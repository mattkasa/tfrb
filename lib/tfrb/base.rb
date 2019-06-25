require_relative 'version'
require_relative 'block'
require_relative 'config'

require 'mixlib/shellout'

class Tfrb::Base
  attr_accessor :block
  attr_accessor :path
  attr_accessor :local_state_path
  attr_accessor :environments
  attr_accessor :state
  attr_accessor :skip_import
  attr_accessor :dry_run

  def initialize(block, environments)
    @skip_import = false
    @dry_run = false
    @block = block
    @path = Tfrb::Config[:path]
    @temp_path = File.join(Tfrb::Config[:temp_path], block)
    Dir.mkdir(@temp_path) unless Dir.exist?(@temp_path)
    @local_state_path = temp_path('.terraform', 'local.tfstate')
    @environments = environments.each_with_object({}) do |environment, hash|
      hash[environment] = Tfrb::Block.load(environment)
    end
    @state = {}
  end

  def write!
    @environments.each do |environment_name, environment|
      File.write(temp_path("#{environment_name}.tf.json"), JSON.pretty_generate(environment, indent: '  '))
    end
  end

  def init!
    tf_init = Mixlib::ShellOut.new('terraform', 'init', shell_opts)
    tf_init.run_command
    tf_init.error!
  end

  def load_state!
    return if skip_import
    return unless s3_state?
    tf_pullstate = Mixlib::ShellOut.new('terraform', 'state', 'pull', { cwd: temp_path })
    tf_pullstate.run_command
    tf_pullstate.error!
    File.write(local_state_path, tf_pullstate.stdout) if dry_run
    pulled_state = JSON.parse(tf_pullstate.stdout)
    if pulled_state['modules']
      pulled_state['modules'].each do |state_module|
        if state_module['resources'] && state_module['resources'].size >= 1
          state_module['resources'].each do |resource_key, resource_state|
            next if resource_key =~ /^data\./
            resource_type = resource_state['type']
            resource_name = resource_key.sub(/^#{resource_type}./, '')
            state[resource_type] = {} unless state.has_key?(resource_type)
            state[resource_type][resource_name] = resource_state['primary']['attributes'] unless state[resource_type].has_key?(resource_name)
          end
        end
      end
    end
  end

  def import!(resource, name, id)
    return if skip_import
    if resource !~ /^postgresql/
      environments_backup = Marshal.load(Marshal.dump(@environments))
      @environments.each do |environment_name, environment|
        if environment.has_key?('provider')
          environment['provider'].delete('postgresql') if environment['provider'].has_key?('postgresql')
          environment.delete('provider') if environment['provider'].empty?
        end
        if environment.has_key?('resource')
          environment['resource'].delete_if { |resource, _| resource =~ /^postgresql/ }
          environment.delete('resource') if environment['resource'].empty?
        end
      end
      write!
    end
    tf_import_args = ['terraform', 'import']
    if dry_run
      tf_import_args << "-lock=false"
      tf_import_args << "-state=#{local_state_path}"
    end
    providers = @environments.find { |_, e| e['resource'] && e['resource'][resource] && e['resource'][resource][name] && e['resource'][resource][name]['provider'] }
    if providers && provider = providers[1]['resource'][resource][name]['provider']
      tf_import_args << "-provider=#{provider}"
    end
    tf_import_args << "#{resource}.#{name}"
    tf_import_args << id
    tf_import = Mixlib::ShellOut.new(*tf_import_args, cwd: temp_path)
    tf_import.run_command
    tf_import.error!
    state[resource] ||= {}
    state[resource][name] = Tfrb::Resource.get_state(self, resource, name)
    printf "\033[1;32mImported %s.%s from %s\033[0m\n", resource, name, id
    if resource !~ /^postgresql/
      @environments = environments_backup
      write!
    end
  end

  def staterm!(resource_id)
    printf "\033[1;32mRemoving #{resource_id} from state...\033[0m\n"
    tf_staterm = Mixlib::ShellOut.new('terraform', 'state', 'rm', resource_id, shell_opts)
    tf_staterm.run_command
    tf_staterm.error!
  end

  def taint!(resource_id)
    printf "\033[1;32mTainting #{resource_id}...\033[0m\n"
    tf_taint = Mixlib::ShellOut.new('terraform', 'taint', resource_id, shell_opts)
    tf_taint.run_command
    tf_taint.error!
  end

  def unlock!(lock_id)
    printf "\033[1;32mForce unlocking state...\033[0m\n"
    tf_unlock = Mixlib::ShellOut.new('terraform', 'force-unlock', lock_id, shell_opts.merge(input: 'yes'))
    tf_unlock.run_command
    tf_unlock.error!
  end

  def plan!
    printf "\033[1;32mCalculating plan...\033[0m\n"
    tf_plan_args = ['terraform', 'plan']
    if dry_run
      tf_plan_args << "-lock=false"
      tf_plan_args << "-state=#{local_state_path}"
    else
      tf_plan_args << '-out=plan.cache'
    end
    tf_plan = Mixlib::ShellOut.new(*tf_plan_args, shell_opts)
    tf_plan.run_command
    tf_plan.error!
  end

  def apply!(parallelism = 1)
    printf "\033[1;32mApplying plan...\033[0m\n"
    tf_apply = Mixlib::ShellOut.new('terraform', 'apply', "-parallelism=#{parallelism}", '-auto-approve', 'plan.cache', shell_opts)
    tf_apply.run_command
    tf_apply.error!
    plan_cache = temp_path('plan.cache')
    File.delete(plan_cache) if File.exist?(plan_cache)
  end

  def clean!
    %w(*.tf.json).each do |glob|
      Dir.glob(temp_path(glob)).each do |file|
        File.delete(file) if File.exist?(file)
      end
    end
    File.delete(local_state_path) if File.exist?(local_state_path)
  end

  def s3_state?
    environments.find { |k,v| v['terraform'] && v['terraform']['backend'] && v['terraform']['backend']['s3'] }
  end

  def shell_opts
    {
      cwd: temp_path,
      live_stderr: $stderr,
      live_stdout: $stdout,
      timeout: 3600
    }
  end

  def temp_path(*args)
    File.join(@temp_path, *args)
  end

  class << self
    def load(block, environments, skip_import = false, dry_run = false)
      Tfrb::Resource.load_helpers!

      printf "\033[1;32mLoading %s...\033[0m\n", block
      tfrb = self.new(block, environments)

      # Set skip_import
      tfrb.skip_import = skip_import

      # Set dry_run
      tfrb.dry_run = dry_run

      # Clean temporary files before starting
      tfrb.clean!

      # Load providers using extend (allows providers to fill in credentials, etc.)
      Tfrb::Provider.load(tfrb)

      # Write the .tf.json files to pick up any injection performed by providers
      tfrb.write!

      # Run terraform init if necessary
      tfrb.init! unless Dir.exist?(tfrb.temp_path('.terraform'))

      # Load state
      tfrb.load_state!

      # Preload resources
      Tfrb::Resource.preload(tfrb)

      # Write the .tf.json files so terraform import can be run by custom resources
      tfrb.write!

      # Load resources using extend (allows them to locate existing entities and run terraform import)
      Tfrb::Resource.load(tfrb)

      # Write the .tf.json files again to pick up any injection performed by resources
      tfrb.write!

      # Return a fully loaded tfrb instance
      tfrb
    end
  end
end

require_relative 'provider'
require_relative 'resource'

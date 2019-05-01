require 'mixlib/shellout'

module Tfrb::Resource
  class << self
    def extended(mod)
      Tfrb::Config[:extra_modules].each do |extra_module|
        mod.send(:include, extra_module)
        mod.send(:extend, extra_module)
      end
    end

    def load_helpers!
      # Include helper methods from resources for use in ERB/YAML
      Tfrb::Resource::constants.each do |constant|
        mod = Kernel.const_get("Tfrb::Resource::#{constant}")
        Tfrb::Base.send(:include, mod) if mod.is_a?(Module)
      end
    end

    def preload(tfrb)
      tfrb.environments.each do |environment_name, environment|
        if environment['resource']
          environment['resource'].each do |resource_type, resources|
            # Call resource preload methods
            if custom_resource = get_custom_resource(resource_type)
              if custom_resource.singleton_methods.include?(:preload)
                custom_resource.preload(tfrb, environment_name, resource_type, resources)
              end
            end

            # Inject overrides from Config
            if Tfrb::Config[:overrides].has_key?('resource') && Tfrb::Config[:overrides]['resource'].has_key?(resource_type)
              custom_resource.instance_exec(tfrb, environment_name, resource_type, resources, &Tfrb::Config[:overrides]['resource'][resource_type])
            end

            # Preload resources from local state wherever possible
            unless tfrb.s3_state?
              tfrb.state[resource_type] = {} unless tfrb.state.has_key?(resource_type)
              resources.each do |resource_name, resource|
                if ::File.exist?(::File.join(tfrb.temp_path, 'terraform.tfstate')) && !tfrb.state[resource_type].has_key?(resource_name)
                  printf "\033[1m%s.%s: Loading state...\033[0m\n", resource_type, resource_name
                  state = get_state(tfrb, resource_type, resource_name)
                  tfrb.state[resource_type][resource_name] = state if state && state.keys.size > 0
                end
              end
            end
          end
        end
      end
    end

    def load(tfrb)
      tfrb.environments.each do |environment_name, environment|
        if environment['resource']
          environment['resource'].each do |resource_type, resources|
            if custom_resource = get_custom_resource(resource_type)
              new_resources = resources.select { |resource_name, _| !tfrb.state.has_key?(resource_type) || !tfrb.state[resource_type].has_key?(resource_name) }
              if custom_resource.singleton_methods.include?(:load) && new_resources.size > 0
                custom_resource.load(tfrb, environment_name, resource_type, new_resources)
              end
            else
              printf "\033[31mWarning: no custom resource definition found for %s\n         consider creating one or you may not receive the desired result!\033[0m\n", resource_type, resource_type
            end
          end
        end
      end
    end

    def get_state(base, resource, name)
      tf_state = Mixlib::ShellOut.new('terraform', 'state', 'show', "#{resource}.#{name}", cwd: base.temp_path)
      tf_state.run_command
      tf_state.error!
      tf_state.stdout.split("\n").each_with_object({}) { |line, hash| key, value = line.split(' = '); hash[key.strip] = value }
    end

    def get_custom_resource(resource_type)
      custom_resource_name = self.constants.find { |c| resource_type == c.to_s.gsub(/(.)([A-Z])/,'\1_\2').downcase }
      if custom_resource_name
        Kernel.const_get("Tfrb::Resource::#{custom_resource_name}")
      end
    end
  end

  def resolve_tfvar(base, resource_type, resource_name, var)
    base.environments.each do |environment_name, environment|
      if environment.has_key?('resource') &&
         environment['resource'].has_key?(resource_type) &&
         environment['resource'][resource_type].has_key?(resource_name) &&
         environment['resource'][resource_type][resource_name].has_key?(var)
        return environment['resource'][resource_type][resource_name][var].gsub(/\$\{([^}]+)\}/) { |match| match.sub(/\$\{([^}]+)\}/, '\1').split('.').inject(base.state) { |state, key| state[key] if state } }
      end
    end
    nil
  end

  def set_default(entity, key, value)
    entity[key] = value unless entity.has_key?(key)
  end

  def aws_options(base, resource)
    if resource.has_key?('provider')
      aws_providers = base.environments.find { |_, e|
        e['provider'] &&
        e['provider']['aws'] &&
        e['provider']['aws']['alias'] &&
        e['provider']['aws']['alias'] == resource['provider'].sub(/^aws\./, '')
      }
    end
    aws_providers = base.environments.find { |_, e| e['provider'] && e['provider']['aws'] } unless aws_providers
    if aws_provider = aws_providers[1]['provider']['aws']
      {
        region: aws_provider['region'],
        access_key_id: aws_provider['access_key'],
        secret_access_key: aws_provider['secret_key']
      }
    end
  end

  def import!(base, resource, name, id)
    base.import!(resource, name, id)
  end
end

Dir[File.join(File.dirname(__FILE__), 'resource', '*.rb')].each { |file| require_relative file }

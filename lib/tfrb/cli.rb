require 'tfrb'
require 'tfrb/version'
require 'tfrb/config'
require 'thor'
require 'mixlib/shellout'

class Tfrb::CLI < Thor
  map %w[--version -v] => :__print_version

  desc '--version, -v', 'print the version'
  def __print_version
    puts Tfrb::VERSION
  end

  desc 'init', 'Runs a terraform init'
  def init
    load_tfrb.init!
  end

  desc 'plan', 'Runs a terraform plan'
  method_option :dry_run, aliases: '-n', type: :boolean, desc: 'Dry run using local copy of statefile', default: false
  method_option :skip_import, aliases: '-s', type: :boolean, desc: 'Skip automatic terraform import', default: false
  def plan
    tfrb = load_tfrb(options[:skip_import], options[:dry_run])
    tfrb.plan!
    tfrb.clean!
  end

  desc 'apply', 'Runs a terraform apply'
  method_option :skip_import, aliases: '-s', type: :boolean, desc: 'Skip automatic terraform import', default: false
  method_option :parallelism, aliases: '-p', type: :numeric, desc: 'Number of concurrent operations', default: 1
  def apply
    tfrb = load_tfrb(options[:skip_import])
    tfrb.apply!(options[:parallelism])
    tfrb.clean!
  end

  desc 'import TYPE NAME ID', 'Runs a terraform import'
  def import(resource_type, resource_name, resource_id)
    tfrb = load_tfrb
    tfrb.skip_import = false
    tfrb.import!(resource_type, resource_name, resource_id)
    tfrb.clean!
  end

  [:staterm, :taint].each do |cmd|
    desc "#{cmd} RESOURCE", "Runs a terraform #{cmd}"
    define_method(cmd) do |resource_id|
      tfrb = load_tfrb
      tfrb.send("#{cmd}!".to_sym, resource_id)
      tfrb.clean!
    end
  end

  desc 'unlock LOCK_ID', 'Runs a terraform unlock'
  def unlock(lock_id)
    tfrb = load_tfrb
    tfrb.unlock!(lock_id)
    tfrb.clean!
  end

  private

  def load_tfrb(skip_import = true, dry_run = false)
    unless File.exist?('tfrb.rb')
      puts 'Missing tfrb.rb file'
      exit(false)
    end

    require File.expand_path('tfrb.rb')

    unless Tfrb::Config[:files] && Tfrb::Config[:files].size > 0
      puts 'No tfrb files found'
      exit(false)
    end

    require 'tfrb/base'

    Tfrb::Base.load(Tfrb::Config[:environment_name], Tfrb::Config[:files], skip_import, dry_run)
  end
end

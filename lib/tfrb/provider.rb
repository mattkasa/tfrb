module Tfrb::Provider
  def self.load(tfrb)
    tfrb.environments.each do |environment_name, environment|
      if environment['provider']
        environment['provider'].keys.each do |provider|
          self.constants.each do |c|
            if provider == c.to_s.gsub(/(.)([A-Z])/,'\1_\2').downcase
              Kernel.const_get("Tfrb::Provider::#{c}").load(tfrb, environment)

              # Inject overrides from Config
              if Tfrb::Config[:overrides].has_key?('provider') && Tfrb::Config[:overrides]['provider'].has_key?(provider)
                environment['provider'][provider].merge!(Tfrb::Config[:overrides]['provider'][provider])
              end
            end
          end
        end
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'provider', '*.rb')].each { |file| require_relative file }

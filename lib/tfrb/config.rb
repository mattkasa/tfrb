module Tfrb
  class Config
    @@config = {}

    class << self
      def [](key)
        @@config[key]
      end

      def []=(key, value)
        @@config[key] = value
      end
    end
  end
end

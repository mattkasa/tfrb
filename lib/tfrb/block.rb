module Tfrb
  class Block
    Tfrb::Config[:extra_modules].each do |extra_module|
      include(extra_module)
    end

    def initialize
      @data = {}
    end

    def to_h
      @data
    end

    def import(filename, params = {})
      instance_eval(IO.read(File.join(Tfrb::Config[:path], "#{filename}.rb")), filename)
    end

    def method_missing(method_name, *args, &block)
      method_name = method_name.to_s.gsub(/_$/, '').to_sym if method_name.to_s =~ /_$/
      if block_given?
        @data[method_name.to_s] ||= {}
        instance = self.class.new
        instance.instance_eval(&block)
        if args && args.size > 0
          hash = args[0..-2].reduce(@data[method_name.to_s]) { |h, v| h[v] ||= {} }
          hash[args.last] = instance.to_h
        else
          @data[method_name.to_s] = instance.to_h
        end
        # puts "method missing called for #{method_name}[#{args}] with block: #{instance.to_h}"
      else
        @data.merge!({ method_name.to_s => args[0] })
        # puts "method missing called for #{method_name}[#{args}] without block"
      end
    end

    def self.load(filename)
      instance = self.new
      instance.import(filename)
      instance.to_h
    end
  end
end

class AttrAccessorObject
  def self.my_attr_accessor(*names)
    def polls
      @polls
    end

    def polls=(value)
      @polls= value
    end

    names.each do |name|
      define_method("#{name}") {instance_variable_get("@#{name}")}
    end

    names.each do |name|
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", "#{value}")
      end
    end
  end
end

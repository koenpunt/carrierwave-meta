module CarrierWave
  module ModelDelegateAttribute
    extend ::ActiveSupport::Concern

    module ClassMethods
      def model_delegate_attribute(attribute, default = nil)
        attr_accessor attribute

        before :remove, :"reset_#{attribute}"

        var_name = :"@#{attribute}"

        define_getter(attribute, var_name, default)
        define_setter(attribute, var_name, default)
        define_reset(attribute, default)
      end

      private
      def define_getter(attribute, var_name, default)
        define_method :"#{attribute}" do
          model_accessor = model_getter_name(attribute)
          value = instance_variable_get(var_name)
          value ||= model.send(model_accessor) if model.present? && model.respond_to?(model_accessor)
          value ||= default
          instance_variable_set(var_name, value)
        end
      end

      def define_setter(attribute, var_name, default)
        define_method :"#{attribute}=" do |value|
          model_accessor = model_getter_name(attribute)
          instance_variable_set(var_name, value)
          if model.present? && model.respond_to?(:"#{model_accessor}=") && !model.destroyed?
            model.send(:"#{model_accessor}=", value)
          end
        end
      end

      def define_reset(attribute, default)
        define_method :"reset_#{attribute}" do
          send(:"#{attribute}=", default)
        end
      end
    end

    private
    def model_getter_name(attribute)
      name = []
      name << mounted_as if mounted_as.present?
      name << version_name if version_name.present?
      name << attribute
      name.join('_')
    end
  end
end

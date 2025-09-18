require "json"
require_relative "camel_json"

class Representation
  include ::KeycloakAdmin::CamelJson

  def as_json(options=nil)
    Hash[instance_variables.map do |ivar|
      value = instance_variable_get(ivar)
      processed_value = case value
                        when Representation
                          value.as_json(options)
                        when Array
                          value.map { |v| v.is_a?(Representation) ? v.as_json(options) : v }
                        when Hash
                          value.transform_values { |v| v.is_a?(Representation) ? v.as_json(options) : v }
                        else
                          value
                        end
      [ivar.to_s[1..-1], processed_value]
    end]
  end

  def to_json(options=nil)
    snaked_hash = as_json(options)
    deep_camelize_keys(snaked_hash).to_json(options)
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    from_hash(hash)
  end

  private

  def deep_camelize_keys(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, val), result|
        camelized_key = key.is_a?(String) ? camelize(key, false) : key
        result[camelized_key] = deep_camelize_keys(val)
      end
    when Array
      value.map { |item| deep_camelize_keys(item) }
    else
      value
    end
  end
end

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
      # Only the representation's own attribute names are camelized. The keys of
      # free-form maps (e.g. `config`, `attributes`) are Keycloak-defined and must
      # be sent verbatim, so they are left untouched above by `transform_values`.
      [camelize(ivar.to_s[1..-1], false), processed_value]
    end]
  end

  def to_json(options=nil)
    as_json(options).to_json(options)
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    from_hash(hash)
  end
end

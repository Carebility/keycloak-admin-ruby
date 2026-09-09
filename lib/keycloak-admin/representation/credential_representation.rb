module KeycloakAdmin
  class CredentialRepresentation < Representation
    attr_accessor :id,
      :type,
      :user_label,
      :created_date,
      :secret_data,
      :credential_data,
      :priority,
      :value,
      :temporary,
      :device,
      :hashedSaltedValue,
      :salt,
      :hashIterations,
      :counter,
      :algorithm,
      :digits,
      :period,
      :config

    def self.from_password(password, temporary=false)
      credential = new
      credential.value     = password
      credential.type      = "password"
      credential.temporary = temporary
      credential
    end

    def self.from_json(json)
      attributes = JSON.parse(json)
      from_hash(attributes)
    end

    def self.from_hash(hash)
      credential                   = new
      credential.id                = hash["id"]
      credential.type              = hash["type"]
      credential.user_label        = hash["userLabel"]
      credential.created_date      = hash["createdDate"]
      credential.secret_data       = hash["secretData"]
      credential.credential_data   = hash["credentialData"]
      credential.priority          = hash["priority"]
      credential.value             = hash["value"]
      credential.temporary         = hash["temporary"]
      credential.device            = hash["device"]
      credential.hashedSaltedValue = hash["hashedSaltedValue"]
      credential.salt              = hash["salt"]
      credential.hashIterations    = hash["hashIterations"]
      credential.counter           = hash["counter"]
      credential.algorithm         = hash["algorithm"]
      credential.digits            = hash["digits"]
      credential.period            = hash["period"]
      credential.config            = hash["config"]
      credential
    end
  end
end

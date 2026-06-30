module KeycloakAdmin
  module CamelJson

    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      string = lower_case_and_underscored_word.to_s
      if first_letter_in_uppercase
        string.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        return string if string.empty?
        string[0] + camelize(string)[1..-1]
      end
    end
  end
end

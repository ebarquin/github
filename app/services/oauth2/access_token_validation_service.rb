module Oauth2::AccessTokenValidationService
  # Results:
  VALID = :valid
  EXPIRED = :expired
  REVOKED = :revoked
  INSUFFICIENT_SCOPE = :insufficient_scope

  class << self
    def validate(token, scopes: [])
      if token.expired?
        return EXPIRED

      elsif token.revoked?
        return REVOKED

      elsif !self.sufficient_scope?(token, scopes)
        return INSUFFICIENT_SCOPE

      else
        return VALID
      end
    end

    protected

    # True if the token's scope is a superset of required scopes,
    # or the required scopes is empty.
    def sufficient_scope?(token, required_scopes)
      if required_scopes.blank?
        true
      else
        # Check whether the token is allowed access to any of the required scopes.
        Set.new(required_scopes).intersection(Set.new(token.scopes)).present?
      end
    end
  end
end

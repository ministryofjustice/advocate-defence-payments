module Claims
  class UpdateDraft < ClaimActionsService
    def initialize(claim, params:, validate:)
      self.claim = claim
      self.params = params
      self.validate = validate
    end

    def call
      claim.assign_attributes(params)
      claim.source = 'api_web_edited' if claim.from_api?

      save_draft!(validate?)

      result
    end

    def draft?
      true
    end

    def action
      :edit
    end
  end
end

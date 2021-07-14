class ClaimShowPage < BasePage
  section :nav, "nav.breadcrumbs > ul" do
    element :your_claims, "li:nth-of-type(1) > a"
    element :archive, "li:nth-of-type(2) > a"
  end

  element :status, "div.claim-hgroup strong.govuk-tag"
  element :edit_this_claim, "div.claim-detail-actions a:nth-of-type(1)"
  element :fees, "#claim_assessment_attributes_fees"
  element :expenses, "#claim_assessment_attributes_expenses"
  element :authorised, "label[for='claim_state_authorised']"
  element :update, "button#button.govuk-button"
  element :refused, "label[for='claim_state_refused']"
  element :rejected, "label[for='claim_state_rejected']"

  sections :rejection_reasons, '.js-cw-claim-rejection-reasons .multiple-choice' do
    element :label, 'label'
    element :input, 'input'
  end
  element :reject_reason_text, '#claim_reject_reason_text'

  sections :refusal_reasons, '.js-cw-claim-refuse-reasons .multiple-choice' do
    element :label, 'label'
    element :input, 'input'
  end
  element :refuse_reason_text, '#claim_refuse_reason_text'

  section :messages_panel, "#claim-accordion .messages-container" do
    element :enter_your_message, "textarea#message-body-field"
    element :send, 'button.govuk-button', text: 'Send'

    def upload_file(path)
      attach_file("message-attachment-field", path)
    end

    sections :messages, '.message-body' do
    end
  end
end

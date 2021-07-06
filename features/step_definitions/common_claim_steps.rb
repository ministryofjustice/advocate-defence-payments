When(/^I goto claim form step '(.*)'$/) do |form_step|
  form_step = form_step.parameterize.underscore
  uri = Addressable::URI.parse(@claim_form_page.current_url)
  uri.query_values = uri.query_values.merge('step' => form_step)
  visit uri
  wait_for_ajax # for fee calc on fee pages, etc
end

When(/^I enter a providers reference of '(.*?)'$/) do |ref|
  @claim_form_page.providers_ref.set ref
end

When(/^I select the court '(.*?)'$/) do |court_name|
  @claim_form_page.auto_court.choose_autocomplete_option(court_name)
  wait_for_ajax
end

When(/^I select a case type of '(.*?)'$/) do |case_type|
  @claim_form_page.case_type_dropdown.select case_type
end

When(/^I select a case stage of '(.*?)'$/) do |case_stage|
  patiently do
    @claim_form_page.auto_case_stage.choose_autocomplete_option(case_stage)
  end
  wait_for_ajax
end

When(/^I enter a case number of '(.*?)'$/) do |number|
  @claim_form_page.case_number.set number
end

When(/^I enter defendant, (.*?)representation order and MAAT reference$/) do |scheme_text|
    date = scheme_date_for(scheme_text)
    using_wait_time(6) do
      @claim_form_page.wait_until_defendants_visible
      @claim_form_page.defendants.first.first_name.set "Bob"
      @claim_form_page.defendants.first.last_name.set "Billiards"
      @claim_form_page.defendants.first.dob.set_date "1955-01-01"
      @claim_form_page.defendants.last.representation_orders.first.date.set_date date
      @claim_form_page.defendants.last.representation_orders.first.maat_reference.set "4567890"
    end
end

When(/^I add another defendant, (.*?)representation order and MAAT reference$/) do |scheme_text|
  date = scheme_date_for(scheme_text)
  using_wait_time 6 do
    @claim_form_page.add_another_defendant.click
    wait_for_ajax
    @claim_form_page.defendants.last.first_name.set "Ned"
    @claim_form_page.defendants.last.last_name.set "Kelly"
    @claim_form_page.defendants.last.dob.set_date "1912-12-12"
    @claim_form_page.defendants.last.representation_orders.first.date.set_date date
    @claim_form_page.defendants.last.representation_orders.first.maat_reference.set Random.rand(4000000...9999999)
  end
end

Then(/^I should see (\d+)\s*representation orders$/) do |count|
  expect(@claim_form_page).to have_selector("fieldset legend", text: "Representation order details", count: count)
end

When(/^I upload (\d+) documents?$/) do |count|
  @document_count = count.to_i
  @claim_form_page.attach_evidence(count: @document_count)
end

When(/^I upload the document '(.*)'$/) do |document|
  @claim_form_page.attach_evidence(document: document)
end

When(/^I check the boxes for the uploaded documents$/) do
  @claim_form_page.check_evidence_checklist(@document_count || 1)
end

When(/^I check the evidence boxes for\s+'([^']*)'$/) do |labels|
  labels = labels.split(',')
  labels.each do |label|
    patiently do
      @claim_form_page.evidence_checklist.check(label)
    end
  end
  wait_for_ajax
  sleep 1 # can't find a way around need for this when popups enabled.
end

When("I answer {string} to was prosecution evidence served on this case?") do |string|
  @claim_form_page.prosecution_evidence.choose(string)
end

# NOTE: can't use have_items because, at least, LAC1 check box may not have a label/be-hidden
Then(/^I should see (\d+)\s*evidence check boxes$/) do |count|
  expect(@claim_form_page.evidence_checklist).to be_visible
  expect(@claim_form_page.evidence_checklist.labels.count).to eql(count.to_i) if count.present?
end

When(/^I add some additional information$/) do
  @claim_form_page.additional_information.set "Bish bosh bash"
end

When(/^I click Submit to LAA$/) do
  allow(Aws::SNS::Client).to receive(:new).and_return Aws::SNS::Client.new(region: 'eu-west-1', stub_responses: true)
  @claim_form_page.wait_until_submit_to_laa_visible
  patiently do
    @claim_form_page.submit_to_laa.click
  end
  wait_for_ajax
end

Then(/^I should be on the check your claim page$/) do
  expect(@claim_summary_page).to be_displayed
end

When(/^I save as draft$/) do
  @claim_form_page.save_to_drafts.click
end

When(/^I click "Continue"$/) do
  @claim_summary_page.wait_until_continue_visible
  patiently do
    @claim_summary_page.continue.click
  end
end

When(/^I click "Continue" in the claim form$/) do
  @claim_form_page.wait_until_continue_button_visible
  patiently do
    @claim_form_page.continue_button.click
  end
  wait_for_ajax
end

When(/^I click "Continue" I should be on the 'Case details' page and see a "([^"]*)" error$/) do |error_message|
  sleep 3
  @claim_form_page.continue_button.click
  wait_for_ajax
  using_wait_time(6) do
    if !page.has_content?(error_message)
      #clicking again because the first one didn't work
      @claim_form_page.continue_button.click
      wait_for_ajax
    end
    within('div.error-summary') do
      expect(page).to have_content(error_message)
    end
  end
end

When(/^I click "Continue" in the claim form and move to the '(.*?)' form page$/) do |page_title|
  original_header = page.first('h2.govuk-heading-l').text
  sleep 3
  @claim_form_page.continue_button.click
  wait_for_ajax
  using_wait_time(6) do
    if page.first('h2.govuk-heading-l').text.eql?(original_header)
      #clicking again because the first one didn't work
      @claim_form_page.continue_button.click
      wait_for_ajax
    end
    within('#claim-form') do
      expect(page.first('h2.govuk-heading-l')).to have_content(page_title)
    end
  end
end

Then(/^I am on the miscellaneous fees page$/) do
  expect(@claim_form_page).to have_miscellaneous_fees
end

Then(/^the summary total should equal '(.*)'$/) do |amount|
  expect(page).to have_content(amount)
end

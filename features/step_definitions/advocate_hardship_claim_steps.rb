Then(/^I should be on the advocate hardship new claim page$/) do
  expect(@advocate_hardship_claim_form_page).to be_displayed
end

When(/I enter (.*?)(retrial|trial) start date$/i) do |scheme_text, trial_type|
  trial_start = Date.parse(scheme_date_for(scheme_text))
  trial_end = trial_start.next_day(7)

  using_wait_time 3 do
    @advocate_hardship_claim_form_page.trial_details.first_day_of_trial.set_date trial_start.strftime

    if trial_type.downcase.eql?('retrial')
      trial_end = trial_start.next_day(7)
      @advocate_hardship_claim_form_page.trial_details.trial_concluded_on.set_date trial_end.strftime
      @advocate_hardship_claim_form_page.trial_details.estimated_trial_length.set 5
      @advocate_hardship_claim_form_page.trial_details.actual_trial_length.set 8

      retrial_start = trial_end.next_day
      retrial_end = retrial_start.next_day(7)
      @advocate_hardship_claim_form_page.retrial_details.retrial_started_at.set_date retrial_start.strftime
      @advocate_hardship_claim_form_page.retrial_details.retrial_concluded_at.set_date retrial_end.strftime
      @advocate_hardship_claim_form_page.retrial_details.retrial_estimated_length.set 5
      @advocate_hardship_claim_form_page.retrial_details.retrial_actual_length.set 8
    end
  end
end

Then("I enter an estimated trial length of {int}") do |int|
  @advocate_hardship_claim_form_page.trial_details.estimated_trial_length.set int
end

Then("I should see the case stage {string}") do |case_stage|
  within '.basic-fee' do
    expect(page).to have_content('Case stage')
    expect(page).to have_content(case_stage)
  end
end

Then("I should see the offence details {string}") do |details|
    expect(page).to have_content('Offence')

    within '.basic-fee' do
      details.split(',').map(&:strip).each do |detail|
        expect(page).to have_content(detail)
      end
    end
end

Then("I should see hardship cracked trial fields") do
  section = @advocate_hardship_claim_form_page.cracked_trial_details
  expect(section.trial_fixed_notice_at).to be_visible
  expect(section.trial_fixed_at).to be_visible
  expect(section).not_to have_trial_cracked_at
  expect(section).to have_content('If the case cracked today, which third would it be?')
end


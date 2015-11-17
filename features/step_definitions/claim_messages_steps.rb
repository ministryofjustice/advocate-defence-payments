Given(/^a claim with messages exists that I have been assigned to$/) do
  @case_worker = CaseWorker.first
  @claim = create(:submitted_claim)
  @messages = create_list(:message, 5, claim_id: @claim.id)
  @messages.each { |m| m.update_column(:sender_id, create(:advocate).user.id) }
  @claim.case_workers << @case_worker
end

Then(/^I should see the messages for that claim in chronological order$/) do
  message_dom_ids = @messages.sort_by(&:created_at).map { |m| "message_#{m.id}" }
  expect(page.body).to match(/.*#{message_dom_ids.join('.*')}.*/m)
end

When(/^I leave a message$/) do
  within '#messages' do
    fill_in 'message_body', with: 'Lorem'
    click_on 'Send'
  end
end

Then(/^I should see my message at the bottom of the message list$/) do
  within '#messages' do
    within '.messages-list' do
      message_body = all('.message-body').last
      expect(message_body).to have_content(/Lorem/)
    end
  end
end

Given(/^I have a submitted claim with messages$/) do
  @claim = create(:submitted_claim, advocate_id: Advocate.first.id)
  @messages = create_list(:message, 5, claim_id: @claim.id)
  @messages.each { |m| m.update_column(:sender_id, create(:advocate).user.id) }
end


When(/^I edit the claim and save to draft$/) do
  claim = Claim.last
  visit "/advocates/claims/#{claim.id}/edit"
  click_on 'Save to drafts'
end

Then(/^I should not see any dates in the message history field$/) do
  expect(page.all('div.event-date').count).to eq 0
end

Then(/^I should see 'no messages found' in the claim history$/) do
  expect(page).to have_content('No messages found')
end

Then(/^I (.*?) see the redetermination button$/) do | radio_button_expectation |
  case radio_button_expectation
    when 'should not'
      within('.messages-container') do
        expect(page).to_not have_content('Apply for redetermination')
      end
    when 'should'
      within('.messages-container') do
        expect(page).to have_content('Apply for redetermination')
      end
  end
end

Then(/^I (.*?) see the request written reason button$/) do | radio_button_expectation |
  case radio_button_expectation
    when 'should not'
      within('.messages-container') do
        expect(page).to_not have_content('Request written reasons')
      end
    when 'should'
      within('.messages-container') do
        expect(page).to have_content('Request written reasons')
      end
  end
end

Then(/^I (.*?) see the controls to send messages$/) do | msg_control_expectation |
  case msg_control_expectation
    when 'should not'
      within('.messages-container') do
        expect(page).to_not have_css('.js-test-send-buttons')
      end
    when 'should'
      within('.messages-container') do
        expect(page).to have_css('.js-test-send-buttons')
      end
  end
end

When(/^click on (.*?)$/) do | radio_button|
  within('.messages-container') do
    click_link radio_button
    wait_for_ajax

  end
end

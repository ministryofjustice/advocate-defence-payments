Then(/^I should be redirected to the claim scheme choice page$/) do
  expect(page.current_path).to eq(external_users_claims_scheme_choice_path)
end
Given('an external provider exists') do
  user = create(:user, email: 'test.user@chambers.com')
  create(:external_user, :advocate_and_admin, user: user)
end

When('I enter {string} in the email field') do |email|
  @provider_search_page.email.set email
end

When("I click the search button") do
  @provider_search_page.search.click
end

Then('I should be on the provider index page') do
  expect(@provider_index_page).to be_displayed
end

Then('I should be on the new provider page') do
  expect(@new_provider_page).to be_displayed
end

Then('I should be on the provider search page') do
  expect(@provider_search_page).to be_displayed
end

Then('I should be on the provider manager user index page') do
  expect(@provider_users_index_page).to be_displayed
end

Then('I should be on the provider manager user show page') do
  expect(@provider_users_show_page).to be_displayed
end

Then('I should be on the provider manager user new page') do
  expect(@provider_users_new_page).to be_displayed
end

Then('I should be on the provider manager user edit page') do
  expect(@provider_users_edit_page).to be_displayed
end

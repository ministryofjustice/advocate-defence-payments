Feature: Cracked trial
  Background:
    As an advocate i want to see cracked trial detail fields for
    cracked trial case types only

    Given a case type of "Cracked trial" exists
      And a case type of "Contempt" exists

  @javascript @webmock_allow_localhost_connect
  Scenario: Cracked trial conditional fields
    Given I am a signed in advocate
      And I am on the new claim page
     Then I should NOT see Cracked trial fields
      And I select2 a Case Type of "Cracked trial"
     Then I should see Cracked trial fields
      And I select2 a Case Type of "Contempt"
     Then I should NOT see Cracked trial fields

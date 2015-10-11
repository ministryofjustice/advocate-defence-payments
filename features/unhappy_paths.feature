Feature: Unhappy paths
  Background:
    As an advocate saving drafts and submitting claims I want to be sure that error messages are displayed if I do something wrong

  Scenario: Attempt to sign in with wrong password
    Given I attempt to sign in with an incorrect password
    Then I should be redirected back to the sign in page
    And I should see a sign in error message

  Scenario: Attempt to save draft claim as advocate admin without specifying the advocate
    Given I am a signed in advocate admin
    And There are case types in place
    And I am on the new claim page
    And I fill in the claim details omitting the advocate
    When I save to drafts
    Then I should be redirected back to the create claim page
    And The entered values should be preserved on the page
    And I should see a summary error message "Advocate cannot be blank"

  Scenario: Attempt to submit claim to LAA without specifying defendant details
    Given I am a signed in advocate
      And There are case types in place
      And I am on the new claim page
      And I attempt to submit to LAA without specifying defendant details
     Then I should be redirected back to the create claim page
      And I should see a field level error message "First name cannot be blank"
      And I should see a field level error message "Last name cannot be blank"
      And I should see a field level error message "Date of birth cannot be blank"

Scenario Outline: Attempt to submit claim to LAA without specifying required text fields
    Given I am a signed in advocate
      And There are case types in place
      And I am on the new claim page
      And I fill in the claim details
      And I add a miscellaneous fee
      And I blank out the <field_id> field
      And I submit to LAA
     Then I should be redirected back to the create claim page
      And I should see a summary error message <error_message>

    Examples:

    | field_id                                   | error_message                                                |
    | "claim_case_number"                        | "Case number cannot be blank, you must enter a case number"  |
    | "claim_defendants_attributes_0_first_name" | "There is a problem with one or more defendants"             |
    | "claim_basic_fees_attributes_0_quantity"   | "There is a problem with one or more basic fees"             |
    | "claim_misc_fees_attributes_0_quantity"    | "There is a problem with one or more miscellaneous fees"     |
    | "claim_expenses_attributes_0_quantity"     | "There is a problem with one or more expenses"               |

    # TODO: unhappy paths for representation order details

    # TODO: unhappy paths for invalid dates attended dates and dates in general

    # TODO: - unhappy paths for select list items
    # Scenario Outline: Attempt to submit claim to LAA without specifying required select-list fields
    # Given I am a signed in advocate
    #   And There are case types in place
    #   And I am on the new claim page
    #   And I fill in the claim details
    #   And I blank out the <select_id> select-list
    #   And I submit to LAA
    #  Then I should be redirected back to the create claim page
    #   And I should see the error message <error_message>

    # Examples:

    # | select_id               | error_message                                                |
    # | "claim_court_id"        | "Court cannot be blank, you must select a court"          |

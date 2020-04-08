class ExternalUsers::Advocates::HardshipClaimsController < ExternalUsers::ClaimsController
  skip_load_and_authorize_resource

  resource_klass Claim::AdvocateHardshipClaim

  private

  def build_nested_resources
    %i[misc_fees expenses].each do |association|
      build_nested_resource(@claim, association)
    end

    super
  end
end

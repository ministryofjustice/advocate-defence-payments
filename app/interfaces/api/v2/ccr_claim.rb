module API
  module V2
    class CCRClaim < Grape::API
      helpers ClaimParamsHelper

      helpers do
        def claim
          ::Claim::BaseClaim.agfs.find_by(uuid: params[:uuid]) || error!('Claim not found', 404)
        end

        def entity_class
          if claim.interim?
            API::Entities::CCR::InterimClaim
          elsif claim.supplementary?
            API::Entities::CCR::SupplementaryClaim
          elsif claim.hardship?
            API::Entities::CCR::HardshipClaim
          else
            API::Entities::CCR::FinalClaim
          end
        end
      end

      resource :claims, desc: 'Operations on claims' do
        desc 'Retrieve a claim by UUID for CCR injection'
        params { use :common_injection_params }

        get ':uuid' do
          present claim, with: entity_class
        end
      end
    end
  end
end

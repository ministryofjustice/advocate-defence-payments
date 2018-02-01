module CCLF
  module Fee
    class MiscFeeAdapter < MappingFeeAdapter
      MISC_FEE_BILL_MAPPINGS = {
        # MIUPL: zip([nil, nil]), # TODO: Case uplift - no equivalent in LGFS - to be removed from app too?!
        MICJA: zip(%w[OTHER COST_JUDGE_FEE]), # Costs judge application
        MICJP: zip(%w[OTHER COST_JUD_EXP]), # Costs judge preparation
        MIEVI: zip(%w[EVID_PROV_FEE EVID_PROV_FEE]), # Evidence provision fee
        MISPF: zip(%w[FEE_SUPPLEMENT SPECIAL_PREP]) # Special preparation fee
      }.freeze

      # **
      # NOTE: in CCLF these scenarios are for a "final" trial/retrial/cracked trial/cracked before retrial
      #   - there are many other scenarios covering interim and transfer claim varieties

      private

      def bill_mappings
        MISC_FEE_BILL_MAPPINGS
      end

      def bill_key
        object.fee_type.unique_code.to_sym
      end
    end
  end
end

# Service to retrieve the unit price for a given fee.
# Unit price will require input from different attributes
# on the claim and may require the quantity from separate
# but related fees (i.e. for uplifts).
#
module Claims
  module FeeCalculator
    class UnitPrice < Calculate
      private

      # TODO: unit should be passed from options or dynamically determined
      # However, day is the unit for all fixed fees.
      #
      def unit_price(modifier = nil)
        @prices = fee_scheme.prices(
          scenario: scenario.id,
          offence_class: offence_class,
          advocate_type: advocate_type,
          fee_type_code: fee_type_code_for(fee_type),
          unit: 'DAY'
        )

        return fee_per_unit unless modifier
        fee_per_unit * unit_scale_factor(modifier) * quantity_from_parent_or_one
      end

      def price
        raise 'Too many prices' if @prices.size > 1
        @prices.first
      end

      def fee_per_unit
        price.fee_per_unit.to_f
      end

      def unit_scale_factor(modifier)
        modifier = price.modifiers.find { |o| !o.modifier_type.find { |mt| mt.name.eql?(modifier.upcase.to_s).empty? } }
        modifier.percent_per_unit.to_f / 100
      end

      def uplift?
        fee_type.case_uplift? || fee_type.defendant_uplift?
      end

      def parent_fee_type
        return unless uplift?
        fee_type.case_uplift? ? case_uplift_parent : defendant_uplift_parent
      end

      def quantity_from_parent_or_one
        parent = parent_fee_type
        return 1 unless parent
        current_total_quantity_for_fee_type(parent)
      end

      def amount
        if fee_type.case_uplift?
          unit_price(:number_of_cases)
        elsif fee_type.defendant_uplift?
          unit_price(:number_of_defendants)
        else
          unit_price
        end
      end
    end
  end
end

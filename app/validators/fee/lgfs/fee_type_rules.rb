# frozen_string_literal: true

module Fee
  module Lgfs
    class FeeTypeRules
      include Fee::Concerns::FeeTypeRulesCreator

      def initialize
        with_set_for_fee_type('MIUMU') do |set|
          set << add_rule(*graduated_fee_type_only_rule)
          set << add_rule(*clar_fee_type_only_rule)
        end

        with_set_for_fee_type('MIUMO') do |set|
          set << add_rule(*graduated_fee_type_only_rule)
          set << add_rule(*clar_fee_type_only_rule)
        end
      end

      private

      # TODO: change agfs_scheme_12_release_date to clar release date
      #
      def clar_fee_type_only_rule
        @clar_fee_type_only_rule ||= \
          [
            'claim.earliest_representation_order_date',
            :minimum,
            Settings.agfs_scheme_12_release_date.beginning_of_day,
            message: 'fee_scheme_applicability',
            attribute_for_error: :fee_type,
            allow_nil: true
          ]
      end
    end
  end
end

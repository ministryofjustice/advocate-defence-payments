require 'rails_helper'

RSpec.describe ErrorMessageTranslator do
  let(:translations) do
    {
      'name' => {
        '_seq' => 50,
        'cannot_be_blank' => {
          'long' => 'The claimant name must not be blank, please enter a name',
          'short' => 'Enter a name',
          'api' => 'The claimant name must not be blank'
        },
        'too_long' => {
          'long' => 'The name cannot be longer than 50 characters',
          'short' => 'Too long',
          'api' => 'The name cannot be longer than 50 characters'
        }
      },
      'date_of_birth' => {
        'too_early' => {
          'long' => 'The date of birth may not be more than 100 years old',
          'short' => 'Invalid date',
          'api' => 'The date of birth may not be more than 100 years old'
        }
      },
      'trial_date' => {
        '_seq' => 20,
        'not_future' => {
          'long' => 'The trial date may not be in the future',
          'short' => 'Invalid date',
          'api' => 'The trial date may not be in the future'
        }
      },
      'defendant' => {
        '_seq' => 30,
        'first_name' => {
          '_seq' => 10,
          'blank' => {
            'long' => "Enter a first name for the \#{defendant}",
            'short' => 'Cannot be blank',
            'api' => "The first name for the \#{defendant} must not be blank"
          }
        }
      },
      'fixed_fee' => {
        '_seq' => 600,
        'quantity' => {
          '_seq' => 30,
          'invalid' => {
            'long' => "Enter a valid quantity for the \#{fixed_fee}",
            'short' => 'Enter a valid quantity',
            'api' => 'Enter a valid quantity for the fixed fee'
          }
        }
      },
      'representation_order' => {
        '_seq' => 80,
        'maat_reference' => {
          'seq' => 20,
          'blank' => {
            'long' => "The MAAT Reference must be 7-10 numeric digits for the \#{representation_order} of the \#{defendant}",
            'short' => 'Invalid format',
            'api' => "The MAAT Reference must be 7-10 numeric digits for the \#{representation_order} of the \#{defendant}"
          }
        }
      }
    }
  end

  let(:emt) { ErrorMessageTranslator.new(translations, key, error) }

  describe '#long_message' do
    subject { emt.long_message }

    let(:key) { :name }
    let(:error) { 'cannot_be_blank' }

    context 'when the key and error both exist in the translation table' do
      it { is_expected.to eq 'The claimant name must not be blank, please enter a name' }
    end

    context 'when the key does not exist in the translation table' do
      let(:key) { :stepmother }

      it { is_expected.to eq 'Stepmother cannot be blank' }
    end

    context 'when the error does not exist in the translation table' do
      let(:error) { 'rubbish' }

      it { is_expected.to eq 'Name rubbish' }
    end

    context 'when the key has a sub-model with a has_many relation' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Enter a first name for the second defendant' }
    end

    context 'when the field does not exist and there is a sub-model' do
      let(:key) { :person_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Person 2 first name blank' }
    end

    context 'when the sub-module for the key does not exist' do
      let(:key) { :defendant_2_age }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 2 age blank' }
    end

    context 'when the error for a key and sub-module does not exist' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'balderdash' }

      it { is_expected.to eq 'Defendant 2 first name balderdash' }
    end

    context 'when the key has a sub-module with a has_one relation' do
      let(:key) { 'fixed_fee.quantity' }
      let(:error) { 'invalid' }

      it { is_expected.to eq 'Enter a valid quantity for the fixed fee' }
    end

    context 'when the key has a sub-sub-module' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'blank' }

      it do
        is_expected.to eq(
          'The MAAT Reference must be 7-10 numeric digits for the second representation order of the fifth defendant'
        )
      end
    end

    context 'when the sub-module does not exist and the key has a sub-sub-module' do
      let(:key) { :defendant_5_court_order_2_maat_reference }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 5 court order 2 maat reference blank' }
    end

    context 'when the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_court }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 5 representation order 2 court blank' }
    end

    context 'when the error for the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'no_such_error' }

      it { is_expected.to eq 'Defendant 5 representation order 2 maat reference no such error' }
    end
  end

  describe '#short_message' do
    subject { emt.short_message }

    let(:key) { :name }
    let(:error) { 'cannot_be_blank' }

    context 'when the key and error both exist in the translation table' do
      it { is_expected.to eq 'Enter a name' }
    end

    context 'when the key does not exist in the translation table' do
      let(:key) { :stepmother }

      it { is_expected.to eq 'Cannot be blank' }
    end

    context 'when the error does not exist in the translation table' do
      let(:error) { 'rubbish' }

      it { is_expected.to eq 'Rubbish' }
    end

    context 'when the key has a sub-model with a has_many relation' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Cannot be blank' }
    end

    context 'when the field does not exist and there is a sub-model' do
      let(:key) { :person_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Blank' }
    end

    context 'when the sub-module for the key does not exist' do
      let(:key) { :defendant_2_age }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Blank' }
    end

    context 'when the error for a key and sub-module does not exist' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'balderdash' }

      it { is_expected.to eq 'Balderdash' }
    end

    context 'when the key has a sub-module with a has_one relation' do
      let(:key) { 'fixed_fee.quantity' }
      let(:error) { 'invalid' }

      it { is_expected.to eq 'Enter a valid quantity' }
    end

    context 'when the key has a sub-sub-module' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Invalid format' }
    end

    context 'when the sub-module does not exist and the key has a sub-sub-module' do
      let(:key) { :defendant_5_court_order_2_maat_reference }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Blank' }
    end

    context 'when the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_court }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Blank' }
    end

    context 'when the error for the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'no_such_error' }

      it { is_expected.to eq 'No such error' }
    end
  end

  describe '#api_message' do
    subject { emt.api_message }

    let(:key) { :name }
    let(:error) { 'cannot_be_blank' }

    context 'when the key and error both exist in the translation table' do
      it { is_expected.to eq 'The claimant name must not be blank' }
    end

    context 'when the key does not exist in the translation table' do
      let(:key) { :stepmother }

      it { is_expected.to eq 'Stepmother cannot be blank' }
    end

    context 'when the error does not exist in the translation table' do
      let(:error) { 'rubbish' }

      it { is_expected.to eq 'Name rubbish' }
    end

    context 'when the key has a sub-model with a has_many relation' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'The first name for the second defendant must not be blank' }
    end

    context 'when the field does not exist and there is a sub-model' do
      let(:key) { :person_2_first_name }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Person 2 first name blank' }
    end

    context 'when the sub-module for the key does not exist' do
      let(:key) { :defendant_2_age }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 2 age blank' }
    end

    context 'when the error for a key and sub-module does not exist' do
      let(:key) { :defendant_2_first_name }
      let(:error) { 'balderdash' }

      it { is_expected.to eq 'Defendant 2 first name balderdash' }
    end

    context 'when the key has a sub-module with a has_one relation' do
      let(:key) { 'fixed_fee.quantity' }
      let(:error) { 'invalid' }

      it { is_expected.to eq 'Enter a valid quantity for the fixed fee' }
    end

    context 'when the key has a sub-sub-module' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'blank' }

      it do
        is_expected.to eq(
          'The MAAT Reference must be 7-10 numeric digits for the second representation order of the fifth defendant'
        )
      end
    end

    context 'when the sub-module does not exist and the key has a sub-sub-module' do
      let(:key) { :defendant_5_court_order_2_maat_reference }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 5 court order 2 maat reference blank' }
    end

    context 'when the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_court }
      let(:error) { 'blank' }

      it { is_expected.to eq 'Defendant 5 representation order 2 court blank' }
    end

    context 'when the error for the sub-sub-module does not exist' do
      let(:key) { :defendant_5_representation_order_2_maat_reference }
      let(:error) { 'no_such_error' }

      it { is_expected.to eq 'Defendant 5 representation order 2 maat reference no such error' }
    end
  end

  describe 'to_ordinal' do
    let(:key)           { :defendant_5_representation_order_2_maat_reference }
    let(:error)         { 'no_such_error' }

    it 'returns empty string for 0' do
      expect(emt.send(:to_ordinal, 0)).to be_empty
      expect(emt.send(:to_ordinal, '0')).to be_empty
    end

    it 'returns words for 1 to 10' do
      expect(emt.send(:to_ordinal, '1')).to eq 'first'
      expect(emt.send(:to_ordinal, '2')).to eq 'second'
      expect(emt.send(:to_ordinal, '3')).to eq 'third'
      expect(emt.send(:to_ordinal, '4')).to eq 'fourth'
      expect(emt.send(:to_ordinal, '5')).to eq 'fifth'
      expect(emt.send(:to_ordinal, '6')).to eq 'sixth'
      expect(emt.send(:to_ordinal, '7')).to eq 'seventh'
      expect(emt.send(:to_ordinal, '8')).to eq 'eighth'
      expect(emt.send(:to_ordinal, '9')).to eq 'ninth'
      expect(emt.send(:to_ordinal, '10')).to eq 'tenth'
    end

    it 'returns ordinals for 11+' do
      expect(emt.send(:to_ordinal, '11')).to eq '11th'
      expect(emt.send(:to_ordinal, '12')).to eq '12th'
      expect(emt.send(:to_ordinal, '21')).to eq '21st'
      expect(emt.send(:to_ordinal, '43')).to eq '43rd'
      expect(emt.send(:to_ordinal, '67')).to eq '67th'
    end
  end
end

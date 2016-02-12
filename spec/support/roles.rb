require 'rails_helper'

shared_examples_for 'roles' do |klass, roles|
  describe 'validation' do
    let(:assigned_roles) { [] }
    subject { build(klass.to_s.underscore.to_sym, roles: assigned_roles) }

    it 'should be valid when a valid role is present' do
      assigned_roles << roles.first
      expect(subject).to be_valid
    end

    it 'should not be valid with an invalid role' do
      assigned_roles << [roles.first, 'foobar123xyz']
      expect(subject).to_not be_valid
      expect(subject.errors[:roles]).to include("must be one or more of: #{roles.map{ |r| r.humanize.downcase }.join(', ')}")
    end

    it 'should not be valid without a role' do
      expect(subject).to_not be_valid
      expect(subject.errors[:roles]).to include('at least one role must be present')
    end
  end

  describe 'scopes' do
    roles.each do |role|
      describe ".#{role.pluralize}" do
        before { create(klass.to_s.underscore.to_sym, roles: [role]) }

        it "only returns #{klass.to_s.underscore} with role '#{role}'" do
          expect(klass.send(role.pluralize).count).to eq(1)
        end
      end
    end
  end

  describe '#is?' do
    roles.each do |role|
      context "for #{role}" do
        subject { create(klass.to_s.underscore.to_sym, roles: [role]) }

        it "returns true for #{role}" do
          expect(subject.is?(role)).to eq(true)
        end

        it 'returns false for any other role' do
          expect(subject.is?('foobar123xyz')).to eq(false)
        end
      end
    end
  end

  describe 'role based dynamic boolean methods' do
    roles.each do |role|
      describe "##{role}?" do
        subject { create(klass.to_s.underscore.to_sym, roles: [role]) }

        it 'returns true when role present' do
          expect(subject.send("#{role}?")).to eq(true)
        end
      end
    end
  end
end

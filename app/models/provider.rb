# == Schema Information
#
# Table name: providers
#
#  id                        :integer          not null, primary key
#  name                      :string
#  firm_agfs_supplier_number :string
#  provider_type             :string
#  vat_registered            :boolean
#  uuid                      :uuid
#  api_key                   :uuid
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  roles                     :string
#


# Note on supplier numbers:
#
# Firms have 1 or more lgfs supplier numbers which are held as an association
# Chambers have an agfs_supplier number for each advocate
# Firms that do AGFS work as well as LGFS work have an additional firm agfs supplier number, instead of an agfs supplier number for each advocate
#

class Provider < ActiveRecord::Base
  auto_strip_attributes :name, :firm_agfs_supplier_number, squish: true, nullify: true

  PROVIDER_TYPES = %w( chamber firm )

  ROLES = %w( agfs lgfs )
  include Roles

  PROVIDER_TYPES.each do |type|
    define_method "#{type}?" do
      provider_type == type
    end

    scope type.pluralize.to_sym, -> { where(provider_type: type) }
  end

  has_many :external_users, dependent: :destroy do
    def ordered_by_last_name
      self.sort { |a, b| a.user.sortable_name <=> b.user.sortable_name }
    end
  end

  has_many :lgfs_supplier_numbers, class_name: SupplierNumber, dependent: :destroy

  has_many :claims_created, -> { active }, through: :external_users
  has_many :claims, -> { active }, through: :external_users

  accepts_nested_attributes_for :lgfs_supplier_numbers, allow_destroy: true

  before_validation :set_api_key, :upcase_firm_agfs_supplier_number

  validates :provider_type, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :api_key, presence: true

  validates :firm_agfs_supplier_number, presence: true, if: :agfs_firm?
  validates :firm_agfs_supplier_number, absence: true, unless: :agfs_firm?
  validates :firm_agfs_supplier_number, format: { with: ExternalUser::SUPPLIER_NUMBER_REGEX, allow_nil: true }
  validates_with SupplierNumberSubModelValidator, if: :lgfs?

  # Allows calling of provider.admins or provider.advocates
  ExternalUser::ROLES.each do |role|
    delegate role.pluralize.to_sym, to: :external_users
  end

  def agfs_firm?
    agfs? && firm?
  end

  def regenerate_api_key!
    update_column(:api_key, SecureRandom.uuid)
  end

  def available_claim_types
    claim_types = []
    claim_types << Claim::AdvocateClaim if self.agfs?
    claim_types.concat [ Claim::LitigatorClaim, Claim::InterimClaim, Claim::TransferClaim ] if self.lgfs?
    claim_types
  end

  def perform_validation?
    true
  end

  def agfs_supplier_numbers
    advocates.map(&:supplier_number)
  end

  private

  def upcase_firm_agfs_supplier_number
    firm_agfs_supplier_number.upcase! unless firm_agfs_supplier_number.blank?
  end

  def set_api_key
    self.api_key ||= SecureRandom.uuid
  end
end

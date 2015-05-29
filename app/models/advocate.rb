class Advocate < ActiveRecord::Base
  ROLES = %w{ admin advocate }
  include UserRoles

  belongs_to :chamber
  has_one :user, as: :persona, inverse_of: :persona, dependent: :destroy
  has_many :claims, dependent: :destroy
  has_many :claims_created, dependent: :nullify, class_name: 'Claim', foreign_key: 'creator_id', inverse_of: :creator
  has_many :documents # Do not destroy - ultimately belong to chambers.

  default_scope { includes(:user, :chamber) }

  validates :user, :chamber, presence: true
  validates :chamber, presence: true
  validates :account_number, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9]{5}\z/, message: "must be 5 alhpa-numeric characters" }

  accepts_nested_attributes_for :user

  delegate :email, to: :user
  delegate :first_name, to: :user
  delegate :last_name, to: :user
  delegate :name, to: :user
end

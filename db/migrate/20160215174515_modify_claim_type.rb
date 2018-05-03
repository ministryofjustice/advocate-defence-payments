class ModifyClaimType < ActiveRecord::Migration[4.2]
  def change
    # change previous data migration as STI sub-models cannot be cloned
    # by Amoeba gem. Awaiting fix.
    ActiveRecord::Base.connection.execute "UPDATE claims SET type = 'Claim::BaseClaim'"
  end
end

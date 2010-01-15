class AddFederatedProfileImageUrlToProfiles < ActiveRecord::Migration
  def self.up
    add_column :profiles, :federated_profile_image_url, :string
  end

  def self.down
    remove_column :profiles, :federated_profile_image_url
  end
end

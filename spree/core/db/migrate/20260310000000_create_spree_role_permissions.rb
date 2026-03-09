class CreateSpreeRolePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_role_permissions do |t|
      t.references :role, null: false
      t.string :subject_class, null: false
      t.string :action, null: false
      t.timestamps
    end

    add_index :spree_role_permissions, [:role_id, :subject_class, :action], unique: true,
              name: 'index_spree_role_permissions_on_role_subject_action'
  end
end

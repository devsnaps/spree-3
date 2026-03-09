class CreateSpreeRolePermissionSets < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_role_permission_sets do |t|
      t.references :role, null: false
      t.string :permission_set_class, null: false
      t.timestamps
    end

    add_index :spree_role_permission_sets, [:role_id, :permission_set_class], unique: true,
              name: 'index_spree_role_permission_sets_on_role_and_class'
  end
end

FactoryBot.define do
  factory :role_permission_set, class: 'Spree::RolePermissionSet' do
    association :role, factory: :role
    permission_set_class { 'Spree::PermissionSets::OrderDisplay' }
  end
end

FactoryBot.define do
  factory :role_permission, class: 'Spree::RolePermission' do
    association :role, factory: :role
    subject_class { 'Spree::Product' }
    action { 'read' }
  end
end

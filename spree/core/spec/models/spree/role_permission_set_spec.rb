require 'spec_helper'

RSpec.describe Spree::RolePermissionSet, type: :model do
  before { Spree.permissions.reset! }

  describe '.sanitize_permission_set_classes' do
    it 'keeps only known permission set classes' do
      result = described_class.sanitize_permission_set_classes([
        'Spree::PermissionSets::OrderDisplay',
        'Spree::PermissionSets::UnknownSet'
      ])

      expect(result).to eq(['Spree::PermissionSets::OrderDisplay'])
    end
  end

  describe '.sync_role_configuration!' do
    it 'assigns selected permission sets to role name' do
      described_class.sync_role_configuration!(
        role_name: 'customer_service',
        permission_set_classes: ['Spree::PermissionSets::OrderDisplay']
      )

      expect(Spree.permissions.permission_sets_for(:customer_service)).to contain_exactly(Spree::PermissionSets::OrderDisplay)
    end
  end

  describe 'validation' do
    let(:role) { create(:role) }

    it 'rejects unknown permission set class' do
      assignment = build(:role_permission_set, role: role, permission_set_class: 'Spree::PermissionSets::UnknownSet')

      expect(assignment).not_to be_valid
      expect(assignment.errors[:permission_set_class]).to be_present
    end
  end
end

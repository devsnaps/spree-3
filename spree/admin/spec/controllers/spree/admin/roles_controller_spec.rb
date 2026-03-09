require 'spec_helper'

RSpec.describe Spree::Admin::RolesController, type: :controller do
  stub_authorization!
  render_views

  before { Spree.permissions.reset! }

  describe 'GET #index' do
    let!(:roles) { create_list(:role, 3) }

    it 'renders the list of roles' do
      get :index

      expect(response).to be_successful
      expect(response).to render_template(:index)

      expect(assigns(:roles)).to contain_exactly(*roles, Spree::Role.default_admin_role)
    end
  end

  describe 'GET #new' do
    it 'renders the new role form' do
      get :new

      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:role_params) do
      {
        name: 'Default Role',
        permission_set_classes: ['Spree::PermissionSets::OrderDisplay', 'Spree::PermissionSets::OrderManagement']
      }
    end

    let(:role) { Spree::Role.last }

    it 'creates a new role' do
      post :create, params: { role: role_params }

      expect(response).to redirect_to(spree.edit_admin_role_path(role))

      expect(role).to be_persisted
      expect(role.name).to eq('Default Role')
      expect(role.role_permission_sets.pluck(:permission_set_class)).to contain_exactly(
        'Spree::PermissionSets::OrderDisplay',
        'Spree::PermissionSets::OrderManagement'
      )
      expect(Spree.permissions.permission_sets_for(role.name)).to contain_exactly(
        Spree::PermissionSets::OrderDisplay,
        Spree::PermissionSets::OrderManagement
      )
    end
  end

  describe 'GET #edit' do
    let!(:role) { create(:role) }

    it 'renders the edit role form' do
      get :edit, params: { id: role.to_param }

      expect(response).to be_successful
      expect(response).to render_template(:edit)
    end
  end

  describe 'PUT #update' do
    let!(:role) { create(:role, name: 'Default Role') }
    let!(:role_permission_set) { create(:role_permission_set, role: role, permission_set_class: 'Spree::PermissionSets::OrderDisplay') }

    it 'updates the role' do
      put :update, params: {
        id: role.to_param,
        role: {
          name: 'Updated Role',
          permission_set_classes: ['Spree::PermissionSets::UserDisplay']
        }
      }

      expect(response).to redirect_to(spree.edit_admin_role_path(role))
      expect(role.reload.name).to eq('Updated Role')
      expect(role.role_permission_sets.pluck(:permission_set_class)).to contain_exactly('Spree::PermissionSets::UserDisplay')
      expect(Spree.permissions.permission_sets_for('Default Role')).to be_empty
      expect(Spree.permissions.permission_sets_for('Updated Role')).to contain_exactly(Spree::PermissionSets::UserDisplay)
    end
  end

  describe 'DELETE #destroy' do
    let!(:role) { create(:role) }

    it 'deletes the role' do
      delete :destroy, params: { id: role.to_param }

      expect(response).to redirect_to(spree.admin_roles_path)
      expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

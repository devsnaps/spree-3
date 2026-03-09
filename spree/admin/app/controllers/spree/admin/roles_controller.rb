module Spree
  module Admin
    class RolesController < ResourceController
      include Spree::Admin::SettingsConcern

      helper_method :permission_actions, :permission_resources, :selected_permissions

      PERMISSION_RESOURCES = [
        { label: 'Dashboard', subject_class: 'dashboard' },
        { label: 'Admin Users', subject_class: -> { Spree.admin_user_class.to_s } },
        { label: 'Customers', subject_class: -> { Spree.user_class.to_s } },
        { label: 'Roles', subject_class: 'Spree::Role' },
        { label: 'Orders', subject_class: 'Spree::Order' },
        { label: 'Payments', subject_class: 'Spree::Payment' },
        { label: 'Shipments', subject_class: 'Spree::Shipment' },
        { label: 'Products', subject_class: 'Spree::Product' },
        { label: 'Taxons', subject_class: 'Spree::Taxon' },
        { label: 'Promotions', subject_class: 'Spree::Promotion' },
        { label: 'Stock Items', subject_class: 'Spree::StockItem' },
        { label: 'Stores', subject_class: 'Spree::Store' },
        { label: 'Shipping Methods', subject_class: 'Spree::ShippingMethod' },
        { label: 'Payment Methods', subject_class: 'Spree::PaymentMethod' },
        { label: 'Tax Rates', subject_class: 'Spree::TaxRate' },
        { label: 'Webhook Endpoints', subject_class: 'Spree::WebhookEndpoint' },
        { label: 'API Keys', subject_class: 'Spree::ApiKey' }
      ].freeze

      def create
        invoke_callbacks(:create, :before)
        set_created_by
        @object.attributes = permitted_resource_params

        if save_with_permissions
          invoke_callbacks(:create, :after)
          flash[:success] = message_after_create
          redirect_to location_after_create, status: :see_other
        else
          invoke_callbacks(:create, :fails)
          render action: :new, status: :unprocessable_content
        end
      end

      def update
        invoke_callbacks(:update, :before)

        if update_with_permissions
          set_current_store
          invoke_callbacks(:update, :after)
          flash[:success] = message_after_update
          redirect_to location_after_save, status: :see_other
        else
          invoke_callbacks(:update, :fails)
          render action: :edit, status: :unprocessable_content
        end
      end

      private

      def permitted_resource_params
        params.require(:role).permit(:name)
      end

      def save_with_permissions
        ActiveRecord::Base.transaction do
          @object.save!
          sync_role_permissions!
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        @object.errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record == @object
        false
      end

      def update_with_permissions
        ActiveRecord::Base.transaction do
          @object.update!(permitted_resource_params)
          sync_role_permissions!
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        @object.errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record == @object
        false
      end

      def sync_role_permissions!
        @object.role_permissions.destroy_all

        sanitized_permissions.each do |subject_class, actions|
          actions.each do |action|
            @object.role_permissions.create!(subject_class: subject_class, action: action)
          end
        end
      end

      def sanitized_permissions
        @sanitized_permissions ||= begin
          raw_permissions = Array(params.dig(:role, :permissions))

          raw_permissions.each_with_object({}) do |row, sanitized|
            subject_class, action = row.to_s.split('|', 2)
            next unless permission_subject_classes.include?(subject_class)
            next unless permission_actions.include?(action)

            sanitized[subject_class] ||= []
            sanitized[subject_class] << action
          end.transform_values(&:uniq)
        end
      end

      def selected_permissions
        @selected_permissions ||= begin
          if params.dig(:role, :permissions).present?
            sanitized_permissions
          elsif @object.persisted?
            @object.role_permissions.group_by(&:subject_class).transform_values { |rows| rows.map(&:action).uniq }
          else
            {}
          end
        end
      end

      def permission_actions
        Spree::RolePermission::ACTIONS
      end

      def permission_resources
        PERMISSION_RESOURCES.map do |resource|
          subject_class = resource[:subject_class]
          subject_class = subject_class.call if subject_class.respond_to?(:call)

          { label: resource[:label], subject_class: subject_class }
        end
      end

      def permission_subject_classes
        @permission_subject_classes ||= permission_resources.map { |resource| resource[:subject_class] }
      end

      def collection_includes
        [:role_permissions]
      end
    end
  end
end

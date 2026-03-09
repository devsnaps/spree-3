module Spree
  module Admin
    class RolesController < ResourceController
      include Spree::Admin::SettingsConcern

      helper_method :available_permission_sets, :selected_permission_set_classes

      def create
        invoke_callbacks(:create, :before)
        set_created_by
        @object.attributes = role_params

        if persist_role_with_permission_sets
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
        previous_role_name = @object.name
        @object.assign_attributes(role_params)

        if persist_role_with_permission_sets(previous_role_name: previous_role_name)
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
        role_params
      end

      def role_params
        params.require(:role).permit(:name)
      end

      def persist_role_with_permission_sets(previous_role_name: nil)
        ActiveRecord::Base.transaction do
          @object.save!
          sync_role_permission_sets!
        end

        sync_runtime_permission_configuration!(previous_role_name: previous_role_name)
        true
      rescue ActiveRecord::RecordInvalid => e
        @object.errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record == @object
        false
      end

      def sync_role_permission_sets!
        @object.role_permission_sets.destroy_all

        sanitized_permission_set_classes.each do |permission_set_class|
          @object.role_permission_sets.create!(permission_set_class: permission_set_class)
        end
      end

      def sync_runtime_permission_configuration!(previous_role_name: nil)
        if previous_role_name.present? && previous_role_name != @object.name
          Spree.permissions.clear(previous_role_name)
        end

        Spree::RolePermissionSet.sync_role_configuration!(
          role_name: @object.name,
          permission_set_classes: @object.role_permission_sets.pluck(:permission_set_class)
        )
      end

      def sanitized_permission_set_classes
        @sanitized_permission_set_classes ||= Spree::RolePermissionSet.sanitize_permission_set_classes(
          params.dig(:role, :permission_set_classes)
        )
      end

      def selected_permission_set_classes
        @selected_permission_set_classes ||= begin
          if params.dig(:role, :permission_set_classes).present?
            sanitized_permission_set_classes
          elsif @object.persisted? && @object.role_permission_sets.any?
            @object.role_permission_sets.pluck(:permission_set_class)
          elsif @object.name.present?
            Spree.permissions.permission_sets_for(@object.name).map(&:name)
          else
            []
          end
        end
      end

      def available_permission_sets
        Spree::RolePermissionSet.available_permission_set_class_names.sort.map do |class_name|
          key = class_name.demodulize.underscore
          i18n_prefix = "spree.admin.roles.permission_sets.items.#{key}"

          {
            class_name: class_name,
            label: I18n.exists?("#{i18n_prefix}.name") ? I18n.t("#{i18n_prefix}.name") : class_name.demodulize.titleize,
            description: I18n.exists?("#{i18n_prefix}.description") ? I18n.t("#{i18n_prefix}.description") : nil
          }
        end
      end

      def collection_includes
        [:role_permission_sets]
      end
    end
  end
end

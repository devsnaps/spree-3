module Spree
  class RolePermissionSet < Spree.base_class
    belongs_to :role, class_name: 'Spree::Role'

    validates :role, :permission_set_class, presence: true
    validates :permission_set_class, uniqueness: { scope: :role_id }
    validate :permission_set_class_must_be_valid

    class << self
      def available_permission_set_classes
        Spree::PermissionSets.constants.filter_map do |constant_name|
          klass = "Spree::PermissionSets::#{constant_name}".safe_constantize
          next unless klass.present? && klass < Spree::PermissionSets::Base

          klass
        end
      end

      def available_permission_set_class_names
        available_permission_set_classes.map(&:name)
      end

      def sanitize_permission_set_classes(permission_set_classes)
        Array(permission_set_classes).map(&:to_s).uniq & available_permission_set_class_names
      end

      def sync_role_configuration!(role_name:, permission_set_classes:)
        sanitized_classes = sanitize_permission_set_classes(permission_set_classes)

        Spree.permissions.clear(role_name)
        Spree.permissions.assign(role_name, sanitized_classes.map(&:constantize)) if sanitized_classes.any?
      end

      def load_all_into_configuration!
        return unless table_exists?
        return unless Spree::Role.table_exists?

        joins(:role).pluck('spree_roles.name', :permission_set_class).group_by(&:first).each do |role_name, rows|
          sync_role_configuration!(role_name: role_name, permission_set_classes: rows.map(&:last))
        end
      end
    end

    private

    def permission_set_class_must_be_valid
      return if self.class.available_permission_set_class_names.include?(permission_set_class)

      errors.add(:permission_set_class, :inclusion)
    end
  end
end

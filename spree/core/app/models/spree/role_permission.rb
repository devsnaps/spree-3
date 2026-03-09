module Spree
  class RolePermission < Spree.base_class
    ACTIONS = %w[create read update destroy].freeze

    belongs_to :role, class_name: 'Spree::Role'

    validates :role, :subject_class, :action, presence: true
    validates :action, inclusion: { in: ACTIONS }
    validates :subject_class, uniqueness: { scope: [:role_id, :action] }
  end
end

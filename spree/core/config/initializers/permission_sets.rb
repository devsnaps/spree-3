Rails.application.config.after_initialize do
  begin
    Spree::RolePermissionSet.load_all_into_configuration!
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    nil
  end
end

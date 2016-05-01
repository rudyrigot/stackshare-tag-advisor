module AdminRestricted
  extend ActiveSupport::Concern

  included do
    http_basic_authenticate_with name: "admin", password: Rails.configuration.x.admin_password unless Rails.env.test?
  end
end

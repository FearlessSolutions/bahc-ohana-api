Raven.configure do |config|
 config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
 config.environments = %w(development staging production)
end
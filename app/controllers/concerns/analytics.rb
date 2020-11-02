require 'open-uri'

module Analytics
  def get_ui_analytics(start_date, end_date)
    ui_analytics_api_url = ENV['UI_URL'] + "/api/analytics?start_date=#{start_date}&end_date=#{end_date}"
    analytics_json = open(ui_analytics_api_url).read
    JSON.parse(analytics_json)
  end

  def total_homepage_views(analytics)
    analytics["homepage_views"]
  end

  def new_homepage_views(analytics)
    analytics["new_homepage_views"]
  end
end

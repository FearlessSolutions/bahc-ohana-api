class Admin
  class AnalyticsController < ApplicationController
    include Analytics

    before_action :authenticate_admin!
    before_action :set_start_and_end_dates

    layout 'admin'

    def index
      @ui_analytics = get_ui_analytics(@start_date, @end_date)
      @total_homepage_views = total_homepage_views(@ui_analytics)
      @new_homepage_views = new_homepage_views(@ui_analytics)
      @organizations_count = Organization.count
      @new_org_count = Organization.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
      @locations_count = Location.count
      @new_location_count = Location.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
      @services_count = Service.count
      @new_service_count = Service.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
    end

    def update
      redirect_to action: :index, analytics: { start_date: @start_date, end_date: @end_date }
    end

    private

    def set_start_and_end_dates
      @start_date = analytics_params[:start_date].try(:to_date) || Date.today - 30.days
      @end_date = analytics_params[:end_date].try(:to_date) || Date.today
    end

    def analytics_params
      if params[:analytics].nil?
        {}
      else
        params.require('analytics').permit(:start_date, :end_date)
      end
    end
  end
end

class Admin
  class ManagementController < ApplicationController
    layout 'admin'
    before_action :authorize_admin
    before_action :find_admin, only: %i[edit update]

    def index
      @super_admins = Admin.where(super_admin: true)
      @admins = Admin.where(super_admin: false).order(:email).to_a.sort_by(&:domain)
    end

    def edit; end

    def update
      @admin.update update_admin_params[:admin]
      redirect_to admin_management_index_path
    end

    # rubocop:disable Metrics/AbcSize
    def drop_admin
      location = Location.find drop_admin_params[:location][:id]
      admin = Admin.find drop_admin_params[:location][:admin_id]
      location.admin_emails.delete admin.email
      location.save
      redirect_to edit_admin_management_path(admin.id)
    end
    # rubocop:enable Metrics/AbcSize

    private

    def authorize_admin
      unless admin_signed_in?
        flash[:error] = t('devise.failure.unauthenticated')
        return redirect_to new_admin_session_url
      end
      user_not_authorized unless current_admin.super_admin?
    end

    def update_admin_params
      params.permit(admin: [:name])
    end

    def drop_admin_params
      params.permit(location: %i[id admin_id])
    end

    def find_admin
      @admin = Admin.find params[:id]
    end
  end
end

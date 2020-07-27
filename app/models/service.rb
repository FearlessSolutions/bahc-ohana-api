class Service < ApplicationRecord
  include HandleTags

  update_index('locations#location') { location }
  update_index('services#service') { self }

  belongs_to :location, touch: true, optional: false
  belongs_to :program, touch: true
  scope :unarchived, -> { where(archived_at: nil)}
  has_and_belongs_to_many :categories,
                          after_add: :touch_location,
                          after_remove: :touch_location

  has_many :regular_schedules, dependent: :destroy, inverse_of: :service
  accepts_nested_attributes_for :regular_schedules,
                                allow_destroy: true, reject_if: :all_blank

  has_many :holiday_schedules, dependent: :destroy, inverse_of: :service
  accepts_nested_attributes_for :holiday_schedules,
                                allow_destroy: true, reject_if: :all_blank

  has_many :contacts, dependent: :destroy, inverse_of: :service

  has_many :phones, dependent: :destroy, inverse_of: :service
  accepts_nested_attributes_for :phones,
                                allow_destroy: true, reject_if: :all_blank

  has_many :tag_resources, as: :resource
  has_many :tags, through: :tag_resources

  validates :accepted_payments, :languages, :required_documents, pg_array: true

  validates :email, email: true, allow_blank: true

  validates :name, :description, :status,
            presence: { message: I18n.t('errors.messages.blank_for_service') }

  # Commenting out to allow for very dirty data to be imported.
  # validate :service_areas, :service_area_match # array: { service_area: true }

  validates :website, url: true, allow_blank: true

  auto_strip_attributes :alternate_name, :audience, :description, :address_details,
                        :eligibility, :email, :fees, :application_process,
                        :interpretation_services, :name, :wait_time, :status,
                        :website

  auto_strip_attributes :funding_sources, :keywords, :service_areas,
                        reject_blank: true, nullify: false

  serialize :funding_sources, Array
  serialize :keywords, Array
  serialize :service_areas, Array

  def self.updated_between(start_date, end_date)
    query = where({})

    if start_date.present?
      query = query.where("services.updated_at > ?", start_date)
    end

    if end_date.present?
      query = query.where("services.updated_at < ?", end_date)
    end

    query
  end

  def self.with_name(keyword)
    if keyword.present?
      where("services.id = ? OR services.name ILIKE ?", keyword.to_i, "%#{keyword}%" )
    else
      all
    end
  end

  def self.with_tag(tag_id)
    if tag_id.present?
      joins(:tags).where(:tags => {:id => tag_id})
    else
      all
    end
  end

  extend Enumerize
  enumerize :status, in: %i[active defunct inactive]

  def self.with_locations(ids)
    joins(:location).where('location_id IN (?)', ids).distinct
  end

  def self.food_and_covid
    food = ServicesSearch.new(tags: 'food').search.load.objects
    covid = ServicesSearch.new(tags: 'covid-19').search.load.objects
    both = food + covid
    both.uniq
  end

  after_save :update_location_status, if: :saved_change_to_status?

  def location_name
    location.name
  end

  def full_name
    "#{name} / #{location_name}"
  end

  def address
    location.full_address
  end

  def contact_info
    contacts_strings = contacts.map do |contact|
      "#{contact.name}: #{contact.email}, #{contact.phones.map(&:number).join(', ')}"
    end

    contacts_strings.join(' // ')
  end

  private

  def update_location_status
    return if location.active == location_services_active?

    location.update_columns(active: location_services_active?)
  end

  def location_services_active?
    location.services.pluck(:status).include?('active')
  end

  def touch_location(_category)
    location.update_column(:updated_at, Time.zone.now) if persisted?
  end

  # rubocop:disable Metrics/LineLength
  def service_area_match
    errors.add(:service_area, "[#{service_areas.join('|')}] aren't in B'more!") unless /Baltimore/.match?(service_areas.join(' '))
  end
  # rubocop:enable Metrics/LineLength
end

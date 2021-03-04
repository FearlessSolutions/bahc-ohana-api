require 'rails_helper'

describe Location do
  subject { build(:location) }

  it { is_expected.to be_valid }

  # Associations
  it { is_expected.to belong_to(:organization).required }
  it { is_expected.to have_one(:address).dependent(:destroy) }
  it { is_expected.to have_many(:resource_contacts).dependent(:destroy) }
  it { is_expected.to have_many(:phones).dependent(:destroy).inverse_of(:location) }
  it { is_expected.to have_many(:services).dependent(:destroy) }
  it { is_expected.to have_many(:regular_schedules).dependent(:destroy).inverse_of(:location) }
  it { is_expected.to have_many(:holiday_schedules).dependent(:destroy).inverse_of(:location) }

  it { is_expected.to accept_nested_attributes_for(:address).allow_destroy(true) }
  it { is_expected.to accept_nested_attributes_for(:phones).allow_destroy(true) }
  it { is_expected.to accept_nested_attributes_for(:regular_schedules).allow_destroy(true) }
  it { is_expected.to accept_nested_attributes_for(:holiday_schedules).allow_destroy(true) }

  it { is_expected.to validate_presence_of(:name).with_message("can't be blank for Location") }

  it do
    is_expected.to validate_presence_of(:description).with_message("can't be blank for Location")
  end

  # Validations
  it { is_expected.to allow_value('http://monfresh.com').for(:website) }

  it do
    is_expected.not_to allow_value('http://').
      for(:website).
      with_message('http:// is not a valid URL')
  end

  it { is_expected.not_to allow_value('http:///codeforamerica.org').for(:website) }
  it { is_expected.not_to allow_value('http://codeforamericaorg').for(:website) }
  it { is_expected.not_to allow_value('www.codeforamerica.org').for(:website) }

  it { is_expected.to allow_value('moncef@blah.com').for(:email) }

  it do
    is_expected.not_to allow_value('moncef@blahcom').
      for(:email).
      with_message('moncef@blahcom is not a valid email')
  end

  it { is_expected.not_to allow_value('moncef.blahcom').for(:email) }
  it { is_expected.not_to allow_value(' foo @bar.com').for(:email) }

  it { is_expected.to allow_value(%w[moncef@blah.com]).for(:admin_emails) }

  it do
    is_expected.not_to allow_value(%w[moncef@blahcom]).
      for(:admin_emails).
      with_message('moncef@blahcom is not a valid email')
  end

  it { is_expected.not_to allow_value(%w[moncef.blahcom]).for(:admin_emails) }
  it { is_expected.not_to allow_value([' foo @bar.com']).for(:admin_emails) }

  it do
    is_expected.to enumerize(:accessibility).
      in(
        :deaf_interpreter, :disabled_parking, :ramp,
        :tape_braille, :wheelchair
      )
  end

  describe 'invalidations' do
    context 'non-virtual and without an address' do
      subject { build(:location, address: nil) }
      it { is_expected.not_to be_valid }
    end
  end

  describe 'auto_strip_attributes' do
    it 'strips extra whitespace before validation' do
      loc = build(:loc_with_extra_whitespace)
      loc.valid?
      expect(loc.description).to eq('Provides job training')
      expect(loc.name).to eq('VRS Services')
      expect(loc.short_desc).to eq('Provides job training.')
      expect(loc.transportation).to eq('BART stop 1 block away.')
      expect(loc.website).to eq('http://samaritanhouse.com')
      expect(loc.admin_emails).to eq(['foo@bar.com'])
      expect(loc.email).to eq('bar@foo.com')
      expect(loc.languages).to eq(%w[English Vietnamese])
    end
  end

  # Instance methods
  it { is_expected.to respond_to(:address_street) }
  describe '#address_street' do
    it 'returns address.address_1' do
      expect(subject.address_street).to eq(subject.address.address_1)
    end
  end

  it { is_expected.to respond_to(:full_physical_address) }
  describe '#full_physical_address' do
    it 'joins all address elements into one string' do
      combined = "#{subject.address.address_1}, " \
        "#{subject.address.city}, #{subject.address.state_province} " \
        "#{subject.address.postal_code}"

      expect(subject.full_physical_address).to eq(combined)
    end
  end

  describe 'slug candidates' do
    before { @loc = create(:location) }

    context 'when name is not taken' do
      it 'creates a new slug based on name' do
        new_loc = create(:no_address)
        expect(new_loc.reload.slug).to eq('no-address')
      end
    end

    context 'when name is not updated' do
      it "doesn't update slug" do
        @loc.update!(description: 'new description')
        expect(@loc.reload.slug).to eq('vrs-services')
      end
    end
  end

  describe 'geolocation methods' do
    before { @loc = create(:location) }

    it "doesn't geocode when address hasn't changed" do
      @loc.name = 'new name'
      expect(@loc).not_to receive(:geocode)
      @loc.save!
    end

    it "doesn't geocode when location is new and has coordinates" do
      loc = build(:location_with_admin)
      expect(loc).not_to receive(:geocode)
      loc.save!
    end

    it "doesn't geocode when location is virtual and has coordinates" do
      loc = build(:location_with_admin, virtual: true)
      expect(loc).not_to receive(:geocode)
      loc.save!
    end

    it "doesn't geocode when location has coordinates but no address" do
      loc = build(:no_address, latitude: 37.5808591, longitude: -122.343072)
      expect(loc).not_to receive(:geocode)
      loc.save!
    end

    it "doesn't geocode when location has neither address nor coordinates" do
      org = create(:nearby_org)
      loc = Location.new(
        name: 'foo',
        description: 'bar',
        virtual: true
      )
      loc.organization_id = org.id
      expect(loc).not_to receive(:geocode)
      loc.save!
    end

    it 'geocodes when address has changed' do
      address = {
        address_1: '1 davis drive', city: 'belmont', state_province: 'CA',
        postal_code: '94002', country: 'US'
      }
      coords = [@loc.longitude, @loc.latitude]

      @loc.update!(address_attributes: address)
      expect(@loc.reload.latitude).to_not eq(coords.second)
    end

    it 'does not geocode when address is added to location with coords' do
      loc = create(:no_address, latitude: 37.5808591, longitude: -122.343072)

      expect(loc).to_not receive(:geocode)

      loc.update!(address_attributes: attributes_for(:address))
    end

    it 'geocodes when address is added to virtual location that did not have one' do
      loc = create(:no_address)
      expect(loc.latitude).to be_nil

      loc.update!(address_attributes: attributes_for(:address))

      expect(loc.reload.latitude).to be_present
    end

    it 'geocodes when location is new, has an address, but no coordinates' do
      org = create(:nearby_org)
      loc = Location.new(
        name: 'foo',
        description: 'bar',
        address_attributes: attributes_for(:address)
      )
      loc.organization_id = org.id

      expect(loc).to receive(:geocode)

      loc.save
    end
  end

  describe 'native Postgres array columns' do
    it 'is not valid when the value is not an array' do
      org = build_stubbed(:nearby_org)
      loc = Location.new(
        name: 'foo',
        description: 'bar',
        address_attributes: attributes_for(:address),
        languages: 'Spanish',
        organization_id: org.id
      )

      expect(loc).to_not be_valid
    end

    it 'is valid when the value is an array' do
      org = create(:nearby_org)
      loc = Location.new(
        name: 'foo',
        description: 'bar',
        address_attributes: attributes_for(:address),
        languages: %w[French]
      )
      loc.organization_id = org.id

      expect(loc).to be_valid
    end
  end

  describe 'archived location' do
    it 'can create archived location' do
      org = build_stubbed(:nearby_org)
      loc = Location.new(
        name: 'foo',
        description: 'bar',
        address_attributes: attributes_for(:address),
        languages: 'Spanish',
        organization_id: org.id,
        archived_at: Time.zone.yesterday
      )

      expect(loc.archived_at.present?).to be(true)
    end
  end
end

require 'rails_helper'

RSpec.describe LocationsSearch, :elasticsearch do
  def search(attributes = {})
    described_class.new(attributes).search.load
  end

  def import(*args)
    LocationsIndex.import!(*args)
  end

  describe 'archive location search' do

    before(:each) do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    after(:each) do
      Organization.find_each(&:destroy)
    end

    specify 'only returns locations not archived' do
      location_1 = create_location("covid location", @organization)
      location_2 = create_location("Not featured and not covid", @organization)
      location_3 = create_location("featured location", @organization, "1")

      LocationsIndex.reset!

      location_1.update_columns(archived: true)
      location_2.update_columns(archived: false)
      location_3.update_columns(archived: true)

      LocationsIndex.reset!


      results = search().objects
      expect(results).to contain_exactly(location_2)
      expect(results.size).to eq(1)
      expect(results).not_to include([location_1, location_3])

      location_1.update_columns(archived: false)
      location_2.update_columns(archived: true)
      location_3.update_columns(archived: false)

      LocationsIndex.reset!

      results = search().objects
      expect(results).to include(location_1, location_3)
      expect(results.size).to eq(2)
      expect(results).not_to include(location_2)
    end
  end
end

private 

def create_location(name, organization, featured = "0")
  create(:location, name: name, organization: organization, featured: featured)
end
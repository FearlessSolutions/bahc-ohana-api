require 'rails_helper'

describe PhoneImporter do
  include CSVHelpers

  let(:invalid_content) do
    path = Rails.root.join('spec', 'support', 'fixtures', 'invalid_phone.csv')
    replace_variables_in_csv(path, {location_id: location.id})
  end

  let(:valid_content) do
    path = Rails.root.join('spec', 'support', 'fixtures', 'valid_location_phone.csv')
    replace_variables_in_csv(path, {location_id: location.id})
  end

  let(:no_parent) { Rails.root.join('spec', 'support', 'fixtures', 'phone_with_no_parent.csv') }

  let!(:location) { create(:location) }

  subject(:importer) { PhoneImporter.new(content) }

  describe '#valid?' do
    context 'when the phone content is invalid' do
      let(:content) { invalid_content }

      it { is_expected.not_to be_valid }
    end

    context 'when the content is valid' do
      let(:content) { valid_content }

      it { is_expected.to be_valid }
    end
  end

  describe '#errors' do
    context 'when the phone content is not valid' do
      let(:content) { invalid_content }

      errors = ["Line 2: Number Type can't be blank for Phone"]

      its(:errors) { is_expected.to eq(errors) }
    end

    context 'when a parent does not exist' do
      let(:content) { no_parent }

      errors = ['Line 2: Phone is missing a parent: Location or Contact or ' \
        'Service or Organization']

      its(:errors) { is_expected.to eq(errors) }
    end
  end

  describe '#import' do
    context 'with all the required fields to create a phone' do
      let(:content) { valid_content }

      it 'creates a phone' do
        expect { importer.import }.to change(Phone, :count).by(1)
      end

      describe 'the phone' do
        before { importer.import }

        subject { Phone.first }

        its(:id) { is_expected.to eq 2 }
        its(:department) { is_expected.to eq 'Food Pantry' }
        its(:extension) { is_expected.to eq '123' }
        its(:number) { is_expected.to eq '703-555-1212' }
        its(:number_type) { is_expected.to eq 'voice' }
        its(:vanity_number) { is_expected.to eq '703-555-FOOD' }
        its(:country_prefix) { is_expected.to eq '1' }
        its(:location_id) { is_expected.to eq(location.id) }
      end
    end

    context 'when the phone belongs to a service' do
      let!(:service) { create(:service, location: location) }

      let(:valid_service_phone) do
        path = Rails.root.join('spec', 'support', 'fixtures', 'valid_service_phone.csv')
        replace_variables_in_csv(path, {service_id: service.id})
      end

      let(:content) { valid_service_phone }

      describe 'the phone' do
        before { importer.import }

        subject { Phone.first }

        its(:service_id) { is_expected.to eq(service.id) }
      end
    end

    context 'when the phone belongs to an organization' do
      let(:organization) { location.organization }

      let(:valid_org_phone) do
        path = Rails.root.join('spec', 'support', 'fixtures', 'valid_org_phone.csv')
        replace_variables_in_csv(path, {org_id: organization.id})
      end

      let(:content) { valid_org_phone }

      describe 'the phone' do
        before { importer.import }

        subject { Phone.first }

        its(:organization_id) { is_expected.to eq(organization.id) }
      end
    end

    context 'when the phone belongs to a contact' do
      let!(:contact) { location.contacts.create!(attributes_for(:contact)) }

      let(:valid_contact_phone) do
        path = Rails.root.join('spec', 'support', 'fixtures', 'valid_contact_phone.csv')
        replace_variables_in_csv(path, {contact_id: contact.id})
      end

      let(:content) { valid_contact_phone }

      describe 'the phone' do
        before { importer.import }

        subject { Phone.first }

        its(:contact_id) { is_expected.to eq(contact.id) }
      end
    end

    context 'when one of the fields required for a phone is blank' do
      let(:content) { invalid_content }

      it 'saves the valid entries and skips invalid ones' do
        expect { importer.import }.to change(Phone, :count).by(1)
      end
    end

    context 'when the phone already exists' do
      before do
        importer.import
      end

      let(:content) { valid_content }

      it 'does not create a new phone' do
        expect { importer.import }.to_not change(Phone, :count)
      end

      it 'does not generate errors' do
        expect(importer.errors).to eq []
      end
    end
  end

  describe '.check_and_import_file' do
    it 'calls FileChecker' do
      file = double('FileChecker')
      allow(file).to receive(:validate).and_return true

      expect(Kernel).to receive(:puts).
        with(/\n===> Importing .*/)

      expect(FileChecker).to receive(:new).
        with(valid_content, PhoneImporter.required_headers).and_return(file)

      PhoneImporter.check_and_import_file(valid_content)
    end

    context 'with invalid data' do
      it 'outputs error message' do
        expect(Kernel).to receive(:puts).
          with(/\n===> Importing .*/)

        expect(Kernel).to receive(:puts).
          with("Line 2: Number Type can't be blank for Phone")

        PhoneImporter.check_and_import_file(invalid_content)
      end
    end
  end

  describe '.required_headers' do
    it 'matches required headers in Wiki' do
      expect(PhoneImporter.required_headers).
        to eq %w[id location_id organization_id service_id contact_id department
                 extension number number_type vanity_number country_prefix]
    end
  end
end

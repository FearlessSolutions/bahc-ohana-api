require 'rails_helper'

describe RegularScheduleImporter do
  include CSVHelpers

  let(:invalid_content) do
    path = Rails.root.join('spec', 'support', 'fixtures', 'invalid_regular_schedule.csv')
    replace_variables_in_csv(path, {location_id: location.id})
  end

  let(:valid_content) do
    path = Rails.root.join('spec', 'support', 'fixtures', 'valid_location_regular_schedule.csv')
    replace_variables_in_csv(path, {location_id: location.id})
  end

  let(:no_parent) do
    Rails.root.join('spec', 'support', 'fixtures', 'regular_schedule_with_no_parent.csv')
  end

  let!(:location) { create(:location) }

  subject(:importer) { RegularScheduleImporter.new(content) }

  describe '#valid?' do
    context 'when the regular_schedule content is invalid' do
      let(:content) { invalid_content }

      it { is_expected.not_to be_valid }
    end

    context 'when the content is valid' do
      let(:content) { valid_content }

      it { is_expected.to be_valid }
    end
  end

  describe '#errors' do
    context 'when the regular_schedule content is not valid' do
      let(:content) { invalid_content }

      errors = ["Line 2: Closes at can't be blank for Regular Schedule"]

      its(:errors) { is_expected.to eq(errors) }
    end

    context 'when a parent does not exist' do
      let(:content) { no_parent }

      errors = ['Line 2: Regular Schedule is missing a parent: Location or ' \
        'Service']

      its(:errors) { is_expected.to eq(errors) }
    end
  end

  describe '#import' do
    context 'with all the required fields to create a regular_schedule' do
      let(:content) { valid_content }

      it 'creates a regular_schedule' do
        expect { importer.import }.to change(RegularSchedule, :count).by(1)
      end

      describe 'the regular_schedule' do
        before { importer.import }

        subject { RegularSchedule.first }

        its(:id) { is_expected.to eq 2 }
        its(:weekday) { is_expected.to eq 1 }
        its(:opens_at) { is_expected.to eq Time.utc(2000, 1, 1, 9, 30, 0) }
        its(:closes_at) { is_expected.to eq Time.utc(2000, 1, 1, 17, 00, 0) }
        its(:location_id) { is_expected.to eq(location.id) }
      end
    end

    context 'when the regular_schedule belongs to a service' do
      let!(:service) { create(:service, location: location) }

      let(:content) do
        path = Rails.root.join('spec', 'support', 'fixtures', 'valid_service_regular_schedule.csv')
        replace_variables_in_csv(path, {service_id: service.id})
      end

      describe 'the regular_schedule' do
        before { importer.import }

        subject { RegularSchedule.first }

        its(:service_id) { is_expected.to eq(service.id) }
      end
    end

    context 'when file contains invalid entries' do
      let(:content) { invalid_content }

      it 'saves the valid entries and skips invalid ones' do
        expect { importer.import }.to change(RegularSchedule, :count).by(4)
      end
    end

    context 'when the regular_schedule already exists' do
      before do
        importer.import
      end

      let(:content) { valid_content }

      it 'does not create a new regular_schedule' do
        expect { importer.import }.to_not change(RegularSchedule, :count)
      end

      it 'does not generate errors' do
        expect(importer.errors).to eq []
      end
    end
  end

  describe '.check_and_import_file' do
    context 'when FileChecker returns skip import' do
      it 'does not import the file' do
        file = double('FileChecker')
        allow(file).to receive(:validate).and_return 'skip import'

        expect(Kernel).to_not receive(:puts)
        expect(RegularScheduleImporter).to_not receive(:import)

        expect(FileChecker).to receive(:new).
          with(valid_content, RegularScheduleImporter.required_headers).and_return(file)

        RegularScheduleImporter.check_and_import_file(valid_content)
      end
    end

    context 'when FileChecker returns true' do
      it 'imports the file' do
        file = double('FileChecker')
        allow(file).to receive(:validate).and_return true

        expect(Kernel).to receive(:puts).
          with(/\n===> Importing .*/)

        expect(RegularScheduleImporter).to receive(:process_import).with(valid_content)

        expect(FileChecker).to receive(:new).
          with(valid_content, RegularScheduleImporter.required_headers).and_return(file)

        RegularScheduleImporter.check_and_import_file(valid_content)
      end
    end

    context 'with invalid data' do
      it 'outputs error message' do
        expect(Kernel).to receive(:puts).
          with(/\n===> Importing .*/)

        expect(Kernel).to receive(:puts).
          with("Line 2: Closes at can't be blank for Regular Schedule")

        RegularScheduleImporter.check_and_import_file(invalid_content)
      end
    end
  end

  describe '.required_headers' do
    it 'matches required headers in Wiki' do
      expect(RegularScheduleImporter.required_headers).
        to eq %w[id location_id service_id weekday opens_at closes_at]
    end
  end
end

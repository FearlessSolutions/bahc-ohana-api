require 'rails_helper'

feature 'Create a new program' do
  background do
    create(:location)
    login_super_admin
    visit('/admin/programs/new')
  end

  scenario 'with all required fields', :js do
    find('.select2', text: I18n.t('admin.shared.forms.choose_org.placeholder')).click
    all('input[type="search"]').last.fill_in(with: "Pare")
    find("li", text: "Parent Agency").click

    fill_in 'program_name', with: 'New Program'
    click_button I18n.t('admin.buttons.create_program')
    expect(page).to have_content 'Program was successfully created.'

    click_link 'New Program'
    click_link 'New Program'
    expect(find_field('program_name').value).to eq 'New Program'
  end

  scenario 'without any required fields' do
    click_button I18n.t('admin.buttons.create_program')
    expect(page).to have_content "Name can't be blank for Program"
    expect(page).to have_content 'Organization must exist'
  end

  scenario 'with alternate_name', :js do
    find('.select2', text: I18n.t('admin.shared.forms.choose_org.placeholder')).click
    all('input[type="search"]').last.fill_in(with: "Pare")
    find("li", text: "Parent Agency").click

    fill_in 'program_name', with: 'New Program'
    fill_in 'program_alternate_name', with: 'Alternate name'
    click_button I18n.t('admin.buttons.create_program')
    click_link 'New Program'

    expect(find_field('program_alternate_name').value).to eq 'Alternate name'
  end
end

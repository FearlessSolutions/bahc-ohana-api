require 'rails_helper'

feature 'Update title' do
  background do
    @location = create(:location)
    @location.contacts.create!(attributes_for(:contact))
    login_super_admin
    visit '/admin/locations/' + @location.slug
    click_link 'Moncef Belyamani'
  end

  scenario 'with valid title' do
    fill_in 'contact_title', with: 'CFO'
    click_button I18n.t('admin.buttons.save_changes')
    expect(page).to have_content 'Contact was successfully updated.'
    expect(find_field('contact_title').value).to eq 'CFO'
  end
end

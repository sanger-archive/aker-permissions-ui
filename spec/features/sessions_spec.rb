require 'rails_helper'

RSpec.feature "Sessions", type: :feature do

  let(:user) { create(:user, email: 'jeff') }

  describe 'Navigating to the homepage' do
    context 'when I am not logged in' do
      it 'will redirect me to the login page' do
        visit root_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'when I am logged in' do
      before :each do
        sign_in(user)
        allow_any_instance_of(StampsController).to receive(:current_user).and_return(user)

        stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [stamp1, stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        owned_stamps = double('owned stamps', all: [stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)

        visit root_path
      end

      it 'will take me to the homepage' do
        visit root_path
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('Log Out')
      end

      it 'will let you log out' do
        visit root_path
        click_on 'Log Out'
        expect(page).to have_current_path(new_user_session_path)
      end
    end

  end

end

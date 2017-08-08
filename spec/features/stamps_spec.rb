require 'rails_helper'

RSpec.feature "Stamps", type: :feature do

  let(:user) { create(:user, email: 'jeff') }

  describe 'Stamps' do
    context 'with a logged in user' do

      before :each do
        sign_in(user)
        allow_any_instance_of(StampsController).to receive(:current_user).and_return(user)
      end

      context '#index' do
        before :each do
          stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
          stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

          @all_stamps = [stamp1, stamp2]
          allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
          owned_stamps = double('owned stamps', all: [stamp1])
          allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)

          visit root_path
        end

        it 'shows all stamps' do
          expect(page).to have_current_path(root_path)
          expect(page).to have_selector('tr', count: @all_stamps.size+1)
        end

        it 'shows Edit and delete for stamps that the current user owns' do
          find('tr', text: 'stamp1').should have_content("Edit")
          find('tr', text: 'stamp1').should have_content("Delete")
          find('tr', text: 'stamp1').should_not have_content("View")
        end

        it 'only shows View for stamps that the current user does not own' do
          find('tr', text: 'stamp2').should have_content("View")
          find('tr', text: 'stamp2').should_not have_content("Edit")
          find('tr', text: 'stamp2').should_not have_content("Delete")
        end

      end

      context '#destroy' do
         before :each do
          @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
          @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

          @all_stamps = [@stamp1, @stamp2]
          allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
          owned_stamps = double('owned stamps', all: [@stamp1])
          allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)

          visit root_path
        end

        it 'shows delete for stamps that the current user owns' do
          page.has_content?('stamp1')
          find('tr', text: 'stamp1').should have_content("Delete")
        end

        it 'can delete a stamp that the user owns' do
          allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
          allow(@stamp1).to receive(:deactivate).and_return true
          click_link('Delete')
          page.has_content?('Stamp deleted')
        end
      end
    end
  end

end

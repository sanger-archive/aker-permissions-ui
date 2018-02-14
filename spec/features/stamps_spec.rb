require 'rails_helper'
require 'ostruct'

RSpec.feature "Stamps", type: :feature do
  # These could be anything
  JWT_NBF_TIME = 60
  JWT_EXP_TIME = 600

  let(:user) { OpenStruct.new(email: 'jeff', groups: ['world']) }

  let(:jwt) do
    iat = Time.now.to_i
    exp = iat + JWT_EXP_TIME
    nbf = iat - JWT_NBF_TIME
    payload = { data: { email: user.email, groups: user.groups }, exp: exp, nbf: nbf, iat: iat }
    JWT.encode payload, Rails.application.config.jwt_secret_key, 'HS256'
  end
  let(:login_url) { Rails.configuration.login_url+'?'+{redirect_url: request.original_url}.to_query }

  def set_cookie(key, value)
    headers = {}
    Rack::Utils.set_cookie_header!(headers, key, value)
    cookie_string = headers['Set-Cookie']
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end

  before do
    set_cookie(:"aker_jwt_#{Rails.env}", jwt) if jwt
  end

  describe 'Stamps' do
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

      it 'will let you create a new stamp' do
        visit root_path
        expect(page).to have_content('Create New Stamp')
      end

      it 'shows Edit and delete for stamps that the current user owns' do
        expect(find('tr', text: 'stamp1')).to have_content("Edit")
        expect(find('tr', text: 'stamp1')).to have_content("Delete")
        expect(find('tr', text: 'stamp1')).not_to have_content("View")
      end

      it 'only shows View for stamps that the current user does not own' do
        expect(find('tr', text: 'stamp2')).to have_content("View")
        expect(find('tr', text: 'stamp2')).not_to have_content("Delete")
        expect(find('tr', text: 'stamp2')).not_to have_content("Edit")
      end

    end

    context '#show' do
      before :each do
        @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [@stamp1, @stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        owned_stamps = double('owned stamps', all: [@stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)
        allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp2])

        visit root_path
      end

      it 'shows the view modal when you click on View' do
        allow(@stamp2).to receive(:permissions).and_return([])
        click_link("View")
        expect(page).to have_content('View Stamp')
        expect(field_labeled("Name", disabled: true).value).to eq 'stamp2'
        expect(page).not_to have_content('Update')
      end
    end

    context '#edit' do
      before :each do
        @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [@stamp1, @stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        owned_stamps = double('owned stamps', all: [@stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)
        allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])

        visit root_path
      end

      it 'shows the edit modal when you click on Edit' do
        allow(@stamp1).to receive(:permissions).and_return([])
        click_link("Edit")
        expect(page).to have_content('Edit Stamp')
        expect(field_labeled("Name").value).to eq 'stamp1'
        expect(page).to have_button('Update')
      end
    end

    context '#update' do
      before :each do
        @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [@stamp1, @stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        owned_stamps = double('owned stamps', all: [@stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(owned_stamps)
        allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])

        visit root_path
      end

      it 'shows the edit modal when you click on Edit' do
        new_name = "newstampname"
        @new_stamp = double('stamp', id: @stamp1.id, name: new_name, owner_id: 'jeff', user_editors: 'user1')

        allow(@stamp1).to receive(:permissions).and_return([])
        allow(@stamp1).to receive(:update).with(name: new_name).and_return(@new_stamp)
        allow(@stamp1).to receive(:set_permissions_to)
        allow(StampClient::Stamp).to receive(:all).and_return([@new_stamp, @stamp2])

        click_link("Edit")
        fill_in('Name', :with => 'newstampname')
        click_button("Update")
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('newstampname')
        expect(page).not_to have_content('stamp1')
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
        expect(page).to have_content('stamp1')
        expect(find('tr', text: 'stamp1')).to have_content("Delete")
      end

      it 'can delete a stamp that the user owns' do
        allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
        allow(@stamp1).to receive(:destroy).and_return true
        click_link('Delete')
        expect(page).to have_current_path(root_path)
        page.has_content?('Stamp deleted')
      end
    end
  end

end

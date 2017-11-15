require 'rails_helper'
require 'ostruct'

RSpec.feature "Deputies", type: :feature do

  let(:user) { OpenStruct.new(email: 'jeff', groups: ['world']) }

  let(:jwt) do
    iat = Time.now.to_i
    exp = iat + Rails.application.config.jwt_exp_time
    nbf = iat - Rails.application.config.jwt_nbf_time
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
    set_cookie(:aker_user_jwt, jwt) if jwt
  end

  describe 'Deputiess' do
    context '#index' do
      before :each do
        deputy1 = double('deputy', id: SecureRandom.uuid, user_email: 'jeff', deputy: 'deputy1')
        deputy2 = double('deputy', id: SecureRandom.uuid, user_email: 'dirk', deputy: 'deputy2')

        @all_deputies = [deputy1, deputy2]
        allow(StampClient::Deputy).to receive(:all).and_return(@all_deputies)

        visit deputies_path
      end

      it 'shows all deputies' do
        expect(page).to have_current_path(deputies_path)
        expect(page).to have_selector('h5', count: @all_deputies.size)
      end

      it 'will let you create a new deputy' do
        visit deputies_path
        expect(page).to have_content('Assign Sample Guardian Deputies')
      end

      it 'shows Delete for deputies of the current user' do
        expect(find('tr', text: 'deputy1')).to have_content("Delete")
      end
    end

    context '#destroy' do
      before :each do
        @deputy1 = double('deputy', id: SecureRandom.uuid, user_email: 'jeff', deputy: 'deputy1')
        @deputy2 = double('deputy', id: SecureRandom.uuid, user_email: 'dirk', deputy: 'deputy2')

        @all_deputies = [@deputy1, @deputy2]
        allow(StampClient::Deputy).to receive(:all).and_return(@all_deputies)

        visit deputies_path
      end

      it 'shows delete for deputies of the user' do
        expect(page).to have_content('deputy1')
        expect(find('tr', text: 'deputy1')).to have_content("Delete")
      end

      it 'can delete a a deputy of the user' do
        allow(StampClient::Deputy).to receive(:find).and_return([@deputy1])
        allow(@deputy1).to receive(:destroy).and_return true
        click_link('Delete')
        expect(page).to have_current_path(deputies_path)
        page.has_content?('Deputy deleted')
      end
    end
  end
end

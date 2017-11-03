require 'rails_helper'

RSpec.describe DeputiesController, type: :controller do

  let(:user) { OpenStruct.new(email: 'jeff', groups: ['world']) }
  let(:jwt) do
    iat = Time.now.to_i
    exp = iat + Rails.application.config.jwt_exp_time
    nbf = iat - Rails.application.config.jwt_nbf_time
    payload = { data: { email: user.email, groups: user.groups }, exp: exp, nbf: nbf, iat: iat }
    JWT.encode payload, Rails.application.config.jwt_secret_key, 'HS256'
  end
  let(:login_url) { Rails.configuration.login_url+'?'+{redirect_url: request.original_url}.to_query }

  before do
    request.cookies[:aker_user_jwt] = jwt if jwt
  end

  describe '#index' do
    context 'when no JWT is included' do
      let(:jwt) { nil }

      it 'redirects to the login page' do
        get :index
        expect(response).to redirect_to(login_url)
      end
    end

    context 'when a JWT is included' do
      before do
        deputy1 = double('deputy', id: SecureRandom.uuid, user_email: 'jeff', deputy: 'deputy1')
        deputy2 = double('deputy', id: SecureRandom.uuid, user_email: 'dirk', deputy: 'deputy2')

        @all_deputies = [deputy1, deputy2]
        allow(StampClient::Deputy).to receive(:all).and_return(@all_deputies)
      end

      it 'has a list of deputies belonging to the current user' do
        get :index, params: {}
        deputies = controller.instance_variable_get("@all_deputies")
        expect(deputies.length).to eq @all_deputies.size
      end
    end
  end

  describe 'CREATE #create' do
    it "should send a create request to the stamp client" do
      deputy3 = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'deputy3')
      expect(StampClient::Deputy).to receive(:create).and_return(deputy3)

      post :create, params: { deputy: { user_deputies: "mary" } }
      expect(flash[:success]).to match('Deputy created')
    end

    it "should show error flash when stamp client fails to create deputy" do
      expect(StampClient::Deputy).to receive(:create).and_return false

      post :create, params: { deputy: { user_deputies: "mary" } }
      expect(flash[:danger]).to match("Failed to create deputy")
    end

    it "should show success flash when stamp client creates stamp" do
      deputy4 = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'deputy4')
      expect(StampClient::Deputy).to receive(:create).and_return(deputy4)

      post :create, params: { deputy: { user_deputies: "mary" } }
      expect(flash[:success]).to match('Deputy created')
    end
  end

  describe 'DELETE #destroy' do
    before do
      @deputy1 = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'deputy1')
      @deputy2 = double('deputy', id: SecureRandom.uuid, user_email: 'jeff', deputy: 'deputy2')
    end

    it "should show success flash when stamp client deletes deputy" do
      controller.instance_variable_set(:@deputy, @deputy1)
      expect(StampClient::Deputy).to receive(:find).and_return([@deputy1])
      allow(@deputy1).to receive(:destroy).and_return true

      delete :destroy, params: { id: @deputy1 }
      expect(@deputy1.destroy).not_to be_nil
      expect(flash[:success]).to match('Deputy deleted')
    end

    it "should show error flash when stamp client fails to delete deputy" do
      controller.instance_variable_set(:@deputy, @deputy1)
      expect(StampClient::Deputy).to receive(:find).and_return([@deputy1])
      expect(@deputy1).to receive(:destroy)

      delete :destroy, params: { id: @deputy1 }
      expect(flash[:danger]).to match('Failed to delete deputy')
    end
  end
end

require 'rails_helper'

RSpec.describe DeputiesController, type: :controller do
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
      end

      it 'has a list of deputies belonging to the current user' do
        expect(StampClient::Deputy).to receive(:all).and_return(@all_deputies)

        get :index, params: {}

        deputies = controller.instance_variable_get('@all_deputies')
        expect(deputies.length).to eq @all_deputies.size
      end
    end
  end

  describe 'CREATE #create' do
    DEP_CREATED_MSG = 'Deputy created'
    before do
      @deputy = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'jeff')
    end

    it 'should send a create request to the StampClient' do
      expect(StampClient::Deputy).to receive(:create).and_return(@deputy)

      post :create, params: { deputy: { user_deputies: @deputy.deputy } }

      expect(flash[:success]).to match(DEP_CREATED_MSG)
    end

    it 'should show error flash when StampClient fails to create deputy' do
      expect(StampClient::Deputy).to receive(:create).and_return false

      post :create, params: { deputy: { user_deputies: @deputy.deputy } }

      expect(flash[:danger]).to match('Failed to create deputy')
    end

    it 'should show success flash when StampClient creates stamp' do
      deputy4 = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'deputy4')
      allow(StampClient::Deputy).to receive(:create).and_return(deputy4)

      post :create, params: { deputy: { user_deputies: @deputy.deputy } }

      expect(flash[:success]).to match(DEP_CREATED_MSG)
    end
  end

  describe 'DELETE #destroy' do
    before do
      @deputy1 = double('deputy', id: SecureRandom.uuid, user_email: 'mary', deputy: 'deputy1')
      controller.instance_variable_set(:@deputy, @deputy1)
    end

    it 'should show success flash when StampClient deletes deputy' do
      expect(StampClient::Deputy).to receive(:find).with(@deputy1.id).and_return([@deputy1])
      expect(@deputy1).to receive(:destroy).and_return(true)

      delete :destroy, params: { id: @deputy1.id }

      expect(flash[:success]).to match('Deputy deleted')
    end

    it 'should show error flash when StampClient fails to delete deputy' do
      expect(StampClient::Deputy).to receive(:find).with(@deputy1.id).and_return([@deputy1])
      expect(@deputy1).to receive(:destroy).and_return(false)

      delete :destroy, params: { id: @deputy1.id }

      expect(flash[:danger]).to match('Failed to delete deputy')
    end
  end
end

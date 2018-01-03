require 'rails_helper'
require 'ostruct'

RSpec.describe StampsController, type: :controller do
  JWT_NBF_TIME = 60
  JWT_EXP_TIME = 3600

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
        stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [stamp1, stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        @owned_stamps = double('owned stamps', all: [stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(@owned_stamps)
      end

      it 'has a list of stamps belonging to the current user' do
        get :index, params: {}
        stamps = controller.instance_variable_get("@all_stamps")
        expect(stamps.length).to eq @all_stamps.size
      end

      it 'has a list of stamps not belonging to the current user' do
        get :index, params: {}
        owned_stamps = controller.instance_variable_get("@owned_stamps")
        expect(owned_stamps.length).to eq @owned_stamps.all.size
      end
    end
  end

  describe 'CREATE #create' do

    it "should send a create request to the stamp client" do
      stamp3 = double('stamp', id: SecureRandom.uuid, name: 'stamp3')
      expect(StampClient::Stamp).to receive(:create).and_return(stamp3)
      expect(stamp3).to receive(:set_permissions_to).and_return true

      post :create, params: { stamp: { name: 'stamp3' } }
      expect(flash[:success]).to match('Stamp created')
    end

    it "should show error flash when stamp client fails to create stamp" do
      expect(StampClient::Stamp).to receive(:create).and_return false

      post :create, params: { stamp: { name: 'stamp1' } }
      expect(flash[:danger]).to match("Failed to create stamp")
    end

    it "should show success flash when stamp client creates stamp" do
      stamp4 = double('stamp', id: SecureRandom.uuid, name: 'stamp4')
      expect(StampClient::Stamp).to receive(:create).and_return(stamp4)
      expect(stamp4).to receive(:set_permissions_to).and_return true

      post :create, params: { stamp: { name: "stamp4", group_editors: 'teamxzy', user_consumers: 'zogh' } }
      expect(flash[:success]).to match('Stamp created')
    end
  end

  describe '#show' do
    before do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it 'renders the show modal' do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect(StampForm).to receive(:from_stamp)

      get :show, params: { id: @stamp1.id }
      expect(response).to render_template "stamps/show"
    end
  end

  describe '#edit' do
    before do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it 'renders the edit modal' do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect(StampForm).to receive(:from_stamp)

      get :edit, params: { id: @stamp1.id }
      expect(response).to render_template "stamps/edit"
    end
  end

  describe 'PUT #update' do
    before do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it "should show success flash when stamp client updates stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect_any_instance_of(StampForm).to receive(:save).and_return(true)

      put :update, params: { id: @stamp1.id, stamp: { name: "newstampname" } }
      expect(flash[:success]).to match('Stamp updated')
    end

    it "should show error flash when stamp client fails to update stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect_any_instance_of(StampForm).to receive(:save).and_return(false)

      put :update, params: { id: @stamp1.id, stamp: { name: "newstampname" } }
      expect(flash[:danger]).to match('Failed to update stamp')
    end
  end

  describe 'DELETE #destroy' do
    before do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
      @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')
    end

    it "should show success flash when stamp client deletes stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      allow(@stamp1).to receive(:destroy).and_return true

      delete :destroy, params: { id: @stamp1 }
      expect(@stamp1.destroy).not_to be_nil
      expect(flash[:success]).to match('Stamp deleted')
    end

    it "should show error flash when stamp client fails to delete stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      expect(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect(@stamp1).to receive(:destroy)

      delete :destroy, params: { id: @stamp1 }
      expect(flash[:danger]).to match('Failed to delete stamp')
    end
  end

end

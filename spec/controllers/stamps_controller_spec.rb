require 'rails_helper'

RSpec.describe StampsController, type: :controller do

  let(:user) { create(:user, email: 'jeff') }

  before :each do
    sign_in(user)
    allow_any_instance_of(StampsController).to receive(:current_user).and_return(user)
  end

  describe '#index' do
    before :each do
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

  describe 'CREATE #create' do

    it "should create a new stamp" do
      stamp3 = double('stamp', id: SecureRandom.uuid, name: 'stamp3')
      allow(StampClient::Stamp).to receive(:create).and_return(stamp3)
      allow(stamp3).to receive(:set_permissions_to).and_return true

      post :create, params: { stamp: { name: 'stamp3' } }
      expect(flash[:success]).to match('Stamp created')
    end

    it "fails to create a new stamp" do
      allow(StampClient::Stamp).to receive(:create).and_return false

      post :create, params: { stamp: { name: 'stamp1' } }
      expect(flash[:danger]).to match("Failed to create stamp")
    end

    it "should create a new stamp with permissions" do
      stamp4 = double('stamp', id: SecureRandom.uuid, name: 'stamp4')
      allow(StampClient::Stamp).to receive(:create).and_return(stamp4)
      allow(stamp4).to receive(:set_permissions_to).and_return true

      post :create, params: { stamp: { name: "stamp4", group_editors: 'teamxzy', user_consumers: 'zogh' } }
      expect(flash[:success]).to match('Stamp created')
    end
  end

  describe '#show' do
    before :each do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it 'renders the show modal' do
      controller.instance_variable_set(:@stamp, @stamp1)
      allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      allow(StampForm).to receive(:from_stamp)

      get :show, params: { id: @stamp1.id }
      expect(response).to render_template "stamps/show"
    end
  end

  describe '#edit' do
    before :each do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it 'renders the edit modal' do
      controller.instance_variable_set(:@stamp, @stamp1)
      allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      allow(StampForm).to receive(:from_stamp)

      get :edit, params: { id: @stamp1.id }
      expect(response).to render_template "stamps/edit"
    end
  end

  describe 'PUT #update' do
    before :each do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
    end

    it "it should update the stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      expect_any_instance_of(StampForm).to receive(:save).and_return(true)

      put :update, params: { id: @stamp1.id, stamp: { name: "newstampname" } }
      expect(flash[:success]).to match('Stamp updated')
    end

    it "it should not update the stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      allow_any_instance_of(StampForm).to receive(:save).and_return(false)

      get :update, params: { id: @stamp1.id, stamp: { name: "newstampname" } }
      expect(flash[:danger]).to match('Failed to update stamp')
    end

  end

  describe 'DELETE #destroy' do
    before :each do
      @stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
      @stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')
    end

    it "should deactivate the stamp" do
      controller.instance_variable_set(:@stamp, @stamp1)
      allow(StampClient::Stamp).to receive(:find_with_permissions).and_return([@stamp1])
      allow(@stamp1).to receive(:destroy).and_return true

      delete :destroy, params: { id: @stamp1 }
      expect(@stamp1.destroy).not_to be_nil
      expect(flash[:success]).to match('Stamp deleted')
    end
  end

end

require 'rails_helper'

RSpec.describe StampsController, type: :controller do

  let(:user) { create(:user, email: 'jeff') }

  describe '#index' do
    context 'when the user is logged in' do
      before :each do
        sign_in(user)
        allow_any_instance_of(StampsController).to receive(:current_user).and_return(user)

        stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [stamp1, stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
        @owned_stamps = double('owned stamps', all: [stamp1])
        allow(StampClient::Stamp).to receive(:where).with({owner_id: 'jeff'}).and_return(@owned_stamps)

        visit root_path
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

    context "when a user is logged in" do

      before :each do
        sign_in(user)
        allow_any_instance_of(StampsController).to receive(:current_user).and_return(user)

        stamp1 = double('stamp', id: SecureRandom.uuid, name: 'stamp1', owner_id: 'jeff')
        stamp2 = double('stamp', id: SecureRandom.uuid, name: 'stamp2', owner_id: 'dirk')

        @all_stamps = [stamp1, stamp2]
        allow(StampClient::Stamp).to receive(:all).and_return(@all_stamps)
      end

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

        post :create, params: { stamp: { name: "stamp4", user_writers: 'dirk,jeff@sanger.ac.uk', group_writers: 'team_gamma,team_DELTA', user_spenders: 'DIRK@sanger.ac.uk', group_spenders: 'team_delta,team_epsilon' } }
        expect(flash[:success]).to match('Stamp created')
      end

    end

  end

end

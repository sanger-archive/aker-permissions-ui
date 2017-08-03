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

end

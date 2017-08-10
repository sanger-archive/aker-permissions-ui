require 'rails_helper'

RSpec.describe StampsController, type: :controller do

  let(:user) { create(:user, email: 'jeff') }
  let(:url) { Rails.configuration.stamp_url }
  let(:content_type) { 'application/vnd.api+json' }
  let(:request_headers) { { 'Accept' => content_type, 'Content-Type'=> content_type } }
  let(:response_headers) { { 'Content-Type' => content_type } }

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
      @oldname = "oldname"
      stamp_data = { id: SecureRandom.uuid, type: "stamps", attributes: { name: @oldname, 'owner_id': user.email }}

      stub_request(:post, url+"stamps")
         .with(body: { data: { type: "stamps", attributes: { name: @oldname }}}.to_json, headers: request_headers)
         .to_return(status: 200, body: { data: stamp_data }.to_json, headers: response_headers)

      @stamp = build(:stamp, name: @oldname)
      @stamp.save
    end

    context "when the stamp does not have permissions to update" do
      it "it should update the stamp" do
        controller.instance_variable_set(:@stamp, @stamp)
        owner = user.email
        newname = "newstampname"

        old_response_body = make_stamp_without_permission_data(@stamp.id, @oldname, owner)

        stub_request(:get, url+"stamps/"+@stamp.id+"?include=permissions")
          .with(headers: request_headers )
          .to_return(status: 200, body: old_response_body.to_json, headers: response_headers)

        new_stamp_data = { id: @stamp.id, type: "stamps", attributes: { name: newname }}

        stub_request(:patch, url+"stamps/"+@stamp.id)
          .with(body: { data: { id: @stamp.id, type: "stamps", attributes: { name: newname }}}.to_json, headers: request_headers)
          .to_return(status: 200, body: { data: new_stamp_data }.to_json, headers: response_headers)

        new_response_body = make_stamp_without_permission_data(@stamp.id, newname, owner)

        stub_request(:post, url+"stamps/"+@stamp.id+"/set_permissions")
          .with(body: { data: []}.to_json, headers: request_headers)
          .to_return(status: 200, body: new_response_body.to_json, headers: response_headers)

        put :update, params: { id: @stamp.id, stamp: { name: "newstampname" } }
        expect(flash[:success]).to match('Stamp updated')
      end
    end


    context "when the stamp does have permissions to update" do
      it "it should update the stamp" do
        controller.instance_variable_set(:@stamp, @stamp)
        owner = user.email
        old_permission_id = "1"
        old_permission_type = :consume
        old_permitted = 'xyz'

        old_response_body = make_stamp_with_permission_data(@stamp.id, @stamp.name, owner, old_permission_id, old_permitted, old_permission_type)

        stub_request(:get, url+"stamps/"+@stamp.id+"?include=permissions")
          .with(headers: request_headers )
          .to_return(status: 200, body: old_response_body.to_json, headers: response_headers)

        stub_request(:patch, url+"stamps/"+@stamp.id)
           .with(body: { data: { id: @stamp.id, type: "stamps", attributes: {}}}.to_json, headers: request_headers)
           .to_return(status: 200, body: "", headers: {})

        new_permission_id = "2"
        new_permission_type = :edit
        new_permitted = 'dirk@sanger.ac.uk'

        stub_data = { data: [ {permitted: new_permitted, 'permission-type': new_permission_type}] }
        new_response_body = make_stamp_with_permission_data(@stamp.id, @stamp.name, owner, new_permission_id, new_permitted, new_permission_type)

        stub_request(:post, url+"stamps/"+@stamp.id+"/set_permissions")
            .with(body: stub_data.to_json, headers: request_headers)
            .to_return(status: 200, body: new_response_body.to_json, headers: response_headers)

        put :update, params: { id: @stamp.id, stamp: { name: @oldname, user_editors: 'dirk'} }
        expect(flash[:success]).to match('Stamp updated')
      end
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


  def make_stamp_with_permission_data(stamp_id, stamp_name, owner, permission_id, permitted, permission_type)
    {
      data:
      {
        id: stamp_id,
        type: "stamps",
        attributes:
        {
          name: stamp_name,
          "owner-id": owner
        },
        relationships:
        {
          permissions:
          {
            data: [{ type: "permissions", id: permission_id}]
          }
        }
      },
      included:
      [
        {
          id: permission_id,
          type: "permissions",
          attributes:
          {
            "permission-type": permission_type,
            permitted: permitted,
            "accessible-id": stamp_id
          }
        }
      ]
    }
  end

  def make_stamp_without_permission_data(stamp_id, stamp_name, owner)
    {
      data:
      {
        id: stamp_id,
        type: "stamps",
        attributes:
        {
          name: stamp_name,
          "owner-id": owner
        },
        relationships:
        {
          permissions:
          {
            data: []
          }
        }
      },
      included:
      []
    }
  end

end

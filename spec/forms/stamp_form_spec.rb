require 'rails_helper'

RSpec.describe StampForm do
  let(:user) { create(:user) }
  let(:content_type) { 'application/vnd.api+json' }
  let(:request_headers) { { 'Accept' => content_type, 'Content-Type'=> content_type } }
  let(:response_headers) { { 'Content-Type' => content_type } }
  let(:url) { 'http://localhost:7000/api/v1/' }

  describe '#new' do
    let(:form) { StampForm.new(name: 'dirk', group_editors: 'zombies,pirates', user_consumers: 'zogh') }

    it 'has the attributes specified that are in the ATTRIBUTES list' do
      expect(form.name).to eq 'dirk'
      expect(form.group_editors).to eq('zombies,pirates')
      expect(form.user_consumers).to eq('zogh')
    end
    it 'has nil for attributes that were not specified' do
      expect(form.id).to be_nil
      expect(form.user_editors).to be_nil
      expect(form.group_consumers).to be_nil
    end
  end

  describe '#save' do
    let(:stamp) do
      r = build(:stamp, name: 'stamp1')
      r.save
      r
    end

    context 'when the form creates a new stamp with the correct converted permissions' do
      let(:form) { StampForm.new(name: 'jelly', user_editors: 'dirk,jeff', group_editors: 'zombies,   PIRATES', user_consumers: 'DIRK', group_consumers: 'ninjas') }

      before do
        @new_id = SecureRandom.uuid
        @name = "jelly"
        @owner = user.email

        stamp_data = make_stamp_data(@new_id, @name, @owner)

        stub_request(:post, url+"stamps")
          .with( body: { data: { type: "stamps", attributes: { name: "jelly" }}}.to_json, headers: request_headers )
          .to_return(status: 201, body: { data: stamp_data }.to_json, headers: response_headers)

        stub_request(:get, stamp_urlid(@new_id))
         .with(headers: request_headers)
         .to_return(status: 200, body: { data: stamp_data }.to_json, headers: response_headers)

        @permission_id1 = "1"
        @permission_type1 = :edit
        @permitted1 = 'dirk@sanger.ac.uk,jeff@sanger.ac.uk,zombies,PIRATES'

        @permission_id2 = "2"
        @permission_type2 = :consume
        @permitted2 = 'dirk@sanger.ac.uk,ninjas'

        stub_data = { data: [{permitted: "dirk@sanger.ac.uk", "permission-type": :edit}, { permitted: "jeff@sanger.ac.uk", "permission-type": :edit },{permitted: "zombies", "permission-type": :edit}, {permitted: "pirates", "permission-type": :edit},{permitted: "dirk@sanger.ac.uk", "permission-type": :consume}, {permitted: "ninjas", "permission-type": :consume}]}
        response_body = make_stamp_with_permission_data(@new_id, @name, @owner_id, @permission_id1, @permitted1, @permission_type1, @permission_id2, @permitted2, @permission_type2)

        stub_request(:post, stamp_urlid(@new_id)+"/set_permissions").
          with(body: stub_data.to_json,
              headers: request_headers).
          to_return(status: 200, body: response_body.to_json, headers: response_headers)


        stub_request(:get, stamp_urlid(@new_id)+"?include=permissions")
          .with(headers: request_headers )
          .to_return(status: 200, body: response_body.to_json, headers: response_headers)

        @result = form.save
     end

      it 'has an id' do
        expect(@result.id).to eq(@new_id)
      end

      it 'has a name' do
        expect(@result.name).to eq(@name)
      end

      it 'creates a stamp as described' do
        stamp = StampClient::Stamp.find(@result.id)
        expect(stamp).not_to be_nil
        expect(stamp.first.name).to eq(@name)
        expect(stamp.first.owner_id).to eq(@owner)
      end

      it 'sets up the correct permissions' do
        stamp = StampClient::Stamp.find_with_permissions(@new_id)
        permissions = stamp.first.permissions
        expect(permissions).not_to be_nil
        expect(permissions.length).to eq 2
        permission1 = permissions&.first
        expect(permission1.id).to eq @permission_id1
        expect(permission1.permission_type).to eq @permission_type1
        expect(permission1.permitted).to eq @permitted1
        permission2 = permissions&.last
        expect(permission2.id).to eq @permission_id2
        expect(permission2.permission_type).to eq @permission_type2
        expect(permission2.permitted).to eq @permitted2
        expect(permission2.accessible_id).to eq @new_id
      end
    end
  end

  def stamp_urlid(id)
    url+'stamps/'+id
  end

  def make_stamp_data(id, name, owner_id)
    {
      id: id,
      type: "stamps",
      attributes: {
        name: name,
        'owner-id': owner_id
      }
    }
  end

  def make_stamp_with_permission_data(stampid, name, owner_id, permission_id1, permitted1, permission_type1, permission_id2, permitted2, permission_type2)
    {
      data:
      {
        id: stampid,
        type: "stamps",
        attributes:
        {
          name: name,
          "owner-id": owner_id
        },
        relationships:
        {
          permissions:
          {
            data: [{ type: "permissions", id: permission_id1}, { type: "permissions", id: permission_id2}]
          }
        }
      },
      included:
      [
        {
          id: permission_id1,
          type: "permissions",
          attributes:
          {
            "permission-type": permission_type1,
            permitted: permitted1,
            "accessible-id": stampid
          }
        },
        {
          id: permission_id2,
          type: "permissions",
          attributes:
          {
            "permission-type": permission_type2,
            permitted: permitted2,
            "accessible-id": stampid
          }
        }
      ]
    }
  end

end

require 'rails_helper'

RSpec.describe DeputyForm do

  describe '#new' do
    let(:form) { DeputyForm.new(user_email: 'jeff', user_deputies: 'user1,user2', group_deputies: 'group1,group2') }

    it 'has the attributes specified that are in the ATTRIBUTES list' do
      expect(form.user_deputies).to eq('user1,user2')
      expect(form.group_deputies).to eq('group1,group2')
    end

    it 'has nil for attributes that were not specified' do
      expect(form.id).to be_nil
    end
  end

  describe '#save' do
    context 'validation' do
      let(:form1) { DeputyForm.new() }
      let(:form2_1) { DeputyForm.new(user_deputies: 'zs56d87fvbc`/;') }
      let(:form2_2) { DeputyForm.new(group_deputies: 'zs56d87fvbc`/;') }
      let(:form3) { DeputyForm.new(user_deputies: 'pirates zombies, clowns', group_deputies: 'zogh') }
      let(:form4) { DeputyForm.new(group_deputies: 'zogh653,dirk_123') }

      before do
        allow_any_instance_of(DeputyForm).to receive(:create_objects).and_return(true)
      end

      it 'not valid when nothing is specified' do
        @result = form1.save
        expect(@result).to be false
      end

      it 'not valid when a deputy is in the wrong format' do
        @result = form2_1.save
        expect(@result).to be false
        @result = form2_2.save
        expect(@result).to be false
      end

      it "is valid with all possible attributes" do
        @result = form3.save
        expect(@result).to be true
        @result = form4.save
        expect(@result).to be true
      end
    end

    context 'when creating a new DeputyForm' do
      let(:form) { DeputyForm.new(user_deputies: 'pirates zombies, clowns', group_deputies: 'zogh') }

      it 'calls create_objects' do
        expect(form).to receive(:create_objects)
        form.save
      end
    end
  end
end

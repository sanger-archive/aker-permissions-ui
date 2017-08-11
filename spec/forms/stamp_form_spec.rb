require 'rails_helper'

RSpec.describe StampForm do
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
    context 'validation' do
      let(:form1) { StampForm.new(name: '', group_editors: 'zombies,pirates', user_consumers: 'zogh') }
      let(:form2) { StampForm.new(name: 'stamp_2', group_editors: 'zs56d87fvbc`/;') }
      let(:form3) { StampForm.new(name: 'stamp.,/', group_editors: 'pirates zombies, clowns', user_consumers: 'zogh') }
      let(:form4) { StampForm.new(name: 'stamp-3', user_editors: 'zogh653@sanger.ac.uk,dirk_123', group_editors: 'ab12c,     cbj45_', user_consumers: 'di23rk, dsio_290-', group_consumers: 'x64z') }

      before do
        allow_any_instance_of(StampForm).to receive(:create_objects).and_return(true)
      end

      it 'not valid when no name is specified' do
        @result = form1.save
        expect(@result).to be false
      end

      it 'not valid when a permission attribute is in the wrong format' do
        @result = form2.save
        expect(@result).to be false
      end

      it 'not valid when a name is in the wrong format' do
        @result = form3.save
        expect(@result).to be false
      end

      it "is valid with all possible attributes" do
        @result = form4.save
        expect(@result).to be true
      end
    end

    context 'when creating a new StampForm' do
      let(:form) { StampForm.new(name: 'stamp1', group_editors: 'zombies,pirates', user_consumers: 'zogh') }

      it 'calls create_objects' do
        expect(form).to receive(:create_objects)
        expect(form).not_to receive(:update_objects)
        form.save
      end
    end

    context 'when updating a StampForm' do
      let(:form) { StampForm.new(id: '123', name: 'stamp1', group_editors: 'zombies,pirates', user_consumers: 'zogh') }

      it 'calls update_objects' do
        expect(form).to receive(:update_objects)
        expect(form).not_to receive(:create_objects)
        form.save
      end
    end
  end

  describe '#from_stamp' do
    let(:form) { StampForm.new(id: '123', name: 'stamp1', group_editors: 'pirates') }
    let(:stamp) { build(:stamp, id: '321', name: 'stamp1', group_editors: ['pirates']) }

    it 'calls create_stamps' do
      expect(StampForm).to receive(:attributes_from_stamp).and_return({ id: stamp.id, name: stamp.name, group_editors: ['pirates']})
      expect(StampForm).to receive(:new).with({ id: stamp.id, name: stamp.name, group_editors: ['pirates']})

      stamp_form = StampForm.from_stamp(stamp)
    end
  end

end

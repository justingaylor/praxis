require 'spec_helper'

describe Praxis::Plugins::Authorization do
  let(:resource_definition) do
    Class.new do
      include Praxis::ResourceDefinition
    end
  end
  let(:action_definition) { Praxis::ActionDefinition.new(:foo, resource_definition) }

  let(:defined_scopes) { {something: {}, another: {}} }

  before do
    allow(Praxis::ApiDefinition.instance.info(resource_definition.version)).
      to receive(:authorization_scopes).and_return(defined_scopes)
  end

  context '.check_authorization' do
  end

  context 'ApiGeneralInfo additions' do
    subject(:info){ Praxis::ApiGeneralInfo.new }

    context 'with authorization_scope set' do
      let(:info_block) do
        Proc.new do
          authorization_scope :something, description: 'must do something'
          authorization_scope :another, description: 'along with another thing'
        end
      end

      subject(:authorization_scopes){ info.authorization_scopes}

      before do
        info.instance_exec(&info_block)
      end

      its([:something]) { should eq(description: 'must do something') }
      its([:another]) { should eq(description: 'along with another thing') }
    end

    context 'without authorization_scope' do
      its(:authorization_scopes) { should eq({})}
    end
  end

  context 'ResourceDefinition additions' do

    context '.authorization_scope' do
      subject(:authorization_scope) { resource_definition.authorization_scope }
      it { should be nil }


      context 'with an unknown scope name' do
        it 'raises an error' do
          expect {
            resource_definition.authorization_scope :unknown
          }.to raise_error(/Undefined authorization_scope/)
        end
      end

      context 'with a known scope name' do
         before do
           resource_definition.authorization_scope(:something)
         end

         it { should match_array [:something] }
      end

    end
  end

  context 'ActionDefinition additions' do

    context '.authorization_scope' do
      subject(:authorization_scope) { action_definition.authorization_scope }

      it { should be nil }

      it 'may be set on the action directly' do
        action_definition.authorization_scope :another
        expect(action_definition.authorization_scope).to match_array [:another]
      end

      context 'with an unknown scope name' do
        it 'raises an error' do
          expect {
            action_definition.authorization_scope :unknown
          }.to raise_error(/Undefined authorization_scope/)
        end
      end

      context 'inheriting from the ResourceDefinition' do
        before do
          resource_definition.authorization_scope :something
        end
        it { should match_array [:something] }

        it 'can be overriden' do
          action_definition.authorization_scope :another
          expect(action_definition.authorization_scope).to match_array [:another]
        end
      end

    end

    context '.authorization' do
      let(:authorization_block) do
        Proc.new do
        end
      end

      before do
        action_definition.instance_exec(&authorization_block)
      end

      context 'privilege' do
        let(:authorization_block) do
          Proc.new do
            authorization do
              privilege 'foo', description: 'stuff'
            end
          end
        end
        it 'sets the privileges' do
          expect(action_definition.privileges['foo']).to eq 'stuff'
        end
      end

      context 'no_privilege' do
        let(:authorization_block) do
          Proc.new do
            authorization do
              no_privilege
            end
          end
        end
        it 'sets the privileges' do
          expect(action_definition.privileges).to eq({})
        end
      end

      it 'defaults privileges to nil' do
        expect(action_definition.privileges).to be nil
      end

    end

  end
end

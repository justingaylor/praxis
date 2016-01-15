require 'spec_helper'

describe Praxis::Plugins::Authorization do
  context 'ResourceDefinition additions' do
    context '.authorization_scope' do

      it 'applies properly' do
        expect(ApiResources::Volumes.authorization_scope).to match_array([:cloud])
        # expect(V2::Definitions::Projects.authorization_scope).to match_array([:project])
        # expect(V2::Definitions::Users.authorization_scope).to match_array([:current_user])
        # expect(V2::Definitions::UserOrgs.authorization_scope).to match_array([:current_user, :org])
      end

      it 'defaults to nil' do
        expect(V2::Definitions::UserIdentities.authorization_scope).to be_nil
      end
    end
  end

  context 'ActionDefinition additions' do
    context '.authorization_scope' do
      it 'inherits from ResourceDefinition' do
        action = V2::Definitions::OrgProjects.actions[:index]
        expect(action.authorization_scope).to match_array([:org])
      end

      it 'can override in an action' do
        action = V2::Definitions::OrgProjects.actions[:show]
        expect(action.authorization_scope).to match_array([:project])
      end
    end
  end
end

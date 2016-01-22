module Praxis
  module Plugins
    module Authorization
      include Praxis::PluginConcern

      # Simple entrypoint that delegates to the instance of the plugin
      def self.check_authorization(controller)
        Plugin.instance.check_authorization(controller)
      end

      class Plugin < Praxis::Plugin
        include Singleton

        def config_key
          :auth
        end

        def prepare_config!(node)
          node.attributes do
            attribute :adapter, Attributor::Class,
                      description: 'The adapter class'
          end
        end

        def load_config!
          fail 'Must set adapter!' unless options[:adapter]
          #fail "adapter must be of class Method, got: #{options[:adapter].class}" unless options[:adapter].is_a? ::Method
          { adapter: options[:adapter] }
        end

        def check_authorization(controller)
          request = controller.request
          unless request.action.privileges
            raise "An authorization block is missing for the action #{request.action.name.inspect}"
          end

          # There must always be privileges if we are this far
          # Likewise, there must always be a principal

          privileges = request.action.privileges.keys

          config.adapter.call controller, privileges
        rescue => e
          App::Config.logger.error "Error: #{e.class.name}, Message: #{e.message}"
          return Praxis::Responses::Forbidden.new(body: 'forbidden')
        end
      end

      module ApiGeneralInfo
        extend ActiveSupport::Concern

        def authorization_scope(val=nil, **opts)
          if val.nil?
            get(:authorization_scopes) || {}
          else
            existing = get(:authorization_scopes) || {}
            set(:authorization_scopes, existing.merge(val => opts))
          end
        end

        def authorization_scopes
          get(:authorization_scopes) || {}
        end
      end

      module ResourceDefinition
        extend ActiveSupport::Concern

        module ClassMethods
          def authorization_scope(*values)
            return @authorization_scopes if values.empty?
            bad_scopes = values - Praxis::ApiDefinition.instance.info(self.version).authorization_scopes.keys
            fail "Undefined authorization_scope received for #{self.name}: #{bad_scopes.join(', ')}. Please define it in your ApiDefinition." unless bad_scopes.empty?
            @authorization_scopes = [values].flatten
          end
          def authorization_scopes
            @authorization_scopes ||= []
          end
        end
      end

      module ActionDefinition
        extend ActiveSupport::Concern

        included do
          decorate_docs do |_action, _docs|
            # TODO: do
            # docs[:authorization] = "AUTH[#{@authorized_resource}] => #{@authorized_actions}"
          end
        end

        class DSL
          attr_reader :privileges

          def privilege(privilege, description: nil)
            @privileges ||= {}
            fail "Privilege \"#{privilege}\" already defined for action!" if @privileges[privilege]
            @privileges[privilege] = description
          end

          def no_privilege
            # authorization will raise if @privileges == nil
            @privileges ||= {}
          end
        end

        attr_reader :privileges

        def authorization_scope(*values)
          if values.any?
            bad_scopes = values - Praxis::ApiDefinition.instance.info(self.resource_definition.version).authorization_scopes.keys
            fail "Undefined authorization_scope received for #{self.resource_definition.name}##{self.name}: #{bad_scopes.join(', ')}" unless bad_scopes.empty?
            return @authorization_scope = values
          end

          if @authorization_scope.nil?
            @authorization_scope = resource_definition.authorization_scope
          end

          @authorization_scope
        end

        def authorization(&blk)
          fail 'authorization can only be called once per action!' unless @privileges.nil?
          d = DSL.new
          d.instance_eval(&blk)
          @privileges = d.privileges
          fail 'Must call privilege or no_privilege at least once inside the authorization block.' if @privileges.nil?

          # TODO: What is the purpose of this line?
          response :forbidden unless @privileges.empty?
        end
      end

      # Example Authorization Adapters for specs
      class OptimisticAdapter

      end
    end
  end
end

module Messaging
  module Message
    class Metadata
      class Error < RuntimeError; end

      include Schema::DataStructure

      attribute :stream_name, String
      alias :source_message_stream_name :stream_name
      alias :source_message_stream_name= :stream_name=

      attribute :position, Integer
      alias :source_message_position :position
      alias :source_message_position= :position=

      attribute :global_position, Integer
      alias :source_message_global_position :global_position
      alias :source_message_global_position= :global_position=
      alias :sequence :global_position
      alias :sequence= :global_position=

      attribute :causation_message_stream_name, String
      attribute :causation_message_position, Integer
      attribute :causation_message_global_position, Integer
      alias :causation_sequence :causation_message_global_position
      alias :causation_sequence= :causation_message_global_position=

      attribute :correlation_stream_name, String
      alias :origin_stream_name :correlation_stream_name
      alias :origin_stream_name= :correlation_stream_name=
      alias :origin :correlation_stream_name
      alias :origin= :correlation_stream_name=

      attribute :reply_stream_name, String

      attribute :properties, Array, default: -> { Array.new }

      attribute :time, Time

      attribute :schema_version, String

      def identifier
        return nil if stream_name.nil? || position.nil?
        "#{stream_name}/#{position}"
      end
      alias :source_message_identifier :identifier

      def causation_message_identifier
        return nil if causation_message_stream_name.nil? || causation_message_position.nil?
        "#{causation_message_stream_name}/#{causation_message_position}"
      end
      alias :causation_identifier :causation_message_identifier

      def follow(preceding_metadata)
        self.causation_message_stream_name = preceding_metadata.stream_name
        self.causation_message_position = preceding_metadata.position
        self.causation_message_global_position = preceding_metadata.global_position

        self.correlation_stream_name = preceding_metadata.correlation_stream_name

        self.reply_stream_name = preceding_metadata.reply_stream_name

        preceding_metadata.properties.each do |property|
          if property.transient?
            next
          end

          set_property(
            property.name,
            property.value,
            transient: property.transient
          )
        end
      end

      def follows?(preceding_metadata)
        if causation_message_stream_name.nil? && preceding_metadata.stream_name.nil?
          return false
        end

        if causation_message_stream_name != preceding_metadata.stream_name
          return false
        end


        if causation_message_position.nil? && preceding_metadata.position.nil?
          return false
        end

        if causation_message_position != preceding_metadata.position
          return false
        end


        if causation_message_global_position.nil? && preceding_metadata.global_position.nil?
          return false
        end

        if causation_message_global_position != preceding_metadata.global_position
          return false
        end


        if not preceding_metadata.correlation_stream_name.nil?
          if correlation_stream_name != preceding_metadata.correlation_stream_name
            return false
          end
        end


        if not preceding_metadata.reply_stream_name.nil?
          if reply_stream_name != preceding_metadata.reply_stream_name
            return false
          end
        end

        true
      end

      def clear_reply_stream_name
        self.reply_stream_name = nil
      end

      def reply?
        !reply_stream_name.nil?
      end

      def correlated?(stream_name)
        correlation_stream_name = self.correlation_stream_name

        return false if correlation_stream_name.nil?

        stream_name = Category.normalize(stream_name)

        if MessageStore::StreamName.category?(stream_name)
          correlation_stream_name = MessageStore::StreamName.get_category(correlation_stream_name)
        end

        correlation_stream_name == stream_name
      end
      alias :correlates? :correlated?

      def set_property(name, value, transient: nil)
        transient ||= false

        delete_property(name)

        property = Property.new(name, value, transient)

        properties << property

        property
      end

      def set_transient_property(name, value, transient: nil)
        set_property(name, value, transient: true)
      end

      def get_property(name)
        property = properties.find { |property| property.name == name }
        property&.value
      end

      def delete_property(name)
        i = properties.index { |property| property.name == name }

        return nil if i.nil?

        properties.delete_at(i).value
      end

      def clear_properties
        properties.clear
      end

      def self.source_attribute_names
        [
          :stream_name,
          :position,
          :global_position
        ]
      end

      def self.causation_attribute_names
        [
          :causation_message_stream_name,
          :causation_message_position,
          :causation_message_global_position
        ]
      end

      def self.origin_attribute_names
        [
          :correlation_stream_name,
          :reply_stream_name
        ]
      end

      def self.workflow_attribute_names
        causation_attribute_names + origin_attribute_names
      end

      def self.transient_attributes
        [
          :stream_name,
          :position,
          :global_position,
          :time
        ]
      end
    end
  end
end

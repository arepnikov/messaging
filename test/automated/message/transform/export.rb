require_relative '../../automated_init'

context "Message" do
  context "Export" do
    message = Controls::Message.example

    message_data = Message::Export.(message)

    context "Message is exported to MessageData" do
      test "MessageData type is Message's type" do
        assert(message.message_type == message_data.type)
      end

      test "MessageData's attributes are equal to the message's attributes" do
        assert(message_data.data == message.to_h)
      end

      context "MessageData's metadata attributes are equal to the message's metadata attributes" do
        [
          :causation_message_stream_name,
          :causation_message_position,
          :causation_message_global_position,
          :correlation_stream_name,
          :reply_stream_name,
          :schema_version
        ].each do |attribute|
          test "#{attribute}" do
            assert(message.metadata.send(attribute) == message_data.metadata[attribute])
          end
        end
      end
    end
  end
end

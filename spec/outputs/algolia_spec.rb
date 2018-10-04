# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/algolia"
require "logstash/codecs/plain"
require "logstash/event"
require 'algolia/webmock'

describe LogStash::Outputs::Algolia do
  before(:each) do
    WebMock.enable!
  end


  let(:output) do
    LogStash::Outputs::Algolia.new({
      "application_id" => "fake-app-id",
      "api_key" => "fake-app-key",
      "action" => "%{[_action]}",
      "index" => "%{[_index]}"
    })
  end

  before do
    output.register
  end

  describe "receive message" do
    let(:event_in_index1) { index_event("event1", "index1") }
    let(:event_in_index2) { index_event("event2", "index2") }
    let(:other_event_in_index2) { index_event("event3", "index2") }
    let(:event_to_delete) { delete_event("event4", "index2") }

    subject { output.multi_receive([event_in_index1, event_in_index2, other_event_in_index2, event_to_delete]) }

    it "groups events by indices" do
      expect(Algolia::Index).to receive(:new).with("index1").and_wrap_original do |m, *args|
        index = m.call(*args)
        expect(index).to receive(:add_objects).with([event_in_index1.to_hash])

        index
      end

      expect(Algolia::Index).to receive(:new).with("index2").and_wrap_original do |m, *args|
        index = m.call(*args)
        expect(index).to receive(:add_objects).with([event_in_index2.to_hash, other_event_in_index2.to_hash])
        expect(index).to receive(:delete_objects).with(["event4"])

        index
      end

      is_expected.to eq nil
    end
  end

  def index_event(id, index)
    event = LogStash::Event.new
    event.set("objectID", id)
    event.set("_index", index)
    event.set("_action", "index")

    event
  end

  def delete_event(id, index)
    event = LogStash::Event.new
    event.set("objectID", id)
    event.set("_index", index)
    event.set("_action", "delete")

    event
  end

  after(:each) do
    WebMock.disable!
  end
end
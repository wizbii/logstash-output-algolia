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


  let(:output) { LogStash::Outputs::Algolia.new({"application_id" => "fake-app-id", "api_key" => "fake-app-key"}) }

  before do
    output.register
  end

  describe "receive message" do
    let(:event_in_index1) { create_event("event1", "index1") }
    let(:event_in_index2) { create_event("event2", "index2") }
    let(:other_event_in_index2) { create_event("event3", "index2") }

    subject { output.multi_receive([event_in_index1, event_in_index2, other_event_in_index2]) }

    it "groups events by indices" do
      expect(Algolia::Index).to receive(:new).with("index1").and_wrap_original do |m, *args| 
        index = m.call(*args)
        expect(index).to receive(:add_objects).with([event_in_index1.to_hash])

        index
      end

      expect(Algolia::Index).to receive(:new).with("index2").and_wrap_original do |m, *args| 
        index = m.call(*args)
        expect(index).to receive(:add_objects).with([event_in_index2.to_hash, other_event_in_index2.to_hash])
        
        index
      end

      is_expected.to eq nil
    end
  end

  def create_event(id, index)
    event = LogStash::Event.new 
    event.set("_id", id)
    event.set("_index", index)

    event
  end

  after(:each) do
    WebMock.disable!
  end
end

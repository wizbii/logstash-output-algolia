# encoding: utf-8
require "logstash/outputs/base"
require "algoliasearch"

# An algolia output that does nothing.
class LogStash::Outputs::Algolia < LogStash::Outputs::Base
  config_name "algolia"
  
  config :application_id, :validate => :string, :required => true
  config :api_key, :validate => :string, :required => true

  def register
    @algolia_client = Algolia.init(application_id: @application_id, api_key: @api_key)

    @indices = {}
  end # def register

  def multi_receive(events)
    events
      .group_by { |e| e.get('_index') }
      .each do |index_name, events|
        # todo: group `add_objects` calls by bulks of 10MB max
        partitions(events).each do |events_group|
          get_index(index_name).add_objects(events_group.map(&:to_hash))
        end
      end
    nil
  end # def event

  def get_index(name)
    @indices[name] ||= Algolia::Index.new(name)
  end

  def partitions(events)
    [events]
  end
end # class LogStash::Outputs::Algolia

# encoding: utf-8
require "logstash/outputs/base"
require "algoliasearch"
require 'json'

# An algolia output that does nothing.
class LogStash::Outputs::Algolia < LogStash::Outputs::Base
  config_name "algolia"

  VALID_ACTIONS = ["delete", "index"]
  MAX_BATCH_SIZE_IN_BYTES = 10_000_000

  config :application_id, :validate => :string, :required => true
  config :api_key, :validate => :string, :required => true
  config :index, :validate => :string, :required => true

  # The Algolia action to perform. Valid actions are:
  #
  # - index: indexes a document (an event from Logstash).
  # - delete: deletes a document by id (An 'objectID' field is required for this action)
  # - A sprintf style string to change the action based on the content of the event. The value `%{[foo]}`
  #   would use the foo field for the action
  config :action, :validate => :string, :required => false, :default => "index"

  def register
    @algolia_client = Algolia.init(application_id: @application_id, api_key: @api_key)

    @indices = {}
  end # def register

  def multi_receive(events)
    events
      .group_by { |e| e.sprintf(@action) }
      .select { |action, events| valid_action?(action) }
      .each do |action, events|
        events
          .select { |e| valid_event?(e, action) }
          .group_by { |e| e.sprintf(@index) }
          .each do |index_name, events|
            partitions(events).each do |events_group|
              do_action(action, events, get_index(index_name))
            end
          end
      end

    nil
  end # def multi_receive


  def get_index(name)
    @indices[name] ||= Algolia::Index.new(name)
  end

  def partitions(events)
    sorted_sized_events = events
      .map { |event| { event_body: event, event_size: event.to_json.size } }
      .sort_by { |event_hash| event_hash[:event_size]}
      .reverse
      .reduce([{batch_events: [], batch_size: 0}]) { |batches, event_hash| 
        found_a_place = false
        return batches << {batch_events: [event_hash[:event_body]], batch_size: event_hash[:event_size]} if (event_hash[:event_size] > MAX_BATCH_SIZE_IN_BYTES)
        batches.each_with_index do |bin, i|
          if (batches[i][:batch_size] + event_hash[:event_size] <= MAX_BATCH_SIZE_IN_BYTES)
            batches[i][:batch_size] += event_hash[:event_size]
            batches[i][:batch_events] << event_hash[:event_body] 
            found_a_place = true
            break
          end
        end
        unless found_a_place
          batches << {batch_events: [event_hash[:event_body]], batch_size: event_hash[:event_size]}
        end
        batches
      }
      .map { |batch| batch[:batch_events]}
    
  end

  def add_or_create_batch(batches, event_hash)

  end


  def valid_action?(action)
    return true if VALID_ACTIONS.include?(action)

    @logger.error("Invalid action given: '#{action}'")

    false
  end

  def valid_event?(e, action)
    if action == "delete" && e.get("objectID").nil?
      @logger.error("Invalid event for 'delete' action: no 'objectID' field")

      return false
    end

    true
  end

  def do_action(action, events, algolia_index)
    case action
    when "index"
      algolia_index.add_objects(events.map(&:to_hash))
    when "delete"
      algolia_index.delete_objects(events.map { |e| e.get("objectID") })
    end
  end
end # class LogStash::Outputs::Algolia

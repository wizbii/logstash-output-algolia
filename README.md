# Logstash Algolia Output Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Getting started

Available configuration keys: 
- `application_id`
- `api_key`
- `index`
- `action` > optional, could be `index` (default) or `delete`. If you choose `delete`, your events should have a `objectID` property

An example configuration to copy data from elasticsearch: 

```
input {
  elasticsearch {
    index => "your_index"
  }
}

output {
  algolia {
    application_id => "..."
    api_key => "..."
    index => "your_index"
  }
}
```


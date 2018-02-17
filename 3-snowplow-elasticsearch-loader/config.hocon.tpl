# Copyright (c) 2014-2016 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0, and
# you may not use this file except in compliance with the Apache License
# Version 2.0.  You may obtain a copy of the Apache License Version 2.0 at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Apache License Version 2.0 is distributed on an "AS
# IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the Apache License Version 2.0 for the specific language
# governing permissions and limitations there under.

# This file (config.hocon.sample) contains a template with
# configuration options for the Elasticsearch Loader.

# Sources currently supported are:
# "kinesis" for reading records from a Kinesis stream
# "stdin" for reading unencoded tab-separated events from stdin
# If set to "stdin", JSON documents will not be sent to Elasticsearch
# but will be written to stdout.
# "nsq" for reading unencoded tab-separated events from NSQ
source = "kinesis"

# Where to write good and bad records
sink {
  # Sinks currently supported are:
  # "elasticsearch" for writing good records to Elasticsearch
  # "stdout" for writing good records to stdout
  good = "elasticsearch"

  # Sinks currently supported are:
  # "kinesis" for writing bad records to Kinesis
  # "stderr" for writing bad records to stderr
  # "nsq" for writing bad records to NSQ
  # "none" for ignoring bad records
  bad = "kinesis"
}

# "good" for a stream of successfully enriched events
# "bad" for a stream of bad events
# "plain-json" for writing plain json
enabled = "good"

# The following are used to authenticate for the Amazon Kinesis sink.
#
# If both are set to "default", the default provider chain is used
# (see http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/DefaultAWSCredentialsProviderChain.html)
#
# If both are set to "iam", use AWS IAM Roles to provision credentials.
#
# If both are set to "env", use environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
aws {
  accessKey = "${access-key}"
  secretKey = "${secret-key}"
}

# config for NSQ
nsq {
  # Channel name for NSQ source
  # If more than one application reading from the same NSQ topic at the same time,
  # all of them must have unique channel name for getting all the data from the same topic
  channelName = "None"

  # Host name for NSQ tools
  host = "none.not_applicable.com"

  # HTTP port for nsqd
  port = "9999"

  # HTTP port for nsqlookupd
  lookupPort = "9999"
}

kinesis {
  # "LATEST": most recent data.
  # "TRIM_HORIZON": oldest available data.
  # "AT_TIMESTAMP": Start from the record at or after the specified timestamp
  # Note: This only affects the first run of this application on a stream.
  initialPosition = "TRIM_HORIZON"

  # Need to be specified when initial-position is "AT_TIMESTAMP".
  # Timestamp format need to be in "yyyy-MM-ddTHH:mm:ssZ".
  # Ex: "2017-05-17T10:00:00Z"
  # Note: Time need to specified in UTC.
  initialTimestamp = ""

  # Maximum number of records to get from Kinesis per call to GetRecords
  maxRecords = 10000

  # Region where the Kinesis stream is located
  region = "${aws-region}"

  # "appName" is used for a DynamoDB table to maintain stream state.
  # You can set it automatically using: "SnowplowElasticsearchSink-$\\{sink.kinesis.in.stream-name}"
  appName = "SnowplowLoader-${stream-in}"
}

# Common configuration section for all stream sources
streams {
  inStreamName = "${stream-in}"

  # Stream for enriched events which are rejected by Elasticsearch
  outStreamName = "${bad-stream-out}"

  # Events are accumulated in a buffer before being sent to Elasticsearch.
  # The buffer is emptied whenever:
  # - the combined size of the stored records exceeds byteLimit or
  # - the number of stored records exceeds recordLimit or
  # - the time in milliseconds since it was last emptied exceeds timeLimit
  buffer {
    byteLimit = 300000
    recordLimit = 200 # Not supported by Kafka; will be ignored
    timeLimit = 5000
  }
}

elasticsearch {

  # Events are indexed using an Elasticsearch Client
  # - endpoint: the cluster endpoint
  # - port: the port the cluster can be accessed on
  #   - for http this is usually 9200
  #   - for transport this is usually 9300
  # - max-timeout: the maximum attempt time before a client restart
  # - ssl: if using the http client, whether to use ssl or not
  client {
    endpoint = "${elasticsearch-url}"
    port = "9200"
    maxTimeout = "30"
    ssl = true
  }

  # When using the AWS ES service
  # - signing: if using the http client and the AWS ES service you can sign your requests
  #    http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
  # - region where the AWS ES service is located
  aws {
    signing = true
    region = "${aws-region}"
  }

  # index: the Elasticsearch index name
  # type: the Elasticsearch index type
  cluster {
    name = "elasticsearch"
    index = "snowplow"
    clusterType = "keyword"
  }
}


# Optional section for tracking endpoints
monitoring {
  snowplow {
    collectorUri = ""
    collectorPort = ""
    appId = ""
    method = ""
  }
}

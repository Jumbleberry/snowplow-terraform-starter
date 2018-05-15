# Default configuration for s3-loader

# Sources currently supported are:
# 'kinesis' for reading records from a Kinesis stream
# 'nsq' for reading records from a NSQ topic
source = "kinesis"

# Sink is used for sending events which processing failed.
# Sinks currently supported are:
# 'kinesis' for writing records to a Kinesis stream
# 'nsq' for writing records to a NSQ topic
sink = "kinesis"

# The following are used to authenticate for the Amazon Kinesis sink.
# If both are set to 'default', the default provider chain is used
# (see http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/DefaultAWSCredentialsProviderChain.html)
# If both are set to 'iam', use AWS IAM Roles to provision credentials.
# If both are set to 'env', use environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
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
  # LATEST: most recent data.
  # TRIM_HORIZON: oldest available data.
  # "AT_TIMESTAMP": Start from the record at or after the specified timestamp
  # Note: This only affects the first run of this application on a stream.
  initialPosition = "TRIM_HORIZON"

  # Need to be specified when initialPosition is "AT_TIMESTAMP".
  # Timestamp format need to be in "yyyy-MM-ddTHH:mm:ssZ".
  # Ex: "2017-05-17T10:00:00Z"
  # Note: Time need to specified in UTC.
  initialTimestamp = ""

  # Maximum number of records to read per GetRecords call     
  maxRecords = 10000

  # Region where the Kinesis stream is located
  region = "${aws-region}"

  # "appName" is used for a DynamoDB table to maintain stream state.
  appName = "${consumer-name}"
}

# Common configuration section for all stream sources
streams {
  inStreamName = "${stream-in}"

  # Stream for enriched events which are rejected by S3
  outStreamName = "${bad-stream-out}"

  # Events are accumulated in a buffer before being sent to S3.
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

s3 {
  region = "${aws-region}"
  bucket = "${s3-bucket-out}"

  # Format is one of lzo or gzip
  # Note, that you can use gzip only for enriched data stream.
  format = "lzo"

  # Maximum Timeout that the application is allowed to fail for
  maxTimeout = "500"
}

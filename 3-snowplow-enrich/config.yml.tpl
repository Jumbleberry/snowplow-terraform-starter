aws:
  # Credentials can be hardcoded or set in environment variables
  access_key_id: ${access-key}
  secret_access_key: ${secret-key}
  s3:
    region: ${aws-region}
    buckets:
      assets: s3://snowplow-hosted-assets # DO NOT CHANGE unless you are hosting the jarfiles etc yourself in your own bucket
      #jsonpath_assets: # If you have defined your own JSON Schemas, add the s3:// path to your own JSON Path files in your own bucket here
      #log:
      raw:
        in:                 # This is a YAML array of one or more in buckets - you MUST use hyphens before each entry in the array, as below
          - s3://${raw-bucket}                    # e.g. s3://my-old-collector-bucket
        processing: s3://${processing-bucket}/processing
        #archive:                                  # e.g. s3://my-archive-bucket/raw
      enriched:
        good: s3://${enriched-bucket}/good        # e.g. s3://my-out-bucket/enriched/good
        bad: s3://${enriched-bucket}/bad          # e.g. s3://my-out-bucket/enriched/bad
        errors: s3://${enriched-bucket}/error     # Leave blank unless :continue_on_unexpected_error: set to true below
        #archive:                                  # Where to archive enriched events to, e.g. s3://my-archive-bucket/enriched
      shredded:
        good: s3://${shredded-bucket}/good        # e.g. s3://my-out-bucket/shredded/good
        bad: s3://${shredded-bucket}/bad          # e.g. s3://my-out-bucket/shredded/bad
        errors: s3://${shredded-bucket}/error     # Leave blank unless :continue_on_unexpected_error: set to true below
        #archive:                                  # Where to archive shredded events to, e.g. s3://my-archive-bucket/shredded
  emr:
    ami_version: 5.9.0
    region: ${aws-region}        # Always set this
    jobflow_role: EMR_EC2_DefaultRole # Created using $ aws emr create-default-roles
    service_role: EMR_DefaultRole     # Created using $ aws emr create-default-roles
    placement:                        # Set this if not running in VPC. Leave blank otherwise
    ec2_subnet_id:                    # Set this if running in VPC. Leave blank otherwise
    ec2_key_name: ${key-pair-name}
    bootstrap: []           # Set this to specify custom boostrap actions. Leave empty otherwise
    software:
      hbase:                # Optional. To launch on cluster, provide version, "0.92.0", keep quotes. Leave empty otherwise.
      lingual:              # Optional. To launch on cluster, provide version, "1.1", keep quotes. Leave empty otherwise.
    # Adjust your Hadoop cluster below
    jobflow:
      job_name: Snowplow ETL # Give your job a name
      master_instance_type: m1.small
      core_instance_count: 2
      core_instance_type: m1.small
      core_instance_ebs:    # Optional. Attach an EBS volume to each core instance.
        volume_size: 100    # Gigabytes
        volume_type: "gp2"
        volume_iops: 400    # Optional. Will only be used if volume_type is "io1"
        ebs_optimized: false # Optional. Will default to true
      task_instance_count: 0 # Increase to use spot instances
      task_instance_type: m1.small
      task_instance_bid: 0.015 # In USD. Adjust bid, or leave blank for non-spot-priced (i.e. on-demand) task instances
    bootstrap_failure_tries: 3 # Number of times to attempt the job in the event of bootstrap failures
    configuration:
      yarn-site:
        yarn.resourcemanager.am.max-attempts: "1"
      spark:
        maximizeResourceAllocation: "true"
    additional_info:        # Optional JSON string for selecting additional features
collectors:
  format: thrift # For example: 'clj-tomcat' for the Clojure Collector, 'thrift' for Thrift records, 'tsv/com.amazon.aws.cloudfront/wd_access_log' for Cloudfront access logs or 'ndjson/urbanairship.connect/v1' for UrbanAirship Connect events
enrich:
  versions:
    spark_enrich: 1.13.0 # Version of the Spark Enrichment process
  continue_on_unexpected_error: true # Set to 'true' (and set :out_errors: above) if you don't want any exceptions thrown from ETL
  output_compression: NONE # Compression only supported with Redshift, set to NONE if you have Postgres targets. Allowed formats: NONE, GZIP
storage:
  versions:
    rdb_loader: 0.14.0
    rdb_shredder: 0.13.0        # Version of the Spark Shredding process
    hadoop_elasticsearch: 0.1.0 # Version of the Hadoop to Elasticsearch copying process
monitoring:
  tags: {} # Name-value pairs describing this job
  logging:
    level: DEBUG # You can optionally switch to INFO for production
  snowplow:
    method: get
    app_id: ADD HERE # e.g. snowplow
    collector: ADD HERE # e.g. d3rkrsqld9gmqf.cloudfront.net
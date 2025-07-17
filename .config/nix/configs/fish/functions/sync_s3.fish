function sync_s3 --description="Sync S3 data for given timestamp"
    aws s3 sync "s3://controller-development/control/$argv[1]" "data/control/$argv[1]"
end

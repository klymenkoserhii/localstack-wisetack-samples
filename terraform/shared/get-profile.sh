PROFILE="wisetack-feature2"

if [[ "${PROFILE}" == "local" ]]; then
  if [[ ! $(type -P "awslocal") ]]; then
    echo "To use the 'local' profile you need to install awslocal. Run this and retry:"
    echo "  pip install awscli-local"
    echo "  also you need to add credentials for 'local' profile to ~/.aws/credentials"
    exit 1
  fi

  # For TF backend configuration
  export AWS_S3_ENDPOINT="http://s3.localhost.localstack.cloud:4566"
  export AWS_STS_ENDPOINT="http://localhost:4566"

  # For TF plans
  export TF_VAR_use_localstack="true"
fi

# Use awslocal for localstack
function aws() {
  if [[ "${PROFILE}" == "local" ]]; then
    awslocal "$@"
  else
    $(which aws) "$@"
  fi
}

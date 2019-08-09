#!/bin/bash -x

DATE=$(date "+%Y%m%d-%H%M%S")
VERSION=$(git log --pretty=format:%h | head -n 1)
FILE_NAME=${DATE}-${VERSION}.zip

zip -r ${FILE_NAME} --exclude=*.elixir_ls* --exclude=hello_world/deps/* --exclude=hello_world/_build/* . || (echo "error zip"; exit 1)
aws --profile aws_template s3 cp ${FILE_NAME} s3://myproduct-release/api/ || (echo "error upload to S3"; exit 1)
rm ${FILE_NAME}
export VERSION=${DATE}-${VERSION}


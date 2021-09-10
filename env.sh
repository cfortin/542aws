#!/bin/bash
# This script will help you set up your environment for aws and help you understand where you are. 
# $ source env.sh --staging for staging environment
# $ source env.sh --production for production environment

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "script ${BASH_SOURCE[0]} is being sourced"
else
    echo "ERROR: you probably want to source this script with \$source ${BASH_SOURCE[0]} --staging"
    exit 1
fi

alias aws='/usr/local/bin/aws'

# This script assumes that you ~/.aws/credentials file looks something like below.
# account: 112319184931 is production and account: 533016277303 is staging.
 
# [112319184931]
# aws_access_key_id = <key_id>
# aws_secret_access_key = <secret_key>
#
# [533016277303]
# aws_access_key_id = <key_id>
# aws_secret_access_key = <secret_key>

if [[ $* == *--production ]]; then
    export AWS_PROFILE=112319184931
    echo "You are in the production environment."
elif [[ $* == *--staging ]]; then 
    export AWS_PROFILE=533016277303
    echo "You are in the staging environment."
else
    echo "ERROR: please specify --production or --staging"
    return
fi

export CLUSTER_NAME=my_awesome_cluster
export AWS_DEFAULT_REGION=eu-west-1
export AWS_DEFAULT_OUTPUT="table"

aws sts get-caller-identity

aws rds describe-db-instances \
    --query \
	'DBInstances[*].{ID:DBInstanceIdentifier,
	Name:DBName,
	EngineName:Engine,
	Version:EngineVersion,
	Public:PubliclyAccessible,
	Type:DBInstanceClass,
	OptionGroup:OptionGroupMemberships[*].OptionGroupName|[0],
	VpcId:DBSubnetGroup.VpcId}'

aws eks list-clusters

first_cluster_id=$(aws eks list-clusters --output json --query clusters[0])
example_command="aws eks update-kubeconfig --name $first_cluster_id"
echo "to set up your kubeconfig please run:"
echo $example_command

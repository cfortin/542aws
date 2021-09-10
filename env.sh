#!/bin/bash
set -xeuo pipefail
alias aws='/usr/local/bin/aws'

export AWS_PROFILE=533016277303
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

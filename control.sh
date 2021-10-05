#!/bin/bash

DEFAULT_ENVFILE="$(dirname $0)/.env"
ENVFILE=${ENVFILE:-"$DEFAULT_ENVFILE"}

WORKING_DIR=${WORKING_DIR:-$(realpath ./)}
TEMPLATES_DIR=${TEMPLATES_DIR:-$(realpath ./templates/)}
COMPOSE_FILENAME=${COMPOSE_FILENAME:-"docker-compose-testnet.yaml"}
OUTPUT_DIR=${OUTPUT_DIR:-$(realpath ./configfiles)}
VAL_NAME_PREFIX=${VAL_NAME_PREFIX:-"validator-"}
TESTNET_NAME=${TESTNET_NAME:-"eth_private_testnet"}
COMPOSE_FILE=${WORKING_DIR}/docker-compose-testnet.yaml

IMAGE_TAG=${IMAGE_TAG:-"latest"}

VAL_NUM=${1:-3}

source scripts/helper_functions.sh

### Source scripts under scripts directory
. $(dirname $0)/scripts/helper_functions.sh
###


USAGE="$(basename $0) is the main control script for the testnet.
Usage : $(basename $0) <action> <arguments>

Actions:
  start     --val-num|-n <num of validators>
       Starts a network with <num_validators> 
  configure --val-num|-n <num of validators>
       configures a network with <num_validators> 
  stop
       Stops the running network
  clean
       Cleans up the configuration directories of the network
  status
       Prints the status of the network
        "

function help()
{
  echo "$USAGE"
}

function generate_network_configs()
{
  nvals=$1
  echo "Generating network configuration for $nvals validators..."
  dockercompose_testnet_generator ${VAL_NUM} ${OUTPUT_DIR}
  echo "  done!"
}

function start_network()
{
  nvals=$1
  echo "Starting network with $nvals validators..."

  #run testnet
  echo "Starting the testnet..."

  TESTNET_NAME=${TESTNET_NAME} CONFIGFILES=${OUTPUT_DIR} IMAGE_TAG=${IMAGE_TAG} docker-compose -f ${WORKING_DIR}/${COMPOSE_FILENAME} up -d

  echo "Waiting for everything goes up..."

  echo "Network is up and running"

}

function stop_network()
{
  echo "Stopping network..."
  
  CONFIGFILES=${OUTPUT_DIR} IMAGE_TAG=${IMAGE_TAG} docker-compose -f ${COMPOSE_FILE} down
  
  echo "  stopped!"
}

function print_status()
{
  echo "Printing status of the  network..."
  # TESTNET_NAME=$TESTNET_NAME docker-compose -f docker-compose-testnet.yml status
  CONFIGFILES=${OUTPUT_DIR} IMAGE_TAG=${IMAGE_TAG} TESTNET_NAME=$TESTNET_NAME docker-compose -f ${WORKING_DIR}/${COMPOSE_FILENAME} ps
  echo "  Finished!"
}

function do_cleanup()
{
  echo "Cleaning up network configuration..."
  # rm -rf ${DEPLOYMENT_DIR}/*
  set -x
  rm -rf ${OUTPUT_DIR}/*
  rm ${WORKING_DIR}/${COMPOSE_FILENAME}
  set +x
  echo "  clean up finished!"
}


ARGS="$@"

if [ $# -lt 1 ]
then
  #echo "No args"
  help
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    "start" ) shift
      while [ "$1" != "" ]; do
        case $1 in 
             -n|--val-num ) shift
               VAL_NUM=$1
               ;;
        esac
        shift
      done
      start_network $VAL_NUM
      exit
      ;;
    "configure" ) shift
      while [ "$1" != "" ]; do
        case $1 in 
             -n|--val-num ) shift
               VAL_NUM=$1
               ;;
        esac
        shift
      done
      generate_network_configs $VAL_NUM
      exit
      ;;
    "stop" ) shift
      stop_network
      exit
      ;;
    "status" ) shift
      print_status
      exit
      ;;
    "clean" ) shift
      do_cleanup
      exit
      ;;
  esac
  shift
done
#!/bin/bash

ROOT_DIR=$(cd "$(dirname $0)" && pwd)

PROTO_DIR=$ROOT_DIR/src/packages/protos
DB_DIR=$ROOT_DIR/conf/config.db
WS_DIR=$ROOT_DIR/apps/update/public/download/

cd $PROTO_DIR
./convert.sh
cd $ROOT_DIR

DB_PATH=/Users/funkii/projects/CB2_TD/Assets/StreamingAssets/
cp -rf $DB_DIR $DB_PATH
cp -rf $DB_DIR $WS_DIR

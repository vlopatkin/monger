#!/bin/bash

set -e pipefail

MQ_VERSION=3.2.31
MQ_IMAGE=iron/mq:$MQ_VERSION

LOGS_DIR=./logs
DATA_DIR=`pwd`/mq-data

go get .
go build .
docker pull $MQ_IMAGE
docker build -t monger-cleaner -f Dockerfile.cleaner .

if [ ! -d "$LOGS_DIR" ]; then
    mkdir $LOGS_DIR
fi

run_bench () {
    docker rm -f -v mq || echo "no mq"

    if [ -d "$DATA_DIR/ironmq/data" ]; then
        docker run --rm -v $DATA_DIR:/ironmq/data monger-cleaner
    fi
    docker run -d --name mq -p 8080:8080/tcp -v $DATA_DIR:/ironmq/data $MQ_IMAGE

    #give it a moment to spin up the mq container
    sleep 1;

    MONGER_ARGS="-messages $MSG_COUNT -body-size $MSG_SIZE -n $BATCH_SIZE -queues $QUEUE_COUNT -threads $THREAD_COUNT"
    OUTPUT_FILE_SUFFIX="m$MSG_COUNT-x$MSG_SIZE-by$BATCH_SIZE-in$QUEUE_COUNT-due$THREAD_COUNT"
    OUTPUT_FILE_PREFIX="mq-v$MQ_VERSION"
    echo $MONGER_ARGS
    { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS ;time ./monger -p 123 -t hi -host localhost -port 8080 -wat prod $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-prod.log
    { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS; time ./monger -p 123 -t hi -host localhost -port 8080 -wat cons $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-cons.log
    if [ $MSG_COUNT -lt 10001 ] ; then
        { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS; time ./monger -p 123 -t hi -host localhost -port 8080 -wat cons $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-empty-cons.log
    fi
}

CPU_NAME=`cat /proc/cpuinfo | grep 'model name' | head -n 1 | cut -f 2 -d ':'`
MAX_THREAD_COUNT=`cat /proc/cpuinfo | grep 'model name' | wc -l`

MSG_COUNTS="1000 100000"
MSG_SIZES="100 1000 10000"
BATCH_SIZES="1 10 100"
THREAD_COUNTS="1 $MAX_THREAD_COUNT"
QUEUE_COUNTS="1 10 100"



#10000 100000
for MSG_COUNT in $MSG_COUNTS
do
    for MSG_SIZE in $MSG_SIZES
    do
        for THREAD_COUNT in $THREAD_COUNTS
        do
            for QUEUE_COUNT in $QUEUE_COUNTS
            do
                for BATCH_SIZE in $BATCH_SIZES
                do
                    run_bench
                done
            done
        done
    done
done



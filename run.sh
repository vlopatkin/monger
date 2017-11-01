#!/bin/bash

set -e pipefail

MQ_VERSION=3.2.31
MQ_IMAGE=iron/mq:$MQ_VERSION

MSG_COUNT=10000
MSG_SIZE=1000
THREADS_COUNT=4
QUEUES_COUNT=100
BATCH_SIZE=1
LOGS_DIR=./logs


go build .
docker pull $MQ_IMAGE

if [ ! -d "$LOGS_DIR" ]; then
    mkdir $LOGS_DIR
fi

run_bench () {
    docker rm -f mq || echo "no mq"
    docker run -d --name mq -p 8080:8080/tcp $MQ_IMAGE

    #give it a moment to spin up the mq container
    sleep 1;

    MONGER_ARGS="-messages $MSG_COUNT -body-size $MSG_SIZE -n $BATCH_SIZE -queues $QUEUES_COUNT -threads $THREADS_COUNT"
    OUTPUT_FILE_SUFFIX="m$MSG_COUNT-x$MSG_SIZE-by$BATCH_SIZE-in$QUEUES_COUNT-due$THREADS_COUNT"
    OUTPUT_FILE_PREFIX="mq-v$MQ_VERSION"
    CPU_NAME=`cat /proc/cpuinfo | grep 'model name' | head -n 1 | cut -f 2 -d ':'`
    { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS ;time ./monger -p 123 -t hi -host localhost -port 8080 -wat prod $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-prod.log
    { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS; time ./monger -p 123 -t hi -host localhost -port 8080 -wat cons $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-cons.log
    { echo $CPU_NAME; echo $MQ_IMAGE; echo $MONGER_ARGS; time ./monger -p 123 -t hi -host localhost -port 8080 -wat cons $MONGER_ARGS ; } &>$LOGS_DIR/$OUTPUT_FILE_PREFIX-$OUTPUT_FILE_SUFFIX-empty-cons.log
}


for MSG_COUNT in 10000 100000 1000000
do
    for MSG_SIZE in 100 1000 10000
    do
        for THREADS_COUNT in 1 2 4 8 16 32
        do
            for QUEUES_COUNT in 1 4 32 10 100
            do
                for BATCH_SIZE in 1 5 10 25 50
                do
                    MONGER_ARGS="-messages $MSG_COUNT -body-size $MSG_SIZE -n $BATCH_SIZE -queues $QUEUES_COUNT -threads $THREADS_COUNT"
                    echo $MONGER_ARGS
                    run_bench
                done
            done
        done
    done
done



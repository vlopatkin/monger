### Monger

Try to murder IronMQ, can log or write stats out to InfluxDB v0.9x

![IronMonger](https://upload.wikimedia.org/wikipedia/en/4/44/IronMonger.jpg)

"IronMonger" by [1]. Licensed under Fair use via Wikipedia

### Getting started

```sh
$ go get -u github.com/vlopatkin/monger
$ cd $GOPATH/src/github.com/vlopatkin/monger && go build
$ ./monger --help
```

### Running on IronWorker

Install [IronCLI](https://github.com/iron-io/ironcli) and
[Docker](https://docs.docker.com) on your dev box first.

```sh
$ docker build -t $YOUR_DOCKERHUB_HANDLE/monger:v0 .
$ docker push $YOUR_DOCKERHUB_HANDLE/monger:v0
$ iron register $YOUR_DOCKERHUB_HANDLE/monger:v0 -host mq-host.iron.io -t $token -p $project_id
$ iron worker queue $YOUR_DOCKERHUB_HANDLE/monger
```
### Running local performance tests

Test results will be written into the `logs` folder.
Prerequisites are [Docker](https://docs.docker.com) and [Golang](https://golang.org/doc/install).
Be patient, it take quite a long time.
```
./run.sh
```
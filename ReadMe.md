# a title

Now it is time for me to begin to seriously learn a database. I know the theory of databases, but I lack of experience using a database. I used MS SQL before, but I know little about it. I switch to open-source (ah, the dark side :) ) now, so I choose mariadb as a starting point.  

I grabbed a [Learning MySQL and MariaDB](https://www.amazon.com/Learning-MySQL-MariaDB-Heading-Direction-dp-1449362907/dp/1449362907/ref=mt_paperback?_encoding=UTF8&me=&qid=), and decide to read from the first page to the last page. Try to familiarize myself with mariadb by completing all the exercises.

The first task is to install mariadb. As usual, I don't want to install mariadb locally, because I would like to keep my local environment as simple as possible. Therefore using Docker is one feasible solution.

First of all, pull the official image of mariadb.

```shell
docker pull mariadb
```

Then I can create a container running a mariadb server. Use the following command:

```shell
docker run --name=test-mariadb mariadb
```
Oops, I get error messages that tell me to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD environment variables.

I choose the set MYSQL_ROOT_PASSWORD with the following command.

```shell
docker run --name=test-mariadb --env="MYSQL_ROOT_PASSWORD=your-passworkd" mariadb
```

But this time docker complains that this container name is already in use. I remove the container that uses the same name.

```shell
docker container rm learning-mariadb
```
Then run the container again. Now, I have a running mariadb server.

But, where is mariadb-client? How can I connect to the mariadb server?

After some research, in the [official document](https://hub.docker.com/_/mariadb) (read the Connect to Mariadfrom the MySQL command line client)bof mariadb image I found that the official mariadb image can be used to connect to another mariadb server container. The command given is:

```shell
docker run -it --network some-network --rm mariadb mysql -hsome-mariadb -uexample-user -p
```

There are some syntax errors and is not clearly explained. But it is still a good starting point.

What I need is a mariadb client that can connect to a mariadb server running on a container. The problem now is how can I create a container running mariadb client to connect to an existing mariadb server container from another container?

From the command, I see there is a `network`. I haven't used network, so I try to figure out what `network` is in Docker. These two articles [Use bridge networks](https://docs.docker.com/network/bridge/) and [Networking with standalone containers](https://docs.docker.com/network/network-tutorial-standalone/) helps. The tutorial gives very good examples. Simply put, `network` can be used to connect containers. The first thing I have to do is to create a network. Using the following command to create a network.

```shell
docker network create learning-mariadb-network
```

This command create a `bridge` network (which is a default network when not specifying the `network` type).

Then start a mariadb server container and attach this container to the network called `learning-mariadb-network`.

```shell
docker run --name=learning-mariadb-server --env="MYSQL_ROOT_PASSWORD=your-password" --network learning-mariadb-network mariadb
```

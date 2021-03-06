# Small Traps for Setting a Local mariadb Development Environment by Docker

Now it is time for me to begin to seriously learn a database. I know the theory of databases, but I lack of experience using a database. I used MS SQL before, but I know little about it. I switch to open-source (ah, the dark side :) ) now, so I choose mariadb as a starting point.  

I grabbed a [Learning MySQL and mariadb](https://www.amazon.com/Learning-MySQL-mariadb-Heading-Direction-dp-1449362907/dp/1449362907/ref=mt_paperback?_encoding=UTF8&me=&qid=), and decide to read from the first page to the last page. Try to familiarize myself with mariadb by completing all the exercises.

The first task is to install mariadb. As usual, I don't want to install mariadb locally, because I would like to keep my local environment as simple as possible. Therefore using Docker is my option.

First of all, pull the official image of mariadb.

```shell
docker pull mariadb
```

Then I can create a container running a mariadb server. Use the following command:

```shell
docker run --name=learning-mariadb mariadb
```

Oops, I get error messages that tell me to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD environment variables.

I choose to set MYSQL_ROOT_PASSWORD with the following command.

```shell
docker run --name=learning-mariadb-server --env="MYSQL_ROOT_PASSWORD=your-password" mariadb
```

But this time docker complains that this container name is already in use. I remove the container that uses the same name.

```shell
docker container rm learning-mariadb-server
```

Then run the container again. Now, I have a running mariadb server.

But, where is mariadb-client? How can I connect to the mariadb server?

After some research, in the [official document](https://hub.docker.com/_/mariadb) (read the section, Connect to mariadb from the MySQL command line client) I found that the official mariadb image can be used to connect to another mariadb server container. The command given in the article is:

```shell
docker run -it --network some-network --rm mariadb mysql -hsome-mariadb -uexample-user -p
```

There are some syntax errors and it is not clearly explained. But it is still a good starting point.

What I need is a mariadb client that can connect to a mariadb server running on a container. The problem now is how can I create a container running mariadb client to connect to an existing mariadb server running in another container?

From the command, I see there is a `network`. I haven't used network before, so I try to figure out what `network` is in Docker. These two articles [Use bridge networks](https://docs.docker.com/network/bridge/) and [Networking with standalone containers](https://docs.docker.com/network/network-tutorial-standalone/) helps. The tutorial gives very good examples. Simply put, `network` can be used to connect containers. The first thing I have to do is to create a network. Using the following command to create a network.

```shell
docker network create learning-mariadb-network
```

This command create a `bridge` network (which is a default network when not specifying the `network` type).

Start a mariadb server container and attach this container to the network called `learning-mariadb-network`.

```shell
docker run --name=learning-mariadb-server\
--detach \
--env="MYSQL_ROOT_PASSWORD=your-password" \
--network learning-mariadb-network \
mariadb
```

It is better to run the container in background. `--detach` is thus used.

Now, I can create another container which runs only mariadb client to connect to the mariadb server.

```shell
docker run -it --rm \
--name=learning-mariadb-client \
--network learning-mariadb-network \
mariadb \
mysql -u root -h learning-mariadb-server -p
```

The option `--network` attach this container, whose name is learning-mariadb-client, to a network call `learning-mariadb-network`.

The last part (it is the command to be executed after the container is created) of the command:

```shell
mysql -u root -h learning-mariadb-server -p
```

tells the container to run the command `mysql` with the options

```shell
-u root -h learning-mariadb-server -p
```

The key point of these options is:

```shell
-h learning-mariadb-server
```

This option tells `mysql` (the mariadb-client) to connect to a host named `learning-mariadb-server`. This host name, in fact, is identical to the name of the container
(given by using `--name` ) running a mariadb server. Docker network helps in resolving host names.

Now I have a mariadb-server and a mariadb-client. However, the story does not end here.

The first thing I tried to do is to add a user to the mariadb-server. Add a  user by this command:

```shell
GRANT ALL ON *.* TO 'username'@'%' IDENTIFIED BY 'your-password';
```

After creating a user `username`, list the users by the following command:

```shell
SELECT User, Host FROM mysql.user
```
You can see the following table.

User | Host
-----|----
username | %
 root|% |
 root | localhost |

Then remove the mariadb-server and mariadb-client containers. Run the above process again to create a mariadb-server, and to connect to the mariadb-server using a mariadb-client. List the users again. Oops, I found that there is no user named `username`. The mariadb-server remains in the initial state!!!

The problem is obvious that I did not store the data persistently. When a mariadb-server container is created, an anonymous data volume is also created. When this mariadb-server container is removed, the anonymous data volume still exists in the system. All the changes I made to the mariadb-server are written to the anonymous volume. But when I create another new mariadb-server container without mounting the anonymous data volume, all changes I made with the previous mariadb-server seems to lost forever (in fact, it is not).

It is easy to solve this problem (after I did some research :p for about an hour). First, for convenience, add a named volume by this command:

```shell
docker volume create `your-volume-name`
```

Mount the named volume when creating a **new** mariadb-server container by using the option `-v`. Then the data volume will be initialized, and you can store data persistently. The command is:

```shell
docker run --name=learning-mariadb-server\
--detach \
--env="MYSQL_ROOT_PASSWORD=your-password" \
-v learning-mariadb-dbdata:/var/lib/mysql \
--network learning-mariadb-network \
mariadb
```

It is clear until now. To run a mariadb for development, three items are needed. A mariadb-server, of course, a mariadb-client for connecting to the mariadb-server, and data volume for storing data persistently.

## One more thing. Another caveat

When you already have a data volume with existing data, you do not have to use `MYSQL_ROOT_PASSWORD` to run a mariadb-server. In the official document, it is said that this option will be ignored in any case and the pre-existing database will not be changed in any way.

Thus to run a mariadb-server container against an existing database, using the following command:

```shell
docker run --detach \
--name=your-container-name \
-v learning-mariadb-dbdata:/var/lib/mysql \
--network learning-mariadb-network \
mariadb
```

One other trivial caveat

When a whole new mariadb-server container is initialized without an existing database, a default database will be created. No connection can be made during the initialization period. If you want to connect to the mariadb-server, please wait till the end of the initialization.

## Summary and tools you need

If you want to use Docker to run a mariadb for local development, here is what you needed:

1. create a network (use this directly in command line)

```shell
docker network create learning-mariadb-network
```

2. create a named volume (use this directly in command line)

```shell
docker volume create learning-mariadb-dbdata
```

3. run a mariadb-server container for the first time (use this directly in command line)

```shell
docker run --name=learning-mariadb-server\
--detach \
--env="MYSQL_ROOT_PASSWORD=your-password" \
--network learning-mariadb-network \
mariadb
```

4. now you can use another container running mariadb-client to connect to the mariadb-server (use this directly in command line)

```shell
docker run -it --rm \
--name=learning-mariadb-client \
--network learning-mariadb-network \
mariadb \
mysql -u root -h learning-mariadb-server -p
```

 when your data volume completes initialization, you can omit some environment options to run a mariadb-sever container against existing database(s)

```shell
docker run --detach \
--name=your-container-name \
-v learning-mariadb-dbdata:/var/lib/mysql \
--network learning-mariadb-network \
mariadb
```

OK, now happy using mariadb :) 
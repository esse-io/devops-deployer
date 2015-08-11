# EL BigData Platform Environment Deployer

## Prerequisite

* Hardware and OS

* Install and configure the salt-master on fistbox
  - Install salt master:
```
$ yum install -y epel-release
$ yum install -y salt-master
```

  - Add /etc/salt/master.d/devops.conf on firstox:
```
file_roots:
  devops:
    - /devops/deployer/salt/roots
pillar_roots:
  devops:
    - /devops/deployer/salt/pillar
fileserver_backend:
  - roots
  - minion
file_recv: True
state_output: terse
autosign_file: /etc/salt/autosign.conf
```

  - Run `salt-master -d`

* Install and configure the salt-minion on clients
  - Install salt minion
```
$ yum install -y epel-release
$ yum install -y salt-minion
```

  - Update the *master* attribute in /etc/salt/minion to point to the firstbox
  - Run `salt-minion -d -l debug`


* Install docker on firstbox

We need install docker service on firstbox to setup the docker local registry.
Before this installation you need uninstall existing docker rpm which will conflicate with this version. *And also please make sure you uninstall the docker rpm on all other nodes* 
```
$ wget https://get.docker.com/rpm/1.7.1/centos-6/RPMS/x86_64/docker-engine-1.7.1-1.el6.x86_64.rpm
$ yum localinstall docker-engine-1.7.1-1.el6.x86_64.rpm
```

* Setup docker registry on firstbox:
```
$ docker run -d -p 5000:5000 \
--restart=always --name docker_repo \
-e SETTINGS_FLAVOR=local \
-e SEARCH_BACKEND=sqlalchemy \
-e SQLALCHEMY_INDEX_DATABASE=sqlite:////var/lib/registry/docker-registry.db \
-e STORAGE_PATH=/var/lib/registry \
-v /data/docker_repo:/var/lib/registry registry
```

* Pull the follwing docker images into the local docker registry:
```Note: The docker-registry.$host.com should be reachable or add it into the /etc/hosts. ```

Docker Hub Image    |  Tage    | Local Registry Image                              | Tag
--------------------|----------|---------------------------------------------------|-------
osixia/phpldapadmin | latest   | docker-registry.$host.com:5000/phpldapadmin     | latest
nickstenning/slapd | latest | docker-registry.$host.com:5000/sladp | latest
sameersbn/postgresql | 9.4-2 | docker-registry.$host.com:5000/postgresql | 9.4-2
sameersbn/redis | latest | docker-registry.$host.com:5000/redis | latest
sameersbn/gitlab | 7.13.0 | docker-registry.$host.com:5000/gitlab | 7.13.0
jenkins | latest | docker-registry.$host.com:5000/jenkins | latest

  - Build gerrit image:
```
$ git clone https://github.com/idevops-net/ci.git
$ cd ci/docker/docker-gerrit
$ wget https://gerrit-releases.storage.googleapis.com/gerrit-2.11.2.war
$ docker build -t docker-registry.$host.com:5000/gerrit:0.0.1 --force-rm=true ./
$ docker push docker-registry.$host.com:5000/gerrit:0.0.1
```

Local Registry Image                              | Tag
--------------------------------------------------|-------
docker-registry.$host.com:5000/gerrit           | 0.0.1

  - Build jenkins image:
```
$ cd ci/docker/docker-jenkins
$ wget http://apache.arvixe.com/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip
$ docker build -t docker-registry.$host.com:5000/jenkins:0.0.1 --force-rm=true ./
$ docker push docker-registry.$host.com:5000/jenkins:0.0.1
```

Local Registry Image                              | Tag
--------------------------------------------------|-------
docker-registry.$host.com:5000/jenkins           | 0.0.1

  - Build zookeeper image:
```
$ cd ci/docker/docker-zookeeper
$ docker build -t docker-registry.$host.com:5000/zookeeper:0.0.1 --force-rm=true ./
$ docker push docker-registry.$host.com:5000/zookeeper:0.0.1
```
Local Registry Image                              | Tag
--------------------------------------------------|-------
docker-registry.$host.com:5000/zookeeper | 0.0.1

  - Build kafka image:
```
$ cd ci/docker/docker-kafka
$ docker build -t docker-registry.$host.com:5000/kafak:0.0.1 --force-rm=true ./
$ docker push docker-registry.$host.com:5000/kafka:0.0.1
```
Local Registry Image                              | Tag
--------------------------------------------------|-------
docker-registry.$host.com:5000/kafka | 0.0.1

## Configuration

Update the pillar base on current environment, for example:

* domain in ```pillar/devops.sls```

* networks cidr in ```pillar/devops.sls```

* ip_interface in ```pillar/devops.sls```

* ldap_admin_pass in ```pillar/ldap.sls```

Update the roles list ```pillar/nodes.sls``` base on your deployment plan, for example if you want to run all the ldap related on bd003.$host.com, you can write the following:

```
  role-map:
    'docker':
      - 'docker-registry'
    'ldap':
      - 'ldap-server'
      - 'php-ldap-admin'
  nodes:
    bd003.$host.com:
      roles:
        - ldap
```

And you can run the command to setup your ldap environment:

```
salt 'bd003.$host.com' -G 'roles:ldap'
```

## Deployment

* Restart docker service before any deployment especially after you mount new local disk to save data
 
```   
$ salt '*' service.restart docker
```

* First we need run following salt scripts to update salt configuration base the roles definition, initialize the docker environment and firstbox.

```
$ salt '*' saltutil.refresh_pillar
$ salt '*' saltutil.sync_modules
$ salt '*' state.sls salt devops
Note: after run the above command you need hold on 1 minute at least until salt minion restart finish on all the nodes.

$ salt -G 'roles:firstbox' state.sls firstbox devops
$ salt '*' state.sls salt,docker,ssl-key devops
```

* Deploy java
```
$ salt '*' state.sls java devops
```

* Deploy ldap
```
$ salt -G 'roles:ldap' state.sls ldap,php-ldap-admin devops
```

* After deploy ldap successfully, you should follow the (**Create organization memeber**) steps under **Post configuration** to create ldap account before the next deployment.

* Deploy git
```
$ salt -G 'roles:git' state.sls postgresql,redis,gitlab,gerrit devops
```

* After deploy gerrit successfult, you should follow the (**Create gerrit admin account**) steps under **Post configuration** to enable 'idevops-ci' as the gerrit administrator before continus.

* Deploy jenkins
```
$ salt -G 'roles:jenkins' state.sls jenkins devops
```

* Deploy Hadoop
```
$ salt -G 'roles:hadoop-namenode' state.sls cdh.hdfs devops
$ salt -G 'roles:hadoop-datanode' state.sls cdh.hdfs devops
```

* Deploy Spark and configure Hive
```
$ salt -G 'roles:spark-master' state.sls cdh.spark,cdh.hive devops
$ salt -G 'roles:spark-worker' state.sls cdh.spark devops
```

* Deploy Zookeeper
```
$ salt -G 'roles:zookeeper' state.sls zookeeper devops
```

* Deploy Kafka
```
$ salt -G 'roles:kafka' state.sls kafka devops
```

## Post configuration

* Change the Gitlab default password of root user

Point your browser to [Gitlab](https://bd003.$host.com:10443/) and login using the default username and password:

    username: root
    password: 5iveL!fe

The Gitlab will require you to change the default password.

* Create organization memeber:
  - Create ldap.ldif, you can reference the [ldap.ldif.example](src/scripts/ldap.ldif.example) as an example, and run command to initialize the organization memebers on *bd003*
```
$ ldapadd -h localhost -x -D "cn=admin,dc=$host,dc=com" -f ldap.ldif -W
```
  - You can login the [Ldap web admin page](https://bd003.$host.com:11443) to change your password, the login DN should be like: *cn=david,ou=people,dc=$host,dc=com*, the login DN of admin should be like: *cn=admin,dc=$host,dc=com*.

* Create gerrit admin account:
  - After the gerrit container deploy, you need login the [Gerrit web admin page](http://bd002.$host.com:28080) with the 'idevops-ci' user account and password in ldap, it will be added into the gerrit administrator group since it's the first login user.
  - Add 'idevops-ci' ssh public key into gerrit, you can find it under the ```bd003.$host.com:/data/ssh_keys```

* Enable ldap based authentication in jenkins Configure Global Security
  - Follow this guid to enable it: [LDAP plugin](https://wiki.jenkins-ci.org/display/JENKINS/LDAP+Plugin)
  - And only allow authorized user to access jenkins.

* Create Hive warehouse in HDFS

Run following commands on your firstbox to create tmp and warehouse in HDFS for Hive.
```
$ hadoop fs -mkdir       /tmp
$ hadoop fs -mkdir       /user/hive/warehouse
$ hadoop fs -chmod g+w   /tmp
$ hadoop fs -chmod g+w   /user/hive/warehouse
```

* Start Spark SQL Thrift Server

Run following command on your firstbox to start the thrift server, the total of executor cores *--total-executor-cores* is according to your spark cluster environment, you need provide a vaild number to avoid the spark jobs can not acquire enough resources from culster to run.
```
$ /usr/lib/spark/sbin/start-thriftserver.sh \
spark://<your spark master ip>:7077 \
--hiveconf "hive.metastore.warehouse.dir=hdfs://<your hdfs namenode>:9000/user/hive/warehouse" \
--total-executor-cores 20
```

## Useful Link after deployment:

* <a href="https://bd003.$host.com:11443/" target="_blank">Ldap web admin</a>
* <a href="https://bd003.$host.com:10443/" target="_blank">Gitlab web UI</a>
* <a href="http://bd003.$host.com:28080/" target="_blank">Gerrit web UI</a>
* <a href="http://bd002.$host.com:18080/jenkins" target="_blank">Jenkins web UI</a>

## Troubleshooting

* Salt related error

  - You can check the log file ```/var/log/salt/master``` on salt master or ```/var/log/salt/minion``` on salt client.
  - Run ```salt-run manage.status``` to check the salt client status.
  - Run ```salt -G 'roles:ldap' test.ping``` to check minion's status.
  - Run ```salt-key -d bd003.$host.com``` to delete unnecessary minion





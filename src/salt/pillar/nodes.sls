devops:
  role-map:
    'docker':
      - 'docker-registry'
    'ldap':
      - 'ldap-server'
      - 'php-ldap-admin'
    'git':
      - 'postgresql'
      - 'gitlab'
      - 'redis'
      - 'gerrit'
    'hadoop-namenode':
      - 'cdh.hadoop'
    'hadoop-datanode':
      - 'cdh.hadoop'
    'spark-master':
      - 'cdh.spark'
    'spark-worker':
      - 'cdh.spark'
    'oozie-client':
      - 'oozie'
    'oozie-server':
      - 'oozie'
  nodes:
    bd001.$host.com:
      roles:
        - docker
        - firstbox
        - hadoop-namenode
        - hadoop-datanode
        - spark-master
        - spark-worker
        - kafka
        - logstash-server
        - oozie-client
    bd002.$host.com:
      roles:
        - ldap
        - git
        - hadoop-datanode
        - spark-worker
        - sqoop
    bd003.$host.com:
      roles:
        - jenkins
        - hadoop-datanode
        - spark-worker
        - zookeeper
        - kafka
    bd005.$host.com:
      roles:
        - hadoop-datanode
        - spark-worker
        - kafka
    bd006.$host.com:
      roles:
        - hadoop-datanode
        - spark-worker
        - oozie-server

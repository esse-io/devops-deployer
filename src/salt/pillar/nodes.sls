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
      - 'cdh.hdfs'
    'hadoop-datanode':
      - 'cdh.hdfs'
    'spark-master':
      - 'cdh.spark'
    'spark-worker':
      - 'cdh.spark'
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
    bd002.$host.com:
      roles:
        - ldap
        - git
        - jenkins
        - hadoop-datanode
        - spark-worker
    bd003.$host.com:
      roles:
        - hadoop-datanode
        - spark-worker
        - zookeeper
        - kafka
    bd005.$host.com:
      roles:
        - hadoop-datanode
        - spark-worker
    bd006.$host.com:
      roles:
        - hadoop-datanode
        - spark-worker
        - kafka

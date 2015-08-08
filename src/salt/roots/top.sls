devops:
  'roles:firstbox':
    - match: grain
    - firstbox

  'roles:ldap':
    - match: grain
    - ldap
    - php-ldap-admin

  'roles:ldap-server':
    - match: grain
    - ldap

  'roles:git':
    - match: grain
    - redis
    - postgresql
    - gitlab
    - gerrit

  'roles:postgresql':
    - match: grain
    - postgresql

  'roles:gerrit':
    - match: grain
    - gerrit

  'roles:jenkins':
    - match: grain
    - jenkins

  'roles:hadoop-namenode':
    - match: grain
    - cdh.hdfs

  'roles:hadoop-datanode':
    - match: grain
    - cdh.hdfs

  'roles:spark-master':
    - match: grain
    - cdh.spark

  'roles:spark-worker':
    - match: grain
    - cdh.spark

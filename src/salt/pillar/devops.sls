base:
  salt:
    file_roots: /devops/deployer/salt/roots
    formulas_roots: /devops/deployer/salt/formulas
    pillar_roots: /devops/deployer/salt/pillar
  domain_name: $host.com
  networks:
    cidr: 192.168.2.0/24
  firstbox_interface: eth0
  ci_user: idevops-ci
  gerrit_weburl: ''
  jenkins_weburl: ''


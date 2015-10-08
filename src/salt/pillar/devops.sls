base:
  salt:
    file_roots: /devops/deployer/salt/roots
    formulas_roots: /devops/deployer/salt/formulas
    pillar_roots: /devops/deployer/salt/pillar
  domain_name: $host.com
  networks:
    cidr: 192.168.2.0/24
    ip_interface: eth0
  ci_user: idevops-ci
  gerrit_weburl: 'https://123.124.21.140:20443/gerrit/'
  gerrit_httpd_listenurl: 'proxy-https://*:8080/gerrit/'
  jenkins_weburl: 'https://123.124.21.140:20443/jenkins'

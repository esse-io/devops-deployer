ldap:
  port: 389
  data_volume: '/data/slapd/ldap'
  config_volume: '/data/slapd/config'
  ldap_admin_pass: 'p0o9i*UJ'
  image_version: latest
  base: ou=people,dc=$host,dc=com
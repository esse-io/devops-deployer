openssl genrsa -out {{ ssl_keys }}/{{ key_file }} 2048

openssl req -new -key {{ ssl_keys }}/{{ key_file }} -out {{ ssl_keys }}/esse-io.csr -subj '/CN=www.$host.com/O=$host LTD./C=CN'

openssl x509 -req -days 3650 -in {{ ssl_keys }}/esse-io.csr -signkey {{ ssl_keys }}/{{ key_file }} -out {{ ssl_keys }}/{{ crt_file }}

openssl dhparam -out {{ ssl_keys }}/dhparam.pem 2048

chmod 400 {{ ssl_keys }}/{{ key_file }}

exit $?

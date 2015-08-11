set -x
VOLUME={{ vol_conf }}
/bin/cp -f /tmp/zoo.cfg.tmp $VOLUME/zoo.cfg.tmp
for (( i=1; i<={{ node_count }}; i++ ))
do
  # get container ip
  container_ip=$(./docker-ip zookeeper_${i})
  echo "server.$i=$container_ip:2888:3888" >> $VOLUME/zoo.cfg.tmp
done
mv $VOLUME/zoo.cfg.tmp $VOLUME/zoo.cfg
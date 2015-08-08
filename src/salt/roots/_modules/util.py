from netaddr import IPNetwork, IPAddress
import logging
log = logging.getLogger(__name__)

def addressInNetwork(ip, cidr):
    '''
        check whether ip address is in network
    '''
    if IPAddress(ip) in IPNetwork(cidr):
        return True
    else:
        return False

def getNodeNetworks(id=None):
    '''
        return the network info that are working on the net_type network
        return value:
            {
                'iface':eth0,
                'ipaddr':172.16.11.21,
                'network': 172.16.22.0
                'netmask': '255.255.255.0'
            }
        if no match found, return {}
    '''
    if not id:
      id = __grains__['id']
    nics = __salt__['mine.get'](id, "grains.item")[id]["ip_interfaces"]
    netcidr = __salt__['pillar.get']('base:networks:cidr')

    for iface, ips in nics.items():
        if len(ips) != 0:
            ipaddr = ips[0]
            if addressInNetwork(ipaddr, netcidr):
                ret = {
                    'iface': iface,
                    'ipaddr': ipaddr,
                    'network': str(IPNetwork(netcidr).network),
                    'netmask': str(IPNetwork(netcidr).netmask)
                }
                return ret
    return {}

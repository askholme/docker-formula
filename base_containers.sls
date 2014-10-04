{% set basecontainers = pillar.get('base_containers', {}) %}
{% set priv_ip = salt['grains.get']('private_ip') %}
{% set consul_cmd = [] %}
{% if basecontainers.get('consul_server',True) %}
  {% do consul_cmd.append("-server") %}
{% endif %} 
{% do consul_cmd.append("-advertise %s " % priv_ip) %}
{% do consul_cmd.append("-bootstrap") %}
{% set regs = salt['pillar.get']('docker-registries') %}

busybox:
  docker.pulled

consul_data_container:
  dockerplus.running:
    - name: consul-data
      image: busybox
      command: /bin/sh
      volumes:
        - /data
      check_running: False
      start: False

image_consul:
  docker.pulled:
    - name : progrium/consul:latest
    
consul_container:
  dockerplus.running:
    - name: consul
      image: progrium/consul:latest
      volumes_from: consul-data
      command: {{consul_cmd|join(' ')}}
      ports:
        "8300/tcp":
          HostIp: {{priv_ip}}
          HostPort: 8300/tcp
        8301:
          HostIp: {{priv_ip}}
          HostPort: 8301
        8302:
          HostIp: {{priv_ip}}
          HostPort: 8302
        8400:
          HostIp: {{priv_ip}}
          HostPort: 8400
        8500:
          HostIp: {{priv_ip}}
          HostPort: 8500
        "53/udp":
          HostIp: {{priv_ip}}
          HostPort: 8600/udp

image_registrator:
  docker.pulled:
    - name: progrium/registrator:latest
    
registrator_container:
  dockerplus.running:
    - name: registrator
      image: progrium/registrator:latest
      command: consul://consul:8500
      volumes:
        /var/run/docker.sock:
          bind: /tmp/docker.sock
          isfile: True
      links: 
        consul: consul
      requires:
        - dockerplus: consul_container
image_proxy:
  docker.pulled:
    - name: askholme/configurator:newest
    
proxy_container:
  dockerplus.running:
    - name: proxy
      image: askholme/configurator:newest
      command: /sbin/my_init
      links: 
        consul: consul
      requires:
        - dockerplus: consul_container
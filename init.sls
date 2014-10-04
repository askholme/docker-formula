python-apt:
  pkg.installed:
    - name: python-apt
    
python-pip:
  pkg.installed

git:
  pkg.installed

docker-python-dockerpy:
  pip.installed:
    - name: git+http://github.com/dotcloud/docker-py.git
    - require:
      - pkg: python-apt
      
docker-dependencies:
   pkg.installed:
    - pkgs:
      - iptables
      - ca-certificates
      - lxc

docker_repo:
    pkgrepo.managed:
      - repo: 'deb http://get.docker.io/ubuntu docker main'
      - file: '/etc/apt/sources.list.d/docker.list'
      - key_url: salt://docker/docker.pgp
      - require_in:
          - pkg: lxc-docker
      - require:
        - pkg: python-apt

lxc-docker:
  pkg.latest:
    - require:
      - pkg: docker-dependencies
nsenter:
  file.managed:
    - name: /usr/bin/nsenter
      source: salt://docker/nsenter
      mode: 755
      makedirs: true
      
docker:
  service.running

saltutil.refresh_modules:
  module.run
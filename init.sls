docker-python-apt:
  pkg.installed:
    - name: python-apt

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
        - pkg: docker-python-apt

lxc-docker:
  pkg.latest:
    - require:
      - pkg: docker-dependencies

docker:
  service.running

#install docker-squash
squash:
  archive:
    - extracted
    - name: /opt/squash
    - source: https://github.com/jwilder/docker-squash/releases/download/v0.0.8/docker-squash-linux-amd64-v0.0.8.tar.gz
    - archive_format: tar

# Link to /usr/local/bin/packer
/usr/local/bin/docker-squash:
  file.symlink:
    - target: /opt/squash/docker-squash
    - require:
      - archive: squash

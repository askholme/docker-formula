{% macro run_container(c) -%}
ensure_image_{{c.get('image')}}:
  docker.pulled:
    - name: {{c.get('image')}}
      force: True

# test to know if this is running for the first time. we can't use absent for that
test_if_exists_{{c.get('name')}}:
  docker.present:
    - name: {{c.get('name')}}
# remove containers runnign with the old image. the shell script is slightly confusing
# the last part [within $()] findes the image id for newest image
# the first part finds the image id for the container. The middle grep is then used to test
# if those to matches (nothing that the image only shows the first part of the image hash so it's a part match)
#remove_running_{{c.get('name')}}:
#  docker.absent:
#    - name: {{c.get('name')}}
#    - unless: docker inspect --format "{{ .Image }}" {{c.get('name')}} | grep $(docker images | grep {{'"'}}{{c.get('image')}}{{'"'}}  | awk '{ print $3 }')

ensure_container_{{c.get('name')}}:
  docker.installed:
    - name: {{c.get('name')}}
      {% if c.get('use_host_hostname',False) %$}
      hostname: {{grains['hostname']}}
      {% else %}
      hostname: {{c.get('name')}}
      image: {{c.get('name')}}
      command: {{c.get('command',None)}}
      environment:{% for key,value in c.get('environment').iteritems() %}
        - {{key}} : {{value}}{% endfor %}
      {% if 'ports' in c %}
      ports:{%for port in c.get('ports').keys() %}
        - {{port}}
      {% endfor %}{%endif%}
      {% if 'volumes' in c %}
      volumes: {%for vol in c.volumes %}
        - {{vol}}
      require: 
        - docker: ensure_image_{{c.get('image')}}
        - docker: remove_running_{{c.get('image')}}
      require_in: ensure_running_{{c.get('name')}}

ensure_running:
  docker.running:
    - container: {{c.get('name')}}
    {% if 'volumes_from' in c%}
    - volumes_from: {% for cont in c.get('volumes_from')}
      - {{cont}}
    {% endif %}
    {% if 'ports' in c %}
    - port_bindings:{%for key,value in c.get('ports').iteritems() %}
      - {{key}}{%if value is not None %}:
        "HostIp": {{value.get('hostip','0.0.0.0')}}
        "HostPort": {{value.get('hostport','0.0.0.0')}}{% endfor %}
    network_mode: {{c.get('network_mode','bridge')}}
    publish_all_ports: {{get.get('publish_all_ports',True)}}
    check_is_running: {{c.get('check_running',True)}}
    {% if 'links' in c %}
    - links:{%for link in c.get('links')%}
        {{link}}: {{link}}
    {% endfor %}
{% if 'first_run_cmd' in c %}
execute_first_run_{{c.get('name')}}:
  docker.run:
    - name: {{c.get('first_run_cmd')}}
    - cid: {{c.get('name')}}
    - onfail:
      - docker: test_if_exists_{{c.get('name')}}
{% endif %}
{%- endmacro %}
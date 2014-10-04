
{% set containers = pillar.get('containers', {}) %}
{% for c in containers %}
ensure_image_{{c.get('image')}}:
  docker.pulled:
    - name: {{c.get('image')}}

ensure_container_{{c.get('name')}}:
  dockerplus.running:
    - name: {{c.get('name')}}
      {% if c.get('use_host_hostname',False) -%}
      hostname: {{grains['hostname']}}
      {%- else -%}
      hostname: {{c.get('name')}}
      {%- endif %}
      image: {{c.get('name')}}
      command: {{c.get('command',None)}}
      {%- if 'environment' in c -%}
      environment:{% for key,value in c.get('environment').iteritems() %}
        - {{key}} : {{value}}{% endfor %}
      {%- endif -%}
      {%- if 'ports' in c or 'bindports' in c -%}
      ports:
        {%- if 'bindports' in c -%}{%- for key,value in c.get('bindports').iteritems() -%}
        - {{key}}{%if value is defined %}:
          "HostIp": {{value.get('hostip','0.0.0.0')}}
          "HostPort": {{value.get('hostport','0.0.0.0')}}{% endif %}{% endfor %}
      {%- endif -%}{%- if 'ports' in c -%}{%- for p in c.get('ports') -%} # end bindports loop start ports loop
        - {{p}}
      {%- endfor -%}{%- endif -%} ## end ports loop
      {%- endif -%} #end total ports if
      {% if 'volumes' in c -%}
      volumes: {%for vol in c.volumes %}
        - {{vol}}
      {%- endfor -%}
      {%- endif %}
      publish_all_ports: {{c.get('publish_all_ports',True)}}
      network_mode: {{c.get('network_mode','bridge')}}
      check_is_running: {{c.get('check_running',True)}}
      {% if 'links' in c -%}
      links:{%for link in c.get('links')%}
          {{link}} : {{link}}
      {%- endfor -%}
      {%- endif -%}
      {% if 'volumes_from' in c %}
      volumes_from: {% for cont in c.get('volumes_from') %}
        - {{cont}}
      {%- endfor -%}
      {%- endif -%}
    
{% if 'first_run_cmd' in c %}
execute_first_run_{{c.get('name')}}:
  docker.run:
    - name: {{c.get('first_run_cmd')}}
    - cid: {{c.get('name')}}
    - onfail:
      - docker: test_if_exists_{{c.get('name')}}
    - require:
      - dockerplus: ensure_container_{{c.get('name')}}
{% endif %}
{% endfor %}

#there might be an indentation isuee in the port bindings

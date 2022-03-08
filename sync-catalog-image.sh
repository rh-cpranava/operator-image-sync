---
- name: Operator Image Promotion 
  hosts: localhost 
  become: yes
  become_user: root
  become_method: su
  vars_files:
     - vars.yml
  gather_facts: false
  tasks:
    - name: Fetch the catalog of the docker registry
      uri:
         url: 'https://{{ src_registry_name }}/v2/_catalog'
         url_username: "{{ src_registry_username }}"
         url_password: "{{ src_registry_password }}"
         validate_certs: no    
         dest: /tmp/catalog-output
      register: catalog
    - name: Select values
      shell: 'cat /tmp/catalog-output | jq -r ".repositories[]" | egrep -i {{ src_namespace | join("|") | quote }}'
      register: repositories
    - name: Print list of images
      debug: 
         var: repositories 
    - name: Construct a list of all available images 
      set_fact:
         images: > 
            {{ images | default([]) + new_images }}
      vars: 
         image_tags: >
            {{ (lookup("url", "https://"+src_registry_name+"/v2/"+item+"/tags/list", username=src_registry_username, password=src_registry_password, validate_certs=False)|from_json).tags }}
         new_images: > 
            {{ [item] | product(image_tags) | map('join',':') | list }}
      loop: '{{ repositories.stdout_lines }}'
    - name: Print list of images
      debug: 
         var: images
    - name: Sync the images using skopeo
      command: "skopeo copy --all --dest-tls-verify=False --src-creds={{ src_registry_username }}:{{ src_registry_password }} --dest-creds={{ dest_registry_username }}:{{ dest_registry_password }} --src-tls-verify=False docker://{{ src_registry_name }}/{{item}} docker://{{ dest_registry_name }}/{{ dest_namespace }}/{{ item.split('/') | last  }}"
      loop: '{{ images }}' 

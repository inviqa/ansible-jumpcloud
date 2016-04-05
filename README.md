# JumpCloud Role for Ansible
------------
This role installs the [JumpCloud][jumpcloud] agent and restarts the JumpCloud agent service as required.
It also make use of JumpCloud API to set JumpCloud System attributes.

## Requirements
------------
[cURL][curl] and NTP should be installed as prerequisites.

## Role Variables
------------
#### [`jumpcloud_api_key`][jc-api-key]
Default: none
Used to modify the attribute of a System on JC portal.

The API key as shown in the JumpCloud's API Settings.
To be retrieved from JumpCloud portal by a JC Admin account

To be stored in an Ansible Vault. It's very high-sensitivity Information.

#### [`jumpcloud_x_connect_key`][jc-x-connect-key]
Default: none

The X_Connect key as displayed on the `Servers > Add` screen. **Mandatory**.

#### [`jumpcloud_directory`][jc-directory]
Default: `/opt/jc`

Path to check if JumpCloud has been previously installed.

#### [`jumpcloud_x_connect_url`][jc-x-connect-url]
Default: 'https://kickstart.jumpcloud.com/Kickstart'

URL for the install script.

#### [`jumpcloud_force_install`][jc-force-install]
Default: `no`

Used to determine whether or not to force installation of the client if it has been previously installed.

#### [`jumpcloud_agent_service`][jc-agent-service]
Default: `jcagent`

Name of the service to restart.

#### [`jumpcloud_use_sudo`][jc-use-sudo]
Default: `no`

Whether or not to use sudo during installation.

#### [`jumpcloud_tags`][tags]
The list of JC tags you want a host or a group of hosts to be part of
  - 'tag_one'
  - 'tag_two'

#### [`jumpcloud_displayName`][displayName]
Default: `{{ inventory_hostname }}``

#### [`jumpcloud_allowPublicKeyAuthentication`][allowPublicKeyAuthentication]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowSshPasswordAuthentication`][allowSshPasswordAuthentication]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowSshRootLogin`][allowSshRootLogin]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowMultiFactorAuthentication`][allowMultiFactorAuthentication]
Default: `'false'`
This value must be contained in single quotes "\'"

## Example Playbook
----------------

```YAML
---
- hosts: production
  roles:
     - { role: inviqa.jumpcloud, jumpcloud_x_connect_key: 'abcdef012234343' }
  vars:
    jumpcloud_tags:
      - 'tag_one'
      - 'tag_two'
    jumpcloud_displayName: "a new displayName"
    jumpcloud_allowPublicKeyAuthentication: 'true'
    jumpcloud_allowSshPasswordAuthentication: 'false'
    jumpcloud_allowSshRootLogin: 'true'
    jumpcloud_allowMultiFactorAuthentication: 'false'
...
```

## License
-------

[MIT][licence]

## Author Information
------------------
Author Marco Massari Calderone at Inviq UK Ltd
Inspired by @[barney_hanlon][twitter] (https://github.com/shrikeh/ansible-jumpcloud)

[github]: https://github.com/inviqa/ansible-jumpcloud "Github location of this role"
[curl]: https://galaxy.ansible.com/list#/roles/4384
[jumpcloud]: https://jumpcloud.com "JumpCloud website"
[jc-x-connect-key]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L4 "Link to variable on master"
[jc-directory]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L12 "Link to variable on master"
[jc-x-connect-url]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L13 "Link to variable on master"
[jc-template-path]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L15 "Link to variable on master"
[jc-force-install]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L17 "Link to variable on master"
[jc-agent-service]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L18 "Link to variable on master"
[jc-use-sudo]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L19 "Link to variable on master"
[licence]: https://raw.githubusercontent.com/inviqa/ansible-jumpcloud/master/LICENSE

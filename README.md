# JumpCloud Role for Ansible
------------
This role installs the [JumpCloud][jumpcloud] agent and restarts the JumpCloud agent service as required.
It also make use of JumpCloud API to set JumpCloud System attributes.

## Requirements
------------
[cURL][curl] and NTP should be installed as prerequisites.

## Role Variables
------------
#### [`jumpcloud_api_key`][jumpcloud-api-key]
Default: none
Used to modify the attribute of a System on JC portal.

The API key as shown in the JumpCloud's API Settings.
To be retrieved from JumpCloud portal by a JC Admin account

To be stored in an Ansible Vault. It's very high-sensitivity Information.

#### [`jumpcloud_x_connect_key`][jumpcloud-x-connect-key]
Default: none

The X_Connect key as displayed on the `Servers > Add` screen. **Mandatory**.

#### [`jumpcloud_directory`][jumpcloud-directory]
Default: `/opt/jc`

Path to check if JumpCloud has been previously installed.

#### [`jumpcloud_x_connect_url`][jumpcloud-x-connect-url]
Default: 'https://kickstart.jumpcloud.com/Kickstart'

URL for the install script.

#### [`jumpcloud_force_install`][jumpcloud-force-install]
Default: `no`

Used to determine whether or not to force installation of the client if it has been previously installed.

#### [`jumpcloud_agent_service`][jumpcloud-agent-service]
Default: `jcagent`

Name of the service to restart.

#### [`jumpcloud_use_sudo`][jumpcloud-use-sudo]
Default: `no`

Whether or not to use sudo during installation.

#### [`jumpcloud_tags`]
The list of JC tags you want a host or a group of hosts to be part of
  - 'tag_one'
  - 'tag_two'

#### [`jumpcloud_displayName`][jumpcloud-displayName]
Default: `{{ inventory_hostname }}``

#### [`jumpcloud_allowPublicKeyAuthentication`][jumpcloud-allowPublicKeyAuthentication]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowSshPasswordAuthentication`][jumpcloud-allowSshPasswordAuthentication]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowSshRootLogin`][jumpcloud-allowSshRootLogin]
Default: `'true'`
This value must be contained in single quotes "\'"

#### [`jumpcloud_allowMultiFactorAuthentication`][jumpcloud-allowMultiFactorAuthentication]
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
## TODO
- [ ] create a conditional check to update tags only if they are defined as Variables
- [ ] add the automation of the tag creation if the tag doesn't exists in JC role
- [ ] add the possibility to define which users need to be tagged for that host's tag

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
[jumpcloud-x-connect-key]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L4 "Link to variable on master"
[jumpcloud-directory]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L12 "Link to variable on master"
[jumpcloud-x-connect-url]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L6 "Link to variable on master"
[jumpcloud-agent-service]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L8 "Link to variable on master"
[jumpcloud-force-install]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L9 "Link to variable on master"
[jumpcloud-use-sudo]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L10 "Link to variable on master"
[jumpcloud-displayName]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L11 "Link to variable on master"
[jumpcloud-allowPublicKeyAuthentication]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L12 "Link to variable on master"
[jumpcloud-allowSshPasswordAuthentication]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L13 "Link to variable on master"
[jumpcloud-allowSshRootLogin]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L14 "Link to variable on master"
[jumpcloud-allowMultiFactorAuthentication]: https://github.com/inviqa/ansible-jumpcloud/blob/master/defaults/main.yml#L15 "Link to variable on master"

[licence]: https://raw.githubusercontent.com/inviqa/ansible-jumpcloud/master/LICENSE

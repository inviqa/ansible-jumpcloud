Testing based on the work by @geerlingguy
at https://github.com/geerlingguy/ansible-role-test-vms

# Multi-Platform Ansible Role and Playbook Test VMs

Use Docker+Vagrant and some VirtualBox boxes to follow the latest releases of the OSes, and this project runs a playbook against the following OSs:

  - Debian Stable
  - Ubuntu 12.04.x
  - Ubuntu 14.04.x
  - Ubuntu 16.04.x
  - Ubuntu 18.04.x
  - CentOS 6.x (192.168.3.6)
  - CentOS 7.x (192.168.3.5)

## Requirements
Install Docker

set local Environment Variables that will be read by Ansible
```
JUMPCLOUD_X_CONNECT_KEY=yyyyyyyyyyyyyyzzzzzzzzzzxxxxxxxxxxxxx
JUMPCLOUD_API_KEY=xxxxxxxxxxxxxyyyyyyyyyyyyyyzzzzzzzzzz
```

Make sure that on you JumpCloud account you have the following System Groups:
```
ansible_test_1
ansible_test_2
```

## Testing a Role
The testing process works as follows:
There are an Ansible Playbook and Inventory configured to spin a bunch of Docker containers via Vagrant.
Ansible will install JumpCloud's agent in the containers.

At the end of the provisioning Ansible will run a few test-tasks that will verify if the JumpCloud agent has been installed and if the hosts have been registered again JC portal, including an idempotence test (the provisioning will be run twice on the same containers without rebuilding or restarting them)

This is the command to start the testing process

```
cd  ./tests
ansible-playbook -i inventory playbook.yml
```

To run the test on a specific containers you will need to create additional inventory files, i.e:


```
# *inventory-centos*

[centos]
centos7 image=chrismeyers/centos7
centos6 image=chrismeyers/centos6

[docker_containers:children]
centos

[docker_containers:vars]
# needed for idempotence test
restart=False

```

This command is to to run a playbook which will instruct Docker to destroy the testing containers.
```
cd  ./tests
ansible-playbook -i inventory playbook_cleanup.yml

```

### Travis CI Testing
For the testing to work set up in the Travis CI project's settings the following `Environment Variables` that will be read by Ansible

```
JUMPCLOUD_X_CONNECT_KEY=yyyyyyyyyyyyyyzzzzzzzzzzxxxxxxxxxxxxx
JUMPCLOUD_API_KEY=xxxxxxxxxxxxxyyyyyyyyyyyyyyzzzzzzzzzz
```

## License

MIT

## Author Information

Created in 2014 by [Jeff Geerling](http://jeffgeerling.com/), author of [Ansible for DevOps](http://ansiblefordevops.com/).

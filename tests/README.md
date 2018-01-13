Testing based on the work by @geerlingguy
at https://github.com/geerlingguy/ansible-role-test-vms

# Multi-Platform Ansible Role and Playbook Test VMs

Use Vagrant and some VirtualBox boxes that I build to follow the latest releases of the OSes. Currently, you can find the boxes on [Atlas](https://atlas.hashicorp.com/geerlingguy) (they are hosted at [files.midwesternmac.com](http://files.midwesternmac.com/)), and this project runs a playbook against the following OSes:

  - Ubuntu 12.04.x (192.168.3.4)
  - Ubuntu 14.04.x (192.168.3.3)
  - Ubuntu 16.04.x (192.168.3.2)
  - CentOS 6.x (192.168.3.6)
  - CentOS 7.x (192.168.3.5)

The project is extremely simple, and simply requires [Vagrant](https://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org/), and [Ansible](http://docs.ansible.com/intro_installation.html) to be installed on your host machine.

## Testing a Role

To test a role, the role must be installed on your host machine (you can install galaxy roles via `$ ansible-galaxy install [rolename]`, but this project is more focused on testing roles you'd be working on locally). Just add the role to `playbook.yml` and run `vagrant up`.

It should take a few minutes to download each of the base boxes the first time, but after that, it takes about a minute to boot each VM, then run the playbook with your role(s).

After testing a role, you can destroy the four VMs with `vagrant destroy -f`. You can also just build one particular VM with `vagrant up ubuntu1204` (as an example), or re-run the ansible playbook with `vagrant provision ubuntu1204`.

## License

MIT

## Author Information

Created in 2014 by [Jeff Geerling](http://jeffgeerling.com/), author of [Ansible for DevOps](http://ansiblefordevops.com/).

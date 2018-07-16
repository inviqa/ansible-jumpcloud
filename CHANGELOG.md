# CHANGELOG

V2.2
- verify if a system is correctly registered in JC
- automate the deletion of previously registered servers with the same name in JC
- automate the deletion of the registered servers in JC for testing purposes at the end of the test process
- remove support for Ubuntu 12.04 testing

V2.1
- replace Vagrant testing with Docker testing
- add test tasks and playbook to test on Debian stable, Ubuntu 12.04, 14.04, 16.04, 18.04, Centos 6 and Centos 7
- add TravisCI testing

v2.0
- implemented APIv2 task to handle System Groups
- removed support for TAGS (as they have been converted in Groups)
- added conditional check to add system to groups only when system groups are defined in `jumpcloud_system_groups`

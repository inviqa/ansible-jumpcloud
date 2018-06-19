# CHANGELOG

V2.1
- replace Vagrant testing with Docker testing
- add test tasks and playbook to test on Debian stable, Ubuntu 12.04, 14.04, 16.04, 18.04, Centos 6 and Centos 7
- add TravisCI testing

v2.0
- implemented APIv2 task to handle System Groups
- removed support for TAGS (as they have been coverted in Groups)
- added conditional check to add system to groups only when system groups are defined in `jumpcloud_system_groups`

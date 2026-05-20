#!groovy
import jenkins.model.Jenkins

Jenkins.instance.setSecurityRealm(null)
Jenkins.instance.setAuthorizationStrategy(null)
Jenkins.instance.save()

package main

deny[msg] {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.securityContext.allowPrivilegeEscalation == false
  msg := "containers must set securityContext.allowPrivilegeEscalation=false"
}

deny[msg] {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.securityContext.privileged == false
  msg := "containers must set securityContext.privileged=false"
}

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot == true
  msg := "pod must set securityContext.runAsNonRoot=true"
}

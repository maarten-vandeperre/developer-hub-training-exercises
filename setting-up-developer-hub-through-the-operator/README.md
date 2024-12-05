# Developer Hub Training Exercise - Setting up Developer Hub Through the operator

In this learning exercise, we'll focus on setting up Red Hat Developer Hub using the Developer Hub 
Operator. This will simplify the installation and management of the Developer Hub, streamlining your 
development environment. We'll cover the key steps involved in installing the operator, configuring 
the hub, and troubleshooting common issues during setup. By the end of this exercise, you'll have a 
fully functional Developer Hub in place, ready to enhance your development workflows and increase 
efficiency. You'll also gain practical experience in debugging any potential setup challenges.

You can find the exercise description over here (TODO: still needs to be published).

## Order of executing the yaml manifests
1. oc apply -f manifests/namespaces.yaml
2. oc apply -f manifests/operator-groups.yaml
3. oc apply -f manifests/operator.yaml
4. oc apply -f manifests/secrets_rdhd-secret.yaml
5. oc apply -f manifests/pvc_dynamic-plugin-root.yaml
6. oc apply -f manifests/developer-hub-instance.yaml


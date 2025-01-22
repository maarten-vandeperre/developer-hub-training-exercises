# Developer Hub Training Exercise - Setting up Developer Hub Through the operator

In this learning exercise, we'll focus on setting up Red Hat Developer Hub using the Developer Hub 
Operator. This will simplify the installation and management of the Developer Hub, streamlining your 
development environment. We'll cover the key steps involved in installing the operator, configuring 
the hub, and troubleshooting common issues during setup. By the end of this exercise, you'll have a 
fully functional Developer Hub in place, ready to enhance your development workflows and increase 
efficiency. You'll also gain practical experience in debugging any potential setup challenges.

https://developers.redhat.com/learn/deploying-and-troubleshooting-red-hat-developer-hub-openshift-practical-guide?ssd

## Order of executing the yaml manifests
1. Create namespaces:
   ```shell
   oc apply -f manifests/namespaces.yaml
   ```
2. Create operator groups:
   ```shell
   oc apply -f manifests/operator-groups.yaml
   ```
3. Install operator:
   ```shell
   oc apply -f manifests/operator.yaml
   ```
4. Wait for the operator to become healthy:
   Execute the following command and wait until the Developer Hub operator gets status 'Succeeded'
   _(in the beginning, it can give an empty result)_:
    ```shell
    oc get clusterserviceversion -n openshift-operators -o json | jq -r '{Name: .items[].spec.displayName, Status: .items[].status.phase}'
    ```
5. Create secret with base information:  
   **!!Important:** make sure that you change the base url to be your domain.
   ```shell
   oc apply -f manifests/secrets_rdhd-secret.yaml
   ```
6. Create dynamic plugin root peristent volume to speed up restarts:
   ```shell
   oc apply -f manifests/pvc_dynamic-plugin-root.yaml
   ```
7. Install Developer Hub Instance:
   ```shell
   oc apply -f manifests/developer-hub-instance.yaml
   ```
8. Wait for the instance of Developer Hub to become healthy:
   Execute the following command and wait until the Developer Hub instance gets condition 'Deployed' with status 'True'
   _(in the beginning, it can give an empty result)_:
    ```shell
    oc get backstage -n demo-project -o json | jq -r '{Name: .items[].metadata.name, ConditionType: .items[].status.conditions[].type, ConditionStatus: .items[].status.conditions[].status}'
    ```


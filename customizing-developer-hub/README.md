# Developer Hub Training Exercise - Customizing Developer Hub

In this learning exercise, we'll be customizing developer hub (e.g., look-and-feel, URL to access developer hub, learning paths, ...).

You can find the exercise description over here (TODO: still needs to be published).

## Customizing the theme (i.e., the look-and-feel)


## Order of executing the yaml manifests
1. **!! Important:** Do not forget to change the values to your GitHub app (client) credentials before applying the YAML.
   ```shell
   oc apply -f manifests/secrets_github-credentials.yaml
   ```
2. Create dynamic plugins configuration:      
   ```shell 
   oc apply -f manifests/dynamic-plugins-v1.yaml
   ```
3. Create app config configuration:
   ```shell 
   oc apply -f manifests/app-config-v1.yaml
   ```
4. Apply the updated instance config:  
   _If it is not taking updates on app config and/or dynamic plugins into account, 
  delete the running instance first and then apply this YAML again._
   ```shell 
   oc apply -f manifests/instance-config-v1.yaml
   ```
5. Wait for the pods to be restarted (and the old ones to be removed, to avoid unexpected behavior):
   ``` shell
   oc get pods -n demo-project -o json | jq '.items[] | select(.metadata.ownerReferences[0].name | startswith("backstage-developer-hub-")) | {POD: .metadata.name, DEPLOYMENT: .metadata.ownerReferences[0].name, Status: .status.phase, StartTime: .status.startTime }'
   ```
6. Update app config with software template added:
   ```shell 
   oc apply -f manifests/app-config-v2.yaml
   ```




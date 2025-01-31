# A simple getting started project for building Dynamic Plugins with Red Hat Developer Hub
_This one is based upon [this dynamic plugins getting started repository](https://github.com/gashcrumb/dynamic-plugins-getting-started)._

This project is an example approach to developing a new set of dynamic plugins by 
starting from a newly created Backstage application. 
The code in this repository is at the state where the plugins should be deployable 
to OpenShift (OCP) after building.
This guide will go through the steps leading up to this state, and continue on to
describe the commands needed to upload the dynamic plugin static content to a 
standalone httpd server that runs alongside the Red Hat Developer Hub instance.

[//]: # (The initial steps will focus on an operator based Developer Hub installation, )

[//]: # (perhaps a future update to this README can add the specifics for the Helm-based )

[//]: # (installation.)

At a high level plugin development involves bootstrapping a new Backstage instance 
using the Backstage create-app script, using yarn new to create new plugins, 
and finally developing these plugins using their respective development setup. The provided Backstage app gives an integration point to try all of the plugins together in a Backstage instance by statically integrating the plugins into the Backstage application code.

Once the plugin functionality is working as intended the plugins can be bundled 
and deployed to Developer Hub running on OCP by adding a build target to each 
plugin to export the dynamic plugin's static assets in a way that can be loaded
by Developer Hub.

## plugin development
* version compatibility matrix: https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/versions.md#version-compatibility-matrix
* mkdir plugin-workspace
* cd plugin-workspace
* npx @backstage/create-app@0.5.17* ==> can be that yarn install hangs or fails, but that's no issue so far
* name for the app: local-backstage*
* cd local-backstage
  ==> remove '"app": "link:../app",' from packages/backend/package.json and run yarn install again
* yarn new
* > backend-module
* plugin id: custom-plugin
  * module id: custom-module
  ==> can be that yarn install hangs or fails, but that's no issue so far

(no need to wait for yarn install to go forward with the next steps)


3. Go to plugins sub folder and select the plugin sub folders you want to edit.
    1. Add the following to the plugin's package.json: '"export-dynamic": "janus-cli package export-dynamic-plugin"'.
5. Remove "@backstage/backend-common": "^0.23.3" from plugin's package.json devDependencies
4. Go to the root package.json (e.g., workspace > dynamic-plugin-1 > dynamic-plugin-1) and add
   the new plugin folder to the 'export-dynamic' script.
    E.g., '"export-dynamic": "yarn --cwd plugins/custom-plugin-backend-module-custom-module export-dynamic"'
6. Add  "@janus-idp/cli": "^1.13.1" to the root package.json devDependencies
7. Create a folder named 'deploy' within the local-backstage folder.
6. From the local-backstage root folder, run 'yarn install && yarn run tsc && yarn run build:all && yarn run export-dynamic'
   or for a custom action 'janus-cli package export-dynamic-plugin --embed-package @backstage/plugin-scaffolder-backend-module-github --override-interop default --no-embed-as-dependencies'.
7. Run 'npm pack plugins/custom-plugin-backend-module-custom-module/dist-dynamic --pack-destination ./deploy --json | jq -r '.[0].integrity''
   in order to generate the first tar.gz file. (Be aware to change the plugin directory).
8. Store the resulting hash value, as you will need it later on
9. Make sure the namespace is set correctly (e.g., oc project rh-ee-mvandepe-dev)
9. oc new-build httpd --name=plugin-registry --binary 
10. oc start-build plugin-registry --from-dir=./deploy --wait 
11. oc new-app --image-stream=plugin-registry
12. add dynamic plugin to the dynamic plugins
```yaml
- package: 'http://plugin-registry:8080/internal-backstage-plugin-custom-plugin-backend-module-custom-module-dynamic-0.1.0.tgz'
  disabled: false
  integrity: 'sha512-wBbsXAWUZMfgQ1CsgdvfmpZALuKe6qkGFqxboWANY8ulchw0ii5ADRGoAPR7Ode1L/By1+dpurhtePfTZqdHJw=='
```


* yarn new
* > plugin
* plugin id: custom-fe-plugin
    * module id: custom-module
      ==> can be that yarn install hangs or fails, but that's no issue so far
3. Go to plugins sub folder and select the plugin sub folders you want to edit.
    1. Add the following to the plugin's package.json: '"export-dynamic": "janus-cli package export-dynamic-plugin"'.
4. Go to the root package.json (e.g., workspace > dynamic-plugin-1 > dynamic-plugin-1) and add
   the new plugin folder to the 'export-dynamic' script.
   E.g., '"export-dynamic": "yarn --cwd plugins/custom-plugin-backend-module-custom-module export-dynamic && yarn --cwd plugins/custom-fe-plugin export-dynamic"'
6. *Add  "@janus-idp/cli": "^1.13.1" to the root package.json devDependencies
7. *Create a folder named 'deploy' within the local-backstage folder.
6. From the local-backstage root folder, run 'yarn install && yarn run tsc && yarn run build:all && yarn run export-dynamic'
   or for a custom action 'janus-cli package export-dynamic-plugin --embed-package @backstage/plugin-scaffolder-backend-module-github --override-interop default --no-embed-as-dependencies'.
7. Run 'npm pack plugins/custom-fe-plugin/dist-dynamic --pack-destination ./deploy --json | jq -r '.[0].integrity''
   in order to generate the first tar.gz file. (Be aware to change the plugin directory).
8. Store the resulting hash value, as you will need it later on
9. Make sure the namespace is set correctly (e.g., oc project rh-ee-mvandepe-dev)
9. *oc new-build httpd --name=plugin-registry --binary
10. oc start-build plugin-registry --from-dir=./deploy --wait
11. *oc new-app --image-stream=plugin-registry
12. add dynamic plugin to the dynamic plugins
```yaml
- package: 'http://plugin-registry:8080/internal-backstage-plugin-custom-fe-plugin-dynamic-0.1.0.tgz'
  disabled: false
  integrity: 'sha512-T4GsJ007dWx8zXMpN+o2YCF8BE3X9s6fwJG0CMLH6X9Epx01qL3JqLnUVlLqt0Ju0C37kUV7EXpNDTjNAuPPlg=='
```

add to app-config
```yaml
dynamicPlugins:
      frontend:
        internal.backstage-plugin-simple-chat:
          entityTabs:
            # Adding a new tab
            - path: /dynamic-plugin-1
              title: Dynamic Plugin 1
              mountPoint: entity.page.dynamic-plugin-1
          appIcons:
            - name: chatIcon
              importName: ChatIcon
          mountPoints:
            - mountPoint: entity.page.ci/cards
              importName: SimpleChatPage
              config:
                layout:
                  gridColumn: '1 / -1'
            - mountPoint: entity.page.dynamic-plugin-1/cards
              importName: SimpleChatPage
              config:
                layout:
                  gridColumn: '1 / -1'
          dynamicRoutes:
            - path: /simple-chat
              importName: SimpleChatPage
              menuItem:
                text: 'Simple Chat'
                icon: chatIcon
```

apply dynamic plugins again
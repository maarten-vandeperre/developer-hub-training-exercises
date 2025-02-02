
# A simple getting started project for building Dynamic Plugins with Red Hat Developer Hub
_This one is based upon [this dynamic plugins getting started repository](https://github.com/gashcrumb/dynamic-plugins-getting-started)._

## Overview

> Note: The Dynamic Plugin functionality is a tech preview feature of Red Hat Developer Hub and is still under active development.  Aspects of developing, packaging and deployment of dynamic plugins are subject to change

This project is an example approach to developing a new set of dynamic plugins by starting from a newly created Backstage application.  
The code in this repository is at the state where the plugins should be deployable to OpenShift (OCP) after building.  
This guide will go through the steps leading up to this state, and continue on to describe the commands needed to upload 
the dynamic plugin static content to a standalone httpd server that runs alongside the Red Hat Developer Hub instance.

At a high level plugin development involves bootstrapping a new Backstage instance using the 
Backstage `create-app` script, using `yarn new` to create new plugins, and finally developing these 
plugins using their respective development setup.  The provided Backstage app gives an integration point to 
try all the plugins together in a Backstage instance by statically integrating the plugins into the Backstage application code.

Once the plugin functionality is working as intended the plugins can be bundled and deployed to Developer Hub running on OCP 
by adding a build target to each plugin to export the dynamic plugin's static assets in a way that can be loaded by Developer Hub.

## Prerequisites

* node 20.x (node 18 may work fine also but untested)
* npm (10.8.1 was used during development)
* yarn (1.22.22 was used during initial development)
* jq (1.7.1 was used during development)
* oc
* an OpenShift cluster with a Developer Hub deployment

The commands used for deployment were developed with the bash shell in mind on Linux, 
some steps may require adjustment when trying this on a Windows environment. 
This guide will try and highlight these cases, though probably WSL would work also (but hasn't been tested).

## The Guide

This guide is broken up into four top-level phases, bootstrapping the project and getting it ready, 
implementing the demo functionality, preparing and exporting the plugins as dynamic plugins and finally deploying to 
OpenShift and configuring Developer Hub to load the plugins.

> Note: If you're just interested in a method to deploy a dynamic plugin to Developer Hub you can skip straight 
> to [to this section](#phase-4---dynamic-plugin-deployment) for OpenShift, 
> or using [RHDH local](#using-rhdh-local), and finally [using podman](#using-a-container-image-for-local-development) to directly run the container.

### Phase 1 - Project Bootstrapping

#### Bootstrapping Step 1

Create a new Backstage app using a version of `create-app` that correlates to the Backstage version that the target Developer Hub is running.  
There is a [matrix of versions](https://github.com/janus-idp/backstage-showcase/blob/main/docs/dynamic-plugins/versions.md#version-compatibility-matrix) to be aware of:

```text
RHDH 1.1 -> Backstage 1.23.4 -> create-app 0.5.11
RHDH 1.2 -> Backstage 1.26.5 -> create-app 0.5.14
RHDH 1.3 -> Backstage 1.29.2 -> create-app 0.5.17
RHDH 1.4 -> Backstage 1.31.3 -> create-app 0.5.17
```

Now, create a dir demo-workspace and enter it (i.e., cd demo-workspace).

Then, for Developer Hub 1.4, run:
_There is an issue with the resulting component. Whenever the command reaches 'yarn install', it will stall.
You can ctrl+c (i.e., stop) this process now, remove the line '"app": "link:../app"' in 
local-backstage > backend > package.json_

```cli
npx @backstage/create-app@0.5.17
```

**When prompted for the name enter "local-backstage".**  
After prompting for a project name the `create-app` command will generate a git repo with the Backstage app and 
an [initial commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/6409e6e9a411387fc219dde00184e5cfe1dcb994)

`yarn install` is run automatically by the `create-app` script.  
The generated `package.json` also contains scripts such as `yarn tsc` and `yarn build:all` to build the repo as needed.

> There is an issue with multiple versions of express being dragged in, to resolve this,
> add the following line to the resolutions section of the root package.json:   
> "@types/express": "^5.0.0"

#### Bootstrapping Step 2 [optional]

The `create-app` script suggests to change to the "local-backstage" directory and run `yarn dev` however 
the plugins and development setup needs to be prepared first.

#### Bootstrapping Step 3 [optional]

In development, it's easiest to work with the guest authentication provider vs disabling authentication altogether.  
Set this up by adding a new file `app-config.local.yaml` with the following contents:

```yaml
auth:
  providers:
    guest: {}
```

#### Bootstrapping Step 4
_(Go into the local-backstage folder; i.e., cd local-backstage)_

Now the backend plugin can be bootstrapped.  Run `yarn new` and select `backend-plugin`.  
When prompted for a name specify `simple-chat`.  This will generate some example backend plugin code and add this plugin as a dependency to `packages/backend/package.json`.

[optional]  
The end result of all of this should look similar to 
[this commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/5d31fc3cb9b4a02e8d6dc51b5589ae95097657db) and the 
example backend endpoint should be accessible via `curl` when `yarn start` from `plugins/simple-chat-backend`

#### Bootstrapping Step 5

The frontend plugin can now be bootstrapped.  Run `yarn new` and select `plugin`.  
When prompted for a name, specify `simple-chat`  This will generate some starting frontend code and add this plugin as a dependency 
to `packages/app/package.json`.  The `yarn new` script in this case will also update `packages/app/src/App.tsx` 
to define a new `Route` component for the new plugin.  

[optional]   
However a link to the plugin still needs to be added to the application's 
main navigation.  Do this by editing `packages/app/src/components/Root/Root.tsx` and adding a new `SidebarItem` underneath the existing entry for "Create...":

```typescript
 <SidebarItem icon={ChatIcon} to="simple-chat" text="Simple Chat" />
```

Import `ChatIcon` from '@backstage/core-components'

```typescript
 ChatIcon
```

[optional]   
Once completed, the end result should look similar to 
[this commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/0aa89cdfaae84d42366aca0ac8fa018a187cabba).  
Do a rebuild with `yarn run tsc && yarn run build:all` and then the generated frontend plugin should be visible in 
the UI when running `yarn start` from the root of the repo.

### Phase 2 - Plugin Implementation [optional]

At this point it's time to develop the actual plugin functionality.  
The example app will be a very simple chat application, with the username derived from the logged-in user's identity.  
The backend in this first implementation will simply keep a store of chat messages in-memory.  
The frontend UI will just poll for chat messages and show a list of them, and offer a text input 
field that the user can send new messages with, using the Enter key.

The steps in this phase will not go to into much implementation detail but are called out separately to show 
how a frontend or backend plugin evolves from the generated code to an implementation and then finally a dynamic plugin.

#### Implementation Step 1 [optional]

Create the frontend implementation by changing directory to `plugins/simple-chat` and running `yarn start` 
to start up the frontend plugin's development environment.  
This simple development environment mimics much of the Backstage application shell and offers the ability 
to easily mock or proxy backend services when developing user-facing functionality.

First a simple API for the chat server is developed and mocked in the dev setup.  
To make HTTP requests to the server, an API client is created.  
A hook is used to handle polling the backend for updates, while a second API 
call takes care of sending new messages from the keydown event when the user hits Enter.

The client also uses the identity service to send along the user's username as a nickname.  
When guest authentication is used this value is actually not set, 
so the code deals with this by swapping in a "guest" username for this case.

The details of all of these changes on the generated frontend plugin can be found in 
[this commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/39c7f183c47e91885fe99e0b20588676cf294296).

At this point the chat UI should appear functional even from other windows, 
however refreshing the page will reset the available chat messages.

#### Implementation Step 2 [optional]

To develop the backend using the frontend as a client, run `yarn start-backend` to run the app backend.  
This also happens to serve out the same static assets as the main application, 
so the frontend UI plugin should be visible at `http://localhost:7007`, and can be used to help develop the backend.  
It is also possible to create the backend implementation by changing directory to `plugins/simple-chat-backend` 
and running `yarn start` to start up the backend plugin's development environment.  
This simple development environment runs a stripped down backend including the backend plugin, 
however no static assets such as the frontend UI are available in this mode.

In this case the backend implementation imports the httpAuth service to check 
if incoming requests have an authorization token, either for posting a new message or fetching the available messages.  
These messages are simply stored in an array for this example.

The details of these changes on the generated backend plugin can be found in 
[this commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/139df22817cff2b2cc0cae2391ddba2cdf16d027)

At this point the chat UI should be fully functional, chat messages from other windows/users should show up 
in the UI and the chat messages should not be lost when refreshing the page.

### Phase 3 - Dynamic Plugin enablement

> Note: The Dynamic Plugin feature in Developer Hub is still under active development.  
> Features and tooling around dynamic plugin enablement are still subject to change.

In this phase new build targets will be added to the plugins, along with any necessary 
tweaks to the plugin code to get them working as a dynamic plugin.

#### Enablement Step 1

First prepare the root `package.json` file by updating the `devDependencies` section and add the `@janus-idp/cli` tool:

```json
 "@janus-idp/cli": "^1.13.1",
```

The next job is to update the `scripts` section of the `package.json` files for the repo to add the `export-dynamic-plugin` command.

#### Enablement Step 2

Add the following to the `scripts` section of `plugins/simple-chat-backend/package.json`:

```json
"export-dynamic": "janus-cli package export-dynamic-plugin"
```

#### Enablement Step 3

Add the following to the `scripts` section of `plugins/simple-chat/package.json`:

```json
"export-dynamic": "janus-cli package export-dynamic-plugin"
```

#### Enablement Step 4

Update the root `package.json` file to make it easy to run the `export-dynamic` command from the root of the repository by adding one of the following to the `scripts` section:

##### using yarn v1

> Note: If running this on Windows, either use WSL (or similar) or adjust this command

```json
"export-dynamic": "yarn --cwd plugins/simple-chat-backend export-dynamic && yarn --cwd plugins/simple-chat export-dynamic"
```

##### using yarn v3+

```json
"export-dynamic": "yarn workspaces foreach -A run export-dynamic"
```

Also update the `.gitignore` file at this point to ignore `dist-dynamic` directories:

```text
dist-dynamic
```

#### Enablement Step 5

The backend as generated needs a couple tweaks to work as a dynamic plugin, 
as the generated code relies on a component imported from `@backstage/backend-defaults`.  
Update `plugins/simple-chat-backend/src/service/router.ts` to remove this import:

```typescript
import { MiddlewareFactory } from '@backstage/backend-defaults/rootHttpRouter';
```

and add this import instead:

```typescript
import { MiddlewareFactory } from '@backstage/backend-app-api';
```

These correspond to the versions of the packages released with Backstage 1.26.5.

#### Enablement Step 6

The frontend plugin has it's own icon in the main navigation which needs to be exported. 
Update `plugins/simple-chat/src/index.ts` to re-export the `ChatIcon` from 
`@backstage/core-components` from the plugin so it can be referenced in the configuration.  
Do this by updating `plugins/simple-chat/src/index.ts` to look like:

```typescript
import { ChatIcon as ChatIconBackstage } from '@backstage/core-components';
export { simpleChatPlugin, SimpleChatPage } from './plugin';
export const ChatIcon = ChatIconBackstage;
```

#### Enablement Step 7 [optional]

Finally, the frontend plugin should include some basic configuration so that it will be visible in the Developer Hub app.  
The convention currently is to put this into an `app-config.janus-idp.yaml` file.  
Create the file `plugins/simple-chat/app-config.janus-idp.yaml` and add the following:

```yaml
    dynamicPlugins:
      frontend:
        internal.backstage-plugin-simple-chat:
          appIcons:
          - name: chatIcon
            importName: ChatIcon
          dynamicRoutes:
          - path: /simple-chat
            importName: SimpleChatPage
            menuItem:
              text: 'Simple Chat'
              icon: chatIcon
```

While this is not currently used by any of the tooling, this still serves as a reference for plugin installers.

The results of all of these changes along with the additions discussed in the deployment phase are available in 
[this commit](https://github.com/gashcrumb/dynamic-plugins-getting-started/commit/08b637454f437d0c5a1f4185d8abfb2e0b84d83d)

### Phase 4 - Dynamic Plugin Deployment

> Note: The Dynamic Plugin feature in Developer Hub is still under active development. 
> Features regarding plugin deployment are still being defined and developed.  
> The method shown here is one method that doesn't involve using an NPM registry to host plugin static assets.

Deploying a dynamic plugin to Developer Hub involves exporting a special build of the plugin and packing it into a `.tar.gz` file.  
Once the dynamic plugins are exported as `.tar.gz` to a directory, that directory will be used to create an image, 
which will then be served by an `httpd` instance in OCP.  Custom deployment in Developer Hub is still in a technical preview phase, 
so there's not much tooling to help.  Some scripts mentioned in the last phase have been added 
to this repo to hopefully make this process straightforward.

#### Deployment Step 1

Create a directory to put the `.tar.gz` files into called `deploy` and add a `.gitkeep` file to it.
```text
mkdir deploy && touch deploy/.gitkeep
```

Update the `.gitignore` file as well to ignore `.tar.gz` files:

```text
deploy/*.tgz
```

#### Deployment Step 2

Make sure to build everything at this point, often it's easiest to run a chain of commands from the root of the repo like:

```text
yarn install && yarn run tsc && yarn run build:all && yarn run export-dynamic
```

#### Deployment Step 3
Now we are going to package the plugins, so that we can deploy them to a Developer Hub installation.

Do this for the front-end plugin:   
_!!! Store the resulting hash value, as you will need it later on_     
```shell
npm pack plugins/simple-chat/dist-dynamic --pack-destination ./deploy --json | grep 'integrity'
```  
  
Do this for the backend-end plugin:
_!!! Store the resulting hash value, as you will need it later on_  
```shell
npm pack plugins/simple-chat-backend/dist-dynamic --pack-destination ./deploy --json | grep 'integrity'
```

#### Deployment Step 4
Create the plugin repository:  
_(This step should only be executed once, when you change the plugin, you don't need to execute this command again)._
```shell
./oc new-build httpd --name=plugin-registry --binary
```  

Add the current plugins from the ./deploy folder to the plugin registry:  
```shell
./oc start-build plugin-registry --from-dir=./deploy --wait
```   

Create a new instance of the plugin repository:  
_(This step should only be executed once, when you change the plugin, you don't need to execute this command again)._
```shell
./oc new-app --image-stream=plugin-registry
```  


**In case you just want to update the plugin registry afterward, it is sufficient to only run this command:**  
```shell
./oc start-build plugin-registry --from-dir=./deploy --wait
```  


#### Deployment Step 5 
Add the plugins to the dynamic plugin configuration.  
**!!! Be aware that you need to change the integrity hashes**
```yaml
- package: 'http://plugin-registry:8080/internal-backstage-plugin-simple-chat-backend-dynamic-0.1.0.tgz'
  disabled: false
  integrity: 'sha512-KFmLwXfft5boOdpGZWTl52uMsEZAXrj3RJbVsjfqRTsGQJg3jDFJeM0y9heuDrHRFM4iFDcrWEWX6ztVOCCZnQ==' #backend-hash
- package: 'http://plugin-registry:8080/internal-backstage-plugin-simple-chat-dynamic-0.1.0.tgz' 
  disabled: false
  integrity: 'sha512-1W56bXXUmiB5q0rO+CX0L6PFVVyqUcV2QqkeQo+ejzDWhrl1DU7fKblA+vpHBz8iNR7K5mq9V7MsmDDpBxT2Eg==' #frontend-hash
```
  
Add the following config to the app-config:  

```yaml
dynamicPlugins:
  frontend:
    internal.backstage-plugin-simple-chat:
      appIcons:
        - name: chatIcon
          importName: ChatIcon
      dynamicRoutes:
        - path: /simple-chat
          importName: SimpleChatPage
          menuItem:
            text: 'Simple Chat'
            icon: chatIcon
```
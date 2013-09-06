This folder contains the logic for building the shadow_dom package's
concatenated and minified JS files.

## Prerequisites

Install nodejs and npm. On Debian based systems this is typically:

```bash
     sudo apt-get install nodejs
     sudo apt-get install npm
```
- Install grunt-cli:

```bash
    npm install -g grunt-cli
```

See the Grunt [getting started](http://gruntjs.com/getting-started) page
for more information.

## Building

Run shadow_dom/tool/build.sh (from any directory):

```bash
    ./build.sh
```

## (optional) How to integrate Polymer upstream changes

One time setup:

```bash
    # Note: this requires commit access to dart-lang/ShadowDOM.
    # You can use your own fork instead if you like.
    # Just use that URL here and edit build.sh to pull from there.
    git clone -b shadowdom_patches https://github.com/dart-lang/ShadowDOM.git
    cd ShadowDOM
    git remote add upstream https://github.com/Polymer/ShadowDOM.git
```

You can merge upstream changes by doing:

```bash
    # Check that we are in shadowdom_patches branch and don't have
    # any pending changes.
    git status

    git fetch upstream
    git merge upstream/master
    git push origin shadowdom_patches
```

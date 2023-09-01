This folder contains a pre-built Dart DevTools instance which can be served
as a web application, as well as the package:devtools_server and package:devtools_shared
packages from the same revision, used to host and launch DevTools from a Dart process.

To build DevTools and update the CIPD resources, do the following:

- Commits on devtools master are automatically built and packaged in CIPD.
  If a cherry-pick must be rolled into DEPS, then follow
  go/dart-engprod/devtools.md to manually trigger a secure devtools cipd build.
- Update DEPS to point to the newly updated DevTools by providing "revision:<revision>"
  as the version entry for "third_party/devtools"

DevTools CIPD packages are located at
https://chrome-infra-packages.appspot.com/p/dart/third_party/flutter/devtools/+/.

---
name: Report an issue related to Dart Web Stateful Hot Reload
about: >-
  Create an issue specific to the Stateful Hot Reload feature available via the
  Dart web development compiler (DDC).
labels: area-web, web-hot-reload, web-dev-compiler
assignees: nshahan, biggs0125
---
Begin by checking the [web-hot-reload](https://github.com/dart-lang/sdk/labels/web-hot-reload) label to ensure this is not a known issue.

If a similar issue has not been filed yet, use this template to file a new issue with the correct labels.

If the issue you are experiencing presents itself in Flutter, please file an issue here in the Dart repository. We will forward any Flutter-specific issues to the Flutter repository as needed.

Note: Hot reload rejections are expected errors that occur when a change is made that prevents the compiler from generating valid hot reload code. If you encounter such a rejection you must either undo the change to reload or perform a full hot restart.

Where possible, please include any relevant code snippets and previous versions of the code prior to hot reloading that may have contributed to the discovered issue.

If you are using a published SDK (e.g. on the dev channel) please include the version emitted by `dart --version`. If you're using a locally built SDK, please include the git commit of your local Dart checkout.

Thank you for helping improve hot reload on the web!

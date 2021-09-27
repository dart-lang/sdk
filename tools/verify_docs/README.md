## Whats' this?

A tool to validate the documentation comments for the `dart:` libraries.

## Running the tool

To validate all the dart: libraries, run:

```
dart tools/verify_docs/bin/verify_docs.dart
```

Or to validate an individual library (async, collection, js_util, ...), run:

```
dart tools/verify_docs/bin/verify_docs.dart sdk/lib/<lib-name>
```

The tool should be run from the root of the sdk repository.

## Authoring code samples

TODO(devoncarew): Document the conventions for code samples in the dart: libraries
and the tools available to configure them.

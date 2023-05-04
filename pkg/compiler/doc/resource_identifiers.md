# Resource Identifiers

Content TBD. Work in progress and details in flux.

### Example output

TODO: Reference goldens in tests rather than keep the example below.

The call to `loadDeferredLibrary` in the Dart js_runtime is annotated with
`@pragma('dart2js:resource-identifier')`. This means that an app that uses
deferred loaded libraries will generate a section in the `.resources.json`.


In the Dart sdk directory, compile:

```sh
dart compile js --write-resources --out=somedir/o.js \
   benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart
```

`somedir/o.js.resource_identifiers.json`:

```json
{
  "environment": {
    "dart.web.assertions_enabled": "false"
  },
  "identifiers": [
    {
      "name": "loadDeferredLibrary",
      "uri": "org-dartlang-sdk:///lib/_internal/js_runtime/lib/js_helper.dart",
      "nonconstant": false,
      "files": [
        {
          "filename": "o.js",
          "references": [
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 15,
                "column": 17
              },
              "1": "lib_BigIntParsePrint",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 16,
                "column": 56
              },
              "1": "lib_ListCopy",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 17,
                "column": 54
              },
              "1": "lib_MapCopy",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 18,
                "column": 46
              },
              "1": "lib_MD5",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 19,
                "column": 62
              },
              "1": "lib_RuntimeType",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 20,
                "column": 48
              },
              "1": "lib_SHA1",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 21,
                "column": 52
              },
              "1": "lib_SHA256",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 23,
                "column": 17
              },
              "1": "lib_SkeletalAnimation",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 25,
                "column": 17
              },
              "1": "lib_SkeletalAnimationSIMD",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 27,
                "column": 17
              },
              "1": "lib_TypedDataDuplicate",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 28,
                "column": 60
              },
              "1": "lib_Utf8Decode",
              "2": 0
            },
            {
              "@": {
                "uri": "benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart",
                "line": 29,
                "column": 60
              },
              "1": "lib_Utf8Encode",
              "2": 0
            }
          ]
        }
      ]
    }
  ]
}
```

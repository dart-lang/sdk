# Resource Identifiers

Tree-shaking can cause APIs and resources to be removed from programs.  We
developed a mechanism in dart2js to help developers understand what resources
are still in use after an application is optimized.

## Status

(experimental, in progress)

Currently we have a mechanism that only supports tracking static member
functions. It is not rich enough to track the use of resource classes or
constants, like `IconData` in flutter applications. That would be an ideal
expansion in the future.

## How it works
Today, a developer can tag a top-level method with two pragmas:
```
@pragma('dart2js:never-inline')
@pragma('dart2js:resource-identifier')
void myTopLevelMethod() {... }
```

This will indicate to dart2js that `myTopLevelMethod` is a member it needs to
track. The `never-inline` pragma is necessary because dart2js cannot track
members after they get inlined.

When providing dart2js with the experimental `--write-resources` flag, the
compiler will emit a `.resources.json` file. This file lists whether any
top-level methods annotated with the special pragma was invoked in the program.
It will also include some additional static information, like the source
location of the call, or even which parameters where provided (if the parameters
are constant).

### Example output

TODO: Reference goldens in tests rather than keep the example below.

In the Dart sdk directory, there is a sample benchmark that contains deferred
loaded libraries. If you compile it as:

```sh
dart compile js --write-resources --out=somedir/o.js \
   benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart
```

You can inspect `somedir/o.js.resource_identifiers.json` to see what the output
looks like. At the time this doc was written, the output was:

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

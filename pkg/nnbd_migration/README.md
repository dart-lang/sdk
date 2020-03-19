# Null Safety Migration Tooling

Note: the null safety migration tooling and workflow is in an early state;
this doc will be updated as the steps and workflow are simplified.

## Building the NNBD sdk

In order to run the tool currently you have to be able to build your own copy
of the Dart SDK.

To do this, run:

```
./tools/build.py -mrelease --nnbd create_sdk
```

The NNBD sdk now lives under the ReleaseX64NNBD sub-directory of your build
directory, e.g.

```
xcodebuild/ReleaseX64NNBD/dart-sdk/
```

## Trying this for Flutter devs

TODO:

## Migrating a package

- build a NNBD version of the SDK (see above)
- select a package to work on
- in that package, edit the `analysis_options.yaml` to enable the NNBD
  experiment from the POV of the analyzer:
```yaml
analyzer:
  enable-experiment:
    - non-nullable
```
- run `pub get` for the package (and, verify that the
  `.dart_tool/package_config.json` file was created)

Then, run the migration tool from the top-level of the package directory:

```
<sdk-repo>/xcodebuild/ReleaseX64NNBD/dart migrate .
```

The migration tool will run, print the proposed changes to the console, and
display a url for the preview tool. Open that url from a browser to see a rich
preview of the proposed null safety changes.

## Using the tool

TODO:

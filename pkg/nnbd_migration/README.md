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

1. run the tool (see above)
2. once analysis completes, open the indicated url in a browser
3. browse around the migration preview page, verifying changes and following links to
   see why some changes were made
4. if you disagree with some changes (too many items made nullable?), locate the source
  reason why the change(s) were made, and either:
  1. edit the source file in your IDE, adding a hint to the migration tool about how
     to migrate that type and its uses (`String foo` ==> `String/*!*/ foo`)
  2. or, have the migration tool perform this itself; from the 'Edit Details' area in
     the bottom right, select the `Force type to be non-nullable` or `Force type to be
     nullable` links. These will perform the indicated changes on disk and re-run
     analysis.
5. if you use step 4.2 above, the migration tool will automatically re-perform the 
   migration analysis. If you make manual changes to the files in an IDE, you'll need
   to close the migration tool, and re-perform analysis yourself (loop back to step 1)
6. Once you're happy with the migration results you can apply the proposed changes to
   disk. You can do this directly from the tool (the 'Apply Migration' button in the
   upper right), or, close the tool and re-run from the command line with the
   `--apply-changes` command line argument.

## Providing feedback

Please file issues at https://github.com/dart-lang/sdk/issues, and reference the
`analyzer-nnbd-migration` label (you may not be able to apply the label yourself). 

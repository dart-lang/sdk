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

1. Run the tool (see above).
2. Once analysis and migration suggestions are complete, open the indicated url
in a browser.
3. Start with an important or interesting file in your package on the left
side by clicking on it.
4. Look at the proposed edits in the upper right, and click on them in turn.
5. If you see an edit that looks wrong:
    1. Use the "trace view" in the bottom right to find the root cause
    2. Go to your editor and make a change to the original file by adding a hint
    (`String foo` ==> `String/*!*/ foo`) or making other changes as needed.
    3. You can have the migration tool perform this itself, although right now
       for large packages this takes a prohibitively long time.
       1. ***Warning: DO NOT mix edits in your editor and edits applied by the
       migration tool. We have not yet written the necessary logic to
       prevent the migration tool from clobbering files edited while the
       preview tool is running.*** 
       2. To try this, from the 'Edit Details' area in the bottom right select
       the `Force type to be non-nullable` or `Force type to be nullable`
       links. These will add the indicated hints on disk and recompute the
       migration suggestions. 
6. After some edits are complete, control-C the migration and rerun it.  If
some things are still wrong, return to step 5.
7. Once all edits are complete and you've rerun migration and are satisfied with
the output:
    1. Save your work using git or other means. Applying the migration will
    overwrite the existing files on disk.
    2. Rerun the migration with `--apply-changes`, or click the
    `Apply Migration` button in the interface.
8. Remove any SDK constraint in your pubspec.yaml.
9. Remove any opt-out comments in your library files (e.g.:  `// @dart = 2.6`).
10. Rerun `pub get` and test your package.

## Providing feedback

Please file issues at https://github.com/dart-lang/sdk/issues, and reference the
`analyzer-nnbd-migration` label (you may not be able to apply the label yourself). 

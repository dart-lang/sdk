# Null safety migration tooling

**Note**:

  * This migration tool is now available through the SDK, using the `dart
    migrate` command.  Support for running it via `pub activate` is deprecated.
  * The null safety migration tooling is in an early state and may have bugs and
    other issues.
  * As null safety is still in preview, we recommend only doing trial
    migrations. The final migration of apps and packages should not be done
    until the feature is more complete.
  * For best results, use SDK version 2.9.0-10.0.dev or higher.

## How migration works

The migration uses a _new interactive algorithm_ designed specifically for [Dart
null safety](https://dart.dev/null-safety).

Typical code migration tools are designed to be run once, handle most cases, and
let the developer do manual cleanup on the result. This does **not work well**
for null safety and attempting this workflow will result in a lot more manual
work. Similarly, after your migration has been applied, the migration **cannot
be rerun** without first reverting it.

### Why does the interactive approach save so much time?

Remember that Dart already has nullable types. Every type in old Dart code is
nullable! What old Dart lacks is _non-null_ types.

And like most migrations, our tool tries to preserve your code's current
behavior. In the case of null safety, we may mark a lot of your types as
nullable -- because they really were nullable before.

Nulls are traced through your program as far as they can go, and types are
marked nullable in this process. If the tool makes a single mistake or choice
you disagree with, it can lead to many excess nullable types.

### Interactive feedback to the tool

Unintentional null is the top cause of crashes in Dart programs. By marking your
intention with comments like `/*?*/` and `/*!*/`, we can stop these
unintentional nulls from spreading through your program in your migrated code.
Adding a small number of these hints will have a huge impact on migration
quality.

The high level workflow of the tool is therefore driven through an interactive
web UI. After starting the tool with `dart migrate`, open the presented URL in a
browser. Scan through the changes, use the "nullability trace" feature to find
the best place to add a nullability hint (adding a hint in the best place can
prevent dozens of types from being made nullable). Rerun the migration and
repeat, committing the hints as you go. When the output is correct and
acceptable, apply the migration.

For example,

```dart
List<int> ints = const [0, null];
int zero = ints[0];
int one = zero + 1;
List<int> zeroOne = [zero, one];
```

The default migration will be backwards compatible, but not ideal.

```dart
List<int?> ints = const [0, null];
int? zero = ints[0];
int one = zero! + 1;
List<int?> zeroOne = <int?>[zero, one];
```

`zero` should not be marked nullable, but it is. We then have cascading quality
issues, such as null-checking a value that shouldn't have been marked null, and
marking other variables as null due to deep null tracing. We can fix this all by
adding a single `/*!*/` hint.

```dart
List<int?> ints = const [0, null];
int/*!*/ zero = ints[0]!; // Just add /*!*/ here, the migration tool does the rest!
int one = zero + 1;
List<int> zeroOne = <int>[zero, one];
```

If you add one hint before migrating, you have done the equivalent of making
five manual edits after migrating. To find the best place to put your hints, use
the preview tool's nullability trace feature. This lets you trace back up to the
root cause of any type's inferred nullability. Add hints as close to the
original source of null as possible to have the biggest impact to the migration.

**Note**: The migration tool **cannot be rerun on a migrated codebase.** At
that point in time, every nullable and non-nullable type is indistinguishable
from an **intentionally** nullable or non-nullable type. The opportunity to
change large numbers of types for you at once without also accidentally changing
your intent has been lost. A long migration effort (such as one on a large
project) can be done incrementally, by committing these hints over time.

<!-- TODO(srawlins): We should explain (or point to explanation of) "migrated"
code. I don't see any documents pointing out how null safety is enabled via
pubspec.yaml, or library-by-library comments. -->

## Migrating a package

1. Select a package to work on, and open a command terminal in the top-level of
   the package directory.
2. Run `pub get` in order to make available all dependencies of the package.
3. It is best to migrate a package to null safety _after_ the package's
   dependencies have migrated to null safety. Run
   `pub outdated --mode=null-safety` to learn the migration status of the
   package's dependencies. See the
   [pub outdated documentation](https://dart.dev/tools/pub/cmd/pub-outdated)
   for more information.
4. It is best to migrate a package starting from a clean code repository state
   (`git status`, for example), in case you must revert the migration. Ensure
   there are no pending changes in the package's code repository.
5. Run the migration tool from the top-level of the package directory:

   ```
   dart migrate
   ```

The migration tool will display a URL for the web interface. Open that URL in a
browser to view, analyze, and improve the proposed null-safe migration.

## Using the tool

1. Run the tool (see above).
2. Once analysis and migration is complete, open the indicated URL in a browser.
3. Start with an important or interesting file in your package on the left side
   by clicking on it.
4. Look at the proposed edits in the upper right, and click on them in turn.
5. If you see an edit that looks wrong:
    1. Use the "trace view" in the bottom right to find the root cause
    2. Either click on an "add hint" button to correct it at the root, or open
       your editor and make the change manually.
        * Some changes are as simple as adding a `/*!*/` hint on a type. The
          tool has buttons to do this for you.
        * Others may require larger refactors. These changes can be made in
          your editor.
        * Changes may even be committed to source code management before finally
         _applying_ the migration. In this way, a migration of a large package
         can be carried out over multiple sessions, or between multiple
         engineers. Committing hints and other adjustments along the way helps
         to separate the concerns of describing user intent vs committing to the
         migration result.
    3. Periodically rerun the migration and repeat.
6. Once you are satisfied with the proposed migration:
    1. Save your work using git or other means. Applying the migration will
       overwrite the existing files on disk.
       * Note: In addition to making edits to the Dart source code in
         the package, applying the migration edits the package's `pubspec.yaml`
         file, in order to change the Dart SDK version constraints, under the
         `environment` field, and the "Package Config" file, located in the
         package's `.dart_tool` directory, named `package_config.json`.
    2. Apply the migration by clicking the `Apply Migration` button in the
       interface.
    3. Tip: leaving the web UI open may help you if you later have test failures
       or analysis errors.
7. Rerun `pub get`, then analyze and test your package.
    1. If there are new static analysis issues, or if a test fails, you may
       still use the preview to help you figure out what went wrong.
    2. If large changes are required, revert the migration, and go back to step
       one. The tool does not provide any revert capability; this must be done
       via source code management (for example, `git checkout`).

<!-- TODO(srawlins): direct the user to publish, only after null safety leaves
tech preview. See the big note at https://dart.dev/null-safety.
8. Commit and/or publish your migrated null-safe code. -->

## Providing feedback

Please file issues at https://github.com/dart-lang/sdk/issues, and reference the
`analyzer-nnbd-migration` label (you may not be able to apply the label yourself).

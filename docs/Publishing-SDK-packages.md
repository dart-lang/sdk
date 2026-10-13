# Publishing SDK packages

Packages in `pkg/` and `third_party/pkg/` that are tracked in this repository
and do not have `publish_to` (such as `publish_to: none`) in their
`pubspec.yaml` are published to [pub.dev](https://pub.dev) automatically from
the `main` branch. Packages from `DEPS` are not tracked in this repository and
cannot be published this way.

To publish a package:

1. Make sure automated publishing is enabled for the package on pub.dev, see
   below.
2. Set `version:` in the `pubspec.yaml` of the package to the release version
   (without a `-wip` or `-dev` suffix) and make sure the first version heading
   in the `CHANGELOG.md` of the package matches.
3. Add a `PUBLISH=<package>-v<version>` line to the commit message, e.g.:

   ```
   Prepare to publish package:analyzer 14.6.0

   PUBLISH=_fe_analyzer_shared-v110.0.0
   PUBLISH=analyzer-v14.6.0
   ```

   The line must start at the beginning of the line. Multiple `PUBLISH=` lines
   can be used to publish several packages from one commit.
4. Land the commit on `main`.

Once the commit lands, the `tag-packages` builder creates a
`<package>-v<version>` tag for each `PUBLISH=` line, and the
[publish workflow](../.github/workflows/publish.yml) publishes the package from
GitHub Actions when the tag is mirrored to GitHub. Packages are published with
`--skip-validation`, so run
`tools/sdks/dart-sdk/bin/dart pub publish --dry-run --directory=pkg/<package>`
before landing the commit if in doubt. If pub.dev rejects the publication, the
tag has already been created and a new version is needed.

The presubmit requires a `PUBLISH=<package>-v<version>` line whenever the
version of a publishable package is changed to a version without a `-wip` or
`-dev` suffix. To change the version without publishing, add a
`SKIP_PUBLISH=<package>` line instead.

Packages are only published from `main`; `PUBLISH=` lines on other branches are
ignored. Reverting a commit with a `PUBLISH=` line does not unpublish anything,
so the next release needs a new version.

## Enabling automated publishing for a package

Automated publishing must be enabled once per package by an uploader or
publisher admin on `https://pub.dev/packages/<package>/admin`:

* **Repository:** `dart-lang/sdk`
* **Tag pattern:** `<package>-v{{version}}`

This is only possible once the package exists on pub.dev, so the first version
of a new package must be published manually with `dart pub publish`.

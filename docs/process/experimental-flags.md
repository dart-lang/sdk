# Dart SDK process for changes behind experimental flags

## Problem statement

The Dart SDK ships via a number of channels:

- Via the [Dart SDK](https://dart.dev/get-dart#install)
- Via the [Flutter SDK](https://flutter.dev/)
- Internally at Google via an internal channel

Each of these channels use varying release calendars, and keeping these entirely
aligned is not practical. Further, a number of developers interested in staying
current with Dart changes, consume the Dart SDK via our [dev
channel](https://github.com/dart-lang/sdk/wiki/Branches-and-releases). As a
result, we should anticipate that any dev channel build has the potential to end
up as a shipped SDK though some channel. And as a consequence of that, it is
critical that we keep the quality of our dev channel high AND that we keep it
consistent wrt. which features are complete and supported. At the same time, we
need the ability to land incomplete features to facilitate a number of tasks:

- Compose a feature that spans multiple components/areas
- Automated testing prior to the full completion of the feature
- Allow partner teams to get a preview of a future feature
- Allow customers to get a preview of a future feature
- Etc.

## Solution

To ensure completed & supported features can be differentiated from incomplete
features in-progress, we will put all in-progress features behind a single set
of flags. Changes to features behind these flags are not considered breaking
(even if the feature behind the flag was in a stable SDK), and they are subject
to removal at any time. For details about breaking changes, see the breaking
change process.

All new features that meet one of the following criteria must be developed
behind a flag (when possible):

- All breaking changes
- All language changes

Further, it is recommended to consider developing behind a flag when:

- Landing larger, user-visible changes which will be in an intermediate state
  over several weeks and perhaps even releases
- Making changes with the potential to have significant negative performance
  impact for several weeks and perhaps even across releases

## Details

### Flag format for CLI-based tools

Flags consist of one or more words, combined using dashes, using all lower-case.
The single source of truth of these flags shall be a single shared .dart file.
The tools are expected to offer a framework for querying these flags so that the
implementation of the tools can easily access new flags.

The flags are passed to CLI-based tools using the `--enable-experiment` flag
Multiple flags can be passed by using multiple flags, or by passing several
comma-separated flags. Examples:

```
dart --enable-experiment=super-mixins
dart --enable-experiment=super-mixins,no-slow-checks,preview-dart3
dart --enable-experiment=super-mixins --enable-experiment no-slow-checks --enable-experiment preview-dart3
```

If the user passes a flag that is not recognized (for example, when the flag is
no longer supported), the tool is required to inform about this by printing to
stderr, and not fail.

```
dart --enable-experiment better-mixins
Unknown experiment flag 'better-mixins'.
```

### Flag format for UI-based tools (IDEs/editors/etc.)

IDEs and editors which offer the ability to invoke Dart tools, must support
passing these flags. The support should be generic and flexible so that no UI
change is required when we add or remove a flag. This is expected to take one of
two forms:

- Experiments affecting analysis can be enabled in `analysis_options.yaml` under
  a single `enable-experiment:` key, e.g. to enable the flags `super-mixins` &
  `no-slow-checks`:

  ```
  analyzer:
    enable-experiment:
      - super-mixins
      - no-slow-checks
  ```

- Experiments affecting launch/run behavior, can be enabled in the IDE specific
  run Configuration, by passing the same `--enable-experiment` flag as listed in
  the CLI section.

The current set of experiment flags is defined in a YAML file which the various
tools access:
[experimental_features.yaml](../../tools/experimental_features.yaml).

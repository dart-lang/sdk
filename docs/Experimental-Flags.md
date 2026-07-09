> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

## Experimental Flags

_**NOTE**: This page is intended for developers working on the Dart SDK. If you are a developer and want to **use** experiment flags, see the [experiment flags documentation](https://dart.dev/tools/experiment-flags)._

When working on new features, it is common to control the availability of the feature through a flag. These features are turned off by default during the development cycle and enabled by default after there is sufficient signal that the feature is ready.

Experiment flags are defined in this SDK file:
https://github.com/dart-lang/sdk/blob/main/tools/experimental_features.yaml

Once there is a decision to enable the flag by default in a release, we need to retire the flag.

### When do we retire flags?

Flags should be retired once they have been in stable for a full release cycle (~3 months) and have not caused a significant amount of issues.

1. Feature is developed and hidden behind a flag, which is usually made public in beta 1 of version n-1.
2. Feature flag is enabled by default in beta 1 of version n.
3. Feature flag is retired in beta 1 of version n+1.

Typically, a feature will be experimentally available in the SDK prior to the feature being officially released, but there can be exceptions.
Development of a feature can span several versions, either because it's a big feature like null safety, or because the feature got deprioritized like triple-shift. Feature development can also be very short and happen entirely within a single release cycle, with the experiment only available through dev-releases of version n.

Example:

> The Dart community has been working on implementing telepathic code generation to be released in Dart 6.2.  Users of the Dart 6.1 beta can try this experimental feature using the `--enable-experiment=telepathy` flag. The feature seems to be stable and successful.  In dart 6.2 the feature is no longer behind an experimental flag and is enabled by default.  The team now cleans up the experimental flag tests and removes the flag before launching Dart 6.3.

### Flag retirement work

1. Clean up tests that use experimental flags.
2. Ensure non-test code does not rely on experimental flags.
3. Verify that tests in `/pkg/*` directory do not rely on experimental flags.
4. Set `expired: true` in `tools/experimental_features.yaml` under the experimental flag entry.
5. Run the update scripts to update generated flag-handling code.
6. Alert the EngProd team of work completion.
7. EngProd team increments the SDK version.

## Tools for processing the Dart SDK

# patch_sdk.dart

This script combines:

    tool/input_sdk/lib/...
    tool/input_sdk/patch/...
    tool/input_sdk/private/...

and produces the merged SDK sources in:

    tool/generated_sdk/...

The result has all "external" keywords replaced with the @patch implementations.

Generally local edits should be to `input_sdk/patch` and `input_sdk/private`,
as those two directories are specific to DDC. `input_sdk/lib` should represent
unmodified SDK sources to the maximum extent possible. Currently there are
slight edits to the type annotations in some cases.

See patch_sdk.dart for more information.

# sdk_version_check.dart

Asserts that the Dart VM is at least a particular semantic version.
It returns an exit code to make it easy to integrate with shell scripts.

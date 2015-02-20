## Tools for processing the Dart SDK

# patch_sdk.dart

This script combines:

    tool/input_sdk_src/...
    tool/input_sdk_patch/...

and produces the merged SDK sources in:

    test/generated_sdk/...

The result has all "external" keywords replaced with the @patch implementations.

Generally local edits should be to `input_sdk_patch`, as it is specific to DDC.
`input_sdk_src` should represent unmodified SDK sources to the maximum extent
possible. Currently there are slight edits to the type annotations in some
cases.

See patch_sdk.dart for more information.

# sdk_version_check.dart

Asserts that the Dart VM is at least a particular semantic version.
It returns an exit code to make it easy to integrate with shell scripts.

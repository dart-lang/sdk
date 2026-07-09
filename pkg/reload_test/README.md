# Testing Framework for Hot Reload/Restart Tests for DDC

<!--- TODO(srujzs): Document this package more. For now, document some
conventions that may not be obvious. --->

This package contains utilities to test multiple generations of files in order
to validate hot reload and hot restart.

## Test File Conventions

- Different generations of files have a generation number after the file name
e.g. `file_name.1.dart` is the generation 1-version of the file.
- If a generation file is intended to be rejected, it should contain `.reject`
in the file name. The `config.json` file should contain a key `"expectedErrors"`
with its value being a map of generation number string to the error string.
- If a generation does a hot restart instead of a reload, it should contain
`.restart` in every file name in the same generation.
- It is an error to specify both `.reject` and `.restart`.

# `dart fix`

## What is it?

`dart fix` is a command line tool and part of the regular `dart` tool. It is used
to batch apply fixes for analysis issues.

## How does it work?

`dart fix` runs over your project looking for analysis issues. For each issue
it checks whether there is an automated fix that can be applied. These fixes
are generaly either in response to a lint or hint in your code, or part of
upgrading your source to newer package APIs.

For the first type of change, the fixes are generally in response to the set
of lints and analysis configuration specified in your [analysis_options.yaml]
file.

The second type of change - upgrading to newer package APIs - is performed
based on API changes defined for specific packages. This declarative definition
of the API changes lives in a `fix_data.yaml` file in the package's `lib/`
directory (documentation forthcoming).

## Command line usage

```
Fix Dart source code.

This tool looks for and fixes analysis issues that have associated automated
fixes or issues that have associated package API migration information.

To use the tool, run one of:
- 'dart fix --dry-run' for a preview of the proposed changes for a project
- 'dart fix --apply' to apply the changes

Usage: dart fix [arguments]
-h, --help       Print this usage information.
-n, --dry-run    Show which files would be modified but make no changes.
    --apply      Apply the proposed changes.

Run "dart help" to see global options.
```

[analysis_options.yaml]: https://dart.dev/guides/language/analysis-options

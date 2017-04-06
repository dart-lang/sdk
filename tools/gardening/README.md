# Gardening Tools

This directory is created for gathering all tools doing gardening in one place.
Every tools or script, big or small should go here, and over time, hopefully
we will have useful collection of tools that support every part of the 
gardening work.

The current tools are:

#### compare_failures ####
Compares the test log of a build step with previous builds. Use this to detect 
flakiness of failures, especially timeouts.

Usage:

```console
dart bin/compare_failures.dart <stdio-url>
```

where `<stdio-url>` is a url for a test log (".../logs/stdio") from the 
buildbot. 

#### status_summary ####
Collects the configurations for all status files in the 'tests' folder that
mention one of the test names given as argument.

Usage:

```console
dart bin/status_summary.dart <test-name1> [<test-name2> ...]
```

where `<test-nameX>` are test names like `language/arithmetic_test`.

#### current_summary ####
Collects the test results for all build bots in [buildGroups] for tests
that mention one of the test names given as argument.

Usage:

```console
dart bin/current_summary.dart <test-name1> [<test-name2> ...]
```

where `<test-nameX>` are test names like `language/arithmetic_test`.

The results are currently pulled from the second to last build since the
last build might not have completed yet.

#### find_timeouts ####
Scans past `dart2js-windows` test steps for timeouts and reports the
frequency of each test that has timed out.

Usage: 
```console
dart bin/find_timeouts.dart [<count>]
```

where `<count>` is the number past build that are scanned.  
# Gardening Tools

This directory is created for gathering all tools doing gardening in one place.
Every tool or script, big or small should go here, and over time, hopefully we
will have a useful collection of tools that support every part of the gardening
work.

The current (working) tools are:

- [results](#results)
- [compare_failures](#compare_failures)
- [status_summary](#status_summary)
- [current_summary](#current_summary)
- [luci](#luci)

All the tools have been created in an add-hoc manner, thus they solve specific
tasks that may not match your workflow fully. Feel free to add functionality to
these. Below is a detailed description of each of the tools.

## results ##
The results tool should be the primary tool for looking at failures and updating
of status files. The tool fetches results.logs generated for each invocation of
test.py on either the build bots or the CQ and matches the actual result for
each test against the status files in your repository. Use it by calling:

`dart results.dart get failures <argument>`

The arguments can be one of the following:

```console
    get failures <result.log>               : for a local result.log file.
    get failures <uri_to_result_log>        : for direct links to result.logs.
    get failures <uri_try_bot>              : for links to try bot builders.
    get failures <commit_number> <patchset> : for links to try bot builders (see example below).
    get failures <builder>                  : for a builder name.
    get failures <builder> <build_number>   : for a builder and build number.
    get failures <builder_group>            : for a builder group.
```

Some common workflows are listed below.

#### Finding failures on the CQ by link ####
If a CQ job fails then you will receive an email about try jobs failing. There
is a direct link in the email to the builder that observed a failure:

`https://ci.chromium.org/swarming/task/<swarm_task_id>?server=chromium-swarm.appspot.com`

Copy the link and paste it in the command below to see all failures for that
builder:

```console
dart tools/gardening/bin/results.dart get failures <url>

All result logs fetched.
Calling test.py to find status files for the configuration and the expectation for 18298 tests. Estimated time remaining is 1 seconds...
	FAILED: analyzer/test/generated/strong_mode_kernel_test
	Result: RuntimeError
	Expected: {Slow, Pass}
	Configuration: mode=release, arch=x64, compiler=none, runtime=vm, checked, system=windows, use-sdk, builder-tag=win7

	To run locally (if you have the right architecture and runtime):
	tools/test.py --mode=release --arch=x64 --compiler=none --runtime=vm --checked --system=windows --use-sdk --builder-tag=win7 pkg/analyzer/test/generated/strong_mode_kernel_test

```

In the PolyGerrit interface under Tryjobs, for each try builder, you can obtain
the link by right-clicking a builder-link and use copy link address.

#### Finding failures on the CQ by CL number and patch set ####

To get all failures from all builders in a try run, you can use the following
command:

```console
dart tools/gardening/bin/results.dart get failures <CL number> <patch set>
```

The CL number is shown at the top of the page, and in the URL, and the patch set
number is shown in the try jobs pane.

#### Finding failures on the build bots ####

There are a few ways to find failures on build bots.

To find failures for an entire builder group use the following:
```console
dart tools/gardening/bin/results.dart get failures <group>
```
The groups are shown on the main waterfall: vm,vm-kernel,analyzer...

To find failures for the latest build for a single build bot, use the following:

```console
dart tools/gardening/bin/results.dart get failures <builder_name>
```

If you want to check failures on a specific build on a builder, use the build
number:
```console
dart tools/gardening/bin/results.dart get failures <builder_name> <build_no>
```
Remember, that statuses are tested against status files in your current
repository. As a result, previous errors may not be reported, if the status
files have changed.

You can find failures directly from a result log from a run of test.py. You can
pass the URL linking to a result log, or you can pass the file name of a local
result log on the command line.
```console
dart tools/gardening/bin/results.dart get failures <url>
```

Finally, you can read the result log from a file by passing the file as so:
```console
dart tools/gardening/bin/results.dart get failures <file>
```

#### Updating the status files ####

For now, the tool does not suggest any updates to status files, however, the
tool can help to verify that changes to the status files has been done
correctly.

If a build is failing, the results tool will show which tests failed and how
their results differed from the expectations.

Update the status files appropriately, save the status files and run the tool
again with the same arguments as before. If the changes are correct, the tool
will now report that all test passes.

Note, that changed test files are not rerun, and new status annotations are not
picked up

#### Generating result.log files for my own test runs ####

If you, for some reason, would like to have a result.log output for a test.py
invocation, just pass the flag --write-result-log to test.py. The default
output-directory is `logs`, therefore the file would be written to
`logs/result.log`. Be aware that existing files are overwritten.

To change the output directory, use the `--output-directory` option.

## compare_failures ##
This tool compares a test log of a build step with previous builds. This is
particularly useful to detect changes over time, such as flakiness of failures,
timeouts or to find the build where a test started failing. The tool can be used
for a single builder (vertically) or a builder-group (horizontally and
vertically).

The tool displays the result of the latest 10 runs, which can be modified by the
option `--run-count=X` where `X` is the number of latest results to display.

Some typical use-cases are shown below.

#### Finding failing tests on one builder ####

Say a builder is going red, which means, for a step in that builder, some tests
have not met their expectation. One can then find stdout log of that step and
pass to the tool, as such:

Usage:

```console
dart bin/compare_failures.dart <stdio-url>
```

where `<stdio-url>` is a url for a test log ("https://.../logs/stdio") from the
buildbot. Here is an example:

```console
dart bin/compare_failures.dart https://uberchromegw.corp.google.com/i/client.dart/builders/vm-linux-release-x64-optcounter-threshold-be/builds/6786/steps/checked%20vm%20tests/logs/stdio

Errors for /builders/vm-linux-release-x64-optcounter-threshold-be/builds/6786/steps/checked vm tests :
none-vm-checked release_x64 standalone/io/http_server_response_test
 6786:  Pass       / Crash
 6785:             / -- OK --
 6784:             / -- OK --
 6783:             / -- OK --
 6782:             / -- OK --
 6781:             / -- OK --
 6780:             / -- OK --
 6779:             / -- OK --
 6778:             / -- OK --
 6777:             / -- OK --
 6776:             / -- OK --
```

#### Finding failing tests on a group of builders ####

Sometimes it may be that a group of builders started to turn red. To find if
there is any commonality between failing test, use the following command:

Usage:

```console
dart bin/compare_failures.dart <build-group>
```

where `<build-group>` is the name of the build-group as shown in the console.
Here is an example:

```console
dart bin/compare_failures.dart analyzer

Timeouts for /builders/analyzer-win7-release-be/builds/7106/steps/analyzer unit tests :
none-vm-checked release_x64 pkg/analyzer/test/generated/strong_mode_driver_test
         vm
 7106:   0:00:21.086108
 7105:   0:00:19.712000
 7104:   0:01:00.774077
 7103:   0:00:19.315931
 7102:   0:00:21.380137
 7101:   0:00:16.947695
 7100:   0:00:13.226322
 7099:   0:00:15.951636
 7098:   0:00:19.665966
 7097:   0:00:15.654565
 7096:   0:00:24.775477

Errors for /builders/analyzer-win7-release-be/builds/7106/steps/analyzer unit tests :
none-vm-checked release_x64 pkg/analyzer/test/generated/non_error_resolver_kernel_test
 7106:  Pass Slow  / RuntimeError
 7105:  Pass Slow  / RuntimeError
 7104:  Pass Slow  / RuntimeError
 7103:             / -- OK --
 7102:             / -- OK --
 7101:             / -- OK --
 7100:             / -- OK --
 7099:             / -- OK --
 7098:             / -- OK --
 7097:             / -- OK --
 7096:             / -- OK --

Errors for /builders/analyzer-win7-release-strong-be/builds/3716/steps/analyzer unit tests :
none-vm-checked release_x64 pkg/analyzer/test/generated/non_error_resolver_kernel_test
 3716:  Pass Slow  / RuntimeError
 3715:  Pass Slow  / RuntimeError
 3714:  Pass Slow  / RuntimeError
 3713:             / -- OK --
 3712:             / -- OK --
 3711:             / -- OK --
 3710:             / -- OK --
 3709:             / -- OK --
 3708:             / -- OK --
 3707:             / -- OK --
 3706:             / -- OK --

No errors found for the 52 remaining bots.
```

## status_summary ##
Collects the configurations for all status files in the 'tests' folder that
mention one of the test names given as argument. This is useful to see what the
expectation of a particular test/group of tests have on different
configurations.

Usage:

```console
dart bin/status_summary.dart <test-name1> [<test-name2> ...]
```
where `<test-nameX>` are test names like `language/arithmetic_test` or `function_subtype_typearg2_test`.

#### Finding a summary for a specific test ####
Say that the test `function_subtype_typearg2_test` suddenly started to fail with
a `RuntimeError` on Safari in the dart2js safari builder group. It may be that
similar behavior was already spotted in the dart2js chrome builder group and had
been resolved (the status file was changed). One could then use run the
following command:

```console
dart bin/status_summary.dart function_subtype_typearg2_test

function_subtype_typearg2_test
  file:///usr/local/google/home/mkroghj/dart-sdk/sdk/tests/language/language_dart2js.status
    Crash        [ $compiler == dart2js && $dart2js_with_kernel && $host_checked ] NoSuchMethodError: The method 'hasSubclass' was called on null.
    Crash        [ $compiler == dart2js && $dart2js_with_kernel && $minified ]     NoSuchMethodError: The method 'hasSubclass' was called on null.
  file:///usr/local/google/home/mkroghj/dart-sdk/sdk/tests/language_strong/language_strong.status
    RuntimeError [ $compiler == dartdevc && $runtime != none ]                     Issue 29920
```
The output would then indicate if there are other expectations for the test
`function_subtype_typearg2_test` in other configurations.

## current_summary ##
Collects the test results for all build bots in [buildGroups] (defined in
lib/src/buildbot_data.dart) for tests that mention one of the test names given
as argument.

Usage:

```console
dart bin/current_summary.dart <test-name1> [<test-name2> ...]
```

where `<test-nameX>` are test names like `language/arithmetic_test`.

The results are currently pulled from the second to last build since the last
build might not have completed yet.

#### Finding if a test fails on other configurations ####

Say that a test `function_subtype_typearg2_test` is behaving strange and a few
builders have started to turn red, and you suspect this particular test for
being responsible. Running the following will provide an answer:

```console
dart bin/current_summary.dart function_subtype_typearg2_test

Fetching "/builders/vm-mac-debug-simdbc64-be/builds/-1/steps/vm tests" + 33 more ...
Fetching "/builders/app-linux-debug-x64-be/builds/-1/steps/vm tests" + 2 more ...
Fetching "/builders/vm-kernel-linux-release-x64-be/builds/-1/steps/front-end tests" + 7 more ...
Fetching "/builders/vm-win-debug-ia32-russian-be/builds/-1/steps/vm tests" + 11 more ...
Fetching "/builders/vm-noopt-simarm64-mac-be/builds/-1/steps/test vm" + 9 more ...
Fetching "/builders/vm-linux-product-x64-be/builds/-1/steps/vm tests" + 2 more ...
Fetching "/builders/vm-linux-debug-x64-reload-be/builds/-1/steps/vm tests" + 11 more ...
Fetching "/builders/dart2js-linux-d8-hostchecked-unittest-1-5-be/builds/-1/steps/dart2js-d8 tests" + 54 more ...
Fetching "/builders/dart2js-linux-d8-minified-1-5-be/builds/-1/steps/dart2js-d8 tests" + 79 more ...
Fetching "/builders/dart2js-linux-jsshell-1-4-be/builds/-1/steps/dart2js-jsshell tests" + 39 more ...
Fetching "/builders/analyzer-mac10.11-release-be/builds/-1/steps/analyze tests" + 53 more ...
Fetching "/builders/dart2js-linux-chromeff-1-4-be/builds/-1/steps/dart2js-chrome tests" + 79 more ...
Fetching "/builders/dart2js-linux-drt-1-2-be/builds/-1/steps/dart2js-drt tests" + 39 more ...
Fetching "/builders/dart2js-mac10.11-safari-1-3-be/builds/-1/steps/dart2js-safari tests" + 29 more ...
Fetching "/builders/dart2js-win8-ie11-1-4-be/builds/-1/steps/dart2js ie11 tests" + 111 more ...
Fetching "/builders/pkg-mac10.11-release-be/builds/-1/steps/package unit tests" + 5 more ...

language/function_subtype_typearg2_test
  pass: none-vm                      vm-mac-debug-simdbc64-be/vm tests
  pass: none-vm-checked              vm-mac-debug-simdbc64-be/checked vm tests
  ...
language_2/function_subtype_typearg2_test
  pass: none-vm                      vm-mac-debug-simdbc64-be/vm tests
  pass: none-vm-checked              vm-mac-debug-simdbc64-be/checked vm tests
  pass: none-vm                      vm-mac-release-simdbc64-be/vm tests
  pass: none-vm-checked              vm-mac-release-simdbc64-be/checked vm tests
  pass: none-vm                      vm-linux-debug-x64-be/vm tests
  fail: dart2js-d8                   dart2js-linux-d8-minified-1-5-be/dart2js-with-kernel-d8 tests
  ...
```
The above output has been truncated (shown as ...), to better indicate how the result of a test is shown. One can then grep for failing tests, as so:

```console
dart bin/current_summary.dart --group d8-minified language_2 | grep "fail:" -B 5 -A 5

  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-with-kernel-d8 tests
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-d8-fast-startup tests
  pass: dart2js-d8-checked dart2js-linux-d8-minified-1-5-be/dart2js-d8-fast-startup-checked tests
language_2/function_subtype_typearg2_test
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-d8 tests
  fail: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-with-kernel-d8 tests
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-d8-fast-startup tests
  pass: dart2js-d8-checked dart2js-linux-d8-minified-1-5-be/dart2js-d8-fast-startup-checked tests
language_2/class_codegen_test
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-d8 tests
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-with-kernel-d8 tests
--
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-with-kernel-d8 tests
  pass: dart2js-d8         dart2js-linux-d8-minified-1-5-be/dart2js-d8-fast-startup tests
...
```


## luci ##

Luci is a tool made to query luci/logdog for information. The tool can be used
to find the information about build-bots, build groups, build-details and
commits across builds. There is nothing statically entered in the code files
regarding the bots, thus this tool has all current information.

Usage:

```console
dart bin/luci.dart <command>
```

To find help about each of the sub-tools, use `help` as `<command>`.

#### Find build-bots ####
The primary build-bots are those build-bots shown in the console view. To get
them as list:

```console
dart bin/luci.dart --build-bots

ddc-win-release-stable
pkg-linux-release-dev
dart2js-mac10.11-safari-3-3-be
vm-mac-debug-x64-be
vm-win-debug-ia32-russian-stable
vm-win-debug-ia32-be
dart2js-linux-drt-1-2-stable
dart-sdk-linux-be
pkg-win7-release-stable
vm-kernel-mac-release-x64-be
dart2js-linux-d8-hostchecked-unittest-5-5-stable
...
```

Similarly, all build bots can be found by:
```console
dart bin/luci.dart --build-bots-all
```

#### Find build-groups ####

The build groups can be shown as such:

```console
dart bin/luci.dart --build-groups

safari
vm
dart-sdk
vm-kernel
ddc
vm-product
analyzer
vm-misc
vm-reload
dart2js-jsshell
vm-app
pub-pkg
chrome
vm-precomp
dart2js-windows
dart2js-d8-minified
dart2js-linux
dart2js-d8-hostchecked
misc
```

This should match the view of the console.

#### Find builders in group ####

The tool can show all the builders in a specific group:

```console
dart bin/luci.dart --builders-in-group <group>
```

where `<group>` is one of the groups shown above.

To find all the builders of the `chrome` builder group, use the following:

```console
dart bin/luci.dart --builders-in-group chrome

dart2js-mac10.11-chrome-be
dart2js-linux-drt-1-2-be
dart2js-linux-drt-2-2-be
dart2js-linux-drt-csp-minified-be
```

#### Find detailed information about a build-bot ####

To find detailed information about a build on a build-bot, the following command
can be used. This essentially gives a view similar to the html-page that shows
information about a specific build, since it will give information about the
steps, files and commits.

Usage:

```console
dart bin/luci.dart --build-details <builder> <number>
```

where `<builder>` is the name of the builder and `<number>` is the build number.
It can be used in the following way:

```console
dart bin/luci.dart --build-details vm-linux-debug-x64-reload-be 2971
```

#### Builds with commit ####

The buildbot assigns a build number to each build on a builder.  To find the
build numbers corresponding to a specific commit, use the --builds-with-commit
option as follows:

Usage:

```console
dart bin/luci.dart --builds-with-commit <commit_hash>
```

where `<commit_hash>` is the full hash of the specific commit. Since all bots
have to be checked, and one normally wants to investigate the latest commits,
the cache is only 15 minutes.

To run it, fx, on the hash `4d55a6779e6430c382bf0e0e4b8c0d61bee5c92c`, one can
run the following:

```console
dart bin/luci.dart --builds-with-commit 4d55a6779e6430c382bf0e0e4b8c0d61bee5c92c
2017-09-18 14:42:04.977786 Info: Sorry - this is going to take some time, since we have to look into all 25 latest builds for all bots for client client.dart.
Subsequent queries run faster if caching is not turned off...
The commit '4d55a6779e6430c382bf0e0e4b8c0d61bee5c92c is used in the following builds:
dart2js-mac10.11-safari-3-3-be: #6821	https://luci-milo.appspot.com/buildbot/client.dart/dart2js-mac10.11-safari-3-3-be/6821
vm-mac-debug-x64-be: #13007	https://luci-milo.appspot.com/buildbot/client.dart/vm-mac-debug-x64-be/13007
vm-win-debug-ia32-be: #5270	https://luci-milo.appspot.com/buildbot/client.dart/vm-win-debug-ia32-be/5270
dart-sdk-linux-be: #15544	https://luci-milo.appspot.com/buildbot/client.dart/dart-sdk-linux-be/15544
vm-kernel-mac-release-x64-be: #1441	https://luci-milo.appspot.com/buildbot/client.dart/vm-kernel-mac-release-x64-be/1441
ddc-mac-release-be: #972	https://luci-milo.appspot.com/buildbot/client.dart/ddc-mac-release-be/972
vm-win-product-x64-be: #8433	https://luci-milo.appspot.com/buildbot/client.dart/vm-win-product-x64-be/8433
analyze-linux-be: #3696	https://luci-milo.appspot.com/buildbot/client.dart/analyze-linux-be/3696
vm-win-debug-x64-be: #5096	https://luci-milo.appspot.com/buildbot/client.dart/vm-win-debug-x64-be/5096
vm-win-debug-ia32-russian-be: #3836	https://luci-milo.appspot.com/buildbot/client.dart/vm-win-debug-ia32-russian-be/3836
dart2js-mac10.11-safari-1-3-be: #6730	https://luci-milo.appspot.com/buildbot/client.dart/dart2js-mac10.11-safari-1-3-be/6730
...
```


<!--
#### find_timeouts ####
Scans past `dart2js-windows` test steps for timeouts and reports the
frequency of each test that has timed out.

Usage:
```console
dart bin/find_timeouts.dart [<count>]
```

where `<count>` is the number past build that are scanned.   -->
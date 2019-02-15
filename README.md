# Dart2js Info

This package contains libraries and tools you can use to process info
files produced when running dart2js with `--dump-info`.

The info files contain data about each element included in the output of your
program. The data includes information such as:

  * the size that each function adds to the `.dart.js` output,
  * dependencies between functions,
  * how the code is clustered when using deferred libraries, and
  * the declared and inferred type of each function argument.

All of this information can help you understand why some piece of code is
included in your compiled application, and how far was dart2js able to
understand your code. This data can help you make changes to improve the quality
and size of your framework or app.

This package focuses on gathering libraries and tools that summarize all of that
information. Bear in mind that even with all these tools, it is not trivial to
isolate code-size issues. We just hope that these tools make things a bit
easier.

## Status

[![Build Status](https://travis-ci.org/dart-lang/dart2js_info.svg)](https://travis-ci.org/dart-lang/dart2js_info)

Currently, most tools available here can be used to analyze code-size and
attribution of code-size to different parts of your app. With time, we hope to
add more data to the info files, and include better tools to help
understand the results of type inference.

This package is still in flux and we might make breaking changes at any time.
Our current goal is not to provide a stable API, we mainly want to expose the
functionality and iterate on it.  We recommend that you pin a specific version
of this package and update when needed.

## Tools

All tools are provided as commands of a single command-line interface. To
install:
```console
pub global activate dart2js_info
```

To run a tool, then run:
```console
dart2js_info <command> [arguments]
```

There is a short help available on the tool, and more details are provided
below.

## Format

There are several formats of info files. Dart2js today produces a JSON format,
but very soon will switch to produce a binary format by default.

## Info API

This package also exposes libraries to parse and represent the information from
the info files. If there is data that is stored in the info files but not
exposed by one of our tools, you may be able to use the info APIs to quickly put
together your own tool.

[AllInfo][AllInfo] exposes a Dart representation of all of the collected
information. There are deserialization libraries in this package to decode any
info file produced by the `dart2js` `--dump-info` option. See
`lib/binary_serialization.dart` and `lib/json_info_codec.dart` to find the
binary and JSON decoders respectively. For convenience,
`package:dart2js_info/src/io.dart` also exposes a helper method that can choose,
depending on the extension of the info file, whether to deserialize it using the
binary or JSON decoder.  For example:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';

main(args) async {
  var infoPath = args[0];
  var info = await infoFromFile(infoPath);
  ...
}
```

## Available tools

The following tools are a available today:

  * [`code_deps`][code_deps]: simple tool that can answer queries about the
    dependency between functions and fields in your program. Currently it only
    supports the `some_path` query, which shows a dependency path from one
    function to another.
    
  * [`diff`][diff]: a tool that diffs two info files and reports which
    program elements have been added, removed, or changed size. This also
    tells which elements are no longer deferred or have become deferred.

  * [`library_size`][library_size]: a tool that shows how much code was
    attributed to each library. This tool is configurable so it can group data
    in many ways (e.g. to tally together all libraries that belong to a package,
    or all libraries that match certain name pattern).

  * [`deferred_check`][deferred_check]: a tool that verifies that code
    was split into deferred parts as expected. This tool takes a specification
    of the expected layout of code into deferred parts, and checks that the
    output from `dart2js` meets the specification.

  * [`deferred_size`][deferred_size]: a tool that gives a breakdown of
    the sizes of the deferred parts of the program. This can show how much of
    your total code size can be loaded deferred.

  * [`deferred_layout`][deferred_layout]: a tool that reports which
    code is included on each output unit.

  * [`function_size`][function_size]: a tool that shows how much
    code was attributed to each function. This tool also uses dependency
    information to compute dominance and reachability data. This information can
    sometimes help determine how much savings could come if the function was not
    included in the program.

  * [`coverage_server`][coverage_server] and [`coverage_analysis`][coverage_analysis]:
    dart2js has an experimental feature to gather coverage data of your
    application. The `coverage_log_server` can record this data, and
    `live_code_size_analysis` can correlate that with the info file, so you
    determine why code that is not used is being included in your app.

  * [`convert`][convert]: a tool that converts info files from one format to
    another. Accepted inputs are JSON or the internal binary form, outputs can
    be JSON, backward-compatible JSON, binary, or protobuf schema (as defined in
    `info.proto`).

  * [`show`][show]: a tool that dumps info files in a readable text format.

Next we describe in detail how to use each of these tools.

### Code deps tool

This command-line tool can be used to query for code dependencies. Currently
this tool only supports the `some_path` query, which gives you the shortest path
for how one function depends on another.

Run this tool as follows:
```console
# activate is only needed once to install the dart2js_info tool
$ pub global activate dart2js_info
$ dart2js_info code_deps some_path out.js.info.data main foo
```

The arguments to the query are regular expressions that can be used to
select a single element in your program. If your regular expression is too
general and has more than one match, this tool will pick
the first match and ignore the rest. Regular expressions are matched against
a fully qualified element name, which includes the library and class name
(if any) that contains it. A typical qualified name is of this form:

    libraryName::ClassName.elementName

If the name of a function your are looking for is unique enough, it might be
sufficient to just write that name as your regular expression.

### Diff tool

This command-line tool shows a diff between two info files. It can be run
as follows:

```console
$ pub global activate dart2js_info # only needed once
$ dart2js_info diff old.js.info.data new.js.info.data [--summary]
```

The tool gives a breakdown of the difference between the two info files.
Here's an example output:

```
total_size_difference -2688
total_added 0
total_removed 2321
total_size_changed -203
total_became_deferred 0
total_no_longer_deferred 0

ADDED (0 bytes)
========================================================================

REMOVED (2321 bytes)
========================================================================
dart:_js_helper::getRuntimeTypeString: 488 bytes
dart:_js_helper::substitute: 479 bytes
dart:_js_helper::TypeImpl.toString: 421 bytes
dart:_js_helper::computeSignature: 204 bytes
dart:_js_helper::getRuntimeTypeArguments: 181 bytes
dart:_js_helper::extractFunctionTypeObjectFrom: 171 bytes
dart:_js_helper::getTypeArgumentByIndex: 147 bytes
dart:_js_helper::runtimeTypeToString: 136 bytes
dart:_js_helper::setRuntimeTypeInfo: 94 bytes
dart:core::Object.runtimeType: 0 bytes
dart:_js_helper::getRawRuntimeType: 0 bytes
dart:_js_helper::invoke: 0 bytes
dart:_js_helper::invokeOn: 0 bytes
dart:_js_helper::getField: 0 bytes
dart:_js_helper::getClassName: 0 bytes
dart:_js_helper::getRuntimeType: 0 bytes
dart:_js_helper::TypeImpl.TypeImpl: 0 bytes

CHANGED SIZE (-203 bytes)
========================================================================
dart:_interceptors::JSUnmodifiableArray: -3 bytes
dart:core::List: -3 bytes
dart:_interceptors::ArrayIterator: -4 bytes
dart:_js_helper::TypeImpl._typeName: -10 bytes
dart:_js_helper::TypeImpl._unmangledName: -15 bytes
dart:_js_names::: -30 bytes
dart:_js_names::extractKeys: -30 bytes
dart:core::StringBuffer: -40 bytes
dart:core::StringBuffer._writeAll: -40 bytes
dart:core::: -43 bytes
dart:_interceptors::JSArray.+: -63 bytes
dart:_interceptors::JSArray: -66 bytes
dart:_interceptors::: -73 bytes
dart:_js_helper::TypeImpl: -481 bytes
dart:_js_helper::: -2445 bytes

BECAME DEFERRED (0 bytes)
========================================================================

NO LONGER DEFERRED (0 bytes)
========================================================================

```

You can also pass `--summary` to only show the summary section.

### Library size split tool

This command-line tool shows the size distribution of generated code among
libraries. It can be run as follows:

```console
$ pub global activate dart2js_info # only needed once
$ dart2js_info library_size out.js.info.data
```


Libraries can be grouped using regular expressions. You can
specify what regular expressions to use by providing a `grouping.yaml` file:

```console
$ dart2js_info library_size out.js.info.data grouping.yaml
```

The format of the `grouping.yaml` file is as follows:

```yaml
groups:
- { regexp: "package:(foo)/*.dart", name: "group name 1", cluster: 2}
- { regexp: "dart:.*",              name: "group name 2", cluster: 3}
```

The file should include a single key `groups` containing a list of group
specifications.  Each group is specified by a map of 3 entries:

  * `regexp` (required): a regexp used to match entries that belong to the
  group.

  * `name` (optional): the name given to this group in the output table. If
  omitted, the name is derived from the regexp as the match's group(1) or
  group(0) if no group was defined. When names are omitted the group
  specification implicitly defines several groups, one per observed name.

  * `cluster` (optional): a clustering index for how data is shown in a table.
  Groups with higher cluster indices are shown later in the table after a
  dividing line. If missing, the cluster index defaults to 0.

Here is an example configuration, with comments about what each entry does:

```yaml
groups:
# This group shows the total size for all libraries that were loaded from
# file:// urls, it is shown in cluster #2, which happens to be the last
# cluster in this example before the totals are shown:
- name: "Loose files"
  regexp: "file://.*"
  cluster: 2

# This group shows the total size of all code loaded from packages:
- { name: "All packages", regexp: "package:.*", cluster: 2}

# This group shows the total size of all code loaded from core libraries:
- { name: "Core libs", regexp: "dart:.*", cluster: 2}

# This group shows the total size of all libraries in a single package. Here
# we omitted the `name` entry, instead we extract it from the regexp
# directly.  In this case, the name will be the package-name portion of the
# package-url (determined by group(1) of the regexp).
- { regexp: "package:([^/]*)", cluster: 1}

# The next two groups match the entire library url as the name of the group.
- regexp: "package:.*"
- regexp: "dart:.*"

# If your code lives under /my/project/dir, this will match any file loaded
from a file:// url, and we use as a name the relative path to it.
- regexp: "file:///my/project/dir/(.*)"
```

Regardless of the grouping configuration, the tool will display the total code
size attributed of all libraries, constants, and the program size.

**Note**: eventually you should expect all numbers to add up to the program
size. Currently dart2js's `--dump-info` is not complete, so numbers for
bootstrapping code and lazy static initializers are missing.

### Deferred library verification

This tool checks that the output from dart2js meets a given specification,
given in a YAML file. It can be run as follows:

```console
$ pub global activate dart2js_info # only needed once
$ dart2js_info deferred_check out.js.info.data manifest.yaml
```

The format of the YAML file is:

```yaml
main:
  include:
    - some_package
    - other_package
  exclude:
    - some_other_package

foo:
  include:
    - foo
    - bar

baz:
  include:
    - baz
    - quux
  exclude:
    - zardoz
```

The YAML file consists of a list of declarations, one for each deferred
part expected in the output. At least one of these parts must be named
"main"; this is the main part that contains the program entrypoint. Each
top-level part contains a list of package names that are expected to be
contained in that part, a list of package names that are expected to be in
another part, or both. For instance, in the example YAML above the part named
"baz" is expected to contain the packages "baz" and "quux" and exclude the
package "zardoz".

The names for parts given in the specification YAML file (besides "main")
are the same as the name given to the deferred import in the dart file. For
instance, if you have `import 'package:foo/bar.dart' deferred as baz;` in your
dart file, then the corresponding name in the specification file is 'baz'.

### Deferred library size tool

This tool gives a breakdown of all of the deferred code in the program by size.
It can show how much of the total code size is deferred. It can be run as
follows:

```console
pub global activate dart2js_info # only needed once
dart2js_info deferred_size out.js.info.data
```

The tool will output a table listing all of the deferred imports in the program
as well as the "main" chunk, which is not deferred. The output looks like:

```
Size by library
------------------------------------------------
main                                    12345678
foo                                      7654321
bar                                      1234567
------------------------------------------------
Main chunk size                         12345678
Deferred code size                       8888888
Percent of code deferred                  41.86%
```

### Deferred library layout tool

This tool reports which code is included in each output unit.  It can be run as
follows:

```console
$ pub global activate dart2js_info # only needed once
$ dart2js_info deferred_layout out.js.info.data
```

The tool will output a table listing all of the deferred output units or chunks,
for each unit it will list the set of libraries that contribute code to this
unit. If a library contributes to more than one output unit, the tool lists
which elements are in one or another output unit. For example, the output might
look like this:

```
Output unit main:
  loaded by default
  contains:
     - hello_world.dart
     - dart:core
     ...

Output unit 2:
  loaded by importing: [b]
  contains:
     - c.dart:
       - function d
     - b.dart

Output unit 1:
  loaded by importing: [a]
  contains:
     - c.dart:
       - function c
     - a.dart
```

In this example, all the code of `b.dart` after tree-shaking was included in the
output unit 2, but `c.dart` was split between output unit 1 and output unit 2.

### Function size analysis tool

This command-line tool presents how much each function contributes to the total
code of your application.  We use dependency information to compute dominance
and reachability data as well.

When you run:
```console
$ pub global activate dart2js_info # only needed once
$ dart2js_info function_size out.js.info.data
```

the tool produces a table output with lots of entries. Here is an example entry
with the corresponding table header:
```
 --- Results per element (field or function) ---
    element size     dominated size     reachable size Element identifier
    ...
     275   0.01%     283426  13.97%    1506543  74.28% some.library.name::ClassName.myMethodName
```

Such entry means that the function `myMethodName` uses 275 bytes, which is 0.01%
of the application. That function however calls other functions, which
transitively can include up to 74.28% of the application size. Of all those
reachable functions, some of them are reachable from other parts of the program,
but a subset are dominated by `myMethodName`, that is, other parts of the
program starting from `main` would first go through `myMethodName` before
reaching those functions. In this example, that subset is 13.97% of the
application size. This means that if you somehow can remove your dependency on
`myMethodName`, you will save at least that 13.97%, and possibly some more from
the reachable size, but how much of that we are not certain.

### Coverage tools

Coverage information requires a bit more setup and work to get them running. The
steps are as follows:

  * Compile an app with dart2js using `--dump-info` and
    `--experiment-call-instrumentation`

```console
$ dart2js --dump-info --experiment-call-instrumentation main.dart
```

  The flag only works dart2js version 2.2.0 or newer.

  * Launch the coverage server tool to serve up the JS code of your app:

```console
$ dart2js_info coverage_server main.dart.js
```

  * (optional) If you have a complex application setup, you may need to serve an
    html file or integrate your application server to proxy to the log server
    any GET request for the .dart.js file and /coverage POST requests that send
    coverage data.

  * Load your app and use it to exercise the entire code.

  * Shut down the coverage server (Ctrl-C). This will emit a file named
    `mail.dart.js.coverage.json`

  * Finally, run the live code analysis tool given it both the info and
    coverage json files:

```console
$ dart2js_info coverage_analysis main.dart.info.data main.dart.coverage.json
```

## Code location, features and bugs

This package is developed in [github][repo].  Please file feature requests and
bugs at the [issue tracker][tracker].

[repo]: https://github.com/dart-lang/dart2js_info/
[tracker]: https://github.com/dart-lang/dart2js_info/issues
[code_deps]: https://github.com/dart-lang/dart2js_info/blob/master/bin/code_deps.dart
[diff]: https://github.com/dart-lang/dart2js_info/blob/master/bin/diff.dart
[library_size]: https://github.com/dart-lang/dart2js_info/blob/master/bin/library_size_split.dart
[deferred_check]: https://github.com/dart-lang/dart2js_info/blob/master/bin/deferred_library_check.dart
[deferred_size]: https://github.com/dart-lang/dart2js_info/blob/master/bin/deferred_library_size.dart
[deferred_layout]: https://github.com/dart-lang/dart2js_info/blob/master/bin/deferred_library_layout.dart
[coverage_server]: https://github.com/dart-lang/dart2js_info/blob/master/bin/coverage_log_server.dart
[coverage_analysis]: https://github.com/dart-lang/dart2js_info/blob/master/bin/live_code_size_analysis.dart
[function_size]: https://github.com/dart-lang/dart2js_info/blob/master/bin/function_size_analysis.dart
[AllInfo]: http://dart-lang.github.io/dart2js_info/doc/api/dart2js_info.info/AllInfo-class.html
[convert]: https://github.com/dart-lang/dart2js_info/blob/master/bin/convert.dart
[show]: https://github.com/dart-lang/dart2js_info/blob/master/bin/text_print.dart

# Dart2js Info

This package contains libraries and tools you can use to process `.info.json`
files, which are produced when running dart2js with `--dump-info`.

The `.info.json` files contain data about each element included in
the output of your program. The data includes information such as:

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
earier.

## Status

Currently, most tools available here can be used to analyze code-size and
attibution of code-size to different parts of your app. With time, we hope to
add more data to the `.info.json` files, and include better tools to help
understand the results of type inference.

This package is still in flux and we might make breaking changes at any time.
Our current goal is not to provide a stable API, we mainly want to expose the
functionality and iterate on it.  We recommend that you pin a specific version
of this package and update when needed.

## Info API

[dumped info][AllInfo] exposes a Dart representation of the `.info.json` files.
You can parse the information using `AllInfo.parseFromJson`. For example:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';

main(args) {
  var infoPath = args[0];
  var json = JSON.decode(new File(infoPath).readAsStringSync());
  var info = AllInfo.parseFromJson(json);
  ...
```


## Available tools

The following tools are a available today:

  * [`code_deps.dart`][code_deps]: simple tool that can answer queries about the
    dependency between functions and fields in your program. Currently it only
    supports the `some_path` query, which shows a dependency path from one
    function to another.

  * [`library_size_split`][lib_split]: a tool that shows how much code was
    attributed to each library. This tool is configurable so it can group data
    in many ways (e.g. to tally together all libraries that belong to a package,
    or all libraries that match certain name pattern).

  * [`function_size_analysis`][function_analysis]: a tool that shows how much
    code was attributed to each function. This tool also uses depedency
    information to compute dominance and reachability data. This information can
    sometimes help determine how much savings could come if the function was not
    included in the program.

  * [`coverage_log_server`][coverage] and [`live_code_size_analysis`][live]:
    dart2js has an experimental feature to gather coverage data of your
    application. The `coverage_log_server` can record this data, and
    `live_code_size_analysis` can correlate that with the `.info.json`, so you
    determine why code that is not used is being included in your app.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/dart2js_info/issues
[code_deps]: https://github.com/dart-lang/dart2js_info/blob/master/bin/code_deps.dart
[lib_split]: https://github.com/dart-lang/dart2js_info/blob/master/bin/library_size_split.dart
[coverage]: https://github.com/dart-lang/dart2js_info/blob/master/bin/coverage_log_server.dart
[live]: https://github.com/dart-lang/dart2js_info/blob/master/bin/live_code_size_analsysis.dart
[function_analysis]: https://github.com/dart-lang/dart2js_info/blob/master/bin/function_size_analysis.dart
[AllInfo]: https://github.com/dart-lang/dart2js_info/blob/master/lib/info.dart

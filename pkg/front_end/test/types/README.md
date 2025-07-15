<!--
  -- Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
  -- for details. All rights reserved. Use of this source code is governed by a
  -- BSD-style license that can be found in the LICENSE file.
  -->

# Type Relation Test and Benchmarks

This directory contains tests and benchmarks of type relations, for example,
isSubtypeOf.

## Create or Update Benchmark Data

To collect new data for a benchmark, follow these steps:

1. Identify the program that the benchmark is based on, for example,
`pkg/compiler/lib/src/dart2js.dart`.

2. Modify `pkg/kernel/lib/src/types.dart` as described in the method
`SubtypeTester._collect_performSubtypeCheck`.

3. Compile the program using CFE, for example:

```shell
$ ./sdk/bin/dart pkg/front_end/tool/compile.dart pkg/compiler/lib/src/dart2js.dart
```

This produces a file named `type_checks.json` in the current directory.

4. Rename the file and compress it using `gzip`:

```shell
$ mv type_checks.json dart2js.json
$ gzip dart2js.json
```

This produces a file named `dart2js.json.gz`.

5. Move the file to the directory `pkg/front_end/test/fasta/types/benchmark_data/` in the Dart SDK checkout:

```shell
$ mv dart2js.json.gz pkg/front_end/test/fasta/types/benchmark_data/
```

6. Run the corresponding test:

```shell
$ python3 tools/test.py -n cfe-unittest-asserts-release-mac --detect-host pkg/front_end/test/types/dart2js_benchmark_test
```

Note: this will run the test with the locally updated benchmark data. Fresh checkouts of the Dart SDK will not have the updated data.
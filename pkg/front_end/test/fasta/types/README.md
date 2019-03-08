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
`pkg/compiler/bin/dart2js.dart`.

2. Modify `pkg/kernel/lib/type_environment.dart` as described in the method
`SubtypeTester._collect_isSubtypeOf`.

3. Compile the program using Fasta, for example:

    ./sdk/bin/dart pkg/front_end/tool/_fasta/compile.dart pkg/compiler/bin/dart2js.dart

4. This produces a file named `type_checks.json` in the current directory.

5. Compress the file using `gzip`.
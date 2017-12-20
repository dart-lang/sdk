// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_dynamic_test;

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/fasta_codes.dart' show LocatedMessage;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show FastaDelta, IncrementalCompiler;

import 'package:front_end/src/fasta/severity.dart' show Severity;

void problemHandler(LocatedMessage message, Severity severity, String formatted,
    int line, int column) {
  throw "Unexpected message: $formatted";
}

test() async {
  final CompilerOptions optionBuilder = new CompilerOptions()
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..packagesFileUri = Uri.base.resolve(".packages")
    ..strongMode = false
    ..onProblem = problemHandler;

  final ProcessedOptions options =
      new ProcessedOptions(optionBuilder, false, []);

  IncrementalCompiler compiler =
      new IncrementalCompiler(new CompilerContext(options));

  Uri helloDart = Uri.base.resolve("pkg/front_end/testcases/hello.dart");

  FastaDelta delta = await compiler.computeDelta(entryPoint: helloDart);

  // Expect that the new program contains at least the following libraries:
  // dart:core, dart:async, and hello.dart.
  Expect.isTrue(delta.newProgram.libraries.length > 2);

  compiler.invalidate(helloDart);

  delta = await compiler.computeDelta(entryPoint: helloDart);
  // Expect that the new program contains exactly hello.dart
  Expect.isTrue(delta.newProgram.libraries.length == 1);
}

void main() {
  asyncTest(test);
}

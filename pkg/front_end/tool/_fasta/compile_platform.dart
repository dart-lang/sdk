// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show exitCode;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/tool/compile_platform.dart' show compilePlatform;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future main(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    try {
      await compilePlatform(arguments);
    } on deprecated_InputError catch (e) {
      exitCode = 1;
      CompilerContext.runWithDefaultOptions(
          (c) => c.report(deprecated_InputError.toMessage(e), Severity.error));
      return null;
    }
  }
}

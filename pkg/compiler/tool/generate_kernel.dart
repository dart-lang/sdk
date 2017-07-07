// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper to run fasta with the right target configuration to build dart2js
/// applications using the dart2js platform libraries.
// TODO(sigmund): delete this file once we can configure fasta directly on the
// command line.
library compiler.tool.generate_kernel;

import 'dart:io' show exitCode;

import 'package:front_end/src/fasta/compiler_command_line.dart'
    show CompilerCommandLine;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/errors.dart' show InputError;
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:compiler/src/kernel/fasta_support.dart' show Dart2jsCompileTask;

main(List<String> arguments) async {
  try {
    await CompilerCommandLine.withGlobalOptions("generate_kernel", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      var task =
          new Dart2jsCompileTask(c, new Ticker(isVerbose: c.options.verbose));
      await task.compile();
    });
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

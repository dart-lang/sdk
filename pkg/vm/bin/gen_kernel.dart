// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/args.dart' show ArgParser;
import 'package:kernel/text/ast_to_text.dart'
    show globalDebuggingNames, NameSystem;
import 'package:kernel/src/tool/batch_util.dart' as batch_util;
import 'package:vm/kernel_front_end.dart'
    show
        createCompilerArgParser,
        runCompiler,
        successExitCode,
        compileTimeErrorExitCode,
        badUsageExitCode;

final ArgParser _argParser = createCompilerArgParser();

final String _usage = '''
Usage: dart pkg/vm/bin/gen_kernel.dart --platform vm_platform_strong.dill [options] input.dart
Compiles Dart sources to a kernel binary file for Dart VM.

Options:
${_argParser.usage}
''';

main(List<String> arguments) async {
  if (arguments.isNotEmpty && arguments.last == '--batch') {
    await runBatchModeCompiler();
  } else {
    io.exitCode = await compile(arguments);
  }
}

Future<int> compile(List<String> arguments) async {
  return runCompiler(_argParser.parse(arguments), _usage);
}

Future runBatchModeCompiler() async {
  await batch_util.runBatch((List<String> arguments) async {
    // TODO(kustermann): Once we know where the new IKG api is and how to use
    // it, we should take advantage of it.
    //
    // Important things to note:
    //
    //   * Our global transformations must never alter the AST structures which
    //     the statefull IKG generator keeps across compilations.
    //     => We need to make our own copy.
    //
    //   * We must ensure the stateful IKG generator keeps giving us all the
    //     compile-time errors, warnings, hints for every compilation and we
    //     report the compilation result accordingly.
    //
    final exitCode = await compile(arguments);

    // Re-create global NameSystem to avoid accumulating garbage.
    globalDebuggingNames = new NameSystem();

    switch (exitCode) {
      case successExitCode:
        return batch_util.CompilerOutcome.Ok;
      case compileTimeErrorExitCode:
      case badUsageExitCode:
        return batch_util.CompilerOutcome.Fail;
      default:
        throw 'Could not obtain correct exit code from compiler.';
    }
  });
}

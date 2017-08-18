// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.run;

import 'dart:async' show Future;

import 'dart:io' show stdout, exit, exitCode;

import 'package:testing/testing.dart' show StdioProcess;

import 'testing/patched_sdk_location.dart'
    show computeDartVm, computePatchedSdk;

import 'compiler_context.dart' show CompilerContext;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'fasta.dart' show CompileTask;

import 'deprecated_problems.dart' show deprecated_InputError;

import 'severity.dart' show Severity;

import 'ticker.dart' show Ticker;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

mainEntryPoint(List<String> arguments) async {
  Uri uri;
  for (int i = 0; i < iterations; i++) {
    await CompilerCommandLine.withGlobalOptions("run", arguments, false,
        (CompilerContext c, List<String> restArguments) async {
      var input = Uri.base.resolve(restArguments[0]);
      c.options.inputs.add(input);
      if (i > 0) {
        print("\n");
      }
      try {
        CompileTask task =
            new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
        uri = await task.compile();
      } on deprecated_InputError catch (e) {
        CompilerContext.current
            .report(deprecated_InputError.toMessage(e), Severity.error);
        exit(1);
      }
      if (exitCode != 0) exit(exitCode);
      if (i + 1 == iterations) {
        exit(await run(uri, c, restArguments));
      }
    });
  }
}

Future<int> run(Uri uri, CompilerContext c, List<String> allArguments) async {
  Uri sdk = await computePatchedSdk();
  Uri dartVm = computeDartVm(sdk);
  List<String> arguments = <String>["${uri.toFilePath()}"]
    ..addAll(allArguments.skip(1));
  if (c.options.verbose) {
    print("Running ${dartVm.toFilePath()} ${arguments.join(' ')}");
  }
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), arguments);
  stdout.write(result.output);
  return result.exitCode;
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_compile;

import 'dart:async' show Future;

import 'dart:io' show exitCode;

import '../compiler_command_line.dart' show CompilerCommandLine;

import '../compiler_context.dart' show CompilerContext;

import '../ticker.dart' show Ticker;

import '../fasta.dart' show CompileTask;

import '../errors.dart' show InputError;

import 'analyzer_target.dart' show AnalyzerTarget;

import '../dill/dill_target.dart' show DillTarget;

import '../translate_uri.dart' show TranslateUri;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future<Uri> compile(List<String> arguments) async {
  try {
    return await CompilerCommandLine.withGlobalOptions("kompile", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Compiling via analyzer: ${arguments.join(' ')}");
      }
      AnalyzerCompileTask task =
          new AnalyzerCompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.compile();
    });
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

class AnalyzerCompileTask extends CompileTask {
  AnalyzerCompileTask(CompilerContext c, Ticker ticker) : super(c, ticker);

  AnalyzerTarget createKernelTarget(
      DillTarget dillTarget, TranslateUri uriTranslator) {
    return new AnalyzerTarget(dillTarget, uriTranslator, c.uriToSource);
  }
}

mainEntryPoint(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await compile(arguments);
  }
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_compile;

import 'dart:async' show Future;

import 'dart:io' show exitCode;

import 'package:analyzer/src/fasta/analyzer_target.dart' show AnalyzerTarget;

import 'package:front_end/src/fasta/compiler_command_line.dart'
    show CompilerCommandLine;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/fasta.dart' show CompileTask;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

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
  } on deprecated_InputError catch (e) {
    exitCode = 1;
    print(e.deprecated_format());
    return null;
  }
}

class AnalyzerCompileTask extends CompileTask {
  AnalyzerCompileTask(CompilerContext c, Ticker ticker) : super(c, ticker);

  @override
  AnalyzerTarget createKernelTarget(
      DillTarget dillTarget, UriTranslator uriTranslator, bool strongMode) {
    return new AnalyzerTarget(
        dillTarget, uriTranslator, strongMode, c.uriToSource);
  }
}

main(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await compile(arguments);
  }
}

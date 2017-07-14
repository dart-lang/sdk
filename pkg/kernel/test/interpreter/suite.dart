// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'dart:io' show File;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, runMe;

import 'package:kernel/ast.dart' show Program, Library;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show runDiff, Compile, CompileContext;

import 'package:kernel/interpreter/interpreter.dart';

const String STRONG_MODE = " strong mode ";

class InterpreterContext extends ChainContext implements CompileContext {
  final bool strongMode;

  final List<Step> steps;

  InterpreterContext(this.strongMode)
      : steps = <Step>[
          const Compile(),
          const Interpret(),
          const MatchLogExpectation(".expect"),
        ];

  static Future<InterpreterContext> create(
      Chain suite, Map<String, String> environment) async {
    bool strongMode = environment.containsKey(STRONG_MODE);
    return new InterpreterContext(strongMode);
  }
}

class Interpret extends Step<Program, EvaluationLog, InterpreterContext> {
  const Interpret();

  String get name => "interpret";

  Future<Result<EvaluationLog>> run(Program program, _) async {
    Library library = program.libraries
        .firstWhere((Library library) => library.importUri.scheme != "dart");
    Uri uri = library.importUri;

    StringBuffer buffer = new StringBuffer();
    log.onRecord.listen((LogRecord rec) => buffer.write(rec.message));
    try {
      new Interpreter(program).run();
    } catch (e, s) {
      return crash(e, s);
    }

    return pass(new EvaluationLog(uri, "$buffer"));
  }
}

class MatchLogExpectation extends Step<EvaluationLog, int, InterpreterContext> {
  final String suffix;

  String get name => "match log expectation";

  const MatchLogExpectation(this.suffix);

  Future<Result<int>> run(EvaluationLog result, _) async {
    Uri uri = result.uri;

    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != result.log.trim()) {
        String diff = await runDiff(expectedFile.uri, result.log);
        return fail(null, "$uri doesn't match ${expectedFile.uri}\n$diff");
      } else {
        return pass(0);
      }
    }
    return fail(
        null, """Please create file ${expectedFile.path} with this content:
        ${result.log}""");
  }
}

class EvaluationLog {
  /// Evaluated program uri.
  final Uri uri;

  /// Evaluated program log.
  final String log;

  EvaluationLog(this.uri, this.log);
}

main(List<String> arguments) =>
    runMe(arguments, InterpreterContext.create, "testing.json");

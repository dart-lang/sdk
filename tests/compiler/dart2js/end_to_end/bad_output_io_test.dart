// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// TODO(johnniwinther): Port this test to use '--use-kernel'.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.bad_output_io;

import 'dart:async' show Future;
import 'dart:io' show exit;
import 'package:expect/expect.dart';

import 'package:compiler/compiler.dart' show Diagnostic;
import 'package:compiler/compiler_new.dart'
    show
        CompilationResult,
        CompilerDiagnostics,
        CompilerInput,
        CompilerOutput,
        OutputType;
import 'package:compiler/src/dart2js.dart'
    show exitFunc, compileFunc, compile, diagnosticHandler;
import 'package:compiler/src/source_file_provider.dart'
    show FormattingDiagnosticHandler;

import 'package:compiler/src/options.dart' show CompilerOptions;

class CollectingFormattingDiagnosticHandler
    implements FormattingDiagnosticHandler {
  @override
  final provider = null;
  @override
  bool showWarnings = true;
  @override
  bool showHints = true;
  @override
  bool verbose = true;
  @override
  bool isAborting = false;
  @override
  bool enableColors = false;
  @override
  bool throwOnError = false;
  @override
  bool autoReadFileUri = false;
  @override
  var lastKind = null;

  @override
  final int FATAL = 0;
  @override
  final int INFO = 1;

  final messages = [];

  @override
  void info(var message, [kind = Diagnostic.VERBOSE_INFO]) {
    messages.add([message, kind]);
  }

  @override
  void report(var code, Uri uri, int begin, int end, String message, kind) {
    messages.add([message, kind]);
  }

  @override
  void call(Uri uri, int begin, int end, String message, kind) {
    report(null, uri, begin, end, message, kind);
  }

  @override
  String prefixMessage(String message, Diagnostic kind) {
    return message;
  }

  @override
  int fatalCount;

  @override
  int throwOnErrorCount;
}

Future<CompilationResult> testOutputProvider(
    CompilerOptions options,
    CompilerInput input,
    CompilerDiagnostics diagnostics,
    CompilerOutput output) {
  diagnosticHandler = new CollectingFormattingDiagnosticHandler();
  output.createOutputSink(
      "/non/existing/directory/should/fail/file", "js", OutputType.js);
  return null;
}

void main() {
  compileFunc = testOutputProvider;
  exitFunc = (exitCode) {
    CollectingFormattingDiagnosticHandler handler = diagnosticHandler;
    Expect.equals(1, handler.messages.length);
    var message = handler.messages[0];
    Expect.isTrue(message[0].contains("Cannot open file"));
    Expect.equals(Diagnostic.ERROR, message[1]);
    Expect.equals(1, exitCode);
    exit(0);
  };
  compile(["foo.dart", "--out=bar.dart"]);
}

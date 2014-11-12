// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.missing_file;

import 'dart:io' show exit;
import 'package:expect/expect.dart';

import 'package:compiler/compiler.dart'
       show Diagnostic;
import 'package:compiler/src/dart2js.dart'
       show exitFunc, compileFunc, compile, diagnosticHandler;
import 'package:compiler/src/source_file_provider.dart'
       show FormattingDiagnosticHandler;

class CollectingFormattingDiagnosticHandler
    implements FormattingDiagnosticHandler {

  final provider = null;
  bool showWarnings = true;
  bool showHints = true;
  bool verbose = true;
  bool isAborting = false;
  bool enableColors = false;
  bool throwOnError = false;
  var lastKind = null;

  final int FATAL = 0;
  final int INFO = 1;

  final messages = [];

  void info(var message, [kind]) {
   messages.add([message, kind]);
  }

  void diagnosticHandler(Uri uri, int begin, int end, String message, kind) {
    messages.add([message, kind]);
  }

  void call(Uri uri, int begin, int end, String message, kind) {
    diagnosticHandler(uri, begin, end, message, kind);
  }

  String prefixMessage(String message, Diagnostic kind) {
    return message;
  }

  int fatalCount;

  int throwOnErrorCount;
}

testOutputProvider(script, libraryRoot, packageRoot, inputProvider, handler,
                   [options, outputProvider, environment]) {
  diagnosticHandler = new CollectingFormattingDiagnosticHandler();
  outputProvider("/non/existing/directory/should/fail/file", "js");
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

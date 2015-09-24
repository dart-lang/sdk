// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "package:compiler/src/diagnostics/messages.dart";
import "package:compiler/src/elements/elements.dart";
import "package:compiler/src/resolution/members.dart";
import "package:compiler/src/diagnostics/diagnostic_listener.dart";
import "mock_compiler.dart";


class CallbackMockCompiler extends MockCompiler {
  CallbackMockCompiler() : super.internal();

  var onError;
  var onWarning;

  setOnError(var f) => onError = f;
  setOnWarning(var f) => onWarning = f;

  void reportWarning(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    if (onWarning != null) {
      onWarning(this, message.spannable, message.message);
    }
    super.reportWarning(message, infos);
  }

  void reportError(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    if (onError != null) {
      onError(this, message.spannable, message.message);
    }
    super.reportError(message, infos);
  }
}

Future testErrorHandling() {
  // Test that compiler.currentElement is set correctly when
  // reporting errors/warnings.
  CallbackMockCompiler compiler = new CallbackMockCompiler();
  return compiler.init().then((_) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    compiler.parseScript('NoSuchPrefix.NoSuchType foo() {}');
    FunctionElement foo = compiler.mainApp.find('foo');
    compiler.setOnWarning(
        (c, n, m) => Expect.equals(foo, compiler.currentElement));
    foo.computeType(compiler);
    Expect.equals(1, compiler.warnings.length);
  });
}

main() {
  asyncTest(() => testErrorHandling());
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "package:compiler/src/dart2jslib.dart";
import "package:compiler/src/elements/elements.dart";
import "package:compiler/src/resolution/resolution.dart";
import "package:compiler/src/util/util.dart";
import "mock_compiler.dart";


class CallbackMockCompiler extends MockCompiler {
  CallbackMockCompiler() : super.internal();

  var onError;
  var onWarning;

  setOnError(var f) => onError = f;
  setOnWarning(var f) => onWarning = f;

  void reportWarning(Spannable node,
                     MessageKind messageKind,
                     [Map arguments = const {}]) {
    if (onWarning != null) {
      onWarning(this, node, messageKind.message(arguments));
    }
    super.reportWarning(node, messageKind, arguments);
  }

  void reportError(Spannable node,
                   MessageKind messageKind,
                   [Map arguments = const {}]) {
    if (onError != null) {
      onError(this, node, messageKind.message(arguments));
    }
    super.reportError(node, messageKind, arguments);
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

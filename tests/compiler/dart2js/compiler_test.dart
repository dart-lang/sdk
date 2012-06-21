// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../lib/compiler/implementation/leg.dart");
#import("../../../lib/compiler/implementation/elements/elements.dart");
#import("../../../lib/compiler/implementation/tree/tree.dart");
#import("../../../lib/compiler/implementation/util/util.dart");
#import("mock_compiler.dart");
#import("parser_helper.dart");

class CallbackMockCompiler extends MockCompiler {
  CallbackMockCompiler();

  var onError;
  var onWarning;

  setOnError(var f) => onError = f;
  setOnWarning(var f) => onWarning = f;

  void reportWarning(Node node, var message) {
    if (onWarning !== null) onWarning(this, node, message);
    super.reportWarning(node, message);
  }

  void reportError(Node node, var message) {
    if (onError !== null) onError(this, node, message);
    super.reportError(node, message);
  }
}

testErrorHandling() {
  // Test that compiler.currentElement is set correctly when
  // reporting errors/warnings.
  CallbackMockCompiler compiler = new CallbackMockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  compiler.parseScript('NoSuchPrefix.NoSuchType foo() {}');
  FunctionElement foo = compiler.mainApp.find(buildSourceString('foo'));
  compiler.setOnWarning((c, n, m) => Expect.equals(foo, compiler.currentElement));
  foo.computeType(compiler);
  Expect.equals(1, compiler.warnings.length);
}

main() {
  testErrorHandling();
}

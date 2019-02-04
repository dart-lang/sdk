// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Analysis to determine how to generate code for typed JavaScript interop.
library compiler.src.js_backend.js_interop_analysis;

import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../universe/selector.dart' show Selector;
import '../universe/codegen_world_builder.dart';
import '../universe/world_builder.dart' show SelectorConstraints;
import 'namer.dart';
import 'native_data.dart';

jsAst.Statement buildJsInteropBootstrap(CodegenWorldBuilder codegenWorldBuilder,
    NativeBasicData nativeBasicData, Namer namer) {
  if (!nativeBasicData.isJsInteropUsed) return null;
  List<jsAst.Statement> statements = <jsAst.Statement>[];
  codegenWorldBuilder.forEachInvokedName(
      (String name, Map<Selector, SelectorConstraints> selectors) {
    selectors.forEach((Selector selector, SelectorConstraints constraints) {
      if (selector.isClosureCall) {
        // TODO(jacobr): support named arguments.
        if (selector.namedArgumentCount > 0) return;
        int argumentCount = selector.argumentCount;
        String candidateParameterNames =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        List<String> parameters = new List<String>.generate(
            argumentCount, (i) => candidateParameterNames[i]);

        jsAst.Name name = namer.invocationName(selector);
        statements.add(js.statement(
            'Function.prototype.# = function(#) { return this(#) }',
            [name, parameters, parameters]));
      }
    });
  });
  return new jsAst.Block(statements);
}

FunctionType buildJsFunctionType() {
  // TODO(jacobr): consider using codegenWorldBuilder.isChecks to determine the
  // range of positional arguments that need to be supported by JavaScript
  // function types.
  return new FunctionType(
      const DynamicType(),
      const <DartType>[],
      new List<DartType>.filled(16, const DynamicType()),
      const <String>[],
      const <DartType>[],
      const <FunctionTypeVariable>[]);
}

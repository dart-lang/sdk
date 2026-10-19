// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstNodeExtensionTest);
  });
}

@reflectiveTest
class AstNodeExtensionTest extends ParserDiagnosticsTest {
  void test_enclosingClosure2_closure() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  () {
    return 0;
  };
}
''');
    var findNode = parseResult.findNode;
    var node = findNode.returnStatement('return 0');
    expect(node.enclosingClosure2, findNode.singleFunctionExpression);
  }

  void test_enclosingClosure2_closure_localFunction() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  () {
    int g() {
      return 0;
    }
  };
}
''');
    var node = parseResult.findNode.returnStatement('return 0');
    expect(node.enclosingClosure2, isNull);
  }
}

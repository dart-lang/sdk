// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionAsExpressionTest);
  });
}

@reflectiveTest
class ExtensionAsExpressionTest extends PubPackageResolutionTest {
  test_prefixedIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
var v = p.E;
//      ^^^
// [diag.extensionAsExpression] Extension 'p.E' can't be used as an expression.
''');
    var node = result.findNode.importPrefixedNameExpression('p.E;');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: E
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
      candidate: package:test/a.dart::@extension::E
    recovery: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: E
    element: package:test/a.dart::@extension::E
    staticType: InvalidType
  element: package:test/a.dart::@extension::E
  staticType: InvalidType
''');
  }

  test_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
var v = E;
//      ^
// [diag.extensionAsExpression] Extension 'E' can't be used as an expression.
''');
    var node = result.findNode.unqualifiedNameExpression('E;');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: E
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
      candidate: <testLibrary>::@extension::E
    recovery: <null>
  staticType: InvalidType
V1: SimpleIdentifier
  token: E
  element: <testLibrary>::@extension::E
  staticType: InvalidType
''');
  }
}

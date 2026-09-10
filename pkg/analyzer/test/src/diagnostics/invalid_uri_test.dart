// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUriTest);
  });
}

@reflectiveTest
class InvalidUriTest extends PubPackageResolutionTest {
  test_libraryImport_emptyUri() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as top;
int x = 1;
class C {
  int x = 1;
  int get y => top.x; // ref
}
''');

    var node = result.findNode.importPrefixedNameExpression('top.x; // ref');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: top
    period: .
    element: <testLibraryFragment>::@prefix::top
  name: x
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::x
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: top
    element: <testLibraryFragment>::@prefix::top
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: x
    element: <testLibrary>::@getter::x
    staticType: int
  element: <testLibrary>::@getter::x
  staticType: int
''');
  }
}

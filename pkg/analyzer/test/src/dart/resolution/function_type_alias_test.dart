// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeAliasResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionTypeAliasResolutionTest extends PubPackageResolutionTest {
  test_defaultValue() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

typedef void F([int a = foo]);
//                    ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = result.findNode.singleRegularFormalParameter;
    var element = node.declaredFragment!.element;
    assertResolvedNodeText(element.constantInitializer2!, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::foo
    type: int
  staticType: int
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');

    assertElementDefaultValueIsClauseValue(node);
    assertDartObjectText(element.computeConstantValue(), r'''
int 0
  variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_type_element() async {
    var result = await resolveTestCode(r'''
G<int> g;

typedef T G<T>();
''');

    var node = result.findNode.namedType('G<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: G
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@typeAlias::G
  type: int Function()
    alias: <testLibrary>::@typeAlias::G
      typeArguments
        int
''');
  }

  test_type_missing_type_parameter_name() async {
    await resolveTestCode(r'''
typedef F = void Function< extends int>();
''');
  }
}

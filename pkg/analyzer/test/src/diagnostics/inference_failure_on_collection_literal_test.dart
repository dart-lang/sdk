// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnCollectionLiteralTest);
  });
}

@reflectiveTest
class InferenceFailureOnCollectionLiteralTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
  }

  test_collectionsWithAnyElements() async {
    await assertErrorsInCode(
      r'''
void main() {
  var a = [7];
  var b = [7 as dynamic];
  var c = {7};
  var d = {7 as dynamic};
  var e = {7: 42};
  var f = {7 as dynamic: 42};
  var g = {7: 42 as dynamic};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.unusedLocalVariable, 35, 1),
        error(WarningCode.unusedLocalVariable, 61, 1),
        error(WarningCode.unusedLocalVariable, 76, 1),
        error(WarningCode.unusedLocalVariable, 102, 1),
        error(WarningCode.unusedLocalVariable, 121, 1),
        error(WarningCode.unusedLocalVariable, 151, 1),
      ],
    );
  }

  test_conditionalList() async {
    await assertErrorsInCode(
      r'''
void main() {
  var x = "a" == "b" ? [1, 2, 3] : [];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 49, 2),
      ],
    );
  }

  test_defaultParameter_list() async {
    await assertErrorsInCode(
      r'''
void f([list = const []]) => print(list);
''',
      [
        error(WarningCode.inferenceFailureOnUntypedParameter, 8, 4),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 15, 8),
      ],
    );
  }

  test_defaultParameter_map() async {
    await assertErrorsInCode(
      r'''
void f([map = const {}]) => print(map);
''',
      [
        error(WarningCode.inferenceFailureOnUntypedParameter, 8, 3),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 14, 8),
      ],
    );
  }

  test_downwardsInference() async {
    await assertErrorsInCode(
      r'''
void main() {
  List<dynamic> a = [];
  Set<dynamic> b = {};
  Map<dynamic, dynamic> c = {};

  int setLength(Set<Object> set) => set.length;
  setLength({});

  List<int> f() => [];
  Set<int> g() => {};
  Map<int, int> h() => {};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 30, 1),
        error(WarningCode.unusedLocalVariable, 53, 1),
        error(WarningCode.unusedLocalVariable, 85, 1),
        error(WarningCode.unusedElement, 172, 1),
        error(WarningCode.unusedElement, 194, 1),
        error(WarningCode.unusedElement, 221, 1),
      ],
    );
  }

  test_explicitTypeArguments() async {
    await assertErrorsInCode(
      r'''
void main() {
  var a = <dynamic>[];
  var b = <dynamic>{};
  var c = <dynamic, dynamic>{};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.unusedLocalVariable, 43, 1),
        error(WarningCode.unusedLocalVariable, 66, 1),
      ],
    );
  }

  test_functionReturnsList_dynamicReturnType() async {
    await assertErrorsInCode(
      r'''
dynamic f() => [];
''',
      [error(WarningCode.inferenceFailureOnCollectionLiteral, 15, 2)],
    );
  }

  test_functionReturnsList_ObjectReturnType() async {
    await assertNoErrorsInCode(r'''
Object f() => [];
''');
  }

  test_functionReturnsList_voidReturnType() async {
    await assertNoErrorsInCode(r'''
void f() => [];
''');
  }

  test_inferredFromNullAware() async {
    await assertErrorsInCode(
      r'''
void f(List<int>? a) {
  var x = a ?? [];
}
''',
      [error(WarningCode.unusedLocalVariable, 29, 1)],
    );
  }

  test_localConstVariable_list() async {
    await assertErrorsInCode(
      r'''
void main() {
  const x = [];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 22, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 26, 2),
      ],
    );
  }

  test_localConstVariable_map() async {
    await assertErrorsInCode(
      r'''
void main() {
  const x = {};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 22, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 26, 2),
      ],
    );
  }

  test_localVariable_list() async {
    await assertErrorsInCode(
      r'''
void main() {
  var x = [];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 24, 2),
      ],
    );
  }

  test_localVariable_map() async {
    await assertErrorsInCode(
      r'''
void main() {
  var x = {};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 24, 2),
      ],
    );
  }

  test_onlyInnerMostEmptyCollections() async {
    await assertErrorsInCode(
      r'''
void main() {
  var x = {[]: {}};
}
''',
      [
        error(WarningCode.unusedLocalVariable, 20, 1),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 25, 2),
        error(WarningCode.inferenceFailureOnCollectionLiteral, 29, 2),
      ],
    );
  }

  test_topLevelVariable_list() async {
    await assertErrorsInCode(
      r'''
var x = [];
''',
      [error(WarningCode.inferenceFailureOnCollectionLiteral, 8, 2)],
    );
  }

  test_topLevelVariable_listWithInferredType() async {
    await assertNoErrorsInCode(r'''
List<int> x = [];
''');
  }

  test_topLevelVariable_listWithTypeArgument() async {
    await assertNoErrorsInCode(r'''
var x = <int>[];
''');
  }
}

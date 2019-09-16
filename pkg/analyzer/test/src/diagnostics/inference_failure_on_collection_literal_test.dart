// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnCollectionLiteralTest);
  });
}

@reflectiveTest
class InferenceFailureOnCollectionLiteralTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..strictInference = true;

  test_collectionsWithAnyElements() async {
    await assertNoErrorsInCode(r'''
void main() {
  var a = [7];
  var b = [7 as dynamic];
  var c = {7};
  var d = {7 as dynamic};
  var e = {7: 42};
  var f = {7 as dynamic: 42};
  var g = {7: 42 as dynamic};
}
''');
  }

  test_conditionalList() async {
    await assertErrorsInCode(r'''
void main() {
  var x = "a" == "b" ? [1, 2, 3] : [];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 49, 2),
    ]);
  }

  test_defaultParameter_list() async {
    await assertErrorsInCode(r'''
void f([list = const []]) => print(list);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 8, 4),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 15, 8),
    ]);
  }

  test_defaultParameter_map() async {
    await assertErrorsInCode(r'''
void f([map = const {}]) => print(map);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 8, 3),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 14, 8),
    ]);
  }

  test_downwardsInference() async {
    await assertNoErrorsInCode(r'''
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
''');
  }

  test_explicitTypeArguments() async {
    await assertNoErrorsInCode(r'''
void main() {
  var a = <dynamic>[];
  var b = <dynamic>{};
  var c = <dynamic, dynamic>{};
}
''');
  }

  test_functionReturnsList_dynamicReturnType() async {
    await assertErrorsInCode(r'''
dynamic f() => [];
''', [
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 15, 2),
    ]);
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
    await assertNoErrorsInCode(r'''
void main() {
  var x = [1, 2, 3] ?? [];
}
''');
  }

  test_localConstVariable_list() async {
    await assertErrorsInCode(r'''
void main() {
  const x = [];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 26, 2),
    ]);
  }

  test_localConstVariable_map() async {
    await assertErrorsInCode(r'''
void main() {
  const x = {};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 26, 2),
    ]);
  }

  test_localVariable_list() async {
    await assertErrorsInCode(r'''
void main() {
  var x = [];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 24, 2),
    ]);
  }

  test_localVariable_map() async {
    await assertErrorsInCode(r'''
void main() {
  var x = {};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 24, 2),
    ]);
  }

  test_onlyInnerMostEmptyCollections() async {
    await assertErrorsInCode(r'''
void main() {
  var x = {[]: {}};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 25, 2),
      error(HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, 29, 2),
    ]);
  }
}

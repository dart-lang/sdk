// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var a = [7];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var b = [7 as dynamic];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  var c = {7};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
  var d = {7 as dynamic};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
  var e = {7: 42};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'e' isn't used.
  var f = {7 as dynamic: 42};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'f' isn't used.
  var g = {7: 42 as dynamic};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
}
''');
  }

  test_conditionalList() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var x = "a" == "b" ? [1, 2, 3] : [];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                                 ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
}
''');
  }

  test_defaultParameter_list() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([list = const []]) => print(list);
//      ^^^^
// [diag.inferenceFailureOnUntypedParameter] The type of 'list' can't be inferred; a type must be explicitly provided.
//             ^^^^^^^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
''');
  }

  test_defaultParameter_map() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([map = const {}]) => print(map);
//      ^^^
// [diag.inferenceFailureOnUntypedParameter] The type of 'map' can't be inferred; a type must be explicitly provided.
//            ^^^^^^^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'Map' can't be inferred.
''');
  }

  test_downwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  List<dynamic> a = [];
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  Set<dynamic> b = {};
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  Map<dynamic, dynamic> c = {};
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.

  int setLength(Set<Object> set) => set.length;
  setLength({});

  List<int> f() => [];
//          ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
  Set<int> g() => {};
//         ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
  Map<int, int> h() => {};
//              ^
// [diag.unusedElement] The declaration 'h' isn't referenced.
}
''');
  }

  test_explicitTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var a = <dynamic>[];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var b = <dynamic>{};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  var c = <dynamic, dynamic>{};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
}
''');
  }

  test_functionReturnsList_dynamicReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f() => [];
//             ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
''');
  }

  test_functionReturnsList_ObjectReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f() => [];
''');
  }

  test_functionReturnsList_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() => [];
''');
  }

  test_inferredFromNullAware() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<int>? a) {
  var x = a ?? [];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
  }

  test_localConstVariable_list() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  const x = [];
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//          ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
}
''');
  }

  test_localConstVariable_map() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  const x = {};
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//          ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'Map' can't be inferred.
}
''');
  }

  test_localVariable_list() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var x = [];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//        ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
}
''');
  }

  test_localVariable_map() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var x = {};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//        ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'Map' can't be inferred.
}
''');
  }

  test_onlyInnerMostEmptyCollections() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var x = {[]: {}};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//         ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
//             ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'Map' can't be inferred.
}
''');
  }

  test_topLevelVariable_list() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = [];
//      ^^
// [diag.inferenceFailureOnCollectionLiteral] The type argument(s) of 'List' can't be inferred.
''');
  }

  test_topLevelVariable_listWithInferredType() async {
    await resolveTestCodeWithDiagnostics(r'''
List<int> x = [];
''');
  }

  test_topLevelVariable_listWithTypeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = <int>[];
''');
  }
}

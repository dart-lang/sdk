// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopTypeInferenceResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopTypeInferenceResolutionTest extends PubPackageResolutionTest {
  test_referenceInstanceVariable_withDeclaredType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int a = b + 1;
}
final b = new A().a;
''');

    assertType(result.findElement.field('a').type, 'int');
    assertType(result.findElement.topVar('b').type, 'int');
  }

  test_referenceInstanceVariable_withoutDeclaredType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final a = b + 1;
//      ^
// [diag.topLevelCycle] The type of 'a' can't be inferred because it depends on itself through the cycle: a, b.
}
final b = new A().a;
//    ^
// [diag.topLevelCycle] The type of 'b' can't be inferred because it depends on itself through the cycle: a, b.
''');

    assertTypeDynamic(result.findElement.field('a').type);
    assertTypeDynamic(result.findElement.topVar('b').type);
  }
}

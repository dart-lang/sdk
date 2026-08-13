// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidTypeTest);
    defineReflectiveTests(ForInOfInvalidTypeWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ForInOfInvalidTypeTest extends PubPackageResolutionTest {
  test_awaitForIn_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_awaitForIn_interfaceType_notStream() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool e) async {
  await for (var id in e) {
//                     ^
// [diag.forInOfInvalidType] The type 'bool' used in the 'for' loop must implement 'Stream'.
    id;
  }
}
''');
  }

  test_awaitForIn_never() async {
    // TODO(scheglov): extract for-in resolution and implement
    //    assertType(findNode.simple('id;'), 'Never');
    await resolveTestCodeWithDiagnostics(r'''
f(Never e) async {
  await for (var id in e) {
// [diag.deadCode][column 14][length 26] Dead code.
    id;
  }
}
''');
  }

  test_awaitForIn_object() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object e) async {
  await for (var id in e) {
//                     ^
// [diag.forInOfInvalidType] The type 'Object' used in the 'for' loop must implement 'Stream'.
    id;
  }
}
''');
  }

  test_awaitForIn_streamOfDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Stream<dynamic> e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_awaitForIn_streamOfDynamicSubclass() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}
f(MyStream<dynamic> e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_interfaceType_iterable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Iterable e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_interfaceType_notIterable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool e) {
  for (var id in e) {
//               ^
// [diag.forInOfInvalidType] The type 'bool' used in the 'for' loop must implement 'Iterable'.
    id;
  }
}
''');
  }

  test_forIn_interfaceTypeTypedef_iterable() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef L = List<String>;
f(L e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_never() async {
    // TODO(scheglov): extract for-in resolution and implement
    //    assertType(findNode.simple('id;'), 'Never');
    await resolveTestCodeWithDiagnostics(r'''
f(Never e) {
  for (var id in e) {
// [diag.deadCode][column 8][length 26] Dead code.
    id;
  }
}
''');
  }

  test_forIn_object() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object e) async {
  for (var id in e) {
//               ^
// [diag.forInOfInvalidType] The type 'Object' used in the 'for' loop must implement 'Iterable'.
    id;
  }
}
''');
  }
}

@reflectiveTest
class ForInOfInvalidTypeWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_forIn() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
f(dynamic e) {
  for (var id in e) {
//               ^
// [diag.forInOfInvalidType] The type 'dynamic' used in the 'for' loop must implement 'Iterable'.
    id;
  }
}
''');
  }
}

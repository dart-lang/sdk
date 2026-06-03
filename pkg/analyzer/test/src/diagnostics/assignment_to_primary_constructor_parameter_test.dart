// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToPrimaryConstructorParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToPrimaryConstructorParameterTest
    extends PubPackageResolutionTest {
  test_fieldInitializer_late() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  late int y = x = 0;
//             ^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
  }

  test_fieldInitializer_notLate() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y = x = 0;
//        ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  var f = () {
    x = 0;
//  ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
  };
}
''');
  }

  test_fieldInitializer_notLate_nullAware() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int? x) {
  int y = x ??= 0;
//        ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_list() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  List<int> y = [x] = [2];
//               ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_logicalAnd() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x, int z) {
  int y = (x && z) = 2;
//         ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
//              ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_map() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  Map<int?, int> y = {null: x} = {null: 2};
//                          ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_nullAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int? x) {
  int y = (x!) = 2;
//         ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
//          ^
// [diag.unnecessaryNullAssertPattern] The null-assert pattern will have no effect because the matched type isn't nullable.
}
''');
  }

  test_fieldInitializer_notLate_pattern_object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  Object y = int(sign: x) = 2;
//                     ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y = (x) = 0;
//         ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_pattern_record() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  (int, {bool name}) y = (x, name: _) = (2, name: true);
//                        ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_plusEq() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y = x += 1;
//        ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_postfix() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y = x++;
//        ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_fieldInitializer_notLate_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y = ++x;
//          ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_primaryConstructor_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  this {
    x = 0;
  }
}
''');
  }

  test_primaryConstructor_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y;
  this : y = x = 0;
//           ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_primaryConstructor_initializer_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  var f;
  this : f = (() {
    x = 0;
//  ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
  });
}
''');
  }

  test_primaryConstructor_initializer_nullAware() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int? x) {
  int y;
  this : y = x ??= 0;
//           ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_primaryConstructor_initializer_plusEq() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y;
  this : y = x += 1;
//           ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_primaryConstructor_initializer_postfix() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y;
  this : y = x++;
//           ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }

  test_primaryConstructor_initializer_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  int y;
  this : y = ++x;
//             ^
// [diag.assignmentToPrimaryConstructorParameter] A primary constructor parameter can't be assigned to in an initializer.
}
''');
  }
}

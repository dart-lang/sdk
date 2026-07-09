// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePatternFieldTest);
  });
}

@reflectiveTest
class DuplicatePatternFieldTest extends PubPackageResolutionTest {
  test_objectPattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int(sign: 0, sign: 1):
//           ^^^^
// [context 1] The first field.
//                    ^^^^
// [diag.duplicatePatternField][context 1] The field 'sign' is already matched in this pattern.
      break;
  }
}
''');
  }

  test_recordPattern_dynamicType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (foo: 0, foo: 1):
//        ^^^
// [context 1] The first field.
//                ^^^
// [diag.duplicatePatternField][context 1] The field 'foo' is already matched in this pattern.
      break;
  }
}
''');
  }

  test_recordPattern_dynamicType_implicitName_duplicate() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (foo: 0, :var foo):
//        ^^^
// [context 1] The first field.
//                ^
// [diag.duplicatePatternField][context 1] The field 'foo' is already matched in this pattern.
//                     ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
  }

  test_recordPattern_dynamicType_implicitName_original() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (:var foo, foo: 1):
//        ^
// [context 1] The first field.
//             ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
//                  ^^^
// [diag.duplicatePatternField][context 1] The field 'foo' is already matched in this pattern.
      break;
  }
}
''');
  }

  test_recordPattern_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (foo: 0, foo: 1):
//        ^^^
// [context 1] The first field.
//                ^^^
// [diag.duplicatePatternField][context 1] The field 'foo' is already matched in this pattern.
      break;
  }
}
''');
  }

  test_recordPattern_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: 0, foo: 1):
//        ^^^
// [context 1] The first field.
//                ^^^
// [diag.duplicatePatternField][context 1] The field 'foo' is already matched in this pattern.
      break;
  }
}
''');
  }
}

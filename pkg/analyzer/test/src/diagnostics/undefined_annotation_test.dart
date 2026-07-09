// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedAnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedAnnotationTest extends PubPackageResolutionTest {
  test_identifier1_localVariable_const() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  const a = 0;
  g(@a x) {}
  g(0);
}
''');
  }

  test_unresolved_identifier() async {
    await resolveTestCodeWithDiagnostics(r'''
@unresolved
// [diag.undefinedAnnotation][column 1][length 11] Undefined name 'unresolved' used as an annotation.
main() {
}
''');
  }

  test_unresolved_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
@Unresolved()
// [diag.undefinedAnnotation][column 1][length 13] Undefined name 'Unresolved' used as an annotation.
main() {
}
''');
  }

  test_unresolved_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
@p.A(0)
// [diag.undefinedAnnotation][column 1][length 7] Undefined name 'p' used as an annotation.
class B {}
''');
  }

  test_unresolved_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.A(0)
// [diag.undefinedAnnotation][column 1][length 7] Undefined name 'A' used as an annotation.
class B {}
''');
  }

  test_unresolved_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;
@p.unresolved
// [diag.undefinedAnnotation][column 1][length 13] Undefined name 'unresolved' used as an annotation.
main() {
}
''');
  }

  test_useLibraryScope() async {
    await resolveTestCodeWithDiagnostics(r'''
@foo
// [diag.undefinedAnnotation][column 1][length 4] Undefined name 'foo' used as an annotation.
class A {
  static const foo = null;
}
''');
  }
}

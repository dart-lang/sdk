// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTest);
  });
}

@reflectiveTest
class InvalidAnnotationTest extends PubPackageResolutionTest {
  test_class_noUnnamedConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.named();
}

@A
// [diag.invalidAnnotation][column 1][length 2] Annotation must be either a const variable reference or const constructor invocation.
void f() {}
''');
  }

  test_class_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo() => 0;
}

@A.foo
// [diag.invalidAnnotation][column 1][length 6] Annotation must be either a const variable reference or const constructor invocation.
void f() {}
''');
  }

  test_class_staticMethod_arguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo() => 0;
}

@A.foo()
// [diag.invalidAnnotation][column 1][length 8] Annotation must be either a const variable reference or const constructor invocation.
void f() {}
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
get V => 0;
@V
// [diag.invalidAnnotation][column 1][length 2] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_getter_importWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
get V => 0;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
@p.V
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_importWithPrefix_notConstantVariable() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
final V = 0;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
@p.V
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_importWithPrefix_notVariableOrConstructorInvocation() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
typedef V();
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
@p.V
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_localVariable_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const a = 0;
  @a
  var b; // ignore:unused_local_variable
}
''');
  }

  test_localVariable_const_withArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const a = 0;
  @a(0)
//^^^^^
// [diag.invalidAnnotation] Annotation must be either a const variable reference or const constructor invocation.
  var b; // ignore:unused_local_variable
}
''');
  }

  test_localVariable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final a = 0;
  @a
//^^
// [diag.invalidAnnotation] Annotation must be either a const variable reference or const constructor invocation.
  var b; // ignore:unused_local_variable
}
''');
  }

  test_notClass_importWithPrefix() async {
    newFile('$testPackageLibPath/annotations.dart', r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'annotations.dart' as pref;
@pref.property(123)
// [diag.invalidAnnotation][column 1][length 19] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_notClass_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);

@property(123)
// [diag.invalidAnnotation][column 1][length 14] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_notConstantVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
final V = 0;
@V
// [diag.invalidAnnotation][column 1][length 2] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_notVariableOrConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef V();
@V
// [diag.invalidAnnotation][column 1][length 2] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }

  test_prefix_function() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.sin(0)
// [diag.invalidAnnotation][column 1][length 9] Annotation must be either a const variable reference or const constructor invocation.
class B {}
''');
  }

  test_prefix_function_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.sin.cos(0)
// [diag.invalidAnnotation][column 1][length 13] Annotation must be either a const variable reference or const constructor invocation.
class B {}
''');
  }

  test_staticMethodReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static f() {}
}
@A.f
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
main() {
}
''');
  }
}

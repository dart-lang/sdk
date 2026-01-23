// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAnnotationDeferredClassTest);
  });
}

@reflectiveTest
class TypeAnnotationDeferredClassTest extends PubPackageResolutionTest {
  test_annotation_typeArgument() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class D {}
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C<T> { const C(); }
@C<a.D>() main () {}
''',
      [
        error(
          diag.typeAnnotationDeferredClass,
          77,
          3,
          messageContains: ["'a.D'"],
        ),
      ],
    );
  }

  test_asExpression() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  v as a.A;
}''',
      [error(diag.typeAnnotationDeferredClass, 62, 3)],
    );
  }

  test_catchClause() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  try {
  } on a.A {
  }
}''',
      [error(diag.typeAnnotationDeferredClass, 70, 3)],
    );
  }

  test_fieldFormalParameter() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}''',
      [error(diag.typeAnnotationDeferredClass, 71, 3)],
    );
  }

  test_functionDeclaration_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
a.A? f() { return null; }
''',
      [error(diag.typeAnnotationDeferredClass, 48, 4)],
    );
  }

  test_functionTypedFormalParameter_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}''',
      [error(diag.typeAnnotationDeferredClass, 50, 3)],
    );
  }

  test_isExpression() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  bool b = v is a.A;
}''',
      [
        error(diag.unusedLocalVariable, 62, 1),
        error(diag.typeAnnotationDeferredClass, 71, 3),
      ],
    );
  }

  test_methodDeclaration_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A? m() { return null; }
}''',
      [error(diag.typeAnnotationDeferredClass, 60, 4)],
    );
  }

  test_simpleFormalParameter() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}''',
      [error(diag.typeAnnotationDeferredClass, 50, 3)],
    );
  }

  test_typeArgumentList() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c = C();
''',
      [error(diag.typeAnnotationDeferredClass, 64, 3)],
    );
  }

  test_typeArgumentList2() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c = C();
''',
      [
        error(diag.typeAnnotationDeferredClass, 67, 3),
        error(diag.typeAnnotationDeferredClass, 72, 3),
      ],
    );
  }

  test_typeParameter_bound() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}''',
      [error(diag.typeAnnotationDeferredClass, 66, 3)],
    );
  }

  test_variableDeclarationList() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
a.A v = a.A();
''',
      [error(diag.typeAnnotationDeferredClass, 48, 3)],
    );
  }
}

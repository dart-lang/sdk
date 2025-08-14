// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorParamTypeMismatchTest);
  });
}

@reflectiveTest
class ConstConstructorParamTypeMismatchTest extends PubPackageResolutionTest {
  test_assignable_fieldFormal_omittedType() async {
    // If a field is declared without a type, and no initializer, it's type is
    // dynamic.
    await assertNoErrorsInCode(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);
''');
  }

  test_assignable_fieldFormal_subtype() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());
''');
  }

  test_assignable_fieldFormal_typedef() async {
    // foo has the type dynamic -> dynamic, so it is not assignable to A.f.
    await assertErrorsInCode(
      r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 116, 3),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 116, 3),
      ],
    );
  }

  test_assignable_fieldFormal_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);
''');
  }

  test_assignable_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
  }

  test_assignable_undefined() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');
''',
      [error(CompileTimeErrorCode.undefinedClass, 20, 10)],
    );
  }

  test_assignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(
      r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);
''',
      [error(CompileTimeErrorCode.undefinedClass, 20, 10)],
    );
  }

  test_int_to_double_reference_from_other_library_other_file_after() async {
    var other = newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    var otherFileResult = await resolveFile(other);
    expect(otherFileResult.diagnostics, isEmpty);
  }

  test_int_to_double_reference_from_other_library_other_file_before() async {
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    var other = newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    var otherFileResult = await resolveFile(other);
    expect(otherFileResult.diagnostics, isEmpty);
  }

  test_int_to_double_single_library() async {
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
  }

  test_int_to_double_via_default_value_other_file_after() async {
    var other = newFile('$testPackageLibPath/other.dart', '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';
const c = C();
''');
    var otherFileResult = await resolveFile(other);
    expect(otherFileResult.diagnostics, isEmpty);
  }

  test_int_to_double_via_default_value_other_file_before() async {
    var other = newFile('$testPackageLibPath/other.dart', '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    var otherFileResult = await resolveFile(other);
    expect(otherFileResult.diagnostics, isEmpty);

    await assertNoErrorsInCode('''
import 'other.dart';
const c = C();
''');
  }

  test_notAssignable_fieldFormal_optional() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 45, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 64, 9),
      ],
    );
  }

  test_notAssignable_fieldFormal_supertype() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 143, 1),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 143, 1),
      ],
    );
  }

  test_notAssignable_fieldFormal_typedef() async {
    // foo has type String -> int, so it is not assignable to A.f
    // (A.f requires it to be int -> String).
    await assertErrorsInCode(
      r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 127, 3),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 127, 3),
      ],
    );
  }

  test_notAssignable_fieldFormal_unrelated() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 62, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 62, 5),
      ],
    );
  }

  test_notAssignable_fieldFormal_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');
''',
      [error(CompileTimeErrorCode.undefinedClass, 18, 10)],
    );
  }

  test_notAssignable_typeSubstitution() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 52, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 52, 5),
      ],
    );
  }

  test_notAssignable_unrelated() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int x);
}
var v = const A('foo');
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 46, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 46, 5),
      ],
    );
  }

  test_superFormalParameter_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  const A({int a = 0});
}

class B extends A {
  static const f = B();

  const B({super.a = 2});
}
''');
  }

  test_superFormalParameter_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  const A({int a = 0});
}

class B extends A {
  const B({super.a});
}

const b = const B();
''');
  }

  test_superFormalParameter_inherited_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A({int a = 0});
}

class B extends A<int> {
  const B({super.a});
}

const b = const B();
''');
  }
}

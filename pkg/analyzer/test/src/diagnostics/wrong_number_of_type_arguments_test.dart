// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends PubPackageResolutionTest {
  test_class_tooFew() async {
    await assertErrorsInCode(r'''
class A<E, F> {}
A<A> a = null;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 17, 4),
    ]);
  }

  test_class_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {}
A<A, A> a = null;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 14, 7),
    ]);
  }

  test_classAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B<F extends num> = A<F> with M;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 4),
    ]);
  }

  test_const_nonGeneric() async {
    await assertErrorsInCode('''
class C {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 6),
    ]);
  }

  test_const_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 53, 6),
    ]);
  }

  test_const_tooMany() async {
    await assertErrorsInCode('''
class C<E> {
  const C();
}

f() {
  return const C<int, int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 11),
    ]);
  }

  test_dynamic() async {
    await assertErrorsInCode(r'''
dynamic<int> v;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 0, 12),
    ]);
  }

  test_new_nonGeneric() async {
    await assertErrorsInCode('''
class C {}

f() {
  return new C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 31, 6),
    ]);
  }

  test_new_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {}

f() {
  return new C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 37, 6),
    ]);
  }

  test_new_tooMany() async {
    await assertErrorsInCode('''
class C<E> {}

f() {
  return new C<int, int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 34, 11),
    ]);
  }

  test_type_tooFew() async {
    await assertErrorsInCode(r'''
class A<K, V> {
  K element;
}
main(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 36, 6),
    ]);
  }

  test_type_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {
  E element;
}
main(A<int,int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 33, 10),
    ]);
  }

  test_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  T<int> f;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 15, 6),
    ]);
  }

  test_typeTest_tooFew() async {
    await assertErrorsInCode(r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 49, 4),
    ]);
  }

  test_typeTest_tooMany() async {
    await assertErrorsInCode(r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 46, 7),
    ]);
  }
}

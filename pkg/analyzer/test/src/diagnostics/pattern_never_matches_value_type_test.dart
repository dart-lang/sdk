// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternNeverMatchesValueTypeTest);
  });
}

@reflectiveTest
class PatternNeverMatchesValueTypeTest extends PubPackageResolutionTest {
  test_functionType_interfaceType() async {
    await assertErrorsInCode('''
void f(void Function() x) {
  if (x case int _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 41, 3),
    ]);
  }

  test_functionType_interfaceType_function() async {
    await assertNoErrorsInCode('''
void f(void Function() x) {
  if (x case Function _) {}
}
''');
  }

  test_functionType_interfaceType_object() async {
    await assertNoErrorsInCode('''
void f(void Function() x) {
  if (x case Object _) {}
}
''');
  }

  test_functionType_interfaceType_objectQuestion() async {
    await assertNoErrorsInCode('''
void f(void Function() x) {
  if (x case Object? _) {}
}
''');
  }

  test_functionType_recordType() async {
    await assertErrorsInCode('''
void f(void Function() x) {
  if (x case (int,) _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 41, 6),
    ]);
  }

  test_functionTypeQuestion_interfaceType_object() async {
    await assertNoErrorsInCode('''
void f(void Function()? x) {
  if (x case Object _) {}
}
''');
  }

  test_functionTypeQuestion_interfaceType_objectQuestion() async {
    await assertNoErrorsInCode('''
void f(void Function()? x) {
  if (x case Object? _) {}
}
''');
  }

  test_interfaceType2_generic_argumentsMatch() async {
    await assertNoErrorsInCode('''
void f(List<A> x) {
  if (x case List<B> _) {}
}

final class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_generic_argumentsNotMatch() async {
    await assertErrorsInCode('''
void f(List<A> x) {
  if (x case List<B> _) {}
}

final class A {}
final class B {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 33, 7),
    ]);
  }

  test_interfaceType2_matchedDouble_requiredInt() async {
    await assertNoErrorsInCode('''
void f(double x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedExtensionType_requiredExtensionType() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case A _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedExtensionType_requiredRepresentation() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case int _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedExtensionTypeUnrelated_requiredFinal() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case C _) {}
}

extension type A(B _) {}

class B {}

final class C {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_matchedFinal_enumSubtype() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case E _) {}
}

final class A {}
enum E implements A {
  v
}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_noneImplementsRequired() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A {}
final class A3 implements A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneExtendsRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends R implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneImplementsRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A implements R {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneImplementsRequired2() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A {}
final class A3 extends A2 implements R {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneMixesRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A with R {}
mixin class R {}
''');
  }

  test_interfaceType2_matchedFinal_it_implementsGenericRequired_isGeneric_argumentCouldMatch() async {
    await assertNoErrorsInCode('''
void f<T>(A<T> x) {
  if (x case R<int> _) {}
}

final class A<T> extends R<T> {}
class R<T> {}
''');
  }

  test_interfaceType2_matchedFinal_it_implementsGenericRequired_notGeneric_differentArguments() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R<int> _) {}
}

final class A extends R<num> {}
class R<T> {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 6),
    ]);
  }

  test_interfaceType2_matchedFinal_itImplementsRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A implements R {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_itMixesRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A extends Object with R {}
mixin class R {}
''');
  }

  test_interfaceType2_matchedFinal_requiredFutureOrIt() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}

void f(A x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFinal_requiredFutureOrOther() async {
    await assertErrorsInCode('''
import 'dart:async';

final class A {}
class B {}

void f(A x) {
  if (x case FutureOr<B> _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 78, 11),
    ]);
  }

  test_interfaceType2_matchedFinal_requiredUnrelated() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

final class A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_matchedFutureFinal_requiredFutureOrIt() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}

void f(Future<A> x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredFutureIt() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}

void f(FutureOr<A> x) {
  if (x case Future<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredFutureOrIt() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}

void f(FutureOr<A> x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredIt() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}

void f(FutureOr<A> x) {
  if (x case A _) {}
}
''');
  }

  /// `Future` is an interface, so there can be a class that implements both
  /// `B` and `Future<A>`.
  test_interfaceType2_matchedFutureOrFinal_requiredOther() async {
    await assertNoErrorsInCode('''
import 'dart:async';

final class A {}
class B {}

void f(FutureOr<A> x) {
  if (x case B _) {}
}
''');
  }

  test_interfaceType2_matchedInt_requiredDouble() async {
    await assertNoErrorsInCode('''
void f(int x) {
  if (x case double _) {}
}
''');
  }

  test_interfaceType2_matchedObject_requiredClass() async {
    await assertNoErrorsInCode('''
void f(Object x) {
  if (x case A _) {}
}

class A {}
''');
  }

  test_interfaceType2_matchedObject_requiredFinalClass() async {
    await assertNoErrorsInCode('''
void f(Object x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedObjectQuestion_requiredClass() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  if (x case A _) {}
}

class A {}
''');
  }

  test_interfaceType2_matchedObjectQuestion_requiredFinalClass() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedRepresentation_requiredExtensionType() async {
    await assertNoErrorsInCode('''
void f(int x) {
  if (x case A _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedSealed_enumSubtype() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case E _) {}
}

sealed class A {}
enum E implements A {
  v
}
''');
  }

  test_interfaceType2_matchedSealed_hasNonFinalSubtype() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

sealed class A {}
final class A2 extends A {}
class A3 implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedSealed_mixinSubtype() async {
    // No warning, because `M` can be implemented outside.
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case M _) {}
}

sealed class A {}
mixin M implements A {}
''');
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_noneImplementsRequired() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

sealed class A {}
final class A2 extends A {}
final class A3 implements A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_noneImplementsRequired2() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

sealed class A {}
sealed class A2 extends A {}
final class A3 implements A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_oneImplementsRequired() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

sealed class A {}
final class A2 extends A implements R {}
class R {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case A _) {}
}

final class A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf_generic_argumentsMatch() async {
    await assertNoErrorsInCode('''
void f(A<B> x) {
  if (x case A<C> _) {}
}

final class A<T> {}
final class B {}
final class C extends B {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf_generic_argumentsNotMatch() async {
    await assertErrorsInCode('''
void f(A<B> x) {
  if (x case A<C> _) {}
}

final class A<T> {}
final class B {}
final class C {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 4),
    ]);
  }

  test_interfaceType2_requiredFinal_matchedSubtype() async {
    await assertNoErrorsInCode('''
void f(B x) {
  if (x case A _) {}
}

final class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSubtype_generic_argumentsNotMatch() async {
    await assertErrorsInCode('''
void f(B x) {
  if (x case A<D> _) {}
}

final class A<T> {}
final class B extends A<C> {}
final class C {}
final class D {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 4),
    ]);
  }

  test_interfaceType2_requiredFinal_matchedSupertype() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case B _) {}
}

class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_argumentsMatch() async {
    await assertNoErrorsInCode('''
void f(A<C> x) {
  if (x case B _) {}
}

class A<T> {}
final class B extends A<C> {}
final class C {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_argumentsNotMatch() async {
    await assertErrorsInCode('''
void f(A<D> x) {
  if (x case B _) {}
}

class A<T> {}
final class B extends A<C> {}
final class C {}
final class D {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 1),
    ]);
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_differentArguments() async {
    await assertNoErrorsInCode('''
void f(A<num> x) {
  if (x case B _) {}
}

class A<T> {}
final class B extends A<int> {}
''');
  }

  test_interfaceType2_requiredFinal_matchedUnrelated() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case B _) {}
}

class A {}
final class B {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_requiredSealed_hasNonFinalSubtype() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

class A {}
sealed class R {}
final class R1 extends R {}
class R2 extends R {}
''');
  }

  test_interfaceType2_requiredSealed_onlyFinalSubtypes_noneImplementsMatched() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

class A {}
sealed class R {}
final class R1 extends R {}
final class R2 extends R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_interfaceType2_requiredSealed_onlyFinalSubtypes_oneImplementsMatched() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

class A {}
sealed class R {}
final class R1 extends R {}
final class R2 extends R implements A {}
''');
  }

  test_interfaceType_functionType() async {
    await assertErrorsInCode('''
void f(int x) {
  if (x case void Function() _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 29, 15),
    ]);
  }

  test_interfaceType_functionType_function() async {
    await assertNoErrorsInCode('''
void f(Function x) {
  if (x case void Function() _) {}
}
''');
  }

  test_interfaceType_functionType_object() async {
    await assertNoErrorsInCode('''
void f(Object x) {
  if (x case void Function() _) {}
}
''');
  }

  test_interfaceType_recordType() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case (A,) _) {}
}

class A {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 4),
    ]);
  }

  test_interfaceType_recordType_object() async {
    await assertNoErrorsInCode('''
void f(Object x) {
  if (x case (int,) _) {}
}
''');
  }

  test_interfaceType_recordType_record() async {
    await assertNoErrorsInCode('''
void f(Record x) {
  if (x case (int,) _) {}
}
''');
  }

  test_matchedEnum_requiredDifferentEnum() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

enum A { v }
enum R { v }
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_matchedEnum_requiredNotEnum() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

enum A { v }
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 1),
    ]);
  }

  test_matchedEnum_requiredNotEnum_implemented() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

enum A implements R { v }
class R {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_rightTypeArguments() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R<num> _) {}
}

enum A implements R<int> { v }
class R<T> {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_rightTypeArguments2() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R<num> _) {}
}

enum A<T> implements R<T> {
  v1<String>(),
  v2<int>(),
}

class R<T> {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_wrongTypeArguments() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R<int> _) {}
}

enum A implements R<num> { v }
class R<T> {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 6),
    ]);
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_wrongTypeArguments2() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case R<String> _) {}
}

enum A<T> implements R<T> {
  v1<int>(),
  v2<double>(),
}

class R<T> {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 9),
    ]);
  }

  test_matchedEnum_requiredNotEnum_mixed() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case R _) {}
}

enum A with R { v }
mixin R {}
''');
  }

  test_matchedEnum_requiredSameEnum() async {
    await assertNoErrorsInCode('''
void f(E? x) {
  if (x case E _) {}
}

enum E { v }
''');
  }

  test_matchedEnum_requiredSameEnum_generic_hasValue() async {
    await assertNoErrorsInCode('''
void f<T>(E<T>? x) {
  if (x case E<num> _) {}
}

enum E<T> { v<int>() }
''');
  }

  test_matchedEnum_requiredSameEnum_generic_noValue() async {
    await assertErrorsInCode('''
void f<T>(E<T>? x) {
  if (x case E<String> _) {}
}

enum E<T> { v1<int>(), v2<double>() }
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 34, 9),
    ]);
  }

  test_matchedFutureOrRecord_requiredFutureRecord_match() async {
    await assertNoErrorsInCode('''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case Future<(int,)> _) {}
}
''');
  }

  test_matchedFutureOrRecord_requiredFutureRecord_notMatch() async {
    await assertErrorsInCode('''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case Future<(String,)> _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 64, 17),
    ]);
  }

  test_matchedFutureOrRecord_requiredRecord_match() async {
    await assertNoErrorsInCode('''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case (int,) _) {}
}
''');
  }

  test_matchedFutureOrRecord_requiredRecord_notMatch() async {
    await assertErrorsInCode('''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case (String,) _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 64, 9),
    ]);
  }

  test_matchedFutureRecord_requiredFutureOrRecord_match() async {
    await assertNoErrorsInCode('''
import 'dart:async';

void f(Future<(int,)> x) {
  if (x case FutureOr<(int,)> _) {}
}
''');
  }

  test_matchedFutureRecord_requiredFutureOrRecord_notMatch() async {
    await assertErrorsInCode('''
import 'dart:async';

void f(Future<(int,)> x) {
  if (x case FutureOr<(String,)> _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 62, 19),
    ]);
  }

  test_matchedNull_requiredNotNullable() async {
    await assertErrorsInCode('''
void f(Null x) {
  if (x case A _) {}
}

class A {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 1),
    ]);
  }

  test_matchedNull_requiredNull() async {
    await assertNoErrorsInCode('''
void f(Null x) {
  if (x case Null _) {}
}
''');
  }

  test_matchedNull_requiredObject() async {
    await assertErrorsInCode('''
void f(Null x) {
  if (x case Object _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 6),
    ]);
  }

  test_matchedRecord_requiredFutureOrRecord_match() async {
    await assertNoErrorsInCode('''
import 'dart:async';

void f((int,) x) {
  if (x case FutureOr<(int,)> _) {}
}
''');
  }

  test_matchedRecord_requiredFutureOrRecord_notMatch() async {
    await assertErrorsInCode('''
import 'dart:async';

void f((int,) x) {
  if (x case FutureOr<(String,)> _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 54, 19),
    ]);
  }

  test_recordType2_named_differentCount() async {
    await assertErrorsInCode('''
void f(({int f1,}) x) {
  if (x case ({int f1, int f2,}) _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 37, 19),
    ]);
  }

  test_recordType2_named_differentNames() async {
    await assertErrorsInCode('''
void f(({int a, int b}) x) {
  if (x case ({int f1, int f2,}) _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 42, 19),
    ]);
  }

  test_recordType2_named_unrelated() async {
    await assertErrorsInCode('''
void f(({A f1,}) x) {
  if (x case ({R f1,}) _) {}
}

final class A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 35, 9),
    ]);
  }

  test_recordType2_positional_canMatch() async {
    await assertNoErrorsInCode('''
void f((A,) x) {
  if (x case (B,) _) {}
}

class A {}
class B {}
''');
  }

  test_recordType2_positional_differentCount() async {
    await assertErrorsInCode('''
void f((int,) x) {
  if (x case (int, String) _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 13),
    ]);
  }

  test_recordType2_positional_unrelated() async {
    await assertErrorsInCode('''
void f((A,) x) {
  if (x case (R,) _) {}
}

final class A {}
class R {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 4),
    ]);
  }

  test_recordType_functionType() async {
    await assertErrorsInCode('''
void f((int,) x) {
  if (x case void Function() _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 15),
    ]);
  }

  test_recordType_interfaceType() async {
    await assertErrorsInCode('''
void f((A,) x) {
  if (x case A _) {}
}

class A {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 1),
    ]);
  }

  test_recordType_interfaceType_object() async {
    await assertNoErrorsInCode('''
void f((int,)? x) {
  if (x case Object _) {}
}
''');
  }

  test_recordType_interfaceType_record() async {
    await assertNoErrorsInCode('''
void f((int,)? x) {
  if (x case Record _) {}
}
''');
  }

  test_refutable_pattern_castPattern_match() async {
    await assertNoErrorsInCode('''
void f(num x) {
  if (x case _ as int) {}
}
''');
  }

  test_refutable_pattern_castPattern_notMatch() async {
    await assertErrorsInCode('''
void f(String x) {
  if (x case _ as int) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 37, 3),
    ]);
  }

  test_refutable_pattern_declaredVariablePattern_match() async {
    await assertErrorsInCode('''
void f(num x) {
  if (x case int a) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
  }

  test_refutable_pattern_declaredVariablePattern_notMatch() async {
    await assertErrorsInCode('''
void f(String x) {
  if (x case int a) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 3),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
  }

  test_refutable_pattern_listPattern_match() async {
    await assertNoErrorsInCode('''
void f(List<num> x) {
  if (x case <int>[]) {}
}
''');
  }

  test_refutable_pattern_listPattern_notMatch() async {
    await assertErrorsInCode('''
void f(int x) {
  if (x case <int>[]) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 29, 7),
    ]);
  }

  test_refutable_pattern_mapPattern_match() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  if (x case <int, String>{0: _}) {}
}
''');
  }

  test_refutable_pattern_mapPattern_notMatch() async {
    await assertErrorsInCode('''
void f(int x) {
  if (x case <int, String>{0: _}) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 29, 19),
    ]);
  }

  test_refutable_pattern_objectPattern_match() async {
    await assertNoErrorsInCode('''
void f(num x) {
  if (x case int()) {}
}
''');
  }

  test_refutable_pattern_objectPattern_notMatch() async {
    await assertErrorsInCode('''
void f(String x) {
  if (x case int()) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 3),
    ]);
  }

  test_refutable_pattern_reportPattern_match() async {
    await assertErrorsInCode('''
void f((int,) x) {
  switch (x) {
    case (int f,):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 48, 1),
    ]);
  }

  test_refutable_pattern_reportPattern_notMatch() async {
    await assertErrorsInCode('''
void f((int,) x) {
  switch (x) {
    case (int f1, int f2):
      break;
  }
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 43, 16),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 48, 2),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 56, 2),
    ]);
  }

  test_refutable_pattern_wildcard_match() async {
    await assertNoErrorsInCode('''
void f(num x) {
  if (x case int _) {}
}
''');
  }

  test_refutable_pattern_wildcard_notMatch() async {
    await assertErrorsInCode('''
void f(String x) {
  if (x case int _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 3),
    ]);
  }

  test_requiredNull_matchedNotNullable() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case Null _) {}
}

class A {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 4),
    ]);
  }

  test_requiredNull_matchedNotNullable_functionType() async {
    await assertErrorsInCode('''
void f(void Function() x) {
  if (x case Null _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 41, 4),
    ]);
  }

  test_requiredNull_matchedNotNullable_interfaceType_object() async {
    await assertErrorsInCode('''
void f(Object x) {
  if (x case Null _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 32, 4),
    ]);
  }

  test_requiredNull_matchedNotNullable_typeParameterType() async {
    await assertErrorsInCode('''
void f<T extends num>(T x) {
  if (x case Null _) {}
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 42, 4),
    ]);
  }

  test_requiredNull_matchedNullable_dynamicType() async {
    await assertNoErrorsInCode('''
void f(dynamic x) {
  if (x case Null _) {}
}
''');
  }

  test_requiredNull_matchedNullable_functionType() async {
    await assertNoErrorsInCode('''
void f(void Function()? x) {
  if (x case Null _) {}
}
''');
  }

  test_requiredNull_matchedNullable_interfaceType() async {
    await assertNoErrorsInCode('''
void f(A? x) {
  if (x case Null _) {}
}

class A {}
''');
  }

  test_requiredNull_matchedNullable_typeParameterType_implicitBound() async {
    await assertNoErrorsInCode('''
void f<T>(T x) {
  if (x case Null _) {}
}
''');
  }

  // TODO(scheglov): We should report that `B?` should be replaced with `B`.
  test_requiredNullable_matchedNotNullable_match() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case B? _) {}
}

final class A {}
final class B extends A {}
''');
  }

  /// Check that nullable does not prevent reporting the warning.
  test_requiredNullable_matchedNotNullable_notMatch() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case B? _) {}
}

final class A {}
final class B {}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 27, 2),
    ]);
  }

  test_requiredNullable_matchedNull() async {
    await assertNoErrorsInCode('''
void f(Null x) {
  if (x case A? _) {}
}

final class A {}
''');
  }

  /// They match only because both can be `Null`.
  /// Otherwise, two unrelated final classes cannot match.
  test_requiredNullable_matchedNullable() async {
    await assertNoErrorsInCode('''
void f(A? x) {
  if (x case B? _) {}
}

final class A {}
final class B {}
''');
  }
}

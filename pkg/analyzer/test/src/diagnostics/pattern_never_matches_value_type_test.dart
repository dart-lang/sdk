// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternNeverMatchesValueTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternNeverMatchesValueTypeTest extends PubPackageResolutionTest {
  test_functionType_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case int _) {}
//           ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'void Function()' can never match the required type 'int'.
}
''');
  }

  test_functionType_interfaceType_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case Function _) {}
}
''');
  }

  test_functionType_interfaceType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case Object _) {}
}
''');
  }

  test_functionType_interfaceType_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case Object? _) {}
}
''');
  }

  test_functionType_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case (int,) _) {}
//           ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'void Function()' can never match the required type '(int,)'.
}
''');
  }

  test_functionTypeQuestion_interfaceType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function()? x) {
  if (x case Object _) {}
}
''');
  }

  test_functionTypeQuestion_interfaceType_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function()? x) {
  if (x case Object? _) {}
}
''');
  }

  test_interfaceType2_generic_argumentsMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<A> x) {
  if (x case List<B> _) {}
}

final class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_generic_argumentsNotMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<A> x) {
  if (x case List<B> _) {}
//           ^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'List<A>' can never match the required type 'List<B>'.
}

final class A {}
final class B {}
''');
  }

  test_interfaceType2_matchedDouble_requiredInt() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedExtensionType_requiredExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case A _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedExtensionType_requiredRepresentation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case int _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedExtensionTypeUnrelated_requiredFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case C _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'C'.
}

extension type A(B _) {}

class B {}

final class C {}
''');
  }

  test_interfaceType2_matchedFinal_enumSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

final class A {}
final class A2 extends A {}
final class A3 implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneExtendsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends R implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneImplementsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A implements R {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_hasSubtypes_oneImplementsRequired2() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

final class A {}
final class A2 extends A with R {}
mixin class R {}
''');
  }

  test_interfaceType2_matchedFinal_it_implementsGenericRequired_isGeneric_argumentCouldMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(A<T> x) {
  if (x case R<int> _) {}
}

final class A<T> extends R<T> {}
class R<T> {}
''');
  }

  test_interfaceType2_matchedFinal_it_implementsGenericRequired_notGeneric_differentArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R<int> _) {}
//           ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R<int>'.
}

final class A extends R<num> {}
class R<T> {}
''');
  }

  test_interfaceType2_matchedFinal_itImplementsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

final class A implements R {}
class R {}
''');
  }

  test_interfaceType2_matchedFinal_itMixesRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

final class A extends Object with R {}
mixin class R {}
''');
  }

  test_interfaceType2_matchedFinal_requiredFutureOrIt() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}

void f(A x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFinal_requiredFutureOrOther() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}
class B {}

void f(A x) {
  if (x case FutureOr<B> _) {}
//           ^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'FutureOr<B>'.
}
''');
  }

  test_interfaceType2_matchedFinal_requiredUnrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

final class A {}
class R {}
''');
  }

  test_interfaceType2_matchedFutureFinal_requiredFutureOrIt() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}

void f(Future<A> x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredFutureIt() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}

void f(FutureOr<A> x) {
  if (x case Future<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredFutureOrIt() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}

void f(FutureOr<A> x) {
  if (x case FutureOr<A> _) {}
}
''');
  }

  test_interfaceType2_matchedFutureOrFinal_requiredIt() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

final class A {}
class B {}

void f(FutureOr<A> x) {
  if (x case B _) {}
}
''');
  }

  test_interfaceType2_matchedInt_requiredDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case double _) {}
}
''');
  }

  test_interfaceType2_matchedObject_requiredClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case A _) {}
}

class A {}
''');
  }

  test_interfaceType2_matchedObject_requiredFinalClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedObjectQuestion_requiredClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case A _) {}
}

class A {}
''');
  }

  test_interfaceType2_matchedObjectQuestion_requiredFinalClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int _) {}
}
''');
  }

  test_interfaceType2_matchedRepresentation_requiredExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case A _) {}
}

extension type A(int _) {}
''');
  }

  test_interfaceType2_matchedSealed_enumSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case M _) {}
}

sealed class A {}
mixin M implements A {}
''');
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_noneImplementsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

sealed class A {}
final class A2 extends A {}
final class A3 implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_noneImplementsRequired2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

sealed class A {}
sealed class A2 extends A {}
final class A3 implements A {}
class R {}
''');
  }

  test_interfaceType2_matchedSealed_onlyFinalSubtypes_oneImplementsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

sealed class A {}
final class A2 extends A implements R {}
class R {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case A _) {}
}

final class A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf_generic_argumentsMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<B> x) {
  if (x case A<C> _) {}
}

final class A<T> {}
final class B {}
final class C extends B {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSelf_generic_argumentsNotMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<B> x) {
  if (x case A<C> _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A<B>' can never match the required type 'A<C>'.
}

final class A<T> {}
final class B {}
final class C {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(B x) {
  if (x case A _) {}
}

final class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSubtype_generic_argumentsNotMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(B x) {
  if (x case A<D> _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'B' can never match the required type 'A<D>'.
}

final class A<T> {}
final class B extends A<C> {}
final class C {}
final class D {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case B _) {}
}

class A {}
final class B extends A {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_argumentsMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<C> x) {
  if (x case B _) {}
}

class A<T> {}
final class B extends A<C> {}
final class C {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_argumentsNotMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<D> x) {
  if (x case B _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A<D>' can never match the required type 'B'.
}

class A<T> {}
final class B extends A<C> {}
final class C {}
final class D {}
''');
  }

  test_interfaceType2_requiredFinal_matchedSupertype_generic_differentArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<num> x) {
  if (x case B _) {}
}

class A<T> {}
final class B extends A<int> {}
''');
  }

  test_interfaceType2_requiredFinal_matchedUnrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case B _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'B'.
}

class A {}
final class B {}
''');
  }

  test_interfaceType2_requiredSealed_hasNonFinalSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

class A {}
sealed class R {}
final class R1 extends R {}
final class R2 extends R {}
''');
  }

  test_interfaceType2_requiredSealed_onlyFinalSubtypes_oneImplementsMatched() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case void Function() _) {}
//           ^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'int' can never match the required type 'void Function()'.
}
''');
  }

  test_interfaceType_functionType_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Function x) {
  if (x case void Function() _) {}
}
''');
  }

  test_interfaceType_functionType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case void Function() _) {}
}
''');
  }

  test_interfaceType_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case (A,) _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type '(A,)'.
}

class A {}
''');
  }

  test_interfaceType_recordType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case (int,) _) {}
}
''');
  }

  test_interfaceType_recordType_record() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Record x) {
  if (x case (int,) _) {}
}
''');
  }

  test_matchedEnum_requiredDifferentEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

enum A { v }
enum R { v }
''');
  }

  test_matchedEnum_requiredNotEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R'.
}

enum A { v }
class R {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

enum A implements R { v }
class R {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_rightTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R<num> _) {}
}

enum A implements R<int> { v }
class R<T> {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_rightTypeArguments2() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R<int> _) {}
//           ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'R<int>'.
}

enum A implements R<num> { v }
class R<T> {}
''');
  }

  test_matchedEnum_requiredNotEnum_implemented_generic_wrongTypeArguments2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R<String> _) {}
//           ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A<dynamic>' can never match the required type 'R<String>'.
}

enum A<T> implements R<T> {
  v1<int>(),
  v2<double>(),
}

class R<T> {}
''');
  }

  test_matchedEnum_requiredNotEnum_mixed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case R _) {}
}

enum A with R { v }
mixin R {}
''');
  }

  test_matchedEnum_requiredSameEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(E? x) {
  if (x case E _) {}
}

enum E { v }
''');
  }

  test_matchedEnum_requiredSameEnum_generic_hasValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(E<T>? x) {
  if (x case E<num> _) {}
}

enum E<T> { v<int>() }
''');
  }

  test_matchedEnum_requiredSameEnum_generic_noValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(E<T>? x) {
  if (x case E<String> _) {}
//           ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'E<T>?' can never match the required type 'E<String>'.
}

enum E<T> { v1<int>(), v2<double>() }
''');
  }

  test_matchedFutureOrRecord_requiredFutureRecord_match() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case Future<(int,)> _) {}
}
''');
  }

  test_matchedFutureOrRecord_requiredFutureRecord_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case Future<(String,)> _) {}
//           ^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'FutureOr<(int,)>' can never match the required type 'Future<(String,)>'.
}
''');
  }

  test_matchedFutureOrRecord_requiredRecord_match() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case (int,) _) {}
}
''');
  }

  test_matchedFutureOrRecord_requiredRecord_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(FutureOr<(int,)> x) {
  if (x case (String,) _) {}
//           ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'FutureOr<(int,)>' can never match the required type '(String,)'.
}
''');
  }

  test_matchedFutureRecord_requiredFutureOrRecord_match() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(Future<(int,)> x) {
  if (x case FutureOr<(int,)> _) {}
}
''');
  }

  test_matchedFutureRecord_requiredFutureOrRecord_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f(Future<(int,)> x) {
  if (x case FutureOr<(String,)> _) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'Future<(int,)>' can never match the required type 'FutureOr<(String,)>'.
}
''');
  }

  test_matchedNull_requiredNotNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  if (x case A _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type 'Null' can never match the required type 'A'.
//                ^^
// [diag.deadCode] Dead code.
}

class A {}
''');
  }

  test_matchedNull_requiredNull() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  if (x case Null _) {}
}
''');
  }

  test_matchedNull_requiredObject() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  if (x case Object _) {}
//           ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'Null' can never match the required type 'Object'.
//                     ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_matchedRecord_requiredFutureOrRecord_match() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f((int,) x) {
  if (x case FutureOr<(int,)> _) {}
}
''');
  }

  test_matchedRecord_requiredFutureOrRecord_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void f((int,) x) {
  if (x case FutureOr<(String,)> _) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(int,)' can never match the required type 'FutureOr<(String,)>'.
}
''');
  }

  test_recordType2_named_differentCount() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int f1,}) x) {
  if (x case ({int f1, int f2,}) _) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int f1})' can never match the required type '({int f1, int f2})'.
}
''');
  }

  test_recordType2_named_differentNames() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int a, int b}) x) {
  if (x case ({int f1, int f2,}) _) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int a, int b})' can never match the required type '({int f1, int f2})'.
}
''');
  }

  test_recordType2_named_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({A f1,}) x) {
  if (x case ({R f1,}) _) {}
//           ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({A f1})' can never match the required type '({R f1})'.
}

final class A {}
class R {}
''');
  }

  test_recordType2_positional_canMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((A,) x) {
  if (x case (B,) _) {}
}

class A {}
class B {}
''');
  }

  test_recordType2_positional_differentCount() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) x) {
  if (x case (int, String) _) {}
//           ^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(int,)' can never match the required type '(int, String)'.
}
''');
  }

  test_recordType2_positional_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((A,) x) {
  if (x case (R,) _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(A,)' can never match the required type '(R,)'.
}

final class A {}
class R {}
''');
  }

  test_recordType_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) x) {
  if (x case void Function() _) {}
//           ^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(int,)' can never match the required type 'void Function()'.
}
''');
  }

  test_recordType_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((A,) x) {
  if (x case A _) {}
//           ^
// [diag.patternNeverMatchesValueType] The matched value type '(A,)' can never match the required type 'A'.
}

class A {}
''');
  }

  test_recordType_interfaceType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,)? x) {
  if (x case Object _) {}
}
''');
  }

  test_recordType_interfaceType_record() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,)? x) {
  if (x case Record _) {}
}
''');
  }

  test_refutable_pattern_castPattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case _ as int) {}
}
''');
  }

  test_refutable_pattern_castPattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String x) {
  if (x case _ as int) {}
//                ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'String' can never match the required type 'int'.
}
''');
  }

  test_refutable_pattern_declaredVariablePattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case int a) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_refutable_pattern_declaredVariablePattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String x) {
  if (x case int a) {}
//           ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'String' can never match the required type 'int'.
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_refutable_pattern_listPattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<num> x) {
  if (x case <int>[]) {}
}
''');
  }

  test_refutable_pattern_listPattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case <int>[]) {}
//           ^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'int' can never match the required type 'List<int>'.
}
''');
  }

  test_refutable_pattern_mapPattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case <int, String>{0: _}) {}
}
''');
  }

  test_refutable_pattern_mapPattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case <int, String>{0: _}) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'int' can never match the required type 'Map<int, String>'.
}
''');
  }

  test_refutable_pattern_objectPattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case int()) {}
}
''');
  }

  test_refutable_pattern_objectPattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String x) {
  if (x case int()) {}
//           ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'String' can never match the required type 'int'.
}
''');
  }

  test_refutable_pattern_reportPattern_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) x) {
  switch (x) {
    case (int f,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'f' isn't used.
      break;
  }
}
''');
  }

  test_refutable_pattern_reportPattern_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) x) {
  switch (x) {
    case (int f1, int f2):
//       ^^^^^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(int,)' can never match the required type '(Object?, Object?)'.
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'f1' isn't used.
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'f2' isn't used.
      break;
  }
}
''');
  }

  test_refutable_pattern_wildcard_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case int _) {}
}
''');
  }

  test_refutable_pattern_wildcard_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String x) {
  if (x case int _) {}
//           ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'String' can never match the required type 'int'.
}
''');
  }

  test_requiredNull_matchedNotNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case Null _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'Null'.
//                   ^^
// [diag.deadCode] Dead code.
}

class A {}
''');
  }

  test_requiredNull_matchedNotNullable_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case Null _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'void Function()' can never match the required type 'Null'.
//                   ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_requiredNull_matchedNotNullable_interfaceType_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case Null _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'Object' can never match the required type 'Null'.
//                   ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_requiredNull_matchedNotNullable_typeParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T x) {
  if (x case Null _) {}
//           ^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'T' can never match the required type 'Null'.
//                   ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_requiredNull_matchedNullable_dynamicType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  if (x case Null _) {}
}
''');
  }

  test_requiredNull_matchedNullable_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function()? x) {
  if (x case Null _) {}
}
''');
  }

  test_requiredNull_matchedNullable_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A? x) {
  if (x case Null _) {}
}

class A {}
''');
  }

  test_requiredNull_matchedNullable_typeParameterType_implicitBound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x case Null _) {}
}
''');
  }

  // TODO(scheglov): We should report that `B?` should be replaced with `B`.
  test_requiredNullable_matchedNotNullable_match() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case B? _) {}
}

final class A {}
final class B extends A {}
''');
  }

  /// Check that nullable does not prevent reporting the warning.
  test_requiredNullable_matchedNotNullable_notMatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case B? _) {}
//           ^^
// [diag.patternNeverMatchesValueType] The matched value type 'A' can never match the required type 'B?'.
}

final class A {}
final class B {}
''');
  }

  test_requiredNullable_matchedNull() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  if (x case A? _) {}
}

final class A {}
''');
  }

  /// They match only because both can be `Null`.
  /// Otherwise, two unrelated final classes cannot match.
  test_requiredNullable_matchedNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A? x) {
  if (x case B? _) {}
}

final class A {}
final class B {}
''');
  }
}

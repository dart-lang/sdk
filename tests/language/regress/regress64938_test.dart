// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for http://dartbug.com/64938.
//
// A nullable type S0? is a subtype of T1 if Null is a subtype of T1 and S0
// is a subtype of T1. Null is a subtype of a nullable FutureOr, and of a
// FutureOr whose type argument is a nullable FutureOr.

import 'dart:async';

import 'package:expect/expect.dart';

class Box<T> {
  final T value;
  Box(this.value);
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
bool isA<T>(Object? o) => o is T;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
T asA<T>(Object? o) => o as T;

void check<T>(Object? o) {
  Expect.isTrue(isA<T>(o), '$o is $T');
  Expect.identical(o, asA<T>(o));
}

void checkNot<T>(Object? o) {
  Expect.isFalse(isA<T>(o), '$o is not $T');
  Expect.throws<TypeError>(() => asA<T>(o));
}

typedef IntFunction = int Function();

int one() => 1;

X? nullableIdentity<X extends Object>(X? x) => x;
X? nullableIntIdentity<X extends int>(X? x) => x;
X? nullableNullableIdentity<X extends Object?>(X? x) => x;

Type typeOf<T>() => T;
Type nullableFutureOrOf<T>() => typeOf<FutureOr<T>?>();

class NestedFutureOrField {
  FutureOr<FutureOr<String>?> field;
  NestedFutureOrField(this.field);
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
bool isNullParameter(FutureOr<FutureOr<String>?> value) => value == null;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
bool isNullField(NestedFutureOrField o) => o.field == null;

void testNullableFutureOr() {
  // Class types.
  check<Box<FutureOr<String>?>>(Box<String?>('a'));
  check<Box<FutureOr<String>?>>(Box<String?>(null));
  check<Box<FutureOr<num>?>>(Box<int?>(1));
  check<Box<FutureOr<String>?>>(Box<Future<String>?>(null));
  check<Box<FutureOr<num>?>>(Box<Future<int>?>(null));
  check<Box<FutureOr<String?>>>(Box<String?>('a'));

  // Record types.
  check<Box<FutureOr<(int,)>?>>(Box<(int,)?>((1,)));
  check<Box<FutureOr<(num,)>?>>(Box<(int,)?>(null));
  check<Box<FutureOr<(int,)?>>>(Box<(int,)?>(null));

  // Function types.
  check<Box<FutureOr<IntFunction>?>>(Box<IntFunction?>(one));
  check<Box<FutureOr<num Function()>?>>(Box<IntFunction?>(null));
  check<Box<FutureOr<IntFunction?>>>(Box<IntFunction?>(one));

  // Type parameters, compared in the return types of generic functions.
  check<FutureOr<X>? Function<X extends Object>(X?)>(nullableIdentity);
  check<FutureOr<X>? Function<X extends Object?>(X?)>(nullableNullableIdentity);

  // Controls.
  checkNot<Box<FutureOr<String>>>(Box<String?>('a'));
  checkNot<Box<FutureOr<int>?>>(Box<String?>('a'));
  checkNot<Box<FutureOr<(String,)>?>>(Box<(int,)?>(null));
  checkNot<Box<FutureOr<String Function()>?>>(Box<IntFunction?>(null));
  checkNot<FutureOr<X> Function<X extends Object>(X?)>(nullableIdentity);
}

void testNestedNullableFutureOr() {
  check<Box<FutureOr<FutureOr<String>?>>>(Box<String?>('a'));
  check<Box<FutureOr<FutureOr<String>?>>>(Box<String?>(null));
  check<Box<FutureOr<FutureOr<String?>>>>(Box<String?>('a'));
  check<Box<FutureOr<FutureOr<(int,)>?>>>(Box<(int,)?>(null));
  check<Box<FutureOr<FutureOr<IntFunction>?>>>(Box<IntFunction?>(null));
  checkNot<Box<FutureOr<FutureOr<String>>>>(Box<String?>('a'));

  // A FutureOr whose type argument is a nullable FutureOr is nullable.
  Expect.isTrue(isNullParameter(null));
  Expect.isFalse(isNullParameter('a'));
  Expect.isTrue(isNullField(NestedFutureOrField(null)));
  Expect.isFalse(isNullField(NestedFutureOrField('a')));

  // FutureOr<T>? normalizes to FutureOr<T> if T is nullable, including when
  // T is a nullable FutureOr.
  Expect.equals(
    typeOf<FutureOr<FutureOr<String>?>>(),
    nullableFutureOrOf<FutureOr<String>?>(),
  );
  Expect.equals(typeOf<FutureOr<String?>>(), nullableFutureOrOf<String?>());
}

void testNullableTypeParameter() {
  // A nullable type parameter X? is not a subtype of a type that does not
  // accept null, even if the bound of X is.
  checkNot<Object Function<X extends Object>(X?)>(nullableIdentity);
  checkNot<FutureOr<Object> Function<X extends Object>(X?)>(nullableIdentity);
  checkNot<num Function<X extends int>(X?)>(nullableIntIdentity);
  checkNot<FutureOr<num> Function<X extends int>(X?)>(nullableIntIdentity);
  check<num? Function<X extends int>(X?)>(nullableIntIdentity);
  check<Object? Function<X extends Object>(X?)>(nullableIdentity);
  check<FutureOr<num>? Function<X extends int>(X?)>(nullableIntIdentity);
}

void main() {
  testNullableFutureOr();
  testNestedNullableFutureOr();
  testNullableTypeParameter();
}

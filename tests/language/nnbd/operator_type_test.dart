// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that language operators and constructs requiring non-nullable values
// will not accept an operand with a nullable static type.
// See: https://github.com/dart-lang/language/issues/298

main() {
  nonNullable();
  potentiallyNonNullable<bool>();
  nullable();
  potentiallyNullable();
}

dynamic nonNullable() {
  // Check that a nullable expression is not allowed where a non-nullable
  // value is required.

  bool? bq = maybeNullable(true); // Prevent promotion.
  bool b = true;

  dynamic x;

  x = bq && b;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = b && bq;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = bq || b;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = b || bq;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = !bq;
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = bq ? "a" : "b";
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  if (bq) {}
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  while (bq) {}
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  do {} while (bq);
  //           ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  for (; bq;) {}
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  try {
    throw bq;
    //    ^^
    // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
    // [cfe] Can't throw a value of 'bool?' since it is neither dynamic nor non-nullable.
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = [if (bq) 1];
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  x = [for (; bq;) 1];
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>'.

  x = [...iq];
  //      ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] An expression whose value can be 'null' must be null-checked before it can be dereferenced.

  Stream<Object?> foo() async* {
    Stream<int>? sq = maybeNullable(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The type 'Stream<int>?' used in the 'for' loop must implement 'Stream<dynamic>'.

    yield* sq;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
    // [cfe] A value of type 'Stream<int>?' can't be assigned to a variable of type 'Stream<Object?>'.
  }

  foo().toList();
  C.factory();

  return x;
}

dynamic potentiallyNonNullable<BQ extends bool?>() {
  // Check that a potentially nullable expression is not allowed where
  // a non-null value is required.

  BQ bq = maybeNotNullable<BQ>(true);
  bool b = true;

  dynamic x;

  x = bq && b;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = b && bq;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = bq || b;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = b || bq;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = !bq;
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_NEGATION_EXPRESSION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = bq ? "a" : "b";
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  if (bq) {}
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  while (bq) {}
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  do {} while (bq);
  //           ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  for (; bq;) {}
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  try {
    throw bq;
    //    ^^
    // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
    // [cfe] Can't throw a value of 'BQ' since it is neither dynamic nor non-nullable.
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_EXPRESSION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = [if (bq) 1];
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  x = [for (; bq;) 1];
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool'.

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>'.

  x = [...iq];
  //      ^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] An expression whose value can be 'null' must be null-checked before it can be dereferenced.

  Stream<Object?> foo<SQ extends Stream<Object?>?>() async* {
    SQ sq = maybeNotNullable<SQ>(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The type 'Stream<Object?>?' used in the 'for' loop must implement 'Stream<dynamic>'.

    yield* sq;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
    // [cfe] A value of type 'SQ' can't be assigned to a variable of type 'Stream<Object?>'.
  }

  foo<Stream<Object?>>().toList();

  C.factory();

  return x;
}

T? maybeNullable<T>(Object value) =>
    identical(value, Object()) ? null : value as T;
T maybeNotNullable<T>(Object value) => value as T;

class C {
  C();
  factory C.factory() {
    C? cq = maybeNullable(C());
    // A factory constructor must not return `null`.
    return cq;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
    // [cfe] A value of type 'C?' can't be returned from a function with return type 'C'.
  }
}

dynamic nullable() {
  // Check places where the operand type must be *nullable*.
  // This should only generate *warnings*, not errors.
  // This is generally null-aware operations.
  int nn = 0;

  dynamic x;

  x = nn ?? 1;
  //        ^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  x = nn ??= 1;
  //         ^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  x = nn?.toRadixString(16);
  //    ^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  x = nn?..toRadixString(16);
  //    ^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  x = nn!;
  //    ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NON_NULL_ASSERTION

  List<int> nni = [1];
  x = [...?nni];
  //   ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  x = nni?[0];
  //     ^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  return x;
}

void potentiallyNullable<NN extends int?, NNI extends List<int>?>() {
  // Check places where the operand type must not be *non-nullable*.
  // See that it does allow *potentially* nullable expression.
  // This allows a potentially nullable value to be implicitly used as
  // nullable (which is a safe approximation, since it might be one,
  // and if not, it's just not null).
  NN nn = maybeNotNullable<NN>(0);

  nn ?? 1;

  nn ??= maybeNotNullable<NN>(1);

  nn?.toRadixString(16);

  nn?..toRadixString(16);

  nn!;

  NNI nni = maybeNotNullable<NNI>(<int>[1]);

  [...?nni];

  nni?[0];
}

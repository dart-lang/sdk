// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Tests that language operators and constructrs requiring non-nullable values
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

  dynamic _;

  _ = bq && b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = b && bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = bq || b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = b || bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = !bq;
  //   ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = bq ? "a" : "b";
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  if (bq) {}
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  while (bq) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  do {} while (bq);
  //           ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  for (; bq;) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  try {
    throw bq;
    //    ^^
    // [analyzer] unspecified
    // [cfe] Can't throw a value of 'bool?' since it is neither dynamic nor non-nullable.
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = [if (bq) 1];
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = [for (; bq;) 1];
  //         ^^
  // [analyzer] unspecified
  //          ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] unspecified
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'Iterable<int>?' is nullable and 'Iterable<dynamic>' isn't.

  _ = [...iq];
  //      ^
  // [cfe] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  //       ^^
  // [analyzer] unspecified

  Stream<Object?> foo() async* {
    Stream<int>? sq = maybeNullable(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] unspecified
    // [cfe] The type 'Stream<int>?' used in the 'for' loop must implement 'Stream<dynamic>' because 'Stream<int>?' is nullable and 'Stream<dynamic>' isn't.

    yield* sq;
    //     ^^
    // [analyzer] unspecified
    // [cfe] A value of type 'Stream<int>?' can't be assigned to a variable of type 'Stream<Object?>' because 'Stream<int>?' is nullable and 'Stream<Object?>' isn't.
  }

  foo().toList();
  C.factory();

  return _;
}

dynamic potentiallyNonNullable<BQ extends bool?>() {
  // Check that a potentially nullable expression is not allowed where
  // a non-null value is required.

  BQ bq = maybeNotNullable<BQ>(true);
  bool b = true;

  dynamic _;

  _ = bq && b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = b && bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = bq || b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = b || bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = !bq;
  //   ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = bq ? "a" : "b";
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  if (bq) {}
  //  ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  while (bq) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  do {} while (bq);
  //           ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  for (; bq;) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  try {
    throw bq;
    //    ^^
    // [analyzer] unspecified
    // [cfe] Can't throw a value of 'BQ' since it is neither dynamic nor non-nullable.
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = [if (bq) 1];
  //       ^^
  // [analyzer] unspecified
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  _ = [for (; bq;) 1];
  //         ^^
  // [analyzer] unspecified
  //          ^
  // [cfe] A value of type 'BQ' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] unspecified
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'Iterable<int>?' is nullable and 'Iterable<dynamic>' isn't.

  _ = [...iq];
  //      ^^
  // [analyzer] unspecified
  // [cfe] An expression whose value can be 'null' must be null-checked before it can be dereferenced.

  Stream<Object?> foo<SQ extends Stream<Object?>?>() async* {
    SQ sq = maybeNotNullable<SQ>(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] unspecified
    // [cfe] The type 'Stream<Object?>?' used in the 'for' loop must implement 'Stream<dynamic>' because 'Stream<Object?>?' is nullable and 'Stream<dynamic>' isn't.

    yield* sq;
    //     ^^
    // [analyzer] unspecified
    // [cfe] A value of type 'SQ' can't be assigned to a variable of type 'Stream<Object?>' because 'Stream<Object?>?' is nullable and 'Stream<Object?>' isn't.
  }

  foo<Stream<Object?>>().toList();

  C.factory();

  return _;
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
    // [analyzer] unspecified
    // [cfe] A value of type 'C?' can't be returned from a function with return type 'C' because 'C?' is nullable and 'C' isn't.
  }
}

dynamic nullable() {
  // Check places where the operand type must be *nullable*.
  // This should only generate *warnings*, not errors.
  // This is generally null-aware operations.
  int nn = 0;

  dynamic _;

  _ = nn ?? 1;
  //  ^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '??' has type 'int' which excludes null.

  _ = nn ??= 1;
  //  ^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '??=' has type 'int' which excludes null.

  _ = nn?.toRadixString(16);
  //  ^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '?.' has type 'int' which excludes null.

  _ = nn?..toRadixString(16);
  //  ^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '?..' has type 'int' which excludes null.

  _ = nn!;
  //  ^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '!' has type 'int' which excludes null.

  List<int> nni = [1];
  _ = [...?nni];
  //       ^^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '...?' has type 'List<int>' which excludes null.

  _ = nni?[0];
  //  ^^^
  // [analyzer] unspecified
  // [cfe] Operand of null-aware operation '?.' has type 'List<int>' which excludes null.

  return _;
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

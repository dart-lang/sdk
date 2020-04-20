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
  // [cfe] unspecified

  _ = b && bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = bq || b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = b || bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = !bq;
  //   ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = bq ? "a" : "b";
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (bq) {}
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  while (bq) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  do {} while (bq);
  //           ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  for (; bq;) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  try {
    throw bq;
    //    ^^
    // [analyzer] unspecified
    // [cfe] unspecified
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [if (bq) 1];
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [for (; bq;) 1];
  //         ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [...iq];
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Stream<Object?> foo() async* {
    Stream<int>? sq = maybeNullable(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] unspecified
    // [cfe] unspecified

    yield* sq;
    //     ^^
    // [analyzer] unspecified
    // [cfe] unspecified
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
  // [cfe] unspecified

  _ = b && bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = bq || b;
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = b || bq;
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = !bq;
  //   ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = bq ? "a" : "b";
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (bq) {}
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  while (bq) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  do {} while (bq);
  //           ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  for (; bq;) {}
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  try {
    throw bq;
    //    ^^
    // [analyzer] unspecified
    // [cfe] unspecified
  } catch (e) {}

  assert(bq);
  //     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [if (bq) 1];
  //       ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [for (; bq;) 1];
  //         ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Iterable<int>? iq = maybeNullable([1]);
  for (var v in iq) {}
  //            ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = [...iq];
  //      ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Stream<Object?> foo<SQ extends Stream<Object?>?>() async* {
    SQ sq = maybeNotNullable<SQ>(Stream<int>.fromIterable([1]));
    await for (var v in sq) {}
    //                  ^^
    // [analyzer] unspecified
    // [cfe] unspecified

    yield* sq;
    //     ^^
    // [analyzer] unspecified
    // [cfe] unspecified
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
    // [cfe] unspecified
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
  // [cfe] unspecified

  _ = nn ??= 1;
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = nn?.toRadixString(16);
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = nn?..toRadixString(16);
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = nn!;
  //  ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  List<int> nni = [1];
  _ = [...?nni];
  //       ^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  _ = nni?[0];
  //  ^^^
  // [analyzer] unspecified
  // [cfe] unspecified

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

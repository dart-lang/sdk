// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

// Test that the type arguments of object patterns are properly inferred.

import "package:expect/expect.dart";

import "../static_type_helper.dart";

sealed class B<T> {}

class C<T> extends B<T> {
  final T t;

  // Note: we use this getter to obtain values for `expectStaticType` (rather
  // than a getter returning simply `T`) to ensure that an error is reported if
  // `T` gets inferred to be `dynamic`.
  List<T> get listOfT => [t];

  C(this.t);
}

bool explicitTypeArguments(B<int> b) {
  switch (b) {
    case C<num>(listOfT: var x):
      x.expectStaticType<Exactly<List<num>>>();
      // Since C<num> isn't a subtype of B<int>, `b` is not promoted.
      b.expectStaticType<Exactly<B<int>>>();
      return true;
  }
  // No need for a `return` since the switch is exhaustive.
}

bool simpleInference(B<num> b) {
  switch (b) {
    case C(listOfT: var x):
      x.expectStaticType<Exactly<List<num>>>();
      b.expectStaticType<Exactly<C<num>>>();
      return true;
  }
  // No need for a `return` since the switch is exhaustive.
}

void inferDynamic(Object o) {
  switch (o) {
    case C(listOfT: var x, t: var t):
      x.expectStaticType<Exactly<List<dynamic>>>();
      t.isEven; // Should be ok since T is `dynamic`.
      o.expectStaticType<Exactly<C<dynamic>>>();
    default:
      Expect.fail('Match failure');
  }
}

class D<T extends num> {
  final T t;

  // Note: we use this getter to obtain values for `expectStaticType` (rather
  // than a getter returning simply `T`) to ensure that an error is reported if
  // `T` gets inferred to be `dynamic`.
  List<T> get listOfT => [t];

  D(this.t);
}

void inferBound(Object o) {
  switch (o) {
    case D(listOfT: var x):
      x.expectStaticType<Exactly<List<num>>>();
      o.expectStaticType<Exactly<D<num>>>();
    default:
      Expect.fail('Match failure');
  }
}

class E<T, U> {
  final T t;
  final U u;

  List<T> get listOfT => [t];
  List<U> get listOfU => [u];

  E(this.t, this.u);

  bool inferEnclosingTypeParameters(E<Set<U>, Set<T>> e) {
    // This test verifies that the inference logic properly distinguishes
    // between the type parameters of the enclosing class and those that are
    // part of the type of `e`.
    if (e case E(listOfT: var x, listOfU: var y)) {
      x.expectStaticType<Exactly<List<Set<U>>>>();
      y.expectStaticType<Exactly<List<Set<T>>>>();
      return true;
    }
    // No need for a `return` since the case fully covers the type of `e`.
  }
}

class F1<T extends F1<T>> {
  late final T t;

  List<T> get listOfT => [t];
}

class F2 extends F1<F2> {
  F2() {
    t = this;
  }
}

void fBounded(Object o) {
  switch (o) {
    case F1(listOfT: var x):
      x.expectStaticType<Exactly<List<F1<Object?>>>>();
      o.expectStaticType<Exactly<F1<F1<Object?>>>>();
    default:
      Expect.fail('Match failure');
  }
}

class G1<T> {
  final T t;

  List<T> get listOfT => [t];

  G1(this.t);
}

class G2<T, U extends Set<T>> extends G1<T> {
  final U u;

  List<U> get listOfU => [u];

  G2(super.t, this.u);
}

void partialInference(G1<int> g) {
  switch (g) {
    case G2(listOfT: var x, listOfU: var y):
      x.expectStaticType<Exactly<List<int>>>();
      y.expectStaticType<Exactly<List<Set<int>>>>();
      g.expectStaticType<Exactly<G2<int, Set<int>>>>();
  }
}

main() {
  explicitTypeArguments(C(0));
  simpleInference(C(0));
  inferDynamic(C(0));
  inferBound(D(0));
  E<int, String>(0, '')
      .inferEnclosingTypeParameters(E<Set<String>, Set<int>>({''}, {0}));
  fBounded(F2());
  partialInference(G2(0, {0}));
}

// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the type arguments of object patterns are properly inferred.

import "package:expect/expect.dart";

import "package:expect/static_type_helper.dart";

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

bool inferDynamic(Object o) {
  switch (o) {
    case C(listOfT: var x, t: var t):
      x.expectStaticType<Exactly<List<dynamic>>>();
      t.isEven; // Should be ok since T is `dynamic`.
      o.expectStaticType<Exactly<C<dynamic>>>();
      return true;
    default:
      return false;
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

bool inferBound(Object o) {
  switch (o) {
    case D(listOfT: var x):
      x.expectStaticType<Exactly<List<num>>>();
      o.expectStaticType<Exactly<D<num>>>();
      return true;
    default:
      return false;
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

bool fBounded(Object o) {
  switch (o) {
    case F1(listOfT: var x):
      x.expectStaticType<Exactly<List<F1<Object?>>>>();
      o.expectStaticType<Exactly<F1<F1<Object?>>>>();
      return true;
    default:
      return false;
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

bool partialInference(G1<int> g) {
  switch (g) {
    case G2(listOfT: var x, listOfU: var y):
      x.expectStaticType<Exactly<List<int>>>();
      y.expectStaticType<Exactly<List<Set<int>>>>();
      g.expectStaticType<Exactly<G2<int, Set<int>>>>();
      return true;
    default:
      return false;
  }
}

class H1<T, U> {
  final T t;
  final U u;

  List<T> get listOfT => [t];
  List<U> get listOfU => [u];

  H1(this.t, this.u);
}

typedef H2<S extends num> = H1<S, String>;

bool typedefResolvingToInterfaceType(Object o) {
  switch (o) {
    case H2(listOfT: var x, listOfU: var y):
      x.expectStaticType<Exactly<List<num>>>();
      y.expectStaticType<Exactly<List<String>>>();
      o.expectStaticType<Exactly<H2<num>>>();
      return true;
    default:
      return false;
  }
}

typedef I<S extends num> = String Function(S);

bool typedefResolvingToFunctionType(Object o) {
  switch (o) {
    case I():
      o.expectStaticType<Exactly<I<num>>>();
      return true;
    default:
      return false;
  }
}

main() {
  Expect.isTrue(explicitTypeArguments(C(0)));
  Expect.isTrue(simpleInference(C(0)));
  Expect.isTrue(inferDynamic(C(0)));
  Expect.isFalse(inferDynamic(0));
  Expect.isTrue(inferBound(D(0)));
  Expect.isFalse(inferBound(0));
  Expect.isTrue(E<int, String>(0, '')
      .inferEnclosingTypeParameters(E<Set<String>, Set<int>>({''}, {0})));
  Expect.isTrue(fBounded(F2()));
  Expect.isFalse(fBounded(0));
  Expect.isTrue(partialInference(G2(0, {0})));
  Expect.isFalse(partialInference(G1(0)));
  Expect.isTrue(typedefResolvingToInterfaceType(H1<int, String>(0, '')));
  Expect.isTrue(typedefResolvingToInterfaceType(H1<num, String>(0, '')));
  Expect.isFalse(typedefResolvingToInterfaceType(H1<Object, String>(0, '')));
  Expect.isTrue(typedefResolvingToFunctionType((Object o) => o.toString()));
  Expect.isTrue(typedefResolvingToFunctionType((num n) => n.toString()));
  Expect.isFalse(typedefResolvingToFunctionType((int i) => i.toString()));
}

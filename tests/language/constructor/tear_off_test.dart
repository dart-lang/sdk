// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "../static_type_helper.dart";

// Test tearing off of constructors.

// Non-generic classes.
class NGen {
  final int x;
  const NGen(this.x);
  const NGen.named(this.x);
}

class NGenRedir {
  final int x;
  const NGenRedir(int x) : this._(x);
  const NGenRedir.named(int x) : this._(x);
  const NGenRedir._(this.x);
}

class NFac implements NFacRedir {
  final int x;
  factory NFac(int x) => NFac._(x);
  factory NFac.named(int x) => NFac._(x);
  const NFac._(this.x);
}

class NFacRedir {
  const factory NFacRedir(int x) = NFac._;
  const factory NFacRedir.named(int x) = NFac._;
}

// Generic classes.
class GGen<T> {
  final int x;
  const GGen(this.x);
  const GGen.named(this.x);
}

class GGenRedir<T> {
  final int x;
  const GGenRedir(int x) : this._(x);
  const GGenRedir.named(int x) : this._(x);
  const GGenRedir._(this.x);
}

class GFac<T> implements GFacRedir<T> {
  final int x;
  factory GFac(int x) => GFac._(x);
  factory GFac.named(int x) => GFac._(x);
  const GFac._(this.x);
}

class GFacRedir<T> {
  const factory GFacRedir(int x) = GFac._;
  const factory GFacRedir.named(int x) = GFac._;
}

class Optional<T> {
  final int x;
  final int y;
  const Optional([this.x = 0, this.y = 0]);
  const Optional.named({this.x = 0, this.y = 0});
}

void main() {
  // Static types.
  NGen.new.expectStaticType<Exactly<NGen Function(int)>>();
  NGen.named.expectStaticType<Exactly<NGen Function(int)>>();
  NGenRedir.new.expectStaticType<Exactly<NGenRedir Function(int)>>();
  NGenRedir.named.expectStaticType<Exactly<NGenRedir Function(int)>>();
  NFac.new.expectStaticType<Exactly<NFac Function(int)>>();
  NFac.named.expectStaticType<Exactly<NFac Function(int)>>();
  NFacRedir.new.expectStaticType<Exactly<NFacRedir Function(int)>>();
  NFacRedir.named.expectStaticType<Exactly<NFacRedir Function(int)>>();

  GGen.new.expectStaticType<Exactly<GGen<T> Function<T>(int)>>();
  GGen.named.expectStaticType<Exactly<GGen<T> Function<T>(int)>>();
  GGenRedir.new.expectStaticType<Exactly<GGenRedir<T> Function<T>(int)>>();
  GGenRedir.named.expectStaticType<Exactly<GGenRedir<T> Function<T>(int)>>();
  GFac.new.expectStaticType<Exactly<GFac<T> Function<T>(int)>>();
  GFac.named.expectStaticType<Exactly<GFac<T> Function<T>(int)>>();
  GFacRedir.new.expectStaticType<Exactly<GFacRedir<T> Function<T>(int)>>();
  GFacRedir.named.expectStaticType<Exactly<GFacRedir<T> Function<T>(int)>>();

  GGen<int>.new.expectStaticType<Exactly<GGen<int> Function(int)>>();
  GGen<int>.named.expectStaticType<Exactly<GGen<int> Function(int)>>();
  GGenRedir<int>.new.expectStaticType<Exactly<GGenRedir<int> Function(int)>>();
  GGenRedir<int>
      .named
      .expectStaticType<Exactly<GGenRedir<int> Function(int)>>();
  GFac<int>.new.expectStaticType<Exactly<GFac<int> Function(int)>>();
  GFac<int>.named.expectStaticType<Exactly<GFac<int> Function(int)>>();
  GFacRedir<int>.new.expectStaticType<Exactly<GFacRedir<int> Function(int)>>();
  GFacRedir<int>
      .named
      .expectStaticType<Exactly<GFacRedir<int> Function(int)>>();

  context<GGen<int> Function(int)>(
      GGen.new..expectStaticType<Exactly<GGen<int> Function(int)>>());
  context<GGen<int> Function(int)>(
      GGen.named..expectStaticType<Exactly<GGen<int> Function(int)>>());
  context<GGenRedir<int> Function(int)>(
      GGenRedir.new..expectStaticType<Exactly<GGenRedir<int> Function(int)>>());
  context<GGenRedir<int> Function(int)>(GGenRedir.named
    ..expectStaticType<Exactly<GGenRedir<int> Function(int)>>());
  context<GFac<int> Function(int)>(
      GFac.new..expectStaticType<Exactly<GFac<int> Function(int)>>());
  context<GFac<int> Function(int)>(
      GFac.named..expectStaticType<Exactly<GFac<int> Function(int)>>());
  context<GFacRedir<int> Function(int)>(
      GFacRedir.new..expectStaticType<Exactly<GFacRedir<int> Function(int)>>());
  context<GFacRedir<int> Function(int)>(GFacRedir.named
    ..expectStaticType<Exactly<GFacRedir<int> Function(int)>>());

  context<Optional<int> Function()>(Optional.new
    ..expectStaticType<Exactly<Optional<int> Function([int, int])>>());
  context<Optional<int> Function()>(Optional.named
    ..expectStaticType<Exactly<Optional<int> Function({int x, int y})>>());

  // Check that tear-offs are canonicalized where possible
  // (where not instantiates with a non-constant type).

  void test<T>(Object? f1, [Object? same, Object? notSame]) {
    Expect.type<T>(f1);
    if (same != null) Expect.identical(f1, same);
    if (notSame != null) Expect.notEquals(f1, notSame);
  }

  test<NGen Function(int)>(NGen.new, NGen.new, NGen.named);
  test<NGen Function(int)>(NGen.named, NGen.named);
  test<NGenRedir Function(int)>(NGenRedir.new, NGenRedir.new, NGenRedir.named);
  test<NGenRedir Function(int)>(NGenRedir.named, NGenRedir.named);
  test<NFac Function(int)>(NFac.new, NFac.new, NFac.named);
  test<NFac Function(int)>(NFac.named, NFac.named);
  test<NFacRedir Function(int)>(NFacRedir.new, NFacRedir.new, NFacRedir.named);
  test<NFacRedir Function(int)>(NFacRedir.named, NFacRedir.named);

  // Generic class constructors torn off as generic functions.
  test<GGen<T> Function<T>(int)>(GGen.new, GGen.new, GGen.named);
  test<GGen<T> Function<T>(int)>(GGen.named, GGen.named);
  test<GGenRedir<T> Function<T>(int)>(
      GGenRedir.new, GGenRedir.new, GGenRedir.named);
  test<GGenRedir<T> Function<T>(int)>(GGenRedir.named, GGenRedir.named);
  test<GFac<T> Function<T>(int)>(GFac.new, GFac.new, GFac.named);
  test<GFac<T> Function<T>(int)>(GFac.named, GFac.named);
  test<GFacRedir<T> Function<T>(int)>(
      GFacRedir.new, GFacRedir.new, GFacRedir.named);
  test<GFacRedir<T> Function<T>(int)>(GFacRedir.named, GFacRedir.named);

  // Generic class constructors torn off with explicit instantiation
  // to constant type.
  test<GGen<int> Function(int)>(GGen<int>.new, GGen<int>.new, GGen<int>.named);
  test<GGen<int> Function(int)>(GGen<int>.named, GGen<int>.named);
  test<GGenRedir<int> Function(int)>(
      GGenRedir<int>.new, GGenRedir<int>.new, GGenRedir<int>.named);
  test<GGenRedir<int> Function(int)>(
      GGenRedir<int>.named, GGenRedir<int>.named);
  test<GFac<int> Function(int)>(GFac<int>.new, GFac<int>.new, GFac<int>.named);
  test<GFac<int> Function(int)>(GFac<int>.named, GFac<int>.named);
  test<GFacRedir<int> Function(int)>(
      GFacRedir<int>.new, GFacRedir<int>.new, GFacRedir<int>.named);
  test<GFacRedir<int> Function(int)>(
      GFacRedir<int>.named, GFacRedir<int>.named);

  // Not equal if *different* instantiations.
  Expect.notEquals(GGen<int>.new, GGen<num>.new);
  Expect.notEquals(GGen<int>.named, GGen<num>.named);
  Expect.notEquals(GGenRedir<int>.new, GGenRedir<num>.new);
  Expect.notEquals(GGenRedir<int>.named, GGenRedir<num>.named);
  Expect.notEquals(GFac<int>.new, GFac<num>.new);
  Expect.notEquals(GFac<int>.named, GFac<num>.named);
  Expect.notEquals(GFacRedir<int>.new, GFacRedir<num>.new);
  Expect.notEquals(GFacRedir<int>.named, GFacRedir<num>.named);

  // Tear off with implicit instantiation to the same constant type.
  void testImplicit<T>(T f1, T f2) {
    Expect.identical(f1, f2);
  }

  testImplicit<GGen<int> Function(int)>(GGen.new, GGen.new);
  testImplicit<GGen<int> Function(int)>(GGen.named, GGen.named);
  testImplicit<GGenRedir<int> Function(int)>(GGenRedir.new, GGenRedir.new);
  testImplicit<GGenRedir<int> Function(int)>(GGenRedir.named, GGenRedir.named);
  testImplicit<GFac<int> Function(int)>(GFac.new, GFac.new);
  testImplicit<GFac<int> Function(int)>(GFac.named, GFac.named);
  testImplicit<GFacRedir<int> Function(int)>(GFacRedir.new, GFacRedir.new);
  testImplicit<GFacRedir<int> Function(int)>(GFacRedir.named, GFacRedir.named);

  // Using a type variable, not a constant type expression.
  // Canonicalization is unspecified, but equality holds.
  (<T>() {
    // Tear off with explicit instantation to the same non-constant type.
    Expect.equals(GGen<T>.new, GGen<T>.new);
    Expect.equals(GGen<T>.named, GGen<T>.named);
    Expect.equals(GGenRedir<T>.new, GGenRedir<T>.new);
    Expect.equals(GGenRedir<T>.named, GGenRedir<T>.named);
    Expect.equals(GFac<T>.new, GFac<T>.new);
    Expect.equals(GFac<T>.named, GFac<T>.named);
    Expect.equals(GFacRedir<T>.new, GFacRedir<T>.new);
    Expect.equals(GFacRedir<T>.named, GFacRedir<T>.named);

    // Tear off with implicit instantiation to the same non-constant type.
    void testImplicit2<T>(T f1, T f2) {
      Expect.equals(f1, f2);
    }

    testImplicit2<GGen<T> Function(int)>(GGen.new, GGen.new);
    testImplicit2<GGen<T> Function(int)>(GGen.named, GGen.named);
    testImplicit2<GGenRedir<T> Function(int)>(GGenRedir.new, GGenRedir.new);
    testImplicit2<GGenRedir<T> Function(int)>(GGenRedir.named, GGenRedir.named);
    testImplicit2<GFac<T> Function(int)>(GFac.new, GFac.new);
    testImplicit2<GFac<T> Function(int)>(GFac.named, GFac.named);
    testImplicit2<GFacRedir<T> Function(int)>(GFacRedir.new, GFacRedir.new);
    testImplicit2<GFacRedir<T> Function(int)>(GFacRedir.named, GFacRedir.named);
  }<int>());
}

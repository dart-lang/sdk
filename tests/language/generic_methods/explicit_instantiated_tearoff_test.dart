// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "../static_type_helper.dart";

// Tests that generic methods can be torn off with explicit instantiation.

R toplevel<R, T>(T value, [T? other]) => value as R;

class C {
  static R staticMethod<R, T>(T value, [T? other]) => value as R;
  R instanceMethod<R, T>(T value, [T? other]) => value as R;

  void tearOffsOnThis() {
    const staticTearOff = staticMethod<int, String>;
    staticMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    instanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    this.instanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();

    Expect.identical(staticMethod<int, String>, staticTearOff);

    Expect.equals(
        instanceMethod<int, String>, this.instanceMethod<int, String>);
  }
}

mixin M on C {
  static R staticMethod<R, T>(T value, [T? other]) => value as R;
  R mixinInstanceMethod<R, T>(T value, [T? other]) => value as R;

  void mixinTearOffsOnThis() {
    const staticTearOff = staticMethod<int, String>;
    staticMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    mixinInstanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    this.mixinInstanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();

    Expect.identical(staticMethod<int, String>, staticTearOff);

    Expect.equals(mixinInstanceMethod<int, String>,
        this.mixinInstanceMethod<int, String>);
  }
}

extension E on C {
  static R staticMethod<R, T>(T value, [T? other]) => value as R;
  R extInstanceMethod<R, T>(T value, [T? other]) => value as R;

  void extensionTearOffsOnThis() {
    const staticTearOff = staticMethod<int, String>;
    staticMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    extInstanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    this.extInstanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    Expect.identical(staticMethod<int, String>, staticTearOff);
    // Extension instance methods do not specify equality.
  }
}

class D extends C with M {
  void tearOffsOnSuper() {
    super.instanceMethod<int, String>
        .expectStaticType<Exactly<int Function(String, [String?])>>();
    Expect.equals(
        super.instanceMethod<int, String>, super.instanceMethod<int, String>);
  }
}

void main() {
  var o = D();
  R local<R, T>(T value, [T? other]) => value as R;

  // Check that some tear-offs are constant.
  const topTearOff = toplevel<int, String>;
  const staticTearOff = C.staticMethod<int, String>;
  const mixinStaticTearOff = M.staticMethod<int, String>;
  const extensionStaticTearOff = E.staticMethod<int, String>;

  // Check that the tear-offs have the correct static type.

  toplevel<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  C.staticMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  M.staticMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  E.staticMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  o.instanceMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  o.mixinInstanceMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  o.extInstanceMethod<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();
  local<int, String>
      .expectStaticType<Exactly<int Function(String, [String?])>>();

  // Check that the tear-offs are canonicalized where possible.
  Expect.identical(toplevel<int, String>, topTearOff);
  Expect.identical(C.staticMethod<int, String>, staticTearOff);
  Expect.identical(M.staticMethod<int, String>, mixinStaticTearOff);
  Expect.identical(E.staticMethod<int, String>, extensionStaticTearOff);

  // Instantiated local methods may or may not be equal.
  // (Specification makes no promise about equality.).

  // But not for instance method tear-off.
  // Specification requires equality.
  Expect.equals(o.instanceMethod<int, String>, o.instanceMethod<int, String>);
  Expect.equals(
      o.mixinInstanceMethod<int, String>, o.mixinInstanceMethod<int, String>);

  // Instantiated extension methods do not specify equality.

  // And not canonicalized where they shouldn't (different types).
  Expect.notEquals(toplevel<int, String>, toplevel<num, String>);
  Expect.notEquals(C.staticMethod<int, String>, C.staticMethod<num, String>);
  Expect.notEquals(local<int, String>, local<num, String>);
  Expect.notEquals(
      o.instanceMethod<int, String>, o.instanceMethod<num, String>);

  (<T>() {
    // Not canonicalized if any type is non-constant.
    // Toplevel, static and instance members are still equal
    // if types are "the same".
    // (Current implementations do not implement that).
    Expect.equals(toplevel<T, String>, toplevel<T, String>);
    Expect.equals(C.staticMethod<T, String>, C.staticMethod<T, String>);
    Expect.equals(M.staticMethod<T, String>, M.staticMethod<T, String>);
    Expect.equals(E.staticMethod<T, String>, E.staticMethod<T, String>);
    Expect.equals(toplevel<int, T>, toplevel<int, T>);
    Expect.equals(C.staticMethod<int, T>, C.staticMethod<int, T>);
    Expect.equals(M.staticMethod<int, T>, M.staticMethod<int, T>);
    Expect.equals(E.staticMethod<int, T>, E.staticMethod<int, T>);
  }<int>());

  o.tearOffsOnThis();
  o.tearOffsOnSuper();
  o.mixinTearOffsOnThis();
  o.extensionTearOffsOnThis();
}

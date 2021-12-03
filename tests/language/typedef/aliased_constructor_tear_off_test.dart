// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that constructor tear-offs from type aliases work and
// are canonicalized correctly

import "package:expect/expect.dart";

import "../static_type_helper.dart";

void use(Type type) {}

class C<T> {
  final T x;
  C(this.x);
  C.named(this.x);
}

typedef Special = C<int>; // Not generic. Not proper rename.
typedef Direct<T> = C<T>; // A proper rename
typedef Bounded<T extends num> = C<T>; // Not proper rename.
typedef Wrapping<T> = C<C<T>>; // Not proper rename.
typedef Extra<T, S> = C<T>; // Not proper rename.

class D<S, T> {
  D();
  D.named();
}

typedef Swapped<T, S> = D<S, T>; // Not a proper rename.

void main() {
  // Tear-offs are constant if uninstantiated
  // or if instantiated with a constant type.
  const List<Object> constructors = [
    Special.new,
    Special.named,
    Direct.new,
    Direct.named,
    Bounded.new,
    Bounded.named,
    Wrapping.new,
    Wrapping.named,
    Extra.new,
    Extra.named,
    Direct<int>.new,
    Direct<int>.named,
    Bounded<int>.new,
    Bounded<int>.named,
    Wrapping<int>.new,
    Wrapping<int>.named,
    Extra<int, int>.new,
    Extra<int, int>.named,
    const <C<int> Function(int)>[
      Direct.new,
      Direct.named,
      Bounded.new,
      Bounded.named,
    ],
    const <C<C<int>> Function(C<int>)>[
      Wrapping.new,
      Wrapping.named,
    ],
    const <C<int> Function(int)>[
      Extra.new,
      Extra.named,
    ]
  ];
  Expect.isNotNull(constructors); // Use variable.

  // The static type is as expected.

  Special.new.expectStaticType<Exactly<C<int> Function(int)>>();
  Special.named.expectStaticType<Exactly<C<int> Function(int)>>();

  // Generic tear-off uses the generics of the type alias.
  Direct.new.expectStaticType<Exactly<C<T> Function<T>(T)>>();
  Direct.named.expectStaticType<Exactly<C<T> Function<T>(T)>>();

  Bounded.new.expectStaticType<Exactly<C<T> Function<T extends num>(T)>>();
  Bounded.named.expectStaticType<Exactly<C<T> Function<T extends num>(T)>>();

  Wrapping.new.expectStaticType<Exactly<C<C<T>> Function<T>(C<T>)>>();
  Wrapping.named.expectStaticType<Exactly<C<C<T>> Function<T>(C<T>)>>();

  Extra.new.expectStaticType<Exactly<C<T> Function<T, S>(T)>>();
  Extra.named.expectStaticType<Exactly<C<T> Function<T, S>(T)>>();

  // Instantiated tear-off uses the instantiated aliased type.

  // Explicitly instantiated.
  Direct<int>.new.expectStaticType<Exactly<C<int> Function(int)>>();
  Direct<int>.named.expectStaticType<Exactly<C<int> Function(int)>>();

  Bounded<int>.new.expectStaticType<Exactly<C<int> Function(int)>>();
  Bounded<int>.named.expectStaticType<Exactly<C<int> Function(int)>>();

  Wrapping<int>.new.expectStaticType<Exactly<C<C<int>> Function(C<int>)>>();
  Wrapping<int>.named.expectStaticType<Exactly<C<C<int>> Function(C<int>)>>();

  Extra<int, String>.new.expectStaticType<Exactly<C<int> Function(int)>>();
  Extra<int, String>.named.expectStaticType<Exactly<C<int> Function(int)>>();

  // Implicitly instantiated.
  context<C<int> Function(int)>(
      Direct.new..expectStaticType<Exactly<C<int> Function(int)>>());
  context<C<int> Function(int)>(
      Direct.named..expectStaticType<Exactly<C<int> Function(int)>>());

  context<C<int> Function(int)>(
      Bounded.new..expectStaticType<Exactly<C<int> Function(int)>>());
  context<C<int> Function(int)>(
      Bounded.named..expectStaticType<Exactly<C<int> Function(int)>>());

  context<C<C<int>> Function(C<int>)>(
      Wrapping.new..expectStaticType<Exactly<C<C<int>> Function(C<int>)>>());
  context<C<C<int>> Function(C<int>)>(
      Wrapping.named..expectStaticType<Exactly<C<C<int>> Function(C<int>)>>());

  context<C<int> Function(int)>(
      Extra.new..expectStaticType<Exactly<C<int> Function(int)>>());
  context<C<int> Function(int)>(
      Extra.named..expectStaticType<Exactly<C<int> Function(int)>>());

  // Uninstantiated tear-offs always canonicalize.
  Expect.identical(Direct.new, Direct.new);
  Expect.identical(Direct.named, Direct.named);
  Expect.identical(Bounded.new, Bounded.new);
  Expect.identical(Bounded.named, Bounded.named);
  Expect.identical(Wrapping.new, Wrapping.new);
  Expect.identical(Wrapping.named, Wrapping.named);
  Expect.identical(Extra.new, Extra.new);
  Expect.identical(Extra.named, Extra.named);

  // Here the type is the same, and the alias is a proper rename.
  Expect.identical(Direct.named, C.named);
  Expect.identical(Direct.new, C.new);

  // The next are unsurprising since the types are different.
  Expect.notEquals(Bounded.named, C.named);
  Expect.notEquals(Bounded.new, C.new);

  Expect.notEquals(Wrapping.named, C.named);
  Expect.notEquals(Wrapping.new, C.new);

  Expect.notEquals(Extra.named, C.named);
  Expect.notEquals(Extra.new, C.new);

  Expect.notEquals(Swapped.new, D.new);
  Expect.notEquals(Swapped.named, D.named);

  // Instantiated alias tear-offs are canonicalized along with direct tear-offs
  // when instantiation uses constant types.

  // Explicit instantiation.
  Expect.identical(Special.new, C<int>.new);
  Expect.identical(Special.named, C<int>.named);

  Expect.identical(Direct<int>.new, C<int>.new);
  Expect.identical(Direct<int>.named, C<int>.named);
  Expect.identical(Bounded<int>.new, C<int>.new);
  Expect.identical(Bounded<int>.named, C<int>.named);
  Expect.identical(Wrapping<int>.new, C<C<int>>.new);
  Expect.identical(Wrapping<int>.named, C<C<int>>.named);
  Expect.identical(Extra<int, String>.new, C<int>.new);
  Expect.identical(Extra<int, String>.named, C<int>.named);
  // And, since the second type parameter doesn't matter:
  Expect.identical(Extra<int, String>.new, Extra<int, bool>.new);
  Expect.identical(Extra<int, String>.named, Extra<int, bool>.named);

  Expect.identical(Swapped<int, String>.new, D<String, int>.new);
  Expect.identical(Swapped<int, String>.named, D<String, int>.named);

  // Implicit instantiation.
  Expect.identical(
    context<C<int> Function(int)>(Direct.new),
    C<int>.new,
  );
  Expect.identical(
    context<C<int> Function(int)>(Direct.named),
    C<int>.named,
  );
  Expect.identical(
    context<C<int> Function(int)>(Bounded.new),
    C<int>.new,
  );
  Expect.identical(
    context<C<int> Function(int)>(Bounded.named),
    C<int>.named,
  );
  Expect.identical(
    context<C<C<int>> Function(C<int>)>(Wrapping.new),
    C<C<int>>.new,
  );
  Expect.identical(
    context<C<C<int>> Function(C<int>)>(Wrapping.named),
    C<C<int>>.named,
  );
  Expect.identical(
    context<D<int, String> Function()>(Swapped.new),
    D<int, String>.new,
  );
  Expect.identical(
    context<D<int, String> Function()>(Swapped.named),
    D<int, String>.named,
  );

  (<T extends num>() {
    // Non-constant type instantiation implies non-constant expressions.
    // Canonicalization is unspecified, but equality holds.
    Expect.equals(Direct<T>.new, Direct<T>.new);
    Expect.equals(Direct<T>.named, Direct<T>.named);
    Expect.equals(Bounded<T>.new, Bounded<T>.new);
    Expect.equals(Bounded<T>.named, Bounded<T>.named);
    Expect.equals(Wrapping<T>.new, Wrapping<T>.new);
    Expect.equals(Wrapping<T>.named, Wrapping<T>.named);
    Expect.equals(Extra<T, String>.new, Extra<T, String>.new);
    Expect.equals(Extra<T, String>.named, Extra<T, String>.named);
    // Also if the non-constant type doesn't occur in the expansion.
    Expect.equals(Extra<int, T>.new, Extra<int, T>.new);
    Expect.equals(Extra<int, T>.named, Extra<int, T>.named);

    Expect.equals(Swapped<T, int>.new, Swapped<T, int>.new);
    Expect.equals(Swapped<T, int>.named, Swapped<T, int>.named);
    Expect.equals(Swapped<int, T>.new, Swapped<int, T>.new);
    Expect.equals(Swapped<int, T>.named, Swapped<int, T>.named);
  }<int>());
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that inference can solve for T? ~ dynamic or void.

class C<T extends Object> {
  final T? value;
  const C(this.value);
  C.list(List<T?> list) : value = list.first;
  void set nonNullValue(T value) {}
}

List<T> foo<T extends Object>(T? value) => [value!];

List<T> bar<T extends Object>(List<T?> value) => [
      for (var element in value)
        if (element != null) element
    ];

extension Ext<T extends Object> on List<T?> {
  List<T> whereNotNull() => [
        for (var element in this)
          if (element != null) element
      ];
}

main() {
  {
    // Testing for dynamic.
    const dynamic o = 42;

    var c = const C(o);
    var f = foo(o);
    var l = [o].whereNotNull();

    c.expectStaticType<Exactly<C<Object>>>();
    Expect.type<C<Object>>(c); // Run-time type is subtype of C<Object>.
    c.nonNullValue = Object(); // And supertype.

    f.expectStaticType<Exactly<List<Object>>>();
    Expect.type<List<Object>>(f); // Run-time type is subtype of List<Object>.
    f[0] = Object(); // And supertype.

    l.expectStaticType<Exactly<List<Object>>>();
    Expect.type<List<Object>>(l); // Run-time type is subtype of List<Object>.
    l[0] = Object(); // And supertype.
  }

  {
    // Testing for void
    List<void> o = <void>[42];

    var c = C.list(o);
    var f = bar(o);
    var l = o.whereNotNull();

    c.expectStaticType<Exactly<C<Object>>>();
    Expect.type<C<Object>>(c); // Run-time type is subtype of C<Object>.
    c.nonNullValue = Object(); // And supertype.

    f.expectStaticType<Exactly<List<Object>>>();
    Expect.type<List<Object>>(f); // Run-time type is subtype of List<Object>.
    f[0] = Object(); // And supertype.

    l.expectStaticType<Exactly<List<Object>>>();
    Expect.type<List<Object>>(l); // Run-time type is subtype of List<Object>.
    l[0] = Object(); // And supertype.
  }
}

// Captures and checks static type of expression.
extension TypeCheck<T> on T {
  T expectStaticType<R extends Exactly<T>>() {
    return this;
  }
}

typedef Exactly<T> = T Function(T);

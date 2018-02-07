// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program testing the use of 'dynamic' in generic types.

import "package:expect/expect.dart";

abstract class Iface<K, V> {}

class M1<K, V> implements Iface<K, V> {}

class M2<K> implements Iface<K, dynamic> {}

class M3 implements Iface<String, dynamic> {}

typedef dynamic F1<T>(dynamic x, T y);

class HasFieldDynamic {
  HasFieldDynamic() : dynamic = "dynamic" {}
  var dynamic; // Field named dynamic is allowed.
}

class HasMethodDynamic {
  dynamic() => "dynamic"; // Method named dynamic is allowed.
}

main() {
  // dynamic is a top-type, equivalent to Object at runtime.
  Expect.isTrue(dynamic is Type);
  Expect.equals(dynamic, dynamic);

  // dynamic is not a subtype of num or String.
  M1<dynamic, dynamic> m1 = new M1<dynamic, dynamic>();
  Expect.isFalse(m1 is Iface<dynamic, num>);
  Expect.isFalse(m1 is Iface<String, dynamic>);
  Expect.isFalse(m1 is Iface<String, num>);
  Expect.isFalse(m1 is Iface<num, String>);

  M2<dynamic> m2 = new M2<dynamic>(); // is Iface<dynamic, dynamic>.
  Expect.isFalse(m2 is Iface<dynamic, num>);
  Expect.isFalse(m2 is Iface<String, dynamic>);
  Expect.isFalse(m2 is Iface<String, num>);
  Expect.isFalse(m2 is Iface<num, String>);

  M3 m3 = new M3(); // is IFace<String, dynamic>.
  Expect.isFalse(m3 is Iface<dynamic, num>);
  Expect.isTrue(m3 is Iface<String, dynamic>);
  Expect.isFalse(m3 is Iface<String, num>);
  Expect.isTrue(m3 is! Iface<num, String>);

  F1<int> f1 = (dynamic s, int i) => s[i]; // is dynamic Function(dynamic, int).
  Expect.isTrue(f1 is F1<int>);

  // "dynamic" is not a reserved word or built-in identifier.

  HasFieldDynamic has_field = new HasFieldDynamic();
  Expect.equals("dynamic", has_field.dynamic);

  HasMethodDynamic has_method = new HasMethodDynamic();
  Expect.equals("dynamic", has_method.dynamic());

  {
    int dynamic = 0; // Local variable named dynamic is allowed.
    Expect.equals(0, dynamic);
  }
}

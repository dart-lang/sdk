// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program testing the use of 'Dynamic' in generic types.

class M1<K, V> implements Map<K, V> {
}

class M2<K> implements Map<K, Dynamic> {
}

class M3 implements Map<String, Dynamic> {
}

typedef Dynamic F1<T>(Dynamic x, T y);

class HasFieldDynamic {
  HasFieldDynamic() : Dynamic = "Dynamic" { }
  var Dynamic;  // Field named Dynamic is allowed.
}

class HasMethodDynamic {
  Dynamic() => "Dynamic";  // Method named Dynamic is allowed.
}

main() {
  M1<Dynamic, Dynamic> m1 = new M1<Dynamic, Dynamic>();
  Expect.isTrue(m1 is Map<Dynamic, num>);
  Expect.isTrue(m1 is Map<String, Dynamic>);
  Expect.isTrue(m1 is Map<String, num>);
  Expect.isTrue(m1 is Map<num, String>);

  M2<Dynamic> m2 = new M2<Dynamic>();
  Expect.isTrue(m2 is Map<Dynamic, num>);
  Expect.isTrue(m2 is Map<String, Dynamic>);
  Expect.isTrue(m2 is Map<String, num>);
  Expect.isTrue(m2 is Map<num, String>);

  M3 m3 = new M3();
  Expect.isTrue(m3 is Map<Dynamic, num>);
  Expect.isTrue(m3 is Map<String, Dynamic>);
  Expect.isTrue(m3 is Map<String, num>);
  Expect.isTrue(m3 is !Map<num, String>);

  F1<int> f1 = (String s, int i) => s[i];
  Expect.isTrue(f1 is F1<int>);

  HasFieldDynamic has_field = new HasFieldDynamic();
  Expect.equals("Dynamic", has_field.Dynamic);

  HasMethodDynamic has_method = new HasMethodDynamic();
  Expect.equals("Dynamic", has_method.Dynamic());

  {
    int Dynamic = 0;  // Local variable named Dynamic is allowed.
    Expect.equals(0, Dynamic);
  }
}

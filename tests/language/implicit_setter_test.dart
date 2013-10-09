// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test of final fields generating implicit setters that throw.

String x = "toplevel";  // Should never be read in this test.

class B {
  var x = 37;
}

class C extends B {
  final x = 42;

  // Local access should work the same as direct access.
  get cx => x;
  void set cx(value) {
    x = value;              /// 02: static type warning
    erase(this).x = value;  // but crash even if the direct setting is omitted.
  }

  // Super access should work.
  get bx => super.x;
  void set bx(value) { super.x = value; }

  noSuchMethod(i) => "noSuchMethod";  // Should never be called in this test.
}

// Class with only final field has setter in implicit interface.
class A {
  final int x = 42;
}

// Should get warning because the implicit interface contains the setter,
// and this non-abstract class doesn't.
class AI
    implements A   /// 01: static type warning
{
  int get x => 37;
}

// Erases static type information. Used to avoid *static* warnings when
// using a setter for a final field.
erase(x) => x;

void main() {
  Expect.equals(42, new C().x);
  Expect.throws(() { erase(new C()).x = 10; });
  Expect.equals(42, new C().cx);
  Expect.throws(() { erase(new C()).cx = 10; });
  Expect.equals(37, new C().bx);
  Expect.equals(10, (erase(new C())..bx = 10).bx);

  Expect.equals(42, new A().x);
  Expect.throws(() { erase(new A()).x = 10; });
  Expect.equals(37, new AI().x);
  Expect.throws(() { erase(new AI()).x = 10; });

  Expect.equals("toplevel", x);  // Should not have changed.
}

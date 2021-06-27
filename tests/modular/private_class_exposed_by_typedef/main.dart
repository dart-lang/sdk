// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "private_name_library.dart";

// These tests are adapted from the set located in
// language/nonfunction_type_aliases/private_names/ to highlight a specific
// DDC issue with public fields in private classes.

void main() {
  test1();
  test2();
}

/// Extend a private class via a public typedef without overriding any methods.
class Derived extends PublicClass {
  Derived() : super();
}

/// Extend a private class via a public typedef overriding methods and
/// properties.  The final field `x` is overriden with a getter which returns
/// different values every time it is called.
class AlsoDerived extends AlsoPublicClass {
  int backingStore = publicNameSentinel;
  int get x => ++backingStore;
  int get y => super.x;
  AlsoDerived() : super.named(privateNameSentinel);
}

/// Test that inherited properties work correctly
void test1() {
  var p = Derived();
  // Reading the virtual field should give the private value
  Expect.equals(privateNameSentinel, p.x);
  // Reading the virtual field from the private library should give the private
  // value
  Expect.equals(privateNameSentinel, readInstanceField(p));
}

/// Test that overridden properties work correctly.
void test2() {
  var p = AlsoDerived();
  // Reading the original virtual field should give the private value.
  Expect.equals(privateNameSentinel, p.y);
  // Reading the overriding getter from the private library should give the
  // public value and increment it each time it is called.
  Expect.equals(publicNameSentinel, p.backingStore);
  Expect.equals(publicNameSentinel + 1, readInstanceField2(p));
  Expect.equals(publicNameSentinel + 1, p.backingStore);
  // Reading the overriding getter from the original library should give the
  // public value and increment it each time it is called.
  Expect.equals(publicNameSentinel + 2, p.x);
  Expect.equals(publicNameSentinel + 2, p.backingStore);
  Expect.equals(privateNameSentinel, p.y);
  Expect.equals(publicNameSentinel + 2, p.backingStore);
  Expect.equals(publicNameSentinel + 3, readInstanceField2(p));
  Expect.equals(publicNameSentinel + 4, p.x);
}

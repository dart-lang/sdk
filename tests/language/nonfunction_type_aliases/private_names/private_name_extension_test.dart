// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs allow extension.

import "package:expect/expect.dart";

import "private_name_library.dart";

/// Extend a private class via a public typedef without overriding any methods.
class Derived extends PublicClass {
  // Check that super constructor calls work.
  Derived() : super();
}

/// Extend a private class via a public typedef overriding methods and
/// properties.  The final field `x` is overriden with a getter which returns
/// different values every time it is called.
class AlsoDerived extends AlsoPublicClass {
  int backingStore = publicLibrarySentinel;
  int get x => backingStore++;
  int get y => super.x;
  // Check that named super constructors work.  Use the private sentinel value
  // to allow us to distinguish reads of `x` from `super.x`.
  AlsoDerived() : super.named(privateLibrarySentinel);
  // Override the instanceMethod to return a distinguishing value.
  int instanceMethod() => publicLibrarySentinel;
  // Add a non-overriding private method with the same textual name as a private
  // name in the super class which returns a distinguishing value.
  int _privateInstanceMethod() => publicLibrarySentinel;
}

/// Test that inherited methods work correctly.
void test1() {
  PublicClass p = Derived();
  Expect.equals(privateLibrarySentinel, p.instanceMethod());
  // Calling the inherited private method from the private library should work.
  Expect.equals(privateLibrarySentinel, callPrivateInstanceMethod(p));
  Expect.equals(privateLibrarySentinel, callInstanceMethod(p));
  // Calling the inherited private method from this library should throw.
  Expect.throwsNoSuchMethodError(() => (p as dynamic)._privateInstanceMethod());
}

/// Test that overriden methods work correctly.
void test2() {
  var p = AlsoDerived();
  Expect.equals(publicLibrarySentinel, p.instanceMethod());
  // Calling the overriden private method from this library should work.
  Expect.equals(publicLibrarySentinel, p._privateInstanceMethod());
  // Calling the inherited private method from the private library should work.
  Expect.equals(privateLibrarySentinel, callPrivateInstanceMethod(p));
  // Calling the overriden private method dynamically from this library should
  // work.
  Expect.equals(publicLibrarySentinel, (p as dynamic)._privateInstanceMethod());
}

/// Test that inherited properties work correctly
void test3() {
  var p = Derived();
  // Reading the virtual field should give the private value
  Expect.equals(privateLibrarySentinel, p.x);
  // Reading the virtual field from the private library should give the private
  // value
  Expect.equals(privateLibrarySentinel, readInstanceField(p));
}

/// Test that overriden properties work correctly.
void test4() {
  var p = AlsoDerived();
  // Reading the original virtual field should give the private value.
  Expect.equals(privateLibrarySentinel, p.y);
  // Reading the overriding getter from this library should give the public
  // value and increment it each time it is called.
  Expect.equals(publicLibrarySentinel, readInstanceField(p));
  // Reading the overriding getter from the original library should give the
  // public value and increment it each time it is called.
  Expect.equals(publicLibrarySentinel + 1, p.x);

  Expect.equals(privateLibrarySentinel, p.y);
  Expect.equals(publicLibrarySentinel + 2, readInstanceField(p));
  Expect.equals(publicLibrarySentinel + 3, p.x);
}

void main() {
  test1();
  test2();
  test3();
  test4();
}

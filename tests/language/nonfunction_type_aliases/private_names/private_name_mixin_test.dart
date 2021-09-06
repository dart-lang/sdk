// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs can be used as mixins.

import "package:expect/expect.dart";

import "private_name_library.dart";

// Class that mixes in a private mixin via a public name.
class Derived0 with PublicMixin {}

void test0() {
  // Test that the Derived0 class receives the PublicMixin methods.
  PublicMixin p = Derived0();
  Expect.equals(privateLibrarySentinel, p.mixinMethod());
  // The private mixin method is accessible in the original library.
  Expect.equals(privateLibrarySentinel, callPrivateMixinMethod(p));
  // The private mixin method is not accessible in this library.
  Expect.throwsNoSuchMethodError(() => (p as dynamic)._privateMixinMethod());
}

// Class that mixes in a private mixin via a public name and overrides the
// PublicMixin methods.
class Derived1 with PublicMixin {
  int mixinMethod() => publicLibrarySentinel;
  int _privateMixinMethod() => publicLibrarySentinel;
}

void test1() {
  // Test that the mixed in methods have been overriden correctly, and that the
  // private methods from the two libraries resolve correctly.
  var p = Derived1();
  Expect.equals(publicLibrarySentinel, p.mixinMethod());
  // The overriding private mixin method is accessible in this library.
  Expect.equals(publicLibrarySentinel, p._privateMixinMethod());
  // The original private mixin method is accessible in the other library.
  Expect.equals(privateLibrarySentinel, callPrivateMixinMethod(p));
}

class _Derived2 extends PublicClass {}

// This class mixes a private super-mixin onto a subclass of a private class,
// and also defines new library private members with the same textual name as
// private members defined in the other library.
class Derived2 extends _Derived2 with PublicSuperMixin {
  int _privateMixinMethod() => publicLibrarySentinel;
  int _privateInstanceMethod() => publicLibrarySentinel;
}

void test2() {
  // Test that the super-mixin methods resolve correctly.
  var p = Derived2();
  PublicSuperMixin _ = p; // Check assignability
  PublicClass __ = p; // Check assignability
  // The mixin and instance methods are accessible.
  Expect.equals(privateLibrarySentinel, p.mixinMethod());
  Expect.equals(privateLibrarySentinel, p.instanceMethod());
  // The original private mixin and instance methods are accessible in the
  // original library.
  Expect.equals(privateLibrarySentinel, callPrivateSuperMixinMethod(p));
  Expect.equals(privateLibrarySentinel, callPrivateInstanceMethod(p));
  // The new private mixin and instance methods are acessible in this library.
  Expect.equals(publicLibrarySentinel, p._privateMixinMethod());
  Expect.equals(publicLibrarySentinel, p._privateInstanceMethod());
}

void main() {
  test0();
  test1();
  test2();
}

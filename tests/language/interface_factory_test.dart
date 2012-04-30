// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that the two major variations of interface factories work.

// Variant 1.  The factory class implements the interface and provides
// a default implementation of the interface.

interface Interface1 default DefaultImplementation {
  // first parameter type 'var' not a subtype of 'int' in default implementation
  Interface1(var secret); /// static type warning
  Interface1.named();

  GetSecret();
}

class DefaultImplementation implements Interface1 {
  int _secret;

  DefaultImplementation(int this._secret) {}
  DefaultImplementation.named() : this._secret = 11 {}

  int GetSecret() { return _secret; }

  static testMain() {
    Expect.equals(7, new Interface1(7).GetSecret());
    Expect.equals(11, new Interface1.named().GetSecret());
  }
}

// Variant 2.  The factory class provides factory constructors for the
// interface.

interface Interface2 default FactoryProvider {
  Interface2(var secret);
  Interface2.named();

  GetSecret();
}

class SomeImplementation implements Interface2 {
  String _secret;

  SomeImplementation(String one, String two) : _secret = "${one}${two}" {}

  String GetSecret() { return _secret; }
}

// Note that FactoryProvider does not implement Interface2.
class FactoryProvider {
  factory Interface2(var secret) {
    return new SomeImplementation(secret, secret);
  }

  factory Interface2.named() {
    return new SomeImplementation("Named", "Constructor");
  }

  static testMain() {
    Expect.equals("cobracobra", new Interface2("cobra").GetSecret());
    Expect.equals("NamedConstructor", new Interface2.named().GetSecret());
  }
}

main() {
  DefaultImplementation.testMain();
  FactoryProvider.testMain();
}

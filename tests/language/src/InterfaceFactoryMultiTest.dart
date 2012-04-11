// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// Test that a factory provider can provide for more than one interface.

interface A default F {
  A(var secret);

  GetSecret();
}

class AImpl implements A {
  String _secret;

  AImpl(String one, String two) : _secret = "${one}${two}";

  String GetSecret() { return _secret; }
}

interface B default F {
  B(var secret);

  GetSecret();
}

class BImpl implements B {
  String _secret;

  BImpl(String one, String two) : _secret = "${two}${one}";

  String GetSecret() { return _secret; }
}


// One factory provider for two interfaces.
class F {
  factory A(var secret) {
    return new AImpl(secret, 'A');
  }

  factory B(var secret) {
    return new BImpl(secret, 'B');
  }
}

main() {
  Expect.equals('1A', new A('1').GetSecret());
  Expect.equals('B2', new B('2').GetSecret());
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for correct hidden native class when abstract class has same name.

library main;

import 'native_testing.dart';
import 'native_library_same_name_used_lib1.dart';

void setup() native """
  // This code is all inside 'setup' and so not accessible from the global
  // scope.
  function I(){}
  I.prototype.read = function() { return this._x; };
  I.prototype.write = function(x) { this._x = x; };
  makeI = function(){return new I};
  self.nativeConstructor(I);
""";

// A pure Dart implementation of I.

class ProxyI implements I {
  ProxyI b;
  ProxyI read() {
    return b;
  }

  write(ProxyI x) {
    b = x;
  }
}

main() {
  nativeTesting();
  setup();

  var a1 = makeI();
  var a2 = makeI();
  var b1 = new ProxyI();
  var b2 = new ProxyI();
  var ob = new Object();

  Expect.isFalse(ob is I, 'ob is I');
  Expect.isFalse(ob is ProxyI, 'ob is ProxyI');

  Expect.isTrue(b1 is I, 'b1 is I');
  Expect.isTrue(b1 is ProxyI, 'b1 is ProxyI');

  Expect.isTrue(a1 is I, 'a1 is I');
  Expect.isFalse(a1 is ProxyI, 'a1 is ProxyI');

  Expect.isTrue(confuse(a1) is I, 'a1 is I');
  Expect.isFalse(confuse(a1) is ProxyI, 'a1 is ProxyI');
}

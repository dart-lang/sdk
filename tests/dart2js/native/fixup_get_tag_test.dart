// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test for dartExperimentalFixupGetTag.

@Native("A")
class Foo {
  // There is one native class with dispatch tag 'A'.
  token() native;
}

void setup() {
  JS('', r"""
(function(){

  dartExperimentalFixupGetTag = function (originalGetTag) {
    function fixedGetTag(obj) {
      // Local JS 'class' B is made to be another implementation of the native
      // class with tag 'A'.
      if (obj instanceof B) return 'A';
      // Other classes behave as before.
      return originalGetTag(obj);
    }
    return fixedGetTag;
  };

  function A(){ }
  A.prototype.token = function () { return 'isA'; };

  function B(){ }
  B.prototype.token = function () { return 'isB'; };

  makeA = function() { return new A(); };
  makeB = function() { return new B(); };

  self.nativeConstructor(A);
})()""");
}

makeA() native;
makeB() native;

main() {
  nativeTesting();
  setup();

  var a = makeA();
  var b = makeB();

  Expect.equals('isA', a.token());

  // This call succeeds because the fixed-up 'getTag' method returns Foo's
  // dispatch tag, and B is a faithful polyfil for Foo/A.
  Expect.equals('isB', b.token());

  Expect.isTrue(a is Foo);
  Expect.isTrue(b is Foo);
}

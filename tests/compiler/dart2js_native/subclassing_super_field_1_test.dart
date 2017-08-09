// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors'
    show findInterceptorForType, findConstructorForNativeSubclassType;

// Test for shadowed fields in classes that extend native classes.

@Native("N")
class N {
  N.init();
}

class A extends N {
  var foo = 111;
  A.init() : super.init();
}

class B extends A {
  var foo = 222;
  B.init() : super.init();

  Afoo() => super.foo;
  Bfoo() => foo;
}

B makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() {
  JS('', r"""
(function(){
function B() { }
makeB = function(){return new B()};

getBPrototype = function(){return B.prototype;};
})()""");
}

main() {
  nativeTesting();
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  B b = makeB();

  var constructor = findConstructorForNativeSubclassType(B, 'init');
  Expect.isNotNull(constructor);
  JS('', '#(#)', constructor, b);

  print(b);

  Expect.equals(222, confuse(b).Bfoo());
  Expect.equals(111, confuse(b).Afoo());

  Expect.equals(222, b.Bfoo());
  Expect.equals(111, b.Afoo());
}

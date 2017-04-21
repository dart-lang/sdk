// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors'
    show findInterceptorForType, findConstructorForNativeSubclassType;

// Test for fields with same name as native fields.  We expect N.foo to have the
// property name 'foo' and A.foo and B.foo to have non-conflicting names.

@Native("N")
class N {
  var foo;
  N.init();
}

class A extends N {
  var foo = 222;
  A.init() : super.init();
  Nfoo() => super.foo; // TODO(sra): Fix compiler assert.
}

class B extends A {
  var foo = 333;
  B.init() : super.init();
  Afoo() => super.foo;
  Bfoo() => foo;

  toString() => '[N.foo = ${Nfoo()}, A.foo = ${Afoo()}, B.foo = ${Bfoo()}]';
}

B makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() native r"""
function B() { this.foo = 111; }  // N.foo
makeB = function(){return new B;};

getBPrototype = function(){return B.prototype;};
""";

main() {
  nativeTesting();
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  B b = makeB();

  var constructor = findConstructorForNativeSubclassType(B, 'init');
  Expect.isNotNull(constructor);
  JS('', '#(#)', constructor, b);

  print(b);

  Expect.equals(333, confuse(b).Bfoo());
  Expect.equals(222, confuse(b).Afoo());
  Expect.equals(111, confuse(b).Nfoo());

  Expect.equals(333, b.Bfoo());
  Expect.equals(222, b.Afoo());
  Expect.equals(111, b.Nfoo());
}

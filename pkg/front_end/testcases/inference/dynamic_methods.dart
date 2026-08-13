// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Foo {
  int foo(int x) => x;
}

test() {
  dynamic d = new Foo();
  var get_hashCode = d.hashCode;
  var call_hashCode = d.hashCode();
  var call_toString = d.toString();
  var call_toStringArg = d.toString(color: "pink");
  var call_foo0 = d.foo();
  var call_foo1 = d.foo(1);
  var call_foo2 = d.foo(1, 2);
  var call_nsm0 = d.noSuchMethod();
  var call_nsm1 = d.noSuchMethod(throw '');
  var call_nsm2 = d.noSuchMethod(null, null);
  var equals_self = d == d;
  var equals_null = d == null;
  var null_equals = null == d;
  var not_equals_self = d != d;
  var not_equals_null = d != null;
  var null_not_equals = null != d;
}

main() {}

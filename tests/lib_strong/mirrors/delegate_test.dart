// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_named_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class C {
  method(a, b, c) => "$a-$b-$c";
  methodWithNamed(a, {b: 'B', c}) => "$a-$b-$c";
  methodWithOpt(a, [b, c = 'C']) => "$a-$b-$c";
  get getter => 'g';
  set setter(x) {
    field = x * 2;
    return 'unobservable value';
  }

  var field;
}

class Proxy {
  var targetMirror;
  Proxy(target) : this.targetMirror = reflect(target);
  noSuchMethod(invocation) => targetMirror.delegate(invocation);
}

main() {
  var c = new C();
  var proxy = new Proxy(c);
  var result;

  Expect.equals('X-Y-Z', proxy.method('X', 'Y', 'Z'));

  Expect.equals('X-B-null', proxy.methodWithNamed('X'));
  Expect.equals('X-Y-null', proxy.methodWithNamed('X', b: 'Y'));
  Expect.equals('X-Y-Z', proxy.methodWithNamed('X', b: 'Y', c: 'Z'));

  Expect.equals('X-null-C', proxy.methodWithOpt('X'));
  Expect.equals('X-Y-C', proxy.methodWithOpt('X', 'Y'));
  Expect.equals('X-Y-Z', proxy.methodWithOpt('X', 'Y', 'Z'));

  Expect.equals('g', proxy.getter);

  Expect.equals(5, proxy.setter = 5);
  Expect.equals(10, proxy.field);

  Expect.equals(5, proxy.field = 5);
  Expect.equals(5, proxy.field);
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.delegate_library;

import 'dart:mirrors';

import 'package:expect/expect.dart';

method(a, b, c) => "$a-$b-$c";
methodWithNamed(a, {b: 'B', c}) => "$a-$b-$c";
methodWithOpt(a, [b, c = 'C']) => "$a-$b-$c";
get getter => 'g';
set setter(x) {
  field = x * 2;
}

var field;

class Proxy {
  var targetMirror;
  Proxy(this.targetMirror);
  noSuchMethod(invocation) => targetMirror.delegate(invocation);
}

main() {
  dynamic proxy = new Proxy(reflectClass(Proxy).owner);
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

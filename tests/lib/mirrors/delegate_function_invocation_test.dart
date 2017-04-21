// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.delegate_function_invocation;

@MirrorsUsed(targets: "test.delegate_function_invocation")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Proxy {
  var targetMirror;
  Proxy(target) : this.targetMirror = reflect(target);
  noSuchMethod(invocation) => targetMirror.delegate(invocation);
}

testClosure() {
  var proxy = new Proxy(() => 42);
  Expect.equals(42, proxy());
  Expect.equals(42, proxy.call());
}

class FakeFunction {
  call() => 43;
}

testFakeFunction() {
  var proxy = new Proxy(new FakeFunction());
  Expect.equals(43, proxy());
  Expect.equals(43, proxy.call());
}

topLevelFunction() => 44;

testTopLevelTearOff() {
  var proxy = new Proxy(topLevelFunction);
  Expect.equals(44, proxy());
  Expect.equals(44, proxy.call());
}

class C {
  method() => 45;
}

testInstanceTearOff() {
  var proxy = new Proxy(new C().method);
  Expect.equals(45, proxy());
  Expect.equals(45, proxy.call());
}

main() {
  testClosure();
  testFakeFunction();
  testTopLevelTearOff();
  testInstanceTearOff();
}

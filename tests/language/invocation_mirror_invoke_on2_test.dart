// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Proxy {
  final proxied;
  Proxy(this.proxied);
  noSuchMethod(mirror) => mirror.invokeOn(proxied);
}

main() {
  testList();
  testString();
  testInt();
  testDouble();
}

testList() {
  var list = [];
  var proxy = new Proxy(list);

  Expect.isTrue(proxy.isEmpty);
  Expect.isTrue(list.isEmpty);

  proxy.add(42);

  Expect.isFalse(proxy.isEmpty);
  Expect.equals(1, proxy.length);
  Expect.equals(42, proxy[0]);

  Expect.isFalse(list.isEmpty);
  Expect.equals(1, list.length);
  Expect.equals(42, list[0]);

  proxy.add(87);

  Expect.equals(2, proxy.length);
  Expect.equals(87, proxy[1]);

  Expect.equals(2, list.length);
  Expect.equals(87, list[1]);

  Expect.throws(() => proxy.funky(), (e) => e is NoSuchMethodError);
  Expect.throws(() => list.funky(), (e) => e is NoSuchMethodError);
}

testString() {
  var string = "funky";
  var proxy = new Proxy(string);

  Expect.equals(string.codeUnitAt(0), proxy.codeUnitAt(0));
  Expect.equals(string.length, proxy.length);

  Expect.throws(() => proxy.funky(), (e) => e is NoSuchMethodError);
  Expect.throws(() => string.funky(), (e) => e is NoSuchMethodError);
}

testInt() {
  var number = 42;
  var proxy = new Proxy(number);

  Expect.equals(number + 87, proxy + 87);
  Expect.equals(number.toDouble(), proxy.toDouble());

  Expect.throws(() => proxy.funky(), (e) => e is NoSuchMethodError);
  Expect.throws(() => number.funky(), (e) => e is NoSuchMethodError);
}

testDouble() {
  var number = 42.99;
  var proxy = new Proxy(number);

  Expect.equals(number + 87, proxy + 87);
  Expect.equals(number.toInt(), proxy.toInt());

  Expect.throws(() => proxy.funky(), (e) => e is NoSuchMethodError);
  Expect.throws(() => number.funky(), (e) => e is NoSuchMethodError);
}

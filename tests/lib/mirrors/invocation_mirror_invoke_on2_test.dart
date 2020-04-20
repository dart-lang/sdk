// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

class Proxy {
  final proxied;
  Proxy(this.proxied);
  noSuchMethod(mirror) => reflect(proxied).delegate(mirror);
}

main() {
  testList();
  testString();
  testInt();
  testDouble();
}

testList() {
  dynamic list = [];
  dynamic proxy = new Proxy(list);

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

  Expect.throwsNoSuchMethodError(() => proxy.funky());
  Expect.throwsNoSuchMethodError(() => list.funky());
}

testString() {
  dynamic string = "funky";
  dynamic proxy = new Proxy(string);

  Expect.equals(string.codeUnitAt(0), proxy.codeUnitAt(0));
  Expect.equals(string.length, proxy.length);

  Expect.throwsNoSuchMethodError(() => proxy.funky());
  Expect.throwsNoSuchMethodError(() => string.funky());
}

testInt() {
  dynamic number = 42;
  dynamic proxy = new Proxy(number);

  Expect.equals(number + 87, proxy + 87);
  Expect.equals(number.toDouble(), proxy.toDouble());

  Expect.throwsNoSuchMethodError(() => proxy.funky());
  Expect.throwsNoSuchMethodError(() => number.funky());
}

testDouble() {
  dynamic number = 42.99;
  dynamic proxy = new Proxy(number);

  Expect.equals(number + 87, proxy + 87);
  Expect.equals(number.toInt(), proxy.toInt());

  Expect.throwsNoSuchMethodError(() => proxy.funky());
  Expect.throwsNoSuchMethodError(() => number.funky());
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=100 --no-background_compilation

// Test field type tracking and field list-length tracking in the presence of
// multiple isolates.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';

class A {
  A(this.a);
  var a;
}

class B extends A {
  B(a, this.b) : super(a) {}

  var b;
}

f1(SendPort send_port) {
  send_port.send(new B("foo", "bar"));
}

test_b(B obj) => obj.a + obj.b;

test_field_type() {
  var receive_port = new ReceivePort();
  asyncStart();
  Future<Isolate> isolate = Isolate.spawn(f1, receive_port.sendPort);
  B b = new B(1, 2);
  for (var i = 0; i < 200; i++) {
    test_b(b);
  }
  Expect.equals(3, test_b(b));
  Future<B> item = receive_port.first;
  item.then((B value) {
    Expect.equals("foobar", test_b(value));
    receive_port.close();
    asyncEnd();
  });
}

class C {
  C(this.list);
  final List list;
}

f2(SendPort send_port) {
  send_port.send(new C(new List(1)));
}

test_c(C obj) => obj.list[9999];

test_list_length() {
  var receive_port = new ReceivePort();
  asyncStart();
  Future<Isolate> isolate = Isolate.spawn(f2, receive_port.sendPort);
  C c = new C(new List(10000));
  for (var i = 0; i < 200; i++) {
    test_c(c);
  }
  Expect.equals(null, test_c(c));
  Future<C> item = receive_port.first;
  item.then((C value) {
    Expect.throws(() => test_c(value), (e) => e is RangeError);
    receive_port.close();
    asyncEnd();
  });
}

main() {
  test_field_type();
  test_list_length();
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups
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

f1(Object send_port) {
  (send_port as SendPort).send(new B("foo", "bar"));
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
  Future item = receive_port.first;
  item.then((value) {
    Expect.equals("foobar", test_b(value as B));
    receive_port.close();
    asyncEnd();
  });
}

class C {
  C(this.list);
  final List list;
}

f2(Object send_port) {
  (send_port as SendPort).send(new C(new List.filled(1, null)));
}

test_c(C obj) => obj.list[9999];

test_list_length() {
  var receive_port = new ReceivePort();
  asyncStart();
  Future<Isolate> isolate = Isolate.spawn(f2, receive_port.sendPort);
  C c = new C(new List.filled(10000, null));
  for (var i = 0; i < 200; i++) {
    test_c(c);
  }
  Expect.equals(null, test_c(c));
  Future item = receive_port.first;
  item.then((value) {
    Expect.throwsRangeError(() => test_c(value as C));
    receive_port.close();
    asyncEnd();
  });
}

main() {
  test_field_type();
  test_list_length();
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("ConstructorTest");
#import("dart:isolate");
#import('../../../lib/unittest/unittest.dart');

class ConstructorTest extends Isolate {
  final int field;
  ConstructorTest() : super(), field = 499;

  void main() {
    this.port.receive((ignoredMessage, reply) {
      reply.send(field, null);
      this.port.close();
    });
  }
}

main() {
  test("constructor correctly initialized child isolate", () {
    ConstructorTest test = new ConstructorTest();
    test.spawn().then(expectAsync1((SendPort port) {
      port.call("ignored").then(expectAsync1((message) {
        Expect.equals(499, message);
      }));
    }));
  });
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("SpawnTest");
#import("dart:isolate");
#import('../../lib/unittest/unittest.dart');

main() {
  test("spawn a new isolate", () {
    SpawnedIsolate isolate = new SpawnedIsolate();
    isolate.spawn().then(expectAsync1((SendPort port) {
      port.call(42).then(expectAsync1((message) {
        Expect.equals(42, message);
      }));
    }));
  });
}

class SpawnedIsolate extends Isolate {

  SpawnedIsolate() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      Expect.equals(42, message);
      replyTo.send(42, null);
      this.port.close();
    });
  }

}

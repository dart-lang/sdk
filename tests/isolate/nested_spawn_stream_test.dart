// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can spawn other isolates.

library NestedSpawnTest;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

void isolateA() {
  IsolateSink replyTo;
  bool isFirst = true;
  stream.listen((msg) {
    if (isFirst) {
      isFirst = false;
      replyTo = msg;
      return;
    }
    expect(msg, "launch nested!");
    IsolateSink sink = streamSpawnFunction(isolateB);
    MessageBox box = new MessageBox();
    sink.add(box.sink);
    sink.add("alive?");
    box.stream.single.then((msg) {
      expect(msg, "and kicking");
      replyTo.add(499);
      replyTo.close();
      stream.close();
    });
  });
}

void isolateB() {
  IsolateSink replyTo;
  bool isFirst = true;
  stream.listen((msg) {
    if (isFirst) {
      isFirst = false;
      replyTo = msg;
      return;
    }
    expect(msg, "alive?");
    replyTo.add("and kicking");
    replyTo.close();
    stream.close();
  });
}


main() {
  test("spawned isolates can spawn nested isolates", () {
    MessageBox box = new MessageBox();
    IsolateSink sink = streamSpawnFunction(isolateA);
    sink.add(box.sink);
    sink.add("launch nested!");
    box.stream.single.then(expectAsync1((msg) {
      expect(msg, 499);
    }));
  });
}

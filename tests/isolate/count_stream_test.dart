// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library CountTest;
import '../../pkg/unittest/lib/unittest.dart';
import 'dart:isolate';

void countMessages() {
  int count = 0;
  IsolateSink replySink;
  bool isFirst = true;
  stream.listen((msg) {
    if (isFirst) {
      replySink = msg;
      isFirst = false;
      return;
    }
    replySink.add(count);
    count++;
  }, onDone: () {
    expect(count, 10);
    replySink.close();
  });
}

void main() {
  test("count 10 consecutive stream messages", () {
    int count = 0;
    MessageBox box = new MessageBox();
    IsolateSink remote = streamSpawnFunction(countMessages);
    remote.add(box.sink);
    box.stream.listen(expectAsync1((remoteCount) {
      expect(remoteCount, count);
      count++;
      if (count < 10) {
        remote.add(null);
      } else {
        remote.close();
      }
    }, count: 10), onDone: expectAsync0(() {
      expect(count, 10);
    }));
    remote.add(null);
  });
}

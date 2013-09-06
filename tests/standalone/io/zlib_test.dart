// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testZLibDeflate() {
  test(int level, List<int> expected) {
    asyncStart();
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var controller = new StreamController(sync: true);
    controller.stream.transform(new ZLibEncoder(gzip: false, level: level))
        .fold([], (buffer, data) {
          buffer.addAll(data);
          return buffer;
        })
        .then((data) {
          Expect.listEquals(expected, data);
          asyncEnd();
        });
    controller.add(data);
    controller.close();
  }
  test(6, [120, 156, 99, 96, 100, 98, 102, 97, 101, 99, 231, 224, 4, 0, 0, 175,
           0, 46]);
}


void testZLibDeflateEmpty() {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: false, level: 6))
      .fold([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
        Expect.listEquals([120, 156, 3, 0, 0, 0, 0, 1], data);
        asyncEnd();
      });
  controller.close();
}


void testZLibDeflateGZip() {
  asyncStart();
  var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: true))
      .fold([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
        Expect.equals(30, data.length);
        Expect.listEquals([99, 96, 100, 98, 102, 97, 101, 99, 231, 224, 4, 0,
                           70, 215, 108, 69, 10, 0, 0, 0],
                          // Skip header, as it can change.
                          data.sublist(10));
        asyncEnd();
      });
  controller.add(data);
  controller.close();
}

void testZLibDeflateInvalidLevel() {
  test2(gzip, level) {
    try {
      new ZLibEncoder(gzip: gzip, level: level).startChunkedConversion(null);
      Expect.fail("No exception thrown");
    } catch (e) {
    }
  }
  test(level) {
    test2(false, level);
    test2(true, level);
    test2(9, level);
  }
  test(-2);
  test(-20);
  test(10);
  test(42);
  test(null);
  test("9");
}

void testZLibInflate() {
  test2(bool gzip, int level) {
    asyncStart();
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var controller = new StreamController(sync: true);
    controller.stream
      .transform(new ZLibEncoder(gzip: gzip, level: level))
      .transform(new ZLibDecoder())
        .fold([], (buffer, data) {
          buffer.addAll(data);
          return buffer;
        })
        .then((inflated) {
          Expect.listEquals(data, inflated);
          asyncEnd();
        });
    controller.add(data);
    controller.close();
  }
  void test(int level) {
    test2(false, level);
    test2(true, level);
  }
  for (int i = -1; i < 10; i++) {
    test(i);
  }
}

void testZLibInflateSync() {
  test2(bool gzip, int level) {
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var encoded = new ZLibEncoder(gzip: gzip, level: level).convert(data);
    var decoded = new ZLibDecoder().convert(encoded);
    Expect.listEquals(data, decoded);
  }
  void test(int level) {
    test2(false, level);
    test2(true, level);
  }
  for (int i = -1; i < 10; i++) {
    test(i);
  }
}

void main() {
  asyncStart();
  testZLibDeflate();
  testZLibDeflateEmpty();
  testZLibDeflateGZip();
  testZLibDeflateInvalidLevel();
  testZLibInflate();
  testZLibInflateSync();
  asyncEnd();
}

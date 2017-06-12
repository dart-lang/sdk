// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testZLibDeflateEmpty() {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: false, level: 6)).fold([],
      (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((data) {
    Expect.listEquals([120, 156, 3, 0, 0, 0, 0, 1], data);
    asyncEnd();
  });
  controller.close();
}

void testZLibDeflateEmptyGzip() {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: true, level: 6)).fold([],
      (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((data) {
    Expect.isTrue(data.length > 0);
    Expect.listEquals([], new ZLibDecoder().convert(data));
    asyncEnd();
  });
  controller.close();
}

void testZLibDeflate(List<int> data) {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: false, level: 6)).fold([],
      (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((data) {
    Expect.listEquals([
      120,
      156,
      99,
      96,
      100,
      98,
      102,
      97,
      101,
      99,
      231,
      224,
      4,
      0,
      0,
      175,
      0,
      46
    ], data);
    asyncEnd();
  });
  controller.add(data);
  controller.close();
}

void testZLibDeflateGZip(List<int> data) {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(gzip: true)).fold([],
      (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((data) {
    Expect.equals(30, data.length);
    Expect.listEquals(
        [
          99,
          96,
          100,
          98,
          102,
          97,
          101,
          99,
          231,
          224,
          4,
          0,
          70,
          215,
          108,
          69,
          10,
          0,
          0,
          0
        ],
        // Skip header, as it can change.
        data.sublist(10));
    asyncEnd();
  });
  controller.add(data);
  controller.close();
}

void testZLibDeflateRaw(List<int> data) {
  asyncStart();
  var controller = new StreamController(sync: true);
  controller.stream.transform(new ZLibEncoder(raw: true, level: 6)).fold([],
      (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((data) {
    Expect
        .listEquals([99, 96, 100, 98, 102, 97, 101, 99, 231, 224, 4, 0], data);
    asyncEnd();
  });
  controller.add(data);
  controller.close();
}

void testZLibDeflateInvalidLevel() {
  test2(gzip, level) {
    [true, false].forEach((gzip) {
      [-2, -20, 10, 42, null, "9"].forEach((level) {
        Expect.throws(() => new ZLibEncoder(gzip: gzip, level: level),
            (e) => e is ArgumentError, "'level' must be in range -1..9");
      });
    });
  }

  ;
}

void testZLibInflate(List<int> data) {
  [true, false].forEach((gzip) {
    [
      ZLibOption.STRATEGY_FILTERED,
      ZLibOption.STRATEGY_HUFFMAN_ONLY,
      ZLibOption.STRATEGY_RLE,
      ZLibOption.STRATEGY_FIXED,
      ZLibOption.STRATEGY_DEFAULT
    ].forEach((strategy) {
      [3, 6, 9].forEach((level) {
        asyncStart();
        var controller = new StreamController(sync: true);
        controller.stream
            .transform(
                new ZLibEncoder(gzip: gzip, level: level, strategy: strategy))
            .transform(new ZLibDecoder())
            .fold([], (buffer, data) {
          buffer.addAll(data);
          return buffer;
        }).then((inflated) {
          Expect.listEquals(data, inflated);
          asyncEnd();
        });
        controller.add(data);
        controller.close();
      });
    });
  });
}

void testZLibInflateRaw(List<int> data) {
  [3, 6, 9].forEach((level) {
    asyncStart();
    var controller = new StreamController(sync: true);
    controller.stream
        .transform(new ZLibEncoder(raw: true, level: level))
        .transform(new ZLibDecoder(raw: true))
        .fold([], (buffer, data) {
      buffer.addAll(data);
      return buffer;
    }).then((inflated) {
      Expect.listEquals(data, inflated);
      asyncEnd();
    });
    controller.add(data);
    controller.close();
  });
}

void testZLibInflateSync(List<int> data) {
  [true, false].forEach((gzip) {
    [3, 6, 9].forEach((level) {
      var encoded = new ZLibEncoder(gzip: gzip, level: level).convert(data);
      var decoded = new ZLibDecoder().convert(encoded);
      Expect.listEquals(data, decoded);
    });
  });
}

void testZlibInflateThrowsWithSmallerWindow() {
  var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  var encoder = new ZLibEncoder(windowBits: 10);
  var encodedData = encoder.convert(data);
  var decoder = new ZLibDecoder(windowBits: 8);
  Expect.throws(() => decoder.convert(encodedData));
}

void testZlibInflateWithLargerWindow() {
  var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  [true, false].forEach((gzip) {
    [3, 6, 9].forEach((level) {
      asyncStart();
      var controller = new StreamController(sync: true);
      controller.stream
          .transform(new ZLibEncoder(gzip: gzip, level: level, windowBits: 8))
          .transform(new ZLibDecoder(windowBits: 10))
          .fold([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      }).then((inflated) {
        Expect.listEquals(data, inflated);
        asyncEnd();
      });
      controller.add(data);
      controller.close();
    });
  });
}

void testZlibWithDictionary() {
  var dict = [102, 111, 111, 98, 97, 114];
  var data = [98, 97, 114, 102, 111, 111];

  [3, 6, 9].forEach((level) {
    var encoded = new ZLibEncoder(level: level, dictionary: dict).convert(data);
    var decoded = new ZLibDecoder(dictionary: dict).convert(encoded);
    Expect.listEquals(data, decoded);
  });
}

var generateListTypes = [
  (list) => list,
  (list) => new Uint8List.fromList(list),
  (list) => new Int8List.fromList(list),
  (list) => new Uint16List.fromList(list),
  (list) => new Int16List.fromList(list),
  (list) => new Uint32List.fromList(list),
  (list) => new Int32List.fromList(list),
];

var generateViewTypes = [
  (list) => new Uint8List.view((new Uint8List.fromList(list)).buffer, 1, 8),
  (list) => new Int8List.view((new Int8List.fromList(list)).buffer, 1, 8),
  (list) => new Uint16List.view((new Uint16List.fromList(list)).buffer, 2, 6),
  (list) => new Int16List.view((new Int16List.fromList(list)).buffer, 2, 6),
  (list) => new Uint32List.view((new Uint32List.fromList(list)).buffer, 4, 4),
  (list) => new Int32List.view((new Int32List.fromList(list)).buffer, 4, 4),
];

void main() {
  asyncStart();
  testZLibDeflateEmpty();
  testZLibDeflateEmptyGzip();
  testZLibDeflateInvalidLevel();
  generateListTypes.forEach((f) {
    var data = f([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    testZLibDeflate(data);
    testZLibDeflateGZip(data);
    testZLibDeflateRaw(data);
    testZLibInflate(data);
    testZLibInflateSync(data);
    testZLibInflateRaw(data);
  });
  generateViewTypes.forEach((f) {
    var data = f([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    testZLibInflate(data);
    testZLibInflateSync(data);
    testZLibInflateRaw(data);
  });
  testZlibInflateThrowsWithSmallerWindow();
  testZlibInflateWithLargerWindow();
  testZlibWithDictionary();
  asyncEnd();
}

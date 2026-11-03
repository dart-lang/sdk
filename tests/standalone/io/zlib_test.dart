// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void testZLibDeflateEmpty() {
  asyncStart();
  var controller = new StreamController<List<int>>(sync: true);
  controller.stream
      .transform(new ZLibEncoder(gzip: false, level: 6))
      .fold<List<int>>([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
        Expect.listEquals([120, 156, 3, 0, 0, 0, 0, 1], data);
        asyncEnd();
      });
  controller.close();
}

void testZLibDeflateEmptyGzip() {
  asyncStart();
  var controller = new StreamController<List<int>>(sync: true);
  controller.stream
      .transform(new ZLibEncoder(gzip: true, level: 6))
      .fold<List<int>>(<int>[], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
        Expect.isTrue(data.length > 0);
        Expect.listEquals([], new ZLibDecoder().convert(data));
        asyncEnd();
      });
  controller.close();
}

void testZLibDeflate(List<int> data) {
  asyncStart();
  var controller = new StreamController<List<int>>(sync: true);
  controller.stream
      .transform(new ZLibEncoder(gzip: false, level: 6))
      .fold<List<int>>([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
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
          46,
        ], data);
        asyncEnd();
      });
  controller.add(data);
  controller.close();
}

void testZLibDeflateGZip(List<int> data) {
  asyncStart();
  var controller = new StreamController<List<int>>(sync: true);
  controller.stream
      .transform(new ZLibEncoder(gzip: true))
      .fold<List<int>>([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
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
            0,
          ],
          // Skip header, as it can change.
          data.sublist(10),
        );
        asyncEnd();
      });
  controller.add(data);
  controller.close();
}

void testZLibDeflateRaw(List<int> data) {
  asyncStart();
  var controller = new StreamController<List<int>>(sync: true);
  controller.stream
      .transform(new ZLibEncoder(raw: true, level: 6))
      .fold<List<int>>([], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      })
      .then((data) {
        Expect.listEquals([
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
        ], data);
        asyncEnd();
      });
  controller.add(data);
  controller.close();
}

void testZLibDeflateInvalidLevel() {
  [true, false].forEach((gzip) {
    [-2, -20, 10, 42].forEach((level) {
      Expect.throwsArgumentError(
        () => new ZLibEncoder(gzip: gzip, level: level),
        "'level' must be in range -1..9",
      );
    });
  });
}

void testZLibInflate(List<int> data) {
  [true, false].forEach((gzip) {
    [
      ZLibOption.strategyFiltered,
      ZLibOption.strategyHuffmanOnly,
      ZLibOption.strategyRle,
      ZLibOption.strategyFixed,
      ZLibOption.strategyDefault,
    ].forEach((strategy) {
      [3, 6, 9].forEach((level) {
        asyncStart();
        var controller = new StreamController<List<int>>(sync: true);
        controller.stream
            .transform(
              new ZLibEncoder(gzip: gzip, level: level, strategy: strategy),
            )
            .transform(new ZLibDecoder())
            .fold<List<int>>([], (buffer, data) {
              buffer.addAll(data);
              return buffer;
            })
            .then((inflated) {
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
    var controller = new StreamController<List<int>>(sync: true);
    controller.stream
        .transform(new ZLibEncoder(raw: true, level: level))
        .transform(new ZLibDecoder(raw: true))
        .fold<List<int>>([], (buffer, data) {
          buffer.addAll(data);
          return buffer;
        })
        .then((inflated) {
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
      var controller = new StreamController<List<int>>(sync: true);
      controller.stream
          .transform(new ZLibEncoder(gzip: gzip, level: level, windowBits: 8))
          .transform(new ZLibDecoder(windowBits: 10))
          .fold<List<int>>([], (buffer, data) {
            buffer.addAll(data);
            return buffer;
          })
          .then((inflated) {
            Expect.listEquals(data, inflated);
            asyncEnd();
          });
      controller.add(data);
      controller.close();
    });
  });
}

void testRoundTripLarge() {
  for (var gzip in [true, false]) {
    for (var strategy in [
      ZLibOption.strategyFiltered,
      ZLibOption.strategyHuffmanOnly,
      ZLibOption.strategyRle,
      ZLibOption.strategyFixed,
      ZLibOption.strategyDefault,
    ]) {
      final uncompressedData = List.generate(2000000, (i) => i % 256);
      final compressedData = ZLibEncoder(
        gzip: gzip,
        strategy: strategy,
      ).convert(uncompressedData);
      final decodedData = new ZLibDecoder().convert(compressedData);
      Expect.listEquals(uncompressedData, decodedData);
    }
  }
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

void testConcatenatedBlocksGZip() {
  /// gzip files consist of concatenated compressed data sets.
  /// See RFC-1952.
  final compressedData = [
    ...ZLibEncoder().convert([1, 2, 3]),
    ...ZLibEncoder().convert([4, 5, 6]),
  ];
  final decodedData = new ZLibDecoder(gzip: true).convert(compressedData);
  Expect.listEquals([1, 2, 3, 4, 5, 6], decodedData);
}

// https://dartbug.com/64218

// An empty gzip member before a member with data.
void testGZipEmptyMemberFirst() {
  final compressedData = [
    // An empty member: header, empty deflate block, CRC-32 and size.
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff,
    0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    // A member of "hello": header, deflate data, CRC-32 and size.
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff,
    0xcb, 0x48, 0xcd, 0xc9, 0xc9, 0x07, 0x00, 0x86, 0xa6, 0x10,
    0x36, 0x05, 0x00, 0x00, 0x00,
  ];
  Expect.listEquals(utf8.encode('hello'), gzip.decode(compressedData));
  Expect.listEquals(
    [1, 2, 3],
    gzip.decode([
      ...gzip.encode([]),
      ...gzip.encode([1, 2, 3]),
    ]),
  );
}

// An empty gzip member between two members with data.
void testGZipEmptyMemberMiddle() {
  final compressedData = [
    ...gzip.encode([1, 2, 3]),
    ...gzip.encode([]),
    ...gzip.encode([4, 5, 6]),
  ];
  Expect.listEquals([1, 2, 3, 4, 5, 6], gzip.decode(compressedData));
}

// Several empty gzip members in a row, only empty ones, and an empty last one.
void testGZipEmptyMembers() {
  Expect.listEquals(
    [7],
    gzip.decode([
      ...gzip.encode([]),
      ...gzip.encode([]),
      ...gzip.encode([]),
      ...gzip.encode([7]),
    ]),
  );
  Expect.listEquals([], gzip.decode([...gzip.encode([]), ...gzip.encode([])]));
  Expect.listEquals(
    [1, 2, 3],
    gzip.decode([
      ...gzip.encode([1, 2, 3]),
      ...gzip.encode([]),
    ]),
  );
}

// Invalid data after an empty gzip member is an error.
void testGZipInvalidDataAfterEmptyMember() {
  Expect.throwsFormatException(
    () => gzip.decode([...gzip.encode([]), 1, 2, 3]),
  );
}

// Data after an empty zlib stream is not decoded: only gzip has members.
void testZLibDataAfterEmptyStream() {
  final compressedData = [
    ...ZLibEncoder().convert([]),
    ...ZLibEncoder().convert([1, 2, 3]),
  ];
  Expect.listEquals([], ZLibDecoder(gzip: false).convert(compressedData));
}

// Deterministic letters A to D, enough to fill several output buffers.
List<int> _pseudoRandomLetters(int length, int seed) {
  var state = seed;
  return List<int>.generate(length, (_) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return 0x41 + (state >> 16) % 4;
  });
}

// An empty gzip member between two members larger than the output buffer.
void testGZipEmptyMemberBetweenLargeMembers() {
  final first = _pseudoRandomLetters(200000, 1);
  final second = _pseudoRandomLetters(200000, 2);
  final decodedData = gzip.decode([
    ...gzip.encode(first),
    ...gzip.encode([]),
    ...gzip.encode(second),
  ]);
  Expect.equals(first.length + second.length, decodedData.length);
  Expect.listEquals([...first, ...second], decodedData);
}

// Decodes [chunks] as consecutive add() calls to one chunked gzip decoder.
void _expectGZipChunks(
  List<int> expected,
  List<List<int>> chunks,
  String where,
) {
  final out = <int>[];
  try {
    final sink = ZLibDecoder(gzip: true)
        .startChunkedConversion(ByteConversionSink.withCallback(out.addAll));
    for (final chunk in chunks) {
      sink.add(chunk);
    }
    sink.close();
  } catch (e) {
    Expect.fail('$where: $e');
  }
  Expect.listEquals(expected, out, where);
}

// Concatenated gzip members given in two chunks split at every position,
// including inside a member's trailer.
void testGZipChunkBoundaries() {
  final first = utf8.encode('first\n');
  final second = utf8.encode('second\n');
  final withEmpty = [
    ...gzip.encode(first),
    ...gzip.encode([]),
    ...gzip.encode(second),
  ];
  final withoutEmpty = [...gzip.encode(first), ...gzip.encode(second)];
  for (var i = 0; i <= withEmpty.length; i++) {
    _expectGZipChunks(
      [...first, ...second],
      [withEmpty.sublist(0, i), withEmpty.sublist(i)],
      'empty member between, split at $i of ${withEmpty.length}',
    );
  }
  for (var i = 0; i <= withoutEmpty.length; i++) {
    _expectGZipChunks(
      [...first, ...second],
      [withoutEmpty.sublist(0, i), withoutEmpty.sublist(i)],
      'no empty member, split at $i of ${withoutEmpty.length}',
    );
  }
}

// Concatenated gzip members given in three chunks split at every pair of
// positions, so that an add() follows a chunk that ended inside a trailer.
void testGZipChunkBoundariesThreeChunks() {
  final first = utf8.encode('first\n');
  final second = utf8.encode('second\n');
  final compressedData = [
    ...gzip.encode(first),
    ...gzip.encode([]),
    ...gzip.encode(second),
  ];
  for (var i = 0; i <= compressedData.length; i++) {
    for (var j = i; j <= compressedData.length; j++) {
      _expectGZipChunks(
        [...first, ...second],
        [
          compressedData.sublist(0, i),
          compressedData.sublist(i, j),
          compressedData.sublist(j),
        ],
        'split at $i and $j of ${compressedData.length}',
      );
    }
  }
}

void testConcatenatedBlocksZLib() {
  // RFC-1950 says: Any data which may appear after ADLER32 are not part of
  // the zlib stream.
  final compressedData = [
    ...ZLibEncoder().convert([1, 2, 3]),
    ...ZLibEncoder().convert([4, 5, 6]),
  ];
  final decodedData = new ZLibDecoder(gzip: false).convert(compressedData);
  Expect.listEquals([1, 2, 3], decodedData);
}

void testInvalidDataAfterBlockGZip() {
  /// gzip files consist of concatenated compressed data sets.
  /// See RFC-1952.
  final compressedData = [
    ...ZLibEncoder().convert([1, 2, 3]),
    1,
    2,
    3,
  ];

  Expect.throwsFormatException(
    () => new ZLibDecoder(gzip: true).convert(compressedData),
  );
}

void testInvalidDataAfterBlockZLib() {
  // RFC-1950 says: Any data which may appear after ADLER32 are not part of
  // the zlib stream.
  final compressedData = [
    ...ZLibEncoder().convert([1, 2, 3]),
    1,
    2,
    3,
  ];

  final decodedData = new ZLibDecoder(gzip: false).convert(compressedData);
  Expect.listEquals([1, 2, 3], decodedData);
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
  testRoundTripLarge();
  testZlibWithDictionary();
  testConcatenatedBlocksGZip();
  testGZipEmptyMemberFirst();
  testGZipEmptyMemberMiddle();
  testGZipEmptyMembers();
  testGZipInvalidDataAfterEmptyMember();
  testZLibDataAfterEmptyStream();
  testGZipEmptyMemberBetweenLargeMembers();
  testGZipChunkBoundaries();
  testGZipChunkBoundariesThreeChunks();
  testConcatenatedBlocksZLib();
  testInvalidDataAfterBlockGZip();
  testInvalidDataAfterBlockZLib();
  asyncEnd();
}

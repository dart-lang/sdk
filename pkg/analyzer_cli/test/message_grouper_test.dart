// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_cli/src/message_grouper.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  MessageGrouper messageGrouper;
  TestStdinStream stdinStream;

  setUp(() {
    stdinStream = new TestStdinStream();
    messageGrouper = new MessageGrouper(stdinStream);
  });

  group('message_grouper', () {
    /// Check that if the message grouper produces the [expectedOutput] in
    /// response to the corresponding [input].
    void check(List<int> input, List<List<int>> expectedOutput) {
      stdinStream.addInputBytes(input);
      for (var chunk in expectedOutput) {
        expect(messageGrouper.next, equals(chunk));
      }
    }

    /// Make a simple message having the given [length]
    List<int> makeMessage(int length) {
      var result = <int>[];
      for (int i = 0; i < length; i++) {
        result.add(i & 0xff);
      }
      return result;
    }

    test('Empty message', () {
      check([0], [[]]);
    });

    test('Short message', () {
      check([
        5,
        10,
        20,
        30,
        40,
        50
      ], [
        [10, 20, 30, 40, 50]
      ]);
    });

    test('Message with 2-byte length', () {
      var len = 0x155;
      var msg = makeMessage(len);
      var encodedLen = [0xd5, 0x02];
      check([]..addAll(encodedLen)..addAll(msg), [msg]);
    });

    test('Message with 3-byte length', () {
      var len = 0x4103;
      var msg = makeMessage(len);
      var encodedLen = [0x83, 0x82, 0x01];
      check([]..addAll(encodedLen)..addAll(msg), [msg]);
    });

    test('Multiple messages', () {
      check([
        2,
        10,
        20,
        2,
        30,
        40
      ], [
        [10, 20],
        [30, 40]
      ]);
    });

    test('Empty message at start', () {
      check([
        0,
        2,
        10,
        20
      ], [
        [],
        [10, 20]
      ]);
    });

    test('Empty message at end', () {
      check([
        2,
        10,
        20,
        0
      ], [
        [10, 20],
        []
      ]);
    });

    test('Empty message in the middle', () {
      check([
        2,
        10,
        20,
        0,
        2,
        30,
        40
      ], [
        [10, 20],
        [],
        [30, 40]
      ]);
    });
  });
}

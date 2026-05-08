// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:test/test.dart';

import '../../../tool/log_player/message_equality.dart';

void main() {
  group('MessageEquality', () {
    test('matches identical messages with params (request)', () {
      var m1 = Message({
        'method': 'foo',
        'params': {'a': 1, 'b': 2},
      });
      var m2 = Message({
        'method': 'foo',
        'params': {'a': 1, 'b': 2},
      });
      expect(MessageEquality().equals(m1, m2), isTrue);
    });

    test('matches identical messages with result (response)', () {
      var m1 = Message({
        'id': 1,
        'result': {'a': 1, 'b': 2},
      });
      var m2 = Message({
        'id': 1,
        'result': {'a': 1, 'b': 2},
      });
      expect(MessageEquality().equals(m1, m2), isTrue);
    });

    test('mismatches messages with different params', () {
      var m1 = Message({
        'method': 'foo',
        'params': {'a': 1},
      });
      var m2 = Message({
        'method': 'foo',
        'params': {'a': 2},
      });
      expect(MessageEquality().equals(m1, m2), isFalse);
    });

    test('mismatches messages with different result', () {
      var m1 = Message({
        'id': 1,
        'result': {'a': 1},
      });
      var m2 = Message({
        'id': 1,
        'result': {'a': 2},
      });
      expect(MessageEquality().equals(m1, m2), isFalse);
    });

    test('ignores ID when skipMatchId is true', () {
      var m1 = Message({
        'id': 1,
        'result': {'a': 1},
      });
      var m2 = Message({
        'id': 2,
        'result': {'a': 1},
      });
      expect(MessageEquality().equals(m1, m2, skipMatchId: true), isTrue);
    });

    test('respects ID when skipMatchId is false (default)', () {
      var m1 = Message({
        'id': 1,
        'result': {'a': 1},
      });
      var m2 = Message({
        'id': 2,
        'result': {'a': 1},
      });
      expect(MessageEquality().equals(m1, m2), isFalse);
    });

    test('matches params with ignored key differences', () {
      var m1 = Message({
        'method': 'foo',
        'params': {'a': 1, 'ignoreMe': 2},
      });
      var m2 = Message({
        'method': 'foo',
        'params': {'a': 1, 'ignoreMe': 3},
      });
      expect(MessageEquality(ignoredKeys: {'ignoreMe'}).equals(m1, m2), isTrue);
    });

    test('matches result with ignored key differences', () {
      var m1 = Message({
        'id': 1,
        'result': {'a': 1, 'ignoreMe': 2},
      });
      var m2 = Message({
        'id': 1,
        'result': {'a': 1, 'ignoreMe': 3},
      });
      expect(MessageEquality(ignoredKeys: {'ignoreMe'}).equals(m1, m2), isTrue);
    });

    test('matches nested maps in params with ignored keys', () {
      var m1 = Message({
        'method': 'foo',
        'params': {
          'nested': {'b': 2, 'ignoreMe': 3},
        },
      });
      var m2 = Message({
        'method': 'foo',
        'params': {
          'nested': {'b': 2, 'ignoreMe': 4},
        },
      });
      expect(MessageEquality(ignoredKeys: {'ignoreMe'}).equals(m1, m2), isTrue);
    });

    test('matches unordered lists if they contain non-ints', () {
      var m1 = Message({
        'method': 'foo',
        'params': {
          'list': ['a', 'b', 'c'],
        },
      });
      var m2 = Message({
        'method': 'foo',
        'params': {
          'list': ['c', 'b', 'a'],
        },
      });
      expect(MessageEquality().equals(m1, m2), isTrue);
    });

    test('does not match unordered lists if all values are ints', () {
      var m1 = Message({
        'method': 'foo',
        'params': {
          'list': [1, 2, 3],
        },
      });
      var m2 = Message({
        'method': 'foo',
        'params': {
          'list': [3, 2, 1],
        },
      });
      expect(MessageEquality().equals(m1, m2), isFalse);
    });

    test('hashes match for equal objects with ignored keys', () {
      var m1 = Message({
        'method': 'foo',
        'params': {'a': 1, 'ignoreMe': 2},
      });
      var m2 = Message({
        'method': 'foo',
        'params': {'a': 1, 'ignoreMe': 3},
      });
      var equality = MessageEquality(ignoredKeys: {'ignoreMe'});
      expect(equality.hash(m1), equals(equality.hash(m2)));
    });
  });
}

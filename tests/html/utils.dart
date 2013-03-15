library TestUtils;

import 'dart:async';
import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';

/**
 * Verifies that [actual] has the same graph structure as [expected].
 * Detects cycles and DAG structure in Maps and Lists.
 */
verifyGraph(expected, actual) {
  var eItems = [];
  var aItems = [];

  message(path, reason) => path == ''
      ? reason
      : reason == null ? "path: $path" : "path: $path, $reason";

  walk(path, expected, actual) {
    if (expected is String || expected is num || expected == null) {
      expect(actual, equals(expected), reason: message(path, 'not equal'));
      return;
    }

    // Cycle or DAG?
    for (int i = 0; i < eItems.length; i++) {
      if (identical(expected, eItems[i])) {
        expect(actual, same(aItems[i]),
            reason: message(path, 'missing back or side edge'));
        return;
      }
    }
    for (int i = 0; i < aItems.length; i++) {
      if (identical(actual, aItems[i])) {
        expect(expected, same(eItems[i]),
            reason: message(path, 'extra back or side edge'));
        return;
      }
    }
    eItems.add(expected);
    aItems.add(actual);

    if (expected is ArrayBuffer) {
      expect(actual is ArrayBuffer, isTrue,
          reason: '$actual is ArrayBuffer');
      expect(expected.byteLength, equals(actual.byteLength),
          reason: message(path, '.byteLength'));
      // TODO(antonm): one can create a view on top of those
      // and check if contents identical.  Let's do it later.
      return;
    }

    if (expected is ArrayBufferView) {
      expect(actual is ArrayBufferView, isTrue,
          reason: '$actual is ArrayBufferView');
      walk('$path/.buffer', expected.buffer, actual.buffer);
      expect(expected.byteOffset, equals(actual.byteOffset),
          reason: message(path, '.byteOffset'));
      expect(expected.byteLength, equals(actual.byteLength),
          reason: message(path, '.byteLength'));
      // And also fallback to elements check below.
    }

    if (expected is List) {
      expect(actual, isList, reason: message(path, '$actual is List'));
      expect(actual.length, expected.length,
          reason: message(path, 'different list lengths'));
      for (var i = 0; i < expected.length; i++) {
        walk('$path[$i]', expected[i], actual[i]);
      }
      return;
    }

    if (expected is Map) {
      expect(actual, isMap, reason: message(path, '$actual is Map'));
      for (var key in expected.keys) {
        if (!actual.containsKey(key)) {
          expect(false, isTrue, reason: message(path, 'missing key "$key"'));
        }
        walk('$path["$key"]',  expected[key], actual[key]);
      }
      for (var key in actual.keys) {
        if (!expected.containsKey(key)) {
          expect(false, isTrue, reason: message(path, 'extra key "$key"'));
        }
      }
      return;
    }

    expect(false, isTrue, reason: 'Unhandled type: $expected');
  }

  walk('', expected, actual);
}

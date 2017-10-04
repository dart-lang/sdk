// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  setUp(() {
    window.localStorage['key1'] = 'val1';
    window.localStorage['key2'] = 'val2';
    window.localStorage['key3'] = 'val3';
  });

  tearDown(() {
    window.localStorage.clear();
  });

  test('containsValue', () {
    expect(window.localStorage.containsValue('does not exist'), isFalse);
    expect(window.localStorage.containsValue('key1'), isFalse);
    expect(window.localStorage.containsValue('val1'), isTrue);
    expect(window.localStorage.containsValue('val3'), isTrue);
  });

  test('containsKey', () {
    expect(window.localStorage.containsKey('does not exist'), isFalse);
    expect(window.localStorage.containsKey('val1'), isFalse);
    expect(window.localStorage.containsKey('key1'), isTrue);
    expect(window.localStorage.containsKey('key3'), isTrue);
  });

  test('[]', () {
    expect(window.localStorage['does not exist'], isNull);
    expect(window.localStorage['key1'], 'val1');
    expect(window.localStorage['key3'], 'val3');
  });

  test('[]=', () {
    expect(window.localStorage['key4'], isNull);
    window.localStorage['key4'] = 'val4';
    expect(window.localStorage['key4'], 'val4');

    expect(window.localStorage['key3'], 'val3');
    window.localStorage['key3'] = 'val3-new';
    expect(window.localStorage['key3'], 'val3-new');
  });

  test('putIfAbsent', () {
    expect(window.localStorage['key4'], isNull);
    expect(window.localStorage.putIfAbsent('key4', () => 'val4'), 'val4');
    expect(window.localStorage['key4'], 'val4');

    expect(window.localStorage['key3'], 'val3');
    expect(
        window.localStorage.putIfAbsent('key3', () {
          fail('should not be called');
          return 'unused';
        }),
        'val3');
    expect(window.localStorage['key3'], 'val3');
  });

  test('remove', () {
    expect(window.localStorage.remove('does not exist'), isNull);
    expect(window.localStorage.remove('key3'), 'val3');
    expect(window.localStorage, equals({'key1': 'val1', 'key2': 'val2'}));
  });

  test('clear', () {
    window.localStorage.clear();
    expect(window.localStorage, equals({}));
  });

  test('forEach', () {
    Map<String, String> results = {};
    window.localStorage.forEach((k, v) {
      results[k] = v;
    });
    expect(results, equals({'key1': 'val1', 'key2': 'val2', 'key3': 'val3'}));
  });

  test('getKeys', () {
    expect(window.localStorage.keys.toList(),
        unorderedEquals(['key1', 'key2', 'key3']));
  });

  test('getVals', () {
    expect(window.localStorage.values.toList(),
        unorderedEquals(['val1', 'val2', 'val3']));
  });

  test('length', () {
    expect(window.localStorage.length, 3);
    window.localStorage.clear();
    expect(window.localStorage.length, 0);
  });

  test('isEmpty', () {
    expect(window.localStorage.isEmpty, isFalse);
    window.localStorage.clear();
    expect(window.localStorage.isEmpty, isTrue);
  });
}

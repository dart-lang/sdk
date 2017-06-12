// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library LocalStorageTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  void testWithLocalStorage(String name, fn()) {
    test(name, () {
      window.localStorage['key1'] = 'val1';
      window.localStorage['key2'] = 'val2';
      window.localStorage['key3'] = 'val3';

      try {
        fn();
      } finally {
        window.localStorage.clear();
      }
    });
  }

  testWithLocalStorage('containsValue', () {
    expect(window.localStorage.containsValue('does not exist'), isFalse);
    expect(window.localStorage.containsValue('key1'), isFalse);
    expect(window.localStorage.containsValue('val1'), isTrue);
    expect(window.localStorage.containsValue('val3'), isTrue);
  });

  testWithLocalStorage('containsKey', () {
    expect(window.localStorage.containsKey('does not exist'), isFalse);
    expect(window.localStorage.containsKey('val1'), isFalse);
    expect(window.localStorage.containsKey('key1'), isTrue);
    expect(window.localStorage.containsKey('key3'), isTrue);
  });

  testWithLocalStorage('[]', () {
    expect(window.localStorage['does not exist'], isNull);
    expect(window.localStorage['key1'], 'val1');
    expect(window.localStorage['key3'], 'val3');
  });

  testWithLocalStorage('[]=', () {
    expect(window.localStorage['key4'], isNull);
    window.localStorage['key4'] = 'val4';
    expect(window.localStorage['key4'], 'val4');

    expect(window.localStorage['key3'], 'val3');
    window.localStorage['key3'] = 'val3-new';
    expect(window.localStorage['key3'], 'val3-new');
  });

  testWithLocalStorage('putIfAbsent', () {
    expect(window.localStorage['key4'], isNull);
    expect(window.localStorage.putIfAbsent('key4', () => 'val4'), 'val4');
    expect(window.localStorage['key4'], 'val4');

    expect(window.localStorage['key3'], 'val3');
    expect(
        window.localStorage.putIfAbsent('key3',
            () => expect(false, isTrue, reason: 'should not be called')),
        'val3');
    expect(window.localStorage['key3'], 'val3');
  });

  testWithLocalStorage('remove', () {
    expect(window.localStorage.remove('does not exist'), isNull);
    expect(window.localStorage.remove('key3'), 'val3');
    expect(window.localStorage, equals({'key1': 'val1', 'key2': 'val2'}));
  });

  testWithLocalStorage('clear', () {
    window.localStorage.clear();
    expect(window.localStorage, equals({}));
  });

  testWithLocalStorage('forEach', () {
    Map<String, String> results = {};
    window.localStorage.forEach((k, v) {
      results[k] = v;
    });
    expect(results, equals({'key1': 'val1', 'key2': 'val2', 'key3': 'val3'}));
  });

  testWithLocalStorage('getKeys', () {
    expect(window.localStorage.keys.toList(),
        unorderedEquals(['key1', 'key2', 'key3']));
  });

  testWithLocalStorage('getVals', () {
    expect(window.localStorage.values.toList(),
        unorderedEquals(['val1', 'val2', 'val3']));
  });

  testWithLocalStorage('length', () {
    expect(window.localStorage.length, 3);
    window.localStorage.clear();
    expect(window.localStorage.length, 0);
  });

  testWithLocalStorage('isEmpty', () {
    expect(window.localStorage.isEmpty, isFalse);
    window.localStorage.clear();
    expect(window.localStorage.isEmpty, isTrue);
  });
}

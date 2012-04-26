// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('LocalStorageTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

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
    Expect.isFalse(window.localStorage.containsValue('does not exist'));
    Expect.isFalse(window.localStorage.containsValue('key1'));
    Expect.isTrue(window.localStorage.containsValue('val1'));
    Expect.isTrue(window.localStorage.containsValue('val3'));
  });

  testWithLocalStorage('containsKey', () {
    Expect.isFalse(window.localStorage.containsKey('does not exist'));
    Expect.isFalse(window.localStorage.containsKey('val1'));
    Expect.isTrue(window.localStorage.containsKey('key1'));
    Expect.isTrue(window.localStorage.containsKey('key3'));
  });

  testWithLocalStorage('[]', () {
    Expect.isNull(window.localStorage['does not exist']);
    Expect.equals('val1', window.localStorage['key1']);
    Expect.equals('val3', window.localStorage['key3']);
  });

  testWithLocalStorage('[]=', () {
    Expect.isNull(window.localStorage['key4']);
    window.localStorage['key4'] = 'val4';
    Expect.equals('val4', window.localStorage['key4']);

    Expect.equals('val3', window.localStorage['key3']);
    window.localStorage['key3'] = 'val3-new';
    Expect.equals('val3-new', window.localStorage['key3']);
  });

  testWithLocalStorage('putIfAbsent', () {
    Expect.isNull(window.localStorage['key4']);
    Expect.equals('val4',
        window.localStorage.putIfAbsent('key4', () => 'val4'));
    Expect.equals('val4', window.localStorage['key4']);

    Expect.equals('val3', window.localStorage['key3']);
    Expect.equals('val3', window.localStorage.putIfAbsent(
            'key3', () => Expect.fail('should not be called')));
    Expect.equals('val3', window.localStorage['key3']);
  });

  testWithLocalStorage('remove', () {
    Expect.isNull(window.localStorage.remove('does not exist'));
    Expect.equals('val3', window.localStorage.remove('key3'));
    Expect.mapEquals({'key1': 'val1', 'key2': 'val2'}, window.localStorage);
  });

  testWithLocalStorage('clear', () {
    window.localStorage.clear();
    Expect.mapEquals({}, window.localStorage);
  });

  testWithLocalStorage('forEach', () {
    Map<String, String> results = {};
    window.localStorage.forEach((k, v) {
      results[k] = v;
    });
    Expect.mapEquals({'key1': 'val1', 'key2': 'val2', 'key3': 'val3'},
        results);
  });

  testWithLocalStorage('getKeys', () {
    Expect.setEquals(['key1', 'key2', 'key3'], window.localStorage.getKeys());
  });

  testWithLocalStorage('getVals', () {
    Expect.setEquals(['val1', 'val2', 'val3'],
        window.localStorage.getValues());
  });

  testWithLocalStorage('length', () {
    Expect.equals(3, window.localStorage.length);
    window.localStorage.clear();
    Expect.equals(0, window.localStorage.length);
  });

  testWithLocalStorage('isEmpty', () {
    Expect.isFalse(window.localStorage.isEmpty());
    window.localStorage.clear();
    Expect.isTrue(window.localStorage.isEmpty());
  });
}

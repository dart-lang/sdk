// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:front_end/src/byte_store/protected_file_byte_store.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProtectedKeysTest);
    defineReflectiveTests(ProtectedFileByteStoreTest);
  });
}

List<int> _b(int length) {
  return new List<int>.filled(length, 0);
}

@reflectiveTest
class ProtectedFileByteStoreTest {
  io.Directory cacheDirectory;
  String cachePath;
  ProtectedFileByteStore store;

  int time = 0;

  String get protectedKeysText {
    String path =
        pathos.join(cachePath, ProtectedFileByteStore.PROTECTED_FILE_NAME);
    return new io.File(path).readAsStringSync();
  }

  void setUp() {
    io.Directory systemTemp = io.Directory.systemTemp;
    cacheDirectory = systemTemp.createTempSync('ProtectedFileByteStoreTest');
    cachePath = cacheDirectory.absolute.path;
    store = new ProtectedFileByteStore(
        cachePath, new Duration(milliseconds: 10),
        cacheSizeBytes: 256, getCurrentTime: _getTime);
  }

  void tearDown() {
    try {
      cacheDirectory.deleteSync(recursive: true);
    } on io.FileSystemException {}
  }

  test_flush() {
    store.put('a', _b(1));
    store.put('b', _b(2));
    store.put('c', _b(3));
    store.put('d', _b(4));

    store.updateProtectedKeys(add: ['b', 'd']);

    // Flush, only protected 'b' and 'd' survive.
    store.flush();
    store.flush();
    _assertCacheContent({'b': 2, 'd': 4}, ['a', 'c']);

    // Remove 'b' and flush.
    // Only 'd' survives.
    store.updateProtectedKeys(remove: ['b']);
    store.flush();
    _assertCacheContent({'d': 4}, ['b']);
  }

  test_put() {
    store.put('a', _b(65));
    store.put('b', _b(63));
    store.put('c', _b(1));

    // We can access all results.
    expect(store.get('a'), hasLength(65));
    expect(store.get('b'), hasLength(63));
    expect(store.get('c'), hasLength(1));
    _assertCacheContent({'a': 65, 'b': 63, 'c': 1}, []);
  }

  test_put_reservedKey() {
    expect(() {
      store.put(ProtectedFileByteStore.PROTECTED_FILE_NAME, <int>[]);
    }, throwsArgumentError);
  }

  test_updateProtectedKeys_add() {
    store.updateProtectedKeys(add: ['a', 'b']);
    _assertKeys({'a': 0, 'b': 0});

    time++;
    store.updateProtectedKeys(add: ['c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 1});
  }

  test_updateProtectedKeys_add_hasSame() {
    store.updateProtectedKeys(add: ['a', 'b', 'c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 0});

    time++;
    store.updateProtectedKeys(add: ['b', 'd']);
    _assertKeys({'a': 0, 'b': 1, 'c': 0, 'd': 1});
  }

  test_updateProtectedKeys_add_removeTooOld() {
    store.updateProtectedKeys(add: ['a', 'b']);
    _assertKeys({'a': 0, 'b': 0});

    // Move time to 10 ms, both 'a' and 'b' are still alive.
    time = 10;
    store.updateProtectedKeys(add: ['c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 10});

    // Move time to 11 ms, now 'a' and 'b' are too old and removed.
    time = 11;
    store.updateProtectedKeys(add: ['d']);
    _assertKeys({'c': 10, 'd': 11});
  }

  test_updateProtectedKeys_addRemove() {
    store.updateProtectedKeys(add: ['a', 'b', 'c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 0});

    time++;
    store.updateProtectedKeys(add: ['d'], remove: ['b']);
    _assertKeys({'a': 0, 'c': 0, 'd': 1});
  }

  test_updateProtectedKeys_addRemove_same() {
    store.updateProtectedKeys(add: ['a', 'b', 'c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 0});

    time++;
    store.updateProtectedKeys(add: ['b'], remove: ['b']);
    _assertKeys({'a': 0, 'c': 0});
  }

  test_updateProtectedKeys_remove() {
    store.updateProtectedKeys(add: ['a', 'b', 'c']);
    _assertKeys({'a': 0, 'b': 0, 'c': 0});

    time++;
    store.updateProtectedKeys(remove: ['b']);
    _assertKeys({'a': 0, 'c': 0});
  }

  void _assertCacheContent(Map<String, int> includes, List<String> excludes) {
    Map<String, int> keyToLength = {};
    for (var file in cacheDirectory.listSync()) {
      String key = pathos.basename(file.path);
      if (file is io.File) {
        keyToLength[key] = file.lengthSync();
      }
    }
    includes.forEach((expectedKey, expectedLength) {
      expect(keyToLength, contains(expectedKey));
      expect(keyToLength, containsPair(expectedKey, expectedLength));
    });
    for (var excludedKey in excludes) {
      expect(keyToLength.keys, isNot(contains(excludedKey)));
    }
  }

  void _assertKeys(Map<String, int> expected) {
    var path =
        pathos.join(cachePath, ProtectedFileByteStore.PROTECTED_FILE_NAME);
    var text = new io.File(path).readAsStringSync();
    var keys = new ProtectedKeys.decode(text);
    expect(keys.map.keys, expected.keys);
    expected.forEach((key, start) {
      expect(keys.map, containsPair(key, start));
    });
  }

  int _getTime() => time;
}

@reflectiveTest
class ProtectedKeysTest {
  test_decode() {
    var keys = new ProtectedKeys({'/a/b/c': 10, '/a/d/e': 123});

    String text = keys.encode();
    expect(text, r'''
/a/b/c
10
/a/d/e
123''');

    keys = _decode(text);
    expect(keys.map['/a/b/c'], 10);
    expect(keys.map['/a/d/e'], 123);
  }

  test_decode_empty() {
    var keys = _decode('');
    expect(keys.map, isEmpty);
  }

  test_decode_error_notEvenNumberOfLines() {
    var keys = _decode('a');
    expect(keys.map, isEmpty);
  }

  test_decode_error_startIsEmpty() {
    var keys = _decode('a\n');
    expect(keys.map, isEmpty);
  }

  test_decode_error_startIsNotInt() {
    var keys = _decode('a\n1.23');
    expect(keys.map, isEmpty);
  }

  test_decode_error_startIsNotNumber() {
    var keys = _decode('a\nb');
    expect(keys.map, isEmpty);
  }

  test_removeOlderThan() {
    var keys = new ProtectedKeys({'a': 1, 'b': 2, 'c': 3});
    _assertKeys(keys, {'a': 1, 'b': 2, 'c': 3});

    keys.removeOlderThan(5, 7);
    _assertKeys(keys, {'b': 2, 'c': 3});
  }

  void _assertKeys(ProtectedKeys keys, Map<String, int> expected) {
    expect(keys.map.keys, expected.keys);
    expected.forEach((key, start) {
      expect(keys.map, containsPair(key, start));
    });
  }

  ProtectedKeys _decode(String text) {
    return new ProtectedKeys.decode(text);
  }
}

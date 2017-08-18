// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/byte_store/byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BytesMemoryCacheTest);
    defineReflectiveTests(MemoryCachingByteStoreTest);
    defineReflectiveTests(NullByteStoreTest);
  });
}

List<int> _b(int length) {
  return new List<int>(length);
}

@reflectiveTest
class BytesMemoryCacheTest {
  test_get_notFound_evict() {
    var cache = new BytesMemoryCache(100);

    // Request '1'.  Nothing found.
    expect(cache.get('1', _noBytes), isNull);

    // Add enough data to the store to force an eviction.
    cache.put('2', _b(40));
    cache.put('3', _b(40));
    cache.put('4', _b(40));
  }

  test_get_notFound_retry() {
    var cache = new BytesMemoryCache(100);

    // Request '1'.  Nothing found.
    expect(cache.get('1', _noBytes), isNull);

    // Request '1' again.
    // The previous `null` result should not have been cached.
    expect(cache.get('1', () => _b(40)), isNotNull);
  }

  test_get_put_evict() {
    var cache = new BytesMemoryCache(100);

    // Keys: [1, 2].
    cache.put('1', _b(40));
    cache.put('2', _b(50));

    // Request '1', so now it is the most recently used.
    // Keys: [2, 1].
    cache.get('1', _noBytes);

    // 40 + 50 + 30 > 100
    // So, '2' is evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), hasLength(40));
    expect(cache.get('2', _noBytes), isNull);
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  test_put_evict_first() {
    var cache = new BytesMemoryCache(100);

    // 40 + 50 < 100
    cache.put('1', _b(40));
    cache.put('2', _b(50));
    expect(cache.get('1', _noBytes), hasLength(40));
    expect(cache.get('2', _noBytes), hasLength(50));

    // 40 + 50 + 30 > 100
    // So, '1' is evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), isNull);
    expect(cache.get('2', _noBytes), hasLength(50));
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  test_put_evict_firstAndSecond() {
    var cache = new BytesMemoryCache(100);

    // 10 + 80 < 100
    cache.put('1', _b(10));
    cache.put('2', _b(80));
    expect(cache.get('1', _noBytes), hasLength(10));
    expect(cache.get('2', _noBytes), hasLength(80));

    // 10 + 80 + 30 > 100
    // So, '1' and '2' are evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), isNull);
    expect(cache.get('2', _noBytes), isNull);
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  static List<int> _noBytes() => null;
}

@reflectiveTest
class MemoryCachingByteStoreTest {
  test_get_notFound_evict() {
    var store = new NullByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // Request '1'.  Nothing found.
    cachingStore.get('1');

    // Add enough data to the store to force an eviction.
    cachingStore.put('2', _b(40));
    cachingStore.put('3', _b(40));
    cachingStore.put('4', _b(40));
  }

  test_get_notFound_retry() {
    var mockStore = new NullByteStore();
    var baseStore = new MemoryCachingByteStore(mockStore, 1000);
    var cachingStore = new MemoryCachingByteStore(baseStore, 100);

    // Request '1'.  Nothing found.
    expect(cachingStore.get('1'), isNull);

    // Add data to the base store, bypassing the caching store.
    baseStore.put('1', _b(40));

    // Request '1' again.  The previous `null` result should not have been
    // cached.
    expect(cachingStore.get('1'), isNotNull);
  }

  test_get_put_evict() {
    var store = new NullByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // Keys: [1, 2].
    cachingStore.put('1', _b(40));
    cachingStore.put('2', _b(50));

    // Request '1', so now it is the most recently used.
    // Keys: [2, 1].
    cachingStore.get('1');

    // 40 + 50 + 30 > 100
    // So, '2' is evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), hasLength(40));
    expect(cachingStore.get('2'), isNull);
    expect(cachingStore.get('3'), hasLength(30));
  }

  test_put_evict_first() {
    var store = new NullByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // 40 + 50 < 100
    cachingStore.put('1', _b(40));
    cachingStore.put('2', _b(50));
    expect(cachingStore.get('1'), hasLength(40));
    expect(cachingStore.get('2'), hasLength(50));

    // 40 + 50 + 30 > 100
    // So, '1' is evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), isNull);
    expect(cachingStore.get('2'), hasLength(50));
    expect(cachingStore.get('3'), hasLength(30));
  }

  test_put_evict_firstAndSecond() {
    var store = new NullByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // 10 + 80 < 100
    cachingStore.put('1', _b(10));
    cachingStore.put('2', _b(80));
    expect(cachingStore.get('1'), hasLength(10));
    expect(cachingStore.get('2'), hasLength(80));

    // 10 + 80 + 30 > 100
    // So, '1' and '2' are evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), isNull);
    expect(cachingStore.get('2'), isNull);
    expect(cachingStore.get('3'), hasLength(30));
  }
}

@reflectiveTest
class NullByteStoreTest {
  test_get() {
    var store = new NullByteStore();

    expect(store.get('1'), isNull);

    store.put('1', _b(10));
    expect(store.get('1'), isNull);
  }
}

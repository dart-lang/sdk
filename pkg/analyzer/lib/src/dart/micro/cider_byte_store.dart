// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/cache.dart';

class CacheData {
  final int id;
  final Uint8List bytes;

  CacheData(this.id, this.bytes);
}

/// Store of bytes associated with string keys and a hash.
///
/// Each key must be not longer than 100 characters and consist of only `[a-z]`,
/// `[0-9]`, `.` and `_` characters. The key cannot be an empty string, the
/// literal `.`, or contain the sequence `..`.
///
/// Note that associations are not guaranteed to be persistent. The value
/// associated with a key can change or become `null` at any point in time.
abstract class CiderByteStore {
  /// Return the bytes associated with the [key], and increment the reference
  /// count.
  ///
  /// Return `null` if the association does not exist.
  Uint8List? get2(String key);

  /// Associate [bytes] with [key].
  /// Return an internalized version of [bytes], the reference count is `1`.
  ///
  /// This method will throw an exception if there is already an association
  /// for the [key]. The client should either use [get2] to access data,
  /// or first [release2] it.
  Uint8List putGet2(String key, Uint8List bytes);

  ///  Used to decrement reference count for the given ids, if implemented.
  void release(Iterable<int> ids);

  ///  Decrement the reference count for every key in [keys].
  void release2(Iterable<String> keys);
}

class CiderByteStoreTestView {
  int length = 0;
}

class CiderCachedByteStore implements CiderByteStore {
  final Cache<String, Uint8List> _cache;

  /// This field gets value only during testing.
  CiderByteStoreTestView? testView;

  CiderCachedByteStore(int maxCacheSize)
      : _cache = Cache<String, Uint8List>(maxCacheSize, (v) => v.length);

  @override
  Uint8List? get2(String key) {
    return _cache.get(key);
  }

  @override
  Uint8List putGet2(String key, Uint8List bytes) {
    _cache.put(key, bytes);
    testView?.length++;
    return bytes;
  }

  @override
  void release(Iterable<int> ids) {
    // do nothing
  }

  @override
  void release2(Iterable<String> keys) {
    // TODO(scheglov) implement
  }
}

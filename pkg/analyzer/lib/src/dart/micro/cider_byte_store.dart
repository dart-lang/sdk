// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:collection/collection.dart';

/// Store of bytes associated with string keys and a hash.
///
/// Each key must be not longer than 100 characters and consist of only `[a-z]`,
/// `[0-9]`, `.` and `_` characters. The key cannot be an empty string, the
/// literal `.`, or contain the sequence `..`.
///
/// Note that associations are not guaranteed to be persistent. The value
/// associated with a key can change or become `null` at any point in time.
abstract class CiderByteStore {
  /// Return the bytes associated with the errors for given [key] and
  /// [signature].
  ///
  /// Return `null` if the association does not exist.
  List<int> get(String key, List<int> signature);

  /// Associate the given [bytes] with the [key] and [digest].
  void put(String key, List<int> signature, List<int> bytes);
}

class CiderCachedByteStore implements CiderByteStore {
  final Cache<String, CiderCacheEntry> _cache;

  CiderCachedByteStore(int maxCacheSize)
      : _cache =
            Cache<String, CiderCacheEntry>(maxCacheSize, (v) => v.bytes.length);

  @override
  List<int> get(String key, List<int> signature) {
    var entry = _cache.get(key, () => null);

    if (entry != null &&
        const ListEquality<int>().equals(entry.signature, signature)) {
      return entry.bytes;
    }
    return null;
  }

  @override
  void put(String key, List<int> signature, List<int> bytes) {
    _cache.put(key, CiderCacheEntry(signature, bytes));
  }
}

class CiderCacheEntry {
  final List<int> signature;
  final List<int> bytes;

  CiderCacheEntry(this.signature, this.bytes);
}

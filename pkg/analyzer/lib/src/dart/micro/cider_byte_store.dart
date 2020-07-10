// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

class CiderMemoryByteStore implements CiderByteStore {
  final Map<String, _CiderCacheEntry> _map = {};

  @override
  List<int> get(String key, List<int> signature) {
    var entry = _map[key];

    if (entry != null &&
        const ListEquality().equals(entry.signature, signature)) {
      return entry.bytes;
    }
    return null;
  }

  @override
  void put(String key, List<int> signature, List<int> bytes) {
    _map[key] = _CiderCacheEntry(signature, bytes);
  }
}

class _CiderCacheEntry {
  final List<int> signature;
  final List<int> bytes;

  _CiderCacheEntry(this.signature, this.bytes);
}

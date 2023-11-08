// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary2/data_reader.dart';

abstract class InfoDeclarationStore {
  String createKey(SummaryDataReader reader, int initialOffset);
  E? get<E>(SummaryDataReader reader, String key, int initialOffset);
  void put(
      SummaryDataReader reader, String key, int initialOffset, Object value);
}

class InfoDeclarationStoreImpl implements InfoDeclarationStore {
  final Map<String, _InfoDeclarationStoreData> map = {};
  late final Finalizer _finalizer;

  InfoDeclarationStoreImpl() {
    _finalizer = Finalizer((key) {
      map.remove(key);
    });
  }

  @override
  String createKey(SummaryDataReader reader, int initialOffset) {
    return "${identityHashCode(reader.bytes)}|$initialOffset";
  }

  @override
  E? get<E>(SummaryDataReader reader, String key, int initialOffset) {
    final lookup = map[key];
    if (lookup != null) {
      if (identical(lookup.bytes.target, reader.bytes) &&
          lookup.offset == initialOffset) {
        final result = lookup.result.target;
        if (result is E) {
          reader.offset = lookup.endOffset;
          return result;
        }
      } else {
        map.remove(key);
      }
    }
    return null;
  }

  @override
  void put(
      SummaryDataReader reader, String key, int initialOffset, Object value) {
    // Assuming that the bytes will live longer than the result.
    _finalizer.attach(value, key);
    map[key] = _InfoDeclarationStoreData(WeakReference(reader.bytes),
        initialOffset, reader.offset, WeakReference(value));
  }
}

class NoOpInfoDeclarationStore implements InfoDeclarationStore {
  const NoOpInfoDeclarationStore();

  @override
  String createKey(SummaryDataReader reader, int initialOffset) {
    return "";
  }

  @override
  E? get<E>(SummaryDataReader reader, String key, int initialOffset) {
    return null;
  }

  @override
  void put(
      SummaryDataReader reader, String key, int initialOffset, Object value) {}
}

class _InfoDeclarationStoreData {
  final WeakReference<Uint8List> bytes;
  final int offset;
  final int endOffset;
  final WeakReference<Object> result;

  _InfoDeclarationStoreData(
      this.bytes, this.offset, this.endOffset, this.result);
}

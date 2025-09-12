// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:collection/collection.dart';

/// The globally unique identifier.
///
/// We give a new identifier each time when just anything changes about
/// an element. Even if an element changes as `A` to `B` to `A`, it will get
/// `id1`, `id2`, `id3`. Never `id1` again.
class ManifestItemId implements Comparable<ManifestItemId> {
  static const int _mod32 = 1 << 32;
  static const int _mask32 = _mod32 - 1;

  /// High 32 bits; bumps only when [_nextLo32] wraps.
  static int _hi32 = Random().nextInt(_mod32);

  /// Low 32-bit counter; seeded from wall time and increments mod 2^32.
  static int _nextLo32 = DateTime.now().microsecondsSinceEpoch & _mask32;

  final int hi32;
  final int lo32;

  factory ManifestItemId.generate() {
    _nextLo32 = (_nextLo32 + 1) & _mask32;
    if (_nextLo32 == 0) {
      _hi32 = (_hi32 + 1) & _mask32;
    }
    return ManifestItemId._(_hi32, _nextLo32);
  }

  factory ManifestItemId.read(SummaryDataReader reader) {
    return ManifestItemId._(reader.readUint32(), reader.readUint32());
  }

  ManifestItemId._(this.hi32, this.lo32)
    : assert(hi32 >= 0 && hi32 <= _mask32),
      assert(lo32 >= 0 && lo32 <= _mask32);

  @override
  int get hashCode => Object.hash(hi32, lo32);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestItemId && other.hi32 == hi32 && other.lo32 == lo32;
  }

  @override
  int compareTo(ManifestItemId other) {
    var result = hi32.compareTo(other.hi32);
    return result != 0 ? result : lo32.compareTo(other.lo32);
  }

  @override
  String toString() => '($hi32, $lo32)';

  void write(BufferedSink sink) {
    sink.writeUint32(hi32);
    sink.writeUint32(lo32);
  }

  static List<ManifestItemId> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestItemId.read(reader));
  }

  static ManifestItemId? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestItemId.read(reader));
  }
}

class ManifestItemIdList {
  final List<ManifestItemId> ids;

  ManifestItemIdList(this.ids);

  factory ManifestItemIdList.read(SummaryDataReader reader) {
    return ManifestItemIdList(ManifestItemId.readList(reader));
  }

  @override
  int get hashCode {
    return const ListEquality<ManifestItemId>().hash(ids);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestItemIdList &&
        const ListEquality<ManifestItemId>().equals(other.ids, ids);
  }

  bool equalToIterable(Iterable<ManifestItemId> other) {
    return const IterableEquality<ManifestItemId>().equals(ids, other);
  }

  @override
  String toString() {
    return '[${ids.join(', ')}]';
  }

  void write(BufferedSink sink) {
    sink.writeList(ids, (id) => id.write(sink));
  }

  static ManifestItemIdList? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestItemIdList.read(reader));
  }
}

extension ManifestItemIdExtension on ManifestItemId? {
  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) {
      it.write(sink);
    });
  }
}

extension ManifestItemIdListOrNullExtension on ManifestItemIdList? {
  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) => it.write(sink));
  }
}

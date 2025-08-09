// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:collection/collection.dart';

/// The globally unique identifier.
///
/// We give a new identifier each time when just anything changes about
/// an element. Even if an element changes as `A` to `B` to `A`, it will get
/// `id1`, `id2`, `id3`. Never `id1` again.
class ManifestItemId implements Comparable<ManifestItemId> {
  static final _randomGenerator = Random();

  final int timestamp;
  final int randomBits;

  factory ManifestItemId.generate() {
    var now = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    var randomBits = _randomGenerator.nextInt(0xFFFFFFFF);
    return ManifestItemId._(now, randomBits);
  }

  factory ManifestItemId.read(SummaryDataReader reader) {
    return ManifestItemId._(reader.readUInt32(), reader.readUInt32());
  }

  ManifestItemId._(this.timestamp, this.randomBits);

  @override
  int get hashCode => Object.hash(timestamp, randomBits);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestItemId &&
        other.timestamp == timestamp &&
        other.randomBits == randomBits;
  }

  @override
  int compareTo(ManifestItemId other) {
    var result = timestamp.compareTo(other.timestamp);
    if (result != 0) {
      return result;
    }
    return randomBits.compareTo(other.randomBits);
  }

  @override
  String toString() {
    return '($timestamp, $randomBits)';
  }

  void write(BufferedSink sink) {
    sink.writeUInt32(timestamp);
    sink.writeUInt32(randomBits);
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

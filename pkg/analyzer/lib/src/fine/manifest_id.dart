// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

/// The globally unique identifier.
///
/// We give a new identifier each time when just anything changes about
/// an element. Even if an element changes as `A` to `B` to `A`, it will get
/// `id1`, `id2`, `id3`. Never `id1` again.
class ManifestItemId {
  static final _randomGenerator = Random();

  final int timestamp;
  final int randomBits;

  factory ManifestItemId.generate() {
    var now = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    var randomBits = _randomGenerator.nextInt(0xFFFFFFFF);
    return ManifestItemId._(now, randomBits);
  }

  factory ManifestItemId.read(SummaryDataReader reader) {
    return ManifestItemId._(
      reader.readUInt32(),
      reader.readUInt32(),
    );
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
  String toString() {
    return '($timestamp, $randomBits)';
  }

  void write(BufferedSink sink) {
    sink.writeUInt32(timestamp);
    sink.writeUInt32(randomBits);
  }
}

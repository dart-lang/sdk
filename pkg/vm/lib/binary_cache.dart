// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.binary_cache;

import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io' show File, IOException;
import 'dart:typed_data' show ByteBuffer, Uint8List;

class Range {
  final int offset;
  final int length;

  Range(this.offset, this.length);

  @override
  String toString() => '[$offset, ${offset + length}]';
}

class BinaryCache {
  // Maps package name to binary data.
  final _cache = <String, Range>{};
  ByteBuffer data;

  Future<void> write(String descriptorPath) async {
    final entries = [];
    for (var package in _cache.keys) {
      final range = _cache[package];
      entries.add({
        'package': package,
        'offset': '${range.offset}',
        'length': '${range.length}'
      });
    }
    final String json = jsonEncode(entries);
    return new File(descriptorPath).writeAsString(json);
  }

  void read(String descriptorPath, String binaryPath) async {
    try {
      final entries = jsonDecode(await new File(descriptorPath).readAsString());
      for (var e in entries) {
        _cache[e['package']] =
            new Range(int.parse(e['offset']), int.parse(e['length']));
      }
    } on IOException {
      _cache.clear();
    }
    if (_cache.isEmpty) {
      return;
    }
    try {
      data = (await new File(binaryPath).readAsBytes()).buffer;
    } on IOException {
      _cache.clear();
    }
  }

  void invalidate(String package) {
    _cache.remove(package);
  }

  Range get(String package) => _cache[package];

  Uint8List getBytes(Range range) =>
      new Uint8List.view(data, range.offset, range.length);

  bool get isEmpty => _cache.isEmpty;

  void add(String package, Range data) {
    _cache[package] = data;
  }

  @override
  String toString() => _cache.toString();
}

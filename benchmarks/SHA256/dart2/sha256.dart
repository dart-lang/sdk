// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

const size = 8 * 1024;
const expected =
    'dc404a613fedaeb54034514bc6505f56b933caa5250299ba7d094377a51caa46';

class SHA256Bench extends BenchmarkBase {
  List<int> data;

  SHA256Bench() : super('SHA256') {
    data = List<int>(size);
    for (int i = 0; i < data.length; i++) {
      data[i] = i % 256;
    }
  }

  @override
  void warmup() {
    for (int i = 0; i < 4; i++) {
      run();
    }
  }

  @override
  void run() {
    final hash = sha256.convert(data);
    if (hex.encode(hash.bytes) != expected) {
      throw 'Incorrect HASH computed.';
    }
  }
}

void main() {
  SHA256Bench().report();
}

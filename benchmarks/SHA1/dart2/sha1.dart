// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

const size = 8 * 1024;
const expected = 'ecca46e1a1d0a6012713b09a870d84f695b6d9b0';

class SHA1Bench extends BenchmarkBase {
  List<int> data;

  SHA1Bench() : super('SHA1') {
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
    final hash = sha1.convert(data);
    if (hex.encode(hash.bytes) != expected) {
      throw 'Incorrect HASH computed.';
    }
  }
}

void main() {
  SHA1Bench().report();
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

const size = 8 * 1024;
const expected = '6556112372898c69e1de0bf689d8db26';

class MD5Bench extends BenchmarkBase {
  List<int> data;

  MD5Bench()
      : data = List<int>.generate(size, (i) => i % 256, growable: false),
        super('MD5');

  @override
  void warmup() {
    for (int i = 0; i < 4; i++) {
      run();
    }
  }

  @override
  void run() {
    final hash = md5.convert(data);
    if (hex.encode(hash.bytes) != expected) {
      throw 'Incorrect HASH computed.';
    }
  }
}

void main() {
  MD5Bench().report();
}

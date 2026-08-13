// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

class DartCLIStartup extends BenchmarkBase {
  const DartCLIStartup() : super('DartCLIStartup');

  // The benchmark code.
  @override
  void run() {
    Process.runSync(Platform.executable, ['help']);
  }
}

void main() {
  const DartCLIStartup().report();
}

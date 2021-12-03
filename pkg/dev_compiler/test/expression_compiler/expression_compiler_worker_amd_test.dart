// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:test/test.dart';

import 'expression_compiler_worker_shared.dart';

void main() async {
  group('amd module format -', () {
    for (var soundNullSafety in [true, false]) {
      group('${soundNullSafety ? "sound" : "unsound"} null safety -', () {
        runTests('amd', soundNullSafety);
      });
    }
  });
}

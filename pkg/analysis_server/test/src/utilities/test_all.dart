// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'flutter_test.dart' as flutter_test;
import 'profiling_test.dart' as profiling_test;

main() {
  defineReflectiveSuite(() {
    flutter_test.main();
    profiling_test.main();
  });
}

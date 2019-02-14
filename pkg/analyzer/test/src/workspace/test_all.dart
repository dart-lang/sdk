// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'basic_test.dart' as basic_test;
import 'bazel_test.dart' as bazel_test;
import 'gn_test.dart' as gn_test;
import 'package_build_test.dart' as package_build_test;

main() {
  defineReflectiveSuite(() {
    basic_test.main();
    bazel_test.main();
    gn_test.main();
    package_build_test.main();
  }, name: 'workspace');
}

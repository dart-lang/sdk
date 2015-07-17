// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that run the checker end-to-end using the file system.
library dev_compiler.test.checker.self_host_test;

import 'package:dev_compiler/devc.dart' show BatchCompiler;
import 'package:dev_compiler/src/options.dart';
import 'package:test/test.dart';
import '../testing.dart' show testDirectory, realSdkContext;

void main() {
  test('checker can run on itself ', () {
    new BatchCompiler(realSdkContext, new CompilerOptions())
        .compileFromUriString('$testDirectory/all_tests.dart');
  }, skip: 'test is very slow');
}

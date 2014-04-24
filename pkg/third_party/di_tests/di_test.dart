// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


library angular.di.test;

import 'package:unittest/unittest.dart';
import '../../../third_party/pkg/di/test/main.dart' as di;

/**
 * Tests Angular's DI package
 */
main() {

  group('main', () {
    di.main();
  });
}

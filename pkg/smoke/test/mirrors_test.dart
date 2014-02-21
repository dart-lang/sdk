// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library smoke.test.mirrors_test;

import 'package:smoke/mirrors.dart';
import 'package:unittest/unittest.dart';
import 'common.dart' as common show main;

main() {
  setUp(useMirrors);
  common.main();
}

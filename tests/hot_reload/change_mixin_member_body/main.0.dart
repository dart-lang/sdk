// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'class.dart';
import 'mixin.dart';

var c = C();

Future<void> main() async {
  Expect.equals('hello', c.fn());
  await hotReload();
  Expect.equals('goodbye', c.fn());
}

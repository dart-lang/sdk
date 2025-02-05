// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

void foo(int a) => a + 1;

Future<void> main() async {
  void Function() bar() {
    return () => foo(3);
  }

  final f = bar();
  await hotReload();
  Expect.throws<NoSuchMethodError>(f);
}

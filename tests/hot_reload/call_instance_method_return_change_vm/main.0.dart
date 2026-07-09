// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

int Function()? retained;
C? c;

class C {
  String returnChange() {
    return 'hello';
  }
}

helper() {
  c = C();
  retained = () => c!.returnChange().length;
  return retained!();
}

Future<void> main() async {
  helper();
  await hotReload();
  Expect.throws<NoSuchMethodError>(
    helper,
    (error) => '$error'.contains("'length'"),
  );
}

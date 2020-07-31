// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

library opted_out_lib;

import 'issue41496b_lib.dart' as opt_in;

typedef void LegacyFoo();

test(LegacyFoo f) {}

main() {
  opt_in.main();
}

// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--deterministic --deoptimize-on-runtime-call-every=1 --optimization-counter-threshold=1

import 'package:expect/expect.dart';

main() {
  final res = RegExp('a.*b');
  for (int i = 0; i < 100; ++i) {
    Expect.isNull(res.firstMatch('*** Failers'));
  }
}

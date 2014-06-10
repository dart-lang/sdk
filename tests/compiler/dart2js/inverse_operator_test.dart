// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String MAIN = r"""
int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));
main() {
  var x = 1;
  if (inscrutable(x) == 0) {
    main();
    x = 2;
  }
  print(!(1 < x));
}""";

main() {
  // Make sure we don't introduce a new variable.
  asyncTest(() => compileAndMatchFuzzy(MAIN, 'main', "1 >= x"));
}

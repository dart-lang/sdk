// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.benchmark.all;

import 'parse.dart' as parse;
import 'eval.dart' as eval;

main() {
  parse.main();
  eval.main();
}

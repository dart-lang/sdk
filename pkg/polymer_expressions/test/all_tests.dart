// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library all_tests;

import 'eval_test.dart' as eval;
import 'parser_test.dart' as parser;
import 'tokenizer_test.dart' as tokenizer;
import 'visitor_test.dart' as visitor;

main() {
  eval.main();
  parser.main();
  tokenizer.main();
  visitor.main();
}

// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that variable declarations in loops are reset in each
// iteration. (the `replacement` variable below)
//
// Before this test, getting this wrong in dart2wasm only caused one test
// failure in a large `dart:convert` test. This test is smaller and checks the
// same thing.

import 'package:expect/expect.dart';

const _TEST_INPUT = "<A>";

List<int?> _convert(String text) {
  List<int?> result = [];
  for (var i = 0; i < text.length; i++) {
    var ch = text[i];
    int? replacement;
    switch (ch) {
      case '<':
        replacement = 1;
      case '>':
        replacement = 2;
    }
    result.add(replacement);
  }
  return result;
}

void main() {
  Expect.listEquals(_convert("<A>"), [1, null, 2]);
}

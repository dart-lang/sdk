// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST = r"""
foo() {
  String s = new Object().toString();
  Object o = new Object().toString();
  return s == 'foo'
    && s == null
    && null == s
    && null == o;
}
""";

main() {
  asyncTest(() => compile(TEST, entry: 'foo', enableTypeAssertions: true,
      check: (String generated) {
    Expect.isTrue(!generated.contains('eqB'));

    RegExp regexp = new RegExp('==');
    Iterator<Match> matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 4);
  }));
}

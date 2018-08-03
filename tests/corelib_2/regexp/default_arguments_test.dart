// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `null` is interpreted as `false` when passed as argument to
// `caseSensitive` and `multiLine`.

import 'package:expect/expect.dart';

main() {
  testCaseSensitive();
  testMultiLine();
}

testCaseSensitive() {
  var r1 = new RegExp('foo');
  var r2 = new RegExp('foo', caseSensitive: true);
  var r3 = new RegExp('foo', caseSensitive: false);
  var r4 = new RegExp('foo', caseSensitive: null);
  Expect.isNull(r1.firstMatch('Foo'), "r1.firstMatch('Foo')");
  Expect.isNull(r2.firstMatch('Foo'), "r2.firstMatch('Foo')");
  Expect.isNotNull(r3.firstMatch('Foo'), "r3.firstMatch('Foo')");
  Expect.isNotNull(r4.firstMatch('Foo'), "r4.firstMatch('Foo')");
}

testMultiLine() {
  var r1 = new RegExp(r'^foo$');
  var r2 = new RegExp(r'^foo$', multiLine: true);
  var r3 = new RegExp(r'^foo$', multiLine: false);
  var r4 = new RegExp(r'^foo$', multiLine: null);
  Expect.isNull(r1.firstMatch('\nfoo\n'), "r1.firstMatch('\\nfoo\\n')");
  Expect.isNotNull(r2.firstMatch('\nfoo\n'), "r2.firstMatch('\\nfoo\\n')");
  Expect.isNull(r3.firstMatch('\nfoo\n'), "r3.firstMatch('\\nfoo\\n')");
  Expect.isNull(r4.firstMatch('\nfoo\n'), "r4.firstMatch('\\nfoo\\n')");
}

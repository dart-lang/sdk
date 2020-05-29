// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// This file contains tests of assertions when assertions are _disabled_. The
/// file 'general7_ea.dart' contains similar tests for when assertions are
/// _enabled_.

/*member: foo:[null]*/
foo(/*[exact=JSUInt31]*/ x, [/*[null]*/ y]) => y;

/*member: main:[null]*/
main() {
  assert(foo('Hi', true), foo(true));
  foo(1);
}

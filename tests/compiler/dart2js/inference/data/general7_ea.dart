// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'general7.dart' contains similar tests for when assertions are
/// _disabled_.

/*member: foo:Value([null|exact=JSBool], value: true)*/
foo(
        /*Union([exact=JSBool], [exact=JSString], [exact=JSUInt31])*/ x,
        [/*Value([null|exact=JSBool], value: true)*/ y]) =>
    y;

/*member: main:[null]*/
main() {
  assert(foo('Hi', true), foo(true));
  foo(1);
}

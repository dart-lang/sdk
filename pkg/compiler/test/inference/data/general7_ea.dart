// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'general7.dart' contains similar tests for when assertions are
/// _disabled_.

/*member: foo:Value([null|exact=JSBool|powerset=1], value: true, powerset: 1)*/
foo(
  /*Union([exact=JSBool|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ x, [
  /*Value([null|exact=JSBool|powerset=1], value: true, powerset: 1)*/ y,
]) => y;

/*member: main:[null|powerset=1]*/
main() {
  assert(foo('Hi', true), foo(true));
  foo(1);
}

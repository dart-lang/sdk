// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'general7.dart' contains similar tests for when assertions are
/// _disabled_.

/*member: foo:Value([null|exact=JSBool|powerset={null}{I}{O}{N}], value: true, powerset: {null}{I}{O}{N})*/
foo(
  /*Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ x, [
  /*Value([null|exact=JSBool|powerset={null}{I}{O}{N}], value: true, powerset: {null}{I}{O}{N})*/ y,
]) => y;

/*member: main:[null|powerset={null}]*/
main() {
  assert(foo('Hi', true), foo(true));
  foo(1);
}

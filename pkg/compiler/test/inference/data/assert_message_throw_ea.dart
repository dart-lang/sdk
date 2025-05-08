// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'assert_message_throw.dart' contains similar tests for when assertions
/// are _disabled_.

/*member: main:[null|powerset={null}]*/
main(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ args) {
  test0();
  test1(args == null);
  test2(args == null);
  test3(args);
}

// Check that `throw` in the message is handled conditionally.
/*member: test0:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})*/
test0() {
  assert(true, throw "unreachable");
  var list = [];
  return list;
}

// Check that side-effects of the assert message is not included after the
// assert.
/*member: test1:[null|powerset={null}]*/
test1(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  var a;
  assert(b, a = 42);
  return a;
}

// Check that side-effects of the assert message is included after the assert
// through the thrown exception.
/*member: test2:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
test2(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

// Check that type tests are preserved after the assert.
/*member: test3:[subclass=JSInt|powerset={I}{O}{N}]*/
test3(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  assert(a is int);
  return a;
}

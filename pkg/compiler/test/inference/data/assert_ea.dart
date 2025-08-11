// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'assert.dart' contains similar tests for when assertions are
/// _disabled_.

/*member: main:[null|powerset={null}]*/
main() {
  simpleAssert();
  failingAssert();
  simpleAssertWithMessage();
  promoteLocalAssert();
  promoteParameterAssert();
  unreachableThrow();
  messageWithSideEffect();
  messageWithCaughtSideEffect();
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement known to be valid.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleAssert:[null|powerset={null}]*/
simpleAssert() {
  assert(true);
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement known to be invalid.
////////////////////////////////////////////////////////////////////////////////

/*member: failingAssert:[exact=JSUInt31|powerset={I}{O}{N}]*/
failingAssert() {
  assert(false);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement with message known to be valid.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleAssertWithMessage:[null|powerset={null}]*/
simpleAssertWithMessage() {
  assert(true, 'foo');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteLocalAssert:[exact=JSUInt31|powerset={I}{O}{N}]*/
_promoteLocalAssert(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ o,
) {
  var local = o;
  assert(local is int);
  return local;
}

/*member: promoteLocalAssert:[null|powerset={null}]*/
promoteLocalAssert() {
  _promoteLocalAssert(0);
  _promoteLocalAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteParameterAssert:[exact=JSUInt31|powerset={I}{O}{N}]*/
_promoteParameterAssert(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ o,
) {
  assert(o is int);
  return o;
}

/*member: promoteParameterAssert:[null|powerset={null}]*/
promoteParameterAssert() {
  _promoteParameterAssert(0);
  _promoteParameterAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement with an unreachable throw.
////////////////////////////////////////////////////////////////////////////////

/*member: unreachableThrow:[exact=JSUInt31|powerset={I}{O}{N}]*/
unreachableThrow() {
  assert(true, throw "unreachable");
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithSideEffect:[null|powerset={null}]*/
_messageWithSideEffect(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  var a;
  assert(b, a = 42);
  return a;
}

/*member: messageWithSideEffect:[null|powerset={null}]*/
messageWithSideEffect() {
  _messageWithSideEffect(true);
  _messageWithSideEffect(false);
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a caught side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithCaughtSideEffect:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
_messageWithCaughtSideEffect(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

/*member: messageWithCaughtSideEffect:[null|powerset={null}]*/
messageWithCaughtSideEffect() {
  _messageWithCaughtSideEffect(true);
  _messageWithCaughtSideEffect(false);
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _disabled_. The
/// file 'assert_ea.dart' contains similar tests for when assertions are
/// _enabled_.

/*member: main:[null|powerset=1]*/
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

/*member: simpleAssert:[null|powerset=1]*/
simpleAssert() {
  assert(true);
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement known to be invalid.
////////////////////////////////////////////////////////////////////////////////

/*member: failingAssert:[exact=JSUInt31|powerset=0]*/
failingAssert() {
  assert(false);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement with message known to be valid.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleAssertWithMessage:[null|powerset=1]*/
simpleAssertWithMessage() {
  assert(true, 'foo');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteLocalAssert:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_promoteLocalAssert(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  var local = o;
  assert(local is int);
  return local;
}

/*member: promoteLocalAssert:[null|powerset=1]*/
promoteLocalAssert() {
  _promoteLocalAssert(0);
  _promoteLocalAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteParameterAssert:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_promoteParameterAssert(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  assert(o is int);
  return o;
}

/*member: promoteParameterAssert:[null|powerset=1]*/
promoteParameterAssert() {
  _promoteParameterAssert(0);
  _promoteParameterAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement with an unreachable throw.
////////////////////////////////////////////////////////////////////////////////

/*member: unreachableThrow:[exact=JSUInt31|powerset=0]*/
unreachableThrow() {
  assert(true, throw "unreachable");
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithSideEffect:[null|powerset=1]*/
_messageWithSideEffect(/*[exact=JSBool|powerset=0]*/ b) {
  var a;
  assert(b, a = 42);
  return a;
}

/*member: messageWithSideEffect:[null|powerset=1]*/
messageWithSideEffect() {
  _messageWithSideEffect(true);
  _messageWithSideEffect(false);
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a caught side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithCaughtSideEffect:[null|powerset=1]*/
_messageWithCaughtSideEffect(/*[exact=JSBool|powerset=0]*/ b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

/*member: messageWithCaughtSideEffect:[null|powerset=1]*/
messageWithCaughtSideEffect() {
  _messageWithCaughtSideEffect(true);
  _messageWithCaughtSideEffect(false);
}

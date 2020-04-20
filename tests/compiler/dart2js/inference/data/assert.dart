// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// This file contains tests of assertions when assertions are _disabled_. The
/// file 'assert_ea.dart' contains similar tests for when assertions are
/// _enabled_.

/*member: main:[null]*/
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

/*member: simpleAssert:[null]*/
simpleAssert() {
  assert(true);
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement known to be invalid.
////////////////////////////////////////////////////////////////////////////////

/*member: failingAssert:[exact=JSUInt31]*/
failingAssert() {
  assert(false);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement with message known to be valid.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleAssertWithMessage:[null]*/
simpleAssertWithMessage() {
  assert(true, 'foo');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteLocalAssert:Union([exact=JSString], [exact=JSUInt31])*/
_promoteLocalAssert(/*Union([exact=JSString], [exact=JSUInt31])*/ o) {
  var local = o;
  assert(local is int);
  return local;
}

/*member: promoteLocalAssert:[null]*/
promoteLocalAssert() {
  _promoteLocalAssert(0);
  _promoteLocalAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _promoteParameterAssert:Union([exact=JSString], [exact=JSUInt31])*/
_promoteParameterAssert(/*Union([exact=JSString], [exact=JSUInt31])*/ o) {
  assert(o is int);
  return o;
}

/*member: promoteParameterAssert:[null]*/
promoteParameterAssert() {
  _promoteParameterAssert(0);
  _promoteParameterAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement with an unreachable throw.
////////////////////////////////////////////////////////////////////////////////

/*member: unreachableThrow:[exact=JSUInt31]*/
unreachableThrow() {
  assert(true, throw "unreachable");
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithSideEffect:[null]*/
_messageWithSideEffect(/*[exact=JSBool]*/ b) {
  var a;
  assert(b, a = 42);
  return a;
}

/*member: messageWithSideEffect:[null]*/
messageWithSideEffect() {
  _messageWithSideEffect(true);
  _messageWithSideEffect(false);
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a caught side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*member: _messageWithCaughtSideEffect:[null]*/
_messageWithCaughtSideEffect(/*[exact=JSBool]*/ b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

/*member: messageWithCaughtSideEffect:[null]*/
messageWithCaughtSideEffect() {
  _messageWithCaughtSideEffect(true);
  _messageWithCaughtSideEffect(false);
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests of assertions when assertions are _enabled_. The
/// file 'assert.dart' contains similar tests for when assertions are
/// _disabled_.

/*element: main:[null]*/
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

/*element: simpleAssert:[null]*/
simpleAssert() {
  assert(true);
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement known to be invalid.
////////////////////////////////////////////////////////////////////////////////

/*element: failingAssert:[exact=JSUInt31]*/
failingAssert() {
  assert(false);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Simple assert statement with message known to be valid.
////////////////////////////////////////////////////////////////////////////////

/*element: simpleAssertWithMessage:[null]*/
simpleAssertWithMessage() {
  assert(true, 'foo');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a local.
////////////////////////////////////////////////////////////////////////////////

/*element: _promoteLocalAssert:[exact=JSUInt31]*/
_promoteLocalAssert(/*Union of [[exact=JSString], [exact=JSUInt31]]*/ o) {
  var local = o;
  assert(local is int);
  return local;
}

/*element: promoteLocalAssert:[null]*/
promoteLocalAssert() {
  _promoteLocalAssert(0);
  _promoteLocalAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement that promotes a parameter.
////////////////////////////////////////////////////////////////////////////////

/*element: _promoteParameterAssert:[exact=JSUInt31]*/
_promoteParameterAssert(/*Union of [[exact=JSString], [exact=JSUInt31]]*/ o) {
  assert(o is int);
  return o;
}

/*element: promoteParameterAssert:[null]*/
promoteParameterAssert() {
  _promoteParameterAssert(0);
  _promoteParameterAssert('');
}

////////////////////////////////////////////////////////////////////////////////
// Assert statement with an unreachable throw.
////////////////////////////////////////////////////////////////////////////////

/*element: unreachableThrow:[exact=JSUInt31]*/
unreachableThrow() {
  assert(true, throw "unreachable");
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*element: _messageWithSideEffect:[null]*/
_messageWithSideEffect(/*[exact=JSBool]*/ b) {
  var a;
  assert(b, a = 42);
  return a;
}

/*element: messageWithSideEffect:[null]*/
messageWithSideEffect() {
  _messageWithSideEffect(true);
  _messageWithSideEffect(false);
}

////////////////////////////////////////////////////////////////////////////////
// Assert with a caught side effect in the message.
////////////////////////////////////////////////////////////////////////////////

/*element: _messageWithCaughtSideEffect:[null|exact=JSUInt31]*/
_messageWithCaughtSideEffect(/*[exact=JSBool]*/ b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

/*element: messageWithCaughtSideEffect:[null]*/
messageWithCaughtSideEffect() {
  _messageWithCaughtSideEffect(true);
  _messageWithCaughtSideEffect(false);
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  emptyTryCatch();
  emptyTryFinally();
  emptyTryCatchFinally();

  tryCatchAssignmentInTry();
  tryCatchAssignmentInCatch();
  tryFinallyAssignmentInFinally();
  tryCatchAssignmentInTryCatch();
  tryCatchAssignmentInTryFinally();

  tryCatchParameterAssignmentInTry();
  tryCatchParameterAssignmentInCatch();
  tryFinallyParameterAssignmentInFinally();
  tryCatchParameterAssignmentInTryCatch();
  tryFinallyParameterAssignmentInTryFinally();
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through an empty try-catch statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _emptyTryCatch:[exact=JSUInt31]*/
_emptyTryCatch(/*[exact=JSUInt31]*/ o) {
  try {} catch (e) {}
  return o;
}

/*member: emptyTryCatch:[null]*/
emptyTryCatch() {
  _emptyTryCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through an empty try-finally statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _emptyTryFinally:[exact=JSUInt31]*/
_emptyTryFinally(/*[exact=JSUInt31]*/ o) {
  try {} finally {}
  return o;
}

/*member: emptyTryFinally:[null]*/
emptyTryFinally() {
  _emptyTryFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through an empty try-catch-finally statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _emptyTryCatchFinally:[exact=JSUInt31]*/
_emptyTryCatchFinally(/*[exact=JSUInt31]*/ o) {
  try {} catch (e) {} finally {}
  return o;
}

/*member: emptyTryCatchFinally:[null]*/
emptyTryCatchFinally() {
  _emptyTryCatchFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in the try block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInTry:[null|exact=JSUInt31]*/
tryCatchAssignmentInTry() {
  var o = 0;
  try {
    o = null;
  } catch (e) {}
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in the catch block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInCatch:[null|exact=JSUInt31]*/
tryCatchAssignmentInCatch() {
  var o = 0;
  try {} catch (e) {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-finally statement with an assignment in the finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: tryFinallyAssignmentInFinally:[null]*/
tryFinallyAssignmentInFinally() {
  var o = 0;
  try {} finally {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in both the try block and the catch
/// block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInTryCatch:Union(null, [exact=JSString], [exact=JSUInt31])*/
tryCatchAssignmentInTryCatch() {
  dynamic o = 0;
  try {
    o = '';
  } catch (e) {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in both the try block and the
/// finally block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInTryFinally:[null]*/
tryCatchAssignmentInTryFinally() {
  dynamic o = 0;
  try {
    o = '';
  } finally {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-catch statement with an assignment in the
/// catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryCatchParameterAssignmentInTry:[null|exact=JSUInt31]*/
_tryCatchParameterAssignmentInTry(/*[exact=JSUInt31]*/ o) {
  try {
    o = null;
  } catch (e) {}
  return o;
}

/*member: tryCatchParameterAssignmentInTry:[null]*/
tryCatchParameterAssignmentInTry() {
  _tryCatchParameterAssignmentInTry(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-catch statement with an assignment in the
/// catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryCatchParameterAssignmentInCatch:[null|exact=JSUInt31]*/
_tryCatchParameterAssignmentInCatch(/*[exact=JSUInt31]*/ o) {
  try {} catch (e) {
    o = null;
  }
  return o;
}

/*member: tryCatchParameterAssignmentInCatch:[null]*/
tryCatchParameterAssignmentInCatch() {
  _tryCatchParameterAssignmentInCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-finally statement with an assignment in the
/// finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryFinallyParameterAssignmentInFinally:[null]*/
_tryFinallyParameterAssignmentInFinally(/*[exact=JSUInt31]*/ o) {
  try {} finally {
    o = null;
  }
  return o;
}

/*member: tryFinallyParameterAssignmentInFinally:[null]*/
tryFinallyParameterAssignmentInFinally() {
  _tryFinallyParameterAssignmentInFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-catch statement with an assignment in the
/// catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryCatchParameterAssignmentInTryCatch:Union(null, [exact=JSString], [exact=JSUInt31])*/
_tryCatchParameterAssignmentInTryCatch(/*[exact=JSUInt31]*/ o) {
  try {
    o = '';
  } catch (e) {
    o = null;
  }
  return o;
}

/*member: tryCatchParameterAssignmentInTryCatch:[null]*/
tryCatchParameterAssignmentInTryCatch() {
  _tryCatchParameterAssignmentInTryCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-finally statement with an assignment in the
/// finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryFinallyParameterAssignmentInTryFinally:[null]*/
_tryFinallyParameterAssignmentInTryFinally(/*[exact=JSUInt31]*/ o) {
  try {
    o = '';
  } finally {
    o = null;
  }
  return o;
}

/*member: tryFinallyParameterAssignmentInTryFinally:[null]*/
tryFinallyParameterAssignmentInTryFinally() {
  _tryFinallyParameterAssignmentInTryFinally(0);
}

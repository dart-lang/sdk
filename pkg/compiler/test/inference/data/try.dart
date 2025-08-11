// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: _emptyTryCatch:[exact=JSUInt31|powerset={I}{O}{N}]*/
_emptyTryCatch(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  try {} catch (e) {}
  return o;
}

/*member: emptyTryCatch:[null|powerset={null}]*/
emptyTryCatch() {
  _emptyTryCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through an empty try-finally statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _emptyTryFinally:[exact=JSUInt31|powerset={I}{O}{N}]*/
_emptyTryFinally(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  try {} finally {}
  return o;
}

/*member: emptyTryFinally:[null|powerset={null}]*/
emptyTryFinally() {
  _emptyTryFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through an empty try-catch-finally statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _emptyTryCatchFinally:[exact=JSUInt31|powerset={I}{O}{N}]*/
_emptyTryCatchFinally(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  try {} catch (e) {
  } finally {}
  return o;
}

/*member: emptyTryCatchFinally:[null|powerset={null}]*/
emptyTryCatchFinally() {
  _emptyTryCatchFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in the try block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInTry:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
tryCatchAssignmentInTry() {
  int? o = 0;
  try {
    o = null;
  } catch (e) {}
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in the catch block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInCatch:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
tryCatchAssignmentInCatch() {
  int? o = 0;
  try {} catch (e) {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-finally statement with an assignment in the finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: tryFinallyAssignmentInFinally:[null|powerset={null}]*/
tryFinallyAssignmentInFinally() {
  int? o = 0;
  try {} finally {
    o = null;
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// A try-catch statement with an assignment in both the try block and the catch
/// block.
////////////////////////////////////////////////////////////////////////////////

/*member: tryCatchAssignmentInTryCatch:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
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

/*member: tryCatchAssignmentInTryFinally:[null|powerset={null}]*/
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

/*member: _tryCatchParameterAssignmentInTry:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
_tryCatchParameterAssignmentInTry(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  try {
    o = null;
  } catch (e) {}
  return o;
}

/*member: tryCatchParameterAssignmentInTry:[null|powerset={null}]*/
tryCatchParameterAssignmentInTry() {
  _tryCatchParameterAssignmentInTry(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-catch statement with an assignment in the
/// catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryCatchParameterAssignmentInCatch:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
_tryCatchParameterAssignmentInCatch(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  try {} catch (e) {
    o = null;
  }
  return o;
}

/*member: tryCatchParameterAssignmentInCatch:[null|powerset={null}]*/
tryCatchParameterAssignmentInCatch() {
  _tryCatchParameterAssignmentInCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-finally statement with an assignment in the
/// finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryFinallyParameterAssignmentInFinally:[null|powerset={null}]*/
_tryFinallyParameterAssignmentInFinally(
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/ o,
) {
  try {} finally {
    o = null;
  }
  return o;
}

/*member: tryFinallyParameterAssignmentInFinally:[null|powerset={null}]*/
tryFinallyParameterAssignmentInFinally() {
  _tryFinallyParameterAssignmentInFinally(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-catch statement with an assignment in the
/// catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryCatchParameterAssignmentInTryCatch:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
_tryCatchParameterAssignmentInTryCatch(
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/ o,
) {
  try {
    o = '';
  } catch (e) {
    o = null;
  }
  return o;
}

/*member: tryCatchParameterAssignmentInTryCatch:[null|powerset={null}]*/
tryCatchParameterAssignmentInTryCatch() {
  _tryCatchParameterAssignmentInTryCatch(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Parameter passed through a try-finally statement with an assignment in the
/// finally clause.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryFinallyParameterAssignmentInTryFinally:[null|powerset={null}]*/
_tryFinallyParameterAssignmentInTryFinally(
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/ o,
) {
  try {
    o = '';
  } finally {
    o = null;
  }
  return o;
}

/*member: tryFinallyParameterAssignmentInTryFinally:[null|powerset={null}]*/
tryFinallyParameterAssignmentInTryFinally() {
  _tryFinallyParameterAssignmentInTryFinally(0);
}

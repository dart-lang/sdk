// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  catchUntyped();
  catchTyped();
  catchStackTrace();
}

////////////////////////////////////////////////////////////////////////////////
/// Untyped catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: catchUntyped:[subclass=Object|powerset={IN}{GFUO}{IMN}]*/
catchUntyped() {
  dynamic local = 0;
  try {} catch (e) {
    local = e;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Typed catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: catchTyped:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
catchTyped() {
  dynamic local = 0;
  try {} on String catch (e) {
    local = e;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Catch clause with stack trace.
////////////////////////////////////////////////////////////////////////////////

/*member: catchStackTrace:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
catchStackTrace() {
  dynamic local = 0;
  try {} catch (_, s) {
    local = s;
  }
  return local;
}

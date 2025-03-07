// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  catchUntyped();
  catchTyped();
  catchStackTrace();
}

////////////////////////////////////////////////////////////////////////////////
/// Untyped catch clause.
////////////////////////////////////////////////////////////////////////////////

/*member: catchUntyped:[subclass=Object|powerset=0]*/
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

/*member: catchTyped:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
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

/*member: catchStackTrace:[null|subclass=Object|powerset=1]*/
catchStackTrace() {
  dynamic local = 0;
  try {} catch (_, s) {
    local = s;
  }
  return local;
}

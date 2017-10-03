// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  catchUntyped();
  catchTyped();
  catchStackTrace();
}

////////////////////////////////////////////////////////////////////////////////
/// Untyped catch clause.
////////////////////////////////////////////////////////////////////////////////

/*element: catchUntyped:[null|subclass=Object]*/
catchUntyped() {
  var local;
  try {} catch (e) {
    local = e;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Typed catch clause.
////////////////////////////////////////////////////////////////////////////////

/*element: catchTyped:Union of [[exact=JSString], [exact=JSUInt31]]*/
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

/*element: catchStackTrace:[null|subclass=Object]*/
catchStackTrace() {
  dynamic local = 0;
  try {} catch (_, s) {
    local = s;
  }
  return local;
}

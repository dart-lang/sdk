// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  switchThrowing();
}

/*member: switchThrowing:has label*/
@pragma('dart2js:noInline')
switchThrowing() {
  switch (0) {
    case 0:
      _switchThrowing();
      break;
    default:
      return;
  }
}

/*member: _switchThrowing:[]*/
_switchThrowing() {
  throw '';
}

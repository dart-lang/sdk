// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  switchThrowing();
}

/*element: switchThrowing:[]*/
@NoInline()
switchThrowing() {
  switch (0) {
    case 0:
      _switchThrowing();
      break;
    default:
      return;
  }
}

/*element: _switchThrowing:[]*/
_switchThrowing() {
  throw '';
}

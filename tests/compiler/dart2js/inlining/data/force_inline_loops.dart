// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  forceInlineLoops();
}
////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method with loops.
////////////////////////////////////////////////////////////////////////////////

/*element: _forLoop:loop,[forceInlineLoops]*/
@ForceInline()
_forLoop() {
  for (int i = 0; i < 10; i++) {
    print(i);
  }
}

/*element: _forInLoop:loop,[forceInlineLoops]*/
@ForceInline()
_forInLoop() {
  for (var e in [0, 1, 2]) {
    print(e);
  }
}

/*element: _whileLoop:loop,[forceInlineLoops]*/
@ForceInline()
_whileLoop() {
  int i = 0;
  while (i < 10) {
    print(i);
    i++;
  }
}

/*element: _doLoop:loop,[forceInlineLoops]*/
@ForceInline()
_doLoop() {
  int i = 0;
  do {
    print(i);
    i++;
  } while (i < 10);
}

/*element: forceInlineLoops:[]*/
@NoInline()
forceInlineLoops() {
  _forLoop();
  _forInLoop();
  _whileLoop();
  _doLoop();
}

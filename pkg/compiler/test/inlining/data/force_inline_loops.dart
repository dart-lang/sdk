// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  forceInlineLoops();
}
////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method with loops.
////////////////////////////////////////////////////////////////////////////////

/*member: _forLoop:loop,[forceInlineLoops]*/
@pragma('dart2js:tryInline')
_forLoop() {
  for (int i = 0; i < 10; i++) {
    print(i);
  }
}

/*member: _forInLoop:loop,[forceInlineLoops]*/
@pragma('dart2js:tryInline')
_forInLoop() {
  for (var e in [0, 1, 2]) {
    print(e);
  }
}

/*member: _whileLoop:loop,[forceInlineLoops]*/
@pragma('dart2js:tryInline')
_whileLoop() {
  int i = 0;
  while (i < 10) {
    print(i);
    i++;
  }
}

/*member: _doLoop:loop,[forceInlineLoops]*/
@pragma('dart2js:tryInline')
_doLoop() {
  int i = 0;
  do {
    print(i);
    i++;
  } while (i < 10);
}

/*member: _hardLoop:loop,(allowLoops)code after return*/
@pragma('dart2js:tryInline')
_hardLoop() {
  for (int i = 0; i < 10; i++) {
    if (i % 2 == 0) return 2;
    if (i % 3 == 0) return 3;
  }
  return 1;
}

/*member: forceInlineLoops:[]*/
@pragma('dart2js:noInline')
forceInlineLoops() {
  _forLoop();
  _forInLoop();
  _whileLoop();
  _doLoop();
  _hardLoop();
}

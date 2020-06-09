// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  tryInlineOnce();
  tryInlineTwice1();
  tryInlineTwice2();
}

////////////////////////////////////////////////////////////////////////////////
// Use `tryInline` to inline a top level method once.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryInlineOnce:[tryInlineOnce]*/
@pragma('dart2js:tryInline')
_tryInlineOnce() {}

/*member: tryInlineOnce:[]*/
@pragma('dart2js:noInline')
tryInlineOnce() {
  _tryInlineOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Use `tryInline`to inline a top level method twice.
////////////////////////////////////////////////////////////////////////////////

/*member: _tryInlineTwice:[tryInlineTwice1,tryInlineTwice2]*/
@pragma('dart2js:tryInline')
_tryInlineTwice() {}

/*member: tryInlineTwice1:[]*/
@pragma('dart2js:noInline')
tryInlineTwice1() {
  _tryInlineTwice();
}

/*member: tryInlineTwice2:[]*/
@pragma('dart2js:noInline')
tryInlineTwice2() {
  _tryInlineTwice();
}

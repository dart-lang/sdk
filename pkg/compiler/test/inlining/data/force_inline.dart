// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  forceInlineOnce();
  forceInlineTwice1();
  forceInlineTwice2();
  forceInlineNested();
  forceInlineOptional();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method once.
////////////////////////////////////////////////////////////////////////////////

/*member: _forceInlineOnce:[forceInlineOnce]*/
@pragma('dart2js:tryInline')
_forceInlineOnce() {}

/*member: forceInlineOnce:[]*/
@pragma('dart2js:noInline')
forceInlineOnce() {
  _forceInlineOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method twice.
////////////////////////////////////////////////////////////////////////////////

/*member: _forceInlineTwice:[forceInlineTwice1,forceInlineTwice2]*/
@pragma('dart2js:tryInline')
_forceInlineTwice() {}

/*member: forceInlineTwice1:[]*/
@pragma('dart2js:noInline')
forceInlineTwice1() {
  _forceInlineTwice();
}

/*member: forceInlineTwice2:[]*/
@pragma('dart2js:noInline')
forceInlineTwice2() {
  _forceInlineTwice();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline nested top level methods.
////////////////////////////////////////////////////////////////////////////////

/*member: _forceInlineNested1:[forceInlineNested]*/
@pragma('dart2js:tryInline')
_forceInlineNested1() {}

/*member: _forceInlineNested2:[forceInlineNested]*/
@pragma('dart2js:tryInline')
_forceInlineNested2() {
  _forceInlineNested1();
}

/*member: forceInlineNested:[]*/
@pragma('dart2js:noInline')
forceInlineNested() {
  _forceInlineNested2();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method with optional argument.
////////////////////////////////////////////////////////////////////////////////

/*member: _forceInlineOptional:[forceInlineOptional]*/
@pragma('dart2js:tryInline')
_forceInlineOptional([x]) {}

/*member: forceInlineOptional:[]*/
@pragma('dart2js:noInline')
forceInlineOptional() {
  _forceInlineOptional();
}

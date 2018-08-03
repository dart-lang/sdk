// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
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

/*element: _forceInlineOnce:[forceInlineOnce]*/
@ForceInline()
_forceInlineOnce() {}

/*element: forceInlineOnce:[]*/
@NoInline()
forceInlineOnce() {
  _forceInlineOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method twice.
////////////////////////////////////////////////////////////////////////////////

/*element: _forceInlineTwice:[forceInlineTwice1,forceInlineTwice2]*/
@ForceInline()
_forceInlineTwice() {}

/*element: forceInlineTwice1:[]*/
@NoInline()
forceInlineTwice1() {
  _forceInlineTwice();
}

/*element: forceInlineTwice2:[]*/
@NoInline()
forceInlineTwice2() {
  _forceInlineTwice();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline nested top level methods.
////////////////////////////////////////////////////////////////////////////////

/*element: _forceInlineNested1:[forceInlineNested]*/
@ForceInline()
_forceInlineNested1() {}

/*element: _forceInlineNested2:[forceInlineNested]*/
@ForceInline()
_forceInlineNested2() {
  _forceInlineNested1();
}

/*element: forceInlineNested:[]*/
@NoInline()
forceInlineNested() {
  _forceInlineNested2();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a top level method with optional argument.
////////////////////////////////////////////////////////////////////////////////

/*element: _forceInlineOptional:[forceInlineOptional]*/
@ForceInline()
_forceInlineOptional([x]) {}

/*element: forceInlineOptional:[]*/
@NoInline()
forceInlineOptional() {
  _forceInlineOptional();
}

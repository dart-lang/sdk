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

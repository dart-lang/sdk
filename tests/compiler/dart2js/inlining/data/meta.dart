// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*element: main:[]*/
main() {
  tryInlineOnce();
  tryInlineTwice1();
  tryInlineTwice2();
}

////////////////////////////////////////////////////////////////////////////////
// Use `tryInline` to inline a top level method once.
////////////////////////////////////////////////////////////////////////////////

/*element: _tryInlineOnce:[tryInlineOnce]*/
@tryInline
_tryInlineOnce() {}

/*element: tryInlineOnce:[]*/
@noInline
tryInlineOnce() {
  _tryInlineOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Use `tryInline`to inline a top level method twice.
////////////////////////////////////////////////////////////////////////////////

/*element: _tryInlineTwice:[tryInlineTwice1,tryInlineTwice2]*/
@tryInline
_tryInlineTwice() {}

/*element: tryInlineTwice1:[]*/
@noInline
tryInlineTwice1() {
  _tryInlineTwice();
}

/*element: tryInlineTwice2:[]*/
@noInline
tryInlineTwice2() {
  _tryInlineTwice();
}

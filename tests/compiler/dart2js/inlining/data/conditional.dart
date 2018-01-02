// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for the heuristics on conditional expression whose condition is a
// parameter for which the max, instead of the sum, of the branch sizes is used.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  conditionalField();
  conditionalParameter();
}

////////////////////////////////////////////////////////////////////////////////
// Conditional expression on a non-parameter (here a top-level field). The
// size of the condition is the sum of the nodes in the conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[_conditionalField]*/
_method1() => 42;

var _field1;

/*element: _conditionalField:[]*/
_conditionalField() {
  return _field1
      ? _method1() + _method1() + _method1()
      : _method1() + _method1() + _method1();
}

/*element: conditionalField:[]*/
@NoInline()
conditionalField() {
  _field1 = false;
  _conditionalField();
  _field1 = true;
  _conditionalField();
}

////////////////////////////////////////////////////////////////////////////////
// Conditional expression on a parameter. The size of the condition is the
// max of the branches + the condition itself.
////////////////////////////////////////////////////////////////////////////////

/*element: _method2:[conditionalParameter]*/
_method2() => 42;

/*element: _conditionalParameter:[conditionalParameter]*/
_conditionalParameter(o) {
  return o
      ? _method2() + _method2() + _method2()
      : _method2() + _method2() + _method2();
}

/*element: conditionalParameter:[]*/
@NoInline()
conditionalParameter() {
  _conditionalParameter(true);
  _conditionalParameter(false);
}

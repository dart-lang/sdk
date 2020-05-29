// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Tests for the heuristics on conditional expression whose condition is a
// parameter for which the max, instead of the sum, of the branch sizes is used.

/*member: main:[]*/
main() {
  conditionalField();
  conditionalParameter();
}

////////////////////////////////////////////////////////////////////////////////
// Conditional expression on a non-parameter (here a top-level field). The
// size of the condition is the sum of the nodes in the conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[_conditionalField]*/
_method1() => 42;

bool _field1;

/*member: _conditionalField:[]*/
_conditionalField() {
  return _field1
      ? _method1() + _method1() + _method1()
      : _method1() + _method1() + _method1();
}

/*member: conditionalField:[]*/
@pragma('dart2js:noInline')
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

/*member: _method2:[conditionalParameter]*/
_method2() => 42;

/*member: _conditionalParameter:[conditionalParameter]*/
_conditionalParameter(bool o) {
  return o
      ? _method2() + _method2() + _method2()
      : _method2() + _method2() + _method2();
}

/*member: conditionalParameter:[]*/
@pragma('dart2js:noInline')
conditionalParameter() {
  _conditionalParameter(true);
  _conditionalParameter(false);
}

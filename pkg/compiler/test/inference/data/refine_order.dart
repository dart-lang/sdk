// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: Class.:[exact=Class]*/
class Class {
  /*member: Class.field:[exact=JSUInt31]*/
  var field = 42;

  /*member: Class.method:[null]*/
  method([/*[null|exact=JSUInt31]*/ a, /*[null|exact=JSUInt31]*/ b]) {}
}

/*member: main:[null]*/
main() {
  new Class();
  statementOrderFieldAccess(null);
  statementOrderFieldUpdate(null);
  statementOrderInvocation(null);
  receiverVsArgument(null);
  argumentsOrder(null);
  operatorOrder(null);
  updateVsRhs(null);
  logicalOr(null);
  conditionalCondition(null);
  conditionalBothBranches(null);
  conditionalOneBranchOnly(null);
}

////////////////////////////////////////////////////////////////////////////////
// Accesses in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderFieldAccess:[null]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldAccess(/*[null|subclass=Object]*/ o) {
  o.field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Updates in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderFieldUpdate:[null]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldUpdate(/*[null|subclass=Object]*/ o) {
  o.field = 42;
  o. /*update: [subclass=Object]*/ field = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Invocations in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderInvocation:[null]*/
@pragma('dart2js:assumeDynamic')
statementOrderInvocation(/*[null|subclass=Object]*/ o) {
  o.method(null);
  o. /*invoke: [subclass=Object]*/ method(null);
}

////////////////////////////////////////////////////////////////////////////////
// Access in argument before method call.
////////////////////////////////////////////////////////////////////////////////

/*member: receiverVsArgument:[null]*/
@pragma('dart2js:assumeDynamic')
receiverVsArgument(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field);
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in multiple arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: argumentsOrder:[null]*/
@pragma('dart2js:assumeDynamic')
argumentsOrder(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field, o. /*[subclass=Object]*/ field);
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of an operator call.
////////////////////////////////////////////////////////////////////////////////

/*member: operatorOrder:[null]*/
@pragma('dart2js:assumeDynamic')
operatorOrder(/*[null|subclass=Object]*/ o) {
  o.field /*invoke: [exact=JSUInt31]*/ < o. /*[subclass=Object]*/ field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Assign after access in right-hand side.
////////////////////////////////////////////////////////////////////////////////

/*member: updateVsRhs:[null]*/
@pragma('dart2js:assumeDynamic')
updateVsRhs(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The right-hand side should refine the left-hand side
  // receiver.
  o.field = o.field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of a logical or.
////////////////////////////////////////////////////////////////////////////////

/*member: logicalOr:[null]*/
@pragma('dart2js:assumeDynamic')
logicalOr(/*[null|subclass=Object]*/ o) {
  o.field || o. /*[subclass=Object]*/ field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in condition of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalCondition:[null]*/
@pragma('dart2js:assumeDynamic')
conditionalCondition(/*[null|subclass=Object]*/ o) {
  o.field ? o. /*[subclass=Object]*/ field : o. /*[subclass=Object]*/ field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access both branches of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalBothBranches:[null]*/
@pragma('dart2js:assumeDynamic')
conditionalBothBranches(/*[null|subclass=Object]*/ o) {
  // ignore: DEAD_CODE
  true ? o.field : o.field;
  o. /*[subclass=Object]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in only one branch of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalOneBranchOnly:[null]*/
@pragma('dart2js:assumeDynamic')
conditionalOneBranchOnly(/*[null|subclass=Object]*/ o) {
  // ignore: DEAD_CODE
  true ? o.field : null;
  o.field;
  o. /*[subclass=Object]*/ field;
}

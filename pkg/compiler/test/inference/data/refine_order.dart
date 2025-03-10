// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: Class.:[exact=Class|powerset=0]*/
class Class {
  /*member: Class.field:[exact=JSUInt31|powerset=0]*/
  var field = 42;

  /*member: Class.method:[null|powerset=1]*/
  method([
    /*[null|exact=JSUInt31|powerset=1]*/ a,
    /*[null|exact=JSUInt31|powerset=1]*/ b,
  ]) {}
}

/*member: main:[null|powerset=1]*/
main() {
  Class();
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

/*member: statementOrderFieldAccess:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldAccess(/*[null|subclass=Object|powerset=1]*/ o) {
  o.field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Updates in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderFieldUpdate:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldUpdate(/*[null|subclass=Object|powerset=1]*/ o) {
  o.field = 42;
  o. /*update: [subclass=Object|powerset=0]*/ field = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Invocations in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderInvocation:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
statementOrderInvocation(/*[null|subclass=Object|powerset=1]*/ o) {
  o.method(null);
  o. /*invoke: [subclass=Object|powerset=0]*/ method(null);
}

////////////////////////////////////////////////////////////////////////////////
// Access in argument before method call.
////////////////////////////////////////////////////////////////////////////////

/*member: receiverVsArgument:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
receiverVsArgument(/*[null|subclass=Object|powerset=1]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field);
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in multiple arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: argumentsOrder:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
argumentsOrder(/*[null|subclass=Object|powerset=1]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field, o. /*[subclass=Object|powerset=0]*/ field);
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of an operator call.
////////////////////////////////////////////////////////////////////////////////

/*member: operatorOrder:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
operatorOrder(/*[null|subclass=Object|powerset=1]*/ o) {
  o.field /*invoke: [exact=JSUInt31|powerset=0]*/ <
      o. /*[subclass=Object|powerset=0]*/ field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Assign after access in right-hand side.
////////////////////////////////////////////////////////////////////////////////

/*member: updateVsRhs:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
updateVsRhs(/*[null|subclass=Object|powerset=1]*/ o) {
  // TODO(johnniwinther): The right-hand side should refine the left-hand side
  // receiver.
  o.field = o.field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of a logical or.
////////////////////////////////////////////////////////////////////////////////

/*member: logicalOr:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
logicalOr(/*[null|subclass=Object|powerset=1]*/ o) {
  o.field || o. /*[subclass=Object|powerset=0]*/ field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in condition of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalCondition:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
conditionalCondition(/*[null|subclass=Object|powerset=1]*/ o) {
  o.field
      ? o. /*[subclass=Object|powerset=0]*/ field
      : o. /*[subclass=Object|powerset=0]*/ field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access both branches of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: _#flag:[exact=_Cell|powerset=0]*/
late bool /*Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/ /*update: [exact=_Cell|powerset=0]*/
flag;

/*member: conditionalBothBranches:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
conditionalBothBranches(/*[null|subclass=Object|powerset=1]*/ o) {
  // ignore: DEAD_CODE
  (flag = true) ? o.field : o.field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in only one branch of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalOneBranchOnly:[null|powerset=1]*/
@pragma('dart2js:assumeDynamic')
conditionalOneBranchOnly(/*[null|subclass=Object|powerset=1]*/ o) {
  // ignore: DEAD_CODE
  (flag = true) ? o.field : null;
  o.field;
  o. /*[subclass=Object|powerset=0]*/ field;
}

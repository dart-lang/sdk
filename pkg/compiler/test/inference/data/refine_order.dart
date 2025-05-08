// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: Class.:[exact=Class|powerset={N}{O}{N}]*/
class Class {
  /*member: Class.field:[exact=JSUInt31|powerset={I}{O}{N}]*/
  var field = 42;

  /*member: Class.method:[null|powerset={null}]*/
  method([
    /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ a,
    /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ b,
  ]) {}
}

/*member: main:[null|powerset={null}]*/
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

/*member: statementOrderFieldAccess:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldAccess(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  o.field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Updates in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderFieldUpdate:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
statementOrderFieldUpdate(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  o.field = 42;
  o. /*update: [subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Invocations in statements.
////////////////////////////////////////////////////////////////////////////////

/*member: statementOrderInvocation:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
statementOrderInvocation(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  o.method(null);
  o. /*invoke: [subclass=Object|powerset={IN}{GFUO}{IMN}]*/ method(null);
}

////////////////////////////////////////////////////////////////////////////////
// Access in argument before method call.
////////////////////////////////////////////////////////////////////////////////

/*member: receiverVsArgument:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
receiverVsArgument(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field);
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in multiple arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: argumentsOrder:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
argumentsOrder(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field, o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field);
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of an operator call.
////////////////////////////////////////////////////////////////////////////////

/*member: operatorOrder:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
operatorOrder(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o) {
  o.field /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ <
      o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Assign after access in right-hand side.
////////////////////////////////////////////////////////////////////////////////

/*member: updateVsRhs:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
updateVsRhs(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o) {
  // TODO(johnniwinther): The right-hand side should refine the left-hand side
  // receiver.
  o.field = o.field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of a logical or.
////////////////////////////////////////////////////////////////////////////////

/*member: logicalOr:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
logicalOr(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o) {
  o.field || o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in condition of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalCondition:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
conditionalCondition(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  o.field
      ? o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field
      : o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access both branches of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: _#flag:[exact=_Cell|powerset={N}{O}{N}]*/
late bool /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ /*update: [exact=_Cell|powerset={N}{O}{N}]*/
flag;

/*member: conditionalBothBranches:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
conditionalBothBranches(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  // ignore: DEAD_CODE
  (flag = true) ? o.field : o.field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in only one branch of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*member: conditionalOneBranchOnly:[null|powerset={null}]*/
@pragma('dart2js:assumeDynamic')
conditionalOneBranchOnly(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ o,
) {
  // ignore: DEAD_CODE
  (flag = true) ? o.field : null;
  o.field;
  o. /*[subclass=Object|powerset={IN}{GFUO}{IMN}]*/ field;
}

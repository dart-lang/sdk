// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: Class.:[exact=Class]*/
class Class {
  /*element: Class.field:[exact=JSUInt31]*/
  var field = 42;

  /*element: Class.method:[null]*/
  method([/*[null|exact=JSUInt31]*/ a, /*[null|exact=JSUInt31]*/ b]) {}
}

/*element: main:[null]*/
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

/*element: statementOrderFieldAccess:[null]*/
@AssumeDynamic()
statementOrderFieldAccess(/*[null|subclass=Object]*/ o) {
  o.field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Updates in statements.
////////////////////////////////////////////////////////////////////////////////

/*element: statementOrderFieldUpdate:[null]*/
@AssumeDynamic()
statementOrderFieldUpdate(/*[null|subclass=Object]*/ o) {
  o.field = 42;
  o. /*update: [exact=Class]*/ field = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Invocations in statements.
////////////////////////////////////////////////////////////////////////////////

/*element: statementOrderInvocation:[null]*/
@AssumeDynamic()
statementOrderInvocation(/*[null|subclass=Object]*/ o) {
  o.method(null);
  o. /*invoke: [exact=Class]*/ method(null);
}

////////////////////////////////////////////////////////////////////////////////
// Access in argument before method call.
////////////////////////////////////////////////////////////////////////////////

/*element: receiverVsArgument:[null]*/
@AssumeDynamic()
receiverVsArgument(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field);
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in multiple arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: argumentsOrder:[null]*/
@AssumeDynamic()
argumentsOrder(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The arguments should refine the receiver.
  o.method(o.field, o. /*[exact=Class]*/ field);
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of an operator call.
////////////////////////////////////////////////////////////////////////////////

/*element: operatorOrder:[null]*/
@AssumeDynamic()
operatorOrder(/*[null|subclass=Object]*/ o) {
  o.field /*invoke: [exact=JSUInt31]*/ < o. /*[exact=Class]*/ field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Assign after access in right-hand side.
////////////////////////////////////////////////////////////////////////////////

/*element: updateVsRhs:[null]*/
@AssumeDynamic()
updateVsRhs(/*[null|subclass=Object]*/ o) {
  // TODO(johnniwinther): The right-hand side should refine the left-hand side
  // receiver.
  o.field = o.field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in both sides of a logical or.
////////////////////////////////////////////////////////////////////////////////

/*element: logicalOr:[null]*/
@AssumeDynamic()
logicalOr(/*[null|subclass=Object]*/ o) {
  o.field || o. /*[exact=Class]*/ field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in condition of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*element: conditionalCondition:[null]*/
@AssumeDynamic()
conditionalCondition(/*[null|subclass=Object]*/ o) {
  o.field ? o. /*[exact=Class]*/ field : o. /*[exact=Class]*/ field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access both branches of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*element: conditionalBothBranches:[null]*/
@AssumeDynamic()
conditionalBothBranches(/*[null|subclass=Object]*/ o) {
  // ignore: DEAD_CODE
  true ? o.field : o.field;
  o. /*[exact=Class]*/ field;
}

////////////////////////////////////////////////////////////////////////////////
// Access in only one branch of a conditional expression.
////////////////////////////////////////////////////////////////////////////////

/*element: conditionalOneBranchOnly:[null]*/
@AssumeDynamic()
conditionalOneBranchOnly(/*[null|subclass=Object]*/ o) {
  // ignore: DEAD_CODE
  true ? o.field : null;
  o.field;
  o. /*[exact=Class]*/ field;
}

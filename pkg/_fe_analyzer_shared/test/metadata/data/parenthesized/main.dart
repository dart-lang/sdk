// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

T genericFunction<T>(T t) => t;

@Helper((0))
/*member: parenthesized1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ParenthesizedExpression(IntegerLiteral(0)))))
resolved=ParenthesizedExpression(IntegerLiteral(0))*/
void parenthesized1() {}

@Helper(('').length)
/*member: parenthesized2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (PropertyGet(ParenthesizedExpression(StringLiteral('')).length))))
resolved=PropertyGet(ParenthesizedExpression(StringLiteral('')).length)*/
void parenthesized2() {}

@Helper((genericFunction)<int>)
/*member: parenthesized3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (Instantiation(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(genericFunction)))<{unresolved-type-annotation:UnresolvedIdentifier(int)}>))))
resolved=Instantiation(ParenthesizedExpression(FunctionTearOff(genericFunction))<int>)*/
void parenthesized3() {}

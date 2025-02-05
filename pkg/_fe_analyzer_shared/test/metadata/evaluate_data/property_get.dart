// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper("foo".length)
/*member: propertyGet1:
resolved=PropertyGet(StringLiteral('foo').length)
evaluate=IntegerLiteral(value=3)*/
void propertyGet1() {}

@Helper("foo"?.length)
/*member: propertyGet2:
resolved=NullAwarePropertyGet(StringLiteral('foo')?.length)
evaluate=IntegerLiteral(value=3)*/
void propertyGet2() {}

@Helper((true ? "foo" : null)?.length)
/*member: propertyGet3:
resolved=NullAwarePropertyGet(ParenthesizedExpression(ConditionalExpression(
  BooleanLiteral(true)
    ? StringLiteral('foo')
    : NullLiteral()))?.length)
evaluate=IntegerLiteral(value=3)*/
void propertyGet3() {}

@Helper((false ? "foo" : null)?.length)
/*member: propertyGet4:
resolved=NullAwarePropertyGet(ParenthesizedExpression(ConditionalExpression(
  BooleanLiteral(false)
    ? StringLiteral('foo')
    : NullLiteral()))?.length)
evaluate=NullLiteral()*/
void propertyGet4() {}

// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const a = 0;
const b = [a, 1, 2];
const c = [...b, 3, 4];

class Class {
  const Class(values);
}

@Class([-1, ...c, 5, 6])
/*member: spread1:
resolved=ConstructorInvocation(
  Class.new(ListLiteral([
    ExpressionElement(UnaryExpression(-IntegerLiteral(1))), 
    SpreadElement(...StaticGet(c)), 
    ExpressionElement(IntegerLiteral(5)), 
    ExpressionElement(IntegerLiteral(6))])))
evaluate=ConstructorInvocation(
  Class.new(ListLiteral([
    ExpressionElement(IntegerLiteral(value=-1)), 
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2)), 
    ExpressionElement(IntegerLiteral(3)), 
    ExpressionElement(IntegerLiteral(4)), 
    ExpressionElement(IntegerLiteral(5)), 
    ExpressionElement(IntegerLiteral(6))])))
c=ListLiteral([
  SpreadElement(...StaticGet(b)), 
  ExpressionElement(IntegerLiteral(3)), 
  ExpressionElement(IntegerLiteral(4))])
b=ListLiteral([
  ExpressionElement(StaticGet(a)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))])
a=IntegerLiteral(0)*/
void spread1() {}

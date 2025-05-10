// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

@Helper(constBool ? 0 : 1)
/*member: conditional1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ConditionalExpression(
    UnresolvedExpression(UnresolvedIdentifier(constBool))
      ? IntegerLiteral(0)
      : IntegerLiteral(1)))))
resolved=ConditionalExpression(
  StaticGet(constBool)
    ? IntegerLiteral(0)
    : IntegerLiteral(1))*/
void conditional1() {}

@Helper(
  bool.fromEnvironment('foo', defaultValue: true)
      ? const String.fromEnvironment('bar', defaultValue: 'baz')
      : int.fromEnvironment('boz', defaultValue: 42),
)
/*member: conditional2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ConditionalExpression(
    UnresolvedExpression(UnresolvedInvoke(
      UnresolvedAccess(
        UnresolvedIdentifier(bool).fromEnvironment)
      (
        StringLiteral('foo'), 
        defaultValue: BooleanLiteral(true))))
      ? UnresolvedExpression(UnresolvedInvoke(
          UnresolvedAccess(
            UnresolvedIdentifier(String).fromEnvironment)
          (
            StringLiteral('bar'), 
            defaultValue: StringLiteral('baz'))))
      : UnresolvedExpression(UnresolvedInvoke(
          UnresolvedAccess(
            UnresolvedIdentifier(int).fromEnvironment)
          (
            StringLiteral('boz'), 
            defaultValue: IntegerLiteral(42))))))))
resolved=ConditionalExpression(
  ConstructorInvocation(
    bool.fromEnvironment(
      StringLiteral('foo'), 
      defaultValue: BooleanLiteral(true)))
    ? ConstructorInvocation(
        String.fromEnvironment(
          StringLiteral('bar'), 
          defaultValue: StringLiteral('baz')))
    : ConstructorInvocation(
        int.fromEnvironment(
          StringLiteral('boz'), 
          defaultValue: IntegerLiteral(42))))*/
void conditional2() {}

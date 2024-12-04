// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const int constInt = 42;

@Helper(-constInt)
/*member: unary1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(-UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=UnaryExpression(-StaticGet(constInt))*/
void unary1() {}

@Helper(!constBool)
/*member: unary2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(!UnresolvedExpression(UnresolvedIdentifier(constBool))))))
resolved=UnaryExpression(!StaticGet(constBool))*/
void unary2() {}

@Helper(~constInt)
/*member: unary3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(~UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=UnaryExpression(~StaticGet(constInt))*/
void unary3() {}

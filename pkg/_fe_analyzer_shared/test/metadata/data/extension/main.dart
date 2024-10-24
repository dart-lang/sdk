// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

extension Extension on int {
  static const variable = 0;

  static void method() {}

  static void genericMethod<T>() {}
}

@Extension.variable
/*member: extensionConstant1:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Extension).variable))
resolved=StaticGet(variable)*/
void extensionConstant1() {}

@self.Extension.variable
/*member: extensionConstant2:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Extension).variable))
resolved=StaticGet(variable)*/
void extensionConstant2() {}

@Extension.unresolved
/*member: extensionConstant3:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Extension).unresolved))
resolved=UnresolvedExpression(UnresolvedAccess(
  ExtensionProto(Extension).unresolved))*/
void extensionConstant3() {}

@self.Extension.unresolved
/*member: extensionConstant4:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Extension).unresolved))
resolved=UnresolvedExpression(UnresolvedAccess(
  ExtensionProto(Extension).unresolved))*/
void extensionConstant4() {}

@Helper(Extension.method)
/*member: extensionConstant5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Extension).method)))))
resolved=FunctionTearOff(method)*/
void extensionConstant5() {}

@Helper(self.Extension.method)
/*member: extensionConstant6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Extension).method)))))
resolved=FunctionTearOff(method)*/
void extensionConstant6() {}

@Helper(Extension.genericMethod)
/*member: extensionConstant7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Extension).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void extensionConstant7() {}

@Helper(self.Extension.genericMethod)
/*member: extensionConstant8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Extension).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void extensionConstant8() {}

@Helper(Extension.genericMethod<int>)
/*member: extensionConstant9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Extension).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void extensionConstant9() {}

@Helper(self.Extension.genericMethod<int>)
/*member: extensionConstant10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Extension).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void extensionConstant10() {}

@Helper(Extension.unresolved<int>)
/*member: extensionConstant11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Extension).unresolved)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ExtensionProto(Extension).unresolved)<int>))*/
void extensionConstant11() {}

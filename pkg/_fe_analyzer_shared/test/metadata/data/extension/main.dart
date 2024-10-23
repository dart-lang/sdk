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
StaticGet(variable)*/
void extensionConstant1() {}

@self.Extension.variable
/*member: extensionConstant2:
StaticGet(variable)*/
void extensionConstant2() {}

@Extension.unresolved
/*member: extensionConstant3:
UnresolvedExpression(UnresolvedAccess(
  ExtensionProto(Extension).unresolved))*/
void extensionConstant3() {}

@self.Extension.unresolved
/*member: extensionConstant4:
UnresolvedExpression(UnresolvedAccess(
  ExtensionProto(Extension).unresolved))*/
void extensionConstant4() {}

@Helper(Extension.method)
/*member: extensionConstant5:
FunctionTearOff(method)*/
void extensionConstant5() {}

@Helper(self.Extension.method)
/*member: extensionConstant6:
FunctionTearOff(method)*/
void extensionConstant6() {}

@Helper(Extension.genericMethod)
/*member: extensionConstant7:
FunctionTearOff(genericMethod)*/
void extensionConstant7() {}

@Helper(self.Extension.genericMethod)
/*member: extensionConstant8:
FunctionTearOff(genericMethod)*/
void extensionConstant8() {}

@Helper(Extension.genericMethod<int>)
/*member: extensionConstant9:
Instantiation(FunctionTearOff(genericMethod)<int>)*/
void extensionConstant9() {}

@Helper(self.Extension.genericMethod<int>)
/*member: extensionConstant10:
Instantiation(FunctionTearOff(genericMethod)<int>)*/
void extensionConstant10() {}

@Helper(Extension.unresolved<int>)
/*member: extensionConstant11:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ExtensionProto(Extension).unresolved)<int>))*/
void extensionConstant11() {}

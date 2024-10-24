// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

enum Enum {
  a,
  b;

  static const int variable = 42;
  static void method() {}
  static void genericMethod<T>() {}
}

enum GenericEnum<T> {
  a<int>(),
  b<String>()
}

@Enum.a
/*member: enumConstant1:
StaticGet(a)*/
void enumConstant1() {}

@self.Enum.b
/*member: enumConstant2:
StaticGet(b)*/
void enumConstant2() {}

@Enum.variable
/*member: enumConstant3:
StaticGet(variable)*/
void enumConstant3() {}

@self.Enum.variable
/*member: enumConstant4:
StaticGet(variable)*/
void enumConstant4() {}

@Enum.values
/*member: enumConstant5:
StaticGet(values)*/
void enumConstant5() {}

@self.Enum.values
/*member: enumConstant6:
StaticGet(values)*/
void enumConstant6() {}

@GenericEnum.a
/*member: enumConstant7:
StaticGet(a)*/
void enumConstant7() {}

@self.GenericEnum.b
/*member: enumConstant8:
StaticGet(b)*/
void enumConstant8() {}

@Helper(Enum)
/*member: enumConstant9:
TypeLiteral(Enum)*/
void enumConstant9() {}

@Helper(self.Enum)
/*member: enumConstant10:
TypeLiteral(Enum)*/
void enumConstant10() {}

@Helper(Enum.method)
/*member: enumConstant11:
FunctionTearOff(method)*/
void enumConstant11() {}

@Helper(self.Enum.method)
/*member: enumConstant12:
FunctionTearOff(method)*/
void enumConstant12() {}

@Helper(Enum.genericMethod)
/*member: enumConstant13:
FunctionTearOff(genericMethod)*/
void enumConstant13() {}

@Helper(self.Enum.genericMethod)
/*member: enumConstant14:
FunctionTearOff(genericMethod)*/
void enumConstant14() {}

@Helper(Enum.genericMethod<int>)
/*member: enumConstant15:
Instantiation(FunctionTearOff(genericMethod)<int>)*/
void enumConstant15() {}

@Helper(self.Enum.genericMethod<int>)
/*member: enumConstant16:
Instantiation(FunctionTearOff(genericMethod)<int>)*/
void enumConstant16() {}

@Helper(GenericEnum)
/*member: enumConstant17:
TypeLiteral(GenericEnum)*/
void enumConstant17() {}

@Helper(self.GenericEnum)
/*member: enumConstant18:
TypeLiteral(GenericEnum)*/
void enumConstant18() {}

@Helper(GenericEnum<bool>)
/*member: enumConstant19:
TypeLiteral(GenericEnum<bool>)*/
void enumConstant19() {}

@Helper(self.GenericEnum<double>)
/*member: enumConstant20:
TypeLiteral(GenericEnum<double>)*/
void enumConstant20() {}

@Helper(Enum.unresolved)
/*member: enumConstant21:
UnresolvedExpression(UnresolvedAccess(
  EnumProto(Enum).unresolved))*/
void enumConstant21() {}

@Helper(self.Enum.unresolved)
/*member: enumConstant22:
UnresolvedExpression(UnresolvedAccess(
  EnumProto(Enum).unresolved))*/
void enumConstant22() {}

@Helper(Enum.unresolved<int>)
/*member: enumConstant23:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    EnumProto(Enum).unresolved)<int>))*/
void enumConstant23() {}

@Helper(self.Enum.unresolved<int>)
/*member: enumConstant24:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    EnumProto(Enum).unresolved)<int>))*/
void enumConstant24() {}




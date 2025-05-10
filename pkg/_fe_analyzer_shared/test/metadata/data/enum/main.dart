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

enum GenericEnum<T> { a<int>(), b<String>() }

@Enum.a
/*member: enumConstant1:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Enum).a))
resolved=StaticGet(a)*/
void enumConstant1() {}

@self.Enum.b
/*member: enumConstant2:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Enum).b))
resolved=StaticGet(b)*/
void enumConstant2() {}

@Enum.variable
/*member: enumConstant3:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Enum).variable))
resolved=StaticGet(variable)*/
void enumConstant3() {}

@self.Enum.variable
/*member: enumConstant4:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Enum).variable))
resolved=StaticGet(variable)*/
void enumConstant4() {}

@Enum.values
/*member: enumConstant5:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Enum).values))
resolved=StaticGet(values)*/
void enumConstant5() {}

@self.Enum.values
/*member: enumConstant6:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Enum).values))
resolved=StaticGet(values)*/
void enumConstant6() {}

@GenericEnum.a
/*member: enumConstant7:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(GenericEnum).a))
resolved=StaticGet(a)*/
void enumConstant7() {}

@self.GenericEnum.b
/*member: enumConstant8:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).GenericEnum).b))
resolved=StaticGet(b)*/
void enumConstant8() {}

@Helper(Enum)
/*member: enumConstant9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(Enum)))))
resolved=TypeLiteral(Enum)*/
void enumConstant9() {}

@Helper(self.Enum)
/*member: enumConstant10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).Enum)))))
resolved=TypeLiteral(Enum)*/
void enumConstant10() {}

@Helper(Enum.method)
/*member: enumConstant11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Enum).method)))))
resolved=FunctionTearOff(method)*/
void enumConstant11() {}

@Helper(self.Enum.method)
/*member: enumConstant12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Enum).method)))))
resolved=FunctionTearOff(method)*/
void enumConstant12() {}

@Helper(Enum.genericMethod)
/*member: enumConstant13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Enum).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void enumConstant13() {}

@Helper(self.Enum.genericMethod)
/*member: enumConstant14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Enum).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void enumConstant14() {}

@Helper(Enum.genericMethod<int>)
/*member: enumConstant15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Enum).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void enumConstant15() {}

@Helper(self.Enum.genericMethod<int>)
/*member: enumConstant16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Enum).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void enumConstant16() {}

@Helper(GenericEnum)
/*member: enumConstant17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(GenericEnum)))))
resolved=TypeLiteral(GenericEnum)*/
void enumConstant17() {}

@Helper(self.GenericEnum)
/*member: enumConstant18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).GenericEnum)))))
resolved=TypeLiteral(GenericEnum)*/
void enumConstant18() {}

@Helper(GenericEnum<bool>)
/*member: enumConstant19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(GenericEnum)<{unresolved-type-annotation:UnresolvedIdentifier(bool)}>)))))
resolved=TypeLiteral(GenericEnum<bool>)*/
void enumConstant19() {}

@Helper(self.GenericEnum<double>)
/*member: enumConstant20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericEnum)<{unresolved-type-annotation:UnresolvedIdentifier(double)}>)))))
resolved=TypeLiteral(GenericEnum<double>)*/
void enumConstant20() {}

@Helper(Enum.unresolved)
/*member: enumConstant21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Enum).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  EnumProto(Enum).unresolved))*/
void enumConstant21() {}

@Helper(self.Enum.unresolved)
/*member: enumConstant22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Enum).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  EnumProto(Enum).unresolved))*/
void enumConstant22() {}

@Helper(Enum.unresolved<int>)
/*member: enumConstant23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Enum).unresolved)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    EnumProto(Enum).unresolved)<int>))*/
void enumConstant23() {}

@Helper(self.Enum.unresolved<int>)
/*member: enumConstant24:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Enum).unresolved)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    EnumProto(Enum).unresolved)<int>))*/
void enumConstant24() {}

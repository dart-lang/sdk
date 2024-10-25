// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

mixin Mixin {
  static const int variable = 42;
  static void method() {}
  static void genericMethod<T>() {}
}

mixin GenericMixin<T> {}

@Mixin.variable
/*member: mixinConstant1:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(Mixin).variable))
resolved=StaticGet(variable)*/
void mixinConstant1() {}

@self.Mixin.variable
/*member: mixinConstant2:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Mixin).variable))
resolved=StaticGet(variable)*/
void mixinConstant2() {}

@Helper(Mixin)
/*member: mixinConstant3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(Mixin)))))
resolved=TypeLiteral(Mixin)*/
void mixinConstant3() {}

@Helper(self.Mixin)
/*member: mixinConstant4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).Mixin)))))
resolved=TypeLiteral(Mixin)*/
void mixinConstant4() {}

@Helper(Mixin.method)
/*member: mixinConstant5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Mixin).method)))))
resolved=FunctionTearOff(method)*/
void mixinConstant5() {}

@Helper(self.Mixin.method)
/*member: mixinConstant6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Mixin).method)))))
resolved=FunctionTearOff(method)*/
void mixinConstant6() {}

@Helper(Mixin.genericMethod)
/*member: mixinConstant7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Mixin).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void mixinConstant7() {}

@Helper(self.Mixin.genericMethod)
/*member: mixinConstant8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Mixin).genericMethod)))))
resolved=FunctionTearOff(genericMethod)*/
void mixinConstant8() {}

@Helper(Mixin.genericMethod<int>)
/*member: mixinConstant9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Mixin).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void mixinConstant9() {}

@Helper(self.Mixin.genericMethod<int>)
/*member: mixinConstant10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Mixin).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void mixinConstant10() {}

@Helper(GenericMixin)
/*member: mixinConstant11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(GenericMixin)))))
resolved=TypeLiteral(GenericMixin)*/
void mixinConstant11() {}

@Helper(self.GenericMixin)
/*member: mixinConstant12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).GenericMixin)))))
resolved=TypeLiteral(GenericMixin)*/
void mixinConstant12() {}

@Helper(GenericMixin<bool>)
/*member: mixinConstant13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(GenericMixin)<{unresolved-type-annotation:UnresolvedIdentifier(bool)}>)))))
resolved=TypeLiteral(GenericMixin<bool>)*/
void mixinConstant13() {}

@Helper(self.GenericMixin<double>)
/*member: mixinConstant14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericMixin)<{unresolved-type-annotation:UnresolvedIdentifier(double)}>)))))
resolved=TypeLiteral(GenericMixin<double>)*/
void mixinConstant14() {}

@Helper(Mixin.unresolved)
/*member: mixinConstant15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Mixin).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  MixinProto(Mixin).unresolved))*/
void mixinConstant15() {}

@Helper(self.Mixin.unresolved)
/*member: mixinConstant16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Mixin).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  MixinProto(Mixin).unresolved))*/
void mixinConstant16() {}

@Helper(Mixin.unresolved<int>)
/*member: mixinConstant17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(Mixin).unresolved)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    MixinProto(Mixin).unresolved)<int>))*/
void mixinConstant17() {}

@Helper(self.Mixin.unresolved<int>)
/*member: mixinConstant18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Mixin).unresolved)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    MixinProto(Mixin).unresolved)<int>))*/
void mixinConstant18() {}

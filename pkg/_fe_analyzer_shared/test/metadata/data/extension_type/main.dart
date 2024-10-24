// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

extension type const ExtensionType(int i) {
  const ExtensionType.named() : i = 42;

  static const variable = 0;

  static void method() {}

  static void genericMethod<T>() {}
}

extension type const GenericExtensionType<T>(T i) {
  const factory GenericExtensionType.named(T t) = GenericExtensionType.new;
}

@ExtensionType.variable
/*member: extensionTypeConstant1:
StaticGet(variable)*/
void extensionTypeConstant1() {}

@self.ExtensionType.variable
/*member: extensionTypeConstant2:
StaticGet(variable)*/
void extensionTypeConstant2() {}

@ExtensionType(10)
/*member: extensionTypeConstant3:
ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant3() {}

@self.ExtensionType(10)
/*member: extensionTypeConstant4:
ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant4() {}

@ExtensionType.new(10)
/*member: extensionTypeConstant5:
ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant5() {}

@self.ExtensionType.new(10)
/*member: extensionTypeConstant6:
ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant6() {}

@ExtensionType.named(10)
/*member: extensionTypeConstant7:
ConstructorInvocation(
  ExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant7() {}

@self.ExtensionType.named(10)
/*member: extensionTypeConstant8:
ConstructorInvocation(
  ExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant8() {}

@GenericExtensionType(10)
/*member: extensionTypeConstant9:
ConstructorInvocation(
  GenericExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant9() {}

@self.GenericExtensionType(10)
/*member: extensionTypeConstant10:
ConstructorInvocation(
  GenericExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant10() {}

@GenericExtensionType<int>(10)
/*member: extensionTypeConstant11:
ConstructorInvocation(
  GenericExtensionType<int>.new(IntegerLiteral(10)))*/
void extensionTypeConstant11() {}

@self.GenericExtensionType<int>(10)
/*member: extensionTypeConstant12:
ConstructorInvocation(
  GenericExtensionType<int>.new(IntegerLiteral(10)))*/
void extensionTypeConstant12() {}

@GenericExtensionType.named(10)
/*member: extensionTypeConstant13:
ConstructorInvocation(
  GenericExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant13() {}

@self.GenericExtensionType.named(10)
/*member: extensionTypeConstant14:
ConstructorInvocation(
  GenericExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant14() {}

@GenericExtensionType<int>.named(10)
/*member: extensionTypeConstant15:
ConstructorInvocation(
  GenericExtensionType<int>.named(IntegerLiteral(10)))*/
void extensionTypeConstant15() {}

@self.GenericExtensionType<int>.named(10)
/*member: extensionTypeConstant16:
ConstructorInvocation(
  GenericExtensionType<int>.named(IntegerLiteral(10)))*/
void extensionTypeConstant16() {}

@ExtensionType.unresolved
/*member: extensionTypeConstant17:
UnresolvedExpression(UnresolvedAccess(
  ExtensionTypeProto(ExtensionType).unresolved))*/
void extensionTypeConstant17() {}

@self.ExtensionType.unresolved
/*member: extensionTypeConstant18:
UnresolvedExpression(UnresolvedAccess(
  ExtensionTypeProto(ExtensionType).unresolved))*/
void extensionTypeConstant18() {}

@Helper(ExtensionType)
/*member: extensionTypeConstant19:
TypeLiteral(ExtensionType)*/
void extensionTypeConstant19() {}

@Helper(ExtensionType.new)
/*member: extensionTypeConstant20:
ConstructorTearOff(ExtensionType.new)*/
void extensionTypeConstant20() {}

@Helper(ExtensionType.named)
/*member: extensionTypeConstant21:
ConstructorTearOff(ExtensionType.named)*/
void extensionTypeConstant21() {}

@Helper(GenericExtensionType)
/*member: extensionTypeConstant22:
TypeLiteral(GenericExtensionType)*/
void extensionTypeConstant22() {}

@Helper(GenericExtensionType<int>)
/*member: extensionTypeConstant23:
TypeLiteral(GenericExtensionType<int>)*/
void extensionTypeConstant23() {}

@Helper(GenericExtensionType.new)
/*member: extensionTypeConstant24:
ConstructorTearOff(GenericExtensionType.new)*/
void extensionTypeConstant24() {}

@Helper(GenericExtensionType<int>.new)
/*member: extensionTypeConstant25:
ConstructorTearOff(GenericExtensionType<int>.new)*/
void extensionTypeConstant25() {}

@Helper(GenericExtensionType.named)
/*member: extensionTypeConstant26:
ConstructorTearOff(GenericExtensionType.named)*/
void extensionTypeConstant26() {}

@Helper(GenericExtensionType<int>.named)
/*member: extensionTypeConstant27:
ConstructorTearOff(GenericExtensionType<int>.named)*/
void extensionTypeConstant27() {}

@Helper(GenericExtensionType<int>.unresolved)
/*member: extensionTypeConstant28:
UnresolvedExpression(UnresolvedAccess(
  GenericExtensionTypeProto(GenericExtensionType<int>).unresolved))*/
void extensionTypeConstant28() {}

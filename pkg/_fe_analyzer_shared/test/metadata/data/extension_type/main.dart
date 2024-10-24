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
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(ExtensionType).variable))
resolved=StaticGet(variable)*/
void extensionTypeConstant1() {}

@self.ExtensionType.variable
/*member: extensionTypeConstant2:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).ExtensionType).variable))
resolved=StaticGet(variable)*/
void extensionTypeConstant2() {}

@ExtensionType(10)
/*member: extensionTypeConstant3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(ExtensionType)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant3() {}

@self.ExtensionType(10)
/*member: extensionTypeConstant4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).ExtensionType)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant4() {}

@ExtensionType.new(10)
/*member: extensionTypeConstant5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(ExtensionType).new)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant5() {}

@self.ExtensionType.new(10)
/*member: extensionTypeConstant6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).ExtensionType).new)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant6() {}

@ExtensionType.named(10)
/*member: extensionTypeConstant7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(ExtensionType).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant7() {}

@self.ExtensionType.named(10)
/*member: extensionTypeConstant8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).ExtensionType).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  ExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant8() {}

@GenericExtensionType(10)
/*member: extensionTypeConstant9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(GenericExtensionType)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant9() {}

@self.GenericExtensionType(10)
/*member: extensionTypeConstant10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).GenericExtensionType)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType.new(IntegerLiteral(10)))*/
void extensionTypeConstant10() {}

@GenericExtensionType<int>(10)
/*member: extensionTypeConstant11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType<int>.new(IntegerLiteral(10)))*/
void extensionTypeConstant11() {}

@self.GenericExtensionType<int>(10)
/*member: extensionTypeConstant12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType<int>.new(IntegerLiteral(10)))*/
void extensionTypeConstant12() {}

@GenericExtensionType.named(10)
/*member: extensionTypeConstant13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericExtensionType).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant13() {}

@self.GenericExtensionType.named(10)
/*member: extensionTypeConstant14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericExtensionType).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType.named(IntegerLiteral(10)))*/
void extensionTypeConstant14() {}

@GenericExtensionType<int>.named(10)
/*member: extensionTypeConstant15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType<int>.named(IntegerLiteral(10)))*/
void extensionTypeConstant15() {}

@self.GenericExtensionType<int>.named(10)
/*member: extensionTypeConstant16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)
  (IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericExtensionType<int>.named(IntegerLiteral(10)))*/
void extensionTypeConstant16() {}

@ExtensionType.unresolved
/*member: extensionTypeConstant17:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(ExtensionType).unresolved))
resolved=UnresolvedExpression(UnresolvedAccess(
  ExtensionTypeProto(ExtensionType).unresolved))*/
void extensionTypeConstant17() {}

@self.ExtensionType.unresolved
/*member: extensionTypeConstant18:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    UnresolvedIdentifier(self).ExtensionType).unresolved))
resolved=UnresolvedExpression(UnresolvedAccess(
  ExtensionTypeProto(ExtensionType).unresolved))*/
void extensionTypeConstant18() {}

@Helper(ExtensionType)
/*member: extensionTypeConstant19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(ExtensionType)))))
resolved=TypeLiteral(ExtensionType)*/
void extensionTypeConstant19() {}

@Helper(ExtensionType.new)
/*member: extensionTypeConstant20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(ExtensionType).new)))))
resolved=ConstructorTearOff(ExtensionType.new)*/
void extensionTypeConstant20() {}

@Helper(ExtensionType.named)
/*member: extensionTypeConstant21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(ExtensionType).named)))))
resolved=ConstructorTearOff(ExtensionType.named)*/
void extensionTypeConstant21() {}

@Helper(GenericExtensionType)
/*member: extensionTypeConstant22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(GenericExtensionType)))))
resolved=TypeLiteral(GenericExtensionType)*/
void extensionTypeConstant22() {}

@Helper(GenericExtensionType<int>)
/*member: extensionTypeConstant23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=TypeLiteral(GenericExtensionType<int>)*/
void extensionTypeConstant23() {}

@Helper(GenericExtensionType.new)
/*member: extensionTypeConstant24:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericExtensionType).new)))))
resolved=ConstructorTearOff(GenericExtensionType.new)*/
void extensionTypeConstant24() {}

@Helper(GenericExtensionType<int>.new)
/*member: extensionTypeConstant25:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)))))
resolved=ConstructorTearOff(GenericExtensionType<int>.new)*/
void extensionTypeConstant25() {}

@Helper(GenericExtensionType.named)
/*member: extensionTypeConstant26:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericExtensionType).named)))))
resolved=ConstructorTearOff(GenericExtensionType.named)*/
void extensionTypeConstant26() {}

@Helper(GenericExtensionType<int>.named)
/*member: extensionTypeConstant27:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)))))
resolved=ConstructorTearOff(GenericExtensionType<int>.named)*/
void extensionTypeConstant27() {}

@Helper(GenericExtensionType<int>.unresolved)
/*member: extensionTypeConstant28:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericExtensionType)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericExtensionTypeProto(GenericExtensionType<int>).unresolved))*/
void extensionTypeConstant28() {}

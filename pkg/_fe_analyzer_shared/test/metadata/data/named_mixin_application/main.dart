// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

class Mixin {}

class Super {
  const Super([a]);
  const Super.named({a});
}

class GenericSuper<T> {
  const GenericSuper([a]);
  const GenericSuper.named({a});
}

class NamedMixinApplication = Super with Mixin;

class GenericNamedMixinApplication<T> = GenericSuper<T> with Mixin;

@NamedMixinApplication(0)
/*member: namedMixinApplication1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(NamedMixinApplication)
  (IntegerLiteral(0))))
resolved=ConstructorInvocation(
  NamedMixinApplication.new(IntegerLiteral(0)))*/
void namedMixinApplication1() {}

@self.NamedMixinApplication(1)
/*member: namedMixinApplication2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).NamedMixinApplication)
  (IntegerLiteral(1))))
resolved=ConstructorInvocation(
  NamedMixinApplication.new(IntegerLiteral(1)))*/
void namedMixinApplication2() {}

@NamedMixinApplication.new(0)
/*member: namedMixinApplication3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).new)
  (IntegerLiteral(0))))
resolved=ConstructorInvocation(
  NamedMixinApplication.new(IntegerLiteral(0)))*/
void namedMixinApplication3() {}

@self.NamedMixinApplication.new(1)
/*member: namedMixinApplication4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).new)
  (IntegerLiteral(1))))
resolved=ConstructorInvocation(
  NamedMixinApplication.new(IntegerLiteral(1)))*/
void namedMixinApplication4() {}

@NamedMixinApplication.named(a: 2)
/*member: namedMixinApplication5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).named)
  (a: IntegerLiteral(2))))
resolved=ConstructorInvocation(
  NamedMixinApplication.named(a: IntegerLiteral(2)))*/
void namedMixinApplication5() {}

@self.NamedMixinApplication.named(a: 3)
/*member: namedMixinApplication6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).named)
  (a: IntegerLiteral(3))))
resolved=ConstructorInvocation(
  NamedMixinApplication.named(a: IntegerLiteral(3)))*/
void namedMixinApplication6() {}

@GenericNamedMixinApplication(4)
/*member: namedMixinApplication7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(GenericNamedMixinApplication)
  (IntegerLiteral(4))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.new(IntegerLiteral(4)))*/
void namedMixinApplication7() {}

@self.GenericNamedMixinApplication(5)
/*member: namedMixinApplication8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).GenericNamedMixinApplication)
  (IntegerLiteral(5))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.new(IntegerLiteral(5)))*/
void namedMixinApplication8() {}

@GenericNamedMixinApplication.new(4)
/*member: namedMixinApplication9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).new)
  (IntegerLiteral(4))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.new(IntegerLiteral(4)))*/
void namedMixinApplication9() {}

@self.GenericNamedMixinApplication.new(5)
/*member: namedMixinApplication10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).new)
  (IntegerLiteral(5))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.new(IntegerLiteral(5)))*/
void namedMixinApplication10() {}

@GenericNamedMixinApplication.named(a: 6)
/*member: namedMixinApplication11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).named)
  (a: IntegerLiteral(6))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.named(a: IntegerLiteral(6)))*/
void namedMixinApplication11() {}

@self.GenericNamedMixinApplication.named(a: 7)
/*member: namedMixinApplication12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).named)
  (a: IntegerLiteral(7))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication.named(a: IntegerLiteral(7)))*/
void namedMixinApplication12() {}

@GenericNamedMixinApplication<int>(8)
/*member: namedMixinApplication13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)
  (IntegerLiteral(8))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.new(IntegerLiteral(8)))*/
void namedMixinApplication13() {}

@self.GenericNamedMixinApplication<int>(9)
/*member: namedMixinApplication14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)
  (IntegerLiteral(9))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.new(IntegerLiteral(9)))*/
void namedMixinApplication14() {}

@GenericNamedMixinApplication<int>.new(8)
/*member: namedMixinApplication15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)
  (IntegerLiteral(8))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.new(IntegerLiteral(8)))*/
void namedMixinApplication15() {}

@self.GenericNamedMixinApplication<int>.new(9)
/*member: namedMixinApplication16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)
  (IntegerLiteral(9))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.new(IntegerLiteral(9)))*/
void namedMixinApplication16() {}

@GenericNamedMixinApplication<int>.named(a: 10)
/*member: namedMixinApplication17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)
  (a: IntegerLiteral(10))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.named(a: IntegerLiteral(10)))*/
void namedMixinApplication17() {}

@self.GenericNamedMixinApplication<int>.named(a: 11)
/*member: namedMixinApplication18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)
  (a: IntegerLiteral(11))))
resolved=ConstructorInvocation(
  GenericNamedMixinApplication<int>.named(a: IntegerLiteral(11)))*/
void namedMixinApplication18() {}

@Helper(NamedMixinApplication)
/*member: namedMixinApplication19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(NamedMixinApplication)))))
resolved=TypeLiteral(NamedMixinApplication)*/
void namedMixinApplication19() {}

@Helper(self.NamedMixinApplication)
/*member: namedMixinApplication20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).NamedMixinApplication)))))
resolved=TypeLiteral(NamedMixinApplication)*/
void namedMixinApplication20() {}

@Helper(NamedMixinApplication.new)
/*member: namedMixinApplication21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).new)))))
resolved=ConstructorTearOff(NamedMixinApplication.new)*/
void namedMixinApplication21() {}

@Helper(self.NamedMixinApplication.new)
/*member: namedMixinApplication22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).new)))))
resolved=ConstructorTearOff(NamedMixinApplication.new)*/
void namedMixinApplication22() {}

@Helper(NamedMixinApplication.named)
/*member: namedMixinApplication23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).named)))))
resolved=ConstructorTearOff(NamedMixinApplication.named)*/
void namedMixinApplication23() {}

@Helper(self.NamedMixinApplication.named)
/*member: namedMixinApplication24:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).named)))))
resolved=ConstructorTearOff(NamedMixinApplication.named)*/
void namedMixinApplication24() {}

@Helper(GenericNamedMixinApplication)
/*member: namedMixinApplication25:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(GenericNamedMixinApplication)))))
resolved=TypeLiteral(GenericNamedMixinApplication)*/
void namedMixinApplication25() {}

@Helper(self.GenericNamedMixinApplication)
/*member: namedMixinApplication26:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).GenericNamedMixinApplication)))))
resolved=TypeLiteral(GenericNamedMixinApplication)*/
void namedMixinApplication26() {}

@Helper(GenericNamedMixinApplication.new)
/*member: namedMixinApplication27:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).new)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication.new)*/
void namedMixinApplication27() {}

@Helper(self.GenericNamedMixinApplication.new)
/*member: namedMixinApplication28:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).new)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication.new)*/
void namedMixinApplication28() {}

@Helper(GenericNamedMixinApplication.named)
/*member: namedMixinApplication29:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).named)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication.named)*/
void namedMixinApplication29() {}

@Helper(self.GenericNamedMixinApplication.named)
/*member: namedMixinApplication30:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).named)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication.named)*/
void namedMixinApplication30() {}

@Helper(GenericNamedMixinApplication<int>)
/*member: namedMixinApplication31:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=TypeLiteral(GenericNamedMixinApplication<int>)*/
void namedMixinApplication31() {}

@Helper(self.GenericNamedMixinApplication<int>)
/*member: namedMixinApplication32:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=TypeLiteral(GenericNamedMixinApplication<int>)*/
void namedMixinApplication32() {}

@Helper(GenericNamedMixinApplication<int>.new)
/*member: namedMixinApplication33:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication<int>.new)*/
void namedMixinApplication33() {}

@Helper(self.GenericNamedMixinApplication<int>.new)
/*member: namedMixinApplication34:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication<int>.new)*/
void namedMixinApplication34() {}

@Helper(GenericNamedMixinApplication<int>.named)
/*member: namedMixinApplication35:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication<int>.named)*/
void namedMixinApplication35() {}

@Helper(self.GenericNamedMixinApplication<int>.named)
/*member: namedMixinApplication36:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)))))
resolved=ConstructorTearOff(GenericNamedMixinApplication<int>.named)*/
void namedMixinApplication36() {}

@NamedMixinApplication.unresolved()
/*member: namedMixinApplication37:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(NamedMixinApplication).unresolved)
  ()))*/
void namedMixinApplication37() {}

@self.NamedMixinApplication.unresolved()
/*member: namedMixinApplication38:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(NamedMixinApplication).unresolved)
  ()))*/
void namedMixinApplication38() {}

@GenericNamedMixinApplication.unresolved()
/*member: namedMixinApplication39:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericNamedMixinApplication).unresolved)
  ()))*/
void namedMixinApplication39() {}

@self.GenericNamedMixinApplication.unresolved()
/*member: namedMixinApplication40:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericNamedMixinApplication).unresolved)
  ()))*/
void namedMixinApplication40() {}

@GenericNamedMixinApplication<int>.unresolved()
/*member: namedMixinApplication41:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericNamedMixinApplication<int>).unresolved)
  ()))*/
void namedMixinApplication41() {}

@self.GenericNamedMixinApplication<int>.unresolved()
/*member: namedMixinApplication42:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).unresolved)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericNamedMixinApplication<int>).unresolved)
  ()))*/
void namedMixinApplication42() {}

@Helper(NamedMixinApplication.unresolved)
/*member: namedMixinApplication43:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(NamedMixinApplication).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(NamedMixinApplication).unresolved))*/
void namedMixinApplication43() {}

@Helper(self.NamedMixinApplication.unresolved)
/*member: namedMixinApplication44:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).NamedMixinApplication).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(NamedMixinApplication).unresolved))*/
void namedMixinApplication44() {}

@Helper(GenericNamedMixinApplication.unresolved)
/*member: namedMixinApplication45:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericNamedMixinApplication).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(GenericNamedMixinApplication).unresolved))*/
void namedMixinApplication45() {}

@Helper(self.GenericNamedMixinApplication.unresolved)
/*member: namedMixinApplication46:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericNamedMixinApplication).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(GenericNamedMixinApplication).unresolved))*/
void namedMixinApplication46() {}

@Helper(GenericNamedMixinApplication<int>.unresolved)
/*member: namedMixinApplication47:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericNamedMixinApplication<int>).unresolved))*/
void namedMixinApplication47() {}

@Helper(self.GenericNamedMixinApplication<int>.unresolved)
/*member: namedMixinApplication48:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericNamedMixinApplication)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).unresolved)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericNamedMixinApplication<int>).unresolved))*/
void namedMixinApplication48() {}

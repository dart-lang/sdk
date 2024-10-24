// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

const String variable = '';

void function() {}

class Class {
  const Class();
  const Class.named();

  static const String field = '';

  static void method() {}
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named();
}

typedef Alias = Class;
typedef ComplexAlias<X> = Class;
typedef GenericAlias<X, Y> = GenericClass<X, Y>;

@Helper(variable)
/*member: access1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(variable)))))
resolved=StaticGet(variable)*/
void access1() {}

@Helper(variable.length)
/*member: access2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(variable).length)))))
resolved=PropertyGet(StaticGet(variable).length)*/
void access2() {}

@Helper(function)
/*member: access3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(function)))))
resolved=FunctionTearOff(function)*/
void access3() {}

@Helper(Class)
/*member: access4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(Class)))))
resolved=TypeLiteral(Class)*/
void access4() {}

@Helper(Class.new)
/*member: access5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).new)))))
resolved=ConstructorTearOff(Class.new)*/
void access5() {}

@Helper(Class.named)
/*member: access6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).named)))))
resolved=ConstructorTearOff(Class.named)*/
void access6() {}

@Helper(Class.field)
/*member: access7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).field)))))
resolved=StaticGet(field)*/
void access7() {}

@Helper(Class.field.length)
/*member: access8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).field).length)))))
resolved=PropertyGet(StaticGet(field).length)*/
void access8() {}

@Helper(Class.method)
/*member: access9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).method)))))
resolved=FunctionTearOff(method)*/
void access9() {}

@Helper(self.variable)
/*member: access10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).variable)))))
resolved=StaticGet(variable)*/
void access10() {}

@Helper(self.variable.length)
/*member: access11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).variable).length)))))
resolved=PropertyGet(StaticGet(variable).length)*/
void access11() {}

@Helper(self.function)
/*member: access12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).function)))))
resolved=FunctionTearOff(function)*/
void access12() {}

@Helper(self.Class)
/*member: access13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).Class)))))
resolved=TypeLiteral(Class)*/
void access13() {}

@Helper(self.Class.new)
/*member: access14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).new)))))
resolved=ConstructorTearOff(Class.new)*/
void access14() {}

@Helper(self.Class.named)
/*member: access15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).named)))))
resolved=ConstructorTearOff(Class.named)*/
void access15() {}

@Helper(self.Class.field)
/*member: access16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).field)))))
resolved=StaticGet(field)*/
void access16() {}

@Helper(self.Class.field.length)
/*member: access17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).field).length)))))
resolved=PropertyGet(StaticGet(field).length)*/
void access17() {}

@Helper(self.Class.method)
/*member: access18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).method)))))
resolved=FunctionTearOff(method)*/
void access18() {}

@Helper(dynamic)
/*member: access19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(dynamic)))))
resolved=TypeLiteral(dynamic)*/
void access19() {}

@Helper(Alias.new)
/*member: access20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Alias).new)))))
resolved=ConstructorTearOff(Alias.new)*/
void access20() {}

@Helper(Alias.named)
/*member: access21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Alias).named)))))
resolved=ConstructorTearOff(Alias.named)*/
void access21() {}

@Helper(ComplexAlias.new)
/*member: access22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(ComplexAlias).new)))))
resolved=ConstructorTearOff(ComplexAlias.new)*/
void access22() {}

@Helper(ComplexAlias.named)
/*member: access23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(ComplexAlias).named)))))
resolved=ConstructorTearOff(ComplexAlias.named)*/
void access23() {}

@Helper(ComplexAlias<int>.new)
/*member: access24:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(ComplexAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)))))
resolved=ConstructorTearOff(ComplexAlias<int>.new)*/
void access24() {}

@Helper(ComplexAlias<int>.named)
/*member: access25:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(ComplexAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)))))
resolved=ConstructorTearOff(ComplexAlias<int>.named)*/
void access25() {}

@Helper(GenericAlias.new)
/*member: access26:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericAlias).new)))))
resolved=ConstructorTearOff(GenericAlias.new)*/
void access26() {}

@Helper(GenericAlias.named)
/*member: access27:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(GenericAlias).named)))))
resolved=ConstructorTearOff(GenericAlias.named)*/
void access27() {}

@Helper(GenericAlias<int, String>.new)
/*member: access28:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(String)}>).new)))))
resolved=ConstructorTearOff(GenericAlias<int,String>.new)*/
void access28() {}

@Helper(GenericAlias<int, String>.named)
/*member: access29:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(String)}>).named)))))
resolved=ConstructorTearOff(GenericAlias<int,String>.named)*/
void access29() {}

@Helper(dynamic)
/*member: access30:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(dynamic)))))
resolved=TypeLiteral(dynamic)*/
void access30() {}

@Helper(self.Alias.new)
/*member: access31:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Alias).new)))))
resolved=ConstructorTearOff(Alias.new)*/
void access31() {}

@Helper(self.Alias.named)
/*member: access32:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Alias).named)))))
resolved=ConstructorTearOff(Alias.named)*/
void access32() {}

@Helper(self.ComplexAlias.new)
/*member: access33:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).ComplexAlias).new)))))
resolved=ConstructorTearOff(ComplexAlias.new)*/
void access33() {}

@Helper(self.ComplexAlias.named)
/*member: access34:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).ComplexAlias).named)))))
resolved=ConstructorTearOff(ComplexAlias.named)*/
void access34() {}

@Helper(self.ComplexAlias<int>.new)
/*member: access35:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).ComplexAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).new)))))
resolved=ConstructorTearOff(ComplexAlias<int>.new)*/
void access35() {}

@Helper(self.ComplexAlias<int>.named)
/*member: access36:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).ComplexAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>).named)))))
resolved=ConstructorTearOff(ComplexAlias<int>.named)*/
void access36() {}

@Helper(self.GenericAlias.new)
/*member: access37:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericAlias).new)))))
resolved=ConstructorTearOff(GenericAlias.new)*/
void access37() {}

@Helper(self.GenericAlias.named)
/*member: access38:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericAlias).named)))))
resolved=ConstructorTearOff(GenericAlias.named)*/
void access38() {}

@Helper(self.GenericAlias<int, String>.new)
/*member: access39:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(String)}>).new)))))
resolved=ConstructorTearOff(GenericAlias<int,String>.new)*/
void access39() {}

@Helper(self.GenericAlias<int, String>.named)
/*member: access40:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(String)}>).named)))))
resolved=ConstructorTearOff(GenericAlias<int,String>.named)*/
void access40() {}

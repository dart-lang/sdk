// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

const String variable = '';

void function() {}

class Class {
  const Class([a]);
  const Class.named({a, b});
  const Class.mixed(a, b, {c, d});
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named({a, b});
}

@variable
/*member: annotation1:
unresolved=UnresolvedExpression(UnresolvedIdentifier(variable))
resolved=StaticGet(variable)*/
void annotation1() {}

@function
/*member: annotation2:
unresolved=UnresolvedExpression(UnresolvedIdentifier(function))
resolved=FunctionTearOff(function)*/
void annotation2() {}

@self.variable
/*member: annotation3:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(self).variable))
resolved=StaticGet(variable)*/
void annotation3() {}

@self.function
/*member: annotation4:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(self).function))
resolved=FunctionTearOff(function)*/
void annotation4() {}

@Class()
/*member: annotation5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Class)
  ()))
resolved=ConstructorInvocation(
  Class.new())*/
void annotation5() {}

@Class.named()
/*member: annotation6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  ()))
resolved=ConstructorInvocation(
  Class.named())*/
void annotation6() {}

@Class.named(a: 0)
/*member: annotation7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (a: IntegerLiteral(0))))
resolved=ConstructorInvocation(
  Class.named(a: IntegerLiteral(0)))*/
void annotation7() {}

@Class.named(b: 1)
/*member: annotation8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (b: IntegerLiteral(1))))
resolved=ConstructorInvocation(
  Class.named(b: IntegerLiteral(1)))*/
void annotation8() {}

@Class.named(a: 0, b: 1)
/*member: annotation9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1))))
resolved=ConstructorInvocation(
  Class.named(
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1)))*/
void annotation9() {}

@Class.mixed(0, 1)
/*member: annotation10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1))))
resolved=ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1)))*/
void annotation10() {}

@Class.mixed(0, 1, c: 2)
/*member: annotation11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2))))
resolved=ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2)))*/
void annotation11() {}

@Class.mixed(0, 1, c: 2, d: 3)
/*member: annotation12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2), 
    d: IntegerLiteral(3))))
resolved=ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2), 
    d: IntegerLiteral(3)))*/
void annotation12() {}

@Class.mixed(0, 1, d: 3)
/*member: annotation13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3))))
resolved=ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3)))*/
void annotation13() {}

@Class.mixed(d: 3, 0, c: 2, 1)
/*member: annotation14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    d: IntegerLiteral(3), 
    IntegerLiteral(0), 
    c: IntegerLiteral(2), 
    IntegerLiteral(1))))
resolved=ConstructorInvocation(
  Class.mixed(
    d: IntegerLiteral(3), 
    IntegerLiteral(0), 
    c: IntegerLiteral(2), 
    IntegerLiteral(1)))*/
void annotation14() {}

@self.Class()
/*member: annotation15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).Class)
  ()))
resolved=ConstructorInvocation(
  Class.new())*/
void annotation15() {}

@self.Class.named()
/*member: annotation16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).named)
  ()))
resolved=ConstructorInvocation(
  Class.named())*/
void annotation16() {}

@GenericClass()
/*member: annotation17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(GenericClass)
  ()))
resolved=ConstructorInvocation(
  GenericClass.new())*/
void annotation17() {}

@GenericClass<Class, Class>()
/*member: annotation18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
  ()))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void annotation18() {}

@GenericClass.named()
/*member: annotation19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericClass).named)
  ()))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void annotation19() {}

@GenericClass<Class, self.Class>.named()
/*member: annotation20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
        UnresolvedIdentifier(self).Class)}>).named)
  ()))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void annotation20() {}

@self.GenericClass.named()
/*member: annotation21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericClass).named)
  ()))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void annotation21() {}

@self.GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named()
/*member: annotation22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}?>)}>).named)
  ()))
resolved=ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void annotation22() {}

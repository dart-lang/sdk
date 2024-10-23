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
StaticGet(variable)*/
void annotation1() {}

@function
/*member: annotation2:
FunctionTearOff(function)*/
void annotation2() {}

@self.variable
/*member: annotation3:
StaticGet(variable)*/
void annotation3() {}

@self.function
/*member: annotation4:
FunctionTearOff(function)*/
void annotation4() {}

@Class()
/*member: annotation5:
ConstructorInvocation(
  Class.new())*/
void annotation5() {}

@Class.named()
/*member: annotation6:
ConstructorInvocation(
  Class.named())*/
void annotation6() {}

@Class.named(a: 0)
/*member: annotation7:
ConstructorInvocation(
  Class.named(a: IntegerLiteral(0)))*/
void annotation7() {}

@Class.named(b: 1)
/*member: annotation8:
ConstructorInvocation(
  Class.named(b: IntegerLiteral(1)))*/
void annotation8() {}

@Class.named(a: 0, b: 1)
/*member: annotation9:
ConstructorInvocation(
  Class.named(
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1)))*/
void annotation9() {}

@Class.mixed(0, 1)
/*member: annotation10:
ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1)))*/
void annotation10() {}

@Class.mixed(0, 1, c: 2)
/*member: annotation11:
ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2)))*/
void annotation11() {}

@Class.mixed(0, 1, c: 2, d: 3)
/*member: annotation12:
ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2), 
    d: IntegerLiteral(3)))*/
void annotation12() {}

@Class.mixed(0, 1, d: 3)
/*member: annotation13:
ConstructorInvocation(
  Class.mixed(
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3)))*/
void annotation13() {}

@Class.mixed(d: 3, 0, c: 2, 1)
/*member: annotation14:
ConstructorInvocation(
  Class.mixed(
    d: IntegerLiteral(3), 
    IntegerLiteral(0), 
    c: IntegerLiteral(2), 
    IntegerLiteral(1)))*/
void annotation14() {}

@self.Class()
/*member: annotation15:
ConstructorInvocation(
  Class.new())*/
void annotation15() {}

@self.Class.named()
/*member: annotation16:
ConstructorInvocation(
  Class.named())*/
void annotation16() {}

@GenericClass()
/*member: annotation17:
ConstructorInvocation(
  GenericClass.new())*/
void annotation17() {}

@GenericClass<Class, Class>()
/*member: annotation18:
ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void annotation18() {}

@GenericClass.named()
/*member: annotation19:
ConstructorInvocation(
  GenericClass.named())*/
void annotation19() {}

@GenericClass<Class, self.Class>.named()
/*member: annotation20:
ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void annotation20() {}

@self.GenericClass.named()
/*member: annotation21:
ConstructorInvocation(
  GenericClass.named())*/
void annotation21() {}

@self.GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named()
/*member: annotation22:
ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void annotation22() {}

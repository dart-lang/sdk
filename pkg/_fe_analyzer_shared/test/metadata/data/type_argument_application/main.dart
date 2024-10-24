// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

T genericFunction<T>(T t) => t;

const T Function<T>(T t) genericFunctionAlias = genericFunction;

class Class {
  const Class([a]);
  const Class.named({a, b});
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named({a, b});

  static T genericMethod<T>(T t) => t;

  static const T Function<T>(T t) genericMethodAlias = genericMethod;
}

@Helper(genericFunctionAlias<int>)
/*member: typeArgumentApplications1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(genericFunctionAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(StaticGet(genericFunctionAlias)<int>)*/
void typeArgumentApplications1() {}

@Helper(genericFunction<int>)
/*member: typeArgumentApplications2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(genericFunction)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericFunction)<int>)*/
void typeArgumentApplications2() {}

@Helper(GenericClass<Class, Class?>)
/*member: typeArgumentApplications3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>)))))
resolved=TypeLiteral(GenericClass<Class,Class?>)*/
void typeArgumentApplications3() {}

@Helper(GenericClass<Class, Class?>.new)
/*member: typeArgumentApplications4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).new)))))
resolved=ConstructorTearOff(GenericClass<Class,Class?>.new)*/
void typeArgumentApplications4() {}

@Helper(GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).named)))))
resolved=ConstructorTearOff(GenericClass<Class,Class?>.named)*/
void typeArgumentApplications5() {}

@Helper(GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).genericMethodAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(StaticGet(genericMethodAlias)<int>)*/
void typeArgumentApplications6() {}

@Helper(GenericClass.genericMethod<int>)
/*member: typeArgumentApplications7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void typeArgumentApplications7() {}

@Helper(self.genericFunctionAlias<int>)
/*member: typeArgumentApplications8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).genericFunctionAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(StaticGet(genericFunctionAlias)<int>)*/
void typeArgumentApplications8() {}

@Helper(self.genericFunction<int>)
/*member: typeArgumentApplications9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).genericFunction)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericFunction)<int>)*/
void typeArgumentApplications9() {}

@Helper(self.GenericClass<Class, Class?>)
/*member: typeArgumentApplications10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>)))))
resolved=TypeLiteral(GenericClass<Class,Class?>)*/
void typeArgumentApplications10() {}

@Helper(self.GenericClass<Class, Class?>.new)
/*member: typeArgumentApplications11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).new)))))
resolved=ConstructorTearOff(GenericClass<Class,Class?>.new)*/
void typeArgumentApplications11() {}

@Helper(self.GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).named)))))
resolved=ConstructorTearOff(GenericClass<Class,Class?>.named)*/
void typeArgumentApplications12() {}

@Helper(self.GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).genericMethodAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(StaticGet(genericMethodAlias)<int>)*/
void typeArgumentApplications13() {}

@Helper(self.GenericClass.genericMethod<int>)
/*member: typeArgumentApplications14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=Instantiation(FunctionTearOff(genericMethod)<int>)*/
void typeArgumentApplications14() {}

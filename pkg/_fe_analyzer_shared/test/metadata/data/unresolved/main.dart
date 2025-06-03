// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

// Annotations work if a macro that generates these:
//
// const String variable = '';
//
// const bool constBool = true;
//
// const int constInt = 42;
//
// const String? constNullableString = '';
//
// const List<int> constList = [];
//
// const List<int>? constNullableList = [];
//
// const Map<int, int>? constNullableMap = {};
//
// T genericFunction<T>(T t) => t;
//
// const T Function<T>(T t) genericFunctionAlias = genericFunction;
//
// void function() {}
//
// class UnresolvedClass {
//   const UnresolvedClass();
// }
//
// class UnresolvedGenericClass<X, Y> {
//   const UnresolvedGenericClass();
// }

class LateDefaultConstructorClass<X, Y> {
  // Annotations work if a macro that generates this:
  //
  // const LateDefaultConstructorClass();
  //
  const LateDefaultConstructorClass.named();
}

class Class {
  const Class([a]);
  // Annotations work if a macro that generates these:
  //
  // const Class.named({a, b});
  // const Class.mixed(a, b, {c, d});
  //
  // static const String field = '';
  //
  // static void method() {}
}

class GenericClass<X, Y> {
  const GenericClass();
  // Annotations work if a macro that generates these:
  //
  // const GenericClass.named({a, b});
  //
  // static T genericMethod<T>(T t) => t;
  //
  // static const T Function<T>(T t) genericMethodAlias = genericMethod;
}

@variable
/*member: metadataAnnotations1:
unresolved=UnresolvedExpression(UnresolvedIdentifier(variable))
resolved=UnresolvedExpression(UnresolvedIdentifier(variable))*/
void metadataAnnotations1() {}

@function
/*member: metadataAnnotations2:
unresolved=UnresolvedExpression(UnresolvedIdentifier(function))
resolved=UnresolvedExpression(UnresolvedIdentifier(function))*/
void metadataAnnotations2() {}

@self.variable
/*member: metadataAnnotations3:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(self).variable))
resolved=UnresolvedExpression(UnresolvedIdentifier(variable))*/
void metadataAnnotations3() {}

@self.function
/*member: metadataAnnotations4:
unresolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(self).function))
resolved=UnresolvedExpression(UnresolvedIdentifier(function))*/
void metadataAnnotations4() {}

@LateDefaultConstructorClass()
/*member: metadataAnnotations5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(LateDefaultConstructorClass)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations5() {}

@Class.named()
/*member: metadataAnnotations6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void metadataAnnotations6() {}

@Class.named(a: 0)
/*member: metadataAnnotations7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (a: IntegerLiteral(0))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (a: IntegerLiteral(0))))*/
void metadataAnnotations7() {}

@Class.named(b: 1)
/*member: metadataAnnotations8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (b: IntegerLiteral(1))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (b: IntegerLiteral(1))))*/
void metadataAnnotations8() {}

@Class.named(a: 0, b: 1)
/*member: metadataAnnotations9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).named)
  (
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1))))*/
void metadataAnnotations9() {}

@Class.mixed(0, 1)
/*member: metadataAnnotations10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1))))*/
void metadataAnnotations10() {}

@Class.mixed(0, 1, c: 2)
/*member: metadataAnnotations11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2))))*/
void metadataAnnotations11() {}

@Class.mixed(0, 1, c: 2, d: 3)
/*member: metadataAnnotations12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2), 
    d: IntegerLiteral(3))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2), 
    d: IntegerLiteral(3))))*/
void metadataAnnotations12() {}

@Class.mixed(0, 1, d: 3)
/*member: metadataAnnotations13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3))))*/
void metadataAnnotations13() {}

@Class.mixed(d: 3, 0, c: 2, 1)
/*member: metadataAnnotations14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(Class).mixed)
  (
    d: IntegerLiteral(3), 
    IntegerLiteral(0), 
    c: IntegerLiteral(2), 
    IntegerLiteral(1))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    d: IntegerLiteral(3), 
    IntegerLiteral(0), 
    c: IntegerLiteral(2), 
    IntegerLiteral(1))))*/
void metadataAnnotations14() {}

@self.LateDefaultConstructorClass()
/*member: metadataAnnotations15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(self).LateDefaultConstructorClass)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations15() {}

@self.Class.named()
/*member: metadataAnnotations16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void metadataAnnotations16() {}

@LateDefaultConstructorClass()
/*member: metadataAnnotations17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(LateDefaultConstructorClass)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations17() {}

@LateDefaultConstructorClass<Class, Class>()
/*member: metadataAnnotations18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void metadataAnnotations18() {}

@UnresolvedGenericClass<Class, Class>()
/*member: metadataAnnotations19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class>)
  ()))*/
void metadataAnnotations19() {}

@GenericClass.named()
/*member: metadataAnnotations20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedIdentifier(GenericClass).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void metadataAnnotations20() {}

@GenericClass<Class, self.Class>.named()
/*member: metadataAnnotations21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
        UnresolvedIdentifier(self).Class)}>).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void metadataAnnotations21() {}

@self.GenericClass.named()
/*member: metadataAnnotations22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).GenericClass).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void metadataAnnotations22() {}

@self.GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named()
/*member: metadataAnnotations23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}?>)}>).named)
  ()))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void metadataAnnotations23() {}

@Helper('-$variable-')
/*member: literals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('-${UnresolvedExpression(UnresolvedIdentifier(variable))}-'))))
resolved=StringLiteral('-${UnresolvedExpression(UnresolvedIdentifier(variable))}-')*/
void literals1() {}

@Helper('a${constInt}b')
/*member: literals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('a${UnresolvedExpression(UnresolvedIdentifier(constInt))}b'))))
resolved=StringLiteral('a${UnresolvedExpression(UnresolvedIdentifier(constInt))}b')*/
void literals2() {}

@Helper(
  'a'
  'b${constInt}'
  'c',
)
/*member: literals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (AdjacentStringLiterals(
      StringLiteral('a')
      StringLiteral('b${UnresolvedExpression(UnresolvedIdentifier(constInt))}')
      StringLiteral('c')))))
resolved=AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b${UnresolvedExpression(UnresolvedIdentifier(constInt))}')
    StringLiteral('c'))*/
void literals3() {}

@Helper(variable)
/*member: access1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(variable)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(variable))*/
void access1() {}

@Helper(variable.length)
/*member: access2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(variable).length)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(variable).length))*/
void access2() {}

@Helper(function)
/*member: access3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(function)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(function))*/
void access3() {}

@Helper(UnresolvedClass)
/*member: access4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedIdentifier(UnresolvedClass)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(UnresolvedClass))*/
void access4() {}

@Helper(LateDefaultConstructorClass.new)
/*member: access5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(LateDefaultConstructorClass).new)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(LateDefaultConstructorClass).))*/
void access5() {}

@Helper(Class.named)
/*member: access6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).named)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).named))*/
void access6() {}

@Helper(Class.field)
/*member: access7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).field)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).field))*/
void access7() {}

@Helper(Class.field.length)
/*member: access8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).field).length)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    ClassProto(Class).field).length))*/
void access8() {}

@Helper(Class.method)
/*member: access9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(Class).method)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).method))*/
void access9() {}

@Helper(self.variable)
/*member: access10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).variable)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(variable))*/
void access10() {}

@Helper(self.variable.length)
/*member: access11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).variable).length)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(variable).length))*/
void access11() {}

@Helper(self.function)
/*member: access12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).function)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(function))*/
void access12() {}

@Helper(self.UnresolvedClass)
/*member: access13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedIdentifier(self).UnresolvedClass)))))
resolved=UnresolvedExpression(UnresolvedIdentifier(UnresolvedClass))*/
void access13() {}

@Helper(self.LateDefaultConstructorClass.new)
/*member: access14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).LateDefaultConstructorClass).new)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(LateDefaultConstructorClass).))*/
void access14() {}

@Helper(self.Class.named)
/*member: access15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).named)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).named))*/
void access15() {}

@Helper(self.Class.field)
/*member: access16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).field)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).field))*/
void access16() {}

@Helper(self.Class.field.length)
/*member: access17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).field).length)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    ClassProto(Class).field).length))*/
void access17() {}

@Helper(self.Class.method)
/*member: access18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class).method)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).method))*/
void access18() {}

@Helper(genericFunctionAlias<int>)
/*member: typeArgumentApplications1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(genericFunctionAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunctionAlias)<int>))*/
void typeArgumentApplications1() {}

@Helper(genericFunction<int>)
/*member: typeArgumentApplications2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(genericFunction)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunction)<int>))*/
void typeArgumentApplications2() {}

@Helper(UnresolvedGenericClass<Class, Class?>)
/*member: typeArgumentApplications3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class?>))*/
void typeArgumentApplications3() {}

@Helper(LateDefaultConstructorClass<Class, Class?>.new)
/*member: typeArgumentApplications4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).new)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(LateDefaultConstructorClass<Class,Class?>).))*/
void typeArgumentApplications4() {}

@Helper(GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).named)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericClass<Class,Class?>).named))*/
void typeArgumentApplications5() {}

@Helper(GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).genericMethodAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethodAlias)<int>))*/
void typeArgumentApplications6() {}

@Helper(GenericClass.genericMethod<int>)
/*member: typeArgumentApplications7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethod)<int>))*/
void typeArgumentApplications7() {}

@Helper(self.genericFunctionAlias<int>)
/*member: typeArgumentApplications8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).genericFunctionAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunctionAlias)<int>))*/
void typeArgumentApplications8() {}

@Helper(self.genericFunction<int>)
/*member: typeArgumentApplications9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).genericFunction)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunction)<int>))*/
void typeArgumentApplications9() {}

@Helper(self.UnresolvedGenericClass<Class, Class?>)
/*member: typeArgumentApplications10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class?>))*/
void typeArgumentApplications10() {}

@Helper(self.LateDefaultConstructorClass<Class, Class?>.new)
/*member: typeArgumentApplications11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).new)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(LateDefaultConstructorClass<Class,Class?>).))*/
void typeArgumentApplications11() {}

@Helper(self.GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedAccess(
    UnresolvedInstantiate(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}?>).named)))))
resolved=UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericClass<Class,Class?>).named))*/
void typeArgumentApplications12() {}

@Helper(self.GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).genericMethodAlias)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethodAlias)<int>))*/
void typeArgumentApplications13() {}

@Helper(self.GenericClass.genericMethod<int>)
/*member: typeArgumentApplications14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).genericMethod)<{unresolved-type-annotation:UnresolvedIdentifier(int)}>)))))
resolved=UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethod)<int>))*/
void typeArgumentApplications14() {}

@Helper(LateDefaultConstructorClass())
/*member: constructorInvocations1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(LateDefaultConstructorClass)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations1() {}

@Helper(LateDefaultConstructorClass.new())
/*member: constructorInvocations2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(LateDefaultConstructorClass).new)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations2() {}

@Helper(Class.named())
/*member: constructorInvocations3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations3() {}

@Helper(self.LateDefaultConstructorClass())
/*member: constructorInvocations4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(self).LateDefaultConstructorClass)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations4() {}

@Helper(self.LateDefaultConstructorClass.new())
/*member: constructorInvocations5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).LateDefaultConstructorClass).new)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations5() {}

@Helper(self.Class.named())
/*member: constructorInvocations6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations6() {}

@Helper(LateDefaultConstructorClass<Class, Class>())
/*member: constructorInvocations7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedInstantiate(
      UnresolvedIdentifier(LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations7() {}

@Helper(GenericClass.named())
/*member: constructorInvocations8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations8() {}

@Helper(GenericClass<Class, self.Class>.named())
/*member: constructorInvocations9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}>).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void constructorInvocations9() {}

@Helper(self.GenericClass.named())
/*member: constructorInvocations10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations10() {}

@Helper(
  self.GenericClass<
    GenericClass?,
    self.GenericClass<Class, self.Class?>
  >.named(),
)
/*member: constructorInvocations11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
          UnresolvedAccess(
            UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
            UnresolvedIdentifier(self).Class)}?>)}>).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void constructorInvocations11() {}

@Helper(const LateDefaultConstructorClass())
/*member: constructorInvocations12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(LateDefaultConstructorClass)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations12() {}

@Helper(const LateDefaultConstructorClass.new())
/*member: constructorInvocations13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(LateDefaultConstructorClass).new)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations13() {}

@Helper(const Class.named())
/*member: constructorInvocations14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations14() {}

@Helper(const self.LateDefaultConstructorClass())
/*member: constructorInvocations15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(self).LateDefaultConstructorClass)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations15() {}

@Helper(const self.LateDefaultConstructorClass.new())
/*member: constructorInvocations16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).LateDefaultConstructorClass).new)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations16() {}

@Helper(const self.Class.named())
/*member: constructorInvocations17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations17() {}

@Helper(const LateDefaultConstructorClass<Class, Class>())
/*member: constructorInvocations18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedInstantiate(
      UnresolvedIdentifier(LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations18() {}

@Helper(const LateDefaultConstructorClass<Class, Class>.new())
/*member: constructorInvocations19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(LateDefaultConstructorClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>).new)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations19() {}

@Helper(const GenericClass.named())
/*member: constructorInvocations20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations20() {}

@Helper(const GenericClass<Class, self.Class>.named())
/*member: constructorInvocations21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}>).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void constructorInvocations21() {}

@Helper(const self.GenericClass.named())
/*member: constructorInvocations22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations22() {}

@Helper(
  const self.GenericClass<
    GenericClass?,
    self.GenericClass<Class, self.Class?>
  >.named(),
)
/*member: constructorInvocations23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
          UnresolvedAccess(
            UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
            UnresolvedIdentifier(self).Class)}?>)}>).named)
    ())))))
resolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void constructorInvocations23() {}

@Helper([constInt])
/*member: listLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals1() {}

@Helper([0, constInt])
/*member: listLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals2() {}

@Helper([0, 1, constInt])
/*member: listLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals3() {}

@Helper(<UnresolvedClass>[])
/*member: listLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>[]))))
resolved=ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>[])*/
void listLiterals4() {}

@Helper(<int>[constInt])
/*member: listLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals5() {}

@Helper(<int>[0, constInt])
/*member: listLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals6() {}

@Helper(<int>[0, 1, constInt])
/*member: listLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals7() {}

@Helper(<int>[0, constInt, ...[]])
/*member: listLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
    SpreadElement(...ListLiteral([]))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...ListLiteral([]))])*/
void listLiterals8() {}

@Helper(<int>[0, 1, ...constList])
/*member: listLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))])*/
void listLiterals9() {}

@Helper(<int>[0, 1, ...?constNullableList])
/*member: listLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))])*/
void listLiterals10() {}

@Helper(<int>[0, 1, if (constBool) 2])
/*member: listLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)))])*/
void listLiterals11() {}

@Helper(<int>[0, 1, if (constBool) 2 else 3])
/*member: listLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)),
      ExpressionElement(IntegerLiteral(3)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))])*/
void listLiterals12() {}

@Helper(const [constInt])
/*member: listLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals13() {}

@Helper(const [0, constInt])
/*member: listLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals14() {}

@Helper(const [0, 1, constInt])
/*member: listLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals15() {}

@Helper(const <UnresolvedClass>[])
/*member: listLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>[]))))
resolved=ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>[])*/
void listLiterals16() {}

@Helper(const <int>[constInt])
/*member: listLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals17() {}

@Helper(const <int>[0, constInt])
/*member: listLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals18() {}

@Helper(const <int>[0, 1, constInt])
/*member: listLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals19() {}

@Helper({constInt})
/*member: setLiteral1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiteral1() {}

@Helper({0, constInt})
/*member: setLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals2() {}

@Helper({0, 1, constInt})
/*member: setLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals3() {}

@Helper(<UnresolvedClass>{})
/*member: setLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{})*/
void setLiterals4() {}

@Helper(<int>{constInt})
/*member: setLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals5() {}

@Helper(<int>{0, constInt})
/*member: setLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals6() {}

@Helper(<int>{0, 1, constInt})
/*member: setLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals7() {}

@Helper(<int>{0, constInt, ...[]})
/*member: setLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
    SpreadElement(...ListLiteral([]))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...ListLiteral([]))})*/
void setLiterals8() {}

@Helper(<int>{0, 1, ...constList})
/*member: setLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))})*/
void setLiterals9() {}

@Helper(<int>{0, 1, ...?constNullableList})
/*member: setLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))})*/
void setLiterals10() {}

@Helper(<int>{0, 1, if (constBool) 2})
/*member: setLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)))})*/
void setLiterals11() {}

@Helper(<int>{0, 1, if (constBool) 2 else 3})
/*member: setLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)),
      ExpressionElement(IntegerLiteral(3)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))})*/
void setLiterals12() {}

@Helper(const {constInt})
/*member: setLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals13() {}

@Helper(const {0, constInt})
/*member: setLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals14() {}

@Helper(const {0, 1, constInt})
/*member: setLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals15() {}

@Helper(const <UnresolvedClass>{})
/*member: setLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{})*/
void setLiterals16() {}

@Helper(const <int>{constInt})
/*member: setLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals17() {}

@Helper(const <int>{0, constInt})
/*member: setLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals18() {}

@Helper(const <int>{0, 1, constInt})
/*member: setLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals19() {}

@Helper({0: constInt})
/*member: mapLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals1() {}

@Helper({0: 0, 1: constInt})
/*member: mapLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals2() {}

@Helper({0: 0, 1: 1, 2: constInt})
/*member: mapLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals3() {}

@Helper(<int, UnresolvedClass>{})
/*member: mapLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{}))))
resolved=SetOrMapLiteral(<int,{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{})*/
void mapLiterals4() {}

@Helper(<int, int>{0: constInt})
/*member: mapLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int,int>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals5() {}

@Helper(<int, int>{0: 0, 1: constInt})
/*member: mapLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals6() {}

@Helper(<int, int>{0: 0, 1: 1, 2: constInt})
/*member: mapLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals7() {}

@Helper(<int, int>{0: 0, 1: constInt, ...{}})
/*member: mapLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt))), 
    SpreadElement(...SetOrMapLiteral({}))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...SetOrMapLiteral({}))})*/
void mapLiterals8() {}

@Helper(<int, int>{
  0: 0,
  1: 1,
  ...{2: 2, 3: constInt},
})
/*member: mapLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    SpreadElement(...SetOrMapLiteral({
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)), 
      MapEntryElement(IntegerLiteral(3):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(...SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)), 
    MapEntryElement(IntegerLiteral(3):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))})*/
void mapLiterals9() {}

@Helper(<int, int>{0: 0, 1: 1, ...?constNullableMap})
/*member: mapLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableMap)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableMap)))})*/
void mapLiterals10() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2})
/*member: mapLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)))})*/
void mapLiterals11() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2 else 3: 3})
/*member: mapLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)),
      MapEntryElement(IntegerLiteral(3):IntegerLiteral(3)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)),
    MapEntryElement(IntegerLiteral(3):IntegerLiteral(3)))})*/
void mapLiterals12() {}

@Helper(const {0: constInt})
/*member: mapLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals13() {}

@Helper(const {0: 0, 1: constInt})
/*member: mapLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals14() {}

@Helper(const {0: 0, 1: 1, 2: constInt})
/*member: mapLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals15() {}

@Helper(const <UnresolvedClass, self.UnresolvedClass>{})
/*member: mapLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)},{unresolved-type-annotation:UnresolvedAccess(
    UnresolvedIdentifier(self).UnresolvedClass)}>{}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)},{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>{})*/
void mapLiterals16() {}

@Helper(const <UnresolvedGenericClass, self.UnresolvedGenericClass>{
  0: constInt,
})
/*member: mapLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedGenericClass)},{unresolved-type-annotation:UnresolvedAccess(
    UnresolvedIdentifier(self).UnresolvedGenericClass)}>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedGenericClass)},{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedGenericClass)}>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals17() {}

@Helper(const <
  UnresolvedGenericClass<int, int>,
  self.UnresolvedGenericClass<int, int>
>{0: 0, 1: constInt})
/*member: mapLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>)},{unresolved-type-annotation:UnresolvedInstantiate(
    UnresolvedAccess(
      UnresolvedIdentifier(self).UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<int,int>)},{unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<int,int>)}>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals18() {}

@Helper(const <UnresolvedGenericClass<UnresolvedClass, UnresolvedClass>, int>{
  0: 0,
  1: 1,
  2: constInt,
})
/*member: mapLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)},{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))))
resolved=SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)},{unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)}>)},int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals19() {}

@Helper((constInt,))
/*member: recordLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals1() {}

@Helper((0, constInt))
/*member: recordLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals2() {}

@Helper((a: 0, constInt))
/*member: recordLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals3() {}

@Helper((0, b: constInt))
/*member: recordLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals4() {}

@Helper(const (constInt,))
/*member: recordLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals5() {}

@Helper(const (0, constInt))
/*member: recordLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals6() {}

@Helper(const (a: 0, constInt))
/*member: recordLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals7() {}

@Helper(const (0, b: constInt))
/*member: recordLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals8() {}

@Helper((constInt))
/*member: parenthesized1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void parenthesized1() {}

@Helper((variable).length)
/*member: parenthesized2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (PropertyGet(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(variable))).length))))
resolved=PropertyGet(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(variable))).length)*/
void parenthesized2() {}

@Helper((genericFunction)<int>)
/*member: parenthesized3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (Instantiation(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(genericFunction)))<{unresolved-type-annotation:UnresolvedIdentifier(int)}>))))
resolved=Instantiation(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(genericFunction)))<int>)*/
void parenthesized3() {}

@Helper(constBool ? 0 : 1)
/*member: conditional1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ConditionalExpression(
    UnresolvedExpression(UnresolvedIdentifier(constBool))
      ? IntegerLiteral(0)
      : IntegerLiteral(1)))))
resolved=ConditionalExpression(
  UnresolvedExpression(UnresolvedIdentifier(constBool))
    ? IntegerLiteral(0)
    : IntegerLiteral(1))*/
void conditional1() {}

@Helper(
  bool.fromEnvironment(variable, defaultValue: true)
      ? const String.fromEnvironment(variable, defaultValue: 'baz')
      : int.fromEnvironment(variable, defaultValue: 42),
)
/*member: conditional2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ConditionalExpression(
    UnresolvedExpression(UnresolvedInvoke(
      UnresolvedAccess(
        UnresolvedIdentifier(bool).fromEnvironment)
      (
        UnresolvedExpression(UnresolvedIdentifier(variable)), 
        defaultValue: BooleanLiteral(true))))
      ? UnresolvedExpression(UnresolvedInvoke(
          UnresolvedAccess(
            UnresolvedIdentifier(String).fromEnvironment)
          (
            UnresolvedExpression(UnresolvedIdentifier(variable)), 
            defaultValue: StringLiteral('baz'))))
      : UnresolvedExpression(UnresolvedInvoke(
          UnresolvedAccess(
            UnresolvedIdentifier(int).fromEnvironment)
          (
            UnresolvedExpression(UnresolvedIdentifier(variable)), 
            defaultValue: IntegerLiteral(42))))))))
resolved=ConditionalExpression(
  ConstructorInvocation(
    bool.fromEnvironment(
      UnresolvedExpression(UnresolvedIdentifier(variable)), 
      defaultValue: BooleanLiteral(true)))
    ? ConstructorInvocation(
        String.fromEnvironment(
          UnresolvedExpression(UnresolvedIdentifier(variable)), 
          defaultValue: StringLiteral('baz')))
    : ConstructorInvocation(
        int.fromEnvironment(
          UnresolvedExpression(UnresolvedIdentifier(variable)), 
          defaultValue: IntegerLiteral(42))))*/
void conditional2() {}

@Helper(constNullableList ?? [0])
/*member: binary1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IfNull(
    UnresolvedExpression(UnresolvedIdentifier(constNullableList))
     ?? 
    ListLiteral([ExpressionElement(IntegerLiteral(0))])
  ))))
resolved=IfNull(
  UnresolvedExpression(UnresolvedIdentifier(constNullableList))
   ?? 
  ListLiteral([ExpressionElement(IntegerLiteral(0))])
)*/
void binary1() {}

@Helper(constBool || true)
/*member: binary2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) || BooleanLiteral(true)))))
resolved=LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) || BooleanLiteral(true))*/
void binary2() {}

@Helper(constBool && true)
/*member: binary3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) && BooleanLiteral(true)))))
resolved=LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) && BooleanLiteral(true))*/
void binary3() {}

@Helper(constInt == 1)
/*member: binary4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) == IntegerLiteral(1)))))
resolved=EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) == IntegerLiteral(1))*/
void binary4() {}

@Helper(constInt != 1)
/*member: binary5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) != IntegerLiteral(1)))))
resolved=EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) != IntegerLiteral(1))*/
void binary5() {}

@Helper(constInt >= 1)
/*member: binary6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >= IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >= IntegerLiteral(1))*/
void binary6() {}

@Helper(constInt > 1)
/*member: binary7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) > IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) > IntegerLiteral(1))*/
void binary7() {}

@Helper(constInt <= 1)
/*member: binary8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) <= IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) <= IntegerLiteral(1))*/
void binary8() {}

@Helper(constInt < 1)
/*member: binary9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) < IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) < IntegerLiteral(1))*/
void binary9() {}

@Helper(constInt | 1)
/*member: binary10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) | IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) | IntegerLiteral(1))*/
void binary10() {}

@Helper(constInt & 1)
/*member: binary11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) & IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) & IntegerLiteral(1))*/
void binary11() {}

@Helper(constInt ^ 1)
/*member: binary12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ^ IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ^ IntegerLiteral(1))*/
void binary12() {}

@Helper(constInt << 1)
/*member: binary13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) << IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) << IntegerLiteral(1))*/
void binary13() {}

@Helper(constInt >> 1)
/*member: binary14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >> IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >> IntegerLiteral(1))*/
void binary14() {}

@Helper(constInt >>> 1)
/*member: binary15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >>> IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >>> IntegerLiteral(1))*/
void binary15() {}

@Helper(constInt + 1)
/*member: binary16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) + IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) + IntegerLiteral(1))*/
void binary16() {}

void binary17() {}

@Helper(constInt - 1)
/*member: binary18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) - IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) - IntegerLiteral(1))*/
void binary18() {}

@Helper(constInt * 1)
/*member: binary19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) * IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) * IntegerLiteral(1))*/
void binary19() {}

@Helper(constInt / 1)
/*member: binary20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) / IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) / IntegerLiteral(1))*/
void binary20() {}

@Helper(constInt % 1)
/*member: binary21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) % IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) % IntegerLiteral(1))*/
void binary21() {}

@Helper(constInt ~/ 1)
/*member: binary22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ~/ IntegerLiteral(1)))))
resolved=BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ~/ IntegerLiteral(1))*/
void binary22() {}

@Helper(constInt is int)
/*member: isAs1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is {unresolved-type-annotation:UnresolvedIdentifier(int)}))))
resolved=IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is int)*/
void isAs1() {}

@Helper(constInt is! String)
/*member: isAs2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is! {unresolved-type-annotation:UnresolvedIdentifier(String)}))))
resolved=IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is! String)*/
void isAs2() {}

@Helper(constInt as int)
/*member: isAs3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (AsExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) as {unresolved-type-annotation:UnresolvedIdentifier(int)}))))
resolved=AsExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) as int)*/
void isAs3() {}

@Helper(-constInt)
/*member: unary1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(-UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=UnaryExpression(-UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void unary1() {}

@Helper(!constBool)
/*member: unary2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(!UnresolvedExpression(UnresolvedIdentifier(constBool))))))
resolved=UnaryExpression(!UnresolvedExpression(UnresolvedIdentifier(constBool)))*/
void unary2() {}

@Helper(~constInt)
/*member: unary3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnaryExpression(~UnresolvedExpression(UnresolvedIdentifier(constInt))))))
resolved=UnaryExpression(~UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void unary3() {}

@Helper(constNullableList!)
/*member: nullCheck1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (NullCheck(UnresolvedExpression(UnresolvedIdentifier(constNullableList))))))
resolved=NullCheck(UnresolvedExpression(UnresolvedIdentifier(constNullableList)))*/
void nullCheck1() {}

@Helper(constNullableString?.length)
/*member: nullAwareAccess1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (NullAwarePropertyGet(UnresolvedExpression(UnresolvedIdentifier(constNullableString))?.length))))
resolved=NullAwarePropertyGet(UnresolvedExpression(UnresolvedIdentifier(constNullableString))?.length)*/
void nullAwareAccess1() {}

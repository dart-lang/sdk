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
UnresolvedExpression(UnresolvedIdentifier(variable))*/
void metadataAnnotations1() {}

@function
/*member: metadataAnnotations2:
UnresolvedExpression(UnresolvedIdentifier(function))*/
void metadataAnnotations2() {}

@self.variable
/*member: metadataAnnotations3:
UnresolvedExpression(UnresolvedIdentifier(variable))*/
void metadataAnnotations3() {}

@self.function
/*member: metadataAnnotations4:
UnresolvedExpression(UnresolvedIdentifier(function))*/
void metadataAnnotations4() {}

@LateDefaultConstructorClass()
/*member: metadataAnnotations5:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations5() {}

@Class.named()
/*member: metadataAnnotations6:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void metadataAnnotations6() {}

@Class.named(a: 0)
/*member: metadataAnnotations7:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (a: IntegerLiteral(0))))*/
void metadataAnnotations7() {}

@Class.named(b: 1)
/*member: metadataAnnotations8:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (b: IntegerLiteral(1))))*/
void metadataAnnotations8() {}

@Class.named(a: 0, b: 1)
/*member: metadataAnnotations9:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  (
    a: IntegerLiteral(0), 
    b: IntegerLiteral(1))))*/
void metadataAnnotations9() {}

@Class.mixed(0, 1)
/*member: metadataAnnotations10:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1))))*/
void metadataAnnotations10() {}

@Class.mixed(0, 1, c: 2)
/*member: metadataAnnotations11:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    c: IntegerLiteral(2))))*/
void metadataAnnotations11() {}

@Class.mixed(0, 1, c: 2, d: 3)
/*member: metadataAnnotations12:
UnresolvedExpression(UnresolvedInvoke(
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
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).mixed)
  (
    IntegerLiteral(0), 
    IntegerLiteral(1), 
    d: IntegerLiteral(3))))*/
void metadataAnnotations13() {}

@Class.mixed(d: 3, 0, c: 2, 1)
/*member: metadataAnnotations14:
UnresolvedExpression(UnresolvedInvoke(
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
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations15() {}

@self.Class.named()
/*member: metadataAnnotations16:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void metadataAnnotations16() {}

@LateDefaultConstructorClass()
/*member: metadataAnnotations17:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void metadataAnnotations17() {}

@LateDefaultConstructorClass<Class, Class>()
/*member: metadataAnnotations18:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void metadataAnnotations18() {}

@UnresolvedGenericClass<Class, Class>()
/*member: metadataAnnotations19:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedInstantiate(
    UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class>)
  ()))*/
void metadataAnnotations19() {}

@GenericClass.named()
/*member: metadataAnnotations20:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void metadataAnnotations20() {}

@GenericClass<Class, self.Class>.named()
/*member: metadataAnnotations21:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void metadataAnnotations21() {}

@self.GenericClass.named()
/*member: metadataAnnotations22:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void metadataAnnotations22() {}

@self.GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named()
/*member: metadataAnnotations23:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void metadataAnnotations23() {}

@Helper('-$variable-')
/*member: literals1:
StringLiteral('-${UnresolvedExpression(UnresolvedIdentifier(variable))}-')*/
void literals1() {}

@Helper('a${constInt}b')
/*member: literals2:
StringLiteral('a${UnresolvedExpression(UnresolvedIdentifier(constInt))}b')*/
void literals2() {}

@Helper('a' 'b${constInt}' 'c')
/*member: literals3:
StringJuxtaposition(
    StringLiteral('a')
    StringLiteral('b${UnresolvedExpression(UnresolvedIdentifier(constInt))}')
    StringLiteral('c'))*/
void literals3() {}

@Helper(variable)
/*member: access1:
UnresolvedExpression(UnresolvedIdentifier(variable))*/
void access1() {}

@Helper(variable.length)
/*member: access2:
UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(variable).length))*/
void access2() {}

@Helper(function)
/*member: access3:
UnresolvedExpression(UnresolvedIdentifier(function))*/
void access3() {}

@Helper(UnresolvedClass)
/*member: access4:
UnresolvedExpression(UnresolvedIdentifier(UnresolvedClass))*/
void access4() {}

@Helper(LateDefaultConstructorClass.new)
/*member: access5:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(LateDefaultConstructorClass).))*/
void access5() {}

@Helper(Class.named)
/*member: access6:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).named))*/
void access6() {}

@Helper(Class.field)
/*member: access7:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).field))*/
void access7() {}

@Helper(Class.field.length)
/*member: access8:
UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    ClassProto(Class).field).length))*/
void access8() {}

@Helper(Class.method)
/*member: access9:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).method))*/
void access9() {}

@Helper(self.variable)
/*member: access10:
UnresolvedExpression(UnresolvedIdentifier(variable))*/
void access10() {}

@Helper(self.variable.length)
/*member: access11:
UnresolvedExpression(UnresolvedAccess(
  UnresolvedIdentifier(variable).length))*/
void access11() {}

@Helper(self.function)
/*member: access12:
UnresolvedExpression(UnresolvedIdentifier(function))*/
void access12() {}

@Helper(self.UnresolvedClass)
/*member: access13:
UnresolvedExpression(UnresolvedIdentifier(UnresolvedClass))*/
void access13() {}

@Helper(self.LateDefaultConstructorClass.new)
/*member: access14:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(LateDefaultConstructorClass).))*/
void access14() {}

@Helper(self.Class.named)
/*member: access15:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).named))*/
void access15() {}

@Helper(self.Class.field)
/*member: access16:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).field))*/
void access16() {}

@Helper(self.Class.field.length)
/*member: access17:
UnresolvedExpression(UnresolvedAccess(
  UnresolvedAccess(
    ClassProto(Class).field).length))*/
void access17() {}

@Helper(self.Class.method)
/*member: access18:
UnresolvedExpression(UnresolvedAccess(
  ClassProto(Class).method))*/
void access18() {}

@Helper(genericFunctionAlias<int>)
/*member: typeArgumentApplications1:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunctionAlias)<int>))*/
void typeArgumentApplications1() {}

@Helper(genericFunction<int>)
/*member: typeArgumentApplications2:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunction)<int>))*/
void typeArgumentApplications2() {}

@Helper(UnresolvedGenericClass<Class, Class?>)
/*member: typeArgumentApplications3:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class?>))*/
void typeArgumentApplications3() {}

@Helper(LateDefaultConstructorClass<Class, Class?>.new)
/*member: typeArgumentApplications4:
UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(LateDefaultConstructorClass<Class,Class?>).))*/
void typeArgumentApplications4() {}

@Helper(GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications5:
UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericClass<Class,Class?>).named))*/
void typeArgumentApplications5() {}

@Helper(GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications6:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethodAlias)<int>))*/
void typeArgumentApplications6() {}

@Helper(GenericClass.genericMethod<int>)
/*member: typeArgumentApplications7:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethod)<int>))*/
void typeArgumentApplications7() {}

@Helper(self.genericFunctionAlias<int>)
/*member: typeArgumentApplications8:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunctionAlias)<int>))*/
void typeArgumentApplications8() {}

@Helper(self.genericFunction<int>)
/*member: typeArgumentApplications9:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(genericFunction)<int>))*/
void typeArgumentApplications9() {}

@Helper(self.UnresolvedGenericClass<Class, Class?>)
/*member: typeArgumentApplications10:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<Class,Class?>))*/
void typeArgumentApplications10() {}

@Helper(self.LateDefaultConstructorClass<Class, Class?>.new)
/*member: typeArgumentApplications11:
UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(LateDefaultConstructorClass<Class,Class?>).))*/
void typeArgumentApplications11() {}

@Helper(self.GenericClass<Class, Class?>.named)
/*member: typeArgumentApplications12:
UnresolvedExpression(UnresolvedAccess(
  GenericClassProto(GenericClass<Class,Class?>).named))*/
void typeArgumentApplications12() {}

@Helper(self.GenericClass.genericMethodAlias<int>)
/*member: typeArgumentApplications13:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethodAlias)<int>))*/
void typeArgumentApplications13() {}

@Helper(self.GenericClass.genericMethod<int>)
/*member: typeArgumentApplications14:
UnresolvedExpression(UnresolvedInstantiate(
  UnresolvedAccess(
    ClassProto(GenericClass).genericMethod)<int>))*/
void typeArgumentApplications14() {}

@Helper(LateDefaultConstructorClass())
/*member: constructorInvocations1:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations1() {}

@Helper(LateDefaultConstructorClass.new())
/*member: constructorInvocations2:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations2() {}

@Helper(Class.named())
/*member: constructorInvocations3:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations3() {}

@Helper(self.LateDefaultConstructorClass())
/*member: constructorInvocations4:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations4() {}

@Helper(self.LateDefaultConstructorClass.new())
/*member: constructorInvocations5:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations5() {}

@Helper(self.Class.named())
/*member: constructorInvocations6:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations6() {}

@Helper(LateDefaultConstructorClass<Class, Class>())
/*member: constructorInvocations7:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations7() {}

@Helper(GenericClass.named())
/*member: constructorInvocations8:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations8() {}

@Helper(GenericClass<Class, self.Class>.named())
/*member: constructorInvocations9:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void constructorInvocations9() {}

@Helper(self.GenericClass.named())
/*member: constructorInvocations10:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations10() {}

@Helper(self
    .GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named())
/*member: constructorInvocations11:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void constructorInvocations11() {}

@Helper(const LateDefaultConstructorClass())
/*member: constructorInvocations12:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations12() {}

@Helper(const LateDefaultConstructorClass.new())
/*member: constructorInvocations13:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations13() {}

@Helper(const Class.named())
/*member: constructorInvocations14:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations14() {}

@Helper(const self.LateDefaultConstructorClass())
/*member: constructorInvocations15:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations15() {}

@Helper(const self.LateDefaultConstructorClass.new())
/*member: constructorInvocations16:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(LateDefaultConstructorClass).)
  ()))*/
void constructorInvocations16() {}

@Helper(const self.Class.named())
/*member: constructorInvocations17:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(Class).named)
  ()))*/
void constructorInvocations17() {}

@Helper(const LateDefaultConstructorClass<Class, Class>())
/*member: constructorInvocations18:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations18() {}

@Helper(const LateDefaultConstructorClass<Class, Class>.new())
/*member: constructorInvocations19:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(LateDefaultConstructorClass<Class,Class>).)
  ()))*/
void constructorInvocations19() {}

@Helper(const GenericClass.named())
/*member: constructorInvocations20:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations20() {}

@Helper(const GenericClass<Class, self.Class>.named())
/*member: constructorInvocations21:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<Class,Class>).named)
  ()))*/
void constructorInvocations21() {}

@Helper(const self.GenericClass.named())
/*member: constructorInvocations22:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    ClassProto(GenericClass).named)
  ()))*/
void constructorInvocations22() {}

@Helper(const self
    .GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named())
/*member: constructorInvocations23:
UnresolvedExpression(UnresolvedInvoke(
  UnresolvedAccess(
    GenericClassProto(GenericClass<GenericClass?,GenericClass<Class,Class?>>).named)
  ()))*/
void constructorInvocations23() {}

@Helper([constInt])
/*member: listLiterals1:
ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals1() {}

@Helper([0, constInt])
/*member: listLiterals2:
ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals2() {}

@Helper([0, 1, constInt])
/*member: listLiterals3:
ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals3() {}

@Helper(<UnresolvedClass>[])
/*member: listLiterals4:
ListLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>[])*/
void listLiterals4() {}

@Helper(<int>[constInt])
/*member: listLiterals5:
ListLiteral(<int>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals5() {}

@Helper(<int>[0, constInt])
/*member: listLiterals6:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals6() {}

@Helper(<int>[0, 1, constInt])
/*member: listLiterals7:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals7() {}

@Helper(<int>[0, constInt, ...[]])
/*member: listLiterals8:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...ListLiteral([]))])*/
void listLiterals8() {}

@Helper(<int>[0, 1, ...constList])
/*member: listLiterals9:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))])*/
void listLiterals9() {}

@Helper(<int>[0, 1, ...?constNullableList])
/*member: listLiterals10:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))])*/
void listLiterals10() {}

@Helper(<int>[0, 1, if (constBool) 2])
/*member: listLiterals11:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)))])*/
void listLiterals11() {}

@Helper(<int>[0, 1, if (constBool) 2 else 3])
/*member: listLiterals12:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))])*/
void listLiterals12() {}

@Helper(const [constInt])
/*member: listLiterals13:
ListLiteral([ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals13() {}

@Helper(const [0, constInt])
/*member: listLiterals14:
ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals14() {}

@Helper(const [0, 1, constInt])
/*member: listLiterals15:
ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals15() {}

@Helper(const <UnresolvedClass>[])
/*member: listLiterals16:
ListLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>[])*/
void listLiterals16() {}

@Helper(const <int>[constInt])
/*member: listLiterals17:
ListLiteral(<int>[ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals17() {}

@Helper(const <int>[0, constInt])
/*member: listLiterals18:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals18() {}

@Helper(const <int>[0, 1, constInt])
/*member: listLiterals19:
ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))])*/
void listLiterals19() {}

@Helper({constInt})
/*member: setLiteral1:
SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiteral1() {}

@Helper({0, constInt})
/*member: setLiterals2:
SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals2() {}

@Helper({0, 1, constInt})
/*member: setLiterals3:
SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals3() {}

@Helper(<UnresolvedClass>{})
/*member: setLiterals4:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>{})*/
void setLiterals4() {}

@Helper(<int>{constInt})
/*member: setLiterals5:
SetOrMapLiteral(<int>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals5() {}

@Helper(<int>{0, constInt})
/*member: setLiterals6:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals6() {}

@Helper(<int>{0, 1, constInt})
/*member: setLiterals7:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals7() {}

@Helper(<int>{0, constInt, ...[]})
/*member: setLiterals8:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...ListLiteral([]))})*/
void setLiterals8() {}

@Helper(<int>{0, 1, ...constList})
/*member: setLiterals9:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))})*/
void setLiterals9() {}

@Helper(<int>{0, 1, ...?constNullableList})
/*member: setLiterals10:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))})*/
void setLiterals10() {}

@Helper(<int>{0, 1, if (constBool) 2})
/*member: setLiterals11:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)))})*/
void setLiterals11() {}

@Helper(<int>{0, 1, if (constBool) 2 else 3})
/*member: setLiterals12:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))})*/
void setLiterals12() {}

@Helper(const {constInt})
/*member: setLiterals13:
SetOrMapLiteral({ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals13() {}

@Helper(const {0, constInt})
/*member: setLiterals14:
SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals14() {}

@Helper(const {0, 1, constInt})
/*member: setLiterals15:
SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals15() {}

@Helper(const <UnresolvedClass>{})
/*member: setLiterals16:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>{})*/
void setLiterals16() {}

@Helper(const <int>{constInt})
/*member: setLiterals17:
SetOrMapLiteral(<int>{ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals17() {}

@Helper(const <int>{0, constInt})
/*member: setLiterals18:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals18() {}

@Helper(const <int>{0, 1, constInt})
/*member: setLiterals19:
SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void setLiterals19() {}

@Helper({0: constInt})
/*member: mapLiterals1:
SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals1() {}

@Helper({0: 0, 1: constInt})
/*member: mapLiterals2:
SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals2() {}

@Helper({0: 0, 1: 1, 2: constInt})
/*member: mapLiterals3:
SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals3() {}

@Helper(<int, UnresolvedClass>{})
/*member: mapLiterals4:
SetOrMapLiteral(<int,<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>{})*/
void mapLiterals4() {}

@Helper(<int, int>{0: constInt})
/*member: mapLiterals5:
SetOrMapLiteral(<int,int>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals5() {}

@Helper(<int, int>{0: 0, 1: constInt})
/*member: mapLiterals6:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals6() {}

@Helper(<int, int>{0: 0, 1: 1, 2: constInt})
/*member: mapLiterals7:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals7() {}

@Helper(<int, int>{0: 0, 1: constInt, ...{}})
/*member: mapLiterals8:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt))), 
  SpreadElement(...SetOrMapLiteral({}))})*/
void mapLiterals8() {}

@Helper(<int, int>{
  0: 0,
  1: 1,
  ...{2: 2, 3: constInt}
})
/*member: mapLiterals9:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(...SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)), 
    MapEntryElement(IntegerLiteral(3):UnresolvedExpression(UnresolvedIdentifier(constInt)))}))})*/
void mapLiterals9() {}

@Helper(<int, int>{0: 0, 1: 1, ...?constNullableMap})
/*member: mapLiterals10:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableMap)))})*/
void mapLiterals10() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2})
/*member: mapLiterals11:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)))})*/
void mapLiterals11() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2 else 3: 3})
/*member: mapLiterals12:
SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    UnresolvedExpression(UnresolvedIdentifier(constBool)),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)),
    MapEntryElement(IntegerLiteral(3):IntegerLiteral(3)))})*/
void mapLiterals12() {}

@Helper(const {0: constInt})
/*member: mapLiterals13:
SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals13() {}

@Helper(const {0: 0, 1: constInt})
/*member: mapLiterals14:
SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals14() {}

@Helper(const {0: 0, 1: 1, 2: constInt})
/*member: mapLiterals15:
SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals15() {}

@Helper(const <UnresolvedClass, self.UnresolvedClass>{})
/*member: mapLiterals16:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass),<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>{})*/
void mapLiterals16() {}

@Helper(
    const <UnresolvedGenericClass, self.UnresolvedGenericClass>{0: constInt})
/*member: mapLiterals17:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedGenericClass),<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedGenericClass)>{MapEntryElement(IntegerLiteral(0):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals17() {}

@Helper(const <UnresolvedGenericClass<int, int>,
    self.UnresolvedGenericClass<int, int>>{0: 0, 1: constInt})
/*member: mapLiterals18:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<int,int>),<<unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<int,int>)>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals18() {}

@Helper(const <UnresolvedGenericClass<UnresolvedClass, UnresolvedClass>, int>{
  0: 0,
  1: 1,
  2: constInt
})
/*member: mapLiterals19:
SetOrMapLiteral(<<<unresolved-type-annotation:UnresolvedInstantiate(
  UnresolvedIdentifier(UnresolvedGenericClass)<<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass),<<unresolved-type-annotation:UnresolvedIdentifier(UnresolvedClass)>),int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):UnresolvedExpression(UnresolvedIdentifier(constInt)))})*/
void mapLiterals19() {}

@Helper((constInt,))
/*member: recordLiterals1:
RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals1() {}

@Helper((0, constInt))
/*member: recordLiterals2:
RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals2() {}

@Helper((a: 0, constInt))
/*member: recordLiterals3:
RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals3() {}

@Helper((0, b: constInt))
/*member: recordLiterals4:
RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals4() {}

@Helper(const (constInt,))
/*member: recordLiterals5:
RecordLiteral(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals5() {}

@Helper(const (0, constInt))
/*member: recordLiterals6:
RecordLiteral(IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals6() {}

@Helper(const (a: 0, constInt))
/*member: recordLiterals7:
RecordLiteral(a: IntegerLiteral(0), UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals7() {}

@Helper(const (0, b: constInt))
/*member: recordLiterals8:
RecordLiteral(IntegerLiteral(0), b: UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void recordLiterals8() {}

@Helper((constInt))
/*member: parenthesized1:
ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void parenthesized1() {}

@Helper((variable).length)
/*member: parenthesized2:
PropertyGet(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(variable))).length)*/
void parenthesized2() {}

@Helper((genericFunction)<int>)
/*member: parenthesized3:
Instantiation(ParenthesizedExpression(UnresolvedExpression(UnresolvedIdentifier(genericFunction)))<int>)*/
void parenthesized3() {}

@Helper(constBool ? 0 : 1)
/*member: conditional1:
ConditionalExpression(
  UnresolvedExpression(UnresolvedIdentifier(constBool))
    ? IntegerLiteral(0)
    : IntegerLiteral(1))*/
void conditional1() {}

@Helper(bool.fromEnvironment(variable, defaultValue: true)
    ? const String.fromEnvironment(variable, defaultValue: 'baz')
    : int.fromEnvironment(variable, defaultValue: 42))
/*member: conditional2:
ConditionalExpression(
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
IfNull(
  UnresolvedExpression(UnresolvedIdentifier(constNullableList))
   ?? 
  ListLiteral([ExpressionElement(IntegerLiteral(0))])
)*/
void binary1() {}

@Helper(constBool || true)
/*member: binary2:
LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) || BooleanLiteral(true))*/
void binary2() {}

@Helper(constBool && true)
/*member: binary3:
LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) && BooleanLiteral(true))*/
void binary3() {}

@Helper(constInt == 1)
/*member: binary4:
EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) == IntegerLiteral(1))*/
void binary4() {}

@Helper(constInt != 1)
/*member: binary5:
EqualityExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) != IntegerLiteral(1))*/
void binary5() {}

@Helper(constInt >= 1)
/*member: binary6:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >= IntegerLiteral(1))*/
void binary6() {}

@Helper(constInt > 1)
/*member: binary7:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) > IntegerLiteral(1))*/
void binary7() {}

@Helper(constInt <= 1)
/*member: binary8:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) <= IntegerLiteral(1))*/
void binary8() {}

@Helper(constInt < 1)
/*member: binary9:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) < IntegerLiteral(1))*/
void binary9() {}

@Helper(constInt | 1)
/*member: binary10:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) | IntegerLiteral(1))*/
void binary10() {}

@Helper(constInt & 1)
/*member: binary11:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) & IntegerLiteral(1))*/
void binary11() {}

@Helper(constInt ^ 1)
/*member: binary12:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ^ IntegerLiteral(1))*/
void binary12() {}

@Helper(constInt << 1)
/*member: binary13:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) << IntegerLiteral(1))*/
void binary13() {}

@Helper(constInt >> 1)
/*member: binary14:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >> IntegerLiteral(1))*/
void binary14() {}

@Helper(constInt >>> 1)
/*member: binary15:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) >>> IntegerLiteral(1))*/
void binary15() {}

@Helper(constInt + 1)
/*member: binary16:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) + IntegerLiteral(1))*/
void binary16() {}

void binary17() {}

@Helper(constInt - 1)
/*member: binary18:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) - IntegerLiteral(1))*/
void binary18() {}

@Helper(constInt * 1)
/*member: binary19:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) * IntegerLiteral(1))*/
void binary19() {}

@Helper(constInt / 1)
/*member: binary20:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) / IntegerLiteral(1))*/
void binary20() {}

@Helper(constInt % 1)
/*member: binary21:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) % IntegerLiteral(1))*/
void binary21() {}

@Helper(constInt ~/ 1)
/*member: binary22:
BinaryExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) ~/ IntegerLiteral(1))*/
void binary22() {}

@Helper(constInt is int)
/*member: isAs1:
IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is int)*/
void isAs1() {}

@Helper(constInt is! String)
/*member: isAs2:
IsTest(UnresolvedExpression(UnresolvedIdentifier(constInt)) is! String)*/
void isAs2() {}

@Helper(constInt as int)
/*member: isAs3:
AsExpression(UnresolvedExpression(UnresolvedIdentifier(constInt)) as int)*/
void isAs3() {}

@Helper(-constInt)
/*member: unary1:
UnaryExpression(-UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void unary1() {}

@Helper(!constBool)
/*member: unary2:
UnaryExpression(!UnresolvedExpression(UnresolvedIdentifier(constBool)))*/
void unary2() {}

@Helper(~constInt)
/*member: unary3:
UnaryExpression(~UnresolvedExpression(UnresolvedIdentifier(constInt)))*/
void unary3() {}

@Helper(constNullableList!)
/*member: nullCheck1:
NullCheck(UnresolvedExpression(UnresolvedIdentifier(constNullableList)))*/
void nullCheck1() {}

@Helper(constNullableString?.length)
/*member: nullAwareAccess1:
NullAwarePropertyGet(UnresolvedExpression(UnresolvedIdentifier(constNullableString))?.length)*/
void nullAwareAccess1() {}

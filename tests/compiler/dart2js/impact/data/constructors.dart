// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  testConstRedirectingFactoryInvoke(0),
  testConstRedirectingFactoryInvokeGeneric(0),
  testConstRedirectingFactoryInvokeGenericDynamic(0),
  testConstRedirectingFactoryInvokeGenericRaw(0),
  testConstructorInvoke(0),
  testConstructorInvokeGeneric(0),
  testConstructorInvokeGenericDynamic(0),
  testConstructorInvokeGenericRaw(0),
  testFactoryConstructor(0),
  testFactoryInvoke(0),
  testFactoryInvokeGeneric(0),
  testFactoryInvokeGenericDynamic(0),
  testFactoryInvokeGenericRaw(0),
  testImplicitConstructor(0),
  testRedirectingFactoryInvoke(0),
  testRedirectingFactoryInvokeGeneric(0),
  testRedirectingFactoryInvokeGenericDynamic(0),
  testRedirectingFactoryInvokeGenericRaw(0)]
*/
main() {
  testConstructorInvoke();
  testConstructorInvokeGeneric();
  testConstructorInvokeGenericRaw();
  testConstructorInvokeGenericDynamic();
  testFactoryInvoke();
  testFactoryInvokeGeneric();
  testFactoryInvokeGenericRaw();
  testFactoryInvokeGenericDynamic();
  testRedirectingFactoryInvoke();
  testRedirectingFactoryInvokeGeneric();
  testRedirectingFactoryInvokeGenericRaw();
  testRedirectingFactoryInvokeGenericDynamic();
  testConstRedirectingFactoryInvoke();
  testConstRedirectingFactoryInvokeGeneric();
  testConstRedirectingFactoryInvokeGenericRaw();
  testConstRedirectingFactoryInvokeGenericDynamic();
  testImplicitConstructor();
  testFactoryConstructor();
}

/*element: testConstructorInvoke:static=[Class.generative(0)]*/
testConstructorInvoke() {
  new Class.generative();
}

/*element: testConstructorInvokeGeneric:static=[GenericClass.generative(0),assertIsSubtype,throwTypeError]*/
testConstructorInvokeGeneric() {
  new GenericClass<int, String>.generative();
}

/*element: testConstructorInvokeGenericRaw:static=[GenericClass.generative(0)]*/
testConstructorInvokeGenericRaw() {
  new GenericClass.generative();
}

/*element: testConstructorInvokeGenericDynamic:static=[GenericClass.generative(0)]*/
testConstructorInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.generative();
}

/*element: testFactoryInvoke:static=[Class.fact(0)]*/
testFactoryInvoke() {
  new Class.fact();
}

/*element: testFactoryInvokeGeneric:static=[GenericClass.fact(0),assertIsSubtype,throwTypeError]*/
testFactoryInvokeGeneric() {
  new GenericClass<int, String>.fact();
}

/*element: testFactoryInvokeGenericRaw:static=[GenericClass.fact(0)]*/
testFactoryInvokeGenericRaw() {
  new GenericClass.fact();
}

/*element: testFactoryInvokeGenericDynamic:static=[GenericClass.fact(0)]*/
testFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.fact();
}

/*element: testRedirectingFactoryInvoke:static=[Class.generative(0)]*/
testRedirectingFactoryInvoke() {
  new Class.redirect();
}

/*element: testRedirectingFactoryInvokeGeneric:static=[GenericClass.generative(0),assertIsSubtype,throwTypeError]*/
testRedirectingFactoryInvokeGeneric() {
  new GenericClass<int, String>.redirect();
}

/*element: testRedirectingFactoryInvokeGenericRaw:static=[GenericClass.generative(0)]*/
testRedirectingFactoryInvokeGenericRaw() {
  new GenericClass.redirect();
}

/*element: testRedirectingFactoryInvokeGenericDynamic:static=[GenericClass.generative(0)]*/
testRedirectingFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.redirect();
}

/*element: testConstRedirectingFactoryInvoke:static=[Class.generative(0)]*/
testConstRedirectingFactoryInvoke() {
  const Class.redirect();
}

/*element: testConstRedirectingFactoryInvokeGeneric:static=[GenericClass.generative(0),assertIsSubtype,throwTypeError]*/
testConstRedirectingFactoryInvokeGeneric() {
  const GenericClass<int, String>.redirect();
}

/*element: testConstRedirectingFactoryInvokeGenericRaw:static=[GenericClass.generative(0)]*/
testConstRedirectingFactoryInvokeGenericRaw() {
  const GenericClass.redirect();
}

/*element: testConstRedirectingFactoryInvokeGenericDynamic:static=[GenericClass.generative(0)]*/
testConstRedirectingFactoryInvokeGenericDynamic() {
  const GenericClass<dynamic, dynamic>.redirect();
}

/*element: ClassImplicitConstructor.:static=[Object.(0)]*/
class ClassImplicitConstructor {}

/*element: testImplicitConstructor:static=[ClassImplicitConstructor.(0)]*/
testImplicitConstructor() => new ClassImplicitConstructor();

class ClassFactoryConstructor {
  /*kernel.element: ClassFactoryConstructor.:type=[check:ClassFactoryConstructor,inst:JSNull]*/
  /*strong.element: ClassFactoryConstructor.:type=[inst:JSNull]*/
  factory ClassFactoryConstructor() => null;
}

/*element: testFactoryConstructor:static=[ClassFactoryConstructor.(0)]*/
testFactoryConstructor() => new ClassFactoryConstructor();

class Class {
  /*element: Class.generative:static=[Object.(0)]*/
  const Class.generative();

  /*kernel.element: Class.fact:type=[check:Class,inst:JSNull]*/
  /*strong.element: Class.fact:type=[inst:JSNull]*/
  factory Class.fact() => null;

  const factory Class.redirect() = Class.generative;
}

class GenericClass<X, Y> {
  /*element: GenericClass.generative:static=[Object.(0)]*/
  const GenericClass.generative();

  /*kernel.element: GenericClass.fact:type=[check:GenericClass<GenericClass.X,GenericClass.Y>,inst:JSNull]*/
  /*strong.element: GenericClass.fact:type=[inst:JSBool,inst:JSNull,param:Object]*/
  factory GenericClass.fact() => null;

  const factory GenericClass.redirect() = GenericClass<X, Y>.generative;
}

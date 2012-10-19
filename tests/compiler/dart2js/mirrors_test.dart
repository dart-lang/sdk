// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../pkg/dartdoc/lib/mirrors.dart");
#import("../../../pkg/dartdoc/lib/mirrors_util.dart");

#import('dart:io');

int count(Iterable iterable) {
  var count = 0;
  for (var element in iterable) {
    count++;
  }
  return count;
}

bool containsType(TypeMirror expected, Iterable<TypeMirror> iterable) {
  for (var element in iterable) {
    if (element.declaration == expected.declaration) {
      return true;
    }
  }
  return false;
}

Mirror findMirror(List<Mirror> list, String name) {
  for (Mirror mirror in list) {
    if (mirror.simpleName == name) {
      return mirror;
    }
  }
  return null;
}

main() {
  var scriptPath = new Path.fromNative(new Options().script);
  var dirPath = scriptPath.directoryPath;
  var libPath = dirPath.join(new Path.fromNative('../../../'));
  var inputPath = dirPath.join(new Path.fromNative('mirrors_helper.dart'));
  var compilation = new Compilation.library([inputPath], libPath);
  Expect.isNotNull(compilation, "No compilation created");

  var mirrors = compilation.mirrors;
  Expect.isNotNull(mirrors, "No mirror system returned from compilation");

  var libraries = mirrors.libraries;
  Expect.isNotNull(libraries, "No libraries map returned");
  Expect.isFalse(libraries.isEmpty(), "Empty libraries map returned");

  var helperLibrary = libraries["mirrors_helper"];
  Expect.isNotNull(helperLibrary, "Library 'mirrors_helper' not found");
  Expect.stringEquals("mirrors_helper", helperLibrary.simpleName,
    "Unexpected library simple name");
  Expect.stringEquals("mirrors_helper", helperLibrary.qualifiedName,
    "Unexpected library qualified name");

  var types = helperLibrary.types;
  Expect.isNotNull(types, "No types map returned");
  Expect.isFalse(types.isEmpty(), "Empty types map returned");

  testFoo(mirrors, helperLibrary, types);
  testBar(mirrors, helperLibrary, types);
  testBaz(mirrors, helperLibrary, types);
  // TODO(johnniwinther): Add test of class [Boz] and typedef [Func].
  // TODO(johnniwinther): Add tests of type argument substitution, which
  // is not currently implemented in dart2js.
  // TODO(johnniwinther): Add tests of Location and Source.
  testPrivate(mirrors, helperLibrary, types);
}

// Testing class Foo:
//
// class Foo {
//
// }
void testFoo(MirrorSystem system, LibraryMirror helperLibrary,
             Map<String,TypeMirror> types) {
  var fooClass = types["Foo"];
  Expect.isNotNull(fooClass, "Type 'Foo' not found");
  Expect.isTrue(fooClass is InterfaceMirror,
                "Unexpected mirror type returned");
  Expect.stringEquals("Foo", fooClass.simpleName,
                      "Unexpected type simple name");
  Expect.stringEquals("mirrors_helper.Foo", fooClass.qualifiedName,
                      "Unexpected type qualified name");

  Expect.equals(helperLibrary, fooClass.library,
                "Unexpected library returned from type");

  Expect.isFalse(fooClass.isObject, "Class is Object");
  Expect.isFalse(fooClass.isDynamic, "Class is Dynamic");
  Expect.isFalse(fooClass.isVoid, "Class is void");
  Expect.isFalse(fooClass.isTypeVariable, "Class is a type variable");
  Expect.isFalse(fooClass.isTypedef, "Class is a typedef");
  Expect.isFalse(fooClass.isFunction, "Class is a function");

  Expect.isTrue(fooClass.isDeclaration, "Class is not declaration");
  Expect.equals(fooClass, fooClass.declaration,
                "Class is not its declaration");

  Expect.isTrue(fooClass.isClass, "Class is not class");
  Expect.isFalse(fooClass.isInterface, "Class is interface");
  Expect.isFalse(fooClass.isPrivate, "Class is private");

  var objectType = fooClass.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(objectType.isObject, "Object is not Object");
  Expect.isFalse(objectType.isDeclaration, "Object type is declaration");
  Expect.isTrue(containsType(fooClass,
                             computeSubdeclarations(objectType)),
                "Class is not subclass of superclass");

  var fooInterfaces = fooClass.interfaces;
  Expect.isNotNull(fooInterfaces, "Interfaces map is null");
  Expect.isTrue(fooInterfaces.isEmpty(), "Interfaces map is not empty");

  var fooSubdeclarations = computeSubdeclarations(fooClass);
  Expect.equals(1, count(fooSubdeclarations), "Unexpected subtype count");
  for (var fooSubdeclaration in fooSubdeclarations) {
    Expect.equals(fooClass, fooSubdeclaration.superclass.declaration,
                  "Class is not superclass of subclass");
  }

  Expect.throws(() => fooClass.typeArguments,
                (exception) => true,
                "Class has type arguments");
  var fooClassTypeVariables = fooClass.typeVariables;
  Expect.isNotNull(fooClassTypeVariables, "Type variable list is null");
  Expect.isTrue(fooClassTypeVariables.isEmpty(),
                "Type variable list is not empty");

  Expect.isNull(fooClass.defaultType, "Class has default type");

  var fooClassMembers = fooClass.declaredMembers;
  Expect.isNotNull(fooClassMembers, "Declared members map is null");
  Expect.isTrue(fooClassMembers.isEmpty(), "Declared members map is unempty");

  var fooClassConstructors = fooClass.constructors;
  Expect.isNotNull(fooClassConstructors, "Constructors map is null");
  Expect.isTrue(fooClassConstructors.isEmpty(),
                "Constructors map is unempty");
}

// Testing interface Bar:
//
// interface Bar<E> {
//
// }
void testBar(MirrorSystem system, LibraryMirror helperLibrary,
             Map<String,TypeMirror> types) {
  var barInterface = types["Bar"];
  Expect.isNotNull(barInterface, "Type 'Bar' not found");
  Expect.isTrue(barInterface is InterfaceMirror,
               "Unexpected mirror type returned");
  Expect.stringEquals("Bar", barInterface.simpleName,
                      "Unexpected type simple name");
  Expect.stringEquals("mirrors_helper.Bar", barInterface.qualifiedName,
                      "Unexpected type qualified name");

  Expect.equals(helperLibrary, barInterface.library,
                "Unexpected library returned from type");

  Expect.isFalse(barInterface.isObject, "Interface is Object");
  Expect.isFalse(barInterface.isDynamic, "Interface is Dynamic");
  Expect.isFalse(barInterface.isVoid, "Interface is void");
  Expect.isFalse(barInterface.isTypeVariable, "Interface is a type variable");
  Expect.isFalse(barInterface.isTypedef, "Interface is a typedef");
  Expect.isFalse(barInterface.isFunction, "Interface is a function");

  Expect.isTrue(barInterface.isDeclaration, "Interface is not declaration");
  Expect.equals(barInterface, barInterface.declaration,
                "Interface is not its declaration");

  Expect.isFalse(barInterface.isClass, "Interface is class");
  Expect.isTrue(barInterface.isInterface, "Interface is not interface");
  Expect.isFalse(barInterface.isPrivate, "Interface is private");

  var objectType = barInterface.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(objectType.isObject, "Object is not Object");
  Expect.isFalse(objectType.isDeclaration, "Object type is declaration");
  Expect.isTrue(containsType(barInterface,
                             computeSubdeclarations(objectType)),
                "Class is not subclass of superclass");

  var barInterfaces = barInterface.interfaces;
  Expect.isNotNull(barInterfaces, "Interfaces map is null");
  Expect.isTrue(barInterfaces.isEmpty(), "Interfaces map is not empty");

  var barSubdeclarations = computeSubdeclarations(barInterface);
  Expect.equals(1, count(barSubdeclarations), "Unexpected subtype count");
  for (var barSubdeclaration in barSubdeclarations) {
    Expect.isTrue(containsType(barInterface,
                               barSubdeclaration.interfaces),
                  "Interface is not superinterface of subclass");
  }

  Expect.throws(() => barInterface.typeArguments,
              (exception) => true,
              "Interface has type arguments");
  var barInterfaceTypeVariables = barInterface.typeVariables;
  Expect.isNotNull(barInterfaceTypeVariables, "Type variable list is null");
  Expect.isFalse(barInterfaceTypeVariables.isEmpty(),
                 "Type variable list is empty");
  Expect.equals(barInterfaceTypeVariables.length, 1,
                "Unexpected number of type variables");

  var barE = barInterfaceTypeVariables[0];
  Expect.isNotNull(barE, "Type variable is null");
  Expect.isTrue(barE.isTypeVariable, "Type variable is not type variable");

  Expect.isNull(barInterface.defaultType, "Interface has default type");

  var barInterfaceMembers = barInterface.declaredMembers;
  Expect.isNotNull(barInterfaceMembers, "Declared members map is null");
  Expect.isTrue(barInterfaceMembers.isEmpty(),
                "Declared members map is unempty");

  var barInterfaceConstructors = barInterface.constructors;
  Expect.isNotNull(barInterfaceConstructors, "Constructors map is null");
  Expect.isTrue(barInterfaceConstructors.isEmpty(),
                "Constructors map is unempty");
}

// Testing class Baz:
//
// class Baz<E,F extends Foo> implements Bar<E> {
//   Baz();
//   const Baz.named();
//   factory Baz.factory() => new Baz<E,F>();
//
//   static method1(e) {}
//   void method2(E e, [F f = null]) {}
//   Baz<E,F> method3(E func1(F f), Func<E,F> func2) => null;
//
//   bool operator==(Object other) => false;
//   int operator -() => 0;
// }
void testBaz(MirrorSystem system, LibraryMirror helperLibrary,
             Map<String,TypeMirror> types) {
  var bazClass = types["Baz"];
  Expect.isNotNull(bazClass, "Type 'Baz' not found");
  Expect.isTrue(bazClass is InterfaceMirror,
                "Unexpected mirror type returned");
  Expect.stringEquals("Baz", bazClass.simpleName,
                      "Unexpected type simple name");
  Expect.stringEquals("mirrors_helper.Baz", bazClass.qualifiedName,
                      "Unexpected type qualified name");

  Expect.equals(helperLibrary, bazClass.library,
                "Unexpected library returned from type");

  Expect.isFalse(bazClass.isObject, "Class is Object");
  Expect.isFalse(bazClass.isDynamic, "Class is Dynamic");
  Expect.isFalse(bazClass.isVoid, "Class is void");
  Expect.isFalse(bazClass.isTypeVariable, "Class is a type variable");
  Expect.isFalse(bazClass.isTypedef, "Class is a typedef");
  Expect.isFalse(bazClass.isFunction, "Class is a function");

  Expect.isTrue(bazClass.isDeclaration, "Class is not declaration");
  Expect.equals(bazClass, bazClass.declaration,
                "Class is not its declaration");

  Expect.isTrue(bazClass.isClass, "Class is not class");
  Expect.isFalse(bazClass.isInterface, "Class is interface");
  Expect.isFalse(bazClass.isPrivate, "Class is private");

  var objectType = bazClass.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(objectType.isObject, "Object is not Object");
  Expect.isFalse(objectType.isDeclaration, "Object type is declaration");
  Expect.isTrue(containsType(bazClass,
                             computeSubdeclarations(objectType)),
                "Class is not subclass of superclass");

  var bazInterfaces = bazClass.interfaces;
  Expect.isNotNull(bazInterfaces, "Interfaces map is null");
  Expect.isTrue(!bazInterfaces.isEmpty(), "Interfaces map is empty");
  for (var bazInterface in bazInterfaces) {
    Expect.isTrue(containsType(bazClass,
                               computeSubdeclarations(objectType)),
                  "Class is not subclass of superinterface");
  }

  var bazSubdeclarations = computeSubdeclarations(bazClass);
  Expect.equals(0, count(bazSubdeclarations), "Unexpected subtype count");

  var barInterface = findMirror(bazInterfaces, "Bar");
  Expect.isNotNull(barInterface, "Interface bar is missing");
  Expect.isFalse(barInterface.isDeclaration, "Interface type is declaration");
  var barInterfaceTypeArguments = barInterface.typeArguments;
  Expect.isNotNull(barInterfaceTypeArguments, "Type arguments are missing");
  Expect.equals(1, barInterfaceTypeArguments.length,
                "Type arguments is empty");

  Expect.throws(() => bazClass.typeArguments,
                (exception) => true,
                "Class has type arguments");
  var bazClassTypeVariables = bazClass.typeVariables;
  Expect.isNotNull(bazClassTypeVariables, "Type variable list is null");
  Expect.equals(2, bazClassTypeVariables.length,
                "Type variable list is not empty");

  var bazE = bazClassTypeVariables[0];
  Expect.isNotNull(bazE, "Type variable is null");
  Expect.stringEquals('E', bazE.simpleName, "Unexpected simpleName");
  Expect.stringEquals('mirrors_helper.Baz.E', bazE.qualifiedName,
                      "Unexpected qualifiedName");
  Expect.equals(bazClass, bazE.declarer,
                "Unexpected type variable declarer");
  var bazEbound = bazE.bound;
  Expect.isNotNull(bazEbound, "Missing type variable bound");
  Expect.isFalse(bazEbound.isDeclaration, "Bound is declaration");
  Expect.isTrue(bazEbound.isObject, "Bound is not object");

  var bazF = bazClassTypeVariables[1];
  Expect.isNotNull(bazF, "Type variable is null");
  Expect.stringEquals('F', bazF.simpleName, "Unexpected simpleName");
  Expect.stringEquals('mirrors_helper.Baz.F', bazF.qualifiedName,
                      "Unexpected qualifiedName");
  Expect.equals(bazClass, bazF.declarer);
  var bazFbound = bazF.bound;
  Expect.isNotNull(bazFbound, "Missing type variable bound");
  Expect.isFalse(bazFbound.isDeclaration, "Bound is declaration");
  Expect.stringEquals("mirrors_helper.Foo", bazFbound.qualifiedName,
                      "Bound is not Foo");

  Expect.isNull(bazClass.defaultType, "Class has default type");

  var bazClassMembers = bazClass.declaredMembers;
  Expect.isNotNull(bazClassMembers, "Declared members map is null");
  Expect.equals(8, bazClassMembers.length,
                "Unexpected number of declared members");

  ////////////////////////////////////////////////////////////////////////////
  // static method1(e) {}
  ////////////////////////////////////////////////////////////////////////////
  var method1 = bazClassMembers["method1"];
  Expect.isNotNull(method1, "method1 not found");
  Expect.stringEquals('method1', method1.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('mirrors_helper.Baz.method1', method1.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(method1.surroundingDeclaration, bazClass,
                "Unexpected surrounding declaration");
  Expect.isFalse(method1.isTopLevel, "Method is top level");
  Expect.isFalse(method1.isConstructor, "Method is constructor");
  Expect.isFalse(method1.isField, "Method is field");
  Expect.isTrue(method1.isMethod, "Method is not method");
  Expect.isFalse(method1.isPrivate, "Method is private");
  Expect.isTrue(method1.isStatic, "Method is not static");
  Expect.isTrue(method1 is MethodMirror, "Method is not MethodMirror");
  Expect.isFalse(method1.isConst, "Method is const");
  Expect.isFalse(method1.isFactory, "Method is factory");
  Expect.isNull(method1.constructorName,
                "Method constructorName is non-null");
  Expect.isFalse(method1.isGetter, "Method is getter");
  Expect.isFalse(method1.isSetter, "Method is setter");
  Expect.isFalse(method1.isOperator, "Method is operator");
  Expect.isNull(method1.operatorName,
                "Method operatorName is non-null");

  var dynamicType = method1.returnType;
  Expect.isNotNull(dynamicType, "Return type was null");
  Expect.isFalse(dynamicType.isObject, "Dynamic is Object");
  Expect.isTrue(dynamicType.isDynamic, "Dynamic is not Dynamic");
  Expect.isFalse(dynamicType.isVoid, "Dynamic is void");
  Expect.isFalse(dynamicType.isTypeVariable, "Dynamic is a type variable");
  Expect.isFalse(dynamicType.isTypedef, "Dynamic is a typedef");
  Expect.isFalse(dynamicType.isFunction, "Dynamic is a function");

  var method1Parameters = method1.parameters;
  Expect.isNotNull(method1Parameters, "Method parameters is null");
  Expect.equals(1, method1Parameters.length, "Unexpected parameter count");
  var method1Parameter1 = method1Parameters[0];
  Expect.isNotNull(method1Parameter1, "Parameter is null");
  Expect.equals(dynamicType, method1Parameter1.type);
  Expect.stringEquals("e", method1Parameter1.simpleName,
                      "Unexpected parameter simpleName");
  Expect.stringEquals("mirrors_helper.Baz.method1#e",
                      method1Parameter1.qualifiedName,
                      "Unexpected parameter qualifiedName");
  Expect.isFalse(method1Parameter1.hasDefaultValue,
    "Parameter has default value");
  Expect.isNull(method1Parameter1.defaultValue,
    "Parameter default value is non-null");
  Expect.isFalse(method1Parameter1.isOptional, "Parameter is optional");

  ////////////////////////////////////////////////////////////////////////////
  // static void method2(E e, [F f = null]) {}
  ////////////////////////////////////////////////////////////////////////////
  var method2 = bazClassMembers["method2"];
  Expect.isNotNull(method2, "method2 not found");
  Expect.stringEquals('method2', method2.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('mirrors_helper.Baz.method2', method2.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(method2.surroundingDeclaration, bazClass,
                "Unexpected surrounding declaration");
  Expect.isFalse(method2.isTopLevel, "Method is top level");
  Expect.isFalse(method2.isConstructor, "Method is constructor");
  Expect.isFalse(method2.isField, "Method is field");
  Expect.isTrue(method2.isMethod, "Method is not method");
  Expect.isFalse(method2.isPrivate, "Method is private");
  Expect.isFalse(method2.isStatic, "Method is static");
  Expect.isTrue(method2 is MethodMirror, "Method is not MethodMirror");
  Expect.isFalse(method2.isConst, "Method is const");
  Expect.isFalse(method2.isFactory, "Method is factory");
  Expect.isNull(method2.constructorName,
                "Method constructorName is non-null");
  Expect.isFalse(method2.isGetter, "Method is getter");
  Expect.isFalse(method2.isSetter, "Method is setter");
  Expect.isFalse(method2.isOperator, "Method is operator");
  Expect.isNull(method2.operatorName,
                "Method operatorName is non-null");

  var voidType = method2.returnType;
  Expect.isNotNull(voidType, "Return type was null");
  Expect.isFalse(voidType.isObject, "void is Object");
  Expect.isFalse(voidType.isDynamic, "void is Dynamic");
  Expect.isTrue(voidType.isVoid, "void is not void");
  Expect.isFalse(voidType.isTypeVariable, "void is a type variable");
  Expect.isFalse(voidType.isTypedef, "void is a typedef");
  Expect.isFalse(voidType.isFunction, "void is a function");

  var method2Parameters = method2.parameters;
  Expect.isNotNull(method2Parameters, "Method parameters is null");
  Expect.equals(2, method2Parameters.length, "Unexpected parameter count");
  var method2Parameter1 = method2Parameters[0];
  Expect.isNotNull(method2Parameter1, "Parameter is null");
  Expect.equals(bazE, method2Parameter1.type);
  Expect.stringEquals("e", method2Parameter1.simpleName,
                      "Unexpected parameter simpleName");
  Expect.stringEquals("mirrors_helper.Baz.method2#e",
                      method2Parameter1.qualifiedName,
                      "Unexpected parameter qualifiedName");
  Expect.isFalse(method2Parameter1.hasDefaultValue,
                      "Parameter has default value");
  Expect.isNull(method2Parameter1.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method2Parameter1.isOptional, "Parameter is optional");
  var method2Parameter2 = method2Parameters[1];
  Expect.isNotNull(method2Parameter2, "Parameter is null");
  Expect.equals(bazF, method2Parameter2.type);
  Expect.stringEquals("f", method2Parameter2.simpleName,
                      "Unexpected parameter simpleName");
  Expect.stringEquals("mirrors_helper.Baz.method2#f",
                      method2Parameter2.qualifiedName,
                      "Unexpected parameter qualifiedName");
  Expect.isTrue(method2Parameter2.hasDefaultValue,
                 "Parameter has default value");
  Expect.stringEquals("null", method2Parameter2.defaultValue,
                      "Parameter default value is non-null");
  Expect.isTrue(method2Parameter2.isOptional, "Parameter is not optional");

  ////////////////////////////////////////////////////////////////////////////
  // Baz<E,F> method3(E func1(F f), Func<E,F> func2) => null;
  ////////////////////////////////////////////////////////////////////////////
  var method3 = bazClassMembers["method3"];
  Expect.isNotNull(method3, "method3 not found");
  Expect.stringEquals('method3', method3.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('mirrors_helper.Baz.method3', method3.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(method3.surroundingDeclaration, bazClass,
                      "Unexpected surrounding declaration");
  Expect.isFalse(method3.isTopLevel, "Method is top level");
  Expect.isFalse(method3.isConstructor, "Method is constructor");
  Expect.isFalse(method3.isField, "Method is field");
  Expect.isTrue(method3.isMethod, "Method is not method");
  Expect.isFalse(method3.isPrivate, "Method is private");
  Expect.isFalse(method3.isStatic, "Method is static");
  Expect.isTrue(method3 is MethodMirror, "Method is not MethodMirror");
  Expect.isFalse(method3.isConst, "Method is const");
  Expect.isFalse(method3.isFactory, "Method is factory");
  Expect.isNull(method3.constructorName,
                "Method constructorName is non-null");
  Expect.isFalse(method3.isGetter, "Method is getter");
  Expect.isFalse(method3.isSetter, "Method is setter");
  Expect.isFalse(method3.isOperator, "Method is operator");
  Expect.isNull(method3.operatorName,
                "Method operatorName is non-null");

  var method3ReturnType = method3.returnType;
  Expect.isNotNull(method3ReturnType, "Return type is null");
  Expect.isTrue(method3ReturnType is InterfaceMirror,
                "Return type is not interface");
  Expect.equals(bazClass, method3ReturnType.declaration,
                "Return type is not Baz");
  // TODO(johnniwinther): Test type arguments of [method3ReturnType].

  var method3Parameters = method3.parameters;
  Expect.isNotNull(method3Parameters, "Method parameters is null");
  Expect.equals(2, method3Parameters.length, "Unexpected parameter count");
  var method3Parameter1 = method3Parameters[0];
  Expect.isNotNull(method3Parameter1, "Parameter is null");
  var method3Parameter1type = method3Parameter1.type;
  Expect.isNotNull(method3Parameter1type, "Parameter type of 'func1' is null");
  Expect.isTrue(method3Parameter1type is FunctionTypeMirror,
                "Parameter type of 'func1' is not a function");
  Expect.equals(bazE, method3Parameter1type.returnType,
                "Return type of 'func1' is not a E");
  Expect.isNotNull(method3Parameter1type.parameters,
                   "Parameters of 'func1' is null");
  Expect.equals(1, method3Parameter1type.parameters.length,
                "Unexpected parameter count of 'func1'");
  Expect.equals(bazE, method3Parameter1type.returnType,
                "Return type of 'func1' is not a E");
  Expect.isNotNull(method3Parameter1type.parameters[0],
                "Parameter 1 of 'func1' is null");
  Expect.stringEquals('f', method3Parameter1type.parameters[0].simpleName,
                "Unexpected name parameter 1 of 'func1'");
  Expect.equals(bazF, method3Parameter1type.parameters[0].type,
                "Argument type of 'func1' is not a F");
  Expect.stringEquals("func1", method3Parameter1.simpleName,
                      "Unexpected parameter simpleName");
  Expect.stringEquals("mirrors_helper.Baz.method3#func1",
                      method3Parameter1.qualifiedName,
                      "Unexpected parameter qualifiedName");
  Expect.isFalse(method3Parameter1.hasDefaultValue,
                 "Parameter has default value");
  Expect.isNull(method3Parameter1.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method3Parameter1.isOptional, "Parameter is optional");

  var method3Parameter2 = method3Parameters[1];
  Expect.isNotNull(method3Parameter2, "Parameter is null");
  var funcTypedef = method3Parameter2.type;
  Expect.isNotNull(funcTypedef, "Parameter type is null");
  Expect.stringEquals("Func", funcTypedef.simpleName,
                      "Unexpected simpleName");
  Expect.stringEquals("mirrors_helper.Func", funcTypedef.qualifiedName,
                      "Unexpected simpleName");
  Expect.isFalse(funcTypedef.isObject, "Typedef is Object");
  Expect.isFalse(funcTypedef.isDynamic, "Typedef is Dynamic");
  Expect.isFalse(funcTypedef.isVoid, "Typedef is void");
  Expect.isFalse(funcTypedef.isTypeVariable, "Typedef is a type variable");
  Expect.isTrue(funcTypedef.isTypedef, "Typedef is not a typedef");
  Expect.isFalse(funcTypedef.isFunction, "Typedef is a function");

  Expect.equals(helperLibrary, funcTypedef.library,
                "Unexpected typedef library");
  Expect.isNull(funcTypedef.superclass, "Non-null superclass on typedef");
  Expect.isNotNull(funcTypedef.interfaces,
                   "Null interfaces map on typedef");
  Expect.isTrue(funcTypedef.interfaces.isEmpty(),
                "Non-empty interfaces map on typedef");
  Expect.isNotNull(funcTypedef.declaredMembers,
                   "Declared members map is null on type def");
  Expect.isTrue(funcTypedef.declaredMembers.isEmpty(),
                "Non-empty declared members map on typedef");

  // TODO(johnniwinther): Returned typedef should not be the declaration:
  Expect.isTrue(funcTypedef.isDeclaration, "Typedef is not declaration");
  Expect.isFalse(funcTypedef.isClass, "Typedef is class");
  Expect.isFalse(funcTypedef.isInterface, "Typedef is interface");
  Expect.isFalse(funcTypedef.isPrivate, "Typedef is private");
  Expect.isNull(funcTypedef.defaultType,
                "Typedef default type is non-null");
  // TODO(johnniwinther): Should not throw an exception since the type should
  // not be the declaration.
  Expect.throws(() => funcTypedef.typeArguments,
                (exception) => true,
                "Typedef has type arguments");
  var funcTypedefTypeVariables = funcTypedef.typeVariables;
  Expect.isNotNull(funcTypedefTypeVariables);
  Expect.equals(2, funcTypedefTypeVariables.length);

  var funcTypedefDefinition = funcTypedef.definition;
  Expect.isNotNull(funcTypedefDefinition);
  Expect.isTrue(funcTypedefDefinition is FunctionTypeMirror);

  Expect.stringEquals("func2", method3Parameter2.simpleName,
                      "Unexpected parameter simpleName");
  Expect.stringEquals("mirrors_helper.Baz.method3#func2",
                      method3Parameter2.qualifiedName,
                      "Unexpected parameter qualifiedName");
  Expect.isFalse(method3Parameter2.hasDefaultValue,
                 "Parameter 'func2' has default value: "
                 "${method3Parameter2.defaultValue}");
  Expect.isNull(method3Parameter2.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method3Parameter2.isOptional, "Parameter is optional");

  ////////////////////////////////////////////////////////////////////////////
  // bool operator==(Object other) => false;
  ////////////////////////////////////////////////////////////////////////////
  var operator_eq = bazClassMembers['=='];
  Expect.isNotNull(operator_eq, "operator == not found");
  Expect.stringEquals('==', operator_eq.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('operator ==', operator_eq.displayName);
  Expect.stringEquals('mirrors_helper.Baz.==',
                      operator_eq.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(operator_eq.surroundingDeclaration, bazClass,
                "Unexpected surrounding declaration");
  Expect.isFalse(operator_eq.isTopLevel, "Method is top level");
  Expect.isFalse(operator_eq.isConstructor, "Method is constructor");
  Expect.isFalse(operator_eq.isField, "Method is field");
  Expect.isTrue(operator_eq.isMethod, "Method is not method");
  Expect.isFalse(operator_eq.isPrivate, "Method is private");
  Expect.isFalse(operator_eq.isStatic, "Method is static");
  Expect.isTrue(operator_eq is MethodMirror, "Method is not MethodMirror");
  Expect.isFalse(operator_eq.isConst, "Method is const");
  Expect.isFalse(operator_eq.isFactory, "Method is factory");
  Expect.isNull(operator_eq.constructorName,
                "Method constructorName is non-null");
  Expect.isFalse(operator_eq.isGetter, "Method is getter");
  Expect.isFalse(operator_eq.isSetter, "Method is setter");
  Expect.isTrue(operator_eq.isOperator, "Method is not operator");
  Expect.stringEquals('==', operator_eq.operatorName,
                      "Unexpected operatorName");

  ////////////////////////////////////////////////////////////////////////////
  // int operator -() => 0;
  ////////////////////////////////////////////////////////////////////////////
  var operator_negate = bazClassMembers[Mirror.UNARY_MINUS];
  Expect.isNotNull(operator_negate, "operator < not found");
  Expect.stringEquals(Mirror.UNARY_MINUS, operator_negate.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('operator -', operator_negate.displayName);
  Expect.stringEquals('mirrors_helper.Baz.${Mirror.UNARY_MINUS}',
                      operator_negate.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(operator_negate.surroundingDeclaration, bazClass,
                "Unexpected surrounding declaration");
  Expect.isFalse(operator_negate.isTopLevel, "Method is top level");
  Expect.isFalse(operator_negate.isConstructor, "Method is constructor");
  Expect.isFalse(operator_negate.isField, "Method is field");
  Expect.isTrue(operator_negate.isMethod, "Method is not method");
  Expect.isFalse(operator_negate.isPrivate, "Method is private");
  Expect.isFalse(operator_negate.isStatic, "Method is static");
  Expect.isTrue(operator_negate is MethodMirror,
                "Method is not MethodMirror");
  Expect.isFalse(operator_negate.isConst, "Method is const");
  Expect.isFalse(operator_negate.isFactory, "Method is factory");
  Expect.isNull(operator_negate.constructorName,
                "Method constructorName is non-null");
  Expect.isFalse(operator_negate.isGetter, "Method is getter");
  Expect.isFalse(operator_negate.isSetter, "Method is setter");
  Expect.isTrue(operator_negate.isOperator, "Method is not operator");
  Expect.stringEquals('-', operator_negate.operatorName,
                      "Unexpected operatorName");


  var bazClassConstructors = bazClass.constructors;
  Expect.isNotNull(bazClassConstructors, "Constructors map is null");
  Expect.equals(3, bazClassConstructors.length,
                "Unexpected number of constructors");

  var bazClassNonameConstructor = bazClassConstructors['Baz'];
  Expect.isNotNull(bazClassNonameConstructor);
  Expect.isTrue(bazClassNonameConstructor is MethodMirror);
  Expect.isTrue(bazClassNonameConstructor.isConstructor);
  Expect.isFalse(bazClassNonameConstructor.isFactory);
  Expect.stringEquals('Baz', bazClassNonameConstructor.simpleName);
  Expect.stringEquals('Baz', bazClassNonameConstructor.displayName);
  Expect.stringEquals('mirrors_helper.Baz.Baz',
      bazClassNonameConstructor.qualifiedName);
  Expect.stringEquals('', bazClassNonameConstructor.constructorName);

  var bazClassNamedConstructor = bazClassConstructors['Baz.named'];
  Expect.isNotNull(bazClassNamedConstructor);
  Expect.isTrue(bazClassNamedConstructor is MethodMirror);
  Expect.isTrue(bazClassNamedConstructor.isConstructor);
  Expect.isFalse(bazClassNamedConstructor.isFactory);
  Expect.stringEquals('Baz.named', bazClassNamedConstructor.simpleName);
  Expect.stringEquals('Baz.named', bazClassNamedConstructor.displayName);
  Expect.stringEquals('mirrors_helper.Baz.Baz.named',
      bazClassNamedConstructor.qualifiedName);
  Expect.stringEquals('named', bazClassNamedConstructor.constructorName);

  var bazClassFactoryConstructor = bazClassConstructors['Baz.factory'];
  Expect.isNotNull(bazClassFactoryConstructor);
  Expect.isTrue(bazClassFactoryConstructor is MethodMirror);
  Expect.isTrue(bazClassFactoryConstructor.isConstructor);
  Expect.isTrue(bazClassFactoryConstructor.isFactory);
  Expect.stringEquals('Baz.factory', bazClassFactoryConstructor.simpleName);
  Expect.stringEquals('Baz.factory', bazClassFactoryConstructor.displayName);
  Expect.stringEquals('mirrors_helper.Baz.Baz.factory',
      bazClassFactoryConstructor.qualifiedName);
  Expect.stringEquals('factory', bazClassFactoryConstructor.constructorName);

  // TODO(johnniwinther): Add more tests of constructors.
  // TODO(johnniwinther): Add a test for unnamed factory methods.
}

// class _PrivateClass {
//   var _privateField;
//   get _privateGetter => _privateField;
//   void set _privateSetter(value) => _privateField = value;
//   void _privateMethod() {}
//   _PrivateClass._privateConstructor();
//   factory _PrivateClass._privateFactoryConstructor() => new _PrivateClass();
// }
void testPrivate(MirrorSystem system, LibraryMirror helperLibrary,
                 Map<String,TypeMirror> types) {
  var privateClass = types['_PrivateClass'];
  Expect.isNotNull(privateClass);
  Expect.isTrue(privateClass is InterfaceMirror);
  Expect.isTrue(privateClass.isClass);
  Expect.isTrue(privateClass.isPrivate);

  var privateField = privateClass.declaredMembers['_privateField'];
  Expect.isNotNull(privateField);
  Expect.isTrue(privateField is FieldMirror);
  Expect.isTrue(privateField.isPrivate);

  var privateGetter = privateClass.declaredMembers['_privateGetter'];
  Expect.isNotNull(privateGetter);
  Expect.isTrue(privateGetter is MethodMirror);
  Expect.isTrue(privateGetter.isGetter);
  Expect.isTrue(privateGetter.isPrivate);

  var privateSetter = privateClass.declaredMembers['_privateSetter='];
  Expect.isNotNull(privateSetter);
  Expect.isTrue(privateSetter is MethodMirror);
  Expect.isTrue(privateSetter.isSetter);
  Expect.isTrue(privateSetter.isPrivate);

  var privateMethod = privateClass.declaredMembers['_privateMethod'];
  Expect.isNotNull(privateMethod);
  Expect.isTrue(privateMethod is MethodMirror);
  Expect.isTrue(privateMethod.isPrivate);

  var privateConstructor =
      privateClass.declaredMembers['_PrivateClass._privateConstructor'];
  Expect.isNotNull(privateConstructor);
  Expect.isTrue(privateConstructor is MethodMirror);
  Expect.isTrue(privateConstructor.isConstructor);
  Expect.isTrue(privateConstructor.isPrivate);

  var privateFactoryConstructor =
      privateClass.declaredMembers['_PrivateClass._privateFactoryConstructor'];
  Expect.isNotNull(privateFactoryConstructor);
  Expect.isTrue(privateFactoryConstructor is MethodMirror);
  Expect.isTrue(privateFactoryConstructor.isFactory);
  Expect.isTrue(privateFactoryConstructor.isPrivate);
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/implementation/mirrors/source_mirrors.dart';
import 'package:compiler/implementation/mirrors/mirrors_util.dart';
import 'package:compiler/implementation/mirrors/analyze.dart';
import 'package:compiler/implementation/filenames.dart'
       show currentDirectory;
import 'package:compiler/implementation/source_file_provider.dart';

import 'dart:io';

final Uri DART_MIRRORS_URI = new Uri(scheme: 'dart', path: 'mirrors');

int count(Iterable iterable) {
  var count = 0;
  for (var element in iterable) {
    count++;
  }
  return count;
}

bool containsType(TypeMirror expected, Iterable<TypeMirror> iterable) {
  for (var element in iterable) {
    if (element.originalDeclaration == expected.originalDeclaration) {
      return true;
    }
  }
  return false;
}

DeclarationMirror findMirror(Iterable<DeclarationMirror> list, Symbol name) {
  for (DeclarationMirror mirror in list) {
    if (mirror.simpleName == name) {
      return mirror;
    }
  }
  return null;
}

main() {
  Uri scriptUri = currentDirectory.resolveUri(Platform.script);
  Uri libUri = scriptUri.resolve('../../../sdk/');
  Uri inputUri = scriptUri.resolve('mirrors_helper.dart');
  var provider = new CompilerSourceFileProvider();
  var diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  asyncStart();
  var result = analyze([inputUri], libUri, null,
                       provider.readStringFromUri, diagnosticHandler,
                       <String>['--preserve-comments']);
  result.then((MirrorSystem mirrors) {
    test(mirrors);
  }).then(asyncSuccess);
}

void test(MirrorSystem mirrors) {
  Expect.isNotNull(mirrors, "No mirror system returned from compilation");

  var libraries = mirrors.libraries;
  Expect.isNotNull(libraries, "No libraries map returned");
  Expect.isFalse(libraries.isEmpty, "Empty libraries map returned");

  var helperLibrary = findMirror(libraries.values, #mirrors_helper);
  Expect.isNotNull(helperLibrary, "Library 'mirrors_helper' not found");
  Expect.equals(#mirrors_helper, helperLibrary.simpleName,
    "Unexpected library simple name");
  Expect.equals(#mirrors_helper, helperLibrary.qualifiedName,
    "Unexpected library qualified name");
  Expect.equals(helperLibrary, mirrors.findLibrary(#mirrors_helper));

  var helperLibraryLocation = helperLibrary.location;
  Expect.isNotNull(helperLibraryLocation);
  Expect.equals(271, helperLibraryLocation.offset, "Unexpected offset");
  Expect.equals(23, helperLibraryLocation.length, "Unexpected length");
  Expect.equals(9, helperLibraryLocation.line, "Unexpected line");
  Expect.equals(1, helperLibraryLocation.column, "Unexpected column");


  var declarations = helperLibrary.declarations;
  Expect.isNotNull(declarations, "No declarations map returned");
  Expect.isFalse(declarations.isEmpty, "Empty declarations map returned");

  testFoo(mirrors, helperLibrary, declarations);
  testBar(mirrors, helperLibrary, declarations);
  testBaz(mirrors, helperLibrary, declarations);
  // TODO(johnniwinther): Add test of class [Boz] and typedef [Func].
  // TODO(johnniwinther): Add tests of type argument substitution, which
  // is not currently implemented in dart2js.
  // TODO(johnniwinther): Add tests of Location and Source.
  testPrivate(mirrors, helperLibrary, declarations);
}

// Testing class Foo:
//
// class Foo {
//
// }
void testFoo(MirrorSystem system, LibraryMirror helperLibrary,
             Map<Symbol, DeclarationMirror> declarations) {
  var fooClass = declarations[#Foo];
  Expect.isNotNull(fooClass, "Type 'Foo' not found");
  Expect.isTrue(fooClass is ClassMirror,
                "Unexpected mirror type returned");
  Expect.equals(#Foo, fooClass.simpleName,
                      "Unexpected type simple name");
  Expect.equals(#mirrors_helper.Foo, fooClass.qualifiedName,
                      "Unexpected type qualified name");

  Expect.equals(helperLibrary, getLibrary(fooClass),
                "Unexpected library returned from type");

  Expect.isFalse(isObject(fooClass), "Class is Object");
  Expect.isFalse(fooClass.isDynamic, "Class is dynamic");
  Expect.isFalse(fooClass.isVoid, "Class is void");
  Expect.isFalse(fooClass is TypeVariableMirror, "Class is a type variable");
  Expect.isFalse(fooClass is TypedefMirror, "Class is a typedef");
  Expect.isFalse(fooClass is FunctionTypeMirror, "Class is a function");

  Expect.isTrue(fooClass.isOriginalDeclaration);
  Expect.equals(fooClass, fooClass.originalDeclaration);

  Expect.isTrue(fooClass is ClassMirror, "Class is not class");
  Expect.isFalse(fooClass.isAbstract);
  Expect.isFalse(fooClass.isPrivate, "Class is private");

  var objectType = fooClass.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(isObject(objectType), "Object is not Object");
  Expect.isTrue(objectType.isOriginalDeclaration);
  Expect.isTrue(containsType(fooClass,
                             computeSubdeclarations(system, objectType)),
                "Class is not subclass of superclass");

  var fooInterfaces = fooClass.superinterfaces;
  Expect.isNotNull(fooInterfaces, "Interfaces map is null");
  Expect.isTrue(fooInterfaces.isEmpty, "Interfaces map is not empty");

  var fooSubdeclarations = computeSubdeclarations(system, fooClass);
  Expect.equals(1, count(fooSubdeclarations), "Unexpected subtype count");
  for (var fooSubdeclaration in fooSubdeclarations) {
    Expect.equals(fooClass, fooSubdeclaration.superclass.originalDeclaration);
  }

  Expect.isTrue(fooClass.typeArguments.isEmpty);
  var fooClassTypeVariables = fooClass.typeVariables;
  Expect.isNotNull(fooClassTypeVariables, "Type variable list is null");
  Expect.isTrue(fooClassTypeVariables.isEmpty,
                "Type variable list is not empty");

  var fooClassMembers = fooClass.declarations;
  Expect.isNotNull(fooClassMembers, "Declared members map is null");
  Expect.equals(1, fooClassMembers.length);

  var fooM = fooClassMembers[#m];
  Expect.isNotNull(fooM);
  Expect.isTrue(fooM is MethodMirror);
  Expect.equals(1, fooM.parameters.length);
  var fooMa = fooM.parameters[0];
  Expect.isNotNull(fooMa);
  Expect.isTrue(fooMa is ParameterMirror);

  //////////////////////////////////////////////////////////////////////////////
  // Metadata tests
  //////////////////////////////////////////////////////////////////////////////

  var metadataList = fooClass.metadata;
  Expect.isNotNull(metadataList);
  Expect.equals(16, metadataList.length);
  var metadataListIndex = 0;
  var metadata;

  var dartMirrorsLibrary = system.libraries[DART_MIRRORS_URI];
  Expect.isNotNull(dartMirrorsLibrary);
  var commentType = dartMirrorsLibrary.declarations[#Comment];
  Expect.isNotNull(commentType);

  // /// Singleline doc comment.
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isTrue(metadata.isDocComment);
  Expect.stringEquals(
      "/// Singleline doc comment.", metadata.text);
  Expect.stringEquals(
      "Singleline doc comment.", metadata.trimmedText);

  // @Metadata
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is TypeInstanceMirror);
  var metadataType = metadata.representedType;
  Expect.isNotNull(metadataType);
  Expect.equals(#Metadata, metadataType.simpleName);

  // // This is intentionally the type literal.
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isFalse(metadata.isDocComment);
  Expect.stringEquals(
      "// This is intentionally the type literal.", metadata.text);
  Expect.stringEquals(
      "This is intentionally the type literal.", metadata.trimmedText);

  // Singleline comment 1.
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isFalse(metadata.isDocComment);
  Expect.stringEquals(
      "// Singleline comment 1.", metadata.text);
  Expect.stringEquals(
      "Singleline comment 1.", metadata.trimmedText);

  // Singleline comment 2.
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isFalse(metadata.isDocComment);
  Expect.stringEquals(
      "// Singleline comment 2.", metadata.text);
  Expect.stringEquals(
      "Singleline comment 2.", metadata.trimmedText);

  // @Metadata(null)
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  InstanceMirror data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.isNull(data.reflectee);

  // @Metadata(true)
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.isTrue(data.reflectee);

  // @Metadata(false)
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.isFalse(data.reflectee);

  // @Metadata(0)
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.equals(0, data.reflectee);

  // @Metadata(1.5)
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.equals(1.5, data.reflectee);

  // @Metadata("Foo")
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.stringEquals("Foo", data.reflectee);

  // @Metadata(const ["Foo"])
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isTrue(data is ListInstanceMirror);
  Expect.isFalse(data.hasReflectee);
  Expect.throws(() => data.reflectee, (_) => true);
  ListInstanceMirror listData = data;
  Expect.equals(1, listData.length);
  InstanceMirror element = listData.getElement(0);
  Expect.isNotNull(element);
  Expect.isTrue(element.hasReflectee);
  Expect.stringEquals("Foo", element.reflectee);

  // @Metadata(/* Inline comment */ const {'foo':"Foo"})
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isTrue(data is MapInstanceMirror);
  Expect.isFalse(data.hasReflectee);
  Expect.throws(() => data.reflectee, (_) => true);
  MapInstanceMirror mapData = data;
  Expect.equals(1, mapData.length);
  var it = mapData.keys.iterator;
  Expect.isTrue(it.moveNext());
  Expect.stringEquals('foo', it.current);
  element = mapData.getValue('foo');
  Expect.isNotNull(element);
  Expect.isTrue(element.hasReflectee);
  Expect.stringEquals("Foo", element.reflectee);
  Expect.isNull(mapData.getValue('bar'));

  // @metadata
  var metadataRef = metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.equals(metadataType.originalDeclaration, metadata.type);
  data = metadata.getField(#data);
  Expect.isNotNull(data);
  Expect.isTrue(data.hasReflectee);
  Expect.isNull(data.reflectee);

  // /** Multiline doc comment. */
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isTrue(metadata.isDocComment);
  Expect.stringEquals(
      "/** Multiline doc comment. */", metadata.text);
  Expect.stringEquals(
      "Multiline doc comment. ", metadata.trimmedText);

  // /* Multiline comment. */
  metadata = metadataList[metadataListIndex++];
  Expect.isTrue(metadata is InstanceMirror);
  Expect.isFalse(metadata.hasReflectee);
  Expect.throws(() => metadata.reflectee, (_) => true);
  Expect.isTrue(metadata is CommentInstanceMirror);
  Expect.equals(commentType.originalDeclaration, metadata.type);
  Expect.isFalse(metadata.isDocComment);
  Expect.stringEquals(
      "/* Multiline comment. */", metadata.text);
  Expect.stringEquals(
      "Multiline comment. ", metadata.trimmedText);

  Expect.equals(metadataList.length, metadataListIndex);

  Expect.isNotNull(fooMa.metadata);
  Expect.equals(1, fooMa.metadata.length);
  Expect.equals(metadataRef, fooMa.metadata[0]);

  //////////////////////////////////////////////////////////////////////////////
  // Location test
  //////////////////////////////////////////////////////////////////////////////

  var fooClassLocation = fooClass.location;
  Expect.isNotNull(fooClassLocation);
  // Expect the location to start with the first metadata, not including the
  // leading comment.
  Expect.equals(376, fooClassLocation.offset, "Unexpected offset");
  // Expect the location to end with the class body.
  Expect.equals(351, fooClassLocation.length, "Unexpected length");
  Expect.equals(18, fooClassLocation.line, "Unexpected line");
  Expect.equals(1, fooClassLocation.column, "Unexpected column");

}

// Testing abstract class Bar:
//
// abstract class Bar<E> {
//
// }
void testBar(MirrorSystem system, LibraryMirror helperLibrary,
             Map<Symbol, DeclarationMirror> classes) {
  var barClass = classes[#Bar];
  Expect.isNotNull(barClass, "Type 'Bar' not found");
  Expect.isTrue(barClass is ClassMirror,
               "Unexpected mirror type returned");
  Expect.equals(#Bar, barClass.simpleName,
                      "Unexpected type simple name");
  Expect.equals(#mirrors_helper.Bar, barClass.qualifiedName,
                "Unexpected type qualified name");

  Expect.equals(helperLibrary, getLibrary(barClass),
                "Unexpected library returned from type");

  Expect.isFalse(isObject(barClass), "Interface is Object");
  Expect.isFalse(barClass.isDynamic, "Interface is dynamic");
  Expect.isFalse(barClass.isVoid, "Interface is void");
  Expect.isFalse(barClass is TypeVariableMirror, "Interface is a type variable");
  Expect.isFalse(barClass is TypedefMirror, "Interface is a typedef");
  Expect.isFalse(barClass is FunctionTypeMirror, "Interface is a function");

  Expect.isTrue(barClass.isOriginalDeclaration);
  Expect.equals(barClass, barClass.originalDeclaration);

  Expect.isTrue(barClass is ClassMirror);
  Expect.isTrue(barClass.isAbstract);
  Expect.isFalse(barClass.isPrivate, "Interface is private");

  var objectType = barClass.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(isObject(objectType), "Object is not Object");
  Expect.isTrue(objectType.isOriginalDeclaration);
  Expect.isTrue(containsType(barClass,
                             computeSubdeclarations(system, objectType)),
                "Class is not subclass of superclass");

  var barInterfaces = barClass.superinterfaces;
  Expect.isNotNull(barInterfaces, "Interfaces map is null");
  Expect.isTrue(barInterfaces.isEmpty, "Interfaces map is not empty");

  var barSubdeclarations = computeSubdeclarations(system, barClass);
  Expect.equals(1, count(barSubdeclarations), "Unexpected subtype count");
  for (var barSubdeclaration in barSubdeclarations) {
    Expect.isTrue(containsType(barClass,
                               barSubdeclaration.superinterfaces),
                  "Interface is not superinterface of subclass");
  }

  Expect.isTrue(barClass.typeArguments.isEmpty);
  var barInterfaceTypeVariables = barClass.typeVariables;
  Expect.isNotNull(barInterfaceTypeVariables, "Type variable list is null");
  Expect.isFalse(barInterfaceTypeVariables.isEmpty,
                 "Type variable list is empty");
  Expect.equals(barInterfaceTypeVariables.length, 1,
                "Unexpected number of type variables");

  var barE = barInterfaceTypeVariables[0];
  Expect.isNotNull(barE, "Type variable is null");
  Expect.isTrue(barE is TypeVariableMirror);

  var barInterfaceMembers = barClass.declarations;
  Expect.isNotNull(barInterfaceMembers, "Declared members map is null");
  Expect.isTrue(barInterfaceMembers.isEmpty,
                "Declarations map is unempty");

  var metadata = barClass.metadata;
  Expect.isNotNull(metadata);
  Expect.equals(0, metadata.length);
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
//   operator$foo() {}
// }
void testBaz(MirrorSystem system, LibraryMirror helperLibrary,
             Map<Symbol, DeclarationMirror> declarations) {
  var bazClass = declarations[#Baz];
  Expect.isNotNull(bazClass, "Type 'Baz' not found");
  Expect.isTrue(bazClass is ClassMirror,
                "Unexpected mirror type returned");
  Expect.equals(#Baz, bazClass.simpleName,
                "Unexpected type simple name");
  Expect.equals(#mirrors_helper.Baz, bazClass.qualifiedName,
                "Unexpected type qualified name");

  Expect.equals(helperLibrary, getLibrary(bazClass),
                "Unexpected library returned from type");

  Expect.isFalse(isObject(bazClass), "Class is Object");
  Expect.isFalse(bazClass.isDynamic, "Class is dynamic");
  Expect.isFalse(bazClass.isVoid, "Class is void");
  Expect.isFalse(bazClass is TypeVariableMirror, "Class is a type variable");
  Expect.isFalse(bazClass is TypedefMirror, "Class is a typedef");
  Expect.isFalse(bazClass is FunctionTypeMirror, "Class is a function");

  Expect.isTrue(bazClass.isOriginalDeclaration);
  Expect.equals(bazClass, bazClass.originalDeclaration);

  Expect.isTrue(bazClass is ClassMirror, "Class is not class");
  Expect.isFalse(bazClass.isAbstract);
  Expect.isFalse(bazClass.isPrivate, "Class is private");

  var objectType = bazClass.superclass;
  Expect.isNotNull(objectType, "Superclass is null");
  Expect.isTrue(isObject(objectType), "Object is not Object");
  Expect.isTrue(objectType.isOriginalDeclaration);
  Expect.isTrue(containsType(bazClass,
                             computeSubdeclarations(system, objectType)),
                "Class is not subclass of superclass");

  var bazInterfaces = bazClass.superinterfaces;
  Expect.isNotNull(bazInterfaces, "Interfaces map is null");
  Expect.isTrue(!bazInterfaces.isEmpty, "Interfaces map is empty");
  for (var bazInterface in bazInterfaces) {
    Expect.isTrue(containsType(bazClass,
                               computeSubdeclarations(system, objectType)),
                  "Class is not subclass of superinterface");
  }

  var bazSubdeclarations = computeSubdeclarations(system, bazClass);
  Expect.equals(0, count(bazSubdeclarations), "Unexpected subtype count");

  var barInterface = findMirror(bazInterfaces, #Bar);
  Expect.isNotNull(barInterface, "Interface bar is missing");
  Expect.isFalse(barInterface.isOriginalDeclaration);
  var barInterfaceTypeArguments = barInterface.typeArguments;
  Expect.isNotNull(barInterfaceTypeArguments, "Type arguments are missing");
  Expect.equals(1, barInterfaceTypeArguments.length,
                "Type arguments is empty");

  Expect.isTrue(bazClass.typeArguments.isEmpty, "Class has type arguments");
  var bazClassTypeVariables = bazClass.typeVariables;
  Expect.isNotNull(bazClassTypeVariables, "Type variable list is null");
  Expect.equals(2, bazClassTypeVariables.length,
                "Type variable list is not empty");

  var bazE = bazClassTypeVariables[0];
  Expect.isNotNull(bazE, "Type variable is null");
  Expect.equals(#E, bazE.simpleName, "Unexpected simpleName");
  Expect.equals(#mirrors_helper.Baz.E, bazE.qualifiedName,
                "Unexpected qualifiedName");
  Expect.equals(bazClass, bazE.owner,
                "Unexpected type variable declarer");
  var bazEbound = bazE.upperBound;
  Expect.isNotNull(bazEbound);
  Expect.isTrue(bazEbound.isOriginalDeclaration);
  Expect.isTrue(isObject(bazEbound), "Bound is not object");

  var bazF = bazClassTypeVariables[1];
  Expect.isNotNull(bazF, "Type variable is null");
  Expect.equals(#F, bazF.simpleName, "Unexpected simpleName");
  Expect.equals(#mirrors_helper.Baz.F, bazF.qualifiedName,
                "Unexpected qualifiedName");
  Expect.equals(bazClass, bazF.owner);
  var bazFbound = bazF.upperBound;
  Expect.isNotNull(bazFbound);
  Expect.isTrue(bazFbound.isOriginalDeclaration);
  Expect.equals(#mirrors_helper.Foo, bazFbound.qualifiedName,
                "Bound is not Foo");

  var bazClassMembers = bazClass.declarations;
  Expect.isNotNull(bazClassMembers, "Declared members map is null");
  Expect.equals(9, bazClassMembers.length,
                "Unexpected number of declared members");

  ////////////////////////////////////////////////////////////////////////////
  // static method1(e) {}
  ////////////////////////////////////////////////////////////////////////////
  var method1 = bazClassMembers[#method1];
  Expect.isNotNull(method1, "method1 not found");
  Expect.equals(#method1, method1.simpleName);
  Expect.equals(#mirrors_helper.Baz.method1, method1.qualifiedName);
  Expect.equals(method1.owner, bazClass);
  Expect.isFalse(method1.isTopLevel);
  Expect.isTrue(method1 is MethodMirror);
  Expect.isFalse(method1.isConstructor);
  Expect.isFalse(method1.isPrivate);
  Expect.isTrue(method1.isStatic);
  Expect.isTrue(method1.isRegularMethod);
  Expect.isFalse(method1.isConstConstructor);
  Expect.isFalse(method1.isGenerativeConstructor);
  Expect.isFalse(method1.isRedirectingConstructor);
  Expect.isFalse(method1.isFactoryConstructor);
  Expect.isFalse(method1.isGetter);
  Expect.isFalse(method1.isSetter);
  Expect.isFalse(method1.isOperator);

  var dynamicType = method1.returnType;
  Expect.isNotNull(dynamicType, "Return type was null");
  Expect.isFalse(isObject(dynamicType), "dynamic is Object");
  Expect.isTrue(dynamicType.isDynamic, "dynamic is not dynamic");
  Expect.isFalse(dynamicType.isVoid, "dynamic is void");
  Expect.isFalse(dynamicType is TypeVariableMirror, "dynamic is a type variable");
  Expect.isFalse(dynamicType is TypedefMirror, "dynamic is a typedef");
  Expect.isFalse(dynamicType is FunctionTypeMirror, "dynamic is a function");

  var method1Parameters = method1.parameters;
  Expect.isNotNull(method1Parameters, "Method parameters is null");
  Expect.equals(1, method1Parameters.length, "Unexpected parameter count");
  var method1Parameter1 = method1Parameters[0];
  Expect.isNotNull(method1Parameter1, "Parameter is null");
  Expect.equals(dynamicType, method1Parameter1.type);
  Expect.equals(#e, method1Parameter1.simpleName);
  Expect.equals(#mirrors_helper.Baz.method1.e, method1Parameter1.qualifiedName);
  Expect.isFalse(method1Parameter1.hasDefaultValue,
    "Parameter has default value");
  Expect.isNull(method1Parameter1.defaultValue,
    "Parameter default value is non-null");
  Expect.isFalse(method1Parameter1.isOptional, "Parameter is optional");

  ////////////////////////////////////////////////////////////////////////////
  // static void method2(E e, [F f = null]) {}
  ////////////////////////////////////////////////////////////////////////////
  var method2 = bazClassMembers[#method2];
  Expect.isNotNull(method2, "method2 not found");
  Expect.equals(#method2, method2.simpleName);
  Expect.equals(#mirrors_helper.Baz.method2, method2.qualifiedName);
  Expect.equals(method2.owner, bazClass);
  Expect.isFalse(method2.isTopLevel);
  Expect.isTrue(method2 is MethodMirror);
  Expect.isFalse(method2.isConstructor);
  Expect.isFalse(method2.isPrivate);
  Expect.isFalse(method2.isStatic);
  Expect.isTrue(method2.isRegularMethod);
  Expect.isFalse(method2.isConstConstructor);
  Expect.isFalse(method2.isGenerativeConstructor);
  Expect.isFalse(method2.isRedirectingConstructor);
  Expect.isFalse(method2.isFactoryConstructor);
  Expect.isFalse(method2.isGetter);
  Expect.isFalse(method2.isSetter);
  Expect.isFalse(method2.isOperator);

  var voidType = method2.returnType;
  Expect.isNotNull(voidType, "Return type was null");
  Expect.isFalse(isObject(voidType), "void is Object");
  Expect.isFalse(voidType.isDynamic, "void is dynamic");
  Expect.isTrue(voidType.isVoid, "void is not void");
  Expect.isFalse(voidType is TypeVariableMirror, "void is a type variable");
  Expect.isFalse(voidType is TypedefMirror, "void is a typedef");
  Expect.isFalse(voidType is FunctionTypeMirror, "void is a function");

  var method2Parameters = method2.parameters;
  Expect.isNotNull(method2Parameters, "Method parameters is null");
  Expect.equals(2, method2Parameters.length, "Unexpected parameter count");
  var method2Parameter1 = method2Parameters[0];
  Expect.isNotNull(method2Parameter1, "Parameter is null");
  Expect.equals(bazE, method2Parameter1.type);
  Expect.equals(#e, method2Parameter1.simpleName);
  Expect.equals(#mirrors_helper.Baz.method2.e, method2Parameter1.qualifiedName);
  Expect.isFalse(method2Parameter1.hasDefaultValue,
                      "Parameter has default value");
  Expect.isNull(method2Parameter1.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method2Parameter1.isOptional, "Parameter is optional");
  var method2Parameter2 = method2Parameters[1];
  Expect.isNotNull(method2Parameter2, "Parameter is null");
  Expect.equals(bazF, method2Parameter2.type);
  Expect.equals(#f, method2Parameter2.simpleName);
  Expect.equals(#mirrors_helper.Baz.method2.f,
                method2Parameter2.qualifiedName);
  Expect.isTrue(method2Parameter2.hasDefaultValue,
                 "Parameter has default value");
  Expect.isNotNull(method2Parameter2.defaultValue,
                   "Parameter default value is null");
  Expect.isTrue(method2Parameter2.isOptional, "Parameter is not optional");

  ////////////////////////////////////////////////////////////////////////////
  // Baz<E,F> method3(E func1(F f), Func<E,F> func2) => null;
  ////////////////////////////////////////////////////////////////////////////
  var method3 = bazClassMembers[#method3];
  Expect.isNotNull(method3, "method3 not found");
  Expect.equals(#method3, method3.simpleName);
  Expect.equals(#mirrors_helper.Baz.method3, method3.qualifiedName);
  Expect.equals(method3.owner, bazClass);
  Expect.isFalse(method3.isTopLevel);
  Expect.isTrue(method3 is MethodMirror);
  Expect.isFalse(method3.isConstructor);
  Expect.isFalse(method3.isPrivate);
  Expect.isFalse(method3.isStatic);
  Expect.isTrue(method3.isRegularMethod);
  Expect.isFalse(method3.isConstConstructor);
  Expect.isFalse(method3.isGenerativeConstructor);
  Expect.isFalse(method3.isRedirectingConstructor);
  Expect.isFalse(method3.isFactoryConstructor);
  Expect.isFalse(method3.isGetter);
  Expect.isFalse(method3.isSetter);
  Expect.isFalse(method3.isOperator);

  var method3ReturnType = method3.returnType;
  Expect.isNotNull(method3ReturnType, "Return type is null");
  Expect.isTrue(method3ReturnType is ClassMirror,
                "Return type is not interface");
  Expect.equals(bazClass, method3ReturnType.originalDeclaration);
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
  Expect.equals(#f, method3Parameter1type.parameters[0].simpleName);
  Expect.equals(bazF, method3Parameter1type.parameters[0].type,
                "Argument type of 'func1' is not a F");
  Expect.equals(#func1, method3Parameter1.simpleName);
  Expect.equals(#mirrors_helper.Baz.method3.func1,
                method3Parameter1.qualifiedName);
  Expect.isFalse(method3Parameter1.hasDefaultValue,
                 "Parameter has default value");
  Expect.isNull(method3Parameter1.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method3Parameter1.isOptional, "Parameter is optional");

  var method3Parameter2 = method3Parameters[1];
  Expect.isNotNull(method3Parameter2, "Parameter is null");
  var funcTypedef = method3Parameter2.type;
  Expect.isNotNull(funcTypedef, "Parameter type is null");
  Expect.equals(#Func, funcTypedef.simpleName);
  Expect.equals(#mirrors_helper.Func, funcTypedef.qualifiedName);
  Expect.isFalse(isObject(funcTypedef), "Typedef is Object");
  Expect.isFalse(funcTypedef.isDynamic, "Typedef is dynamic");
  Expect.isFalse(funcTypedef.isVoid, "Typedef is void");
  Expect.isFalse(funcTypedef is TypeVariableMirror, "Typedef is a type variable");
  Expect.isTrue(funcTypedef is TypedefMirror, "Typedef is not a typedef");
  Expect.isFalse(funcTypedef is FunctionTypeMirror, "Typedef is a function");

  Expect.equals(helperLibrary, getLibrary(funcTypedef),
                "Unexpected typedef library");

  Expect.isFalse(funcTypedef.isOriginalDeclaration);
  Expect.isFalse(funcTypedef is ClassMirror, "Typedef is class");
  Expect.isFalse(funcTypedef.isPrivate, "Typedef is private");
  Expect.equals(2, funcTypedef.typeArguments.length);
  var funcTypedefTypeVariables = funcTypedef.typeVariables;
  Expect.isNotNull(funcTypedefTypeVariables);
  Expect.equals(2, funcTypedefTypeVariables.length);

  var funcTypedefDefinition = funcTypedef.referent;
  Expect.isNotNull(funcTypedefDefinition);
  Expect.isTrue(funcTypedefDefinition is FunctionTypeMirror);

  Expect.equals(#func2, method3Parameter2.simpleName);
  Expect.equals(#mirrors_helper.Baz.method3.func2,
                method3Parameter2.qualifiedName);
  Expect.isFalse(method3Parameter2.hasDefaultValue,
                 "Parameter 'func2' has default value: "
                 "${method3Parameter2.defaultValue}");
  Expect.isNull(method3Parameter2.defaultValue,
                "Parameter default value is non-null");
  Expect.isFalse(method3Parameter2.isOptional, "Parameter is optional");

  ////////////////////////////////////////////////////////////////////////////
  // bool operator==(Object other) => false;
  ////////////////////////////////////////////////////////////////////////////
  var operator_eq = bazClassMembers[const Symbol('==')];
  Expect.isNotNull(operator_eq, "operator == not found");
  Expect.equals(const Symbol('=='), operator_eq.simpleName,
                "Unexpected method simpleName");
  Expect.stringEquals('operator ==', displayName(operator_eq));
  Expect.equals(const Symbol('mirrors_helper.Baz.=='),
                operator_eq.qualifiedName,
                "Unexpected method qualifiedName");
  Expect.equals(operator_eq.owner, bazClass);
  Expect.isFalse(operator_eq.isTopLevel);
  Expect.isTrue(operator_eq is MethodMirror);
  Expect.isFalse(operator_eq.isConstructor);
  Expect.isFalse(operator_eq.isPrivate);
  Expect.isFalse(operator_eq.isStatic);
  Expect.isTrue(operator_eq.isRegularMethod);
  Expect.isFalse(operator_eq.isConstConstructor);
  Expect.isFalse(operator_eq.isGenerativeConstructor);
  Expect.isFalse(operator_eq.isRedirectingConstructor);
  Expect.isFalse(operator_eq.isFactoryConstructor);
  Expect.isFalse(operator_eq.isGetter);
  Expect.isFalse(operator_eq.isSetter);
  Expect.isTrue(operator_eq.isOperator);
  Expect.stringEquals('==', operatorName(operator_eq));

  ////////////////////////////////////////////////////////////////////////////
  // int operator -() => 0;
  ////////////////////////////////////////////////////////////////////////////
  var operator_negate = bazClassMembers[const Symbol('unary-')];
  Expect.isNotNull(operator_negate, "operator < not found");
  Expect.equals(const Symbol('unary-'), operator_negate.simpleName,
                      "Unexpected method simpleName");
  Expect.stringEquals('operator -', displayName(operator_negate));
  Expect.equals(const Symbol('mirrors_helper.Baz.unary-'),
                      operator_negate.qualifiedName,
                      "Unexpected method qualifiedName");
  Expect.equals(operator_negate.owner, bazClass);
  Expect.isFalse(operator_negate.isTopLevel);
  Expect.isTrue(operator_negate is MethodMirror);
  Expect.isFalse(operator_negate.isConstructor);
  Expect.isFalse(operator_negate.isPrivate);
  Expect.isFalse(operator_negate.isStatic);
  Expect.isTrue(operator_negate.isRegularMethod);
  Expect.isFalse(operator_negate.isConstConstructor);
  Expect.isFalse(operator_negate.isGenerativeConstructor);
  Expect.isFalse(operator_negate.isRedirectingConstructor);
  Expect.isFalse(operator_negate.isFactoryConstructor);
  Expect.isFalse(operator_negate.isGetter);
  Expect.isFalse(operator_negate.isSetter);
  Expect.isTrue(operator_negate.isOperator);
  Expect.stringEquals('-', operatorName(operator_negate));


  ////////////////////////////////////////////////////////////////////////////
  // operator$foo() {}
  ////////////////////////////////////////////////////////////////////////////
  var operator$foo = bazClassMembers[#operator$foo];
  Expect.isNotNull(operator$foo, "operator\$foo not found");
  Expect.equals(#operator$foo, operator$foo.simpleName);
  Expect.equals(#mirrors_helper.Baz.operator$foo, operator$foo.qualifiedName);
  Expect.equals(operator$foo.owner, bazClass);
  Expect.isFalse(operator$foo.isTopLevel);
  Expect.isTrue(operator$foo is MethodMirror);
  Expect.isFalse(operator$foo.isConstructor);
  Expect.isFalse(operator$foo.isPrivate);
  Expect.isFalse(operator$foo.isStatic);
  Expect.isTrue(operator$foo.isRegularMethod);
  Expect.isFalse(operator$foo.isConstConstructor);
  Expect.isFalse(operator$foo.isGenerativeConstructor);
  Expect.isFalse(operator$foo.isRedirectingConstructor);
  Expect.isFalse(operator$foo.isFactoryConstructor);
  Expect.isFalse(operator$foo.isGetter);
  Expect.isFalse(operator$foo.isSetter);
  Expect.isFalse(operator$foo.isOperator);

  Expect.equals(dynamicType, operator$foo.returnType);

  var operator$fooParameters = operator$foo.parameters;
  Expect.isNotNull(operator$fooParameters, "Method parameters is null");
  Expect.equals(0, operator$fooParameters.length, "Unexpected parameter count");

  ////////////////////////////////////////////////////////////////////////////
  //   Baz();
  ////////////////////////////////////////////////////////////////////////////
  var bazClassNonameConstructor = bazClassMembers[const Symbol('')];
  Expect.isNotNull(bazClassNonameConstructor);
  Expect.isTrue(bazClassNonameConstructor is MethodMirror);
  Expect.isTrue(bazClassNonameConstructor.isConstructor);
  Expect.isFalse(bazClassNonameConstructor.isRegularMethod);
  Expect.isFalse(bazClassNonameConstructor.isConstConstructor);
  Expect.isTrue(bazClassNonameConstructor.isGenerativeConstructor);
  Expect.isFalse(bazClassNonameConstructor.isRedirectingConstructor);
  Expect.isFalse(bazClassNonameConstructor.isFactoryConstructor);
  Expect.equals(const Symbol(''), bazClassNonameConstructor.simpleName);
  Expect.stringEquals('Baz', displayName(bazClassNonameConstructor));
  Expect.equals(const Symbol('mirrors_helper.Baz.'),
      bazClassNonameConstructor.qualifiedName);

  ////////////////////////////////////////////////////////////////////////////
  //   const Baz.named();
  ////////////////////////////////////////////////////////////////////////////
  var bazClassNamedConstructor = bazClassMembers[#named];
  Expect.isNotNull(bazClassNamedConstructor);
  Expect.isTrue(bazClassNamedConstructor is MethodMirror);
  Expect.isTrue(bazClassNamedConstructor.isConstructor);
  Expect.isFalse(bazClassNamedConstructor.isRegularMethod);
  Expect.isTrue(bazClassNamedConstructor.isConstConstructor);
  Expect.isFalse(bazClassNamedConstructor.isGenerativeConstructor);
  Expect.isFalse(bazClassNamedConstructor.isRedirectingConstructor);
  Expect.isFalse(bazClassNamedConstructor.isFactoryConstructor);
  Expect.equals(#named, bazClassNamedConstructor.simpleName);
  Expect.stringEquals('Baz.named', displayName(bazClassNamedConstructor));
  Expect.equals(#mirrors_helper.Baz.named,
      bazClassNamedConstructor.qualifiedName);

  ////////////////////////////////////////////////////////////////////////////
  //   factory Baz.factory() => new Baz<E,F>();
  ////////////////////////////////////////////////////////////////////////////
  var bazClassFactoryConstructor = bazClassMembers[#factory];
  Expect.isNotNull(bazClassFactoryConstructor);
  Expect.isTrue(bazClassFactoryConstructor is MethodMirror);
  Expect.isTrue(bazClassFactoryConstructor.isConstructor);
  Expect.isFalse(bazClassFactoryConstructor.isRegularMethod);
  Expect.isFalse(bazClassFactoryConstructor.isConstConstructor);
  Expect.isFalse(bazClassFactoryConstructor.isGenerativeConstructor);
  Expect.isFalse(bazClassFactoryConstructor.isRedirectingConstructor);
  Expect.isTrue(bazClassFactoryConstructor.isFactoryConstructor);
  Expect.equals(#factory, bazClassFactoryConstructor.simpleName);
  Expect.stringEquals('Baz.factory', displayName(bazClassFactoryConstructor));
  Expect.equals(#mirrors_helper.Baz.factory,
      bazClassFactoryConstructor.qualifiedName);

  // TODO(johnniwinther): Add more tests of constructors.
  // TODO(johnniwinther): Add a test for unnamed factory methods.

  var metadata = bazClass.metadata;
  Expect.isNotNull(metadata);
  Expect.equals(0, metadata.length);
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
                 Map<Symbol, DeclarationMirror> declarations) {
  var privateClass = declarations[const Symbol('_PrivateClass')];
  Expect.isNotNull(privateClass);
  Expect.isTrue(privateClass is ClassMirror);
  Expect.isFalse(privateClass.isAbstract);
  Expect.isTrue(privateClass.isPrivate);

  var privateField = privateClass.declarations[const Symbol('_privateField')];
  Expect.isNotNull(privateField);
  Expect.isTrue(privateField is VariableMirror);
  Expect.isTrue(privateField.isPrivate);

  var privateGetter = privateClass.declarations[const Symbol('_privateGetter')];
  Expect.isNotNull(privateGetter);
  Expect.isTrue(privateGetter is MethodMirror);
  Expect.isTrue(privateGetter.isGetter);
  Expect.isTrue(privateGetter.isPrivate);
  Expect.isFalse(privateGetter.isRegularMethod);

  var privateSetter =
      privateClass.declarations[const Symbol('_privateSetter=')];
  Expect.isNotNull(privateSetter);
  Expect.isTrue(privateSetter is MethodMirror);
  Expect.isTrue(privateSetter.isSetter);
  Expect.isTrue(privateSetter.isPrivate);
  Expect.isFalse(privateSetter.isRegularMethod);

  var privateMethod = privateClass.declarations[const Symbol('_privateMethod')];
  Expect.isNotNull(privateMethod);
  Expect.isTrue(privateMethod is MethodMirror);
  Expect.isTrue(privateMethod.isPrivate);
  Expect.isTrue(privateMethod.isRegularMethod);

  var privateConstructor =
      privateClass.declarations[const Symbol('_privateConstructor')];
  Expect.isNotNull(privateConstructor);
  Expect.isTrue(privateConstructor is MethodMirror);
  Expect.isTrue(privateConstructor.isConstructor);
  Expect.isTrue(privateConstructor.isPrivate);
  Expect.isFalse(privateConstructor.isConstConstructor);
  Expect.isFalse(privateConstructor.isRedirectingConstructor);
  Expect.isTrue(privateConstructor.isGenerativeConstructor);
  Expect.isFalse(privateConstructor.isFactoryConstructor);

  var privateFactoryConstructor =
      privateClass.declarations[const Symbol('_privateFactoryConstructor')];
  Expect.isNotNull(privateFactoryConstructor);
  Expect.isTrue(privateFactoryConstructor is MethodMirror);
  Expect.isTrue(privateFactoryConstructor.isConstructor);
  Expect.isTrue(privateFactoryConstructor.isPrivate);
  Expect.isFalse(privateFactoryConstructor.isConstConstructor);
  Expect.isFalse(privateFactoryConstructor.isRedirectingConstructor);
  Expect.isFalse(privateFactoryConstructor.isGenerativeConstructor);
  Expect.isTrue(privateFactoryConstructor.isFactoryConstructor);

  var metadata = privateClass.metadata;
  Expect.isNotNull(metadata);
  Expect.equals(0, metadata.length);
}

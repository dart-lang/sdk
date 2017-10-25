// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.transformation.binding;

import '../../../ast.dart';

class RuntimeLibrary {
  final Library typesLibrary;
  final Library declarationsLibrary;
  final Library interceptorsLibrary;

  final Constructor dynamicTypeConstructor;
  final Constructor interfaceTypeConstructor;
  final Constructor declarationClassConstructor;
  final Constructor functionTypeConstructor;
  final Constructor voidTypeConstructor;

  // The class used to mark instances that implement `$type`.
  final Class markerClass;
  final Class declarationClass;
  final Class reifiedTypeClass;

  DartType get typeType => reifiedTypeClass.rawType;

  final Name variablesFieldName = new Name("variables");

  /// The name of the field to create for the type information. This name is
  /// extracted from the class `HasRuntimeTypeGetter`.
  final Name runtimeTypeName;

  final Procedure asInstanceOfFunction;
  final Procedure isSubtypeOfFunction;
  final Procedure typeArgumentsFunction;
  final Procedure allocateDeclarationsFunction;
  final Procedure initFunction;
  final Procedure interceptorFunction;
  final Procedure reifyFunction;
  final Procedure attachTypeFunction;

  factory RuntimeLibrary(Library typesLibrary, Library declarationsLibrary,
      Library interceptorsLibrary) {
    Class dynamicTypeClass;
    Class interfaceTypeClass;
    Class declarationClass;
    Class functionTypeClass;
    Class voidTypeClass;
    Class markerClass;
    Class reifiedTypeClass;

    Procedure allocateDeclarationsFunction;
    Procedure initFunction;
    Procedure interceptorFunction;
    Procedure reifyFunction;
    Procedure attachTypeFunction;
    Procedure asInstanceOfFunction;
    Procedure isSubtypeOfFunction;
    Procedure typeArgumentsFunction;

    for (Procedure p in interceptorsLibrary.procedures) {
      if (p.name.name == "type") {
        interceptorFunction = p;
      } else if (p.name.name == "reify") {
        reifyFunction = p;
      } else if (p.name.name == "attachType") {
        attachTypeFunction = p;
      }
    }
    for (Class c in interceptorsLibrary.classes) {
      if (c.name == "HasRuntimeTypeGetter") {
        markerClass = c;
      }
    }
    for (Class c in typesLibrary.classes) {
      if (c.name == 'Dynamic') {
        dynamicTypeClass = c;
      } else if (c.name == 'Interface') {
        interfaceTypeClass = c;
      } else if (c.name == 'FunctionType') {
        functionTypeClass = c;
      } else if (c.name == 'Void') {
        voidTypeClass = c;
      } else if (c.name == 'ReifiedType') {
        reifiedTypeClass = c;
      }
    }
    for (Procedure p in typesLibrary.procedures) {
      if (p.name.name == "asInstanceOf") {
        asInstanceOfFunction = p;
      } else if (p.name.name == "isSubtypeOf") {
        isSubtypeOfFunction = p;
      } else if (p.name.name == "getTypeArguments") {
        typeArgumentsFunction = p;
      }
    }
    for (Procedure p in declarationsLibrary.procedures) {
      if (p.name.name == "allocateDeclarations") {
        allocateDeclarationsFunction = p;
      } else if (p.name.name == "init") {
        initFunction = p;
      }
    }
    for (Class c in declarationsLibrary.classes) {
      if (c.name == 'Class') {
        declarationClass = c;
      }
    }

    assert(dynamicTypeClass != null);
    assert(declarationClass != null);
    assert(interfaceTypeClass != null);
    assert(functionTypeClass != null);
    assert(voidTypeClass != null);
    assert(markerClass != null);
    assert(declarationClass != null);
    assert(reifiedTypeClass != null);
    assert(allocateDeclarationsFunction != null);
    assert(initFunction != null);
    assert(interceptorFunction != null);
    assert(reifyFunction != null);
    assert(attachTypeFunction != null);
    assert(asInstanceOfFunction != null);
    assert(isSubtypeOfFunction != null);
    assert(typeArgumentsFunction != null);

    return new RuntimeLibrary._(
        markerClass.procedures.single.name,
        typesLibrary,
        declarationsLibrary,
        interceptorsLibrary,
        markerClass,
        declarationClass,
        reifiedTypeClass,
        dynamicTypeClass.constructors.single,
        interfaceTypeClass.constructors.single,
        declarationClass.constructors.single,
        functionTypeClass.constructors.single,
        voidTypeClass.constructors.single,
        allocateDeclarationsFunction,
        initFunction,
        interceptorFunction,
        reifyFunction,
        attachTypeFunction,
        asInstanceOfFunction,
        isSubtypeOfFunction,
        typeArgumentsFunction);
  }

  RuntimeLibrary._(
      this.runtimeTypeName,
      this.typesLibrary,
      this.declarationsLibrary,
      this.interceptorsLibrary,
      this.markerClass,
      this.declarationClass,
      this.reifiedTypeClass,
      this.dynamicTypeConstructor,
      this.interfaceTypeConstructor,
      this.declarationClassConstructor,
      this.functionTypeConstructor,
      this.voidTypeConstructor,
      this.allocateDeclarationsFunction,
      this.initFunction,
      this.interceptorFunction,
      this.reifyFunction,
      this.attachTypeFunction,
      this.asInstanceOfFunction,
      this.isSubtypeOfFunction,
      this.typeArgumentsFunction);

  /// Returns `true` if [node] is defined in the runtime library.
  bool contains(TreeNode node) {
    while (node is! Library) {
      node = node.parent;
      if (node == null) return false;
    }
    return node == typesLibrary || node == declarationsLibrary;
  }
}

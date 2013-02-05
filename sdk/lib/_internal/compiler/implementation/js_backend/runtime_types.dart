// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  Iterable<ClassElement> operator[](ClassElement element);
  // Get the iterator for all classes that need type checks.
  Iterator<ClassElement> get iterator;
}

class RuntimeTypeInformation {
  final Compiler compiler;

  RuntimeTypeInformation(this.compiler);

  /// Contains the classes of all arguments that have been used in
  /// instantiations and checks.
  Set<ClassElement> allArguments;

  bool isJsNative(Element element) {
    return (element == compiler.intClass ||
            element == compiler.boolClass ||
            element == compiler.numClass ||
            element == compiler.doubleClass ||
            element == compiler.stringClass ||
            element == compiler.listClass ||
            element == compiler.objectClass ||
            element == compiler.dynamicClass);
  }

  TypeChecks computeRequiredChecks() {
    Set<ClassElement> instantiatedArguments = new Set<ClassElement>();
    for (DartType type in compiler.codegenWorld.instantiatedTypes) {
      addAllInterfaceTypeArguments(type, instantiatedArguments);
    }

    Set<ClassElement> checkedArguments = new Set<ClassElement>();
    for (DartType type in compiler.enqueuer.codegen.universe.isChecks) {
      addAllInterfaceTypeArguments(type, checkedArguments);
    }

    allArguments = new Set<ClassElement>.from(instantiatedArguments)
        ..addAll(checkedArguments);

    TypeCheckMapping requiredChecks = new TypeCheckMapping();
    for (ClassElement element in instantiatedArguments) {
      if (element == compiler.dynamicClass) continue;
      if (checkedArguments.contains(element)) {
        requiredChecks.add(element, element);
      }
      // Find all supertypes of [element] in [checkedArguments] and add checks.
      for (DartType supertype in element.allSupertypes) {
        ClassElement superelement = supertype.element;
        if (checkedArguments.contains(superelement)) {
          requiredChecks.add(element, superelement);
        }
      }
    }

    return requiredChecks;
  }

  void addAllInterfaceTypeArguments(DartType type, Set<ClassElement> classes) {
    if (type is !InterfaceType) return;
    for (DartType argument in type.typeArguments) {
      forEachInterfaceType(argument, (InterfaceType t) {
        ClassElement cls = t.element;
        if (cls != compiler.dynamicClass && cls != compiler.objectClass) {
          classes.add(cls);
        }
      });
    }
  }

  void forEachInterfaceType(DartType type, f(InterfaceType type)) {
    if (type.kind == TypeKind.INTERFACE) {
      f(type);
      InterfaceType interface = type;
      for (DartType argument in interface.typeArguments) {
        forEachInterfaceType(argument, f);
      }
    }
  }

  /// Return the unique name for the element as an unquoted string.
  String getNameAsString(Element element) {
    JavaScriptBackend backend = compiler.backend;
    return backend.namer.getName(element);
  }

  /// Return the unique JS name for the element, which is a quoted string for
  /// native classes and the isolate acccess to the constructor for classes.
  String getJsName(Element element) {
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    return namer.isolateAccess(element);
  }

  String getRawTypeRepresentation(DartType type) {
    String name = getNameAsString(type.element);
    if (!type.element.isClass()) return name;
    InterfaceType interface = type;
    Link<DartType> variables = interface.element.typeVariables;
    if (variables.isEmpty) return name;
    List<String> arguments = [];
    variables.forEach((_) => arguments.add('dynamic'));
    return '$name<${Strings.join(arguments, ', ')}>';
  }

  String getTypeRepresentation(DartType type, void onVariable(variable)) {
    StringBuffer builder = new StringBuffer();
    void build(DartType part) {
      if (part is TypeVariableType) {
        builder.add('#');
        onVariable(part);
      } else {
        bool hasArguments = part is InterfaceType && !part.isRaw;
        Element element = part.element;
        if (hasArguments) {
          builder.add('[');
        }
        builder.add(getJsName(element));
        if (!hasArguments) return;
        InterfaceType interface = part;
        for (DartType argument in interface.typeArguments) {
          builder.add(', ');
          build(argument);
        }
        builder.add(']');
      }
    }
    build(type);
    return builder.toString();
  }

  static bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.isRaw;
    }
    return false;
  }

  static int getTypeVariableIndex(TypeVariableType variable) {
    ClassElement classElement = variable.element.getEnclosingClass();
    Link<DartType> variables = classElement.typeVariables;
    for (int index = 0; !variables.isEmpty;
         index++, variables = variables.tail) {
      if (variables.head == variable) return index;
    }
  }
}

class TypeCheckMapping implements TypeChecks {
  final Map<ClassElement, Set<ClassElement>> map =
      new Map<ClassElement, Set<ClassElement>>();

  Iterable<ClassElement> operator[](ClassElement element) {
    Set<ClassElement> result = map[element];
    return result != null ? result : const <ClassElement>[];
  }

  void add(ClassElement cls, ClassElement check) {
    map.putIfAbsent(cls, () => new Set<ClassElement>());
    map[cls].add(check);
  }

  Iterator<ClassElement> get iterator => map.keys.iterator;
}

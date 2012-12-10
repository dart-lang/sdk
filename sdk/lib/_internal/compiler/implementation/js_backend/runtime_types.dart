// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class RuntimeTypeInformation {
  final Compiler compiler;

  RuntimeTypeInformation(this.compiler);

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
    if (element.isClass()) {
      ClassElement cls = element;
      // If the class is not instantiated, we will not generate code for it and
      // thus cannot refer to its constructor. For now, use a string instead of
      // a reference to the constructor.
      // TODO(karlklose): remove this and record classes that we need only
      // for runtime types and emit structures for them.
      Universe universe = compiler.enqueuer.resolution.universe;
      if (!universe.instantiatedClasses.contains(cls)) {
        return "'${namer.isolateAccess(element)}'";
      }
    }
   return isJsNative(element) ? "'${element.name.slowToString()}'"
                               : namer.isolateAccess(element);
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

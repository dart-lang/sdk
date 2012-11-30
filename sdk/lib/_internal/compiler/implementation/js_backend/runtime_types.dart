// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class RuntimeTypeInformation {
  final Compiler compiler;

  RuntimeTypeInformation(this.compiler);

  // TODO(karlklose): remove when using type representations.
  String getStringRepresentation(DartType type, {bool expandRawType: false}) {
    StringBuffer builder = new StringBuffer();
    void build(DartType t) {
      if (t is TypeVariableType) {
        builder.add(t.name.slowToString());
        return;
      }
      JavaScriptBackend backend = compiler.backend;
      builder.add(backend.namer.getName(t.element));
      if (t is InterfaceType) {
        InterfaceType interface = t;
        ClassElement element = t.element;
        if (element.typeVariables.isEmpty) return;
        bool isRaw = interface.isRaw;
        if (isRaw && !expandRawType) return;
        builder.add('<');
        Iterable items = interface.typeArguments;
        var stringify = isRaw ? (_) => 'dynamic' : (type) => type.toString();
        bool first = true;
        for (var item in items) {
          if (first) {
            first = false;
          } else {
            builder.add(', ');
          }
          builder.add(stringify(item));
        }
        builder.add('>');
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

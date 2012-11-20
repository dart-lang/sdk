// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library runtime_types;

import '../dart2jslib.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart';

class RuntimeTypeInformation {
  /**
   * Names used for elements in runtime type information. This map is kept to
   * detect elements with the same name and use a different name instead.
   */
  final Map<String, Element> usedNames = new Map<String, Element>();

  final Compiler compiler;

  RuntimeTypeInformation(this.compiler) {
    // Reserve the name 'dynamic' for the dynamic type.
    usedNames['dynamic'] = compiler.dynamicClass;
  }

  /** Get a unique name for the element. */
  String getName(Element element) {
    if (element == compiler.dynamicClass) return 'dynamic';
    String guess = element.name.slowToString();
    String name = guess;
    int id = 0;
    while (usedNames.containsKey(name) && usedNames[name] != element) {
      name = '$guess@$id';
      id++;
    }
    usedNames[name] = element;
    return name;
  }

  // TODO(karlklose): remove when using type representations.
  String buildStringRepresentation(DartType type) {
    StringBuffer builder = new StringBuffer();
    void build(DartType t) {
      builder.add(getName(t.element));
      if (t is InterfaceType) {
        InterfaceType interface = t;
        if (interface.arguments.isEmpty) return;
        bool firstArgument = true;
        builder.add('<');
        for (DartType argument in interface.arguments) {
          if (firstArgument) {
            firstArgument = false;
          } else {
            builder.add(', ');
          }
          build(argument);
        }
        builder.add('>');
      }
    }
    build(type);
    return builder.toString();
  }

  bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.arguments.isEmpty;
    }
    return false;
  }

  /**
   * Map type variables to strings calling [:stringify:] and joins the results
   * to a single string separated by commas.
   * The argument [:hasValue:] is used to treat variables that will not receive
   * a value at the use site of the code that is generated with this function.
   */
  static String stringifyTypeVariables(Link collection,
                                       int numberOfInputs,
                                       stringify(TypeVariableType variable,
                                                 bool hasValue)) {
    int currentVariable = 0;
    bool isFirst = true;
    StringBuffer buffer = new StringBuffer();
    collection.forEach((TypeVariableType variable) {
      if (!isFirst) buffer.add(", ");
      bool hasValue = currentVariable < numberOfInputs;
      buffer.add(stringify(variable, hasValue));
      isFirst = false;
      currentVariable++;
    });
    return buffer.toString();
  }

  /**
   * Generate a string representation template for this element, using '#' to
   * denote the place for the type argument input. If there are more type
   * variables than [numberOfInputs], 'dynamic' is used as the value for these
   * arguments.
   */
  String generateRuntimeTypeString(ClassElement element, int numberOfInputs) {
    String elementName = getName(element);
    if (element.typeVariables.isEmpty) return "$elementName";
    String stringify(_, bool hasValue) => hasValue ? "' + # + '" : "dynamic";
    String arguments = stringifyTypeVariables(element.typeVariables,
                                              numberOfInputs,
                                              stringify);
    return "$elementName<$arguments>";
  }

  /**
   * Generate a string template for the runtime type fields that contain the
   * type descriptions of the reified type arguments, using '#' to denote the
   * place for the type argument value, or [:null:] if there are more than
   * [numberOfInputs] type variables.
   */
  static String generateTypeVariableString(ClassElement element,
                                           int numberOfInputs) {
    String stringify(TypeVariableType variable, bool hasValue) {
      return "'${variable.name.slowToString()}': #";
    }
    return stringifyTypeVariables(element.typeVariables, numberOfInputs,
                                  stringify);
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('runtime_types');

#import('leg.dart');
#import('elements/elements.dart');
#import('tree/tree.dart');
#import('universe/universe.dart');
#import('util/util.dart');

class RuntimeTypeInformation {
  bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.arguments.isEmpty();
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
   * variables than [numberOfInputs], 'Dynamic' is used as the value for these
   * arguments.
   */
  static String generateRuntimeTypeString(ClassElement element,
                                          int numberOfInputs) {
    String elementName = element.name.slowToString();
    if (element.typeVariables.isEmpty()) return "'$elementName'";
    String stringify(_, bool hasValue) => hasValue ? "' + # + '" : "Dynamic";
    String arguments = stringifyTypeVariables(element.typeVariables,
                                              numberOfInputs,
                                              stringify);
    return "'$elementName<$arguments>'";
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

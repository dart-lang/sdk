// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('ssa');

#import('../leg.dart');
#import('../native_handler.dart', prefix: 'native');
#import('../source_file.dart');
#import('../source_map_builder.dart');
#import('../elements/elements.dart');
#import('../scanner/scannerlib.dart');
#import('../tree/tree.dart');
#import('../util/util.dart');
#import('../util/characters.dart');

#source('bailout.dart');
#source('builder.dart');
#source('closure.dart');
#source('codegen.dart');
#source('codegen_helpers.dart');
#source('js_names.dart');
#source('nodes.dart');
#source('optimize.dart');
#source('types.dart');
#source('types_propagation.dart');
#source('validate.dart');
#source('variable_allocator.dart');
#source('value_set.dart');

class RuntimeTypeInformation {
  String asJsString(InterfaceType type) {
    ClassElement element = type.element;
    StringBuffer buffer = new StringBuffer();
    Link<Type> arguments = type.arguments;
    Link<Type> typeVariables = element.typeVariables;
    while (!typeVariables.isEmpty()) {
      TypeVariableType typeVariable = typeVariables.head;
      // TODO(johnniwinther): Retrieve the type name properly and not through
      // [toString]. Note: Two cases below [typeVariable] and [arguments.head].
      buffer.add("${typeVariable}: '${arguments.head}'");
      typeVariables = typeVariables.tail;
      if (!typeVariables.isEmpty()) {
        buffer.add(', ');
      }
    }
    return "{$buffer}";
  }

  bool hasTypeArguments(Type type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return (!interfaceType.arguments.isEmpty() &&
              interfaceType.arguments.tail.isEmpty());
    }
    return false;
  }
}

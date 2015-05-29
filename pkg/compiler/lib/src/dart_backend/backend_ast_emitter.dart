// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library backend_ast_emitter;

import 'backend_ast_nodes.dart';
import '../dart_types.dart';
import '../elements/elements.dart';

class TypeGenerator {

  /// TODO(johnniwinther): Remove this when issue 21283 has been resolved.
  static int pseudoNameCounter = 0;

  static Parameter emitParameter(DartType type,
                                 {String name,
                                  Element element}) {
    if (name == null && element != null) {
      name = element.name;
    }
    if (name == null) {
      name = '_${pseudoNameCounter++}';
    }
    Parameter parameter;
    if (type.isFunctionType) {
      FunctionType functionType = type;
      TypeAnnotation returnType = createOptionalType(functionType.returnType);
      Parameters innerParameters =
          createParametersFromType(functionType);
      parameter = new Parameter.function(name, returnType, innerParameters);
    } else {
      TypeAnnotation typeAnnotation = createOptionalType(type);
      parameter = new Parameter(name, type: typeAnnotation);
    }
    parameter.element = element;
    return parameter;
  }

  static Parameters createParametersFromType(FunctionType functionType) {
    pseudoNameCounter = 0;
    if (functionType.namedParameters.isEmpty) {
      return new Parameters(
          createParameters(functionType.parameterTypes),
          createParameters(functionType.optionalParameterTypes),
          false);
    } else {
      return new Parameters(
          createParameters(functionType.parameterTypes),
          createParameters(functionType.namedParameterTypes,
                         names: functionType.namedParameters),
          true);
    }
  }

  static List<Parameter> createParameters(
      Iterable<DartType> parameterTypes,
      {Iterable<String> names: const <String>[],
       Iterable<Element> elements: const <Element>[]}) {
    Iterator<String> name = names.iterator;
    Iterator<Element> element = elements.iterator;
    return parameterTypes.map((DartType type) {
      name.moveNext();
      element.moveNext();
      return emitParameter(type,
                           name: name.current,
                           element: element.current);
    }).toList();
  }

  /// Like [createTypeAnnotation] except the dynamic type is converted to null.
  static TypeAnnotation createOptionalType(DartType type) {
    if (type.treatAsDynamic) {
      return null;
    } else {
      return createType(type);
    }
  }

  /// Creates the [TypeAnnotation] for a [type] that is not function type.
  static TypeAnnotation createType(DartType type) {
    if (type is GenericType) {
      if (type.treatAsRaw) {
        return new TypeAnnotation(type.element.name)..dartType = type;
      }
      return new TypeAnnotation(
          type.element.name,
          type.typeArguments.map(createType).toList(growable:false))
          ..dartType = type;
    } else if (type is VoidType) {
      return new TypeAnnotation('void')
          ..dartType = type;
    } else if (type is TypeVariableType) {
      return new TypeAnnotation(type.name)
          ..dartType = type;
    } else if (type is DynamicType) {
      return new TypeAnnotation("dynamic")
          ..dartType = type;
    } else if (type is MalformedType) {
      return new TypeAnnotation(type.name)
          ..dartType = type;
    } else {
      throw "Unsupported type annotation: $type";
    }
  }
}

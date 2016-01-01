// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Utilities for converting Dart entities into analysis server's protocol
 * entities.
 */
library analysis_server.plugin.protocol.protocol_dart;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;

/**
 * Return a protocol [Element] corresponding to the given [engine.Element].
 */
Element convertElement(engine.Element element) {
  String name = element.displayName;
  String elementTypeParameters = _getTypeParametersString(element);
  String elementParameters = _getParametersString(element);
  String elementReturnType = getReturnTypeString(element);
  ElementKind kind = convertElementToElementKind(element);
  return new Element(
      kind,
      name,
      Element.makeFlags(
          isPrivate: element.isPrivate,
          isDeprecated: element.isDeprecated,
          isAbstract: _isAbstract(element),
          isConst: _isConst(element),
          isFinal: _isFinal(element),
          isStatic: _isStatic(element)),
      location: newLocation_fromElement(element),
      typeParameters: elementTypeParameters,
      parameters: elementParameters,
      returnType: elementReturnType);
}

/**
 * Return a protocol [ElementKind] corresponding to the given
 * [engine.ElementKind].
 *
 * This does not take into account that an instance of [ClassElement] can be an
 * enum and an instance of [FieldElement] can be an enum constant.
 * Use [convertElementToElementKind] where possible.
 */
ElementKind convertElementKind(engine.ElementKind kind) {
  if (kind == engine.ElementKind.CLASS) {
    return ElementKind.CLASS;
  }
  if (kind == engine.ElementKind.COMPILATION_UNIT) {
    return ElementKind.COMPILATION_UNIT;
  }
  if (kind == engine.ElementKind.CONSTRUCTOR) {
    return ElementKind.CONSTRUCTOR;
  }
  if (kind == engine.ElementKind.FIELD) {
    return ElementKind.FIELD;
  }
  if (kind == engine.ElementKind.FUNCTION) {
    return ElementKind.FUNCTION;
  }
  if (kind == engine.ElementKind.FUNCTION_TYPE_ALIAS) {
    return ElementKind.FUNCTION_TYPE_ALIAS;
  }
  if (kind == engine.ElementKind.GETTER) {
    return ElementKind.GETTER;
  }
  if (kind == engine.ElementKind.LABEL) {
    return ElementKind.LABEL;
  }
  if (kind == engine.ElementKind.LIBRARY) {
    return ElementKind.LIBRARY;
  }
  if (kind == engine.ElementKind.LOCAL_VARIABLE) {
    return ElementKind.LOCAL_VARIABLE;
  }
  if (kind == engine.ElementKind.METHOD) {
    return ElementKind.METHOD;
  }
  if (kind == engine.ElementKind.PARAMETER) {
    return ElementKind.PARAMETER;
  }
  if (kind == engine.ElementKind.PREFIX) {
    return ElementKind.PREFIX;
  }
  if (kind == engine.ElementKind.SETTER) {
    return ElementKind.SETTER;
  }
  if (kind == engine.ElementKind.TOP_LEVEL_VARIABLE) {
    return ElementKind.TOP_LEVEL_VARIABLE;
  }
  if (kind == engine.ElementKind.TYPE_PARAMETER) {
    return ElementKind.TYPE_PARAMETER;
  }
  return ElementKind.UNKNOWN;
}

/**
 * Return an [ElementKind] corresponding to the given [engine.Element].
 */
ElementKind convertElementToElementKind(engine.Element element) {
  if (element is engine.ClassElement && element.isEnum) {
    return ElementKind.ENUM;
  }
  if (element is engine.FieldElement &&
      element.isEnumConstant &&
      // MyEnum.values and MyEnum.one.index return isEnumConstant = true
      // so these additional checks are necessary.
      // TODO(danrubel) MyEnum.values is constant, but is a list
      // so should it return isEnumConstant = true?
      // MyEnum.one.index is final but *not* constant
      // so should it return isEnumConstant = true?
      // Or should we return ElementKind.ENUM_CONSTANT here
      // in either or both of these cases?
      element.type != null &&
      element.type.element == element.enclosingElement) {
    return ElementKind.ENUM_CONSTANT;
  }
  return convertElementKind(element.kind);
}

String _getParametersString(engine.Element element) {
  // TODO(scheglov) expose the corresponding feature from ExecutableElement
  List<engine.ParameterElement> parameters;
  if (element is engine.ExecutableElement) {
    // valid getters don't have parameters
    if (element.kind == engine.ElementKind.GETTER &&
        element.parameters.isEmpty) {
      return null;
    }
    parameters = element.parameters;
  } else if (element is engine.FunctionTypeAliasElement) {
    parameters = element.parameters;
  } else {
    return null;
  }
  StringBuffer sb = new StringBuffer();
  String closeOptionalString = '';
  for (engine.ParameterElement parameter in parameters) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    if (closeOptionalString.isEmpty) {
      engine.ParameterKind kind = parameter.parameterKind;
      if (kind == engine.ParameterKind.NAMED) {
        sb.write('{');
        closeOptionalString = '}';
      }
      if (kind == engine.ParameterKind.POSITIONAL) {
        sb.write('[');
        closeOptionalString = ']';
      }
    }
    parameter.appendToWithoutDelimiters(sb);
  }
  sb.write(closeOptionalString);
  return '(' + sb.toString() + ')';
}

String _getTypeParametersString(engine.Element element) {
  List<engine.TypeParameterElement> typeParameters;
  if (element is engine.ClassElement) {
    typeParameters = element.typeParameters;
  } else if (element is engine.FunctionTypeAliasElement) {
    typeParameters = element.typeParameters;
  }
  if (typeParameters == null || typeParameters.isEmpty) {
    return null;
  }
  return '<${typeParameters.join(', ')}>';
}

bool _isAbstract(engine.Element element) {
  // TODO(scheglov) add isAbstract to Element API
  if (element is engine.ClassElement) {
    return element.isAbstract;
  }
  if (element is engine.MethodElement) {
    return element.isAbstract;
  }
  if (element is engine.PropertyAccessorElement) {
    return element.isAbstract;
  }
  return false;
}

bool _isConst(engine.Element element) {
  // TODO(scheglov) add isConst to Element API
  if (element is engine.ConstructorElement) {
    return element.isConst;
  }
  if (element is engine.VariableElement) {
    return element.isConst;
  }
  return false;
}

bool _isFinal(engine.Element element) {
  // TODO(scheglov) add isFinal to Element API
  if (element is engine.VariableElement) {
    return element.isFinal;
  }
  return false;
}

bool _isStatic(engine.Element element) {
  // TODO(scheglov) add isStatic to Element API
  if (element is engine.ExecutableElement) {
    return element.isStatic;
  }
  if (element is engine.PropertyInducingElement) {
    return element.isStatic;
  }
  return false;
}

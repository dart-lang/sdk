// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for converting Dart entities into analysis server's protocol
/// entities.
library;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

/// Return a protocol [Element] corresponding to the given [engine.Element].
Element convertElement(engine.Element element,
    {required bool withNullability}) {
  var kind = convertElementToElementKind(element);
  var name = getElementDisplayName(element);
  var elementTypeParameters = _getTypeParametersString(element);
  var aliasedType =
      getAliasedTypeString(element, withNullability: withNullability);
  var elementParameters =
      _getParametersString(element, withNullability: withNullability);
  var elementReturnType =
      getReturnTypeString(element, withNullability: withNullability);
  return Element(
    kind,
    name,
    Element.makeFlags(
      isPrivate: element.isPrivate,
      isDeprecated: element.hasDeprecated,
      isAbstract: _isAbstract(element),
      isConst: _isConst(element),
      isFinal: _isFinal(element),
      isStatic: _isStatic(element),
    ),
    location: newLocation_fromElement(element),
    typeParameters: elementTypeParameters,
    aliasedType: aliasedType,
    parameters: elementParameters,
    returnType: elementReturnType,
  );
}

/// Return a protocol [ElementKind] corresponding to the given
/// [engine.ElementKind].
///
/// This does not take into account that an instance of [ClassElement] can be an
/// enum and an instance of [FieldElement] can be an enum constant.
/// Use [convertElementToElementKind] where possible.
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
  if (kind == engine.ElementKind.ENUM) {
    return ElementKind.ENUM;
  }
  if (kind == engine.ElementKind.EXTENSION) {
    return ElementKind.EXTENSION;
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
  if (kind == engine.ElementKind.GENERIC_FUNCTION_TYPE) {
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
  if (kind == engine.ElementKind.PART) {
    return ElementKind.COMPILATION_UNIT;
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
  if (kind == engine.ElementKind.TYPE_ALIAS) {
    return ElementKind.TYPE_ALIAS;
  }
  if (kind == engine.ElementKind.TYPE_PARAMETER) {
    return ElementKind.TYPE_PARAMETER;
  }
  return ElementKind.UNKNOWN;
}

/// Return an [ElementKind] corresponding to the given [engine.Element].
ElementKind convertElementToElementKind(engine.Element element) {
  if (element is engine.EnumElement) {
    return ElementKind.ENUM;
  } else if (element is engine.MixinElement) {
    return ElementKind.MIXIN;
  }
  if (element is engine.FieldElement && element.isEnumConstant) {
    return ElementKind.ENUM_CONSTANT;
  }
  return convertElementKind(element.kind);
}

String getElementDisplayName(engine.Element element) {
  if (element is engine.CompilationUnitElement) {
    return path.basename(element.source.fullName);
  } else {
    return element.displayName;
  }
}

String? _getParametersString(engine.Element element,
    {required bool withNullability}) {
  // TODO(scheglov) expose the corresponding feature from ExecutableElement
  List<engine.ParameterElement> parameters;
  if (element is engine.ExecutableElement) {
    // valid getters don't have parameters
    if (element.kind == engine.ElementKind.GETTER &&
        element.parameters.isEmpty) {
      return null;
    }
    parameters = element.parameters.toList();
  } else if (element is engine.TypeAliasElement) {
    final aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      parameters = aliasedType.parameters.toList();
    } else {
      return null;
    }
  } else {
    return null;
  }

  parameters.sort(_preferRequiredParams);

  var sb = StringBuffer();
  var closeOptionalString = '';
  for (var parameter in parameters) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    if (closeOptionalString.isEmpty) {
      if (parameter.isNamed) {
        sb.write('{');
        closeOptionalString = '}';
      } else if (parameter.isOptionalPositional) {
        sb.write('[');
        closeOptionalString = ']';
      }
    }
    if (parameter.isRequiredNamed) {
      sb.write('required ');
    } else if (parameter.hasRequired) {
      sb.write('@required ');
    }
    parameter.appendToWithoutDelimiters(sb, withNullability: withNullability);
  }
  sb.write(closeOptionalString);
  return '($sb)';
}

String? _getTypeParametersString(engine.Element element) {
  List<engine.TypeParameterElement>? typeParameters;
  if (element is engine.InterfaceElement) {
    typeParameters = element.typeParameters;
  } else if (element is engine.TypeAliasElement) {
    typeParameters = element.typeParameters;
  }
  if (typeParameters == null || typeParameters.isEmpty) {
    return null;
  }
  return '<${typeParameters.join(', ')}>';
}

bool _isAbstract(engine.Element element) {
  if (element is engine.ClassElement) {
    return element.isAbstract;
  }
  if (element is engine.MethodElement) {
    return element.isAbstract;
  }
  if (element is engine.MixinElement) {
    return true;
  }
  if (element is engine.PropertyAccessorElement) {
    return element.isAbstract;
  }
  return false;
}

bool _isConst(engine.Element element) {
  if (element is engine.ConstructorElement) {
    return element.isConst;
  }
  if (element is engine.VariableElement) {
    return element.isConst;
  }
  return false;
}

bool _isFinal(engine.Element element) {
  if (element is engine.VariableElement) {
    return element.isFinal;
  }
  return false;
}

bool _isStatic(engine.Element element) {
  if (element is engine.ExecutableElement) {
    return element.isStatic;
  }
  if (element is engine.PropertyInducingElement) {
    return element.isStatic;
  }
  return false;
}

/// Sort required named parameters before optional ones.
int _preferRequiredParams(
    engine.ParameterElement e1, engine.ParameterElement e2) {
  var rank1 = (e1.isRequiredNamed || e1.hasRequired)
      ? 0
      : !e1.isNamed
          ? -1
          : 1;
  var rank2 = (e2.isRequiredNamed || e2.hasRequired)
      ? 0
      : !e2.isNamed
          ? -1
          : 1;
  return rank1 - rank2;
}

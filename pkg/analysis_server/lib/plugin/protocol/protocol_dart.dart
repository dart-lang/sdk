// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for converting Dart entities into analysis server's protocol
/// entities.
library;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:path/path.dart' as path;

Element convertElement(engine.Element element) {
  var kind = convertElementToElementKind(element);
  var name = getElementDisplayName(element);
  var elementTypeParameters = _getTypeParametersString(element);
  var aliasedType = getAliasedTypeString(element);
  var elementParameters = getParametersString(element);
  var elementReturnType = getReturnTypeString(element);
  var extendedType = getExtendedTypeString(element);
  return Element(
    kind,
    name,
    Element.makeFlags(
      isPrivate: element.isPrivate,
      isDeprecated: element.isDeprecatedWithKind('use'),
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
    extendedType: extendedType,
  );
}

/// Return a protocol [ElementKind] corresponding to the given
/// [engine.ElementKind].
///
/// This does not take into account that an instance of [engine.ClassElement]
/// can be an enum and an instance of [engine.FieldElement] can be an enum
/// constant. Use [convertElementToElementKind] where possible.
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
  if (kind == engine.ElementKind.EXTENSION_TYPE) {
    return ElementKind.EXTENSION_TYPE;
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
  if (kind == engine.ElementKind.MIXIN) {
    return ElementKind.MIXIN;
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

Element convertLibraryFragment(LibraryFragmentImpl fragment) {
  return Element(
    ElementKind.COMPILATION_UNIT,
    path.basename(fragment.source.fullName),
    Element.makeFlags(
      isPrivate: fragment.isPrivate,
      isDeprecated: fragment.library.isDeprecatedWithKind('use'),
    ),
    location: newLocation_fromFragment(fragment),
  );
}

String getElementDisplayName(engine.Element element) {
  if (element is engine.LibraryFragment) {
    return path.basename((element as engine.LibraryFragment).source.fullName);
  } else {
    return element.displayName;
  }
}

String getParametersListString(List<engine.FormalParameterElement> parameters) {
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
    } else if (parameter.metadata.hasDeprecated) {
      sb.write('@required ');
    }
    parameter.appendToWithoutDelimiters(sb);
  }
  sb.write(closeOptionalString);
  return '($sb)';
}

String? getParametersString(engine.Element element) {
  // TODO(scheglov): expose the corresponding feature from ExecutableElement
  List<engine.FormalParameterElement> parameters;
  if (element is engine.ExecutableElement) {
    // valid getters don't have parameters
    if (element.kind == engine.ElementKind.GETTER &&
        element.formalParameters.isEmpty) {
      return null;
    }
    parameters = element.formalParameters.toList();
  } else if (element is engine.TypeAliasElement) {
    var aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      parameters = aliasedType.formalParameters.toList();
    } else {
      return null;
    }
  } else {
    return null;
  }

  return getParametersListString(parameters);
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
  engine.FormalParameterElement e1,
  engine.FormalParameterElement e2,
) {
  var rank1 = (e1.isRequiredNamed || e1.metadata.hasRequired)
      ? 0
      : !e1.isNamed
      ? -1
      : 1;
  var rank2 = (e2.isRequiredNamed || e2.metadata.hasRequired)
      ? 0
      : !e2.isNamed
      ? -1
      : 1;
  return rank1 - rank2;
}

// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of utility methods used by completion contributors.
library;

import 'package:analysis_server/src/protocol_server.dart' show Location;
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    as protocol
    show Element, ElementKind;

/// The name of the type `dynamic`;
const DYNAMIC = 'dynamic';

/// Sort by relevance first, highest to lowest, and then by the completion
/// alphabetically.
Comparator<CompletionSuggestionBuilder> completionComparator = (a, b) {
  if (a.relevance == b.relevance) {
    return a.completion.compareTo(b.completion);
  }
  return b.relevance.compareTo(a.relevance);
};

String buildClosureParameters(
  FunctionType type, {
  required bool includeTypes,
  required bool includeKeywords,
}) {
  var buffer = StringBuffer();
  buffer.write('(');

  var hasNamed = false;
  var hasOptionalPositional = false;
  var parameters = type.formalParameters;
  var existingNames = parameters.map((p) => p.displayName).toSet();
  for (var i = 0; i < parameters.length; ++i) {
    var parameter = parameters[i];
    if (i != 0) {
      buffer.write(', ');
    }
    if (parameter.isNamed && !hasNamed) {
      hasNamed = true;
      buffer.write('{');
    } else if (parameter.isOptionalPositional && !hasOptionalPositional) {
      hasOptionalPositional = true;
      buffer.write('[');
    }
    if (includeTypes) {
      buffer.write(parameter.type);
      buffer.write(' ');
    }
    var name = parameter.displayName;
    if (name.isEmpty) {
      name = 'p$i';
      var index = 1;
      while (existingNames.contains(name)) {
        name = 'p${i}_$index';
        index++;
      }
    }

    if (includeKeywords && parameter.isRequiredNamed) {
      buffer.write('required ');
    }
    buffer.write(name);
  }

  if (hasNamed) {
    buffer.write('}');
  } else if (hasOptionalPositional) {
    buffer.write(']');
  }

  buffer.write(')');
  return buffer.toString();
}

/// Compute default argument list text and ranges based on the given
/// [requiredParams] and [namedParams].
CompletionDefaultArgumentList computeCompletionDefaultArgumentList(
  Element2 element,
  Iterable<FormalParameterElement> requiredParams,
  Iterable<FormalParameterElement> namedParams,
) {
  var sb = StringBuffer();
  var ranges = <int>[];

  int offset;

  for (var param in requiredParams) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    offset = sb.length;

    var name = param.displayName;
    sb.write(name);
    ranges.addAll([offset, name.length]);
  }

  for (var param in namedParams) {
    if (param.metadata2.hasRequired || param.isRequiredNamed) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      var name = param.displayName;
      sb.write('$name: ');
      offset = sb.length;
      // TODO(pq): fix to use getDefaultStringParameterValue()
      sb.write(name);
      ranges.addAll([offset, name.length]);
    }
  }

  return CompletionDefaultArgumentList(
    text: sb.isNotEmpty ? sb.toString() : null,
    ranges: ranges.isNotEmpty ? ranges : null,
  );
}

/// Create a new protocol Element for inclusion in a completion suggestion.
protocol.Element createLocalElement(
  Source source,
  protocol.ElementKind kind,
  SimpleIdentifier id, {
  String? parameters,
  TypeAnnotation? returnType,
  bool isAbstract = false,
  bool isDeprecated = false,
}) {
  var name = id.name;
  // TODO(danrubel): use lineInfo to determine startLine and startColumn
  var location = Location(
    source.fullName,
    id.offset,
    id.length,
    0,
    0,
    endLine: 0,
    endColumn: 0,
  );
  var flags = protocol.Element.makeFlags(
    isAbstract: isAbstract,
    isDeprecated: isDeprecated,
    isPrivate: Identifier.isPrivateName(name),
  );
  return protocol.Element(
    kind,
    name,
    flags,
    location: location,
    parameters: parameters,
    returnType: nameForType(id, returnType),
  );
}

/// Return a default argument value for the given [parameter].
DefaultArgument? getDefaultStringParameterValue(
  FormalParameterElement parameter,
  String quote,
) {
  var type = parameter.type;
  if (type is InterfaceType) {
    if (type.isDartCoreList) {
      return DefaultArgument('[]', cursorPosition: 1);
    } else if (type.isDartCoreMap) {
      return DefaultArgument('{}', cursorPosition: 1);
    } else if (type.isDartCoreString) {
      return DefaultArgument('$quote$quote', cursorPosition: 1);
    }
  } else if (type is FunctionType) {
    var params = type.formalParameters
        .map((p) => '${getTypeString(p.type)}${p.displayName}')
        .join(', ');
    // TODO(devoncarew): Support having this method return text with newlines.
    var text = '($params) {  }';
    return DefaultArgument(text, cursorPosition: text.length - 2);
  }
  return null;
}

String getRequestLineIndent(DartCompletionRequest request) {
  var content = request.content;
  var lineStartOffset = request.offset;
  var notWhitespaceOffset = request.offset;
  for (; lineStartOffset > 0; lineStartOffset--) {
    var char = content.substring(lineStartOffset - 1, lineStartOffset);
    if (char == '\n') {
      break;
    }
    if (char != ' ' && char != '\t') {
      notWhitespaceOffset = lineStartOffset - 1;
    }
  }
  return content.substring(lineStartOffset, notWhitespaceOffset);
}

String getTypeString(DartType type) {
  if (type is DynamicType) {
    return '';
  } else {
    return '${type.getDisplayString()} ';
  }
}

/// Instantiates the given [InterfaceElement2]
InterfaceType instantiateInstanceElement(
  InterfaceElement2 element,
  NeverType neverType,
) {
  var typeParameters = element.typeParameters2;
  var typeArguments = const <DartType>[];
  if (typeParameters.isNotEmpty) {
    typeArguments = List.filled(typeParameters.length, neverType);
  }
  return element.instantiate(
    typeArguments: typeArguments,
    nullabilitySuffix: NullabilitySuffix.none,
  );
}

/// Returns true if the [parameter] is part of a constructor for a Flutter
/// [Widget].
bool isFlutterWidgetParameter(FormalParameterElement parameter) {
  var element = parameter.enclosingElement2;
  if (element is ConstructorElement2 &&
      element.enclosingElement2.isWidget) {
    return true;
  }
  return false;
}

/// Return name of the type of the given [identifier], or, if it unresolved, the
/// name of its declared [declaredType].
String? nameForType(SimpleIdentifier identifier, TypeAnnotation? declaredType) {
  // Get the type from the identifier element.
  DartType type;
  var element = identifier.element;
  if (element == null) {
    return DYNAMIC;
  } else if (element is FunctionTypedElement2) {
    if (element is PropertyAccessorElement2 && element is SetterElement) {
      return null;
    }
    type = element.returnType;
  } else if (element is TypeAliasElement2) {
    var aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      type = aliasedType.returnType;
    } else {
      return null;
    }
  } else if (element is VariableElement2) {
    type = element.type;
  } else {
    return null;
  }

  // If the type is unresolved, use the declared type.
  if (type is DynamicType) {
    if (declaredType is NamedType) {
      return declaredType.qualifiedName;
    }
    return DYNAMIC;
  }
  return type.getDisplayString();
}

class CompletionDefaultArgumentList {
  final String? text;
  final List<int>? ranges;

  CompletionDefaultArgumentList({required this.text, required this.ranges});
}

/// A tuple of text to insert and an (optional) location for the cursor.
class DefaultArgument {
  /// The text to insert.
  final String text;

  /// An optional location for the cursor, relative to the text's start. This
  /// field can be null.
  final int? cursorPosition;

  DefaultArgument(this.text, {this.cursorPosition});
}

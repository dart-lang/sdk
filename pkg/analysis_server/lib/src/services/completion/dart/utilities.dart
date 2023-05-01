// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of utility methods used by completion contributors.
library;

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, Location;
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show Element, ElementKind;

/// The name of the type `dynamic`;
const DYNAMIC = 'dynamic';

/// Sort by relevance first, highest to lowest, and then by the completion
/// alphabetically.
Comparator<CompletionSuggestion> completionComparator = (a, b) {
  if (a.relevance == b.relevance) {
    return a.completion.compareTo(b.completion);
  }
  return b.relevance.compareTo(a.relevance);
};

String buildClosureParameters(FunctionType type) {
  var buffer = StringBuffer();
  buffer.write('(');

  var hasNamed = false;
  var hasOptionalPositional = false;
  var parameters = type.parameters;
  var existingNames = parameters.map((p) => p.name).toSet();
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
    var name = parameter.name;
    if (name.isEmpty) {
      name = 'p$i';
      var index = 1;
      while (existingNames.contains(name)) {
        name = 'p${i}_$index';
        index++;
      }
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
  Element element,
  Iterable<ParameterElement> requiredParams,
  Iterable<ParameterElement> namedParams,
) {
  var sb = StringBuffer();
  var ranges = <int>[];

  int offset;

  for (var param in requiredParams) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    offset = sb.length;

    var parameterType = param.type;
    if (parameterType is FunctionType) {
      var rangeStart = offset;
      int rangeLength;

      // todo (pq): consider adding ranges for params
      // pending: https://github.com/dart-lang/sdk/issues/40207
      // (types in closure param completions make this UX awkward)
      final parametersString = buildClosureParameters(parameterType);
      final blockBuffer = StringBuffer(parametersString);

      blockBuffer.write(' ');

      // todo (pq): consider refactoring to share common logic w/
      //  ArgListContributor.buildClosureSuggestions
      final returnType = parameterType.returnType;
      if (returnType is VoidType) {
        blockBuffer.write('{');
        rangeStart = sb.length + blockBuffer.length;
        blockBuffer.write(' }');
        rangeLength = 1;
      } else {
        final returnValue = returnType.isDartCoreBool ? 'false' : 'null';
        blockBuffer.write('=> ');
        rangeStart = sb.length + blockBuffer.length;
        blockBuffer.write(returnValue);
        rangeLength = returnValue.length;
      }

      sb.write(blockBuffer);
      ranges.addAll([rangeStart, rangeLength]);
    } else {
      var name = param.name;
      sb.write(name);
      ranges.addAll([offset, name.length]);
    }
  }

  for (var param in namedParams) {
    if (param.hasRequired || param.isRequiredNamed) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      var name = param.name;
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
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String? parameters,
    TypeAnnotation? returnType,
    bool isAbstract = false,
    bool isDeprecated = false}) {
  var name = id.name;
  // TODO(danrubel) use lineInfo to determine startLine and startColumn
  var location = Location(source.fullName, id.offset, id.length, 0, 0,
      endLine: 0, endColumn: 0);
  var flags = protocol.Element.makeFlags(
      isAbstract: isAbstract,
      isDeprecated: isDeprecated,
      isPrivate: Identifier.isPrivateName(name));
  return protocol.Element(kind, name, flags,
      location: location,
      parameters: parameters,
      returnType: nameForType(id, returnType));
}

/// Return a default argument value for the given [parameter].
DefaultArgument? getDefaultStringParameterValue(
    ParameterElement parameter, CodeStyleOptions codeStyleOptions,
    {required bool withNullability}) {
  var type = parameter.type;
  if (type is InterfaceType) {
    if (type.isDartCoreList) {
      return DefaultArgument('[]', cursorPosition: 1);
    } else if (type.isDartCoreMap) {
      return DefaultArgument('{}', cursorPosition: 1);
    } else if (type.isDartCoreString) {
      var quote = codeStyleOptions.preferredQuoteForStrings;
      return DefaultArgument('$quote$quote', cursorPosition: 1);
    }
  } else if (type is FunctionType) {
    var params = type.parameters
        .map((p) =>
            '${getTypeString(p.type, withNullability: withNullability)}${p.name}')
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

String getTypeString(DartType type, {required bool withNullability}) {
  if (type is DynamicType) {
    return '';
  } else {
    return '${type.getDisplayString(withNullability: withNullability)} ';
  }
}

/// Return name of the type of the given [identifier], or, if it unresolved, the
/// name of its declared [declaredType].
String? nameForType(SimpleIdentifier identifier, TypeAnnotation? declaredType) {
  // Get the type from the identifier element.
  DartType type;
  var element = identifier.staticElement;
  if (element == null) {
    return DYNAMIC;
  } else if (element is FunctionTypedElement) {
    if (element is PropertyAccessorElement && element.isSetter) {
      return null;
    }
    type = element.returnType;
  } else if (element is TypeAliasElement) {
    final aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      type = aliasedType.returnType;
    } else {
      return null;
    }
  } else if (element is VariableElement) {
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
  return type.getDisplayString(withNullability: false);
}

class CompletionDefaultArgumentList {
  final String? text;
  final List<int>? ranges;

  CompletionDefaultArgumentList({
    required this.text,
    required this.ranges,
  });
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

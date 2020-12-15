// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of utility methods used by completion contributors.
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, Location;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show Element, ElementKind;
import 'package:meta/meta.dart';

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

/// A marker used in place of `null` when a function has no return type.
final TypeName NO_RETURN_TYPE = astFactory.typeName(
    astFactory.simpleIdentifier(StringToken(TokenType.IDENTIFIER, '', 0)),
    null);

/// Add default argument list text and ranges based on the given
/// [requiredParams] and [namedParams].
void addDefaultArgDetails(
    CompletionSuggestion suggestion,
    Element element,
    Iterable<ParameterElement> requiredParams,
    Iterable<ParameterElement> namedParams) {
  var sb = StringBuffer();
  var ranges = <int>[];

  int offset;

  for (var param in requiredParams) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    offset = sb.length;

    if (param.type is FunctionType) {
      FunctionType type = param.type;

      var rangeStart = offset;
      int rangeLength;

      // todo (pq): consider adding ranges for params
      // pending: https://github.com/dart-lang/sdk/issues/40207
      // (types in closure param completions make this UX awkward)
      final parametersString = buildClosureParameters(type);
      final blockBuffer = StringBuffer(parametersString);

      blockBuffer.write(' ');

      // todo (pq): consider refactoring to share common logic w/
      //  ArgListContributor.buildClosureSuggestions
      final returnType = type.returnType;
      if (returnType.isVoid) {
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

  suggestion.defaultArgumentListString = sb.isNotEmpty ? sb.toString() : null;
  suggestion.defaultArgumentListTextRanges = ranges.isNotEmpty ? ranges : null;
}

String buildClosureParameters(FunctionType type) {
  var buffer = StringBuffer();
  buffer.write('(');

  var hasNamed = false;
  var hasOptionalPositional = false;
  var parameters = type.parameters;
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
    // todo (pq): consider abbreviating names
    buffer.write(parameter.name);
  }

  if (hasNamed) {
    buffer.write('}');
  } else if (hasOptionalPositional) {
    buffer.write(']');
  }

  buffer.write(')');
  return buffer.toString();
}

/// Create a new protocol Element for inclusion in a completion suggestion.
protocol.Element createLocalElement(
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters,
    TypeAnnotation returnType,
    bool isAbstract = false,
    bool isDeprecated = false}) {
  String name;
  Location location;
  if (id != null) {
    name = id.name;
    // TODO(danrubel) use lineInfo to determine startLine and startColumn
    location = Location(source.fullName, id.offset, id.length, 0, 0);
  } else {
    name = '';
    location = Location(source.fullName, -1, 0, 1, 0);
  }
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
DefaultArgument getDefaultStringParameterValue(ParameterElement parameter,
    {@required bool withNullability}) {
  if (parameter != null) {
    var type = parameter.type;
    if (type is InterfaceType) {
      if (type.isDartCoreList) {
        return DefaultArgument('[]', cursorPosition: 1);
      } else if (type.isDartCoreMap) {
        return DefaultArgument('{}', cursorPosition: 1);
      } else if (type.isDartCoreString) {
        return DefaultArgument("''", cursorPosition: 1);
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
  }

  return null;
}

String getRequestLineIndent(DartCompletionRequest request) {
  var content = request.result.content;
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

String getTypeString(DartType type, {@required bool withNullability}) {
  if (type.isDynamic) {
    return '';
  } else {
    return type.getDisplayString(withNullability: withNullability) + ' ';
  }
}

/// Return `true` if the @deprecated annotation is present on the given [node].
bool isDeprecated(AnnotatedNode node) {
  if (node != null) {
    var metadata = node.metadata;
    if (metadata != null) {
      return metadata.any((Annotation a) {
        return a.name is SimpleIdentifier && a.name.name == 'deprecated';
      });
    }
  }
  return false;
}

/// Return name of the type of the given [identifier], or, if it unresolved, the
/// name of its declared [declaredType].
String nameForType(SimpleIdentifier identifier, TypeAnnotation declaredType) {
  if (identifier == null) {
    return null;
  }

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
    var aliasedElement = element.aliasedElement;
    if (aliasedElement is GenericFunctionTypeElement) {
      type = aliasedElement.returnType;
    } else {
      return null;
    }
  } else if (element is VariableElement) {
    type = element.type;
  } else {
    return null;
  }

  // If the type is unresolved, use the declared type.
  if (type != null && type.isDynamic) {
    if (declaredType is TypeName) {
      var id = declaredType.name;
      if (id != null) {
        return id.name;
      }
    }
    return DYNAMIC;
  }

  if (type == null) {
    return DYNAMIC;
  }
  return type.getDisplayString(withNullability: false);
}

/// A tuple of text to insert and an (optional) location for the cursor.
class DefaultArgument {
  /// The text to insert.
  final String text;

  /// An optional location for the cursor, relative to the text's start. This
  /// field can be null.
  final int cursorPosition;

  DefaultArgument(this.text, {this.cursorPosition});
}

// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A collection of utility methods used by completion contributors.
 */
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;
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

/**
 * The name of the type `dynamic`;
 */
const DYNAMIC = 'dynamic';

/**
 * A marker used in place of `null` when a function has no return type.
 */
final TypeName NO_RETURN_TYPE = astFactory.typeName(
    astFactory.simpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)),
    null);

/**
 * Add default argument list text and ranges based on the given [requiredParams]
 * and [namedParams].
 */
void addDefaultArgDetails(
    CompletionSuggestion suggestion,
    Element element,
    Iterable<ParameterElement> requiredParams,
    Iterable<ParameterElement> namedParams) {
  StringBuffer sb = new StringBuffer();
  List<int> ranges = <int>[];

  int offset;

  for (ParameterElement param in requiredParams) {
    if (sb.isNotEmpty) {
      sb.write(', ');
    }
    offset = sb.length;
    String name = param.name;
    sb.write(name);
    ranges.addAll([offset, name.length]);
  }

  for (ParameterElement param in namedParams) {
    if (param.hasRequired) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      String name = param.name;
      sb.write('$name: ');
      offset = sb.length;
      String defaultValue = _getDefaultValue(param);
      sb.write(defaultValue);
      ranges.addAll([offset, defaultValue.length]);
    }
  }

  suggestion.defaultArgumentListString = sb.isNotEmpty ? sb.toString() : null;
  suggestion.defaultArgumentListTextRanges = ranges.isNotEmpty ? ranges : null;
}

/**
 * Create a new protocol Element for inclusion in a completion suggestion.
 */
protocol.Element createLocalElement(
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters,
    TypeAnnotation returnType,
    bool isAbstract: false,
    bool isDeprecated: false}) {
  String name;
  Location location;
  if (id != null) {
    name = id.name;
    // TODO(danrubel) use lineInfo to determine startLine and startColumn
    location = new Location(source.fullName, id.offset, id.length, 0, 0);
  } else {
    name = '';
    location = new Location(source.fullName, -1, 0, 1, 0);
  }
  int flags = protocol.Element.makeFlags(
      isAbstract: isAbstract,
      isDeprecated: isDeprecated,
      isPrivate: Identifier.isPrivateName(name));
  return new protocol.Element(kind, name, flags,
      location: location,
      parameters: parameters,
      returnType: nameForType(id, returnType));
}

/**
 * Create a new suggestion based upon the given information. Return the new
 * suggestion or `null` if it could not be created.
 */
CompletionSuggestion createLocalSuggestion(SimpleIdentifier id,
    bool isDeprecated, int defaultRelevance, TypeAnnotation returnType,
    {ClassOrMixinDeclaration classDecl,
    CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
    protocol.Element element}) {
  if (id == null) {
    return null;
  }
  String completion = id.name;
  if (completion == null || completion.length <= 0 || completion == '_') {
    return null;
  }
  CompletionSuggestion suggestion = new CompletionSuggestion(
      kind,
      isDeprecated ? DART_RELEVANCE_LOW : defaultRelevance,
      completion,
      completion.length,
      0,
      isDeprecated,
      false,
      returnType: nameForType(id, returnType),
      element: element);
  if (classDecl != null) {
    SimpleIdentifier classId = classDecl.name;
    if (classId != null) {
      String className = classId.name;
      if (className != null && className.length > 0) {
        suggestion.declaringType = className;
      }
    }
  }
  return suggestion;
}

String getDefaultStringParameterValue(ParameterElement param) {
  if (param != null) {
    DartType type = param.type;
    if (type is InterfaceType && isDartList(type)) {
      List<DartType> typeArguments = type.typeArguments;
      if (typeArguments.length == 1) {
        DartType typeArg = typeArguments.first;
        String typeInfo = !typeArg.isDynamic ? '<${typeArg.name}>' : '';
        return '$typeInfo[]';
      }
    }
    if (type is FunctionType) {
      String params = type.parameters
          .map((p) => '${getTypeString(p.type)}${p.name}')
          .join(', ');
      //TODO(pq): consider adding a `TODO:` message in generated stub
      return '($params) {}';
    }
    //TODO(pq): support map literals
  }
  return null;
}

String getTypeString(DartType type) => type.isDynamic ? '' : '${type.name} ';

bool isDartList(DartType type) {
  ClassElement element = type.element;
  if (element != null) {
    return element.name == "List" && element.library.isDartCore;
  }
  return false;
}

/**
 * Return `true` if the @deprecated annotation is present on the given [node].
 */
bool isDeprecated(AnnotatedNode node) {
  if (node != null) {
    NodeList<Annotation> metadata = node.metadata;
    if (metadata != null) {
      return metadata.any((Annotation a) {
        return a.name is SimpleIdentifier && a.name.name == 'deprecated';
      });
    }
  }
  return false;
}

/**
 * Return name of the type of the given [identifier], or, if it unresolved, the
 * name of its declared [declaredType].
 */
String nameForType(SimpleIdentifier identifier, TypeAnnotation declaredType) {
  if (identifier == null) {
    return null;
  }

  // Get the type from the identifier element.
  DartType type;
  Element element = identifier.staticElement;
  if (element == null) {
    return DYNAMIC;
  } else if (element is FunctionTypedElement) {
    if (element is PropertyAccessorElement && element.isSetter) {
      return null;
    }
    type = element.returnType;
  } else if (element is VariableElement) {
    type = identifier.staticType;
  } else {
    return null;
  }

  // If the type is unresolved, use the declared type.
  if (type != null && type.isUndefined) {
    if (declaredType is TypeName) {
      Identifier id = declaredType.name;
      if (id != null) {
        return id.name;
      }
    }
    return DYNAMIC;
  }

  if (type == null) {
    return DYNAMIC;
  }
  return type.toString();
}

//TODO(pq): fix to use getDefaultStringParameterValue()
String _getDefaultValue(ParameterElement param) => 'null';

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A collection of utility methods used by completion contributors.
 */
import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';

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
    Iterable<ParameterElement> namedParams,
    IdeOptions options) {
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
    if (param.isRequired) {
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

  if (options?.generateFlutterWidgetChildrenBoilerPlate == true) {
    if (element is ConstructorElement) {
      if (isFlutterWidget(element.enclosingElement)) {
        for (ParameterElement param in element.parameters) {
          if (param.name == 'children') {
            String defaultValue = getDefaultStringParameterValue(param);
            if (sb.isNotEmpty) {
              sb.write(', ');
            }
            sb.write('children: ');
            offset = sb.length;
            sb.write(defaultValue);
            ranges.addAll([offset, defaultValue.length]);
          }
        }
      }
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
      returnType: nameForType(returnType));
}

/**
 * Create a new suggestion for the given [fieldDecl]. Return the new suggestion
 * or `null` if it could not be created.
 */
CompletionSuggestion createLocalFieldSuggestion(
    Source source, FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
  bool deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
  TypeAnnotation type = fieldDecl.fields.type;
  return createLocalSuggestion(
      varDecl.name, deprecated, DART_RELEVANCE_LOCAL_FIELD, type,
      classDecl: fieldDecl.parent,
      element: createLocalElement(
          source, protocol.ElementKind.FIELD, varDecl.name,
          returnType: type, isDeprecated: deprecated));
}

/**
 * Create a new suggestion based upon the given information. Return the new
 * suggestion or `null` if it could not be created.
 */
CompletionSuggestion createLocalSuggestion(SimpleIdentifier id,
    bool isDeprecated, int defaultRelevance, TypeAnnotation returnType,
    {ClassDeclaration classDecl,
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
      returnType: nameForType(returnType),
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
  DartType type = param.type;
  if (type is InterfaceType && isDartList(type)) {
    List<DartType> typeArguments = type.typeArguments;
    StringBuffer sb = new StringBuffer();
    if (typeArguments.length == 1) {
      DartType typeArg = typeArguments.first;
      if (!typeArg.isDynamic) {
        sb.write('<${typeArg.name}>');
      }
      sb.write('[]');
      return sb.toString();
    }
  }
  return null;
}

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
 * Return the name for the given [type].
 */
String nameForType(TypeAnnotation type) {
  if (type == NO_RETURN_TYPE) {
    return null;
  }
  if (type == null) {
    return DYNAMIC;
  }
  if (type is TypeName) {
    Identifier id = type.name;
    if (id == null) {
      return DYNAMIC;
    }
    String name = id.name;
    if (name == null || name.length <= 0) {
      return DYNAMIC;
    }
    TypeArgumentList typeArgs = type.typeArguments;
    if (typeArgs != null) {
      //TODO (danrubel) include type arguments
    }
    return name;
  } else if (type is GenericFunctionType) {
    // TODO(brianwilkerson) Implement this.
  }
  return DYNAMIC;
}

String _getDefaultValue(ParameterElement param) => 'null';

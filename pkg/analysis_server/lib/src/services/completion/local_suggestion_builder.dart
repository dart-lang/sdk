// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder.local;

import 'package:analysis_server/src/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';

const DYNAMIC = 'dynamic';

final TypeName NO_RETURN_TYPE = new TypeName(
    new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)), null);

/**
 * Create a new protocol Element for inclusion in a completion suggestion.
 */
protocol.Element createElement(
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters, TypeName returnType, bool isAbstract: false,
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
 * Create a new suggestion for the given field.
 * Return the new suggestion or `null` if it could not be created.
 */
CompletionSuggestion createFieldSuggestion(
    Source source, FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
  bool deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
  TypeName type = fieldDecl.fields.type;
  return createSuggestion(
      varDecl.name, deprecated, DART_RELEVANCE_LOCAL_FIELD, type,
      classDecl: fieldDecl.parent,
      element: createElement(source, protocol.ElementKind.FIELD, varDecl.name,
          returnType: type, isDeprecated: deprecated));
}

/**
 * Create a new suggestion based upon the given information.
 * Return the new suggestion or `null` if it could not be created.
 */
CompletionSuggestion createSuggestion(SimpleIdentifier id, bool isDeprecated,
    int defaultRelevance, TypeName returnType,
    {ClassDeclaration classDecl, protocol.Element element}) {
  if (id == null) {
    return null;
  }
  String completion = id.name;
  if (completion == null || completion.length <= 0 || completion == '_') {
    return null;
  }
  CompletionSuggestion suggestion = new CompletionSuggestion(
      CompletionSuggestionKind.INVOCATION,
      isDeprecated ? DART_RELEVANCE_LOW : defaultRelevance, completion,
      completion.length, 0, isDeprecated, false,
      returnType: nameForType(returnType), element: element);
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

/**
 * Return `true` if the @deprecated annotation is present
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
 * Return the name for the given type.
 */
String nameForType(TypeName type) {
  if (type == NO_RETURN_TYPE) {
    return null;
  }
  if (type == null) {
    return DYNAMIC;
  }
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
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.constructor;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;

const DYNAMIC = 'dynamic';

final TypeName NO_RETURN_TYPE = new TypeName(
    new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)), null);

/**
* Create a new protocol Element for inclusion in a completion suggestion.
*/
protocol.Element createLocalElement(
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters,
    TypeName returnType,
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
* Create a new suggestion for the given field.
* Return the new suggestion or `null` if it could not be created.
*/
CompletionSuggestion createLocalFieldSuggestion(
    Source source, FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
  bool deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
  TypeName type = fieldDecl.fields.type;
  return createLocalSuggestion(
      varDecl.name, deprecated, DART_RELEVANCE_LOCAL_FIELD, type,
      classDecl: fieldDecl.parent,
      element: createLocalElement(
          source, protocol.ElementKind.FIELD, varDecl.name,
          returnType: type, isDeprecated: deprecated));
}

/**
* Create a new suggestion based upon the given information.
* Return the new suggestion or `null` if it could not be created.
*/
CompletionSuggestion createLocalSuggestion(SimpleIdentifier id,
    bool isDeprecated, int defaultRelevance, TypeName returnType,
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

/**
 * A contributor for calculating constructor suggestions
 * for declarations in the local file.
 */
class LocalConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    if (!optype.isPrefixed) {
      if (optype.includeConstructorSuggestions) {
        AstNode node = request.target.containingNode;

        await request.resolveContainingStatement(node);

        // Discard any cached target information
        // because it may have changed as a result of the resolution
        node = request.target.containingNode;

        _Visitor visitor = new _Visitor(request, suggestions, optype);
        visitor.visit(node);
      }
    }
    return suggestions;
  }
}

/**
 * A visitor for collecting constructor suggestions.
 */
class _Visitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final List<CompletionSuggestion> suggestions;

  _Visitor(DartCompletionRequest request, this.suggestions, this.optype)
      : request = request,
        super(request.offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    bool found = false;
    for (ClassMember member in declaration.members) {
      if (member is ConstructorDeclaration) {
        found = true;
        _addSuggestion(declaration, member);
      }
    }
    if (!found) {
      _addSuggestion(declaration, null);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  @override
  void declaredLabel(Label label, bool isCaseLabel) {}

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredMethod(MethodDeclaration declaration) {}

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}

  /**
   * For the given class and constructor,
   * add a suggestion of the form B(...) or B.name(...).
   * If the given constructor is `null`
   * then add a default constructor suggestion.
   */
  void _addSuggestion(
      ClassDeclaration classDecl, ConstructorDeclaration constructorDecl) {
    String completion = classDecl.name.name;
    SimpleIdentifier elemId;

    int relevance = optype.constructorSuggestionsFilter(
        classDecl.element?.type, DART_RELEVANCE_DEFAULT);
    if (relevance == null) {
      return;
    }

    // Build a suggestion for explicitly declared constructor
    if (constructorDecl != null) {
      elemId = constructorDecl.name;
      ConstructorElement elem = constructorDecl.element;
      if (elemId != null) {
        String name = elemId.name;
        if (name != null && name.length > 0) {
          completion = '$completion.$name';
        }
      }
      if (elem != null) {
        CompletionSuggestion suggestion = createSuggestion(elem,
            completion: completion, relevance: relevance);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
    }

    // Build a suggestion for an implicit constructor
    else {
      protocol.Element element = createLocalElement(
          request.source, protocol.ElementKind.CONSTRUCTOR, elemId,
          parameters: '()');
      element.returnType = classDecl.name.name;
      CompletionSuggestion suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          relevance,
          completion,
          completion.length,
          0,
          false,
          false,
          declaringType: classDecl.name.name,
          element: element,
          parameterNames: [],
          parameterTypes: [],
          requiredParameterCount: 0,
          hasNamedParameters: false);
      suggestions.add(suggestion);
    }
  }
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.label;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
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
 * A contributor for calculating label suggestions.
 */
class LabelContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    if (!optype.isPrefixed) {
      if (optype.includeStatementLabelSuggestions ||
          optype.includeCaseLabelSuggestions) {
        new _LabelVisitor(request, optype.includeStatementLabelSuggestions,
                optype.includeCaseLabelSuggestions, suggestions)
            .visit(request.target.containingNode);
      }
    }
    return suggestions;
  }
}

/**
 * A visitor for collecting suggestions for break and continue labels.
 */
class _LabelVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final List<CompletionSuggestion> suggestions;

  /**
   * True if statement labels should be included as suggestions.
   */
  final bool includeStatementLabels;

  /**
   * True if case labels should be included as suggestions.
   */
  final bool includeCaseLabels;

  _LabelVisitor(DartCompletionRequest request, this.includeStatementLabels,
      this.includeCaseLabels, this.suggestions)
      : request = request,
        super(request.offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    // ignored
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    // ignored
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (isCaseLabel ? includeCaseLabels : includeStatementLabels) {
      CompletionSuggestion suggestion = _addSuggestion(label.label);
      if (suggestion != null) {
        suggestion.element = createLocalElement(
            request.source, protocol.ElementKind.LABEL, label.label,
            returnType: NO_RETURN_TYPE);
      }
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    // ignored
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.IDENTIFIER,
            DART_RELEVANCE_DEFAULT,
            completion,
            completion.length,
            0,
            false,
            false);
        suggestions.add(suggestion);
        return suggestion;
      }
    }
    return null;
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedComputer extends DartCompletionComputer {
  bool shouldWaitForLowPrioritySuggestions;
  _ImportedSuggestionBuilder builder;

  ImportedComputer({this.shouldWaitForLowPrioritySuggestions: false});

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = request.node.accept(new _ImportedAstVisitor(request));
    if (builder != null) {
      builder.shouldWaitForLowPrioritySuggestions =
          shouldWaitForLowPrioritySuggestions;
      return builder.computeFast(request.node);
    }
    return true;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.computeFull(request.node);
    }
    return new Future.value(false);
  }
}

/**
 * [_ImportedAstVisitor] determines whether an import suggestions are needed
 * and instantiates the builder to create those suggestions.
 */
class _ImportedAstVisitor extends
    GeneralizingAstVisitor<_ImportedSuggestionBuilder> {
  final DartCompletionRequest request;

  _ImportedAstVisitor(this.request);

  @override
  _ImportedSuggestionBuilder visitArgumentList(ArgumentList node) {
    return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
  }

  @override
  _ImportedSuggestionBuilder visitBlock(Block node) {
    return new _ImportedSuggestionBuilder(request);
  }

  @override
  _ImportedSuggestionBuilder visitCascadeExpression(CascadeExpression node) {
    // Make suggestions for the target, but not for the selector
    // InvocationComputer makes selector suggestions
    Expression target = node.target;
    if (target != null && request.offset <= target.end) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    Token leftBracket = node.leftBracket;
    if (leftBracket != null && request.offset >= leftBracket.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitExpression(Expression node) {
    return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
  }

  @override
  _ImportedSuggestionBuilder
      visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    // A pre-variable declaration (e.g. C ^) is parsed as an expression
    // statement. Do not make suggestions for the variable name.
    if (expression is SimpleIdentifier && request.offset <= expression.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder
      visitFormalParameterList(FormalParameterList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset > leftParen.offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return new _ImportedSuggestionBuilder(request);
      }
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitForStatement(ForStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitIfStatement(IfStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
      }
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder
      visitInterpolationExpression(InterpolationExpression node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period == null || request.offset <= period.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitNode(AstNode node) {
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Make suggestions for the prefix, but not for the selector
    // InvocationComputer makes selector suggestions
    Token period = node.period;
    if (period == null || request.offset <= period.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitPropertyAccess(PropertyAccess node) {
    // Make suggestions for the target, but not for the property name
    // InvocationComputer makes property name suggestions
    var operator = node.operator;
    if (operator != null && request.offset < operator.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }

  @override
  _ImportedSuggestionBuilder visitStringLiteral(StringLiteral node) {
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitTypeName(TypeName node) {
    // TODO (danrubel) refactor this and local_computer
    // to reduce duplicate code
    bool typesOnly = false;
    // If suggesting completions within a TypeName node
    // then limit suggestions to only types in specific situations
    AstNode p = node.parent;
    if (p is IsExpression || p is ConstructorName || p is AsExpression) {
      typesOnly = true;
    } else if (p is VariableDeclarationList) {
      // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
      // the user may be either (1) entering a type for the assignment
      // or (2) starting a new statement.
      // Consider suggesting only types
      // if only spaces separates the 1st and 2nd identifiers.
    }
    return new _ImportedSuggestionBuilder(request, typesOnly: typesOnly);
  }

  @override
  _ImportedSuggestionBuilder
      visitVariableDeclaration(VariableDeclaration node) {
    Token equals = node.equals;
    // Make suggestions for the RHS of a variable declaration
    if (equals != null && request.offset >= equals.end) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }
}

/**
 * [_ImportedSuggestionBuilder] traverses the imports and builds suggestions
 * based upon imported elements.
 */
class _ImportedSuggestionBuilder implements SuggestionBuilder {
  bool shouldWaitForLowPrioritySuggestions;
  final DartCompletionRequest request;
  final bool typesOnly;
  final bool excludeVoidReturn;
  DartCompletionCache cache;

  _ImportedSuggestionBuilder(this.request, {this.typesOnly: false,
      this.excludeVoidReturn: false}) {
    cache = request.cache;
  }

  /**
   * If the needed information is cached, then add suggestions and return `true`
   * else return `false` indicating that additional work is necessary.
   */
  bool computeFast(AstNode node) {
    CompilationUnit unit = request.unit;
    if (cache.isImportInfoCached(unit)) {
      _addInheritedSuggestions(node);
      _addTopLevelSuggestions();
      return true;
    }
    return false;
  }

  /**
   * Compute suggested based upon imported elements.
   */
  Future<bool> computeFull(AstNode node) {

    Future<bool> addSuggestions(_) {
      _addInheritedSuggestions(node);
      _addTopLevelSuggestions();
      return new Future.value(true);
    }

    Future future = null;
    if (!cache.isImportInfoCached(request.unit)) {
      future = cache.computeImportInfo(request.unit, request.searchEngine);
    }
    if (future != null && shouldWaitForLowPrioritySuggestions) {
      return future.then(addSuggestions);
    }
    return addSuggestions(true);
  }

  /**
   * Add imported element suggestions.
   */
  void _addElementSuggestions(List<Element> elements) {
    elements.forEach((Element elem) {
      if (elem is! ClassElement) {
        if (typesOnly) {
          return;
        }
        if (elem is ExecutableElement) {
          if (elem.isOperator) {
            return;
          }
          DartType returnType = elem.returnType;
          if (returnType != null && returnType.isVoid) {
            if (excludeVoidReturn) {
              return;
            }
          }
        }
      }
      request.suggestions.add(
          createElementSuggestion(elem, relevance: CompletionRelevance.DEFAULT));
    });
  }

  /**
   * Add suggestions for any inherited imported members.
   */
  void _addInheritedSuggestions(AstNode node) {
    var classDecl = node.getAncestor((p) => p is ClassDeclaration);
    if (classDecl is ClassDeclaration) {
      // Build a list of inherited types that are imported
      // and include any inherited imported members
      List<String> inheritedTypes = new List<String>();
      visitInheritedTypes(classDecl, (_) {
        // local declarations are handled by the local computer
      }, (String typeName) {
        inheritedTypes.add(typeName);
      });
      HashSet<String> visited = new HashSet<String>();
      while (inheritedTypes.length > 0) {
        String name = inheritedTypes.removeLast();
        ClassElement elem = cache.importedClassMap[name];
        if (visited.add(name) && elem != null) {
          _addElementSuggestions(elem.accessors);
          _addElementSuggestions(elem.methods);
          elem.allSupertypes.forEach((InterfaceType type) {
            if (visited.add(type.name)) {
              _addElementSuggestions(type.accessors);
              _addElementSuggestions(type.methods);
            }
          });
        }
      }
    }
  }

  /**
   * Add top level suggestions from the cache.
   * To reduce the number of suggestions sent to the client,
   * filter the suggestions based upon the first character typed.
   * If no characters are available to use for filtering,
   * then exclude all low priority suggestions.
   */
  void _addTopLevelSuggestions() {
    String filterText = request.filterText;
    if (filterText.length > 1) {
      filterText = filterText.substring(0, 1);
    }

    //TODO (danrubel) Revisit this filtering once paged API has been added
    addFilteredSuggestions(List<CompletionSuggestion> unfiltered) {
      unfiltered.forEach((CompletionSuggestion suggestion) {
        if (filterText.length > 0) {
          if (suggestion.completion.startsWith(filterText)) {
            request.suggestions.add(suggestion);
          }
        } else {
          if (suggestion.relevance != CompletionRelevance.LOW) {
            request.suggestions.add(suggestion);
          }
        }
      });
    }

    DartCompletionCache cache = request.cache;
    addFilteredSuggestions(cache.importedTypeSuggestions);
    addFilteredSuggestions(cache.libraryPrefixSuggestions);
    if (!typesOnly) {
      addFilteredSuggestions(cache.otherImportedSuggestions);
      if (!excludeVoidReturn) {
        addFilteredSuggestions(cache.importedVoidReturnSuggestions);
      }
    }
  }
}

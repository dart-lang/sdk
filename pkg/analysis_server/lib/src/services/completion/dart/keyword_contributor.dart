// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

const ASYNC_STAR = 'async*';
const DEFAULT_COLON = 'default:';
const DEFERRED_AS = 'deferred as';
const EXPORT_STATEMENT = "export '';";
const IMPORT_STATEMENT = "import '';";
const PART_STATEMENT = "part '';";
const SYNC_STAR = 'sync*';
const YIELD_STAR = 'yield*';

/// A contributor that produces suggestions based on the set of keywords that
/// are valid at the completion point.
class KeywordContributor extends DartCompletionContributor {
  KeywordContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    // Don't suggest anything right after double or integer literals.
    if (request.target.isDoubleOrIntLiteral()) {
      return;
    }

    final visitor = _KeywordVisitor(request, builder);

    final patternLocation = request.opType.patternLocation;
    if (patternLocation is NamedPatternFieldWantsFinalOrVar) {
      visitor._addSuggestions([
        Keyword.FINAL,
        Keyword.VAR,
      ]);
      return;
    } else if (patternLocation is NamedPatternFieldWantsName) {
      return;
    }

    request.target.containingNode.accept(visitor);
  }
}

/// A visitor for generating keyword suggestions.
class _KeywordVisitor extends SimpleAstVisitor<void> {
  final DartCompletionRequest request;

  final SuggestionBuilder builder;

  final SyntacticEntity? entity;

  _KeywordVisitor(this.request, this.builder) : entity = request.target.entity;

  Token? get droppedToken => request.target.droppedToken;

  @override
  void visitArgumentList(ArgumentList node) {
    if (request.opType.includeOnlyNamedArgumentSuggestions) {
      return;
    }
    final entity = this.entity;
    if (entity == node.rightParenthesis) {
      _addExpressionKeywords(node);
      var previous = node.findPrevious(entity as Token);
      if (previous != null && previous.isSynthetic) {
        previous = node.findPrevious(previous);
      }
      if (previous != null && previous.lexeme == ')') {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
    }
    if (entity is SimpleIdentifier && node.arguments.contains(entity)) {
      _addExpressionKeywords(node);
      var index = node.arguments.indexOf(entity);
      if (index > 0) {
        var previousArgument = node.arguments[index - 1];
        var endToken = previousArgument.endToken;
        var tokenAfterEnd = endToken.next!;
        if (endToken.lexeme == ')' &&
            tokenAfterEnd.lexeme == ',' &&
            tokenAfterEnd.isSynthetic) {
          _addSuggestion(Keyword.ASYNC);
          _addSuggestion2(ASYNC_STAR);
          _addSuggestion2(SYNC_STAR);
        }
      }
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var constructorDeclaration =
        node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructorDeclaration != null) {
      if (request.featureSet.isEnabled(Feature.super_parameters)) {
        _addSuggestion(Keyword.SUPER);
      }
      _addSuggestion(Keyword.THIS);
    }
    final entity = this.entity;
    if (entity is Token) {
      FormalParameter? lastParameter() {
        var parameters = node.parameters;
        if (parameters.isNotEmpty) {
          return parameters.last.notDefault;
        }
        return null;
      }

      bool hasCovariant() {
        var last = lastParameter();
        return last != null &&
            (last.covariantKeyword != null || last.name?.lexeme == 'covariant');
      }

      bool hasRequired() {
        var last = lastParameter();
        return last != null &&
            (last.requiredKeyword != null || last.name?.lexeme == 'required');
      }

      var tokenType = entity.type;
      if (tokenType == TokenType.CLOSE_PAREN) {
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
        if (!hasCovariant()) {
          _addSuggestion(Keyword.COVARIANT);
        }
      } else if (tokenType == TokenType.CLOSE_CURLY_BRACKET) {
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
        if (!hasCovariant()) {
          _addSuggestion(Keyword.COVARIANT);
          if (request.featureSet.isEnabled(Feature.non_nullable) &&
              !hasRequired()) {
            _addSuggestion(Keyword.REQUIRED);
          }
        }
      } else if (tokenType == TokenType.CLOSE_SQUARE_BRACKET) {
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
        if (!hasCovariant()) {
          _addSuggestion(Keyword.COVARIANT);
        }
      }
    } else if (entity is FormalParameter) {
      var beginToken = entity.beginToken;
      var offset = request.target.offset;
      if (offset <= beginToken.end) {
        _addSuggestion(Keyword.COVARIANT);
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
        if (entity.isNamed &&
            !entity.isRequired &&
            request.featureSet.isEnabled(Feature.non_nullable)) {
          _addSuggestion(Keyword.REQUIRED);
        }
      } else if (entity is FunctionTypedFormalParameter) {
        _addSuggestion(Keyword.COVARIANT);
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
        if (entity.isNamed &&
            !entity.isRequired &&
            request.featureSet.isEnabled(Feature.non_nullable)) {
          _addSuggestion(Keyword.REQUIRED);
        }
      }
    }
  }

  void _addExpressionKeywords(AstNode node) {
    _addSuggestions([
      Keyword.FALSE,
      Keyword.NULL,
      Keyword.TRUE,
    ]);
    if (!request.inConstantContext) {
      _addSuggestions([Keyword.CONST]);
    }
    if (node.inClassMemberBody) {
      _addSuggestions([Keyword.SUPER, Keyword.THIS]);
    }
    if (node.inAsyncMethodOrFunction) {
      _addSuggestion(Keyword.AWAIT);
    }
    if (request.featureSet.isEnabled(Feature.patterns)) {
      _addSuggestion(Keyword.SWITCH);
    }
  }

  void _addSuggestion(Keyword keyword) {
    _addSuggestion2(keyword.lexeme);
  }

  void _addSuggestion2(String keyword, {int? offset}) {
    builder.suggestKeyword(keyword, offset: offset);
  }

  void _addSuggestions(List<Keyword> keywords) {
    for (var keyword in keywords) {
      _addSuggestion(keyword);
    }
  }
}

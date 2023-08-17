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
import 'package:analyzer/src/dart/ast/token.dart';
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
  void visitCompilationUnit(CompilationUnit node) {
    SyntacticEntity? previousMember;
    for (var member in node.childEntities) {
      if (entity == member) {
        break;
      }
      previousMember = member;
    }
    if (previousMember is ClassDeclaration) {
      if (previousMember.leftBracket.isSynthetic) {
        // If the prior member is an unfinished class declaration
        // then the user is probably finishing that.
        _addClassDeclarationKeywords(previousMember);
        return;
      }
    }
    if (previousMember is ExtensionDeclaration) {
      if (previousMember.leftBracket.isSynthetic) {
        // If the prior member is an unfinished extension declaration then the
        // user is probably finishing that.
        _addExtensionDeclarationKeywords(previousMember);
        return;
      }
    }
    if (previousMember is MixinDeclaration) {
      if (previousMember.leftBracket.isSynthetic) {
        // If the prior member is an unfinished mixin declaration
        // then the user is probably finishing that.
        _addMixinDeclarationKeywords(previousMember);
        return;
      }
    }
    if (previousMember is ImportDirective) {
      if (previousMember.semicolon.isSynthetic) {
        // If the prior member is an unfinished import directive
        // then the user is probably finishing that
        _addImportDirectiveKeywords(previousMember);
        return;
      }
    }
    if (previousMember == null || previousMember is Directive) {
      if (previousMember == null &&
          !node.directives.any((d) => d is LibraryDirective)) {
        _addSuggestions([Keyword.LIBRARY]);
      }
      _addSuggestion2(IMPORT_STATEMENT, offset: 8);
      _addSuggestion2(EXPORT_STATEMENT, offset: 8);
      _addSuggestion2(PART_STATEMENT, offset: 6);
    }
    if (entity == null || entity is Declaration) {
      if (previousMember is FunctionDeclaration &&
          previousMember.functionExpression.body.isEmpty) {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
      _addCompilationUnitKeywords();
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (request.opType.completionLocation == 'FieldDeclaration_static') {
      _addSuggestion(Keyword.CONST);
      _addSuggestion(Keyword.DYNAMIC);
      _addSuggestion(Keyword.FINAL);
      _addSuggestion(Keyword.LATE);
      return;
    }

    if (request.opType.completionLocation == 'FieldDeclaration_static_late') {
      _addSuggestion(Keyword.DYNAMIC);
      _addSuggestion(Keyword.FINAL);
      return;
    }

    var fields = node.fields;
    if (entity != fields) {
      return;
    }
    var variables = fields.variables;
    if (variables.isEmpty || request.offset > variables.first.beginToken.end) {
      return;
    }
    if (node.abstractKeyword == null) {
      _addSuggestion(Keyword.ABSTRACT);
    }
    if (node.covariantKeyword == null) {
      _addSuggestion(Keyword.COVARIANT);
    }
    if (node.externalKeyword == null) {
      _addSuggestion(Keyword.EXTERNAL);
    }
    if (node.fields.lateKeyword == null &&
        request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
    }
    if (node.fields.type == null) {
      _addSuggestion(Keyword.DYNAMIC);
    }
    if (!node.isStatic) {
      _addSuggestion(Keyword.STATIC);
    }
    if (!variables.first.isConst) {
      _addSuggestion(Keyword.CONST);
    }
    if (!variables.first.isFinal) {
      _addSuggestion(Keyword.FINAL);
    }
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _visitForEachParts(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _visitForEachParts(node);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _visitForEachParts(node);
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

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _visitForParts(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _visitForParts(node);
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _visitForParts(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    // Actual: for (va^)
    // Parsed: for (va^; ;)
    if (node.forLoopParts == entity) {
      _addSuggestions([Keyword.FINAL, Keyword.VAR]);
    } else if (node.rightParenthesis == entity) {
      var parts = node.forLoopParts;
      if (parts is ForPartsWithDeclarations) {
        var variables = parts.variables;
        var keyword = variables.keyword;
        if (variables.variables.length == 1 &&
            variables.variables[0].name.isSynthetic &&
            keyword != null &&
            parts.leftSeparator.isSynthetic) {
          var afterKeyword = keyword.next!;
          if (afterKeyword.type == TokenType.OPEN_PAREN) {
            var endGroup = afterKeyword.endGroup;
            if (endGroup != null && request.offset >= endGroup.end) {
              _addSuggestion(Keyword.IN);
            }
          }
        }
      }
    }
  }

  // @override
  // void visitMethodDeclaration(MethodDeclaration node) {
  //   if (entity == node.body) {
  //     if (node.body.isEmpty) {
  //       _addClassBodyKeywords();
  //       _addSuggestion(Keyword.ASYNC);
  //       _addSuggestion2(ASYNC_STAR);
  //       _addSuggestion2(SYNC_STAR);
  //     } else {
  //       _addSuggestion(Keyword.ASYNC);
  //       if (node.body is! ExpressionFunctionBody) {
  //         _addSuggestion2(ASYNC_STAR);
  //         _addSuggestion2(SYNC_STAR);
  //       }
  //     }
  //   } else if (entity == node.returnType || entity == node.name) {
  //     // If the cursor is at the beginning of the declaration, include the class
  //     // body keywords.  See dartbug.com/41039.
  //     _addClassBodyKeywords();
  //   }
  // }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (entity == node.methodName) {
      // no keywords in '.' expressions
    } else if (entity == node.argumentList) {
      // Note that we're checking the argumentList rather than the typeArgumentList
      // as you'd expect. For some reason, when the cursor is in a type argument
      // list (f<^>()), the entity is the invocation's argumentList...
      // See similar logic in `imported_reference_contributor`.

      _addSuggestion(Keyword.DYNAMIC);
      _addSuggestion(Keyword.VOID);
    } else {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _addExpressionKeywords(node);
    _addSuggestions([Keyword.DYNAMIC]);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    var operator = node.operator;
    if (request.offset >= operator.end) {
      if (request.opType.completionLocation == 'TypeArgumentList_argument') {
        // This is most likely a type argument list.
        _addSuggestions([Keyword.DYNAMIC, Keyword.VOID]);
        return;
      }
      _addConstantExpressionKeywords(node);
      _addSuggestions([Keyword.DYNAMIC, Keyword.VOID]);
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var entity = this.entity;
    if (node.type == entity && entity is GenericFunctionType) {
      var offset = request.offset;
      var returnType = entity.returnType;
      if ((returnType == null && offset < entity.offset) ||
          (returnType != null &&
              offset >= returnType.offset &&
              offset < returnType.end)) {
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addExpressionKeywords(node);
  }

  void _addClassDeclarationKeywords(ClassDeclaration node) {
    // Very simplistic suggestion because analyzer will warn if
    // the extends / with / implements keywords are out of order
    if (node.extendsClause == null) {
      _addSuggestion(Keyword.EXTENDS);
    } else if (node.withClause == null) {
      _addSuggestion(Keyword.WITH);
    }
    if (node.implementsClause == null) {
      _addSuggestion(Keyword.IMPLEMENTS);
    }
  }

  void _addCompilationUnitKeywords() {
    _addSuggestions([
      Keyword.ABSTRACT,
      Keyword.CLASS,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.MIXIN,
      Keyword.TYPEDEF,
      Keyword.VAR,
      Keyword.VOID
    ]);
    if (request.featureSet.isEnabled(Feature.extension_methods)) {
      _addSuggestion(Keyword.EXTENSION);
    }
    if (request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
    }
    if (request.featureSet.isEnabled(Feature.class_modifiers)) {
      _addSuggestions([Keyword.BASE, Keyword.INTERFACE]);
    }
    if (request.featureSet.isEnabled(Feature.sealed_class)) {
      _addSuggestion(Keyword.SEALED);
    }
  }

  void _addConstantExpressionKeywords(AstNode node) {
    // TODO(brianwilkerson) Use this method in place of `_addExpressionKeywords`
    //  when in a constant context.
    _addSuggestions([
      Keyword.FALSE,
      Keyword.NULL,
      Keyword.TRUE,
    ]);
    if (!request.inConstantContext) {
      _addSuggestions([Keyword.CONST]);
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

  void _addExtensionDeclarationKeywords(ExtensionDeclaration node) {
    if (node.onKeyword.isSynthetic) {
      _addSuggestion(Keyword.ON);
    }
  }

  void _addImportDirectiveKeywords(ImportDirective node) {
    var hasDeferredKeyword = node.deferredKeyword != null;
    var hasAsKeyword = node.asKeyword != null;
    if (!hasAsKeyword) {
      _addSuggestion(Keyword.AS);
    }
    if (!hasDeferredKeyword) {
      if (!hasAsKeyword) {
        _addSuggestion2(DEFERRED_AS);
      } else if (entity == node.asKeyword) {
        _addSuggestion(Keyword.DEFERRED);
      }
    }
    if (!hasDeferredKeyword || hasAsKeyword) {
      if (node.combinators.isEmpty) {
        _addSuggestion(Keyword.SHOW);
        _addSuggestion(Keyword.HIDE);
      }
    }
  }

  void _addMixinDeclarationKeywords(MixinDeclaration node) {
    // Very simplistic suggestion because analyzer will warn if
    // the on / implements clauses are out of order
    if (node.onClause == null) {
      _addSuggestion(Keyword.ON);
    }
    if (node.implementsClause == null) {
      _addSuggestion(Keyword.IMPLEMENTS);
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

  void _visitForEachParts(ForEachParts node) {
    if (entity == node.inKeyword) {
      var previous = node.findPrevious(node.inKeyword);
      if (previous is SyntheticStringToken && previous.lexeme == 'in') {
        previous = node.findPrevious(previous);
      }
      if (previous != null && previous.type == TokenType.EQ) {
        _addSuggestions(
            [Keyword.CONST, Keyword.FALSE, Keyword.NULL, Keyword.TRUE]);
      } else {
        _addSuggestion(Keyword.IN);
      }
    } else if (!node.inKeyword.isSynthetic && node.iterable.isSynthetic) {
      _addSuggestion(Keyword.AWAIT);
    }
  }

  void _visitForParts(ForParts node) {
    // Actual: for (int x i^)
    // Parsed: for (int x; i^;)
    // Handle the degenerate case while typing - for (int x i^)
    if (node.condition == entity &&
        entity is SimpleIdentifier &&
        node is ForPartsWithDeclarations) {
      if (_isPreviousTokenSynthetic(entity, TokenType.SEMICOLON)) {
        _addSuggestion(Keyword.IN);
      }
    }
  }

  static bool _isPreviousTokenSynthetic(Object? entity, TokenType type) {
    if (entity is AstNode) {
      var token = entity.beginToken;
      var previousToken = entity.findPrevious(token);
      return previousToken != null &&
          previousToken.isSynthetic &&
          previousToken.type == type;
    }
    return false;
  }
}

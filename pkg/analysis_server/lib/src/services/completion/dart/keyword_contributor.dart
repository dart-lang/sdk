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
  /// The keywords that are valid at the beginning of a pattern (and hence a
  /// guarded pattern).
  static const List<Keyword> patternKeywords = [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.FINAL,
    Keyword.NULL,
    Keyword.TRUE,
    Keyword.VAR,
  ];

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
  void visitAsExpression(AsExpression node) {
    if (identical(entity, node.asOperator) &&
        node.expression is ParenthesizedExpression) {
      _addSuggestion(Keyword.ASYNC);
      _addSuggestion2(ASYNC_STAR);
      _addSuggestion2(SYNC_STAR);
    } else if (identical(entity, node.type)) {
      _addSuggestion(Keyword.DYNAMIC);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitBlock(Block node) {
    var prevStmt = OpType.getPreviousStatement(node, entity);
    if (prevStmt is TryStatement) {
      if (prevStmt.finallyBlock == null) {
        _addSuggestion(Keyword.ON);
        _addSuggestion(Keyword.CATCH);
        _addSuggestion(Keyword.FINALLY);
        if (prevStmt.catchClauses.isEmpty) {
          // If try statement with no catch, on, or finally
          // then only suggest these keywords
          return;
        }
      }
    }

    if (entity is ExpressionStatement) {
      var expression = (entity as ExpressionStatement).expression;
      if (expression is SimpleIdentifier) {
        var token = expression.token;
        var previous = node.findPrevious(token);
        if (previous != null && previous.isSynthetic) {
          previous = node.findPrevious(previous);
        }
        var next = token.next!;
        if (next.isSynthetic) {
          next = next.next!;
        }
        if (previous != null &&
            previous.type == TokenType.CLOSE_PAREN &&
            next.type == TokenType.OPEN_CURLY_BRACKET) {
          _addSuggestion(Keyword.ASYNC);
          _addSuggestion2(ASYNC_STAR);
          _addSuggestion2(SYNC_STAR);
        }
      }
    }
    _addStatementKeywords(node);
    if (node.inCatchClause) {
      _addSuggestion(Keyword.RETHROW);
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitCaseClause(CaseClause node) {
    _addSuggestions(patternKeywords);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final entity = this.entity;
    // Don't suggest class name
    if (entity == node.name) {
      return;
    }
    if (entity == node.classKeyword) {
      var previous = node.findPrevious(node.classKeyword);
      if (previous != null) {
        if (previous.keyword != Keyword.BASE &&
            previous.keyword != Keyword.FINAL &&
            previous.keyword != Keyword.INTERFACE &&
            previous.keyword != Keyword.MIXIN &&
            previous.keyword != Keyword.SEALED) {
          if (previous.keyword != Keyword.ABSTRACT) {
            if (request.featureSet.isEnabled(Feature.sealed_class)) {
              _addSuggestion(Keyword.SEALED);
            }
          } else {
            // abstract ^ class A {}
            if (request.featureSet.isEnabled(Feature.class_modifiers)) {
              _addSuggestions([
                Keyword.BASE,
                Keyword.FINAL,
                Keyword.INTERFACE,
                Keyword.MIXIN
              ]);
            }
          }
        }
        if (request.featureSet.isEnabled(Feature.class_modifiers) &&
            previous.keyword == Keyword.BASE) {
          // base ^ class A {}
          // abstract base ^ class A {}
          _addSuggestion(Keyword.MIXIN);
        }
      }
    } else if (entity == node.mixinKeyword) {
      var previous = node.findPrevious(node.mixinKeyword!);
      if (previous != null) {
        if (previous.keyword != Keyword.BASE) {
          // abstract ^ mixin class A {}
          if (request.featureSet.isEnabled(Feature.class_modifiers)) {
            _addSuggestion(Keyword.BASE);
          }
        }
      }
    } else if (entity == node.rightBracket) {
      _addClassBodyKeywords();
    } else if (entity is ClassMember) {
      _addClassBodyKeywords();
      var index = node.members.indexOf(entity);
      var previous = index > 0 ? node.members[index - 1] : null;
      if (previous is MethodDeclaration && previous.body.isEmpty) {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
    } else {
      _addClassDeclarationKeywords(node);
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
  void visitConditionalExpression(ConditionalExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.initializers.isNotEmpty) {
      if (entity is ConstructorInitializer) {
        _addSuggestion(Keyword.ASSERT);
      }
      var last = node.initializers.last;
      if (last == entity) {
        var previous = node.findPrevious(last.beginToken);
        if (previous != null && previous.end <= request.offset) {
          _addSuggestion(Keyword.SUPER);
          _addSuggestion(Keyword.THIS);
        }
      }
    } else {
      var separator = node.separator;
      if (separator != null) {
        var offset = request.offset;
        if (separator.end <= offset && offset <= separator.next!.offset) {
          _addSuggestion(Keyword.ASSERT);
          _addSuggestion(Keyword.SUPER);
          _addSuggestion(Keyword.THIS);
        }
      }
    }
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.name is SyntheticStringToken) {
      return;
    }
    var parent = node.parent;
    if (!(parent is GuardedPattern && parent.hasWhen)) {
      _addSuggestion(Keyword.WHEN);
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (entity == node.defaultValue) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (!request.featureSet.isEnabled(Feature.enhanced_enums)) {
      return;
    }

    if (entity == node.name) {
      return;
    }

    var semicolon = node.semicolon;
    if (request.offset <= node.leftBracket.offset) {
      if (node.withClause == null) {
        _addSuggestion(Keyword.WITH);
      }
      if (node.implementsClause == null) {
        _addSuggestion(Keyword.IMPLEMENTS);
      }
    } else if (semicolon != null && semicolon.end <= request.offset) {
      _addEnumBodyKeywords();
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // Don't suggest extension name
    if (entity == node.name) {
      return;
    }
    if (entity == node.rightBracket) {
      _addExtensionBodyKeywords();
    } else if (entity is ClassMember) {
      _addExtensionBodyKeywords();
    } else {
      _addExtensionDeclarationKeywords(node);
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _addExpressionKeywords(node);
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
  void visitForElement(ForElement node) {
    _addCollectionElementKeywords();
    _addExpressionKeywords(node);
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

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // If the cursor is at the beginning of the declaration, include the
    // compilation unit keywords.  See dartbug.com/41039.
    if (entity == node.returnType || entity == node.name) {
      _addSuggestion(Keyword.DYNAMIC);
      _addSuggestion(Keyword.VOID);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (entity == node.body) {
      var body = node.body;
      if (!body.isAsynchronous) {
        _addSuggestion(Keyword.ASYNC);
        if (body is! ExpressionFunctionBody) {
          _addSuggestion2(ASYNC_STAR);
          _addSuggestion2(SYNC_STAR);
        }
      }
      var grandParent = node.parent;
      if (body is EmptyFunctionBody &&
          grandParent is FunctionDeclaration &&
          grandParent.parent is CompilationUnit) {
        _addCompilationUnitKeywords();
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (entity == node.type) {
      _addSuggestion(Keyword.DYNAMIC);
      _addSuggestion(Keyword.VOID);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    if (entity == node.rightParenthesis) {
      var caseClause = node.caseClause;
      if (caseClause == null) {
        _addSuggestion(Keyword.CASE);
        _addSuggestion(Keyword.IS);
      } else if (caseClause.guardedPattern.hasWhen) {
        if (caseClause.guardedPattern.whenClause?.expression == null) {
          _addExpressionKeywords(node);
        }
      } else {
        _addSuggestion(Keyword.WHEN);
      }
    } else if (entity == node.thenElement || entity == node.elseElement) {
      _addCollectionElementKeywords();
      _addExpressionKeywords(node);
    } else if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_isPreviousTokenSynthetic(entity, TokenType.CLOSE_PAREN)) {
      // analyzer parser
      // Actual: if (x i^)
      // Parsed: if (x) i^
      _addSuggestion(Keyword.IS);
    } else if (entity == node.rightParenthesis) {
      var caseClause = node.caseClause;
      if (caseClause == null) {
        _addSuggestion(Keyword.CASE);
        _addSuggestion(Keyword.IS);
      } else if (caseClause.guardedPattern.hasWhen) {
        if (caseClause.guardedPattern.whenClause?.expression == null) {
          _addExpressionKeywords(node);
        }
      } else {
        _addSuggestion(Keyword.WHEN);
      }
    } else if (entity == node.thenStatement || entity == node.elseStatement) {
      _addStatementKeywords(node);
    } else if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (entity == node.asKeyword) {
      if (node.deferredKeyword == null) {
        _addSuggestion(Keyword.DEFERRED);
      }
    }
    // Handle degenerate case where import statement does not have a semicolon
    // and the cursor is in the uri string
    if ((entity == node.semicolon && node.uri.offset + 1 != request.offset) ||
        node.combinators.contains(entity)) {
      _addImportDirectiveKeywords(node);
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (entity == node.constructorName) {
      // no keywords in 'new ^' expression
    } else {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (entity == node.isOperator) {
      _addSuggestion(Keyword.IS);
    } else {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    // no suggestions
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (entity == node.body) {
      if (node.body.isEmpty) {
        _addClassBodyKeywords();
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      } else {
        _addSuggestion(Keyword.ASYNC);
        if (node.body is! ExpressionFunctionBody) {
          _addSuggestion2(ASYNC_STAR);
          _addSuggestion2(SYNC_STAR);
        }
      }
    } else if (entity == node.returnType || entity == node.name) {
      // If the cursor is at the beginning of the declaration, include the class
      // body keywords.  See dartbug.com/41039.
      _addClassBodyKeywords();
    }
  }

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
  void visitMixinDeclaration(MixinDeclaration node) {
    final entity = this.entity;
    // Don't suggest mixin name
    if (entity == node.name) {
      return;
    }
    if (entity == node.rightBracket) {
      _addClassBodyKeywords();
    } else if (entity is ClassMember) {
      _addClassBodyKeywords();
      var index = node.members.indexOf(entity);
      var previous = index > 0 ? node.members[index - 1] : null;
      if (previous is MethodDeclaration && previous.body.isEmpty) {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
    } else if (entity != node.mixinKeyword) {
      _addMixinDeclarationKeywords(node);
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (entity is SimpleIdentifier && entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    var expression = node.expression;
    if (expression is Identifier || expression is PropertyAccess) {
      if (entity == node.rightParenthesis) {
        var next = expression.endToken.next;
        if (next == entity || next == droppedToken) {
          // Fasta parses `if (x i^)` as `if (x ^) where the `i` is in the token
          // stream but not part of the ParenthesizedExpression.
          _addSuggestion(Keyword.IS);
          return;
        }
      }
    }
    _addExpressionKeywords(node);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (entity != node.identifier) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // suggestions before '.' but not after
    if (entity != node.propertyName) {
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
  void visitReturnStatement(ReturnStatement node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
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

  @override
  void visitSpreadElement(SpreadElement node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _addStatementKeywords(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    final entity = this.entity;
    if (entity == node.colon && request.target.offset <= node.colon.offset) {
      var previous = node.colon.previous?.keyword;
      if (previous == Keyword.AS) {
        _addSuggestion(Keyword.DYNAMIC);
      } else if (previous != Keyword.WHEN) {
        _addSuggestions([Keyword.AS, Keyword.WHEN]);
      }
    } else if (entity is GuardedPattern) {
      var pattern = node.guardedPattern.pattern;
      if (pattern is DeclaredVariablePattern) {
        var keyword = pattern.keyword;
        if (keyword == null) {
          _addConstantExpressionKeywords(node);
          _addSuggestions([Keyword.FINAL, Keyword.VAR]);
        }
      } else if (pattern is ConstantPattern) {
        _addConstantExpressionKeywords(node);
        _addSuggestions([Keyword.FINAL, Keyword.VAR]);
      } else {
        _addConstantExpressionKeywords(node);
      }
    } else {
      _addStatementKeywords(node);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    } else if (entity == node.rightBracket) {
      _addSuggestion(Keyword.CASE);
      _addSuggestion2(DEFAULT_COLON);
      if (node.members.isNotEmpty) {
        _addStatementKeywords(node);
      }
    }
    if (node.members.contains(entity)) {
      _addSuggestion(Keyword.CASE);
      _addSuggestion2(DEFAULT_COLON);
      if (entity != node.members.first) {
        _addStatementKeywords(node);
      }
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    var variableDeclarationList = node.variables;
    if (entity != variableDeclarationList) return;
    var variables = variableDeclarationList.variables;
    if (variables.isEmpty || request.offset > variables.first.beginToken.end) {
      return;
    }
    if (node.externalKeyword == null) {
      _addSuggestion(Keyword.EXTERNAL);
    }
    if (variableDeclarationList.lateKeyword == null &&
        request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
    }
    if (!variables.first.isConst) {
      _addSuggestion(Keyword.CONST);
    }
    if (!variables.first.isFinal) {
      _addSuggestion(Keyword.FINAL);
    }
  }

  @override
  void visitTryStatement(TryStatement node) {
    var obj = entity;
    if (obj is CatchClause ||
        (obj is KeywordToken && obj.value() == Keyword.FINALLY)) {
      _addSuggestion(Keyword.ON);
      _addSuggestion(Keyword.CATCH);
      return;
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _addSuggestion(Keyword.DYNAMIC);
    _addSuggestion(Keyword.VOID);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _addExpressionKeywords(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (entity == node.initializer) {
      _addExpressionKeywords(node);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var keyword = node.keyword;
    var variables = node.variables;
    if (variables.isNotEmpty && entity == variables[0]) {
      var type = node.type;
      if (type == null && keyword?.keyword != Keyword.VAR) {
        _addSuggestion(Keyword.DYNAMIC);
        _addSuggestion(Keyword.VOID);
      } else if (type is RecordTypeAnnotation) {
        // This might be a record pattern that happens to look like a type, in
        // which case the user might be typing `in`.
        _addSuggestion(Keyword.IN);
      }
    }
  }

  @override
  void visitWhenClause(WhenClause node) {
    var whenKeyword = node.whenKeyword;
    if (!whenKeyword.isSynthetic && request.offset > whenKeyword.end) {
      _addExpressionKeywords(node);
    }
  }

  void _addClassBodyKeywords() {
    _addSuggestions([
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.FACTORY,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ]);
    if (request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
    }
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

  void _addCollectionElementKeywords() {
    if (request.featureSet.isEnabled(Feature.control_flow_collections)) {
      _addSuggestions([
        Keyword.FOR,
        Keyword.IF,
      ]);
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

  void _addEnumBodyKeywords() {
    _addSuggestions([
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.LATE,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ]);
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

  void _addExtensionBodyKeywords() {
    _addSuggestions([
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ]);
    if (request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
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

  void _addStatementKeywords(AstNode node) {
    if (node.inClassMemberBody) {
      _addSuggestions([Keyword.SUPER, Keyword.THIS]);
    }
    if (node.inAsyncMethodOrFunction) {
      _addSuggestion(Keyword.AWAIT);
    } else if (node.inAsyncStarOrSyncStarMethodOrFunction) {
      _addSuggestion(Keyword.AWAIT);
      _addSuggestion(Keyword.YIELD);
      _addSuggestion2(YIELD_STAR);
    }
    if (node.inLoop) {
      _addSuggestions([Keyword.BREAK, Keyword.CONTINUE]);
    }
    if (node.inSwitch) {
      _addSuggestions([Keyword.BREAK]);
    }
    if (_isEntityAfterIfWithoutElse(node)) {
      _addSuggestions([Keyword.ELSE]);
    }
    _addSuggestions([
      Keyword.ASSERT,
      Keyword.CONST,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ]);
    if (request.featureSet.isEnabled(Feature.non_nullable)) {
      _addSuggestion(Keyword.LATE);
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

  bool _isEntityAfterIfWithoutElse(AstNode node) {
    var block = node.thisOrAncestorOfType<Block>();
    if (block == null) {
      return false;
    }
    final entity = this.entity;
    if (entity is Statement) {
      var entityIndex = block.statements.indexOf(entity);
      if (entityIndex > 0) {
        var prevStatement = block.statements[entityIndex - 1];
        return prevStatement is IfStatement &&
            prevStatement.elseStatement == null;
      }
    }
    if (entity is Token) {
      for (var statement in block.statements) {
        if (statement.endToken.next == entity) {
          return statement is IfStatement && statement.elseStatement == null;
        }
      }
    }
    return false;
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

extension on GuardedPattern {
  /// Return `true` if this pattern has, or might have, a `when` keyword.
  bool get hasWhen {
    if (whenClause != null) {
      return true;
    }
    var pattern = this.pattern;
    if (pattern is DeclaredVariablePattern) {
      if (pattern.name.lexeme == 'when') {
        final type = pattern.type;
        if (type is NamedType && type.typeArguments == null) {
          return true;
        }
      }
    }
    return false;
  }
}

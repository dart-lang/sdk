// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/declaration_helper.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_helper.dart';
import 'package:analysis_server/src/services/completion/dart/label_helper.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/token.dart';

/// A completion pass that will create candidate suggestions based on the
/// elements in scope in the library containing the selection, as well as
/// suggestions that are not related to elements, such as keywords.
//
// The visit methods in this class are allowed to visit the parent of the
// visited node (the covering node), but are not allowed to visit children. This
// rule will prevent the introduction of an infinite loop between the visit
// methods of the parent and child.
class InScopeCompletionPass extends SimpleAstVisitor<void> {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The helper used to suggest declarations that are in scope.
  late final DeclarationHelper declarationHelper =
      DeclarationHelper(collector: collector, offset: offset);

  /// The helper used to suggest keywords.
  late final KeywordHelper keywordHelper = KeywordHelper(
      collector: collector, featureSet: featureSet, offset: offset);

  /// The helper used to suggest labels.
  late final LabelHelper labelHelper = LabelHelper(collector: collector);

  /// Initialize a newly created completion visitor that can use the [state] to
  /// add candidate suggestions to the [collector].
  InScopeCompletionPass({required this.state, required this.collector});

  /// Return the feature set that applies to the library for which completions
  /// are being computed.
  FeatureSet get featureSet => state.libraryElement.featureSet;

  /// Return the offset at which completion was requested.
  int get offset => state.selection.offset;

  /// Return the node that should be used as the context in which completion is
  /// occurring.
  ///
  /// This is normally the covering node, but if the covering node begins with
  /// an identifier (or keyword) and the [offset] is covered by the identifier
  /// or keyword, then we look for the highest node that also begins with the
  /// same token, but that isn't part of a list of nodes, and use the parent of
  /// that node.
  ///
  /// This allows us more context for completing what the user might be trying
  /// to write and also reduces the complexity of the visitor and reduces the
  /// amount of code duplication.
  AstNode get _completionNode {
    var selection = state.selection;
    var coveringNode = selection.coveringNode;
    var beginToken = coveringNode.beginToken;
    if (!beginToken.isKeywordOrIdentifier ||
        !selection.isCoveredByToken(beginToken)) {
      return coveringNode;
    }
    var child = coveringNode;
    var parent = child.parent;
    while (parent != null &&
        parent.beginToken == beginToken &&
        !(child is! SimpleIdentifier && parent.isChildInList(child))) {
      child = parent;
      parent = child.parent;
    }
    // The [child] is now the highest node that starts with the [beginToken].
    if (parent != null &&
        !(child is! SimpleIdentifier && parent.isChildInList(child))) {
      return parent;
    }
    return child;
  }

  /// Compute the candidate suggestions associated with this pass.
  void computeSuggestions() {
    _completionNode.accept(this);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
      var (:before, after: _) = node.argumentsBeforeAndAfterOffset(offset);
      if (before != null) {
        _handledPossibleClosure(before);
        _forExpression(before);
        return;
      }
      // collector.completionLocation = 'ArgumentList_${context}_named';
      var parent = node.parent;
      var element = switch (parent) {
        InstanceCreationExpression invocation =>
          invocation.constructorName.staticElement,
        MethodInvocation invocation => invocation.methodName.staticElement,
        FunctionExpressionInvocation invocation => invocation.staticElement,
        _ => null,
      };
      if (element is ExecutableElement) {
        // Only suggest expression keywords if at least one of the parameters is
        // a positional parameter.
        if (element.parameters.any((element) => element.isPositional)) {
          _forExpression(parent);
        }
      } else if (parent is Expression) {
        _forExpression(parent);
      }
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (node.asOperator.coversOffset(offset) &&
        node.expression is ParenthesizedExpression) {
      // If the user has typed `as` after something that could be either a
      // parenthesized expression or a parameter list, the parser will recover
      // by parsing an `as` expression. This handles the case where the user is
      // actually trying to write a function expression.
      // TODO(brianwilkerson) Decide whether we should do more to ensure that
      //  the expression could be a parameter list.
      keywordHelper.addFunctionBodyModifiers(null);
    } else if (node.type.coversOffset(offset)) {
      collector.completionLocation = 'AsExpression_type';
      // TODO(brianwilkerson) Add a parameter to _forTypeAnnotation to prohibit
      //  producing `void`, then convert the call below.
      keywordHelper.addKeyword(Keyword.DYNAMIC);
    }
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    collector.completionLocation = 'ConstructorDeclaration_initializer';
    keywordHelper.addConstructorInitializerKeywords(
        node.parent as ConstructorDeclaration);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (offset <= node.assertKeyword.end) {
      keywordHelper.addKeyword(Keyword.ASSERT);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    collector.completionLocation = 'AssignmentExpression_rightHandSide';
    _forExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    collector.completionLocation = 'AwaitExpression_expression';
    _forExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var operator = node.operator.lexeme;
    collector.completionLocation = 'BinaryExpression_${operator}_rightOperand';
    _forExpression(node);
  }

  @override
  void visitBlock(Block node) {
    if (offset <= node.leftBracket.offset) {
      var parent = node.parent;
      if (parent is BlockFunctionBody) {
        parent.parent?.accept(this);
      }
      return;
    }
    collector.completionLocation = 'Block_statement';
    var previousStatement = node.statements.elementBefore(offset);
    if (previousStatement is TryStatement) {
      if (previousStatement.finallyBlock == null) {
        // TODO(brianwilkerson) Consider adding `on ^ {}`, `catch (e) {^}`, and
        //  `finally {^}`.
        keywordHelper.addKeyword(Keyword.ON);
        keywordHelper.addKeyword(Keyword.CATCH);
        keywordHelper.addKeyword(Keyword.FINALLY);
        if (previousStatement.catchClauses.isEmpty) {
          // If the try statement has no catch, on, or finally then only suggest
          // these keywords, because at least one of these clauses is required.
          return;
        }
      }
    } else if (previousStatement is IfStatement &&
        previousStatement.elseKeyword == null) {
      keywordHelper.addKeyword(Keyword.ELSE);
    }
    _forStatement(node);
    if (node.inCatchClause) {
      keywordHelper.addKeyword(Keyword.RETHROW);
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _forExpression(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    var breakEnd = node.breakKeyword.end;
    if (offset <= breakEnd) {
      keywordHelper.addKeyword(Keyword.BREAK);
    } else if (breakEnd < offset && offset <= node.semicolon.offset) {
      labelHelper.addLabels(node);
    }
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    collector.completionLocation = 'CascadeExpression_cascadeSection';
    _forExpression(node);
  }

  @override
  void visitCaseClause(CaseClause node) {
    collector.completionLocation = 'CaseClause_pattern';
    _forPattern(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    var onKeyword = node.onKeyword;
    var catchKeyword = node.catchKeyword;
    if (onKeyword != null) {
      if (offset <= onKeyword.end) {
        keywordHelper.addKeyword(Keyword.ON);
      } else if (catchKeyword != null && offset < catchKeyword.offset) {
        _forTypeAnnotation();
      }
    }
    if (catchKeyword != null &&
        offset >= catchKeyword.offset &&
        offset <= catchKeyword.end) {
      keywordHelper.addKeyword(Keyword.CATCH);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (offset < node.classKeyword.offset) {
      keywordHelper.addClassModifiers(node);
      return;
    }
    if (offset <= node.classKeyword.end) {
      keywordHelper.addKeyword(Keyword.CLASS);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the class.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addClassDeclarationKeywords(node);
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ClassDeclaration_member';
      _forClassMember();
      var element = node.members.elementBefore(offset);
      if (element is MethodDeclaration) {
        var body = element.body;
        if (body.isEmpty) {
          keywordHelper.addFunctionBodyModifiers(body);
        }
      }
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    declarationHelper.addLexicalDeclarations(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // This method is only invoked when the cursor is between two members.
    var surroundingMembers = node.membersBeforeAndAfterOffset(offset);
    var before = surroundingMembers.before;
    if (before != null && _handledIncompletePrecedingUnitMember(node, before)) {
      // The  member is incomplete, so assume that the user is completing it
      //rather than starting a new member.
      return;
    }
    _forCompilationUnitMember(node, surroundingMembers);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    // TODO(brianwilkerson) Consider adding a location for the condition.
    if (offset >= node.question.end && offset <= node.colon.offset) {
      collector.completionLocation = 'ConditionalExpression_thenExpression';
    } else if (offset >= node.colon.end) {
      collector.completionLocation = 'ConditionalExpression_elseExpression';
    }
    _forExpression(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    var expression = node.expression;
    if (expression is SimpleIdentifier) {
      node.parent?.accept(this);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var separator = node.separator;
    if (separator != null) {
      if (offset >= separator.end && offset <= node.body.offset) {
        collector.completionLocation = 'ConstructorDeclaration_initializer';
        keywordHelper.addConstructorInitializerKeywords(node);
      }
    }
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    collector.completionLocation = 'ConstructorDeclaration_initializer';
    keywordHelper.addConstructorInitializerKeywords(
        node.parent as ConstructorDeclaration);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _forExpression(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    var continueEnd = node.continueKeyword.end;
    if (offset <= continueEnd) {
      keywordHelper.addKeyword(Keyword.CONTINUE);
    } else if (continueEnd < offset && offset <= node.semicolon.offset) {
      labelHelper.addLabels(node);
    }
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var name = node.name;
    if (name is SyntheticStringToken) {
      return;
    }
    if (node.keyword != null) {
      var type = node.type;
      if (!type.isSingleIdentifier && name.coversOffset(offset)) {
        // Don't suggest a name for the variable.
        return;
      }
      // Otherwise it's possible that the type is actually the name and the name
      // is the going to be the keyword `when`.
    }
    var parent = node.parent;
    if (!(parent is GuardedPattern && parent.hasWhen)) {
      keywordHelper.addKeyword(Keyword.WHEN);
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var defaultValue = node.defaultValue;
    if (defaultValue is Expression && defaultValue.coversOffset(offset)) {
      collector.completionLocation = 'DefaultFormalParameter_defaultValue';
      _forExpression(defaultValue);
    } else {
      node.parameter.accept(this);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    if (offset <= node.doKeyword.end) {
      _forStatement(node);
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    var parent = node.parent;
    if (parent is Block) {
      var statements = parent.statements;
      var index = statements.indexOf(node);
      if (index > 0) {
        var previousStatement = statements[index - 1];
        if (previousStatement is TryStatement &&
            previousStatement.finallyBlock == null) {
          keywordHelper.addTryClauseKeywords(canHaveFinally: true);
          if (previousStatement.catchClauses.isEmpty) {
            // Don't suggest a new statement because the `try` statement is
            // incomplete.
            return;
          }
        }
      }
    }
    if (offset <= node.semicolon.offset) {
      _forStatement(node);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (!featureSet.isEnabled(Feature.enhanced_enums)) {
      return;
    }
    if (offset < node.enumKeyword.offset) {
      // There are no modifiers for enums.
      return;
    }
    if (offset <= node.enumKeyword.end) {
      keywordHelper.addKeyword(Keyword.ENUM);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the mixin.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addEnumDeclarationKeywords(node);
      return;
    }
    var rightBracket = node.rightBracket;
    if (!rightBracket.isSynthetic && offset >= rightBracket.end) {
      return;
    }
    var semicolon = node.semicolon;
    if (semicolon != null && offset >= semicolon.end) {
      collector.completionLocation = 'EnumDeclaration_member';
      _forEnumMember();
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var expression = node.expression;
    if (offset >= node.functionDefinition.end && offset <= expression.end) {
      collector.completionLocation = 'ExpressionFunctionBody_expression';
      _forExpression(expression);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    collector.completionLocation = 'ExpressionStatement_expression';
    if (_forIncompletePrecedingStatement(node)) {
      if (node.isSingleIdentifier) {
        var precedingStatement = node.precedingStatement;
        if (precedingStatement is TryStatement) {
          return;
        }
      }
    }
    _forStatement(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (offset < node.extensionKeyword.offset) {
      // There are no modifiers for extensions.
      return;
    }
    if (offset <= node.extensionKeyword.end) {
      keywordHelper.addKeyword(Keyword.EXTENSION);
      return;
    }
    var name = node.name;
    if (name != null && offset <= name.end) {
      keywordHelper.addKeyword(Keyword.ON);
      if (featureSet.isEnabled(Feature.inline_class)) {
        keywordHelper.addPseudoKeyword('type');
      }
      // TODO(brianwilkerson) Suggest a name for the extension.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      if (node.onKeyword.isSynthetic) {
        keywordHelper.addExtensionDeclarationKeywords(node);
      } else {
        collector.completionLocation = 'ExtensionDeclaration_extendedType';
      }
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ExtensionDeclaration_member';
      _forExtensionMember();
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _forExpression(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (offset >= node.representation.end &&
        (offset <= node.leftBracket.offset || node.leftBracket.isSynthetic)) {
      keywordHelper.addKeyword(Keyword.IMPLEMENTS);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _forIncompletePrecedingClassMember(node);
    var fields = node.fields;
    var type = fields.type;
    if (type == null) {
      var variables = fields.variables;
      var firstField = variables.firstOrNull;
      if (firstField != null) {
        var name = firstField.name;
        if (variables.length == 1 && name.isKeyword && offset > name.end) {
          // The parser has recovered by using one of the existing keywords as
          // the name of a field, which means that there is no type.
          keywordHelper.addFieldDeclarationKeywords(node,
              keyword: name.keyword);
        } else if (offset <= name.end) {
          keywordHelper.addFieldDeclarationKeywords(node);
        }
      }
    } else {
      if (offset <= type.end) {
        keywordHelper.addFieldDeclarationKeywords(node);
        // TODO(brianwilkerson) `var` should only be suggested if neither
        //  `static` nor `final` are present.
        keywordHelper.addKeyword(Keyword.VAR);
      }
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
    var literal = node.thisOrAncestorOfType<TypedLiteral>();
    if (literal is ListLiteral) {
      _forCollectionElement(literal, literal.elements);
    } else if (literal is SetOrMapLiteral) {
      _forCollectionElement(literal, literal.elements);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (offset >= node.end) {
      var parent = node.parent;
      if (parent is FunctionExpression) {
        visitFunctionExpression(parent);
        return;
      }
    }
    var parameters = node.parameters;
    var precedingParameter = parameters.elementBefore(offset);
    if (precedingParameter != null && precedingParameter.isIncomplete) {
      precedingParameter.accept(this);
      return;
    }

    keywordHelper.addFormalParameterKeywords(node);
    _forTypeAnnotation();
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (offset >= node.leftSeparator.end &&
        offset <= node.rightSeparator.offset) {
      var condition = node.condition;
      if (condition is SimpleIdentifier &&
          node.leftSeparator.isSynthetic &&
          node.rightSeparator.isSynthetic) {
        // Handle the degenerate case while typing `for (int x i^)`.
        // Actual: for (int x i^)
        // Parsed: for (int x; i^;)
        keywordHelper.addKeyword(Keyword.IN);
        return;
      }
      _forExpression(node);
    } else if (offset >= node.rightSeparator.end) {
      _forExpression(node);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    if (offset <= node.forKeyword.end) {
      _forStatement(node);
    } else if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
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
            if (endGroup != null && offset >= endGroup.end) {
              // Actual: for (va^)
              // Parsed: for (va^; ;)
              keywordHelper.addKeyword(Keyword.IN);
            }
          }
        }
      } else if (parts is ForPartsWithExpression &&
          parts.leftSeparator.isSynthetic &&
          parts.initialization is SimpleIdentifier) {
        keywordHelper.addKeyword(Keyword.FINAL);
        keywordHelper.addKeyword(Keyword.VAR);
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // If the cursor is at the beginning of the declaration, include the
    // compilation unit keywords. See dartbug.com/41039.
    var returnType = node.returnType;
    if ((returnType == null || returnType.beginToken == returnType.endToken) &&
        offset <= node.name.offset) {
      collector.completionLocation = 'FunctionDeclaration_returnType';
      _forTypeAnnotation();
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (offset >=
            (node.parameters?.end ?? node.typeParameters?.end ?? node.offset) &&
        offset <= node.body.offset) {
      var body = node.body;
      keywordHelper.addFunctionBodyModifiers(body);
      var grandParent = node.parent;
      if (body is EmptyFunctionBody &&
          grandParent is FunctionDeclaration &&
          grandParent.parent is CompilationUnit) {
        _forCompilationUnitDeclaration();
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _forExpression(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _forExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (node.typedefKeyword.coversOffset(offset)) {
      keywordHelper.addKeyword(Keyword.TYPEDEF);
    }
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var returnType = node.returnType;
    if (returnType != null && offset <= returnType.end) {
      keywordHelper.addFormalParameterKeywords(node.parentFormalParameterList);
      _forTypeAnnotation();
    } else if (returnType == null && offset < node.name.offset) {
      _forTypeAnnotation();
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.typedefKeyword.coversOffset(offset)) {
      keywordHelper.addKeyword(Keyword.TYPEDEF);
    } else if (offset >= node.equals.end && offset <= node.semicolon.offset) {
      _forTypeAnnotation();
    }
  }

  @override
  void visitIfElement(IfElement node) {
    var expression = node.expression;
    if (offset > expression.end && offset <= node.rightParenthesis.offset) {
      var caseClause = node.caseClause;
      if (caseClause == null) {
        keywordHelper.addKeyword(Keyword.CASE);
        keywordHelper.addKeyword(Keyword.IS);
      } else if (caseClause.guardedPattern.hasWhen) {
        if (caseClause.guardedPattern.whenClause?.expression == null) {
          keywordHelper.addExpressionKeywords(node);
        }
      } else {
        keywordHelper.addKeyword(Keyword.WHEN);
      }
    } else if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
      keywordHelper.addExpressionKeywords(node);
    } else if (offset >= node.rightParenthesis.end) {
      // TODO(brianwilkerson) Ensure that we are suggesting `else` after the
      //  then expression.
      var literal = node.thisOrAncestorOfType<TypedLiteral>();
      if (literal is ListLiteral) {
        _forCollectionElement(literal, literal.elements);
      } else if (literal is SetOrMapLiteral) {
        _forCollectionElement(literal, literal.elements);
      }
      // var thenElement = node.thenElement;
      // if (offset >= thenElement.end &&
      //     !thenElement.isSynthetic &&
      //     node.elseKeyword == null) {
      //   keywordHelper.addKeyword(Keyword.ELSE);
      // }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (node.rightParenthesis.isSynthetic) {
      // analyzer parser
      // Actual: if (x i^)
      // Parsed: if (x) i^
      keywordHelper.addKeyword(Keyword.IS);
      return;
    }
    var expression = node.expression;
    if (offset <= node.ifKeyword.end) {
      _forStatement(node);
    } else if (offset > expression.end &&
        offset <= node.rightParenthesis.offset) {
      var caseClause = node.caseClause;
      if (caseClause == null) {
        keywordHelper.addKeyword(Keyword.CASE);
        keywordHelper.addKeyword(Keyword.IS);
      } else if (caseClause.guardedPattern.hasWhen) {
        if (caseClause.guardedPattern.whenClause?.expression == null) {
          _forExpression(node);
        }
      } else {
        keywordHelper.addKeyword(Keyword.WHEN);
      }
    } else if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
      _forExpression(node);
    } else if (offset >= node.rightParenthesis.end) {
      _forStatement(node);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (offset <= node.uri.offset) {
      return;
    } else if (offset <= node.uri.end) {
      // TODO(brianwilkerson) Complete the URI.
    } else {
      keywordHelper.addImportDirectiveKeywords(node);
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _forExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var keyword = node.keyword;
    if (keyword != null && offset > keyword.end) {
      // no keywords in 'new ^' expression
    } else {
      _forExpression(node);
    }
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    declarationHelper.addLexicalDeclarations(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    var isOperator = node.isOperator;
    if (isOperator.coversOffset(offset)) {
      keywordHelper.addKeyword(Keyword.IS);
    } else if (offset < isOperator.offset) {
      _forExpression(node);
    } else if (offset > isOperator.end) {
      // TODO(brianwilkerson) Suggest the types available in the current scope.
      // declarationHelper.addTypes();
    }
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    if (offset >= node.end) {
      var unit = node.parent;
      if (unit is CompilationUnit) {
        _forDirective(unit, node);
        var (before: _, :after) = unit.membersBeforeAndAfterMember(node);
        if (after is CompilationUnitMember?) {
          _forCompilationUnitDeclaration();
        }
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    final offset = this.offset;
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ListLiteral_element';
      _forCollectionElement(node, node.elements);
    }
  }

  @override
  void visitListPattern(ListPattern node) {
    collector.completionLocation = 'ListPattern_element';
    _forPattern(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    collector.completionLocation = 'LogicalAndPattern_rightOperand';
    _forPattern(node);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    collector.completionLocation = 'LogicalOrPattern_rightOperand';
    _forPattern(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    if (offset == node.offset) {
      node.parent?.accept(this);
    } else if (offset >= node.separator.end) {
      collector.completionLocation = 'MapLiteralEntry_value';
    }
  }

  @override
  void visitMapPattern(MapPattern node) {
    collector.completionLocation = 'MapPatternEntry_key';
    _forConstantExpression(node);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    var separator = node.separator;
    if (separator.isSynthetic || offset <= separator.offset) {
      node.parent?.accept(this);
      return;
    }
    collector.completionLocation = 'MapPatternEntry_value';
    _forPattern(node, mustBeConst: false);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (offset >= node.firstTokenAfterCommentAndMetadata.previous!.offset &&
        offset <= node.name.end) {
      _forTypeAnnotation();
      // If the cursor is at the beginning of the declaration, include the class
      // member keywords.  See dartbug.com/41039.
      keywordHelper.addClassMemberKeywords();
    }
    var body = node.body;
    var tokenBeforeBody = body.beginToken.previous!;
    if (offset >= tokenBeforeBody.end && offset <= body.offset) {
      if (body.keyword == null) {
        keywordHelper.addFunctionBodyModifiers(body);
      }
      if (body.isEmpty) {
        keywordHelper.addClassMemberKeywords();
      }
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (offset < node.mixinKeyword.offset) {
      keywordHelper.addMixinModifiers(node);
      return;
    }
    if (offset <= node.mixinKeyword.end) {
      keywordHelper.addKeyword(Keyword.MIXIN);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the mixin.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addMixinDeclarationKeywords(node);
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'MixinDeclaration_member';
      _forMixinMember();
      var element = node.members.elementBefore(offset);
      if (element is MethodDeclaration) {
        var body = element.body;
        if (body.isEmpty) {
          keywordHelper.addFunctionBodyModifiers(body);
        }
      }
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (offset >= node.name.end) {
      _forExpression(node);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _forTypeAnnotation();
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _forExpression(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    var expression = node.expression;
    if (expression is Identifier || expression is PropertyAccess) {
      if (offset == node.rightParenthesis.offset) {
        var next = expression.endToken.next;
        if (next?.type == TokenType.IDENTIFIER) {
          // Fasta parses `if (x i^)` as `if (x ^)` where the `i` is in the
          // token stream but not part of the `ParenthesizedExpression`.
          keywordHelper.addKeyword(Keyword.IS);
          return;
        }
      }
    }
    _forExpression(node);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    collector.completionLocation = 'ParenthesizedPattern_expression';
    _forPattern(node);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _forExpression(node);
  }

  @override
  void visitPatternField(PatternField node) {
    var name = node.name;
    if (name != null && offset <= name.colon.offset) {
      // TODO(brianwilkerson) Suggest the properties of the object or fields of
      //  the record.
      return;
    }
    if (name == null) {
      var parent = node.parent;
      if (parent is ObjectPattern) {
        // TODO(brianwilkerson) Suggest the properties of the object.
        // _addPropertiesOfType(parent.type.type);
      } else if (parent is RecordPattern) {
        _forPattern(node);
        // TODO(brianwilkerson) If we know the expected record type, add the
        //  names of any named fields.
      }
    } else if (name.name == null) {
      collector.completionLocation = 'PatternField_pattern';
      _forVariablePattern();
    } else {
      collector.completionLocation = 'PatternField_pattern';
      _forPattern(node, mustBeConst: false);
    }
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _forExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _forExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (offset <= node.period.offset) {
      _forExpression(node);
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _forExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // suggestions before '.' but not after
    if (offset <= node.operator.offset) {
      _forExpression(node);
    }
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    collector.completionLocation = 'RecordLiteral_fields';
    _forExpression(node);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _forExpression(node);
    // TODO(brianwilkerson) Is there a reason we aren't suggesting 'void'?
    keywordHelper.addKeyword(Keyword.DYNAMIC);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    collector.completionLocation = 'ConstructorDeclaration_initializer';
    keywordHelper.addConstructorInitializerKeywords(
        node.parent as ConstructorDeclaration);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    var operand = node.operand;
    if (operand is SimpleIdentifier &&
        offset >= node.operator.end &&
        offset <= operand.end) {
      keywordHelper.addExpressionKeywords(node);
    }
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    collector.completionLocation = 'RestPatternElement_pattern';
    _forPattern(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    collector.completionLocation = 'ReturnStatement_expression';
    if (offset <= node.returnKeyword.end) {
      _forStatement(node);
    } else {
      _forExpression(node.expression ?? node);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var offset = this.offset;
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'SetOrMapLiteral_element';
      _forCollectionElement(node, node.elements);
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var name = node.name;
    if (name != null && node.isSingleIdentifier) {
      if (name.isKeyword) {
        if (name.keyword == Keyword.REQUIRED && node.covariantKeyword == null) {
          keywordHelper.addKeyword(Keyword.COVARIANT);
        }
        _forTypeAnnotation();
        return;
      } else if (name.isSynthetic) {
        keywordHelper
            .addFormalParameterKeywords(node.parentFormalParameterList);
        _forTypeAnnotation();
      } else {
        keywordHelper
            .addFormalParameterKeywords(node.parentFormalParameterList);
        _forTypeAnnotation();
      }
    }
    var type = node.type;
    if (type != null) {
      if (type.beginToken.coversOffset(offset)) {
        keywordHelper
            .addFormalParameterKeywords(node.parentFormalParameterList);
        _forTypeAnnotation();
      } else if (type is GenericFunctionType &&
          offset < type.functionKeyword.offset &&
          type.returnType == null) {
        _forTypeAnnotation();
      }
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    collector.completionLocation = 'SpreadElement_expression';
    _forExpression(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    collector.completionLocation = 'ConstructorDeclaration_initializer';
    keywordHelper.addConstructorInitializerKeywords(
        node.parent as ConstructorDeclaration);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _forStatement(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    if (offset <= node.keyword.offset) {
      keywordHelper.addKeyword(Keyword.CASE);
      keywordHelper.addKeywordFromText(Keyword.DEFAULT, ':');
    } else if (offset <= node.keyword.end) {
      if (node.colon.isSynthetic) {
        keywordHelper.addKeywordFromText(Keyword.DEFAULT, ':');
      } else {
        keywordHelper.addKeyword(Keyword.DEFAULT);
      }
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
      _forExpression(node);
    } else if (offset >= node.leftBracket.end &&
        offset <= node.rightBracket.offset) {
      _forPattern(node);
    }
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (node.arrow.isSynthetic) {
      // TODO(brianwilkerson) The user is completing the pattern.
      return;
    }
    var expression = node.expression;
    var endToken = expression.endToken;
    if (endToken == expression.beginToken || endToken.isSynthetic) {
      // The user is completing in the expression.
      _forExpression(node.expression);
    }
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    if (offset <= node.keyword.end) {
      keywordHelper.addKeyword(Keyword.CASE);
    } else if (offset <= node.colon.offset) {
      var previous = node.colon.previous!;
      var previousKeyword = previous.keyword;
      if (previousKeyword == null) {
        if (previous.isSynthetic || previous.coversOffset(offset)) {
          keywordHelper.addExpressionKeywords(node);
          keywordHelper.addKeyword(Keyword.FINAL);
          keywordHelper.addKeyword(Keyword.VAR);
        } else {
          keywordHelper.addKeyword(Keyword.AS);
          keywordHelper.addKeyword(Keyword.WHEN);
        }
      } else if (previousKeyword == Keyword.AS) {
        keywordHelper.addKeyword(Keyword.DYNAMIC);
      } else if (previousKeyword != Keyword.WHEN) {
        keywordHelper.addKeyword(Keyword.AS);
        keywordHelper.addKeyword(Keyword.WHEN);
      }
    } else {
      if (node.statements.isEmpty || offset <= node.statements.first.offset) {
        keywordHelper.addKeyword(Keyword.CASE);
        keywordHelper.addKeywordFromText(Keyword.DEFAULT, ':');
      }
      _forStatement(node);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (offset <= node.switchKeyword.end) {
      _forStatement(node);
    } else if (offset >= node.leftParenthesis.end &&
        offset <= node.rightParenthesis.offset) {
      _forExpression(node);
    } else if (offset >= node.leftBracket.end &&
        offset <= node.rightBracket.offset) {
      var members = node.members;
      keywordHelper.addKeyword(Keyword.CASE);
      keywordHelper.addKeywordFromText(Keyword.DEFAULT, ':');
      if (members.isNotEmpty) {
        if (!members.any((element) => element is SwitchDefault)) {
          keywordHelper.addKeywordFromText(Keyword.DEFAULT, ':');
        }
        var element = members.elementBefore(offset);
        if (element != null) {
          _forStatement(element);
        }
      }
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _forExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _forExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    collector.completionLocation = 'ThrowExpression_expression';
    _forExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (_handledRecovery(node)) {
      return;
    }

    var variableDeclarationList = node.variables;
    var variables = variableDeclarationList.variables;
    if (variables.isEmpty || offset > variables.first.beginToken.end) {
      return;
    }
    if (node.externalKeyword == null) {
      keywordHelper.addKeyword(Keyword.EXTERNAL);
    }
    if (variableDeclarationList.lateKeyword == null &&
        featureSet.isEnabled(Feature.non_nullable)) {
      keywordHelper.addKeyword(Keyword.LATE);
    }
    if (!variables.first.isConst) {
      keywordHelper.addKeyword(Keyword.CONST);
    }
    if (!variables.first.isFinal) {
      keywordHelper.addKeyword(Keyword.FINAL);
    }
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (offset <= node.tryKeyword.end) {
      _forStatement(node);
    } else if (offset >= node.body.end) {
      var finallyKeyword = node.finallyKeyword;
      if (finallyKeyword == null) {
        var catchClauses = node.catchClauses;
        var lastClause = catchClauses.lastOrNull;
        if (lastClause == null) {
          keywordHelper.addTryClauseKeywords(canHaveFinally: true);
        } else {
          keywordHelper.addTryClauseKeywords(
              canHaveFinally: offset >= lastClause.end);
        }
      } else if (offset < finallyKeyword.offset) {
        keywordHelper.addTryClauseKeywords(canHaveFinally: false);
      }
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _forTypeAnnotation();
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _forExpression(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // The parser often recovers from incomplete code by creating a variable
    // declaration. Start by checking to see whether the variable declaration is
    // likely only there for recovery.
    var parent = node.parent;
    if (parent is! VariableDeclarationList) {
      return;
    }
    var grandparent = parent.parent;
    if (grandparent is FieldDeclaration) {
      // The order of these conditions is critical. We need to check for an
      // incomplete preceding member even when the grandparent isn't a single
      // identifier, but want to return only if both conditions are true.
      if (_forIncompletePrecedingClassMember(grandparent) &&
          grandparent.isSingleIdentifier) {
        return;
      }
    } else if (grandparent is ForPartsWithDeclarations) {
      if (node.equals == null &&
          parent.variables.length == 1 &&
          parent.type is RecordTypeAnnotation) {
        keywordHelper.addKeyword(Keyword.IN);
      }
    } else if (grandparent is TopLevelVariableDeclaration) {
      if (_handledRecovery(grandparent)) {
        return;
      }
    }

    if (offset <= node.name.end) {
      var container = grandparent?.parent;
      var keyword = parent.keyword;
      if (parent.type == null) {
        if (keyword == null) {
          keywordHelper.addKeyword(Keyword.CONST);
          keywordHelper.addKeyword(Keyword.FINAL);
          keywordHelper.addKeyword(Keyword.VAR);
        }
        if (keyword == null || keyword.keyword != Keyword.VAR) {
          _forTypeAnnotation();
        }
      }
      if (grandparent is FieldDeclaration) {
        if (grandparent.externalKeyword == null) {
          keywordHelper.addKeyword(Keyword.EXTERNAL);
        }
        if (grandparent.staticKeyword == null) {
          keywordHelper.addKeyword(Keyword.STATIC);
          if (container is ClassDeclaration || container is MixinDeclaration) {
            if (grandparent.abstractKeyword == null) {
              keywordHelper.addKeyword(Keyword.ABSTRACT);
            }
            if (grandparent.covariantKeyword == null) {
              keywordHelper.addKeyword(Keyword.COVARIANT);
            }
          }
          if (parent.lateKeyword == null &&
              container is! ExtensionDeclaration) {
            keywordHelper.addKeyword(Keyword.LATE);
          }
        }
        if (node.name == grandparent.beginToken) {
          // The parser often recovers from incomplete code by assuming that
          // the user is typing a field declaration, but it's quite possible
          // that the user is trying to type a different kind of declaration.
          keywordHelper.addKeyword(Keyword.CONST);
          if (container is ClassDeclaration) {
            keywordHelper.addKeyword(Keyword.FACTORY);
          }
          keywordHelper.addKeyword(Keyword.GET);
          keywordHelper.addKeyword(Keyword.OPERATOR);
          keywordHelper.addKeyword(Keyword.SET);
        }
      } else if (grandparent is TopLevelVariableDeclaration) {
        if (grandparent.externalKeyword == null) {
          keywordHelper.addKeyword(Keyword.EXTERNAL);
        }
        if (parent.lateKeyword == null && container is! ExtensionDeclaration) {
          keywordHelper.addKeyword(Keyword.LATE);
        }
      }
      return;
    }
    var equals = node.equals;
    if (equals != null && offset >= equals.end) {
      collector.completionLocation = 'VariableDeclaration_initializer';
      _forExpression(node);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var keyword = node.keyword;
    var variables = node.variables;
    if (variables.isNotEmpty && offset <= variables[0].name.end) {
      var type = node.type;
      if (type == null && keyword?.keyword != Keyword.VAR) {
        _forTypeAnnotation();
      } else if (type is RecordTypeAnnotation) {
        // This might be a record pattern that happens to look like a type, in
        // which case the user might be typing `in`.
        keywordHelper.addKeyword(Keyword.IN);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (_forIncompletePrecedingStatement(node)) {
      return;
    }
    if (offset <= node.beginToken.end) {
      _forStatement(node);
    } else if (offset >= node.end) {
      var parent = node.parent;
      if (parent != null) {
        collector.completionLocation = 'Block_statement';
        _forStatement(parent);
      }
    }
  }

  @override
  void visitWhenClause(WhenClause node) {
    var whenKeyword = node.whenKeyword;
    if (!whenKeyword.isSynthetic && offset > whenKeyword.end) {
      _forExpression(node);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    if (offset <= node.whileKeyword.end) {
      _forStatement(node);
    }
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    if (offset <= node.yieldKeyword.end) {
      keywordHelper.addKeyword(Keyword.YIELD);
    } else if (node.semicolon.isSynthetic || offset <= node.semicolon.end) {
      _forExpression(node);
    }
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a class member.
  void _forClassMember() {
    keywordHelper.addClassMemberKeywords();
    // TODO(brianwilkerson) Suggest type names.
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an element in a collection [literal], with the given
  /// [elements].
  void _forCollectionElement(
      TypedLiteral literal, NodeList<CollectionElement> elements) {
    var preceedingElement = elements.elementBefore(offset);
    keywordHelper.addCollectionElementKeywords(literal, elements);
    declarationHelper.addLexicalDeclarations(preceedingElement ?? literal);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a top-level declaration.
  void _forCompilationUnitDeclaration() {
    keywordHelper.addCompilationUnitDeclarationKeywords();
  }

  void _forCompilationUnitMember(CompilationUnit unit,
      ({AstNode? before, AstNode? after}) surroundingMembers) {
    var before = surroundingMembers.before;
    if (before is Directive?) {
      _forDirective(unit, before);
    }
    if (surroundingMembers.after is CompilationUnitMember?) {
      _forCompilationUnitDeclaration();
    }
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a constant expression. The [node] provides context to
  /// determine which keywords to include.
  void _forConstantExpression(AstNode node) {
    var inConstantContext = node is Expression && node.inConstantContext;
    keywordHelper.addConstantExpressionKeywords(
        inConstantContext: inConstantContext);
    declarationHelper.addLexicalDeclarations(node, mustBeConstant: true);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a directive. The [before] directive is the directive before
  /// the one being added.
  void _forDirective(CompilationUnit unit, Directive? before) {
    keywordHelper.addDirectiveKeywords(unit, before);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an enum member.
  void _forEnumMember() {
    keywordHelper.addEnumMemberKeywords();
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an expression. The [node] provides context to determine which
  /// keywords to include.
  void _forExpression(AstNode? node) {
    keywordHelper.addExpressionKeywords(node);
    if (node != null) {
      declarationHelper.addLexicalDeclarations(node);
    }
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an extension member.
  void _forExtensionMember() {
    keywordHelper.addExtensionMemberKeywords(isStatic: false);
  }

  /// Return `true` if the preceding member is incomplete and no other
  /// suggestions should be offered.
  ///
  /// If the completion offset is within the first token of the given [member],
  /// then check to see whether the preceding member is incomplete. If it is,
  /// then the user might be attempting to complete the preceding member rather
  /// than attempting to prepend something to the given [member], so add the
  /// suggestions appropriate for that situation.
  bool _forIncompletePrecedingClassMember(ClassMember member) {
    if (offset <= member.beginToken.end) {
      var precedingMember = member.precedingMember;
      if (precedingMember == null) {
        return false;
      }
      // Ideally we'd visit the preceding member in order to avoid duplicating
      // code, but the offset will be past where the parser inserted sythetic
      // tokens, preventing that from working.
      switch (precedingMember) {
        // TODO(brianwilkerson) Add support for other kinds of declarations.
        case MethodDeclaration declaration:
          if (declaration.body.isFullySynthetic) {
            keywordHelper.addFunctionBodyModifiers(declaration.body);
            return true;
          }
        case _:
      }
    }
    return false;
  }

  /// Return `true` if the preceding statement is incomplete and no other
  /// suggestions should be offered.
  ///
  /// If the completion offset is within the first token of the given
  /// [statement], then check to see whether the preceding statement is
  /// incomplete. If it is, then the user might be attempting to complete the
  /// preceding statement rather than attempting to prepend something to the
  /// given [statement], so add the suggestions appropriate for that situation.
  bool _forIncompletePrecedingStatement(Statement statement) {
    if (offset <= statement.beginToken.end) {
      var precedingStatement = statement.precedingStatement;
      if (precedingStatement == null) {
        return false;
      }
      // Ideally we'd visit the preceding member in order to avoid
      // duplicating code, but the offset will be past where the parser
      // inserted sythetic tokens, preventing that from working.
      switch (precedingStatement) {
        // TODO(brianwilkerson) Add support for other kinds of declarations.
        case IfStatement declaration:
          if (declaration.elseKeyword == null) {
            keywordHelper.addKeyword(Keyword.ELSE);
            return true;
          }
        case TryStatement declaration:
          if (declaration.finallyBlock == null) {
            visitTryStatement(declaration);
            return declaration.catchClauses.isEmpty;
          }
        case _:
      }
    }
    return false;
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a mixin member.
  void _forMixinMember() {
    keywordHelper.addMixinMemberKeywords();
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a pattern.
  void _forPattern(AstNode node, {bool mustBeConst = true}) {
    keywordHelper.addPatternKeywords();
    declarationHelper.addLexicalDeclarations(node, mustBeConstant: mustBeConst);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a statement. The [node] provides context to determine which
  /// keywords to include.
  void _forStatement(AstNode node) {
    _forExpression(node);
    keywordHelper.addStatementKeywords(node);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a type annotation.
  void _forTypeAnnotation() {
    keywordHelper.addKeyword(Keyword.DYNAMIC);
    keywordHelper.addKeyword(Keyword.VOID);
    // TODO(brianwilkerson) Suggest the types available in the current scope.
    // _addTypesInScope();
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a variable pattern.
  void _forVariablePattern() {
    keywordHelper.addVariablePatternKeywords();
    // TODO(brianwilkerson) Suggest the types available in the current scope.
    // _addTypesInScope();
  }

  /// Return `true` if the [precedingMember] is incomplete.
  ///
  /// If it's incomplete, assume that the user is attempting to complete it and
  /// offer appropriate suggestions.
  bool _handledIncompletePrecedingUnitMember(
      CompilationUnit unit, AstNode precedingMember) {
    // Ideally we'd visit the preceding member in order to avoid duplicating
    // code, but in some cases the offset will be past where the parser inserted
    // sythetic tokens, preventing that from working.
    switch (precedingMember) {
      // TODO(brianwilkerson) Add support for other kinds of declarations.
      case ClassDeclaration declaration:
        if (declaration.hasNoBody) {
          keywordHelper.addClassDeclarationKeywords(declaration);
          return true;
        }
      //   case ExtensionDeclaration declaration:
      //     if (declaration.leftBracket.isSynthetic) {
      //       // If the prior member is an unfinished extension declaration then the
      //       // user is probably finishing that.
      //       _addExtensionDeclarationKeywords(declaration);
      //       return;
      //     }
      //   }
      case ExtensionTypeDeclaration declaration:
        if (declaration.hasNoBody) {
          visitExtensionTypeDeclaration(declaration);
          return true;
        }
      case FunctionDeclaration declaration:
        var body = declaration.functionExpression.body;
        if (body.isEmpty) {
          keywordHelper.addFunctionBodyModifiers(body);
        }
      case ImportDirective directive:
        if (directive.semicolon.isSynthetic) {
          visitImportDirective(directive);
          return true;
        }
      //   case MixinDeclaration declaration:
      //     if (declaration.leftBracket.isSynthetic) {
      //       // If the prior member is an unfinished mixin declaration
      //       // then the user is probably finishing that.
      //       _addMixinDeclarationKeywords(declaration);
      //       return;
      //     }
      //   }
    }
    return false;
  }

  /// Return `true` if the given [expression] is the result of recovery and
  /// suggestions have already been produced.
  ///
  /// The parser recovers from a parenthesized list in an argument list by
  /// creating either a `ParenthesizedExpression` or a `RecordLiteral`
  bool _handledPossibleClosure(Expression? expression) {
    var nextToken = expression?.endToken.nextNonSynthetic;
    if (nextToken == null || offset > nextToken.offset) {
      return false;
    }
    switch (expression) {
      case ParenthesizedExpression(:var expression):
        if (expression is SimpleIdentifier) {
          keywordHelper.addFunctionBodyModifiers(null);
          return true;
        }
      case RecordLiteral record:
        for (var field in record.fields) {
          if (field is! SimpleIdentifier) {
            return false;
          }
        }
        keywordHelper.addFunctionBodyModifiers(null);
        return true;
    }
    return false;
  }

  /// Return `true` if the given [declaration] is the result of recovery and
  /// suggestions have already been produced.
  ///
  /// The parser recovers from a simple identifier by assuming that it's a
  /// top-level variable declaration. But a simple identifier could be the start
  /// of any kind of member, so defer to the compilation unit.
  bool _handledRecovery(TopLevelVariableDeclaration declaration) {
    var unit = declaration.parent;
    if (unit is CompilationUnit) {
      ({AstNode? before, AstNode? after})? surroundingMembers;
      if (offset <= declaration.beginToken.end) {
        surroundingMembers = unit.membersBeforeAndAfterMember(declaration);
        var before = surroundingMembers.before;
        if (before != null &&
            _handledIncompletePrecedingUnitMember(unit, before)) {
          // The preceding member is incomplete, so assume that the user is
          // completing it rather than starting a new member.
          return true;
        }
      }
      if (declaration.isSingleIdentifier) {
        surroundingMembers ??= unit.membersBeforeAndAfterMember(declaration);
        _forCompilationUnitMember(unit, surroundingMembers);
        return true;
      }
    }
    return false;
  }

  void _visitForEachParts(ForEachParts node) {
    if (node.inKeyword.coversOffset(offset)) {
      var previous = node.findPrevious(node.inKeyword);
      if (previous is SyntheticStringToken && previous.lexeme == 'in') {
        previous = node.findPrevious(previous);
      }
      if (previous != null && previous.type == TokenType.EQ) {
        keywordHelper.addKeyword(Keyword.CONST);
        keywordHelper.addKeyword(Keyword.FALSE);
        keywordHelper.addKeyword(Keyword.NULL);
        keywordHelper.addKeyword(Keyword.TRUE);
      } else {
        keywordHelper.addKeyword(Keyword.IN);
      }
    } else if (!node.inKeyword.isSynthetic) {
      keywordHelper.addKeyword(Keyword.AWAIT);
      declarationHelper.addLexicalDeclarations(node);
    }
  }

  /// If the completion offset is at or before the offset of the [node], then
  /// visit the parent of the node.
  void _visitParentIfAtOrBeforeNode(AstNode node) {
    if (offset <= node.offset) {
      node.parent?.accept(this);
    }
  }
}

extension on AstNode {
  /// Whether all of the tokens in this node are synthetic.
  bool get isFullySynthetic {
    var current = beginToken;
    var stop = endToken.next!;
    while (current != stop) {
      if (!current.isSynthetic) {
        return false;
      }
      current = current.next!;
    }
    return true;
  }

  /// Return `true` if the [child] is an element in a list of children of this
  /// node.
  bool isChildInList(AstNode child) {
    return switch (this) {
      AdjacentStrings(:var strings) => strings.contains(child),
      ArgumentList(:var arguments) => arguments.contains(child),
      AugmentationImportDirective(:var metadata) => metadata.contains(child),
      Block(:var statements) => statements.contains(child),
      CascadeExpression(:var cascadeSections) =>
        cascadeSections.contains(child),
      ClassDeclaration(:var members, :var metadata) =>
        members.contains(child) || metadata.contains(child),
      ClassTypeAlias(:var metadata) => metadata.contains(child),
      Comment(:var references) => references.contains(child),
      CompilationUnit(:var directives, :var declarations) =>
        directives.contains(child) || declarations.contains(child),
      ConstructorDeclaration(:var initializers, :var metadata) =>
        initializers.contains(child) || metadata.contains(child),
      DeclaredIdentifier(:var metadata) => metadata.contains(child),
      DottedName(:var components) => components.contains(child),
      EnumConstantDeclaration(:var metadata) => metadata.contains(child),
      EnumDeclaration(:var constants, :var members, :var metadata) =>
        constants.contains(child) ||
            members.contains(child) ||
            metadata.contains(child),
      ExportDirective(:var combinators, :var configurations, :var metadata) =>
        combinators.contains(child) ||
            configurations.contains(child) ||
            metadata.contains(child),
      ExtensionDeclaration(:var members, :var metadata) =>
        members.contains(child) || metadata.contains(child),
      ExtensionTypeDeclaration(:var members, :var metadata) =>
        members.contains(child) || metadata.contains(child),
      FieldDeclaration(:var metadata) => metadata.contains(child),
      ForEachPartsWithPattern(:var metadata) => metadata.contains(child),
      FormalParameter(:var metadata) => metadata.contains(child),
      FormalParameterList(:var parameters) => parameters.contains(child),
      ForParts(:var updaters) => updaters.contains(child),
      FunctionDeclaration(:var metadata) => metadata.contains(child),
      FunctionTypeAlias(:var metadata) => metadata.contains(child),
      GenericTypeAlias(:var metadata) => metadata.contains(child),
      HideCombinator(:var hiddenNames) => hiddenNames.contains(child),
      ImplementsClause(:var interfaces) => interfaces.contains(child),
      ImportDirective(:var combinators, :var configurations, :var metadata) =>
        combinators.contains(child) ||
            configurations.contains(child) ||
            metadata.contains(child),
      LabeledStatement(:var labels) => labels.contains(child),
      LibraryAugmentationDirective(:var metadata) => metadata.contains(child),
      LibraryDirective(:var metadata) => metadata.contains(child),
      LibraryIdentifier(:var components) => components.contains(child),
      ListLiteral(:var elements) => elements.contains(child),
      ListPattern(:var elements) => elements.contains(child),
      MapPattern(:var elements) => elements.contains(child),
      MethodDeclaration(:var metadata) => metadata.contains(child),
      MixinDeclaration(:var members, :var metadata) =>
        members.contains(child) || metadata.contains(child),
      ObjectPattern(:var fields) => fields.contains(child),
      OnClause(:var superclassConstraints) =>
        superclassConstraints.contains(child),
      PartDirective(:var metadata) => metadata.contains(child),
      PartOfDirective(:var metadata) => metadata.contains(child),
      PatternVariableDeclaration(:var metadata) => metadata.contains(child),
      RecordLiteral(:var fields) => fields.contains(child),
      RecordPattern(:var fields) => fields.contains(child),
      RecordTypeAnnotation(:var positionalFields) =>
        positionalFields.contains(child),
      RecordTypeAnnotationField(:var metadata) => metadata.contains(child),
      RecordTypeAnnotationNamedFields(:var fields) => fields.contains(child),
      RepresentationDeclaration(:var fieldMetadata) =>
        fieldMetadata.contains(child),
      SetOrMapLiteral(:var elements) => elements.contains(child),
      ShowCombinator(:var shownNames) => shownNames.contains(child),
      SwitchExpression(:var cases) => cases.contains(child),
      SwitchMember(:var labels, :var statements) =>
        labels.contains(child) || statements.contains(child),
      SwitchStatement(:var members) => members.contains(child),
      TopLevelVariableDeclaration(:var metadata) => metadata.contains(child),
      TryStatement(:var catchClauses) => catchClauses.contains(child),
      TypeArgumentList(:var arguments) => arguments.contains(child),
      TypeParameter(:var metadata) => metadata.contains(child),
      TypeParameterList(:var typeParameters) => typeParameters.contains(child),
      VariableDeclaration(:var metadata) => metadata.contains(child),
      VariableDeclarationList(:var metadata, :var variables) =>
        metadata.contains(child) || variables.contains(child),
      WithClause(:var mixinTypes) => mixinTypes.contains(child),
      AstNode() => false,
    };
  }
}

extension on ClassDeclaration {
  /// Whether this class declaration doesn't have a body.
  bool get hasNoBody {
    return leftBracket.isSynthetic && rightBracket.isSynthetic;
  }
}

extension on ClassMember {
  /// Return the member before `this`, or `null` if this is the first member in
  /// the body.
  ClassMember? get precedingMember {
    final parent = this.parent;
    var members = switch (parent) {
      ClassDeclaration() => parent.members,
      EnumDeclaration() => parent.members,
      ExtensionDeclaration() => parent.members,
      ExtensionTypeDeclaration() => parent.members,
      MixinDeclaration() => parent.members,
      _ => null
    };
    if (members == null) {
      return null;
    }
    var index = members.indexOf(this);
    if (index <= 0) {
      return null;
    }
    return members[index - 1];
  }
}

extension on ArgumentList {
  /// Return a record whose fields are the arguments in this argument list
  /// that are lexically immediately before and after the given [offset].
  ({Expression? before, Expression? after}) argumentsBeforeAndAfterOffset(
      int offset) {
    Expression? previous;
    for (var argument in arguments) {
      if (offset < argument.offset) {
        return (before: previous, after: argument);
      }
      previous = argument;
    }
    return (before: previous, after: null);
  }
}

extension on CompilationUnit {
  /// Return a record whose fields are the members in this compilation unit
  /// that are lexically immediately before and after the given [member].
  ({AstNode? before, AstNode? after}) membersBeforeAndAfterMember(
      AstNode? member) {
    var members = sortedDirectivesAndDeclarations;
    AstNode? before, after;
    if (member != null) {
      var index = members.indexOf(member);
      if (index > 0) {
        before = members[index - 1];
      }
      if (index + 1 < members.length) {
        after = members[index + 1];
      }
    }
    return (before: before, after: after);
  }

  /// Return a record whose fields are the members in this compilation unit
  /// that are lexically immediately before and after the given [offset].
  ({AstNode? before, AstNode? after}) membersBeforeAndAfterOffset(int offset) {
    var members = sortedDirectivesAndDeclarations;
    AstNode? previous;
    for (var member in members) {
      if (offset < member.offset) {
        return (before: previous, after: member);
      }
      previous = member;
    }
    return (before: previous, after: null);
  }
}

extension on ExpressionStatement {
  /// Whether this statement consists of a single identifier.
  bool get isSingleIdentifier {
    var first = beginToken;
    var last = endToken;
    return first.isKeywordOrIdentifier &&
        last.isSynthetic &&
        first.next == last;
  }
}

extension on ExtensionTypeDeclaration {
  /// Whether this class declaration doesn't have a body.
  bool get hasNoBody {
    return leftBracket.isSynthetic && rightBracket.isSynthetic;
  }
}

extension on FieldDeclaration {
  /// Whether this field declaration consists of a single identifier.
  bool get isSingleIdentifier {
    var first = beginToken;
    var last = endToken;
    return first.isKeywordOrIdentifier &&
        last.isSynthetic &&
        first.next == last;
  }
}

extension on FormalParameter {
  /// Whether this formal parameter declaration is incomplete.
  bool get isIncomplete {
    final name = this.name;
    if (name == null || name.isKeyword) {
      return true;
    }
    var self = this;
    if (self is DefaultFormalParameter && self.separator != null) {
      var defaultValue = self.defaultValue;
      if (defaultValue == null || defaultValue.isSynthetic) {
        // The `defaultValue` won't be `null` if the separator is non-`null`,
        // but the condition is necessary because the type system can't express
        // that constraint.
        return true;
      }
    }
    return false;
  }

  /// Whether this formal parameter declaration consists of a single identifier.
  bool get isSingleIdentifier {
    final beginToken = this.beginToken;
    return beginToken == endToken && beginToken.isKeywordOrIdentifier;
  }
}

extension on GuardedPattern {
  /// Whether this pattern has, or might have, a `when` keyword.
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

extension on Statement {
  /// Return the statement before `this`, or `null` if this is the first statement in
  /// the block.
  Statement? get precedingStatement {
    final parent = this.parent;
    if (parent is! Block) {
      return null;
    }
    var statements = parent.statements;
    var index = statements.indexOf(this);
    if (index <= 0) {
      return null;
    }
    return statements[index - 1];
  }
}

extension on SyntacticEntity? {
  /// Return `true` if the receiver covers the [offset].
  bool coversOffset(int offset) {
    final self = this;
    return self != null && self.offset <= offset && self.end >= offset;
  }
}

extension on Token {
  Token? get nextNonSynthetic {
    var candidate = next;
    while (candidate != null &&
        candidate.isSynthetic &&
        candidate.next != candidate) {
      candidate = candidate.next;
    }
    return candidate;
  }
}

extension on TopLevelVariableDeclaration {
  /// Whether this top level variable declaration consists of a single
  /// identifier.
  bool get isSingleIdentifier {
    var first = beginToken;
    var next = first.next;
    var last = endToken;
    return first.isKeywordOrIdentifier &&
        last.isSynthetic &&
        (next == last || (next?.isSynthetic == true && next?.next == last));
  }
}

extension on TypeAnnotation? {
  /// Whether this type annotation consists of a single identifier.
  bool get isSingleIdentifier {
    var self = this;
    return self is NamedType &&
        self.question == null &&
        self.typeArguments == null &&
        self.importPrefix == null;
  }
}

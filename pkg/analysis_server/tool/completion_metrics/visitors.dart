// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' as element;

class ExpectedCompletion {
  final SyntacticEntity _entity;

  /// Some completions are special cased from the DAS "import" for instance is
  /// suggested as a completion "import '';", the completion string here in this
  /// instance would have the value "import '';".
  final String _completionString;

  final protocol.CompletionSuggestionKind _kind;

  final int _lineNumber;

  final int _columnNumber;

  final protocol.ElementKind _elementKind;

  ExpectedCompletion(this._entity, this._lineNumber, this._columnNumber,
      this._kind, this._elementKind)
      : _completionString = null;

  ExpectedCompletion.specialCompletionString(
      this._entity,
      this._lineNumber,
      this._columnNumber,
      this._completionString,
      this._kind,
      this._elementKind);

  int get columnNumber => _columnNumber;

  String get completion => _completionString ?? _entity.toString();

  protocol.ElementKind get elementKind => _elementKind;

  protocol.CompletionSuggestionKind get kind => _kind;

  int get lineNumber => _lineNumber;

  int get offset => _entity.offset;

  SyntacticEntity get syntacticEntity => _entity;

  bool matches(protocol.CompletionSuggestion completionSuggestion) {
    if (completionSuggestion.completion == completion) {
      if (kind != null &&
          completionSuggestion.kind != null &&
          completionSuggestion.kind != kind) {
        return false;
      }
      if (elementKind != null &&
          completionSuggestion.element?.kind != null &&
          completionSuggestion.element?.kind != elementKind) {
        return false;
      }
      return true;
    }
    return false;
  }
}

class ExpectedCompletionsVisitor extends RecursiveAstVisitor {
  final List<ExpectedCompletion> expectedCompletions;

  CompilationUnit _enclosingCompilationUnit;

  /// This boolean is set to enable whether or not we should assert that some
  /// found keyword in Dart syntax should be in the completion set returned from
  /// the analysis server.  This is off by default because with syntax such as
  /// "^get foo() => _foo;", "get" and "set" won't be suggested because this
  /// syntax has specified the "get" modifier, i.e. it would be invalid to
  /// include it again: "get get foo() => _foo;".
  final bool _doExpectKeywordCompletions = false;

  /// This boolean is set to enable if identifiers in comments should be
  /// expected to be completed. The default is false as typos in a dartdoc
  /// comment don't yield an error like Dart syntax mistakes would yield.
  final bool _doExpectCommentRefs = false;

  ExpectedCompletionsVisitor() : expectedCompletions = <ExpectedCompletion>[];

  safelyRecordEntity(SyntacticEntity entity,
      {protocol.CompletionSuggestionKind kind,
      protocol.ElementKind elementKind}) {
    // Only record if this entity is not null, has a length, etc.
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      // Compute the line number at this offset
      var lineNumber = _enclosingCompilationUnit.lineInfo
          .getLocation(entity.offset)
          .lineNumber;

      var columnNumber = _enclosingCompilationUnit.lineInfo
          .getLocation(entity.offset)
          .columnNumber;

      // Some special cases in the if and if-else blocks, 'import' from the
      // DAS is "import '';" which we want to be sure to match.
      if (entity.toString() == 'async') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, lineNumber, columnNumber, ASYNC_STAR, kind, elementKind));
      } else if (entity.toString() == 'default') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity,
            lineNumber,
            columnNumber,
            DEFAULT_COLON,
            kind,
            elementKind));
      } else if (entity.toString() == 'deferred') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, lineNumber, columnNumber, DEFERRED_AS, kind, elementKind));
      } else if (entity.toString() == 'export') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity,
            lineNumber,
            columnNumber,
            EXPORT_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'import') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity,
            lineNumber,
            columnNumber,
            IMPORT_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'part') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity,
            lineNumber,
            columnNumber,
            PART_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'sync') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, lineNumber, columnNumber, SYNC_STAR, kind, elementKind));
      } else if (entity.toString() == 'yield') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, lineNumber, columnNumber, YIELD_STAR, kind, elementKind));
      } else {
        expectedCompletions.add(ExpectedCompletion(
            entity, lineNumber, columnNumber, kind, elementKind));
      }
    }
  }

  safelyRecordKeywordCompletion(SyntacticEntity entity) {
    if (_doExpectKeywordCompletions) {
      safelyRecordEntity(entity,
          kind: protocol.CompletionSuggestionKind.KEYWORD);
    }
  }

  @override
  visitAsExpression(AsExpression node) {
    safelyRecordKeywordCompletion(node.asOperator);
    return super.visitAsExpression(node);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    return super.visitAwaitExpression(node);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    // 'async' | 'async' '*' | 'sync' '*':
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitBlockFunctionBody(node);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    // 'false' | 'true'
    safelyRecordKeywordCompletion(node.literal);
    return super.visitBooleanLiteral(node);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    safelyRecordKeywordCompletion(node.breakKeyword);
    return super.visitBreakStatement(node);
  }

  @override
  visitCatchClause(CatchClause node) {
    // Should we 'catch', it won't be suggested when it already exists as a
    // keyword in the file?
    safelyRecordKeywordCompletion(node.catchKeyword);
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitCatchClause(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    safelyRecordKeywordCompletion(node.abstractKeyword);
    safelyRecordKeywordCompletion(node.classKeyword);
    return super.visitClassDeclaration(node);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    safelyRecordKeywordCompletion(node.abstractKeyword);
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitClassTypeAlias(node);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    _enclosingCompilationUnit = node;
    return super.visitCompilationUnit(node);
  }

  @override
  visitConfiguration(Configuration node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    return super.visitConfiguration(node);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    safelyRecordKeywordCompletion(node.constKeyword);
    safelyRecordKeywordCompletion(node.factoryKeyword);
    return super.visitConstructorDeclaration(node);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitConstructorFieldInitializer(node);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    safelyRecordKeywordCompletion(node.continueKeyword);
    return super.visitContinueStatement(node);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitDeclaredIdentifier(node);
  }

  @override
  visitDoStatement(DoStatement node) {
    safelyRecordKeywordCompletion(node.doKeyword);
    safelyRecordKeywordCompletion(node.whileKeyword);
    return super.visitDoStatement(node);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    safelyRecordKeywordCompletion(node.enumKeyword);
    return super.visitEnumDeclaration(node);
  }

  @override
  visitExportDirective(ExportDirective node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitExportDirective(node);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitExpressionFunctionBody(node);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    safelyRecordKeywordCompletion(node.extendsKeyword);
    return super.visitExtendsClause(node);
  }

  @override
  visitExtensionDeclaration(ExtensionDeclaration node) {
    safelyRecordKeywordCompletion(node.extensionKeyword);
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitExtensionDeclaration(node);
  }

  @override
  visitExtensionOverride(ExtensionOverride node) {
    node.visitChildren(this);
    return null;
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    safelyRecordKeywordCompletion(node.covariantKeyword);
    safelyRecordKeywordCompletion(node.staticKeyword);
    return super.visitFieldDeclaration(node);
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitFieldFormalParameter(node);
  }

  @override
  visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    safelyRecordKeywordCompletion(node.inKeyword);
    return super.visitForEachPartsWithDeclaration(node);
  }

  @override
  visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    safelyRecordKeywordCompletion(node.inKeyword);
    return super.visitForEachPartsWithIdentifier(node);
  }

  @override
  visitForElement(ForElement node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    safelyRecordKeywordCompletion(node.forKeyword);
    return super.visitForElement(node);
  }

  @override
  visitForStatement(ForStatement node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    safelyRecordKeywordCompletion(node.forKeyword);
    return super.visitForStatement(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    // 'get' or 'set':
    safelyRecordKeywordCompletion(node.propertyKeyword);
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  visitGenericFunctionType(GenericFunctionType node) {
    safelyRecordKeywordCompletion(node.functionKeyword);
    return super.visitGenericFunctionType(node);
  }

  @override
  visitGenericTypeAlias(GenericTypeAlias node) {
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitGenericTypeAlias(node);
  }

  @override
  visitHideCombinator(HideCombinator node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitHideCombinator(node);
  }

  @override
  visitIfElement(IfElement node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    safelyRecordKeywordCompletion(node.elseKeyword);
    return super.visitIfElement(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    safelyRecordKeywordCompletion(node.elseKeyword);
    return super.visitIfStatement(node);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    safelyRecordKeywordCompletion(node.implementsKeyword);
    return super.visitImplementsClause(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.asKeyword);
    return super.visitImportDirective(node);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Here we explicitly do not record 'new' as we don't suggest it in the
    // completion service.
    // https://dart-review.googlesource.com/c/sdk/+/131020
    var keywordStr = node.keyword?.lexeme;
    if (Keyword.CONST.lexeme == keywordStr) {
      safelyRecordKeywordCompletion(node.keyword);
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  visitIsExpression(IsExpression node) {
    safelyRecordKeywordCompletion(node.isOperator);
    return super.visitIsExpression(node);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    safelyRecordKeywordCompletion(node.libraryKeyword);
    return super.visitLibraryDirective(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    safelyRecordKeywordCompletion(node.constKeyword);
    return super.visitListLiteral(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    safelyRecordKeywordCompletion(node.modifierKeyword);
    safelyRecordKeywordCompletion(node.operatorKeyword);
    safelyRecordKeywordCompletion(node.propertyKeyword);
    return super.visitMethodDeclaration(node);
  }

  @override
  visitMixinDeclaration(MixinDeclaration node) {
    safelyRecordKeywordCompletion(node.mixinKeyword);
    return super.visitMixinDeclaration(node);
  }

  @override
  visitNativeClause(NativeClause node) {
    safelyRecordKeywordCompletion(node.nativeKeyword);
    return super.visitNativeClause(node);
  }

  @override
  visitNativeFunctionBody(NativeFunctionBody node) {
    safelyRecordKeywordCompletion(node.nativeKeyword);
    return super.visitNativeFunctionBody(node);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    safelyRecordKeywordCompletion(node.literal);
    return super.visitNullLiteral(node);
  }

  @override
  visitOnClause(OnClause node) {
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitOnClause(node);
  }

  @override
  visitPartDirective(PartDirective node) {
    safelyRecordKeywordCompletion(node.partKeyword);
    return super.visitPartDirective(node);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    safelyRecordKeywordCompletion(node.partKeyword);
    safelyRecordKeywordCompletion(node.ofKeyword);
    return super.visitPartOfDirective(node);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    safelyRecordKeywordCompletion(node.rethrowKeyword);
    return super.visitRethrowExpression(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    safelyRecordKeywordCompletion(node.returnKeyword);
    return super.visitReturnStatement(node);
  }

  @override
  visitSetOrMapLiteral(SetOrMapLiteral node) {
    safelyRecordKeywordCompletion(node.constKeyword);
    return super.visitSetOrMapLiteral(node);
  }

  @override
  visitShowCombinator(ShowCombinator node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitShowCombinator(node);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.covariantKeyword);
    return super.visitSimpleFormalParameter(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (_doIncludeSimpleIdentifier(node)) {
      var elementKind;
      if (node.staticElement?.kind != null) {
        elementKind = protocol.convertElementKind(node.staticElement?.kind);

        // If the completed element kind is a getter or setter set the element
        // kind to null as the exact kind from the DAS is unknown at this
        // point.
        if (elementKind == protocol.ElementKind.GETTER ||
            elementKind == protocol.ElementKind.SETTER) {
          elementKind = null;
        }

        // Map PREFIX element kinds to LIBRARY kinds as this is the ElementKind
        // used for prefixes reported from the completion engine.
        if (elementKind == protocol.ElementKind.PREFIX) {
          elementKind = protocol.ElementKind.LIBRARY;
        }
      }
      safelyRecordEntity(node, elementKind: elementKind);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    safelyRecordKeywordCompletion(node.superKeyword);
    return super.visitSuperConstructorInvocation(node);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    safelyRecordKeywordCompletion(node.superKeyword);
    return super.visitSuperExpression(node);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitSwitchCase(node);
  }

  @override
  visitSwitchDefault(SwitchDefault node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitSwitchDefault(node);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    safelyRecordKeywordCompletion(node.switchKeyword);
    return super.visitSwitchStatement(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitThisExpression(node);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    safelyRecordKeywordCompletion(node.throwKeyword);
    return super.visitThrowExpression(node);
  }

  @override
  visitTryStatement(TryStatement node) {
    safelyRecordKeywordCompletion(node.tryKeyword);
    safelyRecordKeywordCompletion(node.finallyKeyword);
    return super.visitTryStatement(node);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    safelyRecordKeywordCompletion(node.extendsKeyword);
    return super.visitTypeParameter(node);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.lateKeyword);
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    safelyRecordKeywordCompletion(node.whileKeyword);
    return super.visitWhileStatement(node);
  }

  @override
  visitWithClause(WithClause node) {
    safelyRecordKeywordCompletion(node.withKeyword);
    return super.visitWithClause(node);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    safelyRecordKeywordCompletion(node.yieldKeyword);
    return super.visitYieldStatement(node);
  }

  bool _doIncludeSimpleIdentifier(SimpleIdentifier node) {
    // Do not continue if this node is synthetic, or if the node is in a
    // declaration context
    if (node == null || node.isSynthetic || node.inDeclarationContext()) {
      return false;
    }
    // If we are in a comment reference context, return if we should include
    // such identifiers.
    if (node.thisOrAncestorOfType<CommentReference>() != null) {
      return _doExpectCommentRefs;
    }

    // TODO (jwren) If there is a mode of completing at a token location where
    //  the token is removed before the completion query happens, then this
    //  should be disabled in such a case:
    // Named arguments, i.e. the 'foo' in 'method_call(foo: 1)' should not be
    // included, by design, the completion engine won't suggest named arguments
    // already it the source.
    if (node.staticElement?.kind == element.ElementKind.PARAMETER &&
        node.parent is Label &&
        node.thisOrAncestorOfType<ArgumentList>() != null) {
      return false;
    }

    // If the type of the SimpleIdentifier is dynamic, don't include.
    if (node.staticType != null && node.staticType.isDynamic) {
      return false;
    }
    return true;
  }
}

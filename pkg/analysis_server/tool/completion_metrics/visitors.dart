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
  final String _filePath;

  final SyntacticEntity _entity;

  /// Some completions are special cased from the DAS "import" for instance is
  /// suggested as a completion "import '';", the completion string here in this
  /// instance would have the value "import '';".
  final String _completionString;

  final protocol.CompletionSuggestionKind _kind;

  final int _lineNumber;

  final int _columnNumber;

  final protocol.ElementKind _elementKind;

  ExpectedCompletion(this._filePath, this._entity, this._lineNumber,
      this._columnNumber, this._kind, this._elementKind)
      : _completionString = null;

  ExpectedCompletion.specialCompletionString(
      this._filePath,
      this._entity,
      this._lineNumber,
      this._columnNumber,
      this._completionString,
      this._kind,
      this._elementKind);

  int get columnNumber => _columnNumber;

  String get completion => _completionString ?? _entity.toString();

  protocol.ElementKind get elementKind => _elementKind;

  String get filePath => _filePath;

  protocol.CompletionSuggestionKind get kind => _kind;

  int get lineNumber => _lineNumber;

  String get location => '$filePath:$lineNumber:$columnNumber';

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

  @override
  String toString() =>
      "'$completion', kind = $kind, elementKind = $elementKind, $location";
}

class ExpectedCompletionsVisitor extends RecursiveAstVisitor<void> {
  final List<ExpectedCompletion> expectedCompletions;

  final String filePath;

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

  ExpectedCompletionsVisitor(this.filePath)
      : expectedCompletions = <ExpectedCompletion>[],
        assert(filePath != null);

  void safelyRecordEntity(SyntacticEntity entity,
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
            filePath,
            entity,
            lineNumber,
            columnNumber,
            ASYNC_STAR,
            kind,
            elementKind));
      } else if (entity.toString() == 'default') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            DEFAULT_COLON,
            kind,
            elementKind));
      } else if (entity.toString() == 'deferred') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            DEFERRED_AS,
            kind,
            elementKind));
      } else if (entity.toString() == 'export') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            EXPORT_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'import') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            IMPORT_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'part') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            PART_STATEMENT,
            kind,
            elementKind));
      } else if (entity.toString() == 'sync') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            SYNC_STAR,
            kind,
            elementKind));
      } else if (entity.toString() == 'yield') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            filePath,
            entity,
            lineNumber,
            columnNumber,
            YIELD_STAR,
            kind,
            elementKind));
      } else {
        expectedCompletions.add(ExpectedCompletion(
            filePath, entity, lineNumber, columnNumber, kind, elementKind));
      }
    }
  }

  void safelyRecordKeywordCompletion(SyntacticEntity entity) {
    if (_doExpectKeywordCompletions) {
      safelyRecordEntity(entity,
          kind: protocol.CompletionSuggestionKind.KEYWORD);
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    safelyRecordKeywordCompletion(node.asOperator);
    return super.visitAsExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    return super.visitAwaitExpression(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    // 'async' | 'async' '*' | 'sync' '*':
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    // 'false' | 'true'
    safelyRecordKeywordCompletion(node.literal);
    return super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    safelyRecordKeywordCompletion(node.breakKeyword);
    return super.visitBreakStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    // Should we 'catch', it won't be suggested when it already exists as a
    // keyword in the file?
    safelyRecordKeywordCompletion(node.catchKeyword);
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    safelyRecordKeywordCompletion(node.abstractKeyword);
    safelyRecordKeywordCompletion(node.classKeyword);
    return super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    safelyRecordKeywordCompletion(node.abstractKeyword);
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitClassTypeAlias(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _enclosingCompilationUnit = node;
    return super.visitCompilationUnit(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    return super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    safelyRecordKeywordCompletion(node.constKeyword);
    safelyRecordKeywordCompletion(node.factoryKeyword);
    return super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    safelyRecordKeywordCompletion(node.continueKeyword);
    return super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    safelyRecordKeywordCompletion(node.doKeyword);
    safelyRecordKeywordCompletion(node.whileKeyword);
    return super.visitDoStatement(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    safelyRecordKeywordCompletion(node.enumKeyword);
    return super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    safelyRecordKeywordCompletion(node.extendsKeyword);
    return super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    safelyRecordKeywordCompletion(node.extensionKeyword);
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.visitChildren(this);
    return null;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    safelyRecordKeywordCompletion(node.abstractKeyword);
    safelyRecordKeywordCompletion(node.covariantKeyword);
    safelyRecordKeywordCompletion(node.externalKeyword);
    safelyRecordKeywordCompletion(node.staticKeyword);
    return super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    safelyRecordKeywordCompletion(node.inKeyword);
    return super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    safelyRecordKeywordCompletion(node.inKeyword);
    return super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    safelyRecordKeywordCompletion(node.forKeyword);
    return super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    safelyRecordKeywordCompletion(node.awaitKeyword);
    safelyRecordKeywordCompletion(node.forKeyword);
    return super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    // 'get' or 'set':
    safelyRecordKeywordCompletion(node.propertyKeyword);
    return super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    safelyRecordKeywordCompletion(node.functionKeyword);
    return super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    safelyRecordKeywordCompletion(node.typedefKeyword);
    return super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    safelyRecordKeywordCompletion(node.elseKeyword);
    return super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    safelyRecordKeywordCompletion(node.elseKeyword);
    return super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    safelyRecordKeywordCompletion(node.implementsKeyword);
    return super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.asKeyword);
    return super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
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
  void visitIsExpression(IsExpression node) {
    safelyRecordKeywordCompletion(node.isOperator);
    return super.visitIsExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    safelyRecordKeywordCompletion(node.libraryKeyword);
    return super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    safelyRecordKeywordCompletion(node.constKeyword);
    return super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    safelyRecordKeywordCompletion(node.modifierKeyword);
    safelyRecordKeywordCompletion(node.operatorKeyword);
    safelyRecordKeywordCompletion(node.propertyKeyword);
    return super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    safelyRecordKeywordCompletion(node.mixinKeyword);
    return super.visitMixinDeclaration(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    safelyRecordKeywordCompletion(node.nativeKeyword);
    return super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    safelyRecordKeywordCompletion(node.nativeKeyword);
    return super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    safelyRecordKeywordCompletion(node.literal);
    return super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    safelyRecordKeywordCompletion(node.onKeyword);
    return super.visitOnClause(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    safelyRecordKeywordCompletion(node.partKeyword);
    return super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    safelyRecordKeywordCompletion(node.partKeyword);
    safelyRecordKeywordCompletion(node.ofKeyword);
    return super.visitPartOfDirective(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    safelyRecordKeywordCompletion(node.rethrowKeyword);
    return super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    safelyRecordKeywordCompletion(node.returnKeyword);
    return super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    safelyRecordKeywordCompletion(node.constKeyword);
    return super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.covariantKeyword);
    return super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_doIncludeSimpleIdentifier(node)) {
      protocol.ElementKind elementKind;
      if (node.staticElement?.kind != null) {
        elementKind = protocol.convertElementKind(node.staticElement.kind);

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

        // For identifiers in a FieldFormalParameter, i.e. the 'foo' in some
        // ClassName(this.foo), set the elementKind to FIELD which is what the
        // completion engine does (elementKind before this if statement is a
        // PARAMETER).
        if (node.parent is FieldFormalParameter) {
          elementKind = protocol.ElementKind.FIELD;
        }

        // Class references that are constructor calls are constructor kinds,
        // unless either:
        //   1) the constructor is a named constructor, i.e. some "Foo.bar()",
        //      the "Foo" in this case is a class,
        //   2) or, there is an explicit const or new keyword before the
        //      constructor invocation in which case the "Foo" above is
        //      considered a constructor still
        if (elementKind == protocol.ElementKind.CLASS) {
          if (node.parent?.parent is ConstructorName) {
            var constructorName = node.parent.parent as ConstructorName;
            var instanceCreationExpression = constructorName.parent;
            if (instanceCreationExpression is InstanceCreationExpression &&
                constructorName.type.name == node) {
              if (instanceCreationExpression.keyword != null ||
                  constructorName.name == null) {
                elementKind = protocol.ElementKind.CONSTRUCTOR;
              }
            }
          }
        }
      }
      safelyRecordEntity(node, elementKind: elementKind);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    safelyRecordKeywordCompletion(node.superKeyword);
    return super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    safelyRecordKeywordCompletion(node.superKeyword);
    return super.visitSuperExpression(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    safelyRecordKeywordCompletion(node.keyword);
    return super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    safelyRecordKeywordCompletion(node.switchKeyword);
    return super.visitSwitchStatement(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    safelyRecordKeywordCompletion(node.thisKeyword);
    return super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    safelyRecordKeywordCompletion(node.throwKeyword);
    return super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    safelyRecordKeywordCompletion(node.externalKeyword);
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    safelyRecordKeywordCompletion(node.tryKeyword);
    safelyRecordKeywordCompletion(node.finallyKeyword);
    return super.visitTryStatement(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    safelyRecordKeywordCompletion(node.extendsKeyword);
    return super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    // 'final', 'const' or 'var'
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.lateKeyword);
    return super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    safelyRecordKeywordCompletion(node.whileKeyword);
    return super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    safelyRecordKeywordCompletion(node.withKeyword);
    return super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    safelyRecordKeywordCompletion(node.yieldKeyword);
    return super.visitYieldStatement(node);
  }

  bool _doIncludeSimpleIdentifier(SimpleIdentifier node) {
    // Do not continue if this node is synthetic, or if the node is in a
    // declaration context
    if (node == null || node.isSynthetic || node.inDeclarationContext()) {
      return false;
    }

    // If the type of the SimpleIdentifier is dynamic, don't include.
    if (node.staticType != null && node.staticType.isDynamic) {
      return false;
    }

    // If we are in a comment reference context, return if we should include
    // such identifiers.
    if (node.thisOrAncestorOfType<CommentReference>() != null) {
      return _doExpectCommentRefs;
    }

    // Ignore the SimpleIdentifiers that make up library directives.
    if (node.thisOrAncestorOfType<LibraryDirective>() != null) {
      return false;
    }

    // TODO (jwren) If there is a mode of completing at a token location where
    //  the token is removed before the completion query happens, then this
    //  should be disabled in such a case:
    // Named arguments, i.e. the 'foo' in 'method_call(foo: 1)' should not be
    // included, by design, the completion engine won't suggest named arguments
    // already it the source.
    //
    // The null check, node.staticElement == null, handles the cases where the
    // invocation is unknown, i.e. the 'arg' in 'foo.bar(arg: 1)', where foo is
    // dynamic.
    if ((node.staticElement == null ||
            node.staticElement?.kind == element.ElementKind.PARAMETER) &&
        node.parent is Label &&
        node.thisOrAncestorOfType<ArgumentList>() != null) {
      return false;
    }

    return true;
  }
}

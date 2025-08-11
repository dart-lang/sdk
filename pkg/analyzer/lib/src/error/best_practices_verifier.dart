// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/dart/error/hint_codes.g.dart';
library;

import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart' show ExecutableMember;
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/annotation_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
import 'package:analyzer/src/error/doc_comment_verifier.dart';
import 'package:analyzer/src/error/error_handler_verifier.dart';
import 'package:analyzer/src/error/must_call_super_verifier.dart';
import 'package:analyzer/src/error/null_safe_api_verifier.dart';
import 'package:analyzer/src/error/widget_preview_verifier.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';

/// Instances of the class `BestPracticesVerifier` traverse an AST structure
/// looking for violations of Dart best practices.
class BestPracticesVerifier extends RecursiveAstVisitor<void> {
  /// The class containing the AST nodes being visited, or `null` if we are not
  /// in the scope of a class.
  InterfaceElement? _enclosingClass;

  /// A flag indicating whether a surrounding member is annotated as
  /// `@doNotStore`.
  bool _inDoNotStoreMember = false;

  /// The error reporter by which diagnostics will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// The type [Null].
  final InterfaceType _nullType;

  /// The type system primitives.
  final TypeSystemImpl _typeSystem;

  /// The current library.
  final LibraryElementImpl _currentLibrary;

  final AnnotationVerifier _annotationVerifier;

  final DeprecatedMemberUseVerifier _deprecatedVerifier;

  final ErrorHandlerVerifier _errorHandlerVerifier;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  final MustCallSuperVerifier _mustCallSuperVerifier;

  final NullSafeApiVerifier _nullSafeApiVerifier;

  late final DocCommentVerifier _docCommentVerifier = DocCommentVerifier(
    _diagnosticReporter,
  );

  final WidgetPreviewVerifier _widgetPreviewVerifier;

  /// The [WorkspacePackageImpl] in which [_currentLibrary] is declared.
  final WorkspacePackageImpl? _workspacePackage;

  /// True if inference failures should be reported, otherwise false.
  final bool _strictInference;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPackagePublicApi =
      _workspacePackage != null &&
      _workspacePackage.sourceIsInPublicApi(_currentLibrary.source);

  BestPracticesVerifier(
    this._diagnosticReporter,
    TypeProviderImpl typeProvider,
    this._currentLibrary,
    CompilationUnit unit, {
    required TypeSystemImpl typeSystem,
    required AnalysisOptions analysisOptions,
    required WorkspacePackageImpl? workspacePackage,
  }) : _nullType = typeProvider.nullType,
       _typeSystem = typeSystem,
       _strictInference = analysisOptions.strictInference,
       _annotationVerifier = AnnotationVerifier(
         _diagnosticReporter,
         _currentLibrary,
         workspacePackage,
       ),
       _deprecatedVerifier = DeprecatedMemberUseVerifier(
         workspacePackage,
         _diagnosticReporter,
         strictCasts: analysisOptions.strictCasts,
       ),
       _errorHandlerVerifier = ErrorHandlerVerifier(
         _diagnosticReporter,
         typeProvider,
         typeSystem,
         strictCasts: analysisOptions.strictCasts,
       ),
       _invalidAccessVerifier = _InvalidAccessVerifier(
         _diagnosticReporter,
         unit,
         _currentLibrary,
         workspacePackage,
       ),
       _mustCallSuperVerifier = MustCallSuperVerifier(_diagnosticReporter),
       _nullSafeApiVerifier = NullSafeApiVerifier(
         _diagnosticReporter,
         typeSystem,
       ),
       _widgetPreviewVerifier = WidgetPreviewVerifier(_diagnosticReporter),
       _workspacePackage = workspacePackage {
    _deprecatedVerifier.pushInDeprecatedValue(
      _currentLibrary.metadata.hasDeprecated,
    );
    _inDoNotStoreMember = _currentLibrary.metadata.hasDoNotStore;
  }

  @override
  void visitAnnotation(Annotation node) {
    _annotationVerifier.checkAnnotation(node);
    _widgetPreviewVerifier.checkAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _invalidAccessVerifier._checkForInvalidDoNotSubmitParameter(node);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (_isUnnecessaryCast(node, _typeSystem)) {
      _diagnosticReporter.atNode(node, WarningCode.UNNECESSARY_CAST);
    }
    var type = node.type.type;
    if (type != null &&
        _typeSystem.isNonNullable(type) &&
        node.expression.typeOrThrow.isDartCoreNull) {
      _diagnosticReporter.atNode(node, WarningCode.CAST_FROM_NULL_ALWAYS_FAILS);
    }
    super.visitAsExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _deprecatedVerifier.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _deprecatedVerifier.binaryExpression(node);
    _checkForInvariantNanComparison(node);
    _checkForInvariantNullComparison(node);
    _invalidAccessVerifier.verifyBinary(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitCastPattern(CastPattern node) {
    var type = node.type.type;
    var matchedValueType = node.matchedValueType;
    if (type != null &&
        _typeSystem.isNonNullable(type) &&
        matchedValueType != null &&
        matchedValueType.isDartCoreNull) {
      _diagnosticReporter.atNode(node, WarningCode.CAST_FROM_NULL_ALWAYS_FAILS);
    }
    super.visitCastPattern(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    _checkForNullableTypeInCatchClause(node);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = element;

    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    _deprecatedVerifier.pushInDeprecatedValue(element.metadata.hasDeprecated);
    if (element.metadata.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }

    try {
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _checkForImmutable(node);
    _checkForInvalidSealedSuperclass(node);
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitClassTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitComment(Comment node) {
    for (var docImport in node.docImports) {
      _docCommentVerifier.docImport(docImport);
    }
    for (var docDirective in node.docDirectives) {
      _docCommentVerifier.docDirective(docDirective);
    }
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    var newKeyword = node.newKeyword;
    if (newKeyword != null &&
        _currentLibrary.featureSet.isEnabled(Feature.constructor_tearoffs)) {
      _diagnosticReporter.atToken(
        newKeyword,
        WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE,
      );
    }
    super.visitCommentReference(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    if (node.expression.isDoubleNan) {
      _diagnosticReporter.atNode(
        node,
        WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE,
      );
    }
    super.visitConstantPattern(node);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclaration node) {
    var element = node.declaredFragment!.element;
    _checkStrictInferenceInParameters(
      node.parameters,
      body: node.body,
      initializers: node.initializers,
    );
    _deprecatedVerifier.pushInDeprecatedValue(element.metadata.hasDeprecated);
    try {
      super.visitConstructorDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _deprecatedVerifier.constructorName(node);
    super.visitConstructorName(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var separator = node.separator;
    if (node.isNamed &&
        separator != null &&
        separator.type == TokenType.COLON) {
      // This is a warning in code whose language version is < 3.0, but an error
      // in code whose language version is >= 3.0.
      if (_currentLibrary.languageVersion.effective.major < 3) {
        _diagnosticReporter.atToken(
          separator,
          HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE,
        );
      } else {
        _diagnosticReporter.atToken(
          separator,
          CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE,
        );
      }
    }
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitDefaultFormalParameter(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _deprecatedVerifier.dotShorthandConstructorInvocation(node);
    _checkForLiteralConstructorUseInDotShorthand(node);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitEnumDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    _deprecatedVerifier.exportDirective(node);
    _checkForInternalExport(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (!_invalidAccessVerifier._inTestDirectory) {
      _checkForReturnOfDoNotStore(node.expression);
    }
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitExtensionDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _deprecatedVerifier.extensionOverride(node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitExtensionTypeDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    try {
      super.visitFieldDeclaration(node);
      for (var field in node.fields.variables) {
        if (!_invalidAccessVerifier._inTestDirectory) {
          _checkForAssignmentOfDoNotStore(field.initializer);
        }

        var element = field.declaredFragment!.element;
        var enclosingElement = element.enclosingElement!;
        if (enclosingElement is! InterfaceElement) {
          continue;
        }

        ExecutableElement? overriddenElement;
        if (element
            case PropertyAccessorElement(name: var name?) ||
                FieldElement(name: var name?)) {
          var nameObj = Name(_currentLibrary.source.uri, name);
          overriddenElement =
              enclosingElement.getInheritedConcreteMember(nameObj) ??
              enclosingElement.getInheritedConcreteMember(nameObj.forSetter);
        }

        if (overriddenElement != null &&
            _hasNonVirtualAnnotation(overriddenElement)) {
          // Overridden members are always inside classes or mixins, which are
          // always named, so we can safely assume
          // `overriddenElement.enclosingElement3.name` is non-`null`.
          _diagnosticReporter.atToken(
            field.name,
            WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
            arguments: [
              field.name.lexeme,
              overriddenElement.enclosingElement!.displayName,
            ],
          );
        }
      }
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkFinalParameter(node, node.keyword);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _checkRequiredParameter(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    var element = node.declaredFragment!.element;
    _deprecatedVerifier.pushInDeprecatedValue(element.metadata.hasDeprecated);
    if (element.metadata.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      // Return types are inferred only on non-recursive local functions.
      if (node.parent is CompilationUnit && !node.isSetter) {
        _checkStrictInferenceReturnType(
          node.returnType,
          node,
          node.name.lexeme,
        );
      }
      _checkStrictInferenceInParameters(
        node.functionExpression.parameters,
        body: node.functionExpression.body,
      );
      super.visitFunctionDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // TODO(srawlins): Check strict-inference return type on recursive
    // local functions.
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var body = node.body;
    if (!(node as FunctionExpressionImpl).wasFunctionTypeSupplied) {
      _checkStrictInferenceInParameters(node.parameters, body: node.body);
    }
    _checkForUnnecessarySetLiteral(body, node);
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _deprecatedVerifier.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkStrictInferenceReturnType(node.returnType, node, node.name.lexeme);
    _checkStrictInferenceInParameters(node.parameters);
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitFunctionTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _checkStrictInferenceReturnType(node.returnType, node, node.name.lexeme);
    _checkStrictInferenceInParameters(node.parameters);
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // GenericTypeAlias is handled in [visitGenericTypeAlias], where a proper
    // name can be reported in any message.
    if (node.parent is! GenericTypeAlias) {
      _checkStrictInferenceReturnType(node.returnType, node, node.toString());
    }
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    if (node.functionType != null) {
      _checkStrictInferenceReturnType(
        node.functionType!.returnType,
        node,
        node.name.lexeme,
      );
    }
    _deprecatedVerifier.pushInDeprecatedValue(
      node.declaredFragment!.element.metadata.hasDeprecated,
    );

    try {
      super.visitGenericTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _deprecatedVerifier.importDirective(node);
    var import = node.libraryImport;
    if (import != null && import.prefix2?.isDeferred == true) {
      _checkForLoadLibraryFunction(node, import);
    }
    _invalidAccessVerifier.verifyImport(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _deprecatedVerifier.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    _deprecatedVerifier.instanceCreationExpression(node);
    _nullSafeApiVerifier.instanceCreation(node);
    _checkForLiteralConstructorUse(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIsExpression(covariant IsExpressionImpl node) {
    _checkAllTypeChecks(node);
    super.visitIsExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    var element = node.declaredFragment!.element;
    var enclosingElement = element.enclosingElement;

    _deprecatedVerifier.pushInDeprecatedValue(element.metadata.hasDeprecated);
    if (element.metadata.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      _mustCallSuperVerifier.checkMethodDeclaration(node);
      _checkForUnnecessaryNoSuchMethod(node);
      _checkForNullableEqualsParameterType(node);

      var name = Name.forElement(element);
      if (name == null) {
        return;
      }

      var elementIsOverride = false;
      if (enclosingElement is InterfaceElement) {
        if (element is MethodElement || element is PropertyAccessorElement) {
          elementIsOverride = enclosingElement.getOverridden(name) != null;
        }
      }

      if (!node.isSetter && !elementIsOverride) {
        _checkStrictInferenceReturnType(
          node.returnType,
          node,
          node.name.lexeme,
        );
      }
      if (!elementIsOverride) {
        _checkStrictInferenceInParameters(node.parameters, body: node.body);
      }

      var overriddenElement =
          enclosingElement is InterfaceElement
              ? enclosingElement.getInheritedConcreteMember(name)
              : null;

      if (overriddenElement != null &&
          _hasNonVirtualAnnotation(overriddenElement)) {
        // Overridden members are always inside classes or mixins, which are
        // always named, so we can safely assume
        // `overriddenElement.enclosingElement3.name` is non-`null`.
        _diagnosticReporter.atToken(
          node.name,
          WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
          arguments: [
            node.name.lexeme,
            overriddenElement.enclosingElement!.displayName,
          ],
        );
      }

      super.visitMethodDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
    _deprecatedVerifier.methodInvocation(node);
    _errorHandlerVerifier.verifyMethodInvocation(node);
    _nullSafeApiVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = _enclosingClass;

    _deprecatedVerifier.pushInDeprecatedValue(element.metadata.hasDeprecated);

    try {
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _deprecatedVerifier.namedType(node);
    _invalidAccessVerifier.verifyNamedType(node);
    var question = node.question;
    if (question != null) {
      var type = node.typeOrThrow;
      // Only report non-aliased, non-user-defined `Null?` and `dynamic?`. Do
      // not report synthetic `dynamic` in place of an unresolved type.
      if ((type is InterfaceType && type.element == _nullType.element ||
              (type is DynamicType && node.name.lexeme == 'dynamic')) &&
          type.alias == null) {
        _diagnosticReporter.atToken(
          question,
          WarningCode.UNNECESSARY_QUESTION_MARK,
          arguments: [node.qualifiedName],
        );
      }
    }
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _deprecatedVerifier.patternField(node);
    _invalidAccessVerifier.verifyPatternField(node as PatternFieldImpl);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _deprecatedVerifier.postfixExpression(node);
    if (node.operator.type == TokenType.BANG &&
        node.operand.typeOrThrow.isDartCoreNull) {
      _diagnosticReporter.atNode(node, WarningCode.NULL_CHECK_ALWAYS_FAILS);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _deprecatedVerifier.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _deprecatedVerifier.redirectingConstructorInvocation(node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (!_invalidAccessVerifier._inTestDirectory) {
      _checkForReturnOfDoNotStore(node.expression);
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _checkForDuplications(node);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _deprecatedVerifier.simpleIdentifier(node);
    _invalidAccessVerifier.verify(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _deprecatedVerifier.superConstructorInvocation(node);
    _invalidAccessVerifier.verifySuperConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _checkFinalParameter(node, node.keyword);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    if (!_invalidAccessVerifier._inTestDirectory) {
      for (var decl in node.variables.variables) {
        _checkForAssignmentOfDoNotStore(decl.initializer);
      }
    }

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  /// Checks for the passed [IsExpression] for the unnecessary type check
  /// warning codes as well as null checks expressed using an
  /// [IsExpression].
  ///
  /// Returns `true` if a warning code is generated on [node].
  /// See [WarningCode.TYPE_CHECK_IS_NOT_NULL],
  /// [WarningCode.TYPE_CHECK_IS_NULL],
  /// [WarningCode.UNNECESSARY_TYPE_CHECK_TRUE], and
  /// [WarningCode.UNNECESSARY_TYPE_CHECK_FALSE].
  bool _checkAllTypeChecks(IsExpressionImpl node) {
    var leftNode = node.expression;
    var leftType = leftNode.typeOrThrow;

    var rightNode = node.type;
    var rightType = rightNode.typeOrThrow;

    void report() {
      _diagnosticReporter.atNode(
        node,
        node.notOperator == null
            ? WarningCode.UNNECESSARY_TYPE_CHECK_TRUE
            : WarningCode.UNNECESSARY_TYPE_CHECK_FALSE,
      );
    }

    // `cannotResolve is X` or `cannotResolve is! X`
    if (leftType is InvalidType) {
      return false;
    }

    // `is dynamic` or `is! dynamic`
    if (rightType is DynamicType) {
      report();
      return true;
    }

    // `is CannotResolveType` or `is! CannotResolveType`
    if (rightType is InvalidType) {
      return false;
    }

    // `is Null` or `is! Null`
    if (rightType.isDartCoreNull) {
      if (leftNode is NullLiteral) {
        report();
      } else {
        _diagnosticReporter.atNode(
          node,
          node.notOperator == null
              ? WarningCode.TYPE_CHECK_IS_NULL
              : WarningCode.TYPE_CHECK_IS_NOT_NULL,
        );
      }
      return true;
    }

    if (_typeSystem.isSubtypeOf(leftType, rightType)) {
      report();
      return true;
    }

    return false;
  }

  void _checkFinalParameter(FormalParameter node, Token? keyword) {
    if (node.isFinal) {
      _diagnosticReporter.atToken(keyword!, WarningCode.UNNECESSARY_FINAL);
    }
  }

  void _checkForAssignmentOfDoNotStore(Expression? expression) {
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    for (var entry in expressionMap.entries) {
      // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
      // named elements, so we can safely assume `entry.value.name` is
      // non-`null`.
      _diagnosticReporter.atNode(
        entry.key,
        WarningCode.ASSIGNMENT_OF_DO_NOT_STORE,
        arguments: [entry.value.name!],
      );
    }
  }

  /// Generate hints related to duplicate elements (keys) in sets (maps).
  void _checkForDuplications(SetOrMapLiteral node) {
    // This only checks for top-level elements. If, for, and spread elements
    // that contribute duplicate values are not detected.
    if (node.isConst) {
      // This case is covered by the ErrorVerifier.
      return;
    }
    var expressions =
        node.isSet
            ? node.elements.whereType<Expression>()
            : node.elements.whereType<MapLiteralEntry>().map(
              (entry) => entry.key,
            );
    var alreadySeen = <DartObject>{};
    for (var expression in expressions) {
      var constEvaluation = expression.computeConstantValue();
      if (constEvaluation != null && constEvaluation.diagnostics.isEmpty) {
        var value = constEvaluation.value;
        if (value != null && !alreadySeen.add(value)) {
          var errorCode =
              node.isSet
                  ? WarningCode.EQUAL_ELEMENTS_IN_SET
                  : WarningCode.EQUAL_KEYS_IN_MAP;
          _diagnosticReporter.atNode(expression, errorCode);
        }
      }
    }
  }

  /// Checks whether [node] violates the rules of [immutable].
  ///
  /// If [node] is marked with [immutable] or inherits from a class or mixin
  /// marked with [immutable], this function searches the fields of [node] and
  /// its superclasses, reporting a warning if any non-final instance fields are
  /// found.
  void _checkForImmutable(NamedCompilationUnitMember node) {
    /// Return `true` if the given class [element] or any superclass of it is
    /// annotated with the `@immutable` annotation.
    bool isOrInheritsImmutable(
      InterfaceElement element,
      Set<InterfaceElement> visited,
    ) {
      if (visited.add(element)) {
        if (element.metadata.hasImmutable) {
          return true;
        }
        for (InterfaceType interface in element.mixins) {
          if (isOrInheritsImmutable(interface.element, visited)) {
            return true;
          }
        }
        for (InterfaceType mixin in element.interfaces) {
          if (isOrInheritsImmutable(mixin.element, visited)) {
            return true;
          }
        }
        if (element.supertype != null) {
          return isOrInheritsImmutable(element.supertype!.element, visited);
        }
      }
      return false;
    }

    Iterable<String> nonFinalInstanceFields(InterfaceElement element) {
      return element.fields
          .where(
            (FieldElement field) =>
                !field.isSynthetic && !field.isFinal && !field.isStatic,
          )
          .map((FieldElement field) => '${element.name}.${field.name}');
    }

    Iterable<String> definedOrInheritedNonFinalInstanceFields(
      InterfaceElement element,
      Set<InterfaceElement> visited,
    ) {
      Iterable<String> nonFinalFields = [];
      if (visited.add(element)) {
        nonFinalFields = nonFinalInstanceFields(element);
        nonFinalFields = nonFinalFields.followedBy(
          element.mixins.expand(
            (InterfaceType mixin) => nonFinalInstanceFields(mixin.element),
          ),
        );
        if (element.supertype != null) {
          nonFinalFields = nonFinalFields.followedBy(
            definedOrInheritedNonFinalInstanceFields(
              element.supertype!.element,
              visited,
            ),
          );
        }
      }
      return nonFinalFields;
    }

    var element = node.declaredFragment!.element as InterfaceElement;
    if (isOrInheritsImmutable(element, HashSet<InterfaceElement>())) {
      Iterable<String> nonFinalFields =
          definedOrInheritedNonFinalInstanceFields(
            element,
            HashSet<InterfaceElement>(),
          );
      if (nonFinalFields.isNotEmpty) {
        _diagnosticReporter.atToken(
          node.name,
          WarningCode.MUST_BE_IMMUTABLE,
          arguments: [nonFinalFields.join(', ')],
        );
      }
    }
  }

  /// Check that the namespace exported by [node] does not include any elements
  /// annotated with `@internal`.
  void _checkForInternalExport(ExportDirectiveImpl node) {
    if (!_inPackagePublicApi) return;

    var libraryExport = node.libraryExport;
    if (libraryExport == null) return;

    var libraryElement = libraryExport.exportedLibrary;
    if (libraryElement == null) return;

    if (libraryElement.metadata.hasInternal) {
      _diagnosticReporter.atNode(
        node,
        WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
        arguments: [libraryElement.displayName],
      );
    }
    var exportNamespace = NamespaceBuilder().createExportNamespaceForDirective2(
      libraryExport,
    );
    exportNamespace.definedNames2.forEach((String name, Element element) {
      if (element case Annotatable annotatable) {
        if (annotatable.metadata.hasInternal) {
          _diagnosticReporter.atNode(
            node,
            WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
            arguments: [element.displayName],
          );
          return;
        }
      }
      if (element is ExecutableElement) {
        var signatureTypes = [
          ...element.formalParameters.map((p) => p.type),
          element.returnType,
          ...element.typeParameters.map((tp) => tp.bound),
        ];
        for (var type in signatureTypes) {
          var aliasElement = type?.alias?.element;
          if (aliasElement != null && aliasElement.metadata.hasInternal) {
            _diagnosticReporter.atNode(
              node,
              WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY,
              arguments: [aliasElement.name!, element.displayName],
            );
          }
        }
      }
    });
  }

  void _checkForInvalidSealedSuperclass(NamedCompilationUnitMember node) {
    bool currentPackageContains(Element element) {
      return _isLibraryInWorkspacePackage(element.library);
    }

    // [NamedCompilationUnitMember.declaredElement] is not necessarily a
    // ClassElement, but [_checkForInvalidSealedSuperclass] should only be
    // called with a [ClassOrMixinDeclaration], or a [ClassTypeAlias]. The
    // `declaredElement` of these specific classes is a [ClassElement].
    var element = node.declaredFragment!.element as InterfaceElement;
    // TODO(srawlins): Perhaps replace this with a getter on Element, like
    // `Element.hasOrInheritsSealed`?
    for (InterfaceType supertype in element.allSupertypes) {
      var superclass = supertype.element;
      if (superclass.metadata.hasSealed) {
        if (!currentPackageContains(superclass)) {
          if (element is MixinElement &&
              element.superclassConstraints.contains(supertype)) {
            // This is a special violation of the sealed class contract,
            // requiring specific messaging.
            _diagnosticReporter.atNode(
              node,
              WarningCode.MIXIN_ON_SEALED_CLASS,
              arguments: [superclass.name.toString()],
            );
          } else {
            // This is a regular violation of the sealed class contract.
            _diagnosticReporter.atNode(
              node,
              WarningCode.SUBTYPE_OF_SEALED_CLASS,
              arguments: [superclass.name.toString()],
            );
          }
        }
      }
    }
  }

  void _checkForInvariantNanComparison(BinaryExpression node) {
    void reportStartEnd(
      DiagnosticCode diagnosticCode,
      SyntacticEntity startEntity,
      SyntacticEntity endEntity,
    ) {
      var offset = startEntity.offset;
      _diagnosticReporter.atOffset(
        offset: offset,
        length: endEntity.end - offset,
        diagnosticCode: diagnosticCode,
      );
    }

    void checkLeftRight(DiagnosticCode diagnosticCode) {
      if (node.leftOperand.isDoubleNan) {
        reportStartEnd(diagnosticCode, node.leftOperand, node.operator);
      } else if (node.rightOperand.isDoubleNan) {
        reportStartEnd(diagnosticCode, node.operator, node.rightOperand);
      }
    }

    if (node.operator.type == TokenType.BANG_EQ) {
      checkLeftRight(WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      checkLeftRight(WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE);
    }
  }

  void _checkForInvariantNullComparison(BinaryExpression node) {
    WarningCode errorCode;
    if (node.operator.type == TokenType.BANG_EQ) {
      errorCode = WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE;
    } else if (node.operator.type == TokenType.EQ_EQ) {
      errorCode = WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE;
    } else {
      return;
    }

    if (node.leftOperand is NullLiteral) {
      var rightType = node.rightOperand.typeOrThrow;
      if (_typeSystem.isStrictlyNonNullable(rightType)) {
        var offset = node.leftOperand.offset;
        _diagnosticReporter.atOffset(
          offset: offset,
          length: node.operator.end - offset,
          diagnosticCode: errorCode,
        );
      }
    }

    if (node.rightOperand is NullLiteral) {
      var leftType = node.leftOperand.typeOrThrow;
      if (_typeSystem.isStrictlyNonNullable(leftType)) {
        var offset = node.operator.offset;
        _diagnosticReporter.atOffset(
          offset: offset,
          length: node.rightOperand.end - offset,
          diagnosticCode: errorCode,
        );
      }
    }
  }

  /// Check that the instance creation node is const if the constructor is
  /// marked with [literal].
  void _checkForLiteralConstructorUse(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    var constructor = constructorName.element;
    if (constructor == null) {
      return;
    }
    if (!node.isConst && constructor.metadata.hasLiteral && node.canBeConst) {
      // Echoing jwren's `TODO` from _checkForDeprecatedMemberUse:
      // TODO(jwren): We should modify ConstructorElement.getDisplayName(), or
      // have the logic centralized elsewhere, instead of doing this logic
      // here.
      String fullConstructorName = constructorName.type.qualifiedName;
      if (constructorName.name != null) {
        fullConstructorName = '$fullConstructorName.${constructorName.name}';
      }
      var warning =
          node.keyword?.keyword == Keyword.NEW
              ? WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW
              : WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR;
      _diagnosticReporter.atNode(
        node,
        warning,
        arguments: [fullConstructorName],
      );
    }
  }

  /// Report a warning if the dot shorthand constructor is marked with [literal]
  /// and is not const.
  ///
  /// See [WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR].
  void _checkForLiteralConstructorUseInDotShorthand(
    DotShorthandConstructorInvocation node,
  ) {
    var constructor = node.constructorName.element;
    if (constructor is! ConstructorElement) return;
    if (!node.isConst && constructor.metadata.hasLiteral && node.canBeConst) {
      _diagnosticReporter.atNode(
        node,
        WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR,
        arguments: [constructor.displayName],
      );
    }
  }

  /// Check that the imported library does not define a loadLibrary function.
  /// The import has already been determined to be deferred when this is called.
  ///
  /// @param node the import directive to evaluate
  /// @param importElement the [LibraryImport] retrieved from the node
  /// @return `true` if and only if an error code is generated on the passed
  ///         node
  /// See [HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION].
  bool _checkForLoadLibraryFunction(
    ImportDirective node,
    LibraryImport importElement,
  ) {
    var importedLibrary = importElement.importedLibrary;
    var prefix = importElement.prefix2?.element;
    if (importedLibrary == null || prefix == null) {
      return false;
    }
    var prefixName = prefix.name;
    if (prefixName == null) {
      return false;
    }
    var importNamespace = importElement.namespace;
    var loadLibraryElement = importNamespace.getPrefixed2(
      prefixName,
      TopLevelFunctionElement.LOAD_LIBRARY_NAME,
    );
    if (loadLibraryElement != null) {
      _diagnosticReporter.atNode(
        node,
        HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION,
      );
      return true;
    }
    return false;
  }

  void _checkForNullableEqualsParameterType(MethodDeclaration node) {
    if (node.name.type != TokenType.EQ_EQ) {
      return;
    }

    var parameters = node.parameters;
    if (parameters == null) {
      return;
    }

    if (parameters.parameters.length != 1) {
      return;
    }

    var parameter = parameters.parameters.first;
    var parameterElement = parameter.declaredFragment!.element;

    var type = parameterElement.type;
    if (!type.isDartCoreObject && type is! DynamicType) {
      // There is no legal way to define a nullable parameter type, which is not
      // `dynamic` or `Object?`, so avoid double reporting here.
      return;
    }

    if (_typeSystem.isNullable(parameterElement.type)) {
      _diagnosticReporter.atToken(
        node.name,
        WarningCode.NON_NULLABLE_EQUALS_PARAMETER,
      );
    }
  }

  void _checkForNullableTypeInCatchClause(CatchClause node) {
    var typeNode = node.exceptionType;
    if (typeNode == null) {
      return;
    }

    var typeObj = typeNode.typeOrThrow;
    if (typeObj is InvalidType) {
      return;
    }

    if (_typeSystem.isPotentiallyNullable(typeObj)) {
      _diagnosticReporter.atNode(
        typeNode,
        WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE,
      );
    }
  }

  void _checkForReturnOfDoNotStore(Expression? expression) {
    if (_inDoNotStoreMember) {
      return;
    }
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    if (expressionMap.isNotEmpty) {
      var parent =
          expression!.thisOrAncestorMatching(
                (e) => e is FunctionDeclaration || e is MethodDeclaration,
              )
              as Declaration?;
      if (parent == null) {
        return;
      }
      for (var entry in expressionMap.entries) {
        // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
        // named elements, so we can safely assume `entry.value.name` is
        // non-`null`.
        _diagnosticReporter.atNode(
          entry.key,
          WarningCode.RETURN_OF_DO_NOT_STORE,
          arguments: [
            entry.value.name!,
            parent.declaredFragment!.element.displayName,
          ],
        );
      }
    }
  }

  /// Generates a warning for `noSuchMethod` methods that do nothing except of
  /// calling another `noSuchMethod` which is not defined by `Object`.
  ///
  /// Returns `true` if a warning code is generated for [node].
  bool _checkForUnnecessaryNoSuchMethod(MethodDeclaration node) {
    if (node.name.lexeme != MethodElement.NO_SUCH_METHOD_METHOD_NAME) {
      return false;
    }
    bool isNonObjectNoSuchMethodInvocation(Expression? invocation) {
      if (invocation is MethodInvocation &&
          invocation.target is SuperExpression &&
          invocation.argumentList.arguments.length == 1) {
        SimpleIdentifier name = invocation.methodName;
        if (name.name == MethodElement.NO_SUCH_METHOD_METHOD_NAME) {
          var methodElement = name.element;
          var classElement = methodElement?.enclosingElement;
          return methodElement is MethodElement &&
              classElement is ClassElement &&
              !classElement.isDartCoreObject;
        }
      }
      return false;
    }

    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      if (isNonObjectNoSuchMethodInvocation(body.expression)) {
        _diagnosticReporter.atToken(
          node.name,
          WarningCode.UNNECESSARY_NO_SUCH_METHOD,
        );
        return true;
      }
    } else if (body is BlockFunctionBody) {
      List<Statement> statements = body.block.statements;
      if (statements.length == 1) {
        Statement returnStatement = statements.first;
        if (returnStatement is ReturnStatement &&
            isNonObjectNoSuchMethodInvocation(returnStatement.expression)) {
          _diagnosticReporter.atToken(
            node.name,
            WarningCode.UNNECESSARY_NO_SUCH_METHOD,
          );
          return true;
        }
      }
    }
    return false;
  }

  /// Generate hints related to returning a set literal in an
  /// [ExpressionFunctionBody], having a single expression,
  /// for a function of `void` return type.
  void _checkForUnnecessarySetLiteral(
    FunctionBody body,
    FunctionExpression node,
  ) {
    if (body is ExpressionFunctionBodyImpl) {
      var parameterType = node.correspondingParameter?.type;

      DartType? returnType;
      if (parameterType is FunctionType) {
        returnType = parameterType.returnType;
      } else {
        var parent = node.parent;
        if (parent is! FunctionDeclaration) return;
        returnType = parent.returnType?.type;
      }
      if (returnType == null) return;

      bool isReturnVoid;
      if (returnType is VoidType) {
        isReturnVoid = true;
      } else if (returnType is ParameterizedType &&
          (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr)) {
        var typeArguments = returnType.typeArguments;
        isReturnVoid =
            typeArguments.length == 1 && typeArguments.first is VoidType;
      } else {
        isReturnVoid = false;
      }
      if (isReturnVoid) {
        var expression = body.expression;
        if (expression is SetOrMapLiteralImpl && expression.isSet) {
          _diagnosticReporter.atNode(
            expression,
            WarningCode.UNNECESSARY_SET_LITERAL,
          );
        }
      }
    }
  }

  void _checkRequiredParameter(FormalParameterList node) {
    var requiredParameters = node.parameters.where(
      (p) => p.declaredFragment?.element.metadata.hasRequired == true,
    );
    var nonNamedParamsWithRequired = requiredParameters.where(
      (p) => p.isPositional,
    );
    var namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.isNamed)
        .where((p) => p is DefaultFormalParameter && p.defaultValue != null);
    for (var param in nonNamedParamsWithRequired.where((p) => p.isOptional)) {
      _diagnosticReporter.atNode(
        param,
        WarningCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM,
        arguments: [_formalParameterNameOrEmpty(param)],
      );
    }
    for (var param in nonNamedParamsWithRequired.where((p) => p.isRequired)) {
      _diagnosticReporter.atNode(
        param,
        WarningCode.INVALID_REQUIRED_POSITIONAL_PARAM,
        arguments: [_formalParameterNameOrEmpty(param)],
      );
    }
    for (var param in namedParamsWithRequiredAndDefault) {
      _diagnosticReporter.atNode(
        param,
        WarningCode.INVALID_REQUIRED_NAMED_PARAM,
        arguments: [_formalParameterNameOrEmpty(param)],
      );
    }
  }

  /// In "strict-inference" mode, check that each of the [parameters]' type is
  /// specified.
  ///
  /// Only parameters which are referenced in [initializers] or [body] are
  /// reported. If [initializers] and [body] are both null, the parameters are
  /// assumed to originate from a typedef, function-typed parameter, or function
  /// which is abstract or external.
  void _checkStrictInferenceInParameters(
    FormalParameterList? parameters, {
    List<ConstructorInitializer>? initializers,
    FunctionBody? body,
  }) {
    _UsedParameterVisitor? usedParameterVisitor;

    bool isParameterReferenced(SimpleFormalParameter parameter) {
      if ((body == null || body is EmptyFunctionBody) && initializers == null) {
        // The parameter is in a typedef, or function that is abstract,
        // external, etc.
        return true;
      }
      if (usedParameterVisitor == null) {
        // Visit the function body and initializers once to determine whether
        // each of the parameters is referenced.
        usedParameterVisitor = _UsedParameterVisitor(
          parameters!.parameters
              .map((p) => p.declaredFragment!.element)
              .toSet(),
        );
        body?.accept(usedParameterVisitor!);
        for (var initializer in initializers ?? <ConstructorInitializer>[]) {
          initializer.accept(usedParameterVisitor!);
        }
      }

      return usedParameterVisitor!.isUsed(parameter.declaredFragment!.element);
    }

    void checkParameterTypeIsKnown(SimpleFormalParameter parameter) {
      if (parameter.type == null && isParameterReferenced(parameter)) {
        var element = parameter.declaredFragment!.element;
        _diagnosticReporter.atNode(
          parameter,
          WarningCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER,
          arguments: [element.displayName],
        );
      }
    }

    if (_strictInference && parameters != null) {
      for (FormalParameter parameter in parameters.parameters) {
        if (parameter is SimpleFormalParameter) {
          checkParameterTypeIsKnown(parameter);
        } else if (parameter is DefaultFormalParameter) {
          var nonDefault = parameter.parameter;
          if (nonDefault is SimpleFormalParameter) {
            checkParameterTypeIsKnown(nonDefault);
          }
        }
      }
    }
  }

  /// In "strict-inference" mode, check that [returnType] is specified.
  void _checkStrictInferenceReturnType(
    AstNode? returnType,
    AstNode reportNode,
    String displayName,
  ) {
    if (!_strictInference || returnType != null) {
      return;
    }

    switch (reportNode) {
      case MethodDeclaration():
        _diagnosticReporter.atToken(
          reportNode.name,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
      case FunctionDeclaration():
        _diagnosticReporter.atToken(
          reportNode.name,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
      case _:
        _diagnosticReporter.atNode(
          reportNode,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
    }
  }

  /// Return subexpressions that are marked `@doNotStore`, as a map so that
  /// corresponding elements can be used in the diagnostic message.
  Map<Expression, Element> _getSubExpressionsMarkedDoNotStore(
    Expression? expression, {
    Map<Expression, Element>? addTo,
  }) {
    var expressions = addTo ?? <Expression, Element>{};

    Element? element;
    if (expression is PropertyAccess) {
      element = expression.propertyName.element;
      // Tear-off.
      if (element is LocalFunctionElement ||
          element is TopLevelFunctionElement ||
          element is MethodElement) {
        element = null;
      }
    } else if (expression is MethodInvocation) {
      element = expression.methodName.element;
    } else if (expression is Identifier) {
      element = expression.element;
      // Tear-off.
      if (element is LocalFunctionElement ||
          element is TopLevelFunctionElement ||
          element is MethodElement) {
        element = null;
      }
    } else if (expression is ConditionalExpression) {
      _getSubExpressionsMarkedDoNotStore(
        expression.elseExpression,
        addTo: expressions,
      );
      _getSubExpressionsMarkedDoNotStore(
        expression.thenExpression,
        addTo: expressions,
      );
    } else if (expression is BinaryExpression) {
      _getSubExpressionsMarkedDoNotStore(
        expression.leftOperand,
        addTo: expressions,
      );
      _getSubExpressionsMarkedDoNotStore(
        expression.rightOperand,
        addTo: expressions,
      );
    } else if (expression is FunctionExpression) {
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        _getSubExpressionsMarkedDoNotStore(body.expression, addTo: expressions);
      }
    }
    if (element is PropertyAccessorElement && element.isSynthetic) {
      element = element.variable;
    }

    if (element != null && element.hasOrInheritsDoNotStore) {
      expressions[expression!] = element;
    }

    return expressions;
  }

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage.contains(library.firstFragment.source);
  }

  static String _formalParameterNameOrEmpty(FormalParameter node) {
    return node.name?.lexeme ?? '';
  }

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is PropertyAccessorElement && element.isSynthetic) {
      var variable = element.variable;
      if (variable != null && variable.metadata.hasNonVirtual) {
        return true;
      }
    }
    return element.metadata.hasNonVirtual;
  }

  /// Checks for the passed as expression for the [WarningCode.UNNECESSARY_CAST]
  /// hint code.
  ///
  /// Returns `true` if and only if an unnecessary cast hint should be generated
  /// on [node].  See [WarningCode.UNNECESSARY_CAST].
  static bool _isUnnecessaryCast(AsExpression node, TypeSystemImpl typeSystem) {
    var leftType = node.expression.typeOrThrow;
    var rightType = node.type.typeOrThrow;

    // `cannotResolve is SomeType` is already reported.
    if (leftType is InvalidType) {
      return false;
    }

    // `x as Unresolved` is already reported as an error.
    if (rightType is InvalidType) {
      return false;
    }

    // The cast is necessary.
    if (leftType != rightType) {
      return false;
    }

    // `x as dynamic` is a valid use case. The explicit cast is a recommended
    // way to dynamically call a `Function` when the `avoid_dynamic_calls` lint
    // rule is enabled.
    if (rightType is DynamicType) {
      return false;
    }

    // `x as Function` is a valid use case. The explicit cast is a recommended
    // way to dynamically call a `Function` when the `avoid_dynamic_calls` lint
    // rule is enabled.
    if (rightType.isDartCoreFunction) {
      return false;
    }

    return true;
  }
}

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';

  final DiagnosticReporter _errorReporter;
  final LibraryElement _library;
  final WorkspacePackageImpl? _workspacePackage;

  final bool _inTemplateSource;
  final bool _inTestDirectory;

  InterfaceElement? _enclosingClass;

  _InvalidAccessVerifier(
    this._errorReporter,
    CompilationUnit unit,
    this._library,
    this._workspacePackage,
  ) : _inTemplateSource = _library.firstFragment.source.fullName.contains(
        _templateExtension,
      ),
      _inTestDirectory = unit.inTestDir;

  /// Produces a warning if [identifier] is accessed from an invalid location.
  ///
  /// In particular, a warning is produced in either of the two following cases:
  ///
  /// * The element associated with [identifier] is annotated with [internal],
  ///   and is accessed from outside the package in which the element is
  ///   declared.
  /// * The element associated with [identifier] is annotated with [protected],
  ///   [visibleForTesting], and/or `visibleForTemplate`, and is accessed from a
  ///   location which is invalid as per the rules of each such annotation.
  ///   Conversely, if the element is annotated with more than one of these
  ///   annotations, the access is valid (and no warning is produced) if it
  ///   conforms to the rules of at least one of the annotations.
  void verify(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext() || _inCommentReference(identifier)) {
      return;
    }

    // This is the same logic used in [checkForDeprecatedMemberUseAtIdentifier]
    // to avoid reporting an error twice for named constructors.
    var parent = identifier.parent;
    if (parent is ConstructorName && identical(identifier, parent.name)) {
      return;
    }
    var grandparent = parent?.parent;

    var element =
        grandparent is ConstructorName
            ? grandparent.element
            : identifier.writeOrReadElement;

    if (element == null) {
      return;
    }

    _checkForInvalidDoNotSubmitAccess(identifier, element);

    if (_inCurrentLibrary(element)) {
      return;
    }

    if (parent is HideCombinator) {
      return;
    }

    _checkForInvalidInternalAccess(
      parent: identifier.parent,
      nameToken: identifier.token,
      element: element,
    );

    _checkForOtherInvalidAccess(identifier, element);
  }

  void verifyBinary(BinaryExpression node) {
    var element = node.element;
    if (element != null && _hasVisibleForOverriding(element)) {
      var operator = node.operator;

      if (node.leftOperand is SuperExpression) {
        var methodDeclaration = node.thisOrAncestorOfType<MethodDeclaration>();
        if (methodDeclaration?.name.lexeme == operator.lexeme) {
          return;
        }
      }

      _errorReporter.atToken(
        operator,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER,
        arguments: [operator.type.lexeme],
      );
    }
  }

  void verifyImport(ImportDirective node) {
    var importedLibrary = node.libraryImport?.importedLibrary;
    if (importedLibrary != null &&
        importedLibrary.isInternal &&
        !_isLibraryInWorkspacePackage(importedLibrary)) {
      // The only way for an import directive's URI to have a `null`
      // `stringValue` is if its string contains an interpolation, in which case
      // the element would never have resolved in the first place.  So we can
      // safely assume `node.uri.stringValue` is non-`null`.
      _errorReporter.atNode(
        node,
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        arguments: [node.uri.stringValue!],
      );
    }
  }

  void verifyNamedType(NamedType node) {
    var element = node.element;

    var parent = node.parent;
    if (parent is ConstructorName) {
      element = parent.element;
    }

    if (element == null) {
      return;
    }

    _checkForInvalidDoNotSubmitAccess(node, element);

    if (_inCurrentLibrary(element)) {
      return;
    }

    _checkForInvalidInternalAccess(
      parent: node,
      nameToken: node.name,
      element: element,
    );

    _checkForOtherInvalidAccess(node, element);
  }

  void verifyPatternField(PatternFieldImpl node) {
    var element = node.element;
    if (element == null) {
      return;
    }
    _checkForInvalidDoNotSubmitAccess(node, element);

    if (_inCurrentLibrary(element)) {
      return;
    }

    if (element.isInternal && !_isLibraryInWorkspacePackage(element.library)) {
      var fieldName = node.name;
      if (fieldName == null) {
        return;
      }
      var errorEntity = node.errorEntity;

      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        arguments: [element.displayName],
      );
    }

    _checkForOtherInvalidAccess(node, element);
  }

  void verifySuperConstructorInvocation(SuperConstructorInvocation node) {
    if (node.constructorName != null) {
      // Named constructor calls are handled by [verify].
      return;
    }
    var element = node.element;
    if (element != null &&
        element.isInternal &&
        !_isLibraryInWorkspacePackage(element.library)) {
      _errorReporter.atNode(
        node,
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        arguments: [element.name!],
      );
    }
  }

  void _checkForInvalidDoNotSubmitAccess(AstNode node, Element element) {
    if (element is FormalParameterElement || !_hasDoNotSubmit(element)) {
      return;
    }

    // It's valid for a member annotated with `@doNotSubmit` to access another
    // member annotated with `@doNotSubmit`. For example, this is valid:
    // ```
    // @doNotSubmit
    // void foo() {}
    //
    // @doNotSubmit
    // void bar() {
    //   // OK: `foo` is annotated with `@doNotSubmit` but so is `bar`.
    //   foo();
    // }
    // ```
    var declaration = node.thisOrAncestorOfType<Declaration>();
    if (declaration != null) {
      var element = declaration.declaredFragment?.element;
      if (element != null && _hasDoNotSubmit(element)) {
        return;
      }
    }

    var (name, errorEntity) = _getIdentifierNameAndErrorEntity(node, element);
    _errorReporter.atOffset(
      offset: errorEntity.offset,
      length: errorEntity.length,
      diagnosticCode: WarningCode.INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER,
      arguments: [name],
    );
  }

  // void a({@doNotSubmit int? b}) {}
  // void c() {
  //   // Error: `b` is annotated with `@doNotSubmit` and it's a parameter.
  //   a(b: 0);
  // }
  void _checkForInvalidDoNotSubmitParameter(ArgumentList node) {
    // void a({@doNotSubmit int? b}) {
    //   // OK: `b` is annotated with `@doNotSubmit` but it's a parameter.
    //   print(b);
    // }
    //
    // void c({@doNotSubmit int? b}) {
    //   void d() {
    //     // OK: `b` is annotated with `@doNotSubmit` but it's a parent arg.
    //     print(b);
    //   }
    // }

    // Check if the method being called is a parent method of the current node.
    var bodyParent = node.thisOrAncestorOfType<FunctionBody>()?.parent;
    if (bodyParent == node.thisOrAncestorOfType<FunctionDeclaration>() ||
        bodyParent == node.thisOrAncestorOfType<MethodDeclaration>()) {
      return;
    }

    for (var argument in node.arguments) {
      var element = argument.correspondingParameter;
      if (element != null) {
        if (!_hasDoNotSubmit(element)) {
          continue;
        }
        if (argument is NamedExpression) {
          argument = argument.name.label;
          var (name, errorEntity) = _getIdentifierNameAndErrorEntity(
            argument,
            element,
          );
          _errorReporter.atOffset(
            offset: errorEntity.offset,
            length: errorEntity.length,
            diagnosticCode: WarningCode.INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER,
            arguments: [name],
          );
        } else {
          // For positional arguments.
          _errorReporter.atNode(
            argument,
            WarningCode.INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER,
            arguments: [element.displayName],
          );
        }
      }
    }
  }

  void _checkForInvalidInternalAccess({
    required AstNode? parent,
    required Token nameToken,
    required Element element,
  }) {
    if (element.isInternal && !_isLibraryInWorkspacePackage(element.library)) {
      String name;
      SyntacticEntity node;

      var grandparent = parent?.parent;

      if (grandparent is ConstructorName) {
        name = grandparent.toSource();
        node = grandparent;
      } else {
        name = nameToken.lexeme;
        node = nameToken;
      }

      _errorReporter.atEntity(
        node,
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        arguments: [name],
      );
    }
  }

  void _checkForOtherInvalidAccess(AstNode node, Element element) {
    var hasProtected = element.isProtected;
    if (hasProtected) {
      var definingClass = element.enclosingElement as InterfaceElement;
      if (_hasTypeOrSuperType(_enclosingClass, definingClass)) {
        return;
      }
    }

    var isVisibleForTemplateApplied = _isVisibleForTemplateApplied(element);
    if (isVisibleForTemplateApplied) {
      if (_inTemplateSource || _inExportDirective(node)) {
        return;
      }
    }

    var hasVisibleForTesting = element.isVisibleForTesting;
    if (hasVisibleForTesting) {
      if (_inTestDirectory || _inExportDirective(node)) {
        return;
      }
    }

    var (name, errorEntity) = _getIdentifierNameAndErrorEntity(node, element);

    var hasVisibleForOverriding = _hasVisibleForOverriding(element);
    if (hasVisibleForOverriding) {
      var parent = node.parent;
      if (parent is MethodInvocation && parent.target is SuperExpression ||
          parent is PropertyAccess && parent.target is SuperExpression) {
        var grandparent = parent?.parent;
        var methodDeclaration =
            grandparent?.thisOrAncestorOfType<MethodDeclaration>();
        if (methodDeclaration?.name.lexeme == name) {
          return;
        }
      }
    }

    // At this point, [identifier] was not cleared as protected access, nor
    // cleared as access for templates or testing. Report a violation for each
    // annotation present.

    var definingClass = element.enclosingElement;
    if (definingClass == null) {
      return;
    }

    if (hasProtected) {
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_PROTECTED_MEMBER,
        arguments: [name, definingClass.displayName],
      );
    }

    if (isVisibleForTemplateApplied) {
      var libraryFragment = definingClass.firstFragment.libraryFragment!;
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
        arguments: [name, libraryFragment.source.uri],
      );
    }

    if (hasVisibleForTesting) {
      var libraryFragment = definingClass.firstFragment.libraryFragment!;
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
        arguments: [name, libraryFragment.source.uri],
      );
    }

    if (hasVisibleForOverriding) {
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER,
        arguments: [name],
      );
    }
  }

  bool _hasDoNotSubmit(Element element) {
    if (element case Annotatable annotatable) {
      if (annotatable.metadata.hasDoNotSubmit) {
        return true;
      }
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable;
      return variable != null && variable.metadata.hasDoNotSubmit;
    }
    return false;
  }

  bool _hasTypeOrSuperType(
    InterfaceElement? element,
    InterfaceElement superElement,
  ) {
    if (element == null) {
      return false;
    }
    return element.thisType.asInstanceOf(superElement) != null;
  }

  bool _hasVisibleForOverriding(Element element) {
    if (element case Annotatable annotatable) {
      if (annotatable.metadata.hasVisibleForOverriding) {
        return true;
      }
    }

    if (element is PropertyAccessorElement) {
      var variable = element.variable;
      return variable != null && variable.metadata.hasVisibleForOverriding;
    }

    return false;
  }

  bool _hasVisibleForTemplate(Element? element) {
    if (element == null) {
      return false;
    }
    if (element case Annotatable annotatable) {
      if (annotatable.metadata.hasVisibleForTemplate) {
        return true;
      }
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable;
      if (variable != null && variable.metadata.hasVisibleForTemplate) {
        return true;
      }
    }
    var enclosingElement = element.enclosingElement;
    if (_hasVisibleForTemplate(enclosingElement)) {
      return true;
    }
    return false;
  }

  bool _hasVisibleOutsideTemplate(Element element) {
    if (element case Annotatable annotatable) {
      if (annotatable.metadata.hasVisibleOutsideTemplate) {
        return true;
      }
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable;
      if (variable != null && variable.metadata.hasVisibleOutsideTemplate) {
        return true;
      }
    }
    var enclosingElement = element.enclosingElement;
    if (enclosingElement != null &&
        _hasVisibleOutsideTemplate(enclosingElement)) {
      return true;
    }
    return false;
  }

  bool _inCommentReference(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is CommentReference || parent?.parent is CommentReference;
  }

  bool _inCurrentLibrary(Element element) => element.library == _library;

  bool _inExportDirective(AstNode node) =>
      node.parent is Combinator && node.parent!.parent is ExportDirective;

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage.contains(library.firstFragment.source);
  }

  /// Check if @visibleForTemplate is applied to the given [Element].
  ///
  /// [ClassElement], [EnumElement] and [MixinElement] are excluded from the
  /// @visibleForTemplate access checks. Instead, the access restriction is
  /// cascaded to all the corresponding members not annotated by
  /// @visibleOutsideTemplate.
  /// For other types of elements, check if they are annotated based on
  /// `hasVisibleForTemplate` value.
  bool _isVisibleForTemplateApplied(Element element) {
    if (element is ClassElement ||
        element is EnumElement ||
        element is MixinElement) {
      return false;
    } else {
      return _hasVisibleForTemplate(element) &&
          !_hasVisibleOutsideTemplate(element);
    }
  }

  static (String, SyntacticEntity) _getIdentifierNameAndErrorEntity(
    AstNode node,
    Element element,
  ) {
    String name;
    SyntacticEntity errorEntity = node;

    var parent = node.parent;
    var grandparent = parent?.parent;
    if (node is Identifier) {
      if (grandparent is ConstructorName) {
        name = grandparent.toSource();
        errorEntity = grandparent;
      } else {
        name = node.name;
      }
    } else if (node is NamedType) {
      if (parent is ConstructorName) {
        name = parent.toSource();
        errorEntity = parent;
      } else {
        name = node.name.lexeme;
      }
    } else if (node is PatternFieldImpl) {
      name = element.displayName;
      errorEntity = node.errorEntity;
    } else {
      throw StateError('Unhandled node type: ${node.runtimeType}');
    }

    return (name, errorEntity);
  }
}

/// A visitor that determines, upon visiting a function body and/or a
/// constructor's initializers, whether a parameter is referenced.
class _UsedParameterVisitor extends RecursiveAstVisitor<void> {
  final Set<FormalParameterElement> _parameters;

  final Set<FormalParameterElement> _usedParameters = {};

  _UsedParameterVisitor(this._parameters);

  bool isUsed(FormalParameterElement parameter) =>
      _usedParameters.contains(parameter);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is ExecutableMember) {
      element = element.baseElement;
    }
    if (_parameters.contains(element)) {
      _usedParameters.add(element as FormalParameterElement);
    }
  }
}

extension on Expression {
  /// Whether this is the [PrefixedIdentifier] referring to `double.nan`.
  // TODO(srawlins): This will return the wrong answer for `prefixed.double.nan`
  // and for `import 'foo.dart' as double; double.nan`.
  bool get isDoubleNan {
    var self = this;
    return self is PrefixedIdentifier &&
        self.prefix.name == 'double' &&
        self.identifier.name == 'nan';
  }
}

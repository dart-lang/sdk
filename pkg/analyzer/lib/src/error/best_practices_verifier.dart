// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

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
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart' show ExecutableMember;
import 'package:analyzer/src/dart/element/type.dart';
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
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/linter.dart';
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

  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type [Null].
  final InterfaceType _nullType;

  /// The type system primitives.
  final TypeSystemImpl _typeSystem;

  /// The inheritance manager to access interface type hierarchy.
  final InheritanceManager3 _inheritanceManager;

  /// The current library.
  final LibraryElement _currentLibrary;

  final AnnotationVerifier _annotationVerifier;

  final DeprecatedMemberUseVerifier _deprecatedVerifier;

  final ErrorHandlerVerifier _errorHandlerVerifier;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  final MustCallSuperVerifier _mustCallSuperVerifier;

  final NullSafeApiVerifier _nullSafeApiVerifier;

  late final DocCommentVerifier _docCommentVerifier =
      DocCommentVerifier(_errorReporter);

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage? _workspacePackage;

  /// True if inference failures should be reported, otherwise false.
  final bool _strictInference;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPackagePublicApi = _workspacePackage != null &&
      _workspacePackage.sourceIsInPublicApi(_currentLibrary.source);

  BestPracticesVerifier(
    this._errorReporter,
    TypeProviderImpl typeProvider,
    this._currentLibrary,
    CompilationUnit unit, {
    required TypeSystemImpl typeSystem,
    required InheritanceManager3 inheritanceManager,
    required AnalysisOptions analysisOptions,
    required WorkspacePackage? workspacePackage,
  })  : _nullType = typeProvider.nullType,
        _typeSystem = typeSystem,
        _strictInference =
            (analysisOptions as AnalysisOptionsImpl).strictInference,
        _inheritanceManager = inheritanceManager,
        _annotationVerifier = AnnotationVerifier(
            _errorReporter, _currentLibrary, workspacePackage),
        _deprecatedVerifier = DeprecatedMemberUseVerifier(
            workspacePackage, _errorReporter,
            strictCasts: analysisOptions.strictCasts),
        _errorHandlerVerifier = ErrorHandlerVerifier(
            _errorReporter, typeProvider, typeSystem,
            strictCasts: analysisOptions.strictCasts),
        _invalidAccessVerifier = _InvalidAccessVerifier(
            _errorReporter, unit, _currentLibrary, workspacePackage),
        _mustCallSuperVerifier = MustCallSuperVerifier(_errorReporter),
        _nullSafeApiVerifier = NullSafeApiVerifier(_errorReporter, typeSystem),
        _workspacePackage = workspacePackage {
    _deprecatedVerifier.pushInDeprecatedValue(_currentLibrary.hasDeprecated);
    _inDoNotStoreMember = _currentLibrary.hasDoNotStore;
  }

  @override
  void visitAnnotation(Annotation node) {
    _annotationVerifier.checkAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _invalidAccessVerifier._checkForInvalidDoNotSubmitParameter(node);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (isUnnecessaryCast(node, _typeSystem)) {
      _errorReporter.atNode(
        node,
        WarningCode.UNNECESSARY_CAST,
      );
    }
    var type = node.type.type;
    if (type != null &&
        _typeSystem.isNonNullable(type) &&
        node.expression.typeOrThrow.isDartCoreNull) {
      _errorReporter.atNode(
        node,
        WarningCode.CAST_FROM_NULL_ALWAYS_FAILS,
      );
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
      _errorReporter.atNode(
        node,
        WarningCode.CAST_FROM_NULL_ALWAYS_FAILS,
      );
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
    var element = node.declaredElement!;
    if (element.isAugmentation) {
      return;
    }

    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = element;

    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
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
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

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
      _errorReporter.atToken(
        newKeyword,
        WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE,
      );
    }
    super.visitCommentReference(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    if (node.expression.isDoubleNan) {
      _errorReporter.atNode(
        node,
        WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE,
      );
    }
    super.visitConstantPattern(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredElement as ConstructorElementImpl;
    _checkStrictInferenceInParameters(node.parameters,
        body: node.body, initializers: node.initializers);
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
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
        _errorReporter.atToken(
          separator,
          HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE,
        );
      } else {
        _errorReporter.atToken(
          separator,
          CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE,
        );
      }
    }
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

    try {
      super.visitDefaultFormalParameter(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

    try {
      super.visitEnumDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
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
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

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
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

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
        ExecutableElement? getOverriddenPropertyAccessor() {
          var element = field.declaredElement;
          if (element is PropertyAccessorElement || element is FieldElement) {
            Name name = Name(_currentLibrary.source.uri, element!.name);
            var enclosingElement = element.enclosingElement3!;
            var enclosingDeclaration = enclosingElement is InstanceElement
                ? enclosingElement.augmented.declaration
                : enclosingElement;
            if (enclosingDeclaration is InterfaceElement) {
              var overridden = _inheritanceManager
                  .getMember2(enclosingDeclaration, name, forSuper: true);
              // Check for a setter.
              if (overridden == null) {
                Name setterName =
                    Name(_currentLibrary.source.uri, '${element.name}=');
                overridden = _inheritanceManager.getMember2(
                    enclosingDeclaration, setterName,
                    forSuper: true);
              }
              return overridden;
            }
          }
          return null;
        }

        var overriddenElement = getOverriddenPropertyAccessor();
        if (overriddenElement != null &&
            _hasNonVirtualAnnotation(overriddenElement)) {
          // Overridden members are always inside classes or mixins, which are
          // always named, so we can safely assume
          // `overriddenElement.enclosingElement3.name` is non-`null`.
          _errorReporter.atToken(
            field.name,
            WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
            arguments: [
              field.name.lexeme,
              overriddenElement.enclosingElement3.displayName
            ],
          );
        }
        if (!_invalidAccessVerifier._inTestDirectory) {
          _checkForAssignmentOfDoNotStore(field.initializer);
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
    ExecutableElement element = node.declaredElement!;
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      // Return types are inferred only on non-recursive local functions.
      if (node.parent is CompilationUnit && !node.isSetter) {
        _checkStrictInferenceReturnType(
            node.returnType, node, node.name.lexeme);
      }
      _checkStrictInferenceInParameters(node.functionExpression.parameters,
          body: node.functionExpression.body);
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
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

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
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.functionType != null) {
      _checkStrictInferenceReturnType(
          node.functionType!.returnType, node, node.name.lexeme);
    }
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement!.hasDeprecated);

    try {
      super.visitGenericTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _deprecatedVerifier.importDirective(node);
    var importElement = node.element;
    if (importElement != null &&
        importElement.prefix is DeferredImportElementPrefix) {
      _checkForLoadLibraryFunction(node, importElement);
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
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _deprecatedVerifier.instanceCreationExpression(node);
    _nullSafeApiVerifier.instanceCreation(node);
    _checkForLiteralConstructorUse(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkAllTypeChecks(node);
    super.visitIsExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    var element = node.declaredElement!;
    var enclosingElement = element.enclosingElement3;
    var enclosingDeclaration = enclosingElement is InstanceElement
        ? enclosingElement.augmented.declaration
        : enclosingElement;

    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      _mustCallSuperVerifier.checkMethodDeclaration(node);
      _checkForUnnecessaryNoSuchMethod(node);
      _checkForNullableEqualsParameterType(node);

      var name = Name(_currentLibrary.source.uri, element.name);
      var elementIsOverride = element is ClassMemberElement &&
              enclosingDeclaration is InterfaceElement
          ? _inheritanceManager.getOverridden2(enclosingDeclaration, name) !=
              null
          : false;

      if (!node.isSetter && !elementIsOverride) {
        _checkStrictInferenceReturnType(
            node.returnType, node, node.name.lexeme);
      }
      if (!elementIsOverride) {
        _checkStrictInferenceInParameters(node.parameters, body: node.body);
      }

      var overriddenElement = enclosingDeclaration is InterfaceElement
          ? _inheritanceManager.getMember2(enclosingDeclaration, name,
              forSuper: true)
          : null;

      if (overriddenElement != null &&
          _hasNonVirtualAnnotation(overriddenElement)) {
        // Overridden members are always inside classes or mixins, which are
        // always named, so we can safely assume
        // `overriddenElement.enclosingElement3.name` is non-`null`.
        _errorReporter.atToken(
          node.name,
          WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
          arguments: [
            node.name.lexeme,
            overriddenElement.enclosingElement3.displayName
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
  void visitMethodInvocation(MethodInvocation node) {
    _deprecatedVerifier.methodInvocation(node);
    _errorHandlerVerifier.verifyMethodInvocation(node);
    _nullSafeApiVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var element = node.declaredElement!;
    if (element.isAugmentation) {
      return;
    }

    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = _enclosingClass;

    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);

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
              (type is DynamicType && node.name2.lexeme == 'dynamic')) &&
          type.alias == null) {
        _errorReporter.atToken(
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
      _errorReporter.atNode(
        node,
        WarningCode.NULL_CHECK_ALWAYS_FAILS,
      );
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
      RedirectingConstructorInvocation node) {
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
  bool _checkAllTypeChecks(IsExpression node) {
    var leftNode = node.expression;
    var leftType = leftNode.typeOrThrow;

    var rightNode = node.type;
    var rightType = rightNode.type as TypeImpl;

    void report() {
      _errorReporter.atNode(
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
        _errorReporter.atNode(
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
      _errorReporter.atToken(
        keyword!,
        WarningCode.UNNECESSARY_FINAL,
      );
    }
  }

  void _checkForAssignmentOfDoNotStore(Expression? expression) {
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    for (var entry in expressionMap.entries) {
      // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
      // named elements, so we can safely assume `entry.value.name` is
      // non-`null`.
      _errorReporter.atNode(
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
    var expressions = node.isSet
        ? node.elements.whereType<Expression>()
        : node.elements.whereType<MapLiteralEntry>().map((entry) => entry.key);
    var alreadySeen = <DartObject>{};
    for (var expression in expressions) {
      var constEvaluation = expression.computeConstantValue();
      if (constEvaluation.errors.isEmpty) {
        var value = constEvaluation.value;
        if (value != null && !alreadySeen.add(value)) {
          var errorCode = node.isSet
              ? WarningCode.EQUAL_ELEMENTS_IN_SET
              : WarningCode.EQUAL_KEYS_IN_MAP;
          _errorReporter.atNode(
            expression,
            errorCode,
          );
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
        InterfaceElement element, Set<InterfaceElement> visited) {
      if (visited.add(element)) {
        if (element.hasImmutable) {
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
          .where((FieldElement field) =>
              !field.isSynthetic && !field.isFinal && !field.isStatic)
          .map((FieldElement field) => '${element.name}.${field.name}');
    }

    Iterable<String> definedOrInheritedNonFinalInstanceFields(
        InterfaceElement element, Set<InterfaceElement> visited) {
      Iterable<String> nonFinalFields = [];
      if (visited.add(element)) {
        nonFinalFields = nonFinalInstanceFields(element);
        nonFinalFields = nonFinalFields.followedBy(element.mixins.expand(
            (InterfaceType mixin) => nonFinalInstanceFields(mixin.element)));
        if (element.supertype != null) {
          nonFinalFields = nonFinalFields.followedBy(
              definedOrInheritedNonFinalInstanceFields(
                  element.supertype!.element, visited));
        }
      }
      return nonFinalFields;
    }

    var element = node.declaredElement as InterfaceElement;
    if (isOrInheritsImmutable(element, HashSet<InterfaceElement>())) {
      Iterable<String> nonFinalFields =
          definedOrInheritedNonFinalInstanceFields(
              element, HashSet<InterfaceElement>());
      if (nonFinalFields.isNotEmpty) {
        _errorReporter.atToken(
          node.name,
          WarningCode.MUST_BE_IMMUTABLE,
          arguments: [nonFinalFields.join(', ')],
        );
      }
    }
  }

  /// Check that the namespace exported by [node] does not include any elements
  /// annotated with `@internal`.
  void _checkForInternalExport(ExportDirective node) {
    if (!_inPackagePublicApi) return;

    var libraryElement = node.element?.exportedLibrary;
    if (libraryElement == null) return;
    if (libraryElement.hasInternal) {
      _errorReporter.atNode(
        node,
        WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
        arguments: [libraryElement.displayName],
      );
    }
    var exportNamespace =
        NamespaceBuilder().createExportNamespaceForDirective(node.element!);
    exportNamespace.definedNames.forEach((String name, Element element) {
      if (element.hasInternal) {
        _errorReporter.atNode(
          node,
          WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
          arguments: [element.displayName],
        );
      } else if (element is FunctionElement) {
        var signatureTypes = [
          ...element.parameters.map((p) => p.type),
          element.returnType,
          ...element.typeParameters.map((tp) => tp.bound),
        ];
        for (var type in signatureTypes) {
          var aliasElement = type?.alias?.element;
          if (aliasElement != null && aliasElement.hasInternal) {
            _errorReporter.atNode(
              node,
              WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY,
              arguments: [aliasElement.name, element.displayName],
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
    var element = node.declaredElement as InterfaceElement;
    // TODO(srawlins): Perhaps replace this with a getter on Element, like
    // `Element.hasOrInheritsSealed`?
    for (InterfaceType supertype in element.allSupertypes) {
      var superclass = supertype.element;
      if (superclass.hasSealed) {
        if (!currentPackageContains(superclass)) {
          if (element is MixinElement &&
              element.superclassConstraints.contains(supertype)) {
            // This is a special violation of the sealed class contract,
            // requiring specific messaging.
            _errorReporter.atNode(
              node,
              WarningCode.MIXIN_ON_SEALED_CLASS,
              arguments: [superclass.name.toString()],
            );
          } else {
            // This is a regular violation of the sealed class contract.
            _errorReporter.atNode(
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
      ErrorCode errorCode,
      SyntacticEntity startEntity,
      SyntacticEntity endEntity,
    ) {
      var offset = startEntity.offset;
      _errorReporter.atOffset(
        offset: offset,
        length: endEntity.end - offset,
        errorCode: errorCode,
      );
    }

    void checkLeftRight(ErrorCode errorCode) {
      if (node.leftOperand.isDoubleNan) {
        reportStartEnd(errorCode, node.leftOperand, node.operator);
      } else if (node.rightOperand.isDoubleNan) {
        reportStartEnd(errorCode, node.operator, node.rightOperand);
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
        _errorReporter.atOffset(
          offset: offset,
          length: node.operator.end - offset,
          errorCode: errorCode,
        );
      }
    }

    if (node.rightOperand is NullLiteral) {
      var leftType = node.leftOperand.typeOrThrow;
      if (_typeSystem.isStrictlyNonNullable(leftType)) {
        var offset = node.operator.offset;
        _errorReporter.atOffset(
          offset: offset,
          length: node.rightOperand.end - offset,
          errorCode: errorCode,
        );
      }
    }
  }

  /// Check that the instance creation node is const if the constructor is
  /// marked with [literal].
  void _checkForLiteralConstructorUse(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    ConstructorElement? constructor = constructorName.staticElement;
    if (constructor == null) {
      return;
    }
    if (!node.isConst && constructor.hasLiteral && node.canBeConst) {
      // Echoing jwren's `TODO` from _checkForDeprecatedMemberUse:
      // TODO(jwren): We should modify ConstructorElement.getDisplayName(), or
      // have the logic centralized elsewhere, instead of doing this logic
      // here.
      String fullConstructorName = constructorName.type.qualifiedName;
      if (constructorName.name != null) {
        fullConstructorName = '$fullConstructorName.${constructorName.name}';
      }
      var warning = node.keyword?.keyword == Keyword.NEW
          ? WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW
          : WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR;
      _errorReporter.atNode(
        node,
        warning,
        arguments: [fullConstructorName],
      );
    }
  }

  /// Check that the imported library does not define a loadLibrary function.
  /// The import has already been determined to be deferred when this is called.
  ///
  /// @param node the import directive to evaluate
  /// @param importElement the [LibraryImportElement] retrieved from the node
  /// @return `true` if and only if an error code is generated on the passed
  ///         node
  /// See [CompileTimeErrorCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION].
  bool _checkForLoadLibraryFunction(
      ImportDirective node, LibraryImportElement importElement) {
    var importedLibrary = importElement.importedLibrary;
    var prefix = importElement.prefix?.element;
    if (importedLibrary == null || prefix == null) {
      return false;
    }
    var importNamespace = importElement.namespace;
    var loadLibraryElement = importNamespace.getPrefixed(
        prefix.name, FunctionElement.LOAD_LIBRARY_NAME);
    if (loadLibraryElement != null) {
      _errorReporter.atNode(
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
    var parameterElement = parameter.declaredElement;
    if (parameterElement == null) {
      return;
    }

    var type = parameterElement.type;
    if (!type.isDartCoreObject && type is! DynamicType) {
      // There is no legal way to define a nullable parameter type, which is not
      // `dynamic` or `Object?`, so avoid double reporting here.
      return;
    }

    if (_typeSystem.isNullable(parameterElement.type)) {
      _errorReporter.atToken(
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
      _errorReporter.atNode(
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
      var parent = expression!.thisOrAncestorMatching(
              (e) => e is FunctionDeclaration || e is MethodDeclaration)
          as Declaration?;
      if (parent == null) {
        return;
      }
      for (var entry in expressionMap.entries) {
        // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
        // named elements, so we can safely assume `entry.value.name` is
        // non-`null`.
        _errorReporter.atNode(
          entry.key,
          WarningCode.RETURN_OF_DO_NOT_STORE,
          arguments: [entry.value.name!, parent.declaredElement!.displayName],
        );
      }
    }
  }

  /// Generates a warning for `noSuchMethod` methods that do nothing except of
  /// calling another `noSuchMethod` which is not defined by `Object`.
  ///
  /// Returns `true` if a warning code is generated for [node].
  bool _checkForUnnecessaryNoSuchMethod(MethodDeclaration node) {
    if (node.name.lexeme != FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
      return false;
    }
    bool isNonObjectNoSuchMethodInvocation(Expression? invocation) {
      if (invocation is MethodInvocation &&
          invocation.target is SuperExpression &&
          invocation.argumentList.arguments.length == 1) {
        SimpleIdentifier name = invocation.methodName;
        if (name.name == FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
          var methodElement = name.staticElement;
          var classElement = methodElement?.enclosingElement3;
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
        _errorReporter.atToken(
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
          _errorReporter.atToken(
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
      FunctionBody body, FunctionExpression node) {
    if (body is ExpressionFunctionBodyImpl) {
      var parameterType = node.staticParameterElement?.type;

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
          _errorReporter.atNode(
            expression,
            WarningCode.UNNECESSARY_SET_LITERAL,
          );
        }
      }
    }
  }

  void _checkRequiredParameter(FormalParameterList node) {
    var requiredParameters =
        node.parameters.where((p) => p.declaredElement?.hasRequired == true);
    var nonNamedParamsWithRequired =
        requiredParameters.where((p) => p.isPositional);
    var namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.isNamed)
        .where((p) => p.declaredElement!.defaultValueCode != null);
    for (var param in nonNamedParamsWithRequired.where((p) => p.isOptional)) {
      _errorReporter.atNode(
        param,
        WarningCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM,
        arguments: [_formalParameterNameOrEmpty(param)],
      );
    }
    for (var param in nonNamedParamsWithRequired.where((p) => p.isRequired)) {
      _errorReporter.atNode(
        param,
        WarningCode.INVALID_REQUIRED_POSITIONAL_PARAM,
        arguments: [_formalParameterNameOrEmpty(param)],
      );
    }
    for (var param in namedParamsWithRequiredAndDefault) {
      _errorReporter.atNode(
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
  void _checkStrictInferenceInParameters(FormalParameterList? parameters,
      {List<ConstructorInitializer>? initializers, FunctionBody? body}) {
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
            parameters!.parameters.map((p) => p.declaredElement!).toSet());
        body?.accept(usedParameterVisitor!);
        for (var initializer in initializers ?? <ConstructorInitializer>[]) {
          initializer.accept(usedParameterVisitor!);
        }
      }

      return usedParameterVisitor!.isUsed(parameter.declaredElement!);
    }

    void checkParameterTypeIsKnown(SimpleFormalParameter parameter) {
      if (parameter.type == null && isParameterReferenced(parameter)) {
        ParameterElement element = parameter.declaredElement!;
        _errorReporter.atNode(
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
      AstNode? returnType, AstNode reportNode, String displayName) {
    if (!_strictInference || returnType != null) {
      return;
    }

    switch (reportNode) {
      case MethodDeclaration():
        _errorReporter.atToken(
          reportNode.name,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
      case FunctionDeclaration():
        _errorReporter.atToken(
          reportNode.name,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
      case _:
        _errorReporter.atNode(
          reportNode,
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          arguments: [displayName],
        );
    }
  }

  /// Return subexpressions that are marked `@doNotStore`, as a map so that
  /// corresponding elements can be used in the diagnostic message.
  Map<Expression, Element> _getSubExpressionsMarkedDoNotStore(
      Expression? expression,
      {Map<Expression, Element>? addTo}) {
    var expressions = addTo ?? <Expression, Element>{};

    Element? element;
    if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
      // Tear-off.
      if (element is FunctionElement || element is MethodElement) {
        element = null;
      }
    } else if (expression is MethodInvocation) {
      element = expression.methodName.staticElement;
    } else if (expression is Identifier) {
      element = expression.staticElement;
      // Tear-off.
      if (element is FunctionElement || element is MethodElement) {
        element = null;
      }
    } else if (expression is ConditionalExpression) {
      _getSubExpressionsMarkedDoNotStore(expression.elseExpression,
          addTo: expressions);
      _getSubExpressionsMarkedDoNotStore(expression.thenExpression,
          addTo: expressions);
    } else if (expression is BinaryExpression) {
      _getSubExpressionsMarkedDoNotStore(expression.leftOperand,
          addTo: expressions);
      _getSubExpressionsMarkedDoNotStore(expression.rightOperand,
          addTo: expressions);
    } else if (expression is FunctionExpression) {
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        _getSubExpressionsMarkedDoNotStore(body.expression, addTo: expressions);
      }
    }
    if (element is PropertyAccessorElement && element.isSynthetic) {
      element = element.variable2;
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
    return _workspacePackage.contains(library.source);
  }

  /// Checks for the passed as expression for the [WarningCode.UNNECESSARY_CAST]
  /// hint code.
  ///
  /// Returns `true` if and only if an unnecessary cast hint should be generated
  /// on [node].  See [WarningCode.UNNECESSARY_CAST].
  static bool isUnnecessaryCast(AsExpression node, TypeSystemImpl typeSystem) {
    var leftType = node.expression.typeOrThrow;
    var rightType = node.type.typeOrThrow;

    // `dynamicValue as SomeType` is a valid use case.
    if (leftType is DynamicType) {
      return false;
    }

    // `cannotResolve is SomeType` is already reported.
    if (leftType is InvalidType) {
      return false;
    }

    // `x as dynamic` is a valid use case.
    if (rightType is DynamicType) {
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

    return true;
  }

  static String _formalParameterNameOrEmpty(FormalParameter node) {
    return node.name?.lexeme ?? '';
  }

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is PropertyAccessorElement && element.isSynthetic) {
      var variable = element.variable2;
      if (variable != null && variable.hasNonVirtual) {
        return true;
      }
    }
    return element.hasNonVirtual;
  }
}

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';

  final ErrorReporter _errorReporter;
  final LibraryElement _library;
  final WorkspacePackage? _workspacePackage;

  final bool _inTemplateSource;
  final bool _inTestDirectory;

  InterfaceElement? _enclosingClass;

  _InvalidAccessVerifier(this._errorReporter, CompilationUnit unit,
      this._library, this._workspacePackage)
      : _inTemplateSource =
            _library.source.fullName.contains(_templateExtension),
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

    var element = grandparent is ConstructorName
        ? grandparent.staticElement
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
    var element = node.staticElement;
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
    var element = node.element?.importedLibrary;
    if (element != null &&
        element.isInternal &&
        !_isLibraryInWorkspacePackage(element.library)) {
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
      element = parent.staticElement;
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
      nameToken: node.name2,
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
    var element = node.staticElement;
    if (element != null &&
        element.isInternal &&
        !_isLibraryInWorkspacePackage(element.library)) {
      _errorReporter.atNode(
        node,
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        arguments: [element.name],
      );
    }
  }

  void _checkForInvalidDoNotSubmitAccess(AstNode node, Element element) {
    if (element is ParameterElement || !_hasDoNotSubmit(element)) {
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
      var element = declaration.declaredElement;
      if (element != null && _hasDoNotSubmit(element)) {
        return;
      }
    }

    var (name, errorEntity) = _getIdentifierNameAndErrorEntity(node, element);
    _errorReporter.atOffset(
      offset: errorEntity.offset,
      length: errorEntity.length,
      errorCode: WarningCode.invalid_use_of_do_not_submit_member,
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
      var element = argument.staticParameterElement;
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
            errorCode: WarningCode.invalid_use_of_do_not_submit_member,
            arguments: [name],
          );
        } else {
          // For positional arguments.
          _errorReporter.atNode(
            argument,
            WarningCode.invalid_use_of_do_not_submit_member,
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
      var definingClass = element.enclosingElement3 as InterfaceElement;
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

    var definingClass = element.enclosingElement3;
    if (definingClass == null) {
      return;
    }

    if (hasProtected) {
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_PROTECTED_MEMBER,
        arguments: [name, definingClass.source!.uri],
      );
    }

    if (isVisibleForTemplateApplied) {
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
        arguments: [name, definingClass.source!.uri],
      );
    }

    if (hasVisibleForTesting) {
      _errorReporter.atEntity(
        errorEntity,
        WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
        arguments: [name, definingClass.source!.uri],
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
    if (element.hasDoNotSubmit) {
      return true;
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable2;
      return variable != null && variable.hasDoNotSubmit;
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
    if (element.hasVisibleForOverriding) {
      return true;
    }

    if (element is PropertyAccessorElement) {
      var variable = element.variable2;
      return variable != null && variable.hasVisibleForOverriding;
    }

    return false;
  }

  bool _hasVisibleForTemplate(Element? element) {
    if (element == null) {
      return false;
    }
    if (element.hasVisibleForTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable2;
      if (variable != null && variable.hasVisibleForTemplate) {
        return true;
      }
    }
    var enclosingElement = element.enclosingElement3;
    if (_hasVisibleForTemplate(enclosingElement)) {
      return true;
    }
    return false;
  }

  bool _hasVisibleOutsideTemplate(Element element) {
    if (element.hasVisibleOutsideTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement) {
      var variable = element.variable2;
      if (variable != null && variable.hasVisibleOutsideTemplate) {
        return true;
      }
    }
    var enclosingElement = element.enclosingElement3;
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
    return _workspacePackage.contains(library.source);
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
        name = node.name2.lexeme;
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
  final Set<ParameterElement> _parameters;

  final Set<ParameterElement> _usedParameters = {};

  _UsedParameterVisitor(this._parameters);

  bool isUsed(ParameterElement parameter) =>
      _usedParameters.contains(parameter);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is ExecutableMember) {
      element = element.declaration;
    }
    if (_parameters.contains(element)) {
      _usedParameters.add(element as ParameterElement);
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

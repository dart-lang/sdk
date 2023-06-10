// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/annotation_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
import 'package:analyzer/src/error/error_handler_verifier.dart';
import 'package:analyzer/src/error/must_call_super_verifier.dart';
import 'package:analyzer/src/error/null_safe_api_verifier.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';

/// Instances of the class `BestPracticesVerifier` traverse an AST structure
/// looking for violations of Dart best practices.
class BestPracticesVerifier extends RecursiveAstVisitor<void> {
  static const String toIntMethodName = "toInt";

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

  /// The type system primitives
  final TypeSystemImpl _typeSystem;

  /// The inheritance manager to access interface type hierarchy.
  final InheritanceManager3 _inheritanceManager;

  /// The current library
  final LibraryElement _currentLibrary;

  final AnnotationVerifier _annotationVerifier;

  final DeprecatedMemberUseVerifier _deprecatedVerifier;

  final ErrorHandlerVerifier _errorHandlerVerifier;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  final MustCallSuperVerifier _mustCallSuperVerifier;

  final NullSafeApiVerifier _nullSafeApiVerifier;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage? _workspacePackage;

  /// The [LinterContext] used for possible const calculations.
  final LinterContext _linterContext;

  /// Is `true` if the library being analyzed is non-nullable by default.
  final bool _isNonNullableByDefault;

  /// True if inference failures should be reported, otherwise false.
  final bool _strictInference;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPackagePublicApi = _workspacePackage != null &&
      _workspacePackage!.sourceIsInPublicApi(_currentLibrary.source);

  BestPracticesVerifier(
    this._errorReporter,
    TypeProviderImpl typeProvider,
    this._currentLibrary,
    CompilationUnit unit,
    String content, {
    required TypeSystemImpl typeSystem,
    required InheritanceManager3 inheritanceManager,
    required DeclaredVariables declaredVariables,
    required AnalysisOptions analysisOptions,
    required WorkspacePackage? workspacePackage,
  })  : _nullType = typeProvider.nullType,
        _typeSystem = typeSystem,
        _isNonNullableByDefault = typeSystem.isNonNullableByDefault,
        _strictInference =
            (analysisOptions as AnalysisOptionsImpl).strictInference,
        _inheritanceManager = inheritanceManager,
        _annotationVerifier = AnnotationVerifier(
            _errorReporter, _currentLibrary, workspacePackage),
        _deprecatedVerifier =
            DeprecatedMemberUseVerifier(workspacePackage, _errorReporter),
        _errorHandlerVerifier =
            ErrorHandlerVerifier(_errorReporter, typeProvider, typeSystem),
        _invalidAccessVerifier = _InvalidAccessVerifier(
            _errorReporter, _currentLibrary, workspacePackage),
        _mustCallSuperVerifier = MustCallSuperVerifier(_errorReporter),
        _nullSafeApiVerifier = NullSafeApiVerifier(_errorReporter, typeSystem),
        _workspacePackage = workspacePackage,
        _linterContext = LinterContextImpl(
          [],
          LinterContextUnit(content, unit),
          declaredVariables,
          typeProvider,
          typeSystem,
          inheritanceManager,
          analysisOptions,
          workspacePackage,
        ) {
    _deprecatedVerifier.pushInDeprecatedValue(_currentLibrary.hasDeprecated);
    _inDoNotStoreMember = _currentLibrary.hasDoNotStore;
    _invalidAccessVerifier._inTestDirectory = _linterContext.inTestDir(unit);
  }

  @override
  void visitAnnotation(Annotation node) {
    _annotationVerifier.checkAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (isUnnecessaryCast(node, _typeSystem)) {
      _errorReporter.reportErrorForNode(WarningCode.UNNECESSARY_CAST, node);
    }
    var type = node.type.type;
    if (_isNonNullableByDefault &&
        type != null &&
        _typeSystem.isNonNullable(type) &&
        node.expression.typeOrThrow.isDartCoreNull) {
      _errorReporter.reportErrorForNode(
          WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, node);
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
    _checkForDivisionOptimizationHint(node);
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
      _errorReporter.reportErrorForNode(
          WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, node);
    }
    super.visitCastPattern(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    _checkForNullableTypeInCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
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
  void visitCommentReference(CommentReference node) {
    var newKeyword = node.newKeyword;
    if (newKeyword != null &&
        _currentLibrary.featureSet.isEnabled(Feature.constructor_tearoffs)) {
      _errorReporter.reportErrorForToken(
          WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, newKeyword, []);
    }
    super.visitCommentReference(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    if (node.expression.isDoubleNan) {
      _errorReporter.reportErrorForNode(
        WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE,
        node,
      );
    }
    super.visitConstantPattern(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredElement as ConstructorElementImpl;
    if (!_isNonNullableByDefault && element.isFactory) {
      if (node.body is BlockFunctionBody) {
        // Check the block for a return statement.
        if (!ExitDetector.exits(node.body)) {
          _errorReporter.reportErrorForNode(
              WarningCode.MISSING_RETURN, node, [node.returnType.name]);
        }
      }
    }
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
        _errorReporter.reportErrorForToken(
            HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE, separator);
      } else {
        _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE, separator);
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
  void visitFieldDeclaration(FieldDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    try {
      super.visitFieldDeclaration(node);
      for (var field in node.fields.variables) {
        ExecutableElement? getOverriddenPropertyAccessor() {
          final element = field.declaredElement;
          if (element is PropertyAccessorElement || element is FieldElement) {
            Name name = Name(_currentLibrary.source.uri, element!.name);
            Element enclosingElement = element.enclosingElement!;
            if (enclosingElement is InterfaceElement) {
              var overridden = _inheritanceManager
                  .getMember2(enclosingElement, name, forSuper: true);
              // Check for a setter.
              if (overridden == null) {
                Name setterName =
                    Name(_currentLibrary.source.uri, '${element.name}=');
                overridden = _inheritanceManager
                    .getMember2(enclosingElement, setterName, forSuper: true);
              }
              return overridden;
            }
          }
          return null;
        }

        final overriddenElement = getOverriddenPropertyAccessor();
        if (overriddenElement != null &&
            _hasNonVirtualAnnotation(overriddenElement)) {
          // Overridden members are always inside classes or mixins, which are
          // always named, so we can safely assume
          // `overriddenElement.enclosingElement3.name` is non-`null`.
          _errorReporter.reportErrorForToken(
              WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, field.name, [
            field.name.lexeme,
            overriddenElement.enclosingElement.displayName
          ]);
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
      _checkForMissingReturn(node.functionExpression.body, node);

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
    if (node.parent is! FunctionDeclaration) {
      _checkForMissingReturn(body, node);
    }
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
    _checkForImportOfLegacyLibraryIntoNullSafe(node);
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
    var enclosingElement = element.enclosingElement;

    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      _checkForMissingReturn(node.body, node);
      _mustCallSuperVerifier.checkMethodDeclaration(node);
      _checkForUnnecessaryNoSuchMethod(node);

      var name = Name(_currentLibrary.source.uri, element.name);
      var elementIsOverride = element is ClassMemberElement &&
              enclosingElement is InterfaceElement
          ? _inheritanceManager.getOverridden2(enclosingElement, name) != null
          : false;

      if (!node.isSetter && !elementIsOverride) {
        _checkStrictInferenceReturnType(
            node.returnType, node, node.name.lexeme);
      }
      if (!elementIsOverride) {
        _checkStrictInferenceInParameters(node.parameters, body: node.body);
      }

      var overriddenElement = enclosingElement is InterfaceElement
          ? _inheritanceManager.getMember2(enclosingElement, name,
              forSuper: true)
          : null;

      if (overriddenElement != null &&
          _hasNonVirtualAnnotation(overriddenElement)) {
        // Overridden members are always inside classes or mixins, which are
        // always named, so we can safely assume
        // `overriddenElement.enclosingElement3.name` is non-`null`.
        _errorReporter.reportErrorForToken(
            WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
            node.name,
            [node.name.lexeme, overriddenElement.enclosingElement.displayName]);
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
    _checkForNullAwareWarnings(node, node.operator);
    _errorHandlerVerifier.verifyMethodInvocation(node);
    _nullSafeApiVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;
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
        _errorReporter.reportErrorForToken(
          WarningCode.UNNECESSARY_QUESTION_MARK,
          question,
          [node.qualifiedName],
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
      _errorReporter.reportErrorForNode(
          WarningCode.NULL_CHECK_ALWAYS_FAILS, node);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _deprecatedVerifier.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkForNullAwareWarnings(node, node.operator);
    super.visitPropertyAccess(node);
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
      _errorReporter.reportErrorForNode(
        node.notOperator == null
            ? WarningCode.UNNECESSARY_TYPE_CHECK_TRUE
            : WarningCode.UNNECESSARY_TYPE_CHECK_FALSE,
        node,
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
        _errorReporter.reportErrorForNode(
          node.notOperator == null
              ? WarningCode.TYPE_CHECK_IS_NULL
              : WarningCode.TYPE_CHECK_IS_NOT_NULL,
          node,
        );
      }
      return true;
    }

    if (_isNonNullableByDefault) {
      if (_typeSystem.isSubtypeOf(leftType, rightType)) {
        report();
        return true;
      }
    } else {
      // In legacy all types are subtypes of `Object`.
      if (rightType.isDartCoreObject) {
        report();
        return true;
      }
    }

    return false;
  }

  void _checkFinalParameter(FormalParameter node, Token? keyword) {
    if (node.isFinal) {
      _errorReporter.reportErrorForToken(
        WarningCode.UNNECESSARY_FINAL,
        keyword!,
      );
    }
  }

  void _checkForAssignmentOfDoNotStore(Expression? expression) {
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    for (var entry in expressionMap.entries) {
      // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
      // named elements, so we can safely assume `entry.value.name` is
      // non-`null`.
      _errorReporter.reportErrorForNode(
        WarningCode.ASSIGNMENT_OF_DO_NOT_STORE,
        entry.key,
        [entry.value.name!],
      );
    }
  }

  /// Check for the passed binary expression for the
  /// [HintCode.DIVISION_OPTIMIZATION].
  ///
  /// @param node the binary expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.DIVISION_OPTIMIZATION].
  bool _checkForDivisionOptimizationHint(BinaryExpression node) {
    // Return if the operator is not '/'
    if (node.operator.type != TokenType.SLASH) {
      return false;
    }
    // Return if the '/' operator is not defined in core, or if we don't know
    // its static type
    var methodElement = node.staticElement;
    if (methodElement == null) {
      return false;
    }
    LibraryElement libraryElement = methodElement.library;
    if (!libraryElement.isDartCore) {
      return false;
    }
    // Report error if the (x/y) has toInt() invoked on it
    var parent = node.parent;
    if (parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesizedExpression =
          _wrapParenthesizedExpression(parent);
      var grandParent = parenthesizedExpression.parent;
      if (grandParent is MethodInvocation) {
        if (toIntMethodName == grandParent.methodName.name &&
            grandParent.argumentList.arguments.isEmpty) {
          _errorReporter.reportErrorForNode(
              HintCode.DIVISION_OPTIMIZATION, grandParent);
          return true;
        }
      }
    }
    return false;
  }

  /// Generate hints related to duplicate elements (keys) in sets (maps).
  void _checkForDuplications(SetOrMapLiteral node) {
    // This only checks for top-level elements. If, for, and spread elements
    // that contribute duplicate values are not detected.
    if (node.isConst) {
      // This case is covered by the ErrorVerifier.
      return;
    }
    final expressions = node.isSet
        ? node.elements.whereType<Expression>()
        : node.elements.whereType<MapLiteralEntry>().map((entry) => entry.key);
    final alreadySeen = <DartObject>{};
    for (final expression in expressions) {
      final constEvaluation = _linterContext.evaluateConstant(expression);
      if (constEvaluation.errors.isEmpty) {
        var value = constEvaluation.value;
        if (value != null && !alreadySeen.add(value)) {
          var errorCode = node.isSet
              ? WarningCode.EQUAL_ELEMENTS_IN_SET
              : WarningCode.EQUAL_KEYS_IN_MAP;
          _errorReporter.reportErrorForNode(errorCode, expression);
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
    /// Return `true` if the given class [element] is annotated with the
    /// `@immutable` annotation.
    bool isImmutable(InterfaceElement element) {
      for (ElementAnnotation annotation in element.metadata) {
        if (annotation.isImmutable) {
          return true;
        }
      }
      return false;
    }

    /// Return `true` if the given class [element] or any superclass of it is
    /// annotated with the `@immutable` annotation.
    bool isOrInheritsImmutable(
        InterfaceElement element, Set<InterfaceElement> visited) {
      if (visited.add(element)) {
        if (isImmutable(element)) {
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
        _errorReporter.reportErrorForToken(WarningCode.MUST_BE_IMMUTABLE,
            node.name, [nonFinalFields.join(', ')]);
      }
    }
  }

  void _checkForImportOfLegacyLibraryIntoNullSafe(ImportDirective node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var importElement = node.element;
    if (importElement == null) {
      return;
    }

    var importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null || importedLibrary.isNonNullableByDefault) {
      return;
    }

    _errorReporter.reportErrorForNode(
      HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE,
      node.uri,
      [importedLibrary.source.uri],
    );
  }

  /// Check that the namespace exported by [node] does not include any elements
  /// annotated with `@internal`.
  void _checkForInternalExport(ExportDirective node) {
    if (!_inPackagePublicApi) return;

    var libraryElement = node.element?.exportedLibrary;
    if (libraryElement == null) return;
    if (libraryElement.hasInternal) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
          node,
          [libraryElement.displayName]);
    }
    var exportNamespace =
        NamespaceBuilder().createExportNamespaceForDirective(node.element!);
    exportNamespace.definedNames.forEach((String name, Element element) {
      if (element.hasInternal) {
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
            node,
            [element.displayName]);
      } else if (element is FunctionElement) {
        var signatureTypes = [
          ...element.parameters.map((p) => p.type),
          element.returnType,
          ...element.typeParameters.map((tp) => tp.bound),
        ];
        for (var type in signatureTypes) {
          var aliasElement = type?.alias?.element;
          if (aliasElement != null && aliasElement.hasInternal) {
            _errorReporter.reportErrorForNode(
                WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY,
                node,
                [aliasElement.name, element.displayName]);
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
      final superclass = supertype.element;
      if (superclass.hasSealed) {
        if (!currentPackageContains(superclass)) {
          if (element is MixinElement &&
              element.superclassConstraints.contains(supertype)) {
            // This is a special violation of the sealed class contract,
            // requiring specific messaging.
            _errorReporter.reportErrorForNode(WarningCode.MIXIN_ON_SEALED_CLASS,
                node, [superclass.name.toString()]);
          } else {
            // This is a regular violation of the sealed class contract.
            _errorReporter.reportErrorForNode(
                WarningCode.SUBTYPE_OF_SEALED_CLASS,
                node,
                [superclass.name.toString()]);
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
      _errorReporter.reportErrorForOffset(
        errorCode,
        offset,
        endEntity.end - offset,
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
    if (!_isNonNullableByDefault) return;

    void reportStartEnd(
      ErrorCode errorCode,
      SyntacticEntity startEntity,
      SyntacticEntity endEntity,
    ) {
      var offset = startEntity.offset;
      _errorReporter.reportErrorForOffset(
        errorCode,
        offset,
        endEntity.end - offset,
      );
    }

    void checkLeftRight(ErrorCode errorCode) {
      if (node.leftOperand is NullLiteral) {
        var rightType = node.rightOperand.typeOrThrow;
        if (_typeSystem.isStrictlyNonNullable(rightType)) {
          reportStartEnd(errorCode, node.leftOperand, node.operator);
        }
      }

      if (node.rightOperand is NullLiteral) {
        var leftType = node.leftOperand.typeOrThrow;
        if (_typeSystem.isStrictlyNonNullable(leftType)) {
          reportStartEnd(errorCode, node.operator, node.rightOperand);
        }
      }
    }

    if (node.operator.type == TokenType.BANG_EQ) {
      checkLeftRight(WarningCode.UNNECESSARY_NULL_COMPARISON_TRUE);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      checkLeftRight(WarningCode.UNNECESSARY_NULL_COMPARISON_FALSE);
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
    if (!node.isConst &&
        constructor.hasLiteral &&
        _linterContext.canBeConst(node)) {
      // Echoing jwren's TODO from _checkForDeprecatedMemberUse:
      // TODO(jwren) We should modify ConstructorElement.getDisplayName(), or
      // have the logic centralized elsewhere, instead of doing this logic
      // here.
      String fullConstructorName = constructorName.type.qualifiedName;
      if (constructorName.name != null) {
        fullConstructorName = '$fullConstructorName.${constructorName.name}';
      }
      var warning = node.keyword?.keyword == Keyword.NEW
          ? WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW
          : WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR;
      _errorReporter.reportErrorForNode(warning, node, [fullConstructorName]);
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
      _errorReporter.reportErrorForNode(
          HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION, node);
      return true;
    }
    return false;
  }

  /// Generates a warning for functions that have a potentially non-nullable
  /// return type, but do not have a return statement on all branches. At the
  /// end of blocks with no return, Dart implicitly returns `null`. Avoiding
  /// these implicit returns is considered a best practice.
  ///
  /// See [WarningCode.MISSING_RETURN].
  void _checkForMissingReturn(FunctionBody body, AstNode functionNode) {
    if (_isNonNullableByDefault) {
      return;
    }

    // Generators always return.
    if (body.isGenerator) {
      return;
    }

    if (body is! BlockFunctionBody) {
      return;
    }

    var bodyContext = BodyInferenceContext.of(body)!;
    // TODO(scheglov) Update InferenceContext to record any type, dynamic.
    var returnType = bodyContext.contextType ?? DynamicTypeImpl.instance;

    if (_typeSystem.isNullable(returnType)) {
      return;
    }

    if (ExitDetector.exits(body)) {
      return;
    }

    if (functionNode is FunctionDeclaration) {
      _errorReporter.reportErrorForToken(
        WarningCode.MISSING_RETURN,
        functionNode.name,
        [returnType],
      );
    } else if (functionNode is MethodDeclaration) {
      _errorReporter.reportErrorForToken(
        WarningCode.MISSING_RETURN,
        functionNode.name,
        [returnType],
      );
    } else {
      _errorReporter.reportErrorForNode(
        WarningCode.MISSING_RETURN,
        functionNode,
        [returnType],
      );
    }
  }

  void _checkForNullableTypeInCatchClause(CatchClause node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var type = node.exceptionType;
    if (type == null) {
      return;
    }

    if (_typeSystem.isPotentiallyNullable(type.typeOrThrow)) {
      _errorReporter.reportErrorForNode(
        WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE,
        type,
      );
    }
  }

  /// Produce several null-aware related warnings.
  void _checkForNullAwareWarnings(Expression node, Token? operator) {
    if (_isNonNullableByDefault) {
      return;
    }

    if (operator == null || operator.type != TokenType.QUESTION_PERIOD) {
      return;
    }

    // childOfParent is used to know from which branch node comes.
    var childOfParent = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      childOfParent = parent;
      parent = parent.parent;
    }

    // CAN_BE_NULL_AFTER_NULL_AWARE
    if (parent is MethodInvocation &&
        !parent.isNullAware &&
        _nullType.lookUpMethod2(parent.methodName.name, _currentLibrary) ==
            null) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }
    if (parent is PropertyAccess &&
        !parent.isNullAware &&
        _nullType.lookUpGetter2(parent.propertyName.name, _currentLibrary) ==
            null) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }
    if (parent is CascadeExpression && parent.target == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }

    // NULL_AWARE_IN_CONDITION
    if (parent is IfStatement && parent.expression == childOfParent ||
        parent is ForPartsWithDeclarations &&
            parent.condition == childOfParent ||
        parent is DoStatement && parent.condition == childOfParent ||
        parent is WhileStatement && parent.condition == childOfParent ||
        parent is ConditionalExpression && parent.condition == childOfParent ||
        parent is AssertStatement && parent.condition == childOfParent) {
      _errorReporter.reportErrorForNode(
          WarningCode.NULL_AWARE_IN_CONDITION, childOfParent);
      return;
    }

    // NULL_AWARE_IN_LOGICAL_OPERATOR
    if (parent is PrefixExpression && parent.operator.type == TokenType.BANG ||
        parent is BinaryExpression &&
            [TokenType.BAR_BAR, TokenType.AMPERSAND_AMPERSAND]
                .contains(parent.operator.type)) {
      _errorReporter.reportErrorForNode(
          WarningCode.NULL_AWARE_IN_LOGICAL_OPERATOR, childOfParent);
      return;
    }

    // NULL_AWARE_BEFORE_OPERATOR
    if (parent is BinaryExpression &&
        ![TokenType.EQ_EQ, TokenType.BANG_EQ, TokenType.QUESTION_QUESTION]
            .contains(parent.operator.type) &&
        parent.leftOperand == childOfParent) {
      _errorReporter.reportErrorForNode(
          WarningCode.NULL_AWARE_BEFORE_OPERATOR, childOfParent);
      return;
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
        _errorReporter.reportErrorForNode(
          WarningCode.RETURN_OF_DO_NOT_STORE,
          entry.key,
          [entry.value.name!, parent.declaredElement!.displayName],
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
        _errorReporter.reportErrorForToken(
            WarningCode.UNNECESSARY_NO_SUCH_METHOD, node.name);
        return true;
      }
    } else if (body is BlockFunctionBody) {
      List<Statement> statements = body.block.statements;
      if (statements.length == 1) {
        Statement returnStatement = statements.first;
        if (returnStatement is ReturnStatement &&
            isNonObjectNoSuchMethodInvocation(returnStatement.expression)) {
          _errorReporter.reportErrorForToken(
              WarningCode.UNNECESSARY_NO_SUCH_METHOD, node.name);
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
          var elements = expression.elements;
          if (elements.length == 1 && elements.first is Expression) {
            _errorReporter.reportErrorForNode(
                WarningCode.UNNECESSARY_SET_LITERAL, expression);
          }
        }
      }
    }
  }

  void _checkRequiredParameter(FormalParameterList node) {
    final requiredParameters =
        node.parameters.where((p) => p.declaredElement?.hasRequired == true);
    final nonNamedParamsWithRequired =
        requiredParameters.where((p) => p.isPositional);
    final namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.isNamed)
        .where((p) => p.declaredElement!.defaultValueCode != null);
    for (final param in nonNamedParamsWithRequired.where((p) => p.isOptional)) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM,
          param,
          [_formalParameterNameOrEmpty(param)]);
    }
    for (final param in nonNamedParamsWithRequired.where((p) => p.isRequired)) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_REQUIRED_POSITIONAL_PARAM,
          param,
          [_formalParameterNameOrEmpty(param)]);
    }
    for (final param in namedParamsWithRequiredAndDefault) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_REQUIRED_NAMED_PARAM,
          param,
          [_formalParameterNameOrEmpty(param)]);
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
        _errorReporter.reportErrorForNode(
          WarningCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER,
          parameter,
          [element.displayName],
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
    if (!_strictInference) {
      return;
    }
    if (returnType == null) {
      _errorReporter.reportErrorForNode(
          WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          reportNode,
          [displayName]);
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
    return _workspacePackage!.contains(library.source);
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
    if (!typeSystem.isSubtypeOf(leftType, rightType)) {
      return false;
    }

    // Casting from `T*` to `T?` is a way to force `T?`.
    if (leftType.nullabilitySuffix == NullabilitySuffix.star &&
        rightType.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }

    // For `condition ? then : else` the result type is `LUB`.
    // Casts might be used to consider only a portion of the inheritance tree.
    var parent = node.parent;
    if (parent is ConditionalExpression) {
      var other = node == parent.thenExpression
          ? parent.elseExpression
          : parent.thenExpression;

      var currentType = typeSystem.leastUpperBound(
        node.typeOrThrow,
        other.typeOrThrow,
      );

      var typeWithoutCast = typeSystem.leastUpperBound(
        node.expression.typeOrThrow,
        other.typeOrThrow,
      );

      if (typeWithoutCast != currentType) {
        return false;
      }
    }

    return true;
  }

  static String _formalParameterNameOrEmpty(FormalParameter node) {
    return node.name?.lexeme ?? '';
  }

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is PropertyAccessorElement && element.isSynthetic) {
      return element.variable.hasNonVirtual;
    }
    return element.hasNonVirtual;
  }

  /// Given a parenthesized expression, this returns the parent (or recursively
  /// grand-parent) of the expression that is a parenthesized expression, but
  /// whose parent is not a parenthesized expression.
  ///
  /// For example given the code `(((e)))`: `(e) -> (((e)))`.
  ///
  /// @param parenthesizedExpression some expression whose parent is a
  ///        parenthesized expression
  /// @return the first parent or grand-parent that is a parenthesized
  ///         expression, that does not have a parenthesized expression parent
  static ParenthesizedExpression _wrapParenthesizedExpression(
      ParenthesizedExpression parenthesizedExpression) {
    var parent = parenthesizedExpression.parent;
    if (parent is ParenthesizedExpression) {
      return _wrapParenthesizedExpression(parent);
    }
    return parenthesizedExpression;
  }
}

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';

  final ErrorReporter _errorReporter;
  final LibraryElement _library;
  final WorkspacePackage? _workspacePackage;

  final bool _inTemplateSource;
  late final bool _inTestDirectory;

  InterfaceElement? _enclosingClass;

  _InvalidAccessVerifier(
      this._errorReporter, this._library, this._workspacePackage)
      : _inTemplateSource =
            _library.source.fullName.contains(_templateExtension);

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

    if (element == null || _inCurrentLibrary(element)) {
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

      _errorReporter.reportErrorForToken(
          WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER,
          operator,
          [operator.type.lexeme]);
    }
  }

  void verifyImport(ImportDirective node) {
    var element = node.element?.importedLibrary;
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element!.library)) {
      // The only way for an import directive's URI to have a `null`
      // `stringValue` is if its string contains an interpolation, in which case
      // the element would never have resolved in the first place.  So we can
      // safely assume `node.uri.stringValue` is non-`null`.
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
          node,
          [node.uri.stringValue!]);
    }
  }

  void verifyNamedType(NamedType node) {
    var element = node.element;

    final parent = node.parent;
    if (parent is ConstructorName) {
      element = parent.staticElement;
    }

    if (element == null || _inCurrentLibrary(element)) {
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
    if (element == null || _inCurrentLibrary(element)) {
      return;
    }

    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element.library)) {
      var fieldName = node.name;
      if (fieldName == null) {
        return;
      }
      var errorEntity = node.errorEntity;

      _errorReporter.reportErrorForOffset(
          WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
          errorEntity.offset,
          errorEntity.length,
          [element.displayName]);
    }

    _checkForOtherInvalidAccess(node, element);
  }

  void verifySuperConstructorInvocation(SuperConstructorInvocation node) {
    if (node.constructorName != null) {
      // Named constructor calls are handled by [verify].
      return;
    }
    var element = node.staticElement;
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element!.library)) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_USE_OF_INTERNAL_MEMBER, node, [element.name]);
    }
  }

  void _checkForInvalidInternalAccess({
    required AstNode? parent,
    required Token nameToken,
    required Element element,
  }) {
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element.library)) {
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

      _errorReporter.reportErrorForOffset(
        WarningCode.INVALID_USE_OF_INTERNAL_MEMBER,
        node.offset,
        node.length,
        [name],
      );
    }
  }

  void _checkForOtherInvalidAccess(AstNode node, Element element) {
    bool hasProtected = _hasProtected(element);
    if (hasProtected) {
      var definingClass = element.enclosingElement as InterfaceElement;
      if (_hasTypeOrSuperType(_enclosingClass, definingClass)) {
        return;
      }
    }

    bool isVisibleForTemplateApplied = _isVisibleForTemplateApplied(element);
    if (isVisibleForTemplateApplied) {
      if (_inTemplateSource || _inExportDirective(node)) {
        return;
      }
    }

    bool hasVisibleForTesting = _hasVisibleForTesting(element);
    if (hasVisibleForTesting) {
      if (_inTestDirectory || _inExportDirective(node)) {
        return;
      }
    }

    bool hasVisibleForOverriding = _hasVisibleForOverriding(element);

    // At this point, [identifier] was not cleared as protected access, nor
    // cleared as access for templates or testing. Report a violation for each
    // annotation present.

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
      throw StateError('Can only handle Identifier or PatternField, but got '
          '${node.runtimeType}');
    }

    var definingClass = element.enclosingElement;
    if (definingClass == null) {
      return;
    }
    if (hasProtected) {
      _errorReporter.reportErrorForOffset(
          WarningCode.INVALID_USE_OF_PROTECTED_MEMBER,
          errorEntity.offset,
          errorEntity.length,
          [name, definingClass.source!.uri]);
    }
    if (isVisibleForTemplateApplied) {
      _errorReporter.reportErrorForOffset(
          WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
          errorEntity.offset,
          errorEntity.length,
          [name, definingClass.source!.uri]);
    }

    if (hasVisibleForTesting) {
      _errorReporter.reportErrorForOffset(
          WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
          errorEntity.offset,
          errorEntity.length,
          [name, definingClass.source!.uri]);
    }

    if (hasVisibleForOverriding) {
      var parent = node.parent;
      var validOverride = false;
      if (parent is MethodInvocation && parent.target is SuperExpression ||
          parent is PropertyAccess && parent.target is SuperExpression) {
        var methodDeclaration =
            grandparent?.thisOrAncestorOfType<MethodDeclaration>();
        if (methodDeclaration?.name.lexeme == name) {
          validOverride = true;
        }
      }
      if (!validOverride) {
        _errorReporter.reportErrorForOffset(
            WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER,
            errorEntity.offset,
            errorEntity.length,
            [name]);
      }
    }
  }

  bool _hasInternal(Element? element) {
    if (element == null) {
      return false;
    }
    if (element.hasInternal) {
      return true;
    }
    if (element is PropertyAccessorElement && element.variable.hasInternal) {
      return true;
    }
    return false;
  }

  bool _hasProtected(Element element) {
    if (element is PropertyAccessorElement &&
        element.enclosingElement is InterfaceElement &&
        (element.hasProtected || element.variable.hasProtected)) {
      return true;
    }
    if (element is MethodElement &&
        element.enclosingElement is InterfaceElement &&
        element.hasProtected) {
      return true;
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

    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForOverriding) {
      return true;
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
    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForTemplate) {
      return true;
    }
    final enclosingElement = element.enclosingElement;
    if (_hasVisibleForTemplate(enclosingElement)) {
      return true;
    }
    return false;
  }

  bool _hasVisibleForTesting(Element element) {
    if (element.hasVisibleForTesting) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForTesting) {
      return true;
    }
    return false;
  }

  bool _hasVisibleOutsideTemplate(Element element) {
    if (element.hasVisibleOutsideTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleOutsideTemplate) {
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
    return _workspacePackage!.contains(library.source);
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
    final self = this;
    return self is PrefixedIdentifier &&
        self.prefix.name == 'double' &&
        self.identifier.name == 'nan';
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart'
    show SubstitutedExecutableElementImpl;
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/annotation_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/deprecated_functionality_verifier.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
import 'package:analyzer/src/error/do_not_submit_member_use_verifier.dart';
import 'package:analyzer/src/error/doc_comment_verifier.dart';
import 'package:analyzer/src/error/element_usage_detector.dart';
import 'package:analyzer/src/error/element_usage_frontier_detector.dart';
import 'package:analyzer/src/error/error_handler_verifier.dart';
import 'package:analyzer/src/error/experimental_member_use_verifier.dart';
import 'package:analyzer/src/error/immutable_verifier.dart';
import 'package:analyzer/src/error/listener.dart';
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

  /// The diagnostic reporter by which diagnostics will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// The type [Null].
  final InterfaceType _nullType;

  /// The type system primitives.
  final TypeSystemImpl _typeSystem;

  /// The current library.
  final LibraryElementImpl _currentLibrary;

  final AnnotationVerifier _annotationVerifier;

  final DeprecatedFunctionalityVerifier _deprecatedFunctionalityVerifier;

  final ElementUsageFrontierDetector _elementUsageFrontierDetector;

  final ErrorHandlerVerifier _errorHandlerVerifier;

  late final ImmutableVerifier _immutableVerifier = ImmutableVerifier(
    _diagnosticReporter,
  );

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
       _deprecatedFunctionalityVerifier = DeprecatedFunctionalityVerifier(
         _diagnosticReporter,
         _currentLibrary,
       ),
       _elementUsageFrontierDetector = ElementUsageFrontierDetector(
         workspacePackage: workspacePackage,
         usagesAndReporters: [
           UsageSetAndReporter(
             const DeprecatedElementUsageSet(),
             DeprecatedElementUsageReporter(
               diagnosticReporter: _diagnosticReporter,
             ),
           ),
           UsageSetAndReporter(
             const ExperimentalElementUsageSet(),
             ExperimentalElementUsageReporter(
               diagnosticReporter: _diagnosticReporter,
             ),
           ),
           UsageSetAndReporter(
             const DoNotSubmitElementUsageSet(),
             DoNotSubmitElementUsageReporter(
               diagnosticReporter: _diagnosticReporter,
             ),
           ),
         ],
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
    _elementUsageFrontierDetector.pushElement(_currentLibrary);
    _inDoNotStoreMember = _currentLibrary.metadata.hasDoNotStore;
  }

  @override
  void visitAnnotation(Annotation node) {
    _annotationVerifier.checkAnnotation(node);
    _widgetPreviewVerifier.checkAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (_isUnnecessaryCast(node, _typeSystem)) {
      _diagnosticReporter.report(diag.unnecessaryCast.at(node));
    }
    var type = node.type.type;
    if (type != null &&
        _typeSystem.isNonNullable(type) &&
        node.expression.typeOrThrow.isDartCoreNull) {
      _diagnosticReporter.report(diag.castFromNullAlwaysFails.at(node));
    }
    super.visitAsExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _elementUsageFrontierDetector.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _elementUsageFrontierDetector.binaryExpression(node);
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
      _diagnosticReporter.report(diag.castFromNullAlwaysFails.at(node));
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
    _deprecatedFunctionalityVerifier.classDeclaration(node);
    _elementUsageFrontierDetector.pushElement(element);
    if (element.metadata.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }

    try {
      _immutableVerifier.checkDeclaration(
        node,
        nameToken: node.namePart.typeName,
      );
      _checkForInvalidSealedSuperclass(node);
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _elementUsageFrontierDetector.popElement();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _immutableVerifier.checkDeclaration(node, nameToken: node.name);
    _checkForInvalidSealedSuperclass(node);
    _deprecatedFunctionalityVerifier.classTypeAlias(node);
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);

    try {
      super.visitClassTypeAlias(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
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
      _diagnosticReporter.report(
        diag.deprecatedNewInCommentReference.at(newKeyword),
      );
    }
    super.visitCommentReference(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    if (node.expression.isDoubleNan) {
      _diagnosticReporter.report(diag.unnecessaryNanComparisonFalse.at(node));
    }
    super.visitConstantPattern(node);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclaration node) {
    _checkStrictInferenceInParameters(
      node.parameters,
      body: node.body,
      initializers: node.initializers,
    );
    var element = node.declaredFragment!.element;
    _elementUsageFrontierDetector.pushElement(element);
    _elementUsageFrontierDetector.constructorDeclaration(node);

    _deprecatedFunctionalityVerifier.constructorDeclaration(node);

    try {
      super.visitConstructorDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _elementUsageFrontierDetector.constructorName(node);
    _deprecatedFunctionalityVerifier.constructorName(node);
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
        _diagnosticReporter.report(
          diag.deprecatedColonForDefaultValue.at(separator),
        );
      } else {
        _diagnosticReporter.report(
          diag.obsoleteColonForDefaultValue.at(separator),
        );
      }
    }
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);
    _elementUsageFrontierDetector.formalParameter(node);

    try {
      super.visitDefaultFormalParameter(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _deprecatedFunctionalityVerifier.dotShorthandConstructorInvocation(node);
    _elementUsageFrontierDetector.dotShorthandConstructorInvocation(node);
    _checkForLiteralConstructorUseInDotShorthand(node);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _deprecatedFunctionalityVerifier.dotShorthandInvocation(node);
    _elementUsageFrontierDetector.dotShorthandInvocation(node);
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    _elementUsageFrontierDetector.dotShorthandPropertyAccess(node);
    super.visitDotShorthandPropertyAccess(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);
    _deprecatedFunctionalityVerifier.enumDeclaration(node);

    try {
      super.visitEnumDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    _elementUsageFrontierDetector.exportDirective(node);
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
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);

    try {
      super.visitExtensionDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _elementUsageFrontierDetector.extensionOverride(node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);

    try {
      super.visitExtensionTypeDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _elementUsageFrontierDetector.pushElement(node.firstVariableElement);

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
          var nameObj = Name(_currentLibrary.uri, name);
          overriddenElement =
              enclosingElement.getInheritedConcreteMember(nameObj) ??
              enclosingElement.getInheritedConcreteMember(nameObj.forSetter);
        }

        if (overriddenElement != null &&
            _hasNonVirtualAnnotation(overriddenElement)) {
          // Overridden members are always inside classes or mixins, which are
          // always named, so we can safely assume
          // `overriddenElement.enclosingElement3.name` is non-`null`.
          _diagnosticReporter.report(
            diag.invalidOverrideOfNonVirtualMember
                .withArguments(
                  memberName: field.name.lexeme,
                  definingClass:
                      overriddenElement.enclosingElement!.displayName,
                )
                .at(field.name),
          );
        }
      }
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkFinalParameter(node, node.keyword);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    var element = node.declaredFragment!.element;
    _elementUsageFrontierDetector.pushElement(element);
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
      _elementUsageFrontierDetector.popElement();
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
    _elementUsageFrontierDetector.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkStrictInferenceReturnType(node.returnType, node, node.name.lexeme);
    _checkStrictInferenceInParameters(node.parameters);
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);

    try {
      super.visitFunctionTypeAlias(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
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
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);

    try {
      super.visitGenericTypeAlias(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _elementUsageFrontierDetector.importDirective(node);
    var import = node.libraryImport;
    if (import != null && import.prefix?.isDeferred == true) {
      _checkForLoadLibraryFunction(node, import);
    }
    _invalidAccessVerifier.verifyImport(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _elementUsageFrontierDetector.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    _elementUsageFrontierDetector.instanceCreationExpression(node);
    _deprecatedFunctionalityVerifier.instanceCreationExpression(node);
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
    var nameToken = node.name;
    var element = node.declaredFragment!.element;
    var enclosingElement = element.enclosingElement;

    _elementUsageFrontierDetector.pushElement(element);
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
          nameToken.lexeme,
        );
      }
      if (!elementIsOverride) {
        _checkStrictInferenceInParameters(node.parameters, body: node.body);
      }

      var overriddenElement = enclosingElement is InterfaceElement
          ? enclosingElement.getInheritedConcreteMember(name)
          : null;

      if (overriddenElement != null &&
          _hasNonVirtualAnnotation(overriddenElement)) {
        // Overridden members are always inside classes or mixins, which are
        // always named, so we can safely assume
        // `overriddenElement.enclosingElement3.name` is non-`null`.
        _diagnosticReporter.report(
          diag.invalidOverrideOfNonVirtualMember
              .withArguments(
                memberName: nameToken.lexeme,
                definingClass: overriddenElement.enclosingElement!.displayName,
              )
              .at(nameToken),
        );
      }

      // Returns `true` if the first tokens of the method are any of:
      // - factory
      // - external factory
      // - augment factory
      // - augment external factory
      bool isAmbiguousFactoryMethod() {
        if (nameToken.lexeme != Keyword.FACTORY.lexeme) return false;
        var firstToken = node.firstTokenAfterCommentAndMetadata;
        if (firstToken == nameToken) return true;
        var secondToken = firstToken.next!;
        if (firstToken.lexeme == Keyword.EXTERNAL.lexeme) {
          return secondToken == nameToken;
        }
        if (_currentLibrary.featureSet.isEnabled(Feature.augmentations) &&
            firstToken.lexeme == Keyword.AUGMENT.lexeme) {
          return secondToken == nameToken ||
              (secondToken.lexeme == Keyword.EXTERNAL.lexeme &&
                  secondToken.next == nameToken);
        }
        return false;
      }

      if (!_currentLibrary.featureSet.isEnabled(Feature.primary_constructors) &&
          isAmbiguousFactoryMethod()) {
        _diagnosticReporter.report(diag.deprecatedFactoryMethod.at(nameToken));
      }

      super.visitMethodDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
    _elementUsageFrontierDetector.methodInvocation(node);
    _deprecatedFunctionalityVerifier.methodInvocation(node);
    _errorHandlerVerifier.verifyMethodInvocation(node);
    _nullSafeApiVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = _enclosingClass;

    _deprecatedFunctionalityVerifier.mixinDeclaration(node);
    _elementUsageFrontierDetector.pushElement(element);

    try {
      _immutableVerifier.checkDeclaration(node, nameToken: node.name);
      _checkForInvalidSealedSuperclass(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _elementUsageFrontierDetector.namedType(node);
    _invalidAccessVerifier.verifyNamedType(node);
    var question = node.question;
    if (question != null) {
      var type = node.typeOrThrow;
      // Only report non-aliased, non-user-defined `Null?` and `dynamic?`. Do
      // not report synthetic `dynamic` in place of an unresolved type.
      if ((type is InterfaceType && type.element == _nullType.element ||
              (type is DynamicType && node.name.lexeme == 'dynamic')) &&
          type.alias == null) {
        _diagnosticReporter.report(
          diag.unnecessaryQuestionMark
              .withArguments(typeName: node.qualifiedName)
              .at(question),
        );
      }
    }
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _elementUsageFrontierDetector.patternField(node);
    _invalidAccessVerifier.verifyPatternField(node as PatternFieldImpl);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _elementUsageFrontierDetector.postfixExpression(node);
    if (node.operator.type == TokenType.BANG &&
        node.operand.typeOrThrow.isDartCoreNull) {
      _diagnosticReporter.report(diag.nullCheckAlwaysFails.at(node));
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _elementUsageFrontierDetector.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    var element = node.declaration?.declaredFragment!.element;
    _elementUsageFrontierDetector.pushElement(element);
    // TODO(srawlins): Account for @doNotStore, as in `visitFunctionDeclaration`.
    super.visitPrimaryConstructorBody(node);
    _elementUsageFrontierDetector.popElement();
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    _checkStrictInferenceInParameters(node.formalParameters);
    _deprecatedFunctionalityVerifier.primaryConstructorDeclaration(node);
    super.visitPrimaryConstructorDeclaration(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _elementUsageFrontierDetector.redirectingConstructorInvocation(node);
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
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _elementUsageFrontierDetector.pushElement(node.declaredFragment!.element);
    _elementUsageFrontierDetector.formalParameter(node);

    try {
      super.visitSimpleFormalParameter(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _elementUsageFrontierDetector.simpleIdentifier(node);
    _invalidAccessVerifier.verify(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _elementUsageFrontierDetector.superConstructorInvocation(node);
    _invalidAccessVerifier.verifySuperConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _elementUsageFrontierDetector.superFormalParameter(node);
    _checkFinalParameter(node, node.keyword);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _elementUsageFrontierDetector.pushElement(node.firstVariableElement);

    if (!_invalidAccessVerifier._inTestDirectory) {
      for (var decl in node.variables.variables) {
        _checkForAssignmentOfDoNotStore(decl.initializer);
      }
    }

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _elementUsageFrontierDetector.popElement();
    }
  }

  /// Checks for the passed [IsExpression] for the unnecessary type check
  /// warning codes as well as null checks expressed using an
  /// [IsExpression].
  ///
  /// Returns `true` if a warning code is generated on [node].
  /// See [diag.typeCheckIsNotNull],
  /// [diag.typeCheckIsNull],
  /// [diag.unnecessaryTypeCheckTrue], and
  /// [diag.unnecessaryTypeCheckFalse].
  bool _checkAllTypeChecks(IsExpressionImpl node) {
    var leftNode = node.expression;
    var leftType = leftNode.typeOrThrow;

    var rightNode = node.type;
    var rightType = rightNode.typeOrThrow;

    void report() {
      _diagnosticReporter.report(
        (node.notOperator == null
                ? diag.unnecessaryTypeCheckTrue
                : diag.unnecessaryTypeCheckFalse)
            .at(node),
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
        _diagnosticReporter.report(
          (node.notOperator == null
                  ? diag.typeCheckIsNull
                  : diag.typeCheckIsNotNull)
              .at(node),
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
      _diagnosticReporter.report(diag.unnecessaryFinal.at(keyword!));
    }
  }

  void _checkForAssignmentOfDoNotStore(Expression? expression) {
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    for (var entry in expressionMap.entries) {
      // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
      // named elements, so we can safely assume `entry.value.name` is
      // non-`null`.
      _diagnosticReporter.report(
        diag.assignmentOfDoNotStore
            .withArguments(name: entry.value.name!)
            .at(entry.key),
      );
    }
  }

  /// Generates hints related to duplicate elements (keys) in sets (maps).
  void _checkForDuplications(SetOrMapLiteral node) {
    // This only checks for top-level elements. If, for, and spread elements
    // that contribute duplicate values are not detected.
    if (node.isConst) {
      // This case is covered by the DiagnosticVerifier.
      return;
    }
    var expressions = node.isSet
        ? node.elements.whereType<Expression>()
        : node.elements.whereType<MapLiteralEntry>().map((entry) => entry.key);
    var alreadySeen = <DartObject>{};
    for (var expression in expressions) {
      var constEvaluation = expression.computeConstantValue();
      if (constEvaluation != null && constEvaluation.diagnostics.isEmpty) {
        var value = constEvaluation.value;
        if (value != null && !alreadySeen.add(value)) {
          var diagnosticCode = node.isSet
              ? diag.equalElementsInSet
              : diag.equalKeysInMap;
          _diagnosticReporter.report(diagnosticCode.at(expression));
        }
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
      _diagnosticReporter.report(
        diag.invalidExportOfInternalElement
            .withArguments(name: libraryElement.displayName)
            .at(node),
      );
    }
    var exportNamespace = NamespaceBuilder().createExportNamespaceForDirective2(
      libraryExport,
    );
    exportNamespace.definedNames2.forEach((String name, Element element) {
      if (element.metadata.hasInternal) {
        _diagnosticReporter.report(
          diag.invalidExportOfInternalElement
              .withArguments(name: element.displayName)
              .at(node),
        );
        return;
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
            _diagnosticReporter.report(
              diag.invalidExportOfInternalElementIndirectly
                  .withArguments(
                    internalElementName: aliasElement.name!,
                    exportedElementName: element.displayName,
                  )
                  .at(node),
            );
          }
        }
      }
    });
  }

  void _checkForInvalidSealedSuperclass(CompilationUnitMember node) {
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
            _diagnosticReporter.report(
              diag.mixinOnSealedClass
                  .withArguments(name: superclass.name.toString())
                  .at(node),
            );
          } else {
            // This is a regular violation of the sealed class contract.
            _diagnosticReporter.report(
              diag.subtypeOfSealedClass
                  .withArguments(name: superclass.name.toString())
                  .at(node),
            );
          }
        }
      }
    }
  }

  void _checkForInvariantNanComparison(BinaryExpression node) {
    void reportStartEnd(
      LocatableDiagnostic locatableDiagnostic,
      SyntacticEntity startEntity,
      SyntacticEntity endEntity,
    ) {
      var offset = startEntity.offset;
      _diagnosticReporter.report(
        locatableDiagnostic.atOffset(
          offset: offset,
          length: endEntity.end - offset,
        ),
      );
    }

    void checkLeftRight(LocatableDiagnostic locatableDiagnostic) {
      if (node.leftOperand.isDoubleNan) {
        reportStartEnd(locatableDiagnostic, node.leftOperand, node.operator);
      } else if (node.rightOperand.isDoubleNan) {
        reportStartEnd(locatableDiagnostic, node.operator, node.rightOperand);
      }
    }

    if (node.operator.type == TokenType.BANG_EQ) {
      checkLeftRight(diag.unnecessaryNanComparisonTrue);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      checkLeftRight(diag.unnecessaryNanComparisonFalse);
    }
  }

  void _checkForInvariantNullComparison(BinaryExpression node) {
    LocatableDiagnostic locatableDiagnostic;
    if (node.operator.type == TokenType.BANG_EQ) {
      locatableDiagnostic = diag.unnecessaryNullComparisonNeverNullTrue;
    } else if (node.operator.type == TokenType.EQ_EQ) {
      locatableDiagnostic = diag.unnecessaryNullComparisonNeverNullFalse;
    } else {
      return;
    }

    if (node.leftOperand is NullLiteral) {
      var rightType = node.rightOperand.typeOrThrow;
      if (_typeSystem.isStrictlyNonNullable(rightType)) {
        var offset = node.leftOperand.offset;
        _diagnosticReporter.report(
          locatableDiagnostic.atOffset(
            offset: offset,
            length: node.operator.end - offset,
          ),
        );
      }
    }

    if (node.rightOperand is NullLiteral) {
      var leftType = node.leftOperand.typeOrThrow;
      if (_typeSystem.isStrictlyNonNullable(leftType)) {
        var offset = node.operator.offset;
        _diagnosticReporter.report(
          locatableDiagnostic.atOffset(
            offset: offset,
            length: node.rightOperand.end - offset,
          ),
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
      var warning = node.keyword?.keyword == Keyword.NEW
          ? diag.nonConstCallToLiteralConstructorUsingNew
          : diag.nonConstCallToLiteralConstructor;
      _diagnosticReporter.report(
        warning.withArguments(constructorName: fullConstructorName).at(node),
      );
    }
  }

  /// Report a warning if the dot shorthand constructor is marked with [literal]
  /// and is not const.
  ///
  /// See [diag.nonConstCallToLiteralConstructor].
  void _checkForLiteralConstructorUseInDotShorthand(
    DotShorthandConstructorInvocation node,
  ) {
    var constructor = node.constructorName.element;
    if (constructor is! ConstructorElement) return;
    if (!node.isConst && constructor.metadata.hasLiteral && node.canBeConst) {
      _diagnosticReporter.report(
        diag.nonConstCallToLiteralConstructor
            .withArguments(constructorName: constructor.displayName)
            .at(node),
      );
    }
  }

  /// Checks that the imported library does not define a `loadLibrary` function.
  ///
  /// Only call this for a deferred [importElement].
  ///
  /// Returns whether an error code is generated on [node].
  bool _checkForLoadLibraryFunction(
    ImportDirective node,
    LibraryImport importElement,
  ) {
    var importedLibrary = importElement.importedLibrary;
    var prefix = importElement.prefix?.element;
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
      _diagnosticReporter.report(
        diag.importDeferredLibraryWithLoadFunction.at(node),
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
      _diagnosticReporter.report(diag.nonNullableEqualsParameter.at(node.name));
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
      _diagnosticReporter.report(diag.nullableTypeInCatchClause.at(typeNode));
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
        _diagnosticReporter.report(
          diag.returnOfDoNotStore
              .withArguments(
                invokedFunction: entry.value.name!,
                returningFunction: parent.declaredFragment!.element.displayName,
              )
              .at(entry.key),
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
        _diagnosticReporter.report(diag.unnecessaryNoSuchMethod.at(node.name));
        return true;
      }
    } else if (body is BlockFunctionBody) {
      List<Statement> statements = body.block.statements;
      if (statements.length == 1) {
        Statement returnStatement = statements.first;
        if (returnStatement is ReturnStatement &&
            isNonObjectNoSuchMethodInvocation(returnStatement.expression)) {
          _diagnosticReporter.report(
            diag.unnecessaryNoSuchMethod.at(node.name),
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
          _diagnosticReporter.report(diag.unnecessarySetLiteral.at(expression));
        }
      }
    }
  }

  /// In "strict-inference" mode, checks that the type of each of parameter in
  /// [parameterList] is specified.
  ///
  /// Only parameters which are referenced in [initializers] or [body] are
  /// reported. If [initializers] and [body] are both `null`, the parameters are
  /// assumed to originate from a typedef, function-typed parameter, or function
  /// which is abstract or external.
  void _checkStrictInferenceInParameters(
    FormalParameterList? parameterList, {
    List<ConstructorInitializer>? initializers,
    FunctionBody? body,
  }) {
    if (!_strictInference || parameterList == null) {
      return;
    }

    var implicitlyTypedParameters = parameterList.parameters
        .map((p) => p.notDefault)
        .whereType<SimpleFormalParameter>()
        .where((p) => p.type == null)
        .toList();

    if (implicitlyTypedParameters.isEmpty) return;

    // Whether the parameters are in a typedef, or function that is abstract,
    // external, etc.
    var parameterReferenceIsUnknown =
        (body == null || body is EmptyFunctionBody) && initializers == null;

    if (!parameterReferenceIsUnknown) {
      var usedVisitor = _UsedParameterVisitor(
        implicitlyTypedParameters
            .map((p) => p.declaredFragment!.element)
            .toSet(),
      );
      body?.accept(usedVisitor);
      if (initializers != null) {
        for (var initializer in initializers) {
          initializer.accept(usedVisitor);
        }
      }

      implicitlyTypedParameters.removeWhere(
        (p) => !usedVisitor.isUsed(p.declaredFragment!.element),
      );
    }

    for (var parameter in implicitlyTypedParameters) {
      var element = parameter.declaredFragment!.element;
      _diagnosticReporter.report(
        diag.inferenceFailureOnUntypedParameter
            .withArguments(parameter: element.displayName)
            .at(parameter),
      );
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
      case MethodDeclaration(:var name) || FunctionDeclaration(:var name):
        _diagnosticReporter.report(
          diag.inferenceFailureOnFunctionReturnType
              .withArguments(function: displayName)
              .at(name),
        );
      case _:
        _diagnosticReporter.report(
          diag.inferenceFailureOnFunctionReturnType
              .withArguments(function: displayName)
              .at(reportNode),
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
    if (element is PropertyAccessorElement && element.isOriginVariable) {
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

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is PropertyAccessorElement && element.isOriginVariable) {
      if (element.variable.metadata.hasNonVirtual) {
        return true;
      }
    }
    return element.metadata.hasNonVirtual;
  }

  /// Checks for the passed as expression for the [diag.unnecessaryCast]
  /// hint code.
  ///
  /// Returns `true` if and only if an unnecessary cast hint should be generated
  /// on [node].  See [diag.unnecessaryCast].
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

  final DiagnosticReporter _diagnosticReporter;
  final LibraryElement _library;
  final WorkspacePackageImpl? _workspacePackage;

  final bool _inTemplateSource;
  final bool _inTestDirectory;

  InterfaceElement? _enclosingClass;

  _InvalidAccessVerifier(
    this._diagnosticReporter,
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

    var element = grandparent is ConstructorName
        ? grandparent.element
        : identifier.writeOrReadElement;

    if (element == null) {
      return;
    }

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

      _diagnosticReporter.report(
        diag.invalidUseOfVisibleForOverridingMember
            .withArguments(name: operator.type.lexeme)
            .at(operator),
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
      _diagnosticReporter.report(
        diag.invalidUseOfInternalMember
            .withArguments(name: node.uri.stringValue!)
            .at(node),
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

    if (_inCurrentLibrary(element)) {
      return;
    }

    if (element.isInternal && !_isLibraryInWorkspacePackage(element.library)) {
      var fieldName = node.name;
      if (fieldName == null) {
        return;
      }
      var errorEntity = node.errorEntity;

      _diagnosticReporter.report(
        diag.invalidUseOfInternalMember
            .withArguments(name: element.displayName)
            .at(errorEntity),
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
      _diagnosticReporter.report(
        diag.invalidUseOfInternalMember
            .withArguments(name: element.name!)
            .at(node),
      );
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

      _diagnosticReporter.report(
        diag.invalidUseOfInternalMember.withArguments(name: name).at(node),
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
        var methodDeclaration = grandparent
            ?.thisOrAncestorOfType<MethodDeclaration>();
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
      _diagnosticReporter.report(
        diag.invalidUseOfProtectedMember
            .withArguments(
              memberName: name,
              definingClass: definingClass.displayName,
            )
            .at(errorEntity),
      );
    }

    if (isVisibleForTemplateApplied) {
      _diagnosticReporter.report(
        diag.invalidUseOfVisibleForTemplateMember
            .withArguments(memberName: name, uri: definingClass.library!.uri)
            .at(errorEntity),
      );
    }

    if (hasVisibleForTesting) {
      _diagnosticReporter.report(
        diag.invalidUseOfVisibleForTestingMember
            .withArguments(memberName: name, uri: definingClass.library!.uri)
            .at(errorEntity),
      );
    }

    if (hasVisibleForOverriding) {
      _diagnosticReporter.report(
        diag.invalidUseOfVisibleForOverridingMember
            .withArguments(name: name)
            .at(errorEntity),
      );
    }
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
    if (element.metadata.hasVisibleForOverriding) {
      return true;
    }

    if (element is PropertyAccessorElement) {
      return element.variable.metadata.hasVisibleForOverriding;
    }

    return false;
  }

  bool _hasVisibleForTemplate(Element? element) {
    if (element == null) {
      return false;
    }
    if (element.metadata.hasVisibleForTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement) {
      if (element.variable.metadata.hasVisibleForTemplate) {
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
    if (element.metadata.hasVisibleOutsideTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement) {
      if (element.variable.metadata.hasVisibleOutsideTemplate) {
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
    library as LibraryElementImpl;
    return _workspacePackage.contains(library.internal.firstFragment.source);
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
    if (element is SubstitutedExecutableElementImpl) {
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

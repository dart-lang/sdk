// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

export 'package:analyzer/src/dart/constant/constant_verifier.dart';
export 'package:analyzer/src/dart/resolver/exit_detector.dart';
export 'package:analyzer/src/dart/resolver/scope.dart';
export 'package:analyzer/src/generated/type_system.dart';

/// Instances of the class `BestPracticesVerifier` traverse an AST structure
/// looking for violations of Dart best practices.
class BestPracticesVerifier extends RecursiveAstVisitor<void> {
//  static String _HASHCODE_GETTER_NAME = "hashCode";

  static String _NULL_TYPE_NAME = "Null";

  static String _TO_INT_METHOD_NAME = "toInt";

  /// The class containing the AST nodes being visited, or `null` if we are not
  /// in the scope of a class.
  ClassElementImpl _enclosingClass;

  /// A flag indicating whether a surrounding member (compilation unit or class)
  /// is deprecated.
  bool _inDeprecatedMember;

  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type [Null].
  final InterfaceType _nullType;

  /// The type system primitives
  final TypeSystem _typeSystem;

  /// The inheritance manager to access interface type hierarchy.
  final InheritanceManager3 _inheritanceManager;

  /// The current library
  final LibraryElement _currentLibrary;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  WorkspacePackage _workspacePackage;

  /// The [LinterContext] used for possible const calculations.
  LinterContext _linterContext;

  /// Is `true` if NNBD is enabled for the library being analyzed.
  final bool _isNonNullable;

  /// True if inference failures should be reported, otherwise false.
  final bool _strictInference;

  /// Create a new instance of the [BestPracticesVerifier].
  ///
  /// @param errorReporter the error reporter
  BestPracticesVerifier(
    this._errorReporter,
    TypeProvider typeProvider,
    this._currentLibrary,
    CompilationUnit unit,
    String content, {
    TypeSystem typeSystem,
    @required InheritanceManager3 inheritanceManager,
    ResourceProvider resourceProvider,
    DeclaredVariables declaredVariables,
    AnalysisOptions analysisOptions,
  })  : _nullType = typeProvider.nullType,
        _typeSystem = typeSystem ?? new Dart2TypeSystem(typeProvider),
        _isNonNullable = unit.featureSet.isEnabled(Feature.non_nullable),
        _strictInference =
            (analysisOptions as AnalysisOptionsImpl).strictInference,
        _inheritanceManager = inheritanceManager,
        _invalidAccessVerifier =
            new _InvalidAccessVerifier(_errorReporter, _currentLibrary) {
    _inDeprecatedMember = _currentLibrary.hasDeprecated;
    String libraryPath = _currentLibrary.source.fullName;
    _workspacePackage = _getPackage(libraryPath, resourceProvider);

    _linterContext = LinterContextImpl(
      null /* allUnits */,
      new LinterContextUnit(content, unit),
      declaredVariables,
      typeProvider,
      _typeSystem,
      _inheritanceManager,
      analysisOptions,
      _workspacePackage,
    );
  }

  @override
  void visitAnnotation(Annotation node) {
    ElementAnnotation element = node.elementAnnotation;
    AstNode parent = node.parent;
    if (element?.isFactory == true) {
      if (parent is MethodDeclaration) {
        _checkForInvalidFactory(parent);
      } else {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_FACTORY_ANNOTATION, node, []);
      }
    } else if (element?.isImmutable == true) {
      if (parent is! ClassOrMixinDeclaration && parent is! ClassTypeAlias) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_IMMUTABLE_ANNOTATION, node, []);
      }
    } else if (element?.isLiteral == true) {
      if (parent is! ConstructorDeclaration ||
          (parent as ConstructorDeclaration).constKeyword == null) {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_LITERAL_ANNOTATION, node, []);
      }
    } else if (element?.isNonVirtual == true) {
      if (parent is FieldDeclaration) {
        if (parent.isStatic) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_NON_VIRTUAL_ANNOTATION,
              node,
              [node.element.name]);
        }
      } else if (parent is MethodDeclaration) {
        if (parent.parent is ExtensionDeclaration ||
            parent.isStatic ||
            parent.isAbstract) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_NON_VIRTUAL_ANNOTATION,
              node,
              [node.element.name]);
        }
      } else {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_NON_VIRTUAL_ANNOTATION, node, [node.element.name]);
      }
    } else if (element?.isSealed == true) {
      if (!(parent is ClassDeclaration || parent is ClassTypeAlias)) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_SEALED_ANNOTATION, node, [node.element.name]);
      }
    } else if (element?.isVisibleForTemplate == true ||
        element?.isVisibleForTesting == true) {
      if (parent is Declaration) {
        reportInvalidAnnotation(Element declaredElement) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_VISIBILITY_ANNOTATION,
              node,
              [declaredElement.name, node.name.name]);
        }

        if (parent is TopLevelVariableDeclaration) {
          for (VariableDeclaration variable in parent.variables.variables) {
            if (Identifier.isPrivateName(variable.declaredElement.name)) {
              reportInvalidAnnotation(variable.declaredElement);
            }
          }
        } else if (parent is FieldDeclaration) {
          for (VariableDeclaration variable in parent.fields.variables) {
            if (Identifier.isPrivateName(variable.declaredElement.name)) {
              reportInvalidAnnotation(variable.declaredElement);
            }
          }
        } else if (parent.declaredElement != null &&
            Identifier.isPrivateName(parent.declaredElement.name)) {
          reportInvalidAnnotation(parent.declaredElement);
        }
      } else {
        // Something other than a declaration was annotated. Whatever this is,
        // it probably warrants a Hint, but this has not been specified on
        // visibleForTemplate or visibleForTesting, so leave it alone for now.
      }
    }

    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (Expression argument in node.arguments) {
      ParameterElement parameter = argument.staticParameterElement;
      if (parameter?.isOptionalPositional == true) {
        _checkForDeprecatedMemberUse(parameter, argument);
      }
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _checkForUnnecessaryCast(node);
    super.visitAsExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    if (operatorType != TokenType.EQ) {
      _checkForDeprecatedMemberUse(node.staticElement, node);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _checkForDivisionOptimizationHint(node);
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    ClassElementImpl element = node.declaredElement;
    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = element;

    bool wasInDeprecatedMember = _inDeprecatedMember;
    if (element != null && element.hasDeprecated) {
      _inDeprecatedMember = true;
    }

    try {
      // Commented out until we decide that we want this hint in the analyzer
      //    checkForOverrideEqualsButNotHashCode(node);
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _checkForImmutable(node);
    _checkForInvalidSealedSuperclass(node);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.declaredElement.isFactory) {
      if (node.body is BlockFunctionBody) {
        // Check the block for a return statement, if not, create the hint.
        if (!ExitDetector.exits(node.body)) {
          _errorReporter.reportErrorForNode(
              HintCode.MISSING_RETURN, node, [node.returnType.name]);
        }
      }
    }
    _checkStrictInferenceInParameters(node.parameters);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    super.visitExportDirective(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    bool wasInDeprecatedMember = _inDeprecatedMember;
    if (_hasDeprecatedAnnotation(node.metadata)) {
      _inDeprecatedMember = true;
    }

    try {
      super.visitFieldDeclaration(node);
      for (var field in node.fields.variables) {
        ExecutableElement getOverriddenPropertyAccessor() {
          final element = field.declaredElement;
          if (element is PropertyAccessorElement || element is FieldElement) {
            Name name = new Name(_currentLibrary.source.uri, element.name);
            Element enclosingElement = element.enclosingElement;
            if (enclosingElement is ClassElement) {
              InterfaceType classType = enclosingElement.thisType;
              var overridden = _inheritanceManager.getMember(classType, name,
                  forSuper: true);
              // Check for a setter.
              if (overridden == null) {
                Name setterName =
                    new Name(_currentLibrary.source.uri, '${element.name}=');
                overridden = _inheritanceManager
                    .getMember(classType, setterName, forSuper: true);
              }
              return overridden;
            }
          }
          return null;
        }

        final overriddenElement = getOverriddenPropertyAccessor();
        if (_hasNonVirtualAnnotation(overriddenElement)) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
              field.name,
              [field.name, overriddenElement.enclosingElement.name]);
        }
      }
    } finally {
      _inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _checkRequiredParameter(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bool wasInDeprecatedMember = _inDeprecatedMember;
    ExecutableElement element = node.declaredElement;
    if (element != null && element.hasDeprecated) {
      _inDeprecatedMember = true;
    }
    try {
      _checkForMissingReturn(
          node.returnType, node.functionExpression.body, element, node);

      // Return types are inferred only on non-recursive local functions.
      if (node.parent is CompilationUnit) {
        _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
      }
      _checkStrictInferenceInParameters(node.functionExpression.parameters);
      super.visitFunctionDeclaration(node);
    } finally {
      _inDeprecatedMember = wasInDeprecatedMember;
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
    if (node.parent is! FunctionDeclaration) {
      _checkForMissingReturn(null, node.body, node.declaredElement, node);
    }
    DartType functionType = InferenceContext.getContext(node);
    if (functionType is! FunctionType) {
      _checkStrictInferenceInParameters(node.parameters);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var callElement = node.staticElement;
    if (callElement is MethodElement &&
        callElement.name == FunctionElement.CALL_METHOD_NAME) {
      _checkForDeprecatedMemberUse(callElement, node);
    }

    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _checkStrictInferenceReturnType(
        node.returnType, node, node.identifier.name);
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
          node.functionType.returnType, node, node.name.name);
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    ImportElement importElement = node.element;
    if (importElement != null && importElement.isDeferred) {
      _checkForLoadLibraryFunction(node, importElement);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
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
    bool wasInDeprecatedMember = _inDeprecatedMember;
    ExecutableElement element = node.declaredElement;
    Element enclosingElement = element?.enclosingElement;

    InterfaceType classType =
        enclosingElement is ClassElement ? enclosingElement.thisType : null;
    Name name = Name(_currentLibrary.source.uri, element?.name ?? '');

    bool elementIsOverride() =>
        element is ClassMemberElement && enclosingElement != null
            ? _inheritanceManager.getOverridden(classType, name) != null
            : false;
    ExecutableElement getConcreteOverriddenElement() =>
        element is ClassMemberElement && enclosingElement != null
            ? _inheritanceManager.getMember(classType, name, forSuper: true)
            : null;
    ExecutableElement getOverriddenPropertyAccessor() =>
        element is PropertyAccessorElement && enclosingElement != null
            ? _inheritanceManager.getMember(classType, name, forSuper: true)
            : null;

    if (element != null && element.hasDeprecated) {
      _inDeprecatedMember = true;
    }
    try {
      // This was determined to not be a good hint, see: dartbug.com/16029
      //checkForOverridingPrivateMember(node);
      _checkForMissingReturn(node.returnType, node.body, element, node);
      _checkForUnnecessaryNoSuchMethod(node);

      if (_strictInference && !node.isSetter && !elementIsOverride()) {
        _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
      }
      _checkStrictInferenceInParameters(node.parameters);

      ExecutableElement overriddenElement = getConcreteOverriddenElement();
      if (overriddenElement == null && (node.isSetter || node.isGetter)) {
        overriddenElement = getOverriddenPropertyAccessor();
      }

      if (_hasNonVirtualAnnotation(overriddenElement)) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
            node.name,
            [node.name, overriddenElement.enclosingElement.name]);
      }

      super.visitMethodDeclaration(node);
    } finally {
      _inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkForNullAwareHints(node, node.operator);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _enclosingClass = node.declaredElement;
    _invalidAccessVerifier._enclosingClass = _enclosingClass;

    bool wasInDeprecatedMember = _inDeprecatedMember;
    if (_hasDeprecatedAnnotation(node.metadata)) {
      _inDeprecatedMember = true;
    }

    try {
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkForNullAwareHints(node, node.operator);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForDeprecatedMemberUseAtIdentifier(node);
    _invalidAccessVerifier.verify(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    bool wasInDeprecatedMember = _inDeprecatedMember;
    if (_hasDeprecatedAnnotation(node.metadata)) {
      _inDeprecatedMember = true;
    }

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  /// Check for the passed is expression for the unnecessary type check hint
  /// codes as well as null checks expressed using an is expression.
  ///
  /// @param node the is expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.TYPE_CHECK_IS_NOT_NULL], [HintCode.TYPE_CHECK_IS_NULL],
  /// [HintCode.UNNECESSARY_TYPE_CHECK_TRUE], and
  /// [HintCode.UNNECESSARY_TYPE_CHECK_FALSE].
  bool _checkAllTypeChecks(IsExpression node) {
    Expression expression = node.expression;
    TypeAnnotation typeName = node.type;
    TypeImpl lhsType = expression.staticType;
    TypeImpl rhsType = typeName.type;
    if (lhsType == null || rhsType == null) {
      return false;
    }
    String rhsNameStr = typeName is TypeName ? typeName.name.name : null;
    // if x is dynamic
    if (rhsType.isDynamic && rhsNameStr == Keyword.DYNAMIC.lexeme) {
      if (node.notOperator == null) {
        // the is case
        _errorReporter.reportErrorForNode(
            HintCode.UNNECESSARY_TYPE_CHECK_TRUE, node);
      } else {
        // the is not case
        _errorReporter.reportErrorForNode(
            HintCode.UNNECESSARY_TYPE_CHECK_FALSE, node);
      }
      return true;
    }
    Element rhsElement = rhsType.element;
    LibraryElement libraryElement = rhsElement?.library;
    if (libraryElement != null && libraryElement.isDartCore) {
      // `is Null` or `is! Null`
      if (rhsNameStr == _NULL_TYPE_NAME) {
        if (expression is NullLiteral) {
          if (node.notOperator == null) {
            _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_TYPE_CHECK_TRUE,
              node,
            );
          } else {
            _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_TYPE_CHECK_FALSE,
              node,
            );
          }
        } else {
          if (node.notOperator == null) {
            _errorReporter.reportErrorForNode(
              HintCode.TYPE_CHECK_IS_NULL,
              node,
            );
          } else {
            _errorReporter.reportErrorForNode(
              HintCode.TYPE_CHECK_IS_NOT_NULL,
              node,
            );
          }
        }
        return true;
      }
      // `is Object` or `is! Object`
      if (rhsType.isObject) {
        var nullability = rhsType.nullabilitySuffix;
        if (nullability == NullabilitySuffix.star ||
            nullability == NullabilitySuffix.question) {
          if (node.notOperator == null) {
            _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_TYPE_CHECK_TRUE,
              node,
            );
          } else {
            _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_TYPE_CHECK_FALSE,
              node,
            );
          }
          return true;
        }
      }
    }
    return false;
  }

  /// Given some [element], look at the associated metadata and report the use
  /// of the member if it is declared as deprecated. If a diagnostic is reported
  /// it should be reported at the given [node].
  void _checkForDeprecatedMemberUse(Element element, AstNode node) {
    bool isDeprecated(Element element) {
      if (element is PropertyAccessorElement && element.isSynthetic) {
        // TODO(brianwilkerson) Why isn't this the implementation for PropertyAccessorElement?
        Element variable = element.variable;
        if (variable == null) {
          return false;
        }
        return variable.hasDeprecated;
      }
      return element.hasDeprecated;
    }

    bool isLocalParameter(Element element, AstNode node) {
      if (element is ParameterElement) {
        ExecutableElement definingFunction = element.enclosingElement;
        FunctionBody body = node.thisOrAncestorOfType<FunctionBody>();
        while (body != null) {
          ExecutableElement enclosingFunction;
          AstNode parent = body.parent;
          if (parent is ConstructorDeclaration) {
            enclosingFunction = parent.declaredElement;
          } else if (parent is FunctionExpression) {
            enclosingFunction = parent.declaredElement;
          } else if (parent is MethodDeclaration) {
            enclosingFunction = parent.declaredElement;
          }
          if (enclosingFunction == definingFunction) {
            return true;
          }
          body = parent?.thisOrAncestorOfType<FunctionBody>();
        }
      }
      return false;
    }

    if (!_inDeprecatedMember &&
        element != null &&
        isDeprecated(element) &&
        !isLocalParameter(element, node)) {
      String displayName = element.displayName;
      if (element is ConstructorElement) {
        // TODO(jwren) We should modify ConstructorElement.getDisplayName(),
        // or have the logic centralized elsewhere, instead of doing this logic
        // here.
        displayName = element.enclosingElement.displayName;
        if (element.displayName.isNotEmpty) {
          displayName = "$displayName.${element.displayName}";
        }
      } else if (element is LibraryElement) {
        displayName = element.definingCompilationUnit.source.uri.toString();
      } else if (displayName == FunctionElement.CALL_METHOD_NAME &&
          node is MethodInvocation &&
          node.staticInvokeType is InterfaceType) {
        DartType staticInvokeType = node.staticInvokeType;
        displayName = "${staticInvokeType.displayName}.${element.displayName}";
      }
      LibraryElement library =
          element is LibraryElement ? element : element.library;
      String message = _deprecatedMessage(element);
      if (message == null || message.isEmpty) {
        HintCode hintCode = _isLibraryInWorkspacePackage(library)
            ? HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE
            : HintCode.DEPRECATED_MEMBER_USE;
        _errorReporter.reportErrorForNode(hintCode, node, [displayName]);
      } else {
        HintCode hintCode = _isLibraryInWorkspacePackage(library)
            ? HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE
            : HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE;
        _errorReporter
            .reportErrorForNode(hintCode, node, [displayName, message]);
      }
    }
  }

  /// For [SimpleIdentifier]s, only call [checkForDeprecatedMemberUse]
  /// if the node is not in a declaration context.
  ///
  /// Also, if the identifier is a constructor name in a constructor invocation,
  /// then calls to the deprecated constructor will be caught by
  /// [visitInstanceCreationExpression] and
  /// [visitSuperConstructorInvocation], and can be ignored by
  /// this visit method.
  ///
  /// @param identifier some simple identifier to check for deprecated use of
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.DEPRECATED_MEMBER_USE].
  void _checkForDeprecatedMemberUseAtIdentifier(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return;
    }
    AstNode parent = identifier.parent;
    if ((parent is ConstructorName && identical(identifier, parent.name)) ||
        (parent is ConstructorDeclaration &&
            identical(identifier, parent.returnType)) ||
        (parent is SuperConstructorInvocation &&
            identical(identifier, parent.constructorName)) ||
        parent is HideCombinator) {
      return;
    }
    _checkForDeprecatedMemberUse(identifier.staticElement, identifier);
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
    MethodElement methodElement = node.staticElement;
    if (methodElement == null) {
      return false;
    }
    LibraryElement libraryElement = methodElement.library;
    if (libraryElement != null && !libraryElement.isDartCore) {
      return false;
    }
    // Report error if the (x/y) has toInt() invoked on it
    AstNode parent = node.parent;
    if (parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesizedExpression =
          _wrapParenthesizedExpression(parent);
      AstNode grandParent = parenthesizedExpression.parent;
      if (grandParent is MethodInvocation) {
        if (_TO_INT_METHOD_NAME == grandParent.methodName.name &&
            grandParent.argumentList.arguments.isEmpty) {
          _errorReporter.reportErrorForNode(
              HintCode.DIVISION_OPTIMIZATION, grandParent);
          return true;
        }
      }
    }
    return false;
  }

  /// Checks whether [node] violates the rules of [immutable].
  ///
  /// If [node] is marked with [immutable] or inherits from a class or mixin
  /// marked with [immutable], this function searches the fields of [node] and
  /// its superclasses, reporting a hint if any non-final instance fields are
  /// found.
  void _checkForImmutable(NamedCompilationUnitMember node) {
    /// Return `true` if the given class [element] is annotated with the
    /// `@immutable` annotation.
    bool isImmutable(ClassElement element) {
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
        ClassElement element, HashSet<ClassElement> visited) {
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
          return isOrInheritsImmutable(element.supertype.element, visited);
        }
      }
      return false;
    }

    /// Return `true` if the given class [element] defines a non-final instance
    /// field.
    Iterable<String> nonFinalInstanceFields(ClassElement element) {
      return element.fields
          .where((FieldElement field) =>
              !field.isSynthetic && !field.isFinal && !field.isStatic)
          .map((FieldElement field) => '${element.name}.${field.name}');
    }

    /// Return `true` if the given class [element] defines or inherits a
    /// non-final field.
    Iterable<String> definedOrInheritedNonFinalInstanceFields(
        ClassElement element, HashSet<ClassElement> visited) {
      Iterable<String> nonFinalFields = [];
      if (visited.add(element)) {
        nonFinalFields = nonFinalInstanceFields(element);
        nonFinalFields = nonFinalFields.followedBy(element.mixins.expand(
            (InterfaceType mixin) => nonFinalInstanceFields(mixin.element)));
        if (element.supertype != null) {
          nonFinalFields = nonFinalFields.followedBy(
              definedOrInheritedNonFinalInstanceFields(
                  element.supertype.element, visited));
        }
      }
      return nonFinalFields;
    }

    ClassElement element = node.declaredElement;
    if (isOrInheritsImmutable(element, new HashSet<ClassElement>())) {
      Iterable<String> nonFinalFields =
          definedOrInheritedNonFinalInstanceFields(
              element, new HashSet<ClassElement>());
      if (nonFinalFields.isNotEmpty) {
        _errorReporter.reportErrorForNode(
            HintCode.MUST_BE_IMMUTABLE, node.name, [nonFinalFields.join(', ')]);
      }
    }
  }

  void _checkForInvalidFactory(MethodDeclaration decl) {
    // Check declaration.
    // Note that null return types are expected to be flagged by other analyses.
    DartType returnType = decl.returnType?.type;
    if (returnType is VoidType) {
      _errorReporter.reportErrorForNode(HintCode.INVALID_FACTORY_METHOD_DECL,
          decl.name, [decl.name.toString()]);
      return;
    }

    // Check implementation.

    FunctionBody body = decl.body;
    if (body is EmptyFunctionBody) {
      // Abstract methods are OK.
      return;
    }

    // `new Foo()` or `null`.
    bool factoryExpression(Expression expression) =>
        expression is InstanceCreationExpression || expression is NullLiteral;

    if (body is ExpressionFunctionBody && factoryExpression(body.expression)) {
      return;
    } else if (body is BlockFunctionBody) {
      NodeList<Statement> statements = body.block.statements;
      if (statements.isNotEmpty) {
        Statement last = statements.last;
        if (last is ReturnStatement && factoryExpression(last.expression)) {
          return;
        }
      }
    }

    _errorReporter.reportErrorForNode(HintCode.INVALID_FACTORY_METHOD_IMPL,
        decl.name, [decl.name.toString()]);
  }

  void _checkForInvalidSealedSuperclass(NamedCompilationUnitMember node) {
    bool currentPackageContains(Element element) {
      return _isLibraryInWorkspacePackage(element.library);
    }

    // [NamedCompilationUnitMember.declaredElement] is not necessarily a
    // ClassElement, but [_checkForInvalidSealedSuperclass] should only be
    // called with a [ClassOrMixinDeclaration], or a [ClassTypeAlias]. The
    // `declaredElement` of these specific classes is a [ClassElement].
    ClassElement element = node.declaredElement;
    // TODO(srawlins): Perhaps replace this with a getter on Element, like
    // `Element.hasOrInheritsSealed`?
    for (InterfaceType supertype in element.allSupertypes) {
      ClassElement superclass = supertype.element;
      if (superclass.hasSealed) {
        if (!currentPackageContains(superclass)) {
          if (element.superclassConstraints.contains(supertype)) {
            // This is a special violation of the sealed class contract,
            // requiring specific messaging.
            _errorReporter.reportErrorForNode(HintCode.MIXIN_ON_SEALED_CLASS,
                node, [superclass.name.toString()]);
          } else {
            // This is a regular violation of the sealed class contract.
            _errorReporter.reportErrorForNode(HintCode.SUBTYPE_OF_SEALED_CLASS,
                node, [superclass.name.toString()]);
          }
        }
      }
    }
  }

  /// Check that the instance creation node is const if the constructor is
  /// marked with [literal].
  _checkForLiteralConstructorUse(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    ConstructorElement constructor = constructorName.staticElement;
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
      String fullConstructorName = constructorName.type.name.name;
      if (constructorName.name != null) {
        fullConstructorName = '$fullConstructorName.${constructorName.name}';
      }
      HintCode hint = node.keyword?.keyword == Keyword.NEW
          ? HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW
          : HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR;
      _errorReporter.reportErrorForNode(hint, node, [fullConstructorName]);
    }
  }

  /// Check that the imported library does not define a loadLibrary function.
  /// The import has already been determined to be deferred when this is called.
  ///
  /// @param node the import directive to evaluate
  /// @param importElement the [ImportElement] retrieved from the node
  /// @return `true` if and only if an error code is generated on the passed
  ///         node
  /// See [CompileTimeErrorCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION].
  bool _checkForLoadLibraryFunction(
      ImportDirective node, ImportElement importElement) {
    LibraryElement importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null) {
      return false;
    }
    if (importedLibrary.hasLoadLibraryFunction) {
      _errorReporter.reportErrorForNode(
          HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION,
          node,
          [importedLibrary.name]);
      return true;
    }
    return false;
  }

  /// Generate a hint for functions or methods that have a return type, but do
  /// not have a return statement on all branches. At the end of blocks with no
  /// return, Dart implicitly returns `null`. Avoiding these implicit returns
  /// is considered a best practice.
  ///
  /// Note: for async functions/methods, this hint only applies when the
  /// function has a return type that Future<Null> is not assignable to.
  ///
  /// See [HintCode.MISSING_RETURN].
  void _checkForMissingReturn(TypeAnnotation returnNode, FunctionBody body,
      ExecutableElement element, AstNode functionNode) {
    if (body is BlockFunctionBody) {
      // Prefer the type from the element model, in case we've inferred one.
      DartType returnType = element?.returnType ?? returnNode?.type;

      // Skip the check if we're missing a return type (e.g. erroneous code).
      // Generators are never required to have a return statement.
      if (returnType == null || body.isGenerator) {
        return;
      }

      var flattenedType =
          body.isAsynchronous ? _typeSystem.flatten(returnType) : returnType;

      // Function expressions without a return will have their return type set
      // to `Null` regardless of their context type. So we need to figure out
      // if a return type was expected from the original downwards context.
      //
      // This helps detect hint cases like `int Function() f = () {}`.
      // See https://github.com/dart-lang/sdk/issues/28233 for context.
      if (flattenedType.isDartCoreNull && functionNode is FunctionExpression) {
        var contextType = InferenceContext.getContext(functionNode);
        if (contextType is FunctionType) {
          returnType = contextType.returnType;
          flattenedType = body.isAsynchronous
              ? _typeSystem.flatten(returnType)
              : returnType;
        }
      }

      // dynamic, Null, void, and FutureOr<T> where T is (dynamic, Null, void)
      // are allowed to omit a return.
      if (flattenedType.isDartAsyncFutureOr) {
        flattenedType = (flattenedType as InterfaceType).typeArguments[0];
      }
      if (flattenedType.isDynamic ||
          flattenedType.isDartCoreNull ||
          flattenedType.isVoid) {
        return;
      }
      // Otherwise issue a warning if the block doesn't have a return.
      if (!ExitDetector.exits(body)) {
        AstNode errorNode = functionNode is MethodDeclaration
            ? functionNode.name
            : functionNode is FunctionDeclaration
                ? functionNode.name
                : functionNode;
        _errorReporter.reportErrorForNode(
            HintCode.MISSING_RETURN, errorNode, [returnType.displayName]);
      }
    }
  }

  /// Produce several null-aware related hints.
  void _checkForNullAwareHints(Expression node, Token operator) {
    if (_isNonNullable) {
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
        _nullType.lookUpMethod(parent.methodName.name, _currentLibrary) ==
            null) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }
    if (parent is PropertyAccess &&
        !parent.isNullAware &&
        _nullType.lookUpGetter(parent.propertyName.name, _currentLibrary) ==
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
    if (parent is IfStatement && parent.condition == childOfParent ||
        parent is ForPartsWithDeclarations &&
            parent.condition == childOfParent ||
        parent is DoStatement && parent.condition == childOfParent ||
        parent is WhileStatement && parent.condition == childOfParent ||
        parent is ConditionalExpression && parent.condition == childOfParent ||
        parent is AssertStatement && parent.condition == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_IN_CONDITION, childOfParent);
      return;
    }

    // NULL_AWARE_IN_LOGICAL_OPERATOR
    if (parent is PrefixExpression && parent.operator.type == TokenType.BANG ||
        parent is BinaryExpression &&
            [TokenType.BAR_BAR, TokenType.AMPERSAND_AMPERSAND]
                .contains(parent.operator.type)) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, childOfParent);
      return;
    }

    // NULL_AWARE_BEFORE_OPERATOR
    if (parent is BinaryExpression &&
        ![TokenType.EQ_EQ, TokenType.BANG_EQ, TokenType.QUESTION_QUESTION]
            .contains(parent.operator.type) &&
        parent.leftOperand == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_BEFORE_OPERATOR, childOfParent);
      return;
    }
  }

  /// Check for the passed as expression for the [HintCode.UNNECESSARY_CAST]
  /// hint code.
  ///
  /// @param node the as expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.UNNECESSARY_CAST].
  bool _checkForUnnecessaryCast(AsExpression node) {
    // TODO(jwren) After dartbug.com/13732, revisit this, we should be able to
    // remove the (x is! TypeParameterType) checks.
    AstNode parent = node.parent;
    if (parent is ConditionalExpression &&
        (node == parent.thenExpression || node == parent.elseExpression)) {
      Expression thenExpression = parent.thenExpression;
      DartType thenType;
      if (thenExpression is AsExpression) {
        thenType = thenExpression.expression.staticType;
      } else {
        thenType = thenExpression.staticType;
      }
      Expression elseExpression = parent.elseExpression;
      DartType elseType;
      if (elseExpression is AsExpression) {
        elseType = elseExpression.expression.staticType;
      } else {
        elseType = elseExpression.staticType;
      }
      if (thenType != null &&
          elseType != null &&
          !thenType.isDynamic &&
          !elseType.isDynamic &&
          !_typeSystem.isSubtypeOf(thenType, elseType) &&
          !_typeSystem.isSubtypeOf(elseType, thenType)) {
        return false;
      }
    }
    DartType lhsType = node.expression.staticType;
    DartType rhsType = node.type.type;
    if (lhsType != null &&
        rhsType != null &&
        !lhsType.isDynamic &&
        !rhsType.isDynamic &&
        _typeSystem.isSubtypeOf(lhsType, rhsType)) {
      _errorReporter.reportErrorForNode(HintCode.UNNECESSARY_CAST, node);
      return true;
    }
    return false;
  }

  /// Generate a hint for `noSuchMethod` methods that do nothing except of
  /// calling another `noSuchMethod` that is not defined by `Object`.
  ///
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.UNNECESSARY_NO_SUCH_METHOD].
  bool _checkForUnnecessaryNoSuchMethod(MethodDeclaration node) {
    if (node.name.name != FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
      return false;
    }
    bool isNonObjectNoSuchMethodInvocation(Expression invocation) {
      if (invocation is MethodInvocation &&
          invocation.target is SuperExpression &&
          invocation.argumentList.arguments.length == 1) {
        SimpleIdentifier name = invocation.methodName;
        if (name.name == FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
          Element methodElement = name.staticElement;
          Element classElement = methodElement?.enclosingElement;
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
        _errorReporter.reportErrorForNode(
            HintCode.UNNECESSARY_NO_SUCH_METHOD, node);
        return true;
      }
    } else if (body is BlockFunctionBody) {
      List<Statement> statements = body.block.statements;
      if (statements.length == 1) {
        Statement returnStatement = statements.first;
        if (returnStatement is ReturnStatement &&
            isNonObjectNoSuchMethodInvocation(returnStatement.expression)) {
          _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_NO_SUCH_METHOD, node);
          return true;
        }
      }
    }
    return false;
  }

  void _checkRequiredParameter(FormalParameterList node) {
    final requiredParameters =
        node.parameters.where((p) => p.declaredElement?.hasRequired == true);
    final nonNamedParamsWithRequired =
        requiredParameters.where((p) => p.isPositional);
    final namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.isNamed)
        .where((p) => p.declaredElement.defaultValueCode != null);
    for (final param in nonNamedParamsWithRequired.where((p) => p.isOptional)) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM,
          param,
          [param.identifier.name]);
    }
    for (final param in nonNamedParamsWithRequired.where((p) => p.isRequired)) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_REQUIRED_POSITIONAL_PARAM,
          param,
          [param.identifier.name]);
    }
    for (final param in namedParamsWithRequiredAndDefault) {
      _errorReporter.reportErrorForNode(HintCode.INVALID_REQUIRED_NAMED_PARAM,
          param, [param.identifier.name]);
    }
  }

  /// In "strict-inference" mode, check that each of the [parameters]' type is
  /// specified.
  _checkStrictInferenceInParameters(FormalParameterList parameters) {
    void checkParameterTypeIsKnown(SimpleFormalParameter parameter) {
      if (parameter.type == null) {
        ParameterElement element = parameter.declaredElement;
        _errorReporter.reportTypeErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER,
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
          if (parameter.parameter is SimpleFormalParameter) {
            checkParameterTypeIsKnown(parameter.parameter);
          }
        }
      }
    }
  }

  /// In "strict-inference" mode, check that [returnNode]'s return type is
  /// specified.
  void _checkStrictInferenceReturnType(
      AstNode returnType, AstNode reportNode, String displayName) {
    if (!_strictInference) {
      return;
    }
    if (returnType == null) {
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          reportNode,
          [displayName]);
    }
  }

  WorkspacePackage _getPackage(String root, ResourceProvider resourceProvider) {
    Workspace workspace = _currentLibrary.session?.analysisContext?.workspace;
    // If there is no driver setup (as in test environments), we need to create
    // a workspace ourselves.
    // todo (pq): fix tests or otherwise de-dup this logic shared w/ library_analyzer.
    if (workspace == null) {
      final builder = ContextBuilder(
          resourceProvider, null /* sdkManager */, null /* contentCache */);
      workspace =
          ContextBuilder.createWorkspace(resourceProvider, root, builder);
    }
    return workspace?.findPackageFor(root);
  }

  bool _isLibraryInWorkspacePackage(LibraryElement library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage.contains(library.source);
  }

  /// Return the message in the deprecated annotation on the given [element], or
  /// `null` if the element doesn't have a deprecated annotation or if the
  /// annotation does not have a message.
  static String _deprecatedMessage(Element element) {
    ElementAnnotationImpl annotation = element.metadata.firstWhere(
      (e) => e.isDeprecated,
      orElse: () => null,
    );
    if (annotation == null || annotation.element is PropertyAccessorElement) {
      return null;
    }
    DartObject constantValue = annotation.computeConstantValue();
    return constantValue?.getField('message')?.toStringValue() ??
        constantValue?.getField('expires')?.toStringValue();
  }

  /// Check for the passed class declaration for the
  /// [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE] hint code.
  ///
  /// @param node the class declaration to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE].
//  bool _checkForOverrideEqualsButNotHashCode(ClassDeclaration node) {
//    ClassElement classElement = node.element;
//    if (classElement == null) {
//      return false;
//    }
//    MethodElement equalsOperatorMethodElement =
//        classElement.getMethod(sc.TokenType.EQ_EQ.lexeme);
//    if (equalsOperatorMethodElement != null) {
//      PropertyAccessorElement hashCodeElement =
//          classElement.getGetter(_HASHCODE_GETTER_NAME);
//      if (hashCodeElement == null) {
//        _errorReporter.reportErrorForNode(
//            HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE,
//            node.name,
//            [classElement.displayName]);
//        return true;
//      }
//    }
//    return false;
//  }
//
//  /// Return `true` if the given [type] represents `Future<void>`.
//  bool _isFutureVoid(DartType type) {
//    if (type.isDartAsyncFuture) {
//      List<DartType> typeArgs = (type as InterfaceType).typeArguments;
//      if (typeArgs.length == 1 && typeArgs[0].isVoid) {
//        return true;
//      }
//    }
//    return false;
//  }

  static bool _hasDeprecatedAnnotation(List<Annotation> annotations) {
    for (var i = 0; i < annotations.length; i++) {
      if (annotations[i].elementAnnotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element == null) {
      return false;
    }
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
    AstNode parent = parenthesizedExpression.parent;
    if (parent is ParenthesizedExpression) {
      return _wrapParenthesizedExpression(parent);
    }
    return parenthesizedExpression;
  }
}

/// Instances of the class `Dart2JSVerifier` traverse an AST structure looking
/// for hints for code that will be compiled to JS, such as
/// [HintCode.IS_DOUBLE].
class Dart2JSVerifier extends RecursiveAstVisitor<void> {
  /// The name of the `double` type.
  static String _DOUBLE_TYPE_NAME = "double";

  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// Create a new instance of the [Dart2JSVerifier].
  ///
  /// @param errorReporter the error reporter
  Dart2JSVerifier(this._errorReporter);

  @override
  void visitIsExpression(IsExpression node) {
    _checkForIsDoubleHints(node);
    super.visitIsExpression(node);
  }

  /// Check for instances of `x is double`, `x is int`, `x is! double` and
  /// `x is! int`.
  ///
  /// @param node the is expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.IS_DOUBLE],
  /// [HintCode.IS_INT],
  /// [HintCode.IS_NOT_DOUBLE], and
  /// [HintCode.IS_NOT_INT].
  bool _checkForIsDoubleHints(IsExpression node) {
    DartType type = node.type.type;
    Element element = type?.element;
    if (element != null) {
      String typeNameStr = element.name;
      LibraryElement libraryElement = element.library;
      //      if (typeNameStr.equals(INT_TYPE_NAME) && libraryElement != null
      //          && libraryElement.isDartCore()) {
      //        if (node.getNotOperator() == null) {
      //          errorReporter.reportError(HintCode.IS_INT, node);
      //        } else {
      //          errorReporter.reportError(HintCode.IS_NOT_INT, node);
      //        }
      //        return true;
      //      } else
      if (typeNameStr == _DOUBLE_TYPE_NAME &&
          libraryElement != null &&
          libraryElement.isDartCore) {
        if (node.notOperator == null) {
          _errorReporter.reportErrorForNode(HintCode.IS_DOUBLE, node);
        } else {
          _errorReporter.reportErrorForNode(HintCode.IS_NOT_DOUBLE, node);
        }
        return true;
      }
    }
    return false;
  }
}

/// A visitor that finds dead code and unused labels.
class DeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  ///  The type system for this visitor
  final TypeSystem _typeSystem;

  /// The object used to track the usage of labels within a given label scope.
  _LabelTracker labelTracker;

  /// Is `true` if this unit has been parsed as non-nullable.
  final bool _isNonNullableUnit;

  /// Initialize a newly created dead code verifier that will report dead code
  /// to the given [errorReporter] and will use the given [typeSystem] if one is
  /// provided.
  DeadCodeVerifier(this._errorReporter, FeatureSet featureSet,
      {TypeSystem typeSystem})
      : this._typeSystem = typeSystem ?? new Dart2TypeSystem(null),
        _isNonNullableUnit = featureSet.isEnabled(Feature.non_nullable);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForDeadNullCoalesce(
          node.leftHandSide.staticType, node.rightHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    bool isAmpAmp = operator.type == TokenType.AMPERSAND_AMPERSAND;
    bool isBarBar = operator.type == TokenType.BAR_BAR;
    bool isQuestionQuestion = operator.type == TokenType.QUESTION_QUESTION;
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!_isDebugConstant(lhsCondition)) {
        EvaluationResultImpl lhsResult = _getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          bool value = lhsResult.value.toBoolValue();
          if (value == true && isBarBar) {
            // Report error on "else" block: true || !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition?.accept(this);
            return;
          } else if (value == false && isAmpAmp) {
            // Report error on "if" block: false && !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition?.accept(this);
            return;
          }
        }
      }
      // How do we want to handle the RHS? It isn't dead code, but "pointless"
      // or "obscure"...
//            Expression rhsCondition = node.getRightOperand();
//            ValidResult rhsResult = getConstantBooleanValue(rhsCondition);
//            if (rhsResult != null) {
//              if (rhsResult == ValidResult.RESULT_TRUE && isBarBar) {
//                // report error on else block: !e! || true
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              } else if (rhsResult == ValidResult.RESULT_FALSE && isAmpAmp) {
//                // report error on if block: !e! && false
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              }
//            }
    } else if (isQuestionQuestion && _isNonNullableUnit) {
      _checkForDeadNullCoalesce(node.leftOperand.staticType, node.rightOperand);
    }
    super.visitBinaryExpression(node);
  }

  /// For each block, this method reports and error on all statements between
  /// the end of the block and the first return statement (assuming there it is
  /// not at the end of the block.)
  @override
  void visitBlock(Block node) {
    NodeList<Statement> statements = node.statements;
    _checkForDeadStatementsInNodeList(statements);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on "else" block: true ? 1 : !2!
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.elseExpression);
          node.thenExpression?.accept(this);
          return;
        } else {
          // Report error on "if" block: false ? !1! : 2
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenExpression);
          node.elseExpression?.accept(this);
          return;
        }
      }
    }
    super.visitConditionalExpression(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid.
      LibraryElement library = exportElement.exportedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitExportDirective(node);
  }

  @override
  void visitIfElement(IfElement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          CollectionElement elseElement = node.elseElement;
          if (elseElement != null) {
            _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, elseElement);
            node.thenElement?.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenElement);
          node.elseElement?.accept(this);
          return;
        }
      }
    }
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          Statement elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, elseStatement);
            node.thenStatement?.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenStatement);
          node.elseStatement?.accept(this);
          return;
        }
      }
    }
    super.visitIfStatement(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid, but not when the URI is
      // valid but refers to a non-existent file.
      LibraryElement library = importElement.importedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _pushLabels(node.labels);
    try {
      super.visitLabeledStatement(node);
    } finally {
      _popLabels();
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    List<Label> labels = <Label>[];
    for (SwitchMember member in node.members) {
      labels.addAll(member.labels);
    }
    _pushLabels(labels);
    try {
      super.visitSwitchStatement(node);
    } finally {
      _popLabels();
    }
  }

  @override
  void visitTryStatement(TryStatement node) {
    node.body?.accept(this);
    node.finallyBlock?.accept(this);
    NodeList<CatchClause> catchClauses = node.catchClauses;
    int numOfCatchClauses = catchClauses.length;
    List<DartType> visitedTypes = new List<DartType>();
    for (int i = 0; i < numOfCatchClauses; i++) {
      CatchClause catchClause = catchClauses[i];
      if (catchClause.onKeyword != null) {
        // An on-catch clause was found; verify that the exception type is not a
        // subtype of a previous on-catch exception type.
        DartType currentType = catchClause.exceptionType?.type;
        if (currentType != null) {
          if (currentType.isObject) {
            // Found catch clause clause that has Object as an exception type,
            // this is equivalent to having a catch clause that doesn't have an
            // exception type, visit the block, but generate an error on any
            // following catch clauses (and don't visit them).
            catchClause?.accept(this);
            if (i + 1 != numOfCatchClauses) {
              // This catch clause is not the last in the try statement.
              CatchClause nextCatchClause = catchClauses[i + 1];
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = nextCatchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportErrorForOffset(
                  HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
              return;
            }
          }
          int length = visitedTypes.length;
          for (int j = 0; j < length; j++) {
            DartType type = visitedTypes[j];
            if (_typeSystem.isSubtypeOf(currentType, type)) {
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = catchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportErrorForOffset(
                  HintCode.DEAD_CODE_ON_CATCH_SUBTYPE,
                  offset,
                  length,
                  [currentType.displayName, type.displayName]);
              return;
            }
          }
          visitedTypes.add(currentType);
        }
        catchClause?.accept(this);
      } else {
        // Found catch clause clause that doesn't have an exception type,
        // visit the block, but generate an error on any following catch clauses
        // (and don't visit them).
        catchClause?.accept(this);
        if (i + 1 != numOfCatchClauses) {
          // This catch clause is not the last in the try statement.
          CatchClause nextCatchClause = catchClauses[i + 1];
          CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
          int offset = nextCatchClause.offset;
          int length = lastCatchClause.end - offset;
          _errorReporter.reportErrorForOffset(
              HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
          return;
        }
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == false) {
          // Report error on while block: while (false) {!}
          _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, node.body);
          return;
        }
      }
    }
    node.body?.accept(this);
  }

  /// Resolve the names in the given [combinator] in the scope of the given
  /// [library].
  void _checkCombinator(LibraryElement library, Combinator combinator) {
    Namespace namespace =
        new NamespaceBuilder().createExportNamespaceForLibrary(library);
    NodeList<SimpleIdentifier> names;
    ErrorCode hintCode;
    if (combinator is HideCombinator) {
      names = combinator.hiddenNames;
      hintCode = HintCode.UNDEFINED_HIDDEN_NAME;
    } else {
      names = (combinator as ShowCombinator).shownNames;
      hintCode = HintCode.UNDEFINED_SHOWN_NAME;
    }
    for (SimpleIdentifier name in names) {
      String nameStr = name.name;
      Element element = namespace.get(nameStr);
      if (element == null) {
        element = namespace.get("$nameStr=");
      }
      if (element == null) {
        _errorReporter
            .reportErrorForNode(hintCode, name, [library.identifier, nameStr]);
      }
    }
  }

  void _checkForDeadNullCoalesce(TypeImpl lhsType, Expression rhs) {
    if (_isNonNullableUnit && _typeSystem.isNonNullable(lhsType)) {
      _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, rhs, []);
    }
  }

  /// Given some list of [statements], loop through the list searching for dead
  /// statements. If [allowMandated] is true, then allow dead statements that
  /// are mandated by the language spec. This allows for a final break,
  /// continue, return, or throw statement at the end of a switch case, that are
  /// mandated by the language spec.
  void _checkForDeadStatementsInNodeList(NodeList<Statement> statements,
      {bool allowMandated: false}) {
    bool statementExits(Statement statement) {
      if (statement is BreakStatement) {
        return statement.label == null;
      } else if (statement is ContinueStatement) {
        return statement.label == null;
      }
      return ExitDetector.exits(statement);
    }

    int size = statements.length;
    for (int i = 0; i < size; i++) {
      Statement currentStatement = statements[i];
      currentStatement?.accept(this);
      if (statementExits(currentStatement) && i != size - 1) {
        Statement nextStatement = statements[i + 1];
        Statement lastStatement = statements[size - 1];
        // If mandated statements are allowed, and only the last statement is
        // dead, and it's a BreakStatement, then assume it is a statement
        // mandated by the language spec, there to avoid a
        // CASE_BLOCK_NOT_TERMINATED error.
        if (allowMandated && i == size - 2 && nextStatement is BreakStatement) {
          return;
        }
        int offset = nextStatement.offset;
        int length = lastStatement.end - offset;
        _errorReporter.reportErrorForOffset(HintCode.DEAD_CODE, offset, length);
        return;
      }
    }
  }

  /// Given some [expression], return [ValidResult.RESULT_TRUE] if it is `true`,
  /// [ValidResult.RESULT_FALSE] if it is `false`, or `null` if the expression
  /// is not a constant boolean value.
  EvaluationResultImpl _getConstantBooleanValue(Expression expression) {
    if (expression is BooleanLiteral) {
      if (expression.value) {
        return new EvaluationResultImpl(
            new DartObjectImpl(null, BoolState.from(true)));
      } else {
        return new EvaluationResultImpl(
            new DartObjectImpl(null, BoolState.from(false)));
      }
    }

    // Don't consider situations where we could evaluate to a constant boolean
    // expression with the ConstantVisitor
    // else {
    // EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    // if (result == ValidResult.RESULT_TRUE) {
    // return ValidResult.RESULT_TRUE;
    // } else if (result == ValidResult.RESULT_FALSE) {
    // return ValidResult.RESULT_FALSE;
    // }
    // return null;
    // }
    return null;
  }

  /// Return `true` if the given [expression] is resolved to a constant
  /// variable.
  bool _isDebugConstant(Expression expression) {
    Element element;
    if (expression is Identifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is PropertyAccessorElement) {
      PropertyInducingElement variable = element.variable;
      return variable != null && variable.isConst;
    }
    return false;
  }

  /// Exit the most recently entered label scope after reporting any labels that
  /// were not referenced within that scope.
  void _popLabels() {
    for (Label label in labelTracker.unusedLabels()) {
      _errorReporter
          .reportErrorForNode(HintCode.UNUSED_LABEL, label, [label.label.name]);
    }
    labelTracker = labelTracker.outerTracker;
  }

  /// Enter a new label scope in which the given [labels] are defined.
  void _pushLabels(List<Label> labels) {
    labelTracker = new _LabelTracker(labelTracker, labels);
  }
}

/// An [AstVisitor] that fills [UsedLocalElements].
class GatherUsedLocalElementsVisitor extends RecursiveAstVisitor {
  final UsedLocalElements usedElements = new UsedLocalElements();

  final LibraryElement _enclosingLibrary;
  ClassElement _enclosingClass;
  ExecutableElement _enclosingExec;

  GatherUsedLocalElementsVisitor(this._enclosingLibrary);

  @override
  visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null) {
      Element element = exceptionParameter.staticElement;
      usedElements.addCatchException(element);
      if (stackTraceParameter != null || node.onKeyword == null) {
        usedElements.addElement(element);
      }
    }
    if (stackTraceParameter != null) {
      Element element = stackTraceParameter.staticElement;
      usedElements.addCatchStackTrace(element);
    }
    super.visitCatchClause(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ClassElement enclosingClassOld = _enclosingClass;
    try {
      _enclosingClass = node.declaredElement;
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = enclosingClassOld;
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      usedElements.addElement(node.declaredElement);
    }
    super.visitFunctionExpression(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredElement;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    Element element = node.staticElement;
    bool isIdentifierRead = _isReadIdentifier(node);
    if (element is PropertyAccessorElement &&
        element.isSynthetic &&
        isIdentifierRead &&
        element.variable is TopLevelVariableElement) {
      usedElements.addElement(element.variable);
    } else if (element is LocalVariableElement) {
      if (isIdentifierRead) {
        usedElements.addElement(element);
      }
    } else {
      _useIdentifierElement(node);
      if (element == null ||
          element.enclosingElement is ClassElement &&
              !identical(element, _enclosingExec)) {
        usedElements.members.add(node.name);
        if (isIdentifierRead) {
          usedElements.readMembers.add(node.name);
        }
      }
    }
  }

  /// Marks an [Element] of [node] as used in the library.
  void _useIdentifierElement(Identifier node) {
    Element element = node.staticElement;
    if (element == null) {
      return;
    }
    // check if a local element
    if (!identical(element.library, _enclosingLibrary)) {
      return;
    }
    // ignore references to an element from itself
    if (identical(element, _enclosingClass)) {
      return;
    }
    if (identical(element, _enclosingExec)) {
      return;
    }
    // ignore places where the element is not actually used
    if (node.parent is TypeName) {
      if (element is ClassElement) {
        AstNode parent2 = node.parent.parent;
        if (parent2 is IsExpression) {
          return;
        }
        if (parent2 is VariableDeclarationList) {
          // If it's a field's type, it still counts as used.
          if (parent2.parent is! FieldDeclaration) {
            return;
          }
        }
      }
    }
    // OK
    usedElements.addElement(element);
  }

  static bool _isReadIdentifier(SimpleIdentifier node) {
    // not reading at all
    if (!node.inGetterContext()) {
      return false;
    }
    // check if useless reading
    AstNode parent = node.parent;
    if (parent.parent is ExpressionStatement) {
      if (parent is PrefixExpression || parent is PostfixExpression) {
        // v++;
        // ++v;
        return false;
      }
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        // v ??= doSomething();
        //   vs.
        // v += 2;
        TokenType operatorType = parent.operator?.type;
        return operatorType == TokenType.QUESTION_QUESTION_EQ;
      }
    }
    // OK
    return true;
  }
}

/// Maintains and manages contextual type information used for
/// inferring types.
class InferenceContext {
  // TODO(leafp): Consider replacing these node properties with a
  // hash table help in an instance of this class.
  static const String _typeProperty =
      'analyzer.src.generated.InferenceContext.contextType';

  /// The error listener on which to record inference information.
  final ErrorReporter _errorReporter;

  /// If true, emit hints when types are inferred
  final bool _inferenceHints;

  /// Type provider, needed for type matching.
  final TypeProvider _typeProvider;

  /// The type system in use.
  final TypeSystem _typeSystem;

  /// When no context type is available, this will track the least upper bound
  /// of all return statements in a lambda.
  ///
  /// This will always be kept in sync with [_returnStack].
  final List<DartType> _inferredReturn = <DartType>[];

  /// A stack of return types for all of the enclosing
  /// functions and methods.
  final List<DartType> _returnStack = <DartType>[];

  InferenceContext._(TypeProvider typeProvider, this._typeSystem,
      this._inferenceHints, this._errorReporter)
      : _typeProvider = typeProvider;

  /// Get the return type of the current enclosing function, if any.
  ///
  /// The type returned for a function is the type that is expected
  /// to be used in a return or yield context.  For ordinary functions
  /// this is the same as the return type of the function.  For async
  /// functions returning Future<T> and for generator functions
  /// returning Stream<T> or Iterable<T>, this is T.
  DartType get returnContext =>
      _returnStack.isNotEmpty ? _returnStack.last : null;

  /// Records the type of the expression of a return statement.
  ///
  /// This will be used for inferring a block bodied lambda, if no context
  /// type was available.
  void addReturnOrYieldType(DartType type) {
    if (_returnStack.isEmpty) {
      return;
    }

    DartType inferred = _inferredReturn.last;
    inferred = _typeSystem.getLeastUpperBound(type, inferred);
    _inferredReturn[_inferredReturn.length - 1] = inferred;
  }

  /// Pop a return type off of the return stack.
  ///
  /// Also record any inferred return type using [setType], unless this node
  /// already has a context type. This recorded type will be the least upper
  /// bound of all types added with [addReturnOrYieldType].
  void popReturnContext(FunctionBody node) {
    if (_returnStack.isNotEmpty && _inferredReturn.isNotEmpty) {
      DartType context = _returnStack.removeLast() ?? DynamicTypeImpl.instance;
      DartType inferred = _inferredReturn.removeLast();

      if (_typeSystem.isSubtypeOf(inferred, context)) {
        setType(node, inferred);
      }
    } else {
      assert(false);
    }
  }

  /// Push a block function body's return type onto the return stack.
  void pushReturnContext(FunctionBody node) {
    _returnStack.add(getContext(node));
    _inferredReturn.add(_typeProvider.nullType);
  }

  /// Place an info node into the error stream indicating that a
  /// [type] has been inferred as the type of [node].
  void recordInference(Expression node, DartType type) {
    if (!_inferenceHints) {
      return;
    }

    ErrorCode error;
    if (node is Literal) {
      error = StrongModeCode.INFERRED_TYPE_LITERAL;
    } else if (node is InstanceCreationExpression) {
      error = StrongModeCode.INFERRED_TYPE_ALLOCATION;
    } else if (node is FunctionExpression) {
      error = StrongModeCode.INFERRED_TYPE_CLOSURE;
    } else {
      error = StrongModeCode.INFERRED_TYPE;
    }

    _errorReporter.reportErrorForNode(error, node, [node, type]);
  }

  /// Clear the type information associated with [node].
  static void clearType(AstNode node) {
    node?.setProperty(_typeProperty, null);
  }

  /// Look for contextual type information attached to [node], and returns
  /// the type if found.
  ///
  /// The returned type may be partially or completely unknown, denoted with an
  /// unknown type `?`, for example `List<?>` or `(?, int) -> void`.
  /// You can use [Dart2TypeSystem.upperBoundForType] or
  /// [Dart2TypeSystem.lowerBoundForType] if you would prefer a known type
  /// that represents the bound of the context type.
  static DartType getContext(AstNode node) => node?.getProperty(_typeProperty);

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setType(AstNode node, DartType type) {
    if (type == null || type.isDynamic) {
      clearType(node);
    } else {
      node?.setProperty(_typeProperty, type);
    }
  }

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setTypeFromNode(AstNode innerNode, AstNode outerNode) {
    setType(innerNode, getContext(outerNode));
  }
}

/// The four states of a field initialization state through a constructor
/// signature, not initialized, initialized in the field declaration,
/// initialized in the field formal, and finally, initialized in the
/// initializers list.
class INIT_STATE implements Comparable<INIT_STATE> {
  static const INIT_STATE NOT_INIT = const INIT_STATE('NOT_INIT', 0);

  static const INIT_STATE INIT_IN_DECLARATION =
      const INIT_STATE('INIT_IN_DECLARATION', 1);

  static const INIT_STATE INIT_IN_FIELD_FORMAL =
      const INIT_STATE('INIT_IN_FIELD_FORMAL', 2);

  static const INIT_STATE INIT_IN_INITIALIZERS =
      const INIT_STATE('INIT_IN_INITIALIZERS', 3);

  static const List<INIT_STATE> values = const [
    NOT_INIT,
    INIT_IN_DECLARATION,
    INIT_IN_FIELD_FORMAL,
    INIT_IN_INITIALIZERS
  ];

  /// The name of this init state.
  final String name;

  /// The ordinal value of the init state.
  final int ordinal;

  const INIT_STATE(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(INIT_STATE other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// An AST visitor that is used to re-resolve the initializers of instance
/// fields. Although this class is an AST visitor, clients are expected to use
/// the method [resolveCompilationUnit] to run it over a compilation unit.
class InstanceFieldResolverVisitor extends ResolverVisitor {
  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution. The [nameScope] is the scope used to resolve identifiers in
  /// the node that will first be visited.  If `null` or unspecified, a new
  /// [LibraryScope] will be created based on the [definingLibrary].
  InstanceFieldResolverVisitor(
      InheritanceManager3 inheritance,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      {Scope nameScope})
      : super(inheritance, definingLibrary, source, typeProvider, errorListener,
            featureSet: featureSet, nameScope: nameScope);

  /// Resolve the instance fields in the given compilation unit [node].
  void resolveCompilationUnit(CompilationUnit node) {
    NodeList<CompilationUnitMember> declarations = node.declarations;
    int declarationCount = declarations.length;
    for (int i = 0; i < declarationCount; i++) {
      CompilationUnitMember declaration = declarations[i];
      if (declaration is ClassDeclaration) {
        _resolveClassDeclaration(declaration);
      }
    }
  }

  /// Resolve the instance fields in the given class declaration [node].
  void _resolveClassDeclaration(ClassDeclaration node) {
    _enclosingClassDeclaration = node;
    ClassElement outerType = enclosingClass;
    Scope outerScope = nameScope;
    try {
      enclosingClass = node.declaredElement;
      typeAnalyzer.thisType = enclosingClass?.thisType;
      if (enclosingClass == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for class declaration ${node.name.name} in "
            "${definingLibrary.source.fullName}");
        // Don't try to re-resolve the initializers if we cannot set up the
        // right name scope for resolution.
      } else {
        nameScope = new ClassScope(nameScope, enclosingClass);
        NodeList<ClassMember> members = node.members;
        int length = members.length;
        for (int i = 0; i < length; i++) {
          ClassMember member = members[i];
          if (member is FieldDeclaration) {
            _resolveFieldDeclaration(member);
          }
        }
      }
    } finally {
      nameScope = outerScope;
      typeAnalyzer.thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  /// Resolve the instance fields in the given field declaration [node].
  void _resolveFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) {
      for (VariableDeclaration field in node.fields.variables) {
        if (field.initializer != null) {
          field.initializer.accept(this);
          FieldElement fieldElement = field.name.staticElement;
          if (fieldElement.initializer != null) {
            (fieldElement.initializer as ExecutableElementImpl).returnType =
                field.initializer.staticType;
          }
        }
      }
    }
  }
}

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor {
  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritance;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current class or mixin.
  InterfaceType _currentType;

  OverrideVerifier(
      this._inheritance, LibraryElement library, this._errorReporter)
      : _libraryUri = library.source.uri;

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _currentType = node.declaredElement.thisType;
    super.visitClassDeclaration(node);
    _currentType = null;
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    for (VariableDeclaration field in node.fields.variables) {
      FieldElement fieldElement = field.declaredElement;
      if (fieldElement.hasOverride) {
        PropertyAccessorElement getter = fieldElement.getter;
        if (getter != null && _isOverride(getter)) continue;

        PropertyAccessorElement setter = fieldElement.setter;
        if (setter != null && _isOverride(setter)) continue;

        _errorReporter.reportErrorForNode(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD,
          field.name,
        );
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.declaredElement;
    if (element.hasOverride && !_isOverride(element)) {
      if (element is MethodElement) {
        _errorReporter.reportErrorForNode(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD,
          node.name,
        );
      } else if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          _errorReporter.reportErrorForNode(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER,
            node.name,
          );
        } else {
          _errorReporter.reportErrorForNode(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER,
            node.name,
          );
        }
      }
    }
  }

  @override
  visitMixinDeclaration(MixinDeclaration node) {
    _currentType = node.declaredElement.thisType;
    super.visitMixinDeclaration(node);
    _currentType = null;
  }

  /// Return `true` if the [member] overrides a member from a superinterface.
  bool _isOverride(ExecutableElement member) {
    var name = new Name(_libraryUri, member.name);
    return _inheritance.getOverridden(_currentType, name) != null;
  }
}

/// An AST visitor that is used to resolve some of the nodes within a single
/// compilation unit. The nodes that are skipped are those that are within
/// function bodies.
class PartialResolverVisitor extends ResolverVisitor {
  /// The static variables and fields that have an initializer. These are the
  /// variables that need to be re-resolved after static variables have their
  /// types inferred. A subset of these variables are those whose types should
  /// be inferred.
  final List<VariableElement> staticVariables = <VariableElement>[];

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution. The [nameScope] is the scope used to resolve identifiers in
  /// the node that will first be visited.  If `null` or unspecified, a new
  /// [LibraryScope] will be created based on [definingLibrary] and
  /// [typeProvider].
  PartialResolverVisitor(
      InheritanceManager3 inheritance,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      {Scope nameScope})
      : super(inheritance, definingLibrary, source, typeProvider, errorListener,
            featureSet: featureSet, nameScope: nameScope);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    if (_shouldBeSkipped(node)) {
      return null;
    }
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_shouldBeSkipped(node)) {
      return null;
    }
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) {
      _addStaticVariables(node.fields.variables);
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _addStaticVariables(node.variables.variables);
    super.visitTopLevelVariableDeclaration(node);
  }

  /// Add all of the [variables] with initializers to the list of variables
  /// whose type can be inferred. Technically, we only infer the types of
  /// variables that do not have a static type, but all variables with
  /// initializers potentially need to be re-resolved after inference because
  /// they might refer to a field whose type was inferred.
  void _addStaticVariables(List<VariableDeclaration> variables) {
    int length = variables.length;
    for (int i = 0; i < length; i++) {
      VariableDeclaration variable = variables[i];
      if (variable.name.name.isNotEmpty && variable.initializer != null) {
        staticVariables.add(variable.declaredElement);
      }
    }
  }

  /// Return `true` if the given function body should be skipped because it is
  /// the body of a top-level function, method or constructor.
  bool _shouldBeSkipped(FunctionBody body) {
    AstNode parent = body.parent;
    if (parent is MethodDeclaration) {
      return parent.body == body;
    }
    if (parent is ConstructorDeclaration) {
      return parent.body == body;
    }
    if (parent is FunctionExpression) {
      AstNode parent2 = parent.parent;
      if (parent2 is FunctionDeclaration &&
          parent2.parent is! FunctionDeclarationStatement) {
        return parent.body == body;
      }
    }
    return false;
  }
}

/// The enumeration `ResolverErrorCode` defines the error codes used for errors
/// detected by the resolver. The convention for this class is for the name of
/// the error code to indicate the problem that caused the error to be generated
/// and for the error message to explain what is wrong and, when appropriate,
/// how the problem can be corrected.
class ResolverErrorCode extends ErrorCode {
  static const ResolverErrorCode BREAK_LABEL_ON_SWITCH_MEMBER =
      const ResolverErrorCode('BREAK_LABEL_ON_SWITCH_MEMBER',
          "Break label resolves to case or default statement");

  static const ResolverErrorCode CONTINUE_LABEL_ON_SWITCH =
      const ResolverErrorCode('CONTINUE_LABEL_ON_SWITCH',
          "A continue label resolves to switch, must be loop or switch member");

  /// Parts: It is a static warning if the referenced part declaration
  /// <i>p</i> names a library that does not have a library tag.
  ///
  /// Parameters:
  /// 0: the URI of the expected library
  /// 1: the non-matching actual library name from the "part of" declaration
  static const ResolverErrorCode PART_OF_UNNAMED_LIBRARY =
      const ResolverErrorCode(
          'PART_OF_UNNAMED_LIBRARY',
          "Library is unnamed. Expected a URI not a library name '{0}' in the "
              "part-of directive.",
          correction:
              "Try changing the part-of directive to a URI, or try including a"
              " different part.");

  /// Initialize a newly created error code to have the given [name]. The
  /// message associated with the error will be created from the given [message]
  /// template. The correction associated with the error will be created from
  /// the given [correction] template.
  const ResolverErrorCode(String name, String message,
      {String correction, bool hasPublishedDocs})
      : super.temporary(name, message,
            correction: correction,
            hasPublishedDocs: hasPublishedDocs ?? false);

  @override
  ErrorSeverity get errorSeverity => type.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ScopedVisitor {
  /**
   * The manager for the inheritance mappings.
   */
  final InheritanceManager3 inheritance;

  final AnalysisOptionsImpl _analysisOptions;

  /**
   * The feature set that is enabled for the current unit.
   */
  final FeatureSet _featureSet;

  final bool _uiAsCodeEnabled;

  /// Helper for extension method resolution.
  ExtensionMemberResolver extensionResolver;

  /// The object used to resolve the element associated with the current node.
  ElementResolver elementResolver;

  /// The object used to compute the type associated with the current node.
  StaticTypeAnalyzer typeAnalyzer;

  /// The type system in use during resolution.
  Dart2TypeSystem typeSystem;

  /// The class declaration representing the class containing the current node,
  /// or `null` if the current node is not contained in a class.
  ClassDeclaration _enclosingClassDeclaration;

  /// The function type alias representing the function type containing the
  /// current node, or `null` if the current node is not contained in a function
  /// type alias.
  FunctionTypeAlias _enclosingFunctionTypeAlias;

  /// The element representing the function containing the current node, or
  /// `null` if the current node is not contained in a function.
  ExecutableElement _enclosingFunction;

  /// The mixin declaration representing the class containing the current node,
  /// or `null` if the current node is not contained in a mixin.
  MixinDeclaration _enclosingMixinDeclaration;

  InferenceContext inferenceContext;

  /// The object keeping track of which elements have had their types promoted.
  TypePromotionManager _promoteManager;

  final FlowAnalysisHelper _flowAnalysis;

  /// A comment before a function should be resolved in the context of the
  /// function. But when we incrementally resolve a comment, we don't want to
  /// resolve the whole function.
  ///
  /// So, this flag is set to `true`, when just context of the function should
  /// be built and the comment resolved.
  bool resolveOnlyCommentInFunctionBody = false;

  /// The type of the expression of the immediately enclosing [SwitchStatement],
  /// or `null` if not in a [SwitchStatement].
  DartType _enclosingSwitchStatementExpressionType;

  InterfaceType _iterableForSetMapDisambiguationCached;
  InterfaceType _mapForSetMapDisambiguationCached;

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution. The [nameScope] is the scope used to resolve identifiers in
  /// the node that will first be visited.  If `null` or unspecified, a new
  /// [LibraryScope] will be created based on [definingLibrary] and
  /// [typeProvider].
  ///
  /// TODO(paulberry): make [featureSet] a required parameter (this will be a
  /// breaking change).
  ResolverVisitor(
      InheritanceManager3 inheritanceManager,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      {FeatureSet featureSet,
      Scope nameScope,
      bool propagateTypes: true,
      reportConstEvaluationErrors: true,
      FlowAnalysisHelper flowAnalysisHelper})
      : this._(
            inheritanceManager,
            definingLibrary,
            source,
            typeProvider,
            errorListener,
            featureSet ??
                definingLibrary.context.analysisOptions.contextFeatures,
            nameScope,
            propagateTypes,
            reportConstEvaluationErrors,
            flowAnalysisHelper);

  ResolverVisitor._(
      this.inheritance,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      Scope nameScope,
      bool propagateTypes,
      reportConstEvaluationErrors,
      this._flowAnalysis)
      : _analysisOptions = definingLibrary.context.analysisOptions,
        _featureSet = featureSet,
        _uiAsCodeEnabled =
            featureSet.isEnabled(Feature.control_flow_collections) ||
                featureSet.isEnabled(Feature.spread_collections),
        super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    this.typeSystem = definingLibrary.context.typeSystem;
    this._promoteManager = TypePromotionManager(typeSystem);
    this.extensionResolver = ExtensionMemberResolver(this);
    this.elementResolver = new ElementResolver(this,
        reportConstEvaluationErrors: reportConstEvaluationErrors);
    bool strongModeHints = false;
    AnalysisOptions options = _analysisOptions;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
    }
    this.inferenceContext = new InferenceContext._(
        typeProvider, typeSystem, strongModeHints, errorReporter);
    this.typeAnalyzer = new StaticTypeAnalyzer(this, featureSet, _flowAnalysis);
  }

  /// Return the element representing the function containing the current node,
  /// or `null` if the current node is not contained in a function.
  ///
  /// @return the element representing the function containing the current node
  ExecutableElement get enclosingFunction => _enclosingFunction;

  /// Return the object providing promoted or declared types of variables.
  LocalVariableTypeProvider get localVariableTypeProvider {
    if (_flowAnalysis != null) {
      return _flowAnalysis.localVariableTypeProvider;
    } else {
      return _promoteManager.localVariableTypeProvider;
    }
  }

  NullabilitySuffix get noneOrStarSuffix {
    return _nonNullableEnabled
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  InterfaceType get _iterableForSetMapDisambiguation {
    return _iterableForSetMapDisambiguationCached ??=
        typeProvider.iterableElement.instantiate(
      typeArguments: [
        typeProvider.dynamicType,
      ],
      nullabilitySuffix: _nonNullableEnabled
          ? NullabilitySuffix.question
          : NullabilitySuffix.star,
    );
  }

  InterfaceType get _mapForSetMapDisambiguation {
    return _mapForSetMapDisambiguationCached ??=
        typeProvider.mapElement.instantiate(
      typeArguments: [
        typeProvider.dynamicType,
        typeProvider.dynamicType,
      ],
      nullabilitySuffix: _nonNullableEnabled
          ? NullabilitySuffix.question
          : NullabilitySuffix.star,
    );
  }

  /**
   * Return `true` if NNBD is enabled for this compilation unit.
   */
  bool get _nonNullableEnabled => _featureSet.isEnabled(Feature.non_nullable);

  /// Return the static element associated with the given expression whose type
  /// can be overridden, or `null` if there is no element whose type can be
  /// overridden.
  ///
  /// @param expression the expression with which the element is associated
  /// @return the element associated with the given expression
  VariableElement getOverridableStaticElement(Expression expression) {
    Element element;
    if (expression is SimpleIdentifier) {
      element = expression.staticElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is VariableElement) {
      return element;
    }
    return null;
  }

  /// Given a downward inference type [fnType], and the declared
  /// [typeParameterList] for a function expression, determines if we can enable
  /// downward inference and if so, returns the function type to use for
  /// inference.
  ///
  /// This will return null if inference is not possible. This happens when
  /// there is no way we can find a subtype of the function type, given the
  /// provided type parameter list.
  FunctionType matchFunctionTypeParameters(
      TypeParameterList typeParameterList, FunctionType fnType) {
    if (typeParameterList == null) {
      if (fnType.typeFormals.isEmpty) {
        return fnType;
      }

      // A non-generic function cannot be a subtype of a generic one.
      return null;
    }

    NodeList<TypeParameter> typeParameters = typeParameterList.typeParameters;
    if (fnType.typeFormals.isEmpty) {
      // TODO(jmesserly): this is a legal subtype. We don't currently infer
      // here, but we could.  This is similar to
      // Dart2TypeSystem.inferFunctionTypeInstantiation, but we don't
      // have the FunctionType yet for the current node, so it's not quite
      // straightforward to apply.
      return null;
    }

    if (fnType.typeFormals.length != typeParameters.length) {
      // A subtype cannot have different number of type formals.
      return null;
    }

    // Same number of type formals. Instantiate the function type so its
    // parameter and return type are in terms of the surrounding context.
    return fnType.instantiate(typeParameters.map((TypeParameter t) {
      return t.declaredElement.instantiate(
        nullabilitySuffix: noneOrStarSuffix,
      );
    }).toList());
  }

  /// If it is appropriate to do so, override the current type of the static
  /// element associated with the given expression with the given type.
  /// Generally speaking, it is appropriate if the given type is more specific
  /// than the current type.
  ///
  /// @param expression the expression used to access the static element whose
  ///        types might be overridden
  /// @param potentialType the potential type of the elements
  /// @param allowPrecisionLoss see @{code overrideVariable} docs
  void overrideExpression(Expression expression, DartType potentialType,
      bool allowPrecisionLoss, bool setExpressionType) {
    // TODO(brianwilkerson) Remove this method.
  }

  /// Set the enclosing function body when partial AST is resolved.
  void prepareCurrentFunctionBody(FunctionBody body) {
    _promoteManager.enterFunctionBody(body);
  }

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
  }) {
    _enclosingClassDeclaration = null;
    enclosingClass = enclosingClassElement;
    typeAnalyzer.thisType = enclosingClass?.thisType;
    _enclosingFunction = enclosingExecutableElement;
  }

  /// A client is about to resolve a member in the given class declaration.
  void prepareToResolveMembersInClass(ClassDeclaration node) {
    _enclosingClassDeclaration = node;
    enclosingClass = node.declaredElement;
    typeAnalyzer.thisType = enclosingClass?.thisType;
  }

  /// Visit the given [comment] if it is not `null`.
  void safelyVisitComment(Comment comment) {
    if (comment != null) {
      super.visitComment(comment);
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    AstNode parent = node.parent;
    if (identical(parent, _enclosingClassDeclaration) ||
        identical(parent, _enclosingFunctionTypeAlias) ||
        identical(parent, _enclosingMixinDeclaration)) {
      return;
    }
    node.name?.accept(this);
    node.constructorName?.accept(this);
    Element element = node.element;
    if (element is ExecutableElement) {
      InferenceContext.setType(node.arguments, element.type);
    }
    node.arguments?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    ElementAnnotationImpl elementAnnotationImpl = node.elementAnnotation;
    if (elementAnnotationImpl == null) {
      // Analyzer ignores annotations on "part of" directives.
      assert(parent is PartOfDirective);
    } else {
      elementAnnotationImpl.annotationAst = _createCloner().cloneNode(node);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    DartType callerType = InferenceContext.getContext(node);
    if (callerType is FunctionType) {
      Map<String, DartType> namedParameterTypes =
          callerType.namedParameterTypes;
      List<DartType> normalParameterTypes = callerType.normalParameterTypes;
      List<DartType> optionalParameterTypes = callerType.optionalParameterTypes;
      int normalCount = normalParameterTypes.length;
      int optionalCount = optionalParameterTypes.length;

      NodeList<Expression> arguments = node.arguments;
      Iterable<Expression> positional =
          arguments.takeWhile((l) => l is! NamedExpression);
      Iterable<Expression> required = positional.take(normalCount);
      Iterable<Expression> optional =
          positional.skip(normalCount).take(optionalCount);
      Iterable<Expression> named =
          arguments.skipWhile((l) => l is! NamedExpression);

      //TODO(leafp): Consider using the parameter elements here instead.
      //TODO(leafp): Make sure that the parameter elements are getting
      // setup correctly with inference.
      int index = 0;
      for (Expression argument in required) {
        InferenceContext.setType(argument, normalParameterTypes[index++]);
      }
      index = 0;
      for (Expression argument in optional) {
        InferenceContext.setType(argument, optionalParameterTypes[index++]);
      }

      for (Expression argument in named) {
        if (argument is NamedExpression) {
          DartType type = namedParameterTypes[argument.name.label.name];
          if (type != null) {
            InferenceContext.setType(argument, type);
          }
        }
      }
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    _flowAnalysis?.asExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    _flowAnalysis?.flow?.assert_begin();
    node.condition?.accept(this);
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    _flowAnalysis?.flow?.assert_begin();
    node.condition?.accept(this);
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    left?.accept(this);

    var leftLocalVariable = _flowAnalysis?.assignmentExpression(node);

    TokenType operator = node.operator.type;
    if (operator == TokenType.EQ ||
        operator == TokenType.QUESTION_QUESTION_EQ) {
      InferenceContext.setType(right, left.staticType);
    }

    right?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.assignmentExpression_afterRight(
        node,
        leftLocalVariable,
        operator == TokenType.QUESTION_QUESTION_EQ
            ? node.rightHandSide.staticType
            : node.staticType);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    DartType contextType = InferenceContext.getContext(node);
    if (contextType != null) {
      var futureUnion = _createFutureOr(contextType);
      InferenceContext.setType(node.expression, futureUnion);
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    TokenType operator = node.operator.type;
    Expression left = node.leftOperand;
    Expression right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      InferenceContext.setType(left, typeProvider.boolType);
      InferenceContext.setType(right, typeProvider.boolType);

      // TODO(scheglov) Do we need these checks for null?
      left?.accept(this);

      if (_flowAnalysis != null) {
        flow?.logicalBinaryOp_rightBegin(left, isAnd: true);
        _flowAnalysis.checkUnreachableNode(right);
        right.accept(this);
        flow?.logicalBinaryOp_end(node, right, isAnd: true);
      } else {
        _promoteManager.visitBinaryExpression_and_rhs(
          left,
          right,
          () {
            right.accept(this);
          },
        );
      }

      node.accept(elementResolver);
    } else if (operator == TokenType.BAR_BAR) {
      InferenceContext.setType(left, typeProvider.boolType);
      InferenceContext.setType(right, typeProvider.boolType);

      left?.accept(this);

      flow?.logicalBinaryOp_rightBegin(left, isAnd: false);
      _flowAnalysis?.checkUnreachableNode(right);
      right.accept(this);
      flow?.logicalBinaryOp_end(node, right, isAnd: false);

      node.accept(elementResolver);
    } else if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
      left.accept(this);
      _flowAnalysis?.flow?.equalityOp_rightBegin(left);
      right.accept(this);
      node.accept(elementResolver);
      _flowAnalysis?.flow?.equalityOp_end(node, right,
          notEqual: operator == TokenType.BANG_EQ);
    } else {
      if (operator == TokenType.QUESTION_QUESTION) {
        InferenceContext.setTypeFromNode(left, node);
      }
      left?.accept(this);

      // Call ElementResolver.visitBinaryExpression to resolve the user-defined
      // operator method, if applicable.
      node.accept(elementResolver);

      if (operator == TokenType.QUESTION_QUESTION) {
        // Set the right side, either from the context, or using the information
        // from the left side if it is more precise.
        DartType contextType = InferenceContext.getContext(node);
        DartType leftType = left?.staticType;
        if (contextType == null || contextType.isDynamic) {
          contextType = leftType;
        }
        InferenceContext.setType(right, contextType);
      } else {
        var invokeType = node.staticInvokeType;
        if (invokeType != null && invokeType.parameters.isNotEmpty) {
          // If this is a user-defined operator, set the right operand context
          // using the operator method's parameter type.
          var rightParam = invokeType.parameters[0];
          InferenceContext.setType(right, rightParam.type);
        }
      }

      if (operator == TokenType.QUESTION_QUESTION) {
        flow?.ifNullExpression_rightBegin(node.leftOperand);
        right.accept(this);
        flow?.ifNullExpression_end();
      } else {
        right?.accept(this);
      }
    }
    node.accept(typeAnalyzer);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    try {
      inferenceContext.pushReturnContext(node);
      super.visitBlockFunctionBody(node);
    } finally {
      inferenceContext.popReturnContext(node);
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _flowAnalysis?.flow?.booleanLiteral(node, node.value);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.breakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    InferenceContext.setTypeFromNode(node.target, node);
    super.visitCascadeExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    node.metadata?.accept(this);
    _enclosingClassDeclaration = node;
    //
    // Continue the class resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  @override
  void visitComment(Comment node) {
    AstNode parent = node.parent;
    if (parent is FunctionDeclaration ||
        parent is FunctionTypeAlias ||
        parent is ConstructorDeclaration ||
        parent is MethodDeclaration) {
      return;
    }
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    //
    // We do not visit the identifier because it needs to be visited in the
    // context of the reference.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    NodeList<Directive> directives = node.directives;
    int directiveCount = directives.length;
    for (int i = 0; i < directiveCount; i++) {
      directives[i].accept(this);
    }
    NodeList<CompilationUnitMember> declarations = node.declarations;
    int declarationCount = declarations.length;
    for (int i = 0; i < declarationCount; i++) {
      declarations[i].accept(this);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    var flow = _flowAnalysis?.flow;

    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);

    Expression thenExpression = node.thenExpression;
    InferenceContext.setTypeFromNode(thenExpression, node);

    if (_flowAnalysis != null) {
      if (flow != null) {
        flow.conditional_thenBegin(condition);
        _flowAnalysis.checkUnreachableNode(thenExpression);
      }
      thenExpression.accept(this);
    } else {
      _promoteManager.visitConditionalExpression_then(
        condition,
        thenExpression,
        () {
          thenExpression.accept(this);
        },
      );
    }

    Expression elseExpression = node.elseExpression;
    InferenceContext.setTypeFromNode(elseExpression, node);

    if (flow != null) {
      flow.conditional_elseBegin(thenExpression);
      _flowAnalysis.checkUnreachableNode(elseExpression);
      elseExpression.accept(this);
      flow.conditional_end(node, elseExpression);
    } else {
      elseExpression.accept(this);
    }

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _flowAnalysis?.topLevelDeclaration_enter(
          node, node.parameters, node.body);
      _flowAnalysis?.executableDeclaration_enter(node, node.parameters, false);
      _promoteManager.enterFunctionBody(node.body);
      _enclosingFunction = node.declaredElement;
      FunctionType type = _enclosingFunction.type;
      InferenceContext.setType(node.body, type.returnType);
      super.visitConstructorDeclaration(node);
    } finally {
      _flowAnalysis?.executableDeclaration_exit(node.body, false);
      _flowAnalysis?.topLevelDeclaration_exit();
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
    ConstructorElementImpl constructor = node.declaredElement;
    constructor.constantInitializers =
        _createCloner().cloneNodeList(node.initializers);
  }

  @override
  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    super.visitConstructorDeclarationInScope(node);
    // Because of needing a different scope for the initializer list, the
    // overridden implementation of this method cannot cause the visitNode
    // method to be invoked. As a result, we have to hard-code using the
    // element resolver and type analyzer to visit the constructor declaration.
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    FieldElement fieldElement = enclosingClass.getField(node.fieldName.name);
    InferenceContext.setType(node.expression, fieldElement?.type);
    node.expression?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    //
    // We do not visit either the type name, because it won't be visited anyway,
    // or the name, because it needs to be visited in the context of the
    // constructor name.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.continueStatement(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    InferenceContext.setType(node.defaultValue, node.declaredElement?.type);
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.declaredElement;

    if (element.initializer != null && node.defaultValue != null) {
      (element.initializer as FunctionElementImpl).returnType =
          node.defaultValue.staticType;
    }
    // Clone the ASTs for default formal parameters, so that we can use them
    // during constant evaluation.
    if (element is ConstVariableElement &&
        !_hasSerializedConstantInitializer(element)) {
      (element as ConstVariableElement).constantInitializer =
          _createCloner().cloneNode(node.defaultValue);
    }
  }

  @override
  void visitDoStatementInScope(DoStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    var body = node.body;
    var condition = node.condition;

    InferenceContext.setType(node.condition, typeProvider.boolType);

    _flowAnalysis?.flow?.doStatement_bodyBegin(node);
    visitStatementInScope(body);

    _flowAnalysis?.flow?.doStatement_conditionBegin();
    condition.accept(this);

    _flowAnalysis?.flow?.doStatement_end(node.condition);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    //
    // Resolve the metadata in the library scope
    // and associate the annotations with the element.
    //
    if (node.metadata != null) {
      node.metadata.accept(this);
      ElementResolver.resolveMetadata(node);
      node.constants.forEach(ElementResolver.resolveMetadata);
    }
    //
    // Continue the enum resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }
    try {
      InferenceContext.setTypeFromNode(node.expression, node);
      inferenceContext.pushReturnContext(node);
      super.visitExpressionFunctionBody(node);

      DartType type = node.expression.staticType;
      if (_enclosingFunction.isAsynchronous) {
        type = typeSystem.flatten(type);
      }
      if (type != null) {
        inferenceContext.addReturnOrYieldType(type);
      }
    } finally {
      inferenceContext.popReturnContext(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    //
    // Resolve the metadata in the library scope
    // and associate the annotations with the element.
    //
    if (node.metadata != null) {
      node.metadata.accept(this);
      ElementResolver.resolveMetadata(node);
    }
    //
    // Continue the extension resolution.
    //
    try {
      typeAnalyzer.thisType = node.declaredElement.extendedType;
      super.visitExtensionDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = null;
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);

    ExtensionMemberResolver(this).setOverrideReceiverContextType(node);
    node.argumentList.accept(this);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitForElementInScope(ForElement node) {
    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(this);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      }
      var condition = forLoopParts.condition;
      InferenceContext.setType(condition, typeProvider.boolType);
      _flowAnalysis?.for_conditionBegin(node, condition);
      condition?.accept(this);
      _flowAnalysis?.for_bodyBegin(node, condition);
      node.body?.accept(this);
      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(this);
      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      DartType valueType;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
        valueType = loopVariable?.type?.type ?? UnknownInferredType.instance;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        SimpleIdentifier identifier = forLoopParts.identifier;
        identifier?.accept(this);
        identifierElement = identifier?.staticElement;
        if (identifierElement is VariableElement) {
          valueType = identifierElement.type;
        } else if (identifierElement is PropertyAccessorElement) {
          if (identifierElement.parameters.isNotEmpty) {
            valueType = identifierElement.parameters[0].type;
          }
        }
      }

      if (valueType != null) {
        InterfaceType targetType = (node.awaitKeyword == null)
            ? typeProvider.iterableType2(valueType)
            : typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop
      // variable cannot be in scope while visiting the iterator.
      //
      iterable?.accept(this);
      // Note: the iterable could have been rewritten so grab it from
      // forLoopParts again.
      iterable = forLoopParts.iterable;
      loopVariable?.accept(this);
      var elementType = typeAnalyzer.computeForEachElementType(
          iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }
      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable.declaredElement,
          elementType ?? typeProvider.dynamicType);
      node.body?.accept(this);
      _flowAnalysis?.flow?.forEach_end();

      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    }
  }

  @override
  void visitForStatementInScope(ForStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(this);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      }

      var condition = forLoopParts.condition;
      InferenceContext.setType(condition, typeProvider.boolType);

      _flowAnalysis?.for_conditionBegin(node, condition);
      if (condition != null) {
        condition.accept(this);
      }

      _flowAnalysis?.for_bodyBegin(node, condition);
      visitStatementInScope(node.body);

      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(this);

      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      SimpleIdentifier identifier;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        identifier = forLoopParts.identifier;
        identifier?.accept(this);
      }

      DartType valueType;
      if (loopVariable != null) {
        TypeAnnotation typeAnnotation = loopVariable.type;
        valueType = typeAnnotation?.type ?? UnknownInferredType.instance;
      }
      if (identifier != null) {
        identifierElement = identifier.staticElement;
        if (identifierElement is VariableElement) {
          valueType = identifierElement.type;
        } else if (identifierElement is PropertyAccessorElement) {
          if (identifierElement.parameters.isNotEmpty) {
            valueType = identifierElement.parameters[0].type;
          }
        }
      }
      if (valueType != null) {
        InterfaceType targetType = (node.awaitKeyword == null)
            ? typeProvider.iterableType2(valueType)
            : typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop variable
      // cannot be in scope while visiting the iterator.
      //
      iterable?.accept(this);
      // Note: the iterable could have been rewritten so grab it from
      // forLoopParts again.
      iterable = forLoopParts.iterable;
      loopVariable?.accept(this);
      var elementType = typeAnalyzer.computeForEachElementType(
          iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }

      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable?.declaredElement,
          elementType ?? typeProvider.dynamicType);

      Statement body = node.body;
      if (body != null) {
        visitStatementInScope(body);
      }

      _flowAnalysis?.flow?.forEach_end();

      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    bool isFunctionDeclarationStatement =
        node.parent is FunctionDeclarationStatement;
    try {
      SimpleIdentifier functionName = node.name;
      if (_flowAnalysis != null) {
        if (isFunctionDeclarationStatement) {
          _flowAnalysis.flow.functionExpression_begin(node);
        } else {
          _flowAnalysis.topLevelDeclaration_enter(node,
              node.functionExpression.parameters, node.functionExpression.body);
        }
        _flowAnalysis.executableDeclaration_enter(node,
            node.functionExpression.parameters, isFunctionDeclarationStatement);
      }
      _promoteManager.enterFunctionBody(node.functionExpression.body);
      _enclosingFunction = functionName.staticElement as ExecutableElement;
      InferenceContext.setType(
          node.functionExpression, _enclosingFunction.type);
      super.visitFunctionDeclaration(node);
    } finally {
      if (_flowAnalysis != null) {
        _flowAnalysis.executableDeclaration_exit(
            node.functionExpression.body, isFunctionDeclarationStatement);
        if (isFunctionDeclarationStatement) {
          _flowAnalysis.flow.functionExpression_end();
        } else {
          _flowAnalysis.topLevelDeclaration_exit();
        }
      }
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    bool isFunctionDeclaration = node.parent is FunctionDeclaration;
    try {
      if (_flowAnalysis != null) {
        if (!isFunctionDeclaration) {
          _flowAnalysis.flow.functionExpression_begin(node);
        }
      } else {
        _promoteManager.enterFunctionBody(node.body);
      }

      _enclosingFunction = node.declaredElement;
      DartType functionType = InferenceContext.getContext(node);
      if (functionType is FunctionType) {
        functionType =
            matchFunctionTypeParameters(node.typeParameters, functionType);
        if (functionType is FunctionType) {
          _inferFormalParameterList(node.parameters, functionType);
          InferenceContext.setType(
              node.body, _computeReturnOrYieldType(functionType.returnType));
        }
      }
      super.visitFunctionExpression(node);
    } finally {
      if (_flowAnalysis != null) {
        if (!isFunctionDeclaration) {
          _flowAnalysis.flow?.functionExpression_end();
        }
      } else {
        _promoteManager.exitFunctionBody();
      }

      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function?.accept(this);
    node.accept(elementResolver);
    _visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // Resolve the metadata in the library scope.
    if (node.metadata != null) {
      node.metadata.accept(this);
    }
    FunctionTypeAlias outerAlias = _enclosingFunctionTypeAlias;
    _enclosingFunctionTypeAlias = node;
    try {
      super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingFunctionTypeAlias = outerAlias;
    }
  }

  @override
  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAliasInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitGenericTypeAliasInFunctionScope(GenericTypeAlias node) {
    super.visitGenericTypeAliasInFunctionScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

  @override
  void visitIfElement(IfElement node) {
    Expression condition = node.condition;
    InferenceContext.setType(condition, typeProvider.boolType);
    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);
    CollectionElement thenElement = node.thenElement;
    _promoteManager.visitIfElement_thenElement(
      condition,
      thenElement,
      () {
        thenElement.accept(this);
      },
    );
    node.elseElement?.accept(this);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    Expression condition = node.condition;

    InferenceContext.setType(condition, typeProvider.boolType);
    condition?.accept(this);

    Statement thenStatement = node.thenStatement;
    if (_flowAnalysis != null) {
      _flowAnalysis.flow.ifStatement_thenBegin(condition);
      visitStatementInScope(thenStatement);
    } else {
      _promoteManager.visitIfStatement_thenStatement(
        condition,
        thenStatement,
        () {
          visitStatementInScope(thenStatement);
        },
      );
    }

    Statement elseStatement = node.elseStatement;
    if (elseStatement != null) {
      _flowAnalysis?.flow?.ifStatement_elseBegin();
      visitStatementInScope(elseStatement);
    }

    _flowAnalysis?.flow?.ifStatement_end(elseStatement != null);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    if (node.isNullAware) {
      _flowAnalysis?.flow?.nullAwareAccess_rightBegin(node.target);
    }
    node.accept(elementResolver);
    var method = node.staticElement;
    if (method != null && method.parameters.isNotEmpty) {
      var indexParam = node.staticElement.parameters[0];
      InferenceContext.setType(node.index, indexParam.type);
    }
    node.index?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.constructorName?.accept(this);
    _inferArgumentTypesForInstanceCreate(node);
    node.argumentList?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIsExpression(IsExpression node) {
    super.visitIsExpression(node);
    _flowAnalysis?.isExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitListLiteral(ListLiteral node) {
    InterfaceType listType;

    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (typeArguments.arguments.length == 1) {
        DartType elementType = typeArguments.arguments[0].type;
        if (!elementType.isDynamic) {
          listType = typeProvider.listType2(elementType);
        }
      }
    } else {
      listType = typeAnalyzer.inferListType(node, downwards: true);
    }
    if (listType != null) {
      DartType elementType = listType.typeArguments[0];
      DartType iterableType = typeProvider.iterableType2(elementType);
      _pushCollectionTypesDownToAll(node.elements,
          elementType: elementType, iterableType: iterableType);
      InferenceContext.setType(node, listType);
    } else {
      InferenceContext.clearType(node);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _flowAnalysis?.topLevelDeclaration_enter(
          node, node.parameters, node.body);
      _flowAnalysis?.executableDeclaration_enter(node, node.parameters, false);
      _promoteManager.enterFunctionBody(node.body);
      _enclosingFunction = node.declaredElement;
      DartType returnType =
          _computeReturnOrYieldType(_enclosingFunction.type?.returnType);
      InferenceContext.setType(node.body, returnType);
      super.visitMethodDeclaration(node);
    } finally {
      _flowAnalysis?.executableDeclaration_exit(node.body, false);
      _flowAnalysis?.topLevelDeclaration_exit();
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    //
    // We visit the target and argument list, but do not visit the method name
    // because it needs to be visited in the context of the invocation.
    //
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.accept(elementResolver);

    var functionRewrite = MethodInvocationResolver.getRewriteResult(node);
    if (functionRewrite != null) {
      _visitFunctionExpressionInvocation(functionRewrite);
    } else {
      _inferArgumentTypesForInvocation(node);
      node.argumentList?.accept(this);
      node.accept(typeAnalyzer);
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    node.metadata?.accept(this);
    _enclosingMixinDeclaration = node;
    //
    // Continue the class resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitMixinDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingMixinDeclaration = null;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitNamedExpression(node);
  }

  @override
  void visitNode(AstNode node) {
    _flowAnalysis?.checkUnreachableNode(node);
    node.visitChildren(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _flowAnalysis?.flow?.nullLiteral(node);
    super.visitNullLiteral(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitParenthesizedExpression(node);
    _flowAnalysis?.flow?.parenthesizedExpression(node, node.expression);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _flowAnalysis?.flow?.nonNullAssert_end(node.operand);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    //
    // We visit the prefix, but do not visit the identifier because it needs to
    // be visited in the context of the prefix.
    //
    node.prefix?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _flowAnalysis?.flow?.logicalNot_end(node, node.operand);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    //
    // We visit the target, but do not visit the property name because it needs
    // to be visited in the context of the property access node.
    //
    node.target?.accept(this);
    if (node.isNullAware) {
      _flowAnalysis?.flow?.nullAwareAccess_rightBegin(node.target);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    super.visitRethrowExpression(node);
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    InferenceContext.setType(node.expression, inferenceContext.returnContext);
    super.visitReturnStatement(node);
    DartType type = node.expression?.staticType;
    // Generators cannot return values, so don't try to do any inference if
    // we're processing erroneous code.
    if (type != null && _enclosingFunction?.isGenerator == false) {
      if (_enclosingFunction.isAsynchronous) {
        type = typeSystem.flatten(type);
      }
      inferenceContext.addReturnOrYieldType(type);
    }
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments?.arguments;
    InterfaceType literalType;
    var literalResolution = _computeSetOrMapResolution(node);
    if (literalResolution.kind == _LiteralResolutionKind.set) {
      if (typeArguments != null && typeArguments.length == 1) {
        var elementType = typeArguments[0].type;
        literalType = typeProvider.setType2(elementType);
      } else {
        literalType = typeAnalyzer.inferSetTypeDownwards(
            node, literalResolution.contextType);
      }
    } else if (literalResolution.kind == _LiteralResolutionKind.map) {
      if (typeArguments != null && typeArguments.length == 2) {
        var keyType = typeArguments[0].type;
        var valueType = typeArguments[1].type;
        literalType = typeProvider.mapType2(keyType, valueType);
      } else {
        literalType = typeAnalyzer.inferMapTypeDownwards(
            node, literalResolution.contextType);
      }
    } else {
      assert(literalResolution.kind == _LiteralResolutionKind.ambiguous);
      literalType = null;
    }
    if (literalType is InterfaceType) {
      List<DartType> typeArguments = literalType.typeArguments;
      if (typeArguments.length == 1) {
        DartType elementType = literalType.typeArguments[0];
        DartType iterableType = typeProvider.iterableType2(elementType);
        _pushCollectionTypesDownToAll(node.elements,
            elementType: elementType, iterableType: iterableType);
        if (!_uiAsCodeEnabled &&
            node.elements.isEmpty &&
            node.typeArguments == null &&
            node.isMap) {
          // The node is really an empty set literal with no type arguments.
          (node as SetOrMapLiteralImpl).becomeMap();
        }
      } else if (typeArguments.length == 2) {
        DartType keyType = typeArguments[0];
        DartType valueType = typeArguments[1];
        _pushCollectionTypesDownToAll(node.elements,
            iterableType: literalType, keyType: keyType, valueType: valueType);
      }
      (node as SetOrMapLiteralImpl).contextType = literalType;
    } else {
      (node as SetOrMapLiteralImpl).contextType = null;
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }

    if (_flowAnalysis != null &&
        _flowAnalysis.isPotentiallyNonNullableLocalReadBeforeWrite(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
        node,
        [node.name],
      );
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _flowAnalysis?.checkUnreachableNode(node);

    InferenceContext.setType(
        node.expression, _enclosingSwitchStatementExpressionType);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchStatementInScope(SwitchStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    var previousExpressionType = _enclosingSwitchStatementExpressionType;
    try {
      var expression = node.expression;
      expression.accept(this);
      _enclosingSwitchStatementExpressionType = expression.staticType;

      if (_flowAnalysis != null) {
        var flow = _flowAnalysis.flow;

        flow.switchStatement_expressionEnd(node);

        var hasDefault = false;
        var members = node.members;
        for (var member in members) {
          flow.switchStatement_beginCase(member.labels.isNotEmpty, node);
          member.accept(this);

          if (member is SwitchDefault) {
            hasDefault = true;
          }
        }

        flow.switchStatement_end(hasDefault);
      } else {
        node.members.accept(this);
      }
    } finally {
      _enclosingSwitchStatementExpressionType = previousExpressionType;
    }
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (_flowAnalysis == null) {
      return super.visitTryStatement(node);
    }

    _flowAnalysis.checkUnreachableNode(node);
    var flow = _flowAnalysis.flow;

    var body = node.body;
    var catchClauses = node.catchClauses;
    var finallyBlock = node.finallyBlock;

    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }

    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyBegin();
    }
    body.accept(this);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        flow.tryCatchStatement_catchBegin(
            catchClause.exceptionParameter?.staticElement,
            catchClause.stackTraceParameter?.staticElement);
        catchClause.accept(this);
        flow.tryCatchStatement_catchEnd();
      }

      flow.tryCatchStatement_end();
    }

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end(finallyBlock);
    }
  }

  @override
  void visitTypeName(TypeName node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var grandParent = node.parent.parent;
    bool isTopLevel = grandParent is FieldDeclaration ||
        grandParent is TopLevelVariableDeclaration;
    InferenceContext.setTypeFromNode(node.initializer, node);
    if (isTopLevel) {
      _flowAnalysis?.topLevelDeclaration_enter(node, null, null);
    }
    super.visitVariableDeclaration(node);
    if (isTopLevel) {
      _flowAnalysis?.topLevelDeclaration_exit();
    }
    VariableElement element = node.declaredElement;
    if (element.initializer != null && node.initializer != null) {
      var initializer = element.initializer as FunctionElementImpl;
      initializer.returnType = node.initializer.staticType;
    }
    // Note: in addition to cloning the initializers for const variables, we
    // have to clone the initializers for non-static final fields (because if
    // they occur in a class with a const constructor, they will be needed to
    // evaluate the const constructor).
    if (element is ConstVariableElement) {
      (element as ConstVariableElement).constantInitializer =
          _createCloner().cloneNode(node.initializer);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _flowAnalysis?.variableDeclarationList(node);
    for (VariableDeclaration decl in node.variables) {
      VariableElement variableElement = decl.declaredElement;
      InferenceContext.setType(decl, variableElement?.type);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    // Note: since we don't call the base class, we have to maintain
    // _implicitLabelScope ourselves.
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);

      Expression condition = node.condition;
      InferenceContext.setType(condition, typeProvider.boolType);

      _flowAnalysis?.flow?.whileStatement_conditionBegin(node);
      condition?.accept(this);

      Statement body = node.body;
      if (body != null) {
        _flowAnalysis?.flow?.whileStatement_bodyBegin(node, condition);
        visitStatementInScope(body);
        _flowAnalysis?.flow?.whileStatement_end();
      }
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    Expression e = node.expression;
    DartType returnType = inferenceContext.returnContext;
    bool isGenerator = _enclosingFunction?.isGenerator ?? false;
    if (returnType != null && isGenerator) {
      // If we're not in a generator ([a]sync*, then we shouldn't have a yield.
      // so don't infer

      // If this just a yield, then we just pass on the element type
      DartType type = returnType;
      if (node.star != null) {
        // If this is a yield*, then we wrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        type = _enclosingFunction.isSynchronous
            ? typeProvider.iterableType2(type)
            : typeProvider.streamType2(type);
      }
      InferenceContext.setType(e, type);
    }
    super.visitYieldStatement(node);
    DartType type = e?.staticType;
    if (type != null && isGenerator) {
      // If this just a yield, then we just pass on the element type
      if (node.star != null) {
        // If this is a yield*, then we unwrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        if (type is InterfaceType) {
          ClassElement wrapperElement = _enclosingFunction.isSynchronous
              ? typeProvider.iterableElement
              : typeProvider.streamElement;
          var asInstanceType =
              (type as InterfaceTypeImpl).asInstanceOf(wrapperElement);
          if (asInstanceType != null) {
            type = asInstanceType.typeArguments[0];
          }
        }
      }
      if (type != null) {
        inferenceContext.addReturnOrYieldType(type);
      }
    }
  }

  /// Given the declared return type of a function, compute the type of the
  /// values which should be returned or yielded as appropriate.  If a type
  /// cannot be computed from the declared return type, return null.
  DartType _computeReturnOrYieldType(DartType declaredType) {
    bool isGenerator = _enclosingFunction.isGenerator;
    bool isAsynchronous = _enclosingFunction.isAsynchronous;

    // Ordinary functions just return their declared types.
    if (!isGenerator && !isAsynchronous) {
      return declaredType;
    }
    if (declaredType is InterfaceType) {
      if (isGenerator) {
        // If it's sync* we expect Iterable<T>
        // If it's async* we expect Stream<T>
        // Match the types to instantiate the type arguments if possible
        List<DartType> targs = declaredType.typeArguments;
        if (targs.length == 1) {
          var arg = targs[0];
          if (isAsynchronous) {
            if (typeProvider.streamType2(arg) == declaredType) {
              return arg;
            }
          } else {
            if (typeProvider.iterableType2(arg) == declaredType) {
              return arg;
            }
          }
        }
      }
      // async functions expect `Future<T> | T`
      var futureTypeParam = typeSystem.flatten(declaredType);
      return _createFutureOr(futureTypeParam);
    }
    return declaredType;
  }

  /// Compute the context type for the given set or map [literal].
  _LiteralResolution _computeSetOrMapResolution(SetOrMapLiteral literal) {
    _LiteralResolution typeArgumentsResolution =
        _fromTypeArguments(literal.typeArguments);
    DartType contextType = InferenceContext.getContext(literal);
    _LiteralResolution contextResolution = _fromContextType(contextType);
    _LeafElements elementCounts = new _LeafElements(literal.elements);
    _LiteralResolution elementResolution = elementCounts.resolution;

    List<_LiteralResolution> unambiguousResolutions = [];
    Set<_LiteralResolutionKind> kinds = new Set<_LiteralResolutionKind>();
    if (typeArgumentsResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(typeArgumentsResolution);
      kinds.add(typeArgumentsResolution.kind);
    }
    if (contextResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(contextResolution);
      kinds.add(contextResolution.kind);
    }
    if (elementResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(elementResolution);
      kinds.add(elementResolution.kind);
    }

    if (kinds.length == 2) {
      // It looks like it needs to be both a map and a set. Attempt to recover.
      if (elementResolution.kind == _LiteralResolutionKind.ambiguous &&
          elementResolution.contextType != null) {
        return elementResolution;
      } else if (typeArgumentsResolution.kind !=
              _LiteralResolutionKind.ambiguous &&
          typeArgumentsResolution.contextType != null) {
        return typeArgumentsResolution;
      } else if (contextResolution.kind != _LiteralResolutionKind.ambiguous &&
          contextResolution.contextType != null) {
        return contextResolution;
      }
    } else if (unambiguousResolutions.length >= 2) {
      // If there are three resolutions, the last resolution is guaranteed to be
      // from the elements, which always has a context type of `null` (when it
      // is not ambiguous). So, whether there are 2 or 3 resolutions only the
      // first two are potentially interesting.
      return unambiguousResolutions[0].contextType == null
          ? unambiguousResolutions[1]
          : unambiguousResolutions[0];
    } else if (unambiguousResolutions.length == 1) {
      return unambiguousResolutions[0];
    } else if (literal.elements.isEmpty) {
      return _LiteralResolution(
          _LiteralResolutionKind.map,
          typeProvider.mapType2(
              typeProvider.dynamicType, typeProvider.dynamicType));
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return a newly created cloner that can be used to clone constant
  /// expressions.
  ConstantAstCloner _createCloner() {
    return new ConstantAstCloner();
  }

  /// Creates a union of `T | Future<T>`, unless `T` is already a
  /// future-union, in which case it simply returns `T`.
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType2(type);
  }

  /// If [contextType] is defined and is a subtype of `Iterable<Object>` and
  /// [contextType] is not a subtype of `Map<Object, Object>`, then *e* is a set
  /// literal.
  ///
  /// If [contextType] is defined and is a subtype of `Map<Object, Object>` and
  /// [contextType] is not a subtype of `Iterable<Object>` then *e* is a map
  /// literal.
  _LiteralResolution _fromContextType(DartType contextType) {
    if (contextType != null) {
      DartType unwrap(DartType type) {
        if (type is InterfaceType &&
            type.isDartAsyncFutureOr &&
            type.typeArguments.length == 1) {
          return unwrap(type.typeArguments[0]);
        }
        return type;
      }

      DartType unwrappedContextType = unwrap(contextType);
      // TODO(brianwilkerson) Find out what the "greatest closure" is and use that
      // where [unwrappedContextType] is used below.
      bool isIterable = typeSystem.isSubtypeOf(
          unwrappedContextType, _iterableForSetMapDisambiguation);
      bool isMap = typeSystem.isSubtypeOf(
          unwrappedContextType, _mapForSetMapDisambiguation);
      if (isIterable && !isMap) {
        return _LiteralResolution(
            _LiteralResolutionKind.set, unwrappedContextType);
      } else if (isMap && !isIterable) {
        return _LiteralResolution(
            _LiteralResolutionKind.map, unwrappedContextType);
      }
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return the resolution that is indicated by the given [typeArgumentList].
  _LiteralResolution _fromTypeArguments(TypeArgumentList typeArgumentList) {
    if (typeArgumentList != null) {
      NodeList<TypeAnnotation> arguments = typeArgumentList.arguments;
      if (arguments.length == 1) {
        return _LiteralResolution(_LiteralResolutionKind.set,
            typeProvider.setType2(arguments[0].type));
      } else if (arguments.length == 2) {
        return _LiteralResolution(_LiteralResolutionKind.map,
            typeProvider.mapType2(arguments[0].type, arguments[1].type));
      }
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return `true` if the given [parameter] element of the AST being resolved
  /// is resynthesized and is an API-level, not local, so has its initializer
  /// serialized.
  bool _hasSerializedConstantInitializer(ParameterElement parameter) {
    Element executable = parameter.enclosingElement;
    if (executable is MethodElement ||
        executable is FunctionElement &&
            executable.enclosingElement is CompilationUnitElement) {
      return LibraryElementImpl.hasResolutionCapability(
          definingLibrary, LibraryResolutionCapability.constantExpressions);
    }
    return false;
  }

  FunctionType _inferArgumentTypesForGeneric(AstNode inferenceNode,
      DartType uninstantiatedType, TypeArgumentList typeArguments,
      {AstNode errorNode, bool isConst: false}) {
    errorNode ??= inferenceNode;
    if (typeArguments == null &&
        uninstantiatedType is FunctionType &&
        uninstantiatedType.typeFormals.isNotEmpty) {
      var typeArguments = typeSystem.inferGenericFunctionOrType(
        typeParameters: uninstantiatedType.typeFormals,
        parameters: const <ParameterElement>[],
        declaredReturnType: uninstantiatedType.returnType,
        argumentTypes: const <DartType>[],
        contextReturnType: InferenceContext.getContext(inferenceNode),
        downwards: true,
        isConst: isConst,
        errorReporter: errorReporter,
        errorNode: errorNode,
      );
      if (typeArguments != null) {
        return uninstantiatedType.instantiate(typeArguments);
      }
    }
    return null;
  }

  void _inferArgumentTypesForInstanceCreate(InstanceCreationExpression node) {
    ConstructorName constructor = node.constructorName;
    TypeName classTypeName = constructor?.type;
    if (classTypeName == null) {
      return;
    }

    ConstructorElement originalElement = constructor.staticElement;
    FunctionType inferred;
    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (classTypeName.typeArguments == null &&
        originalElement is ConstructorMember) {
      // TODO(leafp): Currently, we may re-infer types here, since we
      // sometimes resolve multiple times.  We should really check that we
      // have not already inferred something.  However, the obvious ways to
      // check this don't work, since we may have been instantiated
      // to bounds in an earlier phase, and we *do* want to do inference
      // in that case.

      // Get back to the uninstantiated generic constructor.
      // TODO(jmesserly): should we store this earlier in resolution?
      // Or look it up, instead of jumping backwards through the Member?
      var rawElement = originalElement.baseElement;

      FunctionType constructorType =
          StaticTypeAnalyzer.constructorToGenericFunctionType(rawElement);

      inferred = _inferArgumentTypesForGeneric(
          node, constructorType, constructor.type.typeArguments,
          isConst: node.isConst, errorNode: node.constructorName);

      if (inferred != null) {
        ArgumentList arguments = node.argumentList;
        InferenceContext.setType(arguments, inferred);
        // Fix up the parameter elements based on inferred method.
        arguments.correspondingStaticParameters =
            resolveArgumentsToParameters(arguments, inferred.parameters, null);

        constructor.type.type = inferred.returnType;
        if (UnknownInferredType.isKnown(inferred)) {
          inferenceContext.recordInference(node, inferred.returnType);
        }

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        constructor.staticElement =
            ConstructorMember.from(rawElement, inferred.returnType);
        node.staticElement = constructor.staticElement;
      }
    }

    if (inferred == null) {
      InferenceContext.setType(node.argumentList, originalElement?.type);
    }
  }

  void _inferArgumentTypesForInvocation(InvocationExpression node) {
    DartType inferred = _inferArgumentTypesForGeneric(
        node, node.function.staticType, node.typeArguments);
    InferenceContext.setType(
        node.argumentList, inferred ?? node.staticInvokeType);
  }

  void _inferFormalParameterList(FormalParameterList node, DartType type) {
    if (typeAnalyzer.inferFormalParameterList(node, type)) {
      // TODO(leafp): This gets dropped on the floor if we're in the field
      // inference task.  We should probably keep these infos.
      //
      // TODO(jmesserly): this is reporting the context type, and therefore not
      // necessarily the correct inferred type for the lambda.
      //
      // For example, `([x]) {}`  could be passed to `int -> void` but its type
      // will really be `([int]) -> void`. Similar issue for named arguments.
      // It can also happen if the return type is inferred later on to be
      // more precise.
      //
      // This reporting bug defeats the deduplication of error messages and
      // results in the same inference message being reported twice.
      //
      // To get this right, we'd have to delay reporting until we have the
      // complete type including return type.
      inferenceContext.recordInference(node.parent, type);
    }
  }

  void _pushCollectionTypesDown(CollectionElement element,
      {DartType elementType,
      @required DartType iterableType,
      DartType keyType,
      DartType valueType}) {
    if (element is ForElement) {
      _pushCollectionTypesDown(element.body,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is IfElement) {
      _pushCollectionTypesDown(element.thenElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
      _pushCollectionTypesDown(element.elseElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is Expression) {
      InferenceContext.setType(element, elementType);
    } else if (element is MapLiteralEntry) {
      InferenceContext.setType(element.key, keyType);
      InferenceContext.setType(element.value, valueType);
    } else if (element is SpreadElement) {
      InferenceContext.setType(element.expression, iterableType);
    }
  }

  void _pushCollectionTypesDownToAll(List<CollectionElement> elements,
      {DartType elementType,
      @required DartType iterableType,
      DartType keyType,
      DartType valueType}) {
    assert(iterableType != null);
    for (CollectionElement element in elements) {
      _pushCollectionTypesDown(element,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    }
  }

  /// Continues resolution of the [FunctionExpressionInvocation] node after
  /// resolving its function.
  void _visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _inferArgumentTypesForInvocation(node);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// An error will be reported to [onError] if any of the arguments cannot be
  /// matched to a parameter. onError can be null to ignore the error.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<ParameterElement> resolveArgumentsToParameters(
      ArgumentList argumentList,
      List<ParameterElement> parameters,
      void onError(ErrorCode errorCode, AstNode node,
          [List<Object> arguments])) {
    if (parameters.isEmpty && argumentList.arguments.isEmpty) {
      return const <ParameterElement>[];
    }
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    List<ParameterElement> unnamedParameters = new List<ParameterElement>();
    Map<String, ParameterElement> namedParameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
        requiredParameterCount++;
      } else if (parameter.isOptionalPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
      } else {
        namedParameters ??= new HashMap<String, ParameterElement>();
        namedParameters[parameter.name] = parameter;
      }
    }
    int unnamedIndex = 0;
    NodeList<Expression> arguments = argumentList.arguments;
    int argumentCount = arguments.length;
    List<ParameterElement> resolvedParameters =
        new List<ParameterElement>(argumentCount);
    int positionalArgumentCount = 0;
    HashSet<String> usedNames;
    bool noBlankArguments = true;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        SimpleIdentifier nameNode = argument.name.label;
        String name = nameNode.name;
        ParameterElement element =
            namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          if (onError != null) {
            onError(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, nameNode,
                [name]);
          }
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        usedNames ??= new HashSet<String>();
        if (!usedNames.add(name)) {
          if (onError != null) {
            onError(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode,
                [name]);
          }
        }
      } else {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        }
      }
    }
    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      if (onError != null) {
        onError(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS,
            argumentList, [requiredParameterCount, positionalArgumentCount]);
      }
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      ErrorCode errorCode;
      int namedParameterCount = namedParameters?.length ?? 0;
      int namedArgumentCount = usedNames?.length ?? 0;
      if (namedParameterCount > namedArgumentCount) {
        errorCode =
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED;
      } else {
        errorCode = CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS;
      }
      if (onError != null) {
        onError(errorCode, argumentList,
            [unnamedParameterCount, positionalArgumentCount]);
      }
    }
    return resolvedParameters;
  }
}

/// The abstract class `ScopedVisitor` maintains name and label scopes as an AST
/// structure is being visited.
abstract class ScopedVisitor extends UnifyingAstVisitor<void> {
  /// The element for the library containing the compilation unit being visited.
  final LibraryElement definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProvider typeProvider;

  /// The error reporter that will be informed of any errors that are found
  /// during resolution.
  final ErrorReporter errorReporter;

  /// The scope used to resolve identifiers.
  Scope nameScope;

  /// The scope used to resolve unlabeled `break` and `continue` statements.
  ImplicitLabelScope _implicitLabelScope = ImplicitLabelScope.ROOT;

  /// The scope used to resolve labels for `break` and `continue` statements, or
  /// `null` if no labels have been defined in the current context.
  LabelScope labelScope;

  /// The class containing the AST nodes being visited,
  /// or `null` if we are not in the scope of a class.
  ClassElement enclosingClass;

  /// The element representing the extension containing the AST nodes being
  /// visited, or `null` if we are not in the scope of an extension.
  ExtensionElement enclosingExtension;

  /// Initialize a newly created visitor to resolve the nodes in a compilation
  /// unit.
  ///
  /// [definingLibrary] is the element for the library containing the
  /// compilation unit being visited.
  /// [source] is the source representing the compilation unit being visited.
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  ScopedVisitor(this.definingLibrary, Source source, this.typeProvider,
      AnalysisErrorListener errorListener,
      {Scope nameScope})
      : source = source,
        errorReporter = new ErrorReporter(errorListener, source) {
    if (nameScope == null) {
      this.nameScope = new LibraryScope(definingLibrary);
    } else {
      this.nameScope = nameScope;
    }
  }

  /// Return the implicit label scope in which the current node is being
  /// resolved.
  ImplicitLabelScope get implicitLabelScope => _implicitLabelScope;

  /// Replaces the current [Scope] with the enclosing [Scope].
  ///
  /// @return the enclosing [Scope].
  Scope popNameScope() {
    nameScope = nameScope.enclosingScope;
    return nameScope;
  }

  /// Pushes a new [Scope] into the visitor.
  ///
  /// @return the new [Scope].
  Scope pushNameScope() {
    Scope newScope = new EnclosedScope(nameScope);
    nameScope = newScope;
    return nameScope;
  }

  @override
  void visitBlock(Block node) {
    Scope outerScope = nameScope;
    try {
      EnclosedScope enclosedScope = new BlockScope(nameScope, node);
      nameScope = enclosedScope;
      super.visitBlock(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    ImplicitLabelScope implicitOuterScope = _implicitLabelScope;
    try {
      _implicitLabelScope = ImplicitLabelScope.ROOT;
      super.visitBlockFunctionBody(node);
    } finally {
      _implicitLabelScope = implicitOuterScope;
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      Scope outerScope = nameScope;
      try {
        nameScope = new EnclosedScope(nameScope);
        nameScope.define(exception.staticElement);
        SimpleIdentifier stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          nameScope.define(stackTrace.staticElement);
        }
        super.visitCatchClause(node);
      } finally {
        nameScope = outerScope;
      }
    } else {
      super.visitCatchClause(node);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    ClassElement classElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for class declaration ${node.name.name} in "
            "${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
        super.visitClassDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.declaredElement;
          nameScope = new TypeParameterScope(nameScope, classElement);
          visitClassDeclarationInScope(node);
          nameScope = new ClassScope(nameScope, classElement);
          visitClassMembersInScope(node);
        } finally {
          enclosingClass = outerClass;
        }
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitClassDeclarationInScope(ClassDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.nativeClause?.accept(this);
  }

  void visitClassMembersInScope(ClassDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement;
      nameScope =
          new ClassScope(new TypeParameterScope(nameScope, element), element);
      super.visitClassTypeAlias(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement constructorElement = node.declaredElement;
    if (constructorElement == null) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Missing element for constructor ");
      buffer.write(node.returnType.name);
      if (node.name != null) {
        buffer.write(".");
        buffer.write(node.name.name);
      }
      buffer.write(" in ");
      buffer.write(definingLibrary.source.fullName);
      AnalysisEngine.instance.instrumentationService.logInfo(buffer.toString());
    }
    Scope outerScope = nameScope;
    try {
      if (constructorElement != null) {
        nameScope = new FunctionScope(nameScope, constructorElement);
      }
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.name?.accept(this);
      node.parameters?.accept(this);
      Scope functionScope = nameScope;
      try {
        if (constructorElement != null) {
          nameScope =
              new ConstructorInitializerScope(nameScope, constructorElement);
        }
        node.initializers.accept(this);
      } finally {
        nameScope = functionScope;
      }
      node.redirectedConstructor?.accept(this);
      visitConstructorDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    node.body?.accept(this);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    VariableElement element = node.declaredElement;
    if (element != null) {
      nameScope.define(element);
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitDoStatementInScope(node);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitDoStatementInScope(DoStatement node) {
    visitStatementInScope(node.body);
    node.condition?.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    ClassElement classElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for enum declaration ${node.name.name} in "
            "${definingLibrary.source.fullName}");
        super.visitEnumDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.declaredElement;
          nameScope = new ClassScope(nameScope, classElement);
          visitEnumMembersInScope(node);
        } finally {
          enclosingClass = outerClass;
        }
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.constants.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    ExtensionElement extensionElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (extensionElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for extension declaration ${node.name.name} "
            "in ${definingLibrary.source.fullName}");
        super.visitExtensionDeclaration(node);
      } else {
        ExtensionElement outerExtension = enclosingExtension;
        try {
          enclosingExtension = extensionElement;
          nameScope = new TypeParameterScope(nameScope, extensionElement);
          visitExtensionDeclarationInScope(node);
          nameScope = ExtensionScope(nameScope, extensionElement);
          visitExtensionMembersInScope(node);
        } finally {
          enclosingExtension = outerExtension;
        }
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitExtensionDeclarationInScope(ExtensionDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.extendedType?.accept(this);
  }

  void visitExtensionMembersInScope(ExtensionDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    //
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    //
    node.iterable?.accept(this);
    node.loopVariable?.accept(this);
  }

  @override
  void visitForElement(ForElement node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      visitForElementInScope(node);
    } finally {
      nameScope = outerNameScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForElementInScope(ForElement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts?.accept(this);
    node.body?.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    // We finished resolving function signature, now include formal parameters
    // scope.  Note: we must not do this if the parent is a
    // FunctionTypedFormalParameter, because in that case we aren't finished
    // resolving the full function signature, just a part of it.
    if (nameScope is FunctionScope &&
        node.parent is! FunctionTypedFormalParameter) {
      (nameScope as FunctionScope).defineParameters();
    }
    if (nameScope is FunctionTypeScope) {
      (nameScope as FunctionTypeScope).defineParameters();
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitForStatementInScope(node);
    } finally {
      nameScope = outerNameScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForStatementInScope(ForStatement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts?.accept(this);
    visitStatementInScope(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement functionElement = node.declaredElement;
    if (functionElement != null &&
        functionElement.enclosingElement is! CompilationUnitElement) {
      nameScope.define(functionElement);
    }
    Scope outerScope = nameScope;
    try {
      if (functionElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for top-level function ${node.name.name} in "
            "${definingLibrary.source.fullName}");
      } else {
        nameScope = new FunctionScope(nameScope, functionElement);
      }
      visitFunctionDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // We have already created a function scope and don't need to do so again.
      super.visitFunctionExpression(node);
    } else {
      Scope outerScope = nameScope;
      try {
        ExecutableElement functionElement = node.declaredElement;
        if (functionElement == null) {
          StringBuffer buffer = new StringBuffer();
          buffer.write("Missing element for function ");
          AstNode parent = node.parent;
          while (parent != null) {
            if (parent is Declaration) {
              Element parentElement = parent.declaredElement;
              buffer.write(parentElement == null
                  ? "<unknown> "
                  : "${parentElement.name} ");
            }
            parent = parent.parent;
          }
          buffer.write("in ");
          buffer.write(definingLibrary.source.fullName);
          AnalysisEngine.instance.instrumentationService
              .logInfo(buffer.toString());
        } else {
          nameScope = new FunctionScope(nameScope, functionElement);
        }
        super.visitFunctionExpression(node);
      } finally {
        nameScope = outerScope;
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      nameScope = new FunctionTypeScope(nameScope, node.declaredElement);
      visitFunctionTypeAliasInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    Scope outerScope = nameScope;
    try {
      ParameterElement parameterElement = node.declaredElement;
      if (parameterElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for function typed formal parameter "
            "${node.identifier.name} in ${definingLibrary.source.fullName}");
      } else {
        nameScope = new EnclosedScope(nameScope);
        var typeParameters = parameterElement.typeParameters;
        int length = typeParameters.length;
        for (int i = 0; i < length; i++) {
          nameScope.define(typeParameters[i]);
        }
      }
      super.visitFunctionTypedFormalParameter(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    DartType type = node.type;
    if (type == null) {
      // The function type hasn't been resolved yet, so we can't create a scope
      // for its parameters.
      super.visitGenericFunctionType(node);
      return;
    }
    GenericFunctionTypeElement element =
        (node as GenericFunctionTypeImpl).declaredElement;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for generic function type in "
                "${definingLibrary.source.fullName}");
        super.visitGenericFunctionType(node);
      } else {
        nameScope = new TypeParameterScope(nameScope, element);
        super.visitGenericFunctionType(node);
      }
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAliasElement element = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for generic function type in "
                "${definingLibrary.source.fullName}");
        super.visitGenericTypeAlias(node);
      } else {
        nameScope = new TypeParameterScope(nameScope, element);
        super.visitGenericTypeAlias(node);

        GenericFunctionTypeElement functionElement = element.function;
        if (functionElement != null) {
          nameScope = new FunctionScope(nameScope, functionElement)
            ..defineParameters();
          visitGenericTypeAliasInFunctionScope(node);
        }
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitGenericTypeAliasInFunctionScope(GenericTypeAlias node) {}

  @override
  void visitIfStatement(IfStatement node) {
    node.condition?.accept(this);
    visitStatementInScope(node.thenStatement);
    visitStatementInScope(node.elseStatement);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    LabelScope outerScope = _addScopesFor(node.labels, node.unlabeled);
    try {
      super.visitLabeledStatement(node);
    } finally {
      labelScope = outerScope;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ExecutableElement methodElement = node.declaredElement;
      if (methodElement == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for method ${node.name.name} in "
                "${definingLibrary.source.fullName}");
      } else {
        nameScope = new FunctionScope(nameScope, methodElement);
      }
      visitMethodDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    ClassElement element = node.declaredElement;

    Scope outerScope = nameScope;
    ClassElement outerClass = enclosingClass;
    try {
      enclosingClass = element;

      nameScope = new TypeParameterScope(nameScope, element);
      visitMixinDeclarationInScope(node);

      nameScope = new ClassScope(nameScope, element);
      visitMixinMembersInScope(node);
    } finally {
      nameScope = outerScope;
      enclosingClass = outerClass;
    }
  }

  void visitMixinDeclarationInScope(MixinDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  void visitMixinMembersInScope(MixinDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  /// Visit the given statement after it's scope has been created. This is used
  /// by ResolverVisitor to correctly visit the 'then' and 'else' statements of
  /// an 'if' statement.
  ///
  /// @param node the statement to be visited
  void visitStatementInScope(Statement node) {
    if (node is Block) {
      // Don't create a scope around a block because the block will create it's
      // own scope.
      visitBlock(node);
    } else if (node != null) {
      Scope outerNameScope = nameScope;
      try {
        nameScope = new EnclosedScope(nameScope);
        node.accept(this);
      } finally {
        nameScope = outerNameScope;
      }
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);
    Scope outerNameScope = nameScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    LabelScope outerScope = labelScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      for (SwitchMember member in node.members) {
        for (Label label in member.labels) {
          SimpleIdentifier labelName = label.label;
          LabelElement labelElement = labelName.staticElement as LabelElement;
          labelScope =
              new LabelScope(labelScope, labelName.name, member, labelElement);
        }
      }
      visitSwitchStatementInScope(node);
    } finally {
      labelScope = outerScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitSwitchStatementInScope(SwitchStatement node) {
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (node.parent.parent is! TopLevelVariableDeclaration &&
        node.parent.parent is! FieldDeclaration) {
      VariableElement element = node.declaredElement;
      if (element != null) {
        nameScope.define(element);
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition?.accept(this);
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitStatementInScope(node.body);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Add scopes for each of the given labels.
  ///
  /// @param labels the labels for which new scopes are to be added
  /// @return the scope that was in effect before the new scopes were added
  LabelScope _addScopesFor(NodeList<Label> labels, AstNode node) {
    LabelScope outerScope = labelScope;
    for (Label label in labels) {
      SimpleIdentifier labelNameNode = label.label;
      String labelName = labelNameNode.name;
      LabelElement labelElement = labelNameNode.staticElement as LabelElement;
      labelScope = new LabelScope(labelScope, labelName, node, labelElement);
    }
    return outerScope;
  }
}

/// Instances of the class `ToDoFinder` find to-do comments in Dart code.
class ToDoFinder {
  /// The error reporter by which to-do comments will be reported.
  final ErrorReporter _errorReporter;

  /// Initialize a newly created to-do finder to report to-do comments to the
  /// given reporter.
  ///
  /// @param errorReporter the error reporter by which to-do comments will be
  ///        reported
  ToDoFinder(this._errorReporter);

  /// Search the comments in the given compilation unit for to-do comments and
  /// report an error for each.
  ///
  /// @param unit the compilation unit containing the to-do comments
  void findIn(CompilationUnit unit) {
    _gatherTodoComments(unit.beginToken);
  }

  /// Search the comment tokens reachable from the given token and create errors
  /// for each to-do comment.
  ///
  /// @param token the head of the list of tokens being searched
  void _gatherTodoComments(Token token) {
    while (token != null && token.type != TokenType.EOF) {
      Token commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT ||
            commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          _scrapeTodoComment(commentToken);
        }
        commentToken = commentToken.next;
      }
      token = token.next;
    }
  }

  /// Look for user defined tasks in comments and convert them into info level
  /// analysis issues.
  ///
  /// @param commentToken the comment token to analyze
  void _scrapeTodoComment(Token commentToken) {
    Iterable<Match> matches =
        TodoCode.TODO_REGEX.allMatches(commentToken.lexeme);
    for (Match match in matches) {
      int offset = commentToken.offset + match.start + match.group(1).length;
      int length = match.group(2).length;
      _errorReporter.reportErrorForOffset(
          TodoCode.TODO, offset, length, [match.group(2)]);
    }
  }
}

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolveTypeName].
class TypeNameResolver {
  final Dart2TypeSystem typeSystem;
  final DartType dynamicType;
  final bool isNonNullableUnit;
  final AnalysisOptionsImpl analysisOptions;
  final LibraryElement definingLibrary;
  final Source source;
  final AnalysisErrorListener errorListener;

  /// Indicates whether bare typenames in "with" clauses should have their type
  /// inferred type arguments loaded from the element model.
  ///
  /// This is needed for mixin type inference, but is incompatible with the old
  /// task model.
  final bool shouldUseWithClauseInferredTypes;

  Scope nameScope;

  /// If [resolveTypeName] finds out that the given [TypeName] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName rewriteResult;

  TypeNameResolver(
      this.typeSystem,
      TypeProvider typeProvider,
      this.isNonNullableUnit,
      this.definingLibrary,
      this.source,
      this.errorListener,
      {this.shouldUseWithClauseInferredTypes: true})
      : dynamicType = typeProvider.dynamicType,
        analysisOptions = definingLibrary.context.analysisOptions;

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableUnit ? NullabilitySuffix.none : NullabilitySuffix.star;
  }

  /// Report an error with the given error code and arguments.
  ///
  /// @param errorCode the error code of the error to be reported
  /// @param node the node specifying the location of the error
  /// @param arguments the arguments to the error, used to compose the error
  ///        message
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    errorListener.onError(new AnalysisError(
        source, node.offset, node.length, errorCode, arguments));
  }

  /// Resolve the given [TypeName] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolveTypeName].
  void resolveTypeName(TypeName node) {
    rewriteResult = null;
    Identifier typeName = node.name;
    _setElement(typeName, null); // Clear old Elements from previous run.
    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      //
      // Check to see whether the type name is either 'dynamic' or 'void',
      // neither of which are in the name scope and hence will not be found by
      // normal means.
      //
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
//        if (argumentList != null) {
//          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, voidType.getName(), 0, argumentList.getArguments().size());
//        }
        node.type = voidType;
        return;
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
      //
      // If not, the look to see whether we might have created the wrong AST
      // structure for a constructor name. If so, fix the AST structure and then
      // proceed.
      //
      AstNode parent = node.parent;
      if (typeName is PrefixedIdentifier &&
          parent is ConstructorName &&
          argumentList == null) {
        ConstructorName name = parent;
        if (name.name == null) {
          PrefixedIdentifier prefixedIdentifier =
              typeName as PrefixedIdentifier;
          SimpleIdentifier prefix = prefixedIdentifier.prefix;
          element = nameScope.lookup(prefix, definingLibrary);
          if (element is PrefixElement) {
            if (nameScope.shouldIgnoreUndefined(typeName)) {
              node.type = dynamicType;
              return;
            }
            AstNode grandParent = parent.parent;
            if (grandParent is InstanceCreationExpression &&
                grandParent.isConst) {
              // If, if this is a const expression, then generate a
              // CompileTimeErrorCode.CONST_WITH_NON_TYPE error.
              reportErrorForNode(
                  CompileTimeErrorCode.CONST_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
            } else {
              // Else, if this expression is a new expression, report a
              // NEW_WITH_NON_TYPE warning.
              reportErrorForNode(
                  StaticWarningCode.NEW_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
            }
            _setElement(prefix, element);
            return;
          } else if (element != null) {
            //
            // Rewrite the constructor name. The parser, when it sees a
            // constructor named "a.b", cannot tell whether "a" is a prefix and
            // "b" is a class name, or whether "a" is a class name and "b" is a
            // constructor name. It arbitrarily chooses the former, but in this
            // case was wrong.
            //
            name.name = prefixedIdentifier.identifier;
            name.period = prefixedIdentifier.period;
            node.name = prefix;
            typeName = prefix;
            rewriteResult = parent;
          }
        }
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
    }
    // check element
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid &&
        element != null &&
        element is! ClassElement &&
        _isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation =
          node.parent.parent as InstanceCreationExpression;
      if (creation.isConst) {
        reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE,
            typeNameSimple, [typeName]);
        elementValid = false;
      } else {
        reportErrorForNode(
            StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
        elementValid = false;
      }
    }
    if (elementValid && element == null) {
      // We couldn't resolve the type name.
      elementValid = false;
      // TODO(jwren) Consider moving the check for
      // CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE from the
      // ErrorVerifier, so that we don't have two errors on a built in
      // identifier being used as a class name.
      // See CompileTimeErrorCodeTest.test_builtInIdentifierAsType().
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      if (_isBuiltInIdentifier(node) && _isTypeAnnotation(node)) {
        reportErrorForNode(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
            typeName, [typeName.name]);
      } else if (typeNameSimple.name == "boolean") {
        reportErrorForNode(
            StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, typeNameSimple, []);
      } else if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME,
            typeName, [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else if (typeName is PrefixedIdentifier &&
          node.parent is ConstructorName &&
          argumentList != null) {
        SimpleIdentifier prefix = (typeName as PrefixedIdentifier).prefix;
        SimpleIdentifier identifier =
            (typeName as PrefixedIdentifier).identifier;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        ClassElement classElement;
        ConstructorElement constructorElement;
        if (prefixElement is ClassElement) {
          classElement = prefixElement;
          constructorElement =
              prefixElement.getNamedConstructor(identifier.name);
        }
        if (constructorElement != null) {
          reportErrorForNode(
              StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
              argumentList,
              [prefix.name, identifier.name]);
          prefix.staticElement = prefixElement;
          identifier.staticElement = constructorElement;
          AstNode grandParent = node.parent.parent;
          if (grandParent is InstanceCreationExpressionImpl) {
            var instanceType = classElement.instantiate(
              typeArguments: List.filled(
                classElement.typeParameters.length,
                dynamicType,
              ),
              nullabilitySuffix: _noneOrStarSuffix,
            );
            grandParent.staticElement = constructorElement;
            grandParent.staticType = instanceType;
            //
            // Re-write the AST to reflect the resolution.
            //
            TypeName newTypeName = astFactory.typeName(prefix, null);
            newTypeName.type = instanceType;
            ConstructorName newConstructorName = astFactory.constructorName(
                newTypeName,
                (typeName as PrefixedIdentifier).period,
                identifier);
            newConstructorName.staticElement = constructorElement;
            NodeReplacer.replace(node.parent, newConstructorName);
            grandParent.typeArguments = node.typeArguments;
            // Re-assign local variables that have effectively changed.
            node = newTypeName;
            typeName = prefix;
            element = prefixElement;
            argumentList = null;
            elementValid = true;
            rewriteResult = newConstructorName;
          }
        } else {
          reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
        }
      } else {
        reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
    }
    if (!elementValid) {
      if (element is MultiplyDefinedElement) {
        _setElement(typeName, element);
      }
      node.type = dynamicType;
      return;
    }

    if (element is ClassElement) {
      _resolveClassElement(node, typeName, argumentList, element);
      return;
    }

    DartType type;
    if (element == DynamicElementImpl.instance) {
      _setElement(typeName, element);
      type = DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else if (element is FunctionTypeAliasElement) {
      _setElement(typeName, element);
    } else if (element is TypeParameterElement) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else if (element is MultiplyDefinedElement) {
      var elements = (element as MultiplyDefinedElement).conflictingElements;
      element = _getElementWhenMultiplyDefined(elements);
    } else {
      // The name does not represent a type.
      if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, typeName,
            [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else {
        AstNode parent = typeName.parent;
        while (parent is TypeName) {
          parent = parent.parent;
        }
        if (parent is ExtendsClause ||
            parent is ImplementsClause ||
            parent is WithClause ||
            parent is ClassTypeAlias) {
          // Ignored. The error will be reported elsewhere.
        } else if (element is LocalVariableElement ||
            (element is FunctionElement &&
                element.enclosingElement is ExecutableElement)) {
          errorListener.onError(new DiagnosticFactory()
              .referencedBeforeDeclaration(source, typeName, element: element));
        } else {
          reportErrorForNode(
              StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      node.type = dynamicType;
      return;
    }
    if (argumentList != null) {
      var parameters = const <TypeParameterElement>[];
      if (element is ClassElement) {
        parameters = element.typeParameters;
      } else if (element is FunctionTypeAliasElement) {
        parameters = element.typeParameters;
      }

      NodeList<TypeAnnotation> arguments = argumentList.arguments;
      int argumentCount = arguments.length;
      int parameterCount = parameters.length;
      List<DartType> typeArguments = new List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _getType(arguments[i]);
        }
      } else {
        reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
            [typeName.name, parameterCount, argumentCount]);
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = dynamicType;
        }
      }
      if (element is GenericTypeAliasElementImpl) {
        type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _getNullability(node.question != null),
        );
        type ??= dynamicType;
      } else {
        type = typeSystem.instantiateType(type, typeArguments);
      }
      type = (type as TypeImpl).withNullability(
        _getNullability(node.question != null),
      );
    } else {
      if (element is GenericTypeAliasElementImpl) {
        var typeArguments = typeSystem.instantiateTypeFormalsToBounds(
          element.typeParameters,
        );
        type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _getNullability(node.question != null),
        );
        type ??= dynamicType;
      } else {
        type = typeSystem.instantiateToBounds(type);
      }
    }

    node.type = type;
  }

  /// Given the multiple elements to which a single name could potentially be
  /// resolved, return the single [ClassElement] that should be used, or `null`
  /// if there is no clear choice.
  ///
  /// @param elements the elements to which a single name could potentially be
  ///        resolved
  /// @return the single interface type that should be used for the type name
  ClassElement _getElementWhenMultiplyDefined(List<Element> elements) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
  }

  DartType _getInferredMixinType(
      ClassElement classElement, ClassElement mixinElement) {
    for (var candidateMixin in classElement.mixins) {
      if (candidateMixin.element == mixinElement) return candidateMixin;
    }
    return null; // Not found
  }

  /// The number of type arguments in the given [typeName] does not match the
  /// number of parameters in the corresponding class element. Return the error
  /// code that should be used to report this error.
  ErrorCode _getInvalidTypeParametersErrorCode(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      parent = parent.parent;
      if (parent is InstanceCreationExpression) {
        if (parent.isConst) {
          return CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS;
        } else {
          return StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS;
        }
      }
    }
    return StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    NullabilitySuffix nullability;
    if (isNonNullableUnit) {
      if (hasQuestion) {
        nullability = NullabilitySuffix.question;
      } else {
        nullability = NullabilitySuffix.none;
      }
    } else {
      nullability = NullabilitySuffix.star;
    }
    return nullability;
  }

  /// Return the type represented by the given type [annotation].
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      return dynamicType;
    }
    return type;
  }

  /// Returns the simple identifier of the given (may be qualified) type name.
  ///
  /// @param typeName the (may be qualified) qualified type name
  /// @return the simple identifier of the given (may be qualified) type name.
  SimpleIdentifier _getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName;
    } else {
      PrefixedIdentifier prefixed = typeName;
      SimpleIdentifier prefix = prefixed.prefix;
      // The prefixed identifier can be:
      // 1. new importPrefix.TypeName()
      // 2. new TypeName.constructorName()
      // 3. new unresolved.Unresolved()
      if (prefix.staticElement is PrefixElement) {
        return prefixed.identifier;
      } else {
        return prefix;
      }
    }
  }

  /// If the [node] is the type name in a redirected factory constructor,
  /// infer type arguments using the enclosing class declaration. Return `null`
  /// otherwise.
  List<DartType> _inferTypeArgumentsForRedirectedConstructor(
      TypeName node, ClassElement typeElement) {
    AstNode constructorName = node.parent;
    AstNode enclosingConstructor = constructorName?.parent;
    if (constructorName is ConstructorName &&
        enclosingConstructor is ConstructorDeclaration &&
        enclosingConstructor.redirectedConstructor == constructorName) {
      ClassOrMixinDeclaration enclosingClassNode = enclosingConstructor.parent;
      var enclosingClassElement = enclosingClassNode.declaredElement;
      if (enclosingClassElement == typeElement) {
        return typeElement.thisType.typeArguments;
      } else {
        return typeSystem.inferGenericFunctionOrType(
          typeParameters: typeElement.typeParameters,
          parameters: const [],
          declaredReturnType: typeElement.thisType,
          argumentTypes: const [],
          contextReturnType: enclosingClassElement.thisType,
        );
      }
    }
    return null;
  }

  /// Return `true` if the given [typeName] is the target in a redirected
  /// constructor.
  bool _isRedirectingConstructor(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      AstNode grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        if (identical(grandParent.redirectedConstructor, parent)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an as expression.
  bool _isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the exception type in a catch
  /// clause.
  bool _isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an instance creation
  /// expression.
  bool _isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      return parent != null && identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an is expression.
  bool _isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] used in a type argument list.
  bool _isTypeNameInTypeArgumentList(TypeName typeName) =>
      typeName.parent is TypeArgumentList;

  /// Given a [typeName] that has a question mark, report an error and return
  /// `true` if it appears in a location where a nullable type is not allowed.
  void _reportInvalidNullableType(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ExtendsClause || parent is ClassTypeAlias) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE, typeName);
    } else if (parent is ImplementsClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE, typeName);
    } else if (parent is OnClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, typeName);
    } else if (parent is WithClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, typeName);
    }
  }

  void _resolveClassElement(TypeName node, Identifier typeName,
      TypeArgumentList argumentList, ClassElement element) {
    _setElement(typeName, element);

    var typeParameters = element.typeParameters;
    var parameterCount = typeParameters.length;

    List<DartType> typeArguments;
    if (argumentList != null) {
      var argumentNodes = argumentList.arguments;
      var argumentCount = argumentNodes.length;

      typeArguments = new List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _getType(argumentNodes[i]);
        }
      } else {
        reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
            [typeName.name, parameterCount, argumentCount]);
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = dynamicType;
        }
      }
    } else if (parameterCount == 0) {
      typeArguments = const <DartType>[];
    } else {
      typeArguments =
          _inferTypeArgumentsForRedirectedConstructor(node, element);
      if (typeArguments == null) {
        typeArguments = typeSystem.instantiateTypeFormalsToBounds2(element);
      }
    }

    var parent = node.parent;

    NullabilitySuffix nullabilitySuffix;
    if (parent is ClassTypeAlias ||
        parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is OnClause ||
        parent is WithClause) {
      if (node.question != null) {
        _reportInvalidNullableType(node);
      }
      if (isNonNullableUnit) {
        nullabilitySuffix = NullabilitySuffix.none;
      } else {
        nullabilitySuffix = NullabilitySuffix.star;
      }
    } else {
      nullabilitySuffix = _getNullability(node.question != null);
    }

    var type = InterfaceTypeImpl.explicit(element, typeArguments,
        nullabilitySuffix: nullabilitySuffix);

    if (shouldUseWithClauseInferredTypes) {
      if (parent is WithClause && parameterCount != 0) {
        // Get the (possibly inferred) mixin type from the element model.
        var grandParent = parent.parent;
        if (grandParent is ClassDeclaration) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else if (grandParent is ClassTypeAlias) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else {
          assert(false, 'Unexpected context for "with" clause');
        }
      }
    }

    node.type = type;
  }

  /// Records the new Element for a TypeName's Identifier.
  ///
  /// A null may be passed in to indicate that the element can't be resolved.
  /// (During a re-run of a task, it's important to clear any previous value
  /// of the element.)
  void _setElement(Identifier typeName, Element element) {
    if (typeName is SimpleIdentifier) {
      typeName.staticElement = element;
    } else if (typeName is PrefixedIdentifier) {
      typeName.identifier.staticElement = element;
      SimpleIdentifier prefix = typeName.prefix;
      prefix.staticElement = nameScope.lookup(prefix, definingLibrary);
    }
  }

  /// Return `true` if the name of the given [typeName] is an built-in
  /// identifier.
  static bool _isBuiltInIdentifier(TypeName typeName) {
    Token token = typeName.name.beginToken;
    return token.type.isKeyword;
  }

  /// @return `true` if given [typeName] is used as a type annotation.
  static bool _isTypeAnnotation(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is VariableDeclarationList) {
      return identical(parent.type, typeName);
    } else if (parent is FieldFormalParameter) {
      return identical(parent.type, typeName);
    } else if (parent is SimpleFormalParameter) {
      return identical(parent.type, typeName);
    }
    return false;
  }
}

/// The interface `TypeProvider` defines the behavior of objects that provide
/// access to types defined by the language.
abstract class TypeProvider {
  /// Return the type representing the built-in type 'bool'.
  InterfaceType get boolType;

  /// Return the type representing the type 'bottom'.
  DartType get bottomType;

  /// Return the type representing the built-in type 'Deprecated'.
  InterfaceType get deprecatedType;

  /// Return the type representing the built-in type 'double'.
  InterfaceType get doubleType;

  /// Return the type representing the built-in type 'dynamic'.
  DartType get dynamicType;

  /// Return the type representing the built-in type 'Function'.
  InterfaceType get functionType;

  /// Return the type representing 'Future<dynamic>'.
  InterfaceType get futureDynamicType;

  /// Return the element representing the built-in class 'Future'.
  ClassElement get futureElement;

  /// Return the type representing 'Future<Null>'.
  InterfaceType get futureNullType;

  /// Return the element representing the built-in class 'FutureOr'.
  ClassElement get futureOrElement;

  /// Return the type representing 'FutureOr<Null>'.
  InterfaceType get futureOrNullType;

  /// Return the type representing the built-in type 'FutureOr'.
  @Deprecated('Use futureOrType2() instead.')
  InterfaceType get futureOrType;

  /// Return the type representing the built-in type 'Future'.
  @Deprecated('Use futureType2() instead.')
  InterfaceType get futureType;

  /// Return the type representing the built-in type 'int'.
  InterfaceType get intType;

  /// Return the type representing the type 'Iterable<dynamic>'.
  InterfaceType get iterableDynamicType;

  /// Return the element representing the built-in class 'Iterable'.
  ClassElement get iterableElement;

  /// Return the type representing the type 'Iterable<Object>'.
  InterfaceType get iterableObjectType;

  /// Return the type representing the built-in type 'Iterable'.
  @Deprecated('Use iterableType2() instead.')
  InterfaceType get iterableType;

  /// Return the element representing the built-in class 'List'.
  ClassElement get listElement;

  /// Return the type representing the built-in type 'List'.
  @Deprecated('Use listType2() instead.')
  InterfaceType get listType;

  /// Return the element representing the built-in class 'Map'.
  ClassElement get mapElement;

  /// Return the type representing 'Map<Object, Object>'.
  InterfaceType get mapObjectObjectType;

  /// Return the type representing the built-in type 'Map'.
  @Deprecated('Use mapType2() instead.')
  InterfaceType get mapType;

  /// Return the type representing the built-in type 'Never'.
  DartType get neverType;

  /// Return a list containing all of the types that cannot be either extended
  /// or implemented.
  List<InterfaceType> get nonSubtypableTypes;

  /// Return a [DartObjectImpl] representing the `null` object.
  DartObjectImpl get nullObject;

  /// Return the type representing the built-in type 'Null'.
  InterfaceType get nullType;

  /// Return the type representing the built-in type 'num'.
  InterfaceType get numType;

  /// Return the type representing the built-in type 'Object'.
  InterfaceType get objectType;

  /// Return the element representing the built-in class 'Set'.
  ClassElement get setElement;

  /// Return the type representing the built-in type 'Set'.
  @Deprecated('Use setType2() instead.')
  InterfaceType get setType;

  /// Return the type representing the built-in type 'StackTrace'.
  InterfaceType get stackTraceType;

  /// Return the type representing 'Stream<dynamic>'.
  InterfaceType get streamDynamicType;

  /// Return the element representing the built-in class 'Stream'.
  ClassElement get streamElement;

  /// Return the type representing the built-in type 'Stream'.
  @Deprecated('Use streamType2() instead.')
  InterfaceType get streamType;

  /// Return the type representing the built-in type 'String'.
  InterfaceType get stringType;

  /// Return the element representing the built-in class 'Symbol'.
  ClassElement get symbolElement;

  /// Return the type representing the built-in type 'Symbol'.
  InterfaceType get symbolType;

  /// Return the type representing the built-in type 'Type'.
  InterfaceType get typeType;

  /// Return the type representing the built-in type `void`.
  VoidType get voidType;

  /// Return the instantiation of the built-in class 'FutureOr' with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureOrType2(DartType valueType);

  /// Return the instantiation of the built-in class 'Future' with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureType2(DartType valueType);

  /// Return 'true' if [id] is the name of a getter on
  /// the Object type.
  bool isObjectGetter(String id);

  /// Return 'true' if [id] is the name of a method or getter on
  /// the Object type.
  bool isObjectMember(String id);

  /// Return 'true' if [id] is the name of a method on
  /// the Object type.
  bool isObjectMethod(String id);

  /// Return the instantiation of the built-in class 'Iterable' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType iterableType2(DartType elementType);

  /// Return the instantiation of the built-in class 'List' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType listType2(DartType elementType);

  /// Return the instantiation of the built-in class 'List' with the
  /// given [keyType] and [valueType]. The type has the nullability suffix of
  /// this provider.
  InterfaceType mapType2(DartType keyType, DartType valueType);

  /// Return the instantiation of the built-in class 'Set' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType setType2(DartType elementType);

  /// Return the instantiation of the built-in class 'Stream' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType streamType2(DartType elementType);
}

/// Instances of the class [UnusedLocalElementsVerifier] traverse an AST
/// looking for cases of [HintCode.UNUSED_ELEMENT], [HintCode.UNUSED_FIELD],
/// [HintCode.UNUSED_LOCAL_VARIABLE], etc.
class UnusedLocalElementsVerifier extends RecursiveAstVisitor {
  /// The error listener to which errors will be reported.
  final AnalysisErrorListener _errorListener;

  /// The elements know to be used.
  final UsedLocalElements _usedElements;

  /// Create a new instance of the [UnusedLocalElementsVerifier].
  UnusedLocalElementsVerifier(this._errorListener, this._usedElements);

  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      var element = node.staticElement;
      if (element is ClassElement) {
        _visitClassElement(element);
      } else if (element is FieldElement) {
        _visitFieldElement(element);
      } else if (element is FunctionElement) {
        _visitFunctionElement(element);
      } else if (element is FunctionTypeAliasElement) {
        _visitFunctionTypeAliasElement(element);
      } else if (element is LocalVariableElement) {
        _visitLocalVariableElement(element);
      } else if (element is MethodElement) {
        _visitMethodElement(element);
      } else if (element is PropertyAccessorElement) {
        _visitPropertyAccessorElement(element);
      } else if (element is TopLevelVariableElement) {
        _visitTopLevelVariableElement(element);
      }
    }
  }

  bool _isNamedUnderscore(LocalVariableElement element) {
    String name = element.name;
    if (name != null) {
      for (int index = name.length - 1; index >= 0; --index) {
        if (name.codeUnitAt(index) != 0x5F) {
          // 0x5F => '_'
          return false;
        }
      }
      return true;
    }
    return false;
  }

  bool _isReadMember(Element element) {
    if (element.isPublic) {
      return true;
    }
    if (element.isSynthetic) {
      return true;
    }
    return _usedElements.readMembers.contains(element.displayName);
  }

  bool _isUsedElement(Element element) {
    if (element.isSynthetic) {
      return true;
    }
    if (element is LocalVariableElement ||
        element is FunctionElement && !element.isStatic) {
      // local variable or function
    } else {
      if (element.isPublic) {
        return true;
      }
    }
    return _usedElements.elements.contains(element);
  }

  bool _isUsedMember(Element element) {
    if (element.isPublic) {
      return true;
    }
    if (element.isSynthetic) {
      return true;
    }
    if (_usedElements.members.contains(element.displayName)) {
      return true;
    }
    return _usedElements.elements.contains(element);
  }

  void _reportErrorForElement(
      ErrorCode errorCode, Element element, List<Object> arguments) {
    if (element != null) {
      _errorListener.onError(new AnalysisError(element.source,
          element.nameOffset, element.nameLength, errorCode, arguments));
    }
  }

  _visitClassElement(ClassElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  _visitFieldElement(FieldElement element) {
    if (!_isReadMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_FIELD, element, [element.displayName]);
    }
  }

  _visitFunctionElement(FunctionElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  _visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  _visitLocalVariableElement(LocalVariableElement element) {
    if (!_isUsedElement(element) && !_isNamedUnderscore(element)) {
      HintCode errorCode;
      if (_usedElements.isCatchException(element)) {
        errorCode = HintCode.UNUSED_CATCH_CLAUSE;
      } else if (_usedElements.isCatchStackTrace(element)) {
        errorCode = HintCode.UNUSED_CATCH_STACK;
      } else {
        errorCode = HintCode.UNUSED_LOCAL_VARIABLE;
      }
      _reportErrorForElement(errorCode, element, [element.displayName]);
    }
  }

  _visitMethodElement(MethodElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  _visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  _visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }
}

/// A container with sets of used [Element]s.
/// All these elements are defined in a single compilation unit or a library.
class UsedLocalElements {
  /// Resolved, locally defined elements that are used or potentially can be
  /// used.
  final HashSet<Element> elements = new HashSet<Element>();

  /// [LocalVariableElement]s that represent exceptions in [CatchClause]s.
  final HashSet<LocalVariableElement> catchExceptionElements =
      new HashSet<LocalVariableElement>();

  /// [LocalVariableElement]s that represent stack traces in [CatchClause]s.
  final HashSet<LocalVariableElement> catchStackTraceElements =
      new HashSet<LocalVariableElement>();

  /// Names of resolved or unresolved class members that are referenced in the
  /// library.
  final HashSet<String> members = new HashSet<String>();

  /// Names of resolved or unresolved class members that are read in the
  /// library.
  final HashSet<String> readMembers = new HashSet<String>();

  UsedLocalElements();

  factory UsedLocalElements.merge(List<UsedLocalElements> parts) {
    UsedLocalElements result = new UsedLocalElements();
    int length = parts.length;
    for (int i = 0; i < length; i++) {
      UsedLocalElements part = parts[i];
      result.elements.addAll(part.elements);
      result.catchExceptionElements.addAll(part.catchExceptionElements);
      result.catchStackTraceElements.addAll(part.catchStackTraceElements);
      result.members.addAll(part.members);
      result.readMembers.addAll(part.readMembers);
    }
    return result;
  }

  void addCatchException(LocalVariableElement element) {
    if (element != null) {
      catchExceptionElements.add(element);
    }
  }

  void addCatchStackTrace(LocalVariableElement element) {
    if (element != null) {
      catchStackTraceElements.add(element);
    }
  }

  void addElement(Element element) {
    if (element != null) {
      elements.add(element);
    }
  }

  bool isCatchException(LocalVariableElement element) {
    return catchExceptionElements.contains(element);
  }

  bool isCatchStackTrace(LocalVariableElement element) {
    return catchStackTraceElements.contains(element);
  }
}

/// Instances of the class `VariableResolverVisitor` are used to resolve
/// [SimpleIdentifier]s to local variables and formal parameters.
class VariableResolverVisitor extends ScopedVisitor {
  /// The method or function that we are currently visiting, or `null` if we are
  /// not inside a method or function.
  ExecutableElement _enclosingFunction;

  /// The container with information about local variables.
  final LocalVariableInfo _localVariableInfo = LocalVariableInfo();

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// [definingLibrary] is the element for the library containing the node being
  /// visited.
  /// [source] is the source representing the compilation unit containing the
  /// node being visited
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  VariableResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    assert(_localVariableInfo != null);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    assert(_localVariableInfo != null);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.functionExpression.body as FunctionBodyImpl).localVariableInfo =
          _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
        (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
        _enclosingFunction = node.declaredElement;
        super.visitFunctionExpression(node);
      } finally {
        _enclosingFunction = outerFunction;
      }
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if already resolved - declaration or type.
    if (node.inDeclarationContext()) {
      return;
    }
    // Ignore if it cannot be a reference to a local variable.
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorDeclaration && parent.returnType == node) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    }
    // Ignore if qualified.
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      return;
    }
    if (parent is MethodInvocation &&
        identical(parent.methodName, node) &&
        parent.realTarget != null) {
      return;
    }
    if (parent is ConstructorName) {
      return;
    }
    if (parent is Label) {
      return;
    }
    // Prepare VariableElement.
    Element element = nameScope.lookup(node, definingLibrary);
    if (element is! VariableElement) {
      return;
    }
    // Must be local or parameter.
    ElementKind kind = element.kind;
    if (kind == ElementKind.LOCAL_VARIABLE || kind == ElementKind.PARAMETER) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        _localVariableInfo.potentiallyMutatedInScope.add(element);
        if (element.enclosingElement != _enclosingFunction) {
          _localVariableInfo.potentiallyMutatedInClosure.add(element);
        }
      }
    }
  }

  @override
  void visitTypeName(TypeName node) {}
}

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';
  static final _testDir = '${path.separator}test${path.separator}';
  static final _testingDir = '${path.separator}testing${path.separator}';

  final ErrorReporter _errorReporter;
  final LibraryElement _library;

  bool _inTemplateSource;
  bool _inTestDirectory;

  ClassElement _enclosingClass;

  _InvalidAccessVerifier(this._errorReporter, this._library) {
    var path = _library.source.fullName;
    _inTemplateSource = path.contains(_templateExtension);
    _inTestDirectory = path.contains(_testDir) || path.contains(_testingDir);
  }

  /// Produces a hint if [identifier] is accessed from an invalid location. In
  /// particular:
  ///
  /// * if the given identifier is a protected closure, field or
  ///   getter/setter, method closure or invocation accessed outside a subclass,
  ///   or accessed outside the library wherein the identifier is declared, or
  /// * if the given identifier is a closure, field, getter, setter, method
  ///   closure or invocation which is annotated with `visibleForTemplate`, and
  ///   is accessed outside of the defining library, and the current library
  ///   does not have the suffix '.template' in its source path, or
  /// * if the given identifier is a closure, field, getter, setter, method
  ///   closure or invocation which is annotated with `visibleForTesting`, and
  ///   is accessed outside of the defining library, and the current library
  ///   does not have a directory named 'test' or 'testing' in its path.
  void verify(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext() || _inCommentReference(identifier)) {
      return;
    }

    Element element = identifier.staticElement;
    if (element == null || _inCurrentLibrary(element)) {
      return;
    }

    bool hasProtected = _hasProtected(element);
    if (hasProtected) {
      ClassElement definingClass = element.enclosingElement;
      if (_hasTypeOrSuperType(_enclosingClass, definingClass)) {
        return;
      }
    }

    bool hasVisibleForTemplate = _hasVisibleForTemplate(element);
    if (hasVisibleForTemplate) {
      if (_inTemplateSource || _inExportDirective(identifier)) {
        return;
      }
    }

    bool hasVisibleForTesting = _hasVisibleForTesting(element);
    if (hasVisibleForTesting) {
      if (_inTestDirectory || _inExportDirective(identifier)) {
        return;
      }
    }

    // At this point, [identifier] was not cleared as protected access, nor
    // cleared as access for templates or testing. Report the appropriate
    // violation(s).
    Element definingClass = element.enclosingElement;
    if (hasProtected) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_PROTECTED_MEMBER,
          identifier,
          [identifier.name, definingClass.source.uri]);
    }
    if (hasVisibleForTemplate) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
          identifier,
          [identifier.name, definingClass.source.uri]);
    }
    if (hasVisibleForTesting) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
          identifier,
          [identifier.name, definingClass.source.uri]);
    }
  }

  bool _hasProtected(Element element) {
    if (element is PropertyAccessorElement &&
        element.enclosingElement is ClassElement &&
        (element.hasProtected || element.variable.hasProtected)) {
      return true;
    }
    if (element is MethodElement &&
        element.enclosingElement is ClassElement &&
        element.hasProtected) {
      return true;
    }
    return false;
  }

  bool _hasTypeOrSuperType(ClassElement element, ClassElement superElement) {
    if (element == null) {
      return false;
    }
    if (element == superElement) {
      return true;
    }
    // TODO(scheglov) `allSupertypes` is very expensive
    var allSupertypes = element.allSupertypes;
    for (var i = 0; i < allSupertypes.length; i++) {
      var supertype = allSupertypes[i];
      if (supertype.element == superElement) {
        return true;
      }
    }
    return false;
  }

  bool _hasVisibleForTemplate(Element element) {
    if (element == null) {
      return false;
    }
    if (element.hasVisibleForTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.enclosingElement is ClassElement &&
        element.variable.hasVisibleForTemplate) {
      return true;
    }
    return false;
  }

  bool _hasVisibleForTesting(Element element) {
    if (element == null) {
      return false;
    }
    if (element.hasVisibleForTesting) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.enclosingElement is ClassElement &&
        element.variable.hasVisibleForTesting) {
      return true;
    }
    return false;
  }

  bool _inCommentReference(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is CommentReference || parent?.parent is CommentReference;
  }

  bool _inCurrentLibrary(Element element) => element.library == _library;

  bool _inExportDirective(SimpleIdentifier identifier) =>
      identifier.parent is Combinator &&
      identifier.parent.parent is ExportDirective;
}

/// An object used to track the usage of labels within a single label scope.
class _LabelTracker {
  /// The tracker for the outer label scope.
  final _LabelTracker outerTracker;

  /// The labels whose usage is being tracked.
  final List<Label> labels;

  /// A list of flags corresponding to the list of [labels] indicating whether
  /// the corresponding label has been used.
  List<bool> used;

  /// A map from the names of labels to the index of the label in [labels].
  final Map<String, int> labelMap = <String, int>{};

  /// Initialize a newly created label tracker.
  _LabelTracker(this.outerTracker, this.labels) {
    used = new List.filled(labels.length, false);
    for (int i = 0; i < labels.length; i++) {
      labelMap[labels[i].label.name] = i;
    }
  }

  /// Record that the label with the given [labelName] has been used.
  void recordUsage(String labelName) {
    if (labelName != null) {
      int index = labelMap[labelName];
      if (index != null) {
        used[index] = true;
      } else if (outerTracker != null) {
        outerTracker.recordUsage(labelName);
      }
    }
  }

  /// Return the unused labels.
  Iterable<Label> unusedLabels() sync* {
    for (int i = 0; i < labels.length; i++) {
      if (!used[i]) {
        yield labels[i];
      }
    }
  }
}

/// A set of counts of the kinds of leaf elements in a collection, used to help
/// disambiguate map and set literals.
class _LeafElements {
  /// The number of expressions found in the collection.
  int expressionCount = 0;

  /// The number of map entries found in the collection.
  int mapEntryCount = 0;

  /// Initialize a newly created set of counts based on the given collection
  /// [elements].
  _LeafElements(List<CollectionElement> elements) {
    for (CollectionElement element in elements) {
      _count(element);
    }
  }

  /// Return the resolution suggested by the set elements.
  _LiteralResolution get resolution {
    if (expressionCount > 0 && mapEntryCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.set, null);
    } else if (mapEntryCount > 0 && expressionCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.map, null);
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Recursively add the given collection [element] to the counts.
  void _count(CollectionElement element) {
    if (element is ForElement) {
      _count(element.body);
    } else if (element is IfElement) {
      _count(element.thenElement);
      _count(element.elseElement);
    } else if (element is Expression) {
      if (_isComplete(element)) {
        expressionCount++;
      }
    } else if (element is MapLiteralEntry) {
      if (_isComplete(element)) {
        mapEntryCount++;
      }
    }
  }

  /// Return `true` if the given collection [element] does not contain any
  /// synthetic tokens.
  bool _isComplete(CollectionElement element) {
    // TODO(paulberry,brianwilkerson): the code below doesn't work because it
    // assumes access to token offsets, which aren't available when working with
    // expressions resynthesized from summaries.  For now we just assume the
    // collection element is complete.
    return true;
//    Token token = element.beginToken;
//    int endOffset = element.endToken.offset;
//    while (token != null && token.offset <= endOffset) {
//      if (token.isSynthetic) {
//        return false;
//      }
//      token = token.next;
//    }
//    return true;
  }
}

/// An indication of the way in which a set or map literal should be resolved to
/// be either a set literal or a map literal.
class _LiteralResolution {
  /// The kind of collection that the literal should be.
  final _LiteralResolutionKind kind;

  /// The type that should be used as the inference context when performing type
  /// inference for the literal.
  DartType contextType;

  /// Initialize a newly created resolution.
  _LiteralResolution(this.kind, this.contextType);

  @override
  String toString() {
    return '$kind ($contextType)';
  }
}

/// The kind of literal to which an unknown literal should be resolved.
enum _LiteralResolutionKind { ambiguous, map, set }

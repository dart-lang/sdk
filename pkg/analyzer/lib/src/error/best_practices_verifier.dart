// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// Instances of the class `BestPracticesVerifier` traverse an AST structure
/// looking for violations of Dart best practices.
class BestPracticesVerifier extends RecursiveAstVisitor<void> {
//  static String _HASHCODE_GETTER_NAME = "hashCode";

  static const String _NULL_TYPE_NAME = "Null";

  static const String _TO_INT_METHOD_NAME = "toInt";

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
  final TypeSystemImpl _typeSystem;

  /// The inheritance manager to access interface type hierarchy.
  final InheritanceManager3 _inheritanceManager;

  /// The current library
  final LibraryElement _currentLibrary;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage _workspacePackage;

  /// The [LinterContext] used for possible const calculations.
  LinterContext _linterContext;

  /// Is `true` if the library being analyzed is non-nullable by default.
  final bool _isNonNullableByDefault;

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
    @required TypeSystemImpl typeSystem,
    @required InheritanceManager3 inheritanceManager,
    @required DeclaredVariables declaredVariables,
    @required AnalysisOptions analysisOptions,
    @required WorkspacePackage workspacePackage,
  })  : _nullType = typeProvider.nullType,
        _typeSystem = typeSystem,
        _isNonNullableByDefault = typeSystem.isNonNullableByDefault,
        _strictInference =
            (analysisOptions as AnalysisOptionsImpl).strictInference,
        _inheritanceManager = inheritanceManager,
        _invalidAccessVerifier =
            _InvalidAccessVerifier(_errorReporter, _currentLibrary),
        _workspacePackage = workspacePackage {
    _inDeprecatedMember = _currentLibrary.hasDeprecated;

    _linterContext = LinterContextImpl(
      null /* allUnits */,
      LinterContextUnit(content, unit),
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
        void reportInvalidAnnotation(Element declaredElement) {
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
    if (isUnnecessaryCast(node, _typeSystem)) {
      _errorReporter.reportErrorForNode(HintCode.UNNECESSARY_CAST, node);
    }
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
    _checkForInvariantNullComparison(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    _checkForNullableTypeInCatchClause(node);
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
    if (!_isNonNullableByDefault && node.declaredElement.isFactory) {
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
  void visitConstructorName(ConstructorName node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    super.visitConstructorName(node);
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
            Name name = Name(_currentLibrary.source.uri, element.name);
            Element enclosingElement = element.enclosingElement;
            if (enclosingElement is ClassElement) {
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
      if (node.parent is CompilationUnit && !node.isSetter) {
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

    Name name = Name(_currentLibrary.source.uri, element?.name ?? '');

    bool elementIsOverride() =>
        element is ClassMemberElement && enclosingElement is ClassElement
            ? _inheritanceManager.getOverridden2(enclosingElement, name) != null
            : false;
    ExecutableElement getConcreteOverriddenElement() =>
        element is ClassMemberElement && enclosingElement is ClassElement
            ? _inheritanceManager.getMember2(enclosingElement, name,
                forSuper: true)
            : null;
    ExecutableElement getOverriddenPropertyAccessor() =>
        element is PropertyAccessorElement && enclosingElement is ClassElement
            ? _inheritanceManager.getMember2(enclosingElement, name,
                forSuper: true)
            : null;

    if (element != null && element.hasDeprecated) {
      _inDeprecatedMember = true;
    }
    try {
      // This was determined to not be a good hint, see: dartbug.com/16029
      //checkForOverridingPrivateMember(node);
      _checkForMissingReturn(node.returnType, node.body, element, node);
      _checkForUnnecessaryNoSuchMethod(node);

      if (!node.isSetter && !elementIsOverride()) {
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
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _checkForDuplications(node);
    super.visitSetOrMapLiteral(node);
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
      if (rhsType.isDartCoreObject) {
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
      } else if (node is MethodInvocation &&
          displayName == FunctionElement.CALL_METHOD_NAME) {
        var invokeType = node.staticInvokeType as InterfaceType;
        if (invokeType is InterfaceType) {
          var invokeClass = invokeType.element;
          displayName = "${invokeClass.name}.${element.displayName}";
        }
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
        if (!alreadySeen.add(constEvaluation.value)) {
          var errorCode = node.isSet
              ? HintCode.EQUAL_ELEMENTS_IN_SET
              : HintCode.EQUAL_KEYS_IN_MAP;
          _errorReporter.reportErrorForNode(errorCode, expression);
        }
      }
    }
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
    if (isOrInheritsImmutable(element, HashSet<ClassElement>())) {
      Iterable<String> nonFinalFields =
          definedOrInheritedNonFinalInstanceFields(
              element, HashSet<ClassElement>());
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

  void _checkForInvariantNullComparison(BinaryExpression node) {
    if (!_isNonNullableByDefault) return;

    void reportStartEnd(
      HintCode errorCode,
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

    void checkLeftRight(HintCode errorCode) {
      if (node.leftOperand is NullLiteral) {
        var rightType = node.rightOperand.staticType;
        if (_typeSystem.isStrictlyNonNullable(rightType)) {
          reportStartEnd(errorCode, node.leftOperand, node.operator);
        }
      }

      if (node.rightOperand is NullLiteral) {
        var leftType = node.leftOperand.staticType;
        if (_typeSystem.isStrictlyNonNullable(leftType)) {
          reportStartEnd(errorCode, node.operator, node.rightOperand);
        }
      }
    }

    if (node.operator.type == TokenType.BANG_EQ) {
      checkLeftRight(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      checkLeftRight(HintCode.UNNECESSARY_NULL_COMPARISON_FALSE);
    }
  }

  /// Check that the instance creation node is const if the constructor is
  /// marked with [literal].
  void _checkForLiteralConstructorUse(InstanceCreationExpression node) {
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

    var bodyContext = BodyInferenceContext.of(body);
    // TODO(scheglov) Update InferenceContext to record any type, dynamic.
    var returnType = bodyContext.contextType ?? DynamicTypeImpl.instance;

    if (_typeSystem.isNullable(returnType)) {
      return;
    }

    if (ExitDetector.exits(body)) {
      return;
    }

    var errorNode = functionNode;
    if (functionNode is FunctionDeclaration) {
      errorNode = functionNode.name;
    } else if (functionNode is MethodDeclaration) {
      errorNode = functionNode.name;
    }

    _errorReporter.reportErrorForNode(
      HintCode.MISSING_RETURN,
      errorNode,
      [returnType],
    );
  }

  void _checkForNullableTypeInCatchClause(CatchClause node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var type = node.exceptionType;
    if (type == null) {
      return;
    }

    if (_typeSystem.isPotentiallyNullable(type.type)) {
      _errorReporter.reportErrorForNode(
        HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE,
        type,
      );
    }
  }

  /// Produce several null-aware related hints.
  void _checkForNullAwareHints(Expression node, Token operator) {
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
  void _checkStrictInferenceInParameters(FormalParameterList parameters) {
    void checkParameterTypeIsKnown(SimpleFormalParameter parameter) {
      if (parameter.type == null) {
        ParameterElement element = parameter.declaredElement;
        _errorReporter.reportErrorForNode(
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

  bool _isLibraryInWorkspacePackage(LibraryElement library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage.contains(library.source);
  }

  /// Checks for the passed as expression for the [HintCode.UNNECESSARY_CAST]
  /// hint code.
  ///
  /// Returns `true` if and only if an unnecessary cast hint should be generated
  /// on [node].  See [HintCode.UNNECESSARY_CAST].
  static bool isUnnecessaryCast(AsExpression node, TypeSystemImpl typeSystem) {
    var leftType = node.expression.staticType;
    var rightType = node.type.type;

    // `dynamicValue as SomeType` is a valid use case.
    if (leftType.isDynamic) {
      return false;
    }

    // `x as Unresolved` is already reported as an error.
    if (rightType.isDynamic) {
      return false;
    }

    // The cast is necessary.
    if (!typeSystem.isSubtypeOf2(leftType, rightType)) {
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
        node.staticType,
        other.staticType,
      );

      var typeWithoutCast = typeSystem.leastUpperBound(
        node.expression.staticType,
        other.staticType,
      );

      if (typeWithoutCast != currentType) {
        return false;
      }
    }

    return true;
  }

  /// Return the message in the deprecated annotation on the given [element], or
  /// `null` if the element doesn't have a deprecated annotation or if the
  /// annotation does not have a message.
  static String _deprecatedMessage(Element element) {
    // Implicit getters/setters.
    if (element.isSynthetic && element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
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

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';
  static final _testDir = '${path.separator}test${path.separator}';
  static final _testDriverDir = '${path.separator}test_driver${path.separator}';
  static final _testingDir = '${path.separator}testing${path.separator}';

  final ErrorReporter _errorReporter;
  final LibraryElement _library;

  bool _inTemplateSource;
  bool _inTestDirectory;

  ClassElement _enclosingClass;

  _InvalidAccessVerifier(this._errorReporter, this._library) {
    var path = _library.source.fullName;
    _inTemplateSource = path.contains(_templateExtension);
    _inTestDirectory = path.contains(_testDir) ||
        path.contains(_testDriverDir) ||
        path.contains(_testingDir);
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

    // This is the same logic used in [checkForDeprecatedMemberUseAtIdentifier]
    // to avoid reporting an error twice for named constructors.
    AstNode parent = identifier.parent;
    if (parent is ConstructorName && identical(identifier, parent.name)) {
      return;
    }
    AstNode grandparent = parent?.parent;

    Element element;
    String name;
    AstNode node;

    if (grandparent is ConstructorName) {
      element = grandparent.staticElement;
      name = grandparent.toSource();
      node = grandparent;
    } else {
      element = identifier.staticElement;
      name = identifier.name;
      node = identifier;
    }

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
          node,
          [name, definingClass.source.uri]);
    }
    if (hasVisibleForTemplate) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
          node,
          [name, definingClass.source.uri]);
    }

    if (hasVisibleForTesting) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
          node,
          [name, definingClass.source.uri]);
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
    return element.thisType.asInstanceOf(superElement) != null;
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

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.resolver;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

export 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
export 'package:analyzer/src/dart/resolver/scope.dart';
export 'package:analyzer/src/generated/type_system.dart';

/**
 * Instances of the class `BestPracticesVerifier` traverse an AST structure looking for
 * violations of Dart best practices.
 */
class BestPracticesVerifier extends RecursiveAstVisitor<Object> {
//  static String _HASHCODE_GETTER_NAME = "hashCode";

  static String _NULL_TYPE_NAME = "Null";

  static String _TO_INT_METHOD_NAME = "toInt";

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElementImpl _enclosingClass;

  /**
   * A flag indicating whether a surrounding member (compilation unit or class)
   * is deprecated.
   */
  bool inDeprecatedMember;

  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * The type [Null].
   */
  final InterfaceType _nullType;

  /**
   * The type Future<Null>, which is needed for determining whether it is safe
   * to have a bare "return;" in an async method.
   */
  final InterfaceType _futureNullType;

  /**
   * The type system primitives
   */
  TypeSystem _typeSystem;

  /**
   * The current library
   */
  LibraryElement _currentLibrary;

  /**
   * The inheritance manager used to find overridden methods.
   */
  InheritanceManager _manager;

  /**
   * Create a new instance of the [BestPracticesVerifier].
   *
   * @param errorReporter the error reporter
   */
  BestPracticesVerifier(this._errorReporter, TypeProvider typeProvider,
      this._currentLibrary, this._manager,
      {TypeSystem typeSystem})
      : _nullType = typeProvider.nullType,
        _futureNullType = typeProvider.futureNullType,
        _typeSystem = typeSystem ?? new TypeSystemImpl(typeProvider) {
    inDeprecatedMember = _currentLibrary.isDeprecated;
  }

  @override
  Object visitAnnotation(Annotation node) {
    ElementAnnotation element =
        resolutionMap.elementAnnotationForAnnotation(node);
    if (element?.isFactory == true) {
      AstNode parent = node.parent;
      if (parent is MethodDeclaration) {
        _checkForInvalidFactory(parent);
      } else {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_FACTORY_ANNOTATION, node, []);
      }
    } else if (element?.isImmutable == true) {
      AstNode parent = node.parent;
      if (parent is! ClassDeclaration) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_IMMUTABLE_ANNOTATION, node, []);
      }
    }
    return super.visitAnnotation(node);
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    for (Expression argument in node.arguments) {
      ParameterElement parameter = argument.bestParameterElement;
      if (parameter?.parameterKind == ParameterKind.POSITIONAL) {
        _checkForDeprecatedMemberUse(parameter, argument);
      }
    }
    _checkForArgumentTypesNotAssignableInList(node);
    return super.visitArgumentList(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _checkForUnnecessaryCast(node);
    return super.visitAsExpression(node);
  }

  @override
  Object visitAssertInitializer(AssertInitializer node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitAssertInitializer(node);
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitAssertStatement(node);
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    if (operatorType == TokenType.EQ) {
      _checkForUseOfVoidResult(node.rightHandSide);
      _checkForInvalidAssignment(node.leftHandSide, node.rightHandSide);
    } else {
      _checkForDeprecatedMemberUse(node.bestElement, node);
    }
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    _checkForDivisionOptimizationHint(node);
    _checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElementImpl outerClass = _enclosingClass;
    bool wasInDeprecatedMember = inDeprecatedMember;
    ClassElement element = AbstractClassElementImpl.getImpl(node.element);
    if (element != null && element.isDeprecated) {
      inDeprecatedMember = true;
    }
    try {
      _enclosingClass = element;
      // Commented out until we decide that we want this hint in the analyzer
      //    checkForOverrideEqualsButNotHashCode(node);
      _checkForImmutable(node);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
      inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitConditionalExpression(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (resolutionMap.elementDeclaredByConstructorDeclaration(node).isFactory) {
      if (node.body is BlockFunctionBody) {
        // Check the block for a return statement, if not, create the hint.
        if (!ExitDetector.exits(node.body)) {
          _errorReporter.reportErrorForNode(
              HintCode.MISSING_RETURN, node, [node.returnType.name]);
        }
      }
    }
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitDoStatement(DoStatement node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitDoStatement(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
    _checkRequiredParameter(node);
    return super.visitFormalParameterList(node);
  }

  @override
  Object visitForStatement(ForStatement node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitForStatement(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    bool wasInDeprecatedMember = inDeprecatedMember;
    ExecutableElement element = node.element;
    if (element != null && element.isDeprecated) {
      inDeprecatedMember = true;
    }
    try {
      _checkForMissingReturn(node.returnType, node.functionExpression.body);
      return super.visitFunctionDeclaration(node);
    } finally {
      inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  Object visitIfStatement(IfStatement node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitIfStatement(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    ImportElement importElement = node.element;
    if (importElement != null && importElement.isDeferred) {
      _checkForLoadLibraryFunction(node, importElement);
    }
    return super.visitImportDirective(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    _checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitIndexExpression(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _checkAllTypeChecks(node);
    return super.visitIsExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    bool wasInDeprecatedMember = inDeprecatedMember;
    ExecutableElement element = node.element;
    if (element != null && element.isDeprecated) {
      inDeprecatedMember = true;
    }
    try {
      // This was determined to not be a good hint, see: dartbug.com/16029
      //checkForOverridingPrivateMember(node);
      _checkForMissingReturn(node.returnType, node.body);
      _checkForUnnecessaryNoSuchMethod(node);
      return super.visitMethodDeclaration(node);
    } finally {
      inDeprecatedMember = wasInDeprecatedMember;
    }
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    Expression realTarget = node.realTarget;
    _checkForAbstractSuperMemberReference(realTarget, node.methodName);
    _checkForCanBeNullAfterNullAware(
        realTarget, node.operator, null, node.methodName);
    DartType staticInvokeType = node.staticInvokeType;
    if (staticInvokeType is InterfaceType) {
      MethodElement methodElement = staticInvokeType.lookUpMethod(
          FunctionElement.CALL_METHOD_NAME, _currentLibrary);
      _checkForDeprecatedMemberUse(methodElement, node);
    }
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    _checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    _checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    Expression realTarget = node.realTarget;
    _checkForAbstractSuperMemberReference(realTarget, node.propertyName);
    _checkForCanBeNullAfterNullAware(
        realTarget, node.operator, node.propertyName, null);
    return super.visitPropertyAccess(node);
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForDeprecatedMemberUseAtIdentifier(node);
    _checkForInvalidProtectedMemberAccess(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitSuperConstructorInvocation(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    _checkForUseOfVoidResult(node.initializer);
    _checkForInvalidAssignment(node.name, node.initializer);
    return super.visitVariableDeclaration(node);
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    _checkForPossibleNullCondition(node.condition);
    return super.visitWhileStatement(node);
  }

  /**
   * Check for the passed is expression for the unnecessary type check hint codes as well as null
   * checks expressed using an is expression.
   *
   * @param node the is expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.TYPE_CHECK_IS_NOT_NULL], [HintCode.TYPE_CHECK_IS_NULL],
   * [HintCode.UNNECESSARY_TYPE_CHECK_TRUE], and
   * [HintCode.UNNECESSARY_TYPE_CHECK_FALSE].
   */
  bool _checkAllTypeChecks(IsExpression node) {
    Expression expression = node.expression;
    TypeAnnotation typeName = node.type;
    DartType lhsType = expression.staticType;
    DartType rhsType = typeName.type;
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
      // if x is Object or null is Null
      if (rhsType.isObject ||
          (expression is NullLiteral && rhsNameStr == _NULL_TYPE_NAME)) {
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
      } else if (rhsNameStr == _NULL_TYPE_NAME) {
        if (node.notOperator == null) {
          // the is case
          _errorReporter.reportErrorForNode(HintCode.TYPE_CHECK_IS_NULL, node);
        } else {
          // the is not case
          _errorReporter.reportErrorForNode(
              HintCode.TYPE_CHECK_IS_NOT_NULL, node);
        }
        return true;
      }
    }
    return false;
  }

  void _checkForAbstractSuperMemberReference(
      Expression target, SimpleIdentifier name) {
    if (target is SuperExpression &&
        !_currentLibrary.context.analysisOptions.enableSuperMixins) {
      Element element = name.staticElement;
      if (element is ExecutableElement && element.isAbstract) {
        if (!_enclosingClass.hasNoSuchMethod) {
          ExecutableElement concrete = null;
          if (element.kind == ElementKind.METHOD) {
            concrete = _enclosingClass.lookUpInheritedConcreteMethod(
                element.displayName, _currentLibrary);
          } else if (element.kind == ElementKind.GETTER) {
            concrete = _enclosingClass.lookUpInheritedConcreteGetter(
                element.displayName, _currentLibrary);
          } else if (element.kind == ElementKind.SETTER) {
            concrete = _enclosingClass.lookUpInheritedConcreteSetter(
                element.displayName, _currentLibrary);
          }
          if (concrete == null) {
            _errorReporter.reportTypeErrorForNode(
                HintCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
                name,
                [element.kind.displayName, name.name]);
          }
        }
      }
    }
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * This method corresponds to ErrorVerifier.checkForArgumentTypeNotAssignable.
   *
   * TODO (jwren) In the ErrorVerifier there are other warnings that we could have a corresponding
   * hint for: see other callers of ErrorVerifier.checkForArgumentTypeNotAssignable(..).
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type of the parameter
   * @param actualStaticType the actual static type of the argument
   * @param expectedPropagatedType the expected propagated type of the parameter, may be
   *          `null`
   * @param actualPropagatedType the expected propagated type of the parameter, may be `null`
   * @return `true` if and only if an hint code is generated on the passed node
   * See [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignable(
      Expression expression,
      DartType expectedStaticType,
      DartType actualStaticType,
      DartType expectedPropagatedType,
      DartType actualPropagatedType,
      ErrorCode hintCode) {
    //
    // Warning case: test static type information
    //
    if (actualStaticType != null && expectedStaticType != null) {
      if (!_typeSystem.isAssignableTo(actualStaticType, expectedStaticType)) {
        // A warning was created in the ErrorVerifier, return false, don't
        // create a hint when a warning has already been created.
        return false;
      }
    }
    //
    // Hint case: test propagated type information
    //
    // Compute the best types to use.
    DartType expectedBestType = expectedPropagatedType ?? expectedStaticType;
    DartType actualBestType = actualPropagatedType ?? actualStaticType;
    if (actualBestType != null && expectedBestType != null) {
      if (!_typeSystem.isAssignableTo(actualBestType, expectedBestType)) {
        _errorReporter.reportTypeErrorForNode(
            hintCode, expression, [actualBestType, expectedBestType]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed argument can be assigned to its corresponding parameter.
   *
   * This method corresponds to ErrorCode.checkForArgumentTypeNotAssignableForArgument.
   *
   * @param argument the argument to evaluate
   * @return `true` if and only if an hint code is generated on the passed node
   * See [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignableForArgument(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    DartType staticParameterType = staticParameterElement?.type;
    ParameterElement propagatedParameterElement =
        argument.propagatedParameterElement;
    DartType propagatedParameterType = propagatedParameterElement?.type;
    return _checkForArgumentTypeNotAssignableWithExpectedTypes(
        argument,
        staticParameterType,
        propagatedParameterType,
        HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * This method corresponds to ErrorCode.checkForArgumentTypeNotAssignableWithExpectedTypes.
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type
   * @param expectedPropagatedType the expected propagated type, may be `null`
   * @return `true` if and only if an hint code is generated on the passed node
   * See [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignableWithExpectedTypes(
          Expression expression,
          DartType expectedStaticType,
          DartType expectedPropagatedType,
          ErrorCode errorCode) =>
      _checkForArgumentTypeNotAssignable(
          expression,
          expectedStaticType,
          expression.staticType,
          expectedPropagatedType,
          expression.propagatedType,
          errorCode);

  /**
   * This verifies that the passed arguments can be assigned to their corresponding parameters.
   *
   * This method corresponds to ErrorCode.checkForArgumentTypesNotAssignableInList.
   *
   * @param node the arguments to evaluate
   * @return `true` if and only if an hint code is generated on the passed node
   * See [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypesNotAssignableInList(ArgumentList argumentList) {
    if (argumentList == null) {
      return false;
    }
    bool problemReported = false;
    for (Expression argument in argumentList.arguments) {
      if (_checkForArgumentTypeNotAssignableForArgument(argument)) {
        problemReported = true;
      }
    }
    return problemReported;
  }

  /**
   * Produce a hint if the given [target] could have a value of `null`, and
   * [identifier] is not a name of a getter or a method that exists in the
   * class [Null].
   */
  void _checkForCanBeNullAfterNullAware(Expression target, Token operator,
      SimpleIdentifier propertyName, SimpleIdentifier methodName) {
    if (operator?.type == TokenType.QUESTION_PERIOD) {
      return;
    }
    bool isNullTypeMember() {
      if (propertyName != null) {
        String name = propertyName.name;
        return _nullType.lookUpGetter(name, _currentLibrary) != null;
      }
      if (methodName != null) {
        String name = methodName.name;
        return _nullType.lookUpMethod(name, _currentLibrary) != null;
      }
      return false;
    }

    target = target?.unParenthesized;
    if (target is MethodInvocation) {
      if (target.operator?.type == TokenType.QUESTION_PERIOD &&
          !isNullTypeMember()) {
        _errorReporter.reportErrorForNode(
            HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, target);
      }
    } else if (target is PropertyAccess) {
      if (target.operator.type == TokenType.QUESTION_PERIOD &&
          !isNullTypeMember()) {
        _errorReporter.reportErrorForNode(
            HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, target);
      }
    }
  }

  /**
   * Given some [Element], look at the associated metadata and report the use of the member if
   * it is declared as deprecated.
   *
   * @param element some element to check for deprecated use of
   * @param node the node use for the location of the error
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.DEPRECATED_MEMBER_USE].
   */
  void _checkForDeprecatedMemberUse(Element element, AstNode node) {
    bool isDeprecated(Element element) {
      if (element == null) {
        return false;
      } else if (element is PropertyAccessorElement && element.isSynthetic) {
        // TODO(brianwilkerson) Why isn't this the implementation for PropertyAccessorElement?
        Element variable = element.variable;
        if (variable == null) {
          return false;
        }
        return variable.isDeprecated;
      }
      return element.isDeprecated;
    }

    if (!inDeprecatedMember && isDeprecated(element)) {
      String displayName = element.displayName;
      if (element is ConstructorElement) {
        // TODO(jwren) We should modify ConstructorElement.getDisplayName(),
        // or have the logic centralized elsewhere, instead of doing this logic
        // here.
        displayName = element.enclosingElement.displayName;
        if (!element.displayName.isEmpty) {
          displayName = "$displayName.${element.displayName}";
        }
      } else if (displayName == FunctionElement.CALL_METHOD_NAME &&
          node is MethodInvocation &&
          node.staticInvokeType is InterfaceType) {
        displayName = "${resolutionMap
            .staticInvokeTypeForInvocationExpression(node)
            .displayName}.${element.displayName}";
      }
      _errorReporter.reportErrorForNode(
          HintCode.DEPRECATED_MEMBER_USE, node, [displayName]);
    }
  }

  /**
   * For [SimpleIdentifier]s, only call [checkForDeprecatedMemberUse]
   * if the node is not in a declaration context.
   *
   * Also, if the identifier is a constructor name in a constructor invocation, then calls to the
   * deprecated constructor will be caught by
   * [visitInstanceCreationExpression] and
   * [visitSuperConstructorInvocation], and can be ignored by
   * this visit method.
   *
   * @param identifier some simple identifier to check for deprecated use of
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.DEPRECATED_MEMBER_USE].
   */
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
    _checkForDeprecatedMemberUse(identifier.bestElement, identifier);
  }

  /**
   * Check for the passed binary expression for the [HintCode.DIVISION_OPTIMIZATION].
   *
   * @param node the binary expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.DIVISION_OPTIMIZATION].
   */
  bool _checkForDivisionOptimizationHint(BinaryExpression node) {
    // Return if the operator is not '/'
    if (node.operator.type != TokenType.SLASH) {
      return false;
    }
    // Return if the '/' operator is not defined in core, or if we don't know
    // its static or propagated type
    MethodElement methodElement = node.bestElement;
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

  void _checkForImmutable(ClassDeclaration node) {
    /**
     * Return `true` if the given class [element] is annotated with the
     * `@immutable` annotation.
     */
    bool isImmutable(ClassElement element) {
      for (ElementAnnotation annotation in element.metadata) {
        if (annotation.isImmutable) {
          return true;
        }
      }
      return false;
    }

    /**
     * Return `true` if the given class [element] or any superclass of it is
     * annotated with the `@immutable` annotation.
     */
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

    /**
     * Return `true` if the given class [element] defines a non-final instance
     * field.
     */
    bool hasNonFinalInstanceField(ClassElement element) {
      for (FieldElement field in element.fields) {
        if (!field.isSynthetic && !field.isFinal && !field.isStatic) {
          return true;
        }
      }
      return false;
    }

    /**
     * Return `true` if the given class [element] defines or inherits a
     * non-final field.
     */
    bool hasOrInheritsNonFinalInstanceField(
        ClassElement element, HashSet<ClassElement> visited) {
      if (visited.add(element)) {
        if (hasNonFinalInstanceField(element)) {
          return true;
        }
        for (InterfaceType mixin in element.mixins) {
          if (hasNonFinalInstanceField(mixin.element)) {
            return true;
          }
        }
        if (element.supertype != null) {
          return hasOrInheritsNonFinalInstanceField(
              element.supertype.element, visited);
        }
      }
      return false;
    }

    ClassElement element = node.element;
    if (isOrInheritsImmutable(element, new HashSet<ClassElement>()) &&
        hasOrInheritsNonFinalInstanceField(
            element, new HashSet<ClassElement>())) {
      _errorReporter.reportErrorForNode(HintCode.MUST_BE_IMMUTABLE, node.name);
    }
  }

  /**
   * This verifies that the passed left hand side and right hand side represent a valid assignment.
   *
   * This method corresponds to ErrorVerifier.checkForInvalidAssignment.
   *
   * @param lhs the left hand side expression
   * @param rhs the right hand side expression
   * @return `true` if and only if an error code is generated on the passed node
   * See [HintCode.INVALID_ASSIGNMENT].
   */
  bool _checkForInvalidAssignment(Expression lhs, Expression rhs) {
    if (lhs == null || rhs == null) {
      return false;
    }
    VariableElement leftVariableElement = ErrorVerifier.getVariableElement(lhs);
    DartType leftType = (leftVariableElement == null)
        ? ErrorVerifier.getStaticType(lhs)
        : leftVariableElement.type;
    DartType staticRightType = ErrorVerifier.getStaticType(rhs);
    if (!_typeSystem.isAssignableTo(staticRightType, leftType,
        isDeclarationCast: true)) {
      // The warning was generated on this rhs
      return false;
    }
    // Test for, and then generate the hint
    DartType bestRightType = rhs.bestType;
    if (leftType != null && bestRightType != null) {
      if (!_typeSystem.isAssignableTo(bestRightType, leftType,
          isDeclarationCast: true)) {
        _errorReporter.reportTypeErrorForNode(
            HintCode.INVALID_ASSIGNMENT, rhs, [bestRightType, leftType]);
        return true;
      }
    }
    return false;
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

  /**
   * Produces a hint if the given identifier is a protected closure, field or
   * getter/setter, method closure or invocation accessed outside a subclass.
   */
  void _checkForInvalidProtectedMemberAccess(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return;
    }

    bool isProtected(Element element) {
      if (element is PropertyAccessorElement &&
          element.enclosingElement is ClassElement &&
          (element.isProtected || element.variable.isProtected)) {
        return true;
      }
      if (element is MethodElement &&
          element.enclosingElement is ClassElement &&
          element.isProtected) {
        return true;
      }
      return false;
    }

    bool inCommentReference(SimpleIdentifier identifier) =>
        identifier.getAncestor((AstNode node) => node is CommentReference) !=
        null;

    bool inCurrentLibrary(Element element) =>
        element.library == _currentLibrary;

    Element element = identifier.bestElement;
    if (isProtected(element) &&
        !inCurrentLibrary(element) &&
        !inCommentReference(identifier)) {
      ClassElement definingClass = element.enclosingElement;
      ClassDeclaration accessingClass =
          identifier.getAncestor((AstNode node) => node is ClassDeclaration);
      if (accessingClass == null ||
          !_hasTypeOrSuperType(accessingClass.element, definingClass.type)) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_USE_OF_PROTECTED_MEMBER,
            identifier,
            [identifier.name.toString(), definingClass.name]);
      }
    }
  }

  /**
   * Check that the imported library does not define a loadLibrary function. The import has already
   * been determined to be deferred when this is called.
   *
   * @param node the import directive to evaluate
   * @param importElement the [ImportElement] retrieved from the node
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION].
   */
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

  /**
   * Generate a hint for functions or methods that have a return type, but do not have a return
   * statement on all branches. At the end of blocks with no return, Dart implicitly returns
   * `null`, avoiding these implicit returns is considered a best practice.
   *
   * Note: for async functions/methods, this hint only applies when the
   * function has a return type that Future<Null> is not assignable to.
   *
   * @param node the binary expression to check
   * @param body the function body
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.MISSING_RETURN].
   */
  void _checkForMissingReturn(TypeAnnotation returnType, FunctionBody body) {
    // Check that the method or function has a return type, and a function body
    if (returnType == null || body == null) {
      return;
    }
    // Check that the body is a BlockFunctionBody
    if (body is BlockFunctionBody) {
      // Generators are never required to have a return statement.
      if (body.isGenerator) {
        return;
      }
      // Check that the type is resolvable, and is not "void"
      DartType returnTypeType = returnType.type;
      if (returnTypeType == null || returnTypeType.isVoid) {
        return;
      }
      // For async, give no hint if the return type does not matter, i.e.
      // dynamic, Future<Null> or Future<dynamic>.
      if (body.isAsynchronous) {
        if (returnTypeType.isDynamic) {
          return;
        }
        if (returnTypeType is InterfaceType &&
            returnTypeType.isDartAsyncFuture) {
          DartType futureArgument = returnTypeType.typeArguments[0];
          if (futureArgument.isDynamic ||
              futureArgument.isDartCoreNull ||
              futureArgument.isObject) {
            return;
          }
        }
      }
      // Check the block for a return statement, if not, create the hint
      if (!ExitDetector.exits(body)) {
        _errorReporter.reportErrorForNode(
            HintCode.MISSING_RETURN, returnType, [returnTypeType.displayName]);
      }
    }
  }

  /**
   * Produce a hint if the given [condition] could have a value of `null`.
   */
  void _checkForPossibleNullCondition(Expression condition) {
    condition = condition?.unParenthesized;
    if (condition is BinaryExpression) {
      _checkForPossibleNullConditionInBinaryExpression(condition);
    } else if (condition is PrefixExpression) {
      _checkForPossibleNullConditionInPrefixExpression(condition);
    } else {
      _checkForPossibleNullConditionInSimpleExpression(condition);
    }
  }

  /**
   * Produce a hint if any of the parts of the given binary [condition] could
   * have a value of `null`.
   */
  void _checkForPossibleNullConditionInBinaryExpression(
      BinaryExpression condition) {
    TokenType type = condition.operator?.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      _checkForPossibleNullCondition(condition.leftOperand);
      _checkForPossibleNullCondition(condition.rightOperand);
    }
  }

  /**
   * Produce a hint if the operand of the given prefix [condition] could
   * have a value of `null`.
   */
  void _checkForPossibleNullConditionInPrefixExpression(
      PrefixExpression condition) {
    if (condition.operator?.type == TokenType.BANG) {
      _checkForPossibleNullCondition(condition.operand);
    }
  }

  /**
   * Produce a hint if the given [condition] could have a value of `null`.
   */
  void _checkForPossibleNullConditionInSimpleExpression(Expression condition) {
    if (condition is MethodInvocation) {
      if (condition.operator?.type == TokenType.QUESTION_PERIOD) {
        _errorReporter.reportErrorForNode(
            HintCode.NULL_AWARE_IN_CONDITION, condition);
      }
    } else if (condition is PropertyAccess) {
      if (condition.operator?.type == TokenType.QUESTION_PERIOD) {
        _errorReporter.reportErrorForNode(
            HintCode.NULL_AWARE_IN_CONDITION, condition);
      }
    }
  }

  /**
   * Check for the passed as expression for the [HintCode.UNNECESSARY_CAST] hint code.
   *
   * @param node the as expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.UNNECESSARY_CAST].
   */
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
          !thenType.isMoreSpecificThan(elseType) &&
          !elseType.isMoreSpecificThan(thenType)) {
        return false;
      }
    }
    DartType lhsType = node.expression.staticType;
    DartType rhsType = node.type.type;
    if (lhsType != null &&
        rhsType != null &&
        !lhsType.isDynamic &&
        !rhsType.isDynamic &&
        lhsType.isMoreSpecificThan(rhsType)) {
      _errorReporter.reportErrorForNode(HintCode.UNNECESSARY_CAST, node);
      return true;
    }
    return false;
  }

  /**
   * Generate a hint for `noSuchMethod` methods that do nothing except of
   * calling another `noSuchMethod` that is not defined by `Object`.
   *
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.UNNECESSARY_NO_SUCH_METHOD].
   */
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
              !classElement.type.isObject;
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

  /**
   * Check for situations where the result of a method or function is used, when
   * it returns 'void'.
   *
   * See [HintCode.USE_OF_VOID_RESULT].
   */
  void _checkForUseOfVoidResult(Expression expression) {
    // TODO(jwren) Many other situations of use could be covered. We currently
    // cover the cases var x = m() and x = m(), but we could also cover cases
    // such as m().x, m()[k], a + m(), f(m()), return m().
    if (expression is MethodInvocation) {
      if (identical(expression.staticType, VoidTypeImpl.instance)) {
        SimpleIdentifier methodName = expression.methodName;
        _errorReporter.reportErrorForNode(
            HintCode.USE_OF_VOID_RESULT, methodName, [methodName.name]);
      }
    }
  }

  void _checkRequiredParameter(FormalParameterList node) {
    final requiredParameters =
        node.parameters.where((p) => p.element?.isRequired == true);
    final nonNamedParamsWithRequired =
        requiredParameters.where((p) => p.kind != ParameterKind.NAMED);
    final namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.kind == ParameterKind.NAMED)
        .where((p) => p.element.defaultValueCode != null);
    final paramsToHint = [
      nonNamedParamsWithRequired,
      namedParamsWithRequiredAndDefault
    ].expand((e) => e);
    for (final param in paramsToHint) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_REQUIRED_PARAM, param, [param.identifier.name]);
    }
  }

  /**
   * Check for the passed class declaration for the
   * [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE] hint code.
   *
   * @param node the class declaration to check
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE].
   */
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

  bool _hasTypeOrSuperType(ClassElement element, InterfaceType type) {
    if (element == null) {
      return false;
    }
    ClassElement typeElement = type.element;
    return element == typeElement ||
        element.allSupertypes
            .any((InterfaceType t) => t.element == typeElement);
  }

  /**
   * Given a parenthesized expression, this returns the parent (or recursively grand-parent) of the
   * expression that is a parenthesized expression, but whose parent is not a parenthesized
   * expression.
   *
   * For example given the code `(((e)))`: `(e) -> (((e)))`.
   *
   * @param parenthesizedExpression some expression whose parent is a parenthesized expression
   * @return the first parent or grand-parent that is a parenthesized expression, that does not have
   *         a parenthesized expression parent
   */
  static ParenthesizedExpression _wrapParenthesizedExpression(
      ParenthesizedExpression parenthesizedExpression) {
    AstNode parent = parenthesizedExpression.parent;
    if (parent is ParenthesizedExpression) {
      return _wrapParenthesizedExpression(parent);
    }
    return parenthesizedExpression;
  }
}

/**
 * Utilities for [LibraryElementImpl] building.
 */
class BuildLibraryElementUtils {
  /**
   * Look through all of the compilation units defined for the given [library],
   * looking for getters and setters that are defined in different compilation
   * units but that have the same names. If any are found, make sure that they
   * have the same variable element.
   */
  static void patchTopLevelAccessors(LibraryElementImpl library) {
    // Without parts getters/setters already share the same variable element.
    List<CompilationUnitElement> parts = library.parts;
    if (parts.isEmpty) {
      return;
    }
    // Collect getters and setters.
    HashMap<String, PropertyAccessorElement> getters =
        new HashMap<String, PropertyAccessorElement>();
    List<PropertyAccessorElement> setters = <PropertyAccessorElement>[];
    _collectAccessors(getters, setters, library.definingCompilationUnit);
    int partLength = parts.length;
    for (int i = 0; i < partLength; i++) {
      CompilationUnitElement unit = parts[i];
      _collectAccessors(getters, setters, unit);
    }
    // Move every setter to the corresponding getter's variable (if exists).
    int setterLength = setters.length;
    for (int j = 0; j < setterLength; j++) {
      PropertyAccessorElement setter = setters[j];
      PropertyAccessorElement getter = getters[setter.displayName];
      if (getter != null) {
        TopLevelVariableElementImpl variable = getter.variable;
        TopLevelVariableElementImpl setterVariable = setter.variable;
        CompilationUnitElementImpl setterUnit = setterVariable.enclosingElement;
        setterUnit.replaceTopLevelVariable(setterVariable, variable);
        variable.setter = setter;
        (setter as PropertyAccessorElementImpl).variable = variable;
      }
    }
  }

  /**
   * Add all of the non-synthetic [getters] and [setters] defined in the given
   * [unit] that have no corresponding accessor to one of the given collections.
   */
  static void _collectAccessors(Map<String, PropertyAccessorElement> getters,
      List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    List<PropertyAccessorElement> accessors = unit.accessors;
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter) {
        if (!accessor.isSynthetic && accessor.correspondingSetter == null) {
          getters[accessor.displayName] = accessor;
        }
      } else {
        if (!accessor.isSynthetic && accessor.correspondingGetter == null) {
          setters.add(accessor);
        }
      }
    }
  }
}

/**
 * Instances of the class `ConstantVerifier` traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver. In particular, it looks for errors
 * and warnings related to constant expressions.
 */
class ConstantVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * The type provider used to access the known types.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system in use.
   */
  final TypeSystem _typeSystem;

  /**
   * The set of variables declared using '-D' on the command line.
   */
  final DeclaredVariables declaredVariables;

  /**
   * The type representing the type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing the type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the type 'string'.
   */
  InterfaceType _stringType;

  /**
   * The current library that is being analyzed.
   */
  final LibraryElement _currentLibrary;

  /**
   * Initialize a newly created constant verifier.
   *
   * @param errorReporter the error reporter by which errors will be reported
   */
  ConstantVerifier(this._errorReporter, LibraryElement currentLibrary,
      this._typeProvider, this.declaredVariables)
      : _currentLibrary = currentLibrary,
        _typeSystem = currentLibrary.context.typeSystem {
    this._boolType = _typeProvider.boolType;
    this._intType = _typeProvider.intType;
    this._numType = _typeProvider.numType;
    this._stringType = _typeProvider.stringType;
  }

  @override
  Object visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    Element element = node.element;
    if (element is ConstructorElement) {
      // should be 'const' constructor
      if (!element.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, node);
        return null;
      }
      // should have arguments
      ArgumentList argumentList = node.arguments;
      if (argumentList == null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, node);
        return null;
      }
      // arguments should be constants
      _validateConstantArguments(argumentList);
    }
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.constKeyword != null) {
      _validateConstructorInitializers(node);
      _validateFieldInitializers(node.parent as ClassDeclaration, node);
    }
    _validateDefaultValues(node.parameters);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    _validateDefaultValues(node.parameters);
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      // We need to evaluate the constant to see if any errors occur during its
      // evaluation.
      ConstructorElement constructor = node.staticElement;
      if (constructor != null) {
        ConstantEvaluationEngine evaluationEngine =
            new ConstantEvaluationEngine(_typeProvider, declaredVariables,
                typeSystem: _typeSystem);
        ConstantVisitor constantVisitor =
            new ConstantVisitor(evaluationEngine, _errorReporter);
        evaluationEngine.evaluateConstructorCall(
            node,
            node.argumentList.arguments,
            constructor,
            constantVisitor,
            _errorReporter);
      }
    }
    _validateInstanceCreationArguments(node);
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.constKeyword != null) {
      DartObjectImpl result;
      for (Expression element in node.elements) {
        result =
            _validate(element, CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT);
        if (result != null) {
          _reportErrorIfFromDeferredLibrary(
              element,
              CompileTimeErrorCode
                  .NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY);
        }
      }
    }
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    bool isConst = node.constKeyword != null;
    bool reportEqualKeys = true;
    HashSet<DartObject> keys = new HashSet<DartObject>();
    List<Expression> invalidKeys = new List<Expression>();
    for (MapLiteralEntry entry in node.entries) {
      Expression key = entry.key;
      if (isConst) {
        DartObjectImpl keyResult =
            _validate(key, CompileTimeErrorCode.NON_CONSTANT_MAP_KEY);
        Expression valueExpression = entry.value;
        DartObjectImpl valueResult = _validate(
            valueExpression, CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE);
        if (valueResult != null) {
          _reportErrorIfFromDeferredLibrary(
              valueExpression,
              CompileTimeErrorCode
                  .NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY);
        }
        if (keyResult != null) {
          _reportErrorIfFromDeferredLibrary(key,
              CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY);
          if (keys.contains(keyResult)) {
            invalidKeys.add(key);
          } else {
            keys.add(keyResult);
          }
          DartType type = keyResult.type;
          if (_implementsEqualsWhenNotAllowed(type)) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode
                    .CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
                key,
                [type.displayName]);
          }
        }
      } else {
        // Note: we throw the errors away because this isn't actually a const.
        AnalysisErrorListener errorListener =
            AnalysisErrorListener.NULL_LISTENER;
        ErrorReporter subErrorReporter =
            new ErrorReporter(errorListener, _errorReporter.source);
        DartObjectImpl result = key.accept(new ConstantVisitor(
            new ConstantEvaluationEngine(_typeProvider, declaredVariables,
                typeSystem: _typeSystem),
            subErrorReporter));
        if (result != null) {
          if (keys.contains(result)) {
            invalidKeys.add(key);
          } else {
            keys.add(result);
          }
        } else {
          reportEqualKeys = false;
        }
      }
    }
    if (reportEqualKeys) {
      int length = invalidKeys.length;
      for (int i = 0; i < length; i++) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.EQUAL_KEYS_IN_MAP, invalidKeys[i]);
      }
    }
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    // TODO(paulberry): to minimize error messages, it would be nice to
    // compare all types with the most popular type rather than the first
    // type.
    NodeList<SwitchMember> switchMembers = node.members;
    bool foundError = false;
    DartType firstType = null;
    for (SwitchMember switchMember in switchMembers) {
      if (switchMember is SwitchCase) {
        Expression expression = switchMember.expression;
        DartObjectImpl caseResult = _validate(
            expression, CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION);
        if (caseResult != null) {
          _reportErrorIfFromDeferredLibrary(
              expression,
              CompileTimeErrorCode
                  .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY);
          DartObject value = caseResult;
          if (firstType == null) {
            firstType = value.type;
          } else {
            DartType nType = value.type;
            if (firstType != nType) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
                  expression,
                  [expression.toSource(), firstType.displayName]);
              foundError = true;
            }
          }
        }
      }
    }
    if (!foundError) {
      _checkForCaseExpressionTypeImplementsEquals(node, firstType);
    }
    return super.visitSwitchStatement(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    if (initializer != null && (node.isConst || node.isFinal)) {
      VariableElementImpl element = node.element as VariableElementImpl;
      EvaluationResultImpl result = element.evaluationResult;
      if (result == null) {
        // Variables marked "const" should have had their values computed by
        // ConstantValueComputer.  Other variables will only have had their
        // values computed if the value was needed (e.g. final variables in a
        // class containing const constructors).
        assert(!node.isConst);
        return null;
      }
      _reportErrors(result.errors,
          CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      _reportErrorIfFromDeferredLibrary(
          initializer,
          CompileTimeErrorCode
              .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY);
    }
    return null;
  }

  /**
   * This verifies that the passed switch statement does not have a case expression with the
   * operator '==' overridden.
   *
   * @param node the switch statement to evaluate
   * @param type the common type of all 'case' expressions
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS].
   */
  bool _checkForCaseExpressionTypeImplementsEquals(
      SwitchStatement node, DartType type) {
    if (!_implementsEqualsWhenNotAllowed(type)) {
      return false;
    }
    // report error
    _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
        node.switchKeyword,
        [type.displayName]);
    return true;
  }

  /**
   * @return `true` if given [Type] implements operator <i>==</i>, and it is not
   *         <i>int</i> or <i>String</i>.
   */
  bool _implementsEqualsWhenNotAllowed(DartType type) {
    // ignore int or String
    if (type == null || type == _intType || type == _typeProvider.stringType) {
      return false;
    } else if (type == _typeProvider.doubleType) {
      return true;
    }
    // prepare ClassElement
    Element element = type.element;
    if (element is ClassElement) {
      // lookup for ==
      MethodElement method =
          element.lookUpConcreteMethod("==", _currentLibrary);
      if (method == null || method.enclosingElement.type.isObject) {
        return false;
      }
      // there is == that we don't like
      return true;
    }
    return false;
  }

  /**
   * Given some computed [Expression], this method generates the passed [ErrorCode] on
   * the node if its' value consists of information from a deferred library.
   *
   * @param expression the expression to be tested for a deferred library reference
   * @param errorCode the error code to be used if the expression is or consists of a reference to a
   *          deferred library
   */
  void _reportErrorIfFromDeferredLibrary(
      Expression expression, ErrorCode errorCode) {
    DeferredLibraryReferenceDetector referenceDetector =
        new DeferredLibraryReferenceDetector();
    expression.accept(referenceDetector);
    if (referenceDetector.result) {
      _errorReporter.reportErrorForNode(errorCode, expression);
    }
  }

  /**
   * Report any errors in the given list. Except for special cases, use the given error code rather
   * than the one reported in the error.
   *
   * @param errors the errors that need to be reported
   * @param errorCode the error code to be used
   */
  void _reportErrors(List<AnalysisError> errors, ErrorCode errorCode) {
    int length = errors.length;
    for (int i = 0; i < length; i++) {
      AnalysisError data = errors[i];
      ErrorCode dataErrorCode = data.errorCode;
      if (identical(dataErrorCode,
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) ||
          identical(
              dataErrorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT) ||
          identical(dataErrorCode,
              CheckedModeCompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) ||
          identical(
              dataErrorCode,
              CheckedModeCompileTimeErrorCode
                  .CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH) ||
          identical(
              dataErrorCode,
              CheckedModeCompileTimeErrorCode
                  .CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH) ||
          identical(dataErrorCode,
              CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH)) {
        _errorReporter.reportError(data);
      } else if (errorCode != null) {
        _errorReporter.reportError(new AnalysisError(
            data.source, data.offset, data.length, errorCode));
      }
    }
  }

  /**
   * Validate that the given expression is a compile time constant. Return the value of the compile
   * time constant, or `null` if the expression is not a compile time constant.
   *
   * @param expression the expression to be validated
   * @param errorCode the error code to be used if the expression is not a compile time constant
   * @return the value of the compile time constant
   */
  DartObjectImpl _validate(Expression expression, ErrorCode errorCode) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter subErrorReporter =
        new ErrorReporter(errorListener, _errorReporter.source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(_typeProvider, declaredVariables,
            typeSystem: _typeSystem),
        subErrorReporter));
    _reportErrors(errorListener.errors, errorCode);
    return result;
  }

  /**
   * Validate that if the passed arguments are constant expressions.
   *
   * @param argumentList the argument list to evaluate
   */
  void _validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      Expression realArgument =
          argument is NamedExpression ? argument.expression : argument;
      _validate(
          realArgument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
    }
  }

  /**
   * Validates that the expressions of the initializers of the given constant
   * [constructor] are all compile time constants.
   */
  void _validateConstructorInitializers(ConstructorDeclaration constructor) {
    List<ParameterElement> parameterElements =
        constructor.parameters.parameterElements;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is AssertInitializer) {
        _validateInitializerExpression(
            parameterElements, initializer.condition);
        Expression message = initializer.message;
        if (message != null) {
          _validateInitializerExpression(parameterElements, message);
        }
      } else if (initializer is ConstructorFieldInitializer) {
        _validateInitializerExpression(
            parameterElements, initializer.expression);
      } else if (initializer is RedirectingConstructorInvocation) {
        _validateInitializerInvocationArguments(
            parameterElements, initializer.argumentList);
      } else if (initializer is SuperConstructorInvocation) {
        _validateInitializerInvocationArguments(
            parameterElements, initializer.argumentList);
      }
    }
  }

  /**
   * Validate that the default value associated with each of the parameters in the given list is a
   * compile time constant.
   *
   * @param parameters the list of parameters to be validated
   */
  void _validateDefaultValues(FormalParameterList parameters) {
    if (parameters == null) {
      return;
    }
    for (FormalParameter parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        Expression defaultValue = parameter.defaultValue;
        DartObjectImpl result;
        if (defaultValue == null) {
          result =
              new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
        } else {
          result = _validate(
              defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (result != null) {
            _reportErrorIfFromDeferredLibrary(
                defaultValue,
                CompileTimeErrorCode
                    .NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY);
          }
        }
        VariableElementImpl element = parameter.element as VariableElementImpl;
        element.evaluationResult = new EvaluationResultImpl(result);
      }
    }
  }

  /**
   * Validates that the expressions of any field initializers in the class declaration are all
   * compile time constants. Since this is only required if the class has a constant constructor,
   * the error is reported at the constructor site.
   *
   * @param classDeclaration the class which should be validated
   * @param errorSite the site at which errors should be reported.
   */
  void _validateFieldInitializers(
      ClassDeclaration classDeclaration, ConstructorDeclaration errorSite) {
    NodeList<ClassMember> members = classDeclaration.members;
    for (ClassMember member in members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration variableDeclaration
            in member.fields.variables) {
          Expression initializer = variableDeclaration.initializer;
          if (initializer != null) {
            // Ignore any errors produced during validation--if the constant
            // can't be evaluated we'll just report a single error.
            AnalysisErrorListener errorListener =
                AnalysisErrorListener.NULL_LISTENER;
            ErrorReporter subErrorReporter =
                new ErrorReporter(errorListener, _errorReporter.source);
            DartObjectImpl result = initializer.accept(new ConstantVisitor(
                new ConstantEvaluationEngine(_typeProvider, declaredVariables,
                    typeSystem: _typeSystem),
                subErrorReporter));
            if (result == null) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode
                      .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
                  errorSite,
                  [variableDeclaration.name.name]);
            }
          }
        }
      }
    }
  }

  /**
   * Validates that the given expression is a compile time constant.
   *
   * @param parameterElements the elements of parameters of constant constructor, they are
   *          considered as a valid potentially constant expressions
   * @param expression the expression to validate
   */
  void _validateInitializerExpression(
      List<ParameterElement> parameterElements, Expression expression) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter subErrorReporter =
        new ErrorReporter(errorListener, _errorReporter.source);
    DartObjectImpl result = expression.accept(
        new _ConstantVerifier_validateInitializerExpression(_typeProvider,
            subErrorReporter, this, parameterElements, declaredVariables,
            typeSystem: _typeSystem));
    _reportErrors(errorListener.errors,
        CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER);
    if (result != null) {
      _reportErrorIfFromDeferredLibrary(
          expression,
          CompileTimeErrorCode
              .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY);
    }
  }

  /**
   * Validates that all of the arguments of a constructor initializer are compile time constants.
   *
   * @param parameterElements the elements of parameters of constant constructor, they are
   *          considered as a valid potentially constant expressions
   * @param argumentList the argument list to validate
   */
  void _validateInitializerInvocationArguments(
      List<ParameterElement> parameterElements, ArgumentList argumentList) {
    if (argumentList == null) {
      return;
    }
    for (Expression argument in argumentList.arguments) {
      _validateInitializerExpression(parameterElements, argument);
    }
  }

  /**
   * Validate that if the passed instance creation is 'const' then all its arguments are constant
   * expressions.
   *
   * @param node the instance creation evaluate
   */
  void _validateInstanceCreationArguments(InstanceCreationExpression node) {
    if (!node.isConst) {
      return;
    }
    ArgumentList argumentList = node.argumentList;
    if (argumentList == null) {
      return;
    }
    _validateConstantArguments(argumentList);
  }
}

/**
 * Instances of the class `Dart2JSVerifier` traverse an AST structure looking for hints for
 * code that will be compiled to JS, such as [HintCode.IS_DOUBLE].
 */
class Dart2JSVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The name of the `double` type.
   */
  static String _DOUBLE_TYPE_NAME = "double";

  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * Create a new instance of the [Dart2JSVerifier].
   *
   * @param errorReporter the error reporter
   */
  Dart2JSVerifier(this._errorReporter);

  @override
  Object visitIsExpression(IsExpression node) {
    _checkForIsDoubleHints(node);
    return super.visitIsExpression(node);
  }

  /**
   * Check for instances of `x is double`, `x is int`, `x is! double` and
   * `x is! int`.
   *
   * @param node the is expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.IS_DOUBLE],
   * [HintCode.IS_INT],
   * [HintCode.IS_NOT_DOUBLE], and
   * [HintCode.IS_NOT_INT].
   */
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

/**
 * Instances of the class `DeadCodeVerifier` traverse an AST structure looking for cases of
 * [HintCode.DEAD_CODE].
 */
class DeadCodeVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   *  The type system for this visitor
   */
  final TypeSystem _typeSystem;

  /**
   * Create a new instance of the [DeadCodeVerifier].
   *
   * @param errorReporter the error reporter
   */
  DeadCodeVerifier(this._errorReporter, {TypeSystem typeSystem})
      : this._typeSystem = typeSystem ?? new TypeSystemImpl(null);

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    bool isAmpAmp = operator.type == TokenType.AMPERSAND_AMPERSAND;
    bool isBarBar = operator.type == TokenType.BAR_BAR;
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!_isDebugConstant(lhsCondition)) {
        EvaluationResultImpl lhsResult = _getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          bool value = lhsResult.value.toBoolValue();
          if (value == true && isBarBar) {
            // report error on else block: true || !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // only visit the LHS:
            lhsCondition?.accept(this);
            return null;
          } else if (value == false && isAmpAmp) {
            // report error on if block: false && !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // only visit the LHS:
            lhsCondition?.accept(this);
            return null;
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
    }
    return super.visitBinaryExpression(node);
  }

  /**
   * For each [Block], this method reports and error on all statements between the end of the
   * block and the first return statement (assuming there it is not at the end of the block.)
   *
   * @param node the block to evaluate
   */
  @override
  Object visitBlock(Block node) {
    NodeList<Statement> statements = node.statements;
    _checkForDeadStatementsInNodeList(statements);
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // report error on else block: true ? 1 : !2!
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.elseExpression);
          node.thenExpression?.accept(this);
          return null;
        } else {
          // report error on if block: false ? !1! : 2
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenExpression);
          node.elseExpression?.accept(this);
          return null;
        }
      }
    }
    return super.visitConditionalExpression(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      LibraryElement library = exportElement.exportedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    return super.visitExportDirective(node);
  }

  @override
  Object visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // report error on else block: if(true) {} else {!}
          Statement elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, elseStatement);
            node.thenStatement?.accept(this);
            return null;
          }
        } else {
          // report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenStatement);
          node.elseStatement?.accept(this);
          return null;
        }
      }
    }
    return super.visitIfStatement(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
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
    return super.visitImportDirective(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitTryStatement(TryStatement node) {
    node.body?.accept(this);
    node.finallyBlock?.accept(this);
    NodeList<CatchClause> catchClauses = node.catchClauses;
    int numOfCatchClauses = catchClauses.length;
    List<DartType> visitedTypes = new List<DartType>();
    for (int i = 0; i < numOfCatchClauses; i++) {
      CatchClause catchClause = catchClauses[i];
      if (catchClause.onKeyword != null) {
        // on-catch clause found, verify that the exception type is not a
        // subtype of a previous on-catch exception type
        DartType currentType = catchClause.exceptionType?.type;
        if (currentType != null) {
          if (currentType.isObject) {
            // Found catch clause clause that has Object as an exception type,
            // this is equivalent to having a catch clause that doesn't have an
            // exception type, visit the block, but generate an error on any
            // following catch clauses (and don't visit them).
            catchClause?.accept(this);
            if (i + 1 != numOfCatchClauses) {
              // this catch clause is not the last in the try statement
              CatchClause nextCatchClause = catchClauses[i + 1];
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = nextCatchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportErrorForOffset(
                  HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
              return null;
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
              return null;
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
          // this catch clause is not the last in the try statement
          CatchClause nextCatchClause = catchClauses[i + 1];
          CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
          int offset = nextCatchClause.offset;
          int length = lastCatchClause.end - offset;
          _errorReporter.reportErrorForOffset(
              HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
          return null;
        }
      }
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == false) {
          // report error on if block: while (false) {!}
          _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, node.body);
          return null;
        }
      }
    }
    node.body?.accept(this);
    return null;
  }

  /**
   * Resolve the names in the given [combinator] in the scope of the given
   * [library].
   */
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

  /**
   * Given some [NodeList] of [Statement]s, from either a [Block] or
   * [SwitchMember], this loops through the list searching for dead statements.
   *
   * @param statements some ordered list of statements in a [Block] or [SwitchMember]
   * @param allowMandated allow dead statements mandated by the language spec.
   *            This allows for a final break, continue, return, or throw statement
   *            at the end of a switch case, that are mandated by the language spec.
   */
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

  /**
   * Given some [Expression], this method returns [ValidResult.RESULT_TRUE] if it is
   * `true`, [ValidResult.RESULT_FALSE] if it is `false`, or `null` if the
   * expression is not a constant boolean value.
   *
   * @param expression the expression to evaluate
   * @return [ValidResult.RESULT_TRUE] if it is `true`, [ValidResult.RESULT_FALSE]
   *         if it is `false`, or `null` if the expression is not a constant boolean
   *         value
   */
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

  /**
   * Return `true` if and only if the passed expression is resolved to a constant variable.
   *
   * @param expression some conditional expression
   * @return `true` if and only if the passed expression is resolved to a constant variable
   */
  bool _isDebugConstant(Expression expression) {
    Element element = null;
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
}

/**
 * A visitor that resolves directives in an AST structure to already built
 * elements.
 *
 * The resulting AST must have everything resolved that would have been resolved
 * by a [DirectiveElementBuilder].
 */
class DirectiveResolver extends SimpleAstVisitor {
  final Map<Source, int> sourceModificationTimeMap;
  final Map<Source, SourceKind> importSourceKindMap;
  final Map<Source, SourceKind> exportSourceKindMap;
  final List<AnalysisError> errors = <AnalysisError>[];

  LibraryElement _enclosingLibrary;

  DirectiveResolver(this.sourceModificationTimeMap, this.importSourceKindMap,
      this.exportSourceKindMap);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _enclosingLibrary =
        resolutionMap.elementDeclaredByCompilationUnit(node).library;
    for (Directive directive in node.directives) {
      directive.accept(this);
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    int nodeOffset = node.offset;
    node.element = null;
    for (ExportElement element in _enclosingLibrary.exports) {
      if (element.nameOffset == nodeOffset) {
        node.element = element;
        // Verify the exported source kind.
        Source exportedSource = element.exportedLibrary.source;
        int exportedTime = sourceModificationTimeMap[exportedSource] ?? -1;
        if (exportedTime >= 0 &&
            exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
          StringLiteral uriLiteral = node.uri;
          errors.add(new AnalysisError(
              _enclosingLibrary.source,
              uriLiteral.offset,
              uriLiteral.length,
              CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
              [uriLiteral.toSource()]));
        }
        break;
      }
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    int nodeOffset = node.offset;
    node.element = null;
    for (ImportElement element in _enclosingLibrary.imports) {
      if (element.nameOffset == nodeOffset) {
        node.element = element;
        // Verify the imported source kind.
        Source importedSource = element.importedLibrary.source;
        int importedTime = sourceModificationTimeMap[importedSource] ?? -1;
        if (importedTime >= 0 &&
            importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
          StringLiteral uriLiteral = node.uri;
          ErrorCode errorCode = element.isDeferred
              ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
              : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY;
          errors.add(new AnalysisError(
              _enclosingLibrary.source,
              uriLiteral.offset,
              uriLiteral.length,
              errorCode,
              [uriLiteral.toSource()]));
        }
        break;
      }
    }
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    node.element = _enclosingLibrary;
  }
}

/**
 * Instances of the class `ElementHolder` hold on to elements created while traversing an AST
 * structure so that they can be accessed when creating their enclosing element.
 */
class ElementHolder {
  List<PropertyAccessorElement> _accessors;

  List<ConstructorElement> _constructors;

  List<ClassElement> _enums;

  List<FieldElement> _fields;

  List<FunctionElement> _functions;

  List<LabelElement> _labels;

  List<LocalVariableElement> _localVariables;

  List<MethodElement> _methods;

  List<ParameterElement> _parameters;

  List<TopLevelVariableElement> _topLevelVariables;

  List<ClassElement> _types;

  List<FunctionTypeAliasElement> _typeAliases;

  List<TypeParameterElement> _typeParameters;

  List<PropertyAccessorElement> get accessors {
    if (_accessors == null) {
      return PropertyAccessorElement.EMPTY_LIST;
    }
    List<PropertyAccessorElement> result = _accessors;
    _accessors = null;
    return result;
  }

  List<ConstructorElement> get constructors {
    if (_constructors == null) {
      return ConstructorElement.EMPTY_LIST;
    }
    List<ConstructorElement> result = _constructors;
    _constructors = null;
    return result;
  }

  List<ClassElement> get enums {
    if (_enums == null) {
      return ClassElement.EMPTY_LIST;
    }
    List<ClassElement> result = _enums;
    _enums = null;
    return result;
  }

  List<FieldElement> get fields {
    if (_fields == null) {
      return FieldElement.EMPTY_LIST;
    }
    List<FieldElement> result = _fields;
    _fields = null;
    return result;
  }

  List<FieldElement> get fieldsWithoutFlushing {
    if (_fields == null) {
      return FieldElement.EMPTY_LIST;
    }
    List<FieldElement> result = _fields;
    return result;
  }

  List<FunctionElement> get functions {
    if (_functions == null) {
      return FunctionElement.EMPTY_LIST;
    }
    List<FunctionElement> result = _functions;
    _functions = null;
    return result;
  }

  List<LabelElement> get labels {
    if (_labels == null) {
      return LabelElement.EMPTY_LIST;
    }
    List<LabelElement> result = _labels;
    _labels = null;
    return result;
  }

  List<LocalVariableElement> get localVariables {
    if (_localVariables == null) {
      return LocalVariableElement.EMPTY_LIST;
    }
    List<LocalVariableElement> result = _localVariables;
    _localVariables = null;
    return result;
  }

  List<MethodElement> get methods {
    if (_methods == null) {
      return MethodElement.EMPTY_LIST;
    }
    List<MethodElement> result = _methods;
    _methods = null;
    return result;
  }

  List<ParameterElement> get parameters {
    if (_parameters == null) {
      return ParameterElement.EMPTY_LIST;
    }
    List<ParameterElement> result = _parameters;
    _parameters = null;
    return result;
  }

  List<TopLevelVariableElement> get topLevelVariables {
    if (_topLevelVariables == null) {
      return TopLevelVariableElement.EMPTY_LIST;
    }
    List<TopLevelVariableElement> result = _topLevelVariables;
    _topLevelVariables = null;
    return result;
  }

  List<FunctionTypeAliasElement> get typeAliases {
    if (_typeAliases == null) {
      return FunctionTypeAliasElement.EMPTY_LIST;
    }
    List<FunctionTypeAliasElement> result = _typeAliases;
    _typeAliases = null;
    return result;
  }

  List<TypeParameterElement> get typeParameters {
    if (_typeParameters == null) {
      return TypeParameterElement.EMPTY_LIST;
    }
    List<TypeParameterElement> result = _typeParameters;
    _typeParameters = null;
    return result;
  }

  List<ClassElement> get types {
    if (_types == null) {
      return ClassElement.EMPTY_LIST;
    }
    List<ClassElement> result = _types;
    _types = null;
    return result;
  }

  void addAccessor(PropertyAccessorElement element) {
    if (_accessors == null) {
      _accessors = new List<PropertyAccessorElement>();
    }
    _accessors.add(element);
  }

  void addConstructor(ConstructorElement element) {
    if (_constructors == null) {
      _constructors = new List<ConstructorElement>();
    }
    _constructors.add(element);
  }

  void addEnum(ClassElement element) {
    if (_enums == null) {
      _enums = new List<ClassElement>();
    }
    _enums.add(element);
  }

  void addField(FieldElement element) {
    if (_fields == null) {
      _fields = new List<FieldElement>();
    }
    _fields.add(element);
  }

  void addFunction(FunctionElement element) {
    if (_functions == null) {
      _functions = new List<FunctionElement>();
    }
    _functions.add(element);
  }

  void addLabel(LabelElement element) {
    if (_labels == null) {
      _labels = new List<LabelElement>();
    }
    _labels.add(element);
  }

  void addLocalVariable(LocalVariableElement element) {
    if (_localVariables == null) {
      _localVariables = new List<LocalVariableElement>();
    }
    _localVariables.add(element);
  }

  void addMethod(MethodElement element) {
    if (_methods == null) {
      _methods = new List<MethodElement>();
    }
    _methods.add(element);
  }

  void addParameter(ParameterElement element) {
    if (_parameters == null) {
      _parameters = new List<ParameterElement>();
    }
    _parameters.add(element);
  }

  void addTopLevelVariable(TopLevelVariableElement element) {
    if (_topLevelVariables == null) {
      _topLevelVariables = new List<TopLevelVariableElement>();
    }
    _topLevelVariables.add(element);
  }

  void addType(ClassElement element) {
    if (_types == null) {
      _types = new List<ClassElement>();
    }
    _types.add(element);
  }

  void addTypeAlias(FunctionTypeAliasElement element) {
    if (_typeAliases == null) {
      _typeAliases = new List<FunctionTypeAliasElement>();
    }
    _typeAliases.add(element);
  }

  void addTypeParameter(TypeParameterElement element) {
    if (_typeParameters == null) {
      _typeParameters = new List<TypeParameterElement>();
    }
    _typeParameters.add(element);
  }

  FieldElement getField(String fieldName, {bool synthetic: false}) {
    if (_fields == null) {
      return null;
    }
    int length = _fields.length;
    for (int i = 0; i < length; i++) {
      FieldElement field = _fields[i];
      if (field.name == fieldName && field.isSynthetic == synthetic) {
        return field;
      }
    }
    return null;
  }

  TopLevelVariableElement getTopLevelVariable(String variableName) {
    if (_topLevelVariables == null) {
      return null;
    }
    int length = _topLevelVariables.length;
    for (int i = 0; i < length; i++) {
      TopLevelVariableElement variable = _topLevelVariables[i];
      if (variable.name == variableName) {
        return variable;
      }
    }
    return null;
  }

  void validate() {
    StringBuffer buffer = new StringBuffer();
    if (_accessors != null) {
      buffer.write(_accessors.length);
      buffer.write(" accessors");
    }
    if (_constructors != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_constructors.length);
      buffer.write(" constructors");
    }
    if (_fields != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_fields.length);
      buffer.write(" fields");
    }
    if (_functions != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_functions.length);
      buffer.write(" functions");
    }
    if (_labels != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_labels.length);
      buffer.write(" labels");
    }
    if (_localVariables != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_localVariables.length);
      buffer.write(" local variables");
    }
    if (_methods != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_methods.length);
      buffer.write(" methods");
    }
    if (_parameters != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_parameters.length);
      buffer.write(" parameters");
    }
    if (_topLevelVariables != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_topLevelVariables.length);
      buffer.write(" top-level variables");
    }
    if (_types != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_types.length);
      buffer.write(" types");
    }
    if (_typeAliases != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_typeAliases.length);
      buffer.write(" type aliases");
    }
    if (_typeParameters != null) {
      if (buffer.length > 0) {
        buffer.write("; ");
      }
      buffer.write(_typeParameters.length);
      buffer.write(" type parameters");
    }
    if (buffer.length > 0) {
      AnalysisEngine.instance.logger
          .logError("Failed to capture elements: $buffer");
    }
  }
}

/**
 * Instances of the class `EnumMemberBuilder` build the members in enum declarations.
 */
class EnumMemberBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The type provider used to access the types needed to build an element model for enum
   * declarations.
   */
  final TypeProvider _typeProvider;

  /**
   * Initialize a newly created enum member builder.
   *
   * @param typeProvider the type provider used to access the types needed to build an element model
   *          for enum declarations
   */
  EnumMemberBuilder(this._typeProvider);

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    //
    // Finish building the enum.
    //
    EnumElementImpl enumElement = node.name.staticElement as EnumElementImpl;
    InterfaceType enumType = enumElement.type;
    //
    // Populate the fields.
    //
    List<FieldElement> fields = new List<FieldElement>();
    List<PropertyAccessorElement> getters = new List<PropertyAccessorElement>();
    InterfaceType intType = _typeProvider.intType;
    String indexFieldName = "index";
    FieldElementImpl indexField = new FieldElementImpl(indexFieldName, -1);
    indexField.isFinal = true;
    indexField.isSynthetic = true;
    indexField.type = intType;
    fields.add(indexField);
    getters.add(_createGetter(indexField));
    ConstFieldElementImpl valuesField = new ConstFieldElementImpl("values", -1);
    valuesField.isStatic = true;
    valuesField.isConst = true;
    valuesField.isSynthetic = true;
    valuesField.type = _typeProvider.listType.instantiate(<DartType>[enumType]);
    fields.add(valuesField);
    getters.add(_createGetter(valuesField));
    //
    // Build the enum constants.
    //
    NodeList<EnumConstantDeclaration> constants = node.constants;
    List<DartObjectImpl> constantValues = new List<DartObjectImpl>();
    int constantCount = constants.length;
    for (int i = 0; i < constantCount; i++) {
      EnumConstantDeclaration constant = constants[i];
      FieldElementImpl constantField = constant.name.staticElement;
      //
      // Create a value for the constant.
      //
      HashMap<String, DartObjectImpl> fieldMap =
          new HashMap<String, DartObjectImpl>();
      fieldMap[indexFieldName] = new DartObjectImpl(intType, new IntState(i));
      DartObjectImpl value =
          new DartObjectImpl(enumType, new GenericState(fieldMap));
      constantValues.add(value);
      constantField.evaluationResult = new EvaluationResultImpl(value);
      fields.add(constantField);
      getters.add(constantField.getter);
    }
    //
    // Build the value of the 'values' field.
    //
    valuesField.evaluationResult = new EvaluationResultImpl(
        new DartObjectImpl(valuesField.type, new ListState(constantValues)));
    //
    // Finish building the enum.
    //
    enumElement.fields = fields;
    enumElement.accessors = getters;
    // Client code isn't allowed to invoke the constructor, so we do not model
    // it.
    return super.visitEnumDeclaration(node);
  }

  /**
   * Create a getter that corresponds to the given [field].
   */
  PropertyAccessorElement _createGetter(FieldElementImpl field) {
    return new PropertyAccessorElementImpl_ImplicitGetter(field);
  }
}

/**
 * Instances of the class `ExitDetector` determine whether the visited AST node is guaranteed
 * to terminate by executing a `return` statement, `throw` expression, `rethrow`
 * expression, or simple infinite loop such as `while(true)`.
 */
class ExitDetector extends GeneralizingAstVisitor<bool> {
  /**
   * Set to `true` when a `break` is encountered, and reset to `false` when a
   * `do`, `while`, `for` or `switch` block is entered.
   */
  bool _enclosingBlockContainsBreak = false;

  /**
   * Set to `true` when a `continue` is encountered, and reset to `false` when a
   * `do`, `while`, `for` or `switch` block is entered.
   */
  bool _enclosingBlockContainsContinue = false;

  /**
   * Add node when a labelled `break` is encountered.
   */
  Set<AstNode> _enclosingBlockBreaksLabel = new Set<AstNode>();

  @override
  bool visitArgumentList(ArgumentList node) =>
      _visitExpressions(node.arguments);

  @override
  bool visitAsExpression(AsExpression node) => _nodeExits(node.expression);

  @override
  bool visitAssertInitializer(AssertInitializer node) => false;

  @override
  bool visitAssertStatement(AssertStatement node) => false;

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    Expression leftHandSide = node.leftHandSide;
    if (_nodeExits(leftHandSide)) {
      return true;
    }
    TokenType operatorType = node.operator.type;
    if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      return false;
    }
    if (leftHandSide is PropertyAccess &&
        leftHandSide.operator.type == TokenType.QUESTION_PERIOD) {
      return false;
    }
    return _nodeExits(node.rightHandSide);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) =>
      _nodeExits(node.expression);

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    Expression lhsExpression = node.leftOperand;
    Expression rhsExpression = node.rightOperand;
    TokenType operatorType = node.operator.type;
    // If the operator is ||, then only consider the RHS of the binary
    // expression if the left hand side is the false literal.
    // TODO(jwren) Do we want to take constant expressions into account,
    // evaluate if(false) {} differently than if(<condition>), when <condition>
    // evaluates to a constant false value?
    if (operatorType == TokenType.BAR_BAR) {
      if (lhsExpression is BooleanLiteral) {
        if (!lhsExpression.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is &&, then only consider the RHS of the binary
    // expression if the left hand side is the true literal.
    if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
      if (lhsExpression is BooleanLiteral) {
        if (lhsExpression.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is ??, then don't consider the RHS of the binary
    // expression.
    if (operatorType == TokenType.QUESTION_QUESTION) {
      return _nodeExits(lhsExpression);
    }
    return _nodeExits(lhsExpression) || _nodeExits(rhsExpression);
  }

  @override
  bool visitBlock(Block node) => _visitStatements(node.statements);

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) => _nodeExits(node.block);

  @override
  bool visitBreakStatement(BreakStatement node) {
    _enclosingBlockContainsBreak = true;
    if (node.label != null) {
      _enclosingBlockBreaksLabel.add(node.target);
    }
    return false;
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) =>
      _nodeExits(node.target) || _visitExpressions(node.cascadeSections);

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    Expression thenStatement = node.thenExpression;
    Expression elseStatement = node.elseExpression;
    // TODO(jwren) Do we want to take constant expressions into account,
    // evaluate if(false) {} differently than if(<condition>), when <condition>
    // evaluates to a constant false value?
    if (_nodeExits(conditionExpression)) {
      return true;
    }
    if (thenStatement == null || elseStatement == null) {
      return false;
    }
    return thenStatement.accept(this) && elseStatement.accept(this);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    _enclosingBlockContainsContinue = true;
    return false;
  }

  @override
  bool visitDoStatement(DoStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    bool outerContinueValue = _enclosingBlockContainsContinue;
    _enclosingBlockContainsBreak = false;
    _enclosingBlockContainsContinue = false;
    try {
      bool bodyExits = _nodeExits(node.body);
      bool containsBreakOrContinue =
          _enclosingBlockContainsBreak || _enclosingBlockContainsContinue;
      // Even if we determine that the body "exits", there might be break or
      // continue statements that actually mean it _doesn't_ always exit.
      if (bodyExits && !containsBreakOrContinue) {
        return true;
      }
      Expression conditionExpression = node.condition;
      if (_nodeExits(conditionExpression)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        // If do {} while (true), and the body doesn't break, then return true.
        if (conditionExpression.value && !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
      _enclosingBlockContainsContinue = outerContinueValue;
    }
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) => false;

  @override
  bool visitExpressionStatement(ExpressionStatement node) =>
      _nodeExits(node.expression);

  @override
  bool visitForEachStatement(ForEachStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      return _nodeExits(node.iterable);
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitForStatement(ForStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      if (node.variables != null &&
          _visitVariableDeclarations(node.variables.variables)) {
        return true;
      }
      if (node.initialization != null && _nodeExits(node.initialization)) {
        return true;
      }
      Expression conditionExpression = node.condition;
      if (conditionExpression != null && _nodeExits(conditionExpression)) {
        return true;
      }
      if (_visitExpressions(node.updaters)) {
        return true;
      }
      bool blockReturns = _nodeExits(node.body);
      // TODO(jwren) Do we want to take all constant expressions into account?
      // If for(; true; ) (or for(;;)), and the body doesn't return or the body
      // doesn't have a break, then return true.
      bool implicitOrExplictTrue = conditionExpression == null ||
          (conditionExpression is BooleanLiteral && conditionExpression.value);
      if (implicitOrExplictTrue) {
        if (blockReturns || !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      false;

  @override
  bool visitFunctionExpression(FunctionExpression node) => false;

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_nodeExits(node.function)) {
      return true;
    }
    return node.argumentList.accept(this);
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) => false;

  @override
  bool visitIdentifier(Identifier node) => false;

  @override
  bool visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    Statement thenStatement = node.thenStatement;
    Statement elseStatement = node.elseStatement;
    if (_nodeExits(conditionExpression)) {
      return true;
    }
    // TODO(jwren) Do we want to take all constant expressions into account?
    if (conditionExpression is BooleanLiteral) {
      if (conditionExpression.value) {
        // if (true) ...
        return _nodeExits(thenStatement);
      } else if (elseStatement != null) {
        // if (false) ...
        return _nodeExits(elseStatement);
      }
    }
    bool thenExits = _nodeExits(thenStatement);
    bool elseExits = _nodeExits(elseStatement);
    if (thenStatement == null || elseStatement == null) {
      return false;
    }
    return thenExits && elseExits;
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    if (_nodeExits(target)) {
      return true;
    }
    if (_nodeExits(node.index)) {
      return true;
    }
    return false;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _nodeExits(node.argumentList);

  @override
  bool visitIsExpression(IsExpression node) => node.expression.accept(this);

  @override
  bool visitLabel(Label node) => false;

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    try {
      bool statementExits = _nodeExits(node.statement);
      bool neverBrokeFromLabel =
          !_enclosingBlockBreaksLabel.contains(node.statement);
      return statementExits && neverBrokeFromLabel;
    } finally {
      _enclosingBlockBreaksLabel.remove(node.statement);
    }
  }

  @override
  bool visitLiteral(Literal node) => false;

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    if (target != null) {
      if (target.accept(this)) {
        return true;
      }
      if (node.operator.type == TokenType.QUESTION_PERIOD) {
        return false;
      }
    }
    return _nodeExits(node.argumentList);
  }

  @override
  bool visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this);

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  bool visitPostfixExpression(PostfixExpression node) => false;

  @override
  bool visitPrefixExpression(PrefixExpression node) => false;

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target != null && target.accept(this)) {
      return true;
    }
    return false;
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => true;

  @override
  bool visitReturnStatement(ReturnStatement node) => true;

  @override
  bool visitSuperExpression(SuperExpression node) => false;

  @override
  bool visitSwitchCase(SwitchCase node) => _visitStatements(node.statements);

  @override
  bool visitSwitchDefault(SwitchDefault node) =>
      _visitStatements(node.statements);

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      bool hasDefault = false;
      bool hasNonExitingCase = false;
      List<SwitchMember> members = node.members;
      for (int i = 0; i < members.length; i++) {
        SwitchMember switchMember = members[i];
        if (switchMember is SwitchDefault) {
          hasDefault = true;
          // If this is the last member and there are no statements, then it
          // does not exit.
          if (switchMember.statements.isEmpty && i + 1 == members.length) {
            hasNonExitingCase = true;
            continue;
          }
        }
        // For switch members with no statements, don't visit the children.
        // Otherwise, if there children statements don't exit, mark this as a
        // non-exiting case.
        if (!switchMember.statements.isEmpty && !switchMember.accept(this)) {
          hasNonExitingCase = true;
        }
      }
      if (hasNonExitingCase) {
        return false;
      }
      // As all cases exit, return whether that list includes `default`.
      return hasDefault;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitThisExpression(ThisExpression node) => false;

  @override
  bool visitThrowExpression(ThrowExpression node) => true;

  @override
  bool visitTryStatement(TryStatement node) {
    if (_nodeExits(node.finallyBlock)) {
      return true;
    }
    if (!_nodeExits(node.body)) {
      return false;
    }
    for (CatchClause c in node.catchClauses) {
      if (!_nodeExits(c.body)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitTypeName(TypeName node) => false;

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    Expression initializer = node.initializer;
    if (initializer != null) {
      return initializer.accept(this);
    }
    return false;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) =>
      _visitVariableDeclarations(node.variables);

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    NodeList<VariableDeclaration> variables = node.variables.variables;
    for (int i = 0; i < variables.length; i++) {
      if (variables[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      Expression conditionExpression = node.condition;
      if (conditionExpression.accept(this)) {
        return true;
      }
      node.body.accept(this);
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        // If while(true), and the body doesn't have a break, then return true.
        // The body might be found to exit, but if there are any break
        // statements, then it is a faulty finding. In other words:
        //
        // * If the body exits, and does not contain a break statement, then
        //   it exits.
        // * If the body does not exit, and does not contain a break statement,
        //   then it loops infinitely (also an exit).
        //
        // As both conditions forbid any break statements to be found, the logic
        // just boils down to checking [_enclosingBlockContainsBreak].
        if (conditionExpression.value && !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitYieldStatement(YieldStatement node) => _nodeExits(node.expression);

  /**
   * Return `true` if the given node exits.
   *
   * @param node the node being tested
   * @return `true` if the given node exits
   */
  bool _nodeExits(AstNode node) {
    if (node == null) {
      return false;
    }
    return node.accept(this);
  }

  bool _visitExpressions(NodeList<Expression> expressions) {
    for (int i = expressions.length - 1; i >= 0; i--) {
      if (expressions[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool _visitStatements(NodeList<Statement> statements) {
    for (int i = 0; i < statements.length; i++) {
      if (statements[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool _visitVariableDeclarations(
      NodeList<VariableDeclaration> variableDeclarations) {
    for (int i = variableDeclarations.length - 1; i >= 0; i--) {
      if (variableDeclarations[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [node] exits.
   */
  static bool exits(AstNode node) {
    return new ExitDetector()._nodeExits(node);
  }
}

/**
 * A visitor that visits ASTs and fills [UsedImportedElements].
 */
class GatherUsedImportedElementsVisitor extends RecursiveAstVisitor {
  final LibraryElement library;
  final UsedImportedElements usedElements = new UsedImportedElements();

  GatherUsedImportedElementsVisitor(this.library);

  @override
  void visitExportDirective(ExportDirective node) {
    _visitDirective(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _visitDirective(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _visitDirective(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _visitIdentifier(node, node.staticElement);
  }

  /**
   * If the given [identifier] is prefixed with a [PrefixElement], fill the
   * corresponding `UsedImportedElements.prefixMap` entry and return `true`.
   */
  bool _recordPrefixMap(SimpleIdentifier identifier, Element element) {
    bool recordIfTargetIsPrefixElement(Expression target) {
      if (target is SimpleIdentifier && target.staticElement is PrefixElement) {
        List<Element> prefixedElements = usedElements.prefixMap
            .putIfAbsent(target.staticElement, () => <Element>[]);
        prefixedElements.add(element);
        return true;
      }
      return false;
    }

    AstNode parent = identifier.parent;
    if (parent is MethodInvocation && parent.methodName == identifier) {
      return recordIfTargetIsPrefixElement(parent.target);
    }
    if (parent is PrefixedIdentifier && parent.identifier == identifier) {
      return recordIfTargetIsPrefixElement(parent.prefix);
    }
    return false;
  }

  /**
   * Visit identifiers used by the given [directive].
   */
  void _visitDirective(Directive directive) {
    directive.documentationComment?.accept(this);
    directive.metadata.accept(this);
  }

  void _visitIdentifier(SimpleIdentifier identifier, Element element) {
    if (element == null) {
      return;
    }
    // If the element is multiply defined then call this method recursively for
    // each of the conflicting elements.
    if (element is MultiplyDefinedElement) {
      List<Element> conflictingElements = element.conflictingElements;
      int length = conflictingElements.length;
      for (int i = 0; i < length; i++) {
        Element elt = conflictingElements[i];
        _visitIdentifier(identifier, elt);
      }
      return;
    }

    // Record `importPrefix.identifier` into 'prefixMap'.
    if (_recordPrefixMap(identifier, element)) {
      return;
    }

    if (element is PrefixElement) {
      usedElements.prefixMap.putIfAbsent(element, () => <Element>[]);
      return;
    } else if (element.enclosingElement is! CompilationUnitElement) {
      // Identifiers that aren't a prefix element and whose enclosing element
      // isn't a CompilationUnit are ignored- this covers the case the
      // identifier is a relative-reference, a reference to an identifier not
      // imported by this library.
      return;
    }
    // Ignore if an unknown library.
    LibraryElement containingLibrary = element.library;
    if (containingLibrary == null) {
      return;
    }
    // Ignore if a local element.
    if (library == containingLibrary) {
      return;
    }
    // Remember the element.
    usedElements.elements.add(element);
  }
}

/**
 * An [AstVisitor] that fills [UsedLocalElements].
 */
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
      _enclosingClass = node.element;
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = enclosingClassOld;
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.element;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      usedElements.addElement(node.element);
    }
    super.visitFunctionExpression(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.element;
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
    if (element is LocalVariableElement) {
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

  /**
   * Marks an [Element] of [node] as used in the library.
   */
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

/**
 * Instances of the class `ImportsVerifier` visit all of the referenced libraries in the source code
 * verifying that all of the imports are used, otherwise a [HintCode.UNUSED_IMPORT] hint is
 * generated with [generateUnusedImportHints].
 *
 * Additionally, [generateDuplicateImportHints] generates [HintCode.DUPLICATE_IMPORT] hints and
 * [HintCode.UNUSED_SHOWN_NAME] hints.
 *
 * While this class does not yet have support for an "Organize Imports" action, this logic built up
 * in this class could be used for such an action in the future.
 */
class ImportsVerifier {
  /**
   * A list of [ImportDirective]s that the current library imports, but does not use.
   *
   * As identifiers are visited by this visitor and an import has been identified as being used
   * by the library, the [ImportDirective] is removed from this list. After all the sources in the
   * library have been evaluated, this list represents the set of unused imports.
   *
   * See [ImportsVerifier.generateUnusedImportErrors].
   */
  final List<ImportDirective> _unusedImports = <ImportDirective>[];

  /**
   * After the list of [unusedImports] has been computed, this list is a proper subset of the
   * unused imports that are listed more than once.
   */
  final List<ImportDirective> _duplicateImports = <ImportDirective>[];

  /**
   * This is a map between the set of [LibraryElement]s that the current library imports, and the
   * list of [ImportDirective]s that import each [LibraryElement]. In cases where the current
   * library imports a library with a single directive (such as `import lib1.dart;`), the library
   * element will map to a list of one [ImportDirective], which will then be removed from the
   * [unusedImports] list. In cases where the current library imports a library with multiple
   * directives (such as `import lib1.dart; import lib1.dart show C;`), the [LibraryElement] will
   * be mapped to a list of the import directives, and the namespace will need to be used to
   * compute the correct [ImportDirective] being used; see [_namespaceMap].
   */
  final HashMap<LibraryElement, List<ImportDirective>> _libraryMap =
      new HashMap<LibraryElement, List<ImportDirective>>();

  /**
   * In cases where there is more than one import directive per library element, this mapping is
   * used to determine which of the multiple import directives are used by generating a
   * [Namespace] for each of the imports to do lookups in the same way that they are done from
   * the [ElementResolver].
   */
  final HashMap<ImportDirective, Namespace> _namespaceMap =
      new HashMap<ImportDirective, Namespace>();

  /**
   * This is a map between prefix elements and the import directives from which they are derived. In
   * cases where a type is referenced via a prefix element, the import directive can be marked as
   * used (removed from the unusedImports) by looking at the resolved `lib` in `lib.X`,
   * instead of looking at which library the `lib.X` resolves.
   *
   * TODO (jwren) Since multiple [ImportDirective]s can share the same [PrefixElement],
   * it is possible to have an unreported unused import in situations where two imports use the same
   * prefix and at least one import directive is used.
   */
  final HashMap<PrefixElement, List<ImportDirective>> _prefixElementMap =
      new HashMap<PrefixElement, List<ImportDirective>>();

  /**
   * A map of identifiers that the current library's imports show, but that the library does not
   * use.
   *
   * Each import directive maps to a list of the identifiers that are imported via the "show"
   * keyword.
   *
   * As each identifier is visited by this visitor, it is identified as being used by the library,
   * and the identifier is removed from this map (under the import that imported it). After all the
   * sources in the library have been evaluated, each list in this map's values present the set of
   * unused shown elements.
   *
   * See [ImportsVerifier.generateUnusedShownNameHints].
   */
  final HashMap<ImportDirective, List<SimpleIdentifier>> _unusedShownNamesMap =
      new HashMap<ImportDirective, List<SimpleIdentifier>>();

  void addImports(CompilationUnit node) {
    for (Directive directive in node.directives) {
      if (directive is ImportDirective) {
        LibraryElement libraryElement = directive.uriElement;
        if (libraryElement == null) {
          continue;
        }
        _unusedImports.add(directive);
        //
        // Initialize prefixElementMap
        //
        if (directive.asKeyword != null) {
          SimpleIdentifier prefixIdentifier = directive.prefix;
          if (prefixIdentifier != null) {
            Element element = prefixIdentifier.staticElement;
            if (element is PrefixElement) {
              List<ImportDirective> list = _prefixElementMap[element];
              if (list == null) {
                list = new List<ImportDirective>();
                _prefixElementMap[element] = list;
              }
              list.add(directive);
            }
            // TODO (jwren) Can the element ever not be a PrefixElement?
          }
        }
        //
        // Initialize libraryMap: libraryElement -> importDirective
        //
        _putIntoLibraryMap(libraryElement, directive);
        //
        // For this new addition to the libraryMap, also recursively add any
        // exports from the libraryElement.
        //
        _addAdditionalLibrariesForExports(
            libraryElement, directive, new HashSet<LibraryElement>());
        _addShownNames(directive);
      }
    }
    if (_unusedImports.length > 1) {
      // order the list of unusedImports to find duplicates in faster than
      // O(n^2) time
      List<ImportDirective> importDirectiveArray =
          new List<ImportDirective>.from(_unusedImports);
      importDirectiveArray.sort(ImportDirective.COMPARATOR);
      ImportDirective currentDirective = importDirectiveArray[0];
      for (int i = 1; i < importDirectiveArray.length; i++) {
        ImportDirective nextDirective = importDirectiveArray[i];
        if (ImportDirective.COMPARATOR(currentDirective, nextDirective) == 0) {
          // Add either the currentDirective or nextDirective depending on which
          // comes second, this guarantees that the first of the duplicates
          // won't be highlighted.
          if (currentDirective.offset < nextDirective.offset) {
            _duplicateImports.add(nextDirective);
          } else {
            _duplicateImports.add(currentDirective);
          }
        }
        currentDirective = nextDirective;
      }
    }
  }

  /**
   * Any time after the defining compilation unit has been visited by this visitor, this method can
   * be called to report an [HintCode.DUPLICATE_IMPORT] hint for each of the import directives
   * in the [duplicateImports] list.
   *
   * @param errorReporter the error reporter to report the set of [HintCode.DUPLICATE_IMPORT]
   *          hints to
   */
  void generateDuplicateImportHints(ErrorReporter errorReporter) {
    int length = _duplicateImports.length;
    for (int i = 0; i < length; i++) {
      errorReporter.reportErrorForNode(
          HintCode.DUPLICATE_IMPORT, _duplicateImports[i].uri);
    }
  }

  /**
   * Report an [HintCode.UNUSED_IMPORT] hint for each unused import.
   *
   * Only call this method after all of the compilation units have been visited by this visitor.
   *
   * @param errorReporter the error reporter used to report the set of [HintCode.UNUSED_IMPORT]
   *          hints
   */
  void generateUnusedImportHints(ErrorReporter errorReporter) {
    int length = _unusedImports.length;
    for (int i = 0; i < length; i++) {
      ImportDirective unusedImport = _unusedImports[i];
      // Check that the imported URI exists and isn't dart:core
      ImportElement importElement = unusedImport.element;
      if (importElement != null) {
        LibraryElement libraryElement = importElement.importedLibrary;
        if (libraryElement == null ||
            libraryElement.isDartCore ||
            libraryElement.isSynthetic) {
          continue;
        }
      }
      errorReporter.reportErrorForNode(
          HintCode.UNUSED_IMPORT, unusedImport.uri);
    }
  }

  /**
   * Report an [HintCode.UNUSED_SHOWN_NAME] hint for each unused shown name.
   *
   * Only call this method after all of the compilation units have been visited by this visitor.
   *
   * @param errorReporter the error reporter used to report the set of [HintCode.UNUSED_SHOWN_NAME]
   *          hints
   */
  void generateUnusedShownNameHints(ErrorReporter reporter) {
    _unusedShownNamesMap.forEach(
        (ImportDirective importDirective, List<SimpleIdentifier> identifiers) {
      if (_unusedImports.contains(importDirective)) {
        // This import is actually wholly unused, not just one or more shown names from it.
        // This is then an "unused import", rather than unused shown names.
        return;
      }
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        reporter.reportErrorForNode(
            HintCode.UNUSED_SHOWN_NAME, identifier, [identifier.name]);
      }
    });
  }

  /**
   * Remove elements from [_unusedImports] using the given [usedElements].
   */
  void removeUsedElements(UsedImportedElements usedElements) {
    // Stop if all the imports and shown names are known to be used.
    if (_unusedImports.isEmpty && _unusedShownNamesMap.isEmpty) {
      return;
    }
    // Process import prefixes.
    usedElements.prefixMap
        .forEach((PrefixElement prefix, List<Element> elements) {
      List<ImportDirective> importDirectives = _prefixElementMap[prefix];
      if (importDirectives != null) {
        int importLength = importDirectives.length;
        for (int i = 0; i < importLength; i++) {
          ImportDirective importDirective = importDirectives[i];
          _unusedImports.remove(importDirective);
          int elementLength = elements.length;
          for (int j = 0; j < elementLength; j++) {
            Element element = elements[j];
            _removeFromUnusedShownNamesMap(element, importDirective);
          }
        }
      }
    });
    // Process top-level elements.
    for (Element element in usedElements.elements) {
      // Stop if all the imports and shown names are known to be used.
      if (_unusedImports.isEmpty && _unusedShownNamesMap.isEmpty) {
        return;
      }
      // Prepare import directives for this element's library.
      LibraryElement library = element.library;
      List<ImportDirective> importsLibrary = _libraryMap[library];
      if (importsLibrary == null) {
        // element's library is not imported. Must be the current library.
        continue;
      }
      // If there is only one import directive for this library, then it must be
      // the directive that this element is imported with, remove it from the
      // unusedImports list.
      if (importsLibrary.length == 1) {
        ImportDirective usedImportDirective = importsLibrary[0];
        _unusedImports.remove(usedImportDirective);
        _removeFromUnusedShownNamesMap(element, usedImportDirective);
        continue;
      }
      // Otherwise, find import directives using namespaces.
      String name = element.displayName;
      for (ImportDirective importDirective in importsLibrary) {
        Namespace namespace = _computeNamespace(importDirective);
        if (namespace?.get(name) != null) {
          _unusedImports.remove(importDirective);
          _removeFromUnusedShownNamesMap(element, importDirective);
        }
      }
    }
  }

  /**
   * Recursively add any exported library elements into the [libraryMap].
   */
  void _addAdditionalLibrariesForExports(LibraryElement library,
      ImportDirective importDirective, Set<LibraryElement> visitedLibraries) {
    if (library == null || !visitedLibraries.add(library)) {
      return;
    }
    List<ExportElement> exports = library.exports;
    int length = exports.length;
    for (int i = 0; i < length; i++) {
      ExportElement exportElt = exports[i];
      LibraryElement exportedLibrary = exportElt.exportedLibrary;
      _putIntoLibraryMap(exportedLibrary, importDirective);
      _addAdditionalLibrariesForExports(
          exportedLibrary, importDirective, visitedLibraries);
    }
  }

  /**
   * Add every shown name from [importDirective] into [_unusedShownNamesMap].
   */
  void _addShownNames(ImportDirective importDirective) {
    if (importDirective.combinators == null) {
      return;
    }
    List<SimpleIdentifier> identifiers = new List<SimpleIdentifier>();
    _unusedShownNamesMap[importDirective] = identifiers;
    for (Combinator combinator in importDirective.combinators) {
      if (combinator is ShowCombinator) {
        for (SimpleIdentifier name in combinator.shownNames) {
          if (name.staticElement != null) {
            identifiers.add(name);
          }
        }
      }
    }
  }

  /**
   * Lookup and return the [Namespace] from the [_namespaceMap].
   *
   * If the map does not have the computed namespace, compute it and cache it in the map. If
   * [importDirective] is not resolved or is not resolvable, `null` is returned.
   *
   * @param importDirective the import directive used to compute the returned namespace
   * @return the computed or looked up [Namespace]
   */
  Namespace _computeNamespace(ImportDirective importDirective) {
    Namespace namespace = _namespaceMap[importDirective];
    if (namespace == null) {
      // If the namespace isn't in the namespaceMap, then compute and put it in
      // the map.
      ImportElement importElement = importDirective.element;
      if (importElement != null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createImportNamespaceForDirective(importElement);
        _namespaceMap[importDirective] = namespace;
      }
    }
    return namespace;
  }

  /**
   * The [libraryMap] is a mapping between a library elements and a list of import
   * directives, but when adding these mappings into the [libraryMap], this method can be
   * used to simply add the mapping between the library element an an import directive without
   * needing to check to see if a list needs to be created.
   */
  void _putIntoLibraryMap(
      LibraryElement libraryElement, ImportDirective importDirective) {
    List<ImportDirective> importList = _libraryMap[libraryElement];
    if (importList == null) {
      importList = new List<ImportDirective>();
      _libraryMap[libraryElement] = importList;
    }
    importList.add(importDirective);
  }

  /**
   * Remove [element] from the list of names shown by [importDirective].
   */
  void _removeFromUnusedShownNamesMap(
      Element element, ImportDirective importDirective) {
    List<SimpleIdentifier> identifiers = _unusedShownNamesMap[importDirective];
    if (identifiers == null) {
      return;
    }
    int length = identifiers.length;
    for (int i = 0; i < length; i++) {
      Identifier identifier = identifiers[i];
      if (element is PropertyAccessorElement) {
        // If the getter or setter of a variable is used, then the variable (the
        // shown name) is used.
        if (identifier.staticElement == element.variable) {
          identifiers.remove(identifier);
          break;
        }
      } else {
        if (identifier.staticElement == element) {
          identifiers.remove(identifier);
          break;
        }
      }
    }
    if (identifiers.isEmpty) {
      _unusedShownNamesMap.remove(importDirective);
    }
  }
}

/**
 * Maintains and manages contextual type information used for
 * inferring types.
 */
class InferenceContext {
  // TODO(leafp): Consider replacing these node properties with a
  // hash table help in an instance of this class.
  static const String _typeProperty =
      'analyzer.src.generated.InferenceContext.contextType';

  /**
   * The error listener on which to record inference information.
   */
  final ErrorReporter _errorReporter;

  /**
   * If true, emit hints when types are inferred
   */
  final bool _inferenceHints;

  /**
   * Type provider, needed for type matching.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system in use.
   */
  final TypeSystem _typeSystem;

  /**
   * When no context type is available, this will track the least upper bound
   * of all return statements in a lambda.
   *
   * This will always be kept in sync with [_returnStack].
   */
  final List<DartType> _inferredReturn = <DartType>[];

  /**
   * A stack of return types for all of the enclosing
   * functions and methods.
   */
  final List<DartType> _returnStack = <DartType>[];

  InferenceContext._(TypeProvider typeProvider, this._typeSystem,
      this._inferenceHints, this._errorReporter)
      : _typeProvider = typeProvider;

  /**
   * Get the return type of the current enclosing function, if any.
   *
   * The type returned for a function is the type that is expected
   * to be used in a return or yield context.  For ordinary functions
   * this is the same as the return type of the function.  For async
   * functions returning Future<T> and for generator functions
   * returning Stream<T> or Iterable<T>, this is T.
   */
  DartType get returnContext =>
      _returnStack.isNotEmpty ? _returnStack.last : null;

  /**
   * Records the type of the expression of a return statement.
   *
   * This will be used for inferring a block bodied lambda, if no context
   * type was available.
   */
  void addReturnOrYieldType(DartType type) {
    if (_returnStack.isEmpty) {
      return;
    }

    DartType inferred = _inferredReturn.last;
    inferred = _typeSystem.getLeastUpperBound(type, inferred);
    _inferredReturn[_inferredReturn.length - 1] = inferred;
  }

  /**
   * Pop a return type off of the return stack.
   *
   * Also record any inferred return type using [setType], unless this node
   * already has a context type. This recorded type will be the least upper
   * bound of all types added with [addReturnOrYieldType].
   */
  void popReturnContext(BlockFunctionBody node) {
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

  /**
   * Push a block function body's return type onto the return stack.
   */
  void pushReturnContext(BlockFunctionBody node) {
    _returnStack.add(getContext(node));
    _inferredReturn.add(_typeProvider.nullType);
  }

  /**
   * Place an info node into the error stream indicating that a
   * [type] has been inferred as the type of [node].
   */
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

  /**
   * Clear the type information associated with [node].
   */
  static void clearType(AstNode node) {
    node?.setProperty(_typeProperty, null);
  }

  /**
   * Look for contextual type information attached to [node], and returns
   * the type if found.
   *
   * The returned type may be partially or completely unknown, denoted with an
   * unknown type `?`, for example `List<?>` or `(?, int) -> void`.
   * You can use [StrongTypeSystemImpl.upperBoundForType] or
   * [StrongTypeSystemImpl.lowerBoundForType] if you would prefer a known type
   * that represents the bound of the context type.
   */
  static DartType getContext(AstNode node) => node?.getProperty(_typeProperty);

  /**
   * Attach contextual type information [type] to [node] for use during
   * inference.
   */
  static void setType(AstNode node, DartType type) {
    if (type == null || type.isDynamic) {
      clearType(node);
    } else {
      node?.setProperty(_typeProperty, type);
    }
  }

  /**
   * Attach contextual type information [type] to [node] for use during
   * inference.
   */
  static void setTypeFromNode(AstNode innerNode, AstNode outerNode) {
    setType(innerNode, getContext(outerNode));
  }
}

/**
 * The four states of a field initialization state through a constructor
 * signature, not initialized, initialized in the field declaration, initialized
 * in the field formal, and finally, initialized in the initializers list.
 */
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

  /**
   * The name of this init state.
   */
  final String name;

  /**
   * The ordinal value of the init state.
   */
  final int ordinal;

  const INIT_STATE(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(INIT_STATE other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/**
 * An AST visitor that is used to re-resolve the initializers of instance
 * fields. Although this class is an AST visitor, clients are expected to use
 * the method [resolveCompilationUnit] to run it over a compilation unit.
 */
class InstanceFieldResolverVisitor extends ResolverVisitor {
  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * The [definingLibrary] is the element for the library containing the node
   * being visited. The [source] is the source representing the compilation unit
   * containing the node being visited. The [typeProvider] is the object used to
   * access the types from the core library. The [errorListener] is the error
   * listener that will be informed of any errors that are found during
   * resolution. The [nameScope] is the scope used to resolve identifiers in the
   * node that will first be visited.  If `null` or unspecified, a new
   * [LibraryScope] will be created based on the [definingLibrary].
   */
  InstanceFieldResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope);

  /**
   * Resolve the instance fields in the given compilation unit [node].
   */
  void resolveCompilationUnit(CompilationUnit node) {
    _overrideManager.enterScope();
    try {
      NodeList<CompilationUnitMember> declarations = node.declarations;
      int declarationCount = declarations.length;
      for (int i = 0; i < declarationCount; i++) {
        CompilationUnitMember declaration = declarations[i];
        if (declaration is ClassDeclaration) {
          _resolveClassDeclaration(declaration);
        }
      }
    } finally {
      _overrideManager.exitScope();
    }
  }

  /**
   * Resolve the instance fields in the given class declaration [node].
   */
  void _resolveClassDeclaration(ClassDeclaration node) {
    _enclosingClassDeclaration = node;
    ClassElement outerType = enclosingClass;
    Scope outerScope = nameScope;
    try {
      enclosingClass = node.element;
      typeAnalyzer.thisType = enclosingClass?.type;
      if (enclosingClass == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for class declaration ${node.name
                .name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
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
      typeAnalyzer.thisType = outerType?.type;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  /**
   * Resolve the instance fields in the given field declaration [node].
   */
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

/**
 * Instances of the class `OverrideVerifier` visit all of the declarations in a compilation
 * unit to verify that if they have an override annotation it is being used correctly.
 */
class OverrideVerifier extends RecursiveAstVisitor {
  /**
   * The error reporter used to report errors.
   */
  final ErrorReporter _errorReporter;

  /**
   * The inheritance manager used to find overridden methods.
   */
  final InheritanceManager _manager;

  /**
   * Initialize a newly created verifier to look for inappropriate uses of the override annotation.
   *
   * @param errorReporter the error reporter used to report errors
   * @param manager the inheritance manager used to find overridden methods
   */
  OverrideVerifier(this._errorReporter, this._manager);

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    for (VariableDeclaration field in node.fields.variables) {
      VariableElement fieldElement = field.element;
      if (fieldElement is FieldElement && _isOverride(fieldElement)) {
        PropertyAccessorElement getter = fieldElement.getter;
        PropertyAccessorElement setter = fieldElement.setter;
        if (!(getter != null && _getOverriddenMember(getter) != null ||
            setter != null && _getOverriddenMember(setter) != null)) {
          _errorReporter.reportErrorForNode(
              HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD, field.name);
        }
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.element;
    if (_isOverride(element)) {
      if (_getOverriddenMember(element) == null) {
        if (element is MethodElement) {
          _errorReporter.reportErrorForNode(
              HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, node.name);
        } else if (element is PropertyAccessorElement) {
          if (element.isGetter) {
            _errorReporter.reportErrorForNode(
                HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, node.name);
          } else {
            _errorReporter.reportErrorForNode(
                HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER, node.name);
          }
        }
      }
    }
  }

  /**
   * Return the member that overrides the given member.
   *
   * @param member the member that overrides the returned member
   * @return the member that overrides the given member
   */
  ExecutableElement _getOverriddenMember(ExecutableElement member) {
    LibraryElement library = member.library;
    if (library == null) {
      return null;
    }
    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return null;
    }
    return _manager.lookupInheritance(classElement, member.name);
  }

  /**
   * Return `true` if the given element has an override annotation associated with it.
   *
   * @param element the element being tested
   * @return `true` if the element has an override annotation associated with it
   */
  bool _isOverride(Element element) => element != null && element.isOverride;
}

/**
 * An AST visitor that is used to resolve the some of the nodes within a single
 * compilation unit. The nodes that are skipped are those that are within
 * function bodies.
 */
class PartialResolverVisitor extends ResolverVisitor {
  /**
   * The static variables and fields that have an initializer. These are the
   * variables that need to be re-resolved after static variables have their
   * types inferred. A subset of these variables are those whose types should
   * be inferred.
   */
  final List<VariableElement> staticVariables = <VariableElement>[];

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * The [definingLibrary] is the element for the library containing the node
   * being visited. The [source] is the source representing the compilation unit
   * containing the node being visited. The [typeProvider] is the object used to
   * access the types from the core library. The [errorListener] is the error
   * listener that will be informed of any errors that are found during
   * resolution. The [nameScope] is the scope used to resolve identifiers in the
   * node that will first be visited.  If `null` or unspecified, a new
   * [LibraryScope] will be created based on [definingLibrary] and
   * [typeProvider]. The [inheritanceManager] is used to perform inheritance
   * lookups.  If `null` or unspecified, a new [InheritanceManager] will be
   * created based on [definingLibrary]. The [typeAnalyzerFactory] is used to
   * create the type analyzer.  If `null` or unspecified, a type analyzer of
   * type [StaticTypeAnalyzer] will be created.
   */
  PartialResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope);

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    if (_shouldBeSkipped(node)) {
      return null;
    }
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_shouldBeSkipped(node)) {
      return null;
    }
    return super.visitExpressionFunctionBody(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) {
      _addStaticVariables(node.fields.variables);
    }
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitNode(AstNode node) {
    return super.visitNode(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _addStaticVariables(node.variables.variables);
    return super.visitTopLevelVariableDeclaration(node);
  }

  /**
   * Add all of the [variables] with initializers to the list of variables whose
   * type can be inferred. Technically, we only infer the types of variables
   * that do not have a static type, but all variables with initializers
   * potentially need to be re-resolved after inference because they might
   * refer to a field whose type was inferred.
   */
  void _addStaticVariables(List<VariableDeclaration> variables) {
    int length = variables.length;
    for (int i = 0; i < length; i++) {
      VariableDeclaration variable = variables[i];
      if (variable.name.name.isNotEmpty && variable.initializer != null) {
        staticVariables.add(variable.element);
      }
    }
  }

  /**
   * Return `true` if the given function body should be skipped because it is
   * the body of a top-level function, method or constructor.
   */
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

/**
 * Kind of the redirecting constructor.
 */
class RedirectingConstructorKind
    implements Comparable<RedirectingConstructorKind> {
  static const RedirectingConstructorKind CONST =
      const RedirectingConstructorKind('CONST', 0);

  static const RedirectingConstructorKind NORMAL =
      const RedirectingConstructorKind('NORMAL', 1);

  static const List<RedirectingConstructorKind> values = const [CONST, NORMAL];

  /**
   * The name of this redirecting constructor kind.
   */
  final String name;

  /**
   * The ordinal value of the redirecting constructor kind.
   */
  final int ordinal;

  const RedirectingConstructorKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(RedirectingConstructorKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/**
 * The enumeration `ResolverErrorCode` defines the error codes used for errors
 * detected by the resolver. The convention for this class is for the name of
 * the error code to indicate the problem that caused the error to be generated
 * and for the error message to explain what is wrong and, when appropriate, how
 * the problem can be corrected.
 */
class ResolverErrorCode extends ErrorCode {
  static const ResolverErrorCode BREAK_LABEL_ON_SWITCH_MEMBER =
      const ResolverErrorCode('BREAK_LABEL_ON_SWITCH_MEMBER',
          "Break label resolves to case or default statement");

  static const ResolverErrorCode CONTINUE_LABEL_ON_SWITCH =
      const ResolverErrorCode('CONTINUE_LABEL_ON_SWITCH',
          "A continue label resolves to switch, must be loop or switch member");

  static const ResolverErrorCode MISSING_LIBRARY_DIRECTIVE_WITH_PART =
      const ResolverErrorCode('MISSING_LIBRARY_DIRECTIVE_WITH_PART',
          "Libraries that have parts must have a library directive");

  /**
   * Parts: It is a static warning if the referenced part declaration
   * <i>p</i> names a library that does not have a library tag.
   *
   * Parameters:
   * 0: the URI of the expected library
   * 1: the non-matching actual library name from the "part of" declaration
   */
  static const ResolverErrorCode PART_OF_UNNAMED_LIBRARY =
      const ResolverErrorCode(
          'PART_OF_UNNAMED_LIBRARY',
          "Library is unnamed. Expected a URI not a library name '{0}' in the "
          "part-of directive.",
          "Try changing the part-of directive to a URI, or try including a"
          " different part.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ResolverErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => type.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * Instances of the class `ResolverVisitor` are used to resolve the nodes within a single
 * compilation unit.
 */
class ResolverVisitor extends ScopedVisitor {
  /**
   * The object used to resolve the element associated with the current node.
   */
  ElementResolver elementResolver;

  /**
   * The object used to compute the type associated with the current node.
   */
  StaticTypeAnalyzer typeAnalyzer;

  /**
   * The type system in use during resolution.
   */
  TypeSystem typeSystem;

  /**
   * The class declaration representing the class containing the current node, or `null` if
   * the current node is not contained in a class.
   */
  ClassDeclaration _enclosingClassDeclaration = null;

  /**
   * The function type alias representing the function type containing the current node, or
   * `null` if the current node is not contained in a function type alias.
   */
  FunctionTypeAlias _enclosingFunctionTypeAlias = null;

  /**
   * The element representing the function containing the current node, or `null` if the
   * current node is not contained in a function.
   */
  ExecutableElement _enclosingFunction = null;

  InferenceContext inferenceContext = null;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager = new TypeOverrideManager();

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager = new TypePromotionManager();

  /**
   * A comment before a function should be resolved in the context of the
   * function. But when we incrementally resolve a comment, we don't want to
   * resolve the whole function.
   *
   * So, this flag is set to `true`, when just context of the function should
   * be built and the comment resolved.
   */
  bool resolveOnlyCommentInFunctionBody = false;

  /**
   * Body of the function currently being analyzed, if any.
   */
  FunctionBody _currentFunctionBody;

  /**
   * Are we running in strong mode or not.
   */
  bool strongMode;

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * The [definingLibrary] is the element for the library containing the node
   * being visited. The [source] is the source representing the compilation unit
   * containing the node being visited. The [typeProvider] is the object used to
   * access the types from the core library. The [errorListener] is the error
   * listener that will be informed of any errors that are found during
   * resolution. The [nameScope] is the scope used to resolve identifiers in the
   * node that will first be visited.  If `null` or unspecified, a new
   * [LibraryScope] will be created based on [definingLibrary] and
   * [typeProvider]. The [inheritanceManager] is used to perform inheritance
   * lookups.  If `null` or unspecified, a new [InheritanceManager] will be
   * created based on [definingLibrary]. The [typeAnalyzerFactory] is used to
   * create the type analyzer.  If `null` or unspecified, a type analyzer of
   * type [StaticTypeAnalyzer] will be created.
   */
  ResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    AnalysisOptions options = definingLibrary.context.analysisOptions;
    this.strongMode = options.strongMode;
    this.elementResolver = new ElementResolver(this);
    this.typeSystem = definingLibrary.context.typeSystem;
    bool strongModeHints = false;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
    }
    this.inferenceContext = new InferenceContext._(
        typeProvider, typeSystem, strongModeHints, errorReporter);
    this.typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Return the element representing the function containing the current node, or `null` if
   * the current node is not contained in a function.
   *
   * @return the element representing the function containing the current node
   */
  ExecutableElement get enclosingFunction => _enclosingFunction;

  /**
   * Return the object keeping track of which elements have had their types overridden.
   *
   * @return the object keeping track of which elements have had their types overridden
   */
  TypeOverrideManager get overrideManager => _overrideManager;

  /**
   * Return the object keeping track of which elements have had their types promoted.
   *
   * @return the object keeping track of which elements have had their types promoted
   */
  TypePromotionManager get promoteManager => _promoteManager;

  /**
   * Return the propagated element associated with the given expression whose type can be
   * overridden, or `null` if there is no element whose type can be overridden.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getOverridablePropagatedElement(Expression expression) {
    Element element = null;
    if (expression is SimpleIdentifier) {
      element = expression.propagatedElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.propagatedElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.propagatedElement;
    }
    if (element is VariableElement) {
      return element;
    }
    return null;
  }

  /**
   * Return the static element associated with the given expression whose type can be overridden, or
   * `null` if there is no element whose type can be overridden.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getOverridableStaticElement(Expression expression) {
    Element element = null;
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

  /**
   * Return the static element associated with the given expression whose type
   * can be promoted, or `null` if there is no element whose type can be
   * promoted.
   */
  VariableElement getPromotionStaticElement(Expression expression) {
    expression = expression?.unParenthesized;
    if (expression is SimpleIdentifier) {
      Element element = expression.staticElement;
      if (element is VariableElement) {
        ElementKind kind = element.kind;
        if (kind == ElementKind.LOCAL_VARIABLE ||
            kind == ElementKind.PARAMETER) {
          return element;
        }
      }
    }
    return null;
  }

  /**
   * Prepares this [ResolverVisitor] to using it for incremental resolution.
   */
  void initForIncrementalResolution() {
    _overrideManager.enterScope();
  }

  /**
   * Given a downward inference type [fnType], and the declared
   * [typeParameterList] for a function expression, determines if we can enable
   * downward inference and if so, returns the function type to use for
   * inference.
   *
   * This will return null if inference is not possible. This happens when
   * there is no way we can find a subtype of the function type, given the
   * provided type parameter list.
   */
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
      // StrongTypeSystemImpl.inferFunctionTypeInstantiation, but we don't
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
    return fnType.instantiate(typeParameters
        .map((TypeParameter t) =>
            (t.name.staticElement as TypeParameterElement).type)
        .toList());
  }

  /**
   * If it is appropriate to do so, override the current type of the static and propagated elements
   * associated with the given expression with the given type. Generally speaking, it is appropriate
   * if the given type is more specific than the current type.
   *
   * @param expression the expression used to access the static and propagated elements whose types
   *          might be overridden
   * @param potentialType the potential type of the elements
   * @param allowPrecisionLoss see @{code overrideVariable} docs
   */
  void overrideExpression(Expression expression, DartType potentialType,
      bool allowPrecisionLoss, bool setExpressionType) {
    VariableElement element = getOverridableStaticElement(expression);
    if (element != null) {
      DartType newBestType =
          overrideVariable(element, potentialType, allowPrecisionLoss);
      if (setExpressionType) {
        recordPropagatedTypeIfBetter(expression, newBestType);
      }
    }
    element = getOverridablePropagatedElement(expression);
    if (element != null) {
      overrideVariable(element, potentialType, allowPrecisionLoss);
    }
  }

  /**
   * If it is appropriate to do so, override the current type of the given element with the given
   * type.
   *
   * @param element the element whose type might be overridden
   * @param potentialType the potential type of the element
   * @param allowPrecisionLoss true if `potentialType` is allowed to be less precise than the
   *          current best type
   *
   * Return a new better [DartType], or `null` if [potentialType] is not better
   * than the current [element] type.
   */
  DartType overrideVariable(VariableElement element, DartType potentialType,
      bool allowPrecisionLoss) {
    // TODO(scheglov) type propagation for instance/top-level fields
    // was disabled because it depends on the order or visiting.
    // If both field and its client are in the same unit, and we visit
    // the client before the field, then propagated type is not set yet.
    if (element is PropertyInducingElement) {
      return null;
    }

    if (potentialType == null ||
        potentialType.isBottom ||
        potentialType.isDartCoreNull) {
      return null;
    }
    DartType currentType = _overrideManager.getBestType(element);

    if (potentialType == currentType) {
      return null;
    }

    // If we aren't allowing precision loss then the third and fourth conditions
    // check that we aren't losing precision.
    //
    // Let [C] be the current type and [P] be the potential type.  When we
    // aren't allowing precision loss -- which is the case for is-checks -- we
    // check that [! (C << P)] or  [P << C]. The second check, that [P << C], is
    // analogous to part of the Dart Language Spec rule for type promotion under
    // is-checks (in the analogy [T] is [P] and [S] is [C]):
    //
    //   An is-expression of the form [v is T] shows that [v] has type [T] iff
    //   [T] is more specific than the type [S] of the expression [v] and both
    //   [T != dynamic] and [S != dynamic].
    //
    // It also covers an important case that is not applicable in the spec:
    // for union types, we want an is-check to promote from an union type to
    // (a subtype of) any of its members.
    //
    // The first check, that [! (C << P)], covers the case where [P] and [C] are
    // unrelated types; This case is not addressed in the spec for static types.
    if (currentType == null ||
        allowPrecisionLoss ||
        !currentType.isMoreSpecificThan(potentialType) ||
        potentialType.isMoreSpecificThan(currentType)) {
      _overrideManager.setType(element, potentialType);
      return potentialType;
    }
    return null;
  }

  /**
   * A client is about to resolve a member in the given class declaration.
   */
  void prepareToResolveMembersInClass(ClassDeclaration node) {
    _enclosingClassDeclaration = node;
    enclosingClass = node.element;
    typeAnalyzer.thisType = enclosingClass?.type;
  }

  /**
   * If the given [type] is valid, strongly more specific than the
   * existing static type of the given [expression], record it as a propagated
   * type of the given [expression]. Otherwise, reset it to `null`.
   *
   * If [hasOldPropagatedType] is `true` then the existing propagated type
   * should also is checked.
   */
  void recordPropagatedTypeIfBetter(Expression expression, DartType type,
      [bool hasOldPropagatedType = false]) {
    // Ensure that propagated type invalid.
    if (strongMode ||
        type == null ||
        type.isBottom ||
        type.isDynamic ||
        type.isDartCoreNull) {
      if (!hasOldPropagatedType) {
        expression.propagatedType = null;
      }
      return;
    }
    // Ensure that propagated type is more specific than the static type.
    DartType staticType = expression.staticType;
    if (type == staticType || !type.isMoreSpecificThan(staticType)) {
      expression.propagatedType = null;
      return;
    }
    // Ensure that the new propagated type is more specific than the old one.
    if (hasOldPropagatedType) {
      DartType oldPropagatedType = expression.propagatedType;
      if (oldPropagatedType != null &&
          !type.isMoreSpecificThan(oldPropagatedType)) {
        return;
      }
    }
    // OK
    expression.propagatedType = type;
  }

  /**
   * Visit the given [comment] if it is not `null`.
   */
  void safelyVisitComment(Comment comment) {
    if (comment != null) {
      super.visitComment(comment);
    }
  }

  @override
  Object visitAnnotation(Annotation node) {
    AstNode parent = node.parent;
    if (identical(parent, _enclosingClassDeclaration) ||
        identical(parent, _enclosingFunctionTypeAlias)) {
      return null;
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
      elementAnnotationImpl.annotationAst =
          new ConstantAstCloner().cloneNode(node);
    }
    return null;
  }

  @override
  Object visitArgumentList(ArgumentList node) {
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
    return super.visitArgumentList(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    // Since an as-statement doesn't actually change the type, we don't
    // let it affect the propagated type when it would result in a loss
    // of precision.
    overrideExpression(node.expression, node.type.type, false, false);
    return null;
  }

  @override
  Object visitAssertInitializer(AssertInitializer node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    super.visitAssertInitializer(node);
    return null;
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    super.visitAssertStatement(node);
    _propagateTrueState(node.condition);
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide?.accept(this);
    TokenType operator = node.operator.type;
    if (operator == TokenType.EQ ||
        operator == TokenType.QUESTION_QUESTION_EQ) {
      InferenceContext.setType(
          node.rightHandSide, node.leftHandSide.staticType);
    }
    node.rightHandSide?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    DartType contextType = InferenceContext.getContext(node);
    if (contextType != null) {
      var futureUnion = _createFutureOr(contextType);
      InferenceContext.setType(node.expression, futureUnion);
    }
    return super.visitAwaitExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    TokenType operatorType = node.operator.type;
    Expression leftOperand = node.leftOperand;
    Expression rightOperand = node.rightOperand;
    if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
      leftOperand?.accept(this);
      if (rightOperand != null) {
        _overrideManager.enterScope();
        try {
          _promoteManager.enterScope();
          try {
            _propagateTrueState(leftOperand);
            // Type promotion.
            _promoteTypes(leftOperand);
            _clearTypePromotionsIfPotentiallyMutatedIn(leftOperand);
            _clearTypePromotionsIfPotentiallyMutatedIn(rightOperand);
            _clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(
                rightOperand);
            // Visit right operand.
            rightOperand.accept(this);
          } finally {
            _promoteManager.exitScope();
          }
        } finally {
          _overrideManager.exitScope();
        }
      }
    } else if (operatorType == TokenType.BAR_BAR) {
      leftOperand?.accept(this);
      if (rightOperand != null) {
        _overrideManager.enterScope();
        try {
          _propagateFalseState(leftOperand);
          rightOperand.accept(this);
        } finally {
          _overrideManager.exitScope();
        }
      }
    } else {
      // TODO(leafp): Do downwards inference using the declared type
      // of the binary operator for other cases.
      if (operatorType == TokenType.QUESTION_QUESTION) {
        InferenceContext.setTypeFromNode(leftOperand, node);
      }
      leftOperand?.accept(this);
      if (operatorType == TokenType.QUESTION_QUESTION) {
        // Set the right side, either from the context, or using the information
        // from the left side if it is more precise.
        DartType contextType = InferenceContext.getContext(node);
        DartType leftType = leftOperand?.staticType;
        if (contextType == null || contextType.isDynamic) {
          contextType = leftType;
        }
        InferenceContext.setType(rightOperand, contextType);
      }
      rightOperand?.accept(this);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    _overrideManager.enterScope();
    try {
      inferenceContext.pushReturnContext(node);
      super.visitBlockFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
      inferenceContext.popReturnContext(node);
    }
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitCascadeExpression(CascadeExpression node) {
    InferenceContext.setTypeFromNode(node.target, node);
    return super.visitCascadeExpression(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
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
      enclosingClass = node.element;
      typeAnalyzer.thisType = enclosingClass?.type;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.type;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
    return null;
  }

  /**
   * Implementation of this method should be synchronized with
   * [visitClassDeclaration].
   */
  visitClassDeclarationIncrementally(ClassDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    node.metadata?.accept(this);
    _enclosingClassDeclaration = node;
    //
    // Continue the class resolution.
    //
    enclosingClass = node.element;
    typeAnalyzer.thisType = enclosingClass?.type;
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  Object visitComment(Comment node) {
    AstNode parent = node.parent;
    if (parent is FunctionDeclaration ||
        parent is FunctionTypeAlias ||
        parent is ConstructorDeclaration ||
        parent is MethodDeclaration) {
      return null;
    }
    super.visitComment(node);
    return null;
  }

  @override
  Object visitCommentReference(CommentReference node) {
    //
    // We do not visit the identifier because it needs to be visited in the
    // context of the reference.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    _overrideManager.enterScope();
    try {
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
    } finally {
      _overrideManager.exitScope();
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    condition?.accept(this);
    Expression thenExpression = node.thenExpression;
    if (thenExpression != null) {
      _overrideManager.enterScope();
      try {
        _promoteManager.enterScope();
        try {
          _propagateTrueState(condition);
          // Type promotion.
          _promoteTypes(condition);
          _clearTypePromotionsIfPotentiallyMutatedIn(thenExpression);
          _clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(
              thenExpression);
          // Visit "then" expression.
          InferenceContext.setTypeFromNode(thenExpression, node);
          thenExpression.accept(this);
        } finally {
          _promoteManager.exitScope();
        }
      } finally {
        _overrideManager.exitScope();
      }
    }
    Expression elseExpression = node.elseExpression;
    if (elseExpression != null) {
      _overrideManager.enterScope();
      try {
        _propagateFalseState(condition);
        InferenceContext.setTypeFromNode(elseExpression, node);
        elseExpression.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    bool thenIsAbrupt = _isAbruptTerminationExpression(thenExpression);
    bool elseIsAbrupt = _isAbruptTerminationExpression(elseExpression);
    if (elseIsAbrupt && !thenIsAbrupt) {
      _propagateTrueState(condition);
      _propagateState(thenExpression);
    } else if (thenIsAbrupt && !elseIsAbrupt) {
      _propagateFalseState(condition);
      _propagateState(elseExpression);
    }
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    FunctionBody outerFunctionBody = _currentFunctionBody;
    try {
      _currentFunctionBody = node.body;
      _enclosingFunction = node.element;
      FunctionType type = _enclosingFunction.type;
      InferenceContext.setType(node.body, type.returnType);
      super.visitConstructorDeclaration(node);
    } finally {
      _currentFunctionBody = outerFunctionBody;
      _enclosingFunction = outerFunction;
    }
    ConstructorElementImpl constructor = node.element;
    constructor.constantInitializers =
        new ConstantAstCloner().cloneNodeList(node.initializers);
    return null;
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
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    FieldElement fieldElement = enclosingClass.getField(node.fieldName.name);
    InferenceContext.setType(node.expression, fieldElement?.type);
    node.expression?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    //
    // We do not visit either the type name, because it won't be visited anyway,
    // or the name, because it needs to be visited in the context of the
    // constructor name.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    InferenceContext.setType(node.defaultValue,
        resolutionMap.elementDeclaredByFormalParameter(node.parameter)?.type);
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.element;
    if (element.initializer != null && node.defaultValue != null) {
      (element.initializer as FunctionElementImpl).returnType =
          node.defaultValue.staticType;
    }
    // Clone the ASTs for default formal parameters, so that we can use them
    // during constant evaluation.
    if (!_hasSerializedConstantInitializer(element)) {
      (element as ConstVariableElement).constantInitializer =
          new ConstantAstCloner().cloneNode(node.defaultValue);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    _overrideManager.enterScope();
    try {
      super.visitDoStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(node.getCondition());
    return null;
  }

  @override
  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return null;
    }
    return super.visitEmptyFunctionBody(node);
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    //
    // Resolve the metadata in the library scope
    // and associate the annotations with the element.
    //
    if (node.metadata != null) {
      node.metadata.accept(this);
      ElementResolver.resolveMetadata(node);
    }
    //
    // Continue the enum resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.element;
      typeAnalyzer.thisType = enclosingClass?.type;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.type;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return null;
    }
    _overrideManager.enterScope();
    try {
      InferenceContext.setTypeFromNode(node.expression, node);
      super.visitExpressionFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _overrideManager.enterScope();
    try {
      super.visitFieldDeclaration(node);
    } finally {
      Map<VariableElement, DartType> overrides =
          _overrideManager.captureOverrides(node.fields);
      _overrideManager.exitScope();
      _overrideManager.applyOverrides(overrides);
    }
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    _overrideManager.enterScope();
    try {
      super.visitForEachStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  @override
  void visitForEachStatementInScope(ForEachStatement node) {
    //
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    //
    Expression iterable = node.iterable;
    DeclaredIdentifier loopVariable = node.loopVariable;
    SimpleIdentifier identifier = node.identifier;
    if (loopVariable?.type?.type != null) {
      InterfaceType targetType = (node.awaitKeyword == null)
          ? typeProvider.iterableType
          : typeProvider.streamType;
      InferenceContext.setType(
          iterable,
          targetType
              .instantiate([resolutionMap.typeForTypeName(loopVariable.type)]));
    }
    iterable?.accept(this);
    loopVariable?.accept(this);
    identifier?.accept(this);
    Statement body = node.body;
    if (body != null) {
      _overrideManager.enterScope();
      try {
        if (loopVariable != null && iterable != null) {
          LocalVariableElement loopElement = loopVariable.element;
          if (loopElement != null) {
            DartType propagatedType = null;
            if (node.awaitKeyword == null) {
              propagatedType = _getIteratorElementType(iterable);
            } else {
              propagatedType = _getStreamElementType(iterable);
            }
            if (propagatedType != null) {
              overrideVariable(loopElement, propagatedType, true);
              recordPropagatedTypeIfBetter(
                  loopVariable.identifier, propagatedType);
            }
          }
        } else if (identifier != null && iterable != null) {
          Element identifierElement = identifier.staticElement;
          if (identifierElement is VariableElement) {
            DartType iteratorElementType = _getIteratorElementType(iterable);
            overrideVariable(identifierElement, iteratorElementType, true);
            recordPropagatedTypeIfBetter(identifier, iteratorElementType);
          }
        }
        visitStatementInScope(body);
      } finally {
        _overrideManager.exitScope();
      }
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  Object visitForStatement(ForStatement node) {
    _overrideManager.enterScope();
    try {
      super.visitForStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  @override
  void visitForStatementInScope(ForStatement node) {
    node.variables?.accept(this);
    node.initialization?.accept(this);
    node.condition?.accept(this);
    _overrideManager.enterScope();
    try {
      _propagateTrueState(node.condition);
      visitStatementInScope(node.body);
      node.updaters.accept(this);
    } finally {
      _overrideManager.exitScope();
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    FunctionBody outerFunctionBody = _currentFunctionBody;
    try {
      SimpleIdentifier functionName = node.name;
      _currentFunctionBody = node.functionExpression.body;
      _enclosingFunction = functionName.staticElement as ExecutableElement;
      InferenceContext.setType(
          node.functionExpression, _enclosingFunction.type);
      super.visitFunctionDeclaration(node);
    } finally {
      _currentFunctionBody = outerFunctionBody;
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    FunctionBody outerFunctionBody = _currentFunctionBody;
    try {
      _currentFunctionBody = node.body;
      _enclosingFunction = node.element;
      _overrideManager.enterScope();
      try {
        DartType functionType = InferenceContext.getContext(node);
        var ts = typeSystem;
        if (functionType is FunctionType && ts is StrongTypeSystemImpl) {
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
        _overrideManager.exitScope();
      }
    } finally {
      _currentFunctionBody = outerFunctionBody;
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function?.accept(this);
    node.accept(elementResolver);
    _inferArgumentTypesForInvocation(node);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
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
    return null;
  }

  @override
  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAliasInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) => null;

  @override
  Object visitHideCombinator(HideCombinator node) => null;

  @override
  Object visitIfStatement(IfStatement node) {
    Expression condition = node.condition;
    condition?.accept(this);
    Map<VariableElement, DartType> thenOverrides =
        const <VariableElement, DartType>{};
    Statement thenStatement = node.thenStatement;
    if (thenStatement != null) {
      _overrideManager.enterScope();
      try {
        _promoteManager.enterScope();
        try {
          _propagateTrueState(condition);
          // Type promotion.
          _promoteTypes(condition);
          _clearTypePromotionsIfPotentiallyMutatedIn(thenStatement);
          _clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(
              thenStatement);
          // Visit "then".
          visitStatementInScope(thenStatement);
        } finally {
          _promoteManager.exitScope();
        }
      } finally {
        thenOverrides = _overrideManager.captureLocalOverrides();
        _overrideManager.exitScope();
      }
    }
    Map<VariableElement, DartType> elseOverrides =
        const <VariableElement, DartType>{};
    Statement elseStatement = node.elseStatement;
    if (elseStatement != null) {
      _overrideManager.enterScope();
      try {
        _propagateFalseState(condition);
        visitStatementInScope(elseStatement);
      } finally {
        elseOverrides = _overrideManager.captureLocalOverrides();
        _overrideManager.exitScope();
      }
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    // Join overrides.
    bool thenIsAbrupt = _isAbruptTerminationStatement(thenStatement);
    bool elseIsAbrupt = _isAbruptTerminationStatement(elseStatement);
    if (elseIsAbrupt && !thenIsAbrupt) {
      _propagateTrueState(condition);
      _overrideManager.applyOverrides(thenOverrides);
    } else if (thenIsAbrupt && !elseIsAbrupt) {
      _propagateFalseState(condition);
      _overrideManager.applyOverrides(elseOverrides);
    } else if (!thenIsAbrupt && !elseIsAbrupt) {
      List<Map<VariableElement, DartType>> perBranchOverrides =
          <Map<VariableElement, DartType>>[];
      perBranchOverrides.add(thenOverrides);
      perBranchOverrides.add(elseOverrides);
      _overrideManager.mergeOverrides(perBranchOverrides);
    }
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.constructorName?.accept(this);
    _inferArgumentTypesForInstanceCreate(node);
    node.argumentList?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitLabel(Label node) => null;

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitListLiteral(ListLiteral node) {
    InterfaceType listT;

    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments.map((t) => t.type).toList();
      if (targs.length == 1 && !targs[0].isDynamic) {
        listT = typeProvider.listType.instantiate([targs[0]]);
      }
    } else if (strongMode) {
      listT = typeAnalyzer.inferListType(node, downwards: true);
    }
    if (listT != null) {
      DartType eType = listT.typeArguments[0];
      for (Expression child in node.elements) {
        InferenceContext.setType(child, eType);
      }
      InferenceContext.setType(node, listT);
    } else {
      InferenceContext.clearType(node);
    }
    super.visitListLiteral(node);
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    InterfaceType mapT;
    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments.map((t) => t.type).toList();
      if (targs.length == 2 && targs.any((t) => !t.isDynamic)) {
        mapT = typeProvider.mapType.instantiate([targs[0], targs[1]]);
      }
    } else if (strongMode) {
      mapT = typeAnalyzer.inferMapType(node, downwards: true);
    }
    if (mapT != null) {
      DartType kType = mapT.typeArguments[0];
      DartType vType = mapT.typeArguments[1];
      for (MapLiteralEntry entry in node.entries) {
        InferenceContext.setType(entry.key, kType);
        InferenceContext.setType(entry.value, vType);
      }
      InferenceContext.setType(node, mapT);
    } else {
      InferenceContext.clearType(node);
    }
    super.visitMapLiteral(node);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    FunctionBody outerFunctionBody = _currentFunctionBody;
    try {
      _currentFunctionBody = node.body;
      _enclosingFunction = node.element;
      DartType returnType =
          _computeReturnOrYieldType(_enclosingFunction.type?.returnType);
      InferenceContext.setType(node.body, returnType);
      super.visitMethodDeclaration(node);
    } finally {
      _currentFunctionBody = outerFunctionBody;
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    //
    // We visit the target and argument list, but do not visit the method name
    // because it needs to be visited in the context of the invocation.
    //
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.accept(elementResolver);
    _inferArgumentTypesForInvocation(node);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    return super.visitNamedExpression(node);
  }

  @override
  Object visitNode(AstNode node) {
    node.visitChildren(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    return super.visitParenthesizedExpression(node);
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    //
    // We visit the prefix, but do not visit the identifier because it needs to
    // be visited in the context of the prefix.
    //
    node.prefix?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    //
    // We visit the target, but do not visit the property name because it needs
    // to be visited in the context of the property access node.
    //
    node.target?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    InferenceContext.setType(node.argumentList,
        resolutionMap.staticElementForConstructorReference(node)?.type);
    node.argumentList?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    Expression e = node.expression;
    InferenceContext.setType(e, inferenceContext.returnContext);
    super.visitReturnStatement(node);
    DartType type = e?.staticType;
    // Generators cannot return values, so don't try to do any inference if
    // we're processing erroneous code.
    if (type != null && _enclosingFunction?.isGenerator == false) {
      if (_enclosingFunction.isAsynchronous) {
        type = type.flattenFutures(typeSystem);
      }
      inferenceContext.addReturnOrYieldType(type);
    }
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) => null;

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    InferenceContext.setType(node.argumentList,
        resolutionMap.staticElementForConstructorReference(node)?.type);
    node.argumentList?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _overrideManager.enterScope();
    try {
      super.visitSwitchCase(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _overrideManager.enterScope();
    try {
      super.visitSwitchDefault(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _overrideManager.enterScope();
    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      Map<VariableElement, DartType> overrides =
          _overrideManager.captureOverrides(node.variables);
      _overrideManager.exitScope();
      _overrideManager.applyOverrides(overrides);
    }
    return null;
  }

  @override
  Object visitTypeName(TypeName node) => null;

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    InferenceContext.setTypeFromNode(node.initializer, node);
    super.visitVariableDeclaration(node);
    VariableElement element = node.element;
    if (element.initializer != null && node.initializer != null) {
      (element.initializer as FunctionElementImpl).returnType =
          node.initializer.staticType;
    }
    // Note: in addition to cloning the initializers for const variables, we
    // have to clone the initializers for non-static final fields (because if
    // they occur in a class with a const constructor, they will be needed to
    // evaluate the const constructor).
    if ((element.isConst ||
            (element is FieldElement &&
                element.isFinal &&
                !element.isStatic)) &&
        node.initializer != null) {
      (element as ConstVariableElement).constantInitializer =
          new ConstantAstCloner().cloneNode(node.initializer);
    }
    return null;
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    for (VariableDeclaration decl in node.variables) {
      VariableElement variableElement =
          resolutionMap.elementDeclaredByVariableDeclaration(decl);
      InferenceContext.setType(decl, variableElement?.type);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    // Note: since we don't call the base class, we have to maintain
    // _implicitLabelScope ourselves.
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      Expression condition = node.condition;
      condition?.accept(this);
      Statement body = node.body;
      if (body != null) {
        _overrideManager.enterScope();
        try {
          _propagateTrueState(condition);
          visitStatementInScope(body);
        } finally {
          _overrideManager.exitScope();
        }
      }
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
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
        InterfaceType wrapperType = _enclosingFunction.isSynchronous
            ? typeProvider.iterableType
            : typeProvider.streamType;
        type = wrapperType.instantiate(<DartType>[type]);
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
        InterfaceType wrapperType = _enclosingFunction.isSynchronous
            ? typeProvider.iterableType
            : typeProvider.streamType;
        type = typeSystem.mostSpecificTypeArgument(type, wrapperType);
      }
      if (type != null) {
        inferenceContext.addReturnOrYieldType(type);
      }
    }
    return null;
  }

  /**
   * Checks each promoted variable in the current scope for compliance with the following
   * specification statement:
   *
   * If the variable <i>v</i> is accessed by a closure in <i>s<sub>1</sub></i> then the variable
   * <i>v</i> is not potentially mutated anywhere in the scope of <i>v</i>.
   */
  void _clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(
      AstNode target) {
    for (Element element in _promoteManager.promotedElements) {
      if (_currentFunctionBody.isPotentiallyMutatedInScope(element)) {
        if (_isVariableAccessedInClosure(element, target)) {
          _promoteManager.setType(element, null);
        }
      }
    }
  }

  /**
   * Checks each promoted variable in the current scope for compliance with the following
   * specification statement:
   *
   * <i>v</i> is not potentially mutated in <i>s<sub>1</sub></i> or within a closure.
   */
  void _clearTypePromotionsIfPotentiallyMutatedIn(AstNode target) {
    for (Element element in _promoteManager.promotedElements) {
      if (_isVariablePotentiallyMutatedIn(element, target)) {
        _promoteManager.setType(element, null);
      }
    }
  }

  /**
   * Given the declared return type of a function, compute the type of the
   * values which should be returned or yielded as appropriate.  If a type
   * cannot be computed from the declared return type, return null.
   */
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
        InterfaceType rawType = isAsynchronous
            ? typeProvider.streamType
            : typeProvider.iterableType;
        // Match the types to instantiate the type arguments if possible
        List<DartType> targs = declaredType.typeArguments;
        if (targs.length == 1 && rawType.instantiate(targs) == declaredType) {
          return targs[0];
        }
      }
      // async functions expect `Future<T> | T`
      var futureTypeParam = declaredType.flattenFutures(typeSystem);
      return _createFutureOr(futureTypeParam);
    }
    return declaredType;
  }

  /**
   * Creates a union of `T | Future<T>`, unless `T` is already a
   * future-union, in which case it simply returns `T`.
   */
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType.instantiate([type]);
  }

  /**
   * The given expression is the expression used to compute the iterator for a
   * for-each statement. Attempt to compute the type of objects that will be
   * assigned to the loop variable and return that type. Return `null` if the
   * type could not be determined. The [iteratorExpression] is the expression
   * that will return the Iterable being iterated over.
   */
  DartType _getIteratorElementType(Expression iteratorExpression) {
    DartType expressionType = iteratorExpression.bestType;
    if (expressionType is InterfaceType) {
      PropertyAccessorElement iteratorFunction =
          expressionType.lookUpInheritedGetter("iterator");
      if (iteratorFunction == null) {
        // TODO(brianwilkerson) Should we report this error?
        return null;
      }
      DartType iteratorType = iteratorFunction.returnType;
      if (iteratorType is InterfaceType) {
        PropertyAccessorElement currentFunction =
            iteratorType.lookUpInheritedGetter("current");
        if (currentFunction == null) {
          // TODO(brianwilkerson) Should we report this error?
          return null;
        }
        return currentFunction.returnType;
      }
    }
    return null;
  }

  /**
   * The given expression is the expression used to compute the stream for an
   * asynchronous for-each statement. Attempt to compute the type of objects
   * that will be assigned to the loop variable and return that type.
   * Return `null` if the type could not be determined. The [streamExpression]
   * is the expression that will return the stream being iterated over.
   */
  DartType _getStreamElementType(Expression streamExpression) {
    DartType streamType = streamExpression.bestType;
    if (streamType is InterfaceType) {
      MethodElement listenFunction = streamType.lookUpInheritedMethod("listen");
      if (listenFunction == null) {
        return null;
      }
      List<ParameterElement> listenParameters = listenFunction.parameters;
      if (listenParameters == null || listenParameters.length < 1) {
        return null;
      }
      DartType onDataType = listenParameters[0].type;
      if (onDataType is FunctionType) {
        List<ParameterElement> onDataParameters = onDataType.parameters;
        if (onDataParameters == null || onDataParameters.isEmpty) {
          return null;
        }
        return onDataParameters[0].type;
      }
    }
    return null;
  }

  /**
   * Return `true` if the given [parameter] element of the AST being resolved
   * is resynthesized and is an API-level, not local, so has its initializer
   * serialized.
   */
  bool _hasSerializedConstantInitializer(ParameterElement parameter) {
    if (LibraryElementImpl.hasResolutionCapability(
        definingLibrary, LibraryResolutionCapability.constantExpressions)) {
      Element executable = parameter.enclosingElement;
      if (executable is MethodElement) {
        return true;
      }
      if (executable is FunctionElement) {
        return executable.enclosingElement is CompilationUnitElement;
      }
    }
    return false;
  }

  FunctionType _inferArgumentTypesForGeneric(AstNode inferenceNode,
      DartType uninstantiatedType, TypeArgumentList typeArguments,
      {AstNode errorNode}) {
    errorNode ??= inferenceNode;
    TypeSystem ts = typeSystem;
    if (typeArguments == null &&
        uninstantiatedType is FunctionType &&
        uninstantiatedType.typeFormals.isNotEmpty &&
        ts is StrongTypeSystemImpl) {
      return ts.inferGenericFunctionOrType<FunctionType>(
          uninstantiatedType,
          ParameterElement.EMPTY_LIST,
          DartType.EMPTY_LIST,
          InferenceContext.getContext(inferenceNode),
          downwards: true,
          errorReporter: errorReporter,
          errorNode: errorNode);
    }
    return null;
  }

  void _inferArgumentTypesForInstanceCreate(InstanceCreationExpression node) {
    ConstructorName constructor = node.constructorName;
    TypeName classTypeName = constructor?.type;
    if (classTypeName == null || !strongMode) {
      return;
    }

    ConstructorElement originalElement =
        resolutionMap.staticElementForConstructorReference(constructor);
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
          errorNode: node.constructorName);

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
    if (!strongMode) {
      // Use propagated type inference for lambdas if not in strong mode.
      _inferFunctionExpressionsParametersTypes(node.argumentList);
      return;
    }
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

  /**
   * If given "mayBeClosure" is [FunctionExpression] without explicit parameters types and its
   * required type is [FunctionType], then infer parameters types from [FunctionType].
   */
  void _inferFunctionExpressionParametersTypes(
      Expression mayBeClosure, DartType mayByFunctionType) {
    // prepare closure
    if (mayBeClosure is! FunctionExpression) {
      return;
    }
    FunctionExpression closure = mayBeClosure as FunctionExpression;
    // prepare expected closure type
    if (mayByFunctionType is! FunctionType) {
      return;
    }
    FunctionType expectedClosureType = mayByFunctionType as FunctionType;
    // If the expectedClosureType is not more specific than the static type,
    // return.
    DartType staticClosureType =
        resolutionMap.elementDeclaredByFunctionExpression(closure)?.type;
    if (staticClosureType != null &&
        !FunctionTypeImpl.relate(
            expectedClosureType,
            staticClosureType,
            (s, t) => true,
            new TypeSystemImpl(typeProvider).instantiateToBounds,
            parameterRelation: (t, s) =>
                (t.type as TypeImpl).isMoreSpecificThan(s.type))) {
      return;
    }
    // set propagated type for the closure
    if (!strongMode) {
      closure.propagatedType = expectedClosureType;
    }
    // set inferred types for parameters
    NodeList<FormalParameter> parameters = closure.parameters.parameters;
    List<ParameterElement> expectedParameters = expectedClosureType.parameters;
    for (int i = 0;
        i < parameters.length && i < expectedParameters.length;
        i++) {
      FormalParameter parameter = parameters[i];
      ParameterElement element = parameter.element;
      DartType currentType = _overrideManager.getBestType(element);
      // may be override the type
      DartType expectedType = expectedParameters[i].type;
      if (currentType == null || expectedType.isMoreSpecificThan(currentType)) {
        _overrideManager.setType(element, expectedType);
      }
    }
  }

  /**
   * Try to infer types of parameters of the [FunctionExpression] arguments.
   */
  void _inferFunctionExpressionsParametersTypes(ArgumentList argumentList) {
    NodeList<Expression> arguments = argumentList.arguments;
    int length = arguments.length;
    for (int i = 0; i < length; i++) {
      Expression argument = arguments[i];
      ParameterElement parameter = argument.propagatedParameterElement;
      if (parameter == null) {
        parameter = argument.staticParameterElement;
      }
      if (parameter != null) {
        _inferFunctionExpressionParametersTypes(argument, parameter.type);
      }
    }
  }

  /**
   * Return `true` if the given expression terminates abruptly (that is, if any expression
   * following the given expression will not be reached).
   *
   * @param expression the expression being tested
   * @return `true` if the given expression terminates abruptly
   */
  bool _isAbruptTerminationExpression(Expression expression) {
    // TODO(brianwilkerson) This needs to be significantly improved. Ideally we
    // would eventually turn this into a method on Expression that returns a
    // termination indication (normal, abrupt with no exception, abrupt with an
    // exception).
    expression = expression?.unParenthesized;
    return expression is ThrowExpression || expression is RethrowExpression;
  }

  /**
   * Return `true` if the given statement terminates abruptly (that is, if any statement
   * following the given statement will not be reached).
   *
   * @param statement the statement being tested
   * @return `true` if the given statement terminates abruptly
   */
  bool _isAbruptTerminationStatement(Statement statement) {
    // TODO(brianwilkerson) This needs to be significantly improved. Ideally we
    // would eventually turn this into a method on Statement that returns a
    // termination indication (normal, abrupt with no exception, abrupt with an
    // exception).
    //
    // collinsn: it is unsound to assume that [break] and [continue] are
    // "abrupt". See: https://code.google.com/p/dart/issues/detail?id=19929#c4
    // (tests are included in TypePropagationTest.java).
    // In general, the difficulty is loopy control flow.
    //
    // In the presence of exceptions things become much more complicated, but
    // while we only use this to propagate at [if]-statement join points,
    // checking for [return] may work well enough in the common case.
    if (statement is ReturnStatement) {
      return true;
    } else if (statement is ExpressionStatement) {
      return _isAbruptTerminationExpression(statement.expression);
    } else if (statement is Block) {
      NodeList<Statement> statements = statement.statements;
      int size = statements.length;
      if (size == 0) {
        return false;
      }

      // This last-statement-is-return heuristic is unsound for adversarial
      // code, but probably works well in the common case:
      //
      //   var x = 123;
      //   var c = true;
      //   L: if (c) {
      //     x = "hello";
      //     c = false;
      //     break L;
      //     return;
      //   }
      //   print(x);
      //
      // Unsound to assume that [x = "hello";] never executed after the
      // if-statement. Of course, a dead-code analysis could point out that
      // [return] here is dead.
      return _isAbruptTerminationStatement(statements[size - 1]);
    }
    return false;
  }

  /**
   * Return `true` if the given variable is accessed within a closure in the given
   * [AstNode] and also mutated somewhere in variable scope. This information is only
   * available for local variables (including parameters).
   *
   * @param variable the variable to check
   * @param target the [AstNode] to check within
   * @return `true` if this variable is potentially mutated somewhere in the given ASTNode
   */
  bool _isVariableAccessedInClosure(Element variable, AstNode target) {
    _ResolverVisitor_isVariableAccessedInClosure visitor =
        new _ResolverVisitor_isVariableAccessedInClosure(variable);
    target.accept(visitor);
    return visitor.result;
  }

  /**
   * Return `true` if the given variable is potentially mutated somewhere in the given
   * [AstNode]. This information is only available for local variables (including parameters).
   *
   * @param variable the variable to check
   * @param target the [AstNode] to check within
   * @return `true` if this variable is potentially mutated somewhere in the given ASTNode
   */
  bool _isVariablePotentiallyMutatedIn(Element variable, AstNode target) {
    _ResolverVisitor_isVariablePotentiallyMutatedIn visitor =
        new _ResolverVisitor_isVariablePotentiallyMutatedIn(variable);
    target.accept(visitor);
    return visitor.result;
  }

  /**
   * If it is appropriate to do so, promotes the current type of the static element associated with
   * the given expression with the given type. Generally speaking, it is appropriate if the given
   * type is more specific than the current type.
   *
   * @param expression the expression used to access the static element whose types might be
   *          promoted
   * @param potentialType the potential type of the elements
   */
  void _promote(Expression expression, DartType potentialType) {
    VariableElement element = getPromotionStaticElement(expression);
    if (element != null) {
      // may be mutated somewhere in closure
      if (_currentFunctionBody.isPotentiallyMutatedInClosure(element)) {
        return;
      }
      // prepare current variable type
      DartType type = _promoteManager.getType(element) ??
          expression.staticType ??
          DynamicTypeImpl.instance;

      potentialType ??= DynamicTypeImpl.instance;

      // Check if we can promote to potentialType from type.
      DartType promoteType = typeSystem.tryPromoteToType(potentialType, type);
      if (promoteType != null) {
        // Do promote type of variable.
        _promoteManager.setType(element, promoteType);
      }
    }
  }

  /**
   * Promotes type information using given condition.
   */
  void _promoteTypes(Expression condition) {
    if (condition is BinaryExpression) {
      if (condition.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        Expression left = condition.leftOperand;
        Expression right = condition.rightOperand;
        _promoteTypes(left);
        _promoteTypes(right);
        _clearTypePromotionsIfPotentiallyMutatedIn(right);
      }
    } else if (condition is IsExpression) {
      if (condition.notOperator == null) {
        _promote(condition.expression, condition.type.type);
      }
    } else if (condition is ParenthesizedExpression) {
      _promoteTypes(condition.expression);
    }
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'false'.
   *
   * @param condition the condition that will have evaluated to 'false'
   */
  void _propagateFalseState(Expression condition) {
    if (condition is BinaryExpression) {
      if (condition.operator.type == TokenType.BAR_BAR) {
        _propagateFalseState(condition.leftOperand);
        _propagateFalseState(condition.rightOperand);
      }
    } else if (condition is IsExpression) {
      if (condition.notOperator != null) {
        // Since an is-statement doesn't actually change the type, we don't
        // let it affect the propagated type when it would result in a loss
        // of precision.
        overrideExpression(
            condition.expression, condition.type.type, false, false);
      }
    } else if (condition is PrefixExpression) {
      if (condition.operator.type == TokenType.BANG) {
        _propagateTrueState(condition.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      _propagateFalseState(condition.expression);
    }
  }

  /**
   * Propagate any type information that results from knowing that the given expression will have
   * been evaluated without altering the flow of execution.
   *
   * @param expression the expression that will have been evaluated
   */
  void _propagateState(Expression expression) {
    // TODO(brianwilkerson) Implement this.
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'true'.
   *
   * @param condition the condition that will have evaluated to 'true'
   */
  void _propagateTrueState(Expression condition) {
    if (condition is BinaryExpression) {
      if (condition.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        _propagateTrueState(condition.leftOperand);
        _propagateTrueState(condition.rightOperand);
      }
    } else if (condition is IsExpression) {
      if (condition.notOperator == null) {
        // Since an is-statement doesn't actually change the type, we don't
        // let it affect the propagated type when it would result in a loss
        // of precision.
        overrideExpression(
            condition.expression, condition.type.type, false, false);
      }
    } else if (condition is PrefixExpression) {
      if (condition.operator.type == TokenType.BANG) {
        _propagateFalseState(condition.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      _propagateTrueState(condition.expression);
    }
  }

  /**
   * Given an [argumentList] and the [parameters] related to the element that
   * will be invoked using those arguments, compute the list of parameters that
   * correspond to the list of arguments.
   *
   * An error will be reported to [onError] if any of the arguments cannot be
   * matched to a parameter. onError can be null to ignore the error.
   *
   * The flag [reportAsError] should be `true` if a compile-time error should be
   * reported; or `false` if a compile-time warning should be reported.
   *
   * Returns the parameters that correspond to the arguments. If no parameter
   * matched an argument, that position will be `null` in the list.
   */
  static List<ParameterElement> resolveArgumentsToParameters(
      ArgumentList argumentList,
      List<ParameterElement> parameters,
      void onError(ErrorCode errorCode, AstNode node, [List<Object> arguments]),
      {bool reportAsError: false}) {
    if (parameters.isEmpty && argumentList.arguments.isEmpty) {
      return const <ParameterElement>[];
    }
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    List<ParameterElement> unnamedParameters = new List<ParameterElement>();
    HashMap<String, ParameterElement> namedParameters = null;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      ParameterKind kind = parameter.parameterKind;
      if (kind == ParameterKind.REQUIRED) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
        requiredParameterCount++;
      } else if (kind == ParameterKind.POSITIONAL) {
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
    HashSet<String> usedNames = null;
    bool noBlankArguments = true;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        SimpleIdentifier nameNode = argument.name.label;
        String name = nameNode.name;
        ParameterElement element =
            namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          ErrorCode errorCode = (reportAsError
              ? CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER
              : StaticWarningCode.UNDEFINED_NAMED_PARAMETER);
          if (onError != null) {
            onError(errorCode, nameNode, [name]);
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
      ErrorCode errorCode = (reportAsError
          ? CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS
          : StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS);
      if (onError != null) {
        onError(errorCode, argumentList,
            [requiredParameterCount, positionalArgumentCount]);
      }
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      ErrorCode errorCode;
      int namedParameterCount = namedParameters?.length ?? 0;
      int namedArgumentCount = usedNames?.length ?? 0;
      if (namedParameterCount > namedArgumentCount) {
        errorCode = (reportAsError
            ? CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED
            : StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED);
      } else {
        errorCode = (reportAsError
            ? CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS
            : StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS);
      }
      if (onError != null) {
        onError(errorCode, argumentList,
            [unnamedParameterCount, positionalArgumentCount]);
      }
    }
    return resolvedParameters;
  }
}

/**
 * The abstract class `ScopedVisitor` maintains name and label scopes as an AST structure is
 * being visited.
 */
/**
 * The abstract class `ScopedVisitor` maintains name and label scopes as an AST structure is
 * being visited.
 */
abstract class ScopedVisitor extends UnifyingAstVisitor<Object> {
  /**
   * The element for the library containing the compilation unit being visited.
   */
  final LibraryElement definingLibrary;

  /**
   * The source representing the compilation unit being visited.
   */
  final Source source;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider typeProvider;

  /**
   * The error reporter that will be informed of any errors that are found
   * during resolution.
   */
  final ErrorReporter errorReporter;

  /**
   * The scope used to resolve identifiers.
   */
  Scope nameScope;

  /**
   * The scope used to resolve unlabeled `break` and `continue` statements.
   */
  ImplicitLabelScope _implicitLabelScope = ImplicitLabelScope.ROOT;

  /**
   * The scope used to resolve labels for `break` and `continue` statements, or
   * `null` if no labels have been defined in the current context.
   */
  LabelScope labelScope;

  /**
   * The class containing the AST nodes being visited,
   * or `null` if we are not in the scope of a class.
   */
  ClassElement enclosingClass;

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation
   * unit.
   *
   * [definingLibrary] is the element for the library containing the
   * compilation unit being visited.
   * [source] is the source representing the compilation unit being visited.
   * [typeProvider] is the object used to access the types from the core
   * library.
   * [errorListener] is the error listener that will be informed of any errors
   * that are found during resolution.
   * [nameScope] is the scope used to resolve identifiers in the node that will
   * first be visited.  If `null` or unspecified, a new [LibraryScope] will be
   * created based on [definingLibrary] and [typeProvider].
   */
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

  /**
   * Return the implicit label scope in which the current node is being
   * resolved.
   */
  ImplicitLabelScope get implicitLabelScope => _implicitLabelScope;

  /**
   * Replaces the current [Scope] with the enclosing [Scope].
   *
   * @return the enclosing [Scope].
   */
  Scope popNameScope() {
    nameScope = nameScope.enclosingScope;
    return nameScope;
  }

  /**
   * Pushes a new [Scope] into the visitor.
   *
   * @return the new [Scope].
   */
  Scope pushNameScope() {
    Scope newScope = new EnclosedScope(nameScope);
    nameScope = newScope;
    return nameScope;
  }

  @override
  Object visitBlock(Block node) {
    Scope outerScope = nameScope;
    try {
      EnclosedScope enclosedScope = new BlockScope(nameScope, node);
      nameScope = enclosedScope;
      super.visitBlock(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    ImplicitLabelScope implicitOuterScope = _implicitLabelScope;
    try {
      _implicitLabelScope = ImplicitLabelScope.ROOT;
      super.visitBlockFunctionBody(node);
    } finally {
      _implicitLabelScope = implicitOuterScope;
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
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
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement classElement = node.element;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for class declaration ${node.name
                .name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
        super.visitClassDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.element;
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
    return null;
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
  Object visitClassTypeAlias(ClassTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.element;
      nameScope =
          new ClassScope(new TypeParameterScope(nameScope, element), element);
      super.visitClassTypeAlias(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement constructorElement = node.element;
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
      AnalysisEngine.instance.logger.logInformation(buffer.toString(),
          new CaughtException(new AnalysisException(), null));
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
    return null;
  }

  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    node.body?.accept(this);
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    VariableElement element = node.element;
    if (element != null) {
      nameScope.define(element);
    }
    super.visitDeclaredIdentifier(node);
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitStatementInScope(node.body);
      node.condition?.accept(this);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    ClassElement classElement = node.element;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for enum declaration ${node.name
                .name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
        super.visitEnumDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.element;
          nameScope = new ClassScope(nameScope, classElement);
          visitEnumMembersInScope(node);
        } finally {
          enclosingClass = outerClass;
        }
      }
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.constants.accept(this);
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitForEachStatementInScope(node);
    } finally {
      nameScope = outerNameScope;
      _implicitLabelScope = outerImplicitScope;
    }
    return null;
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   *
   * @param node the statement to be visited
   */
  void visitForEachStatementInScope(ForEachStatement node) {
    //
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    //
    node.identifier?.accept(this);
    node.iterable?.accept(this);
    node.loopVariable?.accept(this);
    visitStatementInScope(node.body);
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
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
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
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
    return null;
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   *
   * @param node the statement to be visited
   */
  void visitForStatementInScope(ForStatement node) {
    node.variables?.accept(this);
    node.initialization?.accept(this);
    node.condition?.accept(this);
    node.updaters.accept(this);
    visitStatementInScope(node.body);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement functionElement = node.element;
    if (functionElement != null &&
        functionElement.enclosingElement is! CompilationUnitElement) {
      nameScope.define(functionElement);
    }
    Scope outerScope = nameScope;
    try {
      if (functionElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for top-level function ${node.name
                .name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new FunctionScope(nameScope, functionElement);
      }
      visitFunctionDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // We have already created a function scope and don't need to do so again.
      super.visitFunctionExpression(node);
    } else {
      Scope outerScope = nameScope;
      try {
        ExecutableElement functionElement = node.element;
        if (functionElement == null) {
          StringBuffer buffer = new StringBuffer();
          buffer.write("Missing element for function ");
          AstNode parent = node.parent;
          while (parent != null) {
            if (parent is Declaration) {
              Element parentElement = parent.element;
              buffer.write(parentElement == null
                  ? "<unknown> "
                  : "${parentElement.name} ");
            }
            parent = parent.parent;
          }
          buffer.write("in ");
          buffer.write(definingLibrary.source.fullName);
          AnalysisEngine.instance.logger.logInformation(buffer.toString(),
              new CaughtException(new AnalysisException(), null));
        } else {
          nameScope = new FunctionScope(nameScope, functionElement);
        }
        super.visitFunctionExpression(node);
      } finally {
        nameScope = outerScope;
      }
    }
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      nameScope = new FunctionTypeScope(nameScope, node.element);
      visitFunctionTypeAliasInScope(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    Scope outerScope = nameScope;
    try {
      ParameterElement parameterElement = node.element;
      if (parameterElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for function typed formal parameter ${node
                .identifier.name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new EnclosedScope(nameScope);
        List<TypeParameterElement> typeParameters =
            parameterElement.typeParameters;
        int length = typeParameters.length;
        for (int i = 0; i < length; i++) {
          nameScope.define(typeParameters[i]);
        }
      }
      super.visitFunctionTypedFormalParameter(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionTypeElement element = node.type.element;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for generic function type in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
        super.visitGenericFunctionType(node);
      } else {
        nameScope = new TypeParameterScope(nameScope, element);
        super.visitGenericFunctionType(node);
      }
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitGenericTypeAlias(GenericTypeAlias node) {
    TypeParameterizedElement element = node.element;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for generic function type in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
        super.visitGenericTypeAlias(node);
      } else {
        nameScope = new TypeParameterScope(nameScope, element);
        super.visitGenericTypeAlias(node);
      }
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    node.condition?.accept(this);
    visitStatementInScope(node.thenStatement);
    visitStatementInScope(node.elseStatement);
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    LabelScope outerScope = _addScopesFor(node.labels, node.unlabeled);
    try {
      super.visitLabeledStatement(node);
    } finally {
      labelScope = outerScope;
    }
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ExecutableElement methodElement = node.element;
      if (methodElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for method ${node.name.name} in ${definingLibrary
                .source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new FunctionScope(nameScope, methodElement);
      }
      visitMethodDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
  }

  /**
   * Visit the given statement after it's scope has been created. This is used by ResolverVisitor to
   * correctly visit the 'then' and 'else' statements of an 'if' statement.
   *
   * @param node the statement to be visited
   */
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
  Object visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);
    Scope outerNameScope = nameScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
    return null;
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = new EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
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
      super.visitSwitchStatement(node);
    } finally {
      labelScope = outerScope;
      _implicitLabelScope = outerImplicitScope;
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (node.parent.parent is! TopLevelVariableDeclaration &&
        node.parent.parent is! FieldDeclaration) {
      VariableElement element = node.element;
      if (element != null) {
        nameScope.define(element);
      }
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    node.condition?.accept(this);
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitStatementInScope(node.body);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
    return null;
  }

  /**
   * Add scopes for each of the given labels.
   *
   * @param labels the labels for which new scopes are to be added
   * @return the scope that was in effect before the new scopes were added
   */
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

/**
 * Instances of this class manage the knowledge of what the set of subtypes are for a given type.
 */
class SubtypeManager {
  /**
   * A map between [ClassElement]s and a set of [ClassElement]s that are subtypes of the
   * key.
   */
  HashMap<ClassElement, HashSet<ClassElement>> _subtypeMap =
      new HashMap<ClassElement, HashSet<ClassElement>>();

  /**
   * The set of all [LibraryElement]s that have been visited by the manager. This is used both
   * to prevent infinite loops in the recursive methods, and also as a marker for the scope of the
   * libraries visited by this manager.
   */
  HashSet<LibraryElement> _visitedLibraries = new HashSet<LibraryElement>();

  /**
   * Given some [ClassElement], return the set of all subtypes, and subtypes of subtypes.
   *
   * @param classElement the class to recursively return the set of subtypes of
   */
  HashSet<ClassElement> computeAllSubtypes(ClassElement classElement) {
    // Ensure that we have generated the subtype map for the library
    _computeSubtypesInLibrary(classElement.library);
    // use the subtypeMap to compute the set of all subtypes and subtype's
    // subtypes
    HashSet<ClassElement> allSubtypes = new HashSet<ClassElement>();
    _safelyComputeAllSubtypes(
        classElement, new HashSet<ClassElement>(), allSubtypes);
    return allSubtypes;
  }

  /**
   * Given some [LibraryElement], visit all of the types in the library, the passed library,
   * and any imported libraries, will be in the [visitedLibraries] set.
   *
   * @param libraryElement the library to visit, it it hasn't been visited already
   */
  void ensureLibraryVisited(LibraryElement libraryElement) {
    _computeSubtypesInLibrary(libraryElement);
  }

  /**
   * Given some [ClassElement], this method adds all of the pairs combinations of itself and
   * all of its supertypes to the [subtypeMap] map.
   *
   * @param classElement the class element
   */
  void _computeSubtypesInClass(ClassElement classElement) {
    InterfaceType supertypeType = classElement.supertype;
    if (supertypeType != null) {
      ClassElement supertypeElement = supertypeType.element;
      if (supertypeElement != null) {
        _putInSubtypeMap(supertypeElement, classElement);
      }
    }
    List<InterfaceType> interfaceTypes = classElement.interfaces;
    int interfaceLength = interfaceTypes.length;
    for (int i = 0; i < interfaceLength; i++) {
      InterfaceType interfaceType = interfaceTypes[i];
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        _putInSubtypeMap(interfaceElement, classElement);
      }
    }
    List<InterfaceType> mixinTypes = classElement.mixins;
    int mixinLength = mixinTypes.length;
    for (int i = 0; i < mixinLength; i++) {
      InterfaceType mixinType = mixinTypes[i];
      ClassElement mixinElement = mixinType.element;
      if (mixinElement != null) {
        _putInSubtypeMap(mixinElement, classElement);
      }
    }
  }

  /**
   * Given some [CompilationUnitElement], this method calls
   * [computeAllSubtypes] on all of the [ClassElement]s in the
   * compilation unit.
   *
   * @param unitElement the compilation unit element
   */
  void _computeSubtypesInCompilationUnit(CompilationUnitElement unitElement) {
    List<ClassElement> classElements = unitElement.types;
    int length = classElements.length;
    for (int i = 0; i < length; i++) {
      ClassElement classElement = classElements[i];
      _computeSubtypesInClass(classElement);
    }
  }

  /**
   * Given some [LibraryElement], this method calls
   * [computeAllSubtypes] on all of the [ClassElement]s in the
   * compilation unit, and itself for all imported and exported libraries. All visited libraries are
   * added to the [visitedLibraries] set.
   *
   * @param libraryElement the library element
   */
  void _computeSubtypesInLibrary(LibraryElement libraryElement) {
    if (libraryElement == null || _visitedLibraries.contains(libraryElement)) {
      return;
    }
    _visitedLibraries.add(libraryElement);
    _computeSubtypesInCompilationUnit(libraryElement.definingCompilationUnit);
    List<CompilationUnitElement> parts = libraryElement.parts;
    int partLength = parts.length;
    for (int i = 0; i < partLength; i++) {
      CompilationUnitElement part = parts[i];
      _computeSubtypesInCompilationUnit(part);
    }
    List<LibraryElement> imports = libraryElement.importedLibraries;
    int importLength = imports.length;
    for (int i = 0; i < importLength; i++) {
      LibraryElement importElt = imports[i];
      _computeSubtypesInLibrary(importElt.library);
    }
    List<LibraryElement> exports = libraryElement.exportedLibraries;
    int exportLength = exports.length;
    for (int i = 0; i < exportLength; i++) {
      LibraryElement exportElt = exports[i];
      _computeSubtypesInLibrary(exportElt.library);
    }
  }

  /**
   * Add some key/ value pair into the [subtypeMap] map.
   *
   * @param supertypeElement the key for the [subtypeMap] map
   * @param subtypeElement the value for the [subtypeMap] map
   */
  void _putInSubtypeMap(
      ClassElement supertypeElement, ClassElement subtypeElement) {
    HashSet<ClassElement> subtypes = _subtypeMap[supertypeElement];
    if (subtypes == null) {
      subtypes = new HashSet<ClassElement>();
      _subtypeMap[supertypeElement] = subtypes;
    }
    subtypes.add(subtypeElement);
  }

  /**
   * Given some [ClassElement] and a [HashSet<ClassElement>], this method recursively
   * adds all of the subtypes of the [ClassElement] to the passed array.
   *
   * @param classElement the type to compute the set of subtypes of
   * @param visitedClasses the set of class elements that this method has already recursively seen
   * @param allSubtypes the computed set of subtypes of the passed class element
   */
  void _safelyComputeAllSubtypes(ClassElement classElement,
      HashSet<ClassElement> visitedClasses, HashSet<ClassElement> allSubtypes) {
    if (!visitedClasses.add(classElement)) {
      // if this class has already been called on this class element
      return;
    }
    HashSet<ClassElement> subtypes = _subtypeMap[classElement];
    if (subtypes == null) {
      return;
    }
    for (ClassElement subtype in subtypes) {
      _safelyComputeAllSubtypes(subtype, visitedClasses, allSubtypes);
    }
    allSubtypes.addAll(subtypes);
  }
}

/**
 * Instances of the class `ToDoFinder` find to-do comments in Dart code.
 */
class ToDoFinder {
  /**
   * The error reporter by which to-do comments will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * Initialize a newly created to-do finder to report to-do comments to the given reporter.
   *
   * @param errorReporter the error reporter by which to-do comments will be reported
   */
  ToDoFinder(this._errorReporter);

  /**
   * Search the comments in the given compilation unit for to-do comments and report an error for
   * each.
   *
   * @param unit the compilation unit containing the to-do comments
   */
  void findIn(CompilationUnit unit) {
    _gatherTodoComments(unit.beginToken);
  }

  /**
   * Search the comment tokens reachable from the given token and create errors for each to-do
   * comment.
   *
   * @param token the head of the list of tokens being searched
   */
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

  /**
   * Look for user defined tasks in comments and convert them into info level analysis issues.
   *
   * @param commentToken the comment token to analyze
   */
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

/**
 * Helper for resolving types.
 *
 * The client must set [nameScope] before calling [resolveTypeName].
 */
class TypeNameResolver {
  final TypeSystem typeSystem;
  final DartType dynamicType;
  final DartType undefinedType;
  final LibraryElement definingLibrary;
  final Source source;
  final AnalysisErrorListener errorListener;

  Scope nameScope;

  TypeNameResolver(this.typeSystem, TypeProvider typeProvider,
      this.definingLibrary, this.source, this.errorListener)
      : dynamicType = typeProvider.dynamicType,
        undefinedType = typeProvider.undefinedType;

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    errorListener.onError(new AnalysisError(
        source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Resolve the given [TypeName] - set its element and static type. Only the
   * given [node] is resolved, all its children must be already resolved.
   *
   * The client must set [nameScope] before calling [resolveTypeName].
   */
  void resolveTypeName(TypeName node) {
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
      if (typeName.name == dynamicType.name) {
        _setElement(typeName, dynamicType.element);
//        if (argumentList != null) {
//          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, dynamicType.getName(), 0, argumentList.getArguments().size());
//        }
        typeName.staticType = dynamicType;
        node.type = dynamicType;
        return;
      }
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
//        if (argumentList != null) {
//          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, voidType.getName(), 0, argumentList.getArguments().size());
//        }
        typeName.staticType = voidType;
        node.type = voidType;
        return;
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        typeName.staticType = undefinedType;
        node.type = undefinedType;
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
              typeName.staticType = undefinedType;
              node.type = undefinedType;
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
          }
        }
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        typeName.staticType = undefinedType;
        node.type = undefinedType;
        return;
      }
    }
    // check element
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid &&
        element is! ClassElement &&
        _isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation =
          node.parent.parent as InstanceCreationExpression;
      if (creation.isConst) {
        if (element == null) {
          reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_CLASS, typeNameSimple, [typeName]);
        } else {
          reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE,
              typeNameSimple, [typeName]);
        }
        elementValid = false;
      } else {
        if (element != null) {
          reportErrorForNode(
              StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
          elementValid = false;
        }
      }
    }
    if (elementValid && element == null) {
      // We couldn't resolve the type name.
      // TODO(jwren) Consider moving the check for
      // CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE from the
      // ErrorVerifier, so that we don't have two errors on a built in
      // identifier being used as a class name.
      // See CompileTimeErrorCodeTest.test_builtInIdentifierAsType().
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      RedirectingConstructorKind redirectingConstructorKind;
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
      } else if ((redirectingConstructorKind =
              _getRedirectingConstructorKind(node)) !=
          null) {
        ErrorCode errorCode =
            (redirectingConstructorKind == RedirectingConstructorKind.CONST
                ? CompileTimeErrorCode.REDIRECT_TO_NON_CLASS
                : StaticWarningCode.REDIRECT_TO_NON_CLASS);
        reportErrorForNode(errorCode, typeName, [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else {
        reportErrorForNode(
            StaticWarningCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
      elementValid = false;
    }
    if (!elementValid) {
      if (element is MultiplyDefinedElement) {
        _setElement(typeName, element);
      }
      typeName.staticType = undefinedType;
      node.type = undefinedType;
      return;
    }
    DartType type = null;
    if (element is ClassElement) {
      type = element.type;
      // In non-strong mode `FutureOr<T>` is treated as `dynamic`
      if (!typeSystem.isStrong && type.isDartAsyncFutureOr) {
        type = dynamicType;
        _setElement(typeName, type.element);
        typeName.staticType = type;
        node.type = type;
        if (argumentList != null) {
          NodeList<TypeAnnotation> arguments = argumentList.arguments;
          if (arguments.length != 1) {
            reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
                [typeName.name, 1, arguments.length]);
          }
        }
        return;
      }
      _setElement(typeName, element);
    } else if (element is FunctionTypeAliasElement) {
      _setElement(typeName, element);
      type = element.type;
    } else if (element is TypeParameterElement) {
      _setElement(typeName, element);
      type = element.type;
//      if (argumentList != null) {
//        // Type parameters cannot have type arguments.
//        // TODO(brianwilkerson) Report this error.
//        //      resolver.reportError(ResolverErrorCode.?, keyType);
//      }
    } else if (element is MultiplyDefinedElement) {
      List<Element> elements = element.conflictingElements;
      type = _getTypeWhenMultiplyDefined(elements);
      if (type != null) {
        node.type = type;
      }
    } else {
      // The name does not represent a type.
      RedirectingConstructorKind redirectingConstructorKind;
      if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, typeName,
            [typeName.name]);
      } else if ((redirectingConstructorKind =
              _getRedirectingConstructorKind(node)) !=
          null) {
        ErrorCode errorCode =
            (redirectingConstructorKind == RedirectingConstructorKind.CONST
                ? CompileTimeErrorCode.REDIRECT_TO_NON_CLASS
                : StaticWarningCode.REDIRECT_TO_NON_CLASS);
        reportErrorForNode(errorCode, typeName, [typeName.name]);
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
          reportErrorForNode(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
              typeName, [typeName.name]);
        } else {
          reportErrorForNode(
              StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      typeName.staticType = dynamicType;
      node.type = dynamicType;
      return;
    }
    if (argumentList != null) {
      NodeList<TypeAnnotation> arguments = argumentList.arguments;
      int argumentCount = arguments.length;
      List<DartType> parameters = typeSystem.typeFormalsAsTypes(type);
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
        type = element.typeAfterSubstitution(typeArguments) ?? dynamicType;
      } else {
        type = typeSystem.instantiateType(type, typeArguments);
      }
    } else {
      if (element is GenericTypeAliasElementImpl) {
        type = element.typeAfterSubstitution(null) ?? dynamicType;
      } else {
        type = typeSystem.instantiateToBounds(type);
      }
    }
    typeName.staticType = type;
    node.type = type;
  }

  /**
   * The number of type arguments in the given [typeName] does not match the
   * number of parameters in the corresponding class element. Return the error
   * code that should be used to report this error.
   */
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

  /**
   * Checks if the given [typeName] is the target in a redirected constructor.
   */
  RedirectingConstructorKind _getRedirectingConstructorKind(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      AstNode grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        if (identical(grandParent.redirectedConstructor, parent)) {
          if (grandParent.constKeyword != null) {
            return RedirectingConstructorKind.CONST;
          }
          return RedirectingConstructorKind.NORMAL;
        }
      }
    }
    return null;
  }

  /**
   * Return the type represented by the given type [annotation].
   */
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      return undefinedType;
    } else if (type is FunctionType) {
      Element element = type.element;
      if (annotation is TypeName && element is GenericTypeAliasElementImpl) {
        TypeArgumentList argumentList = annotation.typeArguments;
        List<DartType> typeArguments = null;
        if (argumentList != null) {
          List<TypeAnnotation> arguments = argumentList.arguments;
          int argumentCount = arguments.length;
          typeArguments = new List<DartType>(argumentCount);
          for (int i = 0; i < argumentCount; i++) {
            typeArguments[i] = _getType(arguments[i]);
          }
        }
        return element.typeAfterSubstitution(typeArguments) ?? dynamicType;
      }
    }
    return type;
  }

  /**
   * Returns the simple identifier of the given (may be qualified) type name.
   *
   * @param typeName the (may be qualified) qualified type name
   * @return the simple identifier of the given (may be qualified) type name.
   */
  SimpleIdentifier _getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName;
    } else {
      return (typeName as PrefixedIdentifier).identifier;
    }
  }

  /**
   * Given the multiple elements to which a single name could potentially be resolved, return the
   * single interface type that should be used, or `null` if there is no clear choice.
   *
   * @param elements the elements to which a single name could potentially be resolved
   * @return the single interface type that should be used for the type name
   */
  InterfaceType _getTypeWhenMultiplyDefined(List<Element> elements) {
    InterfaceType type = null;
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element is ClassElement) {
        if (type != null) {
          return null;
        }
        type = element.type;
      }
    }
    return type;
  }

  /**
   * Checks if the given [typeName] is used as the type in an as expression.
   */
  bool _isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given [typeName] is used as the exception type in a catch
   * clause.
   */
  bool _isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, typeName);
    }
    return false;
  }

  /**
   * Checks if the given [typeName] is used as the type in an instance creation
   * expression.
   */
  bool _isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      return parent != null && identical(parent.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given [typeName] is used as the type in an is expression.
   */
  bool _isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given [typeName] used in a type argument list.
   */
  bool _isTypeNameInTypeArgumentList(TypeName typeName) =>
      typeName.parent is TypeArgumentList;

  /**
   * Records the new Element for a TypeName's Identifier.
   *
   * A null may be passed in to indicate that the element can't be resolved.
   * (During a re-run of a task, it's important to clear any previous value
   * of the element.)
   */
  void _setElement(Identifier typeName, Element element) {
    if (typeName is SimpleIdentifier) {
      typeName.staticElement = element;
    } else if (typeName is PrefixedIdentifier) {
      typeName.identifier.staticElement = element;
      SimpleIdentifier prefix = typeName.prefix;
      prefix.staticElement = nameScope.lookup(prefix, definingLibrary);
    }
  }

  /**
   * Return `true` if the name of the given [typeName] is an built-in identifier.
   */
  static bool _isBuiltInIdentifier(TypeName typeName) {
    Token token = typeName.name.beginToken;
    return token.type.isKeyword;
  }

  /**
   * @return `true` if given [typeName] is used as a type annotation.
   */
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

/**
 * Instances of the class `TypeOverrideManager` manage the ability to override the type of an
 * element within a given context.
 */
class TypeOverrideManager {
  /**
   * The current override scope, or `null` if no scope has been entered.
   */
  TypeOverrideManager_TypeOverrideScope currentScope;

  /**
   * Apply a set of overrides that were previously captured.
   *
   * @param overrides the overrides to be applied
   */
  void applyOverrides(Map<VariableElement, DartType> overrides) {
    if (currentScope == null) {
      throw new StateError("Cannot apply overrides without a scope");
    }
    currentScope.applyOverrides(overrides);
  }

  /**
   * Return a table mapping the elements whose type is overridden in the current scope to the
   * overriding type.
   *
   * @return the overrides in the current scope
   */
  Map<VariableElement, DartType> captureLocalOverrides() {
    if (currentScope == null) {
      throw new StateError("Cannot capture local overrides without a scope");
    }
    return currentScope.captureLocalOverrides();
  }

  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   *
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<VariableElement, DartType> captureOverrides(
      VariableDeclarationList variableList) {
    if (currentScope == null) {
      throw new StateError("Cannot capture overrides without a scope");
    }
    return currentScope.captureOverrides(variableList);
  }

  /**
   * Enter a new override scope.
   */
  void enterScope() {
    currentScope = new TypeOverrideManager_TypeOverrideScope(currentScope);
  }

  /**
   * Exit the current override scope.
   */
  void exitScope() {
    if (currentScope == null) {
      throw new StateError("No scope to exit");
    }
    currentScope = currentScope._outerScope;
  }

  /**
   * Return the best type information available for the given element. If the type of the element
   * has been overridden, then return the overriding type. Otherwise, return the static type.
   *
   * @param element the element for which type information is to be returned
   * @return the best type information available for the given element
   */
  DartType getBestType(VariableElement element) {
    DartType bestType = getType(element);
    return bestType ?? element.type;
  }

  /**
   * Return the overridden type of the given element, or `null` if the type of the element has
   * not been overridden.
   *
   * @param element the element whose type might have been overridden
   * @return the overridden type of the given element
   */
  DartType getType(Element element) {
    if (currentScope == null) {
      return null;
    }
    return currentScope.getType(element);
  }

  /**
   * Update overrides assuming [perBranchOverrides] is the collection of
   * per-branch overrides for *all* branches flowing into a join point.
   *
   * If a variable type in any of branches is not the same as its type before
   * the branching, then its propagated type is reset to `null`.
   */
  void mergeOverrides(List<Map<VariableElement, DartType>> perBranchOverrides) {
    int length = perBranchOverrides.length;
    for (int i = 0; i < length; i++) {
      Map<VariableElement, DartType> branch = perBranchOverrides[i];
      branch.forEach((VariableElement variable, DartType branchType) {
        DartType currentType = currentScope.getType(variable);
        if (currentType != branchType) {
          currentScope.resetType(variable);
        }
      });
    }
  }

  /**
   * Set the overridden type of the given element to the given type
   *
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(VariableElement element, DartType type) {
    if (currentScope == null) {
      throw new StateError("Cannot override without a scope");
    }
    currentScope.setType(element, type);
  }
}

/**
 * Instances of the class `TypeOverrideScope` represent a scope in which the types of
 * elements can be overridden.
 */
class TypeOverrideManager_TypeOverrideScope {
  /**
   * The outer scope in which types might be overridden.
   */
  final TypeOverrideManager_TypeOverrideScope _outerScope;

  /**
   * A table mapping elements to the overridden type of that element.
   */
  Map<VariableElement, DartType> _overriddenTypes =
      new HashMap<VariableElement, DartType>();

  /**
   * Initialize a newly created scope to be an empty child of the given scope.
   *
   * @param outerScope the outer scope in which types might be overridden
   */
  TypeOverrideManager_TypeOverrideScope(this._outerScope);

  /**
   * Apply a set of overrides that were previously captured.
   *
   * @param overrides the overrides to be applied
   */
  void applyOverrides(Map<VariableElement, DartType> overrides) {
    _overriddenTypes.addAll(overrides);
  }

  /**
   * Return a table mapping the elements whose type is overridden in the current scope to the
   * overriding type.
   *
   * @return the overrides in the current scope
   */
  Map<VariableElement, DartType> captureLocalOverrides() => _overriddenTypes;

  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   *
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<VariableElement, DartType> captureOverrides(
      VariableDeclarationList variableList) {
    Map<VariableElement, DartType> overrides =
        new HashMap<VariableElement, DartType>();
    if (variableList.isConst || variableList.isFinal) {
      for (VariableDeclaration variable in variableList.variables) {
        VariableElement element = variable.element;
        if (element != null) {
          DartType type = _overriddenTypes[element];
          if (type != null) {
            overrides[element] = type;
          }
        }
      }
    }
    return overrides;
  }

  /**
   * Return the overridden type of the given element, or `null` if the type of the element
   * has not been overridden.
   *
   * @param element the element whose type might have been overridden
   * @return the overridden type of the given element
   */
  DartType getType(Element element) {
    Element nonAccessor =
        element is PropertyAccessorElement ? element.variable : element;
    DartType type = _overriddenTypes[nonAccessor];
    if (_overriddenTypes.containsKey(nonAccessor)) {
      return type;
    }
    return type ?? _outerScope?.getType(element);
  }

  /**
   * Clears the overridden type of the given [element].
   */
  void resetType(VariableElement element) {
    _overriddenTypes[element] = null;
  }

  /**
   * Set the overridden type of the given element to the given type
   *
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(VariableElement element, DartType type) {
    _overriddenTypes[element] = type;
  }
}

/**
 * This class resolves bounds of type parameters of classes, class and function
 * type aliases.
 */
class TypeParameterBoundsResolver {
  final TypeProvider typeProvider;
  final LibraryElement library;
  final Source source;
  final AnalysisErrorListener errorListener;

  Scope libraryScope = null;
  TypeNameResolver typeNameResolver = null;

  TypeParameterBoundsResolver(
      this.typeProvider, this.library, this.source, this.errorListener);

  /**
   * Resolve bounds of type parameters of classes, class and function type
   * aliases.
   */
  void resolveTypeBounds(CompilationUnit unit) {
    for (CompilationUnitMember unitMember in unit.declarations) {
      if (unitMember is ClassDeclaration) {
        _resolveTypeParameters(unitMember.typeParameters,
            () => new TypeParameterScope(libraryScope, unitMember.element));
      } else if (unitMember is ClassTypeAlias) {
        _resolveTypeParameters(unitMember.typeParameters,
            () => new TypeParameterScope(libraryScope, unitMember.element));
      } else if (unitMember is FunctionTypeAlias) {
        _resolveTypeParameters(unitMember.typeParameters,
            () => new FunctionTypeScope(libraryScope, unitMember.element));
      }
    }
  }

  void _resolveTypeName(TypeAnnotation type) {
    if (type is TypeName) {
      type.typeArguments?.arguments?.forEach(_resolveTypeName);
      typeNameResolver.resolveTypeName(type);
      // TODO(scheglov) report error when don't apply type bounds for type bounds
    } else {
      // TODO(brianwilkerson) Add resolution of GenericFunctionType
      throw new ArgumentError('Cannot resolve a ${type.runtimeType}');
    }
  }

  void _resolveTypeParameters(
      TypeParameterList typeParameters, Scope createTypeParametersScope()) {
    if (typeParameters != null) {
      Scope typeParametersScope = null;
      for (TypeParameter typeParameter in typeParameters.typeParameters) {
        TypeAnnotation bound = typeParameter.bound;
        if (bound != null) {
          Element typeParameterElement = typeParameter.name.staticElement;
          if (typeParameterElement is TypeParameterElementImpl) {
            if (LibraryElementImpl.hasResolutionCapability(
                library, LibraryResolutionCapability.resolvedTypeNames)) {
              if (bound is TypeName) {
                bound.type = typeParameterElement.bound;
              } else {
                // TODO(brianwilkerson) Add resolution of GenericFunctionType
                throw new ArgumentError(
                    'Cannot resolve a ${bound.runtimeType}');
              }
            } else {
              libraryScope ??= new LibraryScope(library);
              typeParametersScope ??= createTypeParametersScope();
              typeNameResolver ??= new TypeNameResolver(
                  new TypeSystemImpl(typeProvider),
                  typeProvider,
                  library,
                  source,
                  errorListener);
              typeNameResolver.nameScope = typeParametersScope;
              _resolveTypeName(bound);
              typeParameterElement.bound = bound.type;
            }
          }
        }
      }
    }
  }
}

/**
 * Instances of the class `TypePromotionManager` manage the ability to promote types of local
 * variables and formal parameters from their declared types based on control flow.
 */
class TypePromotionManager {
  /**
   * The current promotion scope, or `null` if no scope has been entered.
   */
  TypePromotionManager_TypePromoteScope currentScope;

  /**
   * Returns the elements with promoted types.
   */
  Iterable<Element> get promotedElements => currentScope.promotedElements;

  /**
   * Enter a new promotions scope.
   */
  void enterScope() {
    currentScope = new TypePromotionManager_TypePromoteScope(currentScope);
  }

  /**
   * Exit the current promotion scope.
   */
  void exitScope() {
    if (currentScope == null) {
      throw new StateError("No scope to exit");
    }
    currentScope = currentScope._outerScope;
  }

  /**
   * Return the static type of the given [variable] - declared or promoted.
   */
  DartType getStaticType(VariableElement variable) =>
      getType(variable) ?? variable.type;

  /**
   * Return the promoted type of the given [element], or `null` if the type of
   * the element has not been promoted.
   */
  DartType getType(Element element) => currentScope?.getType(element);

  /**
   * Set the promoted type of the given element to the given type.
   *
   * @param element the element whose type might have been promoted
   * @param type the promoted type of the given element
   */
  void setType(Element element, DartType type) {
    if (currentScope == null) {
      throw new StateError("Cannot promote without a scope");
    }
    currentScope.setType(element, type);
  }
}

/**
 * Instances of the class `TypePromoteScope` represent a scope in which the types of
 * elements can be promoted.
 */
class TypePromotionManager_TypePromoteScope {
  /**
   * The outer scope in which types might be promoter.
   */
  final TypePromotionManager_TypePromoteScope _outerScope;

  /**
   * A table mapping elements to the promoted type of that element.
   */
  HashMap<Element, DartType> _promotedTypes = new HashMap<Element, DartType>();

  /**
   * Initialize a newly created scope to be an empty child of the given scope.
   *
   * @param outerScope the outer scope in which types might be promoted
   */
  TypePromotionManager_TypePromoteScope(this._outerScope);

  /**
   * Returns the elements with promoted types.
   */
  Iterable<Element> get promotedElements => _promotedTypes.keys.toSet();

  /**
   * Return the promoted type of the given element, or `null` if the type of the element has
   * not been promoted.
   *
   * @param element the element whose type might have been promoted
   * @return the promoted type of the given element
   */
  DartType getType(Element element) {
    DartType type = _promotedTypes[element];
    if (type == null && element is PropertyAccessorElement) {
      type = _promotedTypes[element.variable];
    }
    if (type != null) {
      return type;
    } else if (_outerScope != null) {
      return _outerScope.getType(element);
    }
    return null;
  }

  /**
   * Set the promoted type of the given element to the given type.
   *
   * @param element the element whose type might have been promoted
   * @param type the promoted type of the given element
   */
  void setType(Element element, DartType type) {
    _promotedTypes[element] = type;
  }
}

/**
 * The interface `TypeProvider` defines the behavior of objects that provide access to types
 * defined by the language.
 */
abstract class TypeProvider {
  /**
   * Return the type representing the built-in type 'bool'.
   */
  InterfaceType get boolType;

  /**
   * Return the type representing the type 'bottom'.
   */
  DartType get bottomType;

  /**
   * Return the type representing the built-in type 'Deprecated'.
   */
  InterfaceType get deprecatedType;

  /**
   * Return the type representing the built-in type 'double'.
   */
  InterfaceType get doubleType;

  /**
   * Return the type representing the built-in type 'dynamic'.
   */
  DartType get dynamicType;

  /**
   * Return the type representing the built-in type 'Function'.
   */
  InterfaceType get functionType;

  /**
   * Return the type representing 'Future<dynamic>'.
   */
  InterfaceType get futureDynamicType;

  /**
   * Return the type representing 'Future<Null>'.
   */
  InterfaceType get futureNullType;

  /**
   * Return the type representing 'FutureOr<Null>'.
   */
  InterfaceType get futureOrNullType;

  /**
   * Return the type representing the built-in type 'FutureOr'.
   */
  InterfaceType get futureOrType;

  /**
   * Return the type representing the built-in type 'Future'.
   */
  InterfaceType get futureType;

  /**
   * Return the type representing the built-in type 'int'.
   */
  InterfaceType get intType;

  /**
   * Return the type representing the type 'Iterable<dynamic>'.
   */
  InterfaceType get iterableDynamicType;

  /**
   * Return the type representing the built-in type 'Iterable'.
   */
  InterfaceType get iterableType;

  /**
   * Return the type representing the built-in type 'List'.
   */
  InterfaceType get listType;

  /**
   * Return the type representing the built-in type 'Map'.
   */
  InterfaceType get mapType;

  /**
   * Return a list containing all of the types that cannot be either extended or
   * implemented.
   */
  List<InterfaceType> get nonSubtypableTypes;

  /**
   * Return a [DartObjectImpl] representing the `null` object.
   */
  DartObjectImpl get nullObject;

  /**
   * Return the type representing the built-in type 'Null'.
   */
  InterfaceType get nullType;

  /**
   * Return the type representing the built-in type 'num'.
   */
  InterfaceType get numType;

  /**
   * Return the type representing the built-in type 'Object'.
   */
  InterfaceType get objectType;

  /**
   * Return the type representing the built-in type 'StackTrace'.
   */
  InterfaceType get stackTraceType;

  /**
   * Return the type representing 'Stream<dynamic>'.
   */
  InterfaceType get streamDynamicType;

  /**
   * Return the type representing the built-in type 'Stream'.
   */
  InterfaceType get streamType;

  /**
   * Return the type representing the built-in type 'String'.
   */
  InterfaceType get stringType;

  /**
   * Return the type representing the built-in type 'Symbol'.
   */
  InterfaceType get symbolType;

  /**
   * Return the type representing the built-in type 'Type'.
   */
  InterfaceType get typeType;

  /**
   * Return the type representing typenames that can't be resolved.
   */
  DartType get undefinedType;

  /**
   * Return 'true' if [id] is the name of a getter on
   * the Object type.
   */
  bool isObjectGetter(String id);

  /**
   * Return 'true' if [id] is the name of a method or getter on
   * the Object type.
   */
  bool isObjectMember(String id);

  /**
   * Return 'true' if [id] is the name of a method on
   * the Object type.
   */
  bool isObjectMethod(String id);
}

/**
 * Provide common functionality shared by the various TypeProvider
 * implementations.
 */
abstract class TypeProviderBase implements TypeProvider {
  @override
  List<InterfaceType> get nonSubtypableTypes => <InterfaceType>[
        nullType,
        numType,
        intType,
        doubleType,
        boolType,
        stringType
      ];

  @override
  bool isObjectGetter(String id) {
    PropertyAccessorElement element = objectType.element.getGetter(id);
    return (element != null && !element.isStatic);
  }

  @override
  bool isObjectMember(String id) {
    return isObjectGetter(id) || isObjectMethod(id);
  }

  @override
  bool isObjectMethod(String id) {
    MethodElement element = objectType.element.getMethod(id);
    return (element != null && !element.isStatic);
  }
}

/**
 * Instances of the class `TypeProviderImpl` provide access to types defined by the language
 * by looking for those types in the element model for the core library.
 */
class TypeProviderImpl extends TypeProviderBase {
  /**
   * The type representing the built-in type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'bottom'.
   */
  DartType _bottomType;

  /**
   * The type representing the built-in type 'double'.
   */
  InterfaceType _doubleType;

  /**
   * The type representing the built-in type 'Deprecated'.
   */
  InterfaceType _deprecatedType;

  /**
   * The type representing the built-in type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing the built-in type 'Function'.
   */
  InterfaceType _functionType;

  /**
   * The type representing 'Future<dynamic>'.
   */
  InterfaceType _futureDynamicType;

  /**
   * The type representing 'Future<Null>'.
   */
  InterfaceType _futureNullType;

  /**
   * The type representing 'FutureOr<Null>'.
   */
  InterfaceType _futureOrNullType;

  /**
   * The type representing the built-in type 'FutureOr'.
   */
  InterfaceType _futureOrType;

  /**
   * The type representing the built-in type 'Future'.
   */
  InterfaceType _futureType;

  /**
   * The type representing the built-in type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing 'Iterable<dynamic>'.
   */
  InterfaceType _iterableDynamicType;

  /**
   * The type representing the built-in type 'Iterable'.
   */
  InterfaceType _iterableType;

  /**
   * The type representing the built-in type 'List'.
   */
  InterfaceType _listType;

  /**
   * The type representing the built-in type 'Map'.
   */
  InterfaceType _mapType;

  /**
   * An shared object representing the value 'null'.
   */
  DartObjectImpl _nullObject;

  /**
   * The type representing the type 'Null'.
   */
  InterfaceType _nullType;

  /**
   * The type representing the built-in type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the built-in type 'Object'.
   */
  InterfaceType _objectType;

  /**
   * The type representing the built-in type 'StackTrace'.
   */
  InterfaceType _stackTraceType;

  /**
   * The type representing 'Stream<dynamic>'.
   */
  InterfaceType _streamDynamicType;

  /**
   * The type representing the built-in type 'Stream'.
   */
  InterfaceType _streamType;

  /**
   * The type representing the built-in type 'String'.
   */
  InterfaceType _stringType;

  /**
   * The type representing the built-in type 'Symbol'.
   */
  InterfaceType _symbolType;

  /**
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;

  /**
   * The type representing typenames that can't be resolved.
   */
  DartType _undefinedType;

  /**
   * Initialize a newly created type provider to provide the types defined in
   * the given [coreLibrary] and [asyncLibrary].
   */
  TypeProviderImpl(LibraryElement coreLibrary, LibraryElement asyncLibrary) {
    Namespace coreNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(coreLibrary);
    Namespace asyncNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(asyncLibrary);
    _initializeFrom(coreNamespace, asyncNamespace);
  }

  /**
   * Initialize a newly created type provider to provide the types defined in
   * the given [Namespace]s.
   */
  TypeProviderImpl.forNamespaces(
      Namespace coreNamespace, Namespace asyncNamespace) {
    _initializeFrom(coreNamespace, asyncNamespace);
  }

  @override
  InterfaceType get boolType => _boolType;

  @override
  DartType get bottomType => _bottomType;

  @override
  InterfaceType get deprecatedType => _deprecatedType;

  @override
  InterfaceType get doubleType => _doubleType;

  @override
  DartType get dynamicType => _dynamicType;

  @override
  InterfaceType get functionType => _functionType;

  @override
  InterfaceType get futureDynamicType => _futureDynamicType;

  @override
  InterfaceType get futureNullType => _futureNullType;

  @override
  InterfaceType get futureOrNullType => _futureOrNullType;

  @override
  InterfaceType get futureOrType => _futureOrType;

  @override
  InterfaceType get futureType => _futureType;

  @override
  InterfaceType get intType => _intType;

  @override
  InterfaceType get iterableDynamicType => _iterableDynamicType;

  @override
  InterfaceType get iterableType => _iterableType;

  @override
  InterfaceType get listType => _listType;

  @override
  InterfaceType get mapType => _mapType;

  @override
  DartObjectImpl get nullObject {
    if (_nullObject == null) {
      _nullObject = new DartObjectImpl(nullType, NullState.NULL_STATE);
    }
    return _nullObject;
  }

  @override
  InterfaceType get nullType => _nullType;

  @override
  InterfaceType get numType => _numType;

  @override
  InterfaceType get objectType => _objectType;

  @override
  InterfaceType get stackTraceType => _stackTraceType;

  @override
  InterfaceType get streamDynamicType => _streamDynamicType;

  @override
  InterfaceType get streamType => _streamType;

  @override
  InterfaceType get stringType => _stringType;

  @override
  InterfaceType get symbolType => _symbolType;

  @override
  InterfaceType get typeType => _typeType;

  @override
  DartType get undefinedType => _undefinedType;

  /**
   * Return the type with the given name from the given namespace, or `null` if there is no
   * class with the given name.
   *
   * @param namespace the namespace in which to search for the given name
   * @param typeName the name of the type being searched for
   * @return the type that was found
   */
  InterfaceType _getType(Namespace namespace, String typeName) {
    Element element = namespace.get(typeName);
    if (element == null) {
      AnalysisEngine.instance.logger
          .logInformation("No definition of type $typeName");
      return null;
    }
    return (element as ClassElement).type;
  }

  /**
   * Initialize the types provided by this type provider from the given
   * [Namespace]s.
   */
  void _initializeFrom(Namespace coreNamespace, Namespace asyncNamespace) {
    _boolType = _getType(coreNamespace, "bool");
    _bottomType = BottomTypeImpl.instance;
    _deprecatedType = _getType(coreNamespace, "Deprecated");
    _doubleType = _getType(coreNamespace, "double");
    _dynamicType = DynamicTypeImpl.instance;
    _functionType = _getType(coreNamespace, "Function");
    _futureOrType = _getType(asyncNamespace, "FutureOr");
    _futureType = _getType(asyncNamespace, "Future");
    _intType = _getType(coreNamespace, "int");
    _iterableType = _getType(coreNamespace, "Iterable");
    _listType = _getType(coreNamespace, "List");
    _mapType = _getType(coreNamespace, "Map");
    _nullType = _getType(coreNamespace, "Null");
    _numType = _getType(coreNamespace, "num");
    _objectType = _getType(coreNamespace, "Object");
    _stackTraceType = _getType(coreNamespace, "StackTrace");
    _streamType = _getType(asyncNamespace, "Stream");
    _stringType = _getType(coreNamespace, "String");
    _symbolType = _getType(coreNamespace, "Symbol");
    _typeType = _getType(coreNamespace, "Type");
    _undefinedType = UndefinedTypeImpl.instance;
    _futureDynamicType = _futureType.instantiate(<DartType>[_dynamicType]);
    _futureNullType = _futureType.instantiate(<DartType>[_nullType]);
    _iterableDynamicType = _iterableType.instantiate(<DartType>[_dynamicType]);
    _streamDynamicType = _streamType.instantiate(<DartType>[_dynamicType]);
    // FutureOr<T> is still fairly new, so if we're analyzing an SDK that
    // doesn't have it yet, create an element for it.
    _futureOrType ??= createPlaceholderFutureOr(_futureType, _objectType);
    _futureOrNullType = _futureOrType.instantiate(<DartType>[_nullType]);
  }

  /**
   * Create an [InterfaceType] that can be used for `FutureOr<T>` if the SDK
   * being analyzed does not contain its own `FutureOr<T>`.  This ensures that
   * we can analyze older SDKs.
   */
  static InterfaceType createPlaceholderFutureOr(
      InterfaceType futureType, InterfaceType objectType) {
    var compilationUnit =
        futureType.element.getAncestor((e) => e is CompilationUnitElement);
    var element = ElementFactory.classElement('FutureOr', objectType, ['T']);
    element.enclosingElement = compilationUnit;
    return element.type;
  }
}

/**
 * Modes in which [TypeResolverVisitor] works.
 */
enum TypeResolverMode {
  /**
   * Resolve all names types of all nodes.
   */
  everything,

  /**
   * Resolve only type names outside of function bodies, variable initializers,
   * and parameter default values.
   */
  api,

  /**
   * Resolve only type names that would be skipped during [api].
   *
   * Resolution must start from a unit member or a class member. For example
   * it is not allowed to resolve types in a separate statement, or a function
   * body.
   */
  local
}

/**
 * Instances of the class `TypeResolverVisitor` are used to resolve the types associated with
 * the elements in the element model. This includes the types of superclasses, mixins, interfaces,
 * fields, methods, parameters, and local variables. As a side-effect, this also finishes building
 * the type hierarchy.
 */
class TypeResolverVisitor extends ScopedVisitor {
  /**
   * The type representing the type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing typenames that can't be resolved.
   */
  DartType _undefinedType;

  /**
   * The flag specifying if currently visited class references 'super' expression.
   */
  bool _hasReferenceToSuper = false;

  /**
   * True if we're analyzing in strong mode.
   */
  bool _strongMode;

  /**
   * Type type system in use for this resolver pass.
   */
  TypeSystem _typeSystem;

  /**
   * The helper to resolve types.
   */
  TypeNameResolver _typeNameResolver;

  final TypeResolverMode mode;

  /**
   * Is `true` when we are visiting all nodes in [TypeResolverMode.local] mode.
   */
  bool _localModeVisitAll = false;

  /**
   * Is `true` if we are in [TypeResolverMode.local] mode, and the initial
   * [nameScope] was computed.
   */
  bool _localModeScopeReady = false;

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * [definingLibrary] is the element for the library containing the node being
   * visited.
   * [source] is the source representing the compilation unit containing the
   * node being visited.
   * [typeProvider] is the object used to access the types from the core
   * library.
   * [errorListener] is the error listener that will be informed of any errors
   * that are found during resolution.
   * [nameScope] is the scope used to resolve identifiers in the node that will
   * first be visited.  If `null` or unspecified, a new [LibraryScope] will be
   * created based on [definingLibrary] and [typeProvider].
   */
  TypeResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope, this.mode: TypeResolverMode.everything})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    _dynamicType = typeProvider.dynamicType;
    _undefinedType = typeProvider.undefinedType;
    _strongMode = definingLibrary.context.analysisOptions.strongMode;
    _typeSystem = TypeSystem.create(definingLibrary.context);
    _typeNameResolver = new TypeNameResolver(
        _typeSystem, typeProvider, definingLibrary, source, errorListener);
  }

  @override
  Object visitAnnotation(Annotation node) {
    //
    // Visit annotations, if the annotation is @proxy, on a class, and "proxy"
    // resolves to the proxy annotation in dart.core, then resolve the
    // ElementAnnotation.
    //
    // Element resolution is done in the ElementResolver, and this work will be
    // done in the general case for all annotations in the ElementResolver.
    // The reason we resolve this particular element early is so that
    // ClassElement.isProxy() returns the correct information during all
    // phases of the ElementResolver.
    //
    super.visitAnnotation(node);
    Identifier identifier = node.name;
    if (identifier.name.endsWith(ElementAnnotationImpl.PROXY_VARIABLE_NAME) &&
        node.parent is ClassDeclaration) {
      Element element = nameScope.lookup(identifier, definingLibrary);
      if (element != null &&
          element.library.isDartCore &&
          element is PropertyAccessorElement) {
        // This is the @proxy from dart.core
        ElementAnnotationImpl elementAnnotation = node.elementAnnotation;
        elementAnnotation.element = element;
      }
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      // If an 'on' clause is provided the type of the exception parameter is
      // the type in the 'on' clause. Otherwise, the type of the exception
      // parameter is 'Object'.
      TypeAnnotation exceptionTypeName = node.exceptionType;
      DartType exceptionType;
      if (exceptionTypeName == null) {
        exceptionType = typeProvider.dynamicType;
      } else {
        exceptionType = _typeNameResolver._getType(exceptionTypeName);
      }
      _recordType(exception, exceptionType);
      Element element = exception.staticElement;
      if (element is VariableElementImpl) {
        element.declaredType = exceptionType;
      } else {
        // TODO(brianwilkerson) Report the internal error
      }
    }
    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      _recordType(stackTrace, typeProvider.stackTraceType);
      Element element = stackTrace.staticElement;
      if (element is VariableElementImpl) {
        element.declaredType = typeProvider.stackTraceType;
      } else {
        // TODO(brianwilkerson) Report the internal error
      }
    }
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _hasReferenceToSuper = false;
    super.visitClassDeclaration(node);
    ClassElementImpl classElement = _getClassElement(node.name);
    if (classElement != null) {
      // Clear this flag, as we just invalidated any inferred member types.
      classElement.hasBeenInferred = false;
      classElement.hasReferenceToSuper = _hasReferenceToSuper;
    }
    return null;
  }

  @override
  void visitClassDeclarationInScope(ClassDeclaration node) {
    super.visitClassDeclarationInScope(node);
    ExtendsClause extendsClause = node.extendsClause;
    WithClause withClause = node.withClause;
    ImplementsClause implementsClause = node.implementsClause;
    ClassElementImpl classElement = _getClassElement(node.name);
    InterfaceType superclassType = null;
    if (extendsClause != null) {
      ErrorCode errorCode = (withClause == null
          ? CompileTimeErrorCode.EXTENDS_NON_CLASS
          : CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS);
      superclassType = _resolveType(extendsClause.superclass, errorCode,
          CompileTimeErrorCode.EXTENDS_ENUM, errorCode);
    }
    if (classElement != null) {
      if (superclassType == null) {
        InterfaceType objectType = typeProvider.objectType;
        if (!identical(classElement.type, objectType)) {
          superclassType = objectType;
        }
      }
      classElement.supertype = superclassType;
    }
    _resolve(classElement, withClause, implementsClause);
    return null;
  }

  @override
  void visitClassMembersInScope(ClassDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    //
    // Process field declarations before constructors and methods so that the
    // types of field formal parameters can be correctly resolved.
    //
    List<ClassMember> nonFields = new List<ClassMember>();
    NodeList<ClassMember> members = node.members;
    int length = members.length;
    for (int i = 0; i < length; i++) {
      ClassMember member = members[i];
      if (member is ConstructorDeclaration) {
        nonFields.add(member);
      } else {
        member.accept(this);
      }
    }
    int count = nonFields.length;
    for (int i = 0; i < count; i++) {
      nonFields[i].accept(this);
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    ErrorCode errorCode = CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS;
    InterfaceType superclassType = _resolveType(node.superclass, errorCode,
        CompileTimeErrorCode.EXTENDS_ENUM, errorCode);
    if (superclassType == null) {
      superclassType = typeProvider.objectType;
    }
    ClassElementImpl classElement = _getClassElement(node.name);
    if (classElement != null) {
      classElement.supertype = superclassType;
    }
    _resolve(classElement, node.withClause, node.implementsClause);
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    if (node.element == null) {
      ClassDeclaration classNode =
          node.getAncestor((node) => node is ClassDeclaration);
      StringBuffer buffer = new StringBuffer();
      buffer.write("The element for the constructor ");
      buffer.write(node.name == null ? "<unnamed>" : node.name.name);
      buffer.write(" in ");
      if (classNode == null) {
        buffer.write("<unknown class>");
      } else {
        buffer.write(classNode.name.name);
      }
      buffer.write(" in ");
      buffer.write(source.fullName);
      buffer.write(" was not set while trying to resolve types.");
      AnalysisEngine.instance.logger.logError(buffer.toString(),
          new CaughtException(new AnalysisException(), null));
    }
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    DartType declaredType;
    TypeAnnotation typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _typeNameResolver._getType(typeName);
    }
    LocalVariableElementImpl element = node.element as LocalVariableElementImpl;
    element.declaredType = declaredType;
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element = node.identifier.staticElement;
    if (element is ParameterElementImpl) {
      FormalParameterList parameterList = node.parameters;
      if (parameterList == null) {
        DartType type;
        TypeAnnotation typeName = node.type;
        if (typeName == null) {
          element.hasImplicitType = true;
          if (element is FieldFormalParameterElement) {
            FieldElement fieldElement =
                (element as FieldFormalParameterElement).field;
            type = fieldElement?.type;
          }
        } else {
          type = _typeNameResolver._getType(typeName);
        }
        element.declaredType = type ?? _dynamicType;
      } else {
        _setFunctionTypedParameterType(element, node.type, node.parameters);
      }
    } else {
      // TODO(brianwilkerson) Report this internal error
    }
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    if (element == null) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("The element for the top-level function ");
      buffer.write(node.name);
      buffer.write(" in ");
      buffer.write(source.fullName);
      buffer.write(" was not set while trying to resolve types.");
      AnalysisEngine.instance.logger.logError(buffer.toString(),
          new CaughtException(new AnalysisException(), null));
    }
    element.declaredReturnType = _computeReturnType(node.returnType);
    element.type = new FunctionTypeImpl(element);
    _inferSetterReturnType(element);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElementImpl element =
        node.element as FunctionTypeAliasElementImpl;
    super.visitFunctionTypeAlias(node);
    element.returnType = _computeReturnType(node.returnType);
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    Element element = node.identifier.staticElement;
    if (element is ParameterElementImpl) {
      _setFunctionTypedParameterType(element, node.returnType, node.parameters);
    } else {
      // TODO(brianwilkerson) Report this internal error
    }
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionTypeElementImpl element =
        node.type.element as GenericFunctionTypeElementImpl;
    super.visitGenericFunctionType(node);
    element.returnType =
        _computeReturnType(node.returnType) ?? DynamicTypeImpl.instance;
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    if (element == null) {
      ClassDeclaration classNode =
          node.getAncestor((node) => node is ClassDeclaration);
      StringBuffer buffer = new StringBuffer();
      buffer.write("The element for the method ");
      buffer.write(node.name.name);
      buffer.write(" in ");
      if (classNode == null) {
        buffer.write("<unknown class>");
      } else {
        buffer.write(classNode.name.name);
      }
      buffer.write(" in ");
      buffer.write(source.fullName);
      buffer.write(" was not set while trying to resolve types.");
      AnalysisEngine.instance.logger.logError(buffer.toString(),
          new CaughtException(new AnalysisException(), null));
    }

    // When the library is resynthesized, types of all of its elements are
    // already set - statically or inferred. We don't want to overwrite them.
    if (LibraryElementImpl.hasResolutionCapability(
        definingLibrary, LibraryResolutionCapability.resolvedTypeNames)) {
      return null;
    }

    element.declaredReturnType = _computeReturnType(node.returnType);
    element.type = new FunctionTypeImpl(element);
    _inferSetterReturnType(element);
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      PropertyInducingElementImpl variable =
          accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter) {
        variable.declaredType = element.returnType;
      } else if (variable.type == null) {
        List<ParameterElement> parameters = element.parameters;
        DartType type = parameters != null && parameters.length > 0
            ? parameters[0].type
            : _dynamicType;
        variable.declaredType = type;
      }
    }

    return null;
  }

  @override
  Object visitNode(AstNode node) {
    // In API mode we need to skip:
    //   - function bodies;
    //   - default values of parameters;
    //   - initializers of top-level variables.
    if (mode == TypeResolverMode.api) {
      if (node is FunctionBody) {
        return null;
      }
      if (node is DefaultFormalParameter) {
        node.parameter.accept(this);
        return null;
      }
      if (node is VariableDeclaration) {
        return null;
      }
    }

    // In local mode we need to resolve only:
    //   - function bodies;
    //   - default values of parameters;
    //   - initializers of top-level variables.
    // So, we carefully visit only nodes that are, or contain, these nodes.
    // The client may choose to start visiting any node, but we still want to
    // resolve only type names that are local.
    if (mode == TypeResolverMode.local) {
      // We are in the state of visiting all nodes.
      if (_localModeVisitAll) {
        return super.visitNode(node);
      }

      // Ensure that the name scope is ready.
      if (!_localModeScopeReady) {
        void fillNameScope(AstNode node) {
          if (node is FunctionBody ||
              node is FormalParameterList ||
              node is VariableDeclaration) {
            throw new StateError(
                'Local type resolution must start from a class or unit member.');
          }
          // Create enclosing name scopes.
          AstNode parent = node.parent;
          if (parent != null) {
            fillNameScope(parent);
          }
          // Create the name scope for the node.
          if (node is ClassDeclaration) {
            ClassElement classElement = node.element;
            nameScope = new TypeParameterScope(nameScope, classElement);
            nameScope = new ClassScope(nameScope, classElement);
          }
        }

        fillNameScope(node);
        _localModeScopeReady = true;
      }

      /**
       * Visit the given [node] and all its children.
       */
      void visitAllNodes(AstNode node) {
        if (node != null) {
          bool wasVisitAllInLocalMode = _localModeVisitAll;
          try {
            _localModeVisitAll = true;
            node.accept(this);
          } finally {
            _localModeVisitAll = wasVisitAllInLocalMode;
          }
        }
      }

      // Visit only nodes that may contain type names to resolve.
      if (node is CompilationUnit) {
        node.declarations.forEach(visitNode);
      } else if (node is ClassDeclaration) {
        node.members.forEach(visitNode);
      } else if (node is DefaultFormalParameter) {
        visitAllNodes(node.defaultValue);
      } else if (node is FieldDeclaration) {
        visitNode(node.fields);
      } else if (node is FunctionBody) {
        visitAllNodes(node);
      } else if (node is FunctionDeclaration) {
        visitNode(node.functionExpression.parameters);
        visitAllNodes(node.functionExpression.body);
      } else if (node is FormalParameterList) {
        node.parameters.accept(this);
      } else if (node is MethodDeclaration) {
        visitNode(node.parameters);
        visitAllNodes(node.body);
      } else if (node is TopLevelVariableDeclaration) {
        visitNode(node.variables);
      } else if (node is VariableDeclaration) {
        visitAllNodes(node.initializer);
      } else if (node is VariableDeclarationList) {
        node.variables.forEach(visitNode);
      }
      return null;
    }

    // The mode in which we visit all nodes.
    return super.visitNode(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);
    DartType declaredType;
    TypeAnnotation typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _typeNameResolver._getType(typeName);
    }
    Element element = node.element;
    if (element is ParameterElementImpl) {
      element.declaredType = declaredType;
    } else {
      // TODO(brianwilkerson) Report the internal error.
    }
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    _hasReferenceToSuper = true;
    return super.visitSuperExpression(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    super.visitTypeName(node);
    _typeNameResolver.nameScope = this.nameScope;
    _typeNameResolver.resolveTypeName(node);
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    super.visitTypeParameter(node);
    AstNode parent2 = node.parent?.parent;
    if (parent2 is ClassDeclaration ||
        parent2 is ClassTypeAlias ||
        parent2 is FunctionTypeAlias) {
      // Bounds of parameters of classes and function type aliases are
      // already resolved.
    } else {
      TypeAnnotation bound = node.bound;
      if (bound != null) {
        TypeParameterElementImpl typeParameter =
            node.name.staticElement as TypeParameterElementImpl;
        if (typeParameter != null) {
          typeParameter.bound = bound.type;
        }
      }
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    var variableList = node.parent as VariableDeclarationList;
    // When the library is resynthesized, the types of field elements are
    // already set - statically or inferred. We don't want to overwrite them.
    if (variableList.parent is FieldDeclaration &&
        LibraryElementImpl.hasResolutionCapability(
            definingLibrary, LibraryResolutionCapability.resolvedTypeNames)) {
      return null;
    }
    // Resolve the type.
    DartType declaredType;
    TypeAnnotation typeName = variableList.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _typeNameResolver._getType(typeName);
    }
    Element element = node.name.staticElement;
    if (element is VariableElementImpl) {
      element.declaredType = declaredType;
    }
    return null;
  }

  /**
   * Given the [returnType] of a function, compute the return type of the
   * function.
   */
  DartType _computeReturnType(TypeAnnotation returnType) {
    if (returnType == null) {
      return _dynamicType;
    } else {
      return _typeNameResolver._getType(returnType);
    }
  }

  /**
   * Return the class element that represents the class whose name was provided.
   *
   * @param identifier the name from the declaration of a class
   * @return the class element that represents the class
   */
  ClassElementImpl _getClassElement(SimpleIdentifier identifier) {
    // TODO(brianwilkerson) Seems like we should be using
    // ClassDeclaration.getElement().
    if (identifier == null) {
      // TODO(brianwilkerson) Report this
      // Internal error: We should never build a class declaration without a
      // name.
      return null;
    }
    Element element = identifier.staticElement;
    if (element is ClassElementImpl) {
      return element;
    }
    // TODO(brianwilkerson) Report this
    // Internal error: Failed to create an element for a class declaration.
    return null;
  }

  /**
   * Return an array containing all of the elements associated with the parameters in the given
   * list.
   *
   * @param parameterList the list of parameters whose elements are to be returned
   * @return the elements associated with the parameters
   */
  List<ParameterElement> _getElements(FormalParameterList parameterList) {
    List<ParameterElement> elements = new List<ParameterElement>();
    for (FormalParameter parameter in parameterList.parameters) {
      ParameterElement element =
          parameter.identifier.staticElement as ParameterElement;
      // TODO(brianwilkerson) Understand why the element would be null.
      if (element != null) {
        elements.add(element);
      }
    }
    return elements;
  }

  /**
   * In strong mode we infer "void" as the setter return type (as void is the
   * only legal return type for a setter). This allows us to give better
   * errors later if an invalid type is returned.
   */
  void _inferSetterReturnType(ExecutableElementImpl element) {
    if (_strongMode &&
        element is PropertyAccessorElementImpl &&
        element.isSetter &&
        element.hasImplicitReturnType) {
      element.declaredReturnType = VoidTypeImpl.instance;
    }
  }

  /**
   * Record that the static type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the static type of the node
   */
  Object _recordType(Expression expression, DartType type) {
    if (type == null) {
      expression.staticType = _dynamicType;
    } else {
      expression.staticType = type;
    }
    return null;
  }

  /**
   * Resolve the types in the given [withClause] and [implementsClause] and
   * associate those types with the given [classElement].
   */
  void _resolve(ClassElementImpl classElement, WithClause withClause,
      ImplementsClause implementsClause) {
    if (withClause != null) {
      List<InterfaceType> mixinTypes = _resolveTypes(
          withClause.mixinTypes,
          CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
          CompileTimeErrorCode.MIXIN_OF_ENUM,
          CompileTimeErrorCode.MIXIN_OF_NON_CLASS);
      if (classElement != null) {
        classElement.mixins = mixinTypes;
      }
    }
    if (implementsClause != null) {
      NodeList<TypeName> interfaces = implementsClause.interfaces;
      List<InterfaceType> interfaceTypes = _resolveTypes(
          interfaces,
          CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
          CompileTimeErrorCode.IMPLEMENTS_ENUM,
          CompileTimeErrorCode.IMPLEMENTS_DYNAMIC);
      if (classElement != null) {
        classElement.interfaces = interfaceTypes;
      }
      // TODO(brianwilkerson) Move the following checks to ErrorVerifier.
      int count = interfaces.length;
      List<bool> detectedRepeatOnIndex = new List<bool>.filled(count, false);
      for (int i = 0; i < detectedRepeatOnIndex.length; i++) {
        detectedRepeatOnIndex[i] = false;
      }
      for (int i = 0; i < count; i++) {
        TypeName typeName = interfaces[i];
        if (!detectedRepeatOnIndex[i]) {
          Element element = typeName.name.staticElement;
          for (int j = i + 1; j < count; j++) {
            TypeName typeName2 = interfaces[j];
            Identifier identifier2 = typeName2.name;
            String name2 = identifier2.name;
            Element element2 = identifier2.staticElement;
            if (element != null && element == element2) {
              detectedRepeatOnIndex[j] = true;
              errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.IMPLEMENTS_REPEATED, typeName2, [name2]);
            }
          }
        }
      }
    }
  }

  /**
   * Return the type specified by the given name.
   *
   * @param typeName the type name specifying the type to be returned
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   *          a type
   * @param enumTypeError the error to produce if the type name is defined to be an enum
   * @param dynamicTypeError the error to produce if the type name is "dynamic"
   * @return the type specified by the type name
   */
  InterfaceType _resolveType(TypeName typeName, ErrorCode nonTypeError,
      ErrorCode enumTypeError, ErrorCode dynamicTypeError) {
    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element != null && element.isEnum) {
        errorReporter.reportErrorForNode(enumTypeError, typeName);
        return null;
      }
      return type;
    }
    // If the type is not an InterfaceType, then visitTypeName() sets the type
    // to be a DynamicTypeImpl
    Identifier name = typeName.name;
    if (name.name == Keyword.DYNAMIC.lexeme) {
      errorReporter.reportErrorForNode(dynamicTypeError, name, [name.name]);
    } else if (!nameScope.shouldIgnoreUndefined(name)) {
      errorReporter.reportErrorForNode(nonTypeError, name, [name.name]);
    }
    return null;
  }

  /**
   * Resolve the types in the given list of type names.
   *
   * @param typeNames the type names to be resolved
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   *          a type
   * @param enumTypeError the error to produce if the type name is defined to be an enum
   * @param dynamicTypeError the error to produce if the type name is "dynamic"
   * @return an array containing all of the types that were resolved.
   */
  List<InterfaceType> _resolveTypes(
      NodeList<TypeName> typeNames,
      ErrorCode nonTypeError,
      ErrorCode enumTypeError,
      ErrorCode dynamicTypeError) {
    List<InterfaceType> types = new List<InterfaceType>();
    for (TypeName typeName in typeNames) {
      InterfaceType type =
          _resolveType(typeName, nonTypeError, enumTypeError, dynamicTypeError);
      if (type != null) {
        types.add(type);
      }
    }
    return types;
  }

  /**
   * Given a parameter [element], create a function type based on the given
   * [returnType] and [parameterList] and associate the created type with the
   * element.
   */
  void _setFunctionTypedParameterType(ParameterElementImpl element,
      TypeAnnotation returnType, FormalParameterList parameterList) {
    List<ParameterElement> parameters = _getElements(parameterList);
    FunctionElementImpl functionElement = new FunctionElementImpl.forNode(null);
    functionElement.isSynthetic = true;
    functionElement.shareParameters(parameters);
    functionElement.declaredReturnType = _computeReturnType(returnType);
    functionElement.enclosingElement = element;
    functionElement.shareTypeParameters(element.typeParameters);
    element.type = new FunctionTypeImpl(functionElement);
    functionElement.type = element.type;
  }
}

/**
 * Instances of the class [UnusedLocalElementsVerifier] traverse an AST
 * looking for cases of [HintCode.UNUSED_ELEMENT], [HintCode.UNUSED_FIELD],
 * [HintCode.UNUSED_LOCAL_VARIABLE], etc.
 */
class UnusedLocalElementsVerifier extends RecursiveAstVisitor {
  /**
   * The error listener to which errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The elements know to be used.
   */
  final UsedLocalElements _usedElements;

  /**
   * Create a new instance of the [UnusedLocalElementsVerifier].
   */
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
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
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
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
  }

  _visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
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
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
  }

  _visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
  }
}

/**
 * A container with information about used imports prefixes and used imported
 * elements.
 */
class UsedImportedElements {
  /**
   * The map of referenced [PrefixElement]s and the [Element]s that they prefix.
   */
  final Map<PrefixElement, List<Element>> prefixMap =
      new HashMap<PrefixElement, List<Element>>();

  /**
   * The set of referenced top-level [Element]s.
   */
  final Set<Element> elements = new HashSet<Element>();
}

/**
 * A container with sets of used [Element]s.
 * All these elements are defined in a single compilation unit or a library.
 */
class UsedLocalElements {
  /**
   * Resolved, locally defined elements that are used or potentially can be
   * used.
   */
  final HashSet<Element> elements = new HashSet<Element>();

  /**
   * [LocalVariableElement]s that represent exceptions in [CatchClause]s.
   */
  final HashSet<LocalVariableElement> catchExceptionElements =
      new HashSet<LocalVariableElement>();

  /**
   * [LocalVariableElement]s that represent stack traces in [CatchClause]s.
   */
  final HashSet<LocalVariableElement> catchStackTraceElements =
      new HashSet<LocalVariableElement>();

  /**
   * Names of resolved or unresolved class members that are referenced in the
   * library.
   */
  final HashSet<String> members = new HashSet<String>();

  /**
   * Names of resolved or unresolved class members that are read in the
   * library.
   */
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

/**
 * Instances of the class `VariableResolverVisitor` are used to resolve
 * [SimpleIdentifier]s to local variables and formal parameters.
 */
class VariableResolverVisitor extends ScopedVisitor {
  /**
   * The method or function that we are currently visiting, or `null` if we are not inside a
   * method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * Information about local variables in the enclosing function or method.
   */
  LocalVariableInfo _localVariableInfo;

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * [definingLibrary] is the element for the library containing the node being
   * visited.
   * [source] is the source representing the compilation unit containing the
   * node being visited
   * [typeProvider] is the object used to access the types from the core
   * library.
   * [errorListener] is the error listener that will be informed of any errors
   * that are found during resolution.
   * [nameScope] is the scope used to resolve identifiers in the node that will
   * first be visited.  If `null` or unspecified, a new [LibraryScope] will be
   * created based on [definingLibrary] and [typeProvider].
   */
  VariableResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope);

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    assert(_localVariableInfo != null);
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    LocalVariableInfo outerLocalVariableInfo = _localVariableInfo;
    try {
      _localVariableInfo ??= new LocalVariableInfo();
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.element;
      return super.visitConstructorDeclaration(node);
    } finally {
      _localVariableInfo = outerLocalVariableInfo;
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitExportDirective(ExportDirective node) => null;

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    assert(_localVariableInfo != null);
    return super.visitExpressionFunctionBody(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    LocalVariableInfo outerLocalVariableInfo = _localVariableInfo;
    try {
      _localVariableInfo ??= new LocalVariableInfo();
      (node.functionExpression.body as FunctionBodyImpl).localVariableInfo =
          _localVariableInfo;
      _enclosingFunction = node.element;
      return super.visitFunctionDeclaration(node);
    } finally {
      _localVariableInfo = outerLocalVariableInfo;
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      LocalVariableInfo outerLocalVariableInfo = _localVariableInfo;
      try {
        _localVariableInfo ??= new LocalVariableInfo();
        (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
        _enclosingFunction = node.element;
        return super.visitFunctionExpression(node);
      } finally {
        _localVariableInfo = outerLocalVariableInfo;
        _enclosingFunction = outerFunction;
      }
    } else {
      return super.visitFunctionExpression(node);
    }
  }

  @override
  Object visitImportDirective(ImportDirective node) => null;

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    LocalVariableInfo outerLocalVariableInfo = _localVariableInfo;
    try {
      _localVariableInfo ??= new LocalVariableInfo();
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.element;
      return super.visitMethodDeclaration(node);
    } finally {
      _localVariableInfo = outerLocalVariableInfo;
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if already resolved - declaration or type.
    if (node.inDeclarationContext()) {
      return null;
    }
    // Ignore if it cannot be a reference to a local variable.
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter) {
      return null;
    } else if (parent is ConstructorDeclaration && parent.returnType == node) {
      return null;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return null;
    }
    // Ignore if qualified.
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return null;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      return null;
    }
    if (parent is MethodInvocation &&
        identical(parent.methodName, node) &&
        parent.realTarget != null) {
      return null;
    }
    if (parent is ConstructorName) {
      return null;
    }
    if (parent is Label) {
      return null;
    }
    // Prepare VariableElement.
    Element element = nameScope.lookup(node, definingLibrary);
    if (element is! VariableElement) {
      return null;
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
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    return null;
  }
}

class _ConstantVerifier_validateInitializerExpression extends ConstantVisitor {
  final ConstantVerifier verifier;

  List<ParameterElement> parameterElements;

  TypeSystem _typeSystem;

  _ConstantVerifier_validateInitializerExpression(
      TypeProvider typeProvider,
      ErrorReporter errorReporter,
      this.verifier,
      this.parameterElements,
      DeclaredVariables declaredVariables,
      {TypeSystem typeSystem})
      : _typeSystem = typeSystem ?? new TypeSystemImpl(typeProvider),
        super(
            new ConstantEvaluationEngine(typeProvider, declaredVariables,
                typeSystem: typeSystem),
            errorReporter);

  @override
  DartObjectImpl visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    int length = parameterElements.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameterElement = parameterElements[i];
      if (identical(parameterElement, element) && parameterElement != null) {
        DartType type = parameterElement.type;
        if (type != null) {
          if (type.isDynamic) {
            return new DartObjectImpl(
                verifier._typeProvider.objectType, DynamicState.DYNAMIC_STATE);
          } else if (_typeSystem.isSubtypeOf(type, verifier._boolType)) {
            return new DartObjectImpl(
                verifier._typeProvider.boolType, BoolState.UNKNOWN_VALUE);
          } else if (_typeSystem.isSubtypeOf(
              type, verifier._typeProvider.doubleType)) {
            return new DartObjectImpl(
                verifier._typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
          } else if (_typeSystem.isSubtypeOf(type, verifier._intType)) {
            return new DartObjectImpl(
                verifier._typeProvider.intType, IntState.UNKNOWN_VALUE);
          } else if (_typeSystem.isSubtypeOf(type, verifier._numType)) {
            return new DartObjectImpl(
                verifier._typeProvider.numType, NumState.UNKNOWN_VALUE);
          } else if (_typeSystem.isSubtypeOf(type, verifier._stringType)) {
            return new DartObjectImpl(
                verifier._typeProvider.stringType, StringState.UNKNOWN_VALUE);
          }
          //
          // We don't test for other types of objects (such as List, Map,
          // Function or Type) because there are no operations allowed on such
          // types other than '==' and '!=', which means that we don't need to
          // know the type when there is no specific data about the state of
          // such objects.
          //
        }
        return new DartObjectImpl(
            type is InterfaceType ? type : verifier._typeProvider.objectType,
            GenericState.UNKNOWN_VALUE);
      }
    }
    return super.visitSimpleIdentifier(node);
  }
}

class _ResolverVisitor_isVariableAccessedInClosure
    extends RecursiveAstVisitor<Object> {
  final Element variable;

  bool result = false;

  bool _inClosure = false;

  _ResolverVisitor_isVariableAccessedInClosure(this.variable);

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    bool inClosure = this._inClosure;
    try {
      this._inClosure = true;
      return super.visitFunctionExpression(node);
    } finally {
      this._inClosure = inClosure;
    }
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (result) {
      return null;
    }
    if (_inClosure && identical(node.staticElement, variable)) {
      result = true;
    }
    return null;
  }
}

class _ResolverVisitor_isVariablePotentiallyMutatedIn
    extends RecursiveAstVisitor<Object> {
  final Element variable;

  bool result = false;

  _ResolverVisitor_isVariablePotentiallyMutatedIn(this.variable);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (result) {
      return null;
    }
    if (identical(node.staticElement, variable)) {
      if (node.inSetterContext()) {
        result = true;
      }
    }
    return null;
  }
}

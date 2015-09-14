// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.resolver;

import 'dart:collection';

import 'ast.dart';
import 'constant.dart';
import 'element.dart';
import 'element_resolver.dart';
import 'engine.dart';
import 'error.dart';
import 'error_verifier.dart';
import 'html.dart' as ht;
import 'java_core.dart';
import 'java_engine.dart';
import 'scanner.dart' as sc;
import 'sdk.dart' show DartSdk, SdkLibrary;
import 'source.dart';
import 'static_type_analyzer.dart';
import 'utilities_dart.dart';

/**
 * Callback signature used by ImplicitConstructorBuilder to register
 * computations to be performed, and their dependencies.  A call to this
 * callback indicates that [computation] may be used to compute implicit
 * constructors for [classElement], but that the computation may not be invoked
 * until after implicit constructors have been built for [superclassElement].
 */
typedef void ImplicitConstructorBuilderCallback(ClassElement classElement,
    ClassElement superclassElement, void computation());

typedef LibraryResolver LibraryResolverFactory(AnalysisContext context);

typedef ResolverVisitor ResolverVisitorFactory(
    Library library, Source source, TypeProvider typeProvider);

typedef StaticTypeAnalyzer StaticTypeAnalyzerFactory(ResolverVisitor visitor);

typedef TypeResolverVisitor TypeResolverVisitorFactory(
    Library library, Source source, TypeProvider typeProvider);

typedef void VoidFunction();

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
  ClassElement _enclosingClass;

  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * The type Future<Null>, which is needed for determining whether it is safe
   * to have a bare "return;" in an async method.
   */
  final InterfaceType _futureNullType;

  /**
   * Create a new instance of the [BestPracticesVerifier].
   *
   * @param errorReporter the error reporter
   */
  BestPracticesVerifier(this._errorReporter, TypeProvider typeProvider)
      : _futureNullType = typeProvider.futureNullType;

  @override
  Object visitArgumentList(ArgumentList node) {
    _checkForArgumentTypesNotAssignableInList(node);
    return super.visitArgumentList(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _checkForUnnecessaryCast(node);
    return super.visitAsExpression(node);
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operatorType = node.operator.type;
    if (operatorType == sc.TokenType.EQ) {
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
    ClassElement outerClass = _enclosingClass;
    try {
      _enclosingClass = node.element;
      // Commented out until we decide that we want this hint in the analyzer
      //    checkForOverrideEqualsButNotHashCode(node);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _checkForMissingReturn(node.returnType, node.functionExpression.body);
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    _checkForDeprecatedMemberUse(node.uriElement, node);
    ImportElement importElement = node.element;
    if (importElement != null) {
      if (importElement.isDeferred) {
        _checkForLoadLibraryFunction(node, importElement);
      }
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
    // This was determined to not be a good hint, see: dartbug.com/16029
    //checkForOverridingPrivateMember(node);
    _checkForMissingReturn(node.returnType, node.body);
    return super.visitMethodDeclaration(node);
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
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForDeprecatedMemberUseAtIdentifier(node);
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
    TypeName typeName = node.type;
    DartType lhsType = expression.staticType;
    DartType rhsType = typeName.type;
    if (lhsType == null || rhsType == null) {
      return false;
    }
    String rhsNameStr = typeName.name.name;
    // if x is dynamic
    if (rhsType.isDynamic && rhsNameStr == sc.Keyword.DYNAMIC.syntax) {
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
    LibraryElement libraryElement =
        rhsElement != null ? rhsElement.library : null;
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
      if (!actualStaticType.isAssignableTo(expectedStaticType)) {
        // A warning was created in the ErrorVerifier, return false, don't
        // create a hint when a warning has already been created.
        return false;
      }
    }
    //
    // Hint case: test propagated type information
    //
    // Compute the best types to use.
    DartType expectedBestType = expectedPropagatedType != null
        ? expectedPropagatedType
        : expectedStaticType;
    DartType actualBestType =
        actualPropagatedType != null ? actualPropagatedType : actualStaticType;
    if (actualBestType != null && expectedBestType != null) {
      if (!actualBestType.isAssignableTo(expectedBestType)) {
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
    DartType staticParameterType =
        staticParameterElement == null ? null : staticParameterElement.type;
    ParameterElement propagatedParameterElement =
        argument.propagatedParameterElement;
    DartType propagatedParameterType = propagatedParameterElement == null
        ? null
        : propagatedParameterElement.type;
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
   * Given some [Element], look at the associated metadata and report the use of the member if
   * it is declared as deprecated.
   *
   * @param element some element to check for deprecated use of
   * @param node the node use for the location of the error
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.DEPRECATED_MEMBER_USE].
   */
  bool _checkForDeprecatedMemberUse(Element element, AstNode node) {
    if (element != null && element.isDeprecated) {
      String displayName = element.displayName;
      if (element is ConstructorElement) {
        // TODO(jwren) We should modify ConstructorElement.getDisplayName(),
        // or have the logic centralized elsewhere, instead of doing this logic
        // here.
        ConstructorElement constructorElement = element;
        displayName = constructorElement.enclosingElement.displayName;
        if (!constructorElement.displayName.isEmpty) {
          displayName = "$displayName.${constructorElement.displayName}";
        }
      }
      _errorReporter.reportErrorForNode(
          HintCode.DEPRECATED_MEMBER_USE, node, [displayName]);
      return true;
    }
    return false;
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
  bool _checkForDeprecatedMemberUseAtIdentifier(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return false;
    }
    AstNode parent = identifier.parent;
    if ((parent is ConstructorName && identical(identifier, parent.name)) ||
        (parent is SuperConstructorInvocation &&
            identical(identifier, parent.constructorName)) ||
        parent is HideCombinator) {
      return false;
    }
    return _checkForDeprecatedMemberUse(identifier.bestElement, identifier);
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
    if (node.operator.type != sc.TokenType.SLASH) {
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
    if (node.parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesizedExpression =
          _wrapParenthesizedExpression(node.parent as ParenthesizedExpression);
      if (parenthesizedExpression.parent is MethodInvocation) {
        MethodInvocation methodInvocation =
            parenthesizedExpression.parent as MethodInvocation;
        if (_TO_INT_METHOD_NAME == methodInvocation.methodName.name &&
            methodInvocation.argumentList.arguments.isEmpty) {
          _errorReporter.reportErrorForNode(
              HintCode.DIVISION_OPTIMIZATION, methodInvocation);
          return true;
        }
      }
    }
    return false;
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
    if (!staticRightType.isAssignableTo(leftType)) {
      // The warning was generated on this rhs
      return false;
    }
    // Test for, and then generate the hint
    DartType bestRightType = rhs.bestType;
    if (leftType != null && bestRightType != null) {
      if (!bestRightType.isAssignableTo(leftType)) {
        _errorReporter.reportTypeErrorForNode(
            HintCode.INVALID_ASSIGNMENT, rhs, [bestRightType, leftType]);
        return true;
      }
    }
    return false;
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
  bool _checkForMissingReturn(TypeName returnType, FunctionBody body) {
    // Check that the method or function has a return type, and a function body
    if (returnType == null || body == null) {
      return false;
    }
    // Check that the body is a BlockFunctionBody
    if (body is! BlockFunctionBody) {
      return false;
    }
    // Generators are never required to have a return statement.
    if (body.isGenerator) {
      return false;
    }
    // Check that the type is resolvable, and is not "void"
    DartType returnTypeType = returnType.type;
    if (returnTypeType == null || returnTypeType.isVoid) {
      return false;
    }
    // For async, give no hint if Future<Null> is assignable to the return
    // type.
    if (body.isAsynchronous && _futureNullType.isAssignableTo(returnTypeType)) {
      return false;
    }
    // Check the block for a return statement, if not, create the hint
    BlockFunctionBody blockFunctionBody = body as BlockFunctionBody;
    if (!ExitDetector.exits(blockFunctionBody)) {
      _errorReporter.reportErrorForNode(
          HintCode.MISSING_RETURN, returnType, [returnTypeType.displayName]);
      return true;
    }
    return false;
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
   * Check for situations where the result of a method or function is used, when it returns 'void'.
   *
   * TODO(jwren) Many other situations of use could be covered. We currently cover the cases var x =
   * m() and x = m(), but we could also cover cases such as m().x, m()[k], a + m(), f(m()), return
   * m().
   *
   * @param node expression on the RHS of some assignment
   * @return `true` if and only if a hint code is generated on the passed node
   * See [HintCode.USE_OF_VOID_RESULT].
   */
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null || expression is! MethodInvocation) {
      return false;
    }
    MethodInvocation methodInvocation = expression as MethodInvocation;
    if (identical(methodInvocation.staticType, VoidTypeImpl.instance)) {
      SimpleIdentifier methodName = methodInvocation.methodName;
      _errorReporter.reportErrorForNode(
          HintCode.USE_OF_VOID_RESULT, methodName, [methodName.name]);
      return true;
    }
    return false;
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
    if (parenthesizedExpression.parent is ParenthesizedExpression) {
      return _wrapParenthesizedExpression(
          parenthesizedExpression.parent as ParenthesizedExpression);
    }
    return parenthesizedExpression;
  }
}

/**
 * Instances of the class `ClassScope` implement the scope defined by a class.
 */
class ClassScope extends EnclosedScope {
  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param typeElement the element representing the type represented by this scope
   */
  ClassScope(Scope enclosingScope, ClassElement typeElement)
      : super(enclosingScope) {
    if (typeElement == null) {
      throw new IllegalArgumentException("class element cannot be null");
    }
    _defineMembers(typeElement);
  }

  @override
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PropertyAccessorElement && duplicate is MethodElement) {
      if (existing.nameOffset < duplicate.nameOffset) {
        return new AnalysisError(
            duplicate.source,
            duplicate.nameOffset,
            duplicate.displayName.length,
            CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME,
            [existing.displayName]);
      } else {
        return new AnalysisError(
            existing.source,
            existing.nameOffset,
            existing.displayName.length,
            CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME,
            [existing.displayName]);
      }
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Define the instance members defined by the class.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void _defineMembers(ClassElement typeElement) {
    for (PropertyAccessorElement accessor in typeElement.accessors) {
      define(accessor);
    }
    for (MethodElement method in typeElement.methods) {
      define(method);
    }
  }
}

/**
 * A `CompilationUnitBuilder` builds an element model for a single compilation
 * unit.
 */
class CompilationUnitBuilder {
  /**
   * Build the compilation unit element for the given [source] based on the
   * compilation [unit] associated with the source. Throw an AnalysisException
   * if the element could not be built.  [librarySource] is the source for the
   * containing library.
   */
  CompilationUnitElementImpl buildCompilationUnit(
      Source source, CompilationUnit unit, Source librarySource) {
    return PerformanceStatistics.resolve.makeCurrentWhile(() {
      if (unit == null) {
        return null;
      }
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder = new ElementBuilder(holder);
      unit.accept(builder);
      CompilationUnitElementImpl element =
          new CompilationUnitElementImpl(source.shortName);
      element.accessors = holder.accessors;
      element.enums = holder.enums;
      element.functions = holder.functions;
      element.source = source;
      element.librarySource = librarySource;
      element.typeAliases = holder.typeAliases;
      element.types = holder.types;
      element.topLevelVariables = holder.topLevelVariables;
      unit.element = element;
      holder.validate();
      return element;
    });
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
  ConstantVerifier(this._errorReporter, this._currentLibrary,
      this._typeProvider, this.declaredVariables) {
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
      ConstructorElement constructorElement = element;
      // should 'const' constructor
      if (!constructorElement.isConst) {
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
            new ConstantEvaluationEngine(_typeProvider, declaredVariables);
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
          _reportErrorIfFromDeferredLibrary(element,
              CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY);
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
          _reportErrorIfFromDeferredLibrary(valueExpression,
              CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY);
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
                CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
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
            new ConstantEvaluationEngine(_typeProvider, declaredVariables),
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
      for (Expression key in invalidKeys) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.EQUAL_KEYS_IN_MAP, key);
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
        SwitchCase switchCase = switchMember;
        Expression expression = switchCase.expression;
        DartObjectImpl caseResult = _validate(
            expression, CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION);
        if (caseResult != null) {
          _reportErrorIfFromDeferredLibrary(expression,
              CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY);
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
      _reportErrorIfFromDeferredLibrary(initializer,
          CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY);
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
    if (element is! ClassElement) {
      return false;
    }
    ClassElement classElement = element as ClassElement;
    // lookup for ==
    MethodElement method =
        classElement.lookUpConcreteMethod("==", _currentLibrary);
    if (method == null || method.enclosingElement.type.isObject) {
      return false;
    }
    // there is == that we don't like
    return true;
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
    for (AnalysisError data in errors) {
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
              CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH) ||
          identical(dataErrorCode,
              CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH) ||
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
        new ConstantEvaluationEngine(_typeProvider, declaredVariables),
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
      if (argument is NamedExpression) {
        argument = (argument as NamedExpression).expression;
      }
      _validate(
          argument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
    }
  }

  /**
   * Validates that the expressions of the given initializers (of a constant constructor) are all
   * compile time constants.
   *
   * @param constructor the constant constructor declaration to validate
   */
  void _validateConstructorInitializers(ConstructorDeclaration constructor) {
    List<ParameterElement> parameterElements =
        constructor.parameters.parameterElements;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer fieldInitializer = initializer;
        _validateInitializerExpression(
            parameterElements, fieldInitializer.expression);
      }
      if (initializer is RedirectingConstructorInvocation) {
        RedirectingConstructorInvocation invocation = initializer;
        _validateInitializerInvocationArguments(
            parameterElements, invocation.argumentList);
      }
      if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation invocation = initializer;
        _validateInitializerInvocationArguments(
            parameterElements, invocation.argumentList);
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
        DefaultFormalParameter defaultParameter = parameter;
        Expression defaultValue = defaultParameter.defaultValue;
        DartObjectImpl result;
        if (defaultValue == null) {
          result =
              new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
        } else {
          result = _validate(
              defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (result != null) {
            _reportErrorIfFromDeferredLibrary(defaultValue,
                CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY);
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
      if (member is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = member;
        if (!fieldDeclaration.isStatic) {
          for (VariableDeclaration variableDeclaration
              in fieldDeclaration.fields.variables) {
            Expression initializer = variableDeclaration.initializer;
            if (initializer != null) {
              // Ignore any errors produced during validation--if the constant
              // can't be eavluated we'll just report a single error.
              AnalysisErrorListener errorListener =
                  AnalysisErrorListener.NULL_LISTENER;
              ErrorReporter subErrorReporter =
                  new ErrorReporter(errorListener, _errorReporter.source);
              DartObjectImpl result = initializer.accept(new ConstantVisitor(
                  new ConstantEvaluationEngine(
                      _typeProvider, declaredVariables),
                  subErrorReporter));
              if (result == null) {
                _errorReporter.reportErrorForNode(
                    CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
                    errorSite,
                    [variableDeclaration.name.name]);
              }
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
            subErrorReporter, this, parameterElements, declaredVariables));
    _reportErrors(errorListener.errors,
        CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER);
    if (result != null) {
      _reportErrorIfFromDeferredLibrary(expression,
          CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY);
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
    TypeName typeName = node.type;
    DartType type = typeName.type;
    if (type != null && type.element != null) {
      Element element = type.element;
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
   * Create a new instance of the [DeadCodeVerifier].
   *
   * @param errorReporter the error reporter
   */
  DeadCodeVerifier(this._errorReporter);

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    bool isAmpAmp = operator.type == sc.TokenType.AMPERSAND_AMPERSAND;
    bool isBarBar = operator.type == sc.TokenType.BAR_BAR;
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!_isDebugConstant(lhsCondition)) {
        EvaluationResultImpl lhsResult = _getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          if (lhsResult.value.isTrue && isBarBar) {
            // report error on else block: true || !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // only visit the LHS:
            _safelyVisit(lhsCondition);
            return null;
          } else if (lhsResult.value.isFalse && isAmpAmp) {
            // report error on if block: false && !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // only visit the LHS:
            _safelyVisit(lhsCondition);
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
//                safelyVisit(rhsCondition);
//                return null;
//              } else if (rhsResult == ValidResult.RESULT_FALSE && isAmpAmp) {
//                // report error on if block: !e! && false
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                safelyVisit(rhsCondition);
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
    _safelyVisit(conditionExpression);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.isTrue) {
          // report error on else block: true ? 1 : !2!
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.elseExpression);
          _safelyVisit(node.thenExpression);
          return null;
        } else {
          // report error on if block: false ? !1! : 2
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenExpression);
          _safelyVisit(node.elseExpression);
          return null;
        }
      }
    }
    return super.visitConditionalExpression(node);
  }

  @override
  Object visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    _safelyVisit(conditionExpression);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.isTrue) {
          // report error on else block: if(true) {} else {!}
          Statement elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, elseStatement);
            _safelyVisit(node.thenStatement);
            return null;
          }
        } else {
          // report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenStatement);
          _safelyVisit(node.elseStatement);
          return null;
        }
      }
    }
    return super.visitIfStatement(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _checkForDeadStatementsInNodeList(node.statements);
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _checkForDeadStatementsInNodeList(node.statements);
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitTryStatement(TryStatement node) {
    _safelyVisit(node.body);
    _safelyVisit(node.finallyBlock);
    NodeList<CatchClause> catchClauses = node.catchClauses;
    int numOfCatchClauses = catchClauses.length;
    List<DartType> visitedTypes = new List<DartType>();
    for (int i = 0; i < numOfCatchClauses; i++) {
      CatchClause catchClause = catchClauses[i];
      if (catchClause.onKeyword != null) {
        // on-catch clause found, verify that the exception type is not a
        // subtype of a previous on-catch exception type
        TypeName typeName = catchClause.exceptionType;
        if (typeName != null && typeName.type != null) {
          DartType currentType = typeName.type;
          if (currentType.isObject) {
            // Found catch clause clause that has Object as an exception type,
            // this is equivalent to having a catch clause that doesn't have an
            // exception type, visit the block, but generate an error on any
            // following catch clauses (and don't visit them).
            _safelyVisit(catchClause);
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
          for (DartType type in visitedTypes) {
            if (currentType.isSubtypeOf(type)) {
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
        _safelyVisit(catchClause);
      } else {
        // Found catch clause clause that doesn't have an exception type,
        // visit the block, but generate an error on any following catch clauses
        // (and don't visit them).
        _safelyVisit(catchClause);
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
    _safelyVisit(conditionExpression);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.isFalse) {
          // report error on if block: while (false) {!}
          _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, node.body);
          return null;
        }
      }
    }
    _safelyVisit(node.body);
    return null;
  }

  /**
   * Given some [NodeList] of [Statement]s, from either a [Block] or
   * [SwitchMember], this loops through the list in reverse order searching for statements
   * after a return, unlabeled break or unlabeled continue statement to mark them as dead code.
   *
   * @param statements some ordered list of statements in a [Block] or [SwitchMember]
   */
  void _checkForDeadStatementsInNodeList(NodeList<Statement> statements) {
    int size = statements.length;
    for (int i = 0; i < size; i++) {
      Statement currentStatement = statements[i];
      _safelyVisit(currentStatement);
      bool returnOrBreakingStatement = currentStatement is ReturnStatement ||
          (currentStatement is BreakStatement &&
              currentStatement.label == null) ||
          (currentStatement is ContinueStatement &&
              currentStatement.label == null);
      if (returnOrBreakingStatement && i != size - 1) {
        Statement nextStatement = statements[i + 1];
        Statement lastStatement = statements[size - 1];
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
      Identifier identifier = expression;
      element = identifier.staticElement;
    } else if (expression is PropertyAccess) {
      PropertyAccess propertyAccess = expression;
      element = propertyAccess.propertyName.staticElement;
    }
    if (element is PropertyAccessorElement) {
      PropertyInducingElement variable = element.variable;
      return variable != null && variable.isConst;
    }
    return false;
  }

  /**
   * If the given node is not `null`, visit this instance of the dead code verifier.
   *
   * @param node the node to be visited
   */
  void _safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}

/**
 * Instances of the class `DeclarationResolver` are used to resolve declarations in an AST
 * structure to already built elements.
 */
class DeclarationResolver extends RecursiveAstVisitor<Object> {
  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The function type alias containing the AST nodes being visited, or `null` if we are not
   * in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function containing the AST nodes being visited, or `null` if we are not in
   * the scope of a method or function.
   */
  ExecutableElement _enclosingExecutable;

  /**
   * The parameter containing the AST nodes being visited, or `null` if we are not in the
   * scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  /**
   * Resolve the declarations within the given compilation unit to the elements rooted at the given
   * element.
   *
   * @param unit the compilation unit to be resolved
   * @param element the root of the element model used to resolve the AST nodes
   */
  void resolve(CompilationUnit unit, CompilationUnitElement element) {
    _enclosingUnit = element;
    unit.element = element;
    unit.accept(this);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      List<LocalVariableElement> localVariables =
          _enclosingExecutable.localVariables;
      _findIdentifier(localVariables, exceptionParameter);
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        _findIdentifier(localVariables, stackTraceParameter);
      }
    }
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = _findIdentifier(_enclosingUnit.types, className);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = _findIdentifier(_enclosingUnit.types, className);
      return super.visitClassTypeAlias(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier constructorName = node.name;
      if (constructorName == null) {
        _enclosingExecutable = _enclosingClass.unnamedConstructor;
      } else {
        _enclosingExecutable =
            _enclosingClass.getNamedConstructor(constructorName.name);
        constructorName.staticElement = _enclosingExecutable;
      }
      node.element = _enclosingExecutable as ConstructorElement;
      return super.visitConstructorDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    _findIdentifier(_enclosingExecutable.localVariables, variableName);
    return super.visitDeclaredIdentifier(node);
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElement element = _getElementForParameter(node, parameterName);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
          // TODO(brianwilkerson) Report this internal error.
        } else {
          _enclosingExecutable = element.initializer;
        }
        defaultValue.accept(this);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    ParameterElement outerParameter = _enclosingParameter;
    try {
      _enclosingParameter = element;
      return super.visitDefaultFormalParameter(node);
    } finally {
      _enclosingParameter = outerParameter;
    }
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    ClassElement enclosingEnum =
        _findIdentifier(_enclosingUnit.enums, node.name);
    List<FieldElement> constants = enclosingEnum.fields;
    for (EnumConstantDeclaration constant in node.constants) {
      _findIdentifier(constants, constant.name);
    }
    return super.visitEnumDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ExportElement exportElement = _findExport(
          library.exports,
          _enclosingUnit.context.sourceFactory
              .resolveUri(_enclosingUnit.source, uri));
      node.element = exportElement;
    }
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitFieldFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFieldFormalParameter(node);
    }
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier functionName = node.name;
      sc.Token property = node.propertyKeyword;
      if (property == null) {
        if (_enclosingExecutable != null) {
          _enclosingExecutable =
              _findIdentifier(_enclosingExecutable.functions, functionName);
        } else {
          _enclosingExecutable =
              _findIdentifier(_enclosingUnit.functions, functionName);
        }
      } else {
        PropertyAccessorElement accessor =
            _findIdentifier(_enclosingUnit.accessors, functionName);
        if ((property as sc.KeywordToken).keyword == sc.Keyword.SET) {
          accessor = accessor.variable.setter;
          functionName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      node.functionExpression.element = _enclosingExecutable;
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      FunctionElement element =
          _findAtOffset(_enclosingExecutable.functions, node.beginToken.offset);
      node.element = element;
    }
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      _enclosingExecutable = node.element;
      return super.visitFunctionExpression(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement outerAlias = _enclosingAlias;
    try {
      SimpleIdentifier aliasName = node.name;
      _enclosingAlias =
          _findIdentifier(_enclosingUnit.functionTypeAliases, aliasName);
      return super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingAlias = outerAlias;
    }
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitFunctionTypedFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFunctionTypedFormalParameter(node);
    }
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ImportElement importElement = _findImport(
          library.imports,
          _enclosingUnit.context.sourceFactory
              .resolveUri(_enclosingUnit.source, uri),
          node.prefix);
      node.element = importElement;
    }
    return super.visitImportDirective(node);
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitLabeledStatement(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    node.element = _enclosingUnit.library;
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      sc.Token property = node.propertyKeyword;
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (property == null) {
        _enclosingExecutable = _findWithNameAndOffset(
            _enclosingClass.methods, nameOfMethod, methodName.offset);
        methodName.staticElement = _enclosingExecutable;
      } else {
        PropertyAccessorElement accessor =
            _findIdentifier(_enclosingClass.accessors, methodName);
        if ((property as sc.KeywordToken).keyword == sc.Keyword.SET) {
          accessor = accessor.variable.setter;
          methodName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitPartDirective(PartDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      Source partSource = _enclosingUnit.context.sourceFactory
          .resolveUri(_enclosingUnit.source, uri);
      node.element = _findPart(_enclosingUnit.library.parts, partSource);
    }
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    node.element = _enclosingUnit.library;
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitSimpleFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {}
    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    if (_enclosingClass != null) {
      _findIdentifier(_enclosingClass.typeParameters, parameterName);
    } else if (_enclosingAlias != null) {
      _findIdentifier(_enclosingAlias.typeParameters, parameterName);
    }
    return super.visitTypeParameter(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = null;
    SimpleIdentifier variableName = node.name;
    if (_enclosingExecutable != null) {
      element =
          _findIdentifier(_enclosingExecutable.localVariables, variableName);
    }
    if (element == null && _enclosingClass != null) {
      element = _findIdentifier(_enclosingClass.fields, variableName);
    }
    if (element == null && _enclosingUnit != null) {
      element = _findIdentifier(_enclosingUnit.topLevelVariables, variableName);
    }
    Expression initializer = node.initializer;
    if (initializer != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
          // TODO(brianwilkerson) Report this internal error.
        } else {
          _enclosingExecutable = element.initializer;
        }
        return super.visitVariableDeclaration(node);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    return super.visitVariableDeclaration(node);
  }

  /**
   * Return the element in the given array of elements that was created for the declaration at the
   * given offset. This method should only be used when there is no name
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param offset the offset of the name of the element to be returned
   * @return the element at the given offset
   */
  Element _findAtOffset(List<Element> elements, int offset) =>
      _findWithNameAndOffset(elements, "", offset);

  /**
   * Return the export element from the given array whose library has the given source, or
   * `null` if there is no such export.
   *
   * @param exports the export elements being searched
   * @param source the source of the library associated with the export element to being searched
   *          for
   * @return the export element whose library has the given source
   */
  ExportElement _findExport(List<ExportElement> exports, Source source) {
    for (ExportElement export in exports) {
      if (export.exportedLibrary.source == source) {
        return export;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param identifier the name node in the declaration of the element to be returned
   * @return the element created for the declaration with the given name
   */
  Element _findIdentifier(List<Element> elements, SimpleIdentifier identifier) {
    Element element =
        _findWithNameAndOffset(elements, identifier.name, identifier.offset);
    identifier.staticElement = element;
    return element;
  }

  /**
   * Return the import element from the given array whose library has the given source and that has
   * the given prefix, or `null` if there is no such import.
   *
   * @param imports the import elements being searched
   * @param source the source of the library associated with the import element to being searched
   *          for
   * @param prefix the prefix with which the library was imported
   * @return the import element whose library has the given source and prefix
   */
  ImportElement _findImport(
      List<ImportElement> imports, Source source, SimpleIdentifier prefix) {
    for (ImportElement element in imports) {
      if (element.importedLibrary.source == source) {
        PrefixElement prefixElement = element.prefix;
        if (prefix == null) {
          if (prefixElement == null) {
            return element;
          }
        } else {
          if (prefixElement != null &&
              prefix.name == prefixElement.displayName) {
            return element;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return the element for the part with the given source, or `null` if there is no element
   * for the given source.
   *
   * @param parts the elements for the parts
   * @param partSource the source for the part whose element is to be returned
   * @return the element for the part with the given source
   */
  CompilationUnitElement _findPart(
      List<CompilationUnitElement> parts, Source partSource) {
    for (CompilationUnitElement part in parts) {
      if (part.source == partSource) {
        return part;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name at the given offset.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param name the name of the element to be returned
   * @param offset the offset of the name of the element to be returned
   * @return the element with the given name and offset
   */
  Element _findWithNameAndOffset(
      List<Element> elements, String name, int offset) {
    for (Element element in elements) {
      if (element.nameOffset == offset && element.displayName == name) {
        return element;
      }
    }
    return null;
  }

  /**
   * Search the most closely enclosing list of parameters for a parameter with the given name.
   *
   * @param node the node defining the parameter with the given name
   * @param parameterName the name of the parameter being searched for
   * @return the element representing the parameter with that name
   */
  ParameterElement _getElementForParameter(
      FormalParameter node, SimpleIdentifier parameterName) {
    List<ParameterElement> parameters = null;
    if (_enclosingParameter != null) {
      parameters = _enclosingParameter.parameters;
    }
    if (parameters == null && _enclosingExecutable != null) {
      parameters = _enclosingExecutable.parameters;
    }
    if (parameters == null && _enclosingAlias != null) {
      parameters = _enclosingAlias.parameters;
    }
    ParameterElement element =
        parameters == null ? null : _findIdentifier(parameters, parameterName);
    if (element == null) {
      StringBuffer buffer = new StringBuffer();
      buffer.writeln("Invalid state found in the Analysis Engine:");
      buffer.writeln(
          "DeclarationResolver.getElementForParameter() is visiting a parameter that does not appear to be in a method or function.");
      buffer.writeln("Ancestors:");
      AstNode parent = node.parent;
      while (parent != null) {
        buffer.writeln(parent.runtimeType.toString());
        buffer.writeln("---------");
        parent = parent.parent;
      }
      AnalysisEngine.instance.logger.logError(buffer.toString(),
          new CaughtException(new AnalysisException(), null));
    }
    return element;
  }

  /**
   * Return the value of the given string literal, or `null` if the string is not a constant
   * string without any string interpolation.
   *
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String _getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    return literal.stringValue;
  }
}

/**
 * Instances of the class `ElementBuilder` traverse an AST structure and build the element
 * model representing the AST structure.
 */
class ElementBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The element holder associated with the element that is currently being built.
   */
  ElementHolder _currentHolder;

  /**
   * A flag indicating whether a variable declaration is in the context of a field declaration.
   */
  bool _inFieldContext = false;

  /**
   * A flag indicating whether a variable declaration is within the body of a method or function.
   */
  bool _inFunction = false;

  /**
   * A flag indicating whether the class currently being visited can be used as a mixin.
   */
  bool _isValidMixin = false;

  /**
   * A collection holding the function types defined in a class that need to have their type
   * arguments set to the types of the type parameters for the class, or `null` if we are not
   * currently processing nodes within a class.
   */
  List<FunctionTypeImpl> _functionTypesToFix = null;

  /**
   * A table mapping field names to field elements for the fields defined in the current class, or
   * `null` if we are not in the scope of a class.
   */
  HashMap<String, FieldElement> _fieldMap;

  /**
   * Initialize a newly created element builder to build the elements for a compilation unit.
   *
   * @param initialHolder the element holder associated with the compilation unit being built
   */
  ElementBuilder(ElementHolder initialHolder) {
    _currentHolder = initialHolder;
  }

  @override
  Object visitBlock(Block node) {
    bool wasInField = _inFieldContext;
    _inFieldContext = false;
    try {
      node.visitChildren(this);
    } finally {
      _inFieldContext = wasInField;
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      // exception
      LocalVariableElementImpl exception =
          new LocalVariableElementImpl.forNode(exceptionParameter);
      if (node.exceptionType == null) {
        exception.hasImplicitType = true;
      }
      _currentHolder.addLocalVariable(exception);
      exceptionParameter.staticElement = exception;
      // stack trace
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElementImpl stackTrace =
            new LocalVariableElementImpl.forNode(stackTraceParameter);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter.staticElement = stackTrace;
      }
    }
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ElementHolder holder = new ElementHolder();
    _isValidMixin = true;
    _functionTypesToFix = new List<FunctionTypeImpl>();
    //
    // Process field declarations before constructors and methods so that field
    // formal parameters can be correctly resolved to their fields.
    //
    ElementHolder previousHolder = _currentHolder;
    _currentHolder = holder;
    try {
      List<ClassMember> nonFields = new List<ClassMember>();
      node.visitChildren(
          new _ElementBuilder_visitClassDeclaration(this, nonFields));
      _buildFieldMap(holder.fieldsWithoutFlushing);
      int count = nonFields.length;
      for (int i = 0; i < count; i++) {
        nonFields[i].accept(this);
      }
    } finally {
      _currentHolder = previousHolder;
    }
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl.forNode(className);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    List<DartType> typeArguments = _createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    List<ConstructorElement> constructors = holder.constructors;
    if (constructors.length == 0) {
      //
      // Create the default constructor.
      //
      constructors = _createDefaultConstructors(interfaceType);
    }
    element.abstract = node.isAbstract;
    element.accessors = holder.accessors;
    element.constructors = constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeParameters = typeParameters;
    element.validMixin = _isValidMixin;
    int functionTypeCount = _functionTypesToFix.length;
    for (int i = 0; i < functionTypeCount; i++) {
      _functionTypesToFix[i].typeArguments = typeArguments;
    }
    _functionTypesToFix = null;
    _currentHolder.addType(element);
    className.staticElement = element;
    _fieldMap = null;
    holder.validate();
    return null;
  }

  /**
   * Implementation of this method should be synchronized with
   * [visitClassDeclaration].
   */
  void visitClassDeclarationIncrementally(ClassDeclaration node) {
    //
    // Process field declarations before constructors and methods so that field
    // formal parameters can be correctly resolved to their fields.
    //
    ClassElement classElement = node.element;
    _buildFieldMap(classElement.fields);
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _functionTypesToFix = new List<FunctionTypeImpl>();
    _visitChildren(holder, node);
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl.forNode(className);
    element.abstract = node.abstractKeyword != null;
    element.mixinApplication = true;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    element.typeParameters = typeParameters;
    List<DartType> typeArguments = _createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    // set default constructor
    for (FunctionTypeImpl functionType in _functionTypesToFix) {
      functionType.typeArguments = typeArguments;
    }
    _functionTypesToFix = null;
    _currentHolder.addType(element);
    className.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _isValidMixin = false;
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      _visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
    FunctionBody body = node.body;
    SimpleIdentifier constructorName = node.name;
    ConstructorElementImpl element =
        new ConstructorElementImpl.forNode(constructorName);
    if (node.externalKeyword != null) {
      element.external = true;
    }
    if (node.factoryKeyword != null) {
      element.factory = true;
    }
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.const2 = node.constKeyword != null;
    if (body.isAsynchronous) {
      element.asynchronous = true;
    }
    if (body.isGenerator) {
      element.generator = true;
    }
    _currentHolder.addConstructor(element);
    node.element = element;
    if (constructorName == null) {
      Identifier returnType = node.returnType;
      if (returnType != null) {
        element.nameOffset = returnType.offset;
        element.nameEnd = returnType.end;
      }
    } else {
      constructorName.staticElement = element;
      element.periodOffset = node.period.offset;
      element.nameEnd = constructorName.end;
    }
    holder.validate();
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    LocalVariableElementImpl element =
        new LocalVariableElementImpl.forNode(variableName);
    ForEachStatement statement = node.parent as ForEachStatement;
    int declarationEnd = node.offset + node.length;
    int statementEnd = statement.offset + statement.length;
    element.setVisibleRange(declarationEnd, statementEnd - declarationEnd - 1);
    element.const3 = node.isConst;
    element.final2 = node.isFinal;
    if (node.type == null) {
      element.hasImplicitType = true;
    }
    _currentHolder.addLocalVariable(element);
    variableName.staticElement = element;
    return super.visitDeclaredIdentifier(node);
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    ElementHolder holder = new ElementHolder();
    NormalFormalParameter normalParameter = node.parameter;
    SimpleIdentifier parameterName = normalParameter.identifier;
    ParameterElementImpl parameter;
    if (normalParameter is FieldFormalParameter) {
      parameter = new DefaultFieldFormalParameterElementImpl(parameterName);
      FieldElement field =
          _fieldMap == null ? null : _fieldMap[parameterName.name];
      if (field != null) {
        (parameter as DefaultFieldFormalParameterElementImpl).field = field;
      }
    } else {
      parameter = new DefaultParameterElementImpl(parameterName);
    }
    parameter.const3 = node.isConst;
    parameter.final2 = node.isFinal;
    parameter.parameterKind = node.kind;
    // set initializer, default value range
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _visit(holder, defaultValue);
      FunctionElementImpl initializer =
          new FunctionElementImpl.forOffset(defaultValue.beginToken.offset);
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.parameters = holder.parameters;
      initializer.synthetic = true;
      parameter.initializer = initializer;
      parameter.defaultValueCode = defaultValue.toSource();
    }
    // visible range
    _setParameterVisibleRange(node, parameter);
    if (normalParameter is SimpleFormalParameter &&
        normalParameter.type == null) {
      parameter.hasImplicitType = true;
    }
    _currentHolder.addParameter(parameter);
    parameterName.staticElement = parameter;
    normalParameter.accept(this);
    holder.validate();
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    SimpleIdentifier enumName = node.name;
    ClassElementImpl enumElement = new ClassElementImpl.forNode(enumName);
    enumElement.enum2 = true;
    InterfaceTypeImpl enumType = new InterfaceTypeImpl(enumElement);
    enumElement.type = enumType;
    // The equivalent code for enums in the spec shows a single constructor,
    // but that constructor is not callable (since it is a compile-time error
    // to subclass, mix-in, implement, or explicitly instantiate an enum).  So
    // we represent this as having no constructors.
    enumElement.constructors = ConstructorElement.EMPTY_LIST;
    _currentHolder.addEnum(enumElement);
    enumName.staticElement = enumElement;
    return super.visitEnumDeclaration(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    bool wasInField = _inFieldContext;
    _inFieldContext = true;
    try {
      node.visitChildren(this);
    } finally {
      _inFieldContext = wasInField;
    }
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      FieldElement field =
          _fieldMap == null ? null : _fieldMap[parameterName.name];
      FieldFormalParameterElementImpl parameter =
          new FieldFormalParameterElementImpl(parameterName);
      parameter.const3 = node.isConst;
      parameter.final2 = node.isFinal;
      parameter.parameterKind = node.kind;
      if (field != null) {
        parameter.field = field;
      }
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type
    // of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    ParameterElementImpl element = node.element;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression expression = node.functionExpression;
    if (expression != null) {
      ElementHolder holder = new ElementHolder();
      bool wasInFunction = _inFunction;
      _inFunction = true;
      try {
        _visitChildren(holder, node);
      } finally {
        _inFunction = wasInFunction;
      }
      FunctionBody body = expression.body;
      sc.Token property = node.propertyKeyword;
      if (property == null || _inFunction) {
        SimpleIdentifier functionName = node.name;
        FunctionElementImpl element =
            new FunctionElementImpl.forNode(functionName);
        if (node.externalKeyword != null) {
          element.external = true;
        }
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        element.typeParameters = holder.typeParameters;
        if (body.isAsynchronous) {
          element.asynchronous = true;
        }
        if (body.isGenerator) {
          element.generator = true;
        }
        if (_inFunction) {
          Block enclosingBlock = node.getAncestor((node) => node is Block);
          if (enclosingBlock != null) {
            int functionEnd = node.offset + node.length;
            int blockEnd = enclosingBlock.offset + enclosingBlock.length;
            element.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
          }
        }
        if (node.returnType == null) {
          element.hasImplicitReturnType = true;
        }
        _currentHolder.addFunction(element);
        expression.element = element;
        functionName.staticElement = element;
      } else {
        SimpleIdentifier propertyNameNode = node.name;
        if (propertyNameNode == null) {
          // TODO(brianwilkerson) Report this internal error.
          return null;
        }
        String propertyName = propertyNameNode.name;
        TopLevelVariableElementImpl variable = _currentHolder
            .getTopLevelVariable(propertyName) as TopLevelVariableElementImpl;
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(node.name.name, -1);
          variable.final2 = true;
          variable.synthetic = true;
          _currentHolder.addTopLevelVariable(variable);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          if (node.externalKeyword != null) {
            getter.external = true;
          }
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          if (body.isAsynchronous) {
            getter.asynchronous = true;
          }
          if (body.isGenerator) {
            getter.generator = true;
          }
          getter.variable = variable;
          getter.getter = true;
          getter.static = true;
          variable.getter = getter;
          if (node.returnType == null) {
            getter.hasImplicitReturnType = true;
          }
          _currentHolder.addAccessor(getter);
          expression.element = getter;
          propertyNameNode.staticElement = getter;
        } else {
          PropertyAccessorElementImpl setter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          if (node.externalKeyword != null) {
            setter.external = true;
          }
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          if (body.isAsynchronous) {
            setter.asynchronous = true;
          }
          if (body.isGenerator) {
            setter.generator = true;
          }
          setter.variable = variable;
          setter.setter = true;
          setter.static = true;
          variable.setter = setter;
          variable.final2 = false;
          _currentHolder.addAccessor(setter);
          expression.element = setter;
          propertyNameNode.staticElement = setter;
        }
      }
      holder.validate();
    }
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // visitFunctionDeclaration has already created the element for the
      // declaration.  We just need to visit children.
      return super.visitFunctionExpression(node);
    }
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      _visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
    FunctionBody body = node.body;
    FunctionElementImpl element =
        new FunctionElementImpl.forOffset(node.beginToken.offset);
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    if (body.isAsynchronous) {
      element.asynchronous = true;
    }
    if (body.isGenerator) {
      element.generator = true;
    }
    if (_inFunction) {
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      if (enclosingBlock != null) {
        int functionEnd = node.offset + node.length;
        int blockEnd = enclosingBlock.offset + enclosingBlock.length;
        element.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
      }
    }
    FunctionTypeImpl type = new FunctionTypeImpl(element);
    if (_functionTypesToFix != null) {
      _functionTypesToFix.add(type);
    }
    element.type = type;
    element.hasImplicitReturnType = true;
    _currentHolder.addFunction(element);
    node.element = element;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    SimpleIdentifier aliasName = node.name;
    List<ParameterElement> parameters = holder.parameters;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    FunctionTypeAliasElementImpl element =
        new FunctionTypeAliasElementImpl.forNode(aliasName);
    element.parameters = parameters;
    element.typeParameters = typeParameters;
    FunctionTypeImpl type = new FunctionTypeImpl.forTypedef(element);
    type.typeArguments = _createTypeParameterTypes(typeParameters);
    element.type = type;
    _currentHolder.addTypeAlias(element);
    aliasName.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter =
          new ParameterElementImpl.forNode(parameterName);
      parameter.parameterKind = node.kind;
      _setParameterVisibleRange(node, parameter);
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type
    //of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    ParameterElementImpl element = node.element;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    holder.validate();
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element =
          new LabelElementImpl(labelName, onSwitchStatement, false);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitLabeledStatement(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    try {
      ElementHolder holder = new ElementHolder();
      bool wasInFunction = _inFunction;
      _inFunction = true;
      try {
        _visitChildren(holder, node);
      } finally {
        _inFunction = wasInFunction;
      }
      bool isStatic = node.isStatic;
      sc.Token property = node.propertyKeyword;
      FunctionBody body = node.body;
      if (property == null) {
        SimpleIdentifier methodName = node.name;
        String nameOfMethod = methodName.name;
        if (nameOfMethod == sc.TokenType.MINUS.lexeme &&
            node.parameters.parameters.length == 0) {
          nameOfMethod = "unary-";
        }
        MethodElementImpl element =
            new MethodElementImpl(nameOfMethod, methodName.offset);
        element.abstract = node.isAbstract;
        if (node.externalKeyword != null) {
          element.external = true;
        }
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        element.static = isStatic;
        element.typeParameters = holder.typeParameters;
        if (body.isAsynchronous) {
          element.asynchronous = true;
        }
        if (body.isGenerator) {
          element.generator = true;
        }
        if (node.returnType == null) {
          element.hasImplicitReturnType = true;
        }
        _currentHolder.addMethod(element);
        methodName.staticElement = element;
      } else {
        SimpleIdentifier propertyNameNode = node.name;
        String propertyName = propertyNameNode.name;
        FieldElementImpl field =
            _currentHolder.getField(propertyName) as FieldElementImpl;
        if (field == null) {
          field = new FieldElementImpl(node.name.name, -1);
          field.final2 = true;
          field.static = isStatic;
          field.synthetic = true;
          _currentHolder.addField(field);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          if (node.externalKeyword != null) {
            getter.external = true;
          }
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          if (body.isAsynchronous) {
            getter.asynchronous = true;
          }
          if (body.isGenerator) {
            getter.generator = true;
          }
          getter.variable = field;
          getter.abstract = node.isAbstract;
          getter.getter = true;
          getter.static = isStatic;
          field.getter = getter;
          if (node.returnType == null) {
            getter.hasImplicitReturnType = true;
          }
          _currentHolder.addAccessor(getter);
          propertyNameNode.staticElement = getter;
        } else {
          PropertyAccessorElementImpl setter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          if (node.externalKeyword != null) {
            setter.external = true;
          }
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          if (body.isAsynchronous) {
            setter.asynchronous = true;
          }
          if (body.isGenerator) {
            setter.generator = true;
          }
          setter.variable = field;
          setter.abstract = node.isAbstract;
          setter.setter = true;
          setter.static = isStatic;
          field.setter = setter;
          field.final2 = false;
          _currentHolder.addAccessor(setter);
          propertyNameNode.staticElement = setter;
        }
      }
      holder.validate();
    } catch (exception, stackTrace) {
      if (node.name.staticElement == null) {
        ClassDeclaration classNode =
            node.getAncestor((node) => node is ClassDeclaration);
        StringBuffer buffer = new StringBuffer();
        buffer.write("The element for the method ");
        buffer.write(node.name);
        buffer.write(" in ");
        buffer.write(classNode.name);
        buffer.write(" was not set while trying to build the element model.");
        AnalysisEngine.instance.logger.logError(
            buffer.toString(), new CaughtException(exception, stackTrace));
      } else {
        String message =
            "Exception caught in ElementBuilder.visitMethodDeclaration()";
        AnalysisEngine.instance.logger
            .logError(message, new CaughtException(exception, stackTrace));
      }
    } finally {
      if (node.name.staticElement == null) {
        ClassDeclaration classNode =
            node.getAncestor((node) => node is ClassDeclaration);
        StringBuffer buffer = new StringBuffer();
        buffer.write("The element for the method ");
        buffer.write(node.name);
        buffer.write(" in ");
        buffer.write(classNode.name);
        buffer.write(" was not set while trying to resolve types.");
        AnalysisEngine.instance.logger.logError(
            buffer.toString(),
            new CaughtException(
                new AnalysisException(buffer.toString()), null));
      }
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter =
          new ParameterElementImpl.forNode(parameterName);
      parameter.const3 = node.isConst;
      parameter.final2 = node.isFinal;
      parameter.parameterKind = node.kind;
      _setParameterVisibleRange(node, parameter);
      if (node.type == null) {
        parameter.hasImplicitType = true;
      }
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    _isValidMixin = false;
    return super.visitSuperExpression(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    TypeParameterElementImpl typeParameter =
        new TypeParameterElementImpl.forNode(parameterName);
    TypeParameterTypeImpl typeParameterType =
        new TypeParameterTypeImpl(typeParameter);
    typeParameter.type = typeParameterType;
    _currentHolder.addTypeParameter(typeParameter);
    parameterName.staticElement = typeParameter;
    return super.visitTypeParameter(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    bool isConst = node.isConst;
    bool isFinal = node.isFinal;
    bool hasInitializer = node.initializer != null;
    VariableElementImpl element;
    if (_inFieldContext) {
      SimpleIdentifier fieldName = node.name;
      FieldElementImpl field;
      if ((isConst || isFinal) && hasInitializer) {
        field = new ConstFieldElementImpl.forNode(fieldName);
      } else {
        field = new FieldElementImpl.forNode(fieldName);
      }
      element = field;
      if ((node.parent as VariableDeclarationList).type == null) {
        field.hasImplicitType = true;
      }
      _currentHolder.addField(field);
      fieldName.staticElement = field;
    } else if (_inFunction) {
      SimpleIdentifier variableName = node.name;
      LocalVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstLocalVariableElementImpl.forNode(variableName);
      } else {
        variable = new LocalVariableElementImpl.forNode(variableName);
      }
      element = variable;
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      // TODO(brianwilkerson) This isn't right for variables declared in a for
      // loop.
      variable.setVisibleRange(enclosingBlock.offset, enclosingBlock.length);
      if ((node.parent as VariableDeclarationList).type == null) {
        variable.hasImplicitType = true;
      }
      _currentHolder.addLocalVariable(variable);
      variableName.staticElement = element;
    } else {
      SimpleIdentifier variableName = node.name;
      TopLevelVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstTopLevelVariableElementImpl(variableName);
      } else {
        variable = new TopLevelVariableElementImpl.forNode(variableName);
      }
      element = variable;
      if ((node.parent as VariableDeclarationList).type == null) {
        variable.hasImplicitType = true;
      }
      _currentHolder.addTopLevelVariable(variable);
      variableName.staticElement = element;
    }
    element.const3 = isConst;
    element.final2 = isFinal;
    if (hasInitializer) {
      ElementHolder holder = new ElementHolder();
      bool wasInFieldContext = _inFieldContext;
      _inFieldContext = false;
      try {
        _visit(holder, node.initializer);
      } finally {
        _inFieldContext = wasInFieldContext;
      }
      FunctionElementImpl initializer =
          new FunctionElementImpl.forOffset(node.initializer.beginToken.offset);
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.synthetic = true;
      element.initializer = initializer;
      holder.validate();
    }
    if (element is PropertyInducingElementImpl) {
      if (_inFieldContext) {
        (element as FieldElementImpl).static =
            (node.parent.parent as FieldDeclaration).isStatic;
      }
      PropertyAccessorElementImpl getter =
          new PropertyAccessorElementImpl.forVariable(element);
      getter.getter = true;
      if (element.hasImplicitType) {
        getter.hasImplicitReturnType = true;
      }
      _currentHolder.addAccessor(getter);
      element.getter = getter;
      if (!isConst && !isFinal) {
        PropertyAccessorElementImpl setter =
            new PropertyAccessorElementImpl.forVariable(element);
        setter.setter = true;
        ParameterElementImpl parameter =
            new ParameterElementImpl("_${element.name}", element.nameOffset);
        parameter.synthetic = true;
        parameter.parameterKind = ParameterKind.REQUIRED;
        setter.parameters = <ParameterElement>[parameter];
        _currentHolder.addAccessor(setter);
        element.setter = setter;
      }
    }
    return null;
  }

  /**
   * Build the table mapping field names to field elements for the fields defined in the current
   * class.
   *
   * @param fields the field elements defined in the current class
   */
  void _buildFieldMap(List<FieldElement> fields) {
    _fieldMap = new HashMap<String, FieldElement>();
    int count = fields.length;
    for (int i = 0; i < count; i++) {
      FieldElement field = fields[i];
      _fieldMap[field.name] = field;
    }
  }

  /**
   * Creates the [ConstructorElement]s array with the single default constructor element.
   *
   * @param interfaceType the interface type for which to create a default constructor
   * @return the [ConstructorElement]s array with the single default constructor element
   */
  List<ConstructorElement> _createDefaultConstructors(
      InterfaceTypeImpl interfaceType) {
    ConstructorElementImpl constructor =
        new ConstructorElementImpl.forNode(null);
    constructor.synthetic = true;
    constructor.returnType = interfaceType;
    FunctionTypeImpl type = new FunctionTypeImpl(constructor);
    _functionTypesToFix.add(type);
    constructor.type = type;
    return <ConstructorElement>[constructor];
  }

  /**
   * Create the types associated with the given type parameters, setting the type of each type
   * parameter, and return an array of types corresponding to the given parameters.
   *
   * @param typeParameters the type parameters for which types are to be created
   * @return an array of types corresponding to the given parameters
   */
  List<DartType> _createTypeParameterTypes(
      List<TypeParameterElement> typeParameters) {
    int typeParameterCount = typeParameters.length;
    List<DartType> typeArguments = new List<DartType>(typeParameterCount);
    for (int i = 0; i < typeParameterCount; i++) {
      TypeParameterElementImpl typeParameter =
          typeParameters[i] as TypeParameterElementImpl;
      TypeParameterTypeImpl typeParameterType =
          new TypeParameterTypeImpl(typeParameter);
      typeParameter.type = typeParameterType;
      typeArguments[i] = typeParameterType;
    }
    return typeArguments;
  }

  /**
   * Return the body of the function that contains the given parameter, or `null` if no
   * function body could be found.
   *
   * @param node the parameter contained in the function whose body is to be returned
   * @return the body of the function that contains the given parameter
   */
  FunctionBody _getFunctionBody(FormalParameter node) {
    AstNode parent = node.parent;
    while (parent != null) {
      if (parent is ConstructorDeclaration) {
        return parent.body;
      } else if (parent is FunctionExpression) {
        return parent.body;
      } else if (parent is MethodDeclaration) {
        return parent.body;
      }
      parent = parent.parent;
    }
    return null;
  }

  /**
   * Sets the visible source range for formal parameter.
   */
  void _setParameterVisibleRange(
      FormalParameter node, ParameterElementImpl element) {
    FunctionBody body = _getFunctionBody(node);
    if (body != null) {
      element.setVisibleRange(body.offset, body.length);
    }
  }

  /**
   * Make the given holder be the current holder while visiting the given node.
   *
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node to be visited
   */
  void _visit(ElementHolder holder, AstNode node) {
    if (node != null) {
      ElementHolder previousHolder = _currentHolder;
      _currentHolder = holder;
      try {
        node.accept(this);
      } finally {
        _currentHolder = previousHolder;
      }
    }
  }

  /**
   * Make the given holder be the current holder while visiting the children of the given node.
   *
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node whose children are to be visited
   */
  void _visitChildren(ElementHolder holder, AstNode node) {
    if (node != null) {
      ElementHolder previousHolder = _currentHolder;
      _currentHolder = holder;
      try {
        node.visitChildren(this);
      } finally {
        _currentHolder = previousHolder;
      }
    }
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

  FieldElement getField(String fieldName) {
    if (_fields == null) {
      return null;
    }
    for (FieldElement field in _fields) {
      if (field.name == fieldName) {
        return field;
      }
    }
    return null;
  }

  TopLevelVariableElement getTopLevelVariable(String variableName) {
    if (_topLevelVariables == null) {
      return null;
    }
    for (TopLevelVariableElement variable in _topLevelVariables) {
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
 * Instances of the class `EnclosedScope` implement a scope that is lexically enclosed in
 * another scope.
 */
class EnclosedScope extends Scope {
  /**
   * The scope in which this scope is lexically enclosed.
   */
  final Scope enclosingScope;

  /**
   * A table mapping names that will be defined in this scope, but right now are not initialized.
   * According to the scoping rules these names are hidden, even if they were defined in an outer
   * scope.
   */
  HashMap<String, Element> _hiddenElements = new HashMap<String, Element>();

  /**
   * A flag indicating whether there are any names defined in this scope.
   */
  bool _hasHiddenName = false;

  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   */
  EnclosedScope(this.enclosingScope);

  @override
  AnalysisErrorListener get errorListener => enclosingScope.errorListener;

  /**
   * Record that given element is declared in this scope, but hasn't been initialized yet, so it is
   * error to use. If there is already an element with the given name defined in an outer scope,
   * then it will become unavailable.
   *
   * @param element the element declared, but not initialized in this scope
   */
  void hide(Element element) {
    if (element != null) {
      String name = element.name;
      if (name != null && !name.isEmpty) {
        _hiddenElements[name] = element;
        _hasHiddenName = true;
      }
    }
  }

  @override
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    // May be there is a hidden Element.
    if (_hasHiddenName) {
      Element hiddenElement = _hiddenElements[name];
      if (hiddenElement != null) {
        errorListener.onError(new AnalysisError(
            getSource(identifier),
            identifier.offset,
            identifier.length,
            CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, []));
        return hiddenElement;
      }
    }
    // Check enclosing scope.
    return enclosingScope.internalLookup(identifier, name, referencingLibrary);
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
    ClassElementImpl enumElement = node.name.staticElement as ClassElementImpl;
    InterfaceType enumType = enumElement.type;
    enumElement.supertype = _typeProvider.objectType;
    //
    // Populate the fields.
    //
    List<FieldElement> fields = new List<FieldElement>();
    List<PropertyAccessorElement> getters = new List<PropertyAccessorElement>();
    InterfaceType intType = _typeProvider.intType;
    String indexFieldName = "index";
    FieldElementImpl indexField = new FieldElementImpl(indexFieldName, -1);
    indexField.final2 = true;
    indexField.synthetic = true;
    indexField.type = intType;
    fields.add(indexField);
    getters.add(_createGetter(indexField));
    ConstFieldElementImpl valuesField = new ConstFieldElementImpl("values", -1);
    valuesField.static = true;
    valuesField.const3 = true;
    valuesField.synthetic = true;
    valuesField.type = _typeProvider.listType.substitute4(<DartType>[enumType]);
    fields.add(valuesField);
    getters.add(_createGetter(valuesField));
    //
    // Build the enum constants.
    //
    NodeList<EnumConstantDeclaration> constants = node.constants;
    List<DartObjectImpl> constantValues = new List<DartObjectImpl>();
    int constantCount = constants.length;
    for (int i = 0; i < constantCount; i++) {
      SimpleIdentifier constantName = constants[i].name;
      FieldElementImpl constantField =
          new ConstFieldElementImpl.forNode(constantName);
      constantField.static = true;
      constantField.const3 = true;
      constantField.type = enumType;
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
      getters.add(_createGetter(constantField));
      constantName.staticElement = constantField;
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
   * Create a getter that corresponds to the given field.
   *
   * @param field the field for which a getter is to be created
   * @return the getter that was created
   */
  PropertyAccessorElement _createGetter(FieldElementImpl field) {
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl.forVariable(field);
    getter.getter = true;
    getter.returnType = field.type;
    getter.type = new FunctionTypeImpl(getter);
    field.getter = getter;
    return getter;
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

  @override
  bool visitArgumentList(ArgumentList node) =>
      _visitExpressions(node.arguments);

  @override
  bool visitAsExpression(AsExpression node) => _nodeExits(node.expression);

  @override
  bool visitAssertStatement(AssertStatement node) => false;

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    Expression leftHandSide = node.leftHandSide;
    if (_nodeExits(leftHandSide)) {
      return true;
    }
    if (node.operator.type == sc.TokenType.QUESTION_QUESTION_EQ) {
      return false;
    }
    if (leftHandSide is PropertyAccess &&
        leftHandSide.operator.type == sc.TokenType.QUESTION_PERIOD) {
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
    sc.TokenType operatorType = node.operator.type;
    // If the operator is ||, then only consider the RHS of the binary
    // expression if the left hand side is the false literal.
    // TODO(jwren) Do we want to take constant expressions into account,
    // evaluate if(false) {} differently than if(<condition>), when <condition>
    // evaluates to a constant false value?
    if (operatorType == sc.TokenType.BAR_BAR) {
      if (lhsExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = lhsExpression;
        if (!booleanLiteral.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is &&, then only consider the RHS of the binary
    // expression if the left hand side is the true literal.
    if (operatorType == sc.TokenType.AMPERSAND_AMPERSAND) {
      if (lhsExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = lhsExpression;
        if (booleanLiteral.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is ??, then don't consider the RHS of the binary
    // expression.
    if (operatorType == sc.TokenType.QUESTION_QUESTION) {
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
  bool visitContinueStatement(ContinueStatement node) => false;

  @override
  bool visitDoStatement(DoStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      Expression conditionExpression = node.condition;
      if (_nodeExits(conditionExpression)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = conditionExpression;
        // If do {} while (true), and the body doesn't return or the body
        // doesn't have a break, then return true.
        bool blockReturns = _nodeExits(node.body);
        if (booleanLiteral.value &&
            (blockReturns || !_enclosingBlockContainsBreak)) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
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
      // TODO(jwren) Do we want to take all constant expressions into account?
      // If for(; true; ) (or for(;;)), and the body doesn't return or the body
      // doesn't have a break, then return true.
      bool implicitOrExplictTrue = conditionExpression == null ||
          (conditionExpression is BooleanLiteral && conditionExpression.value);
      if (implicitOrExplictTrue) {
        bool blockReturns = _nodeExits(node.body);
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
      BooleanLiteral booleanLiteral = conditionExpression;
      if (booleanLiteral.value) {
        // if(true) ...
        return _nodeExits(thenStatement);
      } else if (elseStatement != null) {
        // if (false) ...
        return _nodeExits(elseStatement);
      }
    }
    if (thenStatement == null || elseStatement == null) {
      return false;
    }
    return _nodeExits(thenStatement) && _nodeExits(elseStatement);
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
  bool visitLabeledStatement(LabeledStatement node) =>
      node.statement.accept(this);

  @override
  bool visitLiteral(Literal node) => false;

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    if (target != null) {
      if (target.accept(this)) {
        return true;
      }
      if (node.operator.type == sc.TokenType.QUESTION_PERIOD) {
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
      List<SwitchMember> members = node.members;
      for (int i = 0; i < members.length; i++) {
        SwitchMember switchMember = members[i];
        if (switchMember is SwitchDefault) {
          hasDefault = true;
          // If this is the last member and there are no statements, return
          // false
          if (switchMember.statements.isEmpty && i + 1 == members.length) {
            return false;
          }
        }
        // For switch members with no statements, don't visit the children,
        // otherwise, return false if no return is found in the children
        // statements.
        if (!switchMember.statements.isEmpty && !switchMember.accept(this)) {
          return false;
        }
      }
      // All of the members exit, determine whether there are possible cases
      // that are not caught by the members.
      DartType type = node.expression == null ? null : node.expression.bestType;
      if (type is InterfaceType) {
        ClassElement element = type.element;
        if (element != null && element.isEnum) {
          // If some of the enum values are not covered, then a warning will
          // have already been generated, so there's no point in generating a
          // hint.
          return true;
        }
      }
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
    if (_nodeExits(node.body)) {
      return true;
    }
    Block finallyBlock = node.finallyBlock;
    if (_nodeExits(finallyBlock)) {
      return true;
    }
    return false;
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
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = conditionExpression;
        // If while(true), and the body doesn't return or the body doesn't have
        // a break, then return true.
        bool blockReturns = node.body.accept(this);
        if (booleanLiteral.value &&
            (blockReturns || !_enclosingBlockContainsBreak)) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

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
    for (int i = statements.length - 1; i >= 0; i--) {
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
 * The scope defined by a function.
 */
class FunctionScope extends EnclosedScope {
  /**
   * The element representing the function that defines this scope.
   */
  final ExecutableElement _functionElement;

  /**
   * A flag indicating whether the parameters have already been defined, used to
   * prevent the parameters from being defined multiple times.
   */
  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope enclosed within the [enclosingScope] that
   * represents the given [_functionElement].
   */
  FunctionScope(Scope enclosingScope, this._functionElement)
      : super(new EnclosedScope(new EnclosedScope(enclosingScope))) {
    if (_functionElement == null) {
      throw new IllegalArgumentException("function element cannot be null");
    }
    _defineTypeParameters();
  }

  /**
   * Define the parameters for the given function in the scope that encloses
   * this function.
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    Scope parameterScope = enclosingScope;
    for (ParameterElement parameter in _functionElement.parameters) {
      if (!parameter.isInitializingFormal) {
        parameterScope.define(parameter);
      }
    }
  }

  /**
   * Define the type parameters for the function.
   */
  void _defineTypeParameters() {
    Scope typeParameterScope = enclosingScope.enclosingScope;
    for (TypeParameterElement typeParameter
        in _functionElement.typeParameters) {
      typeParameterScope.define(typeParameter);
    }
  }
}

/**
 * The scope defined by a function type alias.
 */
class FunctionTypeScope extends EnclosedScope {
  final FunctionTypeAliasElement _typeElement;

  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope enclosed within the [enclosingScope] that
   * represents the given [_typeElement].
   */
  FunctionTypeScope(Scope enclosingScope, this._typeElement)
      : super(new EnclosedScope(enclosingScope)) {
    _defineTypeParameters();
  }

  /**
   * Define the parameters for the function type alias.
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    for (ParameterElement parameter in _typeElement.parameters) {
      define(parameter);
    }
  }

  /**
   * Define the type parameters for the function type alias.
   */
  void _defineTypeParameters() {
    Scope typeParameterScope = enclosingScope;
    for (TypeParameterElement typeParameter in _typeElement.typeParameters) {
      typeParameterScope.define(typeParameter);
    }
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
    _visitMetadata(node.metadata);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _visitMetadata(node.metadata);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _visitMetadata(node.metadata);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // If the prefixed identifier references some A.B, where A is a library
    // prefix, then we can lookup the associated ImportDirective in
    // prefixElementMap and remove it from the unusedImports list.
    SimpleIdentifier prefixIdentifier = node.prefix;
    Element element = prefixIdentifier.staticElement;
    if (element is PrefixElement) {
      usedElements.prefixes.add(element);
      return;
    }
    // Otherwise, pass the prefixed identifier element and name onto
    // visitIdentifier.
    _visitIdentifier(element, prefixIdentifier.name);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _visitIdentifier(node.staticElement, node.name);
  }

  void _visitIdentifier(Element element, String name) {
    if (element == null) {
      return;
    }
    // If the element is multiply defined then call this method recursively for
    // each of the conflicting elements.
    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiplyDefinedElement = element;
      for (Element elt in multiplyDefinedElement.conflictingElements) {
        _visitIdentifier(elt, name);
      }
      return;
    } else if (element is PrefixElement) {
      usedElements.prefixes.add(element);
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

  /**
   * Given some [NodeList] of [Annotation]s, ensure that the identifiers are visited by
   * this visitor. Specifically, this covers the cases where AST nodes don't have their identifiers
   * visited by this visitor, but still need their annotations visited.
   *
   * @param annotations the list of annotations to visit
   */
  void _visitMetadata(NodeList<Annotation> annotations) {
    int count = annotations.length;
    for (int i = 0; i < count; i++) {
      annotations[i].accept(this);
    }
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
          return;
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
    if (parent.parent is ExpressionStatement &&
        (parent is PrefixExpression ||
            parent is PostfixExpression ||
            parent is AssignmentExpression && parent.leftHandSide == node)) {
      // v++;
      // ++v;
      // v += 2;
      return false;
    }
    // OK
    return true;
  }
}

/**
 * Instances of the class `HintGenerator` traverse a library's worth of dart code at a time to
 * generate hints over the set of sources.
 *
 * See [HintCode].
 */
class HintGenerator {
  final List<CompilationUnit> _compilationUnits;

  final InternalAnalysisContext _context;

  final AnalysisErrorListener _errorListener;

  LibraryElement _library;

  GatherUsedImportedElementsVisitor _usedImportedElementsVisitor;

  bool _enableDart2JSHints = false;

  /**
   * The inheritance manager used to find overridden methods.
   */
  InheritanceManager _manager;

  GatherUsedLocalElementsVisitor _usedLocalElementsVisitor;

  HintGenerator(this._compilationUnits, this._context, this._errorListener) {
    _library = _compilationUnits[0].element.library;
    _usedImportedElementsVisitor =
        new GatherUsedImportedElementsVisitor(_library);
    _enableDart2JSHints = _context.analysisOptions.dart2jsHint;
    _manager = new InheritanceManager(_compilationUnits[0].element.library);
    _usedLocalElementsVisitor = new GatherUsedLocalElementsVisitor(_library);
  }

  void generateForLibrary() {
    PerformanceStatistics.hints.makeCurrentWhile(() {
      for (CompilationUnit unit in _compilationUnits) {
        CompilationUnitElement element = unit.element;
        if (element != null) {
          _generateForCompilationUnit(unit, element.source);
        }
      }
      CompilationUnit definingUnit = _compilationUnits[0];
      ErrorReporter definingUnitErrorReporter =
          new ErrorReporter(_errorListener, definingUnit.element.source);
      {
        ImportsVerifier importsVerifier = new ImportsVerifier();
        importsVerifier.addImports(definingUnit);
        importsVerifier
            .removeUsedElements(_usedImportedElementsVisitor.usedElements);
        importsVerifier.generateDuplicateImportHints(definingUnitErrorReporter);
        importsVerifier.generateUnusedImportHints(definingUnitErrorReporter);
      }
      _library.accept(new UnusedLocalElementsVerifier(
          _errorListener, _usedLocalElementsVisitor.usedElements));
    });
  }

  void _generateForCompilationUnit(CompilationUnit unit, Source source) {
    ErrorReporter errorReporter = new ErrorReporter(_errorListener, source);
    unit.accept(_usedImportedElementsVisitor);
    // dead code analysis
    unit.accept(new DeadCodeVerifier(errorReporter));
    unit.accept(_usedLocalElementsVisitor);
    // dart2js analysis
    if (_enableDart2JSHints) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }
    // Dart best practices
    unit.accept(
        new BestPracticesVerifier(errorReporter, _context.typeProvider));
    unit.accept(new OverrideVerifier(errorReporter, _manager));
    // Find to-do comments
    new ToDoFinder(errorReporter).findIn(unit);
    // pub analysis
    // TODO(danrubel/jwren) Commented out until bugs in the pub verifier are
    // fixed
    //    unit.accept(new PubVerifier(context, errorReporter));
  }
}

/**
 * Instances of the class {@code HtmlTagInfo} record information about the tags used in an HTML
 * file.
 */
class HtmlTagInfo {
  /**
   * An array containing all of the tags used in the HTML file.
   */
  List<String> allTags;

  /**
   * A table mapping the id's defined in the HTML file to an array containing the names of tags with
   * that identifier.
   */
  HashMap<String, String> idToTagMap;

  /**
   * A table mapping the classes defined in the HTML file to an array containing the names of tags
   * with that class.
   */
  HashMap<String, List<String>> classToTagsMap;

  /**
   * Initialize a newly created information holder to hold the given information about the tags in
   * an HTML file.
   *
   * @param allTags an array containing all of the tags used in the HTML file
   * @param idToTagMap a table mapping the id's defined in the HTML file to an array containing the
   *          names of tags with that identifier
   * @param classToTagsMap a table mapping the classes defined in the HTML file to an array
   *          containing the names of tags with that class
   */
  HtmlTagInfo(this.allTags, this.idToTagMap, this.classToTagsMap);

  /**
   * Return an array containing the tags that have the given class, or {@code null} if there are no
   * such tags.
   *
   * @return an array containing the tags that have the given class
   */
  List<String> getTagsWithClass(String identifier) {
    return classToTagsMap[identifier];
  }

  /**
   * Return the tag that has the given identifier, or {@code null} if there is no such tag (the
   * identifier is not defined).
   *
   * @return the tag that has the given identifier
   */
  String getTagWithId(String identifier) {
    return idToTagMap[identifier];
  }
}

/**
 * Instances of the class {@code HtmlTagInfoBuilder} gather information about the tags used in one
 * or more HTML structures.
 */
class HtmlTagInfoBuilder implements ht.XmlVisitor {
  /**
   * The name of the 'id' attribute.
   */
  static final String ID_ATTRIBUTE = "id";

  /**
   * The name of the 'class' attribute.
   */
  static final String ID_CLASS = "class";

  /**
   * A set containing all of the tag names used in the HTML.
   */
  HashSet<String> tagSet = new HashSet<String>();

  /**
   * A table mapping the id's that are defined to the tag name with that id.
   */
  HashMap<String, String> idMap = new HashMap<String, String>();

  /**
   * A table mapping the classes that are defined to a set of the tag names with that class.
   */
  HashMap<String, HashSet<String>> classMap =
      new HashMap<String, HashSet<String>>();

  /**
   * Initialize a newly created HTML tag info builder.
   */
  HtmlTagInfoBuilder();

  /**
   * Create a tag information holder holding all of the information gathered about the tags in the
   * HTML structures that were visited.
   *
   * @return the information gathered about the tags in the visited HTML structures
   */
  HtmlTagInfo getTagInfo() {
    List<String> allTags = tagSet.toList();
    HashMap<String, List<String>> classToTagsMap =
        new HashMap<String, List<String>>();
    classMap.forEach((String key, Set<String> tags) {
      classToTagsMap[key] = tags.toList();
    });
    return new HtmlTagInfo(allTags, idMap, classToTagsMap);
  }

  @override
  visitHtmlScriptTagNode(ht.HtmlScriptTagNode node) {
    visitXmlTagNode(node);
  }

  @override
  visitHtmlUnit(ht.HtmlUnit node) {
    node.visitChildren(this);
  }

  @override
  visitXmlAttributeNode(ht.XmlAttributeNode node) {}

  @override
  visitXmlTagNode(ht.XmlTagNode node) {
    node.visitChildren(this);
    String tagName = node.tag;
    tagSet.add(tagName);
    for (ht.XmlAttributeNode attribute in node.attributes) {
      String attributeName = attribute.name;
      if (attributeName == ID_ATTRIBUTE) {
        String attributeValue = attribute.text;
        if (attributeValue != null) {
          String tag = idMap[attributeValue];
          if (tag == null) {
            idMap[attributeValue] = tagName;
          } else {
//            reportError(HtmlWarningCode.MULTIPLY_DEFINED_ID, valueToken);
          }
        }
      } else if (attributeName == ID_CLASS) {
        String attributeValue = attribute.text;
        if (attributeValue != null) {
          HashSet<String> tagList = classMap[attributeValue];
          if (tagList == null) {
            tagList = new HashSet<String>();
            classMap[attributeValue] = tagList;
          } else {
//            reportError(HtmlWarningCode.MULTIPLY_DEFINED_ID, valueToken);
          }
          tagList.add(tagName);
        }
      }
    }
  }

//  /**
//   * Report an error with the given error code at the given location. Use the given arguments to
//   * compose the error message.
//   *
//   * @param errorCode the error code of the error to be reported
//   * @param offset the offset of the first character to be highlighted
//   * @param length the number of characters to be highlighted
//   * @param arguments the arguments used to compose the error message
//   */
//  private void reportError(ErrorCode errorCode, Token token, Object... arguments) {
//    errorListener.onError(new AnalysisError(
//        htmlElement.getSource(),
//        token.getOffset(),
//        token.getLength(),
//        errorCode,
//        arguments));
//  }
//
//  /**
//   * Report an error with the given error code at the given location. Use the given arguments to
//   * compose the error message.
//   *
//   * @param errorCode the error code of the error to be reported
//   * @param offset the offset of the first character to be highlighted
//   * @param length the number of characters to be highlighted
//   * @param arguments the arguments used to compose the error message
//   */
//  private void reportError(ErrorCode errorCode, int offset, int length, Object... arguments) {
//    errorListener.onError(new AnalysisError(
//        htmlElement.getSource(),
//        offset,
//        length,
//        errorCode,
//        arguments));
//  }
}

/**
 * Instances of the class `HtmlUnitBuilder` build an element model for a single HTML unit.
 */
class HtmlUnitBuilder implements ht.XmlVisitor<Object> {
  static String _SRC = "src";

  /**
   * The analysis context in which the element model will be built.
   */
  final InternalAnalysisContext _context;

  /**
   * The error listener to which errors will be reported.
   */
  RecordingErrorListener _errorListener;

  /**
   * The HTML element being built.
   */
  HtmlElementImpl _htmlElement;

  /**
   * The elements in the path from the HTML unit to the current tag node.
   */
  List<ht.XmlTagNode> _parentNodes;

  /**
   * The script elements being built.
   */
  List<HtmlScriptElement> _scripts;

  /**
   * A set of the libraries that were resolved while resolving the HTML unit.
   */
  Set<Library> _resolvedLibraries = new HashSet<Library>();

  /**
   * Initialize a newly created HTML unit builder.
   *
   * @param context the analysis context in which the element model will be built
   */
  HtmlUnitBuilder(this._context) {
    this._errorListener = new RecordingErrorListener();
  }

  /**
   * Return the listener to which analysis errors will be reported.
   *
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   *
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _resolvedLibraries;

  /**
   * Build the HTML element for the given source.
   *
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the HTML
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement(Source source, ht.HtmlUnit unit) {
    HtmlElementImpl result = new HtmlElementImpl(_context, source.shortName);
    result.source = source;
    _htmlElement = result;
    unit.accept(this);
    _htmlElement = null;
    unit.element = result;
    return result;
  }

  @override
  Object visitHtmlScriptTagNode(ht.HtmlScriptTagNode node) {
    if (_parentNodes.contains(node)) {
      return _reportCircularity(node);
    }
    _parentNodes.add(node);
    try {
      Source htmlSource = _htmlElement.source;
      ht.XmlAttributeNode scriptAttribute = _getScriptSourcePath(node);
      String scriptSourcePath =
          scriptAttribute == null ? null : scriptAttribute.text;
      if (node.attributeEnd.type == ht.TokenType.GT &&
          scriptSourcePath == null) {
        EmbeddedHtmlScriptElementImpl script =
            new EmbeddedHtmlScriptElementImpl(node);
        try {
          LibraryResolver resolver = new LibraryResolver(_context);
          LibraryElementImpl library =
              resolver.resolveEmbeddedLibrary(htmlSource, node.script, true);
          script.scriptLibrary = library;
          _resolvedLibraries.addAll(resolver.resolvedLibraries);
          _errorListener.addAll(resolver.errorListener);
        } on AnalysisException catch (exception, stackTrace) {
          //TODO (danrubel): Handle or forward the exception
          AnalysisEngine.instance.logger.logError(
              "Could not resolve script tag",
              new CaughtException(exception, stackTrace));
        }
        node.scriptElement = script;
        _scripts.add(script);
      } else {
        ExternalHtmlScriptElementImpl script =
            new ExternalHtmlScriptElementImpl(node);
        if (scriptSourcePath != null) {
          try {
            scriptSourcePath = Uri.encodeFull(scriptSourcePath);
            // Force an exception to be thrown if the URI is invalid so that we
            // can report the problem.
            parseUriWithException(scriptSourcePath);
            Source scriptSource =
                _context.sourceFactory.resolveUri(htmlSource, scriptSourcePath);
            script.scriptSource = scriptSource;
            if (!_context.exists(scriptSource)) {
              _reportValueError(HtmlWarningCode.URI_DOES_NOT_EXIST,
                  scriptAttribute, [scriptSourcePath]);
            }
          } on URISyntaxException {
            _reportValueError(HtmlWarningCode.INVALID_URI, scriptAttribute,
                [scriptSourcePath]);
          }
        }
        node.scriptElement = script;
        _scripts.add(script);
      }
    } finally {
      _parentNodes.remove(node);
    }
    return null;
  }

  @override
  Object visitHtmlUnit(ht.HtmlUnit node) {
    _parentNodes = new List<ht.XmlTagNode>();
    _scripts = new List<HtmlScriptElement>();
    try {
      node.visitChildren(this);
      _htmlElement.scripts = new List.from(_scripts);
    } finally {
      _scripts = null;
      _parentNodes = null;
    }
    return null;
  }

  @override
  Object visitXmlAttributeNode(ht.XmlAttributeNode node) => null;

  @override
  Object visitXmlTagNode(ht.XmlTagNode node) {
    if (_parentNodes.contains(node)) {
      return _reportCircularity(node);
    }
    _parentNodes.add(node);
    try {
      node.visitChildren(this);
    } finally {
      _parentNodes.remove(node);
    }
    return null;
  }

  /**
   * Return the first source attribute for the given tag node, or `null` if it does not exist.
   *
   * @param node the node containing attributes
   * @return the source attribute contained in the given tag
   */
  ht.XmlAttributeNode _getScriptSourcePath(ht.XmlTagNode node) {
    for (ht.XmlAttributeNode attribute in node.attributes) {
      if (attribute.name == _SRC) {
        return attribute;
      }
    }
    return null;
  }

  Object _reportCircularity(ht.XmlTagNode node) {
    //
    // This should not be possible, but we have an error report that suggests
    // that it happened at least once. This code will guard against infinite
    // recursion and might help us identify the cause of the issue.
    //
    StringBuffer buffer = new StringBuffer();
    buffer.write("Found circularity in XML nodes: ");
    bool first = true;
    for (ht.XmlTagNode pathNode in _parentNodes) {
      if (first) {
        first = false;
      } else {
        buffer.write(", ");
      }
      String tagName = pathNode.tag;
      if (identical(pathNode, node)) {
        buffer.write("*");
        buffer.write(tagName);
        buffer.write("*");
      } else {
        buffer.write(tagName);
      }
    }
    AnalysisEngine.instance.logger.logError(buffer.toString());
    return null;
  }

  /**
   * Report an error with the given error code at the given location. Use the given arguments to
   * compose the error message.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the first character to be highlighted
   * @param length the number of characters to be highlighted
   * @param arguments the arguments used to compose the error message
   */
  void _reportErrorForOffset(
      ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError(
        _htmlElement.source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code at the location of the value of the given attribute.
   * Use the given arguments to compose the error message.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the first character to be highlighted
   * @param length the number of characters to be highlighted
   * @param arguments the arguments used to compose the error message
   */
  void _reportValueError(ErrorCode errorCode, ht.XmlAttributeNode attribute,
      List<Object> arguments) {
    int offset = attribute.valueToken.offset + 1;
    int length = attribute.valueToken.length - 2;
    _reportErrorForOffset(errorCode, offset, length, arguments);
  }
}

/**
 * Instances of the class `ImplicitLabelScope` represent the scope statements
 * that can be the target of unlabeled break and continue statements.
 */
class ImplicitLabelScope {
  /**
   * The implicit label scope associated with the top level of a function.
   */
  static const ImplicitLabelScope ROOT = const ImplicitLabelScope._(null, null);

  /**
   * The implicit label scope enclosing this implicit label scope.
   */
  final ImplicitLabelScope outerScope;

  /**
   * The statement that acts as a target for break and/or continue statements
   * at this scoping level.
   */
  final Statement statement;

  /**
   * Private constructor.
   */
  const ImplicitLabelScope._(this.outerScope, this.statement);

  /**
   * Get the statement which should be the target of an unlabeled `break` or
   * `continue` statement, or `null` if there is no appropriate target.
   */
  Statement getTarget(bool isContinue) {
    if (outerScope == null) {
      // This scope represents the toplevel of a function body, so it doesn't
      // match either break or continue.
      return null;
    }
    if (isContinue && statement is SwitchStatement) {
      return outerScope.getTarget(isContinue);
    }
    return statement;
  }

  /**
   * Initialize a newly created scope to represent a switch statement or loop
   * nested within the current scope.  [statement] is the statement associated
   * with the newly created scope.
   */
  ImplicitLabelScope nest(Statement statement) =>
      new ImplicitLabelScope._(this, statement);
}

/**
 * Instances of the class `ImportsVerifier` visit all of the referenced libraries in the
 * source code verifying that all of the imports are used, otherwise a
 * [HintCode.UNUSED_IMPORT] is generated with
 * [generateUnusedImportHints].
 *
 * While this class does not yet have support for an "Organize Imports" action, this logic built up
 * in this class could be used for such an action in the future.
 */
class ImportsVerifier /*extends RecursiveAstVisitor<Object>*/ {
  /**
   * A list of [ImportDirective]s that the current library imports, as identifiers are visited
   * by this visitor and an import has been identified as being used by the library, the
   * [ImportDirective] is removed from this list. After all the sources in the library have
   * been evaluated, this list represents the set of unused imports.
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
   * This is a map between the set of [LibraryElement]s that the current library imports, and
   * a list of [ImportDirective]s that imports the library. In cases where the current library
   * imports a library with a single directive (such as `import lib1.dart;`), the library
   * element will map to a list of one [ImportDirective], which will then be removed from the
   * [unusedImports] list. In cases where the current library imports a library with multiple
   * directives (such as `import lib1.dart; import lib1.dart show C;`), the
   * [LibraryElement] will be mapped to a list of the import directives, and the namespace
   * will need to be used to compute the correct [ImportDirective] being used, see
   * [namespaceMap].
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

  void addImports(CompilationUnit node) {
    for (Directive directive in node.directives) {
      if (directive is ImportDirective) {
        ImportDirective importDirective = directive;
        LibraryElement libraryElement = importDirective.uriElement;
        if (libraryElement != null) {
          _unusedImports.add(importDirective);
          //
          // Initialize prefixElementMap
          //
          if (importDirective.asKeyword != null) {
            SimpleIdentifier prefixIdentifier = importDirective.prefix;
            if (prefixIdentifier != null) {
              Element element = prefixIdentifier.staticElement;
              if (element is PrefixElement) {
                PrefixElement prefixElementKey = element;
                List<ImportDirective> list =
                    _prefixElementMap[prefixElementKey];
                if (list == null) {
                  list = new List<ImportDirective>();
                  _prefixElementMap[prefixElementKey] = list;
                }
                list.add(importDirective);
              }
              // TODO (jwren) Can the element ever not be a PrefixElement?
            }
          }
          //
          // Initialize libraryMap: libraryElement -> importDirective
          //
          _putIntoLibraryMap(libraryElement, importDirective);
          //
          // For this new addition to the libraryMap, also recursively add any
          // exports from the libraryElement.
          //
          _addAdditionalLibrariesForExports(
              libraryElement, importDirective, new List<LibraryElement>());
        }
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
    for (ImportDirective duplicateImport in _duplicateImports) {
      errorReporter.reportErrorForNode(
          HintCode.DUPLICATE_IMPORT, duplicateImport.uri);
    }
  }

  /**
   * After all of the compilation units have been visited by this visitor, this method can be called
   * to report an [HintCode.UNUSED_IMPORT] hint for each of the import directives in the
   * [unusedImports] list.
   *
   * @param errorReporter the error reporter to report the set of [HintCode.UNUSED_IMPORT]
   *          hints to
   */
  void generateUnusedImportHints(ErrorReporter errorReporter) {
    for (ImportDirective unusedImport in _unusedImports) {
      // Check that the import isn't dart:core
      ImportElement importElement = unusedImport.element;
      if (importElement != null) {
        LibraryElement libraryElement = importElement.importedLibrary;
        if (libraryElement != null && libraryElement.isDartCore) {
          continue;
        }
      }
      errorReporter.reportErrorForNode(
          HintCode.UNUSED_IMPORT, unusedImport.uri);
    }
  }

  /**
   * Remove elements from [_unusedImports] using the given [usedElements].
   */
  void removeUsedElements(UsedImportedElements usedElements) {
    // Stop if all the imports are known to be used.
    if (_unusedImports.isEmpty) {
      return;
    }
    // Process import prefixes.
    for (PrefixElement prefix in usedElements.prefixes) {
      List<ImportDirective> importDirectives = _prefixElementMap[prefix];
      if (importDirectives != null) {
        for (ImportDirective importDirective in importDirectives) {
          _unusedImports.remove(importDirective);
        }
      }
    }
    // Process top-level elements.
    for (Element element in usedElements.elements) {
      // Stop if all the imports are known to be used.
      if (_unusedImports.isEmpty) {
        return;
      }
      // Prepare import directives for this library.
      LibraryElement library = element.library;
      List<ImportDirective> importsLibrary = _libraryMap[library];
      if (importsLibrary == null) {
        continue;
      }
      // If there is only one import directive for this library, then it must be
      // the directive that this element is imported with, remove it from the
      // unusedImports list.
      if (importsLibrary.length == 1) {
        ImportDirective usedImportDirective = importsLibrary[0];
        _unusedImports.remove(usedImportDirective);
        continue;
      }
      // Otherwise, find import directives using namespaces.
      String name = element.displayName;
      for (ImportDirective importDirective in importsLibrary) {
        Namespace namespace = _computeNamespace(importDirective);
        if (namespace != null && namespace.get(name) != null) {
          _unusedImports.remove(importDirective);
        }
      }
    }
  }

  /**
   * Recursively add any exported library elements into the [libraryMap].
   */
  void _addAdditionalLibrariesForExports(LibraryElement library,
      ImportDirective importDirective, List<LibraryElement> exportPath) {
    if (exportPath.contains(library)) {
      return;
    }
    exportPath.add(library);
    for (LibraryElement exportedLibraryElt in library.exportedLibraries) {
      _putIntoLibraryMap(exportedLibraryElt, importDirective);
      _addAdditionalLibrariesForExports(
          exportedLibraryElt, importDirective, exportPath);
    }
  }

  /**
   * Lookup and return the [Namespace] from the [namespaceMap], if the map does not
   * have the computed namespace, compute it and cache it in the map. If the import directive is not
   * resolved or is not resolvable, `null` is returned.
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
}

/**
 * Instances of the class `InheritanceManager` manage the knowledge of where class members
 * (methods, getters & setters) are inherited from.
 */
class InheritanceManager {
  /**
   * The [LibraryElement] that is managed by this manager.
   */
  LibraryElement _library;

  /**
   * This is a mapping between each [ClassElement] and a map between the [String] member
   * names and the associated [ExecutableElement] in the mixin and superclass chain.
   */
  HashMap<ClassElement, MemberMap> _classLookup;

  /**
   * This is a mapping between each [ClassElement] and a map between the [String] member
   * names and the associated [ExecutableElement] in the interface set.
   */
  HashMap<ClassElement, MemberMap> _interfaceLookup;

  /**
   * A map between each visited [ClassElement] and the set of [AnalysisError]s found on
   * the class element.
   */
  HashMap<ClassElement, HashSet<AnalysisError>> _errorsInClassElement =
      new HashMap<ClassElement, HashSet<AnalysisError>>();

  /**
   * Initialize a newly created inheritance manager.
   *
   * @param library the library element context that the inheritance mappings are being generated
   */
  InheritanceManager(LibraryElement library) {
    this._library = library;
    _classLookup = new HashMap<ClassElement, MemberMap>();
    _interfaceLookup = new HashMap<ClassElement, MemberMap>();
  }

  /**
   * Set the new library element context.
   *
   * @param library the new library element
   */
  void set libraryElement(LibraryElement library) {
    this._library = library;
  }

  /**
   * Return the set of [AnalysisError]s found on the passed [ClassElement], or
   * `null` if there are none.
   *
   * @param classElt the class element to query
   * @return the set of [AnalysisError]s found on the passed [ClassElement], or
   *         `null` if there are none
   */
  HashSet<AnalysisError> getErrors(ClassElement classElt) =>
      _errorsInClassElement[classElt];

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed [ClassElement] superclass hierarchy, and the associated [ExecutableElement].
   *
   * @param classElt the class element to query
   * @return a mapping between the set of all members inherited from the passed [ClassElement]
   *         superclass hierarchy, and the associated [ExecutableElement]
   */
  MemberMap getMapOfMembersInheritedFromClasses(ClassElement classElt) =>
      _computeClassChainLookupMap(classElt, new HashSet<ClassElement>());

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed [ClassElement] interface hierarchy, and the associated [ExecutableElement].
   *
   * @param classElt the class element to query
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] interface hierarchy, and the associated [ExecutableElement].
   */
  MemberMap getMapOfMembersInheritedFromInterfaces(ClassElement classElt) =>
      _computeInterfaceLookupMap(classElt, new HashSet<ClassElement>());

  /**
   * Given some [ClassElement] and some member name, this returns the
   * [ExecutableElement] that the class inherits from the mixins,
   * superclasses or interfaces, that has the member name, if no member is inherited `null` is
   * returned.
   *
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or `null` if no such
   *         member exists
   */
  ExecutableElement lookupInheritance(
      ClassElement classElt, String memberName) {
    if (memberName == null || memberName.isEmpty) {
      return null;
    }
    ExecutableElement executable = _computeClassChainLookupMap(
        classElt, new HashSet<ClassElement>()).get(memberName);
    if (executable == null) {
      return _computeInterfaceLookupMap(classElt, new HashSet<ClassElement>())
          .get(memberName);
    }
    return executable;
  }

  /**
   * Given some [ClassElement] and some member name, this returns the
   * [ExecutableElement] that the class either declares itself, or
   * inherits, that has the member name, if no member is inherited `null` is returned.
   *
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or `null` if no such
   *         member exists
   */
  ExecutableElement lookupMember(ClassElement classElt, String memberName) {
    ExecutableElement element = _lookupMemberInClass(classElt, memberName);
    if (element != null) {
      return element;
    }
    return lookupInheritance(classElt, memberName);
  }

  /**
   * Given some [InterfaceType] and some member name, this returns the
   * [FunctionType] of the [ExecutableElement] that the
   * class either declares itself, or inherits, that has the member name, if no member is inherited
   * `null` is returned. The returned [FunctionType] has all type
   * parameters substituted with corresponding type arguments from the given [InterfaceType].
   *
   * @param interfaceType the interface type to query
   * @param memberName the name of the executable element to find and return
   * @return the member's function type, or `null` if no such member exists
   */
  FunctionType lookupMemberType(
      InterfaceType interfaceType, String memberName) {
    ExecutableElement iteratorMember =
        lookupMember(interfaceType.element, memberName);
    if (iteratorMember == null) {
      return null;
    }
    return substituteTypeArgumentsInMemberFromInheritance(
        iteratorMember.type, memberName, interfaceType);
  }

  /**
   * Determine the set of methods which is overridden by the given class member. If no member is
   * inherited, an empty list is returned. If one of the inherited members is a
   * [MultiplyInheritedExecutableElement], then it is expanded into its constituent inherited
   * elements.
   *
   * @param classElt the class to query
   * @param memberName the name of the class member to query
   * @return a list of overridden methods
   */
  List<ExecutableElement> lookupOverrides(
      ClassElement classElt, String memberName) {
    List<ExecutableElement> result = new List<ExecutableElement>();
    if (memberName == null || memberName.isEmpty) {
      return result;
    }
    List<MemberMap> interfaceMaps =
        _gatherInterfaceLookupMaps(classElt, new HashSet<ClassElement>());
    if (interfaceMaps != null) {
      for (MemberMap interfaceMap in interfaceMaps) {
        ExecutableElement overriddenElement = interfaceMap.get(memberName);
        if (overriddenElement != null) {
          if (overriddenElement is MultiplyInheritedExecutableElement) {
            MultiplyInheritedExecutableElement multiplyInheritedElement =
                overriddenElement;
            for (ExecutableElement element
                in multiplyInheritedElement.inheritedElements) {
              result.add(element);
            }
          } else {
            result.add(overriddenElement);
          }
        }
      }
    }
    return result;
  }

  /**
   * This method takes some inherited [FunctionType], and resolves all the parameterized types
   * in the function type, dependent on the class in which it is being overridden.
   *
   * @param baseFunctionType the function type that is being overridden
   * @param memberName the name of the member, this is used to lookup the inheritance path of the
   *          override
   * @param definingType the type that is overriding the member
   * @return the passed function type with any parameterized types substituted
   */
  FunctionType substituteTypeArgumentsInMemberFromInheritance(
      FunctionType baseFunctionType,
      String memberName,
      InterfaceType definingType) {
    // if the baseFunctionType is null, or does not have any parameters,
    // return it.
    if (baseFunctionType == null ||
        baseFunctionType.typeArguments.length == 0) {
      return baseFunctionType;
    }
    // First, generate the path from the defining type to the overridden member
    Queue<InterfaceType> inheritancePath = new Queue<InterfaceType>();
    _computeInheritancePath(inheritancePath, definingType, memberName);
    if (inheritancePath == null || inheritancePath.isEmpty) {
      // TODO(jwren) log analysis engine error
      return baseFunctionType;
    }
    FunctionType functionTypeToReturn = baseFunctionType;
    // loop backward through the list substituting as we go:
    while (!inheritancePath.isEmpty) {
      InterfaceType lastType = inheritancePath.removeLast();
      List<DartType> parameterTypes = lastType.element.type.typeArguments;
      List<DartType> argumentTypes = lastType.typeArguments;
      functionTypeToReturn =
          functionTypeToReturn.substitute2(argumentTypes, parameterTypes);
    }
    return functionTypeToReturn;
  }

  /**
   * Compute and return a mapping between the set of all string names of the members inherited from
   * the passed [ClassElement] superclass hierarchy, and the associated
   * [ExecutableElement].
   *
   * @param classElt the class element to query
   * @param visitedClasses a set of visited classes passed back into this method when it calls
   *          itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] superclass hierarchy, and the associated [ExecutableElement]
   */
  MemberMap _computeClassChainLookupMap(
      ClassElement classElt, HashSet<ClassElement> visitedClasses) {
    MemberMap resultMap = _classLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    } else {
      resultMap = new MemberMap();
    }
    ClassElement superclassElt = null;
    InterfaceType supertype = classElt.supertype;
    if (supertype != null) {
      superclassElt = supertype.element;
    } else {
      // classElt is Object
      _classLookup[classElt] = resultMap;
      return resultMap;
    }
    if (superclassElt != null) {
      if (!visitedClasses.contains(superclassElt)) {
        visitedClasses.add(superclassElt);
        try {
          resultMap = new MemberMap.from(
              _computeClassChainLookupMap(superclassElt, visitedClasses));
          //
          // Substitute the super types down the hierarchy.
          //
          _substituteTypeParametersDownHierarchy(supertype, resultMap);
          //
          // Include the members from the superclass in the resultMap.
          //
          _recordMapWithClassMembers(resultMap, supertype, false);
        } finally {
          visitedClasses.remove(superclassElt);
        }
      } else {
        // This case happens only when the superclass was previously visited and
        // not in the lookup, meaning this is meant to shorten the compute for
        // recursive cases.
        _classLookup[superclassElt] = resultMap;
        return resultMap;
      }
    }
    //
    // Include the members from the mixins in the resultMap.  If there are
    // multiple mixins, visit them in the order listed so that methods in later
    // mixins will overwrite identically-named methods in earlier mixins.
    //
    List<InterfaceType> mixins = classElt.mixins;
    for (InterfaceType mixin in mixins) {
      ClassElement mixinElement = mixin.element;
      if (mixinElement != null) {
        if (!visitedClasses.contains(mixinElement)) {
          visitedClasses.add(mixinElement);
          try {
            MemberMap map = new MemberMap.from(
                _computeClassChainLookupMap(mixinElement, visitedClasses));
            //
            // Substitute the super types down the hierarchy.
            //
            _substituteTypeParametersDownHierarchy(mixin, map);
            //
            // Include the members from the superclass in the resultMap.
            //
            _recordMapWithClassMembers(map, mixin, false);
            //
            // Add the members from map into result map.
            //
            for (int j = 0; j < map.size; j++) {
              String key = map.getKey(j);
              ExecutableElement value = map.getValue(j);
              if (key != null) {
                ClassElement definingClass = value
                    .getAncestor((Element element) => element is ClassElement);
                if (!definingClass.type.isObject) {
                  ExecutableElement existingValue = resultMap.get(key);
                  if (existingValue == null ||
                      (existingValue != null && !_isAbstract(value))) {
                    resultMap.put(key, value);
                  }
                }
              }
            }
          } finally {
            visitedClasses.remove(mixinElement);
          }
        } else {
          // This case happens only when the superclass was previously visited
          // and not in the lookup, meaning this is meant to shorten the compute
          // for recursive cases.
          _classLookup[mixinElement] = resultMap;
          return resultMap;
        }
      }
    }
    _classLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Compute and return the inheritance path given the context of a type and a member that is
   * overridden in the inheritance path (for which the type is in the path).
   *
   * @param chain the inheritance path that is built up as this method calls itself recursively,
   *          when this method is called an empty [LinkedList] should be provided
   * @param currentType the current type in the inheritance path
   * @param memberName the name of the member that is being looked up the inheritance path
   */
  void _computeInheritancePath(Queue<InterfaceType> chain,
      InterfaceType currentType, String memberName) {
    // TODO (jwren) create a public version of this method which doesn't require
    // the initial chain to be provided, then provided tests for this
    // functionality in InheritanceManagerTest
    chain.add(currentType);
    ClassElement classElt = currentType.element;
    InterfaceType supertype = classElt.supertype;
    // Base case- reached Object
    if (supertype == null) {
      // Looked up the chain all the way to Object, return null.
      // This should never happen.
      return;
    }
    // If we are done, return the chain
    // We are not done if this is the first recursive call on this method.
    if (chain.length != 1) {
      // We are done however if the member is in this classElt
      if (_lookupMemberInClass(classElt, memberName) != null) {
        return;
      }
    }
    // Mixins- note that mixins call lookupMemberInClass, not lookupMember
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = mixins.length - 1; i >= 0; i--) {
      ClassElement mixinElement = mixins[i].element;
      if (mixinElement != null) {
        ExecutableElement elt = _lookupMemberInClass(mixinElement, memberName);
        if (elt != null) {
          // this is equivalent (but faster than) calling this method
          // recursively
          // (return computeInheritancePath(chain, mixins[i], memberName);)
          chain.add(mixins[i]);
          return;
        }
      }
    }
    // Superclass
    ClassElement superclassElt = supertype.element;
    if (lookupMember(superclassElt, memberName) != null) {
      _computeInheritancePath(chain, supertype, memberName);
      return;
    }
    // Interfaces
    List<InterfaceType> interfaces = classElt.interfaces;
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null &&
          lookupMember(interfaceElement, memberName) != null) {
        _computeInheritancePath(chain, interfaceType, memberName);
        return;
      }
    }
  }

  /**
   * Compute and return a mapping between the set of all string names of the members inherited from
   * the passed [ClassElement] interface hierarchy, and the associated
   * [ExecutableElement].
   *
   * @param classElt the class element to query
   * @param visitedInterfaces a set of visited classes passed back into this method when it calls
   *          itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] interface hierarchy, and the associated [ExecutableElement]
   */
  MemberMap _computeInterfaceLookupMap(
      ClassElement classElt, HashSet<ClassElement> visitedInterfaces) {
    MemberMap resultMap = _interfaceLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    }
    List<MemberMap> lookupMaps =
        _gatherInterfaceLookupMaps(classElt, visitedInterfaces);
    if (lookupMaps == null) {
      resultMap = new MemberMap();
    } else {
      HashMap<String, List<ExecutableElement>> unionMap =
          _unionInterfaceLookupMaps(lookupMaps);
      resultMap = _resolveInheritanceLookup(classElt, unionMap);
    }
    _interfaceLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Collect a list of interface lookup maps whose elements correspond to all of the classes
   * directly above [classElt] in the class hierarchy (the direct superclass if any, all
   * mixins, and all direct superinterfaces). Each item in the list is the interface lookup map
   * returned by [computeInterfaceLookupMap] for the corresponding super, except with type
   * parameters appropriately substituted.
   *
   * @param classElt the class element to query
   * @param visitedInterfaces a set of visited classes passed back into this method when it calls
   *          itself recursively
   * @return `null` if there was a problem (such as a loop in the class hierarchy) or if there
   *         are no classes above this one in the class hierarchy. Otherwise, a list of interface
   *         lookup maps.
   */
  List<MemberMap> _gatherInterfaceLookupMaps(
      ClassElement classElt, HashSet<ClassElement> visitedInterfaces) {
    InterfaceType supertype = classElt.supertype;
    ClassElement superclassElement =
        supertype != null ? supertype.element : null;
    List<InterfaceType> mixins = classElt.mixins;
    List<InterfaceType> interfaces = classElt.interfaces;
    // Recursively collect the list of mappings from all of the interface types
    List<MemberMap> lookupMaps = new List<MemberMap>();
    //
    // Superclass element
    //
    if (superclassElement != null) {
      if (!visitedInterfaces.contains(superclassElement)) {
        try {
          visitedInterfaces.add(superclassElement);
          //
          // Recursively compute the map for the super type.
          //
          MemberMap map =
              _computeInterfaceLookupMap(superclassElement, visitedInterfaces);
          map = new MemberMap.from(map);
          //
          // Substitute the super type down the hierarchy.
          //
          _substituteTypeParametersDownHierarchy(supertype, map);
          //
          // Add any members from the super type into the map as well.
          //
          _recordMapWithClassMembers(map, supertype, true);
          lookupMaps.add(map);
        } finally {
          visitedInterfaces.remove(superclassElement);
        }
      } else {
        return null;
      }
    }
    //
    // Mixin elements
    //
    for (int i = mixins.length - 1; i >= 0; i--) {
      InterfaceType mixinType = mixins[i];
      ClassElement mixinElement = mixinType.element;
      if (mixinElement != null) {
        if (!visitedInterfaces.contains(mixinElement)) {
          try {
            visitedInterfaces.add(mixinElement);
            //
            // Recursively compute the map for the mixin.
            //
            MemberMap map =
                _computeInterfaceLookupMap(mixinElement, visitedInterfaces);
            map = new MemberMap.from(map);
            //
            // Substitute the mixin type down the hierarchy.
            //
            _substituteTypeParametersDownHierarchy(mixinType, map);
            //
            // Add any members from the mixin type into the map as well.
            //
            _recordMapWithClassMembers(map, mixinType, true);
            lookupMaps.add(map);
          } finally {
            visitedInterfaces.remove(mixinElement);
          }
        } else {
          return null;
        }
      }
    }
    //
    // Interface elements
    //
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        if (!visitedInterfaces.contains(interfaceElement)) {
          try {
            visitedInterfaces.add(interfaceElement);
            //
            // Recursively compute the map for the interfaces.
            //
            MemberMap map =
                _computeInterfaceLookupMap(interfaceElement, visitedInterfaces);
            map = new MemberMap.from(map);
            //
            // Substitute the supertypes down the hierarchy
            //
            _substituteTypeParametersDownHierarchy(interfaceType, map);
            //
            // And add any members from the interface into the map as well.
            //
            _recordMapWithClassMembers(map, interfaceType, true);
            lookupMaps.add(map);
          } finally {
            visitedInterfaces.remove(interfaceElement);
          }
        } else {
          return null;
        }
      }
    }
    if (lookupMaps.length == 0) {
      return null;
    }
    return lookupMaps;
  }

  /**
   * Given some [ClassElement], this method finds and returns the [ExecutableElement] of
   * the passed name in the class element. Static members, members in super types and members not
   * accessible from the current library are not considered.
   *
   * @param classElt the class element to query
   * @param memberName the name of the member to lookup in the class
   * @return the found [ExecutableElement], or `null` if no such member was found
   */
  ExecutableElement _lookupMemberInClass(
      ClassElement classElt, String memberName) {
    List<MethodElement> methods = classElt.methods;
    for (MethodElement method in methods) {
      if (memberName == method.name &&
          method.isAccessibleIn(_library) &&
          !method.isStatic) {
        return method;
      }
    }
    List<PropertyAccessorElement> accessors = classElt.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (memberName == accessor.name &&
          accessor.isAccessibleIn(_library) &&
          !accessor.isStatic) {
        return accessor;
      }
    }
    return null;
  }

  /**
   * Record the passed map with the set of all members (methods, getters and setters) in the type
   * into the passed map.
   *
   * @param map some non-`null` map to put the methods and accessors from the passed
   *          [ClassElement] into
   * @param type the type that will be recorded into the passed map
   * @param doIncludeAbstract `true` if abstract members will be put into the map
   */
  void _recordMapWithClassMembers(
      MemberMap map, InterfaceType type, bool doIncludeAbstract) {
    List<MethodElement> methods = type.methods;
    for (MethodElement method in methods) {
      if (method.isAccessibleIn(_library) &&
          !method.isStatic &&
          (doIncludeAbstract || !method.isAbstract)) {
        map.put(method.name, method);
      }
    }
    List<PropertyAccessorElement> accessors = type.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isAccessibleIn(_library) &&
          !accessor.isStatic &&
          (doIncludeAbstract || !accessor.isAbstract)) {
        map.put(accessor.name, accessor);
      }
    }
  }

  /**
   * This method is used to report errors on when they are found computing inheritance information.
   * See [ErrorVerifier.checkForInconsistentMethodInheritance] to see where these generated
   * error codes are reported back into the analysis engine.
   *
   * @param classElt the location of the source for which the exception occurred
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  void _reportError(ClassElement classElt, int offset, int length,
      ErrorCode errorCode, List<Object> arguments) {
    HashSet<AnalysisError> errorSet = _errorsInClassElement[classElt];
    if (errorSet == null) {
      errorSet = new HashSet<AnalysisError>();
      _errorsInClassElement[classElt] = errorSet;
    }
    errorSet.add(new AnalysisError(
        classElt.source, offset, length, errorCode, arguments));
  }

  /**
   * Given the set of methods defined by classes above [classElt] in the class hierarchy,
   * apply the appropriate inheritance rules to determine those methods inherited by or overridden
   * by [classElt]. Also report static warnings
   * [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE] and
   * [StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD] if appropriate.
   *
   * @param classElt the class element to query.
   * @param unionMap a mapping from method name to the set of unique (in terms of signature) methods
   *          defined in superclasses of [classElt].
   * @return the inheritance lookup map for [classElt].
   */
  MemberMap _resolveInheritanceLookup(ClassElement classElt,
      HashMap<String, List<ExecutableElement>> unionMap) {
    MemberMap resultMap = new MemberMap();
    unionMap.forEach((String key, List<ExecutableElement> list) {
      int numOfEltsWithMatchingNames = list.length;
      if (numOfEltsWithMatchingNames == 1) {
        //
        // Example: class A inherits only 1 method named 'm'.
        // Since it is the only such method, it is inherited.
        // Another example: class A inherits 2 methods named 'm' from 2
        // different interfaces, but they both have the same signature, so it is
        // the method inherited.
        //
        resultMap.put(key, list[0]);
      } else {
        //
        // Then numOfEltsWithMatchingNames > 1, check for the warning cases.
        //
        bool allMethods = true;
        bool allSetters = true;
        bool allGetters = true;
        for (ExecutableElement executableElement in list) {
          if (executableElement is PropertyAccessorElement) {
            allMethods = false;
            if (executableElement.isSetter) {
              allGetters = false;
            } else {
              allSetters = false;
            }
          } else {
            allGetters = false;
            allSetters = false;
          }
        }
        //
        // If there isn't a mixture of methods with getters, then continue,
        // otherwise create a warning.
        //
        if (allMethods || allGetters || allSetters) {
          //
          // Compute the element whose type is the subtype of all of the other
          // types.
          //
          List<ExecutableElement> elements = new List.from(list);
          List<FunctionType> executableElementTypes =
              new List<FunctionType>(numOfEltsWithMatchingNames);
          for (int i = 0; i < numOfEltsWithMatchingNames; i++) {
            executableElementTypes[i] = elements[i].type;
          }
          List<int> subtypesOfAllOtherTypesIndexes = new List<int>();
          for (int i = 0; i < numOfEltsWithMatchingNames; i++) {
            FunctionType subtype = executableElementTypes[i];
            if (subtype == null) {
              continue;
            }
            bool subtypeOfAllTypes = true;
            for (int j = 0;
                j < numOfEltsWithMatchingNames && subtypeOfAllTypes;
                j++) {
              if (i != j) {
                if (!subtype.isSubtypeOf(executableElementTypes[j])) {
                  subtypeOfAllTypes = false;
                  break;
                }
              }
            }
            if (subtypeOfAllTypes) {
              subtypesOfAllOtherTypesIndexes.add(i);
            }
          }
          //
          // The following is split into three cases determined by the number of
          // elements in subtypesOfAllOtherTypes
          //
          if (subtypesOfAllOtherTypesIndexes.length == 1) {
            //
            // Example: class A inherited only 2 method named 'm'.
            // One has the function type '() -> dynamic' and one has the
            // function type '([int]) -> dynamic'. Since the second method is a
            // subtype of all the others, it is the inherited method.
            // Tests: InheritanceManagerTest.
            // test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_*
            //
            resultMap.put(key, elements[subtypesOfAllOtherTypesIndexes[0]]);
          } else {
            if (subtypesOfAllOtherTypesIndexes.isEmpty) {
              //
              // Determine if the current class has a method or accessor with
              // the member name, if it does then then this class does not
              // "inherit" from any of the supertypes. See issue 16134.
              //
              bool classHasMember = false;
              if (allMethods) {
                classHasMember = classElt.getMethod(key) != null;
              } else {
                List<PropertyAccessorElement> accessors = classElt.accessors;
                for (int i = 0; i < accessors.length; i++) {
                  if (accessors[i].name == key) {
                    classHasMember = true;
                  }
                }
              }
              //
              // Example: class A inherited only 2 method named 'm'.
              // One has the function type '() -> int' and one has the function
              // type '() -> String'. Since neither is a subtype of the other,
              // we create a warning, and have this class inherit nothing.
              //
              if (!classHasMember) {
                String firstTwoFuntionTypesStr =
                    "${executableElementTypes[0]}, ${executableElementTypes[1]}";
                _reportError(
                    classElt,
                    classElt.nameOffset,
                    classElt.displayName.length,
                    StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE,
                    [key, firstTwoFuntionTypesStr]);
              }
            } else {
              //
              // Example: class A inherits 2 methods named 'm'.
              // One has the function type '(int) -> dynamic' and one has the
              // function type '(num) -> dynamic'. Since they are both a subtype
              // of the other, a synthetic function '(dynamic) -> dynamic' is
              // inherited.
              // Tests: test_getMapOfMembersInheritedFromInterfaces_
              // union_multipleSubtypes_*
              //
              List<ExecutableElement> elementArrayToMerge = new List<
                  ExecutableElement>(subtypesOfAllOtherTypesIndexes.length);
              for (int i = 0; i < elementArrayToMerge.length; i++) {
                elementArrayToMerge[i] =
                    elements[subtypesOfAllOtherTypesIndexes[i]];
              }
              ExecutableElement mergedExecutableElement =
                  _computeMergedExecutableElement(elementArrayToMerge);
              resultMap.put(key, mergedExecutableElement);
            }
          }
        } else {
          _reportError(
              classElt,
              classElt.nameOffset,
              classElt.displayName.length,
              StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD,
              [key]);
        }
      }
    });
    return resultMap;
  }

  /**
   * Loop through all of the members in some [MemberMap], performing type parameter
   * substitutions using a passed supertype.
   *
   * @param superType the supertype to substitute into the members of the [MemberMap]
   * @param map the MemberMap to perform the substitutions on
   */
  void _substituteTypeParametersDownHierarchy(
      InterfaceType superType, MemberMap map) {
    for (int i = 0; i < map.size; i++) {
      ExecutableElement executableElement = map.getValue(i);
      if (executableElement is MethodMember) {
        executableElement =
            MethodMember.from(executableElement as MethodMember, superType);
        map.setValue(i, executableElement);
      } else if (executableElement is PropertyAccessorMember) {
        executableElement = PropertyAccessorMember.from(
            executableElement as PropertyAccessorMember, superType);
        map.setValue(i, executableElement);
      }
    }
  }

  /**
   * Union all of the [lookupMaps] together into a single map, grouping the ExecutableElements
   * into a list where none of the elements are equal where equality is determined by having equal
   * function types. (We also take note too of the kind of the element: ()->int and () -> int may
   * not be equal if one is a getter and the other is a method.)
   *
   * @param lookupMaps the maps to be unioned together.
   * @return the resulting union map.
   */
  HashMap<String, List<ExecutableElement>> _unionInterfaceLookupMaps(
      List<MemberMap> lookupMaps) {
    HashMap<String, List<ExecutableElement>> unionMap =
        new HashMap<String, List<ExecutableElement>>();
    for (MemberMap lookupMap in lookupMaps) {
      int lookupMapSize = lookupMap.size;
      for (int i = 0; i < lookupMapSize; i++) {
        // Get the string key, if null, break.
        String key = lookupMap.getKey(i);
        if (key == null) {
          break;
        }
        // Get the list value out of the unionMap
        List<ExecutableElement> list = unionMap[key];
        // If we haven't created such a map for this key yet, do create it and
        // put the list entry into the unionMap.
        if (list == null) {
          list = new List<ExecutableElement>();
          unionMap[key] = list;
        }
        // Fetch the entry out of this lookupMap
        ExecutableElement newExecutableElementEntry = lookupMap.getValue(i);
        if (list.isEmpty) {
          // If the list is empty, just the new value
          list.add(newExecutableElementEntry);
        } else {
          // Otherwise, only add the newExecutableElementEntry if it isn't
          // already in the list, this covers situation where a class inherits
          // two methods (or two getters) that are identical.
          bool alreadyInList = false;
          bool isMethod1 = newExecutableElementEntry is MethodElement;
          for (ExecutableElement executableElementInList in list) {
            bool isMethod2 = executableElementInList is MethodElement;
            if (isMethod1 == isMethod2 &&
                executableElementInList.type ==
                    newExecutableElementEntry.type) {
              alreadyInList = true;
              break;
            }
          }
          if (!alreadyInList) {
            list.add(newExecutableElementEntry);
          }
        }
      }
    }
    return unionMap;
  }

  /**
   * Given some array of [ExecutableElement]s, this method creates a synthetic element as
   * described in 8.1.1:
   *
   * Let <i>numberOfPositionals</i>(<i>f</i>) denote the number of positional parameters of a
   * function <i>f</i>, and let <i>numberOfRequiredParams</i>(<i>f</i>) denote the number of
   * required parameters of a function <i>f</i>. Furthermore, let <i>s</i> denote the set of all
   * named parameters of the <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i>. Then let
   * * <i>h = max(numberOfPositionals(m<sub>i</sub>)),</i>
   * * <i>r = min(numberOfRequiredParams(m<sub>i</sub>)), for all <i>i</i>, 1 <= i <= k.</i>
   * Then <i>I</i> has a method named <i>n</i>, with <i>r</i> required parameters of type
   * <b>dynamic</b>, <i>h</i> positional parameters of type <b>dynamic</b>, named parameters
   * <i>s</i> of type <b>dynamic</b> and return type <b>dynamic</b>.
   *
   */
  static ExecutableElement _computeMergedExecutableElement(
      List<ExecutableElement> elementArrayToMerge) {
    int h = _getNumOfPositionalParameters(elementArrayToMerge[0]);
    int r = _getNumOfRequiredParameters(elementArrayToMerge[0]);
    Set<String> namedParametersList = new HashSet<String>();
    for (int i = 1; i < elementArrayToMerge.length; i++) {
      ExecutableElement element = elementArrayToMerge[i];
      int numOfPositionalParams = _getNumOfPositionalParameters(element);
      if (h < numOfPositionalParams) {
        h = numOfPositionalParams;
      }
      int numOfRequiredParams = _getNumOfRequiredParameters(element);
      if (r > numOfRequiredParams) {
        r = numOfRequiredParams;
      }
      namedParametersList.addAll(_getNamedParameterNames(element));
    }
    return _createSyntheticExecutableElement(
        elementArrayToMerge,
        elementArrayToMerge[0].displayName,
        r,
        h - r,
        new List.from(namedParametersList));
  }

  /**
   * Used by [computeMergedExecutableElement] to actually create the
   * synthetic element.
   *
   * @param elementArrayToMerge the array used to create the synthetic element
   * @param name the name of the method, getter or setter
   * @param numOfRequiredParameters the number of required parameters
   * @param numOfPositionalParameters the number of positional parameters
   * @param namedParameters the list of [String]s that are the named parameters
   * @return the created synthetic element
   */
  static ExecutableElement _createSyntheticExecutableElement(
      List<ExecutableElement> elementArrayToMerge,
      String name,
      int numOfRequiredParameters,
      int numOfPositionalParameters,
      List<String> namedParameters) {
    DynamicTypeImpl dynamicType = DynamicTypeImpl.instance;
    SimpleIdentifier nameIdentifier = new SimpleIdentifier(
        new sc.StringToken(sc.TokenType.IDENTIFIER, name, 0));
    ExecutableElementImpl executable;
    if (elementArrayToMerge[0] is MethodElement) {
      MultiplyInheritedMethodElementImpl unionedMethod =
          new MultiplyInheritedMethodElementImpl(nameIdentifier);
      unionedMethod.inheritedElements = elementArrayToMerge;
      executable = unionedMethod;
    } else {
      MultiplyInheritedPropertyAccessorElementImpl unionedPropertyAccessor =
          new MultiplyInheritedPropertyAccessorElementImpl(nameIdentifier);
      unionedPropertyAccessor.getter =
          (elementArrayToMerge[0] as PropertyAccessorElement).isGetter;
      unionedPropertyAccessor.setter =
          (elementArrayToMerge[0] as PropertyAccessorElement).isSetter;
      unionedPropertyAccessor.inheritedElements = elementArrayToMerge;
      executable = unionedPropertyAccessor;
    }
    int numOfParameters = numOfRequiredParameters +
        numOfPositionalParameters +
        namedParameters.length;
    List<ParameterElement> parameters =
        new List<ParameterElement>(numOfParameters);
    int i = 0;
    for (int j = 0; j < numOfRequiredParameters; j++, i++) {
      ParameterElementImpl parameter = new ParameterElementImpl("", 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    for (int k = 0; k < numOfPositionalParameters; k++, i++) {
      ParameterElementImpl parameter = new ParameterElementImpl("", 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.POSITIONAL;
      parameters[i] = parameter;
    }
    for (int m = 0; m < namedParameters.length; m++, i++) {
      ParameterElementImpl parameter =
          new ParameterElementImpl(namedParameters[m], 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.NAMED;
      parameters[i] = parameter;
    }
    executable.returnType = dynamicType;
    executable.parameters = parameters;
    FunctionTypeImpl methodType = new FunctionTypeImpl(executable);
    executable.type = methodType;
    return executable;
  }

  /**
   * Given some [ExecutableElement], return the list of named parameters.
   */
  static List<String> _getNamedParameterNames(
      ExecutableElement executableElement) {
    List<String> namedParameterNames = new List<String>();
    List<ParameterElement> parameters = executableElement.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameterElement = parameters[i];
      if (parameterElement.parameterKind == ParameterKind.NAMED) {
        namedParameterNames.add(parameterElement.name);
      }
    }
    return namedParameterNames;
  }

  /**
   * Given some [ExecutableElement] return the number of parameters of the specified kind.
   */
  static int _getNumOfParameters(
      ExecutableElement executableElement, ParameterKind parameterKind) {
    int parameterCount = 0;
    List<ParameterElement> parameters = executableElement.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameterElement = parameters[i];
      if (parameterElement.parameterKind == parameterKind) {
        parameterCount++;
      }
    }
    return parameterCount;
  }

  /**
   * Given some [ExecutableElement] return the number of positional parameters.
   *
   * Note: by positional we mean [ParameterKind.REQUIRED] or [ParameterKind.POSITIONAL].
   */
  static int _getNumOfPositionalParameters(
          ExecutableElement executableElement) =>
      _getNumOfParameters(executableElement, ParameterKind.REQUIRED) +
          _getNumOfParameters(executableElement, ParameterKind.POSITIONAL);

  /**
   * Given some [ExecutableElement] return the number of required parameters.
   */
  static int _getNumOfRequiredParameters(ExecutableElement executableElement) =>
      _getNumOfParameters(executableElement, ParameterKind.REQUIRED);

  /**
   * Given some [ExecutableElement] returns `true` if it is an abstract member of a
   * class.
   *
   * @param executableElement some [ExecutableElement] to evaluate
   * @return `true` if the given element is an abstract member of a class
   */
  static bool _isAbstract(ExecutableElement executableElement) {
    if (executableElement is MethodElement) {
      return executableElement.isAbstract;
    } else if (executableElement is PropertyAccessorElement) {
      return executableElement.isAbstract;
    }
    return false;
  }
}

/**
 * This enum holds one of four states of a field initialization state through a constructor
 * signature, not initialized, initialized in the field declaration, initialized in the field
 * formal, and finally, initialized in the initializers list.
 */
class INIT_STATE extends Enum<INIT_STATE> {
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

  const INIT_STATE(String name, int ordinal) : super(name, ordinal);
}

/**
 * Instances of the class `LabelScope` represent a scope in which a single label is defined.
 */
class LabelScope {
  /**
   * The label scope enclosing this label scope.
   */
  final LabelScope _outerScope;

  /**
   * The label defined in this scope.
   */
  final String _label;

  /**
   * The element to which the label resolves.
   */
  final LabelElement element;

  /**
   * The AST node to which the label resolves.
   */
  final AstNode node;

  /**
   * Initialize a newly created scope to represent the label [_label].
   * [_outerScope] is the scope enclosing the new label scope.  [node] is the
   * AST node the label resolves to.  [element] is the element the label
   * resolves to.
   */
  LabelScope(this._outerScope, this._label, this.node, this.element);

  /**
   * Return the LabelScope which defines [targetLabel], or `null` if it is not
   * defined in this scope.
   */
  LabelScope lookup(String targetLabel) {
    if (_label == targetLabel) {
      return this;
    } else if (_outerScope != null) {
      return _outerScope.lookup(targetLabel);
    } else {
      return null;
    }
  }
}

/**
 * Instances of the class `Library` represent the data about a single library during the
 * resolution of some (possibly different) library. They are not intended to be used except during
 * the resolution process.
 */
class Library {
  /**
   * An empty list that can be used to initialize lists of libraries.
   */
  static const List<Library> _EMPTY_ARRAY = const <Library>[];

  /**
   * The prefix of a URI using the dart-ext scheme to reference a native code library.
   */
  static String _DART_EXT_SCHEME = "dart-ext:";

  /**
   * The analysis context in which this library is being analyzed.
   */
  final InternalAnalysisContext _analysisContext;

  /**
   * The inheritance manager which is used for this member lookups in this library.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The listener to which analysis errors will be reported.
   */
  final AnalysisErrorListener errorListener;

  /**
   * The source specifying the defining compilation unit of this library.
   */
  final Source librarySource;

  /**
   * The library element representing this library.
   */
  LibraryElementImpl _libraryElement;

  /**
   * A list containing all of the libraries that are imported into this library.
   */
  List<Library> _importedLibraries = _EMPTY_ARRAY;

  /**
   * A table mapping URI-based directive to the actual URI value.
   */
  HashMap<UriBasedDirective, String> _directiveUris =
      new HashMap<UriBasedDirective, String>();

  /**
   * A flag indicating whether this library explicitly imports core.
   */
  bool explicitlyImportsCore = false;

  /**
   * A list containing all of the libraries that are exported from this library.
   */
  List<Library> _exportedLibraries = _EMPTY_ARRAY;

  /**
   * A table mapping the sources for the compilation units in this library to their corresponding
   * AST structures.
   */
  HashMap<Source, CompilationUnit> _astMap =
      new HashMap<Source, CompilationUnit>();

  /**
   * The library scope used when resolving elements within this library's compilation units.
   */
  LibraryScope _libraryScope;

  /**
   * Initialize a newly created data holder that can maintain the data associated with a library.
   *
   * @param analysisContext the analysis context in which this library is being analyzed
   * @param errorListener the listener to which analysis errors will be reported
   * @param librarySource the source specifying the defining compilation unit of this library
   */
  Library(this._analysisContext, this.errorListener, this.librarySource) {
    this._libraryElement =
        _analysisContext.getLibraryElement(librarySource) as LibraryElementImpl;
  }

  /**
   * Return an array of the [CompilationUnit]s that make up the library. The first unit is
   * always the defining unit.
   *
   * @return an array of the [CompilationUnit]s that make up the library. The first unit is
   *         always the defining unit
   */
  List<CompilationUnit> get compilationUnits {
    List<CompilationUnit> unitArrayList = new List<CompilationUnit>();
    unitArrayList.add(definingCompilationUnit);
    for (Source source in _astMap.keys.toSet()) {
      if (librarySource != source) {
        unitArrayList.add(getAST(source));
      }
    }
    return unitArrayList;
  }

  /**
   * Return a collection containing the sources for the compilation units in this library, including
   * the defining compilation unit.
   *
   * @return the sources for the compilation units in this library
   */
  Set<Source> get compilationUnitSources => _astMap.keys.toSet();

  /**
   * Return the AST structure associated with the defining compilation unit for this library.
   *
   * @return the AST structure associated with the defining compilation unit for this library
   * @throws AnalysisException if an AST structure could not be created for the defining compilation
   *           unit
   */
  CompilationUnit get definingCompilationUnit => getAST(librarySource);

  /**
   * Set the libraries that are exported by this library to be those in the given array.
   *
   * @param exportedLibraries the libraries that are exported by this library
   */
  void set exportedLibraries(List<Library> exportedLibraries) {
    this._exportedLibraries = exportedLibraries;
  }

  /**
   * Return an array containing the libraries that are exported from this library.
   *
   * @return an array containing the libraries that are exported from this library
   */
  List<Library> get exports => _exportedLibraries;

  /**
   * Set the libraries that are imported into this library to be those in the given array.
   *
   * @param importedLibraries the libraries that are imported into this library
   */
  void set importedLibraries(List<Library> importedLibraries) {
    this._importedLibraries = importedLibraries;
  }

  /**
   * Return an array containing the libraries that are imported into this library.
   *
   * @return an array containing the libraries that are imported into this library
   */
  List<Library> get imports => _importedLibraries;

  /**
   * Return an array containing the libraries that are either imported or exported from this
   * library.
   *
   * @return the libraries that are either imported or exported from this library
   */
  List<Library> get importsAndExports {
    HashSet<Library> libraries = new HashSet<Library>();
    for (Library library in _importedLibraries) {
      libraries.add(library);
    }
    for (Library library in _exportedLibraries) {
      libraries.add(library);
    }
    return new List.from(libraries);
  }

  /**
   * Return the inheritance manager for this library.
   *
   * @return the inheritance manager for this library
   */
  InheritanceManager get inheritanceManager {
    if (_inheritanceManager == null) {
      return _inheritanceManager = new InheritanceManager(_libraryElement);
    }
    return _inheritanceManager;
  }

  /**
   * Return the library element representing this library, creating it if necessary.
   *
   * @return the library element representing this library
   */
  LibraryElementImpl get libraryElement {
    if (_libraryElement == null) {
      try {
        _libraryElement = _analysisContext.computeLibraryElement(librarySource)
            as LibraryElementImpl;
      } on AnalysisException catch (exception, stackTrace) {
        AnalysisEngine.instance.logger.logError(
            "Could not compute library element for ${librarySource.fullName}",
            new CaughtException(exception, stackTrace));
      }
    }
    return _libraryElement;
  }

  /**
   * Set the library element representing this library to the given library element.
   *
   * @param libraryElement the library element representing this library
   */
  void set libraryElement(LibraryElementImpl libraryElement) {
    this._libraryElement = libraryElement;
    if (_inheritanceManager != null) {
      _inheritanceManager.libraryElement = libraryElement;
    }
  }

  /**
   * Return the library scope used when resolving elements within this library's compilation units.
   *
   * @return the library scope used when resolving elements within this library's compilation units
   */
  LibraryScope get libraryScope {
    if (_libraryScope == null) {
      _libraryScope = new LibraryScope(_libraryElement, errorListener);
    }
    return _libraryScope;
  }

  /**
   * Return the AST structure associated with the given source.
   *
   * @param source the source representing the compilation unit whose AST is to be returned
   * @return the AST structure associated with the given source
   * @throws AnalysisException if an AST structure could not be created for the compilation unit
   */
  CompilationUnit getAST(Source source) {
    CompilationUnit unit = _astMap[source];
    if (unit == null) {
      unit = _analysisContext.computeResolvableCompilationUnit(source);
      _astMap[source] = unit;
    }
    return unit;
  }

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * library, or `null` if the URI is not valid. If the URI is not valid, report the error.
   *
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source getSource(UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      errorListener.onError(new AnalysisError(librarySource, uriLiteral.offset,
          uriLiteral.length, CompileTimeErrorCode.URI_WITH_INTERPOLATION));
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    _directiveUris[directive] = uriContent;
    uriContent = Uri.encodeFull(uriContent);
    if (directive is ImportDirective &&
        uriContent.startsWith(_DART_EXT_SCHEME)) {
      _libraryElement.hasExtUri = true;
      return null;
    }
    try {
      parseUriWithException(uriContent);
      Source source =
          _analysisContext.sourceFactory.resolveUri(librarySource, uriContent);
      if (!_analysisContext.exists(source)) {
        errorListener.onError(new AnalysisError(
            librarySource,
            uriLiteral.offset,
            uriLiteral.length,
            CompileTimeErrorCode.URI_DOES_NOT_EXIST,
            [uriContent]));
      }
      return source;
    } on URISyntaxException {
      errorListener.onError(new AnalysisError(librarySource, uriLiteral.offset,
          uriLiteral.length, CompileTimeErrorCode.INVALID_URI, [uriContent]));
    }
    return null;
  }

  /**
   * Returns the URI value of the given directive.
   */
  String getUri(UriBasedDirective directive) => _directiveUris[directive];

  /**
   * Set the AST structure associated with the defining compilation unit for this library to the
   * given AST structure.
   *
   * @param unit the AST structure associated with the defining compilation unit for this library
   */
  void setDefiningCompilationUnit(CompilationUnit unit) {
    _astMap[librarySource] = unit;
  }

  @override
  String toString() => librarySource.shortName;
}

/**
 * Instances of the class `LibraryElementBuilder` build an element model for a single library.
 */
class LibraryElementBuilder {
  /**
   * The analysis context in which the element model will be built.
   */
  final InternalAnalysisContext _analysisContext;

  /**
   * The listener to which errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * Initialize a newly created library element builder.
   *
   * @param analysisContext the analysis context in which the element model will be built
   * @param errorListener the listener to which errors will be reported
   */
  LibraryElementBuilder(this._analysisContext, this._errorListener);

  /**
   * Build the library element for the given library.
   *
   * @param library the library for which an element model is to be built
   * @return the library element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  LibraryElementImpl buildLibrary(Library library) {
    CompilationUnitBuilder builder = new CompilationUnitBuilder();
    Source librarySource = library.librarySource;
    CompilationUnit definingCompilationUnit = library.definingCompilationUnit;
    CompilationUnitElementImpl definingCompilationUnitElement = builder
        .buildCompilationUnit(
            librarySource, definingCompilationUnit, librarySource);
    NodeList<Directive> directives = definingCompilationUnit.directives;
    LibraryIdentifier libraryNameNode = null;
    bool hasPartDirective = false;
    FunctionElement entryPoint =
        _findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = new List<Directive>();
    List<CompilationUnitElementImpl> sourcedCompilationUnits =
        new List<CompilationUnitElementImpl>();
    for (Directive directive in directives) {
      //
      // We do not build the elements representing the import and export
      // directives at this point. That is not done until we get to
      // LibraryResolver.buildDirectiveModels() because we need the
      // LibraryElements for the referenced libraries, which might not exist at
      // this point (due to the possibility of circular references).
      //
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = directive.name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive;
        StringLiteral partUri = partDirective.uri;
        Source partSource = partDirective.source;
        if (_analysisContext.exists(partSource)) {
          hasPartDirective = true;
          CompilationUnit partUnit = library.getAST(partSource);
          CompilationUnitElementImpl part =
              builder.buildCompilationUnit(partSource, partUnit, librarySource);
          part.uriOffset = partUri.offset;
          part.uriEnd = partUri.end;
          part.uri = partDirective.uriContent;
          //
          // Validate that the part contains a part-of directive with the same
          // name as the library.
          //
          String partLibraryName =
              _getPartLibraryName(partSource, partUnit, directivesToResolve);
          if (partLibraryName == null) {
            _errorListener.onError(new AnalysisError(
                librarySource,
                partUri.offset,
                partUri.length,
                CompileTimeErrorCode.PART_OF_NON_PART,
                [partUri.toSource()]));
          } else if (libraryNameNode == null) {
            // TODO(brianwilkerson) Collect the names declared by the part.
            // If they are all the same then we can use that name as the
            // inferred name of the library and present it in a quick-fix.
            // partLibraryNames.add(partLibraryName);
          } else if (libraryNameNode.name != partLibraryName) {
            _errorListener.onError(new AnalysisError(
                librarySource,
                partUri.offset,
                partUri.length,
                StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                [libraryNameNode.name, partLibraryName]));
          }
          if (entryPoint == null) {
            entryPoint = _findEntryPoint(part);
          }
          directive.element = part;
          sourcedCompilationUnits.add(part);
        }
      }
    }
    if (hasPartDirective && libraryNameNode == null) {
      _errorListener.onError(new AnalysisError(librarySource, 0, 0,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART));
    }
    //
    // Create and populate the library element.
    //
    LibraryElementImpl libraryElement = new LibraryElementImpl.forNode(
        _analysisContext.getContextFor(librarySource), libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    if (entryPoint != null) {
      libraryElement.entryPoint = entryPoint;
    }
    int sourcedUnitCount = sourcedCompilationUnits.length;
    libraryElement.parts = sourcedCompilationUnits;
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    library.libraryElement = libraryElement;
    if (sourcedUnitCount > 0) {
      _patchTopLevelAccessors(libraryElement);
    }
    return libraryElement;
  }

  /**
   * Build the library element for the given library.  The resulting element is
   * stored in the [ResolvableLibrary] structure.
   *
   * @param library the library for which an element model is to be built
   * @throws AnalysisException if the analysis could not be performed
   */
  void buildLibrary2(ResolvableLibrary library) {
    CompilationUnitBuilder builder = new CompilationUnitBuilder();
    Source librarySource = library.librarySource;
    CompilationUnit definingCompilationUnit = library.definingCompilationUnit;
    CompilationUnitElementImpl definingCompilationUnitElement = builder
        .buildCompilationUnit(
            librarySource, definingCompilationUnit, librarySource);
    NodeList<Directive> directives = definingCompilationUnit.directives;
    LibraryIdentifier libraryNameNode = null;
    bool hasPartDirective = false;
    FunctionElement entryPoint =
        _findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = new List<Directive>();
    List<CompilationUnitElementImpl> sourcedCompilationUnits =
        new List<CompilationUnitElementImpl>();
    for (Directive directive in directives) {
      //
      // We do not build the elements representing the import and export
      // directives at this point. That is not done until we get to
      // LibraryResolver.buildDirectiveModels() because we need the
      // LibraryElements for the referenced libraries, which might not exist at
      // this point (due to the possibility of circular references).
      //
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = directive.name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive;
        StringLiteral partUri = partDirective.uri;
        Source partSource = partDirective.source;
        if (_analysisContext.exists(partSource)) {
          hasPartDirective = true;
          CompilationUnit partUnit = library.getAST(partSource);
          if (partUnit != null) {
            CompilationUnitElementImpl part = builder.buildCompilationUnit(
                partSource, partUnit, librarySource);
            part.uriOffset = partUri.offset;
            part.uriEnd = partUri.end;
            part.uri = partDirective.uriContent;
            //
            // Validate that the part contains a part-of directive with the same
            // name as the library.
            //
            String partLibraryName =
                _getPartLibraryName(partSource, partUnit, directivesToResolve);
            if (partLibraryName == null) {
              _errorListener.onError(new AnalysisError(
                  librarySource,
                  partUri.offset,
                  partUri.length,
                  CompileTimeErrorCode.PART_OF_NON_PART,
                  [partUri.toSource()]));
            } else if (libraryNameNode == null) {
              // TODO(brianwilkerson) Collect the names declared by the part.
              // If they are all the same then we can use that name as the
              // inferred name of the library and present it in a quick-fix.
              // partLibraryNames.add(partLibraryName);
            } else if (libraryNameNode.name != partLibraryName) {
              _errorListener.onError(new AnalysisError(
                  librarySource,
                  partUri.offset,
                  partUri.length,
                  StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                  [libraryNameNode.name, partLibraryName]));
            }
            if (entryPoint == null) {
              entryPoint = _findEntryPoint(part);
            }
            directive.element = part;
            sourcedCompilationUnits.add(part);
          }
        }
      }
    }
    if (hasPartDirective && libraryNameNode == null) {
      _errorListener.onError(new AnalysisError(librarySource, 0, 0,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART));
    }
    //
    // Create and populate the library element.
    //
    LibraryElementImpl libraryElement = new LibraryElementImpl.forNode(
        _analysisContext.getContextFor(librarySource), libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    if (entryPoint != null) {
      libraryElement.entryPoint = entryPoint;
    }
    int sourcedUnitCount = sourcedCompilationUnits.length;
    libraryElement.parts = sourcedCompilationUnits;
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    library.libraryElement = libraryElement;
    if (sourcedUnitCount > 0) {
      _patchTopLevelAccessors(libraryElement);
    }
  }

  /**
   * Add all of the non-synthetic getters and setters defined in the given compilation unit that
   * have no corresponding accessor to one of the given collections.
   *
   * @param getters the map to which getters are to be added
   * @param setters the list to which setters are to be added
   * @param unit the compilation unit defining the accessors that are potentially being added
   */
  void _collectAccessors(HashMap<String, PropertyAccessorElement> getters,
      List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    for (PropertyAccessorElement accessor in unit.accessors) {
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

  /**
   * Search the top-level functions defined in the given compilation unit for the entry point.
   *
   * @param element the compilation unit to be searched
   * @return the entry point that was found, or `null` if the compilation unit does not define
   *         an entry point
   */
  FunctionElement _findEntryPoint(CompilationUnitElementImpl element) {
    for (FunctionElement function in element.functions) {
      if (function.isEntryPoint) {
        return function;
      }
    }
    return null;
  }

  /**
   * Return the name of the library that the given part is declared to be a part of, or `null`
   * if the part does not contain a part-of directive.
   *
   * @param partSource the source representing the part
   * @param partUnit the AST structure of the part
   * @param directivesToResolve a list of directives that should be resolved to the library being
   *          built
   * @return the name of the library that the given part is declared to be a part of
   */
  String _getPartLibraryName(Source partSource, CompilationUnit partUnit,
      List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return libraryName.name;
        }
      }
    }
    return null;
  }

  /**
   * Look through all of the compilation units defined for the given library, looking for getters
   * and setters that are defined in different compilation units but that have the same names. If
   * any are found, make sure that they have the same variable element.
   *
   * @param libraryElement the library defining the compilation units to be processed
   */
  void _patchTopLevelAccessors(LibraryElementImpl libraryElement) {
    HashMap<String, PropertyAccessorElement> getters =
        new HashMap<String, PropertyAccessorElement>();
    List<PropertyAccessorElement> setters = new List<PropertyAccessorElement>();
    _collectAccessors(getters, setters, libraryElement.definingCompilationUnit);
    for (CompilationUnitElement unit in libraryElement.parts) {
      _collectAccessors(getters, setters, unit);
    }
    for (PropertyAccessorElement setter in setters) {
      PropertyAccessorElement getter = getters[setter.displayName];
      if (getter != null) {
        PropertyInducingElementImpl variable =
            getter.variable as PropertyInducingElementImpl;
        variable.setter = setter;
        (setter as PropertyAccessorElementImpl).variable = variable;
      }
    }
  }
}

/**
 * Instances of the class `LibraryImportScope` represent the scope containing all of the names
 * available from imported libraries.
 */
class LibraryImportScope extends Scope {
  /**
   * The element representing the library in which this scope is enclosed.
   */
  final LibraryElement _definingLibrary;

  /**
   * The listener that is to be informed when an error is encountered.
   */
  final AnalysisErrorListener errorListener;

  /**
   * A list of the namespaces representing the names that are available in this scope from imported
   * libraries.
   */
  List<Namespace> _importedNamespaces;

  /**
   * Initialize a newly created scope representing the names imported into the given library.
   *
   * @param definingLibrary the element representing the library that imports the names defined in
   *          this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryImportScope(this._definingLibrary, this.errorListener) {
    _createImportedNamespaces();
  }

  @override
  void define(Element element) {
    if (!Scope.isPrivateName(element.displayName)) {
      super.define(element);
    }
  }

  @override
  Source getSource(AstNode node) {
    Source source = super.getSource(node);
    if (source == null) {
      source = _definingLibrary.definingCompilationUnit.source;
    }
    return source;
  }

  @override
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element foundElement = localLookup(name, referencingLibrary);
    if (foundElement != null) {
      return foundElement;
    }
    for (int i = 0; i < _importedNamespaces.length; i++) {
      Namespace nameSpace = _importedNamespaces[i];
      Element element = nameSpace.get(name);
      if (element != null) {
        if (foundElement == null) {
          foundElement = element;
        } else if (!identical(foundElement, element)) {
          foundElement = MultiplyDefinedElementImpl.fromElements(
              _definingLibrary.context, foundElement, element);
        }
      }
    }
    if (foundElement is MultiplyDefinedElementImpl) {
      foundElement = _removeSdkElements(
          identifier, name, foundElement as MultiplyDefinedElementImpl);
    }
    if (foundElement is MultiplyDefinedElementImpl) {
      String foundEltName = foundElement.displayName;
      List<Element> conflictingMembers = foundElement.conflictingElements;
      int count = conflictingMembers.length;
      List<String> libraryNames = new List<String>(count);
      for (int i = 0; i < count; i++) {
        libraryNames[i] = _getLibraryName(conflictingMembers[i]);
      }
      libraryNames.sort();
      errorListener.onError(new AnalysisError(
          getSource(identifier),
          identifier.offset,
          identifier.length,
          StaticWarningCode.AMBIGUOUS_IMPORT, [
        foundEltName,
        StringUtilities.printListOfQuotedNames(libraryNames)
      ]));
      return foundElement;
    }
    if (foundElement != null) {
      defineNameWithoutChecking(name, foundElement);
    }
    return foundElement;
  }

  /**
   * Create all of the namespaces associated with the libraries imported into this library. The
   * names are not added to this scope, but are stored for later reference.
   *
   * @param definingLibrary the element representing the library that imports the libraries for
   *          which namespaces will be created
   */
  void _createImportedNamespaces() {
    NamespaceBuilder builder = new NamespaceBuilder();
    List<ImportElement> imports = _definingLibrary.imports;
    int count = imports.length;
    _importedNamespaces = new List<Namespace>(count);
    for (int i = 0; i < count; i++) {
      _importedNamespaces[i] =
          builder.createImportNamespaceForDirective(imports[i]);
    }
  }

  /**
   * Returns the name of the library that defines given element.
   *
   * @param element the element to get library name
   * @return the name of the library that defines given element
   */
  String _getLibraryName(Element element) {
    if (element == null) {
      return StringUtilities.EMPTY;
    }
    LibraryElement library = element.library;
    if (library == null) {
      return StringUtilities.EMPTY;
    }
    List<ImportElement> imports = _definingLibrary.imports;
    int count = imports.length;
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].importedLibrary, library)) {
        return library.definingCompilationUnit.displayName;
      }
    }
    List<String> indirectSources = new List<String>();
    for (int i = 0; i < count; i++) {
      LibraryElement importedLibrary = imports[i].importedLibrary;
      if (importedLibrary != null) {
        for (LibraryElement exportedLibrary
            in importedLibrary.exportedLibraries) {
          if (identical(exportedLibrary, library)) {
            indirectSources
                .add(importedLibrary.definingCompilationUnit.displayName);
          }
        }
      }
    }
    int indirectCount = indirectSources.length;
    StringBuffer buffer = new StringBuffer();
    buffer.write(library.definingCompilationUnit.displayName);
    if (indirectCount > 0) {
      buffer.write(" (via ");
      if (indirectCount > 1) {
        indirectSources.sort();
        buffer.write(StringUtilities.printListOfQuotedNames(indirectSources));
      } else {
        buffer.write(indirectSources[0]);
      }
      buffer.write(")");
    }
    return buffer.toString();
  }

  /**
   * Given a collection of elements (captured by the [foundElement]) that the
   * [identifier] (with the given [name]) resolved to, remove from the list all
   * of the names defined in the SDK and return the element(s) that remain.
   */
  Element _removeSdkElements(Identifier identifier, String name,
      MultiplyDefinedElementImpl foundElement) {
    List<Element> conflictingElements = foundElement.conflictingElements;
    List<Element> nonSdkElements = new List<Element>();
    Element sdkElement = null;
    for (Element member in conflictingElements) {
      if (member.library.isInSdk) {
        sdkElement = member;
      } else {
        nonSdkElements.add(member);
      }
    }
    if (sdkElement != null && nonSdkElements.length > 0) {
      String sdkLibName = _getLibraryName(sdkElement);
      String otherLibName = _getLibraryName(nonSdkElements[0]);
      errorListener.onError(new AnalysisError(
          getSource(identifier),
          identifier.offset,
          identifier.length,
          StaticWarningCode.CONFLICTING_DART_IMPORT,
          [name, sdkLibName, otherLibName]));
    }
    if (nonSdkElements.length == conflictingElements.length) {
      // None of the members were removed
      return foundElement;
    } else if (nonSdkElements.length == 1) {
      // All but one member was removed
      return nonSdkElements[0];
    } else if (nonSdkElements.length == 0) {
      // All members were removed
      AnalysisEngine.instance.logger
          .logInformation("Multiply defined SDK element: $foundElement");
      return foundElement;
    }
    return new MultiplyDefinedElementImpl(
        _definingLibrary.context, nonSdkElements);
  }
}

/**
 * Instances of the class `LibraryResolver` are used to resolve one or more mutually dependent
 * libraries within a single context.
 */
class LibraryResolver {
  /**
   * The analysis context in which the libraries are being analyzed.
   */
  final InternalAnalysisContext analysisContext;

  /**
   * The listener to which analysis errors will be reported, this error listener is either
   * references [recordingErrorListener], or it unions the passed
   * [AnalysisErrorListener] with the [recordingErrorListener].
   */
  RecordingErrorListener _errorListener;

  /**
   * A source object representing the core library (dart:core).
   */
  Source _coreLibrarySource;

  /**
   * A Source object representing the async library (dart:async).
   */
  Source _asyncLibrarySource;

  /**
   * The object representing the core library.
   */
  Library _coreLibrary;

  /**
   * The object representing the async library.
   */
  Library _asyncLibrary;

  /**
   * The object used to access the types from the core library.
   */
  TypeProvider _typeProvider;

  /**
   * A table mapping library sources to the information being maintained for those libraries.
   */
  HashMap<Source, Library> _libraryMap = new HashMap<Source, Library>();

  /**
   * A collection containing the libraries that are being resolved together.
   */
  Set<Library> _librariesInCycles;

  /**
   * Initialize a newly created library resolver to resolve libraries within the given context.
   *
   * @param analysisContext the analysis context in which the library is being analyzed
   */
  LibraryResolver(this.analysisContext) {
    this._errorListener = new RecordingErrorListener();
    _coreLibrarySource =
        analysisContext.sourceFactory.forUri(DartSdk.DART_CORE);
    _asyncLibrarySource =
        analysisContext.sourceFactory.forUri(DartSdk.DART_ASYNC);
  }

  /**
   * Return the listener to which analysis errors will be reported.
   *
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   *
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _librariesInCycles;

  /**
   * The object used to access the types from the core library.
   */
  TypeProvider get typeProvider => _typeProvider;

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library createLibrary(Source librarySource) {
    Library library =
        new Library(analysisContext, _errorListener, librarySource);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Resolve the library specified by the given source in the given context. The library is assumed
   * to be embedded in the given source.
   *
   * @param librarySource the source specifying the defining compilation unit of the library to be
   *          resolved
   * @param unit the compilation unit representing the embedded library
   * @param fullAnalysis `true` if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveEmbeddedLibrary(
      Source librarySource, CompilationUnit unit, bool fullAnalysis) {
    //
    // Create the objects representing the library being resolved and the core
    // library.
    //
    Library targetLibrary = _createLibraryWithUnit(librarySource, unit);
    _coreLibrary = _libraryMap[_coreLibrarySource];
    if (_coreLibrary == null) {
      // This will only happen if the library being analyzed is the core
      // library.
      _coreLibrary = createLibrary(_coreLibrarySource);
      if (_coreLibrary == null) {
        LibraryResolver2.missingCoreLibrary(
            analysisContext, _coreLibrarySource);
      }
    }
    _asyncLibrary = _libraryMap[_asyncLibrarySource];
    if (_asyncLibrary == null) {
      // This will only happen if the library being analyzed is the async
      // library.
      _asyncLibrary = createLibrary(_asyncLibrarySource);
      if (_asyncLibrary == null) {
        LibraryResolver2.missingAsyncLibrary(
            analysisContext, _asyncLibrarySource);
      }
    }
    //
    // Compute the set of libraries that need to be resolved together.
    //
    _computeEmbeddedLibraryDependencies(targetLibrary, unit);
    _librariesInCycles = _computeLibrariesInCycles(targetLibrary);
    //
    // Build the element models representing the libraries being resolved.
    // This is done in three steps:
    //
    // 1. Build the basic element models without making any connections
    //    between elements other than the basic parent/child relationships.
    //    This includes building the elements representing the libraries.
    // 2. Build the elements for the import and export directives. This
    //    requires that we have the elements built for the referenced
    //    libraries, but because of the possibility of circular references
    //    needs to happen after all of the library elements have been created.
    // 3. Build the rest of the type model by connecting superclasses, mixins,
    //    and interfaces. This requires that we be able to compute the names
    //    visible in the libraries being resolved, which in turn requires that
    //    we have resolved the import directives.
    //
    _buildElementModels();
    LibraryElement coreElement = _coreLibrary.libraryElement;
    if (coreElement == null) {
      throw new AnalysisException("Could not resolve dart:core");
    }
    LibraryElement asyncElement = _asyncLibrary.libraryElement;
    if (asyncElement == null) {
      throw new AnalysisException("Could not resolve dart:async");
    }
    _buildDirectiveModels();
    _typeProvider = new TypeProviderImpl(coreElement, asyncElement);
    _buildTypeHierarchies();
    //
    // Perform resolution and type analysis.
    //
    // TODO(brianwilkerson) Decide whether we want to resolve all of the
    // libraries or whether we want to only resolve the target library.
    // The advantage to resolving everything is that we have already done part
    // of the work so we'll avoid duplicated effort. The disadvantage of
    // resolving everything is that we might do extra work that we don't
    // really care about. Another possibility is to add a parameter to this
    // method and punt the decision to the clients.
    //
    //if (analyzeAll) {
    resolveReferencesAndTypes();
    //} else {
    //  resolveReferencesAndTypes(targetLibrary);
    //}
    _performConstantEvaluation();
    return targetLibrary.libraryElement;
  }

  /**
   * Resolve the library specified by the given source in the given context.
   *
   * Note that because Dart allows circular imports between libraries, it is possible that more than
   * one library will need to be resolved. In such cases the error listener can receive errors from
   * multiple libraries.
   *
   * @param librarySource the source specifying the defining compilation unit of the library to be
   *          resolved
   * @param fullAnalysis `true` if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveLibrary(Source librarySource, bool fullAnalysis) {
    //
    // Create the object representing the library being resolved and compute
    // the dependency relationship.  Note that all libraries depend implicitly
    // on core, and we inject an ersatz dependency on async, so once this is
    // done the core and async library elements will have been created.
    //
    Library targetLibrary = createLibrary(librarySource);
    _computeLibraryDependencies(targetLibrary);
    _coreLibrary = _libraryMap[_coreLibrarySource];
    _asyncLibrary = _libraryMap[_asyncLibrarySource];
    //
    // Compute the set of libraries that need to be resolved together.
    //
    _librariesInCycles = _computeLibrariesInCycles(targetLibrary);
    //
    // Build the element models representing the libraries being resolved.
    // This is done in three steps:
    //
    // 1. Build the basic element models without making any connections
    //    between elements other than the basic parent/child relationships.
    //    This includes building the elements representing the libraries, but
    //    excludes members defined in enums.
    // 2. Build the elements for the import and export directives. This
    //    requires that we have the elements built for the referenced
    //    libraries, but because of the possibility of circular references
    //    needs to happen after all of the library elements have been created.
    // 3. Build the members in enum declarations.
    // 4. Build the rest of the type model by connecting superclasses, mixins,
    //    and interfaces. This requires that we be able to compute the names
    //    visible in the libraries being resolved, which in turn requires that
    //    we have resolved the import directives.
    //
    _buildElementModels();
    LibraryElement coreElement = _coreLibrary.libraryElement;
    if (coreElement == null) {
      throw new AnalysisException("Could not resolve dart:core");
    }
    LibraryElement asyncElement = _asyncLibrary.libraryElement;
    if (asyncElement == null) {
      throw new AnalysisException("Could not resolve dart:async");
    }
    _buildDirectiveModels();
    _typeProvider = new TypeProviderImpl(coreElement, asyncElement);
    _buildEnumMembers();
    _buildTypeHierarchies();
    //
    // Perform resolution and type analysis.
    //
    // TODO(brianwilkerson) Decide whether we want to resolve all of the
    // libraries or whether we want to only resolve the target library. The
    // advantage to resolving everything is that we have already done part of
    // the work so we'll avoid duplicated effort. The disadvantage of
    // resolving everything is that we might do extra work that we don't
    // really care about. Another possibility is to add a parameter to this
    // method and punt the decision to the clients.
    //
    //if (analyzeAll) {
    resolveReferencesAndTypes();
    //} else {
    //  resolveReferencesAndTypes(targetLibrary);
    //}
    _performConstantEvaluation();
    return targetLibrary.libraryElement;
  }

  /**
   * Resolve the identifiers and perform type analysis in the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the identifiers could not be resolved or if any of the
   *           libraries could not have their types analyzed
   */
  void resolveReferencesAndTypes() {
    for (Library library in _librariesInCycles) {
      _resolveReferencesAndTypesInLibrary(library);
    }
  }

  /**
   * Add a dependency to the given map from the referencing library to the referenced library.
   *
   * @param dependencyMap the map to which the dependency is to be added
   * @param referencingLibrary the library that references the referenced library
   * @param referencedLibrary the library referenced by the referencing library
   */
  void _addDependencyToMap(HashMap<Library, List<Library>> dependencyMap,
      Library referencingLibrary, Library referencedLibrary) {
    List<Library> dependentLibraries = dependencyMap[referencedLibrary];
    if (dependentLibraries == null) {
      dependentLibraries = new List<Library>();
      dependencyMap[referencedLibrary] = dependentLibraries;
    }
    dependentLibraries.add(referencingLibrary);
  }

  /**
   * Given a library that is part of a cycle that includes the root library, add to the given set of
   * libraries all of the libraries reachable from the root library that are also included in the
   * cycle.
   *
   * @param library the library to be added to the collection of libraries in cycles
   * @param librariesInCycle a collection of the libraries that are in the cycle
   * @param dependencyMap a table mapping libraries to the collection of libraries from which those
   *          libraries are referenced
   */
  void _addLibrariesInCycle(Library library, Set<Library> librariesInCycle,
      HashMap<Library, List<Library>> dependencyMap) {
    if (librariesInCycle.add(library)) {
      List<Library> dependentLibraries = dependencyMap[library];
      if (dependentLibraries != null) {
        for (Library dependentLibrary in dependentLibraries) {
          _addLibrariesInCycle(
              dependentLibrary, librariesInCycle, dependencyMap);
        }
      }
    }
  }

  /**
   * Add the given library, and all libraries reachable from it that have not already been visited,
   * to the given dependency map.
   *
   * @param library the library currently being added to the dependency map
   * @param dependencyMap the dependency map being computed
   * @param visitedLibraries the libraries that have already been visited, used to prevent infinite
   *          recursion
   */
  void _addToDependencyMap(
      Library library,
      HashMap<Library, List<Library>> dependencyMap,
      Set<Library> visitedLibraries) {
    if (visitedLibraries.add(library)) {
      bool asyncFound = false;
      for (Library referencedLibrary in library.importsAndExports) {
        _addDependencyToMap(dependencyMap, library, referencedLibrary);
        _addToDependencyMap(referencedLibrary, dependencyMap, visitedLibraries);
        if (identical(referencedLibrary, _asyncLibrary)) {
          asyncFound = true;
        }
      }
      if (!library.explicitlyImportsCore && !identical(library, _coreLibrary)) {
        _addDependencyToMap(dependencyMap, library, _coreLibrary);
      }
      if (!asyncFound && !identical(library, _asyncLibrary)) {
        _addDependencyToMap(dependencyMap, library, _asyncLibrary);
        _addToDependencyMap(_asyncLibrary, dependencyMap, visitedLibraries);
      }
    }
  }

  /**
   * Build the element model representing the combinators declared by the given directive.
   *
   * @param directive the directive that declares the combinators
   * @return an array containing the import combinators that were built
   */
  List<NamespaceCombinator> _buildCombinators(NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = new List<NamespaceCombinator>();
    for (Combinator combinator in directive.combinators) {
      if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = _getIdentifiers(combinator.hiddenNames);
        combinators.add(hide);
      } else {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.offset = combinator.offset;
        show.end = combinator.end;
        show.shownNames =
            _getIdentifiers((combinator as ShowCombinator).shownNames);
        combinators.add(show);
      }
    }
    return combinators;
  }

  /**
   * Every library now has a corresponding [LibraryElement], so it is now possible to resolve
   * the import and export directives.
   *
   * @throws AnalysisException if the defining compilation unit for any of the libraries could not
   *           be accessed
   */
  void _buildDirectiveModels() {
    for (Library library in _librariesInCycles) {
      HashMap<String, PrefixElementImpl> nameToPrefixMap =
          new HashMap<String, PrefixElementImpl>();
      List<ImportElement> imports = new List<ImportElement>();
      List<ExportElement> exports = new List<ExportElement>();
      for (Directive directive in library.definingCompilationUnit.directives) {
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive;
          String uriContent = importDirective.uriContent;
          if (DartUriResolver.isDartExtUri(uriContent)) {
            library.libraryElement.hasExtUri = true;
          }
          Source importedSource = importDirective.source;
          if (importedSource != null) {
            // The imported source will be null if the URI in the import
            // directive was invalid.
            Library importedLibrary = _libraryMap[importedSource];
            if (importedLibrary != null) {
              ImportElementImpl importElement =
                  new ImportElementImpl(directive.offset);
              StringLiteral uriLiteral = importDirective.uri;
              importElement.uriOffset = uriLiteral.offset;
              importElement.uriEnd = uriLiteral.end;
              importElement.uri = uriContent;
              importElement.deferred = importDirective.deferredKeyword != null;
              importElement.combinators = _buildCombinators(importDirective);
              LibraryElement importedLibraryElement =
                  importedLibrary.libraryElement;
              if (importedLibraryElement != null) {
                importElement.importedLibrary = importedLibraryElement;
              }
              SimpleIdentifier prefixNode = directive.prefix;
              if (prefixNode != null) {
                importElement.prefixOffset = prefixNode.offset;
                String prefixName = prefixNode.name;
                PrefixElementImpl prefix = nameToPrefixMap[prefixName];
                if (prefix == null) {
                  prefix = new PrefixElementImpl.forNode(prefixNode);
                  nameToPrefixMap[prefixName] = prefix;
                }
                importElement.prefix = prefix;
                prefixNode.staticElement = prefix;
              }
              directive.element = importElement;
              imports.add(importElement);
              if (analysisContext.computeKindOf(importedSource) !=
                  SourceKind.LIBRARY) {
                ErrorCode errorCode = (importElement.isDeferred
                    ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                    : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
                _errorListener.onError(new AnalysisError(
                    library.librarySource,
                    uriLiteral.offset,
                    uriLiteral.length,
                    errorCode,
                    [uriLiteral.toSource()]));
              }
            }
          }
        } else if (directive is ExportDirective) {
          ExportDirective exportDirective = directive;
          Source exportedSource = exportDirective.source;
          if (exportedSource != null) {
            // The exported source will be null if the URI in the export
            // directive was invalid.
            Library exportedLibrary = _libraryMap[exportedSource];
            if (exportedLibrary != null) {
              ExportElementImpl exportElement =
                  new ExportElementImpl(directive.offset);
              StringLiteral uriLiteral = exportDirective.uri;
              exportElement.uriOffset = uriLiteral.offset;
              exportElement.uriEnd = uriLiteral.end;
              exportElement.uri = exportDirective.uriContent;
              exportElement.combinators = _buildCombinators(exportDirective);
              LibraryElement exportedLibraryElement =
                  exportedLibrary.libraryElement;
              if (exportedLibraryElement != null) {
                exportElement.exportedLibrary = exportedLibraryElement;
              }
              directive.element = exportElement;
              exports.add(exportElement);
              if (analysisContext.computeKindOf(exportedSource) !=
                  SourceKind.LIBRARY) {
                _errorListener.onError(new AnalysisError(
                    library.librarySource,
                    uriLiteral.offset,
                    uriLiteral.length,
                    CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                    [uriLiteral.toSource()]));
              }
            }
          }
        }
      }
      Source librarySource = library.librarySource;
      if (!library.explicitlyImportsCore &&
          _coreLibrarySource != librarySource) {
        ImportElementImpl importElement = new ImportElementImpl(-1);
        importElement.importedLibrary = _coreLibrary.libraryElement;
        importElement.synthetic = true;
        imports.add(importElement);
      }
      LibraryElementImpl libraryElement = library.libraryElement;
      libraryElement.imports = imports;
      libraryElement.exports = exports;
      if (libraryElement.entryPoint == null) {
        Namespace namespace = new NamespaceBuilder()
            .createExportNamespaceForLibrary(libraryElement);
        Element element = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
        if (element is FunctionElement) {
          libraryElement.entryPoint = element;
        }
      }
    }
  }

  /**
   * Build element models for all of the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the element models cannot be built
   */
  void _buildElementModels() {
    for (Library library in _librariesInCycles) {
      LibraryElementBuilder builder =
          new LibraryElementBuilder(analysisContext, errorListener);
      LibraryElementImpl libraryElement = builder.buildLibrary(library);
      library.libraryElement = libraryElement;
    }
  }

  /**
   * Build the members in enum declarations. This cannot be done while building the rest of the
   * element model because it depends on being able to access core types, which cannot happen until
   * the rest of the element model has been built (when resolving the core library).
   *
   * @throws AnalysisException if any of the enum members could not be built
   */
  void _buildEnumMembers() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          EnumMemberBuilder builder = new EnumMemberBuilder(_typeProvider);
          library.getAST(source).accept(builder);
        }
      }
    });
  }

  /**
   * Resolve the type hierarchy across all of the types declared in the libraries in the current
   * cycle.
   *
   * @throws AnalysisException if any of the type hierarchies could not be resolved
   */
  void _buildTypeHierarchies() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          TypeResolverVisitorFactory typeResolverVisitorFactory =
              analysisContext.typeResolverVisitorFactory;
          TypeResolverVisitor visitor = (typeResolverVisitorFactory == null)
              ? new TypeResolverVisitor(library.libraryElement, source,
                  _typeProvider, library.errorListener,
                  nameScope: library.libraryScope)
              : typeResolverVisitorFactory(library, source, _typeProvider);
          library.getAST(source).accept(visitor);
        }
      }
    });
  }

  /**
   * Compute a dependency map of libraries reachable from the given library. A dependency map is a
   * table that maps individual libraries to a list of the libraries that either import or export
   * those libraries.
   *
   * This map is used to compute all of the libraries involved in a cycle that include the root
   * library. Given that we only add libraries that are reachable from the root library, when we
   * work backward we are guaranteed to only get libraries in the cycle.
   *
   * @param library the library currently being added to the dependency map
   */
  HashMap<Library, List<Library>> _computeDependencyMap(Library library) {
    HashMap<Library, List<Library>> dependencyMap =
        new HashMap<Library, List<Library>>();
    _addToDependencyMap(library, dependencyMap, new HashSet<Library>());
    return dependencyMap;
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void _computeEmbeddedLibraryDependencies(
      Library library, CompilationUnit unit) {
    Source librarySource = library.librarySource;
    HashSet<Source> exportedSources = new HashSet<Source>();
    HashSet<Source> importedSources = new HashSet<Source>();
    for (Directive directive in unit.directives) {
      if (directive is ExportDirective) {
        Source exportSource = _resolveSource(librarySource, directive);
        if (exportSource != null) {
          exportedSources.add(exportSource);
        }
      } else if (directive is ImportDirective) {
        Source importSource = _resolveSource(librarySource, directive);
        if (importSource != null) {
          importedSources.add(importSource);
        }
      }
    }
    _computeLibraryDependenciesFromDirectives(library,
        new List.from(importedSources), new List.from(exportedSources));
  }

  /**
   * Return a collection containing all of the libraries reachable from the given library that are
   * contained in a cycle that includes the given library.
   *
   * @param library the library that must be included in any cycles whose members are to be returned
   * @return all of the libraries referenced by the given library that have a circular reference
   *         back to the given library
   */
  Set<Library> _computeLibrariesInCycles(Library library) {
    HashMap<Library, List<Library>> dependencyMap =
        _computeDependencyMap(library);
    Set<Library> librariesInCycle = new HashSet<Library>();
    _addLibrariesInCycle(library, librariesInCycle, dependencyMap);
    return librariesInCycle;
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void _computeLibraryDependencies(Library library) {
    Source librarySource = library.librarySource;
    _computeLibraryDependenciesFromDirectives(
        library,
        analysisContext.computeImportedLibraries(librarySource),
        analysisContext.computeExportedLibraries(librarySource));
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @param importedSources an array containing the sources that are imported into the given library
   * @param exportedSources an array containing the sources that are exported from the given library
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void _computeLibraryDependenciesFromDirectives(Library library,
      List<Source> importedSources, List<Source> exportedSources) {
    List<Library> importedLibraries = new List<Library>();
    bool explicitlyImportsCore = false;
    bool importsAsync = false;
    for (Source importedSource in importedSources) {
      if (importedSource == _coreLibrarySource) {
        explicitlyImportsCore = true;
      }
      if (importedSource == _asyncLibrarySource) {
        importsAsync = true;
      }
      Library importedLibrary = _libraryMap[importedSource];
      if (importedLibrary == null) {
        importedLibrary = _createLibraryOrNull(importedSource);
        if (importedLibrary != null) {
          _computeLibraryDependencies(importedLibrary);
        }
      }
      if (importedLibrary != null) {
        importedLibraries.add(importedLibrary);
      }
    }
    library.importedLibraries = importedLibraries;
    List<Library> exportedLibraries = new List<Library>();
    for (Source exportedSource in exportedSources) {
      Library exportedLibrary = _libraryMap[exportedSource];
      if (exportedLibrary == null) {
        exportedLibrary = _createLibraryOrNull(exportedSource);
        if (exportedLibrary != null) {
          _computeLibraryDependencies(exportedLibrary);
        }
      }
      if (exportedLibrary != null) {
        exportedLibraries.add(exportedLibrary);
      }
    }
    library.exportedLibraries = exportedLibraries;
    library.explicitlyImportsCore = explicitlyImportsCore;
    if (!explicitlyImportsCore && _coreLibrarySource != library.librarySource) {
      Library importedLibrary = _libraryMap[_coreLibrarySource];
      if (importedLibrary == null) {
        importedLibrary = _createLibraryOrNull(_coreLibrarySource);
        if (importedLibrary != null) {
          _computeLibraryDependencies(importedLibrary);
        }
      }
    }
    if (!importsAsync && _asyncLibrarySource != library.librarySource) {
      Library importedLibrary = _libraryMap[_asyncLibrarySource];
      if (importedLibrary == null) {
        importedLibrary = _createLibraryOrNull(_asyncLibrarySource);
        if (importedLibrary != null) {
          _computeLibraryDependencies(importedLibrary);
        }
      }
    }
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source. Return the library object that was created, or `null` if the
   * source is not valid.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   */
  Library _createLibraryOrNull(Source librarySource) {
    if (!analysisContext.exists(librarySource)) {
      return null;
    }
    Library library =
        new Library(analysisContext, _errorListener, librarySource);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @param unit the compilation unit that defines the library
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library _createLibraryWithUnit(Source librarySource, CompilationUnit unit) {
    Library library =
        new Library(analysisContext, _errorListener, librarySource);
    library.setDefiningCompilationUnit(unit);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Return an array containing the lexical identifiers associated with the nodes in the given list.
   *
   * @param names the AST nodes representing the identifiers
   * @return the lexical identifiers associated with the nodes in the list
   */
  List<String> _getIdentifiers(NodeList<SimpleIdentifier> names) {
    int count = names.length;
    List<String> identifiers = new List<String>(count);
    for (int i = 0; i < count; i++) {
      identifiers[i] = names[i].name;
    }
    return identifiers;
  }

  /**
   * Compute a value for all of the constants in the libraries being analyzed.
   */
  void _performConstantEvaluation() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      ConstantValueComputer computer = new ConstantValueComputer(
          analysisContext, _typeProvider, analysisContext.declaredVariables);
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          try {
            CompilationUnit unit = library.getAST(source);
            if (unit != null) {
              computer.add(unit, source, library.librarySource);
            }
          } on AnalysisException catch (exception, stackTrace) {
            AnalysisEngine.instance.logger.logError(
                "Internal Error: Could not access AST for ${source.fullName} during constant evaluation",
                new CaughtException(exception, stackTrace));
          }
        }
      }
      computer.computeValues();
      // As a temporary workaround for issue 21572, run ConstantVerifier now.
      // TODO(paulberry): remove this workaround once issue 21572 is fixed.
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          try {
            CompilationUnit unit = library.getAST(source);
            ErrorReporter errorReporter =
                new ErrorReporter(_errorListener, source);
            ConstantVerifier constantVerifier = new ConstantVerifier(
                errorReporter,
                library.libraryElement,
                _typeProvider,
                analysisContext.declaredVariables);
            unit.accept(constantVerifier);
          } on AnalysisException catch (exception, stackTrace) {
            AnalysisEngine.instance.logger.logError(
                "Internal Error: Could not access AST for ${source.fullName} "
                "during constant verification",
                new CaughtException(exception, stackTrace));
          }
        }
      }
    });
  }

  /**
   * Resolve the identifiers and perform type analysis in the given library.
   *
   * @param library the library to be resolved
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   *           the library cannot be analyzed
   */
  void _resolveReferencesAndTypesInLibrary(Library library) {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (Source source in library.compilationUnitSources) {
        CompilationUnit ast = library.getAST(source);
        ast.accept(new VariableResolverVisitor(library.libraryElement, source,
            _typeProvider, library.errorListener,
            nameScope: library.libraryScope));
        ResolverVisitorFactory visitorFactory =
            analysisContext.resolverVisitorFactory;
        ResolverVisitor visitor = visitorFactory != null
            ? visitorFactory(library, source, _typeProvider)
            : new ResolverVisitor(library.libraryElement, source, _typeProvider,
                library.errorListener,
                nameScope: library.libraryScope,
                inheritanceManager: library.inheritanceManager);
        ast.accept(visitor);
      }
    });
  }

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * given library, or `null` if the URI is not valid.
   *
   * @param librarySource the source representing the library containing the directive
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source _resolveSource(Source librarySource, UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    if (uriContent == null || uriContent.isEmpty) {
      return null;
    }
    uriContent = Uri.encodeFull(uriContent);
    return analysisContext.sourceFactory.resolveUri(librarySource, uriContent);
  }
}

/**
 * Instances of the class `LibraryResolver` are used to resolve one or more mutually dependent
 * libraries within a single context.
 */
class LibraryResolver2 {
  /**
   * The analysis context in which the libraries are being analyzed.
   */
  final InternalAnalysisContext analysisContext;

  /**
   * The listener to which analysis errors will be reported, this error listener is either
   * references [recordingErrorListener], or it unions the passed
   * [AnalysisErrorListener] with the [recordingErrorListener].
   */
  RecordingErrorListener _errorListener;

  /**
   * A source object representing the core library (dart:core).
   */
  Source _coreLibrarySource;

  /**
   * A source object representing the async library (dart:async).
   */
  Source _asyncLibrarySource;

  /**
   * The object representing the core library.
   */
  ResolvableLibrary _coreLibrary;

  /**
   * The object representing the async library.
   */
  ResolvableLibrary _asyncLibrary;

  /**
   * The object used to access the types from the core library.
   */
  TypeProvider _typeProvider;

  /**
   * A table mapping library sources to the information being maintained for those libraries.
   */
  HashMap<Source, ResolvableLibrary> _libraryMap =
      new HashMap<Source, ResolvableLibrary>();

  /**
   * A collection containing the libraries that are being resolved together.
   */
  List<ResolvableLibrary> _librariesInCycle;

  /**
   * Initialize a newly created library resolver to resolve libraries within the given context.
   *
   * @param analysisContext the analysis context in which the library is being analyzed
   */
  LibraryResolver2(this.analysisContext) {
    this._errorListener = new RecordingErrorListener();
    _coreLibrarySource =
        analysisContext.sourceFactory.forUri(DartSdk.DART_CORE);
    _asyncLibrarySource =
        analysisContext.sourceFactory.forUri(DartSdk.DART_ASYNC);
  }

  /**
   * Return the listener to which analysis errors will be reported.
   *
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   *
   * @return an array containing the libraries that were resolved
   */
  List<ResolvableLibrary> get resolvedLibraries => _librariesInCycle;

  /**
   * Resolve the library specified by the given source in the given context.
   *
   * Note that because Dart allows circular imports between libraries, it is possible that more than
   * one library will need to be resolved. In such cases the error listener can receive errors from
   * multiple libraries.
   *
   * @param librarySource the source specifying the defining compilation unit of the library to be
   *          resolved
   * @param fullAnalysis `true` if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveLibrary(
      Source librarySource, List<ResolvableLibrary> librariesInCycle) {
    //
    // Build the map of libraries that are known.
    //
    this._librariesInCycle = librariesInCycle;
    _libraryMap = _buildLibraryMap();
    ResolvableLibrary targetLibrary = _libraryMap[librarySource];
    _coreLibrary = _libraryMap[_coreLibrarySource];
    _asyncLibrary = _libraryMap[_asyncLibrarySource];
    //
    // Build the element models representing the libraries being resolved.
    // This is done in three steps:
    //
    // 1. Build the basic element models without making any connections
    //    between elements other than the basic parent/child relationships.
    //    This includes building the elements representing the libraries, but
    //    excludes members defined in enums.
    // 2. Build the elements for the import and export directives. This
    //    requires that we have the elements built for the referenced
    //    libraries, but because of the possibility of circular references
    //    needs to happen after all of the library elements have been created.
    // 3. Build the members in enum declarations.
    // 4. Build the rest of the type model by connecting superclasses, mixins,
    //    and interfaces. This requires that we be able to compute the names
    //    visible in the libraries being resolved, which in turn requires that
    //    we have resolved the import directives.
    //
    _buildElementModels();
    LibraryElement coreElement = _coreLibrary.libraryElement;
    if (coreElement == null) {
      missingCoreLibrary(analysisContext, _coreLibrarySource);
    }
    LibraryElement asyncElement = _asyncLibrary.libraryElement;
    if (asyncElement == null) {
      missingAsyncLibrary(analysisContext, _asyncLibrarySource);
    }
    _buildDirectiveModels();
    _typeProvider = new TypeProviderImpl(coreElement, asyncElement);
    _buildEnumMembers();
    _buildTypeHierarchies();
    //
    // Perform resolution and type analysis.
    //
    // TODO(brianwilkerson) Decide whether we want to resolve all of the
    // libraries or whether we want to only resolve the target library. The
    // advantage to resolving everything is that we have already done part of
    // the work so we'll avoid duplicated effort. The disadvantage of
    // resolving everything is that we might do extra work that we don't
    // really care about. Another possibility is to add a parameter to this
    // method and punt the decision to the clients.
    //
    //if (analyzeAll) {
    _resolveReferencesAndTypes();
    //} else {
    //  resolveReferencesAndTypes(targetLibrary);
    //}
    _performConstantEvaluation();
    return targetLibrary.libraryElement;
  }

  /**
   * Build the element model representing the combinators declared by the given directive.
   *
   * @param directive the directive that declares the combinators
   * @return an array containing the import combinators that were built
   */
  List<NamespaceCombinator> _buildCombinators(NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = new List<NamespaceCombinator>();
    for (Combinator combinator in directive.combinators) {
      if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = _getIdentifiers(combinator.hiddenNames);
        combinators.add(hide);
      } else {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.offset = combinator.offset;
        show.end = combinator.end;
        show.shownNames =
            _getIdentifiers((combinator as ShowCombinator).shownNames);
        combinators.add(show);
      }
    }
    return combinators;
  }

  /**
   * Every library now has a corresponding [LibraryElement], so it is now possible to resolve
   * the import and export directives.
   *
   * @throws AnalysisException if the defining compilation unit for any of the libraries could not
   *           be accessed
   */
  void _buildDirectiveModels() {
    for (ResolvableLibrary library in _librariesInCycle) {
      HashMap<String, PrefixElementImpl> nameToPrefixMap =
          new HashMap<String, PrefixElementImpl>();
      List<ImportElement> imports = new List<ImportElement>();
      List<ExportElement> exports = new List<ExportElement>();
      for (Directive directive in library.definingCompilationUnit.directives) {
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive;
          String uriContent = importDirective.uriContent;
          if (DartUriResolver.isDartExtUri(uriContent)) {
            library.libraryElement.hasExtUri = true;
          }
          Source importedSource = importDirective.source;
          if (importedSource != null &&
              analysisContext.exists(importedSource)) {
            // The imported source will be null if the URI in the import
            // directive was invalid.
            ResolvableLibrary importedLibrary = _libraryMap[importedSource];
            if (importedLibrary != null) {
              ImportElementImpl importElement =
                  new ImportElementImpl(directive.offset);
              StringLiteral uriLiteral = importDirective.uri;
              if (uriLiteral != null) {
                importElement.uriOffset = uriLiteral.offset;
                importElement.uriEnd = uriLiteral.end;
              }
              importElement.uri = uriContent;
              importElement.deferred = importDirective.deferredKeyword != null;
              importElement.combinators = _buildCombinators(importDirective);
              LibraryElement importedLibraryElement =
                  importedLibrary.libraryElement;
              if (importedLibraryElement != null) {
                importElement.importedLibrary = importedLibraryElement;
              }
              SimpleIdentifier prefixNode = directive.prefix;
              if (prefixNode != null) {
                importElement.prefixOffset = prefixNode.offset;
                String prefixName = prefixNode.name;
                PrefixElementImpl prefix = nameToPrefixMap[prefixName];
                if (prefix == null) {
                  prefix = new PrefixElementImpl.forNode(prefixNode);
                  nameToPrefixMap[prefixName] = prefix;
                }
                importElement.prefix = prefix;
                prefixNode.staticElement = prefix;
              }
              directive.element = importElement;
              imports.add(importElement);
              if (analysisContext.computeKindOf(importedSource) !=
                  SourceKind.LIBRARY) {
                ErrorCode errorCode = (importElement.isDeferred
                    ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                    : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
                _errorListener.onError(new AnalysisError(
                    library.librarySource,
                    uriLiteral.offset,
                    uriLiteral.length,
                    errorCode,
                    [uriLiteral.toSource()]));
              }
            }
          }
        } else if (directive is ExportDirective) {
          ExportDirective exportDirective = directive;
          Source exportedSource = exportDirective.source;
          if (exportedSource != null &&
              analysisContext.exists(exportedSource)) {
            // The exported source will be null if the URI in the export
            // directive was invalid.
            ResolvableLibrary exportedLibrary = _libraryMap[exportedSource];
            if (exportedLibrary != null) {
              ExportElementImpl exportElement =
                  new ExportElementImpl(directive.offset);
              StringLiteral uriLiteral = exportDirective.uri;
              if (uriLiteral != null) {
                exportElement.uriOffset = uriLiteral.offset;
                exportElement.uriEnd = uriLiteral.end;
              }
              exportElement.uri = exportDirective.uriContent;
              exportElement.combinators = _buildCombinators(exportDirective);
              LibraryElement exportedLibraryElement =
                  exportedLibrary.libraryElement;
              if (exportedLibraryElement != null) {
                exportElement.exportedLibrary = exportedLibraryElement;
              }
              directive.element = exportElement;
              exports.add(exportElement);
              if (analysisContext.computeKindOf(exportedSource) !=
                  SourceKind.LIBRARY) {
                _errorListener.onError(new AnalysisError(
                    library.librarySource,
                    uriLiteral.offset,
                    uriLiteral.length,
                    CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                    [uriLiteral.toSource()]));
              }
            }
          }
        }
      }
      Source librarySource = library.librarySource;
      if (!library.explicitlyImportsCore &&
          _coreLibrarySource != librarySource) {
        ImportElementImpl importElement = new ImportElementImpl(-1);
        importElement.importedLibrary = _coreLibrary.libraryElement;
        importElement.synthetic = true;
        imports.add(importElement);
      }
      LibraryElementImpl libraryElement = library.libraryElement;
      libraryElement.imports = imports;
      libraryElement.exports = exports;
      if (libraryElement.entryPoint == null) {
        Namespace namespace = new NamespaceBuilder()
            .createExportNamespaceForLibrary(libraryElement);
        Element element = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
        if (element is FunctionElement) {
          libraryElement.entryPoint = element;
        }
      }
    }
  }

  /**
   * Build element models for all of the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the element models cannot be built
   */
  void _buildElementModels() {
    for (ResolvableLibrary library in _librariesInCycle) {
      LibraryElementBuilder builder =
          new LibraryElementBuilder(analysisContext, errorListener);
      builder.buildLibrary2(library);
    }
  }

  /**
   * Build the members in enum declarations. This cannot be done while building the rest of the
   * element model because it depends on being able to access core types, which cannot happen until
   * the rest of the element model has been built (when resolving the core library).
   *
   * @throws AnalysisException if any of the enum members could not be built
   */
  void _buildEnumMembers() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (ResolvableLibrary library in _librariesInCycle) {
        for (Source source in library.compilationUnitSources) {
          EnumMemberBuilder builder = new EnumMemberBuilder(_typeProvider);
          library.getAST(source).accept(builder);
        }
      }
    });
  }

  HashMap<Source, ResolvableLibrary> _buildLibraryMap() {
    HashMap<Source, ResolvableLibrary> libraryMap =
        new HashMap<Source, ResolvableLibrary>();
    int libraryCount = _librariesInCycle.length;
    for (int i = 0; i < libraryCount; i++) {
      ResolvableLibrary library = _librariesInCycle[i];
      library.errorListener = _errorListener;
      libraryMap[library.librarySource] = library;
      List<ResolvableLibrary> dependencies = library.importsAndExports;
      int dependencyCount = dependencies.length;
      for (int j = 0; j < dependencyCount; j++) {
        ResolvableLibrary dependency = dependencies[j];
        //dependency.setErrorListener(errorListener);
        libraryMap[dependency.librarySource] = dependency;
      }
    }
    return libraryMap;
  }

  /**
   * Resolve the type hierarchy across all of the types declared in the libraries in the current
   * cycle.
   *
   * @throws AnalysisException if any of the type hierarchies could not be resolved
   */
  void _buildTypeHierarchies() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (ResolvableLibrary library in _librariesInCycle) {
        for (ResolvableCompilationUnit unit
            in library.resolvableCompilationUnits) {
          Source source = unit.source;
          CompilationUnit ast = unit.compilationUnit;
          TypeResolverVisitor visitor = new TypeResolverVisitor(
              library.libraryElement,
              source,
              _typeProvider,
              library.libraryScope.errorListener,
              nameScope: library.libraryScope);
          ast.accept(visitor);
        }
      }
    });
  }

  /**
   * Return an array containing the lexical identifiers associated with the nodes in the given list.
   *
   * @param names the AST nodes representing the identifiers
   * @return the lexical identifiers associated with the nodes in the list
   */
  List<String> _getIdentifiers(NodeList<SimpleIdentifier> names) {
    int count = names.length;
    List<String> identifiers = new List<String>(count);
    for (int i = 0; i < count; i++) {
      identifiers[i] = names[i].name;
    }
    return identifiers;
  }

  /**
   * Compute a value for all of the constants in the libraries being analyzed.
   */
  void _performConstantEvaluation() {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      ConstantValueComputer computer = new ConstantValueComputer(
          analysisContext, _typeProvider, analysisContext.declaredVariables);
      for (ResolvableLibrary library in _librariesInCycle) {
        for (ResolvableCompilationUnit unit
            in library.resolvableCompilationUnits) {
          CompilationUnit ast = unit.compilationUnit;
          if (ast != null) {
            computer.add(ast, unit.source, library.librarySource);
          }
        }
      }
      computer.computeValues();
      // As a temporary workaround for issue 21572, run ConstantVerifier now.
      // TODO(paulberry): remove this workaround once issue 21572 is fixed.
      for (ResolvableLibrary library in _librariesInCycle) {
        for (ResolvableCompilationUnit unit
            in library.resolvableCompilationUnits) {
          CompilationUnit ast = unit.compilationUnit;
          ErrorReporter errorReporter =
              new ErrorReporter(_errorListener, unit.source);
          ConstantVerifier constantVerifier = new ConstantVerifier(
              errorReporter,
              library.libraryElement,
              _typeProvider,
              analysisContext.declaredVariables);
          ast.accept(constantVerifier);
        }
      }
    });
  }

  /**
   * Resolve the identifiers and perform type analysis in the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the identifiers could not be resolved or if any of the
   *           libraries could not have their types analyzed
   */
  void _resolveReferencesAndTypes() {
    for (ResolvableLibrary library in _librariesInCycle) {
      _resolveReferencesAndTypesInLibrary(library);
    }
  }

  /**
   * Resolve the identifiers and perform type analysis in the given library.
   *
   * @param library the library to be resolved
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   *           the library cannot be analyzed
   */
  void _resolveReferencesAndTypesInLibrary(ResolvableLibrary library) {
    PerformanceStatistics.resolve.makeCurrentWhile(() {
      for (ResolvableCompilationUnit unit
          in library.resolvableCompilationUnits) {
        Source source = unit.source;
        CompilationUnit ast = unit.compilationUnit;
        ast.accept(new VariableResolverVisitor(library.libraryElement, source,
            _typeProvider, library.libraryScope.errorListener,
            nameScope: library.libraryScope));
        ResolverVisitor visitor = new ResolverVisitor(library.libraryElement,
            source, _typeProvider, library._libraryScope.errorListener,
            nameScope: library._libraryScope,
            inheritanceManager: library.inheritanceManager);
        ast.accept(visitor);
      }
    });
  }

  /**
   * Report that the async library could not be resolved in the given
   * [analysisContext] and throw an exception.  [asyncLibrarySource] is the source
   * representing the async library.
   */
  static void missingAsyncLibrary(
      AnalysisContext analysisContext, Source asyncLibrarySource) {
    throw new AnalysisException("Could not resolve dart:async");
  }

  /**
   * Report that the core library could not be resolved in the given analysis context and throw an
   * exception.
   *
   * @param analysisContext the analysis context in which the failure occurred
   * @param coreLibrarySource the source representing the core library
   * @throws AnalysisException always
   */
  static void missingCoreLibrary(
      AnalysisContext analysisContext, Source coreLibrarySource) {
    throw new AnalysisException("Could not resolve dart:core");
  }
}

/**
 * Instances of the class `TypeAliasInfo` hold information about a [TypeAlias].
 */
class LibraryResolver2_TypeAliasInfo {
  final ResolvableLibrary _library;

  final Source _source;

  final FunctionTypeAlias _typeAlias;

  /**
   * Initialize a newly created information holder with the given information.
   *
   * @param library the library containing the type alias
   * @param source the source of the file containing the type alias
   * @param typeAlias the type alias being remembered
   */
  LibraryResolver2_TypeAliasInfo(this._library, this._source, this._typeAlias);
}

/**
 * Instances of the class `TypeAliasInfo` hold information about a [TypeAlias].
 */
class LibraryResolver_TypeAliasInfo {
  final Library _library;

  final Source _source;

  final FunctionTypeAlias _typeAlias;

  /**
   * Initialize a newly created information holder with the given information.
   *
   * @param library the library containing the type alias
   * @param source the source of the file containing the type alias
   * @param typeAlias the type alias being remembered
   */
  LibraryResolver_TypeAliasInfo(this._library, this._source, this._typeAlias);
}

/**
 * Instances of the class `LibraryScope` implement a scope containing all of the names defined
 * in a given library.
 */
class LibraryScope extends EnclosedScope {
  /**
   * Initialize a newly created scope representing the names defined in the given library.
   *
   * @param definingLibrary the element representing the library represented by this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryScope(
      LibraryElement definingLibrary, AnalysisErrorListener errorListener)
      : super(new LibraryImportScope(definingLibrary, errorListener)) {
    _defineTopLevelNames(definingLibrary);
  }

  @override
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PrefixElement) {
      // TODO(scheglov) consider providing actual 'nameOffset' from the
      // synthetic accessor
      int offset = duplicate.nameOffset;
      if (duplicate is PropertyAccessorElement) {
        PropertyAccessorElement accessor = duplicate;
        if (accessor.isSynthetic) {
          offset = accessor.variable.nameOffset;
        }
      }
      return new AnalysisError(
          duplicate.source,
          offset,
          duplicate.displayName.length,
          CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
          [existing.displayName]);
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Add to this scope all of the public top-level names that are defined in the given compilation
   * unit.
   *
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   *          scope
   */
  void _defineLocalNames(CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      define(element);
    }
    for (ClassElement element in compilationUnit.enums) {
      define(element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      define(element);
    }
    for (FunctionTypeAliasElement element
        in compilationUnit.functionTypeAliases) {
      define(element);
    }
    for (ClassElement element in compilationUnit.types) {
      define(element);
    }
  }

  /**
   * Add to this scope all of the names that are explicitly defined in the given library.
   *
   * @param definingLibrary the element representing the library that defines the names in this
   *          scope
   */
  void _defineTopLevelNames(LibraryElement definingLibrary) {
    for (PrefixElement prefix in definingLibrary.prefixes) {
      define(prefix);
    }
    _defineLocalNames(definingLibrary.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in definingLibrary.parts) {
      _defineLocalNames(compilationUnit);
    }
  }
}

/**
 * This class is used to replace uses of `HashMap<String, ExecutableElement>`
 * which are not as performant as this class.
 */
class MemberMap {
  /**
   * The current size of this map.
   */
  int _size = 0;

  /**
   * The array of keys.
   */
  List<String> _keys;

  /**
   * The array of ExecutableElement values.
   */
  List<ExecutableElement> _values;

  /**
   * Initialize a newly created member map to have the given [initialCapacity].
   * The map will grow if needed.
   */
  MemberMap([int initialCapacity = 10]) {
    _initArrays(initialCapacity);
  }

  /**
   * This constructor takes an initial capacity of the map.
   *
   * @param initialCapacity the initial capacity
   */
  @deprecated // Use new MemberMap(initialCapacity)
  MemberMap.con1(int initialCapacity) {
    _initArrays(initialCapacity);
  }

  /**
   * Copy constructor.
   */
  @deprecated // Use new MemberMap.from(memberMap)
  MemberMap.con2(MemberMap memberMap) {
    _initArrays(memberMap._size + 5);
    for (int i = 0; i < memberMap._size; i++) {
      _keys[i] = memberMap._keys[i];
      _values[i] = memberMap._values[i];
    }
    _size = memberMap._size;
  }

  /**
   * Initialize a newly created member map to contain the same members as the
   * given [memberMap].
   */
  MemberMap.from(MemberMap memberMap) {
    _initArrays(memberMap._size + 5);
    for (int i = 0; i < memberMap._size; i++) {
      _keys[i] = memberMap._keys[i];
      _values[i] = memberMap._values[i];
    }
    _size = memberMap._size;
  }

  /**
   * The size of the map.
   *
   * @return the size of the map.
   */
  int get size => _size;

  /**
   * Given some key, return the ExecutableElement value from the map, if the key does not exist in
   * the map, `null` is returned.
   *
   * @param key some key to look up in the map
   * @return the associated ExecutableElement value from the map, if the key does not exist in the
   *         map, `null` is returned
   */
  ExecutableElement get(String key) {
    for (int i = 0; i < _size; i++) {
      if (_keys[i] != null && _keys[i] == key) {
        return _values[i];
      }
    }
    return null;
  }

  /**
   * Get and return the key at the specified location. If the key/value pair has been removed from
   * the set, then `null` is returned.
   *
   * @param i some non-zero value less than size
   * @return the key at the passed index
   * @throw ArrayIndexOutOfBoundsException this exception is thrown if the passed index is less than
   *        zero or greater than or equal to the capacity of the arrays
   */
  String getKey(int i) => _keys[i];

  /**
   * Get and return the ExecutableElement at the specified location. If the key/value pair has been
   * removed from the set, then then `null` is returned.
   *
   * @param i some non-zero value less than size
   * @return the key at the passed index
   * @throw ArrayIndexOutOfBoundsException this exception is thrown if the passed index is less than
   *        zero or greater than or equal to the capacity of the arrays
   */
  ExecutableElement getValue(int i) => _values[i];

  /**
   * Given some key/value pair, store the pair in the map. If the key exists already, then the new
   * value overrides the old value.
   *
   * @param key the key to store in the map
   * @param value the ExecutableElement value to store in the map
   */
  void put(String key, ExecutableElement value) {
    // If we already have a value with this key, override the value
    for (int i = 0; i < _size; i++) {
      if (_keys[i] != null && _keys[i] == key) {
        _values[i] = value;
        return;
      }
    }
    // If needed, double the size of our arrays and copy values over in both
    // arrays
    if (_size == _keys.length) {
      int newArrayLength = _size * 2;
      List<String> keys_new_array = new List<String>(newArrayLength);
      List<ExecutableElement> values_new_array =
          new List<ExecutableElement>(newArrayLength);
      for (int i = 0; i < _size; i++) {
        keys_new_array[i] = _keys[i];
      }
      for (int i = 0; i < _size; i++) {
        values_new_array[i] = _values[i];
      }
      _keys = keys_new_array;
      _values = values_new_array;
    }
    // Put new value at end of array
    _keys[_size] = key;
    _values[_size] = value;
    _size++;
  }

  /**
   * Given some [String] key, this method replaces the associated key and value pair with
   * `null`. The size is not decremented with this call, instead it is expected that the users
   * check for `null`.
   *
   * @param key the key of the key/value pair to remove from the map
   */
  void remove(String key) {
    for (int i = 0; i < _size; i++) {
      if (_keys[i] == key) {
        _keys[i] = null;
        _values[i] = null;
        return;
      }
    }
  }

  /**
   * Sets the ExecutableElement at the specified location.
   *
   * @param i some non-zero value less than size
   * @param value the ExecutableElement value to store in the map
   */
  void setValue(int i, ExecutableElement value) {
    _values[i] = value;
  }

  /**
   * Initializes [keys] and [values].
   */
  void _initArrays(int initialCapacity) {
    _keys = new List<String>(initialCapacity);
    _values = new List<ExecutableElement>(initialCapacity);
  }
}

/**
 * Instances of the class `Namespace` implement a mapping of identifiers to the elements
 * represented by those identifiers. Namespaces are the building blocks for scopes.
 */
class Namespace {
  /**
   * An empty namespace.
   */
  static Namespace EMPTY = new Namespace(new HashMap<String, Element>());

  /**
   * A table mapping names that are defined in this namespace to the element representing the thing
   * declared with that name.
   */
  final HashMap<String, Element> _definedNames;

  /**
   * Initialize a newly created namespace to have the given defined names.
   *
   * @param definedNames the mapping from names that are defined in this namespace to the
   *          corresponding elements
   */
  Namespace(this._definedNames);

  /**
   * Return a table containing the same mappings as those defined by this namespace.
   *
   * @return a table containing the same mappings as those defined by this namespace
   */
  Map<String, Element> get definedNames =>
      new HashMap<String, Element>.from(_definedNames);

  /**
   * Return the element in this namespace that is available to the containing scope using the given
   * name.
   *
   * @param name the name used to reference the
   * @return the element represented by the given identifier
   */
  Element get(String name) => _definedNames[name];
}

/**
 * Instances of the class `NamespaceBuilder` are used to build a `Namespace`. Namespace
 * builders are thread-safe and re-usable.
 */
class NamespaceBuilder {
  /**
   * Create a namespace representing the export namespace of the given [ExportElement].
   *
   * @param element the export element whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespaceForDirective(ExportElement element) {
    LibraryElement exportedLibrary = element.exportedLibrary;
    if (exportedLibrary == null) {
      //
      // The exported library will be null if the URI does not reference a valid
      // library.
      //
      return Namespace.EMPTY;
    }
    HashMap<String, Element> definedNames =
        _createExportMapping(exportedLibrary, new HashSet<LibraryElement>());
    definedNames = _applyCombinators(definedNames, element.combinators);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the export namespace of the given library.
   *
   * @param library the library whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespaceForLibrary(LibraryElement library) =>
      new Namespace(
          _createExportMapping(library, new HashSet<LibraryElement>()));

  /**
   * Create a namespace representing the import namespace of the given library.
   *
   * @param library the library whose import namespace is to be created
   * @return the import namespace that was created
   */
  Namespace createImportNamespaceForDirective(ImportElement element) {
    LibraryElement importedLibrary = element.importedLibrary;
    if (importedLibrary == null) {
      //
      // The imported library will be null if the URI does not reference a valid
      // library.
      //
      return Namespace.EMPTY;
    }
    HashMap<String, Element> definedNames =
        _createExportMapping(importedLibrary, new HashSet<LibraryElement>());
    definedNames = _applyCombinators(definedNames, element.combinators);
    definedNames = _applyPrefix(definedNames, element.prefix);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the public namespace of the given library.
   *
   * @param library the library whose public namespace is to be created
   * @return the public namespace that was created
   */
  Namespace createPublicNamespaceForLibrary(LibraryElement library) {
    HashMap<String, Element> definedNames = new HashMap<String, Element>();
    _addPublicNames(definedNames, library.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in library.parts) {
      _addPublicNames(definedNames, compilationUnit);
    }
    return new Namespace(definedNames);
  }

  /**
   * Add all of the names in the given namespace to the given mapping table.
   *
   * @param definedNames the mapping table to which the names in the given namespace are to be added
   * @param namespace the namespace containing the names to be added to this namespace
   */
  void _addAllFromNamespace(
      Map<String, Element> definedNames, Namespace namespace) {
    if (namespace != null) {
      definedNames.addAll(namespace.definedNames);
    }
  }

  /**
   * Add the given element to the given mapping table if it has a publicly visible name.
   *
   * @param definedNames the mapping table to which the public name is to be added
   * @param element the element to be added
   */
  void _addIfPublic(Map<String, Element> definedNames, Element element) {
    String name = element.name;
    if (name != null && !Scope.isPrivateName(name)) {
      definedNames[name] = element;
    }
  }

  /**
   * Add to the given mapping table all of the public top-level names that are defined in the given
   * compilation unit.
   *
   * @param definedNames the mapping table to which the public names are to be added
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   *          namespace
   */
  void _addPublicNames(Map<String, Element> definedNames,
      CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      _addIfPublic(definedNames, element);
    }
    for (ClassElement element in compilationUnit.enums) {
      _addIfPublic(definedNames, element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      _addIfPublic(definedNames, element);
    }
    for (FunctionTypeAliasElement element
        in compilationUnit.functionTypeAliases) {
      _addIfPublic(definedNames, element);
    }
    for (ClassElement element in compilationUnit.types) {
      _addIfPublic(definedNames, element);
    }
  }

  /**
   * Apply the given combinators to all of the names in the given mapping table.
   *
   * @param definedNames the mapping table to which the namespace operations are to be applied
   * @param combinators the combinators to be applied
   */
  HashMap<String, Element> _applyCombinators(
      HashMap<String, Element> definedNames,
      List<NamespaceCombinator> combinators) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        _hide(definedNames, combinator.hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = _show(definedNames, combinator.shownNames);
      } else {
        // Internal error.
        AnalysisEngine.instance.logger
            .logError("Unknown type of combinator: ${combinator.runtimeType}");
      }
    }
    return definedNames;
  }

  /**
   * Apply the given prefix to all of the names in the table of defined names.
   *
   * @param definedNames the names that were defined before this operation
   * @param prefixElement the element defining the prefix to be added to the names
   */
  HashMap<String, Element> _applyPrefix(
      HashMap<String, Element> definedNames, PrefixElement prefixElement) {
    if (prefixElement != null) {
      String prefix = prefixElement.name;
      HashMap<String, Element> newNames = new HashMap<String, Element>();
      definedNames.forEach((String name, Element element) {
        newNames["$prefix.$name"] = element;
      });
      return newNames;
    } else {
      return definedNames;
    }
  }

  /**
   * Create a mapping table representing the export namespace of the given library.
   *
   * @param library the library whose public namespace is to be created
   * @param visitedElements a set of libraries that do not need to be visited when processing the
   *          export directives of the given library because all of the names defined by them will
   *          be added by another library
   * @return the mapping table that was created
   */
  HashMap<String, Element> _createExportMapping(
      LibraryElement library, HashSet<LibraryElement> visitedElements) {
    // Check if the export namespace has been already computed.
    {
      Namespace exportNamespace = library.exportNamespace;
      if (exportNamespace != null) {
        return exportNamespace.definedNames;
      }
    }
    // TODO(scheglov) Remove this after switching to the new task model.
    visitedElements.add(library);
    try {
      HashMap<String, Element> definedNames = new HashMap<String, Element>();
      for (ExportElement element in library.exports) {
        LibraryElement exportedLibrary = element.exportedLibrary;
        if (exportedLibrary != null &&
            !visitedElements.contains(exportedLibrary)) {
          //
          // The exported library will be null if the URI does not reference a
          // valid library.
          //
          HashMap<String, Element> exportedNames =
              _createExportMapping(exportedLibrary, visitedElements);
          exportedNames = _applyCombinators(exportedNames, element.combinators);
          definedNames.addAll(exportedNames);
        }
      }
      _addAllFromNamespace(
          definedNames,
          (library.context as InternalAnalysisContext)
              .getPublicNamespace(library));
      return definedNames;
    } finally {
      visitedElements.remove(library);
    }
  }

  /**
   * Hide all of the given names by removing them from the given collection of defined names.
   *
   * @param definedNames the names that were defined before this operation
   * @param hiddenNames the names to be hidden
   */
  void _hide(HashMap<String, Element> definedNames, List<String> hiddenNames) {
    for (String name in hiddenNames) {
      definedNames.remove(name);
      definedNames.remove("$name=");
    }
  }

  /**
   * Show only the given names by removing all other names from the given collection of defined
   * names.
   *
   * @param definedNames the names that were defined before this operation
   * @param shownNames the names to be shown
   */
  HashMap<String, Element> _show(
      HashMap<String, Element> definedNames, List<String> shownNames) {
    HashMap<String, Element> newNames = new HashMap<String, Element>();
    for (String name in shownNames) {
      Element element = definedNames[name];
      if (element != null) {
        newNames[name] = element;
      }
      String setterName = "$name=";
      element = definedNames[setterName];
      if (element != null) {
        newNames[setterName] = element;
      }
    }
    return newNames;
  }
}

/**
 * Instances of the class `OverrideVerifier` visit all of the declarations in a compilation
 * unit to verify that if they have an override annotation it is being used correctly.
 */
class OverrideVerifier extends RecursiveAstVisitor<Object> {
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
  Object visitMethodDeclaration(MethodDeclaration node) {
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
    return super.visitMethodDeclaration(node);
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
   * A flag indicating whether the resolver is being run in strong mode.
   */
  final bool strongMode;

  /**
   * The static variables that have an initializer. These are the variables that
   * need to be re-resolved after static variables have their types inferred. A
   * subset of these variables are those whose types should be inferred. The
   * list will be empty unless the resolver is being run in strong mode.
   */
  final List<VariableElement> staticVariables = <VariableElement>[];

  /**
   * A flag indicating whether we are currently visiting a child of either a
   * field or a top-level variable.
   */
  bool inFieldOrTopLevelVariable = false;

  /**
   * A flag indicating whether we should discard errors while resolving the
   * initializer for variable declarations. We do this for top-level variables
   * and fields because their initializer will be re-resolved at a later time.
   */
  bool discardErrorsInInitializer = false;

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
      {Scope nameScope,
      InheritanceManager inheritanceManager,
      StaticTypeAnalyzerFactory typeAnalyzerFactory})
      : strongMode = definingLibrary.context.analysisOptions.strongMode,
        super(definingLibrary, source, typeProvider,
            new DisablableErrorListener(errorListener));

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    if (inFieldOrTopLevelVariable) {
      return super.visitBlockFunctionBody(node);
    }
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (inFieldOrTopLevelVariable) {
      return super.visitExpressionFunctionBody(node);
    }
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    bool wasInFieldOrTopLevelVariable = inFieldOrTopLevelVariable;
    try {
      inFieldOrTopLevelVariable = true;
      if (strongMode && node.isStatic) {
        _addStaticVariables(node.fields.variables);
        bool wasDiscarding = discardErrorsInInitializer;
        discardErrorsInInitializer = true;
        try {
          return super.visitFieldDeclaration(node);
        } finally {
          discardErrorsInInitializer = wasDiscarding;
        }
      }
      return super.visitFieldDeclaration(node);
    } finally {
      inFieldOrTopLevelVariable = wasInFieldOrTopLevelVariable;
    }
  }

  @override
  Object visitNode(AstNode node) {
    if (discardErrorsInInitializer) {
      AstNode parent = node.parent;
      if (parent is VariableDeclaration && parent.initializer == node) {
        DisablableErrorListener listener = errorListener;
        return listener.disableWhile(() => super.visitNode(node));
      }
    }
    return super.visitNode(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    bool wasInFieldOrTopLevelVariable = inFieldOrTopLevelVariable;
    try {
      inFieldOrTopLevelVariable = true;
      if (strongMode) {
        _addStaticVariables(node.variables.variables);
        bool wasDiscarding = discardErrorsInInitializer;
        discardErrorsInInitializer = true;
        try {
          return super.visitTopLevelVariableDeclaration(node);
        } finally {
          discardErrorsInInitializer = wasDiscarding;
        }
      }
      return super.visitTopLevelVariableDeclaration(node);
    } finally {
      inFieldOrTopLevelVariable = wasInFieldOrTopLevelVariable;
    }
  }

  /**
   * Add all of the [variables] with initializers to the list of variables whose
   * type can be inferred. Technically, we only infer the types of variables
   * that do not have a static type, but all variables with initializers
   * potentially need to be re-resolved after inference because they might
   * refer to a field whose type was inferred.
   */
  void _addStaticVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      if (variable.initializer != null) {
        staticVariables.add(variable.element);
      }
    }
  }
}

/**
 * Instances of the class `PubVerifier` traverse an AST structure looking for deviations from
 * pub best practices.
 */
class PubVerifier extends RecursiveAstVisitor<Object> {
//  static String _PUBSPEC_YAML = "pubspec.yaml";

  /**
   * The analysis context containing the sources to be analyzed
   */
  final AnalysisContext _context;

  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  PubVerifier(this._context, this._errorReporter);

  @override
  Object visitImportDirective(ImportDirective directive) {
    return null;
  }

//  /**
//   * This verifies that the passed file import directive is not contained in a source inside a
//   * package "lib" directory hierarchy referencing a source outside that package "lib" directory
//   * hierarchy.
//   *
//   * @param uriLiteral the import URL (not `null`)
//   * @param path the file path being verified (not `null`)
//   * @return `true` if and only if an error code is generated on the passed node
//   * See [PubSuggestionCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE].
//   */
//  bool
//      _checkForFileImportInsideLibReferencesFileOutside(StringLiteral uriLiteral,
//      String path) {
//    Source source = _getSource(uriLiteral);
//    String fullName = _getSourceFullName(source);
//    if (fullName != null) {
//      int pathIndex = 0;
//      int fullNameIndex = fullName.length;
//      while (pathIndex < path.length &&
//          StringUtilities.startsWith3(path, pathIndex, 0x2E, 0x2E, 0x2F)) {
//        fullNameIndex = JavaString.lastIndexOf(fullName, '/', fullNameIndex);
//        if (fullNameIndex < 4) {
//          return false;
//        }
//        // Check for "/lib" at a specified place in the fullName
//        if (StringUtilities.startsWith4(
//            fullName,
//            fullNameIndex - 4,
//            0x2F,
//            0x6C,
//            0x69,
//            0x62)) {
//          String relativePubspecPath =
//              path.substring(0, pathIndex + 3) +
//              _PUBSPEC_YAML;
//          Source pubspecSource =
//              _context.sourceFactory.resolveUri(source, relativePubspecPath);
//          if (_context.exists(pubspecSource)) {
//            // Files inside the lib directory hierarchy should not reference
//            // files outside
//            _errorReporter.reportErrorForNode(
//                HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE,
//                uriLiteral);
//          }
//          return true;
//        }
//        pathIndex += 3;
//      }
//    }
//    return false;
//  }

//  /**
//   * This verifies that the passed file import directive is not contained in a source outside a
//   * package "lib" directory hierarchy referencing a source inside that package "lib" directory
//   * hierarchy.
//   *
//   * @param uriLiteral the import URL (not `null`)
//   * @param path the file path being verified (not `null`)
//   * @return `true` if and only if an error code is generated on the passed node
//   * See [PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE].
//   */
//  bool
//      _checkForFileImportOutsideLibReferencesFileInside(StringLiteral uriLiteral,
//      String path) {
//    if (StringUtilities.startsWith4(path, 0, 0x6C, 0x69, 0x62, 0x2F)) {
//      if (_checkForFileImportOutsideLibReferencesFileInsideAtIndex(
//          uriLiteral,
//          path,
//          0)) {
//        return true;
//      }
//    }
//    int pathIndex =
//        StringUtilities.indexOf5(path, 0, 0x2F, 0x6C, 0x69, 0x62, 0x2F);
//    while (pathIndex != -1) {
//      if (_checkForFileImportOutsideLibReferencesFileInsideAtIndex(
//          uriLiteral,
//          path,
//          pathIndex + 1)) {
//        return true;
//      }
//      pathIndex =
//          StringUtilities.indexOf5(path, pathIndex + 4, 0x2F, 0x6C, 0x69, 0x62, 0x2F);
//    }
//    return false;
//  }

//  bool
//      _checkForFileImportOutsideLibReferencesFileInsideAtIndex(StringLiteral uriLiteral,
//      String path, int pathIndex) {
//    Source source = _getSource(uriLiteral);
//    String relativePubspecPath = path.substring(0, pathIndex) + _PUBSPEC_YAML;
//    Source pubspecSource =
//        _context.sourceFactory.resolveUri(source, relativePubspecPath);
//    if (!_context.exists(pubspecSource)) {
//      return false;
//    }
//    String fullName = _getSourceFullName(source);
//    if (fullName != null) {
//      if (StringUtilities.indexOf5(fullName, 0, 0x2F, 0x6C, 0x69, 0x62, 0x2F) <
//          0) {
//        // Files outside the lib directory hierarchy should not reference files
//        // inside ... use package: url instead
//        _errorReporter.reportErrorForNode(
//            HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE,
//            uriLiteral);
//        return true;
//      }
//    }
//    return false;
//  }

//  /**
//   * This verifies that the passed package import directive does not contain ".."
//   *
//   * @param uriLiteral the import URL (not `null`)
//   * @param path the path to be validated (not `null`)
//   * @return `true` if and only if an error code is generated on the passed node
//   * See [PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT].
//   */
//  bool _checkForPackageImportContainsDotDot(StringLiteral uriLiteral,
//      String path) {
//    if (StringUtilities.startsWith3(path, 0, 0x2E, 0x2E, 0x2F) ||
//        StringUtilities.indexOf4(path, 0, 0x2F, 0x2E, 0x2E, 0x2F) >= 0) {
//      // Package import should not to contain ".."
//      _errorReporter.reportErrorForNode(
//          HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT,
//          uriLiteral);
//      return true;
//    }
//    return false;
//  }

//  /**
//   * Answer the source associated with the compilation unit containing the given AST node.
//   *
//   * @param node the node (not `null`)
//   * @return the source or `null` if it could not be determined
//   */
//  Source _getSource(AstNode node) {
//    Source source = null;
//    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
//    if (unit != null) {
//      CompilationUnitElement element = unit.element;
//      if (element != null) {
//        source = element.source;
//      }
//    }
//    return source;
//  }

//  /**
//   * Answer the full name of the given source. The returned value will have all
//   * [File.separatorChar] replace by '/'.
//   *
//   * @param source the source
//   * @return the full name or `null` if it could not be determined
//   */
//  String _getSourceFullName(Source source) {
//    if (source != null) {
//      String fullName = source.fullName;
//      if (fullName != null) {
//        return fullName.replaceAll(r'\', '/');
//      }
//    }
//    return null;
//  }
}

/**
 * Kind of the redirecting constructor.
 */
class RedirectingConstructorKind extends Enum<RedirectingConstructorKind> {
  static const RedirectingConstructorKind CONST =
      const RedirectingConstructorKind('CONST', 0);

  static const RedirectingConstructorKind NORMAL =
      const RedirectingConstructorKind('NORMAL', 1);

  static const List<RedirectingConstructorKind> values = const [CONST, NORMAL];

  const RedirectingConstructorKind(String name, int ordinal)
      : super(name, ordinal);
}

/**
 * A `ResolvableLibrary` represents a single library during the resolution of
 * some (possibly different) library. They are not intended to be used except
 * during the resolution process.
 */
class ResolvableLibrary {
  /**
   * An empty array that can be used to initialize lists of libraries.
   */
  static List<ResolvableLibrary> _EMPTY_ARRAY = new List<ResolvableLibrary>(0);

  /**
   * The next artificial hash code.
   */
  static int _NEXT_HASH_CODE = 0;

  /**
   * The artifitial hash code for this object.
   */
  final int _hashCode = _nextHashCode();

  /**
   * The source specifying the defining compilation unit of this library.
   */
  final Source librarySource;

  /**
   * A list containing all of the libraries that are imported into this library.
   */
  List<ResolvableLibrary> _importedLibraries = _EMPTY_ARRAY;

  /**
   * A flag indicating whether this library explicitly imports core.
   */
  bool explicitlyImportsCore = false;

  /**
   * An array containing all of the libraries that are exported from this library.
   */
  List<ResolvableLibrary> _exportedLibraries = _EMPTY_ARRAY;

  /**
   * An array containing the compilation units that comprise this library. The
   * defining compilation unit is always first.
   */
  List<ResolvableCompilationUnit> _compilationUnits;

  /**
   * The library element representing this library.
   */
  LibraryElementImpl _libraryElement;

  /**
   * The listener to which analysis errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The inheritance manager which is used for member lookups in this library.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The library scope used when resolving elements within this library's compilation units.
   */
  LibraryScope _libraryScope;

  /**
   * Initialize a newly created data holder that can maintain the data associated with a library.
   *
   * @param librarySource the source specifying the defining compilation unit of this library
   * @param errorListener the listener to which analysis errors will be reported
   */
  ResolvableLibrary(this.librarySource);

  /**
   * Return an array of the [CompilationUnit]s that make up the library. The first unit is
   * always the defining unit.
   *
   * @return an array of the [CompilationUnit]s that make up the library. The first unit is
   *         always the defining unit
   */
  List<CompilationUnit> get compilationUnits {
    int count = _compilationUnits.length;
    List<CompilationUnit> units = new List<CompilationUnit>(count);
    for (int i = 0; i < count; i++) {
      units[i] = _compilationUnits[i].compilationUnit;
    }
    return units;
  }

  /**
   * Return an array containing the sources for the compilation units in this library, including the
   * defining compilation unit.
   *
   * @return the sources for the compilation units in this library
   */
  List<Source> get compilationUnitSources {
    int count = _compilationUnits.length;
    List<Source> sources = new List<Source>(count);
    for (int i = 0; i < count; i++) {
      sources[i] = _compilationUnits[i].source;
    }
    return sources;
  }

  /**
   * Return the AST structure associated with the defining compilation unit for this library.
   *
   * @return the AST structure associated with the defining compilation unit for this library
   * @throws AnalysisException if an AST structure could not be created for the defining compilation
   *           unit
   */
  CompilationUnit get definingCompilationUnit =>
      _compilationUnits[0].compilationUnit;

  /**
   * Set the listener to which analysis errors will be reported to be the given listener.
   *
   * @param errorListener the listener to which analysis errors will be reported
   */
  void set errorListener(AnalysisErrorListener errorListener) {
    this._errorListener = errorListener;
  }

  /**
   * Set the libraries that are exported by this library to be those in the given array.
   *
   * @param exportedLibraries the libraries that are exported by this library
   */
  void set exportedLibraries(List<ResolvableLibrary> exportedLibraries) {
    this._exportedLibraries = exportedLibraries;
  }

  /**
   * Return an array containing the libraries that are exported from this library.
   *
   * @return an array containing the libraries that are exported from this library
   */
  List<ResolvableLibrary> get exports => _exportedLibraries;

  @override
  int get hashCode => _hashCode;

  /**
   * Set the libraries that are imported into this library to be those in the given array.
   *
   * @param importedLibraries the libraries that are imported into this library
   */
  void set importedLibraries(List<ResolvableLibrary> importedLibraries) {
    this._importedLibraries = importedLibraries;
  }

  /**
   * Return an array containing the libraries that are imported into this library.
   *
   * @return an array containing the libraries that are imported into this library
   */
  List<ResolvableLibrary> get imports => _importedLibraries;

  /**
   * Return an array containing the libraries that are either imported or exported from this
   * library.
   *
   * @return the libraries that are either imported or exported from this library
   */
  List<ResolvableLibrary> get importsAndExports {
    HashSet<ResolvableLibrary> libraries = new HashSet<ResolvableLibrary>();
    for (ResolvableLibrary library in _importedLibraries) {
      libraries.add(library);
    }
    for (ResolvableLibrary library in _exportedLibraries) {
      libraries.add(library);
    }
    return new List.from(libraries);
  }

  /**
   * Return the inheritance manager for this library.
   *
   * @return the inheritance manager for this library
   */
  InheritanceManager get inheritanceManager {
    if (_inheritanceManager == null) {
      return _inheritanceManager = new InheritanceManager(_libraryElement);
    }
    return _inheritanceManager;
  }

  /**
   * Return the library element representing this library, creating it if necessary.
   *
   * @return the library element representing this library
   */
  LibraryElementImpl get libraryElement => _libraryElement;

  /**
   * Set the library element representing this library to the given library element.
   *
   * @param libraryElement the library element representing this library
   */
  void set libraryElement(LibraryElementImpl libraryElement) {
    this._libraryElement = libraryElement;
    if (_inheritanceManager != null) {
      _inheritanceManager.libraryElement = libraryElement;
    }
  }

  /**
   * Return the library scope used when resolving elements within this library's compilation units.
   *
   * @return the library scope used when resolving elements within this library's compilation units
   */
  LibraryScope get libraryScope {
    if (_libraryScope == null) {
      _libraryScope = new LibraryScope(_libraryElement, _errorListener);
    }
    return _libraryScope;
  }

  /**
   * Return an array containing the compilation units that comprise this library. The defining
   * compilation unit is always first.
   *
   * @return the compilation units that comprise this library
   */
  List<ResolvableCompilationUnit> get resolvableCompilationUnits =>
      _compilationUnits;

  /**
   * Set the compilation unit in this library to the given compilation units. The defining
   * compilation unit must be the first element of the array.
   *
   * @param units the compilation units in this library
   */
  void set resolvableCompilationUnits(List<ResolvableCompilationUnit> units) {
    _compilationUnits = units;
  }

  /**
   * Return the AST structure associated with the given source, or `null` if the source does
   * not represent a compilation unit that is included in this library.
   *
   * @param source the source representing the compilation unit whose AST is to be returned
   * @return the AST structure associated with the given source
   * @throws AnalysisException if an AST structure could not be created for the compilation unit
   */
  CompilationUnit getAST(Source source) {
    int count = _compilationUnits.length;
    for (int i = 0; i < count; i++) {
      if (_compilationUnits[i].source == source) {
        return _compilationUnits[i].compilationUnit;
      }
    }
    return null;
  }

  @override
  String toString() => librarySource.shortName;

  static int _nextHashCode() {
    int next = (_NEXT_HASH_CODE + 1) & 0xFFFFFF;
    _NEXT_HASH_CODE = next;
    return next;
  }
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
   * The manager for the inheritance mappings.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The object used to resolve the element associated with the current node.
   */
  ElementResolver elementResolver;

  /**
   * The object used to compute the type associated with the current node.
   */
  StaticTypeAnalyzer typeAnalyzer;

  /**
   * The class element representing the class containing the current node,
   * or `null` if the current node is not contained in a class.
   */
  ClassElement enclosingClass = null;

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

  /**
   * The [Comment] before a [FunctionDeclaration] or a [MethodDeclaration] that
   * cannot be resolved where we visited it, because it should be resolved in the scope of the body.
   */
  Comment _commentBeforeFunction = null;

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
      {Scope nameScope,
      InheritanceManager inheritanceManager,
      StaticTypeAnalyzerFactory typeAnalyzerFactory})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    if (inheritanceManager == null) {
      this._inheritanceManager = new InheritanceManager(definingLibrary);
    } else {
      this._inheritanceManager = inheritanceManager;
    }
    this.elementResolver = new ElementResolver(this);
    if (typeAnalyzerFactory == null) {
      this.typeAnalyzer = new StaticTypeAnalyzer(this);
    } else {
      this.typeAnalyzer = typeAnalyzerFactory(this);
    }
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   *
   * Deprecated.  Please use unnamed constructor instead.
   */
  @deprecated
  ResolverVisitor.con1(
      Library library, Source source, TypeProvider typeProvider,
      {StaticTypeAnalyzerFactory typeAnalyzerFactory})
      : this(
            library.libraryElement, source, typeProvider, library.errorListener,
            nameScope: library.libraryScope,
            inheritanceManager: library.inheritanceManager,
            typeAnalyzerFactory: typeAnalyzerFactory);

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
   * Return the static element associated with the given expression whose type can be promoted, or
   * `null` if there is no element whose type can be promoted.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getPromotionStaticElement(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    if (expression is! SimpleIdentifier) {
      return null;
    }
    SimpleIdentifier identifier = expression as SimpleIdentifier;
    Element element = identifier.staticElement;
    if (element is! VariableElement) {
      return null;
    }
    ElementKind kind = element.kind;
    if (kind == ElementKind.LOCAL_VARIABLE) {
      return element as VariableElement;
    }
    if (kind == ElementKind.PARAMETER) {
      return element as VariableElement;
    }
    return null;
  }

  /**
   * Prepares this [ResolverVisitor] to using it for incremental resolution.
   */
  void initForIncrementalResolution([Declaration declaration = null]) {
    if (declaration != null) {
      Element element = declaration.element;
      if (element is ExecutableElement) {
        _enclosingFunction = element;
      }
      _commentBeforeFunction = declaration.documentationComment;
    }
    _overrideManager.enterScope();
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
    if (potentialType == null || potentialType.isBottom) {
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
      // TODO(scheglov) type propagation for instance/top-level fields
      // was disabled because it depends on the order or visiting.
      // If both field and its client are in the same unit, and we visit
      // the client before the field, then propagated type is not set yet.
//      if (element is PropertyInducingElement) {
//        PropertyInducingElement variable = element;
//        if (!variable.isConst && !variable.isFinal) {
//          return;
//        }
//        (variable as PropertyInducingElementImpl).propagatedType =
//            potentialType;
//      }
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
    typeAnalyzer.thisType = enclosingClass == null ? null : enclosingClass.type;
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
    if (type == null || type.isDynamic || type.isBottom) {
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

  @override
  Object visitAnnotation(Annotation node) {
    AstNode parent = node.parent;
    if (identical(parent, _enclosingClassDeclaration) ||
        identical(parent, _enclosingFunctionTypeAlias)) {
      return null;
    }
    return super.visitAnnotation(node);
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
  Object visitAssertStatement(AssertStatement node) {
    super.visitAssertStatement(node);
    _propagateTrueState(node.condition);
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    sc.TokenType operatorType = node.operator.type;
    Expression leftOperand = node.leftOperand;
    Expression rightOperand = node.rightOperand;
    if (operatorType == sc.TokenType.AMPERSAND_AMPERSAND) {
      safelyVisit(leftOperand);
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
    } else if (operatorType == sc.TokenType.BAR_BAR) {
      safelyVisit(leftOperand);
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
      safelyVisit(leftOperand);
      safelyVisit(rightOperand);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    safelyVisit(_commentBeforeFunction);
    _overrideManager.enterScope();
    try {
      super.visitBlockFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
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
  Object visitClassDeclaration(ClassDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    if (node.metadata != null) {
      node.metadata.accept(this);
    }
    _enclosingClassDeclaration = node;
    //
    // Continue the class resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.element;
      typeAnalyzer.thisType =
          enclosingClass == null ? null : enclosingClass.type;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType == null ? null : outerType.type;
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
    if (node.metadata != null) {
      node.metadata.accept(this);
    }
    _enclosingClassDeclaration = node;
    //
    // Continue the class resolution.
    //
    enclosingClass = node.element;
    typeAnalyzer.thisType = enclosingClass == null ? null : enclosingClass.type;
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  Object visitComment(Comment node) {
    if (node.parent is FunctionDeclaration ||
        node.parent is ConstructorDeclaration ||
        node.parent is MethodDeclaration) {
      if (!identical(node, _commentBeforeFunction)) {
        _commentBeforeFunction = node;
        return null;
      }
    }
    super.visitComment(node);
    _commentBeforeFunction = null;
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
    //
    // TODO(brianwilkerson) The goal of the code below is to visit the
    // declarations in such an order that we can infer type information for
    // top-level variables before we visit references to them. This is better
    // than making no effort, but still doesn't completely satisfy that goal
    // (consider for example "final var a = b; final var b = 0;"; we'll infer a
    // type of 'int' for 'b', but not for 'a' because of the order of the
    // visits). Ideally we would create a dependency graph, but that would
    // require references to be resolved, which they are not.
    //
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
        CompilationUnitMember declaration = declarations[i];
        if (declaration is! ClassDeclaration) {
          declaration.accept(this);
        }
      }
      for (int i = 0; i < declarationCount; i++) {
        CompilationUnitMember declaration = declarations[i];
        if (declaration is ClassDeclaration) {
          declaration.accept(this);
        }
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
    safelyVisit(condition);
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
    try {
      _enclosingFunction = node.element;
      super.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    ConstructorElementImpl constructor = node.element;
    constructor.constantInitializers =
        new ConstantAstCloner().cloneNodeList(node.initializers);
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    safelyVisit(node.expression);
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
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.element;
    if (element.initializer != null && node.defaultValue != null) {
      (element.initializer as FunctionElementImpl).returnType =
          node.defaultValue.staticType;
    }
    FormalParameterList parent = node.parent;
    AstNode grandparent = parent.parent;
    if (grandparent is ConstructorDeclaration &&
        grandparent.constKeyword != null) {
      // For const constructors, we need to clone the ASTs for default formal
      // parameters, so that we can use them during constant evaluation.
      ParameterElement element = node.element;
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
    safelyVisit(_commentBeforeFunction);
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
      ElementResolver.setMetadata(node.element, node);
    }
    //
    // Continue the enum resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.element;
      typeAnalyzer.thisType =
          enclosingClass == null ? null : enclosingClass.type;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType == null ? null : outerType.type;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    safelyVisit(_commentBeforeFunction);
    if (resolveOnlyCommentInFunctionBody) {
      return null;
    }
    _overrideManager.enterScope();
    try {
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
    safelyVisit(iterable);
    DeclaredIdentifier loopVariable = node.loopVariable;
    SimpleIdentifier identifier = node.identifier;
    safelyVisit(loopVariable);
    safelyVisit(identifier);
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
    safelyVisit(node.variables);
    safelyVisit(node.initialization);
    safelyVisit(node.condition);
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
    try {
      SimpleIdentifier functionName = node.name;
      _enclosingFunction = functionName.staticElement as ExecutableElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      _overrideManager.enterScope();
      try {
        super.visitFunctionExpression(node);
      } finally {
        _overrideManager.exitScope();
      }
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    safelyVisit(node.function);
    node.accept(elementResolver);
    _inferFunctionExpressionsParametersTypes(node.argumentList);
    safelyVisit(node.argumentList);
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
  Object visitHideCombinator(HideCombinator node) => null;

  @override
  Object visitIfStatement(IfStatement node) {
    Expression condition = node.condition;
    safelyVisit(condition);
    Map<VariableElement, DartType> thenOverrides =
        new HashMap<VariableElement, DartType>();
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
        new HashMap<VariableElement, DartType>();
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
          new List<Map<VariableElement, DartType>>();
      perBranchOverrides.add(thenOverrides);
      perBranchOverrides.add(elseOverrides);
      _overrideManager.mergeOverrides(perBranchOverrides);
    }
    return null;
  }

  @override
  Object visitLabel(Label node) => null;

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    //
    // We visit the target and argument list, but do not visit the method name
    // because it needs to be visited in the context of the invocation.
    //
    safelyVisit(node.target);
    node.accept(elementResolver);
    _inferFunctionExpressionsParametersTypes(node.argumentList);
    safelyVisit(node.argumentList);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitNode(AstNode node) {
    node.visitChildren(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    //
    // We visit the prefix, but do not visit the identifier because it needs to
    // be visited in the context of the prefix.
    //
    safelyVisit(node.prefix);
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
    safelyVisit(node.target);
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
    safelyVisit(node.argumentList);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
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
    safelyVisit(node.argumentList);
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
  Object visitWhileStatement(WhileStatement node) {
    // Note: since we don't call the base class, we have to maintain
    // _implicitLabelScope ourselves.
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      Expression condition = node.condition;
      safelyVisit(condition);
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
      if ((element as VariableElementImpl).isPotentiallyMutatedInScope) {
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
   * The given expression is the expression used to compute the iterator for a
   * for-each statement. Attempt to compute the type of objects that will be
   * assigned to the loop variable and return that type. Return `null` if the
   * type could not be determined. The [iteratorExpression] is the expression
   * that will return the Iterable being iterated over.
   */
  DartType _getIteratorElementType(Expression iteratorExpression) {
    DartType expressionType = iteratorExpression.bestType;
    if (expressionType is InterfaceType) {
      InterfaceType interfaceType = expressionType;
      FunctionType iteratorFunction =
          _inheritanceManager.lookupMemberType(interfaceType, "iterator");
      if (iteratorFunction == null) {
        // TODO(brianwilkerson) Should we report this error?
        return null;
      }
      DartType iteratorType = iteratorFunction.returnType;
      if (iteratorType is InterfaceType) {
        InterfaceType iteratorInterfaceType = iteratorType;
        FunctionType currentFunction = _inheritanceManager.lookupMemberType(
            iteratorInterfaceType, "current");
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
   * asyncronous for-each statement. Attempt to compute the type of objects that
   * will be assigned to the loop variable and return that type. Return `null`
   * if the type could not be determined. The [streamExpression] is the
   * expression that will return the stream being iterated over.
   */
  DartType _getStreamElementType(Expression streamExpression) {
    DartType streamType = streamExpression.bestType;
    if (streamType is InterfaceType) {
      FunctionType listenFunction =
          _inheritanceManager.lookupMemberType(streamType, "listen");
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
        if (onDataParameters == null || onDataParameters.length < 1) {
          return null;
        }
        DartType eventType = onDataParameters[0].type;
        // TODO(paulberry): checking that typeParameters.isNotEmpty is a
        // band-aid fix for dartbug.com/24191.  Figure out what the correct
        // logic should be.
        if (streamType.typeParameters.isNotEmpty &&
            eventType.element == streamType.typeParameters[0]) {
          return streamType.typeArguments[0];
        }
      }
    }
    return null;
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
        closure.element != null ? closure.element.type : null;
    if (staticClosureType != null &&
        !expectedClosureType.isMoreSpecificThan(staticClosureType)) {
      return;
    }
    // set propagated type for the closure
    closure.propagatedType = expectedClosureType;
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
    for (Expression argument in argumentList.arguments) {
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
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
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
      if (element.isPotentiallyMutatedInClosure) {
        return;
      }
      // prepare current variable type
      DartType type = _promoteManager.getType(element);
      if (type == null) {
        type = expression.staticType;
      }
      // Declared type should not be "dynamic".
      if (type == null || type.isDynamic) {
        return;
      }
      // Promoted type should not be "dynamic".
      if (potentialType == null || potentialType.isDynamic) {
        return;
      }
      // Promoted type should be more specific than declared.
      if (!potentialType.isMoreSpecificThan(type)) {
        return;
      }
      // Do promote type of variable.
      _promoteManager.setType(element, potentialType);
    }
  }

  /**
   * Promotes type information using given condition.
   */
  void _promoteTypes(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition;
      if (binary.operator.type == sc.TokenType.AMPERSAND_AMPERSAND) {
        Expression left = binary.leftOperand;
        Expression right = binary.rightOperand;
        _promoteTypes(left);
        _promoteTypes(right);
        _clearTypePromotionsIfPotentiallyMutatedIn(right);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator == null) {
        _promote(is2.expression, is2.type.type);
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
      BinaryExpression binary = condition;
      if (binary.operator.type == sc.TokenType.BAR_BAR) {
        _propagateFalseState(binary.leftOperand);
        _propagateFalseState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator != null) {
        // Since an is-statement doesn't actually change the type, we don't
        // let it affect the propagated type when it would result in a loss
        // of precision.
        overrideExpression(is2.expression, is2.type.type, false, false);
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition;
      if (prefix.operator.type == sc.TokenType.BANG) {
        _propagateTrueState(prefix.operand);
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
      BinaryExpression binary = condition;
      if (binary.operator.type == sc.TokenType.AMPERSAND_AMPERSAND) {
        _propagateTrueState(binary.leftOperand);
        _propagateTrueState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator == null) {
        // Since an is-statement doesn't actually change the type, we don't
        // let it affect the propagated type when it would result in a loss
        // of precision.
        overrideExpression(is2.expression, is2.type.type, false, false);
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition;
      if (prefix.operator.type == sc.TokenType.BANG) {
        _propagateFalseState(prefix.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      _propagateTrueState(condition.expression);
    }
  }
}

/**
 * The abstract class `Scope` defines the behavior common to name scopes used by the resolver
 * to determine which names are visible at any given point in the code.
 */
abstract class Scope {
  /**
   * The prefix used to mark an identifier as being private to its library.
   */
  static int PRIVATE_NAME_PREFIX = 0x5F;

  /**
   * The suffix added to the declared name of a setter when looking up the setter. Used to
   * disambiguate between a getter and a setter that have the same name.
   */
  static String SETTER_SUFFIX = "=";

  /**
   * The name used to look up the method used to implement the unary minus operator. Used to
   * disambiguate between the unary and binary operators.
   */
  static String UNARY_MINUS = "unary-";

  /**
   * A table mapping names that are defined in this scope to the element representing the thing
   * declared with that name.
   */
  HashMap<String, Element> _definedNames = new HashMap<String, Element>();

  /**
   * A flag indicating whether there are any names defined in this scope.
   */
  bool _hasName = false;

  /**
   * Return the scope in which this scope is lexically enclosed.
   *
   * @return the scope in which this scope is lexically enclosed
   */
  Scope get enclosingScope => null;

  /**
   * Return the listener that is to be informed when an error is encountered.
   *
   * @return the listener that is to be informed when an error is encountered
   */
  AnalysisErrorListener get errorListener;

  /**
   * Add the given element to this scope. If there is already an element with the given name defined
   * in this scope, then an error will be generated and the original element will continue to be
   * mapped to the name. If there is an element with the given name in an enclosing scope, then a
   * warning will be generated but the given element will hide the inherited element.
   *
   * @param element the element to be added to this scope
   */
  void define(Element element) {
    String name = _getName(element);
    if (name != null && !name.isEmpty) {
      if (_definedNames.containsKey(name)) {
        errorListener
            .onError(getErrorForDuplicate(_definedNames[name], element));
      } else {
        _definedNames[name] = element;
        _hasName = true;
      }
    }
  }

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   *
   * @param name the name of the element to be added
   * @param element the element to be added to this scope
   */
  void defineNameWithoutChecking(String name, Element element) {
    _definedNames[name] = element;
    _hasName = true;
  }

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   *
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking(Element element) {
    _definedNames[_getName(element)] = element;
    _hasName = true;
  }

  /**
   * Return the error code to be used when reporting that a name being defined locally conflicts
   * with another element of the same name in the local scope.
   *
   * @param existing the first element to be declared with the conflicting name
   * @param duplicate another element declared with the conflicting name
   * @return the error code used to report duplicate names within a scope
   */
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    // TODO(brianwilkerson) Customize the error message based on the types of
    // elements that share the same name.
    // TODO(jwren) There are 4 error codes for duplicate, but only 1 is being
    // generated.
    Source source = duplicate.source;
    return new AnalysisError(
        source,
        duplicate.nameOffset,
        duplicate.displayName.length,
        CompileTimeErrorCode.DUPLICATE_DEFINITION,
        [existing.displayName]);
  }

  /**
   * Return the source that contains the given identifier, or the source associated with this scope
   * if the source containing the identifier could not be determined.
   *
   * @param identifier the identifier whose source is to be returned
   * @return the source that contains the given identifier
   */
  Source getSource(AstNode node) {
    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
    if (unit != null) {
      CompilationUnitElement unitElement = unit.element;
      if (unitElement != null) {
        return unitElement.source;
      }
    }
    return null;
  }

  /**
   * Return the element with which the given name is associated, or `null` if the name is not
   * defined within this scope.
   *
   * @param identifier the identifier node to lookup element for, used to report correct kind of a
   *          problem and associate problem with
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary);

  /**
   * Return the element with which the given name is associated, or `null` if the name is not
   * defined within this scope. This method only returns elements that are directly defined within
   * this scope, not elements that are defined in an enclosing scope.
   *
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element localLookup(String name, LibraryElement referencingLibrary) {
    if (_hasName) {
      return _definedNames[name];
    }
    return null;
  }

  /**
   * Return the element with which the given identifier is associated, or `null` if the name
   * is not defined within this scope.
   *
   * @param identifier the identifier associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given identifier is associated
   */
  Element lookup(Identifier identifier, LibraryElement referencingLibrary) =>
      internalLookup(identifier, identifier.name, referencingLibrary);

  /**
   * Return the name that will be used to look up the given element.
   *
   * @param element the element whose look-up name is to be returned
   * @return the name that will be used to look up the given element
   */
  String _getName(Element element) {
    if (element is MethodElement) {
      MethodElement method = element;
      if (method.name == "-" && method.parameters.length == 0) {
        return UNARY_MINUS;
      }
    }
    return element.name;
  }

  /**
   * Return `true` if the given name is a library-private name.
   *
   * @param name the name being tested
   * @return `true` if the given name is a library-private name
   */
  static bool isPrivateName(String name) =>
      name != null && StringUtilities.startsWithChar(name, PRIVATE_NAME_PREFIX);
}

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
   * The error listener that will be informed of any errors that are found during resolution.
   */
  final AnalysisErrorListener errorListener;

  /**
   * The scope used to resolve identifiers.
   */
  Scope nameScope;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider typeProvider;

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
  ScopedVisitor(
      this.definingLibrary, this.source, this.typeProvider, this.errorListener,
      {Scope nameScope}) {
    if (nameScope == null) {
      this.nameScope = new LibraryScope(definingLibrary, errorListener);
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
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object> arguments]) {
    errorListener.onError(
        new AnalysisError(source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForToken(ErrorCode errorCode, sc.Token token,
      [List<Object> arguments]) {
    errorListener.onError(new AnalysisError(
        source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Visit the given AST node if it is not null.
   *
   * @param node the node to be visited
   */
  void safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  @override
  Object visitBlock(Block node) {
    Scope outerScope = nameScope;
    try {
      EnclosedScope enclosedScope = new EnclosedScope(nameScope);
      _hideNamesDefinedInBlock(enclosedScope, node);
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
            "Missing element for class declaration ${node.name.name} in ${definingLibrary.source.fullName}",
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
    safelyVisit(node.name);
    safelyVisit(node.typeParameters);
    safelyVisit(node.extendsClause);
    safelyVisit(node.withClause);
    safelyVisit(node.implementsClause);
    safelyVisit(node.nativeClause);
  }

  void visitClassMembersInScope(ClassDeclaration node) {
    safelyVisit(node.documentationComment);
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
    Scope outerScope = nameScope;
    try {
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
      } else {
        nameScope = new FunctionScope(nameScope, constructorElement);
      }
      super.visitConstructorDeclaration(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
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
      safelyVisit(node.condition);
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
            "Missing element for enum declaration ${node.name.name} in ${definingLibrary.source.fullName}",
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
    safelyVisit(node.documentationComment);
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
    safelyVisit(node.identifier);
    safelyVisit(node.iterable);
    safelyVisit(node.loopVariable);
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
    safelyVisit(node.variables);
    safelyVisit(node.initialization);
    safelyVisit(node.condition);
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
            "Missing element for top-level function ${node.name.name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new FunctionScope(nameScope, functionElement);
      }
      super.visitFunctionDeclaration(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
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
      super.visitFunctionTypeAlias(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    Scope outerScope = nameScope;
    try {
      ParameterElement parameterElement = node.element;
      if (parameterElement == null) {
        AnalysisEngine.instance.logger.logInformation(
            "Missing element for function typed formal parameter ${node.identifier.name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new EnclosedScope(nameScope);
        for (TypeParameterElement typeParameter
            in parameterElement.typeParameters) {
          nameScope.define(typeParameter);
        }
      }
      super.visitFunctionTypedFormalParameter(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    safelyVisit(node.condition);
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
            "Missing element for method ${node.name.name} in ${definingLibrary.source.fullName}",
            new CaughtException(new AnalysisException(), null));
      } else {
        nameScope = new FunctionScope(nameScope, methodElement);
      }
      super.visitMethodDeclaration(node);
    } finally {
      nameScope = outerScope;
    }
    return null;
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
    safelyVisit(node.condition);
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

  /**
   * Marks the local declarations of the given [Block] hidden in the enclosing scope.
   * According to the scoping rules name is hidden if block defines it, but name is defined after
   * its declaration statement.
   */
  void _hideNamesDefinedInBlock(EnclosedScope scope, Block block) {
    NodeList<Statement> statements = block.statements;
    int statementCount = statements.length;
    for (int i = 0; i < statementCount; i++) {
      Statement statement = statements[i];
      if (statement is VariableDeclarationStatement) {
        VariableDeclarationStatement vds = statement;
        NodeList<VariableDeclaration> variables = vds.variables.variables;
        int variableCount = variables.length;
        for (int j = 0; j < variableCount; j++) {
          scope.hide(variables[j].element);
        }
      } else if (statement is FunctionDeclarationStatement) {
        FunctionDeclarationStatement fds = statement;
        scope.hide(fds.functionDeclaration.element);
      }
    }
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
    for (InterfaceType interfaceType in interfaceTypes) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        _putInSubtypeMap(interfaceElement, classElement);
      }
    }
    List<InterfaceType> mixinTypes = classElement.mixins;
    for (InterfaceType mixinType in mixinTypes) {
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
    for (ClassElement classElement in classElements) {
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
    for (CompilationUnitElement part in parts) {
      _computeSubtypesInCompilationUnit(part);
    }
    List<LibraryElement> imports = libraryElement.importedLibraries;
    for (LibraryElement importElt in imports) {
      _computeSubtypesInLibrary(importElt.library);
    }
    List<LibraryElement> exports = libraryElement.exportedLibraries;
    for (LibraryElement exportElt in exports) {
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
  void _gatherTodoComments(sc.Token token) {
    while (token != null && token.type != sc.TokenType.EOF) {
      sc.Token commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.type == sc.TokenType.SINGLE_LINE_COMMENT ||
            commentToken.type == sc.TokenType.MULTI_LINE_COMMENT) {
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
  void _scrapeTodoComment(sc.Token commentToken) {
    JavaPatternMatcher matcher =
        new JavaPatternMatcher(TodoCode.TODO_REGEX, commentToken.lexeme);
    if (matcher.find()) {
      int offset =
          commentToken.offset + matcher.start() + matcher.group(1).length;
      int length = matcher.group(2).length;
      _errorReporter.reportErrorForOffset(
          TodoCode.TODO, offset, length, [matcher.group(2)]);
    }
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
      throw new IllegalStateException("Cannot apply overrides without a scope");
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
      throw new IllegalStateException(
          "Cannot capture local overrides without a scope");
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
      throw new IllegalStateException(
          "Cannot capture overrides without a scope");
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
      throw new IllegalStateException("No scope to exit");
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
    return bestType == null ? element.type : bestType;
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
    for (Map<VariableElement, DartType> branch in perBranchOverrides) {
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
      throw new IllegalStateException("Cannot override without a scope");
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
  Map<VariableElement, DartType> _overridenTypes =
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
    _overridenTypes.addAll(overrides);
  }

  /**
   * Return a table mapping the elements whose type is overridden in the current scope to the
   * overriding type.
   *
   * @return the overrides in the current scope
   */
  Map<VariableElement, DartType> captureLocalOverrides() => _overridenTypes;

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
          DartType type = _overridenTypes[element];
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
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    DartType type = _overridenTypes[element];
    if (_overridenTypes.containsKey(element)) {
      return type;
    }
    if (type != null) {
      return type;
    } else if (_outerScope != null) {
      return _outerScope.getType(element);
    }
    return null;
  }

  /**
   * Clears the overridden type of the given [element].
   */
  void resetType(VariableElement element) {
    _overridenTypes[element] = null;
  }

  /**
   * Set the overridden type of the given element to the given type
   *
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(VariableElement element, DartType type) {
    _overridenTypes[element] = type;
  }
}

/**
 * Instances of the class `TypeParameterScope` implement the scope defined by the type
 * parameters in a class.
 */
class TypeParameterScope extends EnclosedScope {
  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param typeElement the element representing the type represented by this scope
   */
  TypeParameterScope(Scope enclosingScope, ClassElement typeElement)
      : super(enclosingScope) {
    if (typeElement == null) {
      throw new IllegalArgumentException("class element cannot be null");
    }
    _defineTypeParameters(typeElement);
  }

  /**
   * Define the type parameters for the class.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void _defineTypeParameters(ClassElement typeElement) {
    for (TypeParameterElement typeParameter in typeElement.typeParameters) {
      define(typeParameter);
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
      throw new IllegalStateException("No scope to exit");
    }
    currentScope = currentScope._outerScope;
  }

  /**
   * Returns static type of the given variable - declared or promoted.
   *
   * @return the static type of the given variable - declared or promoted
   */
  DartType getStaticType(VariableElement variable) {
    DartType staticType = getType(variable);
    if (staticType == null) {
      staticType = variable.type;
    }
    return staticType;
  }

  /**
   * Return the promoted type of the given element, or `null` if the type of the element has
   * not been promoted.
   *
   * @param element the element whose type might have been promoted
   * @return the promoted type of the given element
   */
  DartType getType(Element element) {
    if (currentScope == null) {
      return null;
    }
    return currentScope.getType(element);
  }

  /**
   * Set the promoted type of the given element to the given type.
   *
   * @param element the element whose type might have been promoted
   * @param type the promoted type of the given element
   */
  void setType(Element element, DartType type) {
    if (currentScope == null) {
      throw new IllegalStateException("Cannot promote without a scope");
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
}

/**
 * Instances of the class `TypeProviderImpl` provide access to types defined by the language
 * by looking for those types in the element model for the core library.
 */
class TypeProviderImpl implements TypeProvider {
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
  List<InterfaceType> get nonSubtypableTypes => <InterfaceType>[
        nullType,
        numType,
        intType,
        doubleType,
        boolType,
        stringType
      ];

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
    _futureDynamicType = _futureType.substitute4(<DartType>[_dynamicType]);
    _futureNullType = _futureType.substitute4(<DartType>[_nullType]);
    _iterableDynamicType = _iterableType.substitute4(<DartType>[_dynamicType]);
    _streamDynamicType = _streamType.substitute4(<DartType>[_dynamicType]);
  }
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
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    _dynamicType = typeProvider.dynamicType;
    _undefinedType = typeProvider.undefinedType;
  }

  @override
  Object visitAnnotation(Annotation node) {
    //
    // Visit annotations, if the annotation is @proxy, on a class, and "proxy"
    // resolves to the proxy annotation in dart.core, then create create the
    // ElementAnnotationImpl and set it as the metadata on the enclosing class.
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
        ClassDeclaration classDeclaration = node.parent as ClassDeclaration;
        ElementAnnotationImpl elementAnnotation =
            new ElementAnnotationImpl(element);
        node.elementAnnotation = elementAnnotation;
        (classDeclaration.element as ClassElementImpl).metadata =
            <ElementAnnotationImpl>[elementAnnotation];
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
      TypeName exceptionTypeName = node.exceptionType;
      DartType exceptionType;
      if (exceptionTypeName == null) {
        exceptionType = typeProvider.dynamicType;
      } else {
        exceptionType = _getType(exceptionTypeName);
      }
      _recordType(exception, exceptionType);
      Element element = exception.staticElement;
      if (element is VariableElementImpl) {
        element.type = exceptionType;
      } else {
        // TODO(brianwilkerson) Report the internal error
      }
    }
    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      _recordType(stackTrace, typeProvider.stackTraceType);
      Element element = stackTrace.staticElement;
      if (element is VariableElementImpl) {
        element.type = typeProvider.stackTraceType;
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
      if (!identical(superclassType, typeProvider.objectType)) {
        classElement.validMixin = false;
      }
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
    //
    // Process field declarations before constructors and methods so that the
    // types of field formal parameters can be correctly resolved.
    //
    List<ClassMember> nonFields = new List<ClassMember>();
    node.visitChildren(
        new _TypeResolverVisitor_visitClassMembersInScope(this, nonFields));
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
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    if (element == null) {
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
    } else {
      ClassElement definingClass = element.enclosingElement as ClassElement;
      element.returnType = definingClass.type;
      FunctionTypeImpl type = new FunctionTypeImpl(element);
      type.typeArguments = definingClass.type.typeArguments;
      element.type = type;
    }
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    DartType declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _getType(typeName);
    }
    LocalVariableElementImpl element = node.element as LocalVariableElementImpl;
    element.type = declaredType;
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element = node.identifier.staticElement;
    if (element is ParameterElementImpl) {
      ParameterElementImpl parameter = element;
      FormalParameterList parameterList = node.parameters;
      if (parameterList == null) {
        DartType type;
        TypeName typeName = node.type;
        if (typeName == null) {
          type = _dynamicType;
          if (parameter is FieldFormalParameterElement) {
            FieldElement fieldElement =
                (parameter as FieldFormalParameterElement).field;
            if (fieldElement != null) {
              type = fieldElement.type;
            }
          }
        } else {
          type = _getType(typeName);
        }
        parameter.type = type;
      } else {
        _setFunctionTypedParameterType(parameter, node.type, node.parameters);
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
    element.returnType = _computeReturnType(node.returnType);
    FunctionTypeImpl type = new FunctionTypeImpl(element);
    ClassElement definingClass =
        element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      type.typeArguments = definingClass.type.typeArguments;
    }
    element.type = type;
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
    element.returnType = _computeReturnType(node.returnType);
    FunctionTypeImpl type = new FunctionTypeImpl(element);
    ClassElement definingClass =
        element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      type.typeArguments = definingClass.type.typeArguments;
    }
    element.type = type;
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      PropertyInducingElementImpl variable =
          accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter) {
        variable.type = type.returnType;
      } else if (variable.type == null) {
        List<DartType> parameterTypes = type.normalParameterTypes;
        if (parameterTypes != null && parameterTypes.length > 0) {
          variable.type = parameterTypes[0];
        }
      }
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);
    DartType declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _getType(typeName);
    }
    Element element = node.identifier.staticElement;
    if (element is ParameterElement) {
      (element as ParameterElementImpl).type = declaredType;
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
    Identifier typeName = node.name;
    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      //
      // Check to see whether the type name is either 'dynamic' or 'void',
      // neither of which are in the name scope and hence will not be found by
      // normal means.
      //
      if (typeName.name == _dynamicType.name) {
        _setElement(typeName, _dynamicType.element);
        if (argumentList != null) {
          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, dynamicType.getName(), 0, argumentList.getArguments().size());
        }
        typeName.staticType = _dynamicType;
        node.type = _dynamicType;
        return null;
      }
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
        if (argumentList != null) {
          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, voidType.getName(), 0, argumentList.getArguments().size());
        }
        typeName.staticType = voidType;
        node.type = voidType;
        return null;
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
            if (parent.parent is InstanceCreationExpression &&
                (parent.parent as InstanceCreationExpression).isConst) {
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
            return null;
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
        ErrorCode errorCode = (redirectingConstructorKind ==
                RedirectingConstructorKind.CONST
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
      } else {
        _setElement(typeName, _dynamicType.element);
      }
      typeName.staticType = _undefinedType;
      node.type = _undefinedType;
      return null;
    }
    DartType type = null;
    if (element is ClassElement) {
      _setElement(typeName, element);
      type = element.type;
    } else if (element is FunctionTypeAliasElement) {
      _setElement(typeName, element);
      type = element.type;
    } else if (element is TypeParameterElement) {
      _setElement(typeName, element);
      type = element.type;
      if (argumentList != null) {
        // Type parameters cannot have type arguments.
        // TODO(brianwilkerson) Report this error.
        //      resolver.reportError(ResolverErrorCode.?, keyType);
      }
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
        ErrorCode errorCode = (redirectingConstructorKind ==
                RedirectingConstructorKind.CONST
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
        } else {
          reportErrorForNode(
              StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      _setElement(typeName, _dynamicType.element);
      typeName.staticType = _dynamicType;
      node.type = _dynamicType;
      return null;
    }
    if (argumentList != null) {
      NodeList<TypeName> arguments = argumentList.arguments;
      int argumentCount = arguments.length;
      List<DartType> parameters = _getTypeArguments(type);
      int parameterCount = parameters.length;
      List<DartType> typeArguments = new List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          TypeName argumentTypeName = arguments[i];
          DartType argumentType = _getType(argumentTypeName);
          if (argumentType == null) {
            argumentType = _dynamicType;
          }
          typeArguments[i] = argumentType;
        }
      } else {
        reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
            [typeName.name, parameterCount, argumentCount]);
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _dynamicType;
        }
      }
      if (type is InterfaceTypeImpl) {
        InterfaceTypeImpl interfaceType = type as InterfaceTypeImpl;
        type = interfaceType.substitute4(typeArguments);
      } else if (type is FunctionTypeImpl) {
        FunctionTypeImpl functionType = type as FunctionTypeImpl;
        type = functionType.substitute3(typeArguments);
      } else {
        // TODO(brianwilkerson) Report this internal error.
      }
    } else {
      //
      // Check for the case where there are no type arguments given for a
      // parameterized type.
      //
      List<DartType> parameters = _getTypeArguments(type);
      int parameterCount = parameters.length;
      if (parameterCount > 0) {
        DynamicTypeImpl dynamicType = DynamicTypeImpl.instance;
        List<DartType> arguments = new List<DartType>(parameterCount);
        for (int i = 0; i < parameterCount; i++) {
          arguments[i] = dynamicType;
        }
        type = type.substitute2(arguments, parameters);
      }
    }
    typeName.staticType = type;
    node.type = type;
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    super.visitTypeParameter(node);
    TypeName bound = node.bound;
    if (bound != null) {
      TypeParameterElementImpl typeParameter =
          node.name.staticElement as TypeParameterElementImpl;
      if (typeParameter != null) {
        typeParameter.bound = bound.type;
      }
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    DartType declaredType;
    TypeName typeName = (node.parent as VariableDeclarationList).type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = _getType(typeName);
    }
    Element element = node.name.staticElement;
    if (element is VariableElement) {
      (element as VariableElementImpl).type = declaredType;
      if (element is PropertyInducingElement) {
        PropertyInducingElement variableElement = element;
        PropertyAccessorElementImpl getter =
            variableElement.getter as PropertyAccessorElementImpl;
        getter.returnType = declaredType;
        FunctionTypeImpl getterType = new FunctionTypeImpl(getter);
        ClassElement definingClass =
            element.getAncestor((element) => element is ClassElement);
        if (definingClass != null) {
          getterType.typeArguments = definingClass.type.typeArguments;
        }
        getter.type = getterType;
        PropertyAccessorElementImpl setter =
            variableElement.setter as PropertyAccessorElementImpl;
        if (setter != null) {
          List<ParameterElement> parameters = setter.parameters;
          if (parameters.length > 0) {
            (parameters[0] as ParameterElementImpl).type = declaredType;
          }
          setter.returnType = VoidTypeImpl.instance;
          FunctionTypeImpl setterType = new FunctionTypeImpl(setter);
          if (definingClass != null) {
            setterType.typeArguments = definingClass.type.typeArguments;
          }
          setter.type = setterType;
        }
      }
    } else {
      // TODO(brianwilkerson) Report the internal error.
    }
    return null;
  }

  /**
   * Given a type name representing the return type of a function, compute the return type of the
   * function.
   *
   * @param returnType the type name representing the return type of the function
   * @return the return type that was computed
   */
  DartType _computeReturnType(TypeName returnType) {
    if (returnType == null) {
      return _dynamicType;
    } else {
      return returnType.type;
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
    if (element is! ClassElementImpl) {
      // TODO(brianwilkerson) Report this
      // Internal error: Failed to create an element for a class declaration.
      return null;
    }
    return element as ClassElementImpl;
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
   * The number of type arguments in the given type name does not match the number of parameters in
   * the corresponding class element. Return the error code that should be used to report this
   * error.
   *
   * @param node the type name with the wrong number of type arguments
   * @return the error code that should be used to report that the wrong number of type arguments
   *         were provided
   */
  ErrorCode _getInvalidTypeParametersErrorCode(TypeName node) {
    AstNode parent = node.parent;
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
   * Checks if the given type name is the target in a redirected constructor.
   *
   * @param typeName the type name to analyze
   * @return some [RedirectingConstructorKind] if the given type name is used as the type in a
   *         redirected constructor, or `null` otherwise
   */
  RedirectingConstructorKind _getRedirectingConstructorKind(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      ConstructorName constructorName = parent as ConstructorName;
      parent = constructorName.parent;
      if (parent is ConstructorDeclaration) {
        if (identical(parent.redirectedConstructor, constructorName)) {
          if (parent.constKeyword != null) {
            return RedirectingConstructorKind.CONST;
          }
          return RedirectingConstructorKind.NORMAL;
        }
      }
    }
    return null;
  }

  /**
   * Return the type represented by the given type name.
   *
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  DartType _getType(TypeName typeName) {
    DartType type = typeName.type;
    if (type == null) {
      return _undefinedType;
    }
    return type;
  }

  /**
   * Return the type arguments associated with the given type.
   *
   * @param type the type whole type arguments are to be returned
   * @return the type arguments associated with the given type
   */
  List<DartType> _getTypeArguments(DartType type) {
    if (type is InterfaceType) {
      return type.typeArguments;
    } else if (type is FunctionType) {
      return type.typeArguments;
    }
    return DartType.EMPTY_LIST;
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
    for (Element element in elements) {
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
   * Checks if the given type name is used as the type in an as expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an as expression
   */
  bool _isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      AsExpression asExpression = parent;
      return identical(asExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the exception type in a catch clause.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the exception type in a catch clause
   */
  bool _isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      CatchClause catchClause = parent;
      return identical(catchClause.exceptionType, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an instance creation expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an instance creation
   *         expression
   */
  bool _isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      ConstructorName constructorName = parent;
      return constructorName != null &&
          identical(constructorName.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an is expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an is expression
   */
  bool _isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      IsExpression isExpression = parent;
      return identical(isExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name used in a type argument list.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is in a type argument list
   */
  bool _isTypeNameInTypeArgumentList(TypeName typeName) =>
      typeName.parent is TypeArgumentList;

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
   * Resolve the types in the given with and implements clauses and associate those types with the
   * given class element.
   *
   * @param classElement the class element with which the mixin and interface types are to be
   *          associated
   * @param withClause the with clause to be resolved
   * @param implementsClause the implements clause to be resolved
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
        classElement.withClauseRange =
            new SourceRange(withClause.offset, withClause.length);
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
              reportErrorForNode(
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
        reportErrorForNode(enumTypeError, typeName);
        return null;
      }
      return type;
    }
    // If the type is not an InterfaceType, then visitTypeName() sets the type
    // to be a DynamicTypeImpl
    Identifier name = typeName.name;
    if (name.name == sc.Keyword.DYNAMIC.syntax) {
      reportErrorForNode(dynamicTypeError, name, [name.name]);
    } else {
      reportErrorForNode(nonTypeError, name, [name.name]);
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

  void _setElement(Identifier typeName, Element element) {
    if (element != null) {
      if (typeName is SimpleIdentifier) {
        typeName.staticElement = element;
      } else if (typeName is PrefixedIdentifier) {
        PrefixedIdentifier identifier = typeName;
        identifier.identifier.staticElement = element;
        SimpleIdentifier prefix = identifier.prefix;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        if (prefixElement != null) {
          prefix.staticElement = prefixElement;
        }
      }
    }
  }

  /**
   * Given a parameter element, create a function type based on the given return type and parameter
   * list and associate the created type with the element.
   *
   * @param element the parameter element whose type is to be set
   * @param returnType the (possibly `null`) return type of the function
   * @param parameterList the list of parameters to the function
   */
  void _setFunctionTypedParameterType(ParameterElementImpl element,
      TypeName returnType, FormalParameterList parameterList) {
    List<ParameterElement> parameters = _getElements(parameterList);
    FunctionTypeAliasElementImpl aliasElement =
        new FunctionTypeAliasElementImpl.forNode(null);
    aliasElement.synthetic = true;
    aliasElement.shareParameters(parameters);
    aliasElement.returnType = _computeReturnType(returnType);
    // FunctionTypeAliasElementImpl assumes the enclosing element is a
    // CompilationUnitElement (because non-synthetic function types can only be
    // declared at top level), so to avoid breaking things, go find the
    // compilation unit element.
    aliasElement.enclosingElement =
        element.getAncestor((element) => element is CompilationUnitElement);
    FunctionTypeImpl type = new FunctionTypeImpl.forTypedef(aliasElement);
    ClassElement definingClass =
        element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      aliasElement.shareTypeParameters(definingClass.typeParameters);
      type.typeArguments = definingClass.type.typeArguments;
    } else {
      FunctionTypeAliasElement alias =
          element.getAncestor((element) => element is FunctionTypeAliasElement);
      while (alias != null && alias.isSynthetic) {
        alias =
            alias.getAncestor((element) => element is FunctionTypeAliasElement);
      }
      if (alias != null) {
        aliasElement.typeParameters = alias.typeParameters;
        type.typeArguments = alias.type.typeArguments;
      } else {
        type.typeArguments = DartType.EMPTY_LIST;
      }
    }
    element.type = type;
  }

  /**
   * @return `true` if the name of the given [TypeName] is an built-in identifier.
   */
  static bool _isBuiltInIdentifier(TypeName node) {
    sc.Token token = node.name.beginToken;
    return token.type == sc.TokenType.KEYWORD;
  }

  /**
   * @return `true` if given [TypeName] is used as a type annotation.
   */
  static bool _isTypeAnnotation(TypeName node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList) {
      return identical(parent.type, node);
    }
    if (parent is FieldFormalParameter) {
      return identical(parent.type, node);
    }
    if (parent is SimpleFormalParameter) {
      return identical(parent.type, node);
    }
    return false;
  }
}

/**
 * The interface `TypeSystem` defines the behavior of an object representing
 * the type system.  This provides a common location to put methods that act on
 * types but may need access to more global data structures, and it paves the
 * way for a possible future where we may wish to make the type system
 * pluggable.
 */
abstract class TypeSystem {
  /**
   * Return the [TypeProvider] associated with this [TypeSystem].
   */
  TypeProvider get typeProvider;

  /**
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(DartType type1, DartType type2);

  /**
   * Return `true` if the [leftType] is a subtype of the [rightType] (that is,
   * if leftType <: rightType).
   */
  bool isSubtypeOf(DartType leftType, DartType rightType);
}

/**
 * Implementation of [TypeSystem] using the rules in the Dart specification.
 */
class TypeSystemImpl implements TypeSystem {
  @override
  final TypeProvider typeProvider;

  TypeSystemImpl(this.typeProvider);

  @override
  DartType getLeastUpperBound(DartType type1, DartType type2) {
    // The least upper bound relation is reflexive.
    if (identical(type1, type2)) {
      return type1;
    }
    // The least upper bound of dynamic and any type T is dynamic.
    if (type1.isDynamic) {
      return type1;
    }
    if (type2.isDynamic) {
      return type2;
    }
    // The least upper bound of void and any type T != dynamic is void.
    if (type1.isVoid) {
      return type1;
    }
    if (type2.isVoid) {
      return type2;
    }
    // The least upper bound of bottom and any type T is T.
    if (type1.isBottom) {
      return type2;
    }
    if (type2.isBottom) {
      return type1;
    }
    // Let U be a type variable with upper bound B.  The least upper bound of U
    // and a type T is the least upper bound of B and T.
    while (type1 is TypeParameterType) {
      // TODO(paulberry): is this correct in the complex of F-bounded
      // polymorphism?
      DartType bound = (type1 as TypeParameterType).element.bound;
      if (bound == null) {
        bound = typeProvider.objectType;
      }
      type1 = bound;
    }
    while (type2 is TypeParameterType) {
      // TODO(paulberry): is this correct in the context of F-bounded
      // polymorphism?
      DartType bound = (type2 as TypeParameterType).element.bound;
      if (bound == null) {
        bound = typeProvider.objectType;
      }
      type2 = bound;
    }
    // The least upper bound of a function type and an interface type T is the
    // least upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = typeProvider.functionType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = typeProvider.functionType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      InterfaceType result =
          InterfaceTypeImpl.computeLeastUpperBound(type1, type2);
      if (result == null) {
        return typeProvider.dynamicType;
      }
      return result;
    } else if (type1 is FunctionType && type2 is FunctionType) {
      FunctionType result =
          FunctionTypeImpl.computeLeastUpperBound(type1, type2);
      if (result == null) {
        return typeProvider.functionType;
      }
      return result;
    } else {
      // Should never happen.  As a defensive measure, return the dynamic type.
      assert(false);
      return typeProvider.dynamicType;
    }
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return leftType.isSubtypeOf(rightType);
  }
}

/**
 * Instances of the class [UnusedLocalElementsVerifier] traverse an element
 * structure looking for cases of [HintCode.UNUSED_ELEMENT],
 * [HintCode.UNUSED_FIELD], [HintCode.UNUSED_LOCAL_VARIABLE], etc.
 */
class UnusedLocalElementsVerifier extends RecursiveElementVisitor {
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

  @override
  visitClassElement(ClassElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
    super.visitClassElement(element);
  }

  @override
  visitFieldElement(FieldElement element) {
    if (!_isReadMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_FIELD, element, [element.displayName]);
    }
    super.visitFieldElement(element);
  }

  @override
  visitFunctionElement(FunctionElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
    super.visitFunctionElement(element);
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
    super.visitFunctionTypeAliasElement(element);
  }

  @override
  visitLocalVariableElement(LocalVariableElement element) {
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

  @override
  visitMethodElement(MethodElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
    super.visitMethodElement(element);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(HintCode.UNUSED_ELEMENT, element,
          [element.kind.displayName, element.displayName]);
    }
    super.visitPropertyAccessorElement(element);
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
      _errorListener.onError(new AnalysisError(
          element.source,
          element.nameOffset,
          element.displayName.length,
          errorCode,
          arguments));
    }
  }
}

/**
 * A container with information about used imports prefixes and used imported
 * elements.
 */
class UsedImportedElements {
  /**
   * The set of referenced [PrefixElement]s.
   */
  final Set<PrefixElement> prefixes = new HashSet<PrefixElement>();

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
    for (UsedLocalElements part in parts) {
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

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   *
   * Deprecated.  Please use unnamed constructor instead.
   */
  @deprecated
  VariableResolverVisitor.con1(
      Library library, Source source, TypeProvider typeProvider)
      : this(
            library.libraryElement, source, typeProvider, library.errorListener,
            nameScope: library.libraryScope);

  @override
  Object visitExportDirective(ExportDirective node) => null;

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
        _enclosingFunction = node.element;
        return super.visitFunctionExpression(node);
      } finally {
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
    try {
      _enclosingFunction = node.element;
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if already resolved - declaration or type.
    if (node.staticElement != null) {
      return null;
    }
    // Ignore if qualified.
    AstNode parent = node.parent;
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
    if (kind == ElementKind.LOCAL_VARIABLE) {
      node.staticElement = element;
      LocalVariableElementImpl variableImpl =
          element as LocalVariableElementImpl;
      if (node.inSetterContext()) {
        variableImpl.markPotentiallyMutatedInScope();
        if (element.enclosingElement != _enclosingFunction) {
          variableImpl.markPotentiallyMutatedInClosure();
        }
      }
    } else if (kind == ElementKind.PARAMETER) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        ParameterElementImpl parameterImpl = element as ParameterElementImpl;
        parameterImpl.markPotentiallyMutatedInScope();
        // If we are in some closure, check if it is not the same as where
        // variable is declared.
        if (_enclosingFunction != null &&
            (element.enclosingElement != _enclosingFunction)) {
          parameterImpl.markPotentiallyMutatedInClosure();
        }
      }
    }
    return null;
  }
}

class _ConstantVerifier_validateInitializerExpression extends ConstantVisitor {
  final ConstantVerifier verifier;

  List<ParameterElement> parameterElements;

  _ConstantVerifier_validateInitializerExpression(
      TypeProvider typeProvider,
      ErrorReporter errorReporter,
      this.verifier,
      this.parameterElements,
      DeclaredVariables declaredVariables)
      : super(new ConstantEvaluationEngine(typeProvider, declaredVariables),
            errorReporter);

  @override
  DartObjectImpl visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    for (ParameterElement parameterElement in parameterElements) {
      if (identical(parameterElement, element) && parameterElement != null) {
        DartType type = parameterElement.type;
        if (type != null) {
          if (type.isDynamic) {
            return new DartObjectImpl(
                verifier._typeProvider.objectType, DynamicState.DYNAMIC_STATE);
          } else if (type.isSubtypeOf(verifier._boolType)) {
            return new DartObjectImpl(
                verifier._typeProvider.boolType, BoolState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(verifier._typeProvider.doubleType)) {
            return new DartObjectImpl(
                verifier._typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(verifier._intType)) {
            return new DartObjectImpl(
                verifier._typeProvider.intType, IntState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(verifier._numType)) {
            return new DartObjectImpl(
                verifier._typeProvider.numType, NumState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(verifier._stringType)) {
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

class _ElementBuilder_visitClassDeclaration extends UnifyingAstVisitor<Object> {
  final ElementBuilder builder;

  List<ClassMember> nonFields;

  _ElementBuilder_visitClassDeclaration(this.builder, this.nonFields) : super();

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitNode(AstNode node) => node.accept(builder);
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

class _TypeResolverVisitor_visitClassMembersInScope
    extends UnifyingAstVisitor<Object> {
  final TypeResolverVisitor TypeResolverVisitor_this;

  List<ClassMember> nonFields;

  _TypeResolverVisitor_visitClassMembersInScope(
      this.TypeResolverVisitor_this, this.nonFields)
      : super();

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) => null;

  @override
  Object visitImplementsClause(ImplementsClause node) => null;

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitNode(AstNode node) => node.accept(TypeResolverVisitor_this);

  @override
  Object visitWithClause(WithClause node) => null;
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.error_verifier;

import 'dart:collection';
import "dart:math" as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/pending_error.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk, SdkLibrary;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/strong/checker.dart' as checker
    show hasStrictArrow;

/**
 * A visitor used to traverse an AST structure looking for additional errors and
 * warnings not covered by the parser and resolver.
 */
class ErrorVerifier extends RecursiveAstVisitor<Object> {
  /**
   * Static final string with value `"getter "` used in the construction of the
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE], and
   * similar, error code messages.
   *
   * See [_checkForNonAbstractClassInheritsAbstractMember].
   */
  static String _GETTER_SPACE = "getter ";

  /**
   * Static final string with value `"setter "` used in the construction of the
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE], and
   * similar, error code messages.
   *
   * See [_checkForNonAbstractClassInheritsAbstractMember].
   */
  static String _SETTER_SPACE = "setter ";

  /**
   * The error reporter by which errors will be reported.
   */
  final ErrorReporter _errorReporter;

  /**
   * The current library that is being analyzed.
   */
  final LibraryElement _currentLibrary;

  /**
   * The type representing the type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'int'.
   */
  InterfaceType _intType;

  /**
   * The options for verification.
   */
  AnalysisOptionsImpl _options;

  /**
   * The object providing access to the types defined by the language.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system primitives
   */
  TypeSystem _typeSystem;

  /**
   * The manager for the inheritance mappings.
   */
  final InheritanceManager _inheritanceManager;

  /**
   * A flag indicating whether the visitor is currently within a constructor
   * declaration that is 'const'.
   *
   * See [visitConstructorDeclaration].
   */
  bool _isEnclosingConstructorConst = false;

  /**
   * A flag indicating whether we are currently within a function body marked as
   * being asynchronous.
   */
  bool _inAsync = false;

  /**
   * A flag indicating whether we are currently within a function body marked a
   *  being a generator.
   */
  bool _inGenerator = false;

  /**
   * A flag indicating whether the visitor is currently within a catch clause.
   *
   * See [visitCatchClause].
   */
  bool _isInCatchClause = false;

  /**
   * A flag indicating whether the visitor is currently within a comment.
   */
  bool _isInComment = false;

  /**
   * A flag indicating whether the visitor is currently within an instance
   * creation expression.
   */
  bool _isInConstInstanceCreation = false;

  /**
   * A flag indicating whether the visitor is currently within a native class
   * declaration.
   */
  bool _isInNativeClass = false;

  /**
   * A flag indicating whether the visitor is currently within a static variable
   * declaration.
   */
  bool _isInStaticVariableDeclaration = false;

  /**
   * A flag indicating whether the visitor is currently within an instance
   * variable declaration.
   */
  bool _isInInstanceVariableDeclaration = false;

  /**
   * A flag indicating whether the visitor is currently within an instance
   * variable initializer.
   */
  bool _isInInstanceVariableInitializer = false;

  /**
   * A flag indicating whether the visitor is currently within a constructor
   * initializer.
   */
  bool _isInConstructorInitializer = false;

  /**
   * This is set to `true` iff the visitor is currently within a function typed
   * formal parameter.
   */
  bool _isInFunctionTypedFormalParameter = false;

  /**
   * A flag indicating whether the visitor is currently within a static method.
   * By "method" here getter, setter and operator declarations are also implied
   * since they are all represented with a [MethodDeclaration] in the AST
   * structure.
   */
  bool _isInStaticMethod = false;

  /**
   * A flag indicating whether the visitor is currently within a factory
   * constructor.
   */
  bool _isInFactory = false;

  /**
   * A flag indicating whether the visitor is currently within code in the SDK.
   */
  bool _isInSystemLibrary = false;

  /**
   * A flag indicating whether the current library contains at least one import
   * directive with a URI that uses the "dart-ext" scheme.
   */
  bool _hasExtUri = false;

  /**
   * This is set to `false` on the entry of every [BlockFunctionBody], and is
   * restored to the enclosing value on exit. The value is used in
   * [_checkForMixedReturns] to prevent both
   * [StaticWarningCode.MIXED_RETURN_TYPES] and
   * [StaticWarningCode.RETURN_WITHOUT_VALUE] from being generated in the same
   * function body.
   */
  bool _hasReturnWithoutValue = false;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not
   * in the scope of a class.
   */
  ClassElementImpl _enclosingClass;

  /**
   * The enum containing the AST nodes being visited, or `null` if we are not
   * in the scope of an enum.
   */
  ClassElement _enclosingEnum;

  /**
   * The method or function that we are currently visiting, or `null` if we are
   * not inside a method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * The return statements found in the method or function that we are currently
   * visiting that have a return value.
   */
  List<ReturnStatement> _returnsWith = new List<ReturnStatement>();

  /**
   * The return statements found in the method or function that we are currently
   * visiting that do not have a return value.
   */
  List<ReturnStatement> _returnsWithout = new List<ReturnStatement>();

  /**
   * This map is initialized when visiting the contents of a class declaration.
   * If the visitor is not in an enclosing class declaration, then the map is
   * set to `null`.
   *
   * When set the map maps the set of [FieldElement]s in the class to an
   * [INIT_STATE.NOT_INIT] or [INIT_STATE.INIT_IN_DECLARATION]. The `checkFor*`
   * methods, specifically [_checkForAllFinalInitializedErrorCodes], can make a
   * copy of the map to compute error code states. The `checkFor*` methods
   * should only ever make a copy, or read from this map after it has been set
   * in [visitClassDeclaration].
   *
   * See [visitClassDeclaration], and [_checkForAllFinalInitializedErrorCodes].
   */
  HashMap<FieldElement, INIT_STATE> _initialFieldElementsMap;

  /**
   * A table mapping name of the library to the export directive which export
   * this library.
   */
  HashMap<String, LibraryElement> _nameToExportElement =
      new HashMap<String, LibraryElement>();

  /**
   * A table mapping name of the library to the import directive which import
   * this library.
   */
  HashMap<String, LibraryElement> _nameToImportElement =
      new HashMap<String, LibraryElement>();

  /**
   * A table mapping names to the exported elements.
   */
  HashMap<String, Element> _exportedElements = new HashMap<String, Element>();

  /**
   * A set of the names of the variable initializers we are visiting now.
   */
  HashSet<String> _namesForReferenceToDeclaredVariableInInitializer =
      new HashSet<String>();

  /**
   * The elements that will be defined later in the current scope, but right
   * now are not declared.
   */
  HiddenElements _hiddenElements = null;

  /**
   * A list of types used by the [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]
   * and [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS] error codes.
   */
  List<InterfaceType> _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT;

  /**
   * If `true`, mixins are allowed to inherit from types other than Object, and
   * are allowed to reference `super`.
   */
  final bool enableSuperMixins;

  final _UninstantiatedBoundChecker _uninstantiatedBoundChecker;

  /**
   * Initialize a newly created error verifier.
   */
  ErrorVerifier(ErrorReporter errorReporter, this._currentLibrary,
      this._typeProvider, this._inheritanceManager, this.enableSuperMixins)
      : _errorReporter = errorReporter,
        _uninstantiatedBoundChecker =
            new _UninstantiatedBoundChecker(errorReporter) {
    this._isInSystemLibrary = _currentLibrary.source.isInSystemLibrary;
    this._hasExtUri = _currentLibrary.hasExtUri;
    _isEnclosingConstructorConst = false;
    _isInCatchClause = false;
    _isInStaticVariableDeclaration = false;
    _isInInstanceVariableDeclaration = false;
    _isInInstanceVariableInitializer = false;
    _isInConstructorInitializer = false;
    _isInStaticMethod = false;
    _boolType = _typeProvider.boolType;
    _intType = _typeProvider.intType;
    _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT = _typeProvider.nonSubtypableTypes;
    _typeSystem = _currentLibrary.context.typeSystem;
    _options = _currentLibrary.context.analysisOptions;
  }

  @override
  Object visitAnnotation(Annotation node) {
    _checkForInvalidAnnotationFromDeferredLibrary(node);
    _checkForMissingJSLibAnnotation(node);
    return super.visitAnnotation(node);
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    _checkForArgumentTypesNotAssignableInList(node);
    return super.visitArgumentList(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    return super.visitAsExpression(node);
  }

  @override
  Object visitAssertInitializer(AssertInitializer node) {
    _checkForNonBoolExpression(node);
    return super.visitAssertInitializer(node);
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    _checkForNonBoolExpression(node);
    return super.visitAssertStatement(node);
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    Expression rhs = node.rightHandSide;
    if (operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForInvalidAssignment(lhs, rhs);
    } else {
      _checkForInvalidCompoundAssignment(node, lhs, rhs);
      _checkForArgumentTypeNotAssignableForArgument(rhs);
    }
    _checkForAssignmentToFinal(lhs);
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    if (!_inAsync) {
      _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, node.awaitKeyword);
    }
    return super.visitAwaitExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    TokenType type = operator.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      String lexeme = operator.lexeme;
      _checkForAssignability(node.leftOperand, _boolType,
          StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
      _checkForAssignability(node.rightOperand, _boolType,
          StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
    } else {
      _checkForArgumentTypeNotAssignableForArgument(node.rightOperand);
    }
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitBlock(Block node) {
    _hiddenElements = new HiddenElements(_hiddenElements, node);
    try {
      _checkDuplicateDeclarationInStatements(node.statements);
      return super.visitBlock(node);
    } finally {
      _hiddenElements = _hiddenElements.outerElements;
    }
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    bool wasInAsync = _inAsync;
    bool wasInGenerator = _inGenerator;
    bool previousHasReturnWithoutValue = _hasReturnWithoutValue;
    _hasReturnWithoutValue = false;
    List<ReturnStatement> previousReturnsWith = _returnsWith;
    List<ReturnStatement> previousReturnsWithout = _returnsWithout;
    try {
      _inAsync = node.isAsynchronous;
      _inGenerator = node.isGenerator;
      _returnsWith = new List<ReturnStatement>();
      _returnsWithout = new List<ReturnStatement>();
      super.visitBlockFunctionBody(node);
      _checkForMixedReturns(node);
    } finally {
      _inAsync = wasInAsync;
      _inGenerator = wasInGenerator;
      _returnsWith = previousReturnsWith;
      _returnsWithout = previousReturnsWithout;
      _hasReturnWithoutValue = previousHasReturnWithoutValue;
    }
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        _errorReporter.reportErrorForNode(
            ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode);
      }
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _checkDuplicateDefinitionInCatchClause(node);
    bool previousIsInCatchClause = _isInCatchClause;
    try {
      _isInCatchClause = true;
      _checkForTypeAnnotationDeferredClass(node.exceptionType);
      return super.visitCatchClause(node);
    } finally {
      _isInCatchClause = previousIsInCatchClause;
    }
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElementImpl outerClass = _enclosingClass;
    try {
      _isInNativeClass = node.nativeClause != null;
      _enclosingClass = AbstractClassElementImpl.getImpl(node.element);
      _checkDuplicateClassMembers(node);
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForMemberWithClassName();
      _checkForNoDefaultSuperConstructorImplicit(node);
      _checkForConflictingTypeVariableErrorCodes(node);
      TypeName superclass = node.extendsClause?.superclass;
      ImplementsClause implementsClause = node.implementsClause;
      WithClause withClause = node.withClause;

      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null ||
          superclass != null ||
          withClause != null) {
        _checkClassInheritance(node, superclass, withClause, implementsClause);
      }
      visitClassDeclarationIncrementally(node);
      _checkForFinalNotInitializedInClass(node);
      _checkForDuplicateDefinitionInheritance();
      _checkForConflictingInstanceMethodSetter(node);
      _checkForBadFunctionUse(node);
      return super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _initialFieldElementsMap = null;
      _enclosingClass = outerClass;
    }
  }

  /**
   * Implementation of this method should be synchronized with
   * [visitClassDeclaration].
   */
  void visitClassDeclarationIncrementally(ClassDeclaration node) {
    _isInNativeClass = node.nativeClause != null;
    _enclosingClass = AbstractClassElementImpl.getImpl(node.element);
    // initialize initialFieldElementsMap
    if (_enclosingClass != null) {
      List<FieldElement> fieldElements = _enclosingClass.fields;
      _initialFieldElementsMap = new HashMap<FieldElement, INIT_STATE>();
      for (FieldElement fieldElement in fieldElements) {
        if (!fieldElement.isSynthetic) {
          _initialFieldElementsMap[fieldElement] =
              fieldElement.initializer == null
                  ? INIT_STATE.NOT_INIT
                  : INIT_STATE.INIT_IN_DECLARATION;
        }
      }
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    ClassElementImpl outerClassElement = _enclosingClass;
    try {
      _enclosingClass = AbstractClassElementImpl.getImpl(node.element);
      _checkClassInheritance(
          node, node.superclass, node.withClause, node.implementsClause);
    } finally {
      _enclosingClass = outerClassElement;
    }
    return super.visitClassTypeAlias(node);
  }

  @override
  Object visitComment(Comment node) {
    _isInComment = true;
    try {
      return super.visitComment(node);
    } finally {
      _isInComment = false;
    }
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    _checkDuplicateUnitMembers(node);
    _checkForDeferredPrefixCollisions(node);
    return super.visitCompilationUnit(node);
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    _checkForNonBoolCondition(node.condition);
    return super.visitConditionalExpression(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      ConstructorElement constructorElement = node.element;
      _enclosingFunction = constructorElement;
      _isEnclosingConstructorConst = node.constKeyword != null;
      _isInFactory = node.factoryKeyword != null;
      _checkForInvalidModifierOnBody(
          node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR);
      _checkForConstConstructorWithNonFinalField(node, constructorElement);
      _checkForConstConstructorWithNonConstSuper(node);
      _checkForConflictingConstructorNameAndMember(node, constructorElement);
      _checkForAllFinalInitializedErrorCodes(node);
      _checkForRedirectingConstructorErrorCodes(node);
      _checkForMultipleSuperInitializers(node);
      _checkForRecursiveConstructorRedirect(node, constructorElement);
      if (!_checkForRecursiveFactoryRedirect(node, constructorElement)) {
        _checkForAllRedirectConstructorErrorCodes(node);
      }
      _checkForUndefinedConstructorInInitializerImplicit(node);
      _checkForRedirectToNonConstConstructor(node, constructorElement);
      _checkForReturnInGenerativeConstructor(node);
      return super.visitConstructorDeclaration(node);
    } finally {
      _isEnclosingConstructorConst = false;
      _isInFactory = false;
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      SimpleIdentifier fieldName = node.fieldName;
      Element staticElement = fieldName.staticElement;
      _checkForInvalidField(node, fieldName, staticElement);
      if (staticElement is FieldElement) {
        _checkForFieldInitializerNotAssignable(node, staticElement);
      }
      return super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl &&
          labelElement.isOnSwitchStatement) {
        _errorReporter.reportErrorForNode(
            ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode);
      }
    }
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    _checkForInvalidAssignment(node.identifier, node.defaultValue);
    _checkForDefaultValueInFunctionTypedParameter(node);
    return super.visitDefaultFormalParameter(node);
  }

  @override
  Object visitDoStatement(DoStatement node) {
    _checkForNonBoolCondition(node.condition);
    return super.visitDoStatement(node);
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    ClassElement outerEnum = _enclosingEnum;
    try {
      _enclosingEnum = node.element;
      _checkDuplicateEnumMembers(node);
      return super.visitEnumDeclaration(node);
    } finally {
      _enclosingEnum = outerEnum;
    }
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      LibraryElement exportedLibrary = exportElement.exportedLibrary;
      _checkForAmbiguousExport(node, exportElement, exportedLibrary);
      _checkForExportDuplicateLibraryName(node, exportElement, exportedLibrary);
      _checkForExportInternalLibrary(node, exportElement);
    }
    return super.visitExportDirective(node);
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    bool wasInAsync = _inAsync;
    bool wasInGenerator = _inGenerator;
    try {
      _inAsync = node.isAsynchronous;
      _inGenerator = node.isGenerator;
      FunctionType functionType = _enclosingFunction?.type;
      DartType expectedReturnType = functionType == null
          ? DynamicTypeImpl.instance
          : functionType.returnType;
      ExecutableElement function = _enclosingFunction;
      bool isSetterWithImplicitReturn = function.hasImplicitReturnType &&
          function is PropertyAccessorElement &&
          function.isSetter;
      if (!isSetterWithImplicitReturn) {
        _checkForReturnOfInvalidType(node.expression, expectedReturnType,
            isArrowFunction: true);
      }
      return super.visitExpressionFunctionBody(node);
    } finally {
      _inAsync = wasInAsync;
      _inGenerator = wasInGenerator;
    }
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _isInStaticVariableDeclaration = node.isStatic;
    _isInInstanceVariableDeclaration = !_isInStaticVariableDeclaration;
    if (_isInInstanceVariableDeclaration) {
      VariableDeclarationList variables = node.fields;
      if (variables.isConst) {
        _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.CONST_INSTANCE_FIELD, variables.keyword);
      }
    }
    try {
      _checkForAllInvalidOverrideErrorCodesForField(node);
      return super.visitFieldDeclaration(node);
    } finally {
      _isInStaticVariableDeclaration = false;
      _isInInstanceVariableDeclaration = false;
    }
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    _checkForValidField(node);
    _checkForConstFormalParameter(node);
    _checkForPrivateOptionalParameter(node);
    _checkForFieldInitializingFormalRedirectingConstructor(node);
    _checkForTypeAnnotationDeferredClass(node.type);
    return super.visitFieldFormalParameter(node);
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    _checkForInIterable(node);
    return super.visitForEachStatement(node);
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
    _checkDuplicateDefinitionInParameterList(node);
    _checkUseOfCovariantInParameters(node);
    return super.visitFormalParameterList(node);
  }

  @override
  Object visitForStatement(ForStatement node) {
    if (node.condition != null) {
      _checkForNonBoolCondition(node.condition);
    }
    if (node.variables != null) {
      _checkDuplicateVariables(node.variables);
    }
    return super.visitForStatement(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement functionElement = node.element;
    if (functionElement != null &&
        functionElement.enclosingElement is! CompilationUnitElement) {
      _hiddenElements.declare(functionElement);
    }
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier identifier = node.name;
      String methodName = "";
      if (identifier != null) {
        methodName = identifier.name;
      }
      _enclosingFunction = functionElement;
      TypeAnnotation returnType = node.returnType;
      if (node.isSetter || node.isGetter) {
        _checkForMismatchedAccessorTypes(node, methodName);
        if (node.isSetter) {
          FunctionExpression functionExpression = node.functionExpression;
          if (functionExpression != null) {
            _checkForWrongNumberOfParametersForSetter(
                identifier, functionExpression.parameters);
          }
          _checkForNonVoidReturnTypeForSetter(returnType);
        }
      }
      if (node.isSetter) {
        _checkForInvalidModifierOnBody(node.functionExpression.body,
            CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER);
      }
      _checkForTypeAnnotationDeferredClass(returnType);
      _checkForIllegalReturnType(returnType);
      _checkForImplicitDynamicReturn(node.name, node.element);
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    // If this function expression is wrapped in a function declaration, don't
    // change the enclosingFunction field.
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
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression functionExpression = node.function;
    DartType expressionType = functionExpression.staticType;
    if (!_isFunctionType(expressionType)) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
          functionExpression);
    } else if (expressionType is FunctionType) {
      _checkTypeArguments(node);
    }
    _checkForImplicitDynamicInvoke(node);
    return super.visitFunctionExpressionInvocation(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForDefaultValueInFunctionTypeAlias(node);
    _checkForTypeAliasCannotReferenceItself_function(node);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    bool old = _isInFunctionTypedFormalParameter;
    _isInFunctionTypedFormalParameter = true;
    try {
      _checkForTypeAnnotationDeferredClass(node.returnType);

      // TODO(jmesserly): ideally we'd use _checkForImplicitDynamicReturn, and
      // we can get the function element via `node?.element?.type?.element` but
      // it doesn't have hasImplicitReturnType set correctly.
      if (!_options.implicitDynamic && node.returnType == null) {
        DartType parameterType =
            resolutionMap.elementDeclaredByFormalParameter(node).type;
        if (parameterType is FunctionType &&
            parameterType.returnType.isDynamic) {
          _errorReporter.reportErrorForNode(
              StrongModeCode.IMPLICIT_DYNAMIC_RETURN,
              node.identifier,
              [node.identifier]);
        }
      }

      // TODO(paulberry): remove this once dartbug.com/28515 is fixed.
      if (node.typeParameters != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED,
            node);
      }

      return super.visitFunctionTypedFormalParameter(node);
    } finally {
      _isInFunctionTypedFormalParameter = old;
    }
  }

  @override
  Object visitIfStatement(IfStatement node) {
    _checkForNonBoolCondition(node.condition);
    return super.visitIfStatement(node);
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    node.interfaces.forEach(_checkForImplicitDynamicType);
    return super.visitImplementsClause(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (node.prefix != null) {
      _checkForBuiltInIdentifierAsName(
          node.prefix, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME);
    }
    if (importElement != null) {
      _checkForImportDuplicateLibraryName(node, importElement);
      _checkForImportInternalLibrary(node, importElement);
    }
    return super.visitImportDirective(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    _checkForArgumentTypeNotAssignableForArgument(node.index);
    return super.visitIndexExpression(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    bool wasInConstInstanceCreation = _isInConstInstanceCreation;
    _isInConstInstanceCreation = node.isConst;
    try {
      ConstructorName constructorName = node.constructorName;
      TypeName typeName = constructorName.type;
      DartType type = typeName.type;
      if (type is InterfaceType) {
        _checkForConstOrNewWithAbstractClass(node, typeName, type);
        _checkForConstOrNewWithEnum(node, typeName, type);
        if (_isInConstInstanceCreation) {
          _checkForConstWithNonConst(node);
          _checkForConstWithUndefinedConstructor(
              node, constructorName, typeName);
          if (!_options.strongMode) {
            _checkForConstWithTypeParameters(typeName);
          }
          _checkForConstDeferredClass(node, constructorName, typeName);
        } else {
          _checkForNewWithUndefinedConstructor(node, constructorName, typeName);
        }
      }
      _checkForImplicitDynamicType(typeName);
      return super.visitInstanceCreationExpression(node);
    } finally {
      _isInConstInstanceCreation = wasInConstInstanceCreation;
    }
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    _checkForTypeAnnotationGenericFunctionParameter(node.type);
    return super.visitIsExpression(node);
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (!_options.strongMode && node.constKeyword != null) {
        NodeList<TypeAnnotation> arguments = typeArguments.arguments;
        if (arguments.isNotEmpty) {
          _checkForInvalidTypeArgumentInConstTypedLiteral(arguments,
              CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST);
        }
      }
      _checkForExpectedOneListTypeArgument(node, typeArguments);
    }
    _checkForImplicitDynamicTypedLiteral(node);
    _checkForListElementTypeNotAssignable(node);
    return super.visitListLiteral(node);
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeAnnotation> arguments = typeArguments.arguments;
      if (!_options.strongMode && arguments.isNotEmpty) {
        if (node.constKeyword != null) {
          _checkForInvalidTypeArgumentInConstTypedLiteral(arguments,
              CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP);
        }
      }
      _checkExpectedTwoMapTypeArguments(typeArguments);
    }
    _checkForImplicitDynamicTypedLiteral(node);
    _checkForMapTypeNotAssignable(node);
    _checkForNonConstMapAsExpressionStatement(node);
    return super.visitMapLiteral(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _enclosingFunction;
    try {
      _isInStaticMethod = node.isStatic;
      _enclosingFunction = node.element;
      SimpleIdentifier identifier = node.name;
      String methodName = "";
      if (identifier != null) {
        methodName = identifier.name;
      }
      TypeAnnotation returnType = node.returnType;
      if (node.isSetter || node.isGetter) {
        _checkForMismatchedAccessorTypes(node, methodName);
      }
      if (node.isGetter) {
        _checkForConflictingStaticGetterAndInstanceSetter(node);
      } else if (node.isSetter) {
        _checkForInvalidModifierOnBody(
            node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER);
        _checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        _checkForNonVoidReturnTypeForSetter(returnType);
        _checkForConflictingStaticSetterAndInstanceMember(node);
      } else if (node.isOperator) {
        _checkForOptionalParameterInOperator(node);
        _checkForWrongNumberOfParametersForOperator(node);
        _checkForNonVoidReturnTypeForOperator(node);
      }
      _checkForConcreteClassWithAbstractMember(node);
      _checkForAllInvalidOverrideErrorCodesForMethod(node);
      _checkForTypeAnnotationDeferredClass(returnType);
      _checkForIllegalReturnType(returnType);
      _checkForImplicitDynamicReturn(node, node.element);
      _checkForMustCallSuper(node);
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = previousFunction;
      _isInStaticMethod = false;
    }
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      ClassElement typeReference = ElementResolver.getTypeReference(target);
      _checkForStaticAccessToInstanceMember(typeReference, methodName);
      _checkForInstanceAccessToStaticMember(typeReference, methodName);
    } else {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(methodName);
    }
    _checkTypeArguments(node);
    _checkForImplicitDynamicInvoke(node);
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson) Figure out the right rule for when 'native' is
    // allowed.
    if (!_isInSystemLibrary) {
      _errorReporter.reportErrorForNode(
          ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, node);
    }
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSdkCode(node);
    return super.visitNativeFunctionBody(node);
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    _checkForAssignmentToFinal(node.operand);
    _checkForIntNotAssignable(node.operand);
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is! Annotation) {
      ClassElement typeReference =
          ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, name);
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
    if (operatorType == TokenType.BANG) {
      _checkForNonBoolNegationExpression(operand);
    } else if (operatorType.isIncrementOperator) {
      _checkForAssignmentToFinal(operand);
    }
    _checkForIntNotAssignable(operand);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    ClassElement typeReference =
        ElementResolver.getTypeReference(node.realTarget);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(typeReference, propertyName);
    return super.visitPropertyAccess(node);
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _isInConstructorInitializer = true;
    try {
      return super.visitRedirectingConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    _checkForRethrowOutsideCatch(node);
    return super.visitRethrowExpression(node);
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _returnsWithout.add(node);
    } else {
      _returnsWith.add(node);
    }
    _checkForAllReturnStatementErrorCodes(node);
    return super.visitReturnStatement(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    _checkForConstFormalParameter(node);
    _checkForPrivateOptionalParameter(node);
    _checkForTypeAnnotationDeferredClass(node.type);

    // Checks for an implicit dynamic parameter type.
    //
    // We can skip other parameter kinds besides simple formal, because:
    // - DefaultFormalParameter contains a simple one, so it gets here,
    // - FieldFormalParameter error should be reported on the field,
    // - FunctionTypedFormalParameter is a function type, not dynamic.
    _checkForImplicitDynamicIdentifier(node, node.identifier);

    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForAmbiguousImport(node);
    _checkForReferenceBeforeDeclaration(node);
    _checkForImplicitThisReferenceInInitializer(node);
    if (!_isUnqualifiedReferenceToNonLocalStaticMemberAllowed(node)) {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(node);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _isInConstructorInitializer = true;
    try {
      return super.visitSuperConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _checkDuplicateDeclarationInStatements(node.statements);
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _checkDuplicateDeclarationInStatements(node.statements);
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    _checkForSwitchExpressionNotAssignable(node);
    _checkForCaseBlocksNotTerminated(node);
    _checkForMissingEnumConstantInSwitch(node);
    return super.visitSwitchStatement(node);
  }

  @override
  Object visitThisExpression(ThisExpression node) {
    _checkForInvalidReferenceToThis(node);
    return super.visitThisExpression(node);
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _checkForConstEvalThrowsException(node);
    return super.visitThrowExpression(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkForFinalNotInitialized(node.variables);
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    NodeList<TypeAnnotation> list = node.arguments;
    for (TypeAnnotation type in list) {
      _checkForTypeAnnotationDeferredClass(type);
    }
    return super.visitTypeArgumentList(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    _checkForTypeArgumentNotMatchingBounds(node);
    _checkForTypeParameterReferencedByStatic(node);
    return super.visitTypeName(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    _checkForBuiltInIdentifierAsName(node.name,
        CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    _checkForTypeParameterSupertypeOfItsBound(node);
    _checkForTypeAnnotationDeferredClass(node.bound);
    _checkForImplicitDynamicType(node.bound);
    if (_options.strongMode) node.bound?.accept(_uninstantiatedBoundChecker);
    return super.visitTypeParameter(node);
  }

  @override
  Object visitTypeParameterList(TypeParameterList node) {
    _checkDuplicateDefinitionInTypeParameterList(node);
    return super.visitTypeParameterList(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    Expression initializerNode = node.initializer;
    // do checks
    _checkForInvalidAssignment(nameNode, initializerNode,
        isDeclarationCast: true);
    _checkForImplicitDynamicIdentifier(node, nameNode);
    // visit name
    nameNode.accept(this);
    // visit initializer
    String name = nameNode.name;
    _namesForReferenceToDeclaredVariableInInitializer.add(name);
    bool wasInInstanceVariableInitializer = _isInInstanceVariableInitializer;
    _isInInstanceVariableInitializer = _isInInstanceVariableDeclaration;
    try {
      if (initializerNode != null) {
        initializerNode.accept(this);
      }
    } finally {
      _isInInstanceVariableInitializer = wasInInstanceVariableInitializer;
      _namesForReferenceToDeclaredVariableInInitializer.remove(name);
    }
    // declare the variable
    AstNode grandparent = node.parent.parent;
    if (grandparent is! TopLevelVariableDeclaration &&
        grandparent is! FieldDeclaration) {
      VariableElement element = node.element;
      if (element != null) {
        _hiddenElements.declare(element);
      }
    }
    // done
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    return super.visitVariableDeclarationList(node);
  }

  @override
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _checkForFinalNotInitialized(node.variables);
    return super.visitVariableDeclarationStatement(node);
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    _checkForNonBoolCondition(node.condition);
    return super.visitWhileStatement(node);
  }

  @override
  Object visitWithClause(WithClause node) {
    node.mixinTypes.forEach(_checkForImplicitDynamicType);
    return super.visitWithClause(node);
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
    if (_inGenerator) {
      _checkForYieldOfInvalidType(node.expression, node.star != null);
    } else {
      CompileTimeErrorCode errorCode;
      if (node.star != null) {
        errorCode = CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR;
      } else {
        errorCode = CompileTimeErrorCode.YIELD_IN_NON_GENERATOR;
      }
      _errorReporter.reportErrorForNode(errorCode, node);
    }
    return super.visitYieldStatement(node);
  }

  /**
   * Checks the class for problems with the superclass, mixins, or implemented
   * interfaces.
   */
  void _checkClassInheritance(
      NamedCompilationUnitMember node,
      TypeName superclass,
      WithClause withClause,
      ImplementsClause implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot extend double" already on the
    // class.
    if (!_checkForExtendsDisallowedClass(superclass) &&
        !_checkForImplementsDisallowedClass(implementsClause) &&
        !_checkForAllMixinErrorCodes(withClause)) {
      _checkForImplicitDynamicType(superclass);
      _checkForExtendsDeferredClass(superclass);
      _checkForImplementsDeferredClass(implementsClause);
      _checkForNonAbstractClassInheritsAbstractMember(node.name);
      _checkForInconsistentMethodInheritance();
      _checkForRecursiveInterfaceInheritance(_enclosingClass);
      _checkForConflictingGetterAndMethod();
      _checkForConflictingInstanceGetterAndSuperclassMember();
      _checkImplementsSuperClass(implementsClause);
      _checkImplementsFunctionWithoutCall(node.name);
      _checkForMixinHasNoConstructors(node);

      if (_options.strongMode) {
        _checkForMixinWithConflictingPrivateMember(withClause, superclass);
      }
    }
  }

  /**
   * Given a list of [directives] that have the same prefix, generate an error
   * if there is more than one import and any of those imports is deferred.
   *
   * See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
   */
  void _checkDeferredPrefixCollision(List<ImportDirective> directives) {
    int count = directives.length;
    if (count > 1) {
      for (int i = 0; i < count; i++) {
        Token deferredToken = directives[i].deferredKeyword;
        if (deferredToken != null) {
          _errorReporter.reportErrorForToken(
              CompileTimeErrorCode.SHARED_DEFERRED_PREFIX, deferredToken);
        }
      }
    }
  }

  /**
   * Check that there are no members with the same name.
   */
  void _checkDuplicateClassMembers(ClassDeclaration node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    Set<String> visitedFields = new HashSet<String>();
    for (ClassMember member in node.members) {
      // We ignore constructors because they are checked in the method
      // _checkForConflictingConstructorNameAndMember.
      if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          SimpleIdentifier identifier = field.name;
          _checkDuplicateIdentifier(definedNames, identifier);
          String name = identifier.name;
          if (!field.isFinal &&
              !field.isConst &&
              !visitedFields.contains(name)) {
            _checkDuplicateIdentifier(definedNames, identifier,
                implicitSetter: true);
          }
          visitedFields.add(name);
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(definedNames, member.name);
      }
    }
  }

  /**
   * Check that all of the parameters have unique names.
   */
  void _checkDuplicateDeclarationInStatements(List<Statement> statements) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    for (Statement statement in statements) {
      if (statement is VariableDeclarationStatement) {
        for (VariableDeclaration variable in statement.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name);
        }
      } else if (statement is FunctionDeclarationStatement) {
        _checkDuplicateIdentifier(
            definedNames, statement.functionDeclaration.name);
      }
    }
  }

  /**
   * Check that the exception and stack trace parameters have different names.
   */
  void _checkDuplicateDefinitionInCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      String exceptionName = exceptionParameter.name;
      if (exceptionName == stackTraceParameter.name) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            stackTraceParameter,
            [exceptionName]);
      }
    }
  }

  /**
   * Check that all of the parameters have unique names.
   */
  void _checkDuplicateDefinitionInParameterList(FormalParameterList node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    for (FormalParameter parameter in node.parameters) {
      SimpleIdentifier identifier = parameter.identifier;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.
        _checkDuplicateIdentifier(definedNames, identifier);
      }
    }
  }

  /**
   * Check that all of the parameters have unique names.
   */
  void _checkDuplicateDefinitionInTypeParameterList(TypeParameterList node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    for (TypeParameter parameter in node.typeParameters) {
      _checkDuplicateIdentifier(definedNames, parameter.name);
    }
  }

  /**
   * Check that there are no members with the same name.
   */
  void _checkDuplicateEnumMembers(EnumDeclaration node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    ClassElement element = node.element;
    String indexName = 'index';
    String valuesName = 'values';
    definedNames[indexName] = element.getField(indexName);
    definedNames[valuesName] = element.getField(valuesName);
    for (EnumConstantDeclaration constant in node.constants) {
      _checkDuplicateIdentifier(definedNames, constant.name);
    }
  }

  /**
   * Check whether the given [identifier] is already in the set of
   * [definedNames], and produce an error if it is. If [implicitSetter] is
   * `true`, then the identifier represents the definition of a setter.
   */
  void _checkDuplicateIdentifier(
      Map<String, Element> definedNames, SimpleIdentifier identifier,
      {bool implicitSetter: false}) {
    ErrorCode getError(Element previous, Element current) {
      if (previous is MethodElement && current is PropertyAccessorElement) {
        if (current.isGetter) {
          return CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME;
        }
      } else if (previous is PropertyAccessorElement &&
          current is MethodElement) {
        if (previous.isGetter) {
          return CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME;
        }
      } else if (previous is PrefixElement) {
        return CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    Element current = identifier.staticElement;
    String name = identifier.name;
    if (current is PropertyAccessorElement && current.isSetter) {
      name += '=';
    } else if (current is MethodElement && current.isOperator && name == '-') {
      if (current.parameters.length == 0) {
        name = 'unary-';
      }
    } else if (implicitSetter) {
      name += '=';
    }
    Element previous = definedNames[name];
    if (previous != null) {
      _errorReporter
          .reportErrorForNode(getError(previous, current), identifier, [name]);
    } else {
      definedNames[name] = identifier.staticElement;
    }
  }

  /**
   * Check that there are no members with the same name.
   */
  void _checkDuplicateUnitMembers(CompilationUnit node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    void addWithoutChecking(CompilationUnitElement element) {
      for (PropertyAccessorElement accessor in element.accessors) {
        String name = accessor.name;
        if (accessor.isSetter) {
          name += '=';
        }
        definedNames[name] = accessor;
      }
      for (ClassElement type in element.enums) {
        definedNames[type.name] = type;
      }
      for (FunctionElement function in element.functions) {
        definedNames[function.name] = function;
      }
      for (FunctionTypeAliasElement alias in element.functionTypeAliases) {
        definedNames[alias.name] = alias;
      }
      for (TopLevelVariableElement variable in element.topLevelVariables) {
        definedNames[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedNames[variable.name + '='] = variable;
        }
      }
      for (ClassElement type in element.types) {
        definedNames[type.name] = type;
      }
    }

    for (ImportElement importElement in _currentLibrary.imports) {
      PrefixElement prefix = importElement.prefix;
      if (prefix != null) {
        definedNames[prefix.name] = prefix;
      }
    }
    CompilationUnitElement element = node.element;
    if (element != _currentLibrary.definingCompilationUnit) {
      addWithoutChecking(_currentLibrary.definingCompilationUnit);
      for (CompilationUnitElement part in _currentLibrary.parts) {
        if (element == part) {
          break;
        }
        addWithoutChecking(part);
      }
    }
    for (CompilationUnitMember member in node.declarations) {
      if (member is NamedCompilationUnitMember) {
        _checkDuplicateIdentifier(definedNames, member.name);
      } else if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name);
          if (!variable.isFinal && !variable.isConst) {
            _checkDuplicateIdentifier(definedNames, variable.name,
                implicitSetter: true);
          }
        }
      }
    }
  }

  /**
   * Check that the given list of variable declarations does not define multiple
   * variables of the same name.
   */
  void _checkDuplicateVariables(VariableDeclarationList node) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    for (VariableDeclaration variable in node.variables) {
      _checkDuplicateIdentifier(definedNames, variable.name);
    }
  }

  /**
   * Verify that the given list of [typeArguments] contains exactly two
   * elements.
   *
   * See [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS].
   */
  void _checkExpectedTwoMapTypeArguments(TypeArgumentList typeArguments) {
    int num = typeArguments.arguments.length;
    if (num != 2) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS,
          typeArguments,
          [num]);
    }
  }

  /**
   * Verify that the given [constructor] declaration does not violate any of the
   * error codes relating to the initialization of fields in the enclosing
   * class.
   *
   * See [_initialFieldElementsMap],
   * [StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR], and
   * [CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES].
   */
  void _checkForAllFinalInitializedErrorCodes(
      ConstructorDeclaration constructor) {
    if (constructor.factoryKeyword != null ||
        constructor.redirectedConstructor != null ||
        constructor.externalKeyword != null) {
      return;
    }
    // Ignore if native class.
    if (_isInNativeClass) {
      return;
    }

    HashMap<FieldElement, INIT_STATE> fieldElementsMap =
        new HashMap<FieldElement, INIT_STATE>.from(_initialFieldElementsMap);
    // Visit all of the field formal parameters
    NodeList<FormalParameter> formalParameters =
        constructor.parameters.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      FormalParameter baseParameter(FormalParameter parameter) {
        if (parameter is DefaultFormalParameter) {
          return parameter.parameter;
        }
        return parameter;
      }

      FormalParameter parameter = baseParameter(formalParameter);
      if (parameter is FieldFormalParameter) {
        FieldElement fieldElement =
            (parameter.element as FieldFormalParameterElementImpl).field;
        INIT_STATE state = fieldElementsMap[fieldElement];
        if (state == INIT_STATE.NOT_INIT) {
          fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_FIELD_FORMAL;
        } else if (state == INIT_STATE.INIT_IN_DECLARATION) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode
                    .FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
                formalParameter.identifier,
                [fieldElement.displayName]);
          }
        } else if (state == INIT_STATE.INIT_IN_FIELD_FORMAL) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES,
                formalParameter.identifier,
                [fieldElement.displayName]);
          }
        }
      }
    }
    // Visit all of the initializers
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer constructorInitializer in initializers) {
      if (constructorInitializer is RedirectingConstructorInvocation) {
        return;
      }
      if (constructorInitializer is ConstructorFieldInitializer) {
        SimpleIdentifier fieldName = constructorInitializer.fieldName;
        Element element = fieldName.staticElement;
        if (element is FieldElement) {
          INIT_STATE state = fieldElementsMap[element];
          if (state == INIT_STATE.NOT_INIT) {
            fieldElementsMap[element] = INIT_STATE.INIT_IN_INITIALIZERS;
          } else if (state == INIT_STATE.INIT_IN_DECLARATION) {
            if (element.isFinal || element.isConst) {
              _errorReporter.reportErrorForNode(
                  StaticWarningCode
                      .FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
                  fieldName);
            }
          } else if (state == INIT_STATE.INIT_IN_FIELD_FORMAL) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode
                    .FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
                fieldName);
          } else if (state == INIT_STATE.INIT_IN_INITIALIZERS) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
                fieldName,
                [element.displayName]);
          }
        }
      }
    }
    // Prepare a list of not initialized fields.
    List<FieldElement> notInitFinalFields = <FieldElement>[];
    fieldElementsMap.forEach((FieldElement fieldElement, INIT_STATE state) {
      if (state == INIT_STATE.NOT_INIT) {
        if (fieldElement.isFinal) {
          notInitFinalFields.add(fieldElement);
        }
      }
    });
    // Visit all of the states in the map to ensure that none were never
    // initialized.
    fieldElementsMap.forEach((FieldElement fieldElement, INIT_STATE state) {
      if (state == INIT_STATE.NOT_INIT) {
        if (fieldElement.isConst) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              constructor.returnType,
              [fieldElement.name]);
        }
      }
    });

    if (notInitFinalFields.isNotEmpty) {
      List<String> names = notInitFinalFields.map((item) => item.name).toList();
      names.sort();
      if (names.length == 1) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
            constructor.returnType,
            names);
      } else if (names.length == 2) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2,
            constructor.returnType,
            names);
      } else {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS,
            constructor.returnType,
            [names[0], names[1], names.length - 2]);
      }
    }
  }

  /**
   * Check the given [derivedElement] against override-error codes. The
   * [baseElement] is the element that the executable element is
   * overriding. The [parameters] is the parameters of the executable element.
   * The [errorNameTarget] is the node to report problems on.
   *
   * See [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC],
   * [CompileTimeErrorCode.INVALID_OVERRIDE_REQUIRED],
   * [CompileTimeErrorCode.INVALID_OVERRIDE_POSITIONAL],
   * [CompileTimeErrorCode.INVALID_OVERRIDE_NAMED],
   * [StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE],
   * [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE],
   * [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE],
   * [StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE],
   * [StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE],
   * [StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE], and
   * [StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES].
   */
  bool _checkForAllInvalidOverrideErrorCodes(
      ExecutableElement derivedElement,
      ExecutableElement baseElement,
      List<ParameterElement> parameters,
      List<AstNode> parameterLocations,
      SimpleIdentifier errorNameTarget) {
    if (_options.strongMode) {
      return false; // strong mode already checked for this
    }

    bool isGetter = false;
    bool isSetter = false;
    if (derivedElement is PropertyAccessorElement) {
      isGetter = derivedElement.isGetter;
      isSetter = derivedElement.isSetter;
    }
    String executableElementName = derivedElement.name;
    FunctionType derivedFT = derivedElement.type;
    FunctionType baseFT = baseElement.type;
    InterfaceType enclosingType = _enclosingClass.type;
    baseFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(
        baseFT, executableElementName, enclosingType);
    if (derivedFT == null || baseFT == null) {
      return false;
    }

    // Handle generic function type parameters.
    // TODO(jmesserly): this duplicates some code in isSubtypeOf and most of
    // _isGenericFunctionSubtypeOf. Ideally, we'd let TypeSystem produce
    // an error message once it's ready to "return false".
    if (!derivedFT.typeFormals.isEmpty) {
      if (baseFT.typeFormals.isEmpty) {
        derivedFT = _typeSystem.instantiateToBounds(derivedFT);
      } else {
        List<TypeParameterElement> params1 = derivedFT.typeFormals;
        List<TypeParameterElement> params2 = baseFT.typeFormals;
        int count = params1.length;
        if (params2.length != count) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS,
              errorNameTarget, [
            count,
            params2.length,
            baseElement.enclosingElement.displayName
          ]);
          return true;
        }
        // We build up a substitution matching up the type parameters
        // from the two types, {variablesFresh/variables1} and
        // {variablesFresh/variables2}
        List<DartType> variables1 = new List<DartType>();
        List<DartType> variables2 = new List<DartType>();
        List<DartType> variablesFresh = new List<DartType>();
        for (int i = 0; i < count; i++) {
          TypeParameterElement p1 = params1[i];
          TypeParameterElement p2 = params2[i];
          TypeParameterElementImpl pFresh =
              new TypeParameterElementImpl(p1.name, -1);

          DartType variable1 = p1.type;
          DartType variable2 = p2.type;
          DartType variableFresh = new TypeParameterTypeImpl(pFresh);

          variables1.add(variable1);
          variables2.add(variable2);
          variablesFresh.add(variableFresh);
          DartType bound1 = p1.bound ?? DynamicTypeImpl.instance;
          DartType bound2 = p2.bound ?? DynamicTypeImpl.instance;
          bound1 = bound1.substitute2(variablesFresh, variables1);
          bound2 = bound2.substitute2(variablesFresh, variables2);
          pFresh.bound = bound2;
          if (!_typeSystem.isSubtypeOf(bound2, bound1)) {
            _errorReporter.reportErrorForNode(
                HintCode.INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND,
                errorNameTarget, [
              p1.displayName,
              p1.bound,
              p2.displayName,
              p2.bound,
              baseElement.enclosingElement.displayName
            ]);
            return true;
          }
        }
        // Proceed with the rest of the checks, using instantiated types.
        derivedFT = derivedFT.instantiate(variablesFresh);
        baseFT = baseFT.instantiate(variablesFresh);
      }
    }

    DartType derivedFTReturnType = derivedFT.returnType;
    DartType baseFTReturnType = baseFT.returnType;
    List<DartType> derivedNormalPT = derivedFT.normalParameterTypes;
    List<DartType> baseNormalPT = baseFT.normalParameterTypes;
    List<DartType> derivedPositionalPT = derivedFT.optionalParameterTypes;
    List<DartType> basePositionalPT = baseFT.optionalParameterTypes;
    Map<String, DartType> derivedNamedPT = derivedFT.namedParameterTypes;
    Map<String, DartType> baseNamedPT = baseFT.namedParameterTypes;
    // CTEC.INVALID_OVERRIDE_REQUIRED, CTEC.INVALID_OVERRIDE_POSITIONAL and
    // CTEC.INVALID_OVERRIDE_NAMED
    if (derivedNormalPT.length > baseNormalPT.length) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.INVALID_OVERRIDE_REQUIRED, errorNameTarget, [
        baseNormalPT.length,
        baseElement,
        baseElement.enclosingElement.displayName
      ]);
      return true;
    }
    if (derivedNormalPT.length + derivedPositionalPT.length <
        basePositionalPT.length + baseNormalPT.length) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.INVALID_OVERRIDE_POSITIONAL, errorNameTarget, [
        basePositionalPT.length + baseNormalPT.length,
        baseElement,
        baseElement.enclosingElement.displayName
      ]);
      return true;
    }
    // For each named parameter in the overridden method, verify that there is
    // the same name in the overriding method.
    for (String overriddenParamName in baseNamedPT.keys) {
      if (!derivedNamedPT.containsKey(overriddenParamName)) {
        // The overridden method expected the overriding method to have
        // overridingParamName, but it does not.
        _errorReporter.reportErrorForNode(
            StaticWarningCode.INVALID_OVERRIDE_NAMED, errorNameTarget, [
          overriddenParamName,
          baseElement,
          baseElement.enclosingElement.displayName
        ]);
        return true;
      }
    }
    // SWC.INVALID_METHOD_OVERRIDE_RETURN_TYPE
    if (baseFTReturnType != VoidTypeImpl.instance &&
        !_typeSystem.isAssignableTo(derivedFTReturnType, baseFTReturnType)) {
      _errorReporter.reportTypeErrorForNode(
          !isGetter
              ? StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE
              : StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE,
          errorNameTarget,
          [
            derivedFTReturnType,
            baseFTReturnType,
            baseElement.enclosingElement.displayName
          ]);
      return true;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
    if (parameterLocations == null) {
      return false;
    }
    int parameterIndex = 0;
    for (int i = 0; i < derivedNormalPT.length; i++) {
      if (!_typeSystem.isAssignableTo(baseNormalPT[i], derivedNormalPT[i])) {
        _errorReporter.reportTypeErrorForNode(
            !isSetter
                ? StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
                : StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE,
            parameterLocations[parameterIndex],
            [
              derivedNormalPT[i],
              baseNormalPT[i],
              baseElement.enclosingElement.displayName
            ]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE
    for (int i = 0; i < basePositionalPT.length; i++) {
      if (!_typeSystem.isAssignableTo(
          basePositionalPT[i], derivedPositionalPT[i])) {
        _errorReporter.reportTypeErrorForNode(
            StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE,
            parameterLocations[parameterIndex], [
          derivedPositionalPT[i],
          basePositionalPT[i],
          baseElement.enclosingElement.displayName
        ]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE &
    // SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    for (String overriddenName in baseNamedPT.keys) {
      DartType derivedType = derivedNamedPT[overriddenName];
      if (derivedType == null) {
        // Error, this is never reached- INVALID_OVERRIDE_NAMED would have been
        // created above if this could be reached.
        continue;
      }
      DartType baseType = baseNamedPT[overriddenName];
      if (!_typeSystem.isAssignableTo(baseType, derivedType)) {
        // lookup the parameter for the error to select
        ParameterElement parameterToSelect = null;
        AstNode parameterLocationToSelect = null;
        for (int i = 0; i < parameters.length; i++) {
          ParameterElement parameter = parameters[i];
          if (parameter.parameterKind == ParameterKind.NAMED &&
              overriddenName == parameter.name) {
            parameterToSelect = parameter;
            parameterLocationToSelect = parameterLocations[i];
            break;
          }
        }
        if (parameterToSelect != null) {
          _errorReporter.reportTypeErrorForNode(
              StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE,
              parameterLocationToSelect, [
            derivedType,
            baseType,
            baseElement.enclosingElement.displayName
          ]);
          return true;
        }
      }
    }
    // SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    //
    // Create three lists: a list of the optional parameter ASTs
    // (FormalParameters), a list of the optional parameters elements from our
    // method, and finally a list of the optional parameter elements from the
    // method we are overriding.
    //
    bool foundError = false;
    List<AstNode> formalParameters = new List<AstNode>();
    List<ParameterElementImpl> parameterElts = new List<ParameterElementImpl>();
    List<ParameterElementImpl> overriddenParameterElts =
        new List<ParameterElementImpl>();
    List<ParameterElement> overriddenPEs = baseElement.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameter = parameters[i];
      if (parameter.parameterKind.isOptional) {
        formalParameters.add(parameterLocations[i]);
        parameterElts.add(parameter as ParameterElementImpl);
      }
    }
    for (ParameterElement parameterElt in overriddenPEs) {
      if (parameterElt.parameterKind.isOptional) {
        if (parameterElt is ParameterElementImpl) {
          overriddenParameterElts.add(parameterElt);
        }
      }
    }
    //
    // Next compare the list of optional parameter elements to the list of
    // overridden optional parameter elements.
    //
    if (parameterElts.length > 0) {
      if (parameterElts[0].parameterKind == ParameterKind.NAMED) {
        // Named parameters, consider the names when matching the parameterElts
        // to the overriddenParameterElts
        for (int i = 0; i < parameterElts.length; i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (_isUserDefinedObject(result)) {
            continue;
          }
          String parameterName = parameterElt.name;
          for (int j = 0; j < overriddenParameterElts.length; j++) {
            ParameterElementImpl overriddenParameterElt =
                overriddenParameterElts[j];
            if (overriddenParameterElt.initializer == null) {
              // There is no warning if the overridden parameter has an
              // implicit default.
              continue;
            }
            String overriddenParameterName = overriddenParameterElt.name;
            if (parameterName != null &&
                parameterName == overriddenParameterName) {
              EvaluationResultImpl overriddenResult =
                  overriddenParameterElt.evaluationResult;
              if (_isUserDefinedObject(overriddenResult)) {
                break;
              }
              if (!result.equalValues(_typeProvider, overriddenResult)) {
                _errorReporter.reportErrorForNode(
                    StaticWarningCode
                        .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
                    formalParameters[i],
                    [
                      baseElement.enclosingElement.displayName,
                      baseElement.displayName,
                      parameterName
                    ]);
                foundError = true;
              }
            }
          }
        }
      } else {
        // Positional parameters, consider the positions when matching the
        // parameterElts to the overriddenParameterElts
        for (int i = 0;
            i < parameterElts.length && i < overriddenParameterElts.length;
            i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (_isUserDefinedObject(result)) {
            continue;
          }
          ParameterElementImpl overriddenParameterElt =
              overriddenParameterElts[i];
          if (overriddenParameterElt.initializer == null) {
            // There is no warning if the overridden parameter has an implicit
            // default.
            continue;
          }
          EvaluationResultImpl overriddenResult =
              overriddenParameterElt.evaluationResult;
          if (_isUserDefinedObject(overriddenResult)) {
            continue;
          }
          if (!result.equalValues(_typeProvider, overriddenResult)) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode
                    .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
                formalParameters[i],
                [
                  baseElement.enclosingElement.displayName,
                  baseElement.displayName
                ]);
            foundError = true;
          }
        }
      }
    }
    return foundError;
  }

  /**
   * Check the given [executableElement] against override-error codes. This
   * method computes the given executableElement is overriding and calls
   * [_checkForAllInvalidOverrideErrorCodes] when the [InheritanceManager]
   * returns a [MultiplyInheritedExecutableElement], this method loops through
   * the list in the [MultiplyInheritedExecutableElement]. The [parameters] are
   * the parameters of the executable element. The [errorNameTarget] is the node
   * to report problems on.
   */
  void _checkForAllInvalidOverrideErrorCodesForExecutable(
      ExecutableElement executableElement,
      List<ParameterElement> parameters,
      List<AstNode> parameterLocations,
      SimpleIdentifier errorNameTarget) {
    assert(!_options.strongMode); // strong mode already checked for these
    //
    // Compute the overridden executable from the InheritanceManager
    //
    List<ExecutableElement> overriddenExecutables = _inheritanceManager
        .lookupOverrides(_enclosingClass, executableElement.name);
    if (_checkForInstanceMethodNameCollidesWithSuperclassStatic(
        executableElement, errorNameTarget)) {
      return;
    }
    for (ExecutableElement overriddenElement in overriddenExecutables) {
      if (_checkForAllInvalidOverrideErrorCodes(executableElement,
          overriddenElement, parameters, parameterLocations, errorNameTarget)) {
        return;
      }
    }
  }

  /**
   * Check the given field [declaration] against override-error codes.
   *
   * See [_checkForAllInvalidOverrideErrorCodes].
   */
  void _checkForAllInvalidOverrideErrorCodesForField(
      FieldDeclaration declaration) {
    if (_options.strongMode) {
      return; // strong mode already checked for this
    }

    if (_enclosingClass == null || declaration.isStatic) {
      return;
    }

    VariableDeclarationList fields = declaration.fields;
    for (VariableDeclaration field in fields.variables) {
      FieldElement element = field.element as FieldElement;
      if (element == null) {
        continue;
      }
      PropertyAccessorElement getter = element.getter;
      PropertyAccessorElement setter = element.setter;
      SimpleIdentifier fieldName = field.name;
      if (getter != null) {
        _checkForAllInvalidOverrideErrorCodesForExecutable(
            getter, ParameterElement.EMPTY_LIST, AstNode.EMPTY_LIST, fieldName);
      }
      if (setter != null) {
        _checkForAllInvalidOverrideErrorCodesForExecutable(
            setter, setter.parameters, <AstNode>[fieldName], fieldName);
      }
    }
  }

  /**
   * Check the given [method] declaration against override-error codes.
   *
   * See [_checkForAllInvalidOverrideErrorCodes].
   */
  void _checkForAllInvalidOverrideErrorCodesForMethod(
      MethodDeclaration method) {
    if (_options.strongMode) {
      return; // strong mode already checked for this
    }
    if (_enclosingClass == null ||
        method.isStatic ||
        method.body is NativeFunctionBody) {
      return;
    }
    ExecutableElement executableElement = method.element;
    if (executableElement == null) {
      return;
    }
    SimpleIdentifier methodName = method.name;
    if (methodName.isSynthetic) {
      return;
    }
    FormalParameterList formalParameterList = method.parameters;
    NodeList<FormalParameter> parameterList = formalParameterList?.parameters;
    List<AstNode> parameters =
        parameterList != null ? new List.from(parameterList) : null;
    _checkForAllInvalidOverrideErrorCodesForExecutable(executableElement,
        executableElement.parameters, parameters, methodName);
  }

  /**
   * Verify that all classes of the given [withClause] are valid.
   *
   * See [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR],
   * [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT], and
   * [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER].
   */
  bool _checkForAllMixinErrorCodes(WithClause withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    for (TypeName mixinName in withClause.mixinTypes) {
      DartType mixinType = mixinName.type;
      if (mixinType is InterfaceType) {
        if (_checkForExtendsOrImplementsDisallowedClass(
            mixinName, CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          ClassElement mixinElement = mixinType.element;
          if (_checkForExtendsOrImplementsDeferredClass(
              mixinName, CompileTimeErrorCode.MIXIN_DEFERRED_CLASS)) {
            problemReported = true;
          }
          if (_checkForMixinDeclaresConstructor(mixinName, mixinElement)) {
            problemReported = true;
          }
          if (!enableSuperMixins &&
              _checkForMixinInheritsNotFromObject(mixinName, mixinElement)) {
            problemReported = true;
          }
          if (_checkForMixinReferencesSuper(mixinName, mixinElement)) {
            problemReported = true;
          }
        }
      }
    }
    return problemReported;
  }

  /**
   * Check for errors related to the redirected constructors.
   *
   * See [StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE],
   * [StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE], and
   * [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR].
   */
  void _checkForAllRedirectConstructorErrorCodes(
      ConstructorDeclaration declaration) {
    // Prepare redirected constructor node
    ConstructorName redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }

    // Prepare redirected constructor type
    ConstructorElement redirectedElement = redirectedConstructor.staticElement;
    if (redirectedElement == null) {
      // If the element is null, we check for the
      // REDIRECT_TO_MISSING_CONSTRUCTOR case
      TypeName constructorTypeName = redirectedConstructor.type;
      DartType redirectedType = constructorTypeName.type;
      if (redirectedType != null &&
          redirectedType.element != null &&
          !redirectedType.isDynamic) {
        // Prepare the constructor name
        String constructorStrName = constructorTypeName.name.name;
        if (redirectedConstructor.name != null) {
          constructorStrName += ".${redirectedConstructor.name.name}";
        }
        ErrorCode errorCode = (declaration.constKeyword != null
            ? CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR
            : StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR);
        _errorReporter.reportErrorForNode(errorCode, redirectedConstructor,
            [constructorStrName, redirectedType.displayName]);
      }
      return;
    }
    FunctionType redirectedType = redirectedElement.type;
    DartType redirectedReturnType = redirectedType.returnType;

    // Report specific problem when return type is incompatible
    FunctionType constructorType =
        resolutionMap.elementDeclaredByConstructorDeclaration(declaration).type;
    DartType constructorReturnType = constructorType.returnType;
    if (!_typeSystem.isAssignableTo(
        redirectedReturnType, constructorReturnType)) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE,
          redirectedConstructor,
          [redirectedReturnType, constructorReturnType]);
      return;
    } else if (!_typeSystem.isSubtypeOf(redirectedType, constructorType)) {
      // Check parameters.
      _errorReporter.reportErrorForNode(
          StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE,
          redirectedConstructor,
          [redirectedType, constructorType]);
    }
  }

  /**
   * Check that the return [statement] of the form <i>return e;</i> is not in a
   * generative constructor.
   *
   * Check that return statements without expressions are not in a generative
   * constructor and the return type is not assignable to `null`; that is, we
   * don't have `return;` if the enclosing method has a return type.
   *
   * Check that the return type matches the type of the declared return type in
   * the enclosing method or function.
   *
   * See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR],
   * [StaticWarningCode.RETURN_WITHOUT_VALUE], and
   * [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE].
   */
  void _checkForAllReturnStatementErrorCodes(ReturnStatement statement) {
    FunctionType functionType = _enclosingFunction?.type;
    DartType expectedReturnType = functionType == null
        ? DynamicTypeImpl.instance
        : functionType.returnType;
    Expression returnExpression = statement.expression;
    // RETURN_IN_GENERATIVE_CONSTRUCTOR
    bool isGenerativeConstructor(ExecutableElement element) =>
        element is ConstructorElement && !element.isFactory;
    if (isGenerativeConstructor(_enclosingFunction)) {
      if (returnExpression == null) {
        return;
      }
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR,
          returnExpression);
      return;
    }
    // RETURN_WITHOUT_VALUE
    if (returnExpression == null) {
      if (_inGenerator) {
        return;
      } else if (_inAsync) {
        if (expectedReturnType.isDynamic) {
          return;
        }
        if (expectedReturnType is InterfaceType &&
            expectedReturnType.isDartAsyncFuture) {
          DartType futureArgument = expectedReturnType.typeArguments[0];
          if (futureArgument.isDynamic ||
              futureArgument.isDartCoreNull ||
              futureArgument.isObject) {
            return;
          }
        }
      } else if (expectedReturnType.isDynamic ||
          expectedReturnType.isVoid ||
          (expectedReturnType.isDartCoreNull && _options.strongMode)) {
        // TODO(leafp): Empty returns shouldn't be allowed for Null in strong
        // mode either once we allow void as a type argument.  But for now, the
        // only type we can validly infer for f.then((_) {print("hello");}) is
        // Future<Null>, so we allow this.
        return;
      }
      _hasReturnWithoutValue = true;
      _errorReporter.reportErrorForNode(
          StaticWarningCode.RETURN_WITHOUT_VALUE, statement);
      return;
    } else if (_inGenerator) {
      // RETURN_IN_GENERATOR
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETURN_IN_GENERATOR,
          statement,
          [_inAsync ? "async*" : "sync*"]);
    }

    _checkForReturnOfInvalidType(returnExpression, expectedReturnType);
  }

  /**
   * Verify that the export namespace of the given export [directive] does not
   * export any name already exported by another export directive. The
   * [exportElement] is the [ExportElement] retrieved from the node. If the
   * element in the node was `null`, then this method is not called. The
   * [exportedLibrary] is the library element containing the exported element.
   *
   * See [CompileTimeErrorCode.AMBIGUOUS_EXPORT].
   */
  void _checkForAmbiguousExport(ExportDirective directive,
      ExportElement exportElement, LibraryElement exportedLibrary) {
    if (exportedLibrary == null) {
      return;
    }
    // check exported names
    Namespace namespace =
        new NamespaceBuilder().createExportNamespaceForDirective(exportElement);
    Map<String, Element> definedNames = namespace.definedNames;
    for (String name in definedNames.keys) {
      Element element = definedNames[name];
      Element prevElement = _exportedElements[name];
      if (element != null && prevElement != null && prevElement != element) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.AMBIGUOUS_EXPORT, directive, [
          name,
          prevElement.library.definingCompilationUnit.displayName,
          element.library.definingCompilationUnit.displayName
        ]);
        return;
      } else {
        _exportedElements[name] = element;
      }
    }
  }

  /**
   * Check the given node to see whether it was ambiguous because the name was
   * imported from two or more imports.
   */
  void _checkForAmbiguousImport(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is MultiplyDefinedElementImpl) {
      String name = element.displayName;
      List<Element> conflictingMembers = element.conflictingElements;
      int count = conflictingMembers.length;
      List<String> libraryNames = new List<String>(count);
      for (int i = 0; i < count; i++) {
        libraryNames[i] = _getLibraryName(conflictingMembers[i]);
      }
      libraryNames.sort();
      _errorReporter.reportErrorForNode(StaticWarningCode.AMBIGUOUS_IMPORT,
          node, [name, StringUtilities.printListOfQuotedNames(libraryNames)]);
    } else if (element != null) {
      List<Element> sdkElements =
          node.getProperty(LibraryImportScope.conflictingSdkElements);
      if (sdkElements != null) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.CONFLICTING_DART_IMPORT, node, [
          element.displayName,
          _getLibraryName(sdkElements[0]),
          _getLibraryName(element)
        ]);
      }
    }
  }

  /**
   * Verify that the given [expression] can be assigned to its corresponding
   * parameters. The [expectedStaticType] is the expected static type of the
   * parameter. The [actualStaticType] is the actual static type of the
   * argument.
   *
   * This method corresponds to
   * [BestPracticesVerifier.checkForArgumentTypeNotAssignable].
   *
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForArgumentTypeNotAssignable(
      Expression expression,
      DartType expectedStaticType,
      DartType actualStaticType,
      ErrorCode errorCode) {
    // Warning case: test static type information
    if (actualStaticType != null && expectedStaticType != null) {
      _checkForAssignableExpressionAtType(
          expression, actualStaticType, expectedStaticType, errorCode);
    }
  }

  /**
   * Verify that the given [argument] can be assigned to its corresponding
   * parameter.
   *
   * This method corresponds to
   * [BestPracticesVerifier.checkForArgumentTypeNotAssignableForArgument].
   *
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForArgumentTypeNotAssignableForArgument(Expression argument) {
    if (argument == null) {
      return;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    DartType staticParameterType = staticParameterElement?.type;
    _checkForArgumentTypeNotAssignableWithExpectedTypes(argument,
        staticParameterType, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * Verify that the given [expression] can be assigned to its corresponding
   * parameters. The [expectedStaticType] is the expected static type.
   *
   * This method corresponds to
   * [BestPracticesVerifier.checkForArgumentTypeNotAssignableWithExpectedTypes].
   *
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForArgumentTypeNotAssignableWithExpectedTypes(
      Expression expression, DartType expectedStaticType, ErrorCode errorCode) {
    _checkForArgumentTypeNotAssignable(
        expression, expectedStaticType, getStaticType(expression), errorCode);
  }

  /**
   * Verify that the arguments in the given [argumentList] can be assigned to
   * their corresponding parameters.
   *
   * This method corresponds to
   * [BestPracticesVerifier.checkForArgumentTypesNotAssignableInList].
   *
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForArgumentTypesNotAssignableInList(ArgumentList argumentList) {
    if (argumentList == null) {
      return;
    }

    for (Expression argument in argumentList.arguments) {
      _checkForArgumentTypeNotAssignableForArgument(argument);
    }
  }

  /**
   * Check that the static type of the given expression is assignable to the
   * given type. If it isn't, report an error with the given error code. The
   * [type] is the type that the expression must be assignable to. The
   * [errorCode] is the error code to be reported. The [arguments] are the
   * arguments to pass in when creating the error.
   */
  void _checkForAssignability(Expression expression, InterfaceType type,
      ErrorCode errorCode, List<Object> arguments) {
    if (expression == null) {
      return;
    }
    DartType expressionType = expression.staticType;
    if (expressionType == null) {
      return;
    }
    if (_expressionIsAssignableAtType(expression, expressionType, type)) {
      return;
    }
    _errorReporter.reportErrorForNode(errorCode, expression, arguments);
  }

  bool _checkForAssignableExpression(
      Expression expression, DartType expectedStaticType, ErrorCode errorCode,
      {bool isDeclarationCast = false}) {
    DartType actualStaticType = getStaticType(expression);
    return actualStaticType != null &&
        _checkForAssignableExpressionAtType(
            expression, actualStaticType, expectedStaticType, errorCode,
            isDeclarationCast: isDeclarationCast);
  }

  bool _checkForAssignableExpressionAtType(
      Expression expression,
      DartType actualStaticType,
      DartType expectedStaticType,
      ErrorCode errorCode,
      {bool isDeclarationCast = false}) {
    if (!_expressionIsAssignableAtType(
        expression, actualStaticType, expectedStaticType,
        isDeclarationCast: isDeclarationCast)) {
      _errorReporter.reportTypeErrorForNode(
          errorCode, expression, [actualStaticType, expectedStaticType]);
      return false;
    }
    return true;
  }

  /**
   * Verify that the given [expression] is not final.
   *
   * See [StaticWarningCode.ASSIGNMENT_TO_CONST],
   * [StaticWarningCode.ASSIGNMENT_TO_FINAL], and
   * [StaticWarningCode.ASSIGNMENT_TO_METHOD].
   */
  void _checkForAssignmentToFinal(Expression expression) {
    // prepare element
    Element element = null;
    AstNode highlightedNode = expression;
    if (expression is Identifier) {
      element = expression.staticElement;
      if (expression is PrefixedIdentifier) {
        highlightedNode = expression.identifier;
      }
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
      highlightedNode = expression.propertyName;
    }
    // check if element is assignable
    Element toVariable(Element element) {
      return element is PropertyAccessorElement ? element.variable : element;
    }

    element = toVariable(element);
    if (element is VariableElement) {
      if (element.isConst) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.ASSIGNMENT_TO_CONST, expression);
      } else if (element.isFinal) {
        if (element is FieldElementImpl &&
            element.setter == null &&
            element.isSynthetic) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
              highlightedNode,
              [element.name, element.enclosingElement.displayName]);
          return;
        }
        _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_FINAL,
            highlightedNode, [element.name]);
      }
    } else if (element is FunctionElement) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.ASSIGNMENT_TO_FUNCTION, expression);
    } else if (element is MethodElement) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.ASSIGNMENT_TO_METHOD, expression);
    } else if (element is ClassElement ||
        element is FunctionTypeAliasElement ||
        element is TypeParameterElement) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.ASSIGNMENT_TO_TYPE, expression);
    }
  }

  /**
   * Verifies that the class is not named `Function` and that it doesn't
   * extends/implements/mixes in `Function`.
   */
  void _checkForBadFunctionUse(ClassDeclaration node) {
    ExtendsClause extendsClause = node.extendsClause;
    WithClause withClause = node.withClause;

    if (node.name.name == "Function") {
      _errorReporter.reportErrorForNode(
          HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, node.name);
    }

    if (extendsClause != null) {
      InterfaceType superclassType = _enclosingClass.supertype;
      ClassElement superclassElement = superclassType?.element;
      if (superclassElement != null && superclassElement.name == "Function") {
        _errorReporter.reportErrorForNode(
            HintCode.DEPRECATED_EXTENDS_FUNCTION, extendsClause.superclass);
      }
    }

    if (withClause != null) {
      for (TypeName type in withClause.mixinTypes) {
        Element mixinElement = type.name.staticElement;
        if (mixinElement != null && mixinElement.name == "Function") {
          _errorReporter.reportErrorForNode(
              HintCode.DEPRECATED_MIXIN_FUNCTION, type);
        }
      }
    }
  }

  /**
   * Verify that the given [identifier] is not a keyword, and generates the
   * given [errorCode] on the identifier if it is a keyword.
   *
   * See [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
   * [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME], and
   * [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME].
   */
  void _checkForBuiltInIdentifierAsName(
      SimpleIdentifier identifier, ErrorCode errorCode) {
    Token token = identifier.token;
    if (token.type.isKeyword && token.keyword?.isPseudo != true) {
      _errorReporter
          .reportErrorForNode(errorCode, identifier, [identifier.name]);
    }
  }

  /**
   * Verify that the given [switchCase] is terminated with 'break', 'continue',
   * 'return' or 'throw'.
   *
   * see [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED].
   */
  void _checkForCaseBlockNotTerminated(SwitchCase switchCase) {
    NodeList<Statement> statements = switchCase.statements;
    if (statements.isEmpty) {
      // fall-through without statements at all
      AstNode parent = switchCase.parent;
      if (parent is SwitchStatement) {
        NodeList<SwitchMember> members = parent.members;
        int index = members.indexOf(switchCase);
        if (index != -1 && index < members.length - 1) {
          return;
        }
      }
      // no other switch member after this one
    } else {
      Statement statement = statements.last;
      if (statement is Block && statement.statements.isNotEmpty) {
        Block block = statement;
        statement = block.statements.last;
      }
      // terminated with statement
      if (statement is BreakStatement ||
          statement is ContinueStatement ||
          statement is ReturnStatement) {
        return;
      }
      // terminated with 'throw' expression
      if (statement is ExpressionStatement) {
        Expression expression = statement.expression;
        if (expression is ThrowExpression || expression is RethrowExpression) {
          return;
        }
      }
    }

    _errorReporter.reportErrorForToken(
        StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, switchCase.keyword);
  }

  /**
   * Verify that the switch cases in the given switch [statement] are terminated
   * with 'break', 'continue', 'rethrow', 'return' or 'throw'.
   *
   * See [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED].
   */
  void _checkForCaseBlocksNotTerminated(SwitchStatement statement) {
    NodeList<SwitchMember> members = statement.members;
    int lastMember = members.length - 1;
    for (int i = 0; i < lastMember; i++) {
      SwitchMember member = members[i];
      if (member is SwitchCase) {
        _checkForCaseBlockNotTerminated(member);
      }
    }
  }

  /**
   * Verify that the given [method] declaration is abstract only if the
   * enclosing class is also abstract.
   *
   * See [StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER].
   */
  void _checkForConcreteClassWithAbstractMember(MethodDeclaration method) {
    if (method.isAbstract &&
        _enclosingClass != null &&
        !_enclosingClass.isAbstract) {
      SimpleIdentifier nameNode = method.name;
      String memberName = nameNode.name;
      ExecutableElement overriddenMember;
      if (method.isGetter) {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteGetter(
            memberName, _currentLibrary);
      } else if (method.isSetter) {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteSetter(
            memberName, _currentLibrary);
      } else {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteMethod(
            memberName, _currentLibrary);
      }
      if (overriddenMember == null && !_enclosingClass.hasNoSuchMethod) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
            nameNode,
            [memberName, _enclosingClass.displayName]);
      }
    }
  }

  /**
   * Verify all possible conflicts of the given [constructor]'s name with other
   * constructors and members of the same class. The [constructorElement] is the
   * constructor's element.
   *
   * See [CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT],
   * [CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME],
   * [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD], and
   * [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD].
   */
  void _checkForConflictingConstructorNameAndMember(
      ConstructorDeclaration constructor,
      ConstructorElement constructorElement) {
    SimpleIdentifier constructorName = constructor.name;
    String name = constructorElement.name;
    ClassElement classElement = constructorElement.enclosingElement;
    // constructors
    List<ConstructorElement> constructors = classElement.constructors;
    for (ConstructorElement otherConstructor in constructors) {
      if (identical(otherConstructor, constructorElement)) {
        continue;
      }
      if (name == otherConstructor.name) {
        if (name == null || name.length == 0) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, constructor);
        } else {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
              constructor,
              [name]);
        }
        return;
      }
    }
    // conflict with class member
    if (constructorName != null &&
        constructorElement != null &&
        !constructorName.isSynthetic) {
      FieldElement field = classElement.getField(name);
      if (field != null && field.getter != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD,
            constructor,
            [name]);
      } else if (classElement.getMethod(name) != null) {
        // methods
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD,
            constructor,
            [name]);
      }
    }
  }

  /**
   * Verify that the [_enclosingClass] does not have a method and getter pair
   * with the same name on, via inheritance.
   *
   * See [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD], and
   * [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER].
   */
  void _checkForConflictingGetterAndMethod() {
    if (_enclosingClass == null) {
      return;
    }

    // method declared in the enclosing class vs. inherited getter
    for (MethodElement method in _enclosingClass.methods) {
      String name = method.name;
      // find inherited property accessor (and can be only getter)
      ExecutableElement inherited =
          _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! PropertyAccessorElement) {
        continue;
      }

      _errorReporter.reportErrorForElement(
          CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD, method, [
        _enclosingClass.displayName,
        inherited.enclosingElement.displayName,
        name
      ]);
    }
    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (!accessor.isGetter) {
        continue;
      }
      String name = accessor.name;
      // find inherited method
      ExecutableElement inherited =
          _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! MethodElement) {
        continue;
      }

      _errorReporter.reportErrorForElement(
          CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER, accessor, [
        _enclosingClass.displayName,
        inherited.enclosingElement.displayName,
        name
      ]);
    }
  }

  /**
   * Verify that the superclass of the [_enclosingClass] does not declare
   * accessible static members with the same name as the instance
   * getters/setters declared in [_enclosingClass].
   *
   * See [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER], and
   * [StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER].
   */
  void _checkForConflictingInstanceGetterAndSuperclassMember() {
    if (_enclosingClass == null) {
      return;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // check every accessor
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      // we analyze instance accessors here
      if (accessor.isStatic) {
        continue;
      }
      // prepare accessor properties
      String name = accessor.displayName;
      bool getter = accessor.isGetter;
      // if non-final variable, ignore setter - we already reported problem for
      // getter
      if (accessor.isSetter && accessor.isSynthetic) {
        continue;
      }
      // try to find super element
      ExecutableElement superElement;
      superElement =
          enclosingType.lookUpGetterInSuperclass(name, _currentLibrary);
      if (superElement == null) {
        superElement =
            enclosingType.lookUpSetterInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        superElement =
            enclosingType.lookUpMethodInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        continue;
      }
      // OK, not static
      if (!superElement.isStatic) {
        continue;
      }
      // prepare "super" type to report its name
      ClassElement superElementClass =
          superElement.enclosingElement as ClassElement;
      InterfaceType superElementType = superElementClass.type;

      if (getter) {
        _errorReporter.reportErrorForElement(
            StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
            accessor,
            [superElementType.displayName]);
      } else {
        _errorReporter.reportErrorForElement(
            StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER,
            accessor,
            [superElementType.displayName]);
      }
    }
  }

  /**
   * Verify that the enclosing class does not have a setter with the same name
   * as the given instance method declaration.
   *
   * TODO(jwren) add other "conflicting" error codes into algorithm/ data
   * structure.
   *
   * See [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER].
   */
  void _checkForConflictingInstanceMethodSetter(ClassDeclaration declaration) {
    // Reference all of the class members in this class.
    NodeList<ClassMember> classMembers = declaration.members;
    if (classMembers.isEmpty) {
      return;
    }
    // Create a HashMap to track conflicting members, and then loop through
    // members in the class to construct the HashMap, at the same time,
    // look for violations.  Don't add members if they are part of a conflict,
    // this prevents multiple warnings for one issue.
    HashMap<String, ClassMember> memberHashMap =
        new HashMap<String, ClassMember>();
    for (ClassMember member in classMembers) {
      if (member is MethodDeclaration) {
        if (member.isStatic) {
          continue;
        }
        // prepare name
        SimpleIdentifier name = member.name;
        if (name == null) {
          continue;
        }
        bool addThisMemberToTheMap = true;
        bool isGetter = member.isGetter;
        bool isSetter = member.isSetter;
        bool isOperator = member.isOperator;
        bool isMethod = !isGetter && !isSetter && !isOperator;
        // Do lookups in the enclosing class (and the inherited member) if the
        // member is a method or a setter for
        // StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER warning.
        if (isMethod) {
          String setterName = "${name.name}=";
          Element enclosingElementOfSetter = null;
          ClassMember conflictingSetter = memberHashMap[setterName];
          if (conflictingSetter != null) {
            enclosingElementOfSetter = resolutionMap
                .elementDeclaredByDeclaration(conflictingSetter)
                .enclosingElement;
          } else {
            ExecutableElement elementFromInheritance = _inheritanceManager
                .lookupInheritance(_enclosingClass, setterName);
            if (elementFromInheritance != null) {
              enclosingElementOfSetter =
                  elementFromInheritance.enclosingElement;
            }
          }
          if (enclosingElementOfSetter != null) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER, name, [
              _enclosingClass.displayName,
              name.name,
              enclosingElementOfSetter.displayName
            ]);
            addThisMemberToTheMap = false;
          }
        } else if (isSetter) {
          String methodName = name.name;
          ClassMember conflictingMethod = memberHashMap[methodName];
          if (conflictingMethod != null &&
              conflictingMethod is MethodDeclaration &&
              !conflictingMethod.isGetter) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER2,
                name,
                [_enclosingClass.displayName, name.name]);
            addThisMemberToTheMap = false;
          }
        }
        // Finally, add this member into the HashMap.
        if (addThisMemberToTheMap) {
          if (member.isSetter) {
            memberHashMap["${name.name}="] = member;
          } else {
            memberHashMap[name.name] = member;
          }
        }
      }
    }
  }

  /**
   * Verify that the enclosing class does not have an instance member with the
   * same name as the given static [method] declaration.
   *
   * See [StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER].
   */
  void _checkForConflictingStaticGetterAndInstanceSetter(
      MethodDeclaration method) {
    if (!method.isStatic) {
      return;
    }
    // prepare name
    SimpleIdentifier nameNode = method.name;
    if (nameNode == null) {
      return;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // try to find setter
    ExecutableElement setter =
        enclosingType.lookUpSetter(name, _currentLibrary);
    if (setter == null) {
      return;
    }
    // OK, also static
    if (setter.isStatic) {
      return;
    }
    // prepare "setter" type to report its name
    ClassElement setterClass = setter.enclosingElement as ClassElement;
    InterfaceType setterType = setterClass.type;

    _errorReporter.reportErrorForNode(
        StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER,
        nameNode,
        [setterType.displayName]);
  }

  /**
   * Verify that the enclosing class does not have an instance member with the
   * same name as the given static [method] declaration.
   *
   * See [StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER].
   */
  void _checkForConflictingStaticSetterAndInstanceMember(
      MethodDeclaration method) {
    if (!method.isStatic) {
      return;
    }
    // prepare name
    SimpleIdentifier nameNode = method.name;
    if (nameNode == null) {
      return;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // try to find member
    ExecutableElement member;
    member = enclosingType.lookUpMethod(name, _currentLibrary);
    if (member == null) {
      member = enclosingType.lookUpGetter(name, _currentLibrary);
    }
    if (member == null) {
      member = enclosingType.lookUpSetter(name, _currentLibrary);
    }
    if (member == null) {
      return;
    }
    // OK, also static
    if (member.isStatic) {
      return;
    }
    // prepare "member" type to report its name
    ClassElement memberClass = member.enclosingElement as ClassElement;
    InterfaceType memberType = memberClass.type;

    _errorReporter.reportErrorForNode(
        StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER,
        nameNode,
        [memberType.displayName]);
  }

  /**
   * Verify all conflicts between type variable and enclosing class.
   * TODO(scheglov)
   *
   * See [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS], and
   * [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER].
   */
  void _checkForConflictingTypeVariableErrorCodes(
      ClassDeclaration declaration) {
    for (TypeParameterElement typeParameter in _enclosingClass.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingClass.name == name) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS,
            typeParameter,
            [name]);
      }
      // check members
      if (_enclosingClass.getMethod(name) != null ||
          _enclosingClass.getGetter(name) != null ||
          _enclosingClass.getSetter(name) != null) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
            typeParameter,
            [name]);
      }
    }
  }

  /**
   * Verify that if the given [constructor] declaration is 'const' then there
   * are no invocations of non-'const' super constructors.
   *
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER].
   */
  void _checkForConstConstructorWithNonConstSuper(
      ConstructorDeclaration constructor) {
    if (!_isEnclosingConstructorConst) {
      return;
    }
    // OK, const factory, checked elsewhere
    if (constructor.factoryKeyword != null) {
      return;
    }
    // check for mixins
    if (_enclosingClass.mixins.length != 0) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN,
          constructor.returnType);
      return;
    }
    // try to find and check super constructor invocation
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is SuperConstructorInvocation) {
        ConstructorElement element = initializer.staticElement;
        if (element == null || element.isConst) {
          return;
        }
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
            initializer,
            [element.enclosingElement.displayName]);
        return;
      }
    }
    // no explicit super constructor invocation, check default constructor
    InterfaceType supertype = _enclosingClass.supertype;
    if (supertype == null) {
      return;
    }
    if (supertype.isObject) {
      return;
    }
    ConstructorElement unnamedConstructor =
        supertype.element.unnamedConstructor;
    if (unnamedConstructor == null || unnamedConstructor.isConst) {
      return;
    }

    // default constructor is not 'const', report problem
    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
        constructor.returnType,
        [supertype.displayName]);
  }

  /**
   * Verify that if the given [constructor] declaration is 'const' then there
   * are no non-final instance variable. The [constructorElement] is the
   * constructor element.
   *
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD].
   */
  void _checkForConstConstructorWithNonFinalField(
      ConstructorDeclaration constructor,
      ConstructorElement constructorElement) {
    if (!_isEnclosingConstructorConst) {
      return;
    }
    // check if there is non-final field
    ClassElement classElement = constructorElement.enclosingElement;
    if (!classElement.hasNonFinalField) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
        constructor);
  }

  /**
   * Verify that the given 'const' instance creation [expression] is not
   * creating a deferred type. The [constructorName] is the constructor name,
   * always non-`null`. The [typeName] is the name of the type defining the
   * constructor, always non-`null`.
   *
   * See [CompileTimeErrorCode.CONST_DEFERRED_CLASS].
   */
  void _checkForConstDeferredClass(InstanceCreationExpression expression,
      ConstructorName constructorName, TypeName typeName) {
    if (typeName.isDeferred) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_DEFERRED_CLASS,
          constructorName,
          [typeName.name.name]);
    }
  }

  /**
   * Verify that the given throw [expression] is not enclosed in a 'const'
   * constructor declaration.
   *
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION].
   */
  void _checkForConstEvalThrowsException(ThrowExpression expression) {
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, expression);
    }
  }

  /**
   * Verify that the given normal formal [parameter] is not 'const'.
   *
   * See [CompileTimeErrorCode.CONST_FORMAL_PARAMETER].
   */
  void _checkForConstFormalParameter(NormalFormalParameter parameter) {
    if (parameter.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_FORMAL_PARAMETER, parameter);
    }
  }

  /**
   * Verify that the given instance creation [expression] is not being invoked
   * on an abstract class. The [typeName] is the [TypeName] of the
   * [ConstructorName] from the [InstanceCreationExpression], this is the AST
   * node that the error is attached to. The [type] is the type being
   * constructed with this [InstanceCreationExpression].
   *
   * See [StaticWarningCode.CONST_WITH_ABSTRACT_CLASS], and
   * [StaticWarningCode.NEW_WITH_ABSTRACT_CLASS].
   */
  void _checkForConstOrNewWithAbstractClass(
      InstanceCreationExpression expression,
      TypeName typeName,
      InterfaceType type) {
    if (type.element.isAbstract) {
      ConstructorElement element = expression.staticElement;
      if (element != null && !element.isFactory) {
        if (expression.keyword.keyword == Keyword.CONST) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, typeName);
        } else {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, typeName);
        }
      }
    }
  }

  /**
   * Verify that the given instance creation [expression] is not being invoked
   * on an enum. The [typeName] is the [TypeName] of the [ConstructorName] from
   * the [InstanceCreationExpression], this is the AST node that the error is
   * attached to. The [type] is the type being constructed with this
   * [InstanceCreationExpression].
   *
   * See [CompileTimeErrorCode.INSTANTIATE_ENUM].
   */
  void _checkForConstOrNewWithEnum(InstanceCreationExpression expression,
      TypeName typeName, InterfaceType type) {
    if (type.element.isEnum) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANTIATE_ENUM, typeName);
    }
  }

  /**
   * Verify that the given 'const' instance creation [expression] is not being
   * invoked on a constructor that is not 'const'.
   *
   * This method assumes that the instance creation was tested to be 'const'
   * before being called.
   *
   * See [CompileTimeErrorCode.CONST_WITH_NON_CONST].
   */
  void _checkForConstWithNonConst(InstanceCreationExpression expression) {
    ConstructorElement constructorElement = expression.staticElement;
    if (constructorElement != null && !constructorElement.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_NON_CONST, expression);
    }
  }

  /**
   * Verify that the given [type] does not reference any type parameters.
   *
   * See [CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS].
   */
  void _checkForConstWithTypeParameters(TypeAnnotation type) {
    // something wrong with AST
    if (type is! TypeName) {
      return;
    }
    TypeName typeName = type;
    Identifier name = typeName.name;
    if (name == null) {
      return;
    }
    // should not be a type parameter
    if (name.staticElement is TypeParameterElement) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, name);
    }
    // check type arguments
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      for (TypeAnnotation argument in typeArguments.arguments) {
        _checkForConstWithTypeParameters(argument);
      }
    }
  }

  /**
   * Verify that if the given 'const' instance creation [expression] is being
   * invoked on the resolved constructor. The [constructorName] is the
   * constructor name, always non-`null`. The [typeName] is the name of the type
   * defining the constructor, always non-`null`.
   *
   * This method assumes that the instance creation was tested to be 'const'
   * before being called.
   *
   * See [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR], and
   * [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT].
   */
  void _checkForConstWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      TypeName typeName) {
    // OK if resolved
    if (expression.staticElement != null) {
      return;
    }
    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element != null && element.isEnum) {
        // We have already reported the error.
        return;
      }
    }
    Identifier className = typeName.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR,
          name,
          [className, name]);
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          constructorName,
          [className]);
    }
  }

  /**
   * Verify that there are no default parameters in the given function type
   * [alias].
   *
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS].
   */
  void _checkForDefaultValueInFunctionTypeAlias(FunctionTypeAlias alias) {
    FormalParameterList formalParameterList = alias.parameters;
    NodeList<FormalParameter> parameters = formalParameterList.parameters;
    for (FormalParameter parameter in parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.defaultValue != null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, alias);
        }
      }
    }
  }

  /**
   * Verify that the given default formal [parameter] is not part of a function
   * typed parameter.
   *
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER].
   */
  void _checkForDefaultValueInFunctionTypedParameter(
      DefaultFormalParameter parameter) {
    // OK, not in a function typed parameter.
    if (!_isInFunctionTypedFormalParameter) {
      return;
    }
    // OK, no default value.
    if (parameter.defaultValue == null) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER,
        parameter);
  }

  /**
   * Verify that any deferred imports in the given compilation [unit] have a
   * unique prefix.
   *
   * See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
   */
  void _checkForDeferredPrefixCollisions(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int count = directives.length;
    if (count > 0) {
      HashMap<PrefixElement, List<ImportDirective>> prefixToDirectivesMap =
          new HashMap<PrefixElement, List<ImportDirective>>();
      for (int i = 0; i < count; i++) {
        Directive directive = directives[i];
        if (directive is ImportDirective) {
          SimpleIdentifier prefix = directive.prefix;
          if (prefix != null) {
            Element element = prefix.staticElement;
            if (element is PrefixElement) {
              List<ImportDirective> elements = prefixToDirectivesMap[element];
              if (elements == null) {
                elements = new List<ImportDirective>();
                prefixToDirectivesMap[element] = elements;
              }
              elements.add(directive);
            }
          }
        }
      }
      for (List<ImportDirective> imports in prefixToDirectivesMap.values) {
        _checkDeferredPrefixCollision(imports);
      }
    }
  }

  /**
   * Verify that the enclosing class does not have an instance member with the
   * given name of the static member.
   *
   * See [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE].
   */
  void _checkForDuplicateDefinitionInheritance() {
    if (_enclosingClass == null) {
      return;
    }

    for (ExecutableElement member in _enclosingClass.methods) {
      if (member.isStatic) {
        _checkForDuplicateDefinitionOfMember(member);
      }
    }
    for (ExecutableElement member in _enclosingClass.accessors) {
      if (member.isStatic) {
        _checkForDuplicateDefinitionOfMember(member);
      }
    }
  }

  /**
   * Verify that the enclosing class does not have an instance member with the
   * given name of the [staticMember].
   *
   * See [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE].
   */
  void _checkForDuplicateDefinitionOfMember(ExecutableElement staticMember) {
    // prepare name
    String name = staticMember.name;
    if (name == null) {
      return;
    }
    // try to find member
    ExecutableElement inheritedMember =
        _inheritanceManager.lookupInheritance(_enclosingClass, name);
    if (inheritedMember == null) {
      return;
    }
    // OK, also static
    if (inheritedMember.isStatic) {
      return;
    }
    // determine the display name, use the extended display name if the
    // enclosing class of the inherited member is in a different source
    String displayName;
    Element enclosingElement = inheritedMember.enclosingElement;
    if (enclosingElement.source == _enclosingClass.source) {
      displayName = enclosingElement.displayName;
    } else {
      displayName = enclosingElement.getExtendedDisplayName(null);
    }

    _errorReporter.reportErrorForElement(
        CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE,
        staticMember,
        [name, displayName]);
  }

  /**
   * Verify that if the given list [literal] has type arguments then there is
   * exactly one. The [typeArguments] are the type arguments.
   *
   * See [StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS].
   */
  void _checkForExpectedOneListTypeArgument(
      ListLiteral literal, TypeArgumentList typeArguments) {
    // check number of type arguments
    int num = typeArguments.arguments.length;
    if (num != 1) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS,
          typeArguments,
          [num]);
    }
  }

  /**
   * Verify that the given export [directive] has a unique name among other
   * exported libraries. The [exportElement] is the [ExportElement] retrieved
   * from the node, if the element in the node was `null`, then this method is
   * not called. The [exportedLibrary] is the library element containing the
   * exported element.
   *
   * See [CompileTimeErrorCode.EXPORT_DUPLICATED_LIBRARY_NAME].
   */
  void _checkForExportDuplicateLibraryName(ExportDirective directive,
      ExportElement exportElement, LibraryElement exportedLibrary) {
    if (exportedLibrary == null) {
      return;
    }
    String name = exportedLibrary.name;
    // check if there is other exported library with the same name
    LibraryElement prevLibrary = _nameToExportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != exportedLibrary) {
        if (!name.isEmpty) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED, directive, [
            prevLibrary.definingCompilationUnit.displayName,
            exportedLibrary.definingCompilationUnit.displayName,
            name
          ]);
        }
        return;
      }
    } else {
      _nameToExportElement[name] = exportedLibrary;
    }
  }

  /**
   * Check that if the visiting library is not system, then any given library
   * should not be SDK internal library. The [exportElement] is the
   * [ExportElement] retrieved from the node, if the element in the node was
   * `null`, then this method is not called.
   *
   * See [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY].
   */
  void _checkForExportInternalLibrary(
      ExportDirective directive, ExportElement exportElement) {
    if (_isInSystemLibrary) {
      return;
    }

    LibraryElement exportedLibrary = exportElement.exportedLibrary;
    if (exportedLibrary == null) {
      return;
    }

    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = exportedLibrary.source.uri.toString();
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return;
    }
    if (!sdkLibrary.isInternal) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY,
        directive,
        [directive.uri]);
  }

  /**
   * Verify that the given extends [clause] does not extend a deferred class.
   *
   * See [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS].
   */
  void _checkForExtendsDeferredClass(TypeName superclass) {
    if (superclass == null) {
      return;
    }
    _checkForExtendsOrImplementsDeferredClass(
        superclass, CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS);
  }

  /**
   * Verify that the given extends [clause] does not extend classes such as
   * 'num' or 'String'.
   *
   * See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
   */
  bool _checkForExtendsDisallowedClass(TypeName superclass) {
    if (superclass == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(
        superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /**
   * Verify that the given [typeName] does not extend, implement or mixin
   * classes that are deferred.
   *
   * See [_checkForExtendsDeferredClass],
   * [_checkForExtendsDeferredClassInTypeAlias],
   * [_checkForImplementsDeferredClass],
   * [_checkForAllMixinErrorCodes],
   * [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS],
   * [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS], and
   * [CompileTimeErrorCode.MIXIN_DEFERRED_CLASS].
   */
  bool _checkForExtendsOrImplementsDeferredClass(
      TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }
    if (typeName.isDeferred) {
      _errorReporter
          .reportErrorForNode(errorCode, typeName, [typeName.name.name]);
      return true;
    }
    return false;
  }

  /**
   * Verify that the given [typeName] does not extend, implement or mixin
   * classes such as 'num' or 'String'.
   *
   * See [_checkForExtendsDisallowedClass],
   * [_checkForExtendsDisallowedClassInTypeAlias],
   * [_checkForImplementsDisallowedClass],
   * [_checkForAllMixinErrorCodes],
   * [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS],
   * [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS], and
   * [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS].
   */
  bool _checkForExtendsOrImplementsDisallowedClass(
      TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }
    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (_currentLibrary.source.isInSystemLibrary) {
      return false;
    }
    DartType superType = typeName.type;
    for (InterfaceType disallowedType
        in _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT) {
      if (superType != null && superType == disallowedType) {
        // if the violating type happens to be 'num', we need to rule out the
        // case where the enclosing class is 'int' or 'double'
        if (superType == _typeProvider.numType) {
          AstNode grandParent = typeName.parent.parent;
          // Note: this is a corner case that won't happen often, so adding a
          // field currentClass (see currentFunction) to ErrorVerifier isn't
          // worth if for this case, but if the field currentClass is added,
          // then this message should become a todo to not lookup the
          // grandparent node.
          if (grandParent is ClassDeclaration) {
            ClassElement classElement = grandParent.element;
            DartType classType = classElement.type;
            if (classType != null &&
                (classType == _intType ||
                    classType == _typeProvider.doubleType)) {
              return false;
            }
          }
        }
        // otherwise, report the error
        _errorReporter.reportErrorForNode(
            errorCode, typeName, [disallowedType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * Verify that the given constructor field [initializer] has compatible field
   * and initializer expression types. The [fieldElement] is the static element
   * from the name in the [ConstructorFieldInitializer].
   *
   * See [CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE], and
   * [StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE].
   */
  void _checkForFieldInitializerNotAssignable(
      ConstructorFieldInitializer initializer, FieldElement fieldElement) {
    // prepare field type
    DartType fieldType = fieldElement.type;
    // prepare expression type
    Expression expression = initializer.expression;
    if (expression == null) {
      return;
    }
    // test the static type of the expression
    DartType staticType = getStaticType(expression);
    if (staticType == null) {
      return;
    }
    if (_expressionIsAssignableAtType(expression, staticType, fieldType)) {
      return;
    }
    // report problem
    if (_isEnclosingConstructorConst) {
      // TODO(paulberry): this error should be based on the actual type of the
      // constant, not the static type.  See dartbug.com/21119.
      _errorReporter.reportTypeErrorForNode(
          CheckedModeCompileTimeErrorCode
              .CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
          expression,
          [staticType, fieldType]);
    }
    _errorReporter.reportTypeErrorForNode(
        StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
        expression,
        [staticType, fieldType]);
    // TODO(brianwilkerson) Define a hint corresponding to these errors and
    // report it if appropriate.
//        // test the propagated type of the expression
//        Type propagatedType = expression.getPropagatedType();
//        if (propagatedType != null && propagatedType.isAssignableTo(fieldType)) {
//          return false;
//        }
//        // report problem
//        if (isEnclosingConstructorConst) {
//          errorReporter.reportTypeErrorForNode(
//              CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
//              expression,
//              propagatedType == null ? staticType : propagatedType,
//              fieldType);
//        } else {
//          errorReporter.reportTypeErrorForNode(
//              StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
//              expression,
//              propagatedType == null ? staticType : propagatedType,
//              fieldType);
//        }
//        return true;
  }

  /**
   * Verify that the given field formal [parameter] is in a constructor
   * declaration.
   *
   * See [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR].
   */
  void _checkForFieldInitializingFormalRedirectingConstructor(
      FieldFormalParameter parameter) {
    // prepare the node that should be a ConstructorDeclaration
    AstNode formalParameterList = parameter.parent;
    if (formalParameterList is! FormalParameterList) {
      formalParameterList = formalParameterList?.parent;
    }
    AstNode constructor = formalParameterList?.parent;
    // now check whether the node is actually a ConstructorDeclaration
    if (constructor is ConstructorDeclaration) {
      // constructor cannot be a factory
      if (constructor.factoryKeyword != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR,
            parameter);
        return;
      }
      // constructor cannot have a redirection
      for (ConstructorInitializer initializer in constructor.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
              parameter);
          return;
        }
      }
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
          parameter);
    }
  }

  /**
   * Verify that the given variable declaration [list] has only initialized
   * variables if the list is final or const.
   *
   * See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
   * [StaticWarningCode.FINAL_NOT_INITIALIZED].
   */
  void _checkForFinalNotInitialized(VariableDeclarationList list) {
    if (_isInNativeClass || list.isSynthetic) {
      return;
    }
    bool isConst = list.isConst;
    if (!(isConst || list.isFinal)) {
      return;
    }
    NodeList<VariableDeclaration> variables = list.variables;
    for (VariableDeclaration variable in variables) {
      if (variable.initializer == null) {
        if (isConst) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              variable.name,
              [variable.name.name]);
        } else {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.FINAL_NOT_INITIALIZED,
              variable.name,
              [variable.name.name]);
        }
      }
    }
  }

  /**
   * Verify that final fields in the given class [declaration] that are
   * declared, without any constructors in the enclosing class, are
   * initialized. Cases in which there is at least one constructor are handled
   * at the end of
   * [_checkForAllFinalInitializedErrorCodes].
   *
   * See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
   * [StaticWarningCode.FINAL_NOT_INITIALIZED].
   */
  void _checkForFinalNotInitializedInClass(ClassDeclaration declaration) {
    NodeList<ClassMember> classMembers = declaration.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is ConstructorDeclaration) {
        return;
      }
    }
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration) {
        _checkForFinalNotInitialized(classMember.fields);
      }
    }
  }

  /**
   * If the current function is async, async*, or sync*, verify that its
   * declared return type is assignable to Future, Stream, or Iterable,
   * respectively.  If not, report the error using [returnType].
   */
  void _checkForIllegalReturnType(TypeAnnotation returnType) {
    if (returnType == null) {
      // No declared return type, so the return type must be dynamic, which is
      // assignable to everything.
      return;
    }
    if (_enclosingFunction.isAsynchronous) {
      if (_enclosingFunction.isGenerator) {
        _checkForIllegalReturnTypeCode(
            returnType,
            _typeProvider.streamDynamicType,
            StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE);
      } else {
        _checkForIllegalReturnTypeCode(
            returnType,
            _typeProvider.futureDynamicType,
            StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE);
      }
    } else if (_enclosingFunction.isGenerator) {
      _checkForIllegalReturnTypeCode(
          returnType,
          _typeProvider.iterableDynamicType,
          StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE);
    }
  }

  /**
   * If the current function is async, async*, or sync*, verify that its
   * declared return type is assignable to Future, Stream, or Iterable,
   * respectively. This is called by [_checkForIllegalReturnType] to check if
   * the declared [returnTypeName] is assignable to the required [expectedType]
   * and if not report [errorCode].
   */
  void _checkForIllegalReturnTypeCode(TypeAnnotation returnTypeName,
      DartType expectedType, StaticTypeWarningCode errorCode) {
    DartType returnType = _enclosingFunction.returnType;
    if (_options.strongMode) {
      //
      // When checking an async/sync*/async* method, we know the exact type
      // that will be returned (e.g. Future, Iterable, or Stream).
      //
      // For example an `async` function body will return a `Future<T>` for
      // some `T` (possibly `dynamic`).
      //
      // We allow the declared return type to be a supertype of that
      // (e.g. `dynamic`, `Object`), or Future<S> for some S.
      // (We assume the T <: S relation is checked elsewhere.)
      //
      // We do not allow user-defined subtypes of Future, because an `async`
      // method will never return those.
      //
      // To check for this, we ensure that `Future<bottom> <: returnType`.
      //
      // Similar logic applies for sync* and async*.
      //
      InterfaceType genericType = (expectedType.element as ClassElement).type;
      DartType lowerBound = genericType.instantiate([BottomTypeImpl.instance]);
      if (!_typeSystem.isSubtypeOf(lowerBound, returnType)) {
        _errorReporter.reportErrorForNode(errorCode, returnTypeName);
      }
    } else if (!_typeSystem.isAssignableTo(returnType, expectedType)) {
      _errorReporter.reportErrorForNode(errorCode, returnTypeName);
    }
  }

  /**
   * Verify that the given implements [clause] does not implement classes that
   * are deferred.
   *
   * See [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS].
   */
  void _checkForImplementsDeferredClass(ImplementsClause clause) {
    if (clause == null) {
      return;
    }
    for (TypeName type in clause.interfaces) {
      _checkForExtendsOrImplementsDeferredClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS);
    }
  }

  /**
   * Verify that the given implements [clause] does not implement classes such
   * as 'num' or 'String'.
   *
   * See [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS].
   */
  bool _checkForImplementsDisallowedClass(ImplementsClause clause) {
    if (clause == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in clause.interfaces) {
      if (_checkForExtendsOrImplementsDisallowedClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS)) {
        foundError = true;
      }
    }
    return foundError;
  }

  void _checkForImplicitDynamicIdentifier(AstNode node, Identifier id) {
    if (_options.implicitDynamic) {
      return;
    }
    VariableElement variable = getVariableElement(id);
    if (variable != null &&
        variable.hasImplicitType &&
        variable.type.isDynamic) {
      ErrorCode errorCode;
      if (variable is FieldElement) {
        errorCode = StrongModeCode.IMPLICIT_DYNAMIC_FIELD;
      } else if (variable is ParameterElement) {
        errorCode = StrongModeCode.IMPLICIT_DYNAMIC_PARAMETER;
      } else {
        errorCode = StrongModeCode.IMPLICIT_DYNAMIC_VARIABLE;
      }
      _errorReporter.reportErrorForNode(errorCode, node, [id]);
    }
  }

  void _checkForImplicitDynamicInvoke(InvocationExpression node) {
    if (_options.implicitDynamic ||
        node == null ||
        node.typeArguments != null) {
      return;
    }
    DartType invokeType = node.staticInvokeType;
    DartType declaredType = node.function.staticType;
    if (invokeType is FunctionType &&
        declaredType is FunctionType &&
        declaredType.typeFormals.isNotEmpty) {
      Iterable<DartType> typeArgs =
          FunctionTypeImpl.recoverTypeArguments(declaredType, invokeType);
      if (typeArgs.any((t) => t.isDynamic)) {
        // Issue an error depending on what we're trying to call.
        Expression function = node.function;
        if (function is Identifier) {
          Element element = function.staticElement;
          if (element is MethodElement) {
            _errorReporter.reportErrorForNode(
                StrongModeCode.IMPLICIT_DYNAMIC_METHOD,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }

          if (element is FunctionElement) {
            _errorReporter.reportErrorForNode(
                StrongModeCode.IMPLICIT_DYNAMIC_FUNCTION,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }
        }

        // The catch all case if neither of those matched.
        // For example, invoking a function expression.
        _errorReporter.reportErrorForNode(
            StrongModeCode.IMPLICIT_DYNAMIC_INVOKE,
            node.function,
            [declaredType]);
      }
    }
  }

  void _checkForImplicitDynamicReturn(
      AstNode functionName, ExecutableElement element) {
    if (_options.implicitDynamic) {
      return;
    }
    if (element is PropertyAccessorElement && element.isSetter) {
      return;
    }
    if (element != null &&
        element.hasImplicitReturnType &&
        element.returnType.isDynamic) {
      _errorReporter.reportErrorForNode(StrongModeCode.IMPLICIT_DYNAMIC_RETURN,
          functionName, [element.displayName]);
    }
  }

  void _checkForImplicitDynamicType(TypeAnnotation node) {
    if (_options.implicitDynamic ||
        node == null ||
        (node is TypeName && node.typeArguments != null)) {
      return;
    }
    DartType type = node.type;
    if (type is ParameterizedType &&
        type.typeArguments.isNotEmpty &&
        type.typeArguments.any((t) => t.isDynamic)) {
      _errorReporter.reportErrorForNode(
          StrongModeCode.IMPLICIT_DYNAMIC_TYPE, node, [type]);
    }
  }

  void _checkForImplicitDynamicTypedLiteral(TypedLiteral node) {
    if (_options.implicitDynamic || node.typeArguments != null) {
      return;
    }
    DartType type = node.staticType;
    // It's an error if either the key or value was inferred as dynamic.
    if (type is InterfaceType && type.typeArguments.any((t) => t.isDynamic)) {
      ErrorCode errorCode = node is ListLiteral
          ? StrongModeCode.IMPLICIT_DYNAMIC_LIST_LITERAL
          : StrongModeCode.IMPLICIT_DYNAMIC_MAP_LITERAL;
      _errorReporter.reportErrorForNode(errorCode, node);
    }
  }

  /**
   * Verify that if the given [identifier] is part of a constructor initializer,
   * then it does not implicitly reference 'this' expression.
   *
   * See [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER], and
   * [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC].
   * TODO(scheglov) rename thid method
   */
  void _checkForImplicitThisReferenceInInitializer(
      SimpleIdentifier identifier) {
    if (!_isInConstructorInitializer &&
        !_isInStaticMethod &&
        !_isInFactory &&
        !_isInInstanceVariableInitializer &&
        !_isInStaticVariableDeclaration) {
      return;
    }
    // prepare element
    Element element = identifier.staticElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return;
    }
    // static element
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic) {
      return;
    }
    // not a class member
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return;
    }
    // comment
    AstNode parent = identifier.parent;
    if (parent is CommentReference) {
      return;
    }
    // qualified method invocation
    if (parent is MethodInvocation) {
      if (identical(parent.methodName, identifier) &&
          parent.realTarget != null) {
        return;
      }
    }
    // qualified property access
    if (parent is PropertyAccess) {
      if (identical(parent.propertyName, identifier) &&
          parent.realTarget != null) {
        return;
      }
    }
    if (parent is PrefixedIdentifier) {
      if (identical(parent.identifier, identifier)) {
        return;
      }
    }

    if (_isInStaticMethod) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, identifier);
    } else if (_isInFactory) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, identifier);
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
          identifier);
    }
  }

  /**
   * Verify that the given import [directive] has a unique name among other
   * imported libraries. The [importElement] is the [ImportElement] retrieved
   * from the node, if the element in the node was `null`, then this method is
   * not called.
   *
   * See [CompileTimeErrorCode.IMPORT_DUPLICATED_LIBRARY_NAME].
   */
  void _checkForImportDuplicateLibraryName(
      ImportDirective directive, ImportElement importElement) {
    // prepare imported library
    LibraryElement nodeLibrary = importElement.importedLibrary;
    if (nodeLibrary == null) {
      return;
    }
    String name = nodeLibrary.name;
    // check if there is another imported library with the same name
    LibraryElement prevLibrary = _nameToImportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary && !name.isEmpty) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED, directive, [
          prevLibrary.definingCompilationUnit.displayName,
          nodeLibrary.definingCompilationUnit.displayName,
          name
        ]);
      }
    } else {
      _nameToImportElement[name] = nodeLibrary;
    }
  }

  /**
   * Check that if the visiting library is not system, then any given library
   * should not be SDK internal library. The [importElement] is the
   * [ImportElement] retrieved from the node, if the element in the node was
   * `null`, then this method is not called
   *
   * See [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY].
   */
  void _checkForImportInternalLibrary(
      ImportDirective directive, ImportElement importElement) {
    if (_isInSystemLibrary) {
      return;
    }

    LibraryElement importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null) {
      return;
    }

    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = importedLibrary.source.uri.toString();
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null || !sdkLibrary.isInternal) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY,
        directive,
        [directive.uri]);
  }

  /**
   * For each class declaration, this method is called which verifies that all
   * inherited members are inherited consistently.
   *
   * See [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE].
   */
  void _checkForInconsistentMethodInheritance() {
    // Ensure that the inheritance manager has a chance to generate all errors
    // we may care about, note that we ensure that the interfaces data since
    // there are no errors.
    _inheritanceManager.getMembersInheritedFromInterfaces(_enclosingClass);
    Set<AnalysisError> errors = _inheritanceManager.getErrors(_enclosingClass);
    if (errors == null || errors.isEmpty) {
      return;
    }
    for (AnalysisError error in errors) {
      _errorReporter.reportError(error);
    }
    return;
  }

  /**
   * Check for a type mis-match between the iterable expression and the
   * assigned variable in a for-in statement.
   */
  void _checkForInIterable(ForEachStatement node) {
    // Ignore malformed for statements.
    if (node.identifier == null && node.loopVariable == null) {
      return;
    }

    DartType iterableType = getStaticType(node.iterable);
    if (iterableType.isDynamic) {
      return;
    }

    // The type of the loop variable.
    SimpleIdentifier variable = node.identifier ?? node.loopVariable.identifier;
    DartType variableType = getStaticType(variable);

    DartType loopType = node.awaitKeyword != null
        ? _typeProvider.streamType
        : _typeProvider.iterableType;

    // Use an explicit string instead of [loopType] to remove the "<E>".
    String loopTypeName = node.awaitKeyword != null ? "Stream" : "Iterable";

    // The object being iterated has to implement Iterable<T> for some T that
    // is assignable to the variable's type.
    // TODO(rnystrom): Move this into mostSpecificTypeArgument()?
    iterableType = iterableType.resolveToBound(_typeProvider.objectType);
    DartType bestIterableType =
        _typeSystem.mostSpecificTypeArgument(iterableType, loopType);

    // Allow it to be a supertype of Iterable<T> (basically just Object) and do
    // an implicit downcast to Iterable<dynamic>.
    if (bestIterableType == null) {
      if (_typeSystem.isSubtypeOf(loopType, iterableType)) {
        bestIterableType = DynamicTypeImpl.instance;
      }
    }

    if (bestIterableType == null) {
      _errorReporter.reportTypeErrorForNode(
          StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE,
          node.iterable,
          [iterableType, loopTypeName]);
    } else if (!_typeSystem.isAssignableTo(bestIterableType, variableType,
        isDeclarationCast: true)) {
      _errorReporter.reportTypeErrorForNode(
          StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
          node.iterable,
          [iterableType, loopTypeName, variableType]);
    }
  }

  /**
   * Check that the given [typeReference] is not a type reference and that then
   * the [name] is reference to an instance member.
   *
   * See [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER].
   */
  void _checkForInstanceAccessToStaticMember(
      ClassElement typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return;
    }
    // OK, target is a type
    if (typeReference != null) {
      return;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is ExecutableElement) {
      // OK, top-level element
      if (element.enclosingElement is! ClassElement) {
        return;
      }
      // OK, instance member
      if (!element.isStatic) {
        return;
      }
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
          name,
          [name.name, _getKind(element), element.enclosingElement.name]);
    }
  }

  /**
   * Check whether the given [executableElement] collides with the name of a
   * static method in one of its superclasses, and reports the appropriate
   * warning if it does. The [errorNameTarget] is the node to report problems
   * on.
   *
   * See [StaticTypeWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC].
   */
  bool _checkForInstanceMethodNameCollidesWithSuperclassStatic(
      ExecutableElement executableElement, SimpleIdentifier errorNameTarget) {
    String executableElementName = executableElement.name;
    if (executableElement is! PropertyAccessorElement &&
        !executableElement.isOperator) {
      HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
      InterfaceType superclassType = _enclosingClass.supertype;
      ClassElement superclassElement = superclassType?.element;
      bool executableElementPrivate =
          Identifier.isPrivateName(executableElementName);
      while (superclassElement != null &&
          !visitedClasses.contains(superclassElement)) {
        visitedClasses.add(superclassElement);
        LibraryElement superclassLibrary = superclassElement.library;
        // Check fields.
        FieldElement fieldElt =
            superclassElement.getField(executableElementName);
        if (fieldElt != null) {
          // Ignore if private in a different library - cannot collide.
          if (executableElementPrivate &&
              _currentLibrary != superclassLibrary) {
            continue;
          }
          // instance vs. static
          if (fieldElt.isStatic) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode
                    .INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC,
                errorNameTarget,
                [executableElementName, fieldElt.enclosingElement.displayName]);
            return true;
          }
        }
        // Check methods.
        List<MethodElement> methodElements = superclassElement.methods;
        int length = methodElements.length;
        for (int i = 0; i < length; i++) {
          MethodElement methodElement = methodElements[i];
          // We need the same name.
          if (methodElement.name != executableElementName) {
            continue;
          }
          // Ignore if private in a different library - cannot collide.
          if (executableElementPrivate &&
              _currentLibrary != superclassLibrary) {
            continue;
          }
          // instance vs. static
          if (methodElement.isStatic) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode
                    .INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC,
                errorNameTarget,
                [
                  executableElementName,
                  methodElement.enclosingElement.displayName
                ]);
            return true;
          }
        }
        superclassType = superclassElement.supertype;
        superclassElement = superclassType?.element;
      }
    }
    return false;
  }

  /**
   * Verify that an 'int' can be assigned to the parameter corresponding to the
   * given [argument]. This is used for prefix and postfix expressions where
   * the argument value is implicit.
   *
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForIntNotAssignable(Expression argument) {
    if (argument == null) {
      return;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    DartType staticParameterType = staticParameterElement?.type;
    _checkForArgumentTypeNotAssignable(argument, staticParameterType, _intType,
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * Verify that the given [annotation] isn't defined in a deferred library.
   *
   * See [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
   */
  void _checkForInvalidAnnotationFromDeferredLibrary(Annotation annotation) {
    Identifier nameIdentifier = annotation.name;
    if (nameIdentifier is PrefixedIdentifier && nameIdentifier.isDeferred) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY,
          annotation.name);
    }
  }

  /**
   * Verify that the given left hand side ([lhs]) and right hand side ([rhs])
   * represent a valid assignment.
   *
   * See [StaticTypeWarningCode.INVALID_ASSIGNMENT].
   */
  void _checkForInvalidAssignment(Expression lhs, Expression rhs,
      {bool isDeclarationCast = false}) {
    if (lhs == null || rhs == null) {
      return;
    }
    VariableElement leftVariableElement = getVariableElement(lhs);
    DartType leftType = (leftVariableElement == null)
        ? getStaticType(lhs)
        : leftVariableElement.type;
    _checkForAssignableExpression(
        rhs, leftType, StaticTypeWarningCode.INVALID_ASSIGNMENT,
        isDeclarationCast: isDeclarationCast);
  }

  /**
   * Given an [assignment] using a compound assignment operator, this verifies
   * that the given assignment is valid. The [lhs] is the left hand side
   * expression. The [rhs] is the right hand side expression.
   *
   * See [StaticTypeWarningCode.INVALID_ASSIGNMENT].
   */
  void _checkForInvalidCompoundAssignment(
      AssignmentExpression assignment, Expression lhs, Expression rhs) {
    if (lhs == null) {
      return;
    }
    DartType leftType = getStaticType(lhs);
    DartType rightType = getStaticType(assignment);
    if (!_typeSystem.isAssignableTo(rightType, leftType)) {
      _errorReporter.reportTypeErrorForNode(
          StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [rightType, leftType]);
    }
  }

  /**
   * Check the given [initializer] to ensure that the field being initialized is
   * a valid field. The [fieldName] is the field name from the
   * [ConstructorFieldInitializer]. The [staticElement] is the static element
   * from the name in the [ConstructorFieldInitializer].
   */
  void _checkForInvalidField(ConstructorFieldInitializer initializer,
      SimpleIdentifier fieldName, Element staticElement) {
    if (staticElement is FieldElement) {
      if (staticElement.isSynthetic) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
            initializer,
            [fieldName]);
      } else if (staticElement.isStatic) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
            initializer,
            [fieldName]);
      }
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
          initializer,
          [fieldName]);
      return;
    }
  }

  /**
   * Check to see whether the given function [body] has a modifier associated
   * with it, and report it as an error if it does.
   */
  void _checkForInvalidModifierOnBody(
      FunctionBody body, CompileTimeErrorCode errorCode) {
    Token keyword = body.keyword;
    if (keyword != null) {
      _errorReporter.reportErrorForToken(errorCode, keyword, [keyword.lexeme]);
    }
  }

  /**
   * Verify that the usage of the given 'this' is valid.
   *
   * See [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS].
   */
  void _checkForInvalidReferenceToThis(ThisExpression expression) {
    if (!_isThisInValidContext(expression)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, expression);
    }
  }

  /**
   * Checks to ensure that the given list of type [arguments] does not have a
   * type parameter as a type argument. The [errorCode] is either
   * [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST] or
   * [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP].
   */
  void _checkForInvalidTypeArgumentInConstTypedLiteral(
      NodeList<TypeAnnotation> arguments, ErrorCode errorCode) {
    for (TypeAnnotation type in arguments) {
      if (type is TypeName && type.type is TypeParameterType) {
        _errorReporter.reportErrorForNode(errorCode, type, [type.name]);
      }
    }
  }

  /**
   * Verify that the elements given list [literal] are subtypes of the list's
   * static type.
   *
   * See [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForListElementTypeNotAssignable(ListLiteral literal) {
    // Determine the list's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType listType = literal.staticType;
    assert(listType is InterfaceTypeImpl);

    List<DartType> typeArguments =
        (listType as InterfaceTypeImpl).typeArguments;
    assert(typeArguments.length == 1);

    DartType listElementType = typeArguments[0];

    // Check every list element.
    for (Expression element in literal.elements) {
      if (literal.constKeyword != null) {
        // TODO(paulberry): this error should be based on the actual type of the
        // list element, not the static type.  See dartbug.com/21119.
        _checkForArgumentTypeNotAssignableWithExpectedTypes(
            element,
            listElementType,
            CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE);
      }
      _checkForArgumentTypeNotAssignableWithExpectedTypes(element,
          listElementType, StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE);
    }
  }

  /**
   * Verify that the key/value of entries of the given map [literal] are
   * subtypes of the map's static type.
   *
   * See [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForMapTypeNotAssignable(MapLiteral literal) {
    // Determine the map's key and value types. We base this on the static type
    // and not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType mapType = literal.staticType;
    assert(mapType is InterfaceTypeImpl);

    List<DartType> typeArguments = (mapType as InterfaceTypeImpl).typeArguments;
    assert(typeArguments.length == 2);
    DartType keyType = typeArguments[0];
    DartType valueType = typeArguments[1];

    NodeList<MapLiteralEntry> entries = literal.entries;
    for (MapLiteralEntry entry in entries) {
      Expression key = entry.key;
      Expression value = entry.value;
      if (literal.constKeyword != null) {
        // TODO(paulberry): this error should be based on the actual type of the
        // list element, not the static type.  See dartbug.com/21119.
        _checkForArgumentTypeNotAssignableWithExpectedTypes(key, keyType,
            CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE);
        _checkForArgumentTypeNotAssignableWithExpectedTypes(value, valueType,
            CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE);
      }
      _checkForArgumentTypeNotAssignableWithExpectedTypes(
          key, keyType, StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE);
      _checkForArgumentTypeNotAssignableWithExpectedTypes(
          value, valueType, StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE);
    }
  }

  /**
   * Verify that the [_enclosingClass] does not define members with the same name
   * as the enclosing class.
   *
   * See [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME].
   */
  void _checkForMemberWithClassName() {
    if (_enclosingClass == null) {
      return;
    }
    String className = _enclosingClass.name;
    if (className == null) {
      return;
    }

    // check accessors
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (className == accessor.name) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, accessor);
      }
    }
    // don't check methods, they would be constructors
  }

  /**
   * Check to make sure that all similarly typed accessors are of the same type
   * (including inherited accessors).
   *
   * See [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES], and
   * [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE].
   */
  void _checkForMismatchedAccessorTypes(
      Declaration accessorDeclaration, String accessorTextName) {
    ExecutableElement accessorElement =
        accessorDeclaration.element as ExecutableElement;
    if (accessorElement is PropertyAccessorElement) {
      PropertyAccessorElement counterpartAccessor = null;
      ClassElement enclosingClassForCounterpart = null;
      if (accessorElement.isGetter) {
        counterpartAccessor = accessorElement.correspondingSetter;
      } else {
        counterpartAccessor = accessorElement.correspondingGetter;
        // If the setter and getter are in the same enclosing element, return,
        // this prevents having MISMATCHED_GETTER_AND_SETTER_TYPES reported twice.
        if (counterpartAccessor != null &&
            identical(counterpartAccessor.enclosingElement,
                accessorElement.enclosingElement)) {
          return;
        }
      }
      if (counterpartAccessor == null) {
        // If the accessor is declared in a class, check the superclasses.
        if (_enclosingClass != null) {
          // Figure out the correct identifier to lookup in the inheritance graph,
          // if 'x', then 'x=', or if 'x=', then 'x'.
          String lookupIdentifier = accessorElement.name;
          if (StringUtilities.endsWithChar(lookupIdentifier, 0x3D)) {
            lookupIdentifier =
                lookupIdentifier.substring(0, lookupIdentifier.length - 1);
          } else {
            lookupIdentifier += "=";
          }
          // lookup with the identifier.
          ExecutableElement elementFromInheritance = _inheritanceManager
              .lookupInheritance(_enclosingClass, lookupIdentifier);
          // Verify that we found something, and that it is an accessor
          if (elementFromInheritance != null &&
              elementFromInheritance is PropertyAccessorElement) {
            enclosingClassForCounterpart =
                elementFromInheritance.enclosingElement as ClassElement;
            counterpartAccessor = elementFromInheritance;
          }
        }
        if (counterpartAccessor == null) {
          return;
        }
      }
      // Default of null == no accessor or no type (dynamic)
      DartType getterType = null;
      DartType setterType = null;
      // Get an existing counterpart accessor if any.
      if (accessorElement.isGetter) {
        getterType = _getGetterType(accessorElement);
        setterType = _getSetterType(counterpartAccessor);
      } else if (accessorElement.isSetter) {
        setterType = _getSetterType(accessorElement);
        getterType = _getGetterType(counterpartAccessor);
      }
      // If either types are not assignable to each other, report an error
      // (if the getter is null, it is dynamic which is assignable to everything).
      if (setterType != null &&
          getterType != null &&
          !_typeSystem.isAssignableTo(getterType, setterType)) {
        if (enclosingClassForCounterpart == null) {
          _errorReporter.reportTypeErrorForNode(
              StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
              accessorDeclaration,
              [accessorTextName, setterType, getterType]);
        } else {
          _errorReporter.reportTypeErrorForNode(
              StaticWarningCode
                  .MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE,
              accessorDeclaration,
              [
                accessorTextName,
                setterType,
                getterType,
                enclosingClassForCounterpart.displayName
              ]);
        }
      }
    }
  }

  /**
   * Check to make sure that the given switch [statement] whose static type is
   * an enum type either have a default case or include all of the enum
   * constants.
   */
  void _checkForMissingEnumConstantInSwitch(SwitchStatement statement) {
    // TODO(brianwilkerson) This needs to be checked after constant values have
    // been computed.
    Expression expression = statement.expression;
    DartType expressionType = getStaticType(expression);
    if (expressionType == null) {
      return;
    }
    Element expressionElement = expressionType.element;
    if (expressionElement is ClassElement) {
      if (!expressionElement.isEnum) {
        return;
      }
      List<String> constantNames = <String>[];
      List<FieldElement> fields = expressionElement.fields;
      int fieldCount = fields.length;
      for (int i = 0; i < fieldCount; i++) {
        FieldElement field = fields[i];
        if (field.isStatic && !field.isSynthetic) {
          constantNames.add(field.name);
        }
      }
      NodeList<SwitchMember> members = statement.members;
      int memberCount = members.length;
      for (int i = 0; i < memberCount; i++) {
        SwitchMember member = members[i];
        if (member is SwitchDefault) {
          return;
        }
        String constantName =
            _getConstantName((member as SwitchCase).expression);
        if (constantName != null) {
          constantNames.remove(constantName);
        }
      }
      if (constantNames.isEmpty) {
        return;
      }
      for (int i = 0; i < constantNames.length; i++) {
        int offset = statement.offset;
        int end = statement.rightParenthesis.end;
        _errorReporter.reportErrorForOffset(
            StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
            offset,
            end - offset,
            [constantNames[i]]);
      }
    }
  }

  void _checkForMissingJSLibAnnotation(Annotation node) {
    if (resolutionMap.elementAnnotationForAnnotation(node)?.isJS ?? false) {
      if (_currentLibrary.isJS != true) {
        _errorReporter.reportErrorForNode(
            HintCode.MISSING_JS_LIB_ANNOTATION, node);
      }
    }
  }

  /**
   * Verify that the given function [body] does not contain return statements
   * that both have and do not have return values.
   *
   * See [StaticWarningCode.MIXED_RETURN_TYPES].
   */
  void _checkForMixedReturns(BlockFunctionBody body) {
    if (_hasReturnWithoutValue) {
      return;
    }
    if (_returnsWith.isNotEmpty && _returnsWithout.isNotEmpty) {
      for (ReturnStatement returnWith in _returnsWith) {
        _errorReporter.reportErrorForToken(
            StaticWarningCode.MIXED_RETURN_TYPES, returnWith.returnKeyword);
      }
      for (ReturnStatement returnWithout in _returnsWithout) {
        _errorReporter.reportErrorForToken(
            StaticWarningCode.MIXED_RETURN_TYPES, returnWithout.returnKeyword);
      }
    }
  }

  /**
   * Verify that the given mixin does not have an explicitly declared
   * constructor. The [mixinName] is the node to report problem on. The
   * [mixinElement] is the mixing to evaluate.
   *
   * See [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR].
   */
  bool _checkForMixinDeclaresConstructor(
      TypeName mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR,
            mixinName,
            [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * Report the error [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS] if
   * appropriate.
   */
  void _checkForMixinHasNoConstructors(AstNode node) {
    if (_enclosingClass.doesMixinLackConstructors) {
      ErrorCode errorCode = CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS;
      _errorReporter
          .reportErrorForNode(errorCode, node, [_enclosingClass.supertype]);
    }
  }

  /**
   * Verify that the given mixin has the 'Object' superclass. The [mixinName] is
   * the node to report problem on. The [mixinElement] is the mixing to
   * evaluate.
   *
   * See [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
   */
  bool _checkForMixinInheritsNotFromObject(
      TypeName mixinName, ClassElement mixinElement) {
    InterfaceType mixinSupertype = mixinElement.supertype;
    if (mixinSupertype != null) {
      if (!mixinSupertype.isObject ||
          !mixinElement.isMixinApplication && mixinElement.mixins.length != 0) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT,
            mixinName,
            [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * Verify that the given mixin does not reference 'super'. The [mixinName] is
   * the node to report problem on. The [mixinElement] is the mixing to
   * evaluate.
   *
   * See [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER].
   */
  bool _checkForMixinReferencesSuper(
      TypeName mixinName, ClassElement mixinElement) {
    if (!enableSuperMixins && mixinElement.hasReferenceToSuper) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_REFERENCES_SUPER,
          mixinName,
          [mixinElement.name]);
    }
    return false;
  }

  /**
   * Check for the declaration of a mixin from a library other than the current
   * library that defines a private member that conflicts with a private name
   * from the same library but from a superclass or a different mixin.
   */
  void _checkForMixinWithConflictingPrivateMember(
      WithClause withClause, TypeName superclassName) {
    if (withClause == null) {
      return;
    }
    DartType declaredSupertype = superclassName?.type;
    if (declaredSupertype is! InterfaceType) {
      return;
    }
    InterfaceType superclass = declaredSupertype;
    Map<LibraryElement, Map<String, String>> mixedInNames =
        <LibraryElement, Map<String, String>>{};

    /**
     * Report an error and return `true` if the given [name] is a private name
     * (which is defined in the given [library]) and it conflicts with another
     * definition of that name inherited from the superclass.
     */
    bool isConflictingName(
        String name, LibraryElement library, TypeName typeName) {
      if (Identifier.isPrivateName(name)) {
        Map<String, String> names =
            mixedInNames.putIfAbsent(library, () => <String, String>{});
        if (names.containsKey(name)) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
              typeName,
              [name, typeName.name.name, names[name]]);
          return true;
        }
        names[name] = typeName.name.name;
        ExecutableElement inheritedMember =
            superclass.lookUpMethod(name, library) ??
                superclass.lookUpGetter(name, library) ??
                superclass.lookUpSetter(name, library);
        if (inheritedMember != null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
              typeName, [
            name,
            typeName.name.name,
            inheritedMember.enclosingElement.name
          ]);
          return true;
        }
      }
      return false;
    }

    for (TypeName mixinType in withClause.mixinTypes) {
      DartType type = mixinType.type;
      if (type is InterfaceType) {
        LibraryElement library = type.element.library;
        if (library != _currentLibrary) {
          for (PropertyAccessorElement accessor in type.accessors) {
            if (isConflictingName(accessor.name, library, mixinType)) {
              return;
            }
          }
          for (MethodElement method in type.methods) {
            if (isConflictingName(method.name, library, mixinType)) {
              return;
            }
          }
        }
      }
    }
  }

  /**
   * Verify that the given [constructor] has at most one 'super' initializer.
   *
   * See [CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS].
   */
  void _checkForMultipleSuperInitializers(ConstructorDeclaration constructor) {
    bool hasSuperInitializer = false;
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is SuperConstructorInvocation) {
        if (hasSuperInitializer) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, initializer);
        }
        hasSuperInitializer = true;
      }
    }
  }

  void _checkForMustCallSuper(MethodDeclaration node) {
    if (node.isStatic) {
      return;
    }
    MethodElement element = _findOverriddenMemberThatMustCallSuper(node);
    if (element != null) {
      _InvocationCollector collector = new _InvocationCollector();
      node.accept(collector);
      if (!collector.superCalls.contains(element.name)) {
        _errorReporter.reportErrorForNode(HintCode.MUST_CALL_SUPER, node.name,
            [element.enclosingElement.name]);
      }
    }
  }

  /**
   * Checks to ensure that the given native function [body] is in SDK code.
   *
   * See [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE].
   */
  void _checkForNativeFunctionBodyInNonSdkCode(NativeFunctionBody body) {
    if (!_isInSystemLibrary && !_hasExtUri) {
      _errorReporter.reportErrorForNode(
          ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, body);
    }
  }

  /**
   * Verify that the given instance creation [expression] invokes an existing
   * constructor. The [constructorName] is the constructor name. The [typeName]
   * is the name of the type defining the constructor.
   *
   * This method assumes that the instance creation was tested to be 'new'
   * before being called.
   *
   * See [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR].
   */
  void _checkForNewWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      TypeName typeName) {
    // OK if resolved
    if (expression.staticElement != null) {
      return;
    }
    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element != null && element.isEnum) {
        // We have already reported the error.
        return;
      }
    }
    // prepare class name
    Identifier className = typeName.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR,
          name,
          [className, name]);
    } else {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          constructorName,
          [className]);
    }
  }

  /**
   * Check that if the given class [declaration] implicitly calls default
   * constructor of its superclass, there should be such default constructor -
   * implicit or explicit.
   *
   * See [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT].
   */
  void _checkForNoDefaultSuperConstructorImplicit(
      ClassDeclaration declaration) {
    // do nothing if mixin errors have already been reported for this class.
    if (_enclosingClass.doesMixinLackConstructors) {
      return;
    }
    // do nothing if there is explicit constructor
    List<ConstructorElement> constructors = _enclosingClass.constructors;
    if (!constructors[0].isSynthetic) {
      return;
    }
    // prepare super
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return;
    }
    ClassElement superElement = superType.element;
    // try to find default generative super constructor
    ConstructorElement superUnnamedConstructor =
        superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR,
            declaration.name,
            [superUnnamedConstructor]);
        return;
      }
      if (superUnnamedConstructor.isDefaultConstructor &&
          _enclosingClass
              .isSuperConstructorAccessible(superUnnamedConstructor)) {
        return;
      }
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
        declaration.name,
        [superType.displayName, _enclosingClass.displayName]);
  }

  /**
   * Check that the given class declaration overrides all members required by
   * its superclasses and interfaces. The [classNameNode] is the
   * [SimpleIdentifier] to be used if there is a violation, this is either the
   * named from the [ClassDeclaration] or from the [ClassTypeAlias].
   *
   * See [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR], and
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS].
   */
  void _checkForNonAbstractClassInheritsAbstractMember(
      SimpleIdentifier classNameNode) {
    if (_enclosingClass.isAbstract) {
      return;
    } else if (_enclosingClass.hasNoSuchMethod) {
      return;
    }

    Set<ExecutableElement> missingOverrides = computeMissingOverrides(
        _options.strongMode,
        _typeProvider,
        _typeSystem,
        _inheritanceManager,
        _enclosingClass);
    if (missingOverrides.isEmpty) {
      return;
    }

    List<String> missingOverrideNames = <String>[];
    for (ExecutableElement element in missingOverrides) {
      Element enclosingElement = element.enclosingElement;
      String prefix = StringUtilities.EMPTY;
      if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          prefix = _GETTER_SPACE;
          // "getter "
        } else {
          prefix = _SETTER_SPACE;
          // "setter "
        }
      }
      String newStrMember;
      if (enclosingElement != null) {
        newStrMember =
            "$prefix'${enclosingElement.displayName}.${element.displayName}'";
      } else {
        newStrMember = "$prefix'${element.displayName}'";
      }
      missingOverrideNames.add(newStrMember);
    }
    missingOverrideNames.sort();

    if (missingOverrideNames.length == 1) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          classNameNode,
          [missingOverrideNames[0]]);
    } else if (missingOverrideNames.length == 2) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          classNameNode,
          [missingOverrideNames[0], missingOverrideNames[1]]);
    } else if (missingOverrideNames.length == 3) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
          classNameNode, [
        missingOverrideNames[0],
        missingOverrideNames[1],
        missingOverrideNames[2]
      ]);
    } else if (missingOverrideNames.length == 4) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          classNameNode, [
        missingOverrideNames[0],
        missingOverrideNames[1],
        missingOverrideNames[2],
        missingOverrideNames[3]
      ]);
    } else {
      _errorReporter.reportErrorForNode(
          StaticWarningCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          classNameNode,
          [
            missingOverrideNames[0],
            missingOverrideNames[1],
            missingOverrideNames[2],
            missingOverrideNames[3],
            missingOverrideNames.length - 4
          ]);
    }
  }

  /**
   * Check to ensure that the [condition] is of type bool, are. Otherwise an
   * error is reported on the expression.
   *
   * See [StaticTypeWarningCode.NON_BOOL_CONDITION].
   */
  void _checkForNonBoolCondition(Expression condition) {
    DartType conditionType = getStaticType(condition);
    if (conditionType != null &&
        !_typeSystem.isAssignableTo(conditionType, _boolType)) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.NON_BOOL_CONDITION, condition);
    }
  }

  /**
   * Verify that the given [assertion] has either a 'bool' or '() -> bool'
   * condition.
   *
   * See [StaticTypeWarningCode.NON_BOOL_EXPRESSION].
   */
  void _checkForNonBoolExpression(Assertion assertion) {
    Expression expression = assertion.condition;
    DartType type = getStaticType(expression);
    if (type is InterfaceType) {
      if (!_typeSystem.isAssignableTo(type, _boolType)) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression);
      }
    } else if (type is FunctionType) {
      if (type.typeArguments.length == 0 &&
          !_typeSystem.isAssignableTo(type.returnType, _boolType)) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression);
      }
    }
  }

  /**
   * Checks to ensure that the given [expression] is assignable to bool.
   *
   * See [StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION].
   */
  void _checkForNonBoolNegationExpression(Expression expression) {
    DartType conditionType = getStaticType(expression);
    if (conditionType != null &&
        !_typeSystem.isAssignableTo(conditionType, _boolType)) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION, expression);
    }
  }

  /**
   * Verify the given map [literal] either:
   * * has `const modifier`
   * * has explicit type arguments
   * * is not start of the statement
   *
   * See [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT].
   */
  void _checkForNonConstMapAsExpressionStatement(MapLiteral literal) {
    // "const"
    if (literal.constKeyword != null) {
      return;
    }
    // has type arguments
    if (literal.typeArguments != null) {
      return;
    }
    // prepare statement
    Statement statement =
        literal.getAncestor((node) => node is ExpressionStatement);
    if (statement == null) {
      return;
    }
    // OK, statement does not start with map
    if (!identical(statement.beginToken, literal.beginToken)) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT, literal);
  }

  /**
   * Verify that the given method [declaration] of operator `[]=`, has `void`
   * return type.
   *
   * See [StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR].
   */
  void _checkForNonVoidReturnTypeForOperator(MethodDeclaration declaration) {
    // check that []= operator
    SimpleIdentifier name = declaration.name;
    if (name.name != "[]=") {
      return;
    }
    // check return type
    TypeAnnotation annotation = declaration.returnType;
    if (annotation != null) {
      DartType type = annotation.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, annotation);
      }
    }
  }

  /**
   * Verify the [typeName], used as the return type of a setter, is valid
   * (either `null` or the type 'void').
   *
   * See [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER].
   */
  void _checkForNonVoidReturnTypeForSetter(TypeAnnotation typeName) {
    if (typeName != null) {
      DartType type = typeName.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, typeName);
      }
    }
  }

  /**
   * Verify the given operator-method [declaration], does not have an optional
   * parameter. This method assumes that the method declaration was tested to be
   * an operator declaration before being called.
   *
   * See [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR].
   */
  void _checkForOptionalParameterInOperator(MethodDeclaration declaration) {
    FormalParameterList parameterList = declaration.parameters;
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.kind.isOptional) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR,
            formalParameter);
      }
    }
  }

  /**
   * Check that the given named optional [parameter] does not begin with '_'.
   *
   * See [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER].
   */
  void _checkForPrivateOptionalParameter(FormalParameter parameter) {
    // should be named parameter
    if (parameter.kind != ParameterKind.NAMED) {
      return;
    }
    // name should start with '_'
    SimpleIdentifier name = parameter.identifier;
    if (name == null ||
        name.isSynthetic ||
        !StringUtilities.startsWithChar(name.name, 0x5F)) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, parameter);
  }

  /**
   * Check whether the given constructor [declaration] is the redirecting
   * generative constructor and references itself directly or indirectly. The
   * [constructorElement] is the constructor element.
   *
   * See [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT].
   */
  void _checkForRecursiveConstructorRedirect(ConstructorDeclaration declaration,
      ConstructorElement constructorElement) {
    // we check generative constructor here
    if (declaration.factoryKeyword != null) {
      return;
    }
    // try to find redirecting constructor invocation and analyze it for
    // recursion
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (_hasRedirectingFactoryConstructorCycle(constructorElement)) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, initializer);
        }
        return;
      }
    }
  }

  /**
   * Check whether the given constructor [declaration] has redirected
   * constructor and references itself directly or indirectly. The
   * constructor [element] is the element introduced by the declaration.
   *
   * See [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT].
   */
  bool _checkForRecursiveFactoryRedirect(
      ConstructorDeclaration declaration, ConstructorElement element) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode =
        declaration.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // OK if no cycle
    if (!_hasRedirectingFactoryConstructorCycle(element)) {
      return false;
    }
    // report error
    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
        redirectedConstructorNode);
    return true;
  }

  /**
   * Check that the class [element] is not a superinterface to itself.
   *
   * See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS], and
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS].
   */
  void _checkForRecursiveInterfaceInheritance(ClassElement element) {
    if (element == null) {
      return;
    }

    _safeCheckForRecursiveInterfaceInheritance(element, <ClassElement>[]);
  }

  /**
   * Check that the given constructor [declaration] has a valid combination of
   * redirected constructor invocation(s), super constructor invocations and
   * field initializers.
   *
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR],
   * [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR],
   * [CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS],
   * [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR], and
   * [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR].
   */
  void _checkForRedirectingConstructorErrorCodes(
      ConstructorDeclaration declaration) {
    // Check for default values in the parameters
    ConstructorName redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor != null) {
      for (FormalParameter parameter in declaration.parameters.parameters) {
        if (parameter is DefaultFormalParameter &&
            parameter.defaultValue != null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode
                  .DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
              parameter.identifier);
        }
      }
    }
    // check if there are redirected invocations
    int numRedirections = 0;
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (numRedirections > 0) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
              initializer);
        }
        if (declaration.factoryKeyword == null) {
          RedirectingConstructorInvocation invocation = initializer;
          ConstructorElement redirectingElement = invocation.staticElement;
          if (redirectingElement == null) {
            String enclosingTypeName = _enclosingClass.displayName;
            String constructorStrName = enclosingTypeName;
            if (invocation.constructorName != null) {
              constructorStrName += ".${invocation.constructorName.name}";
            }
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR,
                invocation,
                [constructorStrName, enclosingTypeName]);
          } else {
            if (redirectingElement.isFactory) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode
                      .REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
                  initializer);
            }
          }
        }
        numRedirections++;
      }
    }
    // check for other initializers
    if (numRedirections > 0) {
      for (ConstructorInitializer initializer in declaration.initializers) {
        if (initializer is SuperConstructorInvocation) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
              initializer);
        }
        if (initializer is ConstructorFieldInitializer) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
              initializer);
        }
      }
    }
  }

  /**
   * Check whether the given constructor [declaration] has redirected
   * constructor and references itself directly or indirectly. The
   * constructor [element] is the element introduced by the declaration.
   *
   * See [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR].
   */
  void _checkForRedirectToNonConstConstructor(
      ConstructorDeclaration declaration, ConstructorElement element) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode =
        declaration.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return;
    }
    // prepare element
    if (element == null) {
      return;
    }
    // OK, it is not 'const'
    if (!element.isConst) {
      return;
    }
    // prepare redirected constructor
    ConstructorElement redirectedConstructor = element.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }
    // OK, it is also 'const'
    if (redirectedConstructor.isConst) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR,
        redirectedConstructorNode);
  }

  void _checkForReferenceBeforeDeclaration(SimpleIdentifier node) {
    if (!node.inDeclarationContext() &&
        _hiddenElements != null &&
        _hiddenElements.contains(node.staticElement)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
          node,
          [node.name]);
    }
  }

  /**
   * Check that the given rethrow [expression] is inside of a catch clause.
   *
   * See [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH].
   */
  void _checkForRethrowOutsideCatch(RethrowExpression expression) {
    if (!_isInCatchClause) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, expression);
    }
  }

  /**
   * Check that if the given constructor [declaration] is generative, then
   * it does not have an expression function body.
   *
   * See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR].
   */
  void _checkForReturnInGenerativeConstructor(
      ConstructorDeclaration declaration) {
    // ignore factory
    if (declaration.factoryKeyword != null) {
      return;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = declaration.body;
    if (body is! ExpressionFunctionBody) {
      return;
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, body);
  }

  /**
   * Check that a type mis-match between the type of the [returnExpression] and
   * the [expectedReturnType] by the enclosing method or function.
   *
   * This method is called both by [_checkForAllReturnStatementErrorCodes]
   * and [visitExpressionFunctionBody].
   *
   * See [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE].
   */
  void _checkForReturnOfInvalidType(
      Expression returnExpression, DartType expectedReturnType,
      {bool isArrowFunction = false}) {
    if (_enclosingFunction == null) {
      return;
    }
    if (_inGenerator) {
      // "return expression;" is disallowed in generators, but this is checked
      // elsewhere.  Bare "return" is always allowed in generators regardless
      // of the return type.  So no need to do any further checking.
      return;
    }
    DartType staticReturnType = _computeReturnTypeForMethod(returnExpression);
    if (expectedReturnType.isVoid) {
      if (isArrowFunction) {
        // "void f(..) => e" admits all types for "e".
        return;
      }
      if (staticReturnType.isVoid ||
          staticReturnType.isDynamic ||
          staticReturnType.isBottom ||
          staticReturnType.isDartCoreNull) {
        return;
      }
      _errorReporter.reportTypeErrorForNode(
          StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [
        staticReturnType,
        expectedReturnType,
        _enclosingFunction.displayName
      ]);
      return;
    }
    if (_expressionIsAssignableAtType(
        returnExpression, staticReturnType, expectedReturnType)) {
      return;
    }
    _errorReporter.reportTypeErrorForNode(
        StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
        returnExpression,
        [staticReturnType, expectedReturnType, _enclosingFunction.displayName]);

    // TODO(brianwilkerson) Define a hint corresponding to the warning and
    // report it if appropriate.
//        Type propagatedReturnType = returnExpression.getPropagatedType();
//        boolean isPropagatedAssignable = propagatedReturnType.isAssignableTo(expectedReturnType);
//        if (isStaticAssignable || isPropagatedAssignable) {
//          return false;
//        }
//        errorReporter.reportTypeErrorForNode(
//            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
//            returnExpression,
//            staticReturnType,
//            expectedReturnType,
//            enclosingFunction.getDisplayName());
//        return true;
  }

  /**
   * Check the given [typeReference] and that the [name] is not a reference to
   * an instance member.
   *
   * See [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER].
   */
  void _checkForStaticAccessToInstanceMember(
      ClassElement typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return;
    }
    // OK, target is not a type
    if (typeReference == null) {
      return;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is ExecutableElement) {
      // OK, static
      if (element.isStatic) {
        return;
      }
      _errorReporter.reportErrorForNode(
          StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
          name,
          [name.name]);
    }
  }

  /**
   * Check that the type of the expression in the given 'switch' [statement] is
   * assignable to the type of the 'case' members.
   *
   * See [StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE].
   */
  void _checkForSwitchExpressionNotAssignable(SwitchStatement statement) {
    // prepare 'switch' expression type
    Expression expression = statement.expression;
    DartType expressionType = getStaticType(expression);
    if (expressionType == null) {
      return;
    }

    // compare with type of the first non-default 'case'
    SwitchCase switchCase = statement.members
        .firstWhere((member) => member is SwitchCase, orElse: () => null);
    if (switchCase == null) {
      return;
    }

    Expression caseExpression = switchCase.expression;
    DartType caseType = getStaticType(caseExpression);

    // check types
    if (!_expressionIsAssignableAtType(expression, expressionType, caseType)) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE,
          expression,
          [expressionType, caseType]);
    }
  }

  /**
   * Verify that the given function type [alias] does not reference itself
   * directly.
   *
   * See [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF].
   */
  void _checkForTypeAliasCannotReferenceItself_function(
      FunctionTypeAlias alias) {
    if (_hasTypedefSelfReference(alias.element)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, alias);
    }
  }

  /**
   * Verify that the given type [name] is not a deferred type.
   *
   * See [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS].
   */
  void _checkForTypeAnnotationDeferredClass(TypeAnnotation type) {
    if (type is TypeName && type.isDeferred) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, type, [type.name]);
    }
  }

  /**
   * Verify that the given type [name] is not a type parameter in a generic
   * method.
   *
   * See [StaticWarningCode.TYPE_ANNOTATION_GENERIC_FUNCTION_PARAMETER].
   */
  void _checkForTypeAnnotationGenericFunctionParameter(TypeAnnotation type) {
    if (type is TypeName) {
      Identifier name = type.name;
      if (name is SimpleIdentifier) {
        Element element = name.staticElement;
        if (element is TypeParameterElement &&
            element.enclosingElement is ExecutableElement) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.TYPE_ANNOTATION_GENERIC_FUNCTION_PARAMETER,
              name,
              [name.name]);
        }
      }
    }
  }

  /**
   * Verify that the type arguments in the given [typeName] are all within
   * their bounds.
   *
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  void _checkForTypeArgumentNotMatchingBounds(TypeName typeName) {
    if (typeName.typeArguments == null) {
      return;
    }
    // prepare Type
    DartType type = typeName.type;
    if (type == null) {
      return;
    }
    Element element = type.element;
    if (element is ClassElement) {
      // prepare type parameters
      List<TypeParameterElement> parameterElements = element.typeParameters;
      List<DartType> parameterTypes = element.type.typeArguments;
      List<DartType> arguments = (type as ParameterizedType).typeArguments;
      // iterate over each bounded type parameter and corresponding argument
      NodeList<TypeAnnotation> argumentNodes = typeName.typeArguments.arguments;
      int loopThroughIndex =
          math.min(argumentNodes.length, parameterElements.length);
      bool shouldSubstitute =
          arguments.length != 0 && arguments.length == parameterTypes.length;
      for (int i = 0; i < loopThroughIndex; i++) {
        TypeAnnotation argumentNode = argumentNodes[i];
        DartType argType = argumentNode.type;
        DartType boundType = parameterElements[i].bound;
        if (argType != null && boundType != null) {
          if (shouldSubstitute) {
            boundType = boundType.substitute2(arguments, parameterTypes);
          }
          if (!_typeSystem.isSubtypeOf(argType, boundType)) {
            ErrorCode errorCode;
            if (_isInConstInstanceCreation) {
              errorCode =
                  CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
            } else {
              errorCode =
                  StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
            }
            _errorReporter.reportTypeErrorForNode(
                errorCode, argumentNode, [argType, boundType]);
          }
        }
      }
    }
  }

  /**
   * Check whether the given type [name] is a type parameter being used to
   * define a static member.
   *
   * See [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC].
   */
  void _checkForTypeParameterReferencedByStatic(TypeName name) {
    if (_isInStaticMethod || _isInStaticVariableDeclaration) {
      DartType type = name.type;
      // The class's type parameters are not in scope for static methods.
      // However all other type parameters are legal (e.g. the static method's
      // type parameters, or a local function's type parameters).
      if (type is TypeParameterType &&
          type.element.enclosingElement is ClassElement) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, name);
      }
    }
  }

  /**
   * Check whether the given type [parameter] is a supertype of its bound.
   *
   * See [StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
   */
  void _checkForTypeParameterSupertypeOfItsBound(TypeParameter parameter) {
    TypeParameterElement element = parameter.element;
    // prepare bound
    DartType bound = element.bound;
    if (bound == null) {
      return;
    }
    // OK, type parameter is not supertype of its bound
    if (!bound.isMoreSpecificThan(element.type)) {
      return;
    }

    _errorReporter.reportErrorForNode(
        StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND,
        parameter,
        [element.displayName, bound.displayName]);
  }

  /**
   * Check that if the given generative [constructor] has neither an explicit
   * super constructor invocation nor a redirecting constructor invocation, that
   * the superclass has a default generative constructor.
   *
   * See [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT],
   * [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR], and
   * [StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT].
   */
  void _checkForUndefinedConstructorInInitializerImplicit(
      ConstructorDeclaration constructor) {
    if (_enclosingClass == null) {
      return;
    }
    // do nothing if mixin errors have already been reported for this class.
    if (_enclosingClass.doesMixinLackConstructors) {
      return;
    }

    // Ignore if the constructor is not generative.
    if (constructor.factoryKeyword != null) {
      return;
    }

    // Ignore if the constructor has either an implicit super constructor
    // invocation or a redirecting constructor invocation.
    for (ConstructorInitializer constructorInitializer
        in constructor.initializers) {
      if (constructorInitializer is SuperConstructorInvocation ||
          constructorInitializer is RedirectingConstructorInvocation) {
        return;
      }
    }

    // Check to see whether the superclass has a non-factory unnamed
    // constructor.
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return;
    }
    ClassElement superElement = superType.element;
    ConstructorElement superUnnamedConstructor =
        superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR,
            constructor.returnType,
            [superUnnamedConstructor]);
      } else if (!superUnnamedConstructor.isDefaultConstructor ||
          !_enclosingClass
              .isSuperConstructorAccessible(superUnnamedConstructor)) {
        Identifier returnType = constructor.returnType;
        SimpleIdentifier name = constructor.name;
        int offset = returnType.offset;
        int length = (name != null ? name.end : returnType.end) - offset;
        _errorReporter.reportErrorForOffset(
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT,
            offset,
            length,
            [superType.displayName]);
      }
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          constructor.returnType,
          [superElement.name]);
    }
  }

  /**
   * Check that if the given [name] is a reference to a static member it is
   * defined in the enclosing class rather than in a superclass.
   *
   * See [StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
   */
  void _checkForUnqualifiedReferenceToNonLocalStaticMember(
      SimpleIdentifier name) {
    Element element = name.staticElement;
    if (element == null || element is TypeParameterElement) {
      return;
    }
    Element enclosingElement = element.enclosingElement;
    if (identical(enclosingElement, _enclosingClass)) {
      return;
    }
    if (identical(enclosingElement, _enclosingEnum)) {
      return;
    }
    if (enclosingElement is! ClassElement) {
      return;
    }
    if (element is ExecutableElement && !element.isStatic) {
      return;
    }
    _errorReporter.reportErrorForNode(
        StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
        name,
        [enclosingElement.name]);
  }

  void _checkForValidField(FieldFormalParameter parameter) {
    AstNode parent2 = parameter.parent?.parent;
    if (parent2 is! ConstructorDeclaration &&
        parent2?.parent is! ConstructorDeclaration) {
      return;
    }
    ParameterElement element = parameter.element;
    if (element is FieldFormalParameterElement) {
      FieldElement fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
            parameter,
            [parameter.identifier.name]);
      } else {
        ParameterElement parameterElement = parameter.element;
        if (parameterElement is FieldFormalParameterElementImpl) {
          DartType declaredType = parameterElement.type;
          DartType fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (declaredType != null &&
              fieldType != null &&
              !_typeSystem.isAssignableTo(declaredType, fieldType)) {
            _errorReporter.reportTypeErrorForNode(
                StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
                parameter,
                [declaredType, fieldType]);
          }
        } else {
          if (fieldElement.isSynthetic) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD,
                parameter,
                [parameter.identifier.name]);
          }
        }
      }
    }
//        else {
//        // TODO(jwren) Report error, constructor initializer variable is a top level element
//        // (Either here or in ErrorVerifier.checkForAllFinalInitializedErrorCodes)
//        }
  }

  /**
   * Verify the given operator-method [declaration], has correct number of
   * parameters.
   *
   * This method assumes that the method declaration was tested to be an
   * operator declaration before being called.
   *
   * See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR].
   */
  void _checkForWrongNumberOfParametersForOperator(
      MethodDeclaration declaration) {
    // prepare number of parameters
    FormalParameterList parameterList = declaration.parameters;
    if (parameterList == null) {
      return;
    }
    int numParameters = parameterList.parameters.length;
    // prepare operator name
    SimpleIdentifier nameNode = declaration.name;
    if (nameNode == null) {
      return;
    }
    String name = nameNode.name;
    // check for exact number of parameters
    int expected = -1;
    if ("[]=" == name) {
      expected = 2;
    } else if ("<" == name ||
        ">" == name ||
        "<=" == name ||
        ">=" == name ||
        "==" == name ||
        "+" == name ||
        "/" == name ||
        "~/" == name ||
        "*" == name ||
        "%" == name ||
        "|" == name ||
        "^" == name ||
        "&" == name ||
        "<<" == name ||
        ">>" == name ||
        "[]" == name) {
      expected = 1;
    } else if ("~" == name) {
      expected = 0;
    }
    if (expected != -1 && numParameters != expected) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR,
          nameNode,
          [name, expected, numParameters]);
    } else if ("-" == name && numParameters > 1) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
          nameNode,
          [numParameters]);
    }
  }

  /**
   * Verify that the given setter [parameterList] has only one required
   * parameter. The [setterName] is the name of the setter to report problems
   * on.
   *
   * This method assumes that the method declaration was tested to be a setter
   * before being called.
   *
   * See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER].
   */
  void _checkForWrongNumberOfParametersForSetter(
      SimpleIdentifier setterName, FormalParameterList parameterList) {
    if (setterName == null || parameterList == null) {
      return;
    }

    NodeList<FormalParameter> parameters = parameterList.parameters;
    if (parameters.length != 1 ||
        parameters[0].kind != ParameterKind.REQUIRED) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
          setterName);
    }
  }

  /**
   * Check for a type mis-match between the yielded type and the declared
   * return type of a generator function.
   *
   * This method should only be called in generator functions.
   */
  void _checkForYieldOfInvalidType(
      Expression yieldExpression, bool isYieldEach) {
    assert(_inGenerator);
    if (_enclosingFunction == null) {
      return;
    }
    DartType declaredReturnType = _enclosingFunction.returnType;
    DartType staticYieldedType = getStaticType(yieldExpression);
    DartType impliedReturnType;
    if (isYieldEach) {
      impliedReturnType = staticYieldedType;
    } else if (_enclosingFunction.isAsynchronous) {
      impliedReturnType =
          _typeProvider.streamType.instantiate(<DartType>[staticYieldedType]);
    } else {
      impliedReturnType =
          _typeProvider.iterableType.instantiate(<DartType>[staticYieldedType]);
    }
    if (!_checkForAssignableExpressionAtType(yieldExpression, impliedReturnType,
        declaredReturnType, StaticTypeWarningCode.YIELD_OF_INVALID_TYPE)) {
      return;
    }
    if (isYieldEach) {
      // Since the declared return type might have been "dynamic", we need to
      // also check that the implied return type is assignable to generic
      // Stream/Iterable.
      DartType requiredReturnType;
      if (_enclosingFunction.isAsynchronous) {
        requiredReturnType = _typeProvider.streamDynamicType;
      } else {
        requiredReturnType = _typeProvider.iterableDynamicType;
      }
      if (!_typeSystem.isAssignableTo(impliedReturnType, requiredReturnType)) {
        _errorReporter.reportTypeErrorForNode(
            StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
            yieldExpression,
            [impliedReturnType, requiredReturnType]);
        return;
      }
    }
  }

  /**
   * Verify that if the given class [declaration] implements the class Function
   * that it has a concrete implementation of the call method.
   *
   * See [StaticWarningCode.FUNCTION_WITHOUT_CALL].
   */
  void _checkImplementsFunctionWithoutCall(AstNode className) {
    ClassElement classElement = _enclosingClass;
    if (classElement == null) {
      return;
    }
    if (classElement.isAbstract) {
      return;
    }
    if (!_typeSystem.isSubtypeOf(
        classElement.type, _typeProvider.functionType)) {
      return;
    }
    // If there is a noSuchMethod method, then don't report the warning,
    // see dartbug.com/16078
    if (_enclosingClass.hasNoSuchMethod) {
      return;
    }
    ExecutableElement callMethod = _inheritanceManager.lookupMember(
        classElement, FunctionElement.CALL_METHOD_NAME);
    if (callMethod == null ||
        callMethod is! MethodElement ||
        (callMethod as MethodElement).isAbstract) {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.FUNCTION_WITHOUT_CALL, className);
    }
  }

  /**
   * Verify that the given class [declaration] does not have the same class in
   * the 'extends' and 'implements' clauses.
   *
   * See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
   */
  void _checkImplementsSuperClass(ImplementsClause implementsClause) {
    // prepare super type
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return;
    }
    // prepare interfaces
    if (implementsClause == null) {
      return;
    }
    // check interfaces
    for (TypeName interfaceNode in implementsClause.interfaces) {
      if (interfaceNode.type == superType) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS,
            interfaceNode,
            [superType.displayName]);
      }
    }
  }

  /**
   * Verify that the given [typeArguments] are all within their bounds, as
   * defined by the given [element].
   *
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  void _checkTypeArguments(InvocationExpression node) {
    NodeList<TypeAnnotation> typeArgumentList = node.typeArguments?.arguments;
    if (typeArgumentList == null) {
      return;
    }

    var genericType = node.function.staticType;
    var instantiatedType = node.staticInvokeType;
    if (genericType is FunctionType && instantiatedType is FunctionType) {
      var fnTypeParams =
          TypeParameterTypeImpl.getTypes(genericType.typeFormals);
      var typeArgs = typeArgumentList.map((t) => t.type).toList();

      for (int i = 0, len = math.min(typeArgs.length, fnTypeParams.length);
          i < len;
          i++) {
        // Check the `extends` clause for the type parameter, if any.
        //
        // Also substitute to handle cases like this:
        //
        //     <TFrom, TTo extends TFrom>
        //     <TFrom, TTo extends Iterable<TFrom>>
        //     <T extends Clonable<T>>
        //
        DartType argType = typeArgs[i];
        DartType bound =
            fnTypeParams[i].bound.substitute2(typeArgs, fnTypeParams);
        if (!_typeSystem.isSubtypeOf(argType, bound)) {
          _errorReporter.reportTypeErrorForNode(
              StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
              typeArgumentList[i],
              [argType, bound]);
        }
      }
    }
  }

  void _checkUseOfCovariantInParameters(FormalParameterList node) {
    AstNode parent = node.parent;
    if (parent is MethodDeclaration && !parent.isStatic) {
      return;
    }
    NodeList<FormalParameter> parameters = node.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = parameters[i];
      Token keyword = parameter.covariantKeyword;
      if (keyword != null) {
        _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, keyword);
      }
    }
  }

  DartType _computeReturnTypeForMethod(Expression returnExpression) {
    // This method should never be called for generators, since generators are
    // never allowed to contain return statements with expressions.
    assert(!_inGenerator);
    if (returnExpression == null) {
      if (_enclosingFunction.isAsynchronous) {
        return _typeProvider.futureNullType;
      } else {
        return VoidTypeImpl.instance;
      }
    }
    DartType staticReturnType = getStaticType(returnExpression);
    if (staticReturnType != null && _enclosingFunction.isAsynchronous) {
      return _typeProvider.futureType.instantiate(
          <DartType>[staticReturnType.flattenFutures(_typeSystem)]);
    }
    return staticReturnType;
  }

  bool _expressionIsAssignableAtType(Expression expression,
      DartType actualStaticType, DartType expectedStaticType,
      {isDeclarationCast: false}) {
    bool concrete = _options.strongMode && checker.hasStrictArrow(expression);
    if (concrete && actualStaticType is FunctionType) {
      actualStaticType =
          _typeSystem.functionTypeToConcreteType(actualStaticType);
    }
    return _typeSystem.isAssignableTo(actualStaticType, expectedStaticType,
        isDeclarationCast: isDeclarationCast);
  }

  MethodElement _findOverriddenMemberThatMustCallSuper(MethodDeclaration node) {
    ExecutableElement overriddenMember = _getOverriddenMember(node.element);
    List<ExecutableElement> seen = <ExecutableElement>[];
    while (
        overriddenMember is MethodElement && !seen.contains(overriddenMember)) {
      for (ElementAnnotation annotation in overriddenMember.metadata) {
        if (annotation.isMustCallSuper) {
          return overriddenMember;
        }
      }
      seen.add(overriddenMember);
      // Keep looking up the chain.
      overriddenMember = _getOverriddenMember(overriddenMember);
    }
    return null;
  }

  /**
   * Return the error code that should be used when the given class [element]
   * references itself directly.
   */
  ErrorCode _getBaseCaseErrorCode(ClassElement element) {
    InterfaceType supertype = element.supertype;
    if (supertype != null && _enclosingClass == supertype.element) {
      return CompileTimeErrorCode
          .RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS;
    }
    List<InterfaceType> mixins = element.mixins;
    for (int i = 0; i < mixins.length; i++) {
      if (_enclosingClass == mixins[i].element) {
        return CompileTimeErrorCode
            .RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH;
      }
    }
    return CompileTimeErrorCode
        .RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS;
  }

  /**
   * Given an [expression] in a switch case whose value is expected to be an
   * enum constant, return the name of the constant.
   */
  String _getConstantName(Expression expression) {
    // TODO(brianwilkerson) Convert this to return the element representing the
    // constant.
    if (expression is SimpleIdentifier) {
      return expression.name;
    } else if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }
    return null;
  }

  /**
   * Return the return type of the given [getter].
   */
  DartType _getGetterType(PropertyAccessorElement getter) {
    FunctionType functionType = getter.type;
    if (functionType != null) {
      return functionType.returnType;
    } else {
      return null;
    }
  }

  /**
   * Return a human-readable representation of the kind of the [element].
   */
  String _getKind(ExecutableElement element) {
    if (element is MethodElement) {
      return 'method';
    } else if (element is PropertyAccessorElement) {
      if (element.isSynthetic) {
        PropertyInducingElement variable = element.variable;
        if (variable is FieldElement) {
          return 'field';
        }
        return 'variable';
      } else if (element.isGetter) {
        return 'getter';
      } else {
        return 'setter';
      }
    } else if (element is ConstructorElement) {
      return 'constructor';
    } else if (element is FunctionElement) {
      return 'function';
    }
    return 'member';
  }

  /**
   * Return the name of the library that defines given [element].
   */
  String _getLibraryName(Element element) {
    if (element == null) {
      return StringUtilities.EMPTY;
    }
    LibraryElement library = element.library;
    if (library == null) {
      return StringUtilities.EMPTY;
    }
    List<ImportElement> imports = _currentLibrary.imports;
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

  ExecutableElement _getOverriddenMember(Element member) {
    if (member == null) {
      return null;
    }
    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return null;
    }
    String name = member.name;
    ClassElement superclass = classElement.supertype?.element;
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    while (superclass != null && visitedClasses.add(superclass)) {
      ExecutableElement member = superclass.getMethod(name) ??
          superclass.getGetter(name) ??
          superclass.getSetter(name);
      if (member != null) {
        return member;
      }
      superclass = superclass.supertype?.element;
    }
    return null;
  }

  /**
   * Return the type of the first and only parameter of the given [setter].
   */
  DartType _getSetterType(PropertyAccessorElement setter) {
    // Get the parameters for MethodDeclaration or FunctionDeclaration
    List<ParameterElement> setterParameters = setter.parameters;
    // If there are no setter parameters, return no type.
    if (setterParameters.length == 0) {
      return null;
    }
    return setterParameters[0].type;
  }

  /**
   * Return `true` if the given [constructor] redirects to itself, directly or
   * indirectly.
   */
  bool _hasRedirectingFactoryConstructorCycle(ConstructorElement constructor) {
    ConstructorElement nonMember(ConstructorElement constructor) {
      return constructor is ConstructorMember
          ? constructor.baseElement
          : constructor;
    }

    Set<ConstructorElement> constructors = new HashSet<ConstructorElement>();
    ConstructorElement current = constructor;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, constructor);
      }
      constructors.add(current);
      current = nonMember(current.redirectedConstructor);
    }
    return false;
  }

  /**
   * Return `true` if the given [element] has direct or indirect reference to
   * itself from anywhere except a class element or type parameter bounds.
   */
  bool _hasTypedefSelfReference(Element element) {
    Set<Element> checked = new HashSet<Element>();
    List<Element> toCheck = new List<Element>();
    GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference
        elementVisitor =
        new GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(
            toCheck);
    toCheck.add(element);
    bool firstIteration = true;
    while (true) {
      Element current;
      // get next element
      while (true) {
        // may be no more elements to check
        if (toCheck.isEmpty) {
          return false;
        }
        // try to get next element
        current = toCheck.removeAt(toCheck.length - 1);
        if (element == current) {
          if (firstIteration) {
            firstIteration = false;
            break;
          } else {
            return true;
          }
        }
        if (current != null && !checked.contains(current)) {
          break;
        }
      }
      // check current element
      current.accept(elementVisitor);
      checked.add(current);
    }
  }

  bool _isFunctionType(DartType type) {
    if (type.isDynamic || type.isDartCoreNull) {
      return true;
    } else if (type is FunctionType || type.isDartCoreFunction) {
      return true;
    } else if (type is InterfaceType) {
      MethodElement callMethod =
          type.lookUpMethod(FunctionElement.CALL_METHOD_NAME, _currentLibrary);
      return callMethod != null;
    }
    return false;
  }

  /**
   * Return `true` if the given 'this' [expression] is in a valid context.
   */
  bool _isThisInValidContext(ThisExpression expression) {
    for (AstNode node = expression.parent; node != null; node = node.parent) {
      if (node is CompilationUnit) {
        return false;
      } else if (node is ConstructorDeclaration) {
        return node.factoryKeyword == null;
      } else if (node is ConstructorInitializer) {
        return false;
      } else if (node is MethodDeclaration) {
        return !node.isStatic;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [identifier] is in a location where it is
   * allowed to resolve to a static member of a supertype.
   */
  bool _isUnqualifiedReferenceToNonLocalStaticMemberAllowed(
      SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return true;
    }
    AstNode parent = identifier.parent;
    if (parent is Annotation) {
      return identical(parent.constructorName, identifier);
    }
    if (parent is CommentReference) {
      return parent.newKeyword != null;
    }
    if (parent is ConstructorName) {
      return identical(parent.name, identifier);
    }
    if (parent is MethodInvocation) {
      return identical(parent.methodName, identifier);
    }
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, identifier);
    }
    if (parent is PropertyAccess) {
      return identical(parent.propertyName, identifier);
    }
    if (parent is SuperConstructorInvocation) {
      return identical(parent.constructorName, identifier);
    }
    return false;
  }

  bool _isUserDefinedObject(EvaluationResultImpl result) =>
      result == null ||
      (result.value != null && result.value.isUserDefinedObject);

  /**
   * Check that the given class [element] is not a superinterface to itself. The
   * [path] is a list containing the potentially cyclic implements path.
   *
   * See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS],
   * and [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH].
   */
  bool _safeCheckForRecursiveInterfaceInheritance(
      ClassElement element, List<ClassElement> path) {
    // Detect error condition.
    int size = path.length;
    // If this is not the base case (size > 0), and the enclosing class is the
    // given class element then an error an error.
    if (size > 0 && _enclosingClass == element) {
      String enclosingClassName = _enclosingClass.displayName;
      if (size > 1) {
        // Construct a string showing the cyclic implements path:
        // "A, B, C, D, A"
        String separator = ", ";
        StringBuffer buffer = new StringBuffer();
        for (int i = 0; i < size; i++) {
          buffer.write(path[i].displayName);
          buffer.write(separator);
        }
        buffer.write(element.displayName);
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            _enclosingClass,
            [enclosingClassName, buffer.toString()]);
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH
        _errorReporter.reportErrorForElement(_getBaseCaseErrorCode(element),
            _enclosingClass, [enclosingClassName]);
        return true;
      }
    }
    if (path.indexOf(element) > 0) {
      return false;
    }
    path.add(element);
    // n-case
    InterfaceType supertype = element.supertype;
    if (supertype != null &&
        _safeCheckForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }
    List<InterfaceType> interfaceTypes = element.interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      if (_safeCheckForRecursiveInterfaceInheritance(
          interfaceType.element, path)) {
        return true;
      }
    }
    List<InterfaceType> mixinTypes = element.mixins;
    for (InterfaceType mixinType in mixinTypes) {
      if (_safeCheckForRecursiveInterfaceInheritance(mixinType.element, path)) {
        return true;
      }
    }
    path.removeAt(path.length - 1);
    return false;
  }

  /**
   * Returns [ExecutableElement]s that are declared in interfaces implemented
   * by the [classElement], but not implemented by the [classElement] or its
   * superclasses.
   */
  static Set<ExecutableElement> computeMissingOverrides(
      bool strongMode,
      TypeProvider typeProvider,
      TypeSystem typeSystem,
      InheritanceManager inheritanceManager,
      ClassElement classElement) {
    //
    // Store in local sets the set of all method and accessor names
    //
    HashSet<ExecutableElement> missingOverrides =
        new HashSet<ExecutableElement>();
    //
    // Loop through the set of all executable elements declared in the implicit
    // interface.
    //
    Map<String, ExecutableElement> membersInheritedFromInterfaces =
        inheritanceManager.getMembersInheritedFromInterfaces(classElement);
    Map<String, ExecutableElement> membersInheritedFromSuperclasses =
        inheritanceManager.getMembersInheritedFromClasses(classElement);
    for (String memberName in membersInheritedFromInterfaces.keys) {
      ExecutableElement executableElt =
          membersInheritedFromInterfaces[memberName];
      if (memberName == null) {
        break;
      }
      // If the element is not synthetic and can be determined to be defined in
      // Object, skip it.
      if (executableElt.enclosingElement != null &&
          (executableElt.enclosingElement as ClassElement).type.isObject) {
        continue;
      }
      // Check to see if some element is in local enclosing class that matches
      // the name of the required member.
      if (_isMemberInClassOrMixin(executableElt, classElement)) {
        // We do not have to verify that this implementation of the found method
        // matches the required function type: the set of
        // StaticWarningCode.INVALID_METHOD_OVERRIDE_* warnings break out the
        // different specific situations.
        continue;
      }
      // First check to see if this element was declared in the superclass
      // chain, in which case there is already a concrete implementation.
      ExecutableElement elt = membersInheritedFromSuperclasses[memberName];
      // Check to see if an element was found in the superclass chain with the
      // correct name.
      if (elt != null) {
        // Reference the types, if any are null then continue.
        InterfaceType enclosingType = classElement.type;
        FunctionType concreteType = elt.type;
        FunctionType requiredMemberType = executableElt.type;
        if (enclosingType == null ||
            concreteType == null ||
            requiredMemberType == null) {
          continue;
        }
        // Some element was found in the superclass chain that matches the name
        // of the required member.
        // If it is not abstract and it is the correct one (types match- the
        // version of this method that we have has the correct number of
        // parameters, etc), then this class has a valid implementation of this
        // method, so skip it.
        if ((elt is MethodElement && !elt.isAbstract) ||
            (elt is PropertyAccessorElement && !elt.isAbstract)) {
          // Since we are comparing two function types, we need to do the
          // appropriate type substitutions first ().
          FunctionType foundConcreteFT =
              inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(
                  concreteType, memberName, enclosingType);
          FunctionType requiredMemberFT =
              inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(
                  requiredMemberType, memberName, enclosingType);
          foundConcreteFT =
              typeSystem.functionTypeToConcreteType(foundConcreteFT);
          requiredMemberFT =
              typeSystem.functionTypeToConcreteType(requiredMemberFT);

          // Strong mode does override checking for types in CodeChecker, so
          // we can skip it here. Doing it here leads to unnecessary duplicate
          // error messages in subclasses that inherit from one that has an
          // override error.
          //
          // See: https://github.com/dart-lang/sdk/issues/25232
          if (strongMode ||
              typeSystem.isSubtypeOf(foundConcreteFT, requiredMemberFT)) {
            continue;
          }
        }
      }
      // The not qualifying concrete executable element was found, add it to the
      // list.
      missingOverrides.add(executableElt);
    }
    return missingOverrides;
  }

  /**
   * Return [FieldElement]s that are declared in the [ClassDeclaration] with
   * the given [constructor], but are not initialized.
   */
  static List<FieldElement> computeNotInitializedFields(
      ConstructorDeclaration constructor) {
    Set<FieldElement> fields = new Set<FieldElement>();
    var classDeclaration = constructor.parent as ClassDeclaration;
    for (ClassMember fieldDeclaration in classDeclaration.members) {
      if (fieldDeclaration is FieldDeclaration) {
        for (VariableDeclaration field in fieldDeclaration.fields.variables) {
          if (field.initializer == null) {
            fields.add(field.element);
          }
        }
      }
    }

    List<FormalParameter> parameters = constructor.parameters?.parameters ?? [];
    for (FormalParameter parameter in parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = (parameter as DefaultFormalParameter).parameter;
      }
      if (parameter is FieldFormalParameter) {
        FieldFormalParameterElement element =
            parameter.identifier.staticElement as FieldFormalParameterElement;
        fields.remove(element.field);
      }
    }

    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fields.remove(initializer.fieldName.staticElement);
      }
    }

    return fields.toList();
  }

  /**
   * Return the static type of the given [expression] that is to be used for
   * type analysis.
   */
  static DartType getStaticType(Expression expression) {
    DartType type = expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) This should never happen.
      return DynamicTypeImpl.instance;
    }
    return type;
  }

  /**
   * Return the variable element represented by the given [expression], or
   * `null` if there is no such element.
   */
  static VariableElement getVariableElement(Expression expression) {
    if (expression is Identifier) {
      Element element = expression.staticElement;
      if (element is VariableElement) {
        return element;
      }
    }
    return null;
  }

  /**
   * Return `true` iff the given [classElement] has a concrete method, getter or
   * setter that matches the name of the given [executableElement] in either the
   * class itself, or one of its' mixins.
   *
   * By "match", only the name of the member is tested to match, it does not
   * have to equal or be a subtype of the given executable element, this is due
   * to the specific use where this method is used in
   * [_checkForNonAbstractClassInheritsAbstractMember].
   */
  static bool _isMemberInClassOrMixin(
      ExecutableElement executableElement, ClassElement classElement) {
    ExecutableElement foundElt = null;
    String executableName = executableElement.name;
    if (executableElement is MethodElement) {
      foundElt = classElement.getMethod(executableName);
      if (foundElt != null && !foundElt.isAbstract) {
        return true;
      }
      List<InterfaceType> mixins = classElement.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getMethod(executableName);
      }
      if (foundElt != null && !foundElt.isAbstract) {
        return true;
      }
    } else if (executableElement is PropertyAccessorElement) {
      if (executableElement.isGetter) {
        foundElt = classElement.getGetter(executableName);
      }
      if (foundElt == null && executableElement.isSetter) {
        foundElt = classElement.getSetter(executableName);
      }
      if (foundElt != null &&
          !(foundElt as PropertyAccessorElement).isAbstract) {
        return true;
      }
      List<InterfaceType> mixins = classElement.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getGetter(executableName);
        if (foundElt == null) {
          foundElt = mixins[i].getSetter(executableName);
        }
      }
      if (foundElt != null && !foundElt.isAbstract) {
        return true;
      }
    }
    return false;
  }
}

class GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference
    extends GeneralizingElementVisitor<Object> {
  List<Element> toCheck;

  GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(this.toCheck)
      : super();

  @override
  Object visitClassElement(ClassElement element) {
    // Typedefs are allowed to reference themselves via classes.
    return null;
  }

  @override
  Object visitFunctionElement(FunctionElement element) {
    _addTypeToCheck(element.returnType);
    return super.visitFunctionElement(element);
  }

  @override
  Object visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _addTypeToCheck(element.returnType);
    return super.visitFunctionTypeAliasElement(element);
  }

  @override
  Object visitParameterElement(ParameterElement element) {
    _addTypeToCheck(element.type);
    return super.visitParameterElement(element);
  }

  @override
  Object visitTypeParameterElement(TypeParameterElement element) {
    _addTypeToCheck(element.bound);
    return super.visitTypeParameterElement(element);
  }

  void _addTypeToCheck(DartType type) {
    if (type == null) {
      return;
    }
    // schedule for checking
    toCheck.add(type.element);
    // type arguments
    if (type is InterfaceType) {
      for (DartType typeArgument in type.typeArguments) {
        _addTypeToCheck(typeArgument);
      }
    }
  }
}

/**
 * A record of the elements that will be declared in some scope (block), but are
 * not yet declared.
 */
class HiddenElements {
  /**
   * The elements hidden in outer scopes, or `null` if this is the outermost
   * scope.
   */
  final HiddenElements outerElements;

  /**
   * A set containing the elements that will be declared in this scope, but are
   * not yet declared.
   */
  Set<Element> _elements = new HashSet<Element>();

  /**
   * Initialize a newly created set of hidden elements to include all of the
   * elements defined in the set of [outerElements] and all of the elements
   * declared in the given [block].
   */
  HiddenElements(this.outerElements, Block block) {
    _initializeElements(block);
  }

  /**
   * Return `true` if this set of elements contains the given [element].
   */
  bool contains(Element element) {
    if (_elements.contains(element)) {
      return true;
    } else if (outerElements != null) {
      return outerElements.contains(element);
    }
    return false;
  }

  /**
   * Record that the given [element] has been declared, so it is no longer
   * hidden.
   */
  void declare(Element element) {
    _elements.remove(element);
  }

  /**
   * Initialize the list of elements that are not yet declared to be all of the
   * elements declared somewhere in the given [block].
   */
  void _initializeElements(Block block) {
    _elements.addAll(BlockScope.elementsInBlock(block));
  }
}

/**
 * A class used to compute a list of the constants whose value needs to be
 * computed before errors can be computed by the [VerifyUnitTask].
 */
class RequiredConstantsComputer extends RecursiveAstVisitor {
  /**
   * The source with which any pending errors will be associated.
   */
  final Source source;

  /**
   * A list of the pending errors that were computed.
   */
  final List<PendingError> pendingErrors = <PendingError>[];

  /**
   * A list of the constants whose value needs to be computed before the pending
   * errors can be used to compute an analysis error.
   */
  final List<ConstantEvaluationTarget> requiredConstants =
      <ConstantEvaluationTarget>[];

  /**
   * Initialize a newly created computer to compute required constants within
   * the given [source].
   */
  RequiredConstantsComputer(this.source);

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkForMissingRequiredParam(
        node.staticInvokeType, node.argumentList, node);
    return super.visitFunctionExpressionInvocation(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    DartType type = node.constructorName.type.type;
    if (type is InterfaceType) {
      _checkForMissingRequiredParam(
          resolutionMap.staticElementForConstructorReference(node)?.type,
          node.argumentList,
          node.constructorName);
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    _checkForMissingRequiredParam(
        node.staticInvokeType, node.argumentList, node.methodName);
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    DartType type =
        resolutionMap.staticElementForConstructorReference(node)?.type;
    if (type != null) {
      _checkForMissingRequiredParam(type, node.argumentList, node);
    }
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    DartType type =
        resolutionMap.staticElementForConstructorReference(node)?.type;
    if (type != null) {
      _checkForMissingRequiredParam(type, node.argumentList, node);
    }
    return super.visitSuperConstructorInvocation(node);
  }

  void _checkForMissingRequiredParam(
      DartType type, ArgumentList argumentList, AstNode node) {
    if (type is FunctionType) {
      for (ParameterElement parameter in type.parameters) {
        if (parameter.parameterKind == ParameterKind.NAMED) {
          ElementAnnotationImpl annotation = _getRequiredAnnotation(parameter);
          if (annotation != null) {
            String parameterName = parameter.name;
            if (!_containsNamedExpression(argumentList, parameterName)) {
              requiredConstants.add(annotation);
              pendingErrors.add(new PendingMissingRequiredParameterError(
                  source, parameterName, node, annotation));
            }
          }
        }
      }
    }
  }

  bool _containsNamedExpression(ArgumentList args, String name) {
    NodeList<Expression> arguments = args.arguments;
    for (int i = arguments.length - 1; i >= 0; i--) {
      Expression expression = arguments[i];
      if (expression is NamedExpression) {
        if (expression.name.label.name == name) {
          return true;
        }
      }
    }
    return false;
  }

  ElementAnnotationImpl _getRequiredAnnotation(ParameterElement param) => param
      .metadata
      .firstWhere((ElementAnnotation e) => e.isRequired, orElse: () => null);
}

/**
 * Recursively visits an AST, looking for method invocations.
 */
class _InvocationCollector extends RecursiveAstVisitor {
  final List<String> superCalls = <String>[];

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.target is SuperExpression) {
      superCalls.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }
}

/**
 * Recursively visits a type annotation, looking uninstantiated bounds.
 */
class _UninstantiatedBoundChecker extends RecursiveAstVisitor {
  final ErrorReporter _errorReporter;
  _UninstantiatedBoundChecker(this._errorReporter);

  @override
  visitTypeName(node) {
    var typeArgs = node.typeArguments;
    if (typeArgs != null) {
      typeArgs.accept(this);
      return;
    }

    var element = node.type.element;
    if (element is TypeParameterizedElement &&
        element.typeParameters.any((p) => p.bound != null)) {
      _errorReporter.reportErrorForNode(
          StrongModeCode.NOT_INSTANTIATED_BOUND, node, [node.type]);
    }
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.resolver.error_verifier;

import 'dart:collection';
import "dart:math" as math;

import 'java_engine.dart';
import 'error.dart';
import 'scanner.dart' as sc;
import 'utilities_dart.dart';
import 'ast.dart';
import 'parser.dart' show Parser, ParserErrorCode;
import 'sdk.dart' show DartSdk, SdkLibrary;
import 'element.dart';
import 'constant.dart';
import 'resolver.dart';
import 'element_resolver.dart';

/**
 * Instances of the class `ErrorVerifier` traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver.
 */
class ErrorVerifier extends RecursiveAstVisitor<Object> {
  /**
   * Return the static type of the given expression that is to be used for type analysis.
   *
   * @param expression the expression whose type is to be returned
   * @return the static type of the given expression
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
   * Return the variable element represented by the given expression, or `null` if there is no
   * such element.
   *
   * @param expression the expression whose element is to be returned
   * @return the variable element represented by the expression
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
   * The object providing access to the types defined by the language.
   */
  final TypeProvider _typeProvider;

  /**
   * The manager for the inheritance mappings.
   */
  final InheritanceManager _inheritanceManager;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a
   * [ConstructorDeclaration] and the constructor is 'const'.
   *
   * See [visitConstructorDeclaration].
   */
  bool _isEnclosingConstructorConst = false;

  /**
   * A flag indicating whether we are currently within a function body marked as being asynchronous.
   */
  bool _inAsync = false;

  /**
   * A flag indicating whether we are currently within a function body marked as being a generator.
   */
  bool _inGenerator = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a
   * [CatchClause].
   *
   * See [visitCatchClause].
   */
  bool _isInCatchClause = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of an
   * [Comment].
   */
  bool _isInComment = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of an
   * [InstanceCreationExpression].
   */
  bool _isInConstInstanceCreation = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a native
   * [ClassDeclaration].
   */
  bool _isInNativeClass = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a static variable
   * declaration.
   */
  bool _isInStaticVariableDeclaration = false;

  /**
   * This is set to `true` iff the visitor is currently visiting an instance variable
   * declaration.
   */
  bool _isInInstanceVariableDeclaration = false;

  /**
   * This is set to `true` iff the visitor is currently visiting an instance variable
   * initializer.
   */
  bool _isInInstanceVariableInitializer = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a
   * [ConstructorInitializer].
   */
  bool _isInConstructorInitializer = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a
   * [FunctionTypedFormalParameter].
   */
  bool _isInFunctionTypedFormalParameter = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a static method. By "method"
   * here getter, setter and operator declarations are also implied since they are all represented
   * with a [MethodDeclaration] in the AST structure.
   */
  bool _isInStaticMethod = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a factory constructor.
   */
  bool _isInFactory = false;

  /**
   * This is set to `true` iff the visitor is currently visiting code in the SDK.
   */
  bool _isInSystemLibrary = false;

  /**
   * A flag indicating whether the current library contains at least one import directive with a URI
   * that uses the "dart-ext" scheme.
   */
  bool _hasExtUri = false;

  /**
   * This is set to `false` on the entry of every [BlockFunctionBody], and is restored
   * to the enclosing value on exit. The value is used in
   * [checkForMixedReturns] to prevent both
   * [StaticWarningCode.MIXED_RETURN_TYPES] and [StaticWarningCode.RETURN_WITHOUT_VALUE]
   * from being generated in the same function body.
   */
  bool _hasReturnWithoutValue = false;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function that we are currently visiting, or `null` if we are not inside a
   * method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * The return statements found in the method or function that we are currently visiting that have
   * a return value.
   */
  List<ReturnStatement> _returnsWith = new List<ReturnStatement>();

  /**
   * The return statements found in the method or function that we are currently visiting that do
   * not have a return value.
   */
  List<ReturnStatement> _returnsWithout = new List<ReturnStatement>();

  /**
   * This map is initialized when visiting the contents of a class declaration. If the visitor is
   * not in an enclosing class declaration, then the map is set to `null`.
   *
   * When set the map maps the set of [FieldElement]s in the class to an
   * [INIT_STATE.NOT_INIT] or [INIT_STATE.INIT_IN_DECLARATION]. <code>checkFor*</code>
   * methods, specifically [checkForAllFinalInitializedErrorCodes],
   * can make a copy of the map to compute error code states. <code>checkFor*</code> methods should
   * only ever make a copy, or read from this map after it has been set in
   * [visitClassDeclaration].
   *
   * See [visitClassDeclaration], and [_checkForAllFinalInitializedErrorCodes].
   */
  HashMap<FieldElement, INIT_STATE> _initialFieldElementsMap;

  /**
   * A table mapping name of the library to the export directive which export this library.
   */
  HashMap<String, LibraryElement> _nameToExportElement = new HashMap<String, LibraryElement>();

  /**
   * A table mapping name of the library to the import directive which import this library.
   */
  HashMap<String, LibraryElement> _nameToImportElement = new HashMap<String, LibraryElement>();

  /**
   * A table mapping names to the exported elements.
   */
  HashMap<String, Element> _exportedElements = new HashMap<String, Element>();

  /**
   * A set of the names of the variable initializers we are visiting now.
   */
  HashSet<String> _namesForReferenceToDeclaredVariableInInitializer = new HashSet<String>();

  /**
   * A list of types used by the [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS] and
   * [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS] error codes.
   */
  List<InterfaceType> _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT;

  /**
   * Static final string with value `"getter "` used in the construction of the
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE], and similar, error
   * code messages.
   *
   * See [_checkForNonAbstractClassInheritsAbstractMember].
   */
  static String _GETTER_SPACE = "getter ";

  /**
   * Static final string with value `"setter "` used in the construction of the
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE], and similar, error
   * code messages.
   *
   * See [_checkForNonAbstractClassInheritsAbstractMember].
   */
  static String _SETTER_SPACE = "setter ";

  /**
   * Initialize the [ErrorVerifier] visitor.
   */
  ErrorVerifier(this._errorReporter, this._currentLibrary, this._typeProvider, this._inheritanceManager) {
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
    _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT = <InterfaceType> [
        _typeProvider.nullType,
        _typeProvider.numType,
        _intType,
        _typeProvider.doubleType,
        _boolType,
        _typeProvider.stringType];
  }

  @override
  Object visitAnnotation(Annotation node) {
    _checkForInvalidAnnotationFromDeferredLibrary(node);
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
  Object visitAssertStatement(AssertStatement node) {
    _checkForNonBoolExpression(node);
    return super.visitAssertStatement(node);
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    Expression rhs = node.rightHandSide;
    if (operatorType == sc.TokenType.EQ) {
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
      _errorReporter.reportErrorForToken(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, node.awaitKeyword);
    }
    return super.visitAwaitExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType type = operator.type;
    if (type == sc.TokenType.AMPERSAND_AMPERSAND || type == sc.TokenType.BAR_BAR) {
      String lexeme = operator.lexeme;
      _checkForAssignability(node.leftOperand, _boolType, StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
      _checkForAssignability(node.rightOperand, _boolType, StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
    } else {
      _checkForArgumentTypeNotAssignableForArgument(node.rightOperand);
    }
    return super.visitBinaryExpression(node);
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
        _errorReporter.reportErrorForNode(ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode);
      }
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
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
    ClassElement outerClass = _enclosingClass;
    try {
      _isInNativeClass = node.nativeClause != null;
      _enclosingClass = node.element;
      ExtendsClause extendsClause = node.extendsClause;
      ImplementsClause implementsClause = node.implementsClause;
      WithClause withClause = node.withClause;
      _checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForMemberWithClassName();
      _checkForNoDefaultSuperConstructorImplicit(node);
      _checkForConflictingTypeVariableErrorCodes(node);
      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null || extendsClause != null || withClause != null) {
        // Only check for all of the inheritance logic around clauses if there isn't an error code
        // such as "Cannot extend double" already on the class.
        if (!_checkForImplementsDisallowedClass(implementsClause) && !_checkForExtendsDisallowedClass(extendsClause) && !_checkForAllMixinErrorCodes(withClause)) {
          _checkForExtendsDeferredClass(extendsClause);
          _checkForImplementsDeferredClass(implementsClause);
          _checkForNonAbstractClassInheritsAbstractMember(node.name);
          _checkForInconsistentMethodInheritance();
          _checkForRecursiveInterfaceInheritance(_enclosingClass);
          _checkForConflictingGetterAndMethod();
          _checkForConflictingInstanceGetterAndSuperclassMember();
          _checkImplementsSuperClass(node);
          _checkImplementsFunctionWithoutCall(node);
        }
      }
      // initialize initialFieldElementsMap
      if (_enclosingClass != null) {
        List<FieldElement> fieldElements = _enclosingClass.fields;
        _initialFieldElementsMap = new HashMap<FieldElement, INIT_STATE>();
        for (FieldElement fieldElement in fieldElements) {
          if (!fieldElement.isSynthetic) {
            _initialFieldElementsMap[fieldElement] = fieldElement.initializer == null ? INIT_STATE.NOT_INIT : INIT_STATE.INIT_IN_DECLARATION;
          }
        }
      }
      _checkForFinalNotInitializedInClass(node);
      _checkForDuplicateDefinitionInheritance();
      _checkForConflictingInstanceMethodSetter(node);
      return super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _initialFieldElementsMap = null;
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    ClassElement outerClassElement = _enclosingClass;
    try {
      _enclosingClass = node.element;
      ImplementsClause implementsClause = node.implementsClause;
      // Only check for all of the inheritance logic around clauses if there isn't an error code
      // such as "Cannot extend double" already on the class.
      if (!_checkForExtendsDisallowedClassInTypeAlias(node) && !_checkForImplementsDisallowedClass(implementsClause) && !_checkForAllMixinErrorCodes(node.withClause)) {
        _checkForExtendsDeferredClassInTypeAlias(node);
        _checkForImplementsDeferredClass(implementsClause);
        _checkForRecursiveInterfaceInheritance(_enclosingClass);
        _checkForNonAbstractClassInheritsAbstractMember(node.name);
      }
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
      _checkForInvalidModifierOnBody(node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR);
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
      _checkForFieldInitializerNotAssignable(node, staticElement);
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
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchStatement) {
        _errorReporter.reportErrorForNode(ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode);
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
      FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
      DartType expectedReturnType = functionType == null ? DynamicTypeImpl.instance : functionType.returnType;
      _checkForReturnOfInvalidType(node.expression, expectedReturnType);
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
        _errorReporter.reportErrorForToken(CompileTimeErrorCode.CONST_INSTANCE_FIELD, variables.keyword);
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
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier identifier = node.name;
      String methodName = "";
      if (identifier != null) {
        methodName = identifier.name;
      }
      _enclosingFunction = node.element;
      TypeName returnType = node.returnType;
      if (node.isSetter || node.isGetter) {
        _checkForMismatchedAccessorTypes(node, methodName);
        if (node.isSetter) {
          FunctionExpression functionExpression = node.functionExpression;
          if (functionExpression != null) {
            _checkForWrongNumberOfParametersForSetter(identifier, functionExpression.parameters);
          }
          _checkForNonVoidReturnTypeForSetter(returnType);
        }
      }
      if (node.isSetter) {
        _checkForInvalidModifierOnBody(node.functionExpression.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER);
      }
      _checkForTypeAnnotationDeferredClass(returnType);
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    // If this function expression is wrapped in a function declaration, don't change the
    // enclosingFunction field.
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
      _errorReporter.reportErrorForNode(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, functionExpression);
    }
    return super.visitFunctionExpressionInvocation(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
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
  Object visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
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
        InterfaceType interfaceType = type;
        _checkForConstOrNewWithAbstractClass(node, typeName, interfaceType);
        _checkForConstOrNewWithEnum(node, typeName, interfaceType);
        if (_isInConstInstanceCreation) {
          _checkForConstWithNonConst(node);
          _checkForConstWithUndefinedConstructor(node, constructorName, typeName);
          _checkForConstWithTypeParameters(typeName);
          _checkForConstDeferredClass(node, constructorName, typeName);
        } else {
          _checkForNewWithUndefinedConstructor(node, constructorName, typeName);
        }
      }
      return super.visitInstanceCreationExpression(node);
    } finally {
      _isInConstInstanceCreation = wasInConstInstanceCreation;
    }
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    return super.visitIsExpression(node);
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.constKeyword != null) {
        NodeList<TypeName> arguments = typeArguments.arguments;
        if (arguments.length != 0) {
          _checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST);
        }
      }
      _checkForExpectedOneListTypeArgument(node, typeArguments);
      _checkForListElementTypeNotAssignable(node, typeArguments);
    }
    return super.visitListLiteral(node);
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments.length != 0) {
        if (node.constKeyword != null) {
          _checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP);
        }
      }
      _checkExpectedTwoMapTypeArguments(typeArguments);
      _checkForMapTypeNotAssignable(node, typeArguments);
    }
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
      TypeName returnTypeName = node.returnType;
      if (node.isSetter || node.isGetter) {
        _checkForMismatchedAccessorTypes(node, methodName);
      }
      if (node.isGetter) {
        _checkForVoidReturnType(node);
        _checkForConflictingStaticGetterAndInstanceSetter(node);
      } else if (node.isSetter) {
        _checkForInvalidModifierOnBody(node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER);
        _checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        _checkForNonVoidReturnTypeForSetter(returnTypeName);
        _checkForConflictingStaticSetterAndInstanceMember(node);
      } else if (node.isOperator) {
        _checkForOptionalParameterInOperator(node);
        _checkForWrongNumberOfParametersForOperator(node);
        _checkForNonVoidReturnTypeForOperator(node);
      }
      _checkForConcreteClassWithAbstractMember(node);
      _checkForAllInvalidOverrideErrorCodesForMethod(node);
      _checkForTypeAnnotationDeferredClass(returnTypeName);
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
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson) Figure out the right rule for when 'native' is allowed.
    if (!_isInSystemLibrary) {
      _errorReporter.reportErrorForNode(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, node);
    }
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSDKCode(node);
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
      ClassElement typeReference = ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, name);
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
    if (operatorType == sc.TokenType.BANG) {
      _checkForNonBoolNegationExpression(operand);
    } else if (operatorType.isIncrementOperator) {
      _checkForAssignmentToFinal(operand);
    }
    _checkForIntNotAssignable(operand);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    ClassElement typeReference = ElementResolver.getTypeReference(node.realTarget);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(typeReference, propertyName);
    return super.visitPropertyAccess(node);
  }

  @override
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
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
    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
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
    NodeList<TypeName> list = node.arguments;
    for (TypeName typeName in list) {
      _checkForTypeAnnotationDeferredClass(typeName);
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
    _checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    _checkForTypeParameterSupertypeOfItsBound(node);
    _checkForTypeAnnotationDeferredClass(node.bound);
    return super.visitTypeParameter(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    Expression initializerNode = node.initializer;
    // do checks
    _checkForInvalidAssignment(nameNode, initializerNode);
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
  Object visitYieldStatement(YieldStatement node) {
    if (!_inGenerator) {
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
   * This verifies if the passed map literal has type arguments then there is exactly two.
   *
   * @param typeArguments the type arguments, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS].
   */
  bool _checkExpectedTwoMapTypeArguments(TypeArgumentList typeArguments) {
    // check number of type arguments
    int num = typeArguments.arguments.length;
    if (num == 2) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, typeArguments, [num]);
    return true;
  }

  /**
   * This verifies that the passed constructor declaration does not violate any of the error codes
   * relating to the initialization of fields in the enclosing class.
   *
   * @param node the [ConstructorDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [_initialFieldElementsMap],
   * [StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR],
   * and [CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES].
   */
  bool _checkForAllFinalInitializedErrorCodes(ConstructorDeclaration node) {
    if (node.factoryKeyword != null || node.redirectedConstructor != null || node.externalKeyword != null) {
      return false;
    }
    // Ignore if native class.
    if (_isInNativeClass) {
      return false;
    }
    bool foundError = false;
    HashMap<FieldElement, INIT_STATE> fieldElementsMap = new HashMap<FieldElement, INIT_STATE>.from(_initialFieldElementsMap);
    // Visit all of the field formal parameters
    NodeList<FormalParameter> formalParameters = node.parameters.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      FormalParameter parameter = formalParameter;
      if (parameter is DefaultFormalParameter) {
        parameter = (parameter as DefaultFormalParameter).parameter;
      }
      if (parameter is FieldFormalParameter) {
        FieldElement fieldElement = (parameter.element as FieldFormalParameterElementImpl).field;
        INIT_STATE state = fieldElementsMap[fieldElement];
        if (state == INIT_STATE.NOT_INIT) {
          fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_FIELD_FORMAL;
        } else if (state == INIT_STATE.INIT_IN_DECLARATION) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportErrorForNode(StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        } else if (state == INIT_STATE.INIT_IN_FIELD_FORMAL) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        }
      }
    }
    // Visit all of the initializers
    NodeList<ConstructorInitializer> initializers = node.initializers;
    for (ConstructorInitializer constructorInitializer in initializers) {
      if (constructorInitializer is RedirectingConstructorInvocation) {
        return false;
      }
      if (constructorInitializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = constructorInitializer;
        SimpleIdentifier fieldName = constructorFieldInitializer.fieldName;
        Element element = fieldName.staticElement;
        if (element is FieldElement) {
          FieldElement fieldElement = element;
          INIT_STATE state = fieldElementsMap[fieldElement];
          if (state == INIT_STATE.NOT_INIT) {
            fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_INITIALIZERS;
          } else if (state == INIT_STATE.INIT_IN_DECLARATION) {
            if (fieldElement.isFinal || fieldElement.isConst) {
              _errorReporter.reportErrorForNode(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, fieldName);
              foundError = true;
            }
          } else if (state == INIT_STATE.INIT_IN_FIELD_FORMAL) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER, fieldName);
            foundError = true;
          } else if (state == INIT_STATE.INIT_IN_INITIALIZERS) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, fieldName, [fieldElement.displayName]);
            foundError = true;
          }
        }
      }
    }
    // Visit all of the states in the map to ensure that none were never
    // initialized.
    fieldElementsMap.forEach((FieldElement fieldElement, INIT_STATE state) {
      if (state == INIT_STATE.NOT_INIT) {
        if (fieldElement.isConst) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
                  node.returnType,
                  [fieldElement.name]);
          foundError = true;
        } else if (fieldElement.isFinal) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.FINAL_NOT_INITIALIZED,
                  node.returnType,
                  [fieldElement.name]);
          foundError = true;
        }
      }
    });
    return foundError;
  }

  /**
   * This checks the passed executable element against override-error codes.
   *
   * @param executableElement a non-null [ExecutableElement] to evaluate
   * @param overriddenExecutable the element that the executableElement is overriding
   * @param parameters the parameters of the executable element
   * @param errorNameTarget the node to report problems on
   * @return `true` if and only if an error code is generated on the passed node
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
  bool _checkForAllInvalidOverrideErrorCodes(ExecutableElement executableElement, ExecutableElement overriddenExecutable, List<ParameterElement> parameters, List<AstNode> parameterLocations, SimpleIdentifier errorNameTarget) {
    bool isGetter = false;
    bool isSetter = false;
    if (executableElement is PropertyAccessorElement) {
      PropertyAccessorElement accessorElement = executableElement;
      isGetter = accessorElement.isGetter;
      isSetter = accessorElement.isSetter;
    }
    String executableElementName = executableElement.name;
    FunctionType overridingFT = executableElement.type;
    FunctionType overriddenFT = overriddenExecutable.type;
    InterfaceType enclosingType = _enclosingClass.type;
    overriddenFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(overriddenFT, executableElementName, enclosingType);
    if (overridingFT == null || overriddenFT == null) {
      return false;
    }
    DartType overridingFTReturnType = overridingFT.returnType;
    DartType overriddenFTReturnType = overriddenFT.returnType;
    List<DartType> overridingNormalPT = overridingFT.normalParameterTypes;
    List<DartType> overriddenNormalPT = overriddenFT.normalParameterTypes;
    List<DartType> overridingPositionalPT = overridingFT.optionalParameterTypes;
    List<DartType> overriddenPositionalPT = overriddenFT.optionalParameterTypes;
    Map<String, DartType> overridingNamedPT = overridingFT.namedParameterTypes;
    Map<String, DartType> overriddenNamedPT = overriddenFT.namedParameterTypes;
    // CTEC.INVALID_OVERRIDE_REQUIRED, CTEC.INVALID_OVERRIDE_POSITIONAL and CTEC.INVALID_OVERRIDE_NAMED
    if (overridingNormalPT.length > overriddenNormalPT.length) {
      _errorReporter.reportErrorForNode(StaticWarningCode.INVALID_OVERRIDE_REQUIRED, errorNameTarget, [
          overriddenNormalPT.length,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    if (overridingNormalPT.length + overridingPositionalPT.length < overriddenPositionalPT.length + overriddenNormalPT.length) {
      _errorReporter.reportErrorForNode(StaticWarningCode.INVALID_OVERRIDE_POSITIONAL, errorNameTarget, [
          overriddenPositionalPT.length + overriddenNormalPT.length,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    // For each named parameter in the overridden method, verify that there is
    // the same name in the overriding method.
    for (String overriddenParamName in overriddenNamedPT.keys) {
      if (!overridingNamedPT.containsKey(overriddenParamName)) {
        // The overridden method expected the overriding method to have
        // overridingParamName, but it does not.
        _errorReporter.reportErrorForNode(
            StaticWarningCode.INVALID_OVERRIDE_NAMED,
            errorNameTarget,
            [overriddenParamName,
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
    }
    // SWC.INVALID_METHOD_OVERRIDE_RETURN_TYPE
    if (overriddenFTReturnType != VoidTypeImpl.instance && !overridingFTReturnType.isAssignableTo(overriddenFTReturnType)) {
      _errorReporter.reportTypeErrorForNode(!isGetter ? StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE : StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE, errorNameTarget, [
          overridingFTReturnType,
          overriddenFTReturnType,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
    if (parameterLocations == null) {
      return false;
    }
    int parameterIndex = 0;
    for (int i = 0; i < overridingNormalPT.length; i++) {
      if (!overridingNormalPT[i].isAssignableTo(overriddenNormalPT[i])) {
        _errorReporter.reportTypeErrorForNode(!isSetter ? StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE : StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE, parameterLocations[parameterIndex], [
            overridingNormalPT[i],
            overriddenNormalPT[i],
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE
    for (int i = 0; i < overriddenPositionalPT.length; i++) {
      if (!overridingPositionalPT[i].isAssignableTo(overriddenPositionalPT[i])) {
        _errorReporter.reportTypeErrorForNode(StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE, parameterLocations[parameterIndex], [
            overridingPositionalPT[i],
            overriddenPositionalPT[i],
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE & SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    for (String overriddenName in overriddenNamedPT.keys) {
      DartType overridingType = overridingNamedPT[overriddenName];
      if (overridingType == null) {
        // Error, this is never reached- INVALID_OVERRIDE_NAMED would have been
        // created above if this could be reached.
        continue;
      }
      DartType overriddenType = overriddenNamedPT[overriddenName];
      if (!overriddenType.isAssignableTo(overridingType)) {
        // lookup the parameter for the error to select
        ParameterElement parameterToSelect = null;
        AstNode parameterLocationToSelect = null;
        for (int i = 0; i < parameters.length; i++) {
          ParameterElement parameter = parameters[i];
          if (parameter.parameterKind == ParameterKind.NAMED
              && overriddenName == parameter.name) {
            parameterToSelect = parameter;
            parameterLocationToSelect = parameterLocations[i];
            break;
          }
        }
        if (parameterToSelect != null) {
          _errorReporter.reportTypeErrorForNode(
              StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE,
              parameterLocationToSelect,
              [overridingType,
              overriddenType,
              overriddenExecutable.enclosingElement.displayName]);
          return true;
        }
      }
    }
    // SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    //
    // Create three arrays: an array of the optional parameter ASTs (FormalParameters), an array of
    // the optional parameters elements from our method, and finally an array of the optional
    // parameter elements from the method we are overriding.
    //
    bool foundError = false;
    List<AstNode> formalParameters = new List<AstNode>();
    List<ParameterElementImpl> parameterElts = new List<ParameterElementImpl>();
    List<ParameterElementImpl> overriddenParameterElts = new List<ParameterElementImpl>();
    List<ParameterElement> overriddenPEs = overriddenExecutable.parameters;
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
    // Next compare the list of optional parameter elements to the list of overridden optional
    // parameter elements.
    //
    if (parameterElts.length > 0) {
      if (parameterElts[0].parameterKind == ParameterKind.NAMED) {
        // Named parameters, consider the names when matching the parameterElts to the overriddenParameterElts
        for (int i = 0; i < parameterElts.length; i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (_isUserDefinedObject(result)) {
            continue;
          }
          String parameterName = parameterElt.name;
          for (int j = 0; j < overriddenParameterElts.length; j++) {
            ParameterElementImpl overriddenParameterElt = overriddenParameterElts[j];
            if (overriddenParameterElt.initializer == null) {
              // There is no warning if the overridden parameter has an
              // implicit default.
              continue;
            }
            String overriddenParameterName = overriddenParameterElt.name;
            if (parameterName != null && parameterName == overriddenParameterName) {
              EvaluationResultImpl overriddenResult = overriddenParameterElt.evaluationResult;
              if (_isUserDefinedObject(overriddenResult)) {
                break;
              }
              if (!result.equalValues(_typeProvider, overriddenResult)) {
                _errorReporter.reportErrorForNode(StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED, formalParameters[i], [
                    overriddenExecutable.enclosingElement.displayName,
                    overriddenExecutable.displayName,
                    parameterName]);
                foundError = true;
              }
            }
          }
        }
      } else {
        // Positional parameters, consider the positions when matching the parameterElts to the overriddenParameterElts
        for (int i = 0; i < parameterElts.length && i < overriddenParameterElts.length; i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (_isUserDefinedObject(result)) {
            continue;
          }
          ParameterElementImpl overriddenParameterElt = overriddenParameterElts[i];
          if (overriddenParameterElt.initializer == null) {
            // There is no warning if the overridden parameter has an implicit
            // default.
            continue;
          }
          EvaluationResultImpl overriddenResult = overriddenParameterElt.evaluationResult;
          if (_isUserDefinedObject(overriddenResult)) {
            continue;
          }
          if (!result.equalValues(_typeProvider, overriddenResult)) {
            _errorReporter.reportErrorForNode(StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL, formalParameters[i], [
                overriddenExecutable.enclosingElement.displayName,
                overriddenExecutable.displayName]);
            foundError = true;
          }
        }
      }
    }
    return foundError;
  }

  /**
   * This checks the passed executable element against override-error codes. This method computes
   * the passed executableElement is overriding and calls
   * [checkForAllInvalidOverrideErrorCodes]
   * when the [InheritanceManager] returns a [MultiplyInheritedExecutableElement], this
   * method loops through the array in the [MultiplyInheritedExecutableElement].
   *
   * @param executableElement a non-null [ExecutableElement] to evaluate
   * @param parameters the parameters of the executable element
   * @param errorNameTarget the node to report problems on
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool _checkForAllInvalidOverrideErrorCodesForExecutable(ExecutableElement executableElement, List<ParameterElement> parameters, List<AstNode> parameterLocations, SimpleIdentifier errorNameTarget) {
    //
    // Compute the overridden executable from the InheritanceManager
    //
    List<ExecutableElement> overriddenExecutables = _inheritanceManager.lookupOverrides(_enclosingClass, executableElement.name);
    if (_checkForInstanceMethodNameCollidesWithSuperclassStatic(
        executableElement, errorNameTarget)) {
      return true;
    }
    for (ExecutableElement overriddenElement in overriddenExecutables) {
      if (_checkForAllInvalidOverrideErrorCodes(executableElement, overriddenElement, parameters, parameterLocations, errorNameTarget)) {
        return true;
      }
    }
    return false;
  }

  /**
   * This checks the passed field declaration against override-error codes.
   *
   * @param node the [MethodDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [_checkForAllInvalidOverrideErrorCodes].
   */
  bool _checkForAllInvalidOverrideErrorCodesForField(FieldDeclaration node) {
    if (_enclosingClass == null || node.isStatic) {
      return false;
    }
    bool hasProblems = false;
    VariableDeclarationList fields = node.fields;
    for (VariableDeclaration field in fields.variables) {
      FieldElement element = field.element as FieldElement;
      if (element == null) {
        continue;
      }
      PropertyAccessorElement getter = element.getter;
      PropertyAccessorElement setter = element.setter;
      SimpleIdentifier fieldName = field.name;
      if (getter != null) {
        if (_checkForAllInvalidOverrideErrorCodesForExecutable(
            getter,
            ParameterElementImpl.EMPTY_ARRAY,
            AstNode.EMPTY_ARRAY,
            fieldName)) {
          hasProblems = true;
        }
      }
      if (setter != null) {
        if (_checkForAllInvalidOverrideErrorCodesForExecutable(
            setter,
            setter.parameters,
            <AstNode> [fieldName],
            fieldName)) {
          hasProblems = true;
        }
      }
    }
    return hasProblems;
  }

  /**
   * This checks the passed method declaration against override-error codes.
   *
   * @param node the [MethodDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [_checkForAllInvalidOverrideErrorCodes].
   */
  bool _checkForAllInvalidOverrideErrorCodesForMethod(MethodDeclaration node) {
    if (_enclosingClass == null || node.isStatic || node.body is NativeFunctionBody) {
      return false;
    }
    ExecutableElement executableElement = node.element;
    if (executableElement == null) {
      return false;
    }
    SimpleIdentifier methodName = node.name;
    if (methodName.isSynthetic) {
      return false;
    }
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameterList = formalParameterList != null ? formalParameterList.parameters : null;
    List<AstNode> parameters = parameterList != null ? new List.from(parameterList) : null;
    return _checkForAllInvalidOverrideErrorCodesForExecutable(executableElement, executableElement.parameters, parameters, methodName);
  }

  /**
   * This verifies that all classes of the passed 'with' clause are valid.
   *
   * @param node the 'with' clause to evaluate
   * @return `true` if and only if an error code is generated on the passed node
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
      if (mixinType is! InterfaceType) {
        continue;
      }
      if (_checkForExtendsOrImplementsDisallowedClass(
          mixinName,
          CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
        problemReported = true;
      } else {
        ClassElement mixinElement = (mixinType as InterfaceType).element;
        if (_checkForExtendsOrImplementsDeferredClass(
            mixinName,
            CompileTimeErrorCode.MIXIN_DEFERRED_CLASS)) {
          problemReported = true;
        }
        if (_checkForMixinDeclaresConstructor(mixinName, mixinElement)) {
          problemReported = true;
        }
        if (_checkForMixinInheritsNotFromObject(mixinName, mixinElement)) {
          problemReported = true;
        }
        if (_checkForMixinReferencesSuper(mixinName, mixinElement)) {
          problemReported = true;
        }
      }
    }
    return problemReported;
  }

  /**
   * This checks error related to the redirected constructors.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE],
   * [StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE], and
   * [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR].
   */
  bool _checkForAllRedirectConstructorErrorCodes(ConstructorDeclaration node) {
    //
    // Prepare redirected constructor node
    //
    ConstructorName redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor == null) {
      return false;
    }
    //
    // Prepare redirected constructor type
    //
    ConstructorElement redirectedElement = redirectedConstructor.staticElement;
    if (redirectedElement == null) {
      //
      // If the element is null, we check for the REDIRECT_TO_MISSING_CONSTRUCTOR case
      //
      TypeName constructorTypeName = redirectedConstructor.type;
      DartType redirectedType = constructorTypeName.type;
      if (redirectedType != null && redirectedType.element != null && !redirectedType.isDynamic) {
        //
        // Prepare the constructor name
        //
        String constructorStrName = constructorTypeName.name.name;
        if (redirectedConstructor.name != null) {
          constructorStrName += ".${redirectedConstructor.name.name}";
        }
        ErrorCode errorCode = (node.constKeyword != null ? CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR : StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR);
        _errorReporter.reportErrorForNode(errorCode, redirectedConstructor, [constructorStrName, redirectedType.displayName]);
        return true;
      }
      return false;
    }
    FunctionType redirectedType = redirectedElement.type;
    DartType redirectedReturnType = redirectedType.returnType;
    //
    // Report specific problem when return type is incompatible
    //
    FunctionType constructorType = node.element.type;
    DartType constructorReturnType = constructorType.returnType;
    if (!redirectedReturnType.isAssignableTo(constructorReturnType)) {
      _errorReporter.reportErrorForNode(StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, redirectedConstructor, [redirectedReturnType, constructorReturnType]);
      return true;
    }
    //
    // Check parameters
    //
    if (!redirectedType.isSubtypeOf(constructorType)) {
      _errorReporter.reportErrorForNode(StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, redirectedConstructor, [redirectedType, constructorType]);
      return true;
    }
    return false;
  }

  /**
   * This checks that the return statement of the form <i>return e;</i> is not in a generative
   * constructor.
   *
   * This checks that return statements without expressions are not in a generative constructor and
   * the return type is not assignable to `null`; that is, we don't have `return;` if
   * the enclosing method has a return type.
   *
   * This checks that the return type matches the type of the declared return type in the enclosing
   * method or function.
   *
   * @param node the return statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR],
   * [StaticWarningCode.RETURN_WITHOUT_VALUE], and
   * [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE].
   */
  bool _checkForAllReturnStatementErrorCodes(ReturnStatement node) {
    FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
    DartType expectedReturnType = functionType == null ? DynamicTypeImpl.instance : functionType.returnType;
    Expression returnExpression = node.expression;
    // RETURN_IN_GENERATIVE_CONSTRUCTOR
    bool isGenerativeConstructor = _enclosingFunction is ConstructorElement && !(_enclosingFunction as ConstructorElement).isFactory;
    if (isGenerativeConstructor) {
      if (returnExpression == null) {
        return false;
      }
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, returnExpression);
      return true;
    }
    // RETURN_WITHOUT_VALUE
    if (returnExpression == null) {
      if (VoidTypeImpl.instance.isAssignableTo(expectedReturnType)) {
        return false;
      }
      _hasReturnWithoutValue = true;
      _errorReporter.reportErrorForNode(StaticWarningCode.RETURN_WITHOUT_VALUE, node);
      return true;
    } else if (_inGenerator) {
      // RETURN_IN_GENERATOR
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.RETURN_IN_GENERATOR, node);
    }
    // RETURN_OF_INVALID_TYPE
    return _checkForReturnOfInvalidType(returnExpression, expectedReturnType);
  }

  /**
   * This verifies that the export namespace of the passed export directive does not export any name
   * already exported by other export directive.
   *
   * @param node the export directive node to report problem on
   * @param exportElement the [ExportElement] retrieved from the node, if the element in the
   *          node was `null`, then this method is not called
   * @param exportedLibrary the library element containing the exported element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.AMBIGUOUS_EXPORT].
   */
  bool _checkForAmbiguousExport(ExportDirective node, ExportElement exportElement, LibraryElement exportedLibrary) {
    if (exportedLibrary == null) {
      return false;
    }
    // check exported names
    Namespace namespace = new NamespaceBuilder().createExportNamespaceForDirective(exportElement);
    Map<String, Element> definedNames = namespace.definedNames;
    for (String name in definedNames.keys) {
      Element element = definedNames[name];
      Element prevElement = _exportedElements[name];
      if (element != null && prevElement != null && prevElement != element) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.AMBIGUOUS_EXPORT, node, [
            name,
            prevElement.library.definingCompilationUnit.displayName,
            element.library.definingCompilationUnit.displayName]);
        return true;
      } else {
        _exportedElements[name] = element;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * This method corresponds to BestPracticesVerifier.checkForArgumentTypeNotAssignable.
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type of the parameter
   * @param actualStaticType the actual static type of the argument
   * @param expectedPropagatedType the expected propagated type of the parameter, may be
   *          `null`
   * @param actualPropagatedType the expected propagated type of the parameter, may be `null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignable(Expression expression, DartType expectedStaticType, DartType actualStaticType, ErrorCode errorCode) {
    //
    // Warning case: test static type information
    //
    if (actualStaticType != null && expectedStaticType != null) {
      if (!actualStaticType.isAssignableTo(expectedStaticType)) {
        _errorReporter.reportTypeErrorForNode(errorCode, expression, [actualStaticType, expectedStaticType]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed argument can be assigned to its corresponding parameter.
   *
   * This method corresponds to BestPracticesVerifier.checkForArgumentTypeNotAssignableForArgument.
   *
   * @param argument the argument to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignableForArgument(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    DartType staticParameterType = staticParameterElement == null ? null : staticParameterElement.type;
    return _checkForArgumentTypeNotAssignableWithExpectedTypes(argument, staticParameterType, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * This method corresponds to
   * BestPracticesVerifier.checkForArgumentTypeNotAssignableWithExpectedTypes.
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type
   * @param expectedPropagatedType the expected propagated type, may be `null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForArgumentTypeNotAssignableWithExpectedTypes(Expression expression, DartType expectedStaticType, ErrorCode errorCode) => _checkForArgumentTypeNotAssignable(expression, expectedStaticType, getStaticType(expression), errorCode);

  /**
   * This verifies that the passed arguments can be assigned to their corresponding parameters.
   *
   * This method corresponds to BestPracticesVerifier.checkForArgumentTypesNotAssignableInList.
   *
   * @param node the arguments to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
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
   * Check that the static type of the given expression is assignable to the given type. If it
   * isn't, report an error with the given error code.
   *
   * @param expression the expression being tested
   * @param type the type that the expression must be assignable to
   * @param errorCode the error code to be reported
   * @param arguments the arguments to pass in when creating the error
   * @return `true` if an error was reported
   */
  bool _checkForAssignability(Expression expression, InterfaceType type, ErrorCode errorCode, List<Object> arguments) {
    if (expression == null) {
      return false;
    }
    DartType expressionType = expression.staticType;
    if (expressionType == null) {
      return false;
    }
    if (expressionType.isAssignableTo(type)) {
      return false;
    }
    _errorReporter.reportErrorForNode(errorCode, expression, arguments);
    return true;
  }

  /**
   * This verifies that the passed expression is not final.
   *
   * @param node the expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ASSIGNMENT_TO_CONST],
   * [StaticWarningCode.ASSIGNMENT_TO_FINAL], and
   * [StaticWarningCode.ASSIGNMENT_TO_METHOD].
   */
  bool _checkForAssignmentToFinal(Expression expression) {
    // prepare element
    Element element = null;
    AstNode highlightedNode = expression;
    if (expression is Identifier) {
      element = expression.staticElement;
      if (expression is PrefixedIdentifier) {
        highlightedNode = expression.identifier;
      }
    } else if (expression is PropertyAccess) {
      PropertyAccess propertyAccess = expression;
      element = propertyAccess.propertyName.staticElement;
      highlightedNode = propertyAccess.propertyName;
    }
    // check if element is assignable
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      element = accessor.variable;
    }
    if (element is VariableElement) {
      VariableElement variable = element as VariableElement;
      if (variable.isConst) {
        _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_CONST, expression);
        return true;
      }
      if (variable.isFinal) {
        if (variable is FieldElementImpl && variable.setter == null && variable.isSynthetic) {
          _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER, highlightedNode, [variable.name, variable.enclosingElement.displayName]);
          return true;
        }
        _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_FINAL, highlightedNode, [variable.name]);
        return true;
      }
      return false;
    }
    if (element is FunctionElement) {
      _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_FUNCTION, expression);
      return true;
    }
    if (element is MethodElement) {
      _errorReporter.reportErrorForNode(StaticWarningCode.ASSIGNMENT_TO_METHOD, expression);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed identifier is not a keyword, and generates the passed error code
   * on the identifier if it is a keyword.
   *
   * @param identifier the identifier to check to ensure that it is not a keyword
   * @param errorCode if the passed identifier is a keyword then this error code is created on the
   *          identifier, the error code will be one of
   *          [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
   *          [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME] or
   *          [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
   * [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME], and
   * [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME].
   */
  bool _checkForBuiltInIdentifierAsName(SimpleIdentifier identifier, ErrorCode errorCode) {
    sc.Token token = identifier.token;
    if (token.type == sc.TokenType.KEYWORD) {
      _errorReporter.reportErrorForNode(errorCode, identifier, [identifier.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the given switch case is terminated with 'break', 'continue', 'return' or
   * 'throw'.
   *
   * @param node the switch case to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * see [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED].
   */
  bool _checkForCaseBlockNotTerminated(SwitchCase node) {
    NodeList<Statement> statements = node.statements;
    if (statements.isEmpty) {
      // fall-through without statements at all
      AstNode parent = node.parent;
      if (parent is SwitchStatement) {
        SwitchStatement switchStatement = parent;
        NodeList<SwitchMember> members = switchStatement.members;
        int index = members.indexOf(node);
        if (index != -1 && index < members.length - 1) {
          return false;
        }
      }
      // no other switch member after this one
    } else {
      Statement statement = statements[statements.length - 1];
      // terminated with statement
      if (statement is BreakStatement || statement is ContinueStatement || statement is ReturnStatement) {
        return false;
      }
      // terminated with 'throw' expression
      if (statement is ExpressionStatement) {
        Expression expression = statement.expression;
        if (expression is ThrowExpression) {
          return false;
        }
      }
    }
    // report error
    _errorReporter.reportErrorForToken(StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, node.keyword);
    return true;
  }

  /**
   * This verifies that the switch cases in the given switch statement is terminated with 'break',
   * 'continue', 'return' or 'throw'.
   *
   * @param node the switch statement containing the cases to be checked
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED].
   */
  bool _checkForCaseBlocksNotTerminated(SwitchStatement node) {
    bool foundError = false;
    NodeList<SwitchMember> members = node.members;
    int lastMember = members.length - 1;
    for (int i = 0; i < lastMember; i++) {
      SwitchMember member = members[i];
      if (member is SwitchCase && _checkForCaseBlockNotTerminated(member)) {
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed method declaration is abstract only if the enclosing class is
   * also abstract.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER].
   */
  bool _checkForConcreteClassWithAbstractMember(MethodDeclaration node) {
    if (node.isAbstract && _enclosingClass != null && !_enclosingClass.isAbstract) {
      SimpleIdentifier nameNode = node.name;
      String memberName = nameNode.name;
      ExecutableElement overriddenMember;
      if (node.isGetter) {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteGetter(memberName, _currentLibrary);
      } else if (node.isSetter) {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteSetter(memberName, _currentLibrary);
      } else {
        overriddenMember = _enclosingClass.lookUpInheritedConcreteMethod(memberName, _currentLibrary);
      }
      if (overriddenMember == null) {
        _errorReporter.reportErrorForNode(StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, nameNode, [memberName, _enclosingClass.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies all possible conflicts of the constructor name with other constructors and
   * members of the same class.
   *
   * @param node the constructor declaration to evaluate
   * @param constructorElement the constructor element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT],
   * [CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME],
   * [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD], and
   * [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD].
   */
  bool _checkForConflictingConstructorNameAndMember(ConstructorDeclaration node, ConstructorElement constructorElement) {
    SimpleIdentifier constructorName = node.name;
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
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, node);
        } else {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, node, [name]);
        }
        return true;
      }
    }
    // conflict with class member
    if (constructorName != null && constructorElement != null && !constructorName.isSynthetic) {
      // fields
      FieldElement field = classElement.getField(name);
      if (field != null) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, node, [name]);
        return true;
      }
      // methods
      MethodElement method = classElement.getMethod(name);
      if (method != null) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, node, [name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the [enclosingClass] does not have a method and getter pair with the
   * same name on, via inheritance.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD], and
   * [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER].
   */
  bool _checkForConflictingGetterAndMethod() {
    if (_enclosingClass == null) {
      return false;
    }
    bool hasProblem = false;
    // method declared in the enclosing class vs. inherited getter
    for (MethodElement method in _enclosingClass.methods) {
      String name = method.name;
      // find inherited property accessor (and can be only getter)
      ExecutableElement inherited = _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! PropertyAccessorElement) {
        continue;
      }
      // report problem
      hasProblem = true;
      _errorReporter.reportErrorForOffset(CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD, method.nameOffset, name.length, [
          _enclosingClass.displayName,
          inherited.enclosingElement.displayName,
          name]);
    }
    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (!accessor.isGetter) {
        continue;
      }
      String name = accessor.name;
      // find inherited method
      ExecutableElement inherited = _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! MethodElement) {
        continue;
      }
      // report problem
      hasProblem = true;
      _errorReporter.reportErrorForOffset(CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER, accessor.nameOffset, name.length, [
          _enclosingClass.displayName,
          inherited.enclosingElement.displayName,
          name]);
    }
    // done
    return hasProblem;
  }

  /**
   * This verifies that the superclass of the [enclosingClass] does not declare accessible
   * static members with the same name as the instance getters/setters declared in
   * [enclosingClass].
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER], and
   * [StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER].
   */
  bool _checkForConflictingInstanceGetterAndSuperclassMember() {
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // check every accessor
    bool hasProblem = false;
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      // we analyze instance accessors here
      if (accessor.isStatic) {
        continue;
      }
      // prepare accessor properties
      String name = accessor.displayName;
      bool getter = accessor.isGetter;
      // if non-final variable, ignore setter - we alreay reported problem for getter
      if (accessor.isSetter && accessor.isSynthetic) {
        continue;
      }
      // try to find super element
      ExecutableElement superElement;
      superElement = enclosingType.lookUpGetterInSuperclass(name, _currentLibrary);
      if (superElement == null) {
        superElement = enclosingType.lookUpSetterInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        superElement = enclosingType.lookUpMethodInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        continue;
      }
      // OK, not static
      if (!superElement.isStatic) {
        continue;
      }
      // prepare "super" type to report its name
      ClassElement superElementClass = superElement.enclosingElement as ClassElement;
      InterfaceType superElementType = superElementClass.type;
      // report problem
      hasProblem = true;
      if (getter) {
        _errorReporter.reportErrorForElement(StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER, accessor, [superElementType.displayName]);
      } else {
        _errorReporter.reportErrorForElement(StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER, accessor, [superElementType.displayName]);
      }
    }
    // done
    return hasProblem;
  }

  /**
   * This verifies that the enclosing class does not have a setter with the same name as the passed
   * instance method declaration.
   *
   * TODO(jwren) add other "conflicting" error codes into algorithm/ data structure
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER].
   */
  bool _checkForConflictingInstanceMethodSetter(ClassDeclaration node) {
    // Reference all of the class members in this class.
    NodeList<ClassMember> classMembers = node.members;
    if (classMembers.isEmpty) {
      return false;
    }
    // Create a HashMap to track conflicting members, and then loop through members in the class to
    // construct the HashMap, at the same time, look for violations.  Don't add members if they are
    // part of a conflict, this prevents multiple warnings for one issue.
    bool foundError = false;
    HashMap<String, ClassMember> memberHashMap = new HashMap<String, ClassMember>();
    for (ClassMember classMember in classMembers) {
      if (classMember is MethodDeclaration) {
        MethodDeclaration method = classMember;
        if (method.isStatic) {
          continue;
        }
        // prepare name
        SimpleIdentifier name = method.name;
        if (name == null) {
          continue;
        }
        bool addThisMemberToTheMap = true;
        bool isGetter = method.isGetter;
        bool isSetter = method.isSetter;
        bool isOperator = method.isOperator;
        bool isMethod = !isGetter && !isSetter && !isOperator;
        // Do lookups in the enclosing class (and the inherited member) if the member is a method or
        // a setter for StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER warning.
        if (isMethod) {
          String setterName = "${name.name}=";
          Element enclosingElementOfSetter = null;
          ClassMember conflictingSetter = memberHashMap[setterName];
          if (conflictingSetter != null) {
            enclosingElementOfSetter = conflictingSetter.element.enclosingElement;
          } else {
            ExecutableElement elementFromInheritance = _inheritanceManager.lookupInheritance(_enclosingClass, setterName);
            if (elementFromInheritance != null) {
              enclosingElementOfSetter = elementFromInheritance.enclosingElement;
            }
          }
          if (enclosingElementOfSetter != null) {
            // report problem
            _errorReporter.reportErrorForNode(StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER, name, [
                _enclosingClass.displayName,
                name.name,
                enclosingElementOfSetter.displayName]);
            foundError = true;
            addThisMemberToTheMap = false;
          }
        } else if (isSetter) {
          String methodName = name.name;
          ClassMember conflictingMethod = memberHashMap[methodName];
          if (conflictingMethod != null && conflictingMethod is MethodDeclaration && !conflictingMethod.isGetter) {
            // report problem
            _errorReporter.reportErrorForNode(StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER2, name, [_enclosingClass.displayName, name.name]);
            foundError = true;
            addThisMemberToTheMap = false;
          }
        }
        // Finally, add this member into the HashMap.
        if (addThisMemberToTheMap) {
          if (method.isSetter) {
            memberHashMap["${name.name}="] = method;
          } else {
            memberHashMap[name.name] = method;
          }
        }
      }
    }
    return foundError;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER].
   */
  bool _checkForConflictingStaticGetterAndInstanceSetter(MethodDeclaration node) {
    if (!node.isStatic) {
      return false;
    }
    // prepare name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // try to find setter
    ExecutableElement setter = enclosingType.lookUpSetter(name, _currentLibrary);
    if (setter == null) {
      return false;
    }
    // OK, also static
    if (setter.isStatic) {
      return false;
    }
    // prepare "setter" type to report its name
    ClassElement setterClass = setter.enclosingElement as ClassElement;
    InterfaceType setterType = setterClass.type;
    // report problem
    _errorReporter.reportErrorForNode(StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER, nameNode, [setterType.displayName]);
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER].
   */
  bool _checkForConflictingStaticSetterAndInstanceMember(MethodDeclaration node) {
    if (!node.isStatic) {
      return false;
    }
    // prepare name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return false;
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
      return false;
    }
    // OK, also static
    if (member.isStatic) {
      return false;
    }
    // prepare "member" type to report its name
    ClassElement memberClass = member.enclosingElement as ClassElement;
    InterfaceType memberType = memberClass.type;
    // report problem
    _errorReporter.reportErrorForNode(StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER, nameNode, [memberType.displayName]);
    return true;
  }

  /**
   * This verifies all conflicts between type variable and enclosing class. TODO(scheglov)
   *
   * @param node the class declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS], and
   * [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER].
   */
  bool _checkForConflictingTypeVariableErrorCodes(ClassDeclaration node) {
    bool problemReported = false;
    for (TypeParameterElement typeParameter in _enclosingClass.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingClass.name == name) {
        _errorReporter.reportErrorForOffset(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, typeParameter.nameOffset, name.length, [name]);
        problemReported = true;
      }
      // check members
      if (_enclosingClass.getMethod(name) != null || _enclosingClass.getGetter(name) != null || _enclosingClass.getSetter(name) != null) {
        _errorReporter.reportErrorForOffset(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, typeParameter.nameOffset, name.length, [name]);
        problemReported = true;
      }
    }
    return problemReported;
  }

  /**
   * This verifies that if the passed constructor declaration is 'const' then there are no
   * invocations of non-'const' super constructors.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER].
   */
  bool _checkForConstConstructorWithNonConstSuper(ConstructorDeclaration node) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    // OK, const factory, checked elsewhere
    if (node.factoryKeyword != null) {
      return false;
    }
    // check for mixins
    if (_enclosingClass.mixins.length != 0) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN, node.returnType);
      return true;
    }
    // try to find and check super constructor invocation
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation superInvocation = initializer;
        ConstructorElement element = superInvocation.staticElement;
        if (element == null || element.isConst) {
          return false;
        }
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, superInvocation, [element.enclosingElement.displayName]);
        return true;
      }
    }
    // no explicit super constructor invocation, check default constructor
    InterfaceType supertype = _enclosingClass.supertype;
    if (supertype == null) {
      return false;
    }
    if (supertype.isObject) {
      return false;
    }
    ConstructorElement unnamedConstructor = supertype.element.unnamedConstructor;
    if (unnamedConstructor == null) {
      return false;
    }
    if (unnamedConstructor.isConst) {
      return false;
    }
    // default constructor is not 'const', report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, node.returnType, [supertype.displayName]);
    return true;
  }

  /**
   * This verifies that if the passed constructor declaration is 'const' then there are no non-final
   * instance variable.
   *
   * @param node the constructor declaration to evaluate
   * @param constructorElement the constructor element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD].
   */
  bool _checkForConstConstructorWithNonFinalField(ConstructorDeclaration node, ConstructorElement constructorElement) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    // check if there is non-final field
    ClassElement classElement = constructorElement.enclosingElement;
    if (!classElement.hasNonFinalField) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, node);
    return true;
  }

  /**
   * This verifies that the passed 'const' instance creation expression is not creating a deferred
   * type.
   *
   * @param node the instance creation expression to evaluate
   * @param constructorName the constructor name, always non-`null`
   * @param typeName the name of the type defining the constructor, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_DEFERRED_CLASS].
   */
  bool _checkForConstDeferredClass(InstanceCreationExpression node, ConstructorName constructorName, TypeName typeName) {
    if (typeName.isDeferred) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_DEFERRED_CLASS, constructorName, [typeName.name.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed throw expression is not enclosed in a 'const' constructor
   * declaration.
   *
   * @param node the throw expression expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION].
   */
  bool _checkForConstEvalThrowsException(ThrowExpression node) {
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, node);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed normal formal parameter is not 'const'.
   *
   * @param node the normal formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_FORMAL_PARAMETER].
   */
  bool _checkForConstFormalParameter(NormalFormalParameter node) {
    if (node.isConst) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, node);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed instance creation expression is not being invoked on an abstract
   * class.
   *
   * @param node the instance creation expression to evaluate
   * @param typeName the [TypeName] of the [ConstructorName] from the
   *          [InstanceCreationExpression], this is the AST node that the error is attached to
   * @param type the type being constructed with this [InstanceCreationExpression]
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.CONST_WITH_ABSTRACT_CLASS], and
   * [StaticWarningCode.NEW_WITH_ABSTRACT_CLASS].
   */
  bool _checkForConstOrNewWithAbstractClass(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isAbstract) {
      ConstructorElement element = node.staticElement;
      if (element != null && !element.isFactory) {
        if ((node.keyword as sc.KeywordToken).keyword == sc.Keyword.CONST) {
          _errorReporter.reportErrorForNode(StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, typeName);
        } else {
          _errorReporter.reportErrorForNode(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, typeName);
        }
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed instance creation expression is not being invoked on an enum.
   *
   * @param node the instance creation expression to verify
   * @param typeName the [TypeName] of the [ConstructorName] from the
   *          [InstanceCreationExpression], this is the AST node that the error is attached to
   * @param type the type being constructed with this [InstanceCreationExpression]
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.INSTANTIATE_ENUM].
   */
  bool _checkForConstOrNewWithEnum(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isEnum) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.INSTANTIATE_ENUM, typeName);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed 'const' instance creation expression is not being invoked on a
   * constructor that is not 'const'.
   *
   * This method assumes that the instance creation was tested to be 'const' before being called.
   *
   * @param node the instance creation expression to verify
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_WITH_NON_CONST].
   */
  bool _checkForConstWithNonConst(InstanceCreationExpression node) {
    ConstructorElement constructorElement = node.staticElement;
    if (constructorElement != null && !constructorElement.isConst) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_CONST, node);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed type name does not reference any type parameters.
   *
   * @param typeName the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS].
   */
  bool _checkForConstWithTypeParameters(TypeName typeName) {
    // something wrong with AST
    if (typeName == null) {
      return false;
    }
    Identifier name = typeName.name;
    if (name == null) {
      return false;
    }
    // should not be a type parameter
    if (name.staticElement is TypeParameterElement) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, name);
    }
    // check type arguments
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      bool hasError = false;
      for (TypeName argument in typeArguments.arguments) {
        if (_checkForConstWithTypeParameters(argument)) {
          hasError = true;
        }
      }
      return hasError;
    }
    // OK
    return false;
  }

  /**
   * This verifies that if the passed 'const' instance creation expression is being invoked on the
   * resolved constructor.
   *
   * This method assumes that the instance creation was tested to be 'const' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @param constructorName the constructor name, always non-`null`
   * @param typeName the name of the type defining the constructor, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR], and
   * [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT].
   */
  bool _checkForConstWithUndefinedConstructor(InstanceCreationExpression node, ConstructorName constructorName, TypeName typeName) {
    // OK if resolved
    if (node.staticElement != null) {
      return false;
    }
    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element != null && element.isEnum) {
        // We have already reported the error.
        return false;
      }
    }
    Identifier className = typeName.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, name, [className, name]);
    } else {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, constructorName, [className]);
    }
    return true;
  }

  /**
   * This verifies that there are no default parameters in the passed function type alias.
   *
   * @param node the function type alias to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS].
   */
  bool _checkForDefaultValueInFunctionTypeAlias(FunctionTypeAlias node) {
    bool result = false;
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameters = formalParameterList.parameters;
    for (FormalParameter formalParameter in parameters) {
      if (formalParameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultFormalParameter = formalParameter;
        if (defaultFormalParameter.defaultValue != null) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, node);
          result = true;
        }
      }
    }
    return result;
  }

  /**
   * This verifies that the given default formal parameter is not part of a function typed
   * parameter.
   *
   * @param node the default formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER].
   */
  bool _checkForDefaultValueInFunctionTypedParameter(DefaultFormalParameter node) {
    // OK, not in a function typed parameter.
    if (!_isInFunctionTypedFormalParameter) {
      return false;
    }
    // OK, no default value.
    if (node.defaultValue == null) {
      return false;
    }
    // Report problem.
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, node);
    return true;
  }

  /**
   * This verifies that any deferred imports in the given compilation unit have a unique prefix.
   *
   * @param node the compilation unit containing the imports to be checked
   * @return `true` if an error was generated
   * See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
   */
  bool _checkForDeferredPrefixCollisions(CompilationUnit node) {
    bool foundError = false;
    NodeList<Directive> directives = node.directives;
    int count = directives.length;
    if (count > 0) {
      HashMap<PrefixElement, List<ImportDirective>> prefixToDirectivesMap = new HashMap<PrefixElement, List<ImportDirective>>();
      for (int i = 0; i < count; i++) {
        Directive directive = directives[i];
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive;
          SimpleIdentifier prefix = importDirective.prefix;
          if (prefix != null) {
            Element element = prefix.staticElement;
            if (element is PrefixElement) {
              PrefixElement prefixElement = element;
              List<ImportDirective> elements = prefixToDirectivesMap[prefixElement];
              if (elements == null) {
                elements = new List<ImportDirective>();
                prefixToDirectivesMap[prefixElement] = elements;
              }
              elements.add(importDirective);
            }
          }
        }
      }
      for (List<ImportDirective> imports in prefixToDirectivesMap.values) {
        if (_hasDeferredPrefixCollision(imports)) {
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the given name of
   * the static member.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE].
   */
  bool _checkForDuplicateDefinitionInheritance() {
    if (_enclosingClass == null) {
      return false;
    }
    bool hasProblem = false;
    for (ExecutableElement member in _enclosingClass.methods) {
      if (member.isStatic && _checkForDuplicateDefinitionOfMember(member)) {
        hasProblem = true;
      }
    }
    for (ExecutableElement member in _enclosingClass.accessors) {
      if (member.isStatic && _checkForDuplicateDefinitionOfMember(member)) {
        hasProblem = true;
      }
    }
    return hasProblem;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the given name of
   * the static member.
   *
   * @param staticMember the static member to check conflict for
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE].
   */
  bool _checkForDuplicateDefinitionOfMember(ExecutableElement staticMember) {
    // prepare name
    String name = staticMember.name;
    if (name == null) {
      return false;
    }
    // try to find member
    ExecutableElement inheritedMember = _inheritanceManager.lookupInheritance(_enclosingClass, name);
    if (inheritedMember == null) {
      return false;
    }
    // OK, also static
    if (inheritedMember.isStatic) {
      return false;
    }
    // determine the display name, use the extended display name if the enclosing class of the
    // inherited member is in a different source
    String displayName;
    Element enclosingElement = inheritedMember.enclosingElement;
    if (enclosingElement.source == _enclosingClass.source) {
      displayName = enclosingElement.displayName;
    } else {
      displayName = enclosingElement.getExtendedDisplayName(null);
    }
    // report problem
    _errorReporter.reportErrorForOffset(CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, staticMember.nameOffset, name.length, [name, displayName]);
    return true;
  }

  /**
   * This verifies if the passed list literal has type arguments then there is exactly one.
   *
   * @param node the list literal to evaluate
   * @param typeArguments the type arguments, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS].
   */
  bool _checkForExpectedOneListTypeArgument(ListLiteral node, TypeArgumentList typeArguments) {
    // check number of type arguments
    int num = typeArguments.arguments.length;
    if (num == 1) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, typeArguments, [num]);
    return true;
  }

  /**
   * This verifies the passed import has unique name among other exported libraries.
   *
   * @param node the export directive to evaluate
   * @param exportElement the [ExportElement] retrieved from the node, if the element in the
   *          node was `null`, then this method is not called
   * @param exportedLibrary the library element containing the exported element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXPORT_DUPLICATED_LIBRARY_NAME].
   */
  bool _checkForExportDuplicateLibraryName(ExportDirective node, ExportElement exportElement, LibraryElement exportedLibrary) {
    if (exportedLibrary == null) {
      return false;
    }
    String name = exportedLibrary.name;
    // check if there is other exported library with the same name
    LibraryElement prevLibrary = _nameToExportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != exportedLibrary) {
        if (name.isEmpty) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_UNNAMED,
              node,
              [prevLibrary.definingCompilationUnit.displayName,
                  exportedLibrary.definingCompilationUnit.displayName]);
        } else {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED,
              node,
              [prevLibrary.definingCompilationUnit.displayName,
                  exportedLibrary.definingCompilationUnit.displayName,
                  name]);
        }
        return true;
      }
    } else {
      _nameToExportElement[name] = exportedLibrary;
    }
    // OK
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   *
   * @param node the export directive to evaluate
   * @param exportElement the [ExportElement] retrieved from the node, if the element in the
   *          node was `null`, then this method is not called
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY].
   */
  bool _checkForExportInternalLibrary(ExportDirective node, ExportElement exportElement) {
    if (_isInSystemLibrary) {
      return false;
    }
    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = exportElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * This verifies that the passed extends clause does not extend a deferred class.
   *
   * @param node the extends clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS].
   */
  bool _checkForExtendsDeferredClass(ExtendsClause node) {
    if (node == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDeferredClass(node.superclass, CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS);
  }

  /**
   * This verifies that the passed type alias does not extend a deferred class.
   *
   * @param node the extends clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
   */
  bool _checkForExtendsDeferredClassInTypeAlias(ClassTypeAlias node) {
    if (node == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDeferredClass(node.superclass, CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS);
  }

  /**
   * This verifies that the passed extends clause does not extend classes such as num or String.
   *
   * @param node the extends clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
   */
  bool _checkForExtendsDisallowedClass(ExtendsClause node) {
    if (node == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(node.superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /**
   * This verifies that the passed type alias does not extend classes such as num or String.
   *
   * @param node the extends clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
   */
  bool _checkForExtendsDisallowedClassInTypeAlias(ClassTypeAlias node) {
    if (node == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(node.superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /**
   * This verifies that the passed type name does not extend, implement or mixin classes that are
   * deferred.
   *
   * @param node the type name to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [_checkForExtendsDeferredClass],
   * [_checkForExtendsDeferredClassInTypeAlias],
   * [_checkForImplementsDeferredClass],
   * [_checkForAllMixinErrorCodes],
   * [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS],
   * [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS], and
   * [CompileTimeErrorCode.MIXIN_DEFERRED_CLASS].
   */
  bool _checkForExtendsOrImplementsDeferredClass(TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }
    if (typeName.isDeferred) {
      _errorReporter.reportErrorForNode(errorCode, typeName, [typeName.name.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed type name does not extend, implement or mixin classes such as
   * 'num' or 'String'.
   *
   * @param node the type name to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [_checkForExtendsDisallowedClass],
   * [_checkForExtendsDisallowedClassInTypeAlias],
   * [_checkForImplementsDisallowedClass],
   * [_checkForAllMixinErrorCodes],
   * [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS],
   * [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS], and
   * [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS].
   */
  bool _checkForExtendsOrImplementsDisallowedClass(TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }
    DartType superType = typeName.type;
    for (InterfaceType disallowedType in _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT) {
      if (superType != null && superType == disallowedType) {
        // if the violating type happens to be 'num', we need to rule out the case where the
        // enclosing class is 'int' or 'double'
        if (superType == _typeProvider.numType) {
          AstNode grandParent = typeName.parent.parent;
          // Note: this is a corner case that won't happen often, so adding a field currentClass
          // (see currentFunction) to ErrorVerifier isn't worth if for this case, but if the field
          // currentClass is added, then this message should become a todo to not lookup the
          // grandparent node
          if (grandParent is ClassDeclaration) {
            ClassElement classElement = grandParent.element;
            DartType classType = classElement.type;
            if (classType != null && (classType == _intType || classType == _typeProvider.doubleType)) {
              return false;
            }
          }
        }
        // otherwise, report the error
        _errorReporter.reportErrorForNode(errorCode, typeName, [disallowedType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed constructor field initializer has compatible field and
   * initializer expression types.
   *
   * @param node the constructor field initializer to test
   * @param staticElement the static element from the name in the
   *          [ConstructorFieldInitializer]
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE], and
   * [StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE].
   */
  bool _checkForFieldInitializerNotAssignable(ConstructorFieldInitializer node, Element staticElement) {
    // prepare field element
    if (staticElement is! FieldElement) {
      return false;
    }
    FieldElement fieldElement = staticElement as FieldElement;
    // prepare field type
    DartType fieldType = fieldElement.type;
    // prepare expression type
    Expression expression = node.expression;
    if (expression == null) {
      return false;
    }
    // test the static type of the expression
    DartType staticType = getStaticType(expression);
    if (staticType == null) {
      return false;
    }
    if (staticType.isAssignableTo(fieldType)) {
      return false;
    }
    // report problem
    if (_isEnclosingConstructorConst) {
      // TODO(paulberry): this error should be based on the actual type of the constant, not the
      // static type.  See dartbug.com/21119.
      _errorReporter.reportTypeErrorForNode(CheckedModeCompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType, fieldType]);
    }
    _errorReporter.reportTypeErrorForNode(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType, fieldType]);
    return true;
    // TODO(brianwilkerson) Define a hint corresponding to these errors and report it if appropriate.
    //    // test the propagated type of the expression
    //    Type propagatedType = expression.getPropagatedType();
    //    if (propagatedType != null && propagatedType.isAssignableTo(fieldType)) {
    //      return false;
    //    }
    //    // report problem
    //    if (isEnclosingConstructorConst) {
    //      errorReporter.reportTypeErrorForNode(
    //          CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
    //          expression,
    //          propagatedType == null ? staticType : propagatedType,
    //          fieldType);
    //    } else {
    //      errorReporter.reportTypeErrorForNode(
    //          StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
    //          expression,
    //          propagatedType == null ? staticType : propagatedType,
    //          fieldType);
    //    }
    //    return true;
  }

  /**
   * This verifies that the passed field formal parameter is in a constructor declaration.
   *
   * @param node the field formal parameter to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR].
   */
  bool _checkForFieldInitializingFormalRedirectingConstructor(FieldFormalParameter node) {
    ConstructorDeclaration constructor = node.getAncestor((node) => node is ConstructorDeclaration);
    if (constructor == null) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, node);
      return true;
    }
    // constructor cannot be a factory
    if (constructor.factoryKeyword != null) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, node);
      return true;
    }
    // constructor cannot have a redirection
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, node);
        return true;
      }
    }
    // OK
    return false;
  }

  /**
   * This verifies that the passed variable declaration list has only initialized variables if the
   * list is final or const. This method is called by
   * [checkForFinalNotInitializedInClass],
   * [visitTopLevelVariableDeclaration] and
   * [visitVariableDeclarationStatement].
   *
   * @param node the class declaration to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
   * [StaticWarningCode.FINAL_NOT_INITIALIZED].
   */
  bool _checkForFinalNotInitialized(VariableDeclarationList node) {
    if (_isInNativeClass) {
      return false;
    }
    bool foundError = false;
    if (!node.isSynthetic) {
      NodeList<VariableDeclaration> variables = node.variables;
      for (VariableDeclaration variable in variables) {
        if (variable.initializer == null) {
          if (node.isConst) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_NOT_INITIALIZED, variable.name, [variable.name.name]);
          } else if (node.isFinal) {
            _errorReporter.reportErrorForNode(StaticWarningCode.FINAL_NOT_INITIALIZED, variable.name, [variable.name.name]);
          }
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This verifies that final fields that are declared, without any constructors in the enclosing
   * class, are initialized. Cases in which there is at least one constructor are handled at the end
   * of [checkForAllFinalInitializedErrorCodes].
   *
   * @param node the class declaration to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
   * [StaticWarningCode.FINAL_NOT_INITIALIZED].
   */
  bool _checkForFinalNotInitializedInClass(ClassDeclaration node) {
    NodeList<ClassMember> classMembers = node.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is ConstructorDeclaration) {
        return false;
      }
    }
    bool foundError = false;
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration
          && _checkForFinalNotInitialized(classMember.fields)) {
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed implements clause does not implement classes that are deferred.
   *
   * @param node the implements clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS].
   */
  bool _checkForImplementsDeferredClass(ImplementsClause node) {
    if (node == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in node.interfaces) {
      if (_checkForExtendsOrImplementsDeferredClass(
          type,
          CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS)) {
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed implements clause does not implement classes such as 'num' or
   * 'String'.
   *
   * @param node the implements clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS].
   */
  bool _checkForImplementsDisallowedClass(ImplementsClause node) {
    if (node == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in node.interfaces) {
      if (_checkForExtendsOrImplementsDisallowedClass(
          type,
          CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS)) {
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that if the passed identifier is part of constructor initializer, then it does
   * not reference implicitly 'this' expression.
   *
   * @param node the simple identifier to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER], and
   * [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC].
   * TODO(scheglov) rename thid method
   */
  bool _checkForImplicitThisReferenceInInitializer(SimpleIdentifier node) {
    if (!_isInConstructorInitializer && !_isInStaticMethod && !_isInFactory && !_isInInstanceVariableInitializer && !_isInStaticVariableDeclaration) {
      return false;
    }
    // prepare element
    Element element = node.staticElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return false;
    }
    // static element
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic) {
      return false;
    }
    // not a class member
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return false;
    }
    // comment
    AstNode parent = node.parent;
    if (parent is CommentReference) {
      return false;
    }
    // qualified method invocation
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.methodName, node) && invocation.realTarget != null) {
        return false;
      }
    }
    // qualified property access
    if (parent is PropertyAccess) {
      PropertyAccess access = parent;
      if (identical(access.propertyName, node) && access.realTarget != null) {
        return false;
      }
    }
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent;
      if (identical(prefixed.identifier, node)) {
        return false;
      }
    }
    // report problem
    if (_isInStaticMethod) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, node);
    } else if (_isInFactory) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, node);
    } else {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, node);
    }
    return true;
  }

  /**
   * This verifies the passed import has unique name among other imported libraries.
   *
   * @param node the import directive to evaluate
   * @param importElement the [ImportElement] retrieved from the node, if the element in the
   *          node was `null`, then this method is not called
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPORT_DUPLICATED_LIBRARY_NAME].
   */
  bool _checkForImportDuplicateLibraryName(ImportDirective node, ImportElement importElement) {
    // prepare imported library
    LibraryElement nodeLibrary = importElement.importedLibrary;
    if (nodeLibrary == null) {
      return false;
    }
    String name = nodeLibrary.name;
    // check if there is another imported library with the same name
    LibraryElement prevLibrary = _nameToImportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary) {
        if (name.isEmpty) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_UNNAMED,
              node,
              [prevLibrary.definingCompilationUnit.displayName,
                  nodeLibrary.definingCompilationUnit.displayName]);
        } else {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED,
              node,
              [prevLibrary.definingCompilationUnit.displayName,
                  nodeLibrary.definingCompilationUnit.displayName,
                  name]);
        }
        return true;
      }
    } else {
      _nameToImportElement[name] = nodeLibrary;
    }
    // OK
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   *
   * @param node the import directive to evaluate
   * @param importElement the [ImportElement] retrieved from the node, if the element in the
   *          node was `null`, then this method is not called
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY].
   */
  bool _checkForImportInternalLibrary(ImportDirective node, ImportElement importElement) {
    if (_isInSystemLibrary) {
      return false;
    }
    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = importElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * For each class declaration, this method is called which verifies that all inherited members are
   * inherited consistently.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE].
   */
  bool _checkForInconsistentMethodInheritance() {
    // Ensure that the inheritance manager has a chance to generate all errors we may care about,
    // note that we ensure that the interfaces data since there are no errors.
    _inheritanceManager.getMapOfMembersInheritedFromInterfaces(_enclosingClass);
    HashSet<AnalysisError> errors = _inheritanceManager.getErrors(_enclosingClass);
    if (errors == null || errors.isEmpty) {
      return false;
    }
    for (AnalysisError error in errors) {
      _errorReporter.reportError(error);
    }
    return true;
  }

  /**
   * This checks the given "typeReference" is not a type reference and that then the "name" is
   * reference to an instance member.
   *
   * @param typeReference the resolved [ClassElement] of the left hand side of the expression,
   *          or `null`, aka, the class element of 'C' in 'C.x', see
   *          [getTypeReference]
   * @param name the accessed name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER].
   */
  bool _checkForInstanceAccessToStaticMember(ClassElement typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return false;
    }
    // OK, target is a type
    if (typeReference != null) {
      return false;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is! ExecutableElement) {
      return false;
    }
    ExecutableElement executableElement = element as ExecutableElement;
    // OK, top-level element
    if (executableElement.enclosingElement is! ClassElement) {
      return false;
    }
    // OK, instance member
    if (!executableElement.isStatic) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, name, [name.name]);
    return true;
  }

  /**
   * This checks whether the given [executableElement] collides with the name of a static
   * method in one of its superclasses, and reports the appropriate warning if it does.
   *
   * @param executableElement the method to check.
   * @param errorNameTarget the node to report problems on.
   * @return `true` if and only if a warning was generated.
   * See [StaticTypeWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC].
   */
  bool _checkForInstanceMethodNameCollidesWithSuperclassStatic(ExecutableElement executableElement, SimpleIdentifier errorNameTarget) {
    String executableElementName = executableElement.name;
    if (executableElement is! PropertyAccessorElement && !executableElement.isOperator) {
      HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
      InterfaceType superclassType = _enclosingClass.supertype;
      ClassElement superclassElement = superclassType == null ? null : superclassType.element;
      bool executableElementPrivate = Identifier.isPrivateName(executableElementName);
      while (superclassElement != null && !visitedClasses.contains(superclassElement)) {
        visitedClasses.add(superclassElement);
        LibraryElement superclassLibrary = superclassElement.library;
        // Check fields.
        List<FieldElement> fieldElts = superclassElement.fields;
        for (FieldElement fieldElt in fieldElts) {
          // We need the same name.
          if (fieldElt.name != executableElementName) {
            continue;
          }
          // Ignore if private in a different library - cannot collide.
          if (executableElementPrivate && _currentLibrary != superclassLibrary) {
            continue;
          }
          // instance vs. static
          if (fieldElt.isStatic) {
            _errorReporter.reportErrorForNode(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, errorNameTarget, [
                executableElementName,
                fieldElt.enclosingElement.displayName]);
            return true;
          }
        }
        // Check methods.
        List<MethodElement> methodElements = superclassElement.methods;
        for (MethodElement methodElement in methodElements) {
          // We need the same name.
          if (methodElement.name != executableElementName) {
            continue;
          }
          // Ignore if private in a different library - cannot collide.
          if (executableElementPrivate && _currentLibrary != superclassLibrary) {
            continue;
          }
          // instance vs. static
          if (methodElement.isStatic) {
            _errorReporter.reportErrorForNode(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, errorNameTarget, [
                executableElementName,
                methodElement.enclosingElement.displayName]);
            return true;
          }
        }
        superclassType = superclassElement.supertype;
        superclassElement = superclassType == null ? null : superclassType.element;
      }
    }
    return false;
  }

  /**
   * This verifies that an 'int' can be assigned to the parameter corresponding to the given
   * expression. This is used for prefix and postfix expressions where the argument value is
   * implicit.
   *
   * @param argument the expression to which the operator is being applied
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForIntNotAssignable(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    DartType staticParameterType = staticParameterElement == null ? null : staticParameterElement.type;
    return _checkForArgumentTypeNotAssignable(argument, staticParameterType, _intType, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * This verifies that the passed [Annotation] isn't defined in a deferred library.
   *
   * @param node the [Annotation]
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
   */
  bool _checkForInvalidAnnotationFromDeferredLibrary(Annotation node) {
    Identifier nameIdentifier = node.name;
    if (nameIdentifier is PrefixedIdentifier) {
      if (nameIdentifier.isDeferred) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, node.name);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed left hand side and right hand side represent a valid assignment.
   *
   * @param lhs the left hand side expression
   * @param rhs the right hand side expression
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.INVALID_ASSIGNMENT].
   */
  bool _checkForInvalidAssignment(Expression lhs, Expression rhs) {
    if (lhs == null || rhs == null) {
      return false;
    }
    VariableElement leftVariableElement = getVariableElement(lhs);
    DartType leftType = (leftVariableElement == null) ? getStaticType(lhs) : leftVariableElement.type;
    DartType staticRightType = getStaticType(rhs);
    if (!staticRightType.isAssignableTo(leftType)) {
      _errorReporter.reportTypeErrorForNode(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [staticRightType, leftType]);
      return true;
    }
    return false;
  }

  /**
   * Given an assignment using a compound assignment operator, this verifies that the given
   * assignment is valid.
   *
   * @param node the assignment expression being tested
   * @param lhs the left hand side expression
   * @param rhs the right hand side expression
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.INVALID_ASSIGNMENT].
   */
  bool _checkForInvalidCompoundAssignment(AssignmentExpression node, Expression lhs, Expression rhs) {
    if (lhs == null) {
      return false;
    }
    VariableElement leftVariableElement = getVariableElement(lhs);
    DartType leftType = (leftVariableElement == null) ? getStaticType(lhs) : leftVariableElement.type;
    MethodElement invokedMethod = node.staticElement;
    if (invokedMethod == null) {
      return false;
    }
    DartType rightType = invokedMethod.type.returnType;
    if (leftType == null || rightType == null) {
      return false;
    }
    if (!rightType.isAssignableTo(leftType)) {
      _errorReporter.reportTypeErrorForNode(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [rightType, leftType]);
      return true;
    }
    return false;
  }

  /**
   * Check the given initializer to ensure that the field being initialized is a valid field.
   *
   * @param node the field initializer being checked
   * @param fieldName the field name from the [ConstructorFieldInitializer]
   * @param staticElement the static element from the name in the
   *          [ConstructorFieldInitializer]
   */
  void _checkForInvalidField(ConstructorFieldInitializer node, SimpleIdentifier fieldName, Element staticElement) {
    if (staticElement is FieldElement) {
      FieldElement fieldElement = staticElement;
      if (fieldElement.isSynthetic) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, node, [fieldName]);
      } else if (fieldElement.isStatic) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, node, [fieldName]);
      }
    } else {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, node, [fieldName]);
      return;
    }
  }

  /**
   * Check to see whether the given function body has a modifier associated with it, and report it
   * as an error if it does.
   *
   * @param body the function body being checked
   * @param errorCode the error code to be reported if a modifier is found
   * @return `true` if an error was reported
   */
  bool _checkForInvalidModifierOnBody(FunctionBody body, CompileTimeErrorCode errorCode) {
    sc.Token keyword = body.keyword;
    if (keyword != null) {
      _errorReporter.reportErrorForToken(errorCode, keyword, [keyword.lexeme]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the usage of the passed 'this' is valid.
   *
   * @param node the 'this' expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS].
   */
  bool _checkForInvalidReferenceToThis(ThisExpression node) {
    if (!_isThisInValidContext(node)) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, node);
      return true;
    }
    return false;
  }

  /**
   * Checks to ensure that the passed [ListLiteral] or [MapLiteral] does not have a type
   * parameter as a type argument.
   *
   * @param arguments a non-`null`, non-empty [TypeName] node list from the respective
   *          [ListLiteral] or [MapLiteral]
   * @param errorCode either [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST] or
   *          [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool _checkForInvalidTypeArgumentInConstTypedLiteral(NodeList<TypeName> arguments, ErrorCode errorCode) {
    bool foundError = false;
    for (TypeName typeName in arguments) {
      if (typeName.type is TypeParameterType) {
        _errorReporter.reportErrorForNode(errorCode, typeName, [typeName.name]);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the elements given [ListLiteral] are subtypes of the specified element
   * type.
   *
   * @param node the list literal to evaluate
   * @param typeArguments the type arguments, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForListElementTypeNotAssignable(ListLiteral node, TypeArgumentList typeArguments) {
    NodeList<TypeName> typeNames = typeArguments.arguments;
    if (typeNames.length < 1) {
      return false;
    }
    DartType listElementType = typeNames[0].type;
    // Check every list element.
    bool hasProblems = false;
    for (Expression element in node.elements) {
      if (node.constKeyword != null) {
        // TODO(paulberry): this error should be based on the actual type of the
        // list element, not the static type.  See dartbug.com/21119.
        if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
            element,
            listElementType,
            CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE)) {
          hasProblems = true;
        }
      }
      if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
          element,
          listElementType,
          StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE)) {
        hasProblems = true;
      }
    }
    return hasProblems;
  }

  /**
   * This verifies that the key/value of entries of the given [MapLiteral] are subtypes of the
   * key/value types specified in the type arguments.
   *
   * @param node the map literal to evaluate
   * @param typeArguments the type arguments, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
   * [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
   * [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
   */
  bool _checkForMapTypeNotAssignable(MapLiteral node, TypeArgumentList typeArguments) {
    // Prepare maps key/value types.
    NodeList<TypeName> typeNames = typeArguments.arguments;
    if (typeNames.length < 2) {
      return false;
    }
    DartType keyType = typeNames[0].type;
    DartType valueType = typeNames[1].type;
    // Check every map entry.
    bool hasProblems = false;
    NodeList<MapLiteralEntry> entries = node.entries;
    for (MapLiteralEntry entry in entries) {
      Expression key = entry.key;
      Expression value = entry.value;
      if (node.constKeyword != null) {
        // TODO(paulberry): this error should be based on the actual type of the
        // list element, not the static type.  See dartbug.com/21119.
        if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
            key,
            keyType,
            CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE)) {
          hasProblems = true;
        }
        if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
            value,
            valueType,
            CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE)) {
          hasProblems = true;
        }
      }
      if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
          key,
          keyType,
          StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE)) {
        hasProblems = true;
      }
      if (_checkForArgumentTypeNotAssignableWithExpectedTypes(
          value,
          valueType,
          StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE)) {
        hasProblems = true;
      }
    }
    return hasProblems;
  }

  /**
   * This verifies that the [enclosingClass] does not define members with the same name as
   * the enclosing class.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME].
   */
  bool _checkForMemberWithClassName() {
    if (_enclosingClass == null) {
      return false;
    }
    String className = _enclosingClass.name;
    if (className == null) {
      return false;
    }
    bool problemReported = false;
    // check accessors
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (className == accessor.name) {
        _errorReporter.reportErrorForOffset(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, accessor.nameOffset, className.length);
        problemReported = true;
      }
    }
    // don't check methods, they would be constructors
    // done
    return problemReported;
  }

  /**
   * Check to make sure that all similarly typed accessors are of the same type (including inherited
   * accessors).
   *
   * @param node the accessor currently being visited
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES], and
   * [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE].
   */
  bool _checkForMismatchedAccessorTypes(Declaration accessorDeclaration, String accessorTextName) {
    ExecutableElement accessorElement = accessorDeclaration.element as ExecutableElement;
    if (accessorElement is! PropertyAccessorElement) {
      return false;
    }
    PropertyAccessorElement propertyAccessorElement = accessorElement as PropertyAccessorElement;
    PropertyAccessorElement counterpartAccessor = null;
    ClassElement enclosingClassForCounterpart = null;
    if (propertyAccessorElement.isGetter) {
      counterpartAccessor = propertyAccessorElement.correspondingSetter;
    } else {
      counterpartAccessor = propertyAccessorElement.correspondingGetter;
      // If the setter and getter are in the same enclosing element, return, this prevents having
      // MISMATCHED_GETTER_AND_SETTER_TYPES reported twice.
      if (counterpartAccessor != null && identical(counterpartAccessor.enclosingElement, propertyAccessorElement.enclosingElement)) {
        return false;
      }
    }
    if (counterpartAccessor == null) {
      // If the accessor is declared in a class, check the superclasses.
      if (_enclosingClass != null) {
        // Figure out the correct identifier to lookup in the inheritance graph, if 'x', then 'x=',
        // or if 'x=', then 'x'.
        String lookupIdentifier = propertyAccessorElement.name;
        if (StringUtilities.endsWithChar(lookupIdentifier, 0x3D)) {
          lookupIdentifier = lookupIdentifier.substring(0, lookupIdentifier.length - 1);
        } else {
          lookupIdentifier += "=";
        }
        // lookup with the identifier.
        ExecutableElement elementFromInheritance = _inheritanceManager.lookupInheritance(_enclosingClass, lookupIdentifier);
        // Verify that we found something, and that it is an accessor
        if (elementFromInheritance != null && elementFromInheritance is PropertyAccessorElement) {
          enclosingClassForCounterpart = elementFromInheritance.enclosingElement as ClassElement;
          counterpartAccessor = elementFromInheritance;
        }
      }
      if (counterpartAccessor == null) {
        return false;
      }
    }
    // Default of null == no accessor or no type (dynamic)
    DartType getterType = null;
    DartType setterType = null;
    // Get an existing counterpart accessor if any.
    if (propertyAccessorElement.isGetter) {
      getterType = _getGetterType(propertyAccessorElement);
      setterType = _getSetterType(counterpartAccessor);
    } else if (propertyAccessorElement.isSetter) {
      setterType = _getSetterType(propertyAccessorElement);
      getterType = _getGetterType(counterpartAccessor);
    }
    // If either types are not assignable to each other, report an error (if the getter is null,
    // it is dynamic which is assignable to everything).
    if (setterType != null && getterType != null && !getterType.isAssignableTo(setterType)) {
      if (enclosingClassForCounterpart == null) {
        _errorReporter.reportTypeErrorForNode(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, accessorDeclaration, [accessorTextName, setterType, getterType]);
        return true;
      } else {
        _errorReporter.reportTypeErrorForNode(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, accessorDeclaration, [
            accessorTextName,
            setterType,
            getterType,
            enclosingClassForCounterpart.displayName]);
      }
    }
    return false;
  }

  /**
   * Check to make sure that switch statements whose static type is an enum type either have a
   * default case or include all of the enum constants.
   *
   * @param statement the switch statement to check
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool _checkForMissingEnumConstantInSwitch(SwitchStatement statement) {
    // TODO(brianwilkerson) This needs to be checked after constant values have been computed.
    Expression expression = statement.expression;
    DartType expressionType = getStaticType(expression);
    if (expressionType == null) {
      return false;
    }
    Element expressionElement = expressionType.element;
    if (expressionElement is! ClassElement) {
      return false;
    }
    ClassElement classElement = expressionElement as ClassElement;
    if (!classElement.isEnum) {
      return false;
    }
    List<String> constantNames = new List<String>();
    List<FieldElement> fields = classElement.fields;
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
        return false;
      }
      String constantName = _getConstantName((member as SwitchCase).expression);
      if (constantName != null) {
        constantNames.remove(constantName);
      }
    }
    int nameCount = constantNames.length;
    if (nameCount == 0) {
      return false;
    }
    for (int i = 0; i < nameCount; i++) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.MISSING_ENUM_CONSTANT_IN_SWITCH, statement, [constantNames[i]]);
    }
    return true;
  }

  /**
   * This verifies that the given function body does not contain return statements that both have
   * and do not have return values.
   *
   * @param node the function body being tested
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.MIXED_RETURN_TYPES].
   */
  bool _checkForMixedReturns(BlockFunctionBody node) {
    if (_hasReturnWithoutValue) {
      return false;
    }
    int withCount = _returnsWith.length;
    int withoutCount = _returnsWithout.length;
    if (withCount > 0 && withoutCount > 0) {
      for (int i = 0; i < withCount; i++) {
        _errorReporter.reportErrorForToken(StaticWarningCode.MIXED_RETURN_TYPES, _returnsWith[i].keyword);
      }
      for (int i = 0; i < withoutCount; i++) {
        _errorReporter.reportErrorForToken(StaticWarningCode.MIXED_RETURN_TYPES, _returnsWithout[i].keyword);
      }
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed mixin does not have an explicitly declared constructor.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR].
   */
  bool _checkForMixinDeclaresConstructor(TypeName mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin has the 'Object' superclass.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
   */
  bool _checkForMixinInheritsNotFromObject(TypeName mixinName, ClassElement mixinElement) {
    InterfaceType mixinSupertype = mixinElement.supertype;
    if (mixinSupertype != null) {
      if (!mixinSupertype.isObject || !mixinElement.isTypedef && mixinElement.mixins.length != 0) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin does not reference 'super'.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER].
   */
  bool _checkForMixinReferencesSuper(TypeName mixinName, ClassElement mixinElement) {
    if (mixinElement.hasReferenceToSuper) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.MIXIN_REFERENCES_SUPER, mixinName, [mixinElement.name]);
    }
    return false;
  }

  /**
   * This verifies that the passed constructor has at most one 'super' initializer.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS].
   */
  bool _checkForMultipleSuperInitializers(ConstructorDeclaration node) {
    int numSuperInitializers = 0;
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is SuperConstructorInvocation) {
        numSuperInitializers++;
        if (numSuperInitializers > 1) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, initializer);
        }
      }
    }
    return numSuperInitializers > 0;
  }

  /**
   * Checks to ensure that native function bodies can only in SDK code.
   *
   * @param node the native function body to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE].
   */
  bool _checkForNativeFunctionBodyInNonSDKCode(NativeFunctionBody node) {
    if (!_isInSystemLibrary && !_hasExtUri) {
      _errorReporter.reportErrorForNode(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, node);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed 'new' instance creation expression invokes existing constructor.
   *
   * This method assumes that the instance creation was tested to be 'new' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @param constructorName the constructor name, always non-`null`
   * @param typeName the name of the type defining the constructor, always non-`null`
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR].
   */
  bool _checkForNewWithUndefinedConstructor(InstanceCreationExpression node, ConstructorName constructorName, TypeName typeName) {
    // OK if resolved
    if (node.staticElement != null) {
      return false;
    }
    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element != null && element.isEnum) {
        // We have already reported the error.
        return false;
      }
    }
    // prepare class name
    Identifier className = typeName.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportErrorForNode(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, name, [className, name]);
    } else {
      _errorReporter.reportErrorForNode(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, constructorName, [className]);
    }
    return true;
  }

  /**
   * This checks that if the passed class declaration implicitly calls default constructor of its
   * superclass, there should be such default constructor - implicit or explicit.
   *
   * @param node the [ClassDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT].
   */
  bool _checkForNoDefaultSuperConstructorImplicit(ClassDeclaration node) {
    // do nothing if mixin errors have already been reported for this class.
    ClassElementImpl enclosingClass = _enclosingClass;
    if (enclosingClass.mixinErrorsReported) {
      return false;
    }
    // do nothing if there is explicit constructor
    List<ConstructorElement> constructors = _enclosingClass.constructors;
    if (!constructors[0].isSynthetic) {
      return false;
    }
    // prepare super
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement superElement = superType.element;
    // try to find default generative super constructor
    ConstructorElement superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node.name, [superUnnamedConstructor]);
        return true;
      }
      if (superUnnamedConstructor.isDefaultConstructor &&
          _enclosingClass.isSuperConstructorAccessible(
              superUnnamedConstructor)) {
        return true;
      }
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, node.name, [superType.displayName]);
    return true;
  }

  /**
   * This checks that passed class declaration overrides all members required by its superclasses
   * and interfaces.
   *
   * @param classNameNode the [SimpleIdentifier] to be used if there is a violation, this is
   *          either the named from the [ClassDeclaration] or from the [ClassTypeAlias].
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE],
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR], and
   * [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS].
   */
  bool _checkForNonAbstractClassInheritsAbstractMember(SimpleIdentifier classNameNode) {
    if (_enclosingClass.isAbstract) {
      return false;
    }
    //
    // Store in local sets the set of all method and accessor names
    //
    List<MethodElement> methods = _enclosingClass.methods;
    for (MethodElement method in methods) {
      String methodName = method.name;
      // If the enclosing class declares the method noSuchMethod(), then return.
      // From Spec:  It is a static warning if a concrete class does not have an implementation for
      // a method in any of its superinterfaces unless it declares its own noSuchMethod
      // method (7.10).
      if (methodName == FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
        return false;
      }
    }
    HashSet<ExecutableElement> missingOverrides = new HashSet<ExecutableElement>();
    //
    // Loop through the set of all executable elements declared in the implicit interface.
    //
    MemberMap membersInheritedFromInterfaces = _inheritanceManager.getMapOfMembersInheritedFromInterfaces(_enclosingClass);
    MemberMap membersInheritedFromSuperclasses = _inheritanceManager.getMapOfMembersInheritedFromClasses(_enclosingClass);
    for (int i = 0; i < membersInheritedFromInterfaces.size; i++) {
      String memberName = membersInheritedFromInterfaces.getKey(i);
      ExecutableElement executableElt = membersInheritedFromInterfaces.getValue(i);
      if (memberName == null) {
        break;
      }
      // If the element is not synthetic and can be determined to be defined in Object, skip it.
      if (executableElt.enclosingElement != null && (executableElt.enclosingElement as ClassElement).type.isObject) {
        continue;
      }
      // Check to see if some element is in local enclosing class that matches the name of the
      // required member.
      if (_isMemberInClassOrMixin(executableElt, _enclosingClass)) {
        // We do not have to verify that this implementation of the found method matches the
        // required function type: the set of StaticWarningCode.INVALID_METHOD_OVERRIDE_* warnings
        // break out the different specific situations.
        continue;
      }
      // First check to see if this element was declared in the superclass chain, in which case
      // there is already a concrete implementation.
      ExecutableElement elt = membersInheritedFromSuperclasses.get(memberName);
      // Check to see if an element was found in the superclass chain with the correct name.
      if (elt != null) {
        // Reference the types, if any are null then continue.
        InterfaceType enclosingType = _enclosingClass.type;
        FunctionType concreteType = elt.type;
        FunctionType requiredMemberType = executableElt.type;
        if (enclosingType == null || concreteType == null || requiredMemberType == null) {
          continue;
        }
        // Some element was found in the superclass chain that matches the name of the required
        // member.
        // If it is not abstract and it is the correct one (types match- the version of this method
        // that we have has the correct number of parameters, etc), then this class has a valid
        // implementation of this method, so skip it.
        if ((elt is MethodElement && !elt.isAbstract) || (elt is PropertyAccessorElement && !elt.isAbstract)) {
          // Since we are comparing two function types, we need to do the appropriate type
          // substitutions first ().
          FunctionType foundConcreteFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(concreteType, memberName, enclosingType);
          FunctionType requiredMemberFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(requiredMemberType, memberName, enclosingType);
          if (foundConcreteFT.isSubtypeOf(requiredMemberFT)) {
            continue;
          }
        }
      }
      // The not qualifying concrete executable element was found, add it to the list.
      missingOverrides.add(executableElt);
    }
    // Now that we have the set of missing overrides, generate a warning on this class
    int missingOverridesSize = missingOverrides.length;
    if (missingOverridesSize == 0) {
      return false;
    }
    List<ExecutableElement> missingOverridesArray = new List.from(missingOverrides);
    List<String> stringMembersArrayListSet = new List<String>();
    for (int i = 0; i < missingOverridesArray.length; i++) {
      String newStrMember;
      Element enclosingElement = missingOverridesArray[i].enclosingElement;
      String prefix = StringUtilities.EMPTY;
      if (missingOverridesArray[i] is PropertyAccessorElement) {
        PropertyAccessorElement propertyAccessorElement = missingOverridesArray[i] as PropertyAccessorElement;
        if (propertyAccessorElement.isGetter) {
          prefix = _GETTER_SPACE;
          // "getter "
        } else {
          prefix = _SETTER_SPACE;
          // "setter "
        }
      }
      if (enclosingElement != null) {
        newStrMember = "$prefix'${enclosingElement.displayName}.${missingOverridesArray[i].displayName}'";
      } else {
        newStrMember = "$prefix'${missingOverridesArray[i].displayName}'";
      }
      stringMembersArrayListSet.add(newStrMember);
    }
    List<String> stringMembersArray = new List.from(stringMembersArrayListSet);
    AnalysisErrorWithProperties analysisError;
    if (stringMembersArray.length == 1) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE, classNameNode, [stringMembersArray[0]]);
    } else if (stringMembersArray.length == 2) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO, classNameNode, [stringMembersArray[0], stringMembersArray[1]]);
    } else if (stringMembersArray.length == 3) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE, classNameNode, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2]]);
    } else if (stringMembersArray.length == 4) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR, classNameNode, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2],
          stringMembersArray[3]]);
    } else {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS, classNameNode, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2],
          stringMembersArray[3],
          stringMembersArray.length - 4]);
    }
    analysisError.setProperty(ErrorProperty.UNIMPLEMENTED_METHODS, missingOverridesArray);
    _errorReporter.reportError(analysisError);
    return true;
  }

  /**
   * Checks to ensure that the expressions that need to be of type bool, are. Otherwise an error is
   * reported on the expression.
   *
   * @param condition the conditional expression to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.NON_BOOL_CONDITION].
   */
  bool _checkForNonBoolCondition(Expression condition) {
    DartType conditionType = getStaticType(condition);
    if (conditionType != null && !conditionType.isAssignableTo(_boolType)) {
      _errorReporter.reportErrorForNode(StaticTypeWarningCode.NON_BOOL_CONDITION, condition);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed assert statement has either a 'bool' or '() -> bool' input.
   *
   * @param node the assert statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.NON_BOOL_EXPRESSION].
   */
  bool _checkForNonBoolExpression(AssertStatement node) {
    Expression expression = node.condition;
    DartType type = getStaticType(expression);
    if (type is InterfaceType) {
      if (!type.isAssignableTo(_boolType)) {
        _errorReporter.reportErrorForNode(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression);
        return true;
      }
    } else if (type is FunctionType) {
      FunctionType functionType = type;
      if (functionType.typeArguments.length == 0 && !functionType.returnType.isAssignableTo(_boolType)) {
        _errorReporter.reportErrorForNode(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression);
        return true;
      }
    }
    return false;
  }

  /**
   * Checks to ensure that the given expression is assignable to bool.
   *
   * @param expression the expression expression to test
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION].
   */
  bool _checkForNonBoolNegationExpression(Expression expression) {
    DartType conditionType = getStaticType(expression);
    if (conditionType != null && !conditionType.isAssignableTo(_boolType)) {
      _errorReporter.reportErrorForNode(StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION, expression);
      return true;
    }
    return false;
  }

  /**
   * This verifies the passed map literal either:
   * * has `const modifier`
   * * has explicit type arguments
   * * is not start of the statement
   *
   * @param node the map literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT].
   */
  bool _checkForNonConstMapAsExpressionStatement(MapLiteral node) {
    // "const"
    if (node.constKeyword != null) {
      return false;
    }
    // has type arguments
    if (node.typeArguments != null) {
      return false;
    }
    // prepare statement
    Statement statement = node.getAncestor((node) => node is ExpressionStatement);
    if (statement == null) {
      return false;
    }
    // OK, statement does not start with map
    if (!identical(statement.beginToken, node.beginToken)) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT, node);
    return true;
  }

  /**
   * This verifies the passed method declaration of operator `[]=`, has `void` return
   * type.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR].
   */
  bool _checkForNonVoidReturnTypeForOperator(MethodDeclaration node) {
    // check that []= operator
    SimpleIdentifier name = node.name;
    if (name.name != "[]=") {
      return false;
    }
    // check return type
    TypeName typeName = node.returnType;
    if (typeName != null) {
      DartType type = typeName.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportErrorForNode(StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, typeName);
      }
    }
    // no warning
    return false;
  }

  /**
   * This verifies the passed setter has no return type or the `void` return type.
   *
   * @param typeName the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER].
   */
  bool _checkForNonVoidReturnTypeForSetter(TypeName typeName) {
    if (typeName != null) {
      DartType type = typeName.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportErrorForNode(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, typeName);
      }
    }
    return false;
  }

  /**
   * This verifies the passed operator-method declaration, does not have an optional parameter.
   *
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR].
   */
  bool _checkForOptionalParameterInOperator(MethodDeclaration node) {
    FormalParameterList parameterList = node.parameters;
    if (parameterList == null) {
      return false;
    }
    bool foundError = false;
    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.kind.isOptional) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, formalParameter);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This checks for named optional parameters that begin with '_'.
   *
   * @param node the default formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER].
   */
  bool _checkForPrivateOptionalParameter(FormalParameter node) {
    // should be named parameter
    if (node.kind != ParameterKind.NAMED) {
      return false;
    }
    // name should start with '_'
    SimpleIdentifier name = node.identifier;
    if (name.isSynthetic || !StringUtilities.startsWithChar(name.name, 0x5F)) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, node);
    return true;
  }

  /**
   * This checks if the passed constructor declaration is the redirecting generative constructor and
   * references itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @param constructorElement the constructor element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT].
   */
  bool _checkForRecursiveConstructorRedirect(ConstructorDeclaration node, ConstructorElement constructorElement) {
    // we check generative constructor here
    if (node.factoryKeyword != null) {
      return false;
    }
    // try to find redirecting constructor invocation and analyzer it for recursion
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        // OK if no cycle
        if (!_hasRedirectingFactoryConstructorCycle(constructorElement)) {
          return false;
        }
        // report error
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, initializer);
        return true;
      }
    }
    // OK, no redirecting constructor invocation
    return false;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @param constructorElement the constructor element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT].
   */
  bool _checkForRecursiveFactoryRedirect(ConstructorDeclaration node, ConstructorElement constructorElement) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // OK if no cycle
    if (!_hasRedirectingFactoryConstructorCycle(constructorElement)) {
      return false;
    }
    // report error
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, redirectedConstructorNode);
    return true;
  }

  /**
   * This checks the class declaration is not a superinterface to itself.
   *
   * @param classElt the class element to test
   * @return `true` if and only if an error code is generated on the passed element
   * See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS], and
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS].
   */
  bool _checkForRecursiveInterfaceInheritance(ClassElement classElt) {
    if (classElt == null) {
      return false;
    }
    return _safeCheckForRecursiveInterfaceInheritance(classElt, new List<ClassElement>());
  }

  /**
   * This checks the passed constructor declaration has a valid combination of redirected
   * constructor invocation(s), super constructor invocations and field initializers.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR],
   * [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR],
   * [CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS],
   * [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR], and
   * [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR].
   */
  bool _checkForRedirectingConstructorErrorCodes(ConstructorDeclaration node) {
    bool errorReported = false;
    //
    // Check for default values in the parameters
    //
    ConstructorName redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor != null) {
      for (FormalParameter parameter in node.parameters.parameters) {
        if (parameter is DefaultFormalParameter && parameter.defaultValue != null) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR, parameter.identifier);
          errorReported = true;
        }
      }
    }
    // check if there are redirected invocations
    int numRedirections = 0;
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (numRedirections > 0) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS, initializer);
          errorReported = true;
        }
        if (node.factoryKeyword == null) {
          RedirectingConstructorInvocation invocation = initializer;
          ConstructorElement redirectingElement = invocation.staticElement;
          if (redirectingElement == null) {
            String enclosingTypeName = _enclosingClass.displayName;
            String constructorStrName = enclosingTypeName;
            if (invocation.constructorName != null) {
              constructorStrName += ".${invocation.constructorName.name}";
            }
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, invocation, [constructorStrName, enclosingTypeName]);
          } else {
            if (redirectingElement.isFactory) {
              _errorReporter.reportErrorForNode(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR, initializer);
            }
          }
        }
        numRedirections++;
      }
    }
    // check for other initializers
    if (numRedirections > 0) {
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is SuperConstructorInvocation) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, initializer);
          errorReported = true;
        }
        if (initializer is ConstructorFieldInitializer) {
          _errorReporter.reportErrorForNode(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, initializer);
          errorReported = true;
        }
      }
    }
    // done
    return errorReported;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @param constructorElement the constructor element
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR].
   */
  bool _checkForRedirectToNonConstConstructor(ConstructorDeclaration node, ConstructorElement constructorElement) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // prepare element
    if (constructorElement == null) {
      return false;
    }
    // OK, it is not 'const'
    if (!constructorElement.isConst) {
      return false;
    }
    // prepare redirected constructor
    ConstructorElement redirectedConstructor = constructorElement.redirectedConstructor;
    if (redirectedConstructor == null) {
      return false;
    }
    // OK, it is also 'const'
    if (redirectedConstructor.isConst) {
      return false;
    }
    // report error
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR, redirectedConstructorNode);
    return true;
  }

  /**
   * This checks that the rethrow is inside of a catch clause.
   *
   * @param node the rethrow expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH].
   */
  bool _checkForRethrowOutsideCatch(RethrowExpression node) {
    if (!_isInCatchClause) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, node);
      return true;
    }
    return false;
  }

  /**
   * This checks that if the the given constructor declaration is generative, then it does not have
   * an expression function body.
   *
   * @param node the constructor to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR].
   */
  bool _checkForReturnInGenerativeConstructor(ConstructorDeclaration node) {
    // ignore factory
    if (node.factoryKeyword != null) {
      return false;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = node.body;
    if (body is! ExpressionFunctionBody) {
      return false;
    }
    // report error
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, body);
    return true;
  }

  /**
   * This checks that a type mis-match between the return type and the expressed return type by the
   * enclosing method or function.
   *
   * This method is called both by [checkForAllReturnStatementErrorCodes]
   * and [visitExpressionFunctionBody].
   *
   * @param returnExpression the returned expression to evaluate
   * @param expectedReturnType the expressed return type by the enclosing method or function
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE].
   */
  bool _checkForReturnOfInvalidType(Expression returnExpression, DartType expectedReturnType) {
    if (_enclosingFunction == null) {
      return false;
    }
    DartType staticReturnType = getStaticType(returnExpression);
    if (expectedReturnType.isVoid) {
      if (staticReturnType.isVoid || staticReturnType.isDynamic || staticReturnType.isBottom) {
        return false;
      }
      _errorReporter.reportTypeErrorForNode(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [
          staticReturnType,
          expectedReturnType,
          _enclosingFunction.displayName]);
      return true;
    }
    if (_enclosingFunction.isAsynchronous && !_enclosingFunction.isGenerator) {
      // TODO(brianwilkerson) Figure out how to get the type "Future" so that we can build the type
      // we need to test against.
      //      InterfaceType impliedType = "Future<" + flatten(staticReturnType) + ">"
      //      if (impliedType.isAssignableTo(expectedReturnType)) {
      //        return false;
      //      }
      //      errorReporter.reportTypeErrorForNode(
      //          StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
      //          returnExpression,
      //          impliedType,
      //          expectedReturnType.getDisplayName(),
      //          enclosingFunction.getDisplayName());
      //      return true;
      return false;
    }
    if (staticReturnType.isAssignableTo(expectedReturnType)) {
      return false;
    }
    _errorReporter.reportTypeErrorForNode(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [
        staticReturnType,
        expectedReturnType,
        _enclosingFunction.displayName]);
    return true;
    // TODO(brianwilkerson) Define a hint corresponding to the warning and report it if appropriate.
    //    Type propagatedReturnType = returnExpression.getPropagatedType();
    //    boolean isPropagatedAssignable = propagatedReturnType.isAssignableTo(expectedReturnType);
    //    if (isStaticAssignable || isPropagatedAssignable) {
    //      return false;
    //    }
    //    errorReporter.reportTypeErrorForNode(
    //        StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
    //        returnExpression,
    //        staticReturnType,
    //        expectedReturnType,
    //        enclosingFunction.getDisplayName());
    //    return true;
  }

  /**
   * This checks the given "typeReference" and that the "name" is not the reference to an instance
   * member.
   *
   * @param typeReference the resolved [ClassElement] of the left hand side of the expression,
   *          or `null`, aka, the class element of 'C' in 'C.x', see
   *          [getTypeReference]
   * @param name the accessed name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER].
   */
  bool _checkForStaticAccessToInstanceMember(ClassElement typeReference, SimpleIdentifier name) {
    // OK, target is not a type
    if (typeReference == null) {
      return false;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is! ExecutableElement) {
      return false;
    }
    ExecutableElement memberElement = element as ExecutableElement;
    // OK, static
    if (memberElement.isStatic) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, name, [name.name]);
    return true;
  }

  /**
   * This checks that the type of the passed 'switch' expression is assignable to the type of the
   * 'case' members.
   *
   * @param node the 'switch' statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE].
   */
  bool _checkForSwitchExpressionNotAssignable(SwitchStatement node) {
    // prepare 'switch' expression type
    Expression expression = node.expression;
    DartType expressionType = getStaticType(expression);
    if (expressionType == null) {
      return false;
    }
    // compare with type of the first 'case'
    NodeList<SwitchMember> members = node.members;
    for (SwitchMember switchMember in members) {
      if (switchMember is! SwitchCase) {
        continue;
      }
      SwitchCase switchCase = switchMember as SwitchCase;
      // prepare 'case' type
      Expression caseExpression = switchCase.expression;
      DartType caseType = getStaticType(caseExpression);
      // check types
      if (expressionType.isAssignableTo(caseType)) {
        return false;
      }
      // report problem
      _errorReporter.reportErrorForNode(StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, expression, [expressionType, caseType]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed function type alias does not reference itself directly.
   *
   * @param node the function type alias to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF].
   */
  bool _checkForTypeAliasCannotReferenceItself_function(FunctionTypeAlias node) {
    FunctionTypeAliasElement element = node.element;
    if (!_hasTypedefSelfReference(element)) {
      return false;
    }
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, node);
    return true;
  }

  /**
   * This verifies that the passed type name is not a deferred type.
   *
   * @param expression the expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS].
   */
  bool _checkForTypeAnnotationDeferredClass(TypeName node) {
    if (node != null && node.isDeferred) {
      _errorReporter.reportErrorForNode(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, node, [node.name]);
    }
    return false;
  }

  /**
   * This verifies that the type arguments in the passed type name are all within their bounds.
   *
   * @param node the [TypeName] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  bool _checkForTypeArgumentNotMatchingBounds(TypeName node) {
    if (node.typeArguments == null) {
      return false;
    }
    // prepare Type
    DartType type = node.type;
    if (type == null) {
      return false;
    }
    // prepare ClassElement
    Element element = type.element;
    if (element is! ClassElement) {
      return false;
    }
    ClassElement classElement = element as ClassElement;
    // prepare type parameters
    List<DartType> typeParameters = classElement.type.typeArguments;
    List<TypeParameterElement> boundingElts = classElement.typeParameters;
    // iterate over each bounded type parameter and corresponding argument
    NodeList<TypeName> typeNameArgList = node.typeArguments.arguments;
    List<DartType> typeArguments = (type as InterfaceType).typeArguments;
    int loopThroughIndex = math.min(typeNameArgList.length, boundingElts.length);
    bool foundError = false;
    for (int i = 0; i < loopThroughIndex; i++) {
      TypeName argTypeName = typeNameArgList[i];
      DartType argType = argTypeName.type;
      DartType boundType = boundingElts[i].bound;
      if (argType != null && boundType != null) {
        if (typeArguments.length != 0 && typeArguments.length == typeParameters.length) {
          boundType = boundType.substitute2(typeArguments, typeParameters);
        }
        if (!argType.isSubtypeOf(boundType)) {
          ErrorCode errorCode;
          if (_isInConstInstanceCreation) {
            errorCode = CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
          } else {
            errorCode = StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
          }
          _errorReporter.reportTypeErrorForNode(errorCode, argTypeName, [argType, boundType]);
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This checks that if the passed type name is a type parameter being used to define a static
   * member.
   *
   * @param node the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC].
   */
  bool _checkForTypeParameterReferencedByStatic(TypeName node) {
    if (_isInStaticMethod || _isInStaticVariableDeclaration) {
      DartType type = node.type;
      if (type is TypeParameterType) {
        _errorReporter.reportErrorForNode(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, node);
        return true;
      }
    }
    return false;
  }

  /**
   * This checks that if the passed type parameter is a supertype of its bound.
   *
   * @param node the type parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
   */
  bool _checkForTypeParameterSupertypeOfItsBound(TypeParameter node) {
    TypeParameterElement element = node.element;
    // prepare bound
    DartType bound = element.bound;
    if (bound == null) {
      return false;
    }
    // OK, type parameter is not supertype of its bound
    if (!bound.isMoreSpecificThan(element.type)) {
      return false;
    }
    // report problem
    _errorReporter.reportErrorForNode(StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, node, [element.displayName]);
    return true;
  }

  /**
   * This checks that if the passed generative constructor has neither an explicit super constructor
   * invocation nor a redirecting constructor invocation, that the superclass has a default
   * generative constructor.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT],
   * [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR], and
   * [StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT].
   */
  bool _checkForUndefinedConstructorInInitializerImplicit(ConstructorDeclaration node) {
    if (_enclosingClass == null) {
      return false;
    }
    // do nothing if mixin errors have already been reported for this class.
    ClassElementImpl enclosingClass = _enclosingClass;
    if (enclosingClass.mixinErrorsReported) {
      return false;
    }
    //
    // Ignore if the constructor is not generative.
    //
    if (node.factoryKeyword != null) {
      return false;
    }
    //
    // Ignore if the constructor has either an implicit super constructor invocation or a
    // redirecting constructor invocation.
    //
    for (ConstructorInitializer constructorInitializer in node.initializers) {
      if (constructorInitializer is SuperConstructorInvocation || constructorInitializer is RedirectingConstructorInvocation) {
        return false;
      }
    }
    //
    // Check to see whether the superclass has a non-factory unnamed constructor.
    //
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement superElement = superType.element;
    ConstructorElement superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node.returnType, [superUnnamedConstructor]);
        return true;
      }
      if (!superUnnamedConstructor.isDefaultConstructor ||
          !_enclosingClass.isSuperConstructorAccessible(
              superUnnamedConstructor)) {
        int offset;
        int length;
        {
          Identifier returnType = node.returnType;
          SimpleIdentifier name = node.name;
          offset = returnType.offset;
          length = (name != null ? name.end : returnType.end) - offset;
        }
        _errorReporter.reportErrorForOffset(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, offset, length, [superType.displayName]);
      }
      return false;
    }
    _errorReporter.reportErrorForNode(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, node.returnType, [superElement.name]);
    return true;
  }

  /**
   * This checks that if the given name is a reference to a static member it is defined in the
   * enclosing class rather than in a superclass.
   *
   * @param name the name to be evaluated
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
   */
  bool _checkForUnqualifiedReferenceToNonLocalStaticMember(SimpleIdentifier name) {
    Element element = name.staticElement;
    if (element == null || element is TypeParameterElement) {
      return false;
    }
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return false;
    }
    if ((element is MethodElement && !element.isStatic) || (element is PropertyAccessorElement && !element.isStatic)) {
      return false;
    }
    if (identical(enclosingElement, _enclosingClass)) {
      return false;
    }
    _errorReporter.reportErrorForNode(StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER, name, [name.name]);
    return true;
  }

  void _checkForValidField(FieldFormalParameter node) {
    ParameterElement element = node.element;
    if (element is FieldFormalParameterElement) {
      FieldElement fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, node, [node.identifier.name]);
      } else {
        ParameterElement parameterElement = node.element;
        if (parameterElement is FieldFormalParameterElementImpl) {
          FieldFormalParameterElementImpl fieldFormal = parameterElement;
          DartType declaredType = fieldFormal.type;
          DartType fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, node, [node.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [node.identifier.name]);
          } else if (declaredType != null && fieldType != null && !declaredType.isAssignableTo(fieldType)) {
            _errorReporter.reportTypeErrorForNode(StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, node, [declaredType, fieldType]);
          }
        } else {
          if (fieldElement.isSynthetic) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, node, [node.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportErrorForNode(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [node.identifier.name]);
          }
        }
      }
    }
    //    else {
    //    // TODO(jwren) Report error, constructor initializer variable is a top level element
    //    // (Either here or in ErrorVerifier.checkForAllFinalInitializedErrorCodes)
    //    }
  }

  /**
   * This verifies that the given getter does not have a return type of 'void'.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.VOID_RETURN_FOR_GETTER].
   */
  bool _checkForVoidReturnType(MethodDeclaration node) {
    TypeName returnType = node.returnType;
    if (returnType == null || returnType.name.name != "void") {
      return false;
    }
    _errorReporter.reportErrorForNode(StaticWarningCode.VOID_RETURN_FOR_GETTER, returnType);
    return true;
  }

  /**
   * This verifies the passed operator-method declaration, has correct number of parameters.
   *
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR].
   */
  bool _checkForWrongNumberOfParametersForOperator(MethodDeclaration node) {
    // prepare number of parameters
    FormalParameterList parameterList = node.parameters;
    if (parameterList == null) {
      return false;
    }
    int numParameters = parameterList.parameters.length;
    // prepare operator name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // check for exact number of parameters
    int expected = -1;
    if ("[]=" == name) {
      expected = 2;
    } else if ("<" == name || ">" == name || "<=" == name || ">=" == name || "==" == name || "+" == name || "/" == name || "~/" == name || "*" == name || "%" == name || "|" == name || "^" == name || "&" == name || "<<" == name || ">>" == name || "[]" == name) {
      expected = 1;
    } else if ("~" == name) {
      expected = 0;
    }
    if (expected != -1 && numParameters != expected) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, nameNode, [name, expected, numParameters]);
      return true;
    }
    // check for operator "-"
    if ("-" == name && numParameters > 1) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS, nameNode, [numParameters]);
      return true;
    }
    // OK
    return false;
  }

  /**
   * This verifies if the passed setter parameter list have only one required parameter.
   *
   * This method assumes that the method declaration was tested to be a setter before being called.
   *
   * @param setterName the name of the setter to report problems on
   * @param parameterList the parameter list to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER].
   */
  bool _checkForWrongNumberOfParametersForSetter(SimpleIdentifier setterName, FormalParameterList parameterList) {
    if (setterName == null) {
      return false;
    }
    if (parameterList == null) {
      return false;
    }
    NodeList<FormalParameter> parameters = parameterList.parameters;
    if (parameters.length != 1 || parameters[0].kind != ParameterKind.REQUIRED) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, setterName);
      return true;
    }
    return false;
  }

  /**
   * This verifies that if the given class declaration implements the class Function that it has a
   * concrete implementation of the call method.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [StaticWarningCode.FUNCTION_WITHOUT_CALL].
   */
  bool _checkImplementsFunctionWithoutCall(ClassDeclaration node) {
    if (node.isAbstract) {
      return false;
    }
    ClassElement classElement = node.element;
    if (classElement == null) {
      return false;
    }
    if (!classElement.type.isSubtypeOf(_typeProvider.functionType)) {
      return false;
    }
    // If there is a noSuchMethod method, then don't report the warning, see dartbug.com/16078
    if (classElement.getMethod(FunctionElement.NO_SUCH_METHOD_METHOD_NAME) != null) {
      return false;
    }
    ExecutableElement callMethod = _inheritanceManager.lookupMember(classElement, "call");
    if (callMethod == null || callMethod is! MethodElement || (callMethod as MethodElement).isAbstract) {
      _errorReporter.reportErrorForNode(StaticWarningCode.FUNCTION_WITHOUT_CALL, node.name);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the given class declaration does not have the same class in the 'extends'
   * and 'implements' clauses.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
   */
  bool _checkImplementsSuperClass(ClassDeclaration node) {
    // prepare super type
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    // prepare interfaces
    ImplementsClause implementsClause = node.implementsClause;
    if (implementsClause == null) {
      return false;
    }
    // check interfaces
    bool hasProblem = false;
    for (TypeName interfaceNode in implementsClause.interfaces) {
      if (interfaceNode.type == superType) {
        hasProblem = true;
        _errorReporter.reportErrorForNode(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, interfaceNode, [superType.displayName]);
      }
    }
    // done
    return hasProblem;
  }

  /**
   * Return the error code that should be used when the given class references itself directly.
   *
   * @param classElt the class that references itself
   * @return the error code that should be used
   */
  ErrorCode _getBaseCaseErrorCode(ClassElement classElt) {
    InterfaceType supertype = classElt.supertype;
    if (supertype != null && _enclosingClass == supertype.element) {
      return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS;
    }
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = 0; i < mixins.length; i++) {
      if (_enclosingClass == mixins[i].element) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH;
      }
    }
    return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS;
  }

  /**
   * Given an expression in a switch case whose value is expected to be an enum constant, return the
   * name of the constant.
   *
   * @param expression the expression from the switch case
   * @return the name of the constant referenced by the expression
   */
  String _getConstantName(Expression expression) {
    // TODO(brianwilkerson) Convert this to return the element representing the constant.
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
   * Returns the Type (return type) for a given getter.
   *
   * @param propertyAccessorElement
   * @return The type of the given getter.
   */
  DartType _getGetterType(PropertyAccessorElement propertyAccessorElement) {
    FunctionType functionType = propertyAccessorElement.type;
    if (functionType != null) {
      return functionType.returnType;
    } else {
      return null;
    }
  }

  /**
   * Returns the Type (first and only parameter) for a given setter.
   *
   * @param propertyAccessorElement
   * @return The type of the given setter.
   */
  DartType _getSetterType(PropertyAccessorElement propertyAccessorElement) {
    // Get the parameters for MethodDeclaration or FunctionDeclaration
    List<ParameterElement> setterParameters = propertyAccessorElement.parameters;
    // If there are no setter parameters, return no type.
    if (setterParameters.length == 0) {
      return null;
    }
    return setterParameters[0].type;
  }

  /**
   * Given a list of directives that have the same prefix, generate an error if there is more than
   * one import and any of those imports is deferred.
   *
   * @param directives the list of directives that have the same prefix
   * @return `true` if an error was generated
   * See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
   */
  bool _hasDeferredPrefixCollision(List<ImportDirective> directives) {
    bool foundError = false;
    int count = directives.length;
    if (count > 1) {
      for (int i = 0; i < count; i++) {
        sc.Token deferredToken = directives[i].deferredToken;
        if (deferredToken != null) {
          _errorReporter.reportErrorForToken(CompileTimeErrorCode.SHARED_DEFERRED_PREFIX, deferredToken);
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * @return `true` if the given constructor redirects to itself, directly or indirectly
   */
  bool _hasRedirectingFactoryConstructorCycle(ConstructorElement element) {
    Set<ConstructorElement> constructors = new HashSet<ConstructorElement>();
    ConstructorElement current = element;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, element);
      }
      constructors.add(current);
      current = current.redirectedConstructor;
      if (current is ConstructorMember) {
        current = (current as ConstructorMember).baseElement;
      }
    }
    return false;
  }

  /**
   * @return <code>true</code> if given [Element] has direct or indirect reference to itself
   *         from anywhere except [ClassElement] or type parameter bounds.
   */
  bool _hasTypedefSelfReference(Element target) {
    Set<Element> checked = new HashSet<Element>();
    List<Element> toCheck = new List<Element>();
    GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference elementVisitor =
        new GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(toCheck);
    toCheck.add(target);
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
        if (target == current) {
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
    if (type.isDynamic || type.isBottom) {
      return true;
    } else if (type is FunctionType || type.isDartCoreFunction) {
      return true;
    } else if (type is InterfaceType) {
      MethodElement callMethod = type.lookUpMethod(FunctionElement.CALL_METHOD_NAME, _currentLibrary);
      return callMethod != null;
    }
    return false;
  }

  /**
   * Return `true` iff the passed [ClassElement] has a method, getter or setter that
   * matches the name of the passed [ExecutableElement] in either the class itself, or one of
   * its' mixins that is concrete.
   *
   * By "match", only the name of the member is tested to match, it does not have to equal or be a
   * subtype of the passed executable element, this is due to the specific use where this method is
   * used in [checkForNonAbstractClassInheritsAbstractMember].
   *
   * @param executableElt the executable to search for in the passed class element
   * @param classElt the class method to search through the members of
   * @return `true` iff the passed member is found in the passed class element
   */
  bool _isMemberInClassOrMixin(ExecutableElement executableElt, ClassElement classElt) {
    ExecutableElement foundElt = null;
    String executableName = executableElt.name;
    if (executableElt is MethodElement) {
      foundElt = classElt.getMethod(executableName);
      if (foundElt != null && !(foundElt as MethodElement).isAbstract) {
        return true;
      }
      List<InterfaceType> mixins = classElt.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getMethod(executableName);
      }
      if (foundElt != null && !(foundElt as MethodElement).isAbstract) {
        return true;
      }
    } else if (executableElt is PropertyAccessorElement) {
      PropertyAccessorElement propertyAccessorElement = executableElt;
      if (propertyAccessorElement.isGetter) {
        foundElt = classElt.getGetter(executableName);
      }
      if (foundElt == null && propertyAccessorElement.isSetter) {
        foundElt = classElt.getSetter(executableName);
      }
      if (foundElt != null && !(foundElt as PropertyAccessorElement).isAbstract) {
        return true;
      }
      List<InterfaceType> mixins = classElt.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getGetter(executableName);
        if (foundElt == null) {
          foundElt = mixins[i].getSetter(executableName);
        }
      }
      if (foundElt != null && !(foundElt as PropertyAccessorElement).isAbstract) {
        return true;
      }
    }
    return false;
  }

  /**
   * @param node the 'this' expression to analyze
   * @return `true` if the given 'this' expression is in the valid context
   */
  bool _isThisInValidContext(ThisExpression node) {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is CompilationUnit) {
        return false;
      }
      if (n is ConstructorDeclaration) {
        ConstructorDeclaration constructor = n as ConstructorDeclaration;
        return constructor.factoryKeyword == null;
      }
      if (n is ConstructorInitializer) {
        return false;
      }
      if (n is MethodDeclaration) {
        MethodDeclaration method = n as MethodDeclaration;
        return !method.isStatic;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given identifier is in a location where it is allowed to resolve to
   * a static member of a supertype.
   *
   * @param node the node being tested
   * @return `true` if the given identifier is in a location where it is allowed to resolve to
   *         a static member of a supertype
   */
  bool _isUnqualifiedReferenceToNonLocalStaticMemberAllowed(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return true;
    }
    AstNode parent = node.parent;
    if (parent is ConstructorName || parent is MethodInvocation || parent is PropertyAccess || parent is SuperConstructorInvocation) {
      return true;
    }
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return true;
    }
    if (parent is Annotation && identical(parent.constructorName, node)) {
      return true;
    }
    if (parent is CommentReference) {
      CommentReference commentReference = parent;
      if (commentReference.newKeyword != null) {
        return true;
      }
    }
    return false;
  }

  bool _isUserDefinedObject(EvaluationResultImpl result) => result == null || (result.value != null && result.value.isUserDefinedObject);

  /**
   * This checks the class declaration is not a superinterface to itself.
   *
   * @param classElt the class element to test
   * @param path a list containing the potentially cyclic implements path
   * @return `true` if and only if an error code is generated on the passed element
   * See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS],
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS], and
   * [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH].
   */
  bool _safeCheckForRecursiveInterfaceInheritance(ClassElement classElt, List<ClassElement> path) {
    // Detect error condition.
    int size = path.length;
    // If this is not the base case (size > 0), and the enclosing class is the passed class
    // element then an error an error.
    if (size > 0 && _enclosingClass == classElt) {
      String enclosingClassName = _enclosingClass.displayName;
      if (size > 1) {
        // Construct a string showing the cyclic implements path: "A, B, C, D, A"
        String separator = ", ";
        StringBuffer buffer = new StringBuffer();
        for (int i = 0; i < size; i++) {
          buffer.write(path[i].displayName);
          buffer.write(separator);
        }
        buffer.write(classElt.displayName);
        _errorReporter.reportErrorForOffset(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName, buffer.toString()]);
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH
        _errorReporter.reportErrorForOffset(_getBaseCaseErrorCode(classElt), _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName]);
        return true;
      }
    }
    if (path.indexOf(classElt) > 0) {
      return false;
    }
    path.add(classElt);
    // n-case
    InterfaceType supertype = classElt.supertype;
    if (supertype != null && _safeCheckForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }
    List<InterfaceType> interfaceTypes = classElt.interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      if (_safeCheckForRecursiveInterfaceInheritance(interfaceType.element, path)) {
        return true;
      }
    }
    List<InterfaceType> mixinTypes = classElt.mixins;
    for (InterfaceType mixinType in mixinTypes) {
      if (_safeCheckForRecursiveInterfaceInheritance(mixinType.element, path)) {
        return true;
      }
    }
    path.removeAt(path.length - 1);
    return false;
  }
}

class GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference extends GeneralizingElementVisitor<Object> {
  List<Element> toCheck;

  GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(
      this.toCheck) : super();

  @override
  Object visitClassElement(ClassElement element) {
    // Typedefs are allowed to reference themselves via classes.
    return null;
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
      InterfaceType interfaceType = type;
      for (DartType typeArgument in interfaceType.typeArguments) {
        _addTypeToCheck(typeArgument);
      }
    }
  }
}

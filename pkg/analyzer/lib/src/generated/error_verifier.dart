// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/literal_element_verifier.dart';
import 'package:analyzer/src/error/pending_error.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk, SdkLibrary;
import 'package:analyzer/src/generated/source.dart';

/**
 * A visitor used to traverse an AST structure looking for additional errors and
 * warnings not covered by the parser and resolver.
 */
class ErrorVerifier extends RecursiveAstVisitor<void> {
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
  final InheritanceManager2 _inheritanceManager;

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
  Map<FieldElement, INIT_STATE> _initialFieldElementsMap;

  /**
   * A table mapping name of the library to the export directive which export
   * this library.
   */
  Map<String, LibraryElement> _nameToExportElement =
      new HashMap<String, LibraryElement>();

  /**
   * A table mapping name of the library to the import directive which import
   * this library.
   */
  Map<String, LibraryElement> _nameToImportElement =
      new HashMap<String, LibraryElement>();

  /**
   * A table mapping names to the exported elements.
   */
  Map<String, Element> _exportedElements = new HashMap<String, Element>();

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

  final _UninstantiatedBoundChecker _uninstantiatedBoundChecker;

  /// Setting this flag to `true` disables the check for conflicting generics.
  /// This is used when running with the old task model to work around
  /// dartbug.com/32421.
  ///
  /// TODO(paulberry): remove this flag once dartbug.com/32421 is properly
  /// fixed.
  final bool disableConflictingGenericsCheck;

  bool _isNonNullable = false;

  /**
   * Initialize a newly created error verifier.
   */
  ErrorVerifier(ErrorReporter errorReporter, this._currentLibrary,
      this._typeProvider, this._inheritanceManager, bool enableSuperMixins,
      {this.disableConflictingGenericsCheck: false})
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

  /**
   * If `true`, mixins are allowed to inherit from types other than Object, and
   * are allowed to reference `super`.
   */
  @deprecated
  bool get enableSuperMixins => false;

  ClassElement get enclosingClass => _enclosingClass;

  /**
   * For consumers of error verification as a library, (currently just the
   * angular plugin), expose a setter that can make the errors reported more
   * accurate when dangling code snippets are being resolved from a class
   * context. Note that this setter is very defensive for potential misuse; it
   * should not be modified in the middle of visiting a tree and requires an
   * analyzer-provided Impl instance to work.
   */
  set enclosingClass(ClassElement classElement) {
    assert(classElement is ClassElementImpl);
    assert(_enclosingClass == null);
    assert(_enclosingEnum == null);
    assert(_enclosingFunction == null);
    _enclosingClass = classElement;
  }

  @override
  void visitAnnotation(Annotation node) {
    _checkForInvalidAnnotationFromDeferredLibrary(node);
    _checkForMissingJSLibAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _checkForArgumentTypesNotAssignableInList(node);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _checkForNonBoolExpression(node);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _checkForNonBoolExpression(node);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    Expression rhs = node.rightHandSide;
    if (operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForInvalidAssignment(lhs, rhs);
    } else {
      _checkForInvalidCompoundAssignment(node, lhs, rhs);
      _checkForArgumentTypeNotAssignableForArgument(rhs);
      _checkForNullableDereference(lhs);
    }
    _checkForAssignmentToFinal(lhs);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (!_inAsync) {
      _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, node.awaitKeyword);
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    TokenType type = operator.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      String lexeme = operator.lexeme;
      _checkForAssignability(node.leftOperand, _boolType,
          StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
      _checkForAssignability(node.rightOperand, _boolType,
          StaticTypeWarningCode.NON_BOOL_OPERAND, [lexeme]);
      _checkForUseOfVoidResult(node.rightOperand);
      _checkForNullableDereference(node.leftOperand);
      _checkForNullableDereference(node.rightOperand);
    } else if (type != TokenType.EQ_EQ &&
        type != TokenType.BANG_EQ &&
        type != TokenType.QUESTION_QUESTION) {
      _checkForArgumentTypeNotAssignableForArgument(node.rightOperand);
      _checkForNullableDereference(node.leftOperand);
    } else {
      _checkForArgumentTypeNotAssignableForArgument(node.rightOperand);
    }

    _checkForUseOfVoidResult(node.leftOperand);

    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    _hiddenElements = new HiddenElements(_hiddenElements, node);
    try {
      _checkDuplicateDeclarationInStatements(node.statements);
      super.visitBlock(node);
    } finally {
      _hiddenElements = _hiddenElements.outerElements;
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
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
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        _errorReporter.reportErrorForNode(
            ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode);
      }
    }
  }

  void visitCascadeExpression(CascadeExpression node) {
    _checkForNullableDereference(node.target);
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _checkDuplicateDefinitionInCatchClause(node);
    bool previousIsInCatchClause = _isInCatchClause;
    try {
      _isInCatchClause = true;
      _checkForTypeAnnotationDeferredClass(node.exceptionType);
      _checkForPotentiallyNullableType(node.exceptionType);
      super.visitCatchClause(node);
    } finally {
      _isInCatchClause = previousIsInCatchClause;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    ClassElementImpl outerClass = _enclosingClass;
    try {
      _isInNativeClass = node.nativeClause != null;
      _enclosingClass = AbstractClassElementImpl.getImpl(node.declaredElement);

      List<ClassMember> members = node.members;
      _checkDuplicateClassMembers(members);
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForMemberWithClassName();
      _checkForNoDefaultSuperConstructorImplicit(node);
      _checkForConflictingTypeVariableErrorCodes();
      TypeName superclass = node.extendsClause?.superclass;
      ImplementsClause implementsClause = node.implementsClause;
      WithClause withClause = node.withClause;

      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null ||
          superclass != null ||
          withClause != null) {
        _checkClassInheritance(node, superclass, withClause, implementsClause);
      }

      _initializeInitialFieldElementsMap(_enclosingClass.fields);
      _checkForFinalNotInitializedInClass(members);
      _checkForBadFunctionUse(node);
      super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _initialFieldElementsMap = null;
      _enclosingClass = outerClass;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    ClassElementImpl outerClassElement = _enclosingClass;
    try {
      _enclosingClass = AbstractClassElementImpl.getImpl(node.declaredElement);
      _checkClassInheritance(
          node, node.superclass, node.withClause, node.implementsClause);
    } finally {
      _enclosingClass = outerClassElement;
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _isInComment = true;
    try {
      super.visitComment(node);
    } finally {
      _isInComment = false;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _isNonNullable = (node as CompilationUnitImpl).isNonNullable;
    _checkDuplicateUnitMembers(node);
    _checkForDeferredPrefixCollisions(node);
    super.visitCompilationUnit(node);
    _isNonNullable = false;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _checkForNonBoolCondition(node.condition);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      ConstructorElement constructorElement = node.declaredElement;
      _enclosingFunction = constructorElement;
      _isEnclosingConstructorConst = node.constKeyword != null;
      _isInFactory = node.factoryKeyword != null;
      _checkForInvalidModifierOnBody(
          node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR);
      _checkForConstConstructorWithNonFinalField(node, constructorElement);
      _checkForConstConstructorWithNonConstSuper(node);
      _checkForAllFinalInitializedErrorCodes(node);
      _checkForRedirectingConstructorErrorCodes(node);
      _checkForMixinDeclaresConstructor(node);
      _checkForMultipleSuperInitializers(node);
      _checkForRecursiveConstructorRedirect(node, constructorElement);
      if (!_checkForRecursiveFactoryRedirect(node, constructorElement)) {
        _checkForAllRedirectConstructorErrorCodes(node);
      }
      _checkForUndefinedConstructorInInitializerImplicit(node);
      _checkForRedirectToNonConstConstructor(node, constructorElement);
      _checkForReturnInGenerativeConstructor(node);
      super.visitConstructorDeclaration(node);
    } finally {
      _isEnclosingConstructorConst = false;
      _isInFactory = false;
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      SimpleIdentifier fieldName = node.fieldName;
      Element staticElement = fieldName.staticElement;
      _checkForInvalidField(node, fieldName, staticElement);
      if (staticElement is FieldElement) {
        _checkForFieldInitializerNotAssignable(node, staticElement);
      }
      super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl &&
          labelElement.isOnSwitchStatement) {
        _errorReporter.reportErrorForNode(
            ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode);
      }
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _checkForInvalidAssignment(node.identifier, node.defaultValue);
    _checkForDefaultValueInFunctionTypedParameter(node);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkForNonBoolCondition(node.condition);
    super.visitDoStatement(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    ClassElement outerEnum = _enclosingEnum;
    try {
      _enclosingEnum = node.declaredElement;
      _checkDuplicateEnumMembers(node);
      super.visitEnumDeclaration(node);
    } finally {
      _enclosingEnum = outerEnum;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      LibraryElement exportedLibrary = exportElement.exportedLibrary;
      _checkForAmbiguousExport(node, exportElement, exportedLibrary);
      _checkForExportDuplicateLibraryName(node, exportElement, exportedLibrary);
      _checkForExportInternalLibrary(node, exportElement);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
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
      super.visitExpressionFunctionBody(node);
    } finally {
      _inAsync = wasInAsync;
      _inGenerator = wasInGenerator;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
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
      super.visitFieldDeclaration(node);
    } finally {
      _isInStaticVariableDeclaration = false;
      _isInInstanceVariableDeclaration = false;
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkForValidField(node);
    _checkForConstFormalParameter(node);
    _checkForPrivateOptionalParameter(node);
    _checkForFieldInitializingFormalRedirectingConstructor(node);
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      // Ignore malformed for statements.
      return;
    }
    if (_checkForEachParts(node, loopVariable.identifier)) {
      if (loopVariable.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE, loopVariable);
      }
    }
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    SimpleIdentifier identifier = node.identifier;
    if (identifier == null) {
      // Ignore malformed for statements.
      return;
    }
    if (_checkForEachParts(node, identifier)) {
      Element variableElement = identifier.staticElement;
      if (variableElement is VariableElement && variableElement.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE, identifier);
      }
    }
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _checkDuplicateDefinitionInParameterList(node);
    _checkUseOfCovariantInParameters(node);
    _checkUseOfDefaultValuesInParameters(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (node.condition != null) {
      _checkForNonBoolCondition(node.condition);
    }
    if (node.variables != null) {
      _checkDuplicateVariables(node.variables);
    }
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    if (node.condition != null) {
      _checkForNonBoolCondition(node.condition);
    }
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement functionElement = node.declaredElement;
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
      _checkForImplicitDynamicReturn(node.name, node.declaredElement);
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // If this function expression is wrapped in a function declaration, don't
    // change the enclosingFunction field.
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
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
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression functionExpression = node.function;
    DartType expressionType = functionExpression.staticType;
    if (!_checkForNullableDereference(functionExpression) &&
        !_checkForUseOfVoidResult(functionExpression) &&
        !_isFunctionType(expressionType)) {
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
          functionExpression);
    } else if (expressionType is FunctionType) {
      _checkTypeArguments(node);
    }
    _checkForImplicitDynamicInvoke(node);
    _checkForNullableDereference(node.function);
    _checkForMissingRequiredParam(
        node.staticInvokeType, node.argumentList, node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForDefaultValueInFunctionTypeAlias(node);
    _checkForTypeAliasCannotReferenceItself_function(node);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
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
      if (node.typeParameters != null && !AnalysisDriver.useSummary2) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED,
            node);
      }

      super.visitFunctionTypedFormalParameter(node);
    } finally {
      _isInFunctionTypedFormalParameter = old;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (_hasTypedefSelfReference(node.declaredElement)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, node);
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _checkForNonBoolCondition(node.condition);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _checkForNonBoolCondition(node.condition);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.forEach(_checkForImplicitDynamicType);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (node.prefix != null) {
      _checkForBuiltInIdentifierAsName(
          node.prefix, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME);
    }
    if (importElement != null) {
      _checkForImportDuplicateLibraryName(node, importElement);
      _checkForImportInternalLibrary(node, importElement);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _checkForArgumentTypeNotAssignableForArgument(node.index);
    _checkForNullableDereference(node.target);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    bool wasInConstInstanceCreation = _isInConstInstanceCreation;
    _isInConstInstanceCreation = node.isConst;
    try {
      ConstructorName constructorName = node.constructorName;
      TypeName typeName = constructorName.type;
      DartType type = typeName.type;
      if (type is InterfaceType) {
        _checkForConstOrNewWithAbstractClass(node, typeName, type);
        _checkForConstOrNewWithEnum(node, typeName, type);
        _checkForConstOrNewWithMixin(node, typeName, type);
        _checkForMissingRequiredParam(
            node.staticElement?.type, node.argumentList, node.constructorName);
        if (_isInConstInstanceCreation) {
          _checkForConstWithNonConst(node);
          _checkForConstWithUndefinedConstructor(
              node, constructorName, typeName);
          _checkForConstDeferredClass(node, constructorName, typeName);
        } else {
          _checkForNewWithUndefinedConstructor(node, constructorName, typeName);
        }
        _checkForListConstructor(node, type);
      }
      _checkForImplicitDynamicType(typeName);
      super.visitInstanceCreationExpression(node);
    } finally {
      _isInConstInstanceCreation = wasInConstInstanceCreation;
    }
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _checkForOutOfRange(node);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _checkForUseOfVoidResult(node.expression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    _checkForUseOfVoidResult(node.expression);
    super.visitIsExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        NodeList<TypeAnnotation> arguments = typeArguments.arguments;
        if (arguments.isNotEmpty) {
          _checkForInvalidTypeArgumentInConstTypedLiteral(arguments,
              CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST);
        }
      }
      _checkTypeArgumentCount(typeArguments, 1,
          StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS);
    }
    _checkForInferenceFailureOnCollectionLiteral(node);
    _checkForImplicitDynamicTypedLiteral(node);
    _checkForListElementTypeNotAssignable(node);

    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _enclosingFunction;
    try {
      _isInStaticMethod = node.isStatic;
      _enclosingFunction = node.declaredElement;
      TypeAnnotation returnType = node.returnType;
      if (node.isSetter) {
        _checkForInvalidModifierOnBody(
            node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER);
        _checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        _checkForNonVoidReturnTypeForSetter(returnType);
      } else if (node.isOperator) {
        _checkForOptionalParameterInOperator(node);
        _checkForWrongNumberOfParametersForOperator(node);
        _checkForNonVoidReturnTypeForOperator(node);
      }
      _checkForTypeAnnotationDeferredClass(returnType);
      _checkForIllegalReturnType(returnType);
      _checkForImplicitDynamicReturn(node, node.declaredElement);
      _checkForMustCallSuper(node);
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = previousFunction;
      _isInStaticMethod = false;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      ClassElement typeReference = ElementResolver.getTypeReference(target);
      _checkForStaticAccessToInstanceMember(typeReference, methodName);
      _checkForInstanceAccessToStaticMember(typeReference, methodName);
      _checkForUnnecessaryNullAware(target, node.operator);
    } else {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(methodName);
      _checkForNullableDereference(node.function);
    }
    _checkTypeArguments(node);
    _checkForImplicitDynamicInvoke(node);
    _checkForMissingRequiredParam(
        node.staticInvokeType, node.argumentList, node.methodName);
    if (node.operator?.type != TokenType.QUESTION_PERIOD &&
        methodName.name != 'toString' &&
        methodName.name != 'noSuchMethod') {
      _checkForNullableDereference(target);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // TODO(scheglov) Verify for all mixin errors.
    ClassElementImpl outerClass = _enclosingClass;
    try {
      _enclosingClass = AbstractClassElementImpl.getImpl(node.declaredElement);

      List<ClassMember> members = node.members;
      _checkDuplicateClassMembers(members);
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForMemberWithClassName();
      _checkForConflictingTypeVariableErrorCodes();

      OnClause onClause = node.onClause;
      ImplementsClause implementsClause = node.implementsClause;

      // Only do error checks only if there is a non-null clause.
      if (onClause != null || implementsClause != null) {
        _checkMixinInheritance(node, onClause, implementsClause);
      }

      _initializeInitialFieldElementsMap(_enclosingClass.fields);
      _checkForFinalNotInitializedInClass(members);
      //      _checkForBadFunctionUse(node);
      super.visitMixinDeclaration(node);
    } finally {
      _initialFieldElementsMap = null;
      _enclosingClass = outerClass;
    }
  }

  @override
  void visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson) Figure out the right rule for when 'native' is
    // allowed.
    if (!_isInSystemLibrary) {
      _errorReporter.reportErrorForNode(
          ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, node);
    }
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSdkCode(node);
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) {
      _checkForAssignmentToFinal(node.operand);
      _checkForIntNotAssignable(node.operand);
      _checkForNullableDereference(node.operand);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is! Annotation) {
      ClassElement typeReference =
          ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, name);
    }
    String property = node.identifier.name;
    if (node.staticElement is ExecutableElement &&
        property != 'hashCode' &&
        property != 'runtimeType') {
      _checkForNullableDereference(node.prefix);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
    if (operatorType == TokenType.BANG) {
      _checkForNonBoolNegationExpression(operand);
    } else if (operatorType.isIncrementOperator) {
      _checkForAssignmentToFinal(operand);
    }
    _checkForIntNotAssignable(operand);
    _checkForNullableDereference(operand);
    _checkForUseOfVoidResult(operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    ClassElement typeReference =
        ElementResolver.getTypeReference(node.realTarget);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(typeReference, propertyName);
    if (node.operator?.type != TokenType.QUESTION_PERIOD &&
        propertyName.name != 'hashCode' &&
        propertyName.name != 'runtimeType') {
      _checkForNullableDereference(node.target);
    }
    _checkForUnnecessaryNullAware(node.target, node.operator);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    DartType type =
        resolutionMap.staticElementForConstructorReference(node)?.type;
    if (type != null) {
      _checkForMissingRequiredParam(type, node.argumentList, node);
    }
    _isInConstructorInitializer = true;
    try {
      super.visitRedirectingConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _checkForRethrowOutsideCatch(node);
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _returnsWithout.add(node);
    } else {
      _returnsWith.add(node);
    }
    _checkForAllReturnStatementErrorCodes(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (node.isMap) {
      if (typeArguments != null) {
        NodeList<TypeAnnotation> arguments = typeArguments.arguments;
        if (node.isConst) {
          if (arguments.isNotEmpty) {
            _checkForInvalidTypeArgumentInConstTypedLiteral(arguments,
                CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP);
          }
        }
        _checkTypeArgumentCount(typeArguments, 2,
            StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS);
      }
      _checkForInferenceFailureOnCollectionLiteral(node);
      _checkForImplicitDynamicTypedLiteral(node);
      _checkForMapTypeNotAssignable(node);
      _checkForNonConstMapAsExpressionStatement3(node);
    } else if (node.isSet) {
      if (typeArguments != null) {
        if (node.isConst) {
          NodeList<TypeAnnotation> arguments = typeArguments.arguments;
          if (arguments.isNotEmpty) {
            _checkForInvalidTypeArgumentInConstTypedLiteral(arguments,
                CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET);
          }
        }
        _checkTypeArgumentCount(typeArguments, 1,
            StaticTypeWarningCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS);
      }
      _checkForInferenceFailureOnCollectionLiteral(node);
      _checkForImplicitDynamicTypedLiteral(node);
      _checkForSetElementTypeNotAssignable3(node);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
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

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForAmbiguousImport(node);
    _checkForReferenceBeforeDeclaration(node);
    _checkForImplicitThisReferenceInInitializer(node);
    _checkForTypeParameterReferencedByStatic(node);
    if (!_isUnqualifiedReferenceToNonLocalStaticMemberAllowed(node)) {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    DartType type =
        resolutionMap.staticElementForConstructorReference(node)?.type;
    if (type != null) {
      _checkForMissingRequiredParam(type, node.argumentList, node);
    }
    _isInConstructorInitializer = true;
    try {
      super.visitSuperConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _checkDuplicateDeclarationInStatements(node.statements);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _checkDuplicateDeclarationInStatements(node.statements);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkForSwitchExpressionNotAssignable(node);
    _checkForCaseBlocksNotTerminated(node);
    _checkForMissingEnumConstantInSwitch(node);
    super.visitSwitchStatement(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _checkForInvalidReferenceToThis(node);
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _checkForConstEvalThrowsException(node);
    _checkForNullableDereference(node.expression);
    _checkForUseOfVoidResult(node.expression);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkForFinalNotInitialized(node.variables);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    NodeList<TypeAnnotation> list = node.arguments;
    for (TypeAnnotation type in list) {
      _checkForTypeAnnotationDeferredClass(type);
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeName(TypeName node) {
    _checkForTypeArgumentNotMatchingBounds(node);
    if (node.parent is ConstructorName &&
        node.parent.parent is InstanceCreationExpression) {
      _checkForInferenceFailureOnInstanceCreation(node, node.parent.parent);
    } else {
      _checkForRawTypeName(node);
    }
    super.visitTypeName(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _checkForBuiltInIdentifierAsName(node.name,
        CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    _checkForTypeParameterSupertypeOfItsBound(node);
    _checkForTypeAnnotationDeferredClass(node.bound);
    _checkForImplicitDynamicType(node.bound);
    _checkForGenericFunctionType(node.bound);
    node.bound?.accept(_uninstantiatedBoundChecker);
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _checkDuplicateDefinitionInTypeParameterList(node);
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    Expression initializerNode = node.initializer;
    // do checks
    _checkForInvalidAssignment(nameNode, initializerNode);
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
      VariableElement element = node.declaredElement;
      if (element != null) {
        // There is no hidden elements if we are outside of a function body,
        // which will happen for variables declared in control flow elements.
        _hiddenElements?.declare(element);
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _checkForFinalNotInitialized(node.variables);
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkForNonBoolCondition(node.condition);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.forEach(_checkForImplicitDynamicType);
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    if (_inGenerator) {
      _checkForYieldOfInvalidType(node.expression, node.star != null);
      if (node.star != null) {
        _checkForNullableDereference(node.expression);
      }
    } else {
      CompileTimeErrorCode errorCode;
      if (node.star != null) {
        errorCode = CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR;
      } else {
        errorCode = CompileTimeErrorCode.YIELD_IN_NON_GENERATOR;
      }
      _errorReporter.reportErrorForNode(errorCode, node);
    }
    _checkForUseOfVoidResult(node.expression);
    super.visitYieldStatement(node);
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
        !_checkForImplementsClauseErrorCodes(implementsClause) &&
        !_checkForAllMixinErrorCodes(withClause)) {
      _checkForImplicitDynamicType(superclass);
      _checkForExtendsDeferredClass(superclass);
      _checkForConflictingClassMembers();
      _checkForRepeatedType(implementsClause?.interfaces,
          CompileTimeErrorCode.IMPLEMENTS_REPEATED);
      _checkImplementsSuperClass(implementsClause);
      _checkMixinInference(node, withClause);
      _checkForMixinWithConflictingPrivateMember(withClause, superclass);
      if (!disableConflictingGenericsCheck) {
        _checkForConflictingGenerics(node);
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
  void _checkDuplicateClassMembers(List<ClassMember> members) {
    Set<String> constructorNames = new HashSet<String>();
    Map<String, Element> instanceGetters = new HashMap<String, Element>();
    Map<String, Element> instanceSetters = new HashMap<String, Element>();
    Map<String, Element> staticGetters = new HashMap<String, Element>();
    Map<String, Element> staticSetters = new HashMap<String, Element>();

    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        var name = member.name?.name ?? '';
        if (!constructorNames.add(name)) {
          if (name.isEmpty) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, member);
          } else {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
                member,
                [name]);
          }
        }
      } else if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          SimpleIdentifier identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
      }
    }

    // Check for local static members conflicting with local instance members.
    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        if (member.name != null) {
          String name = member.name.name;
          var staticMember = staticGetters[name] ?? staticSetters[name];
          if (staticMember != null) {
            if (staticMember is PropertyAccessorElement) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
                member.name,
                [name],
              );
            } else {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
                member.name,
                [name],
              );
            }
          }
        }
      } else if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            SimpleIdentifier identifier = field.name;
            String name = identifier.name;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              String className = _enclosingClass.displayName;
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                  identifier,
                  [className, name, className]);
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          SimpleIdentifier identifier = member.name;
          String name = identifier.name;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            String className = identifier.staticElement.enclosingElement.name;
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                identifier,
                [className, name, className]);
          }
        }
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
    ClassElement element = node.declaredElement;

    Map<String, Element> instanceGetters = new HashMap<String, Element>();
    Map<String, Element> staticGetters = new HashMap<String, Element>();

    String indexName = 'index';
    String valuesName = 'values';
    instanceGetters[indexName] = element.getGetter(indexName);
    staticGetters[valuesName] = element.getGetter(valuesName);

    for (EnumConstantDeclaration constant in node.constants) {
      _checkDuplicateIdentifier(staticGetters, constant.name);
    }

    for (EnumConstantDeclaration constant in node.constants) {
      SimpleIdentifier identifier = constant.name;
      String name = identifier.name;
      if (instanceGetters.containsKey(name)) {
        String enumName = element.displayName;
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            identifier,
            [enumName, name, enumName]);
      }
    }
  }

  /**
   * Check whether the given [element] defined by the [identifier] is already
   * in one of the scopes - [getterScope] or [setterScope], and produce an
   * error if it is.
   */
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, SimpleIdentifier identifier,
      {Element element, Map<String, Element> setterScope}) {
    element ??= identifier.staticElement;

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElement) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter, setterScope: setterScope);
      if (!element.isConst && !element.isFinal) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: element.setter, setterScope: setterScope);
      }
      return;
    }

    ErrorCode getError(Element previous, Element current) {
      if (previous is PrefixElement) {
        return CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    bool isGetterSetterPair(Element a, Element b) {
      if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
        return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
      }
      return false;
    }

    String name = identifier.name;
    if (element is MethodElement && element.isOperator && name == '-') {
      if (element.parameters.length == 0) {
        name = 'unary-';
      }
    }

    Element previous = getterScope[name];
    if (previous != null) {
      if (isGetterSetterPair(element, previous)) {
        // OK
      } else {
        _errorReporter.reportErrorForNode(
          getError(previous, element),
          identifier,
          [name],
        );
      }
    } else {
      getterScope[name] = element;
    }

    if (element is PropertyAccessorElement && element.isSetter) {
      previous = setterScope[name];
      if (previous != null) {
        _errorReporter.reportErrorForNode(
          getError(previous, element),
          identifier,
          [name],
        );
      } else {
        setterScope[name] = element;
      }
    }
  }

  /**
   * Check that there are no members with the same name.
   */
  void _checkDuplicateUnitMembers(CompilationUnit node) {
    Map<String, Element> definedGetters = new HashMap<String, Element>();
    Map<String, Element> definedSetters = new HashMap<String, Element>();

    void addWithoutChecking(CompilationUnitElement element) {
      for (PropertyAccessorElement accessor in element.accessors) {
        String name = accessor.name;
        if (accessor.isSetter) {
          name += '=';
        }
        definedGetters[name] = accessor;
      }
      for (ClassElement type in element.enums) {
        definedGetters[type.name] = type;
      }
      for (FunctionElement function in element.functions) {
        definedGetters[function.name] = function;
      }
      for (FunctionTypeAliasElement alias in element.functionTypeAliases) {
        definedGetters[alias.name] = alias;
      }
      for (TopLevelVariableElement variable in element.topLevelVariables) {
        definedGetters[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedGetters[variable.name + '='] = variable;
        }
      }
      for (ClassElement type in element.types) {
        definedGetters[type.name] = type;
      }
    }

    for (ImportElement importElement in _currentLibrary.imports) {
      PrefixElement prefix = importElement.prefix;
      if (prefix != null) {
        definedGetters[prefix.name] = prefix;
      }
    }
    CompilationUnitElement element = node.declaredElement;
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
        _checkDuplicateIdentifier(definedGetters, member.name,
            setterScope: definedSetters);
      } else if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedGetters, variable.name,
              setterScope: definedSetters);
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
   * Check that return statements without expressions are not in a generative
   * constructor and the return type is not assignable to `null`; that is, we
   * don't have `return;` if the enclosing method has a non-void containing
   * return type.
   *
   * See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR],
   * [StaticWarningCode.RETURN_WITHOUT_VALUE], and
   * [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE].
   */
  void _checkForAllEmptyReturnStatementErrorCodes(
      ReturnStatement statement, DartType expectedReturnType) {
    if (_inGenerator) {
      return;
    }
    var returnType =
        _inAsync ? _typeSystem.flatten(expectedReturnType) : expectedReturnType;
    if (returnType.isDynamic ||
        returnType.isDartCoreNull ||
        returnType.isVoid) {
      return;
    }
    // If we reach here, this is an invalid return
    _hasReturnWithoutValue = true;
    _errorReporter.reportErrorForNode(
        StaticWarningCode.RETURN_WITHOUT_VALUE, statement);
    return;
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

    Map<FieldElement, INIT_STATE> fieldElementsMap =
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
            (parameter.declaredElement as FieldFormalParameterElementImpl)
                .field;
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
        if (fieldElement.isFinal && !fieldElement.isLate) {
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
   * Verify that all classes of the given [withClause] are valid.
   *
   * See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
   * [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT], and
   * [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER].
   */
  bool _checkForAllMixinErrorCodes(WithClause withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    int mixinTypeIndex = -1;
    for (int mixinNameIndex = 0;
        mixinNameIndex < withClause.mixinTypes.length;
        mixinNameIndex++) {
      TypeName mixinName = withClause.mixinTypes[mixinNameIndex];
      DartType mixinType = mixinName.type;
      if (mixinType is InterfaceType) {
        mixinTypeIndex++;
        if (_checkForExtendsOrImplementsDisallowedClass(
            mixinName, CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          ClassElement mixinElement = mixinType.element;
          if (_checkForExtendsOrImplementsDeferredClass(
              mixinName, CompileTimeErrorCode.MIXIN_DEFERRED_CLASS)) {
            problemReported = true;
          }
          if (mixinElement.isMixin) {
            if (_checkForMixinSuperclassConstraints(
                mixinNameIndex, mixinName)) {
              problemReported = true;
            } else if (_checkForMixinSuperInvokedMembers(
                mixinTypeIndex, mixinName, mixinElement, mixinType)) {
              problemReported = true;
            }
          } else {
            if (_checkForMixinClassDeclaresConstructor(
                mixinName, mixinElement)) {
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
   * don't have `return;` if the enclosing method has a non-void containing
   * return type.
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
      _checkForAllEmptyReturnStatementErrorCodes(statement, expectedReturnType);
      return;
    } else if (_inGenerator) {
      // RETURN_IN_GENERATOR
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETURN_IN_GENERATOR,
          statement,
          [_inAsync ? "async*" : "sync*"]);
      return;
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
          prevElement.library.definingCompilationUnit.source.uri,
          element.library.definingCompilationUnit.source.uri
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
    }
  }

  /**
   * Verify that the given [expression] can be assigned to its corresponding
   * parameters. The [expectedStaticType] is the expected static type of the
   * parameter. The [actualStaticType] is the actual static type of the
   * argument.
   */
  void _checkForArgumentTypeNotAssignable(
      Expression expression,
      DartType expectedStaticType,
      DartType actualStaticType,
      ErrorCode errorCode) {
    // Warning case: test static type information
    if (actualStaticType != null && expectedStaticType != null) {
      if (!expectedStaticType.isVoid && _checkForUseOfVoidResult(expression)) {
        return;
      }

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
    if (_typeSystem.isAssignableTo(expressionType, type)) {
      return;
    }
    _errorReporter.reportErrorForNode(errorCode, expression, arguments);
  }

  bool _checkForAssignableExpression(
      Expression expression, DartType expectedStaticType, ErrorCode errorCode) {
    DartType actualStaticType = getStaticType(expression);
    return actualStaticType != null &&
        _checkForAssignableExpressionAtType(
            expression, actualStaticType, expectedStaticType, errorCode);
  }

  bool _checkForAssignableExpressionAtType(
      Expression expression,
      DartType actualStaticType,
      DartType expectedStaticType,
      ErrorCode errorCode) {
    if (!_typeSystem.isAssignableTo(actualStaticType, expectedStaticType)) {
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
        if (element is FieldElementImpl) {
          if (element.setter == null && element.isSynthetic) {
            _errorReporter.reportErrorForNode(
                StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
                highlightedNode,
                [element.name, element.enclosingElement.displayName]);
          } else {
            _errorReporter.reportErrorForNode(
                StaticWarningCode.ASSIGNMENT_TO_FINAL,
                highlightedNode,
                [element.name]);
          }
          return;
        }
        _errorReporter.reportErrorForNode(
            StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL,
            highlightedNode,
            [element.name]);
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
   * Verify that the [_enclosingClass] does not have a method and getter pair
   * with the same name on, via inheritance.
   *
   * See [CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE],
   * [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD], and
   * [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD].
   */
  void _checkForConflictingClassMembers() {
    if (_enclosingClass == null) {
      return;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    Uri libraryUri = _currentLibrary.source.uri;

    // method declared in the enclosing class vs. inherited getter/setter
    for (MethodElement method in _enclosingClass.methods) {
      String name = method.name;

      // find inherited property accessor
      ExecutableElement inherited = _inheritanceManager
          .getInherited(enclosingType, new Name(libraryUri, name))
          ?.element;
      inherited ??= _inheritanceManager
          .getInherited(enclosingType, new Name(libraryUri, '$name='))
          ?.element;

      if (method.isStatic && inherited != null) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, method, [
          _enclosingClass.displayName,
          name,
          inherited.enclosingElement.displayName,
        ]);
      } else if (inherited is PropertyAccessorElement) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, method, [
          _enclosingClass.displayName,
          name,
          inherited.enclosingElement.displayName
        ]);
      }
    }

    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      String name = accessor.displayName;

      // find inherited method or property accessor
      ExecutableElement inherited = _inheritanceManager
          .getInherited(enclosingType, new Name(libraryUri, name))
          ?.element;
      inherited ??= _inheritanceManager
          .getInherited(enclosingType, new Name(libraryUri, '$name='))
          ?.element;

      if (accessor.isStatic && inherited != null) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, accessor, [
          _enclosingClass.displayName,
          name,
          inherited.enclosingElement.displayName,
        ]);
      } else if (inherited is MethodElement) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, accessor, [
          _enclosingClass.displayName,
          name,
          inherited.enclosingElement.displayName
        ]);
      }
    }
  }

  void _checkForConflictingGenerics(NamedCompilationUnitMember node) {
    var visitedClasses = <ClassElement>[];
    var interfaces = <ClassElement, InterfaceType>{};
    void visit(InterfaceType type) {
      if (type == null) return;
      var element = type.element;
      if (visitedClasses.contains(element)) return;
      visitedClasses.add(element);
      if (element.typeParameters.isNotEmpty) {
        var oldType = interfaces[element];
        if (oldType == null) {
          interfaces[element] = type;
        } else if (!oldType.isEquivalentTo(type)) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES,
              node,
              [_enclosingClass.name, oldType, type]);
        }
      }
      visit(type.superclass);
      type.mixins.forEach(visit);
      type.superclassConstraints.forEach(visit);
      type.interfaces.forEach(visit);
      visitedClasses.removeLast();
    }

    visit(_enclosingClass.type);
  }

  /**
   * Verify all conflicts between type variable and enclosing class.
   * TODO(scheglov)
   *
   * See [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS], and
   * [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER].
   */
  void _checkForConflictingTypeVariableErrorCodes() {
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
    var hasInstanceField = false;
    for (var mixin in _enclosingClass.mixins) {
      var fields = mixin.element.fields;
      for (var i = 0; i < fields.length; ++i) {
        if (!fields[i].isStatic) {
          hasInstanceField = true;
          break;
        }
      }
    }
    if (hasInstanceField) {
      // TODO(scheglov) Provide the list of fields.
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
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
    if (type.element.isAbstract && !type.element.isMixin) {
      ConstructorElement element = expression.staticElement;
      if (element != null && !element.isFactory) {
        bool isImplicit =
            (expression as InstanceCreationExpressionImpl).isImplicit;
        if (!isImplicit) {
          _errorReporter.reportErrorForNode(
              expression.isConst
                  ? StaticWarningCode.CONST_WITH_ABSTRACT_CLASS
                  : StaticWarningCode.NEW_WITH_ABSTRACT_CLASS,
              typeName);
        } else {
          // TODO(brianwilkerson/jwren) Create a new different StaticWarningCode
          // which does not call out the new keyword so explicitly.
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
   * Verify that the given [expression] is not a mixin instantiation.
   */
  void _checkForConstOrNewWithMixin(InstanceCreationExpression expression,
      TypeName typeName, InterfaceType type) {
    if (type.element.isMixin) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_INSTANTIATE, typeName);
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
      Map<PrefixElement, List<ImportDirective>> prefixToDirectivesMap =
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
   * Return `true` if the caller should continue checking the rest of the
   * information in the for-each part.
   */
  bool _checkForEachParts(ForEachParts node, SimpleIdentifier variable) {
    if (_checkForNullableDereference(node.iterable)) {
      return false;
    }

    if (_checkForUseOfVoidResult(node.iterable)) {
      return false;
    }

    DartType iterableType = getStaticType(node.iterable);
    if (iterableType.isDynamic) {
      return false;
    }

    // The type of the loop variable.
    DartType variableType = getStaticType(variable);

    AstNode parent = node.parent;
    Token awaitKeyword;
    if (parent is ForStatement) {
      awaitKeyword = parent.awaitKeyword;
    } else if (parent is ForElement) {
      awaitKeyword = parent.awaitKeyword;
    }
    DartType loopType = awaitKeyword != null
        ? _typeProvider.streamType
        : _typeProvider.iterableType;

    // Use an explicit string instead of [loopType] to remove the "<E>".
    String loopTypeName = awaitKeyword != null ? "Stream" : "Iterable";

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
    } else if (!_typeSystem.isAssignableTo(bestIterableType, variableType)) {
      _errorReporter.reportTypeErrorForNode(
          StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
          node.iterable,
          [iterableType, loopTypeName, variableType]);
    }
    return true;
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
            prevLibrary.definingCompilationUnit.source.uri.toString(),
            exportedLibrary.definingCompilationUnit.source.uri.toString(),
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
      _errorReporter.reportErrorForNode(errorCode, typeName);
      return true;
    }
    return false;
  }

  /**
   * Verify that the given [typeName] does not extend, implement or mixin
   * classes such as 'num' or 'String'.
   *
   * TODO(scheglov) Remove this method, when all inheritance / override
   * is concentrated. We keep it for now only because we need to know when
   * inheritance is completely wrong, so that we don't need to check anything
   * else.
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
    return _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT.contains(typeName.type);
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
    if (_typeSystem.isAssignableTo(staticType, fieldType)) {
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
        } else if (!_isNonNullable || !variable.isLate) {
          _errorReporter.reportErrorForNode(
              StaticWarningCode.FINAL_NOT_INITIALIZED,
              variable.name,
              [variable.name.name]);
        }
      }
    }
  }

  /**
   * If there are no constructors in the given [members], verify that all
   * final fields are initialized.  Cases in which there is at least one
   * constructor are handled in [_checkForAllFinalInitializedErrorCodes].
   *
   * See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
   * [StaticWarningCode.FINAL_NOT_INITIALIZED].
   */
  void _checkForFinalNotInitializedInClass(List<ClassMember> members) {
    for (ClassMember classMember in members) {
      if (classMember is ConstructorDeclaration) {
        return;
      }
    }
    for (ClassMember classMember in members) {
      if (classMember is FieldDeclaration) {
        _checkForFinalNotInitialized(classMember.fields);
      }
    }
  }

  void _checkForGenericFunctionType(TypeAnnotation node) {
    if (node == null) {
      return;
    }
    DartType type = node.type;
    if (type is FunctionType && type.typeFormals.isNotEmpty) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND,
          node,
          [type]);
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
  }

  /**
   * Verify that the given implements [clause] does not implement classes such
   * as 'num' or 'String'.
   *
   * See [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS],
   * [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS].
   */
  bool _checkForImplementsClauseErrorCodes(ImplementsClause clause) {
    if (clause == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in clause.interfaces) {
      if (_checkForExtendsOrImplementsDisallowedClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS)) {
        foundError = true;
      } else if (_checkForExtendsOrImplementsDeferredClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS)) {
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
      // TODO(brianwilkerson) Add StrongModeCode.IMPLICIT_DYNAMIC_SET_LITERAL
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
          prevLibrary.definingCompilationUnit.source.uri,
          nodeLibrary.definingCompilationUnit.source.uri,
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
        directive.uri,
        [directive.uri.stringValue]);
  }

  /// Checks a collection literal for an inference failure, and reports the
  /// appropriate error if [AnalysisOptionsImpl.strictInference] is set.
  ///
  /// This checks if [node] does not have explicit or inferred type arguments.
  /// When that happens, it reports a
  /// HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL error.
  void _checkForInferenceFailureOnCollectionLiteral(TypedLiteral node) {
    if (!_options.strictInference || node == null) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    var type = node.staticType;
    if (_isMissingTypeArguments(node, type, type.element, node)) {
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, node, [type.name]);
    }
  }

  /// Checks a type on an instance creation expression for an inference
  /// failure, and reports the appropriate error if
  /// [AnalysisOptionsImpl.strictInference] is set.
  ///
  /// This checks if [node] refers to a generic type and does not have explicit
  /// or inferred type arguments. When that happens, it reports a
  /// HintMode.INFERENCE_FAILURE_ON_INSTANCE_CREATION error.
  void _checkForInferenceFailureOnInstanceCreation(
      TypeName node, InstanceCreationExpression inferenceContextNode) {
    if (!_options.strictInference || node == null) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    if (_isMissingTypeArguments(
        node, node.type, node.name.staticElement, inferenceContextNode)) {
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, node, [node.type]);
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
  void _checkForInvalidAssignment(Expression lhs, Expression rhs) {
    if (lhs == null || rhs == null) {
      return;
    }
    VariableElement leftVariableElement = getVariableElement(lhs);
    DartType leftType = (leftVariableElement == null)
        ? getStaticType(lhs)
        : leftVariableElement.type;

    if (!leftType.isVoid && _checkForUseOfVoidResult(rhs)) {
      return;
    }

    _checkForAssignableExpression(
        rhs, leftType, StaticTypeWarningCode.INVALID_ASSIGNMENT);
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

  void _checkForListConstructor(
      InstanceCreationExpression node, InterfaceType type) {
    if (node.argumentList.arguments.length == 1 &&
        _isDartCoreList(type) &&
        _typeSystem.isPotentiallyNonNullable(type.typeArguments[0])) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR_MISMATCH,
          node.constructorName);
    }
  }

  /**
   * Verify that the elements of the given list [literal] are subtypes of the
   * list's static type.
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
    var verifier = LiteralElementVerifier(
      _typeProvider,
      _typeSystem,
      _errorReporter,
      _checkForUseOfVoidResult,
      forList: true,
      elementType: listElementType,
    );
    for (CollectionElement element in literal.elements) {
      verifier.verify(element);
    }
  }

  void _checkForMapTypeNotAssignable(SetOrMapLiteral literal) {
    // Determine the map's key and value types. We base this on the static type
    // and not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType mapType = literal.staticType;
    if (mapType == null) {
      // This is known to happen when the literal is the default value in an
      // optional parameter in a generic function type alias.
      return;
    }
    assert(mapType is InterfaceTypeImpl);

    List<DartType> typeArguments = (mapType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-map type was selected.
    // TODO(brianwilkerson) Unify this and _checkForSetElementTypeNotAssignable3
    //  to better handle recovery situations.
    if (typeArguments.length == 2) {
      DartType keyType = typeArguments[0];
      DartType valueType = typeArguments[1];

      var verifier = LiteralElementVerifier(
        _typeProvider,
        _typeSystem,
        _errorReporter,
        _checkForUseOfVoidResult,
        forMap: true,
        mapKeyType: keyType,
        mapValueType: valueType,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
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
      if (className == accessor.displayName) {
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
   * See [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES].
   */
  void _checkForMismatchedAccessorTypes(
      Declaration accessorDeclaration, String accessorTextName) {
    ExecutableElement accessorElement =
        accessorDeclaration.declaredElement as ExecutableElement;
    if (accessorElement is PropertyAccessorElement) {
      PropertyAccessorElement counterpartAccessor = null;
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
        return;
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
        _errorReporter.reportTypeErrorForNode(
            StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
            accessorDeclaration,
            [accessorTextName, getterType, setterType, accessorTextName]);
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
      if (_currentLibrary.hasJS != true) {
        _errorReporter.reportErrorForNode(
            HintCode.MISSING_JS_LIB_ANNOTATION, node);
      }
    }
  }

  void _checkForMissingRequiredParam(
      DartType type, ArgumentList argumentList, AstNode node) {
    if (type is FunctionType) {
      for (ParameterElement parameter in type.parameters) {
        if (parameter.isRequiredNamed) {
          String parameterName = parameter.name;
          if (!RequiredConstantsComputer._containsNamedExpression(
              argumentList, parameterName)) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT,
                node,
                [parameterName]);
          }
        }
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
    var nonVoidReturnsWith =
        _returnsWith.where((stmt) => !getStaticType(stmt.expression).isVoid);
    if (nonVoidReturnsWith.isNotEmpty && _returnsWithout.isNotEmpty) {
      for (ReturnStatement returnWith in nonVoidReturnsWith) {
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
   * See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR].
   */
  bool _checkForMixinClassDeclaresConstructor(
      TypeName mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR,
            mixinName,
            [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  void _checkForMixinDeclaresConstructor(ConstructorDeclaration node) {
    if (_enclosingClass.isMixin) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, node.returnType);
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
          !mixinElement.isMixinApplication && mixinElement.mixins.isNotEmpty) {
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
    if (mixinElement.hasReferenceToSuper) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_REFERENCES_SUPER,
          mixinName,
          [mixinElement.name]);
    }
    return false;
  }

  /// Check that superclass constrains for the mixin type of [mixinName] at
  /// the [mixinIndex] position in the mixins list are satisfied by the
  /// [_enclosingClass], or a previous mixin.
  bool _checkForMixinSuperclassConstraints(int mixinIndex, TypeName mixinName) {
    InterfaceType mixinType = mixinName.type;
    for (var constraint in mixinType.superclassConstraints) {
      bool isSatisfied =
          _typeSystem.isSubtypeOf(_enclosingClass.supertype, constraint);
      if (!isSatisfied) {
        for (int i = 0; i < mixinIndex && !isSatisfied; i++) {
          isSatisfied =
              _typeSystem.isSubtypeOf(_enclosingClass.mixins[i], constraint);
        }
      }
      if (!isSatisfied) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
            mixinName.name, [
          mixinName.type.displayName,
          _enclosingClass.supertype,
          constraint.displayName
        ]);
        return true;
      }
    }
    return false;
  }

  /// Check that the superclass of the given [mixinElement] at the given
  /// [mixinIndex] in the list of mixins of [_enclosingClass] has concrete
  /// implementations of all the super-invoked members of the [mixinElement].
  bool _checkForMixinSuperInvokedMembers(int mixinIndex, TypeName mixinName,
      ClassElement mixinElement, InterfaceType mixinType) {
    ClassElementImpl mixinElementImpl =
        AbstractClassElementImpl.getImpl(mixinElement);
    if (mixinElementImpl.superInvokedNames.isEmpty) {
      return false;
    }

    InterfaceTypeImpl enclosingType = _enclosingClass.type;
    Uri mixinLibraryUri = mixinElement.librarySource.uri;
    for (var name in mixinElementImpl.superInvokedNames) {
      var nameObject = new Name(mixinLibraryUri, name);

      var superMemberType = _inheritanceManager.getMember(
          enclosingType, nameObject,
          forMixinIndex: mixinIndex, concrete: true, forSuper: true);

      if (superMemberType == null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
            mixinName.name,
            [name]);
        return true;
      }

      FunctionType mixinMemberType =
          _inheritanceManager.getMember(mixinType, nameObject, forSuper: true);

      if (mixinMemberType != null &&
          !_typeSystem.isOverrideSubtypeOf(superMemberType, mixinMemberType)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE,
            mixinName.name,
            [name, mixinMemberType.displayName, superMemberType.displayName]);
        return true;
      }
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

    /// Report an error and return `true` if the given [name] is a private name
    /// (which is defined in the given [library]) and it conflicts with another
    /// definition of that name inherited from the superclass.
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
    if (element != null && _hasConcreteSuperMethod(node)) {
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
      if (element.isEnum || element.isMixin) {
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
      if (superUnnamedConstructor.isDefaultConstructor) {
        return;
      }
    }

    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
        declaration.name,
        [superType.displayName, _enclosingClass.displayName]);
  }

  /**
   * Check to ensure that the [condition] is of type bool, are. Otherwise an
   * error is reported on the expression.
   *
   * See [StaticTypeWarningCode.NON_BOOL_CONDITION].
   */
  void _checkForNonBoolCondition(Expression condition) {
    DartType conditionType = getStaticType(condition);
    if (!_checkForNullableDereference(condition) &&
        !_checkForUseOfVoidResult(condition) &&
        conditionType != null &&
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
      _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression);
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
  void _checkForNonConstMapAsExpressionStatement3(SetOrMapLiteral literal) {
    // "const"
    if (literal.constKeyword != null) {
      return;
    }
    // has type arguments
    if (literal.typeArguments != null) {
      return;
    }
    // prepare statement
    Statement statement = literal.thisOrAncestorOfType<ExpressionStatement>();
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
   * Check for illegal derefences of nullables, ie, "unchecked" usages of
   * nullable values. Note that *any* usage of a null value is an "unchecked"
   * usage, because proper checks will promote the type to a non-nullable value.
   *
   * See [StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE]
   */
  bool _checkForNullableDereference(Expression expression) {
    if (expression == null ||
        !_isNonNullable ||
        expression.staticType == null ||
        (expression.staticType as TypeImpl).nullabilitySuffix !=
            NullabilitySuffix.question) {
      return false;
    }

    StaticWarningCode code = StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE;

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(code, methodName, []);
    } else {
      _errorReporter.reportErrorForNode(code, expression, []);
    }

    return true;
  }

  /**
   * Verify that all classes of the given [onClause] are valid.
   *
   * See [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS],
   * [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS].
   */
  bool _checkForOnClauseErrorCodes(OnClause onClause) {
    if (onClause == null) {
      return false;
    }
    bool problemReported = false;
    for (TypeName typeName in onClause.superclassConstraints) {
      DartType type = typeName.type;
      if (type is InterfaceType) {
        if (_checkForExtendsOrImplementsDisallowedClass(
            typeName,
            CompileTimeErrorCode
                .MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          if (_checkForExtendsOrImplementsDeferredClass(
              typeName,
              CompileTimeErrorCode
                  .MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS)) {
            problemReported = true;
          }
        }
      }
    }
    return problemReported;
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
      if (formalParameter.isOptional) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR,
            formalParameter);
      }
    }
  }

  /**
   * Via informal specification: dart-lang/language/issues/4
   *
   * If e is an integer literal which is not the operand of a unary minus
   * operator, then:
   *   - If the context type is double, it is a compile-time error if the
   *   numerical value of e is not precisely representable by a double.
   *   Otherwise the static type of e is double and the result of evaluating e
   *   is a double instance representing that value.
   *   - Otherwise (the current behavior of e, with a static type of int).
   *
   * and
   *
   * If e is -n and n is an integer literal, then
   *   - If the context type is double, it is a compile-time error if the
   *   numerical value of n is not precisley representable by a double.
   *   Otherwise the static type of e is double and the result of evaluating e
   *   is the result of calling the unary minus operator on a double instance
   *   representing the numerical value of n.
   *   - Otherwise (the current behavior of -n)
   */
  void _checkForOutOfRange(IntegerLiteral node) {
    String lexeme = node.literal.lexeme;
    final bool isNegated = (node as IntegerLiteralImpl).immediatelyNegated;
    final List<Object> extraErrorArgs = [];

    final bool treatedAsDouble = node.staticType == _typeProvider.doubleType;
    final bool valid = treatedAsDouble
        ? IntegerLiteralImpl.isValidAsDouble(lexeme)
        : IntegerLiteralImpl.isValidAsInteger(lexeme, isNegated);

    if (!valid) {
      extraErrorArgs.add(isNegated ? '-$lexeme' : lexeme);

      if (treatedAsDouble) {
        // Suggest the nearest valid double (as a BigInt for printing reasons).
        extraErrorArgs
            .add(BigInt.from(IntegerLiteralImpl.nearestValidDouble(lexeme)));
      }

      _errorReporter.reportErrorForNode(
          treatedAsDouble
              ? CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE
              : CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE,
          node,
          extraErrorArgs);
    }
  }

  /**
   * Verify that the [type] is not potentially nullable.
   */
  void _checkForPotentiallyNullableType(TypeAnnotation type) {
    if (_options.experimentStatus.non_nullable &&
        type?.type != null &&
        _typeSystem.isPotentiallyNullable(type.type)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, type);
    }
  }

  /**
   * Check that the given named optional [parameter] does not begin with '_'.
   *
   * See [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER].
   */
  void _checkForPrivateOptionalParameter(FormalParameter parameter) {
    // should be named parameter
    if (!parameter.isNamed) {
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

  /// Checks a type annotation for a raw generic type, and reports the
  /// appropriate error if [AnalysisOptionsImpl.strictRawTypes] is set.
  ///
  /// This checks if [node] refers to a generic type and does not have explicit
  /// or inferred type arguments. When that happens, it reports error code
  /// [StrongModeCode.STRICT_RAW_TYPE].
  void _checkForRawTypeName(TypeName node) {
    if (!_options.strictRawTypes || node == null) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    if (_isMissingTypeArguments(
        node, node.type, node.name.staticElement, null)) {
      _errorReporter
          .reportErrorForNode(HintCode.STRICT_RAW_TYPE, node, [node.type]);
    }
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
        _hiddenElements.contains(node.staticElement) &&
        node.parent is! CommentReference) {
      _errorReporter.reportError(new DiagnosticFactory()
          .referencedBeforeDeclaration(_errorReporter.source, node));
    }
  }

  void _checkForRepeatedType(List<TypeName> typeNames, ErrorCode errorCode) {
    if (typeNames == null) {
      return;
    }

    int count = typeNames.length;
    List<bool> detectedRepeatOnIndex = new List<bool>.filled(count, false);
    for (int i = 0; i < detectedRepeatOnIndex.length; i++) {
      detectedRepeatOnIndex[i] = false;
    }
    for (int i = 0; i < count; i++) {
      if (!detectedRepeatOnIndex[i]) {
        Element element = typeNames[i].name.staticElement;
        for (int j = i + 1; j < count; j++) {
          TypeName typeName = typeNames[j];
          if (typeName.name.staticElement == element) {
            detectedRepeatOnIndex[j] = true;
            _errorReporter
                .reportErrorForNode(errorCode, typeName, [typeName.name.name]);
          }
        }
      }
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
      Expression returnExpression, DartType expectedType,
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
    if (returnExpression == null) {
      return; // Empty returns are handled elsewhere
    }

    DartType expressionType = getStaticType(returnExpression);

    void reportTypeError() {
      String displayName = _enclosingFunction.displayName;

      if (displayName.isEmpty) {
        _errorReporter.reportTypeErrorForNode(
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE,
            returnExpression,
            [expressionType, expectedType]);
      } else {
        _errorReporter.reportTypeErrorForNode(
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
            returnExpression,
            [expressionType, expectedType, displayName]);
      }
    }

    var toType = expectedType;
    var fromType = expressionType;
    if (_inAsync) {
      toType = _typeSystem.flatten(toType);
      fromType = _typeSystem.flatten(fromType);
    }

    // Anything can be returned to `void` in an arrow bodied function
    // or to `Future<void>` in an async arrow bodied function.
    if (isArrowFunction && toType.isVoid) {
      return;
    }

    if (toType.isVoid) {
      if (fromType.isVoid ||
          fromType.isDynamic ||
          fromType.isDartCoreNull ||
          fromType.isBottom) {
        return;
      }
    } else if (fromType.isVoid) {
      if (toType.isDynamic || toType.isDartCoreNull || toType.isBottom) {
        return;
      }
    }
    if (!expectedType.isVoid && !fromType.isVoid) {
      var checkWithType = (!_inAsync)
          ? fromType
          : _typeProvider.futureType.instantiate(<DartType>[fromType]);
      if (_typeSystem.isAssignableTo(checkWithType, expectedType)) {
        return;
      }
    }

    reportTypeError();
  }

  /**
   * Verify that the elements in the given set [literal] are subtypes of the
   * set's static type.
   *
   * See [CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE], and
   * [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE].
   */
  void _checkForSetElementTypeNotAssignable3(SetOrMapLiteral literal) {
    // Determine the set's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType setType = literal.staticType;
    assert(setType is InterfaceTypeImpl);

    List<DartType> typeArguments = (setType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-set type was selected.
    // TODO(brianwilkerson) Unify this and _checkForMapTypeNotAssignable3 to
    //  better handle recovery situations.
    if (typeArguments.length == 1) {
      DartType setElementType = typeArguments[0];

      // Check every set element.
      var verifier = LiteralElementVerifier(
        _typeProvider,
        _typeSystem,
        _errorReporter,
        _checkForUseOfVoidResult,
        forSet: true,
        elementType: setElementType,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
    }
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
      if (element.isStatic || element is ConstructorElement) {
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
    Expression expression = statement.expression;
    if (_checkForUseOfVoidResult(expression)) {
      return;
    }

    // prepare 'switch' expression type
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
    if (!_typeSystem.isAssignableTo(expressionType, caseType)) {
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
    if (_hasTypedefSelfReference(alias.declaredElement)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, alias);
    }
  }

  /**
   * Verify that the [type] is not a deferred type.
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
   * Verify that the type arguments in the given [typeName] are all within
   * their bounds.
   *
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS],
   * [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS],
   * [CompileTimeErrorCode.GENERIC_FUNCTION_CANNOT_BE_BOUND].
   */
  void _checkForTypeArgumentNotMatchingBounds(TypeName typeName) {
    // prepare Type
    DartType type = typeName.type;
    if (type == null) {
      return;
    }
    if (type is ParameterizedType) {
      var element = type.element;
      // prepare type parameters
      List<TypeParameterElement> parameterElements;
      if (element is ClassElement) {
        parameterElements = element.typeParameters;
      } else if (element is GenericTypeAliasElement) {
        parameterElements = element.typeParameters;
      } else if (element is GenericFunctionTypeElement) {
        // TODO(paulberry): it seems like either this case or the one above
        // should be unnecessary.
        FunctionTypeAliasElement typedefElement = element.enclosingElement;
        parameterElements = typedefElement.typeParameters;
      } else if (type is FunctionType) {
        parameterElements = type.typeFormals;
      } else {
        // There are no other kinds of parameterized types.
        throw new UnimplementedError(
            'Unexpected element associated with parameterized type: '
            '${element.runtimeType}');
      }
      var parameterTypes =
          parameterElements.map<DartType>((p) => p.type).toList();
      List<DartType> arguments = type.typeArguments;
      // iterate over each bounded type parameter and corresponding argument
      NodeList<TypeAnnotation> argumentNodes =
          typeName.typeArguments?.arguments;
      var typeArguments = type.typeArguments;
      int loopThroughIndex =
          math.min(typeArguments.length, parameterElements.length);
      bool shouldSubstitute =
          arguments.length != 0 && arguments.length == parameterTypes.length;
      for (int i = 0; i < loopThroughIndex; i++) {
        DartType argType = typeArguments[i];
        TypeAnnotation argumentNode =
            argumentNodes != null && i < argumentNodes.length
                ? argumentNodes[i]
                : typeName;
        if (argType is FunctionType && argType.typeFormals.isNotEmpty) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
            argumentNode,
          );
          continue;
        }
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
            if (_shouldAllowSuperBoundedTypes(typeName)) {
              var replacedType =
                  (argType as TypeImpl).replaceTopAndBottom(_typeProvider);
              if (!identical(replacedType, argType) &&
                  _typeSystem.isSubtypeOf(replacedType, boundType)) {
                // Bound is satisfied under super-bounded rules, so we're ok.
                continue;
              }
            }
            _errorReporter.reportTypeErrorForNode(
                errorCode, argumentNode, [argType, boundType]);
          }
        }
      }
    }
  }

  void _checkForTypeParameterReferencedByStatic(SimpleIdentifier identifier) {
    if (_isInStaticMethod || _isInStaticVariableDeclaration) {
      var element = identifier.staticElement;
      if (element is TypeParameterElement &&
          element.enclosingElement is ClassElement) {
        // The class's type parameters are not in scope for static methods.
        // However all other type parameters are legal (e.g. the static method's
        // type parameters, or a local function's type parameters).
        _errorReporter.reportErrorForNode(
            StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, identifier);
      }
    }
  }

  /**
   * Check whether the given type [parameter] is a supertype of its bound.
   *
   * See [StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
   */
  void _checkForTypeParameterSupertypeOfItsBound(TypeParameter parameter) {
    TypeParameterElement element = parameter.declaredElement;
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
      } else if (!superUnnamedConstructor.isDefaultConstructor) {
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

  void _checkForUnnecessaryNullAware(Expression target, Token operator) {
    if (operator.type != TokenType.QUESTION_PERIOD || !_isNonNullable) {
      return;
    }

    if (target.staticType != null &&
        (target.staticType as TypeImpl).nullabilitySuffix ==
            NullabilitySuffix.none) {
      _errorReporter.reportErrorForToken(
          HintCode.UNNECESSARY_NULL_AWARE_CALL, operator, []);
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

  /**
   * Check for situations where the result of a method or function is used, when
   * it returns 'void'. Or, in rare cases, when other types of expressions are
   * void, such as identifiers.
   *
   * See [StaticWarningCode.USE_OF_VOID_RESULT].
   */
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null ||
        !identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
          StaticWarningCode.USE_OF_VOID_RESULT, methodName, []);
    } else {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.USE_OF_VOID_RESULT, expression, []);
    }

    return true;
  }

  void _checkForValidField(FieldFormalParameter parameter) {
    AstNode parent2 = parameter.parent?.parent;
    if (parent2 is! ConstructorDeclaration &&
        parent2?.parent is! ConstructorDeclaration) {
      return;
    }
    ParameterElement element = parameter.declaredElement;
    if (element is FieldFormalParameterElement) {
      FieldElement fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
            parameter,
            [parameter.identifier.name]);
      } else {
        ParameterElement parameterElement = parameter.declaredElement;
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
    if (parameters.length != 1 || !parameters[0].isRequiredPositional) {
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

  void _checkMixinInference(
      NamedCompilationUnitMember node, WithClause withClause) {
    if (withClause == null) {
      return;
    }
    ClassElement classElement = node.declaredElement;
    var type = classElement.type;
    var supertype = classElement.supertype;
    List<InterfaceType> supertypesForMixinInference = <InterfaceType>[];
    ClassElementImpl.collectAllSupertypes(
        supertypesForMixinInference, supertype, type);
    for (var typeName in withClause.mixinTypes) {
      var mixinType = typeName.type;
      var mixinElement = mixinType.element;
      if (mixinElement is ClassElement) {
        if (typeName.typeArguments == null) {
          var mixinSupertypeConstraints = _typeSystem
              .gatherMixinSupertypeConstraintsForInference(mixinElement);
          if (mixinSupertypeConstraints.isNotEmpty) {
            var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
                typeName,
                mixinSupertypeConstraints,
                supertypesForMixinInference);
            if (matchingInterfaceTypes != null) {
              // Try to pattern match matchingInterfaceType against
              // mixinSupertypeConstraint to find the correct set of type
              // parameters to apply to the mixin.
              var matchedType = _typeSystem.matchSupertypeConstraints(
                  mixinElement,
                  mixinSupertypeConstraints,
                  matchingInterfaceTypes);
              if (matchedType == null) {
                _errorReporter.reportErrorForToken(
                    CompileTimeErrorCode
                        .MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION,
                    typeName.name.beginToken,
                    [typeName]);
              }
            }
          }
        }
        ClassElementImpl.collectAllSupertypes(
            supertypesForMixinInference, mixinType, type);
      }
    }
  }

  /**
   * Checks the class for problems with the superclass, mixins, or implemented
   * interfaces.
   */
  void _checkMixinInheritance(MixinDeclaration node, OnClause onClause,
      ImplementsClause implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot implement double" already.
    if (!_checkForOnClauseErrorCodes(onClause) &&
        !_checkForImplementsClauseErrorCodes(implementsClause)) {
//      _checkForImplicitDynamicType(superclass);
      _checkForConflictingClassMembers();
      _checkForRepeatedType(
        onClause?.superclassConstraints,
        CompileTimeErrorCode.ON_REPEATED,
      );
      _checkForRepeatedType(
        implementsClause?.interfaces,
        CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      );
      if (!disableConflictingGenericsCheck) {
        _checkForConflictingGenerics(node);
      }
    }
  }

  /**
   * Verify that the given list of [typeArguments] contains exactly the
   * [expectedCount] of elements, reporting an error with the given [errorCode]
   * if not.
   */
  void _checkTypeArgumentCount(
      TypeArgumentList typeArguments, int expectedCount, ErrorCode errorCode) {
    int actualCount = typeArguments.arguments.length;
    if (actualCount != expectedCount) {
      _errorReporter
          .reportErrorForNode(errorCode, typeArguments, [actualCount]);
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

      // If the amount mismatches, clean up the lists to be substitutable. The
      // mismatch in size is reported elsewhere, but we must successfully
      // perform substitution to validate bounds on mismatched lists.
      final providedLength = math.min(typeArgs.length, fnTypeParams.length);
      fnTypeParams = fnTypeParams.sublist(0, providedLength);
      typeArgs = typeArgs.sublist(0, providedLength);

      for (int i = 0; i < providedLength; i++) {
        // Check the `extends` clause for the type parameter, if any.
        //
        // Also substitute to handle cases like this:
        //
        //     <TFrom, TTo extends TFrom>
        //     <TFrom, TTo extends Iterable<TFrom>>
        //     <T extends Clonable<T>>
        //
        DartType argType = typeArgs[i];

        if (argType is FunctionType && argType.typeFormals.isNotEmpty) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
            typeArgumentList[i],
          );
          continue;
        }

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

  void _checkUseOfDefaultValuesInParameters(FormalParameterList node) {
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter ||
        parent is FunctionTypeAlias ||
        parent is FunctionTypedFormalParameter ||
        parent is GenericFunctionType) {
      // These locations are not allowed to have default values.
      return;
    }
    NodeList<FormalParameter> parameters = node.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = parameters[i];
      if (parameter.isOptional) {
        DartType type = parameter.declaredElement.type;
        if (type.isDartAsyncFutureOr) {
          type = (type as ParameterizedType).typeArguments[0];
        }
        if ((parameter as DefaultFormalParameter).defaultValue == null) {
          if (_typeSystem.isPotentiallyNonNullable(type)) {
            SimpleIdentifier parameterName = _parameterName(parameter);
            if (type is TypeParameterType) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE,
                  parameterName ?? parameter,
                  [parameterName?.name ?? '?']);
            } else {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER,
                  parameterName ?? parameter,
                  [parameterName?.name ?? '?']);
            }
          }
        } else if (!_typeSystem.isNonNullable(type) &&
            _typeSystem.isPotentiallyNonNullable(type)) {
          // If the type is both potentially non-nullable and not
          // non-nullable, then it cannot be used for an optional parameter.
          SimpleIdentifier parameterName = _parameterName(parameter);
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE,
              parameterName ?? parameter,
              [parameterName?.name ?? '?']);
        }
      } else if (parameter.isRequiredNamed) {
        if ((parameter as DefaultFormalParameter).defaultValue != null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER,
              _parameterName(parameter) ?? parameter);
        }
      }
    }
  }

  InterfaceType _findInterfaceTypeForMixin(TypeName mixin,
      InterfaceType supertypeConstraint, List<InterfaceType> interfaceTypes) {
    var element = supertypeConstraint.element;
    InterfaceType foundInterfaceType;
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element != element) continue;
      if (foundInterfaceType == null) {
        foundInterfaceType = interfaceType;
      } else {
        if (interfaceType != foundInterfaceType) {
          _errorReporter.reportErrorForToken(
              CompileTimeErrorCode
                  .MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES,
              mixin.name.beginToken,
              [mixin, supertypeConstraint]);
        }
      }
    }
    if (foundInterfaceType == null) {
      _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.MIXIN_INFERENCE_NO_MATCHING_CLASS,
          mixin.name.beginToken,
          [mixin, supertypeConstraint]);
    }
    return foundInterfaceType;
  }

  List<InterfaceType> _findInterfaceTypesForConstraints(
      TypeName mixin,
      List<InterfaceType> supertypeConstraints,
      List<InterfaceType> interfaceTypes) {
    var result = <InterfaceType>[];
    for (var constraint in supertypeConstraints) {
      var interfaceType =
          _findInterfaceTypeForMixin(mixin, constraint, interfaceTypes);
      if (interfaceType == null) {
        // No matching interface type found, so inference fails.  The error has
        // already been reported.
        return null;
      }
      result.add(interfaceType);
    }
    return result;
  }

  /// Find a method which is overridden by [node] and which is annotated with
  /// `@mustCallSuper`.
  ///
  /// As per the definition of `mustCallSuper` [1], every method which overrides
  /// a method annotated with `@mustCallSuper` is implicitly annotated with
  /// `@mustCallSuper`.
  ///
  /// [1] https://pub.dartlang.org/documentation/meta/latest/meta/mustCallSuper-constant.html
  MethodElement _findOverriddenMemberThatMustCallSuper(MethodDeclaration node) {
    Element member = node.declaredElement;
    ClassElement classElement = member.enclosingElement;
    String name = member.name;

    // Walk up the type hierarchy from [classElement], ignoring direct interfaces.
    Queue<ClassElement> superclasses =
        Queue.of(classElement.mixins.map((i) => i.element))
          ..addAll(classElement.superclassConstraints.map((i) => i.element))
          ..add(classElement.supertype?.element);
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    while (superclasses.isNotEmpty) {
      ClassElement ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }
      ExecutableElement member = ancestor.getMethod(name) ??
          ancestor.getGetter(name) ??
          ancestor.getSetter(name);
      if (member is MethodElement && member.hasMustCallSuper) {
        return member;
      }
      superclasses
        ..addAll(ancestor.mixins.map((i) => i.element))
        ..addAll(ancestor.superclassConstraints.map((i) => i.element))
        ..add(ancestor.supertype?.element);
    }
    return null;
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
        return library.definingCompilationUnit.source.uri.toString();
      }
    }
    List<String> indirectSources = new List<String>();
    for (int i = 0; i < count; i++) {
      LibraryElement importedLibrary = imports[i].importedLibrary;
      if (importedLibrary != null) {
        for (LibraryElement exportedLibrary
            in importedLibrary.exportedLibraries) {
          if (identical(exportedLibrary, library)) {
            indirectSources.add(
                importedLibrary.definingCompilationUnit.source.uri.toString());
          }
        }
      }
    }
    int indirectCount = indirectSources.length;
    StringBuffer buffer = new StringBuffer();
    buffer.write(library.definingCompilationUnit.source.uri.toString());
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

  /// Returns whether [node] overrides a concrete method.
  bool _hasConcreteSuperMethod(MethodDeclaration node) {
    ClassElement classElement = node.declaredElement.enclosingElement;
    String name = node.declaredElement.name;

    Queue<ClassElement> superclasses =
        Queue.of(classElement.mixins.map((i) => i.element))
          ..addAll(classElement.superclassConstraints.map((i) => i.element))
          ..add(classElement.supertype?.element);
    return superclasses.any(
        (parent) => parent.lookUpConcreteMethod(name, parent.library) != null);
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
  bool _hasTypedefSelfReference(GenericTypeAliasElement element) {
    if (element == null) {
      return false;
    }
    if (element is GenericTypeAliasElementImpl && element.linkedNode != null) {
      return element.hasSelfReference;
    }
    var visitor = new _HasTypedefSelfReferenceVisitor(element.function);
    element.accept(visitor);
    return visitor.hasSelfReference;
  }

  void _initializeInitialFieldElementsMap(List<FieldElement> fields) {
    _initialFieldElementsMap = new HashMap<FieldElement, INIT_STATE>();
    for (FieldElement fieldElement in fields) {
      if (!fieldElement.isSynthetic) {
        _initialFieldElementsMap[fieldElement] =
            fieldElement.initializer == null
                ? INIT_STATE.NOT_INIT
                : INIT_STATE.INIT_IN_DECLARATION;
      }
    }
  }

  bool _isDartCoreList(InterfaceType type) {
    ClassElement element = type.element;
    if (element == null) {
      return false;
    }
    return element.name == "List" && element.library.isDartCore;
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

  /// Given a [node] without type arguments that refers to [element], issues
  /// an error if [type] is a generic type, and the type arguments were not
  /// supplied from inference or a non-dynamic default instantiation.
  ///
  /// This function is used by other node-specific type checking functions, and
  /// should only be called when [node] has no explicit `typeArguments`.
  ///
  /// [inferenceContextNode] is the node that has the downwards context type,
  /// if any. For example an [InstanceCreationExpression].
  ///
  /// This function will return false if any of the following are true:
  ///
  /// - [inferenceContextNode] has an inference context type that does not
  ///   contain `?`
  /// - [type] does not have any `dynamic` type arguments.
  /// - the element is marked with `@optionalTypeArgs` from "package:meta".
  bool _isMissingTypeArguments(AstNode node, DartType type, Element element,
      Expression inferenceContextNode) {
    // Check if this type has type arguments and at least one is dynamic.
    // If so, we may need to issue a strict-raw-types error.
    if (type is ParameterizedType &&
        type.typeArguments.any((t) => t.isDynamic)) {
      // If we have an inference context node, check if the type was inferred
      // from it. Some cases will not have a context type, such as the type
      // annotation `List` in `List list;`
      if (inferenceContextNode != null) {
        var contextType = InferenceContext.getContext(inferenceContextNode);
        if (contextType != null && UnknownInferredType.isKnown(contextType)) {
          // Type was inferred from downwards context: not an error.
          return false;
        }
      }
      if (element.hasOptionalTypeArgs) {
        return false;
      }
      return true;
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
      return true;
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

  /// Return the name of the [parameter], or `null` if the parameter does not
  /// have a name.
  SimpleIdentifier _parameterName(FormalParameter parameter) {
    if (parameter is NormalFormalParameter) {
      return parameter.identifier;
    } else if (parameter is DefaultFormalParameter) {
      return parameter.parameter.identifier;
    }
    return null;
  }

  /// Determines if the given [typeName] occurs in a context where super-bounded
  /// types are allowed.
  bool _shouldAllowSuperBoundedTypes(TypeName typeName) {
    var parent = typeName.parent;
    if (parent is ExtendsClause) return false;
    if (parent is OnClause) return false;
    if (parent is ClassTypeAlias) return false;
    if (parent is WithClause) return false;
    if (parent is ConstructorName) return false;
    if (parent is ImplementsClause) return false;
    return true;
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
            fields.add(field.declaredElement);
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
        if (parameter.isOptionalNamed) {
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

  ElementAnnotationImpl _getRequiredAnnotation(ParameterElement param) => param
      .metadata
      .firstWhere((ElementAnnotation e) => e.isRequired, orElse: () => null);

  static bool _containsNamedExpression(ArgumentList args, String name) {
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
}

class _HasTypedefSelfReferenceVisitor extends GeneralizingElementVisitor<void> {
  final GenericFunctionTypeElement element;
  bool hasSelfReference = false;

  _HasTypedefSelfReferenceVisitor(this.element);

  @override
  void visitClassElement(ClassElement element) {
    // Typedefs are allowed to reference themselves via classes.
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    _addTypeToCheck(element.returnType);
    super.visitFunctionElement(element);
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _addTypeToCheck(element.returnType);
    super.visitFunctionTypeAliasElement(element);
  }

  @override
  void visitGenericFunctionTypeElement(GenericFunctionTypeElement element) {
    _addTypeToCheck(element.returnType);
    super.visitGenericFunctionTypeElement(element);
  }

  @override
  void visitParameterElement(ParameterElement element) {
    _addTypeToCheck(element.type);
    super.visitParameterElement(element);
  }

  @override
  void visitTypeParameterElement(TypeParameterElement element) {
    _addTypeToCheck(element.bound);
    super.visitTypeParameterElement(element);
  }

  void _addTypeToCheck(DartType type) {
    if (hasSelfReference) {
      return;
    }
    if (type == null) {
      return;
    }
    if (type.element == element) {
      hasSelfReference = true;
      return;
    }
    if (type is FunctionType) {
      _addTypeToCheck(type.returnType);
      for (ParameterElement parameter in type.parameters) {
        _addTypeToCheck(parameter.type);
      }
    }
    // type arguments
    if (type is InterfaceType) {
      for (DartType typeArgument in type.typeArguments) {
        _addTypeToCheck(typeArgument);
      }
    }
  }
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

    var element = node.name.staticElement;
    if (element is TypeParameterizedElement && !element.isSimplyBounded) {
      _errorReporter
          .reportErrorForNode(StrongModeCode.NOT_INSTANTIATED_BOUND, node, []);
    }
  }
}

// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Instances of the class `ConstantVerifier` traverse an AST structure looking
/// for additional errors and warnings not covered by the parser and resolver.
/// In particular, it looks for errors and warnings related to constant
/// expressions.
class ConstantVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type provider used to access the known types.
  final TypeProvider _typeProvider;

  /// The type system in use.
  final TypeSystem _typeSystem;

  /// The set of variables declared using '-D' on the command line.
  final DeclaredVariables declaredVariables;

  /// The type representing the type 'bool'.
  InterfaceType _boolType;

  /// The type representing the type 'int'.
  InterfaceType _intType;

  /// The type representing the type 'num'.
  InterfaceType _numType;

  /// The type representing the type 'string'.
  InterfaceType _stringType;

  /// The current library that is being analyzed.
  final LibraryElement _currentLibrary;

  ConstantEvaluationEngine _evaluationEngine;

  /// Initialize a newly created constant verifier.
  ///
  /// @param errorReporter the error reporter by which errors will be reported
  ConstantVerifier(this._errorReporter, LibraryElement currentLibrary,
      this._typeProvider, this.declaredVariables,
      {bool forAnalysisDriver: false})
      : _currentLibrary = currentLibrary,
        _typeSystem = currentLibrary.context.typeSystem {
    this._boolType = _typeProvider.boolType;
    this._intType = _typeProvider.intType;
    this._numType = _typeProvider.numType;
    this._stringType = _typeProvider.stringType;
    this._evaluationEngine = new ConstantEvaluationEngine(
        _typeProvider, declaredVariables,
        forAnalysisDriver: forAnalysisDriver,
        typeSystem: _typeSystem,
        experimentStatus:
            (currentLibrary.context.analysisOptions as AnalysisOptionsImpl)
                .experimentStatus);
  }

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    Element element = node.element;
    if (element is ConstructorElement) {
      // should be 'const' constructor
      if (!element.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, node);
        return;
      }
      // should have arguments
      ArgumentList argumentList = node.arguments;
      if (argumentList == null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, node);
        return;
      }
      // arguments should be constants
      _validateConstantArguments(argumentList);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.constKeyword != null) {
      _validateConstructorInitializers(node);
      _validateFieldInitializers(node.parent as ClassDeclaration, node);
    }
    _validateDefaultValues(node.parameters);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      TypeName typeName = node.constructorName.type;
      _checkForConstWithTypeParameters(typeName);

      // We need to evaluate the constant to see if any errors occur during its
      // evaluation.
      ConstructorElement constructor = node.staticElement;
      if (constructor != null) {
        ConstantVisitor constantVisitor =
            new ConstantVisitor(_evaluationEngine, _errorReporter);
        _evaluationEngine.evaluateConstructorCall(
            node,
            node.argumentList.arguments,
            constructor,
            constantVisitor,
            _errorReporter);
      }
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.isConst) {
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
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    bool isConst = node.isConst;
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
          if (!keys.add(keyResult)) {
            invalidKeys.add(key);
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
        DartObjectImpl result = key
            .accept(new ConstantVisitor(_evaluationEngine, subErrorReporter));
        if (result != null) {
          if (!keys.add(result)) {
            invalidKeys.add(key);
          }
        } else {
          reportEqualKeys = false;
        }
      }
    }
    if (reportEqualKeys) {
      for (int i = 0; i < invalidKeys.length; i++) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.EQUAL_KEYS_IN_MAP, invalidKeys[i]);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    super.visitSetLiteral(node);
    HashSet<DartObject> elements = new HashSet<DartObject>();
    List<Expression> invalidElements = new List<Expression>();
    if (node.isConst) {
      for (Expression element in node.elements) {
        DartObjectImpl result =
            _validate(element, CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT);
        if (result != null) {
          _reportErrorIfFromDeferredLibrary(
              element,
              CompileTimeErrorCode
                  .NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY);
          if (!elements.add(result)) {
            invalidElements.add(element);
          }
          DartType type = result.type;
          if (_implementsEqualsWhenNotAllowed(type)) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
                element,
                [type.displayName]);
          }
        }
      }
      for (var invalidElement in invalidElements) {
        _errorReporter.reportErrorForNode(
            StaticWarningCode.EQUAL_VALUES_IN_CONST_SET, invalidElement);
      }
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
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
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    if (initializer != null && (node.isConst || node.isFinal)) {
      VariableElementImpl element = node.declaredElement as VariableElementImpl;
      EvaluationResultImpl result = element.evaluationResult;
      if (result == null) {
        // Variables marked "const" should have had their values computed by
        // ConstantValueComputer.  Other variables will only have had their
        // values computed if the value was needed (e.g. final variables in a
        // class containing const constructors).
        assert(!node.isConst);
        return;
      }
      _reportErrors(result.errors,
          CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      _reportErrorIfFromDeferredLibrary(
          initializer,
          CompileTimeErrorCode
              .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY);
    }
  }

  /// This verifies that the passed switch statement does not have a case
  /// expression with the operator '==' overridden.
  ///
  /// @param node the switch statement to evaluate
  /// @param type the common type of all 'case' expressions
  /// @return `true` if and only if an error code is generated on the passed
  ///         node.
  /// See [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS].
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

  /// Verify that the given [type] does not reference any type parameters.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS].
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

  /// @return `true` if given [Type] implements operator <i>==</i>, and it is
  ///         not <i>int</i> or <i>String</i>.
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

  /// Given some computed [Expression], this method generates the passed
  /// [ErrorCode] on the node if its' value consists of information from a
  /// deferred library.
  ///
  /// @param expression the expression to be tested for a deferred library
  ///        reference
  /// @param errorCode the error code to be used if the expression is or
  ///        consists of a reference to a deferred library
  void _reportErrorIfFromDeferredLibrary(
      Expression expression, ErrorCode errorCode) {
    DeferredLibraryReferenceDetector referenceDetector =
        new DeferredLibraryReferenceDetector();
    expression.accept(referenceDetector);
    if (referenceDetector.result) {
      _errorReporter.reportErrorForNode(errorCode, expression);
    }
  }

  /// Report any errors in the given list. Except for special cases, use the
  /// given error code rather than the one reported in the error.
  ///
  /// @param errors the errors that need to be reported
  /// @param errorCode the error code to be used
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
          identical(
              dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT) ||
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

  /// Validate that the given expression is a compile time constant. Return the
  /// value of the compile time constant, or `null` if the expression is not a
  /// compile time constant.
  ///
  /// @param expression the expression to be validated
  /// @param errorCode the error code to be used if the expression is not a
  ///        compile time constant
  /// @return the value of the compile time constant
  DartObjectImpl _validate(Expression expression, ErrorCode errorCode) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter subErrorReporter =
        new ErrorReporter(errorListener, _errorReporter.source);
    DartObjectImpl result = expression
        .accept(new ConstantVisitor(_evaluationEngine, subErrorReporter));
    _reportErrors(errorListener.errors, errorCode);
    return result;
  }

  /// Validate that if the passed arguments are constant expressions.
  ///
  /// @param argumentList the argument list to evaluate
  void _validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      Expression realArgument =
          argument is NamedExpression ? argument.expression : argument;
      _validate(
          realArgument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
    }
  }

  /// Validates that the expressions of the initializers of the given constant
  /// [constructor] are all compile time constants.
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

  /// Validate that the default value associated with each of the parameters in
  /// the given list is a compile time constant.
  ///
  /// @param parameters the list of parameters to be validated
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
        VariableElementImpl element =
            parameter.declaredElement as VariableElementImpl;
        element.evaluationResult = new EvaluationResultImpl(result);
      }
    }
  }

  /// Validates that the expressions of any field initializers in the class
  /// declaration are all compile time constants. Since this is only required if
  /// the class has a constant constructor, the error is reported at the
  /// constructor site.
  ///
  /// @param classDeclaration the class which should be validated
  /// @param errorSite the site at which errors should be reported.
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
            DartObjectImpl result = initializer.accept(
                new ConstantVisitor(_evaluationEngine, subErrorReporter));
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

  /// Validates that the given expression is a compile time constant.
  ///
  /// @param parameterElements the elements of parameters of constant
  ///        constructor, they are considered as a valid potentially constant
  ///        expressions
  /// @param expression the expression to validate
  void _validateInitializerExpression(
      List<ParameterElement> parameterElements, Expression expression) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter subErrorReporter =
        new ErrorReporter(errorListener, _errorReporter.source);
    DartObjectImpl result = expression.accept(
        new _ConstantVerifier_validateInitializerExpression(_typeSystem,
            _evaluationEngine, subErrorReporter, this, parameterElements));
    _reportErrors(errorListener.errors,
        CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER);
    if (result != null) {
      _reportErrorIfFromDeferredLibrary(
          expression,
          CompileTimeErrorCode
              .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY);
    }
  }

  /// Validates that all of the arguments of a constructor initializer are
  /// compile time constants.
  ///
  /// @param parameterElements the elements of parameters of constant
  ///        constructor, they are considered as a valid potentially constant
  ///        expressions
  /// @param argumentList the argument list to validate
  void _validateInitializerInvocationArguments(
      List<ParameterElement> parameterElements, ArgumentList argumentList) {
    if (argumentList == null) {
      return;
    }
    for (Expression argument in argumentList.arguments) {
      _validateInitializerExpression(parameterElements, argument);
    }
  }
}

class _ConstantVerifier_validateInitializerExpression extends ConstantVisitor {
  final TypeSystem typeSystem;
  final ConstantVerifier verifier;

  List<ParameterElement> parameterElements;

  _ConstantVerifier_validateInitializerExpression(
      this.typeSystem,
      ConstantEvaluationEngine evaluationEngine,
      ErrorReporter errorReporter,
      this.verifier,
      this.parameterElements)
      : super(evaluationEngine, errorReporter);

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
          } else if (typeSystem.isSubtypeOf(type, verifier._boolType)) {
            return new DartObjectImpl(
                verifier._typeProvider.boolType, BoolState.UNKNOWN_VALUE);
          } else if (typeSystem.isSubtypeOf(
              type, verifier._typeProvider.doubleType)) {
            return new DartObjectImpl(
                verifier._typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
          } else if (typeSystem.isSubtypeOf(type, verifier._intType)) {
            return new DartObjectImpl(
                verifier._typeProvider.intType, IntState.UNKNOWN_VALUE);
          } else if (typeSystem.isSubtypeOf(type, verifier._numType)) {
            return new DartObjectImpl(
                verifier._typeProvider.numType, NumState.UNKNOWN_VALUE);
          } else if (typeSystem.isSubtypeOf(type, verifier._stringType)) {
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

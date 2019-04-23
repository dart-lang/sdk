// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
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

  /// The set of variables declared using '-D' on the command line.
  final DeclaredVariables declaredVariables;

  /// The type representing the type 'int'.
  final InterfaceType _intType;

  /// The current library that is being analyzed.
  final LibraryElement _currentLibrary;

  final bool _constantUpdate2018Enabled;

  final ConstantEvaluationEngine _evaluationEngine;

  /// Initialize a newly created constant verifier.
  ///
  /// @param errorReporter the error reporter by which errors will be reported
  ///
  /// TODO(paulberry): make [featureSet] a required parameter.
  ConstantVerifier(ErrorReporter errorReporter, LibraryElement currentLibrary,
      TypeProvider typeProvider, DeclaredVariables declaredVariables,
      {bool forAnalysisDriver: false, FeatureSet featureSet})
      : this._(
            errorReporter,
            currentLibrary,
            typeProvider,
            declaredVariables,
            forAnalysisDriver,
            currentLibrary.context.typeSystem,
            featureSet ??
                (currentLibrary.context.analysisOptions as AnalysisOptionsImpl)
                    .contextFeatures);

  ConstantVerifier._(
      this._errorReporter,
      this._currentLibrary,
      this._typeProvider,
      this.declaredVariables,
      bool forAnalysisDriver,
      TypeSystem typeSystem,
      FeatureSet featureSet)
      : _constantUpdate2018Enabled =
            featureSet.isEnabled(Feature.constant_update_2018),
        _intType = _typeProvider.intType,
        _evaluationEngine = new ConstantEvaluationEngine(
            _typeProvider, declaredVariables,
            forAnalysisDriver: forAnalysisDriver,
            typeSystem: typeSystem,
            experimentStatus: featureSet);

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
      _validateFieldInitializers(node.parent, node);
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
      InterfaceType nodeType = node.staticType;
      DartType elementType = nodeType.typeArguments[0];
      var verifier = _ConstLiteralVerifier(
        this,
        errorCode: CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
        forList: true,
        listElementType: elementType,
      );
      for (CollectionElement element in node.elements) {
        verifier.verify(element);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);
    if (node.isSet) {
      if (node.isConst) {
        InterfaceType nodeType = node.staticType;
        var elementType = nodeType.typeArguments[0];
        var duplicateElements = <Expression>[];
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT,
          forSet: true,
          setElementType: elementType,
          setUniqueValues: Set<DartObject>(),
          setDuplicateExpressions: duplicateElements,
        );
        for (CollectionElement element in node.elements) {
          verifier.verify(element);
        }
        for (var duplicateElement in duplicateElements) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET,
            duplicateElement,
          );
        }
      }
    } else if (node.isMap) {
      if (node.isConst) {
        InterfaceType nodeType = node.staticType;
        var keyType = nodeType.typeArguments[0];
        var valueType = nodeType.typeArguments[1];
        bool reportEqualKeys = true;
        var duplicateKeyElements = <Expression>[];
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT,
          forMap: true,
          mapKeyType: keyType,
          mapValueType: valueType,
          mapUniqueKeys: Set<DartObject>(),
          mapDuplicateKeyExpressions: duplicateKeyElements,
        );
        for (CollectionElement entry in node.elements) {
          verifier.verify(entry);
        }
        if (reportEqualKeys) {
          for (var duplicateKeyElement in duplicateKeyElements) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP,
              duplicateKeyElement,
            );
          }
        }
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

  void _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(node);
    if (notPotentiallyConstants.isEmpty) return;

    for (var notConst in notPotentiallyConstants) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_CONSTANT,
        notConst,
      );
    }
  }

  /// Validates that all arguments in the [argumentList] are potentially
  /// constant expressions.
  void _reportNotPotentialConstantsArguments(ArgumentList argumentList) {
    if (argumentList == null) {
      return;
    }
    for (Expression argument in argumentList.arguments) {
      _reportNotPotentialConstants(argument);
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
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is AssertInitializer) {
        _reportNotPotentialConstants(initializer.condition);
        Expression message = initializer.message;
        if (message != null) {
          _reportNotPotentialConstants(message);
        }
      } else if (initializer is ConstructorFieldInitializer) {
        _reportNotPotentialConstants(initializer.expression);
      } else if (initializer is RedirectingConstructorInvocation) {
        _reportNotPotentialConstantsArguments(initializer.argumentList);
      } else if (initializer is SuperConstructorInvocation) {
        _reportNotPotentialConstantsArguments(initializer.argumentList);
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
  void _validateFieldInitializers(ClassOrMixinDeclaration classDeclaration,
      ConstructorDeclaration errorSite) {
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
}

class _ConstLiteralVerifier {
  final ConstantVerifier verifier;
  final Set<DartObject> mapUniqueKeys;
  final List<Expression> mapDuplicateKeyExpressions;
  final ErrorCode errorCode;
  final DartType listElementType;
  final DartType mapKeyType;
  final DartType mapValueType;
  final DartType setElementType;
  final Set<DartObject> setUniqueValues;
  final List<CollectionElement> setDuplicateExpressions;
  final bool forList;
  final bool forMap;
  final bool forSet;

  _ConstLiteralVerifier(
    this.verifier, {
    this.mapUniqueKeys,
    this.mapDuplicateKeyExpressions,
    this.errorCode,
    this.listElementType,
    this.mapKeyType,
    this.mapValueType,
    this.setElementType,
    this.setUniqueValues,
    this.setDuplicateExpressions,
    this.forList = false,
    this.forMap = false,
    this.forSet = false,
  });

  ErrorCode get _fromDeferredErrorCode {
    if (forList) {
      return CompileTimeErrorCode
          .NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY;
    } else if (forSet) {
      return CompileTimeErrorCode
          .NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY;
    }

    return null;
  }

  bool verify(CollectionElement element) {
    if (element is Expression) {
      var value = verifier._validate(element, errorCode);
      if (value == null) return false;

      if (_fromDeferredErrorCode != null) {
        verifier._reportErrorIfFromDeferredLibrary(
            element, _fromDeferredErrorCode);
      }

      if (forList) {
        return _validateListExpression(element, value);
      }

      if (forSet) {
        return _validateSetExpression(element, value);
      }

      return true;
    } else if (element is ForElement) {
      verifier._errorReporter.reportErrorForNode(errorCode, element);
      return false;
    } else if (element is IfElement) {
      if (!verifier._constantUpdate2018Enabled) {
        verifier._errorReporter.reportErrorForNode(errorCode, element);
        return false;
      }
      var conditionValue = verifier._validate(element.condition, errorCode);
      var conditionBool = conditionValue?.toBoolValue();

      // The errors have already been reported.
      if (conditionBool == null) return false;

      verifier._reportErrorIfFromDeferredLibrary(
          element.condition,
          CompileTimeErrorCode
              .NON_CONSTANT_IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY);

      var thenValid = true;
      var elseValid = true;
      if (conditionBool) {
        thenValid = verify(element.thenElement);
        if (element.elseElement != null) {
          elseValid = _reportNotPotentialConstants(element.elseElement);
        }
      } else {
        thenValid = _reportNotPotentialConstants(element.thenElement);
        if (element.elseElement != null) {
          elseValid = verify(element.elseElement);
        }
      }

      return thenValid && elseValid;
    } else if (element is MapLiteralEntry) {
      return _validateMapLiteralEntry(element);
    } else if (element is SpreadElement) {
      if (!verifier._constantUpdate2018Enabled) {
        verifier._errorReporter.reportErrorForNode(errorCode, element);
        return false;
      }
      var value = verifier._validate(element.expression, errorCode);
      if (value == null) return false;

      verifier._reportErrorIfFromDeferredLibrary(
          element.expression,
          CompileTimeErrorCode
              .NON_CONSTANT_SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY);

      if (forList || forSet) {
        return _validateListOrSetSpread(element, value);
      }

      if (forMap) {
        return _validateMapSpread(element, value);
      }

      return true;
    }
    throw new UnsupportedError(
      'Unhandled type of collection element: ${element.runtimeType}',
    );
  }

  /// Return `true` if the [node] is a potential constant.
  bool _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(node);
    if (notPotentiallyConstants.isEmpty) return true;

    for (var notConst in notPotentiallyConstants) {
      CompileTimeErrorCode errorCode;
      if (forList) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT;
      } else if (forMap) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT;
        for (var parent = notConst; parent != null; parent = parent.parent) {
          if (parent is MapLiteralEntry) {
            if (parent.key == notConst) {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_KEY;
            } else {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE;
            }
            break;
          }
        }
      } else if (forSet) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT;
      }
      verifier._errorReporter.reportErrorForNode(errorCode, notConst);
    }

    return false;
  }

  bool _validateListExpression(Expression expression, DartObjectImpl value) {
    if (!verifier._evaluationEngine.runtimeTypeMatch(value, listElementType)) {
      verifier._errorReporter.reportErrorForNode(
        StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, listElementType],
      );
      return false;
    }

    verifier._reportErrorIfFromDeferredLibrary(
      expression,
      CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY,
    );

    return true;
  }

  bool _validateListOrSetSpread(SpreadElement element, DartObjectImpl value) {
    var listValue = value.toListValue();
    var setValue = value.toSetValue();

    if (listValue == null && setValue == null) {
      if (value.isNull && _isNullableSpread(element)) {
        return true;
      }
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
        element.expression,
      );
      return false;
    }

    if (listValue != null) {
      var elementType = value.type.typeArguments[0];
      if (verifier._implementsEqualsWhenNotAllowed(elementType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
          element,
          [elementType],
        );
        return false;
      }
    }

    if (forSet) {
      var iterableValue = listValue ?? setValue;
      for (var item in iterableValue) {
        if (!setUniqueValues.add(item)) {
          setDuplicateExpressions.add(element.expression);
        }
      }
    }

    return true;
  }

  bool _validateMapLiteralEntry(MapLiteralEntry entry) {
    if (!forMap) return false;

    var keyExpression = entry.key;
    var valueExpression = entry.value;

    var keyValue = verifier._validate(
      keyExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_KEY,
    );
    var valueValue = verifier._validate(
      valueExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    );

    if (keyValue != null) {
      var keyType = keyValue.type;

      if (!verifier._evaluationEngine.runtimeTypeMatch(keyValue, mapKeyType)) {
        verifier._errorReporter.reportErrorForNode(
          StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
          keyExpression,
          [keyType, mapKeyType],
        );
      }

      if (verifier._implementsEqualsWhenNotAllowed(keyType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
          keyExpression,
          [keyType],
        );
      }

      verifier._reportErrorIfFromDeferredLibrary(
        keyExpression,
        CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY,
      );

      if (!mapUniqueKeys.add(keyValue)) {
        mapDuplicateKeyExpressions.add(keyExpression);
      }
    }

    if (valueValue != null) {
      if (!verifier._evaluationEngine
          .runtimeTypeMatch(valueValue, mapValueType)) {
        verifier._errorReporter.reportErrorForNode(
          StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
          valueExpression,
          [valueValue.type, mapValueType],
        );
      }

      verifier._reportErrorIfFromDeferredLibrary(
        valueExpression,
        CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
      );
    }

    return true;
  }

  bool _validateMapSpread(SpreadElement element, DartObjectImpl value) {
    if (value.isNull && _isNullableSpread(element)) {
      return true;
    }
    Map<DartObject, DartObject> map = value.toMapValue();
    if (map != null) {
      // TODO(brianwilkerson) Figure out how to improve the error messages. They
      //  currently point to the whole spread expression, but the key and/or
      //  value being referenced might not be located there (if it's referenced
      //  through a const variable).
      for (var entry in map.entries) {
        DartObjectImpl keyValue = entry.key;
        if (keyValue != null) {
          if (!mapUniqueKeys.add(keyValue)) {
            mapDuplicateKeyExpressions.add(element.expression);
          }
        }
      }
      return true;
    }
    verifier._errorReporter.reportErrorForNode(
      CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP,
      element.expression,
    );
    return false;
  }

  bool _validateSetExpression(Expression expression, DartObjectImpl value) {
    if (!verifier._evaluationEngine.runtimeTypeMatch(value, setElementType)) {
      verifier._errorReporter.reportErrorForNode(
        StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, setElementType],
      );
      return false;
    }

    if (verifier._implementsEqualsWhenNotAllowed(value.type)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
        expression,
        [value.type],
      );
      return false;
    }

    verifier._reportErrorIfFromDeferredLibrary(
      expression,
      CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY,
    );

    if (!setUniqueValues.add(value)) {
      setDuplicateExpressions.add(expression);
    }

    return true;
  }

  static bool _isNullableSpread(SpreadElement element) {
    return element.spreadOperator.type ==
        TokenType.PERIOD_PERIOD_PERIOD_QUESTION;
  }
}

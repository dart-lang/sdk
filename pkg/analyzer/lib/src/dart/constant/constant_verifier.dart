// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/exhaustiveness/dart_template_buffer.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/has_type_parameter_reference.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_greatest_closure.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';

/// Instances of the class `ConstantVerifier` traverse an AST structure looking
/// for additional errors and warnings not covered by the parser and resolver.
/// In particular, it looks for errors and warnings related to constant
/// expressions.
class ConstantVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type operations.
  final TypeSystemImpl _typeSystem;

  /// The type provider used to access the known types.
  final TypeProvider _typeProvider;

  /// The set of variables declared using '-D' on the command line.
  final DeclaredVariables declaredVariables;

  /// The current library that is being analyzed.
  final LibraryElementImpl _currentLibrary;

  final ConstantEvaluationEngine _evaluationEngine;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  /// Cache used for checking exhaustiveness.
  final AnalyzerExhaustivenessCache _exhaustivenessCache;

  /// Cache of constant values used for exhaustiveness checking.
  ///
  /// When verifying a switch statement/expression the constant values of the
  /// contained [ConstantPattern]s are cached here. The cache is released once
  /// the exhaustiveness of the switch has been checked.
  Map<ConstantPattern, DartObjectImpl>? _constantPatternValues;

  Map<Expression, DartObjectImpl>? _mapPatternKeyValues;

  late final ExhaustivenessDataForTesting? exhaustivenessDataForTesting;

  /// Initialize a newly created constant verifier.
  ConstantVerifier(ErrorReporter errorReporter,
      LibraryElementImpl currentLibrary, DeclaredVariables declaredVariables,
      {bool retainDataForTesting = false})
      : this._(
          errorReporter,
          currentLibrary,
          currentLibrary.typeSystem,
          currentLibrary.typeProvider,
          declaredVariables,
          retainDataForTesting,
        );

  ConstantVerifier._(
    this._errorReporter,
    this._currentLibrary,
    this._typeSystem,
    this._typeProvider,
    this.declaredVariables,
    bool retainDataForTesting,
  )   : _evaluationEngine = ConstantEvaluationEngine(
          declaredVariables: declaredVariables,
          isNonNullableByDefault:
              _currentLibrary.featureSet.isEnabled(Feature.non_nullable),
          configuration: ConstantEvaluationConfiguration(),
        ),
        _exhaustivenessCache =
            AnalyzerExhaustivenessCache(_typeSystem, _currentLibrary) {
    exhaustivenessDataForTesting = retainDataForTesting
        ? ExhaustivenessDataForTesting(_exhaustivenessCache)
        : null;
  }

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    var element = node.element;
    if (element is ConstructorElement) {
      // should be 'const' constructor
      if (!element.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, node);
        return;
      }
      // should have arguments
      var argumentList = node.arguments;
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
  void visitConstantPattern(ConstantPattern node) {
    var expression = node.expression.unParenthesized;
    if (expression.typeOrThrow is InvalidType) {
      return;
    }

    var value = _evaluateAndReportError(
      expression,
      CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
    );
    if (value is DartObjectImpl) {
      if (_currentLibrary.featureSet.isEnabled(Feature.patterns)) {
        _constantPatternValues?[node] = value;
        if (value.hasPrimitiveEquality(_currentLibrary.featureSet)) {
          var constantType = value.type;
          var matchedValueType = node.matchedValueType;
          if (matchedValueType != null) {
            if (!_canBeEqual(constantType, matchedValueType)) {
              _errorReporter.reportErrorForNode(
                WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE,
                node,
                [matchedValueType, constantType],
              );
              return;
            }
          }
        }
      }
      super.visitConstantPattern(node);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constKeyword = node.constKeyword;
    if (constKeyword != null) {
      // Check and report cycles.
      // Factory cycles are reported in elsewhere in
      // [ErrorVerifier._checkForRecursiveFactoryRedirect].
      final element = node.declaredElement;
      if (element is ConstructorElementImpl &&
          !element.isCycleFree &&
          !element.isFactory) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR,
            node.returnType, []);
      }

      _validateConstructorInitializers(node);
      if (node.factoryKeyword == null) {
        _validateFieldInitializers(
          node.parent.classMembers,
          constKeyword,
          isEnumDeclaration: node.parent is EnumDeclaration,
        );
      }
    }
    _validateDefaultValues(node.parameters);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    super.visitConstructorReference(node);
    if (node.inConstantContext || node.inConstantExpression) {
      _checkForConstWithTypeParameters(node.constructorName.type,
          CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF);
    }
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    super.visitEnumConstantDeclaration(node);

    var argumentList = node.arguments?.argumentList;
    if (argumentList != null) {
      _validateConstantArguments(argumentList);
    }

    var element = node.declaredElement as ConstFieldElementImpl;
    var result = element.evaluationResult;
    if (result is InvalidConstant) {
      _reportError(result, null);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    super.visitFunctionReference(node);
    if (node.inConstantContext || node.inConstantExpression) {
      var typeArguments = node.typeArguments;
      if (typeArguments == null) {
        return;
      }
      for (var typeArgument in typeArguments.arguments) {
        _checkForConstWithTypeParameters(typeArgument,
            CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF);
      }
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // TODO(srawlins): Also check interface types (TypeName?).
    super.visitGenericFunctionType(node);
    var parent = node.parent;
    if ((parent is AsExpression || parent is IsExpression) &&
        (parent as Expression).inConstantContext) {
      _checkForConstWithTypeParameters(
          node, CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      NamedType namedType = node.constructorName.type;
      _checkForConstWithTypeParameters(
          namedType, CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS);

      // We need to evaluate the constant to see if any errors occur during its
      // evaluation.
      var constructor = node.constructorName.staticElement;
      if (constructor != null) {
        var constantVisitor =
            ConstantVisitor(_evaluationEngine, _currentLibrary, _errorReporter);
        var result = _evaluationEngine.evaluateAndFormatErrorsInConstructorCall(
            _currentLibrary,
            node,
            constructor.returnType.typeArguments,
            node.argumentList.arguments,
            constructor,
            constantVisitor);
        switch (result) {
          case InvalidConstant():
            if (!result.avoidReporting) {
              _errorReporter.reportErrorForOffset(
                result.errorCode,
                result.offset,
                result.length,
                result.arguments,
                result.contextMessages,
              );
            }
          case DartObjectImpl():
            // Check for further errors in individual arguments.
            node.argumentList.accept(this);
        }
      }
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.isConst) {
      var nodeType = node.staticType as InterfaceType;
      DartType elementType = nodeType.typeArguments[0];
      var verifier = _ConstLiteralVerifier(
        this,
        errorCode: CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
        listElementType: elementType,
      );
      for (CollectionElement element in node.elements) {
        verifier.verify(element);
      }
    }
  }

  @override
  void visitMapPattern(MapPattern node) {
    node.typeArguments?.accept(this);

    final featureSet = _currentLibrary.featureSet;
    var uniqueKeys = HashMap<DartObjectImpl, Expression>(
      hashCode: (_) => 0,
      equals: (a, b) {
        if (a.isIdentical2(_typeSystem, b).toBoolValue() == true) {
          return true;
        }
        if (a.hasPrimitiveEquality(featureSet) &&
            b.hasPrimitiveEquality(featureSet)) {
          return a == b;
        }
        return false;
      },
    );
    var duplicateKeys = <Expression, Expression>{};
    for (var element in node.elements) {
      element.accept(this);
      if (element is MapPatternEntry) {
        var key = element.key;
        var keyValue = _evaluateAndReportError(
          key,
          CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY,
        );
        if (keyValue is DartObjectImpl) {
          _mapPatternKeyValues?[key] = keyValue;
          var existingKey = uniqueKeys[keyValue];
          if (existingKey != null) {
            duplicateKeys[key] = existingKey;
          } else {
            uniqueKeys[keyValue] = key;
          }
        }
      }
    }

    for (var duplicateEntry in duplicateKeys.entries) {
      _errorReporter.reportError(
        _diagnosticFactory.equalKeysInMapPattern(
          _errorReporter.source,
          duplicateEntry.key,
          duplicateEntry.value,
        ),
      );
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    super.visitRelationalPattern(node);

    _evaluateAndReportError(
      node.operand,
      CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION,
    );
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);
    if (node.isSet) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceType;
        var elementType = nodeType.typeArguments[0];
        var config = _SetVerifierConfig(elementType: elementType);
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT,
          setConfig: config,
        );
        for (CollectionElement element in node.elements) {
          verifier.verify(element);
        }
        for (var duplicateEntry in config.duplicateElements.entries) {
          _errorReporter.reportError(_diagnosticFactory.equalElementsInConstSet(
              _errorReporter.source, duplicateEntry.key, duplicateEntry.value));
        }
      }
    } else if (node.isMap) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceType;
        var keyType = nodeType.typeArguments[0];
        var valueType = nodeType.typeArguments[1];
        bool reportEqualKeys = true;
        var config = _MapVerifierConfig(
          keyType: keyType,
          valueType: valueType,
        );
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT,
          mapConfig: config,
        );
        for (CollectionElement entry in node.elements) {
          verifier.verify(entry);
        }
        if (reportEqualKeys) {
          for (var duplicateEntry in config.duplicateKeys.entries) {
            _errorReporter.reportError(_diagnosticFactory.equalKeysInConstMap(
                _errorReporter.source,
                duplicateEntry.key,
                duplicateEntry.value));
          }
        }
      }
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _withConstantPatternValues((mapPatternKeyValues, constantPatternValues) {
      super.visitSwitchExpression(node);
      _validateSwitchExhaustiveness(
        node: node,
        switchKeyword: node.switchKeyword,
        scrutinee: node.expression,
        caseNodes: node.cases,
        mapPatternKeyValues: mapPatternKeyValues,
        constantPatternValues: constantPatternValues,
        mustBeExhaustive: true,
        isSwitchExpression: true,
      );
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _withConstantPatternValues((mapPatternKeyValues, constantPatternValues) {
      super.visitSwitchStatement(node);
      if (_currentLibrary.featureSet.isEnabled(Feature.patterns)) {
        _validateSwitchExhaustiveness(
          node: node,
          switchKeyword: node.switchKeyword,
          scrutinee: node.expression,
          caseNodes: node.members,
          mapPatternKeyValues: mapPatternKeyValues,
          constantPatternValues: constantPatternValues,
          mustBeExhaustive:
              _typeSystem.isAlwaysExhaustive(node.expression.typeOrThrow),
          isSwitchExpression: false,
        );
      } else if (_currentLibrary.isNonNullableByDefault) {
        _validateSwitchStatement_nullSafety(node);
      } else {
        _validateSwitchStatement_legacy(node);
      }
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    var initializer = node.initializer;
    if (initializer != null && (node.isConst || node.isFinal)) {
      var element = node.declaredElement as VariableElementImpl;
      if (element is FieldElement && !element.isStatic) {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ClassElementImpl &&
            !enclosingElement.hasGenerativeConstConstructor) {
          // TODO(kallentu): Evaluate if we need to do this check for inline
          // classes.
          //
          // We report errors in the class fields only if there's a generative
          // const constructor in the class.
          return;
        }
      }

      var result = element.evaluationResult;
      if (result == null) {
        // Variables marked "const" should have had their values computed by
        // ConstantValueComputer.  Other variables will only have had their
        // values computed if the value was needed (e.g. final variables in a
        // class containing const constructors).
        assert(!node.isConst);
        return;
      }
      if (result is InvalidConstant) {
        if (node.isConst) {
          _reportError(result,
              CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
        } else {
          _reportError(result, null);
        }
      }
    }
  }

  /// Returns `false` if we can prove that `constant == value` always returns
  /// `false`, taking into account the fact that [constantType] has primitive
  /// equality.
  bool _canBeEqual(DartType constantType, DartType valueType) {
    if (constantType is InterfaceType) {
      if (valueType is InterfaceType) {
        if (constantType.isDartCoreInt && valueType.isDartCoreDouble) {
          return true;
        }
        final valueTypeGreatest = PatternGreatestClosureHelper(
          topType: _typeSystem.objectQuestion,
          bottomType: NeverTypeImpl.instance,
        ).eliminateToGreatest(valueType);
        return _typeSystem.isSubtypeOf(constantType, valueTypeGreatest);
      } else if (valueType is TypeParameterTypeImpl) {
        final bound = valueType.promotedBound ?? valueType.element.bound;
        if (bound != null && !hasTypeParameterReference(bound)) {
          final lowestBound =
              valueType.nullabilitySuffix == NullabilitySuffix.question
                  ? _typeSystem.makeNullable(bound)
                  : bound;
          return _canBeEqual(constantType, lowestBound);
        }
      } else if (valueType is FunctionType) {
        if (constantType.isDartCoreNull) {
          return _typeSystem.isNullable(valueType);
        }
        return false;
      }
    }
    // All other cases are not supported, so no warning.
    return true;
  }

  /// Verify that the given [type] does not reference any type parameters.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS].
  void _checkForConstWithTypeParameters(
      TypeAnnotation type, ErrorCode errorCode) {
    if (type is NamedType) {
      // Should not be a type parameter.
      if (type.element is TypeParameterElement) {
        _errorReporter.reportErrorForNode(errorCode, type);
        return;
      }
      // Check type arguments.
      var typeArguments = type.typeArguments;
      if (typeArguments != null) {
        for (TypeAnnotation argument in typeArguments.arguments) {
          _checkForConstWithTypeParameters(argument, errorCode);
        }
      }
    } else if (type is GenericFunctionType) {
      var returnType = type.returnType;
      if (returnType != null) {
        _checkForConstWithTypeParameters(returnType, errorCode);
      }
      for (var parameter in type.parameters.parameters) {
        // [parameter] cannot be a [DefaultFormalParameter], a
        // [FieldFormalParameter], nor a [FunctionTypedFormalParameter].
        if (parameter is SimpleFormalParameter) {
          var parameterType = parameter.type;
          if (parameterType != null) {
            _checkForConstWithTypeParameters(parameterType, errorCode);
          }
        }
      }
      var typeParameters = type.typeParameters;
      if (typeParameters != null) {
        for (var typeParameter in typeParameters.typeParameters) {
          var bound = typeParameter.bound;
          if (bound != null) {
            _checkForConstWithTypeParameters(bound, errorCode);
          }
        }
      }
    }
  }

  /// Evaluates [expression] and reports any evaluation error.
  ///
  /// Returns the compile time constant of [expression], or an [InvalidConstant]
  /// if an error was found during evaluation. If an [InvalidConstant] was
  /// found, the error will be reported and [errorCode] will be the default
  /// error code to be reported.
  Constant _evaluateAndReportError(Expression expression, ErrorCode errorCode) {
    var errorListener = RecordingErrorListener();
    var subErrorReporter = ErrorReporter(
      errorListener,
      _errorReporter.source,
      isNonNullableByDefault: _currentLibrary.isNonNullableByDefault,
    );
    var constantVisitor =
        ConstantVisitor(_evaluationEngine, _currentLibrary, subErrorReporter);
    var result = constantVisitor.evaluateConstant(expression);
    if (result is InvalidConstant) {
      _reportError(result, errorCode);
    }
    return result;
  }

  /// Reports an error to the [_errorReporter].
  ///
  /// If the [error] isn't found in the list, use the given [defaultErrorCode]
  /// instead.
  void _reportError(InvalidConstant error, ErrorCode? defaultErrorCode) {
    if (error.avoidReporting) {
      return;
    }

    // TODO(kallentu): Create a set of errors so this method is readable. But
    // also maybe turn this into a deny list instead of an allow list.
    //
    // These error codes are more specific than the [defaultErrorCode] so they
    // will overwrite and replace the default when we report the error.
    ErrorCode errorCode = error.errorCode;
    if (identical(
            errorCode, CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT) ||
        identical(
            errorCode, CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS) ||
        identical(
            errorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE) ||
        identical(
            errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM) ||
        identical(errorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_STRING) ||
        identical(
            errorCode, CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT) ||
        identical(errorCode,
            CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH) ||
        identical(errorCode,
            CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH) ||
        identical(errorCode, CompileTimeErrorCode.CONST_TYPE_PARAMETER) ||
        identical(errorCode,
            CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF) ||
        identical(errorCode,
            CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET) ||
        identical(errorCode, CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP) ||
        identical(errorCode, CompileTimeErrorCode.EXPRESSION_IN_MAP) ||
        identical(errorCode, CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH) ||
        identical(errorCode, CompileTimeErrorCode.NON_BOOL_CONDITION) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY) ||
        identical(errorCode,
            CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION) ||
        identical(
            errorCode,
            CompileTimeErrorCode
                .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION)) {
      _errorReporter.reportError(
        AnalysisError.tmp(
          source: _errorReporter.source,
          offset: error.offset,
          length: error.length,
          errorCode: error.errorCode,
          arguments: error.arguments,
          contextMessages: error.contextMessages,
        ),
      );
    } else if (defaultErrorCode != null) {
      _errorReporter.reportError(
        AnalysisError.tmp(
          source: _errorReporter.source,
          offset: error.offset,
          length: error.length,
          errorCode: defaultErrorCode,
        ),
      );
    }
  }

  void _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: _currentLibrary.featureSet,
    );
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
    for (Expression argument in argumentList.arguments) {
      _reportNotPotentialConstants(argument);
    }
  }

  /// Check if the object [obj] matches the type [type] according to runtime
  /// type checking rules.
  bool _runtimeTypeMatch(DartObjectImpl obj, DartType type) {
    return _currentLibrary.typeSystem.runtimeTypeMatch(obj, type);
  }

  /// Validate that if the passed arguments are constant expressions.
  ///
  /// @param argumentList the argument list to evaluate
  void _validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      Expression realArgument =
          argument is NamedExpression ? argument.expression : argument;
      _evaluateAndReportError(
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
        var message = initializer.message;
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
  void _validateDefaultValues(FormalParameterList? parameters) {
    if (parameters == null) {
      return;
    }
    for (FormalParameter parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        var defaultValue = parameter.defaultValue;
        Constant? result;
        if (defaultValue == null) {
          result = DartObjectImpl(
            _typeSystem,
            _typeProvider.nullType,
            NullState.NULL_STATE,
          );
        } else if (defaultValue.typeOrThrow is InvalidType) {
          // We have already reported an error.
        } else {
          result = _evaluateAndReportError(
              defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
        }
        VariableElementImpl element =
            parameter.declaredElement as VariableElementImpl;
        element.evaluationResult = result;
      }
    }
  }

  /// Validates that the expressions of any field initializers in
  /// [members] are all compile-time constants. Since this is only
  /// required if the class has a constant constructor, the error is reported at
  /// [constKeyword], the const keyword on such a constant constructor.
  void _validateFieldInitializers(
    List<ClassMember> members,
    Token constKeyword, {
    required bool isEnumDeclaration,
  }) {
    for (ClassMember member in members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration variableDeclaration
            in member.fields.variables) {
          if (isEnumDeclaration &&
              variableDeclaration.name.lexeme == 'values') {
            continue;
          }
          var initializer = variableDeclaration.initializer;
          if (initializer != null) {
            // Ignore any errors produced during validation--if the constant
            // can't be evaluated we'll just report a single error.
            AnalysisErrorListener errorListener =
                AnalysisErrorListener.NULL_LISTENER;
            ErrorReporter subErrorReporter = ErrorReporter(
              errorListener,
              _errorReporter.source,
              isNonNullableByDefault: _currentLibrary.isNonNullableByDefault,
            );
            var result = initializer.accept(ConstantVisitor(
                _evaluationEngine, _currentLibrary, subErrorReporter));
            // TODO(kallentu): Report the specific error we got from the
            // evaluator to make it clear to the user what's wrong.
            if (result is! DartObjectImpl) {
              _errorReporter.reportErrorForToken(
                  CompileTimeErrorCode
                      .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
                  constKeyword,
                  [variableDeclaration.name.lexeme]);
            }
          }
        }
      }
    }
  }

  void _validateSwitchExhaustiveness({
    required AstNode node,
    required Token switchKeyword,
    required Expression scrutinee,
    required List<AstNode> caseNodes,
    required Map<Expression, DartObjectImpl> mapPatternKeyValues,
    required Map<ConstantPattern, DartObjectImpl> constantPatternValues,
    required bool mustBeExhaustive,
    required bool isSwitchExpression,
  }) {
    final scrutineeType = scrutinee.typeOrThrow;
    final scrutineeTypeEx = _exhaustivenessCache.getStaticType(scrutineeType);

    final caseNodesWithSpace = <AstNode>[];
    final caseSpaces = <Space>[];
    var hasDefault = false;

    final patternConverter = PatternConverter(
      featureSet: _currentLibrary.featureSet,
      cache: _exhaustivenessCache,
      mapPatternKeyValues: mapPatternKeyValues,
      constantPatternValues: constantPatternValues,
    );
    patternConverter.hasInvalidType = scrutineeType is InvalidType;

    // Build spaces for cases.
    for (final caseNode in caseNodes) {
      GuardedPattern? guardedPattern;
      if (caseNode is SwitchCase) {
        // Should not happen, ignore.
      } else if (caseNode is SwitchDefault) {
        hasDefault = true;
      } else if (caseNode is SwitchExpressionCase) {
        guardedPattern = caseNode.guardedPattern;
      } else if (caseNode is SwitchPatternCase) {
        guardedPattern = caseNode.guardedPattern;
      } else {
        throw UnimplementedError('(${caseNode.runtimeType}) $caseNode');
      }

      if (guardedPattern != null) {
        Space space = patternConverter.createRootSpace(
            scrutineeTypeEx, guardedPattern.pattern,
            hasGuard: guardedPattern.whenClause != null);
        caseNodesWithSpace.add(caseNode);
        caseSpaces.add(space);
      }
    }

    // Prepare for recording data for testing.
    final exhaustivenessDataForTesting = this.exhaustivenessDataForTesting;

    // Compute and report errors.
    final errors = patternConverter.hasInvalidType
        ? const <ExhaustivenessError>[]
        : reportErrors(_exhaustivenessCache, scrutineeTypeEx, caseSpaces);

    final reportNonExhaustive = mustBeExhaustive && !hasDefault;
    for (final error in errors) {
      if (error is UnreachableCaseError) {
        final caseNode = caseNodesWithSpace[error.index];
        final Token errorToken;
        if (caseNode is SwitchExpressionCase) {
          errorToken = caseNode.arrow;
        } else if (caseNode is SwitchPatternCase) {
          errorToken = caseNode.keyword;
        } else {
          throw UnimplementedError('(${caseNode.runtimeType}) $caseNode');
        }
        _errorReporter.reportErrorForToken(
          WarningCode.UNREACHABLE_SWITCH_CASE,
          errorToken,
        );
      } else if (error is NonExhaustiveError && reportNonExhaustive) {
        var errorBuffer = SimpleDartBuffer();
        error.witness.toDart(errorBuffer, forCorrection: false);
        var correctionTextBuffer = SimpleDartBuffer();
        var correctionDataBuffer = AnalyzerDartTemplateBuffer();
        error.witness.toDart(correctionTextBuffer, forCorrection: true);
        error.witness.toDart(correctionDataBuffer, forCorrection: true);
        _errorReporter.reportErrorForToken(
          isSwitchExpression
              ? CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION
              : CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT,
          switchKeyword,
          [
            scrutineeType,
            errorBuffer.toString(),
            correctionTextBuffer.toString(),
          ],
          [],
          correctionDataBuffer.isComplete ? correctionDataBuffer.parts : null,
        );
      }
    }

    // Record data for testing.
    if (exhaustivenessDataForTesting != null) {
      for (var i = 0; i < caseSpaces.length; i++) {
        final caseNode = caseNodesWithSpace[i];
        exhaustivenessDataForTesting.caseSpaces[caseNode] = caseSpaces[i];
      }
      exhaustivenessDataForTesting.switchScrutineeType[node] = scrutineeTypeEx;
      exhaustivenessDataForTesting.switchCases[node] = caseSpaces;
      for (var error in errors) {
        if (error is UnreachableCaseError) {
          exhaustivenessDataForTesting.errors[caseNodesWithSpace[error.index]] =
              error;
        } else if (reportNonExhaustive) {
          exhaustivenessDataForTesting.errors[node] = error;
        }
      }
    }
  }

  void _validateSwitchStatement_legacy(SwitchStatement node) {
    // TODO(paulberry): to minimize error messages, it would be nice to
    // compare all types with the most popular type rather than the first
    // type.
    bool foundError = false;
    DartObjectImpl? firstValue;
    DartType? firstType;
    for (var switchMember in node.members) {
      if (switchMember is SwitchCase) {
        Expression expression = switchMember.expression;

        var expressionValue = _evaluateAndReportError(
          expression,
          CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION,
        );
        if (expressionValue is! DartObjectImpl) {
          continue;
        }
        firstValue ??= expressionValue;

        var expressionValueType = _typeSystem.toLegacyTypeIfOptOut(
          expressionValue.type,
        );

        if (firstType == null) {
          firstType = expressionValueType;
        } else {
          if (firstType != expressionValueType) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
              expression,
              [expression.toSource(), firstType],
            );
            foundError = true;
          }
        }
      }
    }

    if (foundError) {
      return;
    }

    if (firstValue != null) {
      final featureSet = _currentLibrary.featureSet;
      if (!firstValue.hasPrimitiveEquality(featureSet)) {
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
          node.switchKeyword,
          [firstValue.type],
        );
      }
    }
  }

  void _validateSwitchStatement_nullSafety(SwitchStatement node) {
    void validateExpression(Expression expression) {
      var expressionValue = _evaluateAndReportError(
        expression,
        CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION,
      );
      if (expressionValue is! DartObjectImpl) {
        return;
      }

      final featureSet = _currentLibrary.featureSet;
      if (!featureSet.isEnabled(Feature.patterns)) {
        var expressionType = expressionValue.type;
        if (!expressionValue.hasPrimitiveEquality(featureSet)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
            expression,
            [expressionType],
          );
        }
      }
    }

    for (var switchMember in node.members) {
      if (switchMember is SwitchCase) {
        validateExpression(switchMember.expression);
      } else if (switchMember is SwitchPatternCase) {
        if (_currentLibrary.featureSet.isEnabled(Feature.patterns)) {
          switchMember.accept(this);
        } else {
          var pattern = switchMember.guardedPattern.pattern;
          if (pattern is ConstantPattern) {
            validateExpression(pattern.expression.unParenthesized);
          }
        }
      }
    }
  }

  /// Runs [f] with new [_constantPatternValues].
  void _withConstantPatternValues(
    void Function(Map<Expression, DartObjectImpl> mapPatternKeyValues,
            Map<ConstantPattern, DartObjectImpl> constantPatternValues)
        f,
  ) {
    final previousMapKeyValues = _mapPatternKeyValues;
    final previousConstantPatternValues = _constantPatternValues;
    final mapKeyValues = _mapPatternKeyValues = {};
    final constantValues = _constantPatternValues = {};
    f(mapKeyValues, constantValues);
    _mapPatternKeyValues = previousMapKeyValues;
    _constantPatternValues = previousConstantPatternValues;
  }
}

class _ConstLiteralVerifier {
  final ConstantVerifier verifier;
  final ErrorCode errorCode;
  final DartType? listElementType;
  final _SetVerifierConfig? setConfig;
  final _MapVerifierConfig? mapConfig;

  _ConstLiteralVerifier(
    this.verifier, {
    required this.errorCode,
    this.listElementType,
    this.mapConfig,
    this.setConfig,
  });

  bool verify(CollectionElement element) {
    if (element is Expression) {
      var value = verifier._evaluateAndReportError(element, errorCode);
      if (value is! DartObjectImpl) return false;

      final listElementType = this.listElementType;
      if (listElementType != null) {
        return _validateListExpression(listElementType, element, value);
      }

      final setConfig = this.setConfig;
      if (setConfig != null) {
        return _validateSetExpression(setConfig, element, value);
      }

      return true;
    } else if (element is ForElement) {
      verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, element);
      return false;
    } else if (element is IfElement) {
      var conditionValue =
          verifier._evaluateAndReportError(element.expression, errorCode);
      if (conditionValue is! DartObjectImpl) {
        return false;
      }
      var conditionBool = conditionValue.toBoolValue();

      // The errors have already been reported.
      if (conditionBool == null) return false;

      var thenValid = true;
      var elseValid = true;
      var thenElement = element.thenElement;
      var elseElement = element.elseElement;
      if (conditionBool) {
        thenValid = verify(thenElement);
        if (elseElement != null) {
          elseValid = _reportNotPotentialConstants(elseElement);
        }
      } else {
        thenValid = _reportNotPotentialConstants(thenElement);
        if (elseElement != null) {
          elseValid = verify(elseElement);
        }
      }

      return thenValid && elseValid;
    } else if (element is MapLiteralEntry) {
      return _validateMapLiteralEntry(element);
    } else if (element is SpreadElement) {
      var value =
          verifier._evaluateAndReportError(element.expression, errorCode);
      if (value is! DartObjectImpl) return false;

      if (listElementType != null || setConfig != null) {
        return _validateListOrSetSpread(element, value);
      }

      final mapConfig = this.mapConfig;
      if (mapConfig != null) {
        return _validateMapSpread(mapConfig, element, value);
      }

      return true;
    }
    throw UnsupportedError(
      'Unhandled type of collection element: ${element.runtimeType}',
    );
  }

  /// Return `true` if the [node] is a potential constant.
  bool _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: verifier._currentLibrary.featureSet,
    );
    if (notPotentiallyConstants.isEmpty) return true;

    for (var notConst in notPotentiallyConstants) {
      CompileTimeErrorCode errorCode;
      if (listElementType != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT;
      } else if (mapConfig != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT;
        for (AstNode? parent = notConst;
            parent != null;
            parent = parent.parent) {
          if (parent is MapLiteralEntry) {
            if (parent.key == notConst) {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_KEY;
            } else {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE;
            }
            break;
          }
        }
      } else if (setConfig != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT;
      } else {
        throw UnimplementedError();
      }
      verifier._errorReporter.reportErrorForNode(errorCode, notConst);
    }

    return false;
  }

  bool _validateListExpression(
      DartType listElementType, Expression expression, DartObjectImpl value) {
    if (!verifier._runtimeTypeMatch(value, listElementType)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, listElementType],
      );
      return false;
    }

    return true;
  }

  bool _validateListOrSetSpread(SpreadElement element, DartObjectImpl value) {
    var listValue = value.toListValue();
    var setValue = value.toSetValue();
    var iterableValue = listValue ?? setValue;

    if (iterableValue == null) {
      if (value.isNull && element.isNullAware) {
        return true;
      }
      // TODO(kallentu): Consolidate this with
      // [ConstantVisitor._addElementsToList] and the other similar
      // _addElementsTo methods..
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
        element.expression,
      );
      return false;
    }

    final setConfig = this.setConfig;
    if (setConfig == null) {
      return true;
    }

    if (listValue != null) {
      final featureSet = verifier._currentLibrary.featureSet;
      if (!listValue.every((e) => e.hasPrimitiveEquality(featureSet))) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY,
          element,
          [value.type],
        );
        return false;
      }
    }

    for (var item in iterableValue) {
      Expression expression = element.expression;
      var existingValue = setConfig.uniqueValues[item];
      if (existingValue != null) {
        setConfig.duplicateElements[expression] = existingValue;
      } else {
        setConfig.uniqueValues[item] = expression;
      }
    }

    return true;
  }

  bool _validateMapLiteralEntry(MapLiteralEntry entry) {
    var config = mapConfig;
    if (config == null) return false;

    var keyExpression = entry.key;
    var valueExpression = entry.value;

    var keyValue = verifier._evaluateAndReportError(
      keyExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_KEY,
    );
    var valueValue = verifier._evaluateAndReportError(
      valueExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    );

    if (keyValue is DartObjectImpl) {
      var keyType = keyValue.type;

      if (!verifier._runtimeTypeMatch(keyValue, config.keyType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
          keyExpression,
          [keyType, config.keyType],
        );
      }

      final featureSet = verifier._currentLibrary.featureSet;
      if (!keyValue.hasPrimitiveEquality(featureSet)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY,
          keyExpression,
          [keyType],
        );
      }

      var existingKey = config.uniqueKeys[keyValue];
      if (existingKey != null) {
        config.duplicateKeys[keyExpression] = existingKey;
      } else {
        config.uniqueKeys[keyValue] = keyExpression;
      }
    }

    if (valueValue is DartObjectImpl) {
      if (!verifier._runtimeTypeMatch(valueValue, config.valueType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
          valueExpression,
          [valueValue.type, config.valueType],
        );
      }
    }

    return true;
  }

  bool _validateMapSpread(
    _MapVerifierConfig config,
    SpreadElement element,
    DartObjectImpl value,
  ) {
    if (value.isNull && element.isNullAware) {
      return true;
    }
    var map = value.toMapValue();
    if (map != null) {
      // TODO(brianwilkerson) Figure out how to improve the error messages. They
      //  currently point to the whole spread expression, but the key and/or
      //  value being referenced might not be located there (if it's referenced
      //  through a const variable).
      for (var keyValue in map.keys) {
        var existingKey = config.uniqueKeys[keyValue];
        if (existingKey != null) {
          config.duplicateKeys[element.expression] = existingKey;
        } else {
          config.uniqueKeys[keyValue] = element.expression;
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

  bool _validateSetExpression(
    _SetVerifierConfig config,
    Expression expression,
    DartObjectImpl value,
  ) {
    if (!verifier._runtimeTypeMatch(value, config.elementType)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, config.elementType],
      );
      return false;
    }

    final featureSet = verifier._currentLibrary.featureSet;
    if (!value.hasPrimitiveEquality(featureSet)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY,
        expression,
        [value.type],
      );
      return false;
    }

    var existingValue = config.uniqueValues[value];
    if (existingValue != null) {
      config.duplicateElements[expression] = existingValue;
    } else {
      config.uniqueValues[value] = expression;
    }

    return true;
  }
}

class _MapVerifierConfig {
  final DartType keyType;
  final DartType valueType;
  final Map<DartObject, Expression> uniqueKeys = {};
  final Map<Expression, Expression> duplicateKeys = {};

  _MapVerifierConfig({
    required this.keyType,
    required this.valueType,
  });
}

class _SetVerifierConfig {
  final DartType elementType;
  final Map<DartObject, Expression> uniqueValues = {};
  final Map<Expression, Expression> duplicateElements = {};

  _SetVerifierConfig({
    required this.elementType,
  });
}

extension on Expression {
  /// Returns whether `this` is found in a constant expression.
  ///
  /// This does not check whether `this` is found in a constant context.
  bool get inConstantExpression {
    AstNode child = this;
    var parent = child.parent;
    while (parent != null) {
      if (parent is DefaultFormalParameter && child == parent.defaultValue) {
        // A parameter default value does not constitute a constant context, but
        // must be a constant expression.
        return true;
      } else if (parent is VariableDeclaration && child == parent.initializer) {
        var declarationList = parent.parent;
        if (declarationList is VariableDeclarationList) {
          var declarationListParent = declarationList.parent;
          if (declarationListParent is FieldDeclaration &&
              !declarationListParent.isStatic) {
            var container = declarationListParent.parent;
            if (container is ClassDeclaration) {
              var enclosingClass = container.declaredElement;
              if (enclosingClass is ClassElementImpl) {
                // A field initializer of a class with at least one generative
                // const constructor does not constitute a constant context, but
                // must be a constant expression.
                return enclosingClass.hasGenerativeConstConstructor;
              }
            }
          }
        }
        return false;
      } else {
        child = parent;
        parent = child.parent;
      }
    }
    return false;
  }
}

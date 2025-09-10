// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/exhaustiveness/dart_template_buffer.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
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
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';

/// Instances of the class `ConstantVerifier` traverse an AST structure looking
/// for additional errors and warnings not covered by the parser and resolver.
/// In particular, it looks for errors and warnings related to constant
/// expressions.
class ConstantVerifier extends RecursiveAstVisitor<void> {
  /// The diagnostic reporter by which diagnostics will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// The type operations.
  final TypeSystemImpl _typeSystem;

  /// The type provider used to access the known types.
  final TypeProviderImpl _typeProvider;

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

  final ExhaustivenessDataForTesting? exhaustivenessDataForTesting;

  /// Initialize a newly created constant verifier.
  ConstantVerifier(
    DiagnosticReporter diagnosticReporter,
    LibraryElementImpl currentLibrary,
    DeclaredVariables declaredVariables, {
    bool retainDataForTesting = false,
  }) : this._(
         diagnosticReporter,
         currentLibrary,
         currentLibrary.typeSystem,
         currentLibrary.typeProvider,
         declaredVariables,
         AnalyzerExhaustivenessCache(currentLibrary.typeSystem, currentLibrary),
         retainDataForTesting: retainDataForTesting,
       );

  ConstantVerifier._(
    this._diagnosticReporter,
    this._currentLibrary,
    this._typeSystem,
    this._typeProvider,
    DeclaredVariables declaredVariables,
    this._exhaustivenessCache, {
    required bool retainDataForTesting,
  }) : _evaluationEngine = ConstantEvaluationEngine(
         declaredVariables: declaredVariables,
         configuration: ConstantEvaluationConfiguration(),
       ),
       exhaustivenessDataForTesting = retainDataForTesting
           ? ExhaustivenessDataForTesting(_exhaustivenessCache)
           : null;

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    var element = node.element;
    if (element is ConstructorElement) {
      // should be 'const' constructor
      if (!element.isConst) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.nonConstantAnnotationConstructor,
        );
        return;
      }
      // should have arguments
      var argumentList = node.arguments;
      if (argumentList == null) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.noAnnotationConstructorArguments,
        );
        return;
      }
      // arguments should be constants
      _validateConstantArguments(argumentList);
    }
  }

  @override
  void visitConstantPattern(covariant ConstantPatternImpl node) {
    var expression = node.expression.unParenthesized;
    if (expression.typeOrThrow is InvalidType) {
      return;
    }

    var value = _evaluateAndReportError(
      expression,
      CompileTimeErrorCode.constantPatternWithNonConstantExpression,
    );
    if (value is DartObjectImpl) {
      if (_currentLibrary.featureSet.isEnabled(Feature.patterns)) {
        _constantPatternValues?[node] = value;
        if (value.hasPrimitiveEquality(_currentLibrary.featureSet)) {
          var constantType = value.type;
          var matchedValueType = node.matchedValueType;
          matchedValueType = matchedValueType?.extensionTypeErasure;
          if (matchedValueType != null) {
            if (!_canBeEqual(constantType, matchedValueType)) {
              _diagnosticReporter.atNode(
                node,
                WarningCode.constantPatternNeverMatchesValueType,
                arguments: [matchedValueType, constantType],
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
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var constKeyword = node.constKeyword;
    if (constKeyword != null) {
      // Check and report cycles.
      // Factory cycles are reported in elsewhere in
      // [ErrorVerifier._checkForRecursiveFactoryRedirect].
      var element = node.declaredFragment!.element;
      if (!element.isCycleFree && !element.isFactory) {
        _diagnosticReporter.atNode(
          node.returnType,
          CompileTimeErrorCode.recursiveConstantConstructor,
        );
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
      _checkForConstWithTypeParameters(
        node.constructorName.type,
        CompileTimeErrorCode.constWithTypeParametersConstructorTearoff,
      );
    }
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    if (node.isConst) {
      var constructor = node.constructorName.element;
      if (constructor is InternalConstructorElement) {
        _validateConstructorInvocation(node, constructor, node.argumentList);
      }
    } else {
      super.visitDotShorthandConstructorInvocation(node);
    }
  }

  @override
  visitEnumConstantDeclaration(covariant EnumConstantDeclarationImpl node) {
    super.visitEnumConstantDeclaration(node);

    var argumentList = node.arguments?.argumentList;
    if (argumentList != null) {
      _validateConstantArguments(argumentList);
    }

    var element = node.declaredFragment!.element;
    var result = element.evaluationResult;
    if (result is InvalidConstant) {
      _reportError(result, null);
    }
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
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
        _checkForConstWithTypeParameters(
          typeArgument,
          CompileTimeErrorCode.constWithTypeParametersFunctionTearoff,
        );
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
        node,
        CompileTimeErrorCode.constWithTypeParameters,
      );
    }
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    if (node.isConst) {
      var namedType = node.constructorName.type;
      _checkForConstWithTypeParameters(
        namedType,
        CompileTimeErrorCode.constWithTypeParameters,
      );

      var constructor = node.constructorName.element;
      if (constructor != null) {
        _validateConstructorInvocation(node, constructor, node.argumentList);
      }
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.isConst) {
      var nodeType = node.staticType as InterfaceTypeImpl;
      var elementType = nodeType.typeArguments[0];
      var verifier = _ConstLiteralVerifier(
        this,
        diagnosticCode: CompileTimeErrorCode.nonConstantListElement,
        listElementType: elementType,
      );
      for (var element in node.elements) {
        verifier.verify(element);
      }
    }
  }

  @override
  void visitMapPattern(MapPattern node) {
    node.typeArguments?.accept(this);

    var featureSet = _currentLibrary.featureSet;
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
          CompileTimeErrorCode.nonConstantMapPatternKey,
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
      _diagnosticReporter.reportError(
        _diagnosticFactory.equalKeysInMapPattern(
          _diagnosticReporter.source,
          duplicateEntry.key,
          duplicateEntry.value,
        ),
      );
    }
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    super.visitRecordLiteral(node);

    if (node.isConst) {
      for (var field in node.fields) {
        _evaluateAndReportError(
          field,
          CompileTimeErrorCode.nonConstantRecordField,
        );
      }
    }
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    super.visitRelationalPattern(node);

    _evaluateAndReportError(
      node.operand,
      CompileTimeErrorCode.nonConstantRelationalPatternExpression,
    );
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);
    if (node.isSet) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceTypeImpl;
        var elementType = nodeType.typeArguments[0];
        var config = _SetVerifierConfig(elementType: elementType);
        var verifier = _ConstLiteralVerifier(
          this,
          diagnosticCode: CompileTimeErrorCode.nonConstantSetElement,
          setConfig: config,
        );
        for (CollectionElement element in node.elements) {
          verifier.verify(element);
        }
        for (var duplicateEntry in config.duplicateElements.entries) {
          _diagnosticReporter.reportError(
            _diagnosticFactory.equalElementsInConstSet(
              _diagnosticReporter.source,
              duplicateEntry.key,
              duplicateEntry.value,
            ),
          );
        }
      }
    } else if (node.isMap) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceTypeImpl;
        var keyType = nodeType.typeArguments[0];
        var valueType = nodeType.typeArguments[1];
        var config = _MapVerifierConfig(keyType: keyType, valueType: valueType);
        var verifier = _ConstLiteralVerifier(
          this,
          diagnosticCode: CompileTimeErrorCode.nonConstantMapElement,
          mapConfig: config,
        );
        for (var entry in node.elements) {
          verifier.verify(entry);
        }
        for (var duplicateEntry in config.duplicateKeys.entries) {
          _diagnosticReporter.reportError(
            _diagnosticFactory.equalKeysInConstMap(
              _diagnosticReporter.source,
              duplicateEntry.key,
              duplicateEntry.value,
            ),
          );
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
          mustBeExhaustive: _typeSystem.isAlwaysExhaustive(
            node.expression.typeOrThrow,
          ),
          isSwitchExpression: false,
        );
      } else {
        _validateSwitchStatement_nullSafety(node);
      }
    });
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    super.visitVariableDeclaration(node);
    var initializer = node.initializer;
    if (initializer != null && (node.isConst || node.isFinal)) {
      var element = node.declaredFragment!.element;
      if (element is FieldElementImpl && !element.isStatic) {
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
          _reportError(
            result,
            CompileTimeErrorCode.constInitializedWithNonConstantValue,
          );
        } else {
          _reportError(result, null);
        }
      }
    }
  }

  /// Returns `false` if we can prove that `constant == value` always returns
  /// `false`, taking into account the fact that [constantType] has primitive
  /// equality.
  bool _canBeEqual(TypeImpl constantType, TypeImpl valueType) {
    if (constantType is InterfaceType) {
      if (valueType is InterfaceTypeImpl) {
        if (constantType.isDartCoreInt && valueType.isDartCoreDouble) {
          return true;
        }
        var valueTypeGreatest = PatternGreatestClosureHelper(
          topType: _typeSystem.objectQuestion,
          bottomType: NeverTypeImpl.instance,
        ).eliminateToGreatest(valueType);
        return _typeSystem.isSubtypeOf(constantType, valueTypeGreatest);
      } else if (valueType is TypeParameterTypeImpl) {
        var bound = valueType.promotedBound ?? valueType.element.bound;
        if (bound != null && !hasTypeParameterReference(bound)) {
          var lowestBound =
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

  /// Verify that the given [type] does not reference any type parameters which
  /// are declared outside [type].
  ///
  /// A generic function type is allowed to reference its own type parameter(s).
  ///
  /// See [CompileTimeErrorCode.constWithTypeParameters].
  void _checkForConstWithTypeParameters(
    TypeAnnotation type,
    DiagnosticCode diagnosticCode, {
    Set<TypeParameterElement>? allowedTypeParameters,
  }) {
    allowedTypeParameters = {...?allowedTypeParameters};
    if (type is NamedType) {
      // Should not be a type parameter.
      if (type.element is TypeParameterElement &&
          !allowedTypeParameters.contains(type.element)) {
        _diagnosticReporter.atNode(type, diagnosticCode);
        return;
      }
      // Check type arguments.
      var typeArguments = type.typeArguments;
      if (typeArguments != null) {
        for (var argument in typeArguments.arguments) {
          _checkForConstWithTypeParameters(
            argument,
            diagnosticCode,
            allowedTypeParameters: allowedTypeParameters,
          );
        }
      }
    } else if (type is GenericFunctionType) {
      var typeParameters = type.typeParameters;
      if (typeParameters != null) {
        allowedTypeParameters.addAll(
          typeParameters.typeParameters
              .map((tp) => tp.declaredFragment!.element)
              .nonNulls,
        );
        for (var typeParameter in typeParameters.typeParameters) {
          var bound = typeParameter.bound;
          if (bound != null) {
            _checkForConstWithTypeParameters(
              bound,
              diagnosticCode,
              allowedTypeParameters: allowedTypeParameters,
            );
          }
        }
      }
      var returnType = type.returnType;
      if (returnType != null) {
        _checkForConstWithTypeParameters(
          returnType,
          diagnosticCode,
          allowedTypeParameters: allowedTypeParameters,
        );
      }
      for (var parameter in type.parameters.parameters) {
        // In a generic function type, [parameter] can only be a
        // [SimpleFormalParameter].
        if (parameter is SimpleFormalParameter) {
          var parameterType = parameter.type;
          if (parameterType != null) {
            _checkForConstWithTypeParameters(
              parameterType,
              diagnosticCode,
              allowedTypeParameters: allowedTypeParameters,
            );
          }
        }
      }
    }
  }

  /// Evaluates [expression] and reports any evaluation error.
  ///
  /// Returns the compile time constant of [expression], or an [InvalidConstant]
  /// if an error was found during evaluation. If an [InvalidConstant] was
  /// found, the error will be reported and [diagnosticCode] will be the default
  /// error code to be reported.
  Constant _evaluateAndReportError(
    Expression expression,
    DiagnosticCode diagnosticCode,
  ) {
    var diagnosticListener = RecordingDiagnosticListener();
    var subDiagnosticReporter = DiagnosticReporter(
      diagnosticListener,
      _diagnosticReporter.source,
    );
    var constantVisitor = ConstantVisitor(
      _evaluationEngine,
      _currentLibrary,
      subDiagnosticReporter,
    );
    var result = constantVisitor.evaluateConstant(expression);
    if (result is InvalidConstant) {
      _reportError(result, diagnosticCode);
    }
    return result;
  }

  /// Reports an error to the [_diagnosticReporter].
  ///
  /// If the [error] isn't found in the list, use the given
  /// [defaultDiagnosticCode] instead.
  void _reportError(
    InvalidConstant error,
    DiagnosticCode? defaultDiagnosticCode,
  ) {
    if (error.avoidReporting) {
      return;
    }

    // TODO(kallentu): Create a set of errors so this method is readable. But
    // also maybe turn this into a deny list instead of an allow list.
    //
    // These error codes are more specific than the [defaultErrorCode] so they
    // will overwrite and replace the default when we report the error.
    DiagnosticCode diagnosticCode = error.diagnosticCode;
    if (identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalExtensionMethod,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalExtensionTypeMethod,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalForElement) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalMethodInvocation,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalPrimitiveEquality,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalPropertyAccess,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalThrowsException,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalThrowsIdbze) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalTypeBoolNumString,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalTypeBool) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalTypeBoolInt) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalTypeInt) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalTypeNum) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constEvalTypeNumString,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.constEvalTypeString) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.recursiveCompileTimeConstant,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constConstructorFieldTypeMismatch,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constConstructorParamTypeMismatch,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.constTypeParameter) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constWithTypeParametersFunctionTearoff,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constSpreadExpectedListOrSet,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.constSpreadExpectedMap,
        ) ||
        identical(diagnosticCode, CompileTimeErrorCode.expressionInMap) ||
        identical(diagnosticCode, CompileTimeErrorCode.variableTypeMismatch) ||
        identical(diagnosticCode, CompileTimeErrorCode.nonBoolCondition) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantDefaultValueFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantMapKeyFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantMapValueFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.setElementFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.spreadExpressionFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantCaseExpressionFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode
              .invalidAnnotationConstantValueFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.ifElementConditionFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode
              .constInitializedWithNonConstantValueFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantListElementFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.nonConstantRecordFieldFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode
              .constInitializedWithNonConstantValueFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.patternConstantFromDeferredLibrary,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction,
        ) ||
        identical(
          diagnosticCode,
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsAnonymousFunction,
        )) {
      _diagnosticReporter.reportError(
        Diagnostic.tmp(
          source: _diagnosticReporter.source,
          offset: error.offset,
          length: error.length,
          diagnosticCode: error.diagnosticCode,
          arguments: error.arguments,
          contextMessages: error.contextMessages,
        ),
      );
    } else if (defaultDiagnosticCode != null) {
      _diagnosticReporter.reportError(
        Diagnostic.tmp(
          source: _diagnosticReporter.source,
          offset: error.offset,
          length: error.length,
          diagnosticCode: defaultDiagnosticCode,
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
      _diagnosticReporter.atNode(
        notConst,
        CompileTimeErrorCode.invalidConstant,
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
  bool _runtimeTypeMatch(DartObjectImpl obj, TypeImpl type) {
    return _currentLibrary.typeSystem.runtimeTypeMatch(obj, type);
  }

  /// Validates that the arguments in [argumentList] are constant expressions.
  void _validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      Expression realArgument = argument is NamedExpression
          ? argument.expression
          : argument;
      _evaluateAndReportError(
        realArgument,
        CompileTimeErrorCode.constWithNonConstantArgument,
      );
    }
  }

  /// Validates that the expressions of the initializers of the given constant
  /// [constructor] are constant expressions.
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

  /// Validates that the [constructor] invocation, its type arguments, and its
  /// arguments are constant expressions.
  void _validateConstructorInvocation(
    AstNode node,
    InternalConstructorElement constructor,
    ArgumentList argumentList,
  ) {
    var constantVisitor = ConstantVisitor(
      _evaluationEngine,
      _currentLibrary,
      _diagnosticReporter,
    );
    var result = _evaluationEngine.evaluateAndFormatErrorsInConstructorCall(
      _currentLibrary,
      node,
      constructor.returnType.typeArguments,
      argumentList.arguments,
      constructor,
      constantVisitor,
    );
    switch (result) {
      case InvalidConstant():
        if (!result.avoidReporting) {
          _diagnosticReporter.atOffset(
            offset: result.offset,
            length: result.length,
            diagnosticCode: result.diagnosticCode,
            arguments: result.arguments,
            contextMessages: result.contextMessages,
          );
        }
      case DartObjectImpl():
        // Check for further errors in individual arguments.
        argumentList.accept(this);
    }
  }

  /// Validates that the default value associated with each of the parameters in
  /// [parameters] is a constant expression.
  void _validateDefaultValues(covariant FormalParameterListImpl? parameters) {
    if (parameters == null) {
      return;
    }
    for (var parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameterImpl) {
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
            defaultValue,
            CompileTimeErrorCode.nonConstantDefaultValue,
          );
        }
        var element = parameter.declaredFragment!.element;
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
            // Ignore any diagnostics produced during validation--if the
            // constant can't be evaluated we'll just report a single error.
            DiagnosticReporter subDiagnosticReporter = DiagnosticReporter(
              DiagnosticListener.nullListener,
              _diagnosticReporter.source,
            );
            var result = initializer.accept(
              ConstantVisitor(
                _evaluationEngine,
                _currentLibrary,
                subDiagnosticReporter,
              ),
            );
            // TODO(kallentu): Report the specific error we got from the
            // evaluator to make it clear to the user what's wrong.
            if (result is! DartObjectImpl) {
              _diagnosticReporter.atToken(
                constKeyword,
                CompileTimeErrorCode
                    .constConstructorWithFieldInitializedByNonConst,
                arguments: [variableDeclaration.name.lexeme],
              );
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
    var scrutineeType = scrutinee.typeOrThrow;
    var scrutineeTypeEx = _exhaustivenessCache.getStaticType(scrutineeType);

    var caseNodesWithSpace = <CaseNodeImpl>[];
    var caseIsGuarded = <bool>[];
    var caseSpaces = <Space>[];
    SwitchDefault? defaultNode;

    var patternConverter = PatternConverter(
      languageVersion: _currentLibrary.languageVersion.effective,
      featureSet: _currentLibrary.featureSet,
      cache: _exhaustivenessCache,
      mapPatternKeyValues: mapPatternKeyValues,
      constantPatternValues: constantPatternValues,
    );
    patternConverter.hasInvalidType = scrutineeType is InvalidType;

    // Build spaces for cases.
    for (var caseNode in caseNodes) {
      if (caseNode is SwitchCase) {
        // Should not happen, ignore.
      } else if (caseNode is SwitchDefault) {
        defaultNode = caseNode;
      } else if (caseNode is CaseNodeImpl) {
        Space space = patternConverter.createRootSpace(
          scrutineeTypeEx,
          caseNode.guardedPattern.pattern,
        );
        caseNodesWithSpace.add(caseNode);
        caseIsGuarded.add(caseNode.guardedPattern.whenClause != null);
        caseSpaces.add(space);
      } else {
        throw UnimplementedError('(${caseNode.runtimeType}) $caseNode');
      }
    }
    var reportNonExhaustive = mustBeExhaustive && defaultNode == null;

    // Prepare for recording data for testing.
    var exhaustivenessDataForTesting = this.exhaustivenessDataForTesting;

    // Compute and report errors.
    List<CaseUnreachability> caseUnreachabilities = [];
    NonExhaustiveness? nonExhaustiveness;
    if (!patternConverter.hasInvalidType) {
      nonExhaustiveness = computeExhaustiveness(
        _exhaustivenessCache,
        scrutineeTypeEx,
        caseIsGuarded,
        caseSpaces,
        caseUnreachabilities: caseUnreachabilities,
      );
      for (var caseUnreachability in caseUnreachabilities) {
        var caseNode = caseNodesWithSpace[caseUnreachability.index];
        var errorToken = switch (caseNode) {
          SwitchExpressionCaseImpl() => caseNode.arrow,
          SwitchPatternCaseImpl() => caseNode.keyword,
        };
        _diagnosticReporter.atToken(
          errorToken,
          WarningCode.unreachableSwitchCase,
        );
      }
      if (nonExhaustiveness != null) {
        if (reportNonExhaustive) {
          var errorBuffer = SimpleDartBuffer();
          nonExhaustiveness.witnesses.first.toDart(
            errorBuffer,
            forCorrection: false,
          );
          var correctionTextBuffer = SimpleDartBuffer();
          nonExhaustiveness.witnesses.first.toDart(
            correctionTextBuffer,
            forCorrection: true,
          );

          var correctionData = <List<MissingPatternPart>>[];
          for (var witness in nonExhaustiveness.witnesses) {
            var correctionDataBuffer = AnalyzerDartTemplateBuffer();
            witness.toDart(correctionDataBuffer, forCorrection: true);
            if (correctionDataBuffer.isComplete) {
              correctionData.add(correctionDataBuffer.parts);
            }
          }
          var diagnostic = _diagnosticReporter.atToken(
            switchKeyword,
            isSwitchExpression
                ? CompileTimeErrorCode.nonExhaustiveSwitchExpression
                : CompileTimeErrorCode.nonExhaustiveSwitchStatement,
            arguments: [
              scrutineeType,
              errorBuffer.toString(),
              correctionTextBuffer.toString(),
            ],
          );
          if (correctionData.isNotEmpty) {
            MissingPatternPart.byDiagnostic[diagnostic] = correctionData;
          }
        }
      } else {
        if (defaultNode != null && mustBeExhaustive) {
          // Default node is unreachable
          _diagnosticReporter.atToken(
            defaultNode.keyword,
            WarningCode.unreachableSwitchDefault,
          );
        }
      }
    }

    // Record data for testing.
    if (exhaustivenessDataForTesting != null) {
      for (var i = 0; i < caseSpaces.length; i++) {
        var caseNode = caseNodesWithSpace[i];
        exhaustivenessDataForTesting.caseSpaces[caseNode] = caseSpaces[i];
      }
      exhaustivenessDataForTesting.switchScrutineeType[node] = scrutineeTypeEx;
      exhaustivenessDataForTesting.switchCases[node] = caseSpaces;
      for (var caseUnreachability in caseUnreachabilities) {
        exhaustivenessDataForTesting
                .caseUnreachabilities[caseNodesWithSpace[caseUnreachability
                .index]] =
            caseUnreachability;
      }
      if (nonExhaustiveness != null && reportNonExhaustive) {
        exhaustivenessDataForTesting.nonExhaustivenesses[node] =
            nonExhaustiveness;
      }
    }
  }

  void _validateSwitchStatement_nullSafety(SwitchStatement node) {
    void validateExpression(Expression expression) {
      var expressionValue = _evaluateAndReportError(
        expression,
        CompileTimeErrorCode.nonConstantCaseExpression,
      );
      if (expressionValue is! DartObjectImpl) {
        return;
      }

      var featureSet = _currentLibrary.featureSet;
      if (!featureSet.isEnabled(Feature.patterns)) {
        var expressionType = expressionValue.type;
        if (!expressionValue.hasPrimitiveEquality(featureSet)) {
          _diagnosticReporter.atNode(
            expression,
            CompileTimeErrorCode.caseExpressionTypeImplementsEquals,
            arguments: [expressionType],
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
    void Function(
      Map<Expression, DartObjectImpl> mapPatternKeyValues,
      Map<ConstantPattern, DartObjectImpl> constantPatternValues,
    )
    f,
  ) {
    var previousMapKeyValues = _mapPatternKeyValues;
    var previousConstantPatternValues = _constantPatternValues;
    var mapKeyValues = _mapPatternKeyValues = {};
    var constantValues = _constantPatternValues = {};
    f(mapKeyValues, constantValues);
    _mapPatternKeyValues = previousMapKeyValues;
    _constantPatternValues = previousConstantPatternValues;
  }
}

class _ConstLiteralVerifier {
  final ConstantVerifier verifier;
  final DiagnosticCode diagnosticCode;
  final TypeImpl? listElementType;
  final _SetVerifierConfig? setConfig;
  final _MapVerifierConfig? mapConfig;

  _ConstLiteralVerifier(
    this.verifier, {
    required this.diagnosticCode,
    this.listElementType,
    this.mapConfig,
    this.setConfig,
  });

  bool verify(CollectionElement element) {
    if (element is Expression) {
      var value = verifier._evaluateAndReportError(element, diagnosticCode);
      if (value is! DartObjectImpl) return false;

      var listElementType = this.listElementType;
      if (listElementType != null) {
        return _validateListExpression(listElementType, element, value);
      }

      var setConfig = this.setConfig;
      if (setConfig != null) {
        return _validateSetExpression(setConfig, element, value);
      }

      return true;
    } else if (element is ForElement) {
      verifier._diagnosticReporter.atNode(
        element,
        CompileTimeErrorCode.constEvalForElement,
      );
      return false;
    } else if (element is IfElement) {
      var conditionConstant = verifier._evaluateAndReportError(
        element.expression,
        diagnosticCode,
      );
      if (conditionConstant is! DartObjectImpl) {
        return false;
      }

      // The errors have already been reported.
      if (!conditionConstant.isBool) return false;

      var conditionValue = conditionConstant.toBoolValue();

      var thenValid = true;
      var elseValid = true;
      var thenElement = element.thenElement;
      var elseElement = element.elseElement;

      if (conditionValue == null) {
        thenValid = _reportNotPotentialConstants(thenElement);
        if (elseElement != null) {
          elseValid = _reportNotPotentialConstants(elseElement);
        }
        return thenValid && elseValid;
      }

      // Only validate the relevant branch as per `conditionValue`. This
      // avoids issues like duplicate values showing up in a const set, when
      // they occur in each branch, like `{if (x) ...[1] else [1, 2]}`.
      if (conditionValue) {
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
      var value = verifier._evaluateAndReportError(
        element.expression,
        diagnosticCode,
      );
      if (value is! DartObjectImpl) return false;

      if (listElementType != null || setConfig != null) {
        return _validateListOrSetSpread(element, value);
      }

      var mapConfig = this.mapConfig;
      if (mapConfig != null) {
        return _validateMapSpread(mapConfig, element, value);
      }

      return true;
    } else if (element is NullAwareElement) {
      var value = verifier._evaluateAndReportError(
        element.value,
        diagnosticCode,
      );
      if (value is! DartObjectImpl) return false;

      var listElementType = this.listElementType;
      if (listElementType != null) {
        return _validateListExpression(
          verifier._typeSystem.makeNullable(listElementType),
          element.value,
          value,
        );
      }

      // If the value is `null`, skip verifying it with the set, as it won't be
      // added as an element.
      var setConfig = this.setConfig;
      if (setConfig != null && !value.type.isDartCoreNull) {
        return _validateSetExpression(setConfig, element.value, value);
      }

      return true;
    }
    throw UnsupportedError(
      'Unhandled type of collection element: ${element.runtimeType}',
    );
  }

  /// Returns whether the [node] is a potential constant.
  bool _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: verifier._currentLibrary.featureSet,
    );
    if (notPotentiallyConstants.isEmpty) return true;

    for (var notConst in notPotentiallyConstants) {
      CompileTimeErrorCode errorCode;
      if (listElementType != null) {
        errorCode = CompileTimeErrorCode.nonConstantListElement;
      } else if (mapConfig != null) {
        errorCode = CompileTimeErrorCode.nonConstantMapElement;
        for (
          AstNode? parent = notConst;
          parent != null;
          parent = parent.parent
        ) {
          if (parent is MapLiteralEntry) {
            if (parent.key == notConst) {
              errorCode = CompileTimeErrorCode.nonConstantMapKey;
            } else {
              errorCode = CompileTimeErrorCode.nonConstantMapValue;
            }
            break;
          }
        }
      } else if (setConfig != null) {
        errorCode = CompileTimeErrorCode.nonConstantSetElement;
      } else {
        throw UnimplementedError();
      }
      verifier._diagnosticReporter.atNode(notConst, errorCode);
    }

    return false;
  }

  bool _validateListExpression(
    TypeImpl listElementType,
    Expression expression,
    DartObjectImpl value,
  ) {
    if (!verifier._runtimeTypeMatch(value, listElementType)) {
      if (verifier._runtimeTypeMatch(
        value,
        verifier._typeSystem.makeNullable(listElementType),
      )) {
        verifier._diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.listElementTypeNotAssignableNullability,
          arguments: [value.type, listElementType],
        );
      } else {
        verifier._diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.listElementTypeNotAssignable,
          arguments: [value.type, listElementType],
        );
      }
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
      verifier._diagnosticReporter.atNode(
        element.expression,
        CompileTimeErrorCode.constSpreadExpectedListOrSet,
      );
      return false;
    }

    var setConfig = this.setConfig;
    if (setConfig == null) {
      return true;
    }

    if (listValue != null) {
      var featureSet = verifier._currentLibrary.featureSet;
      if (!listValue.every((e) => e.hasPrimitiveEquality(featureSet))) {
        verifier._diagnosticReporter.atNode(
          element,
          CompileTimeErrorCode.constSetElementNotPrimitiveEquality,
          arguments: [value.type],
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

    var isKeyNullAware = entry.keyQuestion != null;
    var isValueNullAware = entry.valueQuestion != null;

    var keyValue = verifier._evaluateAndReportError(
      keyExpression,
      CompileTimeErrorCode.nonConstantMapKey,
    );
    var valueValue = verifier._evaluateAndReportError(
      valueExpression,
      CompileTimeErrorCode.nonConstantMapValue,
    );

    if (keyValue is DartObjectImpl) {
      var keyType = keyValue.type;
      var expectedKeyType = config.keyType;
      if (isKeyNullAware) {
        expectedKeyType = verifier._typeSystem.makeNullable(expectedKeyType);
      }

      if (!verifier._runtimeTypeMatch(keyValue, expectedKeyType)) {
        if (!isKeyNullAware &&
            verifier._runtimeTypeMatch(
              keyValue,
              verifier._typeSystem.makeNullable(expectedKeyType),
            )) {
          verifier._diagnosticReporter.atNode(
            keyExpression,
            CompileTimeErrorCode.mapKeyTypeNotAssignableNullability,
            arguments: [keyType, expectedKeyType],
          );
        } else {
          verifier._diagnosticReporter.atNode(
            keyExpression,
            CompileTimeErrorCode.mapKeyTypeNotAssignable,
            arguments: [keyType, expectedKeyType],
          );
        }
      }

      var featureSet = verifier._currentLibrary.featureSet;
      if (!keyValue.hasPrimitiveEquality(featureSet)) {
        verifier._diagnosticReporter.atNode(
          keyExpression,
          CompileTimeErrorCode.constMapKeyNotPrimitiveEquality,
          arguments: [keyType],
        );
      }

      // Don't check the key for uniqueness if the key is null aware and is
      // `null` or the value is null aware and is `null`, since it won't be
      // added to the map in that case.
      if ((!isKeyNullAware || !keyValue.type.isDartCoreNull) &&
          (!isValueNullAware ||
              valueValue is DartObjectImpl &&
                  !valueValue.type.isDartCoreNull)) {
        var existingKey = config.uniqueKeys[keyValue];
        if (existingKey != null) {
          config.duplicateKeys[keyExpression] = existingKey;
        } else {
          config.uniqueKeys[keyValue] = keyExpression;
        }
      }
    }

    var expectedValueType = config.valueType;
    if (isValueNullAware) {
      expectedValueType = verifier._typeSystem.makeNullable(expectedValueType);
    }
    if (valueValue is DartObjectImpl) {
      if (!verifier._runtimeTypeMatch(valueValue, expectedValueType)) {
        if (!isValueNullAware &&
            verifier._runtimeTypeMatch(
              valueValue,
              verifier._typeSystem.makeNullable(expectedValueType),
            )) {
          verifier._diagnosticReporter.atNode(
            valueExpression,
            CompileTimeErrorCode.mapValueTypeNotAssignableNullability,
            arguments: [valueValue.type, expectedValueType],
          );
        } else {
          verifier._diagnosticReporter.atNode(
            valueExpression,
            CompileTimeErrorCode.mapValueTypeNotAssignable,
            arguments: [valueValue.type, expectedValueType],
          );
        }
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
      // TODO(brianwilkerson): Figure out how to improve the error messages. They
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
    verifier._diagnosticReporter.atNode(
      element.expression,
      CompileTimeErrorCode.constSpreadExpectedMap,
    );
    return false;
  }

  bool _validateSetExpression(
    _SetVerifierConfig config,
    Expression expression,
    DartObjectImpl value,
  ) {
    if (!verifier._runtimeTypeMatch(value, config.elementType)) {
      if (verifier._runtimeTypeMatch(
        value,
        verifier._typeSystem.makeNullable(config.elementType),
      )) {
        verifier._diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.setElementTypeNotAssignableNullability,
          arguments: [value.type, config.elementType],
        );
      } else {
        verifier._diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.setElementTypeNotAssignable,
          arguments: [value.type, config.elementType],
        );
      }
      return false;
    }

    var featureSet = verifier._currentLibrary.featureSet;
    if (!value.hasPrimitiveEquality(featureSet)) {
      verifier._diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.constSetElementNotPrimitiveEquality,
        arguments: [value.type],
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
  final TypeImpl keyType;
  final TypeImpl valueType;
  final Map<DartObject, Expression> uniqueKeys = {};
  final Map<Expression, Expression> duplicateKeys = {};

  _MapVerifierConfig({required this.keyType, required this.valueType});
}

class _SetVerifierConfig {
  final TypeImpl elementType;
  final Map<DartObject, Expression> uniqueValues = {};
  final Map<Expression, Expression> duplicateElements = {};

  _SetVerifierConfig({required this.elementType});
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
              var enclosingClass = container.declaredFragment!.element;
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

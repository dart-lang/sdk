// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, RecordingErrorListener;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/type_system.dart'
    show Dart2TypeSystem, TypeSystem;
import 'package:analyzer/src/task/api/model.dart';

/**
 * Helper class encapsulating the methods for evaluating constants and
 * constant instance creation expressions.
 */
class ConstantEvaluationEngine {
  /**
   * Parameter to "fromEnvironment" methods that denotes the default value.
   */
  static String _DEFAULT_VALUE_PARAM = "defaultValue";

  /**
   * Source of RegExp matching declarable operator names.
   * From sdk/lib/internal/symbol.dart.
   */
  static String _OPERATOR_RE =
      "(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)";

  /**
   * Source of RegExp matching Dart reserved words.
   * From sdk/lib/internal/symbol.dart.
   */
  static String _RESERVED_WORD_RE =
      "(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|"
      "d(?:efault|o)|e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|"
      "i[fns]|n(?:ew|ull)|ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|"
      "r(?:ue|y))|v(?:ar|oid)|w(?:hile|ith))";

  /**
   * Source of RegExp matching any public identifier.
   * From sdk/lib/internal/symbol.dart.
   */
  static String _PUBLIC_IDENTIFIER_RE =
      "(?!$_RESERVED_WORD_RE\\b(?!\\\$))[a-zA-Z\$][\\w\$]*";

  /**
   * RegExp that validates a non-empty non-private symbol.
   * From sdk/lib/internal/symbol.dart.
   */
  static RegExp _PUBLIC_SYMBOL_PATTERN = new RegExp(
      "^(?:$_OPERATOR_RE\$|$_PUBLIC_IDENTIFIER_RE(?:=?\$|[.](?!\$)))+?\$");

  /**
   * The type provider used to access the known types.
   */
  final TypeProvider typeProvider;

  /**
   * The type system.  This is used to guess the types of constants when their
   * exact value is unknown.
   */
  final TypeSystem typeSystem;

  /**
   * The set of variables declared on the command line using '-D'.
   */
  final DeclaredVariables _declaredVariables;

  /**
   * Return the object representing the state of active experiments.
   */
  final ExperimentStatus experimentStatus;

  /**
   * Validator used to verify correct dependency analysis when running unit
   * tests.
   */
  final ConstantEvaluationValidator validator;

  /**
   * Whether this engine is used inside Analysis Driver.
   */
  final bool forAnalysisDriver;

  /**
   * Initialize a newly created [ConstantEvaluationEngine].  The [typeProvider]
   * is used to access known types.  [_declaredVariables] is the set of
   * variables declared on the command line using '-D'.  The [validator], if
   * given, is used to verify correct dependency analysis when running unit
   * tests.
   */
  ConstantEvaluationEngine(TypeProvider typeProvider, this._declaredVariables,
      {ConstantEvaluationValidator validator,
      ExperimentStatus experimentStatus,
      TypeSystem typeSystem,
      this.forAnalysisDriver: false})
      : typeProvider = typeProvider,
        validator =
            validator ?? new ConstantEvaluationValidator_ForProduction(),
        typeSystem = typeSystem ?? new Dart2TypeSystem(typeProvider),
        experimentStatus = experimentStatus ?? new ExperimentStatus();

  /**
   * Check that the arguments to a call to fromEnvironment() are correct. The
   * [arguments] are the AST nodes of the arguments. The [argumentValues] are
   * the values of the unnamed arguments. The [namedArgumentValues] are the
   * values of the named arguments. The [expectedDefaultValueType] is the
   * allowed type of the "defaultValue" parameter (if present). Note:
   * "defaultValue" is always allowed to be null. Return `true` if the arguments
   * are correct, `false` if there is an error.
   */
  bool checkFromEnvironmentArguments(
      NodeList<Expression> arguments,
      List<DartObjectImpl> argumentValues,
      Map<String, DartObjectImpl> namedArgumentValues,
      InterfaceType expectedDefaultValueType) {
    int argumentCount = arguments.length;
    if (argumentCount < 1 || argumentCount > 2) {
      return false;
    }
    if (arguments[0] is NamedExpression) {
      return false;
    }
    if (!identical(argumentValues[0].type, typeProvider.stringType)) {
      return false;
    }
    if (argumentCount == 2) {
      Expression secondArgument = arguments[1];
      if (secondArgument is NamedExpression) {
        if (!(secondArgument.name.label.name == _DEFAULT_VALUE_PARAM)) {
          return false;
        }
        ParameterizedType defaultValueType =
            namedArgumentValues[_DEFAULT_VALUE_PARAM].type;
        if (!(identical(defaultValueType, expectedDefaultValueType) ||
            identical(defaultValueType, typeProvider.nullType))) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  /**
   * Check that the arguments to a call to Symbol() are correct. The [arguments]
   * are the AST nodes of the arguments. The [argumentValues] are the values of
   * the unnamed arguments. The [namedArgumentValues] are the values of the
   * named arguments. Return `true` if the arguments are correct, `false` if
   * there is an error.
   */
  bool checkSymbolArguments(
      NodeList<Expression> arguments,
      List<DartObjectImpl> argumentValues,
      Map<String, DartObjectImpl> namedArgumentValues) {
    if (arguments.length != 1) {
      return false;
    }
    if (arguments[0] is NamedExpression) {
      return false;
    }
    if (!identical(argumentValues[0].type, typeProvider.stringType)) {
      return false;
    }
    String name = argumentValues[0].toStringValue();
    return isValidPublicSymbol(name);
  }

  /**
   * Compute the constant value associated with the given [constant].
   */
  void computeConstantValue(ConstantEvaluationTarget constant) {
    validator.beforeComputeValue(constant);
    if (constant is ParameterElementImpl) {
      if (constant.isOptional) {
        Expression defaultValue = constant.constantInitializer;
        if (defaultValue != null) {
          RecordingErrorListener errorListener = new RecordingErrorListener();
          ErrorReporter errorReporter =
              new ErrorReporter(errorListener, constant.source);
          DartObjectImpl dartObject =
              defaultValue.accept(new ConstantVisitor(this, errorReporter));
          constant.evaluationResult =
              new EvaluationResultImpl(dartObject, errorListener.errors);
        } else {
          constant.evaluationResult =
              EvaluationResultImpl(typeProvider.nullObject);
        }
      }
    } else if (constant is VariableElementImpl) {
      Expression constantInitializer = constant.constantInitializer;
      if (constantInitializer != null) {
        RecordingErrorListener errorListener = new RecordingErrorListener();
        ErrorReporter errorReporter =
            new ErrorReporter(errorListener, constant.source);
        DartObjectImpl dartObject = constantInitializer
            .accept(new ConstantVisitor(this, errorReporter));
        // Only check the type for truly const declarations (don't check final
        // fields with initializers, since their types may be generic.  The type
        // of the final field will be checked later, when the constructor is
        // invoked).
        if (dartObject != null && constant.isConst) {
          if (!runtimeTypeMatch(dartObject, constant.type)) {
            errorReporter.reportErrorForElement(
                CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
                constant,
                [dartObject.type, constant.type]);
          }
        }
        constant.evaluationResult =
            new EvaluationResultImpl(dartObject, errorListener.errors);
      }
    } else if (constant is ConstructorElementImpl) {
      if (constant.isConst) {
        // No evaluation needs to be done; constructor declarations are only in
        // the dependency graph to ensure that any constants referred to in
        // initializer lists and parameter defaults are evaluated before
        // invocations of the constructor.
        constant.isConstantEvaluated = true;
      }
    } else if (constant is ElementAnnotationImpl) {
      Annotation constNode = constant.annotationAst;
      Element element = constant.element;
      if (element is PropertyAccessorElement &&
          element.variable is VariableElementImpl) {
        // The annotation is a reference to a compile-time constant variable.
        // Just copy the evaluation result.
        VariableElementImpl variableElement =
            element.variable as VariableElementImpl;
        if (variableElement.evaluationResult != null) {
          constant.evaluationResult = variableElement.evaluationResult;
        } else {
          // This could happen in the event that the annotation refers to a
          // non-constant.  The error is detected elsewhere, so just silently
          // ignore it here.
          constant.evaluationResult = new EvaluationResultImpl(null);
        }
      } else if (element is ConstructorElement &&
          element.isConst &&
          constNode.arguments != null) {
        RecordingErrorListener errorListener = new RecordingErrorListener();
        ErrorReporter errorReporter =
            new ErrorReporter(errorListener, constant.source);
        ConstantVisitor constantVisitor =
            new ConstantVisitor(this, errorReporter);
        DartObjectImpl result = evaluateConstructorCall(
            constNode,
            constNode.arguments.arguments,
            element,
            constantVisitor,
            errorReporter);
        constant.evaluationResult =
            new EvaluationResultImpl(result, errorListener.errors);
      } else {
        // This may happen for invalid code (e.g. failing to pass arguments
        // to an annotation which references a const constructor).  The error
        // is detected elsewhere, so just silently ignore it here.
        constant.evaluationResult = new EvaluationResultImpl(null);
      }
    } else if (constant is VariableElement) {
      // constant is a VariableElement but not a VariableElementImpl.  This can
      // happen sometimes in the case of invalid user code (for example, a
      // constant expression that refers to a non-static field inside a generic
      // class will wind up referring to a FieldMember).  The error is detected
      // elsewhere, so just silently ignore it here.
    } else {
      // Should not happen.
      assert(false);
      AnalysisEngine.instance.logger.logError(
          "Constant value computer trying to compute the value of a node of type ${constant.runtimeType}");
      return;
    }
  }

  /**
   * Determine which constant elements need to have their values computed
   * prior to computing the value of [constant], and report them using
   * [callback].
   */
  void computeDependencies(
      ConstantEvaluationTarget constant, ReferenceFinderCallback callback) {
    ReferenceFinder referenceFinder = new ReferenceFinder(callback);
    if (constant is ConstructorElement) {
      constant = getConstructorImpl(constant);
    }
    if (constant is VariableElementImpl) {
      Expression initializer = constant.constantInitializer;
      if (initializer != null) {
        initializer.accept(referenceFinder);
      }
    } else if (constant is ConstructorElementImpl) {
      if (constant.isConst) {
        ConstructorElement redirectedConstructor =
            getConstRedirectedConstructor(constant);
        if (redirectedConstructor != null) {
          ConstructorElement redirectedConstructorBase =
              getConstructorImpl(redirectedConstructor);
          callback(redirectedConstructorBase);
          return;
        } else if (constant.isFactory) {
          // Factory constructor, but getConstRedirectedConstructor returned
          // null.  This can happen if we're visiting one of the special external
          // const factory constructors in the SDK, or if the code contains
          // errors (such as delegating to a non-const constructor, or delegating
          // to a constructor that can't be resolved).  In any of these cases,
          // we'll evaluate calls to this constructor without having to refer to
          // any other constants.  So we don't need to report any dependencies.
          return;
        }
        bool defaultSuperInvocationNeeded = true;
        List<ConstructorInitializer> initializers =
            constant.constantInitializers;
        if (initializers != null) {
          for (ConstructorInitializer initializer in initializers) {
            if (initializer is SuperConstructorInvocation ||
                initializer is RedirectingConstructorInvocation) {
              defaultSuperInvocationNeeded = false;
            }
            initializer.accept(referenceFinder);
          }
        }
        if (defaultSuperInvocationNeeded) {
          // No explicit superconstructor invocation found, so we need to
          // manually insert a reference to the implicit superconstructor.
          InterfaceType superclass =
              (constant.returnType as InterfaceType).superclass;
          if (superclass != null && !superclass.isObject) {
            ConstructorElement unnamedConstructor =
                getConstructorImpl(superclass.element.unnamedConstructor);
            if (unnamedConstructor != null) {
              callback(unnamedConstructor);
            }
          }
        }
        for (FieldElement field in constant.enclosingElement.fields) {
          // Note: non-static const isn't allowed but we handle it anyway so
          // that we won't be confused by incorrect code.
          if ((field.isFinal || field.isConst) &&
              !field.isStatic &&
              field.initializer != null) {
            callback(field);
          }
        }
        for (ParameterElement parameterElement in constant.parameters) {
          callback(parameterElement);
        }
      }
    } else if (constant is ElementAnnotationImpl) {
      Annotation constNode = constant.annotationAst;
      Element element = constant.element;
      if (element is PropertyAccessorElement &&
          element.variable is VariableElementImpl) {
        // The annotation is a reference to a compile-time constant variable,
        // so it depends on the variable.
        callback(element.variable);
      } else if (element is ConstructorElementImpl) {
        // The annotation is a constructor invocation, so it depends on the
        // constructor.
        callback(element);
      } else {
        // This could happen in the event of invalid code.  The error will be
        // reported at constant evaluation time.
      }
      if (constNode == null) {
        // We cannot determine what element the annotation is on, nor the offset
        // of the annotation, so there's not a lot of information in this
        // message, but it's better than getting an exception.
        // https://github.com/dart-lang/sdk/issues/26811
        AnalysisEngine.instance.logger.logInformation(
            'No annotationAst for $constant in ${constant.compilationUnit}');
      } else if (constNode.arguments != null) {
        constNode.arguments.accept(referenceFinder);
      }
    } else if (constant is VariableElement) {
      // constant is a VariableElement but not a VariableElementImpl.  This can
      // happen sometimes in the case of invalid user code (for example, a
      // constant expression that refers to a non-static field inside a generic
      // class will wind up referring to a FieldMember).  So just don't bother
      // computing any dependencies.
    } else {
      // Should not happen.
      assert(false);
      AnalysisEngine.instance.logger.logError(
          "Constant value computer trying to compute the value of a node of type ${constant.runtimeType}");
    }
  }

  /**
   * Evaluate a call to fromEnvironment() on the bool, int, or String class. The
   * [environmentValue] is the value fetched from the environment. The
   * [builtInDefaultValue] is the value that should be used as the default if no
   * "defaultValue" argument appears in [namedArgumentValues]. The
   * [namedArgumentValues] are the values of the named parameters passed to
   * fromEnvironment(). Return a [DartObjectImpl] object corresponding to the
   * evaluated result.
   */
  DartObjectImpl computeValueFromEnvironment(
      DartObject environmentValue,
      DartObjectImpl builtInDefaultValue,
      Map<String, DartObjectImpl> namedArgumentValues) {
    DartObjectImpl value = environmentValue as DartObjectImpl;
    if (value.isUnknown || value.isNull) {
      // The name either doesn't exist in the environment or we couldn't parse
      // the corresponding value.
      // If the code supplied an explicit default, use it.
      if (namedArgumentValues.containsKey(_DEFAULT_VALUE_PARAM)) {
        value = namedArgumentValues[_DEFAULT_VALUE_PARAM];
      } else if (value.isNull) {
        // The code didn't supply an explicit default.
        // The name exists in the environment but we couldn't parse the
        // corresponding value.
        // So use the built-in default value, because this is what the VM does.
        value = builtInDefaultValue;
      } else {
        // The code didn't supply an explicit default.
        // The name doesn't exist in the environment.
        // The VM would use the built-in default value, but we don't want to do
        // that for analysis because it's likely to lead to cascading errors.
        // So just leave [value] in the unknown state.
      }
    }
    return value;
  }

  DartObjectImpl evaluateConstructorCall(
      AstNode node,
      List<Expression> arguments,
      ConstructorElement constructor,
      ConstantVisitor constantVisitor,
      ErrorReporter errorReporter,
      {ConstructorInvocation invocation}) {
    if (!constructor.isConst) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_NON_CONST, node);
      return null;
    }

    if (!getConstructorImpl(constructor).isCycleFree) {
      // It's not safe to evaluate this constructor, so bail out.
      // TODO(paulberry): ensure that a reasonable error message is produced
      // in this case, as well as other cases involving constant expression
      // circularities (e.g. "compile-time constant expression depends on
      // itself")
      return new DartObjectImpl.validWithUnknownValue(constructor.returnType);
    }

    int argumentCount = arguments.length;
    var argumentValues = new List<DartObjectImpl>(argumentCount);
    Map<String, NamedExpression> namedNodes;
    Map<String, DartObjectImpl> namedValues;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        namedNodes ??= new HashMap<String, NamedExpression>();
        namedValues ??= new HashMap<String, DartObjectImpl>();
        String name = argument.name.label.name;
        namedNodes[name] = argument;
        namedValues[name] = constantVisitor._valueOf(argument.expression);
      } else {
        var argumentValue = constantVisitor._valueOf(argument);
        argumentValues[i] = argumentValue;
      }
    }
    namedNodes ??= const {};
    namedValues ??= const {};

    if (invocation == null) {
      invocation = new ConstructorInvocation(
        constructor,
        argumentValues,
        namedValues,
      );
    }

    constructor = followConstantRedirectionChain(constructor);
    InterfaceType definingClass = constructor.returnType as InterfaceType;
    if (constructor.isFactory) {
      // We couldn't find a non-factory constructor.
      // See if it's because we reached an external const factory constructor
      // that we can emulate.
      if (constructor.name == "fromEnvironment") {
        if (!checkFromEnvironmentArguments(
            arguments, argumentValues, namedValues, definingClass)) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          return null;
        }
        String variableName =
            argumentCount < 1 ? null : argumentValues[0].toStringValue();
        if (definingClass == typeProvider.boolType) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getBool(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE),
              namedValues);
        } else if (definingClass == typeProvider.intType) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getInt(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE),
              namedValues);
        } else if (definingClass == typeProvider.stringType) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getString(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE),
              namedValues);
        }
      } else if (constructor.name == "" &&
          definingClass == typeProvider.symbolType &&
          argumentCount == 1) {
        if (!checkSymbolArguments(arguments, argumentValues, namedValues)) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          return null;
        }
        String argumentValue = argumentValues[0].toStringValue();
        return new DartObjectImpl(
            definingClass, new SymbolState(argumentValue));
      }
      // Either it's an external const factory constructor that we can't
      // emulate, or an error occurred (a cycle, or a const constructor trying
      // to delegate to a non-const constructor).
      // In the former case, the best we can do is consider it an unknown value.
      // In the latter case, the error has already been reported, so considering
      // it an unknown value will suppress further errors.
      return new DartObjectImpl.validWithUnknownValue(definingClass);
    }
    ConstructorElementImpl constructorBase = getConstructorImpl(constructor);
    validator.beforeGetConstantInitializers(constructorBase);
    List<ConstructorInitializer> initializers =
        constructorBase.constantInitializers;
    if (initializers == null) {
      // This can happen in some cases where there are compile errors in the
      // code being analyzed (for example if the code is trying to create a
      // const instance using a non-const constructor, or the node we're
      // visiting is involved in a cycle).  The error has already been reported,
      // so consider it an unknown value to suppress further errors.
      return new DartObjectImpl.validWithUnknownValue(definingClass);
    }

    var fieldMap = new HashMap<String, DartObjectImpl>();

    // The errors reported while computing values for field initializers, or
    // default values for the constructor parameters, cannot be reported
    // into the current ErrorReporter, because they usually happen in a
    // different source. But they still should cause a constant evaluation
    // error for the current node.
    var externalErrorListener = new BooleanErrorListener();
    var externalErrorReporter =
        new ErrorReporter(externalErrorListener, constructor.source);

    // Start with final fields that are initialized at their declaration site.
    List<FieldElement> fields = constructor.enclosingElement.fields;
    for (int i = 0; i < fields.length; i++) {
      FieldElement field = fields[i];
      if ((field.isFinal || field.isConst) &&
          !field.isStatic &&
          field is ConstFieldElementImpl) {
        validator.beforeGetFieldEvaluationResult(field);

        DartObjectImpl fieldValue = field.evaluationResult?.value;

        // It is possible that the evaluation result is null.
        // This happens for example when we have duplicate fields.
        // class Test {final x = 1; final x = 2; const Test();}
        if (fieldValue == null) {
          continue;
        }
        // Match the value and the type.
        DartType fieldType =
            FieldMember.from(field, constructor.returnType).type;
        if (fieldValue != null && !runtimeTypeMatch(fieldValue, fieldType)) {
          errorReporter.reportErrorForNode(
              CheckedModeCompileTimeErrorCode
                  .CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
              node,
              [fieldValue.type, field.name, fieldType]);
        }
        fieldMap[field.name] = fieldValue;
      }
    }
    // Now evaluate the constructor declaration.
    Map<String, DartObjectImpl> parameterMap =
        new HashMap<String, DartObjectImpl>();
    List<ParameterElement> parameters = constructor.parameters;
    int parameterCount = parameters.length;

    for (int i = 0; i < parameterCount; i++) {
      ParameterElement parameter = parameters[i];
      ParameterElement baseParameter = parameter;
      while (baseParameter is ParameterMember) {
        baseParameter = (baseParameter as ParameterMember).baseElement;
      }
      DartObjectImpl argumentValue = null;
      AstNode errorTarget = null;
      if (baseParameter.isNamed) {
        argumentValue = namedValues[baseParameter.name];
        errorTarget = namedNodes[baseParameter.name];
      } else if (i < argumentCount) {
        argumentValue = argumentValues[i];
        errorTarget = arguments[i];
      }
      if (errorTarget == null) {
        // No argument node that we can direct error messages to, because we
        // are handling an optional parameter that wasn't specified.  So just
        // direct error messages to the constructor call.
        errorTarget = node;
      }
      if (argumentValue == null && baseParameter is ParameterElementImpl) {
        // The parameter is an optional positional parameter for which no value
        // was provided, so use the default value.
        validator.beforeGetParameterDefault(baseParameter);

        EvaluationResultImpl evaluationResult = baseParameter.evaluationResult;
        if (evaluationResult == null) {
          // No default was provided, so the default value is null.
          argumentValue = typeProvider.nullObject;
        } else if (evaluationResult.value != null) {
          argumentValue = evaluationResult.value;
        }
      }
      if (argumentValue != null) {
        if (!runtimeTypeMatch(argumentValue, parameter.type)) {
          errorReporter.reportErrorForNode(
              CheckedModeCompileTimeErrorCode
                  .CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
              errorTarget,
              [argumentValue.type, parameter.type]);
        }
        if (baseParameter.isInitializingFormal) {
          FieldElement field = (parameter as FieldFormalParameterElement).field;
          if (field != null) {
            DartType fieldType = field.type;
            if (fieldType != parameter.type) {
              // We've already checked that the argument can be assigned to the
              // parameter; we also need to check that it can be assigned to
              // the field.
              if (!runtimeTypeMatch(argumentValue, fieldType)) {
                errorReporter.reportErrorForNode(
                    CheckedModeCompileTimeErrorCode
                        .CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
                    errorTarget,
                    [argumentValue.type, fieldType]);
              }
            }
            String fieldName = field.name;
            if (fieldMap.containsKey(fieldName)) {
              errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
            }
            fieldMap[fieldName] = argumentValue;
          }
        }
        String name = baseParameter.name;
        parameterMap[name] = argumentValue;
      }
    }
    ConstantVisitor initializerVisitor = new ConstantVisitor(
        this, externalErrorReporter,
        lexicalEnvironment: parameterMap);
    String superName = null;
    NodeList<Expression> superArguments = null;
    for (var i = 0; i < initializers.length; i++) {
      var initializer = initializers[i];
      if (initializer is ConstructorFieldInitializer) {
        Expression initializerExpression = initializer.expression;
        DartObjectImpl evaluationResult =
            initializerExpression?.accept(initializerVisitor);
        if (evaluationResult != null) {
          String fieldName = initializer.fieldName.name;
          if (fieldMap.containsKey(fieldName)) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          }
          fieldMap[fieldName] = evaluationResult;
          PropertyAccessorElement getter = definingClass.getGetter(fieldName);
          if (getter != null) {
            PropertyInducingElement field = getter.variable;
            if (!runtimeTypeMatch(evaluationResult, field.type)) {
              errorReporter.reportErrorForNode(
                  CheckedModeCompileTimeErrorCode
                      .CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
                  node,
                  [evaluationResult.type, fieldName, field.type]);
            }
          }
        } else {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
        }
      } else if (initializer is SuperConstructorInvocation) {
        SimpleIdentifier name = initializer.constructorName;
        if (name != null) {
          superName = name.name;
        }
        superArguments = initializer.argumentList.arguments;
      } else if (initializer is RedirectingConstructorInvocation) {
        // This is a redirecting constructor, so just evaluate the constructor
        // it redirects to.
        ConstructorElement constructor = initializer.staticElement;
        if (constructor != null && constructor.isConst) {
          // Instantiate the constructor with the in-scope type arguments.
          constructor = ConstructorMember.from(constructor, definingClass);

          DartObjectImpl result = evaluateConstructorCall(
              node,
              initializer.argumentList.arguments,
              constructor,
              initializerVisitor,
              externalErrorReporter,
              invocation: invocation);
          if (externalErrorListener.errorReported) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          }
          return result;
        }
      } else if (initializer is AssertInitializer) {
        Expression condition = initializer.condition;
        if (condition == null) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
        }
        DartObjectImpl evaluationResult = condition.accept(initializerVisitor);
        if (evaluationResult == null ||
            !evaluationResult.isBool ||
            evaluationResult.toBoolValue() != true) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          return null;
        }
      }
    }
    // Evaluate explicit or implicit call to super().
    InterfaceType superclass = definingClass.superclass;
    if (superclass != null && !superclass.isObject) {
      ConstructorElement superConstructor =
          superclass.lookUpConstructor(superName, constructor.library);
      if (superConstructor != null) {
        if (superArguments == null) {
          superArguments = astFactory.nodeList<Expression>(null);
        }

        evaluateSuperConstructorCall(node, fieldMap, superConstructor,
            superArguments, initializerVisitor, externalErrorReporter);
      }
    }
    if (externalErrorListener.errorReported) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
    }
    return new DartObjectImpl(
        definingClass, new GenericState(fieldMap, invocation: invocation));
  }

  void evaluateSuperConstructorCall(
      AstNode node,
      Map<String, DartObjectImpl> fieldMap,
      ConstructorElement superConstructor,
      List<Expression> superArguments,
      ConstantVisitor initializerVisitor,
      ErrorReporter errorReporter) {
    if (superConstructor != null && superConstructor.isConst) {
      DartObjectImpl evaluationResult = evaluateConstructorCall(node,
          superArguments, superConstructor, initializerVisitor, errorReporter);
      if (evaluationResult != null) {
        fieldMap[GenericState.SUPERCLASS_FIELD] = evaluationResult;
      }
    }
  }

  /**
   * Attempt to follow the chain of factory redirections until a constructor is
   * reached which is not a const factory constructor. Return the constant
   * constructor which terminates the chain of factory redirections, if the
   * chain terminates. If there is a problem (e.g. a redirection can't be found,
   * or a cycle is encountered), the chain will be followed as far as possible
   * and then a const factory constructor will be returned.
   */
  ConstructorElement followConstantRedirectionChain(
      ConstructorElement constructor) {
    HashSet<ConstructorElement> constructorsVisited =
        new HashSet<ConstructorElement>();
    while (true) {
      ConstructorElement redirectedConstructor =
          getConstRedirectedConstructor(constructor);
      if (redirectedConstructor == null) {
        break;
      } else {
        ConstructorElement constructorBase = getConstructorImpl(constructor);
        constructorsVisited.add(constructorBase);
        ConstructorElement redirectedConstructorBase =
            getConstructorImpl(redirectedConstructor);
        if (constructorsVisited.contains(redirectedConstructorBase)) {
          // Cycle in redirecting factory constructors--this is not allowed
          // and is checked elsewhere--see
          // [ErrorVerifier.checkForRecursiveFactoryRedirect()]).
          break;
        }
      }
      constructor = redirectedConstructor;
    }
    return constructor;
  }

  /**
   * Generate an error indicating that the given [constant] is not a valid
   * compile-time constant because it references at least one of the constants
   * in the given [cycle], each of which directly or indirectly references the
   * constant.
   */
  void generateCycleError(Iterable<ConstantEvaluationTarget> cycle,
      ConstantEvaluationTarget constant) {
    if (constant is VariableElement) {
      RecordingErrorListener errorListener = new RecordingErrorListener();
      ErrorReporter errorReporter =
          new ErrorReporter(errorListener, constant.source);
      // TODO(paulberry): It would be really nice if we could extract enough
      // information from the 'cycle' argument to provide the user with a
      // description of the cycle.
      errorReporter.reportErrorForElement(
          CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, constant, []);
      (constant as VariableElementImpl).evaluationResult =
          new EvaluationResultImpl(null, errorListener.errors);
    } else if (constant is ConstructorElement) {
      // We don't report cycle errors on constructor declarations since there
      // is nowhere to put the error information.
    } else {
      // Should not happen.  Formal parameter defaults and annotations should
      // never appear as part of a cycle because they can't be referred to.
      assert(false);
      AnalysisEngine.instance.logger.logError(
          "Constant value computer trying to report a cycle error for a node of type ${constant.runtimeType}");
    }
  }

  /**
   * If [constructor] redirects to another const constructor, return the
   * const constructor it redirects to.  Otherwise return `null`.
   */
  ConstructorElement getConstRedirectedConstructor(
      ConstructorElement constructor) {
    if (!constructor.isFactory) {
      return null;
    }
    if (identical(constructor.enclosingElement.type, typeProvider.symbolType)) {
      // The dart:core.Symbol has a const factory constructor that redirects
      // to dart:_internal.Symbol.  That in turn redirects to an external
      // const constructor, which we won't be able to evaluate.
      // So stop following the chain of redirections at dart:core.Symbol, and
      // let [evaluateInstanceCreationExpression] handle it specially.
      return null;
    }
    ConstructorElement redirectedConstructor =
        constructor.redirectedConstructor;
    if (redirectedConstructor == null) {
      // This can happen if constructor is an external factory constructor.
      return null;
    }
    if (!redirectedConstructor.isConst) {
      // Delegating to a non-const constructor--this is not allowed (and
      // is checked elsewhere--see
      // [ErrorVerifier.checkForRedirectToNonConstConstructor()]).
      return null;
    }
    return redirectedConstructor;
  }

  /**
   * Check if the object [obj] matches the type [type] according to runtime type
   * checking rules.
   */
  bool runtimeTypeMatch(DartObjectImpl obj, DartType type) {
    if (obj.isNull) {
      return true;
    }
    var objType = obj.type;
    if (objType.isDartCoreInt && type.isDartCoreDouble) {
      // Work around dartbug.com/35993 by allowing `int` to be used in a place
      // where `double` is expected.
      //
      // Note that this is not technically correct, because it allows code like
      // this:
      //   const Object x = 1;
      //   const double y = x;
      //
      // TODO(paulberry): remove this workaround once dartbug.com/33441 is
      // fixed.
      return true;
    }
    // TODO(scheglov ) Switch to using this, but not now, dartbug.com/33441
    if (typeSystem.isSubtypeOf(objType, type)) {
      return true;
    }
    return objType.isSubtypeOf(type);
  }

  /**
   * Determine whether the given string is a valid name for a public symbol
   * (i.e. whether it is allowed for a call to the Symbol constructor).
   */
  static bool isValidPublicSymbol(String name) =>
      name.isEmpty || name == "void" || _PUBLIC_SYMBOL_PATTERN.hasMatch(name);
}

/**
 * Interface for [AnalysisTarget]s for which constant evaluation can be
 * performed.
 */
abstract class ConstantEvaluationTarget extends AnalysisTarget {
  /**
   * Return the [AnalysisContext] which should be used to evaluate this
   * constant.
   */
  AnalysisContext get context;

  /**
   * Return whether this constant is evaluated.
   */
  bool get isConstantEvaluated;
}

/**
 * Interface used by unit tests to verify correct dependency analysis during
 * constant evaluation.
 */
abstract class ConstantEvaluationValidator {
  /**
   * This method is called just before computing the constant value associated
   * with [constant]. Unit tests will override this method to introduce
   * additional error checking.
   */
  void beforeComputeValue(ConstantEvaluationTarget constant);

  /**
   * This method is called just before getting the constant initializers
   * associated with the [constructor]. Unit tests will override this method to
   * introduce additional error checking.
   */
  void beforeGetConstantInitializers(ConstructorElement constructor);

  /**
   * This method is called just before retrieving an evaluation result from an
   * element. Unit tests will override it to introduce additional error
   * checking.
   */
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant);

  /**
   * This method is called just before getting the constant value of a field
   * with an initializer.  Unit tests will override this method to introduce
   * additional error checking.
   */
  void beforeGetFieldEvaluationResult(FieldElementImpl field);

  /**
   * This method is called just before getting a parameter's default value. Unit
   * tests will override this method to introduce additional error checking.
   */
  void beforeGetParameterDefault(ParameterElement parameter);
}

/**
 * Implementation of [ConstantEvaluationValidator] used in production; does no
 * validation.
 */
class ConstantEvaluationValidator_ForProduction
    implements ConstantEvaluationValidator {
  @override
  void beforeComputeValue(ConstantEvaluationTarget constant) {}

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) {}

  @override
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant) {}

  @override
  void beforeGetFieldEvaluationResult(FieldElementImpl field) {}

  @override
  void beforeGetParameterDefault(ParameterElement parameter) {}
}

/**
 * A visitor used to evaluate constant expressions to produce their compile-time
 * value.
 */
class ConstantVisitor extends UnifyingAstVisitor<DartObjectImpl> {
  /**
   * The type provider used to access the known types.
   */
  final ConstantEvaluationEngine evaluationEngine;

  final Map<String, DartObjectImpl> _lexicalEnvironment;

  /**
   * Error reporter that we use to report errors accumulated while computing the
   * constant.
   */
  final ErrorReporter _errorReporter;

  /**
   * Helper class used to compute constant values.
   */
  DartObjectComputer _dartObjectComputer;

  /**
   * Initialize a newly created constant visitor. The [evaluationEngine] is
   * used to evaluate instance creation expressions. The [lexicalEnvironment]
   * is a map containing values which should override identifiers, or `null` if
   * no overriding is necessary. The [_errorReporter] is used to report errors
   * found during evaluation.  The [validator] is used by unit tests to verify
   * correct dependency analysis.
   */
  ConstantVisitor(this.evaluationEngine, this._errorReporter,
      {Map<String, DartObjectImpl> lexicalEnvironment})
      : _lexicalEnvironment = lexicalEnvironment {
    this._dartObjectComputer =
        new DartObjectComputer(_errorReporter, evaluationEngine);
  }

  /**
   * Return the object representing the state of active experiments.
   */
  ExperimentStatus get experimentStatus => evaluationEngine.experimentStatus;

  /**
   * Convenience getter to gain access to the [evaluationEngine]'s type system.
   */
  TypeSystem get typeSystem => evaluationEngine.typeSystem;

  /**
   * Convenience getter to gain access to the [evaluationEngine]'s type
   * provider.
   */
  TypeProvider get _typeProvider => evaluationEngine.typeProvider;

  /**
   * Given a [type] that may contain free type variables, evaluate them against
   * the current lexical environment and return the substituted type.
   */
  DartType evaluateType(DartType type) {
    if (type is TypeParameterType) {
      return null;
    }
    if (type is ParameterizedType) {
      List<DartType> typeArguments;
      for (int i = 0; i < type.typeArguments.length; i++) {
        DartType ta = type.typeArguments[i];
        DartType t = evaluateType(ta);
        if (!identical(t, ta)) {
          if (typeArguments == null) {
            typeArguments = type.typeArguments.toList(growable: false);
          }
          typeArguments[i] = t;
        }
      }
      if (typeArguments == null) return type;
      return type.substitute2(typeArguments, type.typeArguments);
    }
    return type;
  }

  /**
   * Given a [type], returns the constant value that contains that type value.
   */
  DartObjectImpl typeConstant(DartType type) {
    return new DartObjectImpl(_typeProvider.typeType, new TypeState(type));
  }

  @override
  DartObjectImpl visitAdjacentStrings(AdjacentStrings node) {
    DartObjectImpl result = null;
    for (StringLiteral string in node.strings) {
      if (result == null) {
        result = string.accept(this);
      } else {
        result =
            _dartObjectComputer.concatenate(node, result, string.accept(this));
      }
    }
    return result;
  }

  @override
  DartObjectImpl visitAsExpression(AsExpression node) {
    if (experimentStatus.constant_update_2018) {
      DartObjectImpl expressionResult = node.expression.accept(this);
      DartObjectImpl typeResult = node.type.accept(this);
      return _dartObjectComputer.castToType(node, expressionResult, typeResult);
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitBinaryExpression(BinaryExpression node) {
    TokenType operatorType = node.operator.type;
    DartObjectImpl leftResult = node.leftOperand.accept(this);
    // evaluate lazy operators
    if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
      return _dartObjectComputer.lazyAnd(
          node, leftResult, () => node.rightOperand.accept(this));
    } else if (operatorType == TokenType.BAR_BAR) {
      return _dartObjectComputer.lazyOr(
          node, leftResult, () => node.rightOperand.accept(this));
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      if (experimentStatus.constant_update_2018) {
        return _dartObjectComputer.lazyQuestionQuestion(
            node, leftResult, () => node.rightOperand.accept(this));
      } else {
        return _dartObjectComputer.eagerQuestionQuestion(
            node, leftResult, node.rightOperand.accept(this));
      }
    }
    // evaluate eager operators
    DartObjectImpl rightResult = node.rightOperand.accept(this);
    if (operatorType == TokenType.AMPERSAND) {
      return _dartObjectComputer.eagerAnd(
          node, leftResult, rightResult, experimentStatus.constant_update_2018);
    } else if (operatorType == TokenType.BANG_EQ) {
      return _dartObjectComputer.notEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.BAR) {
      return _dartObjectComputer.eagerOr(
          node, leftResult, rightResult, experimentStatus.constant_update_2018);
    } else if (operatorType == TokenType.CARET) {
      return _dartObjectComputer.eagerXor(
          node, leftResult, rightResult, experimentStatus.constant_update_2018);
    } else if (operatorType == TokenType.EQ_EQ) {
      if (experimentStatus.constant_update_2018) {
        return _dartObjectComputer.lazyEqualEqual(
            node, leftResult, rightResult);
      }
      return _dartObjectComputer.equalEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT) {
      return _dartObjectComputer.greaterThan(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_EQ) {
      return _dartObjectComputer.greaterThanOrEqual(
          node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_GT) {
      return _dartObjectComputer.shiftRight(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_GT_GT) {
      return _dartObjectComputer.logicalShiftRight(
          node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT) {
      return _dartObjectComputer.lessThan(node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT_EQ) {
      return _dartObjectComputer.lessThanOrEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT_LT) {
      return _dartObjectComputer.shiftLeft(node, leftResult, rightResult);
    } else if (operatorType == TokenType.MINUS) {
      return _dartObjectComputer.minus(node, leftResult, rightResult);
    } else if (operatorType == TokenType.PERCENT) {
      return _dartObjectComputer.remainder(node, leftResult, rightResult);
    } else if (operatorType == TokenType.PLUS) {
      return _dartObjectComputer.add(node, leftResult, rightResult);
    } else if (operatorType == TokenType.STAR) {
      return _dartObjectComputer.times(node, leftResult, rightResult);
    } else if (operatorType == TokenType.SLASH) {
      return _dartObjectComputer.divide(node, leftResult, rightResult);
    } else if (operatorType == TokenType.TILDE_SLASH) {
      return _dartObjectComputer.integerDivide(node, leftResult, rightResult);
    } else {
      // TODO(brianwilkerson) Figure out which error to report.
      _error(node, null);
      return null;
    }
  }

  @override
  DartObjectImpl visitBooleanLiteral(BooleanLiteral node) =>
      new DartObjectImpl(_typeProvider.boolType, BoolState.from(node.value));

  @override
  DartObjectImpl visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    DartObjectImpl conditionResult = condition.accept(this);
    if (experimentStatus.constant_update_2018) {
      if (conditionResult == null) {
        return conditionResult;
      } else if (!conditionResult.isBool) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, condition);
        return null;
      }
      conditionResult = _dartObjectComputer.applyBooleanConversion(
          condition, conditionResult);
      if (conditionResult == null) {
        return conditionResult;
      }
      if (conditionResult.toBoolValue() == true) {
        _reportNotPotentialConstants(node.elseExpression);
        return node.thenExpression.accept(this);
      } else if (conditionResult.toBoolValue() == false) {
        _reportNotPotentialConstants(node.thenExpression);
        return node.elseExpression.accept(this);
      }
      // We used to return an object with a known type and an unknown value, but
      // we can't do that without evaluating both the 'then' and 'else'
      // expressions, and we're not suppose to do that under lazy semantics. I'm
      // not sure which failure mode is worse.
      return null;
    }
    DartObjectImpl thenResult = node.thenExpression.accept(this);
    DartObjectImpl elseResult = node.elseExpression.accept(this);
    if (conditionResult == null) {
      return conditionResult;
    } else if (!conditionResult.isBool) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, condition);
      return null;
    } else if (thenResult == null) {
      return thenResult;
    } else if (elseResult == null) {
      return elseResult;
    }
    conditionResult =
        _dartObjectComputer.applyBooleanConversion(condition, conditionResult);
    if (conditionResult == null) {
      return conditionResult;
    }
    if (conditionResult.toBoolValue() == true) {
      return thenResult;
    } else if (conditionResult.toBoolValue() == false) {
      return elseResult;
    }
    ParameterizedType thenType = thenResult.type;
    ParameterizedType elseType = elseResult.type;
    return new DartObjectImpl.validWithUnknownValue(
        typeSystem.getLeastUpperBound(thenType, elseType) as ParameterizedType);
  }

  @override
  DartObjectImpl visitDoubleLiteral(DoubleLiteral node) =>
      new DartObjectImpl(_typeProvider.doubleType, new DoubleState(node.value));

  @override
  DartObjectImpl visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    if (!node.isConst) {
      // TODO(brianwilkerson) Figure out which error to report.
      _error(node, null);
      return null;
    }
    ConstructorElement constructor = node.staticElement;
    if (constructor == null) {
      // Couldn't resolve the constructor so we can't compute a value.  No
      // problem - the error has already been reported.
      return null;
    }

    return evaluationEngine.evaluateConstructorCall(
        node, node.argumentList.arguments, constructor, this, _errorReporter);
  }

  @override
  DartObjectImpl visitIntegerLiteral(IntegerLiteral node) {
    if (node.staticType == _typeProvider.doubleType) {
      return new DartObjectImpl(
          _typeProvider.doubleType, new DoubleState(node.value?.toDouble()));
    }
    return new DartObjectImpl(_typeProvider.intType, new IntState(node.value));
  }

  @override
  DartObjectImpl visitInterpolationExpression(InterpolationExpression node) {
    DartObjectImpl result = node.expression.accept(this);
    if (result != null && !result.isBoolNumStringOrNull) {
      _error(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
      return null;
    }
    return _dartObjectComputer.performToString(node, result);
  }

  @override
  DartObjectImpl visitInterpolationString(InterpolationString node) =>
      new DartObjectImpl(_typeProvider.stringType, new StringState(node.value));

  @override
  DartObjectImpl visitIsExpression(IsExpression node) {
    if (experimentStatus.constant_update_2018) {
      DartObjectImpl expressionResult = node.expression.accept(this);
      DartObjectImpl typeResult = node.type.accept(this);
      return _dartObjectComputer.typeTest(node, expressionResult, typeResult);
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitListLiteral(ListLiteral node) {
    if (!node.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL, node);
      return null;
    }
    bool errorOccurred = false;
    List<DartObjectImpl> list = [];
    for (CollectionElement element in node.elements) {
      errorOccurred = errorOccurred | _addElementsToList(list, element);
    }
    if (errorOccurred) {
      return null;
    }
    DartType nodeType = node.staticType;
    DartType elementType =
        nodeType is InterfaceType && nodeType.typeArguments.isNotEmpty
            ? nodeType.typeArguments[0]
            : _typeProvider.dynamicType;
    InterfaceType listType = _typeProvider.listType.instantiate([elementType]);
    return new DartObjectImpl(listType, new ListState(list));
  }

  @override
  DartObjectImpl visitMethodInvocation(MethodInvocation node) {
    Element element = node.methodName.staticElement;
    if (element is FunctionElement) {
      if (element.name == "identical") {
        NodeList<Expression> arguments = node.argumentList.arguments;
        if (arguments.length == 2) {
          Element enclosingElement = element.enclosingElement;
          if (enclosingElement is CompilationUnitElement) {
            LibraryElement library = enclosingElement.library;
            if (library.isDartCore) {
              DartObjectImpl leftArgument = arguments[0].accept(this);
              DartObjectImpl rightArgument = arguments[1].accept(this);
              return _dartObjectComputer.isIdentical(
                  node, leftArgument, rightArgument);
            }
          }
        }
      }
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this);

  @override
  DartObjectImpl visitNode(AstNode node) {
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitNullLiteral(NullLiteral node) => _typeProvider.nullObject;

  @override
  DartObjectImpl visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  DartObjectImpl visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixNode = node.prefix;
    Element prefixElement = prefixNode.staticElement;
    // String.length
    if (prefixElement is! PrefixElement && prefixElement is! ClassElement) {
      DartObjectImpl prefixResult = node.prefix.accept(this);
      if (_isStringLength(prefixResult, node.identifier)) {
        return prefixResult.stringLength(_typeProvider);
      }
    }
    // importPrefix.CONST
    if (prefixElement is! PrefixElement) {
      DartObjectImpl prefixResult = prefixNode.accept(this);
      if (prefixResult == null) {
        // The error has already been reported.
        return null;
      }
    }
    // validate prefixed identifier
    return _getConstantValue(node, node.staticElement);
  }

  @override
  DartObjectImpl visitPrefixExpression(PrefixExpression node) {
    DartObjectImpl operand = node.operand.accept(this);
    if (operand != null && operand.isNull) {
      _error(node, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
      return null;
    }
    if (node.operator.type == TokenType.BANG) {
      return _dartObjectComputer.logicalNot(node, operand);
    } else if (node.operator.type == TokenType.TILDE) {
      return _dartObjectComputer.bitNot(node, operand);
    } else if (node.operator.type == TokenType.MINUS) {
      return _dartObjectComputer.negated(node, operand);
    } else {
      // TODO(brianwilkerson) Figure out which error to report.
      _error(node, null);
      return null;
    }
  }

  @override
  DartObjectImpl visitPropertyAccess(PropertyAccess node) {
    if (node.target != null) {
      DartObjectImpl prefixResult = node.target.accept(this);
      if (_isStringLength(prefixResult, node.propertyName)) {
        return prefixResult.stringLength(_typeProvider);
      }
    }
    return _getConstantValue(node, node.propertyName.staticElement);
  }

  @override
  DartObjectImpl visitSetOrMapLiteral(SetOrMapLiteral node) {
    // Note: due to dartbug.com/33441, it's possible that a set/map literal
    // resynthesized from a summary will have neither its `isSet` or `isMap`
    // boolean set to `true`.  We work around the problem by assuming such
    // literals are maps.
    // TODO(paulberry): when dartbug.com/33441 is fixed, add an assertion here
    // to verify that `node.isSet == !node.isMap`.
    bool isMap = !node.isSet;
    if (isMap) {
      if (!node.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL, node);
        return null;
      }
      bool errorOccurred = false;
      Map<DartObjectImpl, DartObjectImpl> map = {};
      for (CollectionElement element in node.elements) {
        errorOccurred = errorOccurred | _addElementsToMap(map, element);
      }
      if (errorOccurred) {
        return null;
      }
      DartType keyType = _typeProvider.dynamicType;
      DartType valueType = _typeProvider.dynamicType;
      DartType nodeType = node.staticType;
      if (nodeType is InterfaceType) {
        var typeArguments = nodeType.typeArguments;
        if (typeArguments.length >= 2) {
          keyType = typeArguments[0];
          valueType = typeArguments[1];
        }
      }
      InterfaceType mapType =
          _typeProvider.mapType.instantiate([keyType, valueType]);
      return new DartObjectImpl(mapType, new MapState(map));
    } else {
      if (!node.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL, node);
        return null;
      }
      bool errorOccurred = false;
      Set<DartObjectImpl> set = new Set<DartObjectImpl>();
      for (CollectionElement element in node.elements) {
        errorOccurred = errorOccurred | _addElementsToSet(set, element);
      }
      if (errorOccurred) {
        return null;
      }
      DartType nodeType = node.staticType;
      DartType elementType =
          nodeType is InterfaceType && nodeType.typeArguments.isNotEmpty
              ? nodeType.typeArguments[0]
              : _typeProvider.dynamicType;
      InterfaceType setType = _typeProvider.setType.instantiate([elementType]);
      return new DartObjectImpl(setType, new SetState(set));
    }
  }

  @override
  DartObjectImpl visitSimpleIdentifier(SimpleIdentifier node) {
    if (_lexicalEnvironment != null &&
        _lexicalEnvironment.containsKey(node.name)) {
      return _lexicalEnvironment[node.name];
    }
    return _getConstantValue(node, node.staticElement);
  }

  @override
  DartObjectImpl visitSimpleStringLiteral(SimpleStringLiteral node) =>
      new DartObjectImpl(_typeProvider.stringType, new StringState(node.value));

  @override
  DartObjectImpl visitStringInterpolation(StringInterpolation node) {
    DartObjectImpl result = null;
    bool first = true;
    for (InterpolationElement element in node.elements) {
      if (first) {
        result = element.accept(this);
        first = false;
      } else {
        result =
            _dartObjectComputer.concatenate(node, result, element.accept(this));
      }
    }
    return result;
  }

  @override
  DartObjectImpl visitSymbolLiteral(SymbolLiteral node) {
    StringBuffer buffer = new StringBuffer();
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        buffer.writeCharCode(0x2E);
      }
      buffer.write(components[i].lexeme);
    }
    return new DartObjectImpl(
        _typeProvider.symbolType, new SymbolState(buffer.toString()));
  }

  DartObjectImpl visitTypeAnnotation(TypeAnnotation node) {
    DartType type = evaluateType(node.type);
    if (type == null) {
      return super.visitTypeName(node);
    }
    return typeConstant(type);
  }

  @override
  DartObjectImpl visitTypeName(TypeName node) => visitTypeAnnotation(node);

  /**
   * Add the entries produced by evaluating the given collection [element] to
   * the given [list]. Return `true` if the evaluation of one or more of the
   * elements failed.
   */
  bool _addElementsToList(List<DartObject> list, CollectionElement element) {
    if (element is IfElement) {
      bool conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToList(list, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToList(list, element.elseElement);
      }
      return false;
    } else if (element is Expression) {
      DartObjectImpl value = element.accept(this);
      if (value == null) {
        return true;
      }
      list.add(value);
      return false;
    } else if (element is SpreadElement) {
      DartObjectImpl elementResult = element.expression.accept(this);
      List<DartObject> value = elementResult?.toListValue();
      if (value == null) {
        return true;
      }
      list.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /**
   * Add the entries produced by evaluating the given map [element] to the given
   * [map]. Return `true` if the evaluation of one or more of the entries
   * failed.
   */
  bool _addElementsToMap(
      Map<DartObjectImpl, DartObjectImpl> map, CollectionElement element) {
    if (element is IfElement) {
      bool conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToMap(map, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToMap(map, element.elseElement);
      }
      return false;
    } else if (element is MapLiteralEntry) {
      DartObjectImpl keyResult = element.key.accept(this);
      DartObjectImpl valueResult = element.value.accept(this);
      if (keyResult == null || valueResult == null) {
        return true;
      }
      map[keyResult] = valueResult;
      return false;
    } else if (element is SpreadElement) {
      DartObjectImpl elementResult = element.expression.accept(this);
      Map<DartObject, DartObject> value = elementResult?.toMapValue();
      if (value == null) {
        return true;
      }
      map.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /**
   * Add the entries produced by evaluating the given collection [element] to
   * the given [set]. Return `true` if the evaluation of one or more of the
   * elements failed.
   */
  bool _addElementsToSet(Set<DartObject> set, CollectionElement element) {
    if (element is IfElement) {
      bool conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToSet(set, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToSet(set, element.elseElement);
      }
      return false;
    } else if (element is Expression) {
      DartObjectImpl value = element.accept(this);
      if (value == null) {
        return true;
      }
      set.add(value);
      return false;
    } else if (element is SpreadElement) {
      DartObjectImpl elementResult = element.expression.accept(this);
      Set<DartObject> value = elementResult?.toSetValue();
      if (value == null) {
        return true;
      }
      set.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /**
   * Create an error associated with the given [node]. The error will have the
   * given error [code].
   */
  void _error(AstNode node, ErrorCode code) {
    if (code == null) {
      var parent = node?.parent;
      var parent2 = parent?.parent;
      if (parent is ArgumentList &&
          parent2 is InstanceCreationExpression &&
          parent2.isConst) {
        code = CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT;
      } else {
        code = CompileTimeErrorCode.INVALID_CONSTANT;
      }
    }
    _errorReporter.reportErrorForNode(
        code ?? CompileTimeErrorCode.INVALID_CONSTANT, node);
  }

  /**
   * Evaluate the given [condition] with the assumption that it must be a
   * `bool`.
   */
  bool _evaluateCondition(Expression condition) {
    DartObjectImpl conditionResult = condition.accept(this);
    bool conditionValue = conditionResult?.toBoolValue();
    if (conditionValue == null) {
      // TODO(brianwilkerson) Figure out why the static type is sometimes null.
      DartType staticType = condition.staticType;
      if (staticType == null ||
          typeSystem.isAssignableTo(staticType, _typeProvider.boolType)) {
        // If the static type is not assignable, then we will have already
        // reported this error.
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, condition);
      }
    }
    return conditionValue;
  }

  /**
   * Return the constant value of the static constant represented by the given
   * [element]. The [node] is the node to be used if an error needs to be
   * reported.
   */
  DartObjectImpl _getConstantValue(AstNode node, Element element) {
    Element variableElement =
        element is PropertyAccessorElement ? element.variable : element;
    if (variableElement is VariableElementImpl) {
      // We access values of constant variables here in two cases: when we
      // compute values of other constant  variables, or when we compute values
      // and errors for other constant expressions. In any case, with Analysis
      // Driver, we compute values of all dependencies first (or detect  cycle).
      // So, the value has already been computed. Just return it.
      if (evaluationEngine.forAnalysisDriver) {
        EvaluationResultImpl value = variableElement.evaluationResult;
        if (variableElement.isConst && value != null) {
          return value.value;
        }
      } else {
        // TODO(scheglov) Once we remove task model, we can remove this code.
        evaluationEngine.validator.beforeGetEvaluationResult(variableElement);
        variableElement.computeConstantValue();
        EvaluationResultImpl value = variableElement.evaluationResult;
        if (variableElement.isConst && value != null) {
          return value.value;
        }
      }
    } else if (variableElement is ExecutableElement) {
      ExecutableElement function = element;
      if (function.isStatic) {
        ParameterizedType functionType = function.type;
        if (functionType == null) {
          functionType = _typeProvider.functionType;
        }
        return new DartObjectImpl(functionType, new FunctionState(function));
      }
    } else if (variableElement is TypeDefiningElement) {
      // Constants may not refer to type parameters.
      if (variableElement is! TypeParameterElement) {
        return new DartObjectImpl(
            _typeProvider.typeType, new TypeState(variableElement.type));
      }
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  /**
   * Return `true` if the given [targetResult] represents a string and the
   * [identifier] is "length".
   */
  bool _isStringLength(
      DartObjectImpl targetResult, SimpleIdentifier identifier) {
    if (targetResult == null || targetResult.type != _typeProvider.stringType) {
      return false;
    }
    return identifier.name == 'length';
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

  /**
   * Return the value of the given [expression], or a representation of 'null'
   * if the expression cannot be evaluated.
   */
  DartObjectImpl _valueOf(Expression expression) {
    DartObjectImpl expressionValue = expression.accept(this);
    if (expressionValue != null) {
      return expressionValue;
    }
    return _typeProvider.nullObject;
  }
}

/**
 * A utility class that contains methods for manipulating instances of a Dart
 * class and for collecting errors during evaluation.
 */
class DartObjectComputer {
  /**
   * The error reporter that we are using to collect errors.
   */
  final ErrorReporter _errorReporter;

  /**
   * The type provider used to access the known types.
   */
  final ConstantEvaluationEngine _evaluationEngine;

  DartObjectComputer(this._errorReporter, this._evaluationEngine);

  /**
   * Convenience getter to gain access to the [evaluationEngine]'s type
   * provider.
   */
  TypeProvider get _typeProvider => _evaluationEngine.typeProvider;

  /**
   * Convenience getter to gain access to the [evaluationEngine]'s type system.
   */
  TypeSystem get _typeSystem => _evaluationEngine.typeSystem;

  DartObjectImpl add(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.add(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
        return null;
      }
    }
    return null;
  }

  /**
   * Return the result of applying boolean conversion to the [evaluationResult].
   * The [node] is the node against which errors should be reported.
   */
  DartObjectImpl applyBooleanConversion(
      AstNode node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.convertToBool(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl bitNot(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.bitNot(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl castToType(
      AsExpression node, DartObjectImpl expression, DartObjectImpl type) {
    if (expression != null && type != null) {
      try {
        return expression.castToType(_typeProvider, _typeSystem, type);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl concatenate(Expression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.concatenate(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl divide(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.divide(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl eagerAnd(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand, bool allowBool) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerAnd(_typeProvider, rightOperand, allowBool);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl eagerOr(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand, bool allowBool) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerOr(_typeProvider, rightOperand, allowBool);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl eagerQuestionQuestion(Expression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      if (leftOperand.isNull) {
        return rightOperand;
      }
      return leftOperand;
    }
    return null;
  }

  DartObjectImpl eagerXor(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand, bool allowBool) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerXor(_typeProvider, rightOperand, allowBool);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl equalEqual(Expression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.equalEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl greaterThan(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThan(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl greaterThanOrEqual(BinaryExpression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl integerDivide(BinaryExpression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.integerDivide(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl isIdentical(Expression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.isIdentical(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl lazyAnd(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperandComputer()) {
    if (leftOperand != null) {
      try {
        return leftOperand.lazyAnd(_typeProvider, rightOperandComputer);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl lazyEqualEqual(Expression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lazyEqualEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl lazyOr(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperandComputer()) {
    if (leftOperand != null) {
      try {
        return leftOperand.lazyOr(_typeProvider, rightOperandComputer);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl lazyQuestionQuestion(Expression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperandComputer()) {
    if (leftOperand != null) {
      if (leftOperand.isNull) {
        return rightOperandComputer();
      }
      return leftOperand;
    }
    return null;
  }

  DartObjectImpl lessThan(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThan(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl lessThanOrEqual(BinaryExpression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl logicalNot(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.logicalNot(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl logicalShiftRight(BinaryExpression node,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalShiftRight(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl minus(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.minus(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl negated(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.negated(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl notEqual(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.notEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl performToString(
      AstNode node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.performToString(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl remainder(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.remainder(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl shiftLeft(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftLeft(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl shiftRight(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftRight(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  /**
   * Return the result of invoking the 'length' getter on the
   * [evaluationResult]. The [node] is the node against which errors should be
   * reported.
   */
  EvaluationResultImpl stringLength(
      Expression node, EvaluationResultImpl evaluationResult) {
    if (evaluationResult.value != null) {
      try {
        return new EvaluationResultImpl(
            evaluationResult.value.stringLength(_typeProvider));
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return new EvaluationResultImpl(null);
  }

  DartObjectImpl times(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.times(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl typeTest(
      IsExpression node, DartObjectImpl expression, DartObjectImpl type) {
    if (expression != null && type != null) {
      try {
        DartObjectImpl result =
            expression.hasType(_typeProvider, _typeSystem, type);
        if (node.notOperator != null) {
          return result.logicalNot(_typeProvider);
        }
        return result;
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }
}

/**
 * The result of attempting to evaluate an expression.
 */
class EvaluationResult {
  // TODO(brianwilkerson) Merge with EvaluationResultImpl
  /**
   * The value of the expression.
   */
  final DartObject value;

  /**
   * The errors that should be reported for the expression(s) that were
   * evaluated.
   */
  final List<AnalysisError> _errors;

  /**
   * Initialize a newly created result object with the given [value] and set of
   * [_errors]. Clients should use one of the factory methods: [forErrors] and
   * [forValue].
   */
  EvaluationResult(this.value, this._errors);

  /**
   * Return a list containing the errors that should be reported for the
   * expression(s) that were evaluated. If there are no such errors, the list
   * will be empty. The list can be empty even if the expression is not a valid
   * compile time constant if the errors would have been reported by other parts
   * of the analysis engine.
   */
  List<AnalysisError> get errors => _errors ?? AnalysisError.NO_ERRORS;

  /**
   * Return `true` if the expression is a compile-time constant expression that
   * would not throw an exception when evaluated.
   */
  bool get isValid => _errors == null;

  /**
   * Return an evaluation result representing the result of evaluating an
   * expression that is not a compile-time constant because of the given
   * [errors].
   */
  static EvaluationResult forErrors(List<AnalysisError> errors) =>
      new EvaluationResult(null, errors);

  /**
   * Return an evaluation result representing the result of evaluating an
   * expression that is a compile-time constant that evaluates to the given
   * [value].
   */
  static EvaluationResult forValue(DartObject value) =>
      new EvaluationResult(value, null);
}

/**
 * The result of attempting to evaluate a expression.
 */
class EvaluationResultImpl {
  /**
   * The errors encountered while trying to evaluate the compile time constant.
   * These errors may or may not have prevented the expression from being a
   * valid compile time constant.
   */
  List<AnalysisError> _errors;

  /**
   * The value of the expression, or `null` if the value couldn't be computed
   * due to errors.
   */
  final DartObjectImpl value;

  EvaluationResultImpl(this.value, [List<AnalysisError> errors]) {
    this._errors = errors ?? <AnalysisError>[];
  }

  List<AnalysisError> get errors => _errors;

  bool equalValues(TypeProvider typeProvider, EvaluationResultImpl result) {
    if (this.value != null) {
      if (result.value == null) {
        return false;
      }
      return value == result.value;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    if (value == null) {
      return "error";
    }
    return value.toString();
  }
}

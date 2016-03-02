// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.constant;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/element_handle.dart'
    show ConstructorElementHandle;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, RecordingErrorListener;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/type_system.dart'
    show TypeSystem, TypeSystemImpl;
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/dart.dart';

ConstructorElementImpl _getConstructorImpl(ConstructorElement constructor) {
  while (constructor is ConstructorMember) {
    constructor = (constructor as ConstructorMember).baseElement;
  }
  if (constructor is ConstructorElementHandle) {
    constructor = (constructor as ConstructorElementHandle).actualElement;
  }
  return constructor;
}

/**
 * Callback used by [ReferenceFinder] to report that a dependency was found.
 */
typedef void ReferenceFinderCallback(ConstantEvaluationTarget dependency);

/**
 * The state of an object representing a boolean value.
 */
class BoolState extends InstanceState {
  /**
   * An instance representing the boolean value 'false'.
   */
  static BoolState FALSE_STATE = new BoolState(false);

  /**
   * An instance representing the boolean value 'true'.
   */
  static BoolState TRUE_STATE = new BoolState(true);

  /**
   * A state that can be used to represent a boolean whose value is not known.
   */
  static BoolState UNKNOWN_VALUE = new BoolState(null);

  /**
   * The value of this instance.
   */
  final bool value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  BoolState(this.value);

  @override
  int get hashCode => value == null ? 0 : (value ? 2 : 3);

  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "bool";

  @override
  bool operator ==(Object object) =>
      object is BoolState && identical(value, object.value);

  @override
  BoolState convertToBool() => this;

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value ? "true" : "false");
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is BoolState) {
      bool rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return BoolState.from(identical(value, rightValue));
    } else if (rightOperand is DynamicState) {
      return UNKNOWN_VALUE;
    }
    return FALSE_STATE;
  }

  @override
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return value ? rightOperand.convertToBool() : FALSE_STATE;
  }

  @override
  BoolState logicalNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return value ? FALSE_STATE : TRUE_STATE;
  }

  @override
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return value ? TRUE_STATE : rightOperand.convertToBool();
  }

  @override
  String toString() => value == null ? "-unknown-" : (value ? "true" : "false");

  /**
   * Return the boolean state representing the given boolean [value].
   */
  static BoolState from(bool value) =>
      value ? BoolState.TRUE_STATE : BoolState.FALSE_STATE;
}

/**
 * An [AstCloner] that copies the necessary information from the AST to allow
 * constants to be evaluated.
 */
class ConstantAstCloner extends AstCloner {
  ConstantAstCloner() : super(true);

  @override
  ConstructorName visitConstructorName(ConstructorName node) {
    ConstructorName name = super.visitConstructorName(node);
    name.staticElement = node.staticElement;
    return name;
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpression expression =
        super.visitInstanceCreationExpression(node);
    expression.staticElement = node.staticElement;
    return expression;
  }

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation invocation =
        super.visitRedirectingConstructorInvocation(node);
    invocation.staticElement = node.staticElement;
    return invocation;
  }

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier identifier = super.visitSimpleIdentifier(node);
    identifier.staticElement = node.staticElement;
    return identifier;
  }

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    SuperConstructorInvocation invocation =
        super.visitSuperConstructorInvocation(node);
    invocation.staticElement = node.staticElement;
    return invocation;
  }

  @override
  TypeName visitTypeName(TypeName node) {
    TypeName typeName = super.visitTypeName(node);
    typeName.type = node.type;
    return typeName;
  }
}

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
   * Source of RegExp matching any public identifier.
   * From sdk/lib/internal/symbol.dart.
   */
  static String _PUBLIC_IDENTIFIER_RE =
      "(?!${ConstantValueComputer._RESERVED_WORD_RE}\\b(?!\\\$))[a-zA-Z\$][\\w\$]*";

  /**
   * RegExp that validates a non-empty non-private symbol.
   * From sdk/lib/internal/symbol.dart.
   */
  static RegExp _PUBLIC_SYMBOL_PATTERN = new RegExp(
      "^(?:${ConstantValueComputer._OPERATOR_RE}\$|$_PUBLIC_IDENTIFIER_RE(?:=?\$|[.](?!\$)))+?\$");

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
   * Validator used to verify correct dependency analysis when running unit
   * tests.
   */
  final ConstantEvaluationValidator validator;

  /**
   * Initialize a newly created [ConstantEvaluationEngine].  The [typeProvider]
   * is used to access known types.  [_declaredVariables] is the set of
   * variables declared on the command line using '-D'.  The [validator], if
   * given, is used to verify correct dependency analysis when running unit
   * tests.
   */
  ConstantEvaluationEngine(this.typeProvider, this._declaredVariables,
      {ConstantEvaluationValidator validator, TypeSystem typeSystem})
      : validator = validator != null
            ? validator
            : new ConstantEvaluationValidator_ForProduction(),
        typeSystem = typeSystem != null ? typeSystem : new TypeSystemImpl();

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
      HashMap<String, DartObjectImpl> namedArgumentValues,
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
      if (arguments[1] is! NamedExpression) {
        return false;
      }
      if (!((arguments[1] as NamedExpression).name.label.name ==
          _DEFAULT_VALUE_PARAM)) {
        return false;
      }
      ParameterizedType defaultValueType =
          namedArgumentValues[_DEFAULT_VALUE_PARAM].type;
      if (!(identical(defaultValueType, expectedDefaultValueType) ||
          identical(defaultValueType, typeProvider.nullType))) {
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
      HashMap<String, DartObjectImpl> namedArgumentValues) {
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
      Expression defaultValue = constant.constantInitializer;
      if (defaultValue != null) {
        RecordingErrorListener errorListener = new RecordingErrorListener();
        ErrorReporter errorReporter =
            new ErrorReporter(errorListener, constant.source);
        DartObjectImpl dartObject =
            defaultValue.accept(new ConstantVisitor(this, errorReporter));
        constant.evaluationResult =
            new EvaluationResultImpl(dartObject, errorListener.errors);
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
    } else if (constant is ConstructorElement) {
      if (constant.isConst) {
        // No evaluation needs to be done; constructor declarations are only in
        // the dependency graph to ensure that any constants referred to in
        // initializer lists and parameter defaults are evaluated before
        // invocations of the constructor.  However we do need to annotate the
        // element as being free of constant evaluation cycles so that later
        // code will know that it is safe to evaluate.
        (constant as ConstructorElementImpl).isCycleFree = true;
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
      } else if (element is ConstructorElementImpl &&
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
      constant = _getConstructorImpl(constant);
    }
    if (constant is VariableElementImpl) {
      Expression initializer = constant.constantInitializer;
      if (initializer != null) {
        initializer.accept(referenceFinder);
      }
    } else if (constant is ConstructorElementImpl) {
      if (constant.isConst) {
        constant.isCycleFree = false;
        ConstructorElement redirectedConstructor =
            getConstRedirectedConstructor(constant);
        if (redirectedConstructor != null) {
          ConstructorElement redirectedConstructorBase =
              _getConstructorImpl(redirectedConstructor);
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
        bool superInvocationFound = false;
        List<ConstructorInitializer> initializers =
            constant.constantInitializers;
        for (ConstructorInitializer initializer in initializers) {
          if (initializer is SuperConstructorInvocation) {
            superInvocationFound = true;
          }
          initializer.accept(referenceFinder);
        }
        if (!superInvocationFound) {
          // No explicit superconstructor invocation found, so we need to
          // manually insert a reference to the implicit superconstructor.
          InterfaceType superclass =
              (constant.returnType as InterfaceType).superclass;
          if (superclass != null && !superclass.isObject) {
            ConstructorElement unnamedConstructor =
                _getConstructorImpl(superclass.element.unnamedConstructor);
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
      if (constNode.arguments != null) {
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
      HashMap<String, DartObjectImpl> namedArgumentValues) {
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
      NodeList<Expression> arguments,
      ConstructorElement constructor,
      ConstantVisitor constantVisitor,
      ErrorReporter errorReporter) {
    if (!_getConstructorImpl(constructor).isCycleFree) {
      // It's not safe to evaluate this constructor, so bail out.
      // TODO(paulberry): ensure that a reasonable error message is produced
      // in this case, as well as other cases involving constant expression
      // circularities (e.g. "compile-time constant expression depends on
      // itself")
      return new DartObjectImpl.validWithUnknownValue(constructor.returnType);
    }
    int argumentCount = arguments.length;
    List<DartObjectImpl> argumentValues =
        new List<DartObjectImpl>(argumentCount);
    List<Expression> argumentNodes = new List<Expression>(argumentCount);
    HashMap<String, DartObjectImpl> namedArgumentValues =
        new HashMap<String, DartObjectImpl>();
    HashMap<String, NamedExpression> namedArgumentNodes =
        new HashMap<String, NamedExpression>();
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        String name = argument.name.label.name;
        namedArgumentValues[name] =
            constantVisitor._valueOf(argument.expression);
        namedArgumentNodes[name] = argument;
        argumentValues[i] = typeProvider.nullObject;
      } else {
        argumentValues[i] = constantVisitor._valueOf(argument);
        argumentNodes[i] = argument;
      }
    }
    constructor = followConstantRedirectionChain(constructor);
    InterfaceType definingClass = constructor.returnType as InterfaceType;
    if (constructor.isFactory) {
      // We couldn't find a non-factory constructor.
      // See if it's because we reached an external const factory constructor
      // that we can emulate.
      if (constructor.name == "fromEnvironment") {
        if (!checkFromEnvironmentArguments(
            arguments, argumentValues, namedArgumentValues, definingClass)) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node);
          return null;
        }
        String variableName =
            argumentCount < 1 ? null : argumentValues[0].toStringValue();
        if (identical(definingClass, typeProvider.boolType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getBool(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE),
              namedArgumentValues);
        } else if (identical(definingClass, typeProvider.intType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getInt(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE),
              namedArgumentValues);
        } else if (identical(definingClass, typeProvider.stringType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment =
              _declaredVariables.getString(typeProvider, variableName);
          return computeValueFromEnvironment(
              valueFromEnvironment,
              new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE),
              namedArgumentValues);
        }
      } else if (constructor.name == "" &&
          identical(definingClass, typeProvider.symbolType) &&
          argumentCount == 1) {
        if (!checkSymbolArguments(
            arguments, argumentValues, namedArgumentValues)) {
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
    ConstructorElementImpl constructorBase = _getConstructorImpl(constructor);
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
    HashMap<String, DartObjectImpl> fieldMap =
        new HashMap<String, DartObjectImpl>();
    // Start with final fields that are initialized at their declaration site.
    for (FieldElement field in constructor.enclosingElement.fields) {
      if ((field.isFinal || field.isConst) &&
          !field.isStatic &&
          field is ConstFieldElementImpl) {
        validator.beforeGetFieldEvaluationResult(field);
        EvaluationResultImpl evaluationResult = field.evaluationResult;
        // It is possible that the evaluation result is null.
        // This happens for example when we have duplicate fields.
        // class Test {final x = 1; final x = 2; const Test();}
        if (evaluationResult == null) {
          continue;
        }
        // Match the value and the type.
        DartType fieldType =
            FieldMember.from(field, constructor.returnType).type;
        DartObjectImpl fieldValue = evaluationResult.value;
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
    HashMap<String, DartObjectImpl> parameterMap =
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
      if (baseParameter.parameterKind == ParameterKind.NAMED) {
        argumentValue = namedArgumentValues[baseParameter.name];
        errorTarget = namedArgumentNodes[baseParameter.name];
      } else if (i < argumentCount) {
        argumentValue = argumentValues[i];
        errorTarget = argumentNodes[i];
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
        } else {
          String name = baseParameter.name;
          parameterMap[name] = argumentValue;
        }
      }
    }
    ConstantVisitor initializerVisitor = new ConstantVisitor(
        this, errorReporter,
        lexicalEnvironment: parameterMap);
    String superName = null;
    NodeList<Expression> superArguments = null;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = initializer;
        Expression initializerExpression =
            constructorFieldInitializer.expression;
        DartObjectImpl evaluationResult =
            initializerExpression.accept(initializerVisitor);
        if (evaluationResult != null) {
          String fieldName = constructorFieldInitializer.fieldName.name;
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
        }
      } else if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation superConstructorInvocation = initializer;
        SimpleIdentifier name = superConstructorInvocation.constructorName;
        if (name != null) {
          superName = name.name;
        }
        superArguments = superConstructorInvocation.argumentList.arguments;
      } else if (initializer is RedirectingConstructorInvocation) {
        // This is a redirecting constructor, so just evaluate the constructor
        // it redirects to.
        ConstructorElement constructor = initializer.staticElement;
        if (constructor != null && constructor.isConst) {
          return evaluateConstructorCall(
              node,
              initializer.argumentList.arguments,
              constructor,
              initializerVisitor,
              errorReporter);
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
          superArguments = new NodeList<Expression>(null);
        }
        evaluateSuperConstructorCall(node, fieldMap, superConstructor,
            superArguments, initializerVisitor, errorReporter);
      }
    }
    return new DartObjectImpl(definingClass, new GenericState(fieldMap));
  }

  void evaluateSuperConstructorCall(
      AstNode node,
      HashMap<String, DartObjectImpl> fieldMap,
      ConstructorElement superConstructor,
      NodeList<Expression> superArguments,
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
        ConstructorElement constructorBase = _getConstructorImpl(constructor);
        constructorsVisited.add(constructorBase);
        ConstructorElement redirectedConstructorBase =
            _getConstructorImpl(redirectedConstructor);
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
    if (type.isUndefined) {
      return false;
    }
    return obj.type.isSubtypeOf(type);
  }

  /**
   * Determine whether the given string is a valid name for a public symbol
   * (i.e. whether it is allowed for a call to the Symbol constructor).
   */
  static bool isValidPublicSymbol(String name) =>
      name.isEmpty ||
      name == "void" ||
      new JavaPatternMatcher(_PUBLIC_SYMBOL_PATTERN, name).matches();
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

/// Instances of the class [ConstantEvaluator] evaluate constant expressions to
/// produce their compile-time value.
///
/// According to the Dart Language Specification:
///
/// > A constant expression is one of the following:
/// >
/// > * A literal number.
/// > * A literal boolean.
/// > * A literal string where any interpolated expression is a compile-time
/// >   constant that evaluates to a numeric, string or boolean value or to
/// >   **null**.
/// > * A literal symbol.
/// > * **null**.
/// > * A qualified reference to a static constant variable.
/// > * An identifier expression that denotes a constant variable, class or type
/// >   alias.
/// > * A constant constructor invocation.
/// > * A constant list literal.
/// > * A constant map literal.
/// > * A simple or qualified identifier denoting a top-level function or a
/// >   static method.
/// > * A parenthesized expression _(e)_ where _e_ is a constant expression.
/// > * <span>
/// >   An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i>
/// >   where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions and <i>identical()</i> is statically bound to the predefined
/// >   dart function <i>identical()</i> discussed above.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i>
/// >   or <i>e<sub>1</sub> != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a
/// >   numeric, string or boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> || e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to a boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &amp; e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;&gt;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to an integer value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> +
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> -e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> * e<sub>2</sub></i>, <i>e<sub>1</sub> /
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> ~/ e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &gt; e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;= e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or <i>e<sub>1</sub> %
/// >   e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a numeric
/// >   value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> :
/// >   e<sub>3</sub></i> where <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and
/// >   <i>e<sub>3</sub></i> are constant expressions, and <i>e<sub>1</sub></i>
/// >   evaluates to a boolean value.
/// >   </span>
///
/// The values returned by instances of this class are therefore `null` and
/// instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
/// `DartObject`.
///
/// In addition, this class defines several values that can be returned to
/// indicate various conditions encountered during evaluation. These are
/// documented with the static fields that define those values.
class ConstantEvaluator {
  /**
   * The source containing the expression(s) that will be evaluated.
   */
  final Source _source;

  /**
   * The type provider used to access the known types.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system primitives.
   */
  final TypeSystem _typeSystem;

  /**
   * Initialize a newly created evaluator to evaluate expressions in the given
   * [source]. The [typeProvider] is the type provider used to access known
   * types.
   */
  ConstantEvaluator(this._source, this._typeProvider, {TypeSystem typeSystem})
      : _typeSystem = typeSystem != null ? typeSystem : new TypeSystemImpl();

  EvaluationResult evaluate(Expression expression) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(_typeProvider, new DeclaredVariables(),
            typeSystem: _typeSystem),
        errorReporter));
    if (result != null) {
      return EvaluationResult.forValue(result);
    }
    return EvaluationResult.forErrors(errorListener.errors);
  }
}

/**
 * A visitor used to traverse the AST structures of all of the compilation units
 * being resolved and build the full set of dependencies for all constant
 * expressions.
 */
class ConstantExpressionsDependenciesFinder extends RecursiveAstVisitor {
  /**
   * The constants whose values need to be computed.
   */
  HashSet<ConstantEvaluationTarget> dependencies =
      new HashSet<ConstantEvaluationTarget>();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      _find(node);
    } else {
      super.visitListLiteral(node);
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (node.constKeyword != null) {
      _find(node);
    } else {
      super.visitMapLiteral(node);
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _find(node.expression);
    node.statements.accept(this);
  }

  void _find(Expression node) {
    if (node != null) {
      ReferenceFinder referenceFinder = new ReferenceFinder(dependencies.add);
      node.accept(referenceFinder);
    }
  }
}

/**
 * A visitor used to traverse the AST structures of all of the compilation units
 * being resolved and build tables of the constant variables, constant
 * constructors, constant constructor invocations, and annotations found in
 * those compilation units.
 */
class ConstantFinder extends RecursiveAstVisitor<Object> {
  final AnalysisContext context;
  final Source source;
  final Source librarySource;

  /**
   * The elements and AST nodes whose constant values need to be computed.
   */
  List<ConstantEvaluationTarget> constantsToCompute =
      <ConstantEvaluationTarget>[];

  /**
   * True if instance variables marked as "final" should be treated as "const".
   */
  bool treatFinalInstanceVarAsConst = false;

  ConstantFinder(this.context, this.source, this.librarySource);

  @override
  Object visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    ElementAnnotation elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      // Analyzer ignores annotations on "part of" directives.
      assert(node.parent is PartOfDirective);
    } else {
      constantsToCompute.add(elementAnnotation);
    }
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    bool prevTreatFinalInstanceVarAsConst = treatFinalInstanceVarAsConst;
    if (node.element.constructors.any((ConstructorElement e) => e.isConst)) {
      // Instance vars marked "final" need to be included in the dependency
      // graph, since constant constructors implicitly use the values in their
      // initializers.
      treatFinalInstanceVarAsConst = true;
    }
    try {
      return super.visitClassDeclaration(node);
    } finally {
      treatFinalInstanceVarAsConst = prevTreatFinalInstanceVarAsConst;
    }
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    if (node.constKeyword != null) {
      ConstructorElement element = node.element;
      if (element != null) {
        constantsToCompute.add(element);
        constantsToCompute.addAll(element.parameters);
      }
    }
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null && node.element != null) {
      constantsToCompute.add(node.element);
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    VariableElement element = node.element;
    if (initializer != null &&
        (node.isConst ||
            treatFinalInstanceVarAsConst &&
                element is FieldElement &&
                node.isFinal &&
                !element.isStatic)) {
      if (node.element != null) {
        constantsToCompute.add(node.element);
      }
    }
    return null;
  }
}

/**
 * An object used to compute the values of constant variables and constant
 * constructor invocations in one or more compilation units. The expected usage
 * pattern is for the compilation units to be added to this computer using the
 * method [add] and then for the method [computeValues] to be invoked exactly
 * once. Any use of an instance after invoking the method [computeValues] will
 * result in unpredictable behavior.
 */
class ConstantValueComputer {
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
      "(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|v(?:ar|oid)|w(?:hile|ith))";

  /**
   * A graph in which the nodes are the constants, and the edges are from each
   * constant to the other constants that are referenced by it.
   */
  DirectedGraph<ConstantEvaluationTarget> referenceGraph =
      new DirectedGraph<ConstantEvaluationTarget>();

  /**
   * The elements whose constant values need to be computed.  Any elements
   * which appear in [referenceGraph] but not in this set either belong to a
   * different library cycle (and hence don't need to be recomputed) or were
   * computed during a previous stage of resolution stage (e.g. constants
   * associated with enums).
   */
  HashSet<ConstantEvaluationTarget> _constantsToCompute =
      new HashSet<ConstantEvaluationTarget>();

  /**
   * The evaluation engine that does the work of evaluating instance creation
   * expressions.
   */
  final ConstantEvaluationEngine evaluationEngine;

  final AnalysisContext _context;

  /**
   * Initialize a newly created constant value computer. The [typeProvider] is
   * the type provider used to access known types. The [declaredVariables] is
   * the set of variables declared on the command line using '-D'.
   */
  ConstantValueComputer(this._context, TypeProvider typeProvider,
      DeclaredVariables declaredVariables,
      [ConstantEvaluationValidator validator, TypeSystem typeSystem])
      : evaluationEngine = new ConstantEvaluationEngine(
            typeProvider, declaredVariables,
            validator: validator, typeSystem: typeSystem);

  /**
   * Add the constants in the given compilation [unit] to the list of constants
   * whose value needs to be computed.
   */
  void add(CompilationUnit unit, Source source, Source librarySource) {
    ConstantFinder constantFinder =
        new ConstantFinder(_context, source, librarySource);
    unit.accept(constantFinder);
    _constantsToCompute.addAll(constantFinder.constantsToCompute);
  }

  /**
   * Compute values for all of the constants in the compilation units that were
   * added.
   */
  void computeValues() {
    for (ConstantEvaluationTarget constant in _constantsToCompute) {
      referenceGraph.addNode(constant);
      evaluationEngine.computeDependencies(constant,
          (ConstantEvaluationTarget dependency) {
        referenceGraph.addEdge(constant, dependency);
      });
    }
    List<List<ConstantEvaluationTarget>> topologicalSort =
        referenceGraph.computeTopologicalSort();
    for (List<ConstantEvaluationTarget> constantsInCycle in topologicalSort) {
      if (constantsInCycle.length == 1) {
        ConstantEvaluationTarget constant = constantsInCycle[0];
        if (!referenceGraph.getTails(constant).contains(constant)) {
          _computeValueFor(constant);
          continue;
        }
      }
      for (ConstantEvaluationTarget constant in constantsInCycle) {
        evaluationEngine.generateCycleError(constantsInCycle, constant);
      }
    }
  }

  /**
   * Compute a value for the given [constant].
   */
  void _computeValueFor(ConstantEvaluationTarget constant) {
    if (!_constantsToCompute.contains(constant)) {
      // Element is in the dependency graph but should have been computed by
      // a previous stage of analysis.
      // TODO(paulberry): once we have moved over to the new task model, this
      // should only occur for constants associated with enum members.  Once
      // that happens we should add an assertion to verify that it doesn't
      // occur in any other cases.
      return;
    }
    evaluationEngine.computeConstantValue(constant);
  }
}

/**
 * A visitor used to evaluate constant expressions to produce their compile-time
 * value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 *
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time
 *   constant that evaluates to a numeric, string or boolean value or to
 *   <b>null</b>.
 * * A literal symbol.
 * * <b>null</b>.
 * * A qualified reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, class or type
 *   alias.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static
 *   method.
 * * A parenthesized expression <i>(e)</i> where <i>e</i> is a constant
 *   expression.
 * * An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i>
 *   where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 *   expressions and <i>identical()</i> is statically bound to the predefined
 *   dart function <i>identical()</i> discussed above.
 * * An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i> or
 *   <i>e<sub>1</sub> != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and
 *   <i>e<sub>2</sub></i> are constant expressions that evaluate to a numeric,
 *   string or boolean value.
 * * An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp;
 *   e<sub>2</sub></i> or <i>e<sub>1</sub> || e<sub>2</sub></i>, where <i>e</i>,
 *   <i>e1</sub></i> and <i>e2</sub></i> are constant expressions that evaluate
 *   to a boolean value.
 * * An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^
 *   e<sub>2</sub></i>, <i>e<sub>1</sub> &amp; e<sub>2</sub></i>,
 *   <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;&gt;
 *   e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where
 *   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 *   expressions that evaluate to an integer value or to <b>null</b>.
 * * An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> +
 *   e<sub>2</sub></i>, <i>e<sub>1</sub> - e<sub>2</sub></i>, <i>e<sub>1</sub> *
 *   e<sub>2</sub></i>, <i>e<sub>1</sub> / e<sub>2</sub></i>, <i>e<sub>1</sub>
 *   ~/ e<sub>2</sub></i>, <i>e<sub>1</sub> &gt; e<sub>2</sub></i>,
 *   <i>e<sub>1</sub> &lt; e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;=
 *   e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or
 *   <i>e<sub>1</sub> % e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i>
 *   and <i>e<sub>2</sub></i> are constant expressions that evaluate to a
 *   numeric value or to <b>null</b>.
 * * An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> :
 *   e<sub>3</sub></i> where <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and
 *   <i>e<sub>3</sub></i> are constant expressions, and <i>e<sub>1</sub></i>
 *   evaluates to a boolean value.
 * </blockquote>
 */
class ConstantVisitor extends UnifyingAstVisitor<DartObjectImpl> {
  /**
   * The type provider used to access the known types.
   */
  final ConstantEvaluationEngine evaluationEngine;

  final HashMap<String, DartObjectImpl> _lexicalEnvironment;

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
      {HashMap<String, DartObjectImpl> lexicalEnvironment})
      : _lexicalEnvironment = lexicalEnvironment {
    this._dartObjectComputer =
        new DartObjectComputer(_errorReporter, evaluationEngine.typeProvider);
  }

  /**
   * Convenience getter to gain access to the [evalationEngine]'s type
   * provider.
   */
  TypeProvider get _typeProvider => evaluationEngine.typeProvider;

  /**
   * Convenience getter to gain access to the [evaluationEngine]'s type system.
   */
  TypeSystem get _typeSystem => evaluationEngine.typeSystem;

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
  DartObjectImpl visitBinaryExpression(BinaryExpression node) {
    DartObjectImpl leftResult = node.leftOperand.accept(this);
    DartObjectImpl rightResult = node.rightOperand.accept(this);
    TokenType operatorType = node.operator.type;
    // 'null' is almost never good operand
    if (operatorType != TokenType.BANG_EQ &&
        operatorType != TokenType.EQ_EQ &&
        operatorType != TokenType.QUESTION_QUESTION) {
      if (leftResult != null && leftResult.isNull ||
          rightResult != null && rightResult.isNull) {
        _error(node, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
        return null;
      }
    }
    // evaluate operator
    while (true) {
      if (operatorType == TokenType.AMPERSAND) {
        return _dartObjectComputer.bitAnd(node, leftResult, rightResult);
      } else if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
        return _dartObjectComputer.logicalAnd(node, leftResult, rightResult);
      } else if (operatorType == TokenType.BANG_EQ) {
        return _dartObjectComputer.notEqual(node, leftResult, rightResult);
      } else if (operatorType == TokenType.BAR) {
        return _dartObjectComputer.bitOr(node, leftResult, rightResult);
      } else if (operatorType == TokenType.BAR_BAR) {
        return _dartObjectComputer.logicalOr(node, leftResult, rightResult);
      } else if (operatorType == TokenType.CARET) {
        return _dartObjectComputer.bitXor(node, leftResult, rightResult);
      } else if (operatorType == TokenType.EQ_EQ) {
        return _dartObjectComputer.equalEqual(node, leftResult, rightResult);
      } else if (operatorType == TokenType.GT) {
        return _dartObjectComputer.greaterThan(node, leftResult, rightResult);
      } else if (operatorType == TokenType.GT_EQ) {
        return _dartObjectComputer.greaterThanOrEqual(
            node, leftResult, rightResult);
      } else if (operatorType == TokenType.GT_GT) {
        return _dartObjectComputer.shiftRight(node, leftResult, rightResult);
      } else if (operatorType == TokenType.LT) {
        return _dartObjectComputer.lessThan(node, leftResult, rightResult);
      } else if (operatorType == TokenType.LT_EQ) {
        return _dartObjectComputer.lessThanOrEqual(
            node, leftResult, rightResult);
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
      } else if (operatorType == TokenType.QUESTION_QUESTION) {
        return _dartObjectComputer.questionQuestion(
            node, leftResult, rightResult);
      } else {
        // TODO(brianwilkerson) Figure out which error to report.
        _error(node, null);
        return null;
      }
      break;
    }
  }

  @override
  DartObjectImpl visitBooleanLiteral(BooleanLiteral node) =>
      new DartObjectImpl(_typeProvider.boolType, BoolState.from(node.value));

  @override
  DartObjectImpl visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    DartObjectImpl conditionResult = condition.accept(this);
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
        _typeSystem.getLeastUpperBound(_typeProvider, thenType, elseType)
        as InterfaceType);
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
  DartObjectImpl visitIntegerLiteral(IntegerLiteral node) =>
      new DartObjectImpl(_typeProvider.intType, new IntState(node.value));

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
  DartObjectImpl visitListLiteral(ListLiteral node) {
    if (node.constKeyword == null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL, node);
      return null;
    }
    bool errorOccurred = false;
    List<DartObjectImpl> elements = new List<DartObjectImpl>();
    for (Expression element in node.elements) {
      DartObjectImpl elementResult = element.accept(this);
      if (elementResult == null) {
        errorOccurred = true;
      } else {
        elements.add(elementResult);
      }
    }
    if (errorOccurred) {
      return null;
    }
    DartType elementType = _typeProvider.dynamicType;
    if (node.typeArguments != null &&
        node.typeArguments.arguments.length == 1) {
      DartType type = node.typeArguments.arguments[0].type;
      if (type != null) {
        elementType = type;
      }
    }
    InterfaceType listType = _typeProvider.listType.instantiate([elementType]);
    return new DartObjectImpl(listType, new ListState(elements));
  }

  @override
  DartObjectImpl visitMapLiteral(MapLiteral node) {
    if (node.constKeyword == null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL, node);
      return null;
    }
    bool errorOccurred = false;
    LinkedHashMap<DartObjectImpl, DartObjectImpl> map =
        new LinkedHashMap<DartObjectImpl, DartObjectImpl>();
    for (MapLiteralEntry entry in node.entries) {
      DartObjectImpl keyResult = entry.key.accept(this);
      DartObjectImpl valueResult = entry.value.accept(this);
      if (keyResult == null || valueResult == null) {
        errorOccurred = true;
      } else {
        map[keyResult] = valueResult;
      }
    }
    if (errorOccurred) {
      return null;
    }
    DartType keyType = _typeProvider.dynamicType;
    DartType valueType = _typeProvider.dynamicType;
    if (node.typeArguments != null &&
        node.typeArguments.arguments.length == 2) {
      DartType keyTypeCandidate = node.typeArguments.arguments[0].type;
      if (keyTypeCandidate != null) {
        keyType = keyTypeCandidate;
      }
      DartType valueTypeCandidate = node.typeArguments.arguments[1].type;
      if (valueTypeCandidate != null) {
        valueType = valueTypeCandidate;
      }
    }
    InterfaceType mapType =
        _typeProvider.mapType.instantiate([keyType, valueType]);
    return new DartObjectImpl(mapType, new MapState(map));
  }

  @override
  DartObjectImpl visitMethodInvocation(MethodInvocation node) {
    Element element = node.methodName.staticElement;
    if (element is FunctionElement) {
      FunctionElement function = element;
      if (function.name == "identical") {
        NodeList<Expression> arguments = node.argumentList.arguments;
        if (arguments.length == 2) {
          Element enclosingElement = function.enclosingElement;
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
    while (true) {
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
      break;
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

  /**
   * Create an error associated with the given [node]. The error will have the
   * given error [code].
   */
  void _error(AstNode node, ErrorCode code) {
    _errorReporter.reportErrorForNode(
        code == null ? CompileTimeErrorCode.INVALID_CONSTANT : code, node);
  }

  /**
   * Return the constant value of the static constant represented by the given
   * [element]. The [node] is the node to be used if an error needs to be
   * reported.
   */
  DartObjectImpl _getConstantValue(AstNode node, Element element) {
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElementImpl) {
      VariableElementImpl variableElementImpl = element;
      evaluationEngine.validator.beforeGetEvaluationResult(element);
      EvaluationResultImpl value = variableElementImpl.evaluationResult;
      if (variableElementImpl.isConst && value != null) {
        return value.value;
      }
    } else if (element is ExecutableElement) {
      ExecutableElement function = element;
      if (function.isStatic) {
        ParameterizedType functionType = function.type;
        if (functionType == null) {
          functionType = _typeProvider.functionType;
        }
        return new DartObjectImpl(functionType, new FunctionState(function));
      }
    } else if (element is ClassElement ||
        element is FunctionTypeAliasElement ||
        element is DynamicElementImpl) {
      return new DartObjectImpl(_typeProvider.typeType, new TypeState(element));
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
 * A representation of the value of a compile-time constant expression.
 *
 * Note that, unlike the mirrors system, the object being represented does *not*
 * exist. This interface allows static analysis tools to determine something
 * about the state of the object that would exist if the code that creates the
 * object were executed, but none of the code being analyzed is actually
 * executed.
 */
abstract class DartObject {
  /**
   * Return `true` if the value of the object being represented is known.
   *
   * This method will return `false` if
   * * the value being represented is the value of a declared variable (a
   *   variable whose value is provided at run-time using a `-D` command-line
   *   option), or
   * * the value is a function.
   *
   * The result of this method does not imply anything about the state of
   * object representations returned by the method [getField], those that are
   * elements of the list returned by [toListValue], or the keys or values in
   * the map returned by [toMapValue]. For example, a representation of a list
   * can return `true` even if one or more of the elements of that list would
   * return `false`.
   */
  bool get hasKnownValue;

  /**
   * Return `true` if the object being represented represents the value 'null'.
   */
  bool get isNull;

  /**
   * Return a representation of the type of the object being represented.
   *
   * For values resulting from the invocation of a 'const' constructor, this
   * will be a representation of the run-time type of the object.
   *
   * For values resulting from a literal expression, this will be a
   * representation of the static type of the value -- `int` for integer
   * literals, `List` for list literals, etc. -- even when the static type is an
   * abstract type (such as `List`) and hence will never be the run-time type of
   * the represented object.
   *
   * For values resulting from any other kind of expression, this will be a
   * representation of the result of evaluating the expression.
   *
   * Return `null` if the expression cannot be evaluated, either because it is
   * not a valid constant expression or because one or more of the values used
   * in the expression does not have a known value.
   *
   * This method can return a representation of the type, even if this object
   * would return `false` from [hasKnownValue].
   */
  ParameterizedType get type;

  /**
   * Return a representation of the value of the field with the given [name].
   *
   * Return `null` if either the object being represented does not have a field
   * with the given name or if the implementation of the class of the object is
   * invalid, making it impossible to determine that value of the field.
   *
   * Note that, unlike the mirrors API, this method does *not* invoke a getter;
   * it simply returns a representation of the known state of a field.
   */
  DartObject getField(String name);

  /**
   * Return a boolean corresponding to the value of the object being
   * represented, or `null` if
   * * this object is not of type 'bool',
   * * the value of the object being represented is not known, or
   * * the value of the object being represented is `null`.
   */
  bool toBoolValue();

  /**
   * Return a double corresponding to the value of the object being represented,
   * or `null`
   * if
   * * this object is not of type 'double',
   * * the value of the object being represented is not known, or
   * * the value of the object being represented is `null`.
   */
  double toDoubleValue();

  /**
   * Return an integer corresponding to the value of the object being
   * represented, or `null` if
   * * this object is not of type 'int',
   * * the value of the object being represented is not known, or
   * * the value of the object being represented is `null`.
   */
  int toIntValue();

  /**
   * Return a list corresponding to the value of the object being represented,
   * or `null` if
   * * this object is not of type 'List', or
   * * the value of the object being represented is `null`.
   */
  List<DartObject> toListValue();

  /**
   * Return a map corresponding to the value of the object being represented, or
   * `null` if
   * * this object is not of type 'Map', or
   * * the value of the object being represented is `null`.
   */
  Map<DartObject, DartObject> toMapValue();

  /**
   * Return a string corresponding to the value of the object being represented,
   * or `null` if
   * * this object is not of type 'String',
   * * the value of the object being represented is not known, or
   * * the value of the object being represented is `null`.
   */
  String toStringValue();

  /**
   * Return a string corresponding to the value of the object being represented,
   * or `null` if
   * * this object is not of type 'Symbol', or
   * * the value of the object being represented is `null`.
   * (We return the string
   */
  String toSymbolValue();

  /**
   * Return the representation of the type corresponding to the value of the
   * object being represented, or `null` if
   * * this object is not of type 'Type', or
   * * the value of the object being represented is `null`.
   */
  DartType toTypeValue();
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
   * The type provider used to create objects of the appropriate types, and to
   * identify when an object is of a built-in type.
   */
  final TypeProvider _typeProvider;

  DartObjectComputer(this._errorReporter, this._typeProvider);

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

  DartObjectImpl bitAnd(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitAnd(_typeProvider, rightOperand);
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

  DartObjectImpl bitOr(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitOr(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl bitXor(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitXor(_typeProvider, rightOperand);
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

  DartObjectImpl logicalAnd(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalAnd(_typeProvider, rightOperand);
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

  DartObjectImpl logicalOr(BinaryExpression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalOr(_typeProvider, rightOperand);
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

  DartObjectImpl questionQuestion(Expression node, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      if (leftOperand.isNull) {
        return rightOperand;
      }
      return leftOperand;
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
}

/**
 * An instance of a Dart class.
 */
class DartObjectImpl implements DartObject {
  /**
   * An empty list of objects.
   */
  static const List<DartObjectImpl> EMPTY_LIST = const <DartObjectImpl>[];

  /**
   * The run-time type of this object.
   */
  @override
  final ParameterizedType type;

  /**
   * The state of the object.
   */
  final InstanceState _state;

  /**
   * Initialize a newly created object to have the given [type] and [_state].
   */
  DartObjectImpl(this.type, this._state);

  /**
   * Create an object to represent an unknown value.
   */
  factory DartObjectImpl.validWithUnknownValue(InterfaceType type) {
    if (type.element.library.isDartCore) {
      String typeName = type.name;
      if (typeName == "bool") {
        return new DartObjectImpl(type, BoolState.UNKNOWN_VALUE);
      } else if (typeName == "double") {
        return new DartObjectImpl(type, DoubleState.UNKNOWN_VALUE);
      } else if (typeName == "int") {
        return new DartObjectImpl(type, IntState.UNKNOWN_VALUE);
      } else if (typeName == "String") {
        return new DartObjectImpl(type, StringState.UNKNOWN_VALUE);
      }
    }
    return new DartObjectImpl(type, GenericState.UNKNOWN_VALUE);
  }

  HashMap<String, DartObjectImpl> get fields => _state.fields;

  @override
  int get hashCode => JenkinsSmiHash.hash2(type.hashCode, _state.hashCode);

  @override
  bool get hasKnownValue => !_state.isUnknown;

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   */
  bool get isBool => _state.isBool;

  /**
   * Return `true` if this object represents an object whose type is either
   * 'bool', 'num', 'String', or 'Null'.
   */
  bool get isBoolNumStringOrNull => _state.isBoolNumStringOrNull;

  @override
  bool get isNull => _state is NullState;

  /**
   * Return `true` if this object represents an unknown value.
   */
  bool get isUnknown => _state.isUnknown;

  /**
   * Return `true` if this object represents an instance of a user-defined
   * class.
   */
  bool get isUserDefinedObject => _state is GenericState;

  @override
  bool operator ==(Object object) {
    if (object is! DartObjectImpl) {
      return false;
    }
    DartObjectImpl dartObject = object as DartObjectImpl;
    return type == dartObject.type && _state == dartObject._state;
  }

  /**
   * Return the result of invoking the '+' operator on this object with the
   * given [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl add(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.add(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    } else if (result is StringState) {
      return new DartObjectImpl(typeProvider.stringType, result);
    }
    // We should never get here.
    throw new IllegalStateException("add returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '&' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl bitAnd(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.bitAnd(rightOperand._state));

  /**
   * Return the result of invoking the '~' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl bitNot(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.intType, _state.bitNot());

  /**
   * Return the result of invoking the '|' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl bitOr(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.bitOr(rightOperand._state));

  /**
   * Return the result of invoking the '^' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl bitXor(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.bitXor(rightOperand._state));

  /**
   * Return the result of invoking the ' ' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl concatenate(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.stringType, _state.concatenate(rightOperand._state));

  /**
   * Return the result of applying boolean conversion to this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl convertToBool(TypeProvider typeProvider) {
    InterfaceType boolType = typeProvider.boolType;
    if (identical(type, boolType)) {
      return this;
    }
    return new DartObjectImpl(boolType, _state.convertToBool());
  }

  /**
   * Return the result of invoking the '/' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for
   * an object of this kind.
   */
  DartObjectImpl divide(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.divide(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("divide returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl equalEqual(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (type != rightOperand.type) {
      String typeName = type.name;
      if (!(typeName == "bool" ||
          typeName == "double" ||
          typeName == "int" ||
          typeName == "num" ||
          typeName == "String" ||
          typeName == "Null" ||
          type.isDynamic)) {
        throw new EvaluationException(
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
      }
    }
    return new DartObjectImpl(
        typeProvider.boolType, _state.equalEqual(rightOperand._state));
  }

  @override
  DartObject getField(String name) {
    if (_state is GenericState) {
      return (_state as GenericState).fields[name];
    }
    return null;
  }

  /**
   * Return the result of invoking the '&gt;' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl greaterThan(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.greaterThan(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl greaterThanOrEqual(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(typeProvider.boolType,
          _state.greaterThanOrEqual(rightOperand._state));

  /**
   * Return the result of invoking the '~/' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl integerDivide(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.integerDivide(rightOperand._state));

  /**
   * Return the result of invoking the identical function on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   */
  DartObjectImpl isIdentical(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    return new DartObjectImpl(
        typeProvider.boolType, _state.isIdentical(rightOperand._state));
  }

  /**
   * Return the result of invoking the '&lt;' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lessThan(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.lessThan(rightOperand._state));

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lessThanOrEqual(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.lessThanOrEqual(rightOperand._state));

  /**
   * Return the result of invoking the '&&' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl logicalAnd(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.logicalAnd(rightOperand._state));

  /**
   * Return the result of invoking the '!' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl logicalNot(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.boolType, _state.logicalNot());

  /**
   * Return the result of invoking the '||' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl logicalOr(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.logicalOr(rightOperand._state));

  /**
   * Return the result of invoking the '-' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl minus(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.minus(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("minus returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '-' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl negated(TypeProvider typeProvider) {
    InstanceState result = _state.negated();
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("negated returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '!=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl notEqual(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (type != rightOperand.type) {
      String typeName = type.name;
      if (typeName != "bool" &&
          typeName != "double" &&
          typeName != "int" &&
          typeName != "num" &&
          typeName != "String") {
        return new DartObjectImpl(typeProvider.boolType, BoolState.TRUE_STATE);
      }
    }
    return new DartObjectImpl(typeProvider.boolType,
        _state.equalEqual(rightOperand._state).logicalNot());
  }

  /**
   * Return the result of converting this object to a 'String'. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the object cannot be converted to a
   * 'String'.
   */
  DartObjectImpl performToString(TypeProvider typeProvider) {
    InterfaceType stringType = typeProvider.stringType;
    if (identical(type, stringType)) {
      return this;
    }
    return new DartObjectImpl(stringType, _state.convertToString());
  }

  /**
   * Return the result of invoking the '%' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl remainder(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.remainder(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException(
        "remainder returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl shiftLeft(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.shiftLeft(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl shiftRight(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.shiftRight(rightOperand._state));

  /**
   * Return the result of invoking the 'length' getter on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl stringLength(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.intType, _state.stringLength());

  /**
   * Return the result of invoking the '*' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl times(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.times(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("times returned a ${result.runtimeType}");
  }

  @override
  bool toBoolValue() {
    if (_state is BoolState) {
      return (_state as BoolState).value;
    }
    return null;
  }

  @override
  double toDoubleValue() {
    if (_state is DoubleState) {
      return (_state as DoubleState).value;
    }
    return null;
  }

  @override
  int toIntValue() {
    if (_state is IntState) {
      return (_state as IntState).value;
    }
    return null;
  }

  @override
  List<DartObject> toListValue() {
    if (_state is ListState) {
      return (_state as ListState)._elements;
    }
    return null;
  }

  @override
  Map<DartObject, DartObject> toMapValue() {
    if (_state is MapState) {
      return (_state as MapState)._entries;
    }
    return null;
  }

  @override
  String toString() => "${type.displayName} ($_state)";

  @override
  String toStringValue() {
    if (_state is StringState) {
      return (_state as StringState).value;
    }
    return null;
  }

  @override
  String toSymbolValue() {
    if (_state is SymbolState) {
      return (_state as SymbolState).value;
    }
    return null;
  }

  @override
  DartType toTypeValue() {
    if (_state is TypeState) {
      Element element = (_state as TypeState)._element;
      if (element is TypeDefiningElement) {
        return element.type;
      }
    }
    return null;
  }
}

/**
 * An object used to provide access to the values of variables that have been
 * defined on the command line using the `-D` option.
 */
class DeclaredVariables {
  /**
   * A table mapping the names of declared variables to their values.
   */
  HashMap<String, String> _declaredVariables = new HashMap<String, String>();

  /**
   * Define a variable with the given [name] to have the given [value].
   */
  void define(String name, String value) {
    _declaredVariables[name] = value;
  }

  /**
   * Return the value of the variable with the given [name] interpreted as a
   * 'boolean' value. If the variable is not defined (or [name] is `null`), a
   * DartObject representing "unknown" is returned. If the value cannot be
   * parsed as a boolean, a DartObject representing 'null' is returned. The
   * [typeProvider] is the type provider used to find the type 'bool'.
   */
  DartObject getBool(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    }
    if (value == "true") {
      return new DartObjectImpl(typeProvider.boolType, BoolState.TRUE_STATE);
    } else if (value == "false") {
      return new DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE);
    }
    return new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
  }

  /**
   * Return the value of the variable with the given [name] interpreted as an
   * integer value. If the variable is not defined (or [name] is `null`), a
   * DartObject representing "unknown" is returned. If the value cannot be
   * parsed as an integer, a DartObject representing 'null' is returned.
   */
  DartObject getInt(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(typeProvider.intType, IntState.UNKNOWN_VALUE);
    }
    int bigInteger;
    try {
      bigInteger = int.parse(value);
    } on FormatException {
      return new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
    }
    return new DartObjectImpl(typeProvider.intType, new IntState(bigInteger));
  }

  /**
   * Return the value of the variable with the given [name] interpreted as a
   * String value, or `null` if the variable is not defined. Return the value of
   * the variable with the given name interpreted as a String value. If the
   * variable is not defined (or [name] is `null`), a DartObject representing
   * "unknown" is returned. The [typeProvider] is the type provider used to find
   * the type 'String'.
   */
  DartObject getString(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(
          typeProvider.stringType, StringState.UNKNOWN_VALUE);
    }
    return new DartObjectImpl(typeProvider.stringType, new StringState(value));
  }
}

/**
 * The state of an object representing a double.
 */
class DoubleState extends NumState {
  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static DoubleState UNKNOWN_VALUE = new DoubleState(null);

  /**
   * The value of this instance.
   */
  final double value;

  /**
   * Initialize a newly created state to represent a double with the given
   * [value].
   */
  DoubleState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "double";

  @override
  bool operator ==(Object object) =>
      object is DoubleState && (value == object.value);

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value + rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value + rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value / rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value / rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value > rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value > rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value >= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value >= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      double result = value / rightValue.toDouble();
      return new IntState(result.toInt());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      double result = value / rightValue;
      return new IntState(result.toInt());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return IntState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue.toDouble());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value < rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value < rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value <= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value <= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value - rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value - rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new DoubleState(-(value));
  }

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value % rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value % rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value * rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value * rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * The state of an object representing a Dart object for which there is no type
 * information.
 */
class DynamicState extends InstanceState {
  /**
   * The unique instance of this class.
   */
  static DynamicState DYNAMIC_STATE = new DynamicState();

  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  String get typeName => "dynamic";

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState bitNot() => IntState.UNKNOWN_VALUE;

  @override
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    return StringState.UNKNOWN_VALUE;
  }

  @override
  BoolState convertToBool() => BoolState.UNKNOWN_VALUE;

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState logicalNot() => BoolState.UNKNOWN_VALUE;

  @override
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  NumState negated() => NumState.UNKNOWN_VALUE;

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  /**
   * Return an object representing an unknown numeric value whose type is based
   * on the type of the [rightOperand].
   */
  NumState _unknownNum(InstanceState rightOperand) {
    if (rightOperand is IntState) {
      return IntState.UNKNOWN_VALUE;
    } else if (rightOperand is DoubleState) {
      return DoubleState.UNKNOWN_VALUE;
    }
    return NumState.UNKNOWN_VALUE;
  }
}

/**
 * A run-time exception that would be thrown during the evaluation of Dart code.
 */
class EvaluationException extends JavaException {
  /**
   * The error code associated with the exception.
   */
  final ErrorCode errorCode;

  /**
   * Initialize a newly created exception to have the given [errorCode].
   */
  EvaluationException(this.errorCode);
}

/**
 * The result of attempting to evaluate an expression.
 */
class EvaluationResult {
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
  List<AnalysisError> get errors =>
      _errors == null ? AnalysisError.NO_ERRORS : _errors;

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
    this._errors = errors == null ? <AnalysisError>[] : errors;
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

/**
 * The state of an object representing a function.
 */
class FunctionState extends InstanceState {
  /**
   * The element representing the function being modeled.
   */
  final ExecutableElement _element;

  /**
   * Initialize a newly created state to represent the function with the given
   * [element].
   */
  FunctionState(this._element);

  @override
  int get hashCode => _element == null ? 0 : _element.hashCode;

  @override
  String get typeName => "Function";

  @override
  bool operator ==(Object object) =>
      object is FunctionState && (_element == object._element);

  @override
  StringState convertToString() {
    if (_element == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_element.name);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (_element == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is FunctionState) {
      ExecutableElement rightElement = rightOperand._element;
      if (rightElement == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(_element == rightElement);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() => _element == null ? "-unknown-" : _element.name;
}

/**
 * The state of an object representing a Dart object for which there is no more
 * specific state.
 */
class GenericState extends InstanceState {
  /**
   * Pseudo-field that we use to represent fields in the superclass.
   */
  static String SUPERCLASS_FIELD = "(super)";

  /**
   * A state that can be used to represent an object whose state is not known.
   */
  static GenericState UNKNOWN_VALUE =
      new GenericState(new HashMap<String, DartObjectImpl>());

  /**
   * The values of the fields of this instance.
   */
  final HashMap<String, DartObjectImpl> _fieldMap;

  /**
   * Initialize a newly created state to represent a newly created object. The
   * [fieldMap] contains the values of the fields of the instance.
   */
  GenericState(this._fieldMap);

  @override
  HashMap<String, DartObjectImpl> get fields => _fieldMap;

  @override
  int get hashCode {
    int hashCode = 0;
    for (DartObjectImpl value in _fieldMap.values) {
      hashCode += value.hashCode;
    }
    return hashCode;
  }

  @override
  bool get isUnknown => identical(this, UNKNOWN_VALUE);

  @override
  String get typeName => "user defined type";

  @override
  bool operator ==(Object object) {
    if (object is! GenericState) {
      return false;
    }
    GenericState state = object as GenericState;
    HashSet<String> otherFields =
        new HashSet<String>.from(state._fieldMap.keys.toSet());
    for (String fieldName in _fieldMap.keys.toSet()) {
      if (_fieldMap[fieldName] != state._fieldMap[fieldName]) {
        return false;
      }
      otherFields.remove(fieldName);
    }
    for (String fieldName in otherFields) {
      if (state._fieldMap[fieldName] != _fieldMap[fieldName]) {
        return false;
      }
    }
    return true;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    List<String> fieldNames = _fieldMap.keys.toList();
    fieldNames.sort();
    bool first = true;
    for (String fieldName in fieldNames) {
      if (first) {
        first = false;
      } else {
        buffer.write('; ');
      }
      buffer.write(fieldName);
      buffer.write(' = ');
      buffer.write(_fieldMap[fieldName]);
    }
    return buffer.toString();
  }
}

/**
 * The state of an object representing a Dart object.
 */
abstract class InstanceState {
  /**
   * If this represents a generic dart object, return a map from its field names
   * to their values. Otherwise return null.
   */
  HashMap<String, DartObjectImpl> get fields => null;

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   */
  bool get isBool => false;

  /**
   * Return `true` if this object represents an object whose type is either
   * 'bool', 'num', 'String', or 'Null'.
   */
  bool get isBoolNumStringOrNull => false;

  /**
   * Return `true` if this object represents an unknown value.
   */
  bool get isUnknown => false;

  /**
   * Return the name of the type of this value.
   */
  String get typeName;

  /**
   * Return the result of invoking the '+' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  InstanceState add(InstanceState rightOperand) {
    if (this is StringState && rightOperand is StringState) {
      return concatenate(rightOperand);
    }
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean value.
   */
  void assertBool(InstanceState state) {
    if (!(state is BoolState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean,
   * numeric, string or null value.
   */
  void assertBoolNumStringOrNull(InstanceState state) {
    if (!(state is BoolState ||
        state is DoubleState ||
        state is IntState ||
        state is NumState ||
        state is StringState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(
          CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent an integer or
   * null value.
   */
  void assertIntOrNull(InstanceState state) {
    if (!(state is IntState ||
        state is NumState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean,
   * numeric, string or null value.
   */
  void assertNumOrNull(InstanceState state) {
    if (!(state is DoubleState ||
        state is IntState ||
        state is NumState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a String value.
   */
  void assertString(InstanceState state) {
    if (!(state is StringState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }

  /**
   * Return the result of invoking the '&' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '~' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitNot() {
    assertIntOrNull(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '|' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '^' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the ' ' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of applying boolean conversion to this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState convertToBool() => BoolState.FALSE_STATE;

  /**
   * Return the result of converting this object to a String.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  StringState convertToString();

  /**
   * Return the result of invoking the '/' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState equalEqual(InstanceState rightOperand);

  /**
   * Return the result of invoking the '&gt;' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '~/' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the identical function on this object with
   * the [rightOperand].
   */
  BoolState isIdentical(InstanceState rightOperand);

  /**
   * Return the result of invoking the '&lt;' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&&' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    return BoolState.FALSE_STATE;
  }

  /**
   * Return the result of invoking the '!' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalNot() {
    assertBool(this);
    return BoolState.TRUE_STATE;
  }

  /**
   * Return the result of invoking the '||' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  /**
   * Return the result of invoking the '-' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '-' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState negated() {
    assertNumOrNull(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '%' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with
   * the [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with
   * the [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the 'length' getter on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState stringLength() {
    assertString(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '*' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }
}

/**
 * The state of an object representing an int.
 */
class IntState extends NumState {
  /**
   * A state that can be used to represent an int whose value is not known.
   */
  static IntState UNKNOWN_VALUE = new IntState(null);

  /**
   * The value of this instance.
   */
  final int value;

  /**
   * Initialize a newly created state to represent an int with the given
   * [value].
   */
  IntState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "int";

  @override
  bool operator ==(Object object) =>
      object is IntState && (value == object.value);

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value + rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() + rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value & rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new IntState(~value);
  }

  @override
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value | rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value ^ rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return DoubleState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      } else {
        return new DoubleState(value.toDouble() / rightValue.toDouble());
      }
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() / rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return DoubleState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) > 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() > rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) >= 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() >= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw new EvaluationException(
            CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
      }
      return new IntState(value ~/ rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      double result = value.toDouble() / rightValue;
      return new IntState(result.toInt());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(rightValue == value.toDouble());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) < 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() < rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) <= 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() <= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value - rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() - rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new IntState(-value);
  }

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        return new DoubleState(value.toDouble() % rightValue.toDouble());
      }
      return new IntState(value.remainder(rightValue));
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() % rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value << rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value >> rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value * rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() * rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * The state of an object representing a list.
 */
class ListState extends InstanceState {
  /**
   * The elements of the list.
   */
  final List<DartObjectImpl> _elements;

  /**
   * Initialize a newly created state to represent a list with the given
   * [elements].
   */
  ListState(this._elements);

  @override
  int get hashCode {
    int value = 0;
    int count = _elements.length;
    for (int i = 0; i < count; i++) {
      value = (value << 3) ^ _elements[i].hashCode;
    }
    return value;
  }

  @override
  String get typeName => "List";

  @override
  bool operator ==(Object object) {
    if (object is! ListState) {
      return false;
    }
    List<DartObjectImpl> otherElements = (object as ListState)._elements;
    int count = _elements.length;
    if (otherElements.length != count) {
      return false;
    } else if (count == 0) {
      return true;
    }
    for (int i = 0; i < count; i++) {
      if (_elements[i] != otherElements[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('[');
    bool first = true;
    _elements.forEach((DartObjectImpl element) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(element);
    });
    buffer.write(']');
    return buffer.toString();
  }
}

/**
 * The state of an object representing a map.
 */
class MapState extends InstanceState {
  /**
   * The entries in the map.
   */
  final HashMap<DartObjectImpl, DartObjectImpl> _entries;

  /**
   * Initialize a newly created state to represent a map with the given
   * [entries].
   */
  MapState(this._entries);

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl key in _entries.keys.toSet()) {
      value = (value << 3) ^ key.hashCode;
    }
    return value;
  }

  @override
  String get typeName => "Map";

  @override
  bool operator ==(Object object) {
    if (object is! MapState) {
      return false;
    }
    HashMap<DartObjectImpl, DartObjectImpl> otherElements =
        (object as MapState)._entries;
    int count = _entries.length;
    if (otherElements.length != count) {
      return false;
    } else if (count == 0) {
      return true;
    }
    for (DartObjectImpl key in _entries.keys) {
      DartObjectImpl value = _entries[key];
      DartObjectImpl otherValue = otherElements[key];
      if (value != otherValue) {
        return false;
      }
    }
    return true;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('{');
    bool first = true;
    _entries.forEach((DartObjectImpl key, DartObjectImpl value) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(key);
      buffer.write(' = ');
      buffer.write(value);
    });
    buffer.write('}');
    return buffer.toString();
  }
}

/**
 * The state of an object representing the value 'null'.
 */
class NullState extends InstanceState {
  /**
   * An instance representing the boolean value 'null'.
   */
  static NullState NULL_STATE = new NullState();

  @override
  int get hashCode => 0;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  String get typeName => "Null";

  @override
  bool operator ==(Object object) => object is NullState;

  @override
  BoolState convertToBool() {
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() => new StringState("null");

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(rightOperand is NullState);
  }

  @override
  BoolState logicalNot() {
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => "null";
}

/**
 * The state of an object representing a number of an unknown type (a 'num').
 */
class NumState extends InstanceState {
  /**
   * A state that can be used to represent a number whose value is not known.
   */
  static NumState UNKNOWN_VALUE = new NumState();

  @override
  int get hashCode => 7;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => identical(this, UNKNOWN_VALUE);

  @override
  String get typeName => "num";

  @override
  bool operator ==(Object object) => object is NumState;

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return DoubleState.UNKNOWN_VALUE;
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw new EvaluationException(
            CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
      }
    } else if (rightOperand is DynamicState) {
      return IntState.UNKNOWN_VALUE;
    }
    return IntState.UNKNOWN_VALUE;
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  NumState negated() => UNKNOWN_VALUE;

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  String toString() => "-unknown-";
}

/**
 * An object used to add reference information for a given variable to the
 * bi-directional mapping used to order the evaluation of constants.
 */
class ReferenceFinder extends RecursiveAstVisitor<Object> {
  /**
   * The callback which should be used to report any dependencies that were
   * found.
   */
  final ReferenceFinderCallback _callback;

  /**
   * Initialize a newly created reference finder to find references from a given
   * variable to other variables and to add those references to the given graph.
   * The [_callback] will be invoked for every dependency found.
   */
  ReferenceFinder(this._callback);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      ConstructorElement constructor = _getConstructorImpl(node.staticElement);
      if (constructor != null) {
        _callback(constructor);
      }
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitLabel(Label node) {
    // We are visiting the "label" part of a named expression in a function
    // call (presumably a constructor call), e.g. "const C(label: ...)".  We
    // don't want to visit the SimpleIdentifier for the label because that's a
    // reference to a function parameter that needs to be filled in; it's not a
    // constant whose value we depend on.
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    super.visitRedirectingConstructorInvocation(node);
    ConstructorElement target = _getConstructorImpl(node.staticElement);
    if (target != null) {
      _callback(target);
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElement && element.isConst) {
      _callback(element);
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    super.visitSuperConstructorInvocation(node);
    ConstructorElement constructor = _getConstructorImpl(node.staticElement);
    if (constructor != null) {
      _callback(constructor);
    }
    return null;
  }
}

/**
 * The state of an object representing a string.
 */
class StringState extends InstanceState {
  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static StringState UNKNOWN_VALUE = new StringState(null);

  /**
   * The value of this instance.
   */
  final String value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  StringState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "String";

  @override
  bool operator ==(Object object) =>
      object is StringState && (value == object.value);

  @override
  StringState concatenate(InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new StringState("$value$rightValue");
    } else if (rightOperand is DynamicState) {
      return UNKNOWN_VALUE;
    }
    return super.concatenate(rightOperand);
  }

  @override
  StringState convertToString() => this;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  IntState stringLength() {
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    return new IntState(value.length);
  }

  @override
  String toString() => value == null ? "-unknown-" : "'$value'";
}

/**
 * The state of an object representing a symbol.
 */
class SymbolState extends InstanceState {
  /**
   * The value of this instance.
   */
  final String value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  SymbolState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  String get typeName => "Symbol";

  @override
  bool operator ==(Object object) =>
      object is SymbolState && (value == object.value);

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is SymbolState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() => value == null ? "-unknown-" : "#$value";
}

/**
 * The state of an object representing a type.
 */
class TypeState extends InstanceState {
  /**
   * The element representing the type being modeled.
   */
  final Element _element;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  TypeState(this._element);

  @override
  int get hashCode => _element == null ? 0 : _element.hashCode;

  @override
  String get typeName => "Type";

  @override
  bool operator ==(Object object) =>
      object is TypeState && (_element == object._element);

  @override
  StringState convertToString() {
    if (_element == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_element.name);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (_element == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is TypeState) {
      Element rightElement = rightOperand._element;
      if (rightElement == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(_element == rightElement);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() => _element == null ? "-unknown-" : _element.name;
}

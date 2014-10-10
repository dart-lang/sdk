// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.constant;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart' show ObjectUtilities;
import 'source.dart' show Source;
import 'error.dart';
import 'scanner.dart' show Token, TokenType;
import 'ast.dart';
import 'element.dart';
import 'resolver.dart' show TypeProvider;
import 'engine.dart' show AnalysisEngine, RecordingErrorListener;
import 'utilities_dart.dart' show ParameterKind;
import 'utilities_collection.dart';

/**
 * Instances of the class `BoolState` represent the state of an object representing a boolean
 * value.
 */
class BoolState extends InstanceState {
  /**
   * The value of this instance.
   */
  final bool value;

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
   * Return the boolean state representing the given boolean value.
   *
   * @param value the value to be represented
   * @return the boolean state representing the given boolean value
   */
  static BoolState from(bool value) => value ? BoolState.TRUE_STATE : BoolState.FALSE_STATE;

  /**
   * Initialize a newly created state to represent the given value.
   *
   * @param value the value of this instance
   */
  BoolState(this.value);

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
  bool operator ==(Object object) => object is BoolState && identical(value, object.value);

  @override
  String get typeName => "bool";

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => value == null ? 0 : (value ? 2 : 3);

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   *
   * @return `true` if this object represents a boolean value
   */
  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

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
}

/**
 * Instances of the class `ConstantEvaluator` evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to <b>null</b>.
 * * A literal symbol.
 * * <b>null</b>.
 * * A qualified reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, class or type alias.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static method.
 * * A parenthesized expression <i>(e)</i> where <i>e</i> is a constant expression.
 * * An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i> where
 * <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions and <i>identical()</i> is
 * statically bound to the predefined dart function <i>identical()</i> discussed above.
 * * An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i> or <i>e<sub>1</sub>
 * != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions
 * that evaluate to a numeric, string or boolean value.
 * * An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp; e<sub>2</sub></i> or
 * <i>e<sub>1</sub> || e<sub>2</sub></i>, where <i>e</i>, <i>e1</sub></i> and <i>e2</sub></i> are
 * constant expressions that evaluate to a boolean value.
 * * An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^ e<sub>2</sub></i>,
 * <i>e<sub>1</sub> &amp; e<sub>2</sub></i>, <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub>
 * &gt;&gt; e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where <i>e</i>,
 * <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions that evaluate to an
 * integer value or to <b>null</b>.
 * * An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> + e<sub>2</sub></i>,
 * <i>e<sub>1</sub> -e<sub>2</sub></i>, <i>e<sub>1</sub> * e<sub>2</sub></i>, <i>e<sub>1</sub> /
 * e<sub>2</sub></i>, <i>e<sub>1</sub> ~/ e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;
 * e<sub>2</sub></i>, <i>e<sub>1</sub> &lt; e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;=
 * e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or <i>e<sub>1</sub> %
 * e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 * expressions that evaluate to a numeric value or to <b>null</b>.
 * * An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> where
 * <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and <i>e<sub>3</sub></i> are constant expressions, and
 * <i>e<sub>1</sub></i> evaluates to a boolean value.
 * </blockquote>
 */
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
   * Initialize a newly created evaluator to evaluate expressions in the given source.
   *
   * @param source the source containing the expression(s) that will be evaluated
   * @param typeProvider the type provider used to access known types
   */
  ConstantEvaluator(this._source, this._typeProvider);

  EvaluationResult evaluate(Expression expression) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
    DartObjectImpl result = expression.accept(new ConstantVisitor.con1(_typeProvider, errorReporter));
    if (result != null) {
      return EvaluationResult.forValue(result);
    }
    return EvaluationResult.forErrors(errorListener.errors);
  }
}

/**
 * Instances of the class `ConstantFinder` are used to traverse the AST structures of all of
 * the compilation units being resolved and build a table mapping constant variable elements to the
 * declarations of those variables.
 */
class ConstantFinder extends RecursiveAstVisitor<Object> {
  /**
   * A table mapping constant variable elements to the declarations of those variables.
   */
  final HashMap<VariableElement, VariableDeclaration> variableMap = new HashMap<VariableElement, VariableDeclaration>();

  /**
   * A table mapping constant constructors to the declarations of those constructors.
   */
  final HashMap<ConstructorElement, ConstructorDeclaration> constructorMap = new HashMap<ConstructorElement, ConstructorDeclaration>();

  /**
   * A collection of constant constructor invocations.
   */
  final List<InstanceCreationExpression> constructorInvocations = new List<InstanceCreationExpression>();

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    if (node.constKeyword != null) {
      ConstructorElement element = node.element;
      if (element != null) {
        constructorMap[element] = node;
      }
    }
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    if (node.isConst) {
      constructorInvocations.add(node);
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    if (initializer != null && node.isConst) {
      VariableElement element = node.element;
      if (element != null) {
        variableMap[element] = node;
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ConstantValueComputer` compute the values of constant variables and
 * constant constructor invocations in one or more compilation units. The expected usage pattern is
 * for the compilation units to be added to this computer using the method
 * [add] and then for the method [computeValues] to be invoked
 * exactly once. Any use of an instance after invoking the method [computeValues] will
 * result in unpredictable behavior.
 */
class ConstantValueComputer {
  /**
   * Parameter to "fromEnvironment" methods that denotes the default value.
   */
  static String _DEFAULT_VALUE_PARAM = "defaultValue";

  /**
   * Source of RegExp matching declarable operator names. From sdk/lib/internal/symbol.dart.
   */
  static String _OPERATOR_RE = "(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)";

  /**
   * Source of RegExp matching any public identifier. From sdk/lib/internal/symbol.dart.
   */
  static String _PUBLIC_IDENTIFIER_RE = "(?!${ConstantValueComputer._RESERVED_WORD_RE}\\b(?!\\\$))[a-zA-Z\$][\\w\$]*";

  /**
   * Source of RegExp matching Dart reserved words. From sdk/lib/internal/symbol.dart.
   */
  static String _RESERVED_WORD_RE = "(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|v(?:ar|oid)|w(?:hile|ith))";

  /**
   * RegExp that validates a non-empty non-private symbol. From sdk/lib/internal/symbol.dart.
   */
  static RegExp _PUBLIC_SYMBOL_PATTERN = new RegExp("^(?:${ConstantValueComputer._OPERATOR_RE}\$|${_PUBLIC_IDENTIFIER_RE}(?:=?\$|[.](?!\$)))+?\$");

  /**
   * Determine whether the given string is a valid name for a public symbol (i.e. whether it is
   * allowed for a call to the Symbol constructor).
   */
  static bool isValidPublicSymbol(String name) => name.isEmpty || name == "void" || new JavaPatternMatcher(_PUBLIC_SYMBOL_PATTERN, name).matches();

  /**
   * The type provider used to access the known types.
   */
  TypeProvider typeProvider;

  /**
   * The object used to find constant variables and constant constructor invocations in the
   * compilation units that were added.
   */
  ConstantFinder _constantFinder = new ConstantFinder();

  /**
   * A graph in which the nodes are the constants, and the edges are from each constant to the other
   * constants that are referenced by it.
   */
  DirectedGraph<AstNode> referenceGraph = new DirectedGraph<AstNode>();

  /**
   * A table mapping constant variables to the declarations of those variables.
   */
  HashMap<VariableElement, VariableDeclaration> _variableDeclarationMap;

  /**
   * A table mapping constant constructors to the declarations of those constructors.
   */
  HashMap<ConstructorElement, ConstructorDeclaration> constructorDeclarationMap;

  /**
   * A collection of constant constructor invocations.
   */
  List<InstanceCreationExpression> _constructorInvocations;

  /**
   * The set of variables declared on the command line using '-D'.
   */
  final DeclaredVariables _declaredVariables;

  /**
   * Initialize a newly created constant value computer.
   *
   * @param typeProvider the type provider used to access known types
   * @param declaredVariables the set of variables declared on the command line using '-D'
   */
  ConstantValueComputer(TypeProvider typeProvider, this._declaredVariables) {
    this.typeProvider = typeProvider;
  }

  /**
   * Add the constants in the given compilation unit to the list of constants whose value needs to
   * be computed.
   *
   * @param unit the compilation unit defining the constants to be added
   */
  void add(CompilationUnit unit) {
    unit.accept(_constantFinder);
  }

  /**
   * Compute values for all of the constants in the compilation units that were added.
   */
  void computeValues() {
    _variableDeclarationMap = _constantFinder.variableMap;
    constructorDeclarationMap = _constantFinder.constructorMap;
    _constructorInvocations = _constantFinder.constructorInvocations;
    for (MapEntry<VariableElement, VariableDeclaration> entry in getMapEntrySet(_variableDeclarationMap)) {
      VariableDeclaration declaration = entry.getValue();
      ReferenceFinder referenceFinder = new ReferenceFinder(declaration, referenceGraph, _variableDeclarationMap, constructorDeclarationMap);
      referenceGraph.addNode(declaration);
      declaration.initializer.accept(referenceFinder);
    }
    for (MapEntry<ConstructorElement, ConstructorDeclaration> entry in getMapEntrySet(constructorDeclarationMap)) {
      ConstructorDeclaration declaration = entry.getValue();
      ReferenceFinder referenceFinder = new ReferenceFinder(declaration, referenceGraph, _variableDeclarationMap, constructorDeclarationMap);
      referenceGraph.addNode(declaration);
      bool superInvocationFound = false;
      NodeList<ConstructorInitializer> initializers = declaration.initializers;
      for (ConstructorInitializer initializer in initializers) {
        if (initializer is SuperConstructorInvocation) {
          superInvocationFound = true;
        }
        initializer.accept(referenceFinder);
      }
      if (!superInvocationFound) {
        // No explicit superconstructor invocation found, so we need to manually insert
        // a reference to the implicit superconstructor.
        InterfaceType superclass = (entry.getKey().returnType as InterfaceType).superclass;
        if (superclass != null && !superclass.isObject) {
          ConstructorElement unnamedConstructor = superclass.element.unnamedConstructor;
          ConstructorDeclaration superConstructorDeclaration = findConstructorDeclaration(unnamedConstructor);
          if (superConstructorDeclaration != null) {
            referenceGraph.addEdge(declaration, superConstructorDeclaration);
          }
        }
      }
      for (FormalParameter parameter in declaration.parameters.parameters) {
        referenceGraph.addNode(parameter);
        referenceGraph.addEdge(declaration, parameter);
        if (parameter is DefaultFormalParameter) {
          Expression defaultValue = parameter.defaultValue;
          if (defaultValue != null) {
            ReferenceFinder parameterReferenceFinder = new ReferenceFinder(parameter, referenceGraph, _variableDeclarationMap, constructorDeclarationMap);
            defaultValue.accept(parameterReferenceFinder);
          }
        }
      }
    }
    for (InstanceCreationExpression expression in _constructorInvocations) {
      referenceGraph.addNode(expression);
      ConstructorElement constructor = expression.staticElement;
      if (constructor == null) {
        continue;
      }
      constructor = _followConstantRedirectionChain(constructor);
      ConstructorDeclaration declaration = findConstructorDeclaration(constructor);
      // An instance creation expression depends both on the constructor and the arguments passed
      // to it.
      ReferenceFinder referenceFinder = new ReferenceFinder(expression, referenceGraph, _variableDeclarationMap, constructorDeclarationMap);
      if (declaration != null) {
        referenceGraph.addEdge(expression, declaration);
      }
      expression.argumentList.accept(referenceFinder);
    }
    List<List<AstNode>> topologicalSort = referenceGraph.computeTopologicalSort();
    for (List<AstNode> constantsInCycle in topologicalSort) {
      if (constantsInCycle.length == 1) {
        _computeValueFor(constantsInCycle[0]);
      } else {
        for (AstNode constant in constantsInCycle) {
          _generateCycleError(constantsInCycle, constant);
        }
      }
    }
  }

  /**
   * This method is called just before computing the constant value associated with an AST node.
   * Unit tests will override this method to introduce additional error checking.
   */
  void beforeComputeValue(AstNode constNode) {
  }

  /**
   * This method is called just before getting the constant initializers associated with a
   * constructor AST node. Unit tests will override this method to introduce additional error
   * checking.
   */
  void beforeGetConstantInitializers(ConstructorElement constructor) {
  }

  /**
   * This method is called just before getting a parameter's default value. Unit tests will override
   * this method to introduce additional error checking.
   */
  void beforeGetParameterDefault(ParameterElement parameter) {
  }

  /**
   * Create the ConstantVisitor used to evaluate constants. Unit tests will override this method to
   * introduce additional error checking.
   */
  ConstantVisitor createConstantVisitor(ErrorReporter errorReporter) => new ConstantVisitor.con1(typeProvider, errorReporter);

  ConstructorDeclaration findConstructorDeclaration(ConstructorElement constructor) => constructorDeclarationMap[_getConstructorBase(constructor)];

  /**
   * Check that the arguments to a call to fromEnvironment() are correct.
   *
   * @param arguments the AST nodes of the arguments.
   * @param argumentValues the values of the unnamed arguments.
   * @param namedArgumentValues the values of the named arguments.
   * @param expectedDefaultValueType the allowed type of the "defaultValue" parameter (if present).
   *          Note: "defaultValue" is always allowed to be null.
   * @return true if the arguments are correct, false if there is an error.
   */
  bool _checkFromEnvironmentArguments(NodeList<Expression> arguments, List<DartObjectImpl> argumentValues, HashMap<String, DartObjectImpl> namedArgumentValues, InterfaceType expectedDefaultValueType) {
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
      if (!((arguments[1] as NamedExpression).name.label.name == _DEFAULT_VALUE_PARAM)) {
        return false;
      }
      ParameterizedType defaultValueType = namedArgumentValues[_DEFAULT_VALUE_PARAM].type;
      if (!(identical(defaultValueType, expectedDefaultValueType) || identical(defaultValueType, typeProvider.nullType))) {
        return false;
      }
    }
    return true;
  }

  /**
   * Check that the arguments to a call to Symbol() are correct.
   *
   * @param arguments the AST nodes of the arguments.
   * @param argumentValues the values of the unnamed arguments.
   * @param namedArgumentValues the values of the named arguments.
   * @return true if the arguments are correct, false if there is an error.
   */
  bool _checkSymbolArguments(NodeList<Expression> arguments, List<DartObjectImpl> argumentValues, HashMap<String, DartObjectImpl> namedArgumentValues) {
    if (arguments.length != 1) {
      return false;
    }
    if (arguments[0] is NamedExpression) {
      return false;
    }
    if (!identical(argumentValues[0].type, typeProvider.stringType)) {
      return false;
    }
    String name = argumentValues[0].stringValue;
    return isValidPublicSymbol(name);
  }

  /**
   * Compute a value for the given constant.
   *
   * @param constNode the constant for which a value is to be computed
   */
  void _computeValueFor(AstNode constNode) {
    beforeComputeValue(constNode);
    if (constNode is VariableDeclaration) {
      VariableDeclaration declaration = constNode;
      Element element = declaration.element;
      RecordingErrorListener errorListener = new RecordingErrorListener();
      ErrorReporter errorReporter = new ErrorReporter(errorListener, element.source);
      DartObjectImpl dartObject = declaration.initializer.accept(createConstantVisitor(errorReporter));
      (element as VariableElementImpl).evaluationResult = new EvaluationResultImpl.con2(dartObject, errorListener.errors);
    } else if (constNode is InstanceCreationExpression) {
      InstanceCreationExpression expression = constNode;
      ConstructorElement constructor = expression.staticElement;
      if (constructor == null) {
        // Couldn't resolve the constructor so we can't compute a value.  No problem--the error
        // has already been reported.  But we still need to store an evaluation result.
        expression.evaluationResult = new EvaluationResultImpl.con1(null);
        return;
      }
      RecordingErrorListener errorListener = new RecordingErrorListener();
      CompilationUnit sourceCompilationUnit = expression.getAncestor((node) => node is CompilationUnit);
      ErrorReporter errorReporter = new ErrorReporter(errorListener, sourceCompilationUnit.element.source);
      ConstantVisitor constantVisitor = createConstantVisitor(errorReporter);
      DartObjectImpl result = _evaluateConstructorCall(constNode, expression.argumentList.arguments, constructor, constantVisitor, errorReporter);
      expression.evaluationResult = new EvaluationResultImpl.con2(result, errorListener.errors);
    } else if (constNode is ConstructorDeclaration) {
      ConstructorDeclaration declaration = constNode;
      NodeList<ConstructorInitializer> initializers = declaration.initializers;
      ConstructorElementImpl constructor = declaration.element as ConstructorElementImpl;
      constructor.constantInitializers = new ConstantValueComputer_InitializerCloner().cloneNodeList(initializers);
    } else if (constNode is FormalParameter) {
      if (constNode is DefaultFormalParameter) {
        DefaultFormalParameter parameter = constNode;
        ParameterElement element = parameter.element;
        Expression defaultValue = parameter.defaultValue;
        if (defaultValue != null) {
          RecordingErrorListener errorListener = new RecordingErrorListener();
          ErrorReporter errorReporter = new ErrorReporter(errorListener, element.source);
          DartObjectImpl dartObject = defaultValue.accept(createConstantVisitor(errorReporter));
          (element as ParameterElementImpl).evaluationResult = new EvaluationResultImpl.con2(dartObject, errorListener.errors);
        }
      }
    } else {
      // Should not happen.
      AnalysisEngine.instance.logger.logError("Constant value computer trying to compute the value of a node which is not a VariableDeclaration, InstanceCreationExpression, FormalParameter, or ConstructorDeclaration");
      return;
    }
  }

  /**
   * Evaluate a call to fromEnvironment() on the bool, int, or String class.
   *
   * @param environmentValue Value fetched from the environment
   * @param builtInDefaultValue Value that should be used as the default if no "defaultValue"
   *          argument appears in [namedArgumentValues].
   * @param namedArgumentValues Named parameters passed to fromEnvironment()
   * @return A [DartObjectImpl] object corresponding to the evaluated result
   */
  DartObjectImpl _computeValueFromEnvironment(DartObject environmentValue, DartObjectImpl builtInDefaultValue, HashMap<String, DartObjectImpl> namedArgumentValues) {
    DartObjectImpl value = environmentValue as DartObjectImpl;
    if (value.isUnknown || value.isNull) {
      // The name either doesn't exist in the environment or we couldn't parse the corresponding
      // value.  If the code supplied an explicit default, use it.
      if (namedArgumentValues.containsKey(_DEFAULT_VALUE_PARAM)) {
        value = namedArgumentValues[_DEFAULT_VALUE_PARAM];
      } else if (value.isNull) {
        // The code didn't supply an explicit default.  The name exists in the environment but
        // we couldn't parse the corresponding value.  So use the built-in default value, because
        // this is what the VM does.
        value = builtInDefaultValue;
      } else {
        // The code didn't supply an explicit default.  The name doesn't exist in the environment.
        // The VM would use the built-in default value, but we don't want to do that for analysis
        // because it's likely to lead to cascading errors.  So just leave [value] in the unknown
        // state.
      }
    }
    return value;
  }

  DartObjectImpl _evaluateConstructorCall(AstNode node, NodeList<Expression> arguments, ConstructorElement constructor, ConstantVisitor constantVisitor, ErrorReporter errorReporter) {
    int argumentCount = arguments.length;
    List<DartObjectImpl> argumentValues = new List<DartObjectImpl>(argumentCount);
    List<Expression> argumentNodes = new List<Expression>(argumentCount);
    HashMap<String, DartObjectImpl> namedArgumentValues = new HashMap<String, DartObjectImpl>();
    HashMap<String, NamedExpression> namedArgumentNodes =
        new HashMap<String, NamedExpression>();
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        String name = argument.name.label.name;
        namedArgumentValues[name] = constantVisitor._valueOf(argument.expression);
        namedArgumentNodes[name] = argument;
        argumentValues[i] = constantVisitor.null2;
      } else {
        argumentValues[i] = constantVisitor._valueOf(argument);
        argumentNodes[i] = argument;
      }
    }
    constructor = _followConstantRedirectionChain(constructor);
    InterfaceType definingClass = constructor.returnType as InterfaceType;
    if (constructor.isFactory) {
      // We couldn't find a non-factory constructor.  See if it's because we reached an external
      // const factory constructor that we can emulate.
      if (constructor.name == "fromEnvironment") {
        if (!_checkFromEnvironmentArguments(arguments, argumentValues, namedArgumentValues, definingClass)) {
          errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node, []);
          return null;
        }
        String variableName = argumentCount < 1 ? null : argumentValues[0].stringValue;
        if (identical(definingClass, typeProvider.boolType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment = _declaredVariables.getBool(typeProvider, variableName);
          return _computeValueFromEnvironment(valueFromEnvironment, new DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE), namedArgumentValues);
        } else if (identical(definingClass, typeProvider.intType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment = _declaredVariables.getInt(typeProvider, variableName);
          return _computeValueFromEnvironment(valueFromEnvironment, new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE), namedArgumentValues);
        } else if (identical(definingClass, typeProvider.stringType)) {
          DartObject valueFromEnvironment;
          valueFromEnvironment = _declaredVariables.getString(typeProvider, variableName);
          return _computeValueFromEnvironment(valueFromEnvironment, new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE), namedArgumentValues);
        }
      } else if (constructor.name == "" && identical(definingClass, typeProvider.symbolType) && argumentCount == 1) {
        if (!_checkSymbolArguments(arguments, argumentValues, namedArgumentValues)) {
          errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node, []);
          return null;
        }
        String argumentValue = argumentValues[0].stringValue;
        return new DartObjectImpl(definingClass, new SymbolState(argumentValue));
      }
      // Either it's an external const factory constructor that we can't emulate, or an error
      // occurred (a cycle, or a const constructor trying to delegate to a non-const constructor).
      // In the former case, the best we can do is consider it an unknown value.  In the latter
      // case, the error has already been reported, so considering it an unknown value will
      // suppress further errors.
      return constantVisitor._validWithUnknownValue(definingClass);
    }
    beforeGetConstantInitializers(constructor);
    ConstructorElementImpl constructorBase = _getConstructorBase(constructor) as ConstructorElementImpl;
    List<ConstructorInitializer> initializers = constructorBase.constantInitializers;
    if (initializers == null) {
      // This can happen in some cases where there are compile errors in the code being analyzed
      // (for example if the code is trying to create a const instance using a non-const
      // constructor, or the node we're visiting is involved in a cycle).  The error has already
      // been reported, so consider it an unknown value to suppress further errors.
      return constantVisitor._validWithUnknownValue(definingClass);
    }
    HashMap<String, DartObjectImpl> fieldMap = new HashMap<String, DartObjectImpl>();
    HashMap<String, DartObjectImpl> parameterMap = new HashMap<String, DartObjectImpl>();
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
        // The parameter is an optional positional parameter for which no value was provided, so
        // use the default value.
        beforeGetParameterDefault(baseParameter);
        EvaluationResultImpl evaluationResult = (baseParameter as ParameterElementImpl).evaluationResult;
        if (evaluationResult == null) {
          // No default was provided, so the default value is null.
          argumentValue = constantVisitor.null2;
        } else if (evaluationResult.value != null) {
          argumentValue = evaluationResult.value;
        }
      }
      if (argumentValue != null) {
        if (!argumentValue.isNull && !argumentValue.type.isSubtypeOf(parameter.type)) {
          errorReporter.reportErrorForNode(
              CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
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
              if (!argumentValue.isNull &&
                  !argumentValue.type.isSubtypeOf(fieldType)) {
                errorReporter.reportErrorForNode(
                    CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
                    errorTarget,
                    [argumentValue.type, fieldType]);
              }
            }
            String fieldName = field.name;
            fieldMap[fieldName] = argumentValue;
          }
        } else {
          String name = baseParameter.name;
          parameterMap[name] = argumentValue;
        }
      }
    }
    ConstantVisitor initializerVisitor = new ConstantVisitor.con2(typeProvider, parameterMap, errorReporter);
    String superName = null;
    NodeList<Expression> superArguments = null;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = initializer;
        Expression initializerExpression = constructorFieldInitializer.expression;
        DartObjectImpl evaluationResult = initializerExpression.accept(initializerVisitor);
        if (evaluationResult != null) {
          String fieldName = constructorFieldInitializer.fieldName.name;
          fieldMap[fieldName] = evaluationResult;
        }
      } else if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation superConstructorInvocation = initializer;
        SimpleIdentifier name = superConstructorInvocation.constructorName;
        if (name != null) {
          superName = name.name;
        }
        superArguments = superConstructorInvocation.argumentList.arguments;
      }
    }
    // Evaluate explicit or implicit call to super().
    InterfaceType superclass = definingClass.superclass;
    if (superclass != null && !superclass.isObject) {
      ConstructorElement superConstructor = superclass.lookUpConstructor(superName, constructor.library);
      if (superConstructor != null) {
        if (superArguments == null) {
          superArguments = new NodeList<Expression>(null);
        }
        _evaluateSuperConstructorCall(node, fieldMap, superConstructor, superArguments, initializerVisitor, errorReporter);
      }
    }
    return new DartObjectImpl(definingClass, new GenericState(fieldMap));
  }

  void _evaluateSuperConstructorCall(AstNode node, HashMap<String, DartObjectImpl> fieldMap, ConstructorElement superConstructor, NodeList<Expression> superArguments, ConstantVisitor initializerVisitor, ErrorReporter errorReporter) {
    if (superConstructor != null && superConstructor.isConst) {
      DartObjectImpl evaluationResult = _evaluateConstructorCall(node, superArguments, superConstructor, initializerVisitor, errorReporter);
      if (evaluationResult != null) {
        fieldMap[GenericState.SUPERCLASS_FIELD] = evaluationResult;
      }
    }
  }

  /**
   * Attempt to follow the chain of factory redirections until a constructor is reached which is not
   * a const factory constructor.
   *
   * @return the constant constructor which terminates the chain of factory redirections, if the
   *         chain terminates. If there is a problem (e.g. a redirection can't be found, or a cycle
   *         is encountered), the chain will be followed as far as possible and then a const factory
   *         constructor will be returned.
   */
  ConstructorElement _followConstantRedirectionChain(ConstructorElement constructor) {
    HashSet<ConstructorElement> constructorsVisited = new HashSet<ConstructorElement>();
    while (constructor.isFactory) {
      if (identical(constructor.enclosingElement.type, typeProvider.symbolType)) {
        // The dart:core.Symbol has a const factory constructor that redirects to
        // dart:_internal.Symbol.  That in turn redirects to an external const constructor, which
        // we won't be able to evaluate.  So stop following the chain of redirections at
        // dart:core.Symbol, and let [evaluateInstanceCreationExpression] handle it specially.
        break;
      }
      constructorsVisited.add(constructor);
      ConstructorElement redirectedConstructor = constructor.redirectedConstructor;
      if (redirectedConstructor == null) {
        // This can happen if constructor is an external factory constructor.
        break;
      }
      if (!redirectedConstructor.isConst) {
        // Delegating to a non-const constructor--this is not allowed (and
        // is checked elsewhere--see [ErrorVerifier.checkForRedirectToNonConstConstructor()]).
        break;
      }
      if (constructorsVisited.contains(redirectedConstructor)) {
        // Cycle in redirecting factory constructors--this is not allowed
        // and is checked elsewhere--see [ErrorVerifier.checkForRecursiveFactoryRedirect()]).
        break;
      }
      constructor = redirectedConstructor;
    }
    return constructor;
  }

  /**
   * Generate an error indicating that the given constant is not a valid compile-time constant
   * because it references at least one of the constants in the given cycle, each of which directly
   * or indirectly references the constant.
   *
   * @param constantsInCycle the constants in the cycle that includes the given constant
   * @param constant the constant that is not a valid compile-time constant
   */
  void _generateCycleError(List<AstNode> constantsInCycle, AstNode constant) {
    // TODO(brianwilkerson) Implement this.
  }

  ConstructorElement _getConstructorBase(ConstructorElement constructor) {
    while (constructor is ConstructorMember) {
      constructor = (constructor as ConstructorMember).baseElement;
    }
    return constructor;
  }
}

/**
 * [AstCloner] that copies the necessary information from the AST to allow const constructor
 * initializers to be evaluated.
 */
class ConstantValueComputer_InitializerCloner extends AstCloner {
  @override
  InstanceCreationExpression visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression expression = super.visitInstanceCreationExpression(node);
    expression.evaluationResult = node.evaluationResult;
    return expression;
  }

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier identifier = super.visitSimpleIdentifier(node);
    identifier.staticElement = node.staticElement;
    return identifier;
  }

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation invocation = super.visitSuperConstructorInvocation(node);
    invocation.staticElement = node.staticElement;
    return invocation;
  }
}

/**
 * Instances of the class `ConstantVisitor` evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to <b>null</b>.
 * * A literal symbol.
 * * <b>null</b>.
 * * A qualified reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, class or type alias.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static method.
 * * A parenthesized expression <i>(e)</i> where <i>e</i> is a constant expression.
 * * An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i> where
 * <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions and <i>identical()</i> is
 * statically bound to the predefined dart function <i>identical()</i> discussed above.
 * * An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i> or <i>e<sub>1</sub>
 * != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions
 * that evaluate to a numeric, string or boolean value.
 * * An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp; e<sub>2</sub></i> or
 * <i>e<sub>1</sub> || e<sub>2</sub></i>, where <i>e</i>, <i>e1</sub></i> and <i>e2</sub></i> are
 * constant expressions that evaluate to a boolean value.
 * * An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^ e<sub>2</sub></i>,
 * <i>e<sub>1</sub> &amp; e<sub>2</sub></i>, <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub>
 * &gt;&gt; e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where <i>e</i>,
 * <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions that evaluate to an
 * integer value or to <b>null</b>.
 * * An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> + e<sub>2</sub></i>,
 * <i>e<sub>1</sub> - e<sub>2</sub></i>, <i>e<sub>1</sub> * e<sub>2</sub></i>, <i>e<sub>1</sub> /
 * e<sub>2</sub></i>, <i>e<sub>1</sub> ~/ e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;
 * e<sub>2</sub></i>, <i>e<sub>1</sub> &lt; e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;=
 * e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or <i>e<sub>1</sub> %
 * e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 * expressions that evaluate to a numeric value or to <b>null</b>.
 * * An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> where
 * <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and <i>e<sub>3</sub></i> are constant expressions, and
 * <i>e<sub>1</sub></i> evaluates to a boolean value.
 * </blockquote>
 */
class ConstantVisitor extends UnifyingAstVisitor<DartObjectImpl> {
  /**
   * The type provider used to access the known types.
   */
  final TypeProvider _typeProvider;

  /**
   * An shared object representing the value 'null'.
   */
  DartObjectImpl _nullObject;

  HashMap<String, DartObjectImpl> _lexicalEnvironment;

  /**
   * Error reporter that we use to report errors accumulated while computing the constant.
   */
  final ErrorReporter _errorReporter;

  /**
   * Helper class used to compute constant values.
   */
  DartObjectComputer _dartObjectComputer;

  /**
   * Initialize a newly created constant visitor.
   *
   * @param typeProvider the type provider used to access known types
   * @param lexicalEnvironment values which should override simpleIdentifiers, or null if no
   *          overriding is necessary.
   */
  ConstantVisitor.con1(this._typeProvider, this._errorReporter) {
    this._lexicalEnvironment = null;
    this._dartObjectComputer = new DartObjectComputer(_errorReporter, _typeProvider);
  }

  /**
   * Initialize a newly created constant visitor.
   *
   * @param typeProvider the type provider used to access known types
   * @param lexicalEnvironment values which should override simpleIdentifiers, or null if no
   *          overriding is necessary.
   */
  ConstantVisitor.con2(this._typeProvider, HashMap<String, DartObjectImpl> lexicalEnvironment, this._errorReporter) {
    this._lexicalEnvironment = lexicalEnvironment;
    this._dartObjectComputer = new DartObjectComputer(_errorReporter, _typeProvider);
  }

  @override
  DartObjectImpl visitAdjacentStrings(AdjacentStrings node) {
    DartObjectImpl result = null;
    for (StringLiteral string in node.strings) {
      if (result == null) {
        result = string.accept(this);
      } else {
        result = _dartObjectComputer.concatenate(node, result, string.accept(this));
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
    if (operatorType != TokenType.BANG_EQ && operatorType != TokenType.EQ_EQ) {
      if (leftResult != null && leftResult.isNull || rightResult != null && rightResult.isNull) {
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
        return _dartObjectComputer.greaterThanOrEqual(node, leftResult, rightResult);
      } else if (operatorType == TokenType.GT_GT) {
        return _dartObjectComputer.shiftRight(node, leftResult, rightResult);
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
      break;
    }
  }

  @override
  DartObjectImpl visitBooleanLiteral(BooleanLiteral node) => new DartObjectImpl(_typeProvider.boolType, BoolState.from(node.value));

  @override
  DartObjectImpl visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    DartObjectImpl conditionResult = condition.accept(this);
    DartObjectImpl thenResult = node.thenExpression.accept(this);
    DartObjectImpl elseResult = node.elseExpression.accept(this);
    if (conditionResult == null) {
      return conditionResult;
    } else if (!conditionResult.isBool) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, condition, []);
      return null;
    } else if (thenResult == null) {
      return thenResult;
    } else if (elseResult == null) {
      return elseResult;
    }
    conditionResult = _dartObjectComputer.applyBooleanConversion(condition, conditionResult);
    if (conditionResult == null) {
      return conditionResult;
    }
    if (conditionResult.isTrue) {
      return thenResult;
    } else if (conditionResult.isFalse) {
      return elseResult;
    }
    ParameterizedType thenType = thenResult.type;
    ParameterizedType elseType = elseResult.type;
    return _validWithUnknownValue(thenType.getLeastUpperBound(elseType) as InterfaceType);
  }

  @override
  DartObjectImpl visitDoubleLiteral(DoubleLiteral node) => new DartObjectImpl(_typeProvider.doubleType, new DoubleState(node.value));

  @override
  DartObjectImpl visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.isConst) {
      // TODO(brianwilkerson) Figure out which error to report.
      _error(node, null);
      return null;
    }
    beforeGetEvaluationResult(node);
    EvaluationResultImpl result = node.evaluationResult;
    if (result != null) {
      return result.value;
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitIntegerLiteral(IntegerLiteral node) => new DartObjectImpl(_typeProvider.intType, new IntState(node.value));

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
  DartObjectImpl visitInterpolationString(InterpolationString node) => new DartObjectImpl(_typeProvider.stringType, new StringState(node.value));

  @override
  DartObjectImpl visitListLiteral(ListLiteral node) {
    if (node.constKeyword == null) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL, node, []);
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
    if (node.typeArguments != null && node.typeArguments.arguments.length == 1) {
      DartType type = node.typeArguments.arguments[0].type;
      if (type != null) {
        elementType = type;
      }
    }
    InterfaceType listType = _typeProvider.listType.substitute4([elementType]);
    return new DartObjectImpl(listType, new ListState(new List.from(elements)));
  }

  @override
  DartObjectImpl visitMapLiteral(MapLiteral node) {
    if (node.constKeyword == null) {
      _errorReporter.reportErrorForNode(CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL, node, []);
      return null;
    }
    bool errorOccurred = false;
    HashMap<DartObjectImpl, DartObjectImpl> map = new HashMap<DartObjectImpl, DartObjectImpl>();
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
    if (node.typeArguments != null && node.typeArguments.arguments.length == 2) {
      DartType keyTypeCandidate = node.typeArguments.arguments[0].type;
      if (keyTypeCandidate != null) {
        keyType = keyTypeCandidate;
      }
      DartType valueTypeCandidate = node.typeArguments.arguments[1].type;
      if (valueTypeCandidate != null) {
        valueType = valueTypeCandidate;
      }
    }
    InterfaceType mapType = _typeProvider.mapType.substitute4(
        [keyType, valueType]);
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
              return _dartObjectComputer.equalEqual(node, leftArgument, rightArgument);
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
  DartObjectImpl visitNamedExpression(NamedExpression node) => node.expression.accept(this);

  @override
  DartObjectImpl visitNode(AstNode node) {
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitNullLiteral(NullLiteral node) => null2;

  @override
  DartObjectImpl visitParenthesizedExpression(ParenthesizedExpression node) => node.expression.accept(this);

  @override
  DartObjectImpl visitPrefixedIdentifier(PrefixedIdentifier node) {
    // TODO(brianwilkerson) Uncomment the lines below when the new constant support can be added.
    //    Element element = node.getStaticElement();
    //    if (isStringLength(element)) {
    //      EvaluationResultImpl target = node.getPrefix().accept(this);
    //      return target.stringLength(typeProvider, node);
    //    }
    SimpleIdentifier prefixNode = node.prefix;
    Element prefixElement = prefixNode.staticElement;
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
    Element element = node.propertyName.staticElement;
    // TODO(brianwilkerson) Uncomment the lines below when the new constant support can be added.
    //    if (isStringLength(element)) {
    //      EvaluationResultImpl target = node.getRealTarget().accept(this);
    //      return target.stringLength(typeProvider, node);
    //    }
    return _getConstantValue(node, element);
  }

  @override
  DartObjectImpl visitSimpleIdentifier(SimpleIdentifier node) {
    if (_lexicalEnvironment != null && _lexicalEnvironment.containsKey(node.name)) {
      return _lexicalEnvironment[node.name];
    }
    return _getConstantValue(node, node.staticElement);
  }

  @override
  DartObjectImpl visitSimpleStringLiteral(SimpleStringLiteral node) => new DartObjectImpl(_typeProvider.stringType, new StringState(node.value));

  @override
  DartObjectImpl visitStringInterpolation(StringInterpolation node) {
    DartObjectImpl result = null;
    bool first = true;
    for (InterpolationElement element in node.elements) {
      if (first) {
        result = element.accept(this);
        first = false;
      } else {
        result = _dartObjectComputer.concatenate(node, result, element.accept(this));
      }
    }
    return result;
  }

  @override
  DartObjectImpl visitSymbolLiteral(SymbolLiteral node) {
    JavaStringBuilder builder = new JavaStringBuilder();
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        builder.appendChar(0x2E);
      }
      builder.append(components[i].lexeme);
    }
    return new DartObjectImpl(_typeProvider.symbolType, new SymbolState(builder.toString()));
  }

  /**
   * This method is called just before retrieving an evaluation result from an AST node. Unit tests
   * will override it to introduce additional error checking.
   */
  void beforeGetEvaluationResult(AstNode node) {
  }

  /**
   * Return an object representing the value 'null'.
   *
   * @return an object representing the value 'null'
   */
  DartObjectImpl get null2 {
    if (_nullObject == null) {
      _nullObject = new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
    }
    return _nullObject;
  }

  DartObjectImpl _validWithUnknownValue(InterfaceType type) {
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

  /**
   * Return the value of the given expression, or a representation of 'null' if the expression
   * cannot be evaluated.
   *
   * @param expression the expression whose value is to be returned
   * @return the value of the given expression
   */
  DartObjectImpl _valueOf(Expression expression) {
    DartObjectImpl expressionValue = expression.accept(this);
    if (expressionValue != null) {
      return expressionValue;
    }
    return null2;
  }

  /**
   * Create an error associated with the given node.
   *
   * @param node the AST node associated with the error
   * @param code the error code indicating the nature of the error
   */
  void _error(AstNode node, ErrorCode code) {
    _errorReporter.reportErrorForNode(code == null ? CompileTimeErrorCode.INVALID_CONSTANT : code, node, []);
  }

  /**
   * Return the constant value of the static constant represented by the given element.
   *
   * @param node the node to be used if an error needs to be reported
   * @param element the element whose value is to be returned
   * @return the constant value of the static constant
   */
  DartObjectImpl _getConstantValue(AstNode node, Element element) {
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElementImpl) {
      VariableElementImpl variableElementImpl = element;
      beforeGetEvaluationResult(node);
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
    } else if (element is ClassElement || element is FunctionTypeAliasElement) {
      return new DartObjectImpl(_typeProvider.typeType, new TypeState(element));
    }
    // TODO(brianwilkerson) Figure out which error to report.
    _error(node, null);
    return null;
  }

  /**
   * Return `true` if the given element represents the 'length' getter in class 'String'.
   *
   * @param element the element being tested.
   * @return
   */
  bool _isStringLength(Element element) {
    if (element is! PropertyAccessorElement) {
      return false;
    }
    PropertyAccessorElement accessor = element as PropertyAccessorElement;
    if (!accessor.isGetter || accessor.name != "length") {
      return false;
    }
    Element parent = accessor.enclosingElement;
    return parent == _typeProvider.stringType.element;
  }
}

/**
 * The interface `DartObject` defines the behavior of objects that represent the state of a
 * Dart object.
 */
abstract class DartObject {
  /**
   * Return the boolean value of this object, or `null` if either the value of this object is
   * not known or this object is not of type 'bool'.
   *
   * @return the boolean value of this object
   */
  bool get boolValue;

  /**
   * Return the floating point value of this object, or `null` if either the value of this
   * object is not known or this object is not of type 'double'.
   *
   * @return the floating point value of this object
   */
  double get doubleValue;

  /**
   * Return the integer value of this object, or `null` if either the value of this object is
   * not known or this object is not of type 'int'.
   *
   * @return the integer value of this object
   */
  int get intValue;

  /**
   * Return the string value of this object, or `null` if either the value of this object is
   * not known or this object is not of type 'String'.
   *
   * @return the string value of this object
   */
  String get stringValue;

  /**
   * Return the run-time type of this object.
   *
   * @return the run-time type of this object
   */
  ParameterizedType get type;

  /**
   * Return this object's value if it can be represented exactly, or `null` if either the
   * value cannot be represented exactly or if the value is `null`. Clients should use
   * [hasExactValue] to distinguish between these two cases.
   *
   * @return this object's value
   */
  Object get value;

  /**
   * Return `true` if this object's value can be represented exactly.
   *
   * @return `true` if this object's value can be represented exactly
   */
  bool get hasExactValue;

  /**
   * Return `true` if this object represents the value 'false'.
   *
   * @return `true` if this object represents the value 'false'
   */
  bool get isFalse;

  /**
   * Return `true` if this object represents the value 'null'.
   *
   * @return `true` if this object represents the value 'null'
   */
  bool get isNull;

  /**
   * Return `true` if this object represents the value 'true'.
   *
   * @return `true` if this object represents the value 'true'
   */
  bool get isTrue;
}

/**
 * Instances of the class `DartObjectComputer` contain methods for manipulating instances of a
 * Dart class and for collecting errors during evaluation.
 */
class DartObjectComputer {
  /**
   * The error reporter that we are using to collect errors.
   */
  final ErrorReporter _errorReporter;

  /**
   * The type provider. Used to create objects of the appropriate types, and to identify when an
   * object is of a built-in type.
   */
  final TypeProvider _typeProvider;

  DartObjectComputer(this._errorReporter, this._typeProvider);

  DartObjectImpl add(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.add(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
        return null;
      }
    }
    return null;
  }

  /**
   * Return the result of applying boolean conversion to this result.
   *
   * @param node the node against which errors should be reported
   * @return the result of applying boolean conversion to the given value
   */
  DartObjectImpl applyBooleanConversion(AstNode node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.convertToBool(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl bitAnd(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitAnd(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl bitNot(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.bitNot(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl bitOr(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitOr(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl bitXor(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.bitXor(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl concatenate(Expression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.concatenate(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl divide(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.divide(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl equalEqual(Expression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.equalEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl greaterThan(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThan(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl greaterThanOrEqual(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl integerDivide(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.integerDivide(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl lessThan(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThan(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl lessThanOrEqual(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl logicalAnd(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalAnd(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl logicalNot(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.logicalNot(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl logicalOr(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalOr(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl minus(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.minus(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl negated(Expression node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.negated(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl notEqual(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.notEqual(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl performToString(AstNode node, DartObjectImpl evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.performToString(_typeProvider);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl remainder(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.remainder(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl shiftLeft(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftLeft(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  DartObjectImpl shiftRight(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftRight(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }

  /**
   * Return the result of invoking the 'length' getter on this result.
   *
   * @param node the node against which errors should be reported
   * @return the result of invoking the 'length' getter on this result
   */
  EvaluationResultImpl stringLength(Expression node, EvaluationResultImpl evaluationResult) {
    if (evaluationResult.value != null) {
      try {
        return new EvaluationResultImpl.con1(evaluationResult.value.stringLength(_typeProvider));
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return new EvaluationResultImpl.con1(null);
  }

  DartObjectImpl times(BinaryExpression node, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.times(_typeProvider, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node, []);
      }
    }
    return null;
  }
}

/**
 * Instances of the class `DartObjectImpl` represent an instance of a Dart class.
 */
class DartObjectImpl implements DartObject {
  /**
   * The run-time type of this object.
   */
  final ParameterizedType type;

  /**
   * The state of the object.
   */
  final InstanceState _state;

  /**
   * Initialize a newly created object to have the given type and state.
   *
   * @param type the run-time type of this object
   * @param state the state of the object
   */
  DartObjectImpl(this.type, this._state);

  /**
   * Return the result of invoking the '+' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '+' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
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
    throw new IllegalStateException("add returned a ${result.runtimeType.toString()}");
  }

  /**
   * Return the result of invoking the '&' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl bitAnd(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.bitAnd(rightOperand._state));

  /**
   * Return the result of invoking the '~' operator on this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of invoking the '~' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl bitNot(TypeProvider typeProvider) => new DartObjectImpl(typeProvider.intType, _state.bitNot());

  /**
   * Return the result of invoking the '|' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '|' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl bitOr(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.bitOr(rightOperand._state));

  /**
   * Return the result of invoking the '^' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '^' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl bitXor(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.bitXor(rightOperand._state));

  /**
   * Return the result of invoking the ' ' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the ' ' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl concatenate(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.stringType, _state.concatenate(rightOperand._state));

  /**
   * Return the result of applying boolean conversion to this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of applying boolean conversion to this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl convertToBool(TypeProvider typeProvider) {
    InterfaceType boolType = typeProvider.boolType;
    if (identical(type, boolType)) {
      return this;
    }
    return new DartObjectImpl(boolType, _state.convertToBool());
  }

  /**
   * Return the result of invoking the '/' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '/' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl divide(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.divide(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("divide returned a ${result.runtimeType.toString()}");
  }

  /**
   * Return the result of invoking the '==' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '==' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl equalEqual(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (type != rightOperand.type) {
      String typeName = type.name;
      if (!(typeName == "bool" || typeName == "double" || typeName == "int" || typeName == "num" || typeName == "String" || typeName == "Null" || type.isDynamic)) {
        throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
      }
    }
    return new DartObjectImpl(typeProvider.boolType, _state.equalEqual(rightOperand._state));
  }

  @override
  bool operator ==(Object object) {
    if (object is! DartObjectImpl) {
      return false;
    }
    DartObjectImpl dartObject = object as DartObjectImpl;
    return type == dartObject.type && _state == dartObject._state;
  }

  @override
  bool get boolValue {
    if (_state is BoolState) {
      return (_state as BoolState).value;
    }
    return null;
  }

  @override
  double get doubleValue {
    if (_state is DoubleState) {
      return (_state as DoubleState).value;
    }
    return null;
  }

  HashMap<String, DartObjectImpl> get fields => _state.fields;

  @override
  int get intValue {
    if (_state is IntState) {
      return (_state as IntState).value;
    }
    return null;
  }

  @override
  String get stringValue {
    if (_state is StringState) {
      return (_state as StringState).value;
    }
    return null;
  }

  @override
  Object get value => _state.value;

  /**
   * Return the result of invoking the '&gt;' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl greaterThan(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.greaterThan(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;=' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl greaterThanOrEqual(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.greaterThanOrEqual(rightOperand._state));

  @override
  bool get hasExactValue => _state.hasExactValue;

  @override
  int get hashCode => ObjectUtilities.combineHashCodes(type.hashCode, _state.hashCode);

  /**
   * Return the result of invoking the '~/' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '~/' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl integerDivide(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.integerDivide(rightOperand._state));

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   *
   * @return `true` if this object represents a boolean value
   */
  bool get isBool => _state.isBool;

  /**
   * Return `true` if this object represents an object whose type is either 'bool', 'num',
   * 'String', or 'Null'.
   *
   * @return `true` if this object represents either a boolean, numeric, string or null value
   */
  bool get isBoolNumStringOrNull => _state.isBoolNumStringOrNull;

  @override
  bool get isFalse => _state is BoolState && identical((_state as BoolState).value, false);

  @override
  bool get isNull => _state is NullState;

  @override
  bool get isTrue => _state is BoolState && identical((_state as BoolState).value, true);

  /**
   * Return true if this object represents an unknown value.
   */
  bool get isUnknown => _state.isUnknown;

  /**
   * Return `true` if this object represents an instance of a user-defined class.
   *
   * @return `true` if this object represents an instance of a user-defined class
   */
  bool get isUserDefinedObject => _state is GenericState;

  /**
   * Return the result of invoking the '&lt;' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl lessThan(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.lessThan(rightOperand._state));

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;=' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl lessThanOrEqual(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.lessThanOrEqual(rightOperand._state));

  /**
   * Return the result of invoking the '&&' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&&' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl logicalAnd(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.logicalAnd(rightOperand._state));

  /**
   * Return the result of invoking the '!' operator on this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of invoking the '!' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl logicalNot(TypeProvider typeProvider) => new DartObjectImpl(typeProvider.boolType, _state.logicalNot());

  /**
   * Return the result of invoking the '||' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '||' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl logicalOr(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.boolType, _state.logicalOr(rightOperand._state));

  /**
   * Return the result of invoking the '-' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '-' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
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
    throw new IllegalStateException("minus returned a ${result.runtimeType.toString()}");
  }

  /**
   * Return the result of invoking the '-' operator on this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of invoking the '-' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
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
    throw new IllegalStateException("negated returned a ${result.runtimeType.toString()}");
  }

  /**
   * Return the result of invoking the '!=' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '!=' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl notEqual(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (type != rightOperand.type) {
      String typeName = type.name;
      if (typeName != "bool" && typeName != "double" && typeName != "int" && typeName != "num" && typeName != "String") {
        return new DartObjectImpl(typeProvider.boolType, BoolState.TRUE_STATE);
      }
    }
    return new DartObjectImpl(typeProvider.boolType, _state.equalEqual(rightOperand._state).logicalNot());
  }

  /**
   * Return the result of converting this object to a String.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of converting this object to a String
   * @throws EvaluationException if the object cannot be converted to a String
   */
  DartObjectImpl performToString(TypeProvider typeProvider) {
    InterfaceType stringType = typeProvider.stringType;
    if (identical(type, stringType)) {
      return this;
    }
    return new DartObjectImpl(stringType, _state.convertToString());
  }

  /**
   * Return the result of invoking the '%' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '%' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl remainder(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.remainder(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new IllegalStateException("remainder returned a ${result.runtimeType.toString()}");
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;&lt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl shiftLeft(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.shiftLeft(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;&gt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl shiftRight(TypeProvider typeProvider, DartObjectImpl rightOperand) => new DartObjectImpl(typeProvider.intType, _state.shiftRight(rightOperand._state));

  /**
   * Return the result of invoking the 'length' getter on this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of invoking the 'length' getter on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  DartObjectImpl stringLength(TypeProvider typeProvider) => new DartObjectImpl(typeProvider.intType, _state.stringLength());

  /**
   * Return the result of invoking the '*' operator on this object with the given argument.
   *
   * @param typeProvider the type provider used to find known types
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '*' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
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
    throw new IllegalStateException("times returned a ${result.runtimeType.toString()}");
  }

  @override
  String toString() => "${type.displayName} (${_state.toString()})";
}

/**
 * Instances of the class `DeclaredVariables` provide access to the values of variables that
 * have been defined on the command line using the `-D` option.
 */
class DeclaredVariables {
  /**
   * A table mapping the names of declared variables to their values.
   */
  HashMap<String, String> _declaredVariables = new HashMap<String, String>();

  /**
   * Define a variable with the given name to have the given value.
   *
   * @param variableName the name of the variable being defined
   * @param value the value of the variable
   */
  void define(String variableName, String value) {
    _declaredVariables[variableName] = value;
  }

  /**
   * Return the value of the variable with the given name interpreted as a boolean value. If the
   * variable is not defined (or [variableName] is null), a DartObject representing "unknown"
   * is returned. If the value can't be parsed as a boolean, a DartObject representing null is
   * returned.
   *
   * @param typeProvider the type provider used to find the type 'bool'
   * @param variableName the name of the variable whose value is to be returned
   */
  DartObject getBool(TypeProvider typeProvider, String variableName) {
    String value = _declaredVariables[variableName];
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
   * Return the value of the variable with the given name interpreted as an integer value. If the
   * variable is not defined (or [variableName] is null), a DartObject representing "unknown"
   * is returned. If the value can't be parsed as an integer, a DartObject representing null is
   * returned.
   *
   * @param typeProvider the type provider used to find the type 'int'
   * @param variableName the name of the variable whose value is to be returned
   */
  DartObject getInt(TypeProvider typeProvider, String variableName) {
    String value = _declaredVariables[variableName];
    if (value == null) {
      return new DartObjectImpl(typeProvider.intType, IntState.UNKNOWN_VALUE);
    }
    int bigInteger;
    try {
      bigInteger = int.parse(value);
    } on FormatException catch (exception) {
      return new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
    }
    return new DartObjectImpl(typeProvider.intType, new IntState(bigInteger));
  }

  /**
   * Return the value of the variable with the given name interpreted as a String value, or
   * `null` if the variable is not defined. Return the value of the variable with the given
   * name interpreted as a String value. If the variable is not defined (or [variableName] is
   * null), a DartObject representing "unknown" is returned.
   *
   * @param typeProvider the type provider used to find the type 'String'
   * @param variableName the name of the variable whose value is to be returned
   */
  DartObject getString(TypeProvider typeProvider, String variableName) {
    String value = _declaredVariables[variableName];
    if (value == null) {
      return new DartObjectImpl(typeProvider.intType, IntState.UNKNOWN_VALUE);
    }
    return new DartObjectImpl(typeProvider.stringType, new StringState(value));
  }
}

/**
 * Instances of the class `DoubleState` represent the state of an object representing a
 * double.
 */
class DoubleState extends NumState {
  /**
   * The value of this instance.
   */
  final double value;

  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static DoubleState UNKNOWN_VALUE = new DoubleState(null);

  /**
   * Initialize a newly created state to represent a double with the given value.
   *
   * @param value the value of this instance
   */
  DoubleState(this.value);

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
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
  bool operator ==(Object object) => object is DoubleState && (value == object.value);

  @override
  String get typeName => "double";

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * Instances of the class `DynamicState` represent the state of an object representing a Dart
 * object for which there is no type information.
 */
class DynamicState extends InstanceState {
  /**
   * The unique instance of this class.
   */
  static DynamicState DYNAMIC_STATE = new DynamicState();

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
  String get typeName => "dynamic";

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
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

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
   * Return an object representing an unknown numeric value whose type is based on the type of the
   * right-hand operand.
   *
   * @param rightOperand the operand whose type will determine the type of the result
   * @return an object representing an unknown numeric value
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
 * Instances of the class `EvaluationException` represent a run-time exception that would be
 * thrown during the evaluation of Dart code.
 */
class EvaluationException extends JavaException {
  /**
   * The error code associated with the exception.
   */
  final ErrorCode errorCode;

  /**
   * Initialize a newly created exception to have the given error code.
   *
   * @param errorCode the error code associated with the exception
   */
  EvaluationException(this.errorCode);
}

/**
 * Instances of the class `EvaluationResult` represent the result of attempting to evaluate an
 * expression.
 */
class EvaluationResult {
  /**
   * Return an evaluation result representing the result of evaluating an expression that is not a
   * compile-time constant because of the given errors.
   *
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   * @return the result of evaluating an expression that is not a compile-time constant
   */
  static EvaluationResult forErrors(List<AnalysisError> errors) => new EvaluationResult(null, errors);

  /**
   * Return an evaluation result representing the result of evaluating an expression that is a
   * compile-time constant that evaluates to the given value.
   *
   * @param value the value of the expression
   * @return the result of evaluating an expression that is a compile-time constant
   */
  static EvaluationResult forValue(DartObject value) => new EvaluationResult(value, null);

  /**
   * The value of the expression.
   */
  final DartObject value;

  /**
   * The errors that should be reported for the expression(s) that were evaluated.
   */
  final List<AnalysisError> _errors;

  /**
   * Initialize a newly created result object with the given state. Clients should use one of the
   * factory methods: [forErrors] and [forValue].
   *
   * @param value the value of the expression
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   */
  EvaluationResult(this.value, this._errors);

  /**
   * Return an array containing the errors that should be reported for the expression(s) that were
   * evaluated. If there are no such errors, the array will be empty. The array can be empty even if
   * the expression is not a valid compile time constant if the errors would have been reported by
   * other parts of the analysis engine.
   */
  List<AnalysisError> get errors => _errors == null ? AnalysisError.NO_ERRORS : _errors;

  /**
   * Return `true` if the expression is a compile-time constant expression that would not
   * throw an exception when evaluated.
   *
   * @return `true` if the expression is a valid compile-time constant expression
   */
  bool get isValid => _errors == null;
}

/**
 * Instances of the class `InternalResult` represent the result of attempting to evaluate a
 * expression.
 */
class EvaluationResultImpl {
  /**
   * The errors encountered while trying to evaluate the compile time constant. These errors may or
   * may not have prevented the expression from being a valid compile time constant.
   */
  List<AnalysisError> _errors;

  /**
   * The value of the expression, or null if the value couldn't be computed due to errors.
   */
  final DartObjectImpl value;

  EvaluationResultImpl.con1(this.value) {
    this._errors = new List<AnalysisError>(0);
  }

  EvaluationResultImpl.con2(this.value, List<AnalysisError> errors) {
    this._errors = errors;
  }

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

  List<AnalysisError> get errors => _errors;

  @override
  String toString() {
    if (value == null) {
      return "error";
    }
    return value.toString();
  }
}

/**
 * Instances of the class `FunctionState` represent the state of an object representing a
 * function.
 */
class FunctionState extends InstanceState {
  /**
   * The element representing the function being modeled.
   */
  final ExecutableElement _element;

  /**
   * Initialize a newly created state to represent the given function.
   *
   * @param element the element representing the function being modeled
   */
  FunctionState(this._element);

  @override
  StringState convertToString() {
    if (_element == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_element.name);
  }

  @override
  bool operator ==(Object object) => object is FunctionState && (_element == object._element);

  @override
  BoolState equalEqual(InstanceState rightOperand) {
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
  String get typeName => "Function";

  @override
  int get hashCode => _element == null ? 0 : _element.hashCode;

  @override
  String toString() => _element == null ? "-unknown-" : _element.name;
}

/**
 * Instances of the class `GenericState` represent the state of an object representing a Dart
 * object for which there is no more specific state.
 */
class GenericState extends InstanceState {
  /**
   * The values of the fields of this instance.
   */
  final HashMap<String, DartObjectImpl> _fieldMap;

  /**
   * Pseudo-field that we use to represent fields in the superclass.
   */
  static String SUPERCLASS_FIELD = "(super)";

  /**
   * A state that can be used to represent an object whose state is not known.
   */
  static GenericState UNKNOWN_VALUE = new GenericState(new HashMap<String, DartObjectImpl>());

  /**
   * Initialize a newly created state to represent a newly created object.
   *
   * @param fieldMap the values of the fields of this instance
   */
  GenericState(this._fieldMap);

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  bool operator ==(Object object) {
    if (object is! GenericState) {
      return false;
    }
    GenericState state = object as GenericState;
    HashSet<String> otherFields = new HashSet<String>.from(state._fieldMap.keys.toSet());
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
  HashMap<String, DartObjectImpl> get fields => _fieldMap;

  @override
  String get typeName => "user defined type";

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
}

/**
 * The class `InstanceState` defines the behavior of objects representing the state of a Dart
 * object.
 */
abstract class InstanceState {
  /**
   * Return the result of invoking the '+' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '+' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  InstanceState add(InstanceState rightOperand) {
    // TODO(brianwilkerson) Uncomment the code below when the new constant support can be added.
    //    if (this instanceof StringState || rightOperand instanceof StringState) {
    //      return concatenate(rightOperand);
    //    }
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '~' operator on this object.
   *
   * @return the result of invoking the '~' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState bitNot() {
    assertIntOrNull(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '|' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '|' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '^' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '^' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the ' ' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the ' ' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of applying boolean conversion to this object.
   *
   * @param typeProvider the type provider used to find known types
   * @return the result of applying boolean conversion to this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState convertToBool() => BoolState.FALSE_STATE;

  /**
   * Return the result of converting this object to a String.
   *
   * @return the result of converting this object to a String
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  StringState convertToString();

  /**
   * Return the result of invoking the '/' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '/' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '==' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '==' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState equalEqual(InstanceState rightOperand);

  /**
   * If this represents a generic dart object, return a map from its fieldnames to their values.
   * Otherwise return null.
   */
  HashMap<String, DartObjectImpl> get fields => null;

  /**
   * Return the name of the type of this value.
   *
   * @return the name of the type of this value
   */
  String get typeName;

  /**
   * Return this object's value if it can be represented exactly, or `null` if either the
   * value cannot be represented exactly or if the value is `null`. Clients should use
   * [hasExactValue] to distinguish between these two cases.
   *
   * @return this object's value
   */
  Object get value => null;

  /**
   * Return the result of invoking the '&gt;' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;=' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return `true` if this object's value can be represented exactly.
   *
   * @return `true` if this object's value can be represented exactly
   */
  bool get hasExactValue => false;

  /**
   * Return the result of invoking the '~/' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '~/' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   *
   * @return `true` if this object represents a boolean value
   */
  bool get isBool => false;

  /**
   * Return `true` if this object represents an object whose type is either 'bool', 'num',
   * 'String', or 'Null'.
   *
   * @return `true` if this object represents either a boolean, numeric, string or null value
   */
  bool get isBoolNumStringOrNull => false;

  /**
   * Return true if this object represents an unknown value.
   */
  bool get isUnknown => false;

  /**
   * Return the result of invoking the '&lt;' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;=' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&&' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&&' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    return BoolState.FALSE_STATE;
  }

  /**
   * Return the result of invoking the '!' operator on this object.
   *
   * @return the result of invoking the '!' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState logicalNot() {
    assertBool(this);
    return BoolState.TRUE_STATE;
  }

  /**
   * Return the result of invoking the '||' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '||' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  /**
   * Return the result of invoking the '-' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '-' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '-' operator on this object.
   *
   * @return the result of invoking the '-' operator on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  NumState negated() {
    assertNumOrNull(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '%' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '%' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&lt;&lt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '&gt;&gt;' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the 'length' getter on this object.
   *
   * @return the result of invoking the 'length' getter on this object
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  IntState stringLength() {
    assertString(this);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Return the result of invoking the '*' operator on this object with the given argument.
   *
   * @param rightOperand the right-hand operand of the operation
   * @return the result of invoking the '*' operator on this object with the given argument
   * @throws EvaluationException if the operator is not appropriate for an object of this kind
   */
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(CompileTimeErrorCode.INVALID_CONSTANT);
  }

  /**
   * Throw an exception if the given state does not represent a boolean value.
   *
   * @param state the state being tested
   * @throws EvaluationException if the given state does not represent a boolean value
   */
  void assertBool(InstanceState state) {
    if (!(state is BoolState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }

  /**
   * Throw an exception if the given state does not represent a boolean, numeric, string or null
   * value.
   *
   * @param state the state being tested
   * @throws EvaluationException if the given state does not represent a boolean, numeric, string or
   *           null value
   */
  void assertBoolNumStringOrNull(InstanceState state) {
    if (!(state is BoolState || state is DoubleState || state is IntState || state is NumState || state is StringState || state is NullState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
    }
  }

  /**
   * Throw an exception if the given state does not represent an integer or null value.
   *
   * @param state the state being tested
   * @throws EvaluationException if the given state does not represent an integer or null value
   */
  void assertIntOrNull(InstanceState state) {
    if (!(state is IntState || state is NumState || state is NullState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
  }

  /**
   * Throw an exception if the given state does not represent a boolean, numeric, string or null
   * value.
   *
   * @param state the state being tested
   * @throws EvaluationException if the given state does not represent a boolean, numeric, string or
   *           null value
   */
  void assertNumOrNull(InstanceState state) {
    if (!(state is DoubleState || state is IntState || state is NumState || state is NullState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
  }

  /**
   * Throw an exception if the given state does not represent a String value.
   *
   * @param state the state being tested
   * @throws EvaluationException if the given state does not represent a String value
   */
  void assertString(InstanceState state) {
    if (!(state is StringState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }
}

/**
 * Instances of the class `IntState` represent the state of an object representing an int.
 */
class IntState extends NumState {
  /**
   * The value of this instance.
   */
  final int value;

  /**
   * A state that can be used to represent an int whose value is not known.
   */
  static IntState UNKNOWN_VALUE = new IntState(null);

  /**
   * Initialize a newly created state to represent an int with the given value.
   *
   * @param value the value of this instance
   */
  IntState(this.value);

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
        return new DoubleState(value.toDouble() / rightValue.toDouble());
      }
      return new IntState(value ~/ rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() / rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
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
  bool operator ==(Object object) => object is IntState && (value == object.value);

  @override
  String get typeName => "int";

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

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
        throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
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
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * The unique instance of the class `ListState` represents the state of an object representing
 * a list.
 */
class ListState extends InstanceState {
  /**
   * The elements of the list.
   */
  final List<DartObjectImpl> _elements;

  /**
   * Initialize a newly created state to represent a list with the given elements.
   *
   * @param elements the elements of the list
   */
  ListState(this._elements);

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

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
  String get typeName => "List";

  @override
  List<Object> get value {
    int count = _elements.length;
    List<Object> result = new List<Object>(count);
    for (int i = 0; i < count; i++) {
      DartObjectImpl element = _elements[i];
      if (!element.hasExactValue) {
        return null;
      }
      result[i] = element.value;
    }
    return result;
  }

  @override
  bool get hasExactValue {
    int count = _elements.length;
    for (int i = 0; i < count; i++) {
      if (!_elements[i].hasExactValue) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    int value = 0;
    int count = _elements.length;
    for (int i = 0; i < count; i++) {
      value = (value << 3) ^ _elements[i].hashCode;
    }
    return value;
  }
}

/**
 * The unique instance of the class `ListState` represents the state of an object representing
 * a map.
 */
class MapState extends InstanceState {
  /**
   * The entries in the map.
   */
  final HashMap<DartObjectImpl, DartObjectImpl> _entries;

  /**
   * Initialize a newly created state to represent a map with the given entries.
   *
   * @param entries the entries in the map
   */
  MapState(this._entries);

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  bool operator ==(Object object) {
    if (object is! MapState) {
      return false;
    }
    HashMap<DartObjectImpl, DartObjectImpl> otherElements = (object as MapState)._entries;
    int count = _entries.length;
    if (otherElements.length != count) {
      return false;
    } else if (count == 0) {
      return true;
    }
    for (MapEntry<DartObjectImpl, DartObjectImpl> entry in getMapEntrySet(_entries)) {
      DartObjectImpl key = entry.getKey();
      DartObjectImpl value = entry.getValue();
      DartObjectImpl otherValue = otherElements[key];
      if (value != otherValue) {
        return false;
      }
    }
    return true;
  }

  @override
  String get typeName => "Map";

  @override
  Map<Object, Object> get value {
    HashMap<Object, Object> result = new HashMap<Object, Object>();
    for (MapEntry<DartObjectImpl, DartObjectImpl> entry in getMapEntrySet(_entries)) {
      DartObjectImpl key = entry.getKey();
      DartObjectImpl value = entry.getValue();
      if (!key.hasExactValue || !value.hasExactValue) {
        return null;
      }
      result[key.value] = value.value;
    }
    return result;
  }

  @override
  bool get hasExactValue {
    for (MapEntry<DartObjectImpl, DartObjectImpl> entry in getMapEntrySet(_entries)) {
      if (!entry.getKey().hasExactValue || !entry.getValue().hasExactValue) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl key in _entries.keys.toSet()) {
      value = (value << 3) ^ key.hashCode;
    }
    return value;
  }
}

/**
 * The unique instance of the class `NullState` represents the state of the value 'null'.
 */
class NullState extends InstanceState {
  /**
   * An instance representing the boolean value 'true'.
   */
  static NullState NULL_STATE = new NullState();

  @override
  BoolState convertToBool() {
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() => new StringState("null");

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(rightOperand is NullState);
  }

  @override
  bool operator ==(Object object) => object is NullState;

  @override
  String get typeName => "Null";

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => 0;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  BoolState logicalNot() {
    throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => "null";
}

/**
 * Instances of the class `NumState` represent the state of an object representing a number of
 * an unknown type (a 'num').
 */
class NumState extends InstanceState {
  /**
   * A state that can be used to represent a number whose value is not known.
   */
  static NumState UNKNOWN_VALUE = new NumState();

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
    return UNKNOWN_VALUE;
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  bool operator ==(Object object) => object is NumState;

  @override
  String get typeName => "num";

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
  int get hashCode => 7;

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
      }
    } else if (rightOperand is DynamicState) {
      return IntState.UNKNOWN_VALUE;
    }
    return IntState.UNKNOWN_VALUE;
  }

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => identical(this, UNKNOWN_VALUE);

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
 * Instances of the class `ReferenceFinder` add reference information for a given variable to
 * the bi-directional mapping used to order the evaluation of constants.
 */
class ReferenceFinder extends RecursiveAstVisitor<Object> {
  /**
   * The element representing the construct that will be visited.
   */
  final AstNode _source;

  /**
   * A graph in which the nodes are the constant variables and the edges are from each variable to
   * the other constant variables that are referenced in the head's initializer.
   */
  final DirectedGraph<AstNode> _referenceGraph;

  /**
   * A table mapping constant variables to the declarations of those variables.
   */
  final HashMap<VariableElement, VariableDeclaration> _variableDeclarationMap;

  /**
   * A table mapping constant constructors to the declarations of those constructors.
   */
  final HashMap<ConstructorElement, ConstructorDeclaration> _constructorDeclarationMap;

  /**
   * Initialize a newly created reference finder to find references from the given variable to other
   * variables and to add those references to the given graph.
   *
   * @param source the element representing the variable whose initializer will be visited
   * @param referenceGraph a graph recording which variables (heads) reference which other variables
   *          (tails) in their initializers
   * @param variableDeclarationMap A table mapping constant variables to the declarations of those
   *          variables.
   * @param constructorDeclarationMap A table mapping constant constructors to the declarations of
   *          those constructors.
   */
  ReferenceFinder(this._source, this._referenceGraph, this._variableDeclarationMap, this._constructorDeclarationMap);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      _referenceGraph.addEdge(_source, node);
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElement) {
      VariableElement variable = element as VariableElement;
      if (variable.isConst) {
        VariableDeclaration variableDeclaration = _variableDeclarationMap[variable];
        // The declaration will be null when the variable is not defined in the compilation units
        // that were used to produce the variableDeclarationMap.  In such cases, the variable should
        // already have a value associated with it, but we don't bother to check because there's
        // nothing we can do about it at this point.
        if (variableDeclaration != null) {
          _referenceGraph.addEdge(_source, variableDeclaration);
        }
      }
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    super.visitSuperConstructorInvocation(node);
    ConstructorElement constructor = node.staticElement;
    if (constructor != null && constructor.isConst) {
      ConstructorDeclaration constructorDeclaration = _constructorDeclarationMap[constructor];
      // The declaration will be null when the constructor is not defined in the compilation
      // units that were used to produce the constructorDeclarationMap.  In such cases, the
      // constructor should already have its initializer AST's stored in it, but we don't bother
      // to check because there's nothing we can do about it at this point.
      if (constructorDeclaration != null) {
        _referenceGraph.addEdge(_source, constructorDeclaration);
      }
    }
    return null;
  }
}

/**
 * Instances of the class `StringState` represent the state of an object representing a
 * string.
 */
class StringState extends InstanceState {
  /**
   * The value of this instance.
   */
  final String value;

  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static StringState UNKNOWN_VALUE = new StringState(null);

  /**
   * Initialize a newly created state to represent the given value.
   *
   * @param value the value of this instance
   */
  StringState(this.value);

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
      return new StringState("${value}${rightValue}");
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
  bool operator ==(Object object) => object is StringState && (value == object.value);

  @override
  String get typeName => "String";

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  IntState stringLength() {
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    return new IntState(value.length);
  }

  @override
  String toString() => value == null ? "-unknown-" : "'${value}'";
}

/**
 * Instances of the class `StringState` represent the state of an object representing a
 * symbol.
 */
class SymbolState extends InstanceState {
  /**
   * The value of this instance.
   */
  final String value;

  /**
   * Initialize a newly created state to represent the given value.
   *
   * @param value the value of this instance
   */
  SymbolState(this.value);

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
  bool operator ==(Object object) => object is SymbolState && (value == object.value);

  @override
  String get typeName => "Symbol";

  @override
  bool get hasExactValue => true;

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  String toString() => value == null ? "-unknown-" : "#${value}";
}

/**
 * Instances of the class `TypeState` represent the state of an object representing a type.
 */
class TypeState extends InstanceState {
  /**
   * The element representing the type being modeled.
   */
  final Element _element;

  /**
   * Initialize a newly created state to represent the given value.
   *
   * @param element the element representing the type being modeled
   */
  TypeState(this._element);

  @override
  StringState convertToString() {
    if (_element == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_element.name);
  }

  @override
  bool operator ==(Object object) => object is TypeState && (_element == object._element);

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
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
  String get typeName => "Type";

  @override
  int get hashCode => _element == null ? 0 : _element.hashCode;

  @override
  String toString() => _element == null ? "-unknown-" : _element.name;
}
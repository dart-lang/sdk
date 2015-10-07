// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compile_time_constant_evaluator;

import 'common/resolution.dart' show
    Resolution;
import 'common/tasks.dart' show
    CompilerTask;
import 'compiler.dart' show
    Compiler;
import 'constant_system_dart.dart';
import 'constants/constant_system.dart';
import 'constants/evaluation.dart';
import 'constants/expressions.dart';
import 'constants/values.dart';
import 'dart_types.dart';
import 'diagnostics/diagnostic_listener.dart' show
    DiagnosticReporter;
import 'diagnostics/invariant.dart' show
    invariant;
import 'diagnostics/messages.dart' show
    MessageKind;
import 'enqueue.dart' show
    WorldImpact;
import 'elements/elements.dart';
import 'elements/modelx.dart' show
    FunctionElementX;
import 'resolution/tree_elements.dart' show
    TreeElements;
import 'resolution/operators.dart';
import 'tree/tree.dart';
import 'util/util.dart' show
    Link;
import 'universe/call_structure.dart' show
    CallStructure;

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {
  /// The [ConstantSystem] used by this environment.
  ConstantSystem get constantSystem;

  /// Returns the constant value computed for [expression].
  // TODO(johnniwinther): Support directly evaluation of [expression].
  ConstantValue getConstantValue(ConstantExpression expression);

  /// Returns the constant value for the initializer of [element].
  ConstantValue getConstantValueForVariable(VariableElement element);

  /// Returns the constant for the initializer of [element].
  ConstantExpression getConstantForVariable(VariableElement element);
}

/// A class that can compile and provide constants for variables, nodes and
/// metadata.
abstract class ConstantCompiler extends ConstantEnvironment {
  /// Compiles the compile-time constant for the initializer of [element], or
  /// reports an error if the initializer is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileConstant(VariableElement element);

  /// Computes the compile-time constant for the variable initializer,
  /// if possible.
  void compileVariable(VariableElement element);

  /// Compiles the constant for [node].
  ///
  /// Reports an error if [node] is not a compile-time constant and
  /// [enforceConst].
  ///
  /// If `!enforceConst`, then if [node] is a "runtime constant" (for example
  /// a reference to a deferred constant) it will be returned - otherwise null
  /// is returned.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true});

  /// Compiles the compile-time constant for the value [metadata], or reports an
  /// error if the value is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileMetadata(MetadataAnnotation metadata,
                                     Node node,
                                     TreeElements elements);

  /// Evaluates [constant] and caches the result.
  // TODO(johnniwinther): Remove when all constants are evaluated.
  void evaluate(ConstantExpression constant);
}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Returns the compile-time constant value associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  ConstantValue getConstantValueForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  ConstantExpression getConstantForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant value of [metadata].
  ConstantValue getConstantValueForMetadata(MetadataAnnotation metadata);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantCompiler {
  ConstantCompilerTask(Compiler compiler) : super(compiler);

  /// Copy all cached constant values from [task].
  ///
  /// This is a hack to support reuse cached compilers in memory_compiler.
  // TODO(johnniwinther): Remove this when values are computed from the
  // expressions.
  void copyConstantValues(ConstantCompilerTask task);
}

/**
 * The [ConstantCompilerBase] is provides base implementation for compilation of
 * compile-time constants for both the Dart and JavaScript interpretation of
 * constants. It keeps track of compile-time constants for initializations of
 * global and static fields, and default values of optional parameters.
 */
abstract class ConstantCompilerBase implements ConstantCompiler {
  final Compiler compiler;
  final ConstantSystem constantSystem;

  /**
   * Contains the initial values of fields and default values of parameters.
   *
   * Must contain all static and global initializations of const fields.
   *
   * May contain eagerly compiled initial values for statics and instance
   * fields (if those are compile-time constants).
   *
   * May contain default parameter values of optional arguments.
   *
   * Invariant: The keys in this map are declarations.
   */
  final Map<VariableElement, ConstantExpression> initialVariableValues =
      new Map<VariableElement, ConstantExpression>();

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables = new Set<VariableElement>();

  final Map<ConstantExpression, ConstantValue> constantValueMap =
      <ConstantExpression, ConstantValue>{};

  ConstantCompilerBase(this.compiler, this.constantSystem);

  DiagnosticReporter get reporter => compiler.reporter;

  @override
  ConstantValue getConstantValueForVariable(VariableElement element) {
    return getConstantValue(initialVariableValues[element.declaration]);
  }

  @override
  ConstantExpression getConstantForVariable(VariableElement element) {
    return initialVariableValues[element.declaration];
  }

  ConstantExpression compileConstant(VariableElement element) {
    return internalCompileVariable(element, true, true);
  }

  @override
  void evaluate(ConstantExpression constant) {
    constantValueMap.putIfAbsent(constant, () {
      return constant.evaluate(
          new _CompilerEnvironment(compiler),
          constantSystem);
    });
  }

  ConstantExpression compileVariable(VariableElement element) {
    return internalCompileVariable(element, false, true);
  }

  /// Compile [element] into a constant expression. If [isConst] is true,
  /// then [element] is a constant variable. If [checkType] is true, then
  /// report an error if [element] does not typecheck.
  ConstantExpression internalCompileVariable(
      VariableElement element, bool isConst, bool checkType) {
    if (initialVariableValues.containsKey(element.declaration)) {
      ConstantExpression result = initialVariableValues[element.declaration];
      return result;
    }
    AstElement currentElement = element.analyzableElement;
    return reporter.withCurrentElement(currentElement, () {
      // TODO(johnniwinther): Avoid this eager analysis.
      _analyzeElementEagerly(compiler, currentElement);

      ConstantExpression constant = compileVariableWithDefinitions(
          element, currentElement.resolvedAst.elements,
          isConst: isConst, checkType: checkType);
      return constant;
    });
  }

  /**
   * Returns the a compile-time constant if the variable could be compiled
   * eagerly. If the variable needs to be initialized lazily returns `null`.
   * If the variable is `const` but cannot be compiled eagerly reports an
   * error.
   */
  ConstantExpression compileVariableWithDefinitions(
      VariableElement element, TreeElements definitions,
      {bool isConst: false, bool checkType: true}) {
    Node node = element.node;
    if (pendingVariables.contains(element)) {
      if (isConst) {
        reporter.reportErrorMessage(
            node, MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS);
        ConstantExpression expression = new ErroneousConstantExpression();
        constantValueMap[expression] = constantSystem.createNull();
        return expression;
      }
      return null;
    }
    pendingVariables.add(element);

    Expression initializer = element.initializer;
    ConstantExpression expression;
    if (initializer == null) {
      // No initial value.
      expression = new NullConstantExpression();
      constantValueMap[expression] = constantSystem.createNull();
    } else {
      expression = compileNodeWithDefinitions(initializer, definitions,
          isConst: isConst);
      if (compiler.enableTypeAssertions &&
          checkType &&
          expression != null &&
          element.isField) {
        DartType elementType = element.type;
        ConstantValue value = getConstantValue(expression);
        if (elementType.isMalformed && !value.isNull) {
          if (isConst) {
            ErroneousElement element = elementType.element;
            reporter.reportErrorMessage(
                node, element.messageKind, element.messageArguments);
          } else {
            // We need to throw an exception at runtime.
            expression = null;
          }
        } else {
          DartType constantType = value.getType(compiler.coreTypes);
          if (!constantSystem.isSubtype(
              compiler.types, constantType, elementType)) {
            if (isConst) {
              reporter.reportErrorMessage(
                  node,
                  MessageKind.NOT_ASSIGNABLE,
                  {'fromType': constantType,
                   'toType': elementType});
            } else {
              // If the field cannot be lazily initialized, we will throw
              // the exception at runtime.
              expression = null;
            }
          }
        }
      }
    }
    if (expression != null) {
      initialVariableValues[element.declaration] = expression;
    } else {
      assert(invariant(element, !isConst,
          message: "Variable $element does not compile to a constant."));
    }
    pendingVariables.remove(element);
    return expression;
  }

  void cacheConstantValue(ConstantExpression expression, ConstantValue value) {
    constantValueMap[expression] = value;
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions, {bool isConst: true}) {
    assert(node != null);
    CompileTimeConstantEvaluator evaluator = new CompileTimeConstantEvaluator(
        this, definitions, compiler, isConst: isConst);
    AstConstant constant = evaluator.evaluate(node);
    if (constant != null) {
      cacheConstantValue(constant.expression, constant.value);
      return constant.expression;
    }
    return null;
  }

  ConstantValue getConstantValue(ConstantExpression expression) {
    return constantValueMap[expression];
  }

  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true}) {
    return compileNodeWithDefinitions(node, elements, isConst: enforceConst);
  }

  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }

  void forgetElement(Element element) {
    initialVariableValues.remove(element);
    if (element is ScopeContainerElement) {
      element.forEachLocalMember(initialVariableValues.remove);
    }
    if (element is FunctionElement && element.hasFunctionSignature) {
      element.functionSignature.forEachParameter(this.forgetElement);
    }
  }
}

/// [ConstantCompiler] that uses the Dart semantics for the compile-time
/// constant evaluation.
class DartConstantCompiler extends ConstantCompilerBase {
  DartConstantCompiler(Compiler compiler)
      : super(compiler, const DartConstantSystem());

  ConstantExpression getConstantForNode(Node node, TreeElements definitions) {
    return definitions.getConstant(node);
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions, {bool isConst: true}) {
    ConstantExpression constant = definitions.getConstant(node);
    if (constant != null && getConstantValue(constant) != null) {
      return constant;
    }
    constant =
        super.compileNodeWithDefinitions(node, definitions, isConst: isConst);
    if (constant != null) {
      definitions.setConstant(node, constant);
    }
    return constant;
  }
}

// TODO(johnniwinther): Decouple the creation of [ConstExp] and [Constant] from
// front-end AST in order to reuse the evaluation for the shared front-end.
class CompileTimeConstantEvaluator extends Visitor<AstConstant> {
  bool isEvaluatingConstant;
  final ConstantCompilerBase handler;
  final TreeElements elements;
  final Compiler compiler;

  Element get context => elements.analyzedElement;

  CompileTimeConstantEvaluator(this.handler, this.elements, this.compiler,
      {bool isConst: false})
      : this.isEvaluatingConstant = isConst;

  ConstantSystem get constantSystem => handler.constantSystem;
  Resolution get resolution => compiler.resolution;

  DiagnosticReporter get reporter => compiler.reporter;

  AstConstant evaluate(Node node) {
    // TODO(johnniwinther): should there be a visitErrorNode?
    if (node is ErrorNode) return new ErroneousAstConstant(context, node);
    return node.accept(this);
  }

  AstConstant evaluateConstant(Node node) {
    bool oldIsEvaluatingConstant = isEvaluatingConstant;
    isEvaluatingConstant = true;
    AstConstant result = node.accept(this);
    isEvaluatingConstant = oldIsEvaluatingConstant;
    assert(result != null);
    return result;
  }

  AstConstant visitNode(Node node) {
    return signalNotCompileTimeConstant(node);
  }

  AstConstant visitLiteralBool(LiteralBool node) {
    return new AstConstant(context, node,
        new BoolConstantExpression(node.value),
        constantSystem.createBool(node.value));
  }

  AstConstant visitLiteralDouble(LiteralDouble node) {
    return new AstConstant(context, node,
        new DoubleConstantExpression(node.value),
        constantSystem.createDouble(node.value));
  }

  AstConstant visitLiteralInt(LiteralInt node) {
    return new AstConstant(context, node, new IntConstantExpression(node.value),
        constantSystem.createInt(node.value));
  }

  AstConstant visitLiteralList(LiteralList node) {
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }
    List<ConstantExpression> argumentExpressions = <ConstantExpression>[];
    List<ConstantValue> argumentValues = <ConstantValue>[];
    for (Link<Node> link = node.elements.nodes;
        !link.isEmpty;
        link = link.tail) {
      AstConstant argument = evaluateConstant(link.head);
      if (argument == null) {
        return null;
      }
      argumentExpressions.add(argument.expression);
      argumentValues.add(argument.value);
    }
    DartType type = elements.getType(node);
    return new AstConstant(context, node,
        new ListConstantExpression(type, argumentExpressions),
        constantSystem.createList(type, argumentValues));
  }

  AstConstant visitLiteralMap(LiteralMap node) {
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }
    List<ConstantExpression> keyExpressions = <ConstantExpression>[];
    List<ConstantExpression> valueExpressions = <ConstantExpression>[];
    List<ConstantValue> keyValues = <ConstantValue>[];
    Map<ConstantValue, ConstantValue> map = <ConstantValue, ConstantValue>{};
    for (Link<Node> link = node.entries.nodes;
        !link.isEmpty;
        link = link.tail) {
      LiteralMapEntry entry = link.head;
      AstConstant key = evaluateConstant(entry.key);
      if (key == null) {
        return null;
      }
      AstConstant value = evaluateConstant(entry.value);
      if (value == null) {
        return null;
      }
      if (!map.containsKey(key.value)) {
        keyValues.add(key.value);
      } else {
        reporter.reportWarningMessage(
            entry.key, MessageKind.EQUAL_MAP_ENTRY_KEY);
      }
      keyExpressions.add(key.expression);
      valueExpressions.add(value.expression);
      map[key.value] = value.value;
    }
    InterfaceType type = elements.getType(node);
    return new AstConstant(context, node,
        new MapConstantExpression(type, keyExpressions, valueExpressions),
        constantSystem.createMap(
            compiler, type, keyValues, map.values.toList()));
  }

  AstConstant visitLiteralNull(LiteralNull node) {
    return new AstConstant(context, node, new NullConstantExpression(),
        constantSystem.createNull());
  }

  AstConstant visitLiteralString(LiteralString node) {
    return new AstConstant(context, node,
        new StringConstantExpression(node.dartString.slowToString()),
        constantSystem.createString(node.dartString));
  }

  AstConstant visitStringJuxtaposition(StringJuxtaposition node) {
    AstConstant left = evaluate(node.first);
    AstConstant right = evaluate(node.second);
    if (left == null || right == null) return null;
    StringConstantValue leftValue = left.value;
    StringConstantValue rightValue = right.value;
    return new AstConstant(context, node,
        new ConcatenateConstantExpression([left.expression, right.expression]),
        constantSystem.createString(new DartString.concat(
            leftValue.primitiveValue, rightValue.primitiveValue)));
  }

  AstConstant visitStringInterpolation(StringInterpolation node) {
    List<ConstantExpression> subexpressions = <ConstantExpression>[];
    AstConstant initialString = evaluate(node.string);
    if (initialString == null) {
      return null;
    }
    subexpressions.add(initialString.expression);
    StringConstantValue initialStringValue = initialString.value;
    DartString accumulator = initialStringValue.primitiveValue;
    for (StringInterpolationPart part in node.parts) {
      AstConstant subexpression = evaluate(part.expression);
      if (subexpression == null) {
        return null;
      }
      subexpressions.add(subexpression.expression);
      ConstantValue expression = subexpression.value;
      DartString expressionString;
      if (expression.isNum || expression.isBool) {
        PrimitiveConstantValue primitive = expression;
        expressionString =
            new DartString.literal(primitive.primitiveValue.toString());
      } else if (expression.isString) {
        PrimitiveConstantValue primitive = expression;
        expressionString = primitive.primitiveValue;
      } else {
        // TODO(johnniwinther): Specialize message to indicated that the problem
        // is not constness but the types of the const expressions.
        return signalNotCompileTimeConstant(part.expression);
      }
      accumulator = new DartString.concat(accumulator, expressionString);
      AstConstant partString = evaluate(part.string);
      if (partString == null) return null;
      subexpressions.add(partString.expression);
      StringConstantValue partStringValue = partString.value;
      accumulator =
          new DartString.concat(accumulator, partStringValue.primitiveValue);
    }
    ;
    return new AstConstant(context, node,
        new ConcatenateConstantExpression(subexpressions),
        constantSystem.createString(accumulator));
  }

  AstConstant visitLiteralSymbol(LiteralSymbol node) {
    InterfaceType type = compiler.symbolClass.rawType;
    String text = node.slowNameString;
    List<AstConstant> arguments = <AstConstant>[
      new AstConstant(context, node, new StringConstantExpression(text),
          constantSystem.createString(new LiteralDartString(text)))
    ];
    ConstructorElement constructor = compiler.symbolConstructor;
    AstConstant constant = createConstructorInvocation(
        node, type, constructor, CallStructure.ONE_ARG,
        normalizedArguments: arguments);
    return new AstConstant(
        context, node, new SymbolConstantExpression(text), constant.value);
  }

  ConstantValue makeTypeConstant(DartType elementType) {
    return constantSystem.createType(compiler, elementType);
  }

  /// Returns true if the prefix of the send resolves to a deferred import
  /// prefix.
  bool isDeferredUse(Send send) {
    if (send == null) return false;
    return compiler.deferredLoadTask.deferredPrefixElement(send, elements) !=
        null;
  }

  AstConstant visitIdentifier(Identifier node) {
    Element element = elements[node];
    if (Elements.isClass(element) || Elements.isTypedef(element)) {
      TypeDeclarationElement typeDeclarationElement = element;
      DartType type = typeDeclarationElement.rawType;
      return new AstConstant(element, node, new TypeConstantExpression(type),
          makeTypeConstant(type));
    }
    return signalNotCompileTimeConstant(node);
  }

  // TODO(floitsch): provide better error-messages.
  AstConstant visitSend(Send send) {
    Element element = elements[send];
    if (send.isPropertyAccess) {
      AstConstant result;
      if (Elements.isStaticOrTopLevelFunction(element)) {
        FunctionElementX function = element;
        function.computeType(resolution);
        result = new AstConstant(context, send,
            new FunctionConstantExpression(function),
            new FunctionConstantValue(function));
      } else if (Elements.isStaticOrTopLevelField(element)) {
        ConstantExpression elementExpression;
        if (element.isConst) {
          elementExpression = handler.compileConstant(element);
        } else if (element.isFinal && !isEvaluatingConstant) {
          elementExpression = handler.compileVariable(element);
        }
        if (elementExpression != null) {
          result = new AstConstant(context, send,
              new VariableConstantExpression(element),
              handler.getConstantValue(elementExpression));
        }
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        assert(elements.isTypeLiteral(send));
        DartType elementType = elements.getTypeLiteralType(send);
        result = new AstConstant(context, send,
            new TypeConstantExpression(elementType),
            makeTypeConstant(elementType));
      } else if (send.receiver != null) {
        if (send.selector.asIdentifier().source == "length") {
          AstConstant left = evaluate(send.receiver);
          if (left != null && left.value.isString) {
            StringConstantValue stringConstantValue = left.value;
            DartString string = stringConstantValue.primitiveValue;
            IntConstantValue length = constantSystem.createInt(string.length);
            result = new AstConstant(context, send,
                new StringLengthConstantExpression(left.expression), length);
          }
        }
        // Fall through to error handling.
      } else if (!Elements.isUnresolved(element) &&
          element.isVariable &&
          element.isConst) {
        ConstantExpression variableExpression =
            handler.compileConstant(element);
        if (variableExpression != null) {
          result = new AstConstant(context, send,
              new VariableConstantExpression(element),
              handler.getConstantValue(variableExpression));
        }
      }
      if (result == null) {
        return signalNotCompileTimeConstant(send);
      }
      if (isDeferredUse(send)) {
        if (isEvaluatingConstant) {
          reporter.reportErrorMessage(
              send, MessageKind.DEFERRED_COMPILE_TIME_CONSTANT);
        }
        PrefixElement prefix =
            compiler.deferredLoadTask.deferredPrefixElement(send, elements);
        result = new AstConstant(context, send,
            new DeferredConstantExpression(result.expression, prefix),
            new DeferredConstantValue(result.value, prefix));
        compiler.deferredLoadTask.registerConstantDeferredUse(
            result.value, prefix);
      }
      return result;
    } else if (send.isCall) {
      if (element == compiler.identicalFunction && send.argumentCount() == 2) {
        AstConstant left = evaluate(send.argumentsNode.nodes.head);
        AstConstant right = evaluate(send.argumentsNode.nodes.tail.head);
        if (left == null || right == null) {
          return null;
        }
        ConstantValue result =
            constantSystem.identity.fold(left.value, right.value);
        if (result != null) {
          return new AstConstant(context, send, new IdenticalConstantExpression(
              left.expression, right.expression), result);
        }
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isPrefix) {
      assert(send.isOperator);
      AstConstant receiverConstant = evaluate(send.receiver);
      if (receiverConstant == null) {
        return null;
      }
      Operator node = send.selector;
      UnaryOperator operator = UnaryOperator.parse(node.source);
      UnaryOperation operation = constantSystem.lookupUnary(operator);
      if (operation == null) {
        reporter.internalError(send.selector, "Unexpected operator.");
      }
      ConstantValue folded = operation.fold(receiverConstant.value);
      if (folded == null) {
        return signalNotCompileTimeConstant(send);
      }
      return new AstConstant(context, send,
          new UnaryConstantExpression(operator, receiverConstant.expression),
          folded);
    } else if (send.isOperator && !send.isPostfix) {
      assert(send.argumentCount() == 1);
      AstConstant left = evaluate(send.receiver);
      AstConstant right = evaluate(send.argumentsNode.nodes.head);
      if (left == null || right == null) {
        return null;
      }
      ConstantValue leftValue = left.value;
      ConstantValue rightValue = right.value;
      Operator node = send.selector.asOperator();
      BinaryOperator operator = BinaryOperator.parse(node.source);
      ConstantValue folded = null;
      // operator is null when `node=="is"`
      if (operator != null) {
        switch (operator.kind) {
          case BinaryOperatorKind.EQ:
            if (leftValue.isPrimitive && rightValue.isPrimitive) {
              folded = constantSystem.equal.fold(leftValue, rightValue);
            }
            break;
          case BinaryOperatorKind.NOT_EQ:
            if (leftValue.isPrimitive && rightValue.isPrimitive) {
              BoolConstantValue areEquals =
                  constantSystem.equal.fold(leftValue, rightValue);
              if (areEquals == null) {
                folded = null;
              } else {
                folded = areEquals.negate();
              }
            }
            break;
          default:
            BinaryOperation operation = constantSystem.lookupBinary(operator);
            if (operation != null) {
              folded = operation.fold(leftValue, rightValue);
            }
        }
      }
      if (folded == null) {
        return signalNotCompileTimeConstant(send);
      }
      return new AstConstant(context, send, new BinaryConstantExpression(
          left.expression, operator, right.expression), folded);
    }
    return signalNotCompileTimeConstant(send);
  }

  AstConstant visitConditional(Conditional node) {
    AstConstant condition = evaluate(node.condition);
    if (condition == null) {
      return null;
    } else if (!condition.value.isBool) {
      DartType conditionType = condition.value.getType(compiler.coreTypes);
      if (isEvaluatingConstant) {
        reporter.reportErrorMessage(
            node.condition,
            MessageKind.NOT_ASSIGNABLE,
            {'fromType': conditionType,
             'toType': compiler.boolClass.rawType});
        return new ErroneousAstConstant(context, node);
      }
      return null;
    }
    AstConstant thenExpression = evaluate(node.thenExpression);
    AstConstant elseExpression = evaluate(node.elseExpression);
    if (thenExpression == null || elseExpression == null) {
      return null;
    }
    BoolConstantValue boolCondition = condition.value;
    return new AstConstant(context, node, new ConditionalConstantExpression(
        condition.expression, thenExpression.expression,
        elseExpression.expression), boolCondition.primitiveValue
        ? thenExpression.value
        : elseExpression.value);
  }

  AstConstant visitSendSet(SendSet node) {
    return signalNotCompileTimeConstant(node);
  }

  /**
   * Returns the normalized list of constant arguments that are passed to the
   * constructor including both the concrete arguments and default values for
   * omitted optional arguments.
   *
   * Invariant: [target] must be an implementation element.
   */
  List<AstConstant> evaluateArgumentsToConstructor(Node node,
      CallStructure callStructure, Link<Node> arguments,
      ConstructorElement target, {AstConstant compileArgument(Node node)}) {
    assert(invariant(node, target.isImplementation));

    AstConstant compileDefaultValue(VariableElement element) {
      ConstantExpression constant = handler.compileConstant(element);
      return new AstConstant.fromDefaultValue(
          element, constant, handler.getConstantValue(constant));
    }
    target.computeType(resolution);

    FunctionSignature signature = target.functionSignature;
    if (!callStructure.signatureApplies(signature)) {
      String name = Elements.constructorNameForDiagnostics(
          target.enclosingClass.name, target.name);
      reporter.reportErrorMessage(
          node, MessageKind.INVALID_CONSTRUCTOR_ARGUMENTS,
          {'constructorName': name});

      return new List<AstConstant>.filled(
          target.functionSignature.parameterCount,
          new ErroneousAstConstant(context, node));
    }
    return callStructure.makeArgumentsList(
        arguments, target, compileArgument, compileDefaultValue);
  }

  AstConstant visitNewExpression(NewExpression node) {
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }

    Send send = node.send;
    ConstructorElement constructor = elements[send];
    if (Elements.isUnresolved(constructor)) {
      return signalNotCompileTimeConstant(node);
    }

    // Deferred types can not be used in const instance creation expressions.
    // Check if the constructor comes from a deferred library.
    if (isDeferredUse(node.send.selector.asSend())) {
      return signalNotCompileTimeConstant(node,
          message: MessageKind.DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION);
    }

    InterfaceType type = elements.getType(node);
    CallStructure callStructure = elements.getSelector(send).callStructure;

    return createConstructorInvocation(node, type, constructor, callStructure,
        arguments: node.send.arguments);
  }

  AstConstant createConstructorInvocation(Node node, InterfaceType type,
      ConstructorElement constructor, CallStructure callStructure,
      {Link<Node> arguments, List<AstConstant> normalizedArguments}) {
    // TODO(ahe): This is nasty: we must eagerly analyze the
    // constructor to ensure the redirectionTarget has been computed
    // correctly.  Find a way to avoid this.
    _analyzeElementEagerly(compiler, constructor);

    // The redirection chain of this element may not have been resolved through
    // a post-process action, so we have to make sure it is done here.
    compiler.resolver.resolveRedirectionChain(constructor, node);
    InterfaceType constructedType =
        constructor.computeEffectiveTargetType(type);
    ConstructorElement target = constructor.effectiveTarget;
    // The constructor must be an implementation to ensure that field
    // initializers are handled correctly.
    ConstructorElement implementation = target.implementation;

    if (implementation.isErroneous) {
      // TODO(johnniwinther): This should probably be an [ErroneousAstConstant].
      return new AstConstant(context, node, new ConstructedConstantExpression(
              type, constructor, callStructure, const <ConstantExpression>[]),
          new ConstructedConstantValue(
              constructedType, const <FieldElement, ConstantValue>{}));
    }

    List<AstConstant> concreteArguments;
    if (arguments != null) {
      Map<Node, AstConstant> concreteArgumentMap = <Node, AstConstant>{};
      for (Link<Node> link = arguments; !link.isEmpty; link = link.tail) {
        Node argument = link.head;
        NamedArgument namedArgument = argument.asNamedArgument();
        if (namedArgument != null) {
          argument = namedArgument.expression;
        }
        concreteArgumentMap[argument] = evaluateConstant(argument);
      }

      normalizedArguments = evaluateArgumentsToConstructor(
          node, callStructure, arguments, implementation,
          compileArgument: (node) => concreteArgumentMap[node]);
      concreteArguments = concreteArgumentMap.values.toList();
    } else {
      assert(normalizedArguments != null);
      concreteArguments = normalizedArguments;
    }

    if (target == compiler.intEnvironment ||
        target == compiler.boolEnvironment ||
        target == compiler.stringEnvironment) {
      return createFromEnvironmentConstant(node, constructedType, target,
          callStructure, normalizedArguments, concreteArguments);
    } else {
      return makeConstructedConstant(compiler, handler, context, node, type,
          constructor, constructedType, implementation, callStructure,
          concreteArguments, normalizedArguments);
    }
  }

  AstConstant createFromEnvironmentConstant(Node node, InterfaceType type,
      ConstructorElement constructor, CallStructure callStructure,
      List<AstConstant> normalizedArguments,
      List<AstConstant> concreteArguments) {
    var firstArgument = normalizedArguments[0].value;
    ConstantValue defaultValue = normalizedArguments[1].value;

    if (firstArgument.isNull) {
      reporter.reportErrorMessage(
          normalizedArguments[0].node, MessageKind.NULL_NOT_ALLOWED);
      return null;
    }

    if (!firstArgument.isString) {
      DartType type = defaultValue.getType(compiler.coreTypes);
      reporter.reportErrorMessage(
          normalizedArguments[0].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type,
           'toType': compiler.stringClass.rawType});
      return null;
    }

    if (constructor == compiler.intEnvironment &&
        !(defaultValue.isNull || defaultValue.isInt)) {
      DartType type = defaultValue.getType(compiler.coreTypes);
      reporter.reportErrorMessage(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type,
           'toType': compiler.intClass.rawType});
      return null;
    }

    if (constructor == compiler.boolEnvironment &&
        !(defaultValue.isNull || defaultValue.isBool)) {
      DartType type = defaultValue.getType(compiler.coreTypes);
      reporter.reportErrorMessage(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type,
           'toType': compiler.boolClass.rawType});
      return null;
    }

    if (constructor == compiler.stringEnvironment &&
        !(defaultValue.isNull || defaultValue.isString)) {
      DartType type = defaultValue.getType(compiler.coreTypes);
      reporter.reportErrorMessage(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type,
           'toType': compiler.stringClass.rawType});
      return null;
    }

    String name = firstArgument.primitiveValue.slowToString();
    String value = compiler.fromEnvironment(name);

    AstConstant createEvaluatedConstant(ConstantValue value) {
      ConstantExpression expression;
      ConstantExpression name = concreteArguments[0].expression;
      ConstantExpression defaultValue;
      if (concreteArguments.length > 1) {
        defaultValue = concreteArguments[1].expression;
      }
      if (constructor == compiler.intEnvironment) {
        expression =
            new IntFromEnvironmentConstantExpression(name, defaultValue);
      } else if (constructor == compiler.boolEnvironment) {
        expression =
            new BoolFromEnvironmentConstantExpression(name, defaultValue);
      } else if (constructor == compiler.stringEnvironment) {
        expression =
            new StringFromEnvironmentConstantExpression(name, defaultValue);
      }
      return new AstConstant(context, node, expression, value);
    }

    if (value == null) {
      return createEvaluatedConstant(defaultValue);
    } else if (constructor == compiler.intEnvironment) {
      int number = int.parse(value, onError: (_) => null);
      return createEvaluatedConstant(
          (number == null) ? defaultValue : constantSystem.createInt(number));
    } else if (constructor == compiler.boolEnvironment) {
      if (value == 'true') {
        return createEvaluatedConstant(constantSystem.createBool(true));
      } else if (value == 'false') {
        return createEvaluatedConstant(constantSystem.createBool(false));
      } else {
        return createEvaluatedConstant(defaultValue);
      }
    } else {
      assert(constructor == compiler.stringEnvironment);
      return createEvaluatedConstant(
          constantSystem.createString(new DartString.literal(value)));
    }
  }

  static AstConstant makeConstructedConstant(Compiler compiler,
      ConstantCompilerBase handler, Element context, Node node,
      InterfaceType type, ConstructorElement constructor,
      InterfaceType constructedType, ConstructorElement target,
      CallStructure callStructure, List<AstConstant> concreteArguments,
      List<AstConstant> normalizedArguments) {
    if (target.isRedirectingFactory) {
      // This happens is case of cyclic redirection.
      assert(invariant(node, compiler.compilationFailed,
          message: "makeConstructedConstant can only be called with the "
          "effective target: $constructor"));
      return new ErroneousAstConstant(context, node);
    }
    assert(invariant(node,
        callStructure.signatureApplies(constructor.functionSignature) ||
            compiler.compilationFailed,
        message: "Call structure $callStructure does not apply to constructor "
        "$constructor."));

    ConstructorEvaluator evaluator =
        new ConstructorEvaluator(constructedType, target, handler, compiler);
    evaluator.evaluateConstructorFieldValues(normalizedArguments);
    Map<FieldElement, AstConstant> fieldConstants =
        evaluator.buildFieldConstants(target.enclosingClass);
    Map<FieldElement, ConstantValue> fieldValues =
        <FieldElement, ConstantValue>{};
    fieldConstants.forEach((FieldElement field, AstConstant astConstant) {
      fieldValues[field] = astConstant.value;
    });
    return new AstConstant(context, node, new ConstructedConstantExpression(
            type, constructor, callStructure,
            concreteArguments.map((e) => e.expression).toList()),
        new ConstructedConstantValue(constructedType, fieldValues));
  }

  AstConstant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  AstConstant signalNotCompileTimeConstant(Node node,
      {MessageKind message: MessageKind.NOT_A_COMPILE_TIME_CONSTANT}) {
    if (isEvaluatingConstant) {
      reporter.reportErrorMessage(node, message);

      return new AstConstant(context, node, new ErroneousConstantExpression(),
          new NullConstantValue());
    }
    // Else we don't need to do anything. The final handler is only
    // optimistically trying to compile constants. So it is normal that we
    // sometimes see non-compile time constants.
    // Simply return [:null:] which is used to propagate a failing
    // compile-time compilation.
    return null;
  }
}

class ConstructorEvaluator extends CompileTimeConstantEvaluator {
  final InterfaceType constructedType;
  final ConstructorElement constructor;
  final Map<Element, AstConstant> definitions;
  final Map<Element, AstConstant> fieldValues;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructor] must be an implementation element.
   */
  ConstructorEvaluator(InterfaceType this.constructedType,
      FunctionElement constructor, ConstantCompiler handler, Compiler compiler)
      : this.constructor = constructor,
        this.definitions = new Map<Element, AstConstant>(),
        this.fieldValues = new Map<Element, AstConstant>(),
        super(handler, _analyzeElementEagerly(compiler, constructor), compiler,
            isConst: true) {
    assert(invariant(constructor, constructor.isImplementation));
  }

  AstConstant visitSend(Send send) {
    Element element = elements[send];
    if (Elements.isLocal(element)) {
      AstConstant constant = definitions[element];
      if (constant == null) {
        reporter.internalError(send, "Local variable without value.");
      }
      return constant;
    }
    return super.visitSend(send);
  }

  void potentiallyCheckType(TypedElement element, AstConstant constant) {
    if (compiler.enableTypeAssertions) {
      DartType elementType = element.type.substByContext(constructedType);
      DartType constantType = constant.value.getType(compiler.coreTypes);
      if (!constantSystem.isSubtype(
          compiler.types, constantType, elementType)) {
        reporter.withCurrentElement(constant.element, () {
          reporter.reportErrorMessage(
              constant.node,
              MessageKind.NOT_ASSIGNABLE,
              {'fromType': constantType,
               'toType': elementType});
        });
      }
    }
  }

  void updateFieldValue(Node node, TypedElement element, AstConstant constant) {
    potentiallyCheckType(element, constant);
    fieldValues[element] = constant;
  }

  /**
   * Given the arguments (a list of constants) assigns them to the parameters,
   * updating the definitions map. If the constructor has field-initializer
   * parameters (like [:this.x:]), also updates the [fieldValues] map.
   */
  void assignArgumentsToParameters(List<AstConstant> arguments) {
    if (constructor.isErroneous) return;
    // Assign arguments to parameters.
    FunctionSignature signature = constructor.functionSignature;
    int index = 0;
    signature.orderedForEachParameter((ParameterElement parameter) {
      AstConstant argument = arguments[index++];
      Node node = parameter.node;
      if (parameter.isInitializingFormal) {
        InitializingFormalElement initializingFormal = parameter;
        updateFieldValue(node, initializingFormal.fieldElement, argument);
      } else {
        potentiallyCheckType(parameter, argument);
        definitions[parameter] = argument;
      }
    });
  }

  void evaluateSuperOrRedirectSend(
      List<AstConstant> compiledArguments, FunctionElement targetConstructor) {
    ConstructorEvaluator evaluator = new ConstructorEvaluator(
        constructedType.asInstanceOf(targetConstructor.enclosingClass),
        targetConstructor, handler, compiler);
    evaluator.evaluateConstructorFieldValues(compiledArguments);
    // Copy over the fieldValues from the super/redirect-constructor.
    // No need to go through [updateFieldValue] because the
    // assignments have already been checked in checked mode.
    evaluator.fieldValues.forEach((key, value) => fieldValues[key] = value);
  }

  /**
   * Runs through the initializers of the given [constructor] and updates
   * the [fieldValues] map.
   */
  void evaluateConstructorInitializers() {
    if (constructor.isSynthesized) {
      List<AstConstant> compiledArguments = <AstConstant>[];

      Function compileArgument = (element) => definitions[element];
      Function compileConstant = handler.compileConstant;
      FunctionElement target = constructor.definingConstructor.implementation;
      CallStructure.addForwardingElementArgumentsToList(constructor,
          compiledArguments, target, compileArgument, compileConstant);
      evaluateSuperOrRedirectSend(compiledArguments, target);
      return;
    }
    FunctionExpression functionNode = constructor.node;
    NodeList initializerList = functionNode.initializers;

    bool foundSuperOrRedirect = false;

    if (initializerList != null) {
      for (Link<Node> link = initializerList.nodes;
          !link.isEmpty;
          link = link.tail) {
        assert(link.head is Send);
        if (link.head is! SendSet) {
          // A super initializer or constructor redirection.
          Send call = link.head;
          FunctionElement target = elements[call];
          List<AstConstant> compiledArguments = evaluateArgumentsToConstructor(
              call, elements.getSelector(call).callStructure, call.arguments,
              target, compileArgument: evaluateConstant);
          evaluateSuperOrRedirectSend(compiledArguments, target);
          foundSuperOrRedirect = true;
        } else {
          // A field initializer.
          SendSet init = link.head;
          Link<Node> initArguments = init.arguments;
          assert(!initArguments.isEmpty && initArguments.tail.isEmpty);
          AstConstant fieldValue = evaluate(initArguments.head);
          updateFieldValue(init, elements[init], fieldValue);
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.enclosingClass;
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        assert(superClass != null);
        assert(superClass.isResolved);

        FunctionElement targetConstructor =
            superClass.lookupDefaultConstructor();
        // If we do not find a default constructor, an error was reported
        // already and compilation will fail anyway. So just ignore that case.
        if (targetConstructor != null) {
          List<AstConstant> compiledArguments = evaluateArgumentsToConstructor(
              functionNode, CallStructure.NO_ARGS, const Link<Node>(),
              targetConstructor);
          evaluateSuperOrRedirectSend(compiledArguments, targetConstructor);
        }
      }
    }
  }

  /**
   * Simulates the execution of the [constructor] with the given
   * [arguments] to obtain the field values that need to be passed to the
   * native JavaScript constructor.
   */
  void evaluateConstructorFieldValues(List<AstConstant> arguments) {
    if (constructor.isErroneous) return;
    reporter.withCurrentElement(constructor, () {
      assignArgumentsToParameters(arguments);
      evaluateConstructorInitializers();
    });
  }

  /// Builds a normalized list of the constant values for each field in the
  /// inheritance chain of [classElement].
  Map<FieldElement, AstConstant> buildFieldConstants(
      ClassElement classElement) {
    Map<FieldElement, AstConstant> fieldConstants = <FieldElement, AstConstant>{
    };
    classElement.implementation
        .forEachInstanceField((ClassElement enclosing, FieldElement field) {
      AstConstant fieldValue = fieldValues[field];
      if (fieldValue == null) {
        // Use the default value.
        ConstantExpression fieldExpression =
            handler.internalCompileVariable(field, true, false);
        fieldValue = new AstConstant.fromDefaultValue(
            field, fieldExpression, handler.getConstantValue(fieldExpression));
        // TODO(het): If the field value doesn't typecheck due to the type
        // variable in the constructor invocation, then report the error on the
        // invocation rather than the field.
        potentiallyCheckType(field, fieldValue);
      }
      fieldConstants[field] = fieldValue;
    }, includeSuperAndInjectedMembers: true);
    return fieldConstants;
  }
}

/// A constant created from the front-end AST.
///
/// [element] and [node] point to the source location of the constant.
/// [expression] holds the symbolic constant expression and [value] its constant
/// value.
///
/// This class differs from [ConstantExpression] in that it is coupled to the
/// front-end AST whereas [ConstantExpression] is only coupled to the element
/// model.
class AstConstant {
  final Element element;
  final Node node;
  final ConstantExpression expression;
  final ConstantValue value;

  AstConstant(this.element, this.node, this.expression, this.value);

  factory AstConstant.fromDefaultValue(VariableElement element,
      ConstantExpression constant, ConstantValue value) {
    return new AstConstant(element, element.initializer != null
        ? element.initializer
        : element.node, constant, value);
  }

  String toString() => expression.toString();
}

/// A synthetic constant used to recover from errors.
class ErroneousAstConstant extends AstConstant {
  ErroneousAstConstant(Element element, Node node) : super(element, node,
          // TODO(johnniwinther): Return a [NonConstantValue] instead.
          new ErroneousConstantExpression(), new NullConstantValue());
}

// TODO(johnniwinther): Clean this up.
TreeElements _analyzeElementEagerly(Compiler compiler, AstElement element) {
  compiler.resolution.analyzeElement(element.declaration);
  return element.resolvedAst.elements;
}

class _CompilerEnvironment implements Environment {
  final Compiler compiler;

  _CompilerEnvironment(this.compiler);

  @override
  String readFromEnvironment(String name) {
    return compiler.fromEnvironment(name);
  }
}

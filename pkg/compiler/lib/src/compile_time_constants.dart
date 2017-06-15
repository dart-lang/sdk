// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compile_time_constant_evaluator;

import 'common/resolution.dart' show Resolution;
import 'common/tasks.dart' show CompilerTask, Measurer;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constant_system_dart.dart';
import 'constants/constant_system.dart';
import 'constants/constructors.dart';
import 'constants/evaluation.dart';
import 'constants/expressions.dart';
import 'constants/values.dart';
import 'common_elements.dart' show CommonElements;
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'elements/modelx.dart' show ConstantVariableMixin;
import 'elements/operators.dart';
import 'elements/resolution_types.dart';
import 'resolution/tree_elements.dart' show TreeElements;
import 'tree/tree.dart';
import 'universe/call_structure.dart' show CallStructure;
import 'util/util.dart' show Link;

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {
  /// The [ConstantSystem] used by this environment.
  ConstantSystem get constantSystem;

  /// Returns `true` if a value has been computed for [expression].
  bool hasConstantValue(ConstantExpression expression);

  /// Returns the constant value computed for [expression].
  // TODO(johnniwinther): Support directly evaluation of [expression].
  ConstantValue getConstantValue(ConstantExpression expression);

  /// Returns the constant value for the initializer of [element].
  @deprecated
  ConstantValue getConstantValueForVariable(VariableElement element);
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
  ConstantExpression compileVariable(VariableElement element);

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
  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements);

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

  /// Register that [element] needs lazy initialization.
  void registerLazyStatic(FieldElement element);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantCompiler {
  ConstantCompilerTask(Measurer measurer) : super(measurer);

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
  // TODO(johnniwinther): Make this purely internal when no longer used by
  // poi/forget_element_test.
  final Map<VariableElement, ConstantExpression> initialVariableValues =
      new Map<VariableElement, ConstantExpression>();

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables = new Set<VariableElement>();

  final Map<ConstantExpression, ConstantValue> constantValueMap =
      <ConstantExpression, ConstantValue>{};

  ConstantCompilerBase(this.compiler, this.constantSystem);

  DiagnosticReporter get reporter => compiler.reporter;

  CommonElements get commonElements => compiler.resolution.commonElements;

  @override
  @deprecated
  ConstantValue getConstantValueForVariable(VariableElement element) {
    ConstantExpression constant = initialVariableValues[element.declaration];
    // TODO(johnniwinther): Support eager evaluation of the constant.
    return constant != null ? getConstantValue(constant) : null;
  }

  ConstantExpression compileConstant(VariableElement element) {
    return internalCompileVariable(element, true, true);
  }

  @override
  void evaluate(ConstantExpression constant) {
    constantValueMap.putIfAbsent(constant, () {
      return constant.evaluate(
          new _CompilerEnvironment(compiler), constantSystem);
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
    if (element.hasConstant) {
      if (element.constant != null) {
        if (compiler.serialization.supportsDeserialization) {
          evaluate(element.constant);
        }
        assert(
            hasConstantValue(element.constant),
            failedAt(
                element,
                "Constant expression has not been evaluated: "
                "${element.constant.toStructuredText()}."));
      }
      return element.constant;
    }
    AstElement currentElement = element.analyzableElement;
    return reporter.withCurrentElement(element, () {
      // TODO(johnniwinther): Avoid this eager analysis.
      compiler.resolution.ensureResolved(currentElement.declaration);

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
      ConstantVariableMixin element, TreeElements definitions,
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
      if (compiler.options.enableTypeAssertions &&
          checkType &&
          expression != null &&
          element.isField) {
        ResolutionDartType elementType = element.type;
        ConstantValue value = getConstantValue(expression);
        if (elementType.isMalformed && !value.isNull) {
          if (isConst) {
            // TODO(johnniwinther): Check that it is possible to reach this
            // point in a situation where `elementType is! MalformedType`.
            if (elementType is MalformedType) {
              ErroneousElement element = elementType.element;
              reporter.reportErrorMessage(
                  node, element.messageKind, element.messageArguments);
            } else {
              assert(elementType is MethodTypeVariableType);
              reporter.reportErrorMessage(
                  node, MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED);
            }
          } else {
            // We need to throw an exception at runtime.
            expression = null;
          }
        } else {
          ResolutionDartType constantType = value.getType(commonElements);
          if (!constantSystem.isSubtype(
              compiler.types, constantType, elementType)) {
            if (isConst) {
              reporter.reportErrorMessage(node, MessageKind.NOT_ASSIGNABLE,
                  {'fromType': constantType, 'toType': elementType});
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
      element.constant = expression;
      initialVariableValues[element.declaration] = expression;
    } else {
      assert(
          !isConst,
          failedAt(
              element, "Variable $element does not compile to a constant."));
    }
    pendingVariables.remove(element);
    return expression;
  }

  void cacheConstantValue(ConstantExpression expression, ConstantValue value) {
    constantValueMap[expression] = value;
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions,
      {bool isConst: true}) {
    assert(node != null);
    CompileTimeConstantEvaluator evaluator = new CompileTimeConstantEvaluator(
        this, definitions, compiler,
        isConst: isConst);
    AstConstant constant = evaluator.evaluate(node);
    if (constant != null) {
      cacheConstantValue(constant.expression, constant.value);
      return constant.expression;
    }
    return null;
  }

  bool hasConstantValue(ConstantExpression expression) {
    return constantValueMap.containsKey(expression);
  }

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    assert(
        expression != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "ConstantExpression is null in getConstantValue."));
    // TODO(johnniwinther): ensure expressions have been evaluated at this
    // point. This can't be enabled today due to dartbug.com/26406.
    if (compiler.serialization.supportsDeserialization) {
      evaluate(expression);
    }
    ConstantValue value = constantValueMap[expression];
    if (value == null &&
        expression != null &&
        expression.kind == ConstantExpressionKind.ERRONEOUS) {
      // TODO(johnniwinther): When the Dart constant system sees a constant
      // expression as erroneous but the JavaScript constant system finds it ok
      // we have store a constant value for the erroneous constant expression.
      // Ensure the computed constant expressions are always the same; that only
      // the constant values may be different.
      value = new NullConstantValue();
    }
    return value;
  }

  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true}) {
    return compileNodeWithDefinitions(node, elements, isConst: enforceConst);
  }

  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
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
      Node node, TreeElements definitions,
      {bool isConst: true}) {
    ConstantExpression constant = definitions.getConstant(node);
    if (constant != null && hasConstantValue(constant)) {
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
  CommonElements get commonElements => resolution.commonElements;
  DiagnosticReporter get reporter => compiler.reporter;

  AstConstant evaluate(Node node) {
    // TODO(johnniwinther): should there be a visitErrorNode?
    if (node is ErrorNode) return new ErroneousAstConstant(context, node);
    AstConstant result = node.accept(this);
    assert(!isEvaluatingConstant || result != null,
        failedAt(node, "No AstConstant computed for the node."));
    return result;
  }

  AstConstant evaluateConstant(Node node) {
    bool oldIsEvaluatingConstant = isEvaluatingConstant;
    isEvaluatingConstant = true;
    AstConstant result = node.accept(this);
    isEvaluatingConstant = oldIsEvaluatingConstant;
    assert(result != null,
        failedAt(node, "No AstConstant computed for the node."));
    return result;
  }

  AstConstant visitNode(Node node) {
    return signalNotCompileTimeConstant(node);
  }

  AstConstant visitLiteralBool(LiteralBool node) {
    return new AstConstant(
        context,
        node,
        new BoolConstantExpression(node.value),
        constantSystem.createBool(node.value));
  }

  AstConstant visitLiteralDouble(LiteralDouble node) {
    return new AstConstant(
        context,
        node,
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
      if (argument == null || argument.isError) {
        return argument;
      }
      argumentExpressions.add(argument.expression);
      argumentValues.add(argument.value);
    }
    ResolutionInterfaceType type = elements.getType(node);
    return new AstConstant(
        context,
        node,
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
      if (key == null || key.isError) {
        return key;
      }
      AstConstant value = evaluateConstant(entry.value);
      if (value == null || value.isError) {
        return value;
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
    ResolutionInterfaceType type = elements.getType(node);
    return new AstConstant(
        context,
        node,
        new MapConstantExpression(type, keyExpressions, valueExpressions),
        constantSystem.createMap(
            resolution.commonElements, type, keyValues, map.values.toList()));
  }

  AstConstant visitLiteralNull(LiteralNull node) {
    return new AstConstant(context, node, new NullConstantExpression(),
        constantSystem.createNull());
  }

  AstConstant visitLiteralString(LiteralString node) {
    String text = node.dartString.slowToString();
    return new AstConstant(context, node, new StringConstantExpression(text),
        constantSystem.createString(text));
  }

  AstConstant visitStringJuxtaposition(StringJuxtaposition node) {
    AstConstant left = evaluate(node.first);
    AstConstant right = evaluate(node.second);
    if (left == null || left.isError) {
      return left;
    }
    if (right == null || right.isError) {
      return right;
    }
    StringConstantValue leftValue = left.value;
    StringConstantValue rightValue = right.value;
    return new AstConstant(
        context,
        node,
        new ConcatenateConstantExpression([left.expression, right.expression]),
        constantSystem.createString(
            leftValue.primitiveValue + rightValue.primitiveValue));
  }

  AstConstant visitStringInterpolation(StringInterpolation node) {
    List<ConstantExpression> subexpressions = <ConstantExpression>[];
    AstConstant initialString = evaluate(node.string);
    if (initialString == null || initialString.isError) {
      return initialString;
    }
    subexpressions.add(initialString.expression);
    StringBuffer sb = new StringBuffer();
    StringConstantValue initialStringValue = initialString.value;
    sb.write(initialStringValue.primitiveValue);
    for (StringInterpolationPart part in node.parts) {
      AstConstant subexpression = evaluate(part.expression);
      if (subexpression == null || subexpression.isError) {
        return subexpression;
      }
      subexpressions.add(subexpression.expression);
      ConstantValue expression = subexpression.value;
      if (expression.isPrimitive) {
        PrimitiveConstantValue primitive = expression;
        sb.write(primitive.primitiveValue);
      } else {
        // TODO(johnniwinther): Specialize message to indicated that the problem
        // is not constness but the types of the const expressions.
        return signalNotCompileTimeConstant(part.expression);
      }
      AstConstant partString = evaluate(part.string);
      if (partString == null) return null;
      subexpressions.add(partString.expression);
      StringConstantValue partStringValue = partString.value;
      sb.write(partStringValue.primitiveValue);
    }
    return new AstConstant(
        context,
        node,
        new ConcatenateConstantExpression(subexpressions),
        constantSystem.createString(sb.toString()));
  }

  AstConstant visitLiteralSymbol(LiteralSymbol node) {
    ResolutionInterfaceType type = commonElements.symbolImplementationType;
    String text = node.slowNameString;
    List<AstConstant> arguments = <AstConstant>[
      new AstConstant(context, node, new StringConstantExpression(text),
          constantSystem.createString(text))
    ];
    ConstructorElement constructor =
        resolution.commonElements.symbolConstructorTarget;
    AstConstant constant = createConstructorInvocation(
        node, type, constructor, CallStructure.ONE_ARG,
        normalizedArguments: arguments);
    return new AstConstant(
        context, node, new SymbolConstantExpression(text), constant.value);
  }

  ConstantValue makeTypeConstant(ResolutionDartType elementType) {
    return constantSystem.createType(resolution.commonElements, elementType);
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
      ResolutionDartType type = typeDeclarationElement.rawType;
      return new AstConstant(
          element,
          node,
          new TypeConstantExpression(type, typeDeclarationElement.name),
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
        MethodElement function = element;
        function.computeType(resolution);
        result = new AstConstant(
            context,
            send,
            new FunctionConstantExpression(function, function.type),
            new FunctionConstantValue(function, function.type));
      } else if (Elements.isStaticOrTopLevelField(element)) {
        ConstantExpression elementExpression;
        if (element.isConst) {
          elementExpression = handler.compileConstant(element);
        } else if (element.isFinal && !isEvaluatingConstant) {
          elementExpression = handler.compileVariable(element);
        }
        if (elementExpression != null) {
          FieldElement field = element;
          result = new AstConstant(
              context,
              send,
              new FieldConstantExpression(field),
              handler.getConstantValue(elementExpression));
        }
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        assert(elements.isTypeLiteral(send));
        ResolutionDartType elementType = elements.getTypeLiteralType(send);
        result = new AstConstant(
            context,
            send,
            new TypeConstantExpression(elementType, element.name),
            makeTypeConstant(elementType));
      } else if (send.receiver != null) {
        if (send.selector.asIdentifier().source == "length") {
          AstConstant left = evaluate(send.receiver);
          if (left != null && left.value.isString) {
            StringConstantValue stringConstantValue = left.value;
            String string = stringConstantValue.primitiveValue;
            IntConstantValue length = constantSystem.createInt(string.length);
            result = new AstConstant(context, send,
                new StringLengthConstantExpression(left.expression), length);
          }
        }
        // Fall through to error handling.
      } else if (!Elements.isUnresolved(element) &&
          element.isVariable &&
          element.isConst) {
        LocalVariableElement local = element;
        ConstantExpression variableExpression = handler.compileConstant(local);
        if (variableExpression != null) {
          result = new AstConstant(
              context,
              send,
              new LocalVariableConstantExpression(local),
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
        result = new AstConstant(
            context,
            send,
            new DeferredConstantExpression(result.expression, prefix),
            new DeferredConstantValue(result.value, prefix));
        compiler.deferredLoadTask
            .registerConstantDeferredUse(result.value, prefix);
      }
      return result;
    } else if (send.isCall) {
      if (element == resolution.commonElements.identicalFunction &&
          send.argumentCount() == 2) {
        AstConstant left = evaluate(send.argumentsNode.nodes.head);
        AstConstant right = evaluate(send.argumentsNode.nodes.tail.head);
        if (left == null || right == null) {
          return null;
        }
        ConstantValue result =
            constantSystem.identity.fold(left.value, right.value);
        if (result != null) {
          return new AstConstant(
              context,
              send,
              new IdenticalConstantExpression(
                  left.expression, right.expression),
              result);
        }
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isPrefix) {
      assert(send.isOperator);
      AstConstant receiverConstant = evaluate(send.receiver);
      if (receiverConstant == null || receiverConstant.isError) {
        return receiverConstant;
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
      return new AstConstant(
          context,
          send,
          new UnaryConstantExpression(operator, receiverConstant.expression),
          folded);
    } else if (send.isOperator && !send.isPostfix) {
      assert(send.argumentCount() == 1);
      AstConstant left = evaluate(send.receiver);
      AstConstant right = evaluate(send.argumentsNode.nodes.head);
      if (left == null || left.isError) {
        return left;
      }
      if (right == null || right.isError) {
        return right;
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
      return new AstConstant(
          context,
          send,
          new BinaryConstantExpression(
              left.expression, operator, right.expression),
          folded);
    }
    return signalNotCompileTimeConstant(send);
  }

  AstConstant visitConditional(Conditional node) {
    AstConstant condition = evaluate(node.condition);
    if (condition == null || condition.isError) {
      return condition;
    } else if (!condition.value.isBool) {
      ResolutionDartType conditionType =
          condition.value.getType(commonElements);
      if (isEvaluatingConstant) {
        reporter.reportErrorMessage(node.condition, MessageKind.NOT_ASSIGNABLE,
            {'fromType': conditionType, 'toType': commonElements.boolType});
        return new ErroneousAstConstant(context, node);
      }
      return null;
    }
    AstConstant thenExpression = evaluate(node.thenExpression);
    AstConstant elseExpression = evaluate(node.elseExpression);
    if (thenExpression == null || thenExpression.isError) {
      return thenExpression;
    }
    if (elseExpression == null || elseExpression.isError) {
      return elseExpression;
    }
    BoolConstantValue boolCondition = condition.value;
    return new AstConstant(
        context,
        node,
        new ConditionalConstantExpression(condition.expression,
            thenExpression.expression, elseExpression.expression),
        boolCondition.primitiveValue
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
  List<AstConstant> evaluateArgumentsToConstructor(
      Node node,
      CallStructure callStructure,
      Link<Node> arguments,
      ConstructorElement target,
      {AstConstant compileArgument(Node node)}) {
    assert(target.isImplementation, failedAt(node));

    AstConstant compileDefaultValue(VariableElement element) {
      ConstantExpression constant = handler.compileConstant(element);
      return new AstConstant.fromDefaultValue(
          element, constant, handler.getConstantValue(constant));
    }

    target.computeType(resolution);

    if (!callStructure.signatureApplies(target.parameterStructure)) {
      String name = Elements.constructorNameForDiagnostics(
          target.enclosingClass.name, target.name);
      reporter.reportErrorMessage(node,
          MessageKind.INVALID_CONSTRUCTOR_ARGUMENTS, {'constructorName': name});

      return new List<AstConstant>.filled(
          target.functionSignature.parameterCount,
          new ErroneousAstConstant(context, node));
    }
    return Elements.makeArgumentsList<AstConstant>(
        callStructure, arguments, target, compileArgument, compileDefaultValue);
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

    ResolutionInterfaceType type = elements.getType(node);
    CallStructure callStructure = elements.getSelector(send).callStructure;

    return createConstructorInvocation(node, type, constructor, callStructure,
        arguments: node.send.arguments);
  }

  AstConstant createConstructorInvocation(
      Node node,
      ResolutionInterfaceType type,
      ConstructorElement constructor,
      CallStructure callStructure,
      {Link<Node> arguments,
      List<AstConstant> normalizedArguments}) {
    // TODO(ahe): This is nasty: we must eagerly analyze the
    // constructor to ensure the redirectionTarget has been computed
    // correctly.  Find a way to avoid this.
    resolution.ensureResolved(constructor.declaration);

    // The redirection chain of this element may not have been resolved through
    // a post-process action, so we have to make sure it is done here.
    compiler.resolver.resolveRedirectionChain(constructor, node);

    bool isInvalid = false;
    ResolutionInterfaceType constructedType = type;
    ConstructorElement implementation;
    if (constructor.isRedirectingFactory) {
      if (constructor.isEffectiveTargetMalformed) {
        isInvalid = true;
      } else {
        constructedType = constructor.computeEffectiveTargetType(type);
        ConstructorElement target = constructor.effectiveTarget;
        // The constructor must be an implementation to ensure that field
        // initializers are handled correctly.
        implementation = target.implementation;
      }
    } else {
      // The constructor must be an implementation to ensure that field
      // initializers are handled correctly.
      implementation = constructor.implementation;
      isInvalid = implementation.isMalformed;
      if (implementation.isGenerativeConstructor &&
          constructor.enclosingClass.isAbstract) {
        isInvalid = true;
      }
    }
    if (isInvalid) {
      return signalNotCompileTimeConstant(node);
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
    if (constructor.isFromEnvironmentConstructor) {
      return createFromEnvironmentConstant(node, constructedType, constructor,
          callStructure, normalizedArguments, concreteArguments);
    } else if (compiler.serialization.isDeserialized(constructor)) {
      ConstructedConstantExpression expression =
          new ConstructedConstantExpression(type, constructor, callStructure,
              concreteArguments.map((c) => c.expression).toList());
      return new AstConstant(
          context,
          node,
          expression,
          expression.evaluate(
              new _CompilerEnvironment(compiler), constantSystem));
    } else {
      return makeConstructedConstant(
          compiler,
          handler,
          context,
          node,
          type,
          constructor,
          constructedType,
          implementation,
          callStructure,
          concreteArguments,
          normalizedArguments);
    }
  }

  AstConstant createFromEnvironmentConstant(
      Node node,
      ResolutionInterfaceType type,
      ConstructorElement constructor,
      CallStructure callStructure,
      List<AstConstant> normalizedArguments,
      List<AstConstant> concreteArguments) {
    dynamic firstArgument = normalizedArguments[0].value;
    ConstantValue defaultValue = normalizedArguments[1].value;

    if (firstArgument.isNull) {
      return reportNotCompileTimeConstant(
          normalizedArguments[0].node, MessageKind.NULL_NOT_ALLOWED);
    }

    if (!firstArgument.isString) {
      ResolutionDartType type = defaultValue.getType(commonElements);
      return reportNotCompileTimeConstant(
          normalizedArguments[0].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type, 'toType': commonElements.stringType});
    }

    if (constructor.isIntFromEnvironmentConstructor &&
        !(defaultValue.isNull || defaultValue.isInt)) {
      ResolutionDartType type = defaultValue.getType(commonElements);
      return reportNotCompileTimeConstant(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type, 'toType': commonElements.intType});
    }

    if (constructor.isBoolFromEnvironmentConstructor &&
        !(defaultValue.isNull || defaultValue.isBool)) {
      ResolutionDartType type = defaultValue.getType(commonElements);
      return reportNotCompileTimeConstant(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type, 'toType': commonElements.boolType});
    }

    if (constructor.isStringFromEnvironmentConstructor &&
        !(defaultValue.isNull || defaultValue.isString)) {
      ResolutionDartType type = defaultValue.getType(commonElements);
      return reportNotCompileTimeConstant(
          normalizedArguments[1].node,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': type, 'toType': commonElements.stringType});
    }

    String name = firstArgument.primitiveValue;
    String value = compiler.fromEnvironment(name);

    AstConstant createEvaluatedConstant(ConstantValue value) {
      ConstantExpression expression;
      ConstantExpression name = concreteArguments[0].expression;
      ConstantExpression defaultValue;
      if (concreteArguments.length > 1) {
        defaultValue = concreteArguments[1].expression;
      }
      if (constructor.isIntFromEnvironmentConstructor) {
        expression =
            new IntFromEnvironmentConstantExpression(name, defaultValue);
      } else if (constructor.isBoolFromEnvironmentConstructor) {
        expression =
            new BoolFromEnvironmentConstantExpression(name, defaultValue);
      } else if (constructor.isStringFromEnvironmentConstructor) {
        expression =
            new StringFromEnvironmentConstantExpression(name, defaultValue);
      }
      assert(expression != null);
      return new AstConstant(context, node, expression, value);
    }

    if (value == null) {
      return createEvaluatedConstant(defaultValue);
    } else if (constructor.isIntFromEnvironmentConstructor) {
      int number = int.parse(value, onError: (_) => null);
      return createEvaluatedConstant(
          (number == null) ? defaultValue : constantSystem.createInt(number));
    } else if (constructor.isBoolFromEnvironmentConstructor) {
      if (value == 'true') {
        return createEvaluatedConstant(constantSystem.createBool(true));
      } else if (value == 'false') {
        return createEvaluatedConstant(constantSystem.createBool(false));
      } else {
        return createEvaluatedConstant(defaultValue);
      }
    } else {
      assert(constructor.isStringFromEnvironmentConstructor);
      return createEvaluatedConstant(constantSystem.createString(value));
    }
  }

  static AstConstant makeConstructedConstant(
      Compiler compiler,
      ConstantCompilerBase handler,
      Element context,
      Node node,
      ResolutionInterfaceType type,
      ConstructorElement constructor,
      ResolutionInterfaceType constructedType,
      ConstructorElement target,
      CallStructure callStructure,
      List<AstConstant> concreteArguments,
      List<AstConstant> normalizedArguments) {
    if (target.isRedirectingFactory) {
      // This happens in case of cyclic redirection.
      assert(
          compiler.compilationFailed,
          failedAt(
              node,
              "makeConstructedConstant can only be called with the "
              "effective target: $constructor"));
      return new ErroneousAstConstant(context, node);
    }
    assert(
        callStructure.signatureApplies(constructor.parameterStructure) ||
            compiler.compilationFailed,
        failedAt(
            node,
            "Call structure $callStructure does not apply to constructor "
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
    for (AstConstant fieldValue in fieldConstants.values) {
      if (fieldValue.isError) {
        return fieldValue;
      }
    }
    return new AstConstant(
        context,
        node,
        new ConstructedConstantExpression(type, constructor, callStructure,
            concreteArguments.map((e) => e.expression).toList()),
        new ConstructedConstantValue(constructedType, fieldValues));
  }

  AstConstant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  AstConstant reportNotCompileTimeConstant(Node node, MessageKind message,
      [Map arguments = const {}]) {
    reporter.reportErrorMessage(node, message, arguments);
    return new AstConstant(context, node, new ErroneousConstantExpression(),
        new NullConstantValue());
  }

  AstConstant signalNotCompileTimeConstant(Node node,
      {MessageKind message: MessageKind.NOT_A_COMPILE_TIME_CONSTANT,
      Map arguments: const {}}) {
    if (isEvaluatingConstant) {
      return reportNotCompileTimeConstant(node, message, arguments);
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
  final ResolutionInterfaceType constructedType;
  final ConstructorElement constructor;
  final Map<Element, AstConstant> definitions;
  final Map<Element, AstConstant> fieldValues;
  final ResolvedAst resolvedAst;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructor] must be an implementation element.
   */
  ConstructorEvaluator(
      ResolutionInterfaceType this.constructedType,
      ConstructorElement constructor,
      ConstantCompiler handler,
      Compiler compiler)
      : this.constructor = constructor,
        this.definitions = new Map<Element, AstConstant>(),
        this.fieldValues = new Map<Element, AstConstant>(),
        this.resolvedAst =
            compiler.resolution.computeResolvedAst(constructor.declaration),
        super(handler, null, compiler, isConst: true) {
    assert(constructor.isImplementation, failedAt(constructor));
  }

  @override
  Element get context => resolvedAst.element;

  @override
  TreeElements get elements => resolvedAst.elements;

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
    if (compiler.options.enableTypeAssertions) {
      ResolutionDartType elementType =
          element.type.substByContext(constructedType);
      ResolutionDartType constantType = constant.value.getType(commonElements);
      if (!constantSystem.isSubtype(
          compiler.types, constantType, elementType)) {
        reporter.withCurrentElement(constant.element, () {
          reporter.reportErrorMessage(constant.node, MessageKind.NOT_ASSIGNABLE,
              {'fromType': constantType, 'toType': elementType});
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
    if (constructor.isMalformed) return;
    // Assign arguments to parameters.
    FunctionSignature signature = constructor.functionSignature;
    int index = 0;
    signature.orderedForEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      AstConstant argument = arguments[index++];
      Node node = parameter.node;
      if (parameter.isInitializingFormal) {
        InitializingFormalElement initializingFormal = parameter;
        updateFieldValue(node, initializingFormal.fieldElement, argument);
      } else {
        potentiallyCheckType(parameter, argument);
      }
      definitions[parameter] = argument;
    });
  }

  void evaluateSuperOrRedirectSend(List<AstConstant> compiledArguments,
      CallStructure callStructure, ConstructorElement targetConstructor) {
    ResolutionInterfaceType type =
        constructedType.asInstanceOf(targetConstructor.enclosingClass);
    if (compiler.serialization.isDeserialized(targetConstructor)) {
      List<ConstantExpression> arguments =
          compiledArguments.map((c) => c.expression).toList();
      ConstructedConstantExpression expression =
          new ConstructedConstantExpression(
              type, targetConstructor, callStructure, arguments);

      Map<FieldEntity, ConstantExpression> fields =
          expression.computeInstanceFields(new _CompilerEnvironment(compiler));
      fields.forEach((_field, ConstantExpression expression) {
        FieldElement field = _field;
        ConstantValue value = expression.evaluate(
            new _CompilerEnvironment(compiler), constantSystem);
        fieldValues[field] = new AstConstant(context, null, expression, value);
      });
    } else {
      ConstructorEvaluator evaluator =
          new ConstructorEvaluator(type, targetConstructor, handler, compiler);
      evaluator.evaluateConstructorFieldValues(compiledArguments);
      // Copy over the fieldValues from the super/redirect-constructor.
      // No need to go through [updateFieldValue] because the
      // assignments have already been checked in checked mode.
      evaluator.fieldValues.forEach((key, value) => fieldValues[key] = value);
    }
  }

  /**
   * Runs through the initializers of the given [constructor] and updates
   * the [fieldValues] map.
   */
  void evaluateConstructorInitializers() {
    ResolvedAst resolvedAst = constructor.resolvedAst;
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      List<AstConstant> compiledArguments = <AstConstant>[];

      Function compileArgument = (element) => definitions[element];
      Function compileConstant = handler.compileConstant;
      FunctionElement target = constructor.definingConstructor.implementation;
      Elements.addForwardingElementArgumentsToList(constructor,
          compiledArguments, target, compileArgument, compileConstant);
      CallStructure callStructure = new CallStructure(
          target.functionSignature.parameterCount, target.type.namedParameters);
      evaluateSuperOrRedirectSend(compiledArguments, callStructure, target);
      return;
    }
    FunctionExpression functionNode = resolvedAst.node;
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
          if (!target.isMalformed) {
            CallStructure callStructure =
                elements.getSelector(call).callStructure;
            List<AstConstant> compiledArguments =
                evaluateArgumentsToConstructor(
                    call, callStructure, call.arguments, target,
                    compileArgument: evaluateConstant);
            evaluateSuperOrRedirectSend(
                compiledArguments, callStructure, target);
          }
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
      if (!enclosingClass.isObject) {
        assert(superClass != null);
        assert(superClass.isResolved);

        FunctionElement targetConstructor =
            superClass.lookupDefaultConstructor();
        // If we do not find a default constructor, an error was reported
        // already and compilation will fail anyway. So just ignore that case.
        if (targetConstructor != null) {
          CallStructure callStructure = CallStructure.NO_ARGS;
          List<AstConstant> compiledArguments = evaluateArgumentsToConstructor(
              functionNode,
              callStructure,
              const Link<Node>(),
              targetConstructor);
          evaluateSuperOrRedirectSend(
              compiledArguments, callStructure, targetConstructor);
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
    if (constructor.isMalformed) return;
    reporter.withCurrentElement(constructor, () {
      assignArgumentsToParameters(arguments);
      evaluateConstructorInitializers();
    });
  }

  /// Builds a normalized list of the constant values for each field in the
  /// inheritance chain of [classElement].
  Map<FieldElement, AstConstant> buildFieldConstants(
      ClassElement classElement) {
    Map<FieldElement, AstConstant> fieldConstants =
        <FieldElement, AstConstant>{};
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, FieldElement field) {
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
    return new AstConstant(
        element,
        element.initializer != null ? element.initializer : element.node,
        constant,
        value);
  }

  bool get isError => expression.kind == ConstantExpressionKind.ERRONEOUS;

  String toString() => expression.toString();
}

/// A synthetic constant used to recover from errors.
class ErroneousAstConstant extends AstConstant {
  ErroneousAstConstant(Element element, Node node)
      : super(
            element,
            node,
            // TODO(johnniwinther): Return a [NonConstantValue] instead.
            new ErroneousConstantExpression(),
            new NullConstantValue());
}

class _CompilerEnvironment implements EvaluationEnvironment {
  final Compiler _compiler;

  _CompilerEnvironment(this._compiler);

  @override
  CommonElements get commonElements => _compiler.resolution.commonElements;

  @override
  String readFromEnvironment(String name) {
    return _compiler.fromEnvironment(name);
  }

  @override
  ResolutionInterfaceType substByContext(
      ResolutionInterfaceType base, ResolutionInterfaceType target) {
    return base.substByContext(target);
  }

  @override
  ConstantConstructor getConstructorConstant(ConstructorElement constructor) {
    return constructor.constantConstructor;
  }

  @override
  ConstantExpression getFieldConstant(FieldElement field) {
    return field.constant;
  }

  @override
  ConstantExpression getLocalConstant(LocalVariableElement local) {
    return local.constant;
  }
}

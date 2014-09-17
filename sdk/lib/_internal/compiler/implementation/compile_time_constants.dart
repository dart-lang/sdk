// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {
  /// Returns the constant for the initializer of [element].
  ConstExp getConstantForVariable(VariableElement element);
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
  ConstExp compileConstant(VariableElement element);

  /// Computes the compile-time constant for the variable initializer,
  /// if possible.
  void compileVariable(VariableElement element);

  /// Compiles the compile-time constant for [node], or reports an error if
  /// [node] is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstExp compileNode(Node node, TreeElements elements);

  /// Compiles the compile-time constant for the value [metadata], or reports an
  /// error if the value is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstExp compileMetadata(MetadataAnnotation metadata,
                           Node node, TreeElements elements);
}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Returns the compile-time constant associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  ConstExp getConstantForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant value of [metadata].
  ConstExp getConstantForMetadata(MetadataAnnotation metadata);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantCompiler {
  ConstantCompilerTask(Compiler compiler) : super(compiler);
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
   * Contains the initial value of fields. Must contain all static and global
   * initializations of const fields. May contain eagerly compiled values for
   * statics and instance fields.
   *
   * Invariant: The keys in this map are declarations.
   */
  final Map<VariableElement, ConstExp> initialVariableValues =
      new Map<VariableElement, ConstExp>();

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables = new Set<VariableElement>();

  ConstantCompilerBase(this.compiler, this.constantSystem);

  ConstExp getConstantForVariable(VariableElement element) {
    return initialVariableValues[element.declaration];
  }

  ConstExp compileConstant(VariableElement element) {
    return compileVariable(element, isConst: true);
  }

  ConstExp compileVariable(VariableElement element, {bool isConst: false}) {

    if (initialVariableValues.containsKey(element.declaration)) {
      ConstExp result = initialVariableValues[element.declaration];
      return result;
    }
    AstElement currentElement = element.analyzableElement;
    return compiler.withCurrentElement(currentElement, () {
      compiler.analyzeElement(currentElement.declaration);
      ConstExp constant = compileVariableWithDefinitions(
          element, currentElement.resolvedAst.elements, isConst: isConst);
      return constant;
    });
  }

  /**
   * Returns the a compile-time constant if the variable could be compiled
   * eagerly. If the variable needs to be initialized lazily returns `null`.
   * If the variable is `const` but cannot be compiled eagerly reports an
   * error.
   */
  ConstExp compileVariableWithDefinitions(VariableElement element,
                                          TreeElements definitions,
                                          {bool isConst: false}) {
    Node node = element.node;
    if (pendingVariables.contains(element)) {
      if (isConst) {
        compiler.reportFatalError(
            node, MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS);
      }
      return null;
    }
    pendingVariables.add(element);

    Expression initializer = element.initializer;
    ConstExp value;
    if (initializer == null) {
      // No initial value.
      value = new PrimitiveConstExp(new NullConstant());
    } else {
      value = compileNodeWithDefinitions(
          initializer, definitions, isConst: isConst);
      if (compiler.enableTypeAssertions &&
          value != null &&
          element.isField) {
        DartType elementType = element.type;
        if (elementType.isMalformed && !value.value.isNull) {
          if (isConst) {
            ErroneousElement element = elementType.element;
            compiler.reportFatalError(
                node, element.messageKind, element.messageArguments);
          } else {
            // We need to throw an exception at runtime.
            value = null;
          }
        } else {
          DartType constantType = value.value.computeType(compiler);
          if (!constantSystem.isSubtype(compiler,
                                        constantType, elementType)) {
            if (isConst) {
              compiler.reportFatalError(
                  node, MessageKind.NOT_ASSIGNABLE,
                  {'fromType': constantType, 'toType': elementType});
            } else {
              // If the field cannot be lazily initialized, we will throw
              // the exception at runtime.
              value = null;
            }
          }
        }
      }
    }
    if (value != null) {
      initialVariableValues[element.declaration] = value;
    } else {
      assert(invariant(element, !isConst,
             message: "Variable $element does not compile to a constant."));
    }
    pendingVariables.remove(element);
    return value;
  }

  ConstExp compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    assert(node != null);
    CompileTimeConstantEvaluator evaluator = new CompileTimeConstantEvaluator(
        this, definitions, compiler, isConst: isConst);
    AstConstant constant = evaluator.evaluate(node);
    return constant != null ? constant.expression : null;
  }

  ConstExp compileNode(Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }

  ConstExp compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }
}

/// [ConstantCompiler] that uses the Dart semantics for the compile-time
/// constant evaluation.
class DartConstantCompiler extends ConstantCompilerBase {
  DartConstantCompiler(Compiler compiler)
      : super(compiler, const DartConstantSystem());

  ConstExp getConstantForNode(Node node, TreeElements definitions) {
    return definitions.getConstant(node);
  }

  ConstExp getConstantForMetadata(MetadataAnnotation metadata) {
    return metadata.constant;
  }

  ConstExp compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    ConstExp constant = definitions.getConstant(node);
    if (constant != null) {
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

  CompileTimeConstantEvaluator(this.handler,
                               this.elements,
                               this.compiler,
                               {bool isConst: false})
      : this.isEvaluatingConstant = isConst;

  ConstantSystem get constantSystem => handler.constantSystem;

  AstConstant evaluate(Node node) {
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
    return new AstConstant(
        context, node, new PrimitiveConstExp(
            constantSystem.createBool(node.value)));
  }

  AstConstant visitLiteralDouble(LiteralDouble node) {
    return new AstConstant(
        context, node, new PrimitiveConstExp(
            constantSystem.createDouble(node.value)));
  }

  AstConstant visitLiteralInt(LiteralInt node) {
    return new AstConstant(
        context, node, new PrimitiveConstExp(
            constantSystem.createInt(node.value)));
  }

  AstConstant visitLiteralList(LiteralList node) {
    if (!node.isConst)  {
      return signalNotCompileTimeConstant(node);
    }
    List<ConstExp> argumentExpressions = <ConstExp>[];
    List<Constant> argumentValues = <Constant>[];
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
    return new AstConstant(
        context, node, new ListConstExp(
            new ListConstant(type, argumentValues),
            type,
            argumentExpressions));
  }

  AstConstant visitLiteralMap(LiteralMap node) {
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }
    List<ConstExp> keyExpressions = <ConstExp>[];
    List<Constant> keyValues = <Constant>[];
    Map<Constant, ConstExp> map = new Map<Constant, ConstExp>();
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      AstConstant key = evaluateConstant(entry.key);
      if (key == null) {
        return null;
      }
      if (!map.containsKey(key.value)) {
        keyExpressions.add(key.expression);
        keyValues.add(key.value);
      } else {
        compiler.reportWarning(entry.key, MessageKind.EQUAL_MAP_ENTRY_KEY);
      }
      AstConstant value = evaluateConstant(entry.value);
      if (value == null) {
        return null;
      }
      map[key.value] = value.expression;
    }
    List<ConstExp> valueExpressions = map.values.toList();
    InterfaceType type = elements.getType(node);
    return new AstConstant(
        context, node, new MapConstExp(
            constantSystem.createMap(compiler, type, keyValues,
                valueExpressions.map((e) => e.value).toList()),
            type,
            keyExpressions,
            valueExpressions));
  }

  AstConstant visitLiteralNull(LiteralNull node) {
    return new AstConstant(
        context, node, new PrimitiveConstExp(
            constantSystem.createNull()));
  }

  AstConstant visitLiteralString(LiteralString node) {
    return new AstConstant(
        context, node, new PrimitiveConstExp(
            constantSystem.createString(node.dartString)));
  }

  AstConstant visitStringJuxtaposition(StringJuxtaposition node) {
    AstConstant left = evaluate(node.first);
    AstConstant right = evaluate(node.second);
    if (left == null || right == null) return null;
    StringConstant leftValue = left.value;
    StringConstant rightValue = right.value;
    return new AstConstant(
        context, node, new ConcatenateConstExp(
            constantSystem.createString(
                new DartString.concat(leftValue.value, rightValue.value)),
            [left.expression, right.expression]));
  }

  AstConstant visitStringInterpolation(StringInterpolation node) {
    List<ConstExp> subexpressions = <ConstExp>[];
    AstConstant initialString = evaluate(node.string);
    if (initialString == null) {
      return null;
    }
    subexpressions.add(initialString.expression);
    StringConstant initialStringValue = initialString.value;
    DartString accumulator = initialStringValue.value;
    for (StringInterpolationPart part in node.parts) {
      AstConstant subexpression = evaluate(part.expression);
      if (subexpression == null) {
        return null;
      }
      subexpressions.add(subexpression.expression);
      Constant expression = subexpression.value;
      DartString expressionString;
      if (expression.isNum || expression.isBool) {
        PrimitiveConstant primitive = expression;
        expressionString = new DartString.literal(primitive.value.toString());
      } else if (expression.isString) {
        PrimitiveConstant primitive = expression;
        expressionString = primitive.value;
      } else {
        // TODO(johnniwinther): Specialize message to indicated that the problem
        // is not constness but the types of the const expressions.
        return signalNotCompileTimeConstant(part.expression);
      }
      accumulator = new DartString.concat(accumulator, expressionString);
      AstConstant partString = evaluate(part.string);
      if (partString == null) return null;
      subexpressions.add(partString.expression);
      StringConstant partStringValue = partString.value;
      accumulator = new DartString.concat(accumulator, partStringValue.value);
    };
    return new AstConstant(
        context, node, new ConcatenateConstExp(
          constantSystem.createString(accumulator),
          subexpressions));
  }

  AstConstant visitLiteralSymbol(LiteralSymbol node) {
    InterfaceType type = compiler.symbolClass.rawType;
    String text = node.slowNameString;
    List<AstConstant> arguments =
        <AstConstant>[new AstConstant(context, node,
          new PrimitiveConstExp(constantSystem.createString(
              new DartString.literal(text))))];
    AstConstant constant = makeConstructedConstant(
        compiler, handler, context, node, type, compiler.symbolConstructor,
        new Selector.callConstructor('', null, 1),
        arguments, arguments);
    return new AstConstant(
        context, node, new SymbolConstExp(constant.value, text));
  }

  AstConstant makeTypeConstant(Node node, DartType elementType) {
    DartType constantType =
        compiler.backend.typeImplementation.computeType(compiler);
    return new AstConstant(
        context, node, new TypeConstExp(
            new TypeConstant(elementType, constantType),
            elementType));
  }

  /// Returns true if the prefix of the send resolves to a deferred import
  /// prefix.
  bool isDeferredUse(Send send) {
    if (send == null) return false;
    return compiler.deferredLoadTask
        .deferredPrefixElement(send, elements) != null;
  }

  AstConstant visitIdentifier(Identifier node) {
    Element element = elements[node];
    if (Elements.isClass(element) || Elements.isTypedef(element)) {
      TypeDeclarationElement typeDeclarationElement = element;
      DartType type = typeDeclarationElement.rawType;
      return makeTypeConstant(node, type);
    }
    return signalNotCompileTimeConstant(node);
  }

  // TODO(floitsch): provide better error-messages.
  AstConstant visitSend(Send send) {
    Element element = elements[send];
    if (send.isPropertyAccess) {
      if (isDeferredUse(send)) {
        return signalNotCompileTimeConstant(send,
            message: MessageKind.DEFERRED_COMPILE_TIME_CONSTANT);
      }
      if (Elements.isStaticOrTopLevelFunction(element)) {
        return new AstConstant(
            context, send, new FunctionConstExp(
                new FunctionConstant(element),
                element));
      } else if (Elements.isStaticOrTopLevelField(element)) {
        ConstExp result;
        if (element.isConst) {
          result = handler.compileConstant(element);
        } else if (element.isFinal && !isEvaluatingConstant) {
          result = handler.compileVariable(element);
        }
        if (result != null) {
          return new AstConstant(
              context, send, new VariableConstExp(result.value, element));
        }
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        assert(elements.isTypeLiteral(send));
        return makeTypeConstant(send, elements.getTypeLiteralType(send));
      } else if (send.receiver != null) {
        // Fall through to error handling.
      } else if (!Elements.isUnresolved(element)
                 && element.isVariable
                 && element.isConst) {
        ConstExp result = handler.compileConstant(element);
        if (result != null) {
          return new AstConstant(
              context, send, new VariableConstExp(result.value, element));
        }
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isCall) {
      if (identical(element, compiler.identicalFunction)
          && send.argumentCount() == 2) {
        AstConstant left = evaluate(send.argumentsNode.nodes.head);
        AstConstant right = evaluate(send.argumentsNode.nodes.tail.head);
        if (left == null || right == null) {
          return null;
        }
        Constant result = constantSystem.identity.fold(left.value, right.value);
        if (result != null) {
          return new AstConstant(
              context, send, new BinaryConstExp(result,
                  left.expression, 'identical', right.expression));
        }
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isPrefix) {
      assert(send.isOperator);
      AstConstant receiverConstant = evaluate(send.receiver);
      if (receiverConstant == null) {
        return null;
      }
      Operator op = send.selector;
      UnaryOperation operation = constantSystem.lookupUnary(op.source);
      if (operation == null) {
        compiler.internalError(op, "Unexpected operator.");
      }
      Constant folded = operation.fold(receiverConstant.value);
      if (folded == null) {
        return signalNotCompileTimeConstant(send);
      }
      return new AstConstant(
          context, send, new UnaryConstExp(folded,
              op.source, receiverConstant.expression));
    } else if (send.isOperator && !send.isPostfix) {
      assert(send.argumentCount() == 1);
      AstConstant left = evaluate(send.receiver);
      AstConstant right = evaluate(send.argumentsNode.nodes.head);
      if (left == null || right == null) {
        return null;
      }
      Constant leftValue = left.value;
      Constant rightValue = right.value;
      Operator op = send.selector.asOperator();
      Constant folded = null;
      switch (op.source) {
        case "==":
          if (leftValue.isPrimitive && rightValue.isPrimitive) {
            folded = constantSystem.equal.fold(leftValue, rightValue);
          }
          break;
        case "!=":
          if (leftValue.isPrimitive && rightValue.isPrimitive) {
            BoolConstant areEquals =
                constantSystem.equal.fold(leftValue, rightValue);
            if (areEquals == null) {
              folded = null;
            } else {
              folded = areEquals.negate();
            }
          }
          break;
        default:
          BinaryOperation operation = constantSystem.lookupBinary(op.source);
          if (operation != null) {
            folded = operation.fold(leftValue, rightValue);
          }
      }
      if (folded == null) {
        return signalNotCompileTimeConstant(send);
      }
      return new AstConstant(
          context, send, new BinaryConstExp(folded,
              left.expression, op.source, right.expression));
    }
    return signalNotCompileTimeConstant(send);
  }

  AstConstant visitConditional(Conditional node) {
    AstConstant condition = evaluate(node.condition);
    if (condition == null) {
      return null;
    } else if (!condition.value.isBool) {
      DartType conditionType = condition.value.computeType(compiler);
      if (isEvaluatingConstant) {
        compiler.reportFatalError(
            node.condition, MessageKind.NOT_ASSIGNABLE,
            {'fromType': conditionType, 'toType': compiler.boolClass.rawType});
      }
      return null;
    }
    AstConstant thenExpression = evaluate(node.thenExpression);
    AstConstant elseExpression = evaluate(node.elseExpression);
    if (thenExpression == null || elseExpression == null) {
      return null;
    }
    BoolConstant boolCondition = condition.value;
    return new AstConstant(
        context, node, new ConditionalConstExp(
            boolCondition.value ? thenExpression.value : elseExpression.value,
            condition.expression,
            thenExpression.expression,
            elseExpression.expression));
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
      Selector selector,
      Link<Node> arguments,
      FunctionElement target,
      {AstConstant compileArgument(Node node)}) {
    assert(invariant(node, target.isImplementation));
    List<AstConstant> compiledArguments = <AstConstant>[];

    AstConstant compileDefaultValue(VariableElement element) {
      ConstExp constant = handler.compileConstant(element);
      return new AstConstant.fromDefaultValue(element, constant);
    }
    target.computeSignature(compiler);
    bool succeeded = selector.addArgumentsToList(arguments,
                                                 compiledArguments,
                                                 target,
                                                 compileArgument,
                                                 compileDefaultValue,
                                                 compiler.world);
    if (!succeeded) {
      String name = Elements.constructorNameForDiagnostics(
          target.enclosingClass.name, target.name);
      compiler.reportFatalError(
          node,
          MessageKind.INVALID_CONSTRUCTOR_ARGUMENTS,
          {'constructorName': name});
    }
    return compiledArguments;
  }

  AstConstant visitNewExpression(NewExpression node) {
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }

    Send send = node.send;
    FunctionElement constructor = elements[send];
    if (Elements.isUnresolved(constructor)) {
      return signalNotCompileTimeConstant(node);
    }

    // Deferred types can not be used in const instance creation expressions.
    // Check if the constructor comes from a deferred library.
    if (isDeferredUse(node.send.selector.asSend())) {
      return signalNotCompileTimeConstant(node,
          message: MessageKind.DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION);
    }

    // TODO(ahe): This is nasty: we must eagerly analyze the
    // constructor to ensure the redirectionTarget has been computed
    // correctly.  Find a way to avoid this.
    compiler.analyzeElement(constructor.declaration);

    InterfaceType type = elements.getType(node);
    Selector selector = elements.getSelector(send);

    Map<Node, AstConstant> concreteArgumentMap =
        <Node, AstConstant>{};
    for (Link<Node> link = send.arguments; !link.isEmpty; link = link.tail) {
      Node argument = link.head;
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        argument = namedArgument.expression;
      }
      concreteArgumentMap[argument] = evaluateConstant(argument);
    }

    List<AstConstant> normalizedArguments =
        evaluateArgumentsToConstructor(
          node, selector, send.arguments, constructor.implementation,
          compileArgument: (node) => concreteArgumentMap[node]);
    List<AstConstant> concreteArguments =
        concreteArgumentMap.values.toList();

    if (constructor == compiler.intEnvironment ||
        constructor == compiler.boolEnvironment ||
        constructor == compiler.stringEnvironment) {

      AstConstant createEvaluatedConstant(Constant value) {
        return new AstConstant(
            context, node, new ConstructorConstExp(
                value,
                type,
                constructor,
                elements.getSelector(send),
                concreteArguments.map((e) => e.expression).toList()));
      }

      var firstArgument = normalizedArguments[0].value;
      Constant defaultValue = normalizedArguments[1].value;

      if (firstArgument is NullConstant) {
        compiler.reportFatalError(
            send.arguments.head, MessageKind.NULL_NOT_ALLOWED);
        return null;
      }

      if (firstArgument is! StringConstant) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.stringClass.rawType});
        return null;
      }

      if (constructor == compiler.intEnvironment
          && !(defaultValue is NullConstant || defaultValue is IntConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.intClass.rawType});
        return null;
      }

      if (constructor == compiler.boolEnvironment
          && !(defaultValue is NullConstant || defaultValue is BoolConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.boolClass.rawType});
        return null;
      }

      if (constructor == compiler.stringEnvironment
          && !(defaultValue is NullConstant
               || defaultValue is StringConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.stringClass.rawType});
        return null;
      }

      String value =
          compiler.fromEnvironment(firstArgument.value.slowToString());

      if (value == null) {
        return createEvaluatedConstant(defaultValue);
      } else if (constructor == compiler.intEnvironment) {
        int number = int.parse(value, onError: (_) => null);
        return createEvaluatedConstant(
            (number == null)
                ? defaultValue
                : constantSystem.createInt(number));
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
    } else {
      return makeConstructedConstant(
          compiler, handler, context,
          node, type, constructor, selector,
          concreteArguments, normalizedArguments);
    }
  }

  static AstConstant makeConstructedConstant(
      Compiler compiler,
      ConstantCompilerBase handler,
      Element context,
      Node node,
      InterfaceType type,
      ConstructorElement constructor,
      Selector selector,
      List<AstConstant> concreteArguments,
      List<AstConstant> normalizedArguments) {
    assert(invariant(node, selector.applies(constructor, compiler.world),
        message: "Selector $selector does not apply to constructor "
                 "$constructor."));

    // The redirection chain of this element may not have been resolved through
    // a post-process action, so we have to make sure it is done here.
    compiler.resolver.resolveRedirectionChain(constructor, node);
    InterfaceType constructedType =
        constructor.computeEffectiveTargetType(type);
    ConstructorElement target = constructor.effectiveTarget;
    ClassElement classElement = target.enclosingClass;
    // The constructor must be an implementation to ensure that field
    // initializers are handled correctly.
    target = target.implementation;
    assert(invariant(node, target.isImplementation));

    ConstructorEvaluator evaluator = new ConstructorEvaluator(
        constructedType, target, handler, compiler);
    evaluator.evaluateConstructorFieldValues(normalizedArguments);
    List<AstConstant> fieldConstants =
        evaluator.buildFieldConstants(classElement);

    return new AstConstant(
        context, node, new ConstructorConstExp(
            new ConstructedConstant(
                constructedType,
                fieldConstants.map((e) => e.value).toList()),
            type,
            constructor,
            selector,
            concreteArguments.map((e) => e.expression).toList()));
  }

  AstConstant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  error(Node node, MessageKind message) {
    // TODO(floitsch): get the list of constants that are currently compiled
    // and present some kind of stack-trace.
    compiler.reportFatalError(node, message);
  }

  AstConstant signalNotCompileTimeConstant(Node node,
      {MessageKind message: MessageKind.NOT_A_COMPILE_TIME_CONSTANT}) {
    if (isEvaluatingConstant) {
      error(node, message);
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
                       FunctionElement constructor,
                       ConstantCompiler handler,
                       Compiler compiler)
      : this.constructor = constructor,
        this.definitions = new Map<Element, AstConstant>(),
        this.fieldValues = new Map<Element, AstConstant>(),
        super(handler,
              compiler.resolver.resolveMethodElement(constructor.declaration),
              compiler,
              isConst: true) {
    assert(invariant(constructor, constructor.isImplementation));
  }

  AstConstant visitSend(Send send) {
    Element element = elements[send];
    if (Elements.isLocal(element)) {
      AstConstant constant = definitions[element];
      if (constant == null) {
        compiler.internalError(send, "Local variable without value.");
      }
      return constant;
    }
    return super.visitSend(send);
  }

  void potentiallyCheckType(Node node,
                            TypedElement element,
                            AstConstant constant) {
    if (compiler.enableTypeAssertions) {
      DartType elementType = element.type.substByContext(constructedType);
      DartType constantType = constant.value.computeType(compiler);
      if (!constantSystem.isSubtype(compiler, constantType, elementType)) {
        compiler.withCurrentElement(constant.element, () {
          compiler.reportFatalError(
              constant.node, MessageKind.NOT_ASSIGNABLE,
              {'fromType': constantType, 'toType': elementType});
        });
      }
    }
  }

  void updateFieldValue(Node node,
                        TypedElement element,
                        AstConstant constant) {
    potentiallyCheckType(node, element, constant);
    fieldValues[element] = constant;
  }

  /**
   * Given the arguments (a list of constants) assigns them to the parameters,
   * updating the definitions map. If the constructor has field-initializer
   * parameters (like [:this.x:]), also updates the [fieldValues] map.
   */
  void assignArgumentsToParameters(List<AstConstant> arguments) {
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
        potentiallyCheckType(node, parameter, argument);
        definitions[parameter] = argument;
      }
    });
  }

  void evaluateSuperOrRedirectSend(List<AstConstant> compiledArguments,
                                   FunctionElement targetConstructor) {
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
      Selector.addForwardingElementArgumentsToList(constructor,
                                                   compiledArguments,
                                                   target,
                                                   compileArgument,
                                                   compileConstant,
                                                   compiler.world);
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
        if (link.head is !SendSet) {
          // A super initializer or constructor redirection.
          Send call = link.head;
          FunctionElement target = elements[call];
          List<AstConstant> compiledArguments =
              evaluateArgumentsToConstructor(
                  call, elements.getSelector(call), call.arguments, target,
                  compileArgument: evaluateConstant);
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
        assert(superClass.resolutionState == STATE_DONE);

        Selector selector =
            new Selector.callDefaultConstructor(enclosingClass.library);

        FunctionElement targetConstructor =
            superClass.lookupConstructor(selector);
        if (targetConstructor == null) {
          compiler.internalError(functionNode,
              "No default constructor available.");
        }
        List<AstConstant> compiledArguments =
            evaluateArgumentsToConstructor(
                functionNode, selector, const Link<Node>(), targetConstructor);
        evaluateSuperOrRedirectSend(compiledArguments, targetConstructor);
      }
    }
  }

  /**
   * Simulates the execution of the [constructor] with the given
   * [arguments] to obtain the field values that need to be passed to the
   * native JavaScript constructor.
   */
  void evaluateConstructorFieldValues(List<AstConstant> arguments) {
    compiler.withCurrentElement(constructor, () {
      assignArgumentsToParameters(arguments);
      evaluateConstructorInitializers();
    });
  }

  /// Builds a normalized list of the constant values for each field in the
  /// inheritance chain of [classElement].
  List<AstConstant> buildFieldConstants(ClassElement classElement) {
    List<AstConstant> fieldConstants = <AstConstant>[];
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, FieldElement field) {
          AstConstant fieldValue = fieldValues[field];
          if (fieldValue == null) {
            // Use the default value.
            fieldValue = new AstConstant.fromDefaultValue(
                field, handler.compileConstant(field));
          }
          fieldConstants.add(fieldValue);
        },
        includeSuperAndInjectedMembers: true);
    return fieldConstants;
  }
}

/// A constant created from the front-end AST.
///
/// [element] and [node] point to the source location of the constant.
/// [expression] holds the symbolic constant expression and [value] its constant
/// value.
///
/// This class differs from [ConstExp] in that it is coupled to the front-end
/// AST whereas [ConstExp] is only coupled to the element model.
class AstConstant {
  final Element element;
  final Node node;
  final ConstExp expression;

  AstConstant(this.element, this.node, this.expression);

  factory AstConstant.fromDefaultValue(
      VariableElement element,
      ConstExp constant) {
    return new AstConstant(
        element,
        element.initializer != null ? element.initializer : element.node,
        constant);
  }

  Constant get value => expression.value;

  String toString() => expression.toString();
}
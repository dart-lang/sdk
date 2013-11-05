// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

/**
 * The [ConstantHandler] keeps track of compile-time constants,
 * initializations of global and static fields, and default values of
 * optional parameters.
 */
class ConstantHandler extends CompilerTask {
  final ConstantSystem constantSystem;
  final bool isMetadata;

  /**
   * Contains the initial value of fields. Must contain all static and global
   * initializations of const fields. May contain eagerly compiled values for
   * statics and instance fields.
   */
  final Map<VariableElement, Constant> initialVariableValues;

  /** Set of all registered compiled constants. */
  final Set<Constant> compiledConstants;

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables;

  /** Caches the statics where the initial value cannot be eagerly compiled. */
  final Set<VariableElement> lazyStatics;

  ConstantHandler(Compiler compiler, this.constantSystem,
                  { bool this.isMetadata: false })
      : initialVariableValues = new Map<VariableElement, dynamic>(),
        compiledConstants = new Set<Constant>(),
        pendingVariables = new Set<VariableElement>(),
        lazyStatics = new Set<VariableElement>(),
        super(compiler);

  String get name => 'ConstantHandler';

  void addCompileTimeConstantForEmission(Constant constant) {
    compiledConstants.add(constant);
  }

  Constant getConstantForVariable(VariableElement element) {
    return initialVariableValues[element];
  }

  /**
   * Returns a compile-time constant, or reports an error if the element is not
   * a compile-time constant.
   */
  Constant compileConstant(VariableElement element) {
    return compileVariable(element, isConst: true);
  }

  /**
   * Returns the a compile-time constant if the variable could be compiled
   * eagerly. Otherwise returns `null`.
   */
  Constant compileVariable(VariableElement element, {bool isConst: false}) {
    return measure(() {
      if (initialVariableValues.containsKey(element)) {
        Constant result = initialVariableValues[element];
        return result;
      }
      Element currentElement = element;
      if (element.isParameter()
          || element.isFieldParameter()
          || element.isVariable()) {
        currentElement = element.enclosingElement;
      }
      return compiler.withCurrentElement(currentElement, () {
        TreeElements definitions =
            compiler.analyzeElement(currentElement.declaration);
        Constant constant = compileVariableWithDefinitions(
            element, definitions, isConst: isConst);
        return constant;
      });
    });
  }

  /**
   * Returns the a compile-time constant if the variable could be compiled
   * eagerly. If the variable needs to be initialized lazily returns `null`.
   * If the variable is `const` but cannot be compiled eagerly reports an
   * error.
   */
  Constant compileVariableWithDefinitions(VariableElement element,
                                          TreeElements definitions,
                                          {bool isConst: false}) {
    return measure(() {
      if (!isConst && lazyStatics.contains(element)) return null;

      Node node = element.parseNode(compiler);
      if (pendingVariables.contains(element)) {
        if (isConst) {
          compiler.reportFatalError(
              node, MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS);
        } else {
          lazyStatics.add(element);
          return null;
        }
      }
      pendingVariables.add(element);

      SendSet assignment = node.asSendSet();
      Constant value;
      if (assignment == null) {
        // No initial value.
        value = new NullConstant();
      } else {
        Node right = assignment.arguments.head;
        value =
            compileNodeWithDefinitions(right, definitions, isConst: isConst);
        if (compiler.enableTypeAssertions &&
            value != null &&
            element.isField()) {
          DartType elementType = element.computeType(compiler);
          if (elementType.kind == TypeKind.MALFORMED_TYPE && !value.isNull()) {
            if (isConst) {
              ErroneousElement element = elementType.element;
              compiler.reportFatalError(
                  node, element.messageKind, element.messageArguments);
            } else {
              // We need to throw an exception at runtime.
              value = null;
            }
          } else {
            DartType constantType = value.computeType(compiler);
            if (!constantSystem.isSubtype(compiler,
                                          constantType, elementType)) {
              if (isConst) {
                compiler.reportFatalError(
                    node, MessageKind.NOT_ASSIGNABLE.error,
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
        initialVariableValues[element] = value;
      } else {
        assert(!isConst);
        lazyStatics.add(element);
      }
      pendingVariables.remove(element);
      return value;
    });
  }

  Constant compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: false}) {
    return measure(() {
      assert(node != null);
      Constant constant = definitions.getConstant(node);
      if (constant != null) {
        return constant;
      }
      CompileTimeConstantEvaluator evaluator = new CompileTimeConstantEvaluator(
          this, definitions, compiler, isConst: isConst);
      constant = evaluator.evaluate(node);
      if (constant != null) {
        definitions.setConstant(node, constant);
      }
      return constant;
    });
  }

  /**
   * Returns an [Iterable] of static non final fields that need to be
   * initialized. The fields list must be evaluated in order since they might
   * depend on each other.
   */
  Iterable<VariableElement> getStaticNonFinalFieldsForEmission() {
    return initialVariableValues.keys.where((element) {
      return element.kind == ElementKind.FIELD
          && !element.isInstanceMember()
          && !element.modifiers.isFinal()
          // The const fields are all either emitted elsewhere or inlined.
          && !element.modifiers.isConst();
    });
  }

  /**
   * Returns an [Iterable] of static const fields that need to be initialized.
   * The fields must be evaluated in order since they might depend on each
   * other.
   */
  Iterable<VariableElement> getStaticFinalFieldsForEmission() {
    return initialVariableValues.keys.where((element) {
      return element.kind == ElementKind.FIELD
          && !element.isInstanceMember()
          && element.modifiers.isFinal();
    });
  }

  List<VariableElement> getLazilyInitializedFieldsForEmission() {
    return new List<VariableElement>.from(lazyStatics);
  }

  /**
   * Returns a list of constants topologically sorted so that dependencies
   * appear before the dependent constant.  [preSortCompare] is a comparator
   * function that gives the constants a consistent order prior to the
   * topological sort which gives the constants an ordering that is less
   * sensitive to perturbations in the source code.
   */
  List<Constant> getConstantsForEmission([preSortCompare]) {
    // We must emit dependencies before their uses.
    Set<Constant> seenConstants = new Set<Constant>();
    List<Constant> result = new List<Constant>();

    void addConstant(Constant constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    List<Constant> sorted = compiledConstants.toList();
    if (preSortCompare != null) {
      sorted.sort(preSortCompare);
    }
    sorted.forEach(addConstant);
    return result;
  }

  Constant getInitialValueFor(VariableElement element) {
    Constant initialValue = initialVariableValues[element];
    if (initialValue == null) {
      compiler.internalError("No initial value for given element",
                             element: element);
    }
    return initialValue;
  }
}

class CompileTimeConstantEvaluator extends Visitor {
  bool isEvaluatingConstant;
  final ConstantHandler handler;
  final TreeElements elements;
  final Compiler compiler;

  CompileTimeConstantEvaluator(this.handler,
                               this.elements,
                               this.compiler,
                               {bool isConst: false})
      : this.isEvaluatingConstant = isConst;

  ConstantSystem get constantSystem => handler.constantSystem;

  Constant evaluate(Node node) {
    return node.accept(this);
  }

  Constant evaluateConstant(Node node) {
    bool oldIsEvaluatingConstant = isEvaluatingConstant;
    isEvaluatingConstant = true;
    Constant result = node.accept(this);
    isEvaluatingConstant = oldIsEvaluatingConstant;
    assert(result != null);
    return result;
  }

  Constant visitNode(Node node) {
    return signalNotCompileTimeConstant(node);
  }

  Constant visitLiteralBool(LiteralBool node) {
    return constantSystem.createBool(node.value);
  }

  Constant visitLiteralDouble(LiteralDouble node) {
    return constantSystem.createDouble(node.value);
  }

  Constant visitLiteralInt(LiteralInt node) {
    return constantSystem.createInt(node.value);
  }

  Constant visitLiteralList(LiteralList node) {
    if (!node.isConst())  {
      return signalNotCompileTimeConstant(node);
    }
    List<Constant> arguments = <Constant>[];
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty;
         link = link.tail) {
      arguments.add(evaluateConstant(link.head));
    }
    DartType type = elements.getType(node);
    return new ListConstant(type, arguments);
  }

  Constant visitLiteralMap(LiteralMap node) {
    if (!node.isConst()) {
      return signalNotCompileTimeConstant(node);
    }
    List<Constant> keys = <Constant>[];
    Map<Constant, Constant> map = new Map<Constant, Constant>();
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      Constant key = evaluateConstant(entry.key);
      if (!map.containsKey(key)) keys.add(key);
      map[key] = evaluateConstant(entry.value);
    }

    bool onlyStringKeys = true;
    Constant protoValue = null;
    for (var key in keys) {
      if (key.isString()) {
        if (key.value == MapConstant.PROTO_PROPERTY) {
          protoValue = map[key];
        }
      } else {
        onlyStringKeys = false;
        // Don't handle __proto__ values specially in the general map case.
        protoValue = null;
        break;
      }
    }

    bool hasProtoKey = (protoValue != null);
    List<Constant> values = map.values.toList();
    InterfaceType sourceType = elements.getType(node);
    DartType keysType;
    if (sourceType.treatAsRaw) {
      keysType = compiler.listClass.rawType;
    } else {
      Link<DartType> arguments =
          new Link<DartType>.fromList([sourceType.typeArguments.head]);
      keysType = new InterfaceType(compiler.listClass, arguments);
    }
    ListConstant keysList = new ListConstant(keysType, keys);
    String className = onlyStringKeys
        ? (hasProtoKey ? MapConstant.DART_PROTO_CLASS
                       : MapConstant.DART_STRING_CLASS)
        : MapConstant.DART_GENERAL_CLASS;
    ClassElement classElement = compiler.jsHelperLibrary.find(className);
    classElement.ensureResolved(compiler);
    Link<DartType> typeArgument = sourceType.typeArguments;
    InterfaceType type;
    if (sourceType.treatAsRaw) {
      type = classElement.rawType;
    } else {
      type = new InterfaceType(classElement, typeArgument);
    }
    return new MapConstant(type, keysList, values, protoValue, onlyStringKeys);
  }

  Constant visitLiteralNull(LiteralNull node) {
    return constantSystem.createNull();
  }

  Constant visitLiteralString(LiteralString node) {
    return constantSystem.createString(node.dartString, node);
  }

  Constant visitStringJuxtaposition(StringJuxtaposition node) {
    StringConstant left = evaluate(node.first);
    StringConstant right = evaluate(node.second);
    if (left == null || right == null) return null;
    return constantSystem.createString(
        new DartString.concat(left.value, right.value), node);
  }

  Constant visitStringInterpolation(StringInterpolation node) {
    StringConstant initialString = evaluate(node.string);
    if (initialString == null) return null;
    DartString accumulator = initialString.value;
    for (StringInterpolationPart part in node.parts) {
      Constant expression = evaluate(part.expression);
      DartString expressionString;
      if (expression == null) {
        return signalNotCompileTimeConstant(part.expression);
      } else if (expression.isNum() || expression.isBool()) {
        PrimitiveConstant primitive = expression;
        expressionString = new DartString.literal(primitive.value.toString());
      } else if (expression.isString()) {
        PrimitiveConstant primitive = expression;
        expressionString = primitive.value;
      } else {
        return signalNotCompileTimeConstant(part.expression);
      }
      accumulator = new DartString.concat(accumulator, expressionString);
      StringConstant partString = evaluate(part.string);
      if (partString == null) return null;
      accumulator = new DartString.concat(accumulator, partString.value);
    };
    return constantSystem.createString(accumulator, node);
  }

  Constant visitLiteralSymbol(LiteralSymbol node) {
    InterfaceType type = compiler.symbolClass.computeType(compiler);
    List<Constant> createArguments(_) {
      return [constantSystem.createString(
        new DartString.literal(node.slowNameString), node)];
    }
    return makeConstructedConstant(
        node, type, compiler.symbolConstructor, createArguments);
  }

  Constant makeTypeConstant(Element element) {
    DartType elementType = element.computeType(compiler).asRaw();
    DartType constantType =
        compiler.backend.typeImplementation.computeType(compiler);
    return new TypeConstant(elementType, constantType);
  }

  // TODO(floitsch): provide better error-messages.
  Constant visitSend(Send send) {
    Element element = elements[send];
    if (send.isPropertyAccess) {
      if (Elements.isStaticOrTopLevelFunction(element)) {
        return new FunctionConstant(element);
      } else if (Elements.isStaticOrTopLevelField(element)) {
        Constant result;
        if (element.modifiers.isConst()) {
          result = handler.compileConstant(element);
        } else if (element.modifiers.isFinal() && !isEvaluatingConstant) {
          result = handler.compileVariable(element);
        }
        if (result != null) return result;
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        assert(elements.isTypeLiteral(send));
        return makeTypeConstant(element);
      } else if (send.receiver != null) {
        // Fall through to error handling.
      } else if (!Elements.isUnresolved(element)
                 && element.isVariable()
                 && element.modifiers.isConst()) {
        Constant result = handler.compileConstant(element);
        if (result != null) return result;
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isCall) {
      if (identical(element, compiler.identicalFunction)
          && send.argumentCount() == 2) {
        Constant left = evaluate(send.argumentsNode.nodes.head);
        Constant right = evaluate(send.argumentsNode.nodes.tail.head);
        Constant result = constantSystem.identity.fold(left, right);
        if (result != null) return result;
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        // The node itself is not a constant but we register the selector (the
        // identifier that refers to the class/typedef) as a constant.
        Constant typeConstant = makeTypeConstant(element);
        elements.setConstant(send.selector, typeConstant);
      }
      return signalNotCompileTimeConstant(send);
    } else if (send.isPrefix) {
      assert(send.isOperator);
      Constant receiverConstant = evaluate(send.receiver);
      if (receiverConstant == null) return null;
      Operator op = send.selector;
      Constant folded;
      switch (op.source) {
        case "!":
          folded = constantSystem.not.fold(receiverConstant);
          break;
        case "-":
          folded = constantSystem.negate.fold(receiverConstant);
          break;
        case "~":
          folded = constantSystem.bitNot.fold(receiverConstant);
          break;
        default:
          compiler.internalError("Unexpected operator.", node: op);
          break;
      }
      if (folded == null) return signalNotCompileTimeConstant(send);
      return folded;
    } else if (send.isOperator && !send.isPostfix) {
      assert(send.argumentCount() == 1);
      Constant left = evaluate(send.receiver);
      Constant right = evaluate(send.argumentsNode.nodes.head);
      if (left == null || right == null) return null;
      Operator op = send.selector.asOperator();
      Constant folded = null;
      switch (op.source) {
        case "+":
          folded = constantSystem.add.fold(left, right);
          break;
        case "-":
          folded = constantSystem.subtract.fold(left, right);
          break;
        case "*":
          folded = constantSystem.multiply.fold(left, right);
          break;
        case "/":
          folded = constantSystem.divide.fold(left, right);
          break;
        case "%":
          folded = constantSystem.modulo.fold(left, right);
          break;
        case "~/":
          folded = constantSystem.truncatingDivide.fold(left, right);
          break;
        case "|":
          folded = constantSystem.bitOr.fold(left, right);
          break;
        case "&":
          folded = constantSystem.bitAnd.fold(left, right);
          break;
        case "^":
          folded = constantSystem.bitXor.fold(left, right);
          break;
        case "||":
          folded = constantSystem.booleanOr.fold(left, right);
          break;
        case "&&":
          folded = constantSystem.booleanAnd.fold(left, right);
          break;
        case "<<":
          folded = constantSystem.shiftLeft.fold(left, right);
          break;
        case ">>":
          folded = constantSystem.shiftRight.fold(left, right);
          break;
        case "<":
          folded = constantSystem.less.fold(left, right);
          break;
        case "<=":
          folded = constantSystem.lessEqual.fold(left, right);
          break;
        case ">":
          folded = constantSystem.greater.fold(left, right);
          break;
        case ">=":
          folded = constantSystem.greaterEqual.fold(left, right);
          break;
        case "==":
          if (left.isPrimitive() && right.isPrimitive()) {
            folded = constantSystem.equal.fold(left, right);
          }
          break;
        case "===":
          folded = constantSystem.identity.fold(left, right);
          break;
        case "!=":
          if (left.isPrimitive() && right.isPrimitive()) {
            BoolConstant areEquals = constantSystem.equal.fold(left, right);
            if (areEquals == null) {
              folded = null;
            } else {
              folded = areEquals.negate();
            }
          }
          break;
        case "!==":
          BoolConstant areIdentical =
              constantSystem.identity.fold(left, right);
          if (areIdentical == null) {
            folded = null;
          } else {
            folded = areIdentical.negate();
          }
          break;
      }
      if (folded == null) return signalNotCompileTimeConstant(send);
      return folded;
    }
    return signalNotCompileTimeConstant(send);
  }

  Constant visitConditional(Conditional node) {
    Constant condition = evaluate(node.condition);
    if (condition == null) {
      return null;
    } else if (!condition.isBool()) {
      DartType conditionType = condition.computeType(compiler);
      if (isEvaluatingConstant) {
        compiler.reportFatalError(
            node.condition, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': conditionType, 'toType': compiler.boolClass.rawType});
      }
      return null;
    }
    Constant thenExpression = evaluate(node.thenExpression);
    Constant elseExpression = evaluate(node.elseExpression);
    BoolConstant boolCondition = condition;
    return boolCondition.value ? thenExpression : elseExpression;
  }

  Constant visitSendSet(SendSet node) {
    return signalNotCompileTimeConstant(node);
  }

  /**
   * Returns the list of constants that are passed to the static function.
   *
   * Invariant: [target] must be an implementation element.
   */
  List<Constant> evaluateArgumentsToConstructor(Node node,
                                                Selector selector,
                                                Link<Node> arguments,
                                                FunctionElement target) {
    assert(invariant(node, target.isImplementation));
    List<Constant> compiledArguments = <Constant>[];

    Function compileArgument = evaluateConstant;
    Function compileConstant = handler.compileConstant;
    bool succeeded = selector.addArgumentsToList(arguments,
                                                 compiledArguments,
                                                 target,
                                                 compileArgument,
                                                 compileConstant,
                                                 compiler);
    if (!succeeded) {
      compiler.reportFatalError(
          node,
          MessageKind.INVALID_ARGUMENTS.error, {'methodName': target.name});
    }
    return compiledArguments;
  }

  Constant visitNewExpression(NewExpression node) {
    if (!node.isConst()) {
      return signalNotCompileTimeConstant(node);
    }

    Send send = node.send;
    FunctionElement constructor = elements[send];
    if (Elements.isUnresolved(constructor)) {
      return signalNotCompileTimeConstant(node);
    }
    // TODO(ahe): This is nasty: we must eagerly analyze the
    // constructor to ensure the redirectionTarget has been computed
    // correctly.  Find a way to avoid this.
    compiler.analyzeElement(constructor.declaration);

    InterfaceType type = elements.getType(node);
    List<Constant> evaluateArguments(FunctionElement constructor) {
      Selector selector = elements.getSelector(send);
      return evaluateArgumentsToConstructor(
          node, selector, send.arguments, constructor);
    }

    if (constructor == compiler.intEnvironment
        || constructor == compiler.boolEnvironment
        || constructor == compiler.stringEnvironment) {
      List<Constant> arguments = evaluateArguments(constructor.implementation);
      var firstArgument = arguments[0];
      Constant defaultValue = arguments[1];

      if (firstArgument is NullConstant) {
        compiler.reportFatalError(
            send.arguments.head, MessageKind.NULL_NOT_ALLOWED);
      }

      if (firstArgument is! StringConstant) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.head, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': type, 'toType': compiler.stringClass.rawType});
      }

      if (constructor == compiler.intEnvironment
          && !(defaultValue is NullConstant || defaultValue is IntConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': type, 'toType': compiler.intClass.rawType});
      }

      if (constructor == compiler.boolEnvironment
          && !(defaultValue is NullConstant || defaultValue is BoolConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': type, 'toType': compiler.boolClass.rawType});
      }

      if (constructor == compiler.stringEnvironment
          && !(defaultValue is NullConstant
               || defaultValue is StringConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': type, 'toType': compiler.stringClass.rawType});
      }

      String value =
          compiler.fromEnvironment(firstArgument.value.slowToString());

      if (value == null) {
        return defaultValue;
      } else if (constructor == compiler.intEnvironment) {
        int number = int.parse(value, onError: (_) => null);
        return (number == null)
            ? defaultValue
            : constantSystem.createInt(number);
      } else if (constructor == compiler.boolEnvironment) {
        if (value == 'true') {
          return constantSystem.createBool(true);
        } else if (value == 'false') {
          return constantSystem.createBool(false);
        } else {
          return defaultValue;
        }
      } else {
        assert(constructor == compiler.stringEnvironment);
        return constantSystem.createString(new DartString.literal(value), node);
      }
    } else {
      return makeConstructedConstant(
          node, type, constructor, evaluateArguments);
    }
  }

  Constant makeConstructedConstant(
      Spannable node, InterfaceType type, FunctionElement constructor,
      List<Constant> getArguments(FunctionElement constructor)) {
    if (constructor.isRedirectingFactory) {
      type = constructor.computeTargetType(compiler, type);
    }

    // The redirection chain of this element may not have been resolved through
    // a post-process action, so we have to make sure it is done here.
    compiler.resolver.resolveRedirectionChain(constructor, node);
    constructor = constructor.redirectionTarget;
    ClassElement classElement = constructor.getEnclosingClass();
    // The constructor must be an implementation to ensure that field
    // initializers are handled correctly.
    constructor = constructor.implementation;
    assert(invariant(node, constructor.isImplementation));

    List<Constant> arguments = getArguments(constructor);
    ConstructorEvaluator evaluator =
        new ConstructorEvaluator(constructor, handler, compiler);
    evaluator.evaluateConstructorFieldValues(arguments);
    List<Constant> jsNewArguments = evaluator.buildJsNewArguments(classElement);

    return new ConstructedConstant(type, jsNewArguments);
  }

  Constant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  error(Node node) {
    // TODO(floitsch): get the list of constants that are currently compiled
    // and present some kind of stack-trace.
    compiler.reportFatalError(
        node, MessageKind.NOT_A_COMPILE_TIME_CONSTANT);
  }

  Constant signalNotCompileTimeConstant(Node node) {
    if (isEvaluatingConstant) {
      error(node);
    }
    // Else we don't need to do anything. The final handler is only
    // optimistically trying to compile constants. So it is normal that we
    // sometimes see non-compile time constants.
    // Simply return [:null:] which is used to propagate a failing
    // compile-time compilation.
    return null;
  }
}

class TryCompileTimeConstantEvaluator extends CompileTimeConstantEvaluator {
  TryCompileTimeConstantEvaluator(ConstantHandler handler,
                                  TreeElements elements,
                                  Compiler compiler)
      : super(handler, elements, compiler, isConst: true);

  error(Node node) {
    // Just fail without reporting it anywhere.
    throw new CompileTimeConstantError(
        MessageKind.NOT_A_COMPILE_TIME_CONSTANT, const {},
        compiler.terseDiagnostics);
  }
}

class ConstructorEvaluator extends CompileTimeConstantEvaluator {
  final FunctionElement constructor;
  final Map<Element, Constant> definitions;
  final Map<Element, Constant> fieldValues;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructor] must be an implementation element.
   */
  ConstructorEvaluator(FunctionElement constructor,
                       ConstantHandler handler,
                       Compiler compiler)
      : this.constructor = constructor,
        this.definitions = new Map<Element, Constant>(),
        this.fieldValues = new Map<Element, Constant>(),
        super(handler,
              compiler.resolver.resolveMethodElement(constructor.declaration),
              compiler,
              isConst: true) {
    assert(invariant(constructor, constructor.isImplementation));
  }

  Constant visitSend(Send send) {
    Element element = elements[send];
    if (Elements.isLocal(element)) {
      Constant constant = definitions[element];
      if (constant == null) {
        compiler.internalError("Local variable without value", node: send);
      }
      return constant;
    }
    return super.visitSend(send);
  }

  void potentiallyCheckType(Node node, Element element, Constant constant) {
    if (compiler.enableTypeAssertions) {
      DartType elementType = element.computeType(compiler);
      DartType constantType = constant.computeType(compiler);
      // TODO(ngeoffray): Handle type parameters.
      if (elementType.element.isTypeVariable()) return;
      if (!constantSystem.isSubtype(compiler, constantType, elementType)) {
        compiler.reportFatalError(
            node, MessageKind.NOT_ASSIGNABLE.error,
            {'fromType': elementType, 'toType': constantType});
      }
    }
  }

  void updateFieldValue(Node node, Element element, Constant constant) {
    potentiallyCheckType(node, element, constant);
    fieldValues[element] = constant;
  }

  /**
   * Given the arguments (a list of constants) assigns them to the parameters,
   * updating the definitions map. If the constructor has field-initializer
   * parameters (like [:this.x:]), also updates the [fieldValues] map.
   */
  void assignArgumentsToParameters(List<Constant> arguments) {
    // Assign arguments to parameters.
    FunctionSignature parameters = constructor.computeSignature(compiler);
    int index = 0;
    parameters.orderedForEachParameter((Element parameter) {
      Constant argument = arguments[index++];
      Node node = parameter.parseNode(compiler);
      potentiallyCheckType(node, parameter, argument);
      definitions[parameter] = argument;
      if (parameter.kind == ElementKind.FIELD_PARAMETER) {
        FieldParameterElement fieldParameterElement = parameter;
        updateFieldValue(node, fieldParameterElement.fieldElement, argument);
      }
    });
  }

  void evaluateSuperOrRedirectSend(List<Constant> compiledArguments,
                                   FunctionElement targetConstructor) {
    ConstructorEvaluator evaluator = new ConstructorEvaluator(
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
      List<Constant> compiledArguments = <Constant>[];

      Function compileArgument = (element) => definitions[element];
      Function compileConstant = handler.compileConstant;
      FunctionElement target = constructor.targetConstructor.implementation;
      Selector.addForwardingElementArgumentsToList(constructor,
                                                   compiledArguments,
                                                   target,
                                                   compileArgument,
                                                   compileConstant,
                                                   compiler);
      evaluateSuperOrRedirectSend(compiledArguments, target);
      return;
    }
    FunctionExpression functionNode = constructor.parseNode(compiler);
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
          List<Constant> compiledArguments = evaluateArgumentsToConstructor(
              call, elements.getSelector(call), call.arguments, target);
          evaluateSuperOrRedirectSend(compiledArguments, target);
          foundSuperOrRedirect = true;
        } else {
          // A field initializer.
          SendSet init = link.head;
          Link<Node> initArguments = init.arguments;
          assert(!initArguments.isEmpty && initArguments.tail.isEmpty);
          Constant fieldValue = evaluate(initArguments.head);
          updateFieldValue(init, elements[init], fieldValue);
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.getEnclosingClass();
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        assert(superClass != null);
        assert(superClass.resolutionState == STATE_DONE);

        Selector selector =
            new Selector.callDefaultConstructor(enclosingClass.getLibrary());

        FunctionElement targetConstructor =
            superClass.lookupConstructor(selector);
        if (targetConstructor == null) {
          compiler.internalError("no default constructor available",
                                 node: functionNode);
        }
        List<Constant> compiledArguments = evaluateArgumentsToConstructor(
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
  void evaluateConstructorFieldValues(List<Constant> arguments) {
    compiler.withCurrentElement(constructor, () {
      assignArgumentsToParameters(arguments);
      evaluateConstructorInitializers();
    });
  }

  List<Constant> buildJsNewArguments(ClassElement classElement) {
    List<Constant> jsNewArguments = <Constant>[];
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, Element field) {
          Constant fieldValue = fieldValues[field];
          if (fieldValue == null) {
            // Use the default value.
            fieldValue = handler.compileConstant(field);
          }
          jsNewArguments.add(fieldValue);
        },
        includeSuperAndInjectedMembers: true);
    return jsNewArguments;
  }
}

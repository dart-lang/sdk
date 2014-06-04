// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {
  /// Returns the constant for the initializer of [element].
  Constant getConstantForVariable(VariableElement element);
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
  Constant compileConstant(VariableElement element);

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
  Constant compileNode(Node node, TreeElements elements);

  /// Compiles the compile-time constant for the value [metadata], or reports an
  /// error if the value is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  Constant compileMetadata(MetadataAnnotation metadata,
                           Node node, TreeElements elements);
}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Returns the compile-time constant associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  Constant getConstantForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant value of [metadata].
  Constant getConstantForMetadata(MetadataAnnotation metadata);
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
  final Map<VariableElement, Constant> initialVariableValues =
      new Map<VariableElement, Constant>();

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables = new Set<VariableElement>();

  ConstantCompilerBase(this.compiler, this.constantSystem);

  Constant getConstantForVariable(VariableElement element) {
    return initialVariableValues[element.declaration];
  }

  Constant compileConstant(VariableElement element) {
    return compileVariable(element, isConst: true);
  }

  Constant compileVariable(VariableElement element, {bool isConst: false}) {

    if (initialVariableValues.containsKey(element.declaration)) {
      Constant result = initialVariableValues[element.declaration];
      return result;
    }
    Element currentElement = element;
    if (element.isParameter ||
        element.isFieldParameter ||
        element.isVariable) {
      currentElement = element.enclosingElement;
    }
    return compiler.withCurrentElement(currentElement, () {
      TreeElements definitions =
          compiler.analyzeElement(currentElement.declaration);
      Constant constant = compileVariableWithDefinitions(
          element, definitions, isConst: isConst);
      return constant;
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
    Constant value;
    if (initializer == null) {
      // No initial value.
      value = new NullConstant();
    } else {
      value = compileNodeWithDefinitions(
          initializer, definitions, isConst: isConst);
      if (compiler.enableTypeAssertions &&
          value != null &&
          element.isField) {
        DartType elementType = element.type;
        if (elementType.isMalformed && !value.isNull) {
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
      assert(!isConst);
    }
    pendingVariables.remove(element);
    return value;
  }

  Constant compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    assert(node != null);
    CompileTimeConstantEvaluator evaluator = new CompileTimeConstantEvaluator(
        this, definitions, compiler, isConst: isConst);
    return evaluator.evaluate(node);
  }

  Constant compileNode(Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }

  Constant compileMetadata(MetadataAnnotation metadata,
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

  Constant getConstantForNode(Node node, TreeElements definitions) {
    return definitions.getConstant(node);
  }

  Constant getConstantForMetadata(MetadataAnnotation metadata) {
    return metadata.value;
  }

  Constant compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    Constant constant = definitions.getConstant(node);
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

class CompileTimeConstantEvaluator extends Visitor {
  bool isEvaluatingConstant;
  final ConstantCompilerBase handler;
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
    if (!node.isConst)  {
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
    if (!node.isConst) {
      return signalNotCompileTimeConstant(node);
    }
    List<Constant> keys = <Constant>[];
    Map<Constant, Constant> map = new Map<Constant, Constant>();
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      Constant key = evaluateConstant(entry.key);
      if (!map.containsKey(key)) {
        keys.add(key);
      } else {
        compiler.reportWarning(entry.key, MessageKind.EQUAL_MAP_ENTRY_KEY);
      }
      map[key] = evaluateConstant(entry.value);
    }

    bool onlyStringKeys = true;
    Constant protoValue = null;
    for (var key in keys) {
      if (key.isString) {
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
    return constantSystem.createString(node.dartString);
  }

  Constant visitStringJuxtaposition(StringJuxtaposition node) {
    StringConstant left = evaluate(node.first);
    StringConstant right = evaluate(node.second);
    if (left == null || right == null) return null;
    return constantSystem.createString(
        new DartString.concat(left.value, right.value));
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
      } else if (expression.isNum || expression.isBool) {
        PrimitiveConstant primitive = expression;
        expressionString = new DartString.literal(primitive.value.toString());
      } else if (expression.isString) {
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
    return constantSystem.createString(accumulator);
  }

  Constant visitLiteralSymbol(LiteralSymbol node) {
    InterfaceType type = compiler.symbolClass.rawType;
    List<Constant> createArguments(_) {
      return [constantSystem.createString(
        new DartString.literal(node.slowNameString))];
    }
    return makeConstructedConstant(
        node, type, compiler.symbolConstructor, createArguments,
        isLiteralSymbol: true);
  }

  Constant makeTypeConstant(DartType elementType) {
    DartType constantType =
        compiler.backend.typeImplementation.computeType(compiler);
    return new TypeConstant(elementType, constantType);
  }

  /// Returns true if the prefix of the send resolves to a deferred import
  /// prefix.
  bool isDeferredUse(Send send) {
    if (send == null) return false;
    return compiler.deferredLoadTask
        .deferredPrefixElement(send, elements) != null;
  }

  Constant visitIdentifier(Identifier node) {
    Element element = elements[node];
    if (Elements.isClass(element) || Elements.isTypedef(element)) {
      TypeDeclarationElement typeDeclarationElement = element;
      return makeTypeConstant(typeDeclarationElement.rawType);
    }
    return signalNotCompileTimeConstant(node);
  }

  // TODO(floitsch): provide better error-messages.
  Constant visitSend(Send send) {
    Element element = elements[send];
    if (send.isPropertyAccess) {
      if (isDeferredUse(send)) {
        return signalNotCompileTimeConstant(send,
            message: MessageKind.DEFERRED_COMPILE_TIME_CONSTANT);
      }
      if (Elements.isStaticOrTopLevelFunction(element)) {
        return new FunctionConstant(element);
      } else if (Elements.isStaticOrTopLevelField(element)) {
        Constant result;
        if (element.isConst) {
          result = handler.compileConstant(element);
        } else if (element.isFinal && !isEvaluatingConstant) {
          result = handler.compileVariable(element);
        }
        if (result != null) return result;
      } else if (Elements.isClass(element) || Elements.isTypedef(element)) {
        assert(elements.isTypeLiteral(send));
        return makeTypeConstant(elements.getTypeLiteralType(send));
      } else if (send.receiver != null) {
        // Fall through to error handling.
      } else if (!Elements.isUnresolved(element)
                 && element.isVariable
                 && element.isConst) {
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
          compiler.internalError(op, "Unexpected operator.");
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
          if (left.isPrimitive && right.isPrimitive) {
            folded = constantSystem.equal.fold(left, right);
          }
          break;
        case "===":
          folded = constantSystem.identity.fold(left, right);
          break;
        case "!=":
          if (left.isPrimitive && right.isPrimitive) {
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
    } else if (!condition.isBool) {
      DartType conditionType = condition.computeType(compiler);
      if (isEvaluatingConstant) {
        compiler.reportFatalError(
            node.condition, MessageKind.NOT_ASSIGNABLE,
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
          MessageKind.INVALID_ARGUMENTS, {'methodName': target.name});
    }
    return compiledArguments;
  }

  Constant visitNewExpression(NewExpression node) {
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
            send.arguments.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.stringClass.rawType});
      }

      if (constructor == compiler.intEnvironment
          && !(defaultValue is NullConstant || defaultValue is IntConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.intClass.rawType});
      }

      if (constructor == compiler.boolEnvironment
          && !(defaultValue is NullConstant || defaultValue is BoolConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
            {'fromType': type, 'toType': compiler.boolClass.rawType});
      }

      if (constructor == compiler.stringEnvironment
          && !(defaultValue is NullConstant
               || defaultValue is StringConstant)) {
        DartType type = defaultValue.computeType(compiler);
        compiler.reportFatalError(
            send.arguments.tail.head, MessageKind.NOT_ASSIGNABLE,
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
        return constantSystem.createString(new DartString.literal(value));
      }
    } else {
      return makeConstructedConstant(
          node, type, constructor, evaluateArguments);
    }
  }

  Constant makeConstructedConstant(
      Spannable node, InterfaceType type, ConstructorElement constructor,
      List<Constant> getArguments(ConstructorElement constructor),
      {bool isLiteralSymbol: false}) {
    // The redirection chain of this element may not have been resolved through
    // a post-process action, so we have to make sure it is done here.
    compiler.resolver.resolveRedirectionChain(constructor, node);
    InterfaceType constructedType =
        constructor.computeEffectiveTargetType(type);
    constructor = constructor.effectiveTarget;
    ClassElement classElement = constructor.enclosingClass;
    // The constructor must be an implementation to ensure that field
    // initializers are handled correctly.
    constructor = constructor.implementation;
    assert(invariant(node, constructor.isImplementation));

    List<Constant> arguments = getArguments(constructor);
    ConstructorEvaluator evaluator = new ConstructorEvaluator(
        constructedType, constructor, handler, compiler);
    evaluator.evaluateConstructorFieldValues(arguments);
    List<Constant> jsNewArguments = evaluator.buildJsNewArguments(classElement);

    return new ConstructedConstant(constructedType, jsNewArguments,
        isLiteralSymbol: isLiteralSymbol);
  }

  Constant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  error(Node node, MessageKind message) {
    // TODO(floitsch): get the list of constants that are currently compiled
    // and present some kind of stack-trace.
    compiler.reportFatalError(node, message);
  }

  Constant signalNotCompileTimeConstant(Node node,
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
  final Map<Element, Constant> definitions;
  final Map<Element, Constant> fieldValues;

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
        compiler.internalError(send, "Local variable without value.");
      }
      return constant;
    }
    return super.visitSend(send);
  }

  void potentiallyCheckType(Node node,
                            TypedElement element,
                            Constant constant) {
    if (compiler.enableTypeAssertions) {
      DartType elementType = element.type.substByContext(constructedType);
      DartType constantType = constant.computeType(compiler);
      if (!constantSystem.isSubtype(compiler, constantType, elementType)) {
        compiler.reportFatalError(
            node, MessageKind.NOT_ASSIGNABLE,
            {'fromType': constantType, 'toType': elementType});
      }
    }
  }

  void updateFieldValue(Node node, TypedElement element, Constant constant) {
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
    FunctionSignature signature = constructor.functionSignature;
    int index = 0;
    signature.orderedForEachParameter((ParameterElement parameter) {
      Constant argument = arguments[index++];
      Node node = parameter.node;
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
      List<Constant> compiledArguments = <Constant>[];

      Function compileArgument = (element) => definitions[element];
      Function compileConstant = handler.compileConstant;
      FunctionElement target = constructor.definingConstructor.implementation;
      Selector.addForwardingElementArgumentsToList(constructor,
                                                   compiledArguments,
                                                   target,
                                                   compileArgument,
                                                   compileConstant,
                                                   compiler);
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

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class OptimizationPhase {
  String get name;
  void visitGraph(HGraph graph);
}

class SsaOptimizerTask extends CompilerTask {
  final JavaScriptBackend backend;
  SsaOptimizerTask(JavaScriptBackend backend)
    : this.backend = backend,
      super(backend.compiler);
  String get name => 'SSA optimizer';
  Compiler get compiler => backend.compiler;
  Map<HInstruction, Range> ranges = <HInstruction, Range>{};

  void runPhases(HGraph graph, List<OptimizationPhase> phases) {
    for (OptimizationPhase phase in phases) {
      runPhase(graph, phase);
    }
  }

  void runPhase(HGraph graph, OptimizationPhase phase) {
    phase.visitGraph(graph);
    compiler.tracer.traceGraph(phase.name, graph);
    assert(graph.isValid());
  }

  void optimize(CodegenWorkItem work, HGraph graph) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    JavaScriptItemCompilationContext context = work.compilationContext;
    bool trustPrimitives = compiler.trustPrimitives;
    measure(() {
      SsaDeadCodeEliminator dce;
      List<OptimizationPhase> phases = <OptimizationPhase>[
          // Run trivial instruction simplification first to optimize
          // some patterns useful for type conversion.
          new SsaInstructionSimplifier(constantSystem, backend, this, work),
          new SsaTypeConversionInserter(compiler),
          new SsaRedundantPhiEliminator(),
          new SsaDeadPhiEliminator(),
          new SsaTypePropagator(compiler),
          // After type propagation, more instructions can be
          // simplified.
          new SsaInstructionSimplifier(constantSystem, backend, this, work),
          new SsaCheckInserter(
              trustPrimitives, backend, work, context.boundsChecked),
          new SsaInstructionSimplifier(constantSystem, backend, this, work),
          new SsaCheckInserter(
              trustPrimitives, backend, work, context.boundsChecked),
          new SsaTypePropagator(compiler),
          // Run a dead code eliminator before LICM because dead
          // interceptors are often in the way of LICM'able instructions.
          new SsaDeadCodeEliminator(compiler, this),
          new SsaGlobalValueNumberer(compiler),
          // After GVN, some instructions might need their type to be
          // updated because they now have different inputs.
          new SsaTypePropagator(compiler),
          new SsaCodeMotion(),
          new SsaLoadElimination(compiler),
          new SsaDeadPhiEliminator(),
          new SsaTypePropagator(compiler),
          new SsaValueRangeAnalyzer(compiler, constantSystem, this, work),
          // Previous optimizations may have generated new
          // opportunities for instruction simplification.
          new SsaInstructionSimplifier(constantSystem, backend, this, work),
          new SsaCheckInserter(
              trustPrimitives, backend, work, context.boundsChecked),
          new SsaSimplifyInterceptors(compiler, constantSystem, work),
          dce = new SsaDeadCodeEliminator(compiler, this),
          new SsaTypePropagator(compiler)];
      runPhases(graph, phases);
      if (dce.eliminatedSideEffects) {
        phases = <OptimizationPhase>[
            new SsaGlobalValueNumberer(compiler),
            new SsaCodeMotion(),
            new SsaValueRangeAnalyzer(compiler, constantSystem, this, work),
            new SsaInstructionSimplifier(constantSystem, backend, this, work),
            new SsaCheckInserter(
                trustPrimitives, backend, work, context.boundsChecked),
            new SsaSimplifyInterceptors(compiler, constantSystem, work),
            new SsaDeadCodeEliminator(compiler, this)];
      } else {
        phases = <OptimizationPhase>[
            // Run the simplifier to remove unneeded type checks inserted
            // by type propagation.
            new SsaInstructionSimplifier(constantSystem, backend, this, work)];
      }
      runPhases(graph, phases);
    });
  }
}

bool isFixedLength(mask, Compiler compiler) {
  ClassWorld classWorld = compiler.world;
  JavaScriptBackend backend = compiler.backend;
  if (mask.isContainer && mask.length != null) {
    // A container on which we have inferred the length.
    return true;
  } else if (mask.containsOnly(backend.jsFixedArrayClass)
             || mask.containsOnlyString(classWorld)
             || backend.isTypedArray(mask)) {
    return true;
  }
  return false;
}

/**
 * If both inputs to known operations are available execute the operation at
 * compile-time.
 */
class SsaInstructionSimplifier extends HBaseVisitor
    implements OptimizationPhase {

  // We don't produce constant-folded strings longer than this unless they have
  // a single use.  This protects against exponentially large constant folded
  // strings.
  static const MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH = 512;

  final String name = "SsaInstructionSimplifier";
  final JavaScriptBackend backend;
  final CodegenWorkItem work;
  final ConstantSystem constantSystem;
  HGraph graph;
  Compiler get compiler => backend.compiler;
  final SsaOptimizerTask optimizer;

  SsaInstructionSimplifier(this.constantSystem,
                           this.backend,
                           this.optimizer,
                           this.work);

  void visitGraph(HGraph visitee) {
    graph = visitee;
    visitDominatorTree(visitee);
  }

  visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      HInstruction replacement = instruction.accept(this);
      if (replacement != instruction) {
        block.rewrite(instruction, replacement);

        // The intersection of double and int return conflicting, and
        // because of our number implementation for JavaScript, it
        // might be that an operation thought to return double, can be
        // simplified to an int. For example:
        // `2.5 * 10`.
        if (!(replacement.isNumberOrNull(compiler)
              && instruction.isNumberOrNull(compiler))) {
          // If we can replace [instruction] with [replacement], then
          // [replacement]'s type can be narrowed.
          TypeMask newType = replacement.instructionType.intersection(
              instruction.instructionType, compiler.world);
          replacement.instructionType = newType;
        }

        // If the replacement instruction does not know its
        // source element, use the source element of the
        // instruction.
        if (replacement.sourceElement == null) {
          replacement.sourceElement = instruction.sourceElement;
        }
        if (replacement.sourcePosition == null) {
          replacement.sourcePosition = instruction.sourcePosition;
        }
        if (!replacement.isInBasicBlock()) {
          // The constant folding can return an instruction that is already
          // part of the graph (like an input), so we only add the replacement
          // if necessary.
          block.addAfter(instruction, replacement);
          // Visit the replacement as the next instruction in case it
          // can also be constant folded away.
          next = replacement;
        }
        block.remove(instruction);
      }
      instruction = next;
    }
  }

  HInstruction visitInstruction(HInstruction node) {
    return node;
  }

  HInstruction visitBoolify(HBoolify node) {
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length == 1);
    HInstruction input = inputs[0];
    if (input.isBoolean(compiler)) return input;
    // All values that cannot be 'true' are boolified to false.
    TypeMask mask = input.instructionType;
    if (!mask.contains(backend.jsBoolClass, compiler.world)) {
      return graph.addConstantBool(false, compiler);
    }
    return node;
  }

  HInstruction visitNot(HNot node) {
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length == 1);
    HInstruction input = inputs[0];
    if (input is HConstant) {
      HConstant constant = input;
      bool isTrue = constant.constant.isTrue;
      return graph.addConstantBool(!isTrue, compiler);
    } else if (input is HNot) {
      return input.inputs[0];
    }
    return node;
  }

  HInstruction visitInvokeUnary(HInvokeUnary node) {
    HInstruction folded =
        foldUnary(node.operation(constantSystem), node.operand);
    return folded != null ? folded : node;
  }

  HInstruction foldUnary(UnaryOperation operation, HInstruction operand) {
    if (operand is HConstant) {
      HConstant receiver = operand;
      ConstantValue folded = operation.fold(receiver.constant);
      if (folded != null) return graph.addConstant(folded, compiler);
    }
    return null;
  }

  HInstruction tryOptimizeLengthInterceptedGetter(HInvokeDynamic node) {
    HInstruction actualReceiver = node.inputs[1];
    if (actualReceiver.isIndexablePrimitive(compiler)) {
      if (actualReceiver.isConstantString()) {
        HConstant constantInput = actualReceiver;
        StringConstantValue constant = constantInput.constant;
        return graph.addConstantInt(constant.length, compiler);
      } else if (actualReceiver.isConstantList()) {
        HConstant constantInput = actualReceiver;
        ListConstantValue constant = constantInput.constant;
        return graph.addConstantInt(constant.length, compiler);
      }
      Element element = backend.jsIndexableLength;
      bool isFixed = isFixedLength(actualReceiver.instructionType, compiler);
      HFieldGet result = new HFieldGet(
          element, actualReceiver, backend.positiveIntType,
          isAssignable: !isFixed);
      return result;
    } else if (actualReceiver.isConstantMap()) {
      HConstant constantInput = actualReceiver;
      MapConstantValue constant = constantInput.constant;
      return graph.addConstantInt(constant.length, compiler);
    }
    return null;
  }

  HInstruction handleInterceptedCall(HInvokeDynamic node) {
    // Try constant folding the instruction.
    Operation operation = node.specializer.operation(constantSystem);
    if (operation != null) {
      HInstruction instruction = node.inputs.length == 2
          ? foldUnary(operation, node.inputs[1])
          : foldBinary(operation, node.inputs[1], node.inputs[2]);
      if (instruction != null) return instruction;
    }

    // Try converting the instruction to a builtin instruction.
    HInstruction instruction =
        node.specializer.tryConvertToBuiltin(node, compiler);
    if (instruction != null) return instruction;

    Selector selector = node.selector;
    HInstruction input = node.inputs[1];

    World world = compiler.world;
    if (selector.isCall || selector.isOperator) {
      Element target;
      if (input.isExtendableArray(compiler)) {
        if (selector.applies(backend.jsArrayRemoveLast, world)) {
          target = backend.jsArrayRemoveLast;
        } else if (selector.applies(backend.jsArrayAdd, world)) {
          // The codegen special cases array calls, but does not
          // inline argument type checks.
          if (!compiler.enableTypeAssertions) {
            target = backend.jsArrayAdd;
          }
        }
      } else if (input.isStringOrNull(compiler)) {
        if (selector.applies(backend.jsStringSplit, world)) {
          HInstruction argument = node.inputs[2];
          if (argument.isString(compiler)) {
            target = backend.jsStringSplit;
          }
        } else if (selector.applies(backend.jsStringOperatorAdd, world)) {
          // `operator+` is turned into a JavaScript '+' so we need to
          // make sure the receiver and the argument are not null.
          // TODO(sra): Do this via [node.specializer].
          HInstruction argument = node.inputs[2];
          if (argument.isString(compiler)
              && !input.canBeNull()) {
            return new HStringConcat(input, argument, null,
                                     node.instructionType);
          }
        } else if (selector.applies(backend.jsStringToString, world)
                   && !input.canBeNull()) {
          return input;
        }
      }
      if (target != null) {
        // TODO(ngeoffray): There is a strong dependency between codegen
        // and this optimization that the dynamic invoke does not need an
        // interceptor. We currently need to keep a
        // HInvokeDynamicMethod and not create a HForeign because
        // HForeign is too opaque for the SsaCheckInserter (that adds a
        // bounds check on removeLast). Once we start inlining, the
        // bounds check will become explicit, so we won't need this
        // optimization.
        HInvokeDynamicMethod result = new HInvokeDynamicMethod(
            node.selector, node.inputs.sublist(1), node.instructionType);
        result.element = target;
        return result;
      }
    } else if (selector.isGetter) {
      if (selector.asUntyped.applies(backend.jsIndexableLength, world)) {
        HInstruction optimized = tryOptimizeLengthInterceptedGetter(node);
        if (optimized != null) return optimized;
      }
    }

    return node;
  }

  HInstruction visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    TypeMask receiverType = node.getDartReceiver(compiler).instructionType;
    Selector selector =
        new TypedSelector(receiverType, node.selector, compiler.world);
    Element element = compiler.world.locateSingleElement(selector);
    // TODO(ngeoffray): Also fold if it's a getter or variable.
    if (element != null
        && element.isFunction
        // If we found out that the only target is a [:noSuchMethod:],
        // we just ignore it.
        && element.name == selector.name) {
      FunctionElement method = element;

      if (method.isNative) {
        HInstruction folded = tryInlineNativeMethod(node, method);
        if (folded != null) return folded;
      } else {
        // TODO(ngeoffray): If the method has optional parameters,
        // we should pass the default values.
        FunctionSignature parameters = method.functionSignature;
        if (parameters.optionalParameterCount == 0
            || parameters.parameterCount == node.selector.argumentCount) {
          node.element = element;
        }
      }
    }
    return node;
  }

  HInstruction tryInlineNativeMethod(HInvokeDynamicMethod node,
                                     FunctionElement method) {
    // Enable direct calls to a native method only if we don't run in checked
    // mode, where the Dart version may have type annotations on parameters and
    // return type that it should check.
    // Also check that the parameters are not functions: it's the callee that
    // will translate them to JS functions.
    //
    // TODO(ngeoffray): There are some cases where we could still inline in
    // checked mode if we know the arguments have the right type. And we could
    // do the closure conversion as well as the return type annotation check.

    if (!node.isInterceptedCall) return null;

    // TODO(sra): Check for legacy methods with bodies in the native strings.
    //   foo() native 'return something';
    // They should not be used.

    FunctionSignature signature = method.functionSignature;
    if (signature.optionalParametersAreNamed) return null;

    // Return types on native methods don't need to be checked, since the
    // declaration has to be truthful.

    // The call site might omit optional arguments. The inlined code must
    // preserve the number of arguments, so check only the actual arguments.

    List<HInstruction> inputs = node.inputs.sublist(1);
    int inputPosition = 1;  // Skip receiver.
    bool canInline = true;
    signature.forEachParameter((ParameterElement element) {
      if (inputPosition < inputs.length && canInline) {
        HInstruction input = inputs[inputPosition++];
        DartType type = element.type.unalias(compiler);
        if (type is FunctionType) {
          canInline = false;
        }
        if (compiler.enableTypeAssertions) {
          // TODO(sra): Check if [input] is guaranteed to pass the parameter
          // type check.  Consider using a strengthened type check to avoid
          // passing `null` to primitive types since the native methods usually
          // have non-nullable primitive parameter types.
          canInline = false;
        }
      }
    });

    if (!canInline) return null;

    // Strengthen instruction type from annotations to help optimize
    // dependent instructions.
    native.NativeBehavior nativeBehavior =
        native.NativeBehavior.ofMethod(method, compiler);
    TypeMask returnType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);
    HInvokeDynamicMethod result =
        new HInvokeDynamicMethod(node.selector, inputs, returnType);
    result.element = method;
    return result;
  }

  HInstruction visitBoundsCheck(HBoundsCheck node) {
    HInstruction index = node.index;
    if (index.isInteger(compiler)) return node;
    if (index.isConstant()) {
      HConstant constantInstruction = index;
      assert(!constantInstruction.constant.isInt);
      if (!constantSystem.isInt(constantInstruction.constant)) {
        // -0.0 is a double but will pass the runtime integer check.
        node.staticChecks = HBoundsCheck.ALWAYS_FALSE;
      }
    }
    return node;
  }

  HInstruction foldBinary(BinaryOperation operation,
                          HInstruction left,
                          HInstruction right) {
    if (left is HConstant && right is HConstant) {
      HConstant op1 = left;
      HConstant op2 = right;
      ConstantValue folded = operation.fold(op1.constant, op2.constant);
      if (folded != null) return graph.addConstant(folded, compiler);
    }
    return null;
  }

  HInstruction visitAdd(HAdd node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    // We can only perform this rewriting on Integer, as it is not
    // valid for -0.0.
    if (left.isInteger(compiler) && right.isInteger(compiler)) {
      if (left is HConstant && left.constant.isZero) return right;
      if (right is HConstant && right.constant.isZero) return left;
    }
    return super.visitAdd(node);
  }

  HInstruction visitMultiply(HMultiply node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    if (left.isNumber(compiler) && right.isNumber(compiler)) {
      if (left is HConstant && left.constant.isOne) return right;
      if (right is HConstant && right.constant.isOne) return left;
    }
    return super.visitMultiply(node);
  }

  HInstruction visitInvokeBinary(HInvokeBinary node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    BinaryOperation operation = node.operation(constantSystem);
    HConstant folded = foldBinary(operation, left, right);
    if (folded != null) return folded;
    return node;
  }

  bool allUsersAreBoolifies(HInstruction instruction) {
    List<HInstruction> users = instruction.usedBy;
    int length = users.length;
    for (int i = 0; i < length; i++) {
      if (users[i] is! HBoolify) return false;
    }
    return true;
  }

  HInstruction visitRelational(HRelational node) {
    if (allUsersAreBoolifies(node)) {
      // TODO(ngeoffray): Call a boolified selector.
      // This node stays the same, but the Boolify node will go away.
    }
    // Note that we still have to call [super] to make sure that we end up
    // in the remaining optimizations.
    return super.visitRelational(node);
  }

  HInstruction handleIdentityCheck(HRelational node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    TypeMask leftType = left.instructionType;
    TypeMask rightType = right.instructionType;

    // Intersection of int and double return conflicting, so
    // we don't optimize on numbers to preserve the runtime semantics.
    if (!(left.isNumberOrNull(compiler) && right.isNumberOrNull(compiler))) {
      TypeMask intersection = leftType.intersection(rightType, compiler.world);
      if (intersection.isEmpty && !intersection.isNullable) {
        return graph.addConstantBool(false, compiler);
      }
    }

    if (left.isNull() && right.isNull()) {
      return graph.addConstantBool(true, compiler);
    }

    if (left.isConstantBoolean() && right.isBoolean(compiler)) {
      HConstant constant = left;
      if (constant.constant.isTrue) {
        return right;
      } else {
        return new HNot(right, backend.boolType);
      }
    }

    if (right.isConstantBoolean() && left.isBoolean(compiler)) {
      HConstant constant = right;
      if (constant.constant.isTrue) {
        return left;
      } else {
        return new HNot(left, backend.boolType);
      }
    }

    return null;
  }

  HInstruction visitIdentity(HIdentity node) {
    HInstruction newInstruction = handleIdentityCheck(node);
    return newInstruction == null ? super.visitIdentity(node) : newInstruction;
  }

  void simplifyCondition(HBasicBlock block,
                         HInstruction condition,
                         bool value) {
    condition.dominatedUsers(block.first).forEach((user) {
      HInstruction newCondition = graph.addConstantBool(value, compiler);
      user.changeUse(condition, newCondition);
    });
  }

  HInstruction visitIf(HIf node) {
    HInstruction condition = node.condition;
    if (condition.isConstant()) return node;
    bool isNegated = condition is HNot;

    if (isNegated) {
      condition = condition.inputs[0];
    } else {
      // It is possible for LICM to move a negated version of the
      // condition out of the loop where it used. We still want to
      // simplify the nested use of the condition in that case, so
      // we look for all dominating negated conditions and replace
      // nested uses of them with true or false.
      Iterable<HInstruction> dominating = condition.usedBy.where((user) =>
          user is HNot && user.dominates(node));
      dominating.forEach((hoisted) {
        simplifyCondition(node.thenBlock, hoisted, false);
        simplifyCondition(node.elseBlock, hoisted, true);
      });
    }
    simplifyCondition(node.thenBlock, condition, !isNegated);
    simplifyCondition(node.elseBlock, condition, isNegated);
    return node;
  }

  HInstruction visitIs(HIs node) {
    DartType type = node.typeExpression;
    Element element = type.element;

    if (!node.isRawCheck) {
      return node;
    } else if (type.isTypedef) {
      return node;
    } else if (element == compiler.functionClass) {
      return node;
    }

    if (element == compiler.objectClass || type.treatAsDynamic) {
      return graph.addConstantBool(true, compiler);
    }

    ClassWorld classWorld = compiler.world;
    HInstruction expression = node.expression;
    if (expression.isInteger(compiler)) {
      if (identical(element, compiler.intClass)
          || identical(element, compiler.numClass)
          || Elements.isNumberOrStringSupertype(element, compiler)) {
        return graph.addConstantBool(true, compiler);
      } else if (identical(element, compiler.doubleClass)) {
        // We let the JS semantics decide for that check. Currently
        // the code we emit will always return true.
        return node;
      } else {
        return graph.addConstantBool(false, compiler);
      }
    } else if (expression.isDouble(compiler)) {
      if (identical(element, compiler.doubleClass)
          || identical(element, compiler.numClass)
          || Elements.isNumberOrStringSupertype(element, compiler)) {
        return graph.addConstantBool(true, compiler);
      } else if (identical(element, compiler.intClass)) {
        // We let the JS semantics decide for that check. Currently
        // the code we emit will return true for a double that can be
        // represented as a 31-bit integer and for -0.0.
        return node;
      } else {
        return graph.addConstantBool(false, compiler);
      }
    } else if (expression.isNumber(compiler)) {
      if (identical(element, compiler.numClass)) {
        return graph.addConstantBool(true, compiler);
      } else {
        // We cannot just return false, because the expression may be of
        // type int or double.
      }
    } else if (expression.canBePrimitiveNumber(compiler)
               && identical(element, compiler.intClass)) {
      // We let the JS semantics decide for that check.
      return node;
    // We need the [:hasTypeArguments:] check because we don't have
    // the notion of generics in the backend. For example, [:this:] in
    // a class [:A<T>:], is currently always considered to have the
    // raw type.
    } else if (!RuntimeTypes.hasTypeArguments(type)) {
      TypeMask expressionMask = expression.instructionType;
      assert(TypeMask.assertIsNormalized(expressionMask, classWorld));
      TypeMask typeMask = (element == compiler.nullClass)
          ? new TypeMask.subtype(element, classWorld)
          : new TypeMask.nonNullSubtype(element, classWorld);
      if (expressionMask.union(typeMask, classWorld) == typeMask) {
        return graph.addConstantBool(true, compiler);
      } else if (expressionMask.intersection(typeMask,
                                             compiler.world).isEmpty) {
        return graph.addConstantBool(false, compiler);
      }
    }
    return node;
  }

  HInstruction visitTypeConversion(HTypeConversion node) {
    HInstruction value = node.inputs[0];
    DartType type = node.typeExpression;
    if (type != null) {
      if (type.isMalformed) {
        // Malformed types are treated as dynamic statically, but should
        // throw a type error at runtime.
        return node;
      }
      if (!type.treatAsRaw || type.isTypeVariable) {
        return node;
      }
      if (type.isFunctionType) {
        // TODO(johnniwinther): Optimize function type conversions.
        return node;
      }
    }
    return removeIfCheckAlwaysSucceeds(node, node.checkedType);
  }

  HInstruction visitTypeKnown(HTypeKnown node) {
    return removeIfCheckAlwaysSucceeds(node, node.knownType);
  }

  HInstruction removeIfCheckAlwaysSucceeds(HCheck node, TypeMask checkedType) {
    ClassWorld classWorld = compiler.world;
    if (checkedType.containsAll(classWorld)) return node;
    HInstruction input = node.checkedInput;
    TypeMask inputType = input.instructionType;
    return inputType.isInMask(checkedType, classWorld) ? input : node;
  }

  VariableElement findConcreteFieldForDynamicAccess(HInstruction receiver,
                                                    Selector selector) {
    TypeMask receiverType = receiver.instructionType;
    return compiler.world.locateSingleField(
        new TypedSelector(receiverType, selector, compiler.world));
  }

  HInstruction visitFieldGet(HFieldGet node) {
    if (node.isNullCheck) return node;
    var receiver = node.receiver;
    if (node.element == backend.jsIndexableLength) {
      JavaScriptItemCompilationContext context = work.compilationContext;
      if (context.allocatedFixedLists.contains(receiver)) {
        // TODO(ngeoffray): checking if the second input is an integer
        // should not be necessary but it currently makes it easier for
        // other optimizations to reason about a fixed length constructor
        // that we know takes an int.
        if (receiver.inputs[0].isInteger(compiler)) {
          return receiver.inputs[0];
        }
      } else if (receiver.isConstantList() || receiver.isConstantString()) {
        return graph.addConstantInt(receiver.constant.length, compiler);
      } else {
        var type = receiver.instructionType;
        if (type.isContainer && type.length != null) {
          HInstruction constant = graph.addConstantInt(type.length, compiler);
          if (type.isNullable) {
            // If the container can be null, we update all uses of the
            // length access to use the constant instead, but keep the
            // length access in the graph, to ensure we still have a
            // null check.
            node.block.rewrite(node, constant);
            return node;
          } else {
            return constant;
          }
        }
      }
    }

    // HFieldGet of a constructed constant can be replaced with the constant's
    // field.
    if (receiver is HConstant) {
      ConstantValue constant = receiver.constant;
      if (constant.isConstructedObject) {
        ConstructedConstantValue constructedConstant = constant;
        Map<Element, ConstantValue> fields = constructedConstant.fieldElements;
        ConstantValue value = fields[node.element];
        if (value != null) {
          return graph.addConstant(value, compiler);
        }
      }
    }

    return node;
  }

  HInstruction visitIndex(HIndex node) {
    if (node.receiver.isConstantList() && node.index.isConstantInteger()) {
      var instruction = node.receiver;
      List<ConstantValue> entries = instruction.constant.entries;
      instruction = node.index;
      int index = instruction.constant.primitiveValue;
      if (index >= 0 && index < entries.length) {
        return graph.addConstant(entries[index], compiler);
      }
    }
    return node;
  }

  HInstruction visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }
    HInstruction receiver = node.getDartReceiver(compiler);
    Element field = findConcreteFieldForDynamicAccess(receiver, node.selector);
    if (field == null) return node;
    return directFieldGet(receiver, field);
  }

  HInstruction directFieldGet(HInstruction receiver, Element field) {
    bool isAssignable = !compiler.world.fieldNeverChanges(field);

    TypeMask type;
    if (field.enclosingClass.isNative) {
      type = TypeMaskFactory.fromNativeBehavior(
          native.NativeBehavior.ofFieldLoad(field, compiler),
          compiler);
    } else {
      type = TypeMaskFactory.inferredTypeForElement(field, compiler);
    }

    return new HFieldGet(
        field, receiver, type, isAssignable: isAssignable);
  }

  HInstruction visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    HInstruction receiver = node.getDartReceiver(compiler);
    VariableElement field =
        findConcreteFieldForDynamicAccess(receiver, node.selector);
    if (field == null || !field.isAssignable) return node;
    // Use [:node.inputs.last:] in case the call follows the
    // interceptor calling convention, but is not a call on an
    // interceptor.
    HInstruction value = node.inputs.last;
    if (compiler.enableTypeAssertions) {
      DartType type = field.type;
      if (!type.treatAsRaw || type.isTypeVariable) {
        // We cannot generate the correct type representation here, so don't
        // inline this access.
        return node;
      }
      HInstruction other = value.convertType(
          compiler,
          type,
          HTypeConversion.CHECKED_MODE_CHECK);
      if (other != value) {
        node.block.addBefore(node, other);
        value = other;
      }
    }
    return new HFieldSet(field, receiver, value);
  }

  HInstruction visitStringConcat(HStringConcat node) {
    // Simplify string concat:
    //
    //     "" + R                ->  R
    //     L + ""                ->  L
    //     "L" + "R"             ->  "LR"
    //     (prefix + "L") + "R"  ->  prefix + "LR"
    //
    StringConstantValue getString(HInstruction instruction) {
      if (!instruction.isConstantString()) return null;
      HConstant constant = instruction;
      return constant.constant;
    }

    StringConstantValue leftString = getString(node.left);
    if (leftString != null && leftString.primitiveValue.length == 0) {
      return node.right;
    }

    StringConstantValue rightString = getString(node.right);
    if (rightString == null) return node;
    if (rightString.primitiveValue.length == 0) return node.left;

    HInstruction prefix = null;
    if (leftString == null) {
      if (node.left is! HStringConcat) return node;
      HStringConcat leftConcat = node.left;
      // Don't undo CSE.
      if (leftConcat.usedBy.length != 1) return node;
      prefix = leftConcat.left;
      leftString = getString(leftConcat.right);
      if (leftString == null) return node;
    }

    if (leftString.primitiveValue.length + rightString.primitiveValue.length >
        MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH) {
      if (node.usedBy.length > 1) return node;
    }

    HInstruction folded = graph.addConstant(
        constantSystem.createString(new ast.DartString.concat(
            leftString.primitiveValue, rightString.primitiveValue)),
        compiler);
    if (prefix == null) return folded;
    return new HStringConcat(prefix, folded, node.node, backend.stringType);
  }

  HInstruction visitStringify(HStringify node) {
    HInstruction input = node.inputs[0];
    if (input.isString(compiler)) return input;
    if (input.isConstant()) {
      HConstant constant = input;
      if (!constant.constant.isPrimitive) return node;
      if (constant.constant.isInt) {
        // Only constant-fold int.toString() when Dart and JS results the same.
        // TODO(18103): We should be able to remove this work-around when issue
        // 18103 is resolved by providing the correct string.
        IntConstantValue intConstant = constant.constant;
        // Very conservative range.
        if (!intConstant.isUInt32()) return node;
      }
      PrimitiveConstantValue primitive = constant.constant;
      return graph.addConstant(constantSystem.createString(
          primitive.toDartString()), compiler);
    }
    return node;
  }

  HInstruction visitOneShotInterceptor(HOneShotInterceptor node) {
    return handleInterceptedCall(node);
  }
}

class SsaCheckInserter extends HBaseVisitor implements OptimizationPhase {
  final Set<HInstruction> boundsChecked;
  final CodegenWorkItem work;
  final bool trustPrimitives;
  final JavaScriptBackend backend;
  final String name = "SsaCheckInserter";
  HGraph graph;

  SsaCheckInserter(this.trustPrimitives,
                   this.backend,
                   this.work,
                   this.boundsChecked);

  void visitGraph(HGraph graph) {
    this.graph = graph;

    // In --trust-primitives mode we don't add bounds checks.  This is better
    // than trying to remove them later as the limit expression would become
    // dead and require DCE.
    if (trustPrimitives) return;

    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction = instruction.accept(this);
      instruction = next;
    }
  }

  HBoundsCheck insertBoundsCheck(HInstruction indexNode,
                                 HInstruction array,
                                 HInstruction indexArgument) {
    Compiler compiler = backend.compiler;
    HFieldGet length = new HFieldGet(
        backend.jsIndexableLength, array, backend.positiveIntType,
        isAssignable: !isFixedLength(array.instructionType, compiler));
    indexNode.block.addBefore(indexNode, length);

    TypeMask type = indexArgument.isPositiveInteger(compiler)
        ? indexArgument.instructionType
        : backend.positiveIntType;
    HBoundsCheck check = new HBoundsCheck(
        indexArgument, length, array, type);
    indexNode.block.addBefore(indexNode, check);
    // If the index input to the bounds check was not known to be an integer
    // then we replace its uses with the bounds check, which is known to be an
    // integer.  However, if the input was already an integer we don't do this
    // because putting in a check instruction might obscure the real nature of
    // the index eg. if it is a constant.  The range information from the
    // BoundsCheck instruction is attached to the input directly by
    // visitBoundsCheck in the SsaValueRangeAnalyzer.
    if (!indexArgument.isInteger(compiler)) {
      indexArgument.replaceAllUsersDominatedBy(indexNode, check);
    }
    boundsChecked.add(indexNode);
    return check;
  }

  void visitIndex(HIndex node) {
    if (boundsChecked.contains(node)) return;
    HInstruction index = node.index;
    index = insertBoundsCheck(node, node.receiver, index);
  }

  void visitIndexAssign(HIndexAssign node) {
    if (boundsChecked.contains(node)) return;
    HInstruction index = node.index;
    index = insertBoundsCheck(node, node.receiver, index);
  }

  void visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    Element element = node.element;
    if (node.isInterceptedCall) return;
    if (element != backend.jsArrayRemoveLast) return;
    if (boundsChecked.contains(node)) return;
    insertBoundsCheck(
        node, node.receiver, graph.addConstantInt(0, backend.compiler));
  }
}

class SsaDeadCodeEliminator extends HGraphVisitor implements OptimizationPhase {
  final String name = "SsaDeadCodeEliminator";

  final Compiler compiler;
  final SsaOptimizerTask optimizer;
  SsaLiveBlockAnalyzer analyzer;
  Map<HInstruction, bool> trivialDeadStoreReceivers =
      new Maplet<HInstruction, bool>();
  bool eliminatedSideEffects = false;
  SsaDeadCodeEliminator(this.compiler, this.optimizer);

  HInstruction zapInstructionCache;
  HInstruction get zapInstruction {
    if (zapInstructionCache == null) {
      // A constant with no type does not pollute types at phi nodes.
      ConstantValue constant =
          new DummyConstantValue(const TypeMask.nonNullEmpty());
      zapInstructionCache = analyzer.graph.addConstant(constant, compiler);
    }
    return zapInstructionCache;
  }

  /// Returns whether the next throwing instruction that may have side
  /// effects after [instruction], throws [NoSuchMethodError] on the
  /// same receiver of [instruction].
  bool hasFollowingThrowingNSM(HInstruction instruction) {
    HInstruction receiver = instruction.getDartReceiver(compiler);
    HInstruction current = instruction.next;
    do {
      if ((current.getDartReceiver(compiler) == receiver)
          && current.canThrow()) {
        return true;
      }
      if (current.canThrow() || current.sideEffects.hasSideEffects()) {
        return false;
      }
      if (current.next == null && current is HGoto) {
        // We do not merge blocks in our SSA graph, so if this block
        // just jumps to a single predecessor, visit this predecessor.
        assert(current.block.successors.length == 1);
        current = current.block.successors[0].first;
      } else {
        current = current.next;
      }
    } while (current != null);
    return false;
  }

  bool isTrivialDeadStoreReceiver(HInstruction instruction) {
    // For an allocation, if all the loads are dead (awaiting removal after
    // SsaLoadElimination) and the only other uses are stores, then the
    // allocation does not escape which makes all the stores dead too.
    bool isDeadUse(HInstruction use) {
      if (use is HFieldSet) {
        // The use must be the receiver.  Even if the use is also the argument,
        // i.e.  a.x = a, the store is still dead if all other uses are dead.
        if (use.getDartReceiver(compiler) == instruction) return true;
      } else if (use is HFieldGet) {
        assert(use.getDartReceiver(compiler) == instruction);
        if (isDeadCode(use)) return true;
      }
      return false;
    }
    return instruction is HForeignNew
        && trivialDeadStoreReceivers.putIfAbsent(instruction,
            () => instruction.usedBy.every(isDeadUse));
  }

  bool isTrivialDeadStore(HInstruction instruction) {
    return instruction is HFieldSet
        && isTrivialDeadStoreReceiver(instruction.getDartReceiver(compiler));
  }

  bool isDeadCode(HInstruction instruction) {
    if (!instruction.usedBy.isEmpty) return false;
    if (isTrivialDeadStore(instruction)) return true;
    if (instruction.sideEffects.hasSideEffects()) return false;
    if (instruction.canThrow()
        && instruction.onlyThrowsNSM()
        && hasFollowingThrowingNSM(instruction)) {
      return true;
    }
    return !instruction.canThrow()
           && instruction is !HParameterValue
           && instruction is !HLocalSet;
  }

  void visitGraph(HGraph graph) {
    analyzer = new SsaLiveBlockAnalyzer(graph, compiler, optimizer);
    analyzer.analyze();
    visitPostDominatorTree(graph);
    cleanPhis(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    bool isDeadBlock = analyzer.isDeadBlock(block);
    block.isLive = !isDeadBlock;
    // Start from the last non-control flow instruction in the block.
    HInstruction instruction = block.last.previous;
    while (instruction != null) {
      var previous = instruction.previous;
      if (isDeadBlock) {
        eliminatedSideEffects = eliminatedSideEffects ||
            instruction.sideEffects.hasSideEffects();
        removeUsers(instruction);
        block.remove(instruction);
      } else if (isDeadCode(instruction)) {
        block.remove(instruction);
      }
      instruction = previous;
    }
  }

  void cleanPhis(HGraph graph) {
    L: for (HBasicBlock block in graph.blocks) {
      List<HBasicBlock> predecessors = block.predecessors;
      // Zap all inputs to phis that correspond to dead blocks.
      block.forEachPhi((HPhi phi) {
        for (int i = 0; i < phi.inputs.length; ++i) {
          if (!predecessors[i].isLive && phi.inputs[i] != zapInstruction) {
            replaceInput(i, phi, zapInstruction);
          }
        }
      });
      if (predecessors.length < 2) continue L;
      // Find the index of the single live predecessor if it exists.
      int indexOfLive = -1;
      for (int i = 0; i < predecessors.length; i++) {
        if (predecessors[i].isLive) {
          if (indexOfLive >= 0) continue L;
          indexOfLive = i;
        }
      }
      // Run through the phis of the block and replace them with their input
      // that comes from the only live predecessor if that dominates the phi.
      block.forEachPhi((HPhi phi) {
        HInstruction replacement = (indexOfLive >= 0)
            ? phi.inputs[indexOfLive] : zapInstruction;
        if (replacement.dominates(phi)) {
          block.rewrite(phi, replacement);
          block.removePhi(phi);
        }
      });
    }
  }

  void replaceInput(int i, HInstruction from, HInstruction by) {
    from.inputs[i].usedBy.remove(from);
    from.inputs[i] = by;
    by.usedBy.add(from);
  }

  void removeUsers(HInstruction instruction) {
    instruction.usedBy.forEach((user) {
      removeInput(user, instruction);
    });
    instruction.usedBy.clear();
  }

  void removeInput(HInstruction user, HInstruction input) {
    List<HInstruction> inputs = user.inputs;
    for (int i = 0, length = inputs.length; i < length; i++) {
      if (input == inputs[i]) {
        user.inputs[i] = zapInstruction;
        zapInstruction.usedBy.add(user);
      }
    }
  }
}

class SsaLiveBlockAnalyzer extends HBaseVisitor {
  final HGraph graph;
  final Set<HBasicBlock> live = new Set<HBasicBlock>();
  final List<HBasicBlock> worklist = <HBasicBlock>[];
  final SsaOptimizerTask optimizer;
  final Compiler compiler;

  SsaLiveBlockAnalyzer(this.graph, this.compiler, this.optimizer);

  Map<HInstruction, Range> get ranges => optimizer.ranges;

  bool isDeadBlock(HBasicBlock block) => !live.contains(block);

  void analyze() {
    markBlockLive(graph.entry);
    while (!worklist.isEmpty) {
      HBasicBlock live = worklist.removeLast();
      live.last.accept(this);
    }
  }

  void markBlockLive(HBasicBlock block) {
    if (!live.contains(block)) {
      worklist.add(block);
      live.add(block);
    }
  }

  void visitControlFlow(HControlFlow instruction) {
    instruction.block.successors.forEach(markBlockLive);
  }

  void visitIf(HIf instruction) {
    HInstruction condition = instruction.condition;
    if (condition.isConstant()) {
      if (condition.isConstantTrue()) {
        markBlockLive(instruction.thenBlock);
      } else {
        markBlockLive(instruction.elseBlock);
      }
    } else {
      visitControlFlow(instruction);
    }
  }

  void visitSwitch(HSwitch node) {
    if (node.expression.isInteger(compiler)) {
      Range switchRange = ranges[node.expression];
      if (switchRange != null &&
          switchRange.lower is IntValue &&
          switchRange.upper is IntValue) {
        IntValue lowerValue = switchRange.lower;
        IntValue upperValue = switchRange.upper;
        int lower = lowerValue.value;
        int upper = upperValue.value;
        Set<int> liveLabels = new Set<int>();
        for (int pos = 1; pos < node.inputs.length; pos++) {
          HConstant input = node.inputs[pos];
          if (!input.isConstantInteger()) continue;
          IntConstantValue constant = input.constant;
          int label = constant.primitiveValue;
          if (!liveLabels.contains(label) &&
              label <= upper &&
              label >= lower) {
            markBlockLive(node.block.successors[pos - 1]);
            liveLabels.add(label);
          }
        }
        if (liveLabels.length != upper - lower + 1) {
          markBlockLive(node.defaultTarget);
        }
        return;
      }
    }
    visitControlFlow(node);
  }
}

class SsaDeadPhiEliminator implements OptimizationPhase {
  final String name = "SsaDeadPhiEliminator";

  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = <HPhi>[];
    // A set to keep track of the live phis that we found.
    final Set<HPhi> livePhis = new Set<HPhi>();

    // Add to the worklist all live phis: phis referenced by non-phi
    // instructions.
    for (final block in graph.blocks) {
      block.forEachPhi((HPhi phi) {
        for (final user in phi.usedBy) {
          if (user is !HPhi) {
            worklist.add(phi);
            livePhis.add(phi);
            break;
          }
        }
      });
    }

    // Process the worklist by propagating liveness to phi inputs.
    while (!worklist.isEmpty) {
      HPhi phi = worklist.removeLast();
      for (final input in phi.inputs) {
        if (input is HPhi && !livePhis.contains(input)) {
          worklist.add(input);
          livePhis.add(input);
        }
      }
    }

    // Remove phis that are not live.
    // Traverse in reverse order to remove phis with no uses before the
    // phis that they might use.
    // NOTICE: Doesn't handle circular references, but we don't currently
    // create any.
    List<HBasicBlock> blocks = graph.blocks;
    for (int i = blocks.length - 1; i >= 0; i--) {
      HBasicBlock block = blocks[i];
      HPhi current = block.phis.first;
      HPhi next = null;
      while (current != null) {
        next = current.next;
        if (!livePhis.contains(current)
            // TODO(ahe): Not sure the following is correct.
            && current.usedBy.isEmpty) {
          block.removePhi(current);
        }
        current = next;
      }
    }
  }
}

class SsaRedundantPhiEliminator implements OptimizationPhase {
  final String name = "SsaRedundantPhiEliminator";

  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = <HPhi>[];

    // Add all phis in the worklist.
    for (final block in graph.blocks) {
      block.forEachPhi((HPhi phi) => worklist.add(phi));
    }

    while (!worklist.isEmpty) {
      HPhi phi = worklist.removeLast();

      // If the phi has already been processed, continue.
      if (!phi.isInBasicBlock()) continue;

      // Find if the inputs of the phi are the same instruction.
      // The builder ensures that phi.inputs[0] cannot be the phi
      // itself.
      assert(!identical(phi.inputs[0], phi));
      HInstruction candidate = phi.inputs[0];
      for (int i = 1; i < phi.inputs.length; i++) {
        HInstruction input = phi.inputs[i];
        // If the input is the phi, the phi is still candidate for
        // elimination.
        if (!identical(input, candidate) && !identical(input, phi)) {
          candidate = null;
          break;
        }
      }

      // If the inputs are not the same, continue.
      if (candidate == null) continue;

      // Because we're updating the users of this phi, we may have new
      // phis candidate for elimination. Add phis that used this phi
      // to the worklist.
      for (final user in phi.usedBy) {
        if (user is HPhi) worklist.add(user);
      }
      phi.block.rewrite(phi, candidate);
      phi.block.removePhi(phi);
    }
  }
}

class GvnWorkItem {
  final HBasicBlock block;
  final ValueSet valueSet;
  GvnWorkItem(this.block, this.valueSet);
}

class SsaGlobalValueNumberer implements OptimizationPhase {
  final String name = "SsaGlobalValueNumberer";
  final Compiler compiler;
  final Set<int> visited;

  List<int> blockChangesFlags;
  List<int> loopChangesFlags;

  SsaGlobalValueNumberer(this.compiler) : visited = new Set<int>();

  void visitGraph(HGraph graph) {
    computeChangesFlags(graph);
    moveLoopInvariantCode(graph);
    List<GvnWorkItem> workQueue =
        <GvnWorkItem>[new GvnWorkItem(graph.entry, new ValueSet())];
    do {
      GvnWorkItem item = workQueue.removeLast();
      visitBasicBlock(item.block, item.valueSet, workQueue);
    } while (!workQueue.isEmpty);
  }

  void moveLoopInvariantCode(HGraph graph) {
    for (int i = graph.blocks.length - 1; i >= 0; i--) {
      HBasicBlock block = graph.blocks[i];
      if (block.isLoopHeader()) {
        int changesFlags = loopChangesFlags[block.id];
        HLoopInformation info = block.loopInformation;
        // Iterate over all blocks of this loop. Note that blocks in
        // inner loops are not visited here, but we know they
        // were visited before because we are iterating in post-order.
        // So instructions that are GVN'ed in an inner loop are in their
        // loop entry, and [info.blocks] contains this loop entry.
        moveLoopInvariantCodeFromBlock(block, block, changesFlags);
        for (HBasicBlock other in info.blocks) {
          moveLoopInvariantCodeFromBlock(other, block, changesFlags);
        }
      }
    }
  }

  void moveLoopInvariantCodeFromBlock(HBasicBlock block,
                                      HBasicBlock loopHeader,
                                      int changesFlags) {
    assert(block.parentLoopHeader == loopHeader || block == loopHeader);
    HBasicBlock preheader = loopHeader.predecessors[0];
    int dependsFlags = SideEffects.computeDependsOnFlags(changesFlags);
    HInstruction instruction = block.first;
    bool isLoopAlwaysTaken() {
      HInstruction instruction = loopHeader.last;
      assert(instruction is HGoto || instruction is HLoopBranch);
      return instruction is HGoto
          || instruction.inputs[0].isConstantTrue();
    }
    bool firstInstructionInLoop = block == loopHeader
        // Compensate for lack of code motion.
        || (blockChangesFlags[loopHeader.id] == 0
            && isLoopAlwaysTaken()
            && loopHeader.successors[0] == block);
    while (instruction != null) {
      HInstruction next = instruction.next;
      if (instruction.useGvn() && instruction.isMovable
          && (!instruction.canThrow() || firstInstructionInLoop)
          && !instruction.sideEffects.dependsOn(dependsFlags)) {
        bool loopInvariantInputs = true;
        List<HInstruction> inputs = instruction.inputs;
        for (int i = 0, length = inputs.length; i < length; i++) {
          if (isInputDefinedAfterDominator(inputs[i], preheader)) {
            loopInvariantInputs = false;
            break;
          }
        }

        // If the inputs are loop invariant, we can move the
        // instruction from the current block to the pre-header block.
        if (loopInvariantInputs) {
          block.detach(instruction);
          preheader.moveAtExit(instruction);
        } else {
          firstInstructionInLoop = false;
        }
      }
      int oldChangesFlags = changesFlags;
      changesFlags |= instruction.sideEffects.getChangesFlags();
      if (oldChangesFlags != changesFlags) {
        dependsFlags = SideEffects.computeDependsOnFlags(changesFlags);
      }
      instruction = next;
    }
  }

  bool isInputDefinedAfterDominator(HInstruction input,
                                    HBasicBlock dominator) {
    return input.block.id > dominator.id;
  }

  void visitBasicBlock(
      HBasicBlock block, ValueSet values, List<GvnWorkItem> workQueue) {
    HInstruction instruction = block.first;
    if (block.isLoopHeader()) {
      int flags = loopChangesFlags[block.id];
      values.kill(flags);
    }
    while (instruction != null) {
      HInstruction next = instruction.next;
      int flags = instruction.sideEffects.getChangesFlags();
      assert(flags == 0 || !instruction.useGvn());
      values.kill(flags);
      if (instruction.useGvn()) {
        HInstruction other = values.lookup(instruction);
        if (other != null) {
          assert(other.gvnEquals(instruction) && instruction.gvnEquals(other));
          block.rewriteWithBetterUser(instruction, other);
          block.remove(instruction);
        } else {
          values.add(instruction);
        }
      }
      instruction = next;
    }

    List<HBasicBlock> dominatedBlocks = block.dominatedBlocks;
    for (int i = 0, length = dominatedBlocks.length; i < length; i++) {
      HBasicBlock dominated = dominatedBlocks[i];
      // No need to copy the value set for the last child.
      ValueSet successorValues = (i == length - 1) ? values : values.copy();
      // If we have no values in our set, we do not have to kill
      // anything. Also, if the range of block ids from the current
      // block to the dominated block is empty, there is no blocks on
      // any path from the current block to the dominated block so we
      // don't have to do anything either.
      assert(block.id < dominated.id);
      if (!successorValues.isEmpty && block.id + 1 < dominated.id) {
        visited.clear();
        List<HBasicBlock> workQueue = <HBasicBlock>[dominated];
        int changesFlags = 0;
        do {
          HBasicBlock current = workQueue.removeLast();
          changesFlags |=
              getChangesFlagsForDominatedBlock(block, current, workQueue);
        } while (!workQueue.isEmpty);
        successorValues.kill(changesFlags);
      }
      workQueue.add(new GvnWorkItem(dominated, successorValues));
    }
  }

  void computeChangesFlags(HGraph graph) {
    // Create the changes flags lists. Make sure to initialize the
    // loop changes flags list to zero so we can use bitwise or when
    // propagating loop changes upwards.
    final int length = graph.blocks.length;
    blockChangesFlags = new List<int>(length);
    loopChangesFlags = new List<int>(length);
    for (int i = 0; i < length; i++) loopChangesFlags[i] = 0;

    // Run through all the basic blocks in the graph and fill in the
    // changes flags lists.
    for (int i = length - 1; i >= 0; i--) {
      final HBasicBlock block = graph.blocks[i];
      final int id = block.id;

      // Compute block changes flags for the block.
      int changesFlags = 0;
      HInstruction instruction = block.first;
      while (instruction != null) {
        changesFlags |= instruction.sideEffects.getChangesFlags();
        instruction = instruction.next;
      }
      assert(blockChangesFlags[id] == null);
      blockChangesFlags[id] = changesFlags;

      // Loop headers are part of their loop, so update the loop
      // changes flags accordingly.
      if (block.isLoopHeader()) {
        loopChangesFlags[id] |= changesFlags;
      }

      // Propagate loop changes flags upwards.
      HBasicBlock parentLoopHeader = block.parentLoopHeader;
      if (parentLoopHeader != null) {
        loopChangesFlags[parentLoopHeader.id] |= (block.isLoopHeader())
            ? loopChangesFlags[id]
            : changesFlags;
      }
    }
  }

  int getChangesFlagsForDominatedBlock(HBasicBlock dominator,
                                       HBasicBlock dominated,
                                       List<HBasicBlock> workQueue) {
    int changesFlags = 0;
    List<HBasicBlock> predecessors = dominated.predecessors;
    for (int i = 0, length = predecessors.length; i < length; i++) {
      HBasicBlock block = predecessors[i];
      int id = block.id;
      // If the current predecessor block is on the path from the
      // dominator to the dominated, it must have an id that is in the
      // range from the dominator to the dominated.
      if (dominator.id < id && id < dominated.id && !visited.contains(id)) {
        visited.add(id);
        changesFlags |= blockChangesFlags[id];
        // Loop bodies might not be on the path from dominator to dominated,
        // but they can invalidate values.
        changesFlags |= loopChangesFlags[id];
        workQueue.add(block);
      }
    }
    return changesFlags;
  }
}

// This phase merges equivalent instructions on different paths into
// one instruction in a dominator block. It runs through the graph
// post dominator order and computes a ValueSet for each block of
// instructions that can be moved to a dominator block. These
// instructions are the ones that:
// 1) can be used for GVN, and
// 2) do not use definitions of their own block.
//
// A basic block looks at its sucessors and finds the intersection of
// these computed ValueSet. It moves all instructions of the
// intersection into its own list of instructions.
class SsaCodeMotion extends HBaseVisitor implements OptimizationPhase {
  final String name = "SsaCodeMotion";

  List<ValueSet> values;

  void visitGraph(HGraph graph) {
    values = new List<ValueSet>(graph.blocks.length);
    for (int i = 0; i < graph.blocks.length; i++) {
      values[graph.blocks[i].id] = new ValueSet();
    }
    visitPostDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    List<HBasicBlock> successors = block.successors;

    // Phase 1: get the ValueSet of all successors (if there are more than one),
    // compute the intersection and move the instructions of the intersection
    // into this block.
    if (successors.length > 1) {
      ValueSet instructions = values[successors[0].id];
      for (int i = 1; i < successors.length; i++) {
        ValueSet other = values[successors[i].id];
        instructions = instructions.intersection(other);
      }

      if (!instructions.isEmpty) {
        List<HInstruction> list = instructions.toList();
        for (HInstruction instruction in list) {
          // Move the instruction to the current block.
          instruction.block.detach(instruction);
          block.moveAtExit(instruction);
          // Go through all successors and rewrite their instruction
          // to the shared one.
          for (final successor in successors) {
            HInstruction toRewrite = values[successor.id].lookup(instruction);
            if (toRewrite != instruction) {
              successor.rewriteWithBetterUser(toRewrite, instruction);
              successor.remove(toRewrite);
            }
          }
        }
      }
    }

    // Don't try to merge instructions to a dominator if we have
    // multiple predecessors.
    if (block.predecessors.length != 1) return;

    // Phase 2: Go through all instructions of this block and find
    // which instructions can be moved to a dominator block.
    ValueSet set_ = values[block.id];
    HInstruction instruction = block.first;
    int flags = 0;
    while (instruction != null) {
      int dependsFlags = SideEffects.computeDependsOnFlags(flags);
      flags |= instruction.sideEffects.getChangesFlags();

      HInstruction current = instruction;
      instruction = instruction.next;
      if (!current.useGvn() || !current.isMovable) continue;
      // TODO(sra): We could move throwing instructions provided we keep the
      // exceptions in the same order.  This requires they are in the same order
      // in all successors, which is not tracked by the ValueSet.
      if (current.canThrow()) continue;
      if (current.sideEffects.dependsOn(dependsFlags)) continue;

      bool canBeMoved = true;
      for (final HInstruction input in current.inputs) {
        if (input.block == block) {
          canBeMoved = false;
          break;
        }
      }
      if (!canBeMoved) continue;

      HInstruction existing = set_.lookup(current);
      if (existing == null) {
        set_.add(current);
      } else {
        block.rewriteWithBetterUser(current, existing);
        block.remove(current);
      }
    }
  }
}

class SsaTypeConversionInserter extends HBaseVisitor
    implements OptimizationPhase {
  final String name = "SsaTypeconversionInserter";
  final Compiler compiler;

  SsaTypeConversionInserter(this.compiler);

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  // Update users of [input] that are dominated by [:dominator.first:]
  // to use [TypeKnown] of [input] instead. As the type information depends
  // on the control flow, we mark the inserted [HTypeKnown] nodes as
  // non-movable.
  void insertTypePropagationForDominatedUsers(HBasicBlock dominator,
                                              HInstruction input,
                                              TypeMask convertedType) {
    Setlet<HInstruction> dominatedUsers = input.dominatedUsers(dominator.first);
    if (dominatedUsers.isEmpty) return;

    HTypeKnown newInput = new HTypeKnown.pinned(convertedType, input);
    dominator.addBefore(dominator.first, newInput);
    dominatedUsers.forEach((HInstruction user) {
      user.changeUse(input, newInput);
    });
  }

  void visitIs(HIs instruction) {
    DartType type = instruction.typeExpression;
    Element element = type.element;
    if (!instruction.isRawCheck) {
      return;
    } else if (element.isTypedef) {
      return;
    }

    List<HInstruction> ifUsers = <HInstruction>[];
    List<HInstruction> notIfUsers = <HInstruction>[];

    collectIfUsers(instruction, ifUsers, notIfUsers);

    if (ifUsers.isEmpty && notIfUsers.isEmpty) return;

    TypeMask convertedType =
        new TypeMask.nonNullSubtype(element, compiler.world);
    HInstruction input = instruction.expression;

    for (HIf ifUser in ifUsers) {
      insertTypePropagationForDominatedUsers(ifUser.thenBlock, input,
                                             convertedType);
      // TODO(ngeoffray): Also change uses for the else block on a type
      // that knows it is not of a specific type.
    }
    for (HIf ifUser in notIfUsers) {
      insertTypePropagationForDominatedUsers(ifUser.elseBlock, input,
                                             convertedType);
      // TODO(ngeoffray): Also change uses for the then block on a type
      // that knows it is not of a specific type.
    }
  }

  void visitIdentity(HIdentity instruction) {
    // At HIf(HIdentity(x, null)) strengthens x to non-null on else branch.
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    HInstruction input;

    if (left.isConstantNull()) {
      input = right;
    } else if (right.isConstantNull()) {
      input = left;
    } else {
      return;
    }

    if (!input.instructionType.isNullable) return;

    List<HInstruction> ifUsers = <HInstruction>[];
    List<HInstruction> notIfUsers = <HInstruction>[];

    collectIfUsers(instruction, ifUsers, notIfUsers);

    if (ifUsers.isEmpty && notIfUsers.isEmpty) return;

    TypeMask nonNullType = input.instructionType.nonNullable();

    for (HIf ifUser in ifUsers) {
      insertTypePropagationForDominatedUsers(ifUser.elseBlock, input,
                                             nonNullType);
      // Uses in thenBlock are `null`, but probably not common.
    }
    for (HIf ifUser in notIfUsers) {
      insertTypePropagationForDominatedUsers(ifUser.thenBlock, input,
                                             nonNullType);
      // Uses in elseBlock are `null`, but probably not common.
    }
  }

  collectIfUsers(HInstruction instruction,
                 List<HInstruction> ifUsers,
                 List<HInstruction> notIfUsers) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HIf) {
        ifUsers.add(user);
      } else if (user is HNot) {
        collectIfUsers(user, notIfUsers, ifUsers);
      }
    }
  }
}

/**
 * Optimization phase that tries to eliminate memory loads (for
 * example [HFieldGet]), when it knows the value stored in that memory
 * location.
 */
class SsaLoadElimination extends HBaseVisitor implements OptimizationPhase {
  final Compiler compiler;
  final String name = "SsaLoadElimination";
  MemorySet memorySet;
  List<MemorySet> memories;

  SsaLoadElimination(this.compiler);

  void visitGraph(HGraph graph) {
    memories = new List<MemorySet>(graph.blocks.length);
    List<HBasicBlock> blocks = graph.blocks;
    for (int i = 0; i < blocks.length; i++) {
      HBasicBlock block = blocks[i];
      visitBasicBlock(block);
      if (block.successors.isNotEmpty && block.successors[0].isLoopHeader()) {
        // We've reached the ending block of a loop. Iterate over the
        // blocks of the loop again to take values that flow from that
        // ending block into account.
        for (int j = block.successors[0].id; j <= block.id; j++) {
          visitBasicBlock(blocks[j]);
        }
      }
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    if (block.predecessors.length == 0) {
      // Entry block.
      memorySet = new MemorySet(compiler);
    } else if (block.predecessors.length == 1
               && block.predecessors[0].successors.length == 1) {
      // No need to clone, there is no other successor for
      // `block.predecessors[0]`, and this block has only one
      // predecessor. Since we are not going to visit
      // `block.predecessors[0]` again, we can just re-use its
      // [memorySet].
      memorySet = memories[block.predecessors[0].id];
    } else if (block.predecessors.length == 1) {
      // Clone the memorySet of the predecessor, because it is also used
      // by other successors of it.
      memorySet = memories[block.predecessors[0].id].clone();
    } else {
      // Compute the intersection of all predecessors.
      memorySet = memories[block.predecessors[0].id];
      for (int i = 1; i < block.predecessors.length; i++) {
        memorySet = memorySet.intersectionFor(
          memories[block.predecessors[i].id], block, i);
      }
    }

    memories[block.id] = memorySet;
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  void visitFieldGet(HFieldGet instruction) {
    if (instruction.isNullCheck) return;
    Element element = instruction.element;
    HInstruction receiver =
        instruction.getDartReceiver(compiler).nonCheck();
    HInstruction existing = memorySet.lookupFieldValue(element, receiver);
    if (existing != null) {
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, receiver, instruction);
    }
  }

  void visitFieldSet(HFieldSet instruction) {
    HInstruction receiver =
        instruction.getDartReceiver(compiler).nonCheck();
    memorySet.registerFieldValueUpdate(
        instruction.element, receiver, instruction.inputs.last);
  }

  void visitForeignNew(HForeignNew instruction) {
    memorySet.registerAllocation(instruction);
    int argumentIndex = 0;
    instruction.element.forEachInstanceField((_, Element member) {
      memorySet.registerFieldValue(
          member, instruction, instruction.inputs[argumentIndex++]);
    }, includeSuperAndInjectedMembers: true);
    // In case this instruction has as input non-escaping objects, we
    // need to mark these objects as escaping.
    memorySet.killAffectedBy(instruction);
  }

  void visitInstruction(HInstruction instruction) {
    memorySet.killAffectedBy(instruction);
  }

  void visitLazyStatic(HLazyStatic instruction) {
    handleStaticLoad(instruction.element, instruction);
  }

  void handleStaticLoad(Element element, HInstruction instruction) {
    HInstruction existing = memorySet.lookupFieldValue(element, null);
    if (existing != null) {
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, null, instruction);
    }
  }

  void visitStatic(HStatic instruction) {
    handleStaticLoad(instruction.element, instruction);
  }

  void visitStaticStore(HStaticStore instruction) {
    memorySet.registerFieldValueUpdate(
        instruction.element, null, instruction.inputs.last);
  }

  void visitLiteralList(HLiteralList instruction) {
    memorySet.registerAllocation(instruction);
    memorySet.killAffectedBy(instruction);
  }

  void visitIndex(HIndex instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    HInstruction existing =
        memorySet.lookupKeyedValue(receiver, instruction.index);
    if (existing != null) {
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerKeyedValue(receiver, instruction.index, instruction);
    }
  }

  void visitIndexAssign(HIndexAssign instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    memorySet.registerKeyedValueUpdate(
        receiver, instruction.index, instruction.value);
  }
}

/**
 * Holds values of memory places.
 */
class MemorySet {
  final Compiler compiler;

  /**
   * Maps a field to a map of receiver to value.
   */
  final Map<Element, Map<HInstruction, HInstruction>> fieldValues =
      <Element, Map<HInstruction, HInstruction>> {};

  /**
   * Maps a receiver to a map of keys to value.
   */
  final Map<HInstruction, Map<HInstruction, HInstruction>> keyedValues =
      <HInstruction, Map<HInstruction, HInstruction>> {};

  /**
   * Set of objects that we know don't escape the current function.
   */
  final Setlet<HInstruction> nonEscapingReceivers = new Setlet<HInstruction>();

  MemorySet(this.compiler);

  /**
   * Returns whether [first] and [second] always alias to the same object.
   */
  bool mustAlias(HInstruction first, HInstruction second) {
    return first == second;
  }

  /**
   * Returns whether [first] and [second] may alias to the same object.
   */
  bool mayAlias(HInstruction first, HInstruction second) {
    if (mustAlias(first, second)) return true;
    if (isConcrete(first) && isConcrete(second)) return false;
    if (nonEscapingReceivers.contains(first)) return false;
    if (nonEscapingReceivers.contains(second)) return false;
    // Typed arrays of different types might have a shared buffer.
    if (couldBeTypedArray(first) && couldBeTypedArray(second)) return true;
    TypeMask intersection = first.instructionType.intersection(
        second.instructionType, compiler.world);
    if (intersection.isEmpty) return false;
    return true;
  }

  bool isFinal(Element element) {
    return compiler.world.fieldNeverChanges(element);
  }

  bool isConcrete(HInstruction instruction) {
    return instruction is HForeignNew
        || instruction is HConstant
        || instruction is HLiteralList;
  }

  bool couldBeTypedArray(HInstruction receiver) {
    JavaScriptBackend backend = compiler.backend;
    return backend.couldBeTypedArray(receiver.instructionType);
  }

  /**
   * Returns whether [receiver] escapes the current function.
   */
  bool escapes(HInstruction receiver) {
    return !nonEscapingReceivers.contains(receiver);
  }

  void registerAllocation(HInstruction instruction) {
    nonEscapingReceivers.add(instruction);
  }

  /**
   * Sets `receiver.element` to contain [value]. Kills all potential
   * places that may be affected by this update.
   */
  void registerFieldValueUpdate(Element element,
                                HInstruction receiver,
                                HInstruction value) {
    if (element.isNative) return; // TODO(14955): Remove this restriction?
    // [value] is being set in some place in memory, we remove it from
    // the non-escaping set.
    nonEscapingReceivers.remove(value);
    Map<HInstruction, HInstruction> map = fieldValues.putIfAbsent(
        element, () => <HInstruction, HInstruction> {});
    map.forEach((key, value) {
      if (mayAlias(receiver, key)) map[key] = null;
    });
    map[receiver] = value;
  }

  /**
   * Registers that `receiver.element` is now [value].
   */
  void registerFieldValue(Element element,
                          HInstruction receiver,
                          HInstruction value) {
    if (element.isNative) return; // TODO(14955): Remove this restriction?
    Map<HInstruction, HInstruction> map = fieldValues.putIfAbsent(
        element, () => <HInstruction, HInstruction> {});
    map[receiver] = value;
  }

  /**
   * Returns the value stored in `receiver.element`. Returns null if
   * we don't know.
   */
  HInstruction lookupFieldValue(Element element, HInstruction receiver) {
    Map<HInstruction, HInstruction> map = fieldValues[element];
    return (map == null) ? null : map[receiver];
  }

  /**
   * Kill all places that may be affected by this [instruction]. Also
   * update the set of non-escaping objects in case [instruction] has
   * non-escaping objects in its inputs.
   */
  void killAffectedBy(HInstruction instruction) {
    // Even if [instruction] does not have side effects, it may use
    // non-escaping objects and store them in a new object, which
    // make these objects escaping.
    // TODO(ngeoffray): We need a new side effect flag to know whether
    // an instruction allocates an object.
    instruction.inputs.forEach((input) {
      nonEscapingReceivers.remove(input);
    });

    if (instruction.sideEffects.changesInstanceProperty()
        || instruction.sideEffects.changesStaticProperty()) {
      fieldValues.forEach((element, map) {
        if (isFinal(element)) return;
        map.forEach((receiver, value) {
          if (escapes(receiver)) {
            map[receiver] = null;
          }
        });
      });
    }

    if (instruction.sideEffects.changesIndex()) {
      keyedValues.forEach((receiver, map) {
        if (escapes(receiver)) {
          map.forEach((index, value) {
            map[index] = null;
          });
        }
      });
    }
  }

  /**
   * Returns the value stored in `receiver[index]`. Returns null if
   * we don't know.
   */
  HInstruction lookupKeyedValue(HInstruction receiver, HInstruction index) {
    Map<HInstruction, HInstruction> map = keyedValues[receiver];
    return (map == null) ? null : map[index];
  }

  /**
   * Registers that `receiver[index]` is now [value].
   */
  void registerKeyedValue(HInstruction receiver,
                          HInstruction index,
                          HInstruction value) {
    Map<HInstruction, HInstruction> map = keyedValues.putIfAbsent(
        receiver, () => <HInstruction, HInstruction> {});
    map[index] = value;
  }

  /**
   * Sets `receiver[index]` to contain [value]. Kills all potential
   * places that may be affected by this update.
   */
  void registerKeyedValueUpdate(HInstruction receiver,
                                HInstruction index,
                                HInstruction value) {
    nonEscapingReceivers.remove(value);
    keyedValues.forEach((key, values) {
      if (mayAlias(receiver, key)) {
        // Typed arrays that are views of the same buffer may have different
        // offsets or element sizes, unless they are the same typed array.
        bool weakIndex = couldBeTypedArray(key) && !mustAlias(receiver, key);
        values.forEach((otherIndex, otherValue) {
          if (weakIndex || mayAlias(index, otherIndex)) {
            values[otherIndex] = null;
          }
        });
      }
    });

    // Typed arrays may narrow incoming values.
    if (couldBeTypedArray(receiver)) return;

    Map<HInstruction, HInstruction> map = keyedValues.putIfAbsent(
        receiver, () => <HInstruction, HInstruction> {});
    map[index] = value;
  }

  /**
   * Returns null if either [first] or [second] is null. Otherwise
   * returns [first] if [first] and [second] are equal. Otherwise
   * creates or re-uses a phi in [block] that holds [first] and [second].
   */
  HInstruction findCommonInstruction(HInstruction first,
                                     HInstruction second,
                                     HBasicBlock block,
                                     int predecessorIndex) {
    if (first == null || second == null) return null;
    if (first == second) return first;
    TypeMask phiType = second.instructionType.union(
          first.instructionType, compiler.world);
    if (first is HPhi && first.block == block) {
      HPhi phi = first;
      phi.addInput(second);
      phi.instructionType = phiType;
      return phi;
    } else {
      HPhi phi = new HPhi.noInputs(null, phiType);
      block.addPhi(phi);
      // Previous predecessors had the same input. A phi must have
      // the same number of inputs as its block has predecessors.
      for (int i = 0; i < predecessorIndex; i++) {
        phi.addInput(first);
      }
      phi.addInput(second);
      return phi;
    }
  }

  /**
   * Returns the intersection between [this] and [other].
   */
  MemorySet intersectionFor(MemorySet other,
                            HBasicBlock block,
                            int predecessorIndex) {
    MemorySet result = new MemorySet(compiler);
    if (other == null) return result;

    fieldValues.forEach((element, values) {
      var otherValues = other.fieldValues[element];
      if (otherValues == null) return;
      values.forEach((receiver, value) {
        HInstruction instruction = findCommonInstruction(
            value, otherValues[receiver], block, predecessorIndex);
        if (instruction != null) {
          result.registerFieldValue(element, receiver, instruction);
        }
      });
    });

    keyedValues.forEach((receiver, values) {
      var otherValues = other.keyedValues[receiver];
      if (otherValues == null) return;
      values.forEach((index, value) {
        HInstruction instruction = findCommonInstruction(
            value, otherValues[index], block, predecessorIndex);
        if (instruction != null) {
          result.registerKeyedValue(receiver, index, instruction);
        }
      });
    });

    nonEscapingReceivers.forEach((receiver) {
      if (other.nonEscapingReceivers.contains(receiver)) {
        result.nonEscapingReceivers.add(receiver);
      }
    });
    return result;
  }

  /**
   * Returns a copy of [this].
   */
  MemorySet clone() {
    MemorySet result = new MemorySet(compiler);

    fieldValues.forEach((element, values) {
      result.fieldValues[element] =
          new Map<HInstruction, HInstruction>.from(values);
    });

    keyedValues.forEach((receiver, values) {
      result.keyedValues[receiver] =
          new Map<HInstruction, HInstruction>.from(values);
    });

    result.nonEscapingReceivers.addAll(nonEscapingReceivers);
    return result;
  }
}

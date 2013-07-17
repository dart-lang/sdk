// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of simple_types_inferrer;

TypeMask narrowType(TypeMask type,
                    DartType annotation,
                    Compiler compiler,
                    {bool isNullable: true}) {
  if (annotation.isDynamic) return type;
  if (annotation.isMalformed) return type;
  if (annotation.isVoid) return compiler.typesTask.nullType;
  if (annotation.element == compiler.objectClass) return type;
  TypeMask otherType;
  if (annotation.kind == TypeKind.TYPEDEF
      || annotation.kind == TypeKind.FUNCTION) {
    otherType = compiler.typesTask.functionType;
  } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
    return type;
  } else {
    assert(annotation.kind == TypeKind.INTERFACE);
    otherType = new TypeMask.nonNullSubtype(annotation);
  }
  if (isNullable) otherType = otherType.nullable();
  if (type == null) return otherType;
  return type.intersection(otherType, compiler);
}

/**
 * Returns the least upper bound between [firstType] and
 * [secondType].
 */
TypeMask computeLUB(TypeMask firstType,
                    TypeMask secondType,
                    Compiler compiler) {
  TypeMask dynamicType = compiler.typesTask.dynamicType;
  if (firstType == null) {
    return secondType;
  } else if (secondType == dynamicType) {
    return secondType;
  } else if (firstType == dynamicType) {
    return firstType;
  } else if (firstType == secondType) {
    return firstType;
  } else {
    TypeMask union = firstType.union(secondType, compiler);
    // TODO(kasperl): If the union isn't nullable it seems wasteful
    // to use dynamic. Fix that.
    return union.containsAll(compiler) ? dynamicType : union;
  }
}

/**
 * Placeholder for inferred types of local variables.
 */
class LocalsHandler {
  final Compiler compiler;
  final TypesInferrer inferrer;
  final Map<Element, TypeMask> locals;
  final Map<Element, Element> capturedAndBoxed;
  final Map<Element, TypeMask> fieldsInitializedInConstructor;
  final bool inTryBlock;
  bool isThisExposed;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  LocalsHandler(this.inferrer, this.compiler)
      : locals = new Map<Element, TypeMask>(),
        capturedAndBoxed = new Map<Element, Element>(),
        fieldsInitializedInConstructor = new Map<Element, TypeMask>(),
        inTryBlock = false,
        isThisExposed = true;
  LocalsHandler.from(LocalsHandler other, {bool inTryBlock: false})
      : locals = new Map<Element, TypeMask>.from(other.locals),
        capturedAndBoxed = new Map<Element, Element>.from(
            other.capturedAndBoxed),
        fieldsInitializedInConstructor = new Map<Element, TypeMask>.from(
            other.fieldsInitializedInConstructor),
        inTryBlock = other.inTryBlock || inTryBlock,
        inferrer = other.inferrer,
        compiler = other.compiler,
        isThisExposed = other.isThisExposed;

  TypeMask use(Element local) {
    if (capturedAndBoxed.containsKey(local)) {
      return inferrer.getTypeOfElement(capturedAndBoxed[local]);
    }
    return locals[local];
  }

  void update(Element local, TypeMask type) {
    assert(type != null);
    if (compiler.trustTypeAnnotations || compiler.enableTypeAssertions) {
      type = narrowType(type, local.computeType(compiler), compiler);
    }
    if (capturedAndBoxed.containsKey(local) || inTryBlock) {
      // If a local is captured and boxed, or is set in a try block,
      // we compute the LUB of its assignments.
      //
      // We don't know if an assignment in a try block
      // will be executed, so all assigments in that block are
      // potential types after we have left it.
      type = computeLUB(locals[local], type, compiler);
    }
    locals[local] = type;
  }

  void setCapturedAndBoxed(Element local, Element field) {
    capturedAndBoxed[local] = field;
  }

  /**
   * Merge handlers [first] and [second] into [:this:] and returns
   * whether the merge changed one of the variables types in [first].
   */
  bool merge(LocalsHandler other, {bool discardIfAborts: true}) {
    bool changed = false;
    List<Element> toRemove = <Element>[];
    // Iterating over a map and just updating its entries is OK.
    locals.forEach((Element local, TypeMask oldType) {
      TypeMask otherType = other.locals[local];
      bool isCaptured = capturedAndBoxed.containsKey(local);
      if (otherType == null) {
        if (!isCaptured) {
          // If [local] is not in the other map and is not captured
          // and boxed, we know it is not a
          // local we want to keep. For example, in an if/else, we don't
          // want to keep variables declared in the if or in the else
          // branch at the merge point.
          toRemove.add(local);
        }
        return;
      }
      if (!isCaptured && aborts && discardIfAborts) {
        locals[local] = otherType;
      } else if (!isCaptured && other.aborts && discardIfAborts) {
        // Don't do anything.
      } else {
        TypeMask type = computeLUB(oldType, otherType, compiler);
        if (type != oldType) changed = true;
        locals[local] = type;
      }
    });

    // Remove locals that will not be used anymore.
    toRemove.forEach((Element element) {
      locals.remove(element);
    });

    // Update the locals that are captured and boxed. We
    // unconditionally add them to [this] because we register the type
    // of boxed variables after analyzing all closures.
    other.capturedAndBoxed.forEach((Element local, Element field) {
      capturedAndBoxed[local] =  field;
      // If [element] is not in our [locals], we need to update it.
      // Otherwise, we have already computed the LUB of it.
      if (locals[local] == null) {
        locals[local] = other.locals[local];
      }
    });

    // Merge instance fields initialized in both handlers. This is
    // only relevant for generative constructors.
    toRemove = <Element>[];
    // Iterate over the map in [:this:]. The map in [other] may
    // contain different fields, but if this map does not contain it,
    // then we know the field can be null and we don't need to track
    // it.
    fieldsInitializedInConstructor.forEach((Element element, TypeMask type) {
      TypeMask otherType = other.fieldsInitializedInConstructor[element];
      if (otherType == null) {
        toRemove.add(element);
      } else {
        fieldsInitializedInConstructor[element] =
            computeLUB(type, otherType, compiler);
      }
    });
    // Remove fields that were not initialized in [other].
    toRemove.forEach((Element element) {
      fieldsInitializedInConstructor.remove(element);
    });
    isThisExposed = isThisExposed || other.isThisExposed;
    seenReturnOrThrow = seenReturnOrThrow && other.seenReturnOrThrow;
    seenBreakOrContinue = seenBreakOrContinue && other.seenBreakOrContinue;

    return changed;
  }

  void updateField(Element element, TypeMask type) {
    if (isThisExposed) return;
    fieldsInitializedInConstructor[element] = type;
  }
}

abstract class InferrerVisitor extends ResolvedVisitor<TypeMask> {
  final Element analyzedElement;
  // Subclasses know more about this field. Typing it dynamic to avoid
  // warnings.
  final /* TypesInferrer */ inferrer;
  final Compiler compiler;
  final Map<TargetElement, List<LocalsHandler>> breaksFor =
      new Map<TargetElement, List<LocalsHandler>>();
  final Map<TargetElement, List<LocalsHandler>> continuesFor =
      new Map<TargetElement, List<LocalsHandler>>();
  LocalsHandler locals;

  bool accumulateIsChecks = false;
  bool conditionIsSimple = false;
  List<Send> isChecks;
  int loopLevel = 0;

  bool get inLoop => loopLevel > 0;
  bool get isThisExposed => locals.isThisExposed;
  void set isThisExposed(value) { locals.isThisExposed = value; }

  InferrerVisitor(Element analyzedElement,
                  this.inferrer,
                  Compiler compiler,
                  [LocalsHandler handler])
    : this.compiler = compiler,
      this.analyzedElement = analyzedElement,
      super(compiler.enqueuer.resolution.getCachedElements(analyzedElement)) {
    locals = (handler == null)
        ? new LocalsHandler(inferrer, compiler)
        : handler;
  }

  TypeMask visitSendSet(SendSet node);

  TypeMask visitSuperSend(Send node);

  TypeMask visitStaticSend(Send node);

  TypeMask visitGetterSend(Send node);

  TypeMask visitClosureSend(Send node);

  TypeMask visitDynamicSend(Send node);

  TypeMask visitForIn(ForIn node);

  TypeMask visitReturn(Return node);

  TypeMask visitNode(Node node) {
    node.visitChildren(this);
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitNewExpression(NewExpression node) {
    return node.send.accept(this);
  }

  TypeMask visit(Node node) {
    return node == null ? compiler.typesTask.dynamicType : node.accept(this);
  }

  TypeMask visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    return compiler.typesTask.functionType;
  }

  TypeMask visitFunctionDeclaration(FunctionDeclaration node) {
    locals.update(elements[node], compiler.typesTask.functionType);
    return visit(node.function);
  }

  TypeMask visitLiteralString(LiteralString node) {
    return compiler.typesTask.stringType;
  }

  TypeMask visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return compiler.typesTask.stringType;
  }

  TypeMask visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
    return compiler.typesTask.stringType;
  }

  TypeMask visitLiteralBool(LiteralBool node) {
    return compiler.typesTask.boolType;
  }

  TypeMask visitLiteralDouble(LiteralDouble node) {
    return compiler.typesTask.doubleType;
  }

  TypeMask visitLiteralInt(LiteralInt node) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    Constant constant = constantSystem.createInt(node.value);
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return constantSystem.isDouble(constant)
        ? compiler.typesTask.doubleType
        : compiler.typesTask.intType;
  }

  TypeMask visitLiteralList(LiteralList node) {
    node.visitChildren(this);
    return node.isConst()
        ? compiler.typesTask.constListType
        : compiler.typesTask.growableListType;
  }

  TypeMask visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
    return node.isConst()
        ? compiler.typesTask.constMapType
        : compiler.typesTask.mapType;
  }

  TypeMask visitLiteralNull(LiteralNull node) {
    return compiler.typesTask.nullType;
  }

  TypeMask visitTypeReferenceSend(Send node) {
    return compiler.typesTask.typeType;
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  Element get outermostElement {
    return
        analyzedElement.getOutermostEnclosingMemberOrTopLevel().implementation;
  }

  TypeMask _thisType;
  TypeMask get thisType {
    if (_thisType != null) return _thisType;
    ClassElement cls = outermostElement.getEnclosingClass();
    if (compiler.world.isUsedAsMixin(cls)) {
      return _thisType = new TypeMask.nonNullSubtype(cls.rawType);
    } else if (compiler.world.hasAnySubclass(cls)) {
      return _thisType = new TypeMask.nonNullSubclass(cls.rawType);
    } else {
      return _thisType = new TypeMask.nonNullExact(cls.rawType);
    }
  }

  TypeMask _superType;
  TypeMask get superType {
    if (_superType != null) return _superType;
    return _superType = new TypeMask.nonNullExact(
        outermostElement.getEnclosingClass().superclass.rawType);
  }

  TypeMask visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return superType;
    }
    return compiler.typesTask.dynamicType;
  }

  void potentiallyAddIsCheck(Send node) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[node.receiver])) return;
    isChecks.add(node);
  }

  void updateIsChecks(List<Node> tests, {bool usePositive}) {
    if (tests == null) return;
    for (Send node in tests) {
      if (node.isIsNotCheck) {
        if (usePositive) continue;
      } else {
        if (!usePositive) continue;
      }
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      Element element = elements[node.receiver];
      TypeMask existing = locals.use(element);
      TypeMask newType = narrowType(
          existing, type, compiler, isNullable: false);
      locals.update(element, newType);
    }
  }

  TypeMask visitOperatorSend(Send node) {
    Operator op = node.selector;
    if (const SourceString("[]") == op.source) {
      return visitDynamicSend(node);
    } else if (const SourceString("&&") == op.source) {
      conditionIsSimple = false;
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = true;
      if (isChecks == null) isChecks = <Send>[];
      visit(node.receiver);
      accumulateIsChecks = oldAccumulateIsChecks;
      if (!accumulateIsChecks) isChecks = null;
      LocalsHandler saved = new LocalsHandler.from(locals);
      updateIsChecks(isChecks, usePositive: true);
      visit(node.arguments.head);
      locals.merge(saved);
      return compiler.typesTask.boolType;
    } else if (const SourceString("||") == op.source) {
      conditionIsSimple = false;
      visit(node.receiver);
      LocalsHandler saved = new LocalsHandler.from(locals);
      updateIsChecks(isChecks, usePositive: false);
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      visit(node.arguments.head);
      accumulateIsChecks = oldAccumulateIsChecks;
      locals.merge(saved);
      return compiler.typesTask.boolType;
    } else if (const SourceString("!") == op.source) {
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      node.visitChildren(this);
      accumulateIsChecks = oldAccumulateIsChecks;
      return compiler.typesTask.boolType;
    } else if (const SourceString("is") == op.source) {
      potentiallyAddIsCheck(node);
      node.visitChildren(this);
      return compiler.typesTask.boolType;
    } else if (const SourceString("as") == op.source) {
      TypeMask receiverType = visit(node.receiver);
      DartType type = elements.getType(node.arguments.head);
      return narrowType(receiverType, type, compiler);
    } else if (node.argumentsNode is Prefix) {
      // Unary operator.
      return visitDynamicSend(node);
    } else if (const SourceString('===') == op.source
               || const SourceString('!==') == op.source) {
      node.visitChildren(this);
      return compiler.typesTask.boolType;
    } else {
      // Binary operator.
      return visitDynamicSend(node);
    }
  }

  // Because some nodes just visit their children, we may end up
  // visiting a type annotation, that may contain a send in case of a
  // prefixed type. Therefore we explicitly visit the type annotation
  // to avoid confusing the [ResolvedVisitor].
  visitTypeAnnotation(TypeAnnotation node) {}

  TypeMask visitConditional(Conditional node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = new LocalsHandler.from(locals);
    updateIsChecks(tests, usePositive: true);
    TypeMask firstType = visit(node.thenExpression);
    LocalsHandler thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    TypeMask secondType = visit(node.elseExpression);
    locals.merge(thenLocals);
    TypeMask type = computeLUB(firstType, secondType, compiler);
    return type;
  }

  TypeMask visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      if (definition is Identifier) {
        locals.update(elements[definition], compiler.typesTask.nullType);
      } else {
        assert(definition.asSendSet() != null);
        visit(definition);
      }
    }
    return compiler.typesTask.dynamicType;
  }

  bool handleCondition(Node node, List<Send> tests) {
    bool oldConditionIsSimple = conditionIsSimple;
    bool oldAccumulateIsChecks = accumulateIsChecks;
    List<Send> oldIsChecks = isChecks;
    accumulateIsChecks = true;
    conditionIsSimple = true;
    isChecks = tests;
    visit(node);
    bool simpleCondition = conditionIsSimple;
    accumulateIsChecks = oldAccumulateIsChecks;
    isChecks = oldIsChecks;
    conditionIsSimple = oldConditionIsSimple;
    return simpleCondition;
  }

  TypeMask visitIf(If node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = new LocalsHandler.from(locals);
    updateIsChecks(tests, usePositive: true);
    visit(node.thenPart);
    LocalsHandler thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.elsePart);
    locals.merge(thenLocals);
    return compiler.typesTask.dynamicType;
  }

  void setupBreaksAndContinues(TargetElement element) {
    if (element == null) return;
    if (element.isContinueTarget) continuesFor[element] = <LocalsHandler>[];
    if (element.isBreakTarget) breaksFor[element] = <LocalsHandler>[];
  }

  void clearBreaksAndContinues(TargetElement element) {
    continuesFor.remove(element);
    breaksFor.remove(element);
  }

  void mergeBreaks(TargetElement element) {
    if (element == null) return;
    if (!element.isBreakTarget) return;
    for (LocalsHandler handler in breaksFor[element]) {
      locals.merge(handler, discardIfAborts: false);
    }
  }

  bool mergeContinues(TargetElement element) {
    if (element == null) return false;
    if (!element.isContinueTarget) return false;
    bool changed = false;
    for (LocalsHandler handler in continuesFor[element]) {
      changed = locals.merge(handler, discardIfAborts: false) || changed;
    }
    return changed;
  }

  TypeMask handleLoop(Node node, void logic()) {
    loopLevel++;
    bool changed = false;
    TargetElement target = elements[node];
    setupBreaksAndContinues(target);
    do {
      LocalsHandler saved = new LocalsHandler.from(locals);
      logic();
      changed = saved.merge(locals);
      locals = saved;
      changed = mergeContinues(target) || changed;
    } while (changed);
    loopLevel--;
    mergeBreaks(target);
    clearBreaksAndContinues(target);
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitWhile(While node) {
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
    });
  }

  TypeMask visitDoWhile(DoWhile node) {
    return handleLoop(node, () {
      visit(node.body);
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
    });
  }

  TypeMask visitFor(For node) {
    visit(node.initializer);
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
      visit(node.update);
    });
  }

  TypeMask visitTryStatement(TryStatement node) {
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, inTryBlock: true);
    visit(node.tryBlock);
    saved.merge(locals);
    locals = saved;
    for (Node catchBlock in node.catchBlocks) {
      saved = new LocalsHandler.from(locals);
      visit(catchBlock);
      saved.merge(locals);
      locals = saved;
    }
    visit(node.finallyBlock);
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitThrow(Throw node) {
    node.visitChildren(this);
    locals.seenReturnOrThrow = true;
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitCatchBlock(CatchBlock node) {
    Node exception = node.exception;
    if (exception != null) {
      DartType type = elements.getType(node.type);
      TypeMask mask = type == null
          ? compiler.typesTask.dynamicType
          : new TypeMask.nonNullSubtype(type.asRaw());
      locals.update(elements[exception], mask);
    }
    Node trace = node.trace;
    if (trace != null) {
      locals.update(elements[trace], compiler.typesTask.dynamicType);
    }
    visit(node.block);
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitParenthesizedExpression(ParenthesizedExpression node) {
    return visit(node.expression);
  }

  TypeMask visitBlock(Block node) {
    if (node.statements != null) {
      for (Node statement in node.statements) {
        visit(statement);
        if (locals.aborts) break;
      }
    }
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop
        || body is SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
      return compiler.typesTask.dynamicType;
    }

    TargetElement targetElement = elements[body];
    setupBreaksAndContinues(targetElement);
    visit(body);
    mergeBreaks(targetElement);
    clearBreaksAndContinues(targetElement);
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitBreakStatement(BreakStatement node) {
    TargetElement target = elements[node];
    breaksFor[target].add(locals);
    locals.seenBreakOrContinue = true;
    return compiler.typesTask.dynamicType;
  }

  TypeMask visitContinueStatement(ContinueStatement node) {
    TargetElement target = elements[node];
    continuesFor[target].add(locals);
    locals.seenBreakOrContinue = true;
    return compiler.typesTask.dynamicType;
  }

  void internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }

  TypeMask visitSwitchStatement(SwitchStatement node) {
    visit(node.parenthesizedExpression);

    setupBreaksAndContinues(elements[node]);
    if (Elements.switchStatementHasContinue(node, elements)) {
      void forEachLabeledCase(void action(TargetElement target)) {
        for (SwitchCase switchCase in node.cases) {
          for (Node labelOrCase in switchCase.labelsAndCases) {
            if (labelOrCase.asLabel() == null) continue;
            LabelElement labelElement = elements[labelOrCase];
            if (labelElement != null) {
              action(labelElement.target);
            }
          }
        }
      }

      forEachLabeledCase((TargetElement target) {
        setupBreaksAndContinues(target);
      });

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      do {
        changed = false;
        for (Node switchCase in node.cases) {
          LocalsHandler saved = new LocalsHandler.from(locals);
          visit(switchCase);
          changed = saved.merge(locals, discardIfAborts: false) || changed;
          locals = saved;
        }
      } while (changed);

      forEachLabeledCase((TargetElement target) {
        clearBreaksAndContinues(target);
      });
    } else {
      LocalsHandler saved = new LocalsHandler.from(locals);
      // If there is a default case, the current values of the local
      // variable might be overwritten, so we don't need the current
      // [locals] for the join block.
      LocalsHandler result = Elements.switchStatementHasDefault(node)
          ? null
          : new LocalsHandler.from(locals);

      for (Node switchCase in node.cases) {
        locals = new LocalsHandler.from(saved);
        visit(switchCase);
        if (result == null) {
          result = locals;
        } else {
          result.merge(locals, discardIfAborts: false);
        }
      }
      locals = result;
    }
    clearBreaksAndContinues(elements[node]);
    // In case there is a default in the switch we discard the
    // incoming localsHandler, because the types it holds do not need
    // to be merged after the switch statement. This means that, if all
    // cases, including the default, break or continue, the [result]
    // handler may think it just aborts the current block. Therefore
    // we set the current locals to not have any break or continue, so
    // that the [visitBlock] method does not assume the code after the
    // switch is dead code.
    locals.seenBreakOrContinue = false;
    return compiler.typesTask.dynamicType;
  }
}

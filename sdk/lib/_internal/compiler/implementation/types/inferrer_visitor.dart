// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of simple_types_inferrer;

/**
 * The interface [InferrerVisitor] will use when working on types.
 */
abstract class TypeSystem<T> {
  T get dynamicType;
  T get nullType;
  T get intType;
  T get doubleType;
  T get numType;
  T get boolType;
  T get functionType;
  T get listType;
  T get constListType;
  T get fixedListType;
  T get growableListType;
  T get mapType;
  T get constMapType;
  T get stringType;
  T get typeType;

  T nonNullSubtype(DartType type);
  T nonNullSubclass(DartType type);
  T nonNullExact(DartType type);
  T nonNullEmpty();
  T nullable(T type);
  Selector newTypedSelector(T receiver, Selector selector);

  T allocateContainer(T type,
                      Node node,
                      Element enclosing,
                      [T elementType, int length]);

  /**
   * Returns the intersection between [T] and [annotation].
   * [isNullable] indicates whether the annotation implies a null
   * type.
   */
  T narrowType(T type, DartType annotation, {bool isNullable: true});

  /**
   * Returns the least upper bound between [firstType] and
   * [secondType].
   */
  T computeLUB(T firstType, T secondType);
}

/**
 * An implementation of [TypeSystem] for [TypeMask].
 */
class TypeMaskSystem implements TypeSystem<TypeMask> {
  final Compiler compiler;
  TypeMaskSystem(this.compiler);

  TypeMask narrowType(TypeMask type,
                      DartType annotation,
                      {bool isNullable: true}) {
    if (annotation.isDynamic) return type;
    if (annotation.isMalformed) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type == null) return otherType;
    return type.intersection(otherType, compiler);
  }

  TypeMask computeLUB(TypeMask firstType, TypeMask secondType) {
    if (firstType == null) {
      return secondType;
    } else if (secondType == dynamicType || firstType == dynamicType) {
      return dynamicType;
    } else if (firstType == secondType) {
      return firstType;
    } else {
      TypeMask union = firstType.union(secondType, compiler);
      // TODO(kasperl): If the union isn't nullable it seems wasteful
      // to use dynamic. Fix that.
      return union.containsAll(compiler) ? dynamicType : union;
    }
  }

  TypeMask get dynamicType => compiler.typesTask.dynamicType;
  TypeMask get nullType => compiler.typesTask.nullType;
  TypeMask get intType => compiler.typesTask.intType;
  TypeMask get doubleType => compiler.typesTask.doubleType;
  TypeMask get numType => compiler.typesTask.numType;
  TypeMask get boolType => compiler.typesTask.boolType;
  TypeMask get functionType => compiler.typesTask.functionType;
  TypeMask get listType => compiler.typesTask.listType;
  TypeMask get constListType => compiler.typesTask.constListType;
  TypeMask get fixedListType => compiler.typesTask.fixedListType;
  TypeMask get growableListType => compiler.typesTask.growableListType;
  TypeMask get mapType => compiler.typesTask.mapType;
  TypeMask get constMapType => compiler.typesTask.constMapType;
  TypeMask get stringType => compiler.typesTask.stringType;
  TypeMask get typeType => compiler.typesTask.typeType;

  TypeMask nonNullSubtype(DartType type) => new TypeMask.nonNullSubtype(type);
  TypeMask nonNullSubclass(DartType type) => new TypeMask.nonNullSubclass(type);
  TypeMask nonNullExact(DartType type) => new TypeMask.nonNullExact(type);
  TypeMask nonNullEmpty() => new TypeMask.nonNullEmpty();

  TypeMask nullable(TypeMask type) {
    return type.nullable();
  }

  TypeMask allocateContainer(TypeMask type,
                             Node node,
                             Element enclosing,
                             [TypeMask elementType, int length]) {
    ContainerTypeMask mask = new ContainerTypeMask(type, node, enclosing);
    mask.elementType = elementType;
    mask.length = length;
    return mask;
  }

  Selector newTypedSelector(TypeMask receiver, Selector selector) {
    return new TypedSelector(receiver, selector);
  }
}

/**
 * A variable scope holds types for variables. It has a link to a
 * parent scope, but never changes the types in that parent. Instead,
 * updates to locals of a parent scope are put in the current scope.
 * The inferrer makes sure updates get merged into the parent scope,
 * once the control flow block has been visited.
 */
class VariableScope<T> {
  Map<Element, T> variables;

  /// The parent of this scope. Null for the root scope.
  final VariableScope<T> parent;

  /// The block level of this scope. Starts at 0 for the root scope.
  final int blockLevel;

  VariableScope([parent])
      : this.variables = null,
        this.parent = parent,
        this.blockLevel = parent == null ? 0 : parent.blockLevel + 1;

  VariableScope.deepCopyOf(VariableScope<T> other)
      : variables = other.variables == null
            ? null
            : new Map<Element, T>.from(other.variables),
        blockLevel = other.blockLevel,
        parent = other.parent == null
            ? null
            : new VariableScope<T>.deepCopyOf(other.parent);

  T operator [](Element variable) {
    T result;
    if (variables == null || (result = variables[variable]) == null) {
      return parent == null ? null : parent[variable];
    }
    return result;
  }

  void operator []=(Element variable, T mask) {
    assert(mask != null);
    if (variables == null) {
      variables = new Map<Element, T>();
    }
    variables[variable] = mask;
  }

  void forEachOwnLocal(void f(Element element, T type)) {
    if (variables == null) return;
    variables.forEach(f);
  }

  void remove(Element element) {
    variables.remove(element);
  }

  String toString() {
    String rest = parent == null ? "null" : parent.toString();
    return '$blockLevel: $variables $rest';
  }
}

class FieldInitializationScope<T> {
  final TypeSystem<T> types;
  final Map<Element, T> fields;
  bool isThisExposed;

  FieldInitializationScope(this.types)
      : fields = new Map<Element, T>(),
        isThisExposed = false;

  FieldInitializationScope.internalFrom(FieldInitializationScope<T> other)
      : fields = new Map<Element, T>.from(other.fields),
        types = other.types,
        isThisExposed = other.isThisExposed;

  factory FieldInitializationScope.from(FieldInitializationScope other) {
    if (other == null) return null;
    return new FieldInitializationScope<T>.internalFrom(other);
  }

  void updateField(Element field, T type) {
    if (isThisExposed) return;
    fields[field] = type;
  }

  void merge(FieldInitializationScope other) {
    isThisExposed = isThisExposed || other.isThisExposed;
    List<Element> toRemove = <Element>[];
    // Iterate over the map in [:this:]. The map in [other] may
    // contain different fields, but if this map does not contain it,
    // then we know the field can be null and we don't need to track
    // it.
    fields.forEach((Element field, T type) {
      T otherType = other.fields[field];
      if (otherType == null) {
        toRemove.add(field);
      } else {
        fields[field] = types.computeLUB(type, otherType);
      }
    });
    // Remove fields that were not initialized in [other].
    toRemove.forEach((Element element) { fields.remove(element); });
  }
}

/**
 * Placeholder for inferred types of local variables.
 */
class LocalsHandler<T> {
  final Compiler compiler;
  final TypeSystem<T> types;
  final InferrerEngine<T> inferrer;
  final VariableScope<T> locals;
  final Map<Element, Element> capturedAndBoxed;
  final FieldInitializationScope<T> fieldScope;
  final bool inTryBlock;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  LocalsHandler(this.inferrer, this.types, this.compiler, [this.fieldScope])
      : locals = new VariableScope<T>(),
        capturedAndBoxed = new Map<Element, Element>(),
        inTryBlock = false;

  LocalsHandler.from(LocalsHandler<T> other, {bool inTryBlock})
      : locals = new VariableScope<T>(other.locals),
        fieldScope = new FieldInitializationScope<T>.from(other.fieldScope),
        capturedAndBoxed = other.capturedAndBoxed,
        inTryBlock = inTryBlock == null ? other.inTryBlock : inTryBlock,
        types = other.types,
        inferrer = other.inferrer,
        compiler = other.compiler;

  LocalsHandler.deepCopyOf(LocalsHandler<T> other)
      : locals = new VariableScope<T>.deepCopyOf(other.locals),
        fieldScope = new FieldInitializationScope<T>.from(other.fieldScope),
        capturedAndBoxed = other.capturedAndBoxed,
        inTryBlock = other.inTryBlock,
        types = other.types,
        inferrer = other.inferrer,
        compiler = other.compiler;

  T use(Element local) {
    return capturedAndBoxed.containsKey(local)
        ? inferrer.typeOfElement(capturedAndBoxed[local])
        : locals[local];
  }

  void update(Element local, T type, Node node) {
    assert(type != null);
    if (compiler.trustTypeAnnotations || compiler.enableTypeAssertions) {
      type = types.narrowType(type, local.computeType(compiler));
    }
    if (capturedAndBoxed.containsKey(local)) {
      inferrer.recordTypeOfNonFinalField(
          node, capturedAndBoxed[local], type, null);
    } else if (inTryBlock) {
      // We don't know if an assignment in a try block
      // will be executed, so all assigments in that block are
      // potential types after we have left it.
      locals[local] = types.computeLUB(locals[local], type);
    } else {
      locals[local] = type;
    }
  }

  void setCapturedAndBoxed(Element local, Element field) {
    capturedAndBoxed[local] = field;
  }

  /**
   * Merge handlers [first] and [second] into [:this:] and returns
   * whether the merge changed one of the variables types in [first].
   */
  bool merge(LocalsHandler<T> other, {bool discardIfAborts: true}) {
    VariableScope<T> currentOther = other.locals;
    assert(currentOther != locals);
    bool changed = false;
    // Iterate over all updates in the other handler until we reach
    // the block level of this handler. We know that [VariableScope]s
    // that are lower in block level, are the same.
    do {
      currentOther.forEachOwnLocal((Element local, T otherType) {
        T myType = locals[local];
        if (myType == null) return;
        if (capturedAndBoxed.containsKey(local)) return;
        if (aborts && discardIfAborts) {
          locals[local] = otherType;
        } else if (other.aborts && discardIfAborts) {
          // Don't do anything.
        } else {
          T type = types.computeLUB(myType, otherType);
          if (type != myType) {
            changed = true;
          }
          locals[local] = type;
        }
      });
      currentOther = currentOther.parent;
    } while (currentOther != null
             && currentOther.blockLevel >= locals.blockLevel);

    List<Element> toRemove = <Element>[];
    locals.forEachOwnLocal((Element local, _) {
      if (other.locals[local] == null) {
        // If [local] is not in the other map we know it is not a
        // local we want to keep. For example, in an if/else, we don't
        // want to keep variables declared in the if or in the else
        // branch at the merge point.
        toRemove.add(local);
      }
    });

    // Remove locals that will not be used anymore.
    toRemove.forEach((Element element) {
      locals.remove(element);
    });

    if (fieldScope != null) {
      fieldScope.merge(other.fieldScope);
    }

    seenReturnOrThrow = seenReturnOrThrow && other.seenReturnOrThrow;
    seenBreakOrContinue = seenBreakOrContinue && other.seenBreakOrContinue;

    return changed;
  }

  void updateField(Element element, T type) {
    fieldScope.updateField(element, type);
  }
}

abstract class InferrerVisitor<T> extends ResolvedVisitor<T> {
  final Element analyzedElement;
  final TypeSystem<T> types;
  final InferrerEngine<T> inferrer;
  final Compiler compiler;
  final Map<TargetElement, List<LocalsHandler<T>>> breaksFor =
      new Map<TargetElement, List<LocalsHandler<T>>>();
  final Map<TargetElement, List<LocalsHandler>> continuesFor =
      new Map<TargetElement, List<LocalsHandler<T>>>();
  LocalsHandler<T> locals;

  bool accumulateIsChecks = false;
  bool conditionIsSimple = false;
  List<Send> isChecks;
  int loopLevel = 0;

  bool get inLoop => loopLevel > 0;
  bool get isThisExposed {
    return analyzedElement.isGenerativeConstructor()
        ? locals.fieldScope.isThisExposed
        : true;
  }
  void set isThisExposed(value) {
    if (analyzedElement.isGenerativeConstructor()) {
      locals.fieldScope.isThisExposed = value;
    }
  }

  InferrerVisitor(Element analyzedElement,
                  this.inferrer,
                  this.types,
                  Compiler compiler,
                  [LocalsHandler<T> handler])
    : this.compiler = compiler,
      this.analyzedElement = analyzedElement,
      this.locals = handler,
      super(compiler.enqueuer.resolution.getCachedElements(analyzedElement)) {
    if (handler != null) return;
    FieldInitializationScope<T> fieldScope =
        analyzedElement.isGenerativeConstructor()
            ? new FieldInitializationScope<T>(types)
            : null;
    locals = new LocalsHandler<T>(inferrer, types, compiler, fieldScope);
  }

  T visitSendSet(SendSet node);

  T visitSuperSend(Send node);

  T visitStaticSend(Send node);

  T visitGetterSend(Send node);

  T visitClosureSend(Send node);

  T visitDynamicSend(Send node);

  T visitForIn(ForIn node);

  T visitReturn(Return node);

  T visitFunctionExpression(FunctionExpression node);

  T visitNode(Node node) {
    node.visitChildren(this);
  }

  T visitNewExpression(NewExpression node) {
    return node.send.accept(this);
  }

  T visit(Node node) {
    return node == null ? null : node.accept(this);
  }

  T visitFunctionDeclaration(FunctionDeclaration node) {
    locals.update(elements[node], types.functionType, node);
    return visit(node.function);
  }

  T visitLiteralString(LiteralString node) {
    return types.stringType;
  }

  T visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return types.stringType;
  }

  T visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
    return types.stringType;
  }

  T visitLiteralBool(LiteralBool node) {
    return types.boolType;
  }

  T visitLiteralDouble(LiteralDouble node) {
    return types.doubleType;
  }

  T visitLiteralInt(LiteralInt node) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    Constant constant = constantSystem.createInt(node.value);
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return constantSystem.isDouble(constant)
        ? types.doubleType
        : types.intType;
  }

  T visitLiteralList(LiteralList node) {
    node.visitChildren(this);
    return node.isConst() ? types.constListType : types.growableListType;
  }

  T visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
    return node.isConst() ? types.constMapType : types.mapType;
  }

  T visitLiteralNull(LiteralNull node) {
    return types.nullType;
  }

  T visitTypeReferenceSend(Send node) {
    return types.typeType;
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  Element get outermostElement {
    return
        analyzedElement.getOutermostEnclosingMemberOrTopLevel().implementation;
  }

  T _thisType;
  T get thisType {
    if (_thisType != null) return _thisType;
    ClassElement cls = outermostElement.getEnclosingClass();
    if (compiler.world.isUsedAsMixin(cls)) {
      return _thisType = types.nonNullSubtype(cls.rawType);
    } else if (compiler.world.hasAnySubclass(cls)) {
      return _thisType = types.nonNullSubclass(cls.rawType);
    } else {
      return _thisType = types.nonNullExact(cls.rawType);
    }
  }

  T _superType;
  T get superType {
    if (_superType != null) return _superType;
    return _superType = types.nonNullExact(
        outermostElement.getEnclosingClass().superclass.rawType);
  }

  T visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return superType;
    }
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
      T existing = locals.use(element);
      T newType = types.narrowType(existing, type, isNullable: false);
      locals.update(element, newType, node);
    }
  }

  T visitOperatorSend(Send node) {
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
      LocalsHandler<T> saved = locals;
      locals = new LocalsHandler<T>.from(locals);
      updateIsChecks(isChecks, usePositive: true);
      visit(node.arguments.head);
      saved.merge(locals);
      locals = saved;
      return types.boolType;
    } else if (const SourceString("||") == op.source) {
      conditionIsSimple = false;
      visit(node.receiver);
      LocalsHandler<T> saved = locals;
      locals = new LocalsHandler<T>.from(locals);
      updateIsChecks(isChecks, usePositive: false);
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      visit(node.arguments.head);
      accumulateIsChecks = oldAccumulateIsChecks;
      saved.merge(locals);
      locals = saved;
      return types.boolType;
    } else if (const SourceString("!") == op.source) {
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      node.visitChildren(this);
      accumulateIsChecks = oldAccumulateIsChecks;
      return types.boolType;
    } else if (const SourceString("is") == op.source) {
      potentiallyAddIsCheck(node);
      node.visitChildren(this);
      return types.boolType;
    } else if (const SourceString("as") == op.source) {
      T receiverType = visit(node.receiver);
      DartType type = elements.getType(node.arguments.head);
      return types.narrowType(receiverType, type);
    } else if (node.argumentsNode is Prefix) {
      // Unary operator.
      return visitDynamicSend(node);
    } else if (const SourceString('===') == op.source
               || const SourceString('!==') == op.source) {
      node.visitChildren(this);
      return types.boolType;
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

  T visitConditional(Conditional node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler<T> saved = locals;
    locals = new LocalsHandler<T>.from(locals);
    updateIsChecks(tests, usePositive: true);
    T firstType = visit(node.thenExpression);
    LocalsHandler<T> thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    T secondType = visit(node.elseExpression);
    locals.merge(thenLocals);
    T type = types.computeLUB(firstType, secondType);
    return type;
  }

  T visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      if (definition is Identifier) {
        locals.update(elements[definition], types.nullType, node);
      } else {
        assert(definition.asSendSet() != null);
        visit(definition);
      }
    }
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

  T visitIf(If node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler<T> saved = locals;
    locals = new LocalsHandler<T>.from(locals);
    updateIsChecks(tests, usePositive: true);
    visit(node.thenPart);
    LocalsHandler<T> thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.elsePart);
    locals.merge(thenLocals);
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
    for (LocalsHandler<T> handler in breaksFor[element]) {
      locals.merge(handler, discardIfAborts: false);
    }
  }

  bool mergeContinues(TargetElement element) {
    if (element == null) return false;
    if (!element.isContinueTarget) return false;
    bool changed = false;
    for (LocalsHandler<T> handler in continuesFor[element]) {
      changed = locals.merge(handler, discardIfAborts: false) || changed;
    }
    return changed;
  }

  T handleLoop(Node node, void logic()) {
    loopLevel++;
    bool changed = false;
    TargetElement target = elements[node];
    setupBreaksAndContinues(target);
    do {
      LocalsHandler<T> saved = locals;
      locals = new LocalsHandler<T>.from(locals);
      logic();
      changed = saved.merge(locals);
      locals = saved;
      changed = mergeContinues(target) || changed;
    } while (changed);
    loopLevel--;
    mergeBreaks(target);
    clearBreaksAndContinues(target);
  }

  T visitWhile(While node) {
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
    });
  }

  T visitDoWhile(DoWhile node) {
    return handleLoop(node, () {
      visit(node.body);
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
    });
  }

  T visitFor(For node) {
    visit(node.initializer);
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
      visit(node.update);
    });
  }

  T visitTryStatement(TryStatement node) {
    LocalsHandler<T> saved = locals;
    locals = new LocalsHandler<T>.from(locals, inTryBlock: true);
    visit(node.tryBlock);
    saved.merge(locals);
    locals = saved;
    for (Node catchBlock in node.catchBlocks) {
      saved = locals;
      locals = new LocalsHandler<T>.from(locals);
      visit(catchBlock);
      saved.merge(locals);
      locals = saved;
    }
    visit(node.finallyBlock);
  }

  T visitThrow(Throw node) {
    node.visitChildren(this);
    locals.seenReturnOrThrow = true;
    return types.dynamicType;
  }

  T visitCatchBlock(CatchBlock node) {
    Node exception = node.exception;
    if (exception != null) {
      DartType type = elements.getType(node.type);
      T mask = type == null
          ? types.dynamicType
          : types.nonNullSubtype(type.asRaw());
      locals.update(elements[exception], mask, node);
    }
    Node trace = node.trace;
    if (trace != null) {
      locals.update(elements[trace], types.dynamicType, node);
    }
    visit(node.block);
  }

  T visitParenthesizedExpression(ParenthesizedExpression node) {
    return visit(node.expression);
  }

  T visitBlock(Block node) {
    if (node.statements != null) {
      for (Node statement in node.statements) {
        visit(statement);
        if (locals.aborts) break;
      }
    }
  }

  T visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop
        || body is SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
    } else {
      TargetElement targetElement = elements[body];
      setupBreaksAndContinues(targetElement);
      visit(body);
      mergeBreaks(targetElement);
      clearBreaksAndContinues(targetElement);
    }
  }

  T visitBreakStatement(BreakStatement node) {
    TargetElement target = elements[node];
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    breaksFor[target].add(new LocalsHandler<T>.deepCopyOf(locals));
  }

  T visitContinueStatement(ContinueStatement node) {
    TargetElement target = elements[node];
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // continue will change them.
    continuesFor[target].add(new LocalsHandler<T>.deepCopyOf(locals));
  }

  void internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }

  T visitSwitchStatement(SwitchStatement node) {
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
          LocalsHandler<T> saved = locals;
          locals = new LocalsHandler<T>.from(locals);
          visit(switchCase);
          changed = saved.merge(locals, discardIfAborts: false) || changed;
          locals = saved;
        }
      } while (changed);

      forEachLabeledCase((TargetElement target) {
        clearBreaksAndContinues(target);
      });
    } else {
      LocalsHandler<T> saved = locals;
      List<LocalsHandler<T>> localsToMerge = <LocalsHandler>[];

      for (SwitchCase switchCase in node.cases) {
        if (switchCase.isDefaultCase) {
          // If there is a default case, the current values of the local
          // variable might be overwritten, so we don't need the current
          // [locals] for the join block.
          locals = saved;
          visit(switchCase);
        } else {
          locals = new LocalsHandler<T>.from(saved);
          visit(switchCase);
          localsToMerge.add(locals);
        }
      }
      for (LocalsHandler<T> handler in localsToMerge) {
        saved.merge(handler, discardIfAborts: false);
      }
      locals = saved;
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
  }

  T visitCascadeReceiver(CascadeReceiver node) {
    // TODO(ngeoffray): Implement.
    node.visitChildren(this);
    return types.dynamicType;
  }

  T visitCascade(Cascade node) {
    // TODO(ngeoffray): Implement.
    node.visitChildren(this);
    return types.dynamicType;
  }
}

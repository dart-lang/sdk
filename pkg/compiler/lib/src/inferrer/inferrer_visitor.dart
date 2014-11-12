// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inferrer_visitor;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart';
import '../types/types.dart' show TypeMask;
import 'dart:collection' show IterableMixin;

/**
 * The interface [InferrerVisitor] will use when working on types.
 */
abstract class TypeSystem<T> {
  T get dynamicType;
  T get nullType;
  T get intType;
  T get uint31Type;
  T get uint32Type;
  T get positiveIntType;
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

  T stringLiteralType(DartString value);

  T nonNullSubtype(ClassElement type);
  T nonNullSubclass(ClassElement type);
  T nonNullExact(ClassElement type);
  T nonNullEmpty();
  bool isNull(T type);
  Selector newTypedSelector(T receiver, Selector selector);

  T allocateList(T type,
                 Node node,
                 Element enclosing,
                 [T elementType, int length]);

  T allocateMap(T type, Node node, Element element, [List<T> keyType,
                                                     List<T> valueType]);

  T allocateClosure(Node node, Element element);

  /**
   * Returns the least upper bound between [firstType] and
   * [secondType].
   */
  T computeLUB(T firstType, T secondType);

  /**
   * Returns the intersection between [T] and [annotation].
   * [isNullable] indicates whether the annotation implies a null
   * type.
   */
  T narrowType(T type, DartType annotation, {bool isNullable: true});

  /**
   * Returns a new type that unions [firstInput] and [secondInput].
   */
  T allocateDiamondPhi(T firstInput, T secondInput);

  /**
   * Returns a new type for holding the potential types of [element].
   * [inputType] is the first incoming type of the phi.
   */
  T allocatePhi(Node node, Local variable, T inputType);


  /**
   * Returns a new type for holding the potential types of [element].
   * [inputType] is the first incoming type of the phi. [allocateLoopPhi]
   * only differs from [allocatePhi] in that it allows the underlying
   * implementation of [TypeSystem] to differentiate Phi nodes due to loops
   * from other merging uses.
   */
  T allocateLoopPhi(Node node, Local variable, T inputType);

  /**
   * Simplies the phi representing [element] and of the type
   * [phiType]. For example, if this phi has one incoming input, an
   * implementation of this method could just return that incoming
   * input type.
   */
  T simplifyPhi(Node node, Local variable, T phiType);

  /**
   * Adds [newType] as an input of [phiType].
   */
  T addPhiInput(Local variable, T phiType, T newType);

  /**
   * Returns `true` if `selector` should be updated to reflect the new
   * `receiverType`.
   */
  bool selectorNeedsUpdate(T receiverType, Selector selector);

  /**
   * Returns a new receiver type for this [selector] applied to
   * [receiverType].
   */
  T refineReceiver(Selector selector, T receiverType);

  /**
   * Returns the internal inferrer representation for [mask].
   */
  T getConcreteTypeFor(TypeMask mask);
}

/**
 * A variable scope holds types for variables. It has a link to a
 * parent scope, but never changes the types in that parent. Instead,
 * updates to locals of a parent scope are put in the current scope.
 * The inferrer makes sure updates get merged into the parent scope,
 * once the control flow block has been visited.
 */
class VariableScope<T> {
  Map<Local, T> variables;

  /// The parent of this scope. Null for the root scope.
  final VariableScope<T> parent;

  /// The [Node] that created this scope.
  final Node block;

  VariableScope(this.block, [parent])
      : this.variables = null,
        this.parent = parent;

  VariableScope.deepCopyOf(VariableScope<T> other)
      : variables = other.variables == null
            ? null
            : new Map<Local, T>.from(other.variables),
        block = other.block,
        parent = other.parent == null
            ? null
            : new VariableScope<T>.deepCopyOf(other.parent);

  T operator [](Local variable) {
    T result;
    if (variables == null || (result = variables[variable]) == null) {
      return parent == null ? null : parent[variable];
    }
    return result;
  }

  void operator []=(Local variable, T mask) {
    assert(mask != null);
    if (variables == null) {
      variables = new Map<Local, T>();
    }
    variables[variable] = mask;
  }

  void forEachOwnLocal(void f(Local variable, T type)) {
    if (variables == null) return;
    variables.forEach(f);
  }

  void forEachLocalUntilNode(Node node,
                             void f(Local variable, T type),
                             [Setlet<Local> seenLocals]) {
    if (seenLocals == null) seenLocals = new Setlet<Local>();
    if (variables != null) {
      variables.forEach((variable, type) {
        if (seenLocals.contains(variable)) return;
        seenLocals.add(variable);
        f(variable, type);
      });
    }
    if (block == node) return;
    if (parent != null) parent.forEachLocalUntilNode(node, f, seenLocals);
  }

  void forEachLocal(void f(Local variable, T type)) {
    forEachLocalUntilNode(null, f);
  }

  bool updates(Local variable) {
    if (variables == null) return false;
    return variables.containsKey(variable);
  }

  String toString() {
    String rest = parent == null ? "null" : parent.toString();
    return '$variables $rest';
  }
}

class FieldInitializationScope<T> {
  final TypeSystem<T> types;
  Map<Element, T> fields;
  bool isThisExposed;

  FieldInitializationScope(this.types) : isThisExposed = false;

  FieldInitializationScope.internalFrom(FieldInitializationScope<T> other)
      : types = other.types,
        isThisExposed = other.isThisExposed;

  factory FieldInitializationScope.from(FieldInitializationScope<T> other) {
    if (other == null) return null;
    return new FieldInitializationScope<T>.internalFrom(other);
  }

  void updateField(Element field, T type) {
    if (isThisExposed) return;
    if (fields == null) fields = new Map<Element, T>();
    fields[field] = type;
  }

  T readField(Element field) {
    return fields == null ? null : fields[field];
  }

  void forEach(void f(Element element, T type)) {
    if (fields == null) return;
    fields.forEach(f);
  }

  void mergeDiamondFlow(FieldInitializationScope<T> thenScope,
                        FieldInitializationScope<T> elseScope) {
    // Quick bailout check. If [isThisExposed] is true, we know the
    // code following won't do anything.
    if (isThisExposed) return;
    if (elseScope == null || elseScope.fields == null) {
      elseScope = this;
    }

    thenScope.forEach((Element field, T type) {
      T otherType = elseScope.readField(field);
      if (otherType == null) return;
      updateField(field, types.allocateDiamondPhi(type, otherType));
    });
    isThisExposed = thenScope.isThisExposed || elseScope.isThisExposed;
  }
}

/**
 * Placeholder for inferred arguments types on sends.
 */
class ArgumentsTypes<T> extends IterableMixin<T> {
  final List<T> positional;
  final Map<String, T> named;
  ArgumentsTypes(this.positional, named)
    : this.named = (named == null || named.isEmpty) ? const {} : named {
    assert(this.positional.every((T type) => type != null));
    assert(this.named.values.every((T type) => type != null));
  }

  int get length => positional.length + named.length;

  Iterator<T> get iterator => new ArgumentsTypesIterator(this);

  String toString() => "{ positional = $positional, named = $named }";

  bool operator==(other) {
    if (positional.length != other.positional.length) return false;
    if (named.length != other.named.length) return false;
    for (int i = 0; i < positional.length; i++) {
      if (positional[i] != other.positional[i]) return false;
    }
    named.forEach((name, type) {
      if (other.named[name] != type) return false;
    });
    return true;
  }

  int get hashCode => throw new UnsupportedError('ArgumentsTypes.hashCode');

  bool hasNoArguments() => positional.isEmpty && named.isEmpty;

  bool hasOnePositionalArgumentThatMatches(bool f(T type)) {
    return named.isEmpty && positional.length == 1 && f(positional[0]);
  }

  void forEach(void f(T type)) {
    positional.forEach(f);
    named.values.forEach(f);
  }

  bool every(bool f(T type)) {
    return positional.every(f) && named.values.every(f);
  }

  bool contains(T type) {
    return positional.contains(type) || named.containsValue(type);
  }
}

class ArgumentsTypesIterator<T> implements Iterator<T> {
  final Iterator<T> positional;
  final Iterator<T> named;
  bool _iteratePositional = true;

  ArgumentsTypesIterator(ArgumentsTypes<T> iteratee)
      : positional = iteratee.positional.iterator,
        named = iteratee.named.values.iterator;

  Iterator<T> get _currentIterator => _iteratePositional ? positional : named;

  T get current => _currentIterator.current;

  bool moveNext() {
    if (_iteratePositional && positional.moveNext()) {
      return true;
    }
    _iteratePositional = false;
    return named.moveNext();
  }
}


abstract class MinimalInferrerEngine<T> {
  /**
   * Returns the type of [element].
   */
  T typeOfElement(Element element);

  /**
   * Records that [node] sets non-final field [element] to be of type
   * [type].
   */
  void recordTypeOfNonFinalField(Node node, Element field, T type);

  /**
   * Records that the captured variable [local] is read.
   */
  void recordCapturedLocalRead(Local local);

  /**
   * Records that the variable [local] is being updated.
   */
  void recordLocalUpdate(Local local, T type);
}

/**
 * Placeholder for inferred types of local variables.
 */
class LocalsHandler<T> {
  final Compiler compiler;
  final TypeSystem<T> types;
  final MinimalInferrerEngine<T> inferrer;
  final VariableScope<T> locals;
  final Map<Local, Element> captured;
  final Map<Local, Element> capturedAndBoxed;
  final FieldInitializationScope<T> fieldScope;
  LocalsHandler<T> tryBlock;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }
  bool get inTryBlock => tryBlock != null;

  LocalsHandler(this.inferrer,
                this.types,
                this.compiler,
                Node block,
                [this.fieldScope])
      : locals = new VariableScope<T>(block),
        captured = new Map<Local, Element>(),
        capturedAndBoxed = new Map<Local, Element>(),
        tryBlock = null;

  LocalsHandler.from(LocalsHandler<T> other,
                     Node block,
                     {bool useOtherTryBlock: true})
      : locals = new VariableScope<T>(block, other.locals),
        fieldScope = new FieldInitializationScope<T>.from(other.fieldScope),
        captured = other.captured,
        capturedAndBoxed = other.capturedAndBoxed,
        types = other.types,
        inferrer = other.inferrer,
        compiler = other.compiler {
    tryBlock = useOtherTryBlock ? other.tryBlock : this;
  }

  LocalsHandler.deepCopyOf(LocalsHandler<T> other)
      : locals = new VariableScope<T>.deepCopyOf(other.locals),
        fieldScope = new FieldInitializationScope<T>.from(other.fieldScope),
        captured = other.captured,
        capturedAndBoxed = other.capturedAndBoxed,
        tryBlock = other.tryBlock,
        types = other.types,
        inferrer = other.inferrer,
        compiler = other.compiler;

  T use(Local local) {
    if (capturedAndBoxed.containsKey(local)) {
      return inferrer.typeOfElement(capturedAndBoxed[local]);
    } else {
      if (captured.containsKey(local)) {
        inferrer.recordCapturedLocalRead(local);
      }
      return locals[local];
    }
  }

  void update(LocalElement local, T type, Node node) {
    assert(type != null);
    if (compiler.trustTypeAnnotations || compiler.enableTypeAssertions) {
      type = types.narrowType(type, local.type);
    }
    updateLocal() {
      T currentType = locals[local];
      locals[local] = type;
      if (currentType != type) {
        inferrer.recordLocalUpdate(local, type);
      }
    }
    if (capturedAndBoxed.containsKey(local)) {
      inferrer.recordTypeOfNonFinalField(
          node, capturedAndBoxed[local], type);
    } else if (inTryBlock) {
      // We don't know if an assignment in a try block
      // will be executed, so all assigments in that block are
      // potential types after we have left it. We update the parent
      // of the try block so that, at exit of the try block, we get
      // the right phi for it.
      T existing = tryBlock.locals.parent[local];
      if (existing != null) {
        T phiType = types.allocatePhi(tryBlock.locals.block, local, existing);
        T inputType = types.addPhiInput(local, phiType, type);
        tryBlock.locals.parent[local] = inputType;
      }
      // Update the current handler unconditionnally with the new
      // type.
      updateLocal();
    } else {
      updateLocal();
    }
  }

  void setCaptured(Local local, Element field) {
    captured[local] = field;
  }

  void setCapturedAndBoxed(Local local, Element field) {
    capturedAndBoxed[local] = field;
  }

  void mergeDiamondFlow(LocalsHandler<T> thenBranch,
                        LocalsHandler<T> elseBranch) {
    if (fieldScope != null && elseBranch != null) {
      fieldScope.mergeDiamondFlow(thenBranch.fieldScope, elseBranch.fieldScope);
    }
    seenReturnOrThrow = thenBranch.seenReturnOrThrow
        && elseBranch != null
        && elseBranch.seenReturnOrThrow;
    seenBreakOrContinue = thenBranch.seenBreakOrContinue
        && elseBranch != null
        && elseBranch.seenBreakOrContinue;
    if (aborts) return;

    void mergeOneBranch(LocalsHandler<T> other) {
      other.locals.forEachOwnLocal((Local local, T type) {
        T myType = locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        locals[local] = types.allocateDiamondPhi(myType, type);
      });
    }

    void inPlaceUpdateOneBranch(LocalsHandler<T> other) {
      other.locals.forEachOwnLocal((Local local, T type) {
        T myType = locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        locals[local] = type;
      });
    }

    if (thenBranch.aborts) {
      if (elseBranch == null) return;
      inPlaceUpdateOneBranch(elseBranch);
    } else if (elseBranch == null) {
      mergeOneBranch(thenBranch);
    } else if (elseBranch.aborts) {
      inPlaceUpdateOneBranch(thenBranch);
    } else {
      void mergeLocal(Local local) {
        T myType = locals[local];
        if (myType == null) return;
        T elseType = elseBranch.locals[local];
        T thenType = thenBranch.locals[local];
        if (thenType == elseType) {
          locals[local] = thenType;
        } else {
          locals[local] = types.allocateDiamondPhi(thenType, elseType);
        }
      }

      thenBranch.locals.forEachOwnLocal((Local local, _) {
        mergeLocal(local);
      });
      elseBranch.locals.forEachOwnLocal((Local local, _) {
        // Discard locals we already processed when iterating over
        // [thenBranch]'s locals.
        if (!thenBranch.locals.updates(local)) mergeLocal(local);
      });
    }
  }

  /**
   * Merge all [LocalsHandler] in [handlers] into [:this:].
   *
   * If [keepOwnLocals] is true, the types of locals in this
   * [LocalsHandler] are being used in the merge. [keepOwnLocals]
   * should be true if this [LocalsHandler], the dominator of
   * all [handlers], also direclty flows into the join point,
   * that is the code after all [handlers]. For example, consider:
   *
   * [: switch (...) {
   *      case 1: ...; break;
   *    }
   * :]
   *
   * The [LocalsHandler] at entry of the switch also flows into the
   * exit of the switch, because there is no default case. So the
   * types of locals at entry of the switch have to take part to the
   * merge.
   *
   * The above situation is also true for labeled statements like
   *
   * [: L: {
   *      if (...) break;
   *      ...
   *    }
   * :]
   *
   * where [:this:] is the [LocalsHandler] for the paths through the
   * labeled statement that do not break out.
   */
  void mergeAfterBreaks(List<LocalsHandler<T>> handlers,
                        {bool keepOwnLocals: true}) {
    Node level = locals.block;
    Set<Local> seenLocals = new Setlet<Local>();
    // If we want to keep the locals, we first merge [this] into itself to
    // create the required Phi nodes.
    if (keepOwnLocals && !seenReturnOrThrow) {
      mergeHandler(this, seenLocals);
    }
    bool allBranchesAbort = true;
    // Merge all other handlers.
    for (LocalsHandler handler in handlers) {
      allBranchesAbort = allBranchesAbort && handler.seenReturnOrThrow;
      mergeHandler(handler, seenLocals);
    }
    // Clean up Phi nodes with single input.
    locals.forEachLocal((Local variable, T type) {
      if (!seenLocals.contains(variable)) return;
      T newType = types.simplifyPhi(level, variable, type);
      if (newType != type) {
        locals[variable] = newType;
      }
    });
    seenReturnOrThrow = allBranchesAbort &&
                        (!keepOwnLocals || seenReturnOrThrow);
  }

  /**
   * Merge [other] into this handler. Returns whether a local in this
   * has changed. If [seen] is not null, we allocate new Phi nodes
   * unless the local is already present in the set [seen]. This effectively
   * overwrites the current type knowledge in this handler.
   */
  bool mergeHandler(LocalsHandler<T> other, [Set<Local> seen]) {
    if (other.seenReturnOrThrow) return false;
    bool changed = false;
    other.locals.forEachLocalUntilNode(locals.block, (local, otherType) {
      T myType = locals[local];
      if (myType == null) return;
      T newType;
      if (seen != null && !seen.contains(local)) {
        newType = types.allocatePhi(locals.block, local, otherType);
        seen.add(local);
      } else {
        newType = types.addPhiInput(local, myType, otherType);
      }
      if (newType != myType) {
        changed = true;
        locals[local] = newType;
      }
    });
    return changed;
  }

  /**
   * Merge all [LocalsHandler] in [handlers] into this handler.
   * Returns whether a local in this handler has changed.
   */
  bool mergeAll(List<LocalsHandler<T>> handlers) {
    bool changed = false;
    assert(!seenReturnOrThrow);
    handlers.forEach((other) {
      changed = mergeHandler(other) || changed;
    });
    return changed;
  }

  void startLoop(Node loop) {
    locals.forEachLocal((Local variable, T type) {
      T newType = types.allocateLoopPhi(loop, variable, type);
      if (newType != type) {
        locals[variable] = newType;
      }
    });
  }

  void endLoop(Node loop) {
    locals.forEachLocal((Local variable, T type) {
      T newType = types.simplifyPhi(loop, variable, type);
      if (newType != type) {
        locals[variable] = newType;
      }
    });
  }

  void updateField(Element element, T type) {
    fieldScope.updateField(element, type);
  }
}

abstract class InferrerVisitor
    <T, E extends MinimalInferrerEngine<T>> extends ResolvedVisitor<T> {
  final Compiler compiler;
  final AstElement analyzedElement;
  final TypeSystem<T> types;
  final E inferrer;
  final Map<JumpTarget, List<LocalsHandler<T>>> breaksFor =
      new Map<JumpTarget, List<LocalsHandler<T>>>();
  final Map<JumpTarget, List<LocalsHandler>> continuesFor =
      new Map<JumpTarget, List<LocalsHandler<T>>>();
  LocalsHandler<T> locals;
  final List<T> cascadeReceiverStack = new List<T>();

  bool accumulateIsChecks = false;
  bool conditionIsSimple = false;
  List<Send> isChecks;
  int loopLevel = 0;

  bool get inLoop => loopLevel > 0;
  bool get isThisExposed {
    return analyzedElement.isGenerativeConstructor
        ? locals.fieldScope.isThisExposed
        : true;
  }
  void set isThisExposed(value) {
    if (analyzedElement.isGenerativeConstructor) {
      locals.fieldScope.isThisExposed = value;
    }
  }

  InferrerVisitor(AstElement analyzedElement,
                  this.inferrer,
                  this.types,
                  this.compiler,
                  [LocalsHandler<T> handler])
    : this.analyzedElement = analyzedElement,
      this.locals = handler,
      super(analyzedElement.resolvedAst.elements) {
    if (handler != null) return;
    Node node = analyzedElement.node;
    FieldInitializationScope<T> fieldScope =
        analyzedElement.isGenerativeConstructor
            ? new FieldInitializationScope<T>(types)
            : null;
    locals = new LocalsHandler<T>(inferrer, types, compiler, node, fieldScope);
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

  T visitAssert(Send node) {
    if (!compiler.enableUserAssertions) {
      return types.nullType;
    }
    // TODO(johnniwinther): Don't handle assert like a regular static call since
    // it break the selector name check.
    return visitStaticSend(node);
  }

  T visitNode(Node node) {
    return node.visitChildren(this);
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
    return types.stringLiteralType(node.dartString);
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
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    // The JavaScript backend may turn this literal into an integer at
    // runtime.
    return types.getConcreteTypeFor(
        constantSystem.createDouble(node.value).computeMask(compiler));
  }

  T visitLiteralInt(LiteralInt node) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return types.getConcreteTypeFor(
        constantSystem.createInt(node.value).computeMask(compiler));
  }

  T visitLiteralList(LiteralList node) {
    node.visitChildren(this);
    return node.isConst ? types.constListType : types.growableListType;
  }

  T visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
    return node.isConst ? types.constMapType : types.mapType;
  }

  T visitLiteralNull(LiteralNull node) {
    return types.nullType;
  }

  T visitLiteralSymbol(LiteralSymbol node) {
    // TODO(kasperl): We should be able to tell that the type of a literal
    // symbol is always a non-null exact symbol implementation -- not just
    // any non-null subtype of the symbol interface.
    return types.nonNullSubtype(compiler.symbolClass);
  }

  T visitTypePrefixSend(Send node) {
    // TODO(johnniwinther): Remove the need for handling this node.
    return types.dynamicType;
  }

  T visitTypeLiteralSend(Send node) {
    return types.typeType;
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  Element get outermostElement {
    return analyzedElement.outermostEnclosingMemberOrTopLevel.implementation;
  }

  T _thisType;
  T get thisType {
    if (_thisType != null) return _thisType;
    ClassElement cls = outermostElement.enclosingClass;
    ClassWorld classWorld = compiler.world;
    if (classWorld.isUsedAsMixin(cls)) {
      return _thisType = types.nonNullSubtype(cls);
    } else {
      return _thisType = types.nonNullSubclass(cls);
    }
  }

  T _superType;
  T get superType {
    if (_superType != null) return _superType;
    return _superType = types.nonNullExact(
        outermostElement.enclosingClass.superclass);
  }

  T visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return superType;
    } else {
      Element element = elements[node];
      if (Elements.isLocal(element)) {
        LocalElement local = element;
        return locals.use(local);
      }
      return null;
    }
  }

  void potentiallyAddIsCheck(Send node) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[node.receiver])) return;
    isChecks.add(node);
  }

  void potentiallyAddNullCheck(Send node, Node receiver) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[receiver])) return;
    isChecks.add(node);
  }

  void updateIsChecks(List<Node> tests, {bool usePositive}) {
    void narrow(Element element, DartType type, Node node) {
      if (element is LocalElement) {
        T existing = locals.use(element);
        T newType = types.narrowType(existing, type, isNullable: false);
        locals.update(element, newType, node);
      }
    }

    if (tests == null) return;
    for (Send node in tests) {
      if (node.isTypeTest) {
        if (node.isIsNotCheck) {
          if (usePositive) continue;
        } else {
          if (!usePositive) continue;
        }
        DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
        narrow(elements[node.receiver], type, node);
      } else {
        Element receiverElement = elements[node.receiver];
        Element argumentElement = elements[node.arguments.first];
        String operator = node.selector.asOperator().source;
        if ((operator == '==' && usePositive)
            || (operator == '!=' && !usePositive)) {
          // Type the elements as null.
          if (Elements.isLocal(receiverElement)) {
            locals.update(receiverElement, types.nullType, node);
          }
          if (Elements.isLocal(argumentElement)) {
            locals.update(argumentElement, types.nullType, node);
          }
        } else {
          // Narrow the elements to a non-null type.
          DartType objectType = compiler.objectClass.rawType;
          if (Elements.isLocal(receiverElement)) {
            narrow(receiverElement, objectType, node);
          }
          if (Elements.isLocal(argumentElement)) {
            narrow(argumentElement, objectType, node);
          }
        }
      }
    }
  }

  T visitOperatorSend(Send node) {
    Operator op = node.selector;
    if ("[]" == op.source) {
      return visitDynamicSend(node);
    } else if ("&&" == op.source) {
      conditionIsSimple = false;
      bool oldAccumulateIsChecks = accumulateIsChecks;
      List<Send> oldIsChecks = isChecks;
      if (!accumulateIsChecks) {
        accumulateIsChecks = true;
        isChecks = <Send>[];
      }
      visit(node.receiver);
      LocalsHandler<T> saved = locals;
      locals = new LocalsHandler<T>.from(locals, node);
      updateIsChecks(isChecks, usePositive: true);
      if (!oldAccumulateIsChecks) {
        accumulateIsChecks = false;
        isChecks = oldIsChecks;
      }
      visit(node.arguments.head);
      saved.mergeDiamondFlow(locals, null);
      locals = saved;
      return types.boolType;
    } else if ("||" == op.source) {
      conditionIsSimple = false;
      List<Send> tests = <Send>[];
      bool isSimple = handleCondition(node.receiver, tests);
      LocalsHandler<T> saved = locals;
      locals = new LocalsHandler<T>.from(locals, node);
      if (isSimple) updateIsChecks(tests, usePositive: false);
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      visit(node.arguments.head);
      accumulateIsChecks = oldAccumulateIsChecks;
      saved.mergeDiamondFlow(locals, null);
      locals = saved;
      return types.boolType;
    } else if ("!" == op.source) {
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      node.visitChildren(this);
      accumulateIsChecks = oldAccumulateIsChecks;
      return types.boolType;
    } else if ("is" == op.source) {
      potentiallyAddIsCheck(node);
      node.visitChildren(this);
      return types.boolType;
    } else if ("as" == op.source) {
      T receiverType = visit(node.receiver);
      DartType type = elements.getType(node.arguments.head);
      return types.narrowType(receiverType, type);
    } else if (node.argumentsNode is Prefix) {
      // Unary operator.
      return visitDynamicSend(node);
    } else if ('===' == op.source
               || '!==' == op.source) {
      node.visitChildren(this);
      return types.boolType;
    } else if ('!=' == op.source) {
      visitDynamicSend(node);
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
    locals = new LocalsHandler<T>.from(locals, node);
    updateIsChecks(tests, usePositive: true);
    T firstType = visit(node.thenExpression);
    LocalsHandler<T> thenLocals = locals;
    locals = new LocalsHandler<T>.from(saved, node);
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    T secondType = visit(node.elseExpression);
    saved.mergeDiamondFlow(thenLocals, locals);
    locals = saved;
    T type = types.allocateDiamondPhi(firstType, secondType);
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
    return null;
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
    locals = new LocalsHandler<T>.from(locals, node);
    updateIsChecks(tests, usePositive: true);
    visit(node.thenPart);
    LocalsHandler<T> thenLocals = locals;
    locals = new LocalsHandler<T>.from(saved, node);
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.elsePart);
    saved.mergeDiamondFlow(thenLocals, locals);
    locals = saved;
    return null;
  }

  void setupBreaksAndContinues(JumpTarget element) {
    if (element == null) return;
    if (element.isContinueTarget) continuesFor[element] = <LocalsHandler>[];
    if (element.isBreakTarget) breaksFor[element] = <LocalsHandler>[];
  }

  void clearBreaksAndContinues(JumpTarget element) {
    continuesFor.remove(element);
    breaksFor.remove(element);
  }

  List<LocalsHandler<T>> getBreaks(JumpTarget element) {
    List<LocalsHandler<T>> list = <LocalsHandler<T>>[locals];
    if (element == null) return list;
    if (!element.isBreakTarget) return list;
    return list..addAll(breaksFor[element]);
  }

  List<LocalsHandler<T>> getLoopBackEdges(JumpTarget element) {
    List<LocalsHandler<T>> list = <LocalsHandler<T>>[locals];
    if (element == null) return list;
    if (!element.isContinueTarget) return list;
    return list..addAll(continuesFor[element]);
  }

  T handleLoop(Node node, void logic()) {
    loopLevel++;
    bool changed = false;
    JumpTarget target = elements.getTargetDefinition(node);
    LocalsHandler<T> saved = locals;
    saved.startLoop(node);
    do {
      // Setup (and clear in case of multiple iterations of the loop)
      // the lists of breaks and continues seen in the loop.
      setupBreaksAndContinues(target);
      locals = new LocalsHandler<T>.from(saved, node);
      logic();
      changed = saved.mergeAll(getLoopBackEdges(target));
    } while (changed);
    loopLevel--;
    saved.endLoop(node);
    bool keepOwnLocals = node.asDoWhile() == null;
    saved.mergeAfterBreaks(
        getBreaks(target), keepOwnLocals: keepOwnLocals);
    locals = saved;
    clearBreaksAndContinues(target);
    return null;
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
    locals = new LocalsHandler<T>.from(
        locals, node, useOtherTryBlock: false);
    visit(node.tryBlock);
    saved.mergeDiamondFlow(locals, null);
    locals = saved;
    for (Node catchBlock in node.catchBlocks) {
      saved = locals;
      locals = new LocalsHandler<T>.from(locals, catchBlock);
      visit(catchBlock);
      saved.mergeDiamondFlow(locals, null);
      locals = saved;
    }
    visit(node.finallyBlock);
    return null;
  }

  T visitThrow(Throw node) {
    node.visitChildren(this);
    locals.seenReturnOrThrow = true;
    return types.nonNullEmpty();
  }

  T visitCatchBlock(CatchBlock node) {
    Node exception = node.exception;
    if (exception != null) {
      DartType type = elements.getType(node.type);
      T mask = type == null ||
               type.treatAsDynamic ||
               type.isTypeVariable
          ? types.dynamicType
          : types.nonNullSubtype(type.element);
      locals.update(elements[exception], mask, node);
    }
    Node trace = node.trace;
    if (trace != null) {
      locals.update(elements[trace], types.dynamicType, node);
    }
    visit(node.block);
    return null;
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
    return null;
  }

  T visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop
        || body is SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
    } else {
      JumpTarget targetElement = elements.getTargetDefinition(body);
      setupBreaksAndContinues(targetElement);
      visit(body);
      locals.mergeAfterBreaks(getBreaks(targetElement));
      clearBreaksAndContinues(targetElement);
    }
    return null;
  }

  T visitBreakStatement(BreakStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    breaksFor[target].add(new LocalsHandler<T>.deepCopyOf(locals));
    return null;
  }

  T visitContinueStatement(ContinueStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // continue will change them.
    continuesFor[target].add(new LocalsHandler<T>.deepCopyOf(locals));
    return null;
  }

  void internalError(String reason, {Node node}) {
    compiler.internalError(node, reason);
  }

  T visitSwitchStatement(SwitchStatement node) {
    visit(node.parenthesizedExpression);

    setupBreaksAndContinues(elements.getTargetDefinition(node));
    if (Elements.switchStatementHasContinue(node, elements)) {
      void forEachLabeledCase(void action(JumpTarget target)) {
        for (SwitchCase switchCase in node.cases) {
          for (Node labelOrCase in switchCase.labelsAndCases) {
            if (labelOrCase.asLabel() == null) continue;
            LabelDefinition labelElement =
                elements.getLabelDefinition(labelOrCase);
            if (labelElement != null) {
              action(labelElement.target);
            }
          }
        }
      }

      forEachLabeledCase((JumpTarget target) {
        setupBreaksAndContinues(target);
      });

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      locals.startLoop(node);
      do {
        changed = false;
        for (Node switchCase in node.cases) {
          LocalsHandler<T> saved = locals;
          locals = new LocalsHandler<T>.from(locals, switchCase);
          visit(switchCase);
          changed = saved.mergeAll([locals]) || changed;
          locals = saved;
        }
      } while (changed);
      locals.endLoop(node);

      forEachLabeledCase((JumpTarget target) {
        clearBreaksAndContinues(target);
      });
    } else {
      LocalsHandler<T> saved = locals;
      List<LocalsHandler<T>> localsToMerge = <LocalsHandler<T>>[];
      bool hasDefaultCase = false;

      for (SwitchCase switchCase in node.cases) {
        if (switchCase.isDefaultCase) {
          hasDefaultCase = true;
        }
        locals = new LocalsHandler<T>.from(saved, switchCase);
        visit(switchCase);
        localsToMerge.add(locals);
      }
      saved.mergeAfterBreaks(localsToMerge, keepOwnLocals: !hasDefaultCase);
      locals = saved;
    }
    clearBreaksAndContinues(elements.getTargetDefinition(node));
    return null;
  }

  T visitCascadeReceiver(CascadeReceiver node) {
    var type = visit(node.expression);
    cascadeReceiverStack.add(type);
    return type;
  }

  T visitCascade(Cascade node) {
    // Ignore the result of the cascade send and return the type of the cascade
    // receiver.
    visit(node.expression);
    return cascadeReceiverStack.removeLast();
  }
}

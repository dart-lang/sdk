// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.gvn;

import 'cps_ir_nodes.dart';
import '../universe/side_effects.dart';
import '../elements/elements.dart';
import 'optimizers.dart' show Pass;
import 'loop_hierarchy.dart';
import 'loop_effects.dart';
import '../world.dart';
import '../compiler.dart' show Compiler;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../constants/values.dart';
import 'type_mask_system.dart';

/// Eliminates redundant primitives by reusing the value of another primitive
/// that is known to have the same result.  Primitives are also hoisted out of
/// loops when possible.
///
/// Reusing values can introduce new temporaries, which in some cases is more
/// expensive than recomputing the value on-demand. For example, pulling an
/// expression such as "n+1" out of a loop is generally not worth it.
/// Such primitives are said to be "trivial".
///
/// Trivial primitives are shared on-demand, i.e. they are only shared if
/// this enables a non-trivial primitive to be hoisted out of a loop.
//
//  TODO(asgerf): Enable hoisting across refinement guards when this is safe:
//    - Determine the type required for a given primitive to be "safe"
//    - Recompute the type of a primitive after hoisting.
//        E.g. GetIndex on a String can become a GetIndex on an arbitrary
//             indexable, which is still safe but the type may change
//    - Since the new type may be worse, insert a refinement at the old
//      definition site, so we do not degrade existing type information.
//
//  TODO(asgerf): Put this pass at a better place in the pipeline.  We currently
//    cannot put it anywhere we want, because this pass relies on refinement
//    nodes being present (for safety), whereas other passes rely on refinement
//    nodes being absent (for simplicity & precision).
//
class GVN extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'GVN';

  final Compiler compiler;
  final TypeMaskSystem types;
  JavaScriptBackend get backend => compiler.backend;
  World get world => compiler.world;

  final GvnTable gvnTable = new GvnTable();
  GvnVectorBuilder gvnVectorBuilder;
  LoopHierarchy loopHierarchy;
  LoopSideEffects loopEffects;

  /// Effect numbers at the given join point.
  Map<Continuation, EffectNumbers> effectsAt = <Continuation, EffectNumbers>{};

  /// The effect numbers at the current position (during traversal).
  EffectNumbers effectNumbers = new EffectNumbers();

  /// The loop currently enclosing the binding of a given primitive.
  final Map<Primitive, Continuation> loopHeaderFor =
      <Primitive, Continuation>{};

  /// The GVNs for primitives that have been hoisted outside the given loop.
  ///
  /// These should be removed from the environment when exiting the loop.
  final Map<Continuation, List<int>> loopHoistedBindings =
      <Continuation, List<int>>{};

  /// Maps GVNs to a currently-in-scope binding for that value.
  final Map<int, Primitive> environment = <int, Primitive>{};

  /// Maps GVN'able primitives to their global value number.
  final Map<Primitive, int> gvnFor = <Primitive, int>{};

  Continuation currentLoopHeader;

  GVN(this.compiler, this.types);

  int _usedEffectNumbers = 0;
  int makeNewEffect() => ++_usedEffectNumbers;

  void rewrite(FunctionDefinition node) {
    gvnVectorBuilder = new GvnVectorBuilder(gvnFor, compiler, types);
    loopHierarchy = new LoopHierarchy(node);
    loopEffects =
        new LoopSideEffects(node, world, loopHierarchy: loopHierarchy);
    visit(node);
  }

  // ------------------ GLOBAL VALUE NUMBERING ---------------------

  /// True if [prim] can be eliminated if its value is already in scope.
  bool canReplaceWithExistingValue(Primitive prim) {
    // Primitives that have no side effects other than potentially throwing are
    // known not the throw if the value is already in scope. Handling those
    // specially is equivalent to updating refinements during GVN.
    // GetLazyStatic cannot have side effects because the field has already
    // been initialized.
    return prim.isSafeForElimination ||
           prim is GetField ||
           prim is GetLength ||
           prim is GetIndex ||
           prim is GetLazyStatic;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    Primitive prim = node.primitive;

    loopHeaderFor[prim] = currentLoopHeader;

    if (prim is Refinement) {
      // Do not share refinements (they have no runtime or code size cost), and
      // do not put them in the GVN table because GvnVectorBuilder unfolds
      // refinements by itself.
      return next;
    }

    // Update effect numbers due to side effects from a static initializer.
    // GetLazyStatic is GVN'ed like a GetStatic, but the effects of the static
    // initializer occur before reading the field.
    if (prim is GetLazyStatic) {
      visit(prim);
    }

    // Compute the GVN vector for this computation.
    List vector = gvnVectorBuilder.make(prim, effectNumbers);

    // Update effect numbers due to side effects.
    // Do this after computing the GVN vector so the primitive's GVN is not
    // influenced by its own side effects, except in the case of GetLazyStatic.
    if (prim is! GetLazyStatic) {
      visit(prim);
    }

    if (vector == null) {
      // The primitive is not GVN'able. Move on.
      return next;
    }

    // Compute the GVN for this primitive.
    int gvn = gvnTable.insert(vector);
    gvnFor[prim] = gvn;

    // Try to reuse a previously computed value with the same GVN.
    Primitive existing = environment[gvn];
    if (existing != null &&
        canReplaceWithExistingValue(prim) &&
        !isFastConstant(prim)) {
      if (prim is Interceptor) {
        Interceptor interceptor = existing;
        interceptor.interceptedClasses.addAll(prim.interceptedClasses);
      }
      prim..replaceUsesWith(existing)..destroy();
      node.remove();
      return next;
    }

    if (tryToHoistOutOfLoop(prim, gvn)) {
      return next;
    }

    // The primitive could not be hoisted.  Put the primitive in the
    // environment while processing the body of the LetPrim.
    environment[gvn] = prim;
    pushAction(() {
      assert(environment[gvn] == prim);
      environment[gvn] = existing;
    });

    return next;
  }

  bool isFirstImpureExpressionInLoop(Expression exp) {
    InteriorNode node = exp.parent;
    for (; node is Expression; node = node.parent) {
      if (node is LetPrim && node.primitive.isSafeForElimination) {
        continue;
      }
      if (node is LetCont) {
        continue;
      }
      return false;
    }
    return node == currentLoopHeader;
  }

  bool isHoistablePrimitive(Primitive prim) {
    if (prim.isSafeForElimination) return true;
    if (prim is NullCheck ||
        prim is BoundsCheck ||
        prim is GetLength ||
        prim is GetField ||
        prim is GetIndex) {
      // Expressions that potentially throw but have no other effects can be
      // hoisted if they occur as the first impure expression in a loop.
      // Note regarding BoundsCheck: the current array length is an input to
      // check, so the check itself has no heap dependency.  It will only be
      // hoisted if the length was hoisted.
      // TODO(asgerf): In general we could hoist these out of multiple loops,
      //   but the trick we use here only works for one loop level.
      return isFirstImpureExpressionInLoop(prim.parent);
    }
    return false;
  }

  /// Try to hoist the binding of [prim] out of loops. Returns `true` if it was
  /// hoisted or marked as a trivial hoist-on-demand primitive.
  bool tryToHoistOutOfLoop(Primitive prim, int gvn) {
    // Bail out fast if the primitive is not inside a loop.
    if (currentLoopHeader == null) return false;

    // Do not hoist primitives with side effects.
    if (!isHoistablePrimitive(prim)) return false;

    LetPrim letPrim = prim.parent;

    // Find the depth of the outermost scope where we can bind the primitive
    // without bringing a reference out of scope. 0 is the depth of the
    // top-level scope.
    int hoistDepth = 0;
    List<Primitive> inputsHoistedOnDemand = <Primitive>[];
    InputVisitor.forEach(prim, (Reference ref) {
      Primitive input = ref.definition;
      if (canIgnoreRefinementGuards(prim)) {
        input = input.effectiveDefinition;
      }
      if (isFastConstant(input)) {
        // Fast constants can be hoisted all the way out, but should only be
        // hoisted if needed to hoist something else.
        inputsHoistedOnDemand.add(input);
      } else {
        Continuation loopHeader = loopHeaderFor[input];
        Continuation referencedLoop =
            loopHierarchy.lowestCommonAncestor(loopHeader, currentLoopHeader);
        int depth = loopHierarchy.getDepth(referencedLoop);
        if (depth > hoistDepth) {
          hoistDepth = depth;
        }
      }
    });

    // Bail out if it can not be hoisted further out than it is now.
    if (hoistDepth == loopHierarchy.getDepth(currentLoopHeader)) return false;

    // Walk up the loop hierarchy and check at every step that any heap
    // dependencies can safely be hoisted out of the loop.
    Continuation enclosingLoop = currentLoopHeader;
    Continuation hoistTarget = null;
    while (loopHierarchy.getDepth(enclosingLoop) > hoistDepth &&
           canHoistHeapDependencyOutOfLoop(prim, enclosingLoop)) {
      hoistTarget = enclosingLoop;
      enclosingLoop = loopHierarchy.getEnclosingLoop(enclosingLoop);
    }

    // Bail out if heap dependencies prohibit any hoisting at all.
    if (hoistTarget == null) return false;

    if (isFastConstant(prim)) {
      // The overhead from introducting a temporary might be greater than
      // the overhead of evaluating this primitive at every iteration.
      // Only hoist if this enables hoisting of a non-trivial primitive.
      return true;
    }

    LetCont loopBinding = hoistTarget.parent;

    // The primitive may depend on values that have not yet been
    // hoisted as far as they can.  Hoist those now.
    for (Primitive input in inputsHoistedOnDemand) {
      hoistTrivialPrimitive(input, loopBinding, enclosingLoop);
    }

    // Hoist the primitive.
    letPrim.remove();
    letPrim.insertAbove(loopBinding);
    loopHeaderFor[prim] = enclosingLoop;

    // If a refinement guard was bypassed, use the best refinement
    // currently in scope.
    if (canIgnoreRefinementGuards(prim)) {
      int target = loopHierarchy.getDepth(enclosingLoop);
      InputVisitor.forEach(prim, (Reference ref) {
        Primitive input = ref.definition;
        while (input is Refinement) {
          Continuation loop = loopHeaderFor[input];
          loop = loopHierarchy.lowestCommonAncestor(loop, currentLoopHeader);
          if (loopHierarchy.getDepth(loop) <= target) break;
          Refinement refinement = input;
          input = refinement.value.definition;
        }
        ref.changeTo(input);
      });
    }

    // Put the primitive in the environment while processing the loop.
    environment[gvn] = prim;
    loopHoistedBindings
        .putIfAbsent(hoistTarget, () => <int>[])
        .add(gvn);
    return true;
  }

  /// If the given primitive is a trivial primitive that should be hoisted
  /// on-demand, hoist it and its dependent values above [loopBinding].
  void hoistTrivialPrimitive(Primitive prim,
                             LetCont loopBinding,
                             Continuation enclosingLoop) {
    assert(isFastConstant(prim));

    // The primitive might already be bound in an outer scope.  Do not relocate
    // the primitive unless we are lifting it. For example;
    //    t1 = a + b
    //    t2 = t1 + c
    //    t3 = t1 * t2
    // If it was decided that `t3` should be hoisted, `t1` will be seen twice by
    // this method: by the direct reference and by reference through `t2`.
    // The second time it is seen, it will already have been moved.
    Continuation currentLoop = loopHeaderFor[prim];
    int currentDepth = loopHierarchy.getDepth(currentLoop);
    int targetDepth = loopHierarchy.getDepth(enclosingLoop);
    if (currentDepth <= targetDepth) return;

    // Hoist the trivial primitives being depended on so they remain in scope.
    InputVisitor.forEach(prim, (Reference ref) {
      hoistTrivialPrimitive(ref.definition, loopBinding, enclosingLoop);
    });

    // Move the primitive.
    LetPrim binding = prim.parent;
    binding.remove();
    binding.insertAbove(loopBinding);
    loopHeaderFor[prim] = enclosingLoop;
  }

  bool canIgnoreRefinementGuards(Primitive primitive) {
    return primitive is Interceptor;
  }

  /// Returns true if [prim] is a constant that has no significant runtime cost.
  bool isFastConstant(Primitive prim) {
    return prim is Constant && (prim.value.isPrimitive || prim.value.isDummy);
  }

  /// True if [element] is a final or constant field or a function.
  bool isImmutable(Element element) {
    if (element.isField && backend.isNative(element)) return false;
    return element.isField && world.fieldNeverChanges(element) ||
           element.isFunction;
  }

  bool isImmutableLength(GetLength length) {
    return types.isDefinitelyFixedLengthIndexable(length.object.definition.type,
        allowNull: true);
  }

  /// Assuming [prim] has no side effects, returns true if it can safely
  /// be hoisted out of [loop] without changing its value or changing the timing
  /// of a thrown exception.
  bool canHoistHeapDependencyOutOfLoop(Primitive prim, Continuation loop) {
    // If the primitive might throw, we have to check that it is the first
    // impure expression in the loop.  This has already been checked if
    // [loop] is the current loop header, but for other loops we just give up.
    if (!prim.isSafeForElimination && loop != currentLoopHeader) {
      return false;
    }
    if (prim is GetLength && !isImmutableLength(prim)) {
      return !loopEffects.loopChangesLength(loop);
    } else if (prim is GetField && !isImmutable(prim.field)) {
      return !loopEffects.getSideEffectsInLoop(loop).changesInstanceProperty();
    } else if (prim is GetStatic && !isImmutable(prim.element)) {
      return !loopEffects.getSideEffectsInLoop(loop).changesStaticProperty();
    } else if (prim is GetIndex) {
      return !loopEffects.getSideEffectsInLoop(loop).changesIndex();
    } else {
      return true;
    }
  }

  // ------------------ TRAVERSAL AND EFFECT NUMBERING ---------------------
  //
  // These methods traverse the IR while updating the current effect numbers.
  // They are not specific to GVN.
  //
  // TODO(asgerf): Avoid duplicated code for side effect analysis.
  // Should be easier to fix once primitives and call expressions are the same.

  void addSideEffects(SideEffects fx, {bool length: true}) {
    if (fx.changesInstanceProperty()) {
      effectNumbers.instanceField = makeNewEffect();
    }
    if (fx.changesStaticProperty()) {
      effectNumbers.staticField = makeNewEffect();
    }
    if (fx.changesIndex()) {
      effectNumbers.indexableContent = makeNewEffect();
    }
    if (length && fx.changesIndex()) {
      effectNumbers.indexableLength = makeNewEffect();
    }
  }

  void addAllSideEffects() {
    effectNumbers.instanceField = makeNewEffect();
    effectNumbers.staticField = makeNewEffect();
    effectNumbers.indexableContent = makeNewEffect();
    effectNumbers.indexableLength = makeNewEffect();
  }

  Expression traverseLetHandler(LetHandler node) {
    // Assume any kind of side effects may occur in the try block.
    effectsAt[node.handler] = new EffectNumbers()
      ..instanceField = makeNewEffect()
      ..staticField = makeNewEffect()
      ..indexableContent = makeNewEffect()
      ..indexableLength = makeNewEffect();
    push(node.handler);
    return node.body;
  }

  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    for (Parameter param in cont.parameters) {
      loopHeaderFor[param] = currentLoopHeader;
    }
    if (cont.isRecursive) {
      addSideEffects(loopEffects.getSideEffectsInLoop(cont), length: false);
      if (loopEffects.loopChangesLength(cont)) {
        effectNumbers.indexableLength = makeNewEffect();
      }
      pushAction(() {
        List<int> hoistedBindings = loopHoistedBindings[cont];
        if (hoistedBindings != null) {
          hoistedBindings.forEach(environment.remove);
        }
      });
    } else {
      EffectNumbers join = effectsAt[cont];
      if (join != null) {
        effectNumbers = join;
      } else {
        // This is a call continuation seen immediately after its use.
        // Reuse the current effect numbers.
      }
    }

    return cont.body;
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation.definition;
    if (cont.isRecursive) return;
    EffectNumbers join = effectsAt[cont];
    if (join == null) {
      effectsAt[cont] = effectNumbers.copy();
    } else {
      if (effectNumbers.instanceField != join.instanceField) {
        join.instanceField = makeNewEffect();
      }
      if (effectNumbers.staticField != join.staticField) {
        join.staticField = makeNewEffect();
      }
      if (effectNumbers.indexableContent != join.indexableContent) {
        join.indexableContent = makeNewEffect();
      }
      if (effectNumbers.indexableLength != join.indexableLength) {
        join.indexableLength = makeNewEffect();
      }
    }
  }

  void visitBranch(Branch node) {
    Continuation trueCont = node.trueContinuation.definition;
    Continuation falseCont = node.falseContinuation.definition;
    // Copy the effect number vector once, so the analysis of one branch does
    // not influence the other.
    effectsAt[trueCont] = effectNumbers;
    effectsAt[falseCont] = effectNumbers.copy();
  }

  void visitInvokeMethod(InvokeMethod node) {
    addSideEffects(world.getSideEffectsOfSelector(node.selector, node.mask));
  }

  void visitInvokeStatic(InvokeStatic node) {
    addSideEffects(world.getSideEffectsOfElement(node.target));
  }

  void visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    FunctionElement target = node.target;
    if (target is ConstructorBodyElement) {
      ConstructorBodyElement body = target;
      target = body.constructor;
    }
    addSideEffects(world.getSideEffectsOfElement(target));
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    addSideEffects(world.getSideEffectsOfElement(node.target));
  }

  void visitSetStatic(SetStatic node) {
    effectNumbers.staticField = makeNewEffect();
  }

  void visitSetField(SetField node) {
    effectNumbers.instanceField = makeNewEffect();
  }

  void visitSetIndex(SetIndex node) {
    effectNumbers.indexableContent = makeNewEffect();
  }

  void visitForeignCode(ForeignCode node) {
    addSideEffects(node.nativeBehavior.sideEffects);
  }

  void visitGetLazyStatic(GetLazyStatic node) {
    // TODO(asgerf): How do we get the side effects of a lazy field initializer?
    addAllSideEffects();
  }

  void visitAwait(Await node) {
    addAllSideEffects();
  }

  void visitYield(Yield node) {
    addAllSideEffects();
  }

  void visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    // Push and pop.
    effectNumbers.indexableContent = makeNewEffect();
    effectNumbers.indexableLength = makeNewEffect();
  }
}

/// For each of the four categories of heap locations, the IR is divided into
/// regions wherein the given heap locations are known not to be modified.
///
/// Each region is identified by its "effect number".  Effect numbers from
/// different categories have no relationship to each other.
class EffectNumbers {
  int indexableLength = 0;
  int indexableContent = 0;
  int staticField = 0;
  int instanceField = 0;

  EffectNumbers copy() {
    return new EffectNumbers()
      ..indexableLength = indexableLength
      ..indexableContent = indexableContent
      ..staticField = staticField
      ..instanceField = instanceField;
  }
}

/// Maps vectors to numbers, such that two vectors with the same contents
/// map to the same number.
class GvnTable {
  Map<GvnEntry, int> _table = <GvnEntry, int>{};
  int _usedGvns = 0;
  int _makeNewGvn() => ++_usedGvns;

  int insert(List vector) {
    return _table.putIfAbsent(new GvnEntry(vector), _makeNewGvn);
  }
}

/// Wrapper around a [List] that compares for equality based on contents
/// instead of object identity.
class GvnEntry {
  final List vector;
  final int hashCode;

  GvnEntry(List vector) : vector = vector, hashCode = computeHashCode(vector);

  bool operator==(other) {
    if (other is! GvnEntry) return false;
    GvnEntry entry = other;
    List otherVector = entry.vector;
    if (vector.length != otherVector.length) return false;
    for (int i = 0; i < vector.length; ++i) {
      if (vector[i] != otherVector[i]) return false;
    }
    return true;
  }

  /// Combines the hash codes of [vector] using Jenkin's hash function, with
  /// intermediate results truncated to SMI range.
  static int computeHashCode(List vector) {
    int hash = 0;
    for (int i = 0; i < vector.length; ++i) {
      hash = 0x1fffffff & (hash + vector[i].hashCode);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Converts GVN'able primitives to a vector containing all the values
/// to be considered when computing a GVN for it.
///
/// This includes the instruction type, inputs, effect numbers for any part
/// of the heap being depended on, as well as any instruction-specific payload
/// such as any DartTypes, Elements, and operator kinds.
///
/// Each `visit` or `process` method for a primitive must initialize [vector]
/// if the primitive is GVN'able and fill in any components except the inputs.
/// The inputs will be filled in by [processReference].
class GvnVectorBuilder extends DeepRecursiveVisitor {
  List vector;
  final Map<Primitive, int> gvnFor;
  final Compiler compiler;
  World get world => compiler.world;
  JavaScriptBackend get backend => compiler.backend;
  final TypeMaskSystem types;
  EffectNumbers effectNumbers;

  GvnVectorBuilder(this.gvnFor, this.compiler, this.types);

  List make(Primitive prim, EffectNumbers effectNumbers) {
    this.effectNumbers = effectNumbers;
    vector = null;
    visit(prim);
    return vector;
  }

  /// The `process` methods below do not insert the referenced arguments into
  /// the vector, but instead rely on them being inserted here.
  processReference(Reference ref) {
    if (vector == null) return;
    Primitive prim = ref.definition.effectiveDefinition;
    vector.add(gvnFor[prim] ?? prim);
  }

  processTypeTest(TypeTest node) {
    vector = [GvnCode.TYPE_TEST, node.dartType];
  }

  processTypeTestViaFlag(TypeTestViaFlag node) {
    vector = [GvnCode.TYPE_TEST_VIA_FLAG, node.dartType];
  }

  processApplyBuiltinOperator(ApplyBuiltinOperator node) {
    vector = [GvnCode.BUILTIN_OPERATOR, node.operator.index];
  }

  processGetLength(GetLength node) {
    if (isImmutableLength(node)) {
      // Omit the effect number for fixed-length lists.  Note that if a the list
      // gets refined to a fixed-length type, we still won't be able to GVN a
      // GetLength across the refinement, because the first GetLength uses an
      // effect number in its vector while the second one does not.
      vector = [GvnCode.GET_LENGTH];
    } else {
      vector = [GvnCode.GET_LENGTH, effectNumbers.indexableLength];
    }
  }

  bool isImmutable(Element element) {
    return element.isFunction ||
           element.isField && world.fieldNeverChanges(element);
  }

  bool isImmutableLength(GetLength length) {
    return types.isDefinitelyFixedLengthIndexable(length.object.definition.type,
        allowNull: true);
  }

  bool isNativeField(FieldElement field) {
    // TODO(asgerf): We should add a GetNativeField instruction.
    return backend.isNative(field);
  }

  processGetField(GetField node) {
    if (isNativeField(node.field)) {
      vector = null; // Native field access cannot be GVN'ed.
    } else if (isImmutable(node.field)) {
      vector = [GvnCode.GET_FIELD, node.field];
    } else {
      vector = [GvnCode.GET_FIELD, node.field, effectNumbers.instanceField];
    }
  }

  processGetIndex(GetIndex node) {
    vector = [GvnCode.GET_INDEX, effectNumbers.indexableContent];
  }

  visitGetStatic(GetStatic node) {
    if (isImmutable(node.element)) {
      vector = [GvnCode.GET_STATIC, node.element];
    } else {
      vector = [GvnCode.GET_STATIC, node.element, effectNumbers.staticField];
    }
    // Suppress visit to witness argument.
  }

  processGetLazyStatic(GetLazyStatic node) {
    if (isImmutable(node.element)) {
      vector = [GvnCode.GET_STATIC, node.element];
    } else {
      vector = [GvnCode.GET_STATIC, node.element, effectNumbers.staticField];
    }
  }

  processConstant(Constant node) {
    vector = [GvnCode.CONSTANT, node.value];
  }

  processReifyRuntimeType(ReifyRuntimeType node) {
    vector = [GvnCode.REIFY_RUNTIME_TYPE];
  }

  processReadTypeVariable(ReadTypeVariable node) {
    vector = [GvnCode.READ_TYPE_VARIABLE, node.variable];
  }

  processTypeExpression(TypeExpression node) {
    vector = [GvnCode.TYPE_EXPRESSION, node.dartType];
  }

  processInterceptor(Interceptor node) {
    vector = [GvnCode.INTERCEPTOR];
  }
}

class GvnCode {
  static const int TYPE_TEST = 1;
  static const int TYPE_TEST_VIA_FLAG = 2;
  static const int BUILTIN_OPERATOR = 3;
  static const int GET_LENGTH = 4;
  static const int GET_FIELD = 5;
  static const int GET_INDEX = 6;
  static const int GET_STATIC = 7;
  static const int CONSTANT = 8;
  static const int REIFY_RUNTIME_TYPE = 9;
  static const int READ_TYPE_VARIABLE = 10;
  static const int TYPE_EXPRESSION = 11;
  static const int INTERCEPTOR = 12;
}

typedef ReferenceCallback(Reference ref);
class InputVisitor extends DeepRecursiveVisitor {
  ReferenceCallback callback;

  InputVisitor(this.callback);

  @override
  processReference(Reference ref) {
    callback(ref);
  }

  static void forEach(Primitive node, ReferenceCallback callback) {
    new InputVisitor(callback).visit(node);
  }
}

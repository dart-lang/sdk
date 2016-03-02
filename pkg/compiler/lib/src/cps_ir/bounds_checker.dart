// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.bounds_checker;

import 'cps_ir_nodes.dart';
import 'optimizers.dart' show Pass;
import 'octagon.dart';
import '../constants/values.dart';
import 'cps_fragment.dart';
import 'type_mask_system.dart';
import '../types/types.dart';
import '../world.dart';
import '../elements/elements.dart';
import 'loop_effects.dart';
import 'effects.dart';

/// Eliminates bounds checks when they can be proven safe.
///
/// In general, this pass will try to eliminate any branch with arithmetic
/// in the condition, i.e. `x < y`, `x <= y`, `x == y` etc.
///
/// The analysis uses an [Octagon] abstract domain. Unlike traditional octagon
/// analyzers, we do not use a closed matrix representation, but just maintain
/// a bucket of constraints.  Constraints can therefore be added and removed
/// on-the-fly without significant overhead.
///
/// We never copy the constraint system.  While traversing the IR, the
/// constraint system is mutated to take into account the knowledge that is
/// valid for the current location.  Constraints are added when entering a
/// branch, for instance, and removed again after the branch has been processed.
///
/// Loops are analyzed in two passes. The first pass establishes monotonicity
/// of loop variables, which the second pass uses to compute upper/lower bounds.
///
/// The two-pass scheme is suboptimal compared to a least fixed-point
/// computation, but does not require repeated iteration.  Repeated iteration
/// would be expensive, since we cannot perform a sparse analysis with our
/// mutable octagon representation.
class BoundsChecker extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Bounds checker';

  static const int MAX_UINT32 = (1 << 32) - 1;

  /// All integers of this magnitude or less are representable as JS numbers.
  static const int MAX_SAFE_INT = (1 << 53) - 1;

  /// Marker to indicate that a continuation should get a unique effect number.
  static const int NEW_EFFECT = -1;

  final TypeMaskSystem types;
  final World world;

  /// Fields for the constraint system and its variables.
  final Octagon octagon = new Octagon();
  final Map<Primitive, SignedVariable> valueOf = {};
  final Map<Primitive, Map<int, SignedVariable>> lengthOf = {};

  /// Fields for the two-pass handling of loops.
  final Map<Parameter, Monotonicity> monotonicity = <Parameter, Monotonicity>{};
  bool isStrongLoopPass;
  bool foundLoop = false;

  /// Fields for tracking side effects.
  ///
  /// The IR is divided into regions wherein the lengths of indexable objects
  /// are known not to change. Regions are identified by their "effect number".
  LoopSideEffects loopEffects;
  final Map<Continuation, int> effectNumberAt = <Continuation, int>{};
  int currentEffectNumber = 0;
  int effectNumberCounter = 0;

  BoundsChecker(this.types, this.world);

  void rewrite(FunctionDefinition node) {
    loopEffects = new LoopSideEffects(node, world);
    isStrongLoopPass = false;
    visit(node);
    if (foundLoop) {
      isStrongLoopPass = true;
      effectNumberAt.clear();
      visit(node);
    }
  }

  // ------------- VARIABLES -----------------

  int makeNewEffect() => ++effectNumberCounter;

  bool isInt(Primitive prim) {
    return types.isDefinitelyInt(prim.type);
  }

  bool isUInt32(Primitive prim) {
    return types.isDefinitelyUint32(prim.type);
  }

  bool isNonNegativeInt(Primitive prim) {
    return types.isDefinitelyNonNegativeInt(prim.type);
  }

  /// Get a constraint variable representing the numeric value of [number].
  SignedVariable getValue(Primitive number) {
    number = number.effectiveDefinition;
    int min, max;
    if (isUInt32(number)) {
      min = 0;
      max = MAX_UINT32;
    } else if (isNonNegativeInt(number)) {
      min = 0;
    }
    return valueOf.putIfAbsent(number, () => octagon.makeVariable(min, max));
  }

  /// Get a constraint variable representing the length of [indexableObject] at
  /// program locations with the given [effectNumber].
  SignedVariable getLength(Primitive indexableObject, int effectNumber) {
    indexableObject = indexableObject.effectiveDefinition;
    TypeMask type = indexableObject.type.nonNullable();
    if (types.isDefinitelyFixedLengthIndexable(type)) {
      // Always use the same effect number if the length is immutable.
      effectNumber = 0;
    }
    return lengthOf
        .putIfAbsent(indexableObject, () => <int, SignedVariable>{})
        .putIfAbsent(effectNumber, () {
            int length = types.getContainerLength(type);
            if (length != null) {
              return octagon.makeVariable(length, length);
            } else {
              return octagon.makeVariable(0, MAX_UINT32);
            }
        });
  }

  // ------------- CONSTRAINT HELPERS -----------------

  /// Puts the given constraint "in scope" by adding it to the octagon, and
  /// pushing a stack action that will remove it again.
  void applyConstraint(SignedVariable v1, SignedVariable v2, int k) {
    Constraint constraint = new Constraint(v1, v2, k);
    octagon.pushConstraint(constraint);
    pushAction(() => octagon.popConstraint(constraint));
  }

  /// Return true if we can prove that `v1 + v2 <= k`.
  bool testConstraint(SignedVariable v1, SignedVariable v2, int k) {
    // Add the negated constraint and check for solvability.
    // !(v1 + v2 <= k)   <==>   -v1 - v2 <= -k-1
    Constraint constraint = new Constraint(v1.negated, v2.negated, -k - 1);
    octagon.pushConstraint(constraint);
    bool answer = octagon.isUnsolvable;
    octagon.popConstraint(constraint);
    return answer;
  }

  void makeLessThanOrEqual(SignedVariable v1, SignedVariable v2) {
    // v1 <= v2   <==>   v1 - v2 <= 0
    applyConstraint(v1, v2.negated, 0);
  }

  void makeLessThan(SignedVariable v1, SignedVariable v2) {
    // v1 < v2   <==>   v1 - v2 <= -1
    applyConstraint(v1, v2.negated, -1);
  }

  void makeGreaterThanOrEqual(SignedVariable v1, SignedVariable v2) {
    // v1 >= v2   <==>   v2 - v1 <= 0
    applyConstraint(v2, v1.negated, 0);
  }

  void makeGreaterThan(SignedVariable v1, SignedVariable v2) {
    // v1 > v2   <==>    v2 - v1 <= -1
    applyConstraint(v2, v1.negated, -1);
  }

  void makeLessThanOrEqualToConstant(SignedVariable v1, int k) {
    // v1 + v1 <= 2k
    applyConstraint(v1, v1, 2 * k);
  }

  void makeGreaterThanOrEqualToConstant(SignedVariable v1, int k) {
    // -v1 - v1 <= -2k
    applyConstraint(v1.negated, v1.negated, -2 * k);
  }

  void makeConstant(SignedVariable v1, int k) {
    // We model this using the constraints:
    //    v1 + v1 <=  2k
    //   -v1 - v1 <= -2k
    applyConstraint(v1, v1, 2 * k);
    applyConstraint(v1.negated, v1.negated, -2 * k);
  }

  /// Make `v1 = v2 + k`.
  void makeExactSum(SignedVariable v1, SignedVariable v2, int k) {
    applyConstraint(v1, v2.negated, k);
    applyConstraint(v1.negated, v2, -k);
  }

  /// Make `v1 = v2 [+] k` where [+] represents floating-point addition.
  void makeFloatingPointSum(SignedVariable v1, SignedVariable v2, int k) {
    if (isDefinitelyLessThanOrEqualToConstant(v2, MAX_SAFE_INT - k) &&
        isDefinitelyGreaterThanOrEqualToConstant(v2, -MAX_SAFE_INT + k)) {
      // The result is known to be in the 53-bit range, so no rounding occurs.
      makeExactSum(v1, v2, k);
    } else {
      // A rounding error may occur, so the result may not be exactly v2 + k.
      // We can still add monotonicity constraints:
      //   adding a positive number cannot return a lesser number
      //   adding a negative number cannot return a greater number
      if (k >= 0) {
        // v1 >= v2   <==>   v2 - v1 <= 0   <==>   -v1 + v2 <= 0
        applyConstraint(v1.negated, v2, 0);
      } else {
        // v1 <= v2   <==>   v1 - v2 <= 0
        applyConstraint(v1, v2.negated, 0);
      }
    }
  }

  void makeEqual(SignedVariable v1, SignedVariable v2) {
    // We model this using the constraints:
    //    v1 <= v2   <==>   v1 - v2 <= 0
    //    v1 >= v2   <==>   v2 - v1 <= 0
    applyConstraint(v1, v2.negated, 0);
    applyConstraint(v2, v1.negated, 0);
  }

  void makeNotEqual(SignedVariable v1, SignedVariable v2) {
    // The octagon cannot represent non-equality, but we can sharpen a weak
    // inequality to a sharp one. If v1 and v2 are already known to be equal,
    // this will create a contradiction and eliminate a dead branch.
    // This is necessary for eliminating concurrent modification checks.
    if (isDefinitelyLessThanOrEqualTo(v1, v2)) {
      makeLessThan(v1, v2);
    } else if (isDefinitelyGreaterThanOrEqualTo(v1, v2)) {
      makeGreaterThan(v1, v2);
    }
  }

  /// Return true if we can prove that `v1 <= v2`.
  bool isDefinitelyLessThanOrEqualTo(SignedVariable v1, SignedVariable v2) {
    return testConstraint(v1, v2.negated, 0);
  }

  /// Return true if we can prove that `v1 < v2`.
  bool isDefinitelyLessThan(SignedVariable v1, SignedVariable v2) {
    return testConstraint(v1, v2.negated, -1);
  }

  /// Return true if we can prove that `v1 >= v2`.
  bool isDefinitelyGreaterThanOrEqualTo(SignedVariable v1, SignedVariable v2) {
    return testConstraint(v2, v1.negated, 0);
  }

  bool isDefinitelyLessThanOrEqualToConstant(SignedVariable v1, int value) {
    // v1 <= value   <==>   v1 + v1 <= 2 * value
    return testConstraint(v1, v1, 2 * value);
  }

  bool isDefinitelyGreaterThanOrEqualToConstant(SignedVariable v1, int value) {
    // v1 >= value   <==>   -v1 - v1 <= -2 * value
    return testConstraint(v1.negated, v1.negated, -2 * value);
  }

  // ------------- TAIL EXPRESSIONS -----------------

  @override
  void visitBranch(Branch node) {
    Primitive condition = node.condition;
    Continuation trueCont = node.trueContinuation;
    Continuation falseCont = node.falseContinuation;
    effectNumberAt[trueCont] = currentEffectNumber;
    effectNumberAt[falseCont] = currentEffectNumber;
    pushAction(() {
      // If the branching condition is known statically, either or both of the
      // branch continuations will be replaced by Unreachable. Clean up the
      // branch afterwards.
      if (trueCont.body is Unreachable && falseCont.body is Unreachable) {
        destroyAndReplace(node, new Unreachable());
      } else if (trueCont.body is Unreachable) {
        destroyAndReplace(
            node, new InvokeContinuation(falseCont, <Parameter>[]));
      } else if (falseCont.body is Unreachable) {
        destroyAndReplace(
            node, new InvokeContinuation(trueCont, <Parameter>[]));
      }
    });
    void pushTrue(makeConstraint()) {
      pushAction(() {
        makeConstraint();
        push(trueCont);
      });
    }
    void pushFalse(makeConstraint()) {
      pushAction(() {
        makeConstraint();
        push(falseCont);
      });
    }
    if (condition is ApplyBuiltinOperator &&
        condition.argumentRefs.length == 2 &&
        isInt(condition.argument(0)) &&
        isInt(condition.argument(1))) {
      SignedVariable v1 = getValue(condition.argument(0));
      SignedVariable v2 = getValue(condition.argument(1));
      switch (condition.operator) {
        case BuiltinOperator.NumLe:
          pushTrue(() => makeLessThanOrEqual(v1, v2));
          pushFalse(() => makeGreaterThan(v1, v2));
          return;
        case BuiltinOperator.NumLt:
          pushTrue(() => makeLessThan(v1, v2));
          pushFalse(() => makeGreaterThanOrEqual(v1, v2));
          return;
        case BuiltinOperator.NumGe:
          pushTrue(() => makeGreaterThanOrEqual(v1, v2));
          pushFalse(() => makeLessThan(v1, v2));
          return;
        case BuiltinOperator.NumGt:
          pushTrue(() => makeGreaterThan(v1, v2));
          pushFalse(() => makeLessThanOrEqual(v1, v2));
          return;
        case BuiltinOperator.StrictEq:
          pushTrue(() => makeEqual(v1, v2));
          pushFalse(() => makeNotEqual(v1, v2));
          return;
        case BuiltinOperator.StrictNeq:
          pushTrue(() => makeNotEqual(v1, v2));
          pushFalse(() => makeEqual(v1, v2));
          return;
        default:
      }
    }

    push(trueCont);
    push(falseCont);
  }

  @override
  void visitConstant(Constant node) {
    // TODO(asgerf): It might be faster to inline the constant in the
    //               constraints that reference it.
    if (node.value.isInt) {
      IntConstantValue constant = node.value;
      makeConstant(getValue(node), constant.primitiveValue);
    }
  }

  @override
  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    if (!isInt(node)) return;
    if (node.argumentRefs.length == 1) {
      applyUnaryOperator(node);
    } else if (node.argumentRefs.length == 2) {
      applyBinaryOperator(node);
    }
  }

  void applyBinaryOperator(ApplyBuiltinOperator node) {
    Primitive left = node.argument(0);
    Primitive right = node.argument(1);
    if (!isInt(left) || !isInt(right)) {
      return;
    }
    SignedVariable leftVar = getValue(left);
    SignedVariable rightVar = getValue(right);
    SignedVariable result = getValue(node);
    switch (node.operator) {
      case BuiltinOperator.NumAdd:
        int leftConst = getIntConstant(left);
        if (leftConst != null) {
          makeFloatingPointSum(result, rightVar, leftConst);
        }
        int rightConst = getIntConstant(right);
        if (rightConst != null) {
          makeFloatingPointSum(result, leftVar, rightConst);
        }
        // Attempt to compute the sign of the result.
        // TODO(asgerf): Compute upper/lower bounds instead of using 0.
        if (testConstraint(leftVar, rightVar, 0)) {
          makeLessThanOrEqualToConstant(result, 0);
        }
        if (testConstraint(leftVar.negated, rightVar.negated, 0)) {
          makeGreaterThanOrEqualToConstant(result, 0);
        }
        // Classical octagon-based analyzers would compute upper and lower
        // bounds for the two operands and add constraints for the result based
        // on those.  For performance reasons we only compute the sign
        // TODO(asgerf): It seems expensive, but we should evaluate it.
        break;

      case BuiltinOperator.NumSubtract:
        int leftConst = getIntConstant(left);
        if (leftConst != null) {
          // result = leftConst - right = (-right) + leftConst
          makeFloatingPointSum(result, rightVar.negated, leftConst);
        }
        int rightConst = getIntConstant(right);
        if (rightConst != null) {
          // result = left - rightConst = left + (-rightConst)
          makeFloatingPointSum(result, leftVar, -rightConst);
        }
        // Attempt to compute the sign of the result.
        if (isDefinitelyGreaterThanOrEqualTo(leftVar, rightVar)) {
          makeGreaterThanOrEqualToConstant(result, 0);
        }
        if (isDefinitelyLessThanOrEqualTo(leftVar, rightVar)) {
          makeLessThanOrEqualToConstant(result, 0);
        }
        break;

      case BuiltinOperator.NumTruncatingDivideToSigned32:
        if (isDefinitelyGreaterThanOrEqualToConstant(leftVar, 0)) {
          // If we divide by a positive number, the result is closer to zero.
          // If we divide by a negative number, the result is negative, and
          // thus less than the original (non-negative) number.
          // TODO(asgerf): The divisor is currently always positive, because
          // type propagation checks that, but we could do better.
          makeLessThanOrEqual(result, leftVar);
        }
        break;

      case BuiltinOperator.NumShr:
        if (isDefinitelyGreaterThanOrEqualToConstant(leftVar, 0)) {
          makeLessThanOrEqual(result, leftVar);
        }
        int shiftAmount = getIntConstant(right);
        if (shiftAmount != null) {
          // TODO(asgerf): Compute upper bound on [leftVar] and use that
          // instead of MAX_UINT32.
          makeLessThanOrEqualToConstant(result, MAX_UINT32 >> shiftAmount);
        }
        break;

      case BuiltinOperator.NumRemainder:
        // TODO(asgerf): This check overlaps with checks performed in a type
        //   propagation transformation, and we can do it more precisely here.
        //   Should we do the rewrite here?
        if (isDefinitelyGreaterThanOrEqualToConstant(leftVar, 0) &&
            isDefinitelyGreaterThanOrEqualToConstant(rightVar, 1)) {
          makeLessThanOrEqual(result, leftVar);
          makeLessThan(result, rightVar);
        }
        break;

      case BuiltinOperator.NumAnd:
        // We use the faster UInt32 check instead of constraint based checks
        // here, because the common case is that one operand is a constant.
        if (isUInt32(left)) {
          makeLessThanOrEqual(result, leftVar);
        }
        if (isUInt32(right)) {
          makeLessThanOrEqual(result, rightVar);
        }
        break;

      default:
    }
  }

  void applyUnaryOperator(ApplyBuiltinOperator node) {
    Primitive argument = node.argument(0);
    if (!isInt(argument)) return;
    if (node.operator == BuiltinOperator.NumNegate) {
      valueOf[node] = getValue(argument).negated;
    }
  }

  int getIntConstant(Primitive prim) {
    if (prim is Constant && prim.value.isInt) {
      IntConstantValue constant = prim.value;
      return constant.primitiveValue;
    }
    return null;
  }

  @override
  void visitRefinement(Refinement node) {
    // In general we should get the container length of the refined type and
    // add a constraint if we know the length after the refinement.
    // However, our current type system removes container information when a
    // type becomes part of a union, so this cannot happen.
  }

  @override
  void visitGetLength(GetLength node) {
    valueOf[node] = getLength(node.object, currentEffectNumber);
  }

  @override
  void visitBoundsCheck(BoundsCheck node) {
    if (node.checks == BoundsCheck.NONE) return;
    assert(node.indexRef != null); // Because there is at least one check.
    SignedVariable length = node.lengthRef == null
        ? null
        : getValue(node.length);
    SignedVariable index = getValue(node.index);
    if (node.hasUpperBoundCheck) {
      if (isDefinitelyLessThan(index, length)) {
        node.checks &= ~BoundsCheck.UPPER_BOUND;
      } else {
        makeLessThan(index, length);
      }
    }
    if (node.hasLowerBoundCheck) {
      if (isDefinitelyGreaterThanOrEqualToConstant(index, 0)) {
        node.checks &= ~BoundsCheck.LOWER_BOUND;
      } else {
        makeGreaterThanOrEqualToConstant(index, 0);
      }
    }
    if (node.hasEmptinessCheck) {
      if (isDefinitelyGreaterThanOrEqualToConstant(length, 1)) {
        node.checks &= ~BoundsCheck.EMPTINESS;
      } else {
        makeGreaterThanOrEqualToConstant(length, 1);
      }
    }
    if (!node.lengthUsedInCheck && node.lengthRef != null) {
      node..lengthRef.unlink()..lengthRef = null;
    }
    if (node.checks == BoundsCheck.NONE) {
      // We can't remove the bounds check node because it may still be used to
      // restrict code motion.  But the index is no longer needed.
      node..indexRef.unlink()..indexRef = null;
    }
  }

  void analyzeLoopEntry(InvokeContinuation node) {
    foundLoop = true;
    Continuation cont = node.continuation;
    if (isStrongLoopPass) {
      for (int i = 0; i < node.argumentRefs.length; ++i) {
        Parameter param = cont.parameters[i];
        if (!isInt(param)) continue;
        Primitive initialValue = node.argument(i);
        SignedVariable initialVariable = getValue(initialValue);
        Monotonicity mono = monotonicity[param];
        if (mono == null) {
          // Value never changes. This is extremely uncommon.
          param.replaceUsesWith(initialValue);
        } else if (mono == Monotonicity.Increasing) {
          makeGreaterThanOrEqual(getValue(param), initialVariable);
        } else if (mono == Monotonicity.Decreasing) {
          makeLessThanOrEqual(getValue(param), initialVariable);
        }
      }
    }
    if (loopEffects.changesIndexableLength(cont)) {
      currentEffectNumber = effectNumberAt[cont] = makeNewEffect();
    }
    push(cont);
  }

  void analyzeLoopContinue(InvokeContinuation node) {
    Continuation cont = node.continuation;

    // During the strong loop phase, there is no need to compute monotonicity,
    // and we already put bounds on the loop variables when we went into the
    // loop.
    if (isStrongLoopPass) return;

    // For each loop parameter, try to prove that the new value is definitely
    // less/greater than its old value. When we fail to prove this, update the
    // monotonicity flag accordingly.
    for (int i = 0; i < node.argumentRefs.length; ++i) {
      Parameter param = cont.parameters[i];
      if (!isInt(param)) continue;
      SignedVariable arg = getValue(node.argument(i));
      SignedVariable paramVar = getValue(param);
      if (!isDefinitelyLessThanOrEqualTo(arg, paramVar)) {
        // We couldn't prove that the value does not increase, so assume
        // henceforth that it might be increasing.
        markMonotonicity(cont.parameters[i], Monotonicity.Increasing);
      }
      if (!isDefinitelyGreaterThanOrEqualTo(arg, paramVar)) {
        // We couldn't prove that the value does not decrease, so assume
        // henceforth that it might be decreasing.
        markMonotonicity(cont.parameters[i], Monotonicity.Decreasing);
      }
    }
  }

  void markMonotonicity(Parameter param, Monotonicity mono) {
    Monotonicity current = monotonicity[param];
    if (current == null) {
      monotonicity[param] = mono;
    } else if (current != mono) {
      monotonicity[param] = Monotonicity.NotMonotone;
    }
  }

  @override
  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation;
    if (node.isRecursive) {
      analyzeLoopContinue(node);
    } else if (cont.isRecursive) {
      analyzeLoopEntry(node);
    } else {
      int effect = effectNumberAt[cont];
      if (effect == null) {
        effectNumberAt[cont] = currentEffectNumber;
      } else if (effect != currentEffectNumber && effect != NEW_EFFECT) {
        effectNumberAt[cont] = NEW_EFFECT;
      }
      // TODO(asgerf): Compute join for parameters to increase precision?
    }
  }

  // ---------------- PRIMITIVES --------------------

  @override
  Expression traverseLetPrim(LetPrim node) {
    visit(node.primitive);
    // visitApplyBuiltinMethod updates the effect number.
    if (node.primitive is! ApplyBuiltinMethod) {
      if (node.primitive.effects & Effects.changesIndexableLength != 0) {
        currentEffectNumber = makeNewEffect();
      }
    }
    return node.body;
  }

  @override
  void visitInvokeMethod(InvokeMethod node) {
    if (node.selector.isGetter && node.selector.name == 'length') {
      // If the receiver type is not known to be indexable, the length call
      // was not rewritten to GetLength.  But if we can prove that the call only
      // succeeds for indexables, we can trust that it returns the length.
      TypeMask successType =
          types.receiverTypeFor(node.selector, node.dartReceiver.type);
      if (types.isDefinitelyIndexable(successType)) {
        valueOf[node] = getLength(node.dartReceiver, currentEffectNumber);
      }
    }
  }

  @override
  void visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    Primitive receiver = node.receiver;
    int effectBefore = currentEffectNumber;
    currentEffectNumber = makeNewEffect();
    int effectAfter = currentEffectNumber;
    SignedVariable lengthBefore = getLength(receiver, effectBefore);
    SignedVariable lengthAfter = getLength(receiver, effectAfter);
    switch (node.method) {
      case BuiltinMethod.Push:
        // after = before + count
        int count = node.argumentRefs.length;
        makeExactSum(lengthAfter, lengthBefore, count);
        break;

      case BuiltinMethod.Pop:
        // after = before - 1
        makeExactSum(lengthAfter, lengthBefore, -1);
        break;

      case BuiltinMethod.SetLength:
        makeEqual(lengthAfter, getValue(node.argument(0)));
        break;
    }
  }

  @override
  void visitLiteralList(LiteralList node) {
    makeConstant(getLength(node, currentEffectNumber), node.valueRefs.length);
  }

  // ---------------- INTERIOR EXPRESSIONS --------------------

  @override
  Expression traverseContinuation(Continuation cont) {
    if (octagon.isUnsolvable) {
      destroyAndReplace(cont.body, new Unreachable());
    } else {
      int effect = effectNumberAt[cont];
      if (effect != null) {
        currentEffectNumber = effect == NEW_EFFECT ? makeNewEffect() : effect;
      }
    }
    return cont.body;
  }

  @override
  Expression traverseLetCont(LetCont node) {
    // Join continuations should be pushed at declaration-site, so all their
    // call sites are seen before they are analyzed.
    // Other continuations are pushed at the use site.
    for (Continuation cont in node.continuations) {
      if (cont.hasAtLeastOneUse &&
          !cont.isRecursive &&
          cont.firstRef.parent is InvokeContinuation) {
        push(cont);
      }
    }
    return node.body;
  }
}

/// Lattice representing the known (weak) monotonicity of a loop variable.
///
/// The lattice bottom is represented by `null` and represents the case where
/// the loop variable never changes value during the loop.
enum Monotonicity { NotMonotone, Increasing, Decreasing, }

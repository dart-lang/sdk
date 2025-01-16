// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../options.dart';
import '../universe/selector.dart' show Selector;
import 'codegen.dart' show CodegenPhase;
import 'nodes.dart';

/// Returns `true` if the invocation of [selector] on [member] can use an
/// aliased member.
///
/// Invoking a super getter isn't supported, this would require changes to
/// compact field descriptors in the emitter.
bool canUseAliasedSuperMember(MemberEntity member, Selector selector) {
  return !selector.isGetter;
}

/// Replaces some instructions with specialized versions to make codegen easier.
///
/// - Caches codegen information on nodes.
///
/// - Remove NullChecks where the next instruction would fail on the operand.
///
/// - Combine read/modify/write sequences into HReadModifyWrite instructions to
///   simplify codegen of expressions like `a.x += y`.
class SsaInstructionSelection extends HBaseVisitor<HInstruction?>
    implements CodegenPhase {
  @override
  String get name => 'SsaInstructionSelection';

  final JClosedWorld _closedWorld;
  final CompilerOptions _options;
  late final HGraph graph;

  SsaInstructionSelection(this._options, this._closedWorld);

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  @override
  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.first;
    while (instruction != null) {
      HInstruction? next = instruction.next;
      HInstruction? replacement = instruction.accept(this);
      if (replacement != instruction && replacement != null) {
        node.rewrite(instruction, replacement);

        // If the replacement instruction does not know its source element, use
        // the source element of the instruction.
        replacement.sourceElement ??= instruction.sourceElement;
        replacement.sourceInformation ??= instruction.sourceInformation;

        if (!replacement.isInBasicBlock()) {
          // The constant folding can return an instruction that is already
          // part of the graph (like an input), so we only add the replacement
          // if necessary.
          node.addAfter(instruction, replacement);
          // Visit the replacement as the next instruction in case it can also
          // be constant folded away.
          next = replacement;
        }
        node.remove(instruction);
      }
      instruction = next;
    }
  }

  @override
  HInstruction visitInstruction(HInstruction instruction) {
    return instruction;
  }

  @override
  HInstruction visitNullCheck(HNullCheck node) {
    // If we remove this NullCheck, does the program behave the same?
    HInstruction? faultingInstruction = _followingSameFaultInstruction(node);
    if (faultingInstruction != null) {
      // Force [faultingInstruction] to appear in same source location as
      // [node]. This avoids the source-mapped stack trace containing an
      // impossible location inside an inlined instance method called on `null`.
      // TODO(36841): Implement for instance method calls.
      if (faultingInstruction is HFieldGet ||
          faultingInstruction is HFieldSet ||
          faultingInstruction is HGetLength) {
        faultingInstruction.sourceInformation = node.sourceInformation;
      }
      return node.checkedInput;
    }
    return node;
  }

  /// Searches the instructions following [nullCheck] to see if the first
  /// instruction with an effect or exception will fault on a `null` input just
  /// like the [nullCheck].
  HInstruction? _followingSameFaultInstruction(HNullCheck nullCheck) {
    HInstruction? current = nullCheck.next;
    do {
      // The instructionType of [nullCheck] is not nullable (since it is the
      // (not) null check!) This means that if we do need to check the type, we
      // should test against nullCheck.checkedInput, not the direct input.
      if (current!.getDartReceiver(_closedWorld) == nullCheck) {
        if (current is HFieldGet) return current;
        if (current is HFieldSet) return current;
        if (current is HGetLength) return current;
        if (current is HIndex) return current;
        if (current is HIndexAssign) return current;
        if (current is HInvokeDynamic) {
          HInstruction receiver = current.receiver;
          // Either no interceptor or self-interceptor:
          if (receiver == nullCheck) return current;
          return null;
        }
      }

      if (current is HInvokeExternal) {
        if (current.isNullGuardFor(nullCheck)) return current;
      }
      if (current is HForeignCode) {
        if (current.isNullGuardFor(nullCheck)) return current;
      }

      // TODO(sra): Recognize other usable faulting patterns:
      //
      //  - HInstanceEnvironment when the generated code is `receiver.$ti`.
      //
      //  - super-calls using aliases.
      //
      //  - one-shot interceptor receiver for selector not defined on
      //    null. The fault will appear to happen in the one-shot
      //    interceptor.
      //
      //  - a constant interceptor can be replaced with a conditional
      //    HInterceptor (e.g. (a && JSArray_methods).get$first(a)).

      if (current.canThrow(_abstractValueDomain) ||
          current.sideEffects.hasSideEffects()) {
        return null;
      }

      HInstruction? next = current.next;
      if (next == null) {
        // We do not merge blocks in our SSA graph, so if this block just jumps
        // to a single successor, visit the successor, avoiding back-edges.
        HBasicBlock? successor;
        if (current is HGoto) {
          successor = current.block!.successors.single;
        } else if (current is HIf) {
          // We also leave HIf nodes in place when one branch is dead.
          HInstruction condition = current.inputs.first;
          if (condition is HConstant) {
            successor =
                condition.constant is TrueConstantValue
                    ? current.thenBlock
                    : current.elseBlock;
          }
        }
        if (successor != null && successor.id > current.block!.id) {
          next = successor.first;
        }
      }
      current = next;
    } while (current != null);
    return null;
  }

  @override
  HInstruction visitIdentity(HIdentity node) {
    node.singleComparisonOp = simpleOp(node.left, node.right);
    return node;
  }

  /// Returns the single JavaScript comparison (`==` or `===`) if that
  /// implements `identical(left, right)`, or returns `null` if the more complex
  /// ternary `left == null ? right == null : left === right` is required.
  String? simpleOp(HInstruction left, HInstruction right) {
    AbstractValue leftType = left.instructionType;
    AbstractValue rightType = right.instructionType;
    if (_abstractValueDomain.isNull(leftType).isDefinitelyFalse) {
      return '===';
    }
    if (_abstractValueDomain.isNull(rightType).isDefinitelyFalse) {
      return '===';
    }

    // Dart `null` is implemented by JavaScript `null` and `undefined` which are
    // not strict-equals, so we can't use `===`. We would like to use `==` but
    // need to avoid any cases from ES6 7.2.14 that involve conversions.
    if (_abstractValueDomain.isNull(leftType).isDefinitelyTrue ||
        _abstractValueDomain.isNull(rightType).isDefinitelyTrue) {
      return '==';
    }

    if (_abstractValueDomain.isNumberOrNull(leftType).isDefinitelyTrue &&
        _abstractValueDomain.isNumberOrNull(rightType).isDefinitelyTrue) {
      return '==';
    }
    if (_abstractValueDomain.isStringOrNull(leftType).isDefinitelyTrue &&
        _abstractValueDomain.isStringOrNull(rightType).isDefinitelyTrue) {
      return '==';
    }
    if (_abstractValueDomain.isBooleanOrNull(leftType).isDefinitelyTrue &&
        _abstractValueDomain.isBooleanOrNull(rightType).isDefinitelyTrue) {
      return '==';
    }

    if (_intercepted(leftType)) return null;
    if (_intercepted(rightType)) return null;
    return '==';
  }

  // ToPrimitive conversions of an object occur when the other operand is a
  // primitive (Number, String, Symbol and, indirectly, Boolean). We use
  // 'intercepted' types as a proxy for all the primitive types.
  bool _intercepted(AbstractValue type) =>
      _abstractValueDomain
          .isInterceptor(_abstractValueDomain.excludeNull(type))
          .isPotentiallyTrue;

  @override
  HBinaryBitOp visitBinaryBitOp(HBinaryBitOp node) {
    node.requiresUintConversion = _requiresUintConversion(node);
    return node;
  }

  @override
  HShiftRight visitShiftRight(HShiftRight node) {
    // HShiftRight is JavaScript's `>>>` operation so result is always unsigned.
    node.requiresUintConversion = false;
    return node;
  }

  @override
  HBitNot visitBitNot(HBitNot node) {
    node.requiresUintConversion = _requiresUintConversion(node);
    return node;
  }

  bool _requiresUintConversion(HInstruction node) {
    if (node.isUInt31(_abstractValueDomain).isDefinitelyTrue) return false;
    if (_bitWidth(node) <= 31) return false;
    // JavaScript bitwise operations generally interpret the input as a signed
    // 32-bit value, so the conversion to an unsigned value may be avoided if
    // the value is used only by bitwise operations.
    return _hasNonBitOpUser(node, <HPhi>{});
  }

  Map<HInstruction, int>? _bitWidthCache;
  static const int _max = 32;

  /// Returns the number of bits occupied by the value computed by the
  /// [instruction].  Returns `32`(_MAX) if the value is negative or does not
  /// fit as an unsigned integer in a smaller number of bits.
  //
  // TODO(sra): Consider making the conversion an explicit new HToUint32
  // instruction and make HBitAdd be the pure JavaScript signed 32-bit
  // operation. Lower `a.&(b)` to `HToUint32(HBitAnd(a, b))`. This will require
  // reworking optimizations that recognize bit operations.
  int _bitWidth(HInstruction instruction) {
    int? value = _constantInt(instruction);
    if (value != null) {
      if (value < 0) return _max;
      if (value > ((1 << 31) - 1)) return _max;
      return value.bitLength;
    }

    // For instructions other than constants the width is cached.
    return (_bitWidthCache ??= {})[instruction] ??= _computeBitWidth(
      instruction,
    );
  }

  int _computeBitWidth(HInstruction instruction) {
    if (instruction is HBitAnd) {
      return math.min(
        _bitWidth(instruction.left),
        _bitWidth(instruction.right),
      );
    }
    if (instruction is HBitOr) {
      int leftWidth = _bitWidth(instruction.left);
      if (leftWidth == _max) return _max;
      return math.max(leftWidth, _bitWidth(instruction.right));
    }
    if (instruction is HBitXor) {
      int leftWidth = _bitWidth(instruction.left);
      if (leftWidth == _max) return _max;
      return math.max(leftWidth, _bitWidth(instruction.right));
    }
    if (instruction is HShiftLeft) {
      int? shiftCount = _constantInt(instruction.right);
      if (shiftCount == null || shiftCount < 0 || shiftCount > 31) {
        return _max;
      }
      int leftWidth = _bitWidth(instruction.left);
      int width = leftWidth + shiftCount;
      return math.min(width, _max);
    }
    if (instruction is HShiftRight) {
      int? shiftCount = _constantInt(instruction.right);
      if (shiftCount == null || shiftCount < 0 || shiftCount > 31) return _max;
      int leftWidth = _bitWidth(instruction.left);
      if (leftWidth >= _max) return _max;
      return math.max(leftWidth - shiftCount, 0);
    }
    if (instruction is HAdd) {
      return math.min(
        1 + math.max(_bitWidth(instruction.left), _bitWidth(instruction.right)),
        _max,
      );
    }
    if (instruction.isUInt31(_abstractValueDomain).isDefinitelyTrue) return 31;
    return _max;
  }

  int? _constantInt(HInstruction instruction) {
    if (instruction is HConstant) {
      ConstantValue constant = instruction.constant;
      if (constant is IntConstantValue && constant.intValue.isValidInt) {
        return constant.intValue.toInt();
      }
    }
    return null;
  }

  bool _hasNonBitOpUser(HInstruction instruction, Set<HPhi> phiSet) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HPhi) {
        if (!phiSet.contains(user)) {
          phiSet.add(user);
          if (_hasNonBitOpUser(user, phiSet)) return true;
        }
      } else if (user is! HBitNot && user is! HBinaryBitOp) {
        return true;
      }
    }
    return false;
  }

  @override
  HInstruction? visitFieldSet(HFieldSet node) {
    // Pattern match
    //     t1 = x.f; t2 = t1 + 1; x.f = t2; use(t2)   -->  ++x.f
    //     t1 = x.f; t2 = t1 op y; x.f = t2; use(t2)  -->  x.f op= y
    //     t1 = x.f; t2 = t1 + 1; x.f = t2; use(t1)   -->  x.f++
    HBasicBlock block = node.block!;
    HInstruction op = node.value;
    HInstruction receiver = node.receiver;

    bool isMatchingRead(HInstruction candidate) {
      if (candidate is HFieldGet) {
        if (candidate.element != node.element) return false;
        if (candidate.receiver != node.receiver) return false;
        // Recognize only three instructions in sequence in the same block. This
        // could be broadened to allow non-interfering interleaved instructions.
        if (op.block != block) return false;
        if (candidate.block != block) return false;
        if (node.previous != op) return false;
        if (op.previous != candidate) return false;
        return true;
      }
      return false;
    }

    HInstruction? noMatchingRead() {
      // If we have other HFieldSet optimizations, they go here.
      return null;
    }

    HInstruction? replaceOp(HInstruction replacement, HInstruction getter) {
      block.addBefore(node, replacement);
      block.remove(node);
      block.rewrite(op, replacement);
      block.remove(op);
      block.remove(getter);
      return null;
    }

    HInstruction? plusOrMinus(
      String assignOp,
      String incrementOp,
      HInstruction left,
      HInstruction right,
    ) {
      if (isMatchingRead(left)) {
        if (left.usedBy.length == 1) {
          if (right is HConstant && right.constant.isOne) {
            HInstruction rmw = HReadModifyWrite.preOp(
              node.element,
              incrementOp,
              receiver,
              op.instructionType,
            );
            return replaceOp(rmw, left);
          } else {
            HInstruction rmw = HReadModifyWrite.assignOp(
              node.element,
              assignOp,
              receiver,
              right,
              op.instructionType,
            );
            return replaceOp(rmw, left);
          }
        } else if (op.usedBy.length == 1 &&
            right is HConstant &&
            right.constant.isOne) {
          HInstruction rmw = HReadModifyWrite.postOp(
            node.element,
            incrementOp,
            receiver,
            op.instructionType,
          );
          block.addAfter(left, rmw);
          block.remove(node);
          block.remove(op);
          block.rewrite(left, rmw);
          block.remove(left);
          return null;
        }
      }
      return noMatchingRead();
    }

    HInstruction? simple(
      String assignOp,
      HInstruction left,
      HInstruction right,
    ) {
      if (isMatchingRead(left)) {
        if (left.usedBy.length == 1) {
          HInstruction rmw = HReadModifyWrite.assignOp(
            node.element,
            assignOp,
            receiver,
            right,
            op.instructionType,
          );
          return replaceOp(rmw, left);
        }
      }
      return noMatchingRead();
    }

    HInstruction? bitop(String assignOp, HBinaryBitOp binary) {
      // HBitAnd, HBitOr etc. are more difficult because HBitAnd(a.x, y)
      // sometimes needs to be forced to unsigned: a.x = (a.x & y) >>> 0.
      if (!binary.requiresUintConversion) {
        return simple(assignOp, binary.left, binary.right);
      }
      return noMatchingRead();
    }

    if (op is HAdd) return plusOrMinus('+', '++', op.left, op.right);
    if (op is HSubtract) return plusOrMinus('-', '--', op.left, op.right);

    if (op is HStringConcat) return simple('+', op.left, op.right);

    if (op is HMultiply) return simple('*', op.left, op.right);
    if (op is HDivide) return simple('/', op.left, op.right);

    if (op is HBitAnd) return bitop('&', op);
    if (op is HBitOr) return bitop('|', op);
    if (op is HBitXor) return bitop('^', op);

    return noMatchingRead();
  }

  @override
  HIf visitIf(HIf node) {
    if (!_options.experimentToBoolean) return node;
    HInstruction condition = node.inputs.single;
    // if (x != null) --> if (x)
    if (condition is HNot) {
      HInstruction test = condition.inputs.single;
      if (test is HIdentity) {
        HInstruction operand1 = test.inputs[0];
        HInstruction operand2 = test.inputs[1];
        if (operand2.isNull(_abstractValueDomain).isDefinitelyTrue &&
            !_intercepted(operand1.instructionType)) {
          if (test.usedBy.length == 1 && condition.usedBy.length == 1) {
            node.changeUse(condition, operand1);
            condition.block!.remove(condition);
            test.block!.remove(test);
          }
        }
      }
    }
    // if (x == null) => if (!x)
    if (condition is HIdentity && condition.usedBy.length == 1) {
      HInstruction operand1 = condition.inputs[0];
      HInstruction operand2 = condition.inputs[1];
      if (operand2.isNull(_abstractValueDomain).isDefinitelyTrue &&
          !_intercepted(operand1.instructionType)) {
        var not = HNot(operand1, _abstractValueDomain.boolType);
        node.block!.addBefore(node, not);
        node.changeUse(condition, not);
        condition.block!.remove(condition);
      }
    }
    return node;
  }
}

/// Remove [HTypeKnown] instructions from the graph, to make codegen analysis
/// easier.
class SsaTypeKnownRemover extends HBaseVisitor<void> implements CodegenPhase {
  @override
  String get name => 'SsaTypeKnownRemover';

  @override
  void visitGraph(HGraph graph) {
    // Visit bottom-up to visit uses before instructions and capture refined
    // input types.
    visitPostDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.last;
    while (instruction != null) {
      HInstruction? previous = instruction.previous;
      instruction.accept(this);
      instruction = previous;
    }
  }

  @override
  void visitTypeKnown(HTypeKnown node) {
    node.block!.rewrite(node, node.checkedInput);
    node.block!.remove(node);
  }

  @override
  void visitInstanceEnvironment(HInstanceEnvironment node) {
    node.codegenInputType = node.inputs.single.instructionType;
  }
}

/// Remove [HPrimitiveCheck] instructions from the graph in '--trust-primitives'
/// mode.
class SsaTrustedPrimitiveCheckRemover extends HBaseVisitor<void>
    implements CodegenPhase {
  @override
  String get name => 'SsaTrustedPrimitiveCheckRemover';

  final CompilerOptions _options;

  SsaTrustedPrimitiveCheckRemover(this._options);

  @override
  void visitGraph(HGraph graph) {
    if (!_options.trustPrimitives) return;
    visitDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.first;
    while (instruction != null) {
      HInstruction? next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  @override
  void visitPrimitiveCheck(HPrimitiveCheck node) {
    node.block!.rewrite(node, node.checkedInput);
    node.block!.remove(node);
  }

  @override
  void visitBoolConversion(HBoolConversion node) {
    node.block!.rewrite(node, node.checkedInput);
    node.block!.remove(node);
  }
}

/// Remove trusted late variable checks.
class SsaTrustedLateCheckRemover extends HBaseVisitor<void>
    implements CodegenPhase {
  @override
  String get name => 'SsaInstructionSelection';

  final AbstractValueDomain _abstractValueDomain;

  SsaTrustedLateCheckRemover(this._abstractValueDomain);

  @override
  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.first;
    while (instruction != null) {
      HInstruction? next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  @override
  void visitLateCheck(HLateCheck node) {
    if (!node.isTrusted) return;
    final inputs = node.inputs.toList();
    node.block!.rewrite(node, node.checkedInput);
    node.block!.remove(node);
    // TODO(sra): There might be a unused name.

    // Remove pure unused inputs.
    for (HInstruction input in inputs) {
      if (input.usedBy.isNotEmpty) continue;
      HBasicBlock? block = input.block;
      if (block == null) continue; // Already removed.
      if (input.isPure(_abstractValueDomain)) {
        // Special cases that are removed properly by other phases.
        if (input is HParameterValue) continue;
        if (input is HLocalValue) continue;
        if (input is HPhi) continue;
        block.remove(input);
        continue;
      }
      if (input is HFieldGet) {
        if (input.canThrow(_abstractValueDomain)) continue;
        block.remove(input);
      }
    }
  }
}

/// Use the result of static and field assignments where it is profitable to use
/// the result of the assignment instead of the value.
///
///     a.x = v;
///     b.y = v;
/// -->
///     b.y = a.x = v;
class SsaAssignmentChaining extends HBaseVisitor<HInstruction?>
    implements CodegenPhase {
  @override
  String get name => 'SsaAssignmentChaining';

  final JClosedWorld _closedWorld;

  SsaAssignmentChaining(this._closedWorld);

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  @override
  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.first;
    while (instruction != null) {
      instruction = instruction.accept<HInstruction?>(this);
    }
  }

  /// Returns the next instruction.
  @override
  HInstruction? visitInstruction(HInstruction node) {
    return node.next;
  }

  @override
  HInstruction? visitFieldSet(HFieldSet node) {
    return tryChainAssignment(node, node.value);
  }

  @override
  HInstruction? visitStaticStore(HStaticStore node) {
    return tryChainAssignment(node, node.inputs.single);
  }

  HInstruction? tryChainAssignment(HInstruction setter, HInstruction value) {
    // Try to use result of field or static assignment
    //
    //     t1 = v;  x.f = t1;  ... t1 ...
    // -->
    //     t1 = x.f = v;  ... t1 ...
    //

    // Single use is this setter so there will be no other uses to chain to.
    if (value.usedBy.length <= 1) return setter.next;

    // It is always worthwhile chaining into another setter, since it reduces
    // the number of references to [value].
    HInstruction chain = setter;
    setter.instructionType = value.instructionType;
    for (HInstruction? current = setter.next; ;) {
      if (current is HFieldSet) {
        HFieldSet nextSetter = current;
        if (nextSetter.value == value && nextSetter.receiver != value) {
          nextSetter.changeUse(value, chain);
          nextSetter.instructionType = value.instructionType;
          chain = nextSetter;
          current = nextSetter.next;
          continue;
        }
      } else if (current is HStaticStore) {
        HStaticStore nextStore = current;
        if (nextStore.value == value) {
          nextStore.changeUse(value, chain);
          nextStore.instructionType = value.instructionType;
          chain = nextStore;
          current = nextStore.next;
          continue;
        }
      } else if (current is HReturn) {
        if (current.inputs.isNotEmpty && current.inputs.single == value) {
          current.changeUse(value, chain);
          return current.next;
        }
      }
      break;
    }

    final HInstruction? next = chain.next;

    if (value.usedBy.length <= 1) return next; // setter is only remaining use.

    // Chain to other places.
    var uses = DominatedUses.of(value, chain, excludeDominator: true);

    if (uses.isEmpty) return next;

    bool simpleSource = value is HConstant || value is HParameterValue;

    if (uses.isSingleton) {
      var use = uses.single;
      if (use is HPhi) {
        // Filter out back-edges - that causes problems for variable
        // assignment.
        // TODO(sra): Better analysis to permit phis that are part of a
        // forwards-only tree.
        if (use.block!.id < chain.block!.id) return next;
        if (use.usedBy.any((node) => node is HPhi)) return next;

        // A forward phi often has a new name. We want to avoid [value] having a
        // name at the same time, so chain into the phi only if [value] (1) will
        // never have a name (like a constant) (2) unavoidably has a name
        // (e.g. a parameter) or (3) chaining will result in a single use that
        // variable allocator can try to name consistently with the other phi
        // inputs.
        if (simpleSource || value.usedBy.length <= 2) {
          if (value.isPure(_abstractValueDomain) ||
              setter.previous == value ||
              // the following tests for immediately previous phi.
              (setter.previous == null && value.block == setter.block)) {
            uses.replaceWith(chain);
          }
        }
        return next;
      }
      // TODO(sra): Chains with one remaining potential use have the potential
      // to generate huge expression containing many nested assignments. This
      // will be smaller but nearly impossible to read. Are there interior
      // positions that we should chain into because they are not too difficult
      // to read?
      return next;
    }

    if (simpleSource) return next;

    // If there are many remaining uses, but they are all dominated by [chain],
    // the variable allocator will try to give them all the same name.
    if (uses.length >= 2 &&
        value.usedBy.length - uses.length <= 1 &&
        value == value.nonCheck()) {
      // If [value] is a phi, it might have a name. Exceptions are phis that can
      // be compiled into expressions like `a?b:c` and `a&&b`. We can't tell
      // here if the phi is an expression, which we could chain, or an
      // if-then-else with assignments to a variable. If we try to chain an
      // if-then-else phi we will end up generating code like
      //
      //     t2 = this.x = t1;  // t1 is the phi, t2 is the chained name
      //
      if (value is HPhi) return next;

      // We need [value] to be generate-at-use in the setter to avoid it having
      // a name. As a quick check for generate-at-use, accept pure and
      // immediately preceding instructions.
      if (value.isPure(_abstractValueDomain) || setter.previous == value) {
        // TODO(sra): We can tolerate a few non-throwing loads between setter
        // and value.
        uses.replaceWith(chain);
        chain.sourceElement ??= value.sourceElement;
      }
      return next;
    }

    return next;
  }
}

/// Instead of emitting each SSA instruction with a temporary variable
/// mark instructions that can be emitted at their use-site.
/// For example, in:
///   t0 = 4;
///   t1 = 3;
///   t2 = add(t0, t1);
/// t0 and t1 would be marked and the resulting code would then be:
///   t2 = add(4, 3);
class SsaInstructionMerger extends HBaseVisitor<void> implements CodegenPhase {
  @override
  String get name => 'SsaInstructionMerger';

  final AbstractValueDomain _abstractValueDomain;

  /// List of [HInstruction] that the instruction merger expects in
  /// order when visiting the inputs of an instruction.
  List<HInstruction>? expectedInputs;

  /// Set of pure [HInstruction] that the instruction merger expects to
  /// find. The order of pure instructions do not matter, as they will
  /// not be affected by side effects.
  Set<HInstruction>? pureInputs;
  Set<HInstruction> generateAtUseSite;

  void markAsGenerateAtUseSite(HInstruction instruction) {
    assert(!instruction.isJsStatement());
    generateAtUseSite.add(instruction);
  }

  SsaInstructionMerger(this._abstractValueDomain, this.generateAtUseSite);

  @override
  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void analyzeInputs(HInstruction user, int start) {
    List<HInstruction> inputs = user.inputs;
    for (int i = start; i < inputs.length; i++) {
      HInstruction input = inputs[i];
      if (!generateAtUseSite.contains(input) &&
          !input.isCodeMotionInvariant() &&
          input.usedBy.length == 1 &&
          input is! HPhi &&
          input is! HLocalValue &&
          !input.isJsStatement()) {
        if (isEffectivelyPure(input)) {
          // Only consider a pure input if it is in the same loop.
          // Otherwise, we might move GVN'ed instruction back into the
          // loop.
          if (user.hasSameLoopHeaderAs(input)) {
            // Move it closer to [user], so that instructions in
            // between do not prevent making it generate at use site.
            input.moveBefore(user);
            pureInputs!.add(input);
            // Previous computations done on [input] are now invalid
            // because we moved [input] to another place. So all
            // non code motion invariant instructions need
            // to be removed from the [generateAtUseSite] set.
            for (var instruction in input.inputs) {
              if (!instruction.isCodeMotionInvariant()) {
                generateAtUseSite.remove(instruction);
              }
            }
            // Visit the pure input now so that the expected inputs
            // are after the expected inputs of [user].
            input.accept(this);
          }
        } else {
          expectedInputs!.add(input);
        }
      }
    }
  }

  // Some non-pure instructions may be treated as pure. HLocalGet depends on
  // assignments, but we can ignore the initializing assignment since it will by
  // construction always precede a use.
  bool isEffectivelyPure(HInstruction instruction) {
    if (instruction is HLocalGet) return !isAssignedLocal(instruction.local);
    return instruction.isPure(_abstractValueDomain);
  }

  bool isAssignedLocal(HLocalValue local) {
    // [HLocalValue]s have an initializing assignment which is guaranteed to
    // precede the use, except for [HParameterValue]s which are 'assigned' at
    // entry.
    int initializingAssignmentCount = (local is HParameterValue) ? 0 : 1;
    return local.usedBy
        .whereType<HLocalSet>()
        .skip(initializingAssignmentCount)
        .isNotEmpty;
  }

  @override
  void visitInstruction(HInstruction instruction) {
    // A code motion invariant instruction is dealt before visiting it.
    assert(!instruction.isCodeMotionInvariant());
    analyzeInputs(instruction, 0);
  }

  @override
  void visitInvokeSuper(HInvokeSuper node) {
    MemberEntity superMethod = node.element;
    Selector selector = node.selector;
    // If aliased super members cannot be used, we will generate code like
    //
    //     C.prototype.method.call(instance)
    //
    // where instance is the [this] object for the method. In such a case, the
    // get of prototype might be evaluated before instance is created if we
    // generate instance at use site, which in turn might update the prototype
    // after first access if we use lazy initialization.
    // In this case, we therefore don't allow the receiver (the first argument)
    // to be generated at use site, and only analyze all other arguments.
    if (!canUseAliasedSuperMember(superMethod, selector)) {
      analyzeInputs(node, 1);
    } else {
      super.visitInvokeSuper(node);
    }
  }

  // A bounds check method must not have its first input generated at use site,
  // because it's using it twice.
  @override
  void visitBoundsCheck(HBoundsCheck node) {
    analyzeInputs(node, 1);
  }

  // An identity operation must only have its inputs generated at use site if
  // does not require an expression with multiple uses (because of null /
  // undefined).
  @override
  void visitIdentity(HIdentity node) {
    if (node.singleComparisonOp != null) {
      super.visitIdentity(node);
    }
    // Do nothing.
  }

  @override
  void visitAsCheck(HAsCheck node) {
    // Type checks and cast checks compile to code that only use their input
    // once, so we can safely visit them and try to merge the input.
    visitInstruction(node);
  }

  @override
  void visitAsCheckSimple(HAsCheckSimple node) {
    // Type checks and cast checks compile to code that only use their input
    // once, so we can safely visit them and try to merge the input.
    visitInstruction(node);
  }

  @override
  void visitTypeEval(HTypeEval node) {
    // Type expressions compile to code that only use their input once, so we
    // can safely visit them and try to merge the input.
    visitInstruction(node);
  }

  @override
  void visitPrimitiveCheck(HPrimitiveCheck node) {}

  @override
  void visitNullCheck(HNullCheck node) {
    // If the checked value is used, the input might still have one use
    // (i.e. this HNullCheck), but it cannot be generated at use, since we will
    // rely on non-generate-at-use to assign the value to a variable.
    //
    // However, if the checked value is unused then the input may be generated
    // at use in the check.
    if (node.usedBy.isEmpty) {
      visitInstruction(node);
    }
  }

  @override
  void visitLateReadCheck(HLateReadCheck node) {
    // If the checked value is used, the input might still have one use
    // (i.e. this HLateReadCheck), but it cannot be generated at use, since we
    // will rely on non-generate-at-use to assign the value to a variable.
    //
    // However, if the checked value is unused then the input may be generated
    // at use in the check.
    if (node.usedBy.isEmpty) {
      visitInstruction(node);
    } else {
      // The name argument can be generated at use. If present, it is either a
      // string constant or a reference to a string.
      analyzeInputs(node, 1);
    }
  }

  @override
  void visitTypeKnown(HTypeKnown node) {
    // [HTypeKnown] instructions are removed before code generation.
    assert(false);
  }

  @override
  void visitReadModifyWrite(HReadModifyWrite node) {
    if (node.isPreOp || node.isPostOp) {
      analyzeInputs(node, 0);
      return;
    }
    assert(node.isAssignOp);
    // Generate-at-use is valid for the value operand (t1) if the expression
    // tree for t1 does not change the order of effects or exceptions with
    // respect to reading the field of the receiver (t2).
    //
    //     t1 = foo();
    //     t2 = ...
    //     t2.field += t1;
    //
    // 1. If the read of `t2.field` can throw, we can't move `t1` into the
    //    use-site if some part of the expression tree for `t1` can throw.
    //
    // 2. If the expression for `t1` potentially modifies `t2.field`, we can't
    //    move `t1` past the load `t2.field`.
    //
    // TODO(48243): If instruction merging was smarter about effects and was
    // able to change the order of instructions that read non-aliased fields
    // this analysis could probably be folded into the normal algorithm by
    // having HReadModifyWrite have two SideEffects to model the read
    // indepentently of the write.

    bool throwCheck = node.canThrow(_abstractValueDomain);

    bool isSafeSubexpression(HInstruction expression) {
      // If an expression value is used in more than one place it will be
      // assigned to a JavaScript variable.
      if (expression.usedBy.length > 1) return true;

      // Expressions that are generated as JavaScript statements have their
      // value stored in a variable.
      if (expression.isJsStatement()) return true;

      // Condition 1.
      if (throwCheck && expression.canThrow(_abstractValueDomain)) return false;

      // Condition 2.
      if (expression.sideEffects.changesInstanceProperty()) return false;

      // Many phis end up as JavaScript variables, which would be just fine as
      // part of the value expression. Since SsaConditionMerger is a separate
      // pass we can't tell if this phi will become a generate-at-use expression
      // that is invalid as a subexpression of the value expression.
      if (expression is HPhi) return false;

      return expression.inputs.every(isSafeSubexpression);
    }

    if (isSafeSubexpression(node.value)) {
      analyzeInputs(node, 0);
    }
  }

  @override
  void visitArrayFlagsSet(HArrayFlagsSet node) {
    // Cannot generate-at-use the array input, it is an alias for the value of
    // this instruction and need to be allocated to a variable.
    analyzeInputs(node, 1);
  }

  @override
  void visitArrayFlagsCheck(HArrayFlagsCheck node) {
    // Cannot generate-at-use the array input, it is an alias for the value of
    // this instruction and need to be allocated to a variable.
    analyzeInputs(node, 1);
  }

  void tryGenerateAtUseSite(HInstruction instruction) {
    if (instruction.isJsStatement()) return;
    markAsGenerateAtUseSite(instruction);
  }

  bool isBlockSinglePredecessor(HBasicBlock block) {
    return block.successors.length == 1 &&
        block.successors[0].predecessors.length == 1;
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    // Compensate from not merging blocks: if the block is the
    // single predecessor of its single successor, let the successor
    // visit it.
    if (isBlockSinglePredecessor(node)) return;

    tryMergingExpressions(node);
  }

  void tryMergingExpressions(HBasicBlock block) {
    // Visit each instruction of the basic block in last-to-first order.
    // Keep a list of expected inputs of the current "expression" being
    // merged. If instructions occur in the expected order, they are
    // included in the expression.

    // The expectedInputs list holds non-trivial instructions that may
    // be generated at their use site, if they occur in the correct order.
    expectedInputs ??= [];
    pureInputs ??= {};

    // Pop instructions from expectedInputs until instruction is found.
    // Return true if it is found, or false if not.
    bool findInInputsAndPopNonMatching(HInstruction instruction) {
      assert(!isEffectivelyPure(instruction));
      while (expectedInputs!.isNotEmpty) {
        HInstruction nextInput = expectedInputs!.removeLast();
        assert(!generateAtUseSite.contains(nextInput));
        assert(nextInput.usedBy.length == 1);
        if (identical(nextInput, instruction)) {
          return true;
        }
      }
      return false;
    }

    block.last!.accept(this);
    for (
      HInstruction? instruction = block.last!.previous;
      instruction != null;
      instruction = instruction.previous
    ) {
      if (generateAtUseSite.contains(instruction)) {
        continue;
      }
      if (instruction.isCodeMotionInvariant()) {
        markAsGenerateAtUseSite(instruction);
        continue;
      }
      if (isEffectivelyPure(instruction)) {
        if (pureInputs!.contains(instruction)) {
          tryGenerateAtUseSite(instruction);
        } else {
          // If the input is not in the [pureInputs] set, it has not
          // been visited or should not be generated at use-site. The most
          // likely reason for the latter, is that the instruction is used
          // in more than one location.
          // We must either clear the expectedInputs, or move the pure
          // instruction's inputs in front of the existing ones.
          // Example:
          //   t1 = foo();  // side-effect.
          //   t2 = bar();  // side-effect.
          //   t3 = pure(t2);    // used more than once.
          //   f(t1, t3);   // expected inputs of 'f': t1.
          //   use(t3);
          //
          // If we don't clear the expected inputs we end up in a situation
          // where pure pushes "t2" on top of "t1" leading to:
          //   t3 = pure(bar());
          //   f(foo(), t3);
          //   use(t3);
          //
          // If we clear the expected-inputs list we have the correct
          // output:
          //   t1 = foo();
          //   t3 = pure(bar());
          //   f(t1, t3);
          //   use(t3);
          //
          // Clearing is, however, not optimal.
          // Example:
          //   t1 = foo();  // t1 is now used by `pure`.
          //   t2 = bar();  // t2 is now used by `f`.
          //   t3 = pure(t1);
          //   f(t2, t3);
          //   use(t3);
          //
          // If we clear the expected-inputs we can't generate-at-use any of
          // the instructions.
          //
          // The optimal solution is to move the inputs of 'pure' in
          // front of the expectedInputs list. This makes sense, since we
          // push expected-inputs from left-to right, and the `pure` function
          // invocation is "more left" (i.e. before) the first argument of `f`.
          // With that approach we end up with:
          //   t3 = pure(foo());
          //   f(bar(), t3);
          //   use(t3);
          //
          final expectedInputs = this.expectedInputs!;
          int oldLength = expectedInputs.length;
          instruction.accept(this);
          if (oldLength != 0 && oldLength != expectedInputs.length) {
            // Move the pure instruction's inputs to the front.
            List<HInstruction> newInputs = expectedInputs.sublist(oldLength);
            int newCount = newInputs.length;
            expectedInputs.setRange(
              newCount,
              newCount + oldLength,
              expectedInputs,
            );
            expectedInputs.setRange(0, newCount, newInputs);
          }
        }
      } else {
        if (findInInputsAndPopNonMatching(instruction)) {
          // The current instruction is the next non-trivial
          // expected input.
          tryGenerateAtUseSite(instruction);
        } else {
          assert(expectedInputs!.isEmpty);
        }
        instruction.accept(this);
      }
    }

    if (block.predecessors.length == 1 &&
        isBlockSinglePredecessor(block.predecessors[0])) {
      assert(block.phis.isEmpty);
      tryMergingExpressions(block.predecessors[0]);
    } else {
      expectedInputs = null;
      pureInputs = null;
    }
  }
}

///  Detect control flow arising from short-circuit logical and
///  conditional operators, and prepare the program to be generated
///  using these operators instead of nested ifs and boolean variables.
class SsaConditionMerger extends HGraphVisitor implements CodegenPhase {
  @override
  String get name => 'SsaConditionMerger';

  Set<HInstruction> generateAtUseSite;
  Set<HIf> controlFlowOperators;

  void markAsGenerateAtUseSite(HInstruction instruction) {
    assert(!instruction.isJsStatement());
    generateAtUseSite.add(instruction);
  }

  SsaConditionMerger(this.generateAtUseSite, this.controlFlowOperators);

  @override
  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
  }

  /// Check if a block has at least one statement other than
  /// [instruction].
  bool hasAnyStatement(HBasicBlock block, HInstruction instruction) {
    // If [instruction] is not in [block], then if the block is not
    // empty, we know there will be a statement to emit.
    if (!identical(instruction.block, block)) {
      return !identical(block.last, block.first);
    }

    // If [instruction] is not the last instruction of the block
    // before the control flow instruction, or the last instruction,
    // then we will have to emit a statement for that last instruction.
    if (instruction != block.last &&
        !identical(instruction, block.last!.previous)) {
      return true;
    }

    // If one of the instructions in the block until [instruction] is
    // not generated at use site, then we will have to emit a
    // statement for it.
    // TODO(ngeoffray): we could generate a comma separated
    // list of expressions.
    for (
      HInstruction? temp = block.first;
      !identical(temp, instruction);
      temp = temp!.next
    ) {
      if (!generateAtUseSite.contains(temp)) return true;
    }

    return false;
  }

  bool isSafeToGenerateAtUseSite(HInstruction user, HInstruction input) {
    // HCreate evaluates arguments in order and passes them to a constructor.
    if (user is HCreate) return true;

    // A [HForeign] instruction uses operators and if we generate [input] at use
    // site, the precedence or evaluation order might be wrong.
    if (user is HForeign) return false;

    // A [HCheck] instruction that is a statement sometimes uses its input
    // multiple times, so we avoid generating it at use site.
    if (user is HCheck && user.isJsStatement()) return false;

    // A read-modify-write like `o.field += value` reads the field before
    // evaluating the value, so if we generate [input] at the value, the order
    // of field reads may be changed.
    if (user is HReadModifyWrite && input == user.inputs.last) return false;

    // Avoid code motion into a loop.
    return user.hasSameLoopHeaderAs(input);
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    if (block.last is! HIf) return;
    HIf startIf = block.last as HIf;
    HBasicBlock? end = startIf.joinBlock;

    // We check that the structure is the following:
    //         If
    //       /    \
    //      /      \
    //   1 expr    goto
    //    goto     /
    //      \     /
    //       \   /
    // phi(expr, true|false)
    //
    // and the same for nested nodes:
    //
    //            If
    //          /    \
    //         /      \
    //      1 expr1    \
    //       If         \
    //      /  \         \
    //     /    \         goto
    //  1 expr2            |
    //    goto    goto     |
    //      \     /        |
    //       \   /         |
    //   phi1(expr2, true|false)
    //          \          |
    //           \         |
    //             phi(phi1, true|false)

    if (end == null) return;
    if (end.phis.isEmpty) return;
    if (!identical(end.phis.first, end.phis.last)) return;
    HBasicBlock elseBlock = startIf.elseBlock;

    if (!identical(end.predecessors[1], elseBlock)) return;
    final phi = end.phis.first!;
    // This useless phi should have been removed.  Do not generate-at-use if
    // there is no use. See #48383.
    if (phi.usedBy.isEmpty) return;
    HInstruction thenInput = phi.inputs[0];
    HInstruction elseInput = phi.inputs[1];
    if (thenInput.isJsStatement() || elseInput.isJsStatement()) return;

    if (hasAnyStatement(elseBlock, elseInput)) return;
    assert(elseBlock.successors.length == 1);
    assert(end.predecessors.length == 2);

    HBasicBlock thenBlock = startIf.thenBlock;
    // Skip trivial goto blocks.
    while (thenBlock.successors[0] != end && thenBlock.first is HGoto) {
      thenBlock = thenBlock.successors[0];
    }

    // If the [thenBlock] is already a control flow operation, and does not
    // have any statement and its join block is [end], we can emit a
    // sequence of control flow operation.
    if (controlFlowOperators.contains(thenBlock.last)) {
      HIf otherIf = thenBlock.last as HIf;
      if (!identical(otherIf.joinBlock, end)) {
        // This could be a join block that just feeds into our join block.
        HBasicBlock otherJoin = otherIf.joinBlock!;
        if (otherJoin.first != otherJoin.last) return;
        if (otherJoin.successors.length != 1) return;
        if (otherJoin.successors[0] != end) return;
        if (otherJoin.phis.isEmpty) return;
        if (!identical(otherJoin.phis.first, otherJoin.phis.last)) return;
        final otherPhi = otherJoin.phis.first!;
        if (thenInput != otherPhi) return;
        if (elseInput != otherPhi.inputs[1]) return;
      }
      if (hasAnyStatement(thenBlock, otherIf)) return;
    } else {
      if (!identical(end.predecessors[0], thenBlock)) return;
      if (hasAnyStatement(thenBlock, thenInput)) return;
      assert(thenBlock.successors.length == 1);
    }

    // From now on, we have recognized a control flow operation built from
    // the builder. Mark the if instruction as such.
    controlFlowOperators.add(startIf);

    // Find the next non-HGoto instruction following the phi.
    HInstruction? nextInstruction = phi.block!.first;
    while (nextInstruction is HGoto) {
      nextInstruction = nextInstruction.block!.successors[0].first;
    }

    // If the operation is only used by the first instruction
    // of its block and is safe to be generated at use site, mark it
    // so.
    if (phi.usedBy.length == 1 &&
        phi.usedBy[0] == nextInstruction &&
        isSafeToGenerateAtUseSite(phi.usedBy[0], phi)) {
      markAsGenerateAtUseSite(phi);
    }

    if (identical(elseInput.block, elseBlock)) {
      assert(elseInput.usedBy.length == 1);
      markAsGenerateAtUseSite(elseInput);
    }

    // If [thenInput] is defined in the first predecessor, then it is only used
    // by [phi] and can be generated at use site.
    if (identical(thenInput.block, end.predecessors[0])) {
      assert(thenInput.usedBy.length == 1);
      markAsGenerateAtUseSite(thenInput);
    }
  }
}

/// 'Condition' phis by hoisting common constants to before the control flow.
/// The default pattern is to assign to a variable on all edges into a phi.
///
///     if (condition1) {
///       if (condition2) {
///         ...
///         t1 = ...;
///       } else
///         t1 = false;
///     } else
///       t1 = false;
///
/// Hoisting `t1 = false` is smaller due to not needing `else`:
///
///     t1 = false;
///     if (condition1) {
///       if (condition1) {
///         ...
///         t1 = ...;
///       }
///     }
///
/// This transformation introduces partial redundancy, and increases live-ranges
/// and may require more temporary variables.
class SsaPhiConditioning extends HGraphVisitor implements CodegenPhase {
  @override
  String get name => 'SsaPhiConditioning';

  final Set<HInstruction> generateAtUseSite;
  final Set<HIf> controlFlowOperators;

  final Set<HPhi> _handled = {};

  SsaPhiConditioning(this.generateAtUseSite, this.controlFlowOperators);

  @override
  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    final dominator = block.dominator;
    if (dominator == null) return; // Entry block.

    // The algorithm scans backwards, inspecting the tree of phi nodes rooted at
    // this block, stopping at this block's dominator. The dominator is a place
    // to which the assignment can legally be hoisted and used by the phi nodes.
    // The nodes of the tree are marked as handled. If we don't find an
    // optimization opportunity in the phi tree, there won't be an opportunity
    // in the smaller subtree, and re-scanning subtrees could be non-linear.

    // If this region of the CFG is a control-flow operation (&&, ?:, etc),
    // the inputs of the participating phi nodes must not be changed.
    if (controlFlowOperators.contains(dominator.last)) {
      for (var phi = block.phis.firstPhi; phi != null; phi = phi.nextPhi) {
        _markHandled(phi, dominator);
      }
      return;
    }

    for (var phi = block.phis.firstPhi; phi != null; phi = phi.nextPhi) {
      if (_handled.contains(phi)) continue;
      handlePhi(block, dominator, phi);
    }
  }

  void handlePhi(HBasicBlock block, HBasicBlock dominator, HPhi root) {
    final Map<HInstruction, List<(HPhi, int)>> phiTreeInputs = {};
    final List<HPhi> phiTreeNodes = [];

    void collect(HPhi phi) {
      if (dominator == phi.block) return;
      if (!dominator.dominates(phi.block!)) return;
      if (generateAtUseSite.contains(phi)) return;
      phiTreeNodes.add(phi);
      for (int i = 0; i < phi.inputs.length; i++) {
        final input = phi.inputs[i];
        if (input is HPhi) {
          // Ignore back-edges.
          if (input.block!.id >= phi.block!.id) continue;

          // Ignore subtrees from control flow operators.
          final dom = input.block!.dominator!;
          if (controlFlowOperators.contains(dom.last)) continue;
          collect(input);
        } else if (input is HConstant) {
          // UnreachableConstantValue means that this 'phi' input corresponds to
          // dead control flow.
          if (input.constant is UnreachableConstantValue) continue;

          // Only primitives are cheap enough to add the partial redundancy.
          if (input.isConstantBoolean() ||
              input.isConstantNull() ||
              input.isConstantString() ||
              input.isConstantNumber()) {
            (phiTreeInputs[input] ??= []).add((phi, i));
          }
        }
      }
    }

    collect(root);

    late HInstruction best;
    List<(HPhi, int)> bestReferences = const [];
    for (final MapEntry(key: instruction, value: references)
        in phiTreeInputs.entries) {
      if (references.length > bestReferences.length) {
        bestReferences = references;
        best = instruction;
      }
    }

    // At least two paths with the same constant.
    if (bestReferences.length >= 2) {
      final value = HLateValue(best);
      value.sourceElement = root.sourceElement;

      // To minimize the live range, [value] should be inserted at the common
      // dominator of all the references. This is usually just [dominator], so
      // it is faster on average to search down the successors than to compute
      // the common dominator.

      SINK_DOMINATOR:
      while (true) {
        BLOCKS:
        for (final HBasicBlock block in dominator.successors) {
          if (block.id < dominator.id) continue;
          for (final (phi, _) in bestReferences) {
            if (!block.dominates(phi.block!)) continue BLOCKS;
            // Insertion point can't be the phi block since phis come first.
            if (block == phi.block) continue BLOCKS;
          }
          dominator = block;
          continue SINK_DOMINATOR;
        }
        break;
      }

      dominator.addBefore(dominator.last, value);

      for (final (phi, index) in bestReferences) {
        phi.replaceInput(index, value);
      }
    }

    _handled.addAll(phiTreeNodes);
  }

  void _markHandled(HPhi phi, HBasicBlock dominator) {
    if (_handled.add(phi)) {
      for (final input in phi.inputs) {
        if (input is HPhi && dominator.dominates(input.block!)) {
          _markHandled(input, dominator);
        }
      }
    }
  }
}

/// Insert 'caches' for whole-function region-constants when the local minified
/// name would be shorter than repeated references.  These are caches for 'this'
/// and constant values.
class SsaShareRegionConstants extends HBaseVisitor<void>
    implements CodegenPhase {
  @override
  String get name => 'SsaShareRegionConstants';

  SsaShareRegionConstants();

  @override
  void visitGraph(HGraph graph) {
    // We need the async rewrite to be smarter about hoisting region constants
    // before it is worth-while.
    if (graph.needsAsyncRewrite) return;

    // 'HThis' and constants are in the entry block. No need to walk the rest of
    // the graph.
    visitBasicBlock(graph.entry);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    HInstruction? instruction = node.first;
    while (instruction != null) {
      HInstruction? next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  // Not all occurrences should be replaced with a local variable cache, so we
  // filter the uses.
  int _countCacheableUses(
    HInstruction node,
    bool Function(HInstruction) cacheable,
  ) {
    return node.usedBy.where(cacheable).length;
  }

  // Replace cacheable uses with a reference to a HLateValue node.
  void _cache(
    HInstruction node,
    bool Function(HInstruction) cacheable,
    String name,
  ) {
    var users = node.usedBy.toList();
    var reference = HLateValue(node);
    // TODO(sra): The sourceInformation should really be from the function
    // entry, not the use of `this`.
    reference.sourceInformation = node.sourceInformation;
    reference.sourceElement = _ExpressionName(name);
    node.block!.addAfter(node, reference);
    for (HInstruction user in users) {
      if (cacheable(user)) {
        user.changeUse(node, reference);
      }
    }
  }

  @override
  void visitThis(HThis node) {
    int size = 4;
    // Compare the size of the unchanged minified with the size of the minified
    // code where 'this' is assigned to a variable. We assume the variable has
    // minified size 1.
    //
    // The size overhead of introducing a variable in the worst case includes
    // 'var ':
    //
    //           1234   // size
    //     var x=this;  // (minified ';' can be end-of-line)
    //     123456    7  // additional overhead
    //
    // TODO(sra): If there are multiple values that can potentially be cached,
    // they can share the 'var ' cost, even if none of them are beneficial
    // individually.
    int useCount = node.usedBy.length;
    if (useCount * size <= 7 + size + useCount * 1) return;
    _cache(node, (_) => true, '_this');
  }

  @override
  void visitConstant(HConstant node) {
    if (node.usedBy.length <= 1) return;
    ConstantValue constant = node.constant;

    if (constant is NullConstantValue) {
      _handleNull(node);
      return;
    }

    if (constant is IntConstantValue) {
      _handleInt(node, constant);
      return;
    }

    if (constant is StringConstantValue) {
      _handleString(node, constant);
      return;
    }
  }

  void _handleNull(HConstant node) {
    int size = 4;

    bool isCacheableUse(HInstruction instruction) {
      // One-shot interceptors have `null` as a dummy interceptor.
      if (instruction is HOneShotInterceptor) return false;

      if (instruction is HInvoke) return true;
      if (instruction is HCreate) return true;
      if (instruction is HReturn) return true;
      if (instruction is HPhi) return true;
      if (instruction is HLateValue) return true;

      // JavaScript `x == null` is more efficient than `x == _null`.
      if (instruction is HIdentity) return false;

      // TODO(sra): Determine if other uses result in faster JavaScript code.
      return false;
    }

    int useCount = _countCacheableUses(node, isCacheableUse);
    if (useCount * size <= 7 + size + useCount * 1) return;
    _cache(node, isCacheableUse, '_null');
    return;
  }

  void _handleInt(HConstant node, IntConstantValue intConstant) {
    BigInt value = intConstant.intValue;
    String text = value.toString();
    int size = text.length;
    if (size <= 3) return;

    bool isCacheableUse(HInstruction instruction) {
      if (instruction is HInvoke) return true;
      if (instruction is HCreate) return true;
      if (instruction is HReturn) return true;
      if (instruction is HPhi) return true;
      if (instruction is HLateValue) return true;

      // JavaScript `x === 5` is more efficient than `x === _5`.
      if (instruction is HIdentity) return false;

      // Foreign code templates may use literals in ways that are beneficial.
      if (instruction is HForeignCode) return false;

      // TODO(sra): Determine if other uses result in faster JavaScript code.
      return false;
    }

    int useCount = _countCacheableUses(node, isCacheableUse);
    if (useCount * size <= 7 + size + useCount * 1) return;
    _cache(node, isCacheableUse, '_${text.replaceFirst("-", "_")}');
  }

  void _handleString(HConstant node, StringConstantValue stringConstant) {
    String value = stringConstant.stringValue;
    int length = value.length;
    int size = length + 2; // Include quotes.
    if (size <= 2) return;

    bool isCacheableUse(HInstruction instruction) {
      // Foreign code templates may use literals in ways that are beneficial.
      if (instruction is HForeignCode) return false;

      // Cache larger strings even if unfortunate.
      if (length >= 16) return true;

      if (instruction is HInvoke) return true;
      if (instruction is HCreate) return true;
      if (instruction is HReturn) return true;
      if (instruction is HPhi) return true;
      if (instruction is HLateValue) return true;

      // TODO(sra): Check if a.x="s" can avoid or specialize a write barrier.
      if (instruction is HFieldSet) return true;

      if (instruction is HLateCheck) return true;

      // TODO(sra): Determine if other uses result in faster JavaScript code.
      return false;
    }

    int useCount = _countCacheableUses(node, isCacheableUse);
    if (useCount * size <= 7 + size + useCount * 1) return;
    _cache(node, isCacheableUse, '_s${length}_');
  }
}

/// A simple Entity to give intermediate values nice names when not generating
/// minified code.
class _ExpressionName implements Entity {
  @override
  final String name;
  _ExpressionName(this.name);
}

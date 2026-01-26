// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code_generator.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

final class Arm64CodeGenerator extends CodeGenerator {
  late final Arm64Assembler _asm;

  Arm64CodeGenerator(super.backEndState);

  @override
  Assembler createAssembler() => _asm = Arm64Assembler(backEndState.vmOffsets);

  @override
  void enterFrame() {
    _asm.pushPair(FP, LR);
    _asm.mov(FP, stackPointerReg);

    // Tag and save caller pool pointer.
    _asm.add(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));
    _asm.pushPair(poolPointerReg, codeReg);

    // Load and untag current pool pointer.
    _asm.ldr(
      poolPointerReg,
      _asm.fieldAddress(codeReg, _asm.vmOffsets.Code_object_pool_offset),
    );
    _asm.sub(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));

    // TODO: calculate stack frame size.
    _asm.sub(stackPointerReg, stackPointerReg, Immediate(64));
  }

  void _generateBranch(
    Block trueSuccessor,
    Block falseSuccessor,
    void Function(bool, Label) branch,
  ) {
    if (canFallThroughTo(trueSuccessor)) {
      branch(false, blockLabel(falseSuccessor));
    } else {
      branch(true, blockLabel(trueSuccessor));
      if (!canFallThroughTo(falseSuccessor)) {
        _asm.b(blockLabel(falseSuccessor));
      }
    }
  }

  @override
  void visitBranch(Branch instr) {
    final cond = inputReg(instr, 0);
    final boolValueBit = boolValueBitPosition(log2wordSize);
    _generateBranch(instr.trueSuccessor, instr.falseSuccessor, (
      bool value,
      Label label,
    ) {
      // Test bool value bit: 0 = true, 1 = false.
      if (value) {
        _asm.tbz(cond, boolValueBit, label);
      } else {
        _asm.tbnz(cond, boolValueBit, label);
      }
    });
  }

  @override
  void visitCompareAndBranch(CompareAndBranch instr) {
    final trueSuccessor = instr.trueSuccessor;
    final falseSuccessor = instr.falseSuccessor;
    final left = inputReg(instr, 0);
    final right = instr.right;
    switch (instr.op) {
      case ComparisonOpcode.equal:
      case ComparisonOpcode.intEqual:
      case ComparisonOpcode.notEqual:
      case ComparisonOpcode.intNotEqual:
        if (right is Constant && right.value.isZero) {
          _generateBranch(trueSuccessor, falseSuccessor, (
            bool value,
            Label label,
          ) {
            if (value ==
                (instr.op == ComparisonOpcode.equal ||
                    instr.op == ComparisonOpcode.intEqual)) {
              _asm.cbz(left, label);
            } else {
              _asm.cbnz(left, label);
            }
          });
          return;
        }
      case ComparisonOpcode.intTestIsZero:
      case ComparisonOpcode.intTestIsNotZero:
        if (right is Constant &&
            right.value.isInt &&
            isPowerOf2(right.value.intValue)) {
          final bitNumber = log2OfPowerOf2(right.value.intValue);
          _generateBranch(trueSuccessor, falseSuccessor, (
            bool value,
            Label label,
          ) {
            if (value == (instr.op == ComparisonOpcode.intTestIsZero)) {
              _asm.tbz(left, bitNumber, label);
            } else {
              _asm.tbnz(left, bitNumber, label);
            }
          });
        }
      default:
        break;
    }
    switch (instr.op) {
      case ComparisonOpcode.equal:
      case ComparisonOpcode.notEqual:
      case ComparisonOpcode.intEqual:
      case ComparisonOpcode.intNotEqual:
      case ComparisonOpcode.intLess:
      case ComparisonOpcode.intLessOrEqual:
      case ComparisonOpcode.intGreater:
      case ComparisonOpcode.intGreaterOrEqual:
        final (operand, negated) = _generateAddSubRightOperand(instr, right);
        if (negated) {
          _asm.cmn(left, operand);
        } else {
          _asm.cmp(left, operand);
        }
        break;
      case ComparisonOpcode.intTestIsZero:
      case ComparisonOpcode.intTestIsNotZero:
        final operand = _generateLogicalRightOperand(instr, right);
        _asm.tst(left, operand);
        break;
      default:
        throw 'Unexpected ${instr.op}';
    }
    _generateBranch(trueSuccessor, falseSuccessor, (bool value, Label label) {
      final op = value ? instr.op : instr.op.negate();
      _asm.b(label, op.conditionCode);
    });
  }

  (Operand, bool negated) _generateAddSubRightOperand(
    Instruction instr,
    Definition right,
  ) {
    if (right is Constant) {
      if (right.value.isInt) {
        final value = right.value.intValue;
        if (value == 0) {
          return (ZR, false);
        } else if (_asm.canEncodeImm12(value)) {
          return (Immediate(value), false);
        } else if (_asm.canEncodeImm12(-value)) {
          return (Immediate(-value), true);
        }
      }
      _asm.loadConstant(tempReg, right.value);
      return (tempReg, false);
    }
    return (inputReg(instr, 1), false);
  }

  Operand _generateLogicalRightOperand(Instruction instr, Definition right) {
    if (right is Constant) {
      if (right.value.isInt) {
        final value = right.value.intValue;
        if (_asm.canEncodeBitMasks(value)) {
          return Immediate(value);
        }
      }
      _asm.loadConstant(tempReg, right.value);
      return tempReg;
    }
    return inputReg(instr, 1);
  }

  @override
  void visitReturn(Return instr) {
    assert(inputReg(instr, 0) == returnReg);
    // Restore and untag pool pointer.
    _asm.ldr(poolPointerReg, RegOffsetAddress(FP, -2 * wordSize));
    _asm.sub(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));

    _asm.mov(stackPointerReg, FP);
    _asm.popPair(FP, LR);
    _asm.ret();
  }

  @override
  void visitComparison(Comparison instr) {
    _asm.unimplemented('Unimplemented: code generation for Comparison');
  }

  @override
  void visitConstant(Constant instr) {
    // No-op.
  }

  void _passArguments(CallInstruction instr) {
    Register pendingReg = invalidReg;
    var offset = 0;

    Register getTempReg() => (pendingReg == tempReg) ? LR : tempReg;

    for (var i = 0; i < instr.inputCount; ++i) {
      final arg = instr.inputDefAt(i);
      Register reg;
      if (arg is Constant) {
        if (arg.value.isZero) {
          reg = ZR;
        } else if (arg.value.isNull) {
          reg = nullReg;
        } else {
          reg = getTempReg();
          _asm.loadConstant(reg, arg.value);
        }
      } else {
        final loc = inputLoc(instr, i);
        switch (loc) {
          case Register():
            reg = loc;
            break;
          // TODO: support other locations.
          default:
            throw 'Unimplemented passing arg from ${loc.runtimeType} $loc';
        }
      }
      if (pendingReg == invalidReg) {
        pendingReg = reg;
      } else {
        _asm.stp(pendingReg, reg, RegOffsetAddress(stackPointerReg, offset));
        pendingReg = invalidReg;
        offset += 2 * wordSize;
      }
    }
    if (pendingReg != invalidReg) {
      _asm.str(pendingReg, RegOffsetAddress(stackPointerReg, offset));
    }
  }

  @override
  void visitDirectCall(DirectCall instr) {
    // TODO: pass arg_desc when needed.
    _asm.loadImmediate(argumentsDescriptorReg, 0);
    _passArguments(instr);
    _asm.loadFromPool(functionReg, instr.target);
    // TODO: call directly through Code.
    _asm.ldr(
      codeReg,
      _asm.fieldAddress(functionReg, _asm.vmOffsets.Function_code_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        functionReg,
        _asm.vmOffsets.Function_entry_point_offset.first,
      ),
    );
    _asm.blr(tempReg);
  }

  @override
  void visitInterfaceCall(InterfaceCall instr) {
    _asm.unimplemented('Unimplemented: code generation for InterfaceCall');
  }

  @override
  void visitClosureCall(ClosureCall instr) {
    _asm.unimplemented('Unimplemented: code generation for ClosureCall');
  }

  @override
  void visitDynamicCall(DynamicCall instr) {
    _asm.unimplemented('Unimplemented: code generation for DynamicCall');
  }

  @override
  void visitParameter(Parameter instr) {
    // No-op.
  }

  @override
  void visitLoadLocal(LoadLocal instr) => throw 'Unexpected LoadLocal';

  @override
  void visitStoreLocal(StoreLocal instr) => throw 'Unexpected StoreLocal';

  @override
  void visitLoadInstanceField(LoadInstanceField instr) {
    _asm.unimplemented('Unimplemented: code generation for LoadInstanceField');
  }

  @override
  void visitStoreInstanceField(StoreInstanceField instr) {
    _asm.unimplemented('Unimplemented: code generation for StoreInstanceField');
  }

  @override
  void visitLoadStaticField(LoadStaticField instr) {
    _asm.unimplemented('Unimplemented: code generation for LoadStaticField');
  }

  @override
  void visitStoreStaticField(StoreStaticField instr) {
    _asm.unimplemented('Unimplemented: code generation for StoreStaticField');
  }

  @override
  void visitThrow(Throw instr) {
    _asm.unimplemented('Unimplemented: code generation for Throw');
  }

  @override
  void visitNullCheck(NullCheck instr) {
    _asm.unimplemented('Unimplemented: code generation for NullCheck');
  }

  @override
  void visitTypeParameters(TypeParameters instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeParameters');
  }

  @override
  void visitTypeCast(TypeCast instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeCast');
  }

  @override
  void visitTypeTest(TypeTest instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeTest');
  }

  @override
  void visitTypeArguments(TypeArguments instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeArguments');
  }

  @override
  void visitTypeLiteral(TypeLiteral instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeLiteral');
  }

  @override
  void visitAllocateObject(AllocateObject instr) {
    _asm.unimplemented('Unimplemented: code generation for AllocateObject');
  }

  @override
  void visitAllocateClosure(AllocateClosure instr) {
    _asm.unimplemented('Unimplemented: code generation for AllocateClosure');
  }

  @override
  void visitAllocateList(AllocateList instr) {
    _asm.unimplemented('Unimplemented: code generation for AllocateList');
  }

  @override
  void visitSetListElement(SetListElement instr) {
    _asm.unimplemented('Unimplemented: code generation for SetListElement');
  }

  @override
  void visitBinaryIntOp(BinaryIntOp instr) {
    _asm.unimplemented('Unimplemented: code generation for BinaryIntOp');
  }

  @override
  void visitUnaryIntOp(UnaryIntOp instr) {
    _asm.unimplemented('Unimplemented: code generation for UnaryIntOp');
  }

  @override
  void visitBinaryDoubleOp(BinaryDoubleOp instr) {
    _asm.unimplemented('Unimplemented: code generation for BinaryDoubleOp');
  }

  @override
  void visitUnaryDoubleOp(UnaryDoubleOp instr) {
    _asm.unimplemented('Unimplemented: code generation for UnaryDoubleOp');
  }

  @override
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    _asm.unimplemented('Unimplemented: code generation for UnaryBoolOp');
  }

  @override
  void generateMove(Location from, Location to) {
    if (from is Register && to is Register) {
      _asm.mov(to, from);
      return;
    }
    _asm.unimplemented('Unimplemented: code generation for generateMove');
  }

  @override
  void generateLoadConstant(ConstantValue value, Location to) {
    if (to is Register) {
      _asm.loadConstant(to, value);
      return;
    }
    _asm.unimplemented(
      'Unimplemented: code generation for generateLoadConstant',
    );
  }

  @override
  void generatePush(Location loc) {
    _asm.unimplemented('Unimplemented: code generation for generatePush');
  }

  void generatePop(Location loc) {
    _asm.unimplemented('Unimplemented: code generation for generatePop');
  }
}

extension on ComparisonOpcode {
  Condition get conditionCode => switch (this) {
    ComparisonOpcode.equal => Condition.equal,
    ComparisonOpcode.notEqual => Condition.notEqual,
    ComparisonOpcode.identical => Condition.equal,
    ComparisonOpcode.notIdentical => Condition.notEqual,
    ComparisonOpcode.intEqual => Condition.equal,
    ComparisonOpcode.intNotEqual => Condition.notEqual,
    ComparisonOpcode.intLess => Condition.less,
    ComparisonOpcode.intLessOrEqual => Condition.lessOrEqual,
    ComparisonOpcode.intGreater => Condition.greater,
    ComparisonOpcode.intGreaterOrEqual => Condition.greaterOrEqual,
    ComparisonOpcode.intTestIsZero => Condition.equal,
    ComparisonOpcode.intTestIsNotZero => Condition.notEqual,
    ComparisonOpcode.doubleEqual => Condition.equal,
    ComparisonOpcode.doubleNotEqual => Condition.notEqual,
    ComparisonOpcode.doubleLess => Condition.less,
    ComparisonOpcode.doubleLessOrEqual => Condition.lessOrEqual,
    ComparisonOpcode.doubleGreater => Condition.greater,
    ComparisonOpcode.doubleGreaterOrEqual => Condition.greaterOrEqual,
  };
}

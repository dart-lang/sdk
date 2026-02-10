// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code_generator.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

final class Arm64CodeGenerator extends CodeGenerator {
  late final Arm64Assembler _asm;

  Arm64CodeGenerator(super.backEndState);

  @override
  Assembler createAssembler() => _asm = Arm64Assembler(backEndState.vmOffsets);

  @override
  void enterFrame() {
    _asm.enterDartFrame();
    _asm.subImmediate(
      stackPointerReg,
      stackPointerReg,
      stackFrame.frameSizeToAllocate,
    );
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
    _asm.leaveDartFrame();
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
      offset += wordSize;
    }
    assert(offset <= stackFrame.maxArgumentsStackSlots * wordSize);
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
      _asm.fieldAddress(functionReg, vmOffsets.Function_code_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        functionReg,
        vmOffsets.Function_entry_point_offset.first,
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
    final objectReg = inputReg(instr, 0);
    final valueReg = outputReg(instr);
    if (instr.checkInitialized) {
      // TODO: initialized check for late fields.
      _asm.unimplemented(
        'Unimplemented: code generation for LoadInstanceField.checkInitialized',
      );
      return;
    }
    // TODO: unboxed fields
    _asm.ldr(
      valueReg,
      _asm.fieldAddress(objectReg, objectLayout.getFieldOffset(instr.field)),
    );
  }

  bool _canSkipWriteBarrier(Definition objectDef, Definition valueDef) =>
      (objectDef == valueDef) ||
      switch (valueDef) {
        Constant(:var value)
            when value.isNull ||
                value.isBool ||
                (value.isInt && objectLayout.isSmi(value.intValue)) =>
          true,
        _ => false,
      };

  bool _canBeSmi(Definition def) => switch (def) {
    Constant(:var value) => value.isInt && objectLayout.isSmi(value.intValue),
    _ => def.type is IntType || const IntType().isSubtypeOf(def.type),
  };

  void _writeBarrier(
    Register objectReg,
    Register valueReg,
    Register scratch1Reg,
    Register scratch2Reg, {
    required bool valueCanBeSmi,
  }) {
    // Test whether
    //  - object is old and not remembered and value is new, or
    //  - object is old and value is old and not marked and concurrent marking is in progress.
    // If so, call the WriteBarrier stub.

    final done = Label();
    Label slowPath = addSlowPath(() {
      _asm.callStub(
        backEndState.stubFactory.getWriteBarrierStub(objectReg, valueReg),
      );
      _asm.b(done);
    });

    if (valueCanBeSmi) {
      _asm.tbz(valueReg, smiBit, done);
    } else {
      final ok = Label();
      _asm.tbnz(valueReg, smiBit, ok);
      _asm.unimplemented('Smi value in _writeBarrier');
      _asm.bind(ok);
    }

    _asm.ldr(
      scratch1Reg,
      _asm.address(objectReg, vmOffsets.Object_tags_offset),
      .u8,
    );
    _asm.ldr(
      scratch2Reg,
      _asm.address(valueReg, vmOffsets.Object_tags_offset),
      .u8,
    );
    _asm.and(
      scratch1Reg,
      scratch2Reg,
      ShiftedRegOperand(scratch1Reg, .LSR, barrierOverlapShift),
    );
    _asm.tst(scratch1Reg, ShiftedRegOperand(heapBitsReg, .LSR, 32));
    _asm.b(slowPath, .notEqual);

    _asm.bind(done);
  }

  @override
  void visitStoreInstanceField(StoreInstanceField instr) {
    final objectReg = inputReg(instr, 0);
    final valueReg = inputReg(instr, 1);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);
    if (instr.checkNotInitialized) {
      // TODO: not-initialized check for late final fields.
      _asm.unimplemented(
        'Unimplemented: code generation for StoreInstanceField.checkNotInitialized',
      );
      return;
    }
    // TODO: unboxed fields
    _asm.str(
      valueReg,
      _asm.fieldAddress(objectReg, objectLayout.getFieldOffset(instr.field)),
    );
    if (!_canSkipWriteBarrier(instr.object, instr.value)) {
      _writeBarrier(
        objectReg,
        valueReg,
        scratch1Reg,
        scratch2Reg,
        valueCanBeSmi: _canBeSmi(instr.value),
      );
    }
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
    final cls = (instr.type.dartType as ast.InterfaceType).classNode;
    final instanceSize = objectLayout.getInstanceSize(cls);
    final typeArgsField = objectLayout.getTypeArgumentsField(cls);
    final typeArgumentsReg = AllocationStub.typeArgumentsReg;
    final tagsReg = AllocationStub.tagsReg;
    final resultReg = AllocationStub.resultReg;
    assert(!instr.hasTypeArguments || inputReg(instr, 0) == typeArgumentsReg);
    assert(outputReg(instr) == resultReg);

    // TODO: support huge objects

    final done = Label();
    Label slowPath = addSlowPath(() {
      _asm.callStub(backEndState.stubFactory.getAllocationStub(cls));
      _asm.b(done);
    });

    final endReg = AllocationStub.scratch1Reg;
    final newTopReg = AllocationStub.scratch2Reg;
    // Load Thread.top_ and Thread.end_.
    _asm.ldp(
      resultReg,
      endReg,
      _asm.pairAddress(threadReg, vmOffsets.Thread_top_offset),
    );
    _asm.addImmediate(newTopReg, resultReg, instanceSize);
    _asm.cmp(endReg, newTopReg);
    _asm.b(slowPath, Condition.unsignedLessOrEqual);

    // TLAB has enough space. Update top and initialize object.
    _asm.loadFromPool(tagsReg, NewObjectTags(cls));
    _asm.str(newTopReg, _asm.address(threadReg, vmOffsets.Thread_top_offset));
    _asm.str(tagsReg, _asm.address(resultReg, vmOffsets.Object_tags_offset));
    // TODO: figure out if we need store-store barrier here.

    // TODO: support compressed pointers.
    const maxUnrolledSize = 16 * wordSize;
    if (instanceSize <= maxUnrolledSize) {
      int offset = vmOffsets.Instance_first_field_offset;
      for (; offset + 2 * wordSize <= instanceSize; offset += 2 * wordSize) {
        _asm.stp(nullReg, nullReg, _asm.pairAddress(resultReg, offset));
      }
      if (offset < instanceSize) {
        _asm.str(nullReg, _asm.address(resultReg, offset));
        offset += wordSize;
      }
      assert(offset == instanceSize);
    } else {
      final fieldReg = AllocationStub.scratch1Reg;
      _asm.addImmediate(
        fieldReg,
        resultReg,
        vmOffsets.Instance_first_field_offset,
      );

      final loop = Label();
      _asm.bind(loop);
      _asm.stp(
        nullReg,
        nullReg,
        WritebackRegOffsetAddress(fieldReg, 2 * wordSize, isPostIndexed: true),
      );
      // There is at least two word (kAllocationRedZoneSize) gap at the end of page
      // which makes it possible to initialize objects by two words at once and
      // write slightly beyond the end.
      _asm.cmp(fieldReg, newTopReg);
      _asm.b(loop, Condition.unsignedLess);
    }

    _asm.addImmediate(resultReg, resultReg, heapObjectTag);

    if (typeArgsField != null) {
      if (instr.hasTypeArguments) {
        _asm.str(
          typeArgumentsReg,
          _asm.fieldAddress(
            resultReg,
            objectLayout.getFieldOffset(typeArgsField),
          ),
        );
      } else {
        final typeArgs = getInstantiatorTypeArguments(cls, []);
        if (typeArgs != null) {
          _asm.loadConstant(
            typeArgumentsReg,
            ConstantValue(TypeArgumentsConstant(typeArgs)),
          );
          _asm.str(
            typeArgumentsReg,
            _asm.fieldAddress(
              resultReg,
              objectLayout.getFieldOffset(typeArgsField),
            ),
          );
        }
      }
    }

    // TODO: allocation profile; allocation probe points.

    _asm.bind(done);
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
    switch (from) {
      case Register():
        switch (to) {
          case Register():
            _asm.mov(to, from);
            return;
          case StackLocation():
            _asm.str(from, _asm.address(FP, stackFrame.offsetFromFP(to)));
            return;
          default:
            break;
        }
      case StackLocation():
        switch (to) {
          case Register():
            _asm.ldr(to, _asm.address(FP, stackFrame.offsetFromFP(from)));
            return;
          default:
            break;
        }
      default:
        break;
    }
    _asm.unimplemented(
      'Unimplemented: code generation for generateMove ${from.runtimeType} -> ${to.runtimeType}',
    );
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

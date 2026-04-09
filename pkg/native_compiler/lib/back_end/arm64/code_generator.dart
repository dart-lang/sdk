// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stack_frame.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code_generator.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

final class Arm64CodeGenerator extends CodeGenerator {
  final FunctionRegistry functionRegistry;
  late final Arm64Assembler _asm;

  Arm64CodeGenerator(super.backEndState, this.functionRegistry);

  @override
  Assembler createAssembler() =>
      _asm = Arm64Assembler(backEndState.vmOffsets, backEndState.objectLayout);

  @override
  void enterFrame() {
    _asm.enterDartFrame();
    _asm.subImmediate(
      stackPointerReg,
      stackPointerReg,
      stackFrame.frameSizeToAllocate,
    );
    final function = graph.function;
    if (function.hasOptionalPositionalParameters) {
      _prepareOptionalPositionalParameters(function);
    } else if (function.hasNamedParameters) {
      _prepareNamedParameters(function);
    }
  }

  /// Load positional required and optional arguments into argument registers,
  /// filling in the default values if optional arguments are not passed.
  /// Extra arguments are copied to the shadow parameters area on the stack.
  void _prepareOptionalPositionalParameters(CFunction function) {
    final argCountReg = prologueScratchRegisters[0];
    final argPtrReg = prologueScratchRegisters[1];

    final numRequired = function.numberOfRequiredPositionalParameters;
    final total = function.numberOfParameters;
    assert(numRequired < total);

    // TODO: compressed pointers
    // Load number of arguments (without type arguments) as a Smi.
    _asm.ldr(
      argCountReg,
      _asm.fieldAddress(
        argumentsDescriptorReg,
        vmOffsets.ArgumentsDescriptor_count_offset,
      ),
    );
    // Type arguments are passed as the first required positional parameter,
    // but it is not counted in [ArgumentsDescriptor.count].
    final typeArg = function.hasFunctionTypeParameters ? 1 : 0;
    // Arguments pointer points to FP + [ArgumentsDescriptor.count]*wordSize.
    _asm.add(
      argPtrReg,
      FP,
      ShiftedRegOperand(argCountReg, .LSL, log2wordSize - smiShift),
    );
    // Offset of the first argument, relative to argPtrReg.
    final int baseOffset =
        Arm64StackFrame.lastParameterOffsetFromFP + (typeArg - 1) * wordSize;
    // Label for each number of optional arguments passed.
    final labels = List.generate(total - numRequired, (_) => Label());

    var i = 0;
    final int numArgsToLoadInPairs = math.min(total, argumentRegisters.length);
    for (; i + 1 < numArgsToLoadInPairs; i += 2) {
      if (i >= numRequired) {
        _asm.cmp(argCountReg, Immediate((i + 1 - typeArg) << smiShift));
        _asm.b(labels[i - numRequired], .less);
      }
      // TODO: pass arguments on registers and avoid these loads
      _asm.ldp(
        argumentRegisters[i + 1],
        argumentRegisters[i],
        _asm.pairAddress(argPtrReg, baseOffset - (i + 1) * wordSize),
      );
      if (i >= numRequired) {
        _asm.b(labels[i + 1 - numRequired], .equal);
      } else if (i + 1 >= numRequired) {
        _asm.cmp(argCountReg, Immediate((i + 1 - typeArg) << smiShift));
        _asm.b(labels[i + 1 - numRequired], .equal);
      }
    }
    for (; i < total; ++i) {
      if (i >= numRequired) {
        _asm.cmp(argCountReg, Immediate((i - typeArg) << smiShift));
        _asm.b(labels[i - numRequired], .equal);
      }
      final reg = (i < argumentRegisters.length)
          ? argumentRegisters[i]
          : tempReg;
      _asm.ldr(reg, _asm.address(argPtrReg, baseOffset - i * wordSize));
      if (i >= argumentRegisters.length) {
        _asm.str(
          reg,
          _asm.address(FP, stackFrame.shadowParameterOffsetFromFP(i)),
        );
      }
    }
    final done = Label();
    _asm.b(done);
    for (var i = numRequired; i < total; ++i) {
      _asm.bind(labels[i - numRequired]);
      final reg = (i < argumentRegisters.length)
          ? argumentRegisters[i]
          : tempReg;
      _asm.loadConstant(reg, function.getParameterDefaultValue(i));
      if (i >= argumentRegisters.length) {
        _asm.str(
          reg,
          _asm.address(FP, stackFrame.shadowParameterOffsetFromFP(i)),
        );
      }
    }
    _asm.bind(done);
  }

  /// Load required positional and named arguments into argument registers,
  /// filling in the default values if optional arguments are not passed.
  /// Extra arguments are copied to the shadow parameters area on the stack.
  void _prepareNamedParameters(CFunction function) {
    final argPtrReg = prologueScratchRegisters[0];
    final argNameReg = prologueScratchRegisters[1];

    final numRequired = function.numberOfRequiredPositionalParameters;
    final total = function.numberOfParameters;
    assert(numRequired < total);

    // TODO: compressed pointers
    // Load number of arguments (without type arguments) as a Smi.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        argumentsDescriptorReg,
        vmOffsets.ArgumentsDescriptor_count_offset,
      ),
    );
    // Type arguments are passed as the first required positional parameter,
    // but it is not counted in [ArgumentsDescriptor.count].
    final typeArg = function.hasFunctionTypeParameters ? 1 : 0;
    // Arguments pointer points to FP + [ArgumentsDescriptor.count]*wordSize.
    _asm.add(
      argPtrReg,
      FP,
      ShiftedRegOperand(tempReg, .LSL, log2wordSize - smiShift),
    );
    // Offset of the first argument, relative to argPtrReg.
    final int baseOffset =
        Arm64StackFrame.lastParameterOffsetFromFP + (typeArg - 1) * wordSize;

    var i = 0;
    final int numArgsToLoadInPairs = math.min(
      numRequired,
      argumentRegisters.length,
    );
    for (; i + 1 < numArgsToLoadInPairs; i += 2) {
      // TODO: pass arguments on registers and avoid these loads
      _asm.ldp(
        argumentRegisters[i + 1],
        argumentRegisters[i],
        _asm.pairAddress(argPtrReg, baseOffset - (i + 1) * wordSize),
      );
    }
    for (; i < numRequired; ++i) {
      final reg = (i < argumentRegisters.length)
          ? argumentRegisters[i]
          : tempReg;
      _asm.ldr(reg, _asm.address(argPtrReg, baseOffset - i * wordSize));
      if (i >= argumentRegisters.length) {
        _asm.str(
          reg,
          _asm.address(FP, stackFrame.shadowParameterOffsetFromFP(i)),
        );
      }
    }

    // Each argument entry has 2 words: name and position.
    assert(vmOffsets.ArgumentsDescriptor_name_offset == 0);
    assert(vmOffsets.ArgumentsDescriptor_position_offset == wordSize);
    assert(vmOffsets.ArgumentsDescriptor_named_entry_size == 2 * wordSize);

    // argumentsDescriptorReg points to the position field of the current argument.
    _asm.add(
      argumentsDescriptorReg,
      argumentsDescriptorReg,
      Immediate(
        vmOffsets.ArgumentsDescriptor_first_named_entry_offset +
            vmOffsets.ArgumentsDescriptor_position_offset,
      ),
    );

    if (!function.isRequiredParameter(numRequired)) {
      // Load name of the first optional named parameter.
      _asm.ldr(
        argNameReg,
        RegOffsetAddress(
          argumentsDescriptorReg,
          -vmOffsets.ArgumentsDescriptor_position_offset +
              vmOffsets.ArgumentsDescriptor_name_offset,
        ),
      );
    }

    for (i = numRequired; i < total; ++i) {
      Label? proceed;
      final destReg = (i < argumentRegisters.length)
          ? argumentRegisters[i]
          : tempReg;
      if (!function.isRequiredParameter(i)) {
        _asm.loadFromPool(tempReg, function.getParameterName(i));
        _asm.cmp(argNameReg, tempReg);
        final passed = Label();
        _asm.b(passed, .equal);

        _asm.loadConstant(destReg, function.getParameterDefaultValue(i));
        proceed = Label();
        _asm.b(proceed);

        _asm.bind(passed);
      }
      if (i + 1 < total && !function.isRequiredParameter(i + 1)) {
        // Load both position of this argument and the name of the next argument.
        _asm.ldp(
          tempReg,
          argNameReg,
          WritebackRegOffsetAddress(
            argumentsDescriptorReg,
            vmOffsets.ArgumentsDescriptor_named_entry_size,
            isPostIndexed: true,
          ),
        );
      } else {
        // Only load the position of this argument.
        _asm.ldr(
          tempReg,
          WritebackRegOffsetAddress(
            argumentsDescriptorReg,
            vmOffsets.ArgumentsDescriptor_named_entry_size,
            isPostIndexed: true,
          ),
        );
      }
      _asm.sub(
        tempReg,
        argPtrReg,
        ShiftedRegOperand(tempReg, .LSL, log2wordSize - smiShift),
      );
      _asm.ldr(destReg, RegOffsetAddress(tempReg, baseOffset));
      if (proceed != null) {
        _asm.bind(proceed);
      }
      if (i >= argumentRegisters.length) {
        _asm.str(
          destReg,
          _asm.address(FP, stackFrame.shadowParameterOffsetFromFP(i)),
        );
      }
    }
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

    for (var i = instr.inputCount - 1; i >= 0; --i) {
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
        // TODO: support large offsets
        _asm.stp(pendingReg, reg, RegOffsetAddress(stackPointerReg, offset));
        pendingReg = invalidReg;
        offset += 2 * wordSize;
      }
    }
    if (pendingReg != invalidReg) {
      // TODO: support large offsets
      _asm.str(pendingReg, RegOffsetAddress(stackPointerReg, offset));
      offset += wordSize;
    }
    assert(offset <= stackFrame.maxArgumentsStackSlots * wordSize);
  }

  void _callFunction(CFunction function) {
    // TODO: call directly through Code.
    _asm.loadFromPool(functionReg, function);
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
  void visitDirectCall(DirectCall instr) {
    _passArguments(instr);
    _asm.loadFromPool(argumentsDescriptorReg, instr.argumentsShape);
    _callFunction(instr.target);
  }

  @override
  void visitInterfaceCall(InterfaceCall instr) {
    _passArguments(instr);
    _asm.loadFromPool(argumentsDescriptorReg, instr.argumentsShape);
    // TODO: call through monomorphic/table dispatcher.
    _asm.loadFromPool(R6, graph.function);
    _asm.ldr(
      R0,
      _asm.address(
        stackPointerReg,
        (instr.inputCount - 1 - (instr.hasTypeArguments ? 1 : 0)) * wordSize,
      ),
    );
    _asm.loadPairFromPool(
      inlineCacheDataReg,
      codeReg,
      InterfaceCallEntry(
        graph.function,
        instr.argumentsShape,
        instr.interfaceTarget,
      ),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
    );
    _asm.blr(tempReg);
  }

  @override
  void visitDynamicCall(DynamicCall instr) {
    _passArguments(instr);
    _asm.loadFromPool(argumentsDescriptorReg, instr.argumentsShape);
    _asm.loadFromPool(R6, graph.function);
    _asm.ldr(
      R0,
      _asm.address(
        stackPointerReg,
        (instr.inputCount - 1 - (instr.hasTypeArguments ? 1 : 0)) * wordSize,
      ),
    );
    _asm.loadPairFromPool(
      inlineCacheDataReg,
      codeReg,
      DynamicCallEntry(
        graph.function,
        instr.argumentsShape,
        instr.kind,
        instr.selector,
      ),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
    );
    _asm.blr(tempReg);
  }

  @override
  void visitClosureCall(ClosureCall instr) {
    _passArguments(instr);
    _asm.loadFromPool(argumentsDescriptorReg, instr.argumentsShape);
    _asm.ldr(
      R0,
      _asm.address(
        stackPointerReg,
        (instr.inputCount - 1 - (instr.hasTypeArguments ? 1 : 0)) * wordSize,
      ),
    );
    _asm.ldr(
      functionReg,
      _asm.fieldAddress(R0, vmOffsets.Closure_function_offset),
    );
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
      _asm.address(objectReg, vmOffsets.Object_tags_offset, .u8),
      .u8,
    );
    _asm.ldr(
      scratch2Reg,
      _asm.address(valueReg, vmOffsets.Object_tags_offset, .u8),
      .u8,
    );
    _asm.and(
      scratch1Reg,
      scratch2Reg,
      ShiftedRegOperand(
        scratch1Reg,
        .LSR,
        vmOffsets.UntaggedObject_kBarrierOverlapShift,
      ),
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

  void _loadStaticFieldAddress(Register dst, CField field, Register scratch) {
    _asm.ldr(
      scratch,
      _asm.address(threadReg, vmOffsets.Thread_field_table_values_offset),
    );
    _asm.loadFromPool(dst, StaticFieldOffset(field));
    _asm.add(dst, dst, scratch);
  }

  @override
  void visitLoadStaticField(LoadStaticField instr) {
    final field = instr.field;
    final valueReg = outputReg(instr);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);

    // TODO: shared static fields
    _loadStaticFieldAddress(scratch1Reg, field, scratch2Reg);
    _asm.ldr(valueReg, RegOffsetAddress(scratch1Reg, 0));

    if (instr.checkInitialized) {
      _asm.loadFromPool(scratch2Reg, SentinelConstant());
      _asm.cmp(valueReg, scratch2Reg);

      final done = Label();
      Label slowPath = addSlowPath(() {
        if (hasNonTrivialInitializer(field.astField)) {
          _callFunction(
            functionRegistry.getFunction(field.astField, isInitializer: true),
          );
          assert(valueReg == returnReg);
          _loadStaticFieldAddress(scratch1Reg, field, scratch2Reg);

          if (field.isLate && field.isFinal) {
            final ok = Label();
            _asm.ldr(scratch2Reg, RegOffsetAddress(scratch1Reg, 0));
            _asm.loadFromPool(tempReg, SentinelConstant());
            _asm.cmp(scratch2Reg, tempReg);
            _asm.b(ok, .equal);
            _asm.unimplemented(
              'Unimplemented: already initialized late final field in LoadStaticField',
            );
            _asm.bind(ok);
          }

          _asm.str(valueReg, RegOffsetAddress(scratch1Reg, 0));
          _asm.b(done);
        } else {
          _asm.unimplemented(
            'Unimplemented: uninitialized late field without initializer in LoadStaticField',
          );
        }
      });

      _asm.b(slowPath, .equal);
      _asm.bind(done);
    }
  }

  @override
  void visitStoreStaticField(StoreStaticField instr) {
    final field = instr.field;
    final valueReg = inputReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);

    // TODO: shared static fields
    _loadStaticFieldAddress(scratch1Reg, field, scratch2Reg);

    if (instr.checkNotInitialized) {
      _asm.ldr(scratch2Reg, RegOffsetAddress(scratch1Reg, 0));
      _asm.loadFromPool(tempReg, SentinelConstant());
      _asm.cmp(scratch2Reg, tempReg);

      final done = Label();
      Label slowPath = addSlowPath(() {
        _asm.unimplemented(
          'Unimplemented: already initialized late final field in StoreStaticField',
        );
        _asm.b(done);
      });

      _asm.b(slowPath, .notEqual);
      _asm.bind(done);
    }

    _asm.str(valueReg, RegOffsetAddress(scratch1Reg, 0));
  }

  @override
  void visitThrow(Throw instr) {
    _asm.unimplemented('Unimplemented: code generation for Throw');
  }

  @override
  void visitNullCheck(NullCheck instr) {
    _asm.unimplemented('Unimplemented: code generation for NullCheck');
  }

  int _getNumberOfInputsForSubtypeTestCache(
    ast.DartType type, {
    required bool hasInstantiatorTypeArgs,
    required bool hasFunctionTypeArgs,
  }) {
    if (type is ast.ExtensionType) {
      type = type.extensionTypeErasure;
    }
    switch (type) {
      case ast.NullType():
      case ast.NeverType():
      case ast.InterfaceType() when type.classNode.typeParameters.isEmpty:
        return 1;
      case ast.InterfaceType():
      case ast.FutureOrType():
        if (hasFunctionTypeArgs) {
          return 4;
        }
        if (hasInstantiatorTypeArgs) {
          return 3;
        }
        return 2;
      case ast.FunctionType():
      case ast.RecordType():
      case ast.TypeParameterType():
        return 6;
      case ast.ExtensionType():
      case ast.DynamicType():
      case ast.VoidType():
      case ast.StructuralParameterType():
      case ast.IntersectionType():
      case ast.TypedefType():
      case ast.InvalidType():
      case ast.AuxiliaryType():
      case ast.ExperimentalType():
        throw 'Unexpected type ${type.runtimeType} $type';
    }
  }

  @override
  void visitTypeCast(TypeCast instr) {
    final operandReg = inputReg(instr, 0);
    final resultReg = outputReg(instr);
    if (operandReg != resultReg) {
      _asm.mov(resultReg, operandReg);
    }

    if (!instr.isChecked) {
      return;
    }

    final done = Label();
    late final Label slowPath = addSlowPath(() {
      _asm.unimplemented(
        'Unimplemented: code generation for TypeCast slow path',
      );
      _asm.b(done);
    });

    // Handle a few built-in types, use TTS for other types.
    final type = instr.testedType;
    switch (type) {
      case ObjectType():
        _asm.cmp(resultReg, nullReg);
        _asm.b(slowPath, .equal);
      case NullType():
        _asm.cmp(resultReg, nullReg);
        _asm.b(slowPath, .notEqual);
      case IntType():
        _asm.tbz(resultReg, smiBit, done);
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.MintCid.index);
        _asm.b(slowPath, .notEqual);
      case DoubleType():
        _asm.tbz(resultReg, smiBit, slowPath);
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.DoubleCid.index);
        _asm.b(slowPath, .notEqual);
      case BoolType():
        _asm.tbz(resultReg, smiBit, slowPath);
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.BoolCid.index);
        _asm.b(slowPath, .notEqual);
      case StringType():
        _asm.tbz(resultReg, smiBit, slowPath);
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.OneByteStringCid.index);
        _asm.b(done, .equal);
        _asm.cmpImmediate(tempReg, ClassId.TwoByteStringCid.index);
        _asm.b(slowPath, .notEqual);
      default:
        _asm.tbz(
          resultReg,
          smiBit,
          const IntType().isSubtypeOf(type) ? done : slowPath,
        );
        if (type.isNullable) {
          _asm.cmp(resultReg, nullReg);
          _asm.b(done, .equal);
        }
        final dartType = type.dartType;
        if (dartType is ast.TypeParameterType) {
          final declaration = dartType.parameter.declaration;
          assert(instr.inputCount == 3);
          final instantiatorTypeArgsReg = inputReg(instr, 1);
          final functionTypeArgsReg = inputReg(instr, 2);
          final typeArgsReg = (declaration is ast.Class)
              ? instantiatorTypeArgsReg
              : functionTypeArgsReg;
          final index = computeIndexOfTypeParameter(dartType.parameter);
          _asm.cmp(typeArgsReg, nullReg);
          _asm.b(done, .equal);
          _asm.ldr(
            TypeTestingStub.dstTypeReg,
            _asm.address(
              typeArgsReg,
              vmOffsets.TypeArguments_types_offset +
                  index * objectLayout.compressedWordSize,
            ),
          );
        } else {
          _asm.loadFromPool(TypeTestingStub.dstTypeReg, dartType);
        }
        _asm.ldr(
          tempReg,
          _asm.address(
            TypeTestingStub.dstTypeReg,
            vmOffsets.AbstractType_type_test_stub_entry_point_offset,
          ),
        );
        bool isNullConstant(Definition def) =>
            def is Constant && def.value.isNull;
        final hasInstantiatorTypeArgs =
            instr.inputCount > 1 && !isNullConstant(instr.inputDefAt(1));
        final hasFunctionTypeArgs =
            instr.inputCount > 1 && !isNullConstant(instr.inputDefAt(2));
        final stc = SubtypeTestCache(
          _getNumberOfInputsForSubtypeTestCache(
            dartType,
            hasInstantiatorTypeArgs: hasInstantiatorTypeArgs,
            hasFunctionTypeArgs: hasFunctionTypeArgs,
          ),
        );
        _asm.loadFromPool(TypeTestingStub.subtypeTestCacheReg, stc);
        _asm.blr(tempReg);
    }

    _asm.bind(done);
  }

  @override
  void visitTypeTest(TypeTest instr) {
    final operandReg = inputReg(instr, 0);
    final resultReg = outputReg(instr);
    final doneFalse = Label();
    final doneTrue = Label();
    final done = Label();

    // Handle a few built-in types, use STC for other types.
    final type = instr.testedType;
    switch (type) {
      case ObjectType():
        _asm.cmp(operandReg, nullReg);
        _asm.b(doneTrue, .notEqual);
      case NullType():
        _asm.cmp(operandReg, nullReg);
        _asm.b(doneTrue, .equal);
      case IntType():
        _asm.tbz(operandReg, smiBit, doneTrue);
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.MintCid.index);
        _asm.b(doneTrue, .equal);
      case DoubleType():
        _asm.tbz(operandReg, smiBit, doneFalse);
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.DoubleCid.index);
        _asm.b(doneTrue, .equal);
      case BoolType():
        _asm.tbz(operandReg, smiBit, doneFalse);
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.BoolCid.index);
        _asm.b(doneTrue, .equal);
      case StringType():
        _asm.tbz(operandReg, smiBit, doneFalse);
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.OneByteStringCid.index);
        _asm.b(doneTrue, .equal);
        _asm.cmpImmediate(tempReg, ClassId.TwoByteStringCid.index);
        _asm.b(doneTrue, .equal);
      default:
        if (const IntType().isSubtypeOf(type)) {
          _asm.tbz(operandReg, smiBit, doneTrue);
        }
        if (type.isNullable) {
          _asm.cmp(operandReg, nullReg);
          _asm.b(doneTrue, .equal);
        }
        bool isNullConstant(Definition def) =>
            def is Constant && def.value.isNull;
        final hasInstantiatorTypeArgs =
            instr.inputCount > 1 && !isNullConstant(instr.inputDefAt(1));
        final hasFunctionTypeArgs =
            instr.inputCount > 1 && !isNullConstant(instr.inputDefAt(2));
        final stc = SubtypeTestCache(
          _getNumberOfInputsForSubtypeTestCache(
            type.dartType,
            hasInstantiatorTypeArgs: hasInstantiatorTypeArgs,
            hasFunctionTypeArgs: hasFunctionTypeArgs,
          ),
        );
        final stub = switch (stc.numInputs) {
          1 => StubCode.Subtype1TestCache,
          2 => StubCode.Subtype2TestCache,
          3 => StubCode.Subtype3TestCache,
          4 => StubCode.Subtype4TestCache,
          6 => StubCode.Subtype6TestCache,
          _ =>
            throw 'Unexpected number of SubtypeTestCache inputs ${stc.numInputs} (type $type)',
        };

        final Label slowPath = addSlowPath(() {
          assert(stackFrame.maxArgumentsStackSlots >= 6);
          _asm.loadFromPool(tempReg, type.dartType);
          _asm.stp(
            TypeTestingStub.subtypeTestCacheReg,
            hasFunctionTypeArgs
                ? TypeTestingStub.functionTypeArgumentsReg
                : nullReg,
            RegOffsetAddress(stackPointerReg, 0),
          );
          _asm.stp(
            hasInstantiatorTypeArgs
                ? TypeTestingStub.instantiatorTypeArgumentsReg
                : nullReg,
            tempReg,
            RegOffsetAddress(stackPointerReg, 2 * wordSize),
          );
          _asm.stp(
            TypeTestingStub.instanceReg,
            nullReg, // Space for result
            RegOffsetAddress(stackPointerReg, 4 * wordSize),
          );
          _asm.callRuntime(RuntimeEntry.Instanceof, 5);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 5 * wordSize));
          _asm.b(done);
        });

        _asm.loadFromPool(TypeTestingStub.subtypeTestCacheReg, stc);
        _asm.loadFromPool(codeReg, stub);
        _asm.ldr(
          tempReg,
          _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
        );
        _asm.blr(tempReg);
        _asm.cmp(TypeTestingStub.subtypeTestCacheResultReg, nullReg);
        _asm.b(slowPath, .equal);
        _asm.mov(resultReg, TypeTestingStub.subtypeTestCacheResultReg);
        _asm.b(done);
    }

    _asm.bind(doneFalse);
    _asm.loadConstant(resultReg, ConstantValue.fromBool(false));
    _asm.b(done);
    _asm.bind(doneTrue);
    _asm.loadConstant(resultReg, ConstantValue.fromBool(true));
    _asm.bind(done);
  }

  @override
  void visitTypeArguments(TypeArguments instr) {
    _asm.unimplemented('Unimplemented: code generation for TypeArguments');
  }

  @override
  void visitTypeLiteral(TypeLiteral instr) {
    final instantiatorTypeArgsReg = inputReg(instr, 0);
    final functionTypeArgsReg = inputReg(instr, 1);
    final resultReg = outputReg(instr);
    final type = instr.uninstantiatedType;
    if (type is ast.TypeParameterType &&
        type.nullability != ast.Nullability.nullable) {
      final declaration = type.parameter.declaration;
      final index = computeIndexOfTypeParameter(type.parameter);
      final typeArgsReg = (declaration is ast.Class)
          ? instantiatorTypeArgsReg
          : functionTypeArgsReg;
      final done = Label();
      if (resultReg != typeArgsReg) {
        _asm.mov(resultReg, nullReg);
      }
      _asm.cmp(typeArgsReg, nullReg);
      _asm.b(done, .equal);
      _asm.ldr(
        resultReg,
        _asm.address(
          typeArgsReg,
          vmOffsets.TypeArguments_types_offset +
              index * objectLayout.compressedWordSize,
        ),
      );
      _asm.bind(done);
      return;
    }
    assert(stackFrame.maxArgumentsStackSlots >= 4);
    _asm.loadFromPool(tempReg, type);
    _asm.stp(
      functionTypeArgsReg,
      instantiatorTypeArgsReg,
      RegOffsetAddress(stackPointerReg, 0),
    );
    _asm.stp(tempReg, nullReg, RegOffsetAddress(stackPointerReg, 2 * wordSize));
    _asm.callRuntime(RuntimeEntry.InstantiateType, 3);
    _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 3 * wordSize));
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

    _asm.loadFromPool(tagsReg, NewObjectTags(cls));
    _asm.inlineAllocation(
      resultReg,
      tagsReg,
      AllocationStub.scratch1Reg,
      AllocationStub.scratch2Reg,
      instanceSize,
      slowPath,
      initializeFields: true,
    );

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
    final cls = GlobalContext.instance.coreTypes.index.getClass(
      'dart:core',
      '_Closure',
    );
    final instanceSize = objectLayout.getInstanceSize(cls);
    final resultReg = AllocationStub.resultReg;
    assert(outputReg(instr) == resultReg);

    final initializeObject = Label();
    Label slowPath = addSlowPath(() {
      _asm.callStub(backEndState.stubFactory.getAllocationStub(cls));
      _asm.b(initializeObject);
    });

    _asm.loadImmediate(
      AllocationStub.tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.ClosureCid,
        instanceSize,
        log2wordSize,
      ),
    );
    _asm.inlineAllocation(
      resultReg,
      AllocationStub.tagsReg,
      AllocationStub.scratch1Reg,
      AllocationStub.scratch2Reg,
      instanceSize,
      slowPath,
      initializeFields: true,
    );

    _asm.bind(initializeObject);
    final fieldReg = AllocationStub.scratch1Reg;
    _asm.loadFromPool(fieldReg, instr.function);
    _asm.str(
      fieldReg,
      _asm.fieldAddress(resultReg, vmOffsets.Closure_function_offset),
    );
    // TODO: initialize the rest of the fields.
    assert(instr.inputCount == 0);
  }

  @override
  void visitAllocateList(AllocateList instr) {
    final tagsReg = temporaryReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 1);
    final scratch2Reg = temporaryReg(instr, 2);
    final resultReg = outputReg(instr);
    // TODO: support AllocateList with non-constant length
    final length = (instr.length as Constant).value.intValue;
    assert(objectLayout.isSmi(length));
    final instanceSize = roundUp(
      vmOffsets.Array_data_offset + length * objectLayout.compressedWordSize,
      objectAlignment(wordSize),
    );
    assert(outputReg(instr) == resultReg);

    final done = Label();
    Label slowPath = addSlowPath(() {
      _asm.unimplemented(
        'Unimplemented: code generation for AllocateList slow path',
      );
      _asm.b(done);
    });

    _asm.loadImmediate(
      tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.ArrayCid,
        instanceSize,
        log2wordSize,
      ),
    );
    _asm.inlineAllocation(
      resultReg,
      tagsReg,
      scratch1Reg,
      scratch2Reg,
      instanceSize,
      slowPath,
      initializeFields: true,
    );

    _asm.bind(done);
    _asm.loadImmediate(scratch1Reg, length << smiShift);
    _asm.str(
      scratch1Reg,
      _asm.fieldAddress(resultReg, vmOffsets.Array_length_offset),
    );
  }

  @override
  void visitSetListElement(SetListElement instr) {
    final listReg = inputReg(instr, 0);
    final valueReg = inputReg(instr, 2);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);
    // TODO: support SetListElement with non-constant index
    final index = (instr.index as Constant).value.intValue;
    _asm.str(
      valueReg,
      _asm.fieldAddress(
        listReg,
        vmOffsets.Array_data_offset + index * objectLayout.compressedWordSize,
      ),
    );
    if (!_canSkipWriteBarrier(instr.list, instr.value)) {
      _writeBarrier(
        listReg,
        valueReg,
        scratch1Reg,
        scratch2Reg,
        valueCanBeSmi: _canBeSmi(instr.value),
      );
    }
  }

  @override
  void visitBoxInt(BoxInt instr) {
    var operandReg = inputReg(instr, 0);
    final tagsReg = temporaryReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 1);
    final scratch2Reg = temporaryReg(instr, 2);
    final resultReg = outputReg(instr);
    final done = Label();
    final instanceSize = vmOffsets.Mint_InstanceSize;

    Label slowPath = addSlowPath(() {
      _asm.unimplemented('Unimplemented: code generation for BoxInt slow path');
      _asm.b(done);
    });

    if (operandReg == resultReg) {
      _asm.mov(tempReg, operandReg);
      operandReg = tempReg;
    }

    _asm.adds(resultReg, operandReg, operandReg);
    _asm.b(done, .noOverflow);

    _asm.loadImmediate(
      tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.MintCid,
        instanceSize,
        log2wordSize,
      ),
    );
    _asm.inlineAllocation(
      resultReg,
      tagsReg,
      scratch1Reg,
      scratch2Reg,
      instanceSize,
      slowPath,
      initializeFields: false,
    );
    _asm.str(
      operandReg,
      _asm.fieldAddress(resultReg, vmOffsets.Mint_value_offset),
    );
    _asm.bind(done);
  }

  @override
  void visitBoxDouble(BoxDouble instr) {
    final operandReg = inputFPReg(instr, 0);
    final tagsReg = temporaryReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 1);
    final scratch2Reg = temporaryReg(instr, 2);
    final resultReg = outputReg(instr);
    final done = Label();
    final instanceSize = vmOffsets.Double_InstanceSize;

    Label slowPath = addSlowPath(() {
      _asm.unimplemented(
        'Unimplemented: code generation for BoxDouble slow path',
      );
      _asm.b(done);
    });

    _asm.loadImmediate(
      tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.DoubleCid,
        instanceSize,
        log2wordSize,
      ),
    );
    _asm.inlineAllocation(
      resultReg,
      tagsReg,
      scratch1Reg,
      scratch2Reg,
      instanceSize,
      slowPath,
      initializeFields: false,
    );
    _asm.fstr(
      operandReg,
      _asm.fieldAddress(resultReg, vmOffsets.Double_value_offset),
    );
    _asm.bind(done);
  }

  @override
  void visitUnboxInt(UnboxInt instr) {
    var operandReg = inputReg(instr, 0);
    final resultReg = outputReg(instr);
    final done = Label();

    if (operandReg == resultReg) {
      _asm.mov(tempReg, operandReg);
      operandReg = tempReg;
    }

    _asm.asr(resultReg, operandReg, smiShift);
    _asm.tbz(operandReg, smiBit, done);
    _asm.ldr(
      resultReg,
      _asm.fieldAddress(operandReg, vmOffsets.Mint_value_offset),
    );
    _asm.bind(done);
  }

  @override
  void visitUnboxDouble(UnboxDouble instr) {
    final operandReg = inputReg(instr, 0);
    final resultReg = outputFPReg(instr);
    _asm.fldr(
      resultReg,
      _asm.fieldAddress(operandReg, vmOffsets.Double_value_offset),
    );
  }

  @override
  void visitBinaryIntOp(BinaryIntOp instr) {
    final leftReg = inputReg(instr, 0);
    final right = instr.right;
    final resultReg = outputReg(instr);
    switch (instr.op) {
      case .add:
      case .sub:
        final (rightOperand, negated) = _generateAddSubRightOperand(
          instr,
          right,
        );
        if ((instr.op == .sub) == negated) {
          _asm.add(resultReg, leftReg, rightOperand);
        } else {
          _asm.sub(resultReg, leftReg, rightOperand);
        }
        break;
      case .mul:
        Register rightReg;
        if (right is Constant) {
          rightReg = tempReg;
          _asm.loadConstant(rightReg, right.value);
        } else {
          rightReg = inputReg(instr, 1);
        }
        _asm.mul(resultReg, leftReg, rightReg);
        break;
      case .truncatingDiv:
      case .mod:
      case .rem:
        _asm.unimplemented(
          'Unimplemented: code generation for BinaryIntOp ${instr.op.token}',
        );
        break;
      case .bitOr:
      case .bitAnd:
      case .bitXor:
        final rightOperand = _generateLogicalRightOperand(instr, right);
        switch (instr.op) {
          case .bitOr:
            _asm.orr(resultReg, leftReg, rightOperand);
            break;
          case .bitAnd:
            _asm.and(resultReg, leftReg, rightOperand);
            break;
          case .bitXor:
            _asm.eor(resultReg, leftReg, rightOperand);
            break;
          default:
            throw "Unexpected logical op ${instr.op}";
        }
        break;
      case .shiftLeft:
      case .shiftRight:
      case .unsignedShiftRight:
        final done = Label();
        late final Label slowPath = addSlowPath(() {
          _asm.unimplemented(
            'Unimplemented: code generation for slow path of BinaryIntOp ${instr.op.token}',
          );
          _asm.b(done);
        });
        if (right is Constant) {
          final shift = right.value.intValue;
          if (shift < 0) {
            _asm.b(slowPath);
          } else if (shift > 0 && shift < 64) {
            switch (instr.op) {
              case .shiftLeft:
                _asm.lsl(resultReg, leftReg, shift);
                break;
              case .shiftRight:
                _asm.asr(resultReg, leftReg, shift);
                break;
              case .unsignedShiftRight:
                _asm.lsr(resultReg, leftReg, shift);
                break;
              default:
                throw "Unexpected shift op ${instr.op}";
            }
          } else {
            // Guaranteed by simplification pass.
            throw 'Unexpected shift amount $shift';
          }
        } else {
          final rightReg = inputReg(instr, 1);
          _asm.cmp(rightReg, Immediate(63));
          _asm.b(slowPath, .unsignedGreater);
          switch (instr.op) {
            case .shiftLeft:
              _asm.lslv(resultReg, leftReg, rightReg);
              break;
            case .shiftRight:
              _asm.asrv(resultReg, leftReg, rightReg);
              break;
            case .unsignedShiftRight:
              _asm.lsrv(resultReg, leftReg, rightReg);
              break;
            default:
              throw "Unexpected shift op ${instr.op}";
          }
        }
        _asm.bind(done);
        break;
    }
  }

  @override
  void visitUnaryIntOp(UnaryIntOp instr) {
    _asm.unimplemented(
      'Unimplemented: code generation for UnaryIntOp ${instr.op.token}',
    );
  }

  @override
  void visitBinaryDoubleOp(BinaryDoubleOp instr) {
    _asm.unimplemented(
      'Unimplemented: code generation for BinaryDoubleOp ${instr.op.token}',
    );
  }

  @override
  void visitUnaryDoubleOp(UnaryDoubleOp instr) {
    _asm.unimplemented(
      'Unimplemented: code generation for UnaryDoubleOp ${instr.op.token}',
    );
  }

  @override
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    _asm.unimplemented(
      'Unimplemented: code generation for UnaryBoolOp ${instr.op.token}',
    );
  }

  @override
  Location getMoveTempRegister(RegisterClass registerClass) =>
      switch (registerClass) {
        .cpu => tempReg,
        .fpu => fpTempReg,
      };

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

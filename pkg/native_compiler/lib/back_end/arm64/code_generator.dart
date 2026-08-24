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
import 'package:native_compiler/runtime/names.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:vm/modular/transformations/pragma.dart';

final class Arm64CodeGenerator extends CodeGenerator {
  final FunctionRegistry functionRegistry;
  late final Arm64Assembler _asm;

  late final CFunction _asyncStarStreamControllerAdd = functionRegistry
      .getFunction(
        GlobalContext.instance.coreLibraries.getProcedure(
          'dart:async',
          '_AsyncStarStreamController',
          'add',
        ),
      );
  late final CFunction _asyncStarStreamControllerAddStream = functionRegistry
      .getFunction(
        GlobalContext.instance.coreLibraries.getProcedure(
          'dart:async',
          '_AsyncStarStreamController',
          'addStream',
        ),
      );

  late final CField _syncStarIteratorCurrent = CField(
    GlobalContext.instance.coreLibraries.getField(
      'dart:async',
      '_SyncStarIterator',
      '_current',
    ),
  );

  late final CField _syncStarIteratorYieldStarIterable = CField(
    GlobalContext.instance.coreLibraries.getField(
      'dart:async',
      '_SyncStarIterator',
      '_yieldStarIterable',
    ),
  );

  Arm64CodeGenerator(
    super.backEndState,
    super.asmIntrinsics,
    this.functionRegistry,
  );

  @override
  Assembler createAssembler() => _asm = Arm64Assembler(
    backEndState.vmOffsets,
    addCallSiteMetadata,
    backEndState.objectLayout,
  );

  @override
  void enterFrame() {
    _asm.enterDartFrame();
    _asm.subImmediate(
      stackPointerReg,
      stackPointerReg,
      stackFrame.frameSizeInSlots * wordSize,
    );
    final function = graph.function;
    if (function.hasOptionalPositionalParameters) {
      _prepareOptionalPositionalParameters(function);
    } else if (function.hasNamedParameters) {
      _prepareNamedParameters(function);
    }
    if (function.isSuspendable) {
      _asm.str(nullReg, _asm.address(FP, stackFrame.suspendStateOffsetFromFP));
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
        vmOffsets.ArgumentsDescriptor_first_named_entry_offset -
            heapObjectTag +
            vmOffsets.ArgumentsDescriptor_position_offset,
      ),
    );

    final namedParams = [
      for (var i = numRequired; i < total; ++i)
        (
          name: function.getParameterName(i),
          index: i,
          isRequired: function.isRequiredParameter(i),
        ),
    ];
    namedParams.sort((a, b) => a.name.compareTo(b.name));

    if (!namedParams.first.isRequired) {
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

    for (i = 0; i < namedParams.length; ++i) {
      Label? proceed;
      final param = namedParams[i];
      final destReg = (param.index < argumentRegisters.length)
          ? argumentRegisters[param.index]
          : tempReg;
      if (!param.isRequired) {
        _asm.loadFromPool(tempReg, param.name);
        _asm.cmp(argNameReg, tempReg);
        final passed = Label();
        _asm.b(passed, .equal);

        _asm.loadConstant(
          destReg,
          function.getParameterDefaultValue(param.index),
        );
        proceed = Label();
        _asm.b(proceed);

        _asm.bind(passed);
      }
      if (i + 1 < namedParams.length && !namedParams[i + 1].isRequired) {
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
      if (param.index >= argumentRegisters.length) {
        _asm.str(
          destReg,
          _asm.address(FP, stackFrame.shadowParameterOffsetFromFP(param.index)),
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
    _generateBranch(instr.trueSuccessor, instr.falseSuccessor, (
      bool value,
      Label label,
    ) {
      _asm.branchIfBoolIs(cond, value, label);
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
        final (operand, negated) = _generateAddSubRightOperand(
          instr,
          right,
          isUnboxed: instr.op.isIntComparison,
        );
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
    Definition right, {
    required bool isUnboxed,
  }) {
    if (right is Constant) {
      if (right.value.isInt) {
        int value = right.value.intValue;
        if (!isUnboxed) {
          value = value << smiShift;
        }
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
    switch (graph.function.asyncMarker) {
      case .Async:
        _asm.jumpVmStub(
          instr.value.type.canBeFuture
              ? StubCode.ReturnAsync
              : StubCode.ReturnAsyncNotFuture,
        );
        return;
      case .AsyncStar:
        _asm.jumpVmStub(StubCode.ReturnAsyncStar);
        return;
      case .SyncStar:
        // Overwrite the return value to indicate the end of iteration.
        _asm.loadConstant(returnReg, ConstantValue.fromBool(false));
        break;
      case .Sync:
        break;
    }
    _asm.leaveDartFrame();
    _asm.ret();
  }

  @override
  void visitUnreachable(Unreachable instr) {
    _asm.unimplemented('Unreachable: ${instr.message}');
  }

  @override
  void visitComparison(Comparison instr) {
    final right = instr.right;
    final result = outputReg(instr);
    switch (instr.op) {
      case .equal:
      case .notEqual:
      case .intEqual:
      case .intNotEqual:
      case .intLess:
      case .intLessOrEqual:
      case .intGreater:
      case .intGreaterOrEqual:
        final left = inputReg(instr, 0);
        final (operand, negated) = _generateAddSubRightOperand(
          instr,
          right,
          isUnboxed: instr.op.isIntComparison,
        );
        if (negated) {
          _asm.cmn(left, operand);
        } else {
          _asm.cmp(left, operand);
        }
        break;
      case .intTestIsZero:
      case .intTestIsNotZero:
        final left = inputReg(instr, 0);
        final operand = _generateLogicalRightOperand(instr, right);
        _asm.tst(left, operand);
        break;
      case .doubleEqual:
      case .doubleNotEqual:
      case .doubleLess:
      case .doubleLessOrEqual:
      case .doubleGreater:
      case .doubleGreaterOrEqual:
        final left = inputFPReg(instr, 0);
        if (right is Constant && right.value.isZero) {
          _asm.fcmp(left, Immediate(0));
        } else {
          _asm.fcmp(left, inputFPReg(instr, 1));
        }
        break;
      case .identical:
      case .notIdentical:
        _generateIdentical(instr);
        break;
    }
    _asm.loadConstant(result, ConstantValue.fromBool(true));
    _asm.loadConstant(tempReg, ConstantValue.fromBool(false));
    _asm.csel(result, result, tempReg, instr.op.conditionCode);
  }

  void _generateIdentical(Comparison instr) {
    assert((instr.op == .identical) || (instr.op == .notIdentical));
    final leftReg = inputReg(instr, 0);
    final rightReg = inputReg(instr, 1);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);
    final done = Label();
    final notDouble = Label();
    final compareValues = Label();

    // Same value => identical.
    _asm.cmp(leftReg, rightReg);
    _asm.b(done, .equal); // Z is set.

    // Any Smi => not identical.
    _asm.and(tempReg, leftReg, rightReg);
    _asm.tbz(tempReg, smiBit, done); // Z is not set (from previous cmp).

    _asm.loadClassId(scratch1Reg, leftReg);
    _asm.loadClassId(scratch2Reg, rightReg);

    // Different class ids => not identical.
    _asm.cmp(scratch1Reg, scratch2Reg);
    _asm.b(done, .notEqual); // Z is not set.

    _asm.cmpImmediate(scratch1Reg, ClassId.DoubleCid.index);
    _asm.b(notDouble, .notEqual);

    _asm.ldr(
      scratch1Reg,
      _asm.fieldAddress(leftReg, vmOffsets.Double_value_offset),
    );
    _asm.ldr(
      scratch2Reg,
      _asm.fieldAddress(rightReg, vmOffsets.Double_value_offset),
    );
    _asm.b(compareValues);

    _asm.bind(notDouble);
    _asm.cmpImmediate(scratch1Reg, ClassId.MintCid.index);
    _asm.b(done, .notEqual); // Z is not set.

    _asm.ldr(
      scratch1Reg,
      _asm.fieldAddress(leftReg, vmOffsets.Mint_value_offset),
    );
    _asm.ldr(
      scratch2Reg,
      _asm.fieldAddress(rightReg, vmOffsets.Mint_value_offset),
    );

    _asm.bind(compareValues);
    _asm.cmp(scratch1Reg, scratch2Reg);

    _asm.bind(done);
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
        if (loc is Register) {
          reg = loc;
        } else {
          reg = getTempReg();
          generateMove(loc, reg);
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
    recordOutgoingArgumentsAtSafepoint(.dartCall, instr.inputCount);
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
    addCallSiteMetadata(.dartCall);
  }

  void _callRuntime(RuntimeEntry entry, int argumentCount) {
    recordOutgoingArgumentsAtSafepoint(.runtimeCall, argumentCount + 1);
    _asm.callRuntime(entry, argumentCount);
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
    addCallSiteMetadata(.dartCall);
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
    addCallSiteMetadata(.dartCall);
  }

  @override
  void visitExternalCall(ExternalCall instr) {
    _passArguments(instr);
    // ExternalCall instruction takes an extra `null` input to reserve
    // slot for the return value in the stack frame.
    final numArgs = instr.inputCount - 1;
    assert(numArgs < (1 << vmOffsets.NativeArguments_kArgcBitsSize));
    final argcTag =
        (numArgs << vmOffsets.NativeArguments_kArgcBitsPos) |
        (instr.target.hasFunctionTypeParameters
            ? (1 << vmOffsets.NativeArguments_kGenericFunctionBitPos)
            : 0);
    _asm.addImmediate(
      CallBootstrapNativeStub.firstArgPointerReg,
      stackPointerReg,
      (1 /* slot for result */ + numArgs - 1) * wordSize,
    );
    _asm.loadImmediate(CallBootstrapNativeStub.argcTagReg, argcTag);
    _asm.loadFromPool(
      CallBootstrapNativeStub.nativeFunctionReg,
      NativeFunction(instr.target),
    );
    _asm.callVmStub(StubCode.CallBootstrapNative);
    _asm.ldr(returnReg, _asm.address(stackPointerReg, 0));
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
    addCallSiteMetadata(.dartCall);
  }

  @override
  void visitParameter(Parameter instr) {
    if (instr.isCatchParameter &&
        !instr.variable.isExceptionVariable &&
        !instr.variable.isStackTraceVariable) {
      _asm.unimplemented('Unimplemented: code generation for catch Parameter');
    }
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
    final field = instr.field;

    if (field == objectLayout.Object_classId) {
      _asm.loadClassId(valueReg, objectReg);
      return;
    }

    final fieldOffset = objectLayout.getFieldOffset(field);
    final memoryOrder = objectLayout.getFieldMemoryOrder(field);
    switch (memoryOrder) {
      case .relaxed:
        // TODO: compressed pointers, unboxed fields
        _asm.ldr(valueReg, _asm.fieldAddress(objectReg, fieldOffset));
      case .acquireRelease:
        _asm.addImmediate(tempReg, objectReg, fieldOffset - heapObjectTag);
        _asm.ldar(valueReg, tempReg);
    }
    if (instr.checkInitialized) {
      assert(valueReg != objectReg);
      assert(memoryOrder == .relaxed);

      _asm.loadFromPool(tempReg, SentinelConstant());
      _asm.cmp(valueReg, tempReg);

      final done = Label();
      Label slowPath = addSlowPath(() {
        if (hasNonTrivialInitializer(field.astField)) {
          assert(valueReg == returnReg);
          assert(stackFrame.maxArgumentsStackSlots >= 1);
          _asm.str(objectReg, RegOffsetAddress(stackPointerReg, 0));
          recordOutgoingArgumentsAtSafepoint(.dartCall, 1);
          _callFunction(
            functionRegistry.getFunction(field.astField, isInitializer: true),
          );
          // Reload object from the stack after the call.
          _asm.ldr(objectReg, RegOffsetAddress(stackPointerReg, 0));

          // TODO: consider moving this code into field initializer
          if (field.isLate && field.isFinal) {
            final ok = Label();
            final scratch1Reg = temporaryReg(instr, 0);
            _asm.ldr(scratch1Reg, _asm.fieldAddress(objectReg, fieldOffset));
            _asm.loadFromPool(tempReg, SentinelConstant());
            _asm.cmp(scratch1Reg, tempReg);
            _asm.b(ok, .equal);

            assert(stackFrame.maxArgumentsStackSlots >= 2);
            _asm.loadFromPool(tempReg, field.astField);
            _asm.stp(
              tempReg,
              nullReg, // Space for result.
              RegOffsetAddress(stackPointerReg, 0),
            );
            _callRuntime(
              RuntimeEntry.LateFieldAssignedDuringInitializationError,
              1,
            );
            _asm.breakpoint();

            _asm.bind(ok);
          }

          _asm.str(valueReg, _asm.fieldAddress(objectReg, fieldOffset));
          _asm.b(done);
        } else {
          assert(stackFrame.maxArgumentsStackSlots >= 2);
          _asm.loadFromPool(tempReg, field.astField);
          _asm.stp(
            tempReg,
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _callRuntime(RuntimeEntry.LateFieldNotInitializedError, 1);
          _asm.breakpoint();
        }
      });

      _asm.b(slowPath, .equal);
      _asm.bind(done);
    }
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
    Definition(:var type) => type.canBeInt,
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
      _asm.address(
        objectReg,
        vmOffsets.Object_tags_offset - heapObjectTag,
        .u8,
      ),
      .u8,
    );
    _asm.ldr(
      scratch2Reg,
      _asm.address(valueReg, vmOffsets.Object_tags_offset - heapObjectTag, .u8),
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
    final memoryOrder = objectLayout.getFieldMemoryOrder(instr.field);
    switch (memoryOrder) {
      case .relaxed:
        // TODO: compressed pointers, unboxed fields
        _asm.str(
          valueReg,
          _asm.fieldAddress(
            objectReg,
            objectLayout.getFieldOffset(instr.field),
          ),
        );
      case .acquireRelease:
        _asm.addImmediate(
          tempReg,
          objectReg,
          objectLayout.getFieldOffset(instr.field) - heapObjectTag,
        );
        _asm.stlr(valueReg, tempReg);
    }
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

  void _loadStaticFieldAddress(
    Register dst,
    CField field,
    Register scratch, {
    required bool isShared,
  }) {
    _asm.ldr(
      scratch,
      _asm.address(
        threadReg,
        isShared
            ? vmOffsets.Thread_shared_field_table_values_offset
            : vmOffsets.Thread_field_table_values_offset,
      ),
    );
    _asm.loadFromPool(dst, StaticFieldOffset(field));
    _asm.add(dst, dst, scratch);
  }

  @override
  void visitLoadStaticField(LoadStaticField instr) {
    final field = instr.field;
    final isShared = field.astField.isShared(GlobalContext.instance.coreTypes);
    final valueReg = outputReg(instr);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);

    // TODO: shared static fields with experiment enabled
    _loadStaticFieldAddress(
      scratch1Reg,
      field,
      scratch2Reg,
      isShared: isShared,
    );

    if (isShared) {
      _asm.ldar(valueReg, scratch1Reg);
    } else {
      _asm.ldr(valueReg, RegOffsetAddress(scratch1Reg, 0));
    }

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
          _loadStaticFieldAddress(
            scratch1Reg,
            field,
            scratch2Reg,
            isShared: isShared,
          );

          // TODO: consider moving this code into field initializer
          if (field.isLate && field.isFinal) {
            final ok = Label();
            _asm.ldr(scratch2Reg, RegOffsetAddress(scratch1Reg, 0));
            _asm.loadFromPool(tempReg, SentinelConstant());
            _asm.cmp(scratch2Reg, tempReg);
            _asm.b(ok, .equal);

            assert(stackFrame.maxArgumentsStackSlots >= 2);
            _asm.loadFromPool(tempReg, field.astField);
            _asm.stp(
              tempReg,
              nullReg, // Space for result.
              RegOffsetAddress(stackPointerReg, 0),
            );
            _callRuntime(
              RuntimeEntry.LateFieldAssignedDuringInitializationError,
              1,
            );
            _asm.breakpoint();

            _asm.bind(ok);
          }

          _asm.str(valueReg, RegOffsetAddress(scratch1Reg, 0));
          _asm.b(done);
        } else {
          assert(stackFrame.maxArgumentsStackSlots >= 2);
          _asm.loadFromPool(tempReg, field.astField);
          _asm.stp(
            tempReg,
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _callRuntime(RuntimeEntry.LateFieldNotInitializedError, 1);
          _asm.breakpoint();
        }
      });

      _asm.b(slowPath, .equal);
      _asm.bind(done);
    }
  }

  @override
  void visitStoreStaticField(StoreStaticField instr) {
    final field = instr.field;
    final isShared = field.astField.isShared(GlobalContext.instance.coreTypes);
    final valueReg = inputReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 0);
    final scratch2Reg = temporaryReg(instr, 1);

    // TODO: shared static fields with experiment enabled
    _loadStaticFieldAddress(
      scratch1Reg,
      field,
      scratch2Reg,
      isShared: isShared,
    );

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

    if (isShared) {
      _asm.stlr(valueReg, scratch1Reg);
    } else {
      _asm.str(valueReg, RegOffsetAddress(scratch1Reg, 0));
    }
  }

  @override
  void visitLoadExternalField(LoadExternalField instr) {
    final valueReg = outputReg(instr);
    final objectReg = instr.hasObject ? inputReg(instr, 0) : threadReg;
    _asm.ldr(
      valueReg,
      _asm.address(objectReg, objectLayout.getFieldOffset(instr.field)),
    );
  }

  @override
  void visitLoadArrayElement(LoadArrayElement instr) {
    OperandSize sz = instr.kind.elementSize(objectLayout);
    int offset = instr.kind.dataOffset(vmOffsets);
    Register baseReg = inputReg(instr, 0);
    final index = instr.index;
    if (index is Constant) {
      offset += index.value.intValue << sz.log2sizeInBytes;
    } else {
      final indexReg = inputReg(instr, 1);
      _asm.add(
        tempReg,
        baseReg,
        ShiftedRegOperand(indexReg, .LSL, sz.log2sizeInBytes),
      );
      baseReg = tempReg;
    }
    final resultReg = outputReg(instr);
    _asm.ldr(resultReg, _asm.address(baseReg, offset - heapObjectTag, sz), sz);
  }

  @override
  void visitStoreArrayElement(StoreArrayElement instr) {
    OperandSize sz = instr.kind.elementSize(objectLayout);
    int offset = instr.kind.dataOffset(vmOffsets);
    final Register arrayReg = inputReg(instr, 0);
    Register valueReg = inputReg(instr, 2);

    if (instr.kind == .uint8ClampedList) {
      // Clamp value to [0, 0xff] range.
      final scratchReg = temporaryReg(instr, 0);
      _asm.cmpImmediate(valueReg, 0xff);
      // x = value > 0xff ? 0xff : 0
      _asm.csetm(scratchReg, .greater);
      // y = value in range ? value : x
      _asm.csel(scratchReg, valueReg, scratchReg, .unsignedLessOrEqual);
      valueReg = scratchReg;
    }

    var baseReg = arrayReg;
    final index = instr.index;
    if (index is Constant) {
      offset += index.value.intValue << sz.log2sizeInBytes;
    } else {
      final indexReg = inputReg(instr, 1);
      _asm.add(
        tempReg,
        baseReg,
        ShiftedRegOperand(indexReg, .LSL, sz.log2sizeInBytes),
      );
      baseReg = tempReg;
    }
    _asm.str(valueReg, _asm.address(baseReg, offset - heapObjectTag, sz), sz);

    if (instr.kind == .fixedLengthList &&
        !_canSkipWriteBarrier(instr.array, instr.value)) {
      // TODO: array-specific write barrier.
      final scratch1Reg = temporaryReg(instr, 0);
      final scratch2Reg = temporaryReg(instr, 1);
      _writeBarrier(
        arrayReg,
        valueReg,
        scratch1Reg,
        scratch2Reg,
        valueCanBeSmi: _canBeSmi(instr.value),
      );
    }
  }

  @override
  void visitLoadExternalArrayElement(LoadExternalArrayElement instr) {
    final arrayReg = inputReg(instr, 0);
    final indexReg = inputReg(instr, 1);
    final resultReg = outputReg(instr);
    _asm.ldr(
      resultReg,
      RegExtRegAddress(arrayReg, indexReg, .UXTX, scaled: true),
    );
  }

  @override
  void visitThrow(Throw instr) {
    switch (instr.kind) {
      case .exception:
        assert(stackFrame.maxArgumentsStackSlots >= 2);
        _asm.stp(
          inputReg(instr, 0),
          nullReg, // Space for result.
          RegOffsetAddress(stackPointerReg, 0),
        );
        _callRuntime(RuntimeEntry.Throw, 1);
        _asm.breakpoint();
        break;
      case .rethrowException:
        assert(stackFrame.maxArgumentsStackSlots >= 4);
        _asm.stp(ZR, inputReg(instr, 1), RegOffsetAddress(stackPointerReg, 0));
        _asm.stp(
          inputReg(instr, 0),
          nullReg, // Space for result.
          RegOffsetAddress(stackPointerReg, 2 * wordSize),
        );
        _callRuntime(RuntimeEntry.ReThrow, 3);
        _asm.breakpoint();
        break;
      default:
        _asm.unimplemented(
          'Unimplemented: code generation for Throw with ${instr.kind}',
        );
    }
  }

  @override
  void visitNullCheck(NullCheck instr) {
    final operandReg = inputReg(instr, 0);
    final resultReg = outputReg(instr);
    if (operandReg != resultReg) {
      _asm.mov(resultReg, operandReg);
    }
    final Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 1);
      // Space for result.
      _asm.str(nullReg, RegOffsetAddress(stackPointerReg, 0));
      _callRuntime(RuntimeEntry.NullCastError, 0);
      _asm.breakpoint();
    });
    _asm.cmp(resultReg, nullReg);
    _asm.b(slowPath, .equal);
  }

  @override
  void visitIndexCheck(IndexCheck instr) {
    final indexReg = inputReg(instr, 0);
    final lengthReg = inputReg(instr, 1);
    final resultReg = outputReg(instr);
    final Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 1);
      _asm.stp(indexReg, lengthReg, RegOffsetAddress(stackPointerReg, 0));
      _asm.str(
        nullReg, // Space for result.
        RegOffsetAddress(stackPointerReg, 2 * wordSize),
      );
      _callRuntime(RuntimeEntry.RangeError, 2);
      _asm.breakpoint();
    });
    _asm.cmp(indexReg, lengthReg);
    _asm.b(slowPath, .unsignedGreaterOrEqual);
    if (indexReg != resultReg) {
      _asm.mov(resultReg, indexReg);
    }
  }

  @override
  void visitSubtypeCheck(SubtypeCheck instr) {
    final temp0Reg = temporaryReg(instr, 0);
    final temp1Reg = temporaryReg(instr, 1);
    // The arrangement of arguments on the stack for runtime call:
    //     args[0]  instantiator type args
    //     args[1]  function type args
    //     args[2]  sub_type
    //     args[3]  super_type
    //     args[4]  name
    //   no return value, but slot is still allocated for it
    const nArguments = 5;
    const nArgumentsPlusReturnResult = nArguments + 1;
    // Order of inputs is determined by _referencedTypeParameters in ast_to_ir.dart.
    final instantiatorTypeReg = inputReg(instr, 0);
    final functionTypeReg = inputReg(instr, 1);

    _asm.loadFromPool(temp0Reg, instr.name);
    _asm.loadFromPool(temp1Reg, instr.bound.dartType);
    assert(stackFrame.maxArgumentsStackSlots >= nArgumentsPlusReturnResult);
    _asm.stp(temp0Reg, temp1Reg, RegOffsetAddress(stackPointerReg, 0));
    _asm.loadFromPool(temp0Reg, instr.type.dartType);
    _asm.stp(
      temp0Reg,
      functionTypeReg,
      RegOffsetAddress(stackPointerReg, 2 * wordSize),
    );
    _asm.stp(
      instantiatorTypeReg,
      nullReg,
      RegOffsetAddress(stackPointerReg, 4 * wordSize),
    );
    _callRuntime(RuntimeEntry.SubtypeCheck, nArguments);
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

    final type = instr.testedType;
    final dartType = type.dartType;
    final done = Label();
    late final Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 3);
      _asm.loadFromPool(tempReg, dartType);
      _asm.stp(tempReg, resultReg, RegOffsetAddress(stackPointerReg, 0));
      _asm.str(
        nullReg, // Space for result.
        RegOffsetAddress(stackPointerReg, 2 * wordSize),
      );
      _callRuntime(RuntimeEntry.TypeError, 2);
      _asm.breakpoint();
    });

    // Handle a few built-in types, use TTS for other types.
    switch (type) {
      case ObjectType():
        _asm.cmp(resultReg, nullReg);
        _asm.b(slowPath, .equal);
      case NullType():
        _asm.cmp(resultReg, nullReg);
        _asm.b(slowPath, .notEqual);
      case IntType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(resultReg, smiBit, done);
        }
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.MintCid.index);
        _asm.b(slowPath, .notEqual);
      case DoubleType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(resultReg, smiBit, slowPath);
        }
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.DoubleCid.index);
        _asm.b(slowPath, .notEqual);
      case BoolType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(resultReg, smiBit, slowPath);
        }
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.BoolCid.index);
        _asm.b(slowPath, .notEqual);
      case StringType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(resultReg, smiBit, slowPath);
        }
        _asm.loadClassId(tempReg, resultReg);
        _asm.cmpImmediate(tempReg, ClassId.OneByteStringCid.index);
        _asm.b(done, .equal);
        _asm.cmpImmediate(tempReg, ClassId.TwoByteStringCid.index);
        _asm.b(slowPath, .notEqual);
      default:
        if (_canBeSmi(instr.operand)) {
          if (const IntType().isSubtypeOf(type)) {
            _asm.tbz(resultReg, smiBit, done);
          } else if (!type.canBeInt) {
            _asm.tbz(resultReg, smiBit, slowPath);
          }
        }
        if (type.isNullable && instr.operand.canBeNull) {
          _asm.cmp(resultReg, nullReg);
          _asm.b(done, .equal);
        }
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
            _asm.fieldAddress(
              typeArgsReg,
              vmOffsets.TypeArguments_types_offset +
                  index * objectLayout.compressedWordSize,
            ),
          );
        } else {
          _asm.loadFromPool(TypeTestingStub.dstTypeReg, dartType);
        }
        _asm.ldr(
          TypeTestingStub.entryPointReg,
          _asm.fieldAddress(
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
        if (instr.inputCount == 1) {
          _asm.mov(TypeTestingStub.instantiatorTypeArgumentsReg, nullReg);
          _asm.mov(TypeTestingStub.functionTypeArgumentsReg, nullReg);
        }
        // VM expects exact code pattern for type testing stub calling sequence.
        _asm.loadFromPool(
          TypeTestingStub.subtypeTestCacheReg,
          SubtypeTestCacheWithName(stc, Name('', null)),
        );
        _asm.blr(TypeTestingStub.entryPointReg);
        addCallSiteMetadata(.stubCall);
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
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(operandReg, smiBit, doneTrue);
        }
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.MintCid.index);
        _asm.b(doneTrue, .equal);
      case DoubleType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(operandReg, smiBit, doneFalse);
        }
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.DoubleCid.index);
        _asm.b(doneTrue, .equal);
      case BoolType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(operandReg, smiBit, doneFalse);
        }
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.BoolCid.index);
        _asm.b(doneTrue, .equal);
      case StringType():
        if (_canBeSmi(instr.operand)) {
          _asm.tbz(operandReg, smiBit, doneFalse);
        }
        _asm.loadClassId(tempReg, operandReg);
        _asm.cmpImmediate(tempReg, ClassId.OneByteStringCid.index);
        _asm.b(doneTrue, .equal);
        _asm.cmpImmediate(tempReg, ClassId.TwoByteStringCid.index);
        _asm.b(doneTrue, .equal);
      default:
        if (_canBeSmi(instr.operand)) {
          if (const IntType().isSubtypeOf(type)) {
            _asm.tbz(operandReg, smiBit, doneTrue);
          } else if (!type.canBeInt) {
            _asm.tbz(operandReg, smiBit, doneFalse);
          }
        }
        if (type.isNullable && instr.operand.canBeNull) {
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
          _callRuntime(RuntimeEntry.Instanceof, 5);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 5 * wordSize));
          _asm.b(done);
        });

        _asm.loadFromPool(TypeTestingStub.subtypeTestCacheReg, stc);
        _asm.callVmStub(stub);
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
    switch (computeTypeArgumentsReuse(instr.types)) {
      case .instantiator:
        _asm.mov(outputReg(instr), inputReg(instr, 0));
        return;
      case .function:
        _asm.mov(outputReg(instr), inputReg(instr, 1));
        return;
      case .none:
        break;
    }
    _asm.loadConstant(
      InstantiateTypeArgumentsStub.uninstantiatedTypeArgumentsReg,
      ConstantValue(TypeArgumentsConstant(instr.types)),
    );
    _asm.callVmStub(StubCode.InstantiateTypeArguments);
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
        _asm.fieldAddress(
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
    _callRuntime(RuntimeEntry.InstantiateType, 3);
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
    final function = instr.function;
    final closureLayout = instr.closureLayout;
    final lengthAndFlags = vmOffsets.encodeClosureLengthAndFlags(
      closureLayout.length,
      hasDelayedTypeArgs: closureLayout.hasDelayedTypeArgs,
      hasInstantiatorTypeArgs: closureLayout.hasClassTypeArgs,
      hasFunctionTypeArgs: closureLayout.hasFunctionTypeArgs,
    );
    final instanceSize = roundUp(
      vmOffsets.Closure_elementsStartOffset +
          closureLayout.length * objectLayout.compressedWordSize,
      objectAlignment(wordSize),
    );

    final resultReg = AllocationStub.resultReg;
    assert(outputReg(instr) == resultReg);

    final done = Label();
    Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 4);
      _asm.loadImmediate(tempReg, lengthAndFlags << smiShift);
      _asm.stp(
        nullReg, // Context.
        tempReg,
        RegOffsetAddress(stackPointerReg, 0),
      );
      _asm.loadFromPool(tempReg, function);
      _asm.stp(
        tempReg,
        nullReg, // Space for result.
        RegOffsetAddress(stackPointerReg, 2 * wordSize),
      );
      _callRuntime(RuntimeEntry.AllocateClosure, 3);
      _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 3 * wordSize));
      _asm.b(done);
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
    final fieldReg = AllocationStub.scratch1Reg;
    _asm.loadFromPool(fieldReg, function);
    _asm.str(
      fieldReg,
      _asm.fieldAddress(resultReg, vmOffsets.Closure_function_offset),
    );
    _asm.loadImmediate(fieldReg, lengthAndFlags << smiShift);
    _asm.str(
      fieldReg,
      _asm.fieldAddress(resultReg, vmOffsets.Closure_length_and_flags_offset),
    );
    _asm.str(ZR, _asm.fieldAddress(resultReg, vmOffsets.Closure_hash_offset));
    // TODO: initialize delayed type arguments.
    _asm.bind(done);
  }

  @override
  void visitAllocateContext(AllocateContext instr) {
    final instanceSize = roundUp(
      vmOffsets.Context_elementsStartOffset +
          instr.length * objectLayout.compressedWordSize,
      objectAlignment(wordSize),
    );
    final resultReg = AllocationStub.resultReg;
    assert(outputReg(instr) == resultReg);

    final done = Label();
    Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 2);
      _asm.loadImmediate(tempReg, instr.length << smiShift);
      _asm.stp(
        tempReg,
        nullReg, // Space for result.
        RegOffsetAddress(stackPointerReg, 0),
      );
      _callRuntime(RuntimeEntry.AllocateContext, 1);
      _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 1 * wordSize));
      _asm.b(done);
    });

    _asm.loadImmediate(
      AllocationStub.tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.ContextCid,
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
    final fieldReg = AllocationStub.scratch1Reg;
    _asm.loadImmediate(fieldReg, instr.length);
    _asm.str(
      fieldReg,
      _asm.fieldAddress(resultReg, vmOffsets.Context_num_variables_offset),
    );
    _asm.bind(done);
  }

  @override
  void visitAllocateArray(AllocateArray instr) {
    final arrayKind = instr.kind;
    final elemSize = arrayKind.elementSize(objectLayout);
    final headerSize = arrayKind.dataOffset(vmOffsets);
    final maxElements = arrayKind.maxNewSpaceElements(objectLayout);
    final classId = arrayKind.classId;
    final alignment = objectAlignment(wordSize);
    final tagsReg = temporaryReg(instr, 0);
    final scratch1Reg = temporaryReg(instr, 1);
    final scratch2Reg = temporaryReg(instr, 2);
    final instanceSizeReg = temporaryReg(instr, 3);
    final resultReg = outputReg(instr);
    final typeArgsReg = instr.hasTypeArguments ? inputReg(instr, 0) : nullReg;

    final lengthDef = instr.length;
    var lengthReg = invalidReg;
    var length = -1;
    var instanceSize = 0;
    if (lengthDef is Constant) {
      length = lengthDef.value.intValue;
      if (0 <= length && length <= maxElements) {
        instanceSize = roundUp(
          headerSize + (length << elemSize.log2sizeInBytes),
          alignment,
        );
      } else {
        lengthReg = tempReg;
        _asm.loadConstant(lengthReg, lengthDef.value);
      }
    } else {
      lengthReg = inputReg(instr, instr.hasTypeArguments ? 1 : 0);
    }

    final done = Label();
    Label slowPath = addSlowPath(() {
      if (lengthReg == invalidReg) {
        lengthReg = tempReg;
        _asm.loadConstant(lengthReg, (lengthDef as Constant).value);
      }
      switch (arrayKind) {
        case .fixedLengthList:
          assert(stackFrame.maxArgumentsStackSlots >= 3);
          _asm.stp(
            typeArgsReg, // Type arguments.
            lengthReg, // Array length.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _asm.str(
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 2 * wordSize),
          );
          _callRuntime(RuntimeEntry.AllocateArray, 2);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 2 * wordSize));
          break;
        case .oneByteString:
          assert(stackFrame.maxArgumentsStackSlots >= 2);
          _asm.stp(
            lengthReg, // Array length.
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _callRuntime(RuntimeEntry.AllocateOneByteString, 1);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, wordSize));
          break;
        case .twoByteString:
          assert(stackFrame.maxArgumentsStackSlots >= 2);
          _asm.stp(
            lengthReg, // Array length.
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _callRuntime(RuntimeEntry.AllocateTwoByteString, 1);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, wordSize));
          break;
        case .int8List ||
            .uint8List ||
            .uint8ClampedList ||
            .int16List ||
            .uint16List ||
            .int32List ||
            .uint32List ||
            .int64List ||
            .uint64List:
          assert(stackFrame.maxArgumentsStackSlots >= 3);
          _asm.loadImmediate(scratch1Reg, classId.index << smiShift);
          _asm.stp(
            lengthReg, // Array length.
            scratch1Reg, // Class ID.
            RegOffsetAddress(stackPointerReg, 0),
          );
          _asm.str(
            nullReg, // Space for result.
            RegOffsetAddress(stackPointerReg, 2 * wordSize),
          );
          _callRuntime(RuntimeEntry.AllocateTypedData, 2);
          _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 2 * wordSize));
          break;
      }
      _asm.b(done);
    });

    _asm.loadImmediate(
      tagsReg,
      vmOffsets.computeNewObjectTags(classId, instanceSize, log2wordSize),
    );

    if (lengthReg == invalidReg) {
      _asm.inlineAllocation(
        resultReg,
        tagsReg,
        scratch1Reg,
        scratch2Reg,
        instanceSize,
        slowPath,
        initializeFields: true,
        initValueReg: (arrayKind == .fixedLengthList) ? nullReg : ZR,
      );

      _asm.loadImmediate(tempReg, length << smiShift);
      _asm.str(
        tempReg,
        _asm.fieldAddress(resultReg, arrayKind.lengthFieldOffset(vmOffsets)),
      );

      final dataFieldOffset = arrayKind.dataFieldOffset(vmOffsets);
      if (dataFieldOffset != null) {
        _asm.addImmediate(tempReg, resultReg, headerSize - heapObjectTag);
        _asm.str(tempReg, _asm.fieldAddress(resultReg, dataFieldOffset));
      }
    } else {
      // Make sure length is a Smi and between 0 and maxElements.
      _asm.tbnz(lengthReg, smiBit, slowPath);
      _asm.cmpImmediate(lengthReg, maxElements << smiShift);
      _asm.b(slowPath, .unsignedGreater);

      // Compute instance size.
      final shift = elemSize.log2sizeInBytes - smiShift;
      if (shift < 0) {
        _asm.lsr(instanceSizeReg, lengthReg, -shift);
      } else {
        _asm.lsl(instanceSizeReg, lengthReg, shift);
      }
      _asm.addImmediate(
        instanceSizeReg,
        instanceSizeReg,
        headerSize + alignment - 1,
      );
      _asm.andImmediate(instanceSizeReg, instanceSizeReg, ~(alignment - 1));

      // Combine tags and size.
      final log2alignment = log2objectAlignment(log2wordSize);
      _asm.cmpImmediate(
        instanceSizeReg,
        (1 << (vmOffsets.UntaggedObject_kSizeTagSize + log2alignment)),
      );
      _asm.lsl(
        tempReg,
        instanceSizeReg,
        vmOffsets.UntaggedObject_kSizeTagPos - log2alignment,
      );
      _asm.csel(tempReg, ZR, tempReg, .unsignedGreaterOrEqual);
      _asm.orr(tagsReg, tagsReg, tempReg);

      _asm.inlineArrayAllocation(
        resultReg,
        tagsReg,
        instanceSizeReg,
        lengthReg,
        scratch1Reg,
        scratch2Reg,
        slowPath,
        initializeFields: true,
        lengthFieldOffset: arrayKind.lengthFieldOffset(vmOffsets),
        dataFieldOffset: arrayKind.dataFieldOffset(vmOffsets),
        headerSize: headerSize,
        initValueReg: (arrayKind == .fixedLengthList) ? nullReg : ZR,
      );
    }
    if (instr.hasTypeArguments) {
      assert(arrayKind == .fixedLengthList);
      _asm.str(
        typeArgsReg,
        _asm.fieldAddress(resultReg, vmOffsets.Array_type_arguments_offset),
      );
    }
    _asm.bind(done);
  }

  @override
  void visitAllocateRecord(AllocateRecord instr) {
    final instanceSize = roundUp(
      vmOffsets.Record_elementsStartOffset +
          instr.type.numFields * objectLayout.compressedWordSize,
      objectAlignment(wordSize),
    );
    final resultReg = AllocationStub.resultReg;
    assert(outputReg(instr) == resultReg);

    final done = Label();
    Label slowPath = addSlowPath(() {
      assert(stackFrame.maxArgumentsStackSlots >= 2);
      _asm.loadFromPool(tempReg, instr.type.shape);
      _asm.stp(
        tempReg, // Record shape.
        nullReg, // Space for result.
        RegOffsetAddress(stackPointerReg, 0),
      );
      _callRuntime(RuntimeEntry.AllocateRecord, 1);
      _asm.ldr(resultReg, RegOffsetAddress(stackPointerReg, 1 * wordSize));
      _asm.b(done);
    });

    _asm.loadImmediate(
      AllocationStub.tagsReg,
      vmOffsets.computeNewObjectTags(
        ClassId.RecordCid,
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
    final fieldReg = AllocationStub.scratch1Reg;
    _asm.loadFromPool(fieldReg, instr.type.shape);
    _asm.str(
      fieldReg,
      _asm.fieldAddress(resultReg, vmOffsets.Record_shape_offset),
    );
    _asm.bind(done);
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

    if (_canBeSmi(instr.operand)) {
      _asm.asr(resultReg, operandReg, smiShift);
      _asm.tbz(operandReg, smiBit, done);
    }
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
          isUnboxed: true,
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
    final operandReg = inputReg(instr, 0);
    switch (instr.op) {
      case .neg:
        _asm.neg(outputReg(instr), operandReg);
        break;
      case .bitNot:
        _asm.mvn(outputReg(instr), operandReg);
        break;
      case .toDouble:
        _asm.scvtf(outputFPReg(instr), operandReg);
        break;
      case .hash:
        final scratch = temporaryReg(instr, 0);
        final resultReg = outputReg(instr);
        _asm.loadImmediate(scratch, 0x2d51);
        _asm.mul(tempReg, operandReg, scratch);
        _asm.umulh(resultReg, operandReg, scratch);
        _asm.eor(resultReg, resultReg, tempReg);
        _asm.eor(resultReg, resultReg, ShiftedRegOperand(resultReg, .LSR, 32));
        _asm.ubfm(resultReg, resultReg, 63, 29);
        break;
      case .bitLength:
        final resultReg = outputReg(instr);
        // XOR with sign bit to complement bits if value is negative.
        _asm.eor(
          resultReg,
          operandReg,
          ShiftedRegOperand(operandReg, .ASR, 63),
        );
        _asm.clz(resultReg, resultReg);
        _asm.loadImmediate(tempReg, 64);
        _asm.sub(resultReg, tempReg, resultReg);
        break;
      default:
        _asm.unimplemented(
          'Unimplemented: code generation for UnaryIntOp ${instr.op.token}',
        );
    }
  }

  @override
  void visitBinaryDoubleOp(BinaryDoubleOp instr) {
    final leftReg = inputFPReg(instr, 0);
    final rightReg = inputFPReg(instr, 1);
    switch (instr.op) {
      case .add:
        _asm.fadd(outputFPReg(instr), leftReg, rightReg);
      case .sub:
        _asm.fsub(outputFPReg(instr), leftReg, rightReg);
      case .mul:
        _asm.fmul(outputFPReg(instr), leftReg, rightReg);
      case .div:
        _asm.fdiv(outputFPReg(instr), leftReg, rightReg);
      default:
        _asm.unimplemented(
          'Unimplemented: code generation for BinaryDoubleOp ${instr.op.token}',
        );
    }
  }

  @override
  void visitUnaryDoubleOp(UnaryDoubleOp instr) {
    _asm.unimplemented(
      'Unimplemented: code generation for UnaryDoubleOp ${instr.op.token}',
    );
  }

  @override
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    final operandReg = inputReg(instr, 0);
    final resultReg = outputReg(instr);
    switch (instr.op) {
      case .not:
        final boolValueBit = boolValueBitPosition(log2wordSize);
        _asm.eor(resultReg, operandReg, Immediate(1 << boolValueBit));
        break;
    }
  }

  @override
  void visitEnterSuspendableFunction(EnterSuspendableFunction instr) {
    final asyncMarker = graph.function.asyncMarker;
    final stub = switch (asyncMarker) {
      .Async => StubCode.InitAsync,
      .AsyncStar => StubCode.InitAsyncStar,
      .SyncStar => StubCode.InitSyncStar,
      .Sync => throw 'Unexpected async marker',
    };
    _asm.callVmStub(stub);
    // Suspend async* and sync* functions at the beginning.
    if (asyncMarker == .AsyncStar) {
      _asm.mov(SuspendStub.argumentReg, nullReg);
      _asm.callVmStub(StubCode.YieldAsyncStar);
    } else if (asyncMarker == .SyncStar) {
      _asm.mov(SuspendStub.argumentReg, nullReg);
      _asm.callVmStub(StubCode.SuspendSyncStarAtStart);
    }
  }

  @override
  void visitSuspend(Suspend instr) {
    void loadFunctionData(Register dst) {
      _asm.ldr(tempReg, _asm.address(FP, stackFrame.suspendStateOffsetFromFP));
      _asm.ldr(
        dst,
        _asm.fieldAddress(tempReg, vmOffsets.SuspendState_function_data_offset),
      );
    }

    switch (instr.op) {
      case .await:
        _asm.callVmStub(StubCode.Await);
        break;
      case .awaitWithTypeCheck:
        _asm.callVmStub(StubCode.AwaitWithTypeCheck);
        break;
      case .asyncYield || .asyncYieldStar:
        // Load controller from suspend state.
        loadFunctionData(tempReg);
        // Call controller.add or addStream.
        assert(stackFrame.maxArgumentsStackSlots >= 2);
        _asm.stp(
          SuspendStub.argumentReg,
          tempReg,
          RegOffsetAddress(stackPointerReg, 0),
        );
        recordOutgoingArgumentsAtSafepoint(.dartCall, 2);
        _callFunction(
          instr.op == .asyncYield
              ? _asyncStarStreamControllerAdd
              : _asyncStarStreamControllerAddStream,
        );
        // It returns true if subscription was canceled.
        final done = Label();
        _asm.branchIfBoolIs(returnReg, true, done);
        // Suspend.
        _asm.mov(SuspendStub.argumentReg, nullReg);
        _asm.callVmStub(StubCode.YieldAsyncStar);
        _asm.bind(done);
        break;
      case .syncYield || .syncYieldStar:
        // Load iterator from suspend state.
        final iteratorReg = temporaryReg(instr, 0);
        final scratch1Reg = temporaryReg(instr, 1);
        final scratch2Reg = temporaryReg(instr, 2);
        loadFunctionData(iteratorReg);
        // Set _SyncStarIterator._current or _yieldStarIterable.
        _asm.str(
          SuspendStub.argumentReg,
          _asm.fieldAddress(
            iteratorReg,
            objectLayout.getFieldOffset(
              instr.op == .syncYield
                  ? _syncStarIteratorCurrent
                  : _syncStarIteratorYieldStarIterable,
            ),
          ),
        );
        _writeBarrier(
          iteratorReg,
          SuspendStub.argumentReg,
          scratch1Reg,
          scratch2Reg,
          valueCanBeSmi: _canBeSmi(instr.operand),
        );
        // Suspend.
        _asm.mov(SuspendStub.argumentReg, nullReg);
        _asm.callVmStub(StubCode.SuspendSyncStarAtYield);
        break;
    }
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
          case FPRegister():
            _asm.fldr(to, _asm.address(FP, stackFrame.offsetFromFP(from)));
            return;
          default:
            break;
        }
      case FPRegister():
        switch (to) {
          case FPRegister():
            _asm.fmov(to, from);
            return;
          case StackLocation():
            _asm.fstr(from, _asm.address(FP, stackFrame.offsetFromFP(to)));
            return;
          default:
            break;
        }
      default:
        break;
    }
    throw 'Unexpected move ${from.runtimeType} $from -> ${to.runtimeType} $to';
  }

  @override
  void generateLoadConstant(ConstantValue value, Location to) {
    switch (to) {
      case Register():
        _asm.loadConstant(to, value);
        return;
      case FPRegister():
        assert(value.isDouble && value.isUnboxed);
        _asm.loadDoubleImmediate(to, value.doubleValue);
        return;
      case StackLocation():
        _asm.loadConstant(tempReg, value);
        _asm.str(tempReg, _asm.address(FP, stackFrame.offsetFromFP(to)));
        return;
    }
  }
}

extension on ComparisonOpcode {
  Condition get conditionCode => switch (this) {
    .equal => Condition.equal,
    .notEqual => Condition.notEqual,
    .identical => Condition.equal,
    .notIdentical => Condition.notEqual,
    .intEqual => Condition.equal,
    .intNotEqual => Condition.notEqual,
    .intLess => Condition.less,
    .intLessOrEqual => Condition.lessOrEqual,
    .intGreater => Condition.greater,
    .intGreaterOrEqual => Condition.greaterOrEqual,
    .intTestIsZero => Condition.equal,
    .intTestIsNotZero => Condition.notEqual,
    .doubleEqual => Condition.equal,
    .doubleNotEqual => Condition.notEqual,
    .doubleLess => Condition.unsignedLess, // LO
    .doubleLessOrEqual => Condition.unsignedLessOrEqual, // LS
    .doubleGreater => Condition.greater, // GT
    .doubleGreaterOrEqual => Condition.greaterOrEqual, // GE
  };
}

extension on ArrayKind {
  OperandSize elementSize(ObjectLayout objectLayout) => switch (this) {
    .fixedLengthList =>
      (objectLayout.compressedWordSize == 8
          ? .s64
          : ((objectLayout.compressedWordSize == 4)
                ? .s32
                : (throw 'Unexpected compressedWordSize ${objectLayout.compressedWordSize}'))),
    .oneByteString => .u8,
    .twoByteString => .u16,
    .int8List => .s8,
    .uint8List || .uint8ClampedList => .u8,
    .int16List => .s16,
    .uint16List => .u16,
    .int32List => .s32,
    .uint32List => .u32,
    .int64List => .s64,
    .uint64List => .u64,
  };

  int dataOffset(VMOffsets vmOffsets) => switch (this) {
    .fixedLengthList => vmOffsets.Array_data_offset,
    .oneByteString => vmOffsets.OneByteString_data_offset,
    .twoByteString => vmOffsets.TwoByteString_data_offset,
    .int8List ||
    .uint8List ||
    .uint8ClampedList ||
    .int16List ||
    .uint16List ||
    .int32List ||
    .uint32List ||
    .int64List ||
    .uint64List => vmOffsets.TypedData_payload_offset,
  };

  int lengthFieldOffset(VMOffsets vmOffsets) => switch (this) {
    .fixedLengthList => vmOffsets.Array_length_offset,
    .oneByteString || .twoByteString => vmOffsets.String_length_offset,
    .int8List ||
    .uint8List ||
    .uint8ClampedList ||
    .int16List ||
    .uint16List ||
    .int32List ||
    .uint32List ||
    .int64List ||
    .uint64List => vmOffsets.TypedDataBase_length_offset,
  };

  int? dataFieldOffset(VMOffsets vmOffsets) => switch (this) {
    .fixedLengthList ||
    .oneByteString ||
    .twoByteString => null, // No 'data' field.
    .int8List ||
    .uint8List ||
    .uint8ClampedList ||
    .int16List ||
    .uint16List ||
    .int32List ||
    .uint32List ||
    .int64List ||
    .uint64List => vmOffsets.PointerBase_data_offset,
  };

  int maxNewSpaceElements(ObjectLayout objectLayout) {
    final vmOffsets = objectLayout.vmOffsets;
    final elemSize = elementSize(objectLayout);
    return (vmOffsets.Heap_kNewAllocatableSize - dataOffset(vmOffsets)) >>
        elemSize.log2sizeInBytes;
  }

  ClassId get classId => switch (this) {
    .fixedLengthList => ClassId.ArrayCid,
    .oneByteString => ClassId.OneByteStringCid,
    .twoByteString => ClassId.TwoByteStringCid,
    .int8List => ClassId.TypedDataInt8ArrayCid,
    .uint8List => ClassId.TypedDataUint8ArrayCid,
    .uint8ClampedList => ClassId.TypedDataUint8ClampedArrayCid,
    .int16List => ClassId.TypedDataInt16ArrayCid,
    .uint16List => ClassId.TypedDataUint16ArrayCid,
    .int32List => ClassId.TypedDataInt32ArrayCid,
    .uint32List => ClassId.TypedDataUint32ArrayCid,
    .int64List => ClassId.TypedDataInt64ArrayCid,
    .uint64List => ClassId.TypedDataUint64ArrayCid,
  };
}

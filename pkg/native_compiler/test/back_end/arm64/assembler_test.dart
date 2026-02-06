// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:test/test.dart';
import 'disassembler.dart' show Disassembler;

void main() {
  final vmOffsets = Arm64VMOffsets();
  final objectPoolBase = vmOffsets.ObjectPool_elementOffset(0);
  late Arm64Assembler asm;

  setUp(() {
    asm = Arm64Assembler(vmOffsets);
  });

  void expectDisassembly(String expected) {
    final bytes = asm.bytes;
    final actual = Disassembler.decodeInstructions(
      Uint32List.view(bytes.buffer, 0, bytes.length >> 2),
    );
    expect(actual, equals(expected));
  }

  void expectThrows(void Function() actual) {
    expect(actual, throwsA(anything));
  }

  test('simple', () {
    asm.add(R0, ZR, ZR);
    asm.add(R0, R0, Immediate(42));
    asm.ret();
    expectDisassembly(
      'add r0, zr, zr\n'
      'add r0, r0, #0x2a\n'
      'ret\n',
    );
  });

  // Negative test cases require enabled assertions.
  test('check assertions enabled', () {
    expectThrows(() {
      assert(false);
    });
  });

  group('macro-instruction', () {
    test('address', () {
      asm.ldr(R0, asm.address(R0, -256));
      asm.str(R1, asm.address(R0, 0x7ff8));
      // TODO: support large offsets
      expectThrows(() {
        asm.address(R0, -257);
      });
      expectThrows(() {
        asm.address(R0, 257);
      });
      expectThrows(() {
        asm.address(R0, 0x8000);
      });
      expectDisassembly(
        'ldr r0, [r0, #-256]\n'
        'str r1, [r0, #32760]\n',
      );
    });
    test('pairAddress', () {
      asm.ldp(R1, R2, asm.pairAddress(R0, -0x200));
      asm.stp(R1, R2, asm.pairAddress(R0, 0x1f8));
      // TODO: support large and unaligned offsets
      expectThrows(() {
        asm.pairAddress(R0, 3);
      });
      expectThrows(() {
        asm.pairAddress(R0, -1);
      });
      expectThrows(() {
        asm.pairAddress(R0, -0x208);
      });
      expectThrows(() {
        asm.pairAddress(R0, 0x200);
      });
      expectDisassembly(
        'ldp r1, r2, [r0, #-512]\n'
        'stp r1, r2, [r0, #504]\n',
      );
    });
    test('enterDartFrame', () {
      asm.enterDartFrame();
      expectDisassembly(
        'stp fp, lr, [sp, #-16]!\n'
        'mov fp, sp\n'
        'add pp, pp, #0x1\n'
        'stp pp, code, [sp, #-16]!\n'
        'ldr pp, [code, #${vmOffsets.Code_object_pool_offset - heapObjectTag}]\n'
        'sub pp, pp, #0x1\n',
      );
    });
    test('leaveDartFrame', () {
      asm.leaveDartFrame();
      expectDisassembly(
        'ldr pp, [fp, #-16]\n'
        'sub pp, pp, #0x1\n'
        'mov sp, fp\n'
        'ldp fp, lr, [sp], #16 !\n',
      );
    });
    test('push', () {
      asm.push(R0);
      asm.push(ZR);
      expectThrows(() {
        asm.push(SP);
      });
      expectDisassembly(
        'str r0, [sp, #-8]!\n'
        'str zr, [sp, #-8]!\n',
      );
    });
    test('pop', () {
      asm.pop(R1);
      asm.pop(ZR);
      expectThrows(() {
        asm.push(SP);
      });
      expectDisassembly(
        'ldr r1, [sp], #8 !\n'
        'ldr zr, [sp], #8 !\n',
      );
    });
    test('pushPair', () {
      asm.pushPair(R0, R1);
      asm.pushPair(FP, LR);
      asm.pushPair(R0, R0);
      asm.pushPair(R2, ZR);
      expectThrows(() {
        asm.pushPair(stackPointerReg, R0);
      });
      expectThrows(() {
        asm.pushPair(R0, SP);
      });
      expectDisassembly(
        'stp r0, r1, [sp, #-16]!\n'
        'stp fp, lr, [sp, #-16]!\n'
        'stp r0, r0, [sp, #-16]!\n'
        'stp r2, zr, [sp, #-16]!\n',
      );
    });
    test('popPair', () {
      asm.popPair(R0, R1);
      asm.popPair(FP, LR);
      asm.popPair(ZR, R2);
      expectThrows(() {
        asm.popPair(R0, stackPointerReg);
      });
      expectThrows(() {
        asm.popPair(SP, R1);
      });
      expectDisassembly(
        'ldp r0, r1, [sp], #16 !\n'
        'ldp fp, lr, [sp], #16 !\n'
        'ldp zr, r2, [sp], #16 !\n',
      );
    });
    test('loadFromPool', () {
      asm.loadFromPool(R0, ConstantValue.fromString('abc') as Object);
      asm.loadFromPool(R1, ConstantValue.fromString('def') as Object);
      asm.loadFromPool(R2, ConstantValue.fromString('abc') as Object);
      expectDisassembly(
        'ldr r0, [pp, #${objectPoolBase}]\n'
        'ldr r1, [pp, #${objectPoolBase + 8}]\n'
        'ldr r2, [pp, #${objectPoolBase}]\n',
      );
    });
    test('loadFromPool - large offset', () {
      final expected = StringBuffer();
      for (var offs = objectPoolBase; offs < 32768; offs += 8) {
        asm.loadFromPool(R0, ConstantValue.fromString('$offs') as Object);
        expected.write('ldr r0, [pp, #$offs]\n');
      }
      // TODO: support large offsets
      expectThrows(() {
        asm.loadFromPool(R0, ConstantValue.fromString('oops') as Object);
      });
      expectDisassembly(expected.toString());
    });
    test('loadConstant', () {
      asm.loadConstant(R0, ConstantValue.fromString('abc'));
      asm.loadConstant(R1, ConstantValue.fromInt(42));
      expectDisassembly(
        'ldr r0, [pp, #${objectPoolBase}]\n'
        'movz r1, #0x2a\n',
      );
    });
    test('loadImmediate', () {
      asm.loadImmediate(R0, 0);
      asm.loadImmediate(R1, 1);
      asm.loadImmediate(R2, -1);
      asm.loadImmediate(R3, 42);
      asm.loadImmediate(R0, -42);
      asm.loadImmediate(LR, 0xaabb);
      asm.loadImmediate(LR, 0xaabbccdd);
      asm.loadImmediate(R1, 0xffffffff_ffffaabb);
      asm.loadImmediate(R1, 0xffffffff_aabbccdd);
      asm.loadImmediate(R2, 0x11223344_55667788);
      asm.loadImmediate(R2, 0xaabbccdd_eeff0011);
      asm.loadImmediate(R3, 0xfefefefe);
      asm.loadImmediate(R4, 0xfefefefe_fefefefe);
      asm.loadImmediate(R5, 0xff00ff00_ff00ff00);
      expectDisassembly(
        'movz r0, #0x0\n'
        'movz r1, #0x1\n'
        'movn r2, #0x0\n'
        'movz r3, #0x2a\n'
        'movn r0, #0x29\n'
        'movz lr, #0xaabb\n'
        'movz lr, #0xccdd\n'
        'movk lr, #0xaabb lsl 16\n'
        'movn r1, #0x5544\n'
        'movn r1, #0x3322\n'
        'movk r1, #0xaabb lsl 16\n'
        'movz r2, #0x7788\n'
        'movk r2, #0x5566 lsl 16\n'
        'movk r2, #0x3344 lsl 32\n'
        'movk r2, #0x1122 lsl 48\n'
        'movz r2, #0x11\n'
        'movk r2, #0xeeff lsl 16\n'
        'movk r2, #0xccdd lsl 32\n'
        'movk r2, #0xaabb lsl 48\n'
        'movz r3, #0xfefe\n'
        'movk r3, #0xfefe lsl 16\n'
        'mov r4, 0xfefefefefefefefe\n'
        'mov r5, 0xff00ff00ff00ff00\n',
      );
    });
    test('addImmediate', () {
      asm.addImmediate(R0, R0, 0);
      asm.addImmediate(R1, R2, 0);
      asm.addImmediate(R1, R2, 0, .s32);
      asm.addImmediate(R1, R2, 0xabc);
      asm.addImmediate(R1, R2, -0xabc);
      asm.addImmediate(R1, R2, 0xabc000);
      asm.addImmediate(R1, R2, -0xabc000);
      asm.addImmediate(R1, R2, 0x11223344_55667788);
      asm.addImmediate(SP, FP, 0x11223344_55667788);
      expectDisassembly(
        'mov r1, r2\n'
        'movw r1, r2\n'
        'add r1, r2, #0xabc\n'
        'sub r1, r2, #0xabc\n'
        'add r1, r2, #0xabc000\n'
        'sub r1, r2, #0xabc000\n'
        'movz tmp, #0x7788\n'
        'movk tmp, #0x5566 lsl 16\n'
        'movk tmp, #0x3344 lsl 32\n'
        'movk tmp, #0x1122 lsl 48\n'
        'add r1, r2, tmp\n'
        'movz tmp, #0x7788\n'
        'movk tmp, #0x5566 lsl 16\n'
        'movk tmp, #0x3344 lsl 32\n'
        'movk tmp, #0x1122 lsl 48\n'
        'add csp, fp, tmp uxtx 0\n',
      );
    });
    test('subImmediate', () {
      asm.subImmediate(R3, R3, 0);
      asm.subImmediate(SP, FP, 0);
      asm.subImmediate(R1, R2, 0, .u32);
      asm.subImmediate(R1, R2, 0xabc);
      asm.subImmediate(R1, R2, -0xabc);
      asm.subImmediate(R1, R2, 0xabc000);
      asm.subImmediate(R1, R2, -0xabc000);
      asm.subImmediate(R1, R2, 0x11223344_55667788);
      asm.subImmediate(SP, FP, 0x11223344_55667788);
      expectDisassembly(
        'mov csp, fp\n'
        'movw r1, r2\n'
        'sub r1, r2, #0xabc\n'
        'add r1, r2, #0xabc\n'
        'sub r1, r2, #0xabc000\n'
        'add r1, r2, #0xabc000\n'
        'movz tmp, #0x7788\n'
        'movk tmp, #0x5566 lsl 16\n'
        'movk tmp, #0x3344 lsl 32\n'
        'movk tmp, #0x1122 lsl 48\n'
        'sub r1, r2, tmp\n'
        'movz tmp, #0x7788\n'
        'movk tmp, #0x5566 lsl 16\n'
        'movk tmp, #0x3344 lsl 32\n'
        'movk tmp, #0x1122 lsl 48\n'
        'sub csp, fp, tmp uxtx 0\n',
      );
    });
    test('andImmediate', () {
      asm.andImmediate(R1, R2, 0);
      asm.andImmediate(R1, R2, 0, .u32);
      asm.andImmediate(R1, R2, -1);
      asm.andImmediate(R1, R2, -1, .u32);
      asm.andImmediate(R1, R2, 0xff);
      asm.andImmediate(R1, R2, 0x11223344_55667788);
      expectDisassembly(
        'movz r1, #0x0\n'
        'movz r1, #0x0\n'
        'mov r1, r2\n'
        'movw r1, r2\n'
        'and r1, r2, 0xff\n'
        'movz tmp, #0x7788\n'
        'movk tmp, #0x5566 lsl 16\n'
        'movk tmp, #0x3344 lsl 32\n'
        'movk tmp, #0x1122 lsl 48\n'
        'and r1, r2, tmp\n',
      );
    });
    test('callRuntime', () {
      asm.callRuntime(RuntimeEntry.AllocateObject, 2);
      expectDisassembly(
        'ldr r5, [thr, #${vmOffsets.Thread_runtime_entry_offset(RuntimeEntry.AllocateObject, wordSize)}]\n'
        'movz r4, #0x2\n'
        'ldr lr, [thr, #${vmOffsets.Thread_call_to_runtime_entry_point_offset}]\n'
        'blr lr\n',
      );
    });
    test('callStub', () {
      final stub = Code('<stub>', null, Uint8List(0), ObjectPool());
      asm.callStub(stub);
      expectDisassembly(
        'ldr code, [pp, #${objectPoolBase}]\n'
        'ldr lr, [code, #${vmOffsets.Code_entry_point_offset.first - heapObjectTag}]\n'
        'blr lr\n',
      );
    });
  });

  group('instruction', () {
    test('add', () {
      asm.add(R0, R0, R1);
      asm.add(R0, R0, ShiftedRegOperand(R1, .LSL, 1));
      asm.add(R2, ZR, ShiftedRegOperand(R1, .LSR, 8));
      asm.add(R0, R0, ShiftedRegOperand(R1, .ASR, 63));
      asm.add(R1, ZR, ShiftedRegOperand(R1, .LSL, 3), .s32);
      asm.addw(R0, R0, ShiftedRegOperand(R1, .ASR, 3));
      asm.add(R0, R0, ExtRegOperand(R1, .SXTW, 0));
      asm.add(R0, R1, ExtRegOperand(R1, .UXTX, 3));
      asm.add(R0, SP, ExtRegOperand(R1, .UXTX, 0));
      asm.add(R0, R1, Immediate(42));
      asm.add(SP, SP, Immediate(16));
      expectDisassembly(
        'add r0, r0, r1\n'
        'add r0, r0, r1 lsl #1\n'
        'add r2, zr, r1 lsr #8\n'
        'add r0, r0, r1 asr #63\n'
        'addw r1, zr, r1 lsl #3\n'
        'addw r0, r0, r1 asr #3\n'
        'add r0, r0, r1 sxtw\n'
        'add r0, r1, r1 uxtx 3\n'
        'add r0, csp, r1 uxtx 0\n'
        'add r0, r1, #0x2a\n'
        'add csp, csp, #0x10\n',
      );
      expectThrows(() {
        asm.add(R0, R0, SP);
      });
      expectThrows(() {
        asm.add(R0, R0, ShiftedRegOperand(SP, .LSL, 1));
      });
      expectThrows(() {
        asm.add(R0, R0, ShiftedRegOperand(R1, .LSL, 64));
      });
      expectThrows(() {
        asm.add(R0, R0, ShiftedRegOperand(R1, .LSL, 32), .s32);
      });
      expectThrows(() {
        asm.add(R0, R0, ShiftedRegOperand(R1, .LSL, -1));
      });
      expectThrows(() {
        asm.add(R0, R0, ExtRegOperand(SP, .UXTX, 0));
      });
      expectThrows(() {
        asm.add(R0, R0, ExtRegOperand(R1, .UXTX, 5));
      });
      expectThrows(() {
        asm.add(R0, R0, ExtRegOperand(R1, .UXTX, -1));
      });
      expectThrows(() {
        asm.add(R0, ZR, ExtRegOperand(R1, .UXTX, 0));
      });
      expectThrows(() {
        asm.add(R0, R0, Immediate(4097));
      });
      expectThrows(() {
        asm.add(R0, R0, Immediate(-1));
      });
      expectThrows(() {
        asm.add(R0, R0, R1, .s8);
      });
    });

    test('adds', () {
      asm.adds(tempReg, R2, R1);
      asm.adds(tempReg, R2, R1, .s32);
      expectDisassembly(
        'adds tmp, r2, r1\n'
        'addws tmp, r2, r1\n',
      );
      expectThrows(() {
        asm.adds(R0, R0, SP);
      });
      expectThrows(() {
        asm.adds(SP, R0, ExtRegOperand(R1, .UXTX, 0));
      });
    });

    test('sub', () {
      asm.sub(R3, R0, R1);
      asm.sub(R3, ZR, R0);
      asm.sub(R1, ZR, ShiftedRegOperand(R1, .LSL, 1), .s32);
      asm.sub(R0, R0, ExtRegOperand(R1, .UXTB, 0));
      asm.subw(R0, R1, Immediate(42));
      asm.sub(SP, SP, Immediate(16));
      expectDisassembly(
        'sub r3, r0, r1\n'
        'neg r3, r0\n'
        'negw r1, r1 lsl #1\n'
        'sub r0, r0, r1 uxtb\n'
        'subw r0, r1, #0x2a\n'
        'sub csp, csp, #0x10\n',
      );
    });

    test('subs', () {
      asm.subs(tempReg, R2, R0);
      asm.subs(R1, R1, R1, .s32);
      expectDisassembly(
        'subs tmp, r2, r0\n'
        'subws r1, r1, r1\n',
      );
    });

    test('cmp', () {
      asm.cmp(R0, ExtRegOperand(R0, .SXTW, 0));
      expectDisassembly('cmp r0, r0 sxtw\n');
    });

    test('cmn', () {
      asm.cmn(SP, Immediate(32));
      expectDisassembly('cmn csp, #0x20\n');
    });

    test('adc', () {
      asm.adc(R1, R2, R3);
      asm.adc(tempReg, ZR, R0, .s32);
      expectDisassembly(
        'adc r1, r2, r3\n'
        'adcw tmp, zr, r0\n',
      );
      expectThrows(() {
        asm.adds(R0, R0, SP);
      });
      expectThrows(() {
        asm.adds(R0, R0, R1, .u16);
      });
    });

    test('adcs', () {
      asm.adcs(tempReg, R2, R0);
      asm.adcsw(R0, ZR, R1);
      expectDisassembly(
        'adcs tmp, r2, r0\n'
        'adcws r0, zr, r1\n',
      );
    });

    test('sbc', () {
      asm.sbc(R0, R1, R2);
      asm.sbc(tempReg, R0, ZR, .s32);
      expectDisassembly(
        'sbc r0, r1, r2\n'
        'sbcw tmp, r0, zr\n',
      );
    });

    test('sbcs', () {
      asm.sbcs(tempReg, R0, R0);
      asm.sbcs(R1, ZR, R0, .s32);
      expectDisassembly(
        'sbcs tmp, r0, r0\n'
        'sbcws r1, zr, r0\n',
      );
    });

    test('ubfx', () {
      asm.ubfx(R0, R1, 4, 8);
      expectDisassembly('ubfm r0, r1, #4, #11\n');
      expectThrows(() {
        asm.ubfx(R0, R1, -1, 8);
      });
      expectThrows(() {
        asm.ubfx(R0, R1, 62, 3);
      });
    });

    test('sbfx', () {
      asm.sbfx(R0, R1, 4, 8);
      expectDisassembly('sbfm r0, r1, #4, #11\n');
      expectThrows(() {
        asm.sbfx(R0, R1, 0, -1);
      });
    });

    test('bfi', () {
      asm.bfi(R0, R1, 12, 5);
      expectDisassembly('bfm r0, r1, #52, #4\n');
      expectThrows(() {
        asm.bfi(R0, R1, 12, 65);
      });
    });

    test('ubfiz', () {
      asm.ubfiz(R0, R1, 1, 30);
      asm.ubfiz(R0, R1, 0, 32);
      expectDisassembly(
        'ubfm r0, r1, #63, #29\n'
        'ubfm r0, r1, #0, #31\n',
      );
      expectThrows(() {
        asm.ubfiz(R0, R1, 3, 34, .s32);
      });
    });

    test('bfxil', () {
      asm.bfxil(R0, R1, 4, 8);
      expectDisassembly('bfm r0, r1, #4, #11\n');
      expectThrows(() {
        asm.bfxil(R0, SP, 4, 8);
      });
    });

    test('sbfiz', () {
      asm.sbfiz(R0, R1, 4, 12);
      expectDisassembly('sbfm r0, r1, #60, #11\n');
    });

    test('sxtb', () {
      asm.sxtb(R1, R2);
      expectDisassembly('sxtb r1, r2\n');
      expectThrows(() {
        asm.sxtb(SP, R2);
      });
    });

    test('sxth', () {
      asm.sxth(R1, R2);
      expectDisassembly('sxth r1, r2\n');
      expectThrows(() {
        asm.sxtb(R1, SP);
      });
    });

    test('sxtw', () {
      asm.sxtw(R1, R2);
      expectDisassembly('sxtw r1, r2\n');
    });

    test('uxtb', () {
      asm.uxtb(R1, R2);
      expectDisassembly('uxtb r1, r2\n');
    });

    test('uxth', () {
      asm.uxth(R1, R2);
      expectDisassembly('uxth r1, r2\n');
    });

    test('and', () {
      asm.and(R0, R1, R2);
      asm.and(R0, R0, Immediate(-512));
      asm.andw(R0, R0, Immediate(-512));
      asm.and(SP, R0, Immediate(-16));
      expectDisassembly(
        'and r0, r1, r2\n'
        'and r0, r0, 0xfffffffffffffe00\n'
        'andw r0, r0, 0xfffffe00\n'
        'and csp, r0, 0xfffffffffffffff0\n',
      );
      expectThrows(() {
        asm.and(R0, R1, Immediate(0));
      });
      expectThrows(() {
        asm.and(R0, R1, Immediate(0x1101111));
      });
    });

    test('ands', () {
      asm.ands(ZR, R1, R2);
      asm.ands(R0, R0, Immediate(-512));
      asm.ands(R0, R0, Immediate(-512), .s32);
      expectDisassembly(
        'tst r1, r2\n'
        'ands r0, r0, 0xfffffffffffffe00\n'
        'andws r0, r0, 0xfffffe00\n',
      );
      expectThrows(() {
        asm.ands(SP, R0, Immediate(-16));
      });
    });

    test('eor', () {
      asm.eor(R0, R1, R2);
      asm.eor(R0, R0, Immediate(0xff00));
      asm.eor(R0, R0, Immediate(0xff00), .s32);
      expectDisassembly(
        'eor r0, r1, r2\n'
        'eor r0, r0, 0xff00\n'
        'eorw r0, r0, 0xff00\n',
      );
    });

    test('orr', () {
      asm.orr(R0, R1, R2);
      asm.orr(R0, R0, Immediate(0xff00));
      expectDisassembly(
        'orr r0, r1, r2\n'
        'orr r0, r0, 0xff00\n',
      );
    });

    test('bic', () {
      asm.bic(R0, R1, ZR);
      asm.bic(R0, R1, ShiftedRegOperand(R1, .LSR, 3));
      asm.bicw(R0, R1, ZR);
      expectDisassembly(
        'bic r0, r1, zr\n'
        'bic r0, r1, r1 lsr #3\n'
        'bicw r0, r1, zr\n',
      );
    });

    test('bics', () {
      asm.bics(R0, ZR, R0);
      asm.bics(R0, R1, ShiftedRegOperand(R0, .ASR, 16));
      expectDisassembly(
        'bics r0, zr, r0\n'
        'bics r0, r1, r0 asr #16\n',
      );
    });

    test('eon', () {
      asm.eon(R0, R0, R1);
      asm.eon(R0, R0, ShiftedRegOperand(R1, .LSL, 15));
      asm.eon(R0, R0, ShiftedRegOperand(R1, .LSL, 15), .s32);
      expectDisassembly(
        'eon r0, r0, r1\n'
        'eon r0, r0, r1 lsl #15\n'
        'eonw r0, r0, r1 lsl #15\n',
      );
    });

    test('orn', () {
      asm.orn(R3, R2, R1);
      asm.ornw(R3, R2, R1);
      asm.orn(R3, R2, ShiftedRegOperand(R4, .ROR, 2));
      expectDisassembly(
        'orn r3, r2, r1\n'
        'ornw r3, r2, r1\n'
        'orn r3, r2, r4 ror #2\n',
      );
    });

    test('mov', () {
      asm.mov(R1, R0);
      asm.mov(R0, R1, .s32);
      asm.mov(R0, ZR);
      expectDisassembly(
        'mov r1, r0\n'
        'movw r0, r1\n'
        'mov r0, zr\n',
      );
      expectThrows(() {
        asm.mov(R1, R0, .s8);
      });
    });

    test('movz', () {
      asm.movz(R0, 42, 0);
      asm.movz(R0, 42, 16);
      asm.movz(R0, 42, 32);
      asm.movz(R0, 42, 48);
      asm.movz(R0, 0x8000, 0);
      expectDisassembly(
        'movz r0, #0x2a\n'
        'movz r0, #0x2a lsl 16\n'
        'movz r0, #0x2a lsl 32\n'
        'movz r0, #0x2a lsl 48\n'
        'movz r0, #0x8000\n',
      );
      expectThrows(() {
        asm.movz(R0, 42, 15);
      });
      expectThrows(() {
        asm.movz(R0, -1, 0);
      });
      expectThrows(() {
        asm.movz(R0, 0x10000, 0);
      });
      expectThrows(() {
        asm.movz(SP, 42, 0);
      });
    });

    test('movn', () {
      asm.movn(R0, 42, 0);
      asm.movn(R0, 42, 16);
      asm.movn(R0, 42, 32);
      asm.movn(R0, 42, 48);
      expectDisassembly(
        'movn r0, #0x2a\n'
        'movn r0, #0x2a lsl 16\n'
        'movn r0, #0x2a lsl 32\n'
        'movn r0, #0x2a lsl 48\n',
      );
    });

    test('movk', () {
      asm.movk(R0, 42, 0);
      asm.movk(R0, 42, 16);
      asm.movk(R0, 42, 32);
      asm.movk(R0, 42, 48);
      expectDisassembly(
        'movk r0, #0x2a\n'
        'movk r0, #0x2a lsl 16\n'
        'movk r0, #0x2a lsl 32\n'
        'movk r0, #0x2a lsl 48\n',
      );
    });

    test('ldr', () {
      asm.ldr(R0, RegOffsetAddress(R1, 7));
      asm.ldr(R0, RegOffsetAddress(R1, 7), .u32);
      asm.ldr(R0, RegOffsetAddress(R1, 7), .s32);
      asm.ldr(R0, RegOffsetAddress(R1, 7), .u16);
      asm.ldr(R0, RegOffsetAddress(R1, 7), .s16);
      asm.ldr(R0, RegOffsetAddress(R1, 7), .u8);
      asm.ldr(R0, RegOffsetAddress(R1, 7), .s8);
      asm.ldr(R0, RegOffsetAddress(SP, 4096));
      asm.ldr(R0, WritebackRegOffsetAddress(R1, 16, isPostIndexed: true));
      asm.ldr(R0, WritebackRegOffsetAddress(R1, -8, isPostIndexed: false));
      expectDisassembly(
        'ldr r0, [r1, #7]\n'
        'ldrw r0, [r1, #7]\n'
        'ldrsw r0, [r1, #7]\n'
        'ldrh r0, [r1, #7]\n'
        'ldrsh r0, [r1, #7]\n'
        'ldrb r0, [r1, #7]\n'
        'ldrsb r0, [r1, #7]\n'
        'ldr r0, [csp, #4096]\n'
        'ldr r0, [r1], #16 !\n'
        'ldr r0, [r1, #-8]!\n',
      );
      expectThrows(() {
        asm.ldr(R0, RegOffsetAddress(R1, 32768));
      });
      expectThrows(() {
        asm.ldr(R0, RegOffsetAddress(R1, 4097));
      });
      expectThrows(() {
        asm.ldr(R0, RegOffsetAddress(R1, -512));
      });
      expectThrows(() {
        asm.ldr(SP, RegOffsetAddress(R1, 8));
      });
      expectThrows(() {
        asm.ldr(R0, WritebackRegOffsetAddress(R1, 512, isPostIndexed: true));
      });
      expectThrows(() {
        asm.ldr(R0, WritebackRegOffsetAddress(R1, -513, isPostIndexed: false));
      });
      expectThrows(() {
        asm.ldr(R0, WritebackRegOffsetAddress(R0, 8, isPostIndexed: false));
      });
      expectThrows(() {
        asm.ldr(R0, WritebackRegOffsetAddress(R0, 8, isPostIndexed: true));
      });
    });

    test('str', () {
      asm.str(ZR, RegOffsetAddress(SP, -8));
      asm.str(R1, RegOffsetAddress(R0, 7));
      asm.str(R0, RegOffsetAddress(R1, 7), .s32);
      asm.str(R0, RegOffsetAddress(R1, 7), .s16);
      asm.str(R0, RegOffsetAddress(R1, 7), .s8);
      asm.str(R0, WritebackRegOffsetAddress(R1, -32, isPostIndexed: true));
      asm.str(R0, WritebackRegOffsetAddress(R1, 8, isPostIndexed: false));
      expectDisassembly(
        'str zr, [csp, #-8]\n'
        'str r1, [r0, #7]\n'
        'strw r0, [r1, #7]\n'
        'strh r0, [r1, #7]\n'
        'strb r0, [r1, #7]\n'
        'str r0, [r1], #-32 !\n'
        'str r0, [r1, #8]!\n',
      );
      expectThrows(() {
        asm.str(R0, RegOffsetAddress(R1, 32768));
      });
      expectThrows(() {
        asm.str(R0, RegOffsetAddress(R1, 4097));
      });
      expectThrows(() {
        asm.str(R0, RegOffsetAddress(R1, -512));
      });
      expectThrows(() {
        asm.str(SP, RegOffsetAddress(R1, 8));
      });
      expectThrows(() {
        asm.str(R0, RegOffsetAddress(ZR, 8));
      });
      expectThrows(() {
        asm.str(R0, WritebackRegOffsetAddress(R1, 512, isPostIndexed: true));
      });
      expectThrows(() {
        asm.str(R0, WritebackRegOffsetAddress(R1, -513, isPostIndexed: false));
      });
      expectThrows(() {
        asm.str(R0, WritebackRegOffsetAddress(R0, 8, isPostIndexed: false));
      });
      expectThrows(() {
        asm.str(R0, WritebackRegOffsetAddress(R0, 8, isPostIndexed: true));
      });
    });

    test('ldp', () {
      asm.ldp(R0, R1, RegOffsetAddress(R2, -512));
      asm.ldp(R0, R1, RegOffsetAddress(R2, 16), .u32);
      asm.ldp(R0, R1, RegOffsetAddress(R2, 252), .s32);
      asm.ldp(R3, R1, RegOffsetAddress(SP, 256));
      asm.ldp(R2, R0, WritebackRegOffsetAddress(R1, 16, isPostIndexed: true));
      asm.ldp(R0, R4, WritebackRegOffsetAddress(R1, -8, isPostIndexed: false));
      expectDisassembly(
        'ldp r0, r1, [r2, #-512]\n'
        'ldpw r0, r1, [r2, #16]\n'
        'ldpsw r0, r1, [r2, #252]\n'
        'ldp r3, r1, [csp, #256]\n'
        'ldp r2, r0, [r1], #16 !\n'
        'ldp r0, r4, [r1, #-8]!\n',
      );
      expectThrows(() {
        asm.ldp(R0, R1, RegOffsetAddress(R2, 1));
      });
      expectThrows(() {
        asm.ldp(R0, R1, RegOffsetAddress(R2, 512));
      });
      expectThrows(() {
        asm.ldp(R0, R1, RegOffsetAddress(R2, -520));
      });
      expectThrows(() {
        asm.ldp(R0, R1, RegOffsetAddress(R2, 256), .s32);
      });
      expectThrows(() {
        asm.ldp(R0, R1, RegOffsetAddress(R2, -260), .u32);
      });
      expectThrows(() {
        asm.ldp(R0, R1, WritebackRegOffsetAddress(R0, 8, isPostIndexed: true));
      });
      expectThrows(() {
        asm.ldp(
          R0,
          R1,
          WritebackRegOffsetAddress(R1, -8, isPostIndexed: false),
        );
      });
      expectThrows(() {
        asm.ldp(
          R0,
          R1,
          WritebackRegOffsetAddress(R2, 512, isPostIndexed: true),
        );
      });
      expectThrows(() {
        asm.ldp(
          R0,
          R1,
          WritebackRegOffsetAddress(R2, -520, isPostIndexed: false),
        );
      });
    });

    test('stp', () {
      asm.stp(R0, R1, RegOffsetAddress(R2, 16));
      asm.stp(R0, R1, RegOffsetAddress(R2, 4), .u32);
      asm.stp(R0, R1, RegOffsetAddress(R2, -256), .s32);
      asm.stp(R3, R1, RegOffsetAddress(SP, 256));
      asm.stp(R2, R0, WritebackRegOffsetAddress(R1, 16, isPostIndexed: true));
      asm.stp(R0, R4, WritebackRegOffsetAddress(R1, -8, isPostIndexed: false));
      expectDisassembly(
        'stp r0, r1, [r2, #16]\n'
        'stpw r0, r1, [r2, #4]\n'
        'stpw r0, r1, [r2, #-256]\n'
        'stp r3, r1, [csp, #256]\n'
        'stp r2, r0, [r1], #16 !\n'
        'stp r0, r4, [r1, #-8]!\n',
      );
      expectThrows(() {
        asm.stp(R0, R1, RegOffsetAddress(R2, 4));
      });
      expectThrows(() {
        asm.stp(R0, R1, RegOffsetAddress(R2, 512));
      });
      expectThrows(() {
        asm.stp(R0, R1, RegOffsetAddress(R2, -520));
      });
      expectThrows(() {
        asm.stp(R0, R1, WritebackRegOffsetAddress(ZR, 8, isPostIndexed: true));
      });
      expectThrows(() {
        asm.stp(R0, R1, WritebackRegOffsetAddress(R0, 8, isPostIndexed: true));
      });
      expectThrows(() {
        asm.stp(
          R0,
          R1,
          WritebackRegOffsetAddress(R1, -8, isPostIndexed: false),
        );
      });
      expectThrows(() {
        asm.stp(
          R0,
          R1,
          WritebackRegOffsetAddress(R2, 512, isPostIndexed: true),
        );
      });
      expectThrows(() {
        asm.stp(
          R0,
          R1,
          WritebackRegOffsetAddress(R2, -520, isPostIndexed: false),
        );
      });
    });

    test('nop', () {
      asm.nop();
      expectDisassembly('nop\n');
    });

    test('b', () {
      final loop = Label();
      final done = Label();
      asm.movz(R0, 1);
      asm.bind(loop);
      asm.cmp(R0, Immediate(10));
      asm.b(done, .greaterOrEqual);
      asm.add(R0, R0, Immediate(1));
      asm.b(loop);
      asm.bind(done);
      expectDisassembly(
        'movz r0, #0x1\n'
        'cmp r0, #0xa\n'
        'bge +12\n'
        'add r0, r0, #0x1\n'
        'b -12\n',
      );
    });

    test('b - large offset', () {
      final target0 = Label();
      final target1 = Label();
      final target2 = Label();
      asm.bind(target0);
      asm.nop();
      asm.b(target2);
      asm.b(target1);
      for (var i = 0; i < (1 << 25) - 3; ++i) {
        asm.nop();
      }
      asm.b(target0);
      asm.bind(target1);
      // TODO: support far jumps
      expectThrows(() {
        asm.b(target0);
      });
      expectThrows(() {
        asm.bind(target2);
      });
    });

    test('b.cond - large offset', () {
      final target0 = Label();
      final target1 = Label();
      final target2 = Label();
      asm.bind(target0);
      asm.nop();
      asm.b(target2, .less);
      asm.b(target1, .equal);
      for (var i = 0; i < (1 << 18) - 3; ++i) {
        asm.nop();
      }
      asm.b(target0, .notZero);
      asm.bind(target1);
      // TODO: support far jumps
      expectThrows(() {
        asm.b(target0, .notZero);
      });
      expectThrows(() {
        asm.bind(target2);
      });
    });

    test('cbz/cbnz', () {
      final loop = Label();
      final done = Label();
      asm.movz(R0, 10);
      asm.bind(loop);
      asm.sub(R0, R0, Immediate(1));
      asm.cbz(R0, done);
      asm.cbnz(R0, loop);
      asm.bind(done);
      expectDisassembly(
        'movz r0, #0xa\n'
        'sub r0, r0, #0x1\n'
        'cbz r0, +8\n'
        'cbnz r0, -8\n',
      );
    });

    test('cbz/cbnz - large offset', () {
      final target0 = Label();
      final target1 = Label();
      final target2 = Label();
      asm.bind(target0);
      asm.nop();
      asm.cbz(R0, target2);
      asm.cbz(R1, target1);
      for (var i = 0; i < (1 << 18) - 3; ++i) {
        asm.nop();
      }
      asm.cbnz(R0, target0);
      asm.bind(target1);
      // TODO: support far jumps
      expectThrows(() {
        asm.cbnz(R0, target0);
      });
      expectThrows(() {
        asm.bind(target2);
      });
    });

    test('tbz/tbnz', () {
      final loop = Label();
      final isEven = Label();
      asm.movz(R0, 0xff);
      asm.bind(loop);
      asm.sub(R0, R0, Immediate(1));
      asm.tbz(R0, 0, isEven);
      asm.sub(R0, R0, Immediate(1));
      asm.bind(isEven);
      asm.tbnz(R0, 40, loop);
      expectDisassembly(
        'movz r0, #0xff\n'
        'sub r0, r0, #0x1\n'
        'tbzw r0, #0, +8\n'
        'sub r0, r0, #0x1\n'
        'tbnz r0, #40, -12\n',
      );
    });

    test('tbz/tbnz - large offset', () {
      final target0 = Label();
      final target1 = Label();
      final target2 = Label();
      asm.bind(target0);
      asm.nop();
      asm.tbnz(R0, 31, target2);
      asm.tbz(R1, 63, target1);
      for (var i = 0; i < (1 << 13) - 3; ++i) {
        asm.nop();
      }
      asm.tbz(R1, 0, target0);
      asm.bind(target1);
      // TODO: support far jumps
      expectThrows(() {
        asm.tbz(R1, 0, target0);
      });
      expectThrows(() {
        asm.bind(target2);
      });
    });

    test('br', () {
      asm.br(R4);
      expectDisassembly('br r4\n');
    });

    test('blr', () {
      asm.blr(R0);
      expectDisassembly('blr r0\n');
    });

    test('ret', () {
      asm.ret();
      asm.ret(R1);
      expectDisassembly(
        'ret\n'
        'ret r1\n',
      );
    });
  });
}

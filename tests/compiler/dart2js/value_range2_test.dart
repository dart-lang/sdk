// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../lib/compiler/implementation/ssa/ssa.dart");
#import("../../../lib/compiler/implementation/leg.dart");

Value instructionValue = new InstructionValue(new HReturn(null));
Value lengthValue = new LengthValue(new HReturn(null));

Range createSingleRange(Value value) => new Range(value, value);
Range createSingleIntRange(int value) => createSingleRange(new IntValue(value));
Range createSingleInstructionRange() => createSingleRange(instructionValue);
Range createSingleLengthRange() => createSingleRange(lengthValue);
Range createIntRange(int lower, int upper) {
  return new Range(new IntValue(lower), new IntValue(upper));
}
Range createLengthRange(int lower) {
  return new Range(new IntValue(lower), lengthValue);
}
Range createInstructionRange(int lower) {
  return new Range(new IntValue(lower), instructionValue);
}

Range instruction = createSingleInstructionRange();
Range FF = createSingleIntRange(0xFF);
Range FA = createSingleIntRange(0xFA);
Range nFF = createSingleIntRange(-0xFF);
Range length = createSingleLengthRange();
Range _FA_FF = createIntRange(0xFA, 0xFF);
Range _0_FF = createIntRange(0, 0xFF);
Range _nFF_FF = createIntRange(-0xFF, 0xFF);
Range _nFF_0 = createIntRange(-0xFF, 0);
Range _0_length = createLengthRange(0);
Range _0_instruction = createInstructionRange(0);

checkAndRange(Range one, Range two, lower, upper) {
  if (lower is num) lower = new IntValue(lower);
  if (upper is num) upper = new IntValue(upper);
  Range range = new Range(lower, upper);
  Expect.equals(range, one & two);
}

checkSubRange(Range one, Range two, [lower, upper]) {
  if (lower == null) {
    lower = new OperationValue(one.lower, two.upper, const SubtractOperation());
  } else if (lower is num) {
    lower = new IntValue(lower);
  }
  if (upper == null) {
    upper = new OperationValue(one.upper, two.lower, const SubtractOperation());
  } else if (upper is num) {
    upper = new IntValue(upper);
  }

  Expect.equals(new Range(lower, upper), one - two);
}

testAnd() {
  checkAndRange(
      instruction, instruction, const MinIntValue(), const MaxIntValue());
  checkAndRange(instruction, FF, 0, 0xFF);
  checkAndRange(instruction, FA, 0, 0xFA);
  checkAndRange(instruction, nFF, const MinIntValue(), const MaxIntValue());
  checkAndRange(instruction, length, 0, length.upper);
  checkAndRange(instruction, _FA_FF, 0, 0xFF);
  checkAndRange(instruction, _0_FF, 0, 0xFF);
  checkAndRange(instruction, _nFF_FF, const MinIntValue(), const MaxIntValue());
  checkAndRange(instruction, _nFF_0, const MinIntValue(), const MaxIntValue());
  checkAndRange(instruction, _0_length, 0, _0_length.upper);
  checkAndRange(instruction, _0_instruction, 0, _0_instruction.upper);

  checkAndRange(length, FF, 0, 0xFF);
  checkAndRange(length, FA, 0, 0xFA);
  checkAndRange(length, nFF, 0, length.upper);
  checkAndRange(length, length, 0, length.upper);
  checkAndRange(length, _FA_FF, 0, 0xFF);
  checkAndRange(length, _0_FF, 0, 0xFF);
  checkAndRange(length, _nFF_FF, 0, length.upper);
  checkAndRange(length, _nFF_0, 0, length.upper);
  checkAndRange(length, _0_length, 0, length.upper);
  checkAndRange(length, _0_instruction, 0, const MaxIntValue());

  checkAndRange(FF, FF, 0xFF, 0xFF);
  checkAndRange(FF, FA, 0xFA, 0xFA);
  checkAndRange(FF, nFF, 1, 1);
  checkAndRange(FF, length, 0, 0xFF);
  checkAndRange(FF, _FA_FF, 0, 0xFF);
  checkAndRange(FF, _0_FF, 0, 0xFF);
  checkAndRange(FF, _nFF_FF, 0, 0xFF);
  checkAndRange(FF, _nFF_0, 0, 0xFF);
  checkAndRange(FF, _0_length, 0, 0xFF);
  checkAndRange(FF, _0_instruction, 0, 0xFF);

  checkAndRange(FA, FF, 0xFA, 0xFA);
  checkAndRange(FA, FA, 0xFA, 0xFA);
  checkAndRange(FA, nFF, 0, 0);
  checkAndRange(FA, length, 0, 0xFA);
  checkAndRange(FA, _FA_FF, 0, 0xFA);
  checkAndRange(FA, _0_FF, 0, 0xFA);
  checkAndRange(FA, _nFF_FF, 0, 0xFA);
  checkAndRange(FA, _nFF_0, 0, 0xFA);
  checkAndRange(FA, _0_length, 0, 0xFA);
  checkAndRange(FA, _0_instruction, 0, 0xFA);

  checkAndRange(nFF, FF, 1, 1);
  checkAndRange(nFF, FA, 0, 0);
  checkAndRange(nFF, nFF, -0xFF, -0xFF);
  checkAndRange(nFF, length, 0, length.upper);
  checkAndRange(nFF, _FA_FF, 0, 0xFF);
  checkAndRange(nFF, _0_FF, 0, 0xFF);
  checkAndRange(nFF, _nFF_FF, const MinIntValue(), const MaxIntValue());
  checkAndRange(nFF, _nFF_0, const MinIntValue(), const MaxIntValue());
  checkAndRange(nFF, _0_length, 0, _0_length.upper);
  checkAndRange(nFF, _0_instruction, 0, _0_instruction.upper);

  checkAndRange(_FA_FF, FF, 0, 0xFF);
  checkAndRange(_FA_FF, FA, 0, 0xFA);
  checkAndRange(_FA_FF, nFF, 0, 0xFF);
  checkAndRange(_FA_FF, length, 0, 0xFF);
  checkAndRange(_FA_FF, _FA_FF, 0, 0xFF);
  checkAndRange(_FA_FF, _0_FF, 0, 0xFF);
  checkAndRange(_FA_FF, _nFF_FF, 0, 0xFF);
  checkAndRange(_FA_FF, _nFF_0, 0, 0xFF);
  checkAndRange(_FA_FF, _0_length, 0, 0xFF);
  checkAndRange(_FA_FF, _0_instruction, 0, 0xFF);

  checkAndRange(_0_FF, FF, 0, 0xFF);
  checkAndRange(_0_FF, FA, 0, 0xFA);
  checkAndRange(_0_FF, nFF, 0, 0xFF);
  checkAndRange(_0_FF, length, 0, 0xFF);
  checkAndRange(_0_FF, _FA_FF, 0, 0xFF);
  checkAndRange(_0_FF, _0_FF, 0, 0xFF);
  checkAndRange(_0_FF, _nFF_FF, 0, 0xFF);
  checkAndRange(_0_FF, _nFF_0, 0, 0xFF);
  checkAndRange(_0_FF, _0_length, 0, 0xFF);
  checkAndRange(_0_FF, _0_instruction, 0, 0xFF);

  checkAndRange(_nFF_FF, FF, 0, 0xFF);
  checkAndRange(_nFF_FF, FA, 0, 0xFA);
  checkAndRange(_nFF_FF, nFF, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_FF, length, 0, length.upper);
  checkAndRange(_nFF_FF, _FA_FF, 0, 0xFF);
  checkAndRange(_nFF_FF, _0_FF, 0, 0xFF);
  checkAndRange(_nFF_FF, _nFF_FF, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_FF, _nFF_0, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_FF, _0_length, 0, _0_length.upper);
  checkAndRange(_nFF_FF, _0_instruction, 0, _0_instruction.upper);

  checkAndRange(_nFF_0, FF, 0, 0xFF);
  checkAndRange(_nFF_0, FA, 0, 0xFA);
  checkAndRange(_nFF_0, nFF, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_0, length, 0, length.upper);
  checkAndRange(_nFF_0, _FA_FF, 0, 0xFF);
  checkAndRange(_nFF_0, _0_FF, 0, 0xFF);
  checkAndRange(_nFF_0, _nFF_FF, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_0, _nFF_0, const MinIntValue(), const MaxIntValue());
  checkAndRange(_nFF_0, _0_length, 0, _0_length.upper);
  checkAndRange(_nFF_0, _0_instruction, 0, _0_instruction.upper);

  checkAndRange(_0_length, FF, 0, 0xFF);
  checkAndRange(_0_length, FA, 0, 0xFA);
  checkAndRange(_0_length, nFF, 0, _0_length.upper);
  checkAndRange(_0_length, length, 0, length.upper);
  checkAndRange(_0_length, _FA_FF, 0, 0xFF);
  checkAndRange(_0_length, _0_FF, 0, 0xFF);
  checkAndRange(_0_length, _nFF_FF, 0, _0_length.upper);
  checkAndRange(_0_length, _nFF_0, 0, _0_length.upper);
  checkAndRange(_0_length, _0_length, 0, _0_length.upper);
  checkAndRange(_0_length, _0_instruction, 0, const MaxIntValue());

  checkAndRange(_0_instruction, FF, 0, 0xFF);
  checkAndRange(_0_instruction, FA, 0, 0xFA);
  checkAndRange(_0_instruction, nFF, 0, _0_instruction.upper);
  checkAndRange(_0_instruction, length, 0, const MaxIntValue());
  checkAndRange(_0_instruction, _FA_FF, 0, 0xFF);
  checkAndRange(_0_instruction, _0_FF, 0, 0xFF);
  checkAndRange(_0_instruction, _nFF_FF, 0, _0_instruction.upper);
  checkAndRange(_0_instruction, _nFF_0, 0, _0_instruction.upper);
  checkAndRange(_0_instruction, _0_length, 0, const MaxIntValue());
  checkAndRange(_0_instruction, _0_instruction, 0, _0_instruction.upper);
}

testSub() {
  checkSubRange(instruction, instruction, 0, 0);
  checkSubRange(instruction, FF);
  checkSubRange(instruction, FA);
  checkSubRange(instruction, nFF);
  checkSubRange(instruction, length);
  checkSubRange(instruction, _FA_FF);
  checkSubRange(instruction, _0_FF, null, instruction.upper);
  checkSubRange(instruction, _nFF_FF);
  checkSubRange(instruction, _nFF_0, instruction.lower, null);
  checkSubRange(instruction, _0_length, null, instruction.upper);
  checkSubRange(instruction, _0_instruction, 0, _0_instruction.upper);

  checkSubRange(length, FF);
  checkSubRange(length, FA);
  checkSubRange(length, nFF);
  checkSubRange(length, length, 0, 0);
  checkSubRange(length, _FA_FF);
  checkSubRange(length, _0_FF, null, length.upper);
  checkSubRange(length, _nFF_FF);
  checkSubRange(length, _nFF_0, length.lower, null);
  checkSubRange(length, _0_length, 0, length.upper);
  checkSubRange(length, _0_instruction, null, length.upper);

  checkSubRange(FF, FF, 0, 0);
  checkSubRange(FF, FA, 0xFF - 0xFA, 0xFF - 0xFA);
  checkSubRange(FF, nFF, 0xFF + 0xFF, 0xFF + 0xFF);
  checkSubRange(FF, length);
  checkSubRange(FF, _FA_FF, 0, 0xFF - 0xFA);
  checkSubRange(FF, _0_FF, 0, 0xFF);
  checkSubRange(FF, _nFF_FF, 0, 0xFF + 0xFF);
  checkSubRange(FF, _nFF_0, 0xFF, 0xFF + 0xFF);
  checkSubRange(FF, _0_length, null, 0xFF);
  checkSubRange(FF, _0_instruction, null, 0xFF);

  checkSubRange(FA, FF, 0xFA - 0xFF, 0xFA - 0xFF);
  checkSubRange(FA, FA, 0, 0);
  checkSubRange(FA, nFF, 0xFA + 0xFF, 0xFA + 0xFF);
  checkSubRange(FA, length);
  checkSubRange(FA, _FA_FF, 0xFA - 0xFF, 0);
  checkSubRange(FA, _0_FF, 0xFA - 0xFF, 0xFA);
  checkSubRange(FA, _nFF_FF, 0xFA - 0xFF, 0xFA + 0xFF);
  checkSubRange(FA, _nFF_0, 0xFA, 0xFA + 0xFF);
  checkSubRange(FA, _0_length, null, 0xFA);
  checkSubRange(FA, _0_instruction, null, 0xFA);

  checkSubRange(nFF, FF, -0xFF - 0xFF, -0xFF - 0xFF);
  checkSubRange(nFF, FA, -0xFF - 0xFA, -0xFF - 0xFA);
  checkSubRange(nFF, nFF, 0, 0);
  checkSubRange(nFF, length);
  checkSubRange(nFF, _FA_FF, -0xFF - 0xFF, -0xFF - 0xFA);
  checkSubRange(nFF, _0_FF, -0xFF - 0xFF, -0xFF);
  checkSubRange(nFF, _nFF_FF, -0xFF - 0xFF, 0);
  checkSubRange(nFF, _nFF_0, -0xFF, 0);
  checkSubRange(nFF, _0_length, null, -0xFF);
  checkSubRange(nFF, _0_instruction, null, -0xFF);

  checkSubRange(_FA_FF, FF, 0xFA - 0xFF, 0);
  checkSubRange(_FA_FF, FA, 0, 0xFF - 0xFA);
  checkSubRange(_FA_FF, nFF, 0xFA + 0xFF, 0xFF + 0xFF);
  checkSubRange(_FA_FF, length);
  checkSubRange(_FA_FF, _FA_FF, 0xFA - 0xFF, 0xFF - 0xFA);
  checkSubRange(_FA_FF, _0_FF, 0xFA - 0xFF, 0xFF);
  checkSubRange(_FA_FF, _nFF_FF, 0xFA - 0xFF, 0xFF + 0xFF);
  checkSubRange(_FA_FF, _nFF_0, 0xFA, 0xFF + 0xFF);
  checkSubRange(_FA_FF, _0_length, null, 0xFF);
  checkSubRange(_FA_FF, _0_instruction, null, 0xFF);

  checkSubRange(_0_FF, FF, -0xFF, 0);
  checkSubRange(_0_FF, FA, -0xFA, 0xFF - 0xFA);
  checkSubRange(_0_FF, nFF, 0xFF, 0xFF + 0xFF);
  checkSubRange(_0_FF, length);
  checkSubRange(_0_FF, _FA_FF, -0xFF, 0xFF - 0xFA);
  checkSubRange(_0_FF, _0_FF, -0xFF, 0xFF);
  checkSubRange(_0_FF, _nFF_FF, -0xFF, 0xFF + 0xFF);
  checkSubRange(_0_FF, _nFF_0, 0, 0xFF + 0xFF);
  checkSubRange(_0_FF, _0_length, null, 0xFF);
  checkSubRange(_0_FF, _0_instruction, null, 0xFF);

  checkSubRange(_nFF_FF, FF, -0xFF - 0xFF, 0);
  checkSubRange(_nFF_FF, FA, -0xFF - 0xFA, 0xFF - 0xFA);
  checkSubRange(_nFF_FF, nFF, 0, 0xFF + 0xFF);
  checkSubRange(_nFF_FF, length);
  checkSubRange(_nFF_FF, _FA_FF, -0xFF - 0xFF, 0xFF - 0xFA);
  checkSubRange(_nFF_FF, _0_FF, -0xFF - 0xFF, 0xFF);
  checkSubRange(_nFF_FF, _nFF_FF, -0xFF - 0xFF, 0xFF + 0xFF);
  checkSubRange(_nFF_FF, _nFF_0, -0xFF, 0xFF + 0xFF);
  checkSubRange(_nFF_FF, _0_length, null, 0xFF);
  checkSubRange(_nFF_FF, _0_instruction, null, 0xFF);

  checkSubRange(_nFF_0, FF, -0xFF - 0xFF, -0xFF);
  checkSubRange(_nFF_0, FA, -0xFF - 0xFA, -0xFA);
  checkSubRange(_nFF_0, nFF, 0, 0xFF);
  checkSubRange(_nFF_0, length);
  checkSubRange(_nFF_0, _FA_FF, -0xFF - 0xFF, -0xFA);
  checkSubRange(_nFF_0, _0_FF, -0xFF - 0xFF, 0);
  checkSubRange(_nFF_0, _nFF_FF, -0xFF - 0xFF, 0xFF);
  checkSubRange(_nFF_0, _nFF_0, -0xFF, 0xFF);
  checkSubRange(_nFF_0, _0_length, null, 0);
  checkSubRange(_nFF_0, _0_instruction, null, 0);

  checkSubRange(_0_length, FF, -0xFF, null);
  checkSubRange(_0_length, FA, -0xFA, null);
  checkSubRange(_0_length, nFF, 0xFF, null);
  checkSubRange(_0_length, length, null, 0);
  checkSubRange(_0_length, _FA_FF, -0xFF, null);
  checkSubRange(_0_length, _0_FF, -0xFF, _0_length.upper);
  checkSubRange(_0_length, _nFF_FF, -0xFF, null);
  checkSubRange(_0_length, _nFF_0, 0, null);
  checkSubRange(_0_length, _0_length, null, _0_length.upper);
  checkSubRange(_0_length, _0_instruction, null, _0_length.upper);

  checkSubRange(_0_instruction, FF, -0xFF, null);
  checkSubRange(_0_instruction, FA, -0xFA, null);
  checkSubRange(_0_instruction, nFF, 0xFF, null);
  checkSubRange(_0_instruction, length);
  checkSubRange(_0_instruction, _FA_FF, -0xFF, null);
  checkSubRange(_0_instruction, _0_FF, -0xFF, _0_instruction.upper);
  checkSubRange(_0_instruction, _nFF_FF, -0xFF, null);
  checkSubRange(_0_instruction, _nFF_0, 0, null);
  checkSubRange(_0_instruction, _0_length, null, _0_instruction.upper);
  checkSubRange(_0_instruction, _0_instruction, null, _0_instruction.upper);
}

main() {
  HInstruction.idCounter = 0;
  testAnd();
  testSub();
}

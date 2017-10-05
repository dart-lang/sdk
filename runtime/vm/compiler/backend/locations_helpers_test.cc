// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/locations_helpers.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/unit_test.h"

namespace dart {

#if !defined(TARGET_ARCH_DBC)

#define Reg(index) (static_cast<Register>(index))
#define Fpu(index) (static_cast<FpuRegister>(index))

#define ReqReg Location::RequiresRegister()
#define ReqFpu Location::RequiresFpuRegister()
#define RegLoc(index) Location::RegisterLocation(Reg(index))
#define FpuLoc(index) Location::FpuRegisterLocation(Fpu(index))

static void ValidateSummary(LocationSummary* locs,
                            Location expected_output,
                            intptr_t expected_input_count,
                            const Location* expected_inputs,
                            intptr_t expected_temp_count,
                            const Location* expected_temps) {
  EXPECT(locs->out(0).Equals(expected_output));
  EXPECT_EQ(expected_input_count, locs->input_count());
  for (intptr_t i = 0; i < expected_input_count; i++) {
    EXPECT(locs->in(i).Equals(expected_inputs[i]));
  }
  EXPECT_EQ(expected_temp_count, locs->temp_count());
  for (intptr_t i = 0; i < expected_temp_count; i++) {
    EXPECT(locs->temp(i).Equals(expected_temps[i]));
  }
}

static void FillSummary(LocationSummary* locs,
                        Location expected_output,
                        intptr_t expected_input_count,
                        const Location* expected_inputs,
                        intptr_t expected_temp_count,
                        const Location* expected_temps) {
  locs->set_out(0, expected_output);
  for (intptr_t i = 0; i < expected_input_count; i++) {
    locs->set_in(i, expected_inputs[i]);
  }
  for (intptr_t i = 0; i < expected_temp_count; i++) {
    locs->set_temp(i, expected_temps[i]);
  }
}

class MockInstruction : public ZoneAllocated {
 public:
  virtual ~MockInstruction() {}

  LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary(Thread::Current()->zone(), false);
    }
    return locs_;
  }

  virtual LocationSummary* MakeLocationSummary(Zone* zone, bool opt) const = 0;
  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

 private:
  LocationSummary* locs_;
};

#define INSTRUCTION_TEST(Name, Arity, Signature, ExpectedOut, ExpectedIn,      \
                         ExpectedTemp, AllocatedOut, AllocatedIn,              \
                         AllocatedTemp)                                        \
  class Name##Instr : public MockInstruction {                                 \
   public:                                                                     \
    LocationSummary* MakeLocationSummary(Zone* zone, bool opt) const;          \
    void EmitNativeCode(FlowGraphCompiler* compiler);                          \
    virtual intptr_t InputCount() const { return Arity; }                      \
  };                                                                           \
  TEST_CASE(LocationsHelpers_##Name) {                                         \
    const Location expected_out = ExpectedOut;                                 \
    const Location expected_in[] = {PP_APPLY(PP_UNPACK, ExpectedIn)};          \
    const Location expected_temp[] = {PP_APPLY(PP_UNPACK, ExpectedTemp)};      \
                                                                               \
    const Location allocated_out = AllocatedOut;                               \
    const Location allocated_in[] = {PP_APPLY(PP_UNPACK, AllocatedIn)};        \
    const Location allocated_temp[] = {PP_APPLY(PP_UNPACK, AllocatedTemp)};    \
                                                                               \
    Name##Instr* instr = new Name##Instr();                                    \
    LocationSummary* locs = instr->locs();                                     \
                                                                               \
    ValidateSummary(locs, expected_out, ARRAY_SIZE(expected_in), expected_in,  \
                    ARRAY_SIZE(expected_temp), expected_temp);                 \
    FillSummary(locs, allocated_out, ARRAY_SIZE(allocated_in), allocated_in,   \
                ARRAY_SIZE(allocated_temp), allocated_temp);                   \
                                                                               \
    instr->EmitNativeCode(NULL);                                               \
  }                                                                            \
  DEFINE_BACKEND(Name, Signature)

// Reg -> Reg
INSTRUCTION_TEST(Unary,
                 1,
                 (Register out, Register in),
                 ReqReg,
                 (ReqReg),
                 (),
                 RegLoc(0),
                 (RegLoc(1)),
                 ()) {
  EXPECT_EQ(Reg(0), out);
  EXPECT_EQ(Reg(1), in);
}

// (Reg, Fpu) -> Reg
INSTRUCTION_TEST(Binary1,
                 2,
                 (Register out, Register in0, FpuRegister in1),
                 ReqReg,
                 (ReqReg, Location::RequiresFpuRegister()),
                 (),
                 RegLoc(0),
                 (RegLoc(1), FpuLoc(2)),
                 ()) {
  EXPECT_EQ(Reg(0), out);
  EXPECT_EQ(Reg(1), in0);
  EXPECT_EQ(Fpu(2), in1);
}

// (Fpu, Reg) -> Reg
INSTRUCTION_TEST(Binary2,
                 2,
                 (Register out, FpuRegister in0, Register in1),
                 ReqReg,
                 (ReqFpu, ReqReg),
                 (),
                 RegLoc(0),
                 (FpuLoc(1), RegLoc(2)),
                 ()) {
  EXPECT_EQ(Reg(0), out);
  EXPECT_EQ(Fpu(1), in0);
  EXPECT_EQ(Reg(2), in1);
}

// -> Reg(3)
INSTRUCTION_TEST(FixedOutput,
                 0,
                 (Fixed<Register, Reg(3)> out),
                 RegLoc(3),
                 (),
                 (),
                 RegLoc(3),
                 (),
                 ()) {
  EXPECT_EQ(Reg(3), Reg(out));
}

// Fpu(3) -> Fpu
INSTRUCTION_TEST(FixedInput,
                 1,
                 (FpuRegister out, Fixed<FpuRegister, Fpu(3)> in),
                 ReqFpu,
                 (FpuLoc(3)),
                 (),
                 FpuLoc(0),
                 (FpuLoc(3)),
                 ()) {
  EXPECT_EQ(Fpu(0), out);
  EXPECT_EQ(Fpu(3), Fpu(in));
}

// Reg -> SameAsFirstInput
INSTRUCTION_TEST(SameAsFirstInput,
                 2,
                 (SameAsFirstInput, Register in0, Register in1),
                 Location::SameAsFirstInput(),
                 (ReqReg, ReqReg),
                 (),
                 RegLoc(0),
                 (RegLoc(0), RegLoc(1)),
                 ()) {
  EXPECT_EQ(Reg(0), in0);
  EXPECT_EQ(Reg(1), in1);
}

// {Temps: Fpu, Reg} (Reg, Fpu) -> Reg
INSTRUCTION_TEST(Temps,
                 2,
                 (Register out,
                  Register in0,
                  FpuRegister in1,
                  Temp<FpuRegister> temp0,
                  Temp<Register> temp1),
                 ReqReg,
                 (ReqReg, ReqFpu),
                 (ReqFpu, ReqReg),
                 RegLoc(0),
                 (RegLoc(1), FpuLoc(2)),
                 (FpuLoc(3), RegLoc(4))) {
  EXPECT_EQ(Reg(0), out);
  EXPECT_EQ(Reg(1), in0);
  EXPECT_EQ(Fpu(2), in1);
  EXPECT_EQ(Fpu(3), Fpu(temp0));
  EXPECT_EQ(Reg(4), Reg(temp1));
}

// {Temps: Fpu(3)} -> Fpu
INSTRUCTION_TEST(FixedTemp,
                 0,
                 (FpuRegister out, Temp<Fixed<FpuRegister, Fpu(3)> > temp),
                 ReqFpu,
                 (),
                 (FpuLoc(3)),
                 FpuLoc(4),
                 (),
                 (FpuLoc(3))) {
  EXPECT_EQ(Fpu(4), out);
  EXPECT_EQ(Fpu(3), Fpu(temp));
}

#endif  // !defined(TARGET_ARCH_DBC)

}  // namespace dart

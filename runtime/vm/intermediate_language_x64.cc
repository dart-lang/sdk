// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"

#define __ compiler->assembler()->

namespace dart {


static LocationSummary* MakeSimpleLocationSummary(
    intptr_t input_count, Location out) {
  LocationSummary* summary = new LocationSummary(input_count);
  for (intptr_t i = 0; i < input_count; i++) {
    summary->set_in(i, Location::RequiresRegister());
  }
  summary->set_out(out);
  return summary;
}


LocationSummary* StrictCompareComp::MakeLocationSummary() {
  return MakeSimpleLocationSummary(2, Location::SameAsFirstInput());
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();

  __ cmpq(left, right);
  Label load_true, done;
  if (kind() == Token::kEQ_STRICT) {
    __ j(EQUAL, &load_true, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
  }
  __ LoadObject(result, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(result, bool_true);
  __ Bind(&done);
}


void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  computation()->EmitNativeCode(compiler);
  __ pushq(locs()->out().reg());
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64

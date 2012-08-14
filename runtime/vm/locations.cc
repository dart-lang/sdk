// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/locations.h"

#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/flow_graph_compiler.h"

namespace dart {

LocationSummary::LocationSummary(intptr_t input_count,
                                 intptr_t temp_count,
                                 LocationSummary::ContainsCall contains_call)
    : input_locations_(input_count),
      temp_locations_(temp_count),
      output_location_(),
      stack_bitmap_(NULL),
      is_call_(contains_call == kCall) {
  if (is_call()) stack_bitmap_ = new BitmapBuilder();
  for (intptr_t i = 0; i < input_count; i++) {
    input_locations_.Add(Location());
  }
  for (intptr_t i = 0; i < temp_count; i++) {
    temp_locations_.Add(Location());
  }
}


LocationSummary* LocationSummary::Make(
    intptr_t input_count,
    Location out,
    LocationSummary::ContainsCall contains_call) {
  LocationSummary* summary = new LocationSummary(input_count, 0, contains_call);
  for (intptr_t i = 0; i < input_count; i++) {
    summary->set_in(i, Location::RequiresRegister());
  }
  summary->set_out(out);
  return summary;
}


const char* Location::Name() const {
  switch (kind()) {
    case kInvalid: return "?";
    case kRegister: return Assembler::RegisterName(reg());
    case kStackSlot: return "S";
    case kUnallocated:
      switch (policy()) {
        case kAny:
          return "A";
        case kPrefersRegister:
          return "P";
        case kRequiresRegister:
          return "R";
        case kSameAsFirstInput:
          return "0";
      }
      UNREACHABLE();
    default:
      ASSERT(IsConstant());
      return "C";
  }
  return "?";
}


void Location::PrintTo(BufferFormatter* f) const {
  if (kind() == kStackSlot) {
    f->Print("S%+d", stack_index());
  } else {
    f->Print("%s", Name());
  }
}


void Location::Print() const {
  if (kind() == kStackSlot) {
    OS::Print("S%+d", stack_index());
  } else {
    OS::Print("%s", Name());
  }
}


void LocationSummary::PrintTo(BufferFormatter* f) const {
  if (input_count() > 0) {
    f->Print(" (");
    for (intptr_t i = 0; i < input_count(); i++) {
      if (i != 0) f->Print(", ");
      in(i).PrintTo(f);
    }
    f->Print(")");
  }

  if (temp_count() > 0) {
    f->Print(" [");
    for (intptr_t i = 0; i < temp_count(); i++) {
      if (i != 0) f->Print(", ");
      temp(i).PrintTo(f);
    }
    f->Print("]");
  }

  if (!out().IsInvalid()) {
    f->Print(" => ");
    out().PrintTo(f);
  }

  if (is_call()) f->Print(" C");
}

}  // namespace dart

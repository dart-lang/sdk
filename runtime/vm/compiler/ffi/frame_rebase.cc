// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/frame_rebase.h"

namespace dart {

namespace compiler {

namespace ffi {

const NativeLocation& FrameRebase::Rebase(const NativeLocation& loc) const {
  if (!loc.IsStack() || loc.AsStack().base_register() != old_base_) {
    return loc;
  }

  return *new (zone_) NativeStackLocation(
      loc.payload_type(), loc.container_type(), new_base_,
      loc.AsStack().offset_in_bytes() + stack_delta_in_bytes_);
}

Location FrameRebase::Rebase(const Location loc) const {
  if (loc.IsPairLocation()) {
    return Location::Pair(Rebase(loc.Component(0)), Rebase(loc.Component(1)));
  }
  if (!loc.HasStackIndex() || loc.base_reg() != old_base_) {
    return loc;
  }

  const intptr_t new_stack_index =
      loc.stack_index() + stack_delta_in_bytes_ / compiler::target::kWordSize;
  if (loc.IsStackSlot()) {
    return Location::StackSlot(new_stack_index, new_base_);
  }
  if (loc.IsDoubleStackSlot()) {
    return Location::DoubleStackSlot(new_stack_index, new_base_);
  }
  ASSERT(loc.IsQuadStackSlot());
  return Location::QuadStackSlot(new_stack_index, new_base_);
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

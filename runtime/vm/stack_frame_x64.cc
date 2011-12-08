// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/stack_frame.h"

namespace dart {

// The constant kExitLinkOffsetInEntryFrame must be kept in sync with the
// code in the InvokeDartCode stub.
static const int kExitLinkOffsetInEntryFrame = -8 * kWordSize;


intptr_t StackFrame::PcAddressOffsetFromSp() {
  UNIMPLEMENTED();
  return 0;
}


uword StackFrame::GetCallerFp() const {
  UNIMPLEMENTED();
  return 0;
}


uword StackFrame::GetCallerSp() const {
  UNIMPLEMENTED();
  return 0;
}


intptr_t EntryFrame::ExitLinkOffset() {
  UNIMPLEMENTED();
  return 0;
}


void StackFrameIterator::SetupLastExitFrameData() {
  UNIMPLEMENTED();
}


void StackFrameIterator::SetupNextExitFrameData() {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64

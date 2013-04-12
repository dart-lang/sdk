// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/stack_frame.h"

namespace dart {

// The constant kExitLinkOffsetInEntryFrame must be kept in sync with the
// code in the InvokeDartCode stub.
static const int kExitLinkOffsetInEntryFrame = -10 * kWordSize;
static const int kPcAddressOffsetFromSp = -2 * kWordSize;
static const int kEntrypointMarkerOffsetFromFp = 2 * kWordSize;
static const int kSpOffsetFromPreviousFp = 3 * kWordSize;


intptr_t StackFrame::PcAddressOffsetFromSp() {
  return kPcAddressOffsetFromSp;
}


intptr_t StackFrame::EntrypointMarkerOffsetFromFp() {
  return kEntrypointMarkerOffsetFromFp;
}


uword StackFrame::GetCallerFp() const {
  return *(reinterpret_cast<uword*>(fp()));
}


uword StackFrame::GetCallerSp() const {
  return fp() + kSpOffsetFromPreviousFp;
}


intptr_t EntryFrame::ExitLinkOffset() const {
  UNIMPLEMENTED();
  return 0;
}


intptr_t EntryFrame::SavedContextOffset() const {
  UNIMPLEMENTED();
  return 0;
}


void StackFrameIterator::SetupLastExitFrameData() {
  Isolate* current = Isolate::Current();
  uword exit_marker = current->top_exit_frame_info();
  frames_.fp_ = exit_marker;
}


void StackFrameIterator::SetupNextExitFrameData() {
  uword exit_address = entry_.fp() + kExitLinkOffsetInEntryFrame;
  uword exit_marker = *reinterpret_cast<uword*>(exit_address);
  frames_.fp_ = exit_marker;
  frames_.sp_ = 0;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

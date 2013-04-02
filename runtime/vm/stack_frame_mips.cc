// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/stack_frame.h"

namespace dart {

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
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

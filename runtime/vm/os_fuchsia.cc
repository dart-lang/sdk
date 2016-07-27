// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/os.h"

#include <magenta/syscalls.h>
#include <magenta/types.h>

#include "platform/assert.h"

namespace dart {

const char* OS::Name() {
  return "fuchsia";
}


intptr_t OS::ProcessId() {
  UNIMPLEMENTED();
  return 0;
}


const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  UNIMPLEMENTED();
  return "";
}


int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  UNIMPLEMENTED();
  return 0;
}


int OS::GetLocalTimeZoneAdjustmentInSeconds() {
  UNIMPLEMENTED();
  return 0;
}


int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeMicros() / 1000;
}


int64_t OS::GetCurrentTimeMicros() {
  return _magenta_current_time() / 1000;
}


int64_t OS::GetCurrentMonotonicTicks() {
  UNIMPLEMENTED();
  return 0;
}


int64_t OS::GetCurrentMonotonicFrequency() {
  UNIMPLEMENTED();
  return 0;
}


int64_t OS::GetCurrentMonotonicMicros() {
  UNIMPLEMENTED();
  return 0;
}


int64_t OS::GetCurrentThreadCPUMicros() {
  UNIMPLEMENTED();
  return 0;
}


void* OS::AlignedAllocate(intptr_t size, intptr_t alignment) {
  UNIMPLEMENTED();
  return NULL;
}


void OS::AlignedFree(void* ptr) {
  UNIMPLEMENTED();
}


// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_linux.cc
intptr_t OS::ActivationFrameAlignment() {
  UNIMPLEMENTED();
  return 0;
}


intptr_t OS::PreferredCodeAlignment() {
  UNIMPLEMENTED();
  return 0;
}


bool OS::AllowStackFrameIteratorFromAnotherThread() {
  UNIMPLEMENTED();
  return false;
}


int OS::NumberOfAvailableProcessors() {
  UNIMPLEMENTED();
  return 0;
}


void OS::Sleep(int64_t millis) {
  UNIMPLEMENTED();
}


void OS::SleepMicros(int64_t micros) {
  UNIMPLEMENTED();
}


void OS::DebugBreak() {
  UNIMPLEMENTED();
}


char* OS::StrNDup(const char* s, intptr_t n) {
  UNIMPLEMENTED();
  return NULL;
}


intptr_t OS::StrNLen(const char* s, intptr_t n) {
  UNIMPLEMENTED();
  return 0;
}


void OS::Print(const char* format, ...) {
  UNIMPLEMENTED();
}


void OS::VFPrint(FILE* stream, const char* format, va_list args) {
  vfprintf(stream, format, args);
  fflush(stream);
}


int OS::SNPrint(char* str, size_t size, const char* format, ...) {
  UNIMPLEMENTED();
  return 0;
}


int OS::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  UNIMPLEMENTED();
  return 0;
}


char* OS::SCreate(Zone* zone, const char* format, ...) {
  UNIMPLEMENTED();
  return NULL;
}


char* OS::VSCreate(Zone* zone, const char* format, va_list args) {
  UNIMPLEMENTED();
  return NULL;
}


bool OS::StringToInt64(const char* str, int64_t* value) {
  UNIMPLEMENTED();
  return false;
}


void OS::RegisterCodeObservers() {
  UNIMPLEMENTED();
}


void OS::PrintErr(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VFPrint(stderr, format, args);
  va_end(args);
}


void OS::InitOnce() {
  // TODO(5411554): For now we check that initonce is called only once,
  // Once there is more formal mechanism to call InitOnce we can move
  // this check there.
  static bool init_once_called = false;
  ASSERT(init_once_called == false);
  init_once_called = true;
}


void OS::Shutdown() {
}


void OS::Abort() {
  abort();
}


void OS::Exit(int code) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

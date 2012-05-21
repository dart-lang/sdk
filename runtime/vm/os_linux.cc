// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"

#include <errno.h>
#include <limits.h>
#include <time.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "platform/utils.h"
#include "vm/isolate.h"

namespace dart {

bool OS::GmTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  struct tm* error_code = gmtime_r(&seconds, tm_result);
  return error_code != NULL;
}


bool OS::LocalTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  struct tm* error_code = localtime_r(&seconds, tm_result);
  return error_code != NULL;
}


bool OS::MkGmTime(tm* tm, int64_t* seconds_result) {
  // Set wday to an impossible day, so that we can catch bad input.
  tm->tm_wday = -1;
  time_t seconds = timegm(tm);
  if ((seconds == -1) && (tm->tm_wday == -1)) {
    return false;
  }
  *seconds_result = seconds;
  return true;
}


bool OS::MkTime(tm* tm, int64_t* seconds_result) {
  // Let the libc figure out if daylight saving is active.
  tm->tm_isdst = -1;
  // Set wday to an impossible day, so that we can catch bad input.
  tm->tm_wday = -1;
  time_t seconds = mktime(tm);
  if ((seconds == -1) && (tm->tm_wday == -1)) {
    return false;
  }
  *seconds_result = seconds;
  return true;
}


int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeMicros() / 1000;
}


int64_t OS::GetCurrentTimeMicros() {
  // gettimeofday has microsecond resolution.
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    UNREACHABLE();
    return 0;
  }
  return (static_cast<int64_t>(tv.tv_sec) * 1000000) + tv.tv_usec;
}


// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_linux.cc
word OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM)
  const int kMinimumAlignment = 8;
#else
#error Unsupported architecture.
#endif
  word alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default stack alignment for
  // testing purposes.
  // Flags::DebugIsInt("stackalign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  return alignment;
}


word OS::PreferredCodeAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM)
  const int kMinimumAlignment = 16;
#else
#error Unsupported architecture.
#endif
  word alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default code alignment for
  // testing purposes.
  // Flags::DebugIsInt("codealign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  return alignment;
}


uword OS::GetStackSizeLimit() {
  struct rlimit stack_limit;
  int retval = getrlimit(RLIMIT_STACK, &stack_limit);
  ASSERT(retval == 0);
  if (stack_limit.rlim_cur > INT_MAX) {
    retval = INT_MAX;
  } else {
    retval = stack_limit.rlim_cur;
  }
  return retval;
}


int OS::NumberOfAvailableProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}


void OS::Sleep(int64_t millis) {
  // TODO(5411554):  For now just use usleep we may have to revisit this.
  usleep(millis * 1000);
}


void OS::DebugBreak() {
#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_IA32)
  asm("int $3");
#elif defined(HOST_ARCH_ARM)
  asm("svc #0x9f0001");  // __ARM_NR_breakpoint
#else
#error Unsupported architecture.
#endif
}


void OS::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VFPrint(stdout, format, args);
  va_end(args);
}


void OS::VFPrint(FILE* stream, const char* format, va_list args) {
  vfprintf(stream, format, args);
  fflush(stream);
}


int OS::SNPrint(char* str, size_t size, const char* format, ...) {
  va_list args;
  va_start(args, format);
  int retval = VSNPrint(str, size, format, args);
  va_end(args);
  return retval;
}


int OS::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  return vsnprintf(str, size, format, args);
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
  exit(code);
}

}  // namespace dart

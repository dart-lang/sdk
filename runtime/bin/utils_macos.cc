// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include <errno.h>  // NOLINT
#include <netdb.h>  // NOLINT
#include <mach/mach.h>  // NOLINT
#include <mach/clock.h>  // NOLINT
#include <mach/mach_time.h>  // NOLINT
#include <sys/time.h>  // NOLINT
#include <time.h>  // NOLINT

#include "bin/utils.h"
#include "platform/assert.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_sub_system(kSystem);
  set_code(errno);
  const int kBufferSize = 1024;
  char error_message[kBufferSize];
  Utils::StrError(errno, error_message, kBufferSize);
  SetMessage(error_message);
}


void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);
  if (sub_system == kSystem) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    Utils::StrError(code, error_message, kBufferSize);
    SetMessage(error_message);
  } else if (sub_system == kGetAddressInfo) {
    SetMessage(gai_strerror(code));
  } else {
    UNREACHABLE();
  }
}

const char* StringUtils::ConsoleStringToUtf8(
    const char* str, intptr_t len, intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

const char* StringUtils::Utf8ToConsoleString(
    const char* utf8, intptr_t len, intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::ConsoleStringToUtf8(
    char* str, intptr_t len, intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::Utf8ToConsoleString(
    char* utf8, intptr_t len, intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  return false;
}

void TimerUtils::InitOnce() {
}

int64_t TimerUtils::GetCurrentMonotonicMillis() {
  return GetCurrentMonotonicMicros() / 1000;
}

int64_t TimerUtils::GetCurrentMonotonicMicros() {
#if TARGET_OS_IOS
  // On iOS mach_absolute_time stops while the device is sleeping. Instead use
  // now - KERN_BOOTTIME to get a time difference that is not impacted by clock
  // changes. KERN_BOOTTIME will be updated by the system whenever the system
  // clock change.
  struct timeval boottime;
  int mib[2] = {CTL_KERN, KERN_BOOTTIME};
  size_t size = sizeof(boottime);
  int kr = sysctl(mib, sizeof(mib) / sizeof(mib[0]), &boottime, &size, NULL, 0);
  ASSERT(KERN_SUCCESS == kr);
  int64_t now = GetCurrentTimeMicros();
  int64_t origin = boottime.tv_sec * kMicrosecondsPerSecond;
  origin += boottime.tv_usec;
  return now - origin;
#else
  static mach_timebase_info_data_t timebase_info;
  if (timebase_info.denom == 0) {
    // Zero-initialization of statics guarantees that denom will be 0 before
    // calling mach_timebase_info.  mach_timebase_info will never set denom to
    // 0 as that would be invalid, so the zero-check can be used to determine
    // whether mach_timebase_info has already been called.  This is
    // recommended by Apple's QA1398.
    kern_return_t kr = mach_timebase_info(&timebase_info);
    ASSERT(KERN_SUCCESS == kr);
  }

  // timebase_info converts absolute time tick units into nanoseconds.  Convert
  // to microseconds.
  int64_t result = mach_absolute_time() / kNanosecondsPerMicrosecond;
  result *= timebase_info.numer;
  result /= timebase_info.denom;
  return result;
#endif  // TARGET_OS_IOS
}

void TimerUtils::Sleep(int64_t millis) {
  struct timespec req;  // requested.
  struct timespec rem;  // remainder.
  int64_t micros = millis * kMicrosecondsPerMillisecond;
  int64_t seconds = micros / kMicrosecondsPerSecond;
  micros = micros - seconds * kMicrosecondsPerSecond;
  int64_t nanos = micros * kNanosecondsPerMicrosecond;
  req.tv_sec = seconds;
  req.tv_nsec = nanos;
  while (true) {
    int r = nanosleep(&req, &rem);
    if (r == 0) {
      break;
    }
    // We should only ever see an interrupt error.
    ASSERT(errno == EINTR);
    // Copy remainder into requested and repeat.
    req = rem;
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)

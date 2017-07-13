// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include <errno.h>           // NOLINT
#include <mach/clock.h>      // NOLINT
#include <mach/mach.h>       // NOLINT
#include <mach/mach_time.h>  // NOLINT
#include <netdb.h>           // NOLINT
#if HOST_OS_IOS
#include <sys/sysctl.h>  // NOLINT
#endif
#include <sys/time.h>  // NOLINT
#include <time.h>      // NOLINT

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

const char* StringUtils::ConsoleStringToUtf8(const char* str,
                                             intptr_t len,
                                             intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

const char* StringUtils::Utf8ToConsoleString(const char* utf8,
                                             intptr_t len,
                                             intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::ConsoleStringToUtf8(char* str,
                                       intptr_t len,
                                       intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::Utf8ToConsoleString(char* utf8,
                                       intptr_t len,
                                       intptr_t* result_len) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::StrNDup(const char* s, intptr_t n) {
// strndup has only been added to Mac OS X in 10.7. We are supplying
// our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) ||                 \
    __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ <= 1060
  intptr_t len = strlen(s);
  if ((n < 0) || (len < 0)) {
    return NULL;
  }
  if (n < len) {
    len = n;
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  if (result == NULL) {
    return NULL;
  }
  result[len] = '\0';
  return reinterpret_cast<char*>(memmove(result, s, len));
#else   // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strndup(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  return false;
}

static mach_timebase_info_data_t timebase_info;

void TimerUtils::InitOnce() {
  kern_return_t kr = mach_timebase_info(&timebase_info);
  ASSERT(KERN_SUCCESS == kr);
}

int64_t TimerUtils::GetCurrentMonotonicMillis() {
  return GetCurrentMonotonicMicros() / 1000;
}

#if HOST_OS_IOS
static int64_t GetCurrentTimeMicros() {
  // gettimeofday has microsecond resolution.
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    UNREACHABLE();
    return 0;
  }
  return (static_cast<int64_t>(tv.tv_sec) * 1000000) + tv.tv_usec;
}
#endif  // HOST_OS_IOS

int64_t TimerUtils::GetCurrentMonotonicMicros() {
#if HOST_OS_IOS
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
  ASSERT(timebase_info.denom != 0);
  // timebase_info converts absolute time tick units into nanoseconds.  Convert
  // to microseconds.
  int64_t result = mach_absolute_time() / kNanosecondsPerMicrosecond;
  result *= timebase_info.numer;
  result /= timebase_info.denom;
  return result;
#endif  // HOST_OS_IOS
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

#endif  // defined(HOST_OS_MACOS)

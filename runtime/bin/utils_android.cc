// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include <errno.h>  // NOLINT
#include <netdb.h>  // NOLINT
#include <sys/time.h>  // NOLINT
#include <time.h>  // NOLINT

#include "bin/utils.h"
#include "platform/assert.h"


namespace dart {
namespace bin {

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_sub_system(kSystem);
  set_code(errno);
  const int kBufferSize = 1024;
  char error_message[kBufferSize];
  strerror_r(errno, error_message, kBufferSize);
  SetMessage(error_message);
}


void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);
  if (sub_system == kSystem) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(code, error_message, kBufferSize);
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

int64_t TimerUtils::GetCurrentTimeMilliseconds() {
  return GetCurrentTimeMicros() / 1000;
}

int64_t TimerUtils::GetCurrentTimeMicros() {
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    UNREACHABLE();
    return 0;
  }
  return (static_cast<int64_t>(tv.tv_sec) * 1000000) + tv.tv_usec;
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

#endif  // defined(TARGET_OS_ANDROID)

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include <errno.h>
#include <zircon/syscalls.h>
#include <zircon/types.h>

#include "bin/utils.h"
#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  Reload();
}

void OSError::Reload() {
  SetCodeAndMessage(kSystem, errno);
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);
  if (sub_system == kSystem) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    SetMessage(Utils::StrError(code, error_buf, kBufferSize));
  } else if (sub_system == kGetAddressInfo) {
    UNIMPLEMENTED();
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

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  return false;
}

void TimerUtils::InitOnce() {}

int64_t TimerUtils::GetCurrentMonotonicMillis() {
  return GetCurrentMonotonicMicros() / 1000;
}

int64_t TimerUtils::GetCurrentMonotonicMicros() {
  zx_time_t ticks = zx_clock_get_monotonic();
  return ticks / kNanosecondsPerMicrosecond;
}

void TimerUtils::Sleep(int64_t millis) {
  zx_nanosleep(zx_deadline_after(millis * kMicrosecondsPerMillisecond *
                                 kNanosecondsPerMicrosecond));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)

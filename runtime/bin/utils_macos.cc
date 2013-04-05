// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include <errno.h>  // NOLINT
#include <netdb.h>  // NOLINT
#include <sys/time.h>  // NOLINT

#include "bin/utils.h"
#include "platform/assert.h"

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_sub_system(kSystem);
  set_code(errno);
  SetMessage(strerror(errno));
}


void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);
  if (sub_system == kSystem) {
    SetMessage(strerror(code));
  } else if (sub_system == kGetAddressInfo) {
    SetMessage(gai_strerror(code));
  } else {
    UNREACHABLE();
  }
}

const char* StringUtils::ConsoleStringToUtf8(const char* str) {
  return str;
}

const char* StringUtils::Utf8ToConsoleString(const char* utf8) {
  return utf8;
}

char* StringUtils::ConsoleStringToUtf8(char* str) {
  return str;
}

char* StringUtils::Utf8ToConsoleString(char* utf8) {
  return utf8;
}

wchar_t* StringUtils::Utf8ToWide(char* utf8) {
  UNIMPLEMENTED();
  return NULL;
}

const wchar_t* StringUtils::Utf8ToWide(const char* utf8) {
  UNIMPLEMENTED();
  return NULL;
}

char* StringUtils::WideToUtf8(wchar_t* str) {
  UNIMPLEMENTED();
  return NULL;
}

const char* StringUtils::WideToUtf8(const wchar_t* str) {
  UNIMPLEMENTED();
  return NULL;
}

wchar_t** ShellUtils::GetUnicodeArgv(int* argc) {
  return NULL;
}

void ShellUtils::FreeUnicodeArgv(wchar_t** argv) {
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
  usleep(millis * 1000);
}

#endif  // defined(TARGET_OS_MACOS)

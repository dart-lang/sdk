// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"

#include <time.h>

#include "platform/assert.h"

namespace dart {

bool OS::BreakDownSecondsSinceEpoch(time_t seconds_since_epoch,
                                    bool in_utc,
                                    BrokenDownDate* result) {
  struct tm tm_result;
  errno_t error_code;
  if (in_utc) {
    error_code = gmtime_s(&tm_result, &seconds_since_epoch);
  } else {
    // TODO(floitsch): we should be able to call tzset only once during
    // initialization.
    tzset();  // Make sure the libc knows about the local zone.
    error_code = localtime_s(&tm_result, &seconds_since_epoch);
  }
  result->year = tm_result.tm_year;
  result->month= tm_result.tm_mon;
  result->day = tm_result.tm_mday;
  result->hours = tm_result.tm_hour;
  result->minutes = tm_result.tm_min;
  result->seconds = tm_result.tm_sec;
  return error_code == 0;
}


bool OS::BrokenDownToSecondsSinceEpoch(
    const BrokenDownDate& broken_down, bool in_utc, time_t* result) {
  struct tm tm_broken_down;
  // mktime takes the years since 1900.
  tm_broken_down.tm_year = broken_down.year;
  tm_broken_down.tm_mon = broken_down.month;
  tm_broken_down.tm_mday = broken_down.day;
  tm_broken_down.tm_hour = broken_down.hours;
  tm_broken_down.tm_min = broken_down.minutes;
  tm_broken_down.tm_sec = broken_down.seconds;
  // Set wday to an impossible day, so that we can catch bad input.
  tm_broken_down.tm_wday = -1;
  // Make sure the libc knows about the local zone.
  // In case of 'in_utc' this call is mainly for multi-threading issues. If
  // another thread uses a time-function it will set the timezone. The timezone
  // adjustement below would then not work anymore.
  // TODO(floitsch): we should be able to call tzset only once during
  // initialization.
  tzset();
  if (in_utc) {
    // Disable daylight saving in utc mode.
    tm_broken_down.tm_isdst = 0;
    // mktime assumes that the given date is local time zone.
    *result = mktime(&tm_broken_down);
    // Remove the timezone.
    *result -= timezone;
  } else {
    // Let libc figure out if daylight saving is active.
    tm_broken_down.tm_isdst = -1;
    *result = mktime(&tm_broken_down);
  }
  if ((*result == -1) && (tm_broken_down.tm_wday == -1)) {
    return false;
  }
  return true;
}


int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeMicros() / 1000;
}


int64_t OS::GetCurrentTimeMicros() {
  static const int64_t kTimeEpoc = 116444736000000000LL;
  static const int64_t kTimeScaler = 10;  // 100 ns to us.

  // Although win32 uses 64-bit integers for representing timestamps,
  // these are packed into a FILETIME structure. The FILETIME
  // structure is just a struct representing a 64-bit integer. The
  // TimeStamp union allows access to both a FILETIME and an integer
  // representation of the timestamp. The Windows timestamp is in
  // 100-nanosecond intervals since January 1, 1601.
  union TimeStamp {
    FILETIME ft_;
    int64_t t_;
  };
  TimeStamp time;
  GetSystemTimeAsFileTime(&time.ft_);
  return (time.t_ - kTimeEpoc) / kTimeScaler;
}


word OS::ActivationFrameAlignment() {
#ifdef _WIN64
  // Windows 64-bit ABI requires the stack to be 16-byte aligned.
  return 16;
#else
  // No requirements on Win32.
  return 0;
#endif
}


word OS::PreferredCodeAlignment() {
  return 16;
}


uword OS::GetStackSizeLimit() {
  // TODO(ager): Can you programatically determine the actual stack
  // size limit on Windows? The 2MB limit is set at link time. Maybe
  // that value should be propagated here?
  return 2 * MB;
}


int OS::NumberOfAvailableProcessors() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  return info.dwNumberOfProcessors;
}


void OS::Sleep(int64_t millis) {
  ::Sleep(millis);
}


void OS::DebugBreak() {
  __asm { int 3 }
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


// TODO(asiva): Consider moving this to "globals.h".
#ifndef va_copy
#define va_copy(dst, src) (memmove(&(dst), &(src), sizeof(dst)))
#endif  /* va_copy */


int OS::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  if (str == NULL || size == 0) {
    return _vscprintf(format, args);
  }
  va_list args_copy;
  va_copy(args_copy, args);
  int written =_vsnprintf(str, size, format, args_copy);
  va_end(args_copy);
  if (written < 0) {
    // _vsnprintf returns -1 if the number of characters to be written is
    // larger than 'size', so we call _vscprintf which returns the number
    // of characters that would have been written.
    va_list args_retry;
    va_copy(args_retry, args);
    written = _vscprintf(format, args_retry);
    va_end(args_retry);
  }
  // Make sure to zero-terminate the string if the output was
  // truncated or if there was an error.
  if (written >= size) {
    str[size - 1] = '\0';
  }
  return written;
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
  // Do not pop up a message box when abort is called.
  _set_abort_behavior(0, _WRITE_ABORT_MSG);
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

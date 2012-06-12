// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"

#include <time.h>

#include "platform/assert.h"

namespace dart {

bool OS::GmTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  errno_t error_code = gmtime_s(tm_result, &seconds);
  return error_code == 0;
}


// As a side-effect sets the globals _timezone, _daylight and _tzname.
bool OS::LocalTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  // localtime_s implicitly sets _timezone, _daylight and _tzname.
  errno_t error_code = localtime_s(tm_result, &seconds);
  return error_code == 0;
}


bool OS::MkGmTime(tm* tm, int64_t* seconds_result) {
  // Disable daylight saving.
  tm->tm_isdst = 0;
  // Set wday to an impossible day, so that we can catch bad input.
  tm->tm_wday = -1;
  time_t seconds = _mkgmtime(tm);
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


static int GetDaylightSavingBiasInSeconds() {
  TIME_ZONE_INFORMATION zone_information;
  memset(&zone_information, 0, sizeof(zone_information));
  if (GetTimeZoneInformation(&zone_information) == TIME_ZONE_ID_INVALID) {
    // By default the daylight saving offset is an hour.
    return -60 * 60;
  } else {
    return static_cast<int>(zone_information.DaylightBias * 60);
  }
}

bool OS::GetTimeZoneName(int64_t seconds_since_epoch,
                         const char** name_result) {
  tm decomposed;
  // LocalTime will set _tzname.
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  if (!succeeded) return false;
  int inDaylightSavingsTime = decomposed.tm_isdst;
  if (inDaylightSavingsTime != 0 && inDaylightSavingsTime != 1) {
    return false;
  }
  *name_result = _tzname[inDaylightSavingsTime];
  return true;
}


bool OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch,
                                    int* offset_result) {
  tm decomposed;
  // LocalTime will set _timezone.
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  if (!succeeded) return false;
  int inDaylightSavingsTime = decomposed.tm_isdst;
  if (inDaylightSavingsTime != 0 && inDaylightSavingsTime != 1) {
    return false;
  }
  // Dart and Windows disagree on the sign of the bias.
  *offset_result = static_cast<int>(-_timezone);
  if (inDaylightSavingsTime == 1) {
    static int daylight_bias = GetDaylightSavingBiasInSeconds();
    // Subtract because windows and Dart disagree on the sign.
    *offset_result = *offset_result - daylight_bias;
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

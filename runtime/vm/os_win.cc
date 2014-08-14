// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/os.h"

#include <malloc.h>  // NOLINT
#include <process.h>  // NOLINT
#include <time.h>  // NOLINT

// TODO(iposva): Move this out to bin/thread initialization.
#include "bin/thread.h"

#include "platform/utils.h"
#include "platform/assert.h"
#include "vm/thread.h"
#include "vm/vtune.h"

namespace dart {

const char* OS::Name() {
  return "windows";
}


intptr_t OS::ProcessId() {
  return static_cast<intptr_t>(GetCurrentProcessId());
}


// As a side-effect sets the globals _timezone, _daylight and _tzname.
static bool LocalTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  // localtime_s implicitly sets _timezone, _daylight and _tzname.
  errno_t error_code = localtime_s(tm_result, &seconds);
  return error_code == 0;
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


const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  tm decomposed;
  // LocalTime will set _tzname.
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  if (succeeded) {
    int inDaylightSavingsTime = decomposed.tm_isdst;
    ASSERT(inDaylightSavingsTime == 0 || inDaylightSavingsTime == 1);
    return _tzname[inDaylightSavingsTime];
  } else {
    // Return an empty string like V8 does.
    return "";
  }
}


int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  tm decomposed;
  // LocalTime will set _timezone.
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  if (succeeded) {
    int inDaylightSavingsTime = decomposed.tm_isdst;
    ASSERT(inDaylightSavingsTime == 0 || inDaylightSavingsTime == 1);
    // Dart and Windows disagree on the sign of the bias.
    int offset = static_cast<int>(-_timezone);
    if (inDaylightSavingsTime == 1) {
      static int daylight_bias = GetDaylightSavingBiasInSeconds();
      // Subtract because windows and Dart disagree on the sign.
      offset = offset - daylight_bias;
    }
    return offset;
  } else {
    // Return zero like V8 does.
    return 0;
  }
}


int OS::GetLocalTimeZoneAdjustmentInSeconds() {
  // TODO(floitsch): avoid excessive calls to _tzset?
  _tzset();
  // Dart and Windows disagree on the sign of the bias.
  return static_cast<int>(-_timezone);
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


void* OS::AlignedAllocate(intptr_t size, intptr_t alignment) {
  const int kMinimumAlignment = 16;
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  void* p = _aligned_malloc(size, alignment);
  if (p == NULL) {
    UNREACHABLE();
  }
  return p;
}


void OS::AlignedFree(void* ptr) {
  _aligned_free(ptr);
}


intptr_t OS::ActivationFrameAlignment() {
#ifdef _WIN64
  // Windows 64-bit ABI requires the stack to be 16-byte aligned.
  return 16;
#else
  // No requirements on Win32.
  return 1;
#endif
}


intptr_t OS::PreferredCodeAlignment() {
  ASSERT(32 <= OS::kMaxPreferredCodeAlignment);
  return 32;
}


bool OS::AllowStackFrameIteratorFromAnotherThread() {
  return true;
}


int OS::NumberOfAvailableProcessors() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  return info.dwNumberOfProcessors;
}


void OS::Sleep(int64_t millis) {
  ::Sleep(millis);
}


void OS::SleepMicros(int64_t micros) {
  // Windows only supports millisecond sleeps.
  if (micros < kMicrosecondsPerMillisecond) {
    // Calling ::Sleep with 0 has no determined behaviour, round up.
    micros = kMicrosecondsPerMillisecond;
  }
  OS::Sleep(micros / kMicrosecondsPerMillisecond);
}


void OS::DebugBreak() {
#if defined(_MSC_VER)
  // Microsoft Visual C/C++ or drop-in replacement.
  __debugbreak();
#elif defined(__GCC__)
  // MinGW?
  asm("int $3");
#else
  // Microsoft style assembly.
  __asm {
    int 3
  }
#endif
}


char* OS::StrNDup(const char* s, intptr_t n) {
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
    int retval = _vscprintf(format, args);
    if (retval < 0) {
      FATAL1("Fatal error in OS::VSNPrint with format '%s'", format);
    }
    return retval;
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
    if (written < 0) {
      FATAL1("Fatal error in OS::VSNPrint with format '%s'", format);
    }
    va_end(args_retry);
  }
  // Make sure to zero-terminate the string if the output was
  // truncated or if there was an error.
  if (written >= size) {
    str[size - 1] = '\0';
  }
  return written;
}


bool OS::StringToInt64(const char* str, int64_t* value) {
  ASSERT(str != NULL && strlen(str) > 0 && value != NULL);
  int32_t base = 10;
  char* endptr;
  int i = 0;
  if (str[0] == '-') {
    i = 1;
  }
  if ((str[i] == '0') &&
      (str[i + 1] == 'x' || str[i + 1] == 'X') &&
      (str[i + 2] != '\0')) {
    base = 16;
  }
  errno = 0;
  *value = _strtoi64(str, &endptr, base);
  return ((errno == 0) && (endptr != str) && (*endptr == 0));
}


void OS::RegisterCodeObservers() {
#if defined(DART_VTUNE_SUPPORT)
  CodeObservers::Register(new VTuneCodeObserver);
#endif
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
  MonitorWaitData::monitor_wait_data_key_ = Thread::CreateThreadLocal();
  MonitorData::GetMonitorWaitDataForThread();
  // TODO(iposva): Move this out to bin/thread initialization.
  bin::MonitorWaitData::monitor_wait_data_key_ = Thread::CreateThreadLocal();
  bin::MonitorData::GetMonitorWaitDataForThread();
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

#endif  // defined(TARGET_OS_WINDOWS)

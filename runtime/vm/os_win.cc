// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "vm/os.h"

#include <malloc.h>   // NOLINT
#include <process.h>  // NOLINT
#include <psapi.h>    // NOLINT
#include <time.h>     // NOLINT

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/os_thread.h"
#include "vm/zone.h"

namespace dart {

// Defined in vm/os_thread_win.cc
extern bool private_flag_windows_run_tls_destructors;

const char* OS::Name() {
  return "windows";
}

intptr_t OS::ProcessId() {
  return static_cast<intptr_t>(GetCurrentProcessId());
}

// As a side-effect sets the globals _timezone, _daylight and _tzname.
static bool LocalTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) {
    return false;
  }
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
  TIME_ZONE_INFORMATION zone_information;
  memset(&zone_information, 0, sizeof(zone_information));

  // Initialize and grab the time zone data.
  _tzset();
  DWORD status = GetTimeZoneInformation(&zone_information);
  if (GetTimeZoneInformation(&zone_information) == TIME_ZONE_ID_INVALID) {
    // If we can't get the time zone data, the Windows docs indicate that we
    // are probably out of memory. Return an empty string.
    return "";
  }

  // Figure out whether we're in standard or daylight.
  bool daylight_savings = (status == TIME_ZONE_ID_DAYLIGHT);
  if (status == TIME_ZONE_ID_UNKNOWN) {
    tm local_time;
    if (LocalTime(seconds_since_epoch, &local_time)) {
      daylight_savings = (local_time.tm_isdst == 1);
    }
  }

  // Convert the wchar string to a null-terminated utf8 string.
  wchar_t* wchar_name = daylight_savings ? zone_information.DaylightName
                                         : zone_information.StandardName;
  intptr_t utf8_len =
      WideCharToMultiByte(CP_UTF8, 0, wchar_name, -1, NULL, 0, NULL, NULL);
  char* name = Thread::Current()->zone()->Alloc<char>(utf8_len + 1);
  WideCharToMultiByte(CP_UTF8, 0, wchar_name, -1, name, utf8_len, NULL, NULL);
  name[utf8_len] = '\0';
  return name;
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

static int64_t qpc_ticks_per_second = 0;

int64_t OS::GetCurrentMonotonicTicks() {
  if (qpc_ticks_per_second == 0) {
    // QueryPerformanceCounter not supported, fallback.
    return GetCurrentTimeMicros();
  }
  // Grab performance counter value.
  LARGE_INTEGER now;
  QueryPerformanceCounter(&now);
  return static_cast<int64_t>(now.QuadPart);
}

int64_t OS::GetCurrentMonotonicFrequency() {
  if (qpc_ticks_per_second == 0) {
    // QueryPerformanceCounter not supported, fallback.
    return kMicrosecondsPerSecond;
  }
  return qpc_ticks_per_second;
}

int64_t OS::GetCurrentMonotonicMicros() {
  int64_t ticks = GetCurrentMonotonicTicks();
  int64_t frequency = GetCurrentMonotonicFrequency();

  // Convert to microseconds.
  int64_t seconds = ticks / frequency;
  int64_t leftover_ticks = ticks - (seconds * frequency);
  int64_t result = seconds * kMicrosecondsPerSecond;
  result += ((leftover_ticks * kMicrosecondsPerSecond) / frequency);
  return result;
}

int64_t OS::GetCurrentThreadCPUMicros() {
  // TODO(johnmccutchan): Implement. See base/time_win.cc for details.
  return -1;
}

intptr_t OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_ARM64)
  return 16;
#elif defined(TARGET_ARCH_ARM)
  return 8;
#elif defined(_WIN64)
  // Windows 64-bit ABI requires the stack to be 16-byte aligned.
  return 16;
#else
  // No requirements on Win32.
  return 1;
#endif
}

intptr_t OS::PreferredCodeAlignment() {
  ASSERT(32 <= OS::kMaxPreferredCodeAlignment);
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_DBC)
  return 32;
#elif defined(TARGET_ARCH_ARM)
  return 16;
#else
#error Unsupported architecture.
#endif
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
  __builtin_trap();
#else
  // Microsoft style assembly.
  __asm {
    int 3
  }
#endif
}

DART_NOINLINE uintptr_t OS::GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(_ReturnAddress());
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

intptr_t OS::StrNLen(const char* s, intptr_t n) {
  return strnlen(s, n);
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
  int written = _vsnprintf(str, size, format, args_copy);
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
  // The static cast is safe here as we have already determined that 'written'
  // is >= 0.
  if (static_cast<size_t>(written) >= size) {
    str[size - 1] = '\0';
  }
  return written;
}

char* OS::SCreate(Zone* zone, const char* format, ...) {
  va_list args;
  va_start(args, format);
  char* buffer = VSCreate(zone, format, args);
  va_end(args);
  return buffer;
}

char* OS::VSCreate(Zone* zone, const char* format, va_list args) {
  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  char* buffer;
  if (zone) {
    buffer = zone->Alloc<char>(len + 1);
  } else {
    buffer = reinterpret_cast<char*>(malloc(len + 1));
  }
  ASSERT(buffer != NULL);

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  VSNPrint(buffer, len + 1, format, print_args);
  va_end(print_args);
  return buffer;
}

bool OS::StringToInt64(const char* str, int64_t* value) {
  ASSERT(str != NULL && strlen(str) > 0 && value != NULL);
  int32_t base = 10;
  char* endptr;
  int i = 0;
  if (str[0] == '-') {
    i = 1;
  }
  if ((str[i] == '0') && (str[i + 1] == 'x' || str[i + 1] == 'X') &&
      (str[i + 2] != '\0')) {
    base = 16;
  }
  errno = 0;
  *value = _strtoi64(str, &endptr, base);
  return ((errno == 0) && (endptr != str) && (*endptr == 0));
}

void OS::RegisterCodeObservers() {}

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
  ThreadLocalData::InitOnce();
  MonitorWaitData::monitor_wait_data_key_ = OSThread::CreateThreadLocal();
  MonitorData::GetMonitorWaitDataForThread();
  LARGE_INTEGER ticks_per_sec;
  if (!QueryPerformanceFrequency(&ticks_per_sec)) {
    qpc_ticks_per_second = 0;
  } else {
    qpc_ticks_per_second = static_cast<int64_t>(ticks_per_sec.QuadPart);
  }
}

void OS::Shutdown() {
  // TODO(zra): Enable once VM can shutdown cleanly.
  // ThreadLocalData::Shutdown();
}

void OS::Abort() {
  // TODO(zra): Remove once VM shuts down cleanly.
  private_flag_windows_run_tls_destructors = false;
  abort();
}

void OS::Exit(int code) {
  // TODO(zra): Remove once VM shuts down cleanly.
  private_flag_windows_run_tls_destructors = false;
  // On Windows we use ExitProcess so that threads can't clobber the exit_code.
  // See: https://code.google.com/p/nativeclient/issues/detail?id=2870
  ::ExitProcess(code);
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_MACOS)

#include "vm/os.h"

#include <errno.h>           // NOLINT
#include <limits.h>          // NOLINT
#include <mach/clock.h>      // NOLINT
#include <mach/mach.h>       // NOLINT
#include <mach/mach_time.h>  // NOLINT
#include <sys/resource.h>    // NOLINT
#include <sys/time.h>        // NOLINT
#include <unistd.h>          // NOLINT
#if HOST_OS_IOS
#include <syslog.h>  // NOLINT
#endif

#include "platform/utils.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

const char* OS::Name() {
#if HOST_OS_IOS
  return "ios";
#else
  return "macos";
#endif
}

intptr_t OS::ProcessId() {
  return static_cast<intptr_t>(getpid());
}

static bool LocalTime(int64_t seconds_since_epoch, tm* tm_result) {
  time_t seconds = static_cast<time_t>(seconds_since_epoch);
  if (seconds != seconds_since_epoch) return false;
  struct tm* error_code = localtime_r(&seconds, tm_result);
  return error_code != NULL;
}

const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  tm decomposed;
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  // If unsuccessful, return an empty string like V8 does.
  return (succeeded && (decomposed.tm_zone != NULL)) ? decomposed.tm_zone : "";
}

int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  tm decomposed;
  bool succeeded = LocalTime(seconds_since_epoch, &decomposed);
  // Even if the offset was 24 hours it would still easily fit into 32 bits.
  // If unsuccessful, return zero like V8 does.
  return succeeded ? static_cast<int>(decomposed.tm_gmtoff) : 0;
}

int OS::GetLocalTimeZoneAdjustmentInSeconds() {
  // TODO(floitsch): avoid excessive calls to tzset?
  tzset();
  // Even if the offset was 24 hours it would still easily fit into 32 bits.
  // Note that Unix and Dart disagree on the sign.
  return static_cast<int>(-timezone);
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

static mach_timebase_info_data_t timebase_info;

int64_t OS::GetCurrentMonotonicTicks() {
  if (timebase_info.denom == 0) {
    kern_return_t kr = mach_timebase_info(&timebase_info);
    ASSERT(KERN_SUCCESS == kr);
  }
  ASSERT(timebase_info.denom != 0);
  // timebase_info converts absolute time tick units into nanoseconds.
  int64_t result = mach_absolute_time();
  result *= timebase_info.numer;
  result /= timebase_info.denom;
  return result;
}

int64_t OS::GetCurrentMonotonicFrequency() {
  return kNanosecondsPerSecond;
}

int64_t OS::GetCurrentMonotonicMicros() {
  ASSERT(GetCurrentMonotonicFrequency() == kNanosecondsPerSecond);
  return GetCurrentMonotonicTicks() / kNanosecondsPerMicrosecond;
}

int64_t OS::GetCurrentThreadCPUMicros() {
#if HOST_OS_IOS
  // Thread CPU time appears unreliable on iOS, sometimes incorrectly reporting
  // no time elapsed.
  return -1;
#else
  mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
  thread_basic_info_data_t info_data;
  thread_basic_info_t info = &info_data;
  mach_port_t thread_port = pthread_mach_thread_np(pthread_self());
  kern_return_t r =
      thread_info(thread_port, THREAD_BASIC_INFO, (thread_info_t)info, &count);
  ASSERT(r == KERN_SUCCESS);
  int64_t thread_cpu_micros =
      (info->system_time.seconds + info->user_time.seconds);
  thread_cpu_micros *= kMicrosecondsPerSecond;
  thread_cpu_micros += info->user_time.microseconds;
  thread_cpu_micros += info->system_time.microseconds;
  return thread_cpu_micros;
#endif
}

intptr_t OS::ActivationFrameAlignment() {
#if HOST_OS_IOS
#if TARGET_ARCH_ARM
  // Even if we generate code that maintains a stronger alignment, we cannot
  // assert the stronger stack alignment because C++ code will not maintain it.
  return 8;
#elif TARGET_ARCH_ARM64
  return 16;
#elif TARGET_ARCH_IA32
  return 16;  // iOS simulator
#elif TARGET_ARCH_X64
  return 16;  // iOS simulator
#elif TARGET_ARCH_DBC
  return 16;  // Should be at least as much as any host architecture.
#else
#error Unimplemented
#endif
#else   // HOST_OS_IOS
  // OS X activation frames must be 16 byte-aligned; see "Mac OS X ABI
  // Function Call Guide".
  return 16;
#endif  // HOST_OS_IOS
}

intptr_t OS::PreferredCodeAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_DBC)
  const int kMinimumAlignment = 32;
#elif defined(TARGET_ARCH_ARM)
  const int kMinimumAlignment = 16;
#else
#error Unsupported architecture.
#endif
  intptr_t alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default code alignment for
  // testing purposes.
  // Flags::DebugIsInt("codealign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  ASSERT(alignment <= OS::kMaxPreferredCodeAlignment);
  return alignment;
}

int OS::NumberOfAvailableProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}

void OS::Sleep(int64_t millis) {
  int64_t micros = millis * kMicrosecondsPerMillisecond;
  SleepMicros(micros);
}

void OS::SleepMicros(int64_t micros) {
  struct timespec req;  // requested.
  struct timespec rem;  // remainder.
  int64_t seconds = micros / kMicrosecondsPerSecond;
  if (seconds > kMaxInt32) {
    // Avoid truncation of overly large sleep values.
    seconds = kMaxInt32;
  }
  micros = micros - seconds * kMicrosecondsPerSecond;
  int64_t nanos = micros * kNanosecondsPerMicrosecond;
  req.tv_sec = static_cast<int32_t>(seconds);
  req.tv_nsec = static_cast<long>(nanos);  // NOLINT (long used in timespec).
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

void OS::DebugBreak() {
  __builtin_trap();
}

DART_NOINLINE uintptr_t OS::GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(
      __builtin_extract_return_addr(__builtin_return_address(0)));
}

void OS::Print(const char* format, ...) {
#if HOST_OS_IOS
  va_list args;
  va_start(args, format);
  vsyslog(LOG_INFO, format, args);
  va_end(args);
#else
  va_list args;
  va_start(args, format);
  VFPrint(stdout, format, args);
  va_end(args);
#endif
}

void OS::VFPrint(FILE* stream, const char* format, va_list args) {
  vfprintf(stream, format, args);
  fflush(stream);
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
  intptr_t len = Utils::VSNPrint(NULL, 0, format, measure_args);
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
  Utils::VSNPrint(buffer, len + 1, format, print_args);
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
  } else if (str[0] == '+') {
    i = 1;
  }
  if ((str[i] == '0') && (str[i + 1] == 'x' || str[i + 1] == 'X') &&
      (str[i + 2] != '\0')) {
    base = 16;
  }
  errno = 0;
  if (base == 16) {
    // Unsigned 64-bit hexadecimal integer literals are allowed but
    // immediately interpreted as signed 64-bit integers.
    *value = static_cast<int64_t>(strtoull(str, &endptr, base));
  } else {
    *value = strtoll(str, &endptr, base);
  }
  return ((errno == 0) && (endptr != str) && (*endptr == 0));
}

void OS::RegisterCodeObservers() {}

void OS::PrintErr(const char* format, ...) {
#if HOST_OS_IOS
  va_list args;
  va_start(args, format);
  vsyslog(LOG_ERR, format, args);
  va_end(args);
#else
  va_list args;
  va_start(args, format);
  VFPrint(stderr, format, args);
  va_end(args);
#endif
}

void OS::Init() {
  // See https://github.com/dart-lang/sdk/issues/29539
  // This is a workaround for a macos bug, we eagerly call localtime_r so that
  // libnotify is initialized early before any fork happens.
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    FATAL1("gettimeofday returned an error (%s)\n", strerror(errno));
    return;
  }
  tm decomposed;
  struct tm* error_code = localtime_r(&(tv.tv_sec), &decomposed);
  if (error_code == NULL) {
    FATAL1("localtime_r returned an error (%s)\n", strerror(errno));
    return;
  }
}

void OS::Cleanup() {}

void OS::PrepareToAbort() {}

void OS::Abort() {
  PrepareToAbort();
  abort();
}

void OS::Exit(int code) {
  exit(code);
}

}  // namespace dart

#endif  // defined(HOST_OS_MACOS)

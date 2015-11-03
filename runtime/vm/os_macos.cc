// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_MACOS)

#include "vm/os.h"

#include <errno.h>  // NOLINT
#include <limits.h>  // NOLINT
#include <mach/mach.h>  // NOLINT
#include <mach/clock.h>  // NOLINT
#include <mach/mach_time.h>  // NOLINT
#include <sys/time.h>  // NOLINT
#include <sys/resource.h>  // NOLINT
#include <unistd.h>  // NOLINT
#if TARGET_OS_IOS
#include <sys/sysctl.h>  // NOLINT
#include <syslog.h>  // NOLINT
#endif

#include "platform/utils.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

const char* OS::Name() {
  return "macos";
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


int64_t OS::GetCurrentTraceMicros() {
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


void* OS::AlignedAllocate(intptr_t size, intptr_t alignment) {
  const int kMinimumAlignment = 16;
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  // Temporary workaround until xcode is upgraded.
  // Mac guarantees malloc returns a 16 byte aligned memory chunk.
  // Currently we only allocate with 16-bye alignment.
  ASSERT(alignment == 16);
  // TODO(johnmccutchan): Remove hack and switch to posix_memalign.
  return malloc(size);
}


void OS::AlignedFree(void* ptr) {
  free(ptr);
}


intptr_t OS::ActivationFrameAlignment() {
#if TARGET_OS_IOS
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
#else
#error Unimplemented
#endif
#else  // TARGET_OS_IOS
  // OS X activation frames must be 16 byte-aligned; see "Mac OS X ABI
  // Function Call Guide".
  return 16;
#endif  // TARGET_OS_IOS
}


intptr_t OS::PreferredCodeAlignment() {
  ASSERT(32 <= OS::kMaxPreferredCodeAlignment);
  return 32;
}


bool OS::AllowStackFrameIteratorFromAnotherThread() {
  return false;
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


char* OS::StrNDup(const char* s, intptr_t n) {
  // strndup has only been added to Mac OS X in 10.7. We are supplying
  // our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || \
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
#else  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strndup(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}


void OS::Print(const char* format, ...) {
#if TARGET_OS_IOS
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


int OS::SNPrint(char* str, size_t size, const char* format, ...) {
  va_list args;
  va_start(args, format);
  int retval = VSNPrint(str, size, format, args);
  va_end(args);
  return retval;
}


int OS::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  int retval = vsnprintf(str, size, format, args);
  if (retval < 0) {
    FATAL1("Fatal error in OS::VSNPrint with format '%s'", format);
  }
  return retval;
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
  if ((str[i] == '0') &&
      (str[i + 1] == 'x' || str[i + 1] == 'X') &&
      (str[i + 2] != '\0')) {
    base = 16;
  }
  errno = 0;
  *value = strtoll(str, &endptr, base);
  return ((errno == 0) && (endptr != str) && (*endptr == 0));
}


void OS::RegisterCodeObservers() {
}


void OS::PrintErr(const char* format, ...) {
#if TARGET_OS_IOS
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


void OS::InitOnce() {
  // TODO(5411554): For now we check that initonce is called only once,
  // Once there is more formal mechanism to call InitOnce we can move
  // this check there.
  static bool init_once_called = false;
  ASSERT(init_once_called == false);
  init_once_called = true;
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

#endif  // defined(TARGET_OS_MACOS)

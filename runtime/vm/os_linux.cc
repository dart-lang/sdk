// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_LINUX)

#include "vm/os.h"

#include <errno.h>         // NOLINT
#include <limits.h>        // NOLINT
#include <malloc.h>        // NOLINT
#include <time.h>          // NOLINT
#include <sys/resource.h>  // NOLINT
#include <sys/time.h>      // NOLINT
#include <sys/types.h>     // NOLINT
#include <sys/syscall.h>   // NOLINT
#include <sys/stat.h>      // NOLINT
#include <fcntl.h>         // NOLINT
#include <unistd.h>        // NOLINT

#include "platform/memory_sanitizer.h"
#include "platform/utils.h"
#include "vm/code_observers.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/os_thread.h"
#include "vm/zone.h"


namespace dart {

#ifndef PRODUCT

DEFINE_FLAG(bool,
            generate_perf_events_symbols,
            false,
            "Generate events symbols for profiling with perf");

// Linux CodeObservers.
class PerfCodeObserver : public CodeObserver {
 public:
  PerfCodeObserver() : out_file_(NULL) {
    Dart_FileOpenCallback file_open = Dart::file_open_callback();
    if (file_open == NULL) {
      return;
    }
    intptr_t pid = getpid();
    char* filename = OS::SCreate(NULL, "/tmp/perf-%" Pd ".map", pid);
    out_file_ = (*file_open)(filename, true);
    free(filename);
  }

  ~PerfCodeObserver() {
    Dart_FileCloseCallback file_close = Dart::file_close_callback();
    if ((file_close == NULL) || (out_file_ == NULL)) {
      return;
    }
    (*file_close)(out_file_);
  }

  virtual bool IsActive() const {
    return FLAG_generate_perf_events_symbols && (out_file_ != NULL);
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    Dart_FileWriteCallback file_write = Dart::file_write_callback();
    if ((file_write == NULL) || (out_file_ == NULL)) {
      return;
    }
    const char* marker = optimized ? "*" : "";
    char* buffer =
        OS::SCreate(Thread::Current()->zone(), "%" Px " %" Px " %s%s\n", base,
                    size, marker, name);
    {
      MutexLocker ml(CodeObservers::mutex());
      (*file_write)(buffer, strlen(buffer), out_file_);
    }
  }

 private:
  void* out_file_;

  DISALLOW_COPY_AND_ASSIGN(PerfCodeObserver);
};


#endif  // !PRODUCT

const char* OS::Name() {
  return "linux";
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


int64_t OS::GetCurrentMonotonicTicks() {
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    UNREACHABLE();
    return 0;
  }
  // Convert to nanoseconds.
  int64_t result = ts.tv_sec;
  result *= kNanosecondsPerSecond;
  result += ts.tv_nsec;
  return result;
}


int64_t OS::GetCurrentMonotonicFrequency() {
  return kNanosecondsPerSecond;
}


int64_t OS::GetCurrentMonotonicMicros() {
  int64_t ticks = GetCurrentMonotonicTicks();
  ASSERT(GetCurrentMonotonicFrequency() == kNanosecondsPerSecond);
  return ticks / kNanosecondsPerMicrosecond;
}


int64_t OS::GetCurrentThreadCPUMicros() {
  struct timespec ts;
  if (clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts) != 0) {
    UNREACHABLE();
    return -1;
  }
  int64_t result = ts.tv_sec;
  result *= kMicrosecondsPerSecond;
  result += (ts.tv_nsec / kNanosecondsPerMicrosecond);
  return result;
}


// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_linux.cc
intptr_t OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_DBC)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM)
  const int kMinimumAlignment = 8;
#else
#error Unsupported architecture.
#endif
  intptr_t alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default stack alignment for
  // testing purposes.
  // Flags::DebugIsInt("stackalign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  return alignment;
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


uintptr_t OS::MaxRSS() {
  struct rusage usage;
  usage.ru_maxrss = 0;
  int r = getrusage(RUSAGE_SELF, &usage);
  ASSERT(r == 0);
  return usage.ru_maxrss * KB;
}


void OS::Sleep(int64_t millis) {
  int64_t micros = millis * kMicrosecondsPerMillisecond;
  SleepMicros(micros);
}


void OS::SleepMicros(int64_t micros) {
  struct timespec req;  // requested.
  struct timespec rem;  // remainder.
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


// TODO(regis, iposva): When this function is no longer called from the
// CodeImmutability test in object_test.cc, it will be called only from the
// simulator, which means that only the Intel implementation is needed.
void OS::DebugBreak() {
  __builtin_trap();
}


uintptr_t DART_NOINLINE OS::GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(
      __builtin_extract_return_addr(__builtin_return_address(0)));
}


char* OS::StrNDup(const char* s, intptr_t n) {
  return strndup(s, n);
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
  MSAN_UNPOISON(str, size);
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
  if ((str[i] == '0') && (str[i + 1] == 'x' || str[i + 1] == 'X') &&
      (str[i + 2] != '\0')) {
    base = 16;
  }
  errno = 0;
  *value = strtoll(str, &endptr, base);
  return ((errno == 0) && (endptr != str) && (*endptr == 0));
}


void OS::RegisterCodeObservers() {
#ifndef PRODUCT
  if (FLAG_generate_perf_events_symbols) {
    CodeObservers::Register(new PerfCodeObserver);
  }
#endif  // !PRODUCT
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
}


void OS::Shutdown() {}


void OS::Abort() {
  abort();
}


void OS::Exit(int code) {
  exit(code);
}

}  // namespace dart

#endif  // defined(HOST_OS_LINUX)

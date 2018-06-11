// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "vm/os.h"

#include <errno.h>
#include <lib/fdio/util.h>
#include <zircon/process.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/types.h>

#include <time_zone/cpp/fidl.h>

#include "lib/app/cpp/environment_services.h"

#include "platform/assert.h"
#include "vm/zone.h"

namespace dart {

#ifndef PRODUCT

DEFINE_FLAG(bool,
            generate_perf_events_symbols,
            false,
            "Generate events symbols for profiling with perf");

#endif  // !PRODUCT

const char* OS::Name() {
  return "fuchsia";
}

intptr_t OS::ProcessId() {
  return static_cast<intptr_t>(getpid());
}

static zx_status_t GetLocalAndDstOffsetInSeconds(int64_t seconds_since_epoch,
                                                 int32_t* local_offset,
                                                 int32_t* dst_offset) {
  time_zone::TimezoneSyncPtr time_svc;
  fuchsia::sys::ConnectToEnvironmentService(time_svc.NewRequest());
  if (!time_svc->GetTimezoneOffsetMinutes(seconds_since_epoch * 1000,
                                          local_offset, dst_offset))
    return ZX_ERR_UNAVAILABLE;
  *local_offset *= 60;
  *dst_offset *= 60;
  return ZX_OK;
}

const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  // TODO(abarth): Handle time zone changes.
  static const auto* tz_name = new std::string([] {
    time_zone::TimezoneSyncPtr time_svc;
    fuchsia::sys::ConnectToEnvironmentService(time_svc.NewRequest());
    fidl::StringPtr result;
    time_svc->GetTimezoneId(&result);
    return *result;
  }());
  return tz_name->c_str();
}

int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  int32_t local_offset, dst_offset;
  zx_status_t status = GetLocalAndDstOffsetInSeconds(
      seconds_since_epoch, &local_offset, &dst_offset);
  return status == ZX_OK ? local_offset + dst_offset : 0;
}

int OS::GetLocalTimeZoneAdjustmentInSeconds() {
  int32_t local_offset, dst_offset;
  zx_status_t status = GetLocalAndDstOffsetInSeconds(
      zx_clock_get(ZX_CLOCK_UTC) / ZX_SEC(1), &local_offset, &dst_offset);
  return status == ZX_OK ? local_offset : 0;
}

int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeMicros() / 1000;
}

int64_t OS::GetCurrentTimeMicros() {
  return zx_clock_get(ZX_CLOCK_UTC) / kNanosecondsPerMicrosecond;
}

int64_t OS::GetCurrentMonotonicTicks() {
  return zx_clock_get(ZX_CLOCK_MONOTONIC);
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
  return zx_clock_get(ZX_CLOCK_THREAD) / kNanosecondsPerMicrosecond;
}

// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_fuchsia.cc
intptr_t OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_DBC)
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
  return sysconf(_SC_NPROCESSORS_CONF);
}

void OS::Sleep(int64_t millis) {
  SleepMicros(millis * kMicrosecondsPerMillisecond);
}

void OS::SleepMicros(int64_t micros) {
  zx_nanosleep(zx_deadline_after(micros * kNanosecondsPerMicrosecond));
}

void OS::DebugBreak() {
  UNIMPLEMENTED();
}

DART_NOINLINE uintptr_t OS::GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(
      __builtin_extract_return_addr(__builtin_return_address(0)));
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

void OS::RegisterCodeObservers() {
#ifndef PRODUCT
  if (FLAG_generate_perf_events_symbols) {
    UNIMPLEMENTED();
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
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)

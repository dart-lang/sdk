// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "third_party/icu/source/common/unicode/errorcode.h"
#include "third_party/icu/source/i18n/unicode/timezone.h"
#include "vm/os.h"

#include <fuchsia/intl/cpp/fidl.h>
#include <lib/sys/cpp/service_directory.h>
#include <zircon/process.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/types.h>

#include <errno.h>

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

// This is the default timezone returned if it could not be obtained.  For
// Fuchsia, the default device timezone is always UTC.
static const char[] DEFAULT_TIMEZONE = "UTC";

// TODO(FL-98): Change this to talk to fuchsia.dart to get timezone service to
// directly get timezone.
//
// Putting this hack right now due to CP-120 as I need to remove
// component:ConnectToEnvironmentServices and this is the only thing that is
// blocking it and FL-98 will take time.
static fuchsia::intl::PropertyProviderSyncPtr pp;

// 1000 milliseconds do one second make.
static const int32_t kMSPerSec = 1000;

static zx_status_t GetLocalAndDstOffsetInSeconds(int64_t seconds_since_epoch,
                                                 int32_t* local_offset,
                                                 int32_t* dst_offset) {
  const std::string timezone_id = GetTimeZoneName(seconds_since_epoch);
  std::unique_ptr<icu::TimeZone> timezone(
    icu::TimeZone::createTimeZone(timezone_id.c_str()));
  UErrorCode error = U_ZERO_ERROR;
  const auto ms_since_epoch =
    static_cast<UDate>(kMSPerSec * seconds_since_epoch);
  // The units of time that local_offset and dst_offset are returned from this
  // function is, usefully, not documented, but it seems that the units are
  // milliseconds.  Add these variables here for clarity.
  int32_t local_offset_ms = 0;
  int32_t dst_offset_ms = 0;
  timezone->getOffset(ms_since_epoch, false /* no local time */,
    local_offset_ms, dst_offset_ms, error);
  if (error != U_ZERO_ERROR) {
    icu::ErrorCode icu_error;
	icu_error.set(error);
	// Sadly there is no way to report the actual error.  Next best thing is to
	// log.  On the upside, a direct call to timezone->getOffset should fail
	// rarely, so this should not amount to log spam.
	LOG(ERROR) << "could not get DST offset: " << icu_error.errorName();
	return ZX_ERR_INTERNAL;
  }
  // We must return offset in seconds, so convert.
  *local_offset = local_offset_ms / kMSPerSec;
  *dst_offset = dst_offset_ms / kMSPerSec;
  return ZX_OK;
}

const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  // TODO(abarth): Handle time zone changes.
  static const auto* tz_name = new std::string([] {
    fuchsia::intl::Profile profile;
    zx_status_t status = pp->GetProfile(&profile);
    if (status != ZX_OK) {
      return DEFAULT_TIMEZONE;
    }
    const std::vector<fuchsia::intl::TimeZoneId>& tzs = profile.time_zones();
    if (tzs.empty()) {
      return DEFAULT_TIMEZONE;
    }
    return tzs[0].id;
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
  zx_time_t now = 0;
  zx_clock_get(ZX_CLOCK_UTC, &now);
  zx_status_t status = GetLocalAndDstOffsetInSeconds(
      now / ZX_SEC(1), &local_offset, &dst_offset);
  return status == ZX_OK ? local_offset : 0;
}

int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeMicros() / 1000;
}

int64_t OS::GetCurrentTimeMicros() {
  zx_time_t now = 0;
  zx_clock_get(ZX_CLOCK_UTC, &now);
  return now / kNanosecondsPerMicrosecond;
}

int64_t OS::GetCurrentMonotonicTicks() {
  return zx_clock_get_monotonic();
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
  zx_time_t now = 0;
  zx_clock_get(ZX_CLOCK_THREAD, &now);
  return now / kNanosecondsPerMicrosecond;
}

// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_fuchsia.cc
intptr_t OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM64)
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

void OS::Init() {
  auto services = sys::ServiceDirectory::CreateFromNamespace();
  services->Connect(pp.NewRequest());
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

#endif  // defined(HOST_OS_FUCHSIA)

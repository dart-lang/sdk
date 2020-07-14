// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "vm/os.h"

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>

#include <fuchsia/intl/cpp/fidl.h>
#include <lib/inspect/cpp/inspect.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/sys/inspect/cpp/component.h>
#include <zircon/process.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/types.h>

#include "unicode/errorcode.h"
#include "unicode/timezone.h"

#include "platform/assert.h"
#include "platform/syslog.h"
#include "platform/utils.h"
#include "vm/zone.h"

namespace {

static constexpr int32_t kMsPerSec = 1000;

// The data directory containing ICU timezone data files.
static constexpr char kICUTZDataDir[] = "/config/data/tzdata/icu/44/le";

// This is the general OK status.
static constexpr int32_t kOk = 0;

// This status means that the error code is not initialized yet ("set" was not
// yet called).  Error codes are usually either 0 (kOk), or negative.
static constexpr int32_t kUninitialized = 1;

// The status codes for tzdata file open and read.
enum class TZDataStatus {
  // The operation completed without error.
  OK = 0,
  // The open call for the tzdata file did not succeed.
  COULD_NOT_OPEN = -1,
  // The close call (after tzdata was loaded) did not succeed.
  COULD_NOT_CLOSE = -2,
};

// Adds a facility for introspecting timezone data errors.  Allows insight into
// the internal state of the VM even if error reporting facilities fail.
//
// Under normal operation, all metric values below should be zero.
class InspectMetrics {
 public:
  // Does not take ownership of inspector.
  explicit InspectMetrics(inspect::Inspector* inspector)
      : inspector_(inspector),
        root_(inspector_->GetRoot()),
        metrics_(root_.CreateChild("os")),
        dst_status_(metrics_.CreateInt("dst_status", kUninitialized)),
        tz_data_status_(metrics_.CreateInt("tz_data_status", kUninitialized)),
        tz_data_close_status_(
            metrics_.CreateInt("tz_data_close_status", kUninitialized)),
        get_profile_status_(
            metrics_.CreateInt("get_profile_status", kUninitialized)),
        profiles_timezone_content_status_(
            metrics_.CreateInt("timezone_content_status", kOk)) {}

  // Sets the last status code for DST offset calls.
  void SetDSTOffsetStatus(zx_status_t status) {
    dst_status_.Set(static_cast<int32_t>(status));
  }

  // Sets the return value of call to InitializeTZData, and the status of the
  // reported by close() on tzdata files.
  void SetInitTzData(TZDataStatus value, int32_t status) {
    tz_data_status_.Set(static_cast<int32_t>(value));
    tz_data_close_status_.Set(status);
  }

  // Sets the last status code for the call to PropertyProvider::GetProfile.
  void SetProfileStatus(zx_status_t status) {
    get_profile_status_.Set(static_cast<int32_t>(status));
  }

  // Sets the last status seen while examining timezones returned from
  // PropertyProvider::GetProfile.
  void SetTimeZoneContentStatus(zx_status_t status) {
    profiles_timezone_content_status_.Set(static_cast<int32_t>(status));
  }

 private:
  // The inspector that all metrics are being reported into.
  inspect::Inspector* inspector_;

  // References inspector_ state.
  inspect::Node& root_;

  // The OS metrics node.
  inspect::Node metrics_;

  // The status of the last GetTimeZoneOffset call.
  inspect::IntProperty dst_status_;

  // The status of the initialization.
  inspect::IntProperty tz_data_status_;

  // The return code for the close() call for tzdata files.
  inspect::IntProperty tz_data_close_status_;

  // The return code of the GetProfile call in GetTimeZoneName.  If this is
  // nonzero, then os_fuchsia.cc reported a default timezone as a fallback.
  inspect::IntProperty get_profile_status_;

  // U_ILLEGAL_ARGUMENT_ERROR(=1) if timezones read from ProfileProvider were
  // incorrect. Otherwise 0.  If this metric reports U_ILLEGAL_ARGUMENT_ERROR,
  // the os_fuchsia.cc module reported a default timezone as a fallback.
  inspect::IntProperty profiles_timezone_content_status_;
};

// Initialized on OS:Init(), deinitialized on OS::Cleanup.
std::unique_ptr<sys::ComponentInspector> component_inspector;
std::unique_ptr<InspectMetrics> metrics;

// Initializes the source of timezone data if available.  Timezone data file in
// Fuchsia is at a fixed directory path.  Returns true on success.
bool InitializeTZData() {
  ASSERT(metrics != nullptr);
  // Try opening the path to check if present.  No need to verify that it is a
  // directory since ICU loading will return an error if the TZ data path is
  // wrong.
  int fd = openat(AT_FDCWD, kICUTZDataDir, O_RDONLY);
  if (fd < 0) {
    metrics->SetInitTzData(TZDataStatus::COULD_NOT_OPEN, fd);
    return false;
  }
  // 0 == Not overwriting the env var if already set.
  setenv("ICU_TIMEZONE_FILES_DIR", kICUTZDataDir, 0);
  int32_t close_status = close(fd);
  if (close_status != 0) {
    metrics->SetInitTzData(TZDataStatus::COULD_NOT_CLOSE, close_status);
    return false;
  }
  metrics->SetInitTzData(TZDataStatus::OK, 0);
  return true;
}

}  // namespace

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
static const char kDefaultTimezone[] = "UTC";

// TODO(FL-98): Change this to talk to fuchsia.dart to get timezone service to
// directly get timezone.
//
// Putting this hack right now due to CP-120 as I need to remove
// component:ConnectToEnvironmentServices and this is the only thing that is
// blocking it and FL-98 will take time.
static fuchsia::intl::PropertyProviderSyncPtr property_provider;

static zx_status_t GetLocalAndDstOffsetInSeconds(int64_t seconds_since_epoch,
                                                 int32_t* local_offset,
                                                 int32_t* dst_offset) {
  const char* timezone_id = OS::GetTimeZoneName(seconds_since_epoch);
  std::unique_ptr<icu::TimeZone> timezone(
      icu::TimeZone::createTimeZone(timezone_id));
  UErrorCode error = U_ZERO_ERROR;
  const auto ms_since_epoch =
      static_cast<UDate>(kMsPerSec * seconds_since_epoch);
  // The units of time that local_offset and dst_offset are returned from this
  // function is, usefully, not documented, but it seems that the units are
  // milliseconds.  Add these variables here for clarity.
  int32_t local_offset_ms = 0;
  int32_t dst_offset_ms = 0;
  timezone->getOffset(ms_since_epoch, /*local_time=*/false, local_offset_ms,
                      dst_offset_ms, error);
  metrics->SetDSTOffsetStatus(error);
  if (error != U_ZERO_ERROR) {
    icu::ErrorCode icu_error;
    icu_error.set(error);
    Syslog::PrintErr("could not get DST offset: %s\n", icu_error.errorName());
    return ZX_ERR_INTERNAL;
  }
  // We must return offset in seconds, so convert.
  *local_offset = local_offset_ms / kMsPerSec;
  *dst_offset = dst_offset_ms / kMsPerSec;
  return ZX_OK;
}

const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  // TODO(abarth): Handle time zone changes.
  static const std::unique_ptr<std::string> tz_name =
      std::make_unique<std::string>([]() -> std::string {
        fuchsia::intl::Profile profile;
        const zx_status_t status = property_provider->GetProfile(&profile);
        metrics->SetProfileStatus(status);
        if (status != ZX_OK) {
          return kDefaultTimezone;
        }
        const std::vector<fuchsia::intl::TimeZoneId>& timezones =
            profile.time_zones();
        if (timezones.empty()) {
          metrics->SetTimeZoneContentStatus(U_ILLEGAL_ARGUMENT_ERROR);
          // Empty timezone array is not up to fuchsia::intl spec.  The serving
          // endpoint is broken and should be fixed.
          Syslog::PrintErr("got empty timezone value\n");
          return kDefaultTimezone;
        }
        return timezones[0].id;
      }());
  return tz_name->c_str();
}

int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  int32_t local_offset = 0;
  int32_t dst_offset = 0;
  const zx_status_t status = GetLocalAndDstOffsetInSeconds(
      seconds_since_epoch, &local_offset, &dst_offset);
  return status == ZX_OK ? local_offset + dst_offset : 0;
}

int OS::GetLocalTimeZoneAdjustmentInSeconds() {
  zx_time_t now = 0;
  zx_clock_get(ZX_CLOCK_UTC, &now);
  int32_t local_offset = 0;
  int32_t dst_offset = 0;
  const zx_status_t status = GetLocalAndDstOffsetInSeconds(
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
  const int64_t ticks = GetCurrentMonotonicTicks();
  ASSERT(GetCurrentMonotonicFrequency() == kNanosecondsPerSecond);
  return ticks / kNanosecondsPerMicrosecond;
}

int64_t OS::GetCurrentThreadCPUMicros() {
  zx_time_t now = 0;
  zx_clock_get(ZX_CLOCK_THREAD, &now);
  return now / kNanosecondsPerMicrosecond;
}

// On Fuchsia, thread timestamp values are not used in the tracing/timeline
// integration. Because of this, we try to avoid querying them, since doing so
// has both a runtime and trace buffer storage cost.
int64_t OS::GetCurrentThreadCPUMicrosForTimeline() {
  return -1;
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
  sys::ComponentContext* context = dart::ComponentContext();
  component_inspector = std::make_unique<sys::ComponentInspector>(context);
  metrics = std::make_unique<InspectMetrics>(component_inspector->inspector());

  InitializeTZData();
  auto services = sys::ServiceDirectory::CreateFromNamespace();
  services->Connect(property_provider.NewRequest());
}

void OS::Cleanup() {
  metrics = nullptr;
  component_inspector = nullptr;
}

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

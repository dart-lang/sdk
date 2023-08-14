// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_FUCHSIA)

#include "vm/os.h"

#include <dlfcn.h>
#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include <fuchsia/intl/cpp/fidl.h>
#include <lib/async-loop/default.h>
#include <lib/async-loop/loop.h>
#include <lib/async/default.h>
#include <lib/inspect/cpp/inspect.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/sys/inspect/cpp/component.h>
#include <zircon/process.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/threads.h>
#include <zircon/time.h>
#include <zircon/types.h>

#include <set>

#include "unicode/errorcode.h"
#include "unicode/timezone.h"
#include "unicode/umachine.h"

#include "platform/assert.h"
#include "platform/syslog.h"
#include "platform/utils.h"
#include "vm/image_snapshot.h"
#include "vm/lockers.h"
#include "vm/os_thread.h"
#include "vm/zone.h"

namespace {

using dart::Mutex;
using dart::MutexLocker;
using dart::Syslog;
using dart::Zone;

// This is the default timezone returned if it could not be obtained.  For
// Fuchsia, the default device timezone is always UTC.
static const char kDefaultTimezone[] = "UTC";

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
  // Takes ownership of the vm_node.
  explicit InspectMetrics(std::unique_ptr<inspect::Node> vm_node)
      : vm_node_(std::move(vm_node)),
        dst_status_(vm_node_->CreateInt("dst_status", kUninitialized)),
        tz_data_status_(vm_node_->CreateInt("tz_data_status", kUninitialized)),
        tz_data_close_status_(
            vm_node_->CreateInt("tz_data_close_status", kUninitialized)),
        get_profile_status_(
            vm_node_->CreateInt("get_profile_status", kUninitialized)),
        profiles_timezone_content_status_(
            vm_node_->CreateInt("timezone_content_status", kOk)),
        num_get_profile_calls_(vm_node_->CreateInt("num_get_profile_calls", 0)),
        num_on_change_calls_(vm_node_->CreateInt("num_on_change_calls", 0)),
        num_intl_provider_errors_(
            vm_node_->CreateInt("num_intl_provider_errors", 0)) {}

  // Registers a single call to GetProfile callback.
  void RegisterGetProfileCall() { num_get_profile_calls_.Add(1); }

  // Registers a single call to OnChange callback.
  void RegisterOnChangeCall() { num_on_change_calls_.Add(1); }

  // Registers a provider error.
  void RegisterIntlProviderError() { num_intl_provider_errors_.Add(1); }

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
  // The OS metrics node.
  std::unique_ptr<inspect::Node> vm_node_;

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

  // Keeps a number of get_profile update calls.
  inspect::IntProperty num_get_profile_calls_;

  // Number of "on change" callback calls.
  inspect::IntProperty num_on_change_calls_;

  // Keeps a number of errors encountered in intl provider.
  inspect::IntProperty num_intl_provider_errors_;
};

// Thread-safe storage for the current timezone name.
//
// Keeps an up to date timezone cache, updating if needed through the
// asynchronous update interface.  Access to this class is thread-safe.
class TimezoneName final {
 public:
  // Creates a new instance of TimezoneName.  Does not take ownership of
  // metrics.
  static std::shared_ptr<TimezoneName> New(
      fuchsia::intl::PropertyProviderPtr proxy,
      std::weak_ptr<InspectMetrics> metrics) {
    auto timezone_name =
        std::make_shared<TimezoneName>(std::move(proxy), metrics);
    timezone_name->InitHandlers(timezone_name);
    return timezone_name;
  }

  TimezoneName(fuchsia::intl::PropertyProviderPtr proxy,
               std::weak_ptr<InspectMetrics> metrics)
      : m_(),
        metrics_(std::move(metrics)),
        proxy_(std::move(proxy)),
        timezone_name_(kDefaultTimezone) {
    ASSERT(metrics_.lock() != nullptr);
  }

  // Gets the current timezone name.  Repeated calls may retrieve updated
  // values.
  std::string Get() const {
    MutexLocker lock(&m_);
    // Returns a copy, to avoid a data race with async updates.
    return timezone_name_;
  }

 private:
  // Sets the event handlers in this resolver.  Intended to resolve a circular
  // reference between the shared timezone name and this.
  void InitHandlers(std::shared_ptr<TimezoneName> timezone_name) {
    ASSERT(timezone_name.get() == this);
    timezone_name->proxy_.set_error_handler(
        [weak_this =
             std::weak_ptr<TimezoneName>(timezone_name)](zx_status_t status) {
          if (!weak_this.expired()) {
            weak_this.lock()->ErrorHandler(status);
          }
        });
    timezone_name->proxy_.events().OnChange =
        [weak_this = std::weak_ptr<TimezoneName>(timezone_name)]() {
          if (!weak_this.expired()) {
            weak_this.lock()->OnChangeCallback();
          }
        };
    timezone_name->proxy_->GetProfile(
        [weak_this = std::weak_ptr<TimezoneName>(timezone_name)](
            fuchsia::intl::Profile profile) {
          if (!weak_this.expired()) {
            weak_this.lock()->GetProfileCallback(std::move(profile));
          }
        });
  }

  // Called on a profile provider error in the context of the event loop
  // thread.
  void ErrorHandler(zx_status_t status) {
    MutexLocker lock(&m_);
    WithMetrics([status](std::shared_ptr<InspectMetrics> metrics) {
      metrics->SetProfileStatus(status);
      metrics->RegisterIntlProviderError();
    });
  }

  // Called when an OnChange event is received in the context of the event loop
  // thread.  The only action here is to trigger an asynchronous update of the
  // intl profile.
  void OnChangeCallback() {
    MutexLocker lock(&m_);
    WithMetrics([](std::shared_ptr<InspectMetrics> metrics) {
      metrics->RegisterOnChangeCall();
    });
    proxy_->GetProfile([this](fuchsia::intl::Profile profile) {
      this->GetProfileCallback(std::move(profile));
    });
  }

  // Called when a GetProfile async request is resolved, in the context of the
  // event loop thread.
  void GetProfileCallback(fuchsia::intl::Profile profile) {
    MutexLocker lock(&m_);
    WithMetrics([](std::shared_ptr<InspectMetrics> metrics) {
      metrics->RegisterGetProfileCall();
    });
    const std::vector<fuchsia::intl::TimeZoneId>& timezones =
        profile.time_zones();
    if (timezones.empty()) {
      WithMetrics([](std::shared_ptr<InspectMetrics> metrics) {
        metrics->SetTimeZoneContentStatus(U_ILLEGAL_ARGUMENT_ERROR);
      });
      // Empty timezone array is not up to fuchsia::intl spec.  The serving
      // endpoint is broken and should be fixed.
      Syslog::PrintErr("got empty timezone value\n");
      return;
    }
    WithMetrics([](std::shared_ptr<InspectMetrics> metrics) {
      metrics->SetProfileStatus(ZX_OK);
      metrics->SetTimeZoneContentStatus(ZX_OK);
    });

    timezone_name_ = timezones[0].id;
  }

  // Runs the provided function only on valid metrics.
  void WithMetrics(std::function<void(std::shared_ptr<InspectMetrics> m)> f) {
    std::shared_ptr<InspectMetrics> l = metrics_.lock();
    if (l != nullptr) {
      f(l);
    }
  }

  // Guards timezone_name_ because the callbacks will be called in an
  // asynchronous thread.
  mutable Mutex m_;

  // Used to keep tally on the update events. Not owned.
  std::weak_ptr<InspectMetrics> metrics_;

  // A client-side proxy for a connection to the property provider service.
  fuchsia::intl::PropertyProviderPtr proxy_;

  // Caches the current timezone name.  This is updated asynchronously through
  // GetProfileCallback.
  std::string timezone_name_;
};

// The timezone names encountered so far.  The timezone names must live forever.
std::set<std::string> timezone_names;

// Initialized on OS:Init(), deinitialized on OS::Cleanup.
std::shared_ptr<InspectMetrics> metrics;
std::shared_ptr<TimezoneName> timezone_name;
async_loop_t* message_loop = nullptr;

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

int64_t GetCurrentTimeNanos() {
  struct timespec ts;
  if (timespec_get(&ts, TIME_UTC) == 0) {
    FATAL("timespec_get failed");
    return 0;
  }
  return zx_time_add_duration(ZX_SEC(ts.tv_sec), ZX_NSEC(ts.tv_nsec));
}

}  // namespace

namespace dart {

#ifndef PRODUCT

DEFINE_FLAG(bool,
            generate_perf_events_symbols,
            false,
            "Generate events symbols for profiling with perf");

#endif  // !PRODUCT

intptr_t OS::ProcessId() {
  return static_cast<intptr_t>(getpid());
}

// TODO(FL-98): Change this to talk to fuchsia.dart to get timezone service to
// directly get timezone.
//
// Putting this hack right now due to CP-120 as I need to remove
// component:ConnectToEnvironmentServices and this is the only thing that is
// blocking it and FL-98 will take time.
static fuchsia::intl::PropertyProviderPtr property_provider;

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
  timezone->getOffset(ms_since_epoch, /*local_time=*/0, local_offset_ms,
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

// Returns a C string with the time zone name. This module retains the
// ownership of the pointer.
const char* OS::GetTimeZoneName(int64_t seconds_since_epoch) {
  ASSERT(timezone_name != nullptr);

  // Sadly, since we do not know how long the timezone name will be needed, we
  // can not ever deallocate it. So instead, we put it into a a set that will
  // not move it around in memory and return a pointer to it.  Since the number
  // of timezones is finite, this ensures that the memory taken up by timezones
  // does not grow indefinitely, even if we end up retaining all the timezones
  // there are.
  const auto i = timezone_names.insert(timezone_name->Get());
  ASSERT(i.first != timezone_names.end());
  return i.first->c_str();
}

int OS::GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch) {
  int32_t local_offset = 0;
  int32_t dst_offset = 0;
  const zx_status_t status = GetLocalAndDstOffsetInSeconds(
      seconds_since_epoch, &local_offset, &dst_offset);
  return status == ZX_OK ? local_offset + dst_offset : 0;
}

int64_t OS::GetCurrentTimeMillis() {
  return GetCurrentTimeNanos() / ZX_MSEC(1);
}

int64_t OS::GetCurrentTimeMicros() {
  return GetCurrentTimeNanos() / ZX_USEC(1);
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
  zx_info_thread_stats_t info = {};
  zx_status_t status = zx_object_get_info(thrd_get_zx_handle(thrd_current()),
                                          ZX_INFO_THREAD_STATS, &info,
                                          sizeof(info), nullptr, nullptr);
  return status == ZX_OK ? info.total_runtime / kNanosecondsPerMicrosecond : 0;
}

int64_t OS::GetCurrentMonotonicMicrosForTimeline() {
#if defined(SUPPORT_TIMELINE)
  return OS::GetCurrentMonotonicMicros();
#else
  return -1;
#endif
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
  intptr_t len = Utils::VSNPrint(nullptr, 0, format, measure_args);
  va_end(measure_args);

  char* buffer;
  if (zone != nullptr) {
    buffer = zone->Alloc<char>(len + 1);
  } else {
    buffer = reinterpret_cast<char*>(malloc(len + 1));
  }
  ASSERT(buffer != nullptr);

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  Utils::VSNPrint(buffer, len + 1, format, print_args);
  va_end(print_args);
  return buffer;
}

bool OS::StringToInt64(const char* str, int64_t* value) {
  ASSERT(str != nullptr && strlen(str) > 0 && value != nullptr);
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
  if (async_get_default_dispatcher() == nullptr) {
    async_loop_create(&kAsyncLoopConfigAttachToCurrentThread, &message_loop);
    async_set_default_dispatcher(async_loop_get_dispatcher(message_loop));
    async_loop_start_thread(message_loop, "Fuchsia async loop", nullptr);
  }

  auto vm_node = dart::TakeDartVmNode();

  // TODO(fxbug.dev/69558) allow vm_node to be null and not crash
  ASSERT(vm_node != nullptr);
  metrics = std::make_shared<InspectMetrics>(std::move(vm_node));

  InitializeTZData();
  auto services = sys::ServiceDirectory::CreateFromNamespace();
  services->Connect(property_provider.NewRequest());

  timezone_name = TimezoneName::New(std::move(property_provider), metrics);
}

void OS::Cleanup() {
  if (message_loop != nullptr) {
    async_loop_shutdown(message_loop);
  }
  timezone_name.reset();
  metrics.reset();

  if (message_loop != nullptr) {
    // Check message_loop is still the default dispatcher before clearing it.
    if (async_get_default_dispatcher() ==
        async_loop_get_dispatcher(message_loop)) {
      async_set_default_dispatcher(nullptr);
    }
    async_loop_destroy(message_loop);
    message_loop = nullptr;
  }
}

void OS::PrepareToAbort() {}

void OS::Abort() {
  PrepareToAbort();
  abort();
}

void OS::Exit(int code) {
  exit(code);
}

// Used to choose between Elf32/Elf64 types based on host archotecture bitsize.
#if defined(ARCH_IS_64_BIT)
#define ElfW(Type) Elf64_##Type
#else
#define ElfW(Type) Elf32_##Type
#endif

OS::BuildId OS::GetAppBuildId(const uint8_t* snapshot_instructions) {
  // First return the build ID information from the instructions image if
  // available.
  const Image instructions_image(snapshot_instructions);
  if (auto* const image_build_id = instructions_image.build_id()) {
    return {instructions_image.build_id_length(), image_build_id};
  }
  Dl_info snapshot_info;
  if (dladdr(snapshot_instructions, &snapshot_info) == 0) {
    return {0, nullptr};
  }
  const uint8_t* dso_base =
      static_cast<const uint8_t*>(snapshot_info.dli_fbase);
  const ElfW(Ehdr)& elf_header = *reinterpret_cast<const ElfW(Ehdr)*>(dso_base);
  const ElfW(Phdr)* const phdr_array =
      reinterpret_cast<const ElfW(Phdr)*>(dso_base + elf_header.e_phoff);
  for (intptr_t i = 0; i < elf_header.e_phnum; i++) {
    const ElfW(Phdr)& header = phdr_array[i];
    if (header.p_type != PT_NOTE) continue;
    if ((header.p_flags & PF_R) != PF_R) continue;
    const uint8_t* const note_addr = dso_base + header.p_vaddr;
    const Elf32_Nhdr& note_header =
        *reinterpret_cast<const Elf32_Nhdr*>(note_addr);
    if (note_header.n_type != NT_GNU_BUILD_ID) continue;
    const char* const note_contents =
        reinterpret_cast<const char*>(note_addr + sizeof(Elf32_Nhdr));
    // The note name contains the null terminator as well.
    if (note_header.n_namesz != strlen(ELF_NOTE_GNU) + 1) continue;
    if (strncmp(ELF_NOTE_GNU, note_contents, note_header.n_namesz) == 0) {
      return {static_cast<intptr_t>(note_header.n_descsz),
              reinterpret_cast<const uint8_t*>(note_contents +
                                               note_header.n_namesz)};
    }
  }
  return {0, nullptr};
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA)

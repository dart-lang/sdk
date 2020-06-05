// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_LINUX)

#include "vm/os.h"

#include <errno.h>         // NOLINT
#include <fcntl.h>         // NOLINT
#include <limits.h>        // NOLINT
#include <malloc.h>        // NOLINT
#include <sys/mman.h>      // NOLINT
#include <sys/resource.h>  // NOLINT
#include <sys/stat.h>      // NOLINT
#include <sys/syscall.h>   // NOLINT
#include <sys/time.h>      // NOLINT
#include <sys/types.h>     // NOLINT
#include <time.h>          // NOLINT
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
            "Generate events symbols for profiling with perf (disables dual "
            "code mapping)");

DEFINE_FLAG(bool,
            generate_perf_jitdump,
            false,
            "Generate jitdump file to use with perf-inject (disables dual code "
            "mapping)");

DECLARE_FLAG(bool, write_protect_code);
DECLARE_FLAG(bool, write_protect_vm_isolate);
#if !defined(DART_PRECOMPILED_RUNTIME)
DECLARE_FLAG(bool, code_comments);
#endif

// Linux CodeObservers.

// Simple perf support: generate /tmp/perf-<pid>.map file that maps
// memory ranges to symbol names for JIT generated code. This allows
// perf-report to resolve addresses falling into JIT generated code.
// However perf-annotate does not work in this mode because JIT code
// is transient and does not exist anymore at the moment when you
// invoke perf-report.
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
                      bool optimized,
                      const CodeComments* comments) {
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

// Code observer that generates a JITDUMP[1] file that can be interpreted by
// perf-inject to generate ELF images for JIT generated code objects, which
// allows both perf-report and perf-annotate to recognize them.
//
// Usage:
//
//   $ perf record -k mono dart --generate-perf-jitdump benchmark.dart
//   $ perf inject -j -i perf.data -o perf.data.jitted
//   $ perf report -i perf.data.jitted
//
// [1] see linux/tools/perf/Documentation/jitdump-specification.txt for
//     JITDUMP binary format.
class JitDumpCodeObserver : public CodeObserver {
 public:
  JitDumpCodeObserver() : pid_(getpid()) {
    char* const filename = OS::SCreate(nullptr, "/tmp/jit-%" Pd ".dump", pid_);
    const int fd = open(filename, O_CREAT | O_TRUNC | O_RDWR, 0666);
    free(filename);

    if (fd == -1) {
      return;
    }

    // Map JITDUMP file, this mapping will be recorded by perf. This allows
    // perf-inject to find this file later.
    const long page_size = sysconf(_SC_PAGESIZE);  // NOLINT(runtime/int)
    if (page_size == -1) {
      close(fd);
      return;
    }

    mapped_ =
        mmap(nullptr, page_size, PROT_READ | PROT_EXEC, MAP_PRIVATE, fd, 0);
    if (mapped_ == nullptr) {
      close(fd);
      return;
    }
    mapped_size_ = page_size;

    out_file_ = fdopen(fd, "w+");
    if (out_file_ == nullptr) {
      close(fd);
      return;
    }

    // Buffer the output to avoid high IO overheads - we are going to be
    // writing all JIT generated code out.
    setvbuf(out_file_, nullptr, _IOFBF, 2 * MB);

    // Disable code write protection and vm isolate write protection, because
    // calling mprotect on the pages filled with JIT generated code objects
    // confuses perf.
    FLAG_write_protect_code = false;
    FLAG_write_protect_vm_isolate = false;

#if !defined(DART_PRECOMPILED_RUNTIME)
    // Enable code comments.
    FLAG_code_comments = true;
#endif

    // Write JITDUMP header.
    WriteHeader();
  }

  ~JitDumpCodeObserver() {
    if (mapped_ != nullptr) {
      munmap(mapped_, mapped_size_);
      mapped_ = nullptr;
    }

    if (out_file_ != nullptr) {
      fclose(out_file_);
      out_file_ = nullptr;
    }
  }

  virtual bool IsActive() const {
    return FLAG_generate_perf_jitdump && (out_file_ != nullptr);
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized,
                      const CodeComments* comments) {
    MutexLocker ml(CodeObservers::mutex());

    const char* marker = optimized ? "*" : "";
    char* buffer = OS::SCreate(Thread::Current()->zone(), "%s%s", marker, name);
    const size_t name_length = strlen(buffer);

    WriteDebugInfo(base, comments);

    CodeLoadEvent ev;
    ev.event = BaseEvent::kLoad;
    ev.size = sizeof(ev) + (name_length + 1) + size;
    ev.time_stamp = OS::GetCurrentMonotonicTicks();
    ev.process_id = getpid();
    ev.thread_id = syscall(SYS_gettid);
    ev.vma = base;
    ev.code_address = base;
    ev.code_size = size;
    ev.code_id = code_id_++;

    WriteFully(&ev, sizeof(ev));
    WriteFully(buffer, name_length + 1);
    WriteFully(reinterpret_cast<void*>(base), size);
  }

 private:
  struct Header {
    const uint32_t magic = 0x4A695444;
    const uint32_t version = 1;
    const uint32_t size = sizeof(Header);
    uint32_t elf_mach_target;
    const uint32_t reserved = 0xDEADBEEF;
    uint32_t process_id;
    uint64_t time_stamp;
    const uint64_t flags = 0;
  };

  struct BaseEvent {
    enum Event {
      kLoad = 0,
      kMove = 1,
      kDebugInfo = 2,
      kClose = 3,
      kUnwindingInfo = 4
    };

    uint32_t event;
    uint32_t size;
    uint64_t time_stamp;
  };

  struct CodeLoadEvent : BaseEvent {
    uint32_t process_id;
    uint32_t thread_id;
    uint64_t vma;
    uint64_t code_address;
    uint64_t code_size;
    uint64_t code_id;
  };

  struct DebugInfoEvent : BaseEvent {
    uint64_t address;
    uint64_t entry_count;
    // DebugInfoEntry entries[entry_count_];
  };

  struct DebugInfoEntry {
    uint64_t address;
    int32_t line_number;
    int32_t column;
    // Followed by nul-terminated name.
  };

  // ELF machine architectures
  // From linux/include/uapi/linux/elf-em.h
  static const uint32_t EM_386 = 3;
  static const uint32_t EM_X86_64 = 62;
  static const uint32_t EM_ARM = 40;
  static const uint32_t EM_AARCH64 = 183;

  static uint32_t GetElfMachineArchitecture() {
#if TARGET_ARCH_IA32
    return EM_386;
#elif TARGET_ARCH_X64
    return EM_X86_64;
#elif TARGET_ARCH_ARM
    return EM_ARM;
#elif TARGET_ARCH_ARM64
    return EM_AARCH64;
#else
    UNREACHABLE();
    return 0;
#endif
  }

#if ARCH_IS_64_BIT
  static const int kElfHeaderSize = 0x40;
#else
  static const int kElfHeaderSize = 0x34;
#endif

  void WriteDebugInfo(uword base, const CodeComments* comments) {
    if (comments == nullptr || comments->Length() == 0) {
      return;
    }

    // Open the comments file for the given code object.
    // Note: for some reason we can't emit all comments into a single file
    // the mapping between PCs and lines goes out of sync (might be
    // perf-annotate bug).
    char* comments_file_name =
        OS::SCreate(nullptr, "/tmp/jit-%" Pd "-%" Pd ".cmts", pid_, code_id_);
    const intptr_t filename_length = strlen(comments_file_name);
    FILE* comments_file = fopen(comments_file_name, "w");
    setvbuf(comments_file, nullptr, _IOFBF, 2 * MB);

    // Count the number of DebugInfoEntry we are going to emit: one
    // per PC.
    intptr_t entry_count = 0;
    for (uint64_t i = 0, len = comments->Length(); i < len;) {
      const intptr_t pc_offset = comments->PCOffsetAt(i);
      while (i < len && comments->PCOffsetAt(i) == pc_offset) {
        i++;
      }
      entry_count++;
    }

    DebugInfoEvent info;
    info.event = BaseEvent::kDebugInfo;
    info.time_stamp = OS::GetCurrentMonotonicTicks();
    info.address = base;
    info.entry_count = entry_count;
    info.size = sizeof(info) +
                entry_count * (sizeof(DebugInfoEntry) + filename_length + 1);
    const int32_t padding = Utils::RoundUp(info.size, 8) - info.size;
    info.size += padding;

    // Write out DebugInfoEvent record followed by entry_count DebugInfoEntry
    // records.
    WriteFully(&info, sizeof(info));
    intptr_t line_number = 0;  // Line number within comments_file.
    for (intptr_t i = 0, len = comments->Length(); i < len;) {
      const intptr_t pc_offset = comments->PCOffsetAt(i);
      while (i < len && comments->PCOffsetAt(i) == pc_offset) {
        line_number += WriteLn(comments_file, comments->CommentAt(i));
        i++;
      }
      DebugInfoEntry entry;
      entry.address = base + pc_offset + kElfHeaderSize;
      entry.line_number = line_number;
      entry.column = 0;
      WriteFully(&entry, sizeof(entry));
      WriteFully(comments_file_name, filename_length + 1);
    }

    // Write out the padding.
    const char padding_bytes[8] = {0};
    WriteFully(padding_bytes, padding);

    fclose(comments_file);
    free(comments_file_name);
  }

  void WriteHeader() {
    Header header;
    header.elf_mach_target = GetElfMachineArchitecture();
    header.process_id = getpid();
    header.time_stamp = OS::GetCurrentTimeMicros();
    WriteFully(&header, sizeof(header));
  }

  // Returns number of new-lines written.
  intptr_t WriteLn(FILE* f, const char* comment) {
    fputs(comment, f);
    fputc('\n', f);

    intptr_t line_count = 1;
    while ((comment = strstr(comment, "\n")) != nullptr) {
      line_count++;
    }
    return line_count;
  }

  void WriteFully(const void* buffer, size_t size) {
    const char* ptr = static_cast<const char*>(buffer);
    while (size > 0) {
      const size_t written = fwrite(ptr, 1, size, out_file_);
      if (written == 0) {
        UNREACHABLE();
        break;
      }
      size -= written;
      ptr += written;
    }
  }

  const intptr_t pid_;

  FILE* out_file_ = nullptr;
  void* mapped_ = nullptr;
  long mapped_size_ = 0;  // NOLINT(runtime/int)

  intptr_t code_id_ = 0;

  DISALLOW_COPY_AND_ASSIGN(JitDumpCodeObserver);
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

int64_t OS::GetCurrentThreadCPUMicrosForTimeline() {
  return OS::GetCurrentThreadCPUMicros();
}

// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_linux.cc
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

// TODO(regis): Function called only from the simulator.
void OS::DebugBreak() {
  __builtin_trap();
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
  if (zone != nullptr) {
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
    CodeObservers::Register(new PerfCodeObserver);
  }

  if (FLAG_generate_perf_jitdump) {
    CodeObservers::Register(new JitDumpCodeObserver);
  }
#endif  // !PRODUCT
}

void OS::PrintErr(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VFPrint(stderr, format, args);
  va_end(args);
}

void OS::Init() {}

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

#endif  // defined(HOST_OS_LINUX)

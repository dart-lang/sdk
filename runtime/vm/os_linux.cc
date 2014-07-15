// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_LINUX)

#include "vm/os.h"

#include <errno.h>  // NOLINT
#include <limits.h>  // NOLINT
#include <malloc.h>  // NOLINT
#include <time.h>  // NOLINT
#include <sys/resource.h>  // NOLINT
#include <sys/time.h>  // NOLINT
#include <sys/types.h>  // NOLINT
#include <sys/syscall.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "platform/utils.h"
#include "vm/code_observers.h"
#include "vm/dart.h"
#include "vm/debuginfo.h"
#include "vm/isolate.h"
#include "vm/thread.h"
#include "vm/vtune.h"
#include "vm/zone.h"


namespace dart {

// Linux CodeObservers.

DEFINE_FLAG(bool, generate_gdb_symbols, false,
    "Generate symbols of generated dart functions for debugging with GDB");
DEFINE_FLAG(bool, generate_perf_events_symbols, false,
    "Generate events symbols for profiling with perf");
DEFINE_FLAG(bool, generate_perf_jitdump, false,
    "Writes jitdump data for profiling with perf annotate");


class PerfCodeObserver : public CodeObserver {
 public:
  PerfCodeObserver() : out_file_(NULL) {
    Dart_FileOpenCallback file_open = Isolate::file_open_callback();
    if (file_open == NULL) {
      return;
    }
    const char* format = "/tmp/perf-%" Pd ".map";
    intptr_t pid = getpid();
    intptr_t len = OS::SNPrint(NULL, 0, format, pid);
    char* filename = new char[len + 1];
    OS::SNPrint(filename, len + 1, format, pid);
    out_file_ = (*file_open)(filename, true);
    delete[] filename;
  }

  ~PerfCodeObserver() {
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
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
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    if ((file_write == NULL) || (out_file_ == NULL)) {
      return;
    }
    const char* format = "%" Px " %" Px " %s%s\n";
    const char* marker = optimized ? "*" : "";
    intptr_t len = OS::SNPrint(NULL, 0, format, base, size, marker, name);
    char* buffer = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(buffer, len + 1, format, base, size, marker, name);
    {
      MutexLocker ml(CodeObservers::mutex());
      (*file_write)(buffer, len, out_file_);
    }
  }

 private:
  void* out_file_;

  DISALLOW_COPY_AND_ASSIGN(PerfCodeObserver);
};


class GdbCodeObserver : public CodeObserver {
 public:
  GdbCodeObserver() { }

  virtual bool IsActive() const {
    return FLAG_generate_gdb_symbols;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    if (prologue_offset > 0) {
      // In order to ensure that gdb sees the first instruction of a function
      // as the prologue sequence we register two symbols for the cases when
      // the prologue sequence is not the first instruction:
      // <name>_entry is used for code preceding the prologue sequence.
      // <name> for rest of the code (first instruction is prologue sequence).
      const char* kFormat = "%s_%s";
      intptr_t len = OS::SNPrint(NULL, 0, kFormat, name, "entry");
      char* pname = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
      OS::SNPrint(pname, (len + 1), kFormat, name, "entry");
      DebugInfo::RegisterSection(pname, base, size);
      DebugInfo::RegisterSection(name,
                                 (base + prologue_offset),
                                 (size - prologue_offset));
    } else {
      DebugInfo::RegisterSection(name, base, size);
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(GdbCodeObserver);
};


#define CLOCKFD 3
#define FD_TO_CLOCKID(fd)       ((~(clockid_t) (fd) << 3) | CLOCKFD)  // NOLINT

class JitdumpCodeObserver : public CodeObserver {
 public:
  JitdumpCodeObserver() {
    ASSERT(FLAG_generate_perf_jitdump);
    out_file_ = NULL;
    clock_fd_ = -1;
    clock_id_ = kInvalidClockId;
    code_sequence_ = 0;
    Dart_FileOpenCallback file_open = Isolate::file_open_callback();
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
    if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
      return;
    }
    // The Jitdump code observer writes all jitted code into
    // /tmp/jit-<pid>.dump, we open the file once on initialization and close
    // it when the VM is going down.
    {
      // Open the file.
      const char* format = "/tmp/jit-%" Pd ".dump";
      intptr_t pid = getpid();
      intptr_t len = OS::SNPrint(NULL, 0, format, pid);
      char* filename = new char[len + 1];
      OS::SNPrint(filename, len + 1, format, pid);
      out_file_ = (*file_open)(filename, true);
      ASSERT(out_file_ != NULL);
      // Write the jit dump header.
      WriteHeader();
    }
    // perf uses an internal clock and because our output is merged with data
    // collected by perf our timestamps must be consistent. Using
    // the posix-clock-module (/dev/trace_clock) as our time source ensures
    // we are consistent with the perf timestamps.
    clock_id_ = kInvalidClockId;
    clock_fd_ = open("/dev/trace_clock", O_RDONLY);
    if (clock_fd_ >= 0) {
      clock_id_ = FD_TO_CLOCKID(clock_fd_);
    }
  }

  ~JitdumpCodeObserver() {
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
    if (file_close == NULL) {
      return;
    }
    ASSERT(out_file_ != NULL);
    (*file_close)(out_file_);
    if (clock_fd_ >= 0) {
      close(clock_fd_);
    }
  }

  virtual bool IsActive() const {
    return FLAG_generate_perf_jitdump && (out_file_ != NULL);
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    WriteCodeLoad(name, base, prologue_offset, size, optimized);
  }

 private:
  static const uint32_t kJitHeaderMagic = 0x4F74496A;
  static const uint32_t kJitHeaderVersion = 0x2;
  static const uint32_t kElfMachIA32 = 3;
  static const uint32_t kElfMachX64 = 62;
  static const uint32_t kElfMachARM = 40;
  // TODO(zra): Find the right ARM64 constant.
  static const uint32_t kElfMachARM64 = 40;
  static const uint32_t kElfMachMIPS = 10;
  static const int kInvalidClockId = -1;

  struct jitheader {
    uint32_t magic;
    uint32_t version;
    uint32_t total_size;
    uint32_t elf_mach;
    uint32_t pad1;
    uint32_t pid;
    uint64_t timestamp;
  };

  enum jit_record_type {
    JIT_CODE_LOAD = 0,
    /* JIT_CODE_UNLOAD = 1, */
    /* JIT_CODE_CLOSE = 2, */
    /* JIT_CODE_DEBUG_INFO = 3, */
    JIT_CODE_MAX = 4,
  };

  struct jr_code_load {
    uint32_t id;
    uint32_t total_size;
    uint64_t timestamp;
    uint32_t pid;
    uint32_t tid;
    uint64_t vma;
    uint64_t code_addr;
    uint32_t code_size;
    uint64_t code_index;
    uint32_t align;
  };

  const char* GenerateCodeName(const char* name, bool optimized) {
    const char* format = "%s%s";
    const char* marker = optimized ? "*" : "";
    intptr_t len = OS::SNPrint(NULL, 0, format, marker, name);
    char* buffer = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(buffer, len + 1, format, marker, name);
    return buffer;
  }

  uint32_t GetElfMach() {
#if defined(TARGET_ARCH_IA32)
    return kElfMachIA32;
#elif defined(TARGET_ARCH_X64)
    return kElfMachX64;
#elif defined(TARGET_ARCH_ARM)
    return kElfMachARM;
#elif defined(TARGET_ARCH_ARM64)
    return kElfMachARM64;
#elif defined(TARGET_ARCH_MIPS)
    return kElfMachMIPS;
#else
#error Unknown architecture.
#endif
  }

  pid_t gettid() {
    // libc doesn't wrap the Linux-specific gettid system call.
    // Note that this thread id is not the same as the posix thread id.
    return syscall(SYS_gettid);
  }

  uint64_t GetKernelTimeNanos() {
    if (clock_id_ != kInvalidClockId) {
      struct timespec ts;
      int r = clock_gettime(clock_id_, &ts);
      ASSERT(r == 0);
      uint64_t nanos = static_cast<uint64_t>(ts.tv_sec) *
                       static_cast<uint64_t>(kNanosecondsPerSecond);
      nanos += static_cast<uint64_t>(ts.tv_nsec);
      return nanos;
    } else {
      return OS::GetCurrentTimeMicros() * kNanosecondsPerMicrosecond;
    }
  }

  void WriteHeader() {
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    ASSERT(file_write != NULL);
    ASSERT(out_file_ != NULL);
    jitheader header;
    header.magic = kJitHeaderMagic;
    header.version = kJitHeaderVersion;
    header.total_size = sizeof(jitheader);
    header.pad1 = 0xdeadbeef;
    header.elf_mach = GetElfMach();
    header.pid = getpid();
    header.timestamp = GetKernelTimeNanos();
    {
      MutexLocker ml(CodeObservers::mutex());
      (*file_write)(&header, sizeof(header), out_file_);
    }
  }

  void WriteCodeLoad(const char* name, uword base, uword prologue_offset,
                     uword code_size, bool optimized) {
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    ASSERT(file_write != NULL);
    ASSERT(out_file_ != NULL);

    const char* code_name = GenerateCodeName(name, optimized);
    const intptr_t code_name_size = strlen(code_name) + 1;
    uint8_t* code_pointer = reinterpret_cast<uint8_t*>(base);

    jr_code_load code_load;
    code_load.id = JIT_CODE_LOAD;
    code_load.total_size = sizeof(code_load) + code_name_size + code_size;
    code_load.timestamp = GetKernelTimeNanos();
    code_load.pid = getpid();
    code_load.tid = gettid();
    code_load.vma = 0x0;  //  Our addresses are absolute.
    code_load.code_addr = base;
    code_load.code_size = code_size;
    code_load.align = OS::PreferredCodeAlignment();

    {
      MutexLocker ml(CodeObservers::mutex());
      // Set this field under the index.
      code_load.code_index = code_sequence_++;
      // Write structures.
      (*file_write)(&code_load, sizeof(code_load), out_file_);
      (*file_write)(code_name, code_name_size, out_file_);
      (*file_write)(code_pointer, code_size, out_file_);
    }
  }

  void* out_file_;
  int clock_fd_;
  int clock_id_;
  uint64_t code_sequence_;
  DISALLOW_COPY_AND_ASSIGN(JitdumpCodeObserver);
};


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


void* OS::AlignedAllocate(intptr_t size, intptr_t alignment) {
  const int kMinimumAlignment = 16;
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  void* p = memalign(alignment, size);
  if (p == NULL) {
    UNREACHABLE();
  }
  return p;
}


void OS::AlignedFree(void* ptr) {
  free(ptr);
}


// TODO(5411554):  May need to hoist these architecture dependent code
// into a architecture specific file e.g: os_ia32_linux.cc
word OS::ActivationFrameAlignment() {
#if defined(TARGET_ARCH_IA32) ||                                               \
    defined(TARGET_ARCH_X64) ||                                                \
    defined(TARGET_ARCH_ARM64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
  const int kMinimumAlignment = 8;
#else
#error Unsupported architecture.
#endif
  word alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default stack alignment for
  // testing purposes.
  // Flags::DebugIsInt("stackalign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  return alignment;
}


word OS::PreferredCodeAlignment() {
#if defined(TARGET_ARCH_IA32) ||                                               \
    defined(TARGET_ARCH_X64) ||                                                \
    defined(TARGET_ARCH_ARM64)
  const int kMinimumAlignment = 32;
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
  const int kMinimumAlignment = 16;
#else
#error Unsupported architecture.
#endif
  word alignment = kMinimumAlignment;
  // TODO(5411554): Allow overriding default code alignment for
  // testing purposes.
  // Flags::DebugIsInt("codealign", &alignment);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(alignment >= kMinimumAlignment);
  ASSERT(alignment <= OS::kMaxPreferredCodeAlignment);
  return alignment;
}


uword OS::GetStackSizeLimit() {
  struct rlimit stack_limit;
  int retval = getrlimit(RLIMIT_STACK, &stack_limit);
  ASSERT(retval == 0);
  if (stack_limit.rlim_cur > INT_MAX) {
    retval = INT_MAX;
  } else {
    retval = stack_limit.rlim_cur;
  }
  return retval;
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


void OS::DebugBreak() {
#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_IA32)
  asm("int $3");
#elif defined(HOST_ARCH_ARM)
  asm("svc #0x9f0001");  // __ARM_NR_breakpoint
#elif defined(HOST_ARCH_MIPS) || defined(HOST_ARCH_ARM64)
  UNIMPLEMENTED();
#else
#error Unsupported architecture.
#endif
}


char* OS::StrNDup(const char* s, intptr_t n) {
  return strndup(s, n);
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
  int retval = vsnprintf(str, size, format, args);
  if (retval < 0) {
    FATAL1("Fatal error in OS::VSNPrint with format '%s'", format);
  }
  return retval;
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
  if (FLAG_generate_perf_events_symbols) {
    CodeObservers::Register(new PerfCodeObserver);
  }
  if (FLAG_generate_gdb_symbols) {
    CodeObservers::Register(new GdbCodeObserver);
  }
  if (FLAG_generate_perf_jitdump) {
    CodeObservers::Register(new JitdumpCodeObserver);
  }
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

#endif  // defined(TARGET_OS_LINUX)

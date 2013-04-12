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
#include <unistd.h>  // NOLINT

#include "platform/utils.h"
#include "vm/code_observers.h"
#include "vm/dart.h"
#include "vm/debuginfo.h"
#include "vm/isolate.h"
#include "vm/vtune.h"
#include "vm/zone.h"


namespace dart {

// Linux CodeObservers.

DEFINE_FLAG(bool, generate_gdb_symbols, false,
    "Generate symbols of generated dart functions for debugging with GDB");
DEFINE_FLAG(bool, generate_perf_events_symbols, false,
    "Generate events symbols for profiling with perf");
DEFINE_FLAG(bool, ll_prof, false,
    "Generate compiled code log file for processing with ll_prof.py.");
DEFINE_FLAG(charp, generate_pprof_symbols, NULL,
    "Writes pprof events symbols to the provided file");

class LowLevelProfileCodeObserver : public CodeObserver {
 public:
  LowLevelProfileCodeObserver() {
    Dart_FileOpenCallback file_open = Isolate::file_open_callback();
    if (file_open == NULL) {
      return;
    }
    const char* filename = "v8.log.ll";
    log_file_ = (*file_open)(filename);
#if defined(TARGET_ARCH_IA32)
    const char arch[] = "ia32";
#elif defined(TARGET_ARCH_X64)
    const char arch[] = "x64";
#elif defined(TARGET_ARCH_ARM)
    const char arch[] = "arm";
#elif defined(TARGET_ARCH_MIPS)
    const char arch[] = "mips";
#else
    const char arch[] = "unknown";
#endif
    LowLevelLogWriteBytes(arch, sizeof(arch));
  }

  ~LowLevelProfileCodeObserver() {
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
    if (file_close == NULL) {
      return;
    }
    ASSERT(log_file_ != NULL);
    (*file_close)(log_file_);
  }

  virtual bool IsActive() const {
    return FLAG_ll_prof;
  }

  struct LowLevelCodeCreateStruct {
    static const char kTag = 'C';

    int32_t name_size;
    uword code_address;
    int32_t code_size;
  };

  template <typename T>
  void LowLevelLogWriteStruct(const T& s) {
    char tag = T::kTag;
    LowLevelLogWriteBytes(reinterpret_cast<const char*>(&tag), sizeof(tag));
    LowLevelLogWriteBytes(reinterpret_cast<const char*>(&s), sizeof(s));
  }

  void LowLevelLogWriteBytes(const char* bytes, int size) {
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    ASSERT(file_write != NULL);
    (file_write)(bytes, size, log_file_);
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    const char* marker = optimized ? "*" : "";
    char* name_buffer =
        Isolate::Current()->current_zone()->PrintToString("%s%s", marker, name);
    intptr_t len = strlen(name_buffer);

    LowLevelCodeCreateStruct event;
    event.name_size = len;
    event.code_address = base;
    event.code_size = size;

    LowLevelLogWriteStruct(event);
    LowLevelLogWriteBytes(name_buffer, len);
    LowLevelLogWriteBytes(reinterpret_cast<char*>(base), size);
  }

 private:
  void* log_file_;

  DISALLOW_COPY_AND_ASSIGN(LowLevelProfileCodeObserver);
};


class PerfCodeObserver : public CodeObserver {
 public:
  PerfCodeObserver() {
    Dart_FileOpenCallback file_open = Isolate::file_open_callback();
    if (file_open == NULL) {
      return;
    }
    const char* format = "/tmp/perf-%ld.map";
    intptr_t pid = getpid();
    intptr_t len = OS::SNPrint(NULL, 0, format, pid);
    char* filename = new char[len + 1];
    OS::SNPrint(filename, len + 1, format, pid);
    out_file_ = (*file_open)(filename);
  }

  ~PerfCodeObserver() {
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
    if (file_close == NULL) {
      return;
    }
    ASSERT(out_file_ != NULL);
    (*file_close)(out_file_);
  }

  virtual bool IsActive() const {
    return FLAG_generate_perf_events_symbols;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    ASSERT(file_write != NULL);
    const char* format = "%"Px" %"Px" %s%s\n";
    const char* marker = optimized ? "*" : "";
    intptr_t len = OS::SNPrint(NULL, 0, format, base, size, marker, name);
    char* buffer = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(buffer, len + 1, format, base, size, marker, name);
    ASSERT(out_file_ != NULL);
    (*file_write)(buffer, len, out_file_);
  }

 private:
  void* out_file_;

  DISALLOW_COPY_AND_ASSIGN(PerfCodeObserver);
};

class PprofCodeObserver : public CodeObserver {
 public:
  PprofCodeObserver() {
    pprof_symbol_generator_ = DebugInfo::NewGenerator();
  }

  ~PprofCodeObserver() {
    Dart_FileOpenCallback file_open = Isolate::file_open_callback();
    if (file_open == NULL) {
      return;
    }
    Dart_FileCloseCallback file_close = Isolate::file_close_callback();
    if (file_close == NULL) {
      return;
    }
    Dart_FileWriteCallback file_write = Isolate::file_write_callback();
    if (file_write == NULL) {
      return;
    }
    if (FLAG_generate_pprof_symbols == NULL) {
      return;
    }
    const char* filename = FLAG_generate_pprof_symbols;
    void* out_file = (*file_open)(filename);
    ASSERT(out_file != NULL);
    DebugInfo::ByteBuffer* debug_region = new DebugInfo::ByteBuffer();
    ASSERT(debug_region != NULL);
    pprof_symbol_generator_->WriteToMemory(debug_region);
    int buffer_size = debug_region->size();
    void* buffer = debug_region->data();
    if (buffer_size > 0) {
      ASSERT(buffer != NULL);
      (*file_write)(buffer, buffer_size, out_file);
    }
    delete debug_region;
    (*file_close)(out_file);
    DebugInfo::UnregisterAllSections();
  }

  virtual bool IsActive() const {
    return FLAG_generate_pprof_symbols != NULL;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    ASSERT(pprof_symbol_generator_ != NULL);
    pprof_symbol_generator_->AddCode(base, size);
    pprof_symbol_generator_->AddCodeRegion(name, base, size);
  }

 private:
  DebugInfo* pprof_symbol_generator_;

  DISALLOW_COPY_AND_ASSIGN(PprofCodeObserver);
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
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
  // TODO(regis): Verify alignment constraints on MIPS.
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
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  const int kMinimumAlignment = 16;
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
  // TODO(regis): Verify alignment constraints on MIPS.
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


int OS::NumberOfAvailableProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}


void OS::Sleep(int64_t millis) {
  // TODO(5411554):  For now just use usleep we may have to revisit this.
  usleep(millis * 1000);
}


void OS::DebugBreak() {
#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_IA32)
  asm("int $3");
#elif defined(HOST_ARCH_ARM)
  asm("svc #0x9f0001");  // __ARM_NR_breakpoint
#elif defined(HOST_ARCH_MIPS)
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
  if (FLAG_ll_prof) {
    CodeObservers::Register(new LowLevelProfileCodeObserver);
  }
  if (FLAG_generate_perf_events_symbols) {
    CodeObservers::Register(new PerfCodeObserver);
  }
  if (FLAG_generate_gdb_symbols) {
    CodeObservers::Register(new GdbCodeObserver);
  }
  if (FLAG_generate_pprof_symbols != NULL) {
    CodeObservers::Register(new PprofCodeObserver);
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

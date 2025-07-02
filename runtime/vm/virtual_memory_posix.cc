// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||            \
    defined(DART_HOST_OS_MACOS)

#include "vm/virtual_memory.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
#include <sys/prctl.h>
#endif

#if defined(DART_HOST_OS_MACOS)
#include <mach/mach_init.h>
#include <mach/vm_map.h>
#endif

#if defined(DART_ENABLE_RX_WORKAROUNDS)
#include <dispatch/dispatch.h>
#include <dispatch/source.h>
#include <mach/mach.h>
#include <mach/mach_port.h>
#include <mach/thread_act.h>

#include "platform/syslog.h"
#include "vm/cpu.h"
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/heap/pages.h"
#include "vm/isolate.h"
#include "vm/virtual_memory_compressed.h"

// #define VIRTUAL_MEMORY_LOGGING 1
#if defined(VIRTUAL_MEMORY_LOGGING)
#define LOG_INFO(msg, ...) OS::PrintErr(msg, ##__VA_ARGS__)
#else
#define LOG_INFO(msg, ...)
#endif  // defined(VIRTUAL_MEMORY_LOGGING)

namespace dart {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

#if defined(DART_HOST_OS_IOS)
#define LARGE_RESERVATIONS_MAY_FAIL
#endif

DECLARE_FLAG(bool, write_protect_code);

#if defined(DART_TARGET_OS_LINUX)
DECLARE_FLAG(bool, generate_perf_events_symbols);
DECLARE_FLAG(bool, generate_perf_jitdump);
#endif

uword VirtualMemory::page_size_ = 0;
VirtualMemory* VirtualMemory::compressed_heap_ = nullptr;

#if defined(DART_ENABLE_RX_WORKAROUNDS)
bool VirtualMemory::should_dual_map_executable_pages_ = false;
#endif  // defined(DART_ENABLE_RX_WORKAROUNDS)

static void* Map(void* addr,
                 size_t length,
                 int prot,
                 int flags,
                 int fd,
                 off_t offset) {
  void* result = mmap(addr, length, prot, flags, fd, offset);
  int error = errno;
  LOG_INFO("mmap(%p, 0x%" Px ", %u, ...): %p\n", addr, length, prot, result);
  if ((result == MAP_FAILED) && (error != ENOMEM)) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("mmap failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  return result;
}

static void Unmap(uword start, uword end) {
  ASSERT(start <= end);
  uword size = end - start;
  if (size == 0) {
    return;
  }

  if (munmap(reinterpret_cast<void*>(start), size) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("munmap failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

static void* GenericMapAligned(void* hint,
                               int prot,
                               intptr_t size,
                               intptr_t alignment,
                               intptr_t allocated_size,
                               int map_flags) {
#if defined(DART_HOST_OS_MACOS)
  // vm_map doesn't support MAP_JIT.
  if ((map_flags & MAP_JIT) == 0) {
    vm_address_t address = 0;
    vm_prot_t cur_prot = 0;
    if ((prot & PROT_READ) != 0) cur_prot |= VM_PROT_READ;
    if ((prot & PROT_WRITE) != 0) cur_prot |= VM_PROT_WRITE;
    if ((prot & PROT_EXEC) != 0) cur_prot |= VM_PROT_EXECUTE;
    vm_prot_t max_prot = VM_PROT_ALL;
    const kern_return_t result =
        vm_map(mach_task_self(), &address, size, /*mask=*/alignment - 1,
               VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, /*offset=*/0,
               /*copy=*/FALSE, cur_prot, max_prot, VM_INHERIT_DEFAULT);
    if (result != KERN_SUCCESS) {
      return nullptr;
    }
    return reinterpret_cast<void*>(address);
  }
#endif
  void* address = Map(hint, allocated_size, prot, map_flags, -1, 0);
  if (address == MAP_FAILED) {
    return nullptr;
  }

  const uword base = reinterpret_cast<uword>(address);
  const uword aligned_base = Utils::RoundUp(base, alignment);

  Unmap(base, aligned_base);
  Unmap(aligned_base + size, base + allocated_size);
  return reinterpret_cast<void*>(aligned_base);
}

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

#if defined(DART_COMPRESSED_POINTERS) && defined(LARGE_RESERVATIONS_MAY_FAIL)
// Truncate to the largest subregion in [region] that doesn't cross an
// [alignment] boundary.
static MemoryRegion ClipToAlignedRegion(MemoryRegion region, size_t alignment) {
  uword base = region.start();
  uword aligned_base = Utils::RoundUp(base, alignment);
  uword size_below =
      region.end() >= aligned_base ? aligned_base - base : region.size();
  uword size_above =
      region.end() >= aligned_base ? region.end() - aligned_base : 0;
  ASSERT(size_below + size_above == region.size());
  if (size_below >= size_above) {
    Unmap(aligned_base, aligned_base + size_above);
    return MemoryRegion(reinterpret_cast<void*>(base), size_below);
  }
  Unmap(base, base + size_below);
  if (size_above > alignment) {
    Unmap(aligned_base + alignment, aligned_base + size_above);
    size_above = alignment;
  }
  return MemoryRegion(reinterpret_cast<void*>(aligned_base), size_above);
}
#endif  // LARGE_RESERVATIONS_MAY_FAIL

#if defined(DART_ENABLE_RX_WORKAROUNDS)
// The function NOTIFY_DEBUGGER_ABOUT_RX_PAGES is a hook point for the debugger.
//
// We expect that LLBD is configured to intercept calls to this function and
// takes care of writing into all pages covered by [base, base+size) address
// range.
//
// For example, you can define the following Python helper script:
//
// ```python
// # rx_helper.py
// import lldb
//
// def handle_new_rx_page(frame: lldb.SBFrame, bp_loc, extra_args, intern_dict):
//     """Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages."""
//     base = frame.register["x0"].GetValueAsAddress()
//     page_len = frame.register["x1"].GetValueAsUnsigned()

//     # Note: NOTIFY_DEBUGGER_ABOUT_RX_PAGES will check contents of the
//     # first page to see if handled it correctly. This makes diagnosing
//     # misconfiguration (e.g. missing breakpoint) easier.
//     data = bytearray(page_len)
//     data[0:8] = b'IHELPED!';

//     error = lldb.SBError()
//     frame.GetThread().GetProcess().WriteMemory(base, data, error)
//     if not error.Success():
//         print(f'Failed to write into {base}[+{page_len}]', error)
//         return
//
// def __lldb_init_module(debugger: lldb.SBDebugger, _):
//     target = debugger.GetDummyTarget()
//     # Caveat: must use BreakpointCreateByRegEx here and not
//     # BreakpointCreateByName. For some reasons callback function does not
//     # get carried over from dummy target for the later.
//     bp = target.bpCreateByRegex("^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$")
//     bp.SetScriptCallbackFunction('{}.handle_new_rx_page'.format(__name__))
//     bp.SetAutoContinue(True)
//     print("-- LLDB integration loaded --")
// ```
//
// Which is then imported into LLDB via `.lldbinit` script:
//
// ```
// # .lldbinit
// command script import --relative-to-command-file rx_helper.py
// ```
//
// XCode allows configuring custom LLDB Init Files: see Product -> Scheme ->
// Run -> Info -> LLDB Init File, you can use `$(SRCROOT)/...` to place LLDB
// script inside project directory itself.
//
__attribute__((noinline)) __attribute__((visibility("default"))) extern "C" void
NOTIFY_DEBUGGER_ABOUT_RX_PAGES(void* base, size_t size) {
  // Note: need this to prevent LLVM from optimizing it away even with
  // noinline.
  asm volatile("" ::"r"(base), "r"(size) : "memory");
}

namespace {

// Handler for EXC_BAD_ACCESS which resumes the thread at the caller of the
// function (sets PC = LR and R0 = kExceptionalReturnValue). This exception
// handler is used to check if we can successfully create executable code
// dynamically: see |CheckIfRXWorks| below.
//
// Note: the handler is using Mach kernel APIs for exception handling instead
// of POSIX signals because using Mach APIs allows to intercept EXC_BAD_ACCESS
// before it stops the debugger.
class ScopedExcBadAccessHandler {
 public:
  static constexpr int32_t kExceptionalReturnValue = 0xDEADDEAD;

  ScopedExcBadAccessHandler() {
    mach_port_options_t options;
    memset(&options, 0, sizeof(options));
    options.flags = MPO_INSERT_SEND_RIGHT;

    mach_port_t exception_port = MACH_PORT_NULL;
    kern_return_t kr =
        mach_port_construct(mach_task_self(), &options, 0, &exception_port);
    RELEASE_ASSERT(kr == KERN_SUCCESS);

    dispatch_source_t source = source_ =
        dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, exception_port,
                               0, DISPATCH_TARGET_QUEUE_DEFAULT);
    RELEASE_ASSERT(source);

    // Process exceptions: ProcessMachExceptionRaiseStateMessage decodes
    // the message and forwards it to IgnoreExceptionAndReturnToCaller.
    dispatch_source_set_event_handler(source, ^{
      constexpr mach_msg_size_t kMaxMessageSize = 5 * KB;
      mach_msg_server_once(ProcessMachExceptionRaiseStateMessage,
                           kMaxMessageSize, exception_port,
                           MACH_MSG_TIMEOUT_NONE);
    });

    // When this handler is no longer needed destroy the port.
    dispatch_source_set_cancel_handler(source, ^{
      mach_port_deallocate(mach_task_self(), exception_port);
      // Note: don't capture this because it will be invalid by the time
      // cancelation handler is called.
      dispatch_release(source);
    });

    dispatch_resume(source);

    old_mask_count_ = 1;  // We expect at most one old handler.
    kern_return_t result = thread_swap_exception_ports(
        mach_thread_self(), EXC_MASK_BAD_ACCESS, exception_port,
        MACH_EXCEPTION_CODES | EXCEPTION_STATE, MACHINE_THREAD_STATE,
        &old_exception_mask_, &old_mask_count_, &old_handler_, &old_behavior_,
        &old_flavor_);
    RELEASE_ASSERT(result == KERN_SUCCESS);
    RELEASE_ASSERT(old_mask_count_ == 1);
  }

  ~ScopedExcBadAccessHandler() {
    kern_return_t result =
        thread_set_exception_ports(mach_thread_self(), old_exception_mask_,
                                   old_handler_, old_behavior_, old_flavor_);
    RELEASE_ASSERT(result == KERN_SUCCESS);
    dispatch_source_cancel(source_);
  }

 private:
  // This exception handler simply ignores the EXC_BAD_ACCESS and
  // makes the thread continue at the caller frame by setting PC to LR and
  // X0 to a special signal value.
  //
  // The signature of this handler matches |catch_exception_raise_state|.
  //
  // See https://developer.apple.com/documentation/kernel/1537255-catch_exception_raise_state
  static kern_return_t IgnoreExceptionAndReturnToCaller(
      mach_port_t exception_port,
      exception_type_t exception,
      const mach_exception_data_t code,
      mach_msg_type_number_t code_count,
      int* flavor,
      const thread_state_t old_state,
      mach_msg_type_number_t old_state_count,
      thread_state_t new_state,
      mach_msg_type_number_t* new_state_count) {
    // Copy old_state into new_state.
    memmove(new_state, old_state, sizeof(*old_state) * old_state_count);
    *new_state_count = old_state_count;

    // Update X0 and PC so that we can successfully resume execution.
    auto arm_new_state =
        reinterpret_cast<arm_unified_thread_state_t*>(new_state);
    arm_new_state->ts_64.__x[0] = kExceptionalReturnValue;
    arm_new_state->ts_64.__pc = arm_new_state->ts_64.__lr;
    return KERN_SUCCESS;
  }

  // The code in |ProcessMachExceptionRaiseStateMessage| and corresponding
  // structure definitions are based on output of the mig
  // (Mach Interface Generator, see |man mig|) applied to mach/mach_exc.defs.
  //
  // Including mig output directly is undesirable because it relies on
  // linking to exception handling routines by name (e.g. it expects
  // special symbols like mach_catch_exception_raise_state,
  // mach_catch_exception_raise_state_identity, to be defined). This might
  // make Dart VM harder to embed - as some other part of the code base might
  // want to use mig generated exception handling code and already define
  // this symbols.
  //
  // Thus we rewrite that code dropping all irrelevant bits and making the
  // code more readable.
  //
  // Request message for mach_exception_raise_state has two variadic arrays
  // inside, so we split it into two chunks each ending with a corresponding
  // variadic array.
#define TRAILING_ARRAY(Type, name, count, max_count)                           \
  Type* name() { return reinterpret_cast<Type*>(this + 1); }                   \
  bool IsValid() const { return count <= max_count; }                          \
  mach_msg_size_t Size() const { return sizeof(*this) + sizeof(Type) * count; }

  // A helper method for parsing a message which contains variadic arrays
  // inside. Such message is split into separate chunks each ending with
  // a trailing array.
  template <typename... Ts>
  static std::tuple<bool, Ts*...> ParseMessage(mach_msg_header_t* header) {
    uword current = reinterpret_cast<uword>(header);
    mach_msg_size_t remaining = header->msgh_size;
    const uword message_end = current + remaining;

    std::tuple<bool, Ts*...> result{
        true, [&current, &remaining]() -> Ts* {
          if (remaining >= sizeof(Ts)) {
            Ts* chunk = reinterpret_cast<Ts*>(current);
            const auto chunk_size = chunk->Size();
            if (chunk->IsValid() && chunk_size <= remaining) {
              current += chunk_size;
              remaining -= chunk_size;
              return chunk;
            }
          }

          // Once an error is encountered shortcut the rest of the parsing
          // by setting number of remaining bytes to 0.
          remaining = 0;
          current = 0;
          return nullptr;
        }()...};

    // If we did not fully parse the message - we have either failed or
    // we have unparsed bytes. Either case is an error.
    if (current != message_end) {
      return {false, static_cast<Ts*>(nullptr)...};
    }
    return result;
  }

#pragma pack(push, 4)
  static constexpr natural_t kMaxCodeCount = 2;
  static constexpr natural_t kMaxStateCount = 1296;

  struct RequestChunk0 {
    mach_msg_header_t Head;
    NDR_record_t NDR;
    exception_type_t exception;
    mach_msg_type_number_t code_count;  // <= kMaxCodeCount
    TRAILING_ARRAY(int64_t, code, code_count, kMaxCodeCount);
  };

  struct RequestChunk1 {
    int flavor;
    mach_msg_type_number_t old_state_count;  // <= kMaxStateCount
    TRAILING_ARRAY(natural_t, old_state, old_state_count, kMaxStateCount);
  };

  struct Reply {
    mach_msg_header_t Head;
    NDR_record_t NDR;
    kern_return_t RetCode;
    int flavor;
    mach_msg_type_number_t new_state_count;
    TRAILING_ARRAY(natural_t, new_state, new_state_count, kMaxStateCount);
  };
#pragma pack(pop)

  static boolean_t ReplyWithError(mach_msg_header_t* reply_header,
                                  kern_return_t code) {
    auto reply = reinterpret_cast<mig_reply_error_t*>(reply_header);
    reply->RetCode = code;
    reply->NDR = NDR_record;
    return FALSE;
  }

  static boolean_t ProcessMachExceptionRaiseStateMessage(
      mach_msg_header_t* request_header,
      mach_msg_header_t* reply_header) {
    reply_header->msgh_bits =
        MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request_header->msgh_bits), 0);
    reply_header->msgh_remote_port = request_header->msgh_remote_port;
    // Minimal size: will update later if success.
    reply_header->msgh_size =
        static_cast<mach_msg_size_t>(sizeof(mig_reply_error_t));
    reply_header->msgh_local_port = MACH_PORT_NULL;
    reply_header->msgh_id = request_header->msgh_id + 100;
    reply_header->msgh_reserved = 0;

    if (request_header->msgh_id != 2406) {
      return ReplyWithError(reply_header, MIG_BAD_ID);
    }

    if (request_header->msgh_bits & MACH_MSGH_BITS_COMPLEX) {
      return ReplyWithError(reply_header, MIG_BAD_ARGUMENTS);
    }

    auto [ok, req0, req1] =
        ParseMessage<RequestChunk0, RequestChunk1>(request_header);
    if (!ok) {
      return ReplyWithError(reply_header, MIG_BAD_ARGUMENTS);
    }

    auto reply = reinterpret_cast<Reply*>(reply_header);
    reply->new_state_count = kMaxStateCount;
    reply->RetCode = IgnoreExceptionAndReturnToCaller(
        request_header->msgh_local_port, req0->exception, req0->code(),
        req0->code_count, &req1->flavor, req1->old_state(),
        req1->old_state_count, reply->new_state(), &reply->new_state_count);
    if (reply->RetCode != KERN_SUCCESS) {
      return ReplyWithError(reply_header, reply->RetCode);
    }

    reply->NDR = NDR_record;
    reply->flavor = req1->flavor;
    reply->Head.msgh_size = reply->Size();
    return TRUE;
  }

  dispatch_source_t source_ = nullptr;

  // Old exception handler (e.g. one installed by the debugger or some
  // other library).
  natural_t old_mask_count_ = 0;
  exception_mask_t old_exception_mask_ = 0;
  mach_port_t old_handler_ = MACH_PORT_NULL;
  exception_behavior_t old_behavior_ = 0;
  thread_state_flavor_t old_flavor_ = 0;

  DISALLOW_COPY_AND_ASSIGN(ScopedExcBadAccessHandler);
};

// Check if we can generate machine code dynamically by creating a small
// function in memory and then trying to execute it.
//
// Returns true if that was successful.
//
// Note: we use Syslog::PrintErr below instead of OS::PrintErr to send
// output to the same location where FATAL message would be reported to if any.
bool CheckIfRXWorks() {
  // Try creating executable VirtualMemory.
  std::unique_ptr<VirtualMemory> mem{
      VirtualMemory::Allocate(VirtualMemory::PageSize(), /*is_executable=*/true,
                              /*is_compressed=*/false, /*name=*/nullptr)};
  if (mem == nullptr) {
    Syslog::PrintErr("Failed to map a test RX page");
    return false;
  }

  // Freshly created virtual memory should have signs of debugger script
  // working. See the comment above for the example of an LLDB script.
  const bool debugger_script_loaded =
      memcmp(mem->address(), "IHELPED!", 8) == 0;

  // Flip memory to RW write a simple function that computes a 32-bit integer
  // square and then flip protection back to R/RX.
  mem->Protect(VirtualMemory::kReadWrite);
  constexpr uint32_t kSquareFunctionCode[] = {
      0x1b007c00,  // mul w0, w0, w0
      0xd65f03c0   // ret
  };
  memmove(mem->address(), kSquareFunctionCode, sizeof(kSquareFunctionCode));
  VirtualMemory::WriteProtectCode(mem->address(), mem->size());

  // Get executable entry point and check that write have succeeded.
  const uword entry_point = mem->start() + mem->OffsetToExecutableAlias();
  if (memcmp(reinterpret_cast<void*>(entry_point), kSquareFunctionCode,
             sizeof(kSquareFunctionCode)) != 0) {
    Syslog::PrintErr("Failed to write executable code: code mismatch");
    return false;
  }
  CPU::FlushICache(entry_point, sizeof(kSquareFunctionCode));

  constexpr int32_t kInput = 11;
  constexpr int32_t kExpectedOutput = kInput * kInput;

  // Invoke square function and catch any potential EXC_BAD_ACCESS.
  int32_t result = 0;
  {
    ScopedExcBadAccessHandler exception_handler;
    auto square = reinterpret_cast<int32_t (*)(int32_t)>(entry_point);
    result = square(kInput);
  }

  // Validate that the code we have generated produced expected result.
  if (result != kExpectedOutput) {
    Syslog::PrintErr(
        "Failed to execute code (error: %s, debugger assist: %s)\n",
        result == ScopedExcBadAccessHandler::kExceptionalReturnValue
            ? "EXC_BAD_ACCESS"
            : "unknown",
        debugger_script_loaded ? "ok" : "not detected");
    return false;
  }

  return true;
}
}  // namespace
#endif

void VirtualMemory::Init() {
  if (FLAG_old_gen_heap_size < 0 || FLAG_old_gen_heap_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --old_gen_heap_size %d is larger than"
        " the physically addressable range, using 0(unlimited) instead.`\n",
        FLAG_old_gen_heap_size);
    FLAG_old_gen_heap_size = 0;
  }
  if (FLAG_new_gen_semi_max_size < 0 ||
      FLAG_new_gen_semi_max_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --new_gen_semi_max_size %d is larger"
        " than the physically addressable range, using %" Pd " instead.`\n",
        FLAG_new_gen_semi_max_size, kDefaultNewGenSemiMaxSize);
    FLAG_new_gen_semi_max_size = kDefaultNewGenSemiMaxSize;
  }
  page_size_ = CalculatePageSize();

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  bool can_jit = true;
  if (IsAtLeastIOS26_0()) {
    should_dual_map_executable_pages_ = true;
    can_jit = CheckIfRXWorks();
  }
#if defined(DART_INCLUDE_SIMULATOR)
  FLAG_use_simulator = !can_jit;
  Syslog::PrintErr("Dart execution mode: %s\n",
                   FLAG_use_simulator ? "simulator" : "JIT");
#else
  if (!can_jit) {
    FATAL(
        "Unable to JIT: failed to create executable machine code dynamically "
        "due to OS restrictions");
  }
#endif
#endif

#if defined(DART_COMPRESSED_POINTERS)
  ASSERT(compressed_heap_ == nullptr);
#if defined(LARGE_RESERVATIONS_MAY_FAIL)
  // Try to reserve a region for the compressed heap by requesting decreasing
  // powers-of-two until one succeeds, and use the largest subregion that does
  // not cross a 4GB boundary. The subregion itself is not necessarily
  // 4GB-aligned.
  for (size_t allocated_size = kCompressedHeapSize + kCompressedHeapAlignment;
       allocated_size >= kCompressedPageSize; allocated_size >>= 1) {
    void* address = GenericMapAligned(
        nullptr, PROT_NONE, allocated_size, kCompressedPageSize,
        allocated_size + kCompressedPageSize,
        MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE);
    if (address == nullptr) continue;

    MemoryRegion region(address, allocated_size);
    region = ClipToAlignedRegion(region, kCompressedHeapAlignment);
    compressed_heap_ = new VirtualMemory(region, region);
    break;
  }
#else
  compressed_heap_ = Reserve(kCompressedHeapSize, kCompressedHeapAlignment);
#endif
  if (compressed_heap_ == nullptr) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to reserve region for compressed heap: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  VirtualMemoryCompressedHeap::Init(compressed_heap_->address(),
                                    compressed_heap_->size());
#endif  // defined(DART_COMPRESSED_POINTERS)
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
  FILE* fp = fopen("/proc/sys/vm/max_map_count", "r");
  if (fp != nullptr) {
    size_t max_map_count = 0;
    int count = fscanf(fp, "%zu", &max_map_count);
    fclose(fp);
    if (count == 1) {
      size_t max_heap_pages = FLAG_old_gen_heap_size * MB / kPageSize;
      if (max_map_count < max_heap_pages) {
        OS::PrintErr(
            "warning: vm.max_map_count (%zu) is not large enough to support "
            "--old_gen_heap_size=%d. Consider increasing it with `sysctl -w "
            "vm.max_map_count=%zu`\n",
            max_map_count, FLAG_old_gen_heap_size, max_heap_pages);
      }
    }
  }
#endif
}

void VirtualMemory::Cleanup() {
#if defined(DART_COMPRESSED_POINTERS)
  delete compressed_heap_;
#endif  // defined(DART_COMPRESSED_POINTERS)
  page_size_ = 0;
#if defined(DART_COMPRESSED_POINTERS)
  compressed_heap_ = nullptr;
  VirtualMemoryCompressedHeap::Cleanup();
#endif  // defined(DART_COMPRESSED_POINTERS)
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              bool is_compressed,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  ASSERT(name != nullptr);

#if defined(DART_COMPRESSED_POINTERS)
  if (is_compressed) {
    RELEASE_ASSERT(!is_executable);
    MemoryRegion region =
        VirtualMemoryCompressedHeap::Allocate(size, alignment);
    if (region.pointer() == nullptr) {
#if defined(LARGE_RESERVATIONS_MAY_FAIL)
      // Try a fresh allocation and hope it ends up in the right region. On
      // macOS/iOS, this works surprisingly often.
      void* address =
          GenericMapAligned(nullptr, PROT_READ | PROT_WRITE, size, alignment,
                            size + alignment, MAP_PRIVATE | MAP_ANONYMOUS);
      if (address != nullptr) {
        uword ok_start = Utils::RoundDown(compressed_heap_->start(),
                                          kCompressedHeapAlignment);
        uword ok_end = ok_start + kCompressedHeapSize;
        uword start = reinterpret_cast<uword>(address);
        uword end = start + size;
        if ((start >= ok_start) && (end <= ok_end)) {
          MemoryRegion region(address, size);
          return new VirtualMemory(region, region);
        }
        munmap(address, size);
      }
#endif
      return nullptr;
    }
    Commit(region.pointer(), region.size());
    return new VirtualMemory(region, region);
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  const intptr_t allocated_size = size + alignment - PageSize();

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  // We need to map the original page using RX for dual mapping to have
  // effect on iOS.
  const int prot = (is_executable && should_dual_map_executable_pages_)
                       ? PROT_READ | PROT_EXEC
                       : PROT_READ | PROT_WRITE;
#else
  const int prot =
      PROT_READ | PROT_WRITE |
      ((is_executable && !FLAG_write_protect_code) ? PROT_EXEC : 0);
#endif

  int map_flags = MAP_PRIVATE | MAP_ANONYMOUS;
#if (defined(DART_HOST_OS_MACOS) && !defined(DART_HOST_OS_IOS))
  if (is_executable && IsAtLeastMacOSX10_14() &&
      !ShouldDualMapExecutablePages()) {
    map_flags |= MAP_JIT;
  }
#endif  // defined(DART_HOST_OS_MACOS)

  void* hint = nullptr;
  // Some 64-bit microarchitectures store only the low 32-bits of targets as
  // part of indirect branch prediction, predicting that the target's upper bits
  // will be same as the call instruction's address. This leads to misprediction
  // for indirect calls crossing a 4GB boundary. We ask mmap to place our
  // generated code near the VM binary to avoid this.
  if (is_executable) {
    hint = reinterpret_cast<void*>(&Dart_Initialize);
  }
  void* address =
      GenericMapAligned(hint, prot, size, alignment, allocated_size, map_flags);
#if defined(DART_HOST_OS_LINUX)
  // On WSL 1 trying to allocate memory close to the binary by supplying a hint
  // fails with ENOMEM for unclear reason. Some reports suggest that this might
  // be related to the alignment of the hint but aligning it by 64Kb does not
  // make the issue go away in our experiments. Instead just retry without any
  // hint.
  if (address == nullptr && hint != nullptr &&
      Utils::IsWindowsSubsystemForLinux()) {
    address = GenericMapAligned(nullptr, prot, size, alignment, allocated_size,
                                map_flags);
  }
#endif
  if (address == nullptr) {
    return nullptr;
  }

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  if (is_executable && should_dual_map_executable_pages_) {
    // |address| is mapped RX, create a corresponding RW alias through which
    // we will write into the executable mapping.
    vm_address_t writable_address = 0;
    vm_prot_t cur_protection, max_protection;
    const kern_return_t result =
        vm_remap(mach_task_self(), &writable_address, size,
                 /*mask=*/alignment - 1, VM_FLAGS_ANYWHERE, mach_task_self(),
                 reinterpret_cast<vm_address_t>(address), /*copy=*/FALSE,
                 &cur_protection, &max_protection, VM_INHERIT_NONE);
    if (result != KERN_SUCCESS) {
      munmap(address, size);
      return nullptr;
    }

    NOTIFY_DEBUGGER_ABOUT_RX_PAGES(reinterpret_cast<void*>(address), size);

    Protect(reinterpret_cast<void*>(writable_address), size, kReadWrite);

    MemoryRegion region(address, size);
    MemoryRegion writable_alias(reinterpret_cast<void*>(writable_address),
                                size);
    return new VirtualMemory(writable_alias, region, writable_alias);
  }
#endif  // defined(DART_ENABLE_RX_WORKAROUNDS)

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  // PR_SET_VMA was only added to mainline Linux in 5.17, and some versions of
  // the Android NDK have incorrect headers, so we manually define it if absent.
#if !defined(PR_SET_VMA)
#define PR_SET_VMA 0x53564d41
#endif
#if !defined(PR_SET_VMA_ANON_NAME)
#define PR_SET_VMA_ANON_NAME 0
#endif
  prctl(PR_SET_VMA, PR_SET_VMA_ANON_NAME, address, size, name);
#endif

  MemoryRegion region(reinterpret_cast<void*>(address), size);
  return new VirtualMemory(region, region);
}

VirtualMemory* VirtualMemory::Reserve(intptr_t size, intptr_t alignment) {
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  intptr_t allocated_size = size + alignment - PageSize();
  void* address =
      GenericMapAligned(nullptr, PROT_NONE, size, alignment, allocated_size,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE);
  if (address == nullptr) {
    return nullptr;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, region);
}

void VirtualMemory::Commit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  void* result = mmap(address, size, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
  if (result == MAP_FAILED) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to commit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

void VirtualMemory::Decommit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  void* result =
      mmap(address, size, PROT_NONE,
           MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED, -1, 0);
  if (result == MAP_FAILED) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to decommit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

VirtualMemory::~VirtualMemory() {
#if defined(DART_COMPRESSED_POINTERS)
  if (VirtualMemoryCompressedHeap::Contains(reserved_.pointer()) &&
      (this != compressed_heap_)) {
    Decommit(reserved_.pointer(), reserved_.size());
    VirtualMemoryCompressedHeap::Free(reserved_.pointer(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (vm_owns_region()) {
    Unmap(reserved_.start(), reserved_.end());
#if defined(DART_ENABLE_RX_WORKAROUNDS)
    if (reserved_.start() != executable_alias_.start()) {
      Unmap(executable_alias_.start(), executable_alias_.end());
    }
#endif  // defined(DART_ENABLE_RX_WORKAROUNDS)
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
#if defined(DART_COMPRESSED_POINTERS)
  // Don't free the sub segment if it's managed by the compressed pointer heap.
  if (VirtualMemoryCompressedHeap::Contains(address)) {
    return false;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  const uword start = reinterpret_cast<uword>(address);
  Unmap(start, start + size);
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsDartMutatorThread() ||
         thread->isolate() == nullptr ||
         thread->isolate()->mutator_thread()->IsAtSafepoint());
#endif
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
  int prot = 0;
  switch (mode) {
    case kNoAccess:
      prot = PROT_NONE;
      break;
    case kReadOnly:
      prot = PROT_READ;
      break;
    case kReadWrite:
      prot = PROT_READ | PROT_WRITE;
      break;
    case kReadExecute:
      prot = PROT_READ | PROT_EXEC;
      break;
    case kReadWriteExecute:
      prot = PROT_READ | PROT_WRITE | PROT_EXEC;
      break;
  }
  if (mprotect(reinterpret_cast<void*>(page_address),
               end_address - page_address, prot) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) failed\n", page_address,
             end_address - page_address, prot);
    FATAL("mprotect failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) ok\n", page_address,
           end_address - page_address, prot);
}

void VirtualMemory::DontNeed(void* address, intptr_t size) {
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
#if defined(DART_HOST_OS_MACOS)
  int advice = MADV_FREE;
#else
  int advice = MADV_DONTNEED;
#endif
  if (madvise(reinterpret_cast<void*>(page_address), end_address - page_address,
              advice) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("madvise failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

#if defined(DART_HOST_OS_MACOS)
// TODO(52579): Reenable on Fuchsia.
bool VirtualMemory::DuplicateRX(VirtualMemory* target) {
  const intptr_t aligned_size = Utils::RoundUp(size(), PageSize());
  ASSERT_LESS_OR_EQUAL(aligned_size, target->size());

  // Mac is special cased because iOS doesn't allow allocating new executable
  // memory, so the default approach would fail. We are allowed to make new
  // mappings of existing executable memory using vm_remap though, which is
  // effectively the same for non-writable memory.
  const mach_port_t task = mach_task_self();
  const vm_address_t source_address = reinterpret_cast<vm_address_t>(address());
  const vm_size_t mem_size = aligned_size;
  const vm_prot_t read_execute = VM_PROT_READ | VM_PROT_EXECUTE;
  vm_prot_t current_protection = read_execute;
  vm_prot_t max_protection = read_execute;
  vm_address_t target_address =
      reinterpret_cast<vm_address_t>(target->address());
  kern_return_t status = vm_remap(
      task, &target_address, mem_size,
      /*mask=*/0,
      /*flags=*/VM_FLAGS_FIXED | VM_FLAGS_OVERWRITE, task, source_address,
      /*copy=*/true, &current_protection, &max_protection,
      /*inheritance=*/VM_INHERIT_NONE);
  if (status != KERN_SUCCESS) {
    return false;
  }
  ASSERT(reinterpret_cast<void*>(target_address) == target->address());
  ASSERT_EQUAL(current_protection & read_execute, read_execute);
  ASSERT_EQUAL(max_protection & read_execute, read_execute);
  return true;
}
#endif  // defined(DART_HOST_OS_MACOS)

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||     \
        // defined(DART_HOST_OS_MACOS)

// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef RUNTIME_VM_FFI_CALLBACK_METADATA_H_
#define RUNTIME_VM_FFI_CALLBACK_METADATA_H_

#include "platform/growable_array.h"
#include "platform/utils.h"
#include "vm/hash_map.h"
#include "vm/lockers.h"
#include "vm/virtual_memory.h"

namespace dart {

// Stores metadata related to FFI callbacks (Dart functions that are assigned a
// function pointer that can be invoked by native code). This is essentially a
// map from trampoline pointer to Metadata, with some logic to assign and memory
// manage those trampolines.
//
// In the past, callbacks were primarily identified by an integer ID, but in
// this class we identify them by their trampoline pointer to solve a very
// specific issue. The trampolines are allocated in pages. On iOS in AOT mode,
// we can't create new executable memory, but we can duplicate existing memory.
// When we were using numeric IDs to identify the trampolines, each trampoline
// page was different, because the IDs were embedded in the machine code. So we
// couldn't use trampolines in AOT mode. But if we key the metadata table by the
// trampoline pointer, then the trampoline just has to look up the PC at the
// start of the trampoline function, so the machine code will always be the
// same. This means we can just duplicate the trampoline page, allowing us to
// unify the FFI callback implementation across JIT and AOT, even on iOS.
class FfiCallbackMetadata {
 public:
  class Metadata;

  // The address of the allocated trampoline.
  using Trampoline = uword;

  enum class TrampolineType : uint8_t {
    kSync = 0,
    kAsync = 1,
#if defined(TARGET_ARCH_IA32)
    kSyncStackDelta4 = 2,
#endif
  };

  enum RuntimeFunctions {
    kGetFfiCallbackMetadata,
    kNumRuntimeFunctions,
  };

  static void Init();
  static void Cleanup();

  // Returns the FfiCallbackMetadata singleton.
  static FfiCallbackMetadata* Instance();

  // Creates a sync callback trampoline for the given function.
  Trampoline CreateSyncFfiCallback(Isolate* isolate,
                                   Zone* zone,
                                   const Function& function,
                                   Metadata** sync_list_head);

  // Deletes all the sync trampolines in the list.
  void DeleteSyncTrampolines(Metadata** sync_list_head);

  // FFI callback metadata for any sync or async trampoline.
  class Metadata {
    Isolate* target_isolate_ = nullptr;

    union {
      // IsLive()
      struct {
        // Note: This is a pointer into an an Instructions object. This is only
        // safe because Instructions objects are never moved by the GC.
        uword target_entry_point_;

        Metadata* sync_list_next_;

        TrampolineType trampoline_type_;
      };

      // !IsLive()
      Metadata* free_list_next_;
    };

    Metadata()
        : target_entry_point_(0),
          sync_list_next_(nullptr),
          trampoline_type_(TrampolineType::kSync) {}
    Metadata(Isolate* target_isolate,
             uword target_entry_point,
             Metadata* sync_list_next,
             TrampolineType trampoline_type)
        : target_isolate_(target_isolate),
          target_entry_point_(target_entry_point),
          sync_list_next_(sync_list_next),
          trampoline_type_(trampoline_type) {}

   public:
    friend class FfiCallbackMetadata;
    bool operator==(const Metadata& other) const {
      return target_isolate_ == other.target_isolate_ &&
             target_entry_point_ == other.target_entry_point_ &&
             sync_list_next_ == other.sync_list_next_ &&
             trampoline_type_ == other.trampoline_type_;
    }
    bool operator!=(const Metadata& other) const { return !(*this == other); }

    // Whether the callback is still alive.
    bool IsLive() const { return target_isolate_ != 0; }

    // The target isolate. The isolate that owns the callback. Sync callbacks
    // must be invoked on this isolate. Async callbacks will send a message to
    // this isolate.
    Isolate* target_isolate() const {
      ASSERT(IsLive());
      return target_isolate_;
    }

    // The Dart entrypoint for the callback, which the trampoline invokes.
    uword target_entry_point() const {
      ASSERT(IsLive());
      return target_entry_point_;
    }

    // To efficiently delete all the sync callbacks for a isolate, they are
    // stored in a singly-linked list. This is the next link in that list.
    Metadata* sync_list_next() {
      ASSERT(IsLive());
      return sync_list_next_;
    }

    // Tells FfiCallbackTrampolineStub how to call into the entry point. Mostly
    // it's just a flag for whether this is a sync or async callback, but on
    // IA32 it also encodes whether there's a stack delta of 4 to deal with.
    TrampolineType trampoline_type() const {
      ASSERT(IsLive());
      return trampoline_type_;
    }
  };

  // Returns the Metadata object for the given trampoline.
  Metadata LookupMetadataForTrampoline(Trampoline trampoline) const;

  // The number of trampolines that can be stored on a single page.
  static constexpr intptr_t NumCallbackTrampolinesPerPage() {
    return (kPageSize - kNativeCallbackSharedStubSize) /
           kNativeCallbackTrampolineSize;
  }

  // Size of the trampoline page. Ideally we'd use VirtualMemory::PageSize(),
  // but that varies across machines, and we need it to be consistent between
  // host and target since it affects stub code generation. So kPageSize may be
  // an overestimate of the target's VirtualMemory::PageSize(), but we try to
  // get it as close as possible to avoid wasting memory.
#if defined(DART_TARGET_OS_LINUX) && defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kPageSize = 64 * KB;
#elif defined(DART_TARGET_OS_MACOS) && defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kPageSize = 16 * KB;
#elif defined(DART_TARGET_OS_FUCHSIA)
  // Fuchsia only gets one page, so make it big.
  // TODO(https://dartbug.com/52579): Remove.
  static constexpr intptr_t kPageSize = 64 * KB;
#else
  static constexpr intptr_t kPageSize = 4 * KB;
#endif
  static constexpr intptr_t kPageMask = ~(kPageSize - 1);

  // Each time we allocate new virtual memory for trampolines we allocate an
  // [RX][RW] area:
  //
  //   * [RX] 2 pages fully containing [StubCode::FfiCallbackTrampoline()]
  //   * [RW] pages sufficient to hold
  //      - `kNumRuntimeFunctions` x [uword] function pointers
  //      - `NumCallbackTrampolinesPerPage()` x [Metadata] objects
  static constexpr intptr_t RXMappingSize() { return 2 * kPageSize; }
  static constexpr intptr_t RWMappingSize() {
    return Utils::RoundUp(
        kNumRuntimeFunctions * compiler::target::kWordSize +
            sizeof(Metadata) * NumCallbackTrampolinesPerPage(),
        kPageSize);
  }
  static constexpr intptr_t MappingSize() {
    return RXMappingSize() + RWMappingSize();
  }
  static constexpr intptr_t MappingAlignment() {
    return Utils::RoundUpToPowerOfTwo(MappingSize());
  }
  static constexpr intptr_t MappingStart(uword address) {
    const uword mask = MappingAlignment() - 1;
    return address & ~mask;
  }
  static constexpr uword RuntimeFunctionOffset(uword function_index) {
    return RXMappingSize() + function_index * compiler::target::kWordSize;
  }
  static constexpr intptr_t MetadataOffset() {
    return RuntimeFunctionOffset(kNumRuntimeFunctions);
  }

#if defined(TARGET_ARCH_X64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 12;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 289;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_IA32)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 10;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 142;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 196;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 296;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_RISCV32)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 230;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_RISCV64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 202;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#else
#error What architecture?
#endif

 private:
  FfiCallbackMetadata();
  ~FfiCallbackMetadata();
  void EnsureStubPageLocked();
  void AddToFreeListLocked(Metadata* entry);
  void FillRuntimeFunction(VirtualMemory* page, uword index, void* function);
  VirtualMemory* AllocateTrampolinePage();
  void EnsureFreeListNotEmptyLocked();
  Metadata* AllocateTrampolineLocked();
  Trampoline TryAllocateFromFreeListLocked();
  Trampoline CreateFfiCallback(Isolate* isolate,
                               Zone* zone,
                               const Function& function,
                               Metadata** sync_list_head);
  Metadata* MetadataOfTrampoline(Trampoline trampoline) const;
  Trampoline TrampolineOfMetadata(Metadata* metadata) const;

  static FfiCallbackMetadata* singleton_;

  mutable RwLock lock_;
  VirtualMemory* stub_page_ = nullptr;
  MallocGrowableArray<VirtualMemory*> trampoline_pages_;
  uword offset_of_first_trampoline_in_page_ = 0;
  Metadata* free_list_head_ = nullptr;
  Metadata* free_list_tail_ = nullptr;

#if defined(DART_TARGET_OS_FUCHSIA)
  // TODO(https://dartbug.com/52579): Remove.
  VirtualMemory* fuchsia_metadata_page_ = nullptr;
#endif  // defined(DART_TARGET_OS_FUCHSIA)

  DISALLOW_COPY_AND_ASSIGN(FfiCallbackMetadata);
};

}  // namespace dart

#endif  // RUNTIME_VM_FFI_CALLBACK_METADATA_H_

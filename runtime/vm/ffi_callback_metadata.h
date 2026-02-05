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

class ApiState;
class Closure;
class Function;
class Isolate;
class PersistentHandle;

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
  class MetadataEntry;

  // The address of the allocated trampoline.
  using Trampoline = uword;

  enum class TrampolineType : uint8_t {
    kSync = 0,
    kSyncStackDelta4 = 1,  // Only used by TARGET_ARCH_IA32
    kAsync = 2,
    kSyncIsolateGroupBound = 3,
    kSyncIsolateGroupBoundStackDelta4 = 4,  // Only used by TARGET_ARCH_IA32
  };

  // There are 2 supported invocation flows for kSync callbacks. The normal flow
  // is when the current thread is already entered into the target isolate. The
  // other flow is when the current thread is not entered into any isolate, but
  // it owns the target isolate. In the latter case, GetFfiCallbackMetadata
  // enters the target isolate. It also ORs this flag onto out_trampoline_type
  // so that the invocation stub knows to exit the isolate again after calling
  // the target callback. So this flag must not collide with TrampolineType
  // values, and on 32-bit arm it needs to fit in a uint8.
  static constexpr uword kSyncCallbackIsolateOwnershipFlag = 1 << 7;

  enum RuntimeFunctions {
    kGetFfiCallbackMetadata,
    kExitTemporaryIsolate,
    kExitIsolateGroupBoundIsolate,
    kExitSyncCallbackTargetIsolate,
    kNumRuntimeFunctions,
  };

  static void Init();
  static void Cleanup();

  // Returns the FfiCallbackMetadata singleton.
  static FfiCallbackMetadata* Instance();

  // Creates an async callback trampoline for the given function and associates
  // it with the send_port.
  Trampoline CreateAsyncFfiCallback(Isolate* isolate,
                                    Zone* zone,
                                    const Function& function,
                                    Dart_Port send_port,
                                    MetadataEntry** list_head);

  // Creates an isolate- or isolategroup- local callback trampoline for
  // the given function.
  Trampoline CreateLocalFfiCallback(Isolate* isolate,
                                    IsolateGroup* isolate_group,
                                    Zone* zone,
                                    const Function& function,
                                    const Closure& closure,
                                    MetadataEntry** list_head);

  // Deletes a single trampoline.
  void DeleteCallback(Trampoline trampoline, MetadataEntry** list_head);

  // Deletes all the trampolines in the list.
  void DeleteAllCallbacks(MetadataEntry** list_head);

  // FFI callback metadata for any sync or async trampoline.
  class Metadata {
    union {
      Isolate* target_isolate_;
      IsolateGroup* target_isolate_group_;
    };
    TrampolineType trampoline_type_;

    // Note: This is a pointer into an an Instructions object. This is only
    // safe because Instructions objects are never moved by the GC.
    uword target_entry_point_;

    // For async callbacks, this is the send port. For sync callbacks this
    // is a persistent handle to the callback's closure, or null.
    uint64_t context_;

    Metadata(Isolate* target_isolate,
             TrampolineType trampoline_type,
             uword target_entry_point,
             uint64_t context)
        : target_isolate_(target_isolate),
          trampoline_type_(trampoline_type),
          target_entry_point_(target_entry_point),
          context_(context) {}

    Metadata(IsolateGroup* target_isolate_group,
             TrampolineType trampoline_type,
             uword target_entry_point,
             uint64_t context)
        : target_isolate_group_(target_isolate_group),
          trampoline_type_(trampoline_type),
          target_entry_point_(target_entry_point),
          context_(context) {}

   public:
    friend class FfiCallbackMetadata;
    bool IsSameCallback(const Metadata& other) const {
      // Not checking the list links, because they can change when other
      // callbacks are deleted.
      return target_isolate_ == other.target_isolate_ &&
             trampoline_type_ == other.trampoline_type_ &&
             target_entry_point_ == other.target_entry_point_ &&
             context_ == other.context_;
    }

    // Whether the callback is still alive.
    bool IsLive() const {
      return target_isolate_ != 0 || target_isolate_group_ != 0;
    }

    // The target isolate. The isolate that owns the callback. Sync callbacks
    // must be invoked on this isolate. Async callbacks will send a message to
    // this isolate.
    Isolate* target_isolate() const {
      ASSERT(IsLive());
      return target_isolate_;
    }

    IsolateGroup* target_isolate_group() const {
      ASSERT(IsLive());
      return target_isolate_group_;
    }

    // The Dart entrypoint for the callback, which the trampoline invokes.
    uword target_entry_point() const {
      ASSERT(IsLive());
      return target_entry_point_;
    }

    // The persistent handle to the closure that the NativeCallable.isolateLocal
    // is wrapping.
    PersistentHandle* closure_handle() const {
      ASSERT(IsLive());
      ASSERT(trampoline_type_ == TrampolineType::kSync ||
             trampoline_type_ == TrampolineType::kSyncStackDelta4 ||
             trampoline_type_ == TrampolineType::kSyncIsolateGroupBound ||
             trampoline_type_ ==
                 TrampolineType::kSyncIsolateGroupBoundStackDelta4);
      return reinterpret_cast<PersistentHandle*>(context_);
    }

    bool is_isolate_group_bound() const {
      return trampoline_type_ == TrampolineType::kSyncIsolateGroupBound ||
             trampoline_type_ ==
                 TrampolineType::kSyncIsolateGroupBoundStackDelta4;
    }
    // ApiState associated with an isolate group associated with this metadata.
    ApiState* api_state() const;

    // For async callbacks, this is the send port. For sync callbacks this is a
    // persistent handle to the callback's closure, or null.
    uint64_t context() const {
      ASSERT(IsLive());
      return context_;
    }

    // The send port that the async callback will send a message to.
    Dart_Port send_port() const {
      ASSERT(IsLive());
      ASSERT(trampoline_type_ == TrampolineType::kAsync);
      return static_cast<Dart_Port>(context_);
    }

    // Tells FfiCallbackTrampolineStub how to call into the entry point. Mostly
    // it's just a flag for whether this is a sync or async callback, but on
    // IA32 it also encodes whether there's a stack delta of 4 to deal with.
    TrampolineType trampoline_type() const { return trampoline_type_; }
  };

  // Metadata linked into a double-linked list.
  class MetadataEntry {
    Metadata metadata_;

    union {
      // IsLive()
      struct {
        // Links in the Isolate's list of callbacks.
        MetadataEntry* list_prev_;
        MetadataEntry* list_next_;
      };

      // !IsLive()
      MetadataEntry* free_list_next_;
    };

   public:
    friend class Metadata;
    friend class FfiCallbackMetadata;
    MetadataEntry(Isolate* target_isolate,
                  TrampolineType trampoline_type,
                  uword target_entry_point,
                  uint64_t context,
                  MetadataEntry* list_prev,
                  MetadataEntry* list_next)
        : metadata_(target_isolate,
                    trampoline_type,
                    target_entry_point,
                    context),
          list_prev_(list_prev),
          list_next_(list_next) {}

    MetadataEntry(IsolateGroup* target_isolate_group,
                  TrampolineType trampoline_type,
                  uword target_entry_point,
                  uint64_t context,
                  MetadataEntry* list_prev,
                  MetadataEntry* list_next)
        : metadata_(target_isolate_group,
                    trampoline_type,
                    target_entry_point,
                    context),
          list_prev_(list_prev),
          list_next_(list_next) {}

    // To efficiently delete all the callbacks for a isolate, they are stored in
    // a linked list. Since we also need to delete async callbacks at arbitrary
    // times, the list must be doubly linked.
    MetadataEntry* list_prev() {
      ASSERT(metadata_.IsLive());
      return list_prev_;
    }
    MetadataEntry* list_next() {
      ASSERT(metadata_.IsLive());
      return list_next_;
    }

    Metadata* metadata() { return &metadata_; }
  };

  // Returns the Metadata object for the given trampoline.
  Metadata LookupMetadataForTrampolineUnlocked(Trampoline trampoline) const;

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
#elif defined(DART_TARGET_OS_ANDROID) && defined(TARGET_ARCH_IS_64_BIT)
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
  //      - `NumCallbackTrampolinesPerPage()` x [MetadataEntry] objects
  static constexpr intptr_t RXMappingSize() { return 2 * kPageSize; }
  static constexpr intptr_t RWMappingSize() {
    return Utils::RoundUp(
        kNumRuntimeFunctions * compiler::target::kWordSize +
            sizeof(MetadataEntry) * NumCallbackTrampolinesPerPage(),
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
  static constexpr intptr_t kNativeCallbackSharedStubSize = 393;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_IA32)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 10;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 241;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 400;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 480;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_RISCV32)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 358;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_RISCV64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 8;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 358;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#else
#error What architecture?
#endif

  // Visible for testing.
#if defined(TESTING)

 public:
#else   // TESTING

 private:
#endif  // TESTING
  MetadataEntry* MetadataEntryOfTrampoline(Trampoline trampoline) const;
  Trampoline TrampolineOfMetadataEntry(MetadataEntry* metadata) const;

 private:
  FfiCallbackMetadata();
  ~FfiCallbackMetadata();
  void EnsureStubPageLocked();
  void AddToFreeListLocked(MetadataEntry* entry);
  void DeleteCallbackLocked(MetadataEntry* entry);
  void FillRuntimeFunction(VirtualMemory* page, uword index, void* function);
  VirtualMemory* AllocateTrampolinePage();
  void EnsureFreeListNotEmptyLocked();
  Trampoline CreateMetadataEntry(Isolate* target_isolate,
                                 IsolateGroup* target_isolate_group,
                                 TrampolineType trampoline_type,
                                 uword target_entry_point,
                                 uint64_t context,
                                 MetadataEntry** list_head);
  Trampoline CreateSyncFfiCallbackImpl(Isolate* isolate,
                                       IsolateGroup* isolate_group,
                                       Zone* zone,
                                       const Function& function,
                                       PersistentHandle* closure,
                                       MetadataEntry** list_head);
  Trampoline TryAllocateFromFreeListLocked();
  static uword GetEntryPoint(Zone* zone, const Function& function);
  static PersistentHandle* CreatePersistentHandle(IsolateGroup* isolate_group,
                                                  const Closure& closure);

  static FfiCallbackMetadata* singleton_;

  mutable Mutex lock_;
  VirtualMemory* stub_page_ = nullptr;
  MallocGrowableArray<VirtualMemory*> trampoline_pages_;
  uword offset_of_first_trampoline_in_page_ = 0;
  MetadataEntry* free_list_head_ = nullptr;
  MetadataEntry* free_list_tail_ = nullptr;

#if defined(DART_TARGET_OS_FUCHSIA) ||                                         \
    (defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64))
  // TODO(https://dartbug.com/52579): Remove.
  // On Fuchsia, we cannot duplicate the page containing the trampoline stub
  // unless we plumb through from the embedder the VMO handle that was used to
  // load the VM isolate snapshot.
  // On simulator FFI, SimulatorFfiCallbackTrampoline cannot be duplicated
  // because it contains a PC-relative call. It would need to be replaced with
  // something like normal stub's PC-relative loading to a corresponding data
  // page, or if we can assume the initial-exec code model a TLS load.
  VirtualMemory* original_metadata_page_ = nullptr;
#endif  // defined(DART_TARGET_OS_FUCHSIA)

  DISALLOW_COPY_AND_ASSIGN(FfiCallbackMetadata);
};

}  // namespace dart

#endif  // RUNTIME_VM_FFI_CALLBACK_METADATA_H_

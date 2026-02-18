// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ffi_callback_metadata.h"

#include "vm/allocation.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/dart_api_state.h"
#include "vm/flag_list.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"

namespace dart {

#if defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
extern "C" void SimulatorFfiCallbackTrampoline();
extern "C" void SimulatorFfiCallbackTrampolineEnd();
#endif

FfiCallbackMetadata::FfiCallbackMetadata() {}

void FfiCallbackMetadata::EnsureStubPageLocked() {
  ASSERT(lock_.IsOwnedByCurrentThread());
  if (stub_page_ != nullptr) {
    return;
  }

  ASSERT_LESS_OR_EQUAL(VirtualMemory::PageSize(), kPageSize);

#if defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
  uword code_start, code_end, page_start;
  if (FLAG_use_simulator) {
    code_start = reinterpret_cast<uword>(SimulatorFfiCallbackTrampoline);
    code_end = reinterpret_cast<uword>(SimulatorFfiCallbackTrampolineEnd);
    page_start = code_start & ~(VirtualMemory::PageSize() - 1);
  } else {
    const Code& trampoline_code = StubCode::FfiCallbackTrampoline();
    code_start = trampoline_code.EntryPoint();
    code_end = code_start + trampoline_code.Size();
    page_start = code_start & ~(VirtualMemory::PageSize() - 1);
    ASSERT_LESS_OR_EQUAL((code_start - page_start) + trampoline_code.Size(),
                         RXMappingSize());
  }
#else
  const Code& trampoline_code = StubCode::FfiCallbackTrampoline();
  const uword code_start = trampoline_code.EntryPoint();
  const uword code_end = code_start + trampoline_code.Size();
  const uword page_start = code_start & ~(VirtualMemory::PageSize() - 1);
  ASSERT_LESS_OR_EQUAL((code_start - page_start) + trampoline_code.Size(),
                       RXMappingSize());
#endif

  // Stub page uses a tight (unaligned) bound for the end of the code area.
  // Otherwise we can read past the end of the code area when doing DuplicateRX.
  stub_page_ = VirtualMemory::ForImagePage(reinterpret_cast<void*>(page_start),
                                           code_end - page_start);

  offset_of_first_trampoline_in_page_ = code_start - page_start;

#if defined(DART_TARGET_OS_FUCHSIA)
  // On Fuchsia we can't currently duplicate pages, so use the first page of
  // trampolines. Store the stub page's metadata in a separately allocated RW
  // page.
  // TODO(https://dartbug.com/52579): Remove.
  original_metadata_page_ = VirtualMemory::AllocateAligned(
      MappingSize(), MappingAlignment(), /*is_executable=*/false,
      /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
  MetadataEntry* metadata_entry = reinterpret_cast<MetadataEntry*>(
      original_metadata_page_->start() + MetadataOffset());
  for (intptr_t i = 0; i < NumCallbackTrampolinesPerPage(); ++i) {
    AddToFreeListLocked(&metadata_entry[i]);
  }
#elif defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
  if (FLAG_use_simulator) {
    original_metadata_page_ = VirtualMemory::AllocateAligned(
        MappingSize(), MappingAlignment(), /*is_executable=*/false,
        /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
    MetadataEntry* metadata_entry = reinterpret_cast<MetadataEntry*>(
        original_metadata_page_->start() + MetadataOffset());
    for (intptr_t i = 0; i < NumCallbackTrampolinesPerPage(); ++i) {
      AddToFreeListLocked(&metadata_entry[i]);
    }
  }
#endif  // defined(DART_TARGET_OS_FUCHSIA)
}

FfiCallbackMetadata::~FfiCallbackMetadata() {
  // Unmap all the trampoline pages. 'VirtualMemory's are new-allocated.
  delete stub_page_;
  for (intptr_t i = 0; i < trampoline_pages_.length(); ++i) {
    delete trampoline_pages_[i];
  }

#if defined(DART_TARGET_OS_FUCHSIA) ||                                         \
    (defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64))
  // TODO(https://dartbug.com/52579): Remove.
  delete original_metadata_page_;
#endif  // defined(DART_TARGET_OS_FUCHSIA)
}

void FfiCallbackMetadata::Init() {
  ASSERT(singleton_ == nullptr);
  singleton_ = new FfiCallbackMetadata();
}

void FfiCallbackMetadata::Cleanup() {
  ASSERT(singleton_ != nullptr);
  delete singleton_;
  singleton_ = nullptr;
}

FfiCallbackMetadata* FfiCallbackMetadata::Instance() {
  ASSERT(singleton_ != nullptr);
  return singleton_;
}

namespace {
uword RXAreaStart(VirtualMemory* page) {
  return page->start() + page->OffsetToExecutableAlias();
}
}  // namespace

void FfiCallbackMetadata::FillRuntimeFunction(VirtualMemory* page,
                                              uword index,
                                              void* function) {
  void** slot = reinterpret_cast<void**>(RXAreaStart(page) +
                                         RuntimeFunctionOffset(index));
  *slot = function;
}

VirtualMemory* FfiCallbackMetadata::AllocateTrampolinePage() {
#if defined(DART_TARGET_OS_FUCHSIA)
  // TODO(https://dartbug.com/52579): Remove.
  UNREACHABLE();
  return nullptr;
#else
#if defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
  if (FLAG_use_simulator) {
    UNREACHABLE();
    return nullptr;
  }
#endif

#if defined(DART_HOST_OS_MACOS) && defined(DART_PRECOMPILED_RUNTIME)
  const bool should_remap_stub_page = true;
#else
  const bool should_remap_stub_page = false;  // No support for remapping.
#endif

#if defined(DART_HOST_OS_MACOS)
  // If we are not going to use vm_remap then we need to pass
  // is_executable=true so that pages get allocated with MAP_JIT flag or
  // using RX workarounds if necessary. Otherwise OS will kill us with a
  // codesigning violation if hardened runtime is enabled or we will simply
  // not be able to execute trampoline code.
  const bool is_executable = !should_remap_stub_page;
#else
  // On other operating systems we can simply flip RW->RX as necessary.
  const bool is_executable = false;
#endif

  VirtualMemory* new_page = VirtualMemory::AllocateAligned(
      MappingSize(), MappingAlignment(), is_executable,
      /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
  if (new_page == nullptr) {
    return nullptr;
  }

  if (should_remap_stub_page) {
#if defined(DART_HOST_OS_MACOS)
    if (!stub_page_->DuplicateRX(new_page)) {
      delete new_page;
      return nullptr;
    }
#else
    static_assert(!should_remap_stub_page,
                  "Remaping only supported on Mac OS X");
#endif
  } else {
    // If we are creating executable mapping then simply fill it with code by
    // copying the page.
    const intptr_t aligned_size =
        Utils::RoundUp(stub_page_->size(), VirtualMemory::PageSize());
    ASSERT(new_page->start() >= stub_page_->end() ||
           new_page->end() <= stub_page_->start());
    memcpy(new_page->address(), stub_page_->address(),  // NOLINT
           stub_page_->size());

    VirtualMemory::WriteProtectCode(new_page->address(), aligned_size);
    if (VirtualMemory::ShouldDualMapExecutablePages()) {
      ASSERT(new_page->OffsetToExecutableAlias() != 0);
      VirtualMemory::Protect(
          reinterpret_cast<void*>(RXAreaStart(new_page) + RXMappingSize()),
          RWMappingSize(), VirtualMemory::kReadWrite);
    }
  }

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    DisassembleToStdout formatter;
    THR_Print("Code for duplicated stub 'FfiCallbackTrampoline' {\n");
    const uword code_start =
        RXAreaStart(new_page) + offset_of_first_trampoline_in_page_;
    Disassembler::Disassemble(code_start, code_start + kPageSize, &formatter,
                              /*comments=*/nullptr);
    THR_Print("}\n");
  }
#endif

  return new_page;
#endif  // defined(DART_TARGET_OS_FUCHSIA)
}

void FfiCallbackMetadata::EnsureFreeListNotEmptyLocked() {
  ASSERT(lock_.IsOwnedByCurrentThread());
  EnsureStubPageLocked();

  if (free_list_head_ != nullptr) {
    return;
  }

  VirtualMemory* new_page = AllocateTrampolinePage();
  if (new_page == nullptr) {
    Exceptions::ThrowOOM();
  }
  trampoline_pages_.Add(new_page);

  // Fill in the runtime functions.
  FillRuntimeFunction(new_page, kGetFfiCallbackMetadata,
                      reinterpret_cast<void*>(DLRT_GetFfiCallbackMetadata));
  FillRuntimeFunction(new_page, kExitTemporaryIsolate,
                      reinterpret_cast<void*>(DLRT_ExitTemporaryIsolate));
  FillRuntimeFunction(
      new_page, kExitIsolateGroupBoundIsolate,
      reinterpret_cast<void*>(DLRT_ExitIsolateGroupBoundIsolate));
  FillRuntimeFunction(
      new_page, kExitSyncCallbackTargetIsolate,
      reinterpret_cast<void*>(DLRT_ExitSyncCallbackTargetIsolate));

  // Add all the trampolines to the free list.
  const intptr_t trampolines_per_page = NumCallbackTrampolinesPerPage();
  MetadataEntry* metadata_entry = reinterpret_cast<MetadataEntry*>(
      RXAreaStart(new_page) + MetadataOffset());
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    AddToFreeListLocked(&metadata_entry[i]);
  }
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateMetadataEntry(
    Isolate* target_isolate,
    IsolateGroup* target_isolate_group,
    TrampolineType trampoline_type,
    uword target_entry_point,
    uint64_t context,
    MetadataEntry** list_head) {
  MutexLocker locker(&lock_);
  EnsureFreeListNotEmptyLocked();
  ASSERT(free_list_head_ != nullptr);
  MetadataEntry* entry = free_list_head_;
  free_list_head_ = entry->free_list_next_;
  if (free_list_head_ == nullptr) {
    ASSERT(free_list_tail_ == entry);
    free_list_tail_ = nullptr;
  }
  MetadataEntry* next_entry = *list_head;
  if (next_entry != nullptr) {
    ASSERT(next_entry->list_prev_ == nullptr);
    next_entry->list_prev_ = entry;
  }
  if (target_isolate != nullptr) {
    *entry = MetadataEntry(target_isolate, trampoline_type, target_entry_point,
                           context, nullptr, next_entry);
  } else {
    ASSERT(target_isolate_group != nullptr);
    *entry = MetadataEntry(target_isolate_group, trampoline_type,
                           target_entry_point, context, nullptr, next_entry);
  }
  *list_head = entry;
  return TrampolineOfMetadataEntry(entry);
}

void FfiCallbackMetadata::AddToFreeListLocked(MetadataEntry* entry) {
  ASSERT(lock_.IsOwnedByCurrentThread());
  if (free_list_tail_ == nullptr) {
    ASSERT(free_list_head_ == nullptr);
    free_list_head_ = free_list_tail_ = entry;
  } else {
    ASSERT(free_list_head_ != nullptr && free_list_tail_ != nullptr);
    ASSERT(!free_list_tail_->metadata()->IsLive());
    free_list_tail_->free_list_next_ = entry;
    free_list_tail_ = entry;
  }
  entry->metadata()->context_ = 0;
  entry->metadata()->target_isolate_ = nullptr;
  entry->free_list_next_ = nullptr;
}

void FfiCallbackMetadata::DeleteCallbackLocked(MetadataEntry* entry) {
  ASSERT(lock_.IsOwnedByCurrentThread());
  if (entry->metadata()->trampoline_type_ != TrampolineType::kAsync &&
      entry->metadata()->context_ != 0) {
    ASSERT(entry->metadata()->target_isolate_ != nullptr);
    entry->metadata()->api_state()->FreePersistentHandle(
        entry->metadata()->closure_handle());
  }
  AddToFreeListLocked(entry);
}

void FfiCallbackMetadata::DeleteAllCallbacks(MetadataEntry** list_head) {
  MutexLocker locker(&lock_);
  for (MetadataEntry* entry = *list_head; entry != nullptr;) {
    MetadataEntry* next = entry->list_next();
    DeleteCallbackLocked(entry);
    entry = next;
  }
  *list_head = nullptr;
}

void FfiCallbackMetadata::DeleteCallback(Trampoline trampoline,
                                         MetadataEntry** list_head) {
  MutexLocker locker(&lock_);
  auto* entry = MetadataEntryOfTrampoline(trampoline);
  ASSERT(entry->metadata()->IsLive());
  auto* prev = entry->list_prev_;
  auto* next = entry->list_next_;
  if (prev != nullptr) {
    prev->list_next_ = next;
  } else {
    ASSERT(*list_head == entry);
    *list_head = next;
  }
  if (next != nullptr) {
    next->list_prev_ = prev;
  }
  DeleteCallbackLocked(entry);
}

uword FfiCallbackMetadata::GetEntryPoint(Zone* zone, const Function& function) {
  const auto& code =
      Code::Handle(zone, FLAG_precompiled_mode ? function.CurrentCode()
                                               : function.EnsureHasCode());
  ASSERT(!code.IsNull());
  return code.EntryPoint();
}

PersistentHandle* FfiCallbackMetadata::CreatePersistentHandle(
    IsolateGroup* isolate_group,
    const Closure& closure) {
  auto* api_state = isolate_group->api_state();
  ASSERT(api_state != nullptr);
  auto* handle = api_state->AllocatePersistentHandle();
  handle->set_ptr(closure);
  return handle;
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateLocalFfiCallback(
    Isolate* isolate,
    IsolateGroup* isolate_group,
    Zone* zone,
    const Function& function,
    const Closure& closure,
    MetadataEntry** list_head) {
  PersistentHandle* handle = nullptr;
  if (closure.IsNull()) {
    // If the closure is null, it means the target is a static function, so is
    // baked into the trampoline and is an ordinary sync callback.
    ASSERT((isolate != nullptr && isolate_group == nullptr &&
            function.GetFfiCallbackKind() ==
                FfiCallbackKind::kIsolateLocalStaticCallback) ||
           (isolate == nullptr && isolate_group != nullptr &&
            function.GetFfiCallbackKind() ==
                FfiCallbackKind::kIsolateGroupBoundStaticCallback));
  } else {
    ASSERT((isolate != nullptr && isolate_group == nullptr &&
            function.GetFfiCallbackKind() ==
                FfiCallbackKind::kIsolateLocalClosureCallback) ||
           (isolate == nullptr && isolate_group != nullptr &&
            function.GetFfiCallbackKind() ==
                FfiCallbackKind::kIsolateGroupBoundClosureCallback));

    if (function.GetFfiCallbackKind() ==
        FfiCallbackKind::kIsolateGroupBoundClosureCallback) {
      closure.EnsureDeeplyImmutable(zone);
    }

    handle = CreatePersistentHandle(
        isolate != nullptr ? isolate->group() : isolate_group, closure);
  }
  return CreateSyncFfiCallbackImpl(isolate, isolate_group, zone, function,
                                   handle, list_head);
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateSyncFfiCallbackImpl(
    Isolate* isolate,
    IsolateGroup* isolate_group,
    Zone* zone,
    const Function& function,
    PersistentHandle* closure,
    MetadataEntry** list_head) {
  TrampolineType trampoline_type = isolate != nullptr
                                       ? TrampolineType::kSync
                                       : TrampolineType::kSyncIsolateGroupBound;

#if defined(TARGET_ARCH_IA32)
  // On ia32, store the stack delta that we need to use when returning.
  const intptr_t stack_return_delta =
      function.FfiCSignatureReturnsStruct() && CallingConventions::kUsesRet4
          ? compiler::target::kWordSize
          : 0;
  if (stack_return_delta != 0) {
    ASSERT(stack_return_delta == 4);
    trampoline_type = isolate != nullptr
                          ? TrampolineType::kSyncStackDelta4
                          : TrampolineType::kSyncIsolateGroupBoundStackDelta4;
  }
#endif

  return CreateMetadataEntry(isolate, isolate_group, trampoline_type,
                             GetEntryPoint(zone, function),
                             reinterpret_cast<uint64_t>(closure), list_head);
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateAsyncFfiCallback(
    Isolate* isolate,
    Zone* zone,
    const Function& send_function,
    Dart_Port send_port,
    MetadataEntry** list_head) {
  ASSERT(send_function.GetFfiCallbackKind() == FfiCallbackKind::kAsyncCallback);
  return CreateMetadataEntry(isolate, /*target_isolate_group=*/nullptr,
                             TrampolineType::kAsync,
                             GetEntryPoint(zone, send_function),
                             static_cast<uint64_t>(send_port), list_head);
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::TrampolineOfMetadataEntry(
    MetadataEntry* metadata_entry) const {
  const uword start = MappingStart(reinterpret_cast<uword>(metadata_entry));
  MetadataEntry* metadata_entries =
      reinterpret_cast<MetadataEntry*>(start + MetadataOffset());
  const uword index = metadata_entry - metadata_entries;
#if defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
  if (FLAG_use_simulator) {
    return reinterpret_cast<uword>(SimulatorFfiCallbackTrampoline) +
           index * kNativeCallbackTrampolineSize;
  } else {
    return start + offset_of_first_trampoline_in_page_ +
           index * kNativeCallbackTrampolineSize;
  }
#elif defined(DART_TARGET_OS_FUCHSIA)
  return StubCode::FfiCallbackTrampoline().EntryPoint() +
         index * kNativeCallbackTrampolineSize;
#else
  return start + offset_of_first_trampoline_in_page_ +
         index * kNativeCallbackTrampolineSize;
#endif
}

FfiCallbackMetadata::MetadataEntry*
FfiCallbackMetadata::MetadataEntryOfTrampoline(Trampoline trampoline) const {
#if defined(DART_TARGET_OS_FUCHSIA)
  // On Fuchsia the metadata page is separate to the trampoline page.
  // TODO(https://dartbug.com/52579): Remove.
  const uword page_start =
      Utils::RoundDown(trampoline - offset_of_first_trampoline_in_page_,
                       VirtualMemory::PageSize());
  const uword index =
      (trampoline - offset_of_first_trampoline_in_page_ - page_start) /
      kNativeCallbackTrampolineSize;
  ASSERT(index < NumCallbackTrampolinesPerPage());
  MetadataEntry* metadata_etnry_table = reinterpret_cast<MetadataEntry*>(
      original_metadata_page_->start() + MetadataOffset());
  return metadata_etnry_table + index;
#elif defined(SIMULATOR_FFI) && defined(HOST_ARCH_ARM64)
  if (FLAG_use_simulator) {
    const uword page_start =
        Utils::RoundDown(trampoline - offset_of_first_trampoline_in_page_,
                         VirtualMemory::PageSize());
    const uword index =
        (trampoline - offset_of_first_trampoline_in_page_ - page_start) /
        kNativeCallbackTrampolineSize;
    ASSERT(index < NumCallbackTrampolinesPerPage());
    MetadataEntry* metadata_etnry_table = reinterpret_cast<MetadataEntry*>(
        original_metadata_page_->start() + MetadataOffset());
    return metadata_etnry_table + index;
  } else {
    const uword start = MappingStart(trampoline);
    MetadataEntry* metadata_entries =
        reinterpret_cast<MetadataEntry*>(start + MetadataOffset());
    const uword index =
        (trampoline - start - offset_of_first_trampoline_in_page_) /
        kNativeCallbackTrampolineSize;
    return &metadata_entries[index];
  }
#else
  const uword start = MappingStart(trampoline);
  MetadataEntry* metadata_entries =
      reinterpret_cast<MetadataEntry*>(start + MetadataOffset());
  const uword index =
      (trampoline - start - offset_of_first_trampoline_in_page_) /
      kNativeCallbackTrampolineSize;
  return &metadata_entries[index];
#endif
}

FfiCallbackMetadata::Metadata
FfiCallbackMetadata::LookupMetadataForTrampolineUnlocked(
    Trampoline trampoline) const {
  return *MetadataEntryOfTrampoline(trampoline)->metadata();
}

FfiCallbackMetadata* FfiCallbackMetadata::singleton_ = nullptr;

ApiState* FfiCallbackMetadata::Metadata::api_state() const {
  return (is_isolate_group_bound() ? target_isolate_group_
                                   : target_isolate_->group())
      ->api_state();
}

}  // namespace dart

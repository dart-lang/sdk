// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ffi_callback_metadata.h"

#include "vm/flag_list.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"

namespace dart {

FfiCallbackMetadata::FfiCallbackMetadata() {}

void FfiCallbackMetadata::EnsureStubPageLocked() {
  // Assumes lock_ is already locked for writing.
  if (stub_page_ != nullptr) {
    return;
  }

  ASSERT_LESS_OR_EQUAL(VirtualMemory::PageSize(), kPageSize);

  const Code& trampoline_code = StubCode::FfiCallbackTrampoline();
  const uword code_start = trampoline_code.EntryPoint();
  const uword page_start = code_start & kPageMask;
  offset_of_first_trampoline_in_page_ = code_start - page_start;

  ASSERT_LESS_OR_EQUAL((code_start - page_start) + trampoline_code.Size(),
                       RXMappingSize());

  stub_page_ = VirtualMemory::ForImagePage(reinterpret_cast<void*>(page_start),
                                           RXMappingSize());

#if defined(DART_TARGET_OS_FUCHSIA)
  // On Fuchsia we can't currently duplicate pages, so use the first page of
  // trampolines. Store the stub page's metadata in a separately allocated RW
  // page.
  // TODO(https://dartbug.com/52579): Remove.
  fuchsia_metadata_page_ = VirtualMemory::AllocateAligned(
      MappingSize(), MappingAlignment(), /*is_executable=*/false,
      /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
  Metadata* metadata = reinterpret_cast<Metadata*>(
      fuchsia_metadata_page_->start() + MetadataOffset());
  for (intptr_t i = 0; i < NumCallbackTrampolinesPerPage(); ++i) {
    AddToFreeListLocked(&metadata[i]);
  }
#endif  // defined(DART_TARGET_OS_FUCHSIA)
}

FfiCallbackMetadata::~FfiCallbackMetadata() {
  // Unmap all the trampoline pages. 'VirtualMemory's are new-allocated.
  delete stub_page_;
  for (intptr_t i = 0; i < trampoline_pages_.length(); ++i) {
    delete trampoline_pages_[i];
  }

#if defined(DART_TARGET_OS_FUCHSIA)
  // TODO(https://dartbug.com/52579): Remove.
  delete fuchsia_metadata_page_;
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

void FfiCallbackMetadata::FillRuntimeFunction(VirtualMemory* page,
                                              uword index,
                                              void* function) {
  void** slot =
      reinterpret_cast<void**>(page->start() + RuntimeFunctionOffset(index));
  *slot = function;
}

VirtualMemory* FfiCallbackMetadata::AllocateTrampolinePage() {
#if defined(DART_TARGET_OS_FUCHSIA)
  return nullptr;
#else
  VirtualMemory* new_page = VirtualMemory::AllocateAligned(
      MappingSize(), MappingAlignment(), /*is_executable=*/false,
      /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
  if (new_page == nullptr) {
    return nullptr;
  }

  if (!stub_page_->DuplicateRX(new_page)) {
    delete new_page;
    return nullptr;
  }

  return new_page;
#endif  // defined(DART_TARGET_OS_FUCHSIA)
}

void FfiCallbackMetadata::EnsureFreeListNotEmptyLocked() {
  EnsureStubPageLocked();

  // Assumes lock_ is already locked for writing.
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

  // Add all the trampolines to the free list.
  const intptr_t trampolines_per_page = NumCallbackTrampolinesPerPage();
  Metadata* metadata =
      reinterpret_cast<Metadata*>(new_page->start() + MetadataOffset());
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    AddToFreeListLocked(&metadata[i]);
  }
}

FfiCallbackMetadata::Metadata* FfiCallbackMetadata::AllocateTrampolineLocked() {
  // Assumes lock_ is already locked for writing.
  EnsureFreeListNotEmptyLocked();
  ASSERT(free_list_head_ != nullptr);
  Metadata* entry = free_list_head_;
  free_list_head_ = entry->free_list_next_;
  if (free_list_head_ == nullptr) {
    ASSERT(free_list_tail_ == entry);
    free_list_tail_ = nullptr;
  }
  return entry;
}

void FfiCallbackMetadata::AddToFreeListLocked(Metadata* entry) {
  // Assumes lock_ is already locked for writing.
  if (free_list_tail_ == nullptr) {
    ASSERT(free_list_head_ == nullptr);
    free_list_head_ = free_list_tail_ = entry;
  } else {
    ASSERT(free_list_head_ != nullptr && free_list_tail_ != nullptr);
    ASSERT(!free_list_tail_->IsLive());
    free_list_tail_->free_list_next_ = entry;
    free_list_tail_ = entry;
  }
  entry->target_isolate_ = nullptr;
  entry->free_list_next_ = nullptr;
}

void FfiCallbackMetadata::DeleteSyncTrampolines(Metadata** sync_list_head) {
  WriteRwLocker locker(Thread::Current(), &lock_);
  for (Metadata* entry = *sync_list_head; entry != nullptr;) {
    Metadata* next = entry->sync_list_next();
    AddToFreeListLocked(entry);
    entry = next;
  }
  *sync_list_head = nullptr;
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateFfiCallback(
    Isolate* isolate,
    Zone* zone,
    const Function& function,
    Metadata** sync_list_head) {
  const auto& code =
      Code::Handle(zone, FLAG_precompiled_mode ? function.CurrentCode()
                                               : function.EnsureHasCode());
  ASSERT(!code.IsNull());

  const uword target_entry_point = code.EntryPoint();
  TrampolineType trampoline_type = TrampolineType::kSync;

#if defined(TARGET_ARCH_IA32)
  // On ia32, store the stack delta that we need to use when returning.
  const intptr_t stack_return_delta =
      function.FfiCSignatureReturnsStruct() && CallingConventions::kUsesRet4
          ? compiler::target::kWordSize
          : 0;
  if (stack_return_delta != 0) {
    ASSERT(stack_return_delta == 4);
    trampoline_type = TrampolineType::kSyncStackDelta4;
  }
#endif

  WriteRwLocker locker(Thread::Current(), &lock_);
  Metadata* entry = AllocateTrampolineLocked();
  Metadata* sync_list_next = *sync_list_head;
  *sync_list_head = entry;
  *entry =
      Metadata(isolate, target_entry_point, sync_list_next, trampoline_type);

  return TrampolineOfMetadata(entry);
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateSyncFfiCallback(
    Isolate* isolate,
    Zone* zone,
    const Function& function,
    Metadata** sync_list_head) {
  return CreateFfiCallback(isolate, zone, function, sync_list_head);
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::TrampolineOfMetadata(
    Metadata* metadata) const {
  const uword start = MappingStart(reinterpret_cast<uword>(metadata));
  Metadata* metadatas = reinterpret_cast<Metadata*>(start + MetadataOffset());
  const uword index = (metadata - metadatas);
#if defined(DART_TARGET_OS_FUCHSIA)
  return StubCode::FfiCallbackTrampoline().EntryPoint() +
         index * kNativeCallbackTrampolineSize;
#else
  return start + offset_of_first_trampoline_in_page_ +
         index * kNativeCallbackTrampolineSize;
#endif
}

FfiCallbackMetadata::Metadata* FfiCallbackMetadata::MetadataOfTrampoline(
    Trampoline trampoline) const {
#if defined(DART_TARGET_OS_FUCHSIA)
  // On Fuchsia the metadata page is separate to the trampoline page.
  // TODO(https://dartbug.com/52579): Remove.
  const uword page_start = Utils::RoundDown(
      trampoline - offset_of_first_trampoline_in_page_, kPageSize);
  const uword index =
      (trampoline - offset_of_first_trampoline_in_page_ - page_start) /
      kNativeCallbackTrampolineSize;
  ASSERT(index < NumCallbackTrampolinesPerPage());
  Metadata* metadata_table = reinterpret_cast<Metadata*>(
      fuchsia_metadata_page_->start() + MetadataOffset());
  return metadata_table + index;
#else
  const uword start = MappingStart(trampoline);
  Metadata* metadatas = reinterpret_cast<Metadata*>(start + MetadataOffset());
  const uword index =
      (trampoline - start - offset_of_first_trampoline_in_page_) /
      kNativeCallbackTrampolineSize;
  return &metadatas[index];
#endif
}

FfiCallbackMetadata::Metadata FfiCallbackMetadata::LookupMetadataForTrampoline(
    Trampoline trampoline) const {
  // Note: The locker's thread may be null because this method is explicitly
  // designed to be usable outside of a VM thread.
  ReadRwLocker locker(Thread::Current(), &lock_);
  return *MetadataOfTrampoline(trampoline);
}

FfiCallbackMetadata* FfiCallbackMetadata::singleton_ = nullptr;

}  // namespace dart

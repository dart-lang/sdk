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

  // Keep in sync with GenerateLoadFfiCallbackMetadataRuntimeFunction.

  // The FfiCallbackTrampoline stub is designed to take up 1 page of memory. At
  // the moment it's not aligned though, so we need to do some alignment math
  // here. So when we duplicate it below, we're wasting some memory because the
  // stub probably straddles 2 aligned pages. It would be better to align the
  // stub inside the stub code compiler, but we don't have a way of doing that
  // at the moment.
  // TODO(52498): Align the stub.

  // |      page       |      page     |                pages               |
  // [ alignment ][ stub ][ alignment ][ functions ][ metadata ][ alignment ]
  ASSERT_LESS_OR_EQUAL(VirtualMemory::PageSize(), kPageSize);
  const Code& trampoline_code = StubCode::FfiCallbackTrampoline();

  const uword code_start = trampoline_code.EntryPoint();
  const uword page_start = Utils::RoundDown(code_start, kPageSize);
  const uword code_end_aligned = page_start + 2 * kPageSize;
  ASSERT_LESS_OR_EQUAL(code_start + trampoline_code.Size(), code_end_aligned);

  const uword functions_start = code_end_aligned;
  const uword functions_size =
      kNumRuntimeFunctions * compiler::target::kWordSize;

  const uword metadata_start = functions_start + functions_size;
  const uword metadata_size =
      NumCallbackTrampolinesPerPage() * sizeof(Metadata);
  const uword metadata_end = metadata_start + metadata_size;
  const uword page_end = Utils::RoundUp(metadata_end, kPageSize);

  stub_page_ = VirtualMemory::ForImagePage(reinterpret_cast<void*>(page_start),
                                           code_end_aligned - page_start);
  offset_of_first_trampoline_in_page_ = code_start - page_start;
  offset_of_first_runtime_function_in_page_ = functions_start - page_start;
  offset_of_first_metadata_in_page_ = metadata_start - page_start;
  size_of_trampoline_page_ = page_end - page_start;
}

FfiCallbackMetadata::~FfiCallbackMetadata() {
  // Unmap all the trampoline pages. 'VirtualMemory's are new-allocated.
  delete stub_page_;
  for (intptr_t i = 0; i < trampoline_pages_.length(); ++i) {
    delete trampoline_pages_[i];
  }
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
  uword offset = offset_of_first_runtime_function_in_page_ +
                 index * compiler::target::kWordSize;
  void** slot = reinterpret_cast<void**>(page->start() + offset);
  *slot = function;
}

VirtualMemory* FfiCallbackMetadata::AllocateTrampolinePage() {
  VirtualMemory* new_page = VirtualMemory::AllocateAligned(
      size_of_trampoline_page_, kPageSize, /*is_executable=*/false,
      /*is_compressed=*/false, "FfiCallbackMetadata::TrampolinePage");
  if (new_page == nullptr) {
    return nullptr;
  }

  if (!stub_page_->DuplicateRX(new_page)) {
    delete new_page;
    return nullptr;
  }

  return new_page;
}

void FfiCallbackMetadata::EnsureFreeListNotEmptyLocked() {
  // Assumes lock_ is already locked for writing.
  if (free_list_head_ != nullptr) {
    return;
  }

  EnsureStubPageLocked();
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
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    const Trampoline trampoline = reinterpret_cast<Trampoline>(
        new_page->start() + offset_of_first_trampoline_in_page_ +
        i * kNativeCallbackTrampolineSize);
    AddToFreeListLocked(trampoline, LookupEntryLocked(trampoline));
  }
}

FfiCallbackMetadata::Trampoline
FfiCallbackMetadata::AllocateTrampolineLocked() {
  // Assumes lock_ is already locked for writing.
  EnsureFreeListNotEmptyLocked();
  ASSERT(free_list_head_ != nullptr);
  const Trampoline trampoline = free_list_head_;
  auto* entry = LookupEntryLocked(trampoline);
  free_list_head_ = entry->free_list_next_;
  if (free_list_head_ == nullptr) {
    ASSERT(free_list_tail_ == trampoline);
    free_list_tail_ = nullptr;
  }
  return trampoline;
}

void FfiCallbackMetadata::AddToFreeListLocked(Trampoline trampoline,
                                              Metadata* entry) {
  // Assumes lock_ is already locked for writing.
  if (free_list_tail_ == nullptr) {
    ASSERT(free_list_head_ == nullptr);
    free_list_head_ = free_list_tail_ = trampoline;
  } else {
    ASSERT(free_list_head_ != nullptr);
    auto* tail = LookupEntryLocked(free_list_tail_);
    ASSERT(!tail->IsLive());
    ASSERT(tail->free_list_next_ == nullptr);
    tail->free_list_next_ = trampoline;
    free_list_tail_ = trampoline;
  }
  entry->target_isolate_ = nullptr;
  entry->free_list_next_ = nullptr;
}

void FfiCallbackMetadata::DeleteSyncTrampolines(Trampoline* sync_list_head) {
  WriteRwLocker locker(Thread::Current(), &lock_);
  for (Trampoline trampoline = *sync_list_head; trampoline != nullptr;) {
    auto* entry = LookupEntryLocked(trampoline);
    ASSERT(entry != nullptr);
    const Trampoline next_trampoline = entry->sync_list_next();
    AddToFreeListLocked(trampoline, entry);
    trampoline = next_trampoline;
  }
  *sync_list_head = nullptr;
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateFfiCallback(
    Isolate* isolate,
    Zone* zone,
    const Function& function,
    Trampoline* sync_list_head) {
  const auto& code =
      Code::Handle(zone, FLAG_precompiled_mode ? function.CurrentCode()
                                               : function.EnsureHasCode());
  ASSERT(!code.IsNull());

  const uword target_entry_point = code.EntryPoint();
  const Trampoline sync_list_next = *sync_list_head;
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
  const Trampoline trampoline = AllocateTrampolineLocked();
  *sync_list_head = trampoline;
  *LookupEntryLocked(trampoline) =
      Metadata(isolate, target_entry_point, sync_list_next, trampoline_type);

  return trampoline;
}

FfiCallbackMetadata::Trampoline FfiCallbackMetadata::CreateSyncFfiCallback(
    Isolate* isolate,
    Zone* zone,
    const Function& function,
    Trampoline* sync_list_head) {
  return CreateFfiCallback(isolate, zone, function, sync_list_head);
}

FfiCallbackMetadata::Metadata* FfiCallbackMetadata::LookupEntryLocked(
    Trampoline trampoline) const {
  // Assumes lock_ is already locked for reading or writing.
  const uword location = reinterpret_cast<uword>(trampoline);

  // The location that the trampoline would be if the code page was aligned.
  const uword aligned_location = location - offset_of_first_trampoline_in_page_;

  // Since the code page isn't aligned, the trampoline may actually be in the
  // following page. So round down the aligned_location, not the raw location.
  const uword page_start = Utils::RoundDown(aligned_location, kPageSize);

  const uword offset = aligned_location - page_start;
  ASSERT_EQUAL(offset % kNativeCallbackTrampolineSize, 0);

  const intptr_t index = offset / kNativeCallbackTrampolineSize;
  ASSERT(index < NumCallbackTrampolinesPerPage());

  const uword metadata_table = page_start + offset_of_first_metadata_in_page_;
  return reinterpret_cast<Metadata*>(metadata_table) + index;
}

FfiCallbackMetadata::Metadata FfiCallbackMetadata::LookupMetadataForTrampoline(
    Trampoline trampoline) const {
  // Note: The locker's thread may be null because this method is explicitly
  // designed to be usable outside of a VM thread.
  ReadRwLocker locker(Thread::Current(), &lock_);
  return *LookupEntryLocked(trampoline);
}

FfiCallbackMetadata* FfiCallbackMetadata::singleton_ = nullptr;

}  // namespace dart

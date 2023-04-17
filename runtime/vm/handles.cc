// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/handles.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"
#include "vm/zone.h"

#include "vm/handles_impl.h"

namespace dart {

void VMHandles::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  return Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                 kOffsetOfRawPtr>::VisitObjectPointers(visitor);
}

#if defined(DEBUG)
static bool IsCurrentApiNativeScope(Zone* zone) {
  ApiNativeScope* scope = ApiNativeScope::Current();
  return (scope != nullptr) && (scope->zone() == zone);
}
#endif  // DEBUG

uword VMHandles::AllocateHandle(Zone* zone) {
  DEBUG_ASSERT(!IsCurrentApiNativeScope(zone));
  uword handle = Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                         kOffsetOfRawPtr>::AllocateHandle(zone);
#if defined(DEBUG)
  *reinterpret_cast<uword*>(handle + kOffsetOfIsZoneHandle * kWordSize) = 0;
#endif
  return handle;
}

uword VMHandles::AllocateZoneHandle(Zone* zone) {
  DEBUG_ASSERT(!IsCurrentApiNativeScope(zone));
  uword handle = Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                         kOffsetOfRawPtr>::AllocateZoneHandle(zone);
#if defined(DEBUG)
  *reinterpret_cast<uword*>(handle + kOffsetOfIsZoneHandle * kWordSize) = 1;
#endif
  return handle;
}

#if defined(DEBUG)
bool VMHandles::IsZoneHandle(uword handle) {
  return *reinterpret_cast<uword*>(handle +
                                   kOffsetOfIsZoneHandle * kWordSize) != 0;
}
#endif

int VMHandles::ScopedHandleCount() {
  Thread* thread = Thread::Current();
  ASSERT(thread->zone() != nullptr);
  VMHandles* handles = thread->zone()->handles();
  return handles->CountScopedHandles();
}

int VMHandles::ZoneHandleCount() {
  Thread* thread = Thread::Current();
  ASSERT(thread->zone() != nullptr);
  VMHandles* handles = thread->zone()->handles();
  return handles->CountZoneHandles();
}

void HandleScope::Initialize() {
  ASSERT(thread()->MayAllocateHandles());
  VMHandles* handles = thread()->zone()->handles();
  ASSERT(handles != nullptr);
  saved_handle_block_ = handles->scoped_blocks_;
  saved_handle_slot_ = handles->scoped_blocks_->next_handle_slot();
#if defined(DEBUG)
  link_ = thread()->top_handle_scope();
  thread()->set_top_handle_scope(this);
#endif
}

HandleScope::HandleScope(ThreadState* thread) : StackResource(thread) {
  Initialize();
}

HandleScope::~HandleScope() {
  ASSERT(thread()->zone() != nullptr);
  VMHandles* handles = thread()->zone()->handles();
  ASSERT(handles != nullptr);
#if defined(DEBUG)
  VMHandles::HandlesBlock* last = handles->scoped_blocks_;
#endif
  handles->scoped_blocks_ = saved_handle_block_;
  handles->scoped_blocks_->set_next_handle_slot(saved_handle_slot_);
#if defined(DEBUG)
  VMHandles::HandlesBlock* block = handles->scoped_blocks_;
  for (;;) {
    block->ZapFreeHandles();
    if (block == last) break;
    block = block->next_block();
  }
  ASSERT(thread()->top_handle_scope() == this);
  thread()->set_top_handle_scope(link_);
#endif
}

}  // namespace dart

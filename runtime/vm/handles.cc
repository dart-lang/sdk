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

DEFINE_FLAG(bool, verify_handles, false, "Verify handles.");

VMHandles::~VMHandles() {
  if (FLAG_trace_handles) {
    OS::PrintErr("***   Handle Counts for 0x(%" Px "):Zone = %d,Scoped = %d\n",
                 reinterpret_cast<intptr_t>(this), CountZoneHandles(),
                 CountScopedHandles());
    OS::PrintErr("*** Deleting VM handle block 0x%" Px "\n",
                 reinterpret_cast<intptr_t>(this));
  }
}

void VMHandles::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  return Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                 kOffsetOfRawPtr>::VisitObjectPointers(visitor);
}

#if defined(DEBUG)
static bool IsCurrentApiNativeScope(Zone* zone) {
  ApiNativeScope* scope = ApiNativeScope::Current();
  return (scope != NULL) && (scope->zone() == zone);
}
#endif  // DEBUG

uword VMHandles::AllocateHandle(Zone* zone) {
  DEBUG_ASSERT(!IsCurrentApiNativeScope(zone));
  return Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                 kOffsetOfRawPtr>::AllocateHandle(zone);
}

uword VMHandles::AllocateZoneHandle(Zone* zone) {
  DEBUG_ASSERT(!IsCurrentApiNativeScope(zone));
  return Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                 kOffsetOfRawPtr>::AllocateZoneHandle(zone);
}

bool VMHandles::IsZoneHandle(uword handle) {
  return Handles<kVMHandleSizeInWords, kVMHandlesPerChunk,
                 kOffsetOfRawPtr>::IsZoneHandle(handle);
}

int VMHandles::ScopedHandleCount() {
  Thread* thread = Thread::Current();
  ASSERT(thread->zone() != NULL);
  VMHandles* handles = thread->zone()->handles();
  return handles->CountScopedHandles();
}

int VMHandles::ZoneHandleCount() {
  Thread* thread = Thread::Current();
  ASSERT(thread->zone() != NULL);
  VMHandles* handles = thread->zone()->handles();
  return handles->CountZoneHandles();
}

void HandleScope::Initialize() {
  ASSERT(thread()->no_handle_scope_depth() == 0);
  VMHandles* handles = thread()->zone()->handles();
  ASSERT(handles != NULL);
  saved_handle_block_ = handles->scoped_blocks_;
  saved_handle_slot_ = handles->scoped_blocks_->next_handle_slot();
#if defined(DEBUG)
  link_ = thread()->top_handle_scope();
  thread()->set_top_handle_scope(this);
#endif
}

HandleScope::HandleScope(Thread* thread) : StackResource(thread) {
  Initialize();
}

HandleScope::~HandleScope() {
  ASSERT(thread()->zone() != NULL);
  VMHandles* handles = thread()->zone()->handles();
  ASSERT(handles != NULL);
  handles->scoped_blocks_ = saved_handle_block_;
  handles->scoped_blocks_->set_next_handle_slot(saved_handle_slot_);
#if defined(DEBUG)
  handles->VerifyScopedHandleState();
  handles->ZapFreeScopedHandles();
  ASSERT(thread()->top_handle_scope() == this);
  thread()->set_top_handle_scope(link_);
#endif
}

#if defined(DEBUG)
NoHandleScope::NoHandleScope(Thread* thread) : StackResource(thread) {
  thread->IncrementNoHandleScopeDepth();
}

NoHandleScope::~NoHandleScope() {
  thread()->DecrementNoHandleScopeDepth();
}
#endif  // defined(DEBUG)

}  // namespace dart

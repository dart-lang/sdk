// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/compiler_stats.h"
#include "vm/flags.h"
#include "vm/heap_profiler.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os.h"
#include "vm/pages.h"
#include "vm/scavenger.h"
#include "vm/stack_frame.h"
#include "vm/verifier.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(bool, verbose_gc, false, "Enables verbose GC.");
DEFINE_FLAG(bool, verify_before_gc, false,
            "Enables heap verification before GC.");
DEFINE_FLAG(bool, verify_after_gc, false,
            "Enables heap verification after GC.");
DEFINE_FLAG(bool, gc_at_alloc, false, "GC at every allocation.");
DEFINE_FLAG(int, new_gen_heap_size, 32, "new gen heap size in MB,"
            "e.g: --new_gen_heap_size=64 allocates a 64MB new gen heap");
DEFINE_FLAG(int, old_gen_heap_size, Heap::kHeapSizeInMB,
            "old gen heap size in MB,"
            "e.g: --old_gen_heap_size=1024 allocates a 1024MB old gen heap");
DEFINE_FLAG(int, code_heap_size, Heap::kCodeHeapSizeInMB,
            "code heap size in MB,"
            "e.g: --code_heap_size=8 allocates a 8MB code heap");

  Heap::Heap() : read_only_(false) {
  new_space_ = new Scavenger(this,
                             (FLAG_new_gen_heap_size * MB),
                             kNewObjectAlignmentOffset);
  old_space_ = new PageSpace(this, (FLAG_old_gen_heap_size * MB));
  code_space_ = new PageSpace(this, (FLAG_code_heap_size * MB), true);
}


Heap::~Heap() {
  delete new_space_;
  delete old_space_;
  delete code_space_;
}


uword Heap::AllocateNew(intptr_t size) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  uword addr = new_space_->TryAllocate(size);
  if (addr != 0) {
    return addr;
  }
  CollectGarbage(kNew);
  addr = new_space_->TryAllocate(size);
  if (addr != 0) {
    return addr;
  }
  return AllocateOld(size);
}


uword Heap::AllocateOld(intptr_t size) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  uword addr = old_space_->TryAllocate(size);
  if (addr == 0) {
    CollectAllGarbage();
    addr = old_space_->TryAllocate(size, PageSpace::kForceGrowth);
    if (addr == 0) {
      OS::PrintErr("Exhausted heap space, trying to allocate %"Pd" bytes.\n",
                   size);
    }
  }
  return addr;
}


uword Heap::AllocateCode(PageSpace* space, intptr_t size) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  ASSERT(Utils::IsAligned(size, OS::PreferredCodeAlignment()));
  uword addr = space->TryAllocate(size);
  if (addr == 0) {
    // TODO(iposva): Support GC.
    FATAL("Exhausted code heap space.");
  }
  if (FLAG_compiler_stats) {
    CompilerStats::code_allocated += size;
  }
  return addr;
}


bool Heap::Contains(uword addr) const {
  return new_space_->Contains(addr) ||
      old_space_->Contains(addr) ||
      code_space_->Contains(addr);
}


bool Heap::NewContains(uword addr) const {
  return new_space_->Contains(addr);
}


bool Heap::OldContains(uword addr) const {
  return old_space_->Contains(addr);
}


bool Heap::CodeContains(uword addr) const {
  return code_space_->Contains(addr);
}


void Heap::IterateObjects(ObjectVisitor* visitor) {
  new_space_->VisitObjects(visitor);
  old_space_->VisitObjects(visitor);
  code_space_->VisitObjects(visitor);
}


void Heap::IteratePointers(ObjectPointerVisitor* visitor) {
  new_space_->VisitObjectPointers(visitor);
  old_space_->VisitObjectPointers(visitor);
  code_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewPointers(ObjectPointerVisitor* visitor) {
  new_space_->VisitObjectPointers(visitor);
}


void Heap::IterateOldPointers(ObjectPointerVisitor* visitor) {
  old_space_->VisitObjectPointers(visitor);
  code_space_->VisitObjectPointers(visitor);
}


void Heap::IterateCodePointers(ObjectPointerVisitor* visitor) {
  code_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewObjects(ObjectVisitor* visitor) {
  new_space_->VisitObjects(visitor);
}


void Heap::IterateOldObjects(ObjectVisitor* visitor) {
  old_space_->VisitObjects(visitor);
  code_space_->VisitObjects(visitor);
}


void Heap::IterateCodeObjects(ObjectVisitor* visitor) {
  code_space_->VisitObjects(visitor);
}


RawInstructions* Heap::FindObjectInCodeSpace(FindObjectVisitor* visitor) {
  // The code heap can only have RawInstructions objects.
  RawObject* raw_obj = code_space_->FindObject(visitor);
  ASSERT((raw_obj == Object::null()) ||
         (raw_obj->GetClassId() == kInstructionsCid));
  return reinterpret_cast<RawInstructions*>(raw_obj);
}


void Heap::CollectGarbage(Space space, ApiCallbacks api_callbacks) {
  bool invoke_api_callbacks = (api_callbacks == kInvokeApiCallbacks);
  switch (space) {
    case kNew: {
      new_space_->Scavenge(invoke_api_callbacks,
                           GCReasonToString(kNewSpace));
      if (new_space_->HadPromotionFailure()) {
        old_space_->MarkSweep(true,
                              GCReasonToString(kPromotionFailure));
      }
      break;
    }
    case kOld:
      old_space_->MarkSweep(invoke_api_callbacks,
                            GCReasonToString(kOldSpace));
      break;
    case kCode:
      UNIMPLEMENTED();
      code_space_->MarkSweep(invoke_api_callbacks,
                             GCReasonToString(kCodeSpace));
      break;
    default:
      UNREACHABLE();
  }
  if (FLAG_verbose_gc) {
    PrintSizes();
  }
}


void Heap::CollectGarbage(Space space) {
  ApiCallbacks api_callbacks;
  if (space == kOld) {
    api_callbacks = kInvokeApiCallbacks;
  } else {
    api_callbacks = kIgnoreApiCallbacks;
  }
  CollectGarbage(space, api_callbacks);
}


void Heap::CollectAllGarbage() {
  const char* gc_reason = GCReasonToString(kFull);
  new_space_->Scavenge(kInvokeApiCallbacks, gc_reason);
  old_space_->MarkSweep(kInvokeApiCallbacks, gc_reason);
  // TODO(iposva): Merge old and code space.
  // code_space_->MarkSweep(kInvokeApiCallbacks, gc_reason);
  if (FLAG_verbose_gc) {
    PrintSizes();
  }
}


void Heap::EnableGrowthControl() {
  old_space_->EnableGrowthControl();
}


void Heap::WriteProtect(bool read_only) {
  read_only_ = read_only;
  new_space_->WriteProtect(read_only);
  old_space_->WriteProtect(read_only);
  // TODO(iposva): Merge old and code space.
  // code_space_->WriteProtect(read_only);
}


uword Heap::TopAddress() {
  return reinterpret_cast<uword>(new_space_->TopAddress());
}


uword Heap::EndAddress() {
  return reinterpret_cast<uword>(new_space_->EndAddress());
}


void Heap::Init(Isolate* isolate) {
  ASSERT(isolate->heap() == NULL);
  Heap* heap = new Heap();
  isolate->set_heap(heap);
}


void Heap::StartEndAddress(uword* start, uword* end) const {
  ASSERT(new_space_->capacity() != 0);
  new_space_->StartEndAddress(start, end);
  if (old_space_->capacity() != 0) {
    uword old_start;
    uword old_end;
    old_space_->StartEndAddress(&old_start, &old_end);
    *start = Utils::Minimum(old_start, *start);
    *end = Utils::Maximum(old_end, *end);
  }
  if (code_space_->capacity() != 0) {
    uword code_start;
    uword code_end;
    code_space_->StartEndAddress(&code_start, &code_end);
    *start = Utils::Minimum(code_start, *start);
    *end = Utils::Maximum(code_end, *end);
  }
  ASSERT(*start <= *end);
}


ObjectSet* Heap::CreateAllocatedObjectSet() const {
  Isolate* isolate = Isolate::Current();
  uword start, end;
  isolate->heap()->StartEndAddress(&start, &end);

  Isolate* vm_isolate = Dart::vm_isolate();
  uword vm_start, vm_end;
  vm_isolate->heap()->StartEndAddress(&vm_start, &vm_end);

  ObjectSet* allocated_set = new ObjectSet(Utils::Minimum(start, vm_start),
                                           Utils::Maximum(end, vm_end));

  VerifyObjectVisitor object_visitor(isolate, allocated_set);
  isolate->heap()->IterateObjects(&object_visitor);
  vm_isolate->heap()->IterateObjects(&object_visitor);

  return allocated_set;
}


bool Heap::Verify() const {
  Isolate* isolate = Isolate::Current();
  ObjectSet* allocated_set = isolate->heap()->CreateAllocatedObjectSet();
  VerifyPointersVisitor visitor(isolate, allocated_set);
  isolate->heap()->IteratePointers(&visitor);
  delete allocated_set;
  // Only returning a value so that Heap::Validate can be called from an ASSERT.
  return true;
}


void Heap::PrintSizes() const {
  OS::PrintErr("New space (%"Pd"k of %"Pd"k) "
               "Old space (%"Pd"k of %"Pd"k) "
               "Code space (%"Pd"k of %"Pd"k)\n",
               (new_space_->in_use() / KB), (new_space_->capacity() / KB),
               (old_space_->in_use() / KB), (old_space_->capacity() / KB),
               (code_space_->in_use() / KB), (code_space_->capacity() / KB));
}


void Heap::Profile(Dart_HeapProfileWriteCallback callback, void* stream) const {
  HeapProfiler profiler(callback, stream);

  // Dump the root set.
  HeapProfilerRootVisitor root_visitor(&profiler);
  Isolate* isolate = Isolate::Current();
  Isolate* vm_isolate = Dart::vm_isolate();
  isolate->VisitObjectPointers(&root_visitor, false,
                               StackFrameIterator::kDontValidateFrames);
  HeapProfilerWeakRootVisitor weak_root_visitor(&root_visitor);
  isolate->VisitWeakPersistentHandles(&weak_root_visitor, true);

  // Dump the current and VM isolate heaps.
  HeapProfilerObjectVisitor object_visitor(isolate, &profiler);
  isolate->heap()->IterateObjects(&object_visitor);
  vm_isolate->heap()->IterateObjects(&object_visitor);
}


const char* Heap::GCReasonToString(GCReason gc_reason) {
  switch (gc_reason) {
    case kNewSpace:
      return "new space";
    case kPromotionFailure:
      return "promotion failure";
    case kOldSpace:
      return "old space";
    case kCodeSpace:
      return "code space";
    case kFull:
      return "full";
    case kGCAtAlloc:
      return "debugging";
    case kGCTestCase:
      return "test case";
    default:
      UNREACHABLE();
      return "";
  }
}


void Heap::SetPeer(RawObject* raw_obj, void* peer) {
  if (raw_obj->IsNewObject()) {
    new_space_->SetPeer(raw_obj, peer);
  } else {
    ASSERT(raw_obj->IsOldObject());
    old_space_->SetPeer(raw_obj, peer);
  }
}


void* Heap::GetPeer(RawObject* raw_obj) {
  if (raw_obj->IsNewObject()) {
    return new_space_->GetPeer(raw_obj);
  }
  ASSERT(raw_obj->IsOldObject());
  return old_space_->GetPeer(raw_obj);
}


int64_t Heap::PeerCount() const {
  return new_space_->PeerCount() + old_space_->PeerCount();
}


#if defined(DEBUG)
NoGCScope::NoGCScope() : StackResource(Isolate::Current()) {
  isolate()->IncrementNoGCScopeDepth();
}


NoGCScope::~NoGCScope() {
  isolate()->DecrementNoGCScopeDepth();
}
#endif  // defined(DEBUG)

}  // namespace dart

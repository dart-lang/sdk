// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap.h"

#include "vm/assert.h"
#include "vm/compiler_stats.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/os.h"
#include "vm/pages.h"
#include "vm/scavenger.h"
#include "vm/utils.h"
#include "vm/verifier.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(bool, verbose_gc, false, "Enables verbose GC.");
DEFINE_FLAG(bool, gc_at_alloc, false, "GC at every allocation.");
DEFINE_FLAG(int, new_gen_heap_size, 32, "new gen heap size in MB,"
            "e.g: --new_gen_heap_size=64 allocates a 64MB new gen heap");
DEFINE_FLAG(int, old_gen_heap_size, Heap::kHeapSizeInMB,
            "old gen heap size in MB,"
            "e.g: --old_gen_heap_size=1024 allocates a 1024MB old gen heap");
DEFINE_FLAG(int, code_heap_size, Heap::kCodeHeapSizeInMB,
            "code heap size in MB,"
            "e.g: --code_heap_size=8 allocates a 8MB old gen heap");

Heap::Heap() {
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
  new_space_->Scavenge();
  if (FLAG_verbose_gc) {
    OS::PrintErr("New space (%dk) Old space (%dk) Code space (%dk)\n",
                 (new_space_->in_use() / KB),
                 (old_space_->in_use() / KB),
                 (code_space_->in_use() / KB));
  }
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
    // TODO(iposva): Support GC.
    FATAL("Exhausted heap space.");
  }
  return addr;
}


uword Heap::AllocateCode(intptr_t size) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  ASSERT(Utils::IsAligned(size, OS::PreferredCodeAlignment()));
  uword addr = code_space_->TryAllocate(size);
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


bool Heap::CodeContains(uword addr) const {
  return code_space_->Contains(addr);
}


void Heap::Init(Isolate* isolate) {
  ASSERT(isolate->heap() == NULL);
  Heap* heap = new Heap();
  isolate->set_heap(heap);
}


bool Heap::Verify() const {
  VerifyPointersVisitor visitor;
  new_space_->VisitObjectPointers(&visitor);
  old_space_->VisitObjectPointers(&visitor);
  code_space_->VisitObjectPointers(&visitor);
  // Only returning a value so that Heap::Validate can be called from an ASSERT.
  return true;
}


void Heap::IterateOldPointers(ObjectPointerVisitor* visitor) {
  old_space_->VisitObjectPointers(visitor);
  code_space_->VisitObjectPointers(visitor);
}


uword Heap::TopAddress() {
  return reinterpret_cast<uword>(new_space_->TopAddress());
}


uword Heap::EndAddress() {
  return reinterpret_cast<uword>(new_space_->EndAddress());
}


#if defined(DEBUG)
NoGCScope::NoGCScope() : StackResource(), isolate_(Isolate::Current()) {
  isolate_->IncrementNoGCScopeDepth();
}


NoGCScope::~NoGCScope() {
  isolate_->DecrementNoGCScopeDepth();
}
#endif  // defined(DEBUG)

}  // namespace dart

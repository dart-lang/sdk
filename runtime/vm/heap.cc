// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/heap_profiler.h"
#include "vm/heap_trace.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/scavenger.h"
#include "vm/stack_frame.h"
#include "vm/verifier.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(bool, verbose_gc, false, "Enables verbose GC.");
DEFINE_FLAG(int, verbose_gc_hdr, 40, "Print verbose GC header interval.");
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

Heap::Heap() : read_only_(false), gc_in_progress_(false) {
  new_space_ = new Scavenger(this,
                             (FLAG_new_gen_heap_size * MB),
                             kNewObjectAlignmentOffset);
  old_space_ = new PageSpace(this, (FLAG_old_gen_heap_size * MB));
  stats_.num_ = 0;
  heap_trace_ = new HeapTrace;
}


Heap::~Heap() {
  delete new_space_;
  delete old_space_;
}


uword Heap::AllocateNew(intptr_t size) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  uword addr = new_space_->TryAllocate(size);
  if (addr == 0) {
    CollectGarbage(kNew);
    addr = new_space_->TryAllocate(size);
    if (addr == 0) {
      return AllocateOld(size, HeapPage::kData);
    }
  }
  if (HeapTrace::is_enabled()) {
    heap_trace_->TraceAllocation(addr, size);
  }
  return addr;
}


uword Heap::AllocateOld(intptr_t size, HeapPage::PageType type) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  uword addr = old_space_->TryAllocate(size, type);
  if (addr == 0) {
    CollectAllGarbage();
    addr = old_space_->TryAllocate(size, type, PageSpace::kForceGrowth);
    if (addr == 0) {
      OS::PrintErr("Exhausted heap space, trying to allocate %"Pd" bytes.\n",
                   size);
      return 0;
    }
  }
  if (HeapTrace::is_enabled()) {
    heap_trace_->TraceAllocation(addr, size);
  }
  return addr;
}


bool Heap::Contains(uword addr) const {
  return new_space_->Contains(addr) ||
      old_space_->Contains(addr);
}


bool Heap::NewContains(uword addr) const {
  return new_space_->Contains(addr);
}


bool Heap::OldContains(uword addr) const {
  return old_space_->Contains(addr);
}


bool Heap::CodeContains(uword addr) const {
  return old_space_->Contains(addr, HeapPage::kExecutable);
}


void Heap::IterateObjects(ObjectVisitor* visitor) {
  new_space_->VisitObjects(visitor);
  old_space_->VisitObjects(visitor);
}


void Heap::IteratePointers(ObjectPointerVisitor* visitor) {
  new_space_->VisitObjectPointers(visitor);
  old_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewPointers(ObjectPointerVisitor* visitor) {
  new_space_->VisitObjectPointers(visitor);
}


void Heap::IterateOldPointers(ObjectPointerVisitor* visitor) {
  old_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewObjects(ObjectVisitor* visitor) {
  new_space_->VisitObjects(visitor);
}


void Heap::IterateOldObjects(ObjectVisitor* visitor) {
  old_space_->VisitObjects(visitor);
}


RawInstructions* Heap::FindObjectInCodeSpace(FindObjectVisitor* visitor) {
  // Only executable pages can have RawInstructions objects.
  RawObject* raw_obj = old_space_->FindObject(visitor, HeapPage::kExecutable);
  ASSERT((raw_obj == Object::null()) ||
         (raw_obj->GetClassId() == kInstructionsCid));
  return reinterpret_cast<RawInstructions*>(raw_obj);
}


void Heap::CollectGarbage(Space space, ApiCallbacks api_callbacks) {
  bool invoke_api_callbacks = (api_callbacks == kInvokeApiCallbacks);
  switch (space) {
    case kNew: {
      RecordBeforeGC(kNew, kNewSpace);
      new_space_->Scavenge(invoke_api_callbacks);
      RecordAfterGC();
      PrintStats();
      if (new_space_->HadPromotionFailure()) {
        CollectGarbage(kOld, api_callbacks);
      }
      break;
    }
    case kOld:
    case kCode: {
      bool promotion_failure = new_space_->HadPromotionFailure();
      RecordBeforeGC(kOld, promotion_failure ? kPromotionFailure : kOldSpace);
      old_space_->MarkSweep(invoke_api_callbacks);
      RecordAfterGC();
      PrintStats();
      break;
    }
    default:
      UNREACHABLE();
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
  RecordBeforeGC(kNew, kFull);
  new_space_->Scavenge(kInvokeApiCallbacks);
  RecordAfterGC();
  PrintStats();
  RecordBeforeGC(kOld, kFull);
  old_space_->MarkSweep(kInvokeApiCallbacks);
  RecordAfterGC();
  PrintStats();
}


void Heap::EnableGrowthControl() {
  old_space_->EnableGrowthControl();
}


void Heap::WriteProtect(bool read_only) {
  read_only_ = read_only;
  new_space_->WriteProtect(read_only);
  old_space_->WriteProtect(read_only);
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
               "Old space (%"Pd"k of %"Pd"k)\n",
               (Used(kNew) / KB), (Capacity(kNew) / KB),
               (Used(kOld) / KB), (Capacity(kOld) / KB));
}


intptr_t Heap::Used(Space space) const {
  return space == kNew ? new_space_->in_use() : old_space_->in_use();
}


intptr_t Heap::Capacity(Space space) const {
  return space == kNew ? new_space_->capacity() : old_space_->capacity();
}


void Heap::Profile(Dart_FileWriteCallback callback, void* stream) const {
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


void Heap::ProfileToFile(const char* reason) const {
  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  ASSERT(file_open != NULL);
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  ASSERT(file_write != NULL);
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  ASSERT(file_close != NULL);
  Isolate* isolate = Isolate::Current();
  const char* format = "%s-%s.hprof";
  intptr_t len = OS::SNPrint(NULL, 0, format, isolate->name(), reason);
  char* filename = isolate->current_zone()->Alloc<char>(len + 1);
  OS::SNPrint(filename, len + 1, format, isolate->name(), reason);
  void* file = (*file_open)(filename);
  if (file != NULL) {
    Profile(file_write, file);
    (*file_close)(file);
  }
}


const char* Heap::GCReasonToString(GCReason gc_reason) {
  switch (gc_reason) {
    case kNewSpace:
      return "new space";
    case kPromotionFailure:
      return "promotion failure";
    case kOldSpace:
      return "old space";
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


void Heap::RecordBeforeGC(Space space, GCReason reason) {
  ASSERT(!gc_in_progress_);
  gc_in_progress_ = true;
  stats_.num_++;
  stats_.space_ = space;
  stats_.reason_ = reason;
  stats_.before_.micros_ = OS::GetCurrentTimeMicros();
  stats_.before_.new_used_ = new_space_->in_use();
  stats_.before_.new_capacity_ = new_space_->capacity();
  stats_.before_.old_used_ = old_space_->in_use();
  stats_.before_.old_capacity_ = old_space_->capacity();
  stats_.times_[0] = 0;
  stats_.times_[1] = 0;
  stats_.times_[2] = 0;
  stats_.times_[3] = 0;
  stats_.data_[0] = 0;
  stats_.data_[1] = 0;
  stats_.data_[2] = 0;
  stats_.data_[3] = 0;
}


void Heap::RecordAfterGC() {
  stats_.after_.micros_ = OS::GetCurrentTimeMicros();
  stats_.after_.new_used_ = new_space_->in_use();
  stats_.after_.new_capacity_ = new_space_->capacity();
  stats_.after_.old_used_ = old_space_->in_use();
  stats_.after_.old_capacity_ = old_space_->capacity();
  ASSERT(gc_in_progress_);
  gc_in_progress_ = false;
}


static intptr_t RoundToKB(intptr_t memory_size) {
  return (memory_size + (KB >> 1)) >> KBLog2;
}


static double RoundToSecs(int64_t micros) {
  const int k1M = 1000000;  // Converting us to secs.
  return static_cast<double>(micros + (k1M / 2)) / k1M;
}


static double RoundToMillis(int64_t micros) {
  const int k1K = 1000;  // Conversting us to ms.
  return static_cast<double>(micros + (k1K / 2)) / k1K;
}


void Heap::PrintStats() {
  if (!FLAG_verbose_gc) return;
  Isolate* isolate = Isolate::Current();

  if ((FLAG_verbose_gc_hdr != 0) &&
      (((stats_.num_ - 1) % FLAG_verbose_gc_hdr) == 0)) {
    OS::PrintErr("[    GC    |  space  | count | start | gc time | "
                 "new gen (KB) | old gen (KB) | timers | data ]\n"
                 "[ (isolate)| (reason)|       |  (s)  |   (ms)  | "
                 " used , cap  |  used , cap  |  (ms)  |      ]\n");
  }

  const char* space_str = stats_.space_ == kNew ? "Scavenge" : "Mark-Sweep";
  OS::PrintErr(
    "[ GC(%"Pd64"): %s(%s), "  // GC(isolate), space(reason)
    "%"Pd", "  // count
    "%.3f, "  // start time
    "%.3f, "  // total time
    "%"Pd", %"Pd", %"Pd", %"Pd", "  // new gen: in use, capacity before/after
    "%"Pd", %"Pd", %"Pd", %"Pd", "  // old gen: in use, capacity before/after
    "%.3f, %.3f, %.3f, %.3f, "  // times
    "%"Pd", %"Pd", %"Pd", %"Pd", "  // data
    "]\n",  // End with a comma to make it easier to import in spreadsheets.
    isolate->main_port(), space_str, GCReasonToString(stats_.reason_),
    stats_.num_,
    RoundToSecs(stats_.before_.micros_ - isolate->start_time()),
    RoundToMillis(stats_.after_.micros_ - stats_.before_.micros_),
    RoundToKB(stats_.before_.new_used_), RoundToKB(stats_.after_.new_used_),
    RoundToKB(stats_.before_.new_capacity_),
    RoundToKB(stats_.after_.new_capacity_),
    RoundToKB(stats_.before_.old_used_), RoundToKB(stats_.after_.old_used_),
    RoundToKB(stats_.before_.old_capacity_),
    RoundToKB(stats_.after_.old_capacity_),
    RoundToMillis(stats_.times_[0]),
    RoundToMillis(stats_.times_[1]),
    RoundToMillis(stats_.times_[2]),
    RoundToMillis(stats_.times_[3]),
    stats_.data_[0],
    stats_.data_[1],
    stats_.data_[2],
    stats_.data_[3]);
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

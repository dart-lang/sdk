// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/flags.h"
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
#include "vm/weak_table.h"

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
  for (int sel = 0;
       sel < kNumWeakSelectors;
       sel++) {
    new_weak_tables_[sel] = new WeakTable();
    old_weak_tables_[sel] = new WeakTable();
  }
  new_space_ = new Scavenger(this,
                             (FLAG_new_gen_heap_size * MBInWords),
                             kNewObjectAlignmentOffset);
  old_space_ = new PageSpace(this, (FLAG_old_gen_heap_size * MBInWords));
  stats_.num_ = 0;
}


Heap::~Heap() {
  delete new_space_;
  delete old_space_;
  for (int sel = 0;
       sel < kNumWeakSelectors;
       sel++) {
    delete new_weak_tables_[sel];
    delete old_weak_tables_[sel];
  }
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
  return addr;
}


uword Heap::AllocateOld(intptr_t size, HeapPage::PageType type) {
  ASSERT(Isolate::Current()->no_gc_scope_depth() == 0);
  uword addr = old_space_->TryAllocate(size, type);
  if (addr == 0) {
    CollectAllGarbage();
    addr = old_space_->TryAllocate(size, type, PageSpace::kForceGrowth);
    if (addr == 0) {
      OS::PrintErr("Exhausted heap space, trying to allocate %" Pd " bytes.\n",
                   size);
      return 0;
    }
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


RawObject* Heap::FindOldObject(FindObjectVisitor* visitor) const {
  return old_space_->FindObject(visitor, HeapPage::kData);
}


void Heap::CollectGarbage(Space space, ApiCallbacks api_callbacks) {
  bool invoke_api_callbacks = (api_callbacks == kInvokeApiCallbacks);
  switch (space) {
    case kNew: {
      RecordBeforeGC(kNew, kNewSpace);
      UpdateClassHeapStatsBeforeGC(kNew);
      new_space_->Scavenge(invoke_api_callbacks);
      RecordAfterGC();
      PrintStats();
      if (new_space_->HadPromotionFailure()) {
        // Old collections should call the API callbacks.
        CollectGarbage(kOld, kInvokeApiCallbacks);
      }
      break;
    }
    case kOld:
    case kCode: {
      bool promotion_failure = new_space_->HadPromotionFailure();
      RecordBeforeGC(kOld, promotion_failure ? kPromotionFailure : kOldSpace);
      UpdateClassHeapStatsBeforeGC(kOld);
      old_space_->MarkSweep(invoke_api_callbacks);
      RecordAfterGC();
      PrintStats();
      break;
    }
    default:
      UNREACHABLE();
  }
}


void Heap::UpdateClassHeapStatsBeforeGC(Heap::Space space) {
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
  if (space == kNew) {
    class_table->ResetCountersNew();
  } else {
    class_table->ResetCountersOld();
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
  UpdateClassHeapStatsBeforeGC(kNew);
  new_space_->Scavenge(kInvokeApiCallbacks);
  RecordAfterGC();
  PrintStats();
  RecordBeforeGC(kOld, kFull);
  UpdateClassHeapStatsBeforeGC(kOld);
  old_space_->MarkSweep(kInvokeApiCallbacks);
  RecordAfterGC();
  PrintStats();
}


void Heap::SetGrowthControlState(bool state) {
  old_space_->SetGrowthControlState(state);
}


bool Heap::GrowthControlState() {
  return old_space_->GrowthControlState();
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
  ASSERT(new_space_->CapacityInWords() != 0);
  new_space_->StartEndAddress(start, end);
  if (old_space_->CapacityInWords() != 0) {
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
  OS::PrintErr("New space (%" Pd "k of %" Pd "k) "
               "Old space (%" Pd "k of %" Pd "k)\n",
               (UsedInWords(kNew) / KBInWords),
               (CapacityInWords(kNew) / KBInWords),
               (UsedInWords(kOld) / KBInWords),
               (CapacityInWords(kOld) / KBInWords));
}


intptr_t Heap::UsedInWords(Space space) const {
  return space == kNew ? new_space_->UsedInWords() : old_space_->UsedInWords();
}


intptr_t Heap::CapacityInWords(Space space) const {
  return space == kNew ? new_space_->CapacityInWords() :
                         old_space_->CapacityInWords();
}


int64_t Heap::GCTimeInMicros(Space space) const {
  if (space == kNew) {
    return new_space_->gc_time_micros();
  }
  return old_space_->gc_time_micros();
}


intptr_t Heap::Collections(Space space) const {
  if (space == kNew) {
    return new_space_->collections();
  }
  return old_space_->collections();
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


int64_t Heap::PeerCount() const {
  return new_weak_tables_[kPeers]->count() + old_weak_tables_[kPeers]->count();
}


int64_t Heap::HashCount() const {
  return
      new_weak_tables_[kHashes]->count() + old_weak_tables_[kHashes]->count();
}


intptr_t Heap::GetWeakEntry(RawObject* raw_obj, WeakSelector sel) const {
  if (raw_obj->IsNewObject()) {
    return new_weak_tables_[sel]->GetValue(raw_obj);
  }
  ASSERT(raw_obj->IsOldObject());
  return old_weak_tables_[sel]->GetValue(raw_obj);
}


void Heap::SetWeakEntry(RawObject* raw_obj, WeakSelector sel, intptr_t val) {
  if (raw_obj->IsNewObject()) {
    new_weak_tables_[sel]->SetValue(raw_obj, val);
  } else {
    ASSERT(raw_obj->IsOldObject());
    old_weak_tables_[sel]->SetValue(raw_obj, val);
  }
}


void Heap::PrintToJSONObject(Space space, JSONObject* object) const {
  if (space == kNew) {
    new_space_->PrintToJSONObject(object);
  } else {
    old_space_->PrintToJSONObject(object);
  }
}


void Heap::RecordBeforeGC(Space space, GCReason reason) {
  ASSERT(!gc_in_progress_);
  gc_in_progress_ = true;
  stats_.num_++;
  stats_.space_ = space;
  stats_.reason_ = reason;
  stats_.before_.micros_ = OS::GetCurrentTimeMicros();
  stats_.before_.new_used_in_words_ = new_space_->UsedInWords();
  stats_.before_.new_capacity_in_words_ = new_space_->CapacityInWords();
  stats_.before_.old_used_in_words_ = old_space_->UsedInWords();
  stats_.before_.old_capacity_in_words_ = old_space_->CapacityInWords();
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
  int64_t delta = stats_.after_.micros_ - stats_.before_.micros_;
  if (stats_.space_ == kNew) {
    new_space_->AddGCTime(delta);
    new_space_->IncrementCollections();
  } else {
    old_space_->AddGCTime(delta);
    old_space_->IncrementCollections();
  }
  stats_.after_.new_used_in_words_ = new_space_->UsedInWords();
  stats_.after_.new_capacity_in_words_ = new_space_->CapacityInWords();
  stats_.after_.old_used_in_words_ = old_space_->UsedInWords();
  stats_.after_.old_capacity_in_words_ = old_space_->CapacityInWords();
  ASSERT(gc_in_progress_);
  gc_in_progress_ = false;
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
    "[ GC(%" Pd64 "): %s(%s), "  // GC(isolate), space(reason)
    "%" Pd ", "  // count
    "%.3f, "  // start time
    "%.3f, "  // total time
    "%" Pd ", %" Pd ", "  // new gen: in use before/after
    "%" Pd ", %" Pd ", "  // new gen: capacity before/after
    "%" Pd ", %" Pd ", "  // old gen: in use before/after
    "%" Pd ", %" Pd ", "  // old gen: capacity before/after
    "%.3f, %.3f, %.3f, %.3f, "  // times
    "%" Pd ", %" Pd ", %" Pd ", %" Pd ", "  // data
    "]\n",  // End with a comma to make it easier to import in spreadsheets.
    isolate->main_port(), space_str, GCReasonToString(stats_.reason_),
    stats_.num_,
    RoundMicrosecondsToSeconds(stats_.before_.micros_ - isolate->start_time()),
    RoundMicrosecondsToMilliseconds(stats_.after_.micros_ -
                                    stats_.before_.micros_),
    RoundWordsToKB(stats_.before_.new_used_in_words_),
    RoundWordsToKB(stats_.after_.new_used_in_words_),
    RoundWordsToKB(stats_.before_.new_capacity_in_words_),
    RoundWordsToKB(stats_.after_.new_capacity_in_words_),
    RoundWordsToKB(stats_.before_.old_used_in_words_),
    RoundWordsToKB(stats_.after_.old_used_in_words_),
    RoundWordsToKB(stats_.before_.old_capacity_in_words_),
    RoundWordsToKB(stats_.after_.old_capacity_in_words_),
    RoundMicrosecondsToMilliseconds(stats_.times_[0]),
    RoundMicrosecondsToMilliseconds(stats_.times_[1]),
    RoundMicrosecondsToMilliseconds(stats_.times_[2]),
    RoundMicrosecondsToMilliseconds(stats_.times_[3]),
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


NoHeapGrowthControlScope::NoHeapGrowthControlScope()
    : StackResource(Isolate::Current()) {
    Heap* heap = reinterpret_cast<Isolate*>(isolate())->heap();
    current_growth_controller_state_ = heap->GrowthControlState();
    heap->DisableGrowthControl();
}


NoHeapGrowthControlScope::~NoHeapGrowthControlScope() {
    Heap* heap = reinterpret_cast<Isolate*>(isolate())->heap();
    heap->SetGrowthControlState(current_growth_controller_state_);
}

}  // namespace dart

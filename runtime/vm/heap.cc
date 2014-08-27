// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/scavenger.h"
#include "vm/service.h"
#include "vm/stack_frame.h"
#include "vm/tags.h"
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
DEFINE_FLAG(int, new_gen_ext_limit, 64,
            "maximum total external size (MB) in new gen before triggering GC");

Heap::Heap(Isolate* isolate,
           intptr_t max_new_gen_semi_words,
           intptr_t max_old_gen_words)
    : isolate_(isolate), read_only_(false), gc_in_progress_(false) {
  for (int sel = 0;
       sel < kNumWeakSelectors;
       sel++) {
    new_weak_tables_[sel] = new WeakTable();
    old_weak_tables_[sel] = new WeakTable();
  }
  new_space_ = new Scavenger(this,
                             max_new_gen_semi_words,
                             kNewObjectAlignmentOffset);
  old_space_ = new PageSpace(this, max_old_gen_words);
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
  ASSERT(isolate()->no_gc_scope_depth() == 0);
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
  ASSERT(isolate()->no_gc_scope_depth() == 0);
  uword addr = old_space_->TryAllocate(size, type);
  if (addr != 0) {
    return addr;
  }
  // If we are in the process of running a sweep wait for the sweeper to free
  // memory.
  {
    MonitorLocker ml(old_space_->tasks_lock());
    addr = old_space_->TryAllocate(size, type);
    while ((addr == 0) && (old_space_->tasks())) {
      ml.Wait();
      addr = old_space_->TryAllocate(size, type);
    }
  }
  if (addr != 0) {
    return addr;
  }
  // All GC tasks finished without allocating successfully. Run a full GC.
  CollectAllGarbage();
  addr = old_space_->TryAllocate(size, type, PageSpace::kForceGrowth);
  if (addr != 0) {
    return addr;
  }
  // Wait for all of the concurrent tasks to finish before giving up.
  {
    MonitorLocker ml(old_space_->tasks_lock());
    addr = old_space_->TryAllocate(size, type, PageSpace::kForceGrowth);
    while ((addr == 0) && (old_space_->tasks())) {
      ml.Wait();
      addr = old_space_->TryAllocate(size, type, PageSpace::kForceGrowth);
    }
  }
  if (addr != 0) {
    return addr;
  }
  // Giving up allocating this object.
  OS::PrintErr(
      "Exhausted heap space, trying to allocate %" Pd " bytes.\n", size);
  return 0;
}

void Heap::AllocateExternal(intptr_t size, Space space) {
  ASSERT(isolate()->no_gc_scope_depth() == 0);
  if (space == kNew) {
    new_space_->AllocateExternal(size);
    if (new_space_->ExternalInWords() > (FLAG_new_gen_ext_limit * MBInWords)) {
      // Attempt to free some external allocation by a scavenge. (If the total
      // remains above the limit, next external alloc will trigger another.)
      CollectGarbage(kNew);
    }
  } else {
    ASSERT(space == kOld);
    old_space_->AllocateExternal(size);
    if (old_space_->NeedsGarbageCollection()) {
      CollectAllGarbage();
    }
  }
}

void Heap::FreeExternal(intptr_t size, Space space) {
  if (space == kNew) {
    new_space_->FreeExternal(size);
  } else {
    ASSERT(space == kOld);
    old_space_->FreeExternal(size);
  }
}

void Heap::PromoteExternal(intptr_t size) {
  new_space_->FreeExternal(size);
  old_space_->AllocateExternal(size);
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


void Heap::IterateObjects(ObjectVisitor* visitor) const {
  new_space_->VisitObjects(visitor);
  old_space_->VisitObjects(visitor);
}


void Heap::IteratePointers(ObjectPointerVisitor* visitor) const {
  new_space_->VisitObjectPointers(visitor);
  old_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewPointers(ObjectPointerVisitor* visitor) const {
  new_space_->VisitObjectPointers(visitor);
}


void Heap::IterateOldPointers(ObjectPointerVisitor* visitor) const {
  old_space_->VisitObjectPointers(visitor);
}


void Heap::IterateNewObjects(ObjectVisitor* visitor) const {
  new_space_->VisitObjects(visitor);
}


void Heap::IterateOldObjects(ObjectVisitor* visitor) const {
  old_space_->VisitObjects(visitor);
}


RawInstructions* Heap::FindObjectInCodeSpace(FindObjectVisitor* visitor) const {
  // Only executable pages can have RawInstructions objects.
  RawObject* raw_obj = old_space_->FindObject(visitor, HeapPage::kExecutable);
  ASSERT((raw_obj == Object::null()) ||
         (raw_obj->GetClassId() == kInstructionsCid));
  return reinterpret_cast<RawInstructions*>(raw_obj);
}


RawObject* Heap::FindOldObject(FindObjectVisitor* visitor) const {
  return old_space_->FindObject(visitor, HeapPage::kData);
}


RawObject* Heap::FindNewObject(FindObjectVisitor* visitor) const {
  return new_space_->FindObject(visitor);
}


RawObject* Heap::FindObject(FindObjectVisitor* visitor) const {
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawObject* raw_obj = FindNewObject(visitor);
  if (raw_obj != Object::null()) {
    return raw_obj;
  }
  raw_obj = FindOldObject(visitor);
  if (raw_obj != Object::null()) {
    return raw_obj;
  }
  raw_obj = FindObjectInCodeSpace(visitor);
  return raw_obj;
}


void Heap::CollectGarbage(Space space,
                          ApiCallbacks api_callbacks,
                          GCReason reason) {
  TIMERSCOPE(isolate(), time_gc);
  bool invoke_api_callbacks = (api_callbacks == kInvokeApiCallbacks);
  switch (space) {
    case kNew: {
      VMTagScope tagScope(isolate(), VMTag::kGCNewSpaceTagId);
      RecordBeforeGC(kNew, reason);
      UpdateClassHeapStatsBeforeGC(kNew);
      new_space_->Scavenge(invoke_api_callbacks);
      isolate()->class_table()->UpdatePromoted();
      RecordAfterGC();
      PrintStats();
      if (old_space_->NeedsGarbageCollection()) {
        // Old collections should call the API callbacks.
        CollectGarbage(kOld, kInvokeApiCallbacks, kPromotion);
      }
      break;
    }
    case kOld:
    case kCode: {
      VMTagScope tagScope(isolate(), VMTag::kGCOldSpaceTagId);
      RecordBeforeGC(kOld, reason);
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
  ClassTable* class_table = isolate()->class_table();
  if (space == kNew) {
    class_table->ResetCountersNew();
  } else {
    class_table->ResetCountersOld();
  }
}


void Heap::CollectGarbage(Space space) {
  if (space == kOld) {
    CollectGarbage(space, kInvokeApiCallbacks, kOldSpace);
  } else {
    ASSERT(space == kNew);
    CollectGarbage(space, kInvokeApiCallbacks, kNewSpace);
  }
}


void Heap::CollectAllGarbage() {
  TIMERSCOPE(isolate(), time_gc);
  {
    VMTagScope tagScope(isolate(), VMTag::kGCNewSpaceTagId);
    RecordBeforeGC(kNew, kFull);
    UpdateClassHeapStatsBeforeGC(kNew);
    new_space_->Scavenge(kInvokeApiCallbacks);
    isolate()->class_table()->UpdatePromoted();
    RecordAfterGC();
    PrintStats();
  }
  {
    VMTagScope tagScope(isolate(), VMTag::kGCOldSpaceTagId);
    RecordBeforeGC(kOld, kFull);
    UpdateClassHeapStatsBeforeGC(kOld);
    old_space_->MarkSweep(kInvokeApiCallbacks);
    RecordAfterGC();
    PrintStats();
  }
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


void Heap::Init(Isolate* isolate,
                intptr_t max_new_gen_words,
                intptr_t max_old_gen_words) {
  ASSERT(isolate->heap() == NULL);
  Heap* heap = new Heap(isolate, max_new_gen_words, max_old_gen_words);
  isolate->set_heap(heap);
}


void Heap::GetMergedAddressRange(uword* start, uword* end) const {
  if (new_space_->CapacityInWords() != 0) {
    uword new_start;
    uword new_end;
    new_space_->StartEndAddress(&new_start, &new_end);
    *start = Utils::Minimum(new_start, *start);
    *end = Utils::Maximum(new_end, *end);
  }
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
  uword start = static_cast<uword>(-1);
  uword end = 0;
  Isolate* vm_isolate = Dart::vm_isolate();
  vm_isolate->heap()->GetMergedAddressRange(&start, &end);
  this->GetMergedAddressRange(&start, &end);

  ObjectSet* allocated_set = new ObjectSet(start, end);

  VerifyObjectVisitor object_visitor(isolate(), allocated_set);
  this->IterateObjects(&object_visitor);
  vm_isolate->heap()->IterateObjects(&object_visitor);

  return allocated_set;
}


bool Heap::Verify() const {
  ObjectSet* allocated_set = CreateAllocatedObjectSet();
  VerifyPointersVisitor visitor(isolate(), allocated_set);
  IteratePointers(&visitor);
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

intptr_t Heap::ExternalInWords(Space space) const {
  return space == kNew ? new_space_->ExternalInWords() :
                         old_space_->ExternalInWords();
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
    case kPromotion:
      return "promotion";
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
  stats_.before_.new_ = new_space_->GetCurrentUsage();
  stats_.before_.old_ = old_space_->GetCurrentUsage();
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
  stats_.after_.new_ = new_space_->GetCurrentUsage();
  stats_.after_.old_ = old_space_->GetCurrentUsage();
  ASSERT(gc_in_progress_);
  gc_in_progress_ = false;
  if (Service::NeedsGCEvents()) {
    GCEvent event(stats_);
    Service::HandleGCEvent(&event);
  }
}


void Heap::PrintStats() {
  if (!FLAG_verbose_gc) return;

  if ((FLAG_verbose_gc_hdr != 0) &&
      (((stats_.num_ - 1) % FLAG_verbose_gc_hdr) == 0)) {
    OS::PrintErr("[    GC    |  space  | count | start | gc time | "
                 "new gen (KB) | old gen (KB) | timers | data ]\n"
                 "[ (isolate)| (reason)|       |  (s)  |   (ms)  | "
                 "used,cap,ext | used,cap,ext |  (ms)  |      ]\n");
  }

  const char* space_str = stats_.space_ == kNew ? "Scavenge" : "Mark-Sweep";
  OS::PrintErr(
    "[ GC(%" Pd64 "): %s(%s), "  // GC(isolate), space(reason)
    "%" Pd ", "  // count
    "%.3f, "  // start time
    "%.3f, "  // total time
    "%" Pd ", %" Pd ", "  // new gen: in use before/after
    "%" Pd ", %" Pd ", "  // new gen: capacity before/after
    "%" Pd ", %" Pd ", "  // new gen: external before/after
    "%" Pd ", %" Pd ", "  // old gen: in use before/after
    "%" Pd ", %" Pd ", "  // old gen: capacity before/after
    "%" Pd ", %" Pd ", "  // old gen: external before/after
    "%.3f, %.3f, %.3f, %.3f, "  // times
    "%" Pd ", %" Pd ", %" Pd ", %" Pd ", "  // data
    "]\n",  // End with a comma to make it easier to import in spreadsheets.
    isolate()->main_port(), space_str, GCReasonToString(stats_.reason_),
    stats_.num_,
    MicrosecondsToSeconds(stats_.before_.micros_ - isolate()->start_time()),
    MicrosecondsToMilliseconds(stats_.after_.micros_ -
                                    stats_.before_.micros_),
    RoundWordsToKB(stats_.before_.new_.used_in_words),
    RoundWordsToKB(stats_.after_.new_.used_in_words),
    RoundWordsToKB(stats_.before_.new_.capacity_in_words),
    RoundWordsToKB(stats_.after_.new_.capacity_in_words),
    RoundWordsToKB(stats_.before_.new_.external_in_words),
    RoundWordsToKB(stats_.after_.new_.external_in_words),
    RoundWordsToKB(stats_.before_.old_.used_in_words),
    RoundWordsToKB(stats_.after_.old_.used_in_words),
    RoundWordsToKB(stats_.before_.old_.capacity_in_words),
    RoundWordsToKB(stats_.after_.old_.capacity_in_words),
    RoundWordsToKB(stats_.before_.old_.external_in_words),
    RoundWordsToKB(stats_.after_.old_.external_in_words),
    MicrosecondsToMilliseconds(stats_.times_[0]),
    MicrosecondsToMilliseconds(stats_.times_[1]),
    MicrosecondsToMilliseconds(stats_.times_[2]),
    MicrosecondsToMilliseconds(stats_.times_[3]),
    stats_.data_[0],
    stats_.data_[1],
    stats_.data_[2],
    stats_.data_[3]);
}


void GCEvent::PrintJSON(JSONStream* js) const {
  Isolate* isolate = Isolate::Current();
  {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "ServiceEvent");
    jsobj.AddPropertyF("id", "gc/%" Pd, stats_.num_);
    jsobj.AddProperty("eventType", "GC");  // TODO(koda): "GarbageCollected"
    jsobj.AddProperty("isolate", isolate);
    jsobj.AddProperty("reason", Heap::GCReasonToString(stats_.reason_));
    isolate->heap()->PrintToJSONObject(Heap::kNew, &jsobj);
    isolate->heap()->PrintToJSONObject(Heap::kOld, &jsobj);
  }
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

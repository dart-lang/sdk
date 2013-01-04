// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap_trace.h"

#include "include/dart_api.h"
#include "vm/dart_api_state.h"
#include "vm/debugger.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/unicode.h"

namespace dart {

DEFINE_FLAG(bool, heap_trace, false, "Enable heap tracing.");

Dart_FileOpenCallback HeapTrace::open_callback_ = NULL;
Dart_FileWriteCallback HeapTrace::write_callback_ = NULL;
Dart_FileCloseCallback HeapTrace::close_callback_ = NULL;
bool HeapTrace::is_enabled_ = false;

class HeapTraceVisitor : public ObjectPointerVisitor {
 public:
  HeapTraceVisitor(Isolate* isolate,
                   HeapTrace* heap_trace,
                   ObjectSet* object_set)
      : ObjectPointerVisitor(isolate),
        heap_trace_(heap_trace),
        vm_isolate_(Dart::vm_isolate()),
        object_set_(object_set) {
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* raw_obj = *current;

      // We only care about objects in the heap
      // Also, since this visitor will frequently be encountering redudant
      // roots, we use an object_set to skip the duplicates.
      if (raw_obj->IsHeapObject() &&
          raw_obj != reinterpret_cast<RawObject*>(0x1) &&
          raw_obj != reinterpret_cast<RawObject*>(0xabababab) &&
          !object_set_->Contains(raw_obj) &&
          !vm_isolate_->heap()->Contains(RawObject::ToAddr(raw_obj))) {
        object_set_->Add(raw_obj);
        uword addr = RawObject::ToAddr(raw_obj);
        heap_trace_->TraceSingleRoot(addr);
      }
    }
  }

 private:
  HeapTrace* heap_trace_;
  Isolate* vm_isolate_;
  // TODO(cshapiro): replace with a sparse data structure.
  ObjectSet* object_set_;
  DISALLOW_COPY_AND_ASSIGN(HeapTraceVisitor);
};


class HeapTraceScopedHandleVisitor : public ObjectPointerVisitor {
 public:
  HeapTraceScopedHandleVisitor(Isolate* isolate, HeapTrace* heap_trace)
       : ObjectPointerVisitor(isolate), heap_trace_(heap_trace) {
  }

  void VisitPointers(RawObject**  first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* raw_obj = *current;
      Heap* heap = isolate()->heap();

      // We only care about objects in the heap
      if (raw_obj->IsHeapObject() &&
          raw_obj != reinterpret_cast<RawObject*>(0x1) &&
          raw_obj != reinterpret_cast<RawObject*>(0xabababab) &&
          heap->Contains(RawObject::ToAddr(raw_obj))) {
        uword addr = RawObject::ToAddr(raw_obj);
        heap_trace_->TraceScopedHandle(addr);
     }
    }
  }

 private:
  HeapTrace* heap_trace_;
  DISALLOW_COPY_AND_ASSIGN(HeapTraceScopedHandleVisitor);
};


class HeapTraceObjectStoreVisitor : public ObjectPointerVisitor {
 public:
  HeapTraceObjectStoreVisitor(Isolate* isolate, HeapTrace* heap_trace)
        : ObjectPointerVisitor(isolate), heap_trace_(heap_trace) {
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* raw_obj = *current;

      // We only care about obects in the heap.
      if (raw_obj->IsHeapObject() &&
          raw_obj != reinterpret_cast<RawObject*>(0x1) &&
          raw_obj != reinterpret_cast<RawObject*>(0xabababab)) {
        uword addr = RawObject::ToAddr(raw_obj);
        heap_trace_->TraceObjectStorePointer(addr);
      }
    }
  }

 private:
  HeapTrace* heap_trace_;
  DISALLOW_COPY_AND_ASSIGN(HeapTraceObjectStoreVisitor);
};


class HeapTraceInitialHeapVisitor : public ObjectVisitor {
 public:
  HeapTraceInitialHeapVisitor(Isolate* isolate, HeapTrace* heap_trace)
    : ObjectVisitor(isolate), heap_trace_(heap_trace) {}

  void VisitObject(RawObject* raw_obj) {
    heap_trace_->TraceSnapshotAlloc(raw_obj, raw_obj->Size());
  }

 private:
  HeapTrace* heap_trace_;
  DISALLOW_COPY_AND_ASSIGN(HeapTraceInitialHeapVisitor);
};


HeapTrace::HeapTrace() : isolate_initialized_(false), output_stream_(NULL) {
}


HeapTrace::~HeapTrace() {
  if (isolate_initialized_) {
    (*close_callback_)(output_stream_);
  }
}


void HeapTrace::InitOnce(Dart_FileOpenCallback open_callback,
                         Dart_FileWriteCallback write_callback,
                         Dart_FileCloseCallback close_callback) {
  ASSERT(open_callback != NULL);
  ASSERT(write_callback != NULL);
  ASSERT(close_callback != NULL);
  HeapTrace::open_callback_ = open_callback;
  HeapTrace::write_callback_ = write_callback;
  HeapTrace::close_callback_ = close_callback;
  HeapTrace::is_enabled_ = true;
}


ObjectSet* HeapTrace::CreateEmptyObjectSet() const {
  Isolate* isolate = Isolate::Current();
  uword start, end;
  isolate->heap()->StartEndAddress(&start, &end);

  Isolate* vm_isolate = Dart::vm_isolate();
  uword vm_start, vm_end;
  vm_isolate->heap()->StartEndAddress(&vm_start, &vm_end);

  ObjectSet* allocated_set = new ObjectSet(Utils::Minimum(start, vm_start),
                                           Utils::Maximum(end, vm_end));

  return allocated_set;
}


void HeapTrace::ResizeObjectSet() {
  Isolate* isolate = Isolate::Current();
  uword start, end;
  isolate->heap()->StartEndAddress(&start, &end);
  Isolate* vm_isolate = Dart::vm_isolate();
  uword vm_start, vm_end;
  vm_isolate->heap()->StartEndAddress(&vm_start, &vm_end);
  object_set_.Resize(Utils::Minimum(start, vm_start),
                     Utils::Maximum(end, vm_end));
}


void HeapTrace::Init(Isolate* isolate) {
  // Do not trace the VM isolate
  if (isolate == Dart::vm_isolate()) {
    return;
  }
  ASSERT(isolate_initialized_ == false);
  const char* format = "%s.htrace";
  intptr_t len = OS::SNPrint(NULL, 0, format, isolate->name());
  char* filename = new char[len + 1];
  OS::SNPrint(filename, len + 1, format, isolate->name());
  output_stream_ = (*open_callback_)(filename);
  ASSERT(output_stream_ != NULL);
  delete[] filename;
  isolate_initialized_ = true;

  HeapTraceObjectStoreVisitor object_store_visitor(isolate, this);
  isolate->object_store()->VisitObjectPointers(&object_store_visitor);

  // Visit any objects that may have been allocated during startup,
  // before we started tracing.
  HeapTraceInitialHeapVisitor heap_visitor(isolate, this);
  isolate->heap()->IterateObjects(&heap_visitor);
  TraceRoots(isolate);
}


// Allocation Record - 'A' (0x41)
//
// Format:
// 'A'
//  uword - address of allocated object
//  uword - size of allocated object
void HeapTrace::TraceAllocation(uword addr, intptr_t size) {
  if (isolate_initialized_) {
    {
      AllocationRecord rec(this);
      rec.Write(addr);
      rec.Write(size);
    }
    TraceRoots(Isolate::Current());
  }
}


// Snapshot Allocation Record - 'B' (0x41)
//
// Format:
// 'B'
//  uword - address of allocated object
//  uword - size of allocated object
void HeapTrace::TraceSnapshotAlloc(RawObject* obj, intptr_t size) {
  if (isolate_initialized_) {
    SnapshotAllocationRecord rec(this);
    rec.Write(RawObject::ToAddr(obj));
    rec.Write(static_cast<uword>(size));
  }
}


// Allocate Zone Handle Record - 'Z' (0x5a)
//
// Format:
//  'Z'
//  uword - handle address (where the handle is pointing)
//  uword - zone address (address of the zone the handle is in)
void HeapTrace::TraceAllocateZoneHandle(uword handle, uword zone_addr) {
  if (isolate_initialized_) {
    AllocZoneHandleRecord rec(this);
    rec.Write(handle);
    rec.Write(zone_addr);
  }
}


// Delete Zone Record - 'z' (0x7a)
//
// Format:
//  'z'
//  uword - zone address (all the handles in that zone are now gone)
void HeapTrace::TraceDeleteZone(Zone* zone) {
  if (isolate_initialized_) {
    DeleteZoneRecord rec(this);
    rec.Write(reinterpret_cast<uword>(zone));
  }
}


// Delete Scoped Hanldes Record - 's' (0x73)
//
// Format:
//  's'
void HeapTrace::TraceDeleteScopedHandles() {
  if (isolate_initialized_) {
    DeleteScopedHandlesRecord rec(this);
  }
}


//  Copy Record - 'C' (0x43)
//
//  Format:
//   'C'
//   uword - old address
//   uword - new address
void HeapTrace::TraceCopy(uword from_addr, uword to_addr) {
    if (isolate_initialized_) {
      CopyRecord rec(this);
      rec.Write(from_addr);
      rec.Write(to_addr);
  }
}


// Object Store Recorda - 'O'(0x4f)
//
// Format:
//  'O'
//  uword - address
void HeapTrace::TraceObjectStorePointer(uword addr) {
  if (isolate_initialized_) {
    ObjectStoreRecord rec(this);
    rec.Write(addr);
  }
}


// Promotion Records - 'P' (0x50)
//
// Format:
//  'P'
//  uword - old address
//  uword - new address
void HeapTrace::TracePromotion(uword old_addr, uword promoted_addr) {
  if (isolate_initialized_) {
    PromotionRecord rec(this);
    rec.Write(old_addr);
    rec.Write(promoted_addr);
  }
}


// Death Range Record - 'L' (0x4c)
//
// Format:
//  'L'
//  uword - inclusive start address of the space being left
//  uword - exclusive end address of the space being left
void HeapTrace::TraceDeathRange(uword inclusive_start, uword exclusive_end) {
  if (isolate_initialized_) {
    DeathRangeRecord rec(this);
    rec.Write(inclusive_start);
    rec.Write(exclusive_end);
  }
}


// Register Class Record - 'K' (0x4b)
//
// Format:
//  'K'
//  uword - address ( the address of the class)
void HeapTrace::TraceRegisterClass(const Class& cls) {
  if (isolate_initialized_) {
    RegisterClassRecord rec(this);
    rec.Write(RawObject::ToAddr(cls.raw()));
  }
}


// Scoped Handle Record - 'H' (0x48)
//
// Format:
//  'H'
//  uword - adress of the scoped handle (where it is pointing)
void HeapTrace::TraceScopedHandle(uword handle) {
  if (isolate_initialized_) {
    AllocScopedHandleRecord rec(this);
    rec.Write(handle);
  }
}


// Root Record - 'R' (0x52)
//
// Format:
// 'R'
// uword - address
void HeapTrace::TraceSingleRoot(uword root_addr) {
  if (isolate_initialized_) {
    RootRecord rec(this);
    rec.Write(root_addr);
  }
}


// Sweep Record - 'S'
//
// Format:
// 'S'
// uword - address
void HeapTrace::TraceSweep(uword sweept_addr) {
  if (isolate_initialized_) {
    SweepRecord rec(this);
    rec.Write(sweept_addr);
  }
}


// Does not output any records directly,
// but does call TraceSingleRoot
void HeapTrace::TraceRoots(Isolate* isolate) {
  if (isolate_initialized_) {
    ResizeObjectSet();
    HeapTraceVisitor visitor(isolate, this, &object_set_);
    HeapTraceScopedHandleVisitor handle_visitor(isolate, this);

    bool visit_prologue_weak_handles = true;
    bool validate_frames = false;

    // Visit objects in per isolate stubs.
    StubCode::VisitObjectPointers(&visitor);

    // stack
    StackFrameIterator frames_iterator(validate_frames);
    StackFrame* frame = frames_iterator.NextFrame();
    while (frame != NULL) {
      frame->VisitObjectPointers(&visitor);
      frame = frames_iterator.NextFrame();
    }

    if (isolate->api_state() != NULL) {
      isolate->api_state()->VisitObjectPointers(&visitor,
                                                visit_prologue_weak_handles);
    }

    // Visit the top context which is stored in the isolate.
    RawContext* top_context = isolate->top_context();
    visitor.VisitPointer(reinterpret_cast<RawObject**>(&top_context));

    // Visit the currently active IC data array.
    RawArray* ic_data_array = isolate->ic_data_array();
    visitor.VisitPointer(reinterpret_cast<RawObject**>(&ic_data_array));

    // Visit objects in the debugger.
    isolate->debugger()->VisitObjectPointers(&visitor);

    isolate->current_zone()->handles()->
        VisitUnvisitedScopedHandles(&handle_visitor);

    object_set_.FastClear();
  }
}


// Store Record - 'U' (0x55)
//
// Format:
//  'U'
//  uword - originating object address (where a pointer is being stored)
//  uword - byte offset into origin where the pointer is being stored
//  uword - value of the pointer being stored
void HeapTrace::TraceStoreIntoObject(uword object,
                                     uword field_addr,
                                     uword value) {
  if (isolate_initialized_) {
    // We don't care about pointers into the VM_Islate heap, so skip them.
    // There should not be any pointers /out/ of the VM isolate; so we
    // do not check object.
    if (Isolate::Current()->heap()->Contains(value)) {
      StoreRecord rec(this);
      uword slot_offset =  field_addr - object;

      rec.Write(object);
      rec.Write(slot_offset);
      rec.Write(value);
    }
  }
}


// Mark Sweep Start Record - '{' (0x7b)
//
// Format:
//  '{'
void HeapTrace::TraceMarkSweepStart() {
  if (isolate_initialized_) {
    MarkSweepStartRecord rec(this);
  }
}


// Mark Sweep Finish Record - '}' (0x7d)
//
// Format:
//  '}'
void HeapTrace::TraceMarkSweepFinish() {
  if (isolate_initialized_) {
    MarkSweepFinishRecord rec(this);
  }
}

}  // namespace dart

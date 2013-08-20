// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap_histogram.h"

#include "platform/assert.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/json_stream.h"

namespace dart {

DEFINE_FLAG(bool, print_object_histogram, false,
            "Print average object histogram at isolate shutdown");

class ObjectHistogramVisitor : public ObjectVisitor {
 public:
  explicit ObjectHistogramVisitor(Isolate* isolate) : ObjectVisitor(isolate) { }

  virtual void VisitObject(RawObject* obj) {
    isolate()->object_histogram()->Add(obj);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(ObjectHistogramVisitor);
};


void ObjectHistogram::Collect() {
  major_gc_count_++;
  ObjectHistogramVisitor object_visitor(isolate_);
  isolate_->heap()->IterateObjects(&object_visitor);
}


ObjectHistogram::ObjectHistogram(Isolate* isolate) {
  isolate_ = isolate;
  major_gc_count_ = 0;
  table_length_ = 512;
  table_ = reinterpret_cast<Element*>(
    calloc(table_length_, sizeof(Element)));  // NOLINT
  for (intptr_t index = 0; index < table_length_; index++) {
    table_[index].class_id_ = index;
  }
}


ObjectHistogram::~ObjectHistogram() {
  free(table_);
}


void ObjectHistogram::RegisterClass(const Class& cls) {
  intptr_t class_id = cls.id();
  if (class_id < table_length_) return;
  // Resize the table.
  intptr_t new_table_length = table_length_ * 2;
  Element* new_table = reinterpret_cast<Element*>(
          realloc(table_, new_table_length * sizeof(Element)));  // NOLINT
  for (intptr_t i = table_length_; i < new_table_length; i++) {
    new_table[i].class_id_ = i;
    new_table[i].count_ = 0;
    new_table[i].size_ = 0;
  }
  table_ = new_table;
  table_length_ = new_table_length;
  ASSERT(class_id < table_length_);
}


void ObjectHistogram::Add(RawObject* obj) {
  intptr_t class_id = obj->GetClassId();
  if (class_id == kFreeListElement) return;
  ASSERT(class_id < table_length_);
  table_[class_id].Add(obj->Size());
}


int ObjectHistogram::compare(const Element** a, const Element** b) {
  return (*b)->size_ - (*a)->size_;
}


ObjectHistogram::Element** ObjectHistogram::GetSortedArray(
      intptr_t* array_length) {
  intptr_t length = 0;
  for (intptr_t index = 0; index < table_length_; index++) {
    if (table_[index].count_ > 0) length++;
  }
  // Then add them to a new array and sort.
  Element** array = reinterpret_cast<Element**>(
    calloc(length, sizeof(Element*)));  // NOLINT
  intptr_t pos = 0;
  for (intptr_t index = 0; index < table_length_; index++) {
    if (table_[index].count_ > 0) array[pos++] = &table_[index];
  }
  typedef int (*CmpFunc)(const void*, const void*);
  qsort(array, length, sizeof(Element*),  // NOLINT
        reinterpret_cast<CmpFunc>(compare));

  *array_length = length;
  return array;
}

void ObjectHistogram::Print() {
  OS::Print("Printing Object Histogram\n");
  OS::Print("____bytes___count_description____________\n");
  // First count the number of non empty entries.

  intptr_t length = 0;
  Element** array = NULL;

  array = GetSortedArray(&length);
  ASSERT(array != NULL);

  // Finally print the sorted array.
  Class& cls = Class::Handle();
  String& str = String::Handle();
  Library& lib = Library::Handle();
  for (intptr_t pos = 0; pos < length; pos++) {
    Element* e = array[pos];
    if (e->count_ > 0) {
      cls = isolate_->class_table()->At(e->class_id_);
      str = cls.Name();
      lib = cls.library();
      OS::Print("%9" Pd " %7" Pd " ",
                e->size_ / major_gc_count_,
                e->count_ / major_gc_count_);
      if (e->class_id_ < kInstanceCid) {
        OS::Print("`%s`", str.ToCString());  // VM names.
      } else {
        OS::Print("%s", str.ToCString());
      }
      if (lib.IsNull()) {
        OS::Print("\n");
      } else {
        str = lib.url();
        OS::Print(", library \'%s\'\n", str.ToCString());
      }
    }
  }
  // Deallocate the array for sorting.
  free(array);
}

void ObjectHistogram::PrintToJSONStream(JSONStream* stream) {
  intptr_t length = 0;
  Element** array = NULL;

  array = GetSortedArray(&length);
  ASSERT(array != NULL);

  // Finally print the sorted array.
  Class& cls = Class::Handle();
  String& str = String::Handle();
  Library& lib = Library::Handle();

  intptr_t size_sum = 0;
  intptr_t count_sum = 0;
  stream->OpenObject();
  stream->PrintProperty("type", "ObjectHistogram");
  stream->OpenArray("properties");
  stream->PrintValue("size");
  stream->PrintValue("count");
  stream->CloseArray();
  stream->OpenArray("members");
  for (intptr_t pos = 0; pos < length; pos++) {
    Element* e = array[pos];
    if (e->count_ > 0) {
      cls = isolate_->class_table()->At(e->class_id_);
      str = cls.Name();
      lib = cls.library();
      stream->OpenObject();
      stream->PrintProperty("type", "ObjectHistogramEntry");
      // It should not be possible to overflow here because the total
      // size of the heap is bounded and we are dividing the value
      // by the number of major gcs that have occurred.
      size_sum += (e->size_ / major_gc_count_);
      count_sum += (e->count_ / major_gc_count_);
      stream->PrintProperty("size", e->size_ / major_gc_count_);
      stream->PrintProperty("count", e->count_ / major_gc_count_);
      stream->PrintProperty("name", str.ToCString());
      if (lib.IsNull()) {
        stream->PrintProperty("category", "");
      } else {
        str = lib.url();
        stream->PrintProperty("category", str.ToCString());
      }
      stream->CloseObject();
    }
  }
  stream->CloseArray();
  stream->OpenObject("sums");
  stream->PrintProperty("size", size_sum);
  stream->PrintProperty("count", count_sum);
  stream->CloseObject();
  stream->CloseObject();

  // Deallocate the array for sorting.
  free(array);
}


}  // namespace dart

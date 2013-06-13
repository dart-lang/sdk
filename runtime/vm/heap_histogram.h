// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_HISTOGRAM_H_
#define VM_HEAP_HISTOGRAM_H_

#include "platform/assert.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/raw_object.h"

namespace dart {

DECLARE_FLAG(bool, print_object_histogram);

// ObjectHistogram is used to compute an average object histogram over
// the lifetime of an isolate and then print the histogram when the isolate
// is shut down. Information is gathered at the back-edge of each major GC
// event. When an object histogram is collected for an isolate, an extra major
// GC is performed just prior to shutdown.
class ObjectHistogram {
 public:
  explicit ObjectHistogram(Isolate* isolate);
  ~ObjectHistogram();

  // Called when a new class is registered in the isolate.
  void RegisterClass(const Class& cls);

  // Collect sample for the histogram. Called at back-edge of major GC.
  void Collect();

  // Print the histogram on stdout.
  void Print();

 private:
  // Add obj to histogram
  void Add(RawObject* obj);

  // For each class an Element keeps track of the accounting.
  class Element : public ValueObject {
   public:
    void Add(int size) {
      count_++;
      size_ += size;
    }
    intptr_t class_id_;
    intptr_t count_;
    intptr_t size_;
  };

  // Compare function for sorting result.
  static int compare(const Element** a, const Element** b);

  intptr_t major_gc_count_;
  intptr_t table_length_;
  Element* table_;
  Isolate* isolate_;

  friend class ObjectHistogramVisitor;

  DISALLOW_COPY_AND_ASSIGN(ObjectHistogram);
};

}  // namespace dart

#endif  // VM_HEAP_HISTOGRAM_H_


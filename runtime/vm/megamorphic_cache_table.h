// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MEGAMORPHIC_CACHE_TABLE_H_
#define VM_MEGAMORPHIC_CACHE_TABLE_H_

#include "vm/allocation.h"

namespace dart {

class Array;
class Function;
class ObjectPointerVisitor;
class RawArray;
class RawFunction;
class RawMegamorphicCache;
class RawString;
class String;

class MegamorphicCacheTable {
 public:
  MegamorphicCacheTable();
  ~MegamorphicCacheTable();

  RawFunction* miss_handler() const { return miss_handler_; }
  void InitMissHandler();

  RawMegamorphicCache* Lookup(const String& name, const Array& descriptor);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void PrintSizes();

 private:
  struct Entry {
    RawString* name;
    RawArray* descriptor;
    RawMegamorphicCache* cache;
  };

  static const int kCapacityIncrement = 128;

  RawFunction* miss_handler_;
  intptr_t capacity_;
  intptr_t length_;
  Entry* table_;

  DISALLOW_COPY_AND_ASSIGN(MegamorphicCacheTable);
};

}  // namespace dart

#endif  // VM_MEGAMORPHIC_CACHE_TABLE_H_

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_TABLE_H_
#define VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/globals.h"

namespace dart {

class Class;
class Function;
template <typename T> class ZoneGrowableArray;
class ObjectPointerVisitor;
class RawClass;
class String;

class ClassTable {
 public:
  ClassTable();
  ~ClassTable();

  RawClass* At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }

  intptr_t IsValidIndex(intptr_t index) const {
    return (index > 0) && (index < top_);
  }

  void Register(const Class& cls);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void Print();

  // Returns true if the class given by its cid has subclasses.
  // Must not be called for kDartObjectCid.
  bool HasSubclasses(intptr_t cid) const;

  // Returns an array containing the cids of the direct and indirect subclasses
  // of the class given by its cid.
  // Must not be called for kDartObjectCid.
  ZoneGrowableArray<intptr_t>* GetSubclassIdsOf(intptr_t cid) const;

  // Returns an array containing instance functions of the given name and
  // belonging to the classes given by their cids.
  // Cids must not contain kDartObjectCid.
  ZoneGrowableArray<Function*>* GetNamedInstanceFunctionsOf(
      const ZoneGrowableArray<intptr_t>& cids,
      const String& function_name) const;

  // Returns an array of functions overriding the given function.
  // Must not be called for a function of class Object.
  ZoneGrowableArray<Function*>* GetOverridesOf(const Function& function) const;

  static intptr_t table_offset() {
    return OFFSET_OF(ClassTable, table_);
  }

 private:
  static const int initial_capacity_ = 512;
  static const int capacity_increment_ = 256;

  intptr_t top_;
  intptr_t capacity_;

  RawClass** table_;

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // VM_CLASS_TABLE_H_

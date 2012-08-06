// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEOPT_INSTRUCTIONS_H_
#define VM_DEOPT_INSTRUCTIONS_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

class Location;
class Value;

// Represents one deopt instruction, e.g, setup return address, store object,
// store register, etc. The target is defined by instruction's position in
// the deopt-info array.
class DeoptInstr : public ZoneAllocated {
 public:
  static DeoptInstr* Create(intptr_t kind_as_int, intptr_t from_index);

  virtual const char* ToCString() const = 0;

 protected:
  enum Kind {
    kSetRetAddress,
    kCopyConstant,
    kCopyRegister,
    kCopyStackSlot,
    kSetPcMarker,
    kSetCallerFp,
    kSetCallerPc,
  };

  DeoptInstr() {}

  virtual DeoptInstr::Kind kind() const = 0;
  virtual intptr_t from_index() const = 0;

  friend class DeoptInfoBuilder;

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptInstr);
};



// Builds one instance of DeoptInfo. Call AddXXX methods in the order of
// their target, starting wih deoptimized code continuation pc and ending with
// the first argument of the deoptimized code.
class DeoptInfoBuilder : public ValueObject {
 public:
  // 'object_table' holds all objects referred to by DeoptInstr in
  // all DeoptInfo instances for a single Code object.
  DeoptInfoBuilder(const GrowableObjectArray& object_table,
                   const intptr_t num_args)
      : instructions_(),
        object_table_(object_table),
        num_args_(num_args) {}

  // Will be neeeded for inlined functions, currently trivial.
  void AddReturnAddress(const Function& function,
                        intptr_t deopt_id,
                        intptr_t to_index);
  // Copy from optimized frame to unoptimized.
  void AddCopy(const Location& from_loc,
               const Value& from_value,
               intptr_t to_index);
  void AddPcMarker(const Function& function, intptr_t to_index);
  void AddCallerFp(intptr_t to_index);
  void AddCallerPc(intptr_t to_index);

  RawDeoptInfo* CreateDeoptInfo() const;

 private:
  intptr_t FindOrAddObjectInTable(const Object& obj) const;

  GrowableArray<DeoptInstr*> instructions_;
  const GrowableObjectArray& object_table_;
  const intptr_t num_args_;

  DISALLOW_COPY_AND_ASSIGN(DeoptInfoBuilder);
};

}  // namespace dart

#endif  // VM_DEOPT_INSTRUCTIONS_H_


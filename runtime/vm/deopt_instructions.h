// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEOPT_INSTRUCTIONS_H_
#define VM_DEOPT_INSTRUCTIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

class Location;
class Value;

// Holds all data relevant for execution of deoptimization instructions.
class DeoptimizationContext : public ValueObject {
 public:
  // 'to_frame_start' points to the return address just below the frame's
  // stack pointer. 'num_args' is 0 if there are no arguments or if there
  // are optional arguments.
  DeoptimizationContext(intptr_t* to_frame_start,
                        intptr_t to_frame_size,
                        const Array& object_table,
                        intptr_t num_args);

  intptr_t* GetFromFrameAddressAt(intptr_t index) const {
    ASSERT((0 <= index) && (index < from_frame_size_));
    return &from_frame_[index];
  }

  intptr_t* GetToFrameAddressAt(intptr_t index) const {
    ASSERT((0 <= index) && (index < to_frame_size_));
    return &to_frame_[index];
  }

  intptr_t* GetFromFpAddress() const;
  intptr_t* GetFromPcAddress() const;

  RawObject* ObjectAt(intptr_t index) const {
    return object_table_.At(index);
  }

  intptr_t RegisterValue(Register reg) const {
    return registers_copy_[reg];
  }

  double XmmRegisterValue(XmmRegister reg) const {
    return xmm_registers_copy_[reg];
  }

  Isolate* isolate() const { return isolate_; }

  intptr_t from_frame_size() const { return from_frame_size_; }

 private:
  const Array& object_table_;
  intptr_t* to_frame_;
  const intptr_t to_frame_size_;
  intptr_t* from_frame_;
  intptr_t from_frame_size_;
  intptr_t* registers_copy_;
  double* xmm_registers_copy_;
  const intptr_t num_args_;
  Isolate* isolate_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationContext);
};



// Represents one deopt instruction, e.g, setup return address, store object,
// store register, etc. The target is defined by instruction's position in
// the deopt-info array.
class DeoptInstr : public ZoneAllocated {
 public:
  static DeoptInstr* Create(intptr_t kind_as_int, intptr_t from_index);

  DeoptInstr() {}
  virtual ~DeoptInstr() {}

  virtual const char* ToCString() const = 0;

  virtual void Execute(DeoptimizationContext* deopt_context,
                       intptr_t to_index) = 0;

 protected:
  enum Kind {
    kSetRetAfterAddress,
    kSetRetBeforeAddress,
    kCopyConstant,
    kCopyRegister,
    kCopyXmmRegister,
    kCopyStackSlot,
    kCopyDoubleStackSlot,
    kSetPcMarker,
    kSetCallerFp,
    kSetCallerPc,
  };

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

  // Return address before instruction.
  void AddReturnAddressBefore(const Function& function,
                              intptr_t deopt_id,
                              intptr_t to_index);

  // Return address after instruction.
  void AddReturnAddressAfter(const Function& function,
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

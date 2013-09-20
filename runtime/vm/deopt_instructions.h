// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEOPT_INSTRUCTIONS_H_
#define VM_DEOPT_INSTRUCTIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

class Location;
class Value;
class MaterializeObjectInstr;

// Holds all data relevant for execution of deoptimization instructions.
class DeoptimizationContext : public ValueObject {
 public:
  // 'to_frame_start' points to the fixed size portion of the frame under sp.
  // 'num_args' is 0 if there are no arguments or if there are optional
  // arguments.
  DeoptimizationContext(intptr_t* to_frame_start,
                        intptr_t to_frame_size,
                        const Array& object_table,
                        intptr_t num_args,
                        DeoptReasonId deopt_reason);

  intptr_t* GetFromFrameAddressAt(intptr_t index) const {
    ASSERT((0 <= index) && (index < from_frame_size_));
    return &from_frame_[index];
  }

  intptr_t* GetToFrameAddressAt(intptr_t index) const {
    ASSERT((0 <= index) && (index < to_frame_size_));
    return &to_frame_[index];
  }

  intptr_t GetFromFp() const;
  intptr_t GetFromPp() const;
  intptr_t GetFromPc() const;

  intptr_t GetCallerFp() const;
  void SetCallerFp(intptr_t callers_fp);

  RawObject* ObjectAt(intptr_t index) const {
    return object_table_.At(index);
  }

  intptr_t RegisterValue(Register reg) const {
    return registers_copy_[reg];
  }

  double FpuRegisterValue(FpuRegister reg) const {
    return *reinterpret_cast<double*>(&fpu_registers_copy_[reg]);
  }

  int64_t FpuRegisterValueAsInt64(FpuRegister reg) const {
    return *reinterpret_cast<int64_t*>(&fpu_registers_copy_[reg]);
  }

  simd128_value_t FpuRegisterValueAsSimd128(FpuRegister reg) const {
    const float* address = reinterpret_cast<float*>(&fpu_registers_copy_[reg]);
    return simd128_value_t().readFrom(address);
  }

  Isolate* isolate() const { return isolate_; }

  intptr_t from_frame_size() const { return from_frame_size_; }

  DeoptReasonId deopt_reason() const { return deopt_reason_; }

 private:
  const Array& object_table_;
  intptr_t* to_frame_;
  const intptr_t to_frame_size_;
  intptr_t* from_frame_;
  intptr_t from_frame_size_;
  intptr_t* registers_copy_;
  fpu_register_t* fpu_registers_copy_;
  const intptr_t num_args_;
  const DeoptReasonId deopt_reason_;
  intptr_t caller_fp_;
  Isolate* isolate_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationContext);
};



// Represents one deopt instruction, e.g, setup return address, store object,
// store register, etc. The target is defined by instruction's position in
// the deopt-info array.
class DeoptInstr : public ZoneAllocated {
 public:
  enum Kind {
    kRetAddress,
    kConstant,
    kRegister,
    kFpuRegister,
    kInt64FpuRegister,
    kFloat32x4FpuRegister,
    kUint32x4FpuRegister,
    kStackSlot,
    kDoubleStackSlot,
    kInt64StackSlot,
    kFloat32x4StackSlot,
    kUint32x4StackSlot,
    kPcMarker,
    kPp,
    kCallerFp,
    kCallerPp,
    kCallerPc,
    kSuffix,
    kMaterializedObjectRef,
    kMaterializeObject
  };

  static DeoptInstr* Create(intptr_t kind_as_int, intptr_t from_index);

  DeoptInstr() {}
  virtual ~DeoptInstr() {}

  virtual const char* ToCString() const = 0;

  virtual void Execute(DeoptimizationContext* deopt_context,
                       intptr_t* to_addr) = 0;

  virtual DeoptInstr::Kind kind() const = 0;

  bool Equals(const DeoptInstr& other) const {
    return (kind() == other.kind()) && (from_index() == other.from_index());
  }

  // Decode the payload of a suffix command.  Return the suffix length and
  // set the output parameter info_number to the index of the shared suffix.
  static intptr_t DecodeSuffix(intptr_t from_index, intptr_t* info_number);

  // Get the function and return address which is encoded in this
  // kRetAfterAddress deopt instruction.
  static uword GetRetAddress(DeoptInstr* instr,
                             const Array& object_table,
                             Function* func);

  // Return number of initialized fields in the object that will be
  // materialized by kMaterializeObject instruction.
  static intptr_t GetFieldCount(DeoptInstr* instr) {
    ASSERT(instr->kind() == DeoptInstr::kMaterializeObject);
    return instr->from_index();
  }

 protected:
  friend class DeoptInfoBuilder;

  virtual intptr_t from_index() const = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptInstr);
};


// Builds a deoptimization info table, one DeoptInfo at a time.  Call AddXXX
// methods in the order of their target, starting wih deoptimized code
// continuation pc and ending with the first argument of the deoptimized
// code.  Call CreateDeoptInfo to write the accumulated instructions into
// the heap and reset the builder's internal state for the next DeoptInfo.
class DeoptInfoBuilder : public ValueObject {
 public:
  explicit DeoptInfoBuilder(const intptr_t num_args);

  // 'object_table' holds all objects referred to by DeoptInstr in
  // all DeoptInfo instances for a single Code object.
  const GrowableObjectArray& object_table() { return object_table_; }

  // Return address before instruction.
  void AddReturnAddress(const Function& function,
                        intptr_t deopt_id,
                        intptr_t to_index);

  // Copy from optimized frame to unoptimized.
  void AddCopy(Value* value, const Location& from_loc, intptr_t to_index);
  void AddPcMarker(const Function& function, intptr_t to_index);
  void AddPp(const Function& function, intptr_t to_index);
  void AddCallerFp(intptr_t to_index);
  void AddCallerPp(intptr_t to_index);
  void AddCallerPc(intptr_t to_index);

  // Add object to be materialized. Emit kMaterializeObject instruction.
  void AddMaterialization(MaterializeObjectInstr* mat);

  // For every materialized object emit instructions describing data required
  // for materialization: class of the instance to allocate and field-value
  // pairs for initialization.
  // Emitted instructions are expected to follow fixed size section of frame
  // emitted first. This way they become a part of the bottom-most deoptimized
  // frame and are discoverable by GC.
  // At deoptimization they will be removed by the stub at the very end:
  // after they were used to materialize objects.
  // Returns the index of the next stack slot. Used for verification.
  intptr_t EmitMaterializationArguments(intptr_t to_index);

  RawDeoptInfo* CreateDeoptInfo(const Array& deopt_table);

  // Mark the actual start of the frame description after all materialization
  // instructions were emitted. Used for verification purposes.
  void MarkFrameStart() {
    ASSERT(frame_start_ == -1);
    frame_start_ = instructions_.length();
  }

 private:
  class TrieNode;

  intptr_t FindOrAddObjectInTable(const Object& obj) const;
  intptr_t FindMaterialization(MaterializeObjectInstr* mat) const;
  intptr_t CalculateStackIndex(const Location& from_loc) const;

  intptr_t FrameSize() const {
    return instructions_.length() - frame_start_;
  }

  void AddConstant(const Object& obj, intptr_t to_index);

  GrowableArray<DeoptInstr*> instructions_;
  const GrowableObjectArray& object_table_;
  const intptr_t num_args_;

  // Used to compress entries by sharing suffixes.
  TrieNode* trie_root_;
  intptr_t current_info_number_;

  intptr_t frame_start_;
  GrowableArray<MaterializeObjectInstr*> materializations_;

  DISALLOW_COPY_AND_ASSIGN(DeoptInfoBuilder);
};


// Utilities for managing the deopt table and its entries.  The table is
// stored in an Array in the heap.  It consists of triples of (PC offset,
// info, reason).  Elements of each entry are stored consecutively in the
// array.
class DeoptTable : public AllStatic {
 public:
  // Return the array size in elements for a given number of table entries.
  static intptr_t SizeFor(intptr_t length);

  // Set the entry at the given index into the table (not an array index).
  static void SetEntry(const Array& table,
                       intptr_t index,
                       const Smi& offset,
                       const DeoptInfo& info,
                       const Smi& reason);

  // Return the length of the table in entries.
  static intptr_t GetLength(const Array& table);

  // Set the output parameters (offset, info, reason) to the entry values at
  // the index into the table (not an array index).
  static void GetEntry(const Array& table,
                       intptr_t index,
                       Smi* offset,
                       DeoptInfo* info,
                       Smi* reason);

 private:
  static const intptr_t kEntrySize = 3;
};

}  // namespace dart

#endif  // VM_DEOPT_INSTRUCTIONS_H_

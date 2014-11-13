// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEOPT_INSTRUCTIONS_H_
#define VM_DEOPT_INSTRUCTIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/deferred_objects.h"
#include "vm/growable_array.h"
#include "vm/locations.h"
#include "vm/object.h"

namespace dart {

class Location;
class Value;
class MaterializeObjectInstr;
class StackFrame;

// Holds all data relevant for execution of deoptimization instructions.
class DeoptContext {
 public:
  enum DestFrameOptions {
    kDestIsOriginalFrame,   // Replace the original frame with deopt frame.
    kDestIsAllocated        // Write deopt frame to a buffer.
  };

  DeoptContext(const StackFrame* frame,
               const Code& code,
               DestFrameOptions dest_options,
               fpu_register_t* fpu_registers,
               intptr_t* cpu_registers);
  virtual ~DeoptContext();

  // Returns the offset of the dest fp from the dest sp.  Used in
  // runtime code to adjust the stack size before deoptimization.
  intptr_t DestStackAdjustment() const;

  intptr_t* GetSourceFrameAddressAt(intptr_t index) const {
    ASSERT(source_frame_ != NULL);
    ASSERT((0 <= index) && (index < source_frame_size_));
    return &source_frame_[index];
  }

  intptr_t GetSourceFp() const;
  intptr_t GetSourcePp() const;
  intptr_t GetSourcePc() const;

  intptr_t GetCallerFp() const;
  void SetCallerFp(intptr_t callers_fp);

  RawObject* ObjectAt(intptr_t index) const {
    const Array& object_table = Array::Handle(object_table_);
    return object_table.At(index);
  }

  intptr_t RegisterValue(Register reg) const {
    ASSERT(cpu_registers_ != NULL);
    ASSERT(reg >= 0);
    ASSERT(reg < kNumberOfCpuRegisters);
    return cpu_registers_[reg];
  }

  double FpuRegisterValue(FpuRegister reg) const {
    ASSERT(fpu_registers_ != NULL);
    ASSERT(reg >= 0);
    ASSERT(reg < kNumberOfFpuRegisters);
    return *reinterpret_cast<double*>(&fpu_registers_[reg]);
  }

  simd128_value_t FpuRegisterValueAsSimd128(FpuRegister reg) const {
    ASSERT(fpu_registers_ != NULL);
    ASSERT(reg >= 0);
    ASSERT(reg < kNumberOfFpuRegisters);
    const float* address = reinterpret_cast<float*>(&fpu_registers_[reg]);
    return simd128_value_t().readFrom(address);
  }

  void set_dest_frame(intptr_t* dest_frame) {
    ASSERT(dest_frame != NULL && dest_frame_ == NULL);
    dest_frame_ = dest_frame;
  }

  Isolate* isolate() const { return isolate_; }

  intptr_t source_frame_size() const { return source_frame_size_; }
  intptr_t dest_frame_size() const { return dest_frame_size_; }

  RawCode* code() const { return code_; }

  ICData::DeoptReasonId deopt_reason() const { return deopt_reason_; }
  bool HasDeoptFlag(ICData::DeoptFlags flag) {
    return (deopt_flags_ & flag) != 0;
  }

  RawDeoptInfo* deopt_info() const { return deopt_info_; }

  // Fills the destination frame but defers materialization of
  // objects.
  void FillDestFrame();

  // Materializes all deferred objects.  Returns the total number of
  // artificial arguments used during deoptimization.
  intptr_t MaterializeDeferredObjects();

  RawArray* DestFrameAsArray();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void DeferMaterializedObjectRef(intptr_t idx, intptr_t* slot) {
    deferred_slots_ = new DeferredObjectRef(
        idx,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  void DeferMaterialization(double value, RawDouble** slot) {
    deferred_slots_ = new DeferredDouble(
        value,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  void DeferMintMaterialization(int64_t value, RawMint** slot) {
    deferred_slots_ = new DeferredMint(
        value,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawFloat32x4** slot) {
    deferred_slots_ = new DeferredFloat32x4(
        value,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawFloat64x2** slot) {
    deferred_slots_ = new DeferredFloat64x2(
        value,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawInt32x4** slot) {
    deferred_slots_ = new DeferredInt32x4(
        value,
        reinterpret_cast<RawObject**>(slot),
        deferred_slots_);
  }

  DeferredObject* GetDeferredObject(intptr_t idx) const {
    return deferred_objects_[idx];
  }

 private:
  intptr_t* GetDestFrameAddressAt(intptr_t index) const {
    ASSERT(dest_frame_ != NULL);
    ASSERT((0 <= index) && (index < dest_frame_size_));
    return &dest_frame_[index];
  }

  void PrepareForDeferredMaterialization(intptr_t count) {
    if (count > 0) {
      deferred_objects_ = new DeferredObject*[count];
      deferred_objects_count_ = count;
    }
  }

  // Sets the materialized value for some deferred object.
  //
  // Claims ownership of the memory for 'object'.
  void SetDeferredObjectAt(intptr_t idx, DeferredObject* object) {
    deferred_objects_[idx] = object;
  }

  intptr_t DeferredObjectsCount() const {
    return deferred_objects_count_;
  }

  RawCode* code_;
  RawArray* object_table_;
  RawDeoptInfo* deopt_info_;
  bool dest_frame_is_allocated_;
  intptr_t* dest_frame_;
  intptr_t dest_frame_size_;
  bool source_frame_is_allocated_;
  intptr_t* source_frame_;
  intptr_t source_frame_size_;
  intptr_t* cpu_registers_;
  fpu_register_t* fpu_registers_;
  intptr_t num_args_;
  ICData::DeoptReasonId deopt_reason_;
  uint32_t deopt_flags_;
  intptr_t caller_fp_;
  Isolate* isolate_;

  DeferredSlot* deferred_slots_;

  intptr_t deferred_objects_count_;
  DeferredObject** deferred_objects_;

  DISALLOW_COPY_AND_ASSIGN(DeoptContext);
};



// Represents one deopt instruction, e.g, setup return address, store object,
// store register, etc. The target is defined by instruction's position in
// the deopt-info array.
class DeoptInstr : public ZoneAllocated {
 public:
  enum Kind {
    kRetAddress,
    kConstant,
    kWord,
    kDouble,
    kFloat32x4,
    kFloat64x2,
    kInt32x4,
    // Mints are split into low and high words on 32-bit architectures. Each
    // word can be in a register or stack slot. Note Mint pairs are only
    // used on 32-bit architectures.
    kMintPair,
    // Mints are held in one word on 64-bit architectures.
    kMint,
    kInt32,
    kUint32,
    kPcMarker,
    kPp,
    kCallerFp,
    kCallerPp,
    kCallerPc,
    kSuffix,
    kMaterializedObjectRef,
    kMaterializeObject
  };

  static DeoptInstr* Create(intptr_t kind_as_int, intptr_t source_index);

  DeoptInstr() {}
  virtual ~DeoptInstr() {}

  virtual const char* ToCString() const {
    const char* args = ArgumentsToCString();
    if (args != NULL) {
      return Isolate::Current()->current_zone()->PrintToString(
          "%s(%s)", KindToCString(kind()), args);
    } else {
      return KindToCString(kind());
    }
  }

  virtual void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) = 0;

  virtual DeoptInstr::Kind kind() const = 0;

  bool Equals(const DeoptInstr& other) const {
    return (kind() == other.kind()) && (source_index() == other.source_index());
  }

  // Decode the payload of a suffix command.  Return the suffix length and
  // set the output parameter info_number to the index of the shared suffix.
  static intptr_t DecodeSuffix(intptr_t source_index, intptr_t* info_number);

  // Get the code and return address which is encoded in this
  // kRetAfterAddress deopt instruction.
  static uword GetRetAddress(DeoptInstr* instr,
                             const Array& object_table,
                             Code* code);

  // Return number of initialized fields in the object that will be
  // materialized by kMaterializeObject instruction.
  static intptr_t GetFieldCount(DeoptInstr* instr) {
    ASSERT(instr->kind() == DeoptInstr::kMaterializeObject);
    return instr->source_index();
  }

 protected:
  friend class DeoptInfoBuilder;

  virtual intptr_t source_index() const = 0;

  virtual const char* ArgumentsToCString() const {
    return NULL;
  }

 private:
  static const char* KindToCString(Kind kind);

  DISALLOW_COPY_AND_ASSIGN(DeoptInstr);
};


// Helper class that allows to read a value of the given register from
// the DeoptContext as the specified type.
// It calls different method depending on which kind of register (cpu/fpu) and
// destination types are specified.
template<typename RegisterType, typename DestinationType>
struct RegisterReader;

template<typename T>
struct RegisterReader<Register, T> {
  static intptr_t Read(DeoptContext* context, Register reg) {
    return context->RegisterValue(reg);
  }
};

template<>
struct RegisterReader<FpuRegister, double> {
  static double Read(DeoptContext* context, FpuRegister reg) {
    return context->FpuRegisterValue(reg);
  }
};


template<>
struct RegisterReader<FpuRegister, simd128_value_t> {
  static simd128_value_t Read(DeoptContext* context, FpuRegister reg) {
    return context->FpuRegisterValueAsSimd128(reg);
  }
};


// Class that encapsulates reading and writing of values that were either in
// the registers in the optimized code or were spilled from those registers
// to the stack.
template<typename RegisterType>
class RegisterSource {
 public:
  enum Kind {
    // Spilled register source represented as its spill slot.
    kStackSlot = 0,
    // Register source represented as its register index.
    kRegister = 1
  };

  explicit RegisterSource(intptr_t source_index)
      : source_index_(source_index) { }

  RegisterSource(Kind kind, intptr_t index)
      : source_index_(KindField::encode(kind) | RawIndexField::encode(index)) {
  }

  template<typename T>
  T Value(DeoptContext* context) const {
    if (is_register()) {
      return static_cast<T>(RegisterReader<RegisterType, T>::Read(
        context, reg()));
    } else {
      return *reinterpret_cast<T*>(context->GetSourceFrameAddressAt(
          context->source_frame_size() - raw_index() - 1));
    }
  }

  intptr_t source_index() const { return source_index_; }

  const char* ToCString() const {
    if (is_register()) {
      return Name(reg());
    } else {
      return Isolate::Current()->current_zone()->PrintToString(
          "s%" Pd "", raw_index());
    }
  }

 private:
  class KindField : public BitField<intptr_t, 0, 1> { };
  class RawIndexField : public BitField<intptr_t, 1, kBitsPerWord - 1> { };

  bool is_register() const {
    return KindField::decode(source_index_) == kRegister;
  }
  intptr_t raw_index() const { return RawIndexField::decode(source_index_); }

  RegisterType reg() const { return static_cast<RegisterType>(raw_index()); }

  static const char* Name(Register reg) {
    return Assembler::RegisterName(reg);
  }

  static const char* Name(FpuRegister fpu_reg) {
    return Assembler::FpuRegisterName(fpu_reg);
  }

  const intptr_t source_index_;
};


typedef RegisterSource<Register> CpuRegisterSource;
typedef RegisterSource<FpuRegister> FpuRegisterSource;


// Builds a deoptimization info table, one DeoptInfo at a time.  Call AddXXX
// methods in the order of their target, starting wih deoptimized code
// continuation pc and ending with the first argument of the deoptimized
// code.  Call CreateDeoptInfo to write the accumulated instructions into
// the heap and reset the builder's internal state for the next DeoptInfo.
class DeoptInfoBuilder : public ValueObject {
 public:
  DeoptInfoBuilder(Isolate* isolate, const intptr_t num_args);

  // 'object_table' holds all objects referred to by DeoptInstr in
  // all DeoptInfo instances for a single Code object.
  const GrowableObjectArray& object_table() { return object_table_; }

  // Return address before instruction.
  void AddReturnAddress(const Code& code,
                        intptr_t deopt_id,
                        intptr_t dest_index);

  // Copy from optimized frame to unoptimized.
  void AddCopy(Value* value, const Location& source_loc, intptr_t dest_index);
  void AddPcMarker(const Code& code, intptr_t dest_index);
  void AddPp(const Code& code, intptr_t dest_index);
  void AddCallerFp(intptr_t dest_index);
  void AddCallerPp(intptr_t dest_index);
  void AddCallerPc(intptr_t dest_index);

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
  intptr_t EmitMaterializationArguments(intptr_t dest_index);

  RawDeoptInfo* CreateDeoptInfo(const Array& deopt_table);

  // Mark the actual start of the frame description after all materialization
  // instructions were emitted. Used for verification purposes.
  void MarkFrameStart() {
    ASSERT(frame_start_ == -1);
    frame_start_ = instructions_.length();
  }

 private:
  class TrieNode;

  CpuRegisterSource ToCpuRegisterSource(const Location& loc);
  FpuRegisterSource ToFpuRegisterSource(const Location& loc,
                                      Location::Kind expected_stack_slot_kind);

  intptr_t FindOrAddObjectInTable(const Object& obj) const;
  intptr_t FindMaterialization(MaterializeObjectInstr* mat) const;
  intptr_t CalculateStackIndex(const Location& source_loc) const;

  intptr_t FrameSize() const {
    return instructions_.length() - frame_start_;
  }

  void AddConstant(const Object& obj, intptr_t dest_index);

  Isolate* isolate() const { return isolate_; }

  Isolate* isolate_;

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
                       const Smi& reason_and_flags);

  // Return the length of the table in entries.
  static intptr_t GetLength(const Array& table);

  // Set the output parameters (offset, info, reason) to the entry values at
  // the index into the table (not an array index).
  static void GetEntry(const Array& table,
                       intptr_t index,
                       Smi* offset,
                       DeoptInfo* info,
                       Smi* reason_and_flags);

  static RawSmi* EncodeReasonAndFlags(ICData::DeoptReasonId reason,
                                      uint32_t flags) {
    return Smi::New(ReasonField::encode(reason) |
                    FlagsField::encode(flags));
  }

  class ReasonField : public BitField<ICData::DeoptReasonId, 0, 8> { };
  class FlagsField : public BitField<uint32_t, 8, 8> { };

 private:
  static const intptr_t kEntrySize = 3;
};

}  // namespace dart

#endif  // VM_DEOPT_INSTRUCTIONS_H_

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEOPT_INSTRUCTIONS_H_
#define RUNTIME_VM_DEOPT_INSTRUCTIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/deferred_objects.h"
#include "vm/flow_graph_compiler.h"
#include "vm/growable_array.h"
#include "vm/locations.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"

namespace dart {

class Location;
class Value;
class MaterializeObjectInstr;
class StackFrame;
class TimelineEvent;

// Holds all data relevant for execution of deoptimization instructions.
// Structure is allocated in C-heap.
class DeoptContext {
 public:
  enum DestFrameOptions {
    kDestIsOriginalFrame,  // Replace the original frame with deopt frame.
    kDestIsAllocated       // Write deopt frame to a buffer.
  };

  // If 'deoptimizing_code' is false, only frame is being deoptimized.
  DeoptContext(const StackFrame* frame,
               const Code& code,
               DestFrameOptions dest_options,
               fpu_register_t* fpu_registers,
               intptr_t* cpu_registers,
               bool is_lazy_deopt,
               bool deoptimizing_code);
  virtual ~DeoptContext();

  // Returns the offset of the dest fp from the dest sp.  Used in
  // runtime code to adjust the stack size before deoptimization.
  intptr_t DestStackAdjustment() const;

  intptr_t* GetSourceFrameAddressAt(intptr_t index) const {
    ASSERT(source_frame_ != NULL);
    ASSERT((0 <= index) && (index < source_frame_size_));
#if !defined(TARGET_ARCH_DBC)
    // Convert FP relative index to SP relative one.
    index = source_frame_size_ - 1 - index;
#endif  // !defined(TARGET_ARCH_DBC)
    return &source_frame_[index];
  }

  // Returns index in stack slot notation where -1 is the first argument
  // For DBC returns index directly relative to FP.
  intptr_t GetStackSlot(intptr_t index) const {
    ASSERT((0 <= index) && (index < source_frame_size_));
    index -= num_args_;
#if defined(TARGET_ARCH_DBC)
    return index < 0 ? index - kDartFrameFixedSize : index;
#else
    return index < 0 ? index : index - kDartFrameFixedSize;
#endif  // defined(TARGET_ARCH_DBC)
  }

  intptr_t GetSourceFp() const;
  intptr_t GetSourcePp() const;
  intptr_t GetSourcePc() const;

  intptr_t GetCallerFp() const;
  void SetCallerFp(intptr_t callers_fp);

  RawObject* ObjectAt(intptr_t index) const {
    const ObjectPool& object_pool = ObjectPool::Handle(object_pool_);
    return object_pool.ObjectAt(index);
  }

  intptr_t RegisterValue(Register reg) const {
    ASSERT(reg >= 0);
    ASSERT(reg < kNumberOfCpuRegisters);
#if !defined(TARGET_ARCH_DBC)
    ASSERT(cpu_registers_ != NULL);
    return cpu_registers_[reg];
#else
    // On DBC registers and stack slots are the same.
    const intptr_t stack_index = num_args_ + kDartFrameFixedSize + reg;
    return *GetSourceFrameAddressAt(stack_index);
#endif  // !defined(TARGET_ARCH_DBC)
  }

  double FpuRegisterValue(FpuRegister reg) const {
    ASSERT(FlowGraphCompiler::SupportsUnboxedDoubles());
    ASSERT(fpu_registers_ != NULL);
    ASSERT(reg >= 0);
#if !defined(TARGET_ARCH_DBC)
    ASSERT(reg < kNumberOfFpuRegisters);
    return *reinterpret_cast<double*>(&fpu_registers_[reg]);
#else
    // On DBC registers and stack slots are the same.
    const intptr_t stack_index = num_args_ + kDartFrameFixedSize + reg;
    return *reinterpret_cast<double*>(GetSourceFrameAddressAt(stack_index));
#endif
  }

  simd128_value_t FpuRegisterValueAsSimd128(FpuRegister reg) const {
    ASSERT(FlowGraphCompiler::SupportsUnboxedSimd128());
    ASSERT(fpu_registers_ != NULL);
    ASSERT(reg >= 0);
    ASSERT(reg < kNumberOfFpuRegisters);
    const float* address = reinterpret_cast<float*>(&fpu_registers_[reg]);
    return simd128_value_t().readFrom(address);
  }

  // Return base pointer for the given frame (either source or destination).
  // Base pointer points to the slot with the lowest address in the frame
  // including incoming arguments and artificial deoptimization frame
  // on top of it.
  // Note: artificial frame created by the deoptimization stub is considered
  // part of the frame because it contains saved caller PC and FP that
  // deoptimization will fill in.
  intptr_t* FrameBase(const StackFrame* frame) {
#if !defined(TARGET_ARCH_DBC)
    // SP of the deoptimization frame is the lowest slot because
    // stack is growing downwards.
    return reinterpret_cast<intptr_t*>(frame->sp() -
                                       (kDartFrameFixedSize * kWordSize));
#else
    // First argument is the lowest slot because stack is growing upwards.
    return reinterpret_cast<intptr_t*>(
        frame->fp() - (kDartFrameFixedSize + num_args_) * kWordSize);
#endif  // !defined(TARGET_ARCH_DBC)
  }

  void set_dest_frame(const StackFrame* frame) {
    ASSERT(frame != NULL && dest_frame_ == NULL);
    dest_frame_ = FrameBase(frame);
  }

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }

  intptr_t source_frame_size() const { return source_frame_size_; }
  intptr_t dest_frame_size() const { return dest_frame_size_; }

  RawCode* code() const { return code_; }

  bool is_lazy_deopt() const { return is_lazy_deopt_; }

  bool deoptimizing_code() const { return deoptimizing_code_; }

  ICData::DeoptReasonId deopt_reason() const { return deopt_reason_; }
  bool HasDeoptFlag(ICData::DeoptFlags flag) {
    return (deopt_flags_ & flag) != 0;
  }

  RawTypedData* deopt_info() const { return deopt_info_; }

  // Fills the destination frame but defers materialization of
  // objects.
  void FillDestFrame();

  // Allocate and prepare exceptions metadata for TrySync
  intptr_t* CatchEntryState(intptr_t num_vars);

  // Materializes all deferred objects.  Returns the total number of
  // artificial arguments used during deoptimization.
  intptr_t MaterializeDeferredObjects();

  RawArray* DestFrameAsArray();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void DeferMaterializedObjectRef(intptr_t idx, intptr_t* slot) {
    deferred_slots_ = new DeferredObjectRef(
        idx, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferMaterialization(double value, RawDouble** slot) {
    deferred_slots_ = new DeferredDouble(
        value, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferMintMaterialization(int64_t value, RawMint** slot) {
    deferred_slots_ = new DeferredMint(
        value, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawFloat32x4** slot) {
    deferred_slots_ = new DeferredFloat32x4(
        value, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawFloat64x2** slot) {
    deferred_slots_ = new DeferredFloat64x2(
        value, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferMaterialization(simd128_value_t value, RawInt32x4** slot) {
    deferred_slots_ = new DeferredInt32x4(
        value, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferRetAddrMaterialization(intptr_t index,
                                   intptr_t deopt_id,
                                   intptr_t* slot) {
    deferred_slots_ = new DeferredRetAddr(
        index, deopt_id, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferPcMarkerMaterialization(intptr_t index, intptr_t* slot) {
    deferred_slots_ = new DeferredPcMarker(
        index, reinterpret_cast<RawObject**>(slot), deferred_slots_);
  }

  void DeferPpMaterialization(intptr_t index, RawObject** slot) {
    deferred_slots_ = new DeferredPp(index, slot, deferred_slots_);
  }

  DeferredObject* GetDeferredObject(intptr_t idx) const {
    return deferred_objects_[idx];
  }

  intptr_t num_args() const { return num_args_; }

 private:
  intptr_t* GetDestFrameAddressAt(intptr_t index) const {
    ASSERT(dest_frame_ != NULL);
    ASSERT((0 <= index) && (index < dest_frame_size_));
#if defined(TARGET_ARCH_DBC)
    // Stack on DBC is growing upwards but we record deopt commands
    // in the same order we record them on other architectures as if
    // the stack was growing downwards.
    index = dest_frame_size_ - 1 - index;
#endif  // defined(TARGET_ARCH_DBC)
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

  intptr_t DeferredObjectsCount() const { return deferred_objects_count_; }

  RawCode* code_;
  RawObjectPool* object_pool_;
  RawTypedData* deopt_info_;
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
  Thread* thread_;
  int64_t deopt_start_micros_;

  DeferredSlot* deferred_slots_;

  intptr_t deferred_objects_count_;
  DeferredObject** deferred_objects_;

  const bool is_lazy_deopt_;
  const bool deoptimizing_code_;

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
    kMaterializedObjectRef,
    kMaterializeObject
  };

  static DeoptInstr* Create(intptr_t kind_as_int, intptr_t source_index);

  DeoptInstr() {}
  virtual ~DeoptInstr() {}

  virtual const char* ToCString() const {
    const char* args = ArgumentsToCString();
    if (args != NULL) {
      return Thread::Current()->zone()->PrintToString(
          "%s(%s)", KindToCString(kind()), args);
    } else {
      return KindToCString(kind());
    }
  }

  virtual void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) = 0;

  // Convert DeoptInstr to TrySync metadata entry.
  virtual CatchEntryStatePair ToCatchEntryStatePair(DeoptContext* deopt_context,
                                                    intptr_t dest_slot) {
    UNREACHABLE();
    return CatchEntryStatePair();
  }

  virtual DeoptInstr::Kind kind() const = 0;

  bool Equals(const DeoptInstr& other) const {
    return (kind() == other.kind()) && (source_index() == other.source_index());
  }

  // Get the code and return address which is encoded in this
  // kRetAfterAddress deopt instruction.
  static uword GetRetAddress(DeoptInstr* instr,
                             const ObjectPool& object_pool,
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

  virtual const char* ArgumentsToCString() const { return NULL; }

 private:
  static const char* KindToCString(Kind kind);

  DISALLOW_COPY_AND_ASSIGN(DeoptInstr);
};

// Helper class that allows to read a value of the given register from
// the DeoptContext as the specified type.
// It calls different method depending on which kind of register (cpu/fpu) and
// destination types are specified.
template <typename RegisterType, typename DestinationType>
struct RegisterReader;

template <typename T>
struct RegisterReader<Register, T> {
  static intptr_t Read(DeoptContext* context, Register reg) {
    return context->RegisterValue(reg);
  }
};

template <>
struct RegisterReader<FpuRegister, double> {
  static double Read(DeoptContext* context, FpuRegister reg) {
    return context->FpuRegisterValue(reg);
  }
};

template <>
struct RegisterReader<FpuRegister, simd128_value_t> {
  static simd128_value_t Read(DeoptContext* context, FpuRegister reg) {
    return context->FpuRegisterValueAsSimd128(reg);
  }
};

// Class that encapsulates reading and writing of values that were either in
// the registers in the optimized code or were spilled from those registers
// to the stack.
template <typename RegisterType>
class RegisterSource {
 public:
  enum Kind {
    // Spilled register source represented as its spill slot.
    kStackSlot = 0,
    // Register source represented as its register index.
    kRegister = 1
  };

  explicit RegisterSource(intptr_t source_index)
      : source_index_(source_index) {}

  RegisterSource(Kind kind, intptr_t index)
      : source_index_(KindField::encode(kind) | RawIndexField::encode(index)) {}

  template <typename T>
  T Value(DeoptContext* context) const {
    if (is_register()) {
      return static_cast<T>(
          RegisterReader<RegisterType, T>::Read(context, reg()));
    } else {
      return *reinterpret_cast<T*>(
          context->GetSourceFrameAddressAt(raw_index()));
    }
  }

  intptr_t StackSlot(DeoptContext* context) const {
    if (is_register()) {
      return raw_index();  // in DBC stack slots are registers.
    } else {
      return context->GetStackSlot(raw_index());
    }
  }

  intptr_t source_index() const { return source_index_; }

  const char* ToCString() const {
    if (is_register()) {
      return Name(reg());
    } else {
      return Thread::Current()->zone()->PrintToString("s%" Pd "", raw_index());
    }
  }

 private:
  class KindField : public BitField<intptr_t, intptr_t, 0, 1> {};
  class RawIndexField
      : public BitField<intptr_t, intptr_t, 1, kBitsPerWord - 1> {};

  bool is_register() const {
    return KindField::decode(source_index_) == kRegister;
  }
  intptr_t raw_index() const { return RawIndexField::decode(source_index_); }

  RegisterType reg() const { return static_cast<RegisterType>(raw_index()); }

  static const char* Name(Register reg) { return Assembler::RegisterName(reg); }

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
  DeoptInfoBuilder(Zone* zone, const intptr_t num_args, Assembler* assembler);

  // Return address before instruction.
  void AddReturnAddress(const Function& function,
                        intptr_t deopt_id,
                        intptr_t dest_index);

  // Copy from optimized frame to unoptimized.
  void AddCopy(Value* value, const Location& source_loc, intptr_t dest_index);
  void AddPcMarker(const Function& function, intptr_t dest_index);
  void AddPp(const Function& function, intptr_t dest_index);
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

  RawTypedData* CreateDeoptInfo(const Array& deopt_table);

  // Mark the actual start of the frame description after all materialization
  // instructions were emitted. Used for verification purposes.
  void MarkFrameStart() {
    ASSERT(frame_start_ == -1);
    frame_start_ = instructions_.length();
  }

 private:
  friend class CompilerDeoptInfo;  // For current_info_number_.

  class TrieNode;

  CpuRegisterSource ToCpuRegisterSource(const Location& loc);
  FpuRegisterSource ToFpuRegisterSource(
      const Location& loc,
      Location::Kind expected_stack_slot_kind);

  intptr_t FindOrAddObjectInTable(const Object& obj) const;
  intptr_t FindMaterialization(MaterializeObjectInstr* mat) const;
  intptr_t CalculateStackIndex(const Location& source_loc) const;

  intptr_t FrameSize() const {
    ASSERT(frame_start_ != -1);
    const intptr_t frame_size = instructions_.length() - frame_start_;
    ASSERT(frame_size >= 0);
    return frame_size;
  }

  void AddConstant(const Object& obj, intptr_t dest_index);

  Zone* zone() const { return zone_; }

  Zone* zone_;

  GrowableArray<DeoptInstr*> instructions_;
  const intptr_t num_args_;
  Assembler* assembler_;

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
// TODO(vegorov): consider compressing the whole table into a single TypedData
// object.
class DeoptTable : public AllStatic {
 public:
  // Return the array size in elements for a given number of table entries.
  static intptr_t SizeFor(intptr_t length);

  // Set the entry at the given index into the table (not an array index).
  static void SetEntry(const Array& table,
                       intptr_t index,
                       const Smi& offset,
                       const TypedData& info,
                       const Smi& reason_and_flags);

  // Return the length of the table in entries.
  static intptr_t GetLength(const Array& table);

  // Set the output parameters (offset, info, reason) to the entry values at
  // the index into the table (not an array index).
  static void GetEntry(const Array& table,
                       intptr_t index,
                       Smi* offset,
                       TypedData* info,
                       Smi* reason_and_flags);

  static RawSmi* EncodeReasonAndFlags(ICData::DeoptReasonId reason,
                                      uint32_t flags) {
    return Smi::New(ReasonField::encode(reason) | FlagsField::encode(flags));
  }

  class ReasonField : public BitField<intptr_t, ICData::DeoptReasonId, 0, 8> {};
  class FlagsField : public BitField<intptr_t, uint32_t, 8, 8> {};

 private:
  static const intptr_t kEntrySize = 3;
};


// Holds deopt information at one deoptimization point. The information consists
// of two parts:
//  - first a prefix consisting of kMaterializeObject instructions describing
//    objects which had their allocation removed as part of AllocationSinking
//    pass and have to be materialized;
//  - followed by a list of DeoptInstr objects, specifying transformation
//    information for each slot in unoptimized frame(s).
// Arguments for object materialization (class of instance to be allocated and
// field-value pairs) are added as artificial slots to the expression stack
// of the bottom-most frame. They are removed from the stack at the very end
// of deoptimization by the deoptimization stub.
class DeoptInfo : public AllStatic {
 public:
  // Size of the frame part of the translation not counting kMaterializeObject
  // instructions in the prefix.
  static intptr_t FrameSize(const TypedData& packed);

  // Returns the number of kMaterializeObject instructions in the prefix.
  static intptr_t NumMaterializations(const GrowableArray<DeoptInstr*>&);

  // Unpack the entire translation into an array of deoptimization
  // instructions.  This copies any shared suffixes into the array.
  static void Unpack(const Array& table,
                     const TypedData& packed,
                     GrowableArray<DeoptInstr*>* instructions);

  // Size of the frame part of the translation not counting kMaterializeObject
  // instructions in the prefix.
  static const char* ToCString(const Array& table, const TypedData& packed);

  // Returns true iff decompression yields the same instructions as the
  // original.
  static bool VerifyDecompression(const GrowableArray<DeoptInstr*>& original,
                                  const Array& deopt_table,
                                  const TypedData& packed);


 private:
  static void UnpackInto(const Array& table,
                         const TypedData& packed,
                         GrowableArray<DeoptInstr*>* instructions,
                         intptr_t length);
};

}  // namespace dart

#endif  // RUNTIME_VM_DEOPT_INSTRUCTIONS_H_

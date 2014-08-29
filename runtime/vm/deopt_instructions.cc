// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/deopt_instructions.h"

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/intermediate_language.h"
#include "vm/locations.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(bool, compress_deopt_info, true,
            "Compress the size of the deoptimization info for optimized code.");
DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, trace_deoptimization_verbose);


DeoptContext::DeoptContext(const StackFrame* frame,
                           const Code& code,
                           DestFrameOptions dest_options,
                           fpu_register_t* fpu_registers,
                           intptr_t* cpu_registers)
    : code_(code.raw()),
      object_table_(Array::null()),
      deopt_info_(DeoptInfo::null()),
      dest_frame_is_allocated_(false),
      dest_frame_(NULL),
      dest_frame_size_(0),
      source_frame_is_allocated_(false),
      source_frame_(NULL),
      source_frame_size_(0),
      cpu_registers_(cpu_registers),
      fpu_registers_(fpu_registers),
      num_args_(0),
      deopt_reason_(ICData::kDeoptUnknown),
      isolate_(Isolate::Current()),
      deferred_slots_(NULL),
      deferred_objects_count_(0),
      deferred_objects_(NULL) {
  object_table_ = code.object_table();

  ICData::DeoptReasonId deopt_reason = ICData::kDeoptUnknown;
  const DeoptInfo& deopt_info =
      DeoptInfo::Handle(code.GetDeoptInfoAtPc(frame->pc(), &deopt_reason));
  ASSERT(!deopt_info.IsNull());
  deopt_info_ = deopt_info.raw();
  deopt_reason_ = deopt_reason;

  const Function& function = Function::Handle(code.function());

  // Do not include incoming arguments if there are optional arguments
  // (they are copied into local space at method entry).
  num_args_ =
      function.HasOptionalParameters() ? 0 : function.num_fixed_parameters();

  // The fixed size section of the (fake) Dart frame called via a stub by the
  // optimized function contains FP, PP (ARM and MIPS only), PC-marker and
  // return-address. This section is copied as well, so that its contained
  // values can be updated before returning to the deoptimized function.
  source_frame_size_ =
      + kDartFrameFixedSize  // For saved values below sp.
      + ((frame->fp() - frame->sp()) / kWordSize)  // For frame size incl. sp.
      + 1  // For fp.
      + kParamEndSlotFromFp  // For saved values above fp.
      + num_args_;  // For arguments.
  source_frame_ = reinterpret_cast<intptr_t*>(
      frame->sp() - (kDartFrameFixedSize * kWordSize));

  if (dest_options == kDestIsOriginalFrame) {
    // Work from a copy of the source frame.
    intptr_t* original_frame = source_frame_;
    source_frame_ = new intptr_t[source_frame_size_];
    ASSERT(source_frame_ != NULL);
    for (intptr_t i = 0; i < source_frame_size_; i++) {
      source_frame_[i] = original_frame[i];
    }
    source_frame_is_allocated_ = true;
  }
  caller_fp_ = GetSourceFp();

  dest_frame_size_ = deopt_info.FrameSize();

  if (dest_options == kDestIsAllocated) {
    dest_frame_ = new intptr_t[dest_frame_size_];
    ASSERT(source_frame_ != NULL);
    for (intptr_t i = 0; i < dest_frame_size_; i++) {
      dest_frame_[i] = 0;
    }
    dest_frame_is_allocated_ = true;
  }

  if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
    OS::PrintErr(
        "Deoptimizing (reason %d '%s') at pc %#" Px " '%s' (count %d)\n",
        deopt_reason,
        DeoptReasonToCString(deopt_reason_),
        frame->pc(),
        function.ToFullyQualifiedCString(),
        function.deoptimization_counter());
  }
}


DeoptContext::~DeoptContext() {
  // Delete memory for source frame and registers.
  if (source_frame_is_allocated_) {
    delete[] source_frame_;
  }
  source_frame_ = NULL;
  delete[] fpu_registers_;
  delete[] cpu_registers_;
  fpu_registers_ = NULL;
  cpu_registers_ = NULL;
  if (dest_frame_is_allocated_) {
    delete[] dest_frame_;
  }
  dest_frame_ = NULL;

  // Delete all deferred objects.
  for (intptr_t i = 0; i < deferred_objects_count_; i++) {
    delete deferred_objects_[i];
  }
  delete[] deferred_objects_;
  deferred_objects_ = NULL;
  deferred_objects_count_ = 0;
}


void DeoptContext::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&object_table_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&deopt_info_));

  // Visit any object pointers on the destination stack.
  if (dest_frame_is_allocated_) {
    for (intptr_t i = 0; i < dest_frame_size_; i++) {
      if (dest_frame_[i] != 0) {
        visitor->VisitPointer(reinterpret_cast<RawObject**>(&dest_frame_[i]));
      }
    }
  }
}


intptr_t DeoptContext::DestStackAdjustment() const {
  return (dest_frame_size_
          - kDartFrameFixedSize
          - num_args_
          - kParamEndSlotFromFp
          - 1);  // For fp.
}


intptr_t DeoptContext::GetSourceFp() const {
  return source_frame_[source_frame_size_ - 1 - num_args_ -
                       kParamEndSlotFromFp];
}


intptr_t DeoptContext::GetSourcePp() const {
  return source_frame_[source_frame_size_ - 1 - num_args_ -
                       kParamEndSlotFromFp +
                       StackFrame::SavedCallerPpSlotFromFp()];
}


intptr_t DeoptContext::GetSourcePc() const {
  return source_frame_[source_frame_size_ - num_args_ + kSavedPcSlotFromSp];
}


intptr_t DeoptContext::GetCallerFp() const {
  return caller_fp_;
}


void DeoptContext::SetCallerFp(intptr_t caller_fp) {
  caller_fp_ = caller_fp;
}


static bool IsObjectInstruction(DeoptInstr::Kind kind) {
  switch (kind) {
    case DeoptInstr::kConstant:
    case DeoptInstr::kPp:
    case DeoptInstr::kCallerPp:
    case DeoptInstr::kMaterializedObjectRef:
    case DeoptInstr::kFloat32x4:
    case DeoptInstr::kInt32x4:
    case DeoptInstr::kFloat64x2:
    case DeoptInstr::kWord:
    case DeoptInstr::kDouble:
    case DeoptInstr::kMintPair:
    case DeoptInstr::kInt32:
    case DeoptInstr::kUint32:
      return true;

    case DeoptInstr::kRetAddress:
    case DeoptInstr::kPcMarker:
    case DeoptInstr::kCallerFp:
    case DeoptInstr::kCallerPc:
      return false;

    case DeoptInstr::kSuffix:
    case DeoptInstr::kMaterializeObject:
    default:
      // We should not encounter these instructions when filling stack slots.
      UNREACHABLE();
      return false;
  }
  UNREACHABLE();
  return false;
}


void DeoptContext::FillDestFrame() {
  const Code& code = Code::Handle(code_);
  const DeoptInfo& deopt_info = DeoptInfo::Handle(deopt_info_);

  const intptr_t len = deopt_info.TranslationLength();
  GrowableArray<DeoptInstr*> deopt_instructions(len);
  const Array& deopt_table = Array::Handle(code.deopt_info_array());
  ASSERT(!deopt_table.IsNull());
  deopt_info.ToInstructions(deopt_table, &deopt_instructions);

  const intptr_t frame_size = deopt_info.FrameSize();

  // For now, we never place non-objects in the deoptimized frame if
  // the destination frame is a copy.  This allows us to copy the
  // deoptimized frame into an Array.
  const bool objects_only = dest_frame_is_allocated_;

  // All kMaterializeObject instructions are emitted before the instructions
  // that describe stack frames. Skip them and defer materialization of
  // objects until the frame is fully reconstructed and it is safe to perform
  // GC.
  // Arguments (class of the instance to allocate and field-value pairs) are
  // described as part of the expression stack for the bottom-most deoptimized
  // frame. They will be used during materialization and removed from the stack
  // right before control switches to the unoptimized code.
  const intptr_t num_materializations = deopt_info.NumMaterializations();
  PrepareForDeferredMaterialization(num_materializations);
  for (intptr_t from_index = 0, to_index = kDartFrameFixedSize;
       from_index < num_materializations;
       from_index++) {
    const intptr_t field_count =
        DeoptInstr::GetFieldCount(deopt_instructions[from_index]);
    intptr_t* args = GetDestFrameAddressAt(to_index);
    DeferredObject* obj = new DeferredObject(field_count, args);
    SetDeferredObjectAt(from_index, obj);
    to_index += obj->ArgumentCount();
  }

  // Populate stack frames.
  for (intptr_t to_index = frame_size - 1, from_index = len - 1;
       to_index >= 0;
       to_index--, from_index--) {
    intptr_t* to_addr = GetDestFrameAddressAt(to_index);
    DeoptInstr* instr = deopt_instructions[from_index];
    if (!objects_only || IsObjectInstruction(instr->kind())) {
      instr->Execute(this, to_addr);
    } else {
      *reinterpret_cast<RawObject**>(to_addr) = Object::null();
    }
  }

  if (FLAG_trace_deoptimization_verbose) {
    intptr_t* start = dest_frame_;
    for (intptr_t i = 0; i < frame_size; i++) {
      OS::PrintErr("*%" Pd ". [%" Px "] %#014" Px " [%s]\n",
                   i,
                   reinterpret_cast<uword>(&start[i]),
                   start[i],
                   deopt_instructions[i + (len - frame_size)]->ToCString());
    }
  }
}


static void FillDeferredSlots(DeoptContext* deopt_context,
                              DeferredSlot** slot_list) {
  DeferredSlot* slot = *slot_list;
  *slot_list = NULL;

  while (slot != NULL) {
    DeferredSlot* current = slot;
    slot = slot->next();

    current->Materialize(deopt_context);

    delete current;
  }
}


// Materializes all deferred objects.  Returns the total number of
// artificial arguments used during deoptimization.
intptr_t DeoptContext::MaterializeDeferredObjects() {
  // Populate slots with references to all unboxed "primitive" values (doubles,
  // mints, simd) and deferred objects. Deferred objects are only allocated
  // but not filled with data. This is done later because deferred objects
  // can references each other.
  FillDeferredSlots(this, &deferred_slots_);

  // Compute total number of artificial arguments used during deoptimization.
  intptr_t deopt_arg_count = 0;
  for (intptr_t i = 0; i < DeferredObjectsCount(); i++) {
    GetDeferredObject(i)->Fill();
    deopt_arg_count += GetDeferredObject(i)->ArgumentCount();
  }

  // Since this is the only step where GC can occur during deoptimization,
  // use it to report the source line where deoptimization occured.
  if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
    DartFrameIterator iterator;
    StackFrame* top_frame = iterator.NextFrame();
    ASSERT(top_frame != NULL);
    const Code& code = Code::Handle(top_frame->LookupDartCode());
    const Function& top_function = Function::Handle(code.function());
    const Script& script = Script::Handle(top_function.script());
    const intptr_t token_pos = code.GetTokenIndexOfPC(top_frame->pc());
    intptr_t line, column;
    script.GetTokenLocation(token_pos, &line, &column);
    String& line_string = String::Handle(script.GetLine(line));
    OS::PrintErr("  Function: %s\n", top_function.ToFullyQualifiedCString());
    OS::PrintErr("  Line %" Pd ": '%s'\n", line, line_string.ToCString());
    OS::PrintErr("  Deopt args: %" Pd "\n", deopt_arg_count);
  }

  return deopt_arg_count;
}


RawArray* DeoptContext::DestFrameAsArray() {
  ASSERT(dest_frame_ != NULL && dest_frame_is_allocated_);
  const Array& dest_array =
      Array::Handle(isolate(), Array::New(dest_frame_size_));
  PassiveObject& obj = PassiveObject::Handle(isolate());
  for (intptr_t i = 0; i < dest_frame_size_; i++) {
    obj = reinterpret_cast<RawObject*>(dest_frame_[i]);
    dest_array.SetAt(i, obj);
  }
  return dest_array.raw();
}


// Deoptimization instruction creating return address using function and
// deopt-id stored at 'object_table_index'.
class DeoptRetAddressInstr : public DeoptInstr {
 public:
  DeoptRetAddressInstr(intptr_t object_table_index, intptr_t deopt_id)
      : object_table_index_(object_table_index), deopt_id_(deopt_id) {
    ASSERT(object_table_index >= 0);
    ASSERT(deopt_id >= 0);
  }

  explicit DeoptRetAddressInstr(intptr_t source_index)
      : object_table_index_(ObjectTableIndex::decode(source_index)),
        deopt_id_(DeoptId::decode(source_index)) {
  }

  virtual intptr_t source_index() const {
    return ObjectTableIndex::encode(object_table_index_) |
        DeoptId::encode(deopt_id_);
  }

  virtual DeoptInstr::Kind kind() const { return kRetAddress; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd ", %" Pd "", object_table_index_, deopt_id_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    Code& code = Code::Handle(deopt_context->isolate());
    code ^= deopt_context->ObjectAt(object_table_index_);
    ASSERT(!code.IsNull());
    uword continue_at_pc = code.GetPcForDeoptId(deopt_id_,
                                                RawPcDescriptors::kDeopt);
    ASSERT(continue_at_pc != 0);
    *dest_addr = continue_at_pc;

    uword pc = code.GetPcForDeoptId(deopt_id_, RawPcDescriptors::kIcCall);
    if (pc != 0) {
      // If the deoptimization happened at an IC call, update the IC data
      // to avoid repeated deoptimization at the same site next time around.
      ICData& ic_data = ICData::Handle();
      CodePatcher::GetInstanceCallAt(pc, code, &ic_data);
      if (!ic_data.IsNull()) {
        ic_data.AddDeoptReason(deopt_context->deopt_reason());
      }
    } else if (deopt_context->deopt_reason() ==
               ICData::kDeoptHoistedCheckClass) {
      // Prevent excessive deoptimization.
      Function::Handle(code.function()).set_allows_hoisting_check_class(false);
    }
  }

  intptr_t object_table_index() const { return object_table_index_; }
  intptr_t deopt_id() const { return deopt_id_; }

 private:
  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class ObjectTableIndex : public BitField<intptr_t, 0, kFieldWidth> { };
  class DeoptId : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };

  const intptr_t object_table_index_;
  const intptr_t deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRetAddressInstr);
};


// Deoptimization instruction moving a constant stored at 'object_table_index'.
class DeoptConstantInstr : public DeoptInstr {
 public:
  explicit DeoptConstantInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t source_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kConstant; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd "", object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    const PassiveObject& obj = PassiveObject::Handle(
        deopt_context->isolate(), deopt_context->ObjectAt(object_table_index_));
    *reinterpret_cast<RawObject**>(dest_addr) = obj.raw();
  }

 private:
  const intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptConstantInstr);
};


// Deoptimization instruction moving value from optimized frame at
// 'source_index' to specified slots in the unoptimized frame.
// 'source_index' represents the slot index of the frame (0 being
// first argument) and accounts for saved return address, frame
// pointer, pool pointer and pc marker.
// Deoptimization instruction moving a CPU register.
class DeoptWordInstr: public DeoptInstr {
 public:
  explicit DeoptWordInstr(intptr_t source_index)
      : source_(source_index) {}

  explicit DeoptWordInstr(const CpuRegisterSource& source)
      : source_(source) {}

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return kWord; }

  virtual const char* ArgumentsToCString() const {
    return source_.ToCString();
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = source_.Value<intptr_t>(deopt_context);
  }

 private:
  const CpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptWordInstr);
};


class DeoptIntegerInstrBase: public DeoptInstr {
 public:
  DeoptIntegerInstrBase() { }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    const int64_t value = GetValue(deopt_context);
    if (Smi::IsValid(value)) {
      *dest_addr = Smi::RawValue(static_cast<intptr_t>(value));
    } else {
      *dest_addr = Smi::RawValue(0);
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

  virtual int64_t GetValue(DeoptContext* deopt_context) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptIntegerInstrBase);
};


class DeoptMintPairInstr: public DeoptIntegerInstrBase {
 public:
  explicit DeoptMintPairInstr(intptr_t source_index)
      : DeoptIntegerInstrBase(),
        lo_(LoRegister::decode(source_index)),
        hi_(HiRegister::decode(source_index)) {
  }

  DeoptMintPairInstr(const CpuRegisterSource& lo, const CpuRegisterSource& hi)
      : DeoptIntegerInstrBase(), lo_(lo), hi_(hi) {}

  virtual intptr_t source_index() const {
    return LoRegister::encode(lo_.source_index()) |
           HiRegister::encode(hi_.source_index());
  }
  virtual DeoptInstr::Kind kind() const { return kMintPair; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%s,%s",
        lo_.ToCString(),
        hi_.ToCString());
  }

  virtual int64_t GetValue(DeoptContext* deopt_context) {
    return Utils::LowHighTo64Bits(
        lo_.Value<uint32_t>(deopt_context), hi_.Value<int32_t>(deopt_context));
  }

 private:
  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class LoRegister : public BitField<intptr_t, 0, kFieldWidth> { };
  class HiRegister : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };

  const CpuRegisterSource lo_;
  const CpuRegisterSource hi_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMintPairInstr);
};


template<DeoptInstr::Kind K, typename T>
class DeoptIntInstr : public DeoptIntegerInstrBase {
 public:
  explicit DeoptIntInstr(intptr_t source_index)
      : DeoptIntegerInstrBase(), source_(source_index) {
  }

  explicit DeoptIntInstr(const CpuRegisterSource& source)
      : DeoptIntegerInstrBase(), source_(source) {
  }

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return K; }

  virtual const char* ArgumentsToCString() const {
    return source_.ToCString();
  }

  virtual int64_t GetValue(DeoptContext* deopt_context) {
    return static_cast<int64_t>(source_.Value<T>(deopt_context));
  }

 private:
  const CpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptIntInstr);
};


typedef DeoptIntInstr<DeoptInstr::kUint32, uint32_t> DeoptUint32Instr;
typedef DeoptIntInstr<DeoptInstr::kInt32, int32_t> DeoptInt32Instr;


template<DeoptInstr::Kind K,
         typename Type,
         typename RawObjectType>
class DeoptFpuInstr: public DeoptInstr {
 public:
  explicit DeoptFpuInstr(intptr_t source_index)
      : source_(source_index) {}

  explicit DeoptFpuInstr(const FpuRegisterSource& source)
      : source_(source) {}

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return K; }

  virtual const char* ArgumentsToCString() const {
    return source_.ToCString();
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = Smi::RawValue(0);
    deopt_context->DeferMaterialization(
        source_.Value<Type>(deopt_context),
        reinterpret_cast<RawObjectType**>(dest_addr));
  }

 private:
  const FpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptFpuInstr);
};

typedef DeoptFpuInstr<DeoptInstr::kDouble, double, RawDouble> DeoptDoubleInstr;

// Simd128 types.
typedef DeoptFpuInstr<DeoptInstr::kFloat32x4, simd128_value_t, RawFloat32x4>
    DeoptFloat32x4Instr;
typedef DeoptFpuInstr<DeoptInstr::kFloat32x4, simd128_value_t, RawFloat32x4>
    DeoptFloat32x4Instr;
typedef DeoptFpuInstr<DeoptInstr::kFloat64x2, simd128_value_t, RawFloat64x2>
    DeoptFloat64x2Instr;
typedef DeoptFpuInstr<DeoptInstr::kInt32x4, simd128_value_t, RawInt32x4>
    DeoptInt32x4Instr;

// Deoptimization instruction creating a PC marker for the code of
// function at 'object_table_index'.
class DeoptPcMarkerInstr : public DeoptInstr {
 public:
  explicit DeoptPcMarkerInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t source_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kPcMarker; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd "", object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    Code& code = Code::Handle(deopt_context->isolate());
    code ^= deopt_context->ObjectAt(object_table_index_);
    if (code.IsNull()) {
      // Callee's PC marker is not used (pc of Deoptimize stub). Set to 0.
      *dest_addr = 0;
      return;
    }
    const Function& function =
        Function::Handle(deopt_context->isolate(), code.function());
    ASSERT(function.HasCode());
    const intptr_t pc_marker =
        code.EntryPoint() + Assembler::EntryPointToPcMarkerOffset();
    *dest_addr = pc_marker;
    // Increment the deoptimization counter. This effectively increments each
    // function occurring in the optimized frame.
    function.set_deoptimization_counter(function.deoptimization_counter() + 1);
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      OS::PrintErr("Deoptimizing %s (count %d)\n",
          function.ToFullyQualifiedCString(),
          function.deoptimization_counter());
    }
    // Clear invocation counter so that hopefully the function gets reoptimized
    // only after more feedback has been collected.
    function.set_usage_counter(0);
    if (function.HasOptimizedCode()) {
      function.SwitchToUnoptimizedCode();
    }
  }

 private:
  intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptPcMarkerInstr);
};


// Deoptimization instruction creating a pool pointer for the code of
// function at 'object_table_index'.
class DeoptPpInstr : public DeoptInstr {
 public:
  explicit DeoptPpInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t source_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kPp; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd "", object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    Code& code = Code::Handle(deopt_context->isolate());
    code ^= deopt_context->ObjectAt(object_table_index_);
    ASSERT(!code.IsNull());
    const intptr_t pp = reinterpret_cast<intptr_t>(code.ObjectPool());
    *dest_addr = pp;
  }

 private:
  intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptPpInstr);
};


// Deoptimization instruction copying the caller saved FP from optimized frame.
class DeoptCallerFpInstr : public DeoptInstr {
 public:
  DeoptCallerFpInstr() {}

  virtual intptr_t source_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kCallerFp; }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = deopt_context->GetCallerFp();
    deopt_context->SetCallerFp(reinterpret_cast<intptr_t>(
        dest_addr - (kSavedCallerFpSlotFromFp * kWordSize)));
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerFpInstr);
};


// Deoptimization instruction copying the caller saved PP from optimized frame.
class DeoptCallerPpInstr : public DeoptInstr {
 public:
  DeoptCallerPpInstr() {}

  virtual intptr_t source_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kCallerPp; }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = deopt_context->GetSourcePp();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerPpInstr);
};


// Deoptimization instruction copying the caller return address from optimized
// frame.
class DeoptCallerPcInstr : public DeoptInstr {
 public:
  DeoptCallerPcInstr() {}

  virtual intptr_t source_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kCallerPc; }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = deopt_context->GetSourcePc();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerPcInstr);
};


// Deoptimization instruction that indicates the rest of this DeoptInfo is a
// suffix of another one.  The suffix contains the info number (0 based
// index in the deopt table of the DeoptInfo to share) and the length of the
// suffix.
class DeoptSuffixInstr : public DeoptInstr {
 public:
  DeoptSuffixInstr(intptr_t info_number, intptr_t suffix_length)
      : info_number_(info_number), suffix_length_(suffix_length) {
    ASSERT(info_number >= 0);
    ASSERT(suffix_length >= 0);
  }

  explicit DeoptSuffixInstr(intptr_t source_index)
      : info_number_(InfoNumber::decode(source_index)),
        suffix_length_(SuffixLength::decode(source_index)) {
  }

  virtual intptr_t source_index() const {
    return InfoNumber::encode(info_number_) |
        SuffixLength::encode(suffix_length_);
  }
  virtual DeoptInstr::Kind kind() const { return kSuffix; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd ":%" Pd, info_number_, suffix_length_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    // The deoptimization info is uncompressed by translating away suffixes
    // before executing the instructions.
    UNREACHABLE();
  }

 private:
  // Static decoder functions in DeoptInstr have access to the bitfield
  // definitions.
  friend class DeoptInstr;

  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class InfoNumber : public BitField<intptr_t, 0, kFieldWidth> { };
  class SuffixLength : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };

  const intptr_t info_number_;
  const intptr_t suffix_length_;

  DISALLOW_COPY_AND_ASSIGN(DeoptSuffixInstr);
};


// Write reference to a materialized object with the given index into the
// stack slot.
class DeoptMaterializedObjectRefInstr : public DeoptInstr {
 public:
  explicit DeoptMaterializedObjectRefInstr(intptr_t index)
      : index_(index) {
    ASSERT(index >= 0);
  }

  virtual intptr_t source_index() const { return index_; }
  virtual DeoptInstr::Kind kind() const { return kMaterializedObjectRef; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "#%" Pd "", index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferMaterializedObjectRef(
        index_, dest_addr);
  }

 private:
  intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMaterializedObjectRefInstr);
};


// Materialize object with the given number of fields.
// Arguments for materialization (class and field-value pairs) are pushed
// to the expression stack of the bottom-most frame.
class DeoptMaterializeObjectInstr : public DeoptInstr {
 public:
  explicit DeoptMaterializeObjectInstr(intptr_t field_count)
      : field_count_(field_count) {
    ASSERT(field_count >= 0);
  }

  virtual intptr_t source_index() const { return field_count_; }
  virtual DeoptInstr::Kind kind() const { return kMaterializeObject; }

  virtual const char* ArgumentsToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%" Pd "", field_count_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    // This instructions are executed manually by the DeoptimizeWithDeoptInfo.
    UNREACHABLE();
  }

 private:
  intptr_t field_count_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMaterializeObjectInstr);
};


intptr_t DeoptInstr::DecodeSuffix(intptr_t source_index,
                                  intptr_t* info_number) {
  *info_number = DeoptSuffixInstr::InfoNumber::decode(source_index);
  return DeoptSuffixInstr::SuffixLength::decode(source_index);
}


uword DeoptInstr::GetRetAddress(DeoptInstr* instr,
                                const Array& object_table,
                                Code* code) {
  ASSERT(instr->kind() == kRetAddress);
  DeoptRetAddressInstr* ret_address_instr =
      static_cast<DeoptRetAddressInstr*>(instr);
  // The following assert may trigger when displaying a backtrace
  // from the simulator.
  ASSERT(Isolate::IsDeoptAfter(ret_address_instr->deopt_id()));
  ASSERT(!object_table.IsNull());
  ASSERT(code != NULL);
  *code ^= object_table.At(ret_address_instr->object_table_index());
  ASSERT(!code->IsNull());
  uword res = code->GetPcForDeoptId(ret_address_instr->deopt_id(),
                                    RawPcDescriptors::kDeopt);
  ASSERT(res != 0);
  return res;
}


DeoptInstr* DeoptInstr::Create(intptr_t kind_as_int, intptr_t source_index) {
  Kind kind = static_cast<Kind>(kind_as_int);
  switch (kind) {
    case kWord:
      return new DeoptWordInstr(source_index);
    case kDouble:
      return new DeoptDoubleInstr(source_index);
    case kMintPair:
      return new DeoptMintPairInstr(source_index);
    case kInt32:
      return new DeoptInt32Instr(source_index);
    case kUint32:
      return new DeoptUint32Instr(source_index);
    case kFloat32x4:
      return new DeoptFloat32x4Instr(source_index);
    case kFloat64x2:
      return new DeoptFloat64x2Instr(source_index);
    case kInt32x4:
      return new DeoptInt32x4Instr(source_index);
    case kRetAddress:
      return new DeoptRetAddressInstr(source_index);
    case kConstant:
      return new DeoptConstantInstr(source_index);
    case kPcMarker:
      return new DeoptPcMarkerInstr(source_index);
    case kPp:
      return new DeoptPpInstr(source_index);
    case kCallerFp:
      return new DeoptCallerFpInstr();
    case kCallerPp:
      return new DeoptCallerPpInstr();
    case kCallerPc:
      return new DeoptCallerPcInstr();
    case kSuffix:
      return new DeoptSuffixInstr(source_index);
    case kMaterializedObjectRef:
      return new DeoptMaterializedObjectRefInstr(source_index);
    case kMaterializeObject:
      return new DeoptMaterializeObjectInstr(source_index);
  }
  UNREACHABLE();
  return NULL;
}


const char* DeoptInstr::KindToCString(Kind kind) {
  switch (kind) {
    case kWord:
      return "word";
    case kDouble:
      return "double";
    case kMintPair:
      return "mint";
    case kInt32:
      return "int32";
    case kUint32:
      return "uint32";
    case kFloat32x4:
      return "float32x4";
    case kFloat64x2:
      return "float64x2";
    case kInt32x4:
      return "int32x4";
    case kRetAddress:
      return "retaddr";
    case kConstant:
      return "const";
    case kPcMarker:
      return "pc";
    case kPp:
      return "pp";
    case kCallerFp:
      return "callerfp";
    case kCallerPp:
      return "callerpp";
    case kCallerPc:
      return "callerpc";
    case kSuffix:
      return "suffix";
    case kMaterializedObjectRef:
      return "ref";
    case kMaterializeObject:
      return "mat";
  }
  UNREACHABLE();
  return NULL;
}


class DeoptInfoBuilder::TrieNode : public ZoneAllocated {
 public:
  // Construct the root node representing the implicit "shared" terminator
  // at the end of each deopt info.
  TrieNode() : instruction_(NULL), info_number_(-1), children_(16) { }

  // Construct a node representing a written instruction.
  TrieNode(DeoptInstr* instruction, intptr_t info_number)
      : instruction_(instruction), info_number_(info_number), children_(4) { }

  intptr_t info_number() const { return info_number_; }

  void AddChild(TrieNode* child) {
    if (child != NULL) children_.Add(child);
  }

  TrieNode* FindChild(const DeoptInstr& instruction) {
    for (intptr_t i = 0; i < children_.length(); ++i) {
      TrieNode* child = children_[i];
      if (child->instruction_->Equals(instruction)) return child;
    }
    return NULL;
  }

 private:
  const DeoptInstr* instruction_;  // Instruction that was written.
  const intptr_t info_number_;  // Index of the deopt info it was written to.

  GrowableArray<TrieNode*> children_;
};


DeoptInfoBuilder::DeoptInfoBuilder(Isolate* isolate, const intptr_t num_args)
    : isolate_(isolate),
      instructions_(),
      object_table_(GrowableObjectArray::Handle(
          GrowableObjectArray::New(Heap::kOld))),
      num_args_(num_args),
      trie_root_(new(isolate) TrieNode()),
      current_info_number_(0),
      frame_start_(-1),
      materializations_() {
}


intptr_t DeoptInfoBuilder::FindOrAddObjectInTable(const Object& obj) const {
  for (intptr_t i = 0; i < object_table_.Length(); i++) {
    if (object_table_.At(i) == obj.raw()) {
      return i;
    }
  }
  // Add object.
  const intptr_t result = object_table_.Length();
  object_table_.Add(obj, Heap::kOld);
  return result;
}


intptr_t DeoptInfoBuilder::CalculateStackIndex(
    const Location& source_loc) const {
  return source_loc.stack_index() < 0 ?
            source_loc.stack_index() + num_args_ :
            source_loc.stack_index() + num_args_ + kDartFrameFixedSize;
}


CpuRegisterSource DeoptInfoBuilder::ToCpuRegisterSource(const Location& loc) {
  if (loc.IsRegister()) {
    return CpuRegisterSource(CpuRegisterSource::kRegister, loc.reg());
  } else {
    ASSERT(loc.IsStackSlot());
    return CpuRegisterSource(
        CpuRegisterSource::kStackSlot, CalculateStackIndex(loc));
  }
}


FpuRegisterSource DeoptInfoBuilder::ToFpuRegisterSource(
  const Location& loc,
  Location::Kind stack_slot_kind) {
  if (loc.IsFpuRegister()) {
    return FpuRegisterSource(FpuRegisterSource::kRegister, loc.fpu_reg());
  } else {
    ASSERT((stack_slot_kind == Location::kQuadStackSlot) ||
           (stack_slot_kind == Location::kDoubleStackSlot));
    ASSERT(loc.kind() == stack_slot_kind);
    return FpuRegisterSource(
        FpuRegisterSource::kStackSlot, CalculateStackIndex(loc));
  }
}

void DeoptInfoBuilder::AddReturnAddress(const Code& code,
                                        intptr_t deopt_id,
                                        intptr_t dest_index) {
  // Check that deopt_id exists.
  // TODO(vegorov): verify after deoptimization targets as well.
#ifdef DEBUG
  ASSERT(Isolate::IsDeoptAfter(deopt_id) ||
         (code.GetPcForDeoptId(deopt_id, RawPcDescriptors::kDeopt) != 0));
#endif
  const intptr_t object_table_index = FindOrAddObjectInTable(code);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(
      new(isolate()) DeoptRetAddressInstr(object_table_index, deopt_id));
}


void DeoptInfoBuilder::AddPcMarker(const Code& code,
                                   intptr_t dest_index) {
  intptr_t object_table_index = FindOrAddObjectInTable(code);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new(isolate()) DeoptPcMarkerInstr(object_table_index));
}


void DeoptInfoBuilder::AddPp(const Code& code,
                             intptr_t dest_index) {
  intptr_t object_table_index = FindOrAddObjectInTable(code);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new(isolate()) DeoptPpInstr(object_table_index));
}


void DeoptInfoBuilder::AddCopy(Value* value,
                               const Location& source_loc,
                               const intptr_t dest_index) {
  DeoptInstr* deopt_instr = NULL;
  if (source_loc.IsConstant()) {
    intptr_t object_table_index = FindOrAddObjectInTable(source_loc.constant());
    deopt_instr = new(isolate()) DeoptConstantInstr(object_table_index);
  } else if (source_loc.IsInvalid() &&
             value->definition()->IsMaterializeObject()) {
    const intptr_t index = FindMaterialization(
        value->definition()->AsMaterializeObject());
    ASSERT(index >= 0);
    deopt_instr = new(isolate()) DeoptMaterializedObjectRefInstr(index);
  } else {
    ASSERT(!source_loc.IsInvalid());
    switch (value->definition()->representation()) {
      case kTagged:
        deopt_instr = new(isolate()) DeoptWordInstr(
          ToCpuRegisterSource(source_loc));
        break;
      case kUnboxedMint: {
        ASSERT(source_loc.IsPairLocation());
        PairLocation* pair = source_loc.AsPairLocation();
        deopt_instr = new(isolate()) DeoptMintPairInstr(
            ToCpuRegisterSource(pair->At(0)),
            ToCpuRegisterSource(pair->At(1)));
        break;
      }
      case kUnboxedInt32:
        deopt_instr = new(isolate()) DeoptInt32Instr(
          ToCpuRegisterSource(source_loc));
        break;
      case kUnboxedUint32:
        deopt_instr = new(isolate()) DeoptUint32Instr(
          ToCpuRegisterSource(source_loc));
        break;
      case kUnboxedDouble:
        deopt_instr = new(isolate()) DeoptDoubleInstr(
            ToFpuRegisterSource(source_loc, Location::kDoubleStackSlot));
        break;
      case kUnboxedFloat32x4:
        deopt_instr = new(isolate()) DeoptFloat32x4Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      case kUnboxedFloat64x2:
        deopt_instr = new(isolate()) DeoptFloat64x2Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      case kUnboxedInt32x4:
        deopt_instr = new(isolate()) DeoptInt32x4Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
  ASSERT(dest_index == FrameSize());
  ASSERT(deopt_instr != NULL);
  instructions_.Add(deopt_instr);
}


void DeoptInfoBuilder::AddCallerFp(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new(isolate()) DeoptCallerFpInstr());
}


void DeoptInfoBuilder::AddCallerPp(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new(isolate()) DeoptCallerPpInstr());
}


void DeoptInfoBuilder::AddCallerPc(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new(isolate()) DeoptCallerPcInstr());
}


void DeoptInfoBuilder::AddConstant(const Object& obj, intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  intptr_t object_table_index = FindOrAddObjectInTable(obj);
  instructions_.Add(new(isolate()) DeoptConstantInstr(object_table_index));
}


void DeoptInfoBuilder::AddMaterialization(MaterializeObjectInstr* mat) {
  const intptr_t index = FindMaterialization(mat);
  if (index >= 0) {
    return;  // Already added.
  }
  materializations_.Add(mat);

  // Count initialized fields and emit kMaterializeObject instruction.
  // There is no need to write nulls into fields because object is null
  // initialized by default.
  intptr_t non_null_fields = 0;
  for (intptr_t i = 0; i < mat->InputCount(); i++) {
    if (!mat->InputAt(i)->BindsToConstantNull()) {
      non_null_fields++;
    }
  }

  instructions_.Add(
      new(isolate()) DeoptMaterializeObjectInstr(non_null_fields));

  for (intptr_t i = 0; i < mat->InputCount(); i++) {
    MaterializeObjectInstr* nested_mat = mat->InputAt(i)->definition()->
        AsMaterializeObject();
    if (nested_mat != NULL) {
      AddMaterialization(nested_mat);
    }
  }
}


intptr_t DeoptInfoBuilder::EmitMaterializationArguments(intptr_t dest_index) {
  ASSERT(dest_index == kDartFrameFixedSize);
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    // Class of the instance to allocate.
    AddConstant(mat->cls(), dest_index++);
    for (intptr_t i = 0; i < mat->InputCount(); i++) {
      if (!mat->InputAt(i)->BindsToConstantNull()) {
        // Emit offset-value pair.
        AddConstant(Smi::Handle(Smi::New(mat->FieldOffsetAt(i))),
                    dest_index++);
        AddCopy(mat->InputAt(i), mat->LocationAt(i), dest_index++);
      }
    }
  }
  return dest_index;
}


intptr_t DeoptInfoBuilder::FindMaterialization(
    MaterializeObjectInstr* mat) const {
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    if (materializations_[i] == mat) {
      return i;
    }
  }
  return -1;
}


RawDeoptInfo* DeoptInfoBuilder::CreateDeoptInfo(const Array& deopt_table) {
  // TODO(vegorov): enable compression of deoptimization info containing object
  // materialization instructions.
  const bool disable_compression =
      (instructions_[0]->kind() == DeoptInstr::kMaterializeObject);

  intptr_t length = instructions_.length();

  // Count the number of instructions that are a shared suffix of some deopt
  // info already written.
  TrieNode* suffix = trie_root_;
  intptr_t suffix_length = 0;
  if (FLAG_compress_deopt_info && !disable_compression) {
    for (intptr_t i = length - 1; i >= 0; --i) {
      TrieNode* node = suffix->FindChild(*instructions_[i]);
      if (node == NULL) break;
      suffix = node;
      ++suffix_length;
    }
  }

  // Allocate space for the translation.  If the shared suffix is longer
  // than one instruction, we replace it with a single suffix instruction.
  if (suffix_length > 1) length -= (suffix_length - 1);
  const DeoptInfo& deopt_info =
      DeoptInfo::Handle(isolate(), DeoptInfo::New(length));

  // Write the unshared instructions and build their sub-tree.
  TrieNode* node = NULL;
  intptr_t write_count = (suffix_length > 1) ? length - 1 : length;
  for (intptr_t i = 0; i < write_count; ++i) {
    DeoptInstr* instr = instructions_[i];
    deopt_info.SetAt(i, instr->kind(), instr->source_index());
    TrieNode* child = node;
    node = new(isolate()) TrieNode(instr, current_info_number_);
    node->AddChild(child);
  }

  if (suffix_length > 1) {
    suffix->AddChild(node);
    DeoptInstr* instr =
        new(isolate()) DeoptSuffixInstr(suffix->info_number(), suffix_length);
    deopt_info.SetAt(length - 1, instr->kind(), instr->source_index());
  } else {
    trie_root_->AddChild(node);
  }

  ASSERT(deopt_info.VerifyDecompression(instructions_, deopt_table));
  instructions_.Clear();
  materializations_.Clear();
  frame_start_ = -1;

  ++current_info_number_;
  return deopt_info.raw();
}


intptr_t DeoptTable::SizeFor(intptr_t length) {
  return length * kEntrySize;
}

void DeoptTable::SetEntry(const Array& table,
                          intptr_t index,
                          const Smi& offset,
                          const DeoptInfo& info,
                          const Smi& reason) {
  ASSERT((table.Length() % kEntrySize) == 0);
  intptr_t i = index * kEntrySize;
  table.SetAt(i, offset);
  table.SetAt(i + 1, info);
  table.SetAt(i + 2, reason);
}


intptr_t DeoptTable::GetLength(const Array& table) {
  ASSERT((table.Length() % kEntrySize) == 0);
  return table.Length() / kEntrySize;
}


void DeoptTable::GetEntry(const Array& table,
                          intptr_t index,
                          Smi* offset,
                          DeoptInfo* info,
                          Smi* reason) {
  intptr_t i = index * kEntrySize;
  *offset ^= table.At(i);
  *info ^= table.At(i + 1);
  *reason ^= table.At(i + 2);
}

}  // namespace dart

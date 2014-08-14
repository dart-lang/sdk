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
    case DeoptInstr::kStackSlot:
    case DeoptInstr::kDoubleStackSlot:
    case DeoptInstr::kMintStackSlotPair:
    case DeoptInstr::kFloat32x4StackSlot:
    case DeoptInstr::kInt32x4StackSlot:
    case DeoptInstr::kFloat64x2StackSlot:
    case DeoptInstr::kPp:
    case DeoptInstr::kCallerPp:
    case DeoptInstr::kMaterializedObjectRef:
      return true;

    case DeoptInstr::kRegister:
    case DeoptInstr::kFpuRegister:
    case DeoptInstr::kMintRegisterPair:
    case DeoptInstr::kMintStackSlotRegister:
    case DeoptInstr::kFloat32x4FpuRegister:
    case DeoptInstr::kInt32x4FpuRegister:
    case DeoptInstr::kFloat64x2FpuRegister:
      // TODO(turnidge): Sometimes we encounter a deopt instruction
      // with a register source while deoptimizing frames during
      // debugging but we haven't saved our register set.  This
      // happens specifically when using the VMService to inspect the
      // stack.  In that case, the register values will have been
      // saved before the StackOverflow runtime call but we do not
      // actually keep track of which registers were saved and
      // restored.
      //
      // It is possible to save this information at the point of the
      // StackOverflow runtime call but would require a bit of magic
      // to either make sure that the registers are pushed on the
      // stack in a predictable fashion or that we save enough
      // information to recover them after the fact.
      //
      // For now, we punt on these instructions.
      return false;

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
      Array::Handle(Array::New(dest_frame_size_));
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < dest_frame_size_; i++) {
    obj = reinterpret_cast<RawObject*>(dest_frame_[i]);
    dest_array.SetAt(i, obj);
  }
  return dest_array.raw();
}


// Deoptimization instruction moving value from optimized frame at
// 'source_index' to specified slots in the unoptimized frame.
// 'source_index' represents the slot index of the frame (0 being
// first argument) and accounts for saved return address, frame
// pointer, pool pointer and pc marker.
class DeoptStackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptStackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kStackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "s%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    intptr_t* source_addr =
        deopt_context->GetSourceFrameAddressAt(source_index);
    *dest_addr = *source_addr;
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptStackSlotInstr);
};


class DeoptDoubleStackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptDoubleStackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kDoubleStackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "ds%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    double* source_addr = reinterpret_cast<double*>(
        deopt_context->GetSourceFrameAddressAt(source_index));
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferDoubleMaterialization(
        *source_addr, reinterpret_cast<RawDouble**>(dest_addr));
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptDoubleStackSlotInstr);
};


class DeoptFloat32x4StackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptFloat32x4StackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kFloat32x4StackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "f32x4s%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    simd128_value_t* source_addr = reinterpret_cast<simd128_value_t*>(
        deopt_context->GetSourceFrameAddressAt(source_index));
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferFloat32x4Materialization(
        *source_addr, reinterpret_cast<RawFloat32x4**>(dest_addr));
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptFloat32x4StackSlotInstr);
};


class DeoptFloat64x2StackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptFloat64x2StackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kFloat64x2StackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "f64x2s%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    simd128_value_t* source_addr = reinterpret_cast<simd128_value_t*>(
        deopt_context->GetSourceFrameAddressAt(source_index));
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferFloat64x2Materialization(
        *source_addr, reinterpret_cast<RawFloat64x2**>(dest_addr));
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptFloat64x2StackSlotInstr);
};


class DeoptInt32x4StackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptInt32x4StackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kInt32x4StackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "ui32x4s%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    simd128_value_t* source_addr = reinterpret_cast<simd128_value_t*>(
        deopt_context->GetSourceFrameAddressAt(source_index));
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferInt32x4Materialization(
        *source_addr, reinterpret_cast<RawInt32x4**>(dest_addr));
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptInt32x4StackSlotInstr);
};


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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "ret oti:%" Pd "(%" Pd ")", object_table_index_, deopt_id_);
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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "const oti:%" Pd "", object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    const Object& obj = Object::Handle(
        deopt_context->isolate(), deopt_context->ObjectAt(object_table_index_));
    *reinterpret_cast<RawObject**>(dest_addr) = obj.raw();
  }

 private:
  const intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptConstantInstr);
};


// Deoptimization instruction moving a CPU register.
class DeoptRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<Register>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kRegister; }

  virtual const char* ToCString() const {
    return Assembler::RegisterName(reg_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = deopt_context->RegisterValue(reg_);
  }

 private:
  const Register reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRegisterInstr);
};


// Deoptimization instruction moving an XMM register.
class DeoptFpuRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptFpuRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<FpuRegister>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kFpuRegister; }

  virtual const char* ToCString() const {
    return Assembler::FpuRegisterName(reg_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    double value = deopt_context->FpuRegisterValue(reg_);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferDoubleMaterialization(
        value, reinterpret_cast<RawDouble**>(dest_addr));
  }

 private:
  const FpuRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptFpuRegisterInstr);
};


class DeoptMintRegisterPairInstr: public DeoptInstr {
 public:
  DeoptMintRegisterPairInstr(intptr_t lo_reg_as_int, intptr_t hi_reg_as_int)
      : lo_reg_(static_cast<Register>(lo_reg_as_int)),
        hi_reg_(static_cast<Register>(hi_reg_as_int)) {}

  virtual intptr_t source_index() const {
    return EncodeRegisters(static_cast<intptr_t>(lo_reg_),
                           static_cast<intptr_t>(hi_reg_));
  }
  virtual DeoptInstr::Kind kind() const { return kMintRegisterPair; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "int64 register pair: %s,%s", Assembler::RegisterName(hi_reg_),
                                      Assembler::RegisterName(lo_reg_));
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    uint32_t lo_value = deopt_context->RegisterValue(lo_reg_);
    int32_t hi_value = deopt_context->RegisterValue(hi_reg_);
    int64_t value = Utils::LowHighTo64Bits(lo_value, hi_value);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    if (Smi::IsValid(value)) {
      *dest_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class LoRegister : public BitField<intptr_t, 0, kFieldWidth> { };
  class HiRegister : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };
  static intptr_t EncodeRegisters(intptr_t lo_reg_as_int,
                                  intptr_t hi_reg_as_int) {
    return LoRegister::encode(lo_reg_as_int) |
           HiRegister::encode(hi_reg_as_int);
  }

  static intptr_t DecodeLoRegister(intptr_t v) {
    return LoRegister::decode(v);
  }

  static intptr_t DecodeHiRegister(intptr_t v) {
    return HiRegister::decode(v);
  }

 private:
  const Register lo_reg_;
  const Register hi_reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMintRegisterPairInstr);
};


class DeoptMintStackSlotPairInstr: public DeoptInstr {
 public:
  DeoptMintStackSlotPairInstr(intptr_t lo_slot, intptr_t hi_slot)
      : lo_slot_(static_cast<Register>(lo_slot)),
        hi_slot_(static_cast<Register>(hi_slot)) {}

  virtual intptr_t source_index() const {
    return EncodeSlots(static_cast<intptr_t>(lo_slot_),
                       static_cast<intptr_t>(hi_slot_));
  }
  virtual DeoptInstr::Kind kind() const { return kMintStackSlotPair; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "int64 stack slots: %" Pd", %" Pd "", lo_slot_, hi_slot_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t lo_source_index =
        deopt_context->source_frame_size() - lo_slot_ - 1;
    int32_t* lo_source_addr = reinterpret_cast<int32_t*>(
        deopt_context->GetSourceFrameAddressAt(lo_source_index));
    intptr_t hi_source_index =
       deopt_context->source_frame_size() - hi_slot_ - 1;
    int32_t* hi_source_addr = reinterpret_cast<int32_t*>(
        deopt_context->GetSourceFrameAddressAt(hi_source_index));
    int64_t value = Utils::LowHighTo64Bits(*lo_source_addr, *hi_source_addr);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    if (Smi::IsValid(value)) {
      *dest_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class LoSlot : public BitField<intptr_t, 0, kFieldWidth> { };
  class HiSlot : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };
  static intptr_t EncodeSlots(intptr_t lo_slot,
                              intptr_t hi_slot) {
    return LoSlot::encode(lo_slot) |
           HiSlot::encode(hi_slot);
  }

  static intptr_t DecodeLoSlot(intptr_t v) {
    return LoSlot::decode(v);
  }

  static intptr_t DecodeHiSlot(intptr_t v) {
    return HiSlot::decode(v);
  }

 private:
  const intptr_t lo_slot_;
  const intptr_t hi_slot_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMintStackSlotPairInstr);
};


class DeoptMintStackSlotRegisterInstr : public DeoptInstr {
 public:
  DeoptMintStackSlotRegisterInstr(intptr_t source_index,
                                  intptr_t reg_as_int,
                                  bool flip)
      : slot_(source_index),
        reg_(static_cast<Register>(reg_as_int)),
        flip_(flip) {
    // when flip_ is false, stack slot is low bits and reg is high bits.
    // when flip_ is true, stack slot is high bits and reg is low bits.
  }

  virtual intptr_t source_index() const {
    return Encode(static_cast<intptr_t>(slot_),
                  static_cast<intptr_t>(reg_),
                  flip_ ? 1 : 0);
  }
  virtual DeoptInstr::Kind kind() const { return kMintStackSlotRegister; }

  virtual const char* ToCString() const {
    if (flip_) {
      return Isolate::Current()->current_zone()->PrintToString(
          "int64 reg: %s, stack slot:  %" Pd "", Assembler::RegisterName(reg_),
                                                 slot_);
    } else {
      return Isolate::Current()->current_zone()->PrintToString(
          "int64 stack slot: %" Pd", reg: %s", slot_,
                                               Assembler::RegisterName(reg_));
    }
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t slot_source_index =
        deopt_context->source_frame_size() - slot_ - 1;
    int32_t* slot_source_addr = reinterpret_cast<int32_t*>(
        deopt_context->GetSourceFrameAddressAt(slot_source_index));
    int32_t slot_value = *slot_source_addr;
    int32_t reg_value = deopt_context->RegisterValue(reg_);
    int64_t value;
    if (flip_) {
      value = Utils::LowHighTo64Bits(reg_value, slot_value);
    } else {
      value = Utils::LowHighTo64Bits(slot_value, reg_value);
    }
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    if (Smi::IsValid(value)) {
      *dest_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class Slot : public BitField<intptr_t, 0, kFieldWidth> { };
  class Reg : public BitField<intptr_t, kFieldWidth, kFieldWidth - 1> { };
  // 1 bit for the flip.
  class Flip : public BitField<intptr_t, kFieldWidth * 2 - 1, 1> { };

  static intptr_t Encode(intptr_t slot,
                         intptr_t reg_as_int,
                         bool flip) {
    return Slot::encode(slot) |
           Reg::encode(reg_as_int) |
           Flip::encode(flip ? 1 : 0);
  }

  static intptr_t DecodeSlot(intptr_t v) {
    return Slot::decode(v);
  }

  static intptr_t DecodeReg(intptr_t v) {
    return Reg::decode(v);
  }

  static bool DecodeFlip(intptr_t v) {
    return Flip::decode(v);
  }

 private:
  const intptr_t slot_;
  const Register reg_;
  const bool flip_;
  DISALLOW_COPY_AND_ASSIGN(DeoptMintStackSlotRegisterInstr);
};


class DeoptUint32RegisterInstr: public DeoptInstr {
 public:
  explicit DeoptUint32RegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<Register>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kUint32Register; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "uint32 %s", Assembler::RegisterName(reg_));
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    uint32_t low = static_cast<uint32_t>(deopt_context->RegisterValue(reg_));
    int64_t value = Utils::LowHighTo64Bits(low, 0);
    if (Smi::IsValid(value)) {
      *dest_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

 private:
  const Register reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptUint32RegisterInstr);
};


class DeoptUint32StackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptUint32StackSlotInstr(intptr_t source_index)
      : stack_slot_index_(source_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t source_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kUint32StackSlot; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "uint32 s%" Pd "", stack_slot_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    intptr_t source_index =
       deopt_context->source_frame_size() - stack_slot_index_ - 1;
    uint32_t* source_addr = reinterpret_cast<uint32_t*>(
        deopt_context->GetSourceFrameAddressAt(source_index));
    int64_t value = Utils::LowHighTo64Bits(*source_addr, 0);
    if (Smi::IsValid(value)) {
      *dest_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(dest_addr));
    }
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptUint32StackSlotInstr);
};


// Deoptimization instruction moving an XMM register.
class DeoptFloat32x4FpuRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptFloat32x4FpuRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<FpuRegister>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kFloat32x4FpuRegister; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%s(f32x4)", Assembler::FpuRegisterName(reg_));
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    simd128_value_t value = deopt_context->FpuRegisterValueAsSimd128(reg_);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferFloat32x4Materialization(
        value, reinterpret_cast<RawFloat32x4**>(dest_addr));
  }

 private:
  const FpuRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptFloat32x4FpuRegisterInstr);
};


class DeoptFloat64x2FpuRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptFloat64x2FpuRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<FpuRegister>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kFloat64x2FpuRegister; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%s(f64x2)", Assembler::FpuRegisterName(reg_));
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    simd128_value_t value = deopt_context->FpuRegisterValueAsSimd128(reg_);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferFloat64x2Materialization(
        value, reinterpret_cast<RawFloat64x2**>(dest_addr));
  }

 private:
  const FpuRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptFloat64x2FpuRegisterInstr);
};


// Deoptimization instruction moving an XMM register.
class DeoptInt32x4FpuRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptInt32x4FpuRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<FpuRegister>(reg_as_int)) {}

  virtual intptr_t source_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kInt32x4FpuRegister; }

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "%s(f32x4)", Assembler::FpuRegisterName(reg_));
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    simd128_value_t value = deopt_context->FpuRegisterValueAsSimd128(reg_);
    *reinterpret_cast<RawSmi**>(dest_addr) = Smi::New(0);
    deopt_context->DeferInt32x4Materialization(
        value, reinterpret_cast<RawInt32x4**>(dest_addr));
  }

 private:
  const FpuRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptInt32x4FpuRegisterInstr);
};


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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "pcmark oti:%" Pd "", object_table_index_);
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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "pp oti:%" Pd "", object_table_index_);
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

  virtual const char* ToCString() const {
    return "callerfp";
  }

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

  virtual const char* ToCString() const {
    return "callerpp";
  }

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

  virtual const char* ToCString() const {
    return "callerpc";
  }

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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "suffix %" Pd ":%" Pd, info_number_, suffix_length_);
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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "mat ref #%" Pd "", index_);
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

  virtual const char* ToCString() const {
    return Isolate::Current()->current_zone()->PrintToString(
        "mat obj len:%" Pd "", field_count_);
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
    case kStackSlot: return new DeoptStackSlotInstr(source_index);
    case kDoubleStackSlot: return new DeoptDoubleStackSlotInstr(source_index);
    case kFloat32x4StackSlot:
        return new DeoptFloat32x4StackSlotInstr(source_index);
    case kFloat64x2StackSlot:
        return new DeoptFloat64x2StackSlotInstr(source_index);
    case kInt32x4StackSlot:
        return new DeoptInt32x4StackSlotInstr(source_index);
    case kRetAddress: return new DeoptRetAddressInstr(source_index);
    case kConstant: return new DeoptConstantInstr(source_index);
    case kRegister: return new DeoptRegisterInstr(source_index);
    case kFpuRegister: return new DeoptFpuRegisterInstr(source_index);
    case kMintRegisterPair: {
      intptr_t lo_reg_as_int =
          DeoptMintRegisterPairInstr::LoRegister::decode(source_index);
      intptr_t hi_reg_as_int =
          DeoptMintRegisterPairInstr::HiRegister::decode(source_index);
      return new DeoptMintRegisterPairInstr(lo_reg_as_int, hi_reg_as_int);
    }
    case kMintStackSlotPair: {
      intptr_t lo_slot =
          DeoptMintStackSlotPairInstr::LoSlot::decode(source_index);
      intptr_t hi_slot =
          DeoptMintStackSlotPairInstr::HiSlot::decode(source_index);
      return new DeoptMintStackSlotPairInstr(lo_slot, hi_slot);
    }
    case kMintStackSlotRegister: {
      intptr_t slot =
          DeoptMintStackSlotRegisterInstr::Slot::decode(source_index);
      intptr_t reg_as_int =
          DeoptMintStackSlotRegisterInstr::Reg::decode(source_index);
      bool flip = DeoptMintStackSlotRegisterInstr::Flip::decode(source_index);
      return new DeoptMintStackSlotRegisterInstr(slot, reg_as_int, flip);
    }
    case kUint32Register:
      return new DeoptUint32RegisterInstr(source_index);
    case kUint32StackSlot:
      return new DeoptUint32StackSlotInstr(source_index);
    case kFloat32x4FpuRegister:
        return new DeoptFloat32x4FpuRegisterInstr(source_index);
    case kFloat64x2FpuRegister:
        return new DeoptFloat64x2FpuRegisterInstr(source_index);
    case kInt32x4FpuRegister:
        return new DeoptInt32x4FpuRegisterInstr(source_index);
    case kPcMarker: return new DeoptPcMarkerInstr(source_index);
    case kPp: return new DeoptPpInstr(source_index);
    case kCallerFp: return new DeoptCallerFpInstr();
    case kCallerPp: return new DeoptCallerPpInstr();
    case kCallerPc: return new DeoptCallerPcInstr();
    case kSuffix: return new DeoptSuffixInstr(source_index);
    case kMaterializedObjectRef:
        return new DeoptMaterializedObjectRefInstr(source_index);
    case kMaterializeObject:
      return new DeoptMaterializeObjectInstr(source_index);
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
  } else if (source_loc.IsRegister()) {
    if (value->definition()->representation() == kUnboxedUint32) {
      deopt_instr = new(isolate()) DeoptUint32RegisterInstr(source_loc.reg());
    } else {
      ASSERT(value->definition()->representation() == kTagged);
      deopt_instr = new(isolate()) DeoptRegisterInstr(source_loc.reg());
    }
  } else if (source_loc.IsFpuRegister()) {
    if (value->definition()->representation() == kUnboxedDouble) {
      deopt_instr = new(isolate()) DeoptFpuRegisterInstr(source_loc.fpu_reg());
    } else if (value->definition()->representation() == kUnboxedFloat32x4) {
      deopt_instr =
          new(isolate()) DeoptFloat32x4FpuRegisterInstr(source_loc.fpu_reg());
    } else if (value->definition()->representation() == kUnboxedInt32x4) {
      deopt_instr =
          new(isolate()) DeoptInt32x4FpuRegisterInstr(source_loc.fpu_reg());
    } else {
      ASSERT(value->definition()->representation() == kUnboxedFloat64x2);
      deopt_instr =
          new(isolate()) DeoptFloat64x2FpuRegisterInstr(source_loc.fpu_reg());
    }
  } else if (source_loc.IsStackSlot()) {
    if (value->definition()->representation() == kUnboxedUint32) {
      intptr_t source_index = CalculateStackIndex(source_loc);
      deopt_instr = new(isolate()) DeoptUint32StackSlotInstr(source_index);
    } else {
      ASSERT(value->definition()->representation() == kTagged);
      intptr_t source_index = CalculateStackIndex(source_loc);
      deopt_instr = new(isolate()) DeoptStackSlotInstr(source_index);
    }
  } else if (source_loc.IsDoubleStackSlot()) {
    ASSERT(value->definition()->representation() == kUnboxedDouble);
    intptr_t source_index = CalculateStackIndex(source_loc);
    deopt_instr = new(isolate()) DeoptDoubleStackSlotInstr(source_index);
  } else if (source_loc.IsQuadStackSlot()) {
    intptr_t source_index = CalculateStackIndex(source_loc);
    if (value->definition()->representation() == kUnboxedFloat32x4) {
      deopt_instr = new(isolate()) DeoptFloat32x4StackSlotInstr(source_index);
    } else if (value->definition()->representation() == kUnboxedInt32x4) {
      deopt_instr = new(isolate()) DeoptInt32x4StackSlotInstr(source_index);
    } else {
      ASSERT(value->definition()->representation() == kUnboxedFloat64x2);
      deopt_instr = new(isolate()) DeoptFloat64x2StackSlotInstr(source_index);
    }
  } else if (source_loc.IsPairLocation()) {
    ASSERT(value->definition()->representation() == kUnboxedMint);
    // There are four cases to consider here:
    // (R = Register, S = Stack slot).
    // 1) R, R.
    // 2) S, S.
    // 3) R, S.
    // 4) S, R.
    PairLocation* pair = source_loc.AsPairLocation();
    if (pair->At(0).IsRegister() && pair->At(1).IsRegister()) {
      deopt_instr =
          new(isolate()) DeoptMintRegisterPairInstr(pair->At(0).reg(),
                                                    pair->At(1).reg());
    } else if (pair->At(0).IsStackSlot() && pair->At(1).IsStackSlot()) {
      deopt_instr = new(isolate()) DeoptMintStackSlotPairInstr(
          CalculateStackIndex(pair->At(0)),
          CalculateStackIndex(pair->At(1)));
    } else if (pair->At(0).IsRegister() && pair->At(1).IsStackSlot()) {
      deopt_instr = new(isolate()) DeoptMintStackSlotRegisterInstr(
          CalculateStackIndex(pair->At(1)),
          pair->At(0).reg(),
          true);
    } else {
      ASSERT(pair->At(0).IsStackSlot() && pair->At(1).IsRegister());
      deopt_instr = new(isolate()) DeoptMintStackSlotRegisterInstr(
          CalculateStackIndex(pair->At(0)),
          pair->At(1).reg(),
          false);
    }
  } else if (source_loc.IsInvalid() &&
             value->definition()->IsMaterializeObject()) {
    const intptr_t index = FindMaterialization(
        value->definition()->AsMaterializeObject());
    ASSERT(index >= 0);
    deopt_instr = new(isolate()) DeoptMaterializedObjectRefInstr(index);
  } else {
    UNREACHABLE();
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

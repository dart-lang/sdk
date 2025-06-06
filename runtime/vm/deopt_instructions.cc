// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/deopt_instructions.h"

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool,
            compress_deopt_info,
            true,
            "Compress the size of the deoptimization info for optimized code.");
DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, trace_deoptimization_verbose);

DeoptContext::DeoptContext(const StackFrame* frame,
                           const Code& code,
                           DestFrameOptions dest_options,
                           fpu_register_t* fpu_registers,
                           intptr_t* cpu_registers,
                           bool is_lazy_deopt,
                           bool deoptimizing_code)
    : code_(code.ptr()),
      object_pool_(code.GetObjectPool()),
      deopt_info_(TypedData::null()),
      dest_frame_is_allocated_(false),
      dest_frame_(nullptr),
      dest_frame_size_(0),
      source_frame_is_allocated_(false),
      source_frame_(nullptr),
      source_frame_size_(0),
      cpu_registers_(cpu_registers),
      fpu_registers_(fpu_registers),
      num_args_(0),
      deopt_reason_(ICData::kDeoptUnknown),
      deopt_flags_(0),
      thread_(Thread::Current()),
      deopt_start_micros_(0),
      deferred_slots_(nullptr),
      deferred_objects_count_(0),
      deferred_objects_(nullptr),
      is_lazy_deopt_(is_lazy_deopt),
      deoptimizing_code_(deoptimizing_code) {
  const TypedData& deopt_info = TypedData::Handle(
      code.GetDeoptInfoAtPc(frame->pc(), &deopt_reason_, &deopt_flags_));
#if defined(DEBUG)
  if (deopt_info.IsNull()) {
    OS::PrintErr("Missing deopt info for pc %" Px "\n", frame->pc());
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
  }
#endif
  ASSERT(!deopt_info.IsNull());
  deopt_info_ = deopt_info.ptr();

  const Function& function = Function::Handle(code.function());

  // Do not include incoming arguments if there are optional arguments
  // (they are copied into local space at method entry).
  num_args_ =
      function.MakesCopyOfParameters() ? 0 : function.num_fixed_parameters();

  // The fixed size section of the (fake) Dart frame called via a stub by the
  // optimized function contains FP, PP (ARM only), PC-marker and
  // return-address. This section is copied as well, so that its contained
  // values can be updated before returning to the deoptimized function.
  ASSERT(frame->fp() >= frame->sp());
  const intptr_t frame_size = (frame->fp() - frame->sp()) / kWordSize;

  source_frame_size_ = +kDartFrameFixedSize   // For saved values below sp.
                       + frame_size           // For frame size incl. sp.
                       + 1                    // For fp.
                       + kParamEndSlotFromFp  // For saved values above fp.
                       + num_args_;           // For arguments.

  source_frame_ = FrameBase(frame);

  if (dest_options == kDestIsOriginalFrame) {
    // Work from a copy of the source frame.
    intptr_t* original_frame = source_frame_;
    source_frame_ = new intptr_t[source_frame_size_];
    ASSERT(source_frame_ != nullptr);
    for (intptr_t i = 0; i < source_frame_size_; i++) {
      source_frame_[i] = original_frame[i];
    }
    source_frame_is_allocated_ = true;
  }
  caller_fp_ = GetSourceFp();

  dest_frame_size_ = DeoptInfo::FrameSize(deopt_info);

  if (dest_options == kDestIsAllocated) {
    dest_frame_ = new intptr_t[dest_frame_size_];
    ASSERT(source_frame_ != nullptr);
    for (intptr_t i = 0; i < dest_frame_size_; i++) {
      dest_frame_[i] = 0;
    }
    dest_frame_is_allocated_ = true;
  }

  if (dest_options != kDestIsAllocated) {
    // kDestIsAllocated is used by the debugger to generate a stack trace
    // and does not signal a real deopt.
    deopt_start_micros_ = OS::GetCurrentMonotonicMicros();
  }

  if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
    THR_Print(
        "Deoptimizing (reason %d '%s') at "
        "pc=%" Pp " fp=%" Pp " '%s' (count %d)\n",
        deopt_reason(), DeoptReasonToCString(deopt_reason()), frame->pc(),
        frame->fp(), function.ToFullyQualifiedCString(),
        function.deoptimization_counter());
  }
}

DeoptContext::~DeoptContext() {
  // Delete memory for source frame and registers.
  if (source_frame_is_allocated_) {
    delete[] source_frame_;
  }
  source_frame_ = nullptr;
  delete[] fpu_registers_;
  delete[] cpu_registers_;
  fpu_registers_ = nullptr;
  cpu_registers_ = nullptr;
  if (dest_frame_is_allocated_) {
    delete[] dest_frame_;
  }
  dest_frame_ = nullptr;

  // Delete all deferred objects.
  for (intptr_t i = 0; i < deferred_objects_count_; i++) {
    delete deferred_objects_[i];
  }
  delete[] deferred_objects_;
  deferred_objects_ = nullptr;
  deferred_objects_count_ = 0;

#if defined(SUPPORT_TIMELINE)
  if (deopt_start_micros_ != 0) {
    TimelineStream* compiler_stream = Timeline::GetCompilerStream();
    ASSERT(compiler_stream != nullptr);
    if (compiler_stream->enabled()) {
      // Allocate all Dart objects needed before calling StartEvent,
      // which blocks safe points until Complete is called.
      const Code& code = Code::Handle(zone(), code_);
      const Function& function = Function::Handle(zone(), code.function());
      const String& function_name =
          String::Handle(zone(), function.QualifiedScrubbedName());
      const char* reason = DeoptReasonToCString(deopt_reason());
      const int counter = function.deoptimization_counter();
      TimelineEvent* timeline_event = compiler_stream->StartEvent();
      if (timeline_event != nullptr) {
        timeline_event->Duration("Deoptimize", deopt_start_micros_,
                                 OS::GetCurrentMonotonicMicros());
        timeline_event->SetNumArguments(3);
        timeline_event->CopyArgument(0, "function", function_name.ToCString());
        timeline_event->CopyArgument(1, "reason", reason);
        timeline_event->FormatArgument(2, "deoptimizationCount", "%d", counter);
        timeline_event->Complete();
      }
    }
  }
#endif  // !PRODUCT
}

void DeoptContext::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&code_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&object_pool_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&deopt_info_));

  // Visit any object pointers on the destination stack.
  if (dest_frame_is_allocated_) {
    for (intptr_t i = 0; i < dest_frame_size_; i++) {
      if (dest_frame_[i] != 0) {
        visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&dest_frame_[i]));
      }
    }
  }
}

intptr_t DeoptContext::DestStackAdjustment() const {
  return dest_frame_size_ - kDartFrameFixedSize - num_args_ - 1  // For fp.
         - kParamEndSlotFromFp;
}

intptr_t DeoptContext::GetSourceFp() const {
  return source_frame_[source_frame_size_ - 1 - num_args_ -
                       kParamEndSlotFromFp + kSavedCallerFpSlotFromFp];
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
    case DeoptInstr::kFloat:
    case DeoptInstr::kDouble:
    case DeoptInstr::kMint:
    case DeoptInstr::kMintPair:
    case DeoptInstr::kInt32:
    case DeoptInstr::kUint32:
      return true;

    case DeoptInstr::kRetAddress:
    case DeoptInstr::kPcMarker:
    case DeoptInstr::kCallerFp:
    case DeoptInstr::kCallerPc:
      return false;

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
  const TypedData& deopt_info = TypedData::Handle(deopt_info_);

  GrowableArray<DeoptInstr*> deopt_instructions;
  const Array& deopt_table = Array::Handle(code.deopt_info_array());
  ASSERT(!deopt_table.IsNull());
  DeoptInfo::Unpack(deopt_table, deopt_info, &deopt_instructions);

  const intptr_t len = deopt_instructions.length();
  const intptr_t frame_size = dest_frame_size_;

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
  const intptr_t num_materializations =
      DeoptInfo::NumMaterializations(deopt_instructions);
  PrepareForDeferredMaterialization(num_materializations);
  for (intptr_t from_index = 0, to_index = kDartFrameFixedSize;
       from_index < num_materializations; from_index++) {
    const intptr_t field_count =
        DeoptInstr::GetFieldCount(deopt_instructions[from_index]);
    intptr_t* args = GetDestFrameAddressAt(to_index);
    DeferredObject* obj = new DeferredObject(field_count, args);
    SetDeferredObjectAt(from_index, obj);
    to_index += obj->ArgumentCount();
  }

  // Populate stack frames.
  for (intptr_t to_index = frame_size - 1, from_index = len - 1; to_index >= 0;
       to_index--, from_index--) {
    intptr_t* to_addr = GetDestFrameAddressAt(to_index);
    DeoptInstr* instr = deopt_instructions[from_index];
    if (!objects_only || IsObjectInstruction(instr->kind())) {
      instr->Execute(this, to_addr);
    } else {
      *reinterpret_cast<ObjectPtr*>(to_addr) = Object::null();
    }
  }

  if (FLAG_trace_deoptimization_verbose) {
    for (intptr_t i = 0; i < frame_size; i++) {
      intptr_t* to_addr = GetDestFrameAddressAt(i);
      THR_Print("*%" Pd ". [%p] 0x%" Px " [%s]\n", i, to_addr, *to_addr,
                deopt_instructions[i + (len - frame_size)]->ToCString());
    }
  }
}

static void FillDeferredSlots(DeoptContext* deopt_context,
                              DeferredSlot** slot_list) {
  DeferredSlot* slot = *slot_list;
  *slot_list = nullptr;

  while (slot != nullptr) {
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
  // use it to report the source line where deoptimization occurred.
  if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
    DartFrameIterator iterator(Thread::Current(),
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* top_frame = iterator.NextFrame();
    ASSERT(top_frame != nullptr);
    const Code& code = Code::Handle(top_frame->LookupDartCode());
    const Function& top_function = Function::Handle(code.function());
    const Script& script = Script::Handle(top_function.script());
    const TokenPosition token_pos = code.GetTokenIndexOfPC(top_frame->pc());
    THR_Print("  Function: %s\n", top_function.ToFullyQualifiedCString());
    intptr_t line;
    if (script.GetTokenLocation(token_pos, &line)) {
      String& line_string = String::Handle(script.GetLine(line));
      char line_buffer[80];
      Utils::SNPrint(line_buffer, sizeof(line_buffer), "  Line %" Pd ": '%s'",
                     line, line_string.ToCString());
      THR_Print("%s\n", line_buffer);
    }
    THR_Print("  Deopt args: %" Pd "\n", deopt_arg_count);
  }

  return deopt_arg_count;
}

ArrayPtr DeoptContext::DestFrameAsArray() {
  ASSERT(dest_frame_ != nullptr && dest_frame_is_allocated_);
  const Array& dest_array = Array::Handle(zone(), Array::New(dest_frame_size_));
  PassiveObject& obj = PassiveObject::Handle(zone());
  for (intptr_t i = 0; i < dest_frame_size_; i++) {
    obj = static_cast<ObjectPtr>(dest_frame_[i]);
    dest_array.SetAt(i, obj);
  }
  return dest_array.ptr();
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
        deopt_id_(DeoptId::decode(source_index)) {}

  virtual intptr_t source_index() const {
    return ObjectTableIndex::encode(object_table_index_) |
           DeoptId::encode(deopt_id_);
  }

  virtual DeoptInstr::Kind kind() const { return kRetAddress; }

  virtual const char* ArgumentsToCString() const {
    return Thread::Current()->zone()->PrintToString(
        "%" Pd ", %" Pd "", object_table_index_, deopt_id_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = Smi::RawValue(0);
    deopt_context->DeferRetAddrMaterialization(object_table_index_, deopt_id_,
                                               dest_addr);
  }

  intptr_t object_table_index() const { return object_table_index_; }
  intptr_t deopt_id() const { return deopt_id_; }

 private:
  static constexpr intptr_t kFieldWidth = kBitsPerWord / 2;
  using ObjectTableIndex = BitField<intptr_t, intptr_t, 0, kFieldWidth>;
  using DeoptId =
      BitField<intptr_t, intptr_t, ObjectTableIndex::kNextBit, kFieldWidth>;

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
    return Thread::Current()->zone()->PrintToString("%" Pd "",
                                                    object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    const PassiveObject& obj = PassiveObject::Handle(
        deopt_context->zone(), deopt_context->ObjectAt(object_table_index_));
    *reinterpret_cast<ObjectPtr*>(dest_addr) = obj.ptr();
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
class DeoptWordInstr : public DeoptInstr {
 public:
  explicit DeoptWordInstr(intptr_t source_index) : source_(source_index) {}

  explicit DeoptWordInstr(const CpuRegisterSource& source) : source_(source) {}

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return kWord; }

  virtual const char* ArgumentsToCString() const { return source_.ToCString(); }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = source_.Value<intptr_t>(deopt_context);
  }

 private:
  const CpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptWordInstr);
};

class DeoptIntegerInstrBase : public DeoptInstr {
 public:
  DeoptIntegerInstrBase() {}

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    const int64_t value = GetValue(deopt_context);
    if (Smi::IsValid(value)) {
      *dest_addr = Smi::RawValue(static_cast<intptr_t>(value));
    } else {
      *dest_addr = Smi::RawValue(0);
      deopt_context->DeferMintMaterialization(
          value, reinterpret_cast<MintPtr*>(dest_addr));
    }
  }

  virtual int64_t GetValue(DeoptContext* deopt_context) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptIntegerInstrBase);
};

class DeoptMintPairInstr : public DeoptIntegerInstrBase {
 public:
  explicit DeoptMintPairInstr(intptr_t source_index)
      : DeoptIntegerInstrBase(),
        lo_(LoRegister::decode(source_index)),
        hi_(HiRegister::decode(source_index)) {}

  DeoptMintPairInstr(const CpuRegisterSource& lo, const CpuRegisterSource& hi)
      : DeoptIntegerInstrBase(), lo_(lo), hi_(hi) {}

  virtual intptr_t source_index() const {
    return LoRegister::encode(lo_.source_index()) |
           HiRegister::encode(hi_.source_index());
  }
  virtual DeoptInstr::Kind kind() const { return kMintPair; }

  virtual const char* ArgumentsToCString() const {
    return Thread::Current()->zone()->PrintToString("%s,%s", lo_.ToCString(),
                                                    hi_.ToCString());
  }

  virtual int64_t GetValue(DeoptContext* deopt_context) {
    return Utils::LowHighTo64Bits(lo_.Value<uint32_t>(deopt_context),
                                  hi_.Value<int32_t>(deopt_context));
  }

 private:
  static constexpr intptr_t kFieldWidth = kBitsPerWord / 2;
  using LoRegister = BitField<intptr_t, intptr_t, 0, kFieldWidth>;
  using HiRegister =
      BitField<intptr_t, intptr_t, LoRegister::kNextBit, kFieldWidth>;

  const CpuRegisterSource lo_;
  const CpuRegisterSource hi_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMintPairInstr);
};

template <DeoptInstr::Kind K, CatchEntryMove::SourceKind slot_kind, typename T>
class DeoptIntInstr : public DeoptIntegerInstrBase {
 public:
  explicit DeoptIntInstr(intptr_t source_index)
      : DeoptIntegerInstrBase(), source_(source_index) {}

  explicit DeoptIntInstr(const CpuRegisterSource& source)
      : DeoptIntegerInstrBase(), source_(source) {}

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return K; }

  virtual const char* ArgumentsToCString() const { return source_.ToCString(); }

  virtual int64_t GetValue(DeoptContext* deopt_context) {
    return static_cast<int64_t>(source_.Value<T>(deopt_context));
  }

 private:
  const CpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptIntInstr);
};

typedef DeoptIntInstr<DeoptInstr::kUint32,
                      CatchEntryMove::SourceKind::kUint32Slot,
                      uint32_t>
    DeoptUint32Instr;
typedef DeoptIntInstr<DeoptInstr::kInt32,
                      CatchEntryMove::SourceKind::kInt32Slot,
                      int32_t>
    DeoptInt32Instr;
typedef DeoptIntInstr<DeoptInstr::kMint,
                      CatchEntryMove::SourceKind::kInt64Slot,
                      int64_t>
    DeoptMintInstr;

template <DeoptInstr::Kind K,
          CatchEntryMove::SourceKind slot_kind,
          typename Type,
          typename PtrType>
class DeoptFpuInstr : public DeoptInstr {
 public:
  explicit DeoptFpuInstr(intptr_t source_index) : source_(source_index) {}

  explicit DeoptFpuInstr(const FpuRegisterSource& source) : source_(source) {}

  virtual intptr_t source_index() const { return source_.source_index(); }
  virtual DeoptInstr::Kind kind() const { return K; }

  virtual const char* ArgumentsToCString() const { return source_.ToCString(); }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = Smi::RawValue(0);
    deopt_context->DeferMaterialization(source_.Value<Type>(deopt_context),
                                        reinterpret_cast<PtrType*>(dest_addr));
  }

 private:
  const FpuRegisterSource source_;

  DISALLOW_COPY_AND_ASSIGN(DeoptFpuInstr);
};

typedef DeoptFpuInstr<DeoptInstr::kFloat,
                      CatchEntryMove::SourceKind::kFloatSlot,
                      float,
                      DoublePtr>
    DeoptFloatInstr;

typedef DeoptFpuInstr<DeoptInstr::kDouble,
                      CatchEntryMove::SourceKind::kDoubleSlot,
                      double,
                      DoublePtr>
    DeoptDoubleInstr;

// Simd128 types.
typedef DeoptFpuInstr<DeoptInstr::kFloat32x4,
                      CatchEntryMove::SourceKind::kFloat32x4Slot,
                      simd128_value_t,
                      Float32x4Ptr>
    DeoptFloat32x4Instr;
typedef DeoptFpuInstr<DeoptInstr::kFloat64x2,
                      CatchEntryMove::SourceKind::kFloat64x2Slot,
                      simd128_value_t,
                      Float64x2Ptr>
    DeoptFloat64x2Instr;
typedef DeoptFpuInstr<DeoptInstr::kInt32x4,
                      CatchEntryMove::SourceKind::kInt32x4Slot,
                      simd128_value_t,
                      Int32x4Ptr>
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
    return Thread::Current()->zone()->PrintToString("%" Pd "",
                                                    object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    Function& function = Function::Handle(deopt_context->zone());
    function ^= deopt_context->ObjectAt(object_table_index_);
    if (function.IsNull()) {
      *reinterpret_cast<ObjectPtr*>(dest_addr) =
          deopt_context->is_lazy_deopt()
              ? StubCode::DeoptimizeLazyFromReturn().ptr()
              : StubCode::Deoptimize().ptr();
      return;
    }

    // We don't always have the Code object for the frame's corresponding
    // unoptimized code as it may have been collected. Use a stub as the pc
    // marker until we can recreate that Code object during deferred
    // materialization to maintain the invariant that Dart frames always have
    // a pc marker.
    *reinterpret_cast<ObjectPtr*>(dest_addr) =
        StubCode::FrameAwaitingMaterialization().ptr();
    deopt_context->DeferPcMarkerMaterialization(object_table_index_, dest_addr);
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
    return Thread::Current()->zone()->PrintToString("%" Pd "",
                                                    object_table_index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *dest_addr = Smi::RawValue(0);
    deopt_context->DeferPpMaterialization(
        object_table_index_, reinterpret_cast<ObjectPtr*>(dest_addr));
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
    deopt_context->SetCallerFp(
        reinterpret_cast<intptr_t>(dest_addr - kSavedCallerFpSlotFromFp));
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

// Write reference to a materialized object with the given index into the
// stack slot.
class DeoptMaterializedObjectRefInstr : public DeoptInstr {
 public:
  explicit DeoptMaterializedObjectRefInstr(intptr_t index) : index_(index) {
    ASSERT(index >= 0);
  }

  virtual intptr_t source_index() const { return index_; }
  virtual DeoptInstr::Kind kind() const { return kMaterializedObjectRef; }

  virtual const char* ArgumentsToCString() const {
    return Thread::Current()->zone()->PrintToString("#%" Pd "", index_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    *reinterpret_cast<SmiPtr*>(dest_addr) = Smi::New(0);
    deopt_context->DeferMaterializedObjectRef(index_, dest_addr);
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
    return Thread::Current()->zone()->PrintToString("%" Pd "", field_count_);
  }

  void Execute(DeoptContext* deopt_context, intptr_t* dest_addr) {
    // This instructions are executed manually by the DeoptimizeWithDeoptInfo.
    UNREACHABLE();
  }

 private:
  intptr_t field_count_;

  DISALLOW_COPY_AND_ASSIGN(DeoptMaterializeObjectInstr);
};

uword DeoptInstr::GetRetAddress(DeoptInstr* instr,
                                const ObjectPool& object_table,
                                Code* code) {
  ASSERT(instr->kind() == kRetAddress);
  DeoptRetAddressInstr* ret_address_instr =
      static_cast<DeoptRetAddressInstr*>(instr);
  ASSERT(!object_table.IsNull());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& function = Function::Handle(zone);
  function ^= object_table.ObjectAt(ret_address_instr->object_table_index());
  ASSERT(!function.ForceOptimize());
  ASSERT(code != nullptr);
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  *code = function.unoptimized_code();
  ASSERT(!code->IsNull());
  uword res = code->GetPcForDeoptId(ret_address_instr->deopt_id(),
                                    UntaggedPcDescriptors::kDeopt);
  ASSERT(res != 0);
  return res;
}

DeoptInstr* DeoptInstr::Create(intptr_t kind_as_int, intptr_t source_index) {
  Kind kind = static_cast<Kind>(kind_as_int);
  switch (kind) {
    case kWord:
      return new DeoptWordInstr(source_index);
    case kFloat:
      return new DeoptFloatInstr(source_index);
    case kDouble:
      return new DeoptDoubleInstr(source_index);
    case kMint:
      return new DeoptMintInstr(source_index);
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
    case kMaterializedObjectRef:
      return new DeoptMaterializedObjectRefInstr(source_index);
    case kMaterializeObject:
      return new DeoptMaterializeObjectInstr(source_index);
  }
  UNREACHABLE();
  return nullptr;
}

const char* DeoptInstr::KindToCString(Kind kind) {
  switch (kind) {
    case kWord:
      return "word";
    case kFloat:
      return "float";
    case kDouble:
      return "double";
    case kMint:
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
    case kMaterializedObjectRef:
      return "ref";
    case kMaterializeObject:
      return "mat";
  }
  UNREACHABLE();
  return nullptr;
}

class DeoptInfoBuilder::TrieNode : public ZoneAllocated {
 public:
  // Construct the root node representing the implicit "shared" terminator
  // at the end of each deopt info.
  TrieNode() : instruction_(nullptr), info_number_(-1), children_(16) {}

  // Construct a node representing a written instruction.
  TrieNode(DeoptInstr* instruction, intptr_t info_number)
      : instruction_(instruction), info_number_(info_number), children_(4) {}

  intptr_t info_number() const { return info_number_; }

  void AddChild(TrieNode* child) {
    if (child != nullptr) children_.Add(child);
  }

  TrieNode* FindChild(const DeoptInstr& instruction) {
    for (intptr_t i = 0; i < children_.length(); ++i) {
      TrieNode* child = children_[i];
      if (child->instruction_->Equals(instruction)) return child;
    }
    return nullptr;
  }

 private:
  const DeoptInstr* instruction_;  // Instruction that was written.
  const intptr_t info_number_;     // Index of the deopt info it was written to.

  GrowableArray<TrieNode*> children_;
};

DeoptInfoBuilder::DeoptInfoBuilder(Zone* zone,
                                   const intptr_t num_args,
                                   compiler::Assembler* assembler)
    : zone_(zone),
      instructions_(),
      num_args_(num_args),
      assembler_(assembler),
      trie_root_(new (zone) TrieNode()),
      current_info_number_(0),
      frame_start_(-1),
      materializations_() {}

intptr_t DeoptInfoBuilder::FindOrAddObjectInTable(const Object& obj) const {
  return assembler_->object_pool_builder().FindObject(obj);
}

intptr_t DeoptInfoBuilder::CalculateStackIndex(
    const Location& source_loc) const {
  intptr_t index = -compiler::target::frame_layout.VariableIndexForFrameSlot(
      source_loc.stack_index());
  return index < 0 ? index + num_args_
                   : index + num_args_ + kDartFrameFixedSize;
}

CpuRegisterSource DeoptInfoBuilder::ToCpuRegisterSource(const Location& loc) {
  if (loc.IsRegister()) {
    return CpuRegisterSource(CpuRegisterSource::kRegister, loc.reg());
  } else {
    ASSERT(loc.IsStackSlot());
    return CpuRegisterSource(CpuRegisterSource::kStackSlot,
                             CalculateStackIndex(loc));
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
    return FpuRegisterSource(FpuRegisterSource::kStackSlot,
                             CalculateStackIndex(loc));
  }
}

void DeoptInfoBuilder::AddReturnAddress(const Function& function,
                                        intptr_t deopt_id,
                                        intptr_t dest_index) {
  const intptr_t object_table_index = FindOrAddObjectInTable(function);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone())
                        DeoptRetAddressInstr(object_table_index, deopt_id));
}

void DeoptInfoBuilder::AddPcMarker(const Function& function,
                                   intptr_t dest_index) {
  intptr_t object_table_index = FindOrAddObjectInTable(function);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone()) DeoptPcMarkerInstr(object_table_index));
}

void DeoptInfoBuilder::AddPp(const Function& function, intptr_t dest_index) {
  intptr_t object_table_index = FindOrAddObjectInTable(function);
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone()) DeoptPpInstr(object_table_index));
}

void DeoptInfoBuilder::AddCopy(Value* value,
                               const Location& source_loc,
                               const intptr_t dest_index) {
  DeoptInstr* deopt_instr = nullptr;
  if (source_loc.IsConstant()) {
    intptr_t object_table_index = FindOrAddObjectInTable(source_loc.constant());
    deopt_instr = new (zone()) DeoptConstantInstr(object_table_index);
  } else if (source_loc.IsInvalid() &&
             value->definition()->IsMaterializeObject()) {
    const intptr_t index =
        FindMaterialization(value->definition()->AsMaterializeObject());
    ASSERT(index >= 0);
    deopt_instr = new (zone()) DeoptMaterializedObjectRefInstr(index);
  } else {
    ASSERT(!source_loc.IsInvalid());
    Representation rep = value->definition()->representation();
    switch (rep) {
      case kTagged:
        deopt_instr =
            new (zone()) DeoptWordInstr(ToCpuRegisterSource(source_loc));
        break;
#if defined(TARGET_ARCH_IS_64_BIT)
      case kUntagged:
#endif
      case kUnboxedInt64: {
        if (source_loc.IsPairLocation()) {
          PairLocation* pair = source_loc.AsPairLocation();
          deopt_instr =
              new (zone()) DeoptMintPairInstr(ToCpuRegisterSource(pair->At(0)),
                                              ToCpuRegisterSource(pair->At(1)));
        } else {
          ASSERT(!source_loc.IsPairLocation());
          deopt_instr =
              new (zone()) DeoptMintInstr(ToCpuRegisterSource(source_loc));
        }
        break;
      }
#if defined(TARGET_ARCH_IS_32_BIT)
      case kUntagged:
#endif
      case kUnboxedInt32:
        deopt_instr =
            new (zone()) DeoptInt32Instr(ToCpuRegisterSource(source_loc));
        break;
      case kUnboxedUint32:
        deopt_instr =
            new (zone()) DeoptUint32Instr(ToCpuRegisterSource(source_loc));
        break;
      case kUnboxedFloat:
        deopt_instr = new (zone()) DeoptFloatInstr(
            ToFpuRegisterSource(source_loc, Location::kDoubleStackSlot));
        break;
      case kUnboxedDouble:
        deopt_instr = new (zone()) DeoptDoubleInstr(
            ToFpuRegisterSource(source_loc, Location::kDoubleStackSlot));
        break;
      case kUnboxedFloat32x4:
        deopt_instr = new (zone()) DeoptFloat32x4Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      case kUnboxedFloat64x2:
        deopt_instr = new (zone()) DeoptFloat64x2Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      case kUnboxedInt32x4:
        deopt_instr = new (zone()) DeoptInt32x4Instr(
            ToFpuRegisterSource(source_loc, Location::kQuadStackSlot));
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
  ASSERT(dest_index == FrameSize());
  ASSERT(deopt_instr != nullptr);
  instructions_.Add(deopt_instr);
}

void DeoptInfoBuilder::AddCallerFp(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone()) DeoptCallerFpInstr());
}

void DeoptInfoBuilder::AddCallerPp(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone()) DeoptCallerPpInstr());
}

void DeoptInfoBuilder::AddCallerPc(intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  instructions_.Add(new (zone()) DeoptCallerPcInstr());
}

void DeoptInfoBuilder::AddConstant(const Object& obj, intptr_t dest_index) {
  ASSERT(dest_index == FrameSize());
  intptr_t object_table_index = FindOrAddObjectInTable(obj);
  instructions_.Add(new (zone()) DeoptConstantInstr(object_table_index));
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

  instructions_.Add(new (zone()) DeoptMaterializeObjectInstr(non_null_fields));

  for (intptr_t i = 0; i < mat->InputCount(); i++) {
    MaterializeObjectInstr* nested_mat =
        mat->InputAt(i)->definition()->AsMaterializeObject();
    if (nested_mat != nullptr) {
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
    AddConstant(Smi::ZoneHandle(Smi::New(mat->length_or_shape())),
                dest_index++);
    for (intptr_t i = 0; i < mat->InputCount(); i++) {
      if (!mat->InputAt(i)->BindsToConstantNull()) {
        // Emit offset-value pair.
        AddConstant(Smi::ZoneHandle(Smi::New(mat->FieldOffsetAt(i))),
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

TypedDataPtr DeoptInfoBuilder::CreateDeoptInfo(const Array& deopt_table) {
  intptr_t length = instructions_.length();

  // Count the number of instructions that are a shared suffix of some deopt
  // info already written.
  TrieNode* suffix = trie_root_;
  intptr_t suffix_length = 0;
  if (FLAG_compress_deopt_info) {
    for (intptr_t i = length - 1; i >= 0; --i) {
      TrieNode* node = suffix->FindChild(*instructions_[i]);
      if (node == nullptr) break;
      suffix = node;
      ++suffix_length;
    }
  }

  // Allocate space for the translation.  If the shared suffix is longer
  // than one instruction, we replace it with a single suffix instruction.
  const bool use_suffix = suffix_length > 1;
  if (use_suffix) {
    length -= (suffix_length - 1);
  }

  typedef ZoneWriteStream::Raw<sizeof(intptr_t), intptr_t> Writer;
  ZoneWriteStream stream(zone(), 2 * length * kWordSize);

  Writer::Write(&stream, FrameSize());

  if (use_suffix) {
    Writer::Write(&stream, suffix_length);
    Writer::Write(&stream, suffix->info_number());
  } else {
    Writer::Write(&stream, 0);
  }

  // Write the unshared instructions and build their sub-tree.
  TrieNode* node = use_suffix ? suffix : trie_root_;
  const intptr_t write_count = use_suffix ? length - 1 : length;
  for (intptr_t i = write_count - 1; i >= 0; --i) {
    DeoptInstr* instr = instructions_[i];
    Writer::Write(&stream, instr->kind());
    Writer::Write(&stream, instr->source_index());

    TrieNode* child = new (zone()) TrieNode(instr, current_info_number_);
    node->AddChild(child);
    node = child;
  }

  const TypedData& deopt_info = TypedData::Handle(
      zone(), TypedData::New(kTypedDataUint8ArrayCid, stream.bytes_written(),
                             Heap::kOld));
  {
    NoSafepointScope no_safepoint;
    memmove(deopt_info.DataAddr(0), stream.buffer(), stream.bytes_written());
  }

  ASSERT(
      DeoptInfo::VerifyDecompression(instructions_, deopt_table, deopt_info));
  instructions_.Clear();
  materializations_.Clear();
  frame_start_ = -1;

  ++current_info_number_;
  return deopt_info.ptr();
}

intptr_t DeoptTable::SizeFor(intptr_t length) {
  return length * kEntrySize;
}

void DeoptTable::SetEntry(const Array& table,
                          intptr_t index,
                          const Smi& offset,
                          const TypedData& info,
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
                          TypedData* info,
                          Smi* reason) {
  intptr_t i = index * kEntrySize;
  *offset ^= table.At(i);
  *info ^= table.At(i + 1);
  *reason ^= table.At(i + 2);
}

intptr_t DeoptInfo::FrameSize(const TypedData& packed) {
  NoSafepointScope no_safepoint;
  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  ReadStream read_stream(reinterpret_cast<uint8_t*>(packed.DataAddr(0)),
                         packed.LengthInBytes());
  return Reader::Read(&read_stream);
}

intptr_t DeoptInfo::NumMaterializations(
    const GrowableArray<DeoptInstr*>& unpacked) {
  intptr_t num = 0;
  while (unpacked[num]->kind() == DeoptInstr::kMaterializeObject) {
    num++;
  }
  return num;
}

void DeoptInfo::UnpackInto(const Array& table,
                           const TypedData& packed,
                           GrowableArray<DeoptInstr*>* unpacked,
                           intptr_t length) {
  NoSafepointScope no_safepoint;
  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  ReadStream read_stream(reinterpret_cast<uint8_t*>(packed.DataAddr(0)),
                         packed.LengthInBytes());
  const intptr_t frame_size = Reader::Read(&read_stream);  // Skip frame size.
  USE(frame_size);

  const intptr_t suffix_length = Reader::Read(&read_stream);
  if (suffix_length != 0) {
    ASSERT(suffix_length > 1);
    const intptr_t info_number = Reader::Read(&read_stream);

    TypedData& suffix = TypedData::Handle();
    Smi& offset = Smi::Handle();
    Smi& reason_and_flags = Smi::Handle();
    DeoptTable::GetEntry(table, info_number, &offset, &suffix,
                         &reason_and_flags);
    UnpackInto(table, suffix, unpacked, suffix_length);
  }

  while ((read_stream.PendingBytes() > 0) && (unpacked->length() < length)) {
    const intptr_t instruction = Reader::Read(&read_stream);
    const intptr_t from_index = Reader::Read(&read_stream);
    unpacked->Add(DeoptInstr::Create(instruction, from_index));
  }
}

void DeoptInfo::Unpack(const Array& table,
                       const TypedData& packed,
                       GrowableArray<DeoptInstr*>* unpacked) {
  ASSERT(unpacked->is_empty());

  // Pass kMaxInt32 as the length to unpack all instructions from the
  // packed stream.
  UnpackInto(table, packed, unpacked, kMaxInt32);

  unpacked->Reverse();
}

const char* DeoptInfo::ToCString(const Array& deopt_table,
                                 const TypedData& packed) {
#define FORMAT "[%s]"
  GrowableArray<DeoptInstr*> deopt_instrs;
  Unpack(deopt_table, packed, &deopt_instrs);

  // Compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  for (intptr_t i = 0; i < deopt_instrs.length(); i++) {
    len += Utils::SNPrint(nullptr, 0, FORMAT, deopt_instrs[i]->ToCString());
  }

  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);

  // Layout the fields in the buffer.
  intptr_t index = 0;
  for (intptr_t i = 0; i < deopt_instrs.length(); i++) {
    index += Utils::SNPrint((buffer + index), (len - index), FORMAT,
                            deopt_instrs[i]->ToCString());
  }

  return buffer;
#undef FORMAT
}

// Returns a bool so it can be asserted.
bool DeoptInfo::VerifyDecompression(const GrowableArray<DeoptInstr*>& original,
                                    const Array& deopt_table,
                                    const TypedData& packed) {
  GrowableArray<DeoptInstr*> unpacked;
  Unpack(deopt_table, packed, &unpacked);
  ASSERT(unpacked.length() == original.length());
  for (intptr_t i = 0; i < unpacked.length(); ++i) {
    ASSERT(unpacked[i]->Equals(*original[i]));
  }
  return true;
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

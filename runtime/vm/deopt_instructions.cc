// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/deopt_instructions.h"

#include "vm/assembler_macros.h"
#include "vm/code_patcher.h"
#include "vm/intermediate_language.h"
#include "vm/locations.h"
#include "vm/parser.h"

namespace dart {

DEFINE_FLAG(bool, compress_deopt_info, true,
            "Compress the size of the deoptimization info for optimized code.");

DeoptimizationContext::DeoptimizationContext(intptr_t* to_frame_start,
                                             intptr_t to_frame_size,
                                             const Array& object_table,
                                             intptr_t num_args,
                                             DeoptReasonId deopt_reason)
    : object_table_(object_table),
      to_frame_(to_frame_start),
      to_frame_size_(to_frame_size),
      from_frame_(NULL),
      from_frame_size_(0),
      registers_copy_(NULL),
      xmm_registers_copy_(NULL),
      num_args_(num_args),
      deopt_reason_(deopt_reason),
      isolate_(Isolate::Current()) {
  from_frame_ = isolate_->deopt_frame_copy();
  from_frame_size_ = isolate_->deopt_frame_copy_size();
  registers_copy_ = isolate_->deopt_cpu_registers_copy();
  xmm_registers_copy_ = isolate_->deopt_xmm_registers_copy();
  caller_fp_ = GetFromFp();
}


intptr_t DeoptimizationContext::GetFromFp() const {
  return from_frame_[from_frame_size_ - 1 - num_args_ - 1];
}


intptr_t DeoptimizationContext::GetFromPc() const {
  return from_frame_[from_frame_size_ - 1 - num_args_];
}

intptr_t DeoptimizationContext::GetCallerFp() const {
  return caller_fp_;
}

void DeoptimizationContext::SetCallerFp(intptr_t caller_fp) {
  caller_fp_ = caller_fp;
}

// Deoptimization instruction moving value from optimized frame at
// 'from_index' to specified slots in the unoptimized frame.
// 'from_index' represents the slot index of the frame (0 being first argument)
// and accounts for saved return address, frame pointer and pc marker.
class DeoptStackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptStackSlotInstr(intptr_t from_index)
      : stack_slot_index_(from_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t from_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kStackSlot; }

  virtual const char* ToCString() const {
    const char* format = "s%"Pd"";
    intptr_t len = OS::SNPrint(NULL, 0, format, stack_slot_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, stack_slot_index_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t from_index =
       deopt_context->from_frame_size() - stack_slot_index_ - 1;
    intptr_t* from_addr = deopt_context->GetFromFrameAddressAt(from_index);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = *from_addr;
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptStackSlotInstr);
};


class DeoptDoubleStackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptDoubleStackSlotInstr(intptr_t from_index)
      : stack_slot_index_(from_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t from_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kDoubleStackSlot; }

  virtual const char* ToCString() const {
    const char* format = "ds%"Pd"";
    intptr_t len = OS::SNPrint(NULL, 0, format, stack_slot_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, stack_slot_index_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t from_index =
       deopt_context->from_frame_size() - stack_slot_index_ - 1;
    double* from_addr = reinterpret_cast<double*>(
        deopt_context->GetFromFrameAddressAt(from_index));
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *reinterpret_cast<RawSmi**>(to_addr) = Smi::New(0);
    Isolate::Current()->DeferDoubleMaterialization(
        *from_addr, reinterpret_cast<RawDouble**>(to_addr));
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptDoubleStackSlotInstr);
};


class DeoptInt64StackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptInt64StackSlotInstr(intptr_t from_index)
      : stack_slot_index_(from_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t from_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kInt64StackSlot; }

  virtual const char* ToCString() const {
    const char* format = "ms%"Pd"";
    intptr_t len = OS::SNPrint(NULL, 0, format, stack_slot_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, stack_slot_index_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t from_index =
       deopt_context->from_frame_size() - stack_slot_index_ - 1;
    int64_t* from_addr = reinterpret_cast<int64_t*>(
        deopt_context->GetFromFrameAddressAt(from_index));
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *reinterpret_cast<RawSmi**>(to_addr) = Smi::New(0);
    if (Smi::IsValid64(*from_addr)) {
      *to_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(*from_addr)));
    } else {
      Isolate::Current()->DeferMintMaterialization(
          *from_addr, reinterpret_cast<RawMint**>(to_addr));
    }
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptInt64StackSlotInstr);
};


// Deoptimization instruction creating return address using function and
// deopt-id stored at 'object_table_index'. Uses the deopt-after
// continuation point.
class DeoptRetAfterAddressInstr : public DeoptInstr {
 public:
  DeoptRetAfterAddressInstr(intptr_t object_table_index, intptr_t deopt_id)
      : object_table_index_(object_table_index), deopt_id_(deopt_id) {
    ASSERT(object_table_index >= 0);
    ASSERT(deopt_id >= 0);
  }

  explicit DeoptRetAfterAddressInstr(intptr_t from_index)
      : object_table_index_(ObjectTableIndex::decode(from_index)),
        deopt_id_(DeoptId::decode(from_index)) {
  }

  virtual intptr_t from_index() const {
    return ObjectTableIndex::encode(object_table_index_) |
        DeoptId::encode(deopt_id_);
  }
  virtual DeoptInstr::Kind kind() const { return kRetAfterAddress; }

  virtual const char* ToCString() const {
    const char* format = "ret aft oti:%"Pd"(%"Pd")";
    intptr_t len = OS::SNPrint(NULL, 0, format, object_table_index_, deopt_id_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, object_table_index_, deopt_id_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    Function& function = Function::Handle(deopt_context->isolate());
    function ^= deopt_context->ObjectAt(object_table_index_);
    const Code& code =
        Code::Handle(deopt_context->isolate(), function.unoptimized_code());
    uword continue_at_pc = code.GetDeoptAfterPcAtDeoptId(deopt_id_);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = continue_at_pc;
  }

 private:
  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class ObjectTableIndex : public BitField<intptr_t, 0, kFieldWidth> { };
  class DeoptId : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };

  const intptr_t object_table_index_;
  const intptr_t deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRetAfterAddressInstr);
};


// Deoptimization instruction creating return address using function and
// deopt-id stored at 'object_table_index'. Uses the deopt-before
// continuation point.
class DeoptRetBeforeAddressInstr : public DeoptInstr {
 public:
  DeoptRetBeforeAddressInstr(intptr_t object_table_index, intptr_t deopt_id)
      : object_table_index_(object_table_index), deopt_id_(deopt_id) {
    ASSERT(object_table_index >= 0);
    ASSERT(deopt_id >= 0);
  }

  explicit DeoptRetBeforeAddressInstr(intptr_t from_index)
      : object_table_index_(ObjectTableIndex::decode(from_index)),
        deopt_id_(DeoptId::decode(from_index)) {
  }

  virtual intptr_t from_index() const {
    return ObjectTableIndex::encode(object_table_index_) |
        DeoptId::encode(deopt_id_);
  }
  virtual DeoptInstr::Kind kind() const { return kRetBeforeAddress; }

  virtual const char* ToCString() const {
    const char* format = "ret bef oti:%"Pd"(%"Pd")";
    intptr_t len = OS::SNPrint(NULL, 0, format, object_table_index_, deopt_id_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, object_table_index_, deopt_id_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    Function& function = Function::Handle(deopt_context->isolate());
    function ^= deopt_context->ObjectAt(object_table_index_);
    const Code& code =
        Code::Handle(deopt_context->isolate(), function.unoptimized_code());
    uword continue_at_pc = code.GetDeoptBeforePcAtDeoptId(deopt_id_);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = continue_at_pc;


    uword pc = code.GetPcForDeoptId(deopt_id_, PcDescriptors::kIcCall);
    if (pc != 0) {
      // If the deoptimization happened at an IC call, update the IC data
      // to avoid repeated deoptimization at the same site next time around.
      const ICData& ic_data = ICData::Handle(
          CodePatcher::GetInstanceCallIcDataAt(pc));
      if (!ic_data.IsNull()) {
        ic_data.set_deopt_reason(deopt_context->deopt_reason());
      }
    }
  }

 private:
  static const intptr_t kFieldWidth = kBitsPerWord / 2;
  class ObjectTableIndex : public BitField<intptr_t, 0, kFieldWidth> { };
  class DeoptId : public BitField<intptr_t, kFieldWidth, kFieldWidth> { };

  const intptr_t object_table_index_;
  const intptr_t deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRetBeforeAddressInstr);
};


// Deoptimization instruction moving a constant stored at 'object_table_index'.
class DeoptConstantInstr : public DeoptInstr {
 public:
  explicit DeoptConstantInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t from_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kConstant; }

  virtual const char* ToCString() const {
    const char* format = "const oti:%"Pd"";
    intptr_t len = OS::SNPrint(NULL, 0, format, object_table_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, object_table_index_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    const Object& obj = Object::Handle(
        deopt_context->isolate(), deopt_context->ObjectAt(object_table_index_));
    RawObject** to_addr = reinterpret_cast<RawObject**>(
        deopt_context->GetToFrameAddressAt(to_index));
    *to_addr = obj.raw();
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

  virtual intptr_t from_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kRegister; }

  virtual const char* ToCString() const {
    return Assembler::RegisterName(reg_);
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t value = deopt_context->RegisterValue(reg_);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = value;
  }

 private:
  const Register reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRegisterInstr);
};


// Deoptimization instruction moving an XMM register.
class DeoptXmmRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptXmmRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<XmmRegister>(reg_as_int)) {}

  virtual intptr_t from_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kXmmRegister; }

  virtual const char* ToCString() const {
    return Assembler::XmmRegisterName(reg_);
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    double value = deopt_context->XmmRegisterValue(reg_);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *reinterpret_cast<RawSmi**>(to_addr) = Smi::New(0);
    Isolate::Current()->DeferDoubleMaterialization(
        value, reinterpret_cast<RawDouble**>(to_addr));
  }

 private:
  const XmmRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptXmmRegisterInstr);
};


class DeoptInt64XmmRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptInt64XmmRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<XmmRegister>(reg_as_int)) {}

  virtual intptr_t from_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kInt64XmmRegister; }

  virtual const char* ToCString() const {
    const char* format = "%s(m)";
    intptr_t len =
        OS::SNPrint(NULL, 0, format, Assembler::XmmRegisterName(reg_));
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, Assembler::XmmRegisterName(reg_));
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    int64_t value = deopt_context->XmmRegisterValueAsInt64(reg_);
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *reinterpret_cast<RawSmi**>(to_addr) = Smi::New(0);
    if (Smi::IsValid64(value)) {
      *to_addr = reinterpret_cast<intptr_t>(
          Smi::New(static_cast<intptr_t>(value)));
    } else {
      Isolate::Current()->DeferMintMaterialization(
          value, reinterpret_cast<RawMint**>(to_addr));
    }
  }

 private:
  const XmmRegister reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptInt64XmmRegisterInstr);
};


// Deoptimization instruction creating a PC marker for the code of
// function at 'object_table_index'.
class DeoptPcMarkerInstr : public DeoptInstr {
 public:
  explicit DeoptPcMarkerInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t from_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kPcMarker; }

  virtual const char* ToCString() const {
    const char* format = "pcmark oti:%"Pd"";
    intptr_t len = OS::SNPrint(NULL, 0, format, object_table_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, object_table_index_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    Function& function = Function::Handle(deopt_context->isolate());
    function ^= deopt_context->ObjectAt(object_table_index_);
    const Code& code =
        Code::Handle(deopt_context->isolate(), function.unoptimized_code());
    ASSERT(!code.IsNull());
    intptr_t pc_marker = code.EntryPoint() +
                         AssemblerMacros::kOffsetOfSavedPCfromEntrypoint;
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = pc_marker;
    // Increment the deoptimization counter. This effectively increments each
    // function occurring in the optimized frame.
    function.set_deoptimization_counter(function.deoptimization_counter() + 1);
    // Clear invocation counter so that hopefully the function gets reoptimized
    // only after more feedback has been collected.
    function.set_usage_counter(0);
    if (function.HasOptimizedCode()) function.SwitchToUnoptimizedCode();
  }

 private:
  intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptPcMarkerInstr);
};


// Deoptimization instruction copying the caller saved FP from optimized frame.
class DeoptCallerFpInstr : public DeoptInstr {
 public:
  DeoptCallerFpInstr() {}

  virtual intptr_t from_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kCallerFp; }

  virtual const char* ToCString() const {
    return "callerfp";
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t from = deopt_context->GetCallerFp();
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = from;
    deopt_context->SetCallerFp(reinterpret_cast<intptr_t>(to_addr));
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerFpInstr);
};


// Deoptimization instruction copying the caller return address from optimized
// frame.
class DeoptCallerPcInstr : public DeoptInstr {
 public:
  DeoptCallerPcInstr() {}

  virtual intptr_t from_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kCallerPc; }

  virtual const char* ToCString() const {
    return "callerpc";
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    intptr_t from = deopt_context->GetFromPc();
    intptr_t* to_addr = deopt_context->GetToFrameAddressAt(to_index);
    *to_addr = from;
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

  explicit DeoptSuffixInstr(intptr_t from_index)
      : info_number_(InfoNumber::decode(from_index)),
        suffix_length_(SuffixLength::decode(from_index)) {
  }

  virtual intptr_t from_index() const {
    return InfoNumber::encode(info_number_) |
        SuffixLength::encode(suffix_length_);
  }
  virtual DeoptInstr::Kind kind() const { return kSuffix; }

  virtual const char* ToCString() const {
    const char* format = "suffix %"Pd":%"Pd;
    intptr_t len = OS::SNPrint(NULL, 0, format, info_number_, suffix_length_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, format, info_number_, suffix_length_);
    return chars;
  }

  void Execute(DeoptimizationContext* deopt_context, intptr_t to_index) {
    // The deoptimization info is uncompresses by translating away suffixes
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


intptr_t DeoptInstr::DecodeSuffix(intptr_t from_index, intptr_t* info_number) {
  *info_number = DeoptSuffixInstr::InfoNumber::decode(from_index);
  return DeoptSuffixInstr::SuffixLength::decode(from_index);
}


DeoptInstr* DeoptInstr::Create(intptr_t kind_as_int, intptr_t from_index) {
  Kind kind = static_cast<Kind>(kind_as_int);
  switch (kind) {
    case kStackSlot: return new DeoptStackSlotInstr(from_index);
    case kDoubleStackSlot: return new DeoptDoubleStackSlotInstr(from_index);
    case kInt64StackSlot: return new DeoptInt64StackSlotInstr(from_index);
    case kRetAfterAddress: return new DeoptRetAfterAddressInstr(from_index);
    case kRetBeforeAddress: return new DeoptRetBeforeAddressInstr(from_index);
    case kConstant: return new DeoptConstantInstr(from_index);
    case kRegister: return new DeoptRegisterInstr(from_index);
    case kXmmRegister: return new DeoptXmmRegisterInstr(from_index);
    case kInt64XmmRegister: return new DeoptInt64XmmRegisterInstr(from_index);
    case kPcMarker: return new DeoptPcMarkerInstr(from_index);
    case kCallerFp: return new DeoptCallerFpInstr();
    case kCallerPc: return new DeoptCallerPcInstr();
    case kSuffix: return new DeoptSuffixInstr(from_index);
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


DeoptInfoBuilder::DeoptInfoBuilder(const intptr_t num_args)
    : instructions_(),
      object_table_(GrowableObjectArray::Handle(GrowableObjectArray::New())),
      num_args_(num_args),
      trie_root_(new TrieNode()),
      current_info_number_(0) {
}


intptr_t DeoptInfoBuilder::FindOrAddObjectInTable(const Object& obj) const {
  for (intptr_t i = 0; i < object_table_.Length(); i++) {
    if (object_table_.At(i) == obj.raw()) {
      return i;
    }
  }
  // Add object.
  const intptr_t result = object_table_.Length();
  object_table_.Add(obj);
  return result;
}


void DeoptInfoBuilder::AddReturnAddressBefore(const Function& function,
                                              intptr_t deopt_id,
                                              intptr_t to_index) {
  const intptr_t object_table_index = FindOrAddObjectInTable(function);
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptRetBeforeAddressInstr(object_table_index,
                                                   deopt_id));
}


void DeoptInfoBuilder::AddReturnAddressAfter(const Function& function,
                                             intptr_t deopt_id,
                                             intptr_t to_index) {
  const intptr_t object_table_index = FindOrAddObjectInTable(function);
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptRetAfterAddressInstr(object_table_index,
                                                  deopt_id));
}


void DeoptInfoBuilder::AddPcMarker(const Function& function,
                                   intptr_t to_index) {
  // Function object was already added by AddReturnAddress, find it.
  intptr_t from_index = FindOrAddObjectInTable(function);
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptPcMarkerInstr(from_index));
}


void DeoptInfoBuilder::AddCopy(const Location& from_loc,
                               const Value& from_value,
                               const intptr_t to_index) {
  DeoptInstr* deopt_instr = NULL;
  if (from_loc.IsConstant()) {
    intptr_t object_table_index = FindOrAddObjectInTable(from_loc.constant());
    deopt_instr = new DeoptConstantInstr(object_table_index);
  } else if (from_loc.IsRegister()) {
    deopt_instr = new DeoptRegisterInstr(from_loc.reg());
  } else if (from_loc.IsXmmRegister()) {
    if (from_loc.representation() == Location::kDouble) {
      deopt_instr = new DeoptXmmRegisterInstr(from_loc.xmm_reg());
    } else {
      ASSERT(from_loc.representation() == Location::kMint);
      deopt_instr = new DeoptInt64XmmRegisterInstr(from_loc.xmm_reg());
    }
  } else if (from_loc.IsStackSlot()) {
    intptr_t from_index = (from_loc.stack_index() < 0) ?
        from_loc.stack_index() + num_args_ :
        from_loc.stack_index() + num_args_ -
            ParsedFunction::kFirstLocalSlotIndex + 1;
    deopt_instr = new DeoptStackSlotInstr(from_index);
  } else if (from_loc.IsDoubleStackSlot()) {
    intptr_t from_index = (from_loc.stack_index() < 0) ?
        from_loc.stack_index() + num_args_ :
        from_loc.stack_index() + num_args_ -
            ParsedFunction::kFirstLocalSlotIndex + 1;
    if (from_loc.representation() == Location::kDouble) {
      deopt_instr = new DeoptDoubleStackSlotInstr(from_index);
    } else {
      ASSERT(from_loc.representation() == Location::kMint);
      deopt_instr = new DeoptInt64StackSlotInstr(from_index);
    }
  } else {
    UNREACHABLE();
  }
  ASSERT(to_index == instructions_.length());
  instructions_.Add(deopt_instr);
}


void DeoptInfoBuilder::AddCallerFp(intptr_t to_index) {
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptCallerFpInstr());
}


void DeoptInfoBuilder::AddCallerPc(intptr_t to_index) {
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptCallerPcInstr());
}


RawDeoptInfo* DeoptInfoBuilder::CreateDeoptInfo() {
  intptr_t length = instructions_.length();

  // Count the number of instructions that are a shared suffix of some deopt
  // info already written.
  TrieNode* suffix = trie_root_;
  intptr_t suffix_length = 0;
  if (FLAG_compress_deopt_info) {
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
  const DeoptInfo& deopt_info = DeoptInfo::Handle(DeoptInfo::New(length));

  // Write the unshared instructions and build their sub-tree.
  TrieNode* node = NULL;
  intptr_t write_count = (suffix_length > 1) ? length - 1 : length;
  for (intptr_t i = 0; i < write_count; ++i) {
    DeoptInstr* instr = instructions_[i];
    deopt_info.SetAt(i, instr->kind(), instr->from_index());
    TrieNode* child = node;
    node = new TrieNode(instr, current_info_number_);
    node->AddChild(child);
  }
  suffix->AddChild(node);

  if (suffix_length > 1) {
    DeoptInstr* instr =
        new DeoptSuffixInstr(suffix->info_number(), suffix_length);
    deopt_info.SetAt(length - 1, instr->kind(), instr->from_index());
  }

  instructions_.Clear();
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

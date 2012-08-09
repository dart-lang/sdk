// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/deopt_instructions.h"

#include "vm/intermediate_language.h"
#include "vm/locations.h"
#include "vm/parser.h"

namespace dart {

// Deoptimization instruction moving value from optimized frame at
// 'from_index' to specified slots in the unoptimized frame.
// 'from_index' represents the local count >= 0, first
// argument being 0.
class DeoptStackSlotInstr : public DeoptInstr {
 public:
  explicit DeoptStackSlotInstr(intptr_t from_index)
      : stack_slot_index_(from_index) {
    ASSERT(stack_slot_index_ >= 0);
  }

  virtual intptr_t from_index() const { return stack_slot_index_; }
  virtual DeoptInstr::Kind kind() const { return kCopyStackSlot; }

  virtual const char* ToCString() const {
    intptr_t len = OS::SNPrint(NULL, 0, "s%d", stack_slot_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, "s%d", stack_slot_index_);
    return chars;
  }

 private:
  const intptr_t stack_slot_index_;  // First argument is 0, always >= 0.

  DISALLOW_COPY_AND_ASSIGN(DeoptStackSlotInstr);
};


// Deoptimization instruction creating return address using function and
// deopt-id stored at 'object_table_index'.
class DeoptRetAddrInstr : public DeoptInstr {
 public:
  explicit DeoptRetAddrInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t from_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kSetRetAddress; }

  virtual const char* ToCString() const {
    intptr_t len = OS::SNPrint(NULL, 0, "ret oti:%d", object_table_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, "ret oti:%d", object_table_index_);
    return chars;
  }

 private:
  const intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRetAddrInstr);
};


// Deoptimization instruction moving a constant stored at 'object_table_index'.
class DeoptConstantInstr : public DeoptInstr {
 public:
  explicit DeoptConstantInstr(intptr_t object_table_index)
      : object_table_index_(object_table_index) {
    ASSERT(object_table_index >= 0);
  }

  virtual intptr_t from_index() const { return object_table_index_; }
  virtual DeoptInstr::Kind kind() const { return kCopyConstant; }

  virtual const char* ToCString() const {
    intptr_t len = OS::SNPrint(NULL, 0, "const oti:%d", object_table_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, "const oti:%d", object_table_index_);
    return chars;
  }

 private:
  const intptr_t object_table_index_;

  DISALLOW_COPY_AND_ASSIGN(DeoptConstantInstr);
};


// Deoptimization instruction moving a register.
class DeoptRegisterInstr: public DeoptInstr {
 public:
  explicit DeoptRegisterInstr(intptr_t reg_as_int)
      : reg_(static_cast<Register>(reg_as_int)) {}

  virtual intptr_t from_index() const { return static_cast<intptr_t>(reg_); }
  virtual DeoptInstr::Kind kind() const { return kCopyRegister; }

  virtual const char* ToCString() const {
    return Assembler::RegisterName(reg_);
  }

 private:
  const Register reg_;

  DISALLOW_COPY_AND_ASSIGN(DeoptRegisterInstr);
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
  virtual DeoptInstr::Kind kind() const { return kSetPcMarker; }

  virtual const char* ToCString() const {
    intptr_t len = OS::SNPrint(NULL, 0, "pcmark oti:%d", object_table_index_);
    char* chars = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(chars, len + 1, "pcmark oti:%d", object_table_index_);
    return chars;
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
  virtual DeoptInstr::Kind kind() const { return kSetCallerFp; }

  virtual const char* ToCString() const { return "callerfp"; }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerFpInstr);
};


// Deoptimization instruction copying the caller return address from optimzied
// frame.
class DeoptCallerPcInstr : public DeoptInstr {
 public:
  DeoptCallerPcInstr() {}

  virtual intptr_t from_index() const { return 0; }
  virtual DeoptInstr::Kind kind() const { return kSetCallerPc; }

  virtual const char* ToCString() const { return "callerpc"; }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptCallerPcInstr);
};


DeoptInstr* DeoptInstr::Create(intptr_t kind_as_int, intptr_t from_index) {
  Kind kind = static_cast<Kind>(kind_as_int);
  switch (kind) {
    case kCopyStackSlot: return new DeoptStackSlotInstr(from_index);
    case kSetRetAddress: return new DeoptRetAddrInstr(from_index);
    case kCopyConstant:  return new DeoptConstantInstr(from_index);
    case kCopyRegister:  return new DeoptRegisterInstr(from_index);
    case kSetPcMarker:   return new DeoptPcMarkerInstr(from_index);
    case kSetCallerFp:   return new DeoptCallerFpInstr();
    case kSetCallerPc:   return new DeoptCallerPcInstr();
  }
  UNREACHABLE();
  return NULL;
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


// Will be neeeded for inlined functions, currently trivial.
void DeoptInfoBuilder::AddReturnAddress(const Function& function,
                                        intptr_t deopt_id,
                                        intptr_t to_index) {
  const intptr_t object_table_index = object_table_.Length();
  object_table_.Add(function);
  object_table_.Add(Smi::ZoneHandle(Smi::New(deopt_id)));
  ASSERT(to_index == instructions_.length());
  instructions_.Add(new DeoptRetAddrInstr(object_table_index));
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
  } else if (from_loc.IsStackSlot()) {
    deopt_instr = new DeoptStackSlotInstr(from_loc.stack_index() + num_args_);
  } else if (from_loc.IsInvalid()) {
    ASSERT(from_value.IsConstant());
    const Object& obj = from_value.AsConstant()->value();
    intptr_t object_table_index = FindOrAddObjectInTable(obj);
    deopt_instr = new DeoptConstantInstr(object_table_index);
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


RawDeoptInfo* DeoptInfoBuilder::CreateDeoptInfo() const {
  const intptr_t len = instructions_.length();
  const DeoptInfo& deopt_info = DeoptInfo::Handle(DeoptInfo::New(len));
  for (intptr_t i = 0; i < len; i++) {
    DeoptInstr* instr = instructions_[i];
    deopt_info.SetAt(i, instr->kind(), instr->from_index());
  }
  return deopt_info.raw();
}

}  // namespace dart

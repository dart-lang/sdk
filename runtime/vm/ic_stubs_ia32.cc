// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/ic_stubs.h"

#include "vm/assembler.h"
#include "vm/code_index_table.h"
#include "vm/disassembler.h"
#include "vm/flags.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, disassemble_stubs);
DEFINE_FLAG(bool, enable_polymorphic_ic, true,
    "Enable polymorphic inline caching");
DEFINE_FLAG(bool, trace_icstub_generation, false,
    "Print every generated IC stub");


// TODO(srdjan): Move FindInCode and AppendICStubToTargets into the shared file.

// Add 'classes' and 'ic_stub' to all 'targets'. Each target's code
// (class RawCode) has an array of (classes-array, ic_stub) pairs.
void ICStubs::AppendICStubToTargets(
    const GrowableArray<const Function*>& targets,
    const GrowableArray<const Class*>& classes,
    const Code& ic_stub) {
  if (FLAG_trace_icstub_generation) {
    OS::Print("Appending ICstub 0x%x to targets:\n", ic_stub.EntryPoint());
  }
  Code& target = Code::Handle();
  Array& class_ic_stubs_array = Array::Handle();
  Code& test_ic_stub = Code::Handle();
  for (intptr_t i = 0; i < targets.length(); i++) {
    target = Code::Handle(targets[i]->code()).raw();
    if (FLAG_trace_icstub_generation) {
      OS::Print(" * code 0x%x\n", target.EntryPoint());
    }
    // Do not add twice: two different classes may have the same target.
    test_ic_stub = ICStubs::FindInCode(target, classes);
    if (test_ic_stub.IsNull()) {
      // Append one class/ic-stub pair entry.
      // Grow the array by two (one pair).
      class_ic_stubs_array = target.class_ic_stubs();
      intptr_t new_length = class_ic_stubs_array.Length() + 2;
      class_ic_stubs_array = Array::Grow(class_ic_stubs_array, new_length);
      target.set_class_ic_stubs(class_ic_stubs_array);
      // Create classes array out of GrowableArray classes.
      Array& a = Array::Handle(Array::New(classes.length()));
      for (intptr_t i = 0; i < classes.length(); i++) {
        a.SetAt(i, *classes[i]);
      }
      class_ic_stubs_array.SetAt(new_length - 2, a);
      class_ic_stubs_array.SetAt(new_length - 1, ic_stub);
      if (FLAG_trace_icstub_generation) {
        OS::Print("   + icstub 0x%x\n", ic_stub.EntryPoint());
      }
    } else {
      if (FLAG_trace_icstub_generation) {
        OS::Print("   . icstub 0x%x\n", test_ic_stub.EntryPoint());
      }
    }
  }
}


// Return true if class 'test' is contained in array 'classes'.
static bool IsClassInArray(const Class& test,
                           const GrowableArray<const Class*>& classes) {
  for (intptr_t i = 0; i < classes.length(); i++) {
    if (classes[i]->raw() == test.raw()) {
      return true;
    }
  }
  return false;
}


// Linear search for the ic stub with given 'classes'. RawCode::class_ic_stubs()
// returns an array of (classes-array, ic-stub-code) pairs. Returns
// RawCode::null() if no stub is found.
RawCode* ICStubs::FindInCode(const Code& target,
                             const GrowableArray<const Class*>& classes) {
  Code& result = Code::Handle();
  if (classes.is_empty()) {
    return result.raw();  // RawCode::null().
  }
  Array& class_ic_stubs = Array::Handle(target.class_ic_stubs());
  const intptr_t len = class_ic_stubs.Length();
  Array& array = Array::Handle();
  Class& cls = Class::Handle();
  // Iterate over all stored IC stubs/array classes pairs until match found.
  for (intptr_t i = 0; i < len; i += 2) {
    // i: array of classes, i + 1: ic stub code.
    array ^= class_ic_stubs.At(i);
    if (array.Length() == classes.length()) {
      bool classes_match = true;
      for (intptr_t k = 0; k < array.Length(); k++) {
        cls ^= array.At(k);
        if (!IsClassInArray(cls, classes)) {
          classes_match = false;
          break;
        }
      }
      if (classes_match) {
        // Found matching stub.
        result ^= class_ic_stubs.At(i + 1);
        break;
      }
    }
  }
  // If no matching stub is found, result.raw() returns null.
  return result.raw();
}


int ICStubs::IndexOfClass(const GrowableArray<const Class*>& classes,
                          const Class& cls) {
  for (intptr_t i = 0; i < classes.length(); i++) {
    if (classes[i]->raw() == cls.raw()) {
      return i;
    }
  }
  return -1;
}


// An IC Stub starts with a Smi test, optionally followed by a null test
// and zero or more class tests. The "StubCode::CallInstanceFunction"
// corresponds to an IC stub without any classes or targets.
bool ICStubs::RecognizeICStub(uword ic_entry_point,
                              GrowableArray<const Class*>* classes,
                              GrowableArray<const Function*>* targets) {
  if (ic_entry_point == StubCode::CallInstanceFunctionLabel().address()) {
    // Unresolved instance call, no classes collected yet.
    return true;
  }
  if (ic_entry_point == StubCode::MegamorphicLookupEntryPoint()) {
    // NoSuchMethod call, no classes collected.
    return true;
  }
  return ParseICStub(ic_entry_point, classes, targets, 0, 0);
}


void ICStubs::PatchTargets(uword ic_entry_point, uword from, uword to) {
  bool is_ok = ParseICStub(ic_entry_point, NULL, NULL, from, to);
  ASSERT(is_ok);
}


// Parse IC stub, collect 'classes' and 'targets' and patches
// all 'from' targets with 'to' targets. No collection occurs
// if 'classes' and 'targets' are NULL, no patching occurs if
// 'from' or 'to' is 0.
// The IC structure is defined in IcStubs::GetIcStub.
bool ICStubs::ParseICStub(uword ic_entry_point,
                          GrowableArray<const Class*>* classes,
                          GrowableArray<const Function*>* targets,
                          uword from,
                          uword to) {
  uword instruction_address = ic_entry_point;
  bool patch_code = (from != 0) && (to != 0);
  if (classes != NULL) {
    classes->Clear();
  }
  if (targets != NULL) {
    targets->Clear();
  }

  // Part A: Load receiver, test if Smi, jump to IC miss or hit.
  ICLoadReceiver load_receiver(instruction_address);
  if (!load_receiver.IsValid()) {
    return false;  // Not an an IC stub.
  }
  instruction_address += load_receiver.pattern_length_in_bytes();

  TestEaxIsSmi test_smi(instruction_address);
  // The target of the Smi test determines if the test should cause
  // IC miss if successful or jump to target (IC hit). Target of IC miss is the
  // stub code, target of IC success is a code object.
  CodeIndexTable* ci_table = Isolate::Current()->code_index_table();
  ASSERT(ci_table != NULL);

  Instructions& inst = Instructions::Handle(
      Instructions::FromEntryPoint(ic_entry_point));
  ASSERT(!inst.IsNull());

  if (!StubCode::InCallInstanceFunctionStubCode(test_smi.TargetAddress())) {
    // Jump is an IC success.
    if (patch_code && (test_smi.TargetAddress() == from)) {
      test_smi.SetTargetAddress(to);
    }
    const Class& smi_class =
        Class::ZoneHandle(Isolate::Current()->object_store()->smi_class());
    const Code& smi_code =
        Code::Handle(ci_table->LookupCode(test_smi.TargetAddress()));
    ASSERT(!smi_class.IsNullClass());
    ASSERT(!smi_code.IsNull());
    if (classes != NULL) {
      classes->Add(&smi_class);
    }
    if (targets != NULL) {
      targets->Add(&Function::ZoneHandle(smi_code.function()));
    }
  }
  instruction_address += test_smi.pattern_length_in_bytes();

  // TODO(srdjan): Add checks that the IC stub ends with
  // a null check and a jmp.
  // Part B: Load receiver's class, compare with all known classes.
  LoadObjectClass load_object_class(instruction_address);
  if (!load_object_class.IsValid()) {
    return false;
  }
  instruction_address += load_object_class.pattern_length_in_bytes();
  while (true) {
    ICCheckReceiverClass check_class(instruction_address);
    if (!check_class.IsValid()) {
      // Done parsing.
      return true;
    }
    if (patch_code && (check_class.TargetAddress() == from)) {
      check_class.SetTargetAddress(to);
    }
    const Class& cls = Class::ZoneHandle(check_class.TestClass());
    const Code& code = Code::ZoneHandle(
        ci_table->LookupCode(check_class.TargetAddress()));
    ASSERT(!cls.IsNullClass());
    ASSERT(!code.IsNull());
    if (classes != NULL) {
      classes->Add(&cls);
    }
    if (targets != NULL) {
      targets->Add(&Function::ZoneHandle(code.function()));
    }
    instruction_address += check_class.pattern_length_in_bytes();
  }
}


// Generate inline cache stub for given targets and classes.
//  EDX: arguments descriptor array (preserved).
//  ECX: function name (unused, preserved).
//  TOS: return address.
// Jump to target if the receiver's class matches the 'receiver_class'.
// Otherwise jump to megamorphic lookup. TODO(srdjan): Patch call site to go to
// megamorphic instead of going via the IC stub.
// IC stub structure:
//   A: Get receiver, test if Smi, jump to IC miss or hit.
//   B: Get receiver's class, compare with all known classes.
RawCode* ICStubs::GetICStub(const GrowableArray<const Class*>& classes,
                            const GrowableArray<const Function*>& targets) {
  // Check if a matching IC stub already exists.
  Code& ic_stub_code = Code::Handle();
  for (intptr_t i = 0; i < targets.length(); i++) {
    ic_stub_code =
        ICStubs::FindInCode(Code::Handle(targets[i]->code()), classes);
    if (!ic_stub_code.IsNull()) {
      return ic_stub_code.raw();  // Reusing the previously created IC stub.
    }
  }

  // Call IC miss handling only if polymorphic inline caching is on, otherwise
  // continue in megamorphic lookup.
  const ExternalLabel* ic_miss_label =
      FLAG_enable_polymorphic_ic
          ? &StubCode::CallInstanceFunctionLabel()
          : &StubCode::MegamorphicLookupLabel();

#define __ assembler.
  Assembler assembler;
  // Part A: Get receiver, test if Smi.
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));  // Get receiver. EAX is a Smi.
  __ testl(EAX, Immediate(kSmiTagMask));

  const Class& smi_class = Class::Handle(
      Isolate::Current()->object_store()->smi_class());
  const int smi_class_index = IndexOfClass(classes, smi_class);
  if (smi_class_index >= 0) {
    // Smi is not IC miss.
    const Code& target = Code::Handle(targets[smi_class_index]->code());
    ExternalLabel target_label("ICtoTargetSmi", target.EntryPoint());
    // Always check for Smi first and either go to target or call ic-miss.
    __ j(ZERO, &target_label);
  } else {
    // Smi is IC miss.
    __ j(ZERO, ic_miss_label);
  }

  // Part B: Load receiver's class, compare with all known classes.
  __ movl(EBX, FieldAddress(EAX, Object::class_offset()));
  for (int cli = 0; cli < classes.length(); cli++) {
    const Class* test_class = classes[cli];
    ASSERT(!test_class->IsNullClass());
    if (test_class->raw() != smi_class.raw()) {
      const Code& target = Code::Handle(targets[cli]->code());
      ExternalLabel target_label("ICtoTargetClass", target.EntryPoint());
      __ CompareObject(EBX, *test_class);
      __ j(EQUAL, &target_label);
    }
  }
  // IC miss. If null jump to megamorphic (don't trash IC), otherwise to IC
  // miss in order to update the IC.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(EAX, raw_null);
  __ j(EQUAL, &StubCode::MegamorphicLookupLabel());

  __ jmp(ic_miss_label);
  ic_stub_code = Code::FinalizeCode("inline cache stub", &assembler);
  ICStubs::AppendICStubToTargets(targets, classes, ic_stub_code);

  if (FLAG_trace_icstub_generation) {
    OS::Print("IC Stub code generated at 0x%x: targets: %d, classes: %d\n",
        ic_stub_code.EntryPoint(), targets.length(), classes.length());
    for (intptr_t i = 0; i < targets.length(); i++) {
      OS::Print("  target: 0x%x class: %s\n",
          Code::Handle(targets[i]->code()).EntryPoint(),
          classes[i]->ToCString());
    }
  }

  if (FLAG_disassemble_stubs) {
    for (intptr_t i = 0; i < classes.length(); i++) {
      ASSERT(classes[i]->raw() != Object::null_class());
      const String& class_name = String::Handle(classes[i]->Name());
      CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
      const Code& target = Code::Handle(targets[i]->code());
      const Function& function =
          Function::Handle(
              code_index_table->LookupFunction(target.EntryPoint()));
      OS::Print("%d: Code for inline cache for class '%s' function '%s': {\n",
          i, class_name.ToCString(), function.ToFullyQualifiedCString());
    }
    Disassembler::Disassemble(ic_stub_code.EntryPoint(),
                              ic_stub_code.EntryPoint() + assembler.CodeSize());
    OS::Print("}\n");
  }

  return ic_stub_code.raw();
#undef __
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/opt_code_generator.h"

#include "vm/assembler_macros.h"
#include "vm/ast_printer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler_->

DEFINE_FLAG(bool, trace_optimization, false, "Trace optimizations.");
DECLARE_FLAG(bool, enable_type_checks);


// Property list to be used in CodeGenInfo. Each property has a setter
// and a getter of specified type and name.
// (name, type, default)
#define PROPERTY_LIST(V)                                                       \
  V(is_temp, bool, false)                                                      \
  V(allow_temp, bool, false)                                                   \
  V(true_label, Label*, NULL)                                                  \
  V(false_label, Label*, NULL)                                                 \
  V(labels_used, bool, false)                                                  \
  V(request_result_in_eax, bool, false)                                        \
  V(result_returned_in_eax, bool, false)                                       \
  V(fallthrough_label, Label*, NULL)                                           \
  V(is_class, const Class*, &Class::ZoneHandle())                              \


// Class holding information being passed from source to destination.
// Add needed properties in the PROPERTY_LIST above.
class CodeGenInfo : public ValueObject {
 public:
  explicit CodeGenInfo(AstNode* node)
      : node_(node), data_(4) {
    ASSERT(node != NULL);
    ASSERT(node->info() == NULL);
    node->set_info(this);
  }

  ~CodeGenInfo() {
    ASSERT(node_->info() == this);
    node_->set_info(NULL);
  }

  bool IsClass(const Class& cls) const {
    return is_class()->raw() == cls.raw();
  }

#define GETTER(name, type, default)                                            \
  type name() const {                                                          \
    Pair* p = Get(k_##name);                                                   \
    return p == NULL ? default : p->name;                                      \
  }
PROPERTY_LIST(GETTER)
#undef GETTER

#define SETTER(name, type, default)                                            \
  void set_##name(type value) {                                                \
    ASSERT(Get(k_##name) == NULL);                                             \
    Pair p;                                                                    \
    p.kind = k_##name;                                                         \
    p.name = value;                                                            \
    data_.Add(p);                                                              \
  }
PROPERTY_LIST(SETTER)
#undef SETTER

 private:
  enum Kind {
#define DEFINE_KIND(name, type, value) k_##name,
PROPERTY_LIST(DEFINE_KIND)
#undef DEFINE_KIND
  };
  struct Pair {
    Kind kind;
    union {
#define UNION_ELEMENTS(name, type, value) type name;
PROPERTY_LIST(UNION_ELEMENTS)
#undef UNION_ELEMENTS
    };
  };

  Pair* Get(Kind kind) const {
    for (int i = 0; i < data_.length(); i++) {
      if (data_[i].kind == kind) {
        return &data_[i];
      }
    }
    return NULL;
  }
  AstNode* node_;
  GrowableArray<Pair> data_;
  DISALLOW_COPY_AND_ASSIGN(CodeGenInfo);
};


// Code that calls the deoptimizer, emitted as deferred code (out of line).
// Specify the corresponding 'node' and the registers that need to
// be pushed for the deoptimization point in unoptimized code.
class DeoptimizationBlob : public ZoneAllocated {
 public:
  DeoptimizationBlob(AstNode* node, DeoptReasonId deopt_reason_id)
      : node_(node),
        registers_(2),
        label_(),
        deopt_reason_id_(deopt_reason_id) {}

  void Push(Register reg) { registers_.Add(reg); }

  void Generate(OptimizingCodeGenerator* codegen) {
    codegen->assembler()->Bind(&label_);
    for (int i = 0; i < registers_.length(); i++) {
      codegen->assembler()->pushl(registers_[i]);
    }
    codegen->assembler()->movl(EAX, Immediate(Smi::RawValue(deopt_reason_id_)));
    codegen->CallDeoptimize(node_->id(), node_->token_index());
#if defined(DEBUG)
    // Check that deoptimization point exists in unoptimized code.
    const Code& unoptimized_code =
        Code::Handle(codegen->parsed_function().function().unoptimized_code());
    ASSERT(!unoptimized_code.IsNull());
    uword continue_at_pc =
        unoptimized_code.GetDeoptPcAtNodeId(node_->id());
    ASSERT(continue_at_pc != 0);
#endif  // DEBUG
  }

  // Jump to this label to deoptimize.
  Label* label() { return &label_; }

 private:
  const AstNode* node_;
  GrowableArray<Register> registers_;
  Label label_;
  DeoptReasonId deopt_reason_id_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationBlob);
};

// TODO(srdjan): Add String_charCodeAt, String_hashCode.

#define RECOGNIZED_LIST(V)                                                     \
  V(ObjectArray, get:length, ObjectArrayLength)                                \
  V(GrowableObjectArray, get:length, GrowableArrayLength)                      \
  V(StringBase, get:length, StringBaseLength)                                  \
  V(IntegerImplementation, toDouble, IntegerToDouble)                          \
  V(Double, toDouble, DoubleToDouble)                                          \
  V(Math, sqrt, MathSqrt)                                                      \

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class Recognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name) k##enum_name,
RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
  };

  // TODO(srdjan): Check that the library is the coreimpl one.
  static Kind RecognizeKind(const Function& function) {
    const String& recognize_name = String::Handle(function.name());
    const String& recognize_class =
         String::Handle(Class::Handle(function.owner()).Name());
    String& test_function_name = String::Handle();
    String& test_class_name = String::Handle();
#define RECOGNIZE_FUNCTION(class_name, function_name, enum_name)               \
    test_function_name = String::NewSymbol(#function_name);                    \
    test_class_name = String::NewSymbol(#class_name);                          \
    if (recognize_name.Equals(test_function_name) &&                           \
        recognize_class.Equals(test_class_name)) {                             \
      return k##enum_name;                                                     \
    }
RECOGNIZED_LIST(RECOGNIZE_FUNCTION)
#undef RECOGNIZE_FUNCTION
    return kUnknown;
  }

  static const char* KindToCString(Kind kind) {
#define KIND_TO_STRING(class_name, function_name, enum_name)                   \
    if (kind == k##enum_name) return #enum_name;
RECOGNIZED_LIST(KIND_TO_STRING)
#undef KIND_TO_STRING
    return "?";
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(Recognizer);
};


// Maintain classes of locals as defined by a store to that local.
// A simple initial implementation, memorizes last typed stores. Does not
// scale well for large code pieces. This will be replaced by SSA based
// type propagation.
class ClassesForLocals : public ZoneAllocated {
 public:
  ClassesForLocals() : classes_(), locals_() {}
  void SetLocalType(const LocalVariable& local, const Class& cls) {
    classes_.Add(&cls);
    locals_.Add(&local);
  }
  // If no type is stored/known, we return a null class in 'cls'.
  void GetLocalClass(const LocalVariable& local, const Class** cls) const {
    for (intptr_t i = locals_.length() - 1; i >=0; i--) {
      if (locals_[i]->Equals(local)) {
        *cls = classes_[i];
        return;
      }
    }
    *cls = &Class::ZoneHandle();
  }

  void Clear() {
    classes_.Clear();
    locals_.Clear();
  }

 private:
  GrowableArray<const Class*> classes_;
  GrowableArray<const LocalVariable*> locals_;

  DISALLOW_COPY_AND_ASSIGN(ClassesForLocals);
};


OptimizingCodeGenerator::OptimizingCodeGenerator(
    Assembler* assembler, const ParsedFunction& parsed_function)
        : CodeGenerator(assembler, parsed_function),
          deoptimization_blobs_(4),
          classes_for_locals_(new ClassesForLocals()),
          smi_class_(Class::ZoneHandle(Isolate::Current()->object_store()
              ->smi_class())),
          double_class_(Class::ZoneHandle(Isolate::Current()->object_store()
              ->double_class())),
          growable_object_array_class_(Class::ZoneHandle(Isolate::Current()
              ->object_store()->growable_object_array_class())) {
  ASSERT(parsed_function.function().is_optimizable());
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               DeoptReasonId reason_id) {
  DeoptimizationBlob* d = new DeoptimizationBlob(node, reason_id);
  deoptimization_blobs_.Add(d);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               Register reg,
                                               DeoptReasonId reason_id) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node, reason_id);
  d->Push(reg);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               Register reg1,
                                               Register reg2,
                                               DeoptReasonId reason_id) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node, reason_id);
  d->Push(reg1);
  d->Push(reg2);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               Register reg1,
                                               Register reg2,
                                               Register reg3,
                                               DeoptReasonId reason_id) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node, reason_id);
  d->Push(reg1);
  d->Push(reg2);
  d->Push(reg3);
  return d;
}


void OptimizingCodeGenerator::GenerateDeferredCode() {
  CodeGenerator::GenerateDeferredCode();
  for (int i = 0; i < deoptimization_blobs_.length(); i++) {
    deoptimization_blobs_[i]->Generate(this);
  }
}


bool OptimizingCodeGenerator::IsResultInEaxRequested(AstNode* node) const {
  return (node->info() != NULL) && node->info()->request_result_in_eax();
}


static const ZoneGrowableArray<const Class*>*
    CollectedClassesAtNode(AstNode* node) {
  ZoneGrowableArray<const Class*>* result =
      new ZoneGrowableArray<const Class*>();
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    return result;
  }
  ASSERT(ic_data.num_args_tested() == 1);
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    Class& cls = Class::ZoneHandle();
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    result->Add(&cls);
  }
  return result;
}


// Debugging helper function.
void OptimizingCodeGenerator::PrintCollectedClassesAtId(AstNode* node,
                                                        intptr_t id) {
  const ICData& ic_data = node->ICDataAtId(id);
  OS::Print("Collected classes id %d num: %d\n", id, ic_data.NumberOfChecks());
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    Function& target = Function::Handle();
    GrowableArray<const Class*> classes;
    ic_data.GetCheckAt(i, &classes, &target);
    OS::Print("[");
    for (intptr_t c = 0; c < classes.length(); c++) {
      OS::Print("%s%s", (c > 0) ? ", " : "", classes[c]->ToCString());
    }
    OS::Print("] -> %s\n", target.ToFullyQualifiedCString());
  }
}


void OptimizingCodeGenerator::TraceOpt(AstNode* node, const char* message) {
  if (FLAG_trace_optimization) {
    OS::Print("Opt node ix: %d; %s\n", node->token_index(), message);
  }
}


void OptimizingCodeGenerator::TraceNotOpt(AstNode* node, const char* message) {
  if (FLAG_trace_optimization) {
    OS::Print("NOTOpt node ix: %d; %s: ", node->token_index(), message);
    AstPrinter::PrintNode(node);
    OS::Print("\n");
  }
}


// Check for stack overflow.
// Note that first 5 bytes may be patched with a jump.
// TODO(srdjan): Add check that no object is inlined in the first
// 5 bytes (length of a jump instruction).
void OptimizingCodeGenerator::GeneratePreEntryCode() {
}


void OptimizingCodeGenerator::CallDeoptimize(intptr_t node_id,
                                             intptr_t token_index) {
  __ call(&StubCode::DeoptimizeLabel());
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
#if defined(DEBUG)
  __ int3();
#endif
}


// Quick loads do not clobber registers.
static bool IsQuickLoad(AstNode* node) {
  return node->IsLoadLocalNode() || node->IsLiteralNode();
}


// Method is closely tied to "VisitLoadTwo".
void OptimizingCodeGenerator::VisitLoadOne(AstNode* node, Register reg) {
  if (!IsQuickLoad(node)) {
    node->Visit(this);
    __ popl(reg);
    return;
  }
  if (node->AsLoadLocalNode()) {
    LoadLocalNode* local_node = node->AsLoadLocalNode();
    ASSERT(local_node != NULL);
    GenerateLoadVariable(reg, local_node->local());
    if (node->info() != NULL) {
      const Class* cls = NULL;
      classes_for_locals_->GetLocalClass(local_node->local(), &cls);
      if (cls != NULL) {
        node->info()->set_is_class(cls);
      }
    }
    return;
  }
  if (node->AsLiteralNode()) {
    LiteralNode* literal_node = node->AsLiteralNode();
    ASSERT(literal_node != NULL);
    __ LoadObject(reg, literal_node->literal());
    if (node->info() != NULL) {
      const Object& literal = literal_node->literal();
      if (literal.IsSmi()) {
        node->info()->set_is_class(&smi_class_);
      } else if (literal.IsDouble()) {
        node->info()->set_is_class(&double_class_);
      }
    }
    return;
  }
  UNREACHABLE();
}


// Method is closely tied to "VisitLoadOne".
void OptimizingCodeGenerator::VisitLoadTwo(AstNode* left,
                                           AstNode* right,
                                           Register left_reg,
                                           Register right_reg) {
  ASSERT(left_reg != right_reg);
  if (IsQuickLoad(right)) {
#if defined(DEBUG)
    // Verify that left_reg does not get clobbered by VisitLoadOne(right, ...).
    VisitLoadOne(left, left_reg);
    __ pushl(left_reg);
    VisitLoadOne(right, right_reg);
    __ cmpl(left_reg, Address(ESP, 0));
    Label ok;
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Internal error at VisitLoadTwo");
    __ Bind(&ok);
    __ popl(left_reg);
#else
    VisitLoadOne(left, left_reg);
    VisitLoadOne(right, right_reg);
#endif
    return;
  }
  left->Visit(this);
  VisitLoadOne(right, right_reg);
  __ popl(left_reg);
}


void OptimizingCodeGenerator::VisitLiteralNode(LiteralNode* node) {
  if (!IsResultNeeded(node)) return;
  const Object& literal = node->literal();
  if (literal.IsSmi()) {
    if (node->info() != NULL) {
      node->info()->set_is_class(&smi_class_);
    }
    if (IsResultInEaxRequested(node)) {
      __ movl(EAX, Immediate(reinterpret_cast<int32_t>(literal.raw())));
      node->info()->set_result_returned_in_eax(true);
    } else {
      __ pushl(Immediate(reinterpret_cast<int32_t>(literal.raw())));
    }
  } else {
    if ((node->info() != NULL) && literal.IsDouble()) {
      node->info()->set_is_class(&double_class_);
    }
    if (IsResultInEaxRequested(node)) {
      __ LoadObject(EAX, literal);
      node->info()->set_result_returned_in_eax(true);
    } else {
      __ PushObject(literal);
    }
  }
}


void OptimizingCodeGenerator::VisitLoadLocalNode(LoadLocalNode* node) {
  if (!IsResultNeeded(node)) return;
  if (IsResultInEaxRequested(node)) {
    GenerateLoadVariable(EAX, node->local());
    node->info()->set_result_returned_in_eax(true);
  } else {
    GeneratePushVariable(node->local(), EAX);
  }
  if (node->info() != NULL) {
    const Class* cls = NULL;
    classes_for_locals_->GetLocalClass(node->local(), &cls);
    if (cls != NULL) {
      node->info()->set_is_class(cls);
    }
  }
}


void OptimizingCodeGenerator::HandleResult(AstNode* node, Register result_reg) {
  if (IsResultNeeded(node)) {
    if (IsResultInEaxRequested(node)) {
      if (result_reg != EAX) {
        __ movl(EAX, result_reg);
      }
      node->info()->set_result_returned_in_eax(true);
    } else {
      __ pushl(result_reg);
    }
  }
}


void OptimizingCodeGenerator::VisitStoreLocalNode(StoreLocalNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitStoreLocalNode(node);
    classes_for_locals_->SetLocalType(node->local(), Class::ZoneHandle());
    return;
  }
  CodeGenInfo value_info(node->value());
  value_info.set_allow_temp(false);
  value_info.set_request_result_in_eax(true);
  node->value()->Visit(this);
  if (!value_info.result_returned_in_eax()) {
    __ popl(EAX);
  }
  CodeGenerator::GenerateStoreVariable(node->local(), EAX, EDX);
  HandleResult(node, EAX);
  classes_for_locals_->SetLocalType(node->local(), *value_info.is_class());
}


static bool NodeHasBothReceiverClasses(AstNode* node,
                                       const Class& cls1,
                                       const Class& cls2) {
  ASSERT(node != NULL);
  ASSERT(!cls1.IsNull() && !cls2.IsNull());
  const ICData& ic_data = node->ICDataAtId(node->id());
  bool cls1_found = false;
  bool cls2_found = false;
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<const Class*> classes;
    Function& target = Function::Handle();
    ic_data.GetCheckAt(i, &classes, &target);
    if (!classes.is_empty()) {
      if (classes[0]->raw() == cls1.raw()) {
        cls1_found = true;
      }
      if (classes[0]->raw() == cls2.raw()) {
        cls2_found = true;
      }
      if (cls1_found && cls2_found) {
        return true;
      }
    }
  }
  return false;
}


// Look only at the first class in all check groups. Returns true if all
// receiver classes are 'cls'.
static bool AtIdNodeHasClassAt(AstNode* node,
                               intptr_t id,
                               const Class& cls,
                               intptr_t arg_index) {
  ASSERT(node != NULL);
  ASSERT(!cls.IsNull());
  const ICData& ic_data = node->ICDataAtId(id);
  if (ic_data.NumberOfChecks() == 0) {
    return false;
  }
  ASSERT(ic_data.num_args_tested() > arg_index);
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<const Class*> classes;
    Function& target = Function::Handle();
    ic_data.GetCheckAt(i, &classes, &target);
    if (classes.is_empty()) {
      return false;
    }
    if (classes[arg_index]->raw() != cls.raw()) {
      return false;
    }
  }
  return true;
}


// IC data may have only one check, and it has to contain the two classes in
// specified order.
static bool AtIdNodeHasTwoClasses(AstNode* node,
                                  intptr_t id,
                                  const Class& cls0,
                                  const Class& cls1) {
  ASSERT(node != NULL);
  ASSERT(!cls0.IsNull() && !cls1.IsNull());
  const ICData& ic_data = node->ICDataAtId(id);
  ASSERT(ic_data.num_args_tested() == 2);
  if (ic_data.NumberOfChecks() != 1) {
    return false;
  }
  Function& target = Function::Handle();
  GrowableArray<const Class*> classes;
  ic_data.GetCheckAt(0, &classes, &target);
  if ((cls0.raw() == classes[0]->raw()) && (cls1.raw() == classes[1]->raw())) {
    return true;
  }
  return false;
}


// SHL: Implement with slow case so that it works both with Smi and Mint types.
// Result is in EAX. Mangles ECX, EBX, EDX.
void OptimizingCodeGenerator::GenerateSmiShiftBinaryOp(BinaryOpNode* node) {
  if (node->kind() == Token::kSHR) {
    // TODO(srdjan): Implement for Mint?
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, ECX, kDeoptSAR);
    CodeGenInfo left_info(node->left());
    CodeGenInfo right_info(node->right());
    // EAX: value to shift, ECX: amount to shift.
    VisitLoadTwo(node->left(), node->right(), EAX, ECX);
    if (!left_info.IsClass(smi_class_) || !right_info.IsClass(smi_class_)) {
      // Check if both Smi.
      __ movl(EBX, EAX);
      __ orl(EBX, ECX);
      __ testl(EBX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());
      PropagateBackLocalClass(node->left(), smi_class_);
      PropagateBackLocalClass(node->right(), smi_class_);
    }
    Immediate count_limit = Immediate(0x1F);
    __ SmiUntag(ECX);
    __ cmpl(ECX, count_limit);
    Label shift_count_ok;
    __ j(LESS_EQUAL, &shift_count_ok, Assembler::kNearJump);
    __ movl(ECX, count_limit);
    __ Bind(&shift_count_ok);
    // Shift amount must be in ECX.
    __ SmiUntag(EAX);  // Value.
    __ sarl(EAX, ECX);
    __ SmiTag(EAX);
    return;
  }
  ASSERT(node->kind() == Token::kSHL);
  if (node->right()->IsLiteralNode() &&
      node->right()->AsLiteralNode()->literal().IsSmi()) {
    Label done;
    // Shift count is a Smi literal.
    Smi& smi = Smi::Handle();
    smi ^= node->right()->AsLiteralNode()->literal().raw();
    if (smi.Value() < Smi::kBits) {
      Label slow_case;
      CodeGenInfo left_info(node->left());
      VisitLoadOne(node->left(), EAX);
      if (!left_info.IsClass(smi_class_)) {
        __ testl(EAX, Immediate(kSmiTagMask));
        __ j(NOT_ZERO, &slow_case, Assembler::kNearJump);  // left not smi
      }
      // Overflow test.
      __ movl(EBX, EAX);
      Immediate imm(smi.Value());
      __ shll(EBX, imm);
      __ sarl(EBX, imm);
      __ cmpl(EAX, EBX);
      __ j(NOT_EQUAL, &slow_case, Assembler::kNearJump);  // Overflow.
      __ shll(EAX, imm);  // Shift for result now we know there is no overflow.
      __ jmp(&done);
      __ Bind(&slow_case);
      __ pushl(EAX);
      __ pushl(Immediate(reinterpret_cast<int32_t>(smi.raw())));
      const int number_of_arguments = 2;
      const Array& no_optional_argument_names = Array::Handle();
      GenerateCheckedInstanceCalls(node,
                                   node->left(),
                                   node->id(),
                                   node->token_index(),
                                   number_of_arguments,
                                   no_optional_argument_names);
      __ Bind(&done);
      return;
    }
  }

  Label slow_case, done;
  CodeGenInfo left_info(node->left());
  CodeGenInfo right_info(node->right());
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  // TODO(srdjan): Better code for count being a Smi literal.
  // EAX: value, EDX: shift amount. Preserve them for slow case.
  // Fast case only if both ar Smi.
  if (!left_info.IsClass(smi_class_) || !right_info.IsClass(smi_class_)) {
    __ movl(EBX, EAX);
    __ orl(EBX, EDX);
    __ testl(EBX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case, Assembler::kNearJump);
  }
  // Check if count too large for handling it inlined.
  __ cmpl(EDX, Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
  __ j(ABOVE_EQUAL, &slow_case, Assembler::kNearJump);
  // Shift amount must be in ECX.
  __ movl(ECX, EDX);
  __ movl(EBX, EAX);
  __ SmiUntag(ECX);
  // Overflow test.
  __ shll(EBX, ECX);
  __ sarl(EBX, ECX);
  __ cmpl(EAX, EBX);
  __ j(NOT_EQUAL, &slow_case, Assembler::kNearJump);  // Overflow.

  __ shll(EAX, ECX);  // Shift for result now we know there is no overflow.
  // EAX is the correctly tagged Smi.
  __ jmp(&done);
  __ Bind(&slow_case);
  __ pushl(EAX);
  __ pushl(EDX);
  const int number_of_arguments = 2;
  const Array& no_optional_argument_names = Array::Handle();
  GenerateCheckedInstanceCalls(node,
                               node->left(),
                               node->id(),
                               node->token_index(),
                               number_of_arguments,
                               no_optional_argument_names);
  __ Bind(&done);
}


// Implement Token::kSUB and Token::kBIT_NOT.
void OptimizingCodeGenerator::GenerateSmiUnaryOp(UnaryOpNode* node) {
  const ICData& ic_data = node->ICDataAtId(node->id());
  ASSERT(ic_data.num_args_tested() == 1);
  DeoptReasonId deopt_reason_id = ic_data.NumberOfChecks() == 0 ?
      kDeoptNoTypeFeedback : kDeoptUnaryOp;
  DeoptimizationBlob* deopt_blob =
      AddDeoptimizationBlob(node, EAX, deopt_reason_id);
  CodeGenInfo info(node->operand());
  VisitLoadOne(node->operand(), EAX);
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback.
    __ jmp(deopt_blob->label());
    return;
  }
  ASSERT(ic_data.NumberOfChecks() == 1);
  if (!info.IsClass(smi_class_)) {
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    PropagateBackLocalClass(node->operand(), smi_class_);
  }
  if (node->kind() == Token::kSUB) {
    __ negl(EAX);
    __ j(OVERFLOW, deopt_blob->label());
  } else {
    ASSERT(node->kind() == Token::kBIT_NOT);
    __ notl(EAX);
    __ andl(EAX, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
  }
  HandleResult(node, EAX);
}


void OptimizingCodeGenerator::GenerateDoubleUnaryOp(UnaryOpNode* node) {
  const Register kOperandRegister = ECX;
  const Register kTempRegister = EBX;
  const Register kResultRegister = EAX;
  const ICData& ic_data = node->ICDataAtId(node->id());
  DeoptReasonId deopt_reason_id = ic_data.NumberOfChecks() == 0 ?
      kDeoptNoTypeFeedback : kDeoptUnaryOp;
  DeoptimizationBlob* deopt_blob =
      AddDeoptimizationBlob(node, kOperandRegister, deopt_reason_id);
  CodeGenInfo info(node->operand());
  info.set_allow_temp(true);
  VisitLoadOne(node->operand(), kOperandRegister);
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback.
    __ jmp(deopt_blob->label());
    return;
  }
  ASSERT(ic_data.NumberOfChecks() == 1);
  if (!info.IsClass(double_class_)) {
    // Deoptimize if not double.
    CheckIfDoubleOrSmi(kOperandRegister,
                       kTempRegister,
                       deopt_blob->label(),
                       deopt_blob->label());
    PropagateBackLocalClass(node->operand(), double_class_);
  }
  const bool using_temp =
      (node->info() != NULL) && node->info()->allow_temp();
  if (!using_temp) {
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
    const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
    __ pushl(kOperandRegister);
    GenerateCall(node->token_index(), &label, PcDescriptors::kOther);
    ASSERT(kResultRegister == EAX);
    __ popl(kOperandRegister);
  } else if (info.is_temp()) {
    __ movl(kResultRegister, kOperandRegister);
  } else {
    const Double& double_object =
        Double::ZoneHandle(Double::New(0.0, Heap::kOld));
    __ LoadObject(kResultRegister, double_object);
  }
  __ movsd(XMM0, FieldAddress(kOperandRegister, Double::value_offset()));
  ASSERT(node->kind() == Token::kSUB);
  __ DoubleNegate(XMM0);
  __ movsd(FieldAddress(kResultRegister, Double::value_offset()), XMM0);
  if (IsResultNeeded(node)) {
    if (node->info() != NULL) {
      node->info()->set_is_temp(using_temp);
      node->info()->set_is_class(&double_class_);
    }
    HandleResult(node, kResultRegister);
  }
}


// Handles only Smi & Smi.
// TODO(srdjan): Certain operations always overflow, and thus cause
// deoptimization. We need to mark those places and handle them.
void OptimizingCodeGenerator::GenerateSmiBinaryOp(BinaryOpNode* node) {
  const char* kOptMessage = "Inlines BinaryOp for Smi";
  Label done;
  const Token::Kind kind = node->kind();
  if ((kind == Token::kADD) ||
      (kind == Token::kSUB) ||
      (kind == Token::kMUL) ||
      (kind == Token::kTRUNCDIV) ||
      (kind == Token::kBIT_AND) ||
      (kind == Token::kBIT_OR) ||
      (kind == Token::kBIT_XOR)) {
    TraceOpt(node, kOptMessage);
    // Check if both arguments are expected to be Smi.
    const ICData& ic_data = node->ICDataAtId(node->id());
    ASSERT(ic_data.num_args_tested() == 2);
    ASSERT(ic_data.NumberOfChecks() > 0);
    Function& target = Function::Handle();
    GrowableArray<const Class*> classes;
    ic_data.GetCheckAt(0, &classes, &target);
    ASSERT(ic_data.NumberOfChecks() == 1);
    ASSERT((classes[0]->raw() == smi_class_.raw()) &&
        (classes[1]->raw() == smi_class_.raw()));
    CodeGenInfo left_info(node->left());
    CodeGenInfo right_info(node->right());
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    Label two_smis, call_operator;
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, ECX, EDX, kDeoptSmiBinaryOp);
    __ movl(ECX, EAX);  // Save if overflow (needs original value).

    if (left_info.IsClass(smi_class_) || right_info.IsClass(smi_class_)) {
      if (!left_info.IsClass(smi_class_)) {
        __ testl(EAX, Immediate(kSmiTagMask));
        __ j(NOT_ZERO, deopt_blob->label());
        PropagateBackLocalClass(node->left(), smi_class_);
      }
      if (!right_info.IsClass(smi_class_)) {
        __ testl(EDX, Immediate(kSmiTagMask));
        __ j(NOT_ZERO, deopt_blob->label());
        PropagateBackLocalClass(node->right(), smi_class_);
      }
    } else {
      // Type feedback says both types are Smi, but static type analysis
      // does not know if any of them is Smi, therefore check.
      __ orl(EAX, EDX);
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());
      __ movl(EAX, ECX);
      PropagateBackLocalClass(node->left(), smi_class_);
      PropagateBackLocalClass(node->right(), smi_class_);
    }
    if (node->info() != NULL) {
      node->info()->set_is_class(&smi_class_);
    }
    switch (kind) {
      case Token::kADD: {
        __ addl(EAX, EDX);
        __ j(OVERFLOW, deopt_blob->label());
        break;
      }
      case Token::kSUB: {
        __ subl(EAX, EDX);
        __ j(OVERFLOW, deopt_blob->label());
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(EAX);
        __ imull(EAX, EDX);
        __ j(OVERFLOW, deopt_blob->label());
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ andl(EAX, EDX);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ orl(EAX, EDX);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ xorl(EAX, EDX);
        break;
      }
      case Token::kTRUNCDIV: {
        // Handle divide by zero in runtime.
        __ cmpl(EDX, Immediate(0));
        __ j(EQUAL, deopt_blob->label());
        // Preserve left & right in case of 'overflow'.
        __ pushl(EDX);
        __ pushl(ECX);
        // Move right to ECX, left is in EAX.
        __ movl(ECX, EDX);
        __ SmiUntag(ECX);
        __ SmiUntag(EAX);
        // Sign extend EAX -> EDX:EAX.
        __ cdq();
        __ idivl(ECX);  // Result in EAX.
        __ popl(ECX);
        __ popl(EDX);
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ cmpl(EAX, Immediate(0x40000000));
        __ j(EQUAL, deopt_blob->label());
        __ SmiTag(EAX);
        break;
      }
      default:
        UNREACHABLE();
    }
  } else if ((kind == Token::kSHL) || (kind == Token::kSHR)) {
    GenerateSmiShiftBinaryOp(node);
  } else {
    // Unhandled node kind.
    TraceNotOpt(node, kOptMessage);
    node->left()->Visit(this);
    node->right()->Visit(this);
    CodeGenerator::GenerateBinaryOperatorCall(node->id(),
                                              node->token_index(),
                                              node->Name());
  }
  __ Bind(&done);
  HandleResult(node, EAX);
}


// Supports some mixed Smi/Mint operations.
// For BIT_AND operation with right operand being Smi, we can throw away
// any Mint bits above the Smi range as long as the right operand is positive.
// 'allow_smi' is true if Smi and Mint classes have been encountered.
void OptimizingCodeGenerator::GenerateMintBinaryOp(BinaryOpNode* node,
                                                   bool allow_smi) {
  const char* kOptMessage = "Inline Mint binop.";
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Token::Kind kind = node->kind();
  if (kind == Token::kBIT_AND) {
    TraceOpt(node, kOptMessage);
    Label is_smi, slow_case, done;
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptMintBinaryOp);
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    __ testl(EDX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case);  // Call operator if right is not Smi.
    __ cmpl(EDX, Immediate(0));
    __ j(LESS, &slow_case);  // Result will not be Smi.

    // Test left.
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(ZERO, &is_smi);

    __ movl(EBX, FieldAddress(EAX, Object::class_offset()));
    __ CompareObject(EBX, Class::ZoneHandle(object_store->mint_class()));
    __ j(NOT_EQUAL, deopt_blob->label());

    // Load lower Mint word, convert to Smi. It is OK to loose bits.
    __ movl(EAX, FieldAddress(EAX, Mint::value_offset()));
    __ SmiTag(EAX);

    __ Bind(&is_smi);
    __ andl(EAX, EDX);
    __ jmp(&done);
    __ Bind(&slow_case);
    __ pushl(EAX);
    __ pushl(EDX);
    const int number_of_arguments = 2;
    const Array& no_optional_argument_names = Array::Handle();
    GenerateCheckedInstanceCalls(node,
                                 node->left(),
                                 node->id(),
                                 node->token_index(),
                                 number_of_arguments,
                                 no_optional_argument_names);
    __ Bind(&done);
    HandleResult(node, EAX);
    return;
  }
  if ((kind == Token::kSHL) && allow_smi) {
    GenerateSmiShiftBinaryOp(node);
    HandleResult(node, EAX);
    return;
  }
  TraceNotOpt(node, kOptMessage);
  CodeGenerator::VisitBinaryOpNode(node);
}


// Conservative approach:
// - true if both nodes are LoadLocalNodes with the same index.
static bool AreNodesOfSameType(AstNode* a, AstNode* b) {
  ASSERT((a != NULL) && (b != NULL));
  if (a->IsLoadLocalNode() && b->IsLoadLocalNode()) {
    return a->AsLoadLocalNode()->local().Equals(b->AsLoadLocalNode()->local());
  }
  return false;
}


// If possible propagate node type back to the local, therefore next load
// of local can use that class and eliminate type checks.
void OptimizingCodeGenerator::PropagateBackLocalClass(AstNode* node,
                                                      const Class& cls) {
  if (node->IsLoadLocalNode()) {
    LoadLocalNode* local_node = node->AsLoadLocalNode();
    classes_for_locals_->SetLocalType(local_node->local(), cls);
  }
}


// 'reg' is not modified, 'temp' is trashed.
// Fall through if double, jump to 'is_smi' if Smi and
// jump to 'not_double_or_smi' if neither double nor Smi.
void OptimizingCodeGenerator::CheckIfDoubleOrSmi(Register reg,
                                                 Register temp,
                                                 Label* is_smi,
                                                 Label* not_double_or_smi) {
  __ testl(reg, Immediate(kSmiTagMask));
  __ j(ZERO, is_smi);
  __ movl(temp, FieldAddress(reg, Object::class_offset()));
  __ CompareObject(temp, double_class_);
  __ j(NOT_EQUAL, not_double_or_smi);
}


// Result of the computation is a newly allocated double object or
// a temporary object if the parent node specifies a CodeGenInfo for this node
// and therefore knows how to handle a temporary. A temporary object cannot
// be used for long living values (e.g., the ones stored on stack or into other
// objects).
// Implement for combinations: Double/Double, Double/Smi, Smi/Double, as
// the result is always double.
// TODO(srdjan): Implement Smi/Smi for kDIV (result also double).
void OptimizingCodeGenerator::GenerateDoubleBinaryOp(BinaryOpNode* node,
                                                     bool receiver_can_be_smi) {
  const char* kOptMessage = "Inlines BinaryOp for Doubles";
  const Token::Kind kind = node->kind();
  if ((kind == Token::kADD) ||
      (kind == Token::kSUB) ||
      (kind == Token::kMUL) ||
      (kind == Token::kDIV)) {
    TraceOpt(node, kOptMessage);
    // All four register below must be different.
    const Register kLeftRegister = EAX;
    const Register kRightRegister = EDX;
    const Register kAllocatedRegister = ECX;
    const Register kTempRegister = EBX;
    CodeGenInfo left_info(node->left());  // Receiver.
    CodeGenInfo right_info(node->right());
    left_info.set_allow_temp(true);
    right_info.set_allow_temp(true);
    VisitLoadTwo(node->left(), node->right(), kLeftRegister, kRightRegister);
    // First allocate result object or specify an existing object as result.
    Register result_register = kNoRegister;
    const bool using_temp =
        (node->info() != NULL) && node->info()->allow_temp();
    if (!using_temp) {
      // Parent node cannot handle a temporary double object, allocate one
      // each time.
      result_register = kAllocatedRegister;
      const Code& stub =
          Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
      const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
      __ pushl(kLeftRegister);
      __ pushl(kRightRegister);
      GenerateCall(node->token_index(), &label, PcDescriptors::kOther);
      __ movl(result_register, EAX);
      __ popl(kRightRegister);
      __ popl(kLeftRegister);
    } else if (left_info.IsClass(double_class_) && left_info.is_temp()) {
      result_register = kLeftRegister;
    } else if (right_info.IsClass(double_class_) && right_info.is_temp()) {
      result_register = kRightRegister;
    } else {
      result_register = kAllocatedRegister;
      // Use inlined temporary double object.
      const Double& double_object =
          Double::ZoneHandle(Double::New(0.0, Heap::kOld));
      __ LoadObject(result_register, double_object);
    }

    DeoptimizationBlob* deopt_blob = NULL;
    Label* deopt_lbl = NULL;
    // Deoptimization can only occur if one of arguments is not double.
    if (!left_info.IsClass(double_class_) ||
        !right_info.IsClass(double_class_)) {
      deopt_blob = AddDeoptimizationBlob(node,
                                         kLeftRegister,
                                         kRightRegister,
                                         kDeoptDoubleBinaryOp);
      deopt_lbl = deopt_blob->label();
    }

    if (receiver_can_be_smi) {
      // Only deoptimize if both argument are Smi.
      __ movl(kTempRegister, kLeftRegister);
      __ orl(kTempRegister, kRightRegister);
      __ testl(kTempRegister, Immediate(kSmiTagMask));
      __ j(ZERO, deopt_lbl);
    }

    bool args_of_same_type = AreNodesOfSameType(node->left(), node->right());
    if (left_info.IsClass(double_class_)) {
      __ movsd(XMM0, FieldAddress(kLeftRegister, Double::value_offset()));
    } else {
      if (receiver_can_be_smi) {
        Label is_smi, done;
        CheckIfDoubleOrSmi(kLeftRegister, kTempRegister, &is_smi, deopt_lbl);
        // Fall through for double. Jump to 'is_smi' if double, jump to
        // 'deopt' if neither smi nor double.
        __ movsd(XMM0, FieldAddress(kLeftRegister, Double::value_offset()));
        __ jmp(&done);
        __ Bind(&is_smi);
        __ SmiUntag(kLeftRegister);
        __ cvtsi2sd(XMM0, kLeftRegister);
        __ Bind(&done);
      } else {
        CheckIfDoubleOrSmi(kLeftRegister, kTempRegister, deopt_lbl, deopt_lbl);
        __ movsd(XMM0, FieldAddress(kLeftRegister, Double::value_offset()));
        PropagateBackLocalClass(node->left(), double_class_);
      }
    }

    const bool right_must_be_double =
        AtIdNodeHasClassAt(node, node->id(), double_class_, 1);

    // If arguments are of same type (e.g., same local), then the test of left
    // argument was sufficient.
    if (right_info.IsClass(double_class_) || args_of_same_type) {
      __ movsd(XMM1, FieldAddress(kRightRegister, Double::value_offset()));
      if (!right_info.IsClass(double_class_)) {
        PropagateBackLocalClass(node->right(), double_class_);
      }
    } else {
      if (right_must_be_double) {
        CheckIfDoubleOrSmi(kRightRegister, kTempRegister, deopt_lbl, deopt_lbl);
        __ movsd(XMM1, FieldAddress(kRightRegister, Double::value_offset()));
        PropagateBackLocalClass(node->right(), double_class_);
      } else {
        Label is_smi, done;
        CheckIfDoubleOrSmi(kRightRegister, kTempRegister, &is_smi, deopt_lbl);
        // Fall through for double. Jump to 'is_smi' if double, jump to
        // 'deopt' if neither smi nor double.
        __ movsd(XMM1, FieldAddress(kRightRegister, Double::value_offset()));
        __ jmp(&done);
        __ Bind(&is_smi);
        __ SmiUntag(kRightRegister);
        __ cvtsi2sd(XMM1, kRightRegister);
        __ Bind(&done);
      }
    }

    switch (kind) {
      case Token::kADD: __ addsd(XMM0, XMM1); break;
      case Token::kSUB: __ subsd(XMM0, XMM1); break;
      case Token::kMUL: __ mulsd(XMM0, XMM1); break;
      case Token::kDIV: __ divsd(XMM0, XMM1); break;
      default: UNREACHABLE();
    }
    __ movsd(FieldAddress(result_register, Double::value_offset()), XMM0);
    if (IsResultNeeded(node)) {
      if (node->info() != NULL) {
        node->info()->set_is_temp(using_temp);
        node->info()->set_is_class(&double_class_);
      }
      HandleResult(node, result_register);
    }
    return;
  }

  TraceNotOpt(node, kOptMessage);
  CodeGenerator::VisitBinaryOpNode(node);
}


static bool NodeInfoHasLabels(AstNode* node) {
  return (node->info() != NULL) &&
      (node->info()->true_label() != NULL) &&
      (node->info()->false_label() != NULL);
}


// Generates code for logical OR, AND operations.
// A logical binary operation either pushes a true/false object on the stack,
// or jumps to the true/false label of the parent node.
// For AND operation, if left argument is false, then the result is false.
// For OR operation, if left argument is true, then the result is true.
// Otherwise the right argument is evaluated and the result corresponds to the
// right argument.
void OptimizingCodeGenerator::GenerateLogicalBinaryOp(BinaryOpNode* node) {
  ASSERT((node->kind() == Token::kAND) || (node->kind() == Token::kOR));
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  // If NodeInfoHasLabels is true, then we do not return a result but
  // jump to the specified true/false labels.
  Label return_false_object, return_true_object, evaluate_right_label;
  Label* false_label = NodeInfoHasLabels(node) ?
      node->info()->false_label() : &return_false_object;
  Label* true_label = NodeInfoHasLabels(node) ?
      node->info()->true_label() : &return_true_object;

  CodeGenInfo left_bool(node->left());
  if (node->kind() == Token::kAND) {
    left_bool.set_true_label(&evaluate_right_label);
    left_bool.set_false_label(false_label);
  } else {
    left_bool.set_true_label(true_label);
    left_bool.set_false_label(&evaluate_right_label);
  }
  VisitLoadOne(node->left(), EAX);
  if (left_bool.labels_used()) {
    __ Bind(&evaluate_right_label);
  } else {
    __ CompareObject(EAX, bool_true);
    if (node->kind() == Token::kAND) {
      __ j(NOT_EQUAL, false_label);
    } else {
      __ j(EQUAL, true_label);
    }
  }

  CodeGenInfo right_bool(node->right());
  right_bool.set_true_label(true_label);
  right_bool.set_false_label(false_label);
  VisitLoadOne(node->right(), EAX);
  if (right_bool.labels_used()) {
    // The control flow continues at the parent's false or true labels.
#if defined(DEBUG)
    __ Unreachable("BinaryOp");
#endif
  } else {
    __ CompareObject(EAX, bool_true);
    __ j(NOT_EQUAL, false_label);
    if (NodeInfoHasLabels(node)) {
      __ jmp(true_label);
    }
  }
  if (NodeInfoHasLabels(node)) {
    node->info()->set_labels_used(true);
  } else {
    Label done;
    __ Bind(&return_true_object);
    __ LoadObject(EAX, bool_true);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&return_false_object);
    __ LoadObject(EAX, bool_false);
    __ Bind(&done);
    HandleResult(node, EAX);
  }
}


void OptimizingCodeGenerator::VisitBinaryOpNode(BinaryOpNode* node) {
  // Operators "&&" and "||" cannot be overloaded, therefore inline them
  // instead of calling the operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // TODO(srdjan): Test in checked mode if they are Booleans otherwise
    // throw exception.
    if (FLAG_enable_type_checks) {
      CodeGenerator::VisitBinaryOpNode(node);
      return;
    }
    GenerateLogicalBinaryOp(node);
    return;
  }

  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptNoTypeFeedback);
    __ jmp(deopt_blob->label());
    return;
  }

  ASSERT(ic_data.num_args_tested() == 2);

  if (AtIdNodeHasTwoClasses(node, node->id(), smi_class_, smi_class_)) {
    GenerateSmiBinaryOp(node);
    return;
  }

  if (AtIdNodeHasClassAt(node, node->id(), double_class_, 0)) {
    const bool receiver_can_be_smi = false;
    GenerateDoubleBinaryOp(node, receiver_can_be_smi);
    return;
  }

  if (AtIdNodeHasTwoClasses(node, node->id(), smi_class_, double_class_)) {
    const bool receiver_can_be_smi = true;
    GenerateDoubleBinaryOp(node, receiver_can_be_smi);
    return;
  }

  const Class& mint_class =
      Class::Handle(Isolate::Current()->object_store()->mint_class());
  if (AtIdNodeHasClassAt(node, node->id(), mint_class, 0)) {
    GenerateMintBinaryOp(node, false);
    return;
  }

  if (NodeHasBothReceiverClasses(node, smi_class_, mint_class)) {
    GenerateMintBinaryOp(node, true);
    return;
  }

  // TODO(srdjan): Implement "+" for Strings.
  // Type feedback tells this is not a Smi or Double operation.
  TraceNotOpt(node,
      "BinaryOp: type feedback tells this is not a Smi, Mint or Double op");
  node->left()->Visit(this);
  node->right()->Visit(this);
  const int number_of_arguments = 2;
  const Array& no_optional_argument_names = Array::Handle();
  GenerateCheckedInstanceCalls(node,
                               node->left(),
                               node->id(),
                               node->token_index(),
                               number_of_arguments,
                               no_optional_argument_names);
  HandleResult(node, EAX);
  return;
}


// Optimized for Smi only.
void OptimizingCodeGenerator::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  if (FLAG_enable_type_checks) {
    const AbstractType& local_type = node->local().type();
    if (!local_type.IsNumberInterface() && !local_type.IsIntInterface()) {
      // Local does not accept a Smi (only Smi's interfaces are public).
      classes_for_locals_->SetLocalType(node->local(), Class::ZoneHandle());
      CodeGenerator::VisitIncrOpLocalNode(node);
      return;
    }
  }
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, kDeoptNoTypeFeedback);
    __ jmp(deopt_blob->label());
    return;
  }
  const char* kOptMessage = "Inlines IncrOpLocal";
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  if (!AtIdNodeHasClassAt(node, node->id(), smi_class_, 0)) {
    classes_for_locals_->SetLocalType(node->local(), Class::ZoneHandle());
    TraceNotOpt(node, kOptMessage);
    CodeGenerator::VisitIncrOpLocalNode(node);
    return;
  }
  TraceOpt(node, kOptMessage);

  GenerateLoadVariable(EAX, node->local());
  if (!node->prefix() && IsResultNeeded(node)) {
    // Preserve as result.
    __ movl(ECX, EAX);
  }
  const int int_value = (node->kind() == Token::kINCR) ? 1 : -1;
  const Immediate smi_value =
      Immediate(reinterpret_cast<int32_t>(Smi::New(int_value)));
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, kDeoptIncrLocal);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt_blob->label());
  __ addl(EAX, smi_value);
  __ j(OVERFLOW, deopt_blob->label());
  GenerateStoreVariable(node->local(), EAX, EDX);
  if (IsResultNeeded(node)) {
    if (node->info() != NULL) {
      node->info()->set_is_class(&smi_class_);
    }
    if (node->prefix()) {
      __ pushl(EAX);
    } else {
      __ pushl(ECX);
    }
  }
  classes_for_locals_->SetLocalType(node->local(), smi_class_);
}


// Debugging helper method, used in assert only.
static bool HaveSameClassesInICData(const ICData& a, const ICData& b) {
  if (a.NumberOfChecks() != b.NumberOfChecks()) {
    return false;
  }
  if (a.NumberOfChecks() == 0) {
    return true;
  }
  if (a.num_args_tested() != b.num_args_tested()) {
    return false;
  }
  // Only one-argument checks implemented.
  ASSERT(a.num_args_tested() == 1);
  Function& a_target = Function::Handle();
  Function& b_target = Function::Handle();
  Class& a_class = Class::Handle();
  Class& b_class = Class::Handle();
  for (intptr_t i = 0; i < a.NumberOfChecks(); i++) {
    a.GetOneClassCheckAt(i, &a_class, &a_target);
    bool found = false;
    for (intptr_t n = 0; n < b.NumberOfChecks(); n++) {
      b.GetOneClassCheckAt(n, &b_class, &b_target);
      if ((a_class.raw() == b_class.raw())) {
        found = true;
        break;
      }
    }
    if (!found) {
      return false;
    }
  }
  return true;
}


void OptimizingCodeGenerator::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  VisitLoadOne(node->receiver(), EBX);
  __ pushl(EBX);  // Duplicate receiver (preserve for setter).
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    // Deoptimization point for this node is after receiver has been
    // pushed twice on stack and before the getter (above) was executed.
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EBX, kDeoptIncrInstance);
    __ jmp(deopt_blob->label());
    return;
  }
  InlineInstanceGetter(node,
                       node->getter_id(),
                       node->receiver(),
                       node->field_name(),
                       EBX);
  // result is in EAX.
  __ popl(EDX);   // Get receiver.
  const bool return_original_value = !node->prefix() && IsResultNeeded(node);
  const Immediate one_value = Immediate(Smi::RawValue(1));
  // EAX: Value.
  // EDX: Receiver.
  if (AtIdNodeHasClassAt(node, node->operator_id(), smi_class_, 0)) {
    // Deoptimization point for this node is after receiver has been
    // pushed twice on stack and before the getter (above) was executed.
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EDX, EDX, kDeoptIncrInstanceOneClass);
    if (return_original_value) {
      // Preserve pre increment result.
      __ movl(ECX, EAX);
    }
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    if (node->kind() == Token::kINCR) {
      __ addl(EAX, one_value);
    } else {
      __ subl(EAX, one_value);
    }
    __ j(OVERFLOW, deopt_blob->label());
    if (return_original_value) {
      // Preserve as result.
      __ pushl(ECX);  // Preserve pre-increment value as result.
    }
  } else {
    if (return_original_value) {
      // Preserve as result.
      __ pushl(EAX);  // Preserve value as result.
    }
    __ pushl(EDX);  // Preserve receiver.
    __ pushl(EAX);  // Left operand.
    __ pushl(one_value);  // Right operand.
    const char* operator_name = (node->kind() == Token::kINCR) ? "+" : "-";
    GenerateBinaryOperatorCall(node->operator_id(),
                               node->token_index(),
                               operator_name);
    __ popl(EDX);  // Restore receiver.
  }
  // EAX: Result of binary operation.
  // EDX: receiver
  if (IsResultNeeded(node) && node->prefix()) {
    // Value stored into field is the result.
    __ pushl(EAX);
  }

  // This can never deoptimize since the checks are the same as in getter.
  ASSERT(HaveSameClassesInICData(node->ICDataAtId(node->getter_id()),
                                 node->ICDataAtId(node->setter_id())));
  InlineInstanceSetter(node,
                       node->setter_id(),
                       node->receiver(),
                       node->field_name(),
                       EDX,   // receiver
                       EAX);  // value.
}





// Return offset of a field or -1 if field is not found.
static intptr_t GetFieldOffset(const Class& field_class,
                               const String& field_name) {
  Class& cls = Class::Handle(field_class.raw());
  Field& field = Field::Handle();
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      return field.Offset();
    }
    cls = cls.SuperClass();
  }
  return -1;
}


// For now, check if the node is the receiver of a non-Smi class.
bool OptimizingCodeGenerator::NodeMayBeSmi(AstNode* node) const {
  if (parsed_function_.function().is_static() ||
      parsed_function_.function().IsConstructor() ||
      parsed_function_.function().IsClosureFunction()) {
    return true;
  }
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  LocalVariable* receiver = scope->VariableAt(0);
  if (node->IsLoadLocalNode() &&
      (&node->AsLoadLocalNode()->local() == receiver)) {
    const Class& function_owner =
        Class::Handle(parsed_function_.function().owner());
    const String& integer_implementation_class_name =
        String::Handle(String::NewSymbol("IntegerImplementation"));
    const Class& integer_implementation_class = Class::Handle(
        Library::Handle(Library::CoreImplLibrary()).
            LookupClass(integer_implementation_class_name));
    if (!function_owner.IsSmi() &&
        (function_owner.raw() != integer_implementation_class.raw())) {
      return false;
    }
  }
  return true;
}


// Emits code for an instance getter that has one or more collected classes,
// all with the same target. Deoptimizes for Smi or unexpected class.
//  EBX: loaded receiver.
// Result is returned in EAX.
void OptimizingCodeGenerator::InlineInstanceGettersWithSameTarget(
    AstNode* node,
    intptr_t id,
    AstNode* receiver,
    const String& field_name,
    Register recv_reg) {
  if (recv_reg != EBX) {
    // TODO(srdjan): Do not hardwire register.
    UNIMPLEMENTED();
  }
  DeoptimizationBlob* deopt_blob =
      AddDeoptimizationBlob(node, EBX, kDeoptInstanceGetterSameTarget);
  if (NodeMayBeSmi(receiver)) {
    __ testl(EBX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
  }

  __ movl(EAX, FieldAddress(EBX, Object::class_offset()));
  const ICData& ic_data = node->ICDataAtId(id);
  Function& target = Function::Handle();
  Label load_field;
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    Class& cls = Class::ZoneHandle();
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    __ CompareObject(EAX, cls);
    if (i == (ic_data.NumberOfChecks() - 1)) {
      __ j(NOT_EQUAL, deopt_blob->label());
    } else {
      __ j(EQUAL, &load_field);
    }
  }
  Class& cls = Class::Handle();
  ic_data.GetOneClassCheckAt(0, &cls, &target);

  __ Bind(&load_field);
  // EBX: receiver.
  if (target.kind() == RawFunction::kImplicitGetter) {
    TraceOpt(node, "Inlines instance getter with same target");
    intptr_t field_offset = GetFieldOffset(cls, field_name);
    ASSERT(field_offset >= 0);
    __ movl(EAX, FieldAddress(EBX, field_offset));
    return;
  }

  Recognizer::Kind recognized_kind = Recognizer::RecognizeKind(target);
  switch (recognized_kind) {
    case Recognizer::kObjectArrayLength: {
      TraceOpt(node, "Inlines ObjectArray.length");
      __ movl(EAX, FieldAddress(EBX, Array::length_offset()));
      return;
    }
    case Recognizer::kGrowableArrayLength: {
      TraceOpt(node, "Inlines GrowableObjectArray.length");
      __ movl(EAX, FieldAddress(EBX, GrowableObjectArray::length_offset()));
      return;
    }
    case Recognizer::kStringBaseLength: {
      TraceOpt(node, "Inlines StringBase.length");
      __ movl(EAX, FieldAddress(EBX, String::length_offset()));
      return;
    }
    default:
      UNIMPLEMENTED();
  }
  UNREACHABLE();
}


static bool IsInlineableInstanceGetter(const Function& function) {
  if (function.kind() == RawFunction::kImplicitGetter) {
    return true;
  }
  Recognizer::Kind recognized = Recognizer::RecognizeKind(function);
  if ((recognized == Recognizer::kObjectArrayLength) ||
      (recognized == Recognizer::kGrowableArrayLength) ||
      (recognized == Recognizer::kStringBaseLength)) {
    return true;
  }
  return false;
}


// Return the unique target of all checks or null.
static RawFunction* GetUniqueTarget(const ICData& ic_data) {
  Function& prev_target = Function::Handle();
  Function& target = Function::Handle();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    ASSERT(!target.IsNull());
    if (!prev_target.IsNull() && (prev_target.raw() != target.raw())) {
      return Function::null();
    }
    prev_target = target.raw();
  }
  return target.raw();
}


// Return true if all targets in 'ic_data' point to same
// inlineable getter target.
static bool ICDataToSameInlineableInstanceGetter(const ICData& ic_data) {
  const Function& target = Function::Handle(GetUniqueTarget(ic_data));
  return !target.IsNull() && IsInlineableInstanceGetter(target);
}


void OptimizingCodeGenerator::InlineInstanceGetter(AstNode* node,
                                                   intptr_t id,
                                                   AstNode* receiver,
                                                   const String& field_name,
                                                   Register recv_reg) {
  if (ICDataToSameInlineableInstanceGetter(node->ICDataAtId(id))) {
    InlineInstanceGettersWithSameTarget(node,
                                        id,
                                        receiver,
                                        field_name,
                                        recv_reg);
  } else {
    // TODO(srdjan): Inline access.
    __ pushl(recv_reg);
    const int kNumberOfArguments = 1;
    const Array& kNoArgumentNames = Array::Handle();
    GenerateCheckedInstanceCalls(node,
                                 receiver,
                                 id,
                                 node->token_index(),
                                 kNumberOfArguments,
                                 kNoArgumentNames);
  }
}


// TODO(srdjan): Implement for multiple getter targets.
// For every class inline its implicit getter, or call the instance getter.
void OptimizingCodeGenerator::VisitInstanceGetterNode(
    InstanceGetterNode* node) {
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    node->receiver()->Visit(this);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, kDeoptInstanceGetter);
    __ jmp(deopt_blob->label());
    return;
  }

  VisitLoadOne(node->receiver(), EBX);
  InlineInstanceGetter(node,
                       node->id(),
                       node->receiver(),
                       node->field_name(),
                       EBX);
  // Result is in EAX.
  HandleResult(node, EAX);
}


// Helper struct to pass arguments to 'GenerateInstanceSetter'.
struct InstanceSetterArgs {
  const Class* cls;
  const Function* target;
  const String* field_name;
  Register recv_reg;
  Register value_reg;
  intptr_t id;
  intptr_t token_index;
};


// Preserves 'args.value_reg'. Either stores instance field directly or
// calls the setter method.
void OptimizingCodeGenerator::GenerateInstanceSetter(
    const InstanceSetterArgs& args) {
  if (args.target->kind() == RawFunction::kImplicitSetter) {
    intptr_t field_offset = GetFieldOffset(*(args.cls), *(args.field_name));
    ASSERT(field_offset >= 0);
    __ StoreIntoObject(args.recv_reg,
        FieldAddress(args.recv_reg, field_offset), args.value_reg);
  } else {
    __ pushl(args.value_reg);
    __ pushl(args.recv_reg);
    __ pushl(args.value_reg);
    const Array& no_optional_argument_names = Array::Handle();
    GenerateDirectCall(args.id,
                       args.token_index,
                       *(args.target),
                       2,
                       no_optional_argument_names);
    __ popl(args.value_reg);
  }
}


// Returns value in 'value_reg', clobbers EBX.
void OptimizingCodeGenerator::InlineInstanceSetter(AstNode* node,
                                                   intptr_t id,
                                                   AstNode* receiver,
                                                   const String& field_name,
                                                   Register recv_reg,
                                                   Register value_reg) {
  // EBX is used as temporary register for class.
  ASSERT((recv_reg != EBX) && (value_reg != EBX));
  GrowableArray<Class*> classes;
  GrowableArray<Function*> targets;
  bool unique_target = true;
  {
    const ICData& ic_data = node->ICDataAtId(id);
    ASSERT(ic_data.NumberOfChecks() > 0);
    ASSERT(ic_data.num_args_tested() == 1);
    for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
      Class& cls = Class::ZoneHandle();
      Function& target = Function::ZoneHandle();
      ic_data.GetOneClassCheckAt(i, &cls, &target);
      classes.Add(&cls);
      targets.Add(&target);
    }
    for (intptr_t i = 1; i < targets.length(); i++) {
      if (targets[i - 1]->raw() != targets[i]->raw()) {
        unique_target = false;
        break;
      }
    }
  }
  // TODO(srdjan): sort classes/target by their invocation count.
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(
      node, recv_reg, value_reg, kDeoptInstanceSetterSameTarget);
  // Deoptimize if Smi, since they do not have setters.
  if (NodeMayBeSmi(receiver)) {
    __ testl(recv_reg, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
  }
  __ movl(EBX, FieldAddress(recv_reg, Object::class_offset()));
  // Initialize setter arguments, but leave the class and target fields NULL.
  InstanceSetterArgs setter_args =
      {NULL, NULL, &field_name, recv_reg, value_reg, id, node->token_index()};

  if (unique_target) {
    Label store_field;
    for (intptr_t i = 0; i < classes.length(); i++) {
      __ CompareObject(EBX, *classes[i]);
      if (i == (classes.length() - 1)) {
        __ j(NOT_EQUAL, deopt_blob->label());
      } else {
        __ j(EQUAL, &store_field);
      }
    }
    __ Bind(&store_field);
    setter_args.cls = classes[0];
    setter_args.target = targets[0];
    GenerateInstanceSetter(setter_args);
    return;
  }
  // Targets are different.
  Label done;
  for (intptr_t i = 0; i < classes.length(); i++) {
    setter_args.cls = classes[i];
    setter_args.target = targets[i];
    __ CompareObject(EBX, *classes[i]);
    if (i == (classes.length() - 1)) {
      __ j(NOT_EQUAL, deopt_blob->label());
      GenerateInstanceSetter(setter_args);
    } else {
      Label next_check;
      __ j(NOT_EQUAL, &next_check);
      GenerateInstanceSetter(setter_args);
      __ jmp(&done);
      __ Bind(&next_check);
    }
  }
  __ Bind(&done);
}


// The call to the instance setter implements the assignment to a field.
// The result of the assignment to a field is the value being stored.
void OptimizingCodeGenerator::VisitInstanceSetterNode(
    InstanceSetterNode* node) {
  // TODO(srdjan): inline setters to different targets as well.
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitInstanceSetterNode(node);
    return;
  }
  VisitLoadTwo(node->receiver(), node->value(), EDX, EAX);
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EDX, EAX, kDeoptInstanceSetter);
    __ jmp(deopt_blob->label());
    return;
  }
  // Value in EAX survives and will be stored on stack if result is needed.
  InlineInstanceSetter(node,
                       node->id(),
                       node->receiver(),
                       node->field_name(),
                       EDX,
                       EAX);

  HandleResult(node, EAX);
}


// Return false if condition is not supported.
static bool SupportedTokenKindToSmiCondition(Token::Kind kind,
                                             Condition* condition) {
  switch (kind) {
    case Token::kEQ:
      *condition = EQUAL;
      return true;
    case Token::kNE:
      *condition = NOT_EQUAL;
      return true;
    case Token::kLT:
      *condition = LESS;
      return true;
    case Token::kGT:
      *condition = GREATER;
      return true;
    case Token::kLTE:
      *condition = LESS_EQUAL;
      return true;
    case Token::kGTE:
      *condition = GREATER_EQUAL;
      return true;
    default:
      return false;
  }
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQUAL:         return NOT_EQUAL;
    case NOT_EQUAL:     return EQUAL;
    case LESS:          return GREATER_EQUAL;
    case LESS_EQUAL:    return GREATER;
    case GREATER:       return LESS_EQUAL;
    case GREATER_EQUAL: return LESS;
    case BELOW:         return ABOVE_EQUAL;
    case BELOW_EQUAL:   return ABOVE;
    case ABOVE:         return BELOW_EQUAL;
    case ABOVE_EQUAL:   return BELOW;
    default:
      OS::Print("Error %d\n", condition);
      UNIMPLEMENTED();
      return EQUAL;
  }
}


void OptimizingCodeGenerator::GenerateConditionalJumps(const CodeGenInfo& nInfo,
                                                       Condition condition) {
  if (nInfo.fallthrough_label() == NULL) {
    __ j(condition, nInfo.true_label());
    __ jmp(nInfo.false_label());
  } else if (nInfo.fallthrough_label() == nInfo.false_label()) {
    __ j(condition, nInfo.true_label());
  } else if (nInfo.fallthrough_label() == nInfo.true_label()) {
    __ j(NegateCondition(condition), nInfo.false_label());
  }
}


// Generate code under assumption that it is common that a Smi
// is compared with null.
// Left argument can be Smi or null, otherwise deoptimize and collect more
// type information.
// Right operand can be Smi or null, otherwise call operator on Smi (e.g,
// when compared with double).
// This code will be more optimized once we collect types for two arguments.
void OptimizingCodeGenerator::GenerateSmiEquality(ComparisonNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  ASSERT((node->kind() == Token::kEQ) || (node->kind() == Token::kNE));
  CodeGenInfo left_info(node->left());
  CodeGenInfo right_info(node->right());
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  if (!IsResultNeeded(node)) {
    return;
  }
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label evaluate_comparison;
  if (!left_info.IsClass(smi_class_)) {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptSmiEquality);
    Label left_not_null;
    __ cmpl(EAX, raw_null);
    __ j(NOT_EQUAL, &left_not_null, Assembler::kNearJump);

    // Left is null, strict compare.
    __ cmpl(EAX, EDX);
    __ jmp(&evaluate_comparison, Assembler::kNearJump);

    // Deoptimize if left is not Smi.
    __ Bind(&left_not_null);
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
  }
  Label done;
  if (right_info.IsClass(smi_class_)) {
    __ cmpl(EAX, EDX);
    // Fall through to evaluate comparison.
  } else {
    Label call_operator, inlined_compare;
    // Test right for being Smi.
    __ testl(EDX, Immediate(kSmiTagMask));
    __ j(ZERO, &inlined_compare, Assembler::kNearJump);
    // Right is not Smi, test it for being null; if so result is false which
    // is generated by comparing it to left. If right is not null call operator
    // (could be double).
    __ cmpl(EDX, raw_null);
    __ j(NOT_EQUAL, &call_operator, Assembler::kNearJump);

    __ Bind(&inlined_compare);
    // Left is Smi, right is Smi or Null.
    __ cmpl(EAX, EDX);
    __ jmp(&evaluate_comparison);

    __ Bind(&call_operator);
    // Left is Smi.
    const int kNumberOfArguments = 2;
    const Array& kNoArgumentNames = Array::Handle();
    __ pushl(EAX);
    __ pushl(EDX);
    GenerateCheckedInstanceCalls(node,
                                 node->left(),
                                 node->id(),
                                 node->token_index(),
                                 kNumberOfArguments,
                                 kNoArgumentNames);
    __ CompareObject(EAX, bool_true);
    // Fall through to evaluate result.
  }
  __ Bind(&evaluate_comparison);
  // Condition is set by a previous comparison operation.
  Condition condition = OVERFLOW;  // Initialize to something.
  bool ok = SupportedTokenKindToSmiCondition(node->kind(), &condition);
  ASSERT(ok);
  if (NodeInfoHasLabels(node)) {
    GenerateConditionalJumps(*(node->info()), condition);
    node->info()->set_labels_used(true);
  } else {
    Label true_label;
    __ j(condition, &true_label, Assembler::kNearJump);
    __ PushObject(bool_false);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&true_label);
    __ PushObject(bool_true);
  }
  __ Bind(&done);
}


// Return false if the code cannot be generated. It is expected that
// node->left() is Smi (or null for equality comparison).
bool OptimizingCodeGenerator::GenerateSmiComparison(ComparisonNode* node) {
  if ((node->kind() == Token::kEQ) || (node->kind() == Token::kNE)) {
    GenerateSmiEquality(node);
    return true;
  }
  Condition condition;
  if (!SupportedTokenKindToSmiCondition(node->kind(), &condition)) {
    return false;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  CodeGenInfo left_info(node->left());
  CodeGenInfo right_info(node->right());
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  if (!IsResultNeeded(node)) {
    return true;
  }
  if (left_info.IsClass(smi_class_) && right_info.IsClass(smi_class_)) {
    __ cmpl(EAX, EDX);
  } else if (left_info.IsClass(smi_class_) || right_info.IsClass(smi_class_)) {
    // One is Smi.
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptSmiCompareSmis);
    Register reg_to_test = left_info.IsClass(smi_class_) ? EDX : EAX;
    __ testl(reg_to_test, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    __ cmpl(EAX, EDX);
  } else {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, ECX, EDX, kDeoptSmiCompareAny);
    __ movl(ECX, EAX);
    __ orl(EAX, EDX);
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    __ cmpl(ECX, EDX);
  }
  if (NodeInfoHasLabels(node)) {
    GenerateConditionalJumps(*(node->info()), condition);
    node->info()->set_labels_used(true);
  } else {
    Label true_label, done;
    __ j(condition, &true_label, Assembler::kNearJump);
    __ PushObject(bool_false);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&true_label);
    __ PushObject(bool_true);
    __ Bind(&done);
  }
  return true;
}


static bool SupportedTokenKindToDoubleCondition(Token::Kind kind,
                                                Condition* condition) {
  switch (kind) {
    case Token::kEQ:
      *condition = EQUAL;
      return true;
    case Token::kLT:
      *condition = BELOW;
      return true;
    case Token::kGT:
      *condition = ABOVE;
      return true;
    case Token::kLTE:
      *condition = BELOW_EQUAL;
      return true;
    case Token::kGTE:
      *condition = ABOVE_EQUAL;
      return true;
    default:
      return false;
  }
}


// Checks if an inlined equality/non-equality operation can be emitted:
// - type feedback must exist.
// - no class in type feedback list overrides '=='.
// - no Smi class in type feedback class list (Smi overrides equality operator).
bool OptimizingCodeGenerator::GenerateEqualityComparison(ComparisonNode* node) {
  ASSERT((node->kind() == Token::kEQ) || (node->kind() == Token::kNE));
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  const ZoneGrowableArray<const Class*>* classes = CollectedClassesAtNode(node);
  if (classes == NULL) {
    return false;
  }
  const int num_classes = classes->length();
  // 'num_classes' can be 0 if the receiver was always null.
  const String& operator_name = String::Handle(String::NewSymbol("=="));
  // Check that all classes resolve to Object.==. Object.!= is not overridable
  // and is based on Object.==.
  ObjectStore* object_store = Isolate::Current()->object_store();
  Function& function = Function::Handle();
  for (intptr_t i = 0; i < num_classes; i++) {
    const Class& cls = *(*classes)[i];
    const int kNumArguments = 2;  // 'this' and 'other' arguments.
    const int kNumNamedArguments = 0;
    function ^=
        Resolver::ResolveDynamicForReceiverClass(cls,
                                                 operator_name,
                                                 kNumArguments,
                                                 kNumNamedArguments);
    ASSERT(!function.IsNull());  // '==' must be defined.
    if (function.owner() != object_store->object_class()) {
      // Overridden '==' operator exists skip optimized comparison.
      TraceNotOpt(node, "Equality comparison, overridden ==");
      return false;
    }
    if (cls.raw() == smi_class_.raw()) {
      // TODO(srdjan): implement mixed smi/non-smi comparison, for the moment
      // bail out.
      TraceNotOpt(node, "Equality comparison, mixed with Smi");
      return false;
    }
  }

  // All targets are Object.==, i.e., '==='. Smi is not among the classes.
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  if (!IsResultNeeded(node)) {
    return true;
  }
  Label compare;
  // Comparison with NULL is "===".
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(EAX, raw_null);
  if (num_classes == 0) {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptEqualityNoFeedback);
    __ j(NOT_EQUAL, deopt_blob->label());
  } else {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EDX, kDeoptEqualityClassCheck);
    __ j(EQUAL, &compare);
    // Smi causes deoptimization.
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
    __ movl(EBX, FieldAddress(EAX, Object::class_offset()));
    for (intptr_t i = 0; i < num_classes; i++) {
      const Class& cls = *(*classes)[i];
      __ CompareObject(EBX, cls);
      if (i == (num_classes - 1)) {
        __ j(NOT_EQUAL, deopt_blob->label());
      } else {
        __ j(EQUAL, &compare);
      }
    }
  }
  __ Bind(&compare);
  __ cmpl(EAX, EDX);
  if (NodeInfoHasLabels(node)) {
    if (node->kind() == Token::kEQ) {
      GenerateConditionalJumps(*(node->info()), EQUAL);
    } else {
      GenerateConditionalJumps(*(node->info()), NOT_EQUAL);
    }
    node->info()->set_labels_used(true);
  } else {
    Label done, load_true;
    if (node->kind() == Token::kEQ) {
      __ j(EQUAL, &load_true, Assembler::kNearJump);
    } else {
      __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
    }
    __ PushObject(bool_false);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&load_true);
    __ PushObject(bool_true);
    __ Bind(&done);
  }
  TraceOpt(node, "Equality comparison");
  return true;
}


// Return false if the code cannot be generated.
bool OptimizingCodeGenerator::GenerateDoubleComparison(ComparisonNode* node) {
  Condition true_condition;
  if (!SupportedTokenKindToDoubleCondition(node->kind(), &true_condition)) {
    return false;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  CodeGenInfo left_info(node->left());
  CodeGenInfo right_info(node->right());
  left_info.set_allow_temp(true);
  right_info.set_allow_temp(true);
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  DeoptimizationBlob* deopt_blob = NULL;
  if (!left_info.IsClass(double_class_) || !right_info.IsClass(double_class_)) {
    deopt_blob = AddDeoptimizationBlob(node, EAX, EDX, kDeoptDoubleComparison);
  }
  if (!left_info.IsClass(double_class_)) {
    CheckIfDoubleOrSmi(EAX, EBX, deopt_blob->label(), deopt_blob->label());
    PropagateBackLocalClass(node->left(), double_class_);
  }
  if (!right_info.IsClass(double_class_)) {
    CheckIfDoubleOrSmi(EDX, EBX, deopt_blob->label(), deopt_blob->label());
    PropagateBackLocalClass(node->right(), double_class_);
  }
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ movsd(XMM1, FieldAddress(EDX, Double::value_offset()));
  __ comisd(XMM0, XMM1);
  if (NodeInfoHasLabels(node)) {
    __ j(PARITY_EVEN, node->info()->false_label());  // NaN -> false;
    GenerateConditionalJumps(*(node->info()), true_condition);
    node->info()->set_labels_used(true);
  } else {
    Label is_false, is_true, done;
    __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false;
    __ j(true_condition, &is_true, Assembler::kNearJump);
    __ Bind(&is_false);
    if (IsResultNeeded(node)) {
      __ PushObject(bool_false);
    }
    __ jmp(&done);
    __ Bind(&is_true);
    if (IsResultNeeded(node)) {
      __ PushObject(bool_true);
    }
    __ Bind(&done);
  }
  return true;
}


// IS, ISNOT are handled in class CodeGenerator.
void OptimizingCodeGenerator::VisitComparisonNode(ComparisonNode* node) {
  if ((node->kind() == Token::kEQ_STRICT) ||
      (node->kind() == Token::kNE_STRICT)) {
    const Bool& bool_true = Bool::ZoneHandle(Bool::True());
    const Bool& bool_false = Bool::ZoneHandle(Bool::False());
    // Note that evaluation of right may cause deoptimization, therefore left
    // must be on stack when evaluating right.
    if (node->right()->IsLiteralNode()) {
      VisitLoadOne(node->left(), EAX);
      __ CompareObject(EAX, node->right()->AsLiteralNode()->literal());
    } else {
      VisitLoadTwo(node->left(), node->right(), EAX, EDX);
      __ cmpl(EAX, EDX);
    }
    if (!IsResultNeeded(node)) {
      return;
    }
    Condition condition = node->kind() == Token::kEQ_STRICT ? EQUAL : NOT_EQUAL;
    if (NodeInfoHasLabels(node)) {
      GenerateConditionalJumps(*(node->info()), condition);
      node->info()->set_labels_used(true);
    } else {
      Label done, is_true;
      __ j(condition, &is_true);
      __ PushObject(bool_false);
      __ jmp(&done);
      __ Bind(&is_true);
      __ PushObject(bool_true);
      __ Bind(&done);
    }
    return;
  }

  if (Token::IsInstanceofOperator(node->kind())) {
    VisitLoadOne(node->left(), EAX);
    ASSERT(node->right()->IsTypeNode());
    GenerateInstanceOf(node->id(),
                       node->token_index(),
                       node->right()->AsTypeNode()->type(),
                       (node->kind() == Token::kISNOT));
    if (!IsResultNeeded(node)) {
      __ popl(EAX);  // Pop the result of the instanceof operation.
    }
    return;
  }

  if (AtIdNodeHasClassAt(node, node->id(), smi_class_, 0)) {
    if (GenerateSmiComparison(node)) {
      // The comparison was handled, code was emitted.
      return;
    }
    // Fall through if condition is not supported.
  } else if (AtIdNodeHasClassAt(node, node->id(), double_class_, 0)) {
    // Double comparison.
    if (GenerateDoubleComparison(node)) {
      return;
    }
  } else if ((node->kind() == Token::kEQ) || (node->kind() == Token::kNE)) {
    // Equality, not-equality comparison of any other type.
    if (GenerateEqualityComparison(node)) {
      return;
    }
  }

  // Fall through here if a comparison was not implemented.
  // TODO(srdjan): Implement for Strings.
  CodeGenerator::VisitComparisonNode(node);
}


void OptimizingCodeGenerator::VisitLoadIndexedNode(LoadIndexedNode* node) {
  const char* kMessage = "Inline indexed access";
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& object_array_class =
      Class::ZoneHandle(object_store->array_class());
  const Class& immutable_object_array_class =
      Class::ZoneHandle(object_store->immutable_array_class());
  if (AtIdNodeHasClassAt(node, node->id(), object_array_class, 0) ||
      AtIdNodeHasClassAt(node, node->id(),
          immutable_object_array_class, 0)) {
    CodeGenInfo array_info(node->array());
    CodeGenInfo index_info(node->index_expr());
    VisitLoadTwo(node->array(), node->index_expr(), EBX, EDX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EBX, EDX, kDeoptLoadIndexedFixedArray);
    const Class& test_class =
        AtIdNodeHasClassAt(node, node->id(), object_array_class, 0) ?
            object_array_class : immutable_object_array_class;
    // Type checks of array.
    if (!array_info.IsClass(test_class)) {
      __ testl(EBX, Immediate(kSmiTagMask));  // Deoptimize if Smi.
      __ j(ZERO, deopt_blob->label());
      __ movl(EAX, FieldAddress(EBX, Object::class_offset()));
      __ CompareObject(EAX, test_class);
      __ j(NOT_EQUAL, deopt_blob->label());
      PropagateBackLocalClass(node->array(), test_class);
    }

    // Type check of index.
    if (!index_info.IsClass(smi_class_)) {
      __ testl(EDX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());
      PropagateBackLocalClass(node->index_expr(), smi_class_);
    }
    // Range check.
    __ cmpl(EDX, FieldAddress(EBX, Array::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());
    // Note that EDX is Smi, i.e, times 2.
    ASSERT(kSmiTagShift == 1);
    __ movl(EAX, FieldAddress(EBX, EDX, TIMES_2, sizeof(RawArray)));
    HandleResult(node, EAX);
    TraceOpt(node, kMessage);
    return;
  }

  if (AtIdNodeHasClassAt(node, node->id(), growable_object_array_class_, 0)) {
    CodeGenInfo array_info(node->array());
    CodeGenInfo index_info(node->index_expr());
    VisitLoadTwo(node->array(), node->index_expr(), EDX, EAX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EDX, EAX, kDeoptLoadIndexedGrowableArray);
    // EAX: index, EDX: array.
    if (!index_info.IsClass(smi_class_)) {
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());  // Not Smi index.
      PropagateBackLocalClass(node->index_expr(), smi_class_);
    }
    if (!array_info.IsClass(growable_object_array_class_)) {
      __ testl(EDX, Immediate(kSmiTagMask));
      __ j(ZERO, deopt_blob->label());  // Array is Smi.
      __ movl(EBX, FieldAddress(EDX, Object::class_offset()));
      __ CompareObject(EBX, growable_object_array_class_);
      __ j(NOT_EQUAL, deopt_blob->label());  // Not GrowableObjectArray.
      PropagateBackLocalClass(node->array(), growable_object_array_class_);
    }
    // Range check: deoptimize if out of bounds.
    __ cmpl(EAX, FieldAddress(EDX, GrowableObjectArray::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());
    __ movl(EDX, FieldAddress(EDX, GrowableObjectArray::data_offset()));
    // Note that EAX is Smi, i.e, times 2.
    ASSERT(kSmiTagShift == 1);
    __ movl(EAX, FieldAddress(EDX, EAX, TIMES_2, sizeof(RawArray)));
    HandleResult(node, EAX);
    return;
  } else {
    // E.g., HashMap.
    TraceNotOpt(node, kMessage);
  }
  CodeGenerator::VisitLoadIndexedNode(node);
}


void OptimizingCodeGenerator::VisitStoreIndexedNode(StoreIndexedNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitStoreIndexedNode(node);
    return;
  }
  Class& class_of_this_array = Class::Handle();
  // Load array and release its CodeGenInfo as value may refer to the same
  // array (e.g. in a[x] += 3). Fixes issue 1570.
  {
    CodeGenInfo array_info(node->array());
    node->array()->Visit(this);
    class_of_this_array = array_info.is_class()->raw();
  }
  // TODO(srdjan): Use VisitLoadTwo and check if index is smi (CodeGenInfo).
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& object_array_class =
      Class::ZoneHandle(object_store->array_class());
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    VisitLoadTwo(node->index_expr(), node->value(), EBX, ECX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EBX, ECX, kDeoptNoTypeFeedback);
    __ jmp(deopt_blob->label());
    return;
  }


  if (AtIdNodeHasClassAt(node, node->id(), object_array_class, 0)) {
    // Release CodeGenInfo of index quickly as it may be used in the value,
    // e.g. a[i] += 3. Fixes issue 1570.
    bool index_is_smi = false;
    {
      CodeGenInfo index_info(node->index_expr());
      node->index_expr()->Visit(this);
      index_is_smi = index_info.IsClass(smi_class_);
    }
    VisitLoadOne(node->value(), ECX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EBX, ECX, kDeoptStoreIndexed);
    __ popl(EBX);  // index.
    __ popl(EAX);  // array.
    // ECX: value, EBX:index, EAX: array.
    // Check class of array.
    if (class_of_this_array.raw() != object_array_class.raw()) {
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(ZERO, deopt_blob->label());  // Array is smi -> deopt.
      __ movl(EDX, FieldAddress(EAX, Object::class_offset()));
      __ CompareObject(EDX, object_array_class);
      __ j(NOT_EQUAL, deopt_blob->label());  // Not ObjectArray -> deopt.
      PropagateBackLocalClass(node->array(), object_array_class);
    }
    // Check class of index.
    if (!index_is_smi) {
      __ testl(EBX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());  // Index not Smi -> deopt.
      PropagateBackLocalClass(node->index_expr(), smi_class_);
    }
    // Range check.
    __ cmpl(EBX, FieldAddress(EAX, Array::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());  // Range error -> deopt.
    ASSERT(kSmiTagShift == 1);
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, EBX, TIMES_2, sizeof(RawArray)),
                       ECX);
    HandleResult(node, ECX);
    return;
  }

  if (AtIdNodeHasClassAt(node, node->id(), growable_object_array_class_, 0)) {
    bool index_is_smi = false;
    // Release CodeGenInfo of index quickly as it may be used in the value,
    // e.g. a[i] += 3. Fixes issue 1570.
    {
      CodeGenInfo index_info(node->index_expr());
      node->index_expr()->Visit(this);
      index_is_smi = index_info.IsClass(smi_class_);
    }
    VisitLoadOne(node->value(), ECX);
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, EAX, EBX, ECX, kDeoptStoreIndexed);
    __ popl(EBX);  // index.
    __ popl(EAX);  // array.
    // ECX: value, EBX:index, EAX: array, EDX: scratch.
    // Check class of array.
    if (class_of_this_array.raw() != growable_object_array_class_.raw()) {
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(ZERO, deopt_blob->label());  // Array is smi -> deopt.
      __ movl(EDX, FieldAddress(EAX, Object::class_offset()));
      __ CompareObject(EDX, growable_object_array_class_);
      __ j(NOT_EQUAL, deopt_blob->label());  // Not GrowableObjectArray.
      PropagateBackLocalClass(node->array(), growable_object_array_class_);
    }
    // Check class of index.
    if (!index_is_smi) {
      __ testl(EBX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());  // Index not Smi -> deopt.
      PropagateBackLocalClass(node->index_expr(), smi_class_);
    }
    // Range check: deoptimize if out of bounds.
    __ cmpl(EBX, FieldAddress(EAX, GrowableObjectArray::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());
    __ movl(EDX, FieldAddress(EAX, GrowableObjectArray::data_offset()));
    // Note that EAX is Smi, i.e, times 2.
    ASSERT(kSmiTagShift == 1);
    __ StoreIntoObject(EDX,
                       FieldAddress(EDX, EBX, TIMES_2, sizeof(RawArray)),
                       ECX);
    HandleResult(node, ECX);
    return;
  }
  node->index_expr()->Visit(this);
  node->value()->Visit(this);
  GenerateStoreIndexed(node->id(), node->token_index(), IsResultNeeded(node));
}


void OptimizingCodeGenerator::VisitForNode(ForNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitForNode(node);
    return;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  node->initializer()->Visit(this);
  SourceLabel* label = node->label();
  Label loop;
  __ Bind(&loop);
  if (node->condition() != NULL) {
    Label iterate_label;
    CodeGenInfo condition_info(node->condition());
    condition_info.set_false_label(label->break_label());
    condition_info.set_true_label(&iterate_label);
    condition_info.set_fallthrough_label(&iterate_label);
    node->condition()->Visit(this);
    if (condition_info.labels_used()) {
      __ Bind(&iterate_label);
    } else {
      __ popl(EAX);
      __ LoadObject(EDX, bool_true);
      __ cmpl(EAX, EDX);
      __ j(NOT_EQUAL, label->break_label());
    }
  }
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ Bind(label->continue_label());
  node->increment()->Visit(this);
  __ jmp(&loop);
  __ Bind(label->break_label());
}


void OptimizingCodeGenerator::VisitDoWhileNode(DoWhileNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitDoWhileNode(node);
    return;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  SourceLabel* label = node->label();
  Label loop;
  __ Bind(&loop);
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ Bind(label->continue_label());
  CodeGenInfo condition_info(node->condition());
  condition_info.set_false_label(label->break_label());
  condition_info.set_true_label(&loop);
  condition_info.set_fallthrough_label(label->break_label());
  node->condition()->Visit(this);
  if (!condition_info.labels_used()) {
    __ popl(EAX);
    __ LoadObject(EDX, bool_true);
    __ cmpl(EAX, EDX);
    __ j(EQUAL, &loop);
  }
  __ Bind(label->break_label());
}


void OptimizingCodeGenerator::VisitWhileNode(WhileNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitWhileNode(node);
    return;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  SourceLabel* label = node->label();
  __ Bind(label->continue_label());
  Label iterate_label;
  CodeGenInfo condition_info(node->condition());
  condition_info.set_false_label(label->break_label());
  condition_info.set_true_label(&iterate_label);
  condition_info.set_fallthrough_label(&iterate_label);
  node->condition()->Visit(this);
  if (condition_info.labels_used()) {
    __ Bind(&iterate_label);
  } else {
    __ popl(EAX);
    __ LoadObject(EDX, bool_true);
    __ cmpl(EAX, EDX);
    __ j(NOT_EQUAL, label->break_label());
  }
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ jmp(label->continue_label());
  __ Bind(label->break_label());
}


void OptimizingCodeGenerator::VisitIfNode(IfNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitIfNode(node);
    return;
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Label false_label, true_label, done;
  CodeGenInfo condition_info(node->condition());
  condition_info.set_false_label(&false_label);
  condition_info.set_true_label(&true_label);
  condition_info.set_fallthrough_label(&true_label);
  node->condition()->Visit(this);
  if (condition_info.labels_used()) {
    __ Bind(&true_label);
  } else {
    __ popl(EAX);
    __ CompareObject(EAX, bool_true);
    __ j(NOT_EQUAL, &false_label);
  }
  node->true_branch()->Visit(this);
  if (node->false_branch() != NULL) {
    Label done;
    __ jmp(&done);
    __ Bind(&false_label);
    node->false_branch()->Visit(this);
    __ Bind(&done);
  } else {
    __ Bind(&false_label);
  }
  __ Bind(&done);
}


void OptimizingCodeGenerator::GenerateDirectCall(
    intptr_t node_id,
    intptr_t token_index,
    const Function& target,
    intptr_t arg_count,
    const Array& optional_argument_names) {
  ASSERT(!target.IsNull());
  const Code& code = Code::Handle(target.CurrentCode());
  ASSERT(!code.IsNull());
  ExternalLabel target_label("DirectInstanceCall", code.EntryPoint());

  __ LoadObject(ECX, target);
  __ LoadObject(EDX, ArgumentsDescriptor(arg_count, optional_argument_names));
  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
  __ addl(ESP, Immediate(arg_count * kWordSize));
}


// Generate inline cache calls instead of deoptimizing when no type feedback is
// provided.
// TODO(srdjan): Recompilation framework should recognize active IC calls
// in optimized code and mark them for reoptimization since type feedback was
// collected in the meantime.
void OptimizingCodeGenerator::GenerateInlineCacheCall(
    intptr_t node_id,
    intptr_t token_index,
    const ICData& ic_data,
    intptr_t num_args,
    const Array& optional_arguments_names) {
  __ LoadObject(ECX, ic_data);
  __ LoadObject(EDX, ArgumentsDescriptor(num_args, optional_arguments_names));
  ExternalLabel target_label(
      "InlineCache", StubCode::OneArgCheckInlineCacheEntryPoint());

  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kIcCall,
                       node_id,
                       token_index);
  __ addl(ESP, Immediate(num_args * kWordSize));
}


// Normalizes the ic_data class/target pairs:
// - If Smi class exists, make it the first one.
// - If 'null_target' not null, append null-class/'null_target'
void OptimizingCodeGenerator::NormalizeClassChecks(
    const ICData& ic_data,
    const Function& null_target,
    GrowableArray<const Class*>* classes,
    GrowableArray<const Function*>* targets) {
  ASSERT(classes != NULL);
  ASSERT(targets != NULL);
  // Check if we can add Smi class in front.
  Class& smi_test_class = Class::Handle();
  Function& smi_target = Function::ZoneHandle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<const Class*> test_classes;
    ic_data.GetCheckAt(i, &test_classes, &smi_target);
    smi_test_class = test_classes[0]->raw();
    if (smi_test_class.raw() == smi_class_.raw()) {
      classes->Add(&Class::ZoneHandle(smi_class_.raw()));
      targets->Add(&Function::ZoneHandle(smi_target.raw()));
      break;
    }
  }
  // Add all classes except Smi.
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    Function& target = Function::ZoneHandle();
    Class& cls = Class::ZoneHandle();
    GrowableArray<const Class*> test_classes;
    ic_data.GetCheckAt(i, &test_classes, &target);
    cls = test_classes[0]->raw();
    ASSERT(!cls.IsNullClass());
    if (cls.raw() != smi_class_.raw()) {
      ASSERT(!cls.IsNull());
      ASSERT(!target.IsNull());
      classes->Add(&cls);
      targets->Add(&target);
    }
  }
  // Do not add a target that has not been compiled yet.
  if (!null_target.IsNull() && null_target.HasCode()) {
    ASSERT(null_target.IsZoneHandle());
    classes->Add(&Class::ZoneHandle(Object::null_class()));
    targets->Add(&null_target);
  }
}


// Use IC data in 'node' to issues checks and calls.
// IC data can contain one or more argument checks.
void OptimizingCodeGenerator::GenerateCheckedInstanceCalls(
    AstNode* node,
    AstNode* receiver,
    intptr_t node_id,
    intptr_t token_index,
    intptr_t num_args,
    const Array& optional_arguments_names) {
  ASSERT(node != NULL);
  ASSERT(receiver != NULL);
  ASSERT(num_args > 0);
  const ICData& ic_data = node->ICDataAtId(node_id);
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback means node was never executed. However that can be
    // a common case especially in case of large switch statements.
    // Use a special inline cache call which can help us decide when to
    // re-optimize this optiumized function.
    GenerateInlineCacheCall(
        node_id, token_index, ic_data, num_args, optional_arguments_names);
    return;
  }

  Function& target_for_null = Function::ZoneHandle();
  ObjectStore* object_store = Isolate::Current()->object_store();
  int num_optional_args =
      optional_arguments_names.IsNull() ? 0 : optional_arguments_names.Length();
  target_for_null = Resolver::ResolveDynamicForReceiverClass(
      Class::Handle(object_store->object_class()),
      String::Handle(ic_data.target_name()),
      num_args,
      num_optional_args);
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  // Make Smi class the first one, if it is in the list.
  NormalizeClassChecks(ic_data, target_for_null, &classes, &targets);
  ASSERT(!classes.is_empty());
  ASSERT(classes.length() == targets.length());
  intptr_t start_ix = 0;

  Label done;
  __ movl(EAX, Address(ESP, (num_args - 1) * kWordSize));  // Load receiver.
  if (classes[0]->raw() == smi_class_.raw()) {
    start_ix++;
    // Smi test is needed.
    __ testl(EAX, Immediate(kSmiTagMask));
    if (classes.length() == 1) {
      // Only Smi test.
      DeoptimizationBlob* deopt_blob =
          AddDeoptimizationBlob(node, kDeoptCheckedInstanceCallSmiOnly);
      __ j(NOT_ZERO, deopt_blob->label());
      GenerateDirectCall(node_id,
                         token_index,
                         *targets[0],
                         num_args,
                         optional_arguments_names);
      return;
    }
    Label not_smi;
    __ j(NOT_ZERO, &not_smi);
    GenerateDirectCall(node_id,
                       token_index,
                       *targets[0],
                       num_args,
                       optional_arguments_names);
    __ jmp(&done);
    __ Bind(&not_smi);  // Continue with other test below.
  } else if (NodeMayBeSmi(receiver)) {
    DeoptimizationBlob* deopt_blob =
        AddDeoptimizationBlob(node, kDeoptCheckedInstanceCallSmiFail);
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
  } else {
    // Receiver cannot be Smi, no need to test it.
  }
  __ movl(EAX, FieldAddress(EAX, Object::class_offset()));  // Receiver's class.
  for (intptr_t i = start_ix; i < classes.length(); i++) {
    const Class& cls = *classes[i];
    const Function& target = *targets[i];
    __ CompareObject(EAX, cls);
    if (i == (classes.length() - 1)) {
      // Last check.
      DeoptimizationBlob* deopt_blob =
          AddDeoptimizationBlob(node, kDeoptCheckedInstanceCallCheckFail);
      __ j(NOT_EQUAL, deopt_blob->label());
      GenerateDirectCall(node_id,
                         token_index,
                         target,
                         num_args,
                         optional_arguments_names);
    } else {
      Label next;
      __ j(NOT_EQUAL, &next);
      GenerateDirectCall(node_id,
                         token_index,
                         target,
                         num_args,
                         optional_arguments_names);
      __ jmp(&done);
      __ Bind(&next);
    }
  }
  __ Bind(&done);
}


void OptimizingCodeGenerator::VisitInstanceCallNode(InstanceCallNode* node) {
  const int number_of_arguments = node->arguments()->length() + 1;
  // Compute the receiver object and pass it as first argument to call.
  node->receiver()->Visit(this);
  // Now compute rest of the arguments to the call.
  node->arguments()->Visit(this);
  if (TryInlineInstanceCall(node)) {
    // Instance call is inlined.
  } else {
    GenerateCheckedInstanceCalls(node,
                                 node->receiver(),
                                 node->id(),
                                 node->token_index(),
                                 number_of_arguments,
                                 node->arguments()->names());
  }
  // Result is in EAX.
  HandleResult(node, EAX);
}


// Returns true if an instance call was replaced with its intrinsic.
// Returns result in EAX.
bool OptimizingCodeGenerator::TryInlineInstanceCall(InstanceCallNode* node) {
  const ZoneGrowableArray<const Class*>* classes = CollectedClassesAtNode(node);
  if ((classes != NULL) && (classes->length() == 1)) {
    const int num_arguments = node->arguments()->length() + 1;
    const int num_named_arguments = node->arguments()->names().IsNull() ?
        0 : node->arguments()->names().Length();
    const Function& target = Function::ZoneHandle(
        Resolver::ResolveDynamicForReceiverClass(*(*classes)[0],
                                                 node->function_name(),
                                                 num_arguments,
                                                 num_named_arguments));
    Recognizer::Kind recognized = Recognizer::RecognizeKind(target);
    if (FLAG_trace_optimization) {
      OS::Print("Monomorphic inline candidate: %s -> %s\n",
          target.ToFullyQualifiedCString(),
          Recognizer::KindToCString(recognized));
    }
    if ((recognized == Recognizer::kIntegerToDouble) &&
        AtIdNodeHasClassAt(node, node->id(), smi_class_, 0)) {
      // TODO(srdjan): Check if we could use temporary double instead of
      // allocating a new object every time.
      const Code& stub =
          Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
      const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
      GenerateCall(node->token_index(), &label, PcDescriptors::kOther);
      // EAX is double object.
      DeoptimizationBlob* deopt_blob =
          AddDeoptimizationBlob(node, EBX, kDeoptIntegerToDouble);
      __ popl(EBX);  // Receiver
      __ testl(EBX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());  // Deoptimize if not Smi.
      __ SmiUntag(EBX);
      __ cvtsi2sd(XMM0, EBX);
      __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
      return true;
    }

    if ((recognized == Recognizer::kDoubleToDouble) &&
        AtIdNodeHasClassAt(node, node->id(), double_class_, 0)) {
      DeoptimizationBlob* deopt_blob =
          AddDeoptimizationBlob(node, EAX, kDeoptDoubleToDouble);
      __ popl(EAX);
      CheckIfDoubleOrSmi(EAX, EBX, deopt_blob->label(), deopt_blob->label());
      return true;
    }
  }
  return false;
}


// TODO(srdjan): For Math.sqrt read type feedback in Math.sqrt and decide
// if the argument is double, smi or something else.
bool OptimizingCodeGenerator::TryInlineStaticCall(StaticCallNode* node) {
  Recognizer::Kind recognized = Recognizer::RecognizeKind(node->function());
  if (false && recognized == Recognizer::kMathSqrt) {
    Label smi_to_double, call_method, done;
    __ movl(EAX, Address(ESP, 0));
    CheckIfDoubleOrSmi(EAX, EBX, &smi_to_double, &call_method);
    __ movsd(XMM1, FieldAddress(EAX, Double::value_offset()));
    __ sqrtsd(XMM0, XMM1);
    AssemblerMacros::TryAllocate(assembler_,
                                 double_class_,
                                 EBX,  // Class register.
                                 &call_method,
                                 EAX);  // Result register.
    __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
    __ jmp(&done);
    __ Bind(&smi_to_double);
    __ Bind(&call_method);
    __ LoadObject(ECX, node->function());
    __ LoadObject(EDX, ArgumentsDescriptor(node->arguments()->length(),
                                           node->arguments()->names()));
    GenerateCall(node->token_index(), &StubCode::CallStaticFunctionLabel(),
                 PcDescriptors::kFuncCall);
    __ Bind(&done);
    return true;
  }
  return false;
}


void OptimizingCodeGenerator::VisitStaticCallNode(StaticCallNode* node) {
  node->arguments()->Visit(this);
  if (TryInlineStaticCall(node)) {
    // Static method is inlined, result is in EAX.
  } else {
    __ LoadObject(ECX, node->function());
    __ LoadObject(EDX, ArgumentsDescriptor(node->arguments()->length(),
                                           node->arguments()->names()));
    GenerateCall(node->token_index(), &StubCode::CallStaticFunctionLabel(),
                 PcDescriptors::kFuncCall);
  }
  __ addl(ESP, Immediate(node->arguments()->length() * kWordSize));
  // Result is in EAX.
  HandleResult(node, EAX);
}


void OptimizingCodeGenerator::VisitReturnNode(ReturnNode* node) {
  if ((node->inlined_finally_list_length() > 0) || FLAG_enable_type_checks) {
    CodeGenerator::VisitReturnNode(node);
    return;
  }
  ASSERT(!IsResultNeeded(node));
  ASSERT(node->value() != NULL);
  CodeGenInfo value_info(node->value());
  value_info.set_request_result_in_eax(true);
  node->value()->Visit(this);
  if (!value_info.result_returned_in_eax()) {
    __ popl(EAX);
  }
  GenerateReturnEpilog(node);
}


void OptimizingCodeGenerator::VisitSequenceNode(SequenceNode* node_sequence) {
  // TODO(srdjan): Allow limited forwarding of types across sequence nodes.
  classes_for_locals_->Clear();
  const intptr_t num_context_variables = (node_sequence->scope() != NULL) ?
      node_sequence->scope()->num_context_variables() : 0;
  if (FLAG_enable_type_checks || (num_context_variables > 0)) {
    CodeGenerator::VisitSequenceNode(node_sequence);
    return;
  }
  for (int i = 0; i < node_sequence->length(); i++) {
    AstNode* child_node = node_sequence->NodeAt(i);
    state()->set_root_node(child_node);
    child_node->Visit(this);
  }
  if (node_sequence->label() != NULL) {
    __ Bind(node_sequence->label()->break_label());
  }
  classes_for_locals_->Clear();
}


void OptimizingCodeGenerator::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitStoreInstanceFieldNode(node);
    return;
  }
  VisitLoadTwo(node->instance(), node->value(), EDX, EAX);
  __ StoreIntoObject(EDX, FieldAddress(EDX, node->field().Offset()), EAX);
  ASSERT(!IsResultNeeded(node));
}


void OptimizingCodeGenerator::VisitCatchClauseNode(CatchClauseNode* node) {
  // TODO(srdjan): Set classes for locals.
  classes_for_locals_->Clear();
  CodeGenerator::VisitCatchClauseNode(node);
}


void OptimizingCodeGenerator::VisitTryCatchNode(TryCatchNode* node) {
  // TODO(srdjan): Set classes for locals.
  classes_for_locals_->Clear();
  CodeGenerator::VisitTryCatchNode(node);
}


void OptimizingCodeGenerator::VisitUnaryOpNode(UnaryOpNode* node) {
  // TODO(srdjan): Test in checked mode if value is Boolean, throw error
  // otherwise.
  if (FLAG_enable_type_checks && node->kind() == Token::kNOT) {
    CodeGenerator::VisitUnaryOpNode(node);
    return;
  }
  // TODO(srdjan): Jump directly to labels instead of returning a boolean.
  if (node->kind() == Token::kNOT) {
    // Only a true bool returns false, everything else is true.
    CodeGenInfo info(node->operand());
    VisitLoadOne(node->operand(), EDX);
    Label done;
    __ LoadObject(EAX, Bool::ZoneHandle(Bool::True()));
    __ cmpl(EDX, EAX);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    __ LoadObject(EAX, Bool::ZoneHandle(Bool::False()));
    __ Bind(&done);
    HandleResult(node, EAX);
    return;
  }

  if ((node->kind() == Token::kSUB) || (node->kind() == Token::kBIT_NOT)) {
    if (AtIdNodeHasClassAt(node, node->id(), smi_class_, 0)) {
      const ICData& ic_data = node->ICDataAtId(node->id());
      ASSERT(ic_data.num_args_tested() == 1);
      GenerateSmiUnaryOp(node);
      return;
    }
  }
  if (node->kind() == Token::kSUB) {
    if (AtIdNodeHasClassAt(node, node->id(), double_class_, 0)) {
      const ICData& ic_data = node->ICDataAtId(node->id());
      ASSERT(ic_data.num_args_tested() == 1);
      GenerateDoubleUnaryOp(node);
      return;
    }
  }
  // TODO(srdjan): Implement unary kSUB (negate) Mint.
  CodeGenerator::VisitUnaryOpNode(node);
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32

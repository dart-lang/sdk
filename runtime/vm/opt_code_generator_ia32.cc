// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/opt_code_generator.h"

#include "vm/assembler_macros.h"
#include "vm/ast_printer.h"
#include "vm/intrinsifier.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler_->

DEFINE_FLAG(bool, trace_optimization, false, "Trace optimizations.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, trace_functions);


// Property list to be used in CodeGenInfo. Each property has a setter
// and a getter of specified type and name.
// (name, type, default)
#define PROPERTY_LIST(V)                                                       \
  V(is_temp, bool, false)                                                      \
  V(true_label, Label*, NULL)                                                  \
  V(false_label, Label*, NULL)                                                 \
  V(labels_used, bool, false)                                                  \
  V(request_result_in_eax, bool, false)                                        \
  V(result_returned_in_eax, bool, false)                                       \
  V(fallthrough_label, Label*, NULL)                                           \
  V(is_class, const Class*, NULL)                                              \


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
    if (is_class() == NULL) {
      return cls.IsNullClass();
    }
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
  explicit DeoptimizationBlob(AstNode* node) : node_(node), registers_(2) {}

  void Push(Register reg) { registers_.Add(reg); }

  void Generate(OptimizingCodeGenerator* codegen) {
    codegen->assembler()->Bind(&label_);
    for (int i = 0; i < registers_.length(); i++) {
      codegen->assembler()->pushl(registers_[i]);
    }
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


static const char* kGrowableArrayClassName = "GrowableObjectArray";
static const char* kGrowableArrayLengthFieldName = "_length";
static const char* kGrowableArrayArrayFieldName = "backingArray";


OptimizingCodeGenerator::OptimizingCodeGenerator(
    Assembler* assembler, const ParsedFunction& parsed_function)
        : CodeGenerator(assembler, parsed_function),
          deoptimization_blobs_(4),
          smi_class_(Class::ZoneHandle(Isolate::Current()->object_store()
              ->smi_class())),
          double_class_(Class::ZoneHandle(Isolate::Current()->object_store()
              ->double_class())) {
  ASSERT(parsed_function.function().is_optimizable());
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node) {
  DeoptimizationBlob* d = new DeoptimizationBlob(node);
  deoptimization_blobs_.Add(d);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node, Register reg) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node);
  d->Push(reg);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               Register reg1,
                                               Register reg2) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node);
  d->Push(reg1);
  d->Push(reg2);
  return d;
}


DeoptimizationBlob*
OptimizingCodeGenerator::AddDeoptimizationBlob(AstNode* node,
                                               Register reg1,
                                               Register reg2,
                                               Register reg3) {
  DeoptimizationBlob* d = AddDeoptimizationBlob(node);
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
  ASSERT(ic_data.NumberOfArgumentsChecked() == 1);
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
  ASSERT(ic_data.NumberOfArgumentsChecked() == 1);
  Function& target = Function::Handle();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    OS::Print("- %s -> %s\n", cls.ToCString(),
        target.ToFullyQualifiedCString());
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


void OptimizingCodeGenerator::IntrinsifyGetter() {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is oad field node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 1);
  ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
  const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
  ASSERT(return_node.value()->IsLoadInstanceFieldNode());
  const LoadInstanceFieldNode& load_node =
      *return_node.value()->AsLoadInstanceFieldNode();
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, load_node.field().Offset()));
  __ ret();
}


void OptimizingCodeGenerator::IntrinsifySetter() {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 2);
  ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
  ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
  const StoreInstanceFieldNode& store_node =
      *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // Receiver.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX, FieldAddress(EAX, store_node.field().Offset()), EBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, raw_null);
  __ ret();
}


bool OptimizingCodeGenerator::TryIntrinsify() {
  if (FLAG_intrinsify && !FLAG_trace_functions) {
    if ((parsed_function_.function().kind() == RawFunction::kImplicitGetter)) {
      IntrinsifyGetter();
      return true;
    }
    if ((parsed_function_.function().kind() == RawFunction::kImplicitSetter)) {
      IntrinsifySetter();
      return true;
    }
  }
  // Even if an intrinsified version of the function was successfully
  // generated, it may fall through to the non-intrinsified method body.
  if (!FLAG_trace_functions) {
    return Intrinsifier::Intrinsify(parsed_function().function(), assembler_);
  }
  return false;
}


// Check for stack overflow.
// Note that first 5 bytes may be patched with a jump.
// TODO(srdjan): Add check that no object is inlined in the first
// 5 bytes (length of a jump instruction).
void OptimizingCodeGenerator::GeneratePreEntryCode() {
  __ cmpl(ESP,
      Address::Absolute(Isolate::Current()->stack_limit_address()));
  __ j(BELOW_EQUAL, &StubCode::StackOverflowLabel());
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
}


void OptimizingCodeGenerator::VisitStoreLocalNode(StoreLocalNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitStoreLocalNode(node);
    return;
  }
  CodeGenInfo value_info(node->value());
  value_info.set_request_result_in_eax(true);
  node->value()->Visit(this);
  if (value_info.is_temp()) {
    if (value_info.IsClass(double_class_)) {
      if (value_info.result_returned_in_eax()) {
        __ pushl(EAX);
      }
      const Code& stub =
          Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
      const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
      GenerateCall(node->token_index(), &label);
      // New allocated object is in EAX; copy value from temporary object.
      __ popl(EDX);  // temporary object from value.
      __ movsd(XMM0, FieldAddress(EDX, Double::value_offset()));
      __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
      CodeGenerator::GenerateStoreVariable(node->local(), EAX, EDX);
    } else {
      UNIMPLEMENTED();  // Cannot handle other temporary types yet.
    }
  } else {
    if (!value_info.result_returned_in_eax()) {
      __ popl(EAX);
    }
    CodeGenerator::GenerateStoreVariable(node->local(), EAX, EDX);
  }
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


static bool NodeHasBothClasses(AstNode* node,
                               const Class& cls1,
                               const Class& cls2) {
  ASSERT(node != NULL);
  ASSERT(!cls1.IsNull() && !cls2.IsNull());

  const ZoneGrowableArray<const Class*>* classes = CollectedClassesAtNode(node);
  if ((classes == NULL) || (classes->length() != 2)) {
    return false;
  }
  if ((cls1.raw() != (*classes)[0]->raw()) &&
      (cls1.raw() != (*classes)[1]->raw())) {
    return false;
  }
  if ((cls2.raw() != (*classes)[0]->raw()) &&
      (cls2.raw() != (*classes)[1]->raw())) {
    return false;
  }
  return true;
}


static bool AtIdNodeHasOnlyClass(AstNode* node, intptr_t id, const Class& cls) {
  ASSERT(node != NULL);
  ASSERT(!cls.IsNull());
  const ICData& ic_data = node->ICDataAtId(id);
  if ((ic_data.NumberOfArgumentsChecked() != 1) ||
      (ic_data.NumberOfChecks() != 1)) {
    return false;
  }
  Class& target_cls = Class::Handle();
  Function& target = Function::Handle();
  ic_data.GetOneClassCheckAt(0, &target_cls, &target);
  return target_cls.raw() == cls.raw();
}



// Implement with slow case so that it can work both with Smi and Mint types.
void OptimizingCodeGenerator::GenerateSmiShiftBinaryOp(BinaryOpNode* node) {
  ASSERT(node->kind() == Token::kSHL);
  Label done;
  bool shift_generated = false;
  if (node->right()->IsLiteralNode() &&
      node->right()->AsLiteralNode()->literal().IsSmi()) {
    // Shift count is a Smi literal.
    Smi& smi = Smi::Handle();
    smi ^= node->right()->AsLiteralNode()->literal().raw();
    if (smi.Value() < Smi::kBits) {
      Label slow_case;
      VisitLoadOne(node->left(), EAX);
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, &slow_case, Assembler::kNearJump);  // left not smi
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
      CodeGenerator::GenerateBinaryOperatorCall(node->id(),
                                                node->token_index(),
                                                node->Name());
      shift_generated = true;
    }
  }

  if (!shift_generated) {
    Label slow_case;
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    // TODO(srdjan): Better code for count being a Smi literal.
    // EAX: value, EDX: shift amount. Preserve them for slow case.
    // Fast case only if both ar Smi.
    __ movl(EBX, EAX);
    __ orl(EBX, EDX);
    __ testl(EBX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case, Assembler::kNearJump);
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
    CodeGenerator::GenerateBinaryOperatorCall(node->id(),
                                              node->token_index(),
                                              node->Name());
    shift_generated = true;
  }
  __ Bind(&done);
}


// TODO(srdjan): Expand inline caches to detect Smi/double operations, so that
// we do not have to call the instance method, and therefore could guarantee
// that the result is a Smi at the end.
void OptimizingCodeGenerator::GenerateSmiBinaryOp(BinaryOpNode* node) {
  const char* kOptMessage = "Inlines BinaryOp for Smi";
  Label done;
  const Token::Kind kind = node->kind();
  if ((kind == Token::kADD) ||
      (kind == Token::kSUB) ||
      (kind == Token::kMUL) ||
      (kind == Token::kBIT_AND) ||
      (kind == Token::kBIT_OR) ||
      (kind == Token::kBIT_XOR)) {
    TraceOpt(node, kOptMessage);
    CodeGenInfo left_info(node->left());
    CodeGenInfo right_info(node->right());
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    Label* overflow_label = NULL;
    Label two_smis, call_operator;
    if (left_info.IsClass(smi_class_) || right_info.IsClass(smi_class_)) {
      DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, ECX, EDX);
      overflow_label = deopt_blob->label();
      __ movl(ECX, EAX);  // Save if overflow (needs original value).
      if (!left_info.IsClass(smi_class_) || !right_info.IsClass(smi_class_)) {
        Register test_reg = left_info.IsClass(smi_class_) ? EDX : EAX;
        __ testl(test_reg, Immediate(kSmiTagMask));
        __ j(NOT_ZERO, deopt_blob->label());
      }
      if (node->info() != NULL) {
        node->info()->set_is_class(&smi_class_);
      }
    } else {
      overflow_label = &call_operator;
      __ movl(ECX, EAX);
      __ orl(EAX, EDX);
      __ testl(EAX, Immediate(kSmiTagMask));
      __ j(ZERO, &two_smis, Assembler::kNearJump);

      // Operator is called either if one of the arguments is not Smi or
      // if we hit an overflow in an arithmetic operation.
      __ Bind(&call_operator);
      // Restore arguments on stack, and dispatch to operator, thus preventing
      // deoptimization in case of smi/non-smi operations. At exit we do not
      // know the result is Smi or not.
      // TODO(srdjan): Handle type feedback for both arguments instead of for
      // receiver only, deoptimize if the type changes.
      __ pushl(ECX);
      __ pushl(EDX);
      GenerateBinaryOperatorCall(node->id(),
                                 node->token_index(),
                                 node->Name());
      __ jmp(&done);
      __ Bind(&two_smis);
      // Restore left operand. EAX will be 'destroyed', ECX holds the left
      // argument, which may be needed for deoptimization.
      __ movl(EAX, ECX);
    }
    switch (kind) {
      case Token::kADD: {
        __ addl(EAX, EDX);
        __ j(OVERFLOW, overflow_label);
        break;
      }
      case Token::kSUB: {
        __ subl(EAX, EDX);
        __ j(OVERFLOW, overflow_label);
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(EAX);
        __ imull(EAX, EDX);
        __ j(OVERFLOW, overflow_label);
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
      default:
        UNREACHABLE();
    }
  } else if (kind == Token::kSHL) {
    GenerateSmiShiftBinaryOp(node);
  } else {
    TraceNotOpt(node, kOptMessage);
    node->left()->Visit(this);
    node->right()->Visit(this);
    CodeGenerator::GenerateBinaryOperatorCall(node->id(),
                                              node->token_index(),
                                              node->Name());
  }
  __ Bind(&done);
  if (CodeGenerator::IsResultNeeded(node)) {
    if (IsResultInEaxRequested(node)) {
      node->info()->set_result_returned_in_eax(true);
    } else {
      __ pushl(EAX);
    }
  }
}


// Supports some mixed Smi/Mint operations.
// For BIT_AND operation with one operand being Smi, we can throw away
// any Mint bits above the Smi range.
// 'allow_smi' is true if Smi and Mint classes have been encountered.
void OptimizingCodeGenerator::GenerateMintBinaryOp(BinaryOpNode* node,
                                                   bool allow_smi) {
  const char* kOptMessage = "Inline Mint binop.";
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Token::Kind kind = node->kind();
  if (kind == Token::kBIT_AND) {
    TraceOpt(node, kOptMessage);
    Label is_smi, slow_case, done;
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX, EDX);
    VisitLoadTwo(node->left(), node->right(), EAX, EDX);
    __ testl(EDX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case);  // Call operator if right is not Smi.

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
    GenerateBinaryOperatorCall(node->id(), node->token_index(), node->Name());
    __ Bind(&done);
    if (CodeGenerator::IsResultNeeded(node)) {
      __ pushl(EAX);
    }
    return;
  }
  if ((kind == Token::kSHL) && allow_smi) {
    GenerateSmiShiftBinaryOp(node);
    if (CodeGenerator::IsResultNeeded(node)) {
      __ pushl(EAX);
    }
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
    return a->AsLoadLocalNode()->local().index() ==
           b->AsLoadLocalNode()->local().index();
  }
  return false;
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


// TODO(srdjan): Detect double/Smi operation and remove extra code to
// always check for Smi on the right hand side.
// Result of the computation is a newly allocated double object or
// a temporary object if the parent node specifies a CodeGenInfo for this node
// and therefore knows how to handle a temporary. A temporary object cannot
// be used for long living values (e.g., the ones stored on stack or into other
// objects).
void OptimizingCodeGenerator::GenerateDoubleBinaryOp(BinaryOpNode* node) {
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
    CodeGenInfo left_info(node->left());
    CodeGenInfo right_info(node->right());
    VisitLoadTwo(node->left(), node->right(), kLeftRegister, kRightRegister);
    // First allocate result object or specify an existing object as result.
    Register result_register = kNoRegister;
    if (node->info() == NULL) {
      // Parent node cannot handle a temporary double object, allocate one
      // each time.
      result_register = kAllocatedRegister;
      const Code& stub =
          Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
      const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
      __ pushl(kLeftRegister);
      __ pushl(kRightRegister);
      GenerateCall(node->token_index(), &label);
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
          Double::ZoneHandle(Double::New(0.0));
      __ LoadObject(result_register, double_object);
    }
    Label is_smi, extract_left;
    DeoptimizationBlob* deopt_blob = NULL;
    Label* deopt_lbl = NULL;
    if (!left_info.IsClass(double_class_) ||
        !right_info.IsClass(double_class_)) {
      deopt_blob = AddDeoptimizationBlob(node, kLeftRegister, kRightRegister);
      deopt_lbl = deopt_blob->label();
    }

    bool nodes_of_same_type = AreNodesOfSameType(node->left(), node->right());
    if (!left_info.IsClass(double_class_)) {
      CheckIfDoubleOrSmi(kLeftRegister, kTempRegister, deopt_lbl, deopt_lbl);
      // Fall through for double. Jump to 'deopt' if not double.
    }
    if (!right_info.IsClass(double_class_) && !nodes_of_same_type) {
      CheckIfDoubleOrSmi(kRightRegister, kTempRegister, &is_smi, deopt_lbl);
      // Fall through for double. Jump to 'is_smi' if double, jump to
      // 'deopt' if neither smi nor double.
      __ movsd(XMM1, FieldAddress(kRightRegister, Double::value_offset()));
      __ jmp(&extract_left);
      __ Bind(&is_smi);
      __ SmiUntag(kRightRegister);
      __ cvtsi2sd(XMM1, kRightRegister);
      __ Bind(&extract_left);
    } else {
      __ movsd(XMM1, FieldAddress(kRightRegister, Double::value_offset()));
    }
    __ movsd(XMM0, FieldAddress(kLeftRegister, Double::value_offset()));

    switch (kind) {
      case Token::kADD: __ addsd(XMM0, XMM1); break;
      case Token::kSUB: __ subsd(XMM0, XMM1); break;
      case Token::kMUL: __ mulsd(XMM0, XMM1); break;
      case Token::kDIV: __ divsd(XMM0, XMM1); break;
      default: UNREACHABLE();
    }
    __ movsd(FieldAddress(result_register, Double::value_offset()), XMM0);
    if (CodeGenerator::IsResultNeeded(node)) {
      if (node->info() != NULL) {
        node->info()->set_is_temp(true);
        node->info()->set_is_class(&double_class_);
      }
      if (IsResultInEaxRequested(node)) {
        __ movl(EAX, result_register);
        node->info()->set_result_returned_in_eax(true);
      } else {
        __ pushl(result_register);
      }
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
    if (IsResultNeeded(node)) {
      __ pushl(EAX);
    }
  }
}


void OptimizingCodeGenerator::VisitBinaryOpNode(BinaryOpNode* node) {
  // Operators "&&" and "||" cannot be overloaded, therefore inline them
  // instead of calling the operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    if (FLAG_enable_type_checks) {
      CodeGenerator::VisitBinaryOpNode(node);
      return;
    }
    GenerateLogicalBinaryOp(node);
    return;
  }

  ObjectStore* object_store = Isolate::Current()->object_store();
  if (AtIdNodeHasOnlyClass(node, node->id(), smi_class_)) {
    GenerateSmiBinaryOp(node);
    return;
  }

  if (AtIdNodeHasOnlyClass(node, node->id(), double_class_)) {
    GenerateDoubleBinaryOp(node);
    return;
  }

  if (AtIdNodeHasOnlyClass(node,
                           node->id(),
                           Class::Handle(object_store->mint_class()))) {
    GenerateMintBinaryOp(node, false);
    return;
  }

  if (NodeHasBothClasses(node,
      smi_class_, Class::Handle(object_store->mint_class()))) {
    GenerateMintBinaryOp(node, true);
    return;
  }

  // Type feedback tells this is not a Smi or Double operation.
  TraceNotOpt(node,
      "BinaryOp: type feedback tells this is not a Smi or Double op");
  CodeGenerator::VisitBinaryOpNode(node);
  return;
}


void OptimizingCodeGenerator::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  if (FLAG_enable_type_checks) {
    CodeGenerator::VisitIncrOpLocalNode(node);
    return;
  }
  const char* kOptMessage = "Inlines IncrOpLocal";
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  if (!AtIdNodeHasOnlyClass(node, node->id(), smi_class_)) {
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
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node);
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
}


// Debugging helper method, used in assert only.
static bool HaveSameClassesInICData(const ICData& a, const ICData& b) {
  if (a.NumberOfChecks() != b.NumberOfChecks()) {
    return false;
  }
  if (a.NumberOfChecks() == 0) {
    return true;
  }
  if (a.NumberOfArgumentsChecked() != b.NumberOfArgumentsChecked()) {
    return false;
  }
  // Only one-argument checks implemented.
  ASSERT(a.NumberOfArgumentsChecked() == 1);
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
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EBX);
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
  if (AtIdNodeHasOnlyClass(node, node->operator_id(), smi_class_)) {
    // Deoptimization point for this node is after receiver has been
    // pushed twice on stack and before the getter (above) was executed.
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EDX, EDX);
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
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EBX);
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
      __ j(EQUAL, &load_field, Assembler::kNearJump);
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
      intptr_t field_offset = GetFieldOffset(
          cls,
          String::Handle(String::NewSymbol(kGrowableArrayLengthFieldName)));
      __ movl(EAX, FieldAddress(EBX, field_offset));
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


// Return true if all targets in 'ic_data' point to same
// inlineable getter target.
static bool ICDataToSameInlineableInstanceSetter(const ICData& ic_data) {
  const Function& target = Function::Handle(GetUniqueTarget(ic_data));
  return !target.IsNull() && (target.kind() == RawFunction::kImplicitSetter);
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
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node);
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
  if (CodeGenerator::IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Clobber EBX leave 'value_reg' untouched.
void OptimizingCodeGenerator::InlineInstanceSettersWithSameTarget(
    AstNode* node,
    intptr_t id,
    AstNode* receiver,
    const String& field_name,
    Register recv_reg,
    Register value_reg) {
  ASSERT((recv_reg != EBX) && (value_reg != EBX));
  DeoptimizationBlob* deopt_blob =
      AddDeoptimizationBlob(node, recv_reg, value_reg);
  if (NodeMayBeSmi(receiver)) {
    __ testl(recv_reg, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
  }
  __ movl(EBX, FieldAddress(recv_reg, Object::class_offset()));
  const ICData& ic_data = node->ICDataAtId(id);
  Function& target = Function::Handle();
  Label store_field;
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    Class& cls = Class::ZoneHandle();
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    __ CompareObject(EBX, cls);
    if (i == (ic_data.NumberOfChecks() - 1)) {
      __ j(NOT_EQUAL, deopt_blob->label());
    } else {
      __ j(EQUAL, &store_field, Assembler::kNearJump);
    }
  }
  Class& cls = Class::Handle();
  ic_data.GetOneClassCheckAt(0, &cls, &target);

  __ Bind(&store_field);
  ASSERT(target.kind() == RawFunction::kImplicitSetter);
  intptr_t field_offset = GetFieldOffset(cls, field_name);
  ASSERT(field_offset >= 0);
  __ StoreIntoObject(recv_reg, FieldAddress(recv_reg, field_offset), value_reg);
}


// Returns value in 'value_reg'.
void OptimizingCodeGenerator::InlineInstanceSetter(AstNode* node,
                                                   intptr_t id,
                                                   AstNode* receiver,
                                                   const String& field_name,
                                                   Register recv_reg,
                                                   Register value_reg) {
  if (ICDataToSameInlineableInstanceSetter(node->ICDataAtId(id))) {
    InlineInstanceSettersWithSameTarget(node,
                                        id,
                                        receiver,
                                        field_name,
                                        recv_reg,
                                        value_reg);
  } else {
    UNIMPLEMENTED();
  }
}


// The call to the instance setter implements the assignment to a field.
// The result of the assignment to a field is the value being stored.
void OptimizingCodeGenerator::VisitInstanceSetterNode(
    InstanceSetterNode* node) {
  // TODO(srdjan): inline setters to different targets as well.
  if (FLAG_enable_type_checks ||
      !ICDataToSameInlineableInstanceSetter(node->ICDataAtId(node->id()))) {
    CodeGenerator::VisitInstanceSetterNode(node);
    return;
  }
  VisitLoadTwo(node->receiver(), node->value(), EDX, EAX);
  const ICData& ic_data = node->ICDataAtId(node->id());
  if (ic_data.NumberOfChecks() == 0) {
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EDX, EAX);
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

  if (CodeGenerator::IsResultNeeded(node)) {
    __ pushl(EAX);
  }
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
  if (!CodeGenerator::IsResultNeeded(node)) {
    return;
  }
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label evaluate_comparison;
  if (!left_info.IsClass(smi_class_)) {
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX, EDX);
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
  if (!CodeGenerator::IsResultNeeded(node)) {
    return true;
  }
  if (left_info.IsClass(smi_class_) && right_info.IsClass(smi_class_)) {
    __ cmpl(EAX, EDX);
  } else if (left_info.IsClass(smi_class_) || right_info.IsClass(smi_class_)) {
    // One is Smi.
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX, EDX);
    Register reg_to_test = left_info.IsClass(smi_class_) ? EDX : EAX;
    __ testl(reg_to_test, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    __ cmpl(EAX, EDX);
  } else {
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, ECX, EDX);
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
  if (!CodeGenerator::IsResultNeeded(node)) {
    return true;
  }
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX, EDX);
  Label compare;
  // Comparison with NULL is "===".
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(EAX, raw_null);
  if (num_classes == 0) {
    __ j(NOT_EQUAL, deopt_blob->label());
  } else {
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
  VisitLoadTwo(node->left(), node->right(), EAX, EDX);
  DeoptimizationBlob* deopt_blob = NULL;
  if (!left_info.IsClass(double_class_) || !right_info.IsClass(double_class_)) {
    deopt_blob = AddDeoptimizationBlob(node, EAX, EDX);
  }
  if (!left_info.IsClass(double_class_)) {
    CheckIfDoubleOrSmi(EAX, EBX, deopt_blob->label(), deopt_blob->label());
  }
  if (!right_info.IsClass(double_class_)) {
    CheckIfDoubleOrSmi(EDX, EBX, deopt_blob->label(), deopt_blob->label());
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
    if (CodeGenerator::IsResultNeeded(node)) {
      __ PushObject(bool_false);
    }
    __ jmp(&done);
    __ Bind(&is_true);
    if (CodeGenerator::IsResultNeeded(node)) {
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
    if (node->right()->IsLiteralNode()) {
      VisitLoadOne(node->left(), EAX);
      __ CompareObject(EAX, node->right()->AsLiteralNode()->literal());
    } else if (node->left()->IsLiteralNode()) {
      VisitLoadOne(node->right(), EAX);
      __ CompareObject(EAX, node->left()->AsLiteralNode()->literal());
    } else {
      VisitLoadTwo(node->left(), node->right(), EAX, EDX);
      __ cmpl(EAX, EDX);
    }
    if (!CodeGenerator::IsResultNeeded(node)) {
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

  if (AtIdNodeHasOnlyClass(node, node->id(), smi_class_)) {
    if (GenerateSmiComparison(node)) {
      return;
    }
    // Fall through if condition is not supported.
  } else if (AtIdNodeHasOnlyClass(node, node->id(), double_class_)) {
    // Double comparison
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
  CodeGenerator::VisitComparisonNode(node);
}


void OptimizingCodeGenerator::VisitLoadIndexedNode(LoadIndexedNode* node) {
  const char* kMessage = "Inline indexed access";
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& object_array_class =
      Class::ZoneHandle(object_store->array_class());
  const Class& immutable_object_array_class =
      Class::ZoneHandle(object_store->immutable_array_class());
  if (AtIdNodeHasOnlyClass(node, node->id(), object_array_class) ||
      AtIdNodeHasOnlyClass(node, node->id(), immutable_object_array_class)) {
    VisitLoadTwo(node->array(), node->index_expr(), EBX, EDX);
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EBX, EDX);
    const Class& test_class =
        AtIdNodeHasOnlyClass(node, node->id(), object_array_class) ?
            object_array_class : immutable_object_array_class;
    // Type checks of array.
    __ testl(EBX, Immediate(kSmiTagMask));  // Deoptimize if Smi.
    __ j(ZERO, deopt_blob->label());
    __ movl(EAX, FieldAddress(EBX, Object::class_offset()));
    __ CompareObject(EAX, test_class);
    __ j(NOT_EQUAL, deopt_blob->label());

    // Type check of index.
    __ testl(EDX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());
    // Range check.
    __ cmpl(EDX, FieldAddress(EBX, Array::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());
    // Note that EDX is Smi, i.e, times 2.
    ASSERT(kSmiTagShift == 1);
    __ movl(EAX, FieldAddress(EBX, EDX, TIMES_2, sizeof(RawArray)));
    if (CodeGenerator::IsResultNeeded(node)) {
      __ pushl(EAX);
    }
    TraceOpt(node, kMessage);
    return;
  }

  const String& growable_object_array_class_name = String::Handle(
      String::NewSymbol(kGrowableArrayClassName));
  const Class& growable_array_class = Class::ZoneHandle(
      Library::Handle(Library::CoreImplLibrary()).
          LookupClass(growable_object_array_class_name));
  if (AtIdNodeHasOnlyClass(node, node->id(), growable_array_class)) {
    const String& growable_array_length_field_name =
        String::Handle(String::NewSymbol(kGrowableArrayLengthFieldName));
    const String& growable_array_array_field_name =
        String::Handle(String::NewSymbol(kGrowableArrayArrayFieldName));
    intptr_t length_offset = GetFieldOffset(growable_array_class,
                                            growable_array_length_field_name);
    intptr_t array_offset = GetFieldOffset(growable_array_class,
                                           growable_array_array_field_name);
    VisitLoadTwo(node->array(), node->index_expr(), EDX, EAX);
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EDX, EAX);
    // TODO(srdjan): Use CodeGenInfo to eliminate Smi test if possible.
    // EAX: index, EDX: array.
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());  // Not Smi index.
    __ testl(EDX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());  // Array is Smi.
    __ movl(EBX, FieldAddress(EDX, Object::class_offset()));
    __ CompareObject(EBX, growable_array_class);
    __ j(NOT_EQUAL, deopt_blob->label());  // Array is not GrowableObjectArray.
    // Range check: deoptimize if out of bounds.
    __ cmpl(EAX, FieldAddress(EDX, length_offset));
    __ j(ABOVE_EQUAL, deopt_blob->label());
    __ movl(EDX, FieldAddress(EDX, array_offset));  // backingArray.
    // Note that EAX is Smi, i.e, times 2.
    ASSERT(kSmiTagShift == 1);
    __ movl(EAX, FieldAddress(EDX, EAX, TIMES_2, sizeof(RawArray)));
    if (CodeGenerator::IsResultNeeded(node)) {
      __ pushl(EAX);
    }
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
  node->array()->Visit(this);
  // TODO(srdjan): Use VisitLoadTwo and check if index is smi (CodeGenInfo).
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& object_array_class =
      Class::ZoneHandle(object_store->array_class());
  if (AtIdNodeHasOnlyClass(node, node->id(), object_array_class)) {
    VisitLoadTwo(node->index_expr(), node->value(), EBX, ECX);
    DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX, EBX, ECX);
    __ popl(EAX);  // array.
    // ECX: value, EBX:index, EAX: array.
    // Check type of array.
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());  // Array is smi -> deopt.
    __ movl(EDX, FieldAddress(EAX, Object::class_offset()));
    __ CompareObject(EDX, object_array_class);
    __ j(NOT_EQUAL, deopt_blob->label());  // Not ObjectArray -> deopt.
    // Check type of index.
    __ testl(EBX, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt_blob->label());  // Index not Smi -> deopt.
    // Range check.
    __ cmpl(EBX, FieldAddress(EAX, Array::length_offset()));
    __ j(ABOVE_EQUAL, deopt_blob->label());  // Range error -> deopt.
    ASSERT(kSmiTagShift == 1);
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, EBX, TIMES_2, sizeof(RawArray)),
                       ECX);
    if (CodeGenerator::IsResultNeeded(node)) {
      __ pushl(ECX);
    }
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
    Function& target,
    intptr_t arg_count,
    const Array& optional_argument_names) {
  ASSERT(!target.IsNull());
  const Code& code = Code::Handle(target.code());
  ASSERT(!code.IsNull());
  ExternalLabel target_label("DirectInstanceCall", code.EntryPoint());

  __ LoadObject(ECX, target);
  __ LoadObject(EDX, ArgumentsDescriptor(arg_count, optional_argument_names));
  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
  __ addl(ESP, Immediate(arg_count * kWordSize));
}


// Use ICData in 'node' to issues checks and calls.
void OptimizingCodeGenerator::GenerateCheckedInstanceCalls(
    AstNode* node,
    AstNode* receiver,
    intptr_t node_id,
    intptr_t token_index,
    intptr_t num_args,
    const Array& optional_argument_names) {
  ASSERT(node != NULL);
  ASSERT(receiver != NULL);
  ASSERT(num_args > 0);
  DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node);
  const ICData& ic_data = node->ICDataAtId(node_id);
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback means node was never executed.
    __ jmp(deopt_blob->label());
    return;
  }
  ASSERT(ic_data.NumberOfArgumentsChecked() == 1);

  // First test for Smi. Null object will cause deoptimization.
  intptr_t smi_class_index = -1;
  Class& smi_test_class = Class::Handle();
  Function& smi_target = Function::ZoneHandle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetOneClassCheckAt(i, &smi_test_class, &smi_target);
    if (smi_test_class.raw() == smi_class_.raw()) {
      smi_class_index = i;
      break;
    }
  }

  Label done;
  __ movl(EAX, Address(ESP, (num_args - 1) * kWordSize));  // Load receiver.
  if (smi_class_index >= 0) {
    // Smi test is needed.
    __ testl(EAX, Immediate(kSmiTagMask));
    if (ic_data.NumberOfChecks() == 1) {
      // Only the Smi test.
      __ j(NOT_ZERO, deopt_blob->label());
      GenerateDirectCall(node_id,
                         token_index,
                         smi_target,
                         num_args,
                         optional_argument_names);
      return;
    }
    Label not_smi;
    __ j(NOT_ZERO, &not_smi);
    GenerateDirectCall(node_id,
                       token_index,
                       smi_target,
                       num_args,
                       optional_argument_names);
    __ jmp(&done);
    __ Bind(&not_smi);  // Continue with other test below.
  } else if (NodeMayBeSmi(receiver)) {
    __ testl(EAX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt_blob->label());
  } else {
    // Receiver cannot be Smi, no need to test it.
  }

  intptr_t last_check_at = (smi_class_index == ic_data.NumberOfChecks() - 1) ?
      ic_data.NumberOfChecks() - 2 : ic_data.NumberOfChecks() - 1;
  // Every class may appear only once in the 'classes' array. Therefore, if
  // Smi class is last, it cannot be the second to last.
  __ movl(EAX, FieldAddress(EAX, Object::class_offset()));  // Receiver's class.
  for (intptr_t i = 0; i <= last_check_at; i++) {
    Function& target = Function::ZoneHandle();
    Class& cls = Class::ZoneHandle();
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    ASSERT(!cls.IsNullClass());
    if (cls.raw() == smi_class_.raw()) {
      ASSERT(i < last_check_at);  // Smi class may not be last.
      continue;  // Skip Smi test.
    }
    __ CompareObject(EAX, cls);
    if (i == last_check_at) {
      __ j(NOT_EQUAL, deopt_blob->label());
      GenerateDirectCall(node_id,
                         token_index,
                         target,
                         num_args,
                         optional_argument_names);
    } else {
      Label next;
      __ j(NOT_EQUAL, &next);
      GenerateDirectCall(node_id,
                         token_index,
                         target,
                         num_args,
                         optional_argument_names);
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
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
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
        AtIdNodeHasOnlyClass(node, node->id(), smi_class_)) {
      // TODO(srdjan): Check if we could use temporary double instead of
      // allocating a new object every time.
      const Code& stub =
          Code::Handle(StubCode::GetAllocationStubForClass(double_class_));
      const ExternalLabel label(double_class_.ToCString(), stub.EntryPoint());
      GenerateCall(node->token_index(), &label);
      // EAX is double object.
      DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EBX);
      __ popl(EBX);  // Receiver
      __ testl(EBX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, deopt_blob->label());  // Deoptimize if not Smi.
      __ SmiUntag(EBX);
      __ cvtsi2sd(XMM0, EBX);
      __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
      return true;
    }

    if ((recognized == Recognizer::kDoubleToDouble) &&
        AtIdNodeHasOnlyClass(node, node->id(), double_class_)) {
      DeoptimizationBlob* deopt_blob = AddDeoptimizationBlob(node, EAX);
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
    GenerateCall(node->token_index(), &StubCode::CallStaticFunctionLabel());
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
    GenerateCall(node->token_index(), &StubCode::CallStaticFunctionLabel());
  }
  __ addl(ESP, Immediate(node->arguments()->length() * kWordSize));
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32

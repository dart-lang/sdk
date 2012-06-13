// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/flow_graph_builder.h"
#include "vm/il_printer.h"
#include "vm/object_store.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, trace_optimization);

// TODO(srdjan): Add _ByteArrayBase, get:length.

#define RECOGNIZED_LIST(V)                                                     \
  V(ObjectArray, get:length, ObjectArrayLength)                                \
  V(ImmutableArray, get:length, ImmutableArrayLength)                          \
  V(GrowableObjectArray, get:length, GrowableArrayLength)                      \
  V(StringBase, get:length, StringBaseLength)                                  \
  V(IntegerImplementation, toDouble, IntegerToDouble)                          \
  V(Double, toDouble, DoubleToDouble)                                          \
  V(Math, sqrt, MathSqrt)                                                      \

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name) k##enum_name,
RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
  };

  static Kind RecognizeKind(const Function& function) {
    // Only core library methods can be recognized.
    const Library& core_lib = Library::Handle(Library::CoreLibrary());
    const Library& core_impl_lib = Library::Handle(Library::CoreImplLibrary());
    const Class& function_class = Class::Handle(function.owner());
    if ((function_class.library() != core_lib.raw()) &&
        (function_class.library() != core_impl_lib.raw())) {
      return kUnknown;
    }
    const String& recognize_name = String::Handle(function.name());
    const String& recognize_class = String::Handle(function_class.Name());
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
};


void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
  if (FLAG_print_flow_graph) {
    OS::Print("After Optimizations:\n");
    FlowGraphPrinter printer(Function::Handle(), block_order_);
    printer.PrintBlocks();
  }
}


void FlowGraphOptimizer::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    Instruction* instr = block_order_[i]->Accept(this);
    // Optimize all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      instr = instr->Accept(this);
    }
  }
}


static bool ICDataHasReceiverClass(const ICData& ic_data, const Class& cls) {
  ASSERT(!cls.IsNull());
  ASSERT(ic_data.num_args_tested() > 0);
  Class& test_class = Class::Handle();
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetOneClassCheckAt(i, &test_class, &target);
    if (cls.raw() == test_class.raw()) {
      return true;
    }
  }
  return false;
}


static bool ICDataHasTwoReceiverClasses(const ICData& ic_data,
                                        const Class& cls1,
                                        const Class& cls2) {
  ASSERT(!cls1.IsNull() && !cls2.IsNull());
  if (ic_data.num_args_tested() != 2) {
    return false;
  }
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<const Class*> classes;
    ic_data.GetCheckAt(i, &classes, &target);
    ASSERT(classes.length() == 2);
    if (classes[0]->raw() == cls1.raw()) {
      if (classes[1]->raw() == cls2.raw()) {
        return true;
      }
    }
  }
  return false;
}


static bool HasOneSmi(const ICData& ic_data) {
  const Class& smi_class =
      Class::Handle(Isolate::Current()->object_store()->smi_class());
  return ICDataHasReceiverClass(ic_data, smi_class);
}


static bool HasTwoSmi(const ICData& ic_data) {
  const Class& smi_class =
      Class::Handle(Isolate::Current()->object_store()->smi_class());
  return ICDataHasTwoReceiverClasses(ic_data, smi_class, smi_class);
}


static bool HasOneDouble(const ICData& ic_data) {
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  return ICDataHasReceiverClass(ic_data, double_class);
}


static bool HasTwoDouble(const ICData& ic_data) {
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  return ICDataHasTwoReceiverClasses(ic_data, double_class, double_class);
}


void FlowGraphOptimizer::TryReplaceWithBinaryOp(InstanceCallComp* comp,
                                                Token::Kind op_kind) {
  if (comp->ic_data()->NumberOfChecks() != 1) {
    // TODO(srdjan): Not yet supported.
    return;
  }

  BinaryOpComp::OperandsType operands_type;

  if (HasTwoSmi(*comp->ic_data())) {
    if (op_kind == Token::kDIV ||
        op_kind == Token::kMOD) {
      // TODO(srdjan): Not yet supported.
      return;
    }

    operands_type = BinaryOpComp::kSmiOperands;
  } else if (HasTwoDouble(*comp->ic_data())) {
    if (op_kind != Token::kADD &&
        op_kind != Token::kSUB &&
        op_kind != Token::kMUL &&
        op_kind != Token::kDIV) {
      // TODO(vegorov): Not yet supported.
      return;
    }

    operands_type = BinaryOpComp::kDoubleOperands;
  } else {
    // TODO(srdjan): Not yet supported.
    return;
  }

  ASSERT(comp->instr() != NULL);
  ASSERT(comp->InputCount() == 2);
  Value* left = comp->InputAt(0);
  Value* right = comp->InputAt(1);
  BinaryOpComp* bin_op =
      new BinaryOpComp(op_kind,
                       operands_type,
                       comp,
                       left,
                       right);
  ASSERT(bin_op->ic_data() == NULL);
  bin_op->set_ic_data(comp->ic_data());
  bin_op->set_instr(comp->instr());
  comp->instr()->replace_computation(bin_op);
}


void FlowGraphOptimizer::TryReplaceWithUnaryOp(InstanceCallComp* comp,
                                              Token::Kind op_kind) {
  if (comp->ic_data()->NumberOfChecks() != 1) {
    // TODO(srdjan): Not yet supported.
    return;
  }
  ASSERT(comp->instr() != NULL);
  ASSERT(comp->InputCount() == 1);
  Computation* unary_op = NULL;
  if (HasOneSmi(*comp->ic_data())) {
    unary_op = new UnarySmiOpComp(op_kind, comp, comp->InputAt(0));
  } else if (HasOneDouble(*comp->ic_data()) && (op_kind == Token::kNEGATE)) {
    unary_op = new NumberNegateComp(comp, comp->InputAt(0));
  }
  if (unary_op != NULL) {
    ASSERT(unary_op->ic_data() == NULL);
    unary_op->set_ic_data(comp->ic_data());
    unary_op->set_instr(comp->instr());
    comp->instr()->replace_computation(unary_op);
  }
}


// Returns true if all targets are the same.
// TODO(srdjan): if targets are native use their C_function to compare.
static bool HasOneTarget(const ICData& ic_data) {
  ASSERT(ic_data.NumberOfChecks() > 0);
  Function& prev_target = Function::Handle();
  GrowableArray<const Class*> classes;
  ic_data.GetCheckAt(0, &classes, &prev_target);
  ASSERT(!prev_target.IsNull());
  Function& target = Function::Handle();
  for (intptr_t i = 1; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetCheckAt(i, &classes, &target);
    ASSERT(!target.IsNull());
    if (prev_target.raw() != target.raw()) {
      return false;
    }
    prev_target = target.raw();
  }
  return true;
}


// Using field class
static RawField* GetField(const Class& field_class, const String& field_name) {
  Class& cls = Class::Handle(field_class.raw());
  Field& field = Field::Handle();
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      return field.raw();
    }
    cls = cls.SuperClass();
  }
  return Field::null();
}


// Returns array of all class ids that are in ic_data. The result is
// normalized so that a smi class is at index 0 if it exists in the ic_data.
static ZoneGrowableArray<intptr_t>*  ExtractClassIds(const ICData& ic_data) {
  if (ic_data.NumberOfChecks() == 0) return NULL;
  ZoneGrowableArray<intptr_t>* result =
      new ZoneGrowableArray<intptr_t>(ic_data.NumberOfChecks());
  intptr_t smi_index = -1;
  Function& target = Function::Handle();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetOneClassCheckAt(i, &cls, &target);
    result->Add(cls.id());
    if (cls.id() == kSmi) {
      ASSERT(smi_index < 0);  // Classes entered only once in ic_data.
      smi_index = i;
    }
  }
  if (smi_index >= 0) {
    // Smi class id must be at index 0.
    intptr_t temp = (*result)[0];
    (*result)[0] =  (*result)[smi_index];
    (*result)[smi_index] = temp;
  }
  return result;
}


// Only unique implicit instance getters can be currently handled.
void FlowGraphOptimizer::TryInlineInstanceGetter(InstanceCallComp* comp) {
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return;
  }
  Function& target = Function::Handle();
  GrowableArray<const Class*> classes;
  ic_data.GetCheckAt(0, &classes, &target);
  ASSERT(classes.length() == 1);

  if (target.kind() == RawFunction::kImplicitGetter) {
    if (!HasOneTarget(ic_data)) {
      // TODO(srdjan): Implement for mutiple targets.
      return;
    }
    // Inline implicit instance getter.
    const String& field_name =
        String::Handle(Field::NameFromGetter(comp->function_name()));
    const Field& field = Field::Handle(GetField(*classes[0], field_name));
    ASSERT(!field.IsNull());
    LoadInstanceFieldComp* load = new LoadInstanceFieldComp(
        field, comp->InputAt(0), comp, ExtractClassIds(ic_data));
    // Replace 'comp' with 'load'.
    load->set_instr(comp->instr());
    comp->instr()->replace_computation(load);
    return;
  }

  // Not an implicit getter.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  // VM objects length getter.
  if ((recognized_kind == MethodRecognizer::kObjectArrayLength) ||
      (recognized_kind == MethodRecognizer::kImmutableArrayLength) ||
      (recognized_kind == MethodRecognizer::kGrowableArrayLength)) {
    if (!HasOneTarget(ic_data)) {
      // TODO(srdjan): Implement for mutiple targets.
      return;
    }
    intptr_t length_offset = -1;
    switch (recognized_kind) {
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
        length_offset = Array::length_offset();
        break;
      case MethodRecognizer::kGrowableArrayLength:
        length_offset = GrowableObjectArray::length_offset();
        break;
      default:
        UNREACHABLE();
    }
    LoadVMFieldComp* load = new LoadVMFieldComp(
        comp->InputAt(0),
        length_offset,
        Type::ZoneHandle(Type::IntInterface()),
        comp,
        ExtractClassIds(ic_data));
    load->set_instr(comp->instr());
    comp->instr()->replace_computation(load);
    return;
  }

  if (recognized_kind == MethodRecognizer::kStringBaseLength) {
    ASSERT(HasOneTarget(ic_data));
    LoadVMFieldComp* load = new LoadVMFieldComp(
        comp->InputAt(0),
        String::length_offset(),
        Type::ZoneHandle(Type::IntInterface()),
        comp,
        ExtractClassIds(ic_data));
    load->set_instr(comp->instr());
    comp->instr()->replace_computation(load);
    return;
  }
}


// Inline only simple, frequently called core library methods.
void FlowGraphOptimizer::TryInlineInstanceMethod(InstanceCallComp* comp) {
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
  if ((ic_data.NumberOfChecks() == 0) || !HasOneTarget(ic_data)) {
    // No type feedback collected.
    return;
  }
  Function& target = Function::Handle();
  GrowableArray<const Class*> classes;
  ic_data.GetCheckAt(0, &classes, &target);
  ASSERT(classes.length() == 1);
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  ObjectKind from_kind;
  if (recognized_kind == MethodRecognizer::kDoubleToDouble) {
    from_kind = kDouble;
  } else if (recognized_kind == MethodRecognizer::kIntegerToDouble) {
    from_kind = kSmi;
  } else {
    return;
  }

  if (classes[0]->id() != from_kind) {
    return;
  }

  ToDoubleComp* coerce = new ToDoubleComp(
      comp->InputAt(0), from_kind, comp);
  coerce->set_instr(comp->instr());
  comp->instr()->replace_computation(coerce);
}


void FlowGraphOptimizer::VisitInstanceCall(InstanceCallComp* comp) {
  if (comp->HasICData()) {
    const String& function_name = comp->function_name();
    Token::Kind op_kind = Token::GetBinaryOp(function_name);
    if (op_kind != Token::kILLEGAL) {
      TryReplaceWithBinaryOp(comp, op_kind);
      return;
    }
    op_kind = Token::GetUnaryOp(function_name);
    if (op_kind != Token::kILLEGAL) {
      TryReplaceWithUnaryOp(comp, op_kind);
      return;
    }
    if (Field::IsGetterName(function_name)) {
      TryInlineInstanceGetter(comp);
      return;
    }
    TryInlineInstanceMethod(comp);
  }
}


void FlowGraphOptimizer::VisitStaticCall(StaticCallComp* comp) {
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(comp->function());
  if (recognized_kind == MethodRecognizer::kMathSqrt) {
    // TODO(srdjan): Implement this.
  }
}


void FlowGraphOptimizer::TryInlineInstanceSetter(InstanceSetterComp* comp) {
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return;
  }
  if (!HasOneTarget(ic_data)) {
    // TODO(srdjan): Implement when not all targets are the sa,e.
    return;
  }
  Function& target = Function::Handle();
  Class& cls = Class::Handle();
  ic_data.GetOneClassCheckAt(0, &cls, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Not an implicit setter.
    // TODO(srdjan): Inline special setters.
    return;
  }
  // Inline implicit instance setter.
  const Field& field = Field::Handle(GetField(cls, comp->field_name()));
  ASSERT(!field.IsNull());
  StoreInstanceFieldComp* store = new StoreInstanceFieldComp(
      field,
      comp->InputAt(0),
      comp->InputAt(1),
      comp,
      ExtractClassIds(ic_data));
  // Replace 'comp' with 'store'.
  store->set_instr(comp->instr());
  comp->instr()->replace_computation(store);
}



void FlowGraphOptimizer::VisitInstanceSetter(InstanceSetterComp* comp) {
  // TODO(srdjan): Add assigneable check node if --enable_type_checks.
  if (comp->HasICData() && !FLAG_enable_type_checks) {
    TryInlineInstanceSetter(comp);
  }
}


enum IndexedAccessType {
  kIndexedLoad,
  kIndexedStore
};


static intptr_t ReceiverClassId(Computation* comp) {
  if (!comp->HasICData()) return kIllegalObjectKind;

  const ICData& ic_data = *comp->ic_data();

  if (ic_data.NumberOfChecks() == 0) return kIllegalObjectKind;
  // TODO(vegorov): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return kIllegalObjectKind;
  ASSERT(HasOneTarget(ic_data));

  Function& target = Function::Handle();
  Class& cls = Class::Handle();
  ic_data.GetOneClassCheckAt(0, &cls, &target);

  return cls.id();
}


void FlowGraphOptimizer::VisitLoadIndexed(LoadIndexedComp* comp) {
  const intptr_t class_id = ReceiverClassId(comp);
  switch (class_id) {
    case kArray:
    case kImmutableArray:
    case kGrowableObjectArray:
      comp->set_receiver_type(static_cast<ObjectKind>(class_id));
  }
}


void FlowGraphOptimizer::VisitStoreIndexed(StoreIndexedComp* comp) {
  if (FLAG_enable_type_checks) return;

  const intptr_t class_id = ReceiverClassId(comp);
  switch (class_id) {
    case kArray:
    case kGrowableObjectArray:
      comp->set_receiver_type(static_cast<ObjectKind>(class_id));
  }
}


void FlowGraphOptimizer::VisitRelationalOp(RelationalOpComp* comp) {
  if (!comp->HasICData()) return;

  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) return;
  // TODO(srdjan): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return;
  ASSERT(HasOneTarget(ic_data));

  if (HasTwoSmi(ic_data)) {
    comp->set_operands_class_id(kSmi);
  } else if (HasTwoDouble(ic_data)) {
    comp->set_operands_class_id(kDouble);
  }
}


void FlowGraphOptimizer::VisitDo(DoInstr* instr) {
  instr->computation()->Accept(this);
}


void FlowGraphOptimizer::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this);
}


}  // namespace dart

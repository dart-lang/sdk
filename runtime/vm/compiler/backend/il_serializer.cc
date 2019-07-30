// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_serializer.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(bool,
            serialize_flow_graph_types,
            true,
            "Serialize inferred type information in flow graphs"
            " (with --serialize_flow_graphs_to)");

DEFINE_FLAG(bool,
            verbose_flow_graph_serialization,
            false,
            "Serialize extra information useful for debugging"
            " (with --serialize_flow_graphs_to)");

DEFINE_FLAG(bool,
            pretty_print_serialization,
            false,
            "Format serialized output nicely"
            " (with --serialize_flow_graphs_to)");

const char* const FlowGraphSerializer::initial_indent = "";

void FlowGraphSerializer::SerializeToBuffer(const FlowGraph* flow_graph,
                                            TextBuffer* buffer) {
  SerializeToBuffer(flow_graph->zone(), flow_graph, buffer);
}

void FlowGraphSerializer::SerializeToBuffer(Zone* zone,
                                            const FlowGraph* flow_graph,
                                            TextBuffer* buffer) {
  ASSERT(buffer != nullptr);
  FlowGraphSerializer serializer(zone, flow_graph);
  auto sexp = serializer.FunctionToSExp();
  if (FLAG_pretty_print_serialization) {
    sexp->SerializeTo(serializer.zone(), buffer, initial_indent);
  } else {
    sexp->SerializeToLine(buffer);
  }
  buffer->AddString("\n\n");
}

void FlowGraphSerializer::AddBool(SExpList* sexp, bool b) {
  sexp->Add(new (zone()) SExpBool(b));
}

void FlowGraphSerializer::AddInteger(SExpList* sexp, intptr_t i) {
  sexp->Add(new (zone()) SExpInteger(i));
}

void FlowGraphSerializer::AddString(SExpList* sexp, const char* cstr) {
  sexp->Add(new (zone()) SExpString(cstr));
}

void FlowGraphSerializer::AddSymbol(SExpList* sexp, const char* cstr) {
  sexp->Add(new (zone()) SExpSymbol(cstr));
}

void FlowGraphSerializer::AddExtraBool(SExpList* sexp,
                                       const char* label,
                                       bool b) {
  sexp->AddExtra(label, new (zone()) SExpBool(b));
}

void FlowGraphSerializer::AddExtraInteger(SExpList* sexp,
                                          const char* label,
                                          intptr_t i) {
  sexp->AddExtra(label, new (zone()) SExpInteger(i));
}

void FlowGraphSerializer::AddExtraString(SExpList* sexp,
                                         const char* label,
                                         const char* cstr) {
  sexp->AddExtra(label, new (zone()) SExpString(cstr));
}

void FlowGraphSerializer::AddExtraSymbol(SExpList* sexp,
                                         const char* label,
                                         const char* cstr) {
  sexp->AddExtra(label, new (zone()) SExpSymbol(cstr));
}

SExpression* FlowGraphSerializer::BlockIdToSExp(intptr_t block_id) {
  return new (zone()) SExpSymbol(OS::SCreate(zone(), "B%" Pd "", block_id));
}

void FlowGraphSerializer::SerializeCanonicalName(TextBuffer* b,
                                                 const Object& obj) {
  if (obj.IsFunction()) {
    const auto& function = Function::Cast(obj);
    tmp_string_ = function.UserVisibleName();
    const char* function_name = tmp_string_.ToCString();
    // If this function is an inner closure then the parent points to its
    // containing function, which will also be part of the canonical name.
    if (function.parent_function() != Function::null()) {
      tmp_function_ = function.parent_function();
      SerializeCanonicalName(b, tmp_function_);
    } else {
      tmp_class_ = function.Owner();
      ASSERT(!tmp_class_.IsNull());
      SerializeCanonicalName(b, tmp_class_);
    }
    b->Printf(":%s", function_name);
  } else if (obj.IsClass()) {
    const auto& cls = Class::Cast(obj);
    tmp_string_ = cls.ScrubbedName();
    const char* class_name = tmp_string_.ToCString();
    tmp_library_ = cls.library();
    if (!tmp_library_.IsNull()) {
      SerializeCanonicalName(b, tmp_library_);
    }
    b->Printf(":%s", class_name);
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    tmp_string_ = lib.url();
    const char* lib_name = tmp_string_.ToCString();
    if (lib_name[0] == '\0') return;
    b->AddString(lib_name);
  } else if (obj.IsField()) {
    const auto& field = Field::Cast(obj);
    tmp_string_ = field.UserVisibleName();
    const char* field_name = tmp_string_.ToCString();
    tmp_class_ = field.Owner();
    ASSERT(!tmp_class_.IsNull());
    SerializeCanonicalName(b, tmp_class_);
    b->Printf(".%s", field_name);
  } else {
    UNREACHABLE();
  }
}

SExpression* FlowGraphSerializer::CanonicalNameToSExp(const Object& obj) {
  TextBuffer b(100);
  SerializeCanonicalName(&b, obj);
  return new (zone()) SExpSymbol(OS::SCreate(zone(), "%s", b.buf()));
}

SExpression* FlowGraphSerializer::BlockEntryToSExp(const char* entry_name,
                                                   BlockEntryInstr* entry) {
  auto sexp = new (zone()) SExpList(zone());
  const auto tag_cstr = OS::SCreate(zone(), "%s-entry", entry_name);
  sexp->Add(new (zone()) SExpSymbol(tag_cstr));
  sexp->Add(BlockIdToSExp(entry->block_id()));
  if (auto with_defs = entry->AsBlockEntryWithInitialDefs()) {
    auto initial_defs = with_defs->initial_definitions();
    for (intptr_t i = 0; i < initial_defs->length(); i++) {
      sexp->Add(initial_defs->At(i)->ToSExpression(this));
    }
  } else if (auto join = entry->AsJoinEntry()) {
    if (auto phi_list = join->phis()) {
      for (intptr_t i = 0; i < phi_list->length(); i++) {
        sexp->Add(phi_list->At(i)->ToSExpression(this));
      }
    }
  }
  return sexp;
}

SExpression* FlowGraphSerializer::FunctionToSExp() {
  auto start = flow_graph()->graph_entry();
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "function");
  sexp->Add(CanonicalNameToSExp(flow_graph()->function()));
  AddExtraInteger(sexp, "deopt_id", start->deopt_id());
  AddConstantPool(sexp);
  if (start->normal_entry()) {
    sexp->Add(BlockEntryToSExp("normal", start->normal_entry()));
  }
  if (start->unchecked_entry()) {
    sexp->Add(BlockEntryToSExp("unchecked", start->unchecked_entry()));
  }
  if (start->osr_entry()) {
    sexp->Add(BlockEntryToSExp("osr", start->osr_entry()));
  }
  for (intptr_t i = 0; i < start->catch_entries().length(); i++) {
    sexp->Add(BlockEntryToSExp("catch", start->catch_entries().At(i)));
  }
  for (intptr_t i = 0; i < start->indirect_entries().length(); i++) {
    sexp->Add(BlockEntryToSExp("indirect", start->indirect_entries().At(i)));
  }
  AddBlocks(sexp);
  return sexp;
}

SExpression* FlowGraphSerializer::UseToSExp(const Definition* definition) {
  ASSERT(definition->HasSSATemp() || definition->HasTemp());
  if (definition->HasSSATemp()) {
    const intptr_t temp_index = definition->ssa_temp_index();
    const auto name_cstr = OS::SCreate(zone(), "v%" Pd "", temp_index);
    if (definition->HasPairRepresentation()) {
      auto sexp = new (zone()) SExpList(zone());
      AddSymbol(sexp, name_cstr);
      AddSymbol(sexp, OS::SCreate(zone(), "v%" Pd "", temp_index + 1));
      return sexp;
    } else {
      return new (zone()) SExpSymbol(name_cstr);
    }
  } else if (definition->HasTemp()) {
    const intptr_t temp_index = definition->temp_index();
    return new (zone()) SExpSymbol(OS::SCreate(zone(), "t%" Pd "", temp_index));
  } else {
    UNREACHABLE();
  }
}

SExpression* FlowGraphSerializer::ClassToSExp(const Class& cls) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Class");
  AddInteger(sexp, cls.id());
  if (FLAG_verbose_flow_graph_serialization) {
    sexp->AddExtra("name", CanonicalNameToSExp(cls));
  }
  return sexp;
}

static bool ShouldSerializeType(CompileType* type) {
  return (FLAG_verbose_flow_graph_serialization ||
          FLAG_serialize_flow_graph_types) &&
         type != NULL &&
         (type->ToNullableCid() != kDynamicCid || !type->is_nullable());
}

SExpression* FlowGraphSerializer::FieldToSExp(const Field& field) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Field");
  sexp->Add(CanonicalNameToSExp(field));
  CompileType t(field.is_nullable(), field.guarded_cid(), nullptr);
  if (ShouldSerializeType(&t)) {
    sexp->AddExtra("type", t.ToSExpression(this));
  }
  return sexp;
}

SExpression* FlowGraphSerializer::AbstractTypeToSExp(const AbstractType& t) {
  auto sexp = new (zone()) SExpList(zone());
  if (t.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(t);
    AddSymbol(sexp, "TypeParameter");
    tmp_string_ = param.name();
    AddSymbol(sexp, tmp_string_.ToCString());
    return sexp;
  }
  if (t.IsTypeRef()) {
    const auto& ref = TypeRef::Cast(t);
    AddSymbol(sexp, "TypeRef");
    // If tmp_type_ was passed into the call, this will change t's contents, but
    // this is safe because we don't need any more info from the TypeRef object
    // and no caller uses the contents of tmp_type_ after calling this function.
    tmp_type_ = ref.type();
    AddExtraInteger(sexp, "hash", tmp_type_.Hash());
    if (FLAG_verbose_flow_graph_serialization) {
      AddExtraString(sexp, "type", tmp_type_.ToCString());
    }
    return sexp;
  }
  ASSERT(t.IsType());
  AddSymbol(sexp, "Type");
  const auto& typ = Type::Cast(t);
  if (typ.HasTypeClass()) {
    tmp_class_ = typ.type_class();
    sexp->Add(ClassToSExp(tmp_class_));
    if (typ.IsRecursive()) {
      AddExtraInteger(sexp, "hash", typ.Hash());
    }
    // Since type arguments may themselves be instantiations of generic
    // classes, we may call back into this function in the middle of printing
    // the TypeArguments and so we must allocate a fresh handle here.
    const auto& args = TypeArguments::Handle(zone(), typ.arguments());
    if (!args.IsNull() && args.Length() > 0) {
      sexp->AddExtra("type_args", TypeArgumentsToSExp(args));
    }
  } else {
    // TODO(dartbug.com/36882): Actually structure non-class types instead of
    // just printing out this version.
    AddString(sexp, typ.ToCString());
  }
  return sexp;
}

SExpression* FlowGraphSerializer::CodeToSExp(const Code& code) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Code");
  if (code.IsStubCode()) {
    AddSymbol(sexp, StubCode::NameOfStub(code.EntryPoint()));
    if (FLAG_verbose_flow_graph_serialization) {
      AddExtraSymbol(sexp, "kind", "stub");
    }
    return sexp;
  }
  tmp_object_ = code.owner();
  if (tmp_object_.IsClass()) {
    sexp->Add(ClassToSExp(Class::Cast(tmp_object_)));
    if (FLAG_verbose_flow_graph_serialization) {
      AddExtraSymbol(sexp, "kind", "allocate");
    }
  } else if (tmp_object_.IsAbstractType()) {
    sexp->Add(AbstractTypeToSExp(AbstractType::Cast(tmp_object_)));
    if (FLAG_verbose_flow_graph_serialization) {
      AddExtraSymbol(sexp, "kind", "type_test");
    }
  } else {
    ASSERT(tmp_object_.IsFunction());
    sexp->Add(CanonicalNameToSExp(tmp_object_));
    if (FLAG_verbose_flow_graph_serialization) {
      AddExtraSymbol(sexp, "kind", "function");
    }
  }
  return sexp;
}

SExpression* FlowGraphSerializer::TypeArgumentsToSExp(const TypeArguments& ta) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "TypeArguments");
  for (intptr_t i = 0; i < ta.Length(); i++) {
    // Currently, reusing this handle is ok because the only place where we
    // might reenter TypeArguments (in SerializeAbstractType) doesn't need the
    // old contents of the handle after calling SerializeTypeArguments. If that
    // changes, then this will need to change also.
    tmp_type_ = ta.TypeAt(i);
    sexp->Add(AbstractTypeToSExp(tmp_type_));
  }
  return sexp;
}

SExpression* FlowGraphSerializer::DartValueToSExp(const Object& dartval) {
  if (dartval.IsString()) {
    return new (zone()) SExpString(dartval.ToCString());
  }
  if (dartval.IsSmi()) {
    return new (zone()) SExpInteger(Smi::Cast(dartval).Value());
  }
  if (dartval.IsBool()) {
    return new (zone()) SExpBool(Bool::Cast(dartval).value());
  }
  if (dartval.IsNull()) {
    return new (zone()) SExpSymbol("null");
  }
  if (dartval.IsField()) {
    return FieldToSExp(Field::Cast(dartval));
  }
  if (dartval.IsClass()) {
    return ClassToSExp(Class::Cast(dartval));
  }
  if (dartval.IsTypeArguments()) {
    return TypeArgumentsToSExp(TypeArguments::Cast(dartval));
  }
  if (dartval.IsCode()) {
    return CodeToSExp(Code::Cast(dartval));
  }
  if (dartval.IsArray()) {
    const Array& arr = Array::Cast(dartval);
    auto sexp = new (zone()) SExpList(zone());
    AddSymbol(sexp, "Array");
    auto& elem = Object::Handle(zone());
    for (intptr_t i = 0; i < arr.Length(); i++) {
      elem = arr.At(i);
      sexp->Add(DartValueToSExp(elem));
    }
    return sexp;
  }
  tmp_class_ = dartval.clazz();
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Instance");
  AddInteger(sexp, tmp_class_.id());
  if (FLAG_verbose_flow_graph_serialization) {
    AddExtraInteger(sexp, "size", dartval.InstanceSize());
    sexp->AddExtra("class", ClassToSExp(tmp_class_));
  }
  return sexp;
}

void FlowGraphSerializer::AddConstantPool(SExpList* sexp) {
  auto initial_defs = flow_graph()->graph_entry()->initial_definitions();
  if (initial_defs->is_empty()) return;
  auto constant_list = new (zone()) SExpList(zone());
  AddSymbol(constant_list, "constants");
  for (intptr_t i = 0; i < initial_defs->length(); i++) {
    ASSERT(initial_defs->At(i)->IsConstant());
    ConstantInstr* value = initial_defs->At(i)->AsConstant();
    auto elem = new (zone()) SExpList(zone());
    AddSymbol(elem, "def");
    elem->Add(UseToSExp(value->AsDefinition()));
    elem->Add(DartValueToSExp(value->value()));
    if (ShouldSerializeType(value->AsDefinition()->Type())) {
      auto val = value->AsDefinition()->Type()->ToSExpression(this);
      elem->AddExtra("type", val);
    }
    constant_list->Add(elem);
  }
  sexp->Add(constant_list);
}

void FlowGraphSerializer::AddBlocks(SExpList* sexp) {
  auto& block_order = flow_graph()->reverse_postorder();
  // Skip the first block, which will be the graph entry block (B0). We
  // output all its information as part of the function expression, so it'll
  // just show up as an empty block here.
  ASSERT(block_order[0]->IsGraphEntry());
  for (intptr_t i = 1; i < block_order.length(); ++i) {
    sexp->Add(block_order[i]->ToSExpression(this));
  }
}

SExpression* Instruction::ToSExpression(FlowGraphSerializer* s) const {
  auto sexp = new (s->zone()) SExpList(s->zone());
  s->AddSymbol(sexp, DebugName());
  AddOperandsToSExpression(sexp, s);
  AddExtraInfoToSExpression(sexp, s);
  return sexp;
}

SExpression* BlockEntryInstr::ToSExpression(FlowGraphSerializer* s) const {
  auto sexp = new (s->zone()) SExpList(s->zone());
  s->AddSymbol(sexp, "block");
  sexp->Add(s->BlockIdToSExp(block_id()));
  AddOperandsToSExpression(sexp, s);
  AddExtraInfoToSExpression(sexp, s);
  return sexp;
}

void BlockEntryInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  // We don't use RemoveCurrentFromGraph(), so this cast is safe.
  auto block = const_cast<BlockEntryInstr*>(this);
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    sexp->Add(it.Current()->ToSExpression(s));
  }
}

void JoinEntryInstr::AddOperandsToSExpression(SExpList* sexp,
                                              FlowGraphSerializer* s) const {
  if (auto phi_list = phis()) {
    for (intptr_t i = 0; i < phi_list->length(); i++) {
      sexp->Add(phi_list->At(i)->ToSExpression(s));
    }
  }
  BlockEntryInstr::AddOperandsToSExpression(sexp, s);
}

void Instruction::AddOperandsToSExpression(SExpList* sexp,
                                           FlowGraphSerializer* s) const {
  for (intptr_t i = 0; i < InputCount(); ++i) {
    if (InputAt(i) == nullptr) continue;
    sexp->Add(InputAt(i)->ToSExpression(s));
  }
}

void Instruction::AddExtraInfoToSExpression(SExpList* sexp,
                                            FlowGraphSerializer* s) const {
  if (GetDeoptId() != DeoptId::kNone) {
    s->AddExtraInteger(sexp, "deopt_id", GetDeoptId());
  }
  if (env() != nullptr) {
    sexp->AddExtra("env", env()->ToSExpression(s));
  }
}

SExpression* Definition::ToSExpression(FlowGraphSerializer* s) const {
  if (!HasSSATemp() && !HasTemp()) {
    return Instruction::ToSExpression(s);
  }
  auto sexp = new (s->zone()) SExpList(s->zone());
  s->AddSymbol(sexp, "def");
  sexp->Add(s->UseToSExp(this));
  if (ShouldSerializeType(type_)) {
    sexp->AddExtra("type", type_->ToSExpression(s));
  }
  sexp->Add(Instruction::ToSExpression(s));
  return sexp;
}

void ConstantInstr::AddOperandsToSExpression(SExpList* sexp,
                                             FlowGraphSerializer* s) const {
  sexp->Add(s->DartValueToSExp(value()));
}

void BranchInstr::AddOperandsToSExpression(SExpList* sexp,
                                           FlowGraphSerializer* s) const {
  sexp->Add(comparison()->ToSExpression(s));
  sexp->Add(s->BlockIdToSExp(true_successor()->block_id()));
  sexp->Add(s->BlockIdToSExp(false_successor()->block_id()));
}

void ParameterInstr::AddOperandsToSExpression(SExpList* sexp,
                                              FlowGraphSerializer* s) const {
  s->AddInteger(sexp, index());
}

void SpecialParameterInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  s->AddSymbol(sexp, KindToCString(kind()));
}

SExpression* FlowGraphSerializer::SlotToSExp(const Slot& slot) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Slot");
  AddInteger(sexp, slot.offset_in_bytes());
  if (FLAG_verbose_flow_graph_serialization) {
    if (slot.IsDartField()) {
      AddExtraSymbol(sexp, "kind", "kDartField");
      sexp->AddExtra("field", FieldToSExp(slot.field()));
    } else if (slot.IsLocalVariable()) {
      AddExtraSymbol(sexp, "kind", "kCapturedVariable");
      AddExtraString(sexp, "name", slot.Name());
    } else if (slot.IsTypeArguments()) {
      AddExtraSymbol(sexp, "kind", "kTypeArguments");
      AddExtraString(sexp, "name", slot.Name());
    } else {
      AddExtraSymbol(sexp, "kind", "kNativeSlot");
      AddExtraString(sexp, "name", slot.Name());
    }
  }
  return sexp;
}

void LoadFieldInstr::AddOperandsToSExpression(SExpList* sexp,
                                              FlowGraphSerializer* s) const {
  sexp->Add(instance()->ToSExpression(s));
  sexp->Add(s->SlotToSExp(slot()));
}

void StoreInstanceFieldInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  sexp->Add(instance()->ToSExpression(s));
  sexp->Add(s->SlotToSExp(slot()));
  sexp->Add(value()->ToSExpression(s));
}

void LoadIndexedUnsafeInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (offset() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "offset", offset());
  }
}

void StoreIndexedUnsafeInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (offset() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "offset", offset());
  }
}

void ComparisonInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  s->AddSymbol(sexp, Token::Str(kind()));
  Instruction::AddOperandsToSExpression(sexp, s);
}

void DoubleTestOpInstr::AddOperandsToSExpression(SExpList* sexp,
                                                 FlowGraphSerializer* s) const {
  const bool negated = kind() != Token::kEQ;
  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      s->AddSymbol(sexp, negated ? "IsNotNaN" : "IsNaN");
      break;
    case MethodRecognizer::kDouble_getIsInfinite:
      s->AddSymbol(sexp, negated ? "IsNotInfinite" : "IsInfinite");
      break;
    default:
      UNREACHABLE();
  }
  sexp->Add(value()->ToSExpression(s));
}

void GotoInstr::AddOperandsToSExpression(SExpList* sexp,
                                         FlowGraphSerializer* s) const {
  sexp->Add(s->BlockIdToSExp(successor()->block_id()));
}

void TailCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                             FlowGraphSerializer* s) const {
  sexp->Add(s->CodeToSExp(code_));
  Instruction::AddOperandsToSExpression(sexp, s);
}

void NativeCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  sexp->Add(s->CanonicalNameToSExp(function()));
  s->AddSymbol(sexp, native_name().ToCString());
}

template <>
void TemplateDartCall<0l>::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (type_args_len() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "type_args_len", type_args_len());
  }
  s->AddExtraInteger(sexp, "args_len", ArgumentCountWithoutTypeArgs());
}

template <>
void TemplateDartCall<1l>::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (type_args_len() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "type_args_len", type_args_len());
  }
  s->AddExtraInteger(sexp, "args_len", ArgumentCountWithoutTypeArgs());
}

void StaticCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  sexp->Add(s->CanonicalNameToSExp(function()));
}

void InstanceCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                                 FlowGraphSerializer* s) const {
  if (!interface_target().IsNull()) {
    sexp->Add(s->CanonicalNameToSExp(interface_target()));
  }
}

void PolymorphicInstanceCallInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  instance_call()->AddOperandsToSExpression(sexp, s);
}

void PolymorphicInstanceCallInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  ASSERT(deopt_id() == instance_call()->deopt_id());
  instance_call()->AddExtraInfoToSExpression(sexp, s);
  if (targets().length() > 0 || FLAG_verbose_flow_graph_serialization) {
    auto elem_list = new (s->zone()) SExpList(s->zone());
    for (intptr_t i = 0; i < targets().length(); i++) {
      auto elem = new (s->zone()) SExpList(s->zone());
      const TargetInfo* ti = targets().TargetAt(i);
      if (ti->cid_start == ti->cid_end) {
        s->AddInteger(elem, ti->cid_start);
      } else {
        auto range = new (s->zone()) SExpList(s->zone());
        s->AddInteger(range, ti->cid_start);
        s->AddInteger(range, ti->cid_end);
        elem->Add(range);
      }
      elem->Add(s->CanonicalNameToSExp(*ti->target));
      elem_list->Add(elem);
    }
    sexp->AddExtra("targets", elem_list);
  }
}

void AllocateObjectInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  sexp->Add(s->ClassToSExp(cls()));
}

void AllocateObjectInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  s->AddExtraInteger(sexp, "size", cls().instance_size());
  if (ArgumentCount() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "args_len", ArgumentCount());
  }
  if (FLAG_verbose_flow_graph_serialization) {
    if (closure_function().IsNull()) {
      s->AddSymbol(sexp, "null");
    } else {
      sexp->Add(s->CanonicalNameToSExp(closure_function()));
    }
  }
}

void BinaryIntegerOpInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  s->AddSymbol(sexp, Token::Str(op_kind()));
  sexp->Add(left()->ToSExpression(s));
  sexp->Add(right()->ToSExpression(s));
}

void CheckedSmiOpInstr::AddOperandsToSExpression(SExpList* sexp,
                                                 FlowGraphSerializer* s) const {
  s->AddSymbol(sexp, Token::Str(op_kind()));
  sexp->Add(left()->ToSExpression(s));
  sexp->Add(right()->ToSExpression(s));
}

static const char* simd_op_kind_string[] = {
#define CASE(Arity, Mask, Name, ...) #Name,
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
};

void SimdOpInstr::AddOperandsToSExpression(SExpList* sexp,
                                           FlowGraphSerializer* s) const {
  s->AddSymbol(sexp, simd_op_kind_string[kind()]);
  Instruction::AddOperandsToSExpression(sexp, s);
}

void SimdOpInstr::AddExtraInfoToSExpression(SExpList* sexp,
                                            FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (HasMask()) {
    s->AddExtraInteger(sexp, "mask", mask());
  }
}

void LoadIndexedInstr::AddExtraInfoToSExpression(SExpList* sexp,
                                                 FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (aligned() || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraBool(sexp, "aligned", aligned());
  }
  if (index_scale() > 1 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "scale", index_scale());
  }
  if (class_id() != kDynamicCid || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "cid", class_id());
  }
}

void StoreIndexedInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (aligned() || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraBool(sexp, "aligned", aligned());
  }
  if (index_scale() > 1 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "scale", index_scale());
  }
  if (class_id() != kDynamicCid || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "cid", class_id());
  }
}

void CheckStackOverflowInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (stack_depth() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "stack_depth", stack_depth());
  }
  if (in_loop() || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "loop_depth", loop_depth());
  }
}

SExpression* Value::ToSExpression(FlowGraphSerializer* s) const {
  auto name = s->UseToSExp(definition());
  if (reaching_type_ == nullptr || reaching_type_ == definition()->type_ ||
      !ShouldSerializeType(reaching_type_)) {
    return name;
  }
  auto sexp = new (s->zone()) SExpList(s->zone());
  s->AddSymbol(sexp, "value");
  sexp->Add(name);
  sexp->AddExtra("type", reaching_type_->ToSExpression(s));
  return sexp;
}

SExpression* CompileType::ToSExpression(FlowGraphSerializer* s) const {
  ASSERT(FLAG_verbose_flow_graph_serialization ||
         FLAG_serialize_flow_graph_types);
  ASSERT(cid_ != kDynamicCid || !is_nullable());

  auto sexp = new (s->zone()) SExpList(s->zone());
  s->AddSymbol(sexp, "CompileType");
  if (cid_ != kIllegalCid && cid_ != kDynamicCid) {
    s->AddInteger(sexp, cid_);
  }
  AddExtraInfoToSExpression(sexp, s);
  return sexp;
}

void CompileType::AddExtraInfoToSExpression(SExpList* sexp,
                                            FlowGraphSerializer* s) const {
  if (!is_nullable() || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraBool(sexp, "nullable", is_nullable());
  }
  if (FLAG_verbose_flow_graph_serialization) {
    s->AddExtraString(sexp, "name", ToCString());
  }
}

SExpression* Environment::ToSExpression(FlowGraphSerializer* s) const {
  auto sexp = new (s->zone()) SExpList(s->zone());
  intptr_t arg_count = 0;

  for (intptr_t i = 0; i < values_.length(); ++i) {
    if (values_[i]->definition()->IsPushArgument()) {
      s->AddSymbol(sexp, OS::SCreate(s->zone(), "arg[%" Pd "]", arg_count++));
    } else {
      sexp->Add(values_[i]->ToSExpression(s));
    }
    // TODO(sstrickl): This currently assumes that there are no locations in the
    // environment (e.g. before register allocation). If we ever want to print
    // out environments on steps after AllocateRegisters, we'll need to handle
    // locations as well.
    ASSERT(locations_ == nullptr || locations_[i].IsInvalid());
  }
  if (outer_ != NULL) {
    sexp->Add(outer_->ToSExpression(s));
  }
  return sexp;
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

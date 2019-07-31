// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_serializer.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/method_recognizer.h"
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
  auto const sexp = serializer.FlowGraphToSExp();
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
  ASSERT(!obj.IsNull());
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
  ASSERT(!obj.IsNull());
  TextBuffer b(100);
  SerializeCanonicalName(&b, obj);
  return new (zone()) SExpSymbol(OS::SCreate(zone(), "%s", b.buf()));
}

SExpSymbol* FlowGraphSerializer::BlockEntryTag(const BlockEntryInstr* entry) {
  if (entry == nullptr) return nullptr;
  BlockEntryInstr* const to_test = const_cast<BlockEntryInstr*>(entry);
  if (to_test->IsGraphEntry()) {
    return new (zone()) SExpSymbol("Graph");
  }
  if (to_test->IsOsrEntry()) {
    return new (zone()) SExpSymbol("OSR");
  }
  if (to_test->IsCatchBlockEntry()) {
    return new (zone()) SExpSymbol("Catch");
  }
  if (to_test->IsIndirectEntry()) {
    return new (zone()) SExpSymbol("Indirect");
  }
  if (to_test->IsFunctionEntry()) {
    if (entry == flow_graph()->graph_entry()->normal_entry()) {
      return new (zone()) SExpSymbol("Normal");
    }
    if (entry == flow_graph()->graph_entry()->unchecked_entry()) {
      return new (zone()) SExpSymbol("Unchecked");
    }
  }
  if (to_test->IsJoinEntry()) {
    return new (zone()) SExpSymbol("Join");
  }
  return nullptr;
}

SExpression* FlowGraphSerializer::FunctionEntryToSExp(BlockEntryInstr* entry) {
  if (entry == nullptr) return nullptr;
  auto sexp = new (zone()) SExpList(zone());
  sexp->Add(BlockEntryTag(entry));
  sexp->Add(BlockIdToSExp(entry->block_id()));
  if (auto with_defs = entry->AsBlockEntryWithInitialDefs()) {
    auto initial_defs = with_defs->initial_definitions();
    for (intptr_t i = 0; i < initial_defs->length(); i++) {
      sexp->Add(initial_defs->At(i)->ToSExpression(this));
    }
  }
  return sexp;
}

SExpression* FlowGraphSerializer::EntriesToSExp(GraphEntryInstr* start) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Entries");
  if (auto const normal = FunctionEntryToSExp(start->normal_entry())) {
    sexp->Add(normal);
  }
  if (auto const unchecked = FunctionEntryToSExp(start->unchecked_entry())) {
    sexp->Add(unchecked);
  }
  if (auto const osr = FunctionEntryToSExp(start->osr_entry())) {
    sexp->Add(osr);
  }
  for (intptr_t i = 0; i < start->catch_entries().length(); i++) {
    sexp->Add(FunctionEntryToSExp(start->catch_entries().At(i)));
  }
  for (intptr_t i = 0; i < start->indirect_entries().length(); i++) {
    sexp->Add(FunctionEntryToSExp(start->indirect_entries().At(i)));
  }
  return sexp;
}

SExpression* FlowGraphSerializer::FlowGraphToSExp() {
  auto const start = flow_graph()->graph_entry();
  auto const sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "FlowGraph");
  sexp->Add(CanonicalNameToSExp(flow_graph()->function()));
  AddExtraInteger(sexp, "deopt_id", start->deopt_id());
  if (start->IsCompiledForOsr()) {
    AddExtraInteger(sexp, "osr_id", start->osr_id());
  }
  if (auto const constants = ConstantPoolToSExp(start)) {
    sexp->Add(constants);
  }
  sexp->Add(EntriesToSExp(start));
  auto& block_order = flow_graph()->reverse_postorder();
  // Skip the first block, which will be the graph entry block (B0). We
  // output all its information as part of the function expression, so it'll
  // just show up as an empty block here.
  ASSERT(block_order[0]->IsGraphEntry());
  for (intptr_t i = 1; i < block_order.length(); ++i) {
    sexp->Add(block_order[i]->ToSExpression(this));
  }
  return sexp;
}

SExpression* FlowGraphSerializer::UseToSExp(const Definition* definition) {
  ASSERT(definition != nullptr);
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
  }
  UNREACHABLE();
}

SExpression* FlowGraphSerializer::ClassToSExp(const Class& cls) {
  if (cls.IsNull()) return nullptr;
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
  if (field.IsNull()) return nullptr;
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
  if (t.IsNull()) return nullptr;
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
  if (code.IsNull()) return nullptr;
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
  if (!tmp_object_.IsNull() && FLAG_verbose_flow_graph_serialization) {
    if (tmp_object_.IsClass()) {
      AddExtraSymbol(sexp, "kind", "allocate");
    } else if (tmp_object_.IsAbstractType()) {
      AddExtraSymbol(sexp, "kind", "type_test");
    } else {
      ASSERT(tmp_object_.IsFunction());
      AddExtraSymbol(sexp, "kind", "function");
    }
  }
  sexp->Add(ObjectToSExp(tmp_object_));
  return sexp;
}

SExpression* FlowGraphSerializer::TypeArgumentsToSExp(const TypeArguments& ta) {
  if (ta.IsNull()) return nullptr;
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

SExpression* FlowGraphSerializer::InstanceToSExp(const Instance& inst) {
  if (inst.IsNull()) return nullptr;
  auto const sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Instance");
  tmp_class_ = inst.clazz();
  AddInteger(sexp, tmp_class_.id());
  if (FLAG_verbose_flow_graph_serialization) {
    AddExtraInteger(sexp, "size", inst.InstanceSize());
    if (auto const cls = ClassToSExp(tmp_class_)) {
      sexp->AddExtra("class", cls);
    }
  }
  return sexp;
}

SExpression* FlowGraphSerializer::FunctionToSExp(const Function& func) {
  if (func.IsNull()) return nullptr;
  auto const sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Function");
  sexp->Add(CanonicalNameToSExp(func));
  if (func.IsRecognized()) {
    AddExtraSymbol(sexp, "recognized",
                   MethodRecognizer::KindToCString(func.recognized_kind()));
  }
  if (func.is_native()) {
    tmp_string_ = func.native_name();
    if (!tmp_string_.IsNull()) {
      AddExtraSymbol(sexp, "native_name", tmp_string_.ToCString());
    }
  }
  if (FLAG_verbose_flow_graph_serialization) {
    AddExtraSymbol(sexp, "kind", Function::KindToCString(func.kind()));
  }
  tmp_type_args_ = func.type_parameters();
  if (auto const ta_sexp = TypeArgumentsToSExp(tmp_type_args_)) {
    sexp->AddExtra("type_params", ta_sexp);
  }
  return sexp;
}

SExpression* FlowGraphSerializer::ObjectToSExp(const Object& dartval) {
  if (dartval.IsNull()) {
    return new (zone()) SExpSymbol("null");
  }
  if (dartval.IsString()) {
    return new (zone()) SExpString(dartval.ToCString());
  }
  if (dartval.IsSmi()) {
    return new (zone()) SExpInteger(Smi::Cast(dartval).Value());
  }
  if (dartval.IsBool()) {
    return new (zone()) SExpBool(Bool::Cast(dartval).value());
  }
  if (dartval.IsDouble()) {
    return new (zone()) SExpDouble(Double::Cast(dartval).value());
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
      sexp->Add(ObjectToSExp(elem));
    }
    return sexp;
  }
  if (dartval.IsFunction()) {
    return FunctionToSExp(Function::Cast(dartval));
  }
  ASSERT(dartval.IsInstance());
  return InstanceToSExp(Instance::Cast(dartval));
}

SExpression* FlowGraphSerializer::ConstantPoolToSExp(GraphEntryInstr* start) {
  auto const initial_defs = start->initial_definitions();
  if (initial_defs == nullptr || initial_defs->is_empty()) return nullptr;
  auto constant_list = new (zone()) SExpList(zone());
  AddSymbol(constant_list, "Constants");
  for (intptr_t i = 0; i < initial_defs->length(); i++) {
    ASSERT(initial_defs->At(i)->IsConstant());
    ConstantInstr* value = initial_defs->At(i)->AsConstant();
    auto elem = new (zone()) SExpList(zone());
    AddSymbol(elem, "def");
    elem->Add(UseToSExp(value->AsDefinition()));
    elem->Add(ObjectToSExp(value->value()));
    if (ShouldSerializeType(value->AsDefinition()->Type())) {
      auto const val = value->AsDefinition()->Type()->ToSExpression(this);
      elem->AddExtra("type", val);
    }
    constant_list->Add(elem);
  }
  return constant_list;
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
  s->AddSymbol(sexp, "Block");
  sexp->Add(s->BlockIdToSExp(block_id()));
  AddOperandsToSExpression(sexp, s);
  AddExtraInfoToSExpression(sexp, s);
  return sexp;
}

void BlockEntryInstr::AddExtraInfoToSExpression(SExpList* sexp,
                                                FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  if (FLAG_verbose_flow_graph_serialization) {
    if (auto const entry_tag = s->BlockEntryTag(this)) {
      sexp->AddExtra("block_type", entry_tag);
    }
    if (PredecessorCount() > 0) {
      auto const preds = new (s->zone()) SExpList(s->zone());
      for (intptr_t i = 0; i < PredecessorCount(); i++) {
        preds->Add(s->BlockIdToSExp(PredecessorAt(i)->block_id()));
      }
      sexp->AddExtra("predecessors", preds);
    }
  }
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
  sexp->Add(s->ObjectToSExp(value()));
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

SExpression* FlowGraphSerializer::LocalVariableToSExp(const LocalVariable& v) {
  auto const sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "LocalVariable");
  if (!v.name().IsNull()) {
    AddSymbol(sexp, v.name().ToCString());
  }
  if (v.index().IsValid()) {
    AddExtraInteger(sexp, "index", v.index().value());
  }
  return sexp;
}

void LoadLocalInstr::AddOperandsToSExpression(SExpList* sexp,
                                              FlowGraphSerializer* s) const {
  sexp->Add(s->LocalVariableToSExp(local()));
}

void StoreLocalInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  sexp->Add(s->LocalVariableToSExp(local()));
}

static const char* SlotKindToCString(Slot::Kind kind) {
  switch (kind) {
    case Slot::Kind::kDartField:
      return "DartField";
    case Slot::Kind::kCapturedVariable:
      return "CapturedVariable";
    case Slot::Kind::kTypeArguments:
      return "TypeArguments";
    default:
      return "NativeSlot";
  }
}

SExpression* FlowGraphSerializer::SlotToSExp(const Slot& slot) {
  auto sexp = new (zone()) SExpList(zone());
  AddSymbol(sexp, "Slot");
  AddInteger(sexp, slot.offset_in_bytes());
  if (FLAG_verbose_flow_graph_serialization) {
    AddExtraSymbol(sexp, "kind", SlotKindToCString(slot.kind()));
    if (slot.IsDartField()) {
      sexp->AddExtra("field", FieldToSExp(slot.field()));
    } else {
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
  if (auto const code = s->CodeToSExp(code_)) {
    sexp->Add(code);
  }
  Instruction::AddOperandsToSExpression(sexp, s);
}

void NativeCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                               FlowGraphSerializer* s) const {
  if (auto const func = s->FunctionToSExp(function())) {
    sexp->Add(func);
  }
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
  if (auto const func = s->FunctionToSExp(function())) {
    sexp->Add(func);
  }
}

void InstanceCallInstr::AddOperandsToSExpression(SExpList* sexp,
                                                 FlowGraphSerializer* s) const {
  if (auto const target = s->FunctionToSExp(interface_target())) {
    sexp->Add(target);
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
      if (auto const target = s->FunctionToSExp(*ti->target)) {
        elem->Add(target);
      }
      elem_list->Add(elem);
    }
    sexp->AddExtra("targets", elem_list);
  }
}

void AllocateObjectInstr::AddOperandsToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  if (auto const sexp_cls = s->ClassToSExp(cls())) {
    sexp->Add(sexp_cls);
  }
}

void AllocateObjectInstr::AddExtraInfoToSExpression(
    SExpList* sexp,
    FlowGraphSerializer* s) const {
  Instruction::AddExtraInfoToSExpression(sexp, s);
  s->AddExtraInteger(sexp, "size", cls().instance_size());
  if (ArgumentCount() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->AddExtraInteger(sexp, "args_len", ArgumentCount());
  }
  if (auto const closure = s->FunctionToSExp(closure_function())) {
    sexp->AddExtra("closure_function", closure);
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

// clang-format off
static const char* simd_op_kind_string[] = {
#define CASE(Arity, Mask, Name, ...) #Name,
  SIMD_OP_LIST(CASE, CASE)
#undef CASE
  "IllegalSimdOp",
};
// clang-format on

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
  if (cid_ == kIllegalCid || cid_ == kDynamicCid ||
      FLAG_verbose_flow_graph_serialization) {
    if (type_ != nullptr) {
      sexp->AddExtra("type", s->AbstractTypeToSExp(*type_));
    } else {
      s->AddExtraString(sexp, "name", ToCString());
    }
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

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_serializer.h"

#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/os.h"
#include "vm/parser.h"

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

void FlowGraphSerializer::SerializeToBuffer(const FlowGraph* flow_graph,
                                            TextBuffer* buffer) {
  ASSERT(buffer != nullptr);
  FlowGraphSerializer serializer(flow_graph, buffer);
  serializer.SerializeFunction();
}

void FlowGraphSerializer::SerializeBlockId(intptr_t block_id) {
  buffer()->Printf("B%" Pd "", block_id);
}

void FlowGraphSerializer::SerializeQuotedString(const char* str) {
  buffer()->AddChar('"');
  buffer()->AddEscapedString(str);
  buffer()->AddChar('"');
}

void FlowGraphSerializer::SerializeCanonicalName(const Object& obj) {
  if (obj.IsFunction()) {
    const auto& function = Function::Cast(obj);
    // If this function is an inner closure then the parent points to its
    // containing function, which will also be part of the canonical name.
    const auto& parent = Function::Handle(zone_, function.parent_function());
    if (!parent.IsNull()) {
      SerializeCanonicalName(parent);
    } else {
      tmp_class_ = function.Owner();
      ASSERT(!tmp_class_.IsNull());
      SerializeCanonicalName(tmp_class_);
    }
    tmp_string_ = function.UserVisibleName();
    buffer()->Printf(":%s", tmp_string_.ToCString());
  } else if (obj.IsClass()) {
    const auto& cls = Class::Cast(obj);
    tmp_library_ = cls.library();
    if (!tmp_library_.IsNull()) {
      SerializeCanonicalName(tmp_library_);
    }
    tmp_string_ = cls.ScrubbedName();
    buffer()->Printf(":%s", tmp_string_.ToCString());
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    tmp_string_ = lib.url();
    const char* lib_name = tmp_string_.ToCString();
    if (lib_name[0] == '\0') return;
    buffer()->AddString(lib_name);
  } else if (obj.IsField()) {
    const auto& field = Field::Cast(obj);
    tmp_class_ = field.Owner();
    ASSERT(!tmp_class_.IsNull());
    SerializeCanonicalName(tmp_class_);
    tmp_string_ = field.UserVisibleName();
    buffer()->Printf(".%s", tmp_string_.ToCString());
  } else {
    UNREACHABLE();
  }
}

void FlowGraphSerializer::SerializeBlockEntry(const char* entry_name,
                                              BlockEntryInstr* entry) {
  buffer()->Printf("\n  (%s-entry ", entry_name);
  SerializeBlockId(entry->block_id());
  if (auto with_defs = entry->AsBlockEntryWithInitialDefs()) {
    auto initial_defs = with_defs->initial_definitions();
    for (intptr_t i = 0; i < initial_defs->length(); i++) {
      buffer()->AddString("\n    ");
      initial_defs->At(i)->SerializeTo(this);
    }
  } else if (auto join = entry->AsJoinEntry()) {
    if (auto phi_list = join->phis()) {
      for (intptr_t i = 0; i < phi_list->length(); i++) {
        buffer()->AddString("\n    ");
        phi_list->At(i)->SerializeTo(this);
      }
    }
  }
  buffer()->AddChar(')');
}

void FlowGraphSerializer::SerializeFunction() {
  auto start = flow_graph()->graph_entry();
  buffer()->Printf("\n(function %s { deopt_id %" Pd " }",
                   flow_graph()->function().ToFullyQualifiedCString(),
                   start->deopt_id());
  SerializeConstantPool();
  if (start->normal_entry()) {
    SerializeBlockEntry("normal", start->normal_entry());
  }
  if (start->unchecked_entry()) {
    SerializeBlockEntry("unchecked", start->unchecked_entry());
  }
  if (start->osr_entry()) {
    SerializeBlockEntry("osr", start->osr_entry());
  }
  for (intptr_t i = 0; i < start->catch_entries().length(); i++) {
    SerializeBlockEntry("catch", start->catch_entries().At(i));
  }
  for (intptr_t i = 0; i < start->indirect_entries().length(); i++) {
    SerializeBlockEntry("indirect", start->indirect_entries().At(i));
  }
  SerializeBlocks();
  buffer()->AddString(")\n");
}

void FlowGraphSerializer::SerializeUse(const Definition* definition) {
  if (definition->HasSSATemp()) {
    if (definition->HasPairRepresentation()) {
      buffer()->Printf("(v%" Pd " v%" Pd ")", definition->ssa_temp_index(),
                       definition->ssa_temp_index() + 1);
    } else {
      buffer()->Printf("v%" Pd "", definition->ssa_temp_index());
    }
  } else if (definition->HasTemp()) {
    buffer()->Printf("t%" Pd "", definition->temp_index());
  }
}

void FlowGraphSerializer::SerializeClass(const Class& cls) {
  buffer()->Printf("(Class %" Pd "", cls.id());
  if (FLAG_verbose_flow_graph_serialization) {
    buffer()->AddString(" { name ");
    SerializeCanonicalName(cls);
    buffer()->AddString(", }");
  }
  buffer()->Printf(")");
}

static bool ShouldSerializeType(CompileType* type) {
  return (FLAG_verbose_flow_graph_serialization ||
          FLAG_serialize_flow_graph_types) &&
         type != NULL &&
         (type->ToNullableCid() != kDynamicCid || !type->is_nullable());
}

void FlowGraphSerializer::SerializeField(const Field& field) {
  buffer()->AddString("(Field ");
  SerializeCanonicalName(field);
  CompileType t(field.is_nullable(), field.guarded_cid(), nullptr);
  if (ShouldSerializeType(&t)) {
    buffer()->AddString(" { type ");
    t.SerializeTo(this);
    buffer()->AddString(", }");
  }
  buffer()->AddString(")");
}

void FlowGraphSerializer::SerializeAbstractType(const AbstractType& t) {
  if (t.IsType()) {
    const auto& typ = Type::Cast(t);
    buffer()->AddString("(Type ");
    if (typ.HasTypeClass()) {
      tmp_class_ = typ.type_class();
      SerializeClass(tmp_class_);

      TextBuffer tmp(400);
      TextBuffer* old = buffer();
      set_buffer(&tmp);

      if (typ.IsRecursive()) {
        buffer()->Printf(" hash %" Px ",", typ.Hash());
      }
      // Since type arguments may themselves be instantiations of generic
      // classes, we may call back into this function in the middle of printing
      // the TypeArguments and so we must allocate a handle here.
      const auto& args = TypeArguments::Handle(zone_, typ.arguments());
      if (!args.IsNull() && args.Length() > 0) {
        buffer()->AddString(" type_args ");
        SerializeTypeArguments(args);
        buffer()->AddString(",");
      }

      set_buffer(old);
      if (tmp.length() > 0) {
        buffer()->Printf(" {%s }", tmp.buf());
      }
    } else {
      // TODO(dartbug.com/36882): Actually structure non-class types instead of
      // just printing out this version.
      SerializeQuotedString(typ.ToCString());
    }
    buffer()->AddChar(')');
  } else if (t.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(t);
    tmp_string_ = param.name();
    buffer()->Printf("(TypeParameter %s)", tmp_string_.ToCString());
  } else if (t.IsTypeRef()) {
    const auto& ref = TypeRef::Cast(t);
    // Safe to do this because even if the handle passed in via t was the one in
    // tmp_type_, we don't need any more information from the TypeRef object
    // itself.
    tmp_type_ = ref.type();
    buffer()->Printf("(TypeRef { hash %" Px ",", tmp_type_.Hash());
    if (FLAG_verbose_flow_graph_serialization) {
      buffer()->AddString(" type ");
      SerializeQuotedString(tmp_type_.ToCString());
      buffer()->AddString(",");
    }
    buffer()->AddString(" })");
  } else {
    UNREACHABLE();
  }
}

void FlowGraphSerializer::SerializeCode(const Code& code) {
  tmp_object_ = code.owner();
  buffer()->AddString("(Code ");
  if (code.IsStubCode()) {
    buffer()->AddString(StubCode::NameOfStub(code.EntryPoint()));
  } else if (tmp_object_.IsClass()) {
    SerializeClass(Class::Cast(tmp_object_));
  } else if (tmp_object_.IsAbstractType()) {
    SerializeAbstractType(AbstractType::Cast(tmp_object_));
  } else {
    ASSERT(tmp_object_.IsFunction());
    SerializeCanonicalName(tmp_object_);
  }
  if (FLAG_verbose_flow_graph_serialization) {
    buffer()->AddString(" { kind ");
    if (code.IsStubCode()) {
      buffer()->AddString("stub");
    } else if (tmp_object_.IsClass()) {
      buffer()->AddString("allocate");
    } else if (tmp_object_.IsAbstractType()) {
      buffer()->AddString("type_test");
    } else {
      buffer()->AddString("function");
    }
    buffer()->AddString(", }");
  }
  buffer()->AddChar(')');
}

void FlowGraphSerializer::SerializeTypeArguments(const TypeArguments& ta) {
  buffer()->AddString("(TypeArguments");
  for (intptr_t i = 0; i < ta.Length(); i++) {
    // Currently, reusing this handle is ok because the only place where we
    // might reenter TypeArguments (in SerializeAbstractType) doesn't need the
    // old contents of the handle after calling SerializeTypeArguments. If that
    // changes, then this will need to change also.
    tmp_type_ = ta.TypeAt(i);
    buffer()->AddChar(' ');
    SerializeAbstractType(tmp_type_);
  }
  buffer()->AddString(")");
}

void FlowGraphSerializer::SerializeDartValue(const Object& dartval) {
  if (dartval.IsString()) {
    SerializeQuotedString(dartval.ToCString());
  } else if (dartval.IsArray()) {
    const Array& arr = Array::Cast(dartval);
    buffer()->AddString("(Array");
    auto& elem = Object::Handle(zone_);
    for (intptr_t i = 0; i < arr.Length(); i++) {
      elem = arr.At(i);
      buffer()->AddChar(' ');
      SerializeDartValue(elem);
    }
    buffer()->AddString(")");
  } else if (dartval.IsField()) {
    SerializeField(Field::Cast(dartval));
  } else if (dartval.IsClass()) {
    SerializeClass(Class::Cast(dartval));
  } else if (dartval.IsTypeArguments()) {
    SerializeTypeArguments(TypeArguments::Cast(dartval));
  } else if (dartval.IsCode()) {
    SerializeCode(Code::Cast(dartval));
  } else if (dartval.IsSmi() || dartval.IsBool() || dartval.IsNull()) {
    buffer()->Printf("%s", dartval.ToCString());
  } else {
    tmp_class_ = dartval.clazz();
    buffer()->Printf("(Instance %" Pd "", tmp_class_.id());
    if (FLAG_verbose_flow_graph_serialization) {
      buffer()->Printf(" { size %" Pd ", class ", dartval.InstanceSize());
      SerializeClass(tmp_class_);
      buffer()->Printf(", }");
    }
    buffer()->Printf(")");
  }
}

void FlowGraphSerializer::SerializeConstantPool() {
  auto initial_defs = flow_graph()->graph_entry()->initial_definitions();
  if (initial_defs->is_empty()) return;
  buffer()->AddString("\n  (constants");
  for (intptr_t i = 0; i < initial_defs->length(); i++) {
    ASSERT(initial_defs->At(i)->IsConstant());
    ConstantInstr* value = initial_defs->At(i)->AsConstant();
    buffer()->AddString("\n    (def ");
    SerializeUse(value->AsDefinition());
    if (ShouldSerializeType(value->AsDefinition()->Type())) {
      buffer()->AddString(" { type ");
      value->AsDefinition()->Type()->SerializeTo(this);
      buffer()->AddString(", }");
    }
    buffer()->AddChar(' ');
    SerializeDartValue(value->value());
    buffer()->AddChar(')');
  }
  buffer()->Printf(")");
}

void FlowGraphSerializer::SerializeBlocks() {
  auto& block_order = flow_graph()->reverse_postorder();
  // Skip the first block, which will be the graph entry block (B0). We
  // output all its information as part of the function expression, so it'll
  // just show up as an empty block here.
  ASSERT(block_order[0]->IsGraphEntry());
  for (intptr_t i = 1; i < block_order.length(); ++i) {
    block_order[i]->SerializeTo(this);
  }
}

template <typename T>
void FlowGraphSerializer::OptionallySerializeExtraInfo(const T* obj) {
  TextBuffer* old = buffer();
  TextBuffer extra(400);
  set_buffer(&extra);
  obj->SerializeExtraInfoTo(this);
  set_buffer(old);
  if (extra.length() > 0) {
    buffer()->Printf(" {%s }", extra.buf());
  }
}

void Instruction::SerializeTo(FlowGraphSerializer* serializer) const {
  serializer->buffer()->Printf("(%s", DebugName());
  SerializeOperandsTo(serializer);
  serializer->OptionallySerializeExtraInfo(this);
  serializer->buffer()->AddChar(')');
}

void BlockEntryInstr::SerializeTo(FlowGraphSerializer* s) const {
  s->buffer()->AddString("\n  (block ");
  s->SerializeBlockId(block_id());
  // We switch the order here because usually BlockEntryInstrs only have
  // a deopt_id, and there's a lot of room on the header line after the
  // block ID.
  s->OptionallySerializeExtraInfo(this);
  SerializeOperandsTo(s);
  s->buffer()->AddString(")");
}

void BlockEntryInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  // We don't use RemoveCurrentFromGraph(), so this cast is safe.
  auto block = const_cast<BlockEntryInstr*>(this);
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    s->buffer()->AddString("\n    ");
    it.Current()->SerializeTo(s);
  }
}

void JoinEntryInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  if (auto phi_list = phis()) {
    for (intptr_t i = 0; i < phi_list->length(); i++) {
      s->buffer()->AddString("\n    ");
      phi_list->At(i)->SerializeTo(s);
    }
  }
  this->BlockEntryInstr::SerializeOperandsTo(s);
}

void Instruction::SerializeOperandsTo(FlowGraphSerializer* s) const {
  for (int i = 0; i < InputCount(); ++i) {
    s->buffer()->AddChar(' ');
    if (InputAt(i) != NULL) InputAt(i)->SerializeTo(s);
  }
}

void Instruction::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  if (GetDeoptId() != DeoptId::kNone) {
    s->buffer()->Printf(" deopt_id %" Pd ",", GetDeoptId());
  }
  if (env() != nullptr) {
    s->buffer()->AddString(" env ");
    env()->SerializeTo(s);
    s->buffer()->AddChar(',');
  }
}

void Definition::SerializeTo(FlowGraphSerializer* s) const {
  if (HasSSATemp() || HasTemp()) {
    s->buffer()->AddString("(def ");
    s->SerializeUse(this);
    if (ShouldSerializeType(type_)) {
      s->buffer()->AddString(" { type ");
      type_->SerializeTo(s);
      s->buffer()->AddString(", }");
    }
    s->buffer()->AddChar(' ');
    Instruction::SerializeTo(s);
    s->buffer()->AddChar(')');
  } else {
    Instruction::SerializeTo(s);
  }
}

void ConstantInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  s->SerializeDartValue(value());
}

void BranchInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  comparison()->SerializeTo(s);
  s->buffer()->AddChar(' ');
  s->SerializeBlockId(true_successor()->block_id());
  s->buffer()->AddChar(' ');
  s->SerializeBlockId(false_successor()->block_id());
}

void ParameterInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %" Pd "", index());
}

void SpecialParameterInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s", KindToCString(kind()));
}

void FlowGraphSerializer::SerializeSlot(const Slot& slot) {
  buffer()->Printf("(Slot %" Pd "", slot.offset_in_bytes());
  if (FLAG_verbose_flow_graph_serialization) {
    if (slot.IsDartField()) {
      buffer()->Printf(" { kind kDartField, field ");
      SerializeField(slot.field());
      buffer()->AddString(", }");
    } else if (slot.IsLocalVariable()) {
      buffer()->Printf(" { kind kCapturedVariable, name \"%s\", }",
                       slot.Name());
    } else if (slot.IsTypeArguments()) {
      buffer()->Printf(" { kind kTypeArguments, name \"%s\", }", slot.Name());
    } else {
      buffer()->Printf(" { kind kNativeSlot, name \"%s\", }", slot.Name());
    }
  }
  buffer()->AddChar(')');
}

void LoadFieldInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  instance()->SerializeTo(s);
  s->buffer()->AddChar(' ');
  s->SerializeSlot(slot());
}

void StoreInstanceFieldInstr::SerializeOperandsTo(
    FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  instance()->SerializeTo(s);
  s->buffer()->AddChar(' ');
  s->SerializeSlot(slot());
  s->buffer()->AddChar(' ');
  value()->SerializeTo(s);
}

void LoadIndexedUnsafeInstr::SerializeExtraInfoTo(
    FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (offset() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" offset %" Pd "", offset());
  }
}

void StoreIndexedUnsafeInstr::SerializeExtraInfoTo(
    FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (offset() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" offset %" Pd "", offset());
  }
}

void ComparisonInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s", Token::Str(kind()));
  Instruction::SerializeOperandsTo(s);
}

void DoubleTestOpInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  const bool negated = kind() != Token::kEQ;
  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      s->buffer()->AddString(negated ? " IsNotNaN " : " IsNaN ");
      break;
    case MethodRecognizer::kDouble_getIsInfinite:
      s->buffer()->AddString(negated ? " IsNotInfinite " : " IsInfinite ");
      break;
    default:
      UNREACHABLE();
  }
  value()->SerializeTo(s);
}

void GotoInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  s->SerializeBlockId(successor()->block_id());
}

void TailCallInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  s->SerializeCode(code_);
  Instruction::SerializeOperandsTo(s);
}

void NativeCallInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  s->buffer()->Printf("%s", native_name().ToCString());
}

static void SerializeArgsInfoTo(FlowGraphSerializer* s,
                                intptr_t type_args_len,
                                intptr_t args_len) {
  if (type_args_len > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" type_args_len %" Pd ",", type_args_len);
  }
  s->buffer()->Printf(" args_len %" Pd ",", args_len);
}

template <>
void TemplateDartCall<0l>::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  SerializeArgsInfoTo(s, type_args_len(), ArgumentCountWithoutTypeArgs());
}

template <>
void TemplateDartCall<1l>::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  SerializeArgsInfoTo(s, type_args_len(), ArgumentCountWithoutTypeArgs());
}

void StaticCallInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s", function().ToFullyQualifiedCString());
}

void InstanceCallInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  if (!interface_target().IsNull()) {
    s->buffer()->AddChar(' ');
    s->SerializeCanonicalName(interface_target());
  }
}

void PolymorphicInstanceCallInstr::SerializeOperandsTo(
    FlowGraphSerializer* s) const {
  instance_call()->SerializeOperandsTo(s);
}

void PolymorphicInstanceCallInstr::SerializeExtraInfoTo(
    FlowGraphSerializer* s) const {
  ASSERT(deopt_id() == instance_call()->deopt_id());
  instance_call()->SerializeExtraInfoTo(s);
  if (targets().length() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" targets {");
    for (intptr_t i = 0; i < targets().length(); i++) {
      const TargetInfo* ti = targets().TargetAt(i);
      if (ti->cid_start == ti->cid_end) {
        s->buffer()->Printf(" %" Pd " ", ti->cid_start);
        s->SerializeCanonicalName(*ti->target);
        s->buffer()->AddChar(',');
      } else {
        s->buffer()->Printf(" [%" Pd ", %" Pd "] ", ti->cid_start, ti->cid_end);
        s->SerializeCanonicalName(*ti->target);
        s->buffer()->AddChar(',');
      }
    }
    s->buffer()->Printf(" }");
  }
}

void AllocateObjectInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar(' ');
  s->SerializeClass(cls());
}

void AllocateObjectInstr::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  s->buffer()->Printf(" size %" Pd ",", cls().instance_size());
  if (ArgumentCount() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" args_len %" Pd ",", ArgumentCount());
  }
  if (FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" closure_function %s,",
                        closure_function().IsNull()
                            ? "null"
                            : closure_function().ToFullyQualifiedCString());
  }
}

void BinaryIntegerOpInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s ", Token::Str(op_kind()));
  left()->SerializeTo(s);
  s->buffer()->AddChar(' ');
  right()->SerializeTo(s);
}

void CheckedSmiOpInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s ", Token::Str(op_kind()));
  left()->SerializeTo(s);
  s->buffer()->AddChar(' ');
  right()->SerializeTo(s);
}

static const char* simd_op_kind_string[] = {
#define CASE(Arity, Mask, Name, ...) #Name,
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
};

void SimdOpInstr::SerializeOperandsTo(FlowGraphSerializer* s) const {
  s->buffer()->Printf(" %s", simd_op_kind_string[kind()]);
  Instruction::SerializeOperandsTo(s);
}

void SimdOpInstr::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (HasMask()) {
    s->buffer()->Printf(" mask %" Pd ",", mask());
  }
}

void LoadIndexedInstr::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (aligned() || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" aligned %s,", aligned() ? "true" : "false");
  }
  if (index_scale() > 1 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" scale %" Pd ",", index_scale());
  }
  if (class_id() != kDynamicCid || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" cid %" Pd ",", class_id());
  }
}

void StoreIndexedInstr::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (aligned() || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" aligned %s,", aligned() ? "true" : "false");
  }
  if (index_scale() > 1 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" scale %" Pd ",", index_scale());
  }
  if (class_id() != kDynamicCid || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" cid %" Pd ",", class_id());
  }
}

void CheckStackOverflowInstr::SerializeExtraInfoTo(
    FlowGraphSerializer* s) const {
  Instruction::SerializeExtraInfoTo(s);
  if (stack_depth() > 0 || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" stack_depth %" Pd ",", stack_depth());
  }
  if (in_loop() || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" loop_depth %" Pd ",", loop_depth());
  }
}

void Value::SerializeTo(FlowGraphSerializer* s) const {
  TextBuffer* old = s->buffer();
  TextBuffer extra(400);
  s->set_buffer(&extra);
  SerializeExtraInfoTo(s);
  s->set_buffer(old);
  if (extra.length() > 0) {
    s->buffer()->AddString("(value ");
    s->SerializeUse(definition());
    s->buffer()->Printf(" {%s })", extra.buf());
  } else {
    s->SerializeUse(definition());
  }
}

void Value::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  if (reaching_type_ != nullptr && reaching_type_ != definition()->type_ &&
      ShouldSerializeType(reaching_type_)) {
    s->buffer()->AddString(" type ");
    reaching_type_->SerializeTo(s);
    s->buffer()->AddChar(',');
  }
}

void CompileType::SerializeTo(FlowGraphSerializer* s) const {
  ASSERT(FLAG_verbose_flow_graph_serialization ||
         FLAG_serialize_flow_graph_types);
  ASSERT(cid_ != kDynamicCid || !is_nullable());

  s->buffer()->AddString("(CompileType");
  if (cid_ != kIllegalCid && cid_ != kDynamicCid) {
    s->buffer()->Printf(" %u", cid_);
  }
  s->OptionallySerializeExtraInfo(this);
  s->buffer()->AddChar(')');
}

void CompileType::SerializeExtraInfoTo(FlowGraphSerializer* s) const {
  if (!is_nullable() || FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" nullable %s,", is_nullable() ? "true" : "false");
  }
  if (FLAG_verbose_flow_graph_serialization) {
    s->buffer()->Printf(" name \"%s\",", ToCString());
  }
}

void Environment::SerializeTo(FlowGraphSerializer* s) const {
  s->buffer()->AddChar('[');
  intptr_t arg_count = 0;
  for (intptr_t i = 0; i < values_.length(); ++i) {
    s->buffer()->AddChar(' ');
    if (values_[i]->definition()->IsPushArgument()) {
      s->buffer()->Printf("arg[%" Pd "]", arg_count++);
    } else {
      values_[i]->SerializeTo(s);
    }
    // TODO(sstrickl): This currently assumes that there are no locations in the
    // environment (e.g. before register allocation). If we ever want to print
    // out environments on steps after AllocateRegisters, we'll need to handle
    // locations as well.
    ASSERT(locations_ == nullptr || locations_[i].IsInvalid());
    s->buffer()->AddChar(',');
  }
  if (outer_ != NULL) {
    s->buffer()->AddChar(' ');
    outer_->SerializeTo(s);
    s->buffer()->AddChar(',');
  }
  s->buffer()->AddString(" ]");
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/il_printer.h"

#include "vm/flow_graph_range_analysis.h"
#include "vm/intermediate_language.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

DEFINE_FLAG(bool, print_environments, false, "Print SSA environments.");


void BufferFormatter::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VPrint(format, args);
  va_end(args);
}


void BufferFormatter::VPrint(const char* format, va_list args) {
  intptr_t available = size_ - position_;
  if (available <= 0) return;
  intptr_t written =
      OS::VSNPrint(buffer_ + position_, available, format, args);
  if (written >= 0) {
    position_ += (available <= written) ? available : written;
  }
}


void FlowGraphPrinter::PrintGraph(const char* phase, FlowGraph* flow_graph) {
  OS::Print("*** BEGIN CFG\n%s\n", phase);
  FlowGraphPrinter printer(*flow_graph);
  printer.PrintBlocks();
  OS::Print("*** END CFG\n");
  fflush(stdout);
}


void FlowGraphPrinter::PrintBlock(BlockEntryInstr* block,
                                  bool print_locations) {
  // Print the block entry.
  PrintOneInstruction(block, print_locations);
  OS::Print("\n");
  // And all the successors in the block.
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    PrintOneInstruction(current, print_locations);
    OS::Print("\n");
  }
}


void FlowGraphPrinter::PrintBlocks() {
  if (!function_.IsNull()) {
    OS::Print("==== %s\n", function_.ToFullyQualifiedCString());
  }

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    PrintBlock(block_order_[i], print_locations_);
  }
}


void FlowGraphPrinter::PrintInstruction(Instruction* instr) {
  PrintOneInstruction(instr, print_locations_);
}


void FlowGraphPrinter::PrintOneInstruction(Instruction* instr,
                                           bool print_locations) {
  char str[4000];
  BufferFormatter f(str, sizeof(str));
  instr->PrintTo(&f);
  if (FLAG_print_environments && (instr->env() != NULL)) {
    instr->env()->PrintTo(&f);
  }
  if (print_locations && (instr->locs_ != NULL)) {
    instr->locs()->PrintTo(&f);
  }
  if (instr->lifetime_position() != -1) {
    OS::Print("%3" Pd ": ", instr->lifetime_position());
  }
  if (!instr->IsBlockEntry()) OS::Print("    ");
  OS::Print("%s", str);
}


void FlowGraphPrinter::PrintTypeCheck(const ParsedFunction& parsed_function,
                                      intptr_t token_pos,
                                      Value* value,
                                      const AbstractType& dst_type,
                                      const String& dst_name,
                                      bool eliminated) {
    const char* compile_type_name = "unknown";
    if (value != NULL && value->reaching_type_ != NULL) {
      compile_type_name = value->reaching_type_->ToCString();
    }
    OS::Print("%s type check: compile type %s is %s specific than "
              "type '%s' of '%s'.\n",
                         eliminated ? "Eliminated" : "Generated",
                         compile_type_name,
                         eliminated ? "more" : "not more",
                         String::Handle(dst_type.Name()).ToCString(),
                         dst_name.ToCString());
}


void CompileType::PrintTo(BufferFormatter* f) const {
  const char* type_name = "?";
  if ((cid_ != kIllegalCid) && (cid_ != kDynamicCid)) {
    const Class& cls =
      Class::Handle(Isolate::Current()->class_table()->At(cid_));
    type_name = String::Handle(cls.PrettyName()).ToCString();
  } else if (type_ != NULL &&
             !type_->Equals(Type::Handle(Type::DynamicType()))) {
    type_name = type_->ToCString();
  } else if (!is_nullable()) {
    type_name = "!null";
  }

  f->Print("T{%s%s}", type_name, is_nullable_ ? "?" : "");
}


const char* CompileType::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}


static void PrintICDataHelper(BufferFormatter* f, const ICData& ic_data) {
  f->Print(" IC[%" Pd ": ", ic_data.NumberOfChecks());
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
    const intptr_t count = ic_data.GetCountAt(i);
    if (i > 0) {
      f->Print(" | ");
    }
    for (intptr_t k = 0; k < class_ids.length(); k++) {
      if (k > 0) {
        f->Print(", ");
      }
      const Class& cls =
          Class::Handle(Isolate::Current()->class_table()->At(class_ids[k]));
      f->Print("%s", String::Handle(cls.Name()).ToCString());
    }
    f->Print(" cnt:%" Pd " trgt:'%s'", count, target.ToQualifiedCString());
  }
  f->Print("]");
}


void FlowGraphPrinter::PrintICData(const ICData& ic_data) {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintICDataHelper(&f, ic_data);
  OS::Print("%s ", buffer);
  const Array& a = Array::Handle(ic_data.arguments_descriptor());
  OS::Print(" arg-desc %" Pd "\n", a.Length());
}


static void PrintUse(BufferFormatter* f, const Definition& definition) {
  if (definition.HasSSATemp()) {
    if (definition.HasPairRepresentation()) {
      f->Print("v%" Pd ", v%" Pd "", definition.ssa_temp_index(),
                                     definition.ssa_temp_index() + 1);
    } else {
      f->Print("v%" Pd "", definition.ssa_temp_index());
    }
  } else if (definition.HasTemp()) {
    f->Print("t%" Pd "", definition.temp_index());
  }
}


const char* Instruction::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}


void Instruction::PrintTo(BufferFormatter* f) const {
  if (GetDeoptId() != Isolate::kNoDeoptId) {
    f->Print("%s:%" Pd "(", DebugName(), GetDeoptId());
  } else {
    f->Print("%s(", DebugName());
  }
  PrintOperandsTo(f);
  f->Print(")");
}


void Instruction::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(", ");
    if (InputAt(i) != NULL) InputAt(i)->PrintTo(f);
  }
}


void Definition::PrintTo(BufferFormatter* f) const {
  PrintUse(f, *this);
  if (HasSSATemp() || HasTemp()) f->Print(" <- ");
  if (GetDeoptId() != Isolate::kNoDeoptId) {
    f->Print("%s:%" Pd "(", DebugName(), GetDeoptId());
  } else {
    f->Print("%s(", DebugName());
  }
  PrintOperandsTo(f);
  f->Print(")");
  if (range_ != NULL) {
    f->Print(" ");
    range_->PrintTo(f);
  }

  if (type_ != NULL &&
      ((type_->ToNullableCid() != kDynamicCid) || !type_->is_nullable())) {
    f->Print(" ");
    type_->PrintTo(f);
  }
}


void Definition::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(", ");
    if (InputAt(i) != NULL) {
      InputAt(i)->PrintTo(f);
    }
  }
}


void Value::PrintTo(BufferFormatter* f) const {
  PrintUse(f, *definition());

  if ((reaching_type_ != NULL) &&
      (reaching_type_ != definition()->type_)) {
    f->Print(" ");
    reaching_type_->PrintTo(f);
  }
}


void ConstantInstr::PrintOperandsTo(BufferFormatter* f) const {
  const char* cstr = value().ToCString();
  const char* new_line = strchr(cstr, '\n');
  if (new_line == NULL) {
    f->Print("#%s", cstr);
  } else {
    const intptr_t pos = new_line - cstr;
    char* buffer = Isolate::Current()->current_zone()->Alloc<char>(pos + 1);
    strncpy(buffer, cstr, pos);
    buffer[pos] = '\0';
    f->Print("#%s\\n...", buffer);
  }
}


void ConstraintInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(" ^ ");
  constraint()->PrintTo(f);
}


void Range::PrintTo(BufferFormatter* f) const {
  f->Print("[");
  min_.PrintTo(f);
  f->Print(", ");
  max_.PrintTo(f);
  f->Print("]");
}


const char* Range::ToCString(const Range* range) {
  if (range == NULL) return "[_|_, _|_]";

  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  range->PrintTo(&f);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}


void RangeBoundary::PrintTo(BufferFormatter* f) const {
  switch (kind_) {
    case kSymbol:
      f->Print("v%" Pd "",
               reinterpret_cast<Definition*>(value_)->ssa_temp_index());
      if (offset_ != 0) f->Print("%+" Pd64 "", offset_);
      break;
    case kNegativeInfinity:
      f->Print("-inf");
      break;
    case kPositiveInfinity:
      f->Print("+inf");
      break;
    case kConstant:
      f->Print("%" Pd64 "", value_);
      break;
    case kUnknown:
      f->Print("_|_");
      break;
  }
}


const char* RangeBoundary::ToCString() const {
  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}


void DropTempsInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd "", num_temps());
  if (value() != NULL) {
    f->Print(", ");
    value()->PrintTo(f);
  }
}


void AssertAssignableInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %s, '%s'",
           dst_type().ToCString(),
           dst_name().ToCString());
  f->Print(" instantiator(");
  instantiator()->PrintTo(f);
  f->Print(")");
  f->Print(" instantiator_type_arguments(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print(")");
}


void AssertBooleanInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
}


void ClosureCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" function=");
  InputAt(0)->PrintTo(f);
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    PushArgumentAt(i)->value()->PrintTo(f);
  }
}


void InstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s", function_name().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    PushArgumentAt(i)->value()->PrintTo(f);
  }
  if (HasICData()) {
    PrintICDataHelper(f, *ic_data());
  }
}


void PolymorphicInstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s", instance_call()->function_name().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    PushArgumentAt(i)->value()->PrintTo(f);
  }
  PrintICDataHelper(f, ic_data());
}


void StrictCompareInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
  if (needs_number_check()) {
    f->Print(", with number check");
  }
}


void TestCidsInstr::PrintOperandsTo(BufferFormatter* f) const {
  left()->PrintTo(f);
  f->Print(" %s [", Token::Str(kind()));
  for (intptr_t i = 0; i < cid_results().length(); i += 2) {
    f->Print("0x%" Px ":%s ",
        cid_results()[i], cid_results()[i + 1] == 0 ? "false" : "true");
  }
  f->Print("] ");
}


void EqualityCompareInstr::PrintOperandsTo(BufferFormatter* f) const {
  left()->PrintTo(f);
  f->Print(" %s ", Token::Str(kind()));
  right()->PrintTo(f);
}


void StaticCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s ", String::Handle(function().name()).ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->Print(", ");
    PushArgumentAt(i)->value()->PrintTo(f);
  }
}


void LoadLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", local().name().ToCString());
}


void StoreLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", local().name().ToCString());
  value()->PrintTo(f);
}


void NativeCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", native_name().ToCString());
}


void GuardFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s %s, ",
           String::Handle(field().name()).ToCString(),
           field().GuardedPropertiesAsCString());
  value()->PrintTo(f);
}


void StoreInstanceFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (field().IsNull()) {
    f->Print("{%" Pd "}, ", offset_in_bytes());
  } else {
    f->Print("%s {%" Pd "}, ",
             String::Handle(field().name()).ToCString(),
             field().Offset());
  }
  instance()->PrintTo(f);
  f->Print(", ");
  value()->PrintTo(f);
}


void IfThenElseInstr::PrintOperandsTo(BufferFormatter* f) const {
  comparison()->PrintOperandsTo(f);
  f->Print(" ? %" Pd " : %" Pd,
           if_true_,
           if_false_);
}


void LoadStaticFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  field_value()->PrintTo(f);
}


void StoreStaticFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  value()->PrintTo(f);
}


void InstanceOfInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(" %s %s",
            negate_result() ? "ISNOT" : "IS",
            String::Handle(type().Name()).ToCString());
  f->Print(" instantiator(");
  instantiator()->PrintTo(f);
  f->Print(")");
  f->Print(" type-arg(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print(")");
}


void RelationalOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void AllocateObjectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", cls().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); i++) {
    f->Print(", ");
    PushArgumentAt(i)->value()->PrintTo(f);
  }

  if (Identity().IsNotAliased()) {
    f->Print(" <not-aliased>");
  }
}


void MaterializeObjectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(cls_.Name()).ToCString());
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->Print(", ");
    f->Print("%s: ", slots_[i]->ToCString());
    InputAt(i)->PrintTo(f);
  }
}


void LoadFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  instance()->PrintTo(f);
  f->Print(", %" Pd, offset_in_bytes());

  if (field() != NULL) {
    f->Print(" {%s}", String::Handle(field()->name()).ToCString());
    const char* expected = "?";
    if (field()->guarded_cid() != kIllegalCid) {
      const Class& cls = Class::Handle(
            Isolate::Current()->class_table()->At(field()->guarded_cid()));
      expected = String::Handle(cls.Name()).ToCString();
    }

    f->Print(" [%s %s]",
             field()->is_nullable() ? "nullable" : "non-nullable",
             expected);
  }

  f->Print(", immutable=%d", immutable_);
}


void InstantiateTypeInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_name = String::Handle(type().Name());
  f->Print("%s, ", type_name.ToCString());
  instantiator()->PrintTo(f);
}


void InstantiateTypeArgumentsInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s, ", type_args.ToCString());
  instantiator()->PrintTo(f);
}


void AllocateContextInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd "", num_context_variables());
}


void AllocateUninitializedContextInstr::PrintOperandsTo(
    BufferFormatter* f) const {
  f->Print("%" Pd "", num_context_variables());
}


void MathUnaryInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("'%s', ", MathUnaryInstr::KindToCString(kind()));
  value()->PrintTo(f);
}


void MergedMathInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("'%s', ", MergedMathInstr::KindToCString(kind()));
  Definition::PrintOperandsTo(f);
}


void ExtractNthOutputInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Extract %" Pd " from ", index());
  Definition::PrintOperandsTo(f);
}


void UnaryIntegerOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}


void BinaryIntegerOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", Token::Str(op_kind()));
  if (is_truncating()) {
    f->Print(" [tr]");
  } else if (!can_overflow()) {
    f->Print(" [-o]");
  }
  f->Print(", ");
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void BinaryDoubleOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void BinaryFloat32x4OpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void BinaryFloat64x2OpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void Simd32x4ShuffleInstr::PrintOperandsTo(BufferFormatter* f) const {
  // TODO(johnmccutchan): Add proper string enumeration of shuffle.
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  value()->PrintTo(f);
}


void Simd32x4ShuffleMixInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  xy()->PrintTo(f);
  f->Print(", ");
  zw()->PrintTo(f);
}


void Simd32x4GetSignMaskInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (op_kind() == MethodRecognizer::kFloat32x4GetSignMask) {
    f->Print("Float32x4.getSignMask ");
  } else {
    ASSERT(op_kind() == MethodRecognizer::kInt32x4GetSignMask);
    f->Print("Int32x4.getSignMask ");
  }
  value()->PrintTo(f);
}


void Float32x4SplatInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("SPLAT ");
  value()->PrintTo(f);
}


void Float32x4ConstructorInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float32x4(");
  value0()->PrintTo(f);
  f->Print(", ");
  value1()->PrintTo(f);
  f->Print(", ");
  value2()->PrintTo(f);
  f->Print(", ");
  value3()->PrintTo(f);
  f->Print(")");
}


void Float32x4ComparisonInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float32x4 Comparison %s, ",
           MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void Float32x4MinMaxInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void Float32x4SqrtInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
}


void Float32x4ScaleInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void Float32x4ZeroArgInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
}


void Float32x4ClampInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float32x4.clamp, ");
  left()->PrintTo(f);
}


void Float32x4WithInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  replacement()->PrintTo(f);
}


void Float32x4ToInt32x4Instr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float32x4.toInt32x4 ");
  left()->PrintTo(f);
}


void Simd64x2ShuffleInstr::PrintOperandsTo(BufferFormatter* f) const {
  // TODO(johnmccutchan): Add proper string enumeration of shuffle.
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  value()->PrintTo(f);
}


void Float64x2SplatInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float64x2.splat ");
  value()->PrintTo(f);
}


void Float64x2ConstructorInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float64x2(");
  value0()->PrintTo(f);
  f->Print(", ");
  value1()->PrintTo(f);
  f->Print(")");
}


void Float32x4ToFloat64x2Instr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float64x2.fromFloat32x4 ");
  left()->PrintTo(f);
}


void Float64x2ToFloat32x4Instr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Float32x4.fromFloat64x2 ");
  left()->PrintTo(f);
}


void Float64x2ZeroArgInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
}


void Float64x2OneArgInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s(", MethodRecognizer::KindToCString(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
  f->Print(")");
}


void Int32x4ConstructorInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4(");
  value0()->PrintTo(f);
  f->Print(", ");
  value1()->PrintTo(f);
  f->Print(", ");
  value2()->PrintTo(f);
  f->Print(", ");
  value3()->PrintTo(f);
  f->Print(")");
}


void Int32x4BoolConstructorInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4.bool(");
  value0()->PrintTo(f);
  f->Print(", ");
  value1()->PrintTo(f);
  f->Print(", ");
  value2()->PrintTo(f);
  f->Print(", ");
  value3()->PrintTo(f);
  f->Print(")");
}


void Int32x4GetFlagInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4.%s ", MethodRecognizer::KindToCString(op_kind()));
  value()->PrintTo(f);
}


void Int32x4SetFlagInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4.%s ", MethodRecognizer::KindToCString(op_kind()));
  value()->PrintTo(f);
  f->Print(", ");
  flagValue()->PrintTo(f);
}


void Int32x4SelectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4.select ");
  mask()->PrintTo(f);
  f->Print(", ");
  trueValue()->PrintTo(f);
  f->Print(", ");
  falseValue()->PrintTo(f);
}


void Int32x4ToFloat32x4Instr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("Int32x4.toFloat32x4 ");
  left()->PrintTo(f);
}


void BinaryInt32x4OpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void UnaryDoubleOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}


void CheckClassIdInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);

  const Class& cls =
    Class::Handle(Isolate::Current()->class_table()->At(cid()));
  f->Print(", %s", String::Handle(cls.PrettyName()).ToCString());
}


void CheckClassInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  PrintICDataHelper(f, unary_checks());
  if (IsNullCheck()) {
    f->Print(" nullcheck");
  }
}


void InvokeMathCFunctionInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(recognized_kind_));
  Definition::PrintOperandsTo(f);
}


void GraphEntryInstr::PrintTo(BufferFormatter* f) const {
  const GrowableArray<Definition*>& defns = initial_definitions_;
  f->Print("B%" Pd "[graph]:%" Pd, block_id(), GetDeoptId());
  if (defns.length() > 0) {
    f->Print(" {");
    for (intptr_t i = 0; i < defns.length(); ++i) {
      Definition* def = defns[i];
      f->Print("\n      ");
      def->PrintTo(f);
    }
    f->Print("\n}");
  }
}


void JoinEntryInstr::PrintTo(BufferFormatter* f) const {
  if (try_index() != CatchClauseNode::kInvalidTryIndex) {
    f->Print("B%" Pd "[join try_idx %" Pd "]:%" Pd " pred(",
             block_id(), try_index(), GetDeoptId());
  } else {
    f->Print("B%" Pd "[join]:%" Pd " pred(", block_id(), GetDeoptId());
  }
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (i > 0) f->Print(", ");
    f->Print("B%" Pd, predecessors_[i]->block_id());
  }
  f->Print(")");
  if (phis_ != NULL) {
    f->Print(" {");
    for (intptr_t i = 0; i < phis_->length(); ++i) {
      if ((*phis_)[i] == NULL) continue;
      f->Print("\n      ");
      (*phis_)[i]->PrintTo(f);
    }
    f->Print("\n}");
  }
  if (HasParallelMove()) {
    f->Print(" ");
    parallel_move()->PrintTo(f);
  }
}


static const char *RepresentationToCString(Representation rep) {
  switch (rep) {
    case kTagged:
      return "tagged";
    case kUntagged:
      return "untagged";
    case kUnboxedDouble:
      return "double";
    case kUnboxedInt32:
      return "int32";
    case kUnboxedUint32:
      return "uint32";
    case kUnboxedMint:
      return "mint";
    case kUnboxedFloat32x4:
      return "float32x4";
    case kUnboxedInt32x4:
      return "int32x4";
    case kUnboxedFloat64x2:
      return "float64x2";
    case kPairOfTagged:
      return "tagged-pair";
    case kPairOfUnboxedDouble:
      return "double-pair";
    case kNoRepresentation:
      return "none";
    case kNumRepresentations:
      UNREACHABLE();
  }
  return "?";
}


void PhiInstr::PrintTo(BufferFormatter* f) const {
  f->Print("v%" Pd " <- phi(", ssa_temp_index());
  for (intptr_t i = 0; i < inputs_.length(); ++i) {
    if (inputs_[i] != NULL) inputs_[i]->PrintTo(f);
    if (i < inputs_.length() - 1) f->Print(", ");
  }
  f->Print(")");
  if (is_alive()) {
    f->Print(" alive");
  } else {
    f->Print(" dead");
  }
  if (range_ != NULL) {
    f->Print(" ");
    range_->PrintTo(f);
  }

  if (representation() != kNoRepresentation &&
      representation() != kTagged) {
    f->Print(" %s", RepresentationToCString(representation()));
  }

  if (type_ != NULL) {
    f->Print(" ");
    type_->PrintTo(f);
  }
}


void UnboxIntNInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (is_truncating()) {
    f->Print("[tr], ");
  }
  Definition::PrintOperandsTo(f);
}


void UnboxedIntConverterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s->%s%s, ",
           RepresentationToCString(from()),
           RepresentationToCString(to()),
           is_truncating() ? "[tr]" : "");
  Definition::PrintOperandsTo(f);
}


void ParameterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd, index());
}


void CheckStackOverflowInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (in_loop()) f->Print("depth %" Pd, loop_depth());
}


void TargetEntryInstr::PrintTo(BufferFormatter* f) const {
  if (try_index() != CatchClauseNode::kInvalidTryIndex) {
    f->Print("B%" Pd "[target try_idx %" Pd "]:%" Pd,
             block_id(), try_index(), GetDeoptId());
  } else {
    f->Print("B%" Pd "[target]:%" Pd, block_id(), GetDeoptId());
  }
  if (HasParallelMove()) {
    f->Print(" ");
    parallel_move()->PrintTo(f);
  }
}


void CatchBlockEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[target catch try_idx %" Pd " catch_try_idx %" Pd "]",
           block_id(), try_index(), catch_try_index());
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }

  const GrowableArray<Definition*>& defns = initial_definitions_;
  if (defns.length() > 0) {
    f->Print(" {");
    for (intptr_t i = 0; i < defns.length(); ++i) {
      Definition* def = defns[i];
      f->Print("\n      ");
      def->PrintTo(f);
    }
    f->Print("\n}");
  }
}


void PushArgumentInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
}


void GotoInstr::PrintTo(BufferFormatter* f) const {
  if (HasParallelMove()) {
    parallel_move()->PrintTo(f);
    f->Print(" ");
  }
  if (GetDeoptId() != Isolate::kNoDeoptId) {
    f->Print("goto:%" Pd " %" Pd "", GetDeoptId(), successor()->block_id());
  } else {
    f->Print("goto: %" Pd "", successor()->block_id());
  }
}


void BranchInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%s ", DebugName());
  f->Print("if ");
  comparison()->PrintTo(f);

  f->Print(" goto (%" Pd ", %" Pd ")",
            true_successor()->block_id(),
            false_successor()->block_id());
}


void ParallelMoveInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%s ", DebugName());
  for (intptr_t i = 0; i < moves_.length(); i++) {
    if (i != 0) f->Print(", ");
    moves_[i]->dest().PrintTo(f);
    f->Print(" <- ");
    moves_[i]->src().PrintTo(f);
  }
}


void Environment::PrintTo(BufferFormatter* f) const {
  f->Print(" env={ ");
  int arg_count = 0;
  for (intptr_t i = 0; i < values_.length(); ++i) {
    if (i > 0) f->Print(", ");
    if (values_[i]->definition()->IsPushArgument()) {
      f->Print("a%d", arg_count++);
    } else {
      values_[i]->PrintTo(f);
    }
    if ((locations_ != NULL) && !locations_[i].IsInvalid()) {
      f->Print(" [");
      locations_[i].PrintTo(f);
      f->Print("]");
    }
  }
  f->Print(" }");
  if (outer_ != NULL) outer_->PrintTo(f);
}

const char* Environment::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}

}  // namespace dart

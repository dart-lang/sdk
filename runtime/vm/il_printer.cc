// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/il_printer.h"

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


void FlowGraphPrinter::PrintBlocks() {
  if (!function_.IsNull()) {
    OS::Print("==== %s\n", function_.ToFullyQualifiedCString());
  }

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Print the block entry.
    PrintInstruction(block_order_[i]);
    // And all the successors until an exit, branch, or a block entry.
    Instruction* current = block_order_[i];
    for (ForwardInstructionIterator it(current->AsBlockEntry());
         !it.Done();
         it.Advance()) {
      current = it.Current();
      OS::Print("\n");
      PrintInstruction(current);
    }
    if (current->next() != NULL) {
      ASSERT(current->next()->IsBlockEntry());
      OS::Print(" goto %"Pd"", current->next()->AsBlockEntry()->block_id());
    }
    OS::Print("\n");
  }
}


void FlowGraphPrinter::PrintInstruction(Instruction* instr) {
  PrintOneInstruction(instr, print_locations_);
}


void FlowGraphPrinter::PrintOneInstruction(Instruction* instr,
                                           bool print_locations) {
  char str[1000];
  BufferFormatter f(str, sizeof(str));
  instr->PrintTo(&f);
  if (FLAG_print_environments && (instr->env() != NULL)) {
    instr->env()->PrintTo(&f);
  }
  if (print_locations && (instr->locs() != NULL)) {
    instr->locs()->PrintTo(&f);
  }
  if (instr->lifetime_position() != -1) {
    OS::Print("%3"Pd": ", instr->lifetime_position());
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
    const Script& script = Script::Handle(parsed_function.function().script());
    const char* compile_type_name = "unknown";
    if (value != NULL) {
      const AbstractType& type = AbstractType::Handle(value->CompileType());
      if (!type.IsNull()) {
        compile_type_name = String::Handle(type.Name()).ToCString();
      }
    }
    Parser::PrintMessage(script, token_pos, "",
                         "%s type check: compile type '%s' is %s specific than "
                         "type '%s' of '%s'.",
                         eliminated ? "Eliminated" : "Generated",
                         compile_type_name,
                         eliminated ? "more" : "not more",
                         String::Handle(dst_type.Name()).ToCString(),
                         dst_name.ToCString());
}


static void PrintICData(BufferFormatter* f, const ICData& ic_data) {
  f->Print(" IC[%"Pd": ", ic_data.NumberOfChecks());
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
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
  }
  f->Print("]");
}


static void PrintPropagatedType(BufferFormatter* f, const Definition& def) {
  if (def.HasPropagatedType()) {
    String& name = String::Handle();
    name = AbstractType::Handle(def.PropagatedType()).Name();
    f->Print(" {PT: %s}", name.ToCString());
  }
  if (def.has_propagated_cid()) {
    const Class& cls = Class::Handle(
        Isolate::Current()->class_table()->At(def.propagated_cid()));
    f->Print(" {PCid: %s}", String::Handle(cls.Name()).ToCString());
  }
}


static void PrintUse(BufferFormatter* f, const Definition& definition) {
  if (definition.is_used()) {
    if (definition.HasSSATemp()) {
      f->Print("v%"Pd, definition.ssa_temp_index());
    } else if (definition.temp_index() != -1) {
      f->Print("t%"Pd, definition.temp_index());
    }
  }
}


void Instruction::PrintTo(BufferFormatter* f) const {
  f->Print("%s:%"Pd"(", DebugName(), GetDeoptId());
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
  if (is_used()) {
    if (HasSSATemp() || (temp_index() != -1)) f->Print(" <- ");
  }
  f->Print("%s:%"Pd"(", DebugName(), GetDeoptId());
  PrintOperandsTo(f);
  f->Print(")");
  PrintPropagatedType(f, *this);
  if (range_ != NULL) {
    f->Print(" ");
    range_->PrintTo(f);
  }
}


void Definition::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(", ");
    if (InputAt(i) != NULL) InputAt(i)->PrintTo(f);
  }
}


void Value::PrintTo(BufferFormatter* f) const {
  PrintUse(f, *definition());
}


void ConstantInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("#%s", value().ToCString());
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


const char* Range::ToCString(Range* range) {
  if (range == NULL) return "[_|_, _|_]";

  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  range->PrintTo(&f);
  return Isolate::Current()->current_zone()->MakeCopyOfString(buffer);
}


void RangeBoundary::PrintTo(BufferFormatter* f) const {
  switch (kind_) {
    case kSymbol:
      f->Print("v%"Pd, reinterpret_cast<Definition*>(value_)->ssa_temp_index());
      if (offset_ != 0) f->Print("%+"Pd, offset_);
      break;
    case kConstant:
      if (value_ == kMinusInfinity) {
        f->Print("-inf");
      } else if (value_ == kPlusInfinity) {
        f->Print("+inf");
      } else {
        f->Print("%"Pd, value_);
      }
      break;
    case kUnknown:
      f->Print("_|_");
      break;
  }
}


void AssertAssignableInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %s, '%s'%s",
           String::Handle(dst_type().Name()).ToCString(),
           dst_name().ToCString(),
           is_eliminated() ? " eliminated" : "");
  f->Print(" instantiator(");
  instantiator()->PrintTo(f);
  f->Print(")");
  f->Print(" instantiator_type_arguments(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print(")");
}


void AssertBooleanInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print("%s", is_eliminated() ? " eliminated" : "");
}


void ArgumentDefinitionTestInstr::PrintOperandsTo(BufferFormatter* f) const {
  saved_arguments_descriptor()->PrintTo(f);
  f->Print(", ?%s @%"Pd"",
           formal_parameter_name().ToCString(),
           formal_parameter_index());
}


void ClosureCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
}


void InstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", function_name().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
  if (HasICData()) {
    PrintICData(f, *ic_data());
  }
}


void PolymorphicInstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  instance_call()->PrintOperandsTo(f);
}


void StrictCompareInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void EqualityCompareInstr::PrintOperandsTo(BufferFormatter* f) const {
  left()->PrintTo(f);
  f->Print(" %s ", Token::Str(kind()));
  right()->PrintTo(f);
  if (HasICData()) {
    PrintICData(f, *ic_data());
  }
}


void StaticCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s ", String::Handle(function().name()).ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
}


void LoadLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s lvl:%"Pd"", local().name().ToCString(), context_level());
}


void StoreLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", local().name().ToCString());
  value()->PrintTo(f);
  f->Print(", lvl: %"Pd"", context_level());
}


void NativeCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", native_name().ToCString());
}


void StoreInstanceFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  instance()->PrintTo(f);
  f->Print(", ");
  value()->PrintTo(f);
}


void LoadStaticFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(field().name()).ToCString());
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
  if (HasICData()) {
    PrintICData(f, *ic_data());
  }
}


void AllocateObjectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", Class::Handle(constructor().Owner()).ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); i++) {
    f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
}


void AllocateObjectWithBoundsCheckInstr::PrintOperandsTo(
    BufferFormatter* f) const {
  f->Print("%s", Class::Handle(constructor().Owner()).ToCString());
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->Print(", ");
    InputAt(i)->PrintTo(f);
  }
}


void CreateArrayInstr::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < ArgumentCount(); ++i) {
    if (i != 0) f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
  if (ArgumentCount() > 0) f->Print(", ");
  element_type()->PrintTo(f);
}


void CreateClosureInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", function().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->Print(", ");
    ArgumentAt(i)->value()->PrintTo(f);
  }
}


void LoadFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %"Pd", immutable=%d", offset_in_bytes(), immutable_);
}


void StoreVMFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  dest()->PrintTo(f);
  f->Print(", %"Pd", ", offset_in_bytes());
  value()->PrintTo(f);
}


void InstantiateTypeArgumentsInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s, ", type_args.ToCString());
  instantiator()->PrintTo(f);
}


void ExtractConstructorTypeArgumentsInstr::PrintOperandsTo(
    BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s, ", type_args.ToCString());
  instantiator()->PrintTo(f);
}


void AllocateContextInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%"Pd"", num_context_variables());
}


void CatchEntryInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, %s",
           exception_var().name().ToCString(),
           stacktrace_var().name().ToCString());
}


void BinarySmiOpInstr::PrintTo(BufferFormatter* f) const {
  Definition::PrintTo(f);
  f->Print(" %co", overflow_ ? '+' : '-');
}

void BinarySmiOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
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


void BinaryMintOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void ShiftMintOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void UnaryMintOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}


void UnarySmiOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}


void CheckClassInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  PrintICData(f, unary_checks());
}


void GraphEntryInstr::PrintTo(BufferFormatter* f) const {
  const GrowableArray<Definition*>& defns = initial_definitions_;
  f->Print("B%"Pd"[graph]", block_id());
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
  f->Print("B%"Pd"[join] pred(", block_id());
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (i > 0) f->Print(", ");
    f->Print("B%"Pd, predecessors_[i]->block_id());
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


void PhiInstr::PrintTo(BufferFormatter* f) const {
  f->Print("v%"Pd" <- phi(", ssa_temp_index());
  for (intptr_t i = 0; i < inputs_.length(); ++i) {
    if (inputs_[i] != NULL) inputs_[i]->PrintTo(f);
    if (i < inputs_.length() - 1) f->Print(", ");
  }
  f->Print(")");
  PrintPropagatedType(f, *this);
  if (is_alive()) {
    f->Print(" alive");
  } else {
    f->Print(" dead");
  }
  if (range_ != NULL) {
    f->Print(" ");
    range_->PrintTo(f);
  }
}


void ParameterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%"Pd, index());
}


void TargetEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%"Pd"[target", block_id());
  if (IsCatchEntry()) {
    f->Print(" catch %"Pd"]", catch_try_index());
  } else {
    f->Print("]");
  }
  if (HasParallelMove()) {
    f->Print(" ");
    parallel_move()->PrintTo(f);
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
  f->Print("goto:%"Pd" %"Pd"", GetDeoptId(), successor()->block_id());
}


void BranchInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%s ", DebugName());
  f->Print("if ");
  comparison()->PrintTo(f);

  f->Print(" goto (%"Pd", %"Pd")",
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

}  // namespace dart

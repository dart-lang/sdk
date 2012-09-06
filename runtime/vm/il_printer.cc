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


void Definition::PrintTo(BufferFormatter* f) const {
  // Do not access 'deopt_id()' as it asserts that the computation can
  // deoptimize.
  if (HasSSATemp()) {
    f->Print("v%"Pd" <- ", ssa_temp_index());
  }
  f->Print("%s:%"Pd"(", DebugName(), deopt_id_);
  PrintOperandsTo(f);
  f->Print(")");
}


void Definition::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(", ");
    if (InputAt(i) != NULL) InputAt(i)->PrintTo(f);
  }
}


void Definition::PrintToVisualizer(BufferFormatter* f) const {
  PrintTo(f);
}


void Value::PrintTo(BufferFormatter* f) const {
  if (definition()->HasSSATemp()) {
    f->Print("v%"Pd"", definition()->ssa_temp_index());
  } else {
    f->Print("t%"Pd"", definition()->temp_index());
  }
}


void ConstantInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("#%s", value().ToCString());
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


void PolymorphicInstanceCallInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%s(", DebugName());
  instance_call()->PrintOperandsTo(f);
  f->Print(") ");
  PrintICData(f, ic_data());
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


void LoadInstanceFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  instance()->PrintTo(f);
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


void LoadVMFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %"Pd"", offset_in_bytes());
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


void BinarySmiOpInstr::PrintOperandsTo(BufferFormatter* f) const {
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


void UnboxedDoubleBinaryOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
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
  f->Print("%2"Pd": [graph]", block_id());
  if (start_env_ != NULL) {
    f->Print("\n{\n");
    const GrowableArray<Value*>& values = start_env_->values();
    for (intptr_t i = 0; i < values.length(); i++) {
      Definition* def = values[i]->definition();
      f->Print("  ");
      def->PrintTo(f);
      f->Print("\n");
    }
    f->Print("} ");
    start_env_->PrintTo(f);
  }
}


void JoinEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%2"Pd": [join]", block_id());
  if (phis_ != NULL) {
    for (intptr_t i = 0; i < phis_->length(); ++i) {
      if ((*phis_)[i] == NULL) continue;
      f->Print("\n");
      (*phis_)[i]->PrintTo(f);
    }
  }
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }
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


void PhiInstr::PrintTo(BufferFormatter* f) const {
  f->Print("     v%"Pd" <- phi(", ssa_temp_index());
  for (intptr_t i = 0; i < inputs_.length(); ++i) {
    if (inputs_[i] != NULL) inputs_[i]->PrintTo(f);
    if (i < inputs_.length() - 1) f->Print(", ");
  }
  f->Print(")");
  PrintPropagatedType(f, *this);
}


void ParameterInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    v%"Pd" <- parameter(%"Pd")",
           HasSSATemp() ? ssa_temp_index() : temp_index(),
           index());
  PrintPropagatedType(f, *this);
}


void TargetEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%2"Pd": [target", block_id());
  if (IsCatchEntry()) {
    f->Print(" catch %"Pd"]", catch_try_index());
  } else {
    f->Print("]");
  }
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }
}


void PushArgumentInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  value()->PrintTo(f);
}


void ReturnInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  value()->PrintTo(f);
}


void ThrowInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s" , DebugName());
}


void ReThrowInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
}


void GotoInstr::PrintTo(BufferFormatter* f) const {
  if (HasParallelMove()) {
    parallel_move()->PrintTo(f);
  } else {
    f->Print("    ");
  }
  f->Print(" goto:%"Pd" %"Pd"", GetDeoptId(), successor()->block_id());
}


void BranchInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  f->Print("if ");
  comparison()->PrintTo(f);

  f->Print(" goto (%"Pd", %"Pd")",
            true_successor()->block_id(),
            false_successor()->block_id());
}


void ParallelMoveInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  for (intptr_t i = 0; i < moves_.length(); i++) {
    if (i != 0) f->Print(", ");
    moves_[i]->dest().PrintTo(f);
    f->Print(" <- ");
    moves_[i]->src().PrintTo(f);
  }
}


void FlowGraphVisualizer::Print(const char* format, ...) {
  char str[1000];
  BufferFormatter f(str, sizeof(str));
  f.Print("%*s", static_cast<int>(2 * indent_), "");
  va_list args;
  va_start(args, format);
  f.VPrint(format, args);
  va_end(args);
  (*Dart::flow_graph_writer())(str, strlen(str));
}


void FlowGraphVisualizer::PrintInstruction(Instruction* instr) {
  char str[1000];
  BufferFormatter f(str, sizeof(str));
  instr->PrintToVisualizer(&f);
  if (FLAG_print_environments && (instr->env() != NULL)) {
    instr->env()->PrintTo(&f);
  }
  f.Print(" <|@\n");
  (*Dart::flow_graph_writer())(str, strlen(str));
}


void FlowGraphVisualizer::PrintFunction() {
#define BEGIN(name)          \
  Print("begin_%s\n", name); \
  indent_++;
#define END(name)          \
  Print("end_%s\n", name); \
  indent_--;

  {
    BEGIN("compilation");
    const char* name = function_.ToFullyQualifiedCString();
    Print("%s \"%s\"\n", "name", name);
    Print("%s \"%s\"\n", "method", name);
    Print("%s %d\n", "date", 0);  // Required field. Unused.
    END("compilation");
  }

  {
    BEGIN("cfg");
    Print("%s \"%s\"\n", "name", "Flow graph builder");

    for (intptr_t i = 0; i < block_order_.length(); ++i) {
      BEGIN("block");
      BlockEntryInstr* entry = block_order_[i];
      Print("%s \"B%"Pd"\"\n", "name", entry->block_id());
      Print("%s %d\n", "from_bci", -1);  // Required field. Unused.
      Print("%s %d\n", "to_bci", -1);  // Required field. Unused.

      Print("predecessors");
      for (intptr_t j = 0; j < entry->PredecessorCount(); ++j) {
        BlockEntryInstr* pred = entry->PredecessorAt(j);
        Print(" \"B%"Pd"\"", pred->block_id());
      }
      Print("\n");

      Print("successors");
      Instruction* last = entry->last_instruction();
      for (intptr_t j = 0; j < last->SuccessorCount(); ++j) {
        intptr_t next_id = last->SuccessorAt(j)->block_id();
        Print(" \"B%"Pd"\"", next_id);
      }
      Print("\n");

      // TODO(fschneider): Use this for exception handlers.
      Print("xhandlers\n");

      // Can be freely used to mark blocks
      Print("flags\n");

      if (entry->dominator() != NULL) {
        Print("%s \"B%"Pd"\"\n", "dominator", entry->dominator()->block_id());
      }

      // TODO(fschneider): Mark blocks with loop nesting level.
      Print("%s %d\n", "loop_depth", 0);

      {
        BEGIN("states");  // Required section.
        {
          BEGIN("locals");  // Required section.
          JoinEntryInstr* join = entry->AsJoinEntry();
          intptr_t num_phis = (join != NULL && join->phi_count())
              ? join->phis()->length()
              : 0;
          Print("%s %"Pd"\n", "size", num_phis);
          for (intptr_t j = 0; j < num_phis; ++j) {
            PhiInstr* phi = (*join->phis())[j];
            if (phi != NULL) {
              Print("%"Pd" ", j);  // Print variable index.
              char buffer[120];
              BufferFormatter formatter(buffer, sizeof(buffer));
              phi->PrintToVisualizer(&formatter);
              Print("%s\n", buffer);
            }
          }
          END("locals");
        }
        END("states");
      }

      {
        BEGIN("HIR");
        // Print the block entry.
        Print("0 0 ");  // Required fields "bci" and "use". Unused.
        PrintInstruction(block_order_[i]);
        // And all the successors until an exit, branch, or a block entry.
        BlockEntryInstr* entry = block_order_[i];
        Instruction* current = entry;
        for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
          current = it.Current();
          Print("0 0 ");
          PrintInstruction(current);
        }
        if (current->next() != NULL) {
          ASSERT(current->next()->IsBlockEntry());
          Print("0 0 _ Goto B%"Pd" <|@\n",
                current->next()->AsBlockEntry()->block_id());
        }
        END("HIR");
      }
      END("block");
    }
    END("cfg");
  }
#undef BEGIN
#undef END
}


// === Printing instructions in a visualizer-understandable format:
// "result instruction(op1, op2)" where result is a temporary name
// or _ for instruction without result.
void GraphEntryInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ [graph]");
  if (start_env_ != NULL) {
    start_env_->PrintTo(f);
  }
}


void JoinEntryInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ [join]");
}


void PhiInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("v%"Pd" [", ssa_temp_index());
  for (intptr_t i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(" ");
    InputAt(i)->PrintTo(f);
  }
  f->Print("]");
}


void ParameterInstr::PrintToVisualizer(BufferFormatter* f) const {
  ASSERT(HasSSATemp());
  ASSERT(temp_index() == -1);
  f->Print("v%"Pd" Parameter(%"Pd")", ssa_temp_index(), index());
}


void TargetEntryInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ [target");
  if (IsCatchEntry()) {
    f->Print(" catch %"Pd"]", catch_try_index());
  } else {
    f->Print("]");
  }
}


void PushArgumentInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ %s ", DebugName());
  value()->PrintTo(f);
}


void ReturnInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ %s ", DebugName());
  value()->PrintTo(f);
}


void ThrowInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ %s ", DebugName());
}


void ReThrowInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ %s ", DebugName());
}


void GotoInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ goto B%"Pd"", successor()->block_id());
}


void BranchInstr::PrintToVisualizer(BufferFormatter* f) const {
  f->Print("_ %s ", DebugName());
  f->Print("if ");
  comparison()->PrintTo(f);
  f->Print(" goto (B%"Pd", B%"Pd")",
            true_successor()->block_id(),
            false_successor()->block_id());
}


void ParallelMoveInstr::PrintToVisualizer(BufferFormatter* f) const {
  UNIMPLEMENTED();
}


void Environment::PrintTo(BufferFormatter* f) const {
  f->Print(" env={ ");
  for (intptr_t i = 0; i < values_.length(); ++i) {
    if (i > 0) f->Print(", ");
    values_[i]->PrintTo(f);
    if ((locations_ != NULL) && !locations_[i].IsInvalid()) {
      f->Print(" [");
      locations_[i].PrintTo(f);
      f->Print("]");
    }
  }
  f->Print(" }");
}

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_printer.h"

#include "vm/compiler/api/print_filter.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

DEFINE_FLAG(bool,
            display_sorted_ic_data,
            false,
            "Calls display a unary, sorted-by count form of ICData");
DEFINE_FLAG(bool, print_environments, false, "Print SSA environments.");

DECLARE_FLAG(bool, trace_inlining_intervals);

bool FlowGraphPrinter::ShouldPrint(const Function& function) {
  return compiler::PrintFilter::ShouldPrint(function);
}

void FlowGraphPrinter::PrintGraph(const char* phase, FlowGraph* flow_graph) {
  LogBlock lb;
  THR_Print("*** BEGIN CFG\n%s\n", phase);
  FlowGraphPrinter printer(*flow_graph);
  printer.PrintBlocks();
  THR_Print("*** END CFG\n");
  fflush(stdout);
}

void FlowGraphPrinter::PrintBlock(BlockEntryInstr* block,
                                  bool print_locations) {
  // Print the block entry.
  PrintOneInstruction(block, print_locations);
  THR_Print("\n");
  // And all the successors in the block.
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    PrintOneInstruction(current, print_locations);
    THR_Print("\n");
  }
}

void FlowGraphPrinter::PrintBlocks() {
  if (!function_.IsNull()) {
    THR_Print("==== %s\n", function_.ToFullyQualifiedCString());
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
  if (print_locations && (instr->HasLocs())) {
    instr->locs()->PrintTo(&f);
  }
  if (FlowGraphAllocator::HasLifetimePosition(instr)) {
    THR_Print("%3" Pd ": ", FlowGraphAllocator::GetLifetimePosition(instr));
  }
  if (!instr->IsBlockEntry()) THR_Print("    ");
  THR_Print("%s", str);
  if (FLAG_trace_inlining_intervals) {
    THR_Print(" iid: %" Pd "", instr->inlining_id());
  }
}

void FlowGraphPrinter::PrintTypeCheck(const ParsedFunction& parsed_function,
                                      TokenPosition token_pos,
                                      Value* value,
                                      const AbstractType& dst_type,
                                      const String& dst_name,
                                      bool eliminated) {
  const char* compile_type_name = "unknown";
  if (value != NULL && value->reaching_type_ != NULL) {
    compile_type_name = value->reaching_type_->ToCString();
  }
  THR_Print(
      "%s type check: compile type %s is %s specific than "
      "type '%s' of '%s'.\n",
      eliminated ? "Eliminated" : "Generated", compile_type_name,
      eliminated ? "more" : "not more",
      String::Handle(dst_type.Name()).ToCString(), dst_name.ToCString());
}

static void PrintTargetsHelper(BufferFormatter* f,
                               const CallTargets& targets,
                               intptr_t num_checks_to_print) {
  f->Print(" Targets[");
  f->Print("%" Pd ": ", targets.length());
  Function& target = Function::Handle();
  if ((num_checks_to_print == FlowGraphPrinter::kPrintAll) ||
      (num_checks_to_print > targets.length())) {
    num_checks_to_print = targets.length();
  }
  for (intptr_t i = 0; i < num_checks_to_print; i++) {
    const CidRange& range = targets[i];
    const auto target_info = targets.TargetAt(i);
    const intptr_t count = target_info->count;
    target = target_info->target->raw();
    if (i > 0) {
      f->Print(" | ");
    }
    if (range.IsSingleCid()) {
      const Class& cls =
          Class::Handle(Isolate::Current()->class_table()->At(range.cid_start));
      f->Print("%s", String::Handle(cls.Name()).ToCString());
      f->Print(" cid %" Pd " cnt:%" Pd " trgt:'%s'", range.cid_start, count,
               target.ToQualifiedCString());
    } else {
      const Class& cls = Class::Handle(target.Owner());
      f->Print("cid %" Pd "-%" Pd " %s", range.cid_start, range.cid_end,
               String::Handle(cls.Name()).ToCString());
      f->Print(" cnt:%" Pd " trgt:'%s'", count, target.ToQualifiedCString());
    }

    if (target_info->exactness.IsTracking()) {
      f->Print(" %s", target_info->exactness.ToCString());
    }
  }
  if (num_checks_to_print < targets.length()) {
    f->Print("...");
  }
  f->Print("]");
}

static void PrintCidsHelper(BufferFormatter* f,
                            const Cids& targets,
                            intptr_t num_checks_to_print) {
  f->Print(" Cids[");
  f->Print("%" Pd ": ", targets.length());
  if ((num_checks_to_print == FlowGraphPrinter::kPrintAll) ||
      (num_checks_to_print > targets.length())) {
    num_checks_to_print = targets.length();
  }
  for (intptr_t i = 0; i < num_checks_to_print; i++) {
    const CidRange& range = targets[i];
    if (i > 0) {
      f->Print(" | ");
    }
    const Class& cls =
        Class::Handle(Isolate::Current()->class_table()->At(range.cid_start));
    f->Print("%s etc. ", String::Handle(cls.Name()).ToCString());
    if (range.IsSingleCid()) {
      f->Print(" cid %" Pd, range.cid_start);
    } else {
      f->Print(" cid %" Pd "-%" Pd, range.cid_start, range.cid_end);
    }
  }
  if (num_checks_to_print < targets.length()) {
    f->Print("...");
  }
  f->Print("]");
}

static void PrintICDataHelper(BufferFormatter* f,
                              const ICData& ic_data,
                              intptr_t num_checks_to_print) {
  f->Print(" IC[");
  if (ic_data.is_tracking_exactness()) {
    f->Print("(%s) ",
             AbstractType::Handle(ic_data.receivers_static_type()).ToCString());
  }
  f->Print("%" Pd ": ", ic_data.NumberOfChecks());
  Function& target = Function::Handle();
  if ((num_checks_to_print == FlowGraphPrinter::kPrintAll) ||
      (num_checks_to_print > ic_data.NumberOfChecks())) {
    num_checks_to_print = ic_data.NumberOfChecks();
  }
  for (intptr_t i = 0; i < num_checks_to_print; i++) {
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
    if (ic_data.is_tracking_exactness()) {
      f->Print(" %s", ic_data.GetExactnessAt(i).ToCString());
    }
  }
  if (num_checks_to_print < ic_data.NumberOfChecks()) {
    f->Print("...");
  }
  f->Print("]");
}

static void PrintICDataSortedHelper(BufferFormatter* f,
                                    const ICData& ic_data_orig) {
  const ICData& ic_data =
      ICData::Handle(ic_data_orig.AsUnaryClassChecksSortedByCount());
  f->Print(" IC[n:%" Pd "; ", ic_data.NumberOfChecks());
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    const intptr_t count = ic_data.GetCountAt(i);
    const intptr_t cid = ic_data.GetReceiverClassIdAt(i);
    const Class& cls =
        Class::Handle(Isolate::Current()->class_table()->At(cid));
    f->Print("%s : %" Pd ", ", String::Handle(cls.Name()).ToCString(), count);
  }
  f->Print("]");
}

void FlowGraphPrinter::PrintICData(const ICData& ic_data,
                                   intptr_t num_checks_to_print) {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintICDataHelper(&f, ic_data, num_checks_to_print);
  THR_Print("%s ", buffer);
  const Array& a = Array::Handle(ic_data.arguments_descriptor());
  THR_Print(" arg-desc %" Pd "\n", a.Length());
}

void FlowGraphPrinter::PrintCidRangeData(const CallTargets& targets,
                                         intptr_t num_checks_to_print) {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTargetsHelper(&f, targets, num_checks_to_print);
  THR_Print("%s ", buffer);
  // TODO(erikcorry): Print args descriptor.
}

static void PrintUse(BufferFormatter* f, const Definition& definition) {
  if (definition.HasSSATemp()) {
    if (definition.HasPairRepresentation()) {
      f->Print("(v%" Pd ", v%" Pd ")", definition.ssa_temp_index(),
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
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void Instruction::PrintTo(BufferFormatter* f) const {
  if (GetDeoptId() != DeoptId::kNone) {
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
  if (GetDeoptId() != DeoptId::kNone) {
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

  if (type_ != NULL) {
    f->Print(" ");
    type_->PrintTo(f);
  }
}

void CheckNullInstr::PrintOperandsTo(BufferFormatter* f) const {
  Definition::PrintOperandsTo(f);
  switch (exception_type()) {
    case kNoSuchMethod:
      f->Print(", NoSuchMethodError");
      break;
    case kArgumentError:
      f->Print(", ArgumentError");
      break;
    case kCastError:
      f->Print(", CastError");
      break;
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

void RedefinitionInstr::PrintOperandsTo(BufferFormatter* f) const {
  Definition::PrintOperandsTo(f);
  if (constrained_type_ != nullptr) {
    f->Print(" ^ %s", constrained_type_->ToCString());
  }
}

void ReachabilityFenceInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
}

void Value::PrintTo(BufferFormatter* f) const {
  PrintUse(f, *definition());

  if ((reaching_type_ != NULL) && (reaching_type_ != definition()->type_)) {
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
    char* buffer = Thread::Current()->zone()->Alloc<char>(pos + 1);
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
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
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
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void MakeTempInstr::PrintOperandsTo(BufferFormatter* f) const {}

void DropTempsInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd "", num_temps());
  if (value() != NULL) {
    f->Print(", ");
    value()->PrintTo(f);
  }
}

void AssertAssignableInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", ");
  dst_type()->PrintTo(f);
  f->Print(", '%s',", dst_name().ToCString());
  f->Print(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Print(")");
}

void AssertSubtypeInstr::PrintOperandsTo(BufferFormatter* f) const {
  sub_type()->PrintTo(f);
  f->Print(", ");
  super_type()->PrintTo(f);
  f->Print(", '%s', ", dst_name().ToCString());
  f->Print(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Print(")");
}

void AssertBooleanInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
}

void ClosureCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" function=");
  InputAt(InputCount() - 1)->PrintTo(f);
  f->Print("<%" Pd ">", type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->Print(" using unchecked entrypoint");
  }
}

void InstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s<%" Pd ">", function_name().ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  if (HasICData()) {
    if (FLAG_display_sorted_ic_data) {
      PrintICDataSortedHelper(f, *ic_data());
    } else {
      PrintICDataHelper(f, *ic_data(), FlowGraphPrinter::kPrintAll);
    }
  }
  if (result_type() != nullptr) {
    f->Print(", result_type = %s", result_type()->ToCString());
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->Print(" using unchecked entrypoint");
  }
}

void PolymorphicInstanceCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s<%" Pd ">", function_name().ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  PrintTargetsHelper(f, targets_, FlowGraphPrinter::kPrintAll);
  if (complete()) {
    f->Print(" COMPLETE");
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->Print(" using unchecked entrypoint");
  }
}

void DispatchTableCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& name =
      String::Handle(interface_target().QualifiedUserVisibleName());
  f->Print(" cid=");
  class_id()->PrintTo(f);
  f->Print(" %s<%" Pd ">", name.ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
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
  intptr_t length = cid_results().length();
  for (intptr_t i = 0; i < length; i += 2) {
    f->Print("0x%" Px ":%s ", cid_results()[i],
             cid_results()[i + 1] == 0 ? "false" : "true");
  }
  f->Print("] ");
  if (CanDeoptimize()) {
    ASSERT(deopt_id() != DeoptId::kNone);
    f->Print("else deoptimize ");
  } else {
    ASSERT(deopt_id() == DeoptId::kNone);
    f->Print("else %s ", cid_results()[length - 1] != 0 ? "false" : "true");
  }
}

void EqualityCompareInstr::PrintOperandsTo(BufferFormatter* f) const {
  left()->PrintTo(f);
  f->Print(" %s ", Token::Str(kind()));
  right()->PrintTo(f);
}

void StaticCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" %s<%" Pd "> ", String::Handle(function().name()).ToCString(),
           type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->Print(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->Print(", using unchecked entrypoint");
  }
  if (function().recognized_kind() != MethodRecognizer::kUnknown) {
    f->Print(", recognized_kind = %s",
             MethodRecognizer::KindToCString(function().recognized_kind()));
  }
  if (result_type() != nullptr) {
    f->Print(", result_type = %s", result_type()->ToCString());
  }
}

void LoadLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s @%d", local().name().ToCString(), local().index().value());
}

void StoreLocalInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s @%d, ", local().name().ToCString(), local().index().value());
  value()->PrintTo(f);
}

void NativeCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", native_name().ToCString());
}

void GuardFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s %s, ", String::Handle(field().name()).ToCString(),
           field().GuardedPropertiesAsCString());
  value()->PrintTo(f);
}

void StoreInstanceFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  instance()->PrintTo(f);
  f->Print(" . %s = ", slot().Name());
  value()->PrintTo(f);

  // Here, we just print the value of the enum field. We would prefer to get
  // the final decision on whether a store barrier will be emitted by calling
  // ShouldEmitStoreBarrier(), but that can change parts of the flow graph.
  if (emit_store_barrier_ == kNoStoreBarrier) {
    f->Print(", NoStoreBarrier");
  }
}

void IfThenElseInstr::PrintOperandsTo(BufferFormatter* f) const {
  comparison()->PrintOperandsTo(f);
  f->Print(" ? %" Pd " : %" Pd, if_true_, if_false_);
}

void LoadStaticFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(field().name()).ToCString());
  if (calls_initializer()) {
    f->Print(", CallsInitializer");
  }
}

void StoreStaticFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  value()->PrintTo(f);
}

void InstanceOfInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(" IS %s,", String::Handle(type().Name()).ToCString());
  f->Print(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Print(")");
}

void RelationalOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}

void AllocateObjectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(cls().ScrubbedName()).ToCString());
  for (intptr_t i = 0; i < InputCount(); ++i) {
    f->Print(", ");
    InputAt(i)->PrintTo(f);
  }
  if (Identity().IsNotAliased()) {
    f->Print(" <not-aliased>");
  }
}

void MaterializeObjectInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(cls_.ScrubbedName()).ToCString());
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->Print(", ");
    f->Print("%s: ", slots_[i]->Name());
    InputAt(i)->PrintTo(f);
  }
}

void LoadFieldInstr::PrintOperandsTo(BufferFormatter* f) const {
  instance()->PrintTo(f);
  f->Print(" . %s%s", slot().Name(), slot().is_immutable() ? " {final}" : "");
  if (calls_initializer()) {
    f->Print(", CallsInitializer");
  }
}

void LoadUntaggedInstr::PrintOperandsTo(BufferFormatter* f) const {
  object()->PrintTo(f);
  f->Print(", %" Pd, offset());
}

void InstantiateTypeInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_name = String::Handle(type().Name());
  f->Print("%s,", type_name.ToCString());
  f->Print(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Print(")");
}

void InstantiateTypeArgumentsInstr::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s,", type_args.ToCString());
  f->Print(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->Print("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Print("), instantiator_class(%s)", instantiator_class().ToCString());
}

void AllocateContextInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd "", num_context_variables());
}

void AllocateUninitializedContextInstr::PrintOperandsTo(
    BufferFormatter* f) const {
  f->Print("%" Pd "", num_context_variables());

  if (Identity().IsNotAliased()) {
    f->Print(" <not-aliased>");
  }
}

void MathUnaryInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("'%s', ", MathUnaryInstr::KindToCString(kind()));
  value()->PrintTo(f);
}

void TruncDivModInstr::PrintOperandsTo(BufferFormatter* f) const {
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

void CheckedSmiOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", Token::Str(op_kind()));
  f->Print(", ");
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}

void CheckedSmiComparisonInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", Token::Str(kind()));
  f->Print(", ");
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
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

void DoubleTestOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      f->Print("IsNaN ");
      break;
    case MethodRecognizer::kDouble_getIsInfinite:
      f->Print("IsInfinite ");
      break;
    default:
      UNREACHABLE();
  }
  value()->PrintTo(f);
}

static const char* simd_op_kind_string[] = {
#define CASE(Arity, Mask, Name, ...) #Name,
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
};

void SimdOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", simd_op_kind_string[kind()]);
  if (HasMask()) {
    f->Print(", mask = %" Pd "", mask());
  }
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->Print(", ");
    InputAt(i)->PrintTo(f);
  }
}

void UnaryDoubleOpInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}

void LoadClassIdInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (!input_can_be_smi_) {
    f->Print("<non-smi> ");
  }
  object()->PrintTo(f);
}

void CheckClassIdInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);

  const Class& cls =
      Class::Handle(Isolate::Current()->class_table()->At(cids().cid_start));
  const String& name = String::Handle(cls.ScrubbedName());
  if (cids().IsSingleCid()) {
    f->Print(", %s", name.ToCString());
  } else {
    const Class& cls2 =
        Class::Handle(Isolate::Current()->class_table()->At(cids().cid_end));
    const String& name2 = String::Handle(cls2.ScrubbedName());
    f->Print(", cid %" Pd "-%" Pd " %s-%s", cids().cid_start, cids().cid_end,
             name.ToCString(), name2.ToCString());
  }
}

void CheckClassInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  PrintCidsHelper(f, cids_, FlowGraphPrinter::kPrintAll);
  if (IsNullCheck()) {
    f->Print(" nullcheck");
  }
}

void CheckConditionInstr::PrintOperandsTo(BufferFormatter* f) const {
  comparison()->PrintOperandsTo(f);
}

void InvokeMathCFunctionInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", MethodRecognizer::KindToCString(recognized_kind_));
  Definition::PrintOperandsTo(f);
}

void BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(
    BufferFormatter* f) const {
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

void GraphEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[graph]:%" Pd, block_id(), GetDeoptId());
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void JoinEntryInstr::PrintTo(BufferFormatter* f) const {
  if (try_index() != kInvalidTryIndex) {
    f->Print("B%" Pd "[join try_idx %" Pd "]:%" Pd " pred(", block_id(),
             try_index(), GetDeoptId());
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

void IndirectEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[join indirect", block_id());
  if (try_index() != kInvalidTryIndex) {
    f->Print(" try_idx %" Pd, try_index());
  }
  f->Print("]:%" Pd " pred(", GetDeoptId());
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

const char* RepresentationToCString(Representation rep) {
  switch (rep) {
    case kTagged:
      return "tagged";
    case kUntagged:
      return "untagged";
    case kUnboxedDouble:
      return "double";
    case kUnboxedFloat:
      return "float";
    case kUnboxedInt32:
      return "int32";
    case kUnboxedUint32:
      return "uint32";
    case kUnboxedInt64:
      return "int64";
    case kUnboxedFloat32x4:
      return "float32x4";
    case kUnboxedInt32x4:
      return "int32x4";
    case kUnboxedFloat64x2:
      return "float64x2";
    case kPairOfTagged:
      return "tagged-pair";
    case kNoRepresentation:
      return "none";
    case kNumRepresentations:
      UNREACHABLE();
  }
  return "?";
}

void PhiInstr::PrintTo(BufferFormatter* f) const {
  if (HasPairRepresentation()) {
    f->Print("(v%" Pd ", v%" Pd ") <- phi(", ssa_temp_index(),
             ssa_temp_index() + 1);
  } else {
    f->Print("v%" Pd " <- phi(", ssa_temp_index());
  }
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

  if (representation() != kNoRepresentation && representation() != kTagged) {
    f->Print(" %s", RepresentationToCString(representation()));
  }

  if (HasType()) {
    f->Print(" %s", TypeAsCString());
  }
}

void UnboxIntegerInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (is_truncating()) {
    f->Print("[tr], ");
  }
  Definition::PrintOperandsTo(f);
}

void IntConverterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s->%s%s, ", RepresentationToCString(from()),
           RepresentationToCString(to()), is_truncating() ? "[tr]" : "");
  Definition::PrintOperandsTo(f);
}

void BitCastInstr::PrintOperandsTo(BufferFormatter* f) const {
  Definition::PrintOperandsTo(f);
  f->Print(" (%s -> %s)", RepresentationToCString(from()),
           RepresentationToCString(to()));
}

void ParameterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%" Pd, index());
}

void SpecialParameterInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", KindToCString(kind()));
}

const char* SpecialParameterInstr::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void CheckStackOverflowInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("stack=%" Pd ", loop=%" Pd, stack_depth(), loop_depth());
}

void TargetEntryInstr::PrintTo(BufferFormatter* f) const {
  if (try_index() != kInvalidTryIndex) {
    f->Print("B%" Pd "[target try_idx %" Pd "]:%" Pd, block_id(), try_index(),
             GetDeoptId());
  } else {
    f->Print("B%" Pd "[target]:%" Pd, block_id(), GetDeoptId());
  }
  if (HasParallelMove()) {
    f->Print(" ");
    parallel_move()->PrintTo(f);
  }
}

void OsrEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[osr entry]:%" Pd " stack_depth=%" Pd, block_id(),
           GetDeoptId(), stack_depth());
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void FunctionEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[function entry]:%" Pd, block_id(), GetDeoptId());
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void NativeEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[native function entry]:%" Pd, block_id(), GetDeoptId());
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void ReturnInstr::PrintOperandsTo(BufferFormatter* f) const {
  Instruction::PrintOperandsTo(f);
  if (yield_index() != PcDescriptorsLayout::kInvalidYieldIndex) {
    f->Print(", yield_index = %" Pd "", yield_index());
  }
}

void FfiCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print(" pointer=");
  InputAt(TargetAddressIndex())->PrintTo(f);
  for (intptr_t i = 0, n = InputCount(); i < n - 1; ++i) {
    f->Print(", ");
    InputAt(i)->PrintTo(f);
    f->Print(" (@");
    marshaller_.Location(i).PrintTo(f);
    f->Print(")");
  }
}

void EnterHandleScopeInstr::PrintOperandsTo(BufferFormatter* f) const {
  if (kind_ == Kind::kEnterHandleScope) {
    f->Print("<enter handle scope>");
  } else {
    f->Print("<get top api scope>");
  }
}

void NativeReturnInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(" (@");
  marshaller_.Location(compiler::ffi::kResultIndex).PrintTo(f);
  f->Print(")");
}

void NativeParameterInstr::PrintOperandsTo(BufferFormatter* f) const {
  // Where the calling convention puts it.
  marshaller_.Location(index_).PrintTo(f);
  f->Print(" at ");
  // Where the arguments are when pushed on the stack.
  marshaller_.NativeLocationOfNativeParameter(index_).PrintTo(f);
}

void CatchBlockEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("B%" Pd "[target catch try_idx %" Pd " catch_try_idx %" Pd "]",
           block_id(), try_index(), catch_try_index());
  if (HasParallelMove()) {
    f->Print("\n");
    parallel_move()->PrintTo(f);
  }

  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void LoadIndexedUnsafeInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s[", RegisterNames::RegisterName(base_reg()));
  index()->PrintTo(f);
  f->Print(" + %" Pd "]", offset());
}

void StoreIndexedUnsafeInstr::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s[", RegisterNames::RegisterName(base_reg()));
  index()->PrintTo(f);
  f->Print(" + %" Pd "], ", offset());
  value()->PrintTo(f);
}

void StoreIndexedInstr::PrintOperandsTo(BufferFormatter* f) const {
  Instruction::PrintOperandsTo(f);
  if (!ShouldEmitStoreBarrier()) {
    f->Print(", NoStoreBarrier");
  }
}

void TailCallInstr::PrintOperandsTo(BufferFormatter* f) const {
  const char* name = "<unknown code>";
  if (code_.IsStubCode()) {
    name = StubCode::NameOfStub(code_.EntryPoint());
  } else {
    const Object& owner = Object::Handle(code_.owner());
    if (owner.IsFunction()) {
      name = Function::Handle(Function::RawCast(owner.raw()))
                 .ToFullyQualifiedCString();
    }
  }
  f->Print("%s(", name);
  InputAt(0)->PrintTo(f);
  f->Print(")");
}

void PushArgumentInstr::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
}

void GotoInstr::PrintTo(BufferFormatter* f) const {
  if (HasParallelMove()) {
    parallel_move()->PrintTo(f);
    f->Print(" ");
  }
  if (GetDeoptId() != DeoptId::kNone) {
    f->Print("goto:%" Pd " B%" Pd "", GetDeoptId(), successor()->block_id());
  } else {
    f->Print("goto: B%" Pd "", successor()->block_id());
  }
}

void IndirectGotoInstr::PrintTo(BufferFormatter* f) const {
  if (GetDeoptId() != DeoptId::kNone) {
    f->Print("igoto:%" Pd "(", GetDeoptId());
  } else {
    f->Print("igoto:(");
  }
  InputAt(0)->PrintTo(f);
  f->Print(")");
}

void BranchInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%s ", DebugName());
  f->Print("if ");
  comparison()->PrintTo(f);

  f->Print(" goto (%" Pd ", %" Pd ")", true_successor()->block_id(),
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

void Utf8ScanInstr::PrintTo(BufferFormatter* f) const {
  Definition::PrintTo(f);
  f->Print(" [%s]", scan_flags_field_.Name());
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
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

#else  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

const char* Instruction::ToCString() const {
  return DebugName();
}

void FlowGraphPrinter::PrintOneInstruction(Instruction* instr,
                                           bool print_locations) {
  UNREACHABLE();
}

void FlowGraphPrinter::PrintTypeCheck(const ParsedFunction& parsed_function,
                                      TokenPosition token_pos,
                                      Value* value,
                                      const AbstractType& dst_type,
                                      const String& dst_name,
                                      bool eliminated) {
  UNREACHABLE();
}

void FlowGraphPrinter::PrintBlock(BlockEntryInstr* block,
                                  bool print_locations) {
  UNREACHABLE();
}

void FlowGraphPrinter::PrintGraph(const char* phase, FlowGraph* flow_graph) {
  UNREACHABLE();
}

void FlowGraphPrinter::PrintICData(const ICData& ic_data,
                                   intptr_t num_checks_to_print) {
  UNREACHABLE();
}

bool FlowGraphPrinter::ShouldPrint(const Function& function) {
  return false;
}

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

}  // namespace dart

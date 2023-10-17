// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_printer.h"

#include <tuple>

#include "vm/class_id.h"
#include "vm/compiler/api/print_filter.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

#if defined(INCLUDE_IL_PRINTER)
DEFINE_FLAG(bool,
            display_sorted_ic_data,
            false,
            "Calls display a unary, sorted-by count form of ICData");
DEFINE_FLAG(bool, print_environments, false, "Print SSA environments.");
DEFINE_FLAG(bool,
            print_flow_graph_as_json,
            false,
            "Use machine readable output when printing IL graphs.");
DEFINE_FLAG(bool, print_redundant_il, false, "Print redundant IL instructions");

DECLARE_FLAG(bool, trace_inlining_intervals);

static bool IsRedundant(Instruction* instr) {
  if (auto constant = instr->AsConstant()) {
    return !constant->HasUses();
  } else if (auto move = instr->AsParallelMove()) {
    return move->IsRedundant();
  } else {
    return false;
  }
}

static bool ShouldPrintInstruction(Instruction* instr) {
  return FLAG_print_redundant_il || !IsRedundant(instr);
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
    case kUnboxedUint8:
      return "uint8";
    case kUnboxedUint16:
      return "uint16";
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

class IlTestPrinter : public AllStatic {
 public:
  static void PrintGraph(const char* phase, FlowGraph* flow_graph) {
    JSONWriter writer;
    writer.OpenObject();
    writer.PrintProperty("p", phase);
    writer.PrintProperty("f", flow_graph->function().ToFullyQualifiedCString());
    writer.OpenArray("b");
    for (auto block : flow_graph->reverse_postorder()) {
      PrintBlock(&writer, block);
    }
    writer.CloseArray();
    writer.OpenObject("desc");
    AttributesSerializer(&writer).WriteDescriptors();
    writer.CloseObject();
    writer.OpenObject("flags");
    writer.PrintPropertyBool("nnbd", IsolateGroup::Current()->null_safety());
    writer.CloseObject();
    writer.CloseObject();
    THR_Print("%s\n", writer.ToCString());
  }

  static void PrintBlock(JSONWriter* writer, BlockEntryInstr* block) {
    writer->OpenObject();
    writer->PrintProperty64("b", block->block_id());
    writer->PrintProperty("o", block->DebugName());
    if (auto block_with_defs = block->AsBlockEntryWithInitialDefs()) {
      if (block_with_defs->initial_definitions() != nullptr &&
          block_with_defs->initial_definitions()->length() > 0) {
        writer->OpenArray("d");
        for (auto defn : *block_with_defs->initial_definitions()) {
          if (ShouldPrintInstruction(defn)) {
            PrintInstruction(writer, defn);
          }
        }
        writer->CloseArray();
      }
    }
    writer->OpenArray("is");
    if (auto join = block->AsJoinEntry()) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        if (ShouldPrintInstruction(it.Current())) {
          PrintInstruction(writer, it.Current());
        }
      }
    }
    for (auto instr : block->instructions()) {
      if (ShouldPrintInstruction(instr)) {
        PrintInstruction(writer, instr);
      }
    }
    writer->CloseArray();
    writer->CloseObject();
  }

  static void PrintInstruction(JSONWriter* writer,
                               Instruction* instr,
                               const char* name = nullptr) {
    writer->OpenObject(name);
    if (auto defn = instr->AsDefinition()) {
      if (defn->ssa_temp_index() != -1) {
        writer->PrintProperty("v", defn->ssa_temp_index());
      }
    }
    writer->PrintProperty("o", instr->DebugName());
    if (auto branch = instr->AsBranch()) {
      PrintInstruction(writer, branch->comparison(), "cc");
    } else {
      if (instr->InputCount() != 0) {
        writer->OpenArray("i");
        for (intptr_t i = 0; i < instr->InputCount(); i++) {
          writer->PrintValue(instr->InputAt(i)->definition()->ssa_temp_index());
        }
        writer->CloseArray();
      } else if (instr->ArgumentCount() != 0 &&
                 instr->GetMoveArguments() != nullptr) {
        writer->OpenArray("i");
        for (intptr_t i = 0; i < instr->ArgumentCount(); i++) {
          writer->PrintValue(
              instr->ArgumentValueAt(i)->definition()->ssa_temp_index());
        }
        writer->CloseArray();
      }
      AttributesSerializer serializer(writer);
      instr->Accept(&serializer);
    }
    if (instr->SuccessorCount() > 0) {
      writer->OpenArray("s");
      for (auto succ : instr->successors()) {
        writer->PrintValue(succ->block_id());
      }
      writer->CloseArray();
    }
    writer->CloseObject();
  }

  template <typename T>
  class HasGetAttributes {
    template <typename U>
    static std::true_type test(decltype(&U::GetAttributes));
    template <typename U>
    static std::false_type test(...);

   public:
    static constexpr bool value = decltype(test<T>(nullptr))::value;
  };

  class AttributesSerializer : public InstructionVisitor {
   public:
    explicit AttributesSerializer(JSONWriter* writer) : writer_(writer) {}

    void WriteDescriptors() {
#define DECLARE_VISIT_INSTRUCTION(ShortName, Attrs)                            \
  WriteDescriptor<ShortName##Instr>(#ShortName);

      FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_INSTRUCTION
    }

#define DECLARE_VISIT_INSTRUCTION(ShortName, Attrs)                            \
  virtual void Visit##ShortName(ShortName##Instr* instr) { Write(instr); }

    FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_INSTRUCTION

   private:
    void WriteAttribute(const char* value) { writer_->PrintValue(value); }

    void WriteAttribute(intptr_t value) { writer_->PrintValue(value); }

    void WriteAttribute(bool value) { writer_->PrintValueBool(value); }

    void WriteAttribute(Token::Kind kind) {
      writer_->PrintValue(Token::Str(kind));
    }

    void WriteAttribute(Representation rep) {
      writer_->PrintValue(RepresentationToCString(rep));
    }

    void WriteAttribute(const Slot* slot) { writer_->PrintValue(slot->Name()); }

    void WriteAttribute(const Function* function) {
      writer_->PrintValue(function->QualifiedUserVisibleNameCString());
    }

    void WriteAttribute(const Object* obj) {
      if (obj->IsNull()) {
        writer_->PrintValueNull();
      } else if (obj->IsBool()) {
        writer_->PrintValueBool(Bool::Cast(*obj).value());
      } else if (obj->IsInteger()) {
        auto value = Integer::Cast(*obj).AsInt64Value();
        // PrintValue64 and PrintValue will check if integer is representable
        // as a JS number, which is too strict. We don't actually need
        // such checks because we only load resulting JSON in Dart.
        writer_->buffer()->Printf("%" Pd64 "", value);
      } else if (obj->IsString()) {
        const auto& str = String::Cast(*obj);
        writer_->PrintValueStr(str, 0, str.Length());
      } else {
        const auto& cls = Class::Handle(obj->clazz());
        writer_->PrintfValue("Instance of %s", cls.UserVisibleNameCString());
      }
    }

    template <typename... Ts>
    void WriteTuple(const std::tuple<Ts...>& tuple) {
      std::apply(
          [&](Ts const&... elements) { (WriteAttribute(elements), ...); },
          tuple);
    }

    template <typename T,
              typename = typename std::enable_if_t<HasGetAttributes<T>::value>>
    void Write(T* instr) {
      writer_->OpenArray("d");
      WriteTuple(instr->GetAttributes());
      writer_->CloseArray();
    }

    void Write(Instruction* instr) {
      // Default, do nothing.
    }

    void WriteAttributeName(const char* str) {
      ASSERT(str != nullptr);
      // To simplify the declaring side, we assume the string might be directly
      // stringized from one of the following expression forms:
      //
      // * &name()
      // * name()
      // * name_
      //
      // Remove the non-name parts of the above before printing.
      const intptr_t start = str[0] == '&' ? 1 : 0;
      intptr_t end = strlen(str);
      switch (str[end - 1]) {
        case ')':
          ASSERT(end >= 2);
          ASSERT_EQUAL(str[end - 2], '(');
          end -= 2;
          break;
        case '_':
          // Strip off the final _ from a direct private field access.
          end -= 1;
          break;
        default:
          break;
      }
      writer_->PrintValue(str + start, end - start);
    }

    template <typename... Ts>
    void WriteAttributeNames(const std::tuple<Ts...>& tuple) {
      std::apply(
          [&](Ts const&... elements) { (WriteAttributeName(elements), ...); },
          tuple);
    }

    template <typename T>
    void WriteDescriptor(
        const char* name,
        typename std::enable_if_t<HasGetAttributes<T>::value>* = nullptr) {
      writer_->OpenArray(name);
      WriteAttributeNames(T::GetAttributeNames());
      writer_->CloseArray();
    }

    template <typename T>
    void WriteDescriptor(
        const char* name,
        typename std::enable_if_t<!HasGetAttributes<T>::value>* = nullptr) {}

    JSONWriter* writer_;
  };
};

bool FlowGraphPrinter::ShouldPrint(
    const Function& function,
    uint8_t** compiler_pass_filter /* = nullptr */) {
  return compiler::PrintFilter::ShouldPrint(function, compiler_pass_filter);
}

void FlowGraphPrinter::PrintGraph(const char* phase, FlowGraph* flow_graph) {
  LogBlock lb;
  if (FLAG_print_flow_graph_as_json) {
    IlTestPrinter::PrintGraph(phase, flow_graph);
  } else {
    THR_Print("*** BEGIN CFG\n%s\n", phase);
    FlowGraphPrinter printer(*flow_graph);
    printer.PrintBlocks();
    THR_Print("*** END CFG\n");
  }
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

    // Skip redundant parallel moves.
    if (!ShouldPrintInstruction(current)) {
      continue;
    }

    PrintOneInstruction(current, print_locations);
    THR_Print("\n");
  }
}

void FlowGraphPrinter::PrintBlocks() {
  if (!function_.IsNull()) {
    THR_Print("==== %s (%s", function_.ToFullyQualifiedCString(),
              Function::KindToCString(function_.kind()));
    // Output saved arguments descriptor information for dispatchers that
    // have it, so it's easy to see which dispatcher this graph represents.
    if (function_.HasSavedArgumentsDescriptor()) {
      const auto& args_desc_array = Array::Handle(function_.saved_args_desc());
      const ArgumentsDescriptor args_desc(args_desc_array);
      THR_Print(", %s", args_desc.ToCString());
    }
    THR_Print(")\n");
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
  if (FLAG_print_environments && (instr->env() != nullptr)) {
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
  if (value != nullptr && value->reaching_type_ != nullptr) {
    compile_type_name = value->reaching_type_->ToCString();
  }
  THR_Print(
      "%s type check: compile type %s is %s specific than "
      "type '%s' of '%s'.\n",
      eliminated ? "Eliminated" : "Generated", compile_type_name,
      eliminated ? "more" : "not more",
      String::Handle(dst_type.Name()).ToCString(), dst_name.ToCString());
}

static void PrintTargetsHelper(BaseTextBuffer* f,
                               const CallTargets& targets,
                               intptr_t num_checks_to_print) {
  f->AddString(" Targets[");
  f->Printf("%" Pd ": ", targets.length());
  Function& target = Function::Handle();
  if ((num_checks_to_print == FlowGraphPrinter::kPrintAll) ||
      (num_checks_to_print > targets.length())) {
    num_checks_to_print = targets.length();
  }
  for (intptr_t i = 0; i < num_checks_to_print; i++) {
    const CidRange& range = targets[i];
    const auto target_info = targets.TargetAt(i);
    const intptr_t count = target_info->count;
    target = target_info->target->ptr();
    if (i > 0) {
      f->AddString(" | ");
    }
    if (range.IsSingleCid()) {
      const Class& cls = Class::Handle(
          IsolateGroup::Current()->class_table()->At(range.cid_start));
      f->Printf("%s", String::Handle(cls.Name()).ToCString());
      f->Printf(" cid %" Pd " cnt:%" Pd " trgt:'%s'", range.cid_start, count,
                target.ToQualifiedCString());
    } else {
      const Class& cls = Class::Handle(target.Owner());
      f->Printf("cid %" Pd "-%" Pd " %s", range.cid_start, range.cid_end,
                String::Handle(cls.Name()).ToCString());
      f->Printf(" cnt:%" Pd " trgt:'%s'", count, target.ToQualifiedCString());
    }

    if (target_info->exactness.IsTracking()) {
      f->Printf(" %s", target_info->exactness.ToCString());
    }
  }
  if (num_checks_to_print < targets.length()) {
    f->AddString("...");
  }
  f->AddString("]");
}

static void PrintCidsHelper(BaseTextBuffer* f,
                            const Cids& targets,
                            intptr_t num_checks_to_print) {
  f->AddString(" Cids[");
  f->Printf("%" Pd ": ", targets.length());
  if ((num_checks_to_print == FlowGraphPrinter::kPrintAll) ||
      (num_checks_to_print > targets.length())) {
    num_checks_to_print = targets.length();
  }
  for (intptr_t i = 0; i < num_checks_to_print; i++) {
    const CidRange& range = targets[i];
    if (i > 0) {
      f->AddString(" | ");
    }
    const Class& cls = Class::Handle(
        IsolateGroup::Current()->class_table()->At(range.cid_start));
    f->Printf("%s etc. ", String::Handle(cls.Name()).ToCString());
    if (range.IsSingleCid()) {
      f->Printf(" cid %" Pd, range.cid_start);
    } else {
      f->Printf(" cid %" Pd "-%" Pd, range.cid_start, range.cid_end);
    }
  }
  if (num_checks_to_print < targets.length()) {
    f->AddString("...");
  }
  f->AddString("]");
}

static void PrintICDataHelper(BaseTextBuffer* f,
                              const ICData& ic_data,
                              intptr_t num_checks_to_print) {
  f->AddString(" IC[");
  if (ic_data.is_tracking_exactness()) {
    f->Printf(
        "(%s) ",
        AbstractType::Handle(ic_data.receivers_static_type()).ToCString());
  }
  f->Printf("%" Pd ": ", ic_data.NumberOfChecks());
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
      f->AddString(" | ");
    }
    for (intptr_t k = 0; k < class_ids.length(); k++) {
      if (k > 0) {
        f->AddString(", ");
      }
      const Class& cls = Class::Handle(
          IsolateGroup::Current()->class_table()->At(class_ids[k]));
      f->Printf("%s", String::Handle(cls.Name()).ToCString());
    }
    f->Printf(" cnt:%" Pd " trgt:'%s'", count, target.ToQualifiedCString());
    if (ic_data.is_tracking_exactness()) {
      f->Printf(" %s", ic_data.GetExactnessAt(i).ToCString());
    }
  }
  if (num_checks_to_print < ic_data.NumberOfChecks()) {
    f->AddString("...");
  }
  f->AddString("]");
}

static void PrintICDataSortedHelper(BaseTextBuffer* f,
                                    const ICData& ic_data_orig) {
  const ICData& ic_data =
      ICData::Handle(ic_data_orig.AsUnaryClassChecksSortedByCount());
  f->Printf(" IC[n:%" Pd "; ", ic_data.NumberOfChecks());
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    const intptr_t count = ic_data.GetCountAt(i);
    const intptr_t cid = ic_data.GetReceiverClassIdAt(i);
    const Class& cls =
        Class::Handle(IsolateGroup::Current()->class_table()->At(cid));
    f->Printf("%s : %" Pd ", ", String::Handle(cls.Name()).ToCString(), count);
  }
  f->AddString("]");
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

static void PrintUse(BaseTextBuffer* f, const Definition& definition) {
  if (definition.HasSSATemp()) {
    f->Printf("v%" Pd "", definition.ssa_temp_index());
  } else if (definition.HasTemp()) {
    f->Printf("t%" Pd "", definition.temp_index());
  }
}

const char* Instruction::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void Instruction::PrintTo(BaseTextBuffer* f) const {
  if (GetDeoptId() != DeoptId::kNone) {
    f->Printf("%s:%" Pd "(", DebugName(), GetDeoptId());
  } else {
    f->Printf("%s(", DebugName());
  }
  PrintOperandsTo(f);
  f->AddString(")");
}

void Instruction::PrintOperandsTo(BaseTextBuffer* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->AddString(", ");
    if (InputAt(i) != nullptr) InputAt(i)->PrintTo(f);
  }
}

void Definition::PrintTo(BaseTextBuffer* f) const {
  PrintUse(f, *this);
  if (HasSSATemp() || HasTemp()) f->AddString(" <- ");
  if (GetDeoptId() != DeoptId::kNone) {
    f->Printf("%s:%" Pd "(", DebugName(), GetDeoptId());
  } else {
    f->Printf("%s(", DebugName());
  }
  PrintOperandsTo(f);
  f->AddString(")");
  if (range_ != nullptr) {
    f->AddString(" ");
    range_->PrintTo(f);
  }

  if (representation() != kNoRepresentation && representation() != kTagged) {
    f->Printf(" %s", RepresentationToCString(representation()));
  } else if (type_ != nullptr) {
    f->AddString(" ");
    type_->PrintTo(f);
  }
}

void CheckNullInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
  switch (exception_type()) {
    case kNoSuchMethod:
      f->AddString(", NoSuchMethodError");
      break;
    case kArgumentError:
      f->AddString(", ArgumentError");
      break;
    case kCastError:
      f->AddString(", CastError");
      break;
  }
}

void Definition::PrintOperandsTo(BaseTextBuffer* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->AddString(", ");
    if (InputAt(i) != nullptr) {
      InputAt(i)->PrintTo(f);
    }
  }
}

void RedefinitionInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
  if (constrained_type_ != nullptr) {
    f->Printf(" ^ %s", constrained_type_->ToCString());
  }
}

void ReachabilityFenceInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
}

const char* Value::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void Value::PrintTo(BaseTextBuffer* f) const {
  PrintUse(f, *definition());

  if ((reaching_type_ != nullptr) && (reaching_type_ != definition()->type_)) {
    f->AddString(" ");
    reaching_type_->PrintTo(f);
  }
}

void ConstantInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const char* cstr = value().ToCString();
  const char* new_line = strchr(cstr, '\n');
  if (new_line == nullptr) {
    f->Printf("#%s", cstr);
  } else {
    const intptr_t pos = new_line - cstr;
    char* buffer = Thread::Current()->zone()->Alloc<char>(pos + 1);
    strncpy(buffer, cstr, pos);
    buffer[pos] = '\0';
    f->Printf("#%s\\n...", buffer);
  }
}

void ConstraintInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  f->AddString(" ^ ");
  constraint()->PrintTo(f);
}

void Range::PrintTo(BaseTextBuffer* f) const {
  f->AddString("[");
  min_.PrintTo(f);
  f->AddString(", ");
  max_.PrintTo(f);
  f->AddString("]");
}

const char* Range::ToCString(const Range* range) {
  if (range == nullptr) return "[_|_, _|_]";

  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  range->PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void RangeBoundary::PrintTo(BaseTextBuffer* f) const {
  switch (kind_) {
    case kSymbol:
      f->Printf("v%" Pd "",
                reinterpret_cast<Definition*>(value_)->ssa_temp_index());
      if (offset_ != 0) f->Printf("%+" Pd64 "", offset_);
      break;
    case kNegativeInfinity:
      f->AddString("-inf");
      break;
    case kPositiveInfinity:
      f->AddString("+inf");
      break;
    case kConstant:
      f->Printf("%" Pd64 "", value_);
      break;
    case kUnknown:
      f->AddString("_|_");
      break;
  }
}

const char* RangeBoundary::ToCString() const {
  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void MakeTempInstr::PrintOperandsTo(BaseTextBuffer* f) const {}

void DropTempsInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%" Pd "", num_temps());
  if (value() != nullptr) {
    f->AddString(", ");
    value()->PrintTo(f);
  }
}

void AssertAssignableInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  f->AddString(", ");
  dst_type()->PrintTo(f);
  f->Printf(", '%s',", dst_name().ToCString());
  f->AddString(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->AddString("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->AddString(")");
}

void AssertSubtypeInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  sub_type()->PrintTo(f);
  f->AddString(", ");
  super_type()->PrintTo(f);
  f->AddString(", ");
  dst_name()->PrintTo(f);
  f->AddString(", instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->AddString("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->AddString(")");
}

void AssertBooleanInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
}

void ClosureCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  if (FLAG_precompiled_mode) {
    f->AddString(" closure=");
  } else {
    f->AddString(" function=");
  }
  InputAt(InputCount() - 1)->PrintTo(f);
  f->Printf("<%" Pd ">", type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->AddString(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
}

void InstanceCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf(" %s<%" Pd ">", function_name().ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->AddString(", ");
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
    f->Printf(", result_type = %s", result_type()->ToCString());
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->AddString(" using unchecked entrypoint");
  }
}

void PolymorphicInstanceCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf(" %s<%" Pd ">", function_name().ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->AddString(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  PrintTargetsHelper(f, targets_, FlowGraphPrinter::kPrintAll);
  if (complete()) {
    f->AddString(" COMPLETE");
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->AddString(" using unchecked entrypoint");
  }
}

void DispatchTableCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const String& name =
      String::Handle(interface_target().QualifiedUserVisibleName());
  f->AddString(" cid=");
  class_id()->PrintTo(f);
  f->Printf(" %s<%" Pd ">", name.ToCString(), type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->AddString(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
}

void StrictCompareInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->AddString(", ");
  right()->PrintTo(f);
  if (needs_number_check()) {
    f->Printf(", with number check");
  }
}

void TestCidsInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  left()->PrintTo(f);
  f->Printf(" %s [", Token::Str(kind()));
  intptr_t length = cid_results().length();
  for (intptr_t i = 0; i < length; i += 2) {
    f->Printf("0x%" Px ":%s ", cid_results()[i],
              cid_results()[i + 1] == 0 ? "false" : "true");
  }
  f->AddString("] ");
  if (CanDeoptimize()) {
    ASSERT(deopt_id() != DeoptId::kNone);
    f->AddString("else deoptimize ");
  } else {
    ASSERT(deopt_id() == DeoptId::kNone);
    f->Printf("else %s ", cid_results()[length - 1] != 0 ? "false" : "true");
  }
}

void TestRangeInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  left()->PrintTo(f);
  f->Printf(" %s [%" Pd "-%" Pd "]", kind() == Token::kIS ? "in" : "not in",
            lower_, upper_);
}

void EqualityCompareInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  left()->PrintTo(f);
  f->Printf(" %s ", Token::Str(kind()));
  right()->PrintTo(f);
}

void StaticCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf(" %s<%" Pd "> ", String::Handle(function().name()).ToCString(),
            type_args_len());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i > 0) f->AddString(", ");
    ArgumentValueAt(i)->PrintTo(f);
  }
  if (entry_kind() == Code::EntryKind::kUnchecked) {
    f->AddString(", using unchecked entrypoint");
  }
  if (function().recognized_kind() != MethodRecognizer::kUnknown) {
    f->Printf(", recognized_kind = %s",
              MethodRecognizer::KindToCString(function().recognized_kind()));
  }
  if (result_type() != nullptr) {
    f->Printf(", result_type = %s", result_type()->ToCString());
  }
}

void LoadLocalInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s @%d", local().name().ToCString(), local().index().value());
}

void StoreLocalInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s @%d, ", local().name().ToCString(), local().index().value());
  value()->PrintTo(f);
}

void NativeCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", native_name().ToCString());
}

void GuardFieldInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s %s, ", String::Handle(field().name()).ToCString(),
            field().GuardedPropertiesAsCString());
  value()->PrintTo(f);
}

void StoreFieldInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  instance()->PrintTo(f);
  f->Printf(" . %s = ", slot().Name());
  value()->PrintTo(f);
  if (slot().representation() != kTagged) {
    f->Printf(" <%s>", RepresentationToCString(slot().representation()));
  }

  // Here, we just print the value of the enum field. We would prefer to get
  // the final decision on whether a store barrier will be emitted by calling
  // ShouldEmitStoreBarrier(), but that can change parts of the flow graph.
  if (emit_store_barrier_ == kNoStoreBarrier) {
    f->AddString(", NoStoreBarrier");
  }
  if (stores_inner_pointer() == InnerPointerAccess::kMayBeInnerPointer) {
    f->AddString(", MayStoreInnerPointer");
  }
}

void IfThenElseInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  comparison()->PrintOperandsTo(f);
  f->Printf(" ? %" Pd " : %" Pd, if_true_, if_false_);
}

void LoadStaticFieldInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", String::Handle(field().name()).ToCString());
  if (calls_initializer()) {
    f->AddString(", CallsInitializer");
  }
}

void StoreStaticFieldInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", String::Handle(field().name()).ToCString());
  value()->PrintTo(f);
}

void InstanceOfInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  f->Printf(" IS %s,", String::Handle(type().Name()).ToCString());
  f->AddString(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->AddString("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->AddString(")");
}

void RelationalOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->AddString(", ");
  right()->PrintTo(f);
}

void AllocationInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
  if (Identity().IsNotAliased()) {
    if (InputCount() > 0) {
      f->AddString(", ");
    }
    f->AddString("<not-aliased>");
  }
}

void AllocateObjectInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("cls=%s", String::Handle(cls().ScrubbedName()).ToCString());
  if (InputCount() > 0 || Identity().IsNotAliased()) {
    f->AddString(", ");
  }
  AllocationInstr::PrintOperandsTo(f);
}

void MaterializeObjectInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", String::Handle(cls_.ScrubbedName()).ToCString());
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->AddString(", ");
    f->Printf("%s: ", slots_[i]->Name());
    InputAt(i)->PrintTo(f);
  }
}

void LoadFieldInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  instance()->PrintTo(f);
  f->Printf(" . %s%s", slot().Name(), IsImmutableLoad() ? " {final}" : "");
  if (calls_initializer()) {
    f->AddString(", CallsInitializer");
  }
  if (loads_inner_pointer() == InnerPointerAccess::kMayBeInnerPointer) {
    f->AddString(", MayLoadInnerPointer");
  }
}

void LoadUntaggedInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  object()->PrintTo(f);
  f->Printf(", %" Pd, offset());
}

void InstantiateTypeInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const String& type_name = String::Handle(type().Name());
  f->Printf("%s,", type_name.ToCString());
  f->AddString(" instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->AddString("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->AddString(")");
}

void InstantiateTypeArgumentsInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  type_arguments()->PrintTo(f);
  f->AddString(", instantiator_type_args(");
  instantiator_type_arguments()->PrintTo(f);
  f->AddString("), function_type_args(");
  function_type_arguments()->PrintTo(f);
  f->Printf(")");
  if (!instantiator_class().IsNull()) {
    f->Printf(", instantiator_class(%s)", instantiator_class().ToCString());
  }
}

void AllocateContextInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("num_variables=%" Pd "", num_context_variables());
  if (InputCount() > 0 || Identity().IsNotAliased()) {
    f->AddString(", ");
  }
  TemplateAllocation::PrintOperandsTo(f);
}

void AllocateUninitializedContextInstr::PrintOperandsTo(
    BaseTextBuffer* f) const {
  f->Printf("num_variables=%" Pd "", num_context_variables());
  if (InputCount() > 0 || Identity().IsNotAliased()) {
    f->AddString(", ");
  }
  TemplateAllocation::PrintOperandsTo(f);
}

void TruncDivModInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
}

void ExtractNthOutputInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("Extract %" Pd " from ", index());
  Definition::PrintOperandsTo(f);
}

void UnboxLaneInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
  f->Printf(", lane %" Pd, lane());
}

void BoxLanesInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
}

void UnaryIntegerOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}

void BinaryIntegerOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", Token::Str(op_kind()));
  if (is_truncating()) {
    f->AddString(" [tr]");
  } else if (!can_overflow()) {
    f->AddString(" [-o]");
  }
  f->AddString(", ");
  left()->PrintTo(f);
  f->AddString(", ");
  right()->PrintTo(f);
}

void BinaryDoubleOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", Token::Str(op_kind()));
  left()->PrintTo(f);
  f->AddString(", ");
  right()->PrintTo(f);
}

void DoubleTestOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      f->AddString("IsNaN ");
      break;
    case MethodRecognizer::kDouble_getIsInfinite:
      f->AddString("IsInfinite ");
      break;
    default:
      UNREACHABLE();
  }
  value()->PrintTo(f);
}

static const char* const simd_op_kind_string[] = {
#define CASE(Arity, Mask, Name, ...) #Name,
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
};

void SimdOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", simd_op_kind_string[kind()]);
  if (HasMask()) {
    f->Printf(", mask = %" Pd "", mask());
  }
  for (intptr_t i = 0; i < InputCount(); i++) {
    f->AddString(", ");
    InputAt(i)->PrintTo(f);
  }
}

void UnaryDoubleOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", Token::Str(op_kind()));
  value()->PrintTo(f);
}

void LoadClassIdInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  if (!input_can_be_smi_) {
    f->AddString("<non-smi> ");
  }
  object()->PrintTo(f);
}

void CheckClassIdInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);

  const Class& cls = Class::Handle(
      IsolateGroup::Current()->class_table()->At(cids().cid_start));
  const String& name = String::Handle(cls.ScrubbedName());
  if (cids().IsSingleCid()) {
    f->Printf(", %s", name.ToCString());
  } else {
    const Class& cls2 = Class::Handle(
        IsolateGroup::Current()->class_table()->At(cids().cid_end));
    const String& name2 = String::Handle(cls2.ScrubbedName());
    f->Printf(", cid %" Pd "-%" Pd " %s-%s", cids().cid_start, cids().cid_end,
              name.ToCString(), name2.ToCString());
  }
}

void HashIntegerOpInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  if (smi_) {
    f->AddString("smi ");
  }

  value()->PrintTo(f);
}

void CheckClassInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  PrintCidsHelper(f, cids_, FlowGraphPrinter::kPrintAll);
  if (IsNullCheck()) {
    f->AddString(" nullcheck");
  }
}

void CheckConditionInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  comparison()->PrintOperandsTo(f);
}

void InvokeMathCFunctionInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s, ", MethodRecognizer::KindToCString(recognized_kind_));
  Definition::PrintOperandsTo(f);
}

void BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(
    BaseTextBuffer* f) const {
  const GrowableArray<Definition*>& defns = initial_definitions_;
  if (defns.length() > 0) {
    f->AddString(" {");
    for (intptr_t i = 0; i < defns.length(); ++i) {
      Definition* def = defns[i];
      // Skip constants which are not used in the graph.
      if (!ShouldPrintInstruction(def)) {
        continue;
      }
      f->AddString("\n      ");
      def->PrintTo(f);
    }
    f->AddString("\n}");
  }
}

void GraphEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[graph]:%" Pd, block_id(), GetDeoptId());
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void JoinEntryInstr::PrintTo(BaseTextBuffer* f) const {
  if (try_index() != kInvalidTryIndex) {
    f->Printf("B%" Pd "[join try_idx %" Pd "]:%" Pd " pred(", block_id(),
              try_index(), GetDeoptId());
  } else {
    f->Printf("B%" Pd "[join]:%" Pd " pred(", block_id(), GetDeoptId());
  }
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (i > 0) f->AddString(", ");
    f->Printf("B%" Pd, predecessors_[i]->block_id());
  }
  f->AddString(")");
  if (phis_ != nullptr) {
    f->AddString(" {");
    for (intptr_t i = 0; i < phis_->length(); ++i) {
      if ((*phis_)[i] == nullptr) continue;
      f->AddString("\n      ");
      (*phis_)[i]->PrintTo(f);
    }
    f->AddString("\n}");
  }
  if (HasParallelMove()) {
    f->AddString(" ");
    parallel_move()->PrintTo(f);
  }
}

void IndirectEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[join indirect", block_id());
  if (try_index() != kInvalidTryIndex) {
    f->Printf(" try_idx %" Pd, try_index());
  }
  f->Printf("]:%" Pd " pred(", GetDeoptId());
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (i > 0) f->AddString(", ");
    f->Printf("B%" Pd, predecessors_[i]->block_id());
  }
  f->AddString(")");
  if (phis_ != nullptr) {
    f->AddString(" {");
    for (intptr_t i = 0; i < phis_->length(); ++i) {
      if ((*phis_)[i] == nullptr) continue;
      f->AddString("\n      ");
      (*phis_)[i]->PrintTo(f);
    }
    f->AddString("\n}");
  }
  if (HasParallelMove()) {
    f->AddString(" ");
    parallel_move()->PrintTo(f);
  }
}

void PhiInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("v%" Pd " <- phi(", ssa_temp_index());
  for (intptr_t i = 0; i < inputs_.length(); ++i) {
    if (inputs_[i] != nullptr) inputs_[i]->PrintTo(f);
    if (i < inputs_.length() - 1) f->AddString(", ");
  }
  f->AddString(")");
  f->AddString(is_alive() ? " alive" : " dead");
  if (range_ != nullptr) {
    f->AddString(" ");
    range_->PrintTo(f);
  }

  if (representation() != kNoRepresentation && representation() != kTagged) {
    f->Printf(" %s", RepresentationToCString(representation()));
  }

  if (HasType()) {
    f->Printf(" %s", TypeAsCString());
  }
}

void UnboxIntegerInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  if (is_truncating()) {
    f->AddString("[tr], ");
  }
  if (SpeculativeModeOfInputs() == kGuardInputs) {
    f->AddString("[guard-inputs], ");
  } else {
    f->AddString("[non-speculative], ");
  }
  Definition::PrintOperandsTo(f);
}

void IntConverterInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s->%s%s, ", RepresentationToCString(from()),
            RepresentationToCString(to()), is_truncating() ? "[tr]" : "");
  Definition::PrintOperandsTo(f);
}

void BitCastInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Definition::PrintOperandsTo(f);
  f->Printf(" (%s -> %s)", RepresentationToCString(from()),
            RepresentationToCString(to()));
}

void ParameterInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%" Pd, env_index());
}

void SpecialParameterInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s", KindToCString(kind()));
}

const char* SpecialParameterInstr::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void CheckStackOverflowInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("stack=%" Pd ", loop=%" Pd, stack_depth(), loop_depth());
}

void TargetEntryInstr::PrintTo(BaseTextBuffer* f) const {
  if (try_index() != kInvalidTryIndex) {
    f->Printf("B%" Pd "[target try_idx %" Pd "]:%" Pd, block_id(), try_index(),
              GetDeoptId());
  } else {
    f->Printf("B%" Pd "[target]:%" Pd, block_id(), GetDeoptId());
  }
  if (HasParallelMove()) {
    f->AddString(" ");
    parallel_move()->PrintTo(f);
  }
}

void OsrEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[osr entry]:%" Pd " stack_depth=%" Pd, block_id(),
            GetDeoptId(), stack_depth());
  if (HasParallelMove()) {
    f->AddString("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void FunctionEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[function entry]:%" Pd, block_id(), GetDeoptId());
  if (HasParallelMove()) {
    f->AddString("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void NativeEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[native function entry]:%" Pd, block_id(), GetDeoptId());
  if (HasParallelMove()) {
    f->AddString("\n");
    parallel_move()->PrintTo(f);
  }
  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void FfiCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->AddString(" pointer=");
  InputAt(TargetAddressIndex())->PrintTo(f);
  if (marshaller_.PassTypedData()) {
    f->AddString(", typed_data=");
    InputAt(TypedDataIndex())->PrintTo(f);
  }
  intptr_t def_index = 0;
  for (intptr_t arg_index = 0; arg_index < marshaller_.num_args();
       arg_index++) {
    const auto& arg_location = marshaller_.Location(arg_index);
    const bool is_compound = arg_location.container_type().IsCompound();
    const intptr_t num_defs = marshaller_.NumDefinitions(arg_index);
    f->AddString(", ");
    if (is_compound) f->AddString("(");
    for (intptr_t i = 0; i < num_defs; i++) {
      InputAt(def_index)->PrintTo(f);
      if ((i + 1) < num_defs) f->AddString(", ");
      def_index++;
    }
    if (is_compound) f->AddString(")");
    f->AddString(" (@");
    arg_location.PrintTo(f);
    f->AddString(")");
  }
}

void CCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->AddString(" target_address=");
  InputAt(TargetAddressIndex())->PrintTo(f);

  const auto& argument_locations =
      native_calling_convention_.argument_locations();
  for (intptr_t i = 0; i < argument_locations.length(); i++) {
    const auto& arg_location = *argument_locations.At(i);
    f->AddString(", ");
    InputAt(i)->PrintTo(f);
    f->AddString(" (@");
    arg_location.PrintTo(f);
    f->AddString(")");
  }
}

void NativeReturnInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  f->AddString(" (@");
  marshaller_.Location(compiler::ffi::kResultIndex).PrintTo(f);
  f->AddString(")");
}

void NativeParameterInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  // Where the calling convention puts it.
  marshaller_.Location(marshaller_.ArgumentIndex(def_index_)).PrintTo(f);
  f->AddString(" at ");
  // Where the arguments are when pushed on the stack.
  marshaller_.NativeLocationOfNativeParameter(def_index_).PrintTo(f);
}

void CatchBlockEntryInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("B%" Pd "[target catch try_idx %" Pd " catch_try_idx %" Pd "]",
            block_id(), try_index(), catch_try_index());
  if (HasParallelMove()) {
    f->AddString("\n");
    parallel_move()->PrintTo(f);
  }

  BlockEntryWithInitialDefs::PrintInitialDefinitionsTo(f);
}

void LoadIndexedUnsafeInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s[", RegisterNames::RegisterName(base_reg()));
  index()->PrintTo(f);
  f->Printf(" + %" Pd "]", offset());
}

void StoreIndexedUnsafeInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  f->Printf("%s[", RegisterNames::RegisterName(base_reg()));
  index()->PrintTo(f);
  f->Printf(" + %" Pd "], ", offset());
  value()->PrintTo(f);
}

void StoreIndexedInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Instruction::PrintOperandsTo(f);
  if (!ShouldEmitStoreBarrier()) {
    f->AddString(", NoStoreBarrier");
  }
}

void MemoryCopyInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  Instruction::PrintOperandsTo(f);
  // kTypedDataUint8ArrayCid is used as the default cid for cases where
  // the destination object is a subclass of PointerBase and the arguments
  // are given in terms of bytes, so only print if the cid differs.
  switch (dest_representation_) {
    case kUntagged:
      f->Printf(", dest untagged");
      break;
    case kTagged:
      if (dest_cid_ != kTypedDataUint8ArrayCid) {
        const Class& cls = Class::Handle(
            IsolateGroup::Current()->class_table()->At(dest_cid_));
        if (!cls.IsNull()) {
          f->Printf(", dest_cid=%s (%d)", cls.ScrubbedNameCString(), dest_cid_);
        } else {
          f->Printf(", dest_cid=%d", dest_cid_);
        }
      }
      break;
    default:
      UNREACHABLE();
  }
  switch (src_representation_) {
    case kUntagged:
      f->Printf(", src untagged");
      break;
    case kTagged:
      if ((dest_representation_ == kTagged && dest_cid_ != src_cid_) ||
          (dest_representation_ != kTagged &&
           src_cid_ != kTypedDataUint8ArrayCid)) {
        const Class& cls =
            Class::Handle(IsolateGroup::Current()->class_table()->At(src_cid_));
        if (!cls.IsNull()) {
          f->Printf(", src_cid=%s (%d)", cls.ScrubbedNameCString(), src_cid_);
        } else {
          f->Printf(", src_cid=%d", src_cid_);
        }
      }
      break;
    default:
      UNREACHABLE();
  }
  if (element_size() != 1) {
    f->Printf(", element_size=%" Pd "", element_size());
  }
  if (unboxed_inputs()) {
    f->AddString(", unboxed_inputs");
  }
  if (can_overlap()) {
    f->AddString(", can_overlap");
  }
}

void TailCallInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const char* name = "<unknown code>";
  if (code_.IsStubCode()) {
    name = StubCode::NameOfStub(code_.EntryPoint());
  } else {
    const Object& owner = Object::Handle(code_.owner());
    if (owner.IsFunction()) {
      name = Function::Handle(Function::RawCast(owner.ptr()))
                 .ToFullyQualifiedCString();
    }
  }
  f->Printf("%s(", name);
  InputAt(0)->PrintTo(f);
  f->AddString(")");
}

void Call1ArgStubInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const char* name = "";
  switch (stub_id_) {
    case StubId::kCloneSuspendState:
      name = "CloneSuspendState";
      break;
    case StubId::kInitAsync:
      name = "InitAsync";
      break;
    case StubId::kInitAsyncStar:
      name = "InitAsyncStar";
      break;
    case StubId::kInitSyncStar:
      name = "InitSyncStar";
      break;
    case StubId::kFfiAsyncCallbackSend:
      name = "FfiAsyncCallbackSend";
      break;
  }
  f->Printf("%s(", name);
  operand()->PrintTo(f);
  f->AddString(")");
}

void SuspendInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  const char* name = "";
  switch (stub_id_) {
    case StubId::kAwait:
      name = "Await";
      break;
    case StubId::kAwaitWithTypeCheck:
      name = "AwaitWithTypeCheck";
      break;
    case StubId::kYieldAsyncStar:
      name = "YieldAsyncStar";
      break;
    case StubId::kSuspendSyncStarAtStart:
      name = "SuspendSyncStarAtStart";
      break;
    case StubId::kSuspendSyncStarAtYield:
      name = "SuspendSyncStarAtYield";
      break;
  }
  f->Printf("%s(", name);
  Definition::PrintOperandsTo(f);
  f->AddString(")");
}

void MoveArgumentInstr::PrintOperandsTo(BaseTextBuffer* f) const {
  value()->PrintTo(f);
  f->Printf(", SP+%" Pd "", sp_relative_index());
}

void GotoInstr::PrintTo(BaseTextBuffer* f) const {
  if (HasParallelMove()) {
    parallel_move()->PrintTo(f);
    f->AddString(" ");
  }
  if (GetDeoptId() != DeoptId::kNone) {
    f->Printf("goto:%" Pd " B%" Pd "", GetDeoptId(), successor()->block_id());
  } else {
    f->Printf("goto: B%" Pd "", successor()->block_id());
  }
}

void IndirectGotoInstr::PrintTo(BaseTextBuffer* f) const {
  if (GetDeoptId() != DeoptId::kNone) {
    f->Printf("igoto:%" Pd "(", GetDeoptId());
  } else {
    f->AddString("igoto:(");
  }
  InputAt(0)->PrintTo(f);
  f->AddString(")");
}

void BranchInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("%s ", DebugName());
  f->AddString("if ");
  comparison()->PrintTo(f);

  f->Printf(" goto (%" Pd ", %" Pd ")", true_successor()->block_id(),
            false_successor()->block_id());
}

void ParallelMoveInstr::PrintTo(BaseTextBuffer* f) const {
  f->Printf("%s ", DebugName());
  for (intptr_t i = 0; i < moves_.length(); i++) {
    if (i != 0) f->AddString(", ");
    moves_[i]->dest().PrintTo(f);
    f->AddString(" <- ");
    moves_[i]->src().PrintTo(f);
  }
}

void Utf8ScanInstr::PrintTo(BaseTextBuffer* f) const {
  Definition::PrintTo(f);
  f->Printf(" [%s]", scan_flags_field_.Name());
}

void Environment::PrintTo(BaseTextBuffer* f) const {
  f->AddString(" env={ ");
  int arg_count = 0;
  for (intptr_t i = 0; i < values_.length(); ++i) {
    if (i > 0) f->AddString(", ");
    if (values_[i]->definition()->IsMoveArgument()) {
      f->Printf("a%d", arg_count++);
    } else {
      values_[i]->PrintTo(f);
    }
    if ((locations_ != nullptr) && !locations_[i].IsInvalid()) {
      f->AddString(" [");
      locations_[i].PrintTo(f);
      f->AddString("]");
    }
  }
  f->AddString(" }");
  if (outer_ != nullptr) outer_->PrintTo(f);
}

const char* Environment::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

#else  // defined(INCLUDE_IL_PRINTER)

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

bool FlowGraphPrinter::ShouldPrint(
    const Function& function,
    uint8_t** compiler_pass_filter /* = nullptr */) {
  return false;
}

#endif  // defined(INCLUDE_IL_PRINTER)

}  // namespace dart

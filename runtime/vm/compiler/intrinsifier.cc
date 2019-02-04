// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/intrinsifier.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, intrinsify, true, "Instrinsify when possible");
DEFINE_FLAG(bool, trace_intrinsifier, false, "Trace intrinsifier");
DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);

bool Intrinsifier::CanIntrinsify(const Function& function) {
  if (FLAG_trace_intrinsifier) {
    THR_Print("CanIntrinsify %s ->", function.ToQualifiedCString());
  }
  if (!FLAG_intrinsify) return false;
  // TODO(regis): We do not need to explicitly filter generic functions here,
  // unless there are errors we don't detect at link time. Revisit if necessary.
  if (function.IsClosureFunction()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, closure function.\n");
    }
    return false;
  }
  // Can occur because of compile-all flag.
  if (function.is_external()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, external function.\n");
    }
    return false;
  }
  if (!function.is_intrinsic()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, not intrinsic function.\n");
    }
    return false;
  }
  switch (function.recognized_kind()) {
    case MethodRecognizer::kInt64ArrayGetIndexed:
    case MethodRecognizer::kInt64ArraySetIndexed:
    case MethodRecognizer::kUint64ArrayGetIndexed:
    case MethodRecognizer::kUint64ArraySetIndexed:
      // TODO(ajcbik): consider 32-bit as well.
      if (kBitsPerWord == 64 && FlowGraphCompiler::SupportsUnboxedInt64()) {
        break;
      }
      if (FLAG_trace_intrinsifier) {
        THR_Print("No, 64-bit int intrinsic on 32-bit platform.\n");
      }
      return false;
    default:
      break;
  }
  if (FLAG_trace_intrinsifier) {
    THR_Print("Yes.\n");
  }
  return true;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
struct IntrinsicDesc {
  const char* class_name;
  const char* function_name;
};

struct LibraryInstrinsicsDesc {
  Library& library;
  IntrinsicDesc* intrinsics;
};

#define DEFINE_INTRINSIC(class_name, function_name, destination, fp)           \
  {#class_name, #function_name},

// clang-format off
static IntrinsicDesc core_intrinsics[] = {
  CORE_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  CORE_INTEGER_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  GRAPH_CORE_INTRINSICS_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc math_intrinsics[] = {
  MATH_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  GRAPH_MATH_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc typed_data_intrinsics[] = {
  TYPED_DATA_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  GRAPH_TYPED_DATA_INTRINSICS_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc developer_intrinsics[] = {
  DEVELOPER_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};
// clang-format on

void Intrinsifier::InitializeState() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  Function& func = Function::Handle(zone);
  String& str = String::Handle(zone);
  String& str2 = String::Handle(zone);
  Error& error = Error::Handle(zone);

  static const intptr_t kNumLibs = 4;
  LibraryInstrinsicsDesc intrinsics[kNumLibs] = {
      {Library::Handle(zone, Library::CoreLibrary()), core_intrinsics},
      {Library::Handle(zone, Library::MathLibrary()), math_intrinsics},
      {Library::Handle(zone, Library::TypedDataLibrary()),
       typed_data_intrinsics},
      {Library::Handle(zone, Library::DeveloperLibrary()),
       developer_intrinsics},
  };

  for (intptr_t i = 0; i < kNumLibs; i++) {
    lib = intrinsics[i].library.raw();
    for (IntrinsicDesc* intrinsic = intrinsics[i].intrinsics;
         intrinsic->class_name != nullptr; intrinsic++) {
      func = Function::null();
      if (strcmp(intrinsic->class_name, "::") == 0) {
        str = String::New(intrinsic->function_name);
        func = lib.LookupFunctionAllowPrivate(str);
      } else {
        str = String::New(intrinsic->class_name);
        cls = lib.LookupClassAllowPrivate(str);
        ASSERT(FLAG_precompiled_mode || !cls.IsNull());
        if (!cls.IsNull()) {
          error = cls.EnsureIsFinalized(thread);
          if (!error.IsNull()) {
            OS::PrintErr("%s\n", error.ToErrorCString());
          }
          ASSERT(error.IsNull());
          str = String::New(intrinsic->function_name);
          if (intrinsic->function_name[0] == '.') {
            str2 = String::New(intrinsic->class_name);
            str = String::Concat(str2, str);
          }
          func = cls.LookupFunctionAllowPrivate(str);
        }
      }
      if (!func.IsNull()) {
        func.set_is_intrinsic(true);
      } else if (!FLAG_precompiled_mode) {
        FATAL2("Intrinsifier failed to find method %s in class %s\n",
               intrinsic->function_name, intrinsic->class_name);
      }
    }
  }
#undef SETUP_FUNCTION
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// DBC does not use graph intrinsics.
#if !defined(TARGET_ARCH_DBC)
static void EmitCodeFor(FlowGraphCompiler* compiler, FlowGraph* graph) {
  // The FlowGraph here is constructed by the intrinsics builder methods, and
  // is different from compiler->flow_graph(), the original method's flow graph.
  compiler->assembler()->Comment("Graph intrinsic begin");
  for (intptr_t i = 0; i < graph->reverse_postorder().length(); i++) {
    BlockEntryInstr* block = graph->reverse_postorder()[i];
    if (block->IsGraphEntry()) continue;  // No code for graph entry needed.

    if (block->HasParallelMove()) {
      compiler->parallel_move_resolver()->EmitNativeCode(
          block->parallel_move());
    }

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (FLAG_code_comments) compiler->EmitComment(instr);
      if (instr->IsParallelMove()) {
        compiler->parallel_move_resolver()->EmitNativeCode(
            instr->AsParallelMove());
      } else if (instr->IsInvokeMathCFunction()) {
        ASSERT(instr->locs() != NULL);
        Intrinsifier::IntrinsicCallPrologue(compiler->assembler());
        instr->EmitNativeCode(compiler);
        Intrinsifier::IntrinsicCallEpilogue(compiler->assembler());
      } else {
        ASSERT(instr->locs() != NULL);
        // Calls are not supported in intrinsics code.
        ASSERT(!instr->locs()->always_calls());
        instr->EmitNativeCode(compiler);
      }
    }
  }
  compiler->assembler()->Comment("Graph intrinsic end");
}
#endif

bool Intrinsifier::GraphIntrinsify(const ParsedFunction& parsed_function,
                                   FlowGraphCompiler* compiler) {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(!parsed_function.function().HasOptionalParameters());
  PrologueInfo prologue_info(-1, -1);

  auto graph_entry =
      new GraphEntryInstr(parsed_function, Compiler::kNoOSRDeoptId);

  intptr_t block_id = 1;  // 0 is GraphEntry.
  graph_entry->set_normal_entry(
      new FunctionEntryInstr(graph_entry, block_id, kInvalidTryIndex,
                             CompilerState::Current().GetNextDeoptId()));

  FlowGraph* graph =
      new FlowGraph(parsed_function, graph_entry, block_id, prologue_info);
  const Function& function = parsed_function.function();
  switch (function.recognized_kind()) {
#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
  case MethodRecognizer::k##enum_name:                                         \
    if (!Build_##enum_name(graph)) return false;                               \
    break;

    GRAPH_INTRINSICS_LIST(EMIT_CASE);
    default:
      return false;
#undef EMIT_CASE
  }

  if (FLAG_support_il_printer && FLAG_print_flow_graph &&
      FlowGraphPrinter::ShouldPrint(function)) {
    THR_Print("Intrinsic graph before\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }

  // Prepare for register allocation (cf. FinalizeGraph).
  graph->RemoveRedefinitions();

  // Ensure loop hierarchy has been computed.
  GrowableArray<BitVector*> dominance_frontier;
  graph->ComputeDominators(&dominance_frontier);
  graph->GetLoopHierarchy();

  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*graph, true);  // Intrinsic mode.
  allocator.AllocateRegisters();

  if (FLAG_support_il_printer && FLAG_print_flow_graph &&
      FlowGraphPrinter::ShouldPrint(function)) {
    THR_Print("Intrinsic graph after\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }
  EmitCodeFor(compiler, graph);
  return true;
#else
  return false;
#endif  // !defined(TARGET_ARCH_DBC)
}

// Returns true if fall-through code can be omitted.
bool Intrinsifier::Intrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler) {
  const Function& function = parsed_function.function();
  if (!CanIntrinsify(function)) {
    return false;
  }

  ASSERT(!compiler->flow_graph().IsCompiledForOsr());
  if (GraphIntrinsify(parsed_function, compiler)) {
    return compiler->intrinsic_slow_path_label()->IsUnused();
  }

#if !defined(HASH_IN_OBJECT_HEADER)
  // These two are more complicated on 32 bit platforms, where the
  // identity hash is not stored in the header of the object.  We
  // therefore don't intrinsify them, falling back on the native C++
  // implementations.
  if (function.recognized_kind() == MethodRecognizer::kObject_getHash ||
      function.recognized_kind() == MethodRecognizer::kObject_setHash) {
    return false;
  }
#endif

#if !defined(PRODUCT) && !defined(TARGET_ARCH_DBC)
#define EMIT_BREAKPOINT() compiler->assembler()->Breakpoint()
#else
#define EMIT_BREAKPOINT()
#endif

#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
  case MethodRecognizer::k##enum_name: {                                       \
    compiler->assembler()->Comment("Intrinsic");                               \
    Label normal_ir_body;                                                      \
    const auto size_before = compiler->assembler()->CodeSize();                \
    enum_name(compiler->assembler(), &normal_ir_body);                         \
    const auto size_after = compiler->assembler()->CodeSize();                 \
    if (size_before == size_after) return false;                               \
    if (!normal_ir_body.IsBound()) {                                           \
      EMIT_BREAKPOINT();                                                       \
      return true;                                                             \
    }                                                                          \
    return false;                                                              \
  }

  switch (function.recognized_kind()) {
    ALL_INTRINSICS_NO_INTEGER_LIB_LIST(EMIT_CASE);
    default:
      break;
  }
  switch (function.recognized_kind()) {
    CORE_INTEGER_LIB_INTRINSIC_LIST(EMIT_CASE)
    default:
      break;
  }

// On DBC all graph intrinsics are handled in the same way as non-graph
// intrinsics.
#if defined(TARGET_ARCH_DBC)
  switch (function.recognized_kind()) {
    GRAPH_INTRINSICS_LIST(EMIT_CASE)
    default:
      break;
  }
#endif

#undef EMIT_BREAKPOINT

#undef EMIT_INTRINSIC
  return false;
}

#if !defined(TARGET_ARCH_DBC)
static intptr_t CidForRepresentation(Representation rep) {
  switch (rep) {
    case kUnboxedDouble:
      return kDoubleCid;
    case kUnboxedFloat32x4:
      return kFloat32x4Cid;
    case kUnboxedInt32x4:
      return kInt32x4Cid;
    case kUnboxedFloat64x2:
      return kFloat64x2Cid;
    case kUnboxedUint32:
      return kDynamicCid;  // smi or mint.
    default:
      UNREACHABLE();
      return kIllegalCid;
  }
}

static Representation RepresentationForCid(intptr_t cid) {
  switch (cid) {
    case kDoubleCid:
      return kUnboxedDouble;
    case kFloat32x4Cid:
      return kUnboxedFloat32x4;
    case kInt32x4Cid:
      return kUnboxedInt32x4;
    case kFloat64x2Cid:
      return kUnboxedFloat64x2;
    default:
      UNREACHABLE();
      return kNoRepresentation;
  }
}

// Notes about the graph intrinsics:
//
// IR instructions which would jump to a deoptimization sequence on failure
// instead branch to the intrinsic slow path.
//
class BlockBuilder : public ValueObject {
 public:
  BlockBuilder(FlowGraph* flow_graph, BlockEntryInstr* entry)
      : flow_graph_(flow_graph),
        entry_(entry),
        current_(entry),
        fall_through_env_(new Environment(0,
                                          0,
                                          DeoptId::kNone,
                                          flow_graph->parsed_function(),
                                          NULL)) {}

  Definition* AddToInitialDefinitions(Definition* def) {
    def->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    auto normal_entry = flow_graph_->graph_entry()->normal_entry();
    flow_graph_->AddToInitialDefinitions(normal_entry, def);
    return def;
  }

  Definition* AddDefinition(Definition* def) {
    def->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    AddInstruction(def);
    return def;
  }

  Instruction* AddInstruction(Instruction* instr) {
    if (instr->ComputeCanDeoptimize()) {
      // Since we use the presence of an environment to determine if an
      // instructions can deoptimize, we need an empty environment for
      // instructions that "deoptimize" to the intrinsic fall-through code.
      instr->SetEnvironment(fall_through_env_);
    }
    current_ = current_->AppendInstruction(instr);
    return instr;
  }

  void AddIntrinsicReturn(Value* value) {
    ReturnInstr* instr = new ReturnInstr(
        TokenPos(), value, CompilerState::Current().GetNextDeoptId());
    AddInstruction(instr);
    entry_->set_last_instruction(instr);
  }

  Definition* AddParameter(intptr_t index) {
    intptr_t adjustment = Intrinsifier::ParameterSlotFromSp();
    return AddToInitialDefinitions(new ParameterInstr(
        adjustment + index, flow_graph_->graph_entry(), SPREG));
  }

  TokenPosition TokenPos() { return flow_graph_->function().token_pos(); }

  Definition* AddNullDefinition() {
    return AddDefinition(new ConstantInstr(Object::ZoneHandle(Object::null())));
  }

  Definition* AddUnboxInstr(Representation rep, Value* value, bool is_checked) {
    Definition* unboxed_value =
        AddDefinition(UnboxInstr::Create(rep, value, DeoptId::kNone));
    if (is_checked) {
      // The type of |value| has already been checked and it is safe to
      // adjust reaching type. This is done manually because there is no type
      // propagation when building intrinsics.
      unboxed_value->AsUnbox()->value()->SetReachingType(
          new CompileType(CompileType::FromCid(CidForRepresentation(rep))));
    }
    return unboxed_value;
  }

  Definition* AddUnboxInstr(Representation rep,
                            Definition* boxed,
                            bool is_checked) {
    return AddUnboxInstr(rep, new Value(boxed), is_checked);
  }

  Definition* InvokeMathCFunction(MethodRecognizer::Kind recognized_kind,
                                  ZoneGrowableArray<Value*>* args) {
    return InvokeMathCFunctionHelper(recognized_kind, args);
  }

 private:
  Definition* InvokeMathCFunctionHelper(MethodRecognizer::Kind recognized_kind,
                                        ZoneGrowableArray<Value*>* args) {
    InvokeMathCFunctionInstr* invoke_math_c_function =
        new InvokeMathCFunctionInstr(args, DeoptId::kNone, recognized_kind,
                                     TokenPos());
    AddDefinition(invoke_math_c_function);
    return invoke_math_c_function;
  }

  FlowGraph* flow_graph_;
  BlockEntryInstr* entry_;
  Instruction* current_;
  Environment* fall_through_env_;
};

static Definition* PrepareIndexedOp(FlowGraph* flow_graph,
                                    BlockBuilder* builder,
                                    Definition* array,
                                    Definition* index,
                                    const Slot& length_field) {
  Definition* length = builder->AddDefinition(new LoadFieldInstr(
      new Value(array), length_field, TokenPosition::kNoSource));
  // Note that the intrinsifier must always use deopting array bound
  // checks, because intrinsics currently don't support calls.
  Definition* safe_index = new CheckArrayBoundInstr(
      new Value(length), new Value(index), DeoptId::kNone);
  builder->AddDefinition(safe_index);
  return safe_index;
}

static bool IntrinsifyArrayGetIndexed(FlowGraph* flow_graph,
                                      intptr_t array_cid) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* array = builder.AddParameter(2);

  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GetLengthFieldForArrayCid(array_cid));

  if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    array = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(array), ExternalTypedData::data_offset()));
  }

  Definition* result = builder.AddDefinition(new LoadIndexedInstr(
      new Value(array), new Value(index),
      Instance::ElementSizeFor(array_cid),  // index scale
      array_cid, kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  // Box and/or convert result if necessary.
  switch (array_cid) {
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedInt32, new Value(result)));
      break;
    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedUint32, new Value(result)));
      break;
    case kTypedDataFloat32ArrayCid:
      result = builder.AddDefinition(
          new FloatToDoubleInstr(new Value(result), DeoptId::kNone));
    // Fall through.
    case kTypedDataFloat64ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedDouble, new Value(result)));
      break;
    case kTypedDataFloat32x4ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedFloat32x4, new Value(result)));
      break;
    case kTypedDataInt32x4ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedInt32x4, new Value(result)));
      break;
    case kTypedDataFloat64x2ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedFloat64x2, new Value(result)));
      break;
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Nothing to do.
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      result = builder.AddDefinition(
          BoxInstr::Create(kUnboxedInt64, new Value(result)));
      break;
    default:
      UNREACHABLE();
      break;
  }
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

static bool IntrinsifyArraySetIndexed(FlowGraph* flow_graph,
                                      intptr_t array_cid) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GetLengthFieldForArrayCid(array_cid));

  // Value check/conversion.
  switch (array_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      builder.AddInstruction(new CheckSmiInstr(new Value(value), DeoptId::kNone,
                                               builder.TokenPos()));
      break;
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
    // Use same truncating unbox-instruction for int32 and uint32.
    // Fall-through.
    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      // Supports smi and mint, slow-case for bigints.
      value = builder.AddUnboxInstr(kUnboxedUint32, new Value(value),
                                    /* is_checked = */ false);
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      value = builder.AddUnboxInstr(kUnboxedInt64, new Value(value),
                                    /* is_checked = */ false);
      break;

    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid: {
      intptr_t value_check_cid = kDoubleCid;
      Representation rep = kUnboxedDouble;
      switch (array_cid) {
        case kTypedDataFloat32x4ArrayCid:
          value_check_cid = kFloat32x4Cid;
          rep = kUnboxedFloat32x4;
          break;
        case kTypedDataInt32x4ArrayCid:
          value_check_cid = kInt32x4Cid;
          rep = kUnboxedInt32x4;
          break;
        case kTypedDataFloat64x2ArrayCid:
          value_check_cid = kFloat64x2Cid;
          rep = kUnboxedFloat64x2;
          break;
        default:
          // Float32/Float64 case already handled.
          break;
      }
      Zone* zone = flow_graph->zone();
      Cids* value_check = Cids::CreateMonomorphic(zone, value_check_cid);
      builder.AddInstruction(new CheckClassInstr(
          new Value(value), DeoptId::kNone, *value_check, builder.TokenPos()));
      value = builder.AddUnboxInstr(rep, new Value(value),
                                    /* is_checked = */ true);
      if (array_cid == kTypedDataFloat32ArrayCid) {
        value = builder.AddDefinition(
            new DoubleToFloatInstr(new Value(value), DeoptId::kNone));
      }
      break;
    }
    default:
      UNREACHABLE();
  }

  if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    array = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(array), ExternalTypedData::data_offset()));
  }
  // No store barrier.
  ASSERT(RawObject::IsExternalTypedDataClassId(array_cid) ||
         RawObject::IsTypedDataClassId(array_cid));
  builder.AddInstruction(new StoreIndexedInstr(
      new Value(array), new Value(index), new Value(value), kNoStoreBarrier,
      Instance::ElementSizeFor(array_cid),  // index scale
      array_cid, kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

#define DEFINE_ARRAY_GETTER_INTRINSIC(enum_name)                               \
  bool Intrinsifier::Build_##enum_name##GetIndexed(FlowGraph* flow_graph) {    \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_ARRAY_SETTER_INTRINSIC(enum_name)                               \
  bool Intrinsifier::Build_##enum_name##SetIndexed(FlowGraph* flow_graph) {    \
    return IntrinsifyArraySetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##SetIndexed));          \
  }

DEFINE_ARRAY_GETTER_INTRINSIC(ObjectArray)
DEFINE_ARRAY_GETTER_INTRINSIC(ImmutableArray)

#define DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(enum_name)                       \
  DEFINE_ARRAY_GETTER_INTRINSIC(enum_name)                                     \
  DEFINE_ARRAY_SETTER_INTRINSIC(enum_name)

DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Int8Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Uint8Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(ExternalUint8Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Uint8ClampedArray)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(ExternalUint8ClampedArray)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Int16Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Uint16Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Int32Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Uint32Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Int64Array)
DEFINE_ARRAY_GETTER_SETTER_INTRINSICS(Uint64Array)

#undef DEFINE_ARRAY_GETTER_SETTER_INTRINSICS
#undef DEFINE_ARRAY_GETTER_INTRINSIC
#undef DEFINE_ARRAY_SETTER_INTRINSIC

#define DEFINE_FLOAT_ARRAY_GETTER_INTRINSIC(enum_name)                         \
  bool Intrinsifier::Build_##enum_name##GetIndexed(FlowGraph* flow_graph) {    \
    if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_FLOAT_ARRAY_SETTER_INTRINSIC(enum_name)                         \
  bool Intrinsifier::Build_##enum_name##SetIndexed(FlowGraph* flow_graph) {    \
    if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArraySetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##SetIndexed));          \
  }

#define DEFINE_FLOAT_ARRAY_GETTER_SETTER_INTRINSICS(enum_name)                 \
  DEFINE_FLOAT_ARRAY_GETTER_INTRINSIC(enum_name)                               \
  DEFINE_FLOAT_ARRAY_SETTER_INTRINSIC(enum_name)

DEFINE_FLOAT_ARRAY_GETTER_SETTER_INTRINSICS(Float64Array)
DEFINE_FLOAT_ARRAY_GETTER_SETTER_INTRINSICS(Float32Array)

#undef DEFINE_FLOAT_ARRAY_GETTER_SETTER_INTRINSICS
#undef DEFINE_FLOAT_ARRAY_GETTER_INTRINSIC
#undef DEFINE_FLOAT_ARRAY_SETTER_INTRINSIC

#define DEFINE_SIMD_ARRAY_GETTER_INTRINSIC(enum_name)                          \
  bool Intrinsifier::Build_##enum_name##GetIndexed(FlowGraph* flow_graph) {    \
    if (!FlowGraphCompiler::SupportsUnboxedSimd128()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_SIMD_ARRAY_SETTER_INTRINSIC(enum_name)                          \
  bool Intrinsifier::Build_##enum_name##SetIndexed(FlowGraph* flow_graph) {    \
    if (!FlowGraphCompiler::SupportsUnboxedSimd128()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArraySetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##SetIndexed));          \
  }

#define DEFINE_SIMD_ARRAY_GETTER_SETTER_INTRINSICS(enum_name)                  \
  DEFINE_SIMD_ARRAY_GETTER_INTRINSIC(enum_name)                                \
  DEFINE_SIMD_ARRAY_SETTER_INTRINSIC(enum_name)

DEFINE_SIMD_ARRAY_GETTER_SETTER_INTRINSICS(Float32x4Array)
DEFINE_SIMD_ARRAY_GETTER_SETTER_INTRINSICS(Int32x4Array)
DEFINE_SIMD_ARRAY_GETTER_SETTER_INTRINSICS(Float64x2Array)

#undef DEFINE_SIMD_ARRAY_GETTER_SETTER_INTRINSICS
#undef DEFINE_SIMD_ARRAY_GETTER_INTRINSIC
#undef DEFINE_SIMD_ARRAY_SETTER_INTRINSIC

static bool BuildCodeUnitAt(FlowGraph* flow_graph, intptr_t cid) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* str = builder.AddParameter(2);

  index =
      PrepareIndexedOp(flow_graph, &builder, str, index, Slot::String_length());

  // For external strings: Load external data.
  if (cid == kExternalOneByteStringCid) {
    str = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(str), ExternalOneByteString::external_data_offset()));
  } else if (cid == kExternalTwoByteStringCid) {
    str = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(str), ExternalTwoByteString::external_data_offset()));
  }

  Definition* result = builder.AddDefinition(new LoadIndexedInstr(
      new Value(str), new Value(index), Instance::ElementSizeFor(cid), cid,
      kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

bool Intrinsifier::Build_OneByteStringCodeUnitAt(FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kOneByteStringCid);
}

bool Intrinsifier::Build_TwoByteStringCodeUnitAt(FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kTwoByteStringCid);
}

bool Intrinsifier::Build_ExternalOneByteStringCodeUnitAt(
    FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kExternalOneByteStringCid);
}

bool Intrinsifier::Build_ExternalTwoByteStringCodeUnitAt(
    FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kExternalTwoByteStringCid);
}

static bool BuildSimdOp(FlowGraph* flow_graph, intptr_t cid, Token::Kind kind) {
  if (!FlowGraphCompiler::SupportsUnboxedSimd128()) return false;

  const Representation rep = RepresentationForCid(cid);

  Zone* zone = flow_graph->zone();
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* right = builder.AddParameter(1);
  Definition* left = builder.AddParameter(2);

  Cids* value_check = Cids::CreateMonomorphic(zone, cid);
  // Check argument. Receiver (left) is known to be a Float32x4.
  builder.AddInstruction(new CheckClassInstr(new Value(right), DeoptId::kNone,
                                             *value_check, builder.TokenPos()));
  Definition* left_simd = builder.AddUnboxInstr(rep, new Value(left),
                                                /* is_checked = */ true);

  Definition* right_simd = builder.AddUnboxInstr(rep, new Value(right),
                                                 /* is_checked = */ true);

  Definition* unboxed_result = builder.AddDefinition(SimdOpInstr::Create(
      SimdOpInstr::KindForOperator(cid, kind), new Value(left_simd),
      new Value(right_simd), DeoptId::kNone));
  Definition* result =
      builder.AddDefinition(BoxInstr::Create(rep, new Value(unboxed_result)));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

bool Intrinsifier::Build_Float32x4Mul(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kMUL);
}

bool Intrinsifier::Build_Float32x4Sub(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kSUB);
}

bool Intrinsifier::Build_Float32x4Add(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kADD);
}

static bool BuildFloat32x4Shuffle(FlowGraph* flow_graph,
                                  MethodRecognizer::Kind kind) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles() ||
      !FlowGraphCompiler::SupportsUnboxedSimd128()) {
    return false;
  }
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* receiver = builder.AddParameter(1);

  Definition* unboxed_receiver =
      builder.AddUnboxInstr(kUnboxedFloat32x4, new Value(receiver),
                            /* is_checked = */ true);

  Definition* unboxed_result = builder.AddDefinition(
      SimdOpInstr::Create(kind, new Value(unboxed_receiver), DeoptId::kNone));

  Definition* result = builder.AddDefinition(
      BoxInstr::Create(kUnboxedDouble, new Value(unboxed_result)));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

bool Intrinsifier::Build_Float32x4ShuffleX(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleX);
}

bool Intrinsifier::Build_Float32x4ShuffleY(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleY);
}

bool Intrinsifier::Build_Float32x4ShuffleZ(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleZ);
}

bool Intrinsifier::Build_Float32x4ShuffleW(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleW);
}

static bool BuildLoadField(FlowGraph* flow_graph, const Slot& field) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(1);

  Definition* length = builder.AddDefinition(
      new LoadFieldInstr(new Value(array), field, builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(length));
  return true;
}

bool Intrinsifier::Build_ObjectArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::Array_length());
}

bool Intrinsifier::Build_ImmutableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::Array_length());
}

bool Intrinsifier::Build_GrowableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::GrowableObjectArray_length());
}

bool Intrinsifier::Build_StringBaseLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::String_length());
}

bool Intrinsifier::Build_TypedDataLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::TypedData_length());
}

bool Intrinsifier::Build_GrowableArrayCapacity(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(1);

  Definition* backing_store = builder.AddDefinition(new LoadFieldInstr(
      new Value(array), Slot::GrowableObjectArray_data(), builder.TokenPos()));
  Definition* capacity = builder.AddDefinition(new LoadFieldInstr(
      new Value(backing_store), Slot::Array_length(), builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(capacity));
  return true;
}

bool Intrinsifier::Build_GrowableArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);

  index = PrepareIndexedOp(flow_graph, &builder, growable_array, index,
                           Slot::GrowableObjectArray_length());

  Definition* backing_store = builder.AddDefinition(
      new LoadFieldInstr(new Value(growable_array),
                         Slot::GrowableObjectArray_data(), builder.TokenPos()));
  Definition* result = builder.AddDefinition(new LoadIndexedInstr(
      new Value(backing_store), new Value(index),
      Instance::ElementSizeFor(kArrayCid),  // index scale
      kArrayCid, kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

bool Intrinsifier::Build_ObjectArraySetIndexed(FlowGraph* flow_graph) {
  if (Isolate::Current()->argument_type_checks()) {
    return false;
  }

  return Build_ObjectArraySetIndexedUnchecked(flow_graph);
}

bool Intrinsifier::Build_ObjectArraySetIndexedUnchecked(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::Array_length());

  builder.AddInstruction(new StoreIndexedInstr(
      new Value(array), new Value(index), new Value(value), kEmitStoreBarrier,
      Instance::ElementSizeFor(kArrayCid),  // index scale
      kArrayCid, kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

bool Intrinsifier::Build_GrowableArraySetIndexed(FlowGraph* flow_graph) {
  if (Isolate::Current()->argument_type_checks()) {
    return false;
  }

  return Build_GrowableArraySetIndexedUnchecked(flow_graph);
}

bool Intrinsifier::Build_GrowableArraySetIndexedUnchecked(
    FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GrowableObjectArray_length());

  Definition* backing_store = builder.AddDefinition(new LoadFieldInstr(
      new Value(array), Slot::GrowableObjectArray_data(), builder.TokenPos()));

  builder.AddInstruction(new StoreIndexedInstr(
      new Value(backing_store), new Value(index), new Value(value),
      kEmitStoreBarrier,
      Instance::ElementSizeFor(kArrayCid),  // index scale
      kArrayCid, kAlignedAccess, DeoptId::kNone, builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

bool Intrinsifier::Build_GrowableArraySetData(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* data = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);
  Zone* zone = flow_graph->zone();

  Cids* value_check = Cids::CreateMonomorphic(zone, kArrayCid);
  builder.AddInstruction(new CheckClassInstr(new Value(data), DeoptId::kNone,
                                             *value_check, builder.TokenPos()));

  builder.AddInstruction(new StoreInstanceFieldInstr(
      Slot::GrowableObjectArray_data(), new Value(growable_array),
      new Value(data), kEmitStoreBarrier, builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

bool Intrinsifier::Build_GrowableArraySetLength(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* length = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);

  builder.AddInstruction(
      new CheckSmiInstr(new Value(length), DeoptId::kNone, builder.TokenPos()));
  builder.AddInstruction(new StoreInstanceFieldInstr(
      Slot::GrowableObjectArray_length(), new Value(growable_array),
      new Value(length), kNoStoreBarrier, builder.TokenPos()));
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

bool Intrinsifier::Build_DoubleFlipSignBit(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {
    return false;
  }
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* receiver = builder.AddParameter(1);
  Definition* unboxed_value =
      builder.AddUnboxInstr(kUnboxedDouble, new Value(receiver),
                            /* is_checked = */ true);
  Definition* unboxed_result = builder.AddDefinition(new UnaryDoubleOpInstr(
      Token::kNEGATE, new Value(unboxed_value), DeoptId::kNone));
  Definition* result = builder.AddDefinition(
      BoxInstr::Create(kUnboxedDouble, new Value(unboxed_result)));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}

static bool BuildInvokeMathCFunction(BlockBuilder* builder,
                                     MethodRecognizer::Kind kind,
                                     intptr_t num_parameters = 1) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {
    return false;
  }
  ZoneGrowableArray<Value*>* args =
      new ZoneGrowableArray<Value*>(num_parameters);

  for (intptr_t i = 0; i < num_parameters; i++) {
    const intptr_t parameter_index = (num_parameters - i);
    Definition* value = builder->AddParameter(parameter_index);
    Definition* unboxed_value =
        builder->AddUnboxInstr(kUnboxedDouble, value, /* is_checked = */ false);
    args->Add(new Value(unboxed_value));
  }

  Definition* unboxed_result = builder->InvokeMathCFunction(kind, args);

  Definition* result = builder->AddDefinition(
      BoxInstr::Create(kUnboxedDouble, new Value(unboxed_result)));

  builder->AddIntrinsicReturn(new Value(result));

  return true;
}

bool Intrinsifier::Build_MathSin(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathSin);
}

bool Intrinsifier::Build_MathCos(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathCos);
}

bool Intrinsifier::Build_MathTan(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathTan);
}

bool Intrinsifier::Build_MathAsin(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAsin);
}

bool Intrinsifier::Build_MathAcos(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAcos);
}

bool Intrinsifier::Build_MathAtan(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAtan);
}

bool Intrinsifier::Build_MathAtan2(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAtan2,
                                  /* num_parameters = */ 2);
}

bool Intrinsifier::Build_DoubleMod(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleMod,
                                  /* num_parameters = */ 2);
}

bool Intrinsifier::Build_DoubleCeil(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleCeil);
}

bool Intrinsifier::Build_DoubleFloor(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleFloor);
}

bool Intrinsifier::Build_DoubleTruncate(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleTruncate);
}

bool Intrinsifier::Build_DoubleRound(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleRound);
}

void Intrinsifier::String_identityHash(Assembler* assembler,
                                       Label* normal_ir_body) {
  String_getHashCode(assembler, normal_ir_body);
}

void Intrinsifier::Double_identityHash(Assembler* assembler,
                                       Label* normal_ir_body) {
  Double_hashCode(assembler, normal_ir_body);
}

void Intrinsifier::RegExp_ExecuteMatch(Assembler* assembler,
                                       Label* normal_ir_body) {
  IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body, /*sticky=*/false);
}

void Intrinsifier::RegExp_ExecuteMatchSticky(Assembler* assembler,
                                             Label* normal_ir_body) {
  IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body, /*sticky=*/true);
}
#endif  // !defined(TARGET_ARCH_DBC)

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

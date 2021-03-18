// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#include "vm/compiler/graph_intrinsifier.h"
#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/intrinsifier.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/flag_list.h"

namespace dart {

DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);

class GraphInstrinsicCodeGenScope {
 public:
  explicit GraphInstrinsicCodeGenScope(FlowGraphCompiler* compiler)
      : compiler_(compiler), old_is_optimizing_(compiler->is_optimizing()) {
    compiler_->is_optimizing_ = true;
  }
  ~GraphInstrinsicCodeGenScope() {
    compiler_->is_optimizing_ = old_is_optimizing_;
  }

 private:
  FlowGraphCompiler* compiler_;
  bool old_is_optimizing_;
};

namespace compiler {

static void EmitCodeFor(FlowGraphCompiler* compiler, FlowGraph* graph) {
  // For graph intrinsics we run the linearscan register allocator, which will
  // pass opt=true for MakeLocationSummary. We therefore also have to ensure
  // `compiler->is_optimizing()` is set to true during EmitNativeCode.
  GraphInstrinsicCodeGenScope optimizing_scope(compiler);

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
        GraphIntrinsifier::IntrinsicCallPrologue(compiler->assembler());
        instr->EmitNativeCode(compiler);
        GraphIntrinsifier::IntrinsicCallEpilogue(compiler->assembler());
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

bool GraphIntrinsifier::GraphIntrinsify(const ParsedFunction& parsed_function,
                                        FlowGraphCompiler* compiler) {
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
  compiler->set_intrinsic_flow_graph(*graph);

  const Function& function = parsed_function.function();

  switch (function.recognized_kind()) {
#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
  case MethodRecognizer::k##enum_name:                                         \
    if (!Build_##enum_name(graph)) return false;                               \
    break;

    GRAPH_INTRINSICS_LIST(EMIT_CASE);
#undef EMIT_CASE
    default:
      if (function.IsImplicitGetterFunction()) {
        if (!Build_ImplicitGetter(graph)) return false;
      } else if (function.IsImplicitSetterFunction()) {
        if (!Build_ImplicitSetter(graph)) return false;
      } else {
        return false;
      }
  }

  if (FLAG_support_il_printer && FLAG_print_flow_graph &&
      FlowGraphPrinter::ShouldPrint(function)) {
    THR_Print("Intrinsic graph before\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }

  // Prepare for register allocation (cf. FinalizeGraph).
  graph->RemoveRedefinitions();

  // Ensure dominators are re-computed. Normally this is done during SSA
  // construction (which we don't do for graph intrinsics).
  GrowableArray<BitVector*> dominance_frontier;
  graph->ComputeDominators(&dominance_frontier);

  CompilerPassState state(parsed_function.thread(), graph,
                          /*speculative_inlining_policy*/ nullptr);
  CompilerPass::RunGraphIntrinsicPipeline(&state);

  if (FLAG_support_il_printer && FLAG_print_flow_graph &&
      FlowGraphPrinter::ShouldPrint(function)) {
    THR_Print("Intrinsic graph after\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }
  EmitCodeFor(compiler, graph);
  return true;
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
static Definition* PrepareIndexedOp(FlowGraph* flow_graph,
                                    BlockBuilder* builder,
                                    Definition* array,
                                    Definition* index,
                                    const Slot& length_field) {
  Definition* length = builder->AddDefinition(
      new LoadFieldInstr(new Value(array), length_field, InstructionSource()));
  // Note that the intrinsifier must always use deopting array bound
  // checks, because intrinsics currently don't support calls.
  Definition* safe_index = new CheckArrayBoundInstr(
      new Value(length), new Value(index), DeoptId::kNone);
  builder->AddDefinition(safe_index);
  return safe_index;
}

static void VerifyParameterIsBoxed(BlockBuilder* builder, intptr_t arg_index) {
  const auto& function = builder->function();
  if (function.is_unboxed_parameter_at(arg_index)) {
    FATAL2("Unsupported unboxed parameter %" Pd " in %s", arg_index,
           function.ToFullyQualifiedCString());
  }
}

static Definition* CreateBoxedParameterIfNeeded(BlockBuilder* builder,
                                                Definition* value,
                                                Representation representation,
                                                intptr_t arg_index) {
  const auto& function = builder->function();
  if (function.is_unboxed_parameter_at(arg_index)) {
    return builder->AddDefinition(
        BoxInstr::Create(representation, new Value(value)));
  } else {
    return value;
  }
}

static Definition* CreateBoxedResultIfNeeded(BlockBuilder* builder,
                                             Definition* value,
                                             Representation representation) {
  const auto& function = builder->function();
  if (function.has_unboxed_return()) {
    return value;
  } else {
    return builder->AddDefinition(
        BoxInstr::Create(representation, new Value(value)));
  }
}

static Definition* CreateUnboxedResultIfNeeded(BlockBuilder* builder,
                                               Definition* value) {
  const auto& function = builder->function();
  if (function.has_unboxed_return() && value->representation() == kTagged) {
    return builder->AddUnboxInstr(FlowGraph::ReturnRepresentationOf(function),
                                  new Value(value), /* is_checked = */ true);
  } else {
    return value;
  }
}

static bool IntrinsifyArrayGetIndexed(FlowGraph* flow_graph,
                                      intptr_t array_cid) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GetLengthFieldForArrayCid(array_cid));

  if (IsExternalTypedDataClassId(array_cid)) {
    array = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(array), target::TypedDataBase::data_field_offset()));
  }

  Definition* result = builder.AddDefinition(new LoadIndexedInstr(
      new Value(array), new Value(index), /*index_unboxed=*/false,
      /*index_scale=*/target::Instance::ElementSizeFor(array_cid), array_cid,
      kAlignedAccess, DeoptId::kNone, builder.Source()));

  // We don't perform [RangeAnalysis] for graph intrinsics. To inform the
  // following boxing instruction about a more precise range we attach it here
  // manually.
  // http://dartbug.com/36632
  const bool known_range =
      array_cid == kTypedDataInt8ArrayCid ||
      array_cid == kTypedDataUint8ArrayCid ||
      array_cid == kTypedDataUint8ClampedArrayCid ||
      array_cid == kExternalTypedDataUint8ArrayCid ||
      array_cid == kExternalTypedDataUint8ClampedArrayCid ||
      array_cid == kTypedDataInt16ArrayCid ||
      array_cid == kTypedDataUint16ArrayCid ||
      array_cid == kTypedDataInt32ArrayCid ||
      array_cid == kTypedDataUint32ArrayCid || array_cid == kOneByteStringCid ||
      array_cid == kTwoByteStringCid;

  bool clear_environment = false;
  if (known_range) {
    Range range;
    result->InferRange(/*range_analysis=*/nullptr, &range);
    result->set_range(range);
    clear_environment = range.Fits(RangeBoundary::kRangeBoundarySmi);
  }

  // Box and/or convert result if necessary.
  switch (array_cid) {
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedInt32);
      break;
    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedUint32);
      break;
    case kTypedDataFloat32ArrayCid:
      result = builder.AddDefinition(
          new FloatToDoubleInstr(new Value(result), DeoptId::kNone));
      FALL_THROUGH;
    case kTypedDataFloat64ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedDouble);
      break;
    case kTypedDataFloat32x4ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedFloat32x4);
      break;
    case kTypedDataInt32x4ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedInt32x4);
      break;
    case kTypedDataFloat64x2ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedFloat64x2);
      break;
    case kArrayCid:
    case kImmutableArrayCid:
      // Nothing to do.
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedIntPtr);
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      result = CreateBoxedResultIfNeeded(&builder, result, kUnboxedInt64);
      break;
    default:
      UNREACHABLE();
      break;
  }
  if (result->IsBoxInteger() && clear_environment) {
    result->AsBoxInteger()->ClearEnv();
  }
  result = CreateUnboxedResultIfNeeded(&builder, result);
  builder.AddReturn(new Value(result));
  return true;
}

static bool IntrinsifyArraySetIndexed(FlowGraph* flow_graph,
                                      intptr_t array_cid) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);
  Definition* value = builder.AddParameter(2, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 2);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GetLengthFieldForArrayCid(array_cid));

  // Value check/conversion.
  switch (array_cid) {
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
#if defined(TARGET_ARCH_IS_32_BIT)
      // On 32-bit architectures, clamping operations need the exact value
      // for proper operations. On 64-bit architectures, kUnboxedIntPtr
      // maps to kUnboxedInt64. All other situations get away with
      // truncating even non-smi values.
      builder.AddInstruction(new CheckSmiInstr(new Value(value), DeoptId::kNone,
                                               builder.Source()));
      FALL_THROUGH;
#endif
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
      value = builder.AddUnboxInstr(kUnboxedIntPtr, new Value(value),
                                    /* is_checked = */ false);
      value->AsUnboxInteger()->mark_truncating();
      break;
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      // Use same truncating unbox-instruction for int32 and uint32.
      FALL_THROUGH;
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
          new Value(value), DeoptId::kNone, *value_check, builder.Source()));
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

  if (IsExternalTypedDataClassId(array_cid)) {
    array = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(array), target::TypedDataBase::data_field_offset()));
  }
  // No store barrier.
  ASSERT(IsExternalTypedDataClassId(array_cid) ||
         IsTypedDataClassId(array_cid));
  builder.AddInstruction(new StoreIndexedInstr(
      new Value(array), new Value(index), new Value(value), kNoStoreBarrier,
      /*index_unboxed=*/false,
      /*index_scale=*/target::Instance::ElementSizeFor(array_cid), array_cid,
      kAlignedAccess, DeoptId::kNone, builder.Source()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddReturn(new Value(null_def));
  return true;
}

#define DEFINE_ARRAY_GETTER_INTRINSIC(enum_name)                               \
  bool GraphIntrinsifier::Build_##enum_name##GetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_ARRAY_SETTER_INTRINSIC(enum_name)                               \
  bool GraphIntrinsifier::Build_##enum_name##SetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
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
  bool GraphIntrinsifier::Build_##enum_name##GetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
    if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_FLOAT_ARRAY_SETTER_INTRINSIC(enum_name)                         \
  bool GraphIntrinsifier::Build_##enum_name##SetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
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
  bool GraphIntrinsifier::Build_##enum_name##GetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
    if (!FlowGraphCompiler::SupportsUnboxedSimd128()) {                        \
      return false;                                                            \
    }                                                                          \
    return IntrinsifyArrayGetIndexed(                                          \
        flow_graph, MethodRecognizer::MethodKindToReceiverCid(                 \
                        MethodRecognizer::k##enum_name##GetIndexed));          \
  }

#define DEFINE_SIMD_ARRAY_SETTER_INTRINSIC(enum_name)                          \
  bool GraphIntrinsifier::Build_##enum_name##SetIndexed(                       \
      FlowGraph* flow_graph) {                                                 \
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

  Definition* str = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index =
      PrepareIndexedOp(flow_graph, &builder, str, index, Slot::String_length());

  // For external strings: Load external data.
  if (cid == kExternalOneByteStringCid) {
    str = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(str), target::ExternalOneByteString::external_data_offset()));
  } else if (cid == kExternalTwoByteStringCid) {
    str = builder.AddDefinition(new LoadUntaggedInstr(
        new Value(str), target::ExternalTwoByteString::external_data_offset()));
  }

  Definition* load = builder.AddDefinition(new LoadIndexedInstr(
      new Value(str), new Value(index), /*index_unboxed=*/false,
      target::Instance::ElementSizeFor(cid), cid, kAlignedAccess,
      DeoptId::kNone, builder.Source()));

  // We don't perform [RangeAnalysis] for graph intrinsics. To inform the
  // following boxing instruction about a more precise range we attach it here
  // manually.
  // http://dartbug.com/36632
  Range range;
  load->InferRange(/*range_analysis=*/nullptr, &range);
  load->set_range(range);

  Definition* result =
      CreateBoxedResultIfNeeded(&builder, load, kUnboxedIntPtr);

  if (result->IsBoxInteger()) {
    result->AsBoxInteger()->ClearEnv();
  }

  builder.AddReturn(new Value(result));
  return true;
}

bool GraphIntrinsifier::Build_OneByteStringCodeUnitAt(FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kOneByteStringCid);
}

bool GraphIntrinsifier::Build_TwoByteStringCodeUnitAt(FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kTwoByteStringCid);
}

bool GraphIntrinsifier::Build_ExternalOneByteStringCodeUnitAt(
    FlowGraph* flow_graph) {
  return BuildCodeUnitAt(flow_graph, kExternalOneByteStringCid);
}

bool GraphIntrinsifier::Build_ExternalTwoByteStringCodeUnitAt(
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

  Definition* left = builder.AddParameter(0, /*with_frame=*/false);
  Definition* right = builder.AddParameter(1, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 1);

  Cids* value_check = Cids::CreateMonomorphic(zone, cid);
  // Check argument. Receiver (left) is known to be a Float32x4.
  builder.AddInstruction(new CheckClassInstr(new Value(right), DeoptId::kNone,
                                             *value_check, builder.Source()));
  Definition* left_simd = builder.AddUnboxInstr(rep, new Value(left),
                                                /* is_checked = */ true);

  Definition* right_simd = builder.AddUnboxInstr(rep, new Value(right),
                                                 /* is_checked = */ true);

  Definition* unboxed_result = builder.AddDefinition(SimdOpInstr::Create(
      SimdOpInstr::KindForOperator(cid, kind), new Value(left_simd),
      new Value(right_simd), DeoptId::kNone));
  Definition* result = CreateBoxedResultIfNeeded(&builder, unboxed_result, rep);

  builder.AddReturn(new Value(result));
  return true;
}

bool GraphIntrinsifier::Build_Float32x4Mul(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kMUL);
}

bool GraphIntrinsifier::Build_Float32x4Div(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kDIV);
}

bool GraphIntrinsifier::Build_Float32x4Sub(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kSUB);
}

bool GraphIntrinsifier::Build_Float32x4Add(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat32x4Cid, Token::kADD);
}

bool GraphIntrinsifier::Build_Float64x2Mul(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat64x2Cid, Token::kMUL);
}

bool GraphIntrinsifier::Build_Float64x2Div(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat64x2Cid, Token::kDIV);
}

bool GraphIntrinsifier::Build_Float64x2Sub(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat64x2Cid, Token::kSUB);
}

bool GraphIntrinsifier::Build_Float64x2Add(FlowGraph* flow_graph) {
  return BuildSimdOp(flow_graph, kFloat64x2Cid, Token::kADD);
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

  Definition* receiver = builder.AddParameter(0, /*with_frame=*/false);

  const auto& function = flow_graph->function();
  Definition* unboxed_receiver =
      !function.is_unboxed_parameter_at(0)
          ? builder.AddUnboxInstr(kUnboxedFloat32x4, new Value(receiver),
                                  /* is_checked = */ true)
          : receiver;

  Definition* unboxed_result = builder.AddDefinition(
      SimdOpInstr::Create(kind, new Value(unboxed_receiver), DeoptId::kNone));

  Definition* result =
      CreateBoxedResultIfNeeded(&builder, unboxed_result, kUnboxedDouble);

  builder.AddReturn(new Value(result));
  return true;
}

bool GraphIntrinsifier::Build_Float32x4ShuffleX(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleX);
}

bool GraphIntrinsifier::Build_Float32x4ShuffleY(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleY);
}

bool GraphIntrinsifier::Build_Float32x4ShuffleZ(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleZ);
}

bool GraphIntrinsifier::Build_Float32x4ShuffleW(FlowGraph* flow_graph) {
  return BuildFloat32x4Shuffle(flow_graph,
                               MethodRecognizer::kFloat32x4ShuffleW);
}

static bool BuildLoadField(FlowGraph* flow_graph, const Slot& field) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  VerifyParameterIsBoxed(&builder, 0);

  Definition* length = builder.AddDefinition(
      new LoadFieldInstr(new Value(array), field, builder.Source()));

  length = CreateUnboxedResultIfNeeded(&builder, length);
  builder.AddReturn(new Value(length));
  return true;
}

bool GraphIntrinsifier::Build_ObjectArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::Array_length());
}

bool GraphIntrinsifier::Build_ImmutableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::Array_length());
}

bool GraphIntrinsifier::Build_GrowableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::GrowableObjectArray_length());
}

bool GraphIntrinsifier::Build_StringBaseLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::String_length());
}

bool GraphIntrinsifier::Build_TypedListLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::TypedDataBase_length());
}

bool GraphIntrinsifier::Build_TypedListViewLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::TypedDataBase_length());
}

bool GraphIntrinsifier::Build_ByteDataViewLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Slot::TypedDataBase_length());
}

bool GraphIntrinsifier::Build_GrowableArrayCapacity(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  VerifyParameterIsBoxed(&builder, 0);

  Definition* backing_store = builder.AddDefinition(new LoadFieldInstr(
      new Value(array), Slot::GrowableObjectArray_data(), builder.Source()));
  Definition* capacity = builder.AddDefinition(new LoadFieldInstr(
      new Value(backing_store), Slot::Array_length(), builder.Source()));
  capacity = CreateUnboxedResultIfNeeded(&builder, capacity);
  builder.AddReturn(new Value(capacity));
  return true;
}

bool GraphIntrinsifier::Build_GrowableArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* growable_array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index = PrepareIndexedOp(flow_graph, &builder, growable_array, index,
                           Slot::GrowableObjectArray_length());

  Definition* backing_store = builder.AddDefinition(
      new LoadFieldInstr(new Value(growable_array),
                         Slot::GrowableObjectArray_data(), builder.Source()));
  Definition* result = builder.AddDefinition(new LoadIndexedInstr(
      new Value(backing_store), new Value(index), /*index_unboxed=*/false,
      /*index_scale=*/target::Instance::ElementSizeFor(kArrayCid), kArrayCid,
      kAlignedAccess, DeoptId::kNone, builder.Source()));
  result = CreateUnboxedResultIfNeeded(&builder, result);
  builder.AddReturn(new Value(result));
  return true;
}

bool GraphIntrinsifier::Build_ObjectArraySetIndexedUnchecked(
    FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);
  Definition* value = builder.AddParameter(2, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 2);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::Array_length());

  builder.AddInstruction(new StoreIndexedInstr(
      new Value(array), new Value(index), new Value(value), kEmitStoreBarrier,
      /*index_unboxed=*/false,
      /*index_scale=*/target::Instance::ElementSizeFor(kArrayCid), kArrayCid,
      kAlignedAccess, DeoptId::kNone, builder.Source()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddReturn(new Value(null_def));
  return true;
}

bool GraphIntrinsifier::Build_GrowableArraySetIndexedUnchecked(
    FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* index = builder.AddParameter(1, /*with_frame=*/false);
  Definition* value = builder.AddParameter(2, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 2);

  index = CreateBoxedParameterIfNeeded(&builder, index, kUnboxedInt64, 1);
  index = PrepareIndexedOp(flow_graph, &builder, array, index,
                           Slot::GrowableObjectArray_length());

  Definition* backing_store = builder.AddDefinition(new LoadFieldInstr(
      new Value(array), Slot::GrowableObjectArray_data(), builder.Source()));

  builder.AddInstruction(new StoreIndexedInstr(
      new Value(backing_store), new Value(index), new Value(value),
      kEmitStoreBarrier, /*index_unboxed=*/false,
      /*index_scale=*/target::Instance::ElementSizeFor(kArrayCid), kArrayCid,
      kAlignedAccess, DeoptId::kNone, builder.Source()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddReturn(new Value(null_def));
  return true;
}

bool GraphIntrinsifier::Build_GrowableArraySetData(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* growable_array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* data = builder.AddParameter(1, /*with_frame=*/false);
  Zone* zone = flow_graph->zone();

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 1);

  Cids* value_check = Cids::CreateMonomorphic(zone, kArrayCid);
  builder.AddInstruction(new CheckClassInstr(new Value(data), DeoptId::kNone,
                                             *value_check, builder.Source()));

  builder.AddInstruction(new StoreInstanceFieldInstr(
      Slot::GrowableObjectArray_data(), new Value(growable_array),
      new Value(data), kEmitStoreBarrier, builder.Source()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddReturn(new Value(null_def));
  return true;
}

bool GraphIntrinsifier::Build_GrowableArraySetLength(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* growable_array = builder.AddParameter(0, /*with_frame=*/false);
  Definition* length = builder.AddParameter(1, /*with_frame=*/false);

  VerifyParameterIsBoxed(&builder, 0);
  VerifyParameterIsBoxed(&builder, 1);

  builder.AddInstruction(
      new CheckSmiInstr(new Value(length), DeoptId::kNone, builder.Source()));
  builder.AddInstruction(new StoreInstanceFieldInstr(
      Slot::GrowableObjectArray_length(), new Value(growable_array),
      new Value(length), kNoStoreBarrier, builder.Source()));
  Definition* null_def = builder.AddNullDefinition();
  builder.AddReturn(new Value(null_def));
  return true;
}

static Definition* ConvertOrUnboxDoubleParameter(BlockBuilder* builder,
                                                 Definition* value,
                                                 intptr_t index,
                                                 bool is_checked) {
  const auto& function = builder->function();
  if (function.is_unboxed_double_parameter_at(index)) {
    return value;
  } else if (function.is_unboxed_integer_parameter_at(index)) {
    if (compiler::target::kWordSize == 4) {
      // Int64ToDoubleInstr is not implemented in 32-bit platforms
      return nullptr;
    }
    auto to_double = new Int64ToDoubleInstr(new Value(value), DeoptId::kNone);
    return builder->AddDefinition(to_double);
  } else {
    ASSERT(!function.is_unboxed_parameter_at(index));
    return builder->AddUnboxInstr(kUnboxedDouble, value, is_checked);
  }
}

bool GraphIntrinsifier::Build_DoubleFlipSignBit(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {
    return false;
  }
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* receiver = builder.AddParameter(0, /*with_frame=*/false);
  Definition* unboxed_value = ConvertOrUnboxDoubleParameter(
      &builder, receiver, 0, /* is_checked = */ true);
  if (unboxed_value == nullptr) {
    return false;
  }
  Definition* unboxed_result = builder.AddDefinition(new UnaryDoubleOpInstr(
      Token::kNEGATE, new Value(unboxed_value), DeoptId::kNone));
  Definition* result =
      CreateBoxedResultIfNeeded(&builder, unboxed_result, kUnboxedDouble);
  builder.AddReturn(new Value(result));
  return true;
}

static bool BuildInvokeMathCFunction(BlockBuilder* builder,
                                     MethodRecognizer::Kind kind,
                                     FlowGraph* flow_graph,
                                     intptr_t num_parameters = 1) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {
    return false;
  }
  ZoneGrowableArray<Value*>* args =
      new ZoneGrowableArray<Value*>(num_parameters);

  for (intptr_t i = 0; i < num_parameters; i++) {
    Definition* value = builder->AddParameter(i, /*with_frame=*/false);
    Definition* unboxed_value = ConvertOrUnboxDoubleParameter(
        builder, value, i, /* is_checked = */ false);
    if (unboxed_value == nullptr) {
      return false;
    }
    args->Add(new Value(unboxed_value));
  }

  Definition* unboxed_result =
      builder->AddDefinition(new InvokeMathCFunctionInstr(
          args, DeoptId::kNone, kind, builder->Source()));
  Definition* result =
      CreateBoxedResultIfNeeded(builder, unboxed_result, kUnboxedDouble);
  builder->AddReturn(new Value(result));

  return true;
}

bool GraphIntrinsifier::Build_MathSin(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathSin,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathCos(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathCos,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathTan(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathTan,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathAsin(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAsin,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathAcos(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAcos,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathAtan(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAtan,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_MathAtan2(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kMathAtan2,
                                  flow_graph,
                                  /* num_parameters = */ 2);
}

bool GraphIntrinsifier::Build_DoubleMod(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleMod,
                                  flow_graph,
                                  /* num_parameters = */ 2);
}

bool GraphIntrinsifier::Build_DoubleCeil(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleCeil,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_DoubleFloor(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleFloor,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_DoubleTruncate(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
  // TODO(johnmccutchan): On X86 this intrinsic can be written in a different
  // way.
  if (TargetCPUFeatures::double_truncate_round_supported()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleTruncate,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_DoubleRound(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  return BuildInvokeMathCFunction(&builder, MethodRecognizer::kDoubleRound,
                                  flow_graph);
}

bool GraphIntrinsifier::Build_ImplicitGetter(FlowGraph* flow_graph) {
  // This code will only be invoked if our assumptions have been met (see
  // [Intrinsifier::CanIntrinsifyFieldAccessor])
  auto zone = flow_graph->zone();
  const auto& function = flow_graph->function();
  ASSERT(Intrinsifier::CanIntrinsifyFieldAccessor(function));

  auto& field = Field::Handle(zone, function.accessor_field());
  if (CompilerState::Current().should_clone_fields()) {
    field = field.CloneFromOriginal();
  }
  ASSERT(field.is_instance() && !field.is_late() && !field.needs_load_guard());

  const auto& slot = Slot::Get(field, &flow_graph->parsed_function());

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  auto receiver = builder.AddParameter(0, /*with_frame=*/false);
  VerifyParameterIsBoxed(&builder, 0);

  Definition* field_value = builder.AddDefinition(new (zone) LoadFieldInstr(
      new (zone) Value(receiver), slot, builder.Source()));

  // We only support cases where we do not have to create a box (whose
  // allocation could fail).
  ASSERT(function.HasUnboxedReturnValue() ||
         !FlowGraphCompiler::IsUnboxedField(field));

  // We might need to unbox the field value before returning.
  if (function.HasUnboxedReturnValue() &&
      !FlowGraphCompiler::IsUnboxedField(field)) {
    ASSERT(FLAG_precompiled_mode);
    field_value = builder.AddUnboxInstr(
        FlowGraph::ReturnRepresentationOf(flow_graph->function()),
        new Value(field_value), /*is_checked=*/true);
  }

  builder.AddReturn(new (zone) Value(field_value));
  return true;
}

bool GraphIntrinsifier::Build_ImplicitSetter(FlowGraph* flow_graph) {
  // This code will only be invoked if our assumptions have been met (see
  // [Intrinsifier::CanIntrinsifyFieldAccessor])
  auto zone = flow_graph->zone();
  const auto& function = flow_graph->function();
  ASSERT(Intrinsifier::CanIntrinsifyFieldAccessor(function));

  auto& field = Field::Handle(zone, function.accessor_field());
  if (CompilerState::Current().should_clone_fields()) {
    field = field.CloneFromOriginal();
  }
  ASSERT(field.is_instance() && !field.is_final());
  ASSERT(!function.HasUnboxedParameters() ||
         FlowGraphCompiler::IsUnboxedField(field));

  const auto& slot = Slot::Get(field, &flow_graph->parsed_function());

  const auto barrier_mode = FlowGraphCompiler::IsUnboxedField(field)
                                ? kNoStoreBarrier
                                : kEmitStoreBarrier;

  flow_graph->CreateCommonConstants();
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  auto normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  auto receiver = builder.AddParameter(0, /*with_frame=*/false);
  auto value = builder.AddParameter(1, /*with_frame=*/false);
  VerifyParameterIsBoxed(&builder, 0);

  if (!function.HasUnboxedParameters() &&
      FlowGraphCompiler::IsUnboxedField(field)) {
    // We do not support storing to possibly guarded fields in JIT in graph
    // intrinsics.
    ASSERT(FLAG_precompiled_mode);
    value = builder.AddUnboxInstr(
        FlowGraph::UnboxedFieldRepresentationOf(field), new Value(value),
        /*is_checked=*/true);
  }

  builder.AddInstruction(new (zone) StoreInstanceFieldInstr(
      slot, new (zone) Value(receiver), new (zone) Value(value), barrier_mode,
      builder.Source()));

  builder.AddReturn(new (zone) Value(flow_graph->constant_null()));
  return true;
}

}  // namespace compiler
}  // namespace dart

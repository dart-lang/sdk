// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#include "vm/assembler.h"
#include "vm/intrinsifier.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/symbols.h"

#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/parser.h"

namespace dart {

DEFINE_FLAG(bool, intrinsify, true, "Instrinsify when possible");
DECLARE_FLAG(bool, throw_on_javascript_int_overflow);
DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);

bool Intrinsifier::CanIntrinsify(const Function& function) {
  if (!FLAG_intrinsify) return false;
  if (function.IsClosureFunction()) return false;
  // Can occur because of compile-all flag.
  if (function.is_external()) return false;
  return function.is_intrinsic();
}


#if defined(DART_NO_SNAPSHOT)
void Intrinsifier::InitializeState() {
  Isolate* isolate = Isolate::Current();
  Library& lib = Library::Handle(isolate);
  Class& cls = Class::Handle(isolate);
  Function& func = Function::Handle(isolate);
  String& str = String::Handle(isolate);
  Error& error = Error::Handle(isolate);

#define SETUP_FUNCTION(class_name, function_name, destination, fp)             \
  if (strcmp(#class_name, "::") == 0) {                                        \
    str = String::New(#function_name);                                         \
    func = lib.LookupFunctionAllowPrivate(str);                                \
  } else {                                                                     \
    str = String::New(#class_name);                                            \
    cls = lib.LookupClassAllowPrivate(str);                                    \
    ASSERT(!cls.IsNull());                                                     \
    error = cls.EnsureIsFinalized(isolate);                                    \
    if (!error.IsNull()) {                                                     \
      OS::PrintErr("%s\n", error.ToErrorCString());                            \
    }                                                                          \
    ASSERT(error.IsNull());                                                    \
    if (#function_name[0] == '.') {                                            \
      str = String::New(#class_name#function_name);                            \
    } else {                                                                   \
      str = String::New(#function_name);                                       \
    }                                                                          \
    func = cls.LookupFunctionAllowPrivate(str);                                \
  }                                                                            \
  ASSERT(!func.IsNull());                                                      \
  func.set_is_intrinsic(true);

  // Set up all core lib functions that can be intrisified.
  lib = Library::CoreLibrary();
  ASSERT(!lib.IsNull());
  CORE_LIB_INTRINSIC_LIST(SETUP_FUNCTION);
  CORE_INTEGER_LIB_INTRINSIC_LIST(SETUP_FUNCTION);
  GRAPH_CORE_INTRINSICS_LIST(SETUP_FUNCTION);

  // Set up all math lib functions that can be intrisified.
  lib = Library::MathLibrary();
  ASSERT(!lib.IsNull());
  MATH_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

  // Set up all dart:typed_data lib functions that can be intrisified.
  lib = Library::TypedDataLibrary();
  ASSERT(!lib.IsNull());
  TYPED_DATA_LIB_INTRINSIC_LIST(SETUP_FUNCTION);
  GRAPH_TYPED_DATA_INTRINSICS_LIST(SETUP_FUNCTION);

  // Setup all dart:developer lib functions that can be intrinsified.
  lib = Library::DeveloperLibrary();
  ASSERT(!lib.IsNull());
  DEVELOPER_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

#undef SETUP_FUNCTION
}
#endif  // defined(DART_NO_SNAPSHOT).


static void EmitCodeFor(FlowGraphCompiler* compiler,
                        FlowGraph* graph) {
  // The FlowGraph here is constructed by the intrinsics builder methods, and
  // is different from compiler->flow_graph(), the original method's flow graph.
  compiler->assembler()->Comment("Graph intrinsic");
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
      } else {
        ASSERT(instr->locs() != NULL);
        // Calls are not supported in intrinsics code.
        ASSERT(!instr->locs()->always_calls());
        instr->EmitNativeCode(compiler);
      }
    }
  }
}


bool Intrinsifier::GraphIntrinsify(const ParsedFunction& parsed_function,
                                   FlowGraphCompiler* compiler) {
  ZoneGrowableArray<const ICData*>* ic_data_array =
      new ZoneGrowableArray<const ICData*>();
  FlowGraphBuilder builder(parsed_function,
                           *ic_data_array,
                           NULL,  // NULL = not inlining.
                           Isolate::kNoDeoptId);  // No OSR id.

  intptr_t block_id = builder.AllocateBlockId();
  TargetEntryInstr* normal_entry =
      new TargetEntryInstr(block_id,
                           CatchClauseNode::kInvalidTryIndex);
  GraphEntryInstr* graph_entry = new GraphEntryInstr(
      parsed_function, normal_entry, Isolate::kNoDeoptId);  // No OSR id.
  FlowGraph* graph = new FlowGraph(parsed_function, graph_entry, block_id);
  const Function& function = parsed_function.function();
  switch (function.recognized_kind()) {
#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
    case MethodRecognizer::k##enum_name:                                       \
      if (!Build_##enum_name(graph)) return false;                             \
      break;

    GRAPH_INTRINSICS_LIST(EMIT_CASE);
    default:
      return false;
#undef EMIT_CASE
  }

  if (FLAG_print_flow_graph && FlowGraphPrinter::ShouldPrint(function)) {
    ISL_Print("Intrinsic graph before\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }

  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*graph, true);  // Intrinsic mode.
  allocator.AllocateRegisters();

  if (FLAG_print_flow_graph && FlowGraphPrinter::ShouldPrint(function)) {
    ISL_Print("Intrinsic graph after\n");
    FlowGraphPrinter printer(*graph);
    printer.PrintBlocks();
  }
  EmitCodeFor(compiler, graph);
  return true;
}


void Intrinsifier::Intrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler) {
  const Function& function = parsed_function.function();
  if (!CanIntrinsify(function)) {
    return;
  }

  ASSERT(!compiler->flow_graph().IsCompiledForOsr());
  if (GraphIntrinsify(parsed_function, compiler)) {
    return;
  }

#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
    case MethodRecognizer::k##enum_name:                                       \
      compiler->assembler()->Comment("Intrinsic");                             \
      enum_name(compiler->assembler());                                        \
      break;

  switch (function.recognized_kind()) {
    ALL_INTRINSICS_NO_INTEGER_LIB_LIST(EMIT_CASE);
    default:
      break;
  }
  // Integer intrinsics are in the core library, but we don't want to
  // intrinsify when Smi > 32 bits if we are looking for javascript integer
  // overflow.
  if (!(FLAG_throw_on_javascript_int_overflow && (Smi::kBits >= 32))) {
    switch (function.recognized_kind()) {
      CORE_INTEGER_LIB_INTRINSIC_LIST(EMIT_CASE)
      default:
        break;
    }
  }
#undef EMIT_INTRINSIC
}


class BlockBuilder : public ValueObject {
 public:
  BlockBuilder(FlowGraph* flow_graph, TargetEntryInstr* entry)
      : flow_graph_(flow_graph), entry_(entry), current_(entry) { }

  Definition* AddToInitialDefinitions(Definition* def) {
    def->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    flow_graph_->AddToInitialDefinitions(def);
    return def;
  }

  Definition* AddDefinition(Definition* def) {
    def->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    current_ = current_->AppendInstruction(def);
    return def;
  }

  Instruction* AddInstruction(Instruction* instr) {
    current_ = current_->AppendInstruction(instr);
    return instr;
  }

  void AddIntrinsicReturn(Value* value) {
    ReturnInstr* instr = new ReturnInstr(TokenPos(), value);
    AddInstruction(instr);
    entry_->set_last_instruction(instr);
  }

  Definition* AddParameter(intptr_t index) {
    intptr_t adjustment = Intrinsifier::ParameterSlotFromSp();
    return AddToInitialDefinitions(
      new ParameterInstr(adjustment + index,
                         flow_graph_->graph_entry(),
                         SPREG));
  }

  intptr_t TokenPos() {
    return flow_graph_->function().token_pos();
  }

  Definition* AddNullDefinition() {
    return AddDefinition(
        new ConstantInstr(Object::ZoneHandle(Object::null())));
  }

 private:
  FlowGraph* flow_graph_;
  BlockEntryInstr* entry_;
  Instruction* current_;
};


static void PrepareIndexedOp(BlockBuilder* builder,
                             Definition* array,
                             Definition* index,
                             intptr_t length_offset) {
  intptr_t token_pos = builder->TokenPos();
  builder->AddInstruction(
      new CheckSmiInstr(new Value(index),
                        Isolate::kNoDeoptId,
                        token_pos));

  Definition* length = builder->AddDefinition(
      new LoadFieldInstr(new Value(array),
                         length_offset,
                         Type::ZoneHandle(Type::SmiType()),
                         Scanner::kNoSourcePos));
  builder->AddInstruction(
      new CheckArrayBoundInstr(new Value(length),
                               new Value(index),
                               Isolate::kNoDeoptId));
}


bool Intrinsifier::Build_ObjectArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* array = builder.AddParameter(2);

  PrepareIndexedOp(&builder, array, index, Array::length_offset());

  Definition* result = builder.AddDefinition(
      new LoadIndexedInstr(new Value(array),
                           new Value(index),
                           Instance::ElementSizeFor(kArrayCid),  // index scale
                           kArrayCid,
                           Isolate::kNoDeoptId,
                           builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}


bool Intrinsifier::Build_ImmutableArrayGetIndexed(FlowGraph* flow_graph) {
  return Build_ObjectArrayGetIndexed(flow_graph);
}


bool Intrinsifier::Build_Uint8ArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* array = builder.AddParameter(2);

  PrepareIndexedOp(&builder, array, index, TypedData::length_offset());

  Definition* result = builder.AddDefinition(
      new LoadIndexedInstr(new Value(array),
                           new Value(index),
                           1,  // index scale
                           kTypedDataUint8ArrayCid,
                           Isolate::kNoDeoptId,
                           builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}


bool Intrinsifier::Build_ExternalUint8ArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* array = builder.AddParameter(2);

  PrepareIndexedOp(&builder, array, index, ExternalTypedData::length_offset());

  Definition* elements = builder.AddDefinition(
      new LoadUntaggedInstr(new Value(array),
                            ExternalTypedData::data_offset()));
  Definition* result = builder.AddDefinition(
      new LoadIndexedInstr(new Value(elements),
                           new Value(index),
                           1,  // index scale
                           kExternalTypedDataUint8ArrayCid,
                           Isolate::kNoDeoptId,
                           builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}


bool Intrinsifier::Build_Uint8ArraySetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  PrepareIndexedOp(&builder, array, index, TypedData::length_offset());

  builder.AddInstruction(
      new CheckSmiInstr(new Value(value),
                        Isolate::kNoDeoptId,
                        builder.TokenPos()));

  builder.AddInstruction(
      new StoreIndexedInstr(new Value(array),
                            new Value(index),
                            new Value(value),
                            kNoStoreBarrier,
                            1,  // index scale
                            kTypedDataUint8ArrayCid,
                            Isolate::kNoDeoptId,
                            builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}


bool Intrinsifier::Build_ExternalUint8ArraySetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  PrepareIndexedOp(&builder, array, index, ExternalTypedData::length_offset());

  builder.AddInstruction(
      new CheckSmiInstr(new Value(value),
                        Isolate::kNoDeoptId,
                        builder.TokenPos()));
  Definition* elements = builder.AddDefinition(
      new LoadUntaggedInstr(new Value(array),
                            ExternalTypedData::data_offset()));
  builder.AddInstruction(
      new StoreIndexedInstr(new Value(elements),
                            new Value(index),
                            new Value(value),
                            kNoStoreBarrier,
                            1,  // index scale
                            kExternalTypedDataUint8ArrayCid,
                            Isolate::kNoDeoptId,
                            builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}


bool Intrinsifier::Build_Float64ArraySetIndexed(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  PrepareIndexedOp(&builder, array, index, TypedData::length_offset());

  const ICData& value_check = ICData::ZoneHandle(ICData::New(
      flow_graph->function(),
      String::Handle(flow_graph->function().name()),
      Object::empty_array(),  // Dummy args. descr.
      Isolate::kNoDeoptId,
      1));
  value_check.AddReceiverCheck(kDoubleCid, flow_graph->function());
  builder.AddInstruction(
      new CheckClassInstr(new Value(value),
                          Isolate::kNoDeoptId,
                          value_check,
                          builder.TokenPos()));
  Definition* double_value = builder.AddDefinition(
      UnboxInstr::Create(kUnboxedDouble,
                         new Value(value),
                         Isolate::kNoDeoptId));
  // Manually adjust reaching type because there is no type propagation
  // when building intrinsics.
  double_value->AsUnbox()->value()->SetReachingType(
      ZoneCompileType::Wrap(CompileType::FromCid(kDoubleCid)));

  builder.AddInstruction(
      new StoreIndexedInstr(new Value(array),
                            new Value(index),
                            new Value(double_value),
                            kNoStoreBarrier,
                            8,  // index scale
                            kTypedDataFloat64ArrayCid,
                            Isolate::kNoDeoptId,
                            builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}


bool Intrinsifier::Build_Float64ArrayGetIndexed(FlowGraph* flow_graph) {
  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* array = builder.AddParameter(2);

  PrepareIndexedOp(&builder, array, index, TypedData::length_offset());

  Definition* unboxed_value = builder.AddDefinition(
      new LoadIndexedInstr(new Value(array),
                           new Value(index),
                           8,  // index scale
                           kTypedDataFloat64ArrayCid,
                           Isolate::kNoDeoptId,
                           builder.TokenPos()));
  Definition* result = builder.AddDefinition(
      BoxInstr::Create(kUnboxedDouble, new Value(unboxed_value)));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}


static bool BuildLoadField(FlowGraph* flow_graph, intptr_t offset) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(1);

  Definition* length = builder.AddDefinition(
      new LoadFieldInstr(new Value(array),
                         offset,
                         Type::ZoneHandle(),
                         builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(length));
  return true;
}


bool Intrinsifier::Build_ObjectArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Array::length_offset());
}


bool Intrinsifier::Build_ImmutableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, Array::length_offset());
}


bool Intrinsifier::Build_GrowableArrayLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, GrowableObjectArray::length_offset());
}


bool Intrinsifier::Build_StringBaseLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, String::length_offset());
}


bool Intrinsifier::Build_TypedDataLength(FlowGraph* flow_graph) {
  return BuildLoadField(flow_graph, TypedData::length_offset());
}


bool Intrinsifier::Build_GrowableArrayCapacity(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* array = builder.AddParameter(1);

  Definition* backing_store = builder.AddDefinition(
      new LoadFieldInstr(new Value(array),
                         GrowableObjectArray::data_offset(),
                         Type::ZoneHandle(),
                         builder.TokenPos()));
  Definition* capacity = builder.AddDefinition(
      new LoadFieldInstr(new Value(backing_store),
                         Array::length_offset(),
                         Type::ZoneHandle(),
                         builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(capacity));
  return true;
}


bool Intrinsifier::Build_GrowableArrayGetIndexed(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* index = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);

  PrepareIndexedOp(
      &builder, growable_array, index, GrowableObjectArray::length_offset());

  Definition* backing_store = builder.AddDefinition(
      new LoadFieldInstr(new Value(growable_array),
                         GrowableObjectArray::data_offset(),
                         Type::ZoneHandle(),
                         builder.TokenPos()));
  Definition* result = builder.AddDefinition(
      new LoadIndexedInstr(new Value(backing_store),
                           new Value(index),
                           Instance::ElementSizeFor(kArrayCid),  // index scale
                           kArrayCid,
                           Isolate::kNoDeoptId,
                           builder.TokenPos()));
  builder.AddIntrinsicReturn(new Value(result));
  return true;
}


bool Intrinsifier::Build_GrowableArraySetIndexed(FlowGraph* flow_graph) {
  if (Isolate::Current()->flags().type_checks()) {
    return false;
  }

  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* value = builder.AddParameter(1);
  Definition* index = builder.AddParameter(2);
  Definition* array = builder.AddParameter(3);

  PrepareIndexedOp(
      &builder, array, index, GrowableObjectArray::length_offset());

  Definition* backing_store = builder.AddDefinition(
      new LoadFieldInstr(new Value(array),
                         GrowableObjectArray::data_offset(),
                         Type::ZoneHandle(),
                         builder.TokenPos()));

  builder.AddInstruction(
      new StoreIndexedInstr(new Value(backing_store),
                            new Value(index),
                            new Value(value),
                            kEmitStoreBarrier,
                            Instance::ElementSizeFor(kArrayCid),  // index scale
                            kArrayCid,
                            Isolate::kNoDeoptId,
                            builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}


bool Intrinsifier::Build_GrowableArraySetData(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* data = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);

  const ICData& value_check = ICData::ZoneHandle(ICData::New(
      flow_graph->function(),
      String::Handle(flow_graph->function().name()),
      Object::empty_array(),  // Dummy args. descr.
      Isolate::kNoDeoptId,
      1));
  value_check.AddReceiverCheck(kArrayCid, flow_graph->function());
  builder.AddInstruction(
      new CheckClassInstr(new Value(data),
                          Isolate::kNoDeoptId,
                          value_check,
                          builder.TokenPos()));

  builder.AddInstruction(
      new StoreInstanceFieldInstr(GrowableObjectArray::data_offset(),
                                  new Value(growable_array),
                                  new Value(data),
                                  kEmitStoreBarrier,
                                  builder.TokenPos()));
  // Return null.
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}


bool Intrinsifier::Build_GrowableArraySetLength(FlowGraph* flow_graph) {
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  TargetEntryInstr* normal_entry = graph_entry->normal_entry();
  BlockBuilder builder(flow_graph, normal_entry);

  Definition* length = builder.AddParameter(1);
  Definition* growable_array = builder.AddParameter(2);

  builder.AddInstruction(
      new CheckSmiInstr(new Value(length),
                        Isolate::kNoDeoptId,
                        builder.TokenPos()));
  builder.AddInstruction(
      new StoreInstanceFieldInstr(GrowableObjectArray::length_offset(),
                                  new Value(growable_array),
                                  new Value(length),
                                  kNoStoreBarrier,
                                  builder.TokenPos()));
  Definition* null_def = builder.AddNullDefinition();
  builder.AddIntrinsicReturn(new Value(null_def));
  return true;
}

}  // namespace dart

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <vector>

#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(DART_PRECOMPILER)

// This test asserts that we are inlining accesses to typed data interfaces
// (e.g. Uint8List) if there are no instantiated 3rd party classes.
ISOLATE_UNIT_TEST_CASE(IRTest_TypedDataAOT_Inlining) {
  const char* kScript =
      R"(
      import 'dart:typed_data';

      foo(Uint8List list, int from) {
        if (from >= list.length) {
          return list[from];
        }
      }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  CheckNullInstr* check_null = nullptr;
  LoadFieldInstr* load_field = nullptr;
  GenericCheckBoundInstr* bounds_check = nullptr;
  Instruction* load_untagged = nullptr;
  LoadIndexedInstr* load_indexed = nullptr;

  ILMatcher cursor(flow_graph, entry);
  if (Isolate::Current()->null_safety()) {
    RELEASE_ASSERT(cursor.TryMatch({
        kMoveGlob,
        {kMatchAndMoveLoadField, &load_field},
        kMoveGlob,
        kMatchAndMoveBranchTrue,
        kMoveGlob,
        {kMatchAndMoveGenericCheckBound, &bounds_check},
        {kMatchAndMoveLoadUntagged, &load_untagged},
        kMoveParallelMoves,
        {kMatchAndMoveLoadIndexed, &load_indexed},
        kMoveGlob,
        kMatchReturn,
    }));
  } else {
    RELEASE_ASSERT(cursor.TryMatch({
        kMoveGlob,
        {kMatchAndMoveCheckNull, &check_null},
        {kMatchAndMoveLoadField, &load_field},
        kMoveGlob,
        kMatchAndMoveBranchTrue,
        kMoveGlob,
        {kMatchAndMoveGenericCheckBound, &bounds_check},
        {kMatchAndMoveLoadUntagged, &load_untagged},
        kMoveParallelMoves,
        {kMatchAndMoveLoadIndexed, &load_indexed},
        kMoveGlob,
        kMatchReturn,
    }));
  }

  EXPECT(load_field->InputAt(0)->definition()->IsParameter());
  EXPECT(bounds_check->length()
             ->definition()
             ->OriginalDefinitionIgnoreBoxingAndConstraints() == load_field);
  EXPECT(load_untagged->InputAt(0)->definition()->IsParameter());
  EXPECT(load_indexed->InputAt(0)->definition() == load_untagged);
}

// This test asserts that we are not inlining accesses to typed data interfaces
// (e.g. Uint8List) if there are instantiated 3rd party classes (e.g.
// UnmodifiableUint8ListView).
ISOLATE_UNIT_TEST_CASE(IRTest_TypedDataAOT_NotInlining) {
  const char* kScript =
      R"(
      import 'dart:typed_data';

      createThirdPartyUint8List() => UnmodifiableUint8ListView(Uint8List(10));

      void foo(Uint8List list, int from) {
        if (from >= list.length) {
          list[from];
        }
      }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  // Firstly we ensure a non internal/external/view Uint8List is allocated.
  Invoke(root_library, "createThirdPartyUint8List");

  // Now we ensure that we don't perform the inlining of the `list[from]`
  // access.
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  InstanceCallInstr* length_call = nullptr;
  PushArgumentInstr* pusharg1 = nullptr;
  PushArgumentInstr* pusharg2 = nullptr;
  InstanceCallInstr* index_get_call = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveInstanceCall, &length_call},
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      {kMatchAndMovePushArgument, &pusharg1},
      {kMatchAndMovePushArgument, &pusharg2},
      {kMatchAndMoveInstanceCall, &index_get_call},
      kMoveGlob,
      kMatchReturn,
  }));

  EXPECT(length_call->Selector() == Symbols::GetLength().raw());
  EXPECT(pusharg1->InputAt(0)->definition()->IsParameter());
  EXPECT(pusharg2->InputAt(0)->definition()->IsParameter());
  EXPECT(index_get_call->Selector() == Symbols::IndexToken().raw());
}

// This test asserts that we are inlining get:length, [] and []= for all typed
// data interfaces.  It also ensures that the asserted IR actually works by
// exercising it.
ISOLATE_UNIT_TEST_CASE(IRTest_TypedDataAOT_FunctionalGetSet) {
  const char* kTemplate =
      R"(
      import 'dart:typed_data';

      void reverse%s(%s list) {
        final length = list.length;
        final halfLength = length ~/ 2;
        for (int i = 0; i < halfLength; ++i) {
          final tmp = list[length-i-1];
          list[length-i-1] = list[i];
          list[i] = tmp;
        }
      }
      )";

  char script_buffer[1024];
  char uri_buffer[1024];
  char function_name[1024];
  auto& lib = Library::Handle();
  auto& function = Function::Handle();

  auto check_il = [&](const char* name) {
    // Fill in the template with the [name].
    Utils::SNPrint(script_buffer, sizeof(script_buffer), kTemplate, name, name);
    Utils::SNPrint(uri_buffer, sizeof(uri_buffer), "file:///reverse-%s.dart",
                   name);
    Utils::SNPrint(function_name, sizeof(function_name), "reverse%s", name);

    // Create a new library, load the function and compile it using our AOT
    // pipeline.
    lib = LoadTestScript(script_buffer, nullptr, uri_buffer);
    function = GetFunction(lib, function_name);
    TestPipeline pipeline(function, CompilerPass::kAOT);
    FlowGraph* flow_graph = pipeline.RunPasses({});
    auto entry = flow_graph->graph_entry()->normal_entry();

    // Ensure the IL matches what we expect.
    ILMatcher cursor(flow_graph, entry);
    if (Isolate::Current()->null_safety()) {
      EXPECT(cursor.TryMatch({
          // Before loop
          kMoveGlob,
          kMatchAndMoveLoadField,
          kMoveGlob,
          kMatchAndMoveBranchTrue,

          // Loop
          kMoveGlob,
          // Load 1
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveLoadIndexed,
          kMoveGlob,
          // Load 2
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveLoadIndexed,
          kMoveGlob,
          // Store 1
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMoveParallelMoves,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,
          kMoveGlob,
          // Store 2
          kMoveParallelMoves,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,
          kMoveGlob,

          // Exit the loop.
          kMatchAndMoveBranchFalse,
          kMoveGlob,
          kMatchReturn,
      }));
    } else {
      EXPECT(cursor.TryMatch({
          // Before loop
          kMoveGlob,
          kMatchAndMoveCheckNull,
          kMatchAndMoveLoadField,
          kMoveGlob,
          kMatchAndMoveBranchTrue,

          // Loop
          kMoveGlob,
          // Load 1
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveLoadIndexed,
          kMoveGlob,
          // Load 2
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveLoadIndexed,
          kMoveGlob,
          // Store 1
          kMatchAndMoveGenericCheckBound,
          kMoveGlob,
          kMoveParallelMoves,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,
          kMoveGlob,
          // Store 2
          kMoveParallelMoves,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,
          kMoveGlob,

          // Exit the loop.
          kMatchAndMoveBranchFalse,
          kMoveGlob,
          kMatchReturn,
      }));
    }
  };

  check_il("Uint8List");
  check_il("Int8List");
  check_il("Uint8ClampedList");
  check_il("Int16List");
  check_il("Uint16List");
  check_il("Int32List");
  check_il("Uint32List");
  check_il("Int64List");
  check_il("Uint64List");
  check_il("Float32List");
  check_il("Float64List");
}

// This test asserts that we get errors if receiver, index or value are null.
ISOLATE_UNIT_TEST_CASE(IRTest_TypedDataAOT_FunctionalIndexError) {
  const char* kTemplate =
      R"(
      import 'dart:typed_data';
      void set%s(%s list, int index, %s value) {
        list[index] = value;
      }
      )";

  char script_buffer[1024];
  char uri_buffer[1024];
  char function_name[1024];
  auto& lib = Library::Handle();
  auto& function = Function::Handle();
  auto& arguments = Array::Handle();
  auto& result = Object::Handle();

  const intptr_t kIndex = 1;
  const intptr_t kLastStage = 3;

  auto run_test = [&](const char* name, const char* type,
                      const TypedDataBase& data, const Object& value,
                      int stage) {
    // Fill in the template with the [name].
    Utils::SNPrint(script_buffer, sizeof(script_buffer), kTemplate, name, name,
                   type);
    Utils::SNPrint(uri_buffer, sizeof(uri_buffer), "file:///set-%s.dart", name);
    Utils::SNPrint(function_name, sizeof(function_name), "set%s", name);

    // Create a new library, load the function and compile it using our AOT
    // pipeline.
    lib = LoadTestScript(script_buffer, nullptr, uri_buffer);
    function = GetFunction(lib, function_name);
    TestPipeline pipeline(function, CompilerPass::kAOT);
    FlowGraph* flow_graph = pipeline.RunPasses({});
    auto entry = flow_graph->graph_entry()->normal_entry();

    // Ensure the IL matches what we expect.
    ILMatcher cursor(flow_graph, entry, /*trace=*/true);
    if (Isolate::Current()->null_safety()) {
      EXPECT(cursor.TryMatch({
          // LoadField length
          kMoveGlob,
          kMatchAndMoveLoadField,

          // Bounds check
          kMoveGlob,
          kMatchAndMoveGenericCheckBound,

          // Store value.
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveOptionalUnbox,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,

          // Return
          kMoveGlob,
          kMatchReturn,
      }));
    } else {
      EXPECT(cursor.TryMatch({
          // Receiver null check
          kMoveGlob,
          kMatchAndMoveCheckNull,

          // Index null check
          kMoveGlob,
          kMatchAndMoveCheckNull,

          // Value null check
          kMoveGlob,
          kMatchAndMoveCheckNull,

          // LoadField length
          kMoveGlob,
          kMatchAndMoveLoadField,

          // Bounds check
          kMoveGlob,
          kMatchAndMoveGenericCheckBound,

          // Store value.
          kMoveGlob,
          kMatchAndMoveLoadUntagged,
          kMoveParallelMoves,
          kMatchAndMoveOptionalUnbox,
          kMoveParallelMoves,
          kMatchAndMoveStoreIndexed,

          // Return
          kMoveGlob,
          kMatchReturn,
      }));
    }

    // Compile the graph and attach the code.
    pipeline.CompileGraphAndAttachFunction();

    arguments = Array::New(3);
    arguments.SetAt(0, stage == 0 ? Object::null_object() : data);
    arguments.SetAt(
        1, stage == 1 ? Object::null_object() : Smi::Handle(Smi::New(kIndex)));
    arguments.SetAt(2, stage == 2 ? Object::null_object() : value);
    result = DartEntry::InvokeFunction(function, arguments);

    // Ensure we didn't deoptimize to unoptimized code.
    EXPECT(function.unoptimized_code() == Code::null());

    if (stage == kLastStage) {
      // The last stage must be successful
      EXPECT(result.IsNull());
    } else {
      // Ensure we get an error.
      EXPECT(result.IsUnhandledException());
      result = UnhandledException::Cast(result).exception();
    }
  };

  const auto& uint8_list =
      TypedData::Handle(TypedData::New(kTypedDataUint8ArrayCid, 16));
  const auto& uint8c_list =
      TypedData::Handle(TypedData::New(kTypedDataUint8ClampedArrayCid, 16));
  const auto& int16_list =
      TypedData::Handle(TypedData::New(kTypedDataInt16ArrayCid, 16));
  const auto& uint16_list =
      TypedData::Handle(TypedData::New(kTypedDataUint16ArrayCid, 16));
  const auto& int32_list =
      TypedData::Handle(TypedData::New(kTypedDataInt32ArrayCid, 16));
  const auto& uint32_list =
      TypedData::Handle(TypedData::New(kTypedDataUint32ArrayCid, 16));
  const auto& int64_list =
      TypedData::Handle(TypedData::New(kTypedDataInt64ArrayCid, 16));
  const auto& uint64_list =
      TypedData::Handle(TypedData::New(kTypedDataUint64ArrayCid, 16));
  const auto& float32_list =
      TypedData::Handle(TypedData::New(kTypedDataFloat32ArrayCid, 16));
  const auto& float64_list =
      TypedData::Handle(TypedData::New(kTypedDataFloat64ArrayCid, 16));
  const auto& int8_list =
      TypedData::Handle(TypedData::New(kTypedDataInt8ArrayCid, 16));
  const auto& int_value = Integer::Handle(Integer::New(42));
  const auto& float_value = Double::Handle(Double::New(4.2));
  // With null safety nulls cannot be passed as non-nullable arguments, so
  // skip all error stages and only run the last stage.
  const intptr_t first_stage =
      Isolate::Current()->null_safety() ? kLastStage : 0;
  for (intptr_t stage = first_stage; stage <= kLastStage; ++stage) {
    run_test("Uint8List", "int", int8_list, int_value, stage);
    run_test("Int8List", "int", uint8_list, int_value, stage);
    run_test("Uint8ClampedList", "int", uint8c_list, int_value, stage);
    run_test("Int16List", "int", int16_list, int_value, stage);
    run_test("Uint16List", "int", uint16_list, int_value, stage);
    run_test("Int32List", "int", int32_list, int_value, stage);
    run_test("Uint32List", "int", uint32_list, int_value, stage);
    run_test("Int64List", "int", int64_list, int_value, stage);
    run_test("Uint64List", "int", uint64_list, int_value, stage);
    run_test("Float32List", "double", float32_list, float_value, stage);
    run_test("Float64List", "double", float64_list, float_value, stage);
  }
}

ISOLATE_UNIT_TEST_CASE(IRTest_TypedDataAOT_Regress43534) {
  const char* kScript =
      R"(
      import 'dart:typed_data';

      @pragma('vm:never-inline')
      void callWith<T>(void Function(T arg) fun, T arg) {
        fun(arg);
      }

      void test() {
        callWith<Uint8List>((Uint8List list) {
          if (list[0] != 0) throw 'a';
        }, Uint8List(10));
      }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "test");
  const auto& test_function =
      Function::Handle(GetFunction(root_library, "test"));
  const auto& closures = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->closure_functions());
  auto& function = Function::Handle();
  for (intptr_t i = closures.Length() - 1; 0 <= i; ++i) {
    function ^= closures.At(i);
    if (function.parent_function() == test_function.raw()) {
      break;
    }
    function = Function::null();
  }
  RELEASE_ASSERT(!function.IsNull());
  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);
  ILMatcher cursor(flow_graph, entry, /*trace=*/true);
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveLoadField,
          kMatchAndMoveGenericCheckBound,
          kMatchAndMoveLoadUntagged,
          kMatchAndMoveLoadIndexed,
          kMatchAndMoveBranchFalse,
          kMoveGlob,
          kMatchReturn,
      },
      kMoveGlob));
}

#endif  // defined(DART_PRECOMPILER)

}  // namespace dart

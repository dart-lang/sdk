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

  EXPECT(load_field->InputAt(0)->definition()->IsParameter());
  EXPECT(bounds_check->InputAt(0)->definition() == load_field);
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

  std::initializer_list<MatchCode> expected_il = {
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
  };

  char script_buffer[1024];
  char uri_buffer[1024];
  char function_name[1024];
  auto& lib = Library::Handle();
  auto& function = Function::Handle();
  auto& view = TypedDataView::Handle();
  auto& arguments = Array::Handle();
  auto& result = Object::Handle();

  auto run_reverse_list = [&](const char* name, const TypedDataBase& data) {
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
    EXPECT(cursor.TryMatch(expected_il));

    // Compile the graph and attach the code.
    pipeline.CompileGraphAndAttachFunction();

    // Class ids are numbered from internal/view/external.
    const classid_t view_cid = data.GetClassId() + 1;
    ASSERT(RawObject::IsTypedDataViewClassId(view_cid));

    // First and last element are not in the view, i.e.
    //    view[0:view.length()-1] = data[1:data.length()-2]
    const intptr_t length_in_bytes =
        (data.LengthInBytes() - 2 * data.ElementSizeInBytes());
    view = TypedDataView::New(view_cid, data, data.ElementSizeInBytes(),
                              length_in_bytes / data.ElementSizeInBytes());
    ASSERT(data.ElementType() == view.ElementType());

    arguments = Array::New(1);
    arguments.SetAt(0, view);
    result = DartEntry::InvokeFunction(function, arguments);
    EXPECT(result.IsNull());

    // Ensure we didn't deoptimize to unoptimized code.
    EXPECT(function.unoptimized_code() == Code::null());
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
  for (intptr_t i = 0; i < 16; ++i) {
    int8_list.SetInt8(i, i);
    uint8_list.SetUint8(i, i);
    uint8c_list.SetUint8(i, i);
    int16_list.SetInt16(2 * i, i);
    uint16_list.SetUint16(2 * i, i);
    int32_list.SetInt32(4 * i, i);
    uint32_list.SetUint32(4 * i, i);
    int64_list.SetInt64(8 * i, i);
    uint64_list.SetUint64(8 * i, i);
    float32_list.SetFloat32(4 * i, i + 0.5);
    float64_list.SetFloat64(8 * i, i + 0.7);
  }
  run_reverse_list("Uint8List", int8_list);
  run_reverse_list("Int8List", uint8_list);
  run_reverse_list("Uint8ClampedList", uint8c_list);
  run_reverse_list("Int16List", int16_list);
  run_reverse_list("Uint16List", uint16_list);
  run_reverse_list("Int32List", int32_list);
  run_reverse_list("Uint32List", uint32_list);
  run_reverse_list("Int64List", int64_list);
  run_reverse_list("Uint64List", uint64_list);
  run_reverse_list("Float32List", float32_list);
  run_reverse_list("Float64List", float64_list);
  for (intptr_t i = 0; i < 16; ++i) {
    // Only the values in the view are reversed.
    const bool in_view = i >= 1 && i < 15;

    const int64_t expected_value = in_view ? (16 - i - 1) : i;
    const uint64_t expected_uvalue = in_view ? (16 - i - 1) : i;
    const float expected_fvalue = (in_view ? (16 - i - 1) : i) + 0.5;
    const double expected_dvalue = (in_view ? (16 - i - 1) : i) + 0.7;

    EXPECT(int8_list.GetInt8(i) == expected_value);
    EXPECT(uint8_list.GetUint8(i) == expected_uvalue);
    EXPECT(uint8c_list.GetUint8(i) == expected_uvalue);
    EXPECT(int16_list.GetInt16(2 * i) == expected_value);
    EXPECT(uint16_list.GetUint16(2 * i) == expected_uvalue);
    EXPECT(int32_list.GetInt32(4 * i) == expected_value);
    EXPECT(uint32_list.GetUint32(4 * i) == expected_uvalue);
    EXPECT(int64_list.GetInt64(8 * i) == expected_value);
    EXPECT(uint64_list.GetUint64(8 * i) == expected_uvalue);
    EXPECT(float32_list.GetFloat32(4 * i) == expected_fvalue);
    EXPECT(float64_list.GetFloat64(8 * i) == expected_dvalue);
  }
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

  std::initializer_list<MatchCode> expected_il = {
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
  };

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
    EXPECT(cursor.TryMatch(expected_il));

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
  for (intptr_t stage = 0; stage <= kLastStage; ++stage) {
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

#endif  // defined(DART_PRECOMPILER)

}  // namespace dart

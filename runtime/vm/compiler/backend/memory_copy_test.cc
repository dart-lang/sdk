// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <vector>

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

extern const char* pointer_prefix;

static constexpr intptr_t kMemoryTestLength = 1024;
static constexpr uint8_t kUnInitialized = 0xFE;

static classid_t TypedDataCidForElementSize(intptr_t elem_size) {
  switch (elem_size) {
    case 1:
      return kTypedDataUint8ArrayCid;
    case 2:
      return kTypedDataUint16ArrayCid;
    case 4:
      return kTypedDataUint32ArrayCid;
    case 8:
      return kTypedDataUint64ArrayCid;
    case 16:
      return kTypedDataInt32x4ArrayCid;
    default:
      break;
  }
  UNIMPLEMENTED();
}

static inline intptr_t ExpectedValue(intptr_t i) {
  return 1 + i % 100;
}

static void InitializeMemory(uint8_t* input, uint8_t* output) {
  const bool use_same_buffer = input == output;
  for (intptr_t i = 0; i < kMemoryTestLength; i++) {
    input[i] = ExpectedValue(i);  // Initialized.
    if (!use_same_buffer) {
      output[i] = kUnInitialized;  // Empty.
    }
  }
}

static bool CheckMemory(Expect expect,
                        const uint8_t* input,
                        const uint8_t* output,
                        intptr_t dest_start,
                        intptr_t src_start,
                        intptr_t length,
                        intptr_t elem_size) {
  ASSERT(Utils::IsPowerOfTwo(kMemoryTestLength));
  expect.LessThan<intptr_t>(0, elem_size);
  if (!Utils::IsPowerOfTwo(elem_size)) {
    expect.Fail("Expected %" Pd " to be a power of two", elem_size);
  }
  expect.LessEqual<intptr_t>(0, length);
  expect.LessEqual<intptr_t>(0, dest_start);
  expect.LessEqual<intptr_t>(dest_start + length,
                             kMemoryTestLength / elem_size);
  expect.LessEqual<intptr_t>(0, src_start);
  expect.LessEqual<intptr_t>(src_start + length, kMemoryTestLength / elem_size);
  const bool use_same_buffer = input == output;
  const intptr_t dest_start_in_bytes = dest_start * elem_size;
  const intptr_t dest_end_in_bytes = dest_start_in_bytes + length * elem_size;
  const intptr_t index_diff = dest_start_in_bytes - src_start * elem_size;
  for (intptr_t i = 0; i < kMemoryTestLength; i++) {
    if (!use_same_buffer) {
      const intptr_t expected = ExpectedValue(i);
      const intptr_t got = input[i];
      if (expected != got) {
        expect.Fail("Unexpected change to input buffer at index %" Pd
                    ", expected %" Pd ", got %" Pd "",
                    i, expected, got);
      }
    }
    const intptr_t unchanged =
        use_same_buffer ? ExpectedValue(i) : kUnInitialized;
    const intptr_t got = output[i];
    if (dest_start_in_bytes <= i && i < dest_end_in_bytes) {
      // Copied.
      const intptr_t expected = ExpectedValue(i - index_diff);
      if (expected != got) {
        if (got == unchanged) {
          expect.Fail("No change to output buffer at index %" Pd
                      ", expected %" Pd ", got %" Pd "",
                      i, expected, got);
        } else {
          expect.Fail("Incorrect change to output buffer at index %" Pd
                      ", expected %" Pd ", got %" Pd "",
                      i, expected, got);
        }
      }
    } else {
      // Untouched.
      if (got != unchanged) {
        expect.Fail("Unexpected change to input buffer at index %" Pd
                    ", expected %" Pd ", got %" Pd "",
                    i, unchanged, got);
      }
    }
  }
  return expect.failed();
}

#define CHECK_DEFAULT_MEMORY(in, out)                                          \
  do {                                                                         \
    if (CheckMemory(dart::Expect(__FILE__, __LINE__), in, out, 0, 0, 0, 1)) {  \
      return;                                                                  \
    }                                                                          \
  } while (false)
#define CHECK_MEMORY(in, out, start, skip, len, size)                          \
  do {                                                                         \
    if (CheckMemory(dart::Expect(__FILE__, __LINE__), in, out, start, skip,    \
                    len, size)) {                                              \
      return;                                                                  \
    }                                                                          \
  } while (false)

static void RunMemoryCopyInstrTest(intptr_t src_start,
                                   intptr_t dest_start,
                                   intptr_t length,
                                   intptr_t elem_size,
                                   bool unboxed_inputs,
                                   bool use_same_buffer) {
  OS::Print("==================================================\n");
  OS::Print("RunMemoryCopyInstrTest src_start %" Pd " dest_start %" Pd
            " length "
            "%" Pd "%s elem_size %" Pd "\n",
            src_start, dest_start, length, unboxed_inputs ? " (unboxed)" : "",
            elem_size);
  OS::Print("==================================================\n");
  classid_t cid = TypedDataCidForElementSize(elem_size);

  uint8_t* ptr = reinterpret_cast<uint8_t*>(malloc(kMemoryTestLength));
  uint8_t* ptr2 = use_same_buffer
                      ? ptr
                      : reinterpret_cast<uint8_t*>(malloc(kMemoryTestLength));
  InitializeMemory(ptr, ptr2);

  OS::Print("&ptr %p &ptr2 %p\n", ptr, ptr2);

  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
    import 'dart:ffi';

    void copyConst() {
      final pointer = Pointer<Uint8>.fromAddress(%s%p);
      final pointer2 = Pointer<Uint8>.fromAddress(%s%p);
      noop();
    }

    void callNonConstCopy() {
      final pointer = Pointer<Uint8>.fromAddress(%s%p);
      final pointer2 = Pointer<Uint8>.fromAddress(%s%p);
      final src_start = %)" Pd R"(;
      final dest_start = %)" Pd R"(;
      final length = %)" Pd R"(;
      copyNonConst(
          pointer, pointer2, src_start, dest_start, length);
    }

    void noop() {}

    void copyNonConst(Pointer<Uint8> ptr1,
                      Pointer<Uint8> ptr2,
                      int src_start,
                      int dest_start,
                      int length) {}
  )", pointer_prefix, ptr, pointer_prefix, ptr2,
      pointer_prefix, ptr, pointer_prefix, ptr2,
      src_start, dest_start, length), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));

  // Test the MemoryCopy instruction when the inputs are constants.
  {
    Invoke(root_library, "copyConst");
    // Running this should be a no-op on the memory.
    CHECK_DEFAULT_MEMORY(ptr, ptr2);

    const auto& const_copy =
        Function::Handle(GetFunction(root_library, "copyConst"));

    TestPipeline pipeline(const_copy, CompilerPass::kJIT);
    FlowGraph* flow_graph = pipeline.RunPasses({
        CompilerPass::kComputeSSA,
    });

    StaticCallInstr* pointer = nullptr;
    StaticCallInstr* pointer2 = nullptr;
    StaticCallInstr* another_function_call = nullptr;
    {
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

      EXPECT(cursor.TryMatch({
          kMoveGlob,
          {kMatchAndMoveStaticCall, &pointer},
          {kMatchAndMoveStaticCall, &pointer2},
          {kMatchAndMoveStaticCall, &another_function_call},
      }));
    }

    Zone* const zone = Thread::Current()->zone();
    auto const rep = unboxed_inputs ? kUnboxedIntPtr : kTagged;

    auto* const src_start_constant_instr = flow_graph->GetConstant(
        Integer::ZoneHandle(zone, Integer::New(src_start, Heap::kOld)), rep);

    auto* const dest_start_constant_instr = flow_graph->GetConstant(
        Integer::ZoneHandle(zone, Integer::New(dest_start, Heap::kOld)), rep);

    auto* const length_constant_instr = flow_graph->GetConstant(
        Integer::ZoneHandle(zone, Integer::New(length, Heap::kOld)), rep);

    auto* const memory_copy_instr = new (zone) MemoryCopyInstr(
        new (zone) Value(pointer), new (zone) Value(pointer2),
        new (zone) Value(src_start_constant_instr),
        new (zone) Value(dest_start_constant_instr),
        new (zone) Value(length_constant_instr),
        /*src_cid=*/cid,
        /*dest_cid=*/cid, unboxed_inputs, /*can_overlap=*/use_same_buffer);
    flow_graph->InsertBefore(another_function_call, memory_copy_instr, nullptr,
                             FlowGraph::kEffect);

    another_function_call->RemoveFromGraph();

    {
      // Check we constructed the right graph.
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
      EXPECT(cursor.TryMatch({
          kMoveGlob,
          kMatchAndMoveStaticCall,
          kMatchAndMoveStaticCall,
          kMatchAndMoveMemoryCopy,
      }));
    }

    {
#if !defined(PRODUCT) && !defined(USING_THREAD_SANITIZER)
      SetFlagScope<bool> sfs(&FLAG_disassemble_optimized, true);
#endif

      pipeline.RunForcedOptimizedAfterSSAPasses();
      pipeline.CompileGraphAndAttachFunction();
    }

    {
      // Check that the memory copy has constant inputs after optimization.
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
      MemoryCopyInstr* memory_copy;
      EXPECT(cursor.TryMatch({
          kMoveGlob,
          {kMatchAndMoveMemoryCopy, &memory_copy},
      }));
      EXPECT(memory_copy->src_start()->BindsToConstant());
      EXPECT(memory_copy->dest_start()->BindsToConstant());
      EXPECT(memory_copy->length()->BindsToConstant());
    }

    // Run the mem copy.
    Invoke(root_library, "copyConst");
  }

  CHECK_MEMORY(ptr, ptr2, dest_start, src_start, length, elem_size);
  // Reinitialize the memory for the non-constant MemoryCopy version.
  InitializeMemory(ptr, ptr2);

  // Test the MemoryCopy instruction when the inputs are not constants.
  {
    Invoke(root_library, "callNonConstCopy");
    // Running this should be a no-op on the memory.
    CHECK_DEFAULT_MEMORY(ptr, ptr2);

    const auto& copy_non_const =
        Function::Handle(GetFunction(root_library, "copyNonConst"));

    TestPipeline pipeline(copy_non_const, CompilerPass::kJIT);
    FlowGraph* flow_graph = pipeline.RunPasses({
        CompilerPass::kComputeSSA,
    });

    auto* const entry_instr = flow_graph->graph_entry()->normal_entry();
    auto* const initial_defs = entry_instr->initial_definitions();
    EXPECT(initial_defs != nullptr);
    EXPECT_EQ(5, initial_defs->length());

    auto* const param_ptr = initial_defs->At(0)->AsParameter();
    EXPECT(param_ptr != nullptr);
    auto* const param_ptr2 = initial_defs->At(1)->AsParameter();
    EXPECT(param_ptr2 != nullptr);
    auto* const param_src_start = initial_defs->At(2)->AsParameter();
    EXPECT(param_src_start != nullptr);
    auto* const param_dest_start = initial_defs->At(3)->AsParameter();
    EXPECT(param_dest_start != nullptr);
    auto* const param_length = initial_defs->At(4)->AsParameter();
    EXPECT(param_length != nullptr);

    ReturnInstr* return_instr;
    {
      ILMatcher cursor(flow_graph, entry_instr);

      EXPECT(cursor.TryMatch({
          kMoveGlob,
          {kMatchReturn, &return_instr},
      }));
    }

    Zone* const zone = Thread::Current()->zone();

    Definition* src_start_def = param_src_start;
    Definition* dest_start_def = param_dest_start;
    Definition* length_def = param_length;
    if (unboxed_inputs) {
      // Manually add the unbox instruction ourselves instead of leaving it
      // up to the SelectDefinitions pass.
      length_def =
          UnboxInstr::Create(kUnboxedWord, new (zone) Value(param_length),
                             DeoptId::kNone, Instruction::kNotSpeculative);
      flow_graph->InsertBefore(return_instr, length_def, nullptr,
                               FlowGraph::kValue);
      dest_start_def =
          UnboxInstr::Create(kUnboxedWord, new (zone) Value(param_dest_start),
                             DeoptId::kNone, Instruction::kNotSpeculative);
      flow_graph->InsertBefore(length_def, dest_start_def, nullptr,
                               FlowGraph::kValue);
      src_start_def =
          UnboxInstr::Create(kUnboxedWord, new (zone) Value(param_src_start),
                             DeoptId::kNone, Instruction::kNotSpeculative);
      flow_graph->InsertBefore(dest_start_def, src_start_def, nullptr,
                               FlowGraph::kValue);
    }

    auto* const memory_copy_instr = new (zone) MemoryCopyInstr(
        new (zone) Value(param_ptr), new (zone) Value(param_ptr2),
        new (zone) Value(src_start_def), new (zone) Value(dest_start_def),
        new (zone) Value(length_def),
        /*src_cid=*/cid,
        /*dest_cid=*/cid, unboxed_inputs, /*can_overlap=*/use_same_buffer);
    flow_graph->InsertBefore(return_instr, memory_copy_instr, nullptr,
                             FlowGraph::kEffect);

    {
      // Check we constructed the right graph.
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
      if (unboxed_inputs) {
        EXPECT(cursor.TryMatch({
            kMoveGlob,
            kMatchAndMoveUnbox,
            kMatchAndMoveUnbox,
            kMatchAndMoveUnbox,
            kMatchAndMoveMemoryCopy,
            kMatchReturn,
        }));
      } else {
        EXPECT(cursor.TryMatch({
            kMoveGlob,
            kMatchAndMoveMemoryCopy,
            kMatchReturn,
        }));
      }
    }

    {
#if !defined(PRODUCT) && !defined(USING_THREAD_SANITIZER)
      SetFlagScope<bool> sfs(&FLAG_disassemble_optimized, true);
#endif

      pipeline.RunForcedOptimizedAfterSSAPasses();
      pipeline.CompileGraphAndAttachFunction();
    }

    {
      // Check that the memory copy has non-constant inputs after optimization.
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
      MemoryCopyInstr* memory_copy;
      EXPECT(cursor.TryMatch({
          kMoveGlob,
          {kMatchAndMoveMemoryCopy, &memory_copy},
      }));
      EXPECT(!memory_copy->src_start()->BindsToConstant());
      EXPECT(!memory_copy->dest_start()->BindsToConstant());
      EXPECT(!memory_copy->length()->BindsToConstant());
    }

    // Run the mem copy.
    Invoke(root_library, "callNonConstCopy");
  }

  CHECK_MEMORY(ptr, ptr2, dest_start, src_start, length, elem_size);
  free(ptr);
  if (!use_same_buffer) {
    free(ptr2);
  }
}

#define MEMORY_COPY_TEST_BOXED(src_start, dest_start, length, elem_size)       \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryCopy_##src_start##_##dest_start##_##length##_##elem_size) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, elem_size, false,    \
                           false);                                             \
  }

#define MEMORY_COPY_TEST_UNBOXED(src_start, dest_start, length, el_si)         \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryCopy_##src_start##_##dest_start##_##length##_##el_si##_u) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, el_si, true, false); \
  }

#define MEMORY_MOVE_TEST_BOXED(src_start, dest_start, length, elem_size)       \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryMove_##src_start##_##dest_start##_##length##_##elem_size) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, elem_size, false,    \
                           true);                                              \
  }

#define MEMORY_MOVE_TEST_UNBOXED(src_start, dest_start, length, el_si)         \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryMove_##src_start##_##dest_start##_##length##_##el_si##_u) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, el_si, true, true);  \
  }

#define MEMORY_COPY_TEST(src_start, dest_start, length, elem_size)             \
  MEMORY_COPY_TEST_BOXED(src_start, dest_start, length, elem_size)             \
  MEMORY_COPY_TEST_UNBOXED(src_start, dest_start, length, elem_size)

#define MEMORY_MOVE_TEST(src_start, dest_start, length, elem_size)             \
  MEMORY_MOVE_TEST_BOXED(src_start, dest_start, length, elem_size)             \
  MEMORY_MOVE_TEST_UNBOXED(src_start, dest_start, length, elem_size)

#define MEMORY_TEST(src_start, dest_start, length, elem_size)                  \
  MEMORY_MOVE_TEST(src_start, dest_start, length, elem_size)                   \
  MEMORY_COPY_TEST(src_start, dest_start, length, elem_size)

// No offset, varying length.
MEMORY_TEST(0, 0, 1, 1)
MEMORY_TEST(0, 0, 2, 1)
MEMORY_TEST(0, 0, 3, 1)
MEMORY_TEST(0, 0, 4, 1)
MEMORY_TEST(0, 0, 5, 1)
MEMORY_TEST(0, 0, 6, 1)
MEMORY_TEST(0, 0, 7, 1)
MEMORY_TEST(0, 0, 8, 1)
MEMORY_TEST(0, 0, 16, 1)

// Offsets.
MEMORY_TEST(2, 2, 1, 1)
MEMORY_TEST(2, 17, 3, 1)
MEMORY_TEST(20, 5, 17, 1)

// Other element sizes.
MEMORY_TEST(0, 0, 1, 2)
MEMORY_TEST(0, 0, 1, 4)
MEMORY_TEST(0, 0, 1, 8)
MEMORY_TEST(0, 0, 2, 2)
MEMORY_TEST(0, 0, 2, 4)
MEMORY_TEST(0, 0, 2, 8)
MEMORY_TEST(0, 0, 4, 2)
MEMORY_TEST(0, 0, 4, 4)
MEMORY_TEST(0, 0, 4, 8)
MEMORY_TEST(0, 0, 8, 2)
MEMORY_TEST(0, 0, 8, 4)
MEMORY_TEST(0, 0, 8, 8)
MEMORY_TEST(0, 0, 2, 16)
MEMORY_TEST(0, 0, 4, 16)
MEMORY_TEST(0, 0, 8, 16)

// Other element sizes with offsets.
MEMORY_TEST(1, 1, 2, 2)
MEMORY_TEST(0, 1, 4, 2)
MEMORY_TEST(1, 2, 3, 2)
MEMORY_TEST(2, 1, 3, 2)
MEMORY_TEST(123, 2, 4, 4)
MEMORY_TEST(2, 123, 4, 4)
MEMORY_TEST(24, 23, 8, 4)
MEMORY_TEST(23, 24, 8, 4)
MEMORY_TEST(5, 72, 1, 8)
MEMORY_TEST(12, 13, 3, 8)
MEMORY_TEST(15, 12, 8, 8)

MEMORY_TEST(13, 14, 15, 16)
MEMORY_TEST(14, 13, 15, 16)

// Size promotions with offsets.
MEMORY_TEST(2, 2, 8, 1)     // promoted to 2.
MEMORY_TEST(4, 4, 8, 1)     // promoted to 4.
MEMORY_TEST(8, 8, 8, 1)     // promoted to 8.
MEMORY_TEST(16, 16, 16, 1)  // promoted to 16 on ARM64.

}  // namespace dart

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

static void RunMemoryCopyInstrTest(intptr_t src_start,
                                   intptr_t dest_start,
                                   intptr_t length,
                                   intptr_t elem_size,
                                   bool length_unboxed) {
  OS::Print("==================================================\n");
  OS::Print("RunMemoryCopyInstrTest src_start %" Pd " dest_start %" Pd
            " length "
            "%" Pd "%s elem_size %" Pd "\n",
            src_start, dest_start, length, length_unboxed ? " (unboxed)" : "",
            elem_size);
  OS::Print("==================================================\n");
  classid_t cid = TypedDataCidForElementSize(elem_size);

  intptr_t dest_copied_start = dest_start * elem_size;
  intptr_t dest_copied_end = dest_copied_start + length * elem_size;
  ASSERT(dest_copied_end < kMemoryTestLength);
  intptr_t expect_diff = (dest_start - src_start) * elem_size;

  uint8_t* ptr = reinterpret_cast<uint8_t*>(malloc(kMemoryTestLength));
  uint8_t* ptr2 = reinterpret_cast<uint8_t*>(malloc(kMemoryTestLength));
  for (intptr_t i = 0; i < kMemoryTestLength; i++) {
    ptr[i] = 1 + i % 100;      // Initialized.
    ptr2[i] = kUnInitialized;  // Emtpy.
  }

  OS::Print("&ptr %p &ptr2 %p\n", ptr, ptr2);

  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
    import 'dart:ffi';

    void myFunction() {
      final pointer = Pointer<Uint8>.fromAddress(%s%p);
      final pointer2 = Pointer<Uint8>.fromAddress(%s%p);
      anotherFunction();
    }

    void anotherFunction() {}
  )", pointer_prefix, ptr, pointer_prefix, ptr2), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
  Invoke(root_library, "myFunction");
  // Running this should be a no-op on the memory.
  for (intptr_t i = 0; i < kMemoryTestLength; i++) {
    EXPECT_EQ(1 + i % 100, static_cast<intptr_t>(ptr[i]));
    EXPECT_EQ(kUnInitialized, static_cast<intptr_t>(ptr2[i]));
  }

  const auto& my_function =
      Function::Handle(GetFunction(root_library, "myFunction"));

  TestPipeline pipeline(my_function, CompilerPass::kJIT);
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

  auto* const src_start_constant_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(src_start, Heap::kOld)), kTagged);

  auto* const dest_start_constant_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(dest_start, Heap::kOld)), kTagged);

  auto* const length_constant_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(length, Heap::kOld)),
      length_unboxed ? kUnboxedIntPtr : kTagged);

  auto* const memory_copy_instr = new (zone)
      MemoryCopyInstr(new (zone) Value(pointer), new (zone) Value(pointer2),
                      new (zone) Value(src_start_constant_instr),
                      new (zone) Value(dest_start_constant_instr),
                      new (zone) Value(length_constant_instr),
                      /*src_cid=*/cid,
                      /*dest_cid=*/cid, length_unboxed);
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
#if !defined(PRODUCT)
    SetFlagScope<bool> sfs(&FLAG_disassemble_optimized, true);
#endif

    pipeline.RunForcedOptimizedAfterSSAPasses();
    pipeline.CompileGraphAndAttachFunction();
  }

  // Run the mem copy.
  Invoke(root_library, "myFunction");
  for (intptr_t i = 0; i < kMemoryTestLength; i++) {
    EXPECT_EQ(1 + i % 100, static_cast<intptr_t>(ptr[i]));
    if (dest_copied_start <= i && i < dest_copied_end) {
      // Copied.
      EXPECT_EQ(1 + (i - expect_diff) % 100, static_cast<intptr_t>(ptr2[i]));
    } else {
      // Untouched.
      EXPECT_EQ(kUnInitialized, static_cast<intptr_t>(ptr2[i]));
    }
  }
  free(ptr);
  free(ptr2);
}

#define MEMORY_COPY_TEST_BOXED(src_start, dest_start, length, elem_size)       \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryCopy_##src_start##_##dest_start##_##length##_##elem_size) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, elem_size, false);   \
  }

#define MEMORY_COPY_TEST_UNBOXED(src_start, dest_start, length, el_si)         \
  ISOLATE_UNIT_TEST_CASE(                                                      \
      IRTest_MemoryCopy_##src_start##_##dest_start##_##length##_##el_si##_u) { \
    RunMemoryCopyInstrTest(src_start, dest_start, length, el_si, true);        \
  }

#define MEMORY_COPY_TEST(src_start, dest_start, length, elem_size)             \
  MEMORY_COPY_TEST_BOXED(src_start, dest_start, length, elem_size)             \
  MEMORY_COPY_TEST_UNBOXED(src_start, dest_start, length, elem_size)

// No offset, varying length.
MEMORY_COPY_TEST(0, 0, 1, 1)
MEMORY_COPY_TEST(0, 0, 2, 1)
MEMORY_COPY_TEST(0, 0, 3, 1)
MEMORY_COPY_TEST(0, 0, 4, 1)
MEMORY_COPY_TEST(0, 0, 5, 1)
MEMORY_COPY_TEST(0, 0, 6, 1)
MEMORY_COPY_TEST(0, 0, 7, 1)
MEMORY_COPY_TEST(0, 0, 8, 1)
MEMORY_COPY_TEST(0, 0, 16, 1)

// Offsets.
MEMORY_COPY_TEST(2, 2, 1, 1)
MEMORY_COPY_TEST(2, 17, 3, 1)
MEMORY_COPY_TEST(20, 5, 17, 1)

// Other element sizes.
MEMORY_COPY_TEST(0, 0, 1, 2)
MEMORY_COPY_TEST(0, 0, 1, 4)
MEMORY_COPY_TEST(0, 0, 1, 8)
MEMORY_COPY_TEST(0, 0, 2, 2)
MEMORY_COPY_TEST(0, 0, 2, 4)
MEMORY_COPY_TEST(0, 0, 2, 8)
MEMORY_COPY_TEST(0, 0, 4, 2)
MEMORY_COPY_TEST(0, 0, 4, 4)
MEMORY_COPY_TEST(0, 0, 4, 8)
MEMORY_COPY_TEST(0, 0, 8, 2)
MEMORY_COPY_TEST(0, 0, 8, 4)
MEMORY_COPY_TEST(0, 0, 8, 8)
// TODO(http://dartbug.com/51237): Fix arm64 issue.
#if !defined(TARGET_ARCH_ARM64)
MEMORY_COPY_TEST(0, 0, 2, 16)
MEMORY_COPY_TEST(0, 0, 4, 16)
MEMORY_COPY_TEST(0, 0, 8, 16)
#endif

// Other element sizes with offsets.
MEMORY_COPY_TEST(1, 1, 2, 2)
MEMORY_COPY_TEST(0, 1, 4, 2)
MEMORY_COPY_TEST(1, 2, 3, 2)
MEMORY_COPY_TEST(123, 2, 4, 4)
MEMORY_COPY_TEST(5, 72, 1, 8)

// TODO(http://dartbug.com/51229): Fix arm issue.
// TODO(http://dartbug.com/51237): Fix arm64 issue.
#if !defined(TARGET_ARCH_ARM) && !defined(TARGET_ARCH_ARM64)
MEMORY_COPY_TEST(13, 14, 15, 16)
#endif

// Size promotions with offsets.
MEMORY_COPY_TEST(2, 2, 8, 1)  // promoted to 2.
MEMORY_COPY_TEST(4, 4, 8, 1)  // promoted to 4.
MEMORY_COPY_TEST(8, 8, 8, 1)  // promoted to 8.

}  // namespace dart

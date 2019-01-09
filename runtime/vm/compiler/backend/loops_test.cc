// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unit tests specific to loops and induction variables.
// Note, try to avoid relying on information that is subject
// to change (block ids, variable numbers, etc.) in order
// to make this test less sensitive to unrelated changes.

#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

// Helper method to construct an induction debug string for loop hierarchy.
void TestString(BufferFormatter* f,
                LoopInfo* loop,
                const GrowableArray<BlockEntryInstr*>& preorder) {
  for (; loop != nullptr; loop = loop->next()) {
    intptr_t depth = loop->NestingDepth();
    f->Print("%*c[%" Pd "\n", static_cast<int>(2 * depth), ' ', loop->id());
    for (BitVector::Iterator block_it(loop->blocks()); !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = preorder[block_it.Current()];
      if (block->IsJoinEntry()) {
        for (PhiIterator it(block->AsJoinEntry()); !it.Done(); it.Advance()) {
          InductionVar* induc = loop->LookupInduction(it.Current());
          if (induc != nullptr) {
            // Obtain the debug string for induction and bounds.
            f->Print("%*c%s", static_cast<int>(2 * depth), ' ',
                     induc->ToCString());
            for (auto bound : induc->bounds()) {
              f->Print(" %s", bound.limit_->ToCString());
            }
            f->Print("\n");
          }
        }
      }
      for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
        InductionVar* induc =
            loop->LookupInduction(it.Current()->AsDefinition());
        if (InductionVar::IsInduction(induc)) {
          f->Print("%*c%s\n", static_cast<int>(2 * depth), ' ',
                   induc->ToCString());
        }
      }
    }
    TestString(f, loop->inner(), preorder);
    f->Print("%*c]\n", static_cast<int>(2 * depth), ' ');
  }
}

// Helper method to build CFG and compute induction.
static const char* ComputeInduction(Thread* thread, const char* script_chars) {
  // Invoke the script.
  Dart_Handle script = TestCase::LoadTestScript(script_chars, NULL);
  Dart_Handle result = Dart_Invoke(script, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Find parsed function "foo".
  TransitionNativeToVM transition(thread);
  Zone* zone = thread->zone();
  Library& lib =
      Library::ZoneHandle(Library::RawCast(Api::UnwrapHandle(script)));
  RawFunction* raw_func =
      lib.LookupLocalFunction(String::Handle(Symbols::New(thread, "foo")));
  ParsedFunction* parsed_function =
      new (zone) ParsedFunction(thread, Function::ZoneHandle(zone, raw_func));
  EXPECT(parsed_function != nullptr);

  // Build flow graph.
  CompilerState state(thread);
  ZoneGrowableArray<const ICData*>* ic_data_array =
      new (zone) ZoneGrowableArray<const ICData*>();
  parsed_function->function().RestoreICDataMap(ic_data_array, true);
  kernel::FlowGraphBuilder builder(parsed_function, ic_data_array, nullptr,
                                   nullptr, true, DeoptId::kNone);
  FlowGraph* flow_graph = builder.BuildGraph();
  EXPECT(flow_graph != nullptr);

  // Setup some pass data structures and perform minimum passes.
  SpeculativeInliningPolicy speculative_policy(/*enable_blacklist*/ false);
  CompilerPassState pass_state(thread, flow_graph, &speculative_policy);
  JitCallSpecializer call_specializer(flow_graph, &speculative_policy);
  pass_state.call_specializer = &call_specializer;
  flow_graph->ComputeSSA(0, nullptr);
  FlowGraphTypePropagator::Propagate(flow_graph);
  call_specializer.ApplyICData();
  flow_graph->SelectRepresentations();
  FlowGraphTypePropagator::Propagate(flow_graph);
  flow_graph->Canonicalize();

  // Build loop hierarchy and find induction.
  const LoopHierarchy& hierarchy = flow_graph->GetLoopHierarchy();
  hierarchy.ComputeInduction();
  flow_graph->RemoveRedefinitions();  // don't query later

  // Construct and return a debug string for testing.
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  TestString(&f, hierarchy.top(), flow_graph->preorder());
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

//
// Induction tests.
//

TEST_CASE(BasicInductionUp) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(0 + 1 * i) 100\n"  // phi
      "  LIN(1 + 1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(BasicInductionDown) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 100; i > 0; i--) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(100 + -1 * i) 0\n"  // phi
      "  LIN(99 + -1 * i)\n"     // sub
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(BasicInductionStepUp) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 10; i < 100; i += 2) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(10 + 2 * i)\n"  // phi
      "  LIN(12 + 2 * i)\n"  // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(BasicInductionStepDown) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 100; i >= 0; i -= 7) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(100 + -7 * i)\n"  // phi
      "  LIN(93 + -7 * i)\n"   // sub
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(BasicInductionLoopNest) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "    for (int j = 1; j < 100; j++) {\n"
      "      for (int k = 2; k < 100; k++) {\n"
      "      }\n"
      "    }\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [2\n"
      "  LIN(0 + 1 * i) 100\n"  // i
      "  LIN(1 + 1 * i)\n"
      "    [1\n"
      "    LIN(1 + 1 * i) 100\n"  // j
      "    LIN(2 + 1 * i)\n"
      "      [0\n"
      "      LIN(2 + 1 * i) 100\n"  // k
      "      LIN(3 + 1 * i)\n"
      "      ]\n"
      "    ]\n"
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(ChainInduction) {
  const char* script_chars =
      "foo() {\n"
      "  int j = 1;\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "    j += 5;\n"
      "    j += 7;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(1 + 12 * i)\n"     // phi (j)
      "  LIN(0 + 1 * i) 100\n"  // phi
      "  LIN(6 + 12 * i)\n"     // j-add
      "  LIN(13 + 12 * i)\n"    // j-add
      "  LIN(1 + 1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(TwoWayInduction) {
  const char* script_chars =
      "foo() {\n"
      "  int j = 123;\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "     if (i == 10) {\n"
      "       j += 3;\n"
      "     } else {\n"
      "       j += 3;\n"
      "     }\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(123 + 3 * i)\n"    // phi (j)
      "  LIN(0 + 1 * i) 100\n"  // phi
      "  LIN(126 + 3 * i)\n"    // j-true
      "  LIN(126 + 3 * i)\n"    // j-false
      "  LIN(1 + 1 * i)\n"      // add
      "  LIN(126 + 3 * i)\n"    // phi (j)
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(DerivedInduction) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 1; i < 100; i++) {\n"
      "    int a = i + 3;\n"
      "    int b = i - 5;\n"
      "    int c = i * 7;\n"
      "    int d = - i;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(1 + 1 * i) 100\n"  // phi
      "  LIN(4 + 1 * i)\n"      // a
      "  LIN(-4 + 1 * i)\n"     // b
      "  LIN(7 + 7 * i)\n"      // c
      "  LIN(-1 + -1 * i)\n"    // d
      "  LIN(2 + 1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(WrapAroundAndDerived) {
  const char* script_chars =
      "foo() {\n"
      "  int w = 99;\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "    int a = w + 3;\n"
      "    int b = w - 5;\n"
      "    int c = w * 7;\n"
      "    int d = - w;\n"
      "    w = i;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  WRAP(99, LIN(0 + 1 * i))\n"    // phi (w)
      "  LIN(0 + 1 * i) 100\n"          // phi
      "  WRAP(102, LIN(3 + 1 * i))\n"   // a
      "  WRAP(94, LIN(-5 + 1 * i))\n"   // b
      "  WRAP(693, LIN(0 + 7 * i))\n"   // c
      "  WRAP(-99, LIN(0 + -1 * i))\n"  // d
      "  LIN(1 + 1 * i)\n"              // add
      "  ]\n";
  EXPECT_STREQ(ComputeInduction(thread, script_chars), expected);
}

TEST_CASE(PeriodicAndDerived) {
  const char* script_chars =
      "foo() {\n"
      "  int p1 = 3;\n"
      "  int p2 = 5;\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "    int a = p1 + 3;\n"
      "    int b = p1 - 5;\n"
      "    int c = p1 * 7;\n"
      "    int d = - p1;\n"
      "    p1 = - p1;\n"
      "    p2 = 100 - p2;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  PERIOD(3, -3)\n"       // phi(p1)
      "  PERIOD(5, 95)\n"       // phi(p2)
      "  LIN(0 + 1 * i) 100\n"  // phi
      "  PERIOD(6, 0)\n"        // a
      "  PERIOD(-2, -8)\n"      // b
      "  PERIOD(21, -21)\n"     // c
      "  PERIOD(-3, 3)\n"       // d
      "  PERIOD(-3, 3)\n"       // p1
      "  PERIOD(95, 5)\n"       // p2
      "  LIN(1 + 1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(ComputeInduction(thread, script_chars), expected);
}

//
// Bound specific tests.
//

TEST_CASE(NonStrictConditionUp) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0; i <= 100; i++) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(0 + 1 * i) 101\n"  // phi
      "  LIN(1 + 1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

#ifndef TARGET_ARCH_DBC
TEST_CASE(NonStrictConditionUpWrap) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0x7ffffffffffffffe; i <= 0x7fffffffffffffff; i++) {\n"
      "    if (i < 0) break;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(9223372036854775806 + 1 * i)\n"  // phi
      "  LIN(9223372036854775806 + 1 * i)\n"  // (un)boxing
      "  LIN(9223372036854775806 + 1 * i)\n"
      "  LIN(9223372036854775806 + 1 * i)\n"
      "  LIN(9223372036854775807 + 1 * i)\n"  // add
      "  LIN(9223372036854775807 + 1 * i)\n"  // unbox
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}
#endif

TEST_CASE(NonStrictConditionDown) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 100; i >= 0; i--) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(100 + -1 * i) -1\n"  // phi
      "  LIN(99 + -1 * i)\n"      // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

#ifndef TARGET_ARCH_DBC
TEST_CASE(NonStrictConditionDownWrap) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0x8000000000000001; i >= 0x8000000000000000; i--) {\n"
      "    if (i > 0) break;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(-9223372036854775807 + -1 * i)\n"  // phi
      "  LIN(-9223372036854775807 + -1 * i)\n"  // (un)boxing
      "  LIN(-9223372036854775807 + -1 * i)\n"
      "  LIN(-9223372036854775807 + -1 * i)\n"
      "  LIN(-9223372036854775808 + -1 * i)\n"  // sub
      "  LIN(-9223372036854775808 + -1 * i)\n"  // unbox
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}
#endif

TEST_CASE(NotEqualConditionUp) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 10; i != 20; i++) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(10 + 1 * i) 20\n"  // phi
      "  LIN(11 + 1 * i)\n"     // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(NotEqualConditionDown) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 20; i != 10; i--) {\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(20 + -1 * i) 10\n"  // phi
      "  LIN(19 + -1 * i)\n"     // sub
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(SecondExitUp) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "     if (i >= 50) break;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(0 + 1 * i) 100 50\n"  // phi
      "  LIN(1 + 1 * i)\n"         // add
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

TEST_CASE(SecondExitDown) {
  const char* script_chars =
      "foo() {\n"
      "  for (int i = 100; i > 0; i--) {\n"
      "     if (i <= 10) break;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  foo();\n"
      "}\n";
  const char* expected =
      "  [0\n"
      "  LIN(100 + -1 * i) 0 10\n"  // phi
      "  LIN(99 + -1 * i)\n"        // sub
      "  ]\n";
  EXPECT_STREQ(expected, ComputeInduction(thread, script_chars));
}

}  // namespace dart

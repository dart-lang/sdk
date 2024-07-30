// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph.h"

#include <vector>

#include "platform/text_buffer.h"
#include "platform/utils.h"
#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IS_64_BIT)
ISOLATE_UNIT_TEST_CASE(FlowGraph_UnboxInt64Phi) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/1);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::IntType()),
                new CompileType(CompileType::Int()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto loop_header = H.JoinEntry();
  auto loop_body = H.TargetEntry();
  auto loop_exit = H.TargetEntry();

  Definition* v0;
  PhiInstr* loop_var;
  Definition* add1;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, kTagged);
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_header);
    loop_var = H.Phi(loop_header, {{normal_entry, v0}, {loop_body, &add1}});
    builder.AddPhi(loop_var);
    builder.AddBranch(new RelationalOpInstr(
                          InstructionSource(), Token::kLT, new Value(loop_var),
                          new Value(H.IntConstant(50)), kMintCid,
                          S.GetNextDeoptId(), Instruction::kNotSpeculative),
                      loop_body, loop_exit);
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_body);
    add1 = builder.AddDefinition(new BinaryInt64OpInstr(
        Token::kADD, new Value(loop_var), new Value(H.IntConstant(1)),
        S.GetNextDeoptId(), Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_exit);
    builder.AddReturn(new Value(loop_var));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  H.flow_graph()->SelectRepresentations();

  EXPECT_PROPERTY(loop_var, it.representation() == kUnboxedInt64);
}
#endif  // defined(TARGET_ARCH_IS_64_BIT)

ISOLATE_UNIT_TEST_CASE(FlowGraph_LateVariablePhiUnboxing) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto loop_header = H.JoinEntry();
  auto loop_body = H.TargetEntry();
  auto loop_exit = H.TargetEntry();

  ConstantInstr* sentinel = H.flow_graph()->GetConstant(Object::sentinel());

  PhiInstr* loop_var;
  PhiInstr* late_var;
  Definition* add1;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_header);
    loop_var = H.Phi(loop_header,
                     {{normal_entry, H.IntConstant(0)}, {loop_body, &add1}});
    builder.AddPhi(loop_var);
    loop_var->UpdateType(CompileType::Int());
    loop_var->UpdateType(CompileType::FromAbstractType(
        Type::ZoneHandle(Type::IntType()), CompileType::kCannotBeNull,
        CompileType::kCanBeSentinel));
    late_var =
        H.Phi(loop_header, {{normal_entry, sentinel}, {loop_body, &add1}});
    builder.AddPhi(late_var);
    builder.AddBranch(new RelationalOpInstr(
                          InstructionSource(), Token::kLT, new Value(loop_var),
                          new Value(H.IntConstant(10)), kMintCid,
                          S.GetNextDeoptId(), Instruction::kNotSpeculative),
                      loop_body, loop_exit);
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_body);
    add1 = builder.AddDefinition(new BinaryInt64OpInstr(
        Token::kADD, new Value(loop_var), new Value(H.IntConstant(1)),
        S.GetNextDeoptId(), Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_exit);
    builder.AddReturn(new Value(late_var));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  H.flow_graph()->SelectRepresentations();

#if defined(TARGET_ARCH_IS_64_BIT)
  EXPECT_PROPERTY(loop_var, it.representation() == kUnboxedInt64);
#endif
  EXPECT_PROPERTY(late_var, it.representation() == kTagged);
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_UnboxedFloatPhi) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto then_body = H.TargetEntry();
  auto else_body = H.TargetEntry();
  auto join_exit = H.JoinEntry();

  PhiInstr* phi;
  Definition* double_to_float_1;
  Definition* double_to_float_2;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    builder.AddBranch(
        new StrictCompareInstr(
            InstructionSource(), Token::kEQ_STRICT, new Value(H.IntConstant(1)),
            new Value(H.IntConstant(1)),
            /*needs_number_check=*/false, S.GetNextDeoptId()),
        then_body, else_body);
  }

  {
    BlockBuilder builder(H.flow_graph(), then_body);
    double_to_float_1 = builder.AddDefinition(new DoubleToFloatInstr(
        new Value(H.DoubleConstant(1)), S.GetNextDeoptId(),
        Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(join_exit, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), else_body);
    double_to_float_2 = builder.AddDefinition(new DoubleToFloatInstr(
        new Value(H.DoubleConstant(2)), S.GetNextDeoptId(),
        Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(join_exit, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), join_exit);
    phi = new PhiInstr(join_exit, 3);
    phi->SetInputAt(0, new Value(double_to_float_1));
    phi->SetInputAt(1, new Value(double_to_float_2));
    phi->SetInputAt(2, new Value(phi));
    builder.AddPhi(phi);
    builder.AddReturn(new Value(phi));
  }
  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  H.flow_graph()->SelectRepresentations();

  EXPECT_PROPERTY(phi, it.representation() == kUnboxedFloat);
}

void TestLargeFrame(const char* type,
                    const char* zero,
                    const char* one,
                    const char* main) {
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 1000);
  TextBuffer printer(256 * KB);

  intptr_t num_locals = 2000;
  printer.Printf("import 'dart:typed_data';\n");
  printer.Printf("@pragma('vm:never-inline')\n");
  printer.Printf("%s one() { return %s; }\n", type, one);
  printer.Printf("@pragma('vm:never-inline')\n");
  printer.Printf("%s largeFrame(int n) {\n", type);
  for (intptr_t i = 0; i < num_locals; i++) {
    printer.Printf("  %s local%" Pd " = %s;\n", type, i, zero);
  }
  printer.Printf("  for (int i = 0; i < n; i++) {\n");
  for (intptr_t i = 0; i < num_locals; i++) {
    printer.Printf("    local%" Pd " += one();\n", i);
  }
  printer.Printf("  }\n");
  printer.Printf("  %s sum = %s;\n", type, zero);
  for (intptr_t i = 0; i < num_locals; i++) {
    printer.Printf("    sum += local%" Pd ";\n", i);
  }
  printer.Printf("  return sum;\n");
  printer.Printf("}\n");

  printer.AddString(main);

  const auto& root_library = Library::Handle(LoadTestScript(printer.buffer()));
  Invoke(root_library, "main");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_LargeFrame_Int) {
  TestLargeFrame("int", "0", "1",
                 "main() {\n"
                 "  for (var i = 0; i < 100; i++) {\n"
                 "    var r = largeFrame(1);\n"
                 "    if (r != 2000) throw r;\n"
                 "  }\n"
                 "  return 'Okay';\n"
                 "}\n");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_LargeFrame_Double) {
  TestLargeFrame("double", "0.0", "1.0",
                 "main() {\n"
                 "  for (var i = 0; i < 100; i++) {\n"
                 "    var r = largeFrame(1);\n"
                 "    if (r != 2000.0) throw r;\n"
                 "  }\n"
                 "  return 'Okay';\n"
                 "}\n");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_LargeFrame_Int32x4) {
  TestLargeFrame("Int32x4", "Int32x4(0, 0, 0, 0)", "Int32x4(1, 2, 3, 4)",
                 "main() {\n"
                 "  for (var i = 0; i < 100; i++) {\n"
                 "    var r = largeFrame(1);\n"
                 "    if (r.x != 2000) throw r;\n"
                 "    if (r.y != 4000) throw r;\n"
                 "    if (r.z != 6000) throw r;\n"
                 "    if (r.w != 8000) throw r;\n"
                 "  }\n"
                 "  return 'Okay';\n"
                 "}\n");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_LargeFrame_Float32x4) {
  TestLargeFrame("Float32x4", "Float32x4(0.0, 0.0, 0.0, 0.0)",
                 "Float32x4(1.0, 2.0, 3.0, 4.0)",
                 "main() {\n"
                 "  for (var i = 0; i < 100; i++) {\n"
                 "    var r = largeFrame(1);\n"
                 "    if (r.x != 2000.0) throw r;\n"
                 "    if (r.y != 4000.0) throw r;\n"
                 "    if (r.z != 6000.0) throw r;\n"
                 "    if (r.w != 8000.0) throw r;\n"
                 "  }\n"
                 "  return 'Okay';\n"
                 "}\n");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_LargeFrame_Float64x2) {
  TestLargeFrame("Float64x2", "Float64x2(0.0, 0.0)", "Float64x2(1.0, 2.0)",
                 "main() {\n"
                 "  for (var i = 0; i < 100; i++) {\n"
                 "    var r = largeFrame(1);\n"
                 "    if (r.x != 2000.0) throw r;\n"
                 "    if (r.y != 4000.0) throw r;\n"
                 "  }\n"
                 "  return 'Okay';\n"
                 "}\n");
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_PhiUnboxingHeuristic_Double) {
  const char* kScript = R"(
    double foo(double sum, int n) {
       if (sum == null) return 0.0;
       for (int i = 0; i < n; i++) {
          sum += 1.0;
       }
       return sum;
    }
    main() {
      foo(0.0, 10);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);

  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveFunctionEntry,
  }));
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveUnbox,  // outside of loop
      kMatchAndMoveCheckSmi,
      kMoveGlob,

      // Loop header
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchTrue,

      // Loop body
      kMatchAndMoveTargetEntry,
      kMatchAndMoveBinaryDoubleOp,
      kMatchAndMoveBinarySmiOp,
      kMatchAndMoveGoto,

      // Loop header, again
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchFalse,

      // After loop
      kMatchAndMoveTargetEntry,
      kMatchAndMoveBox,
      kMatchDartReturn,
  }));
}

static void TestPhiUnboxingHeuristicSimd(const char* script) {
  if (!FlowGraphCompiler::SupportsUnboxedSimd128()) {
    return;
  }

  const auto& root_library = Library::Handle(LoadTestScript(script));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);

  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveFunctionEntry,
  }));
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveUnbox,  // outside of loop
      kMatchAndMoveCheckSmi,
      kMoveGlob,

      // Loop header
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchTrue,

      // Loop body
      kMatchAndMoveTargetEntry,
      kMatchAndMoveSimdOp,
      kMatchAndMoveBinarySmiOp,
      kMatchAndMoveGoto,

      // Loop header, again
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchFalse,

      // After loop
      kMatchAndMoveTargetEntry,
      kMatchAndMoveBox,
      kMatchDartReturn,
  }));
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_PhiUnboxingHeuristic_Float32x4) {
  const char* kScript = R"(
    import 'dart:typed_data';
    Float32x4 foo(Float32x4 sum, int n) {
       if (sum == null) return Float32x4(0.0, 0.0, 0.0, 0.0);
       for (int i = 0; i < n; i++) {
          sum += Float32x4(1.0, 2.0, 3.0, 4.0);
       }
       return sum;
    }
    main() {
      foo(Float32x4(0.0, 0.0, 0.0, 0.0), 10);
    }
  )";
  TestPhiUnboxingHeuristicSimd(kScript);
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_PhiUnboxingHeuristic_Float64x2) {
  const char* kScript = R"(
    import 'dart:typed_data';
    Float64x2 foo(Float64x2 sum, int n) {
       if (sum == null) return Float64x2(0.0, 0.0);
       for (int i = 0; i < n; i++) {
          sum += Float64x2(1.0, 2.0);
       }
       return sum;
    }
    main() {
      foo(Float64x2(0.0, 0.0), 10);
    }
  )";
  TestPhiUnboxingHeuristicSimd(kScript);
}

ISOLATE_UNIT_TEST_CASE(FlowGraph_PhiUnboxingHeuristic_Int32x4) {
  const char* kScript = R"(
    import 'dart:typed_data';
    Int32x4 foo(Int32x4 sum, int n) {
       if (sum == null) return Int32x4(0, 0, 0, 0);
       for (int i = 0; i < n; i++) {
          sum += Int32x4(1, 2, 3, 4);
       }
       return sum;
    }
    main() {
      foo(Int32x4(0, 0, 0, 0), 10);
    }
  )";
  TestPhiUnboxingHeuristicSimd(kScript);
}

}  // namespace dart

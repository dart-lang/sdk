// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/inliner.h"

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

// Test that the redefinition for an inlined polymorphic function used with
// multiple receiver cids does not have a concrete type.
ISOLATE_UNIT_TEST_CASE(Inliner_PolyInliningRedefinition) {
  const char* kScript = R"(
    abstract class A {
      String toInline() { return "A"; }
    }

    class B extends A {}
    class C extends A {
      @override
      String toInline() { return "C";}
    }
    class D extends A {}

    testInlining(A arg) {
      arg.toInline();
    }

    main() {
      for (var i = 0; i < 10; i++) {
        testInlining(B());
        testInlining(C());
        testInlining(D());
      }
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function =
      Function::Handle(GetFunction(root_library, "testInlining"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyClassIds,
      CompilerPass::kInlining,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  EXPECT(entry->initial_definitions()->length() == 1);
  EXPECT(entry->initial_definitions()->At(0)->IsParameter());
  ParameterInstr* param = entry->initial_definitions()->At(0)->AsParameter();

  // First we find the start of the prelude for the inlined instruction,
  // and also keep a reference to the LoadClassId instruction for later.
  LoadClassIdInstr* lcid = nullptr;
  BranchInstr* prelude = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch(
      {
          {kMatchLoadClassId, &lcid},
          {kMatchBranch, &prelude},
      },
      /*insert_before=*/kMoveGlob));

  const Class& cls = Class::Handle(
      root_library.LookupLocalClass(String::Handle(Symbols::New(thread, "B"))));

  Definition* cid_B = flow_graph->GetConstant(Smi::Handle(Smi::New(cls.id())));
  Instruction* current = prelude;

  // We walk false branches until we either reach a branch instruction that uses
  // B's cid for comparison to the value returned from the LCID instruction
  // above, or a default case if there was no branch instruction for B's cid.
  while (true) {
    EXPECT(current->IsBranch());
    const ComparisonInstr* check = current->AsBranch()->comparison();
    EXPECT(check->left()->definition() == lcid);
    if (check->right()->definition() == cid_B) break;
    current = current->SuccessorAt(1);
    // By following false paths, we should be walking a series of blocks that
    // looks like:
    // B#[target]:#
    //   Branch if <check on class ID>
    // If we end up not finding a branch, then we're in a default case
    // that contains a class check.
    current = current->next();
    if (!current->IsBranch()) {
      break;
    }
  }
  // If we found a branch that checks against the class ID, we follow the true
  // branch to a block that contains only a goto to the desired join block.
  if (current->IsBranch()) {
    current = current->SuccessorAt(0);
  } else {
    // We're in the default case, which will check the class ID to make sure
    // it's the one expected for the fallthrough. That check will be followed
    // by a goto to the desired join block.
    EXPECT(current->IsRedefinition());
    const auto redef = current->AsRedefinition();
    EXPECT(redef->value()->definition() == lcid);
    current = current->next();
    EXPECT(current->IsCheckClassId());
    EXPECT(current->AsCheckClassId()->value()->definition() == redef);
  }
  current = current->next();
  EXPECT(current->IsGoto());
  current = current->AsGoto()->successor();
  // Now we should be at a block that starts like:
  // BY[join]:# pred(...)
  //    vW <- Redefinition(vV)
  //
  // where vV is a reference to the function parameter (the receiver of
  // the inlined function).
  current = current->next();
  EXPECT(current->IsRedefinition());
  EXPECT(current->AsRedefinition()->value()->definition() == param);
  EXPECT(current->AsRedefinition()->Type()->ToCid() == kDynamicCid);
}

ISOLATE_UNIT_TEST_CASE(Inliner_TypedData_Regress7551) {
  const char* kScript = R"(
    import 'dart:typed_data';

    setValue(Int32List list, int value) {
      list[0] = value;
    }

    main() {
      final list = Int32List(10);
      setValue(list, 0x1122334455);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function =
      Function::Handle(GetFunction(root_library, "setValue"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyClassIds,
      CompilerPass::kInlining,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();

  EXPECT(entry->initial_definitions()->length() == 2);
  EXPECT(entry->initial_definitions()->At(0)->IsParameter());
  EXPECT(entry->initial_definitions()->At(1)->IsParameter());
  ParameterInstr* list_param =
      entry->initial_definitions()->At(0)->AsParameter();
  ParameterInstr* value_param =
      entry->initial_definitions()->At(1)->AsParameter();

  ILMatcher cursor(flow_graph, entry);

  CheckArrayBoundInstr* bounds_check_instr = nullptr;
  UnboxInt32Instr* unbox_instr = nullptr;
  StoreIndexedInstr* store_instr = nullptr;

  RELEASE_ASSERT(cursor.TryMatch({
      {kMoveGlob},
      {kMatchAndMoveCheckArrayBound, &bounds_check_instr},
      {kMatchAndMoveUnboxInt32, &unbox_instr},
      {kMatchAndMoveStoreIndexed, &store_instr},
  }));

  RELEASE_ASSERT(unbox_instr->InputAt(0)->definition()->OriginalDefinition() ==
                 value_param);
  RELEASE_ASSERT(store_instr->InputAt(0)->definition() == list_param);
  RELEASE_ASSERT(store_instr->InputAt(2)->definition() == unbox_instr);
  RELEASE_ASSERT(unbox_instr->is_truncating());
}

#if defined(DART_PRECOMPILER)

// Verifies that all calls are inlined in List.generate call
// with a simple closure.
ISOLATE_UNIT_TEST_CASE(Inliner_List_generate) {
  const char* kScript = R"(
    foo(n) => List<int>.generate(n, (int x) => x, growable: false);
    main() {
      foo(100);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);

  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveCreateArray,
      kMatchAndMoveUnboxInt64,
      kMatchAndMoveGoto,

      // Loop header
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchTrue,

      // Loop body
      kMatchAndMoveTargetEntry,
      kMatchAndMoveBoxInt64,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveBinaryInt64Op,
      kMatchAndMoveGoto,

      // Loop header once again
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchFalse,

      // After loop
      kMatchAndMoveTargetEntry,
      kMatchReturn,
  }));
}

// Verifies that pragma-decorated call gets inlined.
ISOLATE_UNIT_TEST_CASE(Inliner_always_consider_inlining) {
  const char* kScript = R"(
    choice() {
      dynamic x;
      return x == 123;
    }

    @pragma("vm:always-consider-inlining")
    bar(baz) {
      if (baz is String) {
        return 1;
      }
      if (baz is num) {
        return 2;
      }
      if (baz is bool) {
        dynamic j = 0;
        for (int i = 0; i < 1024; i++) {
          j += "i: $i".length;
        }
        return j;
      }
      return 4;
    }

    bbar(bbaz, something) {
      if (bbaz == null) {
        return "null";
      }
      return bar(bbaz);
    }

    main(args) {
      print(bbar(42, "something"));
      print(bbar(choice() ? "abc": 42, "something"));
      print(bbar("abc", "something"));
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "main"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true);

  StaticCallInstr* call_print1;
  StaticCallInstr* call_print2;
  StaticCallInstr* call_print3;
  StaticCallInstr* call_bar;
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call_print1},
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call_bar},
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call_print2},
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call_print3},
      kMoveGlob,
      kMatchReturn,
  }));
  EXPECT(strcmp(call_print1->function().UserVisibleNameCString(), "print") ==
         0);
  EXPECT(strcmp(call_print2->function().UserVisibleNameCString(), "print") ==
         0);
  EXPECT(strcmp(call_print3->function().UserVisibleNameCString(), "print") ==
         0);
  EXPECT(strcmp(call_bar->function().UserVisibleNameCString(), "bar") == 0);
}

// Verifies that List.of gets inlined.
ISOLATE_UNIT_TEST_CASE(Inliner_List_of_inlined) {
  const char* kScript = R"(
    main() {
      final foo = List<String>.filled(100, "bar");
      final the_copy1 = List.of(foo, growable: false);
      print('${the_copy1.length}');
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "main"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true);

  StaticCallInstr* call_print;
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveJoinEntry,
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      kMatchAndMoveJoinEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveBranchFalse,
      kMatchAndMoveTargetEntry,
      kMoveGlob,
      kMatchAndMoveJoinEntry,
      kMoveGlob,
      kMatchAndMoveBranchFalse,
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call_print},
      kMoveGlob,
      kMatchReturn,
  }));
  EXPECT(strcmp(call_print->function().UserVisibleNameCString(), "print") == 0);
  // Length is fully forwarded and string interpolation is constant folded.
  EXPECT_PROPERTY(call_print->ArgumentAt(0),
                  it.IsConstant() && it.AsConstant()->value().IsString() &&
                      String::Cast(it.AsConstant()->value()).Equals("100"));
}

#endif  // defined(DART_PRECOMPILER)

}  // namespace dart

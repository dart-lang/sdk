// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/inliner.h"

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
    class A {
      String toInline() { return "A"; }
    }

    class B extends A {
      @override
      String toInline() { return "B"; }
    }
    class C extends A {}
    class D extends A {
      @override
      String toInline() { return "D";}
    }
    class E extends A {}

    testInlining(A arg) {
      arg.toInline();
    }

    main() {
      for (var i = 0; i < 10; i++) {
        testInlining(B());
        testInlining(C());
        testInlining(D());
        testInlining(E());
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

  RedefinitionInstr* redefn = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveBranchFalse,
          kMatchAndMoveBranchTrue,
          {kMatchAndMoveRedefinition, &redefn},
          kMatchReturn,
      },
      /*insert_before=*/kMoveGlob));

  EXPECT(redefn->Type()->ToCid() == kDynamicCid);
}

}  // namespace dart

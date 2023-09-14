// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/inliner.h"

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/debugger_api_impl_test.h"
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
      root_library.LookupClass(String::Handle(Symbols::New(thread, "B"))));

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

// Test that when force-optimized functions get inlined, deopt_id and
// environment for instructions coming from those functions get overwritten
// by deopt_id and environment from the call itself.
ISOLATE_UNIT_TEST_CASE(Inliner_InlineForceOptimized) {
  const char* kScript = R"(
    import 'dart:ffi';

    @pragma('vm:never-inline')
    int foo(int x) {
      dynamic ptr = Pointer.fromAddress(x);
      return x + ptr.hashCode;
    }
    main() {
      int r = 0;
      for (int i = 0; i < 1000; i++) {
        r += foo(r);
      }
      return r;
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyClassIds,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  StaticCallInstr* call_instr = nullptr;
  {
    ILMatcher cursor(flow_graph, entry);
    RELEASE_ASSERT(cursor.TryMatch({
        {kMoveGlob},
        {kMatchAndMoveStaticCall, &call_instr},
    }));
    EXPECT(strcmp(call_instr->function().UserVisibleNameCString(),
                  "Pointer.fromAddress") == 0);
  }

  pipeline.RunAdditionalPasses({
      CompilerPass::kInlining,
  });

  AllocateObjectInstr* allocate_object_instr = nullptr;
  {
    ILMatcher cursor(flow_graph, entry);
    RELEASE_ASSERT(cursor.TryMatch({
        {kMoveGlob},
        {kMatchAndMoveAllocateObject, &allocate_object_instr},
    }));
  }

  // Ensure that AllocateObject instruction that came from force-optimized
  // function has deopt and environment taken from the Call instruction.
  EXPECT(call_instr->deopt_id() == allocate_object_instr->deopt_id());
  EXPECT(DeoptId::IsDeoptBefore(call_instr->deopt_id()));

  auto allocate_object_instr_env = allocate_object_instr->env();
  EXPECT(allocate_object_instr_env->LazyDeoptToBeforeDeoptId());
  EXPECT(allocate_object_instr_env->Outermost()->GetDeoptId() ==
         call_instr->deopt_id());
  const auto call_instr_env = call_instr->env();
  const intptr_t call_first_index =
      call_instr_env->Length() - call_instr->InputCount();
  const intptr_t allocate_first_index =
      allocate_object_instr_env->Length() - call_instr->InputCount();
  for (intptr_t i = 0; i < call_instr->InputCount(); i++) {
    EXPECT(call_instr_env->ValueAt(call_first_index + i)->definition() ==
           allocate_object_instr_env->ValueAt(allocate_first_index + i)
               ->definition());
  }
}

static void TestPrint(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handle = Dart_GetNativeArgument(args, 0);
  const char* str = nullptr;
  Dart_StringToCString(handle, &str);
  OS::Print("%s\n", str);
  Dart_ExitScope();
}

void InspectStack(Dart_NativeArguments args) {
#ifndef PRODUCT
  Dart_EnterScope();

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTrace(&stacktrace);
  EXPECT_VALID(result);

  intptr_t frame_count = 0;
  result = Dart_StackTraceLength(stacktrace, &frame_count);
  EXPECT_VALID(result);
  EXPECT_EQ(3, frame_count);
  // Test something bigger than the preallocated size to verify nothing was
  // truncated.
  EXPECT(102 > StackTrace::kPreallocatedStackdepth);

  Dart_Handle function_name;
  Dart_Handle script_url;
  intptr_t line_number = 0;
  intptr_t column_number = 0;
  const char* cstr = "";
  const char* test_lib = "file:///test-lib";

  // Top frame is InspectStack().
  Dart_ActivationFrame frame;
  result = Dart_GetActivationFrame(stacktrace, 0, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("InspectStack", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ(test_lib, cstr);
  EXPECT_EQ(11, line_number);
  EXPECT_EQ(24, column_number);

  // Second frame is foo() positioned at call to InspectStack().
  result = Dart_GetActivationFrame(stacktrace, 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("foo", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ(test_lib, cstr);

  // Bottom frame positioned at main().
  result = Dart_GetActivationFrame(stacktrace, frame_count - 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("main", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ(test_lib, cstr);

  // Out-of-bounds frames.
  result = Dart_GetActivationFrame(stacktrace, frame_count, &frame);
  EXPECT(Dart_IsError(result));
  result = Dart_GetActivationFrame(stacktrace, -1, &frame);
  EXPECT(Dart_IsError(result));

  Dart_SetReturnValue(args, Dart_NewInteger(42));
  Dart_ExitScope();
#endif  // !PRODUCT
}

static Dart_NativeFunction PrintAndInspectResolver(Dart_Handle name,
                                                   int argument_count,
                                                   bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  const char* cstr = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &cstr);
  EXPECT_VALID(result);
  if (strcmp(cstr, "testPrint") == 0) {
    return &TestPrint;
  } else {
    return &InspectStack;
  }
}

TEST_CASE(Inliner_InlineAndRunForceOptimized) {
  auto check_handle = [](Dart_Handle handle) {
    if (Dart_IsError(handle)) {
      OS::PrintErr("Encountered unexpected error: %s\n", Dart_GetError(handle));
      FATAL("Aborting");
    }
    return handle;
  };

  auto get_integer = [&](Dart_Handle lib, const char* name) {
    Dart_Handle handle = Dart_GetField(lib, check_handle(NewString(name)));
    check_handle(handle);

    int64_t value = 0;
    handle = Dart_IntegerToInt64(handle, &value);
    check_handle(handle);
    OS::Print("Field '%s': %" Pd64 "\n", name, value);
    return value;
  };

  const char* kScriptChars = R"(
import 'dart:ffi';
import 'dart:_internal';

int _add(int a, int b) => a + b;

@pragma('vm:external-name', "testPrint")
external void print(String s);

@pragma("vm:external-name", "InspectStack")
external InspectStack();

@pragma('vm:never-inline')
void nop() {}

int prologueCount = 0;
int epilogueCount = 0;

@pragma('vm:never-inline')
void countPrologue() {
  prologueCount++;
  print('countPrologue: $prologueCount');
}

@pragma('vm:never-inline')
void countEpilogue() {
  epilogueCount++;
  print('countEpilogue: $epilogueCount');
}

@pragma('vm:force-optimize')
@pragma('vm:idempotent')
@pragma('vm:prefer-inline')
int idempotentForceOptimizedFunction(int x) {
  countPrologue();
  print('deoptimizing');

  InspectStack();
  VMInternalsForTesting.deoptimizeFunctionsOnStack();
  InspectStack();
  print('deoptimizing after');
  countEpilogue();
  return _add(x, 1);
}

@pragma('vm:never-inline')
int foo(int x, {bool onlyOptimizeFunction = false}) {
  if (onlyOptimizeFunction) {
    print('Optimizing `foo`');
    for (int i = 0; i < 100000; i++) nop();
  }
  print('Running `foo`');
  return x + idempotentForceOptimizedFunction(x+1) + 1;
}

void main() {
  for (int i = 0; i < 100; i++) {
    print('\n\nround=$i');

    // Get the `foo` function optimized while leaving prologue/epilogue counters
    // untouched.
    final (a, b) = (prologueCount, epilogueCount);
    foo(i, onlyOptimizeFunction: true);
    prologueCount = a;
    epilogueCount = b;

    // Execute the optimized function `foo` function (which has the
    // `idempotentForceOptimizedFunction` inlined).
    final result = foo(i);
    if (result != (2 * i + 3)) throw 'Expected ${2 * i + 3} but got $result!';
  }
}
    )";
  DisableBackgroundCompilationScope scope;

  Dart_Handle lib =
      check_handle(TestCase::LoadTestScript(kScriptChars, nullptr));
  Dart_SetNativeResolver(lib, &PrintAndInspectResolver, nullptr);

  // We disable OSR to ensure we control when the function gets optimized,
  // namely afer a call to `foo(..., onlyOptimizeFunction:true)` it will be
  // optimized and during a call to `foo(...)` it will get deoptimized.
  IsolateGroup::Current()->set_use_osr(false);

  // Run the test.
  check_handle(Dart_Invoke(lib, NewString("main"), 0, nullptr));

  // Examine the result.
  const int64_t prologue_count = get_integer(lib, "prologueCount");
  const int64_t epilogue_count = get_integer(lib, "epilogueCount");

  // We always call the "foo" function when its optimized (and it's optimized
  // code has the call to `idempotentForceOptimizedFunction` inlined).
  //
  // The `idempotentForceOptimizedFunction` will always execute prologue,
  // lazy-deoptimize the `foo` frame, that will make the `foo` re-try the call
  // to `idempotentForceOptimizedFunction`.
  // = > We should see the prologue of the force-optimized function to be
  // executed twice as many times as epilogue.
  EXPECT_EQ(epilogue_count * 2, prologue_count);
}

}  // namespace dart

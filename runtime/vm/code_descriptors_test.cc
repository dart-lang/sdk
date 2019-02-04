// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"

#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/native_entry.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/unit_test.h"

namespace dart {

static void NativeFunc(Dart_NativeArguments args) {
  Dart_Handle i = Dart_GetNativeArgument(args, 0);
  Dart_Handle k = Dart_GetNativeArgument(args, 1);
  int64_t value = -1;
  EXPECT_VALID(Dart_IntegerToInt64(i, &value));
  EXPECT_EQ(10, value);
  EXPECT_VALID(Dart_IntegerToInt64(k, &value));
  EXPECT_EQ(20, value);
  {
    TransitionNativeToVM transition(Thread::Current());
    Isolate::Current()->heap()->CollectAllGarbage();
  }
}

static Dart_NativeFunction native_resolver(Dart_Handle name,
                                           int argument_count,
                                           bool* auto_setup_scope) {
  ASSERT(auto_setup_scope);
  *auto_setup_scope = false;
  return reinterpret_cast<Dart_NativeFunction>(&NativeFunc);
}

TEST_CASE(StackMapGC) {
  const char* kScriptChars =
      "class A {"
      "  static void func(var i, var k) native 'NativeFunc';"
      "  static foo() {"
      "    var i;"
      "    var s1;"
      "    var k;"
      "    var s2;"
      "    var s3;"
      "    i = 10; s1 = 'abcd'; k = 20; s2 = 'B'; s3 = 'C';"
      "    func(i, k);"
      "    return i + k; }"
      "  static int moo() {"
      "    var i = A.foo();"
      "    if (i != 30) throw '$i != 30';"
      "  }\n"
      "}\n";
  // First setup the script and compile the script.
  TestCase::LoadTestScript(kScriptChars, native_resolver);
  TransitionNativeToVM transition(thread);

  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(thread, name));
  EXPECT(!lib.IsNull());
  Class& cls =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  EXPECT(!cls.IsNull());

  // Now compile the two functions 'A.foo' and 'A.moo'
  String& function_moo_name = String::Handle(String::New("moo"));
  Function& function_moo =
      Function::Handle(cls.LookupStaticFunction(function_moo_name));
  EXPECT(CompilerTest::TestCompileFunction(function_moo));
  EXPECT(function_moo.HasCode());

  String& function_foo_name = String::Handle(String::New("foo"));
  Function& function_foo =
      Function::Handle(cls.LookupStaticFunction(function_foo_name));
  EXPECT(CompilerTest::TestCompileFunction(function_foo));
  EXPECT(function_foo.HasCode());

  // Build and setup a stackmap for the call to 'func' in 'A.foo' in order
  // to test the traversal of stack maps when a GC happens.
  StackMapTableBuilder* stackmap_table_builder = new StackMapTableBuilder();
  EXPECT(stackmap_table_builder != NULL);
  BitmapBuilder* stack_bitmap = new BitmapBuilder();
  EXPECT(stack_bitmap != NULL);
  stack_bitmap->Set(0, false);  // var i.
  stack_bitmap->Set(1, true);   // var s1.
  stack_bitmap->Set(2, false);  // var k.
  stack_bitmap->Set(3, true);   // var s2.
  stack_bitmap->Set(4, true);   // var s3.
  const Code& code = Code::Handle(function_foo.unoptimized_code());
  // Search for the pc of the call to 'func'.
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  int call_count = 0;
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kUnoptStaticCall);
  while (iter.MoveNext()) {
    stackmap_table_builder->AddEntry(iter.PcOffset(), stack_bitmap, 0);
    ++call_count;
  }
  // We can't easily check that we put the stackmap at the correct pc, but
  // we did if there was exactly one call seen.
  EXPECT(call_count == 1);
  const Array& stack_maps =
      Array::Handle(stackmap_table_builder->FinalizeStackMaps(code));
  code.set_stackmaps(stack_maps);

  // Now invoke 'A.moo' and it will trigger a GC when the native function
  // is called, this should then cause the stack map of function 'A.foo'
  // to be traversed and the appropriate objects visited.
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function_foo, Object::empty_array()));
  EXPECT(!result.IsError());
}

ISOLATE_UNIT_TEST_CASE(DescriptorList_TokenPositions) {
  DescriptorList* descriptors = new DescriptorList(64);
  ASSERT(descriptors != NULL);
  const intptr_t token_positions[] = {
      kMinInt32,
      5,
      13,
      13,
      13,
      13,
      31,
      23,
      23,
      23,
      33,
      33,
      5,
      5,
      TokenPosition::kMinSourcePos,
      TokenPosition::kMaxSourcePos,
  };
  const intptr_t num_token_positions =
      sizeof(token_positions) / sizeof(token_positions[0]);

  for (intptr_t i = 0; i < num_token_positions; i++) {
    descriptors->AddDescriptor(RawPcDescriptors::kRuntimeCall, 0, 0,
                               TokenPosition(token_positions[i]), 0);
  }

  const PcDescriptors& finalized_descriptors =
      PcDescriptors::Handle(descriptors->FinalizePcDescriptors(0));

  ASSERT(!finalized_descriptors.IsNull());
  PcDescriptors::Iterator it(finalized_descriptors,
                             RawPcDescriptors::kRuntimeCall);

  intptr_t i = 0;
  while (it.MoveNext()) {
    if (token_positions[i] != it.TokenPos().value()) {
      OS::PrintErr("[%" Pd "]: Expected: %" Pd " != %" Pd "\n", i,
                   token_positions[i], it.TokenPos().value());
    }
    EXPECT(token_positions[i] == it.TokenPos().value());
    i++;
  }
}

}  // namespace dart

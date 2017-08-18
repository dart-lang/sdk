// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_frame.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/resolver.h"
#include "vm/unit_test.h"
#include "vm/verifier.h"
#include "vm/zone.h"

namespace dart {

// Unit test for empty stack frame iteration.
ISOLATE_UNIT_TEST_CASE(EmptyStackFrameIteration) {
  StackFrameIterator iterator(StackFrameIterator::kValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  EXPECT(!iterator.HasNextFrame());
  EXPECT(iterator.NextFrame() == NULL);
  VerifyPointersVisitor::VerifyPointers();
}

// Unit test for empty dart stack frame iteration.
ISOLATE_UNIT_TEST_CASE(EmptyDartStackFrameIteration) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  EXPECT(iterator.NextFrame() == NULL);
  VerifyPointersVisitor::VerifyPointers();
}

#define FUNCTION_NAME(name) StackFrame_##name
#define REGISTER_FUNCTION(name, count) {"" #name, FUNCTION_NAME(name), count},

void FUNCTION_NAME(StackFrame_equals)(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  const Instance& expected = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Instance& actual = Instance::CheckedHandle(arguments->NativeArgAt(1));
  if (!expected.OperatorEquals(actual)) {
    OS::Print("expected: '%s' actual: '%s'\n", expected.ToCString(),
              actual.ToCString());
    FATAL("Expect_equals fails.\n");
  }
}

void FUNCTION_NAME(StackFrame_frameCount)(Dart_NativeArguments args) {
  int count = 0;
  StackFrameIterator frames(StackFrameIterator::kValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  while (frames.NextFrame() != NULL) {
    count += 1;  // Count the frame.
  }
  {
    TransitionNativeToVM transition(Thread::Current());
    VerifyPointersVisitor::VerifyPointers();
  }
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  arguments->SetReturn(Object::Handle(Smi::New(count)));
}

void FUNCTION_NAME(StackFrame_dartFrameCount)(Dart_NativeArguments args) {
  int count = 0;
  DartFrameIterator frames(Thread::Current(),
                           StackFrameIterator::kNoCrossThreadIteration);
  while (frames.NextFrame() != NULL) {
    count += 1;  // Count the dart frame.
  }
  {
    TransitionNativeToVM transition(Thread::Current());
    VerifyPointersVisitor::VerifyPointers();
  }
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  arguments->SetReturn(Object::Handle(Smi::New(count)));
}

void FUNCTION_NAME(StackFrame_validateFrame)(Dart_NativeArguments args) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  Dart_Handle index = Dart_GetNativeArgument(args, 0);
  Dart_Handle name = Dart_GetNativeArgument(args, 1);
  const Smi& frame_index_smi = Smi::CheckedHandle(Api::UnwrapHandle(index));
  const char* expected_name =
      String::CheckedHandle(Api::UnwrapHandle(name)).ToCString();
  int frame_index = frame_index_smi.Value();
  int count = 0;
  DartFrameIterator frames(Thread::Current(),
                           StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    if (count == frame_index) {
      // Find the function corresponding to this frame and check if it
      // matches the function name passed in.
      const Function& function =
          Function::Handle(zone, frame->LookupDartFunction());
      if (function.IsNull()) {
        FATAL("StackFrame_validateFrame fails, invalid dart frame.\n");
      }
      const char* name = function.ToFullyQualifiedCString();
      // Currently all unit tests are loaded as being part of dart:core-lib.
      String& url = String::Handle(zone, String::New(TestCase::url()));
      const Library& lib =
          Library::Handle(zone, Library::LookupLibrary(thread, url));
      ASSERT(!lib.IsNull());
      const char* lib_name = String::Handle(zone, lib.url()).ToCString();
      char* full_name = OS::SCreate(zone, "%s_%s", lib_name, expected_name);
      if (strcmp(full_name, name) != 0) {
        FATAL("StackFrame_validateFrame fails, incorrect frame.\n");
      }
      return;
    }
    count += 1;  // Count the dart frames.
    frame = frames.NextFrame();
  }
  FATAL("StackFrame_validateFrame fails, frame count < index passed in.\n");
}

// List all native functions implemented in the vm or core boot strap dart
// libraries so that we can resolve the native function to it's entry
// point.
#define STACKFRAME_NATIVE_LIST(V)                                              \
  V(StackFrame_equals, 2)                                                      \
  V(StackFrame_frameCount, 0)                                                  \
  V(StackFrame_dartFrameCount, 0)                                              \
  V(StackFrame_validateFrame, 2)

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {STACKFRAME_NATIVE_LIST(REGISTER_FUNCTION)};

static Dart_NativeFunction native_lookup(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  ASSERT(obj.IsString());
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  int num_entries = sizeof(BuiltinEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BuiltinEntries[i]);
    if (!strcmp(function_name, entry->name_) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return NULL;
}

// Unit test case to verify stack frame iteration.
TEST_CASE(ValidateStackFrameIteration) {
  const char* kScriptChars =
      "class StackFrame {"
      "  static equals(var obj1, var obj2) native \"StackFrame_equals\";"
      "  static int frameCount() native \"StackFrame_frameCount\";"
      "  static int dartFrameCount() native \"StackFrame_dartFrameCount\";"
      "  static validateFrame(int index,"
      "                       String name) native \"StackFrame_validateFrame\";"
      "} "
      "class First {"
      "  First() { }"
      "  int method1(int param) {"
      "    if (param == 1) {"
      "      param = method2(200);"
      "    } else {"
      "      param = method2(100);"
      "    }"
      "  }"
      "  int method2(int param) {"
      "    if (param == 200) {"
      "      First.staticmethod(this, param);"
      "    } else {"
      "      First.staticmethod(this, 10);"
      "    }"
      "  }"
      "  static int staticmethod(First obj, int param) {"
      "    if (param == 10) {"
      "      obj.method3(10);"
      "    } else {"
      "      obj.method3(200);"
      "    }"
      "  }"
      "  method3(int param) {"
      "    StackFrame.equals(9, StackFrame.frameCount());"
      "    StackFrame.equals(7, StackFrame.dartFrameCount());"
      "    StackFrame.validateFrame(0, \"StackFrame_validateFrame\");"
      "    StackFrame.validateFrame(1, \"First_method3\");"
      "    StackFrame.validateFrame(2, \"First_staticmethod\");"
      "    StackFrame.validateFrame(3, \"First_method2\");"
      "    StackFrame.validateFrame(4, \"First_method1\");"
      "    StackFrame.validateFrame(5, \"Second_method1\");"
      "    StackFrame.validateFrame(6, \"StackFrameTest_testMain\");"
      "  }"
      "}"
      "class Second {"
      "  Second() { }"
      "  int method1(int param) {"
      "    if (param == 1) {"
      "      param = method2(200);"
      "    } else {"
      "      First obj = new First();"
      "      param = obj.method1(1);"
      "      param = obj.method1(2);"
      "    }"
      "  }"
      "  int method2(int param) {"
      "    Second.staticmethod(this, param);"
      "  }"
      "  static int staticmethod(Second obj, int param) {"
      "    obj.method3(10);"
      "  }"
      "  method3(int param) {"
      "    StackFrame.equals(8, StackFrame.frameCount());"
      "    StackFrame.equals(6, StackFrame.dartFrameCount());"
      "    StackFrame.validateFrame(0, \"StackFrame_validateFrame\");"
      "    StackFrame.validateFrame(1, \"Second_method3\");"
      "    StackFrame.validateFrame(2, \"Second_staticmethod\");"
      "    StackFrame.validateFrame(3, \"Second_method2\");"
      "    StackFrame.validateFrame(4, \"Second_method1\");"
      "    StackFrame.validateFrame(5, \"StackFrameTest_testMain\");"
      "  }"
      "}"
      "class StackFrameTest {"
      "  static testMain() {"
      "    Second obj = new Second();"
      "    obj.method1(1);"
      "    obj.method1(2);"
      "  }"
      "}";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));
  Dart_Handle cls = Dart_GetClass(lib, NewString("StackFrameTest"));
  EXPECT_VALID(Dart_Invoke(cls, NewString("testMain"), 0, NULL));
}

// Unit test case to verify stack frame iteration.
TEST_CASE(ValidateNoSuchMethodStackFrameIteration) {
  const char* kScriptChars;
  // The true stack depends on which strategy we are using for noSuchMethod. The
  // stacktrace as seen by Dart is the same either way because dispatcher
  // methods are marked invisible.
  if (FLAG_lazy_dispatchers) {
    kScriptChars =
        "class StackFrame {"
        "  static equals(var obj1, var obj2) native \"StackFrame_equals\";"
        "  static int frameCount() native \"StackFrame_frameCount\";"
        "  static int dartFrameCount() native \"StackFrame_dartFrameCount\";"
        "  static validateFrame(int index,"
        "                       String name) native "
        "\"StackFrame_validateFrame\";"
        "} "
        "class StackFrame2Test {"
        "  StackFrame2Test() {}"
        "  noSuchMethod(Invocation im) {"
        "    /* We should have 6 general frames and 4 dart frames as follows:"
        "     * exit frame"
        "     * dart frame corresponding to StackFrame.frameCount"
        "     * dart frame corresponding to StackFrame2Test.noSuchMethod"
        "     * frame for instance function invocation stub calling "
        "noSuchMethod"
        "     * dart frame corresponding to StackFrame2Test.testMain"
        "     * entry frame"
        "     */"
        "    StackFrame.equals(6, StackFrame.frameCount());"
        "    StackFrame.equals(4, StackFrame.dartFrameCount());"
        "    StackFrame.validateFrame(0, \"StackFrame_validateFrame\");"
        "    StackFrame.validateFrame(1, \"StackFrame2Test_noSuchMethod\");"
        "    StackFrame.validateFrame(2, \"StackFrame2Test_foo\");"
        "    StackFrame.validateFrame(3, \"StackFrame2Test_testMain\");"
        "    return 5;"
        "  }"
        "  static testMain() {"
        "    var obj = new StackFrame2Test();"
        "    StackFrame.equals(5, obj.foo(101, 202));"
        "  }"
        "}";
  } else {
    kScriptChars =
        "class StackFrame {"
        "  static equals(var obj1, var obj2) native \"StackFrame_equals\";"
        "  static int frameCount() native \"StackFrame_frameCount\";"
        "  static int dartFrameCount() native \"StackFrame_dartFrameCount\";"
        "  static validateFrame(int index,"
        "                       String name) native "
        "\"StackFrame_validateFrame\";"
        "} "
        "class StackFrame2Test {"
        "  StackFrame2Test() {}"
        "  noSuchMethod(Invocation im) {"
        "    /* We should have 8 general frames and 3 dart frames as follows:"
        "     * exit frame"
        "     * dart frame corresponding to StackFrame.frameCount"
        "     * dart frame corresponding to StackFrame2Test.noSuchMethod"
        "     * entry frame"
        "     * exit frame (call to runtime InvokeNoSuchMethodDispatcher)"
        "     * IC stub"
        "     * dart frame corresponding to StackFrame2Test.testMain"
        "     * entry frame"
        "     */"
        "    StackFrame.equals(8, StackFrame.frameCount());"
        "    StackFrame.equals(3, StackFrame.dartFrameCount());"
        "    StackFrame.validateFrame(0, \"StackFrame_validateFrame\");"
        "    StackFrame.validateFrame(1, \"StackFrame2Test_noSuchMethod\");"
        "    StackFrame.validateFrame(2, \"StackFrame2Test_testMain\");"
        "    return 5;"
        "  }"
        "  static testMain() {"
        "    var obj = new StackFrame2Test();"
        "    StackFrame.equals(5, obj.foo(101, 202));"
        "  }"
        "}";
  }
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));
  Dart_Handle cls = Dart_GetClass(lib, NewString("StackFrame2Test"));
  EXPECT_VALID(Dart_Invoke(cls, NewString("testMain"), 0, NULL));
}

}  // namespace dart

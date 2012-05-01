// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/benchmark_test.h"

#include "bin/file.h"

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/stack_frame.h"
#include "vm/unit_test.h"

namespace dart {

Benchmark* Benchmark::first_ = NULL;
Benchmark* Benchmark::tail_ = NULL;
const char* Benchmark::executable_ = NULL;

void Benchmark::RunAll(const char* executable) {
  SetExecutable(executable);
  Benchmark* benchmark = first_;
  while (benchmark != NULL) {
    benchmark->RunBenchmark();
    benchmark = benchmark->next_;
  }
}


// Compiler only implemented on IA32 and X64 now.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)


//
// Measure compile of all functions in dart core lib classes.
//
BENCHMARK(CorelibCompileAll) {
  Timer timer(true, "Compile all of Core lib benchmark");
  timer.Start();
  const Error& error = Error::Handle(benchmark->isolate(),
                                     Library::CompileAll());
  EXPECT(error.IsNull());
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

#endif  // TARGET_ARCH_IA32 || TARGET_ARCH_X64


//
// Measure creation of core isolate from a snapshot.
//
BENCHMARK(CorelibIsolateStartup) {
  const int kNumIterations = 100;
  char* err = NULL;
  Dart_Isolate base_isolate = Dart_CurrentIsolate();
  Dart_Isolate test_isolate = Dart_CreateIsolate(NULL, NULL, NULL, &err);
  EXPECT(test_isolate != NULL);
  Dart_EnterScope();
  uint8_t* buffer = NULL;
  intptr_t size = 0;
  Dart_Handle result = Dart_CreateSnapshot(&buffer, &size);
  EXPECT(!Dart_IsError(result));
  Timer timer(true, "Core Isolate startup benchmark");
  timer.Start();
  for (int i = 0; i < kNumIterations; i++) {
    Dart_Isolate new_isolate = Dart_CreateIsolate(NULL, buffer, NULL, &err);
    EXPECT(new_isolate != NULL);
    Dart_ShutdownIsolate();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time / kNumIterations);
  Dart_EnterIsolate(test_isolate);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  Dart_EnterIsolate(base_isolate);
}


//
// Measure invocation of Dart API functions.
//
static void InitNativeFields(Dart_NativeArguments args) {
  Dart_EnterScope();
  int count = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(1, count);

  Dart_Handle recv = Dart_GetNativeArgument(args, 0);
  EXPECT(!Dart_IsError(recv));
  Dart_Handle result = Dart_SetNativeInstanceField(recv, 0, 7);
  EXPECT(!Dart_IsError(result));

  Dart_ExitScope();
}


// The specific api functions called here are a bit arbitrary.  We are
// trying to get a sense of the overhead for using the dart api.
static void UseDartApi(Dart_NativeArguments args) {
  Dart_EnterScope();
  int count = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(3, count);

  // Get the receiver.
  Dart_Handle recv = Dart_GetNativeArgument(args, 0);
  EXPECT(!Dart_IsError(recv));

  // Get param1.
  Dart_Handle param1 = Dart_GetNativeArgument(args, 1);
  EXPECT(!Dart_IsError(param1));
  EXPECT(Dart_IsInteger(param1));
  bool fits = false;
  Dart_Handle result = Dart_IntegerFitsIntoInt64(param1, &fits);
  EXPECT(!Dart_IsError(result) && fits);
  int64_t value1;
  result = Dart_IntegerToInt64(param1, &value1);
  EXPECT(!Dart_IsError(result));
  EXPECT_LE(0, value1);
  EXPECT_LE(value1, 1000000);

  // Get native field from receiver.
  intptr_t value2;
  result = Dart_GetNativeInstanceField(recv, 0, &value2);
  EXPECT(!Dart_IsError(result));
  EXPECT_EQ(7, value2);

  // Return param + receiver.field.
  Dart_SetReturnValue(args, Dart_NewInteger(value1 * value2));
  Dart_ExitScope();
}


static Dart_NativeFunction bm_uda_lookup(Dart_Handle name, int argument_count) {
  const char* cstr = NULL;
  Dart_Handle result = Dart_StringToCString(name, &cstr);
  EXPECT(!Dart_IsError(result));
  if (strcmp(cstr, "init") == 0) {
    return InitNativeFields;
  } else {
    return UseDartApi;
  }
}


BENCHMARK(UseDartApi) {
  const int kNumIterations = 100000;
  const char* kScriptChars =
      "class Class extends NativeFieldsWrapper{\n"
      "  int init() native 'init';\n"
      "  int method(int param1, int param2) native 'method';\n"
      "}\n"
      "\n"
      "void benchmark(int count) {\n"
      "  Class c = new Class();\n"
      "  c.init();\n"
      "  for (int i = 0; i < count; i++) {\n"
      "    c.method(i,7);\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(bm_uda_lookup));

  // Create a native wrapper class with native fields.
  Dart_Handle result = Dart_CreateNativeWrapperClass(
      lib,
      Dart_NewString("NativeFieldsWrapper"),
      1);
  EXPECT(!Dart_IsError(result));

  Timer timer(true, "UseDartApi benchmark");
  timer.Start();
  Dart_Handle args[1];
  args[0] = Dart_NewInteger(kNumIterations);
  Dart_Invoke(lib,
              Dart_NewString("benchmark"),
              1,
              args);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}


//
// Measure compile of all dart2js(compiler) functions.
//
static char* ComputeDart2JSPath(const char* arg) {
  char buffer[2048];
  char* dart2js_path = strdup(File::GetCanonicalPath(arg));
  const char* compiler_path = "%s%slib%scompiler%scompiler.dart";
  const char* path_separator = File::PathSeparator();
  ASSERT(path_separator != NULL && strlen(path_separator) == 1);
  char* ptr = strrchr(dart2js_path, *path_separator);
  while (ptr != NULL) {
    *ptr = '\0';
    OS::SNPrint(buffer, 2048, compiler_path,
                dart2js_path,
                path_separator,
                path_separator,
                path_separator);
    if (File::Exists(buffer)) {
      break;
    }
    ptr = strrchr(dart2js_path, *path_separator);
  }
  if (ptr == NULL) {
    free(dart2js_path);
    dart2js_path = NULL;
  }
  return dart2js_path;
}


static void func(Dart_NativeArguments args) {
}


static Dart_NativeFunction NativeResolver(Dart_Handle name,
                                          int arg_count) {
  return &func;
}


BENCHMARK(Dart2JSCompileAll) {
  char* dart_root = ComputeDart2JSPath(Benchmark::Executable());
  Dart_Handle import_map;
  if (dart_root != NULL) {
    import_map = Dart_NewList(2);
    Dart_ListSetAt(import_map, 0, Dart_NewString("DART_ROOT"));
    Dart_ListSetAt(import_map, 1, Dart_NewString(dart_root));
  } else {
    import_map = Dart_NewList(0);
  }
  const char* kScriptChars =
      "#import('${DART_ROOT}/lib/compiler/compiler.dart');";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(NativeResolver),
      import_map);
  EXPECT(!Dart_IsError(lib));
  Timer timer(true, "Compile all of dart2js benchmark");
  timer.Start();
  Dart_Handle result = Dart_CompileAll();
  EXPECT(!Dart_IsError(result));
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
  free(dart_root);
}


//
// Measure frame lookup during stack traversal.
//
static void StackFrame_accessFrame(Dart_NativeArguments args) {
  const int kNumIterations = 100;
  Dart_EnterScope();
  Code& code = Code::Handle();
  Timer timer(true, "LookupDartCode benchmark");
  timer.Start();
  for (int i = 0; i < kNumIterations; i++) {
    StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
    StackFrame* frame = frames.NextFrame();
    while (frame != NULL) {
      if (frame->IsStubFrame()) {
        code ^= frame->LookupDartCode();
        EXPECT(code.function() == Function::null());
      } else if (frame->IsDartFrame()) {
        code ^= frame->LookupDartCode();
        EXPECT(code.function() != Function::null());
      }
      frame = frames.NextFrame();
    }
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  Dart_SetReturnValue(args, Dart_NewInteger(elapsed_time));
  Dart_ExitScope();
}


static Dart_NativeFunction StackFrameNativeResolver(Dart_Handle name,
                                                    int arg_count) {
  return &StackFrame_accessFrame;
}


// Unit test case to verify stack frame iteration.
BENCHMARK(FrameLookup) {
  const char* kScriptChars =
      "class StackFrame {"
      "  static int accessFrame() native \"StackFrame_accessFrame\";"
      "} "
      "class First {"
      "  First() { }"
      "  int method1(int param) {"
      "    if (param == 1) {"
      "      param = method2(200);"
      "    } else {"
      "      param = method2(100);"
      "    }"
      "    return param;"
      "  }"
      "  int method2(int param) {"
      "    if (param == 200) {"
      "      return First.staticmethod(this, param);"
      "    } else {"
      "      return First.staticmethod(this, 10);"
      "    }"
      "  }"
      "  static int staticmethod(First obj, int param) {"
      "    if (param == 10) {"
      "      return obj.method3(10);"
      "    } else {"
      "      return obj.method3(200);"
      "    }"
      "  }"
      "  int method3(int param) {"
      "    return StackFrame.accessFrame();"
      "  }"
      "}"
      "class StackFrameTest {"
      "  static int testMain() {"
      "    First obj = new First();"
      "    return obj.method1(1);"
      "  }"
      "}";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(StackFrameNativeResolver));
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("StackFrameTest"));
  Dart_Handle result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  int64_t elapsed_time = 0;
  EXPECT(!Dart_IsError(Dart_IntegerToInt64(result, &elapsed_time)));
  benchmark->set_score(elapsed_time);
}

}  // namespace dart

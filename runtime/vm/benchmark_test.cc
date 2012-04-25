// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/benchmark_test.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

Benchmark* Benchmark::first_ = NULL;
Benchmark* Benchmark::tail_ = NULL;

void Benchmark::RunAll() {
  Benchmark* benchmark = first_;
  while (benchmark != NULL) {
    benchmark->RunBenchmark();
    benchmark = benchmark->next_;
  }
}


// Compiler only implemented on IA32 and X64 now.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

BENCHMARK(CorelibCompileAll) {
  Timer timer(true, "Compile all benchmark");
  timer.Start();
  const Error& error = Error::Handle(benchmark->isolate(),
                                     Library::CompileAll());
  EXPECT(error.IsNull());
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

#endif  // TARGET_ARCH_IA32 || TARGET_ARCH_X64


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


void InitNativeFields(Dart_NativeArguments args) {
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
void UseDartApi(Dart_NativeArguments args) {
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

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/benchmark_test.h"
#include "vm/dart_api_impl.h"

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
  Dart_EnterIsolate(test_isolate);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  Dart_EnterIsolate(base_isolate);
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time / kNumIterations);
}

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BENCHMARK_TEST_H_
#define VM_BENCHMARK_TEST_H_

#include "include/dart_api.h"

#include "vm/dart.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(int, code_heap_size);
DECLARE_FLAG(int, heap_growth_space_ratio);

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
namespace bin {
extern const uint8_t* snapshot_buffer;
}

// The BENCHMARK macros are used for benchmarking a specific functionality
// of the VM.
#define BENCHMARK_HELPER(name, kind)                                           \
  void Dart_Benchmark##name(Benchmark* benchmark);                             \
  static Benchmark kRegister##name(Dart_Benchmark##name, #name, kind);         \
  static void Dart_BenchmarkHelper##name(Benchmark* benchmark);                \
  void Dart_Benchmark##name(Benchmark* benchmark) {                            \
    FLAG_heap_growth_space_ratio = 100;                                        \
    BenchmarkIsolateScope __isolate__(benchmark);                              \
    StackZone __zone__(benchmark->isolate());                                  \
    HandleScope __hs__(benchmark->isolate());                                  \
    Dart_BenchmarkHelper##name(benchmark);                                     \
  }                                                                            \
  static void Dart_BenchmarkHelper##name(Benchmark* benchmark)

#define BENCHMARK(name) BENCHMARK_HELPER(name, "RunTime")
#define BENCHMARK_SIZE(name) BENCHMARK_HELPER(name, "CodeSize")


inline Dart_Handle NewString(const char* str) {
  return Dart_NewStringFromCString(str);
}


class Benchmark {
 public:
  typedef void (RunEntry)(Benchmark* benchmark);

  Benchmark(RunEntry* run, const char* name, const char* score_kind) :
      run_(run),
      name_(name),
      score_kind_(score_kind),
      score_(0),
      isolate_(NULL),
      next_(NULL) {
    if (first_ == NULL) {
      first_ = this;
    } else {
      tail_->next_ = this;
    }
    tail_ = this;
  }

  // Accessors.
  const char* name() const { return name_; }
  const char* score_kind() const { return score_kind_; }
  void set_score(intptr_t value) { score_ = value; }
  intptr_t score() const { return score_; }
  Isolate* isolate() const { return reinterpret_cast<Isolate*>(isolate_); }

  Dart_Isolate CreateIsolate(const uint8_t* buffer) {
    char* err = NULL;
    isolate_ = Dart_CreateIsolate(NULL, NULL, buffer, NULL, &err);
    EXPECT(isolate_ != NULL);
    free(err);
    return isolate_;
  }

  void Run() { (*run_)(this); }
  void RunBenchmark();

  static void RunAll(const char* executable);
  static void SetExecutable(const char* arg) { executable_ = arg; }
  static const char* Executable() { return executable_; }

 private:
  static Benchmark* first_;
  static Benchmark* tail_;
  static const char* executable_;

  RunEntry* const run_;
  const char* name_;
  const char* score_kind_;
  intptr_t score_;
  Dart_Isolate isolate_;
  Benchmark* next_;

  DISALLOW_COPY_AND_ASSIGN(Benchmark);
};


class BenchmarkIsolateScope {
 public:
  explicit BenchmarkIsolateScope(Benchmark* benchmark) : benchmark_(benchmark) {
    benchmark_->CreateIsolate(bin::snapshot_buffer);
    Dart_EnterScope();  // Create a Dart API scope for unit benchmarks.
  }
  ~BenchmarkIsolateScope() {
    Dart_ExitScope();  // Exit the Dart API scope created for unit tests.
    ASSERT(benchmark_->isolate() == Isolate::Current());
    Dart_ShutdownIsolate();
    benchmark_ = NULL;
  }
  Benchmark* benchmark() const { return benchmark_; }

 private:
  Benchmark* benchmark_;

  DISALLOW_COPY_AND_ASSIGN(BenchmarkIsolateScope);
};

}  // namespace dart

#endif  // VM_BENCHMARK_TEST_H_

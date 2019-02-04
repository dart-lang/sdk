// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BENCHMARK_TEST_H_
#define RUNTIME_VM_BENCHMARK_TEST_H_

#include "include/dart_api.h"

#include "vm/dart.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/malloc_hooks.h"
#include "vm/object.h"
#include "vm/unit_test.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(int, code_heap_size);
DECLARE_FLAG(int, old_gen_growth_space_ratio);

namespace bin {
// Snapshot pieces if we link in a snapshot, otherwise initialized to NULL.
extern const uint8_t* vm_snapshot_data;
extern const uint8_t* vm_snapshot_instructions;
extern const uint8_t* core_isolate_snapshot_data;
extern const uint8_t* core_isolate_snapshot_instructions;
}  // namespace bin

// The BENCHMARK macros are used for benchmarking a specific functionality
// of the VM.
#define BENCHMARK_HELPER(name, kind)                                           \
  void Dart_Benchmark##name(Benchmark* benchmark);                             \
  static Benchmark kRegister##name(Dart_Benchmark##name, #name, kind);         \
  static void Dart_BenchmarkHelper##name(Benchmark* benchmark,                 \
                                         Thread* thread);                      \
  void Dart_Benchmark##name(Benchmark* benchmark) {                            \
    bool __stack_trace_collection_enabled__ =                                  \
        MallocHooks::stack_trace_collection_enabled();                         \
    MallocHooks::set_stack_trace_collection_enabled(false);                    \
    FLAG_old_gen_growth_space_ratio = 100;                                     \
    BenchmarkIsolateScope __isolate__(benchmark);                              \
    Thread* __thread__ = Thread::Current();                                    \
    ASSERT(__thread__->isolate() == benchmark->isolate());                     \
    Dart_BenchmarkHelper##name(benchmark, __thread__);                         \
    MallocHooks::set_stack_trace_collection_enabled(                           \
        __stack_trace_collection_enabled__);                                   \
  }                                                                            \
  static void Dart_BenchmarkHelper##name(Benchmark* benchmark, Thread* thread)

#define BENCHMARK(name) BENCHMARK_HELPER(name, "RunTime")
#define BENCHMARK_SIZE(name) BENCHMARK_HELPER(name, "CodeSize")
#define BENCHMARK_MEMORY(name) BENCHMARK_HELPER(name, "MemoryUse")

inline Dart_Handle NewString(const char* str) {
  return Dart_NewStringFromCString(str);
}

class Benchmark {
 public:
  typedef void(RunEntry)(Benchmark* benchmark);

  Benchmark(RunEntry* run, const char* name, const char* score_kind)
      : run_(run),
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
  void set_score(int64_t value) { score_ = value; }
  int64_t score() const { return score_; }
  Isolate* isolate() const { return reinterpret_cast<Isolate*>(isolate_); }

  void Run() { (*run_)(this); }
  void RunBenchmark();

  static void RunAll(const char* executable);
  static void SetExecutable(const char* arg) { executable_ = arg; }
  static const char* Executable() { return executable_; }

  void CreateIsolate() {
    isolate_ = TestCase::CreateTestIsolate();
    EXPECT(isolate_ != NULL);
  }

 private:
  static Benchmark* first_;
  static Benchmark* tail_;
  static const char* executable_;

  RunEntry* const run_;
  const char* name_;
  const char* score_kind_;
  int64_t score_;
  Dart_Isolate isolate_;
  Benchmark* next_;

  DISALLOW_COPY_AND_ASSIGN(Benchmark);
};

class BenchmarkIsolateScope {
 public:
  explicit BenchmarkIsolateScope(Benchmark* benchmark) : benchmark_(benchmark) {
    benchmark->CreateIsolate();
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

#endif  // RUNTIME_VM_BENCHMARK_TEST_H_

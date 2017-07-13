// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/benchmark_test.h"

#include "bin/builtin.h"
#include "bin/file.h"
#include "bin/isolate_data.h"

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/clustered_snapshot.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_impl.h"
#include "vm/stack_frame.h"
#include "vm/unit_test.h"

using dart::bin::File;

namespace dart {

Benchmark* Benchmark::first_ = NULL;
Benchmark* Benchmark::tail_ = NULL;
const char* Benchmark::executable_ = NULL;

//
// Measure compile of all dart2js(compiler) functions.
//
static char* ComputeDart2JSPath(const char* arg) {
  char buffer[2048];
  char* dart2js_path = strdup(File::GetCanonicalPath(arg));
  const char* compiler_path = "%s%spkg%scompiler%slib%scompiler.dart";
  const char* path_separator = File::PathSeparator();
  ASSERT(path_separator != NULL && strlen(path_separator) == 1);
  char* ptr = strrchr(dart2js_path, *path_separator);
  while (ptr != NULL) {
    *ptr = '\0';
    OS::SNPrint(buffer, 2048, compiler_path, dart2js_path, path_separator,
                path_separator, path_separator, path_separator, path_separator);
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

static void func(Dart_NativeArguments args) {}

static Dart_NativeFunction NativeResolver(Dart_Handle name,
                                          int arg_count,
                                          bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &func;
}

static void SetupDart2JSPackagePath() {
  bool worked = bin::DartUtils::SetOriginalWorkingDirectory();
  EXPECT(worked);

  Dart_Handle result = bin::DartUtils::PrepareForScriptLoading(false, false);
  DART_CHECK_VALID(result);

  // Setup package root.
  char buffer[2048];
  char* executable_path =
      strdup(File::GetCanonicalPath(Benchmark::Executable()));
  const char* packages_path = "%s%s..%spackages";
  const char* path_separator = File::PathSeparator();
  OS::SNPrint(buffer, 2048, packages_path, executable_path, path_separator,
              path_separator);
  result = bin::DartUtils::SetupPackageRoot(buffer, NULL);
  DART_CHECK_VALID(result);
}

void Benchmark::RunAll(const char* executable) {
  SetExecutable(executable);
  Benchmark* benchmark = first_;
  while (benchmark != NULL) {
    benchmark->RunBenchmark();
    benchmark = benchmark->next_;
  }
}

Dart_Isolate Benchmark::CreateIsolate(const uint8_t* snapshot_data,
                                      const uint8_t* snapshot_instructions) {
  char* err = NULL;
  isolate_ = Dart_CreateIsolate(NULL, NULL, snapshot_data,
                                snapshot_instructions, NULL, NULL, &err);
  EXPECT(isolate_ != NULL);
  free(err);
  return isolate_;
}

//
// Measure compile of all functions in dart core lib classes.
//
BENCHMARK(CorelibCompileAll) {
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  TransitionNativeToVM transition(thread);
  Timer timer(true, "Compile all of Core lib benchmark");
  timer.Start();
  const Error& error = Error::Handle(Library::CompileAll());
  if (!error.IsNull()) {
    OS::PrintErr("Unexpected error in CorelibCompileAll benchmark:\n%s",
                 error.ToErrorCString());
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

#ifndef PRODUCT

BENCHMARK(CorelibCompilerStats) {
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  TransitionNativeToVM transition(thread);
  CompilerStats* stats = thread->isolate()->aggregate_compiler_stats();
  ASSERT(stats != NULL);
  stats->EnableBenchmark();
  Timer timer(true, "Compiler stats compiling all of Core lib");
  timer.Start();
  const Error& error = Error::Handle(Library::CompileAll());
  if (!error.IsNull()) {
    OS::PrintErr("Unexpected error in CorelibCompileAll benchmark:\n%s",
                 error.ToErrorCString());
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(Dart2JSCompilerStats) {
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  SetupDart2JSPackagePath();
  char* dart_root = ComputeDart2JSPath(Benchmark::Executable());
  char* script = NULL;
  if (dart_root != NULL) {
    HANDLESCOPE(thread);
    script = OS::SCreate(NULL, "import '%s/pkg/compiler/lib/compiler.dart';",
                         dart_root);
    Dart_Handle lib = TestCase::LoadTestScript(
        script, reinterpret_cast<Dart_NativeEntryResolver>(NativeResolver));
    EXPECT_VALID(lib);
  } else {
    Dart_Handle lib = TestCase::LoadTestScript(
        "import 'pkg/compiler/lib/compiler.dart';",
        reinterpret_cast<Dart_NativeEntryResolver>(NativeResolver));
    EXPECT_VALID(lib);
  }
  CompilerStats* stats = thread->isolate()->aggregate_compiler_stats();
  ASSERT(stats != NULL);
  stats->EnableBenchmark();
  Timer timer(true, "Compile all of dart2js benchmark");
  timer.Start();
#if !defined(PRODUCT)
  // Constant in product mode.
  const bool old_flag = FLAG_background_compilation;
  FLAG_background_compilation = false;
#endif
  Dart_Handle result = Dart_CompileAll();
#if !defined(PRODUCT)
  FLAG_background_compilation = old_flag;
#endif
  EXPECT_VALID(result);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
  free(dart_root);
  free(script);
}

#endif  // !PRODUCT

//
// Measure creation of core isolate from a snapshot.
//
BENCHMARK(CorelibIsolateStartup) {
  const int kNumIterations = 1000;
  Timer timer(true, "CorelibIsolateStartup");
  Isolate* isolate = thread->isolate();
  Dart_ExitIsolate();
  for (int i = 0; i < kNumIterations; i++) {
    timer.Start();
    TestCase::CreateTestIsolate();
    timer.Stop();
    Dart_ShutdownIsolate();
  }
  benchmark->set_score(timer.TotalElapsedTime() / kNumIterations);
  Dart_EnterIsolate(reinterpret_cast<Dart_Isolate>(isolate));
}

//
// Measure invocation of Dart API functions.
//
static void InitNativeFields(Dart_NativeArguments args) {
  Dart_EnterScope();
  int count = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(1, count);

  Dart_Handle recv = Dart_GetNativeArgument(args, 0);
  EXPECT_VALID(recv);
  Dart_Handle result = Dart_SetNativeInstanceField(recv, 0, 7);
  EXPECT_VALID(result);

  Dart_ExitScope();
}

// The specific api functions called here are a bit arbitrary.  We are
// trying to get a sense of the overhead for using the dart api.
static void UseDartApi(Dart_NativeArguments args) {
  int count = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(3, count);

  // Get native field from receiver.
  intptr_t receiver_value;
  Dart_Handle result = Dart_GetNativeReceiver(args, &receiver_value);
  EXPECT_VALID(result);
  EXPECT_EQ(7, receiver_value);

  // Get param1.
  Dart_Handle param1 = Dart_GetNativeArgument(args, 1);
  EXPECT_VALID(param1);
  EXPECT(Dart_IsInteger(param1));
  bool fits = false;
  result = Dart_IntegerFitsIntoInt64(param1, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);
  int64_t value1;
  result = Dart_IntegerToInt64(param1, &value1);
  EXPECT_VALID(result);
  EXPECT_LE(0, value1);
  EXPECT_LE(value1, 1000000);

  // Return param + receiver.field.
  Dart_SetReturnValue(args, Dart_NewInteger(value1 * receiver_value));
}

static Dart_NativeFunction bm_uda_lookup(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  const char* cstr = NULL;
  Dart_Handle result = Dart_StringToCString(name, &cstr);
  EXPECT_VALID(result);
  if (strcmp(cstr, "init") == 0) {
    return InitNativeFields;
  } else {
    return UseDartApi;
  }
}

BENCHMARK(UseDartApi) {
  const int kNumIterations = 1000000;
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
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(bm_uda_lookup),
      USER_TEST_URI, false);

  // Create a native wrapper class with native fields.
  Dart_Handle result =
      Dart_CreateNativeWrapperClass(lib, NewString("NativeFieldsWrapper"), 1);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  Dart_Handle args[1];
  args[0] = Dart_NewInteger(kNumIterations);

  // Warmup first to avoid compilation jitters.
  Dart_Invoke(lib, NewString("benchmark"), 1, args);

  Timer timer(true, "UseDartApi benchmark");
  timer.Start();
  Dart_Invoke(lib, NewString("benchmark"), 1, args);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

//
// Measure time accessing internal and external strings.
//
BENCHMARK(DartStringAccess) {
  const int kNumIterations = 10000000;
  Timer timer(true, "DartStringAccess benchmark");
  timer.Start();
  Dart_EnterScope();

  // Create strings.
  uint8_t data8[] = {'o', 'n', 'e', 0xFF};
  int external_peer_data = 123;
  intptr_t char_size;
  intptr_t str_len;
  Dart_Handle external_string = Dart_NewExternalLatin1String(
      data8, ARRAY_SIZE(data8), &external_peer_data, NULL);
  Dart_Handle internal_string = NewString("two");

  // Run benchmark.
  for (int64_t i = 0; i < kNumIterations; i++) {
    EXPECT(Dart_IsString(internal_string));
    EXPECT(!Dart_IsExternalString(internal_string));
    EXPECT_VALID(external_string);
    EXPECT(Dart_IsExternalString(external_string));
    void* external_peer = NULL;
    EXPECT_VALID(Dart_StringGetProperties(external_string, &char_size, &str_len,
                                          &external_peer));
    EXPECT_EQ(1, char_size);
    EXPECT_EQ(4, str_len);
    EXPECT_EQ(&external_peer_data, external_peer);
  }

  Dart_ExitScope();
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(Dart2JSCompileAll) {
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  SetupDart2JSPackagePath();
  char* dart_root = ComputeDart2JSPath(Benchmark::Executable());
  char* script = NULL;
  if (dart_root != NULL) {
    HANDLESCOPE(thread);
    script = OS::SCreate(NULL, "import '%s/pkg/compiler/lib/compiler.dart';",
                         dart_root);
    Dart_Handle lib = TestCase::LoadTestScript(
        script, reinterpret_cast<Dart_NativeEntryResolver>(NativeResolver));
    EXPECT_VALID(lib);
  } else {
    Dart_Handle lib = TestCase::LoadTestScript(
        "import 'pkg/compiler/lib/compiler.dart';",
        reinterpret_cast<Dart_NativeEntryResolver>(NativeResolver));
    EXPECT_VALID(lib);
  }
  Timer timer(true, "Compile all of dart2js benchmark");
  timer.Start();
#if !defined(PRODUCT)
  const bool old_flag = FLAG_background_compilation;
  FLAG_background_compilation = false;
#endif
  Dart_Handle result = Dart_CompileAll();
#if !defined(PRODUCT)
  FLAG_background_compilation = old_flag;
#endif
  EXPECT_VALID(result);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
  free(dart_root);
  free(script);
}

//
// Measure frame lookup during stack traversal.
//
static void StackFrame_accessFrame(Dart_NativeArguments args) {
  const int kNumIterations = 100;
  Code& code = Code::Handle();
  Timer timer(true, "LookupDartCode benchmark");
  timer.Start();
  for (int i = 0; i < kNumIterations; i++) {
    StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = frames.NextFrame();
    while (frame != NULL) {
      if (frame->IsStubFrame()) {
        code = frame->LookupDartCode();
        EXPECT(code.function() == Function::null());
      } else if (frame->IsDartFrame()) {
        code = frame->LookupDartCode();
        EXPECT(code.function() != Function::null());
      }
      frame = frames.NextFrame();
    }
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  Dart_SetReturnValue(args, Dart_NewInteger(elapsed_time));
}

static Dart_NativeFunction StackFrameNativeResolver(Dart_Handle name,
                                                    int arg_count,
                                                    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
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
  Dart_Handle cls = Dart_GetClass(lib, NewString("StackFrameTest"));
  Dart_Handle result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  int64_t elapsed_time = 0;
  result = Dart_IntegerToInt64(result, &elapsed_time);
  EXPECT_VALID(result);
  benchmark->set_score(elapsed_time);
}

static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  return reinterpret_cast<uint8_t*>(realloc(ptr, new_size));
}

static void malloc_deallocator(uint8_t* ptr) {
  free(ptr);
}

BENCHMARK_SIZE(CoreSnapshotSize) {
  const char* kScriptChars =
      "import 'dart:async';\n"
      "import 'dart:core';\n"
      "import 'dart:collection';\n"
      "import 'dart:_internal';\n"
      "import 'dart:math';\n"
      "import 'dart:isolate';\n"
      "import 'dart:mirrors';\n"
      "import 'dart:typed_data';\n"
      "\n";

  // Start an Isolate, load a script and create a full snapshot.
  uint8_t* vm_snapshot_data_buffer;
  uint8_t* isolate_snapshot_data_buffer;
  // Need to load the script into the dart: core library due to
  // the import of dart:_internal.
  TestCase::LoadCoreTestScript(kScriptChars, NULL);
  Api::CheckAndFinalizePendingClasses(thread);

  // Write snapshot with object content.
  FullSnapshotWriter writer(Snapshot::kFull, &vm_snapshot_data_buffer,
                            &isolate_snapshot_data_buffer, &malloc_allocator,
                            NULL, NULL /* image_writer */);
  writer.WriteFullSnapshot();
  const Snapshot* snapshot =
      Snapshot::SetupFromBuffer(isolate_snapshot_data_buffer);
  ASSERT(snapshot->kind() == Snapshot::kFull);
  benchmark->set_score(snapshot->length());

  free(vm_snapshot_data_buffer);
  free(isolate_snapshot_data_buffer);
}

BENCHMARK_SIZE(StandaloneSnapshotSize) {
  const char* kScriptChars =
      "import 'dart:async';\n"
      "import 'dart:core';\n"
      "import 'dart:collection';\n"
      "import 'dart:_internal';\n"
      "import 'dart:convert';\n"
      "import 'dart:math';\n"
      "import 'dart:isolate';\n"
      "import 'dart:mirrors';\n"
      "import 'dart:typed_data';\n"
      "import 'dart:_builtin';\n"
      "import 'dart:io';\n"
      "\n";

  // Start an Isolate, load a script and create a full snapshot.
  uint8_t* vm_snapshot_data_buffer;
  uint8_t* isolate_snapshot_data_buffer;
  // Need to load the script into the dart: core library due to
  // the import of dart:_internal.
  TestCase::LoadCoreTestScript(kScriptChars, NULL);
  Api::CheckAndFinalizePendingClasses(thread);

  // Write snapshot with object content.
  FullSnapshotWriter writer(Snapshot::kFull, &vm_snapshot_data_buffer,
                            &isolate_snapshot_data_buffer, &malloc_allocator,
                            NULL, NULL /* image_writer */);
  writer.WriteFullSnapshot();
  const Snapshot* snapshot =
      Snapshot::SetupFromBuffer(isolate_snapshot_data_buffer);
  ASSERT(snapshot->kind() == Snapshot::kFull);
  benchmark->set_score(snapshot->length());

  free(vm_snapshot_data_buffer);
  free(isolate_snapshot_data_buffer);
}

BENCHMARK(CreateMirrorSystem) {
  const char* kScriptChars =
      "import 'dart:mirrors';\n"
      "\n"
      "void benchmark() {\n"
      "  currentMirrorSystem();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Timer timer(true, "currentMirrorSystem() benchmark");
  timer.Start();
  Dart_Invoke(lib, NewString("benchmark"), 0, NULL);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(EnterExitIsolate) {
  const char* kScriptChars =
      "import 'dart:core';\n"
      "\n";
  const intptr_t kLoopCount = 1000000;
  TestCase::LoadTestScript(kScriptChars, NULL);
  Api::CheckAndFinalizePendingClasses(thread);
  Dart_Isolate isolate = Dart_CurrentIsolate();
  Timer timer(true, "Enter and Exit isolate");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    Dart_ExitIsolate();
    Dart_EnterIsolate(isolate);
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

static uint8_t message_buffer[64];
static uint8_t* message_allocator(uint8_t* ptr,
                                  intptr_t old_size,
                                  intptr_t new_size) {
  return message_buffer;
}
static void message_deallocator(uint8_t* ptr) {}

BENCHMARK(SerializeNull) {
  const Object& null_object = Object::Handle();
  const intptr_t kLoopCount = 1000000;
  uint8_t* buffer;
  Timer timer(true, "Serialize Null");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(&buffer, &message_allocator, &message_deallocator,
                         true);
    writer.WriteMessage(null_object);
    intptr_t buffer_len = writer.BytesWritten();

    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    reader.ReadObject();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(SerializeSmi) {
  const Integer& smi_object = Integer::Handle(Smi::New(42));
  const intptr_t kLoopCount = 1000000;
  uint8_t* buffer;
  Timer timer(true, "Serialize Smi");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(&buffer, &message_allocator, &message_deallocator,
                         true);
    writer.WriteMessage(smi_object);
    intptr_t buffer_len = writer.BytesWritten();

    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    reader.ReadObject();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(SimpleMessage) {
  TransitionNativeToVM transition(thread);
  const Array& array_object = Array::Handle(Array::New(2));
  array_object.SetAt(0, Integer::Handle(Smi::New(42)));
  array_object.SetAt(1, Object::Handle());
  const intptr_t kLoopCount = 1000000;
  uint8_t* buffer;
  Timer timer(true, "Simple Message");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(&buffer, &malloc_allocator, &malloc_deallocator, true);
    writer.WriteMessage(array_object);
    intptr_t buffer_len = writer.BytesWritten();

    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    reader.ReadObject();
    free(buffer);
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(LargeMap) {
  const char* kScript =
      "makeMap() {\n"
      "  Map m = {};\n"
      "  for (int i = 0; i < 100000; ++i) m[i*13+i*(i>>7)] = i;\n"
      "  return m;\n"
      "}";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("makeMap"), 0, NULL);
  EXPECT_VALID(h_result);
  Instance& map = Instance::Handle();
  map ^= Api::UnwrapHandle(h_result);
  const intptr_t kLoopCount = 100;
  uint8_t* buffer;
  Timer timer(true, "Large Map");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(&buffer, &malloc_allocator, &malloc_deallocator, true);
    writer.WriteMessage(map);
    intptr_t buffer_len = writer.BytesWritten();

    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    reader.ReadObject();
    free(buffer);
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK_MEMORY(InitialRSS) {
  benchmark->set_score(OS::MaxRSS());
}

}  // namespace dart

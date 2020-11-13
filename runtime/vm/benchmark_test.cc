// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/benchmark_test.h"

#include "bin/builtin.h"
#include "bin/file.h"
#include "bin/isolate_data.h"
#include "bin/process.h"
#include "bin/reference_counting.h"
#include "bin/vmservice_impl.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

#include "vm/clustered_snapshot.h"
#include "vm/dart_api_impl.h"
#include "vm/datastream.h"
#include "vm/stack_frame.h"
#include "vm/timer.h"

using dart::bin::File;

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

//
// Measure compile of all functions in dart core lib classes.
//
BENCHMARK(CorelibCompileAll) {
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kCLILibrary);
  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);
  Timer timer(true, "Compile all of Core lib benchmark");
  timer.Start();
  const Error& error =
      Error::Handle(Library::CompileAll(/*ignore_error=*/true));
  if (!error.IsNull()) {
    OS::PrintErr("Unexpected error in CorelibCompileAll benchmark:\n%s",
                 error.ToErrorCString());
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

// This file is created by the target //runtime/bin:dart_kernel_platform_cc
// which is depended on by run_vm_tests.
static char* ComputeKernelServicePath(const char* arg) {
  char buffer[2048];
  char* kernel_service_path = Utils::StrDup(File::GetCanonicalPath(NULL, arg));
  EXPECT(kernel_service_path != NULL);
  const char* compiler_path = "%s%sgen%skernel_service.dill";
  const char* path_separator = File::PathSeparator();
  ASSERT(path_separator != NULL && strlen(path_separator) == 1);
  char* ptr = strrchr(kernel_service_path, *path_separator);
  while (ptr != NULL) {
    *ptr = '\0';
    Utils::SNPrint(buffer, ARRAY_SIZE(buffer), compiler_path,
                   kernel_service_path, path_separator, path_separator);
    if (File::Exists(NULL, buffer)) {
      break;
    }
    ptr = strrchr(kernel_service_path, *path_separator);
  }
  free(kernel_service_path);
  if (ptr == NULL) {
    return NULL;
  }
  return Utils::StrDup(buffer);
}

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
  int count = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(1, count);

  Dart_Handle recv = Dart_GetNativeArgument(args, 0);
  EXPECT_VALID(recv);
  Dart_Handle result = Dart_SetNativeInstanceField(recv, 0, 7);
  EXPECT_VALID(result);
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
      "import 'dart:nativewrappers';\n"
      "class Class extends NativeFieldWrapperClass1 {\n"
      "  void init() native 'init';\n"
      "  int method(int param1, int param2) native 'method';\n"
      "}\n"
      "\n"
      "void benchmark(int count) {\n"
      "  Class c = Class();\n"
      "  c.init();\n"
      "  for (int i = 0; i < count; i++) {\n"
      "    c.method(i,7);\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, bm_uda_lookup,
                                             RESOLVED_USER_TEST_URI, false);
  Dart_Handle result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  Dart_Handle args[1];
  args[0] = Dart_NewInteger(kNumIterations);

  // Warmup first to avoid compilation jitters.
  result = Dart_Invoke(lib, NewString("benchmark"), 1, args);
  EXPECT_VALID(result);

  Timer timer(true, "UseDartApi benchmark");
  timer.Start();
  result = Dart_Invoke(lib, NewString("benchmark"), 1, args);
  EXPECT_VALID(result);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

static void NoopFinalizer(void* isolate_callback_data, void* peer) {}

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
      data8, ARRAY_SIZE(data8), &external_peer_data, sizeof(data8),
      NoopFinalizer);
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

static void vmservice_resolver(Dart_NativeArguments args) {}

static Dart_NativeFunction NativeResolver(Dart_Handle name,
                                          int arg_count,
                                          bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &vmservice_resolver;
}

//
// Measure compile of all kernel Service(CFE) functions.
//
BENCHMARK(KernelServiceCompileAll) {
  if (FLAG_sound_null_safety == kNullSafetyOptionStrong) {
    // TODO(bkonyi): remove this check when we build the CFE in strong mode.
    return;
  }
  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kCLILibrary);
  char* dill_path = ComputeKernelServicePath(Benchmark::Executable());
  File* file = File::Open(NULL, dill_path, File::kRead);
  EXPECT(file != NULL);
  bin::RefCntReleaseScope<File> rs(file);
  intptr_t kernel_buffer_size = file->Length();
  uint8_t* kernel_buffer =
      reinterpret_cast<uint8_t*>(malloc(kernel_buffer_size));
  bool read_fully = file->ReadFully(kernel_buffer, kernel_buffer_size);
  EXPECT(read_fully);
  Dart_Handle result =
      Dart_LoadScriptFromKernel(kernel_buffer, kernel_buffer_size);
  EXPECT_VALID(result);
  Dart_Handle service_lib = Dart_LookupLibrary(NewString("dart:vmservice_io"));
  ASSERT(!Dart_IsError(service_lib));
  Dart_SetNativeResolver(service_lib, NativeResolver, NULL);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  Timer timer(true, "Compile all of kernel service benchmark");
  timer.Start();
#if !defined(PRODUCT)
  const bool old_flag = FLAG_background_compilation;
  FLAG_background_compilation = false;
#endif
  result = Dart_CompileAll();
#if !defined(PRODUCT)
  FLAG_background_compilation = old_flag;
#endif
  EXPECT_VALID(result);
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
  free(dill_path);
  free(kernel_buffer);
}

//
// Measure frame lookup during stack traversal.
//
static void StackFrame_accessFrame(Dart_NativeArguments args) {
  Timer timer(true, "LookupDartCode benchmark");
  timer.Start();
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    const int kNumIterations = 100;
    Code& code = Code::Handle(thread->zone());
    for (int i = 0; i < kNumIterations; i++) {
      StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
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
  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, StackFrameNativeResolver);
  Dart_Handle cls = Dart_GetClass(lib, NewString("StackFrameTest"));
  Dart_Handle result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  int64_t elapsed_time = 0;
  result = Dart_IntegerToInt64(result, &elapsed_time);
  EXPECT_VALID(result);
  benchmark->set_score(elapsed_time);
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
  // Need to load the script into the dart: core library due to
  // the import of dart:_internal.
  TestCase::LoadCoreTestScript(kScriptChars, NULL);

  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);

  Api::CheckAndFinalizePendingClasses(thread);

  // Write snapshot with object content.
  MallocWriteStream vm_snapshot_data(FullSnapshotWriter::kInitialSize);
  MallocWriteStream isolate_snapshot_data(FullSnapshotWriter::kInitialSize);
  FullSnapshotWriter writer(
      Snapshot::kFullCore, &vm_snapshot_data, &isolate_snapshot_data,
      /*vm_image_writer=*/nullptr, /*iso_image_writer=*/nullptr);
  writer.WriteFullSnapshot();
  const Snapshot* snapshot =
      Snapshot::SetupFromBuffer(isolate_snapshot_data.buffer());
  ASSERT(snapshot->kind() == Snapshot::kFullCore);
  benchmark->set_score(snapshot->length());
}

BENCHMARK_SIZE(StandaloneSnapshotSize) {
  const char* kScriptChars =
      "import 'dart:async';\n"
      "import 'dart:core';\n"
      "import 'dart:collection';\n"
      "import 'dart:convert';\n"
      "import 'dart:math';\n"
      "import 'dart:isolate';\n"
      "import 'dart:mirrors';\n"
      "import 'dart:typed_data';\n"
      "import 'dart:io';\n"
      "import 'dart:cli';\n"
      "\n";

  // Start an Isolate, load a script and create a full snapshot.
  // Need to load the script into the dart: core library due to
  // the import of dart:_internal.
  TestCase::LoadCoreTestScript(kScriptChars, NULL);

  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);

  Api::CheckAndFinalizePendingClasses(thread);

  // Write snapshot with object content.
  MallocWriteStream vm_snapshot_data(FullSnapshotWriter::kInitialSize);
  MallocWriteStream isolate_snapshot_data(FullSnapshotWriter::kInitialSize);
  FullSnapshotWriter writer(
      Snapshot::kFullCore, &vm_snapshot_data, &isolate_snapshot_data,
      /*vm_image_writer=*/nullptr, /*iso_image_writer=*/nullptr);
  writer.WriteFullSnapshot();
  const Snapshot* snapshot =
      Snapshot::SetupFromBuffer(isolate_snapshot_data.buffer());
  ASSERT(snapshot->kind() == Snapshot::kFullCore);
  benchmark->set_score(snapshot->length());
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
  Dart_Handle result = Dart_Invoke(lib, NewString("benchmark"), 0, NULL);
  EXPECT_VALID(result);
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
  {
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Api::CheckAndFinalizePendingClasses(thread);
  }
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

BENCHMARK(SerializeNull) {
  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);
  const Object& null_object = Object::Handle();
  const intptr_t kLoopCount = 1000000;
  Timer timer(true, "Serialize Null");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(true);
    std::unique_ptr<Message> message = writer.WriteMessage(
        null_object, ILLEGAL_PORT, Message::kNormalPriority);

    // Read object back from the snapshot.
    MessageSnapshotReader reader(message.get(), thread);
    reader.ReadObject();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(SerializeSmi) {
  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);
  const Integer& smi_object = Integer::Handle(Smi::New(42));
  const intptr_t kLoopCount = 1000000;
  Timer timer(true, "Serialize Smi");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(true);
    std::unique_ptr<Message> message =
        writer.WriteMessage(smi_object, ILLEGAL_PORT, Message::kNormalPriority);

    // Read object back from the snapshot.
    MessageSnapshotReader reader(message.get(), thread);
    reader.ReadObject();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK(SimpleMessage) {
  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);
  const Array& array_object = Array::Handle(Array::New(2));
  array_object.SetAt(0, Integer::Handle(Smi::New(42)));
  array_object.SetAt(1, Object::Handle());
  const intptr_t kLoopCount = 1000000;
  Timer timer(true, "Simple Message");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(true);
    std::unique_ptr<Message> message = writer.WriteMessage(
        array_object, ILLEGAL_PORT, Message::kNormalPriority);

    // Read object back from the snapshot.
    MessageSnapshotReader reader(message.get(), thread);
    reader.ReadObject();
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
  TransitionNativeToVM transition(thread);
  StackZone zone(thread);
  HANDLESCOPE(thread);
  Instance& map = Instance::Handle();
  map ^= Api::UnwrapHandle(h_result);
  const intptr_t kLoopCount = 100;
  Timer timer(true, "Large Map");
  timer.Start();
  for (intptr_t i = 0; i < kLoopCount; i++) {
    StackZone zone(thread);
    MessageWriter writer(true);
    std::unique_ptr<Message> message =
        writer.WriteMessage(map, ILLEGAL_PORT, Message::kNormalPriority);

    // Read object back from the snapshot.
    MessageSnapshotReader reader(message.get(), thread);
    reader.ReadObject();
  }
  timer.Stop();
  int64_t elapsed_time = timer.TotalElapsedTime();
  benchmark->set_score(elapsed_time);
}

BENCHMARK_MEMORY(InitialRSS) {
  benchmark->set_score(bin::Process::MaxRSS());
}

}  // namespace dart

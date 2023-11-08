// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unit_test.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"

#include "platform/globals.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/virtual_memory.h"

using dart::bin::Builtin;
using dart::bin::DartUtils;

extern "C" {
extern const uint8_t kPlatformStrongDill[];
extern intptr_t kPlatformStrongDillSize;
}

namespace dart {

DECLARE_FLAG(bool, gc_during_reload);
DECLARE_FLAG(bool, force_evacuation);

const uint8_t* platform_strong_dill = kPlatformStrongDill;
const intptr_t platform_strong_dill_size = kPlatformStrongDillSize;

const uint8_t* TesterState::vm_snapshot_data = nullptr;
Dart_IsolateGroupCreateCallback TesterState::create_callback = nullptr;
Dart_IsolateShutdownCallback TesterState::shutdown_callback = nullptr;
Dart_IsolateGroupCleanupCallback TesterState::group_cleanup_callback = nullptr;
const char** TesterState::argv = nullptr;
int TesterState::argc = 0;

void KernelBufferList::AddBufferToList(const uint8_t* kernel_buffer) {
  next_ = new KernelBufferList(kernel_buffer_, next_);
  kernel_buffer_ = kernel_buffer;
}

TestCaseBase* TestCaseBase::first_ = nullptr;
TestCaseBase* TestCaseBase::tail_ = nullptr;
KernelBufferList* TestCaseBase::current_kernel_buffers_ = nullptr;

TestCaseBase::TestCaseBase(const char* name, const char* expectation)
    : raw_test_(false),
      next_(nullptr),
      name_(name),
      expectation_(strlen(expectation) > 0 ? expectation : "Pass") {
  if (first_ == nullptr) {
    first_ = this;
  } else {
    tail_->next_ = this;
  }
  tail_ = this;
}

void TestCaseBase::RunAllRaw() {
  TestCaseBase* test = first_;
  while (test != nullptr) {
    if (test->raw_test_) {
      test->RunTest();
      CleanupState();
    }
    test = test->next_;
  }
}

void TestCaseBase::RunAll() {
  TestCaseBase* test = first_;
  while (test != nullptr) {
    if (!test->raw_test_) {
      test->RunTest();
      CleanupState();
    }
    test = test->next_;
  }
}

void TestCaseBase::CleanupState() {
  if (current_kernel_buffers_ != nullptr) {
    delete current_kernel_buffers_;
    current_kernel_buffers_ = nullptr;
  }
}

void TestCaseBase::AddToKernelBuffers(const uint8_t* kernel_buffer) {
  ASSERT(kernel_buffer != nullptr);
  if (current_kernel_buffers_ == nullptr) {
    current_kernel_buffers_ = new KernelBufferList(kernel_buffer);
  } else {
    current_kernel_buffers_->AddBufferToList(kernel_buffer);
  }
}

Dart_Isolate TestCase::CreateIsolate(const uint8_t* data_buffer,
                                     intptr_t len,
                                     const uint8_t* instr_buffer,
                                     const char* name,
                                     void* group_data,
                                     void* isolate_data) {
  char* err;
  Dart_IsolateFlags api_flags;
  Isolate::FlagsInitialize(&api_flags);
  api_flags.null_safety = FLAG_sound_null_safety;
  Dart_Isolate isolate = nullptr;
  if (len == 0) {
    isolate = Dart_CreateIsolateGroup(
        /*script_uri=*/name, /*name=*/name, data_buffer, instr_buffer,
        &api_flags, group_data, isolate_data, &err);
  } else {
    isolate = Dart_CreateIsolateGroupFromKernel(/*script_uri=*/name,
                                                /*name=*/name, data_buffer, len,
                                                &api_flags, group_data,
                                                isolate_data, &err);
  }
  if (isolate == nullptr) {
    OS::PrintErr("Creation of isolate failed '%s'\n", err);
    free(err);
  }

  EXPECT(isolate != nullptr);
  return isolate;
}

Dart_Isolate TestCase::CreateTestIsolate(const char* name,
                                         void* group_data,
                                         void* isolate_data) {
  return CreateIsolate(bin::core_isolate_snapshot_data,
                       0 /* Snapshots have length encoded within them. */,
                       bin::core_isolate_snapshot_instructions, name,
                       group_data, isolate_data);
}

void SetupCoreLibrariesForUnitTest() {
  TransitionVMToNative transition(Thread::Current());

  Dart_EnterScope();
  bool ok = bin::DartUtils::SetOriginalWorkingDirectory();
  RELEASE_ASSERT(ok);
  Dart_Handle result = bin::DartUtils::PrepareForScriptLoading(
      /*is_service_isolate=*/false,
      /*trace_loading=*/false);
  Dart_ExitScope();

  RELEASE_ASSERT(!Dart_IsError(result));
}

Dart_Isolate TestCase::CreateTestIsolateInGroup(const char* name,
                                                Dart_Isolate parent,
                                                void* group_data,
                                                void* isolate_data) {
  char* error;
  Isolate* result = CreateWithinExistingIsolateGroup(
      reinterpret_cast<Isolate*>(parent)->group(), name, &error);
  if (error != nullptr) {
    OS::PrintErr("CreateTestIsolateInGroup failed: %s\n", error);
    free(error);
  }
  EXPECT(result != nullptr);
  return Api::CastIsolate(result);
}

struct TestLibEntry {
  const char* url;
  const char* source;
};

static MallocGrowableArray<TestLibEntry>* test_libs_ = nullptr;

const char* TestCase::url() {
  return RESOLVED_USER_TEST_URI;
}

void TestCase::AddTestLib(const char* url, const char* source) {
  if (test_libs_ == nullptr) {
    test_libs_ = new MallocGrowableArray<TestLibEntry>();
  }
  // If the test lib is already added, replace the source.
  for (intptr_t i = 0; i < test_libs_->length(); i++) {
    if (strcmp(url, (*test_libs_)[i].url) == 0) {
      (*test_libs_)[i].source = source;
      return;
    }
  }
  TestLibEntry entry;
  entry.url = url;
  entry.source = source;
  test_libs_->Add(entry);
}

const char* TestCase::GetTestLib(const char* url) {
  if (test_libs_ == nullptr) {
    return nullptr;
  }
  for (intptr_t i = 0; i < test_libs_->length(); i++) {
    if (strcmp(url, (*test_libs_)[i].url) == 0) {
      return (*test_libs_)[i].source;
    }
  }
  return nullptr;
}

bool TestCase::IsNNBD() {
  return KernelIsolate::GetExperimentalFlag(ExperimentalFeature::non_nullable);
}

#ifndef PRODUCT
static const char* kIsolateReloadTestLibSource = R"(
@pragma("vm:external-name", "Test_Reload")
external void reloadTest();
@pragma("vm:external-name", "Test_CollectNewSpace")
external void collectNewSpace();
@pragma("vm:external-name", "Test_CollectOldSpace")
external void collectOldSpace();
)";

static const char* IsolateReloadTestLibUri() {
  return "test:isolate_reload_helper";
}

#define RELOAD_NATIVE_LIST(V)                                                  \
  V(Test_Reload, 0)                                                            \
  V(Test_CollectNewSpace, 0)                                                   \
  V(Test_CollectOldSpace, 0)

RELOAD_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} ReloadEntries[] = {RELOAD_NATIVE_LIST(REGISTER_FUNCTION)};

static Dart_NativeFunction IsolateReloadTestNativeResolver(
    Dart_Handle name,
    int argument_count,
    bool* auto_setup_scope) {
  const char* function_name = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  ASSERT(!Dart_IsError(result));
  ASSERT(function_name != nullptr);
  ASSERT(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  int num_entries = sizeof(ReloadEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(ReloadEntries[i]);
    if ((strcmp(function_name, entry->name_) == 0) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return nullptr;
}

void FUNCTION_NAME(Test_Reload)(Dart_NativeArguments native_args) {
  Dart_Handle result = TestCase::TriggerReload(/* kernel_buffer= */ nullptr,
                                               /* kernel_buffer_size= */ 0);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

void FUNCTION_NAME(Test_CollectNewSpace)(Dart_NativeArguments native_args) {
  TransitionNativeToVM transition(Thread::Current());
  GCTestHelper::CollectNewSpace();
}

void FUNCTION_NAME(Test_CollectOldSpace)(Dart_NativeArguments native_args) {
  TransitionNativeToVM transition(Thread::Current());
  GCTestHelper::CollectOldSpace();
}

#endif  // !PRODUCT

static void LoadIsolateReloadTestLibIfNeeded(const char* script) {
#ifndef PRODUCT
  if (strstr(script, IsolateReloadTestLibUri()) != nullptr) {
    Dart_Handle result = TestCase::LoadTestLibrary(
        IsolateReloadTestLibUri(), kIsolateReloadTestLibSource,
        IsolateReloadTestNativeResolver);
    EXPECT_VALID(result);
  }
#endif  // ifndef PRODUCT
}

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         const char* source,
                                         const uint8_t** kernel_buffer,
                                         intptr_t* kernel_buffer_size,
                                         bool incrementally,
                                         bool allow_compile_errors,
                                         const char* multiroot_filepaths,
                                         const char* multiroot_scheme) {
  // clang-format off
  Dart_SourceFile sourcefiles[] = {
    {
      url, source,
    },
    {
      "file:///.packages", ""
    }};
  // clang-format on
  return CompileTestScriptWithDFE(
      url, sizeof(sourcefiles) / sizeof(Dart_SourceFile), sourcefiles,
      kernel_buffer, kernel_buffer_size, incrementally, allow_compile_errors,
      multiroot_filepaths, multiroot_scheme);
}

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         int sourcefiles_count,
                                         Dart_SourceFile sourcefiles[],
                                         const uint8_t** kernel_buffer,
                                         intptr_t* kernel_buffer_size,
                                         bool incrementally,
                                         bool allow_compile_errors,
                                         const char* multiroot_filepaths,
                                         const char* multiroot_scheme) {
  Zone* zone = Thread::Current()->zone();
  Dart_KernelCompilationResult result = KernelIsolate::CompileToKernel(
      url, platform_strong_dill, platform_strong_dill_size, sourcefiles_count,
      sourcefiles, incrementally, /*for_snapshot=*/false,
      /*embed_sources=*/true, nullptr, multiroot_filepaths, multiroot_scheme);
  if (result.status == Dart_KernelCompilationStatus_Ok) {
    if (KernelIsolate::AcceptCompilation().status !=
        Dart_KernelCompilationStatus_Ok) {
      FATAL(
          "An error occurred in the CFE while accepting the most recent"
          " compilation results.");
    }
  }
  return ValidateCompilationResult(zone, result, kernel_buffer,
                                   kernel_buffer_size, allow_compile_errors);
}

char* TestCase::ValidateCompilationResult(
    Zone* zone,
    Dart_KernelCompilationResult compilation_result,
    const uint8_t** kernel_buffer,
    intptr_t* kernel_buffer_size,
    bool allow_compile_errors) {
  if (!allow_compile_errors &&
      (compilation_result.status != Dart_KernelCompilationStatus_Ok)) {
    char* result =
        OS::SCreate(zone, "Compilation failed %s", compilation_result.error);
    free(compilation_result.error);
    if (compilation_result.kernel != nullptr) {
      free(const_cast<uint8_t*>(compilation_result.kernel));
    }
    *kernel_buffer = nullptr;
    *kernel_buffer_size = 0;
    return result;
  }
  *kernel_buffer = compilation_result.kernel;
  *kernel_buffer_size = compilation_result.kernel_size;
  if (compilation_result.error != nullptr) {
    free(compilation_result.error);
  }
  if (kernel_buffer == nullptr) {
    return OS::SCreate(zone, "front end generated a nullptr kernel file");
  }
  return nullptr;
}

static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    return Dart_DefaultCanonicalizeUrl(library_url, url);
  }
  UNREACHABLE();
  return Dart_Null();
}

static intptr_t BuildSourceFilesArray(
    Dart_SourceFile** sourcefiles,
    const char* script,
    const char* script_url = RESOLVED_USER_TEST_URI) {
  ASSERT(sourcefiles != nullptr);
  ASSERT(script != nullptr);

  intptr_t num_test_libs = 0;
  if (test_libs_ != nullptr) {
    num_test_libs = test_libs_->length();
  }

  *sourcefiles = new Dart_SourceFile[num_test_libs + 1];
  (*sourcefiles)[0].uri = script_url;
  (*sourcefiles)[0].source = script;
  for (intptr_t i = 0; i < num_test_libs; ++i) {
    (*sourcefiles)[i + 1].uri = test_libs_->At(i).url;
    (*sourcefiles)[i + 1].source = test_libs_->At(i).source;
  }
  return num_test_libs + 1;
}

Dart_Handle TestCase::LoadTestScriptWithErrors(
    const char* script,
    Dart_NativeEntryResolver resolver,
    const char* lib_url,
    bool finalize_classes) {
  return LoadTestScript(script, resolver, lib_url, finalize_classes, true);
}

Dart_Handle TestCase::LoadTestScript(const char* script,
                                     Dart_NativeEntryResolver resolver,
                                     const char* lib_url,
                                     bool finalize_classes,
                                     bool allow_compile_errors) {
  LoadIsolateReloadTestLibIfNeeded(script);
  Dart_SourceFile* sourcefiles = nullptr;
  intptr_t num_sources = BuildSourceFilesArray(&sourcefiles, script, lib_url);
  Dart_Handle result =
      LoadTestScriptWithDFE(num_sources, sourcefiles, resolver,
                            finalize_classes, true, allow_compile_errors);
  delete[] sourcefiles;
  return result;
}

static void MallocFinalizer(void* isolate_callback_data, void* peer) {
  free(peer);
}

Dart_Handle TestCase::LoadTestLibrary(const char* lib_uri,
                                      const char* script,
                                      Dart_NativeEntryResolver resolver) {
  LoadIsolateReloadTestLibIfNeeded(script);
  const char* prefixed_lib_uri =
      OS::SCreate(Thread::Current()->zone(), "file:///%s", lib_uri);
  Dart_SourceFile sourcefiles[] = {{prefixed_lib_uri, script}};
  const uint8_t* kernel_buffer = nullptr;
  intptr_t kernel_buffer_size = 0;
  int sourcefiles_count = sizeof(sourcefiles) / sizeof(Dart_SourceFile);
  char* error = TestCase::CompileTestScriptWithDFE(
      sourcefiles[0].uri, sourcefiles_count, sourcefiles, &kernel_buffer,
      &kernel_buffer_size, true);
  if ((kernel_buffer == nullptr) && (error != nullptr)) {
    return Dart_NewApiError(error);
  }

  Dart_Handle td = Dart_NewExternalTypedDataWithFinalizer(
      Dart_TypedData_kUint8, const_cast<uint8_t*>(kernel_buffer),
      kernel_buffer_size, const_cast<uint8_t*>(kernel_buffer),
      kernel_buffer_size, MallocFinalizer);
  EXPECT_VALID(td);
  Dart_Handle lib = Dart_LoadLibrary(td);
  EXPECT_VALID(lib);

  // TODO(32618): Kernel doesn't correctly represent the root library.
  lib = Dart_LookupLibrary(Dart_NewStringFromCString(sourcefiles[0].uri));
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_SetRootLibrary(lib);
  EXPECT_VALID(result);

  Dart_SetNativeResolver(lib, resolver, nullptr);
  return lib;
}

Dart_Handle TestCase::LoadTestScriptWithDFE(int sourcefiles_count,
                                            Dart_SourceFile sourcefiles[],
                                            Dart_NativeEntryResolver resolver,
                                            bool finalize,
                                            bool incrementally,
                                            bool allow_compile_errors,
                                            const char* entry_script_uri,
                                            const char* multiroot_filepaths,
                                            const char* multiroot_scheme) {
  // First script is the main script.
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  EXPECT_VALID(result);
  const uint8_t* kernel_buffer = nullptr;
  intptr_t kernel_buffer_size = 0;
  char* error = TestCase::CompileTestScriptWithDFE(
      entry_script_uri != nullptr ? entry_script_uri : sourcefiles[0].uri,
      sourcefiles_count, sourcefiles, &kernel_buffer, &kernel_buffer_size,
      incrementally, allow_compile_errors, multiroot_filepaths,
      multiroot_scheme);
  if ((kernel_buffer == nullptr) && error != nullptr) {
    return Dart_NewApiError(error);
  }

  Dart_Handle td = Dart_NewExternalTypedDataWithFinalizer(
      Dart_TypedData_kUint8, const_cast<uint8_t*>(kernel_buffer),
      kernel_buffer_size, const_cast<uint8_t*>(kernel_buffer),
      kernel_buffer_size, MallocFinalizer);
  EXPECT_VALID(td);
  Dart_Handle lib = Dart_LoadLibrary(td);
  EXPECT_VALID(lib);

  // BOGUS: Kernel doesn't correctly represent the root library.
  lib = Dart_LookupLibrary(Dart_NewStringFromCString(
      entry_script_uri != nullptr ? entry_script_uri : sourcefiles[0].uri));
  EXPECT_VALID(lib);
  result = Dart_SetRootLibrary(lib);
  EXPECT_VALID(result);

  result = Dart_SetNativeResolver(lib, resolver, nullptr);
  EXPECT_VALID(result);
  if (finalize) {
    result = Dart_FinalizeLoading(false);
    EXPECT_VALID(result);
  }
  return lib;
}

#ifndef PRODUCT

Dart_Handle TestCase::SetReloadTestScript(const char* script) {
  // For our vm/cc/IsolateReload_* tests we flip the GC flag on, which will
  // cause the isolate reload to do GCs before/after morphing, etc.
  FLAG_gc_during_reload = true;
  FLAG_force_evacuation = true;

  Dart_SourceFile* sourcefiles = nullptr;
  intptr_t num_files = BuildSourceFilesArray(&sourcefiles, script);
  Dart_KernelCompilationResult compilation_result =
      KernelIsolate::UpdateInMemorySources(num_files, sourcefiles);
  delete[] sourcefiles;
  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    Dart_Handle result = Dart_NewApiError(compilation_result.error);
    free(compilation_result.error);
    return result;
  }
  return Api::Success();
}

Dart_Handle TestCase::TriggerReload(
    std::function<bool(IsolateGroup*, JSONStream*)> do_reload) {
  Thread* thread = Thread::Current();
  IsolateGroup* isolate_group = thread->isolate_group();
  JSONStream js;
  bool success = false;
  {
    TransitionNativeToVM transition(thread);
    success = do_reload(isolate_group, &js);
    OS::PrintErr("RELOAD REPORT:\n%s\n", js.ToCString());
  }

  Dart_Handle result = Dart_Null();
  if (success) {
    result = Dart_FinalizeLoading(false);
  }

  if (Dart_IsError(result)) {
    // Keep load error.
  } else if (isolate_group->reload_context()->reload_aborted()) {
    TransitionNativeToVM transition(thread);
    result = Api::NewHandle(thread, isolate_group->program_reload_context()
                                        ->group_reload_context()
                                        ->error());
  } else {
    result = Dart_RootLibrary();
  }

  TransitionNativeToVM transition(thread);
  if (isolate_group->program_reload_context() != nullptr) {
    isolate_group->DeleteReloadContext();
  }

  return result;
}

Dart_Handle TestCase::TriggerReload(const char* root_script_url) {
  return TriggerReload([&](IsolateGroup* isolate_group, JSONStream* js) {
    return isolate_group->ReloadSources(js,
                                        /*force_reload=*/false, root_script_url,
                                        /*packages_url=*/nullptr,
                                        /*dont_delete_reload_context=*/true);
  });
}

Dart_Handle TestCase::TriggerReload(const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size) {
  return TriggerReload([&](IsolateGroup* isolate_group, JSONStream* js) {
    return isolate_group->ReloadKernel(js,
                                       /*force_reload=*/false, kernel_buffer,
                                       kernel_buffer_size,
                                       /*dont_delete_reload_context=*/true);
  });
}

Dart_Handle TestCase::ReloadTestScript(const char* script) {
  Dart_SourceFile* sourcefiles = nullptr;
  intptr_t num_files = BuildSourceFilesArray(&sourcefiles, script);
  Dart_KernelCompilationResult compilation_result =
      KernelIsolate::UpdateInMemorySources(num_files, sourcefiles);
  delete[] sourcefiles;
  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    Dart_Handle result = Dart_NewApiError(compilation_result.error);
    free(compilation_result.error);
    if (compilation_result.kernel != nullptr) {
      free(const_cast<uint8_t*>(compilation_result.kernel));
    }
    return result;
  }

  return TriggerReload(/*kernel_buffer=*/nullptr, /*kernel_buffer_size=*/0);
}

Dart_Handle TestCase::ReloadTestKernel(const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_size) {
  return TriggerReload(kernel_buffer, kernel_buffer_size);
}

#endif  // !PRODUCT

Dart_Handle TestCase::LoadCoreTestScript(const char* script,
                                         Dart_NativeEntryResolver resolver) {
  return LoadTestScript(script, resolver, CORELIB_TEST_URI);
}

Dart_Handle TestCase::lib() {
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle lib = Dart_LookupLibrary(url);
  EXPECT_VALID(lib);
  ASSERT(Dart_IsLibrary(lib));
  return lib;
}

Dart_Handle TestCase::library_handler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    return url;
  }
  return Api::Success();
}

Dart_Handle TestCase::EvaluateExpression(const Library& lib,
                                         const String& expr,
                                         const Array& param_names,
                                         const Array& param_values) {
  Thread* thread = Thread::Current();

  Object& val = Object::Handle();
  if (!KernelIsolate::IsRunning()) {
    UNREACHABLE();
  } else {
    Dart_KernelCompilationResult compilation_result =
        KernelIsolate::CompileExpressionToKernel(
            /* platform_kernel= */ nullptr, /* platform_kernel_size= */ 0,
            expr.ToCString(), param_names, Array::empty_array(),
            Array::empty_array(), Array::empty_array(), Array::empty_array(),
            String::Handle(lib.url()).ToCString(),
            /* klass= */ nullptr,
            /* method= */ nullptr,
            /* is_static= */ true);
    if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
      return Api::NewError("%s", compilation_result.error);
    }

    const ExternalTypedData& kernel_buffer =
        ExternalTypedData::Handle(ExternalTypedData::NewFinalizeWithFree(
            const_cast<uint8_t*>(compilation_result.kernel),
            compilation_result.kernel_size));

    val = lib.EvaluateCompiledExpression(kernel_buffer, Array::empty_array(),
                                         param_values,
                                         TypeArguments::null_type_arguments());
  }
  return Api::NewHandle(thread, val.ptr());
}

#if !defined(PRODUCT) && (defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64))
static bool IsHex(int c) {
  return ('0' <= c && c <= '9') || ('a' <= c && c <= 'f');
}
#endif

void AssemblerTest::Assemble() {
  auto thread = Thread::Current();
  const String& function_name = String::ZoneHandle(Symbols::New(thread, name_));

  // We make a dummy script so that exception objects can be composed for
  // assembler instructions that do runtime calls.
  const char* kDummyScript = "assembler_test_dummy_function() {}";
  const Script& script = Script::Handle(
      Script::New(function_name, String::Handle(String::New(kDummyScript))));
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::ZoneHandle(
      Class::New(lib, function_name, script, TokenPosition::kMinSource));
  const FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  Function& function = Function::ZoneHandle(Function::New(
      signature, function_name, UntaggedFunction::kRegularFunction, true, false,
      false, false, false, cls, TokenPosition::kMinSource));
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  code_ = Code::FinalizeCodeAndNotify(function, nullptr, assembler_,
                                      Code::PoolAttachment::kAttachPool);
  code_.set_owner(function);
  code_.set_exception_handlers(Object::empty_exception_handlers());
#ifndef PRODUCT
  // Disassemble relative since code addresses are not stable from run to run.
  SetFlagScope<bool> sfs(&FLAG_disassemble_relative, true);
  uword start = code_.PayloadStart();
  if (FLAG_disassemble) {
    OS::PrintErr("Code for test '%s' {\n", name_);
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::PrintErr("}\n");
  }
  Disassembler::Disassemble(start, start + assembler_->CodeSize(), disassembly_,
                            DISASSEMBLY_SIZE);
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  // Blank out absolute addressing constants on ia32, since they are not stable
  // from run to run.
  // Blank out thread-relative offsets on x64 since they change when new fields
  // are added to thread object.
  bool in_hex_constant = false;
  for (char* p = disassembly_; *p != '\0'; p++) {
    if (in_hex_constant) {
      if (IsHex(*p)) {
        *p = '.';
      } else {
        in_hex_constant = false;
      }
    } else {
#if defined(TARGET_ARCH_IA32)
      if (*p == '[' && *(p + 1) == '0' && *(p + 2) == 'x' && IsHex(*(p + 3)) &&
          IsHex(*(p + 4))) {
        p += 2;
        in_hex_constant = true;
      }
#endif  // defined(TARGET_ARCH_IA32)
#if defined(TARGET_ARCH_X64)
      if (*p == '[' && *(p + 1) == 't' && *(p + 2) == 'h' && *(p + 3) == 'r' &&
          *(p + 4) == '+' && *(p + 5) == '0' && *(p + 6) == 'x' &&
          IsHex(*(p + 7)) && IsHex(*(p + 8))) {
        p += 6;
        in_hex_constant = true;
      }
#endif  // defined(TARGET_ARCH_X64)
    }
  }
#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
#endif  // !PRODUCT
}

bool CompilerTest::TestCompileFunction(const Function& function) {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  ASSERT(ClassFinalizer::AllClassesFinalized());
  const Object& result =
      Object::Handle(Compiler::CompileFunction(thread, function));
  return result.IsCode();
}

void ElideJSONSubstring(const char* prefix,
                        const char* in,
                        char* out,
                        const char* postfix) {
  const char* pos = strstr(in, prefix);
  while (pos != nullptr) {
    // Copy up to pos into the output buffer.
    while (in < pos) {
      *out++ = *in++;
    }

    // Skip to the closing postfix.
    in += strlen(prefix);
    in += strcspn(in, postfix);
    pos = strstr(in, prefix);
  }
  // Copy the remainder of in to out.
  while (*in != '\0') {
    *out++ = *in++;
  }
  *out = '\0';
}

void StripTokenPositions(char* buffer) {
  ElideJSONSubstring(",\"tokenPos\":", buffer, buffer, ",");
  ElideJSONSubstring(",\"endTokenPos\":", buffer, buffer, "}");
}

}  // namespace dart

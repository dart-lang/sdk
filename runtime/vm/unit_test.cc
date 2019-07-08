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

const uint8_t* platform_strong_dill = kPlatformStrongDill;
const intptr_t platform_strong_dill_size = kPlatformStrongDillSize;

const uint8_t* TesterState::vm_snapshot_data = NULL;
Dart_IsolateGroupCreateCallback TesterState::create_callback = NULL;
Dart_IsolateShutdownCallback TesterState::shutdown_callback = NULL;
Dart_IsolateGroupCleanupCallback TesterState::group_cleanup_callback = nullptr;
const char** TesterState::argv = NULL;
int TesterState::argc = 0;

void KernelBufferList::AddBufferToList(const uint8_t* kernel_buffer) {
  next_ = new KernelBufferList(kernel_buffer_, next_);
  kernel_buffer_ = kernel_buffer;
}

TestCaseBase* TestCaseBase::first_ = NULL;
TestCaseBase* TestCaseBase::tail_ = NULL;
KernelBufferList* TestCaseBase::current_kernel_buffers_ = NULL;

TestCaseBase::TestCaseBase(const char* name, const char* expectation)
    : raw_test_(false),
      next_(NULL),
      name_(name),
      expectation_(strlen(expectation) > 0 ? expectation : "Pass") {
  if (first_ == NULL) {
    first_ = this;
  } else {
    tail_->next_ = this;
  }
  tail_ = this;
}

void TestCaseBase::RunAllRaw() {
  TestCaseBase* test = first_;
  while (test != NULL) {
    if (test->raw_test_) {
      test->RunTest();
      CleanupState();
    }
    test = test->next_;
  }
}

void TestCaseBase::RunAll() {
  TestCaseBase* test = first_;
  while (test != NULL) {
    if (!test->raw_test_) {
      test->RunTest();
      CleanupState();
    }
    test = test->next_;
  }
}

void TestCaseBase::CleanupState() {
  if (current_kernel_buffers_ != NULL) {
    delete current_kernel_buffers_;
    current_kernel_buffers_ = NULL;
  }
}

void TestCaseBase::AddToKernelBuffers(const uint8_t* kernel_buffer) {
  ASSERT(kernel_buffer != NULL);
  if (current_kernel_buffers_ == NULL) {
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
  Dart_Isolate isolate = NULL;
  if (len == 0) {
    isolate = Dart_CreateIsolateGroup(name, NULL, data_buffer, instr_buffer,
                                      NULL, NULL, &api_flags, group_data,
                                      isolate_data, &err);
  } else {
    isolate = Dart_CreateIsolateGroupFromKernel(name, NULL, data_buffer, len,
                                                &api_flags, group_data,
                                                isolate_data, &err);
  }
  if (isolate == NULL) {
    OS::PrintErr("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);
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

static const char* kPackageScheme = "package:";

static bool IsPackageSchemeURL(const char* url_name) {
  static const intptr_t kPackageSchemeLen = strlen(kPackageScheme);
  return (strncmp(url_name, kPackageScheme, kPackageSchemeLen) == 0);
}

struct TestLibEntry {
  const char* url;
  const char* source;
};

static MallocGrowableArray<TestLibEntry>* test_libs_ = NULL;

const char* TestCase::url() {
  return RESOLVED_USER_TEST_URI;
}

void TestCase::AddTestLib(const char* url, const char* source) {
  if (test_libs_ == NULL) {
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
  if (test_libs_ == NULL) {
    return NULL;
  }
  for (intptr_t i = 0; i < test_libs_->length(); i++) {
    if (strcmp(url, (*test_libs_)[i].url) == 0) {
      return (*test_libs_)[i].source;
    }
  }
  return NULL;
}

#ifndef PRODUCT
static const char* kIsolateReloadTestLibSource =
    "void reloadTest() native 'Reload_Test';\n";

static const char* IsolateReloadTestLibUri() {
  return "test:isolate_reload_helper";
}

static bool IsIsolateReloadTestLib(const char* url_name) {
  static const intptr_t kIsolateReloadTestLibUriLen =
      strlen(IsolateReloadTestLibUri());
  return (strncmp(url_name, IsolateReloadTestLibUri(),
                  kIsolateReloadTestLibUriLen) == 0);
}

static void ReloadTest(Dart_NativeArguments native_args) {
  Dart_Handle result = TestCase::TriggerReload(/* kernel_buffer= */ NULL,
                                               /* kernel_buffer_size= */ 0);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

static Dart_NativeFunction IsolateReloadTestNativeResolver(
    Dart_Handle name,
    int num_of_arguments,
    bool* auto_setup_scope) {
  return ReloadTest;
}

static Dart_Handle LoadIsolateReloadTestLib() {
  return TestCase::LoadTestLibrary(IsolateReloadTestLibUri(),
                                   kIsolateReloadTestLibSource,
                                   IsolateReloadTestNativeResolver);
}
#endif  // !PRODUCT

static Dart_Handle ResolvePackageUri(const char* uri_chars) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = DartUtils::NewString(uri_chars);
  return Dart_Invoke(DartUtils::LookupBuiltinLib(),
                     DartUtils::NewString("_filePathFromUri"), kNumArgs,
                     dart_args);
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

#if 0

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         int sourcefiles_count,
                                         Dart_SourceFile sourcefiles[],
                                         void** kernel_pgm,
                                         bool incrementally,
                                         bool allow_compile_errors) {
  Zone* zone = Thread::Current()->zone();
  Dart_KernelCompilationResult compilation_result = Dart_CompileSourcesToKernel(
      url, platform_strong_dill, platform_strong_dill_size,
      sourcefiles_count, sourcefiles, incrementally, NULL);
  return ValidateCompilationResult(zone, compilation_result, kernel_pgm);
}

char* TestCase::ValidateCompilationResult(
    Zone* zone,
    Dart_KernelCompilationResult compilation_result,
    void** kernel_pgm,
    bool allow_compile_errors) {
  if (!allow_compile_errors &&
      (compilation_result.status != Dart_KernelCompilationStatus_Ok)) {
    char* result =
        OS::SCreate(zone, "Compilation failed %s", compilation_result.error);
    free(compilation_result.error);
    return result;
  }

  const uint8_t* kernel_file = compilation_result.kernel;
  intptr_t kernel_length = compilation_result.kernel_size;
  if (kernel_file == NULL) {
    return OS::SCreate(zone, "front end generated a NULL kernel file");
  }
  *kernel_pgm =
      Dart_ReadKernelBinary(kernel_file, kernel_length, ReleaseFetchedBytes);
  if (*kernel_pgm == NULL) {
    return OS::SCreate(zone, "Failed to read generated kernel binary");
  }
  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    char* result =
        OS::SCreate(zone, "Compilation failed %s", compilation_result.error);
    free(compilation_result.error);
    return result;
  }
  return NULL;
}
#endif

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
  Dart_KernelCompilationResult compilation_result = Dart_CompileSourcesToKernel(
      url, platform_strong_dill, platform_strong_dill_size, sourcefiles_count,
      sourcefiles, incrementally, NULL, multiroot_filepaths, multiroot_scheme);
  return ValidateCompilationResult(zone, compilation_result, kernel_buffer,
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
    if (compilation_result.kernel != NULL) {
      free(const_cast<uint8_t*>(compilation_result.kernel));
    }
    *kernel_buffer = NULL;
    *kernel_buffer_size = 0;
    return result;
  }
  *kernel_buffer = compilation_result.kernel;
  *kernel_buffer_size = compilation_result.kernel_size;
  if (compilation_result.error != NULL) {
    free(compilation_result.error);
  }
  if (kernel_buffer == NULL) {
    return OS::SCreate(zone, "front end generated a NULL kernel file");
  }
  return NULL;
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
  if (tag == Dart_kScriptTag) {
    // Reload request.
    UNREACHABLE();
    return Dart_Null();
  }
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_chars = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_chars);
  if (Dart_IsError(result)) {
    return Dart_NewApiError("accessing url characters failed");
  }
  Dart_Handle library_url = Dart_LibraryUrl(library);
  const char* library_url_string = NULL;
  result = Dart_StringToCString(library_url, &library_url_string);
  if (Dart_IsError(result)) {
    return result;
  }

  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_chars);
  bool is_io_library = DartUtils::IsDartIOLibURL(library_url_string);
  bool is_standalone_library = DartUtils::IsDartCLILibURL(library_url_string);
  if (is_dart_scheme_url) {
    ASSERT(tag == Dart_kImportTag);
    // Handle imports of other built-in libraries present in the SDK.
    if (DartUtils::IsDartIOLibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
    } else if (DartUtils::IsDartBuiltinLibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    } else if (DartUtils::IsDartCLILibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kCLILibrary);
    } else {
      return DartUtils::NewError("Do not know how to load '%s'", url_chars);
    }
  }
  const char* lib_source = TestCase::GetTestLib(url_chars);
  if (lib_source != NULL) {
    UNREACHABLE();
  }
#if !defined(PRODUCT)
  if (IsIsolateReloadTestLib(url_chars)) {
    UNREACHABLE();
    return Dart_Null();
  }
#endif
  if (is_io_library) {
    UNREACHABLE();
    return Dart_Null();
  }
  if (is_standalone_library) {
    UNREACHABLE();
    return Dart_Null();
  }
  Dart_Handle resolved_url = url;
  const char* resolved_url_chars = url_chars;
  if (IsPackageSchemeURL(url_chars)) {
    resolved_url = ResolvePackageUri(url_chars);
    EXPECT_VALID(resolved_url);
    if (Dart_IsError(Dart_StringToCString(resolved_url, &resolved_url_chars))) {
      return Dart_NewApiError("unable to convert resolved uri to string");
    }
  }
  // Do sync loading since unit_test doesn't support async.
  Dart_Handle source = DartUtils::ReadStringFromFile(resolved_url_chars);
  EXPECT_VALID(source);
  if (tag == Dart_kImportTag) {
    UNREACHABLE();
    return Dart_Null();
  } else {
    ASSERT(tag == Dart_kSourceTag);
    UNREACHABLE();
    return Dart_Null();
  }
}

static intptr_t BuildSourceFilesArray(
    Dart_SourceFile** sourcefiles,
    const char* script,
    const char* script_url = RESOLVED_USER_TEST_URI) {
  ASSERT(sourcefiles != NULL);
  ASSERT(script != NULL);

  intptr_t num_test_libs = 0;
  if (test_libs_ != NULL) {
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
#ifndef PRODUCT
    if (strstr(script, IsolateReloadTestLibUri()) != NULL) {
      Dart_Handle result = LoadIsolateReloadTestLib();
      EXPECT_VALID(result);
    }
#endif  // ifndef PRODUCT
    Dart_SourceFile* sourcefiles = NULL;
    intptr_t num_sources = BuildSourceFilesArray(&sourcefiles, script, lib_url);
    Dart_Handle result =
        LoadTestScriptWithDFE(num_sources, sourcefiles, resolver,
                              finalize_classes, true, allow_compile_errors);
    delete[] sourcefiles;
    return result;
}

Dart_Handle TestCase::LoadTestLibrary(const char* lib_uri,
                                      const char* script,
                                      Dart_NativeEntryResolver resolver) {
    const char* prefixed_lib_uri =
        OS::SCreate(Thread::Current()->zone(), "file:///%s", lib_uri);
    Dart_SourceFile sourcefiles[] = {{prefixed_lib_uri, script}};
    const uint8_t* kernel_buffer = NULL;
    intptr_t kernel_buffer_size = 0;
    int sourcefiles_count = sizeof(sourcefiles) / sizeof(Dart_SourceFile);
    char* error = TestCase::CompileTestScriptWithDFE(
        sourcefiles[0].uri, sourcefiles_count, sourcefiles, &kernel_buffer,
        &kernel_buffer_size, true);
    if ((kernel_buffer == NULL) && (error != NULL)) {
      return Dart_NewApiError(error);
    }
    Dart_Handle lib =
        Dart_LoadLibraryFromKernel(kernel_buffer, kernel_buffer_size);
    EXPECT_VALID(lib);

    // Ensure kernel buffer isn't leaked after test is run.
    AddToKernelBuffers(kernel_buffer);

    // TODO(32618): Kernel doesn't correctly represent the root library.
    lib = Dart_LookupLibrary(Dart_NewStringFromCString(sourcefiles[0].uri));
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_SetRootLibrary(lib);
    EXPECT_VALID(result);

    Dart_SetNativeResolver(lib, resolver, NULL);
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
  const uint8_t* kernel_buffer = NULL;
  intptr_t kernel_buffer_size = 0;
  char* error = TestCase::CompileTestScriptWithDFE(
      entry_script_uri != NULL ? entry_script_uri : sourcefiles[0].uri,
      sourcefiles_count, sourcefiles, &kernel_buffer, &kernel_buffer_size,
      incrementally, allow_compile_errors, multiroot_filepaths,
      multiroot_scheme);
  if ((kernel_buffer == NULL) && error != NULL) {
    return Dart_NewApiError(error);
  }

  Dart_Handle lib =
      Dart_LoadLibraryFromKernel(kernel_buffer, kernel_buffer_size);
  EXPECT_VALID(lib);

  // Ensure kernel buffer isn't leaked after test is run.
  AddToKernelBuffers(kernel_buffer);

  // BOGUS: Kernel doesn't correctly represent the root library.
  lib = Dart_LookupLibrary(Dart_NewStringFromCString(
      entry_script_uri != NULL ? entry_script_uri : sourcefiles[0].uri));
  EXPECT_VALID(lib);
  result = Dart_SetRootLibrary(lib);
  EXPECT_VALID(result);

  result = Dart_SetNativeResolver(lib, resolver, NULL);
  EXPECT_VALID(result);
  if (finalize) {
    result = Dart_FinalizeLoading(false);
    EXPECT_VALID(result);
  }
  return lib;
}

#ifndef PRODUCT

Dart_Handle TestCase::SetReloadTestScript(const char* script) {
    Dart_SourceFile* sourcefiles = NULL;
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

Dart_Handle TestCase::TriggerReload(const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  JSONStream js;
  bool success = false;
  {
    TransitionNativeToVM transition(thread);
    success = isolate->ReloadKernel(&js,
                                    false,  // force_reload
                                    kernel_buffer, kernel_buffer_size,
                                    true);  // dont_delete_reload_context
    OS::PrintErr("RELOAD REPORT:\n%s\n", js.ToCString());
  }

  Dart_Handle result = Dart_Null();
  if (success) {
    result = Dart_FinalizeLoading(false);
  }

  if (Dart_IsError(result)) {
    // Keep load error.
  } else if (isolate->reload_context()->reload_aborted()) {
    TransitionNativeToVM transition(thread);
    result = Api::NewHandle(thread, isolate->reload_context()->error());
  } else {
    result = Dart_RootLibrary();
  }

  TransitionNativeToVM transition(thread);
  if (isolate->reload_context() != NULL) {
    isolate->DeleteReloadContext();
  }

  return result;
}

Dart_Handle TestCase::ReloadTestScript(const char* script) {
    Dart_SourceFile* sourcefiles = NULL;
    intptr_t num_files = BuildSourceFilesArray(&sourcefiles, script);
    Dart_KernelCompilationResult compilation_result =
        KernelIsolate::UpdateInMemorySources(num_files, sourcefiles);
    delete[] sourcefiles;
    if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
      Dart_Handle result = Dart_NewApiError(compilation_result.error);
      free(compilation_result.error);
      if (compilation_result.kernel != NULL) {
        free(const_cast<uint8_t*>(compilation_result.kernel));
      }
      return result;
    }

  return TriggerReload(/* kernel_buffer= */ NULL, /* kernel_buffer_size= */ 0);
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
            expr.ToCString(), param_names, Array::empty_array(),
            String::Handle(lib.url()).ToCString(), /* klass=*/nullptr,
            /* is_static= */ false);
    if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
      return Api::NewError("%s", compilation_result.error);
    }

    const uint8_t* kernel_bytes = compilation_result.kernel;
    intptr_t kernel_length = compilation_result.kernel_size;

    val = lib.EvaluateCompiledExpression(kernel_bytes, kernel_length,
                                         Array::empty_array(), param_values,
                                         TypeArguments::null_type_arguments());
    free(const_cast<uint8_t*>(kernel_bytes));
  }
  return Api::NewHandle(thread, val.raw());
}

#if !defined(PRODUCT)
static bool IsHex(int c) {
  return ('0' <= c && c <= '9') || ('a' <= c && c <= 'f');
}
#endif

void AssemblerTest::Assemble() {
  const String& function_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), name_));

  // We make a dummy script so that exception objects can be composed for
  // assembler instructions that do runtime calls, in particular on DBC.
  const char* kDummyScript = "assembler_test_dummy_function() {}";
  const Script& script = Script::Handle(
      Script::New(function_name, String::Handle(String::New(kDummyScript)),
                  RawScript::kSourceTag));
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::ZoneHandle(
      Class::New(lib, function_name, script, TokenPosition::kMinSource));
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction, true, false,
                    false, false, false, cls, TokenPosition::kMinSource));
  code_ = Code::FinalizeCodeAndNotify(function, nullptr, assembler_,
                                      Code::PoolAttachment::kAttachPool);
  code_.set_owner(function);
  code_.set_exception_handlers(Object::empty_exception_handlers());
#ifndef PRODUCT
  const Instructions& instructions = Instructions::Handle(code_.instructions());
  uword start = instructions.PayloadStart();
  if (FLAG_disassemble) {
    OS::PrintErr("Code for test '%s' {\n", name_);
    uword start = instructions.PayloadStart();
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::PrintErr("}\n");
  }
  Disassembler::Disassemble(start, start + assembler_->CodeSize(), disassembly_,
                            DISASSEMBLY_SIZE);
  // Blank out big hex constants, since they are not stable from run to run.
  bool in_hex_constant = false;
  for (char* p = disassembly_; *p != '\0'; p++) {
    if (in_hex_constant) {
      if (IsHex(*p)) {
        *p = '.';
      } else {
        in_hex_constant = false;
      }
    } else {
      if (*p == '0' && *(p + 1) == 'x' && IsHex(*(p + 2)) && IsHex(*(p + 3)) &&
          IsHex(*(p + 4))) {
        p++;
        in_hex_constant = true;
      }
    }
  }
#endif  // !PRODUCT
}

bool CompilerTest::TestCompileFunction(const Function& function) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());
  const Object& result =
      Object::Handle(Compiler::CompileFunction(thread, function));
  return result.IsCode();
}

void ElideJSONSubstring(const char* prefix, const char* in, char* out) {
  const char* pos = strstr(in, prefix);
  while (pos != NULL) {
    // Copy up to pos into the output buffer.
    while (in < pos) {
      *out++ = *in++;
    }

    // Skip to the close quote.
    in += strcspn(in, "\"");
    pos = strstr(in, prefix);
  }
  // Copy the remainder of in to out.
  while (*in != '\0') {
    *out++ = *in++;
  }
  *out = '\0';
}

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unit_test.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"

#include "platform/globals.h"

#include "vm/ast_printer.h"
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
extern const uint8_t kPlatformDill[];
extern const uint8_t kPlatformStrongDill[];
extern intptr_t kPlatformDillSize;
extern intptr_t kPlatformStrongDillSize;
}

namespace dart {

const uint8_t* platform_dill = kPlatformDill;
const uint8_t* platform_strong_dill = kPlatformStrongDill;
const intptr_t platform_dill_size = kPlatformDillSize;
const intptr_t platform_strong_dill_size = kPlatformStrongDillSize;

DEFINE_FLAG(bool,
            use_dart_frontend,
            false,
            "Parse scripts with Dart-to-Kernel parser");

DECLARE_FLAG(bool, strong);

TestCaseBase* TestCaseBase::first_ = NULL;
TestCaseBase* TestCaseBase::tail_ = NULL;

TestCaseBase::TestCaseBase(const char* name)
    : raw_test_(false), next_(NULL), name_(name) {
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
    }
    test = test->next_;
  }
}

void TestCaseBase::RunAll() {
  TestCaseBase* test = first_;
  while (test != NULL) {
    if (!test->raw_test_) {
      test->RunTest();
    }
    test = test->next_;
  }
}

static void NoopRelease(uint8_t* data) {}

Dart_Isolate TestCase::CreateIsolate(const uint8_t* data_buffer,
                                     intptr_t len,
                                     const uint8_t* instr_buffer,
                                     const char* name,
                                     void* data) {
  char* err;
  Dart_IsolateFlags api_flags;
  Isolate::FlagsInitialize(&api_flags);
  api_flags.use_dart_frontend = FLAG_use_dart_frontend;
  Dart_Isolate isolate = NULL;
  if (len == 0) {
    isolate = Dart_CreateIsolate(name, NULL, data_buffer, instr_buffer,
                                 &api_flags, data, &err);
  } else {
    kernel::Program* program = reinterpret_cast<kernel::Program*>(
        Dart_ReadKernelBinary(data_buffer, len, NoopRelease));
    if (program != NULL) {
      isolate = Dart_CreateIsolateFromKernel(name, NULL, program, &api_flags,
                                             data, &err);
      delete program;
    }
  }
  if (isolate == NULL) {
    OS::PrintErr("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);
  return isolate;
}

Dart_Isolate TestCase::CreateTestIsolate(const char* name, void* data) {
  if (FLAG_use_dart_frontend) {
    return CreateIsolate(
        FLAG_strong ? platform_strong_dill : platform_dill,
        FLAG_strong ? platform_strong_dill_size : platform_dill_size,
        NULL, /* There is no instr buffer in case of dill buffers. */
        name, data);
  } else {
    return CreateIsolate(bin::core_isolate_snapshot_data,
                         0 /* Snapshots have length encoded within them. */,
                         bin::core_isolate_snapshot_instructions, name, data);
  }
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
  return (FLAG_use_dart_frontend) ? RESOLVED_USER_TEST_URI : USER_TEST_URI;
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
  return FLAG_use_dart_frontend ? "test:isolate_reload_helper"
                                : "file:///test:isolate_reload_helper";
}

static bool IsIsolateReloadTestLib(const char* url_name) {
  static const intptr_t kIsolateReloadTestLibUriLen =
      strlen(IsolateReloadTestLibUri());
  return (strncmp(url_name, IsolateReloadTestLibUri(),
                  kIsolateReloadTestLibUriLen) == 0);
}

static Dart_Handle IsolateReloadTestLibSource() {
  // Special library with one function.
  return DartUtils::NewString(kIsolateReloadTestLibSource);
}

static void ReloadTest(Dart_NativeArguments native_args) {
  DART_CHECK_VALID(TestCase::TriggerReload());
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
  return Dart_Invoke(DartUtils::BuiltinLib(),
                     DartUtils::NewString("_filePathFromUri"), kNumArgs,
                     dart_args);
}

static ThreadLocalKey script_reload_key = kUnsetThreadLocalKey;

bool TestCase::UsingDartFrontend() {
  return FLAG_use_dart_frontend;
}

bool TestCase::UsingStrongMode() {
  return FLAG_strong;
}

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         const char* source,
                                         void** kernel_pgm,
                                         bool incrementally) {
  // clang-format off
  Dart_SourceFile sourcefiles[] = {
    {
      url, source,
    },
    {
      "file:///.packages", "untitled:/"
    }};
  // clang-format on
  return CompileTestScriptWithDFE(url,
                                  sizeof(sourcefiles) / sizeof(Dart_SourceFile),
                                  sourcefiles, kernel_pgm, incrementally);
}

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
}

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         int sourcefiles_count,
                                         Dart_SourceFile sourcefiles[],
                                         void** kernel_pgm,
                                         bool incrementally) {
  Zone* zone = Thread::Current()->zone();
  Dart_KernelCompilationResult compilation_result = Dart_CompileSourcesToKernel(
      url, FLAG_strong ? platform_strong_dill : platform_dill,
      FLAG_strong ? platform_strong_dill_size : platform_dill_size,
      sourcefiles_count, sourcefiles, incrementally);

  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    return OS::SCreate(zone, "Compilation failed %s", compilation_result.error);
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
    ASSERT(script_reload_key != kUnsetThreadLocalKey);
    const char* script_source = reinterpret_cast<const char*>(
        OSThread::GetThreadLocal(script_reload_key));
    ASSERT(script_source != NULL);
    OSThread::SetThreadLocal(script_reload_key, 0);
    return Dart_LoadScript(url, Dart_Null(), NewString(script_source), 0, 0);
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
    Dart_Handle source = Dart_NewStringFromCString(lib_source);
    return Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  }
#if !defined(PRODUCT)
  if (IsIsolateReloadTestLib(url_chars)) {
    Dart_Handle library =
        Dart_LoadLibrary(url, Dart_Null(), IsolateReloadTestLibSource(), 0, 0);
    DART_CHECK_VALID(library);
    Dart_SetNativeResolver(library, IsolateReloadTestNativeResolver, 0);
    return library;
  }
#endif
  if (is_io_library) {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, Dart_Null(),
                           Builtin::PartSource(Builtin::kIOLibrary, url_chars),
                           0, 0);
  }
  if (is_standalone_library) {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, Dart_Null(),
                           Builtin::PartSource(Builtin::kCLILibrary, url_chars),
                           0, 0);
  }
  Dart_Handle resolved_url = url;
  const char* resolved_url_chars = url_chars;
  if (IsPackageSchemeURL(url_chars)) {
    resolved_url = ResolvePackageUri(url_chars);
    DART_CHECK_VALID(resolved_url);
    if (Dart_IsError(Dart_StringToCString(resolved_url, &resolved_url_chars))) {
      return Dart_NewApiError("unable to convert resolved uri to string");
    }
  }
  // Do sync loading since unit_test doesn't support async.
  Dart_Handle source = DartUtils::ReadStringFromFile(resolved_url_chars);
  EXPECT_VALID(source);
  if (tag == Dart_kImportTag) {
    return Dart_LoadLibrary(url, resolved_url, source, 0, 0);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, resolved_url, source, 0, 0);
  }
}

static Dart_Handle LoadTestScriptWithVMParser(const char* script,
                                              Dart_NativeEntryResolver resolver,
                                              const char* lib_url,
                                              bool finalize_classes) {
  Dart_Handle url = NewString(lib_url);
  Dart_Handle source = NewString(script);
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  DART_CHECK_VALID(lib);
  result = Dart_SetNativeResolver(lib, resolver, NULL);
  DART_CHECK_VALID(result);
  if (finalize_classes) {
    result = Dart_FinalizeLoading(false);
    DART_CHECK_VALID(result);
  }
  return lib;
}

static intptr_t BuildSourceFilesArray(Dart_SourceFile** sourcefiles,
                                      const char* script) {
  ASSERT(sourcefiles != NULL);
  ASSERT(script != NULL);
  ASSERT(FLAG_use_dart_frontend);

  intptr_t num_test_libs = 0;
  if (test_libs_ != NULL) {
    num_test_libs = test_libs_->length();
  }

  *sourcefiles = new Dart_SourceFile[num_test_libs + 1];
  (*sourcefiles)[0].uri = RESOLVED_USER_TEST_URI;
  (*sourcefiles)[0].source = script;
  for (intptr_t i = 0; i < num_test_libs; ++i) {
    (*sourcefiles)[i + 1].uri = test_libs_->At(i).url;
    (*sourcefiles)[i + 1].source = test_libs_->At(i).source;
  }
  return num_test_libs + 1;
}

Dart_Handle TestCase::LoadTestScript(const char* script,
                                     Dart_NativeEntryResolver resolver,
                                     const char* lib_url,
                                     bool finalize_classes) {
  if (FLAG_use_dart_frontend) {
#ifndef PRODUCT
    if (strstr(script, IsolateReloadTestLibUri()) != NULL) {
      Dart_Handle result = LoadIsolateReloadTestLib();
      EXPECT_VALID(result);
    }
#endif  // ifndef PRODUCT
    Dart_SourceFile* sourcefiles = NULL;
    intptr_t num_sources = BuildSourceFilesArray(&sourcefiles, script);
    Dart_Handle result = LoadTestScriptWithDFE(num_sources, sourcefiles,
                                               resolver, finalize_classes);
    delete[] sourcefiles;
    return result;
  } else {
    return LoadTestScriptWithVMParser(script, resolver, lib_url,
                                      finalize_classes);
  }
}

Dart_Handle TestCase::LoadTestLibrary(const char* lib_uri,
                                      const char* script,
                                      Dart_NativeEntryResolver resolver) {
  if (FLAG_use_dart_frontend) {
    const char* prefixed_lib_uri =
        OS::SCreate(Thread::Current()->zone(), "file:///%s", lib_uri);
    Dart_SourceFile sourcefiles[] = {{prefixed_lib_uri, script}};
    void* kernel_pgm = NULL;
    int sourcefiles_count = sizeof(sourcefiles) / sizeof(Dart_SourceFile);
    char* error = TestCase::CompileTestScriptWithDFE(
        sourcefiles[0].uri, sourcefiles_count, sourcefiles, &kernel_pgm, true);
    if (error != NULL) {
      return Dart_NewApiError(error);
    }
    Dart_Handle url = NewString(prefixed_lib_uri);
    Dart_Handle lib = Dart_LoadLibrary(
        url, Dart_Null(), reinterpret_cast<Dart_Handle>(kernel_pgm), 0, 0);
    EXPECT_VALID(lib);
    Dart_SetNativeResolver(lib, resolver, NULL);
    return lib;
  } else {
    Dart_Handle url = NewString(lib_uri);
    Dart_Handle source = NewString(script);
    return Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  }
}

Dart_Handle TestCase::LoadTestScriptWithDFE(int sourcefiles_count,
                                            Dart_SourceFile sourcefiles[],
                                            Dart_NativeEntryResolver resolver,
                                            bool finalize,
                                            bool incrementally) {
  // First script is the main script.
  Dart_Handle url = NewString(sourcefiles[0].uri);
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  EXPECT_VALID(result);
  void* kernel_pgm = NULL;
  char* error = TestCase::CompileTestScriptWithDFE(
      sourcefiles[0].uri, sourcefiles_count, sourcefiles, &kernel_pgm,
      incrementally);
  if (error != NULL) {
    return Dart_NewApiError(error);
  }
  Dart_Handle lib = Dart_LoadScript(
      url, Dart_Null(), reinterpret_cast<Dart_Handle>(kernel_pgm), 0, 0);
  DART_CHECK_VALID(lib);
  result = Dart_SetNativeResolver(lib, resolver, NULL);
  DART_CHECK_VALID(result);
  if (finalize) {
    result = Dart_FinalizeLoading(false);
    DART_CHECK_VALID(result);
  }
  return lib;
}

#ifndef PRODUCT

void TestCase::SetReloadTestScript(const char* script) {
  if (FLAG_use_dart_frontend) {
    Dart_SourceFile* sourcefiles = NULL;
    intptr_t num_files = BuildSourceFilesArray(&sourcefiles, script);
    KernelIsolate::UpdateInMemorySources(num_files, sourcefiles);
  } else {
    if (script_reload_key == kUnsetThreadLocalKey) {
      script_reload_key = OSThread::CreateThreadLocal();
    }
    ASSERT(script_reload_key != kUnsetThreadLocalKey);
    ASSERT(OSThread::GetThreadLocal(script_reload_key) == 0);
    // Store the new script in TLS.
    OSThread::SetThreadLocal(script_reload_key,
                             reinterpret_cast<uword>(script));
  }
}

Dart_Handle TestCase::TriggerReload() {
  Isolate* isolate = Isolate::Current();
  JSONStream js;
  bool success = false;
  {
    TransitionNativeToVM transition(Thread::Current());
    success = isolate->ReloadSources(&js,
                                     false,  // force_reload
                                     NULL, NULL,
                                     true);  // dont_delete_reload_context
    OS::PrintErr("RELOAD REPORT:\n%s\n", js.ToCString());
  }

  if (success) {
    return Dart_FinalizeLoading(false);
  } else {
    return Dart_Null();
  }
}

Dart_Handle TestCase::GetReloadLibrary() {
  Isolate* isolate = Isolate::Current();

  if (isolate->reload_context() != NULL &&
      isolate->reload_context()->reload_aborted()) {
    return Dart_Null();
  }
  return Dart_RootLibrary();
}

Dart_Handle TestCase::GetReloadErrorOrRootLibrary() {
  Isolate* isolate = Isolate::Current();

  if (isolate->reload_context() != NULL &&
      isolate->reload_context()->reload_aborted()) {
    // Return a handle to the error.
    return Api::NewHandle(Thread::Current(),
                          isolate->reload_context()->error());
  }
  return Dart_RootLibrary();
}

Dart_Handle TestCase::ReloadTestScript(const char* script) {
  if (FLAG_use_dart_frontend) {
    Dart_SourceFile* sourcefiles = NULL;
    intptr_t num_files = BuildSourceFilesArray(&sourcefiles, script);
    KernelIsolate::UpdateInMemorySources(num_files, sourcefiles);
    delete[] sourcefiles;
  } else {
    SetReloadTestScript(script);
  }

  Dart_Handle result = TriggerReload();
  if (Dart_IsError(result)) {
    return result;
  }

  result = GetReloadErrorOrRootLibrary();

  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    Isolate* isolate = thread->isolate();
    if (isolate->reload_context() != NULL) {
      isolate->DeleteReloadContext();
    }
  }

  return result;
}

Dart_Handle TestCase::ReloadTestKernel(const void* kernel) {
  Dart_Handle result = TriggerReload();
  if (Dart_IsError(result)) {
    return result;
  }

  result = GetReloadErrorOrRootLibrary();

  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    Isolate* isolate = thread->isolate();
    if (isolate->reload_context() != NULL) {
      isolate->DeleteReloadContext();
    }
  }

  return result;
}

#endif  // !PRODUCT

Dart_Handle TestCase::LoadCoreTestScript(const char* script,
                                         Dart_NativeEntryResolver resolver) {
  return LoadTestScript(script, resolver, CORELIB_TEST_URI);
}

Dart_Handle TestCase::lib() {
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(lib);
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

char* TestCase::BigintToHexValue(Dart_CObject* bigint) {
  return bin::CObject::BigintToHexValue(bigint);
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
  script.Tokenize(String::Handle());
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::ZoneHandle(
      Class::New(lib, function_name, script, TokenPosition::kMinSource));
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction, true, false,
                    false, false, false, cls, TokenPosition::kMinSource));
  code_ = Code::FinalizeCode(function, assembler_);
  code_.set_owner(function);
  code_.set_exception_handlers(Object::empty_exception_handlers());
#ifndef PRODUCT
  const Instructions& instructions = Instructions::Handle(code_.instructions());
  uword start = instructions.PayloadStart();
  if (FLAG_disassemble) {
    OS::Print("Code for test '%s' {\n", name_);
    uword start = instructions.PayloadStart();
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::Print("}\n");
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

CodeGenTest::CodeGenTest(const char* name)
    : function_(Function::ZoneHandle()),
      node_sequence_(new SequenceNode(TokenPosition::kMinSource,
                                      new LocalScope(NULL, 0, 0))),
      default_parameter_values_(new ZoneGrowableArray<const Instance*>()) {
  ASSERT(name != NULL);
  const String& function_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), name));
  // Add function to a class and that class to the class dictionary so that
  // frame walking can be used.
  Library& lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::ZoneHandle(Class::New(
      lib, function_name, Script::Handle(), TokenPosition::kMinSource));
  function_ =
      Function::New(function_name, RawFunction::kRegularFunction, true, false,
                    false, false, false, cls, TokenPosition::kMinSource);
  function_.set_result_type(Type::Handle(Type::DynamicType()));
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function_);
  cls.SetFunctions(functions);
  lib.AddClass(cls);
}

void CodeGenTest::Compile() {
  if (function_.HasCode()) return;
  ParsedFunction* parsed_function =
      new ParsedFunction(Thread::Current(), function_);
  parsed_function->SetNodeSequence(node_sequence_);
  parsed_function->set_default_parameter_values(default_parameter_values_);
  node_sequence_->scope()->AddVariable(parsed_function->current_context_var());
  parsed_function->EnsureExpressionTemp();
  node_sequence_->scope()->AddVariable(parsed_function->expression_temp_var());
  parsed_function->AllocateVariables();
  const Error& error =
      Error::Handle(Compiler::CompileParsedFunction(parsed_function));
  EXPECT(error.IsNull());
}

bool CompilerTest::TestCompileScript(const Library& library,
                                     const Script& script) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(Compiler::Compile(library, script));
  if (!error.IsNull()) {
    OS::Print("Error compiling test script:\n%s\n", error.ToErrorCString());
  }
  return error.IsNull();
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

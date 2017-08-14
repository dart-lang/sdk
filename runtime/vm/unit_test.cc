// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unit_test.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"

#include "platform/globals.h"

#include "vm/assembler.h"
#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/disassembler.h"
#include "vm/isolate_reload.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/virtual_memory.h"

using dart::bin::Builtin;
using dart::bin::DartUtils;

namespace dart {

DEFINE_FLAG(bool,
            use_dart_frontend,
            false,
            "Parse scripts with Dart-to-Kernel parser");

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

Dart_Isolate TestCase::CreateIsolate(const uint8_t* buffer, const char* name) {
  char* err;
  Dart_IsolateFlags api_flags;
  Isolate::FlagsInitialize(&api_flags);
  api_flags.use_dart_frontend = FLAG_use_dart_frontend;
  Dart_Isolate isolate =
      Dart_CreateIsolate(name, NULL, buffer, NULL, &api_flags, NULL, &err);
  if (isolate == NULL) {
    OS::Print("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);
  return isolate;
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
static bool IsIsolateReloadTestLib(const char* url_name) {
  const char* kIsolateReloadTestLibUri = "test:isolate_reload_helper";
  static const intptr_t kIsolateReloadTestLibUriLen =
      strlen(kIsolateReloadTestLibUri);
  return (strncmp(url_name, kIsolateReloadTestLibUri,
                  kIsolateReloadTestLibUriLen) == 0);
}

static Dart_Handle IsolateReloadTestLibSource() {
  // Special library with one function.
  return DartUtils::NewString("void reloadTest() native 'Reload_Test';\n");
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

char* TestCase::CompileTestScriptWithDFE(const char* url,
                                         const char* source,
                                         void** kernel_pgm) {
  Zone* zone = Thread::Current()->zone();
  // clang-format off
  Dart_SourceFile sourcefiles[] = {
    {
      url, source,
    },
    {
      "file:///.packages", "untitled:/"
    }};
  // clang-format on
  int sourcefiles_count = sizeof(sourcefiles) / sizeof(Dart_SourceFile);
  Dart_KernelCompilationResult compilation_result =
      Dart_CompileSourcesToKernel(url, sourcefiles_count, sourcefiles);

  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    return OS::SCreate(zone, "Compilation failed %s", compilation_result.error);
  }
  const uint8_t* kernel_file = compilation_result.kernel;
  intptr_t kernel_length = compilation_result.kernel_size;
  if (kernel_file == NULL) {
    return OS::SCreate(zone, "front end generated a NULL kernel file");
  }
  *kernel_pgm = Dart_ReadKernelBinary(kernel_file, kernel_length);
  if (*kernel_pgm == NULL) {
    return OS::SCreate(zone, "Failed to read generated kernel binary");
  }
  return NULL;
}

static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  if (FLAG_use_dart_frontend) {
    // Reload request.
    ASSERT(script_reload_key != kUnsetThreadLocalKey);
    const char* script_source = reinterpret_cast<const char*>(
        OSThread::GetThreadLocal(script_reload_key));
    ASSERT(script_source != NULL);
    OSThread::SetThreadLocal(script_reload_key, 0);
    const char* urlstr = NULL;
    Dart_Handle result = Dart_StringToCString(url, &urlstr);
    if (Dart_IsError(result)) {
      return Dart_NewApiError("accessing url characters failed");
    }
    void* kernel_pgm;
    char* error =
        TestCase::CompileTestScriptWithDFE(urlstr, script_source, &kernel_pgm);
    if (error == NULL) {
      return Dart_LoadScript(url, Dart_Null(),
                             reinterpret_cast<Dart_Handle>(kernel_pgm), 0, 0);
    } else {
      return Dart_NewApiError(error);
    }
  }
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
  if (is_dart_scheme_url) {
    ASSERT(tag == Dart_kImportTag);
    // Handle imports of other built-in libraries present in the SDK.
    if (DartUtils::IsDartIOLibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
    } else if (DartUtils::IsDartBuiltinLibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
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

static Dart_Handle LoadTestScriptWithDFE(const char* script,
                                         Dart_NativeEntryResolver resolver,
                                         const char* lib_url,
                                         bool finalize_classes) {
  Dart_Handle url = NewString(lib_url);
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  EXPECT_VALID(result);
  void* kernel_pgm = NULL;
  char* error =
      TestCase::CompileTestScriptWithDFE(lib_url, script, &kernel_pgm);
  if (error == NULL) {
    Dart_Handle lib = Dart_LoadScript(
        url, Dart_Null(), reinterpret_cast<Dart_Handle>(kernel_pgm), 0, 0);
    DART_CHECK_VALID(lib);
    result = Dart_SetNativeResolver(lib, resolver, NULL);
    DART_CHECK_VALID(result);
    if (finalize_classes) {
      result = Dart_FinalizeLoading(false);
      DART_CHECK_VALID(result);
    }
    return lib;
  } else {
    return Dart_NewApiError(error);
  }
}

Dart_Handle TestCase::LoadTestScript(const char* script,
                                     Dart_NativeEntryResolver resolver,
                                     const char* lib_url,
                                     bool finalize_classes) {
  if (!FLAG_use_dart_frontend) {
    return LoadTestScriptWithVMParser(script, resolver, lib_url,
                                      finalize_classes);
  } else {
    Zone* zone = Thread::Current()->zone();
    char* resolved_lib_url = OS::SCreate(zone, "file:///%s", lib_url);
    return LoadTestScriptWithDFE(script, resolver, resolved_lib_url,
                                 finalize_classes);
  }
}

#ifndef PRODUCT

void TestCase::SetReloadTestScript(const char* script) {
  if (script_reload_key == kUnsetThreadLocalKey) {
    script_reload_key = OSThread::CreateThreadLocal();
  }
  ASSERT(script_reload_key != kUnsetThreadLocalKey);
  ASSERT(OSThread::GetThreadLocal(script_reload_key) == 0);
  // Store the new script in TLS.
  OSThread::SetThreadLocal(script_reload_key, reinterpret_cast<uword>(script));
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
  SetReloadTestScript(script);

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
  if (FLAG_disassemble) {
    OS::Print("Code for test '%s' {\n", name_);
    const Instructions& instructions =
        Instructions::Handle(code_.instructions());
    uword start = instructions.PayloadStart();
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::Print("}\n");
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

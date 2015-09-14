// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unit_test.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "platform/globals.h"
#include "vm/assembler.h"
#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/disassembler.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/virtual_memory.h"

using dart::bin::Builtin;
using dart::bin::DartUtils;

namespace dart {

DECLARE_FLAG(bool, disassemble);

TestCaseBase* TestCaseBase::first_ = NULL;
TestCaseBase* TestCaseBase::tail_ = NULL;


TestCaseBase::TestCaseBase(const char* name) : next_(NULL), name_(name) {
  if (first_ == NULL) {
    first_ = this;
  } else {
    tail_->next_ = this;
  }
  tail_ = this;
}


void TestCaseBase::RunAll() {
  TestCaseBase* test = first_;
  while (test != NULL) {
    test->RunTest();
    test = test->next_;
  }
}

static const char* kPackageScheme = "package:";

static bool IsPackageSchemeURL(const char* url_name) {
  static const intptr_t kPackageSchemeLen = strlen(kPackageScheme);
  return (strncmp(url_name, kPackageScheme, kPackageSchemeLen) == 0);
}

static Dart_Handle ResolvePackageUri(Dart_Handle builtin_lib,
                                     const char* uri_chars) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = DartUtils::NewString(uri_chars);
  return Dart_Invoke(builtin_lib,
                     DartUtils::NewString("_filePathFromUri"),
                     kNumArgs,
                     dart_args);
}

static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
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

  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin_lib);

  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_chars);
  bool is_io_library = DartUtils::IsDartIOLibURL(library_url_string);
  if (tag == Dart_kCanonicalizeUrl) {
    // If this is a Dart Scheme URL then it is not modified as it will be
    // handled by the VM internally.
    if (is_dart_scheme_url || is_io_library) {
      return url;
    }

    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    return DartUtils::ResolveUri(library_url, url, builtin_lib);
  }
  if (is_dart_scheme_url) {
    ASSERT(tag == Dart_kImportTag);
    // Handle imports of other built-in libraries present in the SDK.
    if (DartUtils::IsDartIOLibURL(url_chars)) {
      return Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
    } else if (DartUtils::IsDartBuiltinLibURL(url_chars)) {
      return builtin_lib;
    } else {
      return DartUtils::NewError("Do not know how to load '%s'", url_chars);
    }
  }
  if (is_io_library) {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library,
                           url,
                           Builtin::PartSource(Builtin::kIOLibrary,
                                               url_chars),
                           0, 0);
  }
  if (IsPackageSchemeURL(url_chars)) {
    Dart_Handle resolved_uri = ResolvePackageUri(builtin_lib, url_chars);
    DART_CHECK_VALID(resolved_uri);
    url_chars = NULL;
    Dart_Handle result = Dart_StringToCString(resolved_uri, &url_chars);
    if (Dart_IsError(result)) {
      return Dart_NewApiError("accessing url characters failed");
    }
  }
  // Do sync loading since unit_test doesn't support async.
  Dart_Handle source = DartUtils::ReadStringFromFile(url_chars);
  EXPECT_VALID(source);
  if (tag == Dart_kImportTag) {
    return Dart_LoadLibrary(url, source, 0, 0);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, source, 0, 0);
  }
}


Dart_Handle TestCase::LoadTestScript(const char* script,
                                     Dart_NativeEntryResolver resolver,
                                     const char* lib_url,
                                     bool finalize_classes) {
  Dart_Handle url = NewString(lib_url);
  Dart_Handle source = NewString(script);
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, source, 0, 0);
  DART_CHECK_VALID(lib);
  result = Dart_SetNativeResolver(lib, resolver, NULL);
  DART_CHECK_VALID(result);
  if (finalize_classes) {
    result = Dart_FinalizeLoading(false);
    DART_CHECK_VALID(result);
  }
  return lib;
}


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
  const String& function_name = String::ZoneHandle(Symbols::New(name_));
  const Class& cls = Class::ZoneHandle(
      Class::New(function_name, Script::Handle(), Scanner::kNoSourcePos));
  const Library& lib = Library::ZoneHandle(Library::New(function_name));
  cls.set_library(lib);
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, false, cls, 0));
  code_ = Code::FinalizeCode(function, assembler_);
  if (FLAG_disassemble) {
    OS::Print("Code for test '%s' {\n", name_);
    const Instructions& instructions =
        Instructions::Handle(code_.instructions());
    uword start = instructions.EntryPoint();
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::Print("}\n");
  }
}


CodeGenTest::CodeGenTest(const char* name)
  : function_(Function::ZoneHandle()),
    node_sequence_(new SequenceNode(Scanner::kNoSourcePos,
                                    new LocalScope(NULL, 0, 0))),
    default_parameter_values_(new ZoneGrowableArray<const Instance*> ()) {
  ASSERT(name != NULL);
  const String& function_name = String::ZoneHandle(Symbols::New(name));
  // Add function to a class and that class to the class dictionary so that
  // frame walking can be used.
  const Class& cls = Class::ZoneHandle(
       Class::New(function_name, Script::Handle(), Scanner::kNoSourcePos));
  function_ = Function::New(
      function_name, RawFunction::kRegularFunction,
      true, false, false, false, false, cls, 0);
  function_.set_result_type(Type::Handle(Type::DynamicType()));
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function_);
  cls.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(cls);
}


void CodeGenTest::Compile() {
  if (function_.HasCode()) return;
  ParsedFunction* parsed_function =
      new ParsedFunction(Thread::Current(), function_);
  parsed_function->SetNodeSequence(node_sequence_);
  parsed_function->set_instantiator(NULL);
  parsed_function->set_default_parameter_values(default_parameter_values_);
  node_sequence_->scope()->AddVariable(
      parsed_function->current_context_var());
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
    OS::Print("Error compiling test script:\n%s\n",
    error.ToErrorCString());
  }
  return error.IsNull();
}


bool CompilerTest::TestCompileFunction(const Function& function) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());
  const Error& error = Error::Handle(Compiler::CompileFunction(thread,
                                                               function));
  return error.IsNull();
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

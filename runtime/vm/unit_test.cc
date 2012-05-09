// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "vm/unit_test.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "vm/assembler.h"
#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/disassembler.h"
#include "vm/parser.h"
#include "vm/virtual_memory.h"


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


static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url,
                                     Dart_Handle import_map) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString8(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_chars = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_chars);
  if (Dart_IsError(result)) {
    return Dart_Error("accessing url characters failed");
  }
  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_chars);
  if (tag == kCanonicalizeUrl) {
    // If this is a Dart Scheme URL then it is not modified as it will be
    // handled by the VM internally.
    if (is_dart_scheme_url) {
      return url;
    }
    Dart_Handle builtin_lib = Builtin::LoadLibrary(Builtin::kBuiltinLibrary);
    DART_CHECK_VALID(builtin_lib);
    return DartUtils::CanonicalizeURL(NULL, library, url_chars);
  }
  if (is_dart_scheme_url) {
    ASSERT(tag == kImportTag);
    // Handle imports of other built-in libraries present in the SDK.
    if (DartUtils::IsDartIOLibURL(url_chars)) {
      return Builtin::LoadLibrary(Builtin::kIOLibrary);
    } else if (DartUtils::IsDartJsonLibURL(url_chars)) {
      return Builtin::LoadLibrary(Builtin::kJsonLibrary);
    } else if (DartUtils::IsDartUriLibURL(url_chars)) {
      return Builtin::LoadLibrary(Builtin::kUriLibrary);
    } else if (DartUtils::IsDartUtfLibURL(url_chars)) {
      return Builtin::LoadLibrary(Builtin::kUtfLibrary);
    } else {
      return Dart_Error("Do not know how to load '%s'", url_chars);
    }
  }
  result = DartUtils::LoadSource(NULL,
                                 library,
                                 url,
                                 tag,
                                 url_chars,
                                 import_map);
  if (!Dart_IsError(result) && (tag == kImportTag)) {
    Builtin::ImportLibrary(result, Builtin::kBuiltinLibrary);
  }
  return result;
}


Dart_Handle TestCase::LoadTestScript(const char* script,
                                     Dart_NativeEntryResolver resolver,
                                     Dart_Handle import_map) {
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(script);
  Dart_Handle lib = Dart_LoadScript(url, source, LibraryTagHandler, import_map);
  DART_CHECK_VALID(lib);
  Dart_Handle result = Dart_SetNativeResolver(lib, resolver);
  DART_CHECK_VALID(result);
  return lib;
}


Dart_Handle TestCase::lib() {
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(lib);
  ASSERT(Dart_IsLibrary(lib));
  return lib;
}


Dart_Handle TestCase::library_handler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url,
                                      Dart_Handle import_map) {
  if (tag == kCanonicalizeUrl) {
    return url;
  }
  return Api::Success(Isolate::Current());
}


uword AssemblerTest::Assemble() {
  const String& function_name = String::ZoneHandle(String::NewSymbol(name_));
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kFunction, true, false, 0));
  const Code& code = Code::Handle(Code::FinalizeCode(function, assembler_));
  if (FLAG_disassemble) {
    OS::Print("Code for test '%s' {\n", name_);
    const Instructions& instructions =
        Instructions::Handle(code.instructions());
    uword start = instructions.EntryPoint();
    Disassembler::Disassemble(start, start + assembler_->CodeSize());
    OS::Print("}\n");
  }
  const Instructions& instructions = Instructions::Handle(code.instructions());
  return instructions.EntryPoint();
}


CodeGenTest::CodeGenTest(const char* name)
  : function_(Function::ZoneHandle()),
    node_sequence_(new SequenceNode(Scanner::kDummyTokenIndex,
                                    new LocalScope(NULL, 0, 0))),
    default_parameter_values_(Array::ZoneHandle()) {
  ASSERT(name != NULL);
  const String& function_name = String::ZoneHandle(String::NewSymbol(name));
  function_ = Function::New(
      function_name, RawFunction::kFunction, true, false, 0);
  function_.set_result_type(Type::Handle(Type::DynamicType()));
  // Add function to a class and that class to the class dictionary so that
  // frame walking can be used.
  Class& cls = Class::ZoneHandle();
  const Script& script = Script::Handle();
  cls = Class::New(function_name, script, Scanner::kDummyTokenIndex);
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function_);
  cls.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(cls);
}


void CodeGenTest::Compile() {
  ParsedFunction parsed_function(function_);
  parsed_function.SetNodeSequence(node_sequence_);
  parsed_function.set_instantiator(NULL);
  parsed_function.set_default_parameter_values(default_parameter_values_);
  parsed_function.AllocateVariables();
  const Error& error =
      Error::Handle(Compiler::CompileParsedFunction(parsed_function));
  EXPECT(error.IsNull());
}


bool CompilerTest::TestCompileScript(const Library& library,
                                     const Script& script) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(Compiler::Compile(library, script));
  return error.IsNull();
}


bool CompilerTest::TestCompileFunction(const Function& function) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());
  const Error& error = Error::Handle(Compiler::CompileFunction(function));
  return error.IsNull();
}

}  // namespace dart

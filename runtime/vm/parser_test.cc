// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#include "vm/ast_printer.h"
#include "vm/class_finalizer.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {


void DumpFunction(const Library& lib, const char* cname, const char* fname) {
  const String& classname = String::Handle(Symbols::New(cname));
  Class& cls = Class::Handle(lib.LookupClass(classname));
  EXPECT(!cls.IsNull());

  String& funcname = String::Handle(String::New(fname));
  Function& function = Function::Handle(cls.LookupStaticFunction(funcname));
  EXPECT(!function.IsNull());

  bool retval;
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    ParsedFunction* parsed_function = new ParsedFunction(function);
    Parser::ParseFunction(parsed_function);
    EXPECT(parsed_function->node_sequence() != NULL);
    printf("Class %s function %s:\n", cname, fname);
    AstPrinter::PrintFunctionNodes(*parsed_function);
    retval = true;
  } else {
    retval = false;
  }
  EXPECT(retval);
  isolate->set_long_jump_base(base);
}


void CheckField(const Library& lib,
                const char* class_name,
                const char* field_name,
                bool expect_static,
                bool is_final) {
  const String& classname = String::Handle(Symbols::New(class_name));
  Class& cls = Class::Handle(lib.LookupClass(classname));
  EXPECT(!cls.IsNull());

  String& fieldname = String::Handle(String::New(field_name));
  String& functionname = String::Handle();
  Function& function = Function::Handle();
  Field& field = Field::Handle();
  if (expect_static) {
    field ^= cls.LookupStaticField(fieldname);
    functionname ^= Field::GetterName(fieldname);
    function ^= cls.LookupStaticFunction(functionname);
    EXPECT(function.IsNull());
    functionname ^= Field::SetterName(fieldname);
    function ^= cls.LookupStaticFunction(functionname);
    EXPECT(function.IsNull());
  } else {
    field ^= cls.LookupInstanceField(fieldname);
    functionname ^= Field::GetterName(fieldname);
    function ^= cls.LookupDynamicFunction(functionname);
    EXPECT(!function.IsNull());
    functionname ^= Field::SetterName(fieldname);
    function ^= cls.LookupDynamicFunction(functionname);
    EXPECT(is_final ? function.IsNull() : !function.IsNull());
  }
  EXPECT(!field.IsNull());

  EXPECT_EQ(field.is_static(), expect_static);
}


void CheckFunction(const Library& lib,
                   const char* class_name,
                   const char* function_name,
                   bool expect_static) {
  const String& classname = String::Handle(Symbols::New(class_name));
  Class& cls = Class::Handle(lib.LookupClass(classname));
  EXPECT(!cls.IsNull());

  String& functionname = String::Handle(String::New(function_name));
  Function& function = Function::Handle();
  if (expect_static) {
    function ^= cls.LookupStaticFunction(functionname);
  } else {
    function ^= cls.LookupDynamicFunction(functionname);
  }
  EXPECT(!function.IsNull());
}


TEST_CASE(ParseClassDefinition) {
  const char* script_chars =
      "class C { }  \n"
      "class A {    \n"
      "  var f0;              \n"
      "  int f1;              \n"
      "  final f2;            \n"
      "  final int f3, f4;    \n"
      "  static String s1, s2;   \n"
      "  static const int s3 = 8675309;    \n"
      "  static bar(i, [var d = 5]) { return 77; } \n"
      "  static foo() native \"native_function_name\";        \n"
      "}  \n";

  String& url = String::Handle(String::New("dart-test:Parser_TopLevel"));
  String& source = String::Handle(String::New(script_chars));
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kSourceTag));
  Library& lib = Library::ZoneHandle(Library::CoreLibrary());

  script.Tokenize(String::Handle(String::New("")));

  Parser::ParseCompilationUnit(lib, script);
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  CheckField(lib, "A", "f1", false, false);
  CheckField(lib, "A", "f2", false, true);
  CheckField(lib, "A", "f3", false, true);
  CheckField(lib, "A", "f4", false, true);
  CheckField(lib, "A", "s1", true, false);
  CheckField(lib, "A", "s2", true, false);
  CheckField(lib, "A", "s3", true, true);
  CheckFunction(lib, "A", "bar", true);
  CheckFunction(lib, "A", "foo", true);
}


TEST_CASE(Parser_TopLevel) {
  const char* script_chars =
      "class A extends B {    \n"
      "  static bar(var i, [var d = 5]) { return 77; } \n"
      "  static foo() { return 42; } \n"
      "  static baz(var i) { var q = 5; return i + q; } \n"
      "}   \n"
      "    \n"
      "class B {  \n"
      "  static bam(k) { return A.foo(); }   \n"
      "}   \n";

  String& url = String::Handle(String::New("dart-test:Parser_TopLevel"));
  String& source = String::Handle(String::New(script_chars));
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kSourceTag));
  Library& lib = Library::ZoneHandle(Library::CoreLibrary());

  script.Tokenize(String::Handle(String::New("")));

  Parser::ParseCompilationUnit(lib, script);
  EXPECT(ClassFinalizer::FinalizePendingClasses());

  DumpFunction(lib, "A", "foo");
  DumpFunction(lib, "A", "bar");
  DumpFunction(lib, "A", "baz");
  DumpFunction(lib, "B", "bam");
}

}  // namespace dart

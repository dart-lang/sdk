// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#include "vm/ast_printer.h"
#include "vm/class_finalizer.h"
#include "vm/debugger.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/unit_test.h"

namespace dart {

DECLARE_FLAG(bool, show_invisible_frames);


static void DumpFunction(const Library& lib,
                         const char* cname,
                         const char* fname) {
  const String& classname =
      String::Handle(Symbols::New(Thread::Current(), cname));
  String& funcname = String::Handle(String::New(fname));

  bool retval;
  EXPECT(Isolate::Current() != NULL);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Class& cls = Class::Handle(lib.LookupClass(classname));
    EXPECT(!cls.IsNull());
    Function& function =
        Function::ZoneHandle(cls.LookupStaticFunction(funcname));
    EXPECT(!function.IsNull());
    ParsedFunction* parsed_function =
        new ParsedFunction(Thread::Current(), function);
    Parser::ParseFunction(parsed_function);
    EXPECT(parsed_function->node_sequence() != NULL);
    printf("Class %s function %s:\n", cname, fname);
    if (FLAG_support_ast_printer) {
      AstPrinter ast_printer;
      ast_printer.PrintFunctionNodes(*parsed_function);
    } else {
      OS::Print("AST printer not supported.");
    }
    retval = true;
  } else {
    retval = false;
  }
  EXPECT(retval);
}


void CheckField(const Library& lib,
                const char* class_name,
                const char* field_name,
                bool expect_static,
                bool is_final) {
  const String& classname =
      String::Handle(Symbols::New(Thread::Current(), class_name));
  Class& cls = Class::Handle(lib.LookupClass(classname));
  EXPECT(!cls.IsNull());

  String& fieldname = String::Handle(String::New(field_name));
  String& functionname = String::Handle();
  Function& function = Function::Handle();
  Field& field = Field::Handle();
  if (expect_static) {
    field ^= cls.LookupStaticFieldAllowPrivate(fieldname);
    functionname ^= Field::GetterName(fieldname);
    function ^= cls.LookupStaticFunction(functionname);
    EXPECT(function.IsNull());
    functionname ^= Field::SetterName(fieldname);
    function ^= cls.LookupStaticFunction(functionname);
    EXPECT(function.IsNull());
  } else {
    field ^= cls.LookupInstanceFieldAllowPrivate(fieldname);
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
  const String& classname =
      String::Handle(Symbols::New(Thread::Current(), class_name));
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
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = Library::ZoneHandle(Library::CoreLibrary());

  script.Tokenize(String::Handle(String::New("")));

  Parser::ParseCompilationUnit(lib, script);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
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
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = Library::ZoneHandle(Library::CoreLibrary());

  script.Tokenize(String::Handle(String::New("")));

  Parser::ParseCompilationUnit(lib, script);
  EXPECT(ClassFinalizer::ProcessPendingClasses());

  DumpFunction(lib, "A", "foo");
  DumpFunction(lib, "A", "bar");
  DumpFunction(lib, "A", "baz");
  DumpFunction(lib, "B", "bam");
}


#ifndef PRODUCT


static const char* saved_vars = NULL;


static char* SkipIndex(const char* input) {
  char* output_buffer = new char[strlen(input)];
  char* output = output_buffer;

  while (input[0] != '\0') {
    const char* index_pos = strstr(input, "index=");
    if (index_pos == NULL) {
      while (input[0] != '\0') {
        *output++ = *input++;
      }
      break;
    }

    // Copy prefix until "index="
    while (input < index_pos) {
      *output++ = *input++;
    }

    // Skip until space.
    input += strcspn(input, " ");
    // Skip until next non-space.
    input += strspn(input, " ");
  }

  output[0] = '\0';
  return output_buffer;
}


// Saves the var descriptors for all frames on the stack as a string.
static void SaveVars(Dart_IsolateId isolate_id,
                     intptr_t bp_id,
                     const Dart_CodeLocation& loc) {
  DebuggerStackTrace* stack = Isolate::Current()->debugger()->StackTrace();
  intptr_t num_frames = stack->Length();
  const int kBufferLen = 2048;
  char* buffer = new char[kBufferLen];
  char* pos = buffer;
  LocalVarDescriptors& var_desc = LocalVarDescriptors::Handle();
  for (intptr_t i = 0; i < num_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    var_desc = frame->code().GetLocalVarDescriptors();
    const char* var_str = SkipIndex(var_desc.ToCString());
    const char* function_str =
        String::Handle(frame->function().QualifiedUserVisibleName())
            .ToCString();
    pos += OS::SNPrint(pos, (kBufferLen - (pos - buffer)), "%s\n%s",
                       function_str, var_str);
    delete[] var_str;
  }
  pos[0] = '\0';
  saved_vars = buffer;
}


// Uses the debugger to pause the program and capture the variable
// descriptors for all frames on the stack.
static const char* CaptureVarsAtLine(Dart_Handle lib,
                                     const char* entry,
                                     int line) {
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  bool saved_flag = FLAG_show_invisible_frames;
  FLAG_show_invisible_frames = true;
  Dart_SetPausedEventHandler(SaveVars);
  EXPECT_VALID(Dart_SetBreakpoint(NewString(TestCase::url()), line));
  saved_vars = NULL;
  EXPECT_VALID(Dart_Invoke(lib, NewString(entry), 0, NULL));
  const char* tmp = saved_vars;
  saved_vars = NULL;
  FLAG_show_invisible_frames = saved_flag;
  return tmp;
}


TEST_CASE(Parser_AllocateVariables_CapturedVar) {
  const char* kScriptChars =
      "int main() {\n"
      "  var value = 11;\n"
      "  int f(var param) {\n"
      "    return param + value;\n"  // line 4
      "  }\n"
      "  return f(22);\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ(
      // function f uses one ctx var at (0); doesn't save ctx.
      "main.f\n"
      " 0 ContextVar    level=0   begin=14  end=28  name=value\n"
      " 1 StackVar      scope=1   begin=16  end=28  name=param\n"
      " 2 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // function main uses one ctx var at (1); saves caller ctx.
      "main\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 ContextLevel  level=1   scope=2   begin=4   end=37\n"
      " 2 ContextVar    level=1   begin=10  end=37  name=value\n"
      " 3 StackVar      scope=2   begin=12  end=37  name=f\n",
      CaptureVarsAtLine(lib, "main", 4));
}


TEST_CASE(Parser_AllocateVariables_NestedCapturedVar) {
  const char* kScriptChars =
      "int a() {\n"
      "  int b() {\n"
      "    var value = 11;\n"
      "    int c() {\n"
      "      return value;\n"  // line 5
      "    }\n"
      "    return c();\n"
      "  }\n"
      "  return b();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ(
      // Innermost function uses captured variable 'value' from middle
      // function.
      "a.b.c\n"
      " 0 ContextVar    level=0   begin=20  end=30  name=value\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Middle function saves the entry context.  Notice that this
      // happens here and not in the outermost function.  We always
      // save the entry context at the last possible moment.
      "a.b\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 ContextLevel  level=1   scope=2   begin=10  end=38\n"
      " 2 ContextVar    level=1   begin=16  end=38  name=value\n"
      " 3 StackVar      scope=2   begin=18  end=38  name=c\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Outermost function neglects to save the entry context.  We
      // don't save the entry context if the function has no captured
      // variables.
      "a\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 StackVar      scope=2   begin=6   end=46  name=b\n",
      CaptureVarsAtLine(lib, "a", 5));
}


TEST_CASE(Parser_AllocateVariables_TwoChains) {
  const char* kScriptChars =
      "int a() {\n"
      "  var value1 = 11;\n"
      "  int b() {\n"
      "    int aa() {\n"
      "      var value2 = 12;\n"
      "      int bb() {\n"
      "        return value2;\n"  // line 7
      "      }\n"
      "      return bb();\n"
      "    }\n"
      "    return value1 + aa();\n"
      "  }\n"
      "  return b();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ(
      // bb captures only value2 from aa.  No others.
      "a.b.aa.bb\n"
      " 0 ContextVar    level=0   begin=33  end=43  name=value2\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // aa shares value2. Notice that we save the entry ctx instead
      // of chaining from b.  This keeps us from holding onto closures
      // that we would never access.
      "a.b.aa\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 ContextLevel  level=1   scope=2   begin=22  end=52\n"
      " 2 ContextVar    level=1   begin=28  end=52  name=value2\n"
      " 3 StackVar      scope=2   begin=30  end=52  name=bb\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // b captures value1 from a.
      "a.b\n"
      " 0 ContextVar    level=0   begin=14  end=62  name=value1\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 2 StackVar      scope=2   begin=18  end=62  name=aa\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // a shares value1, saves entry ctx.
      "a\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 ContextLevel  level=1   scope=2   begin=4   end=70\n"
      " 2 ContextVar    level=1   begin=10  end=70  name=value1\n"
      " 3 StackVar      scope=2   begin=12  end=70  name=b\n",
      CaptureVarsAtLine(lib, "a", 7));
}


TEST_CASE(Parser_AllocateVariables_Issue7681) {
  // This is a distilled version of the program from Issue 7681.
  //
  // When we create the closure at line 11, we need to make sure to
  // save the entry context instead of chaining to the parent context.
  //
  // This test is somewhat redundant with CapturedVarChain but
  // included for good measure.
  const char* kScriptChars =
      "class X {\n"
      "  Function onX;\n"
      "}\n"
      "\n"
      "class Y {\n"
      "  Function onY;\n"
      "}\n"
      "\n"
      "void doIt() {\n"
      "  var x = new X();\n"
      "  x.onX = (y) {\n"
      "    y.onY = () {\n"  // line 12
      "      return y;\n"
      "    };\n"
      "  };\n"
      "   x.onX(new Y());\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ(
      // This frame saves the entry context instead of chaining.  Good.
      "doIt.<anonymous closure>\n"
      " 0 ContextLevel  level=1   scope=1   begin=41  end=62\n"
      " 1 ContextVar    level=1   begin=42  end=62  name=y\n"
      " 2 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      "X.onX\n"
      " 0 StackVar      scope=1   begin=0   end=0   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // No context is saved here since no vars are captured.
      "doIt\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 StackVar      scope=2   begin=35  end=77  name=x\n",
      CaptureVarsAtLine(lib, "doIt", 12));
}


TEST_CASE(Parser_AllocateVariables_CaptureLoopVar) {
  // This test verifies that...
  //
  //   https://code.google.com/p/dart/issues/detail?id=18561
  //
  // ...stays fixed.
  const char* kScriptChars =
      "int outer() {\n"
      "  for(int i = 0; i < 1; i++) {\n"
      "    var value = 11 + i;\n"
      "    int inner() {\n"
      "      return value;\n"  // line 5
      "    }\n"
      "    return inner();\n"
      "  }\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ(
      // inner function captures variable value.  That's fine.
      "outer.inner\n"
      " 0 ContextVar    level=0   begin=32  end=42  name=value\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Closure call saves current context.
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // The outer function saves the entry context, even though the
      // captured variable is in a loop.  Good.
      "outer\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 StackVar      scope=3   begin=12  end=50  name=i\n"
      " 2 ContextLevel  level=1   scope=4   begin=20  end=50\n"
      " 3 ContextVar    level=1   begin=28  end=50  name=value\n"
      " 4 StackVar      scope=4   begin=30  end=50  name=inner\n",
      CaptureVarsAtLine(lib, "outer", 5));
}

TEST_CASE(Parser_AllocateVariables_MiddleChain) {
  const char* kScriptChars =
      "a() {\n"
      "  int x = 11;\n"
      "  b() {\n"
      "    for (int i = 0; i < 1; i++) {\n"
      "      int d() {\n"
      "        return i;\n"
      "      }\n"
      "    }\n"
      "    int c() {\n"
      "      return x + 1;\n"  // line 10
      "    }\n"
      "    return c();\n"
      "  }\n"
      "  return b();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ(
      "a.b.c\n"
      " 0 ContextVar    level=0   begin=50  end=62  name=x\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      // Doesn't save the entry context.  Chains to parent instead.
      "a.b\n"
      " 0 ContextVar    level=0   begin=12  end=71  name=x\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 2 StackVar      scope=2   begin=47  end=71  name=c\n"
      " 3 ContextLevel  level=1   scope=3   begin=18  end=47\n"
      " 4 ContextVar    level=1   begin=22  end=47  name=i\n"
      " 5 StackVar      scope=4   begin=32  end=47  name=d\n"

      "_Closure.call\n"
      " 0 StackVar      scope=1   begin=0   end=4   name=this\n"
      " 1 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"

      "a\n"
      " 0 CurrentCtx    scope=0   begin=0   end=0"
      "   name=:current_context_var\n"
      " 1 ContextLevel  level=1   scope=2   begin=3   end=79\n"
      " 2 ContextVar    level=1   begin=9   end=79  name=x\n"
      " 3 StackVar      scope=2   begin=11  end=79  name=b\n",
      CaptureVarsAtLine(lib, "a", 10));
}

#endif  // !PRODUCT

}  // namespace dart

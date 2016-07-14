// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

// TODO(johnmccutchan):
// - Tests involving generics.

int64_t SimpleInvoke(Dart_Handle lib, const char* method) {
  Dart_Handle result = Dart_Invoke(lib, NewString(method), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t integer_result = 0;
  result = Dart_IntegerToInt64(result, &integer_result);
  EXPECT_VALID(result);
  return integer_result;
}


const char* SimpleInvokeStr(Dart_Handle lib, const char* method) {
  Dart_Handle result = Dart_Invoke(lib, NewString(method), 0, NULL);
  const char* result_str = NULL;
  EXPECT(Dart_IsString(result));
  EXPECT_VALID(Dart_StringToCString(result, &result_str));
  return result_str;
}


Dart_Handle SimpleInvokeError(Dart_Handle lib, const char* method) {
  Dart_Handle result = Dart_Invoke(lib, NewString(method), 0, NULL);
  EXPECT(Dart_IsError(result));
  return result;
}


TEST_CASE(IsolateReload_FunctionReplacement) {
  const char* kScript =
      "main() {\n"
      "  return 4;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "main() {\n"
      "  return 10;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_EQ(10, SimpleInvoke(lib, "main"));
}


TEST_CASE(IsolateReload_BadClass) {
  const char* kScript =
      "class Foo {\n"
      "  final a;\n"
      "  Foo(this.a);\n"
      "}\n"
      "main() {\n"
      "  new Foo(5);\n"
      "  return 4;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "class Foo {\n"
      "  final a kjsdf ksjdf ;\n"
      "  Foo(this.a);\n"
      "}\n"
      "main() {\n"
      "  new Foo(5);\n"
      "  return 10;\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(result, "unexpected token");

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));
}


TEST_CASE(IsolateReload_StaticValuePreserved) {
  const char* kScript =
      "init() => 'old value';\n"
      "var value = init();\n"
      "main() {\n"
      "  return 'init()=${init()},value=${value}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("init()=old value,value=old value",
               SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "init() => 'new value';\n"
      "var value = init();\n"
      "main() {\n"
      "  return 'init()=${init()},value=${value}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("init()=new value,value=old value",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_SavedClosure) {
  // Create a closure in main which only exists in the original source.
  const char* kScript =
      "magic() {\n"
      "  var x = 'ante';\n"
      "  return x + 'diluvian';\n"
      "}\n"
      "var closure;\n"
      "main() {\n"
      "  closure = () { return magic().toString() + '!'; };\n"
      "  return closure();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("antediluvian!", SimpleInvokeStr(lib, "main"));

  // Remove the original closure from the source code.  The closure is
  // able to be recompiled because its source is preserved in a
  // special patch class.
  const char* kReloadScript =
      "magic() {\n"
      "  return 'postapocalyptic';\n"
      "}\n"
      "var closure;\n"
      "main() {\n"
      "  return closure();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("postapocalyptic!", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_TopLevelFieldAdded) {
  const char* kScript =
      "var value1 = 10;\n"
      "main() {\n"
      "  return 'value1=${value1}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("value1=10", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "var value1 = 10;\n"
      "var value2 = 20;\n"
      "main() {\n"
      "  return 'value1=${value1},value2=${value2}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("value1=10,value2=20",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_ClassFieldAdded) {
  const char* kScript =
      "class Foo {\n"
      "  var x;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(44, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var x;\n"
      "  var y;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "Number of instance fields changed");
}


TEST_CASE(IsolateReload_ClassFieldAdded2) {
  const char* kScript =
      "class Foo {\n"
      "  var x;\n"
      "  var y;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(44, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var x;\n"
      "  var y;\n"
      "  var z;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "Number of instance fields changed");
}


TEST_CASE(IsolateReload_ClassFieldRemoved) {
  const char* kScript =
      "class Foo {\n"
      "  var x;\n"
      "  var y;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(44, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var x;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 44;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "Number of instance fields changed");
}


TEST_CASE(IsolateReload_ClassAdded) {
  const char* kScript =
      "main() {\n"
      "  return 'hello';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("hello", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "class A {\n"
      "  toString() => 'hello from A';\n"
      "}\n"
      "main() {\n"
      "  return new A().toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("hello from A", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_LibraryImportAdded) {
  const char* kScript =
      "main() {\n"
      "  return max(3, 4);\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "max");;

  const char* kReloadScript =
      "import 'dart:math';\n"
      "main() {\n"
      "  return max(3, 4);\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));
}


TEST_CASE(IsolateReload_LibraryImportRemoved) {
  const char* kScript =
      "import 'dart:math';\n"
      "main() {\n"
      "  return max(3, 4);\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "main() {\n"
      "  return max(3, 4);\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "max");;
}


TEST_CASE(IsolateReload_LibraryDebuggable) {
  const char* kScript =
      "main() {\n"
      "  return 1;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  // The library is by default debuggable.  Make it not debuggable.
  intptr_t lib_id = -1;
  bool debuggable = false;
  EXPECT_VALID(Dart_LibraryId(lib, &lib_id));
  EXPECT_VALID(Dart_GetLibraryDebuggable(lib_id, &debuggable));
  EXPECT_EQ(true, debuggable);
  EXPECT_VALID(Dart_SetLibraryDebuggable(lib_id, false));
  EXPECT_VALID(Dart_GetLibraryDebuggable(lib_id, &debuggable));
  EXPECT_EQ(false, debuggable);

  EXPECT_EQ(1, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "main() {\n"
      "  return 2;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_EQ(2, SimpleInvoke(lib, "main"));

  // Library debuggability is preserved.
  intptr_t new_lib_id = -1;
  EXPECT_VALID(Dart_LibraryId(lib, &new_lib_id));
  EXPECT_VALID(Dart_GetLibraryDebuggable(new_lib_id, &debuggable));
  EXPECT_EQ(false, debuggable);
}


TEST_CASE(IsolateReload_ImplicitConstructorChanged) {
  // Note that we are checking that the value 20 gets cleared from the
  // compile-time constants cache.  To make this test work, "20" and
  // "10" need to be at the same token position.
  const char* kScript =
      "class A {\n"
      "  int field = 20;\n"
      "}\n"
      "var savedA = new A();\n"
      "main() {\n"
      "  var newA = new A();\n"
      "  return 'saved:${savedA.field} new:${newA.field}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("saved:20 new:20", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class A {\n"
      "  int field = 10;\n"
      "}\n"
      "var savedA = new A();\n"
      "main() {\n"
      "  var newA = new A();\n"
      "  return 'saved:${savedA.field} new:${newA.field}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("saved:20 new:10", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_ConstructorChanged) {
  const char* kScript =
      "class A {\n"
      "  int field;\n"
      "  A() { field = 20; }\n"
      "}\n"
      "var savedA = new A();\n"
      "main() {\n"
      "  var newA = new A();\n"
      "  return 'saved:${savedA.field} new:${newA.field}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("saved:20 new:20", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "class A {\n"
      "  int field;\n"
      "  A() { field = 10; }\n"
      "}\n"
      "var savedA = new A();\n"
      "main() {\n"
      "  var newA = new A();\n"
      "  return 'saved:${savedA.field} new:${newA.field}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("saved:20 new:10", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_SuperClassChanged) {
  const char* kScript =
      "class A {\n"
      "}\n"
      "class B extends A {\n"
      "}\n"
      "var list = [ new A(), new B() ];\n"
      "main() {\n"
      "  return (list.map((x) => '${x is A}/${x is B}')).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("(true/false, true/true)", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "var _unused;"
      "class B{\n"
      "}\n"
      "class A extends B {\n"
      "}\n"
      "var list = [ new A(), new B() ];\n"
      "main() {\n"
      "  return (list.map((x) => '${x is A}/${x is B}')).toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("(true/true, false/true)", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_Generics) {
  // Reload a program with generics without changing the source.  We
  // do this to produce duplication TypeArguments and make sure that
  // the system doesn't die.
  const char* kScript =
      "class A {\n"
      "}\n"
      "class B<T extends A> {\n"
      "}\n"
      "main() {\n"
      "  return new B<A>().toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Instance of 'B<A>'", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class A {\n"
      "}\n"
      "class B<T extends A> {\n"
      "}\n"
      "main() {\n"
      "  return new B<A>().toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Instance of 'B<A>'", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_MixinChanged) {
  const char* kScript =
      "class Mixin1 {\n"
      "  var field = 'mixin1';\n"
      "  func() => 'mixin1';\n"
      "}\n"
      "class B extends Object with Mixin1 {\n"
      "}\n"
      "var saved = new B();\n"
      "main() {\n"
      "  return 'saved:field=${saved.field},func=${saved.func()}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("saved:field=mixin1,func=mixin1",
               SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class Mixin2 {\n"
      "  var field = 'mixin2';\n"
      "  func() => 'mixin2';\n"
      "}\n"
      "class B extends Object with Mixin2 {\n"
      "}\n"
      "var saved = new B();\n"
      "main() {\n"
      "  var newer = new B();\n"
      "  return 'saved:field=${saved.field},func=${saved.func()} '\n"
      "         'newer:field=${newer.field},func=${newer.func()}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  // The saved instance of B retains its old field value from mixin1,
  // but it gets the new implementation of func from mixin2.
  EXPECT_STREQ("saved:field=mixin1,func=mixin2 "
               "newer:field=mixin2,func=mixin2",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_ComplexInheritanceChange) {
  const char* kScript =
      "class A {\n"
      "  String name;\n"
      "  A(this.name);\n"
      "}\n"
      "class B extends A {\n"
      "  B(name) : super(name);\n"
      "}\n"
      "class C extends B {\n"
      "  C(name) : super(name);\n"
      "}\n"
      "var list = [ new A('a'), new B('b'), new C('c') ];\n"
      "main() {\n"
      "  return (list.map((x) {\n"
      "    return '${x.name} is A(${x is A})/ B(${x is B})/ C(${x is C})';\n"
      "  })).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("(a is A(true)/ B(false)/ C(false),"
               " b is A(true)/ B(true)/ C(false),"
               " c is A(true)/ B(true)/ C(true))",
               SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class C {\n"
      "  String name;\n"
      "  C(this.name);\n"
      "}\n"
      "class X extends C {\n"
      "  X(name) : super(name);\n"
      "}\n"
      "class A extends X {\n"
      "  A(name) : super(name);\n"
      "}\n"
      "var list;\n"
      "main() {\n"
      "  list.add(new X('x'));\n"
      "  return (list.map((x) {\n"
      "    return '${x.name} is A(${x is A})/ C(${x is C})/ X(${x is X})';\n"
      "  })).toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("(a is A(true)/ C(true)/ X(true),"
               " b is A(true)/ C(true)/ X(true),"  // still extends A...
               " c is A(false)/ C(true)/ X(false),"
               " x is A(false)/ C(true)/ X(true))",
               SimpleInvokeStr(lib, "main"));

  // Revive the class B and make sure all allocated instances take
  // their place in the inheritance hierarchy.
  const char* kReloadScript2 =
      "class X {\n"
      "  String name;\n"
      "  X(this.name);\n"
      "}\n"
      "class A extends X{\n"
      "  A(name) : super(name);\n"
      "}\n"
      "class B extends X {\n"
      "  B(name) : super(name);\n"
      "}\n"
      "class C extends A {\n"
      "  C(name) : super(name);\n"
      "}\n"
      "var list;\n"
      "main() {\n"
      "  return (list.map((x) {\n"
      "    return '${x.name} is '\n"
      "           'A(${x is A})/ B(${x is B})/ C(${x is C})/ X(${x is X})';\n"
      "  })).toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript2);
  EXPECT_VALID(lib);

  EXPECT_STREQ("(a is A(true)/ B(false)/ C(false)/ X(true),"
               " b is A(false)/ B(true)/ C(false)/ X(true),"
               " c is A(true)/ B(false)/ C(true)/ X(true),"
               " x is A(false)/ B(false)/ C(false)/ X(true))",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_LiveStack) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "helper() => 7;\n"
      "alpha() { var x = helper(); reloadTest(); return x + helper(); }\n"
      "foo() => alpha();\n"
      "bar() => foo();\n"
      "main() {\n"
      "  return bar();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "helper() => 100;\n"
      "alpha() => 5 + helper();\n"
      "foo() => alpha();\n"
      "bar() => foo();\n"
      "main() {\n"
      "  return bar();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ(107, SimpleInvoke(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ(105, SimpleInvoke(lib, "main"));
}


TEST_CASE(IsolateReload_LibraryLookup) {
  const char* kScript =
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  Dart_Handle result;

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "importedFunc");

  // Fail to find 'test:importable_lib' in the isolate.
  result = Dart_LookupLibrary(NewString("test:importable_lib"));
  EXPECT(Dart_IsError(result));

  const char* kReloadScript =
      "import 'test:importable_lib';\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  // Reload and add 'test:importable_lib' to isolate.
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("a", SimpleInvokeStr(lib, "main"));

  // Find 'test:importable_lib' in the isolate.
  result = Dart_LookupLibrary(NewString("test:importable_lib"));
  EXPECT(Dart_IsLibrary(result));

  // Reload and remove 'dart:math' from isolate.
  lib = TestCase::ReloadTestScript(kScript);
  EXPECT_VALID(lib);

  // Fail to find 'test:importable_lib' in the isolate.
  result = Dart_LookupLibrary(NewString("test:importable_lib"));
  EXPECT(Dart_IsError(result));
}


TEST_CASE(IsolateReload_LibraryHide) {
  // Import 'test:importable_lib' with importedFunc hidden. Will result in an
  // error.
  const char* kScript =
      "import 'test:importable_lib' hide importedFunc;\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  // Dart_Handle result;

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "importedFunc");

  // Import 'test:importable_lib'.
  const char* kReloadScript =
      "import 'test:importable_lib';\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("a", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_LibraryShow) {
  // Import 'test:importable_lib' with importedIntFunc visible. Will result in
  // an error when 'main' is invoked.
  const char* kScript =
      "import 'test:importable_lib' show importedIntFunc;\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n"
      "mainInt() {\n"
      "  return importedIntFunc();\n"
      "}\n";


  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  // Works.
  EXPECT_EQ(4, SimpleInvoke(lib, "mainInt"));
  // Results in an error.
  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "importedFunc");

  // Import 'test:importable_lib' with importedFunc visible. Will result in
  // an error when 'mainInt' is invoked.
  const char* kReloadScript =
      "import 'test:importable_lib' show importedFunc;\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n"
      "mainInt() {\n"
      "  return importedIntFunc();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  // Works.
  EXPECT_STREQ("a", SimpleInvokeStr(lib, "main"));
  // Results in an error.
  EXPECT_ERROR(SimpleInvokeError(lib, "mainInt"), "importedIntFunc");
}


// Verifies that we clear the ICs for the functions live on the stack in a way
// that is compatible with the fast path smi stubs.
TEST_CASE(IsolateReload_SmiFastPathStubs) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "import 'test:importable_lib' show importedIntFunc;\n"
      "main() {\n"
      "  var x = importedIntFunc();\n"
      "  var y = importedIntFunc();\n"
      "  reloadTest();\n"
      "  return x + y;\n"
      "}\n";


  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  // Identity reload.
  TestCase::SetReloadTestScript(kScript);

  EXPECT_EQ(8, SimpleInvoke(lib, "main"));
}


// Verifies that we assign the correct patch classes for imported
// mixins when we reload.
TEST_CASE(IsolateReload_ImportedMixinFunction) {
  const char* kScript =
      "import 'test:importable_lib' show ImportedMixin;\n"
      "class A extends Object with ImportedMixin {\n"
      "}"
      "var func = new A().mixinFunc;\n"
      "main() {\n"
      "  return func();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("mixin", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "import 'test:importable_lib' show ImportedMixin;\n"
      "class A extends Object with ImportedMixin {\n"
      "}"
      "var func;\n"
      "main() {\n"
      "  return func();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("mixin", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_TopLevelParseError) {
  const char* kScript =
      "main() {\n"
      "  return 4;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "kjsadkfjaksldfjklsadf;\n"
      "main() {\n"
      "  return 4;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "unexpected token");
}


TEST_CASE(IsolateReload_PendingUnqualifiedCall_StaticToInstance) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'static';\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'instance';\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("instance", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("instance", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingUnqualifiedCall_InstanceToStatic) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'instance';\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'static';\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("static", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("static", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingConstructorCall_AbstractToConcrete) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "abstract class Foo {}\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return new Foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    new C().test();\n"
      "    return 'okay';\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class Foo {}\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return new Foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    new C().test();\n"
      "    return 'okay';\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("okay", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("okay", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingConstructorCall_ConcreteToAbstract) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class Foo {}\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return new Foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    new C().test();\n"
      "    return 'okay';\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "abstract class Foo {}\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return new Foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    new C().test();\n"
      "    return 'okay';\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("exception", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("exception", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingStaticCall_DefinedToNSM) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'static'\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return C.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    return new C().test();\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return C.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    return new C().test();\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("exception", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("exception", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingStaticCall_NSMToDefined) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return C.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    return new C().test();\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'static'\n"
      "  test() {\n"
      "    reloadTest();\n"
      "    return C.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    return new C().test();\n"
      "  } catch (e) {\n"
      "    return 'exception';\n"
      "  }\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ("static", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);

  EXPECT_EQ("static", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_PendingSuperCall) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class S {\n"
      "  foo() => 1;\n"
      "}\n"
      "class C extends S {\n"
      "  foo() => 100;\n"
      "  test() {\n"
      "    var n = super.foo();\n"
      "    reloadTest();\n"
      "    return n + super.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class S {\n"
      "  foo() => 10;\n"
      "}\n"
      "class C extends S {\n"
      "  foo() => 100;\n"
      "  test() {\n"
      "    var n = super.foo();\n"
      "    reloadTest();\n"
      "    return n + super.foo();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return new C().test();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_EQ(11, SimpleInvoke(lib, "main"));
}


TEST_CASE(IsolateReload_EnumEquality) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  x = Fruit.Banana;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  if (x == Fruit.Banana) {\n"
      "    return 'yes';\n"
      "  } else {\n"
      "    return 'no';\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("yes", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumIdentical) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  x = Fruit.Banana;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  if (identical(x, Fruit.Banana)) {\n"
      "    return 'yes';\n"
      "  } else {\n"
      "    return 'no';\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("yes", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumReorderIdentical) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  x = Fruit.Banana;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Banana,\n"
      "  Apple,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  if (identical(x, Fruit.Banana)) {\n"
      "    return 'yes';\n"
      "  } else {\n"
      "    return 'no';\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("yes", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumAddition) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Cantalope,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  String r = '${Fruit.Apple.index}/${Fruit.Apple} ';\n"
      "  r += '${Fruit.Cantalope.index}/${Fruit.Cantalope} ';\n"
      "  r += '${Fruit.Banana.index}/${Fruit.Banana}';\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("0/Fruit.Apple 1/Fruit.Cantalope 2/Fruit.Banana",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumToNotEnum) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple\n"
      "}\n"
      "main() {\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class Fruit {\n"
      "  final int zero = 0;\n"
      "}\n"
      "main() {\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(result, "Enum class cannot be redefined to be a non-enum class");
}


TEST_CASE(IsolateReload_NotEnumToEnum) {
  const char* kScript =
      "class Fruit {\n"
      "  final int zero = 0;\n"
      "}\n"
      "main() {\n"
      "  return 'yes';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("yes", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple\n"
      "}\n"
      "main() {\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(result, "Class cannot be redefined to be a enum class");
}


TEST_CASE(IsolateReload_EnumDelete) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "  Cantalope,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  // Delete 'Cantalope'.

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  String r = '${Fruit.Apple.index}/${Fruit.Apple} ';\n"
      "  r += '${Fruit.Banana.index}/${Fruit.Banana} ';\n"
      "  r += '${Fruit.Cantalope.index}/${Fruit.Cantalope}';\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("0/Fruit.Apple 1/Fruit.Banana 2/Fruit.Cantalope",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumComplex) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "  Cantalope,\n"
      "}\n"
      "var x;\n"
      "var y;\n"
      "var z;\n"
      "main() {\n"
      "  x = Fruit.Apple;\n"
      "  y = Fruit.Banana;\n"
      "  z = Fruit.Cantalope;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  // Delete 'Cantalope'. Add 'Dragon'. Move 'Apple' and 'Banana'.

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Dragon,\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "var y;\n"
      "var z;\n"
      "main() {\n"
      "  String r = '';\n"
      "  r += '${identical(x, Fruit.Apple)}';\n"
      "  r += ' ${identical(y, Fruit.Banana)}';\n"
      "  r += ' ${identical(z, Fruit.Cantalope)}';\n"
      "  r += ' ${Fruit.Dragon}';\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("true true true Fruit.Dragon", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumValuesArray) {
  const char* kScript =
      "enum Fruit {\n"
      "  Cantalope,\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  x = Fruit.Cantalope;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  // Delete 'Cantalope'.

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Banana,\n"
      "  Apple\n"
      "}\n"
      "var x;\n"
      "bool identityCheck(Fruit f) {\n"
      "  return identical(Fruit.values[f.index], f);\n"
      "}\n"
      "main() {\n"
      "  if ((x is Fruit) && identical(x, Fruit.Cantalope)) {\n"
      "    String r = '${identityCheck(Fruit.Apple)}';\n"
      "    r += ' ${identityCheck(Fruit.Banana)}';\n"
      "    r += ' ${identityCheck(Fruit.Cantalope)}';\n"
      "    r += ' ${identityCheck(x)}';\n"
      "    return r;\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("true true true true",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumIdentityReload) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "  Cantalope,\n"
      "}\n"
      "var x;\n"
      "var y;\n"
      "var z;\n"
      "var w;\n"
      "main() {\n"
      "  x = { Fruit.Apple: Fruit.Apple.index,\n"
      "        Fruit.Banana: Fruit.Banana.index,\n"
      "        Fruit.Cantalope: Fruit.Cantalope.index};\n"
      "  y = Fruit.Apple;\n"
      "  z = Fruit.Banana;\n"
      "  w = Fruit.Cantalope;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "  Cantalope,\n"
      "}\n"
      "var x;\n"
      "var y;\n"
      "var z;\n"
      "var w;\n"
      "bool identityCheck(Fruit f, int index) {\n"
      "  return identical(Fruit.values[index], f);\n"
      "}\n"
      "main() {\n"
      "  String r = '';\n"
      "  x.forEach((key, value) {\n"
      "    r += '${identityCheck(key, value)} ';\n"
      "  });\n"
      "  r += '${x[Fruit.Apple] == Fruit.Apple.index} ';\n"
      "  r += '${x[Fruit.Banana] == Fruit.Banana.index} ';\n"
      "  r += '${x[Fruit.Cantalope] == Fruit.Cantalope.index} ';\n"
      "  r += '${identical(y, Fruit.values[x[Fruit.Apple]])} ';\n"
      "  r += '${identical(z, Fruit.values[x[Fruit.Banana]])} ';\n"
      "  r += '${identical(w, Fruit.values[x[Fruit.Cantalope]])} ';\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("true true true true true true true true true ",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_ConstantIdentical) {
  const char* kScript =
      "class Fruit {\n"
      "  final String name;\n"
      "  const Fruit(this.name);\n"
      "  String toString() => name;\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  x = const Fruit('Pear');\n"
      "  return x.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Pear", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class Fruit {\n"
      "  final String name;\n"
      "  const Fruit(this.name);\n"
      "  String toString() => name;\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  if (identical(x, const Fruit('Pear'))) {\n"
      "    return 'yes';\n"
      "  } else {\n"
      "    return 'no';\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("yes", SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_EnumValuesToString) {
  const char* kScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  String r = '';\n"
      "  r += Fruit.Apple.toString();\n"
      "  r += ' ';\n"
      "  r += Fruit.Banana.toString();\n"
      "  return r;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple Fruit.Banana", SimpleInvokeStr(lib, "main"));

  // Insert 'Cantalope'.

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Cantalope,\n"
      "  Banana\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  String r = '';\n"
      "  r += Fruit.Apple.toString();\n"
      "  r += ' ';\n"
      "  r += Fruit.Cantalope.toString();\n"
      "  r += ' ';\n"
      "  r += Fruit.Banana.toString();\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);

  EXPECT_STREQ("Fruit.Apple Fruit.Cantalope Fruit.Banana",
               SimpleInvokeStr(lib, "main"));
}


TEST_CASE(IsolateReload_DirectSubclasses_Success) {
  Object& new_subclass = Object::Handle();
  String& name = String::Handle();

  // Lookup the Iterator class by name from the dart core library.
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Library& core_lib = Library::Handle(object_store->core_library());
  name = String::New("Iterator");
  const Class& iterator_cls = Class::Handle(core_lib.LookupClass(name));

  // Keep track of how many subclasses an Iterator has.
  const GrowableObjectArray& subclasses =
      GrowableObjectArray::Handle(iterator_cls.direct_subclasses());
  intptr_t saved_subclass_count = subclasses.Length();

  const char* kScript =
      "class AIterator extends Iterator {\n"
      "}\n"
      "main() {\n"
      "  return 1;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(1, SimpleInvoke(lib, "main"));

  // Iterator has one non-core subclass.
  EXPECT_EQ(saved_subclass_count + 1, subclasses.Length());

  // The new subclass is named AIterator.
  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("AIterator", name.ToCString());

  const char* kReloadScript =
      "class AIterator {\n"
      "}\n"
      "class BIterator extends Iterator {\n"
      "}\n"
      "main() {\n"
      "  return 2;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(2, SimpleInvoke(lib, "main"));

  // Iterator still has only one non-core subclass (AIterator is gone).
  EXPECT_EQ(saved_subclass_count + 1, subclasses.Length());

  // The new subclass is named BIterator.
  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("BIterator", name.ToCString());
}


TEST_CASE(IsolateReload_DirectSubclasses_GhostSubclass) {
  Object& new_subclass = Object::Handle();
  String& name = String::Handle();

  // Lookup the Iterator class by name from the dart core library.
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Library& core_lib = Library::Handle(object_store->core_library());
  name = String::New("Iterator");
  const Class& iterator_cls = Class::Handle(core_lib.LookupClass(name));

  // Keep track of how many subclasses an Iterator has.
  const GrowableObjectArray& subclasses =
      GrowableObjectArray::Handle(iterator_cls.direct_subclasses());
  intptr_t saved_subclass_count = subclasses.Length();

  const char* kScript =
      "class AIterator extends Iterator {\n"
      "}\n"
      "main() {\n"
      "  return 1;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(1, SimpleInvoke(lib, "main"));

  // Iterator has one new subclass.
  EXPECT_EQ(saved_subclass_count + 1, subclasses.Length());

  // The new subclass is named AIterator.
  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("AIterator", name.ToCString());

  const char* kReloadScript =
      "class BIterator extends Iterator {\n"
      "}\n"
      "main() {\n"
      "  return 2;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(2, SimpleInvoke(lib, "main"));

  // Iterator has two non-core subclasses.
  EXPECT_EQ(saved_subclass_count + 2, subclasses.Length());

  // The non-core subclasses are AIterator and BIterator.
  new_subclass = subclasses.At(subclasses.Length() - 2);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("AIterator", name.ToCString());

  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("BIterator", name.ToCString());
}


// Make sure that we restore the direct subclass info when we revert.
TEST_CASE(IsolateReload_DirectSubclasses_Failure) {
  Object& new_subclass = Object::Handle();
  String& name = String::Handle();

  // Lookup the Iterator class by name from the dart core library.
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Library& core_lib = Library::Handle(object_store->core_library());
  name = String::New("Iterator");
  const Class& iterator_cls = Class::Handle(core_lib.LookupClass(name));

  // Keep track of how many subclasses an Iterator has.
  const GrowableObjectArray& subclasses =
      GrowableObjectArray::Handle(iterator_cls.direct_subclasses());
  intptr_t saved_subclass_count = subclasses.Length();

  const char* kScript =
      "class AIterator extends Iterator {\n"
      "}\n"
      "class Foo {\n"
      "  final a;\n"
      "  Foo(this.a);\n"
      "}\n"
      "main() {\n"
      "  new Foo(5);\n"  // Force Foo to be finalized.
      "  return 1;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(1, SimpleInvoke(lib, "main"));

  // Iterator has one non-core subclass...
  EXPECT_EQ(saved_subclass_count + 1, subclasses.Length());

  // ... and the non-core subclass is named AIterator.
  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("AIterator", name.ToCString());

  // Attempt to reload with a bogus script.
  const char* kReloadScript =
      "class BIterator extends Iterator {\n"
      "}\n"
      "class Foo {\n"
      "  final a kjsdf ksjdf ;\n"  // When we refinalize, we get an error.
      "  Foo(this.a);\n"
      "}\n"
      "main() {\n"
      "  new Foo(5);\n"
      "  return 2;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "unexpected token");

  // If we don't clean up the subclasses, we would find BIterator in
  // the list of subclasses, which would be bad.  Make sure that
  // Iterator still has only one non-core subclass...
  EXPECT_EQ(saved_subclass_count + 1, subclasses.Length());

  // ...and the non-core subclass is still named AIterator.
  new_subclass = subclasses.At(subclasses.Length() - 1);
  name = Class::Cast(new_subclass).Name();
  EXPECT_STREQ("AIterator", name.ToCString());
}

#endif  // !PRODUCT

}  // namespace dart

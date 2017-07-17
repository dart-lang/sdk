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

DECLARE_FLAG(bool, support_deprecated_tearoff_syntax);

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
  EXPECT_STREQ("value1=10,value2=20", SimpleInvokeStr(lib, "main"));
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
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));
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
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));
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
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));
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
  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "max");

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

  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "max");
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

TEST_CASE(IsolateReload_TypeIdentity) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class T { }\n"
      "getType() => T;\n"
      "main() {\n"
      "  var oldType = getType();\n"
      "  reloadTest();\n"
      "  var newType = getType();\n"
      "  return identical(oldType, newType).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class T extends Stopwatch { }\n"
      "getType() => T;\n"
      "main() {\n"
      "  var oldType = getType();\n"
      "  reloadTest();\n"
      "  var newType = getType();\n"
      "  return identical(oldType, newType).toString();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_TypeIdentityGeneric) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class T<G> { }\n"
      "getType() => new T<int>().runtimeType;\n"
      "main() {\n"
      "  var oldType = getType();\n"
      "  reloadTest();\n"
      "  var newType = getType();\n"
      "  return identical(oldType, newType).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class T<G> extends Stopwatch { }\n"
      "getType() => new T<int>().runtimeType;\n"
      "main() {\n"
      "  var oldType = getType();\n"
      "  reloadTest();\n"
      "  var newType = getType();\n"
      "  return identical(oldType, newType).toString();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_TypeIdentityParameter) {
  const char* kScript =
      "import 'dart:mirrors';\n"
      "import 'test:isolate_reload_helper';\n"
      "class T<G> { }\n"
      "getTypeVar() => reflectType(T).typeVariables[0];\n"
      "main() {\n"
      "  var oldType = getTypeVar();\n"
      "  reloadTest();\n"
      "  var newType = getTypeVar();\n"
      "  return (oldType == newType).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'dart:mirrors';\n"
      "import 'test:isolate_reload_helper';\n"
      "class T<G> extends Stopwatch { }\n"
      "getTypeVar() => reflectType(T).typeVariables[0];\n"
      "main() {\n"
      "  var oldType = getTypeVar();\n"
      "  reloadTest();\n"
      "  var newType = getTypeVar();\n"
      "  return (oldType == newType).toString();\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
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
  EXPECT_STREQ("saved:field=mixin1,func=mixin1", SimpleInvokeStr(lib, "main"));

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
  EXPECT_STREQ(
      "saved:field=mixin1,func=mixin2 "
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
  EXPECT_STREQ(
      "(a is A(true)/ B(false)/ C(false),"
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
  EXPECT_STREQ(
      "(a is A(true)/ C(true)/ X(true),"
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
  EXPECT_STREQ(
      "(a is A(true)/ B(false)/ C(false)/ X(true),"
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
  const char* kImportScript = "importedFunc() => 'a';\n";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";
  Dart_Handle result;
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "importedFunc");

  // Fail to find 'test:lib1' in the isolate.
  result = Dart_LookupLibrary(NewString("test:lib1"));
  EXPECT(Dart_IsError(result));

  const char* kReloadScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  // Reload and add 'test:lib1' to isolate.
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("a", SimpleInvokeStr(lib, "main"));

  // Find 'test:lib1' in the isolate.
  result = Dart_LookupLibrary(NewString("test:lib1"));
  EXPECT(Dart_IsLibrary(result));

  // Reload and remove 'dart:math' from isolate.
  lib = TestCase::ReloadTestScript(kScript);
  EXPECT_VALID(lib);

  // Fail to find 'test:lib1' in the isolate.
  result = Dart_LookupLibrary(NewString("test:lib1"));
  EXPECT(Dart_IsError(result));
}

TEST_CASE(IsolateReload_LibraryHide) {
  const char* kImportScript = "importedFunc() => 'a';\n";
  TestCase::AddTestLib("test:lib1", kImportScript);

  // Import 'test:lib1' with importedFunc hidden. Will result in an
  // error.
  const char* kScript =
      "import 'test:lib1' hide importedFunc;\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  // Dart_Handle result;

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_ERROR(SimpleInvokeError(lib, "main"), "importedFunc");

  // Import 'test:lib1'.
  const char* kReloadScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("a", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_LibraryShow) {
  const char* kImportScript =
      "importedFunc() => 'a';\n"
      "importedIntFunc() => 4;\n";
  TestCase::AddTestLib("test:lib1", kImportScript);

  // Import 'test:lib1' with importedIntFunc visible. Will result in
  // an error when 'main' is invoked.
  const char* kScript =
      "import 'test:lib1' show importedIntFunc;\n"
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

  // Import 'test:lib1' with importedFunc visible. Will result in
  // an error when 'mainInt' is invoked.
  const char* kReloadScript =
      "import 'test:lib1' show importedFunc;\n"
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
  const char* kImportScript = "importedIntFunc() => 4;\n";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "import 'test:lib1' show importedIntFunc;\n"
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
  const char* kImportScript =
      "class ImportedMixin {\n"
      "  mixinFunc() => 'mixin';\n"
      "}\n";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:lib1' show ImportedMixin;\n"
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
      "import 'test:lib1' show ImportedMixin;\n"
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

  EXPECT_STREQ("instance", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("instance", SimpleInvokeStr(lib, "main"));
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

  EXPECT_STREQ("static", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("static", SimpleInvokeStr(lib, "main"));
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

  EXPECT_STREQ("okay", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("okay", SimpleInvokeStr(lib, "main"));
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

  EXPECT_STREQ("exception", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("exception", SimpleInvokeStr(lib, "main"));
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

  EXPECT_STREQ("exception", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("exception", SimpleInvokeStr(lib, "main"));
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

  EXPECT_STREQ("static", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  EXPECT_STREQ("static", SimpleInvokeStr(lib, "main"));
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

TEST_CASE(IsolateReload_TearOff_Instance_Equality) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'old';\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f1 = c.foo;\n"
      "  reloadTest();\n"
      "  var f2 = c.foo;\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'new';\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f1 = c.foo;\n"
      "  reloadTest();\n"
      "  var f2 = c.foo;\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("new new true false", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_TearOff_Class_Identity) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'old';\n"
      "}\n"
      "getFoo() => C.foo;\n"
      "main() {\n"
      "  var f1 = getFoo();\n"
      "  reloadTest();\n"
      "  var f2 = getFoo();\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo() => 'new';\n"
      "}\n"
      "getFoo() => C.foo;\n"
      "main() {\n"
      "  var f1 = getFoo();\n"
      "  reloadTest();\n"
      "  var f2 = getFoo();\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("new new true true", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_TearOff_Library_Identity) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "foo() => 'old';\n"
      "getFoo() => foo;\n"
      "main() {\n"
      "  var f1 = getFoo();\n"
      "  reloadTest();\n"
      "  var f2 = getFoo();\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "foo() => 'new';\n"
      "getFoo() => foo;\n"
      "main() {\n"
      "  var f1 = getFoo();\n"
      "  reloadTest();\n"
      "  var f2 = getFoo();\n"
      "  return '${f1()} ${f2()} ${f1 == f2} ${identical(f1, f2)}';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("new new true true", SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_TearOff_List_Set) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'old';\n"
      "}\n"
      "List list = new List(2);\n"
      "Set set = new Set();\n"
      "main() {\n"
      "  var c = new C();\n"
      "  list[0] = c.foo;\n"
      "  list[1] = c.foo;\n"
      "  set.add(c.foo);\n"
      "  set.add(c.foo);\n"
      "  int countBefore = set.length;\n"
      "  reloadTest();\n"
      "  list[1] = c.foo;\n"
      "  set.add(c.foo);\n"
      "  set.add(c.foo);\n"
      "  int countAfter = set.length;\n"
      "  return '${list[0]()} ${list[1]()} ${list[0] == list[1]} '\n"
      "         '${countBefore == 1} ${countAfter == 1} ${(set.first)()} '\n"
      "         '${set.first == c.foo} ${set.first == c.foo} '\n"
      "         '${set.remove(c.foo)}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo() => 'new';\n"
      "}\n"
      "List list = new List(2);\n"
      "Set set = new Set();\n"
      "main() {\n"
      "  var c = new C();\n"
      "  list[0] = c.foo;\n"
      "  list[1] = c.foo;\n"
      "  set.add(c.foo);\n"
      "  set.add(c.foo);\n"
      "  int countBefore = set.length;\n"
      "  reloadTest();\n"
      "  list[1] = c.foo;\n"
      "  set.add(c.foo);\n"
      "  set.add(c.foo);\n"
      "  int countAfter = set.length;\n"
      "  return '${list[0]()} ${list[1]()} ${list[0] == list[1]} '\n"
      "         '${countBefore == 1} ${countAfter == 1} ${(set.first)()} '\n"
      "         '${set.first == c.foo} ${set.first == c.foo} '\n"
      "         '${set.remove(c.foo)}';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("new new true true true new true true true",
               SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_DanglingGetter_Instance) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  var x = 3;\n"
      "  var y = 4;\n"
      "}\n"
      "invoke(f) {\n"
      "  try {\n"
      "    return f();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c.y;\n"
      "  var r1 = invoke(f);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  var x = 3;\n"
      "}\n"
      "invoke(f) {\n"
      "  try {\n"
      "    return f();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c.y;\n"
      "  var r1 = invoke(f);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ(
      "NoSuchMethodError: Class 'int' has no instance method 'call'. "
      "NoSuchMethodError: Class 'int' has no instance method 'call'.",
      SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_DanglingGetter_Class) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static var x;\n"
      "  static var y;\n"
      "}\n"
      "invoke(f) {\n"
      "  try {\n"
      "    return f();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  C.x = 3;\n"
      "  C.y = 4;\n"
      "  var f = C.y;\n"
      "  var r1 = invoke(f);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static var x;\n"
      "}\n"
      "invoke(f) {\n"
      "  try {\n"
      "    return f();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  C.x = 3;\n"
      "  C.y = 4;\n"
      "  var f = C.y;\n"
      "  var r1 = invoke(f);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ(
      "NoSuchMethodError: Class 'int' has no instance method 'call'. "
      "NoSuchMethodError: Class 'int' has no instance method 'call'.",
      SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

static void IsolateReload_DanlingGetter_LibraryReload(
    Dart_NativeArguments native_args) {
  const char* kImportScript2 = "var x;\n";
  TestCase::AddTestLib("test:other", kImportScript2);

  DART_CHECK_VALID(TestCase::TriggerReload());
}

static Dart_NativeFunction IsolateReload_DanlingGetter_LibraryNativeResolver(
    Dart_Handle name,
    int num_of_arguments,
    bool* auto_setup_scope) {
  return IsolateReload_DanlingGetter_LibraryReload;
}

TEST_CASE(IsolateReload_DanglingGetter_Library) {
  const char* kImportScript =
      "var x;\n"
      "var y;\n";
  TestCase::AddTestLib("test:other", kImportScript);

  const char* kScript =
      "import 'test:other' as prefix;\n"
      "reloadTest() native 'ReloadTest';\n"
      "invoke(f) {\n"
      "  try {\n"
      "    return f();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  prefix.x = 3;\n"
      "  prefix.y = 4;\n"
      "  var f = prefix#y;\n"
      "  var r1 = invoke(f);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  FLAG_support_deprecated_tearoff_syntax = true;
  Dart_Handle lib = TestCase::LoadTestScript(
      kScript, IsolateReload_DanlingGetter_LibraryNativeResolver);
  EXPECT_VALID(lib);

  TestCase::SetReloadTestScript(kScript);  // Root library does not change.

  EXPECT_STREQ("4 NoSuchMethodError: No top-level getter 'y' declared.",
               SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  FLAG_support_deprecated_tearoff_syntax = false;
}

TEST_CASE(IsolateReload_DanglingSetter_Instance) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  var x = 3;\n"
      "  var y = 4;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c#y=;\n"
      "  var r1 = invoke(f, 5);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 6);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  FLAG_support_deprecated_tearoff_syntax = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  var x = 3;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c#y=;\n"
      "  var r1 = invoke(f, 5);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 6);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ("null NoSuchMethodError: Class 'C' has no instance setter 'y='.",
               SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  FLAG_support_deprecated_tearoff_syntax = false;
}

TEST_CASE(IsolateReload_DanglingSetter_Class) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static var x;\n"
      "  static var y;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  C.x = 3;\n"
      "  C.y = 4;\n"
      "  var f = C#y=;\n"
      "  var r1 = invoke(f, 5);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 6);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  FLAG_support_deprecated_tearoff_syntax = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static var x;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  C.x = 3;\n"
      "  C.y = 4;\n"
      "  var f = C#y=;\n"
      "  var r1 = invoke(f, 5);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 6);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ(
      "5 NoSuchMethodError: No static setter 'y=' declared in "
      "class 'C'.",
      SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  FLAG_support_deprecated_tearoff_syntax = false;
}

static void IsolateReload_DanlingSetter_LibraryReload(
    Dart_NativeArguments native_args) {
  const char* kImportScript2 = "var x;\n";
  TestCase::AddTestLib("test:other", kImportScript2);

  DART_CHECK_VALID(TestCase::TriggerReload());
}

static Dart_NativeFunction IsolateReload_DanlingSetter_LibraryNativeResolver(
    Dart_Handle name,
    int num_of_arguments,
    bool* auto_setup_scope) {
  return IsolateReload_DanlingSetter_LibraryReload;
}

TEST_CASE(IsolateReload_DanglingSetter_Library) {
  const char* kImportScript =
      "var x;\n"
      "var y;\n";
  TestCase::AddTestLib("test:other", kImportScript);

  const char* kScript =
      "import 'test:other' as prefix;\n"
      "reloadTest() native 'ReloadTest';\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  prefix.x = 3;\n"
      "  prefix.y = 4;\n"
      "  var f = prefix#y=;\n"
      "  var r1 = invoke(f, 5);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 6);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  FLAG_support_deprecated_tearoff_syntax = true;
  Dart_Handle lib = TestCase::LoadTestScript(
      kScript, IsolateReload_DanlingSetter_LibraryNativeResolver);
  EXPECT_VALID(lib);

  TestCase::SetReloadTestScript(kScript);  // Root library does not change.

  EXPECT_STREQ("5 NoSuchMethodError: No top-level setter 'y=' declared.",
               SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
  FLAG_support_deprecated_tearoff_syntax = false;
}

TEST_CASE(IsolateReload_TearOff_AddArguments) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo(x) => x;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c.foo;\n"
      "  var r1 = invoke(f, 1);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 1);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  foo(x, y, z) => x + y + z;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var c = new C();\n"
      "  var f = c.foo;\n"
      "  var r1 = invoke(f, 1);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 1);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ(
      "1 NoSuchMethodError: Class 'C' has no instance method "
      "'foo' with matching arguments.",
      SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
}

TEST_CASE(IsolateReload_TearOff_AddArguments2) {
  const char* kScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo(x) => x;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var f = C.foo;\n"
      "  var r1 = invoke(f, 1);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 1);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "import 'test:isolate_reload_helper';\n"
      "class C {\n"
      "  static foo(x, y, z) => x + y + z;\n"
      "}\n"
      "invoke(f, a) {\n"
      "  try {\n"
      "    return f(a);\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var f = C.foo;\n"
      "  var r1 = invoke(f, 1);\n"
      "  reloadTest();\n"
      "  var r2 = invoke(f, 1);\n"
      "  return '$r1 $r2';\n"
      "}\n";

  TestCase::SetReloadTestScript(kReloadScript);

  EXPECT_STREQ(
      "1 NoSuchMethodError: Closure call with mismatched arguments: "
      "function 'C.foo'",
      SimpleInvokeStr(lib, "main"));

  lib = TestCase::GetReloadErrorOrRootLibrary();
  EXPECT_VALID(lib);
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
      "  x = Fruit.Cantalope;\n"
      "  return Fruit.Apple.toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("Fruit.Apple", SimpleInvokeStr(lib, "main"));

  // Delete 'Cantalope' but make sure that we can still invoke toString,
  // and access the hashCode and index properties.

  const char* kReloadScript =
      "enum Fruit {\n"
      "  Apple,\n"
      "  Banana,\n"
      "}\n"
      "var x;\n"
      "main() {\n"
      "  String r = '$x ${x.hashCode is int} ${x.index}';\n"
      "  return r;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("Deleted enum value from Fruit true -1",
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

// Tests reload succeeds when instance format changes.
// Change: Foo {a, b, c:42}  -> Foo {c:42}
// Validate: c keeps the value in the retained Foo object.
TEST_CASE(IsolateReload_ChangeInstanceFormat0) {
  const char* kScript =
      "class Foo {\n"
      "  var a;\n"
      "  var b;\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  f.c = 42;\n"
      "  return f.c;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(42, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  return f.c;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(42, SimpleInvoke(lib, "main"));
}

// Tests reload succeeds when instance format changes.
// Change: Foo {}  -> Foo {c:null}
// Validate: c is initialized to null the retained Foo object.
TEST_CASE(IsolateReload_ChangeInstanceFormat1) {
  const char* kScript =
      "class Foo {\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  return 42;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(42, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  return (f.c == null) ? 42: 21;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(42, SimpleInvoke(lib, "main"));
}

// Tests reload succeeds when instance format changes.
// Change: Foo {c:42}  -> Foo {}
// Validate: running the after script fails.
TEST_CASE(IsolateReload_ChangeInstanceFormat2) {
  const char* kScript =
      "class Foo {\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  f.c = 42;\n"
      "  return f.c;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(42, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  try {\n"
      "    return f.c;\n"
      "  } catch (e) {\n"
      "    return 24;\n"
      "  }\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(24, SimpleInvoke(lib, "main"));
}

// Tests reload succeeds when instance format changes.
// Change: Foo {a, b, c:42, d}  -> Foo {c:42, g}
// Validate: c keeps the value in the retained Foo object.
TEST_CASE(IsolateReload_ChangeInstanceFormat3) {
  const char* kScript =
      "class Foo<A,B> {\n"
      "  var a;\n"
      "  var b;\n"
      "  var c;\n"
      "  var d;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  f.a = 1;\n"
      "  f.b = 2;\n"
      "  f.c = 3;\n"
      "  f.d = 4;\n"
      "  return f.c;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(3, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo<A,B> {\n"
      "  var c;\n"
      "  var g;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  return f.c;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(3, SimpleInvoke(lib, "main"));
}

// Tests reload succeeds when instance format changes.
// Change: Bar {c:42}, Foo : Bar {d, e} -> Foo {c:42}
// Validate: c keeps the value in the retained Foo object.
TEST_CASE(IsolateReload_ChangeInstanceFormat4) {
  const char* kScript =
      "class Bar{\n"
      "  var c;\n"
      "}\n"
      "class Foo extends Bar{\n"
      "  var d;\n"
      "  var e;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  f.c = 44;\n"
      "  return f.c;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo {\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  return f.c;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));
}

// Tests reload succeeds when instance format changes.
// Change: Bar {a, b}, Foo : Bar {c:42} -> Bar {c:42}, Foo : Bar {}
// Validate: c keeps the value in the retained Foo object.
TEST_CASE(IsolateReload_ChangeInstanceFormat5) {
  const char* kScript =
      "class Bar{\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class Foo extends Bar{\n"
      "  var c;\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  f = new Foo();\n"
      "  f.c = 44;\n"
      "  return f.c;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Bar{\n"
      "  var c;\n"
      "}\n"
      "class Foo extends Bar {\n"
      "}\n"
      "var f;\n"
      "main() {\n"
      "  return f.c;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_EQ(44, SimpleInvoke(lib, "main"));
}

// Tests reload fails when type parameters change.
// Change: Foo<A,B> {a, b}  -> Foo<A> {a}
// Validate: the right error message is returned.
TEST_CASE(IsolateReload_ChangeInstanceFormat6) {
  const char* kScript =
      "class Foo<A, B> {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "main() {\n"
      "  new Foo();\n"
      "  return 43;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(43, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Foo<A> {\n"
      "  var a;\n"
      "}\n";
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "type parameters have changed");
}

// Tests reload succeeds when type parameters are changed for allocated class.
// Change: Foo<A,B> {a, b} -> Foo<A> {a}
// Validate: return value from main is correct.
// Please note: This test works because no instances are created from Foo.
TEST_CASE(IsolateReload_ChangeInstanceFormat7) {
  const char* kScript =
      "class Foo<A, B> {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  const char* kReloadScript =
      "class Foo<A> {\n"
      "  var a;\n"
      "}\n";
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
}

// Regression for handle sharing bug: Change the shape of two classes and see
// that their instances don't change class.
TEST_CASE(IsolateReload_ChangeInstanceFormat8) {
  const char* kScript =
      "class A{\n"
      "  var x;\n"
      "}\n"
      "class B {\n"
      "  var x, y, z, w;\n"
      "}\n"
      "var a, b;\n"
      "main() {\n"
      "  a = new A();\n"
      "  b = new B();\n"
      "  return '$a $b';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("Instance of 'A' Instance of 'B'", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class A{\n"
      "  var x, y;\n"
      "}\n"
      "class B {\n"
      "  var x, y, z, w, v;\n"
      "}\n"
      "var a, b;\n"
      "main() {\n"
      "  return '$a $b';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("Instance of 'A' Instance of 'B'", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_ShapeChangeRetainsHash) {
  const char* kScript =
      "class A{\n"
      "  var x;\n"
      "}\n"
      "var a, hash1, hash2;\n"
      "main() {\n"
      "  a = new A();\n"
      "  hash1 = a.hashCode;\n"
      "  return 'okay';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("okay", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class A{\n"
      "  var x, y, z;\n"
      "}\n"
      "var a, hash1, hash2;\n"
      "main() {\n"
      "  hash2 = a.hashCode;\n"
      "  return (hash1 == hash2).toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_StaticTearOffRetainsHash) {
  const char* kScript =
      "foo() {}\n"
      "var hash1, hash2;\n"
      "main() {\n"
      "  hash1 = foo.hashCode;\n"
      "  return 'okay';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("okay", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "foo() {}\n"
      "var hash1, hash2;\n"
      "main() {\n"
      "  hash2 = foo.hashCode;\n"
      "  return (hash1 == hash2).toString();\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
}

static bool NothingModifiedCallback(const char* url, int64_t since) {
  return false;
}

TEST_CASE(IsolateReload_NoLibsModified) {
  const char* kImportScript = "importedFunc() => 'fancy';";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' feast';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));

  const char* kReloadImportScript = "importedFunc() => 'bossy';";
  TestCase::AddTestLib("test:lib1", kReloadImportScript);

  const char* kReloadScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' pants';\n"
      "}\n";

  Dart_SetFileModifiedCallback(&NothingModifiedCallback);
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  Dart_SetFileModifiedCallback(NULL);

  // No reload occurred because no files were "modified".
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));
}

static bool MainModifiedCallback(const char* url, int64_t since) {
  if (strcmp(url, "test-lib") == 0) {
    return true;
  }
  return false;
}

TEST_CASE(IsolateReload_MainLibModified) {
  const char* kImportScript = "importedFunc() => 'fancy';";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' feast';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));

  const char* kReloadImportScript = "importedFunc() => 'bossy';";
  TestCase::AddTestLib("test:lib1", kReloadImportScript);

  const char* kReloadScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' pants';\n"
      "}\n";

  Dart_SetFileModifiedCallback(&MainModifiedCallback);
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  Dart_SetFileModifiedCallback(NULL);

  // Imported library is not reloaded.
  EXPECT_STREQ("fancy pants", SimpleInvokeStr(lib, "main"));
}

static bool ImportModifiedCallback(const char* url, int64_t since) {
  if (strcmp(url, "test:lib1") == 0) {
    return true;
  }
  return false;
}

TEST_CASE(IsolateReload_ImportedLibModified) {
  const char* kImportScript = "importedFunc() => 'fancy';";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' feast';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));

  const char* kReloadImportScript = "importedFunc() => 'bossy';";
  TestCase::AddTestLib("test:lib1", kReloadImportScript);

  const char* kReloadScript =
      "import 'test:lib1';\n"
      "main() {\n"
      "  return importedFunc() + ' pants';\n"
      "}\n";

  Dart_SetFileModifiedCallback(&ImportModifiedCallback);
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  Dart_SetFileModifiedCallback(NULL);

  // Modification of an imported library propagates to the importing library.
  EXPECT_STREQ("bossy pants", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_PrefixImportedLibModified) {
  const char* kImportScript = "importedFunc() => 'fancy';";
  TestCase::AddTestLib("test:lib1", kImportScript);

  const char* kScript =
      "import 'test:lib1' as cobra;\n"
      "main() {\n"
      "  return cobra.importedFunc() + ' feast';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));

  const char* kReloadImportScript = "importedFunc() => 'bossy';";
  TestCase::AddTestLib("test:lib1", kReloadImportScript);

  const char* kReloadScript =
      "import 'test:lib1' as cobra;\n"
      "main() {\n"
      "  return cobra.importedFunc() + ' pants';\n"
      "}\n";

  Dart_SetFileModifiedCallback(&ImportModifiedCallback);
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  Dart_SetFileModifiedCallback(NULL);

  // Modification of an prefix-imported library propagates to the
  // importing library.
  EXPECT_STREQ("bossy pants", SimpleInvokeStr(lib, "main"));
}

static bool ExportModifiedCallback(const char* url, int64_t since) {
  if (strcmp(url, "test:exportlib") == 0) {
    return true;
  }
  return false;
}

TEST_CASE(IsolateReload_ExportedLibModified) {
  const char* kImportScript = "export 'test:exportlib';";
  TestCase::AddTestLib("test:importlib", kImportScript);

  const char* kExportScript = "exportedFunc() => 'fancy';";
  TestCase::AddTestLib("test:exportlib", kExportScript);

  const char* kScript =
      "import 'test:importlib';\n"
      "main() {\n"
      "  return exportedFunc() + ' feast';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("fancy feast", SimpleInvokeStr(lib, "main"));

  const char* kReloadExportScript = "exportedFunc() => 'bossy';";
  TestCase::AddTestLib("test:exportlib", kReloadExportScript);

  const char* kReloadScript =
      "import 'test:importlib';\n"
      "main() {\n"
      "  return exportedFunc() + ' pants';\n"
      "}\n";

  Dart_SetFileModifiedCallback(&ExportModifiedCallback);
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  Dart_SetFileModifiedCallback(NULL);

  // Modification of an exported library propagates.
  EXPECT_STREQ("bossy pants", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_SimpleConstFieldUpdate) {
  const char* kScript =
      "const value = 'a';\n"
      "main() {\n"
      "  return 'value=${value}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("value=a", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "const value = 'b';\n"
      "main() {\n"
      "  return 'value=${value}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("value=b", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_ConstFieldUpdate) {
  const char* kScript =
      "const value = const Duration(seconds: 1);\n"
      "main() {\n"
      "  return 'value=${value}';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("value=0:00:01.000000", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "const value = const Duration(seconds: 2);\n"
      "main() {\n"
      "  return 'value=${value}';\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  EXPECT_STREQ("value=0:00:02.000000", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_RunNewFieldInitializers) {
  const char* kScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y.
  const char* kReloadScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "  int y = 7;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return value.y;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  // Verify that we ran field initializers on existing instances.
  EXPECT_EQ(7, SimpleInvoke(lib, "main"));
}

TEST_CASE(IsolateReload_RunNewFieldInitializersReferenceStaticField) {
  const char* kScript =
      "int myInitialValue = 8 * 7;\n"
      "class Foo {\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y.
  const char* kReloadScript =
      "int myInitialValue = 8 * 7;\n"
      "class Foo {\n"
      "  int x = 4;\n"
      "  int y = myInitialValue;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return value.y;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  // Verify that we ran field initializers on existing instances.
  EXPECT_EQ(56, SimpleInvoke(lib, "main"));
}

TEST_CASE(IsolateReload_RunNewFieldInitializersMutateStaticField) {
  const char* kScript =
      "int myInitialValue = 8 * 7;\n"
      "class Foo {\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "Foo value1;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  value1 = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y.
  const char* kReloadScript =
      "int myInitialValue = 8 * 7;\n"
      "class Foo {\n"
      "  int x = 4;\n"
      "  int y = myInitialValue++;\n"
      "}\n"
      "Foo value;\n"
      "Foo value1;\n"
      "main() {\n"
      "  return myInitialValue;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  // Verify that we ran field initializers on existing instances and that
  // they affected the value of the field myInitialValue.
  EXPECT_EQ(58, SimpleInvoke(lib, "main"));
}

// When an initializer expression throws, we leave the field as null.
TEST_CASE(IsolateReload_RunNewFieldInitializersThrows) {
  const char* kScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y.
  const char* kReloadScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "  int y = throw 'a';\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return '${value.y == null}';"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  // Verify that we ran field initializers on existing instances.
  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));
}

// When an initializer expression has a syntax error, we detect it at reload
// time.
TEST_CASE(IsolateReload_RunNewFieldInitializersSyntaxError) {
  const char* kScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y with a syntax error in the initializing expression.
  const char* kReloadScript =
      "class Foo {\n"
      "  int x = 4;\n"
      "  int y = ......;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return '${value.y == null}';"
      "}\n";

  // The reload fails because the initializing expression is parsed at
  // class finalization time.
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "...");
}

// When an initializer expression has a syntax error, we detect it at reload
// time.
TEST_CASE(IsolateReload_RunNewFieldInitializersSyntaxError2) {
  const char* kScript =
      "class Foo {\n"
      "  Foo() { /* default constructor */ }\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y with a syntax error in the initializing expression.
  const char* kReloadScript =
      "class Foo {\n"
      "  Foo() { /* default constructor */ }\n"
      "  int x = 4;\n"
      "  int y = ......;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return '${value.y == null}';"
      "}\n";

  // The reload fails because the initializing expression is parsed at
  // class finalization time.
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "...");
}

// When an initializer expression has a syntax error, we detect it at reload
// time.
TEST_CASE(IsolateReload_RunNewFieldInitializersSyntaxError3) {
  const char* kScript =
      "class Foo {\n"
      "  Foo() { /* default constructor */ }\n"
      "  int x = 4;\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  value = new Foo();\n"
      "  return value.x;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(4, SimpleInvoke(lib, "main"));

  // Add the field y with a syntax error in the initializing expression.
  const char* kReloadScript =
      "class Foo {\n"
      "  Foo() { /* default constructor */ }\n"
      "  int x = 4;\n"
      "  int y = ......\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return '${value.y == null}';"
      "}\n";

  // The reload fails because the initializing expression is parsed at
  // class finalization time.
  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(lib, "......");
}

TEST_CASE(IsolateReload_RunNewFieldInitialiazersSuperClass) {
  const char* kScript =
      "class Super {\n"
      "  static var foo = 'right';\n"
      "}\n"
      "class Foo extends Super {\n"
      "  static var foo = 'wrong';\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  Super.foo;\n"
      "  Foo.foo;\n"
      "  value = new Foo();\n"
      "  return 0;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_EQ(0, SimpleInvoke(lib, "main"));

  const char* kReloadScript =
      "class Super {\n"
      "  static var foo = 'right';\n"
      "  var newField = foo;\n"
      "}\n"
      "class Foo extends Super {\n"
      "  static var foo = 'wrong';\n"
      "}\n"
      "Foo value;\n"
      "main() {\n"
      "  return value.newField;\n"
      "}\n";

  lib = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(lib);
  // Verify that we ran field initializers on existing instances in the
  // correct scope.
  EXPECT_STREQ("right", SimpleInvokeStr(lib, "main"));
}

TEST_CASE(IsolateReload_TypedefToNotTypedef) {
  const char* kScript =
      "typedef bool Predicate(dynamic x);\n"
      "main() {\n"
      "  return (42 is Predicate).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("false", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "class Predicate {\n"
      "  bool call(dynamic x) { return false; }\n"
      "}\n"
      "main() {\n"
      "  return (42 is Predicate).toString();\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(result,
               "Typedef class cannot be redefined to be a non-typedef class");
}

TEST_CASE(IsolateReload_NotTypedefToTypedef) {
  const char* kScript =
      "class Predicate {\n"
      "  bool call(dynamic x) { return false; }\n"
      "}\n"
      "main() {\n"
      "  return (42 is Predicate).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("false", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "typedef bool Predicate(dynamic x);\n"
      "main() {\n"
      "  return (42 is Predicate).toString();\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_ERROR(result, "Class cannot be redefined to be a typedef class");
}

TEST_CASE(IsolateReload_TypedefAddParameter) {
  const char* kScript =
      "typedef bool Predicate(dynamic x);\n"
      "main() {\n"
      "  bool foo(x) => true;\n"
      "  return (foo is Predicate).toString();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  EXPECT_STREQ("true", SimpleInvokeStr(lib, "main"));

  const char* kReloadScript =
      "typedef bool Predicate(dynamic x, dynamic y);\n"
      "main() {\n"
      "  bool foo(x) => true;\n"
      "  return (foo is Predicate).toString();\n"
      "}\n";

  Dart_Handle result = TestCase::ReloadTestScript(kReloadScript);
  EXPECT_VALID(result);
  EXPECT_STREQ("false", SimpleInvokeStr(lib, "main"));
}

#endif  // !PRODUCT

}  // namespace dart

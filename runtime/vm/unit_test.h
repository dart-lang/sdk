// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_UNIT_TEST_H_
#define VM_UNIT_TEST_H_

#include "include/dart_api.h"

#include "vm/ast.h"
#include "vm/dart.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/zone.h"

// The UNIT_TEST_CASE macro is used for tests that do not need any
// default isolate or zone functionality.
#define UNIT_TEST_CASE(name)                                                   \
  void Dart_Test##name();                                                      \
  static const dart::TestCase kRegister##name(Dart_Test##name, #name);         \
  void Dart_Test##name()

// The TEST_CASE macro is used for tests that need an isolate and zone
// in order to test its functionality.
#define TEST_CASE(name)                                                        \
  static void Dart_TestHelper##name();                                         \
  UNIT_TEST_CASE(name)                                                         \
  {                                                                            \
    TestIsolateScope __test_isolate__;                                         \
    Zone __zone__(__test_isolate__.isolate());                                 \
    HandleScope __hs__(__test_isolate__.isolate());                            \
    Dart_TestHelper##name();                                                   \
  }                                                                            \
  static void Dart_TestHelper##name()

// The ASSEMBLER_TEST_GENERATE macro is used to generate a unit test
// for the assembler.
#define ASSEMBLER_TEST_GENERATE(name, assembler)                               \
  void AssemblerTestGenerate##name(Assembler* assembler)

// The ASSEMBLER_TEST_EXTERN macro is used to declare a unit test
// for the assembler.
#define ASSEMBLER_TEST_EXTERN(name)                                            \
  extern void AssemblerTestGenerate##name(Assembler* assembler);

// The ASSEMBLER_TEST_RUN macro is used to execute the assembler unit
// test generated using the ASSEMBLER_TEST_GENERATE macro.
// C++ callee-saved registers are not preserved. Arguments may be passed in.
#define ASSEMBLER_TEST_RUN(name, entry)                                        \
  static void AssemblerTestRun##name(uword entry);                             \
  TEST_CASE(name) {                                                            \
    Assembler __assembler__;                                                   \
    AssemblerTest __test__(""#name, &__assembler__);                           \
    AssemblerTestGenerate##name(__test__.assembler());                         \
    AssemblerTestRun##name(__test__.Assemble());                               \
  }                                                                            \
  static void AssemblerTestRun##name(uword entry)

// Populate node list with AST nodes.
#define CODEGEN_TEST_GENERATE(name, test)                                      \
  static void CodeGenTestGenerate##name(CodeGenTest* test)

// Populate node list with AST nodes, possibly using the provided function
// object built by a previous CODEGEN_TEST_GENERATE.
#define CODEGEN_TEST2_GENERATE(name, function, test)                           \
  static void CodeGenTestGenerate##name(const Function& function,              \
                                        CodeGenTest* test)


// Pass the name of test and the expected results as RawObject.
#define CODEGEN_TEST_RUN(name, expected)                                       \
  static void CodeGenTestRun##name(const Function& function);                  \
  TEST_CASE(name) {                                                            \
    CodeGenTest __test__(""#name);                                             \
    CodeGenTestGenerate##name(&__test__);                                      \
    __test__.Compile();                                                        \
    CodeGenTestRun##name(__test__.function());                                 \
  }                                                                            \
  static void CodeGenTestRun##name(const Function& function) {                 \
    GrowableArray<const Object*>  arguments;                                   \
    const Array& kNoArgumentNames = Array::Handle();                           \
    Object& result = Object::Handle();                                         \
    result = DartEntry::InvokeStatic(function, arguments, kNoArgumentNames);   \
    EXPECT(!result.IsError());                                                 \
    Instance& actual = Instance::Handle();                                     \
    actual ^= result.raw();                                                    \
    EXPECT(actual.Equals(Instance::Handle(expected)));                         \
  }


// Pass the name of test, and use the generated function to call it
// and evaluate its result.
#define CODEGEN_TEST_RAW_RUN(name, function)                                   \
  static void CodeGenTestRun##name(const Function& function);                  \
  TEST_CASE(name) {                                                            \
    CodeGenTest __test__(""#name);                                             \
    CodeGenTestGenerate##name(&__test__);                                      \
    __test__.Compile();                                                        \
    CodeGenTestRun##name(__test__.function());                                 \
  }                                                                            \
  static void CodeGenTestRun##name(const Function& function)


// Generate code for two sequences of AST nodes and execute the first one.
// The first one may reference the Function object generated by the second one.
#define CODEGEN_TEST2_RUN(name1, name2, expected)                              \
  static void CodeGenTestRun##name1(const Function& function);                 \
  TEST_CASE(name1) {                                                           \
    /* Generate code for name2 */                                              \
    CodeGenTest __test2__(""#name2);                                           \
    CodeGenTestGenerate##name2(&__test2__);                                    \
    __test2__.Compile();                                                       \
    /* Generate code for name1, providing function2 */                         \
    CodeGenTest __test1__(""#name1);                                           \
    CodeGenTestGenerate##name1(__test2__.function(), &__test1__);              \
    __test1__.Compile();                                                       \
    CodeGenTestRun##name1(__test1__.function());                               \
  }                                                                            \
  static void CodeGenTestRun##name1(const Function& function) {                \
    GrowableArray<const Object*> arguments;                                    \
    const Array& kNoArgumentNames = Array::Handle();                           \
    Object& result = Object::Handle();                                         \
    result = DartEntry::InvokeStatic(function, arguments, kNoArgumentNames);   \
    EXPECT(!result.IsError());                                                 \
    Instance& actual = Instance::Handle();                                     \
    actual ^= result.raw();                                                    \
    EXPECT(actual.Equals(Instance::Handle(expected)));                         \
  }


namespace dart {

// Forward declarations.
class Assembler;
class CodeGenerator;
class VirtualMemory;


class TestCaseBase {
 public:
  explicit TestCaseBase(const char* name);
  virtual ~TestCaseBase() { }

  const char* name() const { return name_; }

  virtual void Run() = 0;
  void RunTest();

  static void RunAll();

 private:
  static TestCaseBase* first_;
  static TestCaseBase* tail_;

  TestCaseBase* next_;
  const char* name_;

  DISALLOW_COPY_AND_ASSIGN(TestCaseBase);
};


class TestCase : TestCaseBase {
 public:
  typedef void (RunEntry)();

  TestCase(RunEntry* run, const char* name) : TestCaseBase(name), run_(run) { }

  static Dart_Handle LoadTestScript(const char* script,
                                    Dart_NativeEntryResolver resolver);
  static Dart_Handle lib();
  static const char* url() { return "dart:test-lib"; }
  static Dart_Isolate CreateTestIsolateFromSnapshot(uint8_t* buffer) {
    return CreateIsolate(buffer);
  }
  static Dart_Isolate CreateTestIsolate() {
    return CreateIsolate(NULL);
  }
  static Dart_Handle library_handler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url);

  virtual void Run();

 private:
  static Dart_Isolate CreateIsolate(uint8_t* buffer) {
    char* err;
    Dart_Isolate isolate = Dart_CreateIsolate(NULL, NULL, buffer, NULL, &err);
    if (isolate == NULL) {
      OS::Print("Creation of isolate failed '%s'\n", err);
      free(err);
    }
    EXPECT(isolate != NULL);
    return isolate;
  }

  RunEntry* const run_;
};


class TestIsolateScope {
 public:
  TestIsolateScope() {
    isolate_ = reinterpret_cast<Isolate*>(TestCase::CreateTestIsolate());
    Dart_EnterScope();  // Create a Dart API scope for unit tests.
  }
  ~TestIsolateScope() {
    Dart_ExitScope();  // Exit the Dart API scope created for unit tests.
    ASSERT(isolate_ == Isolate::Current());
    Dart_ShutdownIsolate();
    isolate_ = NULL;
  }
  Isolate* isolate() const { return isolate_; }

 private:
  Isolate* isolate_;

  DISALLOW_COPY_AND_ASSIGN(TestIsolateScope);
};


class AssemblerTest {
 public:
  AssemblerTest(const char* name, Assembler* assembler)
      : name_(name),
        assembler_(assembler) {
    ASSERT(name != NULL);
    ASSERT(assembler != NULL);
  }
  ~AssemblerTest() { }

  Assembler* assembler() const { return assembler_; }

  // Assemble test and return entry.
  uword Assemble();

 private:
  const char* name_;
  Assembler* assembler_;

  DISALLOW_COPY_AND_ASSIGN(AssemblerTest);
};


class CodeGenTest {
 public:
  explicit CodeGenTest(const char* name);
  ~CodeGenTest() { }

    // Accessors.
  const Function& function() const { return function_; }

  SequenceNode* node_sequence() const { return node_sequence_; }

  void set_default_parameter_values(const Array& value) {
    default_parameter_values_ = value.raw();
  }

  // Compile test and set code in function.
  void Compile();

  LocalVariable* CreateTempConstVariable(const char* name_part);

 private:
  Function& function_;
  SequenceNode* node_sequence_;
  Array& default_parameter_values_;

  DISALLOW_COPY_AND_ASSIGN(CodeGenTest);
};


class CompilerTest : public AllStatic {
 public:
  // Test the Compiler::CompileScript functionality by checking the return
  // value to see if no parse errors were reported.
  static bool TestCompileScript(const Library& library, const Script& script);

  // Test the Compiler::CompileFunction functionality by checking the return
  // value to see if no parse errors were reported.
  static bool TestCompileFunction(const Function& function);
};

#define EXPECT_VALID(handle)                                                   \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (Dart_IsError(tmp_handle)) {                                            \
      dart::Expect(__FILE__, __LINE__).Fail(                                   \
          "expected '%s' to be a valid handle but found an error handle:\n"    \
          "    '%s'\n",                                                        \
          #handle, Dart_GetError(tmp_handle));                                 \
    }                                                                          \
  } while (0)

#define EXPECT_ERROR(handle, substring)                                        \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (Dart_IsError(tmp_handle)) {                                            \
      dart::Expect(__FILE__, __LINE__).IsSubstring((substring),                \
                                                   Dart_GetError(tmp_handle)); \
    } else {                                                                   \
      dart::Expect(__FILE__, __LINE__).Fail(                                   \
          "expected '%s' to be an error handle but found a valid handle.\n",   \
          #handle);                                                            \
    }                                                                          \
  } while (0)

}  // namespace dart

#endif  // VM_UNIT_TEST_H_

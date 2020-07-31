// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_UNIT_TEST_H_
#define RUNTIME_VM_UNIT_TEST_H_

#include "include/dart_native_api.h"

#include "platform/globals.h"

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/globals.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/simulator.h"
#include "vm/zone.h"

// The VM_UNIT_TEST_CASE macro is used for tests that do not need any
// default isolate or zone functionality.
#define VM_UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation)                  \
  void Dart_Test##name();                                                      \
  static const dart::TestCase kRegister##name(Dart_Test##name, #name,          \
                                              expectation);                    \
  void Dart_Test##name()

#define VM_UNIT_TEST_CASE(name) VM_UNIT_TEST_CASE_WITH_EXPECTATION(name, "Pass")

// The UNIT_TEST_CASE macro is used for tests that do not require any
// functionality provided by the VM. Tests declared using this macro will be run
// after the VM is cleaned up.
#define UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation)                     \
  void Dart_Test##name();                                                      \
  static const dart::RawTestCase kRegister##name(Dart_Test##name, #name,       \
                                                 expectation);                 \
  void Dart_Test##name()

#define UNIT_TEST_CASE(name) UNIT_TEST_CASE_WITH_EXPECTATION(name, "Pass")

// The ISOLATE_UNIT_TEST_CASE macro is used for tests that need an isolate and
// zone in order to test its functionality. This macro is used for tests that
// are implemented using the VM code directly and do not use the Dart API
// for calling into the VM. The safepoint execution state of threads using
// this macro is transitioned from kThreadInNative to kThreadInVM.
#define ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation)             \
  static void Dart_TestHelper##name(Thread* thread);                           \
  VM_UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation) {                      \
    TestIsolateScope __test_isolate__;                                         \
    Thread* __thread__ = Thread::Current();                                    \
    ASSERT(__thread__->isolate() == __test_isolate__.isolate());               \
    TransitionNativeToVM transition(__thread__);                               \
    StackZone __zone__(__thread__);                                            \
    HandleScope __hs__(__thread__);                                            \
    Dart_TestHelper##name(__thread__);                                         \
  }                                                                            \
  static void Dart_TestHelper##name(Thread* thread)

#define ISOLATE_UNIT_TEST_CASE(name)                                           \
  ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(name, "Pass")

// The TEST_CASE macro is used for tests that need an isolate and zone
// in order to test its functionality. This macro is used for tests that
// are implemented using the Dart API for calling into the VM. The safepoint
// execution state of threads using this macro remains kThreadNative.
#define TEST_CASE_WITH_EXPECTATION(name, expectation)                          \
  static void Dart_TestHelper##name(Thread* thread);                           \
  VM_UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation) {                      \
    TestIsolateScope __test_isolate__;                                         \
    Thread* __thread__ = Thread::Current();                                    \
    ASSERT(__thread__->isolate() == __test_isolate__.isolate());               \
    TransitionNativeToVM transition1(__thread__);                              \
    StackZone __zone__(__thread__);                                            \
    HandleScope __hs__(__thread__);                                            \
    TransitionVMToNative transition2(__thread__);                              \
    Dart_TestHelper##name(__thread__);                                         \
  }                                                                            \
  static void Dart_TestHelper##name(Thread* thread)

#define TEST_CASE(name) TEST_CASE_WITH_EXPECTATION(name, "Pass")

// The ASSEMBLER_TEST_GENERATE macro is used to generate a unit test
// for the assembler.
#define ASSEMBLER_TEST_GENERATE(name, assembler)                               \
  void AssemblerTestGenerate##name(compiler::Assembler* assembler)

// The ASSEMBLER_TEST_EXTERN macro is used to declare a unit test
// for the assembler.
#define ASSEMBLER_TEST_EXTERN(name)                                            \
  extern void AssemblerTestGenerate##name(compiler::Assembler* assembler);

// The ASSEMBLER_TEST_RUN macro is used to execute the assembler unit
// test generated using the ASSEMBLER_TEST_GENERATE macro.
// C++ callee-saved registers are not preserved. Arguments may be passed in.
#define ASSEMBLER_TEST_RUN_WITH_EXPECTATION(name, test, expectation)           \
  static void AssemblerTestRun##name(AssemblerTest* test);                     \
  ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation) {                 \
    {                                                                          \
      bool use_far_branches = false;                                           \
      LongJumpScope jump;                                                      \
      if (setjmp(*jump.Set()) == 0) {                                          \
        compiler::ObjectPoolBuilder object_pool_builder;                       \
        compiler::Assembler assembler(&object_pool_builder, use_far_branches); \
        AssemblerTest test("" #name, &assembler);                              \
        AssemblerTestGenerate##name(test.assembler());                         \
        test.Assemble();                                                       \
        AssemblerTestRun##name(&test);                                         \
        return;                                                                \
      }                                                                        \
    }                                                                          \
                                                                               \
    const Error& error = Error::Handle(Thread::Current()->sticky_error());     \
    if (error.raw() == Object::branch_offset_error().raw()) {                  \
      bool use_far_branches = true;                                            \
      compiler::ObjectPoolBuilder object_pool_builder;                         \
      compiler::Assembler assembler(&object_pool_builder, use_far_branches);   \
      AssemblerTest test("" #name, &assembler);                                \
      AssemblerTestGenerate##name(test.assembler());                           \
      test.Assemble();                                                         \
      AssemblerTestRun##name(&test);                                           \
    } else {                                                                   \
      FATAL1("Unexpected error: %s\n", error.ToErrorCString());                \
    }                                                                          \
  }                                                                            \
  static void AssemblerTestRun##name(AssemblerTest* test)

#define ASSEMBLER_TEST_RUN(name, test)                                         \
  ASSEMBLER_TEST_RUN_WITH_EXPECTATION(name, test, "Pass")

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
#if defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
// Running on actual ARM hardware, execute code natively.
#define EXECUTE_TEST_CODE_INT32(name, entry) reinterpret_cast<name>(entry)()
#define EXECUTE_TEST_CODE_INT64(name, entry) reinterpret_cast<name>(entry)()
#define EXECUTE_TEST_CODE_INT64_LL(name, entry, long_arg0, long_arg1)          \
  reinterpret_cast<name>(entry)(long_arg0, long_arg1)
#define EXECUTE_TEST_CODE_FLOAT(name, entry) reinterpret_cast<name>(entry)()
#define EXECUTE_TEST_CODE_DOUBLE(name, entry) reinterpret_cast<name>(entry)()
#define EXECUTE_TEST_CODE_INT32_F(name, entry, float_arg)                      \
  reinterpret_cast<name>(entry)(float_arg)
#define EXECUTE_TEST_CODE_INT32_D(name, entry, double_arg)                     \
  reinterpret_cast<name>(entry)(double_arg)
#define EXECUTE_TEST_CODE_INTPTR_INTPTR(name, entry, pointer_arg)              \
  reinterpret_cast<name>(entry)(pointer_arg)
#define EXECUTE_TEST_CODE_INT32_INTPTR(name, entry, pointer_arg)               \
  reinterpret_cast<name>(entry)(pointer_arg)
#else
// Not running on ARM hardware, call simulator to execute code.
#if defined(ARCH_IS_64_BIT)
#define EXECUTE_TEST_CODE_INT64(name, entry)                                   \
  static_cast<int64_t>(                                                        \
      Simulator::Current()->Call(bit_cast<int64_t, uword>(entry), 0, 0, 0, 0))
#define EXECUTE_TEST_CODE_DOUBLE(name, entry)                                  \
  bit_cast<double, int64_t>(Simulator::Current()->Call(                        \
      bit_cast<int64_t, uword>(entry), 0, 0, 0, 0, true))
#define EXECUTE_TEST_CODE_INTPTR_INTPTR(name, entry, pointer_arg)              \
  static_cast<intptr_t>(Simulator::Current()->Call(                            \
      bit_cast<int64_t, uword>(entry),                                         \
      bit_cast<int64_t, intptr_t>(pointer_arg), 0, 0, 0))
#define EXECUTE_TEST_CODE_INT32_INTPTR(name, entry, pointer_arg)               \
  static_cast<int32_t>(Simulator::Current()->Call(                             \
      bit_cast<int64_t, uword>(entry),                                         \
      bit_cast<int64_t, intptr_t>(pointer_arg), 0, 0, 0))
#else
#define EXECUTE_TEST_CODE_INT32(name, entry)                                   \
  static_cast<int32_t>(                                                        \
      Simulator::Current()->Call(bit_cast<int32_t, uword>(entry), 0, 0, 0, 0))
#define EXECUTE_TEST_CODE_DOUBLE(name, entry)                                  \
  bit_cast<double, int64_t>(Simulator::Current()->Call(                        \
      bit_cast<int32_t, uword>(entry), 0, 0, 0, 0, true))
#define EXECUTE_TEST_CODE_INTPTR_INTPTR(name, entry, pointer_arg)              \
  static_cast<intptr_t>(Simulator::Current()->Call(                            \
      bit_cast<int32_t, uword>(entry),                                         \
      bit_cast<int32_t, intptr_t>(pointer_arg), 0, 0, 0))
#define EXECUTE_TEST_CODE_INT32_INTPTR(name, entry, pointer_arg)               \
  static_cast<int32_t>(Simulator::Current()->Call(                             \
      bit_cast<int32_t, uword>(entry),                                         \
      bit_cast<int32_t, intptr_t>(pointer_arg), 0, 0, 0))
#endif  // defined(ARCH_IS_64_BIT)
#define EXECUTE_TEST_CODE_INT64_LL(name, entry, long_arg0, long_arg1)          \
  static_cast<int64_t>(Simulator::Current()->Call(                             \
      bit_cast<int32_t, uword>(entry), Utils::Low32Bits(long_arg0),            \
      Utils::High32Bits(long_arg0), Utils::Low32Bits(long_arg1),               \
      Utils::High32Bits(long_arg1)))
#define EXECUTE_TEST_CODE_FLOAT(name, entry)                                   \
  bit_cast<float, int32_t>(Simulator::Current()->Call(                         \
      bit_cast<int32_t, uword>(entry), 0, 0, 0, 0, true))
#define EXECUTE_TEST_CODE_INT32_F(name, entry, float_arg)                      \
  static_cast<int32_t>(Simulator::Current()->Call(                             \
      bit_cast<int32_t, uword>(entry), bit_cast<int32_t, float>(float_arg), 0, \
      0, 0, false, true))
#define EXECUTE_TEST_CODE_INT32_D(name, entry, double_arg)                     \
  static_cast<int32_t>(Simulator::Current()->Call(                             \
      bit_cast<int32_t, uword>(entry),                                         \
      Utils::Low32Bits(bit_cast<int64_t, double>(double_arg)),                 \
      Utils::High32Bits(bit_cast<int64_t, double>(double_arg)), 0, 0, false,   \
      true))
#endif  // defined(HOST_ARCH_ARM)
#endif  // defined(TARGET_ARCH_{ARM, ARM64})

#define ZONE_STR(FMT, ...)                                                     \
  OS::SCreate(Thread::Current()->zone(), FMT, __VA_ARGS__)

inline Dart_Handle NewString(const char* str) {
  return Dart_NewStringFromCString(str);
}

namespace dart {

// Forward declarations.
namespace compiler {
class Assembler;
}
class CodeGenerator;
class VirtualMemory;

namespace bin {
// Snapshot pieces if we link in a snapshot, otherwise initialized to NULL.
extern const uint8_t* vm_snapshot_data;
extern const uint8_t* vm_snapshot_instructions;
extern const uint8_t* core_isolate_snapshot_data;
extern const uint8_t* core_isolate_snapshot_instructions;
}  // namespace bin

extern const uint8_t* platform_strong_dill;
extern const intptr_t platform_strong_dill_size;

class TesterState : public AllStatic {
 public:
  static const uint8_t* vm_snapshot_data;
  static Dart_IsolateGroupCreateCallback create_callback;
  static Dart_IsolateShutdownCallback shutdown_callback;
  static Dart_IsolateGroupCleanupCallback group_cleanup_callback;
  static const char** argv;
  static int argc;
};

class KernelBufferList {
 public:
  explicit KernelBufferList(const uint8_t* kernel_buffer)
      : kernel_buffer_(kernel_buffer), next_(NULL) {}

  KernelBufferList(const uint8_t* kernel_buffer, KernelBufferList* next)
      : kernel_buffer_(kernel_buffer), next_(next) {}

  ~KernelBufferList() {
    free(const_cast<uint8_t*>(kernel_buffer_));
    if (next_ != NULL) {
      delete next_;
    }
  }

  void AddBufferToList(const uint8_t* kernel_buffer);

 private:
  const uint8_t* kernel_buffer_;
  KernelBufferList* next_;
};

class TestCaseBase {
 public:
  explicit TestCaseBase(const char* name, const char* expectation);
  virtual ~TestCaseBase() {}

  const char* name() const { return name_; }
  const char* expectation() const { return expectation_; }

  virtual void Run() = 0;
  void RunTest();

  static void RunAll();
  static void RunAllRaw();
  static void CleanupState();
  static void AddToKernelBuffers(const uint8_t* kernel_buffer);

 protected:
  static KernelBufferList* current_kernel_buffers_;
  bool raw_test_;

 private:
  static TestCaseBase* first_;
  static TestCaseBase* tail_;

  TestCaseBase* next_;
  const char* name_;
  const char* expectation_;

  DISALLOW_COPY_AND_ASSIGN(TestCaseBase);
};

#define USER_TEST_URI "test-lib"
#define RESOLVED_USER_TEST_URI "file:///test-lib"
#define CORELIB_TEST_URI "dart:test-lib"

class TestCase : TestCaseBase {
 public:
  typedef void(RunEntry)();

  TestCase(RunEntry* run, const char* name, const char* expectation)
      : TestCaseBase(name, expectation), run_(run) {}

  static char* CompileTestScriptWithDFE(const char* url,
                                        const char* source,
                                        const uint8_t** kernel_buffer,
                                        intptr_t* kernel_buffer_size,
                                        bool incrementally = true,
                                        bool allow_compile_errors = false,
                                        const char* multiroot_filepaths = NULL,
                                        const char* multiroot_scheme = NULL);
  static char* CompileTestScriptWithDFE(const char* url,
                                        int sourcefiles_count,
                                        Dart_SourceFile sourcefiles[],
                                        const uint8_t** kernel_buffer,
                                        intptr_t* kernel_buffer_size,
                                        bool incrementally = true,
                                        bool allow_compile_errors = false,
                                        const char* multiroot_filepaths = NULL,
                                        const char* multiroot_scheme = NULL);
  static Dart_Handle LoadTestScript(
      const char* script,
      Dart_NativeEntryResolver resolver,
      const char* lib_uri = RESOLVED_USER_TEST_URI,
      bool finalize = true,
      bool allow_compile_errors = false);
  static Dart_Handle LoadTestScriptWithErrors(
      const char* script,
      Dart_NativeEntryResolver resolver = NULL,
      const char* lib_uri = RESOLVED_USER_TEST_URI,
      bool finalize = true);
  static Dart_Handle LoadTestLibrary(const char* lib_uri,
                                     const char* script,
                                     Dart_NativeEntryResolver resolver = NULL);
  static Dart_Handle LoadTestScriptWithDFE(
      int sourcefiles_count,
      Dart_SourceFile sourcefiles[],
      Dart_NativeEntryResolver resolver = NULL,
      bool finalize = true,
      bool incrementally = true,
      bool allow_compile_errors = false,
      const char* entry_script_uri = NULL,
      const char* multiroot_filepaths = NULL,
      const char* multiroot_scheme = NULL);
  static Dart_Handle LoadCoreTestScript(const char* script,
                                        Dart_NativeEntryResolver resolver);

  static Dart_Handle EvaluateExpression(const Library& lib,
                                        const String& expr,
                                        const Array& param_names,
                                        const Array& param_values);

  static Dart_Handle lib();
  static const char* url();
  static Dart_Isolate CreateTestIsolateFromSnapshot(uint8_t* buffer,
                                                    const char* name = NULL) {
    return CreateIsolate(buffer, 0, NULL, name);
  }
  static Dart_Isolate CreateTestIsolate(const char* name = nullptr,
                                        void* isolate_group_data = nullptr,
                                        void* isolate_data = nullptr);
  static Dart_Isolate CreateTestIsolateInGroup(const char* name,
                                               Dart_Isolate parent,
                                               void* group_data = nullptr,
                                               void* isolate_data = nullptr);

  static Dart_Handle library_handler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url);

  virtual void Run();

  // Sets |script| to be the source used at next reload.
  static Dart_Handle SetReloadTestScript(const char* script);

  // Initiates the reload.
  static Dart_Handle TriggerReload(const uint8_t* kernel_buffer,
                                   intptr_t kernel_buffer_size);

  // Helper function which reloads the current isolate using |script|.
  static Dart_Handle ReloadTestScript(const char* script);

  // Helper function which reloads the current isolate using |script|.
  static Dart_Handle ReloadTestKernel(const uint8_t* kernel_buffer,
                                      intptr_t kernel_buffer_size);

  static void AddTestLib(const char* url, const char* source);
  static const char* GetTestLib(const char* url);

  // Return true if non-nullable experiment is enabled.
  static bool IsNNBD();

  static const char* NullableTag() { return IsNNBD() ? "?" : ""; }
  static const char* NullAssertTag() { return IsNNBD() ? "!" : ""; }
  static const char* LateTag() { return IsNNBD() ? "late" : ""; }

 private:
  // |data_buffer| can either be snapshot data, or kernel binary data.
  // If |data_buffer| is snapshot data, then |len| should be zero as snapshot
  // size is encoded within them. If |len| is non-zero, then |data_buffer|
  // will be treated as a kernel binary (but CreateIsolate will not
  // take ownership of the buffer) and |instr_buffer| will be ignored.
  static Dart_Isolate CreateIsolate(const uint8_t* data_buffer,
                                    intptr_t len,
                                    const uint8_t* instr_buffer,
                                    const char* name,
                                    void* group_data = nullptr,
                                    void* isolate_data = nullptr);

  static char* ValidateCompilationResult(Zone* zone,
                                         Dart_KernelCompilationResult result,
                                         const uint8_t** kernel_buffer,
                                         intptr_t* kernel_buffer_size,
                                         bool allow_compile_errors);

  RunEntry* const run_;
};

class RawTestCase : TestCaseBase {
 public:
  typedef void(RunEntry)();

  RawTestCase(RunEntry* run, const char* name, const char* expectation)
      : TestCaseBase(name, expectation), run_(run) {
    raw_test_ = true;
  }
  virtual void Run();

 private:
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

// Ensures core libraries are initialized, thereby allowing vm/cc tests to
// e.g. run functions using microtasks.
void SetupCoreLibrariesForUnitTest();

template <typename T>
struct is_void {
  static const bool value = false;
};

template <>
struct is_void<void> {
  static const bool value = true;
};

template <typename T>
struct is_double {
  static const bool value = false;
};

template <>
struct is_double<double> {
  static const bool value = true;
};

class AssemblerTest {
 public:
  AssemblerTest(const char* name, compiler::Assembler* assembler)
      : name_(name),
        assembler_(assembler),
        code_(Code::ZoneHandle()),
        disassembly_(Thread::Current()->zone()->Alloc<char>(DISASSEMBLY_SIZE)) {
    ASSERT(name != NULL);
    ASSERT(assembler != NULL);
  }
  ~AssemblerTest() {}

  compiler::Assembler* assembler() const { return assembler_; }

  const Code& code() const { return code_; }

  uword payload_start() const { return code_.PayloadStart(); }
  uword payload_size() const { return assembler_->CodeSize(); }
  uword entry() const { return code_.EntryPoint(); }

// Invoke/InvokeWithCodeAndThread is used to call assembler test functions
// using the ABI calling convention.
// ResultType is the return type of the assembler test function.
// ArgNType is the type of the Nth argument.
#if defined(USING_SIMULATOR)

#if defined(ARCH_IS_64_BIT)
  // TODO(fschneider): Make InvokeWithCodeAndThread<> more general and work on
  // 32-bit.
  // Since Simulator::Call always return a int64_t, bit_cast does not work
  // on 32-bit platforms when returning an int32_t. Since template functions
  // don't support partial specialization, we'd need to introduce a helper
  // class to support 32-bit return types.
  template <typename ResultType>
  ResultType InvokeWithCodeAndThread() {
    const bool fp_return = is_double<ResultType>::value;
    const bool fp_args = false;
    Thread* thread = Thread::Current();
    ASSERT(thread != NULL);
    return bit_cast<ResultType, int64_t>(Simulator::Current()->Call(
        bit_cast<intptr_t, uword>(entry()), reinterpret_cast<intptr_t>(&code_),
        reinterpret_cast<intptr_t>(thread), 0, 0, fp_return, fp_args));
  }
  template <typename ResultType, typename Arg1Type>
  ResultType InvokeWithCodeAndThread(Arg1Type arg1) {
    const bool fp_return = is_double<ResultType>::value;
    const bool fp_args = is_double<Arg1Type>::value;
    // TODO(fschneider): Support double arguments for simulator calls.
    COMPILE_ASSERT(!fp_args);
    Thread* thread = Thread::Current();
    ASSERT(thread != NULL);
    return bit_cast<ResultType, int64_t>(Simulator::Current()->Call(
        bit_cast<intptr_t, uword>(entry()), reinterpret_cast<intptr_t>(&code_),
        reinterpret_cast<intptr_t>(thread), reinterpret_cast<intptr_t>(arg1), 0,
        fp_return, fp_args));
  }
#endif  // ARCH_IS_64_BIT

  template <typename ResultType,
            typename Arg1Type,
            typename Arg2Type,
            typename Arg3Type>
  ResultType Invoke(Arg1Type arg1, Arg2Type arg2, Arg3Type arg3) {
    // TODO(fschneider): Support double arguments for simulator calls.
    COMPILE_ASSERT(is_void<ResultType>::value);
    COMPILE_ASSERT(!is_double<Arg1Type>::value);
    COMPILE_ASSERT(!is_double<Arg2Type>::value);
    COMPILE_ASSERT(!is_double<Arg3Type>::value);
    const bool fp_args = false;
    const bool fp_return = false;
    Simulator::Current()->Call(
        bit_cast<intptr_t, uword>(entry()), static_cast<intptr_t>(arg1),
        static_cast<intptr_t>(arg2), reinterpret_cast<intptr_t>(arg3), 0,
        fp_return, fp_args);
  }
#else
  template <typename ResultType>
  ResultType InvokeWithCodeAndThread() {
    Thread* thread = Thread::Current();
    ASSERT(thread != NULL);
    typedef ResultType (*FunctionType)(const Code&, Thread*);
    return reinterpret_cast<FunctionType>(entry())(code_, thread);
  }

  template <typename ResultType, typename Arg1Type>
  ResultType InvokeWithCodeAndThread(Arg1Type arg1) {
    Thread* thread = Thread::Current();
    ASSERT(thread != NULL);
    typedef ResultType (*FunctionType)(const Code&, Thread*, Arg1Type);
    return reinterpret_cast<FunctionType>(entry())(code_, thread, arg1);
  }

  template <typename ResultType,
            typename Arg1Type,
            typename Arg2Type,
            typename Arg3Type>
  ResultType Invoke(Arg1Type arg1, Arg2Type arg2, Arg3Type arg3) {
    typedef ResultType (*FunctionType)(Arg1Type, Arg2Type, Arg3Type);
    return reinterpret_cast<FunctionType>(entry())(arg1, arg2, arg3);
  }
#endif  // defined(USING_SIMULATOR)

  // Assemble test and set code_.
  void Assemble();

  // Disassembly of the code with large constants blanked out.
  char* BlankedDisassembly() { return disassembly_; }

 private:
  const char* name_;
  compiler::Assembler* assembler_;
  Code& code_;
  static const intptr_t DISASSEMBLY_SIZE = 10240;
  char* disassembly_;

  DISALLOW_COPY_AND_ASSIGN(AssemblerTest);
};

class CompilerTest : public AllStatic {
 public:
  // Test the Compiler::CompileFunction functionality by checking the return
  // value to see if no parse errors were reported.
  static bool TestCompileFunction(const Function& function);
};

#define EXPECT_VALID(handle)                                                   \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (!Api::IsValid(tmp_handle)) {                                           \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail(                                                               \
              "expected '%s' to be a valid handle but '%s' has already been "  \
              "freed\n",                                                       \
              #handle, #handle);                                               \
    }                                                                          \
    if (Dart_IsError(tmp_handle)) {                                            \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail(                                                               \
              "expected '%s' to be a valid handle but found an error "         \
              "handle:\n"                                                      \
              "    '%s'\n",                                                    \
              #handle, Dart_GetError(tmp_handle));                             \
    }                                                                          \
  } while (0)

#define EXPECT_ERROR(handle, substring)                                        \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (Dart_IsError(tmp_handle)) {                                            \
      dart::Expect(__FILE__, __LINE__)                                         \
          .IsSubstring((substring), Dart_GetError(tmp_handle));                \
    } else {                                                                   \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail(                                                               \
              "expected '%s' to be an error handle but found a valid "         \
              "handle.\n",                                                     \
              #handle);                                                        \
    }                                                                          \
  } while (0)

#define EXPECT_TRUE(handle)                                                    \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (Dart_IsBoolean(tmp_handle)) {                                          \
      bool value;                                                              \
      Dart_BooleanValue(tmp_handle, &value);                                   \
      if (!value) {                                                            \
        dart::Expect(__FILE__, __LINE__)                                       \
            .Fail("expected True, but was '%s'\n", #handle);                   \
      }                                                                        \
    } else {                                                                   \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("expected True, but was '%s'\n", #handle);                     \
    }                                                                          \
  } while (0)

#define EXPECT_NULL(handle)                                                    \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (!Dart_IsNull(tmp_handle)) {                                            \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("expected '%s' to be a null handle.\n", #handle);              \
    }                                                                          \
  } while (0)

#define EXPECT_NON_NULL(handle)                                                \
  do {                                                                         \
    Dart_Handle tmp_handle = (handle);                                         \
    if (Dart_IsNull(tmp_handle)) {                                             \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("expected '%s' to be a non-null handle.\n", #handle);          \
    }                                                                          \
  } while (0)

// Elide a substring which starts with some prefix and ends with a ".
//
// This is used to remove non-deterministic or fragile substrings from
// JSON output.
//
// For example:
//
//    prefix = "classes"
//    in = "\"id\":\"classes/46\""
//
// Yields:
//
//    out = "\"id\":\"\""
//
void ElideJSONSubstring(const char* prefix, const char* in, char* out);

template <typename T>
class SetFlagScope : public ValueObject {
 public:
  SetFlagScope(T* flag, T value) : flag_(flag), original_value_(*flag) {
    *flag_ = value;
  }

  ~SetFlagScope() { *flag_ = original_value_; }

 private:
  T* flag_;
  T original_value_;
};

}  // namespace dart

#endif  // RUNTIME_VM_UNIT_TEST_H_

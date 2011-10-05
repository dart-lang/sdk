// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/resolver.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

// Setup function for invocation.
static void SetupFunction(const char* test_library_name,
                          const char* test_class_name,
                          const char* test_static_function_name,
                          bool is_static) {
  // Setup a dart class and function.
  char script_chars[1024];
  OS::SNPrint(script_chars,
              sizeof(script_chars),
              "class Base {\n"
              "  dynCall() { return 3; }\n"
              "  static statCall() { return 4; }\n"
              "\n"
              "}\n"
              "class %s extends Base {\n"
              "  %s %s(String s, int i) { return i; }\n"
              "}\n",
              test_class_name,
              is_static ? "static" : "",
              test_static_function_name);

  String& url = String::Handle(is_static ?
                               String::New("dart-test:DartStaticResolve") :
                               String::New("dart-test:DartDynamicResolve"));
  String& source = String::Handle(String::New(script_chars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kScript));
  const String& lib_name = String::Handle(String::New(test_library_name));
  Library& lib = Library::Handle(Library::New(lib_name));
  lib.Register();
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
}


// Setup a static function for invocation.
static void SetupStaticFunction(const char* test_library_name,
                                const char* test_class_name,
                                const char* test_static_function_name) {
  // Setup a static dart class and function.
  SetupFunction(test_library_name,
                test_class_name,
                test_static_function_name,
                true);
}


// Setup an instance  function for invocation.
static void SetupInstanceFunction(const char* test_library_name,
                                  const char* test_class_name,
                                  const char* test_function_name) {
  // Setup a static dart class and function.
  SetupFunction(test_library_name,
                test_class_name,
                test_function_name,
                false);
}


TEST_CASE(DartStaticResolve) {
  const char* test_library_name = "ResolverApp";
  const char* test_class_name = "A";
  const char* test_static_function_name = "static_foo";
  const int kTestValue = 42;
  const Resolver::StaticResolveType kResolveType = Resolver::kIsQualified;

  // Setup a static function which can be invoked.
  SetupStaticFunction(test_library_name,
                      test_class_name,
                      test_static_function_name);

  const String& library_name = String::Handle(String::New(test_library_name));
  const Library& library =
      Library::Handle(Library::LookupLibrary(library_name));
  const String& class_name = String::Handle(String::New(test_class_name));
  const String& static_function_name =
      String::Handle(String::New(test_static_function_name));

  // Now try to resolve and invoke the static function in this class.
  {
    const int kNumArguments = 2;
    const Array& kNoArgumentNames = Array::Handle();
    const Function& function = Function::Handle(
        Resolver::ResolveStatic(library,
                                class_name,
                                static_function_name,
                                kNumArguments,
                                kNoArgumentNames,
                                kResolveType));
    EXPECT(!function.IsNull());
    GrowableArray<const Object*> arguments(2);
    const String& arg0 = String::Handle(String::New("junk"));
    arguments.Add(&arg0);
    const Smi& arg1 = Smi::Handle(Smi::New(kTestValue));
    arguments.Add(&arg1);
    const Smi& retval = Smi::Handle(
        reinterpret_cast<RawSmi*>(
            DartEntry::InvokeStatic(function, arguments)));
    EXPECT_EQ(kTestValue, retval.Value());
  }

  // Now try to resolve a static function with invalid argument count.
  {
    const int kNumArguments = 1;
    const Array& kNoArgumentNames = Array::Handle();
    const Function& bad_function = Function::Handle(
        Resolver::ResolveStatic(library,
                                class_name,
                                static_function_name,
                                kNumArguments,
                                kNoArgumentNames,
                                kResolveType));
    EXPECT(bad_function.IsNull());
  }

  // Hierarchy walking.
  {
    const String& super_static_function_name =
        String::Handle(String::New("statCall"));
    const String& super_class_name = String::Handle(String::New("Base"));
    const int kNumArguments = 0;
    const Array& kNoArgumentNames = Array::Handle();
    const Function& super_function = Function::Handle(
        Resolver::ResolveStatic(library,
                                super_class_name,
                                super_static_function_name,
                                kNumArguments,
                                kNoArgumentNames,
                                kResolveType));
    EXPECT(!super_function.IsNull());
  }
}


TEST_CASE(DartDynamicResolve) {
  const char* test_library_name = "ResolverApp";
  const char* test_class_name = "A";
  const char* test_function_name = "foo";
  const int kTestValue = 42;

  // Setup a function which can be invoked.
  SetupInstanceFunction(test_library_name,
                        test_class_name,
                        test_function_name);

  // Now create an instance object of the class and try to
  // resolve a function in it.
  const String& lib_name = String::Handle(String::New(test_library_name));
  const Library& lib = Library::Handle(Library::LookupLibrary(lib_name));
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(lib.LookupClass(
      String::Handle(String::NewSymbol(test_class_name))));
  EXPECT(!cls.IsNull());

  Instance& receiver = Instance::Handle(Instance::New(cls));
  const String& function_name = String::Handle(String::New(test_function_name));

  // Now try to resolve and invoke the instance function in this class.
  {
    const int kNumPositionalArguments = 3;
    const int kNumNamedArguments = 0;
    const Function& function = Function::Handle(
        Resolver::ResolveDynamic(receiver,
                                 function_name,
                                 kNumPositionalArguments,
                                 kNumNamedArguments));
    EXPECT(!function.IsNull());
    GrowableArray<const Object*> arguments;
    const String& arg0 = String::Handle(String::New("junk"));
    arguments.Add(&arg0);
    const Smi& arg1 = Smi::Handle(Smi::New(kTestValue));
    arguments.Add(&arg1);
    const Smi& retval = Smi::Handle(
        reinterpret_cast<RawSmi*>(DartEntry::InvokeDynamic(receiver,
                                                           function,
                                                           arguments)));
    EXPECT_EQ(kTestValue, retval.Value());
  }

  // Now try to resolve an instance function with invalid argument count.
  {
    const int kNumPositionalArguments = 1;
    const int kNumNamedArguments = 0;
    const Function& bad_function = Function::Handle(
        Resolver::ResolveDynamic(receiver,
                                 function_name,
                                 kNumPositionalArguments,
                                 kNumNamedArguments));
    EXPECT(bad_function.IsNull());
  }

  // Hierarchy walking.
  {
    const int kNumPositionalArguments = 1;
    const int kNumNamedArguments = 0;
    const String& super_function_name =
        String::Handle(String::New("dynCall"));
    const Function& super_function = Function::Handle(
        Resolver::ResolveDynamic(receiver,
                                 super_function_name,
                                 kNumPositionalArguments,
                                 kNumNamedArguments));
    EXPECT(!super_function.IsNull());
  }
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart

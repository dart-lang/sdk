// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/resolver.h"
#include "platform/assert.h"
#include "vm/assembler.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

// Setup function for invocation.
static void SetupFunction(const char* test_library_name,
                          const char* test_class_name,
                          const char* test_static_function_name,
                          bool is_static) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // Setup a dart class and function.
  char script_chars[1024];
  OS::SNPrint(script_chars, sizeof(script_chars),
              "class Base {\n"
              "  dynCall() { return 3; }\n"
              "  static statCall() { return 4; }\n"
              "\n"
              "}\n"
              "class %s extends Base {\n"
              "  %s %s(String s, int i) { return i; }\n"
              "}\n",
              test_class_name, is_static ? "static" : "",
              test_static_function_name);

  String& url = String::Handle(
      zone, is_static ? String::New("dart-test:DartStaticResolve")
                      : String::New("dart-test:DartDynamicResolve"));
  String& source = String::Handle(zone, String::New(script_chars));
  Script& script =
      Script::Handle(zone, Script::New(url, source, RawScript::kScriptTag));
  const String& lib_name = String::Handle(zone, String::New(test_library_name));
  Library& lib = Library::Handle(zone, Library::New(lib_name));
  lib.Register(thread);
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
}

// Setup a static function for invocation.
static void SetupStaticFunction(const char* test_library_name,
                                const char* test_class_name,
                                const char* test_static_function_name) {
  // Setup a static dart class and function.
  SetupFunction(test_library_name, test_class_name, test_static_function_name,
                true);
}

// Setup an instance  function for invocation.
static void SetupInstanceFunction(const char* test_library_name,
                                  const char* test_class_name,
                                  const char* test_function_name) {
  // Setup a static dart class and function.
  SetupFunction(test_library_name, test_class_name, test_function_name, false);
}

TEST_CASE(DartStaticResolve) {
  const char* test_library_name = "ResolverApp";
  const char* test_class_name = "A";
  const char* test_static_function_name = "static_foo";
  const int kTestValue = 42;

  // Setup a static function which can be invoked.
  SetupStaticFunction(test_library_name, test_class_name,
                      test_static_function_name);

  const String& library_name = String::Handle(String::New(test_library_name));
  const Library& library =
      Library::Handle(Library::LookupLibrary(thread, library_name));
  const String& class_name = String::Handle(String::New(test_class_name));
  const String& static_function_name =
      String::Handle(String::New(test_static_function_name));

  // Now try to resolve and invoke the static function in this class.
  {
    const int kTypeArgsLen = 0;
    const int kNumArguments = 2;
    const Function& function = Function::Handle(Resolver::ResolveStatic(
        library, class_name, static_function_name, kTypeArgsLen, kNumArguments,
        Object::empty_array()));
    EXPECT(!function.IsNull());  // No ambiguity error expected.
    const Array& args = Array::Handle(Array::New(kNumArguments));
    const String& arg0 = String::Handle(String::New("junk"));
    args.SetAt(0, arg0);
    const Smi& arg1 = Smi::Handle(Smi::New(kTestValue));
    args.SetAt(1, arg1);
    const Smi& retval = Smi::Handle(
        reinterpret_cast<RawSmi*>(DartEntry::InvokeFunction(function, args)));
    EXPECT_EQ(kTestValue, retval.Value());
  }

  // Now try to resolve a static function with invalid argument count.
  {
    const int kTypeArgsLen = 0;
    const int kNumArguments = 1;
    const Function& bad_function = Function::Handle(Resolver::ResolveStatic(
        library, class_name, static_function_name, kTypeArgsLen, kNumArguments,
        Object::empty_array()));
    EXPECT(bad_function.IsNull());  // No ambiguity error expected.
  }

  // Hierarchy walking.
  {
    const String& super_static_function_name =
        String::Handle(String::New("statCall"));
    const String& super_class_name = String::Handle(String::New("Base"));
    const int kTypeArgsLen = 0;
    const int kNumArguments = 0;
    const Function& super_function = Function::Handle(Resolver::ResolveStatic(
        library, super_class_name, super_static_function_name, kTypeArgsLen,
        kNumArguments, Object::empty_array()));
    EXPECT(!super_function.IsNull());  // No ambiguity error expected.
  }
}

TEST_CASE(DartDynamicResolve) {
  const char* test_library_name = "ResolverApp";
  const char* test_class_name = "A";
  const char* test_function_name = "foo";
  const int kTestValue = 42;

  // Setup a function which can be invoked.
  SetupInstanceFunction(test_library_name, test_class_name, test_function_name);

  // Now create an instance object of the class and try to
  // resolve a function in it.
  const String& lib_name = String::Handle(String::New(test_library_name));
  const Library& lib =
      Library::Handle(Library::LookupLibrary(thread, lib_name));
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(thread, test_class_name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.

  Instance& receiver = Instance::Handle(Instance::New(cls));
  const String& function_name = String::Handle(String::New(test_function_name));

  // Now try to resolve and invoke the instance function in this class.
  {
    const int kTypeArgsLen = 0;
    const int kNumArguments = 3;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
    const Function& function = Function::Handle(
        Resolver::ResolveDynamic(receiver, function_name, args_desc));
    EXPECT(!function.IsNull());
    const Array& args = Array::Handle(Array::New(kNumArguments));
    args.SetAt(0, receiver);
    const String& arg0 = String::Handle(String::New("junk"));
    args.SetAt(1, arg0);
    const Smi& arg1 = Smi::Handle(Smi::New(kTestValue));
    args.SetAt(2, arg1);
    const Smi& retval = Smi::Handle(
        reinterpret_cast<RawSmi*>(DartEntry::InvokeFunction(function, args)));
    EXPECT_EQ(kTestValue, retval.Value());
  }

  // Now try to resolve an instance function with invalid argument count.
  {
    const int kTypeArgsLen = 0;
    const int kNumArguments = 1;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
    const Function& bad_function = Function::Handle(
        Resolver::ResolveDynamic(receiver, function_name, args_desc));
    EXPECT(bad_function.IsNull());
  }

  // Hierarchy walking.
  {
    const int kTypeArgsLen = 0;
    const int kNumArguments = 1;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
    const String& super_function_name = String::Handle(String::New("dynCall"));
    const Function& super_function = Function::Handle(
        Resolver::ResolveDynamic(receiver, super_function_name, args_desc));
    EXPECT(!super_function.IsNull());
  }
}

}  // namespace dart

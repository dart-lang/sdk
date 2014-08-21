// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#include "vm/assembler.h"
#include "vm/intrinsifier.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, intrinsify, true, "Instrinsify when possible");
DECLARE_FLAG(bool, throw_on_javascript_int_overflow);

bool Intrinsifier::CanIntrinsify(const Function& function) {
  if (!FLAG_intrinsify) return false;
  if (function.IsClosureFunction()) return false;
  // Can occur because of compile-all flag.
  if (function.is_external()) return false;
  return function.is_intrinsic();
}


void Intrinsifier::InitializeState() {
  Isolate* isolate = Isolate::Current();
  Library& lib = Library::Handle(isolate);
  Class& cls = Class::Handle(isolate);
  Function& func = Function::Handle(isolate);
  String& str = String::Handle(isolate);
  Error& error = Error::Handle(isolate);

#define SETUP_FUNCTION(class_name, function_name, destination, fp)             \
  if (strcmp(#class_name, "::") == 0) {                                        \
    str = String::New(#function_name);                                         \
    func = lib.LookupFunctionAllowPrivate(str);                                \
  } else {                                                                     \
    str = String::New(#class_name);                                            \
    cls = lib.LookupClassAllowPrivate(str);                                    \
    ASSERT(!cls.IsNull());                                                     \
    error = cls.EnsureIsFinalized(isolate);                                    \
    if (!error.IsNull()) {                                                     \
      OS::PrintErr("%s\n", error.ToErrorCString());                            \
    }                                                                          \
    ASSERT(error.IsNull());                                                    \
    if (#function_name[0] == '.') {                                            \
      str = String::New(#class_name#function_name);                            \
    } else {                                                                   \
      str = String::New(#function_name);                                       \
    }                                                                          \
    func = cls.LookupFunctionAllowPrivate(str);                                \
  }                                                                            \
  ASSERT(!func.IsNull());                                                      \
  func.set_is_intrinsic(true);

  // Set up all core lib functions that can be intrisified.
  lib = Library::CoreLibrary();
  ASSERT(!lib.IsNull());
  CORE_LIB_INTRINSIC_LIST(SETUP_FUNCTION);
  CORE_INTEGER_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

  // Set up all math lib functions that can be intrisified.
  lib = Library::MathLibrary();
  ASSERT(!lib.IsNull());
  MATH_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

  // Set up all dart:typed_data lib functions that can be intrisified.
  lib = Library::TypedDataLibrary();
  ASSERT(!lib.IsNull());
  TYPED_DATA_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

  // Setup all dart:profiler lib functions that can be intrinsified.
  lib = Library::ProfilerLibrary();
  ASSERT(!lib.IsNull());
  PROFILER_LIB_INTRINSIC_LIST(SETUP_FUNCTION);

#undef SETUP_FUNCTION
}


void Intrinsifier::Intrinsify(const Function& function, Assembler* assembler) {
  if (!CanIntrinsify(function)) return;

#define EMIT_CASE(test_class_name, test_function_name, enum_name, fp)          \
    case MethodRecognizer::k##enum_name:                                       \
      ASSERT(function.CheckSourceFingerprint(fp));                             \
      assembler->Comment("Intrinsic");                                         \
      enum_name(assembler);                                                    \
      break;

  if (FLAG_throw_on_javascript_int_overflow && (Smi::kBits >= 32)) {
    // Integer intrinsics are in the core library, but we don't want to
    // intrinsify when Smi > 32 bits if we are looking for javascript integer
    // overflow.
    switch (function.recognized_kind()) {
      CORE_LIB_INTRINSIC_LIST(EMIT_CASE);
      MATH_LIB_INTRINSIC_LIST(EMIT_CASE);
      TYPED_DATA_LIB_INTRINSIC_LIST(EMIT_CASE);
      PROFILER_LIB_INTRINSIC_LIST(EMIT_CASE);
      default:
        break;
    }
  } else {
    switch (function.recognized_kind()) {
      CORE_LIB_INTRINSIC_LIST(EMIT_CASE);
      CORE_INTEGER_LIB_INTRINSIC_LIST(EMIT_CASE);
      MATH_LIB_INTRINSIC_LIST(EMIT_CASE);
      TYPED_DATA_LIB_INTRINSIC_LIST(EMIT_CASE);
      PROFILER_LIB_INTRINSIC_LIST(EMIT_CASE);
      default:
        UNREACHABLE();
        break;
    }
  }
#undef EMIT_INTRINSIC
}

}  // namespace dart

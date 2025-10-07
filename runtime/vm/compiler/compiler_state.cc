// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/compiler_state.h"

#include <functional>

#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/slot.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"
#include "vm/scopes.h"

namespace dart {

template <typename T>
T* PutIfAbsent(Thread* thread,
               ZoneGrowableArray<T*>** array_slot,
               intptr_t index,
               std::function<T*()> create) {
  auto array = *array_slot;

  if (array == nullptr) {
    Zone* const Z = thread->zone();
    *array_slot = array = new (Z) ZoneGrowableArray<T*>(Z, index + 1);
  }

  while (array->length() <= index) {
    array->Add(nullptr);
  }

  if (array->At(index) == nullptr) {
    (*array)[index] = create();
  }
  return array->At(index);
}

CompilerTracing CompilerState::ShouldTrace(const Function& func) {
  return FlowGraphPrinter::ShouldPrint(func) ? CompilerTracing::kOn
                                             : CompilerTracing::kOff;
}

const Class& CompilerState::ComparableClass() {
  if (comparable_class_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    // When obfuscation is enabled we need to obfuscate the name of the
    // class before looking it up.
    String& name = String::Handle(zone, Symbols::New(thread, "Comparable"));
    if (thread->isolate_group()->obfuscate()) {
      Obfuscator obfuscator(thread, Object::null_string());
      name = obfuscator.Rename(name);
    }

    const Library& lib = Library::Handle(zone, Library::CoreLibrary());
    const Class& cls = Class::ZoneHandle(zone, lib.LookupClass(name));
    ASSERT(!cls.IsNull());
    comparable_class_ = &cls;
  }
  return *comparable_class_;
}

const Function& CompilerState::StringBaseInterpolateSingle() {
  if (interpolate_single_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    interpolate_single_ = &Function::ZoneHandle(
        zone, cls.LookupFunctionAllowPrivate(Symbols::InterpolateSingle()));
    ASSERT(!interpolate_single_->IsNull());
  }
  return *interpolate_single_;
}

const Function& CompilerState::StringBaseInterpolate() {
  if (interpolate_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    interpolate_ = &Function::ZoneHandle(
        zone, cls.LookupFunctionAllowPrivate(Symbols::Interpolate()));
    ASSERT(!interpolate_->IsNull());
  }
  return *interpolate_;
}
#define DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Upper, Lower)                 \
  const Function& CompilerState::TypedListGet##Upper() {                       \
    if (typed_list_get_##Lower##_ == nullptr) {                                \
      Thread* thread = Thread::Current();                                      \
      Zone* zone = thread->zone();                                             \
      const auto& cls = CompilerState::TypedListClass();                       \
      typed_list_get_##Lower##_ = &Function::ZoneHandle(                       \
          zone, cls.LookupFunctionAllowPrivate(Symbols::_nativeGet##Upper())); \
      ASSERT(!typed_list_get_##Lower##_->IsNull());                            \
    }                                                                          \
    return *typed_list_get_##Lower##_;                                         \
  }                                                                            \
  const Function& CompilerState::TypedListSet##Upper() {                       \
    if (typed_list_set_##Lower##_ == nullptr) {                                \
      Thread* thread = Thread::Current();                                      \
      Zone* zone = thread->zone();                                             \
      const auto& cls = CompilerState::TypedListClass();                       \
      typed_list_set_##Lower##_ = &Function::ZoneHandle(                       \
          zone, cls.LookupFunctionAllowPrivate(Symbols::_nativeSet##Upper())); \
      ASSERT(!typed_list_set_##Lower##_->IsNull());                            \
    }                                                                          \
    return *typed_list_set_##Lower##_;                                         \
  }

DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Float32, float32)
DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Float64, float64)
DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Float32x4, float32x4)
DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Int32x4, int32x4)
DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER(Float64x2, float64x2)

#undef DEFINE_TYPED_LIST_NATIVE_FUNCTION_GETTER

#define DEFINE_CLASS_GETTER(Lib, Upper, Lower, Symbol)                         \
  const Class& CompilerState::Upper##Class() {                                 \
    if (Lower##_class_ == nullptr) {                                           \
      Thread* thread = Thread::Current();                                      \
      Zone* zone = thread->zone();                                             \
      const auto& lib = Library::Handle(zone, Library::Lib##Library());        \
      const auto& cls =                                                        \
          Class::Handle(zone, lib.LookupClassAllowPrivate(Symbols::Symbol())); \
      ASSERT(!cls.IsNull());                                                   \
      const Error& error = Error::Handle(zone, cls.EnsureIsFinalized(thread)); \
      ASSERT(error.IsNull());                                                  \
      Lower##_class_ = &cls;                                                   \
    }                                                                          \
    return *Lower##_class_;                                                    \
  }

DEFINE_CLASS_GETTER(TypedData, TypedData, typed_data, TypedData)
DEFINE_CLASS_GETTER(TypedData, TypedList, typed_list, _TypedList)

#undef DEFINE_CLASS_GETTER

const Field& CompilerState::ErrorStackTraceField() {
  if (error_stack_trace_field_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    const auto& error_class = Class::Handle(
        zone, thread->isolate_group()->object_store()->error_class());
    const auto& field = Field::ZoneHandle(
        zone,
        error_class.LookupInstanceFieldAllowPrivate(Symbols::_stackTrace()));
    ASSERT(!field.IsNull());
    error_stack_trace_field_ = &field;
  }
  return *error_stack_trace_field_;
}

static bool IsMarkedWithNoBoundsChecks(const Function& function) {
  Object& options = Object::Handle();
  return Library::FindPragma(dart::Thread::Current(),
                             /*only_core=*/false, function,
                             Symbols::vm_unsafe_no_bounds_checks(),
                             /*multiple=*/false, &options);
}

FunctionPragmas::FunctionPragmas(const Function& function)
    : function(function),
      unsafe_no_bounds_checks(IsMarkedWithNoBoundsChecks(function)) {}

const FunctionPragmas& CompilerState::PragmasOf(const Function& function) {
  if (cached_pragmas_ == nullptr) {
    Zone* zone = thread()->zone();
    cached_pragmas_ = new (zone) CachedPragmasMap(zone);
  }

  auto result = cached_pragmas_->LookupValue(&function);
  if (result == nullptr) {
    Zone* zone = thread()->zone();
    result = new (zone) FunctionPragmas(Function::Handle(zone, function.ptr()));
    cached_pragmas_->Insert(result);
  }

  return *result;
}

void CompilerState::ReportCrash() {
  OS::PrintErr("=== Crash occurred when compiling %s in %s mode in %s pass\n",
               function() != nullptr ? function()->ToFullyQualifiedCString()
                                     : "unknown function",
               is_aot()          ? "AOT"
               : is_optimizing() ? "optimizing JIT"
                                 : "unoptimized JIT",
               pass() != nullptr ? pass()->name() : "unknown");
  if (pass_state() != nullptr && pass()->id() == CompilerPass::kGenerateCode) {
    if (pass_state()->graph_compiler->current_block() != nullptr) {
      OS::PrintErr("=== When compiling block %s\n",
                   pass_state()->graph_compiler->current_block()->ToCString());
    }
    if (pass_state()->graph_compiler->current_instruction() != nullptr) {
      OS::PrintErr(
          "=== When compiling instruction %s\n",
          pass_state()->graph_compiler->current_instruction()->ToCString());
    }
  }
  if (pass_state() != nullptr && pass_state()->flow_graph() != nullptr) {
    pass_state()->flow_graph()->Print(pass()->name());
  } else {
    OS::PrintErr("=== Flow Graph not available\n");
  }
}

}  // namespace dart

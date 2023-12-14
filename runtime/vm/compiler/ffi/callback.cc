// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/callback.h"

#include "vm/canonical_tables.h"
#include "vm/class_finalizer.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

const String& NativeCallbackFunctionName(Thread* thread,
                                         Zone* zone,
                                         const Function& dart_target,
                                         FfiFunctionKind kind) {
  switch (kind) {
    case FfiFunctionKind::kAsyncCallback:
      return Symbols::FfiAsyncCallback();
    case FfiFunctionKind::kIsolateLocalClosureCallback:
      return Symbols::FfiIsolateLocalCallback();
    case FfiFunctionKind::kIsolateLocalStaticCallback:
      return String::Handle(
          zone, Symbols::FromConcat(thread, Symbols::FfiCallback(),
                                    String::Handle(zone, dart_target.name())));
    default:
      UNREACHABLE();
  }
}

FunctionPtr NativeCallbackFunction(const FunctionType& c_signature,
                                   const Function& dart_target,
                                   const Instance& exceptional_return,
                                   FfiFunctionKind kind) {
  Thread* const thread = Thread::Current();
  Zone* const zone = thread->zone();
  Function& function = Function::Handle(zone);
  ASSERT(c_signature.IsCanonical());
  ASSERT(exceptional_return.IsSmi() || exceptional_return.IsCanonical());

  // Create a new Function named '<target>_FfiCallback' and stick it in the
  // 'dart:ffi' library. Note that these functions will never be invoked by
  // Dart, so they may have duplicate names.
  const auto& name =
      NativeCallbackFunctionName(thread, zone, dart_target, kind);
  const Library& lib = Library::Handle(zone, Library::FfiLibrary());
  const Class& owner_class = Class::Handle(zone, lib.toplevel_class());
  auto& signature = FunctionType::Handle(zone, FunctionType::New());
  function =
      Function::New(signature, name, UntaggedFunction::kFfiTrampoline,
                    /*is_static=*/true,
                    /*is_const=*/false,
                    /*is_abstract=*/false,
                    /*is_external=*/false,
                    /*is_native=*/false, owner_class, TokenPosition::kNoSource);
  function.set_is_debuggable(false);

  // Set callback-specific fields which the flow-graph builder needs to generate
  // the body.
  function.SetFfiCSignature(c_signature);
  function.SetFfiCallbackTarget(dart_target);
  function.SetFfiFunctionKind(kind);

  // We need to load the exceptional return value as a constant in the generated
  // function. Even though the FE ensures that it is a constant, it could still
  // be a literal allocated in new space. We need to copy it into old space in
  // that case.
  //
  // Exceptional return values currently cannot be pointers because we don't
  // have constant pointers.
  ASSERT(exceptional_return.IsNull() || exceptional_return.IsNumber() ||
         exceptional_return.IsBool());
  if (!exceptional_return.IsSmi() && exceptional_return.IsNew()) {
    function.SetFfiCallbackExceptionalReturn(Instance::Handle(
        zone, exceptional_return.CopyShallowToOldSpace(thread)));
  } else {
    function.SetFfiCallbackExceptionalReturn(exceptional_return);
  }

  // The dart type of the FfiCallback has no arguments or type arguments and
  // has a result type of dynamic, as the callback is never invoked via Dart,
  // only via native calls that do not use this information. Having no Dart
  // arguments ensures the scope builder does not add inappropriate parameter
  // variables.
  signature.set_result_type(Object::dynamic_type());
  // Finalize (and thus canonicalize) the signature.
  signature ^= ClassFinalizer::FinalizeType(signature);
  function.SetSignature(signature);

  {
    // Ensure only one thread updates the cache of deduped ffi trampoline
    // functions.
    auto isolate_group = thread->isolate_group();
    SafepointWriteRwLocker ml(thread, isolate_group->program_lock());

    auto object_store = isolate_group->object_store();
    if (object_store->ffi_callback_functions() == Array::null()) {
      FfiCallbackFunctionSet set(
          HashTables::New<FfiCallbackFunctionSet>(/*initial_capacity=*/4));
      object_store->set_ffi_callback_functions(set.Release());
    }
    FfiCallbackFunctionSet set(object_store->ffi_callback_functions());

    const intptr_t entry_count_before = set.NumOccupied();
    function ^= set.InsertOrGet(function);
    const intptr_t entry_count_after = set.NumOccupied();

    object_store->set_ffi_callback_functions(set.Release());

    if (entry_count_before != entry_count_after) {
      function.AssignFfiCallbackId(entry_count_before);
    } else {
      ASSERT(function.FfiCallbackId() != -1);
    }
  }

  return function.ptr();
}

static void EnsureFfiCallbackMetadata(Thread* thread, intptr_t callback_id) {
  static constexpr intptr_t kInitialCallbackIdsReserved = 16;

  auto object_store = thread->isolate_group()->object_store();
  auto zone = thread->zone();

  auto& code_array =
      GrowableObjectArray::Handle(zone, object_store->ffi_callback_code());
  if (code_array.IsNull()) {
    code_array =
        GrowableObjectArray::New(kInitialCallbackIdsReserved, Heap::kOld);
    object_store->set_ffi_callback_code(code_array);
  }
  if (code_array.Length() <= callback_id) {
    // Ensure we've enough space in the arrays.
    while (!(callback_id < code_array.Length())) {
      code_array.Add(Code::null_object());
    }
  }

  ASSERT(callback_id < code_array.Length());
}

void SetFfiCallbackCode(Thread* thread,
                        const Function& ffi_trampoline,
                        const Code& code) {
  auto zone = thread->zone();

  const intptr_t callback_id = ffi_trampoline.FfiCallbackId();
  EnsureFfiCallbackMetadata(thread, callback_id);

  auto object_store = thread->isolate_group()->object_store();
  const auto& code_array =
      GrowableObjectArray::Handle(zone, object_store->ffi_callback_code());
  code_array.SetAt(callback_id, code);
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

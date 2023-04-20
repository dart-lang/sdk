// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/bootstrap_natives.h"
#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/service_isolate.h"

namespace dart {

// Helper macros for declaring and defining native entries.
#define REGISTER_NATIVE_ENTRY(name, count)                                     \
  {"" #name, BootstrapNatives::DN_##name, count},

// List all native functions implemented in the vm or core bootstrap dart
// libraries so that we can resolve the native function to it's entry
// point.
static const struct NativeEntries {
  const char* name_;
  BootstrapNativeFunction function_;
  int argument_count_;
} BootStrapEntries[] = {BOOTSTRAP_NATIVE_LIST(REGISTER_NATIVE_ENTRY)
#if !defined(DART_PRECOMPILED_RUNTIME)
                            MIRRORS_BOOTSTRAP_NATIVE_LIST(REGISTER_NATIVE_ENTRY)
#endif  // !DART_PRECOMPILED_RUNTIME
};

#define REGISTER_FFI_NATIVE_ENTRY(name, return_type, argument_types)           \
  {"" #name, reinterpret_cast<void*>(BootstrapNatives::FN_##name)},

static const struct FfiNativeEntries {
  const char* name_;
  void* function_;
} BootStrapFfiEntries[] = {
    BOOTSTRAP_FFI_NATIVE_LIST(REGISTER_FFI_NATIVE_ENTRY)};

Dart_NativeFunction BootstrapNatives::Lookup(Dart_Handle name,
                                             int argument_count,
                                             bool* auto_setup_scope) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  const Object& obj = Object::Handle(thread->zone(), Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return nullptr;
  }
  ASSERT(auto_setup_scope);
  *auto_setup_scope = false;
  const char* function_name = obj.ToCString();
  ASSERT(function_name != nullptr);
  int num_entries = sizeof(BootStrapEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    const struct NativeEntries* entry = &(BootStrapEntries[i]);
    if ((strcmp(function_name, entry->name_) == 0) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return nullptr;
}

void* BootstrapNatives::LookupFfiNative(const char* name,
                                        uintptr_t argument_count) {
  int num_entries =
      sizeof(BootStrapFfiEntries) / sizeof(struct FfiNativeEntries);
  for (int i = 0; i < num_entries; i++) {
    const struct FfiNativeEntries* entry = &(BootStrapFfiEntries[i]);
    if (strcmp(name, entry->name_) == 0) {
      return entry->function_;
    }
  }
  return nullptr;
}

const uint8_t* BootstrapNatives::Symbol(Dart_NativeFunction nf) {
  int num_entries = sizeof(BootStrapEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    const struct NativeEntries* entry = &(BootStrapEntries[i]);
    if (reinterpret_cast<Dart_NativeFunction>(entry->function_) == nf) {
      return reinterpret_cast<const uint8_t*>(entry->name_);
    }
  }
  return nullptr;
}

void Bootstrap::SetupNativeResolver() {
  Library& library = Library::Handle();

  Dart_NativeEntryResolver resolver = BootstrapNatives::Lookup;

  Dart_FfiNativeResolver ffi_native_resolver =
      BootstrapNatives::LookupFfiNative;

  Dart_NativeEntrySymbol symbol_resolver = BootstrapNatives::Symbol;

  library = Library::AsyncLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::CollectionLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::ConvertLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::CoreLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::DeveloperLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::FfiLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::InternalLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);
  library.set_ffi_native_resolver(ffi_native_resolver);

  library = Library::IsolateLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::MathLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

#if !defined(DART_PRECOMPILED_RUNTIME)
  library = Library::MirrorsLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);
#endif

  library = Library::TypedDataLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::VMServiceLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);
}

bool Bootstrap::IsBootstrapResolver(Dart_NativeEntryResolver resolver) {
  return resolver == BootstrapNatives::Lookup;
}

}  // namespace dart

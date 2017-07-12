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
static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BootStrapEntries[] = {BOOTSTRAP_NATIVE_LIST(REGISTER_NATIVE_ENTRY)
#if !defined(DART_PRECOMPILED_RUNTIME)
                            MIRRORS_BOOTSTRAP_NATIVE_LIST(REGISTER_NATIVE_ENTRY)
#endif  // !DART_PRECOMPILED_RUNTIME
};


Dart_NativeFunction BootstrapNatives::Lookup(Dart_Handle name,
                                             int argument_count,
                                             bool* auto_setup_scope) {
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  ASSERT(auto_setup_scope);
  *auto_setup_scope = false;
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  int num_entries = sizeof(BootStrapEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BootStrapEntries[i]);
    if ((strcmp(function_name, entry->name_) == 0) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return NULL;
}


const uint8_t* BootstrapNatives::Symbol(Dart_NativeFunction* nf) {
  int num_entries = sizeof(BootStrapEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BootStrapEntries[i]);
    if (reinterpret_cast<Dart_NativeFunction*>(entry->function_) == nf) {
      return reinterpret_cast<const uint8_t*>(entry->name_);
    }
  }
  return NULL;
}


void Bootstrap::SetupNativeResolver() {
  Library& library = Library::Handle();

  Dart_NativeEntryResolver resolver =
      reinterpret_cast<Dart_NativeEntryResolver>(BootstrapNatives::Lookup);

  Dart_NativeEntrySymbol symbol_resolver =
      reinterpret_cast<Dart_NativeEntrySymbol>(BootstrapNatives::Symbol);

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

  library = Library::InternalLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

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

  library = Library::ProfilerLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::TypedDataLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);

  library = Library::VMServiceLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(resolver);
  library.set_native_entry_symbol_resolver(symbol_resolver);
}


bool Bootstrap::IsBootstapResolver(Dart_NativeEntryResolver resolver) {
  return (resolver ==
          reinterpret_cast<Dart_NativeEntryResolver>(BootstrapNatives::Lookup));
}

}  // namespace dart

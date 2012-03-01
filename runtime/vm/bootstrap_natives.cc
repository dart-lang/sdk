// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/bootstrap_natives.h"
#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

// List all native functions implemented in the vm or core bootstrap dart
// libraries so that we can resolve the native function to it's entry
// point.
static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BootStrapEntries[] = {
  BOOTSTRAP_NATIVE_LIST(REGISTER_NATIVE_ENTRY)
};


static Dart_NativeFunction NativeLookup(Dart_Handle name,
                                        int argument_count) {
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  int num_entries = sizeof(BootStrapEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BootStrapEntries[i]);
    if (!strncmp(function_name, entry->name_, strlen(entry->name_))) {
      if (entry->argument_count_ == argument_count) {
        return reinterpret_cast<Dart_NativeFunction>(entry->function_);
      } else {
        // Wrong number of arguments.
        // TODO(regis): Should we pass a buffer for error reporting?
        return NULL;
      }
    }
  }
  return NULL;
}


void Bootstrap::SetupNativeResolver() {
  Library& library = Library::Handle(Library::CoreLibrary());
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(
      reinterpret_cast<Dart_NativeEntryResolver>(NativeLookup));
  library = Library::CoreImplLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(
      reinterpret_cast<Dart_NativeEntryResolver>(NativeLookup));
}

}  // namespace dart

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/bootstrap_natives.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, print_bootstrap, false, "Print the bootstrap source.");

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


static Dart_NativeFunction native_lookup(Dart_Handle name,
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


RawScript* Bootstrap::LoadScript() {
  const String& url = String::Handle(String::New("bootstrap", Heap::kOld));
  const String& src = String::Handle(String::New(corelib_source_, Heap::kOld));

  const Script& result =
      Script::Handle(Script::New(url, src, RawScript::kSource));
  return result.raw();
}


RawScript* Bootstrap::LoadImplScript() {
  const String& url = String::Handle(String::New("bootstrap_impl",
                                                 Heap::kOld));
  const String& src = String::Handle(String::New(corelib_impl_source_,
                                                 Heap::kOld));

  const Script& result =
      Script::Handle(Script::New(url, src, RawScript::kSource));
  return result.raw();
}


void Bootstrap::Compile(const Library& library, const Script& script) {
  if (FLAG_print_bootstrap) {
    OS::Print("Bootstrap source '%s':\n%s\n",
        String::Handle(script.url()).ToCString(),
        String::Handle(script.source()).ToCString());
  }
  library.SetLoadInProgress();
  Compiler::Compile(library, script);
  library.SetLoaded();
}


void Bootstrap::SetupNativeResolver() {
  Library& library = Library::Handle(Library::CoreLibrary());
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(
      reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));
  library = Library::CoreImplLibrary();
  ASSERT(!library.IsNull());
  library.set_native_entry_resolver(
      reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));
}

}  // namespace dart

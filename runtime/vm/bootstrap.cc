// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, print_bootstrap, false, "Print the bootstrap source.");


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

}  // namespace dart

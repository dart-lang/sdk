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


RawScript* Bootstrap::LoadMathScript() {
  const String& url = String::Handle(String::New("dart:math", Heap::kOld));
  const String& src = String::Handle(String::New(math_source_, Heap::kOld));

  const Script& result =
      Script::Handle(Script::New(url, src, RawScript::kSource));
  return result.raw();
}


RawScript* Bootstrap::LoadIsolateScript()  {
  const String& url = String::Handle(String::New("dart:isolate", Heap::kOld));
  const String& src = String::Handle(String::New(isolate_source_, Heap::kOld));

  const Script& result =
      Script::Handle(Script::New(url, src, RawScript::kSource));
  return result.raw();
}


RawScript* Bootstrap::LoadMirrorsScript()  {
  const String& url = String::Handle(String::New("dart:mirrors", Heap::kOld));
  const String& src = String::Handle(String::New(mirrors_source_, Heap::kOld));

  const Script& result =
      Script::Handle(Script::New(url, src, RawScript::kSource));
  return result.raw();
}


RawError* Bootstrap::Compile(const Library& library, const Script& script) {
  if (FLAG_print_bootstrap) {
    OS::Print("Bootstrap source '%s':\n%s\n",
        String::Handle(script.url()).ToCString(),
        String::Handle(script.source()).ToCString());
  }
  library.SetLoadInProgress();
  const Error& error = Error::Handle(Compiler::Compile(library, script));
  if (error.IsNull()) {
    library.SetLoaded();
  } else {
    library.SetLoadError();
  }
  return error.raw();
}

}  // namespace dart

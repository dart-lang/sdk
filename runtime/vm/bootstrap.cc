// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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


RawScript* Bootstrap::LoadScript(const char* url,
                                 const char* source,
                                 bool patch) {
  return Script::New(String::Handle(String::New(url, Heap::kOld)),
                     String::Handle(String::New(source, Heap::kOld)),
                     patch ? RawScript::kPatchTag : RawScript::kSourceTag);
}


RawScript* Bootstrap::LoadCoreScript(bool patch) {
  // TODO(iposva): Use proper library name.
  const char* url = patch ? "dart:core-patch" : "bootstrap";
  const char* source = patch ? corelib_patch_ : corelib_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCoreImplScript(bool patch) {
  // TODO(iposva): Use proper library name.
  const char* url = patch ? "dart:coreimpl-patch" : "bootstrap_impl";
  const char* source = patch ? corelib_impl_patch_ : corelib_impl_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCollectionScript(bool patch) {
  const char* url = patch ? "dart:collection-patch" : "dart:collection";
  const char* source = patch ? collection_source_ : collection_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadMathScript(bool patch) {
  const char* url = patch ? "dart:math-patch" : "dart:math";
  const char* source = patch ? math_patch_ : math_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadIsolateScript(bool patch)  {
  const char* url = patch ? "dart:isolate-patch" : "dart:isolate";
  const char* source = patch ? isolate_patch_ : isolate_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadMirrorsScript(bool patch)  {
  const char* url = patch ? "dart:mirrors-patch" : "dart:mirrors";
  const char* source = patch ? mirrors_patch_ : mirrors_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadScalarlistScript(bool patch) {
  const char* url = patch ? "dart:scalarlist_patch" : "dart:scalarlist";
  const char* source = patch ? scalarlist_patch_ : scalarlist_source_;
  return LoadScript(url, source, patch);
}


RawError* Bootstrap::Compile(const Library& library, const Script& script) {
  if (FLAG_print_bootstrap) {
    OS::Print("Bootstrap source '%s':\n%s\n",
        String::Handle(script.url()).ToCString(),
        String::Handle(script.Source()).ToCString());
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

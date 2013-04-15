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
                     patch ? RawScript::kPatchTag : RawScript::kLibraryTag);
}


RawScript* Bootstrap::LoadAsyncScript(bool patch) {
  const char* url = patch ? "dart:async-patch" : "dart:async";
  const char* source = patch ? async_patch_ : async_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCoreScript(bool patch) {
  // TODO(iposva): Use proper library name.
  const char* url = patch ? "dart:core-patch" : "bootstrap";
  const char* source = patch ? corelib_patch_ : corelib_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCollectionScript(bool patch) {
  const char* url = patch ? "dart:collection-patch" : "dart:collection";
  const char* source = patch ? collection_patch_ : collection_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCollectionDevScript(bool patch) {
  const char* url =
      patch ? "dart:_collection-dev-patch" : "dart:_collection-dev";
  const char* source = patch ? collection_dev_patch_ : collection_dev_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadCryptoScript(bool patch) {
  const char* url = patch ? "dart:crypto-patch" : "dart:crypto";
  const char* source = patch ? crypto_source_ : crypto_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadIsolateScript(bool patch)  {
  const char* url = patch ? "dart:isolate-patch" : "dart:isolate";
  const char* source = patch ? isolate_patch_ : isolate_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadJsonScript(bool patch) {
  const char* url = patch ? "dart:json-patch" : "dart:json";
  const char* source = patch ? json_patch_ : json_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadMathScript(bool patch) {
  const char* url = patch ? "dart:math-patch" : "dart:math";
  const char* source = patch ? math_patch_ : math_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadMirrorsScript(bool patch)  {
  const char* url = patch ? "dart:mirrors-patch" : "dart:mirrors";
  const char* source = patch ? mirrors_patch_ : mirrors_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadTypedDataScript(bool patch) {
  const char* url = patch ? "dart:typeddata_patch" : "dart:typeddata";
  const char* source = patch ? typeddata_patch_ : typeddata_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadUriScript(bool patch) {
  const char* url = patch ? "dart:uri-patch" : "dart:uri";
  const char* source = patch ? uri_source_ : uri_source_;
  return LoadScript(url, source, patch);
}


RawScript* Bootstrap::LoadUtfScript(bool patch) {
  const char* url = patch ? "dart:utf-patch" : "dart:utf";
  const char* source = patch ? utf_source_ : utf_source_;
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

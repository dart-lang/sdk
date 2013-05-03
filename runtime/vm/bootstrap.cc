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
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, print_bootstrap, false, "Print the bootstrap source.");

#define INIT_LIBRARY(index, name, source, patch)                               \
  { index,                                                                     \
    "dart:"#name, source,                                                      \
    "dart:"#name"-patch", patch }                                              \

typedef struct {
  intptr_t index_;
  const char* uri_;
  const char* source_;
  const char* patch_uri_;
  const char* patch_source_;
} bootstrap_lib_props;


static bootstrap_lib_props bootstrap_libraries[] = {
  INIT_LIBRARY(ObjectStore::kCore,
               core,
               Bootstrap::corelib_source_,
               Bootstrap::corelib_patch_),
  INIT_LIBRARY(ObjectStore::kAsync,
               async,
               Bootstrap::async_source_,
               Bootstrap::async_patch_),
  INIT_LIBRARY(ObjectStore::kCollection,
               collection,
               Bootstrap::collection_source_,
               Bootstrap::collection_patch_),
  INIT_LIBRARY(ObjectStore::kCollectionDev,
               _collection-dev,
               Bootstrap::collection_dev_source_,
               Bootstrap::collection_dev_patch_),
  INIT_LIBRARY(ObjectStore::kCrypto,
               crypto,
               Bootstrap::crypto_source_,
               NULL),
  INIT_LIBRARY(ObjectStore::kIsolate,
               isolate,
               Bootstrap::isolate_source_,
               Bootstrap::isolate_patch_),
  INIT_LIBRARY(ObjectStore::kJson,
               json,
               Bootstrap::json_source_,
               Bootstrap::json_patch_),
  INIT_LIBRARY(ObjectStore::kMath,
               math,
               Bootstrap::math_source_,
               Bootstrap::math_patch_),
  INIT_LIBRARY(ObjectStore::kMirrors,
               mirrors,
               Bootstrap::mirrors_source_,
               Bootstrap::mirrors_patch_),
  INIT_LIBRARY(ObjectStore::kTypedData,
               typed_data,
               Bootstrap::typed_data_source_,
               Bootstrap::typed_data_patch_),
  INIT_LIBRARY(ObjectStore::kUtf,
               utf,
               Bootstrap::utf_source_,
               NULL),
  INIT_LIBRARY(ObjectStore::kUri,
               uri,
               Bootstrap::uri_source_,
               NULL),

  { ObjectStore::kNone, NULL, NULL, NULL, NULL }
};


static RawString* GetLibrarySource(intptr_t index, bool patch) {
  // TODO(asiva): Replace with actual read of the source file.
  const char* source = patch ? bootstrap_libraries[index].patch_source_ :
                               bootstrap_libraries[index].source_;
  ASSERT(source != NULL);
  return String::New(source, Heap::kOld);
}


static Dart_Handle LoadPartSource(Isolate* isolate,
                                  const Library& lib,
                                  const String& uri) {
  // TODO(asiva): For now we return an error here, once we start
  // loading libraries from the real source this would have to call the
  // file read callback here and invoke Compiler::Compile on it.
  return Dart_NewApiError("Unable to load source '%s' ", uri.ToCString());
}


static Dart_Handle BootstrapLibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle uri) {
  Isolate* isolate = Isolate::Current();
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(uri)) {
    return Dart_NewApiError("uri is not a string");
  }
  const String& uri_str = Api::UnwrapStringHandle(isolate, uri);
  ASSERT(!uri_str.IsNull());
  bool is_dart_scheme_uri = uri_str.StartsWith(Symbols::DartScheme());
  if (!is_dart_scheme_uri) {
    // The bootstrap tag handler can only handle dart scheme uris.
    return Dart_NewApiError("Do not know how to load '%s' ",
                            uri_str.ToCString());
  }
  if (tag == kCanonicalizeUrl) {
    // Dart Scheme URIs do not need any canonicalization.
    return uri;
  }
  if (tag == kImportTag) {
    // We expect the core bootstrap libraries to only import other
    // core bootstrap libraries.
    // We have precreated all the bootstrap library objects hence
    // we do not expect to be called back with the tag set to kImportTag.
    // The bootstrap process explicitly loads all the libraries one by one.
    return Dart_NewApiError("Invalid import of '%s' in a bootstrap library",
                            uri_str.ToCString());
  }
  ASSERT(tag == kSourceTag);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  ASSERT(!lib.IsNull());
  return LoadPartSource(isolate, lib, uri_str);
}


static RawError* Compile(const Library& library, const Script& script) {
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


RawError* Bootstrap::LoadandCompileScripts() {
  Isolate* isolate = Isolate::Current();
  String& uri = String::Handle();
  String& patch_uri = String::Handle();
  String& source = String::Handle();
  Script& script = Script::Handle();
  Library& lib = Library::Handle();
  Error& error = Error::Handle();
  Dart_LibraryTagHandler saved_tag_handler = isolate->library_tag_handler();

  // Set the library tag handler for the isolate to the bootstrap
  // library tag handler so that we can load all the bootstrap libraries.
  isolate->set_library_tag_handler(BootstrapLibraryTagHandler);

  // Enter the Dart Scope as we will be calling back into the library
  // tag handler when compiling the bootstrap libraries.
  Dart_EnterScope();

  // Create library objects for all the bootstrap libraries.
  intptr_t i = 0;
  while (bootstrap_libraries[i].index_ != ObjectStore::kNone) {
    uri = Symbols::New(bootstrap_libraries[i].uri_);
    lib = Library::LookupLibrary(uri);
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(uri, false);
      lib.Register();
    }
    isolate->object_store()->set_bootstrap_library(
        bootstrap_libraries[i].index_, lib);
    i = i + 1;
  }

  // Load and compile bootstrap libraries.
  i = 0;
  while (bootstrap_libraries[i].index_ != ObjectStore::kNone) {
    uri = Symbols::New(bootstrap_libraries[i].uri_);
    lib = Library::LookupLibrary(uri);
    ASSERT(!lib.IsNull());
    source = GetLibrarySource(i, false);
    script = Script::New(uri, source, RawScript::kLibraryTag);
    error = Compile(lib, script);
    if (!error.IsNull()) {
      break;
    }
    // If a patch exists, load and patch the script.
    if (bootstrap_libraries[i].patch_source_ != NULL) {
      patch_uri = String::New(bootstrap_libraries[i].patch_uri_,
                              Heap::kOld);
      source = GetLibrarySource(i, true);
      script = Script::New(patch_uri, source, RawScript::kPatchTag);
      error = lib.Patch(script);
      if (!error.IsNull()) {
        break;
      }
    }
    i = i + 1;
  }
  if (error.IsNull()) {
    SetupNativeResolver();
  }

  // Exit the Dart scope.
  Dart_ExitScope();

  // Restore the library tag handler for the isolate.
  isolate->set_library_tag_handler(saved_tag_handler);

  return error.raw();
}

}  // namespace dart

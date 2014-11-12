// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

#define INIT_LIBRARY(index, name, source, patch)                               \
  { index,                                                                     \
    "dart:"#name, source,                                                      \
    "dart:"#name"-patch", patch }                                              \

typedef struct {
  ObjectStore::BootstrapLibraryId index_;
  const char* uri_;
  const char** source_paths_;
  const char* patch_uri_;
  const char** patch_paths_;
} bootstrap_lib_props;


static bootstrap_lib_props bootstrap_libraries[] = {
  INIT_LIBRARY(ObjectStore::kCore,
               core,
               Bootstrap::core_source_paths_,
               Bootstrap::core_patch_paths_),
  INIT_LIBRARY(ObjectStore::kAsync,
               async,
               Bootstrap::async_source_paths_,
               Bootstrap::async_patch_paths_),
  INIT_LIBRARY(ObjectStore::kConvert,
               convert,
               Bootstrap::convert_source_paths_,
               Bootstrap::convert_patch_paths_),
  INIT_LIBRARY(ObjectStore::kCollection,
               collection,
               Bootstrap::collection_source_paths_,
               Bootstrap::collection_patch_paths_),
  INIT_LIBRARY(ObjectStore::kInternal,
               _internal,
               Bootstrap::_internal_source_paths_,
               Bootstrap::_internal_patch_paths_),
  INIT_LIBRARY(ObjectStore::kIsolate,
               isolate,
               Bootstrap::isolate_source_paths_,
               Bootstrap::isolate_patch_paths_),
  INIT_LIBRARY(ObjectStore::kMath,
               math,
               Bootstrap::math_source_paths_,
               Bootstrap::math_patch_paths_),
  INIT_LIBRARY(ObjectStore::kMirrors,
               mirrors,
               Bootstrap::mirrors_source_paths_,
               Bootstrap::mirrors_patch_paths_),
  INIT_LIBRARY(ObjectStore::kTypedData,
               typed_data,
               Bootstrap::typed_data_source_paths_,
               Bootstrap::typed_data_patch_paths_),

  INIT_LIBRARY(ObjectStore::kProfiler,
               profiler,
               Bootstrap::profiler_source_paths_,
               Bootstrap::profiler_patch_paths_),

  { ObjectStore::kNone, NULL, NULL, NULL, NULL }
};


static RawString* GetLibrarySource(const Library& lib,
                                   const String& uri,
                                   bool patch) {
  // First check if this is a valid boot strap library and find it's index
  // in the 'bootstrap_libraries' table above.
  intptr_t index;
  const String& lib_uri = String::Handle(lib.url());
  for (index = 0;
       bootstrap_libraries[index].index_ != ObjectStore::kNone;
       ++index) {
    if (lib_uri.Equals(bootstrap_libraries[index].uri_)) {
      break;
    }
  }
  if (bootstrap_libraries[index].index_ == ObjectStore::kNone) {
    return String::null();  // Library is not a boot strap library.
  }

  // Try to read the source using the path specified for the uri.
  const char** source_paths = patch ?
      bootstrap_libraries[index].patch_paths_ :
      bootstrap_libraries[index].source_paths_;
  if (source_paths == NULL) {
    return String::null();  // No path mapping information exists for library.
  }
  const char* source_path = NULL;
  for (intptr_t i = 0; source_paths[i] != NULL; i += 2) {
    if (uri.Equals(source_paths[i])) {
      source_path = source_paths[i + 1];
      break;
    }
  }
  if (source_path == NULL) {
    return String::null();  // Uri does not exist in path mapping information.
  }

  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileReadCallback file_read = Isolate::file_read_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  if (file_open == NULL || file_read == NULL || file_close == NULL) {
    return String::null();  // File operations are not supported.
  }

  void* stream = (*file_open)(source_path, false);
  if (stream == NULL) {
    return String::null();
  }

  const uint8_t* utf8_array = NULL;
  intptr_t file_length = -1;
  (*file_read)(&utf8_array, &file_length, stream);
  if (file_length == -1) {
    return String::null();
  }
  ASSERT(utf8_array != NULL);

  (*file_close)(stream);

  return String::FromUTF8(utf8_array, file_length);
}


static RawError* Compile(const Library& library, const Script& script) {
  bool update_lib_status = (script.kind() == RawScript::kScriptTag ||
                            script.kind() == RawScript::kLibraryTag);
  if (update_lib_status) {
    library.SetLoadInProgress();
  }
  const Error& error = Error::Handle(Compiler::Compile(library, script));
  if (update_lib_status) {
    if (error.IsNull()) {
      library.SetLoaded();
    } else {
      // Compilation errors are not Dart instances, so just mark the library
      // as having failed to load without providing an error instance.
      library.SetLoadError(Instance::Handle());
    }
  }
  return error.raw();
}


static Dart_Handle LoadPartSource(Isolate* isolate,
                                  const Library& lib,
                                  const String& uri) {
  const String& part_source = String::Handle(
      isolate, GetLibrarySource(lib, uri, false));
  const String& lib_uri = String::Handle(isolate, lib.url());
  if (part_source.IsNull()) {
    return Api::NewError("Unable to read part file '%s' of library '%s'",
                         uri.ToCString(), lib_uri.ToCString());
  }

  // Prepend the library URI to form a unique script URI for the part.
  const Array& strings = Array::Handle(isolate, Array::New(3));
  strings.SetAt(0, lib_uri);
  strings.SetAt(1, Symbols::Slash());
  strings.SetAt(2, uri);
  const String& part_uri = String::Handle(isolate, String::ConcatAll(strings));

  // Create a script object and compile the part.
  const Script& part_script = Script::Handle(
      isolate, Script::New(part_uri, part_source, RawScript::kSourceTag));
  const Error& error = Error::Handle(isolate, Compile(lib, part_script));
  return Api::NewHandle(isolate, error.raw());
}


static Dart_Handle BootstrapLibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle uri) {
  Isolate* isolate = Isolate::Current();
  if (!Dart_IsLibrary(library)) {
    return Api::NewError("not a library");
  }
  if (!Dart_IsString(uri)) {
    return Api::NewError("uri is not a string");
  }
  if (tag == Dart_kCanonicalizeUrl) {
    // In the bootstrap loader we do not try and do any canonicalization.
    return uri;
  }
  const String& uri_str = Api::UnwrapStringHandle(isolate, uri);
  ASSERT(!uri_str.IsNull());
  if (tag == Dart_kImportTag) {
    // We expect the core bootstrap libraries to only import other
    // core bootstrap libraries.
    // We have precreated all the bootstrap library objects hence
    // we do not expect to be called back with the tag set to kImportTag.
    // The bootstrap process explicitly loads all the libraries one by one.
    return Api::NewError("Invalid import of '%s' in a bootstrap library",
                         uri_str.ToCString());
  }
  ASSERT(tag == Dart_kSourceTag);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  ASSERT(!lib.IsNull());
  return LoadPartSource(isolate, lib, uri_str);
}


static RawError* LoadPatchFiles(Isolate* isolate,
                                const Library& lib,
                                const String& patch_uri,
                                const char** patch_files) {
  String& patch_file_uri = String::Handle(isolate);
  String& source = String::Handle(isolate);
  Script& script = Script::Handle(isolate);
  Error& error = Error::Handle(isolate);
  const Array& strings = Array::Handle(isolate, Array::New(3));
  strings.SetAt(0, patch_uri);
  strings.SetAt(1, Symbols::Slash());
  for (intptr_t j = 0; patch_files[j] != NULL; j += 2) {
    patch_file_uri = String::New(patch_files[j]);
    source = GetLibrarySource(lib, patch_file_uri, true);
    if (source.IsNull()) {
      return Api::UnwrapErrorHandle(
          isolate,
          Api::NewError("Unable to find dart patch source for %s",
                        patch_file_uri.ToCString())).raw();
    }
    // Prepend the patch library URI to form a unique script URI for the patch.
    strings.SetAt(2, patch_file_uri);
    patch_file_uri = String::ConcatAll(strings);
    script = Script::New(patch_file_uri, source, RawScript::kPatchTag);
    error = lib.Patch(script);
    if (!error.IsNull()) {
      return error.raw();
    }
  }
  return Error::null();
}


RawError* Bootstrap::LoadandCompileScripts() {
  Isolate* isolate = Isolate::Current();
  String& uri = String::Handle(isolate);
  String& patch_uri = String::Handle(isolate);
  String& source = String::Handle(isolate);
  Script& script = Script::Handle(isolate);
  Library& lib = Library::Handle(isolate);
  Error& error = Error::Handle(isolate);
  Dart_LibraryTagHandler saved_tag_handler = isolate->library_tag_handler();

  // Set the library tag handler for the isolate to the bootstrap
  // library tag handler so that we can load all the bootstrap libraries.
  isolate->set_library_tag_handler(BootstrapLibraryTagHandler);

  HANDLESCOPE(isolate);

  // Create library objects for all the bootstrap libraries.
  for (intptr_t i = 0;
       bootstrap_libraries[i].index_ != ObjectStore::kNone;
       ++i) {
    uri = Symbols::New(bootstrap_libraries[i].uri_);
    lib = Library::LookupLibrary(uri);
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(uri, false);
      lib.SetLoadRequested();
      lib.Register();
    }
    isolate->object_store()->set_bootstrap_library(
        bootstrap_libraries[i].index_, lib);
  }

  // Load, compile and patch bootstrap libraries.
  for (intptr_t i = 0;
       bootstrap_libraries[i].index_ != ObjectStore::kNone;
       ++i) {
    uri = Symbols::New(bootstrap_libraries[i].uri_);
    lib = Library::LookupLibrary(uri);
    ASSERT(!lib.IsNull());
    source = GetLibrarySource(lib, uri, false);
    if (source.IsNull()) {
      error ^= Api::UnwrapErrorHandle(
          isolate, Api::NewError("Unable to find dart source for %s",
                                 uri.ToCString())).raw();
      break;
    }
    script = Script::New(uri, source, RawScript::kLibraryTag);
    error = Compile(lib, script);
    if (!error.IsNull()) {
      break;
    }
    // If a patch exists, load and patch the script.
    if (bootstrap_libraries[i].patch_paths_ != NULL) {
      patch_uri = Symbols::New(bootstrap_libraries[i].patch_uri_);
      error = LoadPatchFiles(isolate,
                             lib,
                             patch_uri,
                             bootstrap_libraries[i].patch_paths_);
      if (!error.IsNull()) {
        break;
      }
    }
  }
  if (error.IsNull()) {
    SetupNativeResolver();
    ClassFinalizer::ProcessPendingClasses();

    Class& cls = Class::Handle(isolate);
    // Eagerly compile the function implementation class as it is the super
    // class of signature classes. This allows us to just finalize signature
    // classes without going through the hoops of trying to compile them.
    const Type& type =
        Type::Handle(isolate, isolate->object_store()->function_impl_type());
    cls = type.type_class();
    Compiler::CompileClass(cls);
  }

  // Restore the library tag handler for the isolate.
  isolate->set_library_tag_handler(saved_tag_handler);

  return error.raw();
}

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/kernel.h"
#include "vm/kernel_reader.h"
#endif
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool,
            use_corelib_source_files,
            kDefaultCorelibSourceFlag,
            "Attempt to use source files directly when loading in the core "
            "libraries during the bootstrap process");

struct BootstrapLibProps {
  ObjectStore::BootstrapLibraryId index;
  const char* uri;
  const char** source_paths;
  const char* patch_uri;
  const char** patch_paths;
};


enum {
  kPathsUriOffset = 0,
  kPathsFileOffset = 1,
  kPathsSourceOffset = 2,
  kPathsEntryLength = 3
};


const char** Bootstrap::profiler_patch_paths_ = NULL;
const char** Bootstrap::typed_data_patch_paths_ = NULL;


#define MAKE_PROPERTIES(CamelName, name)                                       \
  {ObjectStore::k##CamelName, "dart:" #name, Bootstrap::name##_source_paths_,  \
   "dart:" #name "-patch", Bootstrap::name##_patch_paths_},

static const BootstrapLibProps bootstrap_libraries[] = {
    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_PROPERTIES)};

#undef MAKE_PROPERTIES


static const intptr_t kBootstrapLibraryCount = ARRAY_SIZE(bootstrap_libraries);


static RawString* GetLibrarySourceByIndex(intptr_t index,
                                          const String& uri,
                                          bool patch) {
  ASSERT(index >= 0 && index < kBootstrapLibraryCount);

  // Try to read the source using the path specified for the uri.
  const char** source_paths = patch ? bootstrap_libraries[index].patch_paths
                                    : bootstrap_libraries[index].source_paths;
  if (source_paths == NULL) {
    return String::null();  // No path mapping information exists for library.
  }
  const char* source_path = NULL;
  const char* source_data = NULL;
  for (intptr_t i = 0; source_paths[i] != NULL; i += kPathsEntryLength) {
    if (uri.Equals(source_paths[i + kPathsUriOffset])) {
      source_path = source_paths[i + kPathsFileOffset];
      source_data = source_paths[i + kPathsSourceOffset];
      break;
    }
  }
  if ((source_path == NULL) && (source_data == NULL)) {
    return String::null();  // Uri does not exist in path mapping information.
  }

  const uint8_t* utf8_array = NULL;
  intptr_t file_length = -1;

  // If flag to use the core library files directly is specified then try
  // to read the file and extract it's contents otherwise just use the
  // source data that has been backed into the binary.
  if (FLAG_use_corelib_source_files) {
    Dart_FileOpenCallback file_open = Dart::file_open_callback();
    Dart_FileReadCallback file_read = Dart::file_read_callback();
    Dart_FileCloseCallback file_close = Dart::file_close_callback();
    if ((file_open != NULL) && (file_read != NULL) && (file_close != NULL)) {
      // Try to open and read the file.
      void* stream = (*file_open)(source_path, false);
      if (stream != NULL) {
        (*file_read)(&utf8_array, &file_length, stream);
        (*file_close)(stream);
      }
    }
  }
  if (file_length == -1) {
    if (source_data != NULL) {
      file_length = strlen(source_data);
      utf8_array = reinterpret_cast<const uint8_t*>(source_data);
    } else {
      return String::null();
    }
  }
  ASSERT(utf8_array != NULL);
  ASSERT(file_length >= 0);
  return String::FromUTF8(utf8_array, file_length);
}


static RawString* GetLibrarySource(const Library& lib,
                                   const String& uri,
                                   bool patch) {
  // First check if this is a valid bootstrap library and find its index in
  // the 'bootstrap_libraries' table above.
  intptr_t index;
  const String& lib_uri = String::Handle(lib.url());
  for (index = 0; index < kBootstrapLibraryCount; ++index) {
    if (lib_uri.Equals(bootstrap_libraries[index].uri)) {
      break;
    }
  }
  if (index == kBootstrapLibraryCount) {
    return String::null();  // The library is not a bootstrap library.
  }

  return GetLibrarySourceByIndex(index, uri, patch);
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
      library.SetLoadError(Object::null_instance());
    }
  }
  return error.raw();
}


static Dart_Handle LoadPartSource(Thread* thread,
                                  const Library& lib,
                                  const String& uri) {
  Zone* zone = thread->zone();
  const String& part_source =
      String::Handle(zone, GetLibrarySource(lib, uri, false));
  const String& lib_uri = String::Handle(zone, lib.url());
  if (part_source.IsNull()) {
    return Api::NewError("Unable to read part file '%s' of library '%s'",
                         uri.ToCString(), lib_uri.ToCString());
  }

  // Prepend the library URI to form a unique script URI for the part.
  const Array& strings = Array::Handle(zone, Array::New(3));
  strings.SetAt(0, lib_uri);
  strings.SetAt(1, Symbols::Slash());
  strings.SetAt(2, uri);
  const String& part_uri = String::Handle(zone, String::ConcatAll(strings));

  // Create a script object and compile the part.
  const Script& part_script = Script::Handle(
      zone, Script::New(part_uri, part_source, RawScript::kSourceTag));
  const Error& error = Error::Handle(zone, Compile(lib, part_script));
  return Api::NewHandle(thread, error.raw());
}


static Dart_Handle BootstrapLibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle uri) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // This handler calls into the VM directly and does not use the Dart
  // API so we transition back to VM.
  TransitionNativeToVM transition(thread);
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
  const String& uri_str = Api::UnwrapStringHandle(zone, uri);
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
  const Library& lib = Api::UnwrapLibraryHandle(zone, library);
  ASSERT(!lib.IsNull());
  return LoadPartSource(thread, lib, uri_str);
}


static RawError* LoadPatchFiles(Thread* thread,
                                const Library& lib,
                                intptr_t index) {
  const char** patch_files = bootstrap_libraries[index].patch_paths;
  if (patch_files == NULL) return Error::null();

  Zone* zone = thread->zone();
  String& patch_uri = String::Handle(
      zone, Symbols::New(thread, bootstrap_libraries[index].patch_uri));
  String& patch_file_uri = String::Handle(zone);
  String& source = String::Handle(zone);
  Script& script = Script::Handle(zone);
  Error& error = Error::Handle(zone);
  const Array& strings = Array::Handle(zone, Array::New(3));
  strings.SetAt(0, patch_uri);
  strings.SetAt(1, Symbols::Slash());
  for (intptr_t j = 0; patch_files[j] != NULL; j += kPathsEntryLength) {
    patch_file_uri = String::New(patch_files[j + kPathsUriOffset]);
    source = GetLibrarySourceByIndex(index, patch_file_uri, true);
    if (source.IsNull()) {
      const String& message = String::Handle(
          String::NewFormatted("Unable to find dart patch source for %s",
                               patch_file_uri.ToCString()));
      return ApiError::New(message);
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


static void Finish(Thread* thread, bool from_kernel) {
  Bootstrap::SetupNativeResolver();
  if (!ClassFinalizer::ProcessPendingClasses(from_kernel)) {
    FATAL("Error in class finalization during bootstrapping.");
  }

  // Eagerly compile the _Closure class as it is the class of all closure
  // instances. This allows us to just finalize function types without going
  // through the hoops of trying to compile their scope class.
  ObjectStore* object_store = thread->isolate()->object_store();
  Class& cls = Class::Handle(thread->zone(), object_store->closure_class());
  Compiler::CompileClass(cls);
  // Eagerly compile Bool class, bool constants are used from within compiler.
  cls = object_store->bool_class();
  Compiler::CompileClass(cls);
}


static RawError* BootstrapFromSource(Thread* thread) {
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& uri = String::Handle(zone);
  String& source = String::Handle(zone);
  Script& script = Script::Handle(zone);
  Library& lib = Library::Handle(zone);
  Error& error = Error::Handle(zone);

  // Set the library tag handler for the isolate to the bootstrap
  // library tag handler so that we can load all the bootstrap libraries.
  Dart_LibraryTagHandler saved_tag_handler = isolate->library_tag_handler();
  isolate->set_library_tag_handler(BootstrapLibraryTagHandler);

  // Load, compile and patch bootstrap libraries.
  for (intptr_t i = 0; i < kBootstrapLibraryCount; ++i) {
    ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
    uri = Symbols::New(thread, bootstrap_libraries[i].uri);
    lib = isolate->object_store()->bootstrap_library(id);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::LookupLibrary(thread, uri));
    source = GetLibrarySourceByIndex(i, uri, false);
    if (source.IsNull()) {
      const String& message = String::Handle(String::NewFormatted(
          "Unable to find dart source for %s", uri.ToCString()));
      error ^= ApiError::New(message);
      break;
    }
    script = Script::New(uri, source, RawScript::kLibraryTag);
    error = Compile(lib, script);
    if (!error.IsNull()) {
      break;
    }
    // If a patch exists, load and patch the script.
    error = LoadPatchFiles(thread, lib, i);
    if (!error.IsNull()) {
      break;
    }
  }

  if (error.IsNull()) {
    Finish(thread, /*from_kernel=*/false);
  }
  // Restore the library tag handler for the isolate.
  isolate->set_library_tag_handler(saved_tag_handler);

  return error.raw();
}


#if !defined(DART_PRECOMPILED_RUNTIME)
static RawError* BootstrapFromKernel(Thread* thread, kernel::Program* program) {
  Zone* zone = thread->zone();
  kernel::KernelReader reader(program);

  Isolate* isolate = thread->isolate();
  // Mark the already-pending classes.  This mark bit will be used to avoid
  // adding classes to the list more than once.
  GrowableObjectArray& pending_classes = GrowableObjectArray::Handle(
      zone, isolate->object_store()->pending_classes());
  dart::Class& pending = dart::Class::Handle(zone);
  for (intptr_t i = 0; i < pending_classes.Length(); ++i) {
    pending ^= pending_classes.At(i);
    pending.set_is_marked_for_parsing();
  }

  Library& library = Library::Handle(zone);
  String& dart_name = String::Handle(zone);
  String& kernel_name = String::Handle(zone);
  for (intptr_t i = 0; i < kBootstrapLibraryCount; ++i) {
    ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
    library = isolate->object_store()->bootstrap_library(id);
    dart_name = library.url();
    for (intptr_t j = 0; j < program->libraries().length(); ++j) {
      kernel::Library* kernel_library = program->libraries()[j];
      kernel::String* uri = kernel_library->import_uri();
      kernel_name = Symbols::FromUTF8(thread, uri->buffer(), uri->size());
      if (kernel_name.Equals(dart_name)) {
        reader.ReadLibrary(kernel_library);
        library.SetLoaded();
        break;
      }
    }
  }

  Finish(thread, /*from_kernel=*/true);
  return Error::null();
}
#else
static RawError* BootstrapFromKernel(Thread* thread, kernel::Program* program) {
  UNREACHABLE();
  return Error::null();
}
#endif


RawError* Bootstrap::DoBootstrapping(kernel::Program* kernel_program) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& uri = String::Handle(zone);
  Library& lib = Library::Handle(zone);

  HANDLESCOPE(thread);

  // Ensure there are library objects for all the bootstrap libraries.
  for (intptr_t i = 0; i < kBootstrapLibraryCount; ++i) {
    ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
    uri = Symbols::New(thread, bootstrap_libraries[i].uri);
    lib = isolate->object_store()->bootstrap_library(id);
    ASSERT(lib.raw() == Library::LookupLibrary(thread, uri));
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(uri, false);
      lib.SetLoadRequested();
      lib.Register(thread);
      isolate->object_store()->set_bootstrap_library(id, lib);
    }
  }

  return (kernel_program == NULL) ? BootstrapFromSource(thread)
                                  : BootstrapFromKernel(thread, kernel_program);
}

}  // namespace dart

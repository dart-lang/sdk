// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/log.h"

#include "platform/globals.h"


namespace dart {
namespace bin {

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    free(snapshot_buffer);                                                     \
    Log::PrintErr("Error: %s", Dart_GetError(result));                         \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    exit(255);                                                                 \
  }                                                                            \


// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
static const char* snapshot_filename = NULL;
static const char* package_root = NULL;
static uint8_t* snapshot_buffer = NULL;


// Global state which contains a pointer to the script name for which
// a snapshot needs to be created (NULL would result in the creation
// of a generic snapshot that contains only the corelibs).
static char* app_script_name = NULL;


// Global state that captures the URL mappings specified on the command line.
static CommandLineOptions* url_mapping = NULL;

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


static const char* ProcessOption(const char* option, const char* name) {
  const intptr_t length = strlen(name);
  if (strncmp(option, name, length) == 0) {
    return (option + length);
  }
  return NULL;
}


static bool ProcessSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--snapshot=");
  if (name != NULL) {
    snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessPackageRootOption(const char* option) {
  const char* name = ProcessOption(option, "--package_root=");
  if (name != NULL) {
    package_root = name;
    return true;
  }
  return false;
}


static bool ProcessURLmappingOption(const char* option) {
  const char* mapping = ProcessOption(option, "--url_mapping=");
  if (mapping == NULL) {
    mapping = ProcessOption(option, "--url-mapping=");
  }
  if (mapping != NULL) {
    url_mapping->AddArgument(mapping);
    return true;
  }
  return false;
}


// Parse out the command line arguments. Returns -1 if the arguments
// are incorrect, 0 otherwise.
static int ParseArguments(int argc,
                          char** argv,
                          CommandLineOptions* vm_options,
                          char** script_name) {
  const char* kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Skip the binary name.
  int i = 1;

  // Parse out the vm options.
  while ((i < argc) && IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
    if (ProcessSnapshotOption(argv[i]) ||
        ProcessURLmappingOption(argv[i]) ||
        ProcessPackageRootOption(argv[i])) {
      i += 1;
      continue;
    }
    vm_options->AddArgument(argv[i]);
    i += 1;
  }

  // Get the script name.
  if (i < argc) {
    *script_name = argv[i];
    i += 1;
  } else {
    *script_name = NULL;
  }

  if (snapshot_filename == NULL) {
    Log::PrintErr("No snapshot output file specified.\n\n");
    return -1;
  }

  return 0;
}


static void WriteSnapshotFile(const uint8_t* buffer, const intptr_t size) {
  File* file = File::Open(snapshot_filename, File::kWriteTruncate);
  ASSERT(file != NULL);
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Failed to write full snapshot.\n\n");
  }
  delete file;
}


class UriResolverIsolateScope {
 public:
  UriResolverIsolateScope() {
    ASSERT(isolate != NULL);
    snapshotted_isolate_ = Dart_CurrentIsolate();
    Dart_ExitIsolate();
    Dart_EnterIsolate(isolate);
    Dart_EnterScope();
  }

  ~UriResolverIsolateScope() {
    ASSERT(snapshotted_isolate_ != NULL);
    Dart_ExitScope();
    Dart_ExitIsolate();
    Dart_EnterIsolate(snapshotted_isolate_);
  }

  static Dart_Isolate isolate;

 private:
  Dart_Isolate snapshotted_isolate_;

  DISALLOW_COPY_AND_ASSIGN(UriResolverIsolateScope);
};

Dart_Isolate UriResolverIsolateScope::isolate = NULL;


static Dart_Handle ResolveScriptUri(const char* script_uri) {
  bool failed = false;
  char* result_string = NULL;

  {
    UriResolverIsolateScope scope;

    // Run DartUtils::ResolveScriptUri in context of uri resolver isolate.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    CHECK_RESULT(builtin_lib);

    Dart_Handle result = DartUtils::ResolveScriptUri(
        DartUtils::NewString(script_uri), builtin_lib);
    if (Dart_IsError(result)) {
      failed = true;
      result_string = strdup(Dart_GetError(result));
    } else {
      result_string = strdup(DartUtils::GetStringValue(result));
    }
  }

  Dart_Handle result = failed ? Dart_NewApiError(result_string) :
                                DartUtils::NewString(result_string);
  free(result_string);
  return result;
}


static Dart_Handle FilePathFromUri(const char* script_uri) {
  bool failed = false;
  char* result_string = NULL;

  {
    UriResolverIsolateScope scope;

    // Run DartUtils::FilePathFromUri in context of uri resolver isolate.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    CHECK_RESULT(builtin_lib);

    Dart_Handle result = DartUtils::FilePathFromUri(
        DartUtils::NewString(script_uri), builtin_lib);
    if (Dart_IsError(result)) {
      failed = true;
      result_string = strdup(Dart_GetError(result));
    } else {
      result_string = strdup(DartUtils::GetStringValue(result));
    }
  }

  Dart_Handle result = failed ? Dart_NewApiError(result_string) :
                                DartUtils::NewString(result_string);
  free(result_string);
  return result;
}


static Dart_Handle ResolveUri(const char* library_uri, const char* uri) {
  bool failed = false;
  char* result_string = NULL;

  {
    UriResolverIsolateScope scope;

    // Run DartUtils::ResolveUri in context of uri resolver isolate.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    CHECK_RESULT(builtin_lib);

    Dart_Handle result = DartUtils::ResolveUri(
        DartUtils::NewString(library_uri),
        DartUtils::NewString(uri),
        builtin_lib);
    if (Dart_IsError(result)) {
      failed = true;
      result_string = strdup(Dart_GetError(result));
    } else {
      result_string = strdup(DartUtils::GetStringValue(result));
    }
  }

  Dart_Handle result = failed ? Dart_NewApiError(result_string) :
                                DartUtils::NewString(result_string);
  free(result_string);
  return result;
}


static Builtin::BuiltinLibraryId BuiltinId(const char* url) {
  if (DartUtils::IsDartBuiltinLibURL(url)) {
    return Builtin::kBuiltinLibrary;
  }
  if (DartUtils::IsDartIOLibURL(url)) {
    return Builtin::kIOLibrary;
  }
  return Builtin::kInvalidLibrary;
}


static Dart_Handle CreateSnapshotLibraryTagHandler(Dart_LibraryTag tag,
                                                   Dart_Handle library,
                                                   Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  Dart_Handle library_url = Dart_LibraryUrl(library);
  if (Dart_IsError(library_url)) {
    return Dart_NewApiError("accessing library url failed");
  }
  const char* library_url_string = DartUtils::GetStringValue(library_url);
  const char* mapped_library_url_string = DartUtils::MapLibraryUrl(
      url_mapping, library_url_string);
  if (mapped_library_url_string != NULL) {
    library_url = ResolveScriptUri(mapped_library_url_string);
    library_url_string = DartUtils::GetStringValue(library_url);
  }

  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = DartUtils::GetStringValue(url);
  const char* mapped_url_string = DartUtils::MapLibraryUrl(url_mapping,
                                                           url_string);

  Builtin::BuiltinLibraryId libraryBuiltinId = BuiltinId(library_url_string);
  if (tag == Dart_kCanonicalizeUrl) {
    if (mapped_url_string) {
      return url;
    }
    // Parts of internal libraries are handled internally.
    if (libraryBuiltinId != Builtin::kInvalidLibrary) {
      return url;
    }
    return ResolveUri(library_url_string, url_string);
  }

  Builtin::BuiltinLibraryId builtinId = BuiltinId(url_string);
  if (builtinId != Builtin::kInvalidLibrary) {
    // Special case for importing a builtin library.
    if (tag == Dart_kImportTag) {
      return Builtin::LoadAndCheckLibrary(builtinId);
    }
    ASSERT(tag == Dart_kSourceTag);
    return DartUtils::NewError("Unable to part '%s' ", url_string);
  }

  if (libraryBuiltinId != Builtin::kInvalidLibrary) {
    // Special case for parting sources of a builtin library.
    if (tag == Dart_kSourceTag) {
      return Dart_LoadSource(library, url,
          Builtin::PartSource(libraryBuiltinId, url_string), 0, 0);
    }
    ASSERT(tag == Dart_kImportTag);
    return DartUtils::NewError("Unable to import '%s' ", url_string);
  }

  Dart_Handle resolved_url = url;
  if (mapped_url_string != NULL) {
    // Mapped urls are relative to working directory.
    resolved_url = ResolveScriptUri(mapped_url_string);
    if (Dart_IsError(resolved_url)) {
      return resolved_url;
    }
  }

  // Get the file path out of the url.
  Dart_Handle file_path = FilePathFromUri(
      DartUtils::GetStringValue(resolved_url));
  if (Dart_IsError(file_path)) {
    return file_path;
  }

  return DartUtils::LoadSource(library,
                               url,
                               tag,
                               DartUtils::GetStringValue(file_path));
}


static Dart_Handle LoadSnapshotCreationScript(const char* script_name) {
  Dart_Handle resolved_script_uri = ResolveScriptUri(script_name);
  if (Dart_IsError(resolved_script_uri)) {
    return resolved_script_uri;
  }
  Dart_Handle script_path = FilePathFromUri(
      DartUtils::GetStringValue(resolved_script_uri));
  if (Dart_IsError(script_path)) {
    return script_path;
  }
  Dart_Handle source = DartUtils::ReadStringFromFile(
      DartUtils::GetStringValue(script_path));
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadScript(resolved_script_uri, source, 0, 0);
}


static Dart_Handle LoadGenericSnapshotCreationScript(
    Builtin::BuiltinLibraryId id) {
  Dart_Handle source = Builtin::Source(id);
  if (Dart_IsError(source)) {
    return source;  // source contains the error string.
  }
  Dart_Handle lib;
  // Load the builtin library to make it available in the snapshot
  // for importing.
  lib = Builtin::LoadAndCheckLibrary(id);
  ASSERT(!Dart_IsError(lib));
  return lib;
}


static void PrintUsage() {
  Log::PrintErr(
"Usage:\n"
"\n"
"  gen_snapshot [<vm-flags>] [<options>] \\\n"
"               --snapshot=<out-file> [<dart-script-file>]\n"
"\n"
"  Writes a snapshot of <dart-script-file> to <out-file>. If no\n"
"  <dart-script-file> is passed, a generic snapshot of all the corelibs is\n"
"  created. It is required to specify an output file name:\n"
"\n"
"    --snapshot=<file>          Generates a complete snapshot. Uses the url\n"
"                               mapping specified on the command line to load\n"
"                               the libraries.\n"
"Supported options:\n"
"\n"
"--package_root=<path>\n"
"  Where to find packages, that is, \"package:...\" imports.\n"
"\n"
"--url_mapping=<mapping>\n"
"  Uses the URL mapping(s) specified on the command line to load the\n"
"  libraries. For use only with --snapshot=.\n");
}


static void VerifyLoaded(Dart_Handle library) {
  if (Dart_IsError(library)) {
    const char* err_msg = Dart_GetError(library);
    Log::PrintErr("Errors encountered while loading: %s\n", err_msg);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(255);
  }
  ASSERT(Dart_IsLibrary(library));
}


static void CreateAndWriteSnapshot() {
  Dart_Handle result;
  uint8_t* buffer = NULL;
  intptr_t size = 0;

  // First create a snapshot.
  result = Dart_CreateSnapshot(&buffer, &size);
  CHECK_RESULT(result);

  // Now write the snapshot out to specified file and exit.
  WriteSnapshotFile(buffer, size);
  Dart_ExitScope();

  // Shutdown the isolate.
  Dart_ShutdownIsolate();
}


static void SetupForUriResolution() {
  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  if (Dart_IsError(result)) {
    Log::PrintErr("%s", Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(255);
  }
  // This is a generic dart snapshot which needs builtin library setup.
  Dart_Handle library =
      LoadGenericSnapshotCreationScript(Builtin::kBuiltinLibrary);
  VerifyLoaded(library);
}


static void SetupForGenericSnapshotCreation() {
  SetupForUriResolution();

  Dart_Handle library = LoadGenericSnapshotCreationScript(Builtin::kIOLibrary);
  VerifyLoaded(library);
  Dart_Handle result = Dart_FinalizeLoading(false);
  if (Dart_IsError(result)) {
    const char* err_msg = Dart_GetError(library);
    Log::PrintErr("Errors encountered while loading: %s\n", err_msg);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(255);
  }
}


int main(int argc, char** argv) {
  CommandLineOptions vm_options(argc);

  // Initialize the URL mapping array.
  CommandLineOptions url_mapping_array(argc);
  url_mapping = &url_mapping_array;

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &app_script_name) < 0) {
    PrintUsage();
    return 255;
  }

  DartUtils::SetOriginalWorkingDirectory();

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  // Note: We don't expect isolates to be created from dart code during
  // snapshot generation.
  if (!Dart_Initialize(NULL, NULL, NULL, NULL,
                       DartUtils::OpenFile,
                       DartUtils::ReadFile,
                       DartUtils::WriteFile,
                       DartUtils::CloseFile,
                       DartUtils::EntropySource,
                       NULL)) {
    Log::PrintErr("VM initialization failed\n");
    return 255;
  }

  char* error;
  Dart_Isolate isolate = Dart_CreateIsolate(NULL, NULL, NULL, NULL, &error);
  if (isolate == NULL) {
    Log::PrintErr("Error: %s", error);
    free(error);
    exit(255);
  }

  Dart_Handle result;
  Dart_Handle library;
  Dart_EnterScope();

  ASSERT(snapshot_filename != NULL);
  // Load up the script before a snapshot is created.
  if (app_script_name != NULL) {
    // This is the case of a custom embedder (e.g: dartium) trying to
    // create a full snapshot. The current isolate is set up so that we can
    // invoke the dart uri resolution code like _resolveURI. App script is
    // loaded into a separate isolate.

    SetupForUriResolution();

    // Get handle to builtin library.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    CHECK_RESULT(builtin_lib);

    // Ensure that we mark all libraries as loaded.
    result = Dart_FinalizeLoading(false);
    CHECK_RESULT(result);

    // Prepare for script loading by setting up the 'print' and 'timer'
    // closures and setting up 'package root' for URI resolution.
    result = DartUtils::PrepareForScriptLoading(package_root, builtin_lib);
    CHECK_RESULT(result);
    Dart_ExitScope();

    UriResolverIsolateScope::isolate = isolate;

    // Now we create an isolate into which we load all the code that needs to
    // be in the snapshot.
    if (Dart_CreateIsolate(NULL, NULL, NULL, NULL, &error) == NULL) {
      fprintf(stderr, "%s", error);
      free(error);
      exit(255);
    }
    Dart_EnterScope();

    // Set up the library tag handler in such a manner that it will use the
    // URL mapping specified on the command line to load the libraries.
    result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
    CHECK_RESULT(result);
    // Load the specified script.
    library = LoadSnapshotCreationScript(app_script_name);
    VerifyLoaded(library);
    // Ensure that we mark all libraries as loaded.
    result = Dart_FinalizeLoading(false);
    CHECK_RESULT(result);
    CreateAndWriteSnapshot();

    Dart_EnterIsolate(UriResolverIsolateScope::isolate);
    Dart_ShutdownIsolate();
  } else {
    SetupForGenericSnapshotCreation();
    CreateAndWriteSnapshot();
  }
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  return dart::bin::main(argc, argv);
}

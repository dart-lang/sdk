// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <cstdarg>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"

#include "platform/globals.h"


namespace dart {
namespace bin {

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    Log::PrintErr("Error: %s", Dart_GetError(result));                         \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    exit(255);                                                                 \
  }                                                                            \


// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
static const char* vm_isolate_snapshot_filename = NULL;
static const char* isolate_snapshot_filename = NULL;
static const char* instructions_snapshot_filename = NULL;
static const char* embedder_entry_points_manifest = NULL;
static const char* package_root = NULL;


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


static bool ProcessVmIsolateSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--vm_isolate_snapshot=");
  if (name != NULL) {
    vm_isolate_snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessIsolateSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--isolate_snapshot=");
  if (name != NULL) {
    isolate_snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessInstructionsSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--instructions_snapshot=");
  if (name != NULL) {
    instructions_snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessEmbedderEntryPointsManifestOption(const char* option) {
  const char* name = ProcessOption(option, "--embedder_entry_points_manifest=");
  if (name != NULL) {
    embedder_entry_points_manifest = name;
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
    if (ProcessVmIsolateSnapshotOption(argv[i]) ||
        ProcessIsolateSnapshotOption(argv[i]) ||
        ProcessInstructionsSnapshotOption(argv[i]) ||
        ProcessEmbedderEntryPointsManifestOption(argv[i]) ||
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

  if (vm_isolate_snapshot_filename == NULL) {
    Log::PrintErr("No vm isolate snapshot output file specified.\n\n");
    return -1;
  }

  if (isolate_snapshot_filename == NULL) {
    Log::PrintErr("No isolate snapshot output file specified.\n\n");
    return -1;
  }

  if (instructions_snapshot_filename != NULL &&
      embedder_entry_points_manifest == NULL) {
    Log::PrintErr(
        "Specifying an instructions snapshot filename indicates precompilation"
        ". But no embedder entry points manifest was specified.\n\n");
    return -1;
  }

  if (embedder_entry_points_manifest != NULL &&
      instructions_snapshot_filename == NULL) {
    Log::PrintErr(
        "Specifying the embedder entry points manifest indicates "
        "precompilation. But no instuctions snapshot was specified.\n\n");
    return -1;
  }

  return 0;
}


static bool IsSnapshottingForPrecompilation(void) {
  return embedder_entry_points_manifest != NULL &&
         instructions_snapshot_filename != NULL;
}


static void WriteSnapshotFile(const char* filename,
                              const uint8_t* buffer,
                              const intptr_t size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  ASSERT(file != NULL);
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Failed to write snapshot file.\n\n");
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


static Dart_Handle ResolveUriInWorkingDirectory(const char* script_uri) {
  bool failed = false;
  char* result_string = NULL;

  {
    UriResolverIsolateScope scope;

    // Run DartUtils::ResolveUriInWorkingDirectory in context of uri resolver
    // isolate.
    Dart_Handle result = DartUtils::ResolveUriInWorkingDirectory(
        DartUtils::NewString(script_uri));
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
    Dart_Handle result = DartUtils::FilePathFromUri(
        DartUtils::NewString(script_uri));
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
    Dart_Handle result = DartUtils::ResolveUri(
        DartUtils::NewString(library_uri), DartUtils::NewString(uri));
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
    library_url = ResolveUriInWorkingDirectory(mapped_library_url_string);
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
  if ((builtinId != Builtin::kInvalidLibrary) && (mapped_url_string == NULL)) {
    // Special case for importing a builtin library that isn't remapped.
    if (tag == Dart_kImportTag) {
      return Builtin::LoadLibrary(url, builtinId);
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
    resolved_url = ResolveUriInWorkingDirectory(mapped_url_string);
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
  const char* raw_path = DartUtils::GetStringValue(file_path);
  Dart_Handle source = DartUtils::ReadStringFromFile(raw_path);
  if (Dart_IsError(source)) {
    return source;
  }
  if (tag == Dart_kImportTag) {
    return Dart_LoadLibrary(url, source, 0, 0);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, source, 0, 0);
  }
}


static Dart_Handle LoadSnapshotCreationScript(const char* script_name) {
  Dart_Handle resolved_script_uri = ResolveUriInWorkingDirectory(script_name);
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
  if (IsSnapshottingForPrecompilation()) {
    return Dart_LoadScript(resolved_script_uri, source, 0, 0);
  } else {
    return Dart_LoadLibrary(resolved_script_uri, source, 0, 0);
  }
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
"Usage:                                                                      \n"
" gen_snapshot [<vm-flags>] [<options>] [<dart-script-file>]                 \n"
"                                                                            \n"
"  Writes a snapshot of <dart-script-file> to the specified snapshot files.  \n"
"  If no <dart-script-file> is passed, a generic snapshot of all the corelibs\n"
"  is created. It is required to specify the VM isolate snapshot and the     \n"
"  isolate snapshot. The other flags are related to precompilation and are   \n"
"  optional.                                                                 \n"
"                                                                            \n"
"  Precompilation:                                                           \n"
"  In order to configure the snapshotter for precompilation, both the        \n"
"  instructions snapshot and embedder entry points manifest must be          \n"
"  specified. Assembly for the target architecture will be dumped into the   \n"
"  instructions snapshot. This must be linked into the target binary in a    \n"
"  separate step. The embedder entry points manifest lists the standalone    \n"
"  entry points into the VM. Not specifying these will cause the tree shaker \n"
"  to disregard the same as being used. The format of this manifest is as    \n"
"  follows. Each line in the manifest is a comma separated list of three     \n"
"  elements. The first entry is the library URI, the second entry is the     \n"
"  class name and the final entry the function name. The file must be        \n"
"  terminated with a newline charater.                                       \n"
"                                                                            \n"
"    Example:                                                                \n"
"      dart:something,SomeClass,doSomething                                  \n"
"                                                                            \n"
"  Supported options:                                                        \n"
"    --vm_isolate_snapshot=<file>      A full snapshot is a compact          \n"
"    --isolate_snapshot=<file>         representation of the dart vm isolate \n"
"                                      heap and dart isolate heap states.    \n"
"                                      Both these options are required       \n"
"                                                                            \n"
"    --package_root=<path>             Where to find packages, that is,      \n"
"                                      package:...  imports.                 \n"
"                                                                            \n"
"    --url_mapping=<mapping>           Uses the URL mapping(s) specified on  \n"
"                                      the command line to load the          \n"
"                                      libraries.                            \n"
"                                                                            \n"
"    --instructions_snapshot=<file>    (Precompilation only) Contains the    \n"
"                                      assembly that must be linked into     \n"
"                                      the target binary                     \n"
"                                                                            \n"
"    --embedder_entry_points_manifest=<file> (Precompilation only) Contains  \n"
"                                      the stanalone embedder entry points\n");
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


static const char StubNativeFunctionName[] = "StubNativeFunction";


void StubNativeFunction(Dart_NativeArguments arguments) {
  // This is a stub function for the resolver
  UNREACHABLE();
}


static Dart_NativeFunction StubNativeLookup(Dart_Handle name,
                                            int argument_count,
                                            bool* auto_setup_scope) {
  return &StubNativeFunction;
}


static const uint8_t* StubNativeSymbol(Dart_NativeFunction nf) {
  return reinterpret_cast<const uint8_t *>(StubNativeFunctionName);
}


static void SetupStubNativeResolver(size_t lib_index,
                                    const Dart_QualifiedFunctionName* entry) {
  // TODO(24686): Remove this.
  Dart_Handle library_string = Dart_NewStringFromCString(entry->library_uri);
  DART_CHECK_VALID(library_string);
  Dart_Handle library = Dart_LookupLibrary(library_string);
  // Embedder entry points may be setup in libraries that have not been
  // explicitly loaded by the application script. In such cases, library lookup
  // will fail. Manually load those libraries.
  if (Dart_IsError(library)) {
    static const uint32_t kLoadBufferMaxSize = 128;
    char* load_buffer =
        reinterpret_cast<char*>(calloc(kLoadBufferMaxSize, sizeof(char)));
    snprintf(load_buffer,
             kLoadBufferMaxSize,
             "import '%s';",
             DartUtils::GetStringValue(library_string));
    Dart_Handle script_handle = Dart_NewStringFromCString(load_buffer);
    memset(load_buffer, 0, kLoadBufferMaxSize);
    snprintf(load_buffer,
             kLoadBufferMaxSize,
             "dart:_snapshot_%zu",
             lib_index);
    Dart_Handle script_url = Dart_NewStringFromCString(load_buffer);
    free(load_buffer);
    Dart_Handle loaded = Dart_LoadLibrary(script_url, script_handle, 0, 0);
    DART_CHECK_VALID(loaded);

    // Do a fresh lookup
    library = Dart_LookupLibrary(library_string);
  }

  DART_CHECK_VALID(library);
  Dart_Handle result =  Dart_SetNativeResolver(library,
                                               &StubNativeLookup,
                                               &StubNativeSymbol);
  DART_CHECK_VALID(result);
}


static void ImportNativeEntryPointLibrariesIntoRoot(
    const Dart_QualifiedFunctionName* entries) {
  if (entries == NULL) {
    return;
  }

  size_t index = 0;
  while (true) {
    Dart_QualifiedFunctionName entry = entries[index++];
    if (entry.library_uri == NULL) {
      // The termination sentinel has null members.
      break;
    }
    Dart_Handle entry_library =
        Dart_LookupLibrary(Dart_NewStringFromCString(entry.library_uri));
    DART_CHECK_VALID(entry_library);
    Dart_Handle import_result = Dart_LibraryImportLibrary(
        entry_library, Dart_RootLibrary(), Dart_EmptyString());
    DART_CHECK_VALID(import_result);
  }
}


static void SetupStubNativeResolversForPrecompilation(
    const Dart_QualifiedFunctionName* entries) {

  if (entries == NULL) {
    return;
  }

  // Setup native resolvers for all libraries found in the manifest.
  size_t index = 0;
  while (true) {
    Dart_QualifiedFunctionName entry = entries[index++];
    if (entry.library_uri == NULL) {
      // The termination sentinel has null members.
      break;
    }
    // Setup stub resolvers on loaded libraries
    SetupStubNativeResolver(index, &entry);
  }
}


static void CleanupEntryPointItem(const Dart_QualifiedFunctionName *entry) {
  if (entry == NULL) {
    return;
  }
  // The allocation used for these entries is zero'ed. So even in error cases,
  // references to some entries will be null. Calling this on an already cleaned
  // up entry is programmer error.
  free(const_cast<char*>(entry->library_uri));
  free(const_cast<char*>(entry->class_name));
  free(const_cast<char*>(entry->function_name));
}


static void CleanupEntryPointsCollection(Dart_QualifiedFunctionName* entries) {
  if (entries == NULL) {
    return;
  }

  size_t index = 0;
  while (true) {
    Dart_QualifiedFunctionName entry = entries[index++];
    if (entry.library_uri == NULL) {
      break;
    }
    CleanupEntryPointItem(&entry);
  }
  free(entries);
}


char* ParserErrorStringCreate(const char* format, ...) {
  static const size_t kErrorBufferSize = 256;

  char* error_buffer =
      reinterpret_cast<char*>(calloc(kErrorBufferSize, sizeof(char)));
  va_list args;
  va_start(args, format);
  vsnprintf(error_buffer, kErrorBufferSize, format, args);
  va_end(args);

  // In case of error, the buffer is released by the caller
  return error_buffer;
}


const char* ParseEntryNameForIndex(uint8_t index) {
  switch (index) {
    case 0:
      return "Library";
    case 1:
      return "Class";
    case 2:
      return "Function";
    default:
      return "Unknown";
  }
  return NULL;
}


static bool ParseEntryPointsManifestSingleLine(
    const char* line, Dart_QualifiedFunctionName* entry, char** error) {
  bool success = true;
  size_t offset = 0;
  for (uint8_t i = 0; i < 3; i++) {
    const char* component = strchr(line + offset, i == 2 ? '\n' : ',');
    if (component == NULL) {
      success = false;
      *error = ParserErrorStringCreate(
          "Manifest entries must be comma separated and newline terminated. "
          "Could not parse '%s' on line '%s'",
          ParseEntryNameForIndex(i), line);
      break;
    }

    int64_t chars_read = component - (line + offset);
    if (chars_read <= 0) {
      success = false;
      *error =
          ParserErrorStringCreate("There is no '%s' specified on line '%s'",
                                  ParseEntryNameForIndex(i), line);
      break;
    }

    if (entry != NULL) {
      // These allocations are collected in |CleanupEntryPointsCollection|.
      char* entry_item =
          reinterpret_cast<char*>(calloc(chars_read + 1, sizeof(char)));
      memmove(entry_item, line + offset, chars_read);

      switch (i) {
        case 0:  // library
          entry->library_uri = entry_item;
          break;
        case 1:  // class
          entry->class_name = entry_item;
          break;
        case 2:  // function
          entry->function_name = entry_item;
          break;
        default:
          free(entry_item);
          success = false;
          *error = ParserErrorStringCreate("Internal parser error\n");
          break;
      }
    }

    offset += chars_read + 1;
  }
  return success;
}


int64_t ParseEntryPointsManifestLines(FILE* file,
                                      Dart_QualifiedFunctionName* collection) {
  int64_t entries = 0;

  static const int kManifestMaxLineLength = 1024;
  char* line = reinterpret_cast<char*>(malloc(kManifestMaxLineLength));
  size_t line_number = 0;
  while (true) {
    line_number++;
    char* read_line = fgets(line, kManifestMaxLineLength, file);

    if (read_line == NULL) {
      if ((feof(file) != 0) && (ferror(file) != 0)) {
        Log::PrintErr(
            "Error while reading line number %zu. The manifest must be "
            "terminated by a newline\n",
            line_number);
        entries = -1;
      }
      break;
    }

    Dart_QualifiedFunctionName* entry =
        collection != NULL ? collection + entries : NULL;

    char* error_buffer = NULL;
    if (!ParseEntryPointsManifestSingleLine(read_line, entry, &error_buffer)) {
      CleanupEntryPointItem(entry);
      Log::PrintErr("Parser error on line %zu: %s\n", line_number,
                    error_buffer);
      free(error_buffer);
      entries = -1;
      break;
    }

    entries++;
  }

  free(line);

  return entries;
}


static Dart_QualifiedFunctionName* ParseEntryPointsManifestFile(
    const char* path) {
  if (path == NULL) {
    return NULL;
  }

  FILE* file = fopen(path, "r");

  if (file == NULL) {
    Log::PrintErr("Could not open entry points manifest file\n");
    return NULL;
  }

  // Parse the file once but don't store the results. This is done to first
  // determine the number of entries in the manifest
  int64_t entry_count = ParseEntryPointsManifestLines(file, NULL);

  if (entry_count <= 0) {
    Log::PrintErr(
        "Manifest file specified is invalid or contained no entries\n");
    fclose(file);
    return NULL;
  }

  rewind(file);

  // Allocate enough storage for the entries in the file plus a termination
  // sentinel and parse it again to populate the allocation
  Dart_QualifiedFunctionName* entries =
      reinterpret_cast<Dart_QualifiedFunctionName*>(
          calloc(entry_count + 1, sizeof(Dart_QualifiedFunctionName)));

  int64_t parsed_entry_count = ParseEntryPointsManifestLines(file, entries);
  ASSERT(parsed_entry_count == entry_count);

  fclose(file);

  // The entries allocation must be explicitly cleaned up via
  // |CleanupEntryPointsCollection|
  return entries;
}


static Dart_QualifiedFunctionName* ParseEntryPointsManifestIfPresent() {
  Dart_QualifiedFunctionName* entries =
      ParseEntryPointsManifestFile(embedder_entry_points_manifest);
  if (entries == NULL && IsSnapshottingForPrecompilation()) {
    Log::PrintErr(
        "Could not find native embedder entry points during precompilation\n");
    exit(255);
  }
  return entries;
}


static void CreateAndWriteSnapshot() {
  ASSERT(!IsSnapshottingForPrecompilation());
  Dart_Handle result;
  uint8_t* vm_isolate_buffer = NULL;
  intptr_t vm_isolate_size = 0;
  uint8_t* isolate_buffer = NULL;
  intptr_t isolate_size = 0;

  // First create a snapshot.
  result = Dart_CreateSnapshot(&vm_isolate_buffer,
                               &vm_isolate_size,
                               &isolate_buffer,
                               &isolate_size);
  CHECK_RESULT(result);

  // Now write the vm isolate and isolate snapshots out to the
  // specified file and exit.
  WriteSnapshotFile(vm_isolate_snapshot_filename,
                    vm_isolate_buffer,
                    vm_isolate_size);
  WriteSnapshotFile(isolate_snapshot_filename,
                    isolate_buffer,
                    isolate_size);
  Dart_ExitScope();

  // Shutdown the isolate.
  Dart_ShutdownIsolate();
}


static void CreateAndWritePrecompiledSnapshot(
    Dart_QualifiedFunctionName* standalone_entry_points) {
  ASSERT(IsSnapshottingForPrecompilation());
  Dart_Handle result;
  uint8_t* vm_isolate_buffer = NULL;
  intptr_t vm_isolate_size = 0;
  uint8_t* isolate_buffer = NULL;
  intptr_t isolate_size = 0;
  uint8_t* instructions_buffer = NULL;
  intptr_t instructions_size = 0;

  // Precompile with specified embedder entry points
  result = Dart_Precompile(standalone_entry_points, true);
  CHECK_RESULT(result);

  // Create a precompiled snapshot. This gives us an instruction buffer with
  // machine code
  result = Dart_CreatePrecompiledSnapshot(&vm_isolate_buffer,
                                          &vm_isolate_size,
                                          &isolate_buffer,
                                          &isolate_size,
                                          &instructions_buffer,
                                          &instructions_size);
  CHECK_RESULT(result);

  // Now write the vm isolate, isolate and instructions snapshots out to the
  // specified files and exit.
  WriteSnapshotFile(vm_isolate_snapshot_filename,
                    vm_isolate_buffer,
                    vm_isolate_size);
  WriteSnapshotFile(isolate_snapshot_filename,
                    isolate_buffer,
                    isolate_size);
  WriteSnapshotFile(instructions_snapshot_filename,
                    instructions_buffer,
                    instructions_size);
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


static Dart_Isolate CreateServiceIsolate(const char* script_uri,
                                         const char* main,
                                         const char* package_root,
                                         const char* package_config,
                                         Dart_IsolateFlags* flags,
                                         void* data,
                                         char** error) {
  IsolateData* isolate_data = new IsolateData(script_uri,
                                              package_root,
                                              package_config);
  Dart_Isolate isolate = NULL;
  isolate = Dart_CreateIsolate(script_uri,
                               main,
                               NULL,
                               NULL,
                               isolate_data,
                               error);

  if (isolate == NULL) {
    Log::PrintErr("Error: Could not create service isolate");
    return NULL;
  }

  Dart_EnterScope();
  if (!Dart_IsServiceIsolate(isolate)) {
    Log::PrintErr("Error: We only expect to create the service isolate");
    return NULL;
  }
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  // Setup the native resolver.
  Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
  if (Dart_IsError(result)) {
    Log::PrintErr("Error: Could not set tag handler for service isolate");
    return NULL;
  }
  CHECK_RESULT(result);
  ASSERT(Dart_IsServiceIsolate(isolate));
  // Load embedder specific bits and return. Will not start http server.
  if (!VmService::Setup("127.0.0.1", -1, false /* running_precompiled */)) {
    *error = strdup(VmService::GetErrorMessage());
    return NULL;
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}


int main(int argc, char** argv) {
  const int EXTRA_VM_ARGUMENTS = 2;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);

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

  Thread::InitOnce();
  DartUtils::SetOriginalWorkingDirectory();
  // Start event handler.
  TimerUtils::InitOnce();
  EventHandler::Start();

#if !defined(PRODUCT)
  // Constant true in PRODUCT mode.
  vm_options.AddArgument("--load_deferred_eagerly");
#endif

  if (IsSnapshottingForPrecompilation()) {
    vm_options.AddArgument("--precompilation");
#if TARGET_ARCH_ARM
    // This is for the iPod Touch 5th Generation (and maybe other older devices)
    vm_options.AddArgument("--no-use_integer_division");
#endif
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  // Note: We don't expect isolates to be created from dart code during
  // snapshot generation.
  char* error = Dart_Initialize(
      NULL,
      NULL,
      NULL,
      CreateServiceIsolate,
      NULL,
      NULL,
      NULL,
      DartUtils::OpenFile,
      DartUtils::ReadFile,
      DartUtils::WriteFile,
      DartUtils::CloseFile,
      DartUtils::EntropySource,
      NULL);
  if (error != NULL) {
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return 255;
  }

  IsolateData* isolate_data = new IsolateData(NULL, NULL, NULL);
  Dart_Isolate isolate = Dart_CreateIsolate(
      NULL, NULL, NULL, NULL, isolate_data, &error);
  if (isolate == NULL) {
    Log::PrintErr("Error: %s", error);
    free(error);
    exit(255);
  }

  Dart_Handle result;
  Dart_Handle library;
  Dart_EnterScope();

  ASSERT(vm_isolate_snapshot_filename != NULL);
  ASSERT(isolate_snapshot_filename != NULL);
  // Load up the script before a snapshot is created.
  if (app_script_name != NULL) {
    // This is the case of a custom embedder (e.g: dartium) trying to
    // create a full snapshot. The current isolate is set up so that we can
    // invoke the dart uri resolution code like _resolveURI. App script is
    // loaded into a separate isolate.

    SetupForUriResolution();

    // Prepare builtin and its dependent libraries for use to resolve URIs.
    // Set up various closures, e.g: printing, timers etc.
    // Set up 'package root' for URI resolution.
    result = DartUtils::PrepareForScriptLoading(false, false);
    CHECK_RESULT(result);

    // Set up the load port provided by the service isolate so that we can
    // load scripts.
    result = DartUtils::SetupServiceLoadPort();
    CHECK_RESULT(result);

    // Setup package root if specified.
    result = DartUtils::SetupPackageRoot(package_root, NULL);
    CHECK_RESULT(result);

    Dart_ExitScope();
    Dart_ExitIsolate();

    UriResolverIsolateScope::isolate = isolate;

    // Now we create an isolate into which we load all the code that needs to
    // be in the snapshot.
    isolate_data = new IsolateData(NULL, NULL, NULL);
    if (Dart_CreateIsolate(
            NULL, NULL, NULL, NULL, isolate_data, &error) == NULL) {
      fprintf(stderr, "%s", error);
      free(error);
      exit(255);
    }
    Dart_EnterScope();

    // Set up the library tag handler in such a manner that it will use the
    // URL mapping specified on the command line to load the libraries.
    result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
    CHECK_RESULT(result);

    Dart_QualifiedFunctionName* entry_points =
        ParseEntryPointsManifestIfPresent();

    SetupStubNativeResolversForPrecompilation(entry_points);

    // Load the specified script.
    library = LoadSnapshotCreationScript(app_script_name);
    VerifyLoaded(library);

    ImportNativeEntryPointLibrariesIntoRoot(entry_points);

    // Ensure that we mark all libraries as loaded.
    result = Dart_FinalizeLoading(false);
    CHECK_RESULT(result);

    if (entry_points == NULL) {
      ASSERT(!IsSnapshottingForPrecompilation());
      CreateAndWriteSnapshot();
    } else {
      CreateAndWritePrecompiledSnapshot(entry_points);
    }

    CleanupEntryPointsCollection(entry_points);

    Dart_EnterIsolate(UriResolverIsolateScope::isolate);
    Dart_ShutdownIsolate();
  } else {
    SetupForGenericSnapshotCreation();
    CreateAndWriteSnapshot();
  }
  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  EventHandler::Stop();
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  return dart::bin::main(argc, argv);
}

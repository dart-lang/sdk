// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cstdarg>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/loader.h"
#include "bin/log.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

#include "platform/hashmap.h"
#include "platform/globals.h"
#include "platform/growable_array.h"

namespace dart {
namespace bin {

DFE dfe;

// Exit code indicating an API error.
static const int kApiErrorExitCode = 253;
// Exit code indicating a compilation error.
static const int kCompilationErrorExitCode = 254;
// Exit code indicating an unhandled error that is not a compilation error.
static const int kErrorExitCode = 255;

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    intptr_t exit_code = 0;                                                    \
    Log::PrintErr("Error: %s\n", Dart_GetError(result));                       \
    if (Dart_IsCompilationError(result)) {                                     \
      exit_code = kCompilationErrorExitCode;                                   \
    } else if (Dart_IsApiError(result)) {                                      \
      exit_code = kApiErrorExitCode;                                           \
    } else {                                                                   \
      exit_code = kErrorExitCode;                                              \
    }                                                                          \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    exit(exit_code);                                                           \
  }


// The core snapshot to use when creating isolates. Normally NULL, but loaded
// from a file when creating script snapshots.
const uint8_t* isolate_snapshot_data = NULL;
const uint8_t* isolate_snapshot_instructions = NULL;


// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
enum SnapshotKind {
  kCore,
  kCoreJIT,
  kScript,
  kAppAOTBlobs,
  kAppAOTAssembly,
};
static SnapshotKind snapshot_kind = kCore;
static const char* vm_snapshot_data_filename = NULL;
static const char* vm_snapshot_instructions_filename = NULL;
static const char* isolate_snapshot_data_filename = NULL;
static const char* isolate_snapshot_instructions_filename = NULL;
static const char* assembly_filename = NULL;
static const char* script_snapshot_filename = NULL;
static bool dependencies_only = false;
static bool print_dependencies = false;
static const char* dependencies_filename = NULL;


// Value of the --load-compilation-trace flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* load_compilation_trace_filename = NULL;

// Value of the --package-root flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* commandline_package_root = NULL;

// Value of the --packages flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* commandline_packages_file = NULL;


// Global state which contains a pointer to the script name for which
// a snapshot needs to be created (NULL would result in the creation
// of a generic snapshot that contains only the corelibs).
static char* app_script_name = NULL;

// Global state that captures the entry point manifest files specified on the
// command line.
static CommandLineOptions* entry_points_files = NULL;

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


// The environment provided through the command line using -D options.
static dart::HashMap* environment = NULL;

static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}

static bool ProcessEnvironmentOption(const char* arg) {
  ASSERT(arg != NULL);
  if (*arg == '\0') {
    return false;
  }
  if (*arg != '-') {
    return false;
  }
  if (*(arg + 1) != 'D') {
    return false;
  }
  arg = arg + 2;
  if (*arg == '\0') {
    return true;
  }
  if (environment == NULL) {
    environment = new HashMap(&HashMap::SameStringValue, 4);
  }
  // Split the name=value part of the -Dname=value argument.
  char* name;
  char* value = NULL;
  const char* equals_pos = strchr(arg, '=');
  if (equals_pos == NULL) {
    // No equal sign (name without value) currently not supported.
    Log::PrintErr("No value given to -D option\n");
    return false;
  } else {
    int name_len = equals_pos - arg;
    if (name_len == 0) {
      Log::PrintErr("No name given to -D option\n");
      return false;
    }
    // Split name=value into name and value.
    name = reinterpret_cast<char*>(malloc(name_len + 1));
    strncpy(name, arg, name_len);
    name[name_len] = '\0';
    value = strdup(equals_pos + 1);
  }
  HashMap::Entry* entry = environment->Lookup(GetHashmapKeyFromString(name),
                                              HashMap::StringHash(name), true);
  ASSERT(entry != NULL);  // Lookup adds an entry if key not found.
  entry->value = value;
  return true;
}


static Dart_Handle EnvironmentCallback(Dart_Handle name) {
  uint8_t* utf8_array;
  intptr_t utf8_len;
  Dart_Handle result = Dart_Null();
  Dart_Handle handle = Dart_StringToUTF8(name, &utf8_array, &utf8_len);
  if (Dart_IsError(handle)) {
    handle = Dart_ThrowException(
        DartUtils::NewDartArgumentError(Dart_GetError(handle)));
  } else {
    char* name_chars = reinterpret_cast<char*>(malloc(utf8_len + 1));
    memmove(name_chars, utf8_array, utf8_len);
    name_chars[utf8_len] = '\0';
    const char* value = NULL;
    if (environment != NULL) {
      HashMap::Entry* entry =
          environment->Lookup(GetHashmapKeyFromString(name_chars),
                              HashMap::StringHash(name_chars), false);
      if (entry != NULL) {
        value = reinterpret_cast<char*>(entry->value);
      }
    }
    if (value != NULL) {
      result = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(value),
                                      strlen(value));
    }
    free(name_chars);
  }
  return result;
}


static const char* ProcessOption(const char* option, const char* name) {
  const intptr_t length = strlen(name);
  if (strncmp(option, name, length) == 0) {
    return (option + length);
  }
  return NULL;
}


static bool ProcessSnapshotKindOption(const char* option) {
  const char* kind = ProcessOption(option, "--snapshot_kind=");
  if (kind == NULL) {
    kind = ProcessOption(option, "--snapshot-kind=");
  }
  if (kind == NULL) {
    return false;
  }
  if (strcmp(kind, "core-jit") == 0) {
    snapshot_kind = kCoreJIT;
    return true;
  } else if (strcmp(kind, "core") == 0) {
    snapshot_kind = kCore;
    return true;
  } else if (strcmp(kind, "script") == 0) {
    snapshot_kind = kScript;
    return true;
  } else if (strcmp(kind, "app-aot-blobs") == 0) {
    snapshot_kind = kAppAOTBlobs;
    return true;
  } else if (strcmp(kind, "app-aot-assembly") == 0) {
    snapshot_kind = kAppAOTAssembly;
    return true;
  }
  Log::PrintErr(
      "Unrecognized snapshot kind: '%s'\nValid kinds are: "
      "core, script, app-aot-blobs, app-aot-assembly\n",
      kind);
  return false;
}


static bool ProcessVmSnapshotDataOption(const char* option) {
  const char* name = ProcessOption(option, "--vm_snapshot_data=");
  if (name == NULL) {
    name = ProcessOption(option, "--vm-snapshot-data=");
  }
  if (name != NULL) {
    vm_snapshot_data_filename = name;
    return true;
  }
  return false;
}


static bool ProcessVmSnapshotInstructionsOption(const char* option) {
  const char* name = ProcessOption(option, "--vm_snapshot_instructions=");
  if (name == NULL) {
    name = ProcessOption(option, "--vm-snapshot-instructions=");
  }
  if (name != NULL) {
    vm_snapshot_instructions_filename = name;
    return true;
  }
  return false;
}


static bool ProcessIsolateSnapshotDataOption(const char* option) {
  const char* name = ProcessOption(option, "--isolate_snapshot_data=");
  if (name == NULL) {
    name = ProcessOption(option, "--isolate-snapshot-data=");
  }
  if (name != NULL) {
    isolate_snapshot_data_filename = name;
    return true;
  }
  return false;
}


static bool ProcessIsolateSnapshotInstructionsOption(const char* option) {
  const char* name = ProcessOption(option, "--isolate_snapshot_instructions=");
  if (name == NULL) {
    name = ProcessOption(option, "--isolate-snapshot-instructions=");
  }
  if (name != NULL) {
    isolate_snapshot_instructions_filename = name;
    return true;
  }
  return false;
}


static bool ProcessAssemblyOption(const char* option) {
  const char* name = ProcessOption(option, "--assembly=");
  if (name != NULL) {
    assembly_filename = name;
    return true;
  }
  return false;
}


static bool ProcessScriptSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--script_snapshot=");
  if (name == NULL) {
    name = ProcessOption(option, "--script-snapshot=");
  }
  if (name != NULL) {
    script_snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessDependenciesOption(const char* option) {
  const char* name = ProcessOption(option, "--dependencies=");
  if (name != NULL) {
    dependencies_filename = name;
    return true;
  }
  return false;
}


static bool ProcessDependenciesOnlyOption(const char* option) {
  const char* name = ProcessOption(option, "--dependencies_only");
  if (name == NULL) {
    name = ProcessOption(option, "--dependencies-only");
  }
  if (name != NULL) {
    dependencies_only = true;
    return true;
  }
  return false;
}

static bool ProcessPrintDependenciesOption(const char* option) {
  const char* name = ProcessOption(option, "--print_dependencies");
  if (name == NULL) {
    name = ProcessOption(option, "--print-dependencies");
  }
  if (name != NULL) {
    print_dependencies = true;
    return true;
  }
  return false;
}

static bool ProcessEmbedderEntryPointsManifestOption(const char* option) {
  const char* name = ProcessOption(option, "--embedder_entry_points_manifest=");
  if (name != NULL) {
    entry_points_files->AddArgument(name);
    return true;
  }
  return false;
}


static bool ProcessLoadCompilationTraceOption(const char* option) {
  const char* name = ProcessOption(option, "--load_compilation_trace=");
  if (name != NULL) {
    load_compilation_trace_filename = name;
    return true;
  }
  return false;
}


static bool ProcessPackageRootOption(const char* option) {
  const char* name = ProcessOption(option, "--package_root=");
  if (name == NULL) {
    name = ProcessOption(option, "--package-root=");
  }
  if (name != NULL) {
    commandline_package_root = name;
    return true;
  }
  return false;
}


static bool ProcessPackagesOption(const char* option) {
  const char* name = ProcessOption(option, "--packages=");
  if (name != NULL) {
    commandline_packages_file = name;
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
    DartUtils::url_mapping->AddArgument(mapping);
    return true;
  }
  return false;
}


static bool IsSnapshottingForPrecompilation() {
  return (snapshot_kind == kAppAOTBlobs) || (snapshot_kind == kAppAOTAssembly);
}


// Parse out the command line arguments. Returns -1 if the arguments
// are incorrect, 0 otherwise.
static int ParseArguments(int argc,
                          char** argv,
                          CommandLineOptions* vm_options,
                          char** script_name) {
  const char* kPrefix = "-";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Skip the binary name.
  int i = 1;

  // Parse out the vm options.
  while ((i < argc) && IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
    if (ProcessSnapshotKindOption(argv[i]) ||
        ProcessVmSnapshotDataOption(argv[i]) ||
        ProcessVmSnapshotInstructionsOption(argv[i]) ||
        ProcessIsolateSnapshotDataOption(argv[i]) ||
        ProcessIsolateSnapshotInstructionsOption(argv[i]) ||
        ProcessAssemblyOption(argv[i]) ||
        ProcessScriptSnapshotOption(argv[i]) ||
        ProcessDependenciesOption(argv[i]) ||
        ProcessDependenciesOnlyOption(argv[i]) ||
        ProcessPrintDependenciesOption(argv[i]) ||
        ProcessEmbedderEntryPointsManifestOption(argv[i]) ||
        ProcessURLmappingOption(argv[i]) ||
        ProcessLoadCompilationTraceOption(argv[i]) ||
        ProcessPackageRootOption(argv[i]) || ProcessPackagesOption(argv[i]) ||
        ProcessEnvironmentOption(argv[i])) {
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

  // Verify consistency of arguments.
  if ((commandline_package_root != NULL) &&
      (commandline_packages_file != NULL)) {
    Log::PrintErr(
        "Specifying both a packages directory and a packages "
        "file is invalid.\n\n");
    return -1;
  }

  switch (snapshot_kind) {
    case kCore: {
      if ((vm_snapshot_data_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL)) {
        Log::PrintErr(
            "Building a core snapshot requires specifying output files for "
            "--vm_snapshot_data and --isolate_snapshot_data.\n\n");
        return -1;
      }
      break;
    }
    case kCoreJIT: {
      if ((vm_snapshot_data_filename == NULL) ||
          (vm_snapshot_instructions_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL) ||
          (isolate_snapshot_instructions_filename == NULL)) {
        Log::PrintErr(
            "Building a core JIT snapshot requires specifying output "
            "files for --vm_snapshot_data, --vm_snapshot_instructions, "
            "--isolate_snapshot_data and --isolate_snapshot_instructions.\n\n");
        return -1;
      }
      break;
    }
    case kScript: {
      if ((vm_snapshot_data_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL) ||
          (script_snapshot_filename == NULL) || (*script_name == NULL)) {
        Log::PrintErr(
            "Building a script snapshot requires specifying input files for "
            "--vm_snapshot_data and --isolate_snapshot_data, an output file "
            "for --script_snapshot, and a Dart script.\n\n");
        return -1;
      }
      break;
    }
    case kAppAOTBlobs: {
      if ((vm_snapshot_data_filename == NULL) ||
          (vm_snapshot_instructions_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL) ||
          (isolate_snapshot_instructions_filename == NULL) ||
          (*script_name == NULL)) {
        Log::PrintErr(
            "Building an AOT snapshot as blobs requires specifying output "
            "files for --vm_snapshot_data, --vm_snapshot_instructions, "
            "--isolate_snapshot_data and --isolate_snapshot_instructions and a "
            "Dart script.\n\n");
        return -1;
      }
      break;
    }
    case kAppAOTAssembly: {
      if ((assembly_filename == NULL) || (*script_name == NULL)) {
        Log::PrintErr(
            "Building an AOT snapshot as assembly requires specifying "
            "an output file for --assembly and a Dart script.\n\n");
        return -1;
      }
      break;
    }
  }

  if (IsSnapshottingForPrecompilation() && (entry_points_files->count() == 0)) {
    Log::PrintErr(
        "Building an AOT snapshot requires at least one embedder "
        "entry points manifest.\n\n");
    return -1;
  }

  return 0;
}


static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  if (file == NULL) {
    Log::PrintErr("Error: Unable to write snapshot file: %s\n\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Unable to write snapshot file: %s\n\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  file->Release();
}


static void ReadFile(const char* filename, uint8_t** buffer, intptr_t* size) {
  File* file = File::Open(filename, File::kRead);
  if (file == NULL) {
    Log::PrintErr("Unable to open file %s\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  *size = file->Length();
  *buffer = reinterpret_cast<uint8_t*>(malloc(*size));
  if (!file->ReadFully(*buffer, *size)) {
    Log::PrintErr("Unable to read file %s\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  file->Release();
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


static void AddDependency(const char* uri_string) {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
  if (dependencies != NULL) {
    dependencies->Add(strdup(uri_string));
  }
}


static Dart_Handle LoadUrlContents(const char* uri_string) {
  bool failed = false;
  char* error_string = NULL;
  uint8_t* payload = NULL;
  intptr_t payload_length = 0;
  // Switch to the UriResolver Isolate and load the script.
  {
    UriResolverIsolateScope scope;

    Dart_Handle resolved_uri = Dart_NewStringFromCString(uri_string);
    Dart_Handle result =
        Loader::LoadUrlContents(resolved_uri, &payload, &payload_length);
    if (Dart_IsError(result)) {
      failed = true;
      error_string = strdup(Dart_GetError(result));
    }
  }
  AddDependency(uri_string);
  // Switch back to the isolate from which we generate the snapshot and
  // create the source string for the specified uri.
  Dart_Handle result;
  if (!failed) {
    result = Dart_NewStringFromUTF8(payload, payload_length);
    free(payload);
  } else {
    result = Dart_NewApiError(error_string);
    free(error_string);
  }
  return result;
}


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

  Dart_Handle result = failed ? Dart_NewApiError(result_string)
                              : DartUtils::NewString(result_string);
  free(result_string);
  return result;
}


static Dart_Handle LoadSnapshotCreationScript(const char* script_name) {
  // First resolve the specified script uri with respect to the original
  // working directory.
  Dart_Handle resolved_uri = ResolveUriInWorkingDirectory(script_name);
  if (Dart_IsError(resolved_uri)) {
    return resolved_uri;
  }
  // Now load the contents of the specified uri.
  const char* resolved_uri_string = DartUtils::GetStringValue(resolved_uri);
  Dart_Handle source = LoadUrlContents(resolved_uri_string);

  if (Dart_IsError(source)) {
    return source;
  }
  if (snapshot_kind == kCore) {
    return Dart_LoadLibrary(resolved_uri, Dart_Null(), source, 0, 0);
  } else {
    return Dart_LoadScript(resolved_uri, Dart_Null(), source, 0, 0);
  }
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


static void CreateAndWriteDependenciesFile() {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
  if (dependencies == NULL) {
    return;
  }

  Loader::ResolveDependenciesAsFilePaths();

  ASSERT((dependencies_filename != NULL) || print_dependencies);
  bool success = true;
  File* file = NULL;
  if (dependencies_filename != NULL) {
    file = File::Open(dependencies_filename, File::kWriteTruncate);
    if (file == NULL) {
      Log::PrintErr("Error: Unable to open dependencies file: %s\n\n",
                    dependencies_filename);
      exit(kErrorExitCode);
    }

    // Targets:
    switch (snapshot_kind) {
      case kCore:
        success &= file->Print("%s ", vm_snapshot_data_filename);
        success &= file->Print("%s ", isolate_snapshot_data_filename);
        break;
      case kScript:
        success &= file->Print("%s ", script_snapshot_filename);
        break;
      case kAppAOTAssembly:
        success &= file->Print("%s ", assembly_filename);
        break;
      case kCoreJIT:
      case kAppAOTBlobs:
        success &= file->Print("%s ", vm_snapshot_data_filename);
        success &= file->Print("%s ", vm_snapshot_instructions_filename);
        success &= file->Print("%s ", isolate_snapshot_data_filename);
        success &= file->Print("%s ", isolate_snapshot_instructions_filename);
        break;
    }

    success &= file->Print(": ");
  }

  // Sources:
  if (snapshot_kind == kScript) {
    if (dependencies_filename != NULL) {
      success &= file->Print("%s ", vm_snapshot_data_filename);
      success &= file->Print("%s ", isolate_snapshot_data_filename);
    }
    if (print_dependencies) {
      Log::Print("%s\n", vm_snapshot_data_filename);
      Log::Print("%s\n", isolate_snapshot_data_filename);
    }
  }
  for (intptr_t i = 0; i < dependencies->length(); i++) {
    char* dep = dependencies->At(i);
    if (dependencies_filename != NULL) {
      success &= file->Print("%s ", dep);
    }
    if (print_dependencies) {
      Log::Print("%s\n", dep);
    }
    free(dep);
  }

  if (dependencies_filename != NULL) {
    success &= file->Print("\n");

    if (!success) {
      Log::PrintErr("Error: Unable to write dependencies file: %s\n\n",
                    dependencies_filename);
      exit(kErrorExitCode);
    }
    file->Release();
  }
  delete dependencies;
  isolate_data->set_dependencies(NULL);
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
  const char* mapped_library_url_string =
      DartUtils::MapLibraryUrl(library_url_string);
  if (mapped_library_url_string != NULL) {
    library_url = ResolveUriInWorkingDirectory(mapped_library_url_string);
    library_url_string = DartUtils::GetStringValue(library_url);
  }

  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = DartUtils::GetStringValue(url);
  const char* mapped_url_string = DartUtils::MapLibraryUrl(url_string);

  Builtin::BuiltinLibraryId libraryBuiltinId = BuiltinId(library_url_string);
  if (tag == Dart_kCanonicalizeUrl) {
    if (mapped_url_string) {
      return url;
    }
    // Parts of internal libraries are handled internally.
    if (libraryBuiltinId != Builtin::kInvalidLibrary) {
      return url;
    }
    return Dart_DefaultCanonicalizeUrl(library_url, url);
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
      return Dart_LoadSource(library, url, Dart_Null(),
                             Builtin::PartSource(libraryBuiltinId, url_string),
                             0, 0);
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
  const char* resolved_uri_string = DartUtils::GetStringValue(resolved_url);
  Dart_Handle source = LoadUrlContents(resolved_uri_string);
  if (Dart_IsError(source)) {
    return source;
  }
  if (tag == Dart_kImportTag) {
    return Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    return Dart_LoadSource(library, url, Dart_Null(), source, 0, 0);
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


// clang-format off
static void PrintUsage() {
  Log::PrintErr(
"Usage:                                                                      \n"
" gen_snapshot [<vm-flags>] [<options>] [<dart-script-file>]                 \n"
"                                                                            \n"
" Global options:                                                            \n"
"   --package_root=<path>         Where to find packages, that is,           \n"
"                                 package:...  imports.                      \n"
"                                                                            \n"
"   --packages=<packages_file>    Where to find a package spec file          \n"
"                                                                            \n"
"   --url_mapping=<mapping>       Uses the URL mapping(s) specified on       \n"
"                                 the command line to load the               \n"
"                                 libraries.                                 \n"
"   --dependencies=<output-file>  Generates a Makefile with snapshot output  \n"
"                                 files as targets and all transitive imports\n"
"                                 as sources.                                \n"
"   --print_dependencies          Prints all transitive imports to stdout.   \n"
"   --dependencies_only           Don't create and output the snapshot.      \n"
"                                                                            \n"
" To create a core snapshot:                                                 \n"
"   --snapshot_kind=core                                                     \n"
"   --vm_snapshot_data=<output-file>                                         \n"
"   --isolate_snapshot_data=<output-file>                                    \n"
"   [<dart-script-file>]                                                     \n"
"                                                                            \n"
" Writes a snapshot of <dart-script-file> to the specified snapshot files.   \n"
" If no <dart-script-file> is passed, a generic snapshot of all the corelibs \n"
" is created.                                                                \n"
"                                                                            \n"
" To create a script snapshot with respect to a given core snapshot:         \n"
"   --snapshot_kind=script                                                   \n"
"   --vm_snapshot_data=<intput-file>                                         \n"
"   --isolate_snapshot_data=<intput-file>                                    \n"
"   --script_snapshot=<output-file>                                          \n"
"   <dart-script-file>                                                       \n"
"                                                                            \n"
"  Writes a snapshot of <dart-script-file> to the specified snapshot files.  \n"
"  If no <dart-script-file> is passed, a generic snapshot of all the corelibs\n"
"  is created.                                                               \n"
"                                                                            \n"
" To create an AOT application snapshot as blobs suitable for loading with   \n"
" mmap:                                                                      \n"
"   --snapshot_kind=app-aot-blobs                                            \n"
"   --vm_snapshot_data=<output-file>                                         \n"
"   --vm_snapshot_instructions=<output-file>                                 \n"
"   --isolate_snapshot_data=<output-file>                                    \n"
"   --isolate_snapshot_instructions=<output-file>                            \n"
"   {--embedder_entry_points_manifest=<input-file>}                          \n"
"   <dart-script-file>                                                       \n"
"                                                                            \n"
" To create an AOT application snapshot as assembly suitable for compilation \n"
" as a static or dynamic library:                                            \n"
" mmap:                                                                      \n"
"   --snapshot_kind=app-aot-blobs                                            \n"
"   --assembly=<output-file>                                                 \n"
"   {--embedder_entry_points_manifest=<input-file>}                          \n"
"   <dart-script-file>                                                       \n"
"                                                                            \n"
" AOT snapshots require entry points manifest files, which list the places   \n"
" in the Dart program the embedder calls from the C API (Dart_Invoke, etc).  \n"
" Not specifying these may cause the tree shaker to remove them from the     \n"
" program. The format of this manifest is as follows. Each line in the       \n"
" manifest is a comma separated list of three elements. The first entry is   \n"
" the library URI, the second entry is the class name and the final entry    \n"
" the function name. The file must be terminated with a newline character.   \n"
"                                                                            \n"
"   Example:                                                                 \n"
"     dart:something,SomeClass,doSomething                                   \n"
"\n");
}
// clang-format on


static const char StubNativeFunctionName[] = "StubNativeFunction";


void StubNativeFunction(Dart_NativeArguments arguments) {
  // This is a stub function for the resolver
  Dart_SetReturnValue(
      arguments, Dart_NewApiError("<EMBEDDER DID NOT SETUP NATIVE RESOLVER>"));
}


static Dart_NativeFunction StubNativeLookup(Dart_Handle name,
                                            int argument_count,
                                            bool* auto_setup_scope) {
  return &StubNativeFunction;
}


static const uint8_t* StubNativeSymbol(Dart_NativeFunction nf) {
  return reinterpret_cast<const uint8_t*>(StubNativeFunctionName);
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
    snprintf(load_buffer, kLoadBufferMaxSize, "import '%s';",
             DartUtils::GetStringValue(library_string));
    Dart_Handle script_handle = Dart_NewStringFromCString(load_buffer);
    memset(load_buffer, 0, kLoadBufferMaxSize);
    snprintf(load_buffer, kLoadBufferMaxSize, "dart:_snapshot_%zu", lib_index);
    Dart_Handle script_url = Dart_NewStringFromCString(load_buffer);
    free(load_buffer);
    Dart_Handle loaded =
        Dart_LoadLibrary(script_url, Dart_Null(), script_handle, 0, 0);
    DART_CHECK_VALID(loaded);

    // Do a fresh lookup
    library = Dart_LookupLibrary(library_string);
  }

  DART_CHECK_VALID(library);
  Dart_Handle result =
      Dart_SetNativeResolver(library, &StubNativeLookup, &StubNativeSymbol);
  DART_CHECK_VALID(result);
}


// Iterate over all libraries and setup the stub native lookup. This must be
// run after |SetupStubNativeResolversForPrecompilation| because the former
// loads some libraries.
static void SetupStubNativeResolvers() {
  Dart_Handle libraries = Dart_GetLoadedLibraries();
  intptr_t libraries_length;
  Dart_ListLength(libraries, &libraries_length);
  for (intptr_t i = 0; i < libraries_length; i++) {
    Dart_Handle library = Dart_ListGetAt(libraries, i);
    DART_CHECK_VALID(library);
    Dart_NativeEntryResolver old_resolver = NULL;
    Dart_GetNativeResolver(library, &old_resolver);
    if (old_resolver == NULL) {
      Dart_Handle result =
          Dart_SetNativeResolver(library, &StubNativeLookup, &StubNativeSymbol);
      DART_CHECK_VALID(result);
    }
  }
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


static void CleanupEntryPointItem(const Dart_QualifiedFunctionName* entry) {
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
    const char* line,
    Dart_QualifiedFunctionName* entry,
    char** error) {
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


static Dart_QualifiedFunctionName* ParseEntryPointsManifestFiles() {
  // Total number of entries across all manifest files.
  int64_t entry_count = 0;

  // Parse the files once but don't store the results. This is done to first
  // determine the number of entries in the manifest
  for (intptr_t i = 0; i < entry_points_files->count(); i++) {
    const char* path = entry_points_files->GetArgument(i);

    FILE* file = fopen(path, "r");

    if (file == NULL) {
      Log::PrintErr("Could not open entry points manifest file `%s`\n", path);
      return NULL;
    }

    int64_t entries = ParseEntryPointsManifestLines(file, NULL);
    fclose(file);

    if (entries <= 0) {
      Log::PrintErr(
          "Manifest file `%s` specified is invalid or contained no entries\n",
          path);
      return NULL;
    }

    entry_count += entries;
  }

  // Allocate enough storage for the entries in the file plus a termination
  // sentinel and parse it again to populate the allocation
  Dart_QualifiedFunctionName* entries =
      reinterpret_cast<Dart_QualifiedFunctionName*>(
          calloc(entry_count + 1, sizeof(Dart_QualifiedFunctionName)));

  int64_t parsed_entry_count = 0;
  for (intptr_t i = 0; i < entry_points_files->count(); i++) {
    const char* path = entry_points_files->GetArgument(i);
    FILE* file = fopen(path, "r");
    parsed_entry_count +=
        ParseEntryPointsManifestLines(file, &entries[parsed_entry_count]);
    fclose(file);
  }

  ASSERT(parsed_entry_count == entry_count);

  // The entries allocation must be explicitly cleaned up via
  // |CleanupEntryPointsCollection|
  return entries;
}


static Dart_QualifiedFunctionName* ParseEntryPointsManifestIfPresent() {
  Dart_QualifiedFunctionName* entries = ParseEntryPointsManifestFiles();
  if ((entries == NULL) && IsSnapshottingForPrecompilation()) {
    Log::PrintErr(
        "Could not find native embedder entry points during precompilation\n");
    exit(kErrorExitCode);
  }
  return entries;
}


static void LoadCompilationTrace() {
  if ((load_compilation_trace_filename != NULL) &&
      (snapshot_kind == kCoreJIT)) {
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    ReadFile(load_compilation_trace_filename, &buffer, &size);
    Dart_Handle result = Dart_LoadCompilationTrace(buffer, size);
    CHECK_RESULT(result);
  }
}


static void CreateAndWriteCoreSnapshot() {
  ASSERT(snapshot_kind == kCore);
  ASSERT(vm_snapshot_data_filename != NULL);
  ASSERT(isolate_snapshot_data_filename != NULL);

  Dart_Handle result;
  uint8_t* vm_snapshot_data_buffer = NULL;
  intptr_t vm_snapshot_data_size = 0;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  intptr_t isolate_snapshot_data_size = 0;

  // First create a snapshot.
  result = Dart_CreateSnapshot(&vm_snapshot_data_buffer, &vm_snapshot_data_size,
                               &isolate_snapshot_data_buffer,
                               &isolate_snapshot_data_size);
  CHECK_RESULT(result);

  // Now write the vm isolate and isolate snapshots out to the
  // specified file and exit.
  WriteFile(vm_snapshot_data_filename, vm_snapshot_data_buffer,
            vm_snapshot_data_size);
  if (vm_snapshot_instructions_filename != NULL) {
    WriteFile(vm_snapshot_instructions_filename, NULL, 0);
  }
  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  if (isolate_snapshot_instructions_filename != NULL) {
    WriteFile(isolate_snapshot_instructions_filename, NULL, 0);
  }
}


static void CreateAndWriteCoreJITSnapshot() {
  ASSERT(snapshot_kind == kCoreJIT);
  ASSERT(vm_snapshot_data_filename != NULL);
  ASSERT(vm_snapshot_instructions_filename != NULL);
  ASSERT(isolate_snapshot_data_filename != NULL);
  ASSERT(isolate_snapshot_instructions_filename != NULL);

  Dart_Handle result;
  uint8_t* vm_snapshot_data_buffer = NULL;
  intptr_t vm_snapshot_data_size = 0;
  uint8_t* vm_snapshot_instructions_buffer = NULL;
  intptr_t vm_snapshot_instructions_size = 0;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  intptr_t isolate_snapshot_data_size = 0;
  uint8_t* isolate_snapshot_instructions_buffer = NULL;
  intptr_t isolate_snapshot_instructions_size = 0;

  // First create a snapshot.
  result = Dart_CreateCoreJITSnapshotAsBlobs(
      &vm_snapshot_data_buffer, &vm_snapshot_data_size,
      &vm_snapshot_instructions_buffer, &vm_snapshot_instructions_size,
      &isolate_snapshot_data_buffer, &isolate_snapshot_data_size,
      &isolate_snapshot_instructions_buffer,
      &isolate_snapshot_instructions_size);
  CHECK_RESULT(result);

  // Now write the vm isolate and isolate snapshots out to the
  // specified file and exit.
  WriteFile(vm_snapshot_data_filename, vm_snapshot_data_buffer,
            vm_snapshot_data_size);
  WriteFile(vm_snapshot_instructions_filename, vm_snapshot_instructions_buffer,
            vm_snapshot_instructions_size);
  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  WriteFile(isolate_snapshot_instructions_filename,
            isolate_snapshot_instructions_buffer,
            isolate_snapshot_instructions_size);
}


static void CreateAndWriteScriptSnapshot() {
  ASSERT(snapshot_kind == kScript);
  ASSERT(script_snapshot_filename != NULL);

  // First create a snapshot.
  uint8_t* buffer = NULL;
  intptr_t size = 0;
  Dart_Handle result = Dart_CreateScriptSnapshot(&buffer, &size);
  CHECK_RESULT(result);

  // Now write it out to the specified file.
  WriteFile(script_snapshot_filename, buffer, size);
}


static void CreateAndWritePrecompiledSnapshot(
    Dart_QualifiedFunctionName* standalone_entry_points) {
  ASSERT(IsSnapshottingForPrecompilation());
  Dart_Handle result;

  // Precompile with specified embedder entry points
  result = Dart_Precompile(standalone_entry_points, NULL, 0);
  CHECK_RESULT(result);

  // Create a precompiled snapshot.
  bool as_assembly = assembly_filename != NULL;
  if (as_assembly) {
    ASSERT(snapshot_kind == kAppAOTAssembly);

    uint8_t* assembly_buffer = NULL;
    intptr_t assembly_size = 0;
    result =
        Dart_CreateAppAOTSnapshotAsAssembly(&assembly_buffer, &assembly_size);
    CHECK_RESULT(result);

    WriteFile(assembly_filename, assembly_buffer, assembly_size);
  } else {
    ASSERT(snapshot_kind == kAppAOTBlobs);

    uint8_t* vm_snapshot_data_buffer = NULL;
    intptr_t vm_snapshot_data_size = 0;
    uint8_t* vm_snapshot_instructions_buffer = NULL;
    intptr_t vm_snapshot_instructions_size = 0;
    uint8_t* isolate_snapshot_data_buffer = NULL;
    intptr_t isolate_snapshot_data_size = 0;
    uint8_t* isolate_snapshot_instructions_buffer = NULL;
    intptr_t isolate_snapshot_instructions_size = 0;
    result = Dart_CreateAppAOTSnapshotAsBlobs(
        &vm_snapshot_data_buffer, &vm_snapshot_data_size,
        &vm_snapshot_instructions_buffer, &vm_snapshot_instructions_size,
        &isolate_snapshot_data_buffer, &isolate_snapshot_data_size,
        &isolate_snapshot_instructions_buffer,
        &isolate_snapshot_instructions_size);
    CHECK_RESULT(result);

    WriteFile(vm_snapshot_data_filename, vm_snapshot_data_buffer,
              vm_snapshot_data_size);
    WriteFile(vm_snapshot_instructions_filename,
              vm_snapshot_instructions_buffer, vm_snapshot_instructions_size);
    WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
              isolate_snapshot_data_size);
    WriteFile(isolate_snapshot_instructions_filename,
              isolate_snapshot_instructions_buffer,
              isolate_snapshot_instructions_size);
  }
}


static void SetupForUriResolution() {
  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  if (Dart_IsError(result)) {
    Log::PrintErr("%s\n", Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  // This is a generic dart snapshot which needs builtin library setup.
  Dart_Handle library =
      LoadGenericSnapshotCreationScript(Builtin::kBuiltinLibrary);
  CHECK_RESULT(library);
}


static void SetupForGenericSnapshotCreation() {
  SetupForUriResolution();

  Dart_Handle library = LoadGenericSnapshotCreationScript(Builtin::kIOLibrary);
  CHECK_RESULT(library);
  Dart_Handle result = Dart_FinalizeLoading(false);
  if (Dart_IsError(result)) {
    const char* err_msg = Dart_GetError(library);
    Log::PrintErr("Errors encountered while loading: %s\n", err_msg);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
}


static Dart_Isolate CreateServiceIsolate(const char* script_uri,
                                         const char* main,
                                         const char* package_root,
                                         const char* package_config,
                                         Dart_IsolateFlags* flags,
                                         void* data,
                                         char** error) {
  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, package_config, NULL);
  Dart_Isolate isolate = NULL;
  isolate = Dart_CreateIsolate(script_uri, main, isolate_snapshot_data,
                               isolate_snapshot_instructions, NULL,
                               isolate_data, error);

  if (isolate == NULL) {
    Log::PrintErr("Error: Could not create service isolate\n");
    return NULL;
  }

  Dart_EnterScope();
  if (!Dart_IsServiceIsolate(isolate)) {
    Log::PrintErr("Error: We only expect to create the service isolate\n");
    return NULL;
  }
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  if (Dart_IsError(result)) {
    Log::PrintErr("Error: Could not set tag handler for service isolate\n");
    return NULL;
  }
  // Setup the native resolver.
  Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);

  ASSERT(Dart_IsServiceIsolate(isolate));
  // Load embedder specific bits and return. Will not start http server.
  if (!VmService::Setup("127.0.0.1", -1, false /* running_precompiled */,
                        false /* server dev mode */,
                        false /* trace_loading */)) {
    *error = strdup(VmService::GetErrorMessage());
    return NULL;
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}


static MappedMemory* MapFile(const char* filename, File::MapType type) {
  File* file = File::Open(filename, File::kRead);
  if (file == NULL) {
    Log::PrintErr("Failed to open: %s\n", filename);
    exit(kErrorExitCode);
  }
  MappedMemory* mapping = file->Map(type, 0, file->Length());
  if (mapping == NULL) {
    Log::PrintErr("Failed to read: %s\n", vm_snapshot_data_filename);
    exit(kErrorExitCode);
  }
  file->Release();
  return mapping;
}


int main(int argc, char** argv) {
  const int EXTRA_VM_ARGUMENTS = 2;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);

  // Initialize the URL mapping array.
  CommandLineOptions cmdline_url_mapping(argc);
  DartUtils::url_mapping = &cmdline_url_mapping;

  // Initialize the entrypoints array.
  CommandLineOptions entry_points_files_array(argc);
  entry_points_files = &entry_points_files_array;

  // Parse command line arguments.
  if (ParseArguments(argc, argv, &vm_options, &app_script_name) < 0) {
    PrintUsage();
    return kErrorExitCode;
  }

  Thread::InitOnce();
  Loader::InitOnce();
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
  }
  if (snapshot_kind == kCoreJIT) {
    vm_options.AddArgument("--fields_may_be_reset");
    vm_options.AddArgument("--link_natives_lazily");
#if !defined(PRODUCT)
    vm_options.AddArgument("--collect_code=false");
#endif
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  // Note: We don't expect isolates to be created from dart code during
  // core library snapshot generation. However for the case when a full
  // snasphot is generated from a script (app_script_name != NULL) we will
  // need the service isolate to resolve URI and load code.

  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  if (app_script_name != NULL) {
    init_params.create = CreateServiceIsolate;
  }
  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;

  MappedMemory* mapped_vm_snapshot_data = NULL;
  MappedMemory* mapped_vm_snapshot_instructions = NULL;
  MappedMemory* mapped_isolate_snapshot_data = NULL;
  MappedMemory* mapped_isolate_snapshot_instructions = NULL;
  if (snapshot_kind == kScript) {
    mapped_vm_snapshot_data =
        MapFile(vm_snapshot_data_filename, File::kReadOnly);
    init_params.vm_snapshot_data =
        reinterpret_cast<const uint8_t*>(mapped_vm_snapshot_data->address());

    if (vm_snapshot_instructions_filename != NULL) {
      mapped_vm_snapshot_instructions =
          MapFile(vm_snapshot_instructions_filename, File::kReadExecute);
      init_params.vm_snapshot_instructions = reinterpret_cast<const uint8_t*>(
          mapped_vm_snapshot_instructions->address());
    }

    mapped_isolate_snapshot_data =
        MapFile(isolate_snapshot_data_filename, File::kReadOnly);
    isolate_snapshot_data = reinterpret_cast<const uint8_t*>(
        mapped_isolate_snapshot_data->address());

    if (isolate_snapshot_instructions_filename != NULL) {
      mapped_isolate_snapshot_instructions =
          MapFile(isolate_snapshot_instructions_filename, File::kReadExecute);
      isolate_snapshot_instructions = reinterpret_cast<const uint8_t*>(
          mapped_isolate_snapshot_instructions->address());
    }
  }

  char* error = Dart_Initialize(&init_params);
  if (error != NULL) {
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  IsolateData* isolate_data = new IsolateData(NULL, commandline_package_root,
                                              commandline_packages_file, NULL);
  Dart_Isolate isolate = Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                            isolate_snapshot_instructions, NULL,
                                            isolate_data, &error);
  if (isolate == NULL) {
    Log::PrintErr("Error: %s\n", error);
    free(error);
    exit(kErrorExitCode);
  }

  Dart_Handle result;
  Dart_Handle library;
  Dart_EnterScope();

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

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
    result = DartUtils::SetupPackageRoot(commandline_package_root,
                                         commandline_packages_file);
    CHECK_RESULT(result);

    UriResolverIsolateScope::isolate = isolate;
    Dart_ExitScope();
    Dart_ExitIsolate();

    // Now we create an isolate into which we load all the code that needs to
    // be in the snapshot.
    isolate_data = new IsolateData(app_script_name, commandline_package_root,
                                   commandline_packages_file, NULL);
    const uint8_t* kernel = NULL;
    intptr_t kernel_length = 0;
    const bool is_kernel_file =
        dfe.TryReadKernelFile(app_script_name, &kernel, &kernel_length);

    if ((dependencies_filename != NULL) || print_dependencies) {
      isolate_data->set_dependencies(new MallocGrowableArray<char*>());
    }

    void* kernel_program = NULL;
    if (is_kernel_file) {
      kernel_program = Dart_ReadKernelBinary(kernel, kernel_length);
      free(const_cast<uint8_t*>(kernel));
    }

    Dart_Isolate isolate =
        is_kernel_file
            ? Dart_CreateIsolateFromKernel(NULL, NULL, kernel_program, NULL,
                                           isolate_data, &error)
            : Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                 isolate_snapshot_instructions, NULL,
                                 isolate_data, &error);
    if (isolate == NULL) {
      Log::PrintErr("%s\n", error);
      free(error);
      exit(kErrorExitCode);
    }
    Dart_EnterScope();
    result = Dart_SetEnvironmentCallback(EnvironmentCallback);
    CHECK_RESULT(result);

    // Set up the library tag handler in such a manner that it will use the
    // URL mapping specified on the command line to load the libraries.
    result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
    CHECK_RESULT(result);

    if (commandline_packages_file != NULL) {
      AddDependency(commandline_packages_file);
    }

    Dart_QualifiedFunctionName* entry_points =
        ParseEntryPointsManifestIfPresent();

    if (is_kernel_file) {
      Dart_Handle library = Dart_LoadKernel(kernel_program);
      if (Dart_IsError(library)) FATAL("Failed to load app from Kernel IR");
    } else {
      // Set up the library tag handler in such a manner that it will use the
      // URL mapping specified on the command line to load the libraries.
      result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
      CHECK_RESULT(result);
    }

    SetupStubNativeResolversForPrecompilation(entry_points);

    SetupStubNativeResolvers();

    if (!is_kernel_file) {
      // Load the specified script.
      library = LoadSnapshotCreationScript(app_script_name);
      CHECK_RESULT(library);

      ImportNativeEntryPointLibrariesIntoRoot(entry_points);
    }

    // Ensure that we mark all libraries as loaded.
    result = Dart_FinalizeLoading(false);
    CHECK_RESULT(result);

    LoadCompilationTrace();

    if (!dependencies_only) {
      switch (snapshot_kind) {
        case kCore:
          CreateAndWriteCoreSnapshot();
          break;
        case kCoreJIT:
          CreateAndWriteCoreJITSnapshot();
          break;
        case kScript:
          CreateAndWriteScriptSnapshot();
          break;
        case kAppAOTBlobs:
        case kAppAOTAssembly:
          CreateAndWritePrecompiledSnapshot(entry_points);
          break;
        default:
          UNREACHABLE();
      }
    }

    CreateAndWriteDependenciesFile();

    Dart_ExitScope();
    Dart_ShutdownIsolate();

    CleanupEntryPointsCollection(entry_points);

    Dart_EnterIsolate(UriResolverIsolateScope::isolate);
    Dart_ShutdownIsolate();
  } else {
    SetupForGenericSnapshotCreation();
    LoadCompilationTrace();
    switch (snapshot_kind) {
      case kCore:
        CreateAndWriteCoreSnapshot();
        break;
      case kCoreJIT:
        CreateAndWriteCoreJITSnapshot();
        break;
      default:
        UNREACHABLE();
        break;
    }

    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }
  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  EventHandler::Stop();
  delete mapped_vm_snapshot_data;
  delete mapped_isolate_snapshot_data;
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  return dart::bin::main(argc, argv);
}

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
#include "bin/options.h"
#include "bin/platform.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"

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
  kVMAOTAssembly,
};
static SnapshotKind snapshot_kind = kCore;

// Global state which contains a pointer to the script name for which
// a snapshot needs to be created (NULL would result in the creation
// of a generic snapshot that contains only the corelibs).
static char* app_script_name = NULL;

// Global state that captures the entry point manifest files specified on the
// command line.
static CommandLineOptions* entry_points_files = NULL;

// The environment provided through the command line using -D options.
static dart::HashMap* environment = NULL;

static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}

static bool ProcessEnvironmentOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &environment);
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

static const char* kSnapshotKindNames[] = {
    "core",
    "core-jit",
    "script",
    "app-aot-blobs",
    "app-aot-assembly",
    "vm-aot-assembly",
    NULL,
};

#define STRING_OPTIONS_LIST(V)                                                 \
  V(vm_snapshot_data, vm_snapshot_data_filename)                               \
  V(vm_snapshot_instructions, vm_snapshot_instructions_filename)               \
  V(isolate_snapshot_data, isolate_snapshot_data_filename)                     \
  V(isolate_snapshot_instructions, isolate_snapshot_instructions_filename)     \
  V(assembly, assembly_filename)                                               \
  V(script_snapshot, script_snapshot_filename)                                 \
  V(dependencies, dependencies_filename)                                       \
  V(load_compilation_trace, load_compilation_trace_filename)                   \
  V(package_root, commandline_package_root)                                    \
  V(packages, commandline_packages_file)                                       \
  V(save_obfuscation_map, obfuscation_map_filename)

#define BOOL_OPTIONS_LIST(V)                                                   \
  V(dependencies_only, dependencies_only)                                      \
  V(print_dependencies, print_dependencies)                                    \
  V(obfuscate, obfuscate)

#define STRING_OPTION_DEFINITION(flag, variable)                               \
  static const char* variable = NULL;                                          \
  DEFINE_STRING_OPTION(flag, variable)
STRING_OPTIONS_LIST(STRING_OPTION_DEFINITION)
#undef STRING_OPTION_DEFINITION

#define BOOL_OPTION_DEFINITION(flag, variable)                                 \
  static bool variable = false;                                                \
  DEFINE_BOOL_OPTION(flag, variable)
BOOL_OPTIONS_LIST(BOOL_OPTION_DEFINITION)
#undef BOOL_OPTION_DEFINITION

DEFINE_ENUM_OPTION(snapshot_kind, SnapshotKind, snapshot_kind);
DEFINE_STRING_OPTION_CB(embedder_entry_points_manifest,
                        { entry_points_files->AddArgument(value); });
DEFINE_STRING_OPTION_CB(url_mapping,
                        { DartUtils::url_mapping->AddArgument(value); });
DEFINE_CB_OPTION(ProcessEnvironmentOption);

static bool IsSnapshottingForPrecompilation() {
  return (snapshot_kind == kAppAOTBlobs) ||
         (snapshot_kind == kAppAOTAssembly) ||
         (snapshot_kind == kVMAOTAssembly);
}

static bool SnapshotKindAllowedFromKernel() {
  return IsSnapshottingForPrecompilation() || (snapshot_kind == kCore);
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
  while ((i < argc) &&
         OptionProcessor::IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
    if (OptionProcessor::TryProcess(argv[i], vm_options)) {
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
    case kVMAOTAssembly: {
      if ((assembly_filename == NULL) || (*script_name != NULL)) {
        Log::PrintErr(
            "Building an AOT snapshot as assembly requires specifying "
            "an output file for --assembly and a Dart script.\n\n");
        return -1;
      }
      break;
    }
  }

  if (!obfuscate && obfuscation_map_filename != NULL) {
    Log::PrintErr(
        "--obfuscation_map=<...> should only be specified when obfuscation is "
        "enabled by --obfuscate flag.\n\n");
    return -1;
  }

  if (obfuscate && !IsSnapshottingForPrecompilation()) {
    Log::PrintErr(
        "Obfuscation can only be enabled when building AOT snapshot.\n\n");
    return -1;
  }

  return 0;
}

static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
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
  File* file = File::Open(NULL, filename, File::kRead);
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
  if ((snapshot_kind == kCore) || (snapshot_kind == kCoreJIT)) {
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
  if (DartUtils::IsDartHttpLibURL(url)) {
    return Builtin::kHttpLibrary;
  }
  if (DartUtils::IsDartCLILibURL(url)) {
    return Builtin::kCLILibrary;
  }
  return Builtin::kInvalidLibrary;
}

// Generates a depfile like gcc -M -MF. Must be consumable by Ninja.
class DependenciesFileWriter : public ValueObject {
 public:
  DependenciesFileWriter() : dependencies_(NULL), file_(NULL), success_(true) {}

  void WriteDependencies(MallocGrowableArray<char*>* dependencies) {
    dependencies_ = dependencies;

    file_ = File::Open(NULL, dependencies_filename, File::kWriteTruncate);
    if (file_ == NULL) {
      Log::PrintErr("Error: Unable to open dependencies file: %s\n\n",
                    dependencies_filename);
      exit(kErrorExitCode);
    }

    // Write dependencies for one of the output files.
    // TODO(https://github.com/ninja-build/ninja/issues/1184): Do this for all
    // output files.
    switch (snapshot_kind) {
      case kCore:
        WriteDependenciesWithTarget(vm_snapshot_data_filename);
        // WriteDependenciesWithTarget(isolate_snapshot_data_filename);
        break;
      case kScript:
        WriteDependenciesWithTarget(script_snapshot_filename);
        break;
      case kAppAOTAssembly:
        WriteDependenciesWithTarget(assembly_filename);
        break;
      case kCoreJIT:
      case kAppAOTBlobs:
        WriteDependenciesWithTarget(vm_snapshot_data_filename);
        // WriteDependenciesWithTarget(vm_snapshot_instructions_filename);
        // WriteDependenciesWithTarget(isolate_snapshot_data_filename);
        // WriteDependenciesWithTarget(isolate_snapshot_instructions_filename);
        break;
      default:
        UNREACHABLE();
    }

    if (!success_) {
      Log::PrintErr("Error: Unable to write dependencies file: %s\n\n",
                    dependencies_filename);
      exit(kErrorExitCode);
    }
    file_->Release();
  }

 private:
  void WriteDependenciesWithTarget(const char* target) {
    WritePath(target);
    Write(": ");

    if (snapshot_kind == kScript) {
      if (vm_snapshot_data_filename != NULL) {
        WritePath(vm_snapshot_data_filename);
      }
      if (vm_snapshot_instructions_filename != NULL) {
        WritePath(vm_snapshot_instructions_filename);
      }
      if (isolate_snapshot_data_filename != NULL) {
        WritePath(isolate_snapshot_data_filename);
      }
      if (isolate_snapshot_instructions_filename != NULL) {
        WritePath(isolate_snapshot_instructions_filename);
      }
    }

    for (intptr_t i = 0; i < dependencies_->length(); i++) {
      WritePath(dependencies_->At(i));
    }

    Write("\n");
  }

  char* EscapePath(const char* path) {
    char* escaped_path = reinterpret_cast<char*>(malloc(strlen(path) * 2 + 1));
    const char* read_cursor = path;
    char* write_cursor = escaped_path;
    while (*read_cursor != '\0') {
      if ((*read_cursor == ' ') || (*read_cursor == '\\')) {
        *write_cursor++ = '\\';
      }
      *write_cursor++ = *read_cursor++;
    }
    *write_cursor = '\0';
    return escaped_path;
  }

  void WritePath(const char* path) {
    char* escaped_path = EscapePath(path);
    success_ &= file_->Print("%s ", escaped_path);
    free(escaped_path);
  }

  void Write(const char* string) { success_ &= file_->Print("%s", string); }

  MallocGrowableArray<char*>* dependencies_;
  File* file_;
  bool success_;
};

static void CreateAndWriteDependenciesFile() {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
  if (dependencies == NULL) {
    return;
  }

  Loader::ResolveDependenciesAsFilePaths();

  ASSERT((dependencies_filename != NULL) || print_dependencies);
  if (dependencies_filename != NULL) {
    DependenciesFileWriter writer;
    writer.WriteDependencies(dependencies);
  }

  if (print_dependencies) {
    Log::Print("%s\n", vm_snapshot_data_filename);
    if (snapshot_kind == kScript) {
      if (vm_snapshot_data_filename != NULL) {
        Log::Print("%s\n", vm_snapshot_data_filename);
      }
      if (vm_snapshot_instructions_filename != NULL) {
        Log::Print("%s\n", vm_snapshot_instructions_filename);
      }
      if (isolate_snapshot_data_filename != NULL) {
        Log::Print("%s\n", isolate_snapshot_data_filename);
      }
      if (isolate_snapshot_instructions_filename != NULL) {
        Log::Print("%s\n", isolate_snapshot_instructions_filename);
      }
    }
    for (intptr_t i = 0; i < dependencies->length(); i++) {
      Log::Print("%s\n", dependencies->At(i));
    }
  }

  for (intptr_t i = 0; i < dependencies->length(); i++) {
    free(dependencies->At(i));
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
      intptr_t len = snprintf(NULL, 0, "%s/%s", library_url_string, url_string);
      char* patch_filename = reinterpret_cast<char*>(malloc(len + 1));
      snprintf(patch_filename, len + 1, "%s/%s", library_url_string,
               url_string);
      Dart_Handle prefixed_url = Dart_NewStringFromCString(patch_filename);
      Dart_Handle result = Dart_LoadSource(
          library, prefixed_url, Dart_Null(),
          Builtin::PartSource(libraryBuiltinId, patch_filename), 0, 0);
      free(patch_filename);
      return result;
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
"   --vm_snapshot_data=<input-file>                                          \n"
"   --isolate_snapshot_data=<input-file>                                     \n"
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
"   [--obfuscate]                                                            \n"
"   [--save-obfuscation-map=<map-filename>]                                  \n"
"   <dart-script-file>                                                       \n"
"                                                                            \n"
" To create an AOT application snapshot as assembly suitable for compilation \n"
" as a static or dynamic library:                                            \n"
"   --snapshot_kind=app-aot-assembly                                         \n"
"   --assembly=<output-file>                                                 \n"
"   {--embedder_entry_points_manifest=<input-file>}                          \n"
"   [--obfuscate]                                                            \n"
"   [--save-obfuscation-map=<map-filename>]                                  \n"
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
"                                                                            \n"
" AOT snapshots can be obfuscated: that is all identifiers will be renamed   \n"
" during compilation. This mode is enabled with --obfuscate flag. Mapping    \n"
" between original and obfuscated names can be serialized as a JSON array    \n"
" using --save-obfuscation-map=<filename> option. See dartbug.com/30524      \n"
" for implementation details and limitations of the obfuscation pass.        \n"
"                                                                            \n"
"\n");
}
// clang-format on

static void LoadEntryPoint(size_t lib_index,
                           const Dart_QualifiedFunctionName* entry) {
  if (strcmp(entry->library_uri, "::") == 0) {
    return;  // Root library always loaded; can't `import '::';`.
  }

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
    if (strcmp(entry.library_uri, "::") != 0) {
      Dart_Handle entry_library =
          Dart_LookupLibrary(Dart_NewStringFromCString(entry.library_uri));
      DART_CHECK_VALID(entry_library);
      Dart_Handle import_result = Dart_LibraryImportLibrary(
          entry_library, Dart_RootLibrary(), Dart_EmptyString());
      DART_CHECK_VALID(import_result);
    }
  }
}

static void LoadEntryPoints(const Dart_QualifiedFunctionName* entries) {
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
    // Ensure library named in entry point is loaded.
    LoadEntryPoint(index, &entry);
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

    if ((read_line[0] == '\n') || (read_line[0] == '#')) {
      // Blank or comment line.
      continue;
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
  result = Dart_Precompile(standalone_entry_points);
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

  // Serialize obfuscation map if requested.
  if (obfuscation_map_filename != NULL) {
    ASSERT(obfuscate);
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    result = Dart_GetObfuscationMap(&buffer, &size);
    CHECK_RESULT(result);
    WriteFile(obfuscation_map_filename, buffer, size);
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
  Dart_Handle standalone_library =
      LoadGenericSnapshotCreationScript(Builtin::kCLILibrary);
  CHECK_RESULT(standalone_library);
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
                               isolate_snapshot_instructions, flags,
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
  Builtin::LoadAndCheckLibrary(Builtin::kCLILibrary);

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

static MappedMemory* MapFile(const char* filename,
                             File::MapType type,
                             const uint8_t** buffer) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    Log::PrintErr("Failed to open: %s\n", filename);
    exit(kErrorExitCode);
  }
  intptr_t length = file->Length();
  if (length == 0) {
    // Can't map an empty file.
    *buffer = NULL;
    return NULL;
  }
  MappedMemory* mapping = file->Map(type, 0, length);
  if (mapping == NULL) {
    Log::PrintErr("Failed to read: %s\n", filename);
    exit(kErrorExitCode);
  }
  file->Release();
  *buffer = reinterpret_cast<const uint8_t*>(mapping->address());
  return mapping;
}

static int GenerateSnapshotFromKernelProgram(void* kernel_program) {
  ASSERT(SnapshotKindAllowedFromKernel());

  char* error = NULL;
  IsolateData* isolate_data = new IsolateData(NULL, commandline_package_root,
                                              commandline_packages_file, NULL);
  if ((dependencies_filename != NULL) || print_dependencies) {
    isolate_data->set_dependencies(new MallocGrowableArray<char*>());
  }

  Dart_IsolateFlags isolate_flags;
  Dart_IsolateFlagsInitialize(&isolate_flags);

  Dart_QualifiedFunctionName* entry_points = NULL;
  if (IsSnapshottingForPrecompilation()) {
    entry_points = ParseEntryPointsManifestIfPresent();
    isolate_flags.obfuscate = obfuscate;
    isolate_flags.entry_points = entry_points;
  }

  // We need to capture the vmservice library in the core snapshot, so load it
  // in the main isolate as well.
  isolate_flags.load_vmservice_library = true;
  Dart_Isolate isolate = Dart_CreateIsolateFromKernel(
      NULL, NULL, kernel_program, &isolate_flags, isolate_data, &error);
  if (isolate == NULL) {
    delete isolate_data;
    Log::PrintErr("%s\n", error);
    free(error);
    return kErrorExitCode;
  }

  Dart_EnterScope();
  Dart_Handle result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

  if (IsSnapshottingForPrecompilation()) {
    // The root library has to be set to generate AOT snapshots.
    // If the input dill file has a root library, then Dart_LoadScript will
    // ignore this dummy uri and set the root library to the one reported in
    // the dill file. Since dill files are not dart script files,
    // trying to resolve the root library URI based on the dill file name
    // would not help.
    //
    // If the input dill file does not have a root library, then
    // Dart_LoadScript will error.
    Dart_Handle dummy_uri =
        DartUtils::NewString("____dummy_gen_snapshot_root_library_uri____");
    Dart_Handle library =
        Dart_LoadScript(dummy_uri, Dart_Null(),
                        reinterpret_cast<Dart_Handle>(kernel_program), 0, 0);
    if (Dart_IsError(library)) {
      Log::PrintErr("Unable to load root library from the input dill file.\n");
      return kErrorExitCode;
    }

    CreateAndWritePrecompiledSnapshot(entry_points);

    CreateAndWriteDependenciesFile();

    CleanupEntryPointsCollection(entry_points);
  } else {
    CreateAndWriteCoreSnapshot();
  }

  Dart_ExitScope();
  Dart_ShutdownIsolate();
  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  EventHandler::Stop();
  return 0;
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

  // Sniff the script to check if it is actually a dill file.
  void* kernel_program = NULL;
  if (app_script_name != NULL) {
    kernel_program = dfe.ReadScript(app_script_name);
  }
  if (kernel_program != NULL && !SnapshotKindAllowedFromKernel()) {
    // TODO(sivachandra): Add check for the kernel program format (incremental
    // vs batch).
    Log::PrintErr(
        "Can only generate core or aot snapshots from a kernel file.\n");
    return kErrorExitCode;
  }

  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
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
  if (app_script_name != NULL && kernel_program == NULL) {
    // We need the service isolate to load script files.
    // When generating snapshots from a kernel program, we do not need to load
    // any script files.
    init_params.create = CreateServiceIsolate;
  }
  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;
  init_params.start_kernel_isolate = false;

  MappedMemory* mapped_vm_snapshot_data = NULL;
  MappedMemory* mapped_vm_snapshot_instructions = NULL;
  MappedMemory* mapped_isolate_snapshot_data = NULL;
  MappedMemory* mapped_isolate_snapshot_instructions = NULL;
  if (snapshot_kind == kScript) {
    mapped_vm_snapshot_data =
        MapFile(vm_snapshot_data_filename, File::kReadOnly,
                &init_params.vm_snapshot_data);

    if (vm_snapshot_instructions_filename != NULL) {
      mapped_vm_snapshot_instructions =
          MapFile(vm_snapshot_instructions_filename, File::kReadExecute,
                  &init_params.vm_snapshot_instructions);
    }

    mapped_isolate_snapshot_data =
        MapFile(isolate_snapshot_data_filename, File::kReadOnly,
                &isolate_snapshot_data);

    if (isolate_snapshot_instructions_filename != NULL) {
      mapped_isolate_snapshot_instructions =
          MapFile(isolate_snapshot_instructions_filename, File::kReadExecute,
                  &isolate_snapshot_instructions);
    }
  }

  char* error = Dart_Initialize(&init_params);
  if (error != NULL) {
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  if (kernel_program != NULL) {
    return GenerateSnapshotFromKernelProgram(kernel_program);
  }

  Dart_IsolateFlags flags;
  Dart_IsolateFlagsInitialize(&flags);

  Dart_QualifiedFunctionName* entry_points =
      ParseEntryPointsManifestIfPresent();

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

  if (snapshot_kind == kVMAOTAssembly) {
    uint8_t* assembly_buffer = NULL;
    intptr_t assembly_size = 0;
    result =
        Dart_CreateVMAOTSnapshotAsAssembly(&assembly_buffer, &assembly_size);
    CHECK_RESULT(result);

    WriteFile(assembly_filename, assembly_buffer, assembly_size);

    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return 0;
  }

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
    if ((dependencies_filename != NULL) || print_dependencies) {
      isolate_data->set_dependencies(new MallocGrowableArray<char*>());
    }

    if (IsSnapshottingForPrecompilation()) {
      flags.obfuscate = obfuscate;
      flags.entry_points = entry_points;
    }

    Dart_Isolate isolate = NULL;
    isolate = Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                 isolate_snapshot_instructions, &flags,
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

    ASSERT(kernel_program == NULL);

    // Load any libraries named in the entry points. Do this before loading the
    // user's script to ensure conditional imports see the embedder-specific
    // dart: libraries.
    LoadEntryPoints(entry_points);

    // Load the specified script.
    library = LoadSnapshotCreationScript(app_script_name);
    CHECK_RESULT(library);

    ImportNativeEntryPointLibrariesIntoRoot(entry_points);

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
  delete mapped_vm_snapshot_instructions;
  delete mapped_isolate_snapshot_data;
  delete mapped_isolate_snapshot_instructions;
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  return dart::bin::main(argc, argv);
}

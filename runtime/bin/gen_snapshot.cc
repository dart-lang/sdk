// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cstdarg>
#include <memory>

#include "bin/builtin.h"
#include "bin/console.h"
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
// from a file when creating AppJIT snapshots.
const uint8_t* isolate_snapshot_data = NULL;
const uint8_t* isolate_snapshot_instructions = NULL;

// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
enum SnapshotKind {
  kCore,
  kCoreJIT,
  kAppJIT,
  kAppAOTBlobs,
  kAppAOTAssembly,
  kVMAOTAssembly,
};
static SnapshotKind snapshot_kind = kCore;

// Global state which contains a pointer to the script name for which
// a snapshot needs to be created (NULL would result in the creation
// of a generic snapshot that contains only the corelibs).
static char* app_script_name = NULL;

// The environment provided through the command line using -D options.
static dart::SimpleHashMap* environment = NULL;

static bool ProcessEnvironmentOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &environment);
}

static const char* kSnapshotKindNames[] = {
    "core",
    "core-jit",
    "app-jit",
    "app-aot-blobs",
    "app-aot-assembly",
    "vm-aot-assembly",
    NULL,
};

#define STRING_OPTIONS_LIST(V)                                                 \
  V(load_vm_snapshot_data, load_vm_snapshot_data_filename)                     \
  V(load_vm_snapshot_instructions, load_vm_snapshot_instructions_filename)     \
  V(load_isolate_snapshot_data, load_isolate_snapshot_data_filename)           \
  V(load_isolate_snapshot_instructions,                                        \
    load_isolate_snapshot_instructions_filename)                               \
  V(vm_snapshot_data, vm_snapshot_data_filename)                               \
  V(vm_snapshot_instructions, vm_snapshot_instructions_filename)               \
  V(isolate_snapshot_data, isolate_snapshot_data_filename)                     \
  V(isolate_snapshot_instructions, isolate_snapshot_instructions_filename)     \
  V(shared_data, shared_data_filename)                                         \
  V(shared_instructions, shared_instructions_filename)                         \
  V(reused_instructions, reused_instructions_filename)                         \
  V(assembly, assembly_filename)                                               \
  V(script_snapshot, script_snapshot_filename)                                 \
  V(dependencies, dependencies_filename)                                       \
  V(load_compilation_trace, load_compilation_trace_filename)                   \
  V(package_root, commandline_package_root)                                    \
  V(packages, commandline_packages_file)                                       \
  V(save_obfuscation_map, obfuscation_map_filename)

#define BOOL_OPTIONS_LIST(V)                                                   \
  V(obfuscate, obfuscate)                                                      \
  V(verbose, verbose)                                                          \
  V(version, version)                                                          \
  V(help, help)

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
DEFINE_STRING_OPTION_CB(embedder_entry_points_manifest, {
  Log::PrintErr(
      "Option --embedder_entry_points_manifest is no longer supported."
      " Use @pragma(\'vm:entry-point\') instead.\n");
  exit(kErrorExitCode);
});
DEFINE_STRING_OPTION_CB(url_mapping,
                        { DartUtils::url_mapping->AddArgument(value); });
DEFINE_CB_OPTION(ProcessEnvironmentOption);

static bool IsSnapshottingForPrecompilation() {
  return (snapshot_kind == kAppAOTBlobs) ||
         (snapshot_kind == kAppAOTAssembly) ||
         (snapshot_kind == kVMAOTAssembly);
}

// clang-format off
static void PrintUsage() {
  Log::PrintErr(
"Usage: gen_snapshot [<vm-flags>] [<options>] [<dart-script-file>]           \n"
"                                                                            \n"
"Common options:                                                             \n"
"--package_root=<path>                                                       \n"
"  Where to find packages, that is, package:...  imports.                    \n"
"--packages=<packages_file>                                                  \n"
"  Where to find a package spec file                                         \n"
"--url_mapping=<mapping>                                                     \n"
"  Uses the URL mapping(s) specified on the command line to load the         \n"
"  libraries.                                                                \n"
"--dependencies=<output-file>                                                \n"
"  Generates a Makefile with snapshot output files as targets and all        \n"
"  transitive imports as sources.                                            \n"
"--help                                                                      \n"
"  Display this message (add --verbose for information about all VM options).\n"
"--version                                                                   \n"
"  Print the VM version.                                                     \n"
"                                                                            \n"
"To create a core snapshot:                                                  \n"
"--snapshot_kind=core                                                        \n"
"--vm_snapshot_data=<output-file>                                            \n"
"--isolate_snapshot_data=<output-file>                                       \n"
"[<dart-script-file>]                                                        \n"
"                                                                            \n"
"Writes a snapshot of <dart-script-file> to the specified snapshot files.    \n"
"If no <dart-script-file> is passed, a generic snapshot of all the corelibs  \n"
"is created.                                                                 \n"
"                                                                            \n"
"To create a script snapshot with respect to a given core snapshot:          \n"
"--snapshot_kind=script                                                      \n"
"--vm_snapshot_data=<input-file>                                             \n"
"--isolate_snapshot_data=<input-file>                                        \n"
"--script_snapshot=<output-file>                                             \n"
"<dart-script-file>                                                          \n"
"                                                                            \n"
"Writes a snapshot of <dart-script-file> to the specified snapshot files.    \n"
"If no <dart-script-file> is passed, a generic snapshot of all the corelibs  \n"
"is created.                                                                 \n"
"                                                                            \n"
"To create an AOT application snapshot as blobs suitable for loading with    \n"
"mmap:                                                                       \n"
"--snapshot_kind=app-aot-blobs                                               \n"
"--vm_snapshot_data=<output-file>                                            \n"
"--vm_snapshot_instructions=<output-file>                                    \n"
"--isolate_snapshot_data=<output-file>                                       \n"
"--isolate_snapshot_instructions=<output-file>                               \n"
"[--obfuscate]                                                               \n"
"[--save-obfuscation-map=<map-filename>]                                     \n"
" <dart-script-file>                                                         \n"
"                                                                            \n"
"To create an AOT application snapshot as assembly suitable for compilation  \n"
"as a static or dynamic library:                                             \n"
"--snapshot_kind=app-aot-assembly                                            \n"
"--assembly=<output-file>                                                    \n"
"[--obfuscate]                                                               \n"
"[--save-obfuscation-map=<map-filename>]                                     \n"
"<dart-script-file>                                                          \n"
"                                                                            \n"
"AOT snapshots can be obfuscated: that is all identifiers will be renamed    \n"
"during compilation. This mode is enabled with --obfuscate flag. Mapping     \n"
"between original and obfuscated names can be serialized as a JSON array     \n"
"using --save-obfuscation-map=<filename> option. See dartbug.com/30524       \n"
"for implementation details and limitations of the obfuscation pass.         \n"
"                                                                            \n"
"\n");
  if (verbose) {
    Log::PrintErr(
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    char* error = Dart_SetVMFlags(1, &print_flags);
    ASSERT(error == NULL);
  }
}
// clang-format on

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

  if (help) {
    PrintUsage();
    Platform::Exit(0);
  } else if (version) {
    Log::PrintErr("Dart VM version: %s\n", Dart_VersionString());
    Platform::Exit(0);
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
    case kAppJIT: {
      if ((load_vm_snapshot_data_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL) ||
          ((isolate_snapshot_instructions_filename == NULL) &&
           (reused_instructions_filename == NULL))) {
        Log::PrintErr(
            "Building an app JIT snapshot requires specifying input files for "
            "--load_vm_snapshot_data and --load_vm_snapshot_instructions, an "
            " output file for --isolate_snapshot_data, and either an output "
            "file for --isolate_snapshot_instructions or an input file for "
            "--reused_instructions.\n\n");
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

static File* OpenFile(const char* filename) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
  if (file == NULL) {
    Log::PrintErr("Error: Unable to write file: %s\n\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  return file;
}

static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = OpenFile(filename);
  RefCntReleaseScope<File> rs(file);
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Unable to write file: %s\n\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
}

static void ReadFile(const char* filename, uint8_t** buffer, intptr_t* size) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    Log::PrintErr("Unable to open file %s\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
  RefCntReleaseScope<File> rs(file);
  *size = file->Length();
  *buffer = reinterpret_cast<uint8_t*>(malloc(*size));
  if (!file->ReadFully(*buffer, *size)) {
    Log::PrintErr("Unable to read file %s\n", filename);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
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
    RefCntReleaseScope<File> rs(file_);

    // Write dependencies for one of the output files.
    // TODO(https://github.com/ninja-build/ninja/issues/1184): Do this for all
    // output files.
    switch (snapshot_kind) {
      case kCore:
        WriteDependenciesWithTarget(vm_snapshot_data_filename);
        // WriteDependenciesWithTarget(isolate_snapshot_data_filename);
        break;
      case kAppAOTAssembly:
        WriteDependenciesWithTarget(assembly_filename);
        break;
      case kAppJIT:
        WriteDependenciesWithTarget(isolate_snapshot_data_filename);
        // WriteDependenciesWithTarget(isolate_snapshot_instructions_filename);
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
  }

 private:
  void WriteDependenciesWithTarget(const char* target) {
    WritePath(target);
    Write(": ");

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

  ASSERT(dependencies_filename != NULL);
  if (dependencies_filename != NULL) {
    DependenciesFileWriter writer;
    writer.WriteDependencies(dependencies);
  }

  for (intptr_t i = 0; i < dependencies->length(); i++) {
    free(dependencies->At(i));
  }
  dependencies->Clear();
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

static void LoadCompilationTrace() {
  if ((load_compilation_trace_filename != NULL) &&
      ((snapshot_kind == kCoreJIT) || (snapshot_kind == kAppJIT))) {
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

static std::unique_ptr<MappedMemory> MapFile(const char* filename,
                                             File::MapType type,
                                             const uint8_t** buffer) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    Log::PrintErr("Failed to open: %s\n", filename);
    exit(kErrorExitCode);
  }
  RefCntReleaseScope<File> rs(file);
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
  *buffer = reinterpret_cast<const uint8_t*>(mapping->address());
  return std::unique_ptr<MappedMemory>(mapping);
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

static void CreateAndWriteAppJITSnapshot() {
  ASSERT(snapshot_kind == kAppJIT);
  ASSERT(isolate_snapshot_data_filename != NULL);
  ASSERT((isolate_snapshot_instructions_filename != NULL) ||
         (reused_instructions_filename != NULL));

  const uint8_t* reused_instructions = NULL;
  std::unique_ptr<MappedMemory> mapped_reused_instructions;
  if (reused_instructions_filename != NULL) {
    mapped_reused_instructions = MapFile(reused_instructions_filename,
                                         File::kReadOnly, &reused_instructions);
  }

  Dart_Handle result;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  intptr_t isolate_snapshot_data_size = 0;
  uint8_t* isolate_snapshot_instructions_buffer = NULL;
  intptr_t isolate_snapshot_instructions_size = 0;

  result = Dart_CreateAppJITSnapshotAsBlobs(
      &isolate_snapshot_data_buffer, &isolate_snapshot_data_size,
      &isolate_snapshot_instructions_buffer,
      &isolate_snapshot_instructions_size, reused_instructions);
  CHECK_RESULT(result);

  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  if (reused_instructions_filename == NULL) {
    WriteFile(isolate_snapshot_instructions_filename,
              isolate_snapshot_instructions_buffer,
              isolate_snapshot_instructions_size);
  }
}

static void StreamingWriteCallback(void* callback_data,
                                   const uint8_t* buffer,
                                   intptr_t size) {
  File* file = reinterpret_cast<File*>(callback_data);
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Unable to write snapshot file\n\n");
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(kErrorExitCode);
  }
}

static void CreateAndWritePrecompiledSnapshot() {
  ASSERT(IsSnapshottingForPrecompilation());
  Dart_Handle result;

  // Precompile with specified embedder entry points
  result = Dart_Precompile();
  CHECK_RESULT(result);

  // Create a precompiled snapshot.
  bool as_assembly = assembly_filename != NULL;
  if (as_assembly) {
    ASSERT(snapshot_kind == kAppAOTAssembly);
    File* file = OpenFile(assembly_filename);
    RefCntReleaseScope<File> rs(file);
    result = Dart_CreateAppAOTSnapshotAsAssembly(StreamingWriteCallback, file);
    CHECK_RESULT(result);
  } else {
    ASSERT(snapshot_kind == kAppAOTBlobs);

    const uint8_t* shared_data = NULL;
    const uint8_t* shared_instructions = NULL;
    std::unique_ptr<MappedMemory> mapped_shared_data;
    std::unique_ptr<MappedMemory> mapped_shared_instructions;
    if (shared_data_filename != NULL) {
      mapped_shared_data =
          MapFile(shared_data_filename, File::kReadOnly, &shared_data);
    }
    if (shared_instructions_filename != NULL) {
      mapped_shared_instructions = MapFile(
          shared_instructions_filename, File::kReadOnly, &shared_instructions);
    }

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
        &isolate_snapshot_instructions_size, shared_data, shared_instructions);
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
                               isolate_snapshot_instructions, NULL, NULL, flags,
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
                        false /* server dev mode */, false /* trace_loading */,
                        true /* deterministic */)) {
    *error = strdup(VmService::GetErrorMessage());
    return NULL;
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}

static Dart_QualifiedFunctionName no_entry_points[] = {
    {NULL, NULL, NULL}  // Must be terminated with NULL entries.
};

static int GenerateSnapshotFromKernel(const uint8_t* kernel_buffer,
                                      intptr_t kernel_buffer_size) {
  char* error = NULL;
  IsolateData* isolate_data = new IsolateData(NULL, commandline_package_root,
                                              commandline_packages_file, NULL);
  if (dependencies_filename != NULL) {
    isolate_data->set_dependencies(new MallocGrowableArray<char*>());
  }

  Dart_IsolateFlags isolate_flags;
  Dart_IsolateFlagsInitialize(&isolate_flags);

  if (IsSnapshottingForPrecompilation()) {
    isolate_flags.obfuscate = obfuscate;
    isolate_flags.entry_points = no_entry_points;
  }

  Dart_Isolate isolate;
  if (isolate_snapshot_data == NULL) {
    // We need to capture the vmservice library in the core snapshot, so load it
    // in the main isolate as well.
    isolate_flags.load_vmservice_library = true;
    isolate = Dart_CreateIsolateFromKernel(NULL, NULL, kernel_buffer,
                                           kernel_buffer_size, &isolate_flags,
                                           isolate_data, &error);
  } else {
    isolate = Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                 isolate_snapshot_instructions, NULL, NULL,
                                 &isolate_flags, isolate_data, &error);
  }
  if (isolate == NULL) {
    delete isolate_data;
    Log::PrintErr("%s\n", error);
    free(error);
    return kErrorExitCode;
  }

  Dart_EnterScope();
  Dart_Handle result =
      Dart_SetEnvironmentCallback(DartUtils::EnvironmentCallback);
  CHECK_RESULT(result);

  // The root library has to be set to generate AOT snapshots, and sometimes we
  // set one for the core snapshot too.
  // If the input dill file has a root library, then Dart_LoadScript will
  // ignore this dummy uri and set the root library to the one reported in
  // the dill file. Since dill files are not dart script files,
  // trying to resolve the root library URI based on the dill file name
  // would not help.
  //
  // If the input dill file does not have a root library, then
  // Dart_LoadScript will error.
  //
  // TODO(kernel): Dart_CreateIsolateFromKernel should respect the root library
  // in the kernel file, though this requires auditing the other loading paths
  // in the embedders that had to work around this.
  result = Dart_SetRootLibrary(
      Dart_LoadLibraryFromKernel(kernel_buffer, kernel_buffer_size));
  CHECK_RESULT(result);

  switch (snapshot_kind) {
    case kAppAOTBlobs:
    case kAppAOTAssembly: {
      if (Dart_IsNull(Dart_RootLibrary())) {
        Log::PrintErr(
            "Unable to load root library from the input dill file.\n");
        return kErrorExitCode;
      }

      CreateAndWritePrecompiledSnapshot();

      CreateAndWriteDependenciesFile();

      break;
    }
    case kCore:
      CreateAndWriteCoreSnapshot();
      break;
    case kCoreJIT:
      LoadCompilationTrace();
      CreateAndWriteCoreJITSnapshot();
      break;
    case kAppJIT:
      LoadCompilationTrace();
      CreateAndWriteAppJITSnapshot();
      break;
    default:
      UNREACHABLE();
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
  const int EXTRA_VM_ARGUMENTS = 4;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);

  // Initialize the URL mapping array.
  CommandLineOptions cmdline_url_mapping(argc);
  DartUtils::url_mapping = &cmdline_url_mapping;

  // When running from the command line we assume that we are optimizing for
  // throughput, and therefore use a larger new gen semi space size and a faster
  // new gen growth factor unless others have been specified.
  if (kWordSize <= 4) {
    vm_options.AddArgument("--new_gen_semi_max_size=16");
  } else {
    vm_options.AddArgument("--new_gen_semi_max_size=32");
  }
  vm_options.AddArgument("--new_gen_growth_factor=4");

  // Parse command line arguments.
  if (ParseArguments(argc, argv, &vm_options, &app_script_name) < 0) {
    PrintUsage();
    return kErrorExitCode;
  }
  DartUtils::SetEnvironment(environment);

  // Sniff the script to check if it is actually a dill file.
  uint8_t* kernel_buffer = NULL;
  intptr_t kernel_buffer_size = NULL;
  if (app_script_name != NULL) {
    dfe.ReadScript(app_script_name, &kernel_buffer, &kernel_buffer_size);
  }
  if (kernel_buffer != NULL) {
    if (dependencies_filename != NULL) {
      Log::PrintErr("Depfiles are not supported in Dart 2.\n");
      return kErrorExitCode;
    }
  }

  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
    return kErrorExitCode;
  }
  Console::SaveConfig();
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
  if (snapshot_kind == kCoreJIT || snapshot_kind == kAppJIT) {
    vm_options.AddArgument("--fields_may_be_reset");
    vm_options.AddArgument("--link_natives_lazily");
#if !defined(PRODUCT)
    vm_options.AddArgument("--collect_code=false");
#endif
  }

  char* error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != NULL) {
    Log::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  // Initialize the Dart VM.
  // Note: We don't expect isolates to be created from dart code during
  // core library snapshot generation. However for the case when a full
  // snasphot is generated from a script (app_script_name != NULL) we will
  // need the service isolate to resolve URI and load code.

  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  if (app_script_name != NULL && kernel_buffer == NULL) {
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

  std::unique_ptr<MappedMemory> mapped_vm_snapshot_data;
  std::unique_ptr<MappedMemory> mapped_vm_snapshot_instructions;
  std::unique_ptr<MappedMemory> mapped_isolate_snapshot_data;
  std::unique_ptr<MappedMemory> mapped_isolate_snapshot_instructions;
  if (load_vm_snapshot_data_filename != NULL) {
    mapped_vm_snapshot_data =
        MapFile(load_vm_snapshot_data_filename, File::kReadOnly,
                &init_params.vm_snapshot_data);
  }
  if (load_vm_snapshot_instructions_filename != NULL) {
    mapped_vm_snapshot_instructions =
        MapFile(load_vm_snapshot_instructions_filename, File::kReadExecute,
                &init_params.vm_snapshot_instructions);
  }
  if (load_isolate_snapshot_data_filename) {
    mapped_isolate_snapshot_data =
        MapFile(load_isolate_snapshot_data_filename, File::kReadOnly,
                &isolate_snapshot_data);
  }
  if (load_isolate_snapshot_instructions_filename != NULL) {
    mapped_isolate_snapshot_instructions =
        MapFile(load_isolate_snapshot_instructions_filename, File::kReadExecute,
                &isolate_snapshot_instructions);
  }

  error = Dart_Initialize(&init_params);
  if (error != NULL) {
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  if (kernel_buffer != NULL) {
    return GenerateSnapshotFromKernel(kernel_buffer, kernel_buffer_size);
  }

  Dart_IsolateFlags flags;
  Dart_IsolateFlagsInitialize(&flags);

  IsolateData* isolate_data = new IsolateData(NULL, commandline_package_root,
                                              commandline_packages_file, NULL);
  Dart_Isolate isolate = Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                            isolate_snapshot_instructions, NULL,
                                            NULL, NULL, isolate_data, &error);
  if (isolate == NULL) {
    Log::PrintErr("Error: %s\n", error);
    free(error);
    exit(kErrorExitCode);
  }

  Dart_Handle result;
  Dart_Handle library;
  Dart_EnterScope();

  if (snapshot_kind == kVMAOTAssembly) {
    File* file = OpenFile(assembly_filename);
    RefCntReleaseScope<File> rs(file);
    result = Dart_CreateVMAOTSnapshotAsAssembly(StreamingWriteCallback, file);
    CHECK_RESULT(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return 0;
  }

  result = Dart_SetEnvironmentCallback(DartUtils::EnvironmentCallback);
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
    result = DartUtils::SetupPackageRoot(NULL, commandline_packages_file);
    CHECK_RESULT(result);

    UriResolverIsolateScope::isolate = isolate;
    Dart_ExitScope();
    Dart_ExitIsolate();

    // Now we create an isolate into which we load all the code that needs to
    // be in the snapshot.
    isolate_data = new IsolateData(app_script_name, commandline_package_root,
                                   commandline_packages_file, NULL);
    if (dependencies_filename != NULL) {
      isolate_data->set_dependencies(new MallocGrowableArray<char*>());
    }

    if (IsSnapshottingForPrecompilation()) {
      flags.obfuscate = obfuscate;
      flags.entry_points = no_entry_points;
    }

    Dart_Isolate isolate = NULL;
    isolate = Dart_CreateIsolate(NULL, NULL, isolate_snapshot_data,
                                 isolate_snapshot_instructions, NULL, NULL,
                                 &flags, isolate_data, &error);
    if (isolate == NULL) {
      Log::PrintErr("%s\n", error);
      free(error);
      exit(kErrorExitCode);
    }
    Dart_EnterScope();
    result = Dart_SetEnvironmentCallback(DartUtils::EnvironmentCallback);
    CHECK_RESULT(result);

    // Set up the library tag handler in such a manner that it will use the
    // URL mapping specified on the command line to load the libraries.
    result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
    CHECK_RESULT(result);

    if (commandline_packages_file != NULL) {
      AddDependency(commandline_packages_file);
    }

    ASSERT(kernel_buffer == NULL);

    // Load the specified script.
    library = LoadSnapshotCreationScript(app_script_name);
    CHECK_RESULT(library);

    // Ensure that we mark all libraries as loaded.
    result = Dart_FinalizeLoading(false);
    CHECK_RESULT(result);

    LoadCompilationTrace();

    switch (snapshot_kind) {
      case kCore:
        CreateAndWriteCoreSnapshot();
        break;
      case kCoreJIT:
        CreateAndWriteCoreJITSnapshot();
        break;
      case kAppJIT:
        CreateAndWriteAppJITSnapshot();
        break;
      case kAppAOTBlobs:
      case kAppAOTAssembly:
        CreateAndWritePrecompiledSnapshot();
        break;
      default:
        UNREACHABLE();
    }

    CreateAndWriteDependenciesFile();

    Dart_ExitScope();
    Dart_ShutdownIsolate();

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
      case kAppJIT:
        CreateAndWriteAppJITSnapshot();
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
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  return dart::bin::main(argc, argv);
}

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
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/loader.h"
#include "bin/options.h"
#include "bin/platform.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"
#include "platform/syslog.h"
#include "platform/text_buffer.h"

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
    Syslog::PrintErr("Error: %s\n", Dart_GetError(result));                    \
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

// The environment provided through the command line using -D options.
static dart::SimpleHashMap* environment = NULL;

static bool ProcessEnvironmentOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &environment);
}

// The core snapshot to use when creating isolates. Normally NULL, but loaded
// from a file when creating AppJIT snapshots.
const uint8_t* isolate_snapshot_data = NULL;
const uint8_t* isolate_snapshot_instructions = NULL;

// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into. The ordering of this list must
// match kSnapshotKindNames below.
enum SnapshotKind {
  kCore,
  kCoreJIT,
  kApp,
  kAppJIT,
  kAppAOTAssembly,
  kAppAOTElf,
  kVMAOTAssembly,
};
static SnapshotKind snapshot_kind = kCore;

// The ordering of this list must match the SnapshotKind enum above.
static const char* kSnapshotKindNames[] = {
    // clang-format off
    "core",
    "core-jit",
    "app",
    "app-jit",
    "app-aot-assembly",
    "app-aot-elf",
    "vm-aot-assembly",
    NULL,
    // clang-format on
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
  V(blobs_container_filename, blobs_container_filename)                        \
  V(assembly, assembly_filename)                                               \
  V(elf, elf_filename)                                                         \
  V(loading_unit_manifest, loading_unit_manifest_filename)                     \
  V(load_compilation_trace, load_compilation_trace_filename)                   \
  V(load_type_feedback, load_type_feedback_filename)                           \
  V(save_debugging_info, debugging_info_filename)                              \
  V(save_obfuscation_map, obfuscation_map_filename)

#define BOOL_OPTIONS_LIST(V)                                                   \
  V(compile_all, compile_all)                                                  \
  V(help, help)                                                                \
  V(obfuscate, obfuscate)                                                      \
  V(strip, strip)                                                              \
  V(verbose, verbose)                                                          \
  V(version, version)

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
DEFINE_CB_OPTION(ProcessEnvironmentOption);

static bool IsSnapshottingForPrecompilation() {
  return (snapshot_kind == kAppAOTAssembly) || (snapshot_kind == kAppAOTElf) ||
         (snapshot_kind == kVMAOTAssembly);
}

// clang-format off
static void PrintUsage() {
  Syslog::PrintErr(
"Usage: gen_snapshot [<vm-flags>] [<options>] <dart-kernel-file>             \n"
"                                                                            \n"
"Common options:                                                             \n"
"--help                                                                      \n"
"  Display this message (add --verbose for information about all VM options).\n"
"--version                                                                   \n"
"  Print the SDK version.                                                    \n"
"                                                                            \n"
"To create a core snapshot:                                                  \n"
"--snapshot_kind=core                                                        \n"
"--vm_snapshot_data=<output-file>                                            \n"
"--isolate_snapshot_data=<output-file>                                       \n"
"<dart-kernel-file>                                                          \n"
"                                                                            \n"
"To create an AOT application snapshot as assembly suitable for compilation  \n"
"as a static or dynamic library:                                             \n"
"--snapshot_kind=app-aot-assembly                                            \n"
"--assembly=<output-file>                                                    \n"
"[--strip]                                                                   \n"
"[--obfuscate]                                                               \n"
"[--save-debugging-info=<debug-filename>]                                    \n"
"[--save-obfuscation-map=<map-filename>]                                     \n"
"<dart-kernel-file>                                                          \n"
"                                                                            \n"
"To create an AOT application snapshot as an ELF shared library:             \n"
"--snapshot_kind=app-aot-elf                                                 \n"
"--elf=<output-file>                                                         \n"
"[--strip]                                                                   \n"
"[--obfuscate]                                                               \n"
"[--save-debugging-info=<debug-filename>]                                    \n"
"[--save-obfuscation-map=<map-filename>]                                     \n"
"<dart-kernel-file>                                                          \n"
"                                                                            \n"
"AOT snapshots can be obfuscated: that is all identifiers will be renamed    \n"
"during compilation. This mode is enabled with --obfuscate flag. Mapping     \n"
"between original and obfuscated names can be serialized as a JSON array     \n"
"using --save-obfuscation-map=<filename> option. See dartbug.com/30524       \n"
"for implementation details and limitations of the obfuscation pass.         \n"
"                                                                            \n"
"\n");
  if (verbose) {
    Syslog::PrintErr(
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
                          CommandLineOptions* inputs) {
  // Skip the binary name.
  int i = 1;

  // Parse out the vm options.
  while ((i < argc) && OptionProcessor::IsValidShortFlag(argv[i])) {
    if (OptionProcessor::TryProcess(argv[i], vm_options)) {
      i += 1;
      continue;
    }
    vm_options->AddArgument(argv[i]);
    i += 1;
  }

  // Parse out the kernel inputs.
  while (i < argc) {
    inputs->AddArgument(argv[i]);
    i++;
  }

  if (help) {
    PrintUsage();
    Platform::Exit(0);
  } else if (version) {
    Syslog::PrintErr("Dart SDK version: %s\n", Dart_VersionString());
    Platform::Exit(0);
  }

  // Verify consistency of arguments.
  if (inputs->count() < 1) {
    Syslog::PrintErr("At least one input is required\n");
    return -1;
  }

  switch (snapshot_kind) {
    case kCore: {
      if ((vm_snapshot_data_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL)) {
        Syslog::PrintErr(
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
        Syslog::PrintErr(
            "Building a core JIT snapshot requires specifying output "
            "files for --vm_snapshot_data, --vm_snapshot_instructions, "
            "--isolate_snapshot_data and --isolate_snapshot_instructions.\n\n");
        return -1;
      }
      break;
    }
    case kApp:
    case kAppJIT: {
      if ((load_vm_snapshot_data_filename == NULL) ||
          (isolate_snapshot_data_filename == NULL) ||
          (isolate_snapshot_instructions_filename == NULL)) {
        Syslog::PrintErr(
            "Building an app JIT snapshot requires specifying input files for "
            "--load_vm_snapshot_data and --load_vm_snapshot_instructions, an "
            " output file for --isolate_snapshot_data, and an output "
            "file for --isolate_snapshot_instructions.\n\n");
        return -1;
      }
      break;
    }
    case kAppAOTElf: {
      if (elf_filename == NULL) {
        Syslog::PrintErr(
            "Building an AOT snapshot as ELF requires specifying "
            "an output file for --elf.\n\n");
        return -1;
      }
      break;
    }
    case kAppAOTAssembly:
    case kVMAOTAssembly: {
      if (assembly_filename == NULL) {
        Syslog::PrintErr(
            "Building an AOT snapshot as assembly requires specifying "
            "an output file for --assembly.\n\n");
        return -1;
      }
      break;
    }
  }

  if (!obfuscate && obfuscation_map_filename != NULL) {
    Syslog::PrintErr(
        "--save-obfuscation_map=<...> should only be specified when "
        "obfuscation is enabled by the --obfuscate flag.\n\n");
    return -1;
  }

  if (!IsSnapshottingForPrecompilation()) {
    if (obfuscate) {
      Syslog::PrintErr(
          "Obfuscation can only be enabled when building an AOT snapshot.\n\n");
      return -1;
    }

    if (debugging_info_filename != nullptr) {
      Syslog::PrintErr(
          "--save-debugging-info=<...> can only be enabled when building an "
          "AOT snapshot.\n\n");
      return -1;
    }

    if (strip) {
      Syslog::PrintErr(
          "Stripping can only be enabled when building an AOT snapshot.\n\n");
      return -1;
    }
  }

  return 0;
}

PRINTF_ATTRIBUTE(1, 2) static void PrintErrAndExit(const char* format, ...) {
  va_list args;
  va_start(args, format);
  Syslog::VPrintErr(format, args);
  va_end(args);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
  exit(kErrorExitCode);
}

static File* OpenFile(const char* filename) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
  if (file == NULL) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n", filename);
  }
  return file;
}

static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = OpenFile(filename);
  RefCntReleaseScope<File> rs(file);
  if (!file->WriteFully(buffer, size)) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n", filename);
  }
}

static void ReadFile(const char* filename, uint8_t** buffer, intptr_t* size) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    PrintErrAndExit("Error: Unable to read file: %s\n", filename);
  }
  RefCntReleaseScope<File> rs(file);
  *size = file->Length();
  *buffer = reinterpret_cast<uint8_t*>(malloc(*size));
  if (!file->ReadFully(*buffer, *size)) {
    PrintErrAndExit("Error: Unable to read file: %s\n", filename);
  }
}

static void MaybeLoadExtraInputs(const CommandLineOptions& inputs) {
  for (intptr_t i = 1; i < inputs.count(); i++) {
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    ReadFile(inputs.GetArgument(i), &buffer, &size);
    Dart_Handle result = Dart_LoadLibraryFromKernel(buffer, size);
    CHECK_RESULT(result);
  }
}

static void MaybeLoadCode() {
  if (compile_all &&
      ((snapshot_kind == kCoreJIT) || (snapshot_kind == kAppJIT))) {
    Dart_Handle result = Dart_CompileAll();
    CHECK_RESULT(result);
  }

  if ((load_compilation_trace_filename != NULL) &&
      ((snapshot_kind == kCoreJIT) || (snapshot_kind == kAppJIT))) {
    // Finalize all classes. This ensures that there are no non-finalized
    // classes in the gaps between cid ranges. Such classes prevent merging of
    // cid ranges.
    Dart_Handle result = Dart_FinalizeAllClasses();
    CHECK_RESULT(result);
    // Sort classes to have better cid ranges.
    result = Dart_SortClasses();
    CHECK_RESULT(result);
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    ReadFile(load_compilation_trace_filename, &buffer, &size);
    result = Dart_LoadCompilationTrace(buffer, size);
    free(buffer);
    CHECK_RESULT(result);
  }

  if ((load_type_feedback_filename != NULL) &&
      ((snapshot_kind == kCoreJIT) || (snapshot_kind == kAppJIT))) {
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    ReadFile(load_type_feedback_filename, &buffer, &size);
    Dart_Handle result = Dart_LoadTypeFeedback(buffer, size);
    free(buffer);
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
                               &isolate_snapshot_data_size,
                               /*is_core=*/true);
  CHECK_RESULT(result);

  // Now write the vm isolate and isolate snapshots out to the
  // specified file and exit.
  WriteFile(vm_snapshot_data_filename, vm_snapshot_data_buffer,
            vm_snapshot_data_size);
  if (vm_snapshot_instructions_filename != NULL) {
    // Create empty file for the convenience of build systems. Makes things
    // polymorphic with generating core-jit snapshots.
    WriteFile(vm_snapshot_instructions_filename, NULL, 0);
  }
  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  if (isolate_snapshot_instructions_filename != NULL) {
    // Create empty file for the convenience of build systems. Makes things
    // polymorphic with generating core-jit snapshots.
    WriteFile(isolate_snapshot_instructions_filename, NULL, 0);
  }
}

static std::unique_ptr<MappedMemory> MapFile(const char* filename,
                                             File::MapType type,
                                             const uint8_t** buffer) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    Syslog::PrintErr("Failed to open: %s\n", filename);
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
    Syslog::PrintErr("Failed to read: %s\n", filename);
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

static void CreateAndWriteAppSnapshot() {
  ASSERT(snapshot_kind == kApp);
  ASSERT(isolate_snapshot_data_filename != NULL);

  Dart_Handle result;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  intptr_t isolate_snapshot_data_size = 0;

  result = Dart_CreateSnapshot(NULL, NULL, &isolate_snapshot_data_buffer,
                               &isolate_snapshot_data_size, /*is_core=*/false);
  CHECK_RESULT(result);

  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  if (isolate_snapshot_instructions_filename != NULL) {
    // Create empty file for the convenience of build systems. Makes things
    // polymorphic with generating core-jit snapshots.
    WriteFile(isolate_snapshot_instructions_filename, NULL, 0);
  }
}

static void CreateAndWriteAppJITSnapshot() {
  ASSERT(snapshot_kind == kAppJIT);
  ASSERT(isolate_snapshot_data_filename != NULL);
  ASSERT(isolate_snapshot_instructions_filename != NULL);

  Dart_Handle result;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  intptr_t isolate_snapshot_data_size = 0;
  uint8_t* isolate_snapshot_instructions_buffer = NULL;
  intptr_t isolate_snapshot_instructions_size = 0;

  result = Dart_CreateAppJITSnapshotAsBlobs(
      &isolate_snapshot_data_buffer, &isolate_snapshot_data_size,
      &isolate_snapshot_instructions_buffer,
      &isolate_snapshot_instructions_size);
  CHECK_RESULT(result);

  WriteFile(isolate_snapshot_data_filename, isolate_snapshot_data_buffer,
            isolate_snapshot_data_size);
  WriteFile(isolate_snapshot_instructions_filename,
            isolate_snapshot_instructions_buffer,
            isolate_snapshot_instructions_size);
}

static void StreamingWriteCallback(void* callback_data,
                                   const uint8_t* buffer,
                                   intptr_t size) {
  File* file = reinterpret_cast<File*>(callback_data);
  if ((file != nullptr) && !file->WriteFully(buffer, size)) {
    PrintErrAndExit("Error: Unable to write snapshot file\n\n");
  }
}

static void StreamingCloseCallback(void* callback_data) {
  File* file = reinterpret_cast<File*>(callback_data);
  file->Release();
}

static File* OpenLoadingUnitManifest() {
  File* manifest_file = OpenFile(loading_unit_manifest_filename);
  if (!manifest_file->Print("{ \"loadingUnits\": [\n")) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n",
                    loading_unit_manifest_filename);
  }
  return manifest_file;
}

static void WriteLoadingUnitManifest(File* manifest_file,
                                     intptr_t id,
                                     const char* path) {
  TextBuffer line(128);
  if (id != 1) {
    line.AddString(",\n");
  }
  line.Printf("{ \"id\": %" Pd ", \"path\": \"", id);
  line.AddEscapedString(path);
  line.AddString("\", \"libraries\": [\n");
  Dart_Handle uris = Dart_LoadingUnitLibraryUris(id);
  CHECK_RESULT(uris);
  intptr_t length;
  CHECK_RESULT(Dart_ListLength(uris, &length));
  for (intptr_t i = 0; i < length; i++) {
    const char* uri;
    CHECK_RESULT(Dart_StringToCString(Dart_ListGetAt(uris, i), &uri));
    if (i != 0) {
      line.AddString(",\n");
    }
    line.AddString("\"");
    line.AddEscapedString(uri);
    line.AddString("\"");
  }
  line.AddString("]}");
  if (!manifest_file->Print("%s\n", line.buffer())) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n",
                    loading_unit_manifest_filename);
  }
}

static void CloseLoadingUnitManifest(File* manifest_file) {
  if (!manifest_file->Print("] }\n")) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n",
                    loading_unit_manifest_filename);
  }
  manifest_file->Release();
}

static void NextLoadingUnit(void* callback_data,
                            intptr_t loading_unit_id,
                            void** write_callback_data,
                            void** write_debug_callback_data,
                            const char* main_filename,
                            const char* suffix) {
  char* filename = loading_unit_id == 1
                       ? Utils::StrDup(main_filename)
                       : Utils::SCreate("%s-%" Pd ".part.%s", main_filename,
                                        loading_unit_id, suffix);
  File* file = OpenFile(filename);
  *write_callback_data = file;

  if (debugging_info_filename != nullptr) {
    char* debug_filename =
        loading_unit_id == 1
            ? Utils::StrDup(debugging_info_filename)
            : Utils::SCreate("%s-%" Pd ".part.so", debugging_info_filename,
                             loading_unit_id);
    File* debug_file = OpenFile(debug_filename);
    *write_debug_callback_data = debug_file;
    free(debug_filename);
  }

  WriteLoadingUnitManifest(reinterpret_cast<File*>(callback_data),
                           loading_unit_id, filename);

  free(filename);
}

static void NextAsmCallback(void* callback_data,
                            intptr_t loading_unit_id,
                            void** write_callback_data,
                            void** write_debug_callback_data) {
  NextLoadingUnit(callback_data, loading_unit_id, write_callback_data,
                  write_debug_callback_data, assembly_filename, "S");
}

static void NextElfCallback(void* callback_data,
                            intptr_t loading_unit_id,
                            void** write_callback_data,
                            void** write_debug_callback_data) {
  NextLoadingUnit(callback_data, loading_unit_id, write_callback_data,
                  write_debug_callback_data, elf_filename, "so");
}

static void CreateAndWritePrecompiledSnapshot() {
  ASSERT(IsSnapshottingForPrecompilation());
  Dart_Handle result;

  // Precompile with specified embedder entry points
  result = Dart_Precompile();
  CHECK_RESULT(result);

  // Create a precompiled snapshot.
  if (snapshot_kind == kAppAOTAssembly) {
    if (strip && (debugging_info_filename == nullptr)) {
      Syslog::PrintErr(
          "Warning: Generating assembly code without DWARF debugging"
          " information.\n");
    }
    if (loading_unit_manifest_filename == nullptr) {
      File* file = OpenFile(assembly_filename);
      RefCntReleaseScope<File> rs(file);
      File* debug_file = nullptr;
      if (debugging_info_filename != nullptr) {
        debug_file = OpenFile(debugging_info_filename);
      }
      result = Dart_CreateAppAOTSnapshotAsAssembly(StreamingWriteCallback, file,
                                                   strip, debug_file);
      if (debug_file != nullptr) debug_file->Release();
      CHECK_RESULT(result);
    } else {
      File* manifest_file = OpenLoadingUnitManifest();
      result = Dart_CreateAppAOTSnapshotAsAssemblies(
          NextAsmCallback, manifest_file, strip, StreamingWriteCallback,
          StreamingCloseCallback);
      CHECK_RESULT(result);
      CloseLoadingUnitManifest(manifest_file);
    }
    if (obfuscate && !strip) {
      Syslog::PrintErr(
          "Warning: The generated assembly code contains unobfuscated DWARF "
          "debugging information.\n"
          "         To avoid this, use --strip to remove it.\n");
    }
  } else if (snapshot_kind == kAppAOTElf) {
    if (strip && (debugging_info_filename == nullptr)) {
      Syslog::PrintErr(
          "Warning: Generating ELF library without DWARF debugging"
          " information.\n");
    }
    if (loading_unit_manifest_filename == nullptr) {
      File* file = OpenFile(elf_filename);
      RefCntReleaseScope<File> rs(file);
      File* debug_file = nullptr;
      if (debugging_info_filename != nullptr) {
        debug_file = OpenFile(debugging_info_filename);
      }
      result = Dart_CreateAppAOTSnapshotAsElf(StreamingWriteCallback, file,
                                              strip, debug_file);
      if (debug_file != nullptr) debug_file->Release();
      CHECK_RESULT(result);
    } else {
      File* manifest_file = OpenLoadingUnitManifest();
      result = Dart_CreateAppAOTSnapshotAsElfs(NextElfCallback, manifest_file,
                                               strip, StreamingWriteCallback,
                                               StreamingCloseCallback);
      CHECK_RESULT(result);
      CloseLoadingUnitManifest(manifest_file);
    }
    if (obfuscate && !strip) {
      Syslog::PrintErr(
          "Warning: The generated ELF library contains unobfuscated DWARF "
          "debugging information.\n"
          "         To avoid this, use --strip to remove it and "
          "--save-debugging-info=<...> to save it to a separate file.\n");
    }
  } else {
    UNREACHABLE();
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

static Dart_QualifiedFunctionName no_entry_points[] = {
    {NULL, NULL, NULL}  // Must be terminated with NULL entries.
};

static int CreateIsolateAndSnapshot(const CommandLineOptions& inputs) {
  uint8_t* kernel_buffer = NULL;
  intptr_t kernel_buffer_size = 0;
  ReadFile(inputs.GetArgument(0), &kernel_buffer, &kernel_buffer_size);

  Dart_IsolateFlags isolate_flags;
  Dart_IsolateFlagsInitialize(&isolate_flags);
  isolate_flags.null_safety =
      Dart_DetectNullSafety(nullptr, nullptr, nullptr, nullptr, nullptr,
                            kernel_buffer, kernel_buffer_size);
  if (IsSnapshottingForPrecompilation()) {
    isolate_flags.obfuscate = obfuscate;
    isolate_flags.entry_points = no_entry_points;
  }

  auto isolate_group_data = std::unique_ptr<IsolateGroupData>(
      new IsolateGroupData(nullptr, nullptr, nullptr, false));
  Dart_Isolate isolate;
  char* error = NULL;

  bool loading_kernel_failed = false;
  if (isolate_snapshot_data == NULL) {
    // We need to capture the vmservice library in the core snapshot, so load it
    // in the main isolate as well.
    isolate_flags.load_vmservice_library = true;
    isolate = Dart_CreateIsolateGroupFromKernel(
        NULL, NULL, kernel_buffer, kernel_buffer_size, &isolate_flags,
        isolate_group_data.get(), /*isolate_data=*/nullptr, &error);
    loading_kernel_failed = (isolate == nullptr);
  } else {
    isolate = Dart_CreateIsolateGroup(NULL, NULL, isolate_snapshot_data,
                                      isolate_snapshot_instructions,
                                      &isolate_flags, isolate_group_data.get(),
                                      /*isolate_data=*/nullptr, &error);
  }
  if (isolate == NULL) {
    Syslog::PrintErr("%s\n", error);
    free(error);
    free(kernel_buffer);
    // The only real reason when `gen_snapshot` fails to create an isolate from
    // a valid kernel file is if loading the kernel results in a "compile-time"
    // error.
    //
    // There are other possible reasons, like memory allocation failures, but
    // those are very uncommon.
    //
    // The Dart API doesn't allow us to distinguish the different error cases,
    // so we'll use [kCompilationErrorExitCode] for failed kernel loading, since
    // a compile-time error is the most probable cause.
    return loading_kernel_failed ? kCompilationErrorExitCode : kErrorExitCode;
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
  // TODO(kernel): Dart_CreateIsolateGroupFromKernel should respect the root
  // library in the kernel file, though this requires auditing the other
  // loading paths in the embedders that had to work around this.
  result = Dart_SetRootLibrary(
      Dart_LoadLibraryFromKernel(kernel_buffer, kernel_buffer_size));
  CHECK_RESULT(result);

  MaybeLoadExtraInputs(inputs);

  MaybeLoadCode();

  switch (snapshot_kind) {
    case kCore:
      CreateAndWriteCoreSnapshot();
      break;
    case kCoreJIT:
      CreateAndWriteCoreJITSnapshot();
      break;
    case kApp:
      CreateAndWriteAppSnapshot();
      break;
    case kAppJIT:
      CreateAndWriteAppJITSnapshot();
      break;
    case kAppAOTAssembly:
    case kAppAOTElf:
      CreateAndWritePrecompiledSnapshot();
      break;
    case kVMAOTAssembly: {
      File* file = OpenFile(assembly_filename);
      RefCntReleaseScope<File> rs(file);
      result = Dart_CreateVMAOTSnapshotAsAssembly(StreamingWriteCallback, file);
      CHECK_RESULT(result);
      break;
    }
    default:
      UNREACHABLE();
  }

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  free(kernel_buffer);
  return 0;
}

int main(int argc, char** argv) {
  const int EXTRA_VM_ARGUMENTS = 7;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions inputs(argc);

  // When running from the command line we assume that we are optimizing for
  // throughput, and therefore use a larger new gen semi space size and a faster
  // new gen growth factor unless others have been specified.
  if (kWordSize <= 4) {
    vm_options.AddArgument("--new_gen_semi_max_size=16");
  } else {
    vm_options.AddArgument("--new_gen_semi_max_size=32");
  }
  vm_options.AddArgument("--new_gen_growth_factor=4");
  vm_options.AddArgument("--deterministic");

  // Parse command line arguments.
  if (ParseArguments(argc, argv, &vm_options, &inputs) < 0) {
    PrintUsage();
    return kErrorExitCode;
  }
  DartUtils::SetEnvironment(environment);

  if (!Platform::Initialize()) {
    Syslog::PrintErr("Initialization failed\n");
    return kErrorExitCode;
  }
  Console::SaveConfig();
  Loader::InitOnce();
  DartUtils::SetOriginalWorkingDirectory();
  // Start event handler.
  TimerUtils::InitOnce();
  EventHandler::Start();

  if (IsSnapshottingForPrecompilation()) {
    vm_options.AddArgument("--precompilation");
  } else if ((snapshot_kind == kCoreJIT) || (snapshot_kind == kAppJIT)) {
    vm_options.AddArgument("--fields_may_be_reset");
#if !defined(TARGET_ARCH_IA32)
    vm_options.AddArgument("--link_natives_lazily");
#endif
  }

  char* error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != NULL) {
    Syslog::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
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
  if (load_isolate_snapshot_data_filename != nullptr) {
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
    Syslog::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  int result = CreateIsolateAndSnapshot(inputs);
  if (result != 0) {
    return result;
  }

  error = Dart_Cleanup();
  if (error != NULL) {
    Syslog::PrintErr("VM cleanup failed: %s\n", error);
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

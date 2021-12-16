// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/elf_loader.h"
#include "bin/error_exit.h"
#include "bin/file.h"

#include "bin/options.h"
#include "bin/platform.h"

#include "include/analyze_snapshot_api.h"

namespace dart {
namespace bin {

#define STRING_OPTIONS_LIST(V) V(out, out_path)

#define BOOL_OPTIONS_LIST(V)                                                   \
  V(help, help)                                                                \
  V(version, version)

#define STRING_OPTION_DEFINITION(flag, variable)                               \
  static const char* variable = nullptr;                                       \
  DEFINE_STRING_OPTION(flag, variable)
STRING_OPTIONS_LIST(STRING_OPTION_DEFINITION)
#undef STRING_OPTION_DEFINITION

#define BOOL_OPTION_DEFINITION(flag, variable)                                 \
  static bool variable = false;                                                \
  DEFINE_BOOL_OPTION(flag, variable)
BOOL_OPTIONS_LIST(BOOL_OPTION_DEFINITION)
#undef BOOL_OPTION_DEFINITION

// clang-format off
static void PrintUsage() {
  Syslog::PrintErr(
"Usage: analyze_snapshot [<vm-flags>] [<options>] <snapshot_data>            \n"
"                                                                            \n"
"Common options:                                                             \n"
"--help                                                                      \n"
"  Display this message.                                                     \n"
"--version                                                                   \n"
"  Print the SDK version.                                                    \n"
"--out                                                                       \n"
"  Path to generate the analysis results JSON.                               \n"
"                                                                            \n"
"If omitting [<vm-flags>] the VM parsing the snapshot is created with the    \n"
"following default flags:                                                    \n"
"--enable_mirrors=false                                                      \n"
"--background_compilation                                                    \n"
"--lazy_async_stacks                                                         \n"
"--precompilation                                                            \n"
"                                                                            \n"
"\n");
}
// clang-format on

const uint8_t* vm_snapshot_data = nullptr;
const uint8_t* vm_snapshot_instructions = nullptr;
const uint8_t* vm_isolate_data = nullptr;
const uint8_t* vm_isolate_instructions = nullptr;

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

  if (out_path == nullptr) {
    Syslog::PrintErr(
        "Please specify an output path for analysis with the --out flag.\n\n");
    return -1;
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
  File* file = File::Open(nullptr, filename, File::kWriteTruncate);
  if (file == nullptr) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n", filename);
  }
  return file;
}

static void WriteFile(const char* filename,
                      const char* buffer,
                      const intptr_t size) {
  File* file = OpenFile(filename);
  RefCntReleaseScope<File> rs(file);
  if (!file->WriteFully(buffer, size)) {
    PrintErrAndExit("Error: Unable to write file: %s\n\n", filename);
  }
}

int RunAnalyzer(int argc, char** argv) {
  // Constant mirrors gen_snapshot binary, subject to change.
  const int EXTRA_VM_ARGUMENTS = 7;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions inputs(argc);
  // Parse command line arguments.
  if (ParseArguments(argc, argv, &vm_options, &inputs) < 0) {
    PrintUsage();
    return kErrorExitCode;
  }

  // Initialize VM with default flags if none are provided.
  // TODO(#47924): Implement auto-parsing of flags from the snapshot file.
  if (vm_options.count() == 0) {
    vm_options.AddArgument("--enable_mirrors=false");
    vm_options.AddArgument("--background_compilation");
    vm_options.AddArgument("--lazy_async_stacks");
    vm_options.AddArgument("--precompilation");
  }

  char* error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != nullptr) {
    Syslog::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  // Dart_LoadELF will crash on nonexistant file non-gracefully
  // even though it should return `nullptr`.
  File* const file =
      File::Open(/*namespc=*/nullptr, inputs.GetArgument(0), File::kRead);
  if (file == nullptr) {
    Syslog::PrintErr("Snapshot file does not exist\n");
    return kErrorExitCode;
  }
  file->Release();

  const char* loader_error = nullptr;
  Dart_LoadedElf* loaded_elf = Dart_LoadELF(
      inputs.GetArgument(0), 0, &loader_error, &vm_snapshot_data,
      &vm_snapshot_instructions, &vm_isolate_data, &vm_isolate_instructions);

  if (loaded_elf == nullptr) {
    Syslog::PrintErr("Failure calling Dart_LoadELF:\n%s\n", loader_error);
    return kErrorExitCode;
  }

  // Begin initialization
  Dart_InitializeParams init_params = {};
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  init_params.vm_snapshot_data = vm_snapshot_data;
  init_params.vm_snapshot_instructions = vm_snapshot_instructions;

  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;

  error = Dart_Initialize(&init_params);
  if (error != nullptr) {
    Syslog::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  auto isolate_group_data = std::unique_ptr<IsolateGroupData>(
      new IsolateGroupData(nullptr, nullptr, nullptr, false));

  Dart_IsolateFlags isolate_flags;
  Dart_IsolateFlagsInitialize(&isolate_flags);
  // Null safety can be determined from the snapshot itself
  isolate_flags.null_safety =
      Dart_DetectNullSafety(nullptr, nullptr, nullptr, vm_snapshot_data,
                            vm_snapshot_instructions, nullptr, -1);

  Dart_CreateIsolateGroup(nullptr, nullptr, vm_isolate_data,
                          vm_isolate_instructions, &isolate_flags,
                          isolate_group_data.get(),
                          /*isolate_data=*/nullptr, &error);

  if (error != nullptr) {
    Syslog::PrintErr("Dart_CreateIsolateGroup Error: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  dart::snapshot_analyzer::Dart_SnapshotAnalyzerInformation info = {
      vm_snapshot_data, vm_snapshot_instructions, vm_isolate_data,
      vm_isolate_instructions};

  char* out = NULL;
  intptr_t out_len = 0;

  Dart_EnterScope();
  Dart_DumpSnapshotInformationAsJson(&out, &out_len, &info);
  WriteFile(out_path, out, out_len);
  // Since ownership of the JSON buffer is ours, free before we exit.
  free(out);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  return 0;
}
}  // namespace bin
}  // namespace dart
int main(int argc, char** argv) {
  return dart::bin::RunAnalyzer(argc, argv);
}

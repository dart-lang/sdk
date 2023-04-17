// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/elf_loader.h"
#include "bin/error_exit.h"
#include "bin/file.h"

#include "bin/options.h"
#include "bin/platform.h"

#if defined(TARGET_ARCH_IS_64_BIT) && defined(DART_PRECOMPILED_RUNTIME) &&     \
    (defined(DART_TARGET_OS_ANDROID) || defined(DART_TARGET_OS_LINUX))
#define SUPPORT_ANALYZE_SNAPSHOT
#endif

#ifdef SUPPORT_ANALYZE_SNAPSHOT
#include "include/analyze_snapshot_api.h"
#endif

namespace dart {
namespace bin {
#ifdef SUPPORT_ANALYZE_SNAPSHOT
#define STRING_OPTIONS_LIST(V) V(out, out_path)

#define BOOL_OPTIONS_LIST(V)                                                   \
  V(help, help)                                                                \
  V(sdk_version, sdk_version)                                                  \
  V(pp, pp)

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
"--sdk_version                                                               \n"
"  Print the SDK version.                                                    \n"
"--out                                                                       \n"
"  Path to generate the analysis results JSON.                               \n"
"--pp                                                                        \n"
"  Flag to pretty-print analysis to stdout.                                  \n"
"If omitting [<vm-flags>] the VM parsing the snapshot is created with the    \n"
"following default flags:                                                    \n"
"--enable_mirrors=false                                                      \n"
"--background_compilation                                                    \n"
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

  // Parse out remaining inputs.
  while (i < argc) {
    inputs->AddArgument(argv[i]);
    i++;
  }

  if (help) {
    PrintUsage();
    Platform::Exit(0);
  } else if (sdk_version) {
    Syslog::PrintErr("Dart SDK version: %s\n", Dart_VersionString());
    Platform::Exit(0);
  }

  // Verify consistency of arguments.
  if (inputs->count() < 1) {
    Syslog::PrintErr("At least one input is required\n");
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
    vm_options.AddArgument("--precompilation");
  }

  char* error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != nullptr) {
    Syslog::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    return kErrorExitCode;
  }

  const char* script_name = nullptr;
  script_name = inputs.GetArgument(0);

  // Dart_LoadELF will crash on nonexistent file non-gracefully
  // even though it should return `nullptr`.
  File* const file = File::Open(/*namespc=*/nullptr, script_name, File::kRead);
  if (file == nullptr) {
    Syslog::PrintErr("Snapshot file does not exist\n");
    return kErrorExitCode;
  }
  file->Release();

  const char* loader_error = nullptr;
  Dart_LoadedElf* loaded_elf = Dart_LoadELF(
      script_name, 0, &loader_error, &vm_snapshot_data,
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

  char* out = nullptr;
  intptr_t out_len = 0;

  Dart_EnterScope();
  if (out_path != nullptr) {
    Dart_DumpSnapshotInformationAsJson(&out, &out_len, &info);
    WriteFile(out_path, out, out_len);
    // Since ownership of the JSON buffer is ours, free before we exit.
    free(out);
  }

  if (pp) {
    Dart_DumpSnapshotInformationPP(&info);
  }

  Dart_ExitScope();
  Dart_ShutdownIsolate();
  // Unload our DartELF to avoid leaks
  Dart_UnloadELF(loaded_elf);
  return 0;
}
#endif
}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
#ifdef SUPPORT_ANALYZE_SNAPSHOT
  return dart::bin::RunAnalyzer(argc, argv);
#else
  dart::Syslog::PrintErr("Unsupported platform.\n");
  dart::Syslog::PrintErr(
      "Requires SDK with following "
      "flags:\n\tTARGET_ARCH_IS_64_BIT\n\tDART_PRECOMPILED_RUNTIME\n\tDART_"
      "TARGET_OS_ANDROID || DART_TARGET_OS_LINUX");
  return dart::bin::kErrorExitCode;
#endif
}

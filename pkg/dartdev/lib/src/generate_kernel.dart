// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show ResidentCompilerInfo, sendAndReceiveResponse;
import 'package:kernel/binary/tag.dart' show isValidSdkHash;
import 'package:path/path.dart' as p;
import 'package:pub/pub.dart';

import 'core.dart';
import 'resident_frontend_constants.dart';
import 'resident_frontend_utils.dart';
import 'sdk.dart';
import 'unified_analytics.dart';

typedef CompileRequestGeneratorCallback = String Function({
  required String executable,
  required String outputDill,
  required ArgResults args,
  String? packages,
});

/// Uses the resident frontend compiler to compute a kernel file for
/// [executable]. Throws a [FrontendCompilerException] if the compilation
/// fails or if the source code contains compilation errors.
///
/// [executable] is expected to contain a path to the dart source file and
/// a package_config file.
///
/// [serverInfoFile] is the location that should be checked to find an existing
/// Resident Frontend Compiler. If one does not exist, a server is created and
/// its address and port information is written to this file location.
///
/// [args] is the [ArgResults] object that is created by the DartDev commands.
/// This is where the optional path override for the serverInfoFile is passed
/// in.
///
/// [compileRequestGenerator] is applied to produce a request for the Resident
/// Frontend Server.
Future<DartExecutableWithPackageConfig> generateKernel(
  DartExecutableWithPackageConfig executable,
  File serverInfoFile,
  ArgResults args,
  CompileRequestGeneratorCallback compileRequestGenerator, {
  bool aot = false,
}) async {
  // Locates the package_config.json and cached kernel file, makes sure the
  // resident frontend server is up and running, and computes a kernel.
  final packageRoot = _packageRootFor(executable);
  if (packageRoot == null) {
    throw FrontendCompilerException._(
        'Unable to locate .dart_tool/package_config.json in any parent folder.'
        'Did you run `pub get`?',
        CompilationIssue.standaloneProgramError);
  }
  await ensureCompilationServerIsRunning(serverInfoFile);
  final packageConfig = p.join(packageRoot, packageConfigName);
  final cachedKernel = _cachedKernelPath(executable.executable, packageRoot);
  Map<String, dynamic> result;
  try {
    result = await sendAndReceiveResponse(
      compileRequestGenerator(
        executable: p.canonicalize(executable.executable),
        outputDill: cachedKernel,
        packages: packageConfig,
        args: args,
      ),
      serverInfoFile,
    );
  } on FileSystemException catch (e) {
    throw FrontendCompilerException._(e.message, CompilationIssue.serverError);
  }
  if (!result[responseSuccessString]) {
    if (result.containsKey(responseErrorString)) {
      throw FrontendCompilerException._(
        result[responseErrorString],
        CompilationIssue.serverError,
      );
    } else {
      throw FrontendCompilerException._(
        (result[responseOutputString] as List<dynamic>).join('\n'),
        CompilationIssue.compilationError,
      );
    }
  }
  return DartExecutableWithPackageConfig(
    executable: cachedKernel,
    packageConfig: packageConfig,
  );
}

/// Returns the absolute path to [executable]'s cached kernel file.
/// Throws a [FrontendCompilerException] if the cached kernel cannot be
/// created.
String _cachedKernelPath(String executable, String packageRoot) {
  final executableDirPath = p.canonicalize(p.dirname(executable));
  var cachedKernelDirectory = p.join(
    packageRoot,
    '.dart_tool',
    dartdevKernelCache,
  );

  final subdirectoryList =
      executableDirPath.replaceFirst(packageRoot, '').split(p.separator);
  for (var directory in subdirectoryList) {
    cachedKernelDirectory = p.join(cachedKernelDirectory, directory);
  }

  try {
    Directory(cachedKernelDirectory).createSync(recursive: true);
  } catch (e) {
    throw FrontendCompilerException._(
      e.toString(),
      CompilationIssue.serverError,
    );
  }
  return p.canonicalize(
    p.join(
      cachedKernelDirectory,
      '${p.basename(executable)}-${sdk.version}.dill',
    ),
  );
}

/// Ensures that a Resident Frontend Compiler associated with [serverInfoFile]
/// will be running at the point when the future returned by this function
/// completes. Throws a [FrontendCompilerException] if starting the server
/// fails.
Future<void> ensureCompilationServerIsRunning(
  File serverInfoFile,
) async {
  if (serverInfoFile.existsSync()) {
    final residentCompilerInfo = ResidentCompilerInfo.fromFile(serverInfoFile);
    if (residentCompilerInfo.sdkHash != null &&
        isValidSdkHash(residentCompilerInfo.sdkHash!)) {
      // There is already a Resident Frontend Compiler associated with
      // [serverInfoFile] that is running and compatible with the Dart SDK that
      // the user is currently using.
      return;
    } else {
      log.stderr(
        'The Dart SDK has been upgraded or downgraded since the Resident '
        'Frontend Compiler was started, so the Resident Frontend Compiler will '
        'now be restarted for compatibility reasons.',
      );
      await shutDownOrForgetResidentFrontendCompiler(serverInfoFile);
    }
  }
  try {
    Directory(p.dirname(serverInfoFile.path)).createSync(recursive: true);
    final Process frontendServerProcess;
    if (File(sdk.frontendServerAotSnapshot).existsSync()) {
      frontendServerProcess = await Process.start(
        sdk.dartAotRuntime,
        [
          sdk.frontendServerAotSnapshot,
          '--resident-info-file-name=${serverInfoFile.absolute.path}'
        ],
        workingDirectory: homeDir?.path,
        mode: ProcessStartMode.detachedWithStdio,
      );
    } else {
      // AOT snapshots cannot be generated on IA32, so we need this fallback
      // branch until support for IA32 is dropped (https://dartbug.com/49969).
      frontendServerProcess = await Process.start(
        sdk.dart,
        [
          sdk.frontendServerSnapshot,
          '--resident-info-file-name=${serverInfoFile.absolute.path}'
        ],
        workingDirectory: homeDir?.path,
        mode: ProcessStartMode.detachedWithStdio,
      );
    }

    final serverOutput =
        String.fromCharCodes(await frontendServerProcess.stdout.first).trim();
    if (serverOutput.startsWith('Error')) {
      throw StateError(serverOutput);
    }
    // Prints the server's address and port information
    log.stdout(serverOutput);
    log.stdout('');
    log.stdout(
        'Run dart compilation-server shutdown to terminate the process.');
  } catch (e) {
    throw FrontendCompilerException._(
      e.toString(),
      CompilationIssue.serverCreationError,
    );
  }
}

/// Returns the path to the root of the [executable]'s package, or null
/// if it is a standalone dart file.
String? _packageRootFor(DartExecutableWithPackageConfig executable) {
  Directory currentDirectory =
      Directory(p.dirname(p.canonicalize(executable.executable)));

  while (currentDirectory.parent.path != currentDirectory.path) {
    if (File(p.join(currentDirectory.path, packageConfigName)).existsSync()) {
      return currentDirectory.path;
    }
    currentDirectory = currentDirectory.parent;
  }
  return null;
}

/// Indicates the type of issue encountered with the
/// Resident Frontend Compiler
enum CompilationIssue {
  /// Communication with the Resident Frontend Compiler failed.
  serverError,

  /// The Resident Frontend Compiler failed to launch
  serverCreationError,

  /// There were compilation errors in the Dart source code.
  compilationError,

  /// Resident mode is only supported for sources within Dart packages
  standaloneProgramError,
}

/// Indicates an error with the Resident Frontend Compiler.
class FrontendCompilerException implements Exception {
  final String message;
  final CompilationIssue issue;

  FrontendCompilerException._(this.message, this.issue);

  @override
  String toString() {
    return 'FrontendCompilerException: $message';
  }
}

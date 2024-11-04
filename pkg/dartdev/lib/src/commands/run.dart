// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:path/path.dart';
import 'package:pub/pub.dart';

import '../core.dart';
import '../experiments.dart';
import '../generate_kernel.dart';
import '../native_assets.dart';
import '../resident_frontend_constants.dart';
import '../resident_frontend_utils.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';
import 'compilation_server.dart';

class RunCommand extends DartdevCommand {
  static const bool isProductMode = bool.fromEnvironment('dart.vm.product');
  static const String cmdName = 'run';

  // kErrorExitCode, as defined in runtime/bin/error_exit.h
  static const errorExitCode = 255;

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser(
      // Don't parse flags after script name.
      allowTrailingOptions: false,
      usageLineLength: dartdevUsageLineLength,
    );
  }

  final bool nativeAssetsExperimentEnabled;

  RunCommand({
    bool verbose = false,
    this.nativeAssetsExperimentEnabled = false,
  }) : super(
          cmdName,
          'Run a Dart program.',
          verbose,
        ) {
    argParser
      ..addFlag(
        residentOption,
        abbr: 'r',
        negatable: false,
        help: 'Enable faster startup times by using a resident frontend '
            'compiler for compilation.\n'
            'If --resident-compiler-info-file is provided in conjunction with '
            'this flag, the specified info file will be used, otherwise the '
            'default info file will be used. If there is not already a '
            'compiler associated with the selected info file, one will be '
            "started. Refer to 'dart ${CompilationServerCommand.commandName} "
            "start -h' for more information about info files.",
        hide: !verbose,
      )
      ..addOption(
        CompilationServerCommand.residentCompilerInfoFileFlag,
        hide: !verbose,
        help: CompilationServerCommand.residentCompilerInfoFileFlagDescription,
      )
      ..addOption(
        CompilationServerCommand.legacyResidentServerInfoFileFlag,
        // This option is only available for backwards compatibility, and should
        // never be shown in the help message.
        hide: true,
      );
    // NOTE: When updating this list of flags, be sure to add any VM flags to
    // the list of flags in Options::ProcessVMDebuggingOptions in
    // runtime/bin/main_options.cc. Failure to do so will result in those VM
    // options being ignored.
    argParser.addSeparator(
      'Debugging options:',
    );
    if (!isProductMode) {
      argParser
        ..addOption(
          'observe',
          help: 'The observe flag is a convenience flag used to run a program '
              'with a set of common options useful for debugging. '
              'Run `dart help -v run` for details.',
          valueHelp: '[<port>[/<bind-address>]]',
        )
        ..addFlag(
          'enable-asserts',
          help: 'Enable assert statements.',
        )
        ..addOption(
          'launch-dds',
          hide: true,
          help: 'Launch DDS.',
        );

      if (verbose) {
        argParser.addSeparator(
            verbose ? 'Options implied by --observe are currently:' : '');
      }
      argParser
        ..addOption(
          'enable-vm-service',
          help: 'Enables the VM service and listens on the specified port for '
              'connections (default port number is 8181, default bind address '
              'is localhost).',
          valueHelp: '[<port>[/<bind-address>]]',
          hide: !verbose,
        )
        ..addFlag(
          'serve-devtools',
          help: 'Serves an instance of the Dart DevTools debugger and profiler '
              'via the VM service at <vm-service-uri>/devtools.',
          defaultsTo: true,
          hide: !verbose,
        )
        ..addFlag(
          'pause-isolates-on-exit',
          help: 'Pause isolates on exit when '
              'running with --enable-vm-service.',
          hide: !verbose,
        )
        ..addFlag(
          'pause-isolates-on-unhandled-exceptions',
          help: 'Pause isolates when an unhandled exception is encountered '
              'when running with --enable-vm-service.',
          hide: !verbose,
        )
        ..addFlag(
          'warn-on-pause-with-no-debugger',
          help:
              'Print a warning when an isolate pauses with no attached debugger'
              ' when running with --enable-vm-service.',
          hide: !verbose,
        )
        ..addOption(
          'timeline-streams',
          help: 'Enables recording for specific timeline streams.\n'
              'Valid streams include: all, API, Compiler, CompilerVerbose, Dart, '
              'Debugger, Embedder, GC, Isolate, VM.\n'
              'Defaults to "Compiler, Dart, GC" when --observe is provided.',
          valueHelp: 'str1, str2, ...',
          hide: !verbose,
        );

      if (verbose) {
        argParser.addSeparator('Other debugging options:');
      }
      argParser
        ..addFlag(
          'pause-isolates-on-start',
          help: 'Pause isolates on start when '
              'running with --enable-vm-service.',
          hide: !verbose,
        )
        ..addOption(
          'timeline-recorder',
          help: 'Selects the timeline recorder to use.\n'
              'Valid recorders include: none, ring, endless, startup, '
              'systrace, file, callback, perfettofile.\n'
              'Defaults to ring.',
          valueHelp: 'recorder',
          hide: !verbose,
        );
    } else {
      argParser.addOption('timeline-recorder',
          help: 'Selects the timeline recorder to use.\n'
              'Valid recorders include: none, systrace, file, callback.\n'
              'Defaults to none.',
          valueHelp: 'recorder');
    }

    argParser.addSeparator('Logging options:');
    argParser.addOption(
      'verbosity',
      help: 'Sets the verbosity level of the compilation.',
      defaultsTo: Verbosity.defaultValue,
      allowed: Verbosity.allowedValues,
      allowedHelp: Verbosity.allowedValuesHelp,
    );

    if (verbose) {
      argParser.addSeparator('Advanced options:');
    }
    argParser.addMultiOption(
      'define',
      abbr: 'D',
      valueHelp: 'key=value',
      help: 'Define an environment declaration.',
      hide: !verbose,
    );
    if (!isProductMode) {
      argParser
        ..addFlag(
          'disable-service-auth-codes',
          hide: !verbose,
          negatable: false,
          help: 'Disables the requirement for an authentication code to '
              'communicate with the VM service. Authentication codes help '
              'protect against CSRF attacks, so it is not recommended to '
              'disable them unless behind a firewall on a secure device.',
        )
        ..addFlag(
          'enable-service-port-fallback',
          hide: !verbose,
          negatable: false,
          help: 'When the VM service is told to bind to a particular port, '
              'fallback to 0 if it fails to bind instead of failing to '
              'start.',
        );
    }
    argParser
      ..addOption(
        'namespace',
        hide: !verbose,
        valueHelp: 'path',
        help: 'The path to a directory that dart:io calls will treat as the '
            'root of the filesystem.',
      )
      ..addOption(
        'root-certs-file',
        hide: !verbose,
        valueHelp: 'path',
        help: 'The path to a file containing the trusted root certificates '
            'to use for secure socket connections.',
      )
      ..addOption(
        'root-certs-cache',
        hide: !verbose,
        valueHelp: 'path',
        help: 'The path to a cache directory containing the trusted root '
            'certificates to use for secure socket connections.',
      )
      ..addFlag(
        'trace-loading',
        hide: !verbose,
        negatable: false,
        help: 'Enables tracing of library and script loading.',
      )
      ..addOption(
        'packages',
        hide: !verbose,
        valueHelp: 'path',
        help: 'The path to the package resolution configuration file, which '
            'supplies a mapping of package names\ninto paths.',
      );

    if (!isProductMode) {
      argParser
        ..addOption(
          'write-service-info',
          help: 'Outputs information necessary to connect to the VM service to '
              'specified file in JSON format. Useful for clients which are '
              'unable to listen to stdout for the Dart VM service listening '
              'message.',
          valueHelp: 'file',
          hide: !verbose,
        )
        ..addFlag('dds',
            hide: !verbose,
            help:
                'Use the Dart Development Service (DDS) for enhanced debugging '
                'functionality. Note: Disabling DDS may break some '
                'functionality in IDEs and other tooling.',
            defaultsTo: true)
        ..addFlag('serve-observatory',
            hide: !verbose,
            help: 'Enable hosting Observatory through the VM Service.',
            defaultsTo: true)
        ..addFlag(
          'print-dtd',
          hide: !verbose,
          help: 'Prints connection details for the Dart Tooling Daemon (DTD).'
              'Useful for Dart DevTools extension authors working with DTD in the '
              'extension development environment.',
        )
        ..addFlag(
          'debug-dds',
          hide: true,
        );
    }
    argParser.addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation =>
      '${super.invocation} [<dart-file|package-target> [args]]';

  /// Attempts to compile [executable] to a kernel file using the Resident
  /// Frontend Compiler associated with [residentCompilerInfoFile]. If
  /// [shouldRetryOnFrontendCompilerException] is true, when a
  /// [FrontendCompilerException] is encountered during compilation, the
  /// Resident Frontend Compiler will be restarted, and compilation will be
  /// retried. This method returns the compiled kernel file if compilation
  /// succeeds, otherwise it returns null.
  static Future<DartExecutableWithPackageConfig?>
      _compileToKernelUsingResidentCompiler({
    required DartExecutableWithPackageConfig executable,
    required File residentCompilerInfoFile,
    required ArgResults args,
    required bool shouldRetryOnFrontendCompilerException,
  }) async {
    final executableFile = File(executable.executable);
    assert(!await isFileKernelFile(executableFile) &&
        !await isFileAppJitSnapshot(executableFile) &&
        !await isFileAotSnapshot(executableFile));

    try {
      return await generateKernel(
        executable,
        residentCompilerInfoFile,
        args,
        createCompileJitJson,
      );
    } on FrontendCompilerException catch (e) {
      if (e.issue == CompilationIssue.serverError) {
        if (shouldRetryOnFrontendCompilerException) {
          log.stderr(
            'Error: A connection to the Resident Frontend Compiler could '
            'not be established. Restarting the Resident Frontend Compiler '
            'and retrying compilation.',
          );
          await shutDownOrForgetResidentFrontendCompiler(
            residentCompilerInfoFile,
          );
          return _compileToKernelUsingResidentCompiler(
            executable: executable,
            residentCompilerInfoFile: residentCompilerInfoFile,
            args: args,
            shouldRetryOnFrontendCompilerException: false,
          );
        } else {
          log.stderr(
            'Error: A connection to the Resident Frontend Compiler could '
            "not be established. Please re-run 'dart run --resident' and a "
            'new compiler will automatically be started in its place.',
          );
          await shutDownOrForgetResidentFrontendCompiler(
            residentCompilerInfoFile,
          );
          return null;
        }
      } else {
        log.stderr(
            '${ansi.yellow}Failed to build ${executable.executable}:${ansi.none}');
        log.stderr(e.message);
        return null;
      }
    }
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    var mainCommand = '';
    var runArgs = <String>[];
    if (args.rest.isNotEmpty) {
      mainCommand = args.rest.first;
      // The command line arguments after the command name.
      runArgs = args.rest.skip(1).toList();
    }

    String? nativeAssets;
    if (!nativeAssetsExperimentEnabled) {
      if (await warnOnNativeAssets()) {
        return errorExitCode;
      }
    } else {
      final runPackageName = getPackageForCommand(mainCommand);
      final assetsYamlFileUri = await compileNativeAssetsJitYamlFile(
        verbose: verbose,
        runPackageName: runPackageName,
      );
      if (assetsYamlFileUri == null) {
        log.stderr('Error: Compiling native assets failed.');
        return errorExitCode;
      }
      nativeAssets = assetsYamlFileUri.toFilePath();
    }

    final String? residentCompilerInfoFileArg =
        args[CompilationServerCommand.residentCompilerInfoFileFlag] ??
            args[CompilationServerCommand.legacyResidentServerInfoFileFlag];
    final useResidentCompiler = args.wasParsed(residentOption);
    if (residentCompilerInfoFileArg != null && !useResidentCompiler) {
      log.stderr(
        'Error: the --resident flag must be passed whenever the '
        '--resident-compiler-info-file option is passed.',
      );
      return errorExitCode;
    }

    DartExecutableWithPackageConfig executable;
    final hasExperiments = args.enabledExperiments.isNotEmpty;
    try {
      executable = await getExecutableForCommand(
        mainCommand,
        allowSnapshot: !(useResidentCompiler || hasExperiments),
        nativeAssets: nativeAssets,
      );
    } on CommandResolutionFailedException catch (e) {
      log.stderr(e.message);
      return errorExitCode;
    }

    if (useResidentCompiler) {
      final File? residentCompilerInfoFile =
          getResidentCompilerInfoFileConsideringArgs(args);
      if (residentCompilerInfoFile == null) {
        log.stderr(
          CompilationServerCommand
              .inaccessibleDefaultResidentCompilerInfoFileMessage,
        );
        return errorExitCode;
      }

      // Ensure the parent directory exists.
      if (!residentCompilerInfoFile.parent.existsSync()) {
        residentCompilerInfoFile.parent.createSync();
      }

      final executableFile = File(executable.executable);
      if (!await isFileKernelFile(executableFile) &&
          !await isFileAppJitSnapshot(executableFile) &&
          !await isFileAotSnapshot(executableFile)) {
        final compiledKernelFile = await _compileToKernelUsingResidentCompiler(
          executable: executable,
          residentCompilerInfoFile: residentCompilerInfoFile,
          args: args,
          shouldRetryOnFrontendCompilerException: true,
        );
        if (compiledKernelFile == null) {
          return errorExitCode;
        } else {
          executable = compiledKernelFile;
        }
      }
    }

    VmInteropHandler.run(
      executable.executable,
      runArgs,
      packageConfigOverride:
          args.option('packages') ?? executable.packageConfig,
    );
    return 0;
  }
}

/// Keep in sync with [getExecutableForCommand].
///
/// Returns `null` if root package should be used.
// TODO(https://github.com/dart-lang/pub/issues/4067): Don't duplicate logic.
String? getPackageForCommand(String descriptor) {
  final root = current;
  var asPath = descriptor;
  try {
    asPath = Uri.parse(descriptor).toFilePath();
  } catch (_) {
    /// Here to get the same logic as[getExecutableForCommand].
  }
  final asDirectFile = join(root, asPath);
  if (File(asDirectFile).existsSync()) {
    return null; // root package.
  }
  if (!File(join(root, 'pubspec.yaml')).existsSync()) {
    return null;
  }
  String package;
  if (descriptor.contains(':')) {
    final parts = descriptor.split(':');
    if (parts.length > 2) {
      return null;
    }
    package = parts[0];
    if (package.isEmpty) {
      return null; // root package.
    }
  } else {
    package = descriptor;
    if (package.isEmpty) {
      return null; // root package.
    }
  }
  if (package == 'test') {
    // `dart run test` is expected to behave as `dart test`.
    return null; // root package.
  }
  return package;
}

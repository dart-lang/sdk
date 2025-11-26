// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdev/src/commands/compile.dart';
import 'package:dartdev/src/commands/install.dart';
import 'package:dartdev/src/install/file_system.dart';
import 'package:dartdev/src/install/pub_formats.dart';
import 'package:dartdev/src/progress.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show invokeReplaceCachedDill;
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
  static const String cmdName = 'run';

  static const gitRefOption = 'git-ref';
  static const gitPathOption = 'git-path';

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
  final bool dataAssetsExperimentEnabled;

  RunCommand({
    bool verbose = false,
    this.nativeAssetsExperimentEnabled = false,
    this.dataAssetsExperimentEnabled = false,
  }) : super(
          cmdName,
          '''Run a Dart program from a file, a local package, or a remote package.

Usage: dart [vm-options] run [arguments] [<dart-file>|<local-package>|<remote-executable> [args]]

<dart-file>
  A path to a Dart script (e.g., `bin/main.dart`).

<local-package>
  An executable from a local package dependency, in the format <package>[:<executable>].
  For example, `test:test` runs the `test` executable from the `test` package.
  If the executable is not specified, the package name is used.

<remote-executable>
  An executable from a remote package. This can be from a hosted package server
  (like pub.dev) or a git repository.

  When running a remote executable, all other command-line flags are disabled,
  except for the options for remote executables. `dart run <remote-executable>`
  uses `dart install` under the hood and compiles the app into a standalone
  executable, preventing passing VM options.

  From a hosted package server:
    <hosted-url>/<package>[@<version>][:<executable>]

    Downloads the package from a hosted package server and runs the specified
    executable.
    If a version is provided, the specified version is downloaded.
    If an executable is not specified, the package name is used.
    For example, `https://pub.dev/dcli@1.0.0:dcli_complete` runs the
    `dcli_complete` executable from version 1.0.0 of the `dcli` package.

  From a git repository:
    <git-url>[:<executable>]

    Clones the git repository and runs the specified executable from it.
    If an executable is not specified, the package name from the cloned
    repository's pubspec.yaml is used.
    The git url can be any valid git url.''',
          verbose,
        ) {
    argParser
      ..addFlag(
        residentOption,
        abbr: 'r',
        negatable: false,
        help: 'Enable faster startup times by using a resident frontend '
            'compiler for compilation.\n'
            'If --$residentCompilerInfoFileOption is provided in conjunction with '
            'this flag, the specified info file will be used, otherwise the '
            'default info file will be used. If there is not already a '
            'compiler associated with the selected info file, one will be '
            "started. Refer to 'dart ${CompilationServerCommand.commandName} "
            "start -h' for more information about info files.",
        hide: !verbose,
      )
      ..addFlag(
        quietOption,
        hide: !verbose,
        help: 'Disable the printing of messages about the resident compiler '
            'starting up / shutting down.',
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
        help: 'Print a warning when an isolate pauses with no attached debugger'
            ' when running with --enable-vm-service.',
        hide: !verbose,
      )
      ..addOption(
        'timeline-streams',
        help: 'Enables recording for specific timeline streams.\n'
            'Valid streams include: all, API, Compiler, CompilerVerbose, Dart, '
            'Debugger, Embedder, GC, Isolate, Microtask, VM.\n'
            'Defaults to "Compiler, Dart, GC, Microtask" when --observe is '
            'provided.',
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
      )
      ..addFlag(
        'profile-microtasks',
        hide: !verbose,
        negatable: false,
        help: 'Record information about each microtask. Information about '
            'completed microtasks will be written to the "Microtask" '
            'timeline stream.',
      )
      ..addFlag(
        'profile-startup',
        hide: !verbose,
        negatable: false,
        help: 'Make the profiler discard new samples once the profiler '
            'sample buffer is full. When this flag is not set, the '
            'profiler sample buffer is used as a ring buffer, meaning that '
            'once it is full, new samples start overwriting the oldest '
            'ones. This flag itself does not enable the profiler; the '
            'profiler must be enabled separately, e.g. with --profiler.',
      )
      ..addSeparator('Logging options:')
      ..addOption(
        'verbosity',
        help: 'Sets the verbosity level of the compilation.',
        defaultsTo: Verbosity.defaultValue,
        allowed: Verbosity.allowedValues,
        allowedHelp: Verbosity.allowedValuesHelp,
      );

    if (verbose) {
      argParser.addSeparator('Advanced options:');
    }
    argParser
      ..addMultiOption(
        'define',
        abbr: 'D',
        valueHelp: 'key=value',
        help: 'Define an environment declaration.',
        hide: !verbose,
      )
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
      )
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
      )
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
          help: 'Use the Dart Development Service (DDS) for enhanced debugging '
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
      )
      ..addExperimentalFlags(verbose: verbose)
      ..addSeparator('Options for remote executables:')
      ..addOption(
        gitPathOption,
        help: 'Path of git package in repository. '
            'Only applies when using a git url for <remote-executable>.',
      )
      ..addOption(
        gitRefOption,
        help: 'Git branch or commit to be retrieved. '
            'Only applies when using a git url for <remote-executable>.',
      );
  }

  @override
  String get invocation =>
      '${super.invocation} [<dart-file|package-target> [args]]';

  @override
  CommandCategory get commandCategory => CommandCategory.project;

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
    required bool quiet,
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
        quiet: quiet,
      );
    } on FrontendCompilerException catch (e) {
      if (e.issue == CompilationIssue.serverError) {
        if (shouldRetryOnFrontendCompilerException) {
          if (!quiet) {
            log.stderr(
              'Error: A connection to the Resident Frontend Compiler could '
              'not be established. Restarting the Resident Frontend Compiler '
              'and retrying compilation.',
            );
          }
          await shutDownOrForgetResidentFrontendCompiler(
            residentCompilerInfoFile,
          );
          return _compileToKernelUsingResidentCompiler(
            executable: executable,
            residentCompilerInfoFile: residentCompilerInfoFile,
            args: args,
            shouldRetryOnFrontendCompilerException: false,
            quiet: quiet,
          );
        } else {
          log.stderr(
            'Error: A connection to the Resident Frontend Compiler could '
            "not be established. Please re-run 'dart run --$residentOption' and a "
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

    if (_isRemoteRun(mainCommand)) {
      return _runRemote(args, mainCommand, runArgs);
    }
    return _runLocal(args, mainCommand, runArgs);
  }

  FutureOr<int> _runLocal(
    ArgResults args,
    String mainCommand,
    List<String> runArgs,
  ) async {
    final String? residentCompilerInfoFileArg =
        args[CompilationServerCommand.residentCompilerInfoFileFlag] ??
            args[CompilationServerCommand.legacyResidentServerInfoFileFlag];
    final useResidentCompiler = args.wasParsed(residentOption);
    if (residentCompilerInfoFileArg != null && !useResidentCompiler) {
      log.stderr(
        'Error: the --$residentOption flag must be passed whenever the '
        '--$residentCompilerInfoFileOption option is passed.',
      );
      return errorExitCode;
    }
    if (args.wasParsed(quietOption) && !useResidentCompiler) {
      log.stderr(
        'Error: the --$residentOption flag must be passed whenever the '
        '--$quietOption flag is passed.',
      );
      return errorExitCode;
    }
    if (args.wasParsed(gitPathOption) || args.wasParsed(gitRefOption)) {
      usageException(
        'Options `--$gitPathOption` and `--$gitRefOption` '
        'can only be used with a remote executable.',
      );
    }

    String? nativeAssets;
    final packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
      Directory.current.uri,
    );
    if (packageConfigUri != null) {
      final packageConfig =
          await DartNativeAssetsBuilder.loadPackageConfig(packageConfigUri);
      if (packageConfig == null) {
        return compileErrorExitCode;
      }
      final runPackageName = getPackageForCommand(mainCommand) ??
          await DartNativeAssetsBuilder.findRootPackageName(
            Directory.current.uri,
          );
      if (runPackageName != null) {
        final pubspecUri = await DartNativeAssetsBuilder.findWorkspacePubspec(
            packageConfigUri);
        final builder = DartNativeAssetsBuilder(
          pubspecUri: pubspecUri,
          packageConfigUri: packageConfigUri,
          packageConfig: packageConfig,
          runPackageName: runPackageName,
          // Enable accessing assets of dev dependencies in the debugger and
          // enabling commands such as `dart run test` and `dart run
          // coverage_with_test` that rely on having dev dependencies.
          includeDevDependencies: true,
          verbose: verbose,
          dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
        );
        if (!nativeAssetsExperimentEnabled) {
          if (await builder.warnOnNativeAssets()) {
            return errorExitCode;
          }
        } else if (await builder.hasHooks()) {
          final verbosity = args.option('verbosity')!;
          final showProgress = verbosity != Verbosity.error.name;
          final assetsYamlFileUri = await (showProgress
              ? progress(
                  'Running build hooks',
                  builder.compileNativeAssetsJitYamlFile,
                )
              : builder.compileNativeAssetsJitYamlFile());
          if (assetsYamlFileUri == null) {
            log.stderr('Error: Running build hooks failed.');
            return errorExitCode;
          }
          nativeAssets = assetsYamlFileUri.toFilePath();
        }
      }
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
      if (await isFileKernelFile(executableFile)) {
        // If the file is a kernel file, we do not need to compile it, but we do
        // need to replace the file in the resident frontend compiler kernel
        // cache associated with this executable, because the cached kernel file
        // may be used to populate context for expression evaluation later.
        await ensureCompilationServerIsRunning(
          residentCompilerInfoFile,
          quiet: args[quietOption] ?? false,
        );
        final succeeded = await invokeReplaceCachedDill(
          replacementDillPath: executableFile.absolute.path,
          serverInfoFile: residentCompilerInfoFile,
        );
        if (!succeeded) {
          log.stderr(
            'Error: Encountered a problem accessing the Resident Frontend '
            "Compiler's kernel file cache. Please try re-running the same "
            'command again. If the error persists, please file an issue at '
            'https://github.com/dart-lang/sdk/issues/new.',
          );
          return errorExitCode;
        }
      } else if (!await isFileAppJitSnapshot(executableFile) &&
          !await isFileAotSnapshot(executableFile)) {
        final compiledKernelFile = await _compileToKernelUsingResidentCompiler(
          executable: executable,
          residentCompilerInfoFile: residentCompilerInfoFile,
          args: args,
          shouldRetryOnFrontendCompilerException: true,
          quiet: args[quietOption] ?? false,
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
      useExecProcess: true,
    );
    return 0;
  }

  static RemoteSourceKind? _remoteSourceKindFromArgument(String argument) {
    if (argument.startsWith('git@')) {
      return RemoteSourceKind.git;
    }
    final potentialUri =
        argument.split(_colonButNoSlashes).first.split('@').first;
    final endsWithDotGitRegex = RegExp(r'\.git[/\\]?$');
    if (endsWithDotGitRegex.hasMatch(potentialUri)) {
      return RemoteSourceKind.git;
    }
    final parsedUri = Uri.tryParse(potentialUri);
    if (parsedUri != null) {
      switch (parsedUri.scheme.toLowerCase()) {
        case 'git':
          return RemoteSourceKind.git;
        case 'http':
        case 'https':
          return RemoteSourceKind.hosted;
      }
    }
    final parsedGitSshUrl = GitSshUrl.tryParse(potentialUri);
    if (parsedGitSshUrl != null) {
      return RemoteSourceKind.git;
    }

    // Local execution.
    return null;
  }

  static bool _isRemoteRun(String mainCommand) {
    return _remoteSourceKindFromArgument(mainCommand) != null;
  }

  /// Parse the arguments for remote run.
  ///
  /// Constructs a [InstallCommandParsedArguments] to be able to reuse the
  /// [InstallCommand] implementation.
  InstallCommandParsedArguments _parseRemoteArguments(String mainCommand) {
    final argResults = this.argResults!;

    final sourceKind = _remoteSourceKindFromArgument(mainCommand)!;

    final gitPath = argResults.option(gitPathOption);
    var gitRef = argResults.option(gitRefOption);
    if (sourceKind != RemoteSourceKind.git &&
        (gitPath != null || gitRef != null)) {
      usageException(
        'Options `--$gitPathOption` and `--$gitRefOption` '
        'can only be used with a git source.',
      );
    }

    for (final option in argResults.options) {
      if (argResults.wasParsed(option) &&
          option != gitPathOption &&
          option != gitRefOption) {
        usageException(
          'Option $option cannot be used in remote runs. '
          '`dart run <remote-executable>` uses `dart install` under the hood '
          'and compiles the app into a standalone executable.',
        );
      }
    }

    String? hostedUrl;
    String? versionConstraint;
    final String source;
    switch (sourceKind) {
      case RemoteSourceKind.git:
        if (mainCommand.startsWith('git@') && mainCommand.contains('.git')) {
          // Valid values might contain a colon for the command or not:
          // - git@github.com:org/repo.git
          // - git@github.com:org/repo.git:executable
          // Drop everything after the 2nd colon for the git repository.
          source = mainCommand.split(':').sublist(0, 2).join(':');
        } else {
          source = mainCommand.split(_colonButNoSlashes).first;
        }
      case RemoteSourceKind.hosted:
        final parsedUri = Uri.parse(
            mainCommand.split('@').first.split(_colonButNoSlashes).first);
        hostedUrl = '${parsedUri.scheme}://${parsedUri.host}';
        source = parsedUri.path.replaceFirst('/', '');
        versionConstraint = mainCommand
                .split('@')
                .lastButNotFirstOrNull
                ?.split(_colonButNoSlashes)
                .first ??
            'any';
      case RemoteSourceKind.path:
        throw StateError('Unreachable');
    }

    return InstallCommandParsedArguments(
      source: source,
      sourceKind: sourceKind,
      versionConstraint: versionConstraint,
      gitPath: gitPath,
      gitRef: gitRef,
      hostedUrl: hostedUrl,
      overwrite: false,
    );
  }

  Future<String> _findPackageName(
    InstallCommandParsedArguments parsedArgs,
  ) async {
    switch (parsedArgs.sourceKind) {
      case RemoteSourceKind.git:
        return await getPackageNameFromGitRepo(
          parsedArgs.source,
          ref: parsedArgs.gitRef,
          path: parsedArgs.gitPath,
          relativeTo: Directory.current.path,
          tagPattern: null,
        );
      case RemoteSourceKind.hosted:
        return parsedArgs.source;

      case RemoteSourceKind.path:
        throw StateError('Unreachable');
    }
  }

  /// Installs (if needed) and runs the remote executable.
  ///
  /// Installs the app bundle at the same location as `dart install` but does
  /// not symlink the executable.
  Future<int> _runRemote(
    ArgResults args,
    String mainCommand,
    List<String> runArgs,
  ) async {
    final parsedArgs = _parseRemoteArguments(mainCommand);
    final packageName = await _findPackageName(parsedArgs);

    return await InstallCommand.inTempDir((tempDirectory) async {
      try {
        // Create a helper package for running a pub-resolve and pulling in the
        // wanted package and its dependencies.
        final helperPackageDirectory =
            Directory.fromUri(tempDirectory.uri.resolve('helperPackage/'));
        helperPackageDirectory.createSync();
        InstallCommand.createHelperPackagePubspec(
          helperPackageDir: helperPackageDirectory,
          packageName: packageName,
          parsedArgs: parsedArgs,
        );
        await InstallCommand.resolveHelperPackage(helperPackageDirectory);
        final helperPackageLockFile =
            File.fromUri(helperPackageDirectory.uri.resolve('pubspec.lock'));

        final appBundleDirectory = InstallCommand.selectAppBundleDirectory(
          parsedArgs,
          packageName,
          helperPackageDirectory,
          helperPackageLockFile,
        );

        // If the pubspec lock file changed, re-build the executable.
        if (!appBundleDirectory
            .pubspecLockIsIdenticalTo(helperPackageLockFile)) {
          final helperPackageConfigFile = File.fromUri(helperPackageDirectory
              .uri
              .resolve('.dart_tool/package_config.json'));

          final sourcePackageRootDirectory = Directory(Uri.parse(
            PackageConfigFile.loadSync(helperPackageConfigFile)
                .packages
                .firstWhere((e) => e.name == packageName)
                .rootUri,
          ).toFilePath())
              .ensureEndWithSeparator;

          final sourcePackagePubspecFile = File.fromUri(
              sourcePackageRootDirectory.uri.resolve('pubspec.yaml'));

          final executables = InstallCommand.loadDeclaredExecutables(
            sourcePackagePubspecFile,
            sourcePackageRootDirectory,
          );

          final buildDirectory =
              Directory.fromUri(tempDirectory.uri.resolve('build/'));
          await InstallCommand.doBuild(
            executables,
            buildDirectory,
            helperPackageConfigFile,
            sourcePackagePubspecFile,
            verbose,
          );

          await InstallCommand.createAppBundleDirectory(
            appBundleDirectory,
            buildDirectory,
            helperPackageLockFile,
            sourcePackagePubspecFile,
          );
        }

        final mainCommandRemainder =
            mainCommand.substring(parsedArgs.source.length);
        final executable = mainCommandRemainder
                .split(_colonButNoSlashes)
                .lastButNotFirstOrNull ??
            packageName;
        final executableUri =
            appBundleDirectory.directory.uri.resolve('bundle/bin/$executable');
        final arguments = args.rest.skip(1).toList();

        // The app-bundle contains executables (not AOT snapshots) to make it
        // self-contained. So, spawn a process instead of loading a snapshot in
        // the VM.
        final process = await Process.start(
          executableUri.toFilePath(),
          arguments,
          mode: ProcessStartMode.inheritStdio, // Enable using stdin etc.
        );
        return await process.exitCode;
      } on InstallException catch (e) {
        stderr.writeln(e.message);
        return genericErrorExitCode;
      }
    });
  }
}

extension<T> on List<T> {
  /// Return the last element, but only if there are at least two elements.
  T? get lastButNotFirstOrNull {
    if (length < 2) return null;
    return last;
  }
}

/// Does not match the :// in an url scheme or the :\ in a Windows path.
final _colonButNoSlashes = RegExp(r':(?!(//|\\))');

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

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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
import '../sdk.dart';
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
        'resident',
        abbr: 'r',
        negatable: false,
        help:
            'Enable faster startup times with the resident frontend compiler.\n'
            "See 'dart ${CompilationServerCommand.commandName} -h' for more information.",
      )
      ..addOption(
        CompilationServerCommand.residentServerInfoFileFlag,
        hide: !verbose,
        help: CompilationServerCommand.residentServerInfoFileFlagDescription,
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
              'with a set of common options useful for debugging.',
          valueHelp: '[<port>[/<bind-address>]]',
        )
        ..addOption('launch-dds', hide: true, help: 'Launch DDS.')
        ..addSeparator(
          'Options implied by --observe are currently:',
        )
        ..addOption(
          'enable-vm-service',
          help: 'Enables the VM service and listens on the specified port for '
              'connections (default port number is 8181, default bind address '
              'is localhost).',
          valueHelp: '[<port>[/<bind-address>]]',
        )
        ..addFlag(
          'serve-devtools',
          help: 'Serves an instance of the Dart DevTools debugger and profiler '
              'via the VM service at <vm-service-uri>/devtools.',
          defaultsTo: true,
        )
        ..addFlag(
          'pause-isolates-on-exit',
          help: 'Pause isolates on exit when '
              'running with --enable-vm-service.',
        )
        ..addFlag(
          'pause-isolates-on-unhandled-exceptions',
          help: 'Pause isolates when an unhandled exception is encountered '
              'when running with --enable-vm-service.',
        )
        ..addFlag(
          'warn-on-pause-with-no-debugger',
          help:
              'Print a warning when an isolate pauses with no attached debugger'
              ' when running with --enable-vm-service.',
        )
        ..addOption(
          'timeline-streams',
          help: 'Enables recording for specific timeline streams.\n'
              'Valid streams include: all, API, Compiler, CompilerVerbose, Dart, '
              'Debugger, Embedder, GC, Isolate, VM.\n'
              'Defaults to "Compiler, Dart, GC" when --observe is provided.',
          valueHelp: 'str1, str2, ...',
        )
        ..addSeparator(
          'Other debugging options:',
        )
        ..addFlag(
          'pause-isolates-on-start',
          help: 'Pause isolates on start when '
              'running with --enable-vm-service.',
        )
        ..addFlag(
          'enable-asserts',
          help: 'Enable assert statements.',
        )
        ..addOption('timeline-recorder',
            help: 'Selects the timeline recorder to use.\n'
                'Valid recorders include: none, ring, endless, startup, '
                'systrace, file, callback, perfettofile.\n'
                'Defaults to ring.',
            valueHelp: 'recorder');
    } else {
      argParser.addOption('timeline-recorder',
          help: 'Selects the timeline recorder to use.\n'
              'Valid recorders include: none, systrace, file, callback.\n'
              'Defaults to none.',
          valueHelp: 'recorder');
    }
    argParser.addOption(
      'verbosity',
      help: 'Sets the verbosity level of the compilation.',
      defaultsTo: Verbosity.defaultValue,
      allowed: Verbosity.allowedValues,
      allowedHelp: Verbosity.allowedValuesHelp,
    );

    if (verbose) {
      argParser.addSeparator(
        'Advanced options:',
      );
    }
    argParser.addMultiOption(
      'define',
      abbr: 'D',
      valueHelp: 'key=value',
      help: 'Define an environment declaration.',
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
          'debug-dds',
          hide: true,
        );
    }
    argParser.addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation =>
      '${super.invocation} [<dart-file|package-target> [args]]';

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
    if (!isProductMode) {
      // --launch-dds is provided by the VM if the VM service is to be enabled. In
      // that case, we need to launch DDS as well.
      String? launchDdsArg = args['launch-dds'];
      String ddsHost = '';
      String ddsPort = '';

      bool launchDevTools = args['serve-devtools'] ?? false;
      bool launchDds = false;
      if (launchDdsArg != null) {
        launchDds = true;
        final ddsUrl = launchDdsArg.split('\\:');
        ddsHost = ddsUrl[0];
        ddsPort = ddsUrl[1];
      }
      final bool debugDds = args['debug-dds'];

      bool disableServiceAuthCodes = args['disable-service-auth-codes'];
      final bool enableServicePortFallback =
          args['enable-service-port-fallback'];

      // If the user wants to start a debugging session we need to do some extra
      // work and spawn a Dart Development Service (DDS) instance. DDS is a VM
      // service intermediary which implements the VM service protocol and
      // provides non-VM specific extensions (e.g., log caching, client
      // synchronization).
      _DebuggingSession debugSession;
      if (launchDds) {
        debugSession = _DebuggingSession();
        if (!await debugSession.start(
          ddsHost,
          ddsPort,
          disableServiceAuthCodes,
          launchDevTools,
          debugDds,
          enableServicePortFallback,
        )) {
          return errorExitCode;
        }
      }
    }

    String? nativeAssets;
    if (nativeAssetsExperimentEnabled) {
      try {
        nativeAssets = (await compileNativeAssetsJitYamlFile())?.toFilePath();
      } on Exception catch (e, stacktrace) {
        log.stderr('Error: Compiling native assets failed.');
        log.stderr(e.toString());
        log.stderr(stacktrace.toString());
        return errorExitCode;
      }
    }

    final hasServerInfoOption = args.wasParsed(serverInfoOption);
    final useResidentServer =
        args.wasParsed(residentOption) || hasServerInfoOption;
    DartExecutableWithPackageConfig executable;
    final hasExperiments = args.enabledExperiments.isNotEmpty;
    try {
      executable = await getExecutableForCommand(
        mainCommand,
        allowSnapshot: !(useResidentServer || hasExperiments),
        nativeAssets: nativeAssets,
      );
    } on CommandResolutionFailedException catch (e) {
      log.stderr(e.message);
      return errorExitCode;
    }

    final residentServerInfoFile = hasServerInfoOption
        ? File(maybeUriToFilename(args[serverInfoOption]))
        : defaultResidentServerInfoFile;

    if (useResidentServer && residentServerInfoFile != null) {
      try {
        // Ensure the parent directory exists.
        if (!residentServerInfoFile.parent.existsSync()) {
          residentServerInfoFile.parent.createSync();
        }

        // TODO(#49694) handle the case when executable is a kernel file
        executable = await generateKernel(
          executable,
          residentServerInfoFile,
          args,
          createCompileJitJson,
        );
      } on FrontendCompilerException catch (e) {
        log.stderr(
            '${ansi.yellow}Failed to build ${executable.executable}:${ansi.none}');
        log.stderr(e.message);
        if (e.issue == CompilationIssue.serverError) {
          try {
            await sendAndReceiveResponse(
              residentServerShutdownCommand,
              residentServerInfoFile,
            );
          } catch (_) {
          } finally {
            cleanupResidentServerInfo(residentServerInfoFile);
          }
        }
        return errorExitCode;
      }
    }

    VmInteropHandler.run(
      executable.executable,
      runArgs,
      packageConfigOverride: args['packages'] ?? executable.packageConfig,
    );
    return 0;
  }
}

class _DebuggingSession {
  Future<bool> start(
    String host,
    String port,
    bool disableServiceAuthCodes,
    bool enableDevTools,
    bool debugDds,
    bool enableServicePortFallback,
  ) async {
    final sdkDir = dirname(sdk.dart);
    final fullSdk = sdkDir.endsWith('bin');
    final ddsSnapshot = fullSdk
        ? sdk.ddsSnapshot
        : absolute(sdkDir, 'gen', 'dds.dart.snapshot');
    final devToolsBinaries =
        fullSdk ? sdk.devToolsBinaries : absolute(sdkDir, 'devtools');
    if (!Sdk.checkArtifactExists(ddsSnapshot)) {
      return false;
    }
    ServiceProtocolInfo serviceInfo = await Service.getInfo();
    // Wait for VM service to publish its connection info.
    while (serviceInfo.serverUri == null) {
      await Future.delayed(Duration(milliseconds: 10));
      serviceInfo = await Service.getInfo();
    }
    final process = await Process.start(
      sdk.dart,
      [
        if (debugDds) '--enable-vm-service=0',
        ddsSnapshot,
        serviceInfo.serverUri.toString(),
        host,
        port,
        disableServiceAuthCodes.toString(),
        enableDevTools.toString(),
        devToolsBinaries,
        debugDds.toString(),
        enableServicePortFallback.toString(),
      ],
      mode: ProcessStartMode.detachedWithStdio,
    );
    final completer = Completer<void>();
    const devToolsMessagePrefix =
        'The Dart DevTools debugger and profiler is available at:';
    if (debugDds) {
      late StreamSubscription stdoutSub;
      stdoutSub = process.stdout.transform(utf8.decoder).listen((event) {
        if (event.startsWith(devToolsMessagePrefix)) {
          final ddsDebuggingUri = event.split(' ').last;
          print(
            'A DevTools debugger for DDS is available at: $ddsDebuggingUri',
          );
          stdoutSub.cancel();
        }
      });
    }
    late StreamSubscription stderrSub;
    stderrSub = process.stderr.transform(utf8.decoder).listen((event) {
      final result = json.decode(event) as Map<String, dynamic>;
      final state = result['state'];
      if (state == 'started') {
        if (result.containsKey('devToolsUri')) {
          final devToolsUri = result['devToolsUri'];
          print('$devToolsMessagePrefix $devToolsUri');
        }
        stderrSub.cancel();
        completer.complete();
      } else {
        stderrSub.cancel();
        final error = result['error'] ?? event;
        final stacktrace = result['stacktrace'] ?? '';
        String message = 'Could not start the VM service: ';
        if (error.contains('Failed to create server socket')) {
          message += '$host:$port is already in use.\n';
        } else {
          message += '$error\n$stacktrace\n';
        }
        completer.completeError(message);
      }
    });
    try {
      await completer.future;
      return true;
    } catch (e) {
      stderr.write(e);
      return false;
    }
  }
}

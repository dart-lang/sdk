// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

class RunCommand extends DartdevCommand {
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

  RunCommand({bool verbose = false})
      : super(
          cmdName,
          'Run a Dart program.',
        ) {
    // NOTE: When updating this list of flags, be sure to add any VM flags to
    // the list of flags in Options::ProcessVMDebuggingOptions in
    // runtime/bin/main_options.cc. Failure to do so will result in those VM
    // options being ignored.
    argParser
      ..addSeparator(
        'Debugging options:',
      )
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
        help: 'Print a warning when an isolate pauses with no attached debugger'
            ' when running with --enable-vm-service.',
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
      );

    if (verbose) {
      argParser
        ..addSeparator(
          'Advanced options:',
        );
    }
    argParser
      ..addMultiOption('define',
          abbr: 'D', help: 'Defines an environment variable', hide: true)
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
            'fallback to 0 if it fails to bind instread of failing to '
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
      );
  }

  @override
  String get invocation => '${super.invocation} <dart file | package target>';

  @override
  FutureOr<int> run() async {
    // The command line arguments after 'run'
    var args = argResults.arguments.toList();
    // --launch-dds is provided by the VM if the VM service is to be enabled. In
    // that case, we need to launch DDS as well.
    bool launchDds = false;
    String ddsHost = '';
    String ddsPort = '';

    final launchDdsArg = args.singleWhere(
      (element) => element.startsWith('--launch-dds'),
      orElse: () => null,
    );
    if (launchDdsArg != null) {
      launchDds = true;
      final ddsUrl = (launchDdsArg.split('=')[1]).split(':');
      ddsHost = ddsUrl[0];
      ddsPort = ddsUrl[1];
    }

    var argsContainFile = false;
    for (var arg in args) {
      // The arg.contains('.') matches a file name pattern, i.e. some 'foo.dart'
      if (arg.contains('.')) {
        argsContainFile = true;
      } else if (!argsContainFile &&
          (arg == '--help' || arg == '-h' || arg == 'help')) {
        // Only print usage if a help flag is provided before the script name.
        printUsage();
        return 0;
      }
    }

    var disableServiceAuthCodes =
        argResults['disable-service-auth-codes'] ?? false;

    final cwd = Directory.current;
    if (!argsContainFile && cwd.existsSync()) {
      var foundImplicitFileToRun = false;
      var cwdName = cwd.name;
      for (var entity in cwd.listSync(followLinks: false)) {
        if (entity is Directory && entity.name == 'bin') {
          var filesInBin =
              entity.listSync(followLinks: false).whereType<File>();

          // Search for a dart file in bin/ with the pattern foo/bin/foo.dart
          for (var fileInBin in filesInBin) {
            if (fileInBin.isDartFile && fileInBin.name == '$cwdName.dart') {
              args.add('bin/${fileInBin.name}');
              foundImplicitFileToRun = true;
              break;
            }
          }
          // break here, no actions taken on any entities that are not bin/
          break;
        }
      }

      if (!foundImplicitFileToRun) {
        // This throws.
        usageException('Could not find the implicit file to run: '
            'bin$separator$cwdName.dart.');
      }
    }

    // Pass any --enable-experiment options along.
    if (args.isNotEmpty && wereExperimentsSpecified) {
      List<String> experimentIds = specifiedExperiments;
      args = [
        '--$experimentFlagName=${experimentIds.join(',')}',
        ...args,
      ];
    }

    // If the user wants to start a debugging session we need to do some extra
    // work and spawn a Dart Development Service (DDS) instance. DDS is a VM
    // service intermediary which implements the VM service protocol and
    // provides non-VM specific extensions (e.g., log caching, client
    // synchronization).
    _DebuggingSession debugSession;
    if (launchDds) {
      debugSession = _DebuggingSession();
      if (!await debugSession.start(
          ddsHost, ddsPort, disableServiceAuthCodes)) {
        return errorExitCode;
      }
    }

    var path = args.firstWhere((e) => !e.startsWith('-'));
    final pathIndex = args.indexOf(path);
    final runArgs = (pathIndex + 1 == args.length)
        ? <String>[]
        : args.sublist(pathIndex + 1);
    try {
      path = Uri.parse(path).toFilePath();
    } catch (_) {
      // Input path will either be a valid path or a file uri
      // (e.g /directory/file.dart or file:///directory/file.dart). We will try
      // parsing it as a Uri, but if parsing failed for any reason (likely
      // because path is not a file Uri), `path` will be passed without
      // modification to the VM.
    }
    VmInteropHandler.run(path, runArgs);
    return 0;
  }
}

class _DebuggingSession {
  Future<bool> start(
      String host, String port, bool disableServiceAuthCodes) async {
    final serviceInfo = await Service.getInfo();
    final ddsSnapshot = (dirname(sdk.dart).endsWith('bin'))
        ? sdk.ddsSnapshot
        : absolute(dirname(sdk.dart), 'gen', 'dds.dart.snapshot');
    if (!Sdk.checkArtifactExists(ddsSnapshot)) {
      return false;
    }
    final process = await Process.start(
        sdk.dart,
        [
          if (dirname(sdk.dart).endsWith('bin'))
            sdk.ddsSnapshot
          else
            absolute(dirname(sdk.dart), 'gen', 'dds.dart.snapshot'),
          serviceInfo.serverUri.toString(),
          host,
          port,
          disableServiceAuthCodes.toString(),
        ],
        mode: ProcessStartMode.detachedWithStdio);
    final completer = Completer<void>();
    StreamSubscription sub;
    sub = process.stderr.transform(utf8.decoder).listen((event) {
      if (event == 'DDS started') {
        sub.cancel();
        completer.complete();
      } else if (event.contains('Failed to start DDS')) {
        sub.cancel();
        completer.completeError(event.replaceAll(
          'Failed to start DDS',
          'Could not start Observatory HTTP server',
        ));
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

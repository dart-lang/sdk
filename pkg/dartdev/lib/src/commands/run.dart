// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:pub/pub.dart';

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
    addExperimentalFlags(argParser, verbose);
  }

  @override
  String get invocation => '${super.invocation} <dart file | package target>';

  @override
  FutureOr<int> run() async {
    var mainCommand = '';
    var runArgs = <String>[];
    if (argResults.rest.isNotEmpty) {
      mainCommand = argResults.rest.first;
      // The command line arguments after the command name.
      runArgs = argResults.rest.skip(1).toList();
    }
    // --launch-dds is provided by the VM if the VM service is to be enabled. In
    // that case, we need to launch DDS as well.
    String launchDdsArg = argResults['launch-dds'];
    String ddsHost = '';
    String ddsPort = '';
    bool launchDds = false;
    if (launchDdsArg != null) {
      launchDds = true;
      final ddsUrl = launchDdsArg.split(':');
      ddsHost = ddsUrl[0];
      ddsPort = ddsUrl[1];
    }

    bool disableServiceAuthCodes = argResults['disable-service-auth-codes'];

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

    String path;
    String packagesConfigOverride;

    try {
      final filename = maybeUriToFilename(mainCommand);
      if (File(filename).existsSync()) {
        // TODO(sigurdm): getExecutableForCommand is able to figure this out,
        // but does not return a package config override.
        path = filename;
        packagesConfigOverride = null;
      } else {
        path = await getExecutableForCommand(mainCommand);
        packagesConfigOverride =
            join(current, '.dart_tool', 'package_config.json');
      }
    } on CommandResolutionFailedException catch (e) {
      log.stderr(e.message);
      return errorExitCode;
    }
    VmInteropHandler.run(
      path,
      runArgs,
      packageConfigOverride: packagesConfigOverride,
    );
    return 0;
  }
}

/// Try parsing [maybeUri] as a file uri or [maybeUri] itself if that fails.
String maybeUriToFilename(String maybeUri) {
  try {
    return Uri.parse(maybeUri).toFilePath();
  } catch (_) {
    return maybeUri;
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

// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart' as f;
import 'package:http/http.dart' as http;
import 'package:pub/pub.dart';

import '../resource_provider/resource_provider_file.dart';
import '../resource_provider/resource_provider_wrap_cwd.dart';
import '../shared.dart';
import '../util/stdout_recorder.dart';

const supportedPubCommands = [
  'get',
  'add',
  'downgrade',
  'outdated',
  'upgrade',
  'remove',
  'unpack',
];

Future<({String log})> pub({
  required ResourceProvider resourceProvider,
  required String currentWorkingDirectory,
  required String command,
  required List<String> args,
  required DartPadConfig config,
}) async {
  if (!supportedPubCommands.contains(command)) {
    throw ArgumentError.value(
      command,
      'command',
      'must be one of $supportedPubCommands',
    );
  }

  final stdout = StdoutRecorder();

  final exitCode = await Runner(
    fileSystem: resourceProviderAsFileFileSystem(
      resourceProviderWithCurrentWorkingDirectory(
        resourceProvider,
        currentWorkingDirectory,
      ),
    ),
    stdout: stdout.sink,
    stderr: stdout.sink,
    stdin: const Stream.empty(),
    platformVersion: '3.12.0',
    environment: {
      'PUB_CACHE': '/pub-cache',
      'DART_ROOT': config.dartSdkPath,
      'FLUTTER_ROOT': ?config.flutterSdkPath,
      if (config.pubHostedUrl?.isNotEmpty == true)
        'PUB_HOSTED_URL': ?config.pubHostedUrl,
    },
    httpClient: http.Client(),
  ).run(['pub', command, ...args]);

  if (exitCode != 0) {
    final makeException =
        _pubExceptionMap[exitCode] ?? PubCommandFailedException.new;
    throw makeException(stdout.log, data: {'exitCode': exitCode});
  }

  return (log: stdout.log);
}

typedef _MakeException = Exception Function(String message, {Object? data});

/// Pub uses exit codes from http://www.freebsd.org/cgi/man.cgi?query=sysexits
///
/// See: sdk/third_party/pkg/pub/lib/src/exit_codes.dart
final _pubExceptionMap = <int, _MakeException>{
  64: PubUsageException.new,
  65: PubDataException.new,
  66: PubNoInputException.new,
  67: PubNoUserException.new,
  68: PubNoHostException.new,
  69: PubUnavailableException.new,
  70: PubSoftwareException.new,
  71: PubOsException.new,
  72: PubOsFileException.new,
  73: PubCantCreateException.new,
  74: PubIoException.new,
  75: PubTempFailException.new,
  76: PubProtocolException.new,
  77: PubNoPermException.new,
  78: PubConfigException.new,
};

class Runner extends CommandRunner<int> {
  final f.FileSystem fileSystem;
  final Map<String, String> environment;
  final String platformVersion;
  final Stream<List<int>> stdin;
  final StreamSink<List<int>> stdout;
  final StreamSink<List<int>> stderr;
  final http.Client httpClient;

  Runner({
    required this.fileSystem,
    required this.environment,
    required this.platformVersion,
    required this.stdin,
    required this.stdout,
    required this.stderr,
    required this.httpClient,
  }) : super('dart', 'dart pub emulator') {
    addCommand(
      pubCommand(
        isVerbose: () => false,
        fileSystem: fileSystem,
        environment: environment,
        platformVersion: platformVersion,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        httpClient: httpClient,
      ),
    );
  }
}

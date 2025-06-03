// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

/// Helper class for starting a Dart Tooling Daemon instance, and extracting
/// it's [trustedSecret] and [uri] from stdout.
class ToolingDaemonTestProcess {
  ToolingDaemonTestProcess({this.unrestricted = false});
  late final String? trustedSecret;
  late final Uri uri;
  late final Process? process;
  final bool unrestricted;

  Future<Process> start() async {
    final completer = Completer<void>();
    process = await Process.start(
      Platform.resolvedExecutable,
      [
        'tooling-daemon',
        '--machine',
        if (unrestricted) '--unrestricted',
        '--fakeAnalytics',
      ],
    );
    process!.handle(
      stdoutLines: (line) {
        print('DTD stdout: $line');
        try {
          final json = jsonDecode(line) as Map<String, Object?>;
          final toolingDaemonDetails =
              json['tooling_daemon_details'] as Map<String, Object?>;
          trustedSecret =
              toolingDaemonDetails['trusted_client_secret'] as String?;
          uri = Uri.parse(toolingDaemonDetails['uri'] as String);
          completer.complete();
        } catch (e) {
          // If we failed to decode then this line doesn't have json.
          print('Json parsing error: $e');
        }
      },
      stderrLines: (line) {
        stderr.write('DTD stderr: $line');
      },
    );

    await completer.future;
    return process!;
  }

  void kill() {
    process?.kill();
  }
}

/// Helper class for starting a Dart CLI app and extracting its VM service uri
/// from stdout.
class DartCliAppProcess {
  late final String vmServiceUri;
  late final TestProcess? process;

  Future<TestProcess> start() async {
    final tmpDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tmpDir.deleteSync(recursive: true));

    // A simple Dart command line app that will never exit.
    const fileName = 'app.dart';
    File(join(tmpDir.path, fileName))
      ..writeAsStringSync('''
void main() async {
  while (true) {
    // Loop on an awaited delay to avoid pinning a CPU core.
    await Future.delayed(const Duration(seconds: 1));
  }
}
''')
      ..createSync();

    process = await TestProcess.start(
      Platform.resolvedExecutable,
      [
        'run',
        '--observe=0',
        fileName,
      ],
      workingDirectory: tmpDir.path,
    );

    addTearDown(() async {
      await process!.kill();
    });

    String? uri;
    final stdout = StreamQueue(process!.stdoutStream());
    while (await stdout.hasNext) {
      final line = await stdout.next;
      if (line.contains('The Dart VM service is listening on')) {
        vmServiceUri = uri =
            line.substring(line.indexOf('http:')).replaceFirst('http:', 'ws:');
        await stdout.cancel();
        break;
      }
    }
    if (uri == null) {
      throw StateError(
        'Failed to read vm service URI from the Dart run output.',
      );
    }
    return process!;
  }

  void kill() {
    process?.kill();
  }
}

extension OutputProcessExtension on Process {
  void handle({
    required void Function(String) stdoutLines,
    void Function(String)? stderrLines,
  }) {
    this
        .stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => stdoutLines(line));

    if (stderrLines != null) {
      this
          .stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => stderrLines(line));
    }
  }
}

Matcher throwsAnRpcError(int code) {
  return throwsA(predicate((p0) => (p0 is RpcException) && (p0.code == code)));
}

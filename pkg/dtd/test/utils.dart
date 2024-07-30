// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
        stdout.write('DTD stdout: $line');
        try {
          final json = jsonDecode(line) as Map<String, Object?>;
          final toolingDaemonDetails =
              json['tooling_daemon_details'] as Map<String, dynamic>;
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

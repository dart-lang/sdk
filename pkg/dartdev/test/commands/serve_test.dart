// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

/// Tests the hidden `dart experimental-serve` command: its usage, its errors,
/// what it serves and prints, and that Ctrl+C (or SIGTERM) stops it and
/// deletes its temporary files.
void main() {
  group('experimental-serve', serve, timeout: longTimeout);
}

void serve() {
  test('--help', () async {
    final p = project();
    final result = await p.run(['experimental-serve', '--help']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Serve a Dart web app over HTTP.'));
    expect(
      result.stdout,
      contains('Usage: dart experimental-serve [arguments] [<entrypoint>]'),
    );
    expect(result.stdout, contains('--port'));
  });

  test('explains a missing web/ directory', () async {
    final p = project();
    final result = await p.run(['experimental-serve']);
    expect(result.exitCode, 65);
    expect(result.stderr, contains('No web/ directory found'));
  });

  test('rejects a --port that is not a port number', () async {
    final p = project();
    for (final port in ['abc', '-1', '65536']) {
      final result = await p.run(['experimental-serve', '--port', port]);
      expect(result.exitCode, 64, reason: port);
      expect(
        result.stderr,
        contains('--port must be a number from 0 to 65535.'),
        reason: port,
      );
    }
  });

  test('rejects more than one entrypoint', () async {
    final p = project();
    final result = await p.run([
      'experimental-serve',
      'web/a.dart',
      'web/b.dart',
    ]);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('Expected at most one entrypoint'));
  });

  test('explains a port that is already in use', () async {
    final p = project();
    p.file('web/index.html', '<script defer src="main.dart.js"></script>');
    p.file('web/main.dart', 'void main() {}');
    final other = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(other.close);

    final result = await p.run([
      'experimental-serve',
      '--hostname',
      '127.0.0.1',
      '--port',
      '${other.port}',
    ]);
    expect(result.exitCode, 65);
    expect(
      result.stderr,
      contains('Could not serve on 127.0.0.1:${other.port}: '),
    );
    // Only the message, not the exception's stack trace.
    expect(result.stderr, isNot(contains('SocketException')));
    expect(result.stderr, isNot(contains('.dart:')));
  });

  test('serves the app until Ctrl+C', () async {
    final serve = await _ServeProcess.start(project());
    expect(serve.url.toString(), startsWith('http://localhost:'));

    final client = HttpClient();
    addTearDown(client.close);
    Future<String> get(String path) async {
      final response = await (await client.getUrl(
        serve.url.resolve(path),
      )).close();
      expect(response.statusCode, HttpStatus.ok, reason: path);
      return response.transform(utf8.decoder).join();
    }

    expect(await get('/'), contains('main.dart.js'));
    expect(await get('/main.dart.js'), contains('main_module.bootstrap.js'));
    expect(await get('/web/main.dart.lib.js'), contains('main'));

    // Windows can't send Ctrl+C to another process.
    if (Platform.isWindows) {
      serve.process.kill();
      await serve.process.exitCode;
    } else {
      expect(serve.tempDirectory.listSync(), isNotEmpty);
      serve.process.kill(ProcessSignal.sigint);
      expect(await serve.process.exitCode, 0);
      expect(serve.tempDirectory.listSync(), isEmpty);
    }
    await serve.stderrDone;
    expect(serve.stderr, isNot(contains(startsWith('WARNING'))));
    // Every run says that the command is still changing.
    expect(
      serve.stderr,
      contains(
        '`dart experimental-serve` is under active development and is '
        'likely to change.',
      ),
    );
  });

  test('SIGTERM stops the server', () async {
    final serve = await _ServeProcess.start(project());
    expect(serve.tempDirectory.listSync(), isNotEmpty);
    serve.process.kill(ProcessSignal.sigterm);
    expect(await serve.process.exitCode, 0);
    expect(serve.tempDirectory.listSync(), isEmpty);
  }, skip: Platform.isWindows ? 'Windows has no SIGTERM' : false);

  test('warns when other devices can reach the server', () async {
    final serve = await _ServeProcess.start(
      project(),
      arguments: ['--hostname', '0.0.0.0'],
    );
    expect(serve.url.toString(), startsWith('http://0.0.0.0:'));
    serve.process.kill();
    await serve.process.exitCode;
    await serve.stderrDone;
    // The empty line sets the warning apart from the URL.
    expect(
      serve.stderr,
      containsAllInOrder([
        startsWith('WARNING: Serving on 0.0.0.0,'),
        startsWith('The server has no authentication'),
        '',
      ]),
    );
  });
}

/// A `dart experimental-serve` process for a small web app, started with its
/// own temporary directory.
class _ServeProcess {
  final Process process;

  /// The URL printed in `Serving web on <url>`.
  final Uri url;

  /// The directory the process uses as its system temp directory, where the
  /// compiler writes its output.
  final Directory tempDirectory;

  /// The lines printed to stderr so far.
  final List<String> stderr;

  /// Completes when stderr is closed, after the process exits.
  final Future<void> stderrDone;

  _ServeProcess._(
    this.process,
    this.url,
    this.tempDirectory,
    this.stderr,
    this.stderrDone,
  );

  /// Serves a web app in [p] with
  /// `dart experimental-serve --port 0 [arguments]`, and
  /// completes once it prints the URL.
  static Future<_ServeProcess> start(
    TestProject p, {
    List<String> arguments = const [],
  }) async {
    p.file('web/index.html', '<script defer src="main.dart.js"></script>');
    p.file('web/main.dart', 'void main() {}');
    final tempDirectory = Directory(path.join(p.root.path, 'tmp'))
      ..createSync();
    final process = await p.start(
      ['experimental-serve', '--port', '0', ...arguments],
      // Directory.systemTemp uses TMPDIR on Linux and macOS, and TMP on
      // Windows.
      environment: {'TMPDIR': tempDirectory.path, 'TMP': tempDirectory.path},
    );
    final stderr = <String>[];
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          printOnFailure(line);
          stderr.add(line);
        })
        .asFuture<void>();
    // Prints the URL once the app is compiled. A broadcast stream keeps
    // reading stdout after `firstWhere`, so the process can still print.
    final servingLine = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream()
        .firstWhere((line) => line.startsWith('Serving web on '))
        .timeout(const Duration(minutes: 2));
    return _ServeProcess._(
      process,
      Uri.parse(servingLine.substring('Serving web on '.length)),
      tempDirectory,
      stderr,
      stderrDone,
    );
  }
}

// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devtools_shared/devtools_test_utils.dart';

const verbose = true;

class DevToolsServerDriver {
  DevToolsServerDriver._(
    this._process,
    this._stdin,
    Stream<String> _stdout,
    Stream<String> _stderr,
  )   : stdout = _convertToMapStream(_stdout),
        stderr = _stderr.map((line) {
          _trace('<== STDERR $line');
          return line;
        });

  final Process _process;
  final Stream<Map<String, dynamic>?> stdout;
  final Stream<String> stderr;
  final StringSink _stdin;

  void write(Map<String, dynamic> request) {
    final line = jsonEncode(request);
    _trace('==> $line');
    _stdin.writeln(line);
  }

  static Stream<Map<String, dynamic>?> _convertToMapStream(
    Stream<String> stream,
  ) {
    return stream.map((line) {
      _trace('<== $line');
      return line;
    }).map((line) {
      try {
        return jsonDecode(line) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }).where((item) => item != null);
  }

  static void _trace(String message) {
    if (verbose) {
      print(message);
    }
  }

  bool kill() => _process.kill();

  static Future<DevToolsServerDriver> create({
    int port = 0,
    int? tryPorts,
    List<String> additionalArgs = const [],
  }) async {
    final script =
        Platform.script.resolveUri(Uri.parse('./serve_devtools.dart'));
    final args = [
      script.path,
      '--machine',
      '--port',
      '$port',
      ...additionalArgs,
    ];

    if (tryPorts != null) {
      args.addAll(['--try-ports', '$tryPorts']);
    }

    if (useChromeHeadless && headlessModeIsSupported) {
      args.add('--headless');
    }
    final Process process = await Process.start(
      Platform.resolvedExecutable,
      args,
    );

    return DevToolsServerDriver._(
      process,
      process.stdin,
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()),
    );
  }
}

// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A wrapper around a `dart tooling-daemon --machine` process used by tests
/// that have the server connect to DTD and provide services.
class DtdProcess {
  /// The [Process] spawned.
  final Process _proc;

  /// A completer for the DTD URI that is printed to stdout by the process.
  final Completer<Uri> _dtdUriCompleter = Completer<Uri>();

  DtdProcess._(this._proc) {
    // Read output for the URI.
    _proc.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((
      data,
    ) {
      var json = jsonDecode(data);
      if (json case {'tooling_daemon_details': {'uri': String uri}}) {
        _dtdUriCompleter.complete(Uri.parse(uri));
      }
    });

    // No stderr output is expected so print anything that arrives to aid
    // debugging.
    _proc.stderr
        .transform(utf8.decoder)
        .listen((data) => print('<== DTD stderr: $data'));

    // Handle unexpected termination.
    unawaited(
      _proc.exitCode.then((code) {
        if (!_dtdUriCompleter.isCompleted) {
          _dtdUriCompleter.completeError(
            'DTD process exited with $code without providing a URI',
          );
        }
      }),
    );
  }

  /// A [Future] that completes with the URI once provided by DTD.
  ///
  /// Completes with an error if the process terminates without providing a URI.
  Future<Uri> get dtdUri => _dtdUriCompleter.future;

  /// Terminates the process.
  Future<void> dispose() async {
    _proc.kill();
    await _proc.exitCode;
  }

  /// Spawns and returns a new DTD process.
  static Future<DtdProcess> start() async {
    var proc = await Process.start(Platform.resolvedExecutable, [
      'tooling-daemon',
      '--machine',
      '--fakeAnalytics',
    ]);

    return DtdProcess._(proc);
  }
}

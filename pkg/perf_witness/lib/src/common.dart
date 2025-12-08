// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:dart_data_home/dart_data_home.dart';
import 'package:path/path.dart' as p;

final String? _controlSocketsDirectory = () {
  final dir = getDartDataHome('perf');
  try {
    // Ensure that directory exists.
    io.Directory(dir).createSync(recursive: true);
    return dir;
  } catch (_) {
    // Ignore any sort of exceptions.
    return null;
  }
}();

List<({int pid, io.File socketPath})> getAllControlSockets() {
  if (_controlSocketsDirectory == null) {
    return const [];
  }

  try {
    final allPidFiles = io.Directory(
      _controlSocketsDirectory!,
    ).listSync().whereType<io.File>();
    return [
      for (var file in allPidFiles)
        if (int.tryParse(p.basenameWithoutExtension(file.path)) case final pid?)
          (pid: pid, socketPath: file),
    ];
  } catch (_) {
    // Ignore
    return [];
  }
}

final String? controlSocketPath = () {
  final dirPath = _controlSocketsDirectory;
  if (dirPath == null) {
    return null;
  }
  return p.join(dirPath, '${io.pid}');
}();

final String? recorderSocketPath = () {
  final dirPath = _controlSocketsDirectory;
  if (dirPath == null) {
    return null;
  }
  return p.join(dirPath, 'rec');
}();

abstract class UnixDomainSocket {
  static Future<io.Socket> connect(String path) => io.Socket.connect(
    io.InternetAddress(path, type: io.InternetAddressType.unix),
    0,
  );

  static Future<io.ServerSocket> bind(String path) {
    if (io.FileSystemEntity.typeSync(path) !=
        io.FileSystemEntityType.notFound) {
      io.File(path).deleteSync();
    }

    return io.ServerSocket.bind(
      io.InternetAddress(path, type: io.InternetAddressType.unix),
      0,
    );
  }
}

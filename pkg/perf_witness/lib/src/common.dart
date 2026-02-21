// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:isolate';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:path/path.dart' as p;

final String? _controlSocketsDirectory = () {
  try {
    final dir = getDartDataHome('perf');
    // Ensure that directory exists.
    io.Directory(dir).createSync(recursive: true);
    return dir;
  } catch (_) {
    // Ignore any sort of exceptions.
    return null;
  }
}();

List<({int pid, String socketPath})> getAllControlSockets() {
  if (_controlSocketsDirectory == null) {
    return const [];
  }

  try {
    // Caveat: on Windows Unix Domain Sockets are represented as link rather
    // than file objects, so filtering this list to io.File objects will miss
    // socket objects entirely.
    final allPidFiles = io.Directory(_controlSocketsDirectory!)
        .listSync()
        .map((e) => e.path)
        .where((path) => io.FileSystemEntity.typeSync(path) == .unixDomainSock);
    final result = [
      for (var path in allPidFiles)
        if (int.tryParse(p.basenameWithoutExtension(path)) case final pid?)
          (pid: pid, socketPath: path),
    ];
    return result;
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

  static Future<io.ServerSocket> bind(String path) async {
    if (io.FileSystemEntity.typeSync(path) !=
        io.FileSystemEntityType.notFound) {
      io.File(path).deleteSync();
    }

    return await io.ServerSocket.bind(
      io.InternetAddress(path, type: io.InternetAddressType.unix),
      0,
    );
  }
}

Future<void> waitForUserToQuit({bool waitForQKeyPress = false}) async {
  if (waitForQKeyPress) {
    await Isolate.run(() {
      print('Press Q to exit');
      try {
        io.stdin.echoMode = false;
        io.stdin.lineMode = false;
      } catch (_) {
        // Ignore any issues.
      }
      int byte;
      while ((byte = io.stdin.readByteSync()) != -1) {
        if (byte == 'Q'.codeUnitAt(0) || byte == 'q'.codeUnitAt(0)) {
          break;
        }
      }
    });
  } else {
    final signalFired = io.ProcessSignal.sigint.watch().first;
    print('Press Ctrl-C to exit');
    await signalFired;
  }
}

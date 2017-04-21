// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=http_launch_data/http_isolate_main.dart
// OtherResources=http_launch_data/http_launch_main.dart
// OtherResources=http_launch_data/http_spawn_main.dart
// OtherResources=http_launch_data/packages/simple/simple.dart
//
// Test:
//   *) Launching a script fetched over HTTP.
//   *) Importing a library fetched over HTTP.
//   *) Automatically resolving package_root when script is fetched over HTTP.
//   *) Spawning a URI over HTTP.

library http_launch_test;

import 'dart:async';
import 'dart:io';
import 'package:expect/expect.dart';

String pathToExecutable = Platform.executable;
Uri pathOfData = Platform.script.resolve('http_launch_data/');
int port;

_sendNotFound(HttpResponse response) {
  response.statusCode = HttpStatus.NOT_FOUND;
  response.close();
}

handleRequest(HttpRequest request) {
  final String path = request.uri.path.substring(1);
  final Uri requestPath = pathOfData.resolve(path);
  final File file = new File(requestPath.toFilePath());
  file.exists().then((bool found) {
    if (found) {
      file.openRead().pipe(request.response).catchError((e) {
        _sendNotFound(request.response);
      });
    } else {
      _sendNotFound(request.response);
    }
  });
}

serverRunning(HttpServer server) {
  port = server.port;
  server.listen(handleRequest);
  Future<ProcessResult> no_http_run = Process.run(pathToExecutable,
      [pathOfData.resolve('http_launch_main.dart').toFilePath()]);
  Future<ProcessResult> http_run = Process
      .run(pathToExecutable, ['http://127.0.0.1:$port/http_launch_main.dart']);
  Future<ProcessResult> http_pkg_root_run = Process.run(pathToExecutable, [
    '--package-root=http://127.0.0.1:$port/packages/',
    'http://127.0.0.1:$port/http_launch_main.dart'
  ]);
  Future<ProcessResult> isolate_run = Process.run(pathToExecutable,
      ['http://127.0.0.1:$port/http_spawn_main.dart', '$port']);
  Future<List<ProcessResult>> results =
      Future.wait([no_http_run, http_run, http_pkg_root_run, isolate_run]);
  results.then((results) {
    // Close server.
    server.close();
    // Check results.
    checkResults(results);
  });
}

checkResults(List<ProcessResult> results) {
  Expect.equals(4, results.length);
  // Exited cleanly.
  for (int i = 0; i < results.length; i++) {
    ProcessResult result = results[i];
    if (result.exitCode != 0) {
      print("Exit code for process $i = ${result.exitCode}");
      print("---stdout:---\n${result.stdout}");
      print("---stderr:---\n${result.stderr}\n---");
    }
    Expect.equals(0, result.exitCode);
  }
  String stdout = results[0].stdout;
  // Output is the string 'hello'. Use startsWith to avoid new line differences.
  if (!stdout.startsWith('hello')) {
    print("---- stdout of remote process:\n$stdout\n----");
  }
  Expect.isTrue(stdout.startsWith('hello'));
  // Same output from all three process runs.
  for (int i = 0; i < results.length; i++) {
    Expect.equals(stdout, results[i].stdout);
  }
}

main() {
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0).then(serverRunning);
}

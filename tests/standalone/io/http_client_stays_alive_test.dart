// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";

// NOTE: This test tries to ensure that an HttpClient will close it's
// underlying idle connections after [HttpClient.idleTimeout].
//
// The main script spawns a server and a subprocess which does a connection back
// to it.
// The subprocess is expected to shut down it's idle sockets after
// [HttpClient.idleTimeout] and the main script will assert that this happens
// within +/- 2 <= seconds.

const SECONDS = 4;

void runServerProcess() {
  asyncStart();
  HttpServer.bind('127.0.0.1', 0).then((server) {
    var url = 'http://127.0.0.1:${server.port}/';

    server.idleTimeout = const Duration(hours: 1);

    var subscription = server.listen((HttpRequest request) {
      return request.response..write('hello world')..close();
    });

    var sw = new Stopwatch()..start();
    var arguments = ['--package-root=${Platform.packageRoot}',
                     '${Platform.script}',
                     url];
    Process.run(Platform.executable, arguments).then((res) {
      subscription.cancel();
      if (res.exitCode != 0) {
        throw "Child exited with ${res.exitCode} instead of 0. "
              "(stdout: ${res.stdout}, stderr: ${res.stderr})";
      }
      var seconds = sw.elapsed.inSeconds;
      // NOTE: There is a slight chance this will cause flakiness, but there is
      // no other good way of testing correctness of timing-dependent code
      // form the outside.
      if (seconds < SECONDS || (SECONDS + 10) < seconds) {
        throw "Child did exit within $seconds seconds, but expected it to take "
              "roughly $SECONDS seconds.";
      }

      asyncEnd();
    });
  });
}

void runClientProcess(String url) {
  var uri = Uri.parse(url);

  // NOTE: We make an HTTP client request and then *forget to close* the HTTP
  // client instance. The idle timer should fire after SECONDS.
  var client = new HttpClient();
  client.idleTimeout = const Duration(seconds: SECONDS);

  client.getUrl(uri)
      .then((req) =>req.close())
      .then((response) => response.drain())
      .then((_) => print('drained client request'));
}

void main(List<String> args) {
  if (args.length == 1) {
    runClientProcess(args.first);
  } else {
    runServerProcess();
  }
}

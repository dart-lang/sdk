// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A regression test for issue 22667.
//
// Makes sure that we don't print a '\0' character for files that are not
// properly new-line terminated.
library zero_termination_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'launch_helper.dart' show launchDart2Js;

Uri pathOfData = Platform.script;
Directory tempDir;
String outFilePath;

_sendNotFound(HttpResponse response) {
  response.statusCode = HttpStatus.NOT_FOUND;
  response.close();
}

Future handleRequest(HttpRequest request) {
  final String path = request.uri.path.substring(1);
  final Uri requestPath = pathOfData.resolve(path);
  final File file = new File(requestPath.toFilePath());
  return file.exists().then((bool found) {
    if (found) {
      file.openRead().pipe(request.response).catchError((e) {
        _sendNotFound(request.response);
      });
    } else {
      _sendNotFound(request.response);
    }
  });
}

void cleanup() {
  File outFile = new File(outFilePath);
  if (outFile.existsSync()) {
    outFile.deleteSync();
  }
}

void check(ProcessResult result) {
  Expect.notEquals(0, result.exitCode);
  List<int> stdout = result.stdout;
  String stdoutString = utf8.decode(stdout);
  Expect.isTrue(stdoutString.contains("Error"));
  // Make sure the "499" from the last line is in the output.
  Expect.isTrue(stdoutString.contains("499"));

  // Make sure that the output does not contain any 0 character.
  Expect.isFalse(stdout.contains(0));
}

Future testFile() async {
  String inFilePath =
      pathOfData.resolve('data/one_line_dart_program.dart').path;
  List<String> args = [inFilePath, "--out=" + outFilePath];

  await cleanup();
  check(await launchDart2Js(args, noStdoutEncoding: true));
  await cleanup();
}

Future serverRunning(HttpServer server) async {
  int port = server.port;
  String inFilePath = "http://127.0.0.1:$port/data/one_line_dart_program.dart";
  List<String> args = [inFilePath, "--out=" + outFilePath];

  server.listen(handleRequest);
  try {
    await cleanup();
    check(await launchDart2Js(args, noStdoutEncoding: true));
  } finally {
    await server.close();
    await cleanup();
  }
}

Future testHttp() {
  return HttpServer
      .bind(InternetAddress.LOOPBACK_IP_V4, 0)
      .then((HttpServer server) => serverRunning(server));
}

runTests() async {
  tempDir = Directory.systemTemp.createTempSync('directory_test');
  outFilePath = path.join(tempDir.path, "out.js");

  try {
    await testFile();
    await testHttp();
  } finally {
    await tempDir.delete(recursive: true);
  }
}

main() {
  asyncStart();
  runTests().whenComplete(asyncEnd);
}

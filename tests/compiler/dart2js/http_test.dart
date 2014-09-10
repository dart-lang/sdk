// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test:
//   *) Compiling a script fetched over HTTP.
//   *) Importing a library fetched over HTTP.
//   *) Automatically resolving package_root when script is fetched over HTTP.

library http_launch_test;

import 'dart:async';
import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

Uri pathOfData = Platform.script.resolve('http_launch_data/');
int port;
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
      file.openRead()
          .pipe(request.response)
          .catchError((e) { _sendNotFound(request.response); });
    } else {
      _sendNotFound(request.response);
    }
  });
}

Future launchDart2Js(args) {
  String ext = Platform.isWindows ? '.bat' : '';
  String command =
      path.normalize(path.join(path.fromUri(Platform.script),
                    '../../../../sdk/bin/dart2js${ext}'));
  return Process.run(command, args);
}

void check(ProcessResult result) {
  Expect.equals(0, result.exitCode);
  File outFile = new File(outFilePath);
  Expect.isTrue(outFile.existsSync());
  Expect.isTrue(outFile.readAsStringSync().contains("hello http tester"));
}

void checkNotFound(ProcessResult result, String filename) {
  Expect.notEquals(0, result.exitCode);
  File outFile = new File(outFilePath);
  Expect.isTrue(result.stdout.contains("404"));
  Expect.isTrue(result.stdout.contains(filename));
}

cleanup() {
  File outFile = new File(outFilePath);
  if (outFile.existsSync()) {
    outFile.deleteSync();
  }
}

Future testNonHttp() {
  String inFilePath = pathOfData.resolve('http_launch_main.dart').toFilePath();
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then(check)
      .then((_) { cleanup(); });
}

Future testHttp() {
  String inFilePath = 'http://127.0.0.1:$port/http_launch_main.dart';
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then(check)
      .then((_) { cleanup(); });
}

Future testHttpLib() {
  File file = new File(path.join(tempDir.path, "in.dart"));
  file.writeAsStringSync("""
  import 'http://127.0.0.1:$port/lib1.dart';
  main() { print(foo()); }
  """);
  String inFilePath = file.path;
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then(check)
      .whenComplete(file.deleteSync)
      .then((_) { cleanup(); });
}

Future testHttpPackage() {
  String inFilePath =
      pathOfData.resolve('http_launch_main_package.dart').toFilePath();
  String packageRoot = 'http://127.0.0.1:$port/packages/';
  List<String> args = [inFilePath,
                       "--out=" + outFilePath,
                       "--package-root=" + packageRoot];
  return launchDart2Js(args)
      .then(check)
      .then((_) { cleanup(); });
}

Future testBadHttp() {
  File file = new File(path.join(tempDir.path, "in_bad.dart"));
  file.writeAsStringSync("""
  import 'http://127.0.0.1:$port/not_existing.dart';
  main() { print(foo()); }
  """);
  String inFilePath = file.path;
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then((pr) => checkNotFound(pr, "not_existing.dart"))
      .whenComplete(file.deleteSync)
      .then((_) { cleanup(); });
}

Future testBadHttp2() {
  String inFilePath = 'http://127.0.0.1:$port/not_found.dart';
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then((processResult) => checkNotFound(processResult, "not_found.dart"))
      .then((_) { cleanup(); });
}

serverRunning(HttpServer server) {
  port = server.port;
  tempDir = Directory.systemTemp.createTempSync('directory_test');
  outFilePath = path.join(tempDir.path, "out.js");

  asyncStart();
  server.listen(handleRequest);
  new Future.value()
       .then((_) => cleanup())  // Make sure we start fresh.
       .then((_) => testNonHttp())
       .then((_) => testHttp())
       .then((_) => testHttpLib())
       .then((_) => testHttpPackage())
       .then((_) => testBadHttp())
       .then((_) => testBadHttp2())
       .whenComplete(() => tempDir.delete(recursive: true))
       .whenComplete(server.close)
       .then((_) => asyncEnd());
}

main() {
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0).then(serverRunning);
}

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

import '../launch_helper.dart' show launchDart2Js;

Uri pathOfData = Platform.script.resolve('http_launch_data/');
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

void check(ProcessResult result) {
  Expect.equals(0, result.exitCode);
  File outFile = new File(outFilePath);
  Expect.isTrue(outFile.existsSync());
  Expect.isTrue(outFile.readAsStringSync().contains("hello http tester"));
}

void checkNotFound(ProcessResult result, String filename) {
  Expect.notEquals(0, result.exitCode);
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
  return launchDart2Js(args).then(check).then((_) {
    cleanup();
  });
}

Future testHttpMain(String serverUrl) {
  String inFilePath = '$serverUrl/http_launch_main.dart';
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args).then(check).then((_) {
    cleanup();
  });
}

Future testHttpLib(String serverUrl) {
  File file = new File(path.join(tempDir.path, "in.dart"));
  file.writeAsStringSync("""
  import '$serverUrl/lib1.dart';
  main() { print(foo()); }
  """);
  String inFilePath = file.path;
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then(check)
      .whenComplete(file.deleteSync)
      .then((_) {
    cleanup();
  });
}

Future testHttpPackage(String serverUrl) {
  String inFilePath =
      pathOfData.resolve('http_launch_main_package.dart').toFilePath();
  String packageRoot = '$serverUrl/packages/';
  List<String> args = [
    inFilePath,
    "--out=" + outFilePath,
    "--package-root=" + packageRoot
  ];
  return launchDart2Js(args).then(check).then((_) {
    cleanup();
  });
}

Future testBadHttp(String serverUrl) {
  File file = new File(path.join(tempDir.path, "in_bad.dart"));
  file.writeAsStringSync("""
  import '$serverUrl/not_existing.dart';
  main() { print(foo()); }
  """);
  String inFilePath = file.path;
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then((pr) => checkNotFound(pr, "not_existing.dart"))
      .whenComplete(file.deleteSync)
      .then((_) {
    cleanup();
  });
}

Future testBadHttp2(String serverUrl) {
  String inFilePath = '$serverUrl/not_found.dart';
  List<String> args = [inFilePath, "--out=" + outFilePath];
  return launchDart2Js(args)
      .then((processResult) => checkNotFound(processResult, "not_found.dart"))
      .then((_) {
    cleanup();
  });
}

serverRunning(HttpServer server, String scheme) {
  tempDir = Directory.systemTemp.createTempSync('directory_test');
  outFilePath = path.join(tempDir.path, "out.js");
  int port = server.port;
  String serverUrl = "$scheme://127.0.0.1:$port";

  asyncStart();
  server.listen(handleRequest);
  return new Future.value()
      .then((_) => cleanup()) // Make sure we start fresh.
      .then((_) => testNonHttp())
      .then((_) => testHttpMain(serverUrl))
      .then((_) => testHttpLib(serverUrl))
      .then((_) => testHttpPackage(serverUrl))
      .then((_) => testBadHttp(serverUrl))
      .then((_) => testBadHttp2(serverUrl))
      .whenComplete(() => tempDir.delete(recursive: true))
      .whenComplete(server.close)
      .then((_) => asyncEnd());
}

Future testHttp() {
  return HttpServer
      .bind(InternetAddress.LOOPBACK_IP_V4, 0)
      .then((HttpServer server) => serverRunning(server, "http"));
}

void initializeSSL() {
  Uri pathOfPkcert = pathOfData.resolve('pkcert');
  String testPkcertDatabase = pathOfPkcert.toFilePath();
  // Issue 29926.
  // ignore: UNDEFINED_METHOD
  SecureSocket.initialize(database: testPkcertDatabase, password: 'dartdart');
}

Future testHttps() {
  initializeSSL();
  return HttpServer
      // Issue 29926.
      // ignore: NOT_ENOUGH_REQUIRED_ARGUMENTS
      .bindSecure(InternetAddress.LOOPBACK_IP_V4, 0,
          // Issue 29926.
          // ignore: UNDEFINED_NAMED_PARAMETER
          certificateName: 'localhost_cert')
      .then((HttpServer server) => serverRunning(server, "https"));
}

main() {
  asyncStart();
  testHttp().then((_) => testHttps).whenComplete(asyncEnd);
}

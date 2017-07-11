// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON, UTF8;

import 'dart:isolate' show RawReceivePort;

import 'dart:io';

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show defaultServerAddress;

badRequest(HttpRequest request, int status, String message) {
  request.response.statusCode = status;
  request.response.write('''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>$message</title>
  </head>
  <body>
    <h1>$message</h1>
  </body>
</html>
''');
  request.response.close().catchError((e, s) {
    print("Request error: $e.");
  });
  print("${request.uri}: $message");
}

collectLog(DateTime time, HttpRequest request) async {
  String json = await request.transform(UTF8.decoder).join();
  var data;
  try {
    data = JSON.decode(json);
  } on FormatException catch (e) {
    print(e);
    return badRequest(
        request, HttpStatus.BAD_REQUEST, "Malformed JSON data: ${e.message}.");
  }
  if (data is! Map) {
    return badRequest(
        request, HttpStatus.BAD_REQUEST, "Malformed JSON data: not a map.");
  }
  if (data["type"] != "crash") {
    return badRequest(request, HttpStatus.BAD_REQUEST,
        "Malformed JSON data: type should be 'crash'.");
  }
  request.response.close();
  String year = "${time.year}".padLeft(4, "0");
  String month = "${time.month}".padLeft(2, "0");
  String day = "${time.day}".padLeft(2, "0");
  String us = "${time.microsecondsSinceEpoch}".padLeft(19, '0');
  Uri uri = Uri.base
      .resolve("crash_logs/${data['client']}/$year-$month-$day/$us.log");
  File file = new File.fromUri(uri);
  await file.parent.create(recursive: true);
  await file.writeAsString(json);
  print("Wrote ${uri.toFilePath()}");

  String type = data["type"];
  String text = data["uri"];
  uri = text == null ? null : Uri.parse(text);
  int charOffset = data["offset"];
  var error = data["error"];
  text = data["trace"];
  StackTrace trace = text == null ? null : new StackTrace.fromString(text);
  String client = data["client"];
  print("""
date: ${time}
type: $type
client: $client
uri: $uri
offset: $charOffset
error:
$error
trace:
$trace
""");
}

main(List<String> arguments) async {
  RawReceivePort keepAlive = new RawReceivePort();
  Uri uri;
  if (arguments.length == 1) {
    uri = Uri.base.resolve(arguments.single);
  } else if (arguments.length == 0) {
    uri = Uri.parse(defaultServerAddress);
  } else {
    throw "Unexpected arguments: ${arguments.join(' ')}.";
  }
  int port = uri.hasPort ? uri.port : 0;
  var host = uri.host.isEmpty ? InternetAddress.LOOPBACK_IP_V4 : uri.host;
  HttpServer server = await HttpServer.bind(host, port);
  print("Listening on http://${server.address.host}:${server.port}/");
  await for (HttpRequest request in server) {
    if (request.method != "POST") {
      badRequest(request, HttpStatus.METHOD_NOT_ALLOWED, "Not allowed.");
      continue;
    }
    if (request.uri.path != "/") {
      badRequest(request, HttpStatus.NOT_FOUND, "Not found.");
      continue;
    }
    collectLog(new DateTime.now(), request);
  }
  keepAlive.close();
}

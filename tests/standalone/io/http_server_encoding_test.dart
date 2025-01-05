// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the server response body is returned according to defaults or the
// charset set in the "Content-Type" header.

import 'dart:convert';
import 'dart:io';

import "package:expect/expect.dart";

Future<void> testWriteWithoutContentTypeJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..write('日本語')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語', body);
}

Future<void> testWritelnWithoutContentTypeJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..writeln('日本語')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語\n', body);
}

Future<void> testWriteAllWithoutContentTypeJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..writeAll(['日', '本', '語'])
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語', body);
}

Future<void> testWriteCharCodeWithoutContentTypeJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..writeCharCode(0x65E5)
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日', body);
}

Future<void> testWriteWithCharsetJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
      ..write('日本語')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語', body);
}

/// Tests for regression: https://github.com/dart-lang/sdk/issues/59719
Future<void> testWritelnWithCharsetJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
      ..writeln('日本語')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語\n', body);
}

Future<void> testWriteAllWithCharsetJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
      ..writeAll(['日', '本', '語'])
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日本語', body);
}

Future<void> testWriteCharCodeWithCharsetJapanese() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
      ..writeCharCode(0x65E5)
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('日', body);
}

Future<void> testWriteWithoutCharsetGerman() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain')
      ..write('Löscherstraße')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = latin1.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('Löscherstraße', body);
}

/// If the charset is not recognized then the text is encoded using ISO-8859-1.
///
/// NOTE: If you change this behavior, make sure that you change the
/// documentation for [HttpResponse].
Future<void> testWriteWithUnrecognizedCharsetGerman() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..headers.contentType = ContentType('text', 'plain', charset: '123')
      ..write('Löscherstraße')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=123',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = latin1.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('Löscherstraße', body);
}

Future<void> testWriteWithoutContentTypeGerman() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

  server.first.then((request) {
    request.response
      ..write('Löscherstraße')
      ..close();
  });
  final request = await HttpClient().get('localhost', server.port, '/');
  final response = await request.close();
  Expect.listEquals([
    'text/plain; charset=utf-8',
  ], response.headers[HttpHeaders.contentTypeHeader] ?? []);
  final body = utf8.decode(await response.fold([], (o, n) => o + n));
  Expect.equals('Löscherstraße', body);
}

main() async {
  // Japanese, utf-8 (only built-in encoding that supports Japanese)
  await testWriteWithoutContentTypeJapanese();
  await testWritelnWithoutContentTypeJapanese();
  await testWriteAllWithoutContentTypeJapanese();
  await testWriteCharCodeWithoutContentTypeJapanese();

  await testWriteWithCharsetJapanese();
  await testWritelnWithCharsetJapanese();
  await testWriteAllWithCharsetJapanese();
  await testWriteCharCodeWithCharsetJapanese();

  // Write using an invalid or non-utf-8 charset will fail for Japanese.

  // German
  await testWriteWithoutCharsetGerman();
  await testWriteWithUnrecognizedCharsetGerman();
  await testWriteWithoutContentTypeGerman();
}
